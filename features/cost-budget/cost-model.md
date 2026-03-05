# features/cost-budget/cost-model.md
GetInSync Cost Model Architecture
Last updated: 2026-03-04
Version: 3.0

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
4. **Two cost channels only:** IT Service, Cost Bundle. Software Products are inventory — no cost.
5. **Allocation happens at the relationship level** - via Portfolio Assignment, not at the contract level.
6. **Cost tracking is optional** - TIME/PAID assessment works without cost data.
7. **Estimated costs are valid** - better to have rough numbers than none.

## 3. Cost Sources

### 3.1 Software Products (Inventory Only — No Cost)

> **v3.0 Change:** Software Products no longer carry cost. All software licensing and subscription costs flow through IT Services. See `adr-cost-model-reunification.md` for the decision rationale.

`deployment_profile_software_products` is an **inventory-only** junction — it records "what software runs on this deployment" without any cost data.

- **Behavior:** Links a Software Product to a DP for inventory/tracking purposes.
- **No cost fields:** Cost/vendor/contract columns on the junction are DEPRECATED (see §10.6).
- **Retained fields:** `software_product_id`, `deployed_version`, `quantity` (reference), `notes`.
- **Cost path:** Software licensing costs are entered as IT Service allocations via `deployment_profile_it_services`. The IT Service carries the contract, vendor, and cost pool.

**How it works:** Create an IT Service (e.g., "Microsoft 365 E5 Enterprise Agreement") with the contract cost. Link that IT Service to the Software Products it provides via `it_service_software_products`. Allocate IT Service cost to DPs via `deployment_profile_it_services`. The same DPs can also link to the Software Product via `dpsp` for inventory tracking.

### 3.2 IT Service Cost (Infrastructure + Software Contracts)

> **v3.0 Change:** IT Services now absorb the contract role previously held by ProductContract. They carry vendor, contract lifecycle, and cost pool for both infrastructure AND software licensing.

`it_services.annual_cost` holds the total cost pool for the service — whether that's shared infrastructure, a software enterprise agreement, or a managed service contract.

- **TotalAnnualCost:** The full operating cost or contract value (e.g., $100k).
- **Contract fields (NEW):** `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`.
- **Software Product link (NEW):** `it_service_software_products` junction links an IT Service to the Software Products it provides/funds (inventory relationship — no cost on this junction).
- **Behavior:** Acts as a "Cost Pool".
  - Allocated portions flow to Consumer DPs via `deployment_profile_it_services` junction.
  - Unallocated portions remain as "Stranded Cost" (Overhead) on the Publisher Workspace.
  - Contract lifecycle tracked via `vw_it_service_contract_expiry` view.

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

**Legacy note:** `applications.annual_cost` still exists as a calculated field derived from `annual_licensing_cost + annual_tech_cost` on the primary DP. It predates the two-channel model and is used by `useApplications.ts`. It will be deprecated when the frontend migration (see §10.4) is complete.

### 3.4 Legacy Fields on Deployment Profile

> **Reconciliation (2026-03-04):** These fields were originally targeted for removal in v2.5 but remain in production with heavy frontend usage (16 files). They are architecturally superseded by the three-channel cost model but cannot be dropped until a data migration and frontend refactor are complete.

| Field | Status | Replacement Channel | Frontend Consumers | Migration Risk |
|-------|--------|--------------------|--------------------|----------------|
| `annual_licensing_cost` | LEGACY | IT Service allocation (software costs now flow through IT Services) | 16 files | HIGH — CSV import/export depends on it |
| `annual_tech_cost` | LEGACY | IT Service allocation or Cost Bundle | 16 files | HIGH — same |
| `estimated_tech_debt` | LEGACY | Cost Bundle or dedicated field TBD | TechDebtModal, CSV, Charts | MEDIUM — active feature |

**Rationale:** These were "mystery costs" with no traceability. All NEW costs must flow through proper channels. Legacy data will be migrated in a future session (see §10.4 for prerequisites).

## 4. DP Cost Calculation

### 4.1 Formula

> **v3.0 Change:** DP_Licensing removed. Software costs now flow through the IT Service channel.

```
DP_Total = DP_Infrastructure + DP_Other

Where:
  DP_Infrastructure = SUM(it_service allocations via deployment_profile_it_services)
  DP_Other          = SUM(linked cost_bundle DPs.annual_cost)
```

