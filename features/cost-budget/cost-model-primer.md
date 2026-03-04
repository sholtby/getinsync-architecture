---
title: "GetInSync NextGen — Cost Model Primer"
subtitle: "How costs are recorded, calculated, and displayed"
author: "GetInSync Architecture Team"
date: "March 4, 2026"
version: "1.0"
---

# 1. The Big Idea

**"Every dollar needs a home and an owner."**

GetInSync tracks the cost of running your application portfolio. Instead of dumping a single dollar figure on an application and hoping someone remembers where it came from, costs flow through three defined **channels** — each tied to a specific source.

## Key Concepts

**DeploymentProfile is the cost rollup point, not the Application.** A DeploymentProfile (DP) represents a deployed instance of an application — typically one per environment (PROD, DEV, TEST). Costs attach to DPs because different environments may have different licensing, infrastructure, and support costs.

**Application is a reporting aggregate.** An application's total cost is simply the sum of costs across all its DPs. The application itself stores no cost data directly.

**Three channels, no exceptions.** Every cost enters the system through exactly one of three channels:

| Channel | What It Covers | Source Table |
|---------|---------------|-------------|
| **Software Products** | Licensing, subscriptions | `deployment_profile_software_products` |
| **IT Services** | Shared infrastructure allocations | `deployment_profile_it_services` |
| **Cost Bundles** | Everything else (consulting, MSP, support, etc.) | `deployment_profiles` with `dp_type = 'cost_bundle'` |

If a cost doesn't fit any channel, it goes in a Cost Bundle. No cost lives directly on an application or a standard deployment profile.

---

# 2. The Three Cost Channels

## 2.1 Channel 1: Software Products

Software Product costs represent licensing and subscription fees — the money you pay for the right to use a piece of software.

### Where the data lives

- **Catalog price:** `software_products.annual_cost` — the list price for the product.
- **Per-deployment cost:** `deployment_profile_software_products.annual_cost` — an optional override. If your Ministry negotiated a special rate, this is where that goes.
- **Which price wins:** The system uses `COALESCE(junction.annual_cost, catalog.annual_cost)` — the per-deployment override wins if set; otherwise, the catalog price applies.

### How to enter it

1. Open an application and go to the **Deployments & Costs** tab.
2. Expand a Deployment Profile.
3. Click **Link Software Product**.
4. Select the product from the catalog.
5. Optionally enter an **Annual Cost** override (the catalog price is shown as placeholder).
6. Optionally enter vendor, contract reference, contract dates, and renewal notice period.
7. Save.

### What else is captured

The software product junction also tracks:

| Field | Purpose |
|-------|---------|
| `vendor_org_id` | Who you pay (reseller/vendor — different from manufacturer) |
| `contract_reference` | PO number, agreement ID |
| `contract_start_date` / `contract_end_date` | Contract lifecycle |
| `renewal_notice_days` | Days before expiry to trigger a renewal alert (default: 90) |
| `cost_confidence` | `estimated` or `verified` — flags data quality |
| `quantity` | Number of seats/licenses (reference only, not used in calculations) |

### Example

> **Sage 300 GL — PROD**
>
> - Catalog price: $12,000/year
> - This deployment's cost: $10,000/year (negotiated via CDW)
> - System uses: **$10,000** (junction override wins)

---

## 2.2 Channel 2: IT Services

IT Service costs represent shared infrastructure — the servers, databases, network, and cloud services that multiple applications depend on.

### The cost pool model

An IT Service has a **total cost pool** (e.g., "Database Hosting — SQL Server" costs $100,000/year to operate). That pool gets **allocated** to the applications that use it. Whatever isn't allocated is **stranded cost** — overhead that Central IT absorbs.

```
IT Service: Database Hosting — SQL Server
Total Pool:          $100,000

Allocated:
  Finance App DP:     $10,000  (10%)
  Justice App DP:     $20,000  (20%)

Recovered:            $30,000
Stranded (overhead):  $70,000
```

