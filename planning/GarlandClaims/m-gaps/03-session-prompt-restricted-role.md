# Session Prompt 03 — Restricted Role: Portfolio-Scoped Visibility

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 6-8 hours

---

## Task: Scope the Restricted role to see only assigned portfolios, not the entire namespace

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 8) claims: "Restricted — Read-only access limited to assigned applications only." Currently, Restricted is an enum value in `namespace_role` but has no distinctive behavior — restricted users get namespace-wide read access identical to Viewer. The RBAC architecture doc (§8.3) explicitly documents this as a gap.

This work has two phases:
1. **SQL scripts** (for Stuart) — new junction table, RLS policies, constraint update
2. **Frontend changes** — `usePermissions.ts` and `useApplications.ts` updates to filter by portfolio assignment

**⚠️ Conflict warning:** This session modifies `src/hooks/usePermissions.ts`. The L-gap Steward session also touches this file. Do NOT run both in parallel.

### Hard rules

1. **Branch:** `feat/restricted-role`. Create from `dev`.
2. **SQL scripts go to `planning/sql/GarlandClaims/m-gaps/`** — do NOT execute SQL.
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Restricted = read-only** — this role can NEVER create, update, or delete. Only SELECT visibility is scoped.
5. **Non-restricted roles are unaffected** — Admin, Editor, Steward, and Viewer see everything in their workspace as before. Only Restricted users get filtered visibility.
6. **Do NOT modify Steward logic** — that is a separate session (`GarlandClaims/l-gaps/01`).

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/identity-security/rbac-permissions.md
   - §3.2: Role definitions (lines ~86-115)
   - §8.3: Implementation gap table (lines ~366-376) — "workspace_users constraint has no restricted value"
   - §6: Steward model — read but DO NOT implement (separate session)

2. src/hooks/usePermissions.ts (full file)
   - Current role checking pattern
   - Line where restricted is checked: canCreateFlag: namespaceRole !== 'restricted'
   - Note what canWrite, canRead, isAdmin mean

3. src/hooks/useApplications.ts (full file, ~143 lines)
   - Lines 15-143: how applications are fetched
   - Portfolio query: portfolios.select().eq('workspace_id', workspaceId)
   - Portfolio assignment query: portfolio_assignments.select().in('portfolio_id', portfolioIds)
   - Application query: applications.select().in('id', Array.from(allAppIds))
   - THIS IS THE MAIN FILTERING POINT for restricted users

4. src/hooks/usePortfolios.ts
   - How portfolios are fetched — restricted users should only see assigned portfolios

5. docs-architecture/identity-security/rls-policy.md
   - Standard 4-policy pattern (lines ~356-364)
   - Helper functions: get_current_namespace_id(), check_is_platform_admin()

6. docs-architecture/operations/new-table-checklist.md
   - Junction table pattern

7. src/types/index.ts
   - namespace_role type definition (~line 794)
```

### Step 2 — Verify current state via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Check workspace_users role constraint
psql "$DATABASE_READONLY_URL" -c "SELECT conname, consrc FROM pg_constraint WHERE conrelid = 'public.workspace_users'::regclass AND contype = 'c'"

# Check current namespace_users columns
psql "$DATABASE_READONLY_URL" -c "\d public.namespace_users"

# Check portfolio structure
psql "$DATABASE_READONLY_URL" -c "\d public.portfolios"
psql "$DATABASE_READONLY_URL" -c "\d public.portfolio_assignments"
```

### Step 3 — Generate SQL: Portfolio user assignments table + constraint update

**File:** `planning/sql/GarlandClaims/m-gaps/03-restricted-role-schema.sql`

**3a. Create portfolio_user_assignments junction table:**

```sql
CREATE TABLE public.portfolio_user_assignments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  portfolio_id uuid NOT NULL REFERENCES public.portfolios(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_by uuid REFERENCES auth.users(id),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_portfolio_user_assignment UNIQUE (portfolio_id, user_id)
);

CREATE INDEX idx_portfolio_user_assignments_user ON public.portfolio_user_assignments(user_id);
CREATE INDEX idx_portfolio_user_assignments_portfolio ON public.portfolio_user_assignments(portfolio_id);

COMMENT ON TABLE public.portfolio_user_assignments IS 'Maps restricted users to the portfolios they can see. Non-restricted roles ignore this table.';

ALTER TABLE public.portfolio_user_assignments ENABLE ROW LEVEL SECURITY;
GRANT ALL ON public.portfolio_user_assignments TO authenticated, service_role;

-- Audit trigger
CREATE TRIGGER audit_portfolio_user_assignments
  AFTER INSERT OR UPDATE OR DELETE ON public.portfolio_user_assignments
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();
```

