# planning/q1-2026-master-plan.md
GetInSync NextGen - Q1 2026 Master Execution Plan  
Last updated: 2026-02-25

---

## Executive Summary

**Timeline:** February 10 - March 31, 2026 (8 weeks)  
**Owner:** Stuart Holtby  
**Status:** v2.0 — Mid-quarter reset. Core schema complete. Frontend + polish remaining.

### What Changed Since v1.4

**v1.4 (Feb 14)** planned around Knowledge conference as the forcing function. Since then:

- Knowledge conference **removed from scope** — no longer driving timeline
- Claude Code **replaced AG** as primary frontend tool (Feb 17)
- Technology Health Dashboard **shipped** to production (Feb 21)
- IT Value Creation Phase 21b **deployed** — schema, views, seed data (Feb 22)
- Phase 28 Integration Management **all 13 bugs closed** (Feb 17)
- Business Capability architecture **designed** (Feb 25)
- ITSM API research completed — Phase 37 scoping (Feb 20)
- Significant CSDM research completed — Crawl/Walk/Run/Fly adoption path, ServiceNow relationship model analysis, Business Services layer design

**The core APM platform is functionally complete at the schema level.** 90 tables, 37 audit triggers, 347 RLS policies, 27 views, 53 functions. What remains is frontend implementation and polish.

### Key Metrics

- **Dev Days Used (Feb 10-25):** ~12 days
- **Dev Days Remaining (Feb 26 - Mar 31):** ~20 working days
- **Schema Work Remaining:** Business capabilities tables (~0.5 day), recurring_cost column on initiatives (~1 hr)
- **Frontend Work Remaining:** IT Value Creation UI (~5-6 days), executive roadmap one-pager (~1-2 days), polish (~3-5 days)
- **Q1 Exit Criteria:** IT Value Creation frontend live with executive roadmap output, RBAC UI gating, general polish pass

---

## Completed (Feb 10 - Feb 25)