### Where the data lives

- **Cost pool:** `it_services.annual_cost` — the total operating cost.
- **Allocations:** `deployment_profile_it_services` — links an IT Service to a DP with an allocation.

### Two allocation modes

| Mode | Field Value | How It Works |
|------|------------|-------------|
| **Fixed** | `allocation_basis = 'fixed'` | `allocation_value` is a dollar amount (e.g., $10,000) |
| **Percent** | `allocation_basis = 'percent'` | `allocation_value` is a percentage of the pool (e.g., 10 = 10% of pool) |

### How to enter it

1. Open an application and go to the **Deployments & Costs** tab.
2. Expand a Deployment Profile.
3. In the **"What Services Does It Use?"** section, click **Add Service**.
4. Select the IT Service.
5. Choose allocation basis (fixed dollar or percentage).
6. Enter the allocation value.
7. Save.

### Example

> **Finance ERP — PROD** uses "Database Hosting — SQL Server"
>
> - Allocation basis: percent
> - Allocation value: 10
> - IT Service pool: $100,000
> - Calculated cost: **$10,000** (10% of $100,000)

---

## 2.3 Channel 3: Cost Bundles

Cost Bundles capture everything that isn't a software license or an IT service allocation. They are the "catch-all" channel.

### Use cases

- Estimated/rough costs when you're just getting started
- Consulting and professional services fees
- Managed service provider (MSP) contracts
- One-time migration or project costs
- Annual support agreements
- Legacy balance-forward amounts

### Where the data lives

A Cost Bundle is a special type of Deployment Profile:

- `deployment_profiles.dp_type = 'cost_bundle'`
- `deployment_profiles.annual_cost` — the dollar amount
- `deployment_profiles.cost_recurrence = 'recurring'` — only recurring bundles count toward run rate

### Important: Primary DP rule

Cost Bundles are scoped to an application (via `application_id`), but they only roll up through the **primary** DP (`is_primary = true`). This prevents double-counting when an application has multiple DPs (e.g., PROD and DEV).

### How to enter it

1. Open an application and go to the **Deployments & Costs** tab.
2. Scroll to the **Recurring Costs** section at the bottom.
3. Click **Add Recurring Cost**.
4. Enter a name (e.g., "Annual Support Agreement") and the annual cost.
5. Save.

### Example

> **Finance ERP** has two cost bundles:
>
> - "Vendor Support Agreement" — $5,000/year
> - "Annual Penetration Test" — $3,000/year
> - Total bundle cost: **$8,000**

---

# 3. How Costs Roll Up

## 3.1 Deployment Profile Level

The database view `vw_deployment_profile_costs` calculates the total cost for each application-type DP by summing across all three channels:

```
DP Total = Software Cost + Service Cost + Bundle Cost

Where:
  Software Cost = SUM(COALESCE(junction.annual_cost, catalog.annual_cost))
  Service Cost  = SUM(fixed allocations) + SUM(percent allocations)
  Bundle Cost   = SUM(cost_bundle DPs where is_primary = true)
```

The view returns these columns for each DP:

| Column | Description |
|--------|-------------|
| `deployment_profile_id` | Which DP |
| `application_id` | Which application |
| `software_cost` | Total from Software Product channel |
| `service_cost` | Total from IT Service channel |
| `bundle_cost` | Total from Cost Bundle channel |
| `total_cost` | Sum of all three |

## 3.2 Application Level

An application's **total run rate** is the sum of `total_cost` across all its application-type DPs:

```
App Run Rate = SUM(DP.total_cost) for all DPs where dp_type = 'application'
```

The view `vw_application_run_rate` provides this rollup.

## 3.3 The Cost Utility

In the frontend, the function `getTotalAnnualCost()` in `src/lib/utils/costs.ts` is the single source of truth for displaying an application's cost:

```
getTotalAnnualCost(app):
  1. If total_cost from the view is available → use it
  2. Otherwise → fall back to legacy fields (annual_licensing_cost + annual_tech_cost)
```

