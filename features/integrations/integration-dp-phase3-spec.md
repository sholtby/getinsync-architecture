# Integration-DP Phase 3 — Frontend Design Spec

**Date:** 2026-04-04
**Branch:** `feat/integration-dp-phase3`
**ADR:** `docs-architecture/adr/adr-integration-dp-alignment.md`
**Level Set:** `docs-architecture/planning/april-2026-level-set.md` §4 Stage B

---

## Context

Phase 1-2 of the Integration-DP alignment is deployed:
- `source_deployment_profile_id` and `target_deployment_profile_id` nullable FK columns exist on `application_integrations`
- `vw_integration_detail` has been rebuilt with DP columns (34 columns total)
- The current TypeScript interface has 21 fields, of which 2 are phantom (not in view) and 15 view columns are missing

Phase 3 wires these into the frontend.

---

## Task 1: Full VwIntegrationDetail Type Sync

**File:** `src/types/view-contracts.ts`

Rewrite `VwIntegrationDetail` to exactly match all 34 columns from the live view.

### Current state audit

The existing interface has 21 fields. Two are phantom (not in the view):

| Phantom field | Status | Action |
|---------------|--------|--------|
| `connected_entity_name` | Not in view, not referenced by any consumer code | Remove |
| `data_sensitivity` | Not in view (view has `sensitivity`). Used in `ApplicationConnections.tsx:284` and `ConnectionsVisual.tsx:481,1042,1135` — reads silently return `undefined`, causing broken lock icons and sensitive data badges | Remove; fix consumers to use `sensitivity` |

### Columns to add (15 net-new)

| Column | TypeScript type | Notes |
|--------|----------------|-------|
| `source_workspace_id` | `string \| null` | New |
| `source_workspace_name` | `string \| null` | New |
| `namespace_id` | `string \| null` | New |
| `source_deployment_profile_id` | `string \| null` | Phase 3 DP |
| `source_deployment_profile_name` | `string \| null` | Phase 3 DP |
| `target_workspace_name` | `string \| null` | New |
| `target_deployment_profile_id` | `string \| null` | Phase 3 DP |
| `target_deployment_profile_name` | `string \| null` | Phase 3 DP |
| `external_organization_id` | `string \| null` | New |
| `external_organization_name` | `string \| null` | New |
| `sla_description` | `string \| null` | New |
| `notes` | `string \| null` | New |
| `created_at` | `string \| null` | New (timestamptz) |
| `updated_at` | `string \| null` | New (timestamptz) |
| `contact_count` | `number \| null` | New (bigint) |

**Math check:** 21 existing - 2 phantom + 15 new = 34 columns. Matches view.

**Note:** `target_workspace_id` is NOT in the view (confirmed via `information_schema.columns`). Only `target_workspace_name` is exposed. This asymmetry with `source_workspace_id` is intentional in the view definition.

### Bug fix: data_sensitivity -> sensitivity

Consumers reading `data_sensitivity` must be updated to read `sensitivity`:
- `ApplicationConnections.tsx:284` — lock icon logic
- `ConnectionsVisual.tsx:481` — sensitive data detection
- `ConnectionsVisual.tsx:1042` — sensitive data badge
- `ConnectionsVisual.tsx:1135` — tooltip text

This is a pre-existing silent bug, not new to Phase 3, but must be fixed as part of the type sync.

### Verification

- `integration-types.ts` re-exports as `IntegrationDetail` — no change needed (type alias)
- Grep all consumers: `ApplicationConnections.tsx`, `AddConnectionModal.tsx`, `ConnectionsVisual.tsx`
- Run `npx tsc --noEmit` to confirm zero errors
- **Task 1 must complete before Task 2** — edit mode pre-population reads DP fields from the type

---

## Task 2: DP Selector in AddConnectionModal

**File:** `src/components/integrations/AddConnectionModal.tsx`

**Dependency:** Task 1 (type sync) must be complete — edit mode reads `initialData.source_deployment_profile_id`.

### DP option type

```typescript
interface DeploymentProfileOption {
  id: string;
  name: string;
  environment: string | null;
  is_primary: boolean;
}
```

### Behavior

