# ADR: CSDM Export Readiness

**Version:** 1.0
**Date:** March 28, 2026
**Status:** PROPOSED
**Author:** Stuart Holtby + Claude
**Relates to:**
- `features/integrations/csdm-crawl-gap-analysis.md` (v1.0) — §4.1, §4.2, §4.4
- `adr/adr-integration-dp-alignment.md` (v1.2) — Phase 3 UI coordination
- `adr/adr-dp-infrastructure-boundary.md` (v1.1) — positioning boundary
- `features/integrations/servicenow-alignment.md` (v1.2) — sync scope model
- `csdm-crawl-toolkit/skills/csdm-crawl/references/crawl-checklist.md` — 47-item checklist

---

## 1. Context

The CSDM Crawl Gap Analysis (March 22, 2026) identified 9 field-level gaps preventing
GetInSync from producing Crawl-compliant ServiceNow export data. Three gaps account
for the majority of the problem:

1. **No group entity** — 3 of 16 required fields need `sys_user_group` references
   (managed_by_group, support_group, change_control). GetInSync tracks individuals only.
2. **Business criticality placement** — ServiceNow needs a global 1–5 value.
   GetInSync stores criticality as 0–100 on portfolio_assignments (portfolio-scoped).
3. **Missing change_control role** — `deployment_profile_contacts.role_type` CHECK
   constraint does not include `change_control`.

This ADR resolves all three gaps plus coordinates the Integration-DP Phase 3 UI work
into a single, coherent body of work.

---

## 2. The Design Principle

**"Architecture = CSDM-aligned. UI = QuickBooks simple."**

The CSDM gap is real, but the solution must not infect the UI with ITSM jargon.
ServiceNow asks: "What's the support_group for this Application Service?"
GetInSync asks: **"Who fixes it when it breaks?"**

This ADR introduces a `teams` entity and three plain-English questions on the
Deployment Profile edit screen. The CSDM translation happens at the export boundary,
invisible to the business user.

---

## 3. Decisions

### D1: Teams coexist with individual contacts

Individual contacts (`deployment_profile_contacts`) answer: "Who do I call?"
Teams answer: "Which group handles this?"

These are complementary. Jane Smith is the person you call when SAP is down.
Finance IT Team is the ServiceNow group that receives the incident. Both are needed.
Teams do not replace individual contacts.

### D2: Teams live at namespace and workspace levels

| Scope | Example | Visibility |
|---|---|---|
| Namespace team (workspace_id IS NULL) | "Provincial IT Support" | All workspaces in namespace |
| Workspace team (workspace_id IS NOT NULL) | "Highways Help Desk" | Members of that workspace only |

This supports the Central IT shared model — namespace-level teams serve multiple
ministries. Ministry-specific teams are workspace-scoped.

### D3: Three business questions on the Deployments & Costs tab

Each deployment profile gets three team reference fields, displayed with
plain-English labels:

| UI Label | Column | Maps to ServiceNow |
|---|---|---|
| "Who fixes it when it breaks?" | `support_team_id` | `cmdb_ci_service_auto.support_group` |
| "Who approves changes?" | `change_team_id` | `cmdb_ci_service_auto.change_control` |
| "Which team manages this?" | `managing_team_id` | `cmdb_ci_service_auto.managed_by_group` |

These appear as a new "Operations" section within each DP card on the
Deployments & Costs tab, below the existing contact assignments.

### D4: Business criticality is derived at export only

No new column on `applications`. No UI field. At export time, the publish engine:

1. Finds all `portfolio_assignments` for the application
2. Takes the MAX criticality score across all portfolios
3. Maps 0–100 → 1–5 using the mapping table from gap analysis §4.2

| GIS Score (0–100) | SN Value |
|---|---|
| 80–100 | 1 - most critical |
| 60–79 | 2 - somewhat critical |
| 40–59 | 3 - less critical |
| 20–39 | 4 - minimally critical |
| 0–19 | 5 - least critical |

If no portfolio_assignments exist, export produces NULL (acceptable — sn_getwell
does not check this field).

For Application Service criticality: inherit from the parent application's derived value.

### D5: Single ADR scope

This ADR covers teams, criticality, change_control role, and integration-DP Phase 3
UI coordination as a single body of work. Rationale: these changes share the same
DP edit screen real estate, the same export engine, and the same CSDM compliance target.

---

## 4. Schema Changes

### 4.1 New table: `teams`

