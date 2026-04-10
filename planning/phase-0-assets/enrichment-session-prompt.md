# Claude Code Session Prompt — City of Riverside Demo Data Enrichment

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> The new session's job is to **write chunked SQL scripts** that Stuart will execute manually in the Supabase SQL Editor. The new session **must not** run INSERT / UPDATE / DELETE against the database itself.

---

## Task: Generate chunked SQL enrichment scripts for the City of Riverside demo namespace

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code until you have completed Step 1 (read required context).

### Why this work exists

GetInSync NextGen is about to publish 19 user-help articles to docs.getinsync.ca. A readiness walk (Phase 0 of the GitBook rollout plan) found that the City of Riverside demo data is **production-like but has gaps** that will make screenshots for 4 specific articles look empty. Your job is to generate SQL scripts Stuart can run in the Supabase SQL Editor to close those gaps — using only existing tables and columns. You are **not** creating schema. You are **not** running the SQL. You are writing idempotent `.sql` files that Stuart will paste into Supabase, chunk by chunk.

### Hard rules (read before touching anything)

1. **You may NOT modify database schema.** No `CREATE TABLE`, `ALTER TABLE`, `CREATE COLUMN`, `DROP`, `TRUNCATE`, `CREATE INDEX`, `CREATE POLICY`, nothing. Only `INSERT` / `UPDATE` into **existing** tables and columns.
2. **You may NOT execute INSERT / UPDATE / DELETE against the database.** The `DATABASE_READONLY_URL` in `.env` is for **SELECT introspection only**. Use it to discover row IDs, column names, reference-table codes, and existing values. Never run writes.
3. **You MUST write idempotent SQL.** Every UPDATE should be safe to re-run (it will simply no-op the second time). Every INSERT must check for existence first (`WHERE NOT EXISTS` / `ON CONFLICT DO NOTHING` where a unique constraint exists). Stuart runs SQL manually and may re-run a chunk if he was unsure whether it took.
4. **You MUST wrap each chunk in a transaction** (`BEGIN;` / `COMMIT;`) with a verification `SELECT` at the end of the chunk (before `COMMIT;`) that prints the rows the chunk touched, so Stuart can eyeball correctness before committing. Use `RAISE NOTICE` or a simple final `SELECT` for the verification.
5. **You MUST stay inside the Riverside namespace.** Namespace ID: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`. Namespace slug: `city-of-riverside-demo`. Every `WHERE` clause that can reach across namespaces must include a namespace scope. If you cannot safely scope a statement, flag it in a `-- SAFETY:` comment and leave it for Stuart to review.
6. **You MUST fetch dropdown values from reference tables.** For example: do not guess `hosting_type` codes — SELECT from `hosting_types` first, pick the `code` column, and use that exact value. Same for `environments`, `dr_statuses`, `integration_method_types`, `integration_frequency_types`, `integration_direction_types`, `integration_status_types`, `criticality_types`, `service_types`, etc. If you cannot find a matching reference table row for a value you want to write, STOP and flag it — do not invent codes.
7. **You MAY create seed contacts and involved-party rows** (the `contacts` master table already has 7 rows in Riverside; you may `INSERT` more into `contacts` and into junction tables like `application_contacts`, `deployment_profile_contacts`, `workspace_contacts`). These are data tables, not schema.
8. **Demo data only.** Every new contact name must be obviously fictional (e.g. "Pat Alvarez", "Jordan Chen", "Morgan Reyes"). No real names, no real phone numbers, no real email domains. Use `@riverside-demo.example` for all emails.

### Step 1 — Read the required context (in this order)

```
1. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/gitbook-phase-0-readiness.md
   - This is your requirements document. It lists the exact enrichment tasks per article.
   - Pay special attention to §2.1, §2.4, §4.2, §4.3 (the four NEEDS ENRICHMENT rows).
   - Section 1.4 has an optional enrichment (on-prem DP operational fields).

2. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md
   - Read the "Architecture Rules" and "Database Access" sections so you understand the
     read-only contract and the reference-table-only rule for dropdowns.

3. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/schema/nextgen-schema-current.sql
   - This is the source of truth for column names and types. When in doubt, grep this file
     for the table you are writing to and confirm every column name.

4. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/core/involved-party.md
   - Contacts / involved-parties data model. Confirms which tables link contacts to apps,
     DPs, and workspaces.

5. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/integrations/architecture.md
   - Integrations DP alignment. Confirms source_deployment_profile_id /
     target_deployment_profile_id column names and constraints.

6. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/cost-model.md
   - Cost model. Confirms where contract_reference / contract_start_date / contract_end_date
     live on it_services.

7. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/budget-management.md
   - Workspace budget structure. Confirms workspace_budgets column names.
```

### Step 2 — Discover the actual data

Use the read-only DB connection to inventory what exists. Example commands you should run (adapt as needed):

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm namespace
psql "$DATABASE_READONLY_URL" -c "SELECT id, name, slug FROM namespaces WHERE slug = 'city-of-riverside-demo';"

# Inventory apps, DPs, integrations, workspaces, IT services, contacts, budgets, reference tables.
# Every one of your enrichment chunks needs real IDs discovered this way.
```

Build a short working notebook (scratch markdown in your head or in a temp file under `/tmp/`) that lists:

- The UUID of the Riverside namespace
- UUIDs and names of 1-2 showcase apps from Police Department workspace (CAD, Hexagon OnCall, NG911)
- UUIDs of their deployment profiles
- UUIDs of the 9 integrations and which DPs (if any) each has
- UUIDs of all 11 IT services and their current `annual_cost`, `contract_reference`, `contract_start_date`, `contract_end_date`
- UUIDs of all 18 workspaces and which 2 already have fiscal-2026 budgets
- UUIDs of the 7 existing `contacts` rows (reuse these before creating new ones)
- Reference-table `code` values you will need: hosting types, environments, contact categories, integration methods, criticality types, etc.

### Step 3 — Write the chunked SQL files

Save every file under:

```
/Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/phase-0-assets/enrichment-sql/
```

Create that directory. Use these exact filenames (sorted execution order matters — Stuart will run them top to bottom):

```
00-verify-state-before.sql          # read-only SELECTs — confirms starting state
01-app-contacts-showcase.sql        # Article 2.1 enrichment — CAD showcase app contacts
02-integrations-dp-alignment.sql    # Article 2.4 — name the ServiceNow row + DP-align 2 more
03-workspace-budgets-fy2026.sql     # Article 4.2 — add budgets for Fire, Public Works, Finance
04-it-service-contracts.sql         # Article 4.3 — add contract data to top-3 IT services
05-deployment-profile-ops-fields.sql  # Article 1.4 OPTIONAL — on-prem DP enrichment
06-cost-bundle-dps-showcase.sql     # Article 4.3 — seed cost_bundle DPs for CAD/Hexagon/NG911
99-verify-state-after.sql           # read-only SELECTs — confirms every chunk landed
```

**Per-file requirements:**

- First line: a `-- Chunk: NN-name.sql` header comment
- Second-block: a `-- Purpose:` comment describing the single article it supports
- Third block: a `-- Preconditions:` comment listing the tables touched and whether this chunk depends on any prior chunk
- Body: `BEGIN;` ... SQL ... a verification `SELECT` ... `COMMIT;`
- End: a one-line `-- Rollback:` comment naming the exact `DELETE` / `UPDATE` statement Stuart could use to reverse the chunk if he wants to undo it later (for demo-data cleanup). Leave rollback as a comment only, not executable SQL.
- Keep each chunk under ~150 lines. If it grows larger, split into `02a-` / `02b-` etc.
- **No cross-chunk transactions.** Each file is independently runnable and independently rollback-able.

### Step 4 — Per-chunk enrichment specifications

Use the readiness report (§2.1, §2.4, §4.2, §4.3, §1.4) as the canonical source. The bullets below are a summary for convenience — if they conflict with the readiness report, the **readiness report wins**.

**01-app-contacts-showcase.sql (Article 2.1 — Managing Applications)**
- Pick one showcase application: `Computer-Aided Dispatch` in Police Department (fallback: `Hexagon OnCall CAD/RMS` or `NG911 System`).
- Ensure ≥2 contacts exist in `contacts` for the Riverside namespace. Reuse existing rows if they fit; otherwise `INSERT` new fictional ones (`@riverside-demo.example` email domain, `contact_category` must be a valid code from the contacts category reference).
- `INSERT` rows into `application_contacts` linking the showcase app to those ≥2 contacts with distinct `role`-like values (owner, primary_support, SME). Check the actual junction table columns in the schema before writing.
- If `applications.owner` / `primary_support` / `expert_contacts` are simple text fields (they appear to be, per readiness report), also `UPDATE` those fields on the same showcase app with the contact names. The readiness report notes these are unpopulated everywhere.
- Also populate `applications.primary_use_case` on the showcase app with a realistic 1-sentence description.
- **Do not touch other apps** — showcase-app scope only.

