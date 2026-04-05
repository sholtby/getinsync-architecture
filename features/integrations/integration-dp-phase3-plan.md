# Integration-DP Phase 3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire deployment profile columns into the integration UI — type sync, DP selector in modal, DP name in connections list, bug fixes, and architecture doc updates.

**Architecture:** The `vw_integration_detail` view already includes 4 DP columns (Phase 1-2 deployed). This plan updates the TypeScript contract to match all 34 view columns, adds conditional DP selectors to the Add Connection modal, displays DP names in the connections list, fixes a pre-existing `data_sensitivity` bug, and replaces `alert()` calls with `react-hot-toast`.

**Tech Stack:** React, TypeScript, Supabase, Tailwind CSS, react-hot-toast, @headlessui/react (SearchableSelect)

**Spec:** `docs-architecture/features/integrations/integration-dp-phase3-spec.md`

---

## Pre-flight

- [ ] **Create feature branch**

```bash
cd ~/Dev/getinsync-nextgen-ag
git checkout dev
git pull origin dev
git checkout -b feat/integration-dp-phase3
```

- [ ] **Verify starting state compiles**

```bash
npx tsc --noEmit
```

Expected: 0 errors

---

## Task 1: Full VwIntegrationDetail Type Sync

**Files:**
- Modify: `src/types/view-contracts.ts:31-53`

This task rewrites the `VwIntegrationDetail` interface to exactly match the 34 columns in the live `vw_integration_detail` view. Two phantom fields are removed (`connected_entity_name`, `data_sensitivity`), and 15 columns are added.

- [ ] **Step 1: Replace the VwIntegrationDetail interface**

In `src/types/view-contracts.ts`, replace lines 31-53 (the entire `VwIntegrationDetail` interface) with:

```typescript
/** Supabase view: `vw_integration_detail` */
export interface VwIntegrationDetail {
  id: string;
  integration_name: string | null;
  source_application_id: string;
  source_application_name: string;
  source_workspace_id: string | null;
  source_workspace_name: string | null;
  namespace_id: string | null;
  source_deployment_profile_id: string | null;
  source_deployment_profile_name: string | null;
  target_application_id: string | null;
  target_application_name: string | null;
  target_workspace_name: string | null;
  target_deployment_profile_id: string | null;
  target_deployment_profile_name: string | null;
  external_system_name: string | null;
  external_organization_id: string | null;
  external_organization_name: string | null;
  integration_category: 'internal' | 'external';
  direction: string;
  integration_type: string;
  data_format: string | null;
  frequency: string;
  criticality: string;
  sensitivity: string | null;
  data_classification: string | null;
  status: string;
  description: string | null;
  sla_description: string | null;
  notes: string | null;
  data_tags: string[] | null;
  created_at: string | null;
  updated_at: string | null;
  contact_count: number | null;
  primary_contact_name: string | null;
}
```

Note: Field order matches the view's `ordinal_position`. Removed: `connected_entity_name` (not in view), `data_sensitivity` (not in view — the view uses `sensitivity`).

- [ ] **Step 2: Run type check to find broken consumers**

```bash
npx tsc --noEmit 2>&1 | head -50
```

Expected: Errors in `ApplicationConnections.tsx` (line 284, `data_sensitivity`) and `ConnectionsVisual.tsx` (lines 481, 1042, 1135, `data_sensitivity`). No errors for `connected_entity_name` (not referenced in code).

- [ ] **Step 3: Fix data_sensitivity → sensitivity in ApplicationConnections.tsx**

In `src/pages/ApplicationConnections.tsx`, line 284, change:

```typescript
// OLD
const showLock = int.data_sensitivity === 'high' || int.data_sensitivity === 'confidential';

// NEW
const showLock = int.sensitivity === 'high' || int.sensitivity === 'confidential';
```

- [ ] **Step 4: Fix data_sensitivity → sensitivity in ConnectionsVisual.tsx (3 occurrences)**

In `src/components/integrations/ConnectionsVisual.tsx`:

