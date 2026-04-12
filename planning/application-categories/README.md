# Application Categories — Tracker

> **Purpose:** Hub directory for the Application Categories initiative — populate Riverside demo data with category assignments, add three new AI Chat tools that expose category data, and re-evaluate the harness with category-specific queries.
>
> **Why this matters:** EAs constantly ask "what do I have for X?" — what apps already do CRM, HR, GIS, document management. The schema supports this (M:M `application_category_assignments` against a 14-row `application_categories` catalog), the assignment UI already exists (`ApplicationForm.tsx`, `useApplicationCategories.ts`), but Riverside has 0 of 32 apps assigned and the AI Chat harness has zero awareness of category data. This initiative closes both gaps.

---

## Status

- **Session 1 — Riverside category enrichment** — **COMPLETE (2026-04-11).** 32/32 Riverside apps assigned, 53 total assignments, 0 UNCATEGORIZED misuse. Mapping reviewed and approved by Stuart in-session. Chunks 01-05 applied via the Supabase SQL Editor, each chunk verifier matched the approved mapping, and `99-verify-final.sql` returned all pass criteria. Enrichment SQL committed at `~/getinsync-architecture` main `aca430f` (initial) + `89feb89` (strip `\pset` meta-command for SQL Editor compatibility).
- **Session 2 — AI Chat category tools** — **COMPLETE (2026-04-11).** Branch `feat/ai-chat-category-tools` pushed with commit `30b08ec`. Three new tools: `list-application-categories`, `category` filter on `list-applications`, `category-rollup`. System prompt updated with "Capability and category questions" subsection and cross-tool orchestration note. Stuart deployed to the dev Edge Function.
- **Session 3 — Category eval** — **COMPLETE (2026-04-11).** Eval results at `10-eval-results-category-tools.md`. **Result: 1 regression (Q9 — WRONG), 3/7 new queries GOOD, 2 wrong answers total.** Root causes: (1) `category-rollup` tool's `assessed_count` predicate bug (counts default-0 apps as assessed), (2) missing cross-tool category-membership verification rule. **Recommendation: ITERATE on a small Session 4 fix before merging.** See eval doc for full scoring, tool effectiveness analysis, and proposed fixes.
- **Session 4 — Category tools fix** — PENDING. Scope: (1) Fix `category-rollup` assessed_count predicate in `tools.ts` line 720 (`!== null` → `> 0`), (2) add cross-tool category-membership verification rule (~15 lines in `system-prompt.ts`), (3) re-deploy and re-eval.

---

## Files in this directory

| File | Purpose | Status |
|---|---|---|
| `README.md` | This file — tracker and decision log | Current |
| `01-session-prompt-riverside-category-data.md` | Session 1 — propose mappings, checkpoint with Stuart, then generate chunked SQL in `enrichment-sql/` | Executed 2026-04-11 |
| `02-session-prompt-ai-chat-category-tools.md` | Session 2 — three new tools + system prompt subheading on `feat/ai-chat-category-tools` branch | Executed 2026-04-11 |
| `03-session-prompt-category-eval.md` | Session 3 — re-run 18 queries (11 regression + 5 new + 2 cross-tool), produce frozen results doc | Executed 2026-04-11 |
| `enrichment-sql/` | 7 chunked SQL files — `00-verify-baseline.sql`, `01-assign-police-department.sql`, `02-assign-fire-and-court.sql`, `03-assign-information-technology.sql`, `04-assign-finance-and-hr.sql`, `05-assign-customer-ops-dev-public-water.sql`, `99-verify-final.sql` | Applied 2026-04-11 |
| `10-eval-results-category-tools.md` | Session 3 output. Frozen results doc — 18 scoring entries, 1 regression, 3/7 new queries GOOD. Merge recommendation: ITERATE | Created 2026-04-11 |

---

## Execution order

```
┌─────────────────────────────────────────────────────────┐
│  1. Open 01-session-prompt-riverside-category-data.md  │
│     → paste into fresh Claude Code session              │
│     → session reads catalog, queries Riverside apps,    │
│       proposes mappings, PAUSES at checkpoint           │
│     → Stuart reviews and approves the mapping table     │
│     → session generates chunked SQL files               │
│     → Stuart pastes the chunks into Supabase SQL Editor │
│       in order, validates with verifier scripts         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  2. Open 02-session-prompt-ai-chat-category-tools.md   │
│     → paste into fresh Claude Code session              │
│     → session branches feat/ai-chat-category-tools      │
│       from dev (NOT from feat/ai-chat-harness-eval)     │
│     → session edits tools.ts + system-prompt.ts only    │
│     → session commits and pushes branch                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  [Stuart deploys: supabase functions deploy ai-chat]   │
│     from the feat/ai-chat-category-tools branch         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  [Stuart runs 15 queries against deployed Edge Function]│
│     uses conversation titles                            │
│     "Eval Categories YYYY-MM-DD A" / "B"                │
│     - 10 queries from Batch 1 (regression check)        │
│     - 5 new category queries                            │
│     - 2 cross-tool queries (combine category + other)   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  3. Open 03-session-prompt-category-eval.md            │
│     → paste into fresh Claude Code session              │
│     → session pulls traces, scores 15 queries           │
│     → session writes 10-eval-results-category-tools.md  │
│     → session updates this README with results          │
└─────────────────────────────────────────────────────────┘
```

