# Session Prompt 03 — Multi-Server DP: Server Tag Picker + DP Forms + Server Management Page

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: Session 02 must be merged to `dev`.
> Estimated: 60-90 min. This is the largest session.

---

## Task: Build the ServerTagPicker component, replace server_name inputs in DP forms, and create the Server Management settings page

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

Sessions 01 and 02 built the database schema and TypeScript types for the multi-server model. This session builds the UI: a reusable server tag picker component, updates both DP edit forms to use it, and creates a Server Management settings page for CRUD operations on the `servers` table.

### Hard rules

1. **Branch:** `feat/multi-server-ui`. Create from `dev`.
2. **Run `npx tsc --noEmit` AND `npm run build` before committing.** Both must pass.
3. **Reuse existing components.** The `ContactPicker.tsx`, `SearchableSelect.tsx`, `ApplicationContactsEditor.tsx`, and `LeadershipEditor.tsx` are your reference patterns. Do NOT build from scratch what already exists.
4. **Follow `DataCentersSettings.tsx` exactly** for the server management page pattern.
5. **All dropdowns fetch from reference tables.** Server role dropdown comes from `server_role_types`.
6. **Use `TablePagination` for the server management page.**

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - Section "UI Design" — full spec for tag picker, form changes, and management page

2. src/components/shared/SearchableSelect.tsx
   - Headless UI Combobox pattern for multi-select typeahead

3. src/components/applications/ApplicationContactsEditor.tsx
   - Multi-contact per-role picker with inline add pattern

4. src/components/shared/LeadershipEditor.tsx
   - Role assignment + primary indicator (Crown icon) pattern

5. src/pages/settings/DataCentersSettings.tsx
   - Modal-based namespace-scoped CRUD page pattern — your template for ServersSettings

6. src/components/applications/DeploymentProfileCard.tsx (lines 320-350)
   - Current server_name input + datalist to replace

7. src/components/DeploymentProfileModal.tsx (lines 575-600)
   - Current server_name input + datalist to replace

8. src/hooks/useDeploymentProfileEditor.ts
   - Updated in Session 02 — understand the new server data flow

9. src/hooks/useServerManagement.ts
   - Created in Session 02 — CRUD operations you'll call from UI

10. docs-architecture/operations/screen-building-guidelines.md
    - Layout standards for new pages
