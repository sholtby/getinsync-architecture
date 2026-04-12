## Task: Generate SQL scripts for the multi-server deployment profile schema

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The current `deployment_profiles.server_name` is a single text column — one server label per DP. Real-world data (City of Garland — 363 apps) shows many applications deploy across multiple servers (web, database, application servers). We are replacing this with a proper many-to-many: a `servers` reference table, a `server_role_types` reference table, and a `deployment_profile_servers` junction table. Full spec at `docs-architecture/features/technology-health/multi-server-dp-design.md`.

### Hard rules

1. **Branch:** `feat/multi-server-schema`. Create from `dev`.
2. **You MUST NOT execute any SQL.** Generate `.sql` files only — Stuart applies via Supabase SQL Editor.
3. **You MUST NOT modify any TypeScript, React, or Edge Function files.** This session is SQL-only.
4. **Output directory:** `docs-architecture/planning/sql/multi-server/` (create it).
5. **Follow existing schema patterns exactly.** Use the schema reference and new-table checklist to match GRANT, RLS, audit trigger, and comment conventions.
6. **Use the read-only DB connection** (`DATABASE_READONLY_URL` in `.env`) to verify existing patterns: how `data_centers` table is structured (your model for `servers`), how `application_contacts` junction works (your model for `deployment_profile_servers`), what reference tables look like.
7. **All views must use `security_invoker = true`.**
8. **Supabase SQL Editor rule:** Each `.sql` file should end with ONE consolidated verification SELECT (CTE + UNION ALL with `(ord, section, details)` shape) — the Editor only shows the last result set.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - The full spec. Pay attention to "Schema Design" section.

2. docs-architecture/operations/new-table-checklist.md
   - Checklist for every new table: GRANT, RLS, audit trigger, comments.

3. docs-architecture/identity-security/rls-policy-addendum.md
   - RLS policy patterns. servers follows data_centers pattern (namespace-scoped).

4. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "data_centers" to find the namespace-scoped reference table pattern.
   - Search for "application_contacts" to find the junction table pattern.
   - Search for "server_role_types" to confirm it does NOT exist yet.
   - Search for "server_name" to find the column on deployment_profiles and the index.
```

### Step 2 — Verify patterns via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Check data_centers table structure (model for servers)
psql "$DATABASE_READONLY_URL" -c "\d public.data_centers"

# Check application_contacts junction (model for deployment_profile_servers)
psql "$DATABASE_READONLY_URL" -c "\d public.application_contacts"

# Check a reference table pattern (model for server_role_types)
psql "$DATABASE_READONLY_URL" -c "\d public.integration_method_types"

# Check existing server_name data for migration planning
psql "$DATABASE_READONLY_URL" -c "SELECT namespace_id, server_name, count(*) FROM deployment_profiles WHERE server_name IS NOT NULL GROUP BY namespace_id, server_name ORDER BY namespace_id, server_name"

# Check vw_server_technology_report definition (will be rewritten)
psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_viewdef('vw_server_technology_report', true)"

# Check vw_application_infrastructure_report definition
psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_viewdef('vw_application_infrastructure_report', true)"

# Check vw_technology_tag_lifecycle_risk definition
psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_viewdef('vw_technology_tag_lifecycle_risk', true)"
```

### Step 3 — Generate SQL files

Create these 4 files in `docs-architecture/planning/sql/multi-server/`:

**`01-tables.sql`** — CREATE TABLE for all 3 tables:

- `servers` (namespace-scoped):
  - `id uuid DEFAULT gen_random_uuid() PRIMARY KEY`
  - `namespace_id uuid NOT NULL REFERENCES namespaces(id)`
  - `name text NOT NULL`
  - `os text` (nullable)
  - `data_center_id uuid REFERENCES data_centers(id)` (nullable)
  - `status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'decommissioned'))`
  - `notes text`
  - `created_at timestamptz DEFAULT now()`
  - `updated_at timestamptz DEFAULT now()`
  - UNIQUE on `(namespace_id, name)`
  - Index on `namespace_id`
  - GRANT ALL to authenticated, service_role
  - Audit trigger (match existing pattern)
  - Table + column comments

- `server_role_types` (standard reference table):
  - Follow `integration_method_types` pattern exactly
  - Seed 6 rows: database (10), web (20), application (30), file (40), utility (50), other (60)
  - GRANT ALL to authenticated, service_role

