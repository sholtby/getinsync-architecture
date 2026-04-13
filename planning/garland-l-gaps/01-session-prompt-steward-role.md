# Session Prompt 01 — Steward Role: Application-Scoped Write Access

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None (but do NOT run in parallel with garland-m-gaps/03-restricted-role — both touch usePermissions.ts)
> Estimated: 1-2 days

---

## Task: Implement the Steward role — business owners can edit only their own applications' business assessments

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 8) claims: "Steward — This is your business owner. Invite application owners directly into the platform to assess their own applications. They update what's assigned to them — no training required, no risk of touching someone else's data."

Currently, Steward is an enum value in `namespace_role` that behaves **identically to Editor**. The code has explicit `// steward(future)` comments at three locations in `usePermissions.ts`. The RBAC architecture doc (§6) defines exactly what Steward should be able to edit.

The key insight: **Steward scope is derived from `application_contacts`**, not from a separate assignment table. A user is a Steward for an application if they appear in `application_contacts` with `role_type IN ('business_owner', 'steward')` for that application.

### Hard rules

1. **Branch:** `feat/steward-role`. Create from `dev`.
2. **SQL scripts go to `planning/sql/garland-l-gaps/`** — do NOT execute SQL.
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Steward scope is contact-based** — use `application_contacts.role_type` for scoping, NOT a new junction table. The table already exists.
5. **Steward editable fields (from RBAC doc §6.3):**
   - ✅ Business Assessment factors B1-B10
   - ✅ Lifecycle Status
   - ✅ Annual Licensing Cost
   - ✅ Vendor Contact assignment
   - ❌ Application name, description, or metadata
   - ❌ Technical Assessment factors
   - ❌ DP infrastructure fields (hosting, cloud, DR, etc.)
   - ❌ Portfolio assignment or workspace settings
6. **Do NOT modify Restricted role logic** — that is `garland-m-gaps/03`.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/identity-security/rbac-permissions.md
   - §3.2: Role definitions — Steward row (lines ~86-115)
   - §6: Steward Model (lines ~263-314) — contact types, max 10 apps, delegates
   - §6.3: Steward Editable Fields (lines ~297-306) — the canonical list
   - §8.3: Implementation gap (lines ~369-375)

2. src/hooks/usePermissions.ts (full file, ~60 lines)
   - Line 36: canEditLifecycle: canWrite,      // steward(future)
   - Line 37: canEditCost: canWrite,           // steward(future)
   - Line 41: canEditBizAssessment: canWrite,  // steward(future)
   - Note: canWrite = isAdmin || isEditor — steward is NOT included

3. src/types/contacts.ts (lines ~90-130)
   - LeadershipRoleType: includes 'business_owner' and 'steward'
   - ApplicationContact interface

4. src/components/applications/ApplicationDetailDrawer.tsx
   - Lines 54, 70-73: extracts businessOwner from contacts
   - Uses canEditDP, canEditBizAssessment from usePermissions
   - THIS is where steward-scoped editing needs to gate

5. src/components/applications/DeploymentProfileSection.tsx
   - Assessment form rendering — where B1-B10 fields live
   - Note which sections map to "steward editable" vs "not editable"

6. src/components/applications/OwnerSection.tsx
   - Owner display — shows business_owner contact
   - Stewards should NOT be able to change ownership

7. Schema: application_contacts table definition
   - role_type CHECK constraint includes 'business_owner' and 'steward'
   - application_id + contact_id + role_type uniqueness
```

### Step 2 — Impact analysis

```bash
# Find all consumers of usePermissions
grep -r "usePermissions" src/ --include="*.tsx" --include="*.ts"

# Find all consumers of canEditBizAssessment, canEditLifecycle, canEditCost
grep -r "canEditBizAssessment\|canEditLifecycle\|canEditCost\|canEditDP" src/ --include="*.tsx"

# Find where assessment form fields are rendered
grep -r "B01\|B02\|B03\|b_score\|bizAssessment\|business_assessment" src/ --include="*.tsx"