```sql
CREATE TABLE teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT uq_team_name_per_namespace UNIQUE (namespace_id, name)
);

COMMENT ON TABLE teams IS 'Lightweight team/group entity. Maps to sys_user_group at export.';
COMMENT ON COLUMN teams.workspace_id IS 'NULL = namespace-wide team. Set = workspace-local team.';
```

**Design notes:**
- Unique constraint on (namespace_id, name) — team names unique within a namespace
  regardless of workspace scope. Avoids ambiguity at export.
- No membership management — that's ServiceNow's job. GetInSync just needs the name
  to map to `sys_user_group.name` at publish time.
- `is_active` for soft delete / retirement of teams.

### 4.2 New columns on `deployment_profiles`

```sql
ALTER TABLE deployment_profiles
    ADD COLUMN support_team_id uuid REFERENCES teams(id) ON DELETE SET NULL,
    ADD COLUMN change_team_id uuid REFERENCES teams(id) ON DELETE SET NULL,
    ADD COLUMN managing_team_id uuid REFERENCES teams(id) ON DELETE SET NULL;

COMMENT ON COLUMN deployment_profiles.support_team_id
    IS 'Who fixes it when it breaks? Maps to cmdb_ci_service_auto.support_group';
COMMENT ON COLUMN deployment_profiles.change_team_id
    IS 'Who approves changes? Maps to cmdb_ci_service_auto.change_control';
COMMENT ON COLUMN deployment_profiles.managing_team_id
    IS 'Which team manages this? Maps to cmdb_ci_service_auto.managed_by_group';
```

### 4.3 Update `deployment_profile_contacts` CHECK constraint

```sql
ALTER TABLE deployment_profile_contacts
    DROP CONSTRAINT deployment_profile_contacts_role_type_check;

ALTER TABLE deployment_profile_contacts
    ADD CONSTRAINT deployment_profile_contacts_role_type_check
    CHECK (role_type IN (
        'operational_owner',
        'technical_sme',
        'support',
        'change_control',
        'vendor_rep',
        'other'
    ));
```

This adds `change_control` as an individual contact role alongside the team-level
`change_team_id`. An organization might set the Change team (Finance CAB) AND a
change_control individual contact (Jane Smith, the CAB chair).

### 4.4 RLS on `teams`

```sql
-- Teams follow namespace isolation
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY teams_namespace_isolation ON teams
    FOR ALL
    USING (namespace_id IN (
        SELECT namespace_id FROM namespace_users
        WHERE user_id = auth.uid()
    ));

-- Workspace-scoped teams: visible only to workspace members
-- Namespace-scoped teams (workspace_id IS NULL): visible to all namespace members
-- This is handled by the namespace_id check above — workspace_id scoping
-- is a UI filter, not an RLS restriction. All namespace members can see
-- all teams for export mapping purposes.
```

**RLS note:** Workspace-scoped visibility is a UI concern, not a security concern.
All teams within a namespace are visible to all namespace members. The workspace_id
field controls which teams appear in the dropdown for a given workspace's DPs, not
data isolation.

### 4.5 Audit trigger

```sql
CREATE TRIGGER audit_teams
    AFTER INSERT OR UPDATE OR DELETE ON teams
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

### 4.6 GRANTs

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON teams TO authenticated;
```

---

## 5. Export Mapping

### 5.1 Teams → sys_user_group

At export time, the publish engine resolves team names to ServiceNow group sys_ids:

```
GetInSync teams.name → ServiceNow sys_user_group.name (exact match)
```

If no match is found, the export engine:
1. Logs a warning: "Team '{name}' has no matching sys_user_group"
2. Leaves the field NULL in the export payload
3. Surfaces the warning in the pre-publish validation UI

**Future enhancement:** A `servicenow_group_name` override column on `teams` for
cases where the GetInSync team name differs from the ServiceNow group name.
Not needed for MVP — most organizations use consistent team names.

### 5.2 Business criticality derivation

```sql
-- Export-time derivation (in vw_csdm_business_app or export function)
SELECT
    a.id,
    a.name,
    CASE
        WHEN max_crit >= 80 THEN '1 - most critical'
        WHEN max_crit >= 60 THEN '2 - somewhat critical'
        WHEN max_crit >= 40 THEN '3 - less critical'
        WHEN max_crit >= 20 THEN '4 - minimally critical'
        WHEN max_crit >= 0  THEN '5 - least critical'
        ELSE NULL
    END AS busines_criticality
FROM applications a
LEFT JOIN LATERAL (
    SELECT MAX(pa.criticality) AS max_crit
    FROM portfolio_assignments pa
    JOIN deployment_profiles dp ON dp.id = pa.deployment_profile_id
    WHERE dp.application_id = a.id
      AND pa.criticality IS NOT NULL
) crit ON true;
```