**Line 481** — change:
```typescript
// OLD
const isSensitive = int.data_sensitivity === 'pii' || int.data_sensitivity === 'pci' || int.data_sensitivity === 'phi';
// NEW
const isSensitive = int.sensitivity === 'pii' || int.sensitivity === 'pci' || int.sensitivity === 'phi';
```

**Line 1042** — change:
```typescript
// OLD
{(details?.data_sensitivity === 'pii' || details?.data_sensitivity === 'pci') && <span ...>Sensitive Data</span>}
// NEW
{(details?.sensitivity === 'pii' || details?.sensitivity === 'pci') && <span ...>Sensitive Data</span>}
```

**Line 1135** — change:
```typescript
// OLD
{edge.dashed && <div ...>Sensitive Data ({formatTooltipText(int.data_sensitivity || '')})</div>}
// NEW
{edge.dashed && <div ...>Sensitive Data ({formatTooltipText(int.sensitivity || '')})</div>}
```

- [ ] **Step 5: Verify type check passes**

```bash
npx tsc --noEmit
```

Expected: 0 errors

- [ ] **Step 6: Commit**

```bash
git add src/types/view-contracts.ts src/pages/ApplicationConnections.tsx src/components/integrations/ConnectionsVisual.tsx
git commit -m "feat: sync VwIntegrationDetail to 34 columns, fix data_sensitivity bug"
```

---

## Task 2: DP Selector in AddConnectionModal

**Files:**
- Modify: `src/components/integrations/AddConnectionModal.tsx`

Adds conditional deployment profile selectors for source and target applications. Shows selector only when an app has >1 DP. Single-DP apps auto-assign silently on save. Also replaces `alert()` with `toast.error()`.

- [ ] **Step 1: Add toast import**

At top of `src/components/integrations/AddConnectionModal.tsx`, add after the existing imports:

```typescript
import toast from 'react-hot-toast';
```

- [ ] **Step 2: Add DeploymentProfileOption interface**

After the `OrganizationOption` interface (line 23-26), add:

```typescript
interface DeploymentProfileOption {
    id: string;
    name: string;
    environment: string | null;
    is_primary: boolean;
}
```

- [ ] **Step 3: Add DP form state**

After the existing form state declarations (after line 56, `description`), add:

```typescript
    // Deployment Profile State
    const [sourceDPs, setSourceDPs] = useState<DeploymentProfileOption[]>([]);
    const [targetDPs, setTargetDPs] = useState<DeploymentProfileOption[]>([]);
    const [sourceDeploymentProfileId, setSourceDeploymentProfileId] = useState<string | null>(null);
    const [targetDeploymentProfileId, setTargetDeploymentProfileId] = useState<string | null>(null);
```

- [ ] **Step 4: Add fetchDPs helper function**

After the `fetchRefTable` helper (line 28-35), add:

```typescript
const fetchDPs = async (applicationId: string): Promise<DeploymentProfileOption[]> => {
    const { data, error } = await supabase
        .from('deployment_profiles')
        .select('id, name, environment, is_primary')
        .eq('application_id', applicationId)
        .order('is_primary', { ascending: false })
        .order('name');
    if (error) {
        console.error('Error fetching DPs:', error);
        return [];
    }
    return (data as DeploymentProfileOption[]) || [];
};
```

- [ ] **Step 5: Fetch source DPs on mount and populate edit mode**

Inside the `useEffect` that fires when `isOpen` changes (line 73-112), add DP fetching. The existing `useEffect` is NOT async — it calls `fetchOptions()` fire-and-forget style. Match this pattern by using `.then()` instead of `await`.

After the `fetchOptions()` call (line 75), add source DP fetch:

```typescript
            // Fetch source app DPs
            fetchDPs(currentAppId).then(setSourceDPs);
```

In the edit branch (after line 92, `fetchDataTags`), add:

```typescript
                // Pre-populate DP selections for edit
                setSourceDeploymentProfileId(initialData.source_deployment_profile_id || null);
                setTargetDeploymentProfileId(initialData.target_deployment_profile_id || null);
                // Fetch target DPs if internal with target app
                if (initialData.integration_category === 'internal' && initialData.target_application_id) {
                    fetchDPs(initialData.target_application_id).then(setTargetDPs);
                }
```

