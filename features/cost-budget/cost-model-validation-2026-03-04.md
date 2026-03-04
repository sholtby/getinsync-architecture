# Cost Model Validation Report
**Date:** 2026-03-04
**Reconciled Against:** Schema dump 2026-03-03
**Scope:** All 6 cost-budget architecture docs vs production schema and frontend codebase

---

## Category A: Schema Debt (Legacy Columns)

Columns that architecture docs claim are removed or superseded, but still exist in production with active frontend consumers.

| # | Column | Table | Spec Says | Actual | Frontend Consumers | Recommendation |
|---|--------|-------|-----------|--------|-------------------|----------------|
| A.1 | `annual_licensing_cost` | deployment_profiles | DROP (cost-model.md §3.4) | EXISTS (numeric, default 0) | 16 files | KEEP — blocked by frontend migration |
| A.2 | `annual_tech_cost` | deployment_profiles | DROP (cost-model.md §3.4) | EXISTS (numeric, default 0) | 16 files | KEEP — blocked by frontend migration |
| A.3 | `estimated_tech_debt` | deployment_profiles | Implied removed by §12 ERD | EXISTS (numeric, default 0) | TechDebtModal, CSV export, ChartsView | KEEP — active feature (tech debt dashboard) |
| A.4 | `annual_cost` | applications | Predates 3-channel model | EXISTS (numeric, default 0) | useApplications.ts (calculated from A.1+A.2) | KEEP — cascading dependency on A.1/A.2 |

**Frontend files consuming legacy DP cost columns (A.1–A.3):**

| File | Usage |
|------|-------|
| `src/types/index.ts` | DeploymentProfile interface defines all 3 fields |
| `src/lib/utils/costs.ts` | `getTotalAnnualCost()` sums licensing + tech costs |
| `src/components/DeploymentProfileModal.tsx` | Form state for editing cost fields |
| `src/components/applications/DeploymentProfileCard.tsx` | Display & edit estimated_tech_debt |
| `src/components/ApplicationForm.tsx` | Application creation maps to DP cost fields |
| `src/pages/ApplicationPage.tsx` | Saves cost fields when creating/updating DPs |
| `src/components/modals/TechDebtModal.tsx` | Tech debt dashboard — sums and filters estimated_tech_debt |
| `src/components/dashboard/DashboardCsvExport.ts` | CSV export includes all 3 legacy fields |
| `src/components/ChartsView.tsx` | Tech debt sorting and display in portfolio charts |
| `src/pages/settings/ImportApplications.tsx` | CSV import maps annual_cost → annual_tech_cost |
| `src/components/CSVImportModal.tsx` | CSV import maps annual_cost → annual_tech_cost |
| `src/hooks/useDeploymentProfileEditor.ts` | Hook state for DP editor |
| `src/hooks/useApplications.ts` | Calculates annual_cost from licensing + tech |
| `src/components/dashboard/InlineChartPreview.tsx` | Cost display in chart previews |
| `src/App.tsx` | Application-level cost references |

**Migration prerequisite:** A data migration script must move existing `annual_licensing_cost`/`annual_tech_cost` values into Software Product or Cost Bundle DPs before these columns can be dropped. Estimated effort: 12–14 hours across multiple sessions.

---

## Category B: Missing Schema Elements

Elements documented in architecture specs that do not exist in the production schema.

| # | Element | Spec Source | Actual State | Recommendation |
|---|---------|------------|--------------|----------------|
| B.1 | `deployment_profiles.cost_confidence` | cost-model.md §10.3 | NOT on DP table. EXISTS on `deployment_profile_software_products` junction. | Doc update — mark deferred for DP-level. |
| B.2 | `applications.budget_fiscal_year` | budget-management.md §4.1 | NOT on applications table. Fiscal year tracking is workspace-level via `workspace_budgets`. | Doc update — superseded by workspace_budgets design. |
| B.3 | `updated_at` on dpsp and dpis | software-contract.md §4 | MISSING on both junction tables. `created_at` exists. | Stuart: ADD columns + audit triggers. Priority 2. |
| B.4 | `chk_dpsp_allocation_percent` constraint | vendor-cost.md §6.1, software-contract.md §4 | MISSING from database. | Stuart: ADD constraint. Priority 2. |
| B.5 | `vw_vendor_spend` view | software-contract.md §9 | NOT BUILT. | Defer — no frontend consumers. Build after R.1/R.2 fixed. |
| B.6 | `vw_vendor_spend_summary` view | vendor-cost.md §9.5 | NOT BUILT. | Defer — depends on fixing vw_run_rate_by_vendor first. |

