# Plan: Phase A.1 — Fix Viewer "View-Only" Access (Drawers + Settings Catalogs)

## Context

Phase A (UI Role Gating) was implemented on `feat/restricted-user-audit` branch — `usePermissions` hook created, 13 UI gaps wired. However, the gating was **too aggressive** in some places: viewers should be able to **view everything** but not **edit** anything. Currently, viewers cannot open some drawers/modals because:

1. **Settings catalog pages** (Software Products, Technology Catalog, IT Services): Clicking a product/service **name** opens the edit modal — this is the ONLY way to view item details. If the edit modal is hidden, viewers lose all detail access.
2. **ApplicationDetailDrawer**: The "Edit Application" button (navigates to ApplicationPage) is now hidden for viewers. This might be too restrictive — viewers should be able to navigate to see app details in read-only mode.
3. **ApplicationForm**: `isReadOnly` now set from `!canWrite`, which hides the Save button. This is CORRECT — but need to verify viewers can still open the page and see fields.

**Principle:** Viewers see everything. Edit/Save/Delete buttons are hidden. Forms render in disabled/read-only state.

**Branch:** `feat/restricted-user-audit`
**Test user:** `smholtby+rstrctdusr@gmail.com` / `pKCfo2ot3ze` (namespace_role=viewer, editor on Finance workspace, viewer on Police/IT workspaces)

**What was already done in Phase A (this session):**
- `src/hooks/usePermissions.ts` — NEW centralized permission hook
- `src/contexts/AuthContext.tsx` — `workspaceRole` and `namespaceRole` exposed
- 13 UI components wired with permission gates (see `rbac-permissions.md` §8.4)
- Architecture docs updated (`rbac-permissions.md`, `MANIFEST.md`)
- `npx tsc --noEmit` passes with zero errors

---

## Fix 1: Settings Catalog Name Clicks → Open Modal in Read-Only Mode

**Problem:** On SoftwareProductsSettings, TechnologyCatalogSettings, and ITServiceCatalogSettings, clicking a product/service name calls `setEditingProduct(x); setIsModalOpen(true)` — opening an edit modal. We hid the edit/delete action buttons with `canManageSettings`, but the name-click still opens the modal. Viewers need to see details but not save.

**Files to modify:**

### 1a. `src/pages/settings/SoftwareProductsSettings.tsx`
- The product name `onClick` (around line 399) opens the edit modal — this should STILL work for viewers (so they can view details)
- Pass `isReadOnly={!canManageSettings}` to the modal component
- Need to check what modal component is used and if it supports `isReadOnly`

### 1b. `src/pages/settings/TechnologyCatalogSettings.tsx`
- Same pattern (around line 490) — product name click opens `TechnologyProductModal`
- Pass `isReadOnly={!canManageSettings}` to `TechnologyProductModal`
- `TechnologyProductModal` is 1000+ lines — check if it already has `isReadOnly` support

### 1c. `src/pages/settings/ITServiceCatalogSettings.tsx`
- Same pattern (around line 635) — service name click opens modal
- Pass `isReadOnly={!canManageSettings}` to the IT service modal

**For each modal, check:**
- Does it already have an `isReadOnly` prop?
- If not, add one that: disables all form inputs, hides the Save/Submit button, changes the header from "Edit X" to "View X"

**Alternative (simpler):** If the modals don't support read-only and are complex (1000+ lines), a simpler approach is:
- Keep name clicks working for everyone
- In the modal's `handleSave` function, check `canManageSettings` and show a toast error + return early if not permitted
- This is a "belt and suspenders" approach — RLS already blocks the save, but the toast gives feedback

---

## Fix 2: ApplicationDetailDrawer — Keep "View Application" Navigation for Viewers

**File:** `src/components/applications/ApplicationDetailDrawer.tsx`

**Current code (line ~159-166):**
```tsx
{canEditDP && (
  <button onClick={() => onNavigateToEdit(application.id)} ...>
    Edit Application
  </button>
)}
```

**Fix:** Always show the navigation button, but change the label based on role:
```tsx
<button onClick={() => onNavigateToEdit(application.id)} ...>
  {canEditDP ? 'Edit Application' : 'View Application'}
  <ArrowRight className="w-4 h-4" />
</button>
```

