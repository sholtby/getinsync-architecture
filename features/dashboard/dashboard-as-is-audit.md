# Dashboard As-Is Audit

> Generated: 2026-02-26
> Scope: `src/components/Dashboard.tsx` and all child components it renders
> Purpose: Baseline snapshot before the Main Dashboard Refresh

---

## 1. File Health

### Dashboard.tsx

| Metric | Value |
|--------|-------|
| **File path** | `src/components/Dashboard.tsx` |
| **Total lines** | 2,810 |
| **Monolithic?** | Yes — single file, not split into modules |
| **Functions/components defined inside** | 4 (see below) |

**Functions defined in Dashboard.tsx:**

| Name | Lines | Purpose |
|------|-------|---------|
| `getOverallAssessmentStatus()` | 51-57 | Returns `not_started` / `in_progress` / `complete` for an app |
| `calculateSummary()` | 59-163 | Client-side aggregation of TIME/PAID distributions, avg scores, total cost |
| `SortIcon` (inline component) | 740-745 | Renders sort direction arrow icon in table headers |
| `Dashboard` (main export) | 173-2810 | The dashboard component — **2,637 lines** |

### All Files Participating in Dashboard Rendering

| File | Lines | Role |
|------|-------|------|
| `src/components/Dashboard.tsx` | 2,810 | Main dashboard (KPI bar, TIME/PAID charts, app table, filters, modals) |
| `src/components/AssessmentScoreCard.tsx` | 151 | Inline score display (BF + TH) per deployment row |
| `src/components/modals/DrillDownModal.tsx` | 228 | TIME/PAID drill-down table modal |
| `src/components/modals/ApplicationsOverviewModal.tsx` | 472 | KPI card click-through — overview by owner, portfolio, status |
| `src/components/modals/TechDebtModal.tsx` | 372 | KPI card click-through — tech debt breakdown by T-shirt size |
| `src/components/modals/BusinessFitModal.tsx` | 149 | KPI card click-through — BF distribution histogram |
| `src/components/modals/TechHealthModal.tsx` | 149 | KPI card click-through — TH distribution histogram |
| `src/components/UnsubscribeAppModal.tsx` | 106 | Confirmation dialog for consumer unsubscribe |
| `src/components/RemoveFromPortfolioModal.tsx` | 173 | Smart removal dialog (blocks if last assignment) |
| `src/lib/scoring.ts` | 318 | TIME_COLORS, PAID_COLORS, TIME_BG_COLORS, PAID_BG_COLORS constants |
| `src/lib/utils/costs.ts` | 13 | `getTotalAnnualCost()` |
| `src/lib/utils/formatting.ts` | 28 | `formatCurrency()` |
| `src/lib/techDebtSync.ts` | 48 | `calculateTShirtFromDollar()` |
| `src/hooks/useRemediationSettings.ts` | 105 | Fetches remediation thresholds from `organization_settings` |
| `src/hooks/useTierLimits.ts` | 174 | Tier/feature gating hook |
| `src/utils/usageTracking.ts` | 28 | `logUsageEvent()` — audit log insertion |
| **Total** | **~5,324** | |

---

## 2. Component Tree

```
Dashboard (src/components/Dashboard.tsx)
├── KPI Bar (5 cards, inline)
│   ├── Business Applications card → navigates to /applications/overview
│   ├── Annual Run Rate card → navigates to cost-analysis page
│   ├── Est. Tech Debt card → opens TechDebtModal
│   ├── Avg Business Fit card → opens BusinessFitModal
│   └── Avg Tech Health card → opens TechHealthModal
│   └── [Budget Health card — hidden behind `{false &&}`]
├── TIME Distribution panel (inline horizontal bar chart)
│   └── Rows are clickable → open DrillDownModal
├── PAID Distribution panel (inline horizontal bar chart)
│   └── Rows are clickable → open DrillDownModal
├── Applications table (inline, 3 rendering patterns)
│   ├── SortIcon (inline sub-component)
│   └── AssessmentScoreCard (per deployment row)
├── Filter modals (all inline in Dashboard.tsx)
│   ├── Portfolio/Workspace filter modal (~90 lines)
│   ├── Lifecycle filter modal (~75 lines)
│   └── Operational status filter modal (~75 lines)
├── Detail modals (imported components)
│   ├── ApplicationsOverviewModal
│   ├── TechDebtModal
│   ├── BusinessFitModal
│   └── TechHealthModal
├── Action modals (imported components)
│   ├── UnsubscribeAppModal
│   ├── RemoveFromPortfolioModal
│   └── Consumer error modal (inline, ~30 lines)
└── DrillDownModal
```