> **Note:** Software licensing costs flow through IT Service allocations. An IT Service representing a software contract (e.g., "Microsoft 365 EA") allocates cost to DPs via `deployment_profile_it_services` the same way infrastructure services do.

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

## 7. ProductContract — Merged into IT Service

> **v3.0 Decision:** ProductContract is no longer a separate entity. IT Services absorb the contract role. See `adr-cost-model-reunification.md` for the full rationale.

### 7.1 History

ProductContract was originally a first-class entity in `core-architecture.md` and `conceptual-erd.md`. It was deferred at v2.5 (January 2026) because it would have introduced a third budget track — incompatible with the concurrent budget management build. The v2.5 workaround scattered contract fields onto the `deployment_profile_software_products` junction, creating two parallel cost streams.

### 7.2 Resolution (v3.0)

IT Services now carry:
- **Cost pool:** `it_services.annual_cost` (contract total)
- **Vendor:** `it_services.vendor_org_id`
- **Contract lifecycle:** `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`
- **Allocation:** via `deployment_profile_it_services` (existing mechanism)
- **Budget tracking:** via `it_services.budget_amount` (existing mechanism)
- **Software Product link:** via `it_service_software_products` (new junction — inventory, not cost)
- **Stranded cost:** `pool - allocations` (existing mechanism)
- **Contract expiry:** via `vw_it_service_contract_expiry` (new view)

### 7.3 Why This Works Without a Third Budget Track

IT Services already have a complete budget management stack (see `budget-management.md`): budget amounts, budget status views, budget alerts, and workspace budget summary. Software costs flowing through IT Services inherit all of this for free.

### 7.4 The "Different Price" Pattern (Revised)

With ProductContract merged into IT Service, the workaround changes:

**Before (v2.5):** Different price = different catalog entry.
**After (v3.0):** Different price = different IT Service allocation.

Example: Ministry X has a negotiated rate for Sage 300:
- IT Service: "Sage 300 License Agreement" — pool $12,000
- Ministry X DP allocation: fixed $10,000 (their negotiated rate)
- Stranded: $2,000 (contract holder absorbs the difference)

## 8. Cost Tracking Maturity

Organizations can adopt cost tracking incrementally:

| Level | Name | Licensing | Infrastructure | Allocation | Use Case |
|-------|------|-----------|----------------|------------|----------|
| **0** | **Not Tracked** | — | — | — | Focus on TIME/PAID first |
| **1** | **Estimated** | Cost Bundle | Cost Bundle | Optional | Quick start, rough numbers |
| **2** | **Categorized** | IT Service | Cost Bundle | By % | Know licensing (via IT Service), estimate infra |
| **3** | **Attributed** | IT Service | IT Service | By % | Full traceability |
| **4** | **Allocated** | IT Service + Stranded | IT Service + Stranded | By % with basis | Chargeback-ready |

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

| Field | Table | Values | Status |
|-------|-------|--------|--------|
| `cost_confidence` | `deployment_profile_software_products` | `estimated`, `verified` | DEPRECATED — dpsp is now inventory-only |

> **v3.0 note:** `cost_confidence` on the dpsp junction is deprecated along with all other cost fields on that table. Future cost confidence tracking will move to the IT Service or `deployment_profile_it_services` level (not yet implemented). Cost Bundle DPs do not yet have a `cost_confidence` field (see §10.3 — deferred).

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

### 10.6 Cost Model Reunification — NEW (v3.0)

> **Reference:** `adr-cost-model-reunification.md` — full decision rationale and schema details.

**New columns on `it_services`:**

| Column | Type | Purpose |
|--------|------|---------|
| `contract_reference` | TEXT | PO#, Contract ID, Agreement reference |
| `contract_start_date` | DATE | Contract effective date |
| `contract_end_date` | DATE | Contract expiration date |
| `renewal_notice_days` | INTEGER (default 90) | Days before expiry to trigger renewal alert |

**New table: `it_service_software_products`:**

Inventory junction linking IT Services to the Software Products they provide/fund. No cost on this junction.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID | PK |
| `it_service_id` | UUID | FK to it_services |
| `software_product_id` | UUID | FK to software_products |
| `notes` | TEXT | Free text |
| `created_at` | TIMESTAMPTZ | Audit |

