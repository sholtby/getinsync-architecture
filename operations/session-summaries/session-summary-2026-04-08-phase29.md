# Session Summary — 2026-04-08 (Phase 29)

## Completed

### COR Cost Seeding Part 2 (SQL for Stuart)
- Created `docs-architecture/schema/cor-cost-seeding-part2-it-allocations.sql`
- 37 UPDATEs + 8 INSERTs on `deployment_profile_it_services` — allocation percentages across 9 IT services
- Total allocated IT service cost: **$2,560,450** across COR namespace
- Stuart applied in SQL Editor — verified via read-only DB queries

### View Bug Fix (SQL for Stuart)
- Created `docs-architecture/schema/fix-vw-workspace-budget-summary-double-count.sql`
- `vw_workspace_budget_summary.app_run_rate` was using `vpc.total_cost` (includes service_cost) then `service_run_rate` was computed independently — double-counting
- Fix: changed to `vpc.bundle_cost` — now app_run_rate = cost bundles only, service_run_rate = IT service allocations only
- Dashboard went from $5.1M (wrong) to $2.88M (correct)

### Frontend Changes (merged to dev)
1. **Tech Health "End of Support" rename** — distinguished from Overview "At Risk"
2. **By Server expandable app rows** — click server to see applications; secondary query fetches DP→app mapping
3. **"Primary OS" → "Primary Tech"** column rename (the data shows DBs and web servers, not just OS)
4. **Tech Health KPI card cleanup** — renamed "Applications Profiled" → "Applications", removed Crown Jewels card, reordered (Apps → Mainstream → Extended → EoS), conditionally hide Needs Profiling when 0
5. **Donut label overflow fix** — wider SVG viewBox, smaller donut radius, increased truncation threshold
6. **IT Spend Run Rate sortable** — added `run_rate` to BudgetWorkspaceTable SortField, made column header clickable
7. **Overview → IT Spend pre-sort** — Annual Run Rate KPI click sets `pendingBudgetSort` in ScopeContext, IT Spend consumes and sorts by Run Rate desc
8. **Budget status fix** — `useBudgetData.ts` single-workspace path now derives `workspace_status` from run rate vs budget (was using DB allocation-based status). `BudgetWorkspaceTable` rows also derive status from run rate.

## Database Changes (Stuart applied)
- `deployment_profile_it_services`: 37 rows updated with allocation_basis + allocation_value, 8 new rows inserted
- `vw_workspace_budget_summary`: recreated with `vpc.bundle_cost` fix

## Frontend Commits
- `8123929` — fix: rename Tech Health "At Risk" to "End of Support"
- `c36df6f` — feat: dashboard cleanup — server expand, KPI reorder, sortable run rate, status fix

## Repo Status
- **Code repo:** `dev` branch, pushed, up to date
- **Architecture repo:** `main` branch, pushed, 2 SQL files committed
- **Not yet merged to `main`** — needs testing before production deploy

## Validation Results
| Check | Result |
|---|---|
| TypeScript | ✅ Pass |
| Build | ✅ Pass |
| File sizes | ⚠️ TechnologyHealthSummary.tsx 1,563 lines (pre-existing) |
| Architecture repo | ✅ Clean, pushed |

## Still Open — Next Session

### Priority: IT Spend Dashboard Data Issues
1. **"ADDS" labels on IT Services rows** — unknown source, needs investigation
2. **$0 Allocated to Apps / $0 Allocated to Services** — IT services have `budget_amount = 0`. Need to set realistic budgets on the 11 IT services ($2.98M total to match actual costs)
3. **IT workspace budget $400K vs $2.6M run rate** — budget needs to be ~$3M for demos
4. **Part 1 cost bundles not seeded** — Accela $75K, NG911 $180K, Questica $35K, etc. (10 SaaS apps from cor-cost-seeding-plan.md Part 1)

### Deferred
- User documentation for this session's changes (What's New entry, user-help articles)
- Version bump (user-visible changes shipped — needs CalVer bump when merging to main)
- `dev → main` merge + production deploy

## Context for Next Session

The COR demo namespace now has realistic IT service cost allocations flowing through to the Overview dashboard ($2.6M run rate). The double-counting view bug is fixed. Multiple dashboard UX improvements shipped.

The IT Spend workspace-level page still needs data cleanup (IT service budgets, cost bundles) and investigation of the "ADDS" label issue. The cost seeding plan doc at `docs-architecture/planning/cor-cost-seeding-plan.md` has Part 1 (SaaS cost bundles) still unimplemented.