### Architecture Sprint (Feb 10-14)
| Date | Milestone |
|------|-----------|
| Feb 10 | Visual Tab Architecture v1.0 + Technology Stack ERD v1.0 |
| Feb 11 | Operational Statuses table + Schema backup (72 tables) |
| Feb 12 | Google OAuth verified + Session-end checklist v1.2 |
| Feb 13 | Nested Portfolio UI + Audit log backfill (#5 closed) |
| Feb 13 | Technology Health Dashboard architecture designed (5 new docs) |
| Feb 14 | Gamification architecture designed (v1.2, 4 tables) |
| Feb 14 | Infrastructure Boundary Rubric + Lifecycle Intelligence v1.1 |

### Execution (Feb 17-25)
| Date | Milestone |
|------|-----------|
| Feb 17 | Phase 28 Integration Management — all 13 bugs closed |
| Feb 17 | Claude Code v2.1.44 replaced AG as primary frontend tool |
| Feb 18 | Web Server tech category added, lifecycle reference seeding |
| Feb 20 | ITSM API research doc completed (Phase 37 scoping) |
| Feb 21 | **Technology Health Dashboard — DEPLOYED to production** |
| Feb 22 | **IT Value Creation Phase 21b — DEPLOYED** (Ideas, Programs, Dependencies tables + views + seed data) |
| Feb 25 | Business Capability & Business Services architecture v1.0 |
| Feb 25 | CSDM Crawl/Walk/Run/Fly adoption path researched |

---

## Remaining Q1 Scope (Feb 26 - Mar 31)

### Priority 1: IT Value Creation Frontend (Week 6-7)
**Effort:** 5-6 days  
**Tool:** Claude Code  
**Status:** In progress — grinding on UX

**Revised approach:** Build the working tabs (Scorecard, Initiatives, Ideas, Programs) AND the executive roadmap one-pager as the primary output. The one-pager is the deliverable customers present to leadership — a generated table per workspace showing domain, theme, recommendation, time horizon, and cost. This competes with the consultant PowerPoint, not with project management boards.

| Component | Effort | Notes |
|-----------|--------|-------|
| Scorecard tab (domain cards with severity) | 1-2 days | Mockup exists, needs implementation |
| Initiatives tab (table with inline edit) | 1-2 days | CRUD against initiatives table |
| Ideas tab (lightweight list) | 0.5 day | Simpler than initiatives |
| Programs tab (grouping container) | 0.5 day | Programs contain initiatives |
| Executive Roadmap one-pager | 1-2 days | New view + printable component. The deliverable. |

**New view needed:**
```sql
CREATE VIEW vw_executive_roadmap AS
-- Grouped by domain, sorted by priority
-- Columns: area, theme, recommendation, time_horizon, one_time_cost, recurring_cost, priority
```

**Schema addition needed:**
- `initiatives.recurring_cost` column (numeric) — currently only has estimated_cost (one-time)

### Priority 2: Business Capabilities Schema (Week 6)
**Effort:** 0.5 day  
**Tool:** Supabase SQL Editor

Deploy the two tables from the architecture doc:
- business_capabilities (hierarchical reference taxonomy)
- business_capability_applications (junction to applications)
- RLS policies (4)
- Audit triggers (2)
- Seed function + trigger on namespaces
- Populate template namespace with L1/L2 generic seed (~13 L1, ~60 L2)
- pgTAP assertions (~8-10)

No UI. Tables sit ready for Q2 frontend work.

### Priority 3: RBAC UI Gating (Week 7-8)
**Effort:** 2-3 days  
**Tool:** Claude Code  
**Blocked by:** #41 permission-aware hooks (1-2 days)

| Item | Effort |
|------|--------|
| #41 Permission-aware Supabase hooks (useCanEdit, etc.) | 1-2 days |
| #40 UI role gating — 13 actions lack frontend checks | 1-2 days |
| #42 Role-gated settings sidebar | 0.5 day |

### Priority 4: Polish Pass (Week 8)
**Effort:** 3-5 days  
**Tool:** Claude Code

| Item | Effort | Priority |
|------|--------|----------|
| #55 Filter drawer → push to other dashboards | 1-2 days | MED |
| #51 Surface Tech Health on Application Detail page | 1-2 days | LOW |
| #53 Pagination confirmation | 1 hr | LOW |
| #54 KPI reframe confirmation | 1 hr | LOW |
| #37 Riverside demo data refresh | 0.5 day | MED |
| General UI consistency | 1 day | LOW |

---

## Week-by-Week Timeline (Revised)

```
WEEK 6 (Feb 26 - Mar 4):
  Business Capabilities SQL deployment (0.5 day)
  IT Value Creation — Scorecard + Initiatives tabs (Claude Code)
  Delta: SOC2 policies HIGH due Feb 27 (GPD-528/529/530)

WEEK 7 (Mar 5 - Mar 11):
  IT Value Creation — Ideas + Programs tabs
  Executive Roadmap one-pager (new view + component)
  RBAC hooks (#41) if time

WEEK 8 (Mar 12 - Mar 18):
  RBAC UI gating (#40, #42)
  Polish pass (filter drawer, demo data, consistency)

WEEK 9 (Mar 19 - Mar 25):
  Polish continued
  Delta: SOC2 policies LOW due Mar 27 (GPD-534/535)

WEEK 10 (Mar 26 - Mar 31):
  Q1 wrap-up
  Q2 planning
  Open items refresh
```

**Critical Path:** IT Value Creation tabs → Executive Roadmap → RBAC → Polish

---

## Q2 2026 Backlog

### Near-Term (Early Q2)

| Feature | Architecture Status | Effort | Trigger |
|---------|-------------------|--------|---------|
| Business Capabilities UI | Designed (v1.0), schema deploying Q1 | 2-3 days | Schema deployed, ready anytime |
| Gamification Phase 1 | Designed (v1.2, 4 tables) | 2-3 days | First customer deployment |
| Technology Lifecycle Intelligence (AI) | Designed (v1.1), manual seeding in Q1 | ~10 hrs | Claude API integration |
| IT Value Creation refinement | Executive roadmap iterations | Ongoing | Customer feedback |

### Mid-Term (Q2)

| Feature | Architecture Status | Effort | Trigger |
|---------|-------------------|--------|---------|
| Entra ID SSO | Identity/Security v1.1 exists | 7-8 days | First enterprise customer requiring SSO |
| ServiceNow Integration (Phase 37) | ITSM research v1.0, CSDM mapping done | 15-20 days | Customer with ServiceNow instance |
| Business Services (Phase 2) | Designed in business-capability.md | 1-2 days schema | Customer requesting SPM or CSDM Walk |
| Power BI deployment | 14 views exist, not deployed | 1-2 days | Reporting demand |

### Deferred (No Timeline)

| Feature | Notes |
|---------|-------|
| Composite Applications | Schema risk — needs architecture review |
| Budget Management | CFO tracking — tied to cost model maturity |
| AI Chat (APM Q&A) | Natural language queries — R&D |
| Namespace Editor role activation | Low demand |
| Move Application between workspaces | Manual SQL workaround exists |

---

## Resource Allocation (Remaining Q1)

### Stuart
| Week | Activity | Effort |
|------|----------|--------|
| 6 | Business capabilities SQL + IT Value Creation frontend | 4-5 days |
| 7 | IT Value Creation frontend + executive roadmap | 4-5 days |
| 8 | RBAC hooks + UI gating | 2-3 days |
| 8-9 | Polish pass | 2-3 days |
| 10 | Q1 wrap + Q2 planning | 1-2 days |

### Delta
| Week | Activity | Effort |
|------|----------|--------|
| 6 | SOC2 policies HIGH (GPD-528/529/530, due Feb 27) | 6-8 hrs |
| 7-8 | SOC2 policies MED (GPD-532/533, due Mar 6) | 3 hrs |
| 9 | SOC2 policies LOW (GPD-534/535, due Mar 27) | 1.5 hrs |
| Ongoing | Customer success, Garland mapping | Continuous |

---

## Architecture Document Stats

| Metric | Count |
|--------|-------|
| Total documents | 87 (was 86, +1 business-capability.md) |
| 🟢 AS-BUILT | 50 |
| 🟡 AS-DESIGNED | 1 (business-capability.md) |
| 🟠 NEEDS UPDATE | 0 |
| Schema tables | 90 (will be 92 after business capabilities) |
| RLS policies | 347 (will be 351) |
| Audit triggers | 37 (will be 39) |
| pgTAP assertions | 391 (will be ~401) |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.0 | 2026-02-25 | **Major reset.** Knowledge conference removed. Tech Health + IT Value Creation schema shipped. Claude Code primary tool. Business Capabilities architecture added. Executive roadmap one-pager concept added to IT Value Creation scope. Realistic remaining timeline based on 20 working days. Q2 backlog updated with CSDM publish targets, business services, business capabilities UI. |
| v1.4 | 2026-02-14 | Architecture sprint resequencing. Tech Health pulled from Q2. |
| v1.3 | 2026-02-09 | Integration Management shipped. IT Value Creation pulled forward. |
| v1.2 | 2026-02-08 | M365 ecosystem slotted. Power BI Foundation added. |
| v1.1 | 2026-02-08 | Phase 25.10 complete. Multi-region DB. |
| v1.0 | 2026-02-07 | Initial Q1 2026 Master Plan. |

---

*Document: planning/q1-2026-master-plan.md*  
*February 2026*
