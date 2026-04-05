# Dan Warfield UX Review — Codebase Findings

**Date:** 2026-04-04
**Reviewer:** Dan Warfield (strategic advisor, fellow architect)
**Context:** First-time user review with no prior data entry. Raw reactions triaged into 7 actionable points.
**Investigated by:** Claude Code (Opus) — read-only codebase analysis

---

## Summary

Dan's feedback clusters into two themes: (1) **the Overview tab is a dead end** — every KPI card is non-clickable and there is no drill-down path, and (2) **scope communication is too subtle** — the namespace-level nature of Overview is conveyed only through a 40% opacity dimming that Dan did not register. Of the 7 points investigated, **none are currently addressed in code** — all require implementation work. The good news: Explorer already supports the filters needed for most drill-down targets (crown jewel, TIME quadrant, lifecycle status), and `deployment_profiles.assessed_at` already exists in the schema for staleness tracking. The infrastructure gap is primarily in wiring navigation state between Overview cards and Explorer filters.

---

## Point 1: Scope Bar Visual Grouping

### Current State

**Files:**
- `src/App.tsx` (lines 606–636) — header layout
- `src/components/WorkspaceSwitcher.tsx` — workspace dropdown
- `src/components/SmartPortfolioHeader.tsx` — portfolio dropdown
- `src/components/shared/WorkspaceBanner.tsx` — namespace name display

The header layout places elements in a right-aligned flex container:

```
[Logo/Brand ... left]              [Search] [Help] [AI] [WorkspaceSwitcher | PortfolioSelector] [UserMenu ... right]
```

The **namespace name** (e.g., "City of Riverside") does NOT appear in this header row at all. It appears in the `WorkspaceBanner` component, which renders BELOW the header as a page-level heading (`text-2xl font-semibold`). The workspace and portfolio dropdowns are visually styled as independent pill-shaped buttons (`bg-gray-100 rounded-lg`) with a `gap-4` between them.

There is no visual container, border, or background grouping that connects the namespace identity to the scope selectors. The namespace name and the scope bar live in entirely different visual zones of the page.

### Recommendation

**Option A (minimal):** Add the namespace name as a prefix label inside the scope bar flex container, separated by a subtle divider:

```
[City of Riverside  |  Workspace ▼  Portfolio ▼]
```

This requires adding ~5 lines to `App.tsx` (line 606 area) to render `namespace?.name` with a `border-r border-gray-300` divider before the WorkspaceSwitcher.

**Option B (stronger):** Wrap the entire scope bar in a shared container with a light background and border, making it read as a single "context breadcrumb":

```
┌─────────────────────────────────────────────────┐
│ City of Riverside  ›  All Workspaces  ›  All Portfolios │
└─────────────────────────────────────────────────┘
```

**Effort:** S (Option A) / M (Option B)

---

## Point 2: Assessment Progress vs. Assessment Status + Staleness

### Current State

**Files:**
- `src/components/overview/AssessmentCompletionBar.tsx` — progress visualization
- `src/types/index.ts` (line 160) — `assessed_at: string | null` on DeploymentProfile type
- `src/hooks/useDeploymentProfiles.ts` (line 190) — sets `assessed_at` on save
- `src/types/view-contracts.ts` — VwExplorerDetail does NOT include `assessed_at`

**What exists today:**

The AssessmentCompletionBar displays a **3-segment horizontal bar** showing:
- Green: assessed count
- Amber: in-progress count
- Gray: not started count

Plus two feature cards (TIME Analysis / PAID Analysis progress) and a percentage display.

The label is **"Assessment Progress"** — exactly the framing Dan flagged as "one-time project."

**Schema situation:**
- `deployment_profiles.assessed_at` — **EXISTS** (timestamptz, set when tech assessment is saved)
- `portfolio_assignments` — has `business_assessment_status` (enum) but **NO timestamp** for when business assessment was completed
- No view (`vw_dashboard_summary`, `vw_explorer_detail`, etc.) currently exposes `assessed_at`
- The dashboard summary view (`vw_dashboard_summary_scoped`) has counts but no temporal data

