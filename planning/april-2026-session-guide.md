# April 2026 Session Guide — Claude Code Prompts

**Version:** 1.0
**Date:** April 3, 2026
**Companion to:** `planning/april-2026-level-set.md`

---

## How to Use This Document

Each "chunk" below is a self-contained Claude Code session. Copy the prompt block into a new Claude Code window.

**Rules:**
- Run chunks in order — each lists prerequisites
- DB chunks produce SQL scripts for Stuart to review and execute in Supabase SQL Editor
- After running SQL, tell Claude "schema done" — it will run the checkpoint automatically
- Frontend chunks create feature branches — merge to `dev` when complete
- If a session runs out of context, start a new window with the continuation prompt provided
- Parallel sessions are noted where safe — only parallelize when explicitly stated

**AI Chat + Global Search rule:** Neither AI Chat nor Global Search auto-discovers new tables, views, or columns. Both are hardcoded. Every chunk that adds a new entity or queryable view must include tasks to:
- Add/extend AI Chat tools (`supabase/functions/ai-chat/tools.ts` + `system-prompt.ts`)
- Add to Global Search RPC (`global_search` function) + navigation handler (`AppHeader.tsx`)
- Update semantic layer (`docs-architecture/features/ai-chat/semantic-layer.yaml`)

**Estimated total:** 8 chunks across ~15-20 hours of Claude Code time

---

## Chunk 1 — DB: Contract-Aware Cost Bundles Schema

**Prerequisites:** None
**ADR:** `adr/adr-contract-aware-cost-bundles.md`
**Level Set:** Stage A.1 (items A.1.1–A.1.2)
**Output:** SQL script for Stuart to run in Supabase SQL Editor

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-contract-aware-cost-bundles.md (full ADR — focus on §4)
- docs-architecture/planning/april-2026-level-set.md §4 Stage A.1 (items A.1.1–A.1.2)
- docs-architecture/schema/nextgen-schema-current.sql (current schema reference)

Task: Generate a SQL script for the Contract-Aware Cost Bundles schema changes.
I will review and run this in Supabase SQL Editor — do NOT execute any SQL.

The script must include, in order:

1. ALTER TABLE deployment_profiles — add 4 columns:
   - contract_reference (text, nullable)
   - contract_start_date (date, nullable)
   - contract_end_date (date, nullable)
   - renewal_notice_days (integer, default 90)
   See ADR §4.1 for column comments and index spec.

2. CREATE INDEX idx_dp_contract_end — partial index on contract_end_date
   WHERE contract_end_date IS NOT NULL AND dp_type = 'cost_bundle'.

3. CREATE VIEW vw_contract_expiry — UNION view pulling from both IT Services
   and Cost Bundles. Must use security_invoker = true. See ADR §4.2 for the
   full view definition.

4. GRANT SELECT on vw_contract_expiry to authenticated, service_role.

5. COMMENTs on all new columns per ADR §4.1.

After generating the script:
- Verify the view SQL compiles by checking column references against the
  current schema (use DATABASE_READONLY_URL to confirm column names on
  deployment_profiles, it_services, workspaces, applications, organizations)
- Confirm vendor_org_id already exists on deployment_profiles (it should —
  verify via information_schema)
- Output the complete script in a single code block ready for copy-paste

Do NOT create a feature branch. This is a DB-only session.
```

**After Stuart runs the SQL:**

```
Schema done for Contract-Aware Cost Bundles. The following were applied:
- 4 new columns on deployment_profiles (contract_reference, contract_start_date,
  contract_end_date, renewal_notice_days)
- Partial index idx_dp_contract_end
- vw_contract_expiry UNION view
- Grants on vw_contract_expiry