---

## 3. Three Rendering Patterns

The app table (`<tbody>`) uses a branching strategy based on `groupedApplications` and `groupedSinglePortfolio`. Within `groupedApplications`, a further branch occurs per app based on portfolio count and deployment profile count.

### Pattern 1: Single DP (Flat Row)

**Trigger:** `portfolioCount === 1 && totalDPCount === 1` (lines 1389-1549)

**Condition context:** This is a single app with one portfolio assignment and one deployment profile — the common case for most users.

**What renders:** A single flat `<tr>` with all columns filled:
- ID, Name (with operational status dot, consumer/publisher/integration badges), Workspace (conditional), Portfolio/Lifecycle, AssessmentScoreCard, TIME badge, PAID badge, Total Annual Cost, Actions (View Details, Move/Copy, Remove)

**Supabase queries:** None — all data comes from props.

**KPIs/metrics displayed:** Scores inline via `AssessmentScoreCard`, TIME/PAID badges, formatted cost.

### Pattern 2: Single Portfolio, Multiple DPs (Expandable)

**Trigger:** `portfolioCount === 1 && totalDPCount > 1` (lines 1552-1772)

**Condition context:** The app has multiple deployment profiles within the same portfolio (e.g., PROD + DEV environments).

**What renders:**
- **Parent row:** App name with chevron expander, deployment count badge, dash placeholders for scores/TIME/PAID/cost
- **Child rows** (when expanded): One row per deployment profile showing `└─ DP Name`, AssessmentScoreCard, TIME/PAID badges, cost

**Supabase queries:** None — all data from props.

### Pattern 3: Multiple Portfolios (3-Level Hierarchy)

**Trigger:** `portfolioCount > 1` (lines 1775-2053, rendered via `groupedApplications`)

**Condition context:** "All Portfolios" view where an app appears in multiple portfolios.

**What renders:**
- **Level 1 — App row:** Name with chevron, "In N portfolios" badge, deployment count badge, all score/cost columns show dashes
- **Level 2 — Portfolio rows** (when app expanded): Portfolio name with chevron, deployment count badge
- **Level 3 — DP rows** (when portfolio expanded): `└─ DP Name`, AssessmentScoreCard, TIME/PAID badges, cost

**Supabase queries:** None — all data from props.

### Alternate Single-Portfolio Path

**Trigger:** `groupedApplications` is null/falsy AND `groupedSinglePortfolio` is truthy (lines 2055-2382)

**Condition context:** Fallback single-portfolio rendering path. Similar to Patterns 1/2 but using `groupedSinglePortfolio` map.

**What renders:**
- Single-DP apps: Flat row with lifecycle column, scores, TIME/PAID, cost
- Multi-DP apps: Parent row with chevron + child DP rows when expanded
- **Key difference:** Shows "Application Lifecycle" column instead of "Portfolio" column

**Note:** Both `groupedApplications` and `groupedSinglePortfolio` are always computed. The table body uses `groupedApplications ? (...) : groupedSinglePortfolio ? (...) : null`. Since `groupedApplications` is always a Map (never null), the `groupedSinglePortfolio` branch is effectively dead code. A comment on line 528-531 documents a past bug where an early return broke single-portfolio rendering.

---

## 4. State Management

### useState Hooks (24 total)