### 5.3 Individual contacts → owned_by / managed_by

No change from gap analysis. Export reads from `application_contacts` and
`deployment_profile_contacts`, never from legacy free-text fields.

### 5.4 Integration export

Per the integration-DP ADR, integrations with DP-level FKs export as
"Sends data to::Receives data from" relationships in `cmdb_rel_ci` between
Application Services. Rich metadata (method, format, cadence, sensitivity)
is not exported to `cmdb_rel_ci` — it stays in GetInSync as the system of
record for integration architecture.

---

## 6. UI Changes

### 6.1 Deployments & Costs tab — new "Operations" section

Each DP card gains a new "Operations" section **after** the IT Service dependencies
(Section 4: "What Services Does It Use?"). This is the last section on the card.

**As-built DP card section order (with this change):**

```
┌─────────────────────────────────────────────────┐
│ SAP Finance — Production                    [▼] │
├─────────────────────────────────────────────────┤
│                                                 │
│ ── What Software Is This? ─────────────────── 1 │
│ [LinkedSoftwareProductsList]                    │
│                                                 │
│ ── What Does It Run On? ──────────────────── 2  │
│ [LinkedTechnologyProductsList]                  │
│                                                 │
│ ── Where Does It Run? ───────────────────── 3   │
│ Environment: PROD    Hosting: SaaS              │
│ Version: 4.2.1       Region: CA-Central         │
│ Server: SAPSRV01     DR: Hot Standby            │
│ Remediation: M       Tech Debt: $15,000         │
│                                                 │
│ ── What Services Does It Use? ──────────── 4    │
│ [ITServiceDependencyList]                       │
│                                                 │
│ ── Operations (NEW) ────────────────────── 5    │
│                                                 │
│ Who fixes it when it breaks?                    │
│ ┌─────────────────────────────────────┐         │
│ │ Finance IT Team                   ▼ │         │
│ └─────────────────────────────────────┘         │
│                                                 │
│ Who approves changes?                           │
│ ┌─────────────────────────────────────┐         │
│ │ Finance Change Advisory Board     ▼ │         │
│ └─────────────────────────────────────┘         │
│                                                 │
│ Which team manages this day-to-day?             │
│ ┌─────────────────────────────────────┐         │
│ │ Finance IT Team                   ▼ │         │
│ └─────────────────────────────────────┘         │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Note:** There is no "Contacts" section on the DP card today. Individual
contacts are managed on the Application Detail page (Contacts tab), not
inline on the DP card. The Operations section stands alone as Section 5.

**Dropdown behavior:**
- Shows all namespace-level teams + teams scoped to the DP's workspace
- Sorted alphabetically, namespace teams first (labeled "All workspaces")
- "Add new team..." option at bottom creates inline (name + optional description)
- Empty state: "No teams defined yet. Add your first team to get started."

**Tooltip on section header:**
"These teams map to ServiceNow support groups for incident routing and change
approval. You don't need ServiceNow to use this — it's useful for tracking
who's responsible for each deployment."

### 6.2 Team management screen

Accessible via namespace admin settings. Simple CRUD list:

```
┌─────────────────────────────────────────────────┐
│ Teams                                    [+ Add]│
├─────────────────────────────────────────────────┤
│ Name                    │ Scope          │ Used │
│─────────────────────────┼────────────────┼──────│
│ Provincial IT Support   │ All workspaces │  12  │
│ Finance IT Team         │ Finance        │   8  │
│ Finance CAB             │ Finance        │   4  │
│ Highways Help Desk      │ Highways       │   3  │
│ Central IT Change Board │ All workspaces │  15  │
└─────────────────────────────────────────────────┘
```

"Used" column = count of DPs referencing this team in any of the three FK fields.
Prevents accidental deletion of in-use teams.

### 6.3 Integration-DP Phase 3 coordination

The integration-DP ADR Phase 3 adds a DP selector to the Add Connection modal.
This work shares the same application edit screen. Coordinate so that:
- The "Operations" section (teams) appears as the last section on the DP card
  (after ITServiceDependencyList — Section 5)
- The DP selector in Add Connection only appears when the app has multiple DPs
- Both changes ship in the same release to avoid two rounds of DP card UI changes

---

## 7. Impact on Gap Analysis Scorecard

### Before this ADR

| Category | Ready | Gap | Partial |
|---|---|---|---|
| BA Required (8) | 5 | 2 | 1 |
| AS Required (8) | 3 | 3 | 2 |
| Relationships (3) | 3 | 0 | 0 |

### After this ADR (when implemented)

| Category | Ready | Gap | Partial | Change |
|---|---|---|---|---|
| BA Required (8) | 5 | 1* | 2 | managed_by_group → Ready (via managing_team_id) |
| AS Required (8) | 6 | 0 | 2 | support_group → Ready, change_control → Ready, managed_by_group → Ready |
| Relationships (3) | 3 | 0 | 0 | No change |

*Remaining BA gap: `busines_criticality` is derived at export, not stored — technically
Ready but marked as Partial since it depends on portfolio_assignments being populated.

**Revised scorecard: 14 → 19 of 28 fields ready.** The three team fields resolve the
single largest gap cluster.

---

## 8. Implementation Sequence

| Phase | Work | Estimate | Dependencies |
|---|---|---|---|
| 1 | Schema: `teams` table + RLS + audit + GRANTs | 1 hour | None |
| 2 | Schema: 3 FK columns on `deployment_profiles` | 30 min | Phase 1 |
| 3 | Schema: `change_control` role_type CHECK update | 15 min | None |
| 4 | UI: Team management screen (namespace admin) | 2 hours | Phase 1 |
| 5 | UI: Operations section on DP card (3 dropdowns) | 3 hours | Phase 1, 2 |
| 6 | UI: Integration-DP Phase 3 (DP selector in Add Connection) | 3 hours | integration-DP ADR Phase 2 ✅ |
| 7 | Export: vw_csdm_business_app with criticality derivation | 2 hours | Phase 37 scope |
| 8 | Export: vw_csdm_service_auto with team→group mapping | 2 hours | Phase 37 scope |

**Phases 1–5:** Can ship immediately. ~7 hours total. Improves data model and UI
independent of ServiceNow export.

**Phase 6:** Ships with or after Phase 5. Shares DP card UI real estate.

**Phases 7–8:** Phase 37 scope. Export views depend on the team and criticality
decisions but don't need to ship until the publish engine is built.

---

## 9. pgTAP Assertions to Add

```sql
-- teams table exists
SELECT has_table('public', 'teams');