In the reset branch (after line 109, clearing description), add:

```typescript
                setSourceDeploymentProfileId(null);
                setTargetDeploymentProfileId(null);
                setTargetDPs([]);
```

**Important:** Do NOT make the `useEffect` callback async. Use `.then()` to match the existing fire-and-forget pattern. This step depends on Task 1 being complete (the `source_deployment_profile_id` field must exist on the `IntegrationDetail` type).

- [ ] **Step 6: Fetch target DPs when target app changes**

Add a new `useEffect` after the existing one (after line 112):

```typescript
    useEffect(() => {
        if (targetAppId && mode === 'internal') {
            fetchDPs(targetAppId).then(setTargetDPs);
        } else {
            setTargetDPs([]);
            setTargetDeploymentProfileId(null);
        }
    }, [targetAppId, mode]);
```

- [ ] **Step 7: Add DP fields to save payload**

In `handleSubmit` (line 200-216), add to the `payload` object after the existing fields:

```typescript
                source_deployment_profile_id: sourceDPs.length === 1
                    ? sourceDPs[0].id
                    : sourceDeploymentProfileId,
                target_deployment_profile_id: mode === 'internal'
                    ? (targetDPs.length === 1 ? targetDPs[0].id : targetDeploymentProfileId)
                    : null,
```

- [ ] **Step 8: Replace alert() with toast.error()**

In `handleSubmit` catch block (line 242), change:

```typescript
// OLD
alert('Failed to save connection.');

// NEW
toast.error('Failed to save connection.');
```

- [ ] **Step 9: Add source DP selector UI**

After the connection name field (after line 402, closing `</div>` of the name input), add the source DP selector. It renders only when `sourceDPs.length > 1`:

```tsx
                        {/* Source Deployment Profile (only if multiple DPs) */}
                        {sourceDPs.length > 1 && (
                            <SearchableSelect
                                label="Source Deployment Profile (optional)"
                                options={sourceDPs}
                                value={sourceDPs.find(dp => dp.id === sourceDeploymentProfileId) || null}
                                onChange={(dp) => setSourceDeploymentProfileId(dp?.id || null)}
                                getLabel={(dp) => `${dp.name}${dp.environment ? ` (${dp.environment})` : ''}`}
                                getKey={(dp) => dp.id}
                                placeholder="Select deployment profile..."
                            />
                        )}
```

- [ ] **Step 10: Add target DP selector UI**

After the internal target app `SearchableSelect` (after line 415, closing of the `mode === 'internal'` block), add the target DP selector inside the same conditional:

```tsx
                        {/* Target Deployment Profile (only if internal + multiple DPs) */}
                        {mode === 'internal' && targetDPs.length > 1 && (
                            <SearchableSelect
                                label="Target Deployment Profile (optional)"
                                options={targetDPs}
                                value={targetDPs.find(dp => dp.id === targetDeploymentProfileId) || null}
                                onChange={(dp) => setTargetDeploymentProfileId(dp?.id || null)}
                                getLabel={(dp) => `${dp.name}${dp.environment ? ` (${dp.environment})` : ''}`}
                                getKey={(dp) => dp.id}
                                placeholder="Select deployment profile..."
                            />
                        )}
```

- [ ] **Step 11: Update visual flow helper to show DP name**

In the source box of the visual flow helper (line 333-338), add DP name below app name. Replace the entire source `<div>` (lines 333-338) with:

```tsx
                            <div className="w-44 h-20 bg-emerald-50 border border-emerald-200 rounded-lg shadow-sm flex flex-col items-center justify-center p-3 text-center transition-all">
                                <span className="text-xs text-emerald-600 font-semibold uppercase tracking-wider mb-1">Source</span>
                                <span className="text-sm font-bold text-emerald-900 leading-tight line-clamp-1">
                                    {currentAppName}
                                </span>
                                {sourceDPs.length > 1 && sourceDeploymentProfileId && (
                                    <span className="text-[10px] text-emerald-600 mt-0.5">
                                        ({sourceDPs.find(dp => dp.id === sourceDeploymentProfileId)?.name})
                                    </span>
                                )}
                            </div>
```

