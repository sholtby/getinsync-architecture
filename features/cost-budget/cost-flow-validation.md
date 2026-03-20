# Garland Import Prep — Cost Flow Validation

> Created: 2026-03-16
> Purpose: Document how costs flow through NextGen before importing City of Garland data (364 apps, $16M total estimated cost). Avoid double-counting or orphaned data.

---

## 1. Write Paths to `dp.annual_cost`

| File | Line | Supabase Call | Context | dp_type |
|------|------|---------------|---------|---------|
| `src/components/applications/CostBundleSection.tsx` | 72 | `.insert({ annual_cost: Number(newCost), dp_type: 'cost_bundle' })` | User creates a cost bundle | cost_bundle |
| `src/components/DeploymentProfileModal.tsx` | 588 | `setFormData({ ...formData, annual_cost: value })` (saved via hook) | User edits cost field — **only when `isCostBundle` is true** | cost_bundle |
| `src/hooks/useDeploymentProfileEditor.ts` | ~230 | `.update(updateData)` — updateData does **NOT** include `annual_cost` for application DPs | Hook save — annual_cost is NOT in the update payload for application-type DPs | N/A |

**Key finding: `dp.annual_cost` is only written for `dp_type='cost_bundle'` DPs.** Regular application DPs never get `annual_cost` set from the UI. The column exists on all DPs but stays at `0` for application-type DPs.

**No Edge Functions, triggers, or RPCs write to `annual_cost`.**

---

## 2. Write Paths to `dp.annual_licensing_cost`

| File | Line | Supabase Call | Context | dp_type |
|------|------|---------------|---------|---------|
| `src/pages/ApplicationPage.tsx` | 474 | `.update({ annual_licensing_cost: deploymentData.annual_licensing_cost })` | Edit existing app — saves to primary DP | application |
| `src/pages/ApplicationPage.tsx` | 531 | `.update({ annual_licensing_cost: deploymentData.annual_licensing_cost })` | Create new app — updates auto-created primary DP | application |
| `src/hooks/useDeploymentProfileEditor.ts` | 236 | `.update({ annual_licensing_cost: profile.annual_licensing_cost })` | DeploymentProfileModal save (any DP) | application |
| `src/hooks/useDeploymentProfileEditor.ts` | ~317 | `.insert([insertData])` — insertData includes annual_licensing_cost | Add secondary DP | application |

**Legacy sync (ApplicationPage.tsx:492):** After saving `annual_licensing_cost` to the DP, the code also copies it to `applications.annual_cost` for backwards compatibility:
```typescript
await supabase.from('applications').update({ annual_cost: deploymentData.annual_licensing_cost }).eq('id', id);
```

**Also: `annual_tech_cost`** is written alongside `annual_licensing_cost` via the same paths. CSV imports (`CSVImportModal.tsx:146`, `ImportApplications.tsx:236`) map CSV column "annual_cost" to `annual_tech_cost` (not `annual_licensing_cost`).

**No Edge Functions, triggers, or RPCs compute `annual_licensing_cost`.**

---

## 3. Cost View Matrix