- `deployment_profile_servers` (junction):
  - `id uuid DEFAULT gen_random_uuid() PRIMARY KEY`
  - `deployment_profile_id uuid NOT NULL REFERENCES deployment_profiles(id) ON DELETE CASCADE`
  - `server_id uuid NOT NULL REFERENCES servers(id) ON DELETE RESTRICT`
  - `server_role text` (nullable — unknown for migrated data; soft reference to server_role_types.code)
  - `is_primary boolean NOT NULL DEFAULT false`
  - `created_at timestamptz DEFAULT now()`
  - UNIQUE on `(deployment_profile_id, server_id)`
  - Indexes on both FK columns
  - GRANT ALL to authenticated, service_role
  - Audit trigger

**`02-rls.sql`** — RLS policies for all 3 tables:

- `servers`: namespace-scoped (match `data_centers` RLS pattern). Viewers+ can SELECT, editors+ can INSERT/UPDATE, admins can DELETE.
- `server_role_types`: reference table pattern. Authenticated can SELECT. Admins can INSERT/UPDATE/DELETE.
- `deployment_profile_servers`: inherit from deployment_profiles workspace/namespace scope. Match `application_contacts` RLS pattern.

**`03-migration.sql`** — Data migration from `server_name`:

- Extract distinct `(namespace_id, server_name)` pairs from `deployment_profiles` where `server_name IS NOT NULL`
- Resolve `namespace_id` by joining through `deployment_profiles → workspaces → namespaces` (or however the chain works — verify via DB)
- INSERT into `servers` with `status = 'active'`, `os = NULL`, `data_center_id = NULL`
- For each DP with non-null `server_name`, INSERT into `deployment_profile_servers` with `is_primary = true`, `server_role = NULL`
- Use `ON CONFLICT DO NOTHING` for idempotency
- Wrap in `BEGIN; ... COMMIT;`
- Do NOT drop the `server_name` column

**`04-views.sql`** — View rewrites + new view:

- Rewrite `vw_server_technology_report`: JOIN through `deployment_profile_servers → servers` instead of grouping by text `server_name`. Add `server_id`, `server_os`, `server_status`, `data_center_name` columns. Keep existing columns (deployment_count, application_count, primary_os, etc.).
- Rewrite `vw_application_infrastructure_report`: Replace single `server_name` with aggregated `server_names` (string_agg or json_agg). Keep `server_name` as first/primary server for backward compat.
- Rewrite `vw_technology_tag_lifecycle_risk`: Same pattern — aggregate servers.
- Create new `vw_server_deployment_summary`: server-centric view per the spec. Columns: server_id, server_name, server_os, server_status, data_center_name, namespace_id, deployment_profile_id, deployment_profile_name, server_role, is_primary, application_id, application_name, workspace_id, workspace_name, environment, tech_health.
- All views: `security_invoker = true`
- Each view replacement: `CREATE OR REPLACE VIEW` (or `DROP VIEW` + `CREATE VIEW` if columns changed)

### Step 4 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add docs-architecture/planning/sql/multi-server/
git commit -m "feat: multi-server DP SQL scripts (tables, RLS, migration, views)"
git push -u origin feat/multi-server-schema
```

### Done criteria checklist

- [ ] 4 SQL files in `docs-architecture/planning/sql/multi-server/`
- [ ] `01-tables.sql`: 3 tables with GRANT, audit triggers, comments, seed data
- [ ] `02-rls.sql`: RLS policies for all 3 tables matching existing patterns
- [ ] `03-migration.sql`: Idempotent migration wrapped in transaction, handles NULL server_name gracefully
- [ ] `04-views.sql`: 3 view rewrites + 1 new view, all with `security_invoker = true`
- [ ] Each file ends with a consolidated verification SELECT
- [ ] `server_name` column NOT dropped from `deployment_profiles`
- [ ] Branch pushed to `feat/multi-server-schema`

### What NOT to do

- Do NOT execute any SQL — Stuart applies via Supabase SQL Editor
- Do NOT drop the `server_name` column — that is a future cleanup task
- Do NOT create or modify any TypeScript files
- Do NOT modify any files under `src/` or `supabase/functions/`
- Do NOT modify architecture docs (that is Session 06)
- Do NOT add CHECK constraints referencing `server_role_types.code` on the junction — use soft text reference (same pattern as other reference table codes in the codebase)
