# Application Categories — Tracker

> **Purpose:** Hub directory for the Application Categories initiative — populate Riverside demo data with category assignments, add three new AI Chat tools that expose category data, and re-evaluate the harness with category-specific queries.
>
> **Why this matters:** EAs constantly ask "what do I have for X?" — what apps already do CRM, HR, GIS, document management. The schema supports this (M:M `application_category_assignments` against a 14-row `application_categories` catalog), the assignment UI already exists (`ApplicationForm.tsx`, `useApplicationCategories.ts`), but Riverside has 0 of 32 apps assigned and the AI Chat harness has zero awareness of category data. This initiative closes both gaps.

---

## Status

- **Session 1 — Riverside category enrichment** — PENDING. Standalone session prompt at `01-session-prompt-riverside-category-data.md`. Output is chunked SQL files for Stuart to paste into the Supabase SQL Editor manually.
- **Session 2 — AI Chat category tools** — PENDING. Standalone session prompt at `02-session-prompt-ai-chat-category-tools.md`. Output is code on a new branch `feat/ai-chat-category-tools`, branched from `dev` (NOT from `feat/ai-chat-harness-eval`).
- **Session 3 — Category eval** — PENDING. Standalone session prompt at `03-session-prompt-category-eval.md`. Output is `10-eval-results-category-tools.md` (frozen results doc) in this directory.

---

## Files in this directory

| File | Purpose | Status |
|---|---|---|
| `README.md` | This file — tracker and decision log | Current |
| `01-session-prompt-riverside-category-data.md` | Session 1 — propose mappings, checkpoint with Stuart, then generate chunked SQL in `enrichment-sql/` | Ready to run |
| `02-session-prompt-ai-chat-category-tools.md` | Session 2 — three new tools + system prompt subheading on `feat/ai-chat-category-tools` branch | Ready to run (after Session 1) |
| `03-session-prompt-category-eval.md` | Session 3 — re-run 15 queries (10 Batch 1 regression + 5 new + 2 cross-tool), produce frozen results doc | Ready to run (after Session 2 + Stuart deploy) |
| `enrichment-sql/` | Created by Session 1. Will contain `00-verify-baseline.sql`, `01-NN-assign-*.sql`, `99-verify-final.sql` | Not yet created |
| `10-eval-results-category-tools.md` | Created by Session 3. Frozen results doc with per-query scoring, regression check, merge recommendation | Not yet created |

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

## Riverside baseline (verified 2026-04-11)

- Total apps: **32** (across 18 workspaces)
- Apps with category assignments: **0**
- Total category assignments: **0**

---

## Related initiatives

- **AI Chat harness optimization** (`docs-architecture/planning/ai-chat-harness-optimization/`) — sibling initiative running on `feat/ai-chat-harness-eval`. Batch 2 (rationalization, temporal, classification refusals) ships before this initiative's eval lands. This initiative's branch `feat/ai-chat-category-tools` is intentionally independent.
- **Phase 0 enrichment** (`docs-architecture/planning/phase-0-assets/`) — set the precedent for chunked SQL paste-into-SQL-Editor pattern that Session 1 inherits.

---

*Last updated: 2026-04-11*
