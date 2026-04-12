# Multi-Server Deployment Profile Design

**Version:** 1.0
**Date:** April 12, 2026
**Status:** DRAFT
**Author:** Stuart Holtby + Claude
**Relates to:** `core/deployment-profile.md`, `adr/adr-dp-infrastructure-boundary.md`, `features/technology-health/dashboard.md`

---

## Problem Statement

The current schema allows only one `server_name` per Deployment Profile. Real-world data (e.g., City of Garland — 363 apps, 7,646 assessments) shows that many applications deploy across multiple servers: a web server, database server, application server, and sometimes file/utility servers. The current model forces a choice of "primary" server and loses the rest.

Additionally, a single physical server often hosts multiple deployment profiles. The current text-based `server_name` field supports this implicitly (multiple DPs can share the same string), but there is no normalized entity to query, no attributes on the server itself, and no role context for the relationship.

---

## Goals

1. **Many-to-many relationship** between Deployment Profiles and Servers
2. **Role context** on each link (database, web, application, file, utility)
3. **Server as a light reference entity** with optional attributes (OS, data center, status)
4. **Backward compatibility** — existing `server_name` data migrated cleanly
5. **Improve downstream consumers:**
   - Visual tab: show servers on DP nodes
   - AI Chat: inform the model of all servers per application
   - Dashboards: server-centric views ("what runs on this box?")

---

## Non-Goals

- Full CMDB CI modeling (ServiceNow owns that — see ADR)
- Inbound sync from ServiceNow
- Server discovery or inventory scanning
- Network topology or IP address tracking

---

## Schema Design

### New Table: `servers`

Namespace-scoped server reference. Follows the same scoping pattern as `data_centers`.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `namespace_id` | uuid | NOT NULL, FK `namespaces(id)` | Namespace scoping |
| `name` | text | NOT NULL | Display name, e.g. "PROD-SQL-01" |
| `os` | text | | Optional OS label, e.g. "Windows Server 2022" |
| `data_center_id` | uuid | FK `data_centers(id)` | Optional link to existing data_centers table |
| `status` | text | CHECK `active`/`decommissioned`, default `active` | Soft lifecycle |
| `notes` | text | | Free-form |
| `created_at` | timestamptz | default `now()` | |
| `updated_at` | timestamptz | trigger-maintained | |

**Constraints:**
- UNIQUE on `(namespace_id, name)` — no duplicate server names within a namespace
- RLS: namespace-scoped (viewers can read, editors+ can write)
- Audit trigger: yes
- GRANT ALL to `authenticated`, `service_role`

### New Table: `server_role_types`

Standard reference table for server roles in the junction.

| Column | Type | Notes |
|--------|------|-------|
| Standard reference table pattern | | `id`, `code`, `name`, `description`, `display_order`, `is_active`, `is_system`, `created_at` |

**Seed data:**

| code | name | display_order |
|------|------|---------------|
| `database` | Database Server | 10 |
| `web` | Web Server | 20 |
| `application` | Application Server | 30 |
| `file` | File Server | 40 |
| `utility` | Utility Server | 50 |
| `other` | Other | 60 |

### New Table: `deployment_profile_servers`

Junction table for the many-to-many relationship.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default `gen_random_uuid()` | |
| `deployment_profile_id` | uuid | NOT NULL, FK `deployment_profiles(id)` ON DELETE CASCADE | |
| `server_id` | uuid | NOT NULL, FK `servers(id)` ON DELETE RESTRICT | Can't delete a server still linked to DPs |
| `server_role` | text | FK reference to `server_role_types.code` | Role this server plays for this DP |
| `is_primary` | boolean | default `false` | Marks the "main" server for backward compat / display priority |
| `created_at` | timestamptz | default `now()` | |

**Constraints:**
- UNIQUE on `(deployment_profile_id, server_id)` — no duplicate links
- RLS: inherited from DP's workspace/namespace scope
- Audit trigger: yes
- GRANT ALL to `authenticated`, `service_role`

### Migration Strategy for `deployment_profiles.server_name`

