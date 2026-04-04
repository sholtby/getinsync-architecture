# features/cost-budget/software-contract.md
Software Product Contracts & Vendor Management
Last updated: 2026-04-03
Version: 3.0

---

> **v2.0 MAJOR CHANGE:** Software contracts now live on **IT Services**, not the `deployment_profile_software_products` junction. All cost/vendor/contract columns on the junction are **DEPRECATED**. See `adr-cost-model-reunification.md` for the full decision rationale.

## 1. Purpose

This document defines the architecture for tracking software vendors, contracts, and procurement costs in GetInSync NextGen.

**Key Insight:** Organizations care about "who's ripping me off?" — the vendor/reseller relationship — not just who manufactures the software.

**Scope:**
- Manufacturer vs. Vendor distinction
- IT Service as the contract and cost layer for software (v2.0)
- SAM-lite contract fields (expiry, reference, vendor) on IT Services
- Junction table is now inventory-only (no cost, no contract)
- What we explicitly do NOT track (staying out of the SAM swamp)

**Audience:** Internal architects, developers, and implementers.

---

## 2. Key Distinction: Manufacturer vs. Vendor

| Role | Question | Example | Stability |
|------|----------|---------|-----------|
| **Manufacturer** | Who makes the software? | Microsoft, Adobe, SAP | Fixed per product |
| **Vendor/Reseller** | Who sells it to you? Who has your contract? | CDW, SHI, Insight, Microsoft Direct | Varies by deployment |

### Real-World Scenarios

| Software | Manufacturer | Possible Vendors |
|----------|--------------|------------------|
| Microsoft 365 | Microsoft | Microsoft Direct, CDW, SHI, Insight |
| Adobe Creative Cloud | Adobe | Adobe Direct, CDW, SoftwareOne |
| SAP S/4HANA | SAP | SAP Direct, Accenture, Deloitte |
| Sage 300 | Sage | Sage Direct, local resellers |

### Why This Matters

1. **Same product, different pricing:** Ministry A pays list price direct; Ministry B has volume discount via CDW
2. **Contract consolidation:** "We have 12 Microsoft products through 4 different resellers"
3. **Vendor management:** "Which vendors have contracts expiring?" requires knowing WHO you're paying
4. **Cost analysis:** "How much are we spending with CDW across all products?"

---

## 3. Architectural Decision: Vendor on IT Service, Not Application or Junction

### Decision

**DO NOT add `vendor_organization_id` to the `applications` table.**

> **v2.0 Change:** Vendor relationship is captured on **IT Services**, not the dpsp junction. The junction is now inventory-only.

Vendor relationship is captured on `it_services.vendor_org_id`. The IT Service represents the commercial agreement — who you pay, how much, when the contract expires.

### Rationale

| Approach | Problem |
|----------|---------|
| Vendor on Application | Conflates software maker, reseller, and support provider |
| Vendor on Junction (v1.0) | Created two parallel cost streams; allocation was stubbed; no budget tracking |
| **Vendor on IT Service (v2.0)** | IT Service already has cost pool, allocation, budget, stranded cost, and budget alerts |

### Data Model (v2.0)

```
software_products (Catalog — INVENTORY ONLY)
├── manufacturer_org_id → Organization (Microsoft)
└── annual_cost (reference price — NOT used in cost calculations)

it_services (Contract + Cost Layer)
├── vendor_org_id → Organization (CDW)           ← Who you PAY
├── annual_cost → Contract total / cost pool      ← What you PAY
├── contract_reference → PO#, Agreement#          ← Contract ID
├── contract_start_date / contract_end_date       ← Contract lifecycle
├── renewal_notice_days                           ← Alert threshold
└── budget_amount → Budget for this service       ← Budget tracking

it_service_software_products (Inventory Link — NEW)
├── it_service_id → IT Service
└── software_product_id → Software Product        ← What this service provides

deployment_profile_software_products (Junction — INVENTORY ONLY)
├── software_product_id → Software Product         ← What software runs here
├── deployed_version → What version is running
└── notes
```

### Path Summary (v2.0)