**Audit trail:** The audit trigger on `deployment_profiles` would capture assessment changes, but there is no lightweight mechanism to derive "last assessed" without querying audit logs.

### Recommendation

**Phase 1 — Schema (Stuart, SQL Editor):**
1. Add `business_assessed_at timestamptz` to `portfolio_assignments` (mirrors `deployment_profiles.assessed_at`)
2. Add `assessed_at` to `vw_explorer_detail` view (from deployment_profiles)
3. Add `business_assessed_at` to `vw_explorer_detail` view (from portfolio_assignments)
4. Consider adding aggregate staleness stats to `vw_dashboard_summary_scoped`:
   - `oldest_assessment_at` (MIN of assessed_at across namespace)
   - `stale_assessment_count` (count where assessed_at < NOW() - interval '90 days')

**Phase 2 — Frontend:**
1. Rename "Assessment Progress" to **"Assessment Status"**
2. Below the progress bar, add a staleness row: "X assessments older than 90 days" with a warning color
3. In Explorer, add a "Last Assessed" column (sortable) and a staleness filter (e.g., "Stale > 90 days")

**Effort:** M (schema) + M (frontend) = L total

---

## Point 3: Overview Cards Should Be Clickable (Drill to Explorer)

### Current State

**File:** `src/components/overview/OverviewKpiCards.tsx` (lines 23–120)

All 5 KPI cards are rendered as static `<div>` elements with **zero onClick handlers**. No `useNavigate`, no routing imports, no cursor-pointer styling. The component is purely presentational.

| # | Card | Key | Metric | Clickable? | Natural Drill-Down Target |
|---|------|-----|--------|------------|---------------------------|
| 1 | Applications | `applications` | `total_applications` | No | Explorer (no filter — show all) |
| 2 | Fully Assessed | `assessed` | `assessed_count` | No | Explorer filtered: `tech_assessment_status = 'complete'` |
| 3 | Annual Run Rate | `annual-cost` | `costModelRunRate` | No | IT Spend tab |
| 4 | Crown Jewels | `crown-jewels` | `crown_jewel_count` | No | Explorer filtered: `crownJewel = 'yes'` |
| 5 | At Risk | `at-risk` | `at_risk_count` | No | Explorer filtered: `timeQuadrant` in ['Modernize', 'Eliminate'] |

**Explorer filter infrastructure:**
- `src/hooks/useExplorerData.ts` defines `ExplorerFilters` interface with `crownJewel`, `timeQuadrant`, `paidAction`, `lifecycleStatuses`, `workspace` filters
- Explorer currently reads filters from component-level `useState` only
- **No URL param support** (`useSearchParams` is not used)
- **No navigation state support** (no `useLocation().state` consumption)
- Tab switching via `ScopeContext.setActiveTab()` does not pass filter state

**Infrastructure gap:** To make cards clickable, the app needs a mechanism to pass initial filter state when navigating to Explorer. Two options:
1. **ScopeContext state** — add `pendingExplorerFilters` to ScopeContext, consumed by Explorer on mount
2. **URL search params** — add `?crownJewel=yes` or `?timeQuadrant=Modernize,Eliminate` support to Explorer

### Recommendation

Add a `pendingExplorerFilters` field to ScopeContext. When a card is clicked:
1. Set `pendingExplorerFilters` with the appropriate filter values
2. Call `setActiveTab('explorer')`
3. Explorer reads and clears `pendingExplorerFilters` on mount, applying them as initial filters

Cards should get `cursor-pointer hover:shadow-md hover:border-teal-200 transition-shadow` styling to signal interactivity.

The "Fully Assessed" card needs a new filter option in Explorer: `tech_assessment_status` (not currently a filter). Alternatively, it could navigate to Explorer with no filter (showing the assessment status column).

The "Annual Run Rate" card should navigate to the IT Spend tab rather than Explorer.

**Effort:** M (ScopeContext plumbing + card onClick handlers + Explorer filter consumption)

---

## Point 4: Crown Jewels Card Purpose

### Current State

