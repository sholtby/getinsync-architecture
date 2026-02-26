# Main Dashboard Refresh — Architecture v1.0

**Date:** February 25, 2026  
**Author:** Stuart Holtby  
**Status:** 🟡 PLANNED  
**Priority:** P1 — First screen in every demo  
**Effort:** 3–4 days (Claude Code)  
**Dependencies:** None — all data sources exist  
**Reuses:** Technology Health Dashboard patterns (filter drawer, KPI cards, donuts)

---

## 1. Executive Summary

The main dashboard is the first screen users see when they log in to GetInSync NextGen. In its current state, it displays a flat table of applications with KPI cards and TIME/PAID distribution bars. While functional, this view reads as a data browser rather than a strategic narrative. It does not communicate the value proposition of GetInSync as a CSDM Agent.

This architecture defines a two-level dashboard system that transforms the landing experience from a data table into a portfolio intelligence view. The namespace-level dashboard tells the whole-of-organization story for Directors and CIOs. The workspace-level dashboard provides department-scoped operational context for team leads and stewards.

All data sources already exist in production. The Technology Health Dashboard, shipped February 18–21, established the UX patterns (KPI cards, donut charts, filter drawer, CSV export) that this build will reuse. This is an execution task, not a design task.

---

## 2. Problem Statement

### 2.1 Current State

The current main dashboard renders a workspace-scoped application table with inline TIME/PAID distribution bars and four KPI cards (Total Apps, Assessed %, Crown Jewels, At Risk). Action buttons provide View Charts, Export CSV, Browse Shared Apps, Add Existing App, and + New Application.

Three fundamental problems:

- **Workspace-scoped only** — a Director managing five departments cannot see their whole portfolio without clicking through each workspace individually
- **Raw data without narrative** — there is no concept of "what needs attention" or "what happened recently"
- **Technology Health invisible** — the lifecycle risk intelligence that differentiates GetInSync from spreadsheets does not appear on the landing page

### 2.2 Target State

A two-level dashboard system where the namespace view answers "How is my entire portfolio doing?" and the workspace view answers "How is my department doing?" Both views tell a story in four rows: how big is the portfolio, how healthy is it, what is at risk, and what happened recently.

---

## 3. Two-Level Dashboard Architecture

The dashboard exists at two scopes, each serving different audiences and use cases. The namespace dashboard is the new landing page. The workspace dashboard is the refreshed version of the current screen.

| Dimension | Namespace Dashboard | Workspace Dashboard |
|-----------|-------------------|-------------------|
| **Audience** | Director / CIO / CSDM Lead | Team Lead / Steward / Editor |
| **Question** | "How is my whole portfolio?" | "How is my department?" |
| **Scope** | All workspaces in namespace | Single workspace |
| **Breakdowns** | By workspace | By portfolio (optional) |
| **Actions** | Drill to workspace, export summary, view findings | + New App, Browse Shared, Export CSV, Add Existing |
| **Route** | `/dashboard` (landing page) | `/workspace/:id` |
| **Navigation** | No workspace/portfolio dropdowns | Workspace selector in header |

> The namespace dashboard does not replace the workspace view — it sits above it. Users land on the namespace dashboard and drill into workspaces for operational work.

---

## 4. Namespace Dashboard Wireframe

The namespace dashboard is organized into four visual rows, progressing from summary KPIs at top to actionable detail at bottom.

### 4.1 Row 1: KPI Cards

Four cards spanning full width, each with headline metric, trend indicator, and subtitle.

| Card | Value | Subtitle | Click Action |
|------|-------|----------|-------------|
| Total Applications | Count of all apps | "across N workspaces" | Scroll to app table |
| Assessed | Count (% of total) | "N complete / M total" | Scroll to completion bar |
| Crown Jewels | Count where criticality ≥ 50 | derived, not flagged | Filter to crown jewels |
| At Risk | Count in Modernize + Eliminate | TIME quadrant rollup | Filter to at-risk |

> Crown jewel count is derived from criticality score ≥ 50, not a static flag. This matches the established architectural principle.

### 4.2 Row 2: Assessment Completion Bar

Full-width stacked horizontal bar showing assessment coverage across the entire namespace. Three segments: Assessed (complete), Needs Profiling (in progress or has partial data), and Not Started.

The completion bar answers "how much of our portfolio do we actually understand?" — the single most important metric for a CSDM implementation.

### 4.3 Row 3: Health & Risk Panels (Side by Side)

Two equal-width panels showing portfolio health from complementary angles.

**Left Panel — Portfolio Health (TIME Distribution):**  
Donut chart showing DP distribution across TIME quadrants: Invest (green), Tolerate (yellow), Modernize (orange), Eliminate (red). Below the donut, a compact breakdown table shows count per workspace.