**02-integrations-dp-alignment.sql (Article 2.4 — Integrations)**
- Confirmed current state: 9 `application_integrations` rows, only 1 has both `source_deployment_profile_id` and `target_deployment_profile_id` set, and that row is unnamed.
- Task A: `UPDATE` the unnamed DP-aligned integration (ServiceNow ITSM → Active Directory Services) to set `name = 'ServiceNow CMDB Sync'` (or similar realistic name).
- Task B: Set `source_deployment_profile_id` and `target_deployment_profile_id` on at least 2 more integrations. Recommended:
  - `Emergency Response ↔ CAD` — use the PROD DPs for both apps.
  - `NG911 → CAD Call Routing` — use the PROD DPs for both apps.
- Discover the PROD DP UUIDs via SELECT. Do not guess.
- Each integration `UPDATE` must be idempotent (`WHERE source_deployment_profile_id IS NULL`).
- While you're there, confirm each enriched integration has `integration_method_types` / `integration_frequency_types` / `integration_direction_types` / `integration_status_types` / `criticality_types` codes that exist in the reference tables.

**03-workspace-budgets-fy2026.sql (Article 4.2 — IT Spend)**
- Current state: only 2 of 18 workspaces (IT, Police) have fiscal-2026 budgets in `workspace_budgets`.
- `INSERT` fiscal-2026 budget rows for 3 additional workspaces: **Fire Department**, **Public Works**, **Finance** (or the nearest matching workspace names — discover actual names in Step 2).
- Realistic amounts:
  - Fire Department: `$1,800,000` budget
  - Public Works: `$1,200,000` budget
  - Finance: `$650,000` budget
- Set `fiscal_year = 2026`, `is_current = true`, `actual_run_rate` left NULL (the overview computes run rate from IT services, not from this column, per readiness report).
- Use `INSERT ... WHERE NOT EXISTS (SELECT 1 FROM workspace_budgets WHERE workspace_id = X AND fiscal_year = 2026)` to keep it idempotent.
- Confirm column list in the schema file before writing — do not use `workspaces.budget_amount` (that column is legacy per CLAUDE.md).

**04-it-service-contracts.sql (Article 4.3 — Cost Analysis, IT-service contract side)**
- Current state: 11 IT services in Riverside, total annual_cost $2,976,000. Zero have contract data.
- Pick the **top 3 IT services by `annual_cost`** (SELECT ORDER BY annual_cost DESC LIMIT 3, scoped to the Riverside namespace via `it_services.namespace_id`).
- For each, `UPDATE` to set:
  - `contract_reference` — a realistic fictional contract number (e.g. `CR-2024-0412`, `CR-2025-0183`, `CR-2023-0904`)
  - `contract_start_date` — a date 1-3 years before today
  - `contract_end_date` — a date 6-24 months in the future from today (gives the `vw_it_service_contract_expiry` view a mix of near-expiry and safe-horizon rows)
- `UPDATE ... WHERE contract_reference IS NULL` for idempotency.
- Do NOT touch `annual_cost` or `budget_amount` — those already match the overview KPI.
- **Do NOT populate `annual_cost` on software products** — per `docs-architecture/features/cost-budget/cost-model.md` §3.1, Software Products are now inventory-only; cost lives on IT Service allocations and Cost Bundle DPs (the two channels per v3.0 of the cost model).

**06-cost-bundle-dps-showcase.sql (Article 4.3 — Cost Analysis, Cost Bundle channel side)**