**File:** `src/components/overview/OverviewKpiCards.tsx` (lines 52–60)

The Crown Jewels card displays:
- Icon: Star (amber)
- Label: "Crown Jewels"
- Value: count from `vw_dashboard_summary.crown_jewel_count`
- Sublabel: "criticality ≥ 50"
- **Not clickable** — no onClick handler

Crown Jewel derivation in the database view:
```sql
count(DISTINCT pa_base.application_id)
  FILTER (WHERE (pa_base.criticality >= 50)) AS crown_jewel_count
```

Explorer already supports `crownJewel: 'yes' | 'no' | 'all'` filter in `useExplorerData.ts`. The infrastructure for drill-down exists — it just isn't wired.

### Recommendation

This is a subset of Point 3. Make the card clickable with target: Explorer filtered by `crownJewel = 'yes'`. The filter infrastructure already exists. Dan is right — a count without a click-through is a dead end.

**Effort:** S (included in Point 3 work)

---

## Point 5: "At Risk" Card Placement and Clickability

### Current State

**Current card order (left to right):**
1. Applications (teal)
2. Fully Assessed (emerald)
3. Annual Run Rate (blue)
4. Crown Jewels (amber)
5. **At Risk (red) — LAST position**

"At Risk" definition: `Modernize count + Eliminate count` from TIME quadrant analysis (portfolio_assignments). These are the two TIME quadrants indicating strategic risk — applications that need modernization or elimination.

The card is not clickable. Explorer supports `timeQuadrant` filter but cannot currently filter for "Modernize OR Eliminate" simultaneously (single-select: `string | null`).

### Recommendation

**Reorder cards to lead with action:**
1. **At Risk** (red) — "what needs attention"
2. Applications (teal) — "total portfolio size"
3. Fully Assessed (emerald) — "assessment coverage"
4. Crown Jewels (amber) — "critical assets"
5. Annual Run Rate (blue) — "financial summary"

This puts the most actionable metric first, as Dan suggested.

**Click target:** Explorer with a compound TIME quadrant filter. The current `timeQuadrant: string | null` filter would need to support multi-select (e.g., `timeQuadrant: Set<string>`) to filter for both "Modernize" AND "Eliminate" simultaneously. Alternatively, add a dedicated `atRisk: boolean` filter that maps to the same SQL condition.

**Effort:** S (reorder is a 1-line array change) + S (click handler, same as Point 3) + S (multi-select or atRisk filter in useExplorerData)

---

## Point 6: Filter Icon Not Intuitive

### Current State

**Files:**
- `src/constants/icons.ts` (line 395) — `filter: Filter` (lucide `Filter` icon = funnel shape)
- `src/components/dashboard/DashboardPage.tsx` (lines 459, 474, 549) — the page Dan was looking at

Dan's red arrow points to the **App Health (Dashboard) page** filter icons. The lucide `Filter` icon (funnel/triangle shape) appears in three places on this page alone:
1. **Workspace filter button** (line 459) — small funnel with teal badge count, top-left of app list
2. **Portfolio filter button** (line 474) — same pattern
3. **"Filters" button** (line 549) — funnel icon + "Filters" text label, top-right action bar

The same funnel icon is used across DashboardPage, RoadmapPage, ExplorerPage, and TechnologyHealthPage via `ACTION_ICONS.filter`.

Dan expected the "three slidey sliders" icon, which is lucide's `SlidersHorizontal`. That icon IS already in the codebase but is used inconsistently — only in filter DRAWER headers (IT Spend, Budget, Tech Health), never as the filter BUTTON icon. So there's a visual disconnect: the button that opens the filter drawer uses a funnel, but the drawer header itself uses sliders.

### Recommendation

**Option A (quick):** Change `ACTION_ICONS.filter` from `Filter` to `SlidersHorizontal` in `src/constants/icons.ts` line 395. Since all filter buttons reference `ACTION_ICONS.filter`, this is a single-line change that updates every filter button app-wide.

**Option B (preserve funnel for compact contexts):** Use `SlidersHorizontal` for standalone filter buttons (the primary "open filter drawer" action) and keep `Filter` for inline/compact filter indicators (e.g., inside dropdowns). This requires more targeted changes.

