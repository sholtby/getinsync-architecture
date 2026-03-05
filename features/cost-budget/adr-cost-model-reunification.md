# ADR: Cost Model Reunification — IT Services Absorb the Contract Role

**Version:** 1.0
**Date:** March 4, 2026
**Status:** DECIDED
**Decision:** IT Services become the single cost/contract layer. Software Products become pure inventory. The v2.5 fork that created two parallel cost streams is reversed.

---

## 1. Decision

Software Product costs will flow through IT Services, not through direct junction links. The `deployment_profile_software_products` junction becomes an inventory-only link ("what software runs here"). All contract management — vendor, cost pool, allocation, stranded cost, renewal tracking — lives on IT Services.

This reunifies the two parallel cost streams created by the v2.5 fork (January 2026) and restores the original ProductContract architecture in a simpler form: IT Services absorb the contract role, eliminating the need for a separate ProductContract entity.

---

## 2. Context

### 2.1 The Original Architecture (pre-v2.5)

The original architecture (documented in `core-architecture.md`, `conceptual-erd.md`, `catalogs/software-product.md`) included **ProductContract** as a first-class entity:

```
SoftwareProduct (catalog — what it IS)
    |
ProductContract (commercial agreement — what you PAY)
    |-- SupplierOrgId (vendor)
    |-- TermStart / TermEnd (contract lifecycle)
    |-- TotalCostPerBillingPeriod (cost pool)
    |
DeploymentProfileContract (allocation junction)
    |-- AllocationPercent (0-100%)
    |-- Allocates contract cost into DPs
```

ProductContract supported:
- Cost pool with consumer allocation and stranded cost visibility
- Cross-workspace cost sharing via the "Internal Vendor Pattern"
- Contract lifecycle tracking (renewal, expiry)
- Connection to IT Services via `ITServiceContract` junction

### 2.2 The v2.5 Fork (January 20, 2026)

Cost model v2.5 was described as a "Major simplification." ProductContract was deferred. The rationale was not formally documented, but analysis reveals the likely cause:

**ProductContract would have introduced a third budget track.** The budget management system (built concurrently, v1.2-v1.3) has two tracks:
1. Application budgets (`applications.budget_amount` vs `vw_application_run_rate`)
2. IT Service budgets (`it_services.budget_amount` vs committed allocations)

The workspace budget summary (`vw_workspace_budget_summary`) adds these two tracks: `total_allocated = app_budget_allocated + service_budget_allocated`.

ProductContract as a separate entity would have required:
- A third budget category in the workspace summary
- Cross-workspace cost allocation logic (provider's contract -> consumer's application run rate)
- A third set of budget alerts and status thresholds
- Rewriting `vw_workspace_budget_summary` for three categories

This complexity was incompatible with the concurrent budget management build. The pragmatic decision was to defer ProductContract and flatten its most useful fields onto the `deployment_profile_software_products` junction (vendor, cost override, contract dates, allocation percent).

### 2.3 What the Fork Created

Two days after v2.5, `software-contract.md` (v1.0, January 22, 2026) rebuilt a partial ProductContract directly on the dpsp junction — 12 additional columns including vendor_org_id, annual_cost, contract dates, allocation fields, and cost confidence. This created two parallel cost streams:

| Concept | IT Service Channel | Software Product Channel |
|---------|-------------------|------------------------|
| Cost pool | `it_services.annual_cost` | `software_products.annual_cost` |
| Vendor | `it_services.vendor_org_id` | `dpsp.vendor_org_id` |
| Allocation | `dpis.allocation_basis/value` | `dpsp.allocation_percent/basis` (stubbed) |
| Stranded cost | Calculated in views | Not calculated |
| Contract dates | None | `dpsp.contract_start/end_date` |
| Renewal tracking | None | `dpsp.renewal_notice_days` |
| Budget tracking | `it_services.budget_amount` | None |
| Budget alerts | `vw_budget_alerts` | None |

Problems with the forked model:
1. **Software allocation was stubbed** — `allocation_percent` exists on the junction but is not wired into any view. Same software product linked to 3 DPs = triple-counted.
2. **No stranded cost on software** — no way to see "we're paying for 2000 seats but only allocated 1800."
3. **Contract tracking split** — IT Services have no contract dates; Software Products have contract dates but no budget alerts.
4. **"Catalog price override" confusion** — `software_products.annual_cost` became a meaningless "list price" with the real price on the junction, inverting the original design where the catalog held contracted prices.
5. **`is_internal_only` became meaningless** — the flag exists on both tables but is not enforced anywhere (RLS is namespace-scoped, not workspace-scoped). With software products carrying cost, it was unclear whether the flag controlled inventory visibility or cost sharing.
6. **No connection between channels** — no relationship between IT Services and Software Products, despite many real-world scenarios where an IT Service funds a software product (e.g., an Enterprise Agreement).