**New view: `vw_it_service_contract_expiry`:**

Replaces `vw_software_contract_expiry`. Returns IT Service contract status with buckets: expired, renewal_due, expiring_soon, active, no_contract.

**Deprecated columns on `deployment_profile_software_products`:**

| Column | Disposition |
|--------|------------|
| `vendor_org_id` | DEPRECATED — vendor lives on IT Service |
| `annual_cost` | DEPRECATED — cost lives on IT Service allocation |
| `allocation_percent` | DEPRECATED — allocation is on `dpis` |
| `allocation_basis` | DEPRECATED — allocation is on `dpis` |
| `contract_reference` | DEPRECATED — contract lives on IT Service |
| `contract_start_date` | DEPRECATED — contract lives on IT Service |
| `contract_end_date` | DEPRECATED — contract lives on IT Service |
| `renewal_notice_days` | DEPRECATED — contract lives on IT Service |
| `cost_confidence` | DEPRECATED — confidence is per IT Service or allocation |

**Retained on `dpsp` (inventory role):** `software_product_id`, `deployed_version`, `quantity`, `notes`.

## 11. Out of Scope

- Seat/license tracking (use notes field or quick calculator)
- User provisioning / IAM integration
- True-up and compliance automation
- General Ledger (GL) integration

## 12. ASCII ERD (Conceptual)

```
Cost Sources (v3.0 — Two Channels)          Consumer Allocation
======================================      ===================

+--------------------+
|  software_products |  (INVENTORY ONLY — no cost)
+--------------------+
| name, version      |
+----------+---------+
           |
           | inventory link (dpsp — no cost)
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
           | via dpis (cost allocation)
           |
+-----------------------------+      +-------------------------+
|       it_services           |      |    Cost Bundle DP       |
+-----------------------------+      +-------------------------+
| annual_cost (Pool)          |      | dp_type: 'cost_bundle'  |
| contract_reference    (NEW) |      | annual_cost             |
| contract_start_date   (NEW) |      | cost_confidence         |
| contract_end_date     (NEW) |      +-------------------------+
| renewal_notice_days   (NEW) |
+-----------------------------+
           |                    \
           v                     \   inventory link (NEW)
+-------------------------------+ \  +-----------------------------+
| deployment_profile_it_services|  ->| it_service_software_products|
+-------------------------------+    +-----------------------------+
| allocation_value (Recovered)  |    | it_service_id               |
+-------------------------------+    | software_product_id         |
                                     +-----------------------------+

Stranded Cost = IT Service Pool - SUM(Recovered)
```

## 13. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v3.0 | 2026-03-04 | **Cost model reunification.** IT Services absorb the contract role. Software Products become inventory-only (no cost). Two cost channels (IT Service, Cost Bundle) replace three. §2.4: "two cost channels." §3.1: rewritten — inventory only. §3.2: expanded with contract fields, software product link. §4.1: formula — DP_Licensing removed. §7: ProductContract merged into IT Service (was "deferred"). §8: maturity levels updated. §9.1: cost_confidence on dpsp marked DEPRECATED. §10.6: NEW — reunification schema changes, deprecated dpsp columns. §12: ERD updated to show two-channel model. See `adr-cost-model-reunification.md`. |
| v2.6 | 2026-03-04 | Reconciled with production schema (dump 2026-03-03). §3.1: added cost override note (COALESCE(dpsp, sp)). §3.4: legacy columns documented as LEGACY not REMOVED (16 frontend consumers). §4.1: formula updated with cost override. §9.1: cost_confidence corrected to dpsp junction table. §10.3: marked DEFERRED. §10.4: marked BLOCKED with prerequisites. §10.5: marked DEPLOYED with as-built differences (relationship_type, missing updated_at). §12 ERD: updated to show legacy fields pending migration. |
| v2.5 | 2026-01-20 | Major simplification. Removed direct cost fields from DP. Three cost channels only (Software Product, IT Service, Cost Bundle). Added consumer allocation via portfolio_assignments. Added cost tracking maturity levels. Added cost confidence flag. Deferred ProductContract. |
| v2.4 | 2025-12-12 | Previous version with ProductContract model and EstimatedAnnualCost on DP. |

---

End of file.