Dan's instinct aligns with common SaaS conventions (Notion, Linear, Figma all use the sliders icon for filter actions). Recommend Option A.

**Effort:** XS (1-line change in icons.ts)

---

## Point 7: "Showing All Workspaces" Not Communicating Clearly

### Current State

**File:** `src/App.tsx` (line 606)

```tsx
<div className={`flex items-center gap-4 transition-opacity ${
  activeTab === 'overview' ? 'opacity-40 pointer-events-none' : ''
}`}>
```

When `activeTab === 'overview'`:
- The entire scope bar container gets `opacity-40` (40% opacity — very faded)
- `pointer-events-none` makes it non-interactive
- Smooth CSS transition via `transition-opacity`

**There is NO text indicator.** No "Showing all workspaces" banner, no "Namespace-level view" label, no tooltip. The ONLY signal is the 40% opacity dimming of the workspace and portfolio dropdowns. Dan did not register this.

The `WorkspaceBanner` component (`src/components/shared/WorkspaceBanner.tsx`) shows the namespace name as a large heading when in "all-workspaces" mode, but it doesn't explicitly state "this is a namespace-level view" or "scope bar does not apply here."

**Why this fails:** 40% opacity is ambiguous — it could mean "loading," "disabled," or "less important." It does not communicate "this page ignores your workspace selection." Additionally, if a user selected a specific workspace on App Health and then navigates to Overview, the dimmed dropdown still shows their selected workspace name, creating the impression that the scope should be applied.

### Recommendation

**Option A — Explicit banner (recommended):**
Add a small banner below the scope bar or above the KPI cards on Overview:

```
ℹ️ Overview shows all workspaces in [Namespace Name]. Use App Health or Explorer for workspace-specific views.
```

Style: `bg-blue-50 text-blue-700 text-sm px-4 py-2 rounded-lg` — dismissible with localStorage persistence.

**Option B — Replace scope bar on Overview:**
When on Overview tab, replace the dimmed scope bar with a static label:

```
📊 Viewing: All of City of Riverside
```

This eliminates the ambiguity entirely — the scope bar only appears on tabs where it functions.

**Option C — Stronger visual differentiation:**
Keep the dimmed scope bar but add a tooltip on hover ("Overview always shows all workspaces") and change the Overview tab background to a slightly different shade (`bg-gray-50` vs `bg-white`) to signal a different mode.

**Recommended approach:** Option B. Replacing the dimmed controls with an explicit label is cleaner and more honest about Overview's behavior. The current dimming pattern creates false expectations.

**Effort:** S (Option A or B — straightforward conditional rendering in App.tsx)

---

## New Open Items

Items to add to `docs-architecture/planning/open-items-priority-matrix.md`:

| # | Item | Priority | Effort | Notes |
|---|------|----------|--------|-------|
| 1 | Overview KPI cards → clickable with Explorer drill-down | HIGH | M | Requires ScopeContext plumbing for filter state passing. Biggest single UX win from this review. |
| 2 | Rename "Assessment Progress" → "Assessment Status" + add staleness | MED | L | Schema change needed: `business_assessed_at` on portfolio_assignments + view updates |
| 3 | Scope bar visual grouping with namespace name | MED | S | Quick visual fix — add namespace name prefix to scope bar container |
| 4 | Overview scope communication — replace dimmed scope bar with explicit label | MED | S | Option B recommended — static "Viewing: All of [Namespace]" label |
| 5 | Reorder KPI cards: At Risk first | LOW | XS | 1-line array reorder in OverviewKpiCards.tsx |
| 6 | Change filter icon from funnel to SlidersHorizontal | LOW | XS | 1-line change in constants/icons.ts |
| 7 | Explorer: add multi-select TIME quadrant filter for compound "At Risk" drill-down | LOW | S | Needed for At Risk card click target |

**Suggested implementation order:** 6 → 5 → 4 → 3 → 1 → 7 → 2 (quick wins first, staleness last due to schema dependency)