This lets viewers navigate to ApplicationPage to see full details. The ApplicationForm already has `isReadOnly={!canWrite}` which hides Save and disables inputs.

---

## Fix 3: Verify ApplicationPage Read-Only Mode Works End-to-End

**File:** `src/pages/ApplicationPage.tsx`, `src/components/ApplicationForm.tsx`

**Already done (verify still correct):**
- `ApplicationForm.tsx` line 132: `const isReadOnly = (isConsumer && !!initialData) || !canWrite;`
- This hides the Save button and disables inputs for viewers ✅

**Check:**
- DeploymentsTab `isReadOnly={relationshipType === 'consumer' || !canEditDP}` — correct ✅
- Delete button gated with `isWorkspaceAdmin` — correct ✅

**No changes needed** — just verify viewers see the form fields in disabled state.

---

## Fix 4: Verify All Drawers Still Open for Viewers

**Verify these still work (they should — row clicks are NOT gated):**

| Drawer | Parent | Row Click Handler | Status |
|--------|--------|-------------------|--------|
| ApplicationDetailDrawer | DashboardPage.tsx | `handleRowClick` → `setSelectedApplicationId` | Should work ✅ |
| IdeaDetailDrawer | IdeasTab.tsx | `handleSelectIdea` → `setSelectedIdeaId` | Should work ✅ |
| InitiativeDetailDrawer | RoadmapPage.tsx | `handleSelectInitiative` → `setSelectedInitiativeId` | Should work ✅ |
| ProgramDetailDrawer | ProgramsTab.tsx | `handleSelectProgram` → `setSelectedProgramId` | Should work ✅ |

**If drawers aren't opening:** Debug by checking:
1. Is the table rendering data? (Check `paginated` array isn't empty)
2. Is `usePermissions` throwing or returning unexpected values?
3. Console errors?

---

## Fix 5: Settings Pages — Keep Row-Level Edit/Delete Buttons Hidden, But Keep Name Clickable

**Already done correctly (verify):**
- `SoftwareProductsSettings.tsx`: Action buttons (Pencil, Trash2) wrapped in `{canManageSettings && (...)}` ✅
- `TechnologyCatalogSettings.tsx`: Same ✅
- `ITServiceCatalogSettings.tsx`: Same ✅

**Product/service name clicks** should NOT be gated — they're the only way to view details. These are currently NOT gated and should stay that way.

---

## Implementation Order

1. **Fix 2** first (quickest win — change "Edit Application" to always-visible "View/Edit Application")
2. **Fix 1** (settings modals — add read-only support or save-guard)
3. **Fix 4** (browser verification as viewer)
4. Run `npx tsc --noEmit` — zero errors
5. Test as viewer user, then test as admin (no regression)

---

## Key Files

| File | Change |
|------|--------|
| `src/components/applications/ApplicationDetailDrawer.tsx` | Always show nav button, dynamic label |
| `src/pages/settings/SoftwareProductsSettings.tsx` | Pass `isReadOnly` to modal OR guard save |
| `src/pages/settings/TechnologyCatalogSettings.tsx` | Same |
| `src/pages/settings/ITServiceCatalogSettings.tsx` | Same |
| `src/components/TechnologyProductModal.tsx` | May need `isReadOnly` prop (check first) |
| `src/hooks/usePermissions.ts` | Already complete — no changes |
| `src/contexts/AuthContext.tsx` | Already complete — no changes |

---

## Test Plan

1. Log in as `smholtby+rstrctdusr@gmail.com` / `pKCfo2ot3ze`
2. **Dashboard (App Health):** Click an app row → drawer opens → "View Application" button visible → clicking it navigates to read-only app page
3. **Roadmap Initiatives:** Click an initiative → drawer opens → no Edit button → view details ✅
4. **Roadmap Ideas:** Click an idea → drawer opens → no review actions → view details ✅
5. **Roadmap Programs:** Click a program → drawer opens → no Edit button → view details ✅
6. **Settings > Software Products:** Click a product name → modal opens → fields disabled, no Save button
7. **Settings > Technology Catalog:** Click a tech product name → modal opens → fields disabled, no Save button
8. **Settings > IT Services:** Click a service name → modal opens → fields disabled, no Save button
9. **Settings > Portfolios:** See portfolios, no Add/Edit/Delete buttons
10. Switch to admin user → verify ALL edit functionality still works