1. **Extract:** Deduplicate existing `server_name` values per namespace → INSERT into `servers` (with `status = 'active'`, no OS/data_center yet)
2. **Link:** For each DP with a non-null `server_name`, create a `deployment_profile_servers` row with `is_primary = true`, `server_role = NULL` (unknown from legacy data)
3. **Preserve:** Keep `server_name` column temporarily as read-only fallback during transition
4. **Deprecate:** After all consumers are migrated, drop `server_name` column in a future release

### Views to Update

| View | Change |
|------|--------|
| `vw_server_technology_report` | Rewrite to join through `deployment_profile_servers` → `servers`; group by `servers.id` instead of free-text `server_name` |
| `vw_application_infrastructure_report` | Replace single `server_name` with aggregated server list (JSON array or comma-separated) |
| `vw_technology_tag_lifecycle_risk` | Same — aggregate servers instead of single column |

### New View: `vw_server_deployment_summary`

Server-centric view answering "what runs on this server?"

| Column | Source |
|--------|--------|
| `server_id` | `servers.id` |
| `server_name` | `servers.name` |
| `server_os` | `servers.os` |
| `server_status` | `servers.status` |
| `data_center_name` | `data_centers.name` |
| `namespace_id` | `servers.namespace_id` |
| `deployment_profile_id` | `deployment_profile_servers.deployment_profile_id` |
| `deployment_profile_name` | `deployment_profiles.name` |
| `server_role` | `deployment_profile_servers.server_role` |
| `is_primary` | `deployment_profile_servers.is_primary` |
| `application_id` | `deployment_profiles.application_id` |
| `application_name` | `applications.name` |
| `workspace_id` | `deployment_profiles.workspace_id` |
| `workspace_name` | `workspaces.name` |
| `environment` | `deployment_profiles.environment` |
| `tech_health` | `deployment_profiles.tech_health` |

---

## UI Design

### DP Edit Forms (DeploymentProfileCard + DeploymentProfileModal)

**Current:** Single text input with autocomplete for `server_name`.

**New: Server Tag Picker**
- Multi-select typeahead input showing existing servers for the namespace
- Type a name → see matching servers; select to add
- If no match → option to create a new server inline (creates `servers` row)
- Each tagged server displays as a chip/pill: `PROD-SQL-01 (database)`
- Each chip has a role selector dropdown (from `server_role_types`)
- One server can be toggled as primary (star icon)
- Remove button (X) on each chip to unlink

### Visual Tab (DPNode)

**Current:** Shows single `server_name` as gray text on DP nodes at all zoom levels.

**New rendering by zoom level:**

| Level | Rendering |
|-------|-----------|
| Level 1 (Compact) | Primary server name only — backward compatible appearance |
| Level 2 (Enriched) | Primary server name + count badge if more, e.g. "PROD-SQL-01 +2" |
| Level 3 (Hero) | All servers with roles as a mini-list inside the node card |

**Future (out of scope):** Add server nodes as a new tier in the ReactFlow graph below DPs, with edges showing role relationships. This would create a four-tier visual: Application → DP → Server → (ServiceNow CIs).

### Technology Health Dashboards

| Component | Change |
|-----------|--------|
| `TechnologyHealthByServer` | Rewrite grouping to use `servers` table; show OS, data center, status columns from the entity |
| `SummaryApplicationTable` | Show server list (comma-separated or pill display) instead of single `server_name` |
| `TechnologyHealthByApplication` | Same — multi-server display in secondary text |
| `TechnologyHealthSummary` (CSV export) | Export all servers per DP (pipe-delimited or one row per server) |

### New: Server Management Page

Accessible from namespace settings or Technology Health section.

**Features:**
- List all servers in the namespace with: name, OS, data center, status, linked DP count
- Inline edit for OS, data center, status, notes
- Decommission action (sets status, warns if DPs still linked)
- Standard pagination via `TablePagination`
- Search/filter by name, status, data center

### AI Chat Tools

Update the servers context builder in `supabase/functions/ai-chat/tools.ts`:

**Current output:**
```
- PROD-SQL-01 (Production MSSQL)
```