---

## Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-04-11 | Initiative scoped as 3 sessions: data, tools, eval | Mirrors the proven Batch 0/1/2 pattern from AI Chat harness optimization. Each session is self-contained and can be reviewed independently. |
| 2026-04-11 | AI Chat only — no UI surface in this initiative | Lowest blast radius. The data is queryable via the new tools. UI surface (KPI card, dashboard tab) deferred to a future initiative if demand emerges. No new view, no `vw_explorer_detail` change, no `vw_dashboard_summary` change. |
| 2026-04-11 | All three tool shapes ship together | `list-application-categories` (catalog discoverability) + `category` filter on `list-applications` + `category-rollup` (aggregate breakdown). Each addresses a distinct EA workflow and they compose well: discover catalog → filter list → see aggregate. |
| 2026-04-11 | Session 1 uses checkpoint pattern, not pre-baked mappings | The executing session queries Riverside's apps live, proposes mappings as a markdown table, and pauses for Stuart's approval before generating SQL. Slower than pre-baking but produces a Stuart-approved mapping that catches errors before SQL is written. |
| 2026-04-11 | Session 2 branches `feat/ai-chat-category-tools` from `dev`, NOT from `feat/ai-chat-harness-eval` | Clean separation from Batch 2. Stuart deploys twice (once for Batch 2, once for category tools). Avoids merge tangling. The two branches converge through `dev` once both are merged independently. |
| 2026-04-11 | Eval set = 10 Batch 1 queries + 5 new + 2 cross-tool | The 10 Batch 1 queries are the regression check (did the new tools break Batch 2's gains?). The 5 new category queries measure the new tools directly. The 2 cross-tool queries probe whether the model orchestrates *across* category and non-category tools — the real EA use case. |
| 2026-04-11 | `Uncategorized` category is reserved | Session 1 brief explicitly forbids using the `Uncategorized` (code `UNCATEGORIZED`) category in the enrichment. It exists as a safety default for net-new apps users add via the form, not as a real assignment. All 32 Riverside apps must end up in real categories. |
| 2026-04-11 | Session 1 shipped with the existing 14-cat catalog; catalog refinement deferred to Phase 2 | Level-set conversation identified 3 missing Gartner MQs (`ITSM`, `EAM`, `FSM`) that would clean up shoehorning of ServiceNow ITSM / ServiceDesk Plus / Samsara Fleet / Sensus FlexNet. Decision: ship Riverside enrichment against the 14-cat catalog as-is (53 assignments defensible for demo purposes), file catalog refinement as a future Phase 2 initiative (schema add + seed function update + backfill of existing namespaces + re-map Riverside). Not in scope for Sessions 2 or 3. |
| 2026-04-11 | Session 1 executed — 32/32 apps assigned, 53 total assignments | Mapping approved by Stuart in-session, chunks 01-05 applied via Supabase SQL Editor, each chunk verifier matched approval, and `99-verify-final.sql` returned all pass criteria (totals 32/32/53, unassigned=0, UNCATEGORIZED misuse=0, per-category counts match). One bug fix mid-session: `\pset pager off` meta-command removed from all 7 files because the SQL Editor rejects psql meta-commands (committed as `89feb89`). |
| 2026-04-11 | Session 2 executed — 3 new tools on `feat/ai-chat-category-tools` | `list-application-categories`, `category` filter on `list-applications`, `category-rollup`. Commit `30b08ec`. Stuart deployed to dev Edge Function. |
| 2026-04-11 | Session 3 eval complete — ITERATE recommended | 1 regression on Q9 (`category-rollup` assessed_count bug), 3/7 new queries GOOD, 1 wrong cross-tool answer (Q17). Two concrete fixes proposed: (1) 1-line `tools.ts` predicate change, (2) ~15-line cross-tool verification prompt rule. Session 4 scope is small. |
| 2026-04-11 | Regression baseline is Batch 2 (10/10), not Batch 1 (6/10) | The session brief assumed `feat/ai-chat-category-tools` didn't include Batch 2 changes. Verified that Batch 2 (`b17075a`) IS in the branch ancestry because it was merged to `dev` before Session 2 ran. All scoring uses the Batch 2 baseline. |

---

## Schema reference (verified 2026-04-11 via DATABASE_READONLY_URL)

```
public.application_categories
  - id (uuid, PK)
  - namespace_id (uuid, FK → namespaces)
  - code (text, unique within namespace)
  - name (text)
  - description (text)
  - display_order (int)
  - is_active (bool)
  - created_at (timestamptz)
  - RLS: All users can SELECT; admins can INSERT/UPDATE/DELETE in current namespace
  - Audit: audit_application_categories trigger
  - Templating: copy_application_categories_to_new_namespace() trigger seeds new namespaces

public.application_category_assignments
  - id (uuid, PK)
  - application_id (uuid, FK → applications)
  - category_id (uuid, FK → application_categories)
  - created_at (timestamptz)
  - UNIQUE (application_id, category_id) — junction table
  - RLS: All users can SELECT; admins of the namespace owning the parent application can INSERT/UPDATE/DELETE
  - Audit: audit_application_category_assignments trigger
```

## Riverside category catalog (14 rows, all `is_active=true`)

| display_order | code | name | description |
|---|---|---|---|
| 1 | FINANCE | Finance & Accounting | Financial management, budgeting, accounts payable/receivable, general ledger. |
| 2 | HR | Human Resources | Talent management, payroll, benefits, workforce planning. |
| 3 | CRM | CRM & Citizen Services | Customer/citizen relationship management, case management, service requests. |
| 4 | ERP | ERP & Core Business | Enterprise resource planning, supply chain, procurement. |
| 5 | COLLABORATION | Collaboration & Comms | Email, messaging, video conferencing, document sharing. |
| 6 | ANALYTICS | Analytics & Reporting | Business intelligence, dashboards, data visualization, reporting. |
| 7 | SECURITY | Security & Compliance | Identity management, access control, audit, compliance monitoring. |
| 8 | INFRASTRUCTURE | Infrastructure & Ops | IT operations, monitoring, backup, network management. |
| 9 | DEVELOPMENT | Development & DevOps | Source control, CI/CD, project management, testing tools. |
| 10 | GIS_SPATIAL | GIS & Spatial | Geographic information systems, mapping, spatial analysis. |
| 11 | RECORDS | Records & Document Mgmt | Document management, records retention, archival systems. |
| 12 | LEGAL | Legal & Regulatory | Case management, legal research, regulatory compliance, tribunal systems. |
| 13 | HEALTH | Health & Social Services | Clinical systems, social service delivery, benefits administration. |
| 99 | UNCATEGORIZED | Uncategorized | Applications not yet classified. Default category. **DO NOT USE** in enrichment. |

## Riverside baseline (verified 2026-04-11 — pre-enrichment)

- Total apps: **32** (across 18 workspaces)
- Apps with category assignments: **0**
- Total category assignments: **0**

## Riverside post-enrichment state (verified 2026-04-11 via `99-verify-final.sql`)

- Total apps: **32** — unchanged
- Apps with category assignments: **32** (100% coverage)
- Total category assignments: **53** (avg 1.66 categories per app)
- Apps in `UNCATEGORIZED`: **0** ✓ (reserved)
- Unassigned apps: **0** ✓

**Per-category breakdown (12 of 13 real categories used; `DEVELOPMENT` = 0 by design — no dev/CI tools in Riverside's portfolio):**

| Category | Apps | Category | Apps |
|---|---|---|---|
| RECORDS | 11 | GIS_SPATIAL | 3 |
| CRM | 10 | HEALTH | 3 |
| LEGAL | 7 | ANALYTICS | 2 |
| FINANCE | 5 | ERP | 2 |
| INFRASTRUCTURE | 5 | SECURITY | 1 |
| HR | 3 | COLLABORATION | 1 |
| DEVELOPMENT | 0 | UNCATEGORIZED | 0 |

**Known shoehorning (Phase 2 catalog refinement targets):** ServiceNow ITSM + ServiceDesk Plus folded into `INFRASTRUCTURE` (real category is ITSM); Samsara Fleet folded into `ERP`+`GIS_SPATIAL` and Sensus FlexNet into `INFRASTRUCTURE`+`ANALYTICS` (real category is EAM). All four would re-tag cleanly when `ITSM`+`EAM`+`FSM` are added to the catalog.

---

## Related initiatives

- **AI Chat harness optimization** (`docs-architecture/planning/ai-chat-harness-optimization/`) — sibling initiative running on `feat/ai-chat-harness-eval`. Batch 2 (rationalization, temporal, classification refusals) ships before this initiative's eval lands. This initiative's branch `feat/ai-chat-category-tools` is intentionally independent.
- **Phase 0 enrichment** (`docs-architecture/planning/phase-0-assets/`) — set the precedent for chunked SQL paste-into-SQL-Editor pattern that Session 1 inherits.

---

*Last updated: 2026-04-11 — Session 3 eval complete; Session 4 pending (iterate before merge).*