| Hook | Type | Purpose |
|------|------|---------|
| `deleteConfirm` | `string \| null` | Tracks which app row has deletion pending |
| `showUnsubscribeModal` | `boolean` | Toggle unsubscribe confirmation |
| `unsubscribeTarget` | `{app, portfolioName} \| null` | Target for unsubscribe |
| `showRemoveModal` | `boolean` | Toggle remove-from-portfolio confirmation |
| `removeTarget` | `{app, portfolioName} \| null` | Target for removal |
| `showConsumerErrorModal` | `boolean` | Toggle consumer-exists error dialog |
| `consumerErrorCount` | `number` | Count of consumers blocking removal |
| `sortField` | `SortField` | Current sort column (default: `app_id`) |
| `sortDirection` | `SortDirection` | `asc` / `desc` |
| `showFilterModal` | `boolean` | Portfolio/workspace filter dialog |
| `showLifecycleFilterModal` | `boolean` | Lifecycle filter dialog |
| `showOperationalFilterModal` | `boolean` | Operational status filter dialog |
| `selectedPortfolios` | `Set<string>` | Active portfolio filters |
| `selectedWorkspaces` | `Set<string>` | Active workspace filters |
| `selectedLifecycleStatuses` | `Set<LifecycleStatus>` | Active lifecycle filters |
| `selectedOperationalStatuses` | `Set<OperationalStatus>` | Active operational status filters |
| `selectedTimeQuadrants` | `Set<string>` | TIME quadrant filter (initialized but **never exposed via UI**) |
| `activeDetailModal` | `DetailModal` | Which KPI detail modal is open |
| `expandedApps` | `Set<string>` | Which app rows are expanded |
| `expandedDeploymentProfiles` | `Set<string>` | Which portfolio sub-rows are expanded |
| `canPublish` | `boolean` | Whether user can publish apps |
| `canSubscribe` | `boolean` | Whether user can subscribe to shared apps |
| `budgetFilterActive` | `boolean` | Budget issues filter (hidden behind `{false &&}`) |
| `overBudgetWorkspaces` | `array` | Over-budget workspaces (hidden feature) |
| `eliminateAppIds` | `string[]` | Eliminate-quadrant app IDs (hidden feature) |
| `budgetHealthLoading` | `boolean` | Loading state for budget health (hidden feature) |
| `drillOpen` | `boolean` | Drill-down modal toggle |
| `drillTitle` | `string` | Drill-down modal title |
| `drillType` | `'TIME' \| 'PAID' \| 'DEFAULT'` | Drill-down context |
| `drillApps` | `any[]` | Drill-down filtered app list |

### useEffect Hooks (5 total)

| # | Dependencies | Purpose |
|---|-------------|---------|
| 1 | `[namespace_id, user_id, portfolioName, isAllPortfolios]` | Log usage event to `audit_logs` |
| 2 | `[namespace_id]` | Fetch budget health (over-budget workspaces + eliminate apps) |
| 3 | `[onSetRestoreModalCallback]` | Wire up modal restoration callback |
| 4 | `[isWorkspaceAdmin, currentWorkspace, hasFeature]` | Check publish permissions via `workspace_group_members` |
| 5 | `[currentWorkspace, hasFeature]` | Check subscribe permissions via `workspace_group_members` + `workspace_group_publications` |

### useMemo Hooks (7 total)

| # | Dependencies | Purpose |
|---|-------------|---------|
| 1 | `[propsApplications]` | `uniquePortfolios` — distinct portfolio names for filter dropdown |
| 2 | `[propsApplications]` | `uniqueWorkspaces` — distinct workspace names for filter dropdown |
| 3 | `[propsApplications, selectedPortfolios, ...]` | `filteredApplications` — apply all active filters |
| 4 | `[filteredApplications]` | `totalTechDebt` — sum of `estimated_tech_debt` across all DPs |
| 5 | `[filteredApplications, isAllPortfolios]` | `groupedApplications` — 3-level hierarchy (App > Portfolio > DP) |
| 6 | `[filteredApplications, isAllPortfolios]` | `groupedSinglePortfolio` — 2-level hierarchy (App > DP) |
| 7 | `[filteredApplications, sortField, sortDirection]` | `sortedApplications` — used only by CSV export |

### Filters Available

| Filter | UI Control | Where |
|--------|-----------|-------|
| Portfolio | Checkbox modal | "All Portfolios" view only |
| Workspace | Checkbox modal | Namespace-level view only |
| Lifecycle Status | Checkbox modal | "All Portfolios" view only (table header button) |
| Operational Status | Checkbox modal | Always visible (Running/Planned/Retired) |
| TIME Quadrant | `selectedTimeQuadrants` state exists but **no UI to set it** |
| Budget Issues | Toggle button (hidden behind `{false &&}`) | N/A — disabled |

### Workspace/Portfolio Selection

Dashboard itself does **not** handle workspace or portfolio selection. It receives `workspaceId`, `portfolioId`, `isAllPortfolios`, and the pre-filtered `applications` array as props from its parent. The parent page is responsible for the workspace/portfolio picker and data loading.

---

## 5. Data Flow

### Supabase `.from()` Calls Inside Dashboard.tsx

