# Audit: Application Health Grid — Full Component Assessment

*Produced: February 27, 2026*

## Context
Before adding filter drawer and action panels (Phase C.4), we need a complete picture of the Application Health grid — what's there, what's sound, and what needs work.

---

## 1. Component Map

The grid is a 3-level hierarchical table system totaling ~2,400 lines across 16 files in `src/components/dashboard/`.

### Core Components

| File | Lines | Purpose |
|------|-------|---------|
| `DashboardPage.tsx` | 717 | Top-level container; filter/sort/modal state; KPI bar, distribution panels, grid |
| `DashboardAppTable.tsx` | 340 | Main table wrapper; 3-pattern row rendering; expand/collapse state |
| `dashboardHelpers.ts` | ~182 | Types (`AppGroup`, `PortfolioWithDPs`), helpers (`getOverallAssessmentStatus`, `calculateSummary`, `computeConsumerBadgeInfo`) |

### Row Components (3-level hierarchy)

| File | Lines | Pattern | When Used |
|------|-------|---------|-----------|
| `AppTableRow.tsx` | 82 | **Flat** (1 portfolio, 1 DP) | Single row, no nesting |
| `AppExpandableRow.tsx` | 105 | **Expandable** (1 portfolio, 2+ DPs) | Parent + nested DP rows |
| `AppMultiPortfolioRow.tsx` | 123 | **Multi-Portfolio** (2+ portfolios) | 3-level: App → Portfolio → DP |
| `PortfolioGroupRow.tsx` | 97 | Level-2 sub-row | Portfolio header under multi-portfolio apps |
| `DeploymentProfileRow.tsx` | 112 | Level-3 sub-row | DP data row with scores, costs, actions |

### Cell/Widget Components

| File | Lines | Purpose |
|------|-------|---------|
| `AppNameCell.tsx` | 102 | Name column: app name + status dot + badges (DPs, portfolios, consumer/publisher icons, integration count) |
| `AppActionButtons.tsx` | 53 | Action column: Target, ArrowUpRight, Trash2 icons |
| `QuadrantBadge.tsx` | 33 | TIME/PAID badge with color styling |
| `AssessmentScoreCard.tsx` | 152 | Business & Tech score display with Start/Continue/Edit buttons |
| `DashboardKpiBar.tsx` | 128 | 5-card KPI summary (Applications, Annual Cost, Tech Debt, Business Fit, Tech Health) |
| `DistributionPanel.tsx` | 107 | TIME/PAID quadrant distribution bar charts with drill-down |

### Hooks

| File | Lines | Purpose |
|------|-------|---------|
| `hooks/useDashboardFilters.ts` | 182 | Filter state: Portfolio, Workspace, Lifecycle Status, Operational Status |
| `hooks/useDashboardSummary.ts` | 159 | Computes summary stats (avg scores, distributions, costs) from filtered data |

---

## 2. Column Inventory

### Standard Columns (always shown)

| # | Header | Data Source | Sortable | Notes |
|---|--------|------------|----------|-------|
| 1 | **ID** | `app.app_id` | Yes | Centered numeric ID |
| 2 | **Name** | `app.name` | Yes | + status dot, badges, consumer/publisher icons (see section 5) |
| 3 | **Assessment** | `business_assessment_status`, `tech_assessment_status`, scores | No | Complex conditional rendering (see section 4) |
| 4 | **TIME** | `deployment.timeQuadrant` | Yes | Colored badge (Invest/Tolerate/Modernize/Eliminate) or "—" |
| 5 | **PAID** | `deployment.paidAction` | Yes | Colored badge (Plan/Address/Delay/Ignore) or "—" |
| 6 | **Total Annual Cost** | `annual_licensing_cost + annual_tech_cost` | Yes | Right-aligned formatted currency |
| 7 | **Actions** | — | No | 3 icon buttons (see section 3) |

### Context-Dependent Columns

| Column | Shown When | Data |
|--------|-----------|------|
| **Workspace** | `showWorkspaceColumn === true` (All Portfolios) | `app.workspaceName` |
| **Portfolio** | `isAllPortfolios === true` | Portfolio name; sortable |
| **Application Lifecycle** | `!isAllPortfolios` (single portfolio) | Lifecycle status |

### Sortable Fields
`app_id`, `name`, `portfolio`, `status`, `businessFit`, `techHealth`, `time`, `paid`, `cost`

Sort icons: `ArrowUpDown` (unsorted, gray) → `ArrowUp` (asc, teal) → `ArrowDown` (desc, teal)

---

## 3. Action Buttons

**File:** `rows/AppActionButtons.tsx` (53 lines)

| # | Icon | Lucide Name | Action | Visibility |
|---|------|-------------|--------|------------|
| 1 | Crosshair/target | `Target` | Navigates to `/applications/:id` (edit page) | Always shown |
| 2 | Diagonal arrow | `ArrowUpRight` | Opens `MoveOrCopyModal` | Hidden in All Portfolios view |
| 3 | Trash | `Trash2` | Removes app from portfolio (consumer: unsubscribe; publisher: remove with subscriber check) | Admin only + hidden in All Portfolios |