| Question | Path |
|----------|------|
| Who makes it? | DP → dpsp → Software Product → `manufacturer_org_id` → Organization |
| Who do we pay? | DP → dpis → IT Service → `vendor_org_id` → Organization |
| What's the contract total? | IT Service → `annual_cost` |
| What does this DP pay? | dpis → `allocation_value` (fixed or percent of pool) |
| What software does the service provide? | IT Service → `it_service_software_products` → Software Product |

---

## 4. Schema: deployment_profile_software_products (Inventory Only)

> **v2.0 DEPRECATION:** The "enhanced" dpsp junction from v1.0 scattered cost/vendor/contract fields on the inventory junction. These fields are ALL DEPRECATED in v2.0 — cost and contract data now lives on IT Services. See `adr-cost-model-reunification.md` §4.5 for the full deprecation schedule.

### Inventory Schema (Retained Columns)

```sql
CREATE TABLE deployment_profile_software_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_profile_id UUID REFERENCES deployment_profiles(id) ON DELETE CASCADE,
  software_product_id UUID REFERENCES software_products(id) ON DELETE CASCADE,
  deployed_version TEXT,            -- What version is running
  quantity INTEGER,                 -- Reference: seats/licenses (metadata)
  notes TEXT,                       -- Free text
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(deployment_profile_id, software_product_id)
);
```

### Deprecated Columns (Still in DB — Pending Drop)

| Column | Type | Status | Replacement |
|--------|------|--------|-------------|
| vendor_org_id | UUID | DEPRECATED | `it_services.vendor_org_id` |
| annual_cost | DECIMAL(12,2) | DEPRECATED | IT Service allocation via `dpis.allocation_value` |
| allocation_percent | DECIMAL(5,2) | DEPRECATED | `dpis.allocation_value` with `allocation_basis` |
| allocation_basis | TEXT | DEPRECATED | `dpis.allocation_basis` |
| contract_reference | TEXT | DEPRECATED | `it_services.contract_reference` |
| contract_start_date | DATE | DEPRECATED | `it_services.contract_start_date` |
| contract_end_date | DATE | DEPRECATED | `it_services.contract_end_date` |
| renewal_notice_days | INTEGER | DEPRECATED | `it_services.renewal_notice_days` |
| cost_confidence | TEXT | DEPRECATED | Future: IT Service or dpis level |

**These columns are NULLable and have minimal data (UI never surfaced most of them). They will be dropped in Phase 5 of the reunification migration after a verification period.**

---

## 5. Cost Model (v2.0 — Via IT Service)

> **v2.0 Change:** The junction-level cost override logic from v1.0 is DEPRECATED. Software costs now flow through IT Service allocations.

### Principle

**IT Service is the cost pool. Software Product is inventory only.**

### Formula

```sql
-- Software cost for a DP is calculated via IT Service allocations, NOT junction overrides
DP_Software_Cost = SUM(
  CASE dpis.allocation_basis
    WHEN 'fixed' THEN dpis.allocation_value
    WHEN 'percent' THEN (its.annual_cost * dpis.allocation_value / 100)
  END
)
-- WHERE the IT Service provides the relevant Software Product
-- (linked via it_service_software_products)
```

### Example

| IT Service | Contract Total | DP Allocation | DP Cost |
|------------|---------------|---------------|---------|
| Microsoft 365 EA | $240,000 | fixed: $36,000 (300 seats) | $36,000 |
| Microsoft 365 EA | $240,000 | percent: 5% | $12,000 |
| Sage 300 License | $12,000 | fixed: $10,800 (negotiated) | $10,800 |

### DEPRECATED: Junction Cost Override (v1.0)

The following formula is NO LONGER USED:

```sql
-- DEPRECATED — do not use
Effective_Cost = COALESCE(junction.annual_cost, software_products.annual_cost)
```

---

## 6. SAM-Lite Scope

### What We Track ✅

| Field | Purpose | Business Question |
|-------|---------|-------------------|
| vendor_org_id | Who you pay | "How much are we spending with CDW?" |
| annual_cost | What you pay | "What's our actual software spend?" |
| quantity | How many | "How many licenses do we have?" (reference) |
| contract_reference | Agreement ID | "What's the PO# for renewal?" |
| contract_end_date | Expiration | "What's expiring in the next 90 days?" |
| renewal_notice_days | Alert threshold | "When should we start renewal process?" |
| cost_confidence | Data quality | "Is this cost verified or estimated?" |
| notes | Context | "Any special terms or notes?" |