This fallback exists because some older data hasn't been migrated to the three-channel model yet (see Section 7).

---

# 4. Where Costs Appear in the UI

## 4.1 Application Detail — General Tab

**CostSnapshotCard** shows a single "Total Run Rate" figure for the application. It queries `vw_deployment_profile_costs` and sums across all DPs. Click it to navigate to the full cost breakdown.

## 4.2 Application Detail — Deployments & Costs Tab

**ApplicationCostSummary** shows an expandable tree breaking down costs by channel:

- **Software Products** — each linked product with its effective cost
- **IT Services** — each allocated service with its calculated cost and allocation percentage
- **Recurring Costs** — each cost bundle with its amount
- **Total Run Rate** — the sum

If the application has multiple DPs, each cost line shows which DP it belongs to.

## 4.3 Dashboard — Cost Analysis

**CostAnalysisPanel** provides portfolio-level cost analysis:

- Portfolio total run rate
- Top 5 most expensive applications
- Breakdown by vendor (who are we paying the most?)
- Breakdown by application (expandable to show per-DP costs)

## 4.4 Budget Settings

**BudgetSettings** (Settings > Budget) compares actual run rate against budgets:

- Workspace-level budget from `workspace_budgets` table
- Per-application budget status (healthy / tight / over_10 / over_critical)
- Per-IT-service budget status
- Budget health alerts

---

# 5. Cost Maturity Levels

Organizations don't need to track every dollar from day one. GetInSync supports a crawl-walk-run approach:

| Level | Name | Licensing | Infrastructure | Allocation | When to Use |
|-------|------|-----------|----------------|------------|-------------|
| **0** | Not Tracked | — | — | — | Focus on TIME/PAID assessment first |
| **1** | Estimated | Cost Bundle | Cost Bundle | Optional | Quick start, rough numbers |
| **2** | Categorized | Software Product | Cost Bundle | By % | Know licensing, estimate infra |
| **3** | Attributed | Software Product | IT Service | By % | Full traceability |
| **4** | Allocated | Software Product | IT Service + Stranded | By % with basis | Chargeback-ready |

### Level 1 Example (Quick Start)

Don't know the breakdown? Create a single Cost Bundle:

> "Finance ERP — Estimated Costs" — $50,000/year
>
> Notes: "Includes licensing, hosting, and support. To be broken out later."

This is better than nothing. You get a cost figure in the system immediately, and you can refine it later by replacing the bundle with actual Software Product and IT Service entries.

---

# 6. Data Flow Diagram

```
USER ENTRY
===========
                                                    DATABASE TABLES
                                                    ===============
  Link Software Product  ───────────────────►  deployment_profile_software_products
  (annual_cost override)                        ├─ annual_cost (override)
                                                ├─ vendor_org_id
                                                └─ contract fields
                                                          │
  Allocate IT Service  ─────────────────────►  deployment_profile_it_services
  (fixed $ or % of pool)                        ├─ allocation_value
                                                └─ allocation_basis (fixed/percent)
                                                          │
  Add Recurring Cost  ──────────────────────►  deployment_profiles
  (cost bundle)                                  ├─ dp_type = 'cost_bundle'
                                                 ├─ annual_cost
                                                 └─ cost_recurrence = 'recurring'
                                                          │
                                                          ▼
                                                   CALCULATION
                                                   ===========
                                              vw_deployment_profile_costs
                                                ├─ software_cost
                                                ├─ service_cost
                                                ├─ bundle_cost
                                                └─ total_cost
                                                          │
                                                          ▼
                                                      DISPLAY
                                                      =======
                                  ┌────────────────────────────────────────┐
                                  │                                        │
                          CostSnapshotCard              ApplicationCostSummary
                          (General tab)                 (Deployments & Costs)
                          "Total Run Rate"              Channel-by-channel tree
                                  │                                        │
                                  ▼                                        ▼
                          CostAnalysisPanel              BudgetSettings
                          (Dashboard)                    (Settings)
                          Portfolio breakdown             Budget vs run rate
```