**3b. RLS policies for portfolio_user_assignments:**

```sql
-- Admins/editors can manage assignments
CREATE POLICY pua_select ON public.portfolio_user_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM namespace_users nu
      WHERE nu.user_id = auth.uid()
      AND nu.namespace_id = (
        SELECT w.namespace_id FROM portfolios p
        JOIN workspaces w ON w.id = p.workspace_id
        WHERE p.id = portfolio_user_assignments.portfolio_id
      )
    )
  );

CREATE POLICY pua_insert ON public.portfolio_user_assignments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM namespace_users nu
      WHERE nu.user_id = auth.uid()
      AND nu.namespace_id = (
        SELECT w.namespace_id FROM portfolios p
        JOIN workspaces w ON w.id = p.workspace_id
        WHERE p.id = portfolio_user_assignments.portfolio_id
      )
      AND nu.role IN ('admin')
    )
  );

CREATE POLICY pua_delete ON public.portfolio_user_assignments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM namespace_users nu
      WHERE nu.user_id = auth.uid()
      AND nu.namespace_id = (
        SELECT w.namespace_id FROM portfolios p
        JOIN workspaces w ON w.id = p.workspace_id
        WHERE p.id = portfolio_user_assignments.portfolio_id
      )
      AND nu.role IN ('admin')
    )
  );
```

**3c. Update security posture sentinel:** Note in comments that table count increases by 1 (106 → 107, or current + 1 if SOC2 table was already added).

Add consolidated verification at the bottom of the script.

### Step 4 — Generate SQL: Application-level RLS for restricted visibility

**File:** `planning/sql/GarlandClaims/m-gaps/03-restricted-role-rls.sql`

This is the hardest part. The existing `applications` SELECT policy allows all workspace members to see all apps. For restricted users, we need to add a portfolio-scoping condition.

**Pattern: Modify the existing SELECT policy on `applications`:**

```sql
-- Drop and recreate the SELECT policy
-- IMPORTANT: Read the existing policy first (Step 2 output) and preserve its logic
-- Add a restricted-user branch:

DROP POLICY IF EXISTS applications_select ON public.applications;

CREATE POLICY applications_select ON public.applications
  FOR SELECT USING (
    -- Platform admin bypass
    check_is_platform_admin()
    OR
    -- Non-restricted: existing workspace membership check (unchanged)
    (
      EXISTS (
        SELECT 1 FROM namespace_users nu
        WHERE nu.user_id = auth.uid()
        AND nu.namespace_id = applications.namespace_id
        AND nu.role != 'restricted'
      )
    )
    OR
    -- Restricted: only apps in assigned portfolios
    (
      EXISTS (
        SELECT 1 FROM namespace_users nu
        WHERE nu.user_id = auth.uid()
        AND nu.namespace_id = applications.namespace_id
        AND nu.role = 'restricted'
      )
      AND EXISTS (
        SELECT 1 FROM portfolio_assignments pa
        JOIN portfolio_user_assignments pua ON pua.portfolio_id = pa.portfolio_id
        WHERE pa.application_id = applications.id
        AND pua.user_id = auth.uid()
      )
    )
  );
```

**CRITICAL:** Before writing this, you MUST read the actual existing SELECT policy from Step 2. The policy above is a sketch — the real policy likely has additional conditions (workspace_id checks, etc.). Preserve ALL existing logic and add the restricted branch alongside it.

**Also apply similar logic to these related tables** (restricted users shouldn't see data for apps they can't see):
- `deployment_profiles` SELECT policy
- `portfolio_assignments` SELECT policy

For each, read the existing policy first and adapt.

### Step 5 — Frontend: Update usePermissions.ts

Add a restricted-scoping check:

