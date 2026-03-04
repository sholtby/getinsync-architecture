# features/cost-budget/cost-model.md
GetInSync Cost Model Architecture
Last updated: 2026-03-04

## 1. Purpose

This file defines the cost model for the GetInSync NextGen architecture.

Goals:
- Align with ServiceNow CSDM and APM practices
- Put cost closest to where it is actually incurred
- Support **Shared Infrastructure** (Central IT) without double-counting
- **Stranded Cost:** Automatically calculate unallocated overhead without dummy records
- **Consumer Allocation:** Enable cost sharing across workspaces via portfolio assignments
- **Maturity Levels:** Support organizations from "quick estimate" to "chargeback-ready"

## 2. Design Principles

1. **BusinessApplication is a reporting aggregate, not a cost container.**
2. **DeploymentProfile is the cost rollup point** - but receives cost from proper sources, not manual entry.
3. **No mystery costs on Application DPs** - all costs flow through defined channels.
4. **Three cost channels only:** Software Product, IT Service, Cost Bundle.
5. **Allocation happens at the relationship level** - via Portfolio Assignment, not at the contract level.
6. **Cost tracking is optional** - TIME/PAID assessment works without cost data.
7. **Estimated costs are valid** - better to have rough numbers than none.

## 3. Cost Sources

### 3.1 Software Product Cost (Licensing)

`software_products.annual_cost` is the home for licensing and subscription costs.

- **Behavior:** Cost flows to DeploymentProfiles via `deployment_profile_software_products` junction.
- **Cost Override:** The junction supports a per-deployment cost override via `dpsp.annual_cost`. When set, it takes precedence over the catalog price.
- **Calculation:** `DP_Licensing = SUM(COALESCE(dpsp.annual_cost, sp.annual_cost))`

**Simple Rule:** Different price = different catalog entry. If a workspace has negotiated pricing, create a separate catalog entry (e.g., "Sage 300 (Ministry X Agreement)").

### 3.2 IT Service Cost (Infrastructure)

`it_services.annual_cost` holds the total cost pool for shared infrastructure.

- **TotalAnnualCost:** The full operating cost of the service (e.g., $100k).
- **Behavior:** Acts as a "Cost Pool".
  - Allocated portions flow to Consumer DPs via `deployment_profile_it_services` junction.
  - Unallocated portions remain as "Stranded Cost" (Overhead) on the Publisher Workspace.

### 3.3 Cost Bundle DP (Everything Else)

Cost Bundle is a special DP type (`dp_type = 'cost_bundle'`) for costs that don't fit the Software Product or IT Service model.

Use for:
- Estimated/rough costs (quick start)
- Consulting and professional services
- MSP and managed service fees
- One-time migration costs
- Legacy balance-forward amounts
- Support agreements

**Fields:** `name`, `annual_cost`, `cost_confidence`, `notes`

**Legacy note:** `applications.annual_cost` still exists as a calculated field derived from `annual_licensing_cost + annual_tech_cost` on the primary DP. It predates the three-channel model and is used by `useApplications.ts`. It will be deprecated when the frontend migration (see §10.4) is complete.

### 3.4 Legacy Fields on Deployment Profile

> **Reconciliation (2026-03-04):** These fields were originally targeted for removal in v2.5 but remain in production with heavy frontend usage (16 files). They are architecturally superseded by the three-channel cost model but cannot be dropped until a data migration and frontend refactor are complete.

| Field | Status | Replacement Channel | Frontend Consumers | Migration Risk |
|-------|--------|--------------------|--------------------|----------------|
| `annual_licensing_cost` | LEGACY | Software Product channel | 16 files | HIGH — CSV import/export depends on it |
| `annual_tech_cost` | LEGACY | IT Service allocation or Cost Bundle | 16 files | HIGH — same |
| `estimated_tech_debt` | LEGACY | Cost Bundle or dedicated field TBD | TechDebtModal, CSV, Charts | MEDIUM — active feature |

**Rationale:** These were "mystery costs" with no traceability. All NEW costs must flow through proper channels. Legacy data will be migrated in a future session (see §10.4 for prerequisites).