| # | Table/View | Query Purpose | Lines |
|---|-----------|--------------|-------|
| 1 | `vw_workspace_budget_summary` | Over-budget workspaces (hidden feature) | 235-239 |
| 2 | `portfolio_assignments` | Eliminate-quadrant app IDs (hidden feature) | 244-256 |
| 3 | `workspace_group_members` | Check publish permissions | 347-353 |
| 4 | `workspace_group_members` | Check subscribe permissions (round 1) | 368-372 |
| 5 | `workspace_group_publications` | Check subscribe permissions (round 2) | 381-387 |
| 6 | `portfolio_assignments` | Check consumer count before removal | 402-406 |

### Supabase `.from()` Calls in Child Components

| Component | Table/View | Purpose |
|-----------|-----------|---------|
| `ApplicationsOverviewModal` | `portfolios` | Fetch portfolio IDs for workspace |
| `ApplicationsOverviewModal` | `workspaces` | Fetch workspace IDs for namespace |
| `ApplicationsOverviewModal` | `deployment_profiles` | Fetch profiles with nested app + PA joins |
| `ApplicationsOverviewModal` | `application_contacts` | Fetch business owners |
| `TechDebtModal` | `deployment_profiles` | Fetch all DPs for expense breakdown |
| `UnsubscribeAppModal` | `portfolio_assignments` | DELETE — unsubscribe consumer |
| `RemoveFromPortfolioModal` | `portfolio_assignments` | SELECT count + DELETE |
| `useRemediationSettings` | `organization_settings` | Fetch remediation config |
| `useTierLimits` | `users`, `namespaces`, `workspaces`, `portfolios`, `applications` | Tier + usage counts |
| `usageTracking` | `audit_logs` | INSERT — fire-and-forget event |

### Primary Data Source

The `applications: ApplicationWithScores[]` prop is the primary data source — it is **not** fetched inside Dashboard.tsx. The parent page fetches it (likely from a view like `vw_portfolio_dashboard` or by joining `applications`, `deployment_profiles`, `portfolio_assignments`, and running score calculations client-side).

---

## 6. Reusable Components

### Already Extracted as Reusable Components

| Component | Reused? | Notes |
|-----------|---------|-------|
| `AssessmentScoreCard` | Yes (used ~6 times across patterns) | Well-extracted, consistent props |
| `DrillDownModal` | Yes (1 instance, reused for TIME + PAID) | Generic drill-down table |
| `ApplicationsOverviewModal` | Once | Self-contained, does its own data loading |
| `TechDebtModal` | Once | Self-contained |
| `BusinessFitModal` | Once | Presentational only |
| `TechHealthModal` | Once | Near-clone of BusinessFitModal |
| `UnsubscribeAppModal` | Once | Specific to consumer flows |
| `RemoveFromPortfolioModal` | Once | Specific to publisher flows |
| `formatCurrency()` | Widely | Utility function |
| `getTotalAnnualCost()` | Widely | Utility function |

### Inline / Not Extracted (Should Be)

| UI Pattern | Location | Duplicated? | Suggested Component |
|-----------|----------|-------------|-------------------|
| **KPI stat cards** (5 cards in a grid) | Lines 984-1121 | Each card is ~20 lines of similar structure | `DashboardKpiCard` |
| **TIME distribution bar chart** | Lines 1123-1180 | Unique | `DistributionBarPanel` |
| **PAID distribution bar chart** | Lines 1182-1236 | Near-identical to TIME panel | `DistributionBarPanel` (shared) |
| **App table row (flat, Pattern 1)** | Lines 1400-1548 | Row layout duplicated across all 3 patterns | `AppTableRow` |
| **DP child row** | Lines 1686-1769 | Repeated in Patterns 2, 3, and alternate path | `DeploymentProfileRow` |
| **Portfolio sub-row** (Pattern 3) | Lines 1910-1960 | Unique to Pattern 3 | `PortfolioGroupRow` |
| **Action buttons** (View/Move/Remove) | Lines 1501-1544 | Repeated ~4 times identically | `AppActionButtons` |
| **TIME/PAID badge** | Lines 1468-1496 | Rendered ~6 times with same logic | `QuadrantBadge` |
| **Filter modal shell** | Lines 2393-2650 | Three near-identical modal structures | `FilterModal` (generic) |
| **Consumer error modal** | Lines 2767-2797 | Inline, should be extracted | `ConsumerErrorModal` |
| **Operational status dot** | Lines 1408-1418 | Repeated in every pattern | Part of `AppNameCell` |
| **Integration count badge** | Lines 1430-1435 | Repeated in every pattern | Part of `AppNameCell` |
| **Consumer/publisher icons** | Lines 1420-1429 | Repeated in every pattern | Part of `AppNameCell` |

