# Technology Health Component Refactoring Plan

> **Status:** PLANNED  
> **Created:** 2026-04-13  
> **Scope:** Decompose two oversized components into maintainable feature-folder structure  
> **Files:** `TechnologyHealthSummary.tsx` (1563 lines), `TechnologyHealthByApplication.tsx` (1011 lines)  
> **Risk:** LOW — pure refactor, no behavior changes, no schema changes  
> **Estimated sessions:** 2 (can run in parallel on separate worktrees)

---

## Problem Statement

Two components in `src/components/technology-health/` exceed the 800-line threshold:

| File | Lines | useState | useMemo | Key Issues |
|------|-------|----------|---------|------------|
| `TechnologyHealthSummary.tsx` | 1563 | 23 | 30+ | Monolithic: data fetch + filter state + cascading option derivation + KPI calc + 3 chart sections + duplicated at-risk tables |
| `TechnologyHealthByApplication.tsx` | 1011 | 15 | 9 | Mixed concerns: data fetch + app grouping + filter/sort pipeline + CSV export + inline sub-components |

Both are pre-existing — not caused by recent feature work. The parent container is `TechnologyHealthPage.tsx` which renders them in tabs.

---

## Architecture Constraints

- **No behavior changes.** Every pixel, every filter, every export must work identically after refactoring.
- **No schema changes.** Views and types stay the same.
- **Feature-folder pattern.** Keep everything in `src/components/technology-health/`. No new top-level directories.
- **Existing shared components stay shared:** `LifecycleBadge`, `StandardsBadge`, `TablePagination`, filter drawers.
- **View contract types** in `src/types/view-contracts.ts` are the source of truth — do not duplicate.
- **Impact analysis required** before every extraction: grep all consumers of moved types/functions.

---

## Session 1: TechnologyHealthByApplication.tsx (1011 -> ~350 lines)

### Extraction Plan

#### 1.1 — Extract data-fetching hook: `useApplicationInfrastructureData`
**New file:** `src/components/technology-health/hooks/useApplicationInfrastructureData.ts`

**Move from lines 129-199 + state declarations (lines 96-100, 125):**
- All Supabase queries (infrastructure report, cost bundles, portfolio assignments, DP locations, standards)
- `loading`, `rawData`, `costBundleDpIds`, `portfolioAssignments`, `dpLocations` state
- `useTagStandardsStatus` hook call
- Returns: `{ loading, data, costBundleDpIds, portfolioAssignments, dpLocations, standardsStatus }`

**Estimated reduction:** ~80 lines from main component

#### 1.2 — Extract grouping/aggregation hook: `useApplicationGroups`
**New file:** `src/components/technology-health/hooks/useApplicationGroups.ts`

**Move from lines 203-378:**
- `pickWorstLayer` utility function (lines 274-299)
- `data` filtered memo (lines 203-206)
- `portfolioLookup` memo (lines 210-252)
- `dpLocationMap` memo (lines 257-269)
- `appGroups` memo (lines 301-378)
- `workspaceOptions` memo (lines 382-389)
- `dataCenterOptions` memo (lines 393-402)
- Types: `TechLayerSummary`, `AppGroup` — move to a local types file or keep in hook
- Returns: `{ appGroups, workspaceOptions, dataCenterOptions, dpLocationMap, portfolioLookup }`

**Estimated reduction:** ~180 lines from main component

#### 1.3 — Extract filter/sort/pagination hook: `useFilteredSortedApplications`
**New file:** `src/components/technology-health/hooks/useFilteredSortedApplications.ts`

**Move from lines 104-120 (filter state), 406-507 (filter/sort/paginate memos):**
- All filter useState declarations
- `filteredGroups` memo (lines 406-447)
- `sortedGroups` memo (lines 451-494)
- `paginatedGroups` memo (lines 498-502)
- `handleSort` (lines 511-518)
- `handleClearAllFilters` (lines 588-593)
- `activeFilterCount` memo (lines 597-604)
- Page-reset effect (lines 505-507)
- Returns: `{ filters, setters, sortedGroups, paginatedGroups, handleSort, handleClearAllFilters, activeFilterCount, pagination }`

**Estimated reduction:** ~120 lines from main component

#### 1.4 — Extract CSV export utility
**New file:** `src/components/technology-health/utils/exportApplicationsCsv.ts`