**New output:**
```
- PROD-SQL-01 (database) → AppName / Production MSSQL
- PROD-APP-01 (application) → AppName / Production IIS
```

Support new query patterns:
- "What applications run on PROD-SQL-01?"
- "Which servers does AppX use?"
- "Show me all database servers"

---

## ADR Update

The existing `adr/adr-dp-infrastructure-boundary.md` (v1.1) needs a v2.0 amendment:

- **Boundary unchanged:** ServiceNow still owns CI-level infrastructure
- **What changed:** GetInSync now supports multiple server references per DP (many-to-many with roles) instead of a single `server_name` text field
- **Why:** Real-world import data (Garland, others) has multiple named servers per deployment. Forcing a single-server choice loses valuable portfolio intelligence that doesn't require CI-level detail.
- **Still NOT a CMDB CI:** The `servers` table is a portfolio-level reference for grouping and visualization. It stores a name, optional OS, and optional data center link — not operational attributes like IP, FQDN, patching status, or monitoring endpoints.

---

## Impact Analysis

### Files Requiring Changes

**Schema (Stuart applies via SQL Editor):**
- 3 new tables: `servers`, `server_role_types`, `deployment_profile_servers`
- 4 view rewrites: `vw_server_technology_report`, `vw_application_infrastructure_report`, `vw_technology_tag_lifecycle_risk`, plus new `vw_server_deployment_summary`
- Migration script for existing `server_name` data
- RLS policies for all new tables

**TypeScript Types:**
- `src/types/index.ts` — new `Server`, `DeploymentProfileServer` interfaces; update `DeploymentProfile` to include `servers` array
- `src/types/view-contracts.ts` — update `ServerTechnologyReportRow`, `VwApplicationInfrastructureReportRow`; add `VwServerDeploymentSummaryRow`

**Components:**
- `src/components/applications/DeploymentProfileCard.tsx` — replace server_name input with tag picker
- `src/components/DeploymentProfileModal.tsx` — same
- `src/components/visual/nodes/DPNode.tsx` — multi-server rendering
- `src/components/visual/graphBuilders.ts` — pass server array to nodes
- `src/hooks/useVisualGraphData.ts` — query servers through junction
- `src/hooks/useDeploymentProfileEditor.ts` — replace server_name suggestions with server CRUD
- `src/components/technology-health/TechnologyHealthByServer.tsx` — rewrite for entity-based grouping
- `src/components/technology-health/SummaryApplicationTable.tsx` — multi-server display
- `src/components/technology-health/TechnologyHealthByApplication.tsx` — multi-server display
- `src/components/technology-health/TechnologyHealthSummary.tsx` — CSV export update

**Edge Functions:**
- `supabase/functions/ai-chat/tools.ts` — update server context builder

**Architecture Docs:**
- `adr/adr-dp-infrastructure-boundary.md` — v2.0 amendment
- `core/deployment-profile.md` — update server relationship section
- `features/technology-health/dashboard.md` — update server dashboard section
- `core/visual-diagram.md` — update node rendering spec

---

## Phased Delivery

### Phase 1: Schema + Migration + Types
- Create tables, RLS, audit triggers
- Migrate existing `server_name` data
- Update TypeScript types and view contracts
- Run security posture validation

### Phase 2: DP Edit Forms + Server Management
- Build server tag picker component
- Update DeploymentProfileCard and DeploymentProfileModal
- Build server management page
- Update `useDeploymentProfileEditor` hook

### Phase 3: Views + Dashboards
- Rewrite affected views
- Update Technology Health dashboard components
- Update CSV export

### Phase 4: Visual Tab + AI Chat
- Update DPNode rendering for multi-server
- Update graphBuilders and useVisualGraphData
- Update AI Chat tools context builder
- Update AI Chat eval tests

### Phase 5: Cleanup + Docs
- Drop `server_name` column (after confirming no remaining consumers)
- Update ADR and architecture docs
- Update MANIFEST.md

---

## Changelog

- **v1.0 — April 12, 2026** — Initial design spec.