Run mid-session schema checkpoint.
```

---

## Chunk 2 — DB: CSDM Export Readiness Schema (Teams + DP FKs)

**Prerequisites:** None (can run same session as Chunk 1)
**ADR:** `adr/adr-csdm-export-readiness.md`
**Level Set:** Stage A.1 (items A.1.3–A.1.6)
**Output:** SQL script for Stuart to run in Supabase SQL Editor

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-csdm-export-readiness.md (full ADR — focus on §4)
- docs-architecture/planning/april-2026-level-set.md §4 Stage A.1 (items A.1.3–A.1.5)
- docs-architecture/operations/new-table-checklist.md (new table requirements)
- docs-architecture/schema/nextgen-schema-current.sql (current schema reference)

Task: Generate a SQL script for the CSDM Export Readiness schema changes.
I will review and run this in Supabase SQL Editor — do NOT execute any SQL.

The script must include, in order:

1. CREATE TABLE teams — with columns per ADR §4.1:
   id (uuid PK), namespace_id (FK not null), workspace_id (FK nullable),
   name (text not null), description (text), is_active (bool default true),
   created_at, updated_at.
   UNIQUE constraint on (namespace_id, name).
   Follow new-table-checklist: GRANT ALL to authenticated + service_role,
   ENABLE ROW LEVEL SECURITY, audit trigger.

2. RLS POLICY on teams — namespace isolation per ADR §4.4.
   Use the standard namespace_users pattern.

3. AUDIT TRIGGER on teams — per ADR §4.5.

4. ALTER TABLE deployment_profiles — add 3 FK columns:
   - support_team_id (uuid, FK → teams, ON DELETE SET NULL)
   - change_team_id (uuid, FK → teams, ON DELETE SET NULL)
   - managing_team_id (uuid, FK → teams, ON DELETE SET NULL)
   With COMMENTs per ADR §4.2.

5. ALTER TABLE deployment_profile_contacts — update CHECK constraint:
   Drop existing deployment_profile_contacts_role_type_check.
   Add new CHECK including 'change_control' per ADR §4.3.

After generating the script:
- Verify the RLS policy pattern matches other namespace-isolated tables
  (check an existing policy via DATABASE_READONLY_URL for reference)
- Verify the audit trigger function name matches the project standard
  (audit_log_trigger)
- Verify the current CHECK constraint values on deployment_profile_contacts
  so the DROP/ADD is correct
- Output the complete script in a single code block ready for copy-paste

Do NOT create a feature branch. This is a DB-only session.
```

**After Stuart runs the SQL:**

```
Schema done for CSDM Export Readiness. The following were applied:
- teams table with RLS, audit trigger, grants
- 3 FK columns on deployment_profiles (support_team_id, change_team_id,
  managing_team_id)
- deployment_profile_contacts CHECK constraint updated with change_control

Run mid-session schema checkpoint.
```

---

## Chunk 3 — Frontend: Contract-Aware Cost Bundles UI

**Prerequisites:** Chunk 1 SQL applied and checkpoint passed
**ADR:** `adr/adr-contract-aware-cost-bundles.md`
**Level Set:** Stage A.2
**Branch:** `feat/contract-aware-cost-bundles`

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-contract-aware-cost-bundles.md (full ADR — focus on §6, §8)
- docs-architecture/planning/april-2026-level-set.md §4 Stage A.2
- docs-architecture/operations/screen-building-guidelines.md (UI standards)

We're implementing Contract-Aware Cost Bundles UI. The schema is already
deployed — 4 new columns on deployment_profiles (contract_reference,
contract_start_date, contract_end_date, renewal_notice_days) and the
vw_contract_expiry UNION view.

Create a feature branch from dev: feat/contract-aware-cost-bundles

Tasks:

1. Cost Bundle card — contract details section
   Add a collapsible "Contract Details" section to the Cost Bundle card on
   the Deployments & Costs tab. Four fields:
   - Contract Reference (text input)
   - Start Date (date picker)
   - End Date (date picker)
   - Renewal Notice Days (number input, default 90)
   Collapsed by default. Only visible for dp_type = 'cost_bundle'.
   See ADR §8.1 for wireframe.