**Right Panel — Technology Lifecycle Risk:**  
Donut chart showing lifecycle status distribution: Mainstream (green), Extended Support (yellow), End of Support (red), Unknown (gray). Below the donut, breakdown by technology layer (OS, Database, Web Server).

Data source: `vw_technology_health_summary` and `vw_technology_tag_lifecycle_risk` — already deployed with Riverside demo data (12 tech products, 52 tags across 20 DPs).

### 4.4 Row 4: Action Panels (Three-Column)

**Left (Wide) — Needs Attention:**  
Top 5 highest-priority applications requiring action, ranked by composite severity score. Each entry shows application name, workspace label, severity indicator (dot), and reason text. See §6 for scoring algorithm.

**Middle — Unassessed Applications:**  
Large numeric display of apps with assessment_status = not_started, broken down by workspace. Creates visible accountability.

**Right — Recent Activity:**  
Activity feed from `audit_logs` showing most recent assessment, creation, and update events. Format: "Delta assessed Cayenta (Police Department) — 2 hours ago."

---

## 5. Data Sources & Views

All data required for the dashboard already exists in production. No new tables are needed. Two new views are recommended.

### 5.1 Existing Views

| View | Dashboard Use | Status |
|------|-------------|--------|
| `vw_technology_health_summary` | Lifecycle risk donut data | Deployed ✔ |
| `vw_technology_tag_lifecycle_risk` | Lifecycle by technology layer | Deployed ✔ |
| `vw_application_infrastructure_report` | Tech stack per DP for Needs Attention reasons | Deployed ✔ |
| `vw_namespace_summary` | Workspace count, user count, app count | Deployed ✔ |

### 5.2 Direct Table Queries

| Table | Dashboard Use |
|-------|-------------|
| `deployment_profiles` | TIME/PAID quadrant distribution, assessment_status, criticality scores |
| `applications` | Total app count, operational_status filter, workspace_id grouping |
| `workspaces` | Workspace names for breakdown tables |
| `audit_logs` | Recent activity feed (last 10 events filtered to relevant event_types) |

### 5.3 Proposed New View: vw_dashboard_summary

Single aggregating view that pre-computes KPI card values and distribution counts per namespace. Avoids multiple round-trips from frontend. Security_invoker=true with explicit GRANTs.

| Column | Derivation |
|--------|-----------|
| `namespace_id` | Grouping key |
| `total_applications` | COUNT of applications where operational_status = operational |
| `total_dps` | COUNT of deployment_profiles |
| `assessed_count` | COUNT of DPs where assessment_status = complete |
| `needs_profiling_count` | COUNT of DPs where assessment_status = in_progress |
| `not_started_count` | COUNT of DPs where assessment_status = not_started |
| `crown_jewel_count` | COUNT of DPs where criticality >= 50 |
| `invest_count` / `tolerate_count` / `modernize_count` / `eliminate_count` | COUNT of DPs grouped by time_quadrant |
| `at_risk_count` | modernize_count + eliminate_count |

### 5.4 Proposed New View: vw_dashboard_workspace_breakdown

Workspace-level breakdown view powering donut sub-tables and unassessed panel. One row per workspace with the same metrics as vw_dashboard_summary scoped to workspace_id. Also supports workspace-scoped dashboard by filtering to single workspace_id.

---

## 6. Needs Attention Scoring Algorithm

### 6.1 Severity Signals

| Signal | Weight | Source |
|--------|--------|--------|
| TIME = Eliminate | 40 points | `deployment_profiles.time_quadrant` |
| TIME = Modernize | 25 points | `deployment_profiles.time_quadrant` |
| Any tech at End of Support | 20 points | `vw_application_infrastructure_report` |
| Multiple EOS layers | +10 per additional | `vw_application_infrastructure_report` |
| Crown jewel (criticality ≥ 50) | 15 points additive | `deployment_profiles.criticality` |
| Extended Support tech | 10 points | `vw_application_infrastructure_report` |
| Not fully assessed | 5 points | `deployment_profiles.assessment_status` |

Crown jewel multiplier is additive, not multiplicative. Top 5 by composite score displayed. Ties broken alphabetically.

### 6.2 Reason Text Generation

Each entry shows a concise reason string from the highest-weight signal:

- "RHEL 7 at End of Support" (from lifecycle reference data)
- "Oracle Database on Extended Support" (from lifecycle reference data)
- "Dual EOS stack: OS + Database" (multiple layers EOS)
- "Eliminate quadrant — retire candidate" (from TIME assessment)
- "Crown jewel not fully assessed" (criticality ≥ 50, assessment incomplete)

---

## 7. Navigation & UX Flow

### 7.1 Entry Points

The namespace dashboard becomes the default landing page after login. Route: `/dashboard`. No workspace or portfolio selectors in the header at this level.

The workspace dashboard is accessed by clicking workspace names anywhere in the namespace dashboard or via sidebar navigation. Route: `/workspace/:id` with existing header chrome.