### What We Do NOT Track ❌ (The SAM Swamp)

| Feature | Why Avoid |
|---------|-----------|
| License entitlements | Requires discovery tools, complex modeling |
| Usage/consumption data | Needs integration with identity/endpoint systems |
| True-up calculations | Legal complexity, specialized SAM tools exist |
| Compliance status | Liability concerns, auditor territory |
| Contract terms & conditions | Document management scope creep |
| Renewal workflows | Workflow engine scope creep |
| Approval chains | Procurement system territory |
| Vendor scorecards | Vendor management system territory |

### The Line We Draw

> GetInSync answers: "What software do we have, who do we pay, how much, and when does it expire?"
>
> GetInSync does NOT answer: "Are we compliant with our license terms?"

---

## 7. Contract Expiry Reporting

> **v3.0 Change:** Contract expiry reporting now uses `vw_contract_expiry` — a UNION view combining IT Services and Cost Bundles (deployment profiles with `dp_type = 'cost_bundle'`). This replaces `vw_it_service_contract_expiry`. See `adr-contract-aware-cost-bundles.md` for rationale.

### Dashboard Widget

**"Contract Expiry"** — shows contracts from both IT Services and Cost Bundles.

The widget table includes a **Source** column (`IT Service` or `Cost Bundle`) to help users identify Cost Bundles that should graduate to IT Services as they mature.

### Detail Report (v3.0)

```sql
SELECT
  source_name AS contract_name,
  source_type,
  vendor_name,
  contract_reference,
  contract_end_date,
  annual_cost,
  days_until_expiry,
  status
FROM vw_contract_expiry
WHERE status IN ('renewal_due', 'expiring_soon')
ORDER BY contract_end_date;
```

### Contract Status Buckets

| Status | Condition |
|--------|-----------|
| `expired` | `contract_end_date < CURRENT_DATE` |
| `renewal_due` | Within `renewal_notice_days` of expiry |
| `expiring_soon` | Within 180 days of expiry |
| `active` | More than 180 days to expiry |
| `no_contract` | No contract end date set |

### Notification (Future)

When `contract_end_date - renewal_notice_days <= CURRENT_DATE`:
- Flag in UI
- Optional email notification (future)
- Export for procurement team

### DEPRECATED Views

| View | Status | Replacement |
|------|--------|-------------|
| `vw_software_contract_expiry` | DEPRECATED (Phase 5 drop) | `vw_contract_expiry` |
| `vw_it_service_contract_expiry` | DEPRECATED (kept for backwards compat) | `vw_contract_expiry` |

---

## 8. Allocation Model — Now Via IT Services

> **v2.0 Change:** The stubbed allocation on the dpsp junction is DEPRECATED. Allocation now uses the existing IT Service mechanism (`deployment_profile_it_services`) which already supports fixed-dollar and percentage-based allocation, stranded cost, and budget tracking.

### How It Works (v2.0)

**Shared Microsoft 365 tenant across multiple applications:**

| IT Service | annual_cost | DP | Allocation Basis | Allocation Value | DP Cost |
|------------|------------|-----|-----------------|-----------------|---------|
| Microsoft 365 E3 EA | $43,200 | HR-Prod | percent | 40 | $17,280 |
| Microsoft 365 E3 EA | $43,200 | Fin-Prod | percent | 35 | $15,120 |
| Microsoft 365 E3 EA | $43,200 | CRM-Prod | percent | 25 | $10,800 |
| **Total** | | | | **100%** | **$43,200** |
| **Stranded** | | | | | **$0** |

### Quick Calculator (UI Convenience)

For per-user/per-seat pricing, a UI quick calculator helps users arrive at the right allocation:

```
Unit price ($120) x Seats (150) = $18,000
→ Saved as allocation_basis = 'fixed', allocation_value = $18,000
```

No data model change needed — the calculator computes, the system stores the result.

### DEPRECATED: dpsp.allocation_percent

The junction-level `allocation_percent` and `allocation_basis` columns are deprecated and will be dropped in Phase 5.

