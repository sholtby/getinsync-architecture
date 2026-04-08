# IT Spend KPI Click-Through + Budget Alerts Fix

**Status:** Planned
**Date:** 2026-04-08
**Scope:** IT Spend namespace overview page (All Workspaces view)

---

## Context

The IT Spend namespace overview shows two rows of metric cards above a "Budget by Workspace" table. Currently all cards are display-only — no click interaction. Users see summary numbers but must manually scroll to find the relevant detail.

Additionally, the Budget Alerts KPI card is buggy: it only checks the *aggregate* namespace status (`summary.workspace_status === 'over'`), not individual workspace statuses. A workspace can be TIGHT (82% utilized) while the card shows "0 alerts / all workspaces healthy."

### Status Value Mismatch (pre-existing)

The DB view `vw_workspace_budget_summary` returns these `workspace_status` values: `no_budget`, `over_allocated`, `under_10`, `healthy`. The TypeScript union `VwWorkspaceBudgetSummary.workspace_status` declares: `'no_budget' | 'no_costs' | 'healthy' | 'tight' | 'over'`. The table component `BudgetWorkspaceTable` ignores the DB status and re-derives it client-side via `deriveStatus()` producing: `no_budget`, `no_costs`, `over`, `tight`, `healthy`. This spec uses the **client-derived** status values consistently, since that's what the table already displays.

## Goals

1. Make all KPI and allocation cards clickable — scroll to the workspace table with a relevant sort/filter
2. Fix Budget Alerts to count individual workspace issues using client-derived status
3. Match the hover UX pattern established by Overview KPI cards (hover effect + "View" hint)

---

## Design

### KPI Cards (Row 1)

All 4 cards become clickable. On click, smooth-scroll to the "Budget by Workspace" table and apply the specified sort or filter.

| Card | Click Action |
|------|-------------|
| **Total Budget** | Scroll to table, sort by `workspace_budget` descending |
| **Run Rate** | Scroll to table, sort by `run_rate` descending |
| **Remaining** | Scroll to table, sort by `unallocated` ascending (worst-first) |
| **Budget Alerts** | Scroll to table, filtered to problem workspaces only (client-derived status `tight` or `over`) |

### Allocation Cards (Row 2)

The 4 gray allocation cards (inline JSX in `BudgetNamespaceOverview.tsx`, not part of `BudgetKpiCards`) also become clickable. Since the table has no visible columns for `app_budget_allocated` or `service_budget_allocated`, these cards sort by the closest existing column:

| Card | Click Action |
|------|-------------|
| **Allocated to Apps** | Scroll to table, sort by `total_allocated` descending |
| **Allocated to Services** | Scroll to table, sort by `total_allocated` descending |
| **Unallocated Reserve** | Scroll to table, sort by `unallocated` descending |
| **Total Budget** | Scroll to table, sort by `workspace_budget` descending |

### Budget Alerts Fix

**Current (buggy):** `BudgetKpiCards.tsx` line 127 checks `summary.workspace_status === 'over'` — only checks the aggregate status.

**Fixed:** Accept `workspaceBreakdown` as a new prop. For each workspace row, re-derive status client-side (same logic as `BudgetWorkspaceTable.deriveStatus()`) and count those with `over` or `tight`:

```typescript
const alertCount = workspaceBreakdown?.filter(ws => {
  const budget = ws.workspace_budget || 0;
  const runRate = (ws.app_run_rate || 0) + (ws.service_run_rate || 0);
  if (budget === 0) return false;
  const pct = (runRate / budget) * 100;
  return pct > 100 || pct >= 80; // over or tight
}).length || 0;
```

- Card value: count of problem workspaces (e.g., "1")
- Sublabel: "N workspaces need attention" (or "all workspaces healthy" when 0)

### Filter Reset UX

When Budget Alerts filters the table to problem workspaces, show a dismissible info bar above the table:

```
[!] Showing 2 workspaces with budget issues  [Show all workspaces]
```

- Teal/blue background, inline with the "Budget by Workspace" heading area
- "Show all workspaces" link resets the filter
- Clicking Budget Alerts again while already filtered also resets (toggle behavior)

### Hover UX

Match the Overview KPI card pattern:
- `cursor-pointer` on hover
- Subtle lift: `hover:shadow-md transition-shadow` on KPI cards, `hover:border-gray-300 transition-colors` on allocation cards
- "View" text hint appears on hover (using `group` / `group-hover` Tailwind pattern)

---

## Implementation

### Files to Modify