### Trash Button Details
- **Consumer apps:** Opens `UnsubscribeAppModal`
- **Publisher apps:** Checks for subscribers first — if subscribers exist, shows blocking error modal ("Cannot Remove — Subscribers Exist"); otherwise opens `RemoveFromPortfolioModal`
- **Tooltip:** Dynamically shows "Unsubscribe" for consumers, "Remove from Portfolio" for publishers

**Observation:** No guard for "last app in portfolio" — removal proceeds regardless. Cascade to deployment profiles is handled by the database (cascade delete on portfolio_assignment).

---

## 4. Assessment Score Cells

**File:** `AssessmentScoreCard.tsx` (152 lines)

### Display Logic

| Status | Score Display | Button (Publisher) | Button (Consumer) |
|--------|-------------|-------------------|-------------------|
| `not_started` | — | `[Start]` (blue) | Business: `[Start]`; Tech: Pending (gray, disabled) |
| `in_progress` | — | `[Continue]` (blue/teal) | Business: `[Continue]`; Tech: In Progress (amber) |
| `complete` | Score value (e.g. "45.2") | `[Edit]` (blue/teal) | Business: `[Edit]`; Tech: `[View]` (green, read-only) |

### Button Colors
- Business buttons: blue (`text-blue-600`)
- Tech buttons (publisher): teal (`text-teal-600`)
- Tech buttons (consumer complete): green (`text-green-600`)

### Button Visibility
- **Buttons only shown when `showButtons === true`** — set to `false` in All Portfolios view
- In All Portfolios mode: scores display but are not actionable

### Click Flow
Any button click → `onAssessApplication(deployment, undefined, 'business' | 'technical')` → sets `mainView = 'assessment'` → renders `PortfolioAssessmentWizard` (1,142 lines) with `initialTab` and `editableTab` props.

### Consumer Restriction
Consumers can edit Business assessment but **cannot edit Technical** — tech is managed by the publisher portfolio. When tech is `not_started`, consumer sees disabled "Pending" with tooltip: *"Technical assessment managed by {publisher portfolio}"*.

---

## 5. Badge/Indicator Dots

### Status Dot (next to app name)
**File:** `AppNameCell.tsx` lines 54-65

| `operational_status` | Color | Tooltip |
|---------------------|-------|---------|
| `operational` | Green (`bg-green-500`) | "Running" |
| `planned` | Blue (`bg-blue-500`) | "Planned" |
| `retired` | Gray (`bg-gray-400`) | "Retired" |

Size: `w-2 h-2` (tiny dot)

### Deployment Count Badge
**Shown on:** Expandable rows (Pattern 2) and multi-portfolio parent rows (Pattern 3)

Green pill: `bg-green-50 text-green-700` — e.g., "3 deployments"

### Portfolio Count Badge
**Shown on:** Multi-portfolio parent rows (Pattern 3) only

Blue pill: `bg-blue-50 text-blue-700` — e.g., "In 2 portfolios"

### Consumer/Publisher Icons

| Icon | Lucide Name | Color | When Shown | Meaning |
|------|-------------|-------|-----------|---------|
| Down-left arrow | `ArrowDownLeft` | Blue (`text-blue-500`) | `isConsumer === true` | Subscribed from another portfolio |
| Share | `Share2` | Gray (`text-gray-400`) | `isPublisher && hasConsumers` | Shared with other portfolios |

### Integration Count Badge
Blue pill with link icon: `bg-blue-50 text-blue-700` — shown only if `integrationCount > 0`

---

## 6. Nested DP Expansion

### Expand/Collapse State
```typescript
// DashboardAppTable.tsx
const [expandedApps, setExpandedApps] = useState<Set<string>>(new Set());
const [expandedDeploymentProfiles, setExpandedDeploymentProfiles] = useState<Set<string>>(new Set());
```

### Pattern 1: Flat (1 portfolio, 1 DP)
Single `AppTableRow` — all columns populated, no expand button.

### Pattern 2: Expandable (1 portfolio, 2+ DPs)

| Level | Component | Columns Filled | Actions? | Background |
|-------|-----------|---------------|----------|------------|
| Parent | `AppExpandableRow` | ID, Name (+ chevron + DP count badge) — scores/quadrants/cost empty ("—") | Yes (Edit, Move, Remove) | default |
| Child DP | `DeploymentProfileRow` | Name (indented `pl-5`), Assessment, TIME, PAID, Cost | No | `bg-gray-50` |

Expand toggle: chevron icon in name column. Uses `expandedApps` set keyed by `appId`.

### Pattern 3: Multi-Portfolio (2+ portfolios)

| Level | Component | Indent | Background | Actions? |
|-------|-----------|--------|------------|----------|
| 1 — App | `AppMultiPortfolioRow` | none | default | Yes |
| 2 — Portfolio | `PortfolioGroupRow` | `pl-5` | `bg-gray-50` | No |
| 3 — DP | `DeploymentProfileRow` | `pl-10` | `bg-gray-100` | No |