```

### Step 2 — Impact analysis

```bash
grep -r "serverNameSuggestions" src/ --include="*.ts" --include="*.tsx"
grep -r "server-names-" src/ --include="*.tsx"
grep -r "modal-server-name" src/ --include="*.tsx"
grep -r "DeploymentProfileCard" src/ --include="*.tsx"
grep -r "DeploymentProfileModal" src/ --include="*.tsx"
grep -rn "data-centers" src/App.tsx
grep -rn "Data Centers" src/components/Sidebar.tsx
```

### Step 3 — Build ServerTagPicker component

Create `src/components/shared/ServerTagPicker.tsx`:

**Props interface:**
```typescript
interface ServerTagPickerProps {
  servers: DeploymentProfileServer[];        // Currently linked servers for this DP
  availableServers: Server[];                 // All servers in namespace (for typeahead)
  serverRoleTypes: ServerRoleType[];          // Reference table for role dropdown
  onChange: (servers: DeploymentProfileServer[]) => void;
  onCreateServer: (name: string) => Promise<Server>;  // Inline server creation
  disabled?: boolean;
}
```

**Behavior:**
- Headless UI Combobox for typeahead search over `availableServers`
- Selected servers render as chips/pills: `ServerName (role)` with X remove button
- Each chip has a role dropdown populated from `serverRoleTypes`
- Star toggle on each chip for `is_primary` — only one primary at a time (toggling one off the others)
- When user types a name with no match, show "Create server: [name]" option → calls `onCreateServer`
- Exclude already-linked servers from the suggestion list
- Empty state: show placeholder "Search or add a server..."

**Style:** Match existing chip/badge patterns in the app. Use Tailwind classes consistent with `ApplicationContactsEditor` and `LeadershipEditor`.

### Step 4 — Update DeploymentProfileCard

In `src/components/applications/DeploymentProfileCard.tsx`:

- Remove the `<input type="text" list="server-names-{profile.id}">` + `<datalist>` block (~lines 327-347)
- Replace with `<ServerTagPicker>` wired to the profile's servers from the hook
- Wire `onChange` to save junction records via `useServerManagement.saveProfileServers()`
- Wire `onCreateServer` to `useServerManagement.createServer()`
- Pass `availableServers` and `serverRoleTypes` from the hook's reference data
- Remove `serverNameSuggestions` from the component's props if it was a direct prop (it may come from the hook instead — check)

### Step 5 — Update DeploymentProfileModal

In `src/components/DeploymentProfileModal.tsx`:

- Same replacement as Step 4: remove the `<input>` + `<datalist>` block (~lines 580-595)
- Replace with `<ServerTagPicker>`
- For the modal flow: load existing junction records when editing, track changes in form state, save on modal submit
- For new DP creation: collect server selections in form state, save junction records after the DP INSERT returns the new DP id

### Step 6 — Create Server Management Settings Page

Create `src/pages/settings/ServersSettings.tsx` following `DataCentersSettings.tsx` pattern:

**Layout:**
- Page header: "Servers" with "+ Add Server" button (namespace admin only)
- Table columns: Name, OS, Data Center (name from join), Status (badge), Linked DPs (count), Actions (edit/decommission)
- Search by name (text input filter)
- Filter by status (active/decommissioned toggle)
- `TablePagination` at bottom (default 10 rows)
- Modal for create/edit: Name (required), OS (optional text), Data Center (dropdown from `data_centers`), Status (dropdown), Notes (textarea)
- Decommission action: sets status to 'decommissioned', shows warning if DPs are still linked ("This server is linked to N deployment profiles. Decommissioning will NOT remove those links.")
- Delete action: only available if no linked DPs (junction ON DELETE RESTRICT will block)

**Routing:**
- Add route to `src/App.tsx` at path `/settings/organization/servers` (near the `data-centers` route)
- Add "Servers" nav link to `src/components/Sidebar.tsx` under the Organization section, near "Data Centers"

### Step 7 — Verify

```bash
npx tsc --noEmit
npm run build
```

Both must pass.

### Step 8 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/shared/ServerTagPicker.tsx src/pages/settings/ServersSettings.tsx src/components/applications/DeploymentProfileCard.tsx src/components/DeploymentProfileModal.tsx src/hooks/useDeploymentProfileEditor.ts src/App.tsx src/components/Sidebar.tsx
git commit -m "feat: server tag picker, DP form updates, server management page"
git push -u origin feat/multi-server-ui
```

### Done criteria checklist

- [ ] `npx tsc --noEmit` passes
- [ ] `npm run build` succeeds
- [ ] `ServerTagPicker` renders chips with role dropdowns and primary star toggle
- [ ] `DeploymentProfileCard` uses ServerTagPicker instead of text input
- [ ] `DeploymentProfileModal` uses ServerTagPicker instead of text input
- [ ] Server Management page loads at `/settings/organization/servers`
- [ ] Server Management has full CRUD: create, edit, decommission, delete (when no links)
- [ ] Sidebar shows "Servers" link under Organization
- [ ] Pagination works on server management page
- [ ] No hardcoded dropdown values — role types fetched from `server_role_types`

### What NOT to do

- Do NOT touch `src/components/visual/` — that is Session 04
- Do NOT touch `src/components/technology-health/` — that is Session 05
- Do NOT touch `supabase/functions/` — that is Session 06
- Do NOT touch `docs-architecture/` — that is Session 06
- Do NOT delete `server_name` from any types or database — transition period
- Do NOT create a new pagination component — use `TablePagination`
