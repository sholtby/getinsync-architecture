# Handover: ChartsView.tsx Decomposition

**Date:** March 18, 2026
**Priority:** LOW
**File:** `src/components/ChartsView.tsx` (997 lines)
**Branch suggestion:** `refactor/charts-view-decomposition`

---

## Why

ChartsView.tsx is the largest single component in the codebase at 997 lines. It contains three distinct concerns crammed into one file:

1. **BubbleChart** — a self-contained SVG-like scatter plot component (~450 lines, defined as a nested function component inside ChartsView)
2. **Priority Backlog Table** — a sortable, paginated data table (~170 lines of JSX)
3. **Orchestrator** — filter state, sorting logic, data prep, layout (~280 lines)

The nested `BubbleChart` function is the worst offender — it's a full component with its own `useMemo`, hover state, click handlers, and 400+ lines of render logic, but it's defined *inside* the parent component, which means it re-mounts on every parent re-render (no memoization possible).

---

## Proposed Decomposition

### Target structure

```
src/components/charts/
  ChartsView.tsx           (~250 lines) — orchestrator, filter state, layout
  BubbleChart.tsx           (~350 lines) — extracted scatter plot, receives data via props
  PriorityBacklogTable.tsx  (~200 lines) — extracted table with sort + pagination
  chartsConstants.ts        (~40 lines)  — EFFORT_COLORS, EFFORT_BG_COLORS, REMEDIATION_RADII
  chartsHelpers.ts          (~30 lines)  — getTShirtSize, getDpLabel, getEntryKey
```

### File 1: `chartsConstants.ts` (~40 lines)

Extract these constants that are only used by the charts feature:

```typescript
// Currently at lines 30-56 of ChartsView.tsx
export const EFFORT_COLORS: Record<string, string> = { ... };
export const EFFORT_BG_COLORS: Record<string, string> = { ... };
export const REMEDIATION_RADII: Record<string, number> = { ... };
```

### File 2: `chartsHelpers.ts` (~30 lines)

Extract these utility functions:

```typescript
// getTShirtSize (lines 98-105) — needs maxProjectBudget param
// getEntryKey (lines 109-110) — trivial key derivation
// getDpLabel (lines 113-118) — DP name prefix stripping
```

### File 3: `BubbleChart.tsx` (~350 lines)

Extract the nested `BubbleChart` component (lines 281-727) as a standalone component.

**Current problem:** Defined as a closure inside `ChartsView`, accessing parent scope: `assessedApplications`, `hoveredApp`, `setHoveredApp`, `stableIndexMap`, `getTShirtSize`, `getDpLabel`, `getEntryKey`, `onSelectApplication`, `incompleteCount`, `timeCounts`, `paidCounts`, `timeFilter/paidFilter + setters`.

**Proposed props:**

```typescript
interface BubbleChartProps {
  type: 'time' | 'paid';
  assessedApplications: ApplicationWithScores[];
  allApplications: ApplicationWithScores[];  // for stable index map
  onSelectApplication: (app: ApplicationWithScores) => void;
  incompleteCount: number;
  maxProjectBudget: number;
}
```

Move `hoveredApp` state, `stableIndexMap`, filter chips (timeFilter/paidFilter), and counts *inside* BubbleChart since they're chart-local state.

### File 4: `PriorityBacklogTable.tsx` (~200 lines)

Extract lines 794-980 (the Priority Backlog table).

**Proposed props:**

```typescript
interface PriorityBacklogTableProps {
  applications: ApplicationWithScores[];
  stableIndexMap: Map<string, number>;
  showWorkspaceColumn: boolean;
  isAllPortfolios: boolean;
  onSelectApplication: (app: ApplicationWithScores) => void;
  maxProjectBudget: number;
}
```

Sort state and pagination state live inside this component (they're table-local).

### File 5: `ChartsView.tsx` (~250 lines)

What remains in the orchestrator:

- Props destructuring
- `useAppHealthFilters` hook call
- Filter drawer state + reference table fetch
- `assessedApplications` derivation (memoized filter)
- Layout JSX: header, empty state, BubbleChart x2, PriorityBacklogTable, AppHealthFilterDrawer

---

## Secondary Fix: Category Options in Charts View Filter Drawer

Currently `categoryOptions={[]}` is passed because ChartsView lacks namespace_id access. Fix during decomposition:

**Option A (recommended):** Add `useAuth` import to get `currentWorkspace?.namespace_id`, then fetch `application_categories` in the existing `fetchFilterOptions` useEffect — same pattern as DashboardPage.

**Option B:** Pass `categoryOptions` as a prop from the parent (`App.tsx` → `ChartsView`).

Option A is simpler (self-contained), adds ~10 lines.

---

## Risk Assessment

- **Low risk** — this is purely structural. No behavior changes, no new features.
- **Impact scan needed:** `ChartsView` is imported in exactly one place:

```bash
grep -r "ChartsView" src/ --include="*.ts" --include="*.tsx"
# → src/App.tsx (the only consumer)
```

- The `App.tsx` import path will change from `./components/ChartsView` to `./components/charts/ChartsView` — single line change.

---

## Estimated Effort

- ~30 minutes for a Claude Code session
- `npx tsc --noEmit` + `npm run build` to verify
- No database changes, no architecture doc updates needed (purely internal refactor)

---

## Verification Checklist

1. `npx tsc --noEmit` — zero errors
2. `npm run build` — succeeds
3. `wc -l` on all new files — no file over 400 lines
4. Charts View renders identically (both bubble charts + table + filters)
5. Hover tooltips, click-to-select, sort, pagination all work
6. Filter drawer opens and filters cascade correctly
7. ESLint warning count should decrease (nested component warning eliminated)