## 4. DP Cost Calculation

### 4.1 Formula

```
DP_Total = DP_Licensing + DP_Infrastructure + DP_Other

Where:
  DP_Licensing      = SUM(COALESCE(dpsp.annual_cost, sp.annual_cost))
  DP_Infrastructure = SUM(it_service allocations via deployment_profile_it_services)
  DP_Other          = SUM(linked cost_bundle DPs.annual_cost)
```

> **Note:** `dpsp.annual_cost` is the junction-level cost override. When present, it takes precedence over the catalog price (`sp.annual_cost`). This is implemented in `vw_deployment_profile_costs`.

### 4.2 Linking Cost Bundles to Application DPs

Cost Bundle DPs can be linked to Application DPs via a junction table (future) or by convention (same application_id). Design TBD.

## 5. Consumer Allocation Model

### 5.1 The Principle

**Allocation is a relationship question, not a contract question.**

"Justice pays 25%" is about Justice's relationship to Finance as a consumer of the application - not about splitting a contract.

### 5.2 Portfolio Assignment Fields

| Field | Type | Purpose |
|-------|------|---------|
| `cost_allocation_percent` | DECIMAL(5,2) | The math (e.g., 25.00) |
| `cost_allocation_basis` | TEXT | The "why" (optional) |
| `cost_allocation_notes` | TEXT | The details (optional) |

**Basis values:** `per_user`, `negotiated`, `equal_split`, `consumption`, `headcount`, `other`

### 5.3 Example

```
Deployment Profile: Sage 300 GL - PROD
├── DP_Total: $24,000
│
├── Portfolio Assignment (Finance - publisher)
│   └── cost_allocation_percent: 50%
│   └── cost_allocation_basis: 'per_user'
│   └── cost_allocation_notes: '100 users'
│   └── Allocated Cost: $12,000
│
├── Portfolio Assignment (Justice - consumer)
│   └── cost_allocation_percent: 25%
│   └── cost_allocation_basis: 'per_user'
│   └── cost_allocation_notes: '50 users'
│   └── Allocated Cost: $6,000
│
└── Portfolio Assignment (Social Services - consumer)
    └── cost_allocation_percent: 25%
    └── cost_allocation_basis: 'per_user'
    └── cost_allocation_notes: '50 users'
    └── Allocated Cost: $6,000
```

### 5.4 Validation Rules

- SUM of `cost_allocation_percent` for a DP should = 100%
- Warning if under 100% (unallocated cost)
- Error if over 100% (over-allocated)
- NULL allocation = not yet assigned (different from 0%)

### 5.5 Workflow

| Step | Action | cost_allocation_percent |
|------|--------|------------------------|
| 1. Publish | Finance makes DP available | Publisher = 100% (default) |
| 2. Consume | Justice adds to their portfolio | Consumer = NULL (not set) |
| 3. Negotiate | Admin adjusts allocations | Publisher = 50%, Consumer = 25% |
| 4. Validate | System warns if ≠ 100% | Dashboard shows warning |

**Note:** Sharing is not blocked by cost allocation. Access and cost are separate concerns.

## 6. Stranded Cost (IT Service Overhead)

### 6.1 The Logic

1. **Total Pool:** `ITService.annual_cost` (e.g., $100k)
2. **Recovered:** Sum of allocations from all linked DPs
3. **Stranded:** `Total Pool - Recovered`

### 6.2 Example

```
IT Service: Database Hosting - SQL Server
├── Total Pool: $100,000
├── Allocated to Finance DP: $10,000
├── Allocated to Justice DP: $20,000
├── Recovered: $30,000
└── Stranded (Central IT overhead): $70,000
```

### 6.3 Reporting Rule

- **Portfolio Roll-up:** Uses only the allocated amount attached to DPs in that portfolio.
- **Service Owner Report:** Shows Total Pool, Recovered Amount, and Stranded Overhead.
- **Benefit:** No double-counting. No dummy DPs needed.

## 7. ProductContract (Deferred)

### 7.1 Status

ProductContract is **reserved for future use** but not implemented in v2.5.