| File | Change |
|------|--------|
| `src/components/budget/BudgetKpiCards.tsx` | Add `onCardClick` callback prop + `workspaceBreakdown` prop; add hover styles and click handlers; fix Budget Alerts count using client-derived status |
| `src/components/budget/BudgetNamespaceOverview.tsx` | Add scroll target `id`; add `tableSort`/`tableFilter` state; wire card click handlers; make allocation cards clickable with hover styles; add filter reset info bar |
| `src/components/budget/BudgetWorkspaceTable.tsx` | Accept `externalSort` and `filterProblems` props; apply filter before sort; extract `deriveStatus()` to module scope (currently inside render function) so it can be reused |

### Prop Threading

`BudgetNamespaceOverview` owns the state and passes callbacks down:

```typescript
// BudgetNamespaceOverview state
const [tableSort, setTableSort] = useState<{ field: SortField; dir: SortDir } | null>(null);
const [filterProblems, setFilterProblems] = useState(false);

// Passed to BudgetKpiCards
<BudgetKpiCards
  summary={summary}
  loading={loading}
  workspaceCount={workspaceBreakdown.length}
  workspaceBreakdown={workspaceBreakdown}  // NEW
  onCardClick={(action) => { ... }}         // NEW
/>

// Passed to BudgetWorkspaceTable
<BudgetWorkspaceTable
  workspaces={workspaceBreakdown}
  externalSort={tableSort}      // NEW — overrides current sort
  filterProblems={filterProblems}  // NEW — when true, show only tight/over
/>
```

### Scroll Mechanism

1. Add `id="budget-workspace-table"` to the `<div>` wrapping the "Budget by Workspace" heading
2. On card click, set sort/filter state then scroll:
   ```typescript
   requestAnimationFrame(() => {
     document.getElementById('budget-workspace-table')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
   });
   ```
   `requestAnimationFrame` ensures the DOM has updated with new sort/filter before scrolling.
3. User can still re-sort by clicking column headers — column click clears `externalSort`

### Table Filter Behavior

In `BudgetWorkspaceTable`, when `filterProblems` is true:
```typescript
const filtered = filterProblems
  ? workspaces.filter(ws => {
      const budget = ws.workspace_budget || 0;
      const runRate = (ws.app_run_rate || 0) + (ws.service_run_rate || 0);
      return budget > 0 && ((runRate / budget) * 100 >= 80);
    })
  : workspaces;
```
Then sort and paginate `filtered` instead of `workspaces`.

---

## Verification

1. **Namespace view (All Workspaces):** Click each of the 8 cards — table scrolls into view with correct sort/filter
2. **Budget Alerts count:** With IT workspace at 82% (TIGHT), card should show "1" instead of "0"
3. **Budget Alerts click:** Clicking the card filters table to show only TIGHT/OVER workspaces; info bar appears above table
4. **Filter reset:** Clicking "Show all workspaces" in the info bar restores full table; clicking Budget Alerts again also toggles filter off
5. **Hover UX:** All 8 cards show pointer cursor and visual feedback on hover, "View" hint appears
6. **Sort override:** After clicking a KPI card to sort, clicking a column header in the table overrides with user's manual sort
7. **Empty state:** If no workspaces have budget issues, Budget Alerts shows "0" and clicking it shows the info bar with "0 workspaces with budget issues" then the full table (no filtering)
8. **Workspace detail view:** KPI cards on the single-workspace view remain display-only — no scroll target, no click handlers
9. `npx tsc --noEmit` — zero errors
10. `npm run build` — passes

---

## TypeScript Contract Note

The `VwWorkspaceBudgetSummary.workspace_status` type union (`'no_budget' | 'no_costs' | 'healthy' | 'tight' | 'over'`) does not match the DB view values (`no_budget`, `over_allocated`, `under_10`, `healthy`). This pre-existing mismatch should be fixed as part of this work:

```typescript
// Current (wrong)
workspace_status: 'no_budget' | 'no_costs' | 'healthy' | 'tight' | 'over';

// Fixed (matches DB)
workspace_status: 'no_budget' | 'over_allocated' | 'under_10' | 'healthy';
```

All consumers that reference `workspace_status` must be updated. The table's `deriveStatus()` function already ignores the DB value and re-derives, so the fix is safe. The `BudgetKpiCards` `STATUS_COLORS` map also needs `over_allocated` and `under_10` entries.

---

## Out of Scope

- Making workspace-level (single-workspace) KPI cards clickable
- Adding click-through on Projected IT Spend or Run Rate by Quadrant sections
- Cross-tab navigation from IT Spend KPI cards (decided against — scroll-to-section keeps context)
- Adding `app_budget_allocated` / `service_budget_allocated` columns to the workspace table