| View | Reads `dp.annual_cost`? | Reads `dp_it_services`? | Reads `dp_software_products`? | dp_type filter? | Notes |
|------|------------------------|------------------------|------------------------------|----------------|-------|
| `vw_deployment_profile_costs` | **YES** — but only from cost_bundle DPs (subquery on `dp_type='cost_bundle' AND cost_recurrence='recurring'`) summed as `bundle_cost` | **YES** — allocated via `allocation_basis` (fixed/percent) as `service_cost` | **NO** — hardcoded `(0)::numeric AS software_cost` | Main query: `dp_type='application'` only | `total_cost = service_cost + bundle_cost` |
| `vw_application_run_rate` | **Indirectly** — via `vw_deployment_profile_costs` | **Indirectly** — via `vw_deployment_profile_costs` | **NO** | `operational_status='operational'` | Sums per application |
| `vw_run_rate_by_vendor` | **YES** — Part 2 reads `dp.annual_cost` from cost_bundle DPs directly | **YES** — Part 1 reads DPIS allocations directly | **NO** | Part 1: `dp_type='application'`; Part 2: `dp_type='cost_bundle'` | UNION of two queries by cost channel |
| `vw_dashboard_summary` | **YES** — reads `dp.annual_cost` and `dp.annual_licensing_cost` from **ALL** DPs (no dp_type filter) | **NO** | **NO** | No dp_type filter; only `operational_status='operational'` | Sums directly from deployment_profiles |
| `vw_dashboard_workspace_breakdown` | **YES** — same structure as vw_dashboard_summary but grouped by workspace | **NO** | **NO** | No dp_type filter | Same as dashboard_summary |
| `vw_budget_status` | **Indirectly** — via `vw_application_run_rate` → `vw_deployment_profile_costs` | **Indirectly** — via chain | **NO** | `operational_status='operational'` | Compares `committed` (run rate) vs `budget` |

---

## 4. Frontend Cost Displays — What Shows Where

| Component | File | Data Source | What It Shows |
|-----------|------|-------------|---------------|
| **OverviewKpiCards** ("Annual Run Rate") | `src/components/overview/OverviewKpiCards.tsx:94` | `vw_workspace_budget_summary` → sums `app_run_rate + service_run_rate` across all workspaces | Cost model run rate (IT Services + Cost Bundles) |
| **DashboardAppTable** ("Run Rate" column) | `src/components/dashboard/DashboardAppTable.tsx` | `getTotalAnnualCost(app)` from `src/lib/utils/costs.ts` — uses `dp.total_cost` if available, else `annual_licensing_cost + annual_tech_cost` | Per-app run rate in table |
| **CostAnalysisPanel** | `src/components/dashboard/CostAnalysisPanel.tsx` | `vw_deployment_profile_costs` + raw DPIS/DPSP tables | Portfolio cost breakdown: Software / IT Services / Bundles / Total |
| **CostSnapshotCard** | `src/components/applications/CostSnapshotCard.tsx` | `vw_deployment_profile_costs` (sum `total_cost` for app) | Single app "Total Run Rate" |
| **ApplicationCostSummary** | `src/components/ApplicationCostSummary.tsx` | Direct queries to `dp_software_products`, `dp_it_services`, `deployment_profiles` (cost_bundles) | Expandable breakdown: Software + Services + Bundles |
| **CostBundleSection** | `src/components/applications/CostBundleSection.tsx` | `deployment_profiles` WHERE `dp_type='cost_bundle'` | CRUD for recurring cost bundles |
| **BudgetKpiCards** | `src/components/budget/BudgetKpiCards.tsx` | `vw_workspace_budget_summary` | Budget vs Run Rate vs Remaining |
| **BudgetWorkspaceTable** | `src/components/budget/BudgetWorkspaceTable.tsx` | `vw_workspace_budget_summary` | Per-workspace budget health |
| **BudgetApplicationsTable** | `src/components/budget/BudgetApplicationsTable.tsx` | `vw_budget_status` | Per-app budget vs committed |
| **BudgetServicesTable** | `src/components/budget/BudgetServicesTable.tsx` | `vw_it_service_budget_status` | Per-IT-service budget vs committed |
| **BudgetQuadrantChart** | `src/components/budget/BudgetQuadrantChart.tsx` | `vw_budget_status` (aggregated client-side by TIME quadrant) | Run rate by TIME quadrant |
| **ProjectedSpendCard** | `src/components/budget/ProjectedSpendCard.tsx` | `vw_initiative_summary` | Current + projected run rate from roadmap |
| **RoadmapKpiBar** | `src/components/roadmap/RoadmapKpiBar.tsx` | `vw_initiative_summary` | Investment / New Recurring / Net Run Rate delta |

---

## 5. Double-Counting Scenario Analysis

### Scenario