### 7.2 When It Would Be Needed

- Complex allocation scenarios (split one contract across multiple DPs with different %)
- Contract management features (renewal dates, terms, vendor contacts)
- True-up and compliance tracking

### 7.3 Current Workaround

**Different price = different catalog entry.**

If Ministry X has a negotiated rate, create:
- "Sage 300 Bundle" ($12,000) - standard pricing
- "Sage 300 Bundle (Ministry X)" ($10,000) - negotiated pricing

### 7.4 Future Behavior

When ProductContract is built, it would **override** the catalog price:

```
DP links to Software Product (Sage 300 - $12,000)
DP also has ProductContract ($10,000 negotiated)
→ System uses $10,000 (contract overrides catalog)
```

## 8. Cost Tracking Maturity

Organizations can adopt cost tracking incrementally:

| Level | Name | Licensing | Infrastructure | Allocation | Use Case |
|-------|------|-----------|----------------|------------|----------|
| **0** | **Not Tracked** | — | — | — | Focus on TIME/PAID first |
| **1** | **Estimated** | Cost Bundle | Cost Bundle | Optional | Quick start, rough numbers |
| **2** | **Categorized** | Software Product | Cost Bundle | By % | Know licensing, estimate infra |
| **3** | **Attributed** | Software Product | IT Service | By % | Full traceability |
| **4** | **Allocated** | Software Product | IT Service + Stranded | By % with basis | Chargeback-ready |

### 8.1 Level 1: Estimated (Quick Start)

For organizations not ready for full attribution:

```
Cost Bundle DP: "Sage 300 - Estimated Costs"
├── annual_cost: $24,000
├── cost_confidence: 'estimated'
└── notes: "Includes licensing, hosting, support. To be broken out later."
```

**Benefits:**
- Gets costs into the system quickly
- No false precision
- Easy to refine later
- Honest about data quality

## 9. Cost Confidence Flag

### 9.1 Field

| Field | Table | Values |
|-------|-------|--------|
| `cost_confidence` | `deployment_profile_software_products` | `estimated`, `verified` |

> **As-built (2026-03-04):** `cost_confidence` exists on the `deployment_profile_software_products` junction table, not on `deployment_profiles` directly. Cost Bundle DPs do not yet have a `cost_confidence` field (see §10.3 — deferred).

### 9.2 Dashboard Indicator

> "12 applications have estimated costs. 8 have verified costs."

### 9.3 Behavior

- Default: `estimated`
- Set to `verified` when costs are confirmed/audited
- Does not affect calculations - purely informational

## 10. Schema Changes Summary

### 10.1 Add to `software_products`

```sql
ALTER TABLE software_products
ADD COLUMN annual_cost DECIMAL(12,2) DEFAULT 0;
```

### 10.2 Add to `portfolio_assignments`

```sql
ALTER TABLE portfolio_assignments
ADD COLUMN cost_allocation_percent DECIMAL(5,2) DEFAULT NULL,
ADD COLUMN cost_allocation_basis TEXT DEFAULT NULL,
ADD COLUMN cost_allocation_notes TEXT DEFAULT NULL;
```

### 10.3 Add to `deployment_profiles` (for cost bundles) — DEFERRED

```sql
-- NOT IMPLEMENTED
ALTER TABLE deployment_profiles
ADD COLUMN cost_confidence TEXT DEFAULT 'estimated';
```

> **Status (2026-03-04):** This ALTER has not been applied. `cost_confidence` was added to `deployment_profile_software_products` instead (see §9.1). Adding DP-level `cost_confidence` for cost bundles remains a future enhancement — cost bundles currently rely on the `notes` field to communicate data quality.

### 10.4 Remove from `deployment_profiles` — BLOCKED

```sql
-- NOT IMPLEMENTED — blocked by frontend migration
ALTER TABLE deployment_profiles
DROP COLUMN annual_licensing_cost,
DROP COLUMN annual_tech_cost;
```