### 2.4 The Real-World Scenario That Exposed the Gap

**Central IT purchases Microsoft 365 E5 for 2,000 seats ($240K/year) and allocates to 20 ministries.**

Under the forked model:
- If modeled as a Software Product: no allocation mechanism (stubbed), no stranded cost, no budget tracking. Linking to 20 DPs = $240K counted 20 times.
- If modeled as an IT Service: allocation works, stranded cost works, budget alerts work — but no contract dates, no renewal tracking, and no inventory link to say "this service provides Microsoft 365."
- The workaround ("different price = different catalog entry") creates 20 catalog entries with manual cost splitting and no visibility into the contract total or unallocated seats.

Additional scenarios exposed:
- **Per-user pricing:** The junction has a `quantity` field but it's not in any cost calculation. Users must manually compute seats x price.
- **Zombie renewals:** Contract auto-renews on a credit card but no one is using the software. No mechanism to detect contracted-but-unconsumed products.
- **Dead software:** Product linked to DPs on decommissioned applications. The cost is invisible because there's no contract-level view of total spend vs active consumption.

---

## 3. The Reunified Model

### 3.1 Principle

**IT Services are the cost/contract layer. Software Products are the inventory layer.**

| Entity | Role | Carries cost? |
|--------|------|--------------|
| Software Product | What software exists and where it's deployed | No — inventory only |
| IT Service | The funded, contracted service that provides software or infrastructure | Yes — cost pool, allocation, budget, contracts |
| Cost Bundle | Everything else (consulting, MSP, migration, support) | Yes — unchanged |

### 3.2 How It Works

```
IT Service: "Microsoft 365 E5 Enterprise Agreement"
|-- annual_cost: $240,000 (contract total / cost pool)
|-- vendor_org_id: Microsoft
|-- contract_reference: EA-9999              <- NEW
|-- contract_start_date: 2025-07-01          <- NEW
|-- contract_end_date: 2027-06-30            <- NEW
|-- renewal_notice_days: 90                  <- NEW
|-- budget_amount: $240,000
|-- is_internal_only: false (shared service)
|
|-- Software Products (inventory link):      <- NEW junction
|   |-- "Microsoft 365 E5"
|   |-- "Microsoft Teams"
|   |-- "Microsoft SharePoint Online"
|
|-- Consumer Allocations (dpis — existing):
|   |-- Justice DP -> fixed: $36,000 (300 seats)
|   |-- Heritage DP -> fixed: $360 (3 seats)
|   |-- Finance DP -> percent: 15% ($36,000)
|   |-- ... 17 more ministries
|
|-- Stranded Cost: $24,000 (200 unallocated seats)
|-- Budget Status: vw_it_service_budget_status (existing)
|-- Contract Expiry: vw_it_service_contract_expiry (new view)
```

Each ministry's DP also links to "Microsoft 365 E5" via `dpsp` — but purely as inventory ("what software runs on this deployment"). No cost on that link.

### 3.3 Budget Management Impact

**None.** This is the key advantage over bringing back ProductContract as a separate entity.

| Budget component | Change required |
|-----------------|----------------|
| Application budgets (`applications.budget_amount` vs run rate) | Run rate source changes from `dpsp` software cost to `dpis` allocation — view update only |
| IT Service budgets (`it_services.budget_amount` vs committed) | No change — already works |
| Workspace budget summary | No change — already sums app + service budgets |
| Budget alerts | No change — `vw_budget_alerts` already covers IT Services |
| Budget status thresholds | No change |

### 3.4 `is_internal_only` Gets Clear Meaning

| Table | Flag meaning | Controls |
|-------|-------------|----------|
| `software_products` | **Inventory visibility** — "Can other workspaces see this product in the catalog?" | Who can browse and link for inventory tracking |
| `it_services` | **Cost sharing** — "Can other workspaces allocate from this service's cost pool?" | Who can consume and be charged |

These are two different questions that were conflated when Software Products carried cost. The separation makes both flags meaningful.

### 3.5 Quick Calculator for Per-User Pricing

Per-user/per-seat pricing is handled as a **UI convenience**, not a data model change:

1. User adds an IT Service allocation to their DP
2. Quick calculator appears: `Unit price ($120) x Seats (150) = $18,000`
3. Result saved as a fixed allocation on `dpis.allocation_value`
4. Seat count stored as metadata (on dpis or the inventory link)
5. View formula stays untouched — reads `dpis.allocation_value`

No pricing model flag, no conditional multiplication in views. The calculator helps users arrive at the right number; the system stores the result.

---

## 4. Schema Changes Required

### 4.1 New Columns on `it_services`