> **IMPORTANT CONTEXT:** A Cost Bundle is **not a separate table** — it is a deployment profile with `dp_type = 'cost_bundle'`. Read `docs-architecture/features/cost-budget/cost-model.md` §3.3 and §12 (ERD) before writing this chunk. The schema supports cost bundles via these columns on `deployment_profiles`: `dp_type` (set to `'cost_bundle'`), `annual_cost`, `cost_recurrence` (`'recurring'` or `'one_time'`), `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`. Views `vw_portfolio_costs` and `vw_portfolio_costs_rollup` already aggregate `WHERE dp_type = 'cost_bundle' AND cost_recurrence = 'recurring'` into a `bundle_cost` column. The Riverside demo has **zero** cost_bundle DPs today, which is why the CAD app's "Recurring Costs" section shows $0 in the UI. Your job is to seed 2-3 of them so Article 4.3 has real Recurring Costs + renewal-alert content to screenshot.

- **Target applications (showcase):** `Computer-Aided Dispatch`, `Hexagon OnCall CAD/RMS`, `NG911 System` — all in the Police Department workspace. Discover their `application_id` values via SELECT.
- **Insert 2-3 rows into `deployment_profiles`**, one per showcase bundle. Each row must have:
  - `application_id` = showcase app's UUID (so it appears under that app's Recurring Costs)
  - `workspace_id` = Police Department workspace UUID
  - `name` = realistic bundle name (e.g. `"Accela Annual Support Contract"`, `"Hexagon Managed Services Agreement"`, `"Axon Evidence Cloud Hosting"`)
  - `dp_type = 'cost_bundle'` (REQUIRED — this is what makes it a cost bundle)
  - `cost_recurrence = 'recurring'` (so it feeds the run rate — see `cost-model.md` §3.3 and the view predicates)
  - `annual_cost` = a realistic amount (e.g. `$24,000`, `$48,000`, `$18,000`) with type `numeric(12,2)`
  - `vendor_org_id` = a real vendor org in the Riverside namespace (SELECT from `organizations` WHERE namespace_id = riverside and name matches the vendor — e.g. Accela, Hexagon, Axon). If the vendor org does not exist in Riverside, either (a) create it via `INSERT INTO organizations` with sensible defaults, or (b) leave `vendor_org_id NULL` and flag it with a `-- NOTE:` comment.
  - `contract_reference` = realistic fictional PO / agreement number
  - `contract_start_date` = 1-3 years ago
  - `contract_end_date` = 3-15 months in the future (mix of near-expiry and safe horizons)
  - `renewal_notice_days` = 90 (default)
  - `hosting_type` should be blank/unset for cost bundles — cost_bundle DPs aren't "running" so hosting/environment/DR fields don't apply. Leave NULL.
  - `is_primary = false` (the primary DP is the application DP, not the bundle)
  - Any other required NOT NULL columns discovered from the schema file — fill with sensible defaults
- **Idempotency:** `INSERT ... WHERE NOT EXISTS (SELECT 1 FROM deployment_profiles WHERE application_id = X AND name = Y AND dp_type = 'cost_bundle')`. Re-running the chunk must not create duplicates.
- **Verification SELECT (before COMMIT):** query the showcase apps' Recurring Cost total by summing `annual_cost` where `dp_type = 'cost_bundle' AND cost_recurrence = 'recurring' AND application_id IN (...)`. Should return the sum of the bundles you just inserted.
- **Verification SELECT (nice-to-have):** also select from `vw_portfolio_costs` for the showcase apps and confirm the `bundle_cost` column now shows non-zero values.
- **Rollback comment:** a `DELETE FROM deployment_profiles WHERE dp_type = 'cost_bundle' AND application_id IN (...) AND name IN (...)` statement that Stuart can use to remove only the rows this chunk inserted.
- **Safety:** stay inside `application_id IN (<the three showcase apps>)`. Do not touch any other application's deployment profiles.
- **Do NOT** modify the application DP or any existing non-bundle DPs. This chunk is additive only.

**05-deployment-profile-ops-fields.sql (Article 1.4 — OPTIONAL)**
- Pick one on-prem DP: recommended `Computer-Aided Dispatch - PROD - CHDC` (On-Prem, PROD).
- `UPDATE` to populate `data_center_id`, `server_name`, and text fields or FK references for support/change/managing teams, using realistic fictional values.
- This chunk is **optional**. Mark the top of the file with `-- OPTIONAL — only run if Stuart wants the 1.4 article to showcase on-prem depth.`
- If any of `data_center_id`, `support_team_id`, `change_team_id`, `managing_team_id` are FKs to tables you cannot find existing rows for in the Riverside namespace, leave that field unset and add a `-- NOTE:` comment explaining why.

