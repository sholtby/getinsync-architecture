# Session Prompt 02 — YoY Budget Trend Chart

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 4-6 hours

---

## Task: Build a Year-over-Year budget trend chart consuming `vw_workspace_budget_history`

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 3) claims "Year-over-Year Budget Trends — See how application spending changes over time." The database view `vw_workspace_budget_history` exists with `budget_yoy_change`, `prior_year_budget`, and `prior_year_actual` columns — but no frontend component consumes it. We need a visual trend chart on the IT Spend page.

This is a **UI-only change** — no schema modifications needed. The data layer is complete.

### Hard rules

1. **Branch:** `feat/budget-trend-chart`. Create from `dev`.
2. **Use D3 for charting** — it's already installed (`d3: ^7.9.0`). Do NOT install Recharts or another library.
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Follow screen-building-guidelines.md** — consistent card styling, Tailwind classes, lucide-react icons.
5. **No new database views or tables** — consume `vw_workspace_budget_history` directly.
6. **Reuse existing patterns** — see `BubbleChart.tsx` for D3 conventions, `DonutChart.tsx` for SVG patterns.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "vw_workspace_budget_history" (~line 11118)
   - Columns: id, workspace_id, workspace_name, namespace_id, fiscal_year,
     budget_amount, actual_run_rate, budget_notes, is_current,
     variance, variance_percent, prior_year_budget, prior_year_actual, budget_yoy_change
   - Note: LAG window function partitions by workspace_id, ordered by fiscal_year

2. src/components/budget/BudgetNamespaceOverview.tsx (full file)
   - Layout structure: KPI cards → Allocation cards → ProjectedSpendCard → BudgetWorkspaceTable
   - The trend chart should go between Allocation cards and ProjectedSpendCard

3. src/components/budget/BudgetPage.tsx
   - Conditional render: all-workspaces → BudgetNamespaceOverview, else → BudgetWorkspaceDetail
   - Note: trend chart should appear at BOTH levels (namespace and workspace)

4. src/components/budget/useBudgetData.ts
   - Current data fetching pattern — queries vw_workspace_budget_summary
   - Note: does NOT query vw_workspace_budget_history yet

5. src/components/charts/BubbleChart.tsx
   - D3 pattern: scaleLinear, SVG rendering, hover tooltips
   - Reuse the same approach for axes and scales

6. src/components/ui/DonutChart.tsx
   - Pure SVG component pattern — clean, no library deps beyond D3 scales

7. docs-architecture/operations/screen-building-guidelines.md
   - Card styling standards, spacing, typography
```

### Step 2 — Verify view data via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm view exists and check columns
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_workspace_budget_history' ORDER BY ordinal_position"

# Sample data to understand what comes back
psql "$DATABASE_READONLY_URL" -c "SELECT workspace_name, fiscal_year, budget_amount, actual_run_rate, variance, budget_yoy_change FROM vw_workspace_budget_history ORDER BY workspace_name, fiscal_year DESC LIMIT 20"
```

### Step 3 — Create data hook: `src/components/budget/useBudgetHistory.ts`

```typescript
interface BudgetHistoryRow {
  id: string;
  workspace_id: string;
  workspace_name: string;
  namespace_id: string;
  fiscal_year: number;
  budget_amount: number | null;
  actual_run_rate: number | null;
  variance: number | null;
  variance_percent: number | null;
  prior_year_budget: number | null;
  prior_year_actual: number | null;
  budget_yoy_change: number | null;
  is_current: boolean;
}
```

**Fetch pattern:**
- At namespace level (all-workspaces): aggregate by fiscal_year across all workspaces — `SUM(budget_amount)`, `SUM(actual_run_rate)` grouped by year
- At workspace level: filter by `workspace_id`, return all fiscal years sorted ascending
- Return `{ data: BudgetHistoryRow[], loading: boolean, error: string | null }`

**Aggregation for namespace level:** Since the view returns per-workspace rows, the hook should:
1. Fetch all rows for the namespace: `.eq('namespace_id', namespaceId)`
2. Group by `fiscal_year` in JavaScript, summing `budget_amount` and `actual_run_rate`
3. Compute `variance` and `budget_yoy_change` from the aggregated values
4. Sort by `fiscal_year` ascending for chart X-axis

### Step 4 — Create chart component: `src/components/budget/BudgetTrendChart.tsx`