**As-built junction table schemas:**

`deployment_profile_software_products` (16 columns):
id, deployment_profile_id, software_product_id, deployed_version, notes, created_at, vendor_org_id, annual_cost, quantity, allocation_percent, allocation_basis, contract_reference, contract_start_date, contract_end_date, renewal_notice_days, cost_confidence

`deployment_profile_it_services` (8 columns):
id, deployment_profile_id, it_service_id, relationship_type, allocation_basis, allocation_value, notes, created_at

---

## Category C: View Logic Bugs

| # | View | Bug | Impact | Severity | Fix |
|---|------|-----|--------|----------|-----|
| C.1 | `vw_run_rate_by_vendor` Software channel | Uses `sum(COALESCE(sp.annual_cost, 0))` — reads catalog price only, ignores `dpsp.annual_cost` junction override | Vendor spend understated when junction cost overrides exist | HIGH | Change to `sum(COALESCE(dpsp.annual_cost, sp.annual_cost, 0))` to match `vw_deployment_profile_costs` |
| C.2 | `vw_run_rate_by_vendor` IT Service channel | Uses raw `sum(COALESCE(dpis.allocation_value, 0))` without percent-vs-fixed allocation logic | IT service vendor spend misreported for percentage-based allocations | HIGH | Add CASE expression matching `vw_deployment_profile_costs` pattern |
| C.3 | `vw_budget_status` thresholds | Spec (budget-management.md §5.1): 75/90/100%. As-built: 80/100/110%. | Spec-vs-reality divergence | INFO | Spec updated to match as-built (deliberate evolution — as-built thresholds are more appropriate). |
| C.4 | `vw_budget_transfer_history` | Ignores `from_it_service_id` / `to_it_service_id` columns on `budget_transfers` table | IT service transfers not visible in transfer history | LOW | Add joins when IT service transfers are actively used. |

**C.1/C.2 Corrective SQL for `vw_run_rate_by_vendor`:**

Software channel fix — replace:
```sql
sum(COALESCE(sp.annual_cost, 0::numeric)) AS total_cost
```
With:
```sql
sum(COALESCE(dpsp.annual_cost, sp.annual_cost, 0::numeric)) AS total_cost
```

IT Service channel fix — replace:
```sql
sum(COALESCE(dpis.allocation_value, 0::numeric)) AS total_cost
```
With:
```sql
sum(
  CASE
    WHEN dpis.allocation_basis = 'fixed' THEN COALESCE(dpis.allocation_value, 0::numeric)
    WHEN dpis.allocation_basis = 'percent' AND dpis.allocation_value > 100 THEN COALESCE(dpis.allocation_value, 0::numeric)
    WHEN dpis.allocation_basis = 'percent' THEN COALESCE(its.annual_cost * dpis.allocation_value / 100, 0::numeric)
    ELSE COALESCE(dpis.allocation_value, 0::numeric)
  END
) AS total_cost
```

**C.3 Budget Status Threshold Comparison (resolved — spec updated to match as-built):**

| Status | Spec (v1.3) | As-Built | Resolution |
|--------|-------------|----------|------------|
| healthy | <75% | ≤80% | Spec updated to 80% |
| under_25 | 75–90% | N/A (merged into healthy) | Status removed from spec |
| tight | N/A | 80–100% | New status added to spec |
| over_10 | 90–100% | 100–110% | Spec updated to 100–110% |
| over_critical | >100% | >110% | Spec updated to >110% |
| no_budget | NULL | NULL or 0 | Spec updated to include 0 |
| no_costs | N/A | NULL or 0 costs | New status added to spec |

---

## Category D: Frontend Findings