```sql
ALTER TABLE it_services
ADD COLUMN contract_reference TEXT,
ADD COLUMN contract_start_date DATE,
ADD COLUMN contract_end_date DATE,
ADD COLUMN renewal_notice_days INTEGER DEFAULT 90;

CREATE INDEX idx_it_services_contract_end ON it_services(contract_end_date);

COMMENT ON COLUMN it_services.contract_reference IS
'PO#, Contract ID, or Agreement reference number.';

COMMENT ON COLUMN it_services.contract_end_date IS
'Contract/agreement expiration date. Used for renewal alerts.';

COMMENT ON COLUMN it_services.renewal_notice_days IS
'Days before contract_end_date to trigger renewal alert. Default 90.';
```

### 4.2 New Junction: `it_service_software_products`

Links an IT Service to the Software Products it provides/funds. Inventory relationship — no cost on this junction.

```sql
CREATE TABLE it_service_software_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  it_service_id UUID NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
  software_product_id UUID NOT NULL REFERENCES software_products(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(it_service_id, software_product_id)
);

-- Standard grants, RLS, audit
GRANT ALL ON it_service_software_products TO authenticated, service_role;
ALTER TABLE it_service_software_products ENABLE ROW LEVEL SECURITY;
```

### 4.3 New View: `vw_it_service_contract_expiry`

Replaces `vw_software_contract_expiry` as the contract lifecycle view.

```sql
CREATE OR REPLACE VIEW vw_it_service_contract_expiry AS
SELECT
  its.id AS it_service_id,
  its.name AS it_service_name,
  its.owner_workspace_id AS workspace_id,
  w.namespace_id,
  o.name AS vendor_name,
  its.contract_reference,
  its.contract_start_date,
  its.contract_end_date,
  its.renewal_notice_days,
  its.contract_end_date - CURRENT_DATE AS days_until_expiry,
  CASE
    WHEN its.contract_end_date IS NULL THEN 'no_contract'
    WHEN its.contract_end_date < CURRENT_DATE THEN 'expired'
    WHEN its.contract_end_date <= CURRENT_DATE + (its.renewal_notice_days || ' days')::INTERVAL THEN 'renewal_due'
    WHEN its.contract_end_date <= CURRENT_DATE + INTERVAL '180 days' THEN 'expiring_soon'
    ELSE 'active'
  END AS contract_status,
  its.annual_cost,
  its.budget_amount
FROM it_services its
JOIN workspaces w ON w.id = its.owner_workspace_id
LEFT JOIN organizations o ON o.id = its.vendor_org_id
WHERE its.contract_end_date IS NOT NULL;
```

### 4.4 View Updates

**`vw_deployment_profile_costs`** — Software cost subquery changes:
- Before: `SUM(COALESCE(dpsp.annual_cost, sp.annual_cost, 0))` (junction override or catalog price)
- After: Software subquery removed. All cost flows through the existing IT Service subquery (`dpis` allocations) and Cost Bundle subquery. Software Products contribute zero cost.

**`vw_run_rate_by_vendor`** — Software channel:
- Before: Separate UNION leg for Software Products
- After: Software costs roll through the IT Service channel. The Software UNION leg is removed or becomes inventory-only (count of products, no cost).

**`vw_application_run_rate`** — Unchanged. Still reads from `vw_deployment_profile_costs`. The cost source shifts internally but the output is the same.

### 4.5 Deprecation: Contract Fields on `dpsp`

The following columns on `deployment_profile_software_products` become deprecated:

| Column | Disposition |
|--------|------------|
| `vendor_org_id` | Deprecated — vendor lives on IT Service |
| `annual_cost` | Deprecated — cost lives on IT Service allocation |
| `allocation_percent` | Deprecated — allocation is on `dpis` |
| `allocation_basis` | Deprecated — allocation is on `dpis` |
| `contract_reference` | Deprecated — contract lives on IT Service |
| `contract_start_date` | Deprecated — contract lives on IT Service |
| `contract_end_date` | Deprecated — contract lives on IT Service |
| `renewal_notice_days` | Deprecated — contract lives on IT Service |
| `cost_confidence` | Deprecated — confidence is per IT Service or allocation |

**Retained on `dpsp` (inventory role):**

| Column | Purpose |
|--------|---------|
| `software_product_id` | What software is deployed |
| `deployed_version` | What version is running |
| `quantity` | How many seats/licenses (metadata) |
| `notes` | Free text |

**Migration approach:** Deprecate in code first (stop reading/writing), then drop columns in a future session. No rush — NULLable columns with no readers cause no harm.

---

## 5. Migration Path

### Phase 1: Schema (Stuart — SQL Editor)
- Add 4 contract columns to `it_services`
- Create `it_service_software_products` junction with grants, RLS, audit trigger
- Create `vw_it_service_contract_expiry` view