-- teams has RLS enabled
SELECT policies_are('public', 'teams', ARRAY['teams_namespace_isolation']);

-- teams has audit trigger
SELECT trigger_is('public', 'teams', 'audit_teams', 'audit_log_trigger');

-- teams has GRANTs
SELECT table_privs_are('public', 'teams', 'authenticated',
    ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']);

-- deployment_profiles has team FK columns
SELECT has_column('public', 'deployment_profiles', 'support_team_id');
SELECT has_column('public', 'deployment_profiles', 'change_team_id');
SELECT has_column('public', 'deployment_profiles', 'managing_team_id');

-- change_control is a valid role_type
-- (tested via INSERT into deployment_profile_contacts with role_type='change_control')
```

---

## 10. Documents to Update After Implementation

| Document | Update Required |
|---|---|
| `features/integrations/csdm-crawl-gap-analysis.md` | Update §4.1 resolution to "RESOLVED — teams entity", §4.2 to "RESOLVED — derive at export", §4.4 to "RESOLVED — CHECK updated". Update scorecard. |
| `features/integrations/servicenow-alignment.md` | Add §3.6 "Teams → sys_user_group" mapping section |
| `csdm-crawl-toolkit/.../getinsync-bridge.md` | Update comparison table: managed_by_group, support_group, change_control → ✓ |
| `csdm-crawl-toolkit/.../crawl-checklist.md` | No change — checklist is ServiceNow-focused, not GetInSync-focused |
| `MANIFEST.md` | Add teams table to pending schema changes, increment document count |
| `testing/pgtap-rls-coverage.sql` | Add assertions per §9 |
| `CLAUDE.md` | No change needed |

---

## 11. Risks

| Risk | Mitigation |
|---|---|
| Team names don't match sys_user_group names | Pre-publish validation warns on mismatches. Future: override column. |
| Users don't populate team fields | Fields are optional. Export produces NULL. sn_getwell doesn't check these. |
| Namespace team naming collision with workspace teams | UNIQUE(namespace_id, name) prevents duplicates regardless of workspace scope. |
| Too many UI fields on DP card | "Operations" section is collapsible. Three dropdowns is manageable. |
| Criticality derivation produces unexpected values | Pre-publish preview shows derived values before export. User can verify. |

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-03-28 | Initial ADR — 5 decisions, schema for teams entity, UI wireframe, export mapping, gap analysis impact |