---

## 7. Modularity Assessment

### God-Function: `Dashboard` Component (2,637 lines)

The main `Dashboard` function is a textbook god-component. It handles:
1. State management for 24+ state variables
2. 5 useEffect hooks (data fetching, permission checks, event logging)
3. 7 useMemo computations (filtering, grouping, sorting, aggregation)
4. Business logic (budget health, publish/subscribe permissions, consumer checks)
5. CSV export generation (~100 lines)
6. 3 different table rendering patterns (~1,200 lines of JSX)
7. 3 inline filter modals (~240 lines)
8. 1 inline error modal (~30 lines)

### God-Function: `calculateSummary()` (104 lines)

Performs complex client-side aggregation with deduplication across TIME/PAID distributions, cost rollup, and score averaging. This logic should move to a database view (`vw_dashboard_summary`).

### Shared UI Patterns Duplicated Across Patterns

1. **App name cell** (name + operational dot + consumer icon + publisher icon + integration badge + description tooltip) — duplicated 4 times (~30 lines each = 120 lines total)
2. **TIME/PAID badge rendering** — duplicated 6+ times (~10 lines each = 60+ lines)
3. **Action buttons column** (View Details + Move/Copy + Remove) — duplicated 4 times (~40 lines each = 160 lines)
4. **AssessmentScoreCard usage** — same props pattern repeated 6 times
5. **Filter modal structure** — 3 near-identical modals with Select All / Clear All / checkbox list

### Proposed Component Breakdown

```
src/components/dashboard/
├── Dashboard.tsx                    # Orchestrator (~200 lines)
│   ├── useDashboardState.ts         # State + filters + permissions hook
│   └── useDashboardData.ts          # Budget health, publish/subscribe checks
├── DashboardKpiBar.tsx              # 5-card KPI row
│   └── DashboardKpiCard.tsx         # Single KPI card (icon, label, value)
├── DashboardDistributionPanel.tsx   # TIME or PAID horizontal bar chart
├── DashboardAppTable.tsx            # Table shell (thead + sort logic)
│   ├── AppTableRow.tsx              # Flat single-DP row (Pattern 1)
│   ├── AppExpandableRow.tsx         # Multi-DP parent row (Pattern 2)
│   ├── AppMultiPortfolioRow.tsx     # Multi-portfolio parent row (Pattern 3)
│   ├── DeploymentProfileRow.tsx     # DP child row (shared across patterns)
│   ├── PortfolioGroupRow.tsx        # Portfolio sub-row (Pattern 3 only)
│   ├── AppNameCell.tsx              # Name + status dot + badges + tooltip
│   ├── QuadrantBadge.tsx            # TIME or PAID colored badge
│   └── AppActionButtons.tsx         # View/Move/Remove action column
├── DashboardFilterModal.tsx         # Generic checkbox filter modal
├── DashboardCsvExport.ts            # CSV export logic (pure function)
└── dashboardHelpers.ts              # calculateSummary, getOverallAssessmentStatus
```

**Estimated reduction:** Dashboard.tsx from 2,810 lines to ~200 lines (orchestration only).

---

## 8. Pain Points

### 8.1 Client-Side Aggregations That Should Move to DB Views

| Current Logic | Location | Should Be |
|--------------|----------|-----------|
| `calculateSummary()` — TIME/PAID distribution counts, percentages, costs; avg BF/TH; total licensing cost | Lines 59-163 | `vw_dashboard_summary` — pre-aggregated per workspace/portfolio |
| `uniqueAppCount` / `totalDeploymentProfiles` counting via `new Set()` | Lines 507-508 | Part of `vw_dashboard_summary` |
| `totalTechDebt` summation | Lines 510-515 | Part of `vw_dashboard_summary` |
| `groupedApplications` — 3-level hierarchy construction | Lines 532-568 | `vw_dashboard_workspace_breakdown` or query-level grouping |
| `groupedSinglePortfolio` — 2-level grouping | Lines 571-582 | Same |
| `sortedApplications` — full sort for CSV export | Lines 584-625 | Could be server-side if export moves to API |
| `filteredApplications` — multi-filter pipeline | Lines 440-503 | Partially — filters could be query params |