Note: `line-clamp-2` → `line-clamp-1` is intentional — the DP name takes the second line.

Apply the same pattern to the target box. The target box is inside an IIFE at lines 367-384. Find the target name span (the one containing `{isDefined ? getTargetName() : '--'}`), and insert immediately after that `</span>`:

```tsx
                                        {isDefined && targetDPs.length > 1 && targetDeploymentProfileId && (
                                            <span className="text-[10px] text-emerald-600 mt-0.5">
                                                ({targetDPs.find(dp => dp.id === targetDeploymentProfileId)?.name})
                                            </span>
                                        )}
```

- [ ] **Step 12: Verify type check passes**

```bash
npx tsc --noEmit
```

Expected: 0 errors

- [ ] **Step 13: Commit**

```bash
git add src/components/integrations/AddConnectionModal.tsx
git commit -m "feat: add DP selector to Add Connection modal, replace alert with toast"
```

---

## Task 3: Connections List — Show DP Name

**Files:**
- Modify: `src/pages/ApplicationConnections.tsx`

Displays DP name alongside app name in integration row cards when a DP is specified. Also replaces `alert()` with `toast.error()`.

- [ ] **Step 1: Add toast import**

At top of `src/pages/ApplicationConnections.tsx`, add:

```typescript
import toast from 'react-hot-toast';
```

- [ ] **Step 2: Replace alert() with toast.error()**

In `executeDelete` (line 176), change:

```typescript
// OLD
alert('Failed to delete integration');

// NEW
toast.error('Failed to delete integration.');
```

- [ ] **Step 3: Update renderIntegrationRow to show DP name**

In `renderIntegrationRow` (line 278-342), after the `connectedName` derivation (line 280-282), add DP name logic:

```typescript
        const connectedDpName = isIntegExternal(int)
            ? null  // External integrations show external_system_name, not an app — no DP to display
            : (isTarget ? int.source_deployment_profile_name : int.target_deployment_profile_name);
```

Note: The spec mentions source DP *may* show for external integrations, but the connected entity for external integrations is the external system name (not an app with DPs). Showing the *source* app's DP here would be confusing — it's the current app, not the connected entity. The source DP is visible in the modal when editing.

Then update the connected entity display (line 302-304). Replace:

```tsx
                            <h3 className="text-sm font-semibold text-gray-900">
                                {int.external_system_name || connectedName}
                            </h3>
```

With:

```tsx
                            <h3 className="text-sm font-semibold text-gray-900">
                                {int.external_system_name || connectedName}
                                {connectedDpName && (
                                    <span className="text-gray-500 text-xs font-normal ml-1">({connectedDpName})</span>
                                )}
                            </h3>
```

- [ ] **Step 4: Verify type check passes**

```bash
npx tsc --noEmit
```

Expected: 0 errors

- [ ] **Step 5: Commit**

```bash
git add src/pages/ApplicationConnections.tsx
git commit -m "feat: show DP name in connections list, replace alert with toast"
```

---

## Task 4: Architecture Doc Updates

**Files:**
- Modify: `docs-architecture/features/integrations/architecture.md`
- Modify: `docs-architecture/adr/adr-integration-dp-alignment.md`

- [ ] **Step 1: Update integrations architecture.md §7**

In `docs-architecture/features/integrations/architecture.md`, in section 7 "Open Questions or Follow-Up Work" (line ~294), replace the line:

```
- Future enhancement: allow DeploymentProfiles to reference integrations for lifecycle visualization.
```

With:

```
- **Deployed (Phase 3, April 2026):** Integrations can be scoped to specific Deployment Profiles via `source_deployment_profile_id` and `target_deployment_profile_id` nullable FKs on `application_integrations`. The Add Connection modal shows a DP selector when an app has multiple DPs. The Connections list displays DP names alongside app names when specified. See ADR: `adr/adr-integration-dp-alignment.md`.
```