# Find where contacts are queried for current user
grep -r "application_contacts\|role_type.*business_owner\|role_type.*steward" src/ --include="*.ts" --include="*.tsx"
```

### Step 3 — Create steward scope hook: `src/hooks/useStewardScope.ts`

This hook determines which applications the current user has steward rights on:

```typescript
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from '../contexts/AuthContext';

interface StewardScope {
  /** Application IDs where the current user has steward rights */
  stewardAppIds: Set<string>;
  /** Check if user can steward-edit a specific application */
  canStewardEdit: (applicationId: string) => boolean;
  loading: boolean;
}

export function useStewardScope(): StewardScope {
  const { user, namespaceRole } = useAuth();
  const [stewardAppIds, setStewardAppIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user || namespaceRole !== 'steward') {
      setStewardAppIds(new Set());
      setLoading(false);
      return;
    }

    async function fetchStewardApps() {
      // Find the contact record for this user
      const { data: contact } = await supabase
        .from('contacts')
        .select('id')
        .eq('user_id', user.id)
        .single();

      if (!contact) {
        setStewardAppIds(new Set());
        setLoading(false);
        return;
      }

      // Find all applications where this contact is business_owner or steward
      const { data: assignments } = await supabase
        .from('application_contacts')
        .select('application_id')
        .eq('contact_id', contact.id)
        .in('role_type', ['business_owner', 'steward']);

      setStewardAppIds(new Set(assignments?.map(a => a.application_id) || []));
      setLoading(false);
    }

    fetchStewardApps();
  }, [user, namespaceRole]);

  return {
    stewardAppIds,
    canStewardEdit: (appId: string) => stewardAppIds.has(appId),
    loading,
  };
}
```

**Important:** Check the actual schema for how `contacts.user_id` is stored. The contact record must be linked to the auth user. Verify this mapping exists — if contacts don't have a `user_id` FK, the steward derivation needs to match by email instead.

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'contacts' AND column_name IN ('user_id', 'email')"
```

### Step 4 — Refactor usePermissions.ts

Replace the three `// steward(future)` lines with steward-aware logic. The hook needs to accept an optional `applicationId` parameter so it can check steward scope:

```typescript
// Option A: Add applicationId parameter
export function usePermissions(applicationId?: string) {
  const { namespaceRole, workspaceRole } = useAuth();
  const { canStewardEdit } = useStewardScope();

  const isSteward = namespaceRole === 'steward';
  const isStewardForThisApp = isSteward && applicationId ? canStewardEdit(applicationId) : false;

  return {
    // ... existing permissions ...
    canEditBizAssessment: canWrite || isStewardForThisApp,
    canEditLifecycle: canWrite || isStewardForThisApp,
    canEditCost: canWrite || isStewardForThisApp,

    // Steward CANNOT edit these (keep existing logic):
    canEditDP: canWrite,  // infrastructure fields — admin + editor only
    canEditTechAssessment: canWrite,  // T-score — admin + editor only
    canEditMetadata: canWrite,  // app name, description — admin + editor only
  };
}
```