---

## 9. View Updates (v2.0)

### vw_deployment_profile_costs

> **v2.0 Change:** The software cost subquery has been removed. All cost flows through IT Service and Cost Bundle channels.

**Before (v1.0):** `software_cost = SUM(COALESCE(dpsp.annual_cost, sp.annual_cost))`
**After (v2.0):** `software_cost = 0` (or column removed). All software costs flow through `service_cost` via IT Service allocations.

### vw_contract_expiry (NEW — UNION of IT Services + Cost Bundles)

> **v3.0 Change:** Replaces `vw_it_service_contract_expiry` with a UNION view that includes Cost Bundle contracts.

```sql
-- IT Services with contracts
SELECT 'it_service' AS source_type, its.id AS source_id, its.name AS source_name,
  its.namespace_id, its.owner_workspace_id AS workspace_id,
  NULL AS application_id, NULL AS application_name,
  its.vendor_org_id, o.name AS vendor_name,
  its.contract_reference, its.contract_start_date, its.contract_end_date,
  its.renewal_notice_days, its.annual_cost,
  its.contract_end_date - CURRENT_DATE AS days_until_expiry,
  CASE ... END AS status
FROM it_services its LEFT JOIN organizations o ON o.id = its.vendor_org_id
WHERE its.contract_end_date IS NOT NULL

UNION ALL

-- Cost Bundles with contracts
SELECT 'cost_bundle' AS source_type, dp.id AS source_id, dp.name AS source_name,
  w.namespace_id, dp.workspace_id,
  dp.application_id, a.name AS application_name,
  dp.vendor_org_id, o.name AS vendor_name,
  dp.contract_reference, dp.contract_start_date, dp.contract_end_date,
  dp.renewal_notice_days, dp.annual_cost,
  dp.contract_end_date - CURRENT_DATE AS days_until_expiry,
  CASE ... END AS status
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
LEFT JOIN applications a ON a.id = dp.application_id
LEFT JOIN organizations o ON o.id = dp.vendor_org_id
WHERE dp.dp_type = 'cost_bundle' AND dp.contract_end_date IS NOT NULL;
```

### DEPRECATED Views

| View | Status | Replacement |
|------|--------|-------------|
| `vw_software_contract_expiry` | DEPRECATED | `vw_contract_expiry` |
| `vw_it_service_contract_expiry` | DEPRECATED (kept for backwards compat) | `vw_contract_expiry` |
| `vw_vendor_spend` | NOT BUILT — cancelled | Vendor spend is via `vw_run_rate_by_vendor` (IT Service + Cost Bundle channels) |

---

## 10. UI Implications (v2.0)

### Software Product Link Dialog (Simplified)

> **v2.0 Change:** The link dialog is now inventory-only. Cost, vendor, and contract fields are removed (they were never surfaced in UI anyway — the as-built modal only captured software_product_id, deployed_version, and notes).

When linking a Software Product to a Deployment Profile:

- Software Product (dropdown)
- Deployed Version (text)
- Quantity (number — reference only)
- Notes

### IT Service Modal (Enhanced)

When creating or editing an IT Service:

**Cost fields (existing):**
- Annual Cost (the contract total / cost pool)
- Cost Model (dropdown)

**Contract Details (NEW — collapsible section):**
- Contract Reference (text)
- Start Date (date picker)
- End Date (date picker)
- Renewal Notice Days (number, default 90)

**Software Products Provided (NEW section):**
- List of Software Products linked via `it_service_software_products`
- Add/remove links

### New Reports/Pages

| Report | Location | Content |
|--------|----------|---------|
| Contract Expiry | Dashboard widget or IT Service settings | IT Service contracts expiring (from `vw_it_service_contract_expiry`) |
| Quick Calculator | IT Service allocation dialog | Unit price x Quantity = Fixed allocation |

---

## 11. Migration Notes

### Existing Data

No data migration required. All new fields are NULLable or have defaults.

### Behavioral Change

**Before:** `software_products.annual_cost` was the only cost source
**After:** Junction cost overrides catalog if present

Existing deployments will continue to use catalog price until junction cost is populated.

### RLS Impact

