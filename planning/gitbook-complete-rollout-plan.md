# Complete GitBook Documentation Rollout Plan

**Version:** 1.0
**Date:** 2026-04-09
**Status:** Approved — not yet started
**Owner:** Stuart Holtby
**Supersedes execution model of:** `gitbook-documentation-audit.md` v1.0 (content inventory remains authoritative)

---

## 1. Context

The GetInSync GitBook ([docs.getinsync.ca](https://docs.getinsync.ca)) has 10 published articles but the app has 40+ user-facing features. The GitBook Documentation Audit (`planning/gitbook-documentation-audit.md` v1.0) planned 18 articles organized by EA Journey Tiers and specified a per-article, per-session execution model where Stuart picks one article at a time.

Two things have changed:

1. **Existing OG GetInSync customers** are a second audience not covered by the original audit. They need a transition article that maps OG's entity-centric nav (Portfolios, Ideas, Projects, Programs, Applications, IT Services, Contacts, Suppliers, Analytics) to NextGen's insight-centric nav (Overview, Application Health, Technology Health, Roadmap, IT Spend, Explorer) and explains the mental model shift.

2. **Execution strategy is changing** from "Stuart picks articles ad hoc" to a single end-to-end rollout. This gets the full GitBook published, SUMMARY.md reorganized into tiered sections, and the audit doc retired as "Executed".

This plan expands the audit from 18 → 19 articles (adding 1.5 Transitioning from Classic), sequences them into 6 executable phases, adds a Phase 0 data-seeding step to resolve all data readiness gaps upfront, and ends with the tiered SUMMARY.md reorganization, `whats-new.md` entry, and retirement of the audit doc.

---

## 2. Scope & Outcome

**Deliverables when the plan is fully executed:**

1. 19 published articles in `docs-architecture/guides/user-help/` (9 new + 6 refreshed + 3 reviewed + 1 previously-written, now published)
2. Screenshots captured from localhost:5173 via Chrome MCP, saved to `guides/user-help/images/`
3. `guides/SUMMARY.md` reorganized into 5 tiered sections matching audit §8 target state
4. `guides/whats-new.md` updated with a batched "April 2026 documentation refresh" entry
5. `planning/gitbook-documentation-audit.md` marked `Status: Executed` with a changelog entry
6. `CLAUDE.md` updated with the Feature-to-User-Help Map (audit §6a)
7. `operations/session-end-checklist.md` updated per audit §6b
8. `operations/session-end-user-docs.md` updated per audit §6c
9. Architecture repo committed and pushed to `main` (dual-repo rule — no code repo changes expected)

**No code changes.** This is 100% documentation work.

---

## 3. Execution Model

- **Phased across sessions with checkpoints.** Each tier is one session. Phase 0 may split into 2 sessions if seeding is heavy.
- **Review at end of each tier.** Stuart reviews the tier's articles as a batch before moving to the next tier. A phase cannot start until the prior tier is approved.
- **Phase 0 resolves all data gaps upfront** so screenshot capture is never blocked mid-writing.
- **Per-article workflow** (§10 below) is identical across all phases — follow it for each article.
- **Estimated session count:** 6–7 sessions.

---

## 4. Phase 0 — Prep & Data Seeding

**Goal:** Resolve all data readiness gaps from audit §4 so every article in Phases 1–5 has a live dataset to screenshot.

### Prep steps

1. Confirm dev server runs (`npm run dev`) and Chrome MCP is connected to localhost:5173
2. Verify the demo namespace has at least 2 workspaces (required for 3.5 Overview Dashboard)
3. Create `guides/user-help/images/` directory
4. Save the OG sidebar screenshot Stuart provided in chat as `images/og-sidebar.png`
5. Capture a fresh NextGen top-nav screenshot as `images/nextgen-nav.png`

### Data seeding needed (from audit §4, "Check" and "No" rows)

| Article | Action |
|---------|--------|
| 1.4 Deployment Profiles | Pick one DP with fully populated fields + operations section. Enrich if needed. |
| 2.1 Managing Applications | Pick one well-populated application (contacts, DPs, lifecycle, tags). Enrich if needed. |
| 2.2 Importing Applications | Prepare sample CSV (~10 rows) showing the import template structure |
| 2.4 Integrations | Confirm ≥2 integrations exist with DP-aligned source/target (post Integration-DP alignment Mar 2026) |
| 4.1 Roadmap Initiatives | Confirm ≥3 initiatives exist with linked apps and target dates |
| 4.2 IT Spend | Confirm budget data is populated (`workspace_budgets`, IT service budgets) |
| 4.3 Cost Analysis | Confirm cost channel data is populated (IT services with `annual_cost`, cost bundles) |

**Blocker rule:** If any seeding step cannot be completed via the UI, stop and flag it. Database changes are out of scope — Stuart handles those via Supabase SQL Editor.

**Phase 0 exit criteria:** Every one of the 19 articles has a clear path from "open localhost:5173" → "capture a meaningful screenshot" without further data prep.

---

## 5. Phase 1 — Tier 1: Understand the Platform (5 articles)

*EA / returning user asks: "What is this tool and does it fit me?"*

| # | Article | File | Type | Key content |
|---|---------|------|------|-------------|
| 1.1 | Getting Started | `getting-started.md` | Refresh | 6-tab nav, EA tone, mention CSDM alignment |
| 1.2 | Navigating GetInSync | `navigating-getinsync.md` | Refresh | Add Explorer tab, rename Budget → IT Spend, refresh tab descriptions |
| 1.3 | How GetInSync Maps to CSDM | `csdm-alignment.md` | **NEW** | App → Business App, DP → App Service, Integration → Relationship; DP-as-assessment-anchor philosophy. Source: `catalogs/csdm-application-attributes.md`, `features/integrations/servicenow-alignment.md`. Conceptual only — no export mechanics. |
| 1.4 | What Are Deployment Profiles? | `deployment-profiles.md` | Review | Connect to CSDM language where natural; spot-check accuracy |
| 1.5 | **Transitioning from Classic GetInSync** | `transitioning-from-classic.md` | **NEW** | See §5.1 |

**Tier 1 review checkpoint:** Stuart reviews all 5 articles as a batch. No advance to Phase 2 until approved.

### 5.1 Article outline — 1.5 Transitioning from Classic GetInSync

**Audience:** Existing OG GetInSync customers migrating to NextGen.

**Sections:**

1. **Welcome back** — brief intro, reassurance that the data model is the same
2. **The big shift: entity-centric → insight-centric** — OG asked "what object?" NextGen asks "what question?" (health, cost, lifecycle, roadmap). Explorer is the closest to old flat-list browsing.
3. **Where did it go? — Nav mapping table** (core content):

| Classic nav item | NextGen location | Cross-link |
|------------------|------------------|------------|
| Overview | **Overview** tab | [Overview Dashboard Guide](overview-dashboard.md) |
| Portfolios | **Portfolios** tab *(new)* + Settings → Portfolios | Forthcoming |
| Ideas | **Roadmap** → Initiatives (status: Identified) | [Initiatives](roadmap-initiatives.md) |
| Projects | **Roadmap** → Initiatives (status: Planned/In Progress) | [Initiatives](roadmap-initiatives.md) |
| Programs | **Roadmap** → Strategic Themes | [Initiatives](roadmap-initiatives.md) |
| Applications | **Application Health** tab + **Explorer** tab | [Managing Applications](managing-applications.md) |
| IT Services | **IT Spend** tab + Settings → IT Services | [Understanding IT Spend](it-spend.md) |
| Contacts | Settings → Contacts (Involved Parties) | [Settings & Admin](settings-admin.md) |
| Suppliers | Settings → Organizations | [Settings & Admin](settings-admin.md) |
| Analytics | Distributed across tabs (each has charts/KPIs) | — |

4. **Three things that are genuinely new** — Deployment Profiles (assessment anchor), CSDM alignment, AI Assistant
5. **Where do I start?** — 3-step onboarding path for OG users
6. **Quick reference** — one-liner summary of each NextGen tab

**Screenshots:** `images/og-sidebar.png` next to `images/nextgen-nav.png` for visual comparison.

---

## 6. Phase 2 — Tier 2: Set Up & Populate (4 articles)

*EA asks: "How do I get my portfolio data in here?"*

| # | Article | File | Type | Key content |
|---|---------|------|------|-------------|
| 2.1 | Adding & Managing Applications | `managing-applications.md` | **NEW** | Creation flow, detail page walkthrough, contacts, DPs, operations section |
| 2.2 | Importing Applications | `importing-applications.md` | **NEW** | CSV import workflow, field mapping, validation, bulk tips (reference sample CSV from Phase 0) |
| 2.3 | Settings & Administration | `settings-admin.md` | **NEW** | Org settings, user/role management, workspace setup, teams, assessment config, data centers, contacts, organizations |
| 2.4 | Managing Integrations | `integrations.md` | Refresh | Update for DP-aligned integrations (Phase 2 shipped Mar 2026) |

**Tier 2 review checkpoint.**

---

## 7. Phase 3 — Tier 3: Assess & Analyze (6 articles)

*EA asks: "How do I score my portfolio and find the risks?"*

| # | Article | File | Type | Key content |
|---|---------|------|------|-------------|
| 3.1 | How to Assess an Application | `assessment-guide.md` | Refresh | Verify wizard screenshots, add staleness indicators |
| 3.2 | TIME Quadrant | `time-framework.md` | Review | Spot-check accuracy against current UI |
| 3.3 | PAID Quadrant | `paid-framework.md` | Review | Spot-check accuracy |
| 3.4 | Reading Tech Health | `tech-health.md` | Refresh | "End of Support" label, CSV export, data quality badges |
| 3.5 | Overview Dashboard Guide | `overview-dashboard.md` | **NEW** | KPI cards, drill-down, risk panels, assessment completion (requires 2+ workspaces) |
| 3.6 | Using the Explorer | `explorer.md` | **NEW** | Cross-cutting filters, column selection, advanced queries |

**Tier 3 review checkpoint.**

---

## 8. Phase 4 — Tier 4: Plan & Budget (3 articles)

*EA asks: "What should we do about it, and what does it cost?"*

| # | Article | File | Type | Key content |
|---|---------|------|------|-------------|
| 4.1 | Creating & Managing Initiatives | `roadmap-initiatives.md` | Refresh | Programs/ideas, Gantt/Kanban views, scorecard |
| 4.2 | Understanding IT Spend | `it-spend.md` | **NEW** | Budget tab walkthrough, KPI cards, workspace/service views, run rate |
| 4.3 | Cost Analysis & Run Rate | `cost-analysis.md` | **NEW** | Cost analysis panel, vendor attribution, contracts, expiry widget |

**Tier 4 review checkpoint.**

---

## 9. Phase 5 — Tier 5: Power Features (2 articles)

*EA asks: "How do I get quick answers?"*

| # | Article | File | Type | Key content |
|---|---------|------|------|-------------|
| 5.1 | Portfolio AI Assistant | `ai-assistant.md` | Publish | Article already exists in repo. Review for V2 tool-use features (search_portfolio, query_database). Ready for GitBook. |
| 5.2 | Using Global Search | `global-search.md` | **NEW** | Cmd+K shortcut, searchable entities, result navigation |

**Tier 5 review checkpoint.**

---

## 10. Per-Article Workflow (applies to Phases 1–5)

1. Open article file (or create for NEW)
2. Open the relevant NextGen page in Chrome MCP at localhost:5173
3. Capture screenshots via Chrome MCP, save to `guides/user-help/images/` with descriptive names (e.g. `overview-kpi-cards.png`)
4. Write/update markdown following the voice of existing articles (`getting-started.md`, `navigating-getinsync.md` are the reference templates)
5. Use the heading structure: H1 title → intro paragraph → H2 sections with "Who it's for" and "Use this page when" callouts where applicable
6. Embed screenshots with relative paths: `![description](images/filename.png)`
7. Add cross-links to related articles using relative paths
8. Do NOT update `SUMMARY.md` inline — that happens once in Phase 6
9. Mark the article done on the phase checklist

---

## 11. Phase 6 — SUMMARY Reorganization, Meta Updates & Audit Retirement

**Goal:** Promote all 19 articles into a tiered GitBook navigation and lock in the operational changes from audit §6.

### 11.1 Reorganize `guides/SUMMARY.md`

Replace the current flat "User Help" section with the tiered structure:

```markdown
# Table of contents

* [Getting Started](README.md)
* [What's New](whats-new.md)

## New to GetInSync

* [Getting Started with GetInSync](user-help/getting-started.md)
* [Navigating GetInSync](user-help/navigating-getinsync.md)
* [How GetInSync Maps to CSDM](user-help/csdm-alignment.md)
* [Transitioning from Classic GetInSync](user-help/transitioning-from-classic.md)

## Setting Up Your Portfolio

* [Adding & Managing Applications](user-help/managing-applications.md)
* [What Are Deployment Profiles?](user-help/deployment-profiles.md)
* [Importing Applications](user-help/importing-applications.md)
* [Settings & Administration](user-help/settings-admin.md)
* [Managing Application Integrations](user-help/integrations.md)

## Assessing Your Applications

* [How to Assess an Application](user-help/assessment-guide.md)
* [TIME Quadrant Explanation](user-help/time-framework.md)
* [PAID Quadrant Explanation](user-help/paid-framework.md)
* [Reading Tech Health Indicators](user-help/tech-health.md)
* [Overview Dashboard Guide](user-help/overview-dashboard.md)
* [Using the Explorer](user-help/explorer.md)

## Planning & Budgeting

* [Creating and Managing Initiatives](user-help/roadmap-initiatives.md)
* [Understanding IT Spend](user-help/it-spend.md)
* [Cost Analysis & Run Rate](user-help/cost-analysis.md)

## Power Features

* [Portfolio AI Assistant](user-help/ai-assistant.md)
* [Using Global Search](user-help/global-search.md)
```

### 11.2 Update `guides/whats-new.md`

Append a single entry dated in April 2026: *"April 2026 documentation refresh — 9 new articles + 6 refreshed covering CSDM alignment, classic transition, app management, import, admin, IT Spend, cost analysis, dashboards, Explorer, AI Assistant, global search."* Use the format from existing entries.

### 11.3 Update `CLAUDE.md` Feature-to-User-Help Map

Add the full map from audit §6a as a new section alongside the existing Feature-to-Doc Map. Include an entry for **OG transition / Classic users** → `transitioning-from-classic.md` and for **Portfolios (new tab)** → forthcoming (separate plan).

### 11.4 Update `operations/session-end-checklist.md` §6h (audit §6b)

- Reference the Feature-to-User-Help Map in CLAUDE.md for article routing
- Make `whats-new.md` append format explicit (date, heading, bullet points with business impact)
- Add step: "If you created a new article, update `SUMMARY.md` for GitBook navigation"

### 11.5 Update `operations/session-end-user-docs.md` (audit §6c)

- Point to the Feature-to-User-Help Map in CLAUDE.md
- Add screenshot update guidance: "If UI changed visually, recapture via Chrome MCP"
- Include `whats-new.md` entry template

### 11.6 Retire the audit doc

Edit `planning/gitbook-documentation-audit.md`:

- Header: `Status: Approved` → `Status: Executed (YYYY-MM-DD)`
- Version: 1.0 → 1.2 (1.1 would be the Tier 1 row addition during this plan)
- Add changelog note at bottom: *"Executed as part of Complete GitBook Documentation Rollout plan. All 19 articles shipped. Further updates happen per-feature via the living-specs rule."*
- Update §3 to add row 1.5
- Update §4 to add data readiness row for 1.5
- Update §7 summary counts (8→9 new, 18→19 total)
- Update §8 SUMMARY target to match 11.1 above

### 11.7 Commit & push architecture repo

Single large commit message on `main`:

```
docs: complete GitBook documentation rollout — 19 articles, tiered SUMMARY

- 9 new articles (incl. transitioning-from-classic for OG users)
- 6 articles refreshed for April 2026 UI state
- 3 articles reviewed
- ai-assistant.md promoted to GitBook
- SUMMARY.md reorganized into 5 tiered sections
- whats-new.md batch entry added
- CLAUDE.md: Feature-to-User-Help Map added
- Session-end checklist updated per audit §6b, §6c
- gitbook-documentation-audit.md retired (Status: Executed)
```

Push to `origin main`. No code repo changes expected.

---

## 12. Critical Files

### Created

- `docs-architecture/guides/user-help/csdm-alignment.md`
- `docs-architecture/guides/user-help/transitioning-from-classic.md`
- `docs-architecture/guides/user-help/managing-applications.md`
- `docs-architecture/guides/user-help/importing-applications.md`
- `docs-architecture/guides/user-help/settings-admin.md`
- `docs-architecture/guides/user-help/overview-dashboard.md`
- `docs-architecture/guides/user-help/explorer.md`
- `docs-architecture/guides/user-help/it-spend.md`
- `docs-architecture/guides/user-help/cost-analysis.md`
- `docs-architecture/guides/user-help/global-search.md`
- `docs-architecture/guides/user-help/images/` (many screenshots)

### Modified

- `docs-architecture/guides/user-help/getting-started.md` (refresh)
- `docs-architecture/guides/user-help/navigating-getinsync.md` (refresh)
- `docs-architecture/guides/user-help/deployment-profiles.md` (review)
- `docs-architecture/guides/user-help/integrations.md` (refresh)
- `docs-architecture/guides/user-help/assessment-guide.md` (refresh)
- `docs-architecture/guides/user-help/time-framework.md` (review)
- `docs-architecture/guides/user-help/paid-framework.md` (review)
- `docs-architecture/guides/user-help/tech-health.md` (refresh)
- `docs-architecture/guides/user-help/roadmap-initiatives.md` (refresh)
- `docs-architecture/guides/user-help/ai-assistant.md` (publish)
- `docs-architecture/guides/SUMMARY.md` (reorganize into tiers)
- `docs-architecture/guides/whats-new.md` (append batch entry)
- `CLAUDE.md` (Feature-to-User-Help Map)
- `docs-architecture/operations/session-end-checklist.md` (§6h enhancements)
- `docs-architecture/operations/session-end-user-docs.md` (procedure update)
- `docs-architecture/planning/gitbook-documentation-audit.md` (retirement, row 1.5, count updates)

### Reference (read-only)

- `docs-architecture/catalogs/csdm-application-attributes.md` — source for 1.3 CSDM Alignment
- `docs-architecture/features/integrations/servicenow-alignment.md` — source for 1.3 CSDM Alignment
- `src/components/navigation/tabConfig.ts` — source of truth for NextGen main tabs (validates 1.2, 1.5)
- Every tier-relevant architecture doc in `docs-architecture/features/` — source material for its tier

---

## 13. Verification

1. **Per-phase:** Stuart does a review pass at the end of each tier. Phase cannot advance until approved.
2. **Link check:** Every cross-link in every article resolves to an existing file in `guides/user-help/` (no dead links). Grep for `](user-help/` patterns and verify each target file exists.
3. **Screenshot legibility:** Every screenshot opens, renders without artifacts, and shows the feature being documented.
4. **SUMMARY.md render:** After Phase 11.1, view `guides/SUMMARY.md` locally and confirm the tiered structure matches §11.1 exactly.
5. **Audit doc consistency:** In Phase 11.6, confirm §3 has 19 rows, §4 has 19 rows, §7 summary counts are 9 new + 6 refresh + 3 review + 1 publish = 19 total.
6. **Feature-to-User-Help Map:** Every article file referenced in CLAUDE.md exists.
7. **Dual-repo commit:** Follow the CLAUDE.md dual-repo rule. Commit and push `~/getinsync-architecture/` on `main`. No code repo changes should be required.
8. **GitBook publish:** After the final commit, verify [docs.getinsync.ca](https://docs.getinsync.ca) picks up the new SUMMARY.md and all 19 articles render.

---

## 14. Out of Scope (intentionally deferred)

- **Portfolios Overview page** (planned earlier in the same conversation) — separate plan at `features/portfolios-overview/plan.md`. The transition article (1.5) references it as "forthcoming".
- **In-app banner/widget** linking to the transition article — nice-to-have for another session.
- **Video walkthroughs** of any article.
- **Translation** to other languages.
- **Deep OG-to-NextGen feature mapping** beyond nav items (e.g., specific detail-page field comparisons) — follow-up if users request it.
- **Schema or code changes.** This plan is 100% documentation work.
- **Analytics / GitBook page-view instrumentation** to measure which articles get read.