**Option B:** If adding `applicationId` to usePermissions is too invasive (many callers don't have it), create a separate `useStewardPermissions(applicationId)` hook that returns only the steward-specific overrides.

Choose whichever approach requires fewer changes to existing callers. Check the grep results from Step 2 to count how many callers pass applicationId vs not.

### Step 5 — Gate assessment form sections

In the deployment profile / assessment form components, use the steward-aware permissions:

**Business Assessment (B1-B10):** These should be editable for stewards on their apps.
- Find where B-score fields render as read-only vs editable
- Use `canEditBizAssessment` (now steward-aware) to gate

**Technical Assessment (T-score):** These should remain read-only for stewards.
- Verify these use `canEditTechAssessment` (NOT steward-aware)

**Infrastructure fields (hosting, cloud, DR, etc.):** Read-only for stewards.
- Verify these use `canEditDP` (NOT steward-aware)

**Lifecycle Status dropdown:** Editable for stewards on their apps.
- This may be in `DeploymentProfileSection.tsx` — find the lifecycle status selector
- Gate with `canEditLifecycle` (now steward-aware)

**Annual cost field:** Editable for stewards on their apps.
- Find the cost input field
- Gate with `canEditCost` (now steward-aware)

### Step 6 — Steward application list visibility

Stewards should see ALL applications in their workspace (same as Editor/Viewer) but only be able to EDIT their assigned ones. The read visibility is workspace-wide — only write permissions are scoped.

Verify: `useApplications.ts` does NOT need filtering for steward (unlike Restricted). Stewards see everything, they just can't edit everything.

### Step 7 — Generate SQL: Steward write policies (optional but recommended)

**File:** `planning/sql/garland-l-gaps/01-steward-rls-policies.sql`

For defense-in-depth, add RLS policies that enforce steward write scoping at the database level (not just UI):

```sql
-- Steward can UPDATE deployment_profiles only if they are a contact on the parent application
-- This is additive — existing admin/editor policies still work

-- Example for deployment_profiles UPDATE policy:
-- Read the existing UPDATE policy first, then add a steward branch
```

**Note:** This is complex because deployment_profiles don't have a direct FK to applications — they go through `portfolio_assignments`. Map the join path:
```
deployment_profiles → applications (via deployment_profiles.application_id)
→ application_contacts (via application_id)
→ contacts (via contact_id)
→ contacts.user_id = auth.uid()
AND application_contacts.role_type IN ('business_owner', 'steward')
```

Read the existing UPDATE policies before writing new ones. The steward branch should be an OR addition, not a replacement.

### Step 8 — Type check

```bash
npx tsc --noEmit
```

All callers of `usePermissions()` that don't pass `applicationId` must still compile. The parameter should be optional with no behavior change when omitted.

### Step 9 — Update architecture docs

Update `docs-architecture/identity-security/rbac-permissions.md`:
- §6: Mark Steward as "Implemented — contact-based scoping"
- §6.3: Confirm editable field list matches implementation
- §8.3: Mark gap as "Closed"

### Step 10 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/hooks/usePermissions.ts src/hooks/useStewardScope.ts src/components/applications/
# Add any SQL files generated
git add planning/sql/garland-l-gaps/01-*
git commit -m "feat: steward role — application-scoped business assessment editing

Stewards can edit B1-B10, lifecycle status, and annual cost on applications
where they are assigned as business_owner or steward in application_contacts.
They cannot edit infrastructure fields, technical assessments, or metadata.
Scope derived from application_contacts, not a separate assignment table.
Closes Garland audit red flag (Slide 8, 'Steward role')."
git push -u origin feat/steward-role
```

Also commit architecture doc:
```bash
cd ~/getinsync-architecture
git add identity-security/rbac-permissions.md
git commit -m "docs: close steward role implementation gap in RBAC doc"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] `useStewardScope.ts` hook: queries application_contacts for steward/business_owner assignments
- [ ] `usePermissions.ts`: steward-aware permissions for B1-B10, lifecycle, cost
- [ ] `usePermissions.ts`: steward CANNOT edit DP infrastructure, tech assessment, metadata
- [ ] Assessment forms gate B-score fields using steward-aware permission
- [ ] Lifecycle status dropdown editable for stewards on their apps
- [ ] Annual cost field editable for stewards on their apps
- [ ] All non-steward callers of usePermissions unaffected (optional param)
- [ ] SQL: steward write-scoped RLS policies (defense-in-depth)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] RBAC doc updated — gap marked as closed
- [ ] No Restricted role logic modified

### What NOT to do

- Do NOT create a separate `steward_assignments` junction table — use `application_contacts`
- Do NOT modify the Restricted role — that is `garland-m-gaps/03`
- Do NOT give stewards access to technical assessment fields
- Do NOT give stewards access to infrastructure fields (hosting, cloud, DR, etc.)
- Do NOT modify application visibility — stewards see all apps in their workspace, they just can't edit all of them
- Do NOT execute SQL scripts — generate them for Stuart
- Do NOT remove the `// steward(future)` comments until the implementation is verified working