Also update section 2 (line ~25-27) and section 4.1-4.2 (lines ~149-153) to reflect that integrations now CAN reference DPs. Replace:

Line ~25: `Integrations attach directly to the **BusinessApplication**, not to DeploymentProfiles.`
→ `Integrations attach to the **BusinessApplication** with optional scoping to specific **DeploymentProfiles** via source/target DP foreign keys.`

Line ~149: `- DeploymentProfiles do not hold integrations.`
→ `- DeploymentProfiles can be referenced via optional `source_deployment_profile_id` / `target_deployment_profile_id` FKs on `application_integrations`.`

Line ~152-153: Replace `- No direct relationship.` and `- May surface integration visibility in future lifecycle views only.` with:
→ `- Optional relationship via `source_deployment_profile_id` / `target_deployment_profile_id` on `application_integrations`.`
→ `- Used for DP-scoped integration visibility in the Connections list and (future) Visual tab Level 3.`

- [ ] **Step 2: Update ADR — mark Phase 3 COMPLETE**

In `docs-architecture/adr/adr-integration-dp-alignment.md`, find the Phase 3 section header (line ~111) and add a status line:

```
### Phase 3: UI Updates — COMPLETE (2026-04-04)
```

Also update the implementation plan section (line ~179) to reflect Phase 3 is done. Change:

```
4. Schedule Phase 1 + Phase 2 as a single unit of work (schema migration + view + type updates). Estimate: 1 day. Phase 3 (UI + React Flow rebuild) follows immediately after.
```

To:

```
4. Phase 1 + Phase 2 delivered as a single unit (schema + view + types, March 2026). Phase 3 (UI — DP selector + list display) delivered April 2026. React Flow rebuild (Visual tab Level 3) deferred to Stage C.
```

- [ ] **Step 3: Update MANIFEST.md**

In `docs-architecture/MANIFEST.md`, bump the version number and add a changelog entry:

```
- vX.XX — Integration-DP Phase 3: updated integrations/architecture.md (DP scoping deployed), marked ADR Phase 3 COMPLETE
```

- [ ] **Step 4: Update guides/whats-new.md**

Append an entry to `guides/whats-new.md` for the user-visible changes:

```markdown
### Deployment Profile Scoping for Integrations

You can now specify which Deployment Profile an integration connects through. When creating or editing a connection, if the application has multiple deployment profiles, a "Deployment Profile" dropdown appears. The connections list now shows the DP name alongside the app name when specified.
```

- [ ] **Step 5: Update guides/user-help/integrations.md**

In `guides/user-help/integrations.md`, add a note in the "Adding a Connection" section (or equivalent) explaining the optional DP selector behavior:

> When an application has multiple deployment profiles, you can optionally select which deployment profile the integration runs through. If the application has only one deployment profile, it is assigned automatically.

- [ ] **Step 6: Commit architecture repo**

```bash
cd ~/getinsync-architecture
git add -A
git commit -m "docs: mark Integration-DP Phase 3 complete, update integrations architecture, MANIFEST, whats-new, user-help"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

---

## Task 5: Final Verification & Push

- [ ] **Step 1: Full type check**

```bash
npx tsc --noEmit
```

Expected: 0 errors

- [ ] **Step 2: Production build test**

```bash
npm run build
```

Expected: Build succeeds with no errors

- [ ] **Step 3: Impact scan — verify no remaining data_sensitivity references**

```bash
grep -r "data_sensitivity" src/ --include="*.ts" --include="*.tsx"
```

Expected: 0 matches

- [ ] **Step 4: Impact scan — verify no remaining connected_entity_name references**

```bash
grep -r "connected_entity_name" src/ --include="*.ts" --include="*.tsx"
```

Expected: 0 matches

- [ ] **Step 5: Verify no alert() calls in modified files**

```bash
grep -n "alert(" src/components/integrations/AddConnectionModal.tsx src/pages/ApplicationConnections.tsx
```

Expected: 0 matches

- [ ] **Step 6: Push feature branch**

```bash
git push -u origin feat/integration-dp-phase3
```

- [ ] **Step 7: Confirm with Stuart — ready for dev merge or manual testing first**