**Move from lines 529-584:**
- `handleExportCsv` function — make it a pure function accepting `(groups, dpLocationMap, namespace)`
- Remove closure over component state

**Estimated reduction:** ~60 lines from main component

#### 1.5 — Extract AppRow to its own file
**New file:** `src/components/technology-health/AppRow.tsx`

**Move from lines 856-1010:**
- `AppRow` component
- `AppRowProps` interface
- Also move inline helpers it depends on: `formatTech` (lines 633-636), `TechCell` (lines 640-653)

**Estimated reduction:** ~170 lines from main component

#### 1.6 — Extract types to shared file
**New file:** `src/components/technology-health/types/by-application.ts`

**Move:**
- `TechnologyHealthByApplicationProps` (lines 16-26)
- `SortField` (lines 28-34)
- `SortDir` (line 36)
- `TechLayerSummary` (lines 49-53)
- `AppGroup` (lines 56-73)
- `AppRowProps` (lines 856-865)
- `LIFECYCLE_SEVERITY` constant (lines 39-46)

#### 1.7 — Verify and clean up main component
After all extractions, `TechnologyHealthByApplication.tsx` should contain only:
- Import statements
- The main component with JSX rendering (table headers, filter drawer trigger, pagination)
- Hook calls to the extracted hooks
- Event handlers that bridge hooks to UI

**Target: ~300-350 lines**

### Verification Checklist (Session 1)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `npm run build` succeeds
- [ ] All filters work identically (workspace, datacenter, lifecycle, crown jewel, search)
- [ ] Sort on all columns works
- [ ] Pagination works (page size selector, page navigation, count display)
- [ ] CSV export produces identical output
- [ ] Multi-DP expansion (chevron) works
- [ ] App name click navigates correctly
- [ ] Crown jewel star renders correctly
- [ ] Publisher/consumer badges render correctly
- [ ] Standards badge renders correctly
- [ ] No console errors or warnings introduced

---

## Session 2: TechnologyHealthSummary.tsx (1563 -> ~400 lines)

### Extraction Plan

#### 2.1 — Extract data-fetching hook: `useTechnologyHealthData`
**New file:** `src/components/technology-health/hooks/useTechnologyHealthData.ts`

**Move from lines 38-49 (state), 70-147 (fetch effect):**
- All Supabase queries (health summary, infra report, tags, cost bundles, portfolio, locations, standards)
- All raw data state declarations
- Returns: `{ loading, healthSummary, infraReport, allTags, costBundleDpIds, portfolioAssignments, dpLocations, standardsPendingCount }`

**Estimated reduction:** ~90 lines

#### 2.2 — Extract filter state management hook: `useSummaryFilters`
**New file:** `src/components/technology-health/hooks/useSummaryFilters.ts`

**Move from lines 52-64 (filter state), 184-220 (active filter calc), 569-616 (toggle/clear helpers):**
- All 10 filter selection useState calls
- `collapsedSections` state
- `isAnyFilterActive` memo
- `activeFilterCount` memo
- `makeToggle`, `makeToggleAll`, `clearAllFilters`, `makeClearSection` helpers
- `toggleSection`, `toggleAllSections` helpers
- Returns: `{ selections, togglers, clearAllFilters, activeFilterCount, isAnyFilterActive, sectionState }`

**Estimated reduction:** ~100 lines

#### 2.3 — Extract cascading filter options hook: `useSummaryFilterOptions`
**New file:** `src/components/technology-health/hooks/useSummaryFilterOptions.ts`

**Move from lines 151-451:**
- `branchOptions` memo
- `techNameToProductFamily` memo
- All 9 pairs of `filteredFor*Options` + derived `*Options` memos (OS/DB/Web x class/version/lifecycle)
- `filterInfraRow` function (lines 243-292) with `FilterSkips` interface
- `filteredInfraReport` memo
- Returns: `{ branchOptions, osClassOptions, osVersionOptions, ..., filteredInfraReport }`

This is the densest section — 30 memos with cascading dependencies. Keep them together in one hook to preserve the dependency chain.

**Estimated reduction:** ~300 lines

#### 2.4 — Extract KPI metrics hook: `useTechHealthMetrics`
**New file:** `src/components/technology-health/hooks/useTechHealthMetrics.ts`