New columns inherit existing RLS policies on `deployment_profile_software_products`. No policy changes needed.

The new views need SELECT grants:
```sql
GRANT SELECT ON vw_software_contract_expiry TO authenticated;
GRANT SELECT ON vw_vendor_spend TO authenticated;
```

---

## 12. CSDM Alignment Note

### Original CSDM Spec (v1.0)

The CSDM spec proposed `applications.vendor_organization_id` to align with ServiceNow's vendor field on `cmdb_ci_business_app`.

### Revised Approach

We capture vendor at the **deployment/purchase level** rather than application level because:
1. Same application can have multiple software products from different vendors
2. Vendor is a property of the transaction, not the software itself
3. Enables accurate spend analysis

### ServiceNow Sync Mapping

When syncing to ServiceNow:
- `cmdb_ci_business_app.vendor` → Derived from primary software product's vendor (or left empty)
- Detailed vendor/contract data stays in GetInSync (ServiceNow doesn't have equivalent granularity)

---

## 13. Related Documents

| Document | Relevance |
|----------|-----------|
| features/cost-budget/adr-cost-model-reunification.md | ADR: IT Services absorb the contract role |
| features/cost-budget/cost-model.md | Two cost channels (v3.0), view logic |
| catalogs/it-service.md | IT Service expanded with contract role |
| catalogs/software-product.md | Catalog structure, manufacturer (inventory only) |
| core/involved-party.md | Organization entity, is_vendor flag |

---

## 14. Implementation Phases

### v1.x Phases (COMPLETED — now SUPERSEDED by v2.0 reunification)

| Phase | Scope | Status |
|-------|-------|--------|
| **23-pre** | Junction schema enhancement | DEPLOYED → DEPRECATED by v2.0 |
| **23-pre** | View updates (vw_deployment_profile_costs) | DEPLOYED → Modified by v2.0 |
| **23-pre** | New views (contract_expiry, vendor_spend) | vw_software_contract_expiry DEPLOYED → DEPRECATED; vw_vendor_spend NOT BUILT → CANCELLED |

### v2.0 Reunification Phases (see `adr-cost-model-reunification.md` §5)

| Phase | Scope | Status |
|-------|-------|--------|
| **Phase 0** | Architecture doc updates (this doc + 8 others) | IN PROGRESS |
| **Phase 1** | Schema: 4 contract columns on it_services, new junction, new view | PENDING |
| **Phase 2** | Views: remove software cost subquery from vw_deployment_profile_costs | PENDING |
| **Phase 3** | Frontend: IT Service contract fields, software product linking, quick calculator | PENDING |
| **Phase 4** | Data migration: dpsp cost data → IT Services | PENDING |
| **Phase 5** | Cleanup: drop deprecated dpsp columns, drop vw_software_contract_expiry | PENDING |

---

## 15. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v3.0 | 2026-04-03 | **Contract-aware Cost Bundles.** §7: contract expiry reporting now uses `vw_contract_expiry` (UNION of IT Services + Cost Bundles), replacing `vw_it_service_contract_expiry`. §9: new `vw_contract_expiry` view documented. Dashboard widget shows Source column. See `adr-contract-aware-cost-bundles.md`. |
| v2.0 | 2026-03-04 | **Cost model reunification.** Contracts move from dpsp junction to IT Services. §1: scope updated. §3: vendor on IT Service (was junction). §4: dpsp is inventory-only — cost/contract columns DEPRECATED. §5: cost override → IT Service allocation. §7: contract expiry → vw_it_service_contract_expiry. §8: allocation via IT Services (was stubbed on junction). §9: views updated. §10: UI simplified. §14: v1.x phases superseded by reunification phases. See `adr-cost-model-reunification.md`. |
| v1.1 | 2026-03-04 | Reconciled with production schema (dump 2026-03-03). §4: deployment status added — updated_at MISSING, chk_dpsp_allocation_percent MISSING, deployed_version column noted. §9: vw_vendor_spend marked NOT BUILT. §14: implementation status column added. |
| v1.0 | 2026-01-22 | Initial version — junction enhancement, SAM-lite scope, cost override logic |

---

*Document: features/cost-budget/software-contract.md*
*March 2026*