1. Import OnBase with `dp.annual_cost = 398984` on primary DP (`dp_type='application'`)
2. Create IT Service "Databank OnBase Hosting" with `annual_cost = 398984`
3. Link IT Service to OnBase's DP via `dp_it_services` with `allocation_basis='fixed', allocation_value=398984`

### Answer: **NO** — no single view or page shows $797,968

#### `vw_deployment_profile_costs` — NO double-counting
- Does NOT read `dp.annual_cost` from application-type DPs
- `service_cost` = $398,984 (from DPIS allocation)
- `bundle_cost` = $0 (no cost_bundle DPs)
- `total_cost` = **$398,984**

#### `vw_application_run_rate` — NO double-counting
- Reads from `vw_deployment_profile_costs`
- `total_run_rate` = **$398,984**

#### `vw_budget_status` — NO double-counting
- Reads from `vw_application_run_rate`
- `committed` = **$398,984**

#### Overview KPI "Annual Run Rate" — NO double-counting
- Reads from `vw_workspace_budget_summary` which sums `app_run_rate + service_run_rate`
- Note: `vw_workspace_budget_summary` calculates `service_run_rate` independently from `app_run_rate`. Need to verify these don't overlap for the same DPIS link.

#### `vw_dashboard_summary` — NO double-counting (but different metric)
- Reads `dp.annual_cost` directly from ALL deployment_profiles (no dp_type filter)
- `total_annual_cost = sum(dp.annual_cost)` = **$398,984** (from the application DP)
- Does NOT read DPIS data at all
- Shows the DP-level `annual_cost` field, which is a DIFFERENT cost metric than the cost model views

#### `vw_run_rate_by_vendor` — NO double-counting
- Part 1 (IT Services): $398,984 from DPIS
- Part 2 (Cost Bundles): $0
- Total = **$398,984**

### Why No Double-Counting Occurs

1. **`vw_deployment_profile_costs`** (and everything downstream: run rate, budget) reads cost from **DPIS allocations + cost bundles only** — it ignores `dp.annual_cost` on application-type DPs entirely
2. **`vw_dashboard_summary`** reads `dp.annual_cost` directly but does NOT add DPIS costs on top
3. The two approaches never get summed together in a single view

### Semantic Mismatch Risk

There is a **semantic mismatch** between the dashboard summary and the cost model views:
- `vw_dashboard_summary.total_annual_cost` sums `dp.annual_cost` across all DPs (flat DP-level value)
- `vw_deployment_profile_costs.total_cost` sums DPIS allocations + cost bundles (cost model value)
- If the import sets `dp.annual_cost` but the user also models IT Services, the dashboard `total_annual_cost` won't reflect the IT Service modeling — it keeps showing the imported flat value

---

## Import Recommendation for Garland

- **If importing flat costs only** (no IT Services yet): set `dp.annual_cost` on the primary DP. The dashboard summary will show totals. The cost model views (`vw_deployment_profile_costs`, budget pages) will show $0 until services are linked.
- **If you want cost model views to work immediately**: create IT Services and link via DPIS. Leave `dp.annual_cost = 0` on application DPs.
- **Do NOT set both** `dp.annual_cost` on the application DP AND create matching DPIS links — while it won't technically double-count, it creates confusing semantics where dashboard summary and cost analysis show the same number from different sources.

---

## Appendix: Cost Column Summary on deployment_profiles

| Column | Used by application DPs? | Used by cost_bundle DPs? | Written from UI? |
|--------|--------------------------|--------------------------|------------------|
| `annual_cost` | Column exists but stays at 0 | YES — primary cost field | CostBundleSection, DeploymentProfileModal (cost_bundle mode) |
| `annual_licensing_cost` | YES — licensing/subscription cost | Not used | ApplicationPage, DeploymentProfileModal, useDeploymentProfileEditor |
| `annual_tech_cost` | YES — technical/infrastructure cost | Not used | ApplicationPage, DeploymentProfileModal, CSV imports |