**Visual design:** A grouped bar chart with two bars per fiscal year:
- **Blue bar:** Budget amount
- **Teal bar:** Actual run rate (or actual spend)
- **X-axis:** Fiscal years (e.g., 2024, 2025, 2026)
- **Y-axis:** Dollar amount with K/M abbreviations ($150K, $1.2M)
- **Hover tooltip:** Shows exact budget, actual, variance, and YoY change for the hovered year
- **Variance indicator:** Small arrow or badge between bars showing over/under (green for under budget, red for over)

**D3 usage:**
```typescript
import * as d3 from 'd3';

// Scales
const xScale = d3.scaleBand()
  .domain(data.map(d => d.fiscal_year.toString()))
  .range([margin.left, width - margin.right])
  .padding(0.3);

const yScale = d3.scaleLinear()
  .domain([0, d3.max(data, d => Math.max(d.budget_amount || 0, d.actual_run_rate || 0)) * 1.1])
  .range([height - margin.bottom, margin.top]);
```

**Card container:** Wrap in a card matching the existing budget page styling:
```
bg-white rounded-xl border border-gray-200 p-6
```

**Header:** "Budget vs. Actual Trend" with a `TrendingUp` icon from lucide-react.

**Empty state:** If fewer than 2 fiscal years of data exist, show: "Add budget data for multiple fiscal years to see trends."

**Responsive:** Chart resizes with container width. Use a `ResizeObserver` or `useRef` for width measurement.

### Step 5 — Integrate into BudgetNamespaceOverview.tsx

Add the `BudgetTrendChart` component between the allocation cards and `ProjectedSpendCard`:

```tsx
{/* Existing: Allocation cards */}
<div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
  {/* ... allocation cards ... */}
</div>

{/* NEW: Budget trend chart */}
<BudgetTrendChart
  data={budgetHistory}
  loading={historyLoading}
/>

{/* Existing: ProjectedSpendCard */}
<ProjectedSpendCard ... />
```

Wire up the `useBudgetHistory` hook in the overview component (or in `BudgetPage.tsx` and pass data down).

### Step 6 — Also integrate into BudgetWorkspaceDetail

Read `src/components/budget/BudgetWorkspaceDetail.tsx`. Add the same trend chart for single-workspace view, filtered by the selected workspace.

### Step 7 — Impact analysis and type check

```bash
# Verify no naming conflicts
grep -r "BudgetTrendChart\|useBudgetHistory\|budget_history" src/ --include="*.ts" --include="*.tsx"

# Type check
npx tsc --noEmit
```

### Step 8 — Update architecture doc

Update `docs-architecture/features/cost-budget/budget-management.md`:
- Add section on YoY trend visualization
- Document the view consumed (`vw_workspace_budget_history`)
- Note the aggregation pattern for namespace-level view

### Step 9 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/budget/BudgetTrendChart.tsx src/components/budget/useBudgetHistory.ts src/components/budget/BudgetNamespaceOverview.tsx src/components/budget/BudgetWorkspaceDetail.tsx
git commit -m "feat: YoY budget trend chart on IT Spend page

Grouped bar chart showing budget vs actual spend across fiscal years.
Consumes vw_workspace_budget_history view (already exists).
Displays at both namespace and workspace levels.
Closes Garland audit yellow flag (Slide 3, 'Year-over-Year Budget Trends')."
git push -u origin feat/budget-trend-chart
```

Also commit architecture doc:
```bash
cd ~/getinsync-architecture
git add features/cost-budget/budget-management.md
git commit -m "docs: add YoY budget trend chart to budget-management doc"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] `useBudgetHistory.ts` hook fetches from `vw_workspace_budget_history`
- [ ] Hook aggregates by fiscal_year for namespace-level view
- [ ] `BudgetTrendChart.tsx` renders grouped bar chart with D3
- [ ] Chart shows budget (blue) and actual (teal) bars per fiscal year
- [ ] Hover tooltips show exact values + variance + YoY change
- [ ] Chart integrated into `BudgetNamespaceOverview.tsx`
- [ ] Chart integrated into `BudgetWorkspaceDetail.tsx`
- [ ] Empty state when < 2 fiscal years of data
- [ ] Responsive width
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] No new npm dependencies added

### What NOT to do

- Do NOT install Recharts or any new charting library — use D3 (already installed)
- Do NOT create new database views or modify the schema
- Do NOT add pagination to the chart — budget history is typically 3-5 years, never enough to paginate
- Do NOT modify KPI cards or allocation cards — the chart is additive
- Do NOT add drill-down from the chart — keep it simple for MVP