Level 3 DPs show inline TIME badge next to DP name (via `showInlineTimeBadge` prop) instead of in the TIME column.

Portfolio expand uses `expandedDeploymentProfiles` set keyed by `"${appId}-${portfolioName}"`.

---

## 7. Data Sources

### Primary: `useApplications` hook (via App.tsx → `useApplicationPool`)

| Query | Table/View | Columns | Filters |
|-------|-----------|---------|---------|
| 1 | `portfolios` | `id` | `workspace_id` match |
| 2 | `portfolio_assignments` | `application_id` | portfolios from query 1 |
| 3 | `applications` | `*` + contacts | `workspace_id` match (owned) + IDs from subscriptions |
| 4 | `portfolio_assignments` | full join (application, portfolio, deployment_profile) | app IDs from query 3 |
| 5 | `deployment_profiles` | scores, costs, assessment status | `is_primary = true` |
| 6 | `vw_application_integration_summary` | integration counts | app IDs from query 3 |
| 7 | `portfolios` | names | for publisher portfolio name mapping |

**Enriches each app with:** `scores`, `timeQuadrant`, `paidAction`, `annual_cost`, `assessmentComplete`, `isConsumer`, `isPublisher`, `publisherPortfolioName`, `integrationCount`

### Secondary: KPI/Summary

| Query | Table/View | Purpose |
|-------|-----------|---------|
| 8 | `vw_dashboard_summary` | Namespace-wide KPI aggregates |
| 9 | `vw_dashboard_workspace_breakdown` | Per-workspace breakdown |

### Scope Compliance
- Respects `currentWorkspace` (filters by `workspace_id`)
- Handles `all-workspaces` mode (namespace-level filtering)
- Portfolio filtering done client-side in `useDashboardFilters`
- All data fetched upfront, then filtered client-side (no server-side pagination)

---

## 8. Pagination

**Status: NOT IMPLEMENTED**

- `TablePagination.tsx` exists in `src/components/shared/` (page sizes: 10, 25, 50, 100, All)
- It is **not imported** anywhere in the dashboard folder
- `DashboardAppTable` renders ALL `filteredApplications` without row limits
- No `currentPage`, `pageSize`, or pagination state exists

**Risk:** Large portfolios (100+ apps with multi-DP expansion) render hundreds of DOM rows, impacting scroll performance.

---

## 9. Known Issues / Tech Debt

### Hardcoded Filter Dropdowns (CLAUDE.md violation)

**File:** `DashboardPage.tsx` lines 34-43

```typescript
const LIFECYCLE_FILTER_OPTIONS = [
  { value: 'Mainstream', ... },
  { value: 'Extended', ... },
  { value: 'End of Support', ... },
];

const OPERATIONAL_FILTER_OPTIONS = [
  { value: 'operational', ... },
  { value: 'planned', ... },
  { value: 'retired', ... },
];
```

Both should fetch from reference tables per architecture rules. Need to check if `lifecycle_statuses` reference table exists.

### Console.log Pollution

`useApplications` hook contains ~13 `console.log` statements logging raw data (assignments, apps, deployment profiles). Performance concern with large datasets; should be removed.

### Cost Calculation Inconsistency

- `useApplications` computes cost as `annual_licensing_cost + annual_tech_cost` from deployment_profiles
- `usePortfolioAssignments` pulls from `vw_deployment_profile_costs` view
- Potential mismatch if the view calculation differs from the hook math

### No Pagination

Grid loads and renders all rows. `TablePagination.tsx` component exists but isn't wired up. Should be added for portfolios with 50+ apps.

### No TODO/FIXME Comments

Grid components are clean of temporary markers.

### Unused Computed Data (minor)

`useDashboardFilters` computes `uniqueOwners` and `uniquePrimarySupports` but these aren't used by the dashboard grid. Minor dead weight.

### View Contract Drift Risk

Dashboard TypeScript interfaces (`VwDashboardSummary`, `VwDashboardWorkspaceBreakdown`) must exactly match view columns. If view changes, fields silently become `undefined` — no compile error. (This is the same class of bug that broke the budget page previously.)

---

## Summary

| Area | Status | Notes |
|------|--------|-------|
| Component structure | Sound | 3-pattern hierarchy is well-organized |
| Column inventory | Complete | 7 standard + 3 context-dependent columns |
| Action buttons | Clean | 53 lines, well-guarded with admin/portfolio checks |
| Assessment flow | Sophisticated | Publisher/consumer distinction handled correctly |
| Badge system | Informative | Status dots, DP counts, consumer/publisher icons, integration counts |
| Nested expansion | Works | 3-level expand/collapse with proper state management |
| Data sources | Heavy | ~7 sequential Supabase queries, all client-side |
| Pagination | Missing | `TablePagination` exists but not wired up |
| Hardcoded dropdowns | Violation | Lifecycle + Operational status arrays hardcoded |
| Console.log noise | Cleanup needed | ~13 logging statements in data hook |
