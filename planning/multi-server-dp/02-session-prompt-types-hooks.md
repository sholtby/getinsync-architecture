## Task: Add TypeScript types and refactor hooks for the multi-server deployment profile model

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

Session 01 created 3 new database tables (`servers`, `server_role_types`, `deployment_profile_servers`) and rewrote 4 views. This session updates the TypeScript layer to match: new interfaces, updated view contracts, and a refactored `useDeploymentProfileEditor` hook that fetches/saves server data through the junction table instead of the text `server_name` column.

### Hard rules

1. **Branch:** `feat/multi-server-types`. Create from `dev`.
2. **You MAY only modify files in `src/types/` and `src/hooks/`.** Do not touch UI components.
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Keep backward compatibility** — `server_name` stays on `DeploymentProfile` interface during transition. `serverNameSuggestions` must still flow to consumers (derived from the `servers` table now).
5. **Use the read-only DB connection** to verify the new view definitions exist before writing TypeScript types.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - Sections: "Schema Design" and "TypeScript Type Changes"

2. src/types/index.ts (lines 111-211)
   - Current DeploymentProfile, CreateDeploymentProfileInput, UpdateDeploymentProfileInput interfaces
   - Note server_name field at line 129

3. src/types/view-contracts.ts (lines 280-373)
   - ServerTechnologyReportRow (lines 361-370)
   - VwApplicationInfrastructureReportRow (lines 281-301)
   - VwDeploymentProfileTechnologyRow (lines 330-355)

4. src/hooks/useDeploymentProfileEditor.ts (full file)
   - serverNameSuggestions state (line 112)
   - fetchLocations() server name loading (lines 189-199)
   - handleSave() server_name in updateData (line 260)

5. src/components/applications/ApplicationContactsEditor.tsx (first 50 lines)
   - Junction table CRUD pattern reference
```

### Step 2 — Verify schema exists via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm new tables exist
psql "$DATABASE_READONLY_URL" -c "\d public.servers"
psql "$DATABASE_READONLY_URL" -c "\d public.server_role_types"
psql "$DATABASE_READONLY_URL" -c "\d public.deployment_profile_servers"

# Confirm view definitions match expected columns
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_server_technology_report' ORDER BY ordinal_position"
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_server_deployment_summary' ORDER BY ordinal_position"
```

If any table/view is missing, STOP and tell Stuart "Session 01 SQL hasn't been fully applied yet."

### Step 3 — Impact analysis

```bash
grep -r "serverNameSuggestions" src/ --include="*.ts" --include="*.tsx"
grep -r "ServerTechnologyReportRow" src/ --include="*.ts" --include="*.tsx"
grep -r "VwApplicationInfrastructureReportRow" src/ --include="*.ts" --include="*.tsx"
grep -r "VwDeploymentProfileTechnologyRow" src/ --include="*.ts" --include="*.tsx"
grep -r "server_name" src/ --include="*.ts" --include="*.tsx"
```

Record all consumers — you must ensure they still compile after your changes.

### Step 4 — Add new interfaces to `src/types/index.ts`

Add near the DeploymentProfile section:

```typescript
// --- Servers (Multi-Server DP) ---

export interface Server {
  id: string;
  namespace_id: string;
  name: string;
  os: string | null;
  data_center_id: string | null;
  status: 'active' | 'decommissioned';
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ServerRoleType {
  code: string;
  name: string;
}

export interface DeploymentProfileServer {
  id: string;
  deployment_profile_id: string;
  server_id: string;
  server_role: string | null;
  is_primary: boolean;
  created_at: string;
  // Hydrated from join
  server?: Server;
}
```

### Step 5 — Update view contracts in `src/types/view-contracts.ts`

- **ServerTechnologyReportRow:** Add `server_id: string`, `server_os: string | null`, `server_status: string`, `data_center_name: string | null`. Keep existing fields.
- **VwApplicationInfrastructureReportRow:** Add `server_names: string | null` (aggregated from view). Keep `server_name` for backward compat.
- **VwDeploymentProfileTechnologyRow:** Same — add `server_names` alongside `server_name`.
- **Add new interface `VwServerDeploymentSummaryRow`** matching the new view columns (server_id, server_name, server_os, server_status, data_center_name, namespace_id, deployment_profile_id, deployment_profile_name, server_role, is_primary, application_id, application_name, workspace_id, workspace_name, environment, tech_health).

### Step 6 — Create `src/hooks/useServerManagement.ts`

New hook for server CRUD operations, namespace-scoped. Used by both the Server Management page (Session 03) and the server tag picker.

Exports:
- `servers: Server[]` — all servers in the namespace
- `serverRoleTypes: ServerRoleType[]` — from reference table
- `loading: boolean`
- `fetchServers()` — load from `servers` table filtered by namespace_id
- `fetchServerRoleTypes()` — load from `server_role_types` where is_active = true
- `createServer(name: string): Promise<Server>` — insert + return
- `updateServer(id: string, updates: Partial<Server>): Promise<void>`
- `deleteServer(id: string): Promise<void>` — will fail if junction rows exist (ON DELETE RESTRICT)
- `getProfileServers(profileId: string): Promise<DeploymentProfileServer[]>` — fetch from junction + join servers
- `saveProfileServers(profileId: string, links: Array<{server_id: string, server_role: string | null, is_primary: boolean}>): Promise<void>` — delete existing + insert new (transactional)

Follow error handling patterns: try/catch with toast notifications on error.

### Step 7 — Refactor `src/hooks/useDeploymentProfileEditor.ts`

- Replace `serverNameSuggestions: string[]` state with servers loaded from `useServerManagement` hook (or inline the fetch if the hook isn't imported here).
- Derive `serverNameSuggestions` from `servers.map(s => s.name)` for backward compat — components still need this during transition.
- In `handleSave()`: after saving the DP record, call `saveProfileServers()` to sync the junction table. Keep writing `server_name` to the DP record as the primary server name for backward compat.
- Add `serverRoleTypes` to the returned reference data.
- Add a `loadProfileServers()` call in the profile loading flow so each profile has its servers available.

### Step 8 — Verify

```bash
npx tsc --noEmit
```

Must pass with zero errors. All existing consumers of changed types must still compile.

### Step 9 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/types/index.ts src/types/view-contracts.ts src/hooks/useServerManagement.ts src/hooks/useDeploymentProfileEditor.ts
git commit -m "feat: multi-server DP types + hooks (Server, DeploymentProfileServer, useServerManagement)"
git push -u origin feat/multi-server-types
```

### Done criteria checklist

- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] 3 new interfaces in `src/types/index.ts` (Server, ServerRoleType, DeploymentProfileServer)
- [ ] View contracts updated (ServerTechnologyReportRow expanded, new VwServerDeploymentSummaryRow)
- [ ] `src/hooks/useServerManagement.ts` created with full CRUD + junction management
- [ ] `useDeploymentProfileEditor` refactored — fetches servers from table, derives serverNameSuggestions for backward compat
- [ ] `server_name` NOT removed from DeploymentProfile interface
- [ ] All existing consumers still compile (grep results from Step 3)

### What NOT to do

- Do NOT update UI components — that is Session 03
- Do NOT remove `server_name` from the DeploymentProfile interface — keep for transition
- Do NOT touch DPNode.tsx, dashboard components, or AI chat tools
- Do NOT run `npm run build` (type check is sufficient for this session)
- Do NOT modify any SQL files or database schema
