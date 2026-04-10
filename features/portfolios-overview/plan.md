# Portfolios Overview Page — Implementation Plan

> Recreate the OG "Portfolios" tree-table view in NextGen.

---

## Context

The OG GetInSync app has a "Portfolios" page showing a hierarchical tree of portfolios with aggregated cost and application metrics per row. Users want a similar view in NextGen.

NextGen already has the data infrastructure: `vw_portfolio_costs_rollup` provides recursive cost aggregation through the portfolio tree, and `portfolio_contacts` tracks portfolio leaders. This plan adds a new top-level tab to surface that data in a tree table.

---

## Column Mapping (OG -> NextGen)

| OG Column | NextGen Source | Include? |
|-----------|---------------|----------|
| Name (tree) | `portfolio_name` + hierarchy | Yes |
| Portfolio Manager | `portfolio_contacts` (leader) | Yes |
| Total Applications | `rollup_app_count` | Yes |
| Applications (In Portfolio) | `direct_app_count` | Yes |
| Estimated Annual | `rollup_total_cost` | Yes |
| Estimated Licenses | `rollup_software_cost` | Skip (always 0 — software products have no costs yet) |
| Estimated Support, Op & Dev | `rollup_service_cost` | Yes |
| Estimated Compute & Platform | `rollup_bundle_cost` | Yes |
| License Count | No data source in schema | Skip |
| Processes Supported | No data source in schema | Skip |
| Apps Targeted to be Retired | Count apps with `operational_status='retired'` per portfolio | Yes |

---

## Implementation Steps

### Step 1: Add TypeScript types

**File:** `src/types/view-contracts.ts`

Add `VwPortfolioCostsRollup` interface matching the DB view columns:

```typescript
export interface VwPortfolioCostsRollup {
  portfolio_id: string;
  portfolio_name: string;
  parent_portfolio_id: string | null;
  workspace_id: string;
  workspace_name: string;
  namespace_id: string;
  depth: number;
  is_leaf: boolean;
  is_root: boolean;
  direct_dp_count: number;
  direct_app_count: number;
  direct_software_cost: number;
  direct_service_cost: number;
  direct_bundle_cost: number;
  direct_total_cost: number;
  rollup_dp_count: number;
  rollup_app_count: number;
  rollup_software_cost: number;
  rollup_service_cost: number;
  rollup_bundle_cost: number;
  rollup_total_cost: number;
}
```

### Step 2: Create tree helper utilities

**New file:** `src/components/portfolios-overview/portfolioTreeHelpers.ts`

Pure functions:
- `buildTree(flatRows)` — converts flat query results into nested tree by `parent_portfolio_id`
- `flattenVisibleTree(tree, expandedIds, sortFn)` — depth-first flattening respecting expand/collapse state, applying sort within sibling groups
- `rollupRetirementCounts(leafCounts, tree)` — aggregates retirement counts up from leaves to parents

### Step 3: Create data fetching hook

**New file:** `src/components/portfolios-overview/usePortfolioCostsRollup.ts`

Three parallel Supabase queries:

1. **Cost rollup:** `supabase.from('vw_portfolio_costs_rollup').select('*')` scoped by workspace/namespace
2. **Portfolio managers:** `supabase.from('portfolio_contacts').select('portfolio_id, contacts(display_name)').eq('role_type', 'leader').eq('is_primary', true)`
3. **Retirement counts:** `supabase.from('portfolio_assignments').select('portfolio_id, applications!inner(operational_status)')` filtered to `operational_status = 'retired'`, grouped client-side

Merges results into enriched tree nodes with manager name and retirement count.

### Step 4: Create row component

**New file:** `src/components/portfolios-overview/PortfolioTreeRow.tsx`

Single `<tr>` with:
- **Name cell:** `paddingLeft: depth * 24px`, chevron icon for expand/collapse on parent nodes
- **Portfolio Manager:** text, left-aligned
- **Numeric columns:** right-aligned, `formatCurrency()` for costs, comma-formatted integers for counts
- **Parent rows** show rollup values (bold); **leaf rows** show direct values

### Step 5: Create table component

**New file:** `src/components/portfolios-overview/PortfolioTreeTable.tsx`

Renders `<table>` with:
- Sortable column headers (ArrowUpDown/ArrowUp/ArrowDown pattern from `DashboardAppTable.tsx`)
- Maps over flattened visible rows, renders `PortfolioTreeRow` for each