### Phase 2: Views (Stuart — SQL Editor)
- Update `vw_deployment_profile_costs` to remove software cost subquery
- Update `vw_run_rate_by_vendor` to remove software UNION leg
- Existing IT Service subquery already handles the cost calculation

### Phase 3: Frontend (Claude Code session)
- Update `LinkSoftwareProductModal` — remove cost/vendor/contract fields (they were never surfaced anyway)
- Add IT Service contract fields to `ITServiceModal` (contract reference, dates, renewal)
- Add IT Service → Software Product linking UI
- Add quick calculator to IT Service allocation dialog
- Surface `vw_it_service_contract_expiry` on dashboard

### Phase 4: Data Migration
- For existing `dpsp` rows with `annual_cost` set: create corresponding IT Service + allocation
- For existing `dpsp` rows with contract dates: migrate to IT Service contract fields
- Mark migrated `dpsp` cost/contract columns as NULL

### Phase 5: Cleanup
- Drop deprecated `dpsp` columns
- Drop `vw_software_contract_expiry` (replaced by `vw_it_service_contract_expiry`)
- Update all architecture docs to reflect reunified model

---

## 6. What We Gain

| Before (forked) | After (reunified) |
|-----------------|-------------------|
| Two parallel cost streams, one half-built | Single cost stream with full allocation, stranding, and budget support |
| Software allocation stubbed (inert columns) | Allocation works via existing IT Service mechanism |
| No stranded cost on software contracts | Stranded cost = contract pool - sum of allocations |
| Contract dates on junction, no alerts | Contract dates on IT Service, budget alerts already wired |
| Zombie renewals invisible | `vw_it_service_contract_expiry` surfaces expired and expiring contracts |
| `is_internal_only` meaningless | Clear separation: inventory visibility (SP) vs cost sharing (ITS) |
| "Override" mental model (catalog price is wrong) | "Contract" mental model (IT Service IS the commercial agreement) |
| Budget management can't see software contracts | IT Service budget track already handles it |
| Quick calculator impossible (no allocation mechanism) | Quick calculator on IT Service allocation (seats x price -> fixed amount) |

---

## 7. What We Lose (Acknowledged Trade-offs)

| Trade-off | Mitigation |
|-----------|-----------|
| Simple "link a product and it has a cost" UX | Users now create an IT Service for contracted software. Guided workflow can simplify this. |
| Software Products no longer show cost in the catalog | Cost lives on the IT Service. Catalog shows what's available, not what it costs. |
| Existing dpsp cost data needs migration | Phase 4 handles this. Low data volume expected (feature was barely surfaced in UI). |
| Small internal-only purchases (one workspace, one product) feel heavyweight as IT Services | Cost Bundles remain for simple "just enter a number" scenarios. IT Services are for contracted, allocated costs. |

---

## 8. Related Documents

| Document | Impact |
|----------|--------|
| `features/cost-budget/cost-model.md` | Major update — two cost channels (IT Service, Cost Bundle), not three |
| `features/cost-budget/software-contract.md` | Major update — reframe from junction to IT Service |
| `features/cost-budget/vendor-cost.md` | Update — vendor attribution simplifies to IT Service only |
| `features/cost-budget/budget-management.md` | Minor update — note that software costs now flow through IT Service track |
| `features/cost-budget/budget-alerts.md` | No change — already covers IT Services |
| `catalogs/software-product.md` | Major update — remove cost role, update ProductContract section |
| `catalogs/it-service.md` | Major update — document expanded contract role |
| `core/core-architecture.md` | Update — remove ProductContract as separate entity |
| `core/conceptual-erd.md` | Update — ProductContract merges into IT Service |
| `features/cost-budget/cost-model-primer.md` | Regenerate after doc updates |

---

## 9. Decision Record

| Attribute | Value |
|-----------|-------|
| **Decision date** | March 4, 2026 |
| **Decided by** | Stuart Holtby |
| **Context** | Cost model validation session revealed two disconnected cost streams, stubbed allocation, and missing contract lifecycle visibility on software products |
| **Options considered** | (A) Bring back ProductContract as separate entity, (B) IT Services absorb contract role, (C) Keep forked model and finish stubbed features |
| **Decision** | Option B — IT Services absorb the contract role |
| **Key reason** | No budget management rewrite required. IT Service track already has pool/allocation/stranded/budget/alerts. Only needs contract date columns and a link to Software Products. |
| **Supersedes** | cost-model.md v2.5 "three channel" model; software-contract.md v1.0 junction-based contracts |
| **SOC2 relevance** | CC2.3 — documentation accuracy. This ADR corrects a spec-vs-reality divergence that has existed since January 2026. |

---

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-04 | Initial ADR. Decision: IT Services absorb contract role. Software Products become inventory. |

---

*Document: features/cost-budget/adr-cost-model-reunification.md*
*March 2026*