```typescript
// Add to the returned permissions object:
const isRestricted = namespaceRole === 'restricted';

return {
  // ... existing permissions ...
  isRestricted,
  // All write permissions are false for restricted (should already be the case via canWrite)
};
```

Verify that `canWrite` is already `false` for restricted (it should be, since `canWrite = isAdmin || isEditor`). If not, add an explicit check.

### Step 6 — Frontend: Update useApplications.ts

For restricted users, add a portfolio filter step:

```typescript
// After fetching portfolios, if user is restricted:
// 1. Fetch portfolio_user_assignments for the current user
// 2. Filter portfolios to only those the user is assigned to
// 3. Then proceed with existing portfolio_assignments + applications fetch

if (isRestricted) {
  const { data: assignments } = await supabase
    .from('portfolio_user_assignments')
    .select('portfolio_id')
    .eq('user_id', userId);

  const assignedPortfolioIds = new Set(assignments?.map(a => a.portfolio_id) || []);
  portfolios = portfolios.filter(p => assignedPortfolioIds.has(p.id));
}
```

**Note:** This is a belt-and-suspenders approach — RLS at the database level already filters (from Step 4), but the frontend filter ensures the UI is consistent and prevents empty-state flicker.

### Step 7 — Frontend: Portfolio assignment UI for admins

Create a simple assignment interface in the namespace/workspace user management area. When an admin views a user with the `restricted` role:

- Show a "Portfolio Access" section below the role selector
- List all portfolios in the workspace with checkboxes
- Checked = user can see that portfolio's applications
- Unchecked = user cannot see

This could be in `src/pages/settings/` or wherever user management lives. Search for where role assignment happens:

```bash
grep -r "namespace_role\|role.*select\|role.*dropdown" src/pages/settings/ --include="*.tsx"
```

Keep the UI simple — a checklist, not a complex drag-and-drop. Save on checkbox change.

### Step 8 — Type check and impact analysis

```bash
grep -r "usePermissions\|useApplications\|isRestricted" src/ --include="*.ts" --include="*.tsx"
npx tsc --noEmit
```

### Step 9 — Update architecture docs

Update `docs-architecture/identity-security/rbac-permissions.md`:
- §3.2: Mark Restricted as "Implemented — portfolio-scoped"
- §8.3: Remove the gap entry or mark as "Closed"
- Add §9 or similar: Document `portfolio_user_assignments` table and admin assignment flow

### Step 10 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
mkdir -p planning/sql/GarlandClaims/m-gaps
git add planning/sql/GarlandClaims/m-gaps/03-* src/hooks/usePermissions.ts src/hooks/useApplications.ts src/pages/settings/ src/components/
git commit -m "feat: restricted role scoped to assigned portfolios

Adds portfolio_user_assignments junction table. Restricted users see
only applications in their assigned portfolios. Admins manage portfolio
assignments via the user settings panel.
Closes Garland audit red flag (Slide 8, 'Restricted role')."
git push -u origin feat/restricted-role
```

Also commit architecture doc:
```bash
cd ~/getinsync-architecture
git add identity-security/rbac-permissions.md
git commit -m "docs: close restricted role implementation gap in RBAC doc"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] SQL: `portfolio_user_assignments` table with RLS, audit trigger, grants
- [ ] SQL: `applications` SELECT policy updated with restricted-user portfolio check
- [ ] SQL: `deployment_profiles` and `portfolio_assignments` SELECT policies similarly updated
- [ ] Frontend: `usePermissions.ts` exposes `isRestricted` flag
- [ ] Frontend: `useApplications.ts` filters portfolios for restricted users
- [ ] Frontend: Admin UI for assigning portfolios to restricted users
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] RBAC architecture doc updated — gap marked as closed
- [ ] Security posture sentinel table count noted

### What NOT to do

- Do NOT modify Steward role logic — that is `GarlandClaims/l-gaps/01`
- Do NOT execute SQL scripts — generate them for Stuart
- Do NOT change write permissions for restricted — they are already read-only
- Do NOT modify RLS on tables unrelated to application visibility (budgets, settings, etc.)
- Do NOT add restricted to `workspace_users.role` — restricted operates at namespace level per the architecture doc