1. **Source app** (always the current app in context): fetch its DPs on mount
2. **Target app** (internal integrations only): fetch DPs when `targetApplicationId` changes
3. If app has **>1 DP**: show `SearchableSelect` labeled "Deployment Profile (optional)"
4. If app has **exactly 1 DP**: hide selector; auto-assign that DP's ID on save
5. **External integrations:** source DP selector still applies (the source app has DPs). No target DP selector (external systems don't have DPs).

### DP fetch query

```sql
SELECT id, name, environment, is_primary
FROM deployment_profiles
WHERE application_id = $appId
ORDER BY is_primary DESC, name ASC
```

### Form state additions

```typescript
const [sourceDPs, setSourceDPs] = useState<DeploymentProfileOption[]>([]);
const [targetDPs, setTargetDPs] = useState<DeploymentProfileOption[]>([]);
const [sourceDeploymentProfileId, setSourceDeploymentProfileId] = useState<string | null>(null);
const [targetDeploymentProfileId, setTargetDeploymentProfileId] = useState<string | null>(null);
```

### DP fetch triggers

- Source DPs: fetch on component mount (source app = current application context)
- Target DPs: fetch when `targetApplicationId` changes (internal mode only)
- Clear target DP selection when target app changes

### Save payload changes

Add to the insert/update object:
```typescript
source_deployment_profile_id: sourceDPs.length === 1
  ? sourceDPs[0].id          // auto-assign single DP
  : sourceDeploymentProfileId, // user selection or null
target_deployment_profile_id: targetDPs.length === 1
  ? targetDPs[0].id
  : targetDeploymentProfileId,
```

### Edit mode

When `initialData` is provided:
- Pre-populate `sourceDeploymentProfileId` from `initialData.source_deployment_profile_id`
- Pre-populate `targetDeploymentProfileId` from `initialData.target_deployment_profile_id`

### SearchableSelect prop wiring

Follow existing pattern from target app selector (line ~406-414):
```typescript
<SearchableSelect
  options={sourceDPs}
  value={sourceDPs.find(dp => dp.id === sourceDeploymentProfileId) || null}
  onChange={(dp) => setSourceDeploymentProfileId(dp?.id || null)}
  getLabel={(dp) => `${dp.name}${dp.environment ? ` (${dp.environment})` : ''}`}
  getKey={(dp) => dp.id}
  placeholder="Select deployment profile..."
/>
```

### Visual flow helper update

The source/target boxes at the top of the modal show DP name below app name when selected:
- Line 1: **App Name** (existing)
- Line 2: *(DP Name)* in smaller, muted text (only when DP selected or auto-assigned)

### Existing alert() calls

`AddConnectionModal.tsx:243` uses `alert('Failed to save connection.')`. Replace with toast notification while touching this file. This is a pre-existing CLAUDE.md violation.

---

## Task 3: Connections List — DP Name Display

**File:** `src/pages/ApplicationConnections.tsx`

### Behavior

In the integration row cards (both internal and external sections), when rendering the connected entity name:

- **If DP name is populated:** Display as `"App Name (DP Name)"` — e.g. "SAP ERP (Production)"
- **If DP name is null:** Display app name only (current behavior, unchanged)

### Implementation

The connected entity name is determined by whether the current app is the source or target of the integration:
- If current app is the source -> show target app name + target DP name
- If current app is the target -> show source app name + source DP name

For external integrations: no DP name is shown in the row card. The connected entity is the external system name (not an app with DPs). The source DP is visible in the modal when editing.

DP name portion uses `text-gray-500 text-sm` styling to keep the app name prominent.

### Existing alert() call

`ApplicationConnections.tsx:176` uses `alert('Failed to delete integration')`. Replace with toast notification while touching this file.

### No changes to

- Summary bar counts
- Status filter logic
- Delete functionality (except alert -> toast)

---

## Task 4: Architecture Doc Updates

### `docs-architecture/features/integrations/architecture.md`

Section 7 item 4: Replace "Future enhancement: allow DeploymentProfiles to reference integrations for lifecycle visualization" with:

> **Deployed (Phase 3, April 2026):** Integrations can be scoped to specific Deployment Profiles via `source_deployment_profile_id` and `target_deployment_profile_id` nullable FKs on `application_integrations`. The Add Connection modal shows a DP selector when an app has multiple DPs. The Connections list displays DP names alongside app names when specified. See ADR: `adr/adr-integration-dp-alignment.md`.

### `docs-architecture/adr/adr-integration-dp-alignment.md`

In the status/phases section, mark Phase 3 as **COMPLETE** with date 2026-04-04.

---

## Out of Scope

- **B.4 data migration** (assign existing integrations to primary DP) — Stuart handles via SQL Editor
- **Visual tab React Flow rebuild** (Level 3 DP-scoped blast radius) — Stage C, separate branch
- **New reference tables** — none needed; DPs are queried from `deployment_profiles` table directly
- **ConnectionsVisual.tsx DP labels** — visual diagram node labels don't show DP names (future, Stage C)

---

## Files Modified

| File | Change |
|------|--------|
| `src/types/view-contracts.ts` | Rewrite VwIntegrationDetail: remove 2 phantom fields, add 15 columns (34 total) |
| `src/components/integrations/AddConnectionModal.tsx` | Add DP fetch, selector UI, save payload; replace alert() with toast |
| `src/pages/ApplicationConnections.tsx` | Show DP name in row cards; fix `data_sensitivity` -> `sensitivity`; replace alert() with toast |
| `src/components/integrations/ConnectionsVisual.tsx` | Fix `data_sensitivity` -> `sensitivity` (3 occurrences) |
| `docs-architecture/features/integrations/architecture.md` | Update §7 item 4 |
| `docs-architecture/adr/adr-integration-dp-alignment.md` | Mark Phase 3 COMPLETE |

## Files Read-Only (verify, no changes expected)

| File | Verification |
|------|-------------|
| `src/types/integration-types.ts` | Confirm re-export still works |

## Task execution order

1. Task 1 (type sync + bug fix) — must be first
2. Task 2 (modal) and Task 3 (list) — can be parallel after Task 1
3. Task 4 (docs) — last, after code is verified