**00-verify-state-before.sql / 99-verify-state-after.sql**
- Both are read-only `SELECT`-only files — no `BEGIN;`/`COMMIT;`, no data mutation.
- `00` captures the counts the readiness report documented (0 contacts on showcase app, 1 of 9 integrations DP-aligned, 2 of 18 workspaces budgeted, 0 of 11 IT services with contracts).
- `99` re-runs the same SELECTs and should show the post-enrichment counts (≥2 contacts, ≥3 integrations DP-aligned, 5 of 18 workspaces budgeted, 3 of 11 IT services with contracts).
- Stuart will run `00` before any enrichment, then each enrichment chunk, then `99` to confirm success.

### Step 5 — Deliverables

When you are done, produce:

1. **8 `.sql` files** in `docs-architecture/planning/phase-0-assets/enrichment-sql/` (seven enrichment chunks + before/after verifiers).
2. **A `README.md` in that same directory** (≤ 80 lines) that:
   - Lists the chunks in execution order
   - Notes which chunks are mandatory vs optional
   - Tells Stuart to run `00-verify-state-before.sql` first, then chunks in order, then `99-verify-state-after.sql`
   - Warns that every chunk is idempotent but **rollback is via the `-- Rollback:` comment at the bottom of each file**
   - Warns that these SQL files touch **live demo data** in production Supabase — read before pasting
3. **A short session summary** in your final chat message listing:
   - The namespace ID you scoped to
   - The showcase app you picked for chunk 01
   - The integrations you renamed / DP-aligned in chunk 02
   - The workspaces you budgeted in chunk 03
   - The IT services you contracted in chunk 04
   - Whether you wrote chunk 05 (optional) or skipped it
   - The cost_bundle DPs you seeded in chunk 06 (name / vendor / amount / contract_end_date per bundle)

### Step 6 — Commit

Both the SQL files and the README live inside `docs-architecture/` (the architecture repo, always on `main`). Commit and push to the architecture repo only — no code-repo changes should happen in this session.

```bash
cd ~/getinsync-architecture
git add planning/phase-0-assets/enrichment-sql/
git commit -m "planning: Phase 0 — Riverside demo data enrichment SQL scripts"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] Read-only DB introspection confirmed namespace ID, showcase app, DP IDs, integration IDs, IT service IDs, workspace IDs, reference-table codes
- [ ] `enrichment-sql/` directory exists with 8 `.sql` files + `README.md` (00, 01, 02, 03, 04, 05, 06, 99)
- [ ] Every mutation file has `BEGIN;` / `COMMIT;` and a verification SELECT
- [ ] Every mutation file has a `-- Rollback:` comment at the bottom
- [ ] No schema changes present (`grep -i "CREATE\|ALTER\|DROP\|TRUNCATE" *.sql` returns only matches inside comments)
- [ ] Every namespace-touching statement is scoped by Riverside namespace ID
- [ ] Every dropdown value resolves to a real reference-table `code`
- [ ] Every contact / name / email is obviously fictional
- [ ] Architecture repo committed and pushed on `main`
- [ ] Session summary delivered to Stuart

### What NOT to do

- Do NOT run any INSERT / UPDATE / DELETE against the database. Your only DB interaction is SELECT for discovery.
- Do NOT modify any file outside `docs-architecture/planning/phase-0-assets/enrichment-sql/`.
- Do NOT write to `guides/` — that directory syncs live to docs.getinsync.ca.
- Do NOT invent reference-table codes. If a code does not exist, flag and stop.
- Do NOT look for a table literally named `cost_bundles` — it doesn't exist because Cost Bundle is implemented as `deployment_profiles.dp_type = 'cost_bundle'`. See `cost-model.md` §3.3 and chunk 06 above. If you find yourself wanting to `CREATE TABLE cost_bundles` or `INSERT INTO cost_bundles`, you have misread the model.
- Do NOT touch `workspaces.budget_amount` — it is legacy.
- Do NOT start Phase 1 (Tier 1 article writing). That is a separate session and explicitly out of scope here.
- Do NOT modify the code repo (`~/Dev/getinsync-nextgen-ag` outside `docs-architecture/`). This session is architecture-repo-only.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