### Legacy Cost Flow (still active)
- `getTotalAnnualCost()` in `src/lib/utils/costs.ts` sums `annual_licensing_cost + annual_tech_cost` as fallback when `total_cost` (from view) is unavailable
- `useApplications.ts` calculates `annual_cost` on applications from these legacy fields
- CSV import maps "Annual Cost" column → `annual_tech_cost` on deployment_profile
- CSV export includes `estimated_tech_debt`, `annual_licensing_cost`, `annual_tech_cost`
- `vw_dashboard_summary` returns `total_annual_licensing_cost`, `total_annual_cost`, `total_estimated_tech_debt` (legacy aggregates)

### Three-Channel Cost Flow (active, running in parallel)
- `vw_deployment_profile_costs` → consumed by CostSnapshotCard.tsx, CostAnalysisPanel.tsx
- `vw_budget_status` → consumed by BudgetSettings.tsx
- `vw_it_service_budget_status` → consumed by BudgetSettings.tsx
- `vw_workspace_budget_summary` → consumed by BudgetSettings.tsx
- `ApplicationCostSummary.tsx` calculates costs from all 3 channels directly

### Hardcoded Dropdowns (CLAUDE.md violation)

| File | Array | Values | Should Be |
|------|-------|--------|-----------|
| `src/components/ITServiceModal.tsx` (line 27) | `COST_MODELS` | fixed, per_user, per_instance, consumption, tiered | Reference table (none exists yet) |
| `src/components/SoftwareProductModal.tsx` (line 19) | `LICENSE_TYPES` | perpetual, subscription, open_source, freeware, other | Reference table (none exists yet) |

---

## Category E: Doc Staleness Summary

| Doc | Version | Stale Sections | Action |
|-----|---------|---------------|--------|
| cost-model.md | v2.5 | §3.4 (claims DROP — not dropped, 16 frontend consumers), §4.1 (formula missing cost override), §9.1 (cost_confidence table wrong), §10.3 (ALTER not applied), §10.4 (DROP blocked), §10.5 (dpis marked "Future" — deployed), §12 ERD (shows "no direct cost fields") | UPDATE → v2.6 |
| budget-management.md | v1.3 | §4.1 (budget_fiscal_year on apps — not added), §4.3 (workspaces.budget_amount — doesn't exist), §5.1 (thresholds differ), §6.1/6.3 (view SQL doesn't match as-built), §12.1 (multi-year marked Future — deployed), §12.2 (alerts marked Future — deployed) | UPDATE → v1.4 |
| vendor-cost.md | v1.0 | §9.3 (view has 2 bugs: C.1, C.2), §9.5 (view not built), §14 (phases not updated) | UPDATE → v1.1 |
| software-contract.md | v1.0 | §4 (updated_at/constraint missing from as-built), §9 (vw_vendor_spend not built), §14 (phases not updated) | UPDATE → v1.1 |
| budget-alerts.md | v1.0 | Header says "Implementation Pending" — Phase 1 DB layer deployed | CONFIRMED (minor updates) |
| cost-model-addendum.md | v2.5.1 | None — accurately describes zero cost impact from technology tagging | CONFIRMED (no changes) |

---

## Prioritized Refactoring Plan

### Priority 1 — Immediate (view bugs affecting data accuracy)

| ID | Action | Owner | SOC2 Relevance | Effort |
|----|--------|-------|----------------|--------|
| R.1 | Fix `vw_run_rate_by_vendor` Software channel — use `COALESCE(dpsp.annual_cost, sp.annual_cost)` | Stuart (SQL Editor) | CC7.2 data integrity — vendor spend reports show wrong numbers | 15 min |
| R.2 | Fix `vw_run_rate_by_vendor` IT Service channel — add percent-vs-fixed CASE logic | Stuart (SQL Editor) | CC7.2 data integrity — IT service vendor spend misreported | 15 min |

### Priority 2 — Short-term (missing schema elements)