> **Status (2026-03-04):** These columns CANNOT be dropped until the frontend migration is complete. 16 files reference these columns including the DeploymentProfile TypeScript interface, CSV import/export, tech debt dashboard, and cost utilities. See `cost-model-validation-2026-03-04.md` Category A for the full file list.
>
> **Prerequisites before dropping:**
> 1. Data migration script moves existing values into Cost Bundle DPs
> 2. Frontend refactor replaces all 16 file references with `vw_deployment_profile_costs.total_cost`
> 3. CSV import/export updated to use cost channels
> 4. `vw_dashboard_summary` updated to use channel-based cost aggregates
> 5. Migration tested on demo namespace first

### 10.5 IT Service Allocation — DEPLOYED

Table: `deployment_profile_it_services`

```sql
-- AS-BUILT (9 columns)
CREATE TABLE deployment_profile_it_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_profile_id UUID REFERENCES deployment_profiles(id),
  it_service_id UUID REFERENCES it_services(id),
  relationship_type TEXT NOT NULL,  -- as-built addition (not in original spec)
  allocation_basis TEXT,  -- 'percent' or 'fixed' (not 'flat'/'per_unit' as originally spec'd)
  allocation_value DECIMAL(12,2),  -- The recovered amount
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),  -- added 2026-03-04 (R.4), trigger: set_updated_at_dpis
  UNIQUE(deployment_profile_id, it_service_id)
);
```

> **Deployment status (2026-03-04):** This table is live and used by `vw_deployment_profile_costs`, `vw_run_rate_by_vendor`, `vw_it_service_budget_status`, and the budget management UI.
>
> **As-built differences from spec:**
> - `relationship_type` column added (NOT NULL) — not in original spec
> - `allocation_basis` values are `percent`/`fixed` (not `percent`/`flat`/`per_unit`)

## 11. Out of Scope

- Seat/license tracking (use notes field)
- User provisioning / IAM integration
- True-up and compliance automation
- General Ledger (GL) integration
- ProductContract (deferred to future version)

## 12. ASCII ERD (Conceptual)

```
Cost Sources                           Consumer Allocation
============                           ===================

+--------------------+
|  software_products |
+--------------------+
| annual_cost        |
+----------+---------+
           |
           | via junction
           v
+-------------------------------+       +-------------------------+
|      DeploymentProfile        |       |   portfolio_assignments |
+-------------------------------+       +-------------------------+
| (legacy: annual_licensing_cost|<------| cost_allocation_percent |
|  annual_tech_cost,            |       | cost_allocation_basis   |
|  estimated_tech_debt          |       | cost_allocation_notes   |
|  — pending migration)         |       +-------------------------+
| Receives cost from channels:  |
+-------------------------------+
           ^
           |
           | via junction
           |
+--------------------+      +-------------------------+
|    it_services     |      |    Cost Bundle DP       |
+--------------------+      +-------------------------+
| annual_cost (Pool) |      | dp_type: 'cost_bundle'  |
+--------------------+      | annual_cost             |
           |                | cost_confidence         |
           v                +-------------------------+
+-------------------------------+
| deployment_profile_it_services|
+-------------------------------+
| allocation_value (Recovered)  |
+-------------------------------+

Stranded Cost = IT Service Pool - SUM(Recovered)
```

## 13. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.6 | 2026-03-04 | Reconciled with production schema (dump 2026-03-03). §3.1: added cost override note (COALESCE(dpsp, sp)). §3.4: legacy columns documented as LEGACY not REMOVED (16 frontend consumers). §4.1: formula updated with cost override. §9.1: cost_confidence corrected to dpsp junction table. §10.3: marked DEFERRED. §10.4: marked BLOCKED with prerequisites. §10.5: marked DEPLOYED with as-built differences (relationship_type, missing updated_at). §12 ERD: updated to show legacy fields pending migration. |
| v2.5 | 2026-01-20 | Major simplification. Removed direct cost fields from DP. Three cost channels only (Software Product, IT Service, Cost Bundle). Added consumer allocation via portfolio_assignments. Added cost tracking maturity levels. Added cost confidence flag. Deferred ProductContract. |
| v2.4 | 2025-12-12 | Previous version with ProductContract model and EstimatedAnnualCost on DP. |

---

End of file.