**Move from lines 689-787:**
- `LIFECYCLE_SEVERITY` constant
- `appWorstStatus` memo
- `taggedAppIds` memo
- `appCountByStatus` memo
- `incompleteOnlyAppCount` memo
- `needsProfilingAppIds` memo
- Returns: `{ appWorstStatus, appCountByStatus, incompleteOnlyAppCount, needsProfilingCount, taggedAppCount }`

**Estimated reduction:** ~100 lines

#### 2.5 — Extract approaching-EOS logic + panel component
**New file:** `src/components/technology-health/hooks/useApproachingEos.ts`
**New file:** `src/components/technology-health/ApproachingEosPanel.tsx`

**Hook — move from lines 516-558, 560-565, 851-900:**
- `filteredTags` memo
- `filteredApproachingEosTags` memo
- `approachingEosSorted` memo
- `approachingByCategory` memo
- `approachingUniqueAppsAll` memo
- `approachingUniqueAppsByCategory` memo
- `expandedEos` state + `toggleEos` handler

**Component — extract duplicated at-risk table rendering (appears twice in JSX):**
- Lines ~1247-1294 and ~1440-1486 are duplicated at-risk table markup
- Extract once as `<ApproachingEosPanel category={cat} tags={tags} ... />`

**Estimated reduction:** ~200 lines (100 from hook, 100 from de-duplicating JSX)

#### 2.6 — Extract category donut cards component
**New file:** `src/components/technology-health/CategoryDonutCard.tsx`

**Move from lines 793-845 (categoryCards memo) + lines 1300-1495 (JSX):**
- `categoryCards` memo -> stays in hook or moves to utility
- SVG donut rendering + legend + at-risk table per category
- `CATEGORY_COLORS` constant
- Props: `{ category, totalCount, statusBreakdown, atRiskTags, ... }`

**Estimated reduction:** ~250 lines

#### 2.7 — Extract lifecycle composition section
**New file:** `src/components/technology-health/LifecycleCompositionSection.tsx`

**Move from lines 914-969 (statusCategoryBreakdown memo) + lines 1160-1298 (JSX):**
- Stacked bar chart rendering
- Status x category breakdown computation
- At-risk summary table

**Estimated reduction:** ~200 lines

#### 2.8 — Extract CSV export utility
**New file:** `src/components/technology-health/utils/exportSummaryCsv.ts`

**Move from lines 462-501:**
- `handlePageExportCsv` callback -> pure function

**Estimated reduction:** ~45 lines

#### 2.9 — Extract types
**New file:** `src/components/technology-health/types/summary.ts`

**Move:**
- `TechnologyHealthSummaryProps` (lines 15-23)
- `FilterSkips` (lines 237-241)
- `LIFECYCLE_SEVERITY` (lines 689-696) — shared with ByApplication, so place in `types/shared.ts`
- `CATEGORY_COLORS` (lines 904-908)

#### 2.10 — Verify and clean up main component
After all extractions, `TechnologyHealthSummary.tsx` should contain only:
- Import statements
- The main component shell: hook calls, KPI card JSX layout, section composition
- Bridging logic between hooks and child components

**Target: ~350-400 lines**

### Verification Checklist (Session 2)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `npm run build` succeeds
- [ ] KPI cards display correct counts (applications profiled, needs profiling, approaching EOL, standards pending)
- [ ] All 3 category donut charts render correctly (OS, DB, Web)
- [ ] Stacked bar lifecycle composition renders correctly
- [ ] At-risk tables render correctly in both lifecycle section AND category cards
- [ ] All filters work: branch, OS class/version/lifecycle, DB class/version/lifecycle, Web class/version/lifecycle
- [ ] Cascading filter options update correctly (selecting OS class narrows OS version options)
- [ ] Filter count badge updates correctly
- [ ] Clear all filters works
- [ ] CSV export produces identical output
- [ ] Embedded application table renders correctly with crown-jewel and needs-profiling toggles
- [ ] Collapse/expand sections work
- [ ] Approaching EOS expand/collapse works
- [ ] No console errors or warnings introduced

---

## New File Structure (After Both Sessions)