| ID | Action | Owner | SOC2 Relevance | Effort |
|----|--------|-------|----------------|--------|
| R.3 | Add `updated_at` column + audit trigger on `deployment_profile_software_products` | Stuart (SQL Editor) | CC7.2 change tracking — no audit trail on junction modifications | 10 min |
| R.4 | Add `updated_at` column + audit trigger on `deployment_profile_it_services` | Stuart (SQL Editor) | CC7.2 change tracking | 10 min |
| R.5 | Add `chk_dpsp_allocation_percent` CHECK constraint (0–100 range) | Stuart (SQL Editor) | CC7.2 data integrity | 5 min |

### Priority 3 — Deferred

| ID | Action | Owner | SOC2 Relevance | Effort |
|----|--------|-------|----------------|--------|
| R.6 | Build `vw_vendor_spend` / `vw_vendor_spend_summary` views | Stuart (SQL Editor) | Low — no frontend consumers yet | 30 min |
| R.7 | Fix `vw_budget_transfer_history` to join IT service columns | Stuart (SQL Editor) | Low — IT service transfers not yet used | 15 min |
| R.8 | Frontend legacy column migration (replace 16-file dependency on annual_licensing_cost / annual_tech_cost with cost channel views) | Claude Code session | CC2.3 — spec says removed but code still uses them | 12–14 hrs |
| R.9 | Create `cost_model_types` and `license_types` reference tables; update ITServiceModal, SoftwareProductModal | Stuart + Claude Code | CLAUDE.md compliance — hardcoded dropdowns | 1.5 hrs |

### R.8 Migration Prerequisites (do NOT attempt until all are met)

1. R.1 and R.2 view bugs are fixed
2. R.3–R.5 missing schema elements are in place
3. A data migration script exists to move `annual_licensing_cost`/`annual_tech_cost` values into Cost Bundle DPs
4. Migration tested on a demo namespace first
5. CSV import/export paths updated to use cost channels

---

## SOC2 Evidence Table

| Document | Prior Version | New Version | Action | Reconciliation Date | Reconciled Against |
|----------|---------------|-------------|--------|--------------------|--------------------|
| cost-model.md | v2.5 | v2.6 | UPDATED | 2026-03-04 | Schema dump 2026-03-03 |
| budget-management.md | v1.3 | v1.4 | UPDATED | 2026-03-04 | Schema dump 2026-03-03 |
| vendor-cost.md | v1.0 | v1.1 | UPDATED | 2026-03-04 | Schema dump 2026-03-03 |
| software-contract.md | v1.0 | v1.1 | UPDATED | 2026-03-04 | Schema dump 2026-03-03 |
| budget-alerts.md | v1.0 | v1.0 | CONFIRMED | 2026-03-04 | Schema dump 2026-03-03 |
| cost-model-addendum.md | v2.5.1 | v2.5.1 | CONFIRMED | 2026-03-04 | Schema dump 2026-03-03 |

---

## Views Inventory (as-built)

All cost/budget related views in production:

| View | Purpose | Consumers |
|------|---------|-----------|
| `vw_deployment_profile_costs` | Three-channel cost rollup per DP | CostSnapshotCard, CostAnalysisPanel |
| `vw_application_run_rate` | Total run rate per application | vw_budget_status (subquery) |
| `vw_run_rate_by_vendor` | Vendor spend across 3 channels | CostAnalysisPanel (via RPC fallback) |
| `vw_software_contract_expiry` | Contract status and expiry tracking | (no direct frontend consumer found) |
| `vw_budget_status` | Per-application budget health | BudgetSettings.tsx |
| `vw_it_service_budget_status` | Per-service budget health | BudgetSettings.tsx |
| `vw_workspace_budget_summary` | Workspace-level budget rollup | BudgetSettings.tsx |
| `vw_budget_alerts` | Budget alert generation | (no direct frontend consumer found) |
| `vw_workspace_budget_history` | Year-over-year workspace budgets | (no direct frontend consumer found) |
| `vw_budget_transfer_history` | Budget transfer audit trail | (no direct frontend consumer found) |
| `vw_portfolio_costs` | Portfolio-level cost aggregation | CostAnalysisPanel |
| `vw_portfolio_costs_rollup` | Portfolio cost rollup | (no direct frontend consumer found) |

---

*Report generated: 2026-03-04*
*Validated by: Claude Code (cost model reconciliation session)*