2. Contract Expiry Widget update
   Update ContractExpiryWidget.tsx to query vw_contract_expiry instead of
   vw_it_service_contract_expiry. The UNION view has a source_type column
   ('it_service' or 'cost_bundle') — show both sources with a source
   indicator. See ADR §8.2 for the table layout.
   Before changing the widget, grep for all consumers of
   vw_it_service_contract_expiry and update the TypeScript types to match
   the new view columns.

3. Double-count warning — adding Cost Bundle
   When creating a Cost Bundle on an application that already has IT Service
   allocations on any of its DPs, show a warning dialog. See ADR §6.1 for
   the exact copy and button labels.

4. Double-count prompt — adding IT Service
   When adding an IT Service allocation to a DP whose application has Cost
   Bundles with contract_end_date IS NOT NULL, show an info prompt. See
   ADR §6.2 for the exact copy and button labels. "Review Cost Bundles"
   button should scroll to / highlight the Cost Bundle section.

5. AI Chat — add contract-expiry tool
   AI Chat tools are hardcoded in supabase/functions/ai-chat/tools.ts.
   New views are invisible to AI Chat unless a tool is added. Read
   tools.ts and system-prompt.ts to understand the pattern, then:
   - Add a 'contract-expiry' tool to TOOL_DEFINITIONS that queries
     vw_contract_expiry (filtered by namespace_id)
   - Add execution logic in executeTool()
   - Update system-prompt.ts to describe when to use the new tool
     (e.g., "When asked about contract renewals, expiring contracts,
     or upcoming renewals, use the contract-expiry tool")
   - Update docs-architecture/features/ai-chat/semantic-layer.yaml
     with the new view mapping

After all tasks, update the architecture doc:
- docs-architecture/features/cost-budget/software-contract.md §7 —
  reference vw_contract_expiry instead of vw_it_service_contract_expiry
```

**Continuation prompt (if session runs out of context):**

```
Continuing work from a previous session.
Branch: feat/contract-aware-cost-bundles
Read: docs-architecture/adr/adr-contract-aware-cost-bundles.md

Completed: [list what was done]
Remaining: [list what's left from tasks 1-4]

The schema is already deployed. Do NOT generate SQL.
```

---

## Chunk 4 — Frontend: CSDM Teams + Operations UI

**Prerequisites:** Chunk 2 SQL applied and checkpoint passed
**Can parallelize with:** Chunk 3 (different files — verify before starting)
**ADR:** `adr/adr-csdm-export-readiness.md`
**Level Set:** Stage A.3
**Branch:** `feat/csdm-teams-ui`

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-csdm-export-readiness.md (full ADR — focus on §6)
- docs-architecture/planning/april-2026-level-set.md §4 Stage A.3
- docs-architecture/operations/screen-building-guidelines.md (UI standards)

We're implementing the Teams entity UI. The schema is already deployed:
- teams table (with RLS, audit trigger, grants)
- 3 FK columns on deployment_profiles (support_team_id, change_team_id,
  managing_team_id)
- change_control added to deployment_profile_contacts role_type CHECK

Create a feature branch from dev: feat/csdm-teams-ui

Tasks:

1. Team management screen
   Add a "Teams" section to namespace admin settings. Simple CRUD list with:
   - Columns: Name, Scope (workspace name or "All workspaces" for
     namespace-scoped), Used (count of DPs referencing this team in any
     of the 3 FK fields)
   - Add button creates inline (name + optional description + optional
     workspace scope)
   - "Used" count prevents accidental deletion of in-use teams
   - Pagination using shared TablePagination component
   See ADR §6.2 for wireframe.

2. Operations section on DP card
   Add an "Operations" section to each DP card on the Deployments & Costs
   tab, as the LAST section — after ITServiceDependencyList ("What Services
   Does It Use?"). There is no contacts section on the DP card. Three dropdowns
   with plain-English labels:
   - "Who fixes it when it breaks?" → support_team_id
   - "Who approves changes?" → change_team_id
   - "Which team manages this day-to-day?" → managing_team_id
   Dropdown content: namespace-scoped teams first (labeled "All workspaces"),
   then workspace-scoped teams. Sorted alphabetically within each group.
   "Add new team..." option at bottom creates inline.
   Section header tooltip per ADR §6.1.
   See ADR §6.1 for wireframe.

3. Global Search — add teams to search
   Global Search (Ctrl+K) uses a hardcoded RPC `global_search` that
   searches 12 entity types. Teams are invisible unless added. Generate
   a SQL script (I will run it) that:
   - Adds a `WITH teams_results AS` clause to the global_search RPC
     searching teams.name and teams.description
   - Category label: "Teams", icon: "users"
   - secondary_text: scope (workspace name or "All workspaces")
   Then update src/components/shared/AppHeader.tsx handleSearchSelect()
   to route "Teams" results to /settings/teams (or wherever the team
   management page lives).

4. AI Chat — add teams context
   AI Chat tools are hardcoded in supabase/functions/ai-chat/tools.ts.
   Read tools.ts and system-prompt.ts to understand the pattern, then:
   - Extend the 'application-detail' tool (or create a new tool) so
     that when asked "who supports this application?" or "who manages
     this deployment?", the AI can query team assignments on DPs
     (support_team_id, change_team_id, managing_team_id joined to teams)
   - Update system-prompt.ts to describe the new capability
   - Update docs-architecture/features/ai-chat/semantic-layer.yaml

Note: The dropdowns fetch from the teams table — this is a new table, not
a reference table. Use standard Supabase query pattern with namespace_id
filter. Do NOT hardcode team values.
```

**Continuation prompt (if session runs out of context):**

```
Continuing work from a previous session.
Branch: feat/csdm-teams-ui
Read: docs-architecture/adr/adr-csdm-export-readiness.md

Completed: [list what was done]
Remaining: [list what's left from tasks 1-2]

The schema is already deployed. Do NOT generate SQL.
```

---
<<<----left off here
## Chunk 5 — Frontend: Integration-DP Phase 3 + Type Updates

**Prerequisites:** Chunks 3 and 4 merged to dev (DP card layout finalized)
**ADR:** `adr/adr-integration-dp-alignment.md`
**Level Set:** Stage B
**Branch:** `feat/integration-dp-phase3`

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-integration-dp-alignment.md (full ADR — focus on §Phase 3)
- docs-architecture/planning/april-2026-level-set.md §4 Stage B
- docs-architecture/features/integrations/architecture.md

We're implementing Integration-DP Phase 3. Phase 1-2 is already deployed:
- source_deployment_profile_id and target_deployment_profile_id columns
  exist on application_integrations (nullable FKs)
- vw_integration_detail has been rebuilt with DP columns

Create a feature branch from dev: feat/integration-dp-phase3

Tasks:

1. Update VwIntegrationDetail TypeScript types (open item #68)
   Check the actual vw_integration_detail view definition via
   DATABASE_READONLY_URL. Update the TypeScript interface in
   src/types/ to match. Grep for all consumers and verify they
   still compile. The view now includes source_deployment_profile_id,
   target_deployment_profile_id, source_dp_name, target_dp_name.

2. DP selector in Add Connection modal
   When creating or editing an integration, add optional DP dropdowns
   for source and target. Show DP selector ONLY when the selected
   application has multiple DPs (single-DP apps auto-assign to primary
   silently). See ADR §Phase 3, item 1.

3. Connections list — show DP name
   In the connections/integrations list tab, show DP name alongside
   app name when a DP is specified. Format: "App Name (DP Name)" or
   similar. See ADR §Phase 3, item 2.

4. Update architecture docs:
   - docs-architecture/features/integrations/architecture.md — update
     section 7 item 4 (no longer "future enhancement")
   - docs-architecture/adr/adr-integration-dp-alignment.md — mark
     Phase 3 as COMPLETE in the status section
```

---

## Chunk 6 — DB: Integration-DP Phase 4 — Data Migration

**Prerequisites:** Chunk 5 merged to dev
**ADR:** `adr/adr-integration-dp-alignment.md`
**Level Set:** Stage B.4
**Output:** SQL script for Stuart to run in Supabase SQL Editor

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-integration-dp-alignment.md (full ADR — focus on §Phase 4)
- docs-architecture/schema/nextgen-schema-current.sql

Task: Generate a SQL script for the Integration-DP Phase 4 data migration.
I will review and run this in Supabase SQL Editor — do NOT execute any SQL.

The script must:

1. For each application_integration where source_deployment_profile_id IS NULL:
   - Find the primary DP (is_primary = true) of the source application
   - Set source_deployment_profile_id to that DP's id

2. For each application_integration where target_deployment_profile_id IS NULL
   AND target_application_id IS NOT NULL:
   - Find the primary DP of the target application
   - Set target_deployment_profile_id to that DP's id

3. Report: list any integrations that could NOT be auto-assigned
   (source application has no primary DP). These need manual review.

Important:
- Use UPDATE ... FROM ... pattern, not cursors
- Wrap in a transaction
- Include a dry-run SELECT first that shows what would be updated
  (count + sample rows) — I want to review before the UPDATE runs
- Do NOT mark source/target_deployment_profile_id as NOT NULL after
  migration — they stay nullable per the ADR
```

**After Stuart runs the SQL:**

```
Schema done for Integration-DP Phase 4 data migration.
Existing integrations assigned to primary DPs.
Run mid-session schema checkpoint.
```

---

## Chunk 7 — Frontend: Visual Tab React Flow Resume

**Prerequisites:** Chunks 5 and 6 complete (DP-level integrations working)
**ADR:** `adr/adr-visual-tab-reactflow.md`
**Level Set:** Stage C
**Branch:** `feat/visual-tab-reactflow` (existing parked branch)

```
Read these architecture docs before starting:
- docs-architecture/adr/adr-visual-tab-reactflow.md (full ADR)
- docs-architecture/adr/adr-integration-dp-alignment.md (for context
  on DP-scoped integrations — Phase 1-4 now complete)
- docs-architecture/core/visual-diagram.md
- docs-architecture/planning/april-2026-level-set.md §4 Stage C

We're resuming the parked Visual Tab React Flow branch. The data model
gap that caused the park is now resolved — application_integrations has
source_deployment_profile_id and target_deployment_profile_id columns,
and existing integrations have been migrated to primary DPs.

Resume on the existing branch: feat/visual-tab-reactflow

Step 1: Rebase onto dev
  git checkout feat/visual-tab-reactflow
  git rebase dev
  Resolve any conflicts. The branch was parked March 19 — dev has
  diverged significantly.

Step 2: Wire Level 3 blast radius to DP-scoped data
  Level 3 currently shows ALL integrations for the application.
  Update useVisualGraphData.ts to filter integrations where
  source_deployment_profile_id or target_deployment_profile_id
  matches the selected DP. This is the core fix — Level 3 now
  shows accurate, DP-specific blast radius.

Step 3: Fix known gaps from ADR §Known Gaps:
  - Level 1 layout direction: change from LR to TB (three-tier:
    connected apps top, focused app center, DPs bottom)
  - Double-click on DP for Level 3 (currently single-click)
  - Restore hover tooltip on app nodes (lost from D3 version)

Step 4: QA — verify all three levels render correctly:
  - Level 1: App Graph — edges connect apps
  - Level 2: DP Overview — shows DPs with integration counts
  - Level 3: Blast Radius — shows ONLY integrations for selected DP

Step 5: Update architecture docs:
  - docs-architecture/core/visual-diagram.md — status ⏸ PARKED → ✅
  - docs-architecture/adr/adr-visual-tab-reactflow.md — status
    PARKED → COMPLETE, add changelog entry
```

---

## Chunk 8 — Gamification Phase 1 (Independent)

**Prerequisites:** None (independent of Stages A-C)
**Architecture:** `features/gamification/architecture.md` v1.2
**Level Set:** §5 Independent Work, Tier 2
**Branch:** `feat/gamification-phase1`
**Schedule:** Between Stage A and B for variety, or anytime

```
Read these architecture docs before starting:
- docs-architecture/features/gamification/architecture.md (full spec — v1.2)
- docs-architecture/planning/april-2026-level-set.md §5

We're implementing Gamification Phase 1. This is a greenfield feature
with no dependencies on other in-flight work.

This is a DB + Frontend session. Generate SQL scripts for the schema
changes — I will run them in Supabase SQL Editor. Then build the frontend.

Part A — Generate SQL script (I will run in Supabase SQL Editor):

Schema changes per the architecture doc:
1. gamification_achievements table (definitions)
2. gamification_user_progress table (per-user state)
3. gamification_user_stats table (cache)
4. flags table (data quality flags)
5. All tables need: GRANT ALL to authenticated + service_role,
   RLS enabled with namespace isolation, audit triggers
6. Any views and functions specified in the architecture doc
7. Also handle open item #44: flag CREATE viewer exception —
   flags INSERT policy should allow any workspace member (viewer
   can create flags but not update/delete)

Follow new-table-checklist: docs-architecture/operations/new-table-checklist.md

Part B — Frontend (after schema is applied):

Create a feature branch from dev: feat/gamification-phase1

Build the frontend per the architecture doc. Focus on:
1. Achievement definitions and display
2. Data quality flags UI
3. User progress tracking
4. Activity feed (if scoped in Phase 1)

Tell me when you're ready for Part B — I'll run the SQL first
and confirm "schema done."
```

---

## Quick Reference — Open Items to Fill Gaps

These are small, independent tasks to fill time between chunks or at the end of a session. Each can be done in a standalone session with a simple prompt.

```
#57 — Scope indicator (~0.5 day)
"Add a scope indicator showing 'N of M workspaces' in the tab bar or header.
Users who don't see all workspaces should know their view is filtered.
Branch: feat/scope-indicator"
```

```
#63 — Servers on dashboard (~0.5 day)
"server_name is on Visual tab DP nodes already. Surface it on the Overview
dashboard. Branch: feat/dashboard-server-name"
```

```
#66 — Assessment tour (~0.5 day)
"Shepherd.js is already integrated (S.2 complete). Create a step-by-step
assessment walkthrough tour. Read docs-architecture/features/support/
in-app-support-architecture.md for the tour spec.
Branch: feat/assessment-tour"
```

```
#65 — Budget alerts frontend (~1-2 days)
"DB layer is deployed (alert_preferences table, vw_budget_alerts view).
Build the frontend for budget alert preferences and notification display.
Read docs-architecture/features/cost-budget/budget-alerts.md for the spec.
Branch: feat/budget-alerts-frontend"
```

---

## Session Lifecycle Reminders

**Starting a session:**
- Claude Code reads CLAUDE.md automatically
- The prompt above tells it which ADR/docs to read
- Claude will confirm the branch and start working

**Mid-session — after Stuart applies SQL:**
- Say "schema done" + list what was applied
- Claude runs: security-posture-validation.sql + `npx tsc --noEmit`

**Ending a session — feature complete:**
- Claude merges branch to dev per CLAUDE.md git workflow
- Stuart says "run session-end checklist" if it's the last session of the day

**Ending a session — feature in progress:**
- Claude pushes the feature branch
- Use the continuation prompt template to resume in a new window

**Parallel sessions:**
- Chunks 3 and 4 can run in parallel (different DP card sections)
- Chunk 8 (Gamification) can run anytime alongside any other chunk
- Never run two chunks that modify the same files simultaneously
- When in doubt, run sequentially

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-04-03 | Initial session guide — 8 chunks, gap-filler prompts, lifecycle reminders |