### 8.2 Hardcoded Values

| Value | Location | Issue |
|-------|----------|-------|
| `['Mainstream', 'Extended', 'End of Support']` | Lines 530, 679 | Hardcoded lifecycle statuses — should fetch from `lifecycle_statuses` ref table |
| `['operational', 'planned', 'retired']` | Lines 609, 699 | Hardcoded operational statuses — likely needs a ref table |
| `PAID_DISTRIBUTION_COLORS` object | Lines 165-171 | Hardcoded color map (acceptable for styling, but duplicates `PAID_COLORS` from `scoring.ts`) |
| TIME color map in distribution panel | Lines 1155-1172 | Inline color logic duplicates `TIME_COLORS` from `scoring.ts` |
| Score threshold of 50 in BusinessFitModal/TechHealthModal | In modal files | Hardcoded threshold — should come from settings |
| Budget filter URL param `'issues'` | Line 220 | Magic string |

### 8.3 Dead or Hidden Code

| Item | Location | Status |
|------|----------|--------|
| Budget Health card | Lines 1078-1120 | Hidden behind `{false &&}` |
| Budget filter banner | Lines 853-868 | Hidden behind `{false && budgetFilterActive}` |
| `budgetFilterActive` / `overBudgetWorkspaces` / `eliminateAppIds` state | Lines 220-223 | State + fetch still runs but results are never displayed |
| `selectedTimeQuadrants` | Line 198 | State exists but no UI to modify it |
| `groupedSinglePortfolio` rendering branch | Lines 2055-2382 | Effectively dead — `groupedApplications` is always truthy (a Map) |
| `sortedApplications` | Lines 584-625 | Only used by CSV export — not used for table rendering |

### 8.4 Code Smells

| Smell | Location | Impact |
|-------|----------|--------|
| **`(app as any).workspace_id`** | Line 493 | Type assertion bypass — `workspace_id` not on `ApplicationWithScores` type |
| **`drillApps: any[]`** | Line 289 | Loose typing for drill-down data |
| **`(item: any)`** in eliminate data mapping | Line 258 | No type safety on nested query result |
| **Duplicated tooltip calculation** | Lines 1396-1397, 1693-1694, 2261-2262 | `tooltipPublisher` / `tooltipPublisher3` / `tooltipPublisherSP` — same logic copy-pasted |
| **`window.location.reload()`** | Lines 2737, 2756 | Full page reload after unsubscribe/remove instead of React state update |
| **`console.error` for error handling** | Lines 262, 409 | Should use toast notifications per CLAUDE.md rules |
| **Missing `budgetFilterActive` in useMemo deps** | Line 503 | `filteredApplications` memo lists deps but `budgetFilterActive` and `overBudgetWorkspaces`/`eliminateAppIds` are missing — stale closure risk |

### 8.5 Architecture Opportunities with New Views

When `vw_dashboard_summary` and `vw_dashboard_workspace_breakdown` are available:

1. **Replace `calculateSummary()`** entirely with a single `supabase.from('vw_dashboard_summary').select('*')` call
2. **Replace `groupedApplications` / `groupedSinglePortfolio`** useMemo with structured data from `vw_dashboard_workspace_breakdown`
3. **Remove `totalTechDebt` client computation** — pre-aggregated in the view
4. **Remove `uniqueAppCount` / `totalDeploymentProfiles` counting** — pre-aggregated in the view
5. **Simplify filtering** — push portfolio/workspace/lifecycle/operational filters to the query level
6. **Eliminate the `budget health` useEffect** — budget status can be a column in the dashboard summary view

---

## Summary

Dashboard.tsx is a 2,810-line monolithic component that:
- Defines 4 functions (including a 2,637-line main component)
- Manages 24+ state variables
- Contains 3 inline filter modals + 1 inline error modal
- Implements 3 table rendering patterns with heavily duplicated row JSX
- Performs significant client-side aggregation that should move to database views
- Has ~200 lines of dead/hidden code still executing (budget health fetches)
- Has hardcoded dropdown values that violate the project's reference-table rule

The file is the single largest pain point for maintainability in the codebase and is the primary target for the dashboard refresh.