### 7.2 Filter Drawer

Namespace dashboard includes a filter drawer (matching Technology Health pattern):

- Workspace (multi-select)
- TIME Quadrant (multi-select)
- Assessment Status (multi-select)
- Hosting Type (multi-select)

Filters affect all four rows simultaneously.

### 7.3 Drill-Through Behavior

| Click Target | Destination |
|-------------|------------|
| KPI card | Scroll to relevant section or apply filter |
| Donut slice | Apply filter for that segment |
| Workspace name in breakdown | Navigate to `/workspace/:id` |
| App name in Needs Attention | Navigate to application detail |
| Activity feed entry | Navigate to affected entity |

---

## 8. Component Reuse from Technology Health

| Component | Reuse Plan |
|-----------|-----------|
| KPICard | Direct reuse — same layout, different labels/values |
| DonutChart | Direct reuse — different colors/labels |
| FilterDrawer | Direct reuse — different filter options, same slide-in behavior |
| WorkspaceBreakdownTable | Adapt — workspace breakdown instead of technology layer |
| StickyHeader | Direct reuse |
| CSVExport | Direct reuse — different column definitions |
| LifecycleBadge | Direct reuse — lifecycle status in Needs Attention panel |

> Open item #55 (extract FilterDrawer as reusable component) resolved as part of this build.

---

## 9. Build Phases

### Phase A: Database Views (0.5 day)

Deploy `vw_dashboard_summary` and `vw_dashboard_workspace_breakdown`. Security_invoker=true, explicit GRANTs, RLS-filtered. Run pgTAP regression. Add view contracts to `src/types/view-contracts.ts`.

### Phase B: Namespace Dashboard Shell (1 day)

Build namespace dashboard page via Claude Code. Route: `/dashboard`. Four-row grid. KPI cards from vw_dashboard_summary. Assessment completion bar. No filter drawer yet.

### Phase C: Health & Risk Panels (0.5–1 day)

Two donut chart panels (TIME distribution + Technology Lifecycle Risk). Reuse DonutChart. Workspace breakdown tables. Drill-through clicks.

### Phase D: Action Panels + Filter Drawer (1 day)

Three-column Row 4: Needs Attention with severity scoring, Unassessed Applications, Recent Activity. Extract shared FilterDrawer component (resolves #55). Wire filters to all rows.

### Phase E: Workspace Dashboard Refresh (0.5 day)

Refresh workspace view to match new design language. Same four-row layout scoped to single workspace. Action buttons retained on workspace view only.

---

## 10. Effort Summary

| Phase | Effort | Tool | Blocked By |
|-------|--------|------|-----------|
| A: Database Views | 0.5 day | SQL Editor | None |
| B: Dashboard Shell + KPIs | 1 day | Claude Code | Phase A |
| C: Health & Risk Panels | 0.5–1 day | Claude Code | Phase B |
| D: Action Panels + Filter | 1 day | Claude Code | Phase C |
| E: Workspace Refresh | 0.5 day | Claude Code | Phase D |
| **Total** | **3.5–4 days** | | |

---

## 11. Q1 Remaining Build Order

1. **Main Dashboard Refresh** (this document) — 3–4 days
2. **Technology Lifecycle Intelligence** — auto-detect EOL dates, Claude API lookup — ~10 hours
3. **Executive Roadmap One-Pager** — the deliverable customers hand to their boss — 1–2 days
4. **IT Value Creation Frontend** — Scorecard/Initiatives/Ideas/Programs tabs — 3–4 days (if time)
5. **Business Capabilities SQL** — 2 tables, seed data — 0.5 day
6. **Polish** — RBAC gating, back arrow fixes, minor UX — remaining time

> Technology Lifecycle Intelligence feeds the dashboard directly — smarter lifecycle data makes the Needs Attention panel and Technology Risk donut more compelling.

---

## 12. Open Items Resolved

| # | Item | Resolution |
|---|------|-----------|
| #55 | Filter drawer pattern → push to other dashboards | Resolved in Phase D |
| #52 | Workspace-scoped Technology Health dashboard | Pattern established by Phase E |
| #37 | Riverside demo data refresh (partial) | Gaps identified, parallel track |

---

## 13. Success Criteria

- Director logging in to Riverside sees namespace dashboard as landing page with all four rows populated
- Clicking workspace name navigates to workspace-scoped view
- Filter drawer affects all four rows simultaneously
- Needs Attention panel correctly surfaces highest-risk applications with reason text
- Donut charts match visual quality of Technology Health Dashboard
- Both views pass the 18-year-old test — no CSDM jargon, immediately comprehensible
- pgTAP regression suite passes with new views included
- Production deployment to nextgen.getinsync.ca verified

---

## 14. Document History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | Feb 25, 2026 | Initial architecture. Two-level dashboard, wireframe spec, data sources, build phases. |