---

# 7. Legacy Fields and Migration

Three cost fields from the pre-channel model still exist on the `deployment_profiles` table:

| Field | Status | Notes |
|-------|--------|-------|
| `annual_licensing_cost` | LEGACY | Not editable in UI. 16 frontend files still reference it. |
| `annual_tech_cost` | LEGACY | Not editable in UI. CSV import still maps to this field. |
| `estimated_tech_debt` | LEGACY | Used by TechDebtModal and CSV export. |

These fields are **architecturally superseded** by the three-channel model but cannot be removed yet because:

1. The `getTotalAnnualCost()` utility falls back to them when view data isn't available.
2. CSV import maps the "Annual Cost" column to `annual_tech_cost`.
3. CSV export includes all three fields.
4. The dashboard summary view aggregates these fields.

**Migration plan:** A future session will migrate existing data from these fields into Cost Bundle DPs, update the frontend references, and then drop the columns. See `cost-model-validation-2026-03-04.md` for the full prerequisite list.

---

# 8. Quick Reference

## Key Tables

| Table | Purpose |
|-------|---------|
| `software_products` | Software product catalog (name, manufacturer, annual_cost) |
| `it_services` | IT service catalog (name, annual_cost = total pool) |
| `deployment_profiles` | Deployment instances; also stores cost bundles (`dp_type = 'cost_bundle'`) |
| `deployment_profile_software_products` | Links software products to DPs with cost override + contract fields |
| `deployment_profile_it_services` | Links IT services to DPs with allocation (fixed or percent) |
| `workspace_budgets` | Multi-year workspace budget tracking |

## Key Views

| View | Purpose |
|------|---------|
| `vw_deployment_profile_costs` | Three-channel cost rollup per DP |
| `vw_application_run_rate` | Total run rate per application |
| `vw_run_rate_by_vendor` | Cost by vendor across all three channels |
| `vw_budget_status` | Per-application budget health |
| `vw_it_service_budget_status` | Per-service budget health |
| `vw_workspace_budget_summary` | Workspace-level budget rollup |
| `vw_software_contract_expiry` | Contract status and renewal tracking |

## Key Frontend Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `CostSnapshotCard` | General tab | Shows total run rate |
| `ApplicationCostSummary` | Deployments & Costs tab | Channel-by-channel cost breakdown |
| `CostBundleSection` | Deployments & Costs tab | Add/edit recurring costs |
| `CostAnalysisPanel` | Dashboard | Portfolio-level cost analysis |
| `BudgetSettings` | Settings page | Budget vs run rate management |

## Key Hooks

| Hook | File | Purpose |
|------|------|---------|
| `useDeploymentProfiles` | `src/hooks/useDeploymentProfiles.ts` | Fetch DPs for application/portfolio |
| `useDeploymentProfileEditor` | `src/hooks/useDeploymentProfileEditor.ts` | DP editing state management |

---

# 9. Further Reading

| Document | What It Covers |
|----------|---------------|
| `features/cost-budget/cost-model.md` (v2.6) | Full architecture: allocation model, stranded cost, maturity levels |
| `features/cost-budget/vendor-cost.md` (v1.1) | Vendor attribution, manufacturer vs vendor, run rate views |
| `features/cost-budget/software-contract.md` (v1.1) | Junction schema, SAM-lite contract fields, cost override logic |
| `features/cost-budget/budget-management.md` (v1.4) | Budgets, thresholds, workspace_budgets table, IT service budgets |
| `features/cost-budget/budget-alerts.md` (v1.0) | Alert preferences, configurable alert rules |
| `features/cost-budget/cost-model-validation-2026-03-04.md` | Validation report: known issues, refactoring plan |

---

*Document: features/cost-budget/cost-model-primer.md*
*Version 1.0 — March 2026*