Columns: Name | Portfolio Manager | Total Apps | Direct Apps | Annual Cost | IT Services | Compute & Platform | Apps Retired

### Step 6: Create page component

**New file:** `src/components/portfolios-overview/PortfoliosOverviewPage.tsx`

Page layout following `screen-building-guidelines.md`:
- **Toolbar row:** text filter input, Expand All / Collapse All buttons, Export CSV button
- **PortfolioTreeTable**
- **TablePagination** — paginate at root-portfolio level (each page shows N roots with all expanded children)

State managed: `expandedIds` (Set), filter text, sort field/direction, pagination.

### Step 7: Wire up navigation

| File | Change |
|------|--------|
| `src/contexts/ScopeContext.tsx` line 10 | Add `'portfolios-overview'` to `ActiveTab` union |
| `src/components/navigation/tabConfig.ts` | Add `{ id: 'portfolios-overview', label: 'Portfolios' }` after IT Spend, before Explorer |
| `src/App.tsx` | Add rendering block for `activeTab === 'portfolios-overview'` → `<PortfoliosOverviewPage />` |

---

## File Summary

| File | Action |
|------|--------|
| `src/types/view-contracts.ts` | Add `VwPortfolioCostsRollup` type |
| `src/components/portfolios-overview/portfolioTreeHelpers.ts` | Create — tree build/flatten utilities |
| `src/components/portfolios-overview/usePortfolioCostsRollup.ts` | Create — data fetching hook |
| `src/components/portfolios-overview/PortfolioTreeRow.tsx` | Create — row component |
| `src/components/portfolios-overview/PortfolioTreeTable.tsx` | Create — table component |
| `src/components/portfolios-overview/PortfoliosOverviewPage.tsx` | Create — page container |
| `src/contexts/ScopeContext.tsx` | Modify — add to ActiveTab type |
| `src/components/navigation/tabConfig.ts` | Modify — add tab entry |
| `src/App.tsx` | Modify — add tab rendering block |

## Existing Utilities to Reuse

- `src/components/ui/TablePagination.tsx` — shared pagination
- `src/utils/csv-export.ts` — `buildCsvString()`, `downloadCsv()`
- `src/utils/formatting.ts` — `formatCurrency()`
- Expand/Collapse pattern from `src/pages/settings/PortfoliosSettings.tsx`
- Sort icon pattern from `src/components/dashboard/DashboardAppTable.tsx`

---

## Data Sources

### Primary: `vw_portfolio_costs_rollup` (existing view)

Recursive CTE that rolls up costs through the portfolio tree (max depth 3). Returns both `direct_*` (leaf-level) and `rollup_*` (including descendants) metrics.

### Supplementary: `portfolio_contacts` (existing table)

Join with `contacts` table to get portfolio leader name. Filter: `role_type = 'leader'`, `is_primary = true`.

### Supplementary: Retirement count (ad-hoc query)

Query `portfolio_assignments` joined to `applications` where `operational_status = 'retired'`, group by `portfolio_id`. Roll up client-side using tree structure.

---

## Design Decisions

1. **Tree pagination:** Paginate at root-portfolio level (N roots per page, all expanded children shown inline). Avoids splitting parent/children across pages.
2. **Client-side tree building:** `vw_portfolio_costs_rollup` returns flat rows with depth. Tree assembled in JS. Max depth 3 + typical portfolio counts (tens to low hundreds) make this efficient.
3. **Client-side retirement rollup:** Leaf counts aggregated up the tree in JS rather than a new DB view. Can be promoted to a view later if needed.
4. **Workspace scoping:** Respects current workspace selection from WorkspaceSwitcher. All-workspaces mode shows portfolios across all workspaces.
5. **Skipped columns:** License Count and Processes Supported have no data source. Software Cost is always 0. These can be added when the data model supports them.

---

## Verification Checklist

1. `npx tsc --noEmit` — zero errors
2. `npm run dev` — navigate to Portfolios tab, verify tree renders
3. Expand/collapse all and individual node toggle
4. Sort on each column
5. Text filter with parent auto-expansion for matches
6. CSV export downloads correctly
7. Pagination at root level
8. Workspace scoping (single workspace vs all-workspaces)