```
src/components/technology-health/
  TechnologyHealthPage.tsx           (existing, unchanged)
  TechnologyHealthSummary.tsx        (refactored: ~400 lines)
  TechnologyHealthByApplication.tsx  (refactored: ~350 lines)
  TechnologyHealthByTechnology.tsx   (existing, unchanged)
  TechnologyHealthByServer.tsx       (existing, unchanged)
  StandardsIntelligencePage.tsx      (existing, unchanged)
  
  # New extracted components
  AppRow.tsx                         (~160 lines)
  ApproachingEosPanel.tsx            (~80 lines)
  CategoryDonutCard.tsx              (~150 lines)
  LifecycleCompositionSection.tsx    (~150 lines)
  
  # New hooks
  hooks/
    useApplicationInfrastructureData.ts   (~90 lines)
    useApplicationGroups.ts               (~190 lines)
    useFilteredSortedApplications.ts      (~130 lines)
    useTechnologyHealthData.ts            (~100 lines)
    useSummaryFilters.ts                  (~110 lines)
    useSummaryFilterOptions.ts            (~310 lines)
    useTechHealthMetrics.ts               (~110 lines)
    useApproachingEos.ts                  (~100 lines)
  
  # New utilities
  utils/
    exportApplicationsCsv.ts              (~60 lines)
    exportSummaryCsv.ts                   (~50 lines)
  
  # New types
  types/
    shared.ts                             (~30 lines — LIFECYCLE_SEVERITY, shared constants)
    by-application.ts                     (~50 lines)
    summary.ts                            (~30 lines)
  
  # Existing files (unchanged)
  LifecycleBadge.tsx
  StandardsBadge.tsx
  SummaryApplicationTable.tsx
  TechHealthByAppFilterDrawer.tsx
  TechnologyHealthFilterSidebar.tsx
  ... (other existing files)
```

---

## Parallel Execution Notes

Sessions 1 and 2 can run in **parallel worktrees** because:
- They modify different files (no overlap)
- Shared types (`LIFECYCLE_SEVERITY`) should be extracted by whichever session runs first; the second session adapts
- New `hooks/`, `utils/`, `types/` directories are additive (no conflict)

**Coordination rule:** If both sessions run simultaneously, Session 1 should create the `hooks/`, `utils/`, `types/` directories. Session 2 checks for their existence before creating.

**Merge order:** Either can merge first. The second merge will have a clean merge since files don't overlap.

---

## Session Prompts

### Prompt for Session 1

```
You are refactoring `src/components/technology-health/TechnologyHealthByApplication.tsx` (1011 lines) into a feature-folder structure. This is a pure refactor — no behavior changes.

Read the refactoring plan at `docs-architecture/planning/tech-health-refactoring-plan.md`, specifically the "Session 1" section. Execute steps 1.1 through 1.7 in order.

Key rules:
- Read the full source file before starting any extraction
- Create `hooks/`, `utils/`, `types/` subdirectories under `src/components/technology-health/` if they don't exist
- After each extraction, run `npx tsc --noEmit` to catch type errors immediately
- After all extractions, run `npm run build` to verify production build
- Run through every item on the Session 1 Verification Checklist
- The main component should end up at ~300-350 lines
- Do NOT change any behavior, styling, or user-visible output
- Commit on a branch: `refactor/tech-health-by-application-decompose`
```

### Prompt for Session 2

```
You are refactoring `src/components/technology-health/TechnologyHealthSummary.tsx` (1563 lines) into a feature-folder structure. This is a pure refactor — no behavior changes.

Read the refactoring plan at `docs-architecture/planning/tech-health-refactoring-plan.md`, specifically the "Session 2" section. Execute steps 2.1 through 2.10 in order.

Key rules:
- Read the full source file before starting any extraction
- Create `hooks/`, `utils/`, `types/` subdirectories under `src/components/technology-health/` if they don't exist (they may already exist if Session 1 ran first)
- If `types/shared.ts` already exists with `LIFECYCLE_SEVERITY`, import from there instead of creating a duplicate
- After each extraction, run `npx tsc --noEmit` to catch type errors immediately
- After all extractions, run `npm run build` to verify production build
- Run through every item on the Session 2 Verification Checklist
- The main component should end up at ~350-400 lines
- Do NOT change any behavior, styling, or user-visible output
- Commit on a branch: `refactor/tech-health-summary-decompose`
```
