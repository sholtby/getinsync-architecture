# features/cost-budget/software-contract.md
Software Product Contracts & Vendor Management
Last updated: 2026-01-22

---

## 1. Purpose

This document defines the architecture for tracking software vendors, contracts, and procurement costs in GetInSync NextGen.

**Key Insight:** Organizations care about "who's ripping me off?" — the vendor/reseller relationship — not just who manufactures the software.

**Scope:**
- Manufacturer vs. Vendor distinction
- Enhanced junction table for deployment-level cost tracking
- SAM-lite contract fields (expiry, reference, vendor)
- Cost override logic
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

## 3. Architectural Decision: Vendor on Junction, Not Application

### Decision

**DO NOT add `vendor_organization_id` to the `applications` table.**

Vendor relationship is captured on `deployment_profile_software_products` junction table instead.

### Rationale

| Approach | Problem |
|----------|---------|
| Vendor on Application | Conflates software maker, reseller, and support provider |
| Vendor on Application | Creates redundancy with Software Catalog path |
| Vendor on Application | One app can have multiple software products from different vendors |
| **Vendor on Junction** | Captures the actual purchase relationship |
| **Vendor on Junction** | Same product can have different vendors per deployment |
| **Vendor on Junction** | Enables vendor spend analysis |

### Data Model

```
software_products (Catalog)
├── manufacturer_org_id → Organization (Microsoft)
└── annual_cost (list/reference price)

deployment_profile_software_products (Junction - Enhanced)
├── software_product_id → Software Product
├── vendor_org_id → Organization (CDW)      ← Who you PAY
├── annual_cost → What YOU pay              ← Overrides catalog
└── contract_end_date                       ← When it expires
```

### Path Summary

| Question | Path |
|----------|------|
| Who makes it? | DP → Junction → Software Product → `manufacturer_org_id` → Organization |
| Who do we pay? | DP → Junction → `vendor_org_id` → Organization |
| What's the list price? | Software Product → `annual_cost` |
| What do we actually pay? | Junction → `annual_cost` (if set) OR Software Product → `annual_cost` |

---

## 4. Schema: deployment_profile_software_products (Enhanced)

### Current Schema

```sql
CREATE TABLE deployment_profile_software_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_profile_id UUID REFERENCES deployment_profiles(id) ON DELETE CASCADE,
  software_product_id UUID REFERENCES software_products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(deployment_profile_id, software_product_id)
);
```

### Enhanced Schema

```sql
-- ============================================
-- ENHANCED JUNCTION: VENDOR & CONTRACT FIELDS
-- ============================================

-- Vendor Organization FK
ALTER TABLE deployment_profile_software_products
ADD COLUMN vendor_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

-- Cost Override (what you actually pay)
ALTER TABLE deployment_profile_software_products
ADD COLUMN annual_cost DECIMAL(12,2);

-- Quantity (reference only, no automatic math)
ALTER TABLE deployment_profile_software_products
ADD COLUMN quantity INTEGER;

-- Allocation (stubbed for future use)
ALTER TABLE deployment_profile_software_products
ADD COLUMN allocation_percent DECIMAL(5,2);

ALTER TABLE deployment_profile_software_products
ADD COLUMN allocation_basis TEXT;

-- Contract Reference Fields (SAM-lite)
ALTER TABLE deployment_profile_software_products
ADD COLUMN contract_reference TEXT;

ALTER TABLE deployment_profile_software_products
ADD COLUMN contract_start_date DATE;

ALTER TABLE deployment_profile_software_products
ADD COLUMN contract_end_date DATE;

ALTER TABLE deployment_profile_software_products
ADD COLUMN renewal_notice_days INTEGER DEFAULT 90;

-- Data Quality
ALTER TABLE deployment_profile_software_products
ADD COLUMN cost_confidence TEXT DEFAULT 'estimated';

ALTER TABLE deployment_profile_software_products
ADD COLUMN notes TEXT;

-- Constraints
ALTER TABLE deployment_profile_software_products
ADD CONSTRAINT chk_dpsp_cost_confidence
CHECK (cost_confidence IN ('estimated', 'verified'));

ALTER TABLE deployment_profile_software_products
ADD CONSTRAINT chk_dpsp_allocation_percent
CHECK (allocation_percent IS NULL OR (allocation_percent >= 0 AND allocation_percent <= 100));

-- Indexes
CREATE INDEX idx_dpsp_vendor ON deployment_profile_software_products(vendor_org_id);
CREATE INDEX idx_dpsp_contract_end ON deployment_profile_software_products(contract_end_date);

-- Comments
COMMENT ON COLUMN deployment_profile_software_products.vendor_org_id IS 
'The vendor/reseller you purchase from. Different from manufacturer on software_products.';

COMMENT ON COLUMN deployment_profile_software_products.annual_cost IS 
'Actual annual cost for this deployment. Overrides software_products.annual_cost if set.';

COMMENT ON COLUMN deployment_profile_software_products.quantity IS 
'Number of licenses/seats. Reference only - not used in cost calculations.';

COMMENT ON COLUMN deployment_profile_software_products.allocation_percent IS 
'Stubbed: Percentage of total cost allocated to this DP. NULL = 100%.';

COMMENT ON COLUMN deployment_profile_software_products.contract_end_date IS 
'Contract/agreement expiration date. Used for renewal alerts.';

COMMENT ON COLUMN deployment_profile_software_products.renewal_notice_days IS 
'Days before contract_end_date to trigger renewal alert. Default 90.';
```

### Full Column List (After Enhancement)

| Column | Type | Nullable | Default | Purpose |
|--------|------|----------|---------|---------|
| id | UUID | NO | gen_random_uuid() | PK |
| deployment_profile_id | UUID | NO | — | FK to DP |
| software_product_id | UUID | NO | — | FK to catalog |
| vendor_org_id | UUID | YES | NULL | Who you pay |
| annual_cost | DECIMAL(12,2) | YES | NULL | Override catalog price |
| quantity | INTEGER | YES | NULL | Reference (seats/licenses) |
| allocation_percent | DECIMAL(5,2) | YES | NULL | Stubbed: cost split |
| allocation_basis | TEXT | YES | NULL | Stubbed: 'users', 'estimate', etc. |
| contract_reference | TEXT | YES | NULL | PO#, Contract ID, Agreement# |
| contract_start_date | DATE | YES | NULL | Contract effective date |
| contract_end_date | DATE | YES | NULL | Contract expiration |
| renewal_notice_days | INTEGER | YES | 90 | Alert threshold |
| cost_confidence | TEXT | YES | 'estimated' | Data quality flag |
| notes | TEXT | YES | NULL | Free text |
| created_at | TIMESTAMPTZ | YES | now() | Audit |
| updated_at | TIMESTAMPTZ | YES | now() | Audit |

---

## 5. Cost Override Logic

### Principle

**Junction cost wins if present; catalog price is the fallback.**

### Formula

```sql
Effective_Cost = COALESCE(
  junction.annual_cost,           -- What you actually pay (if known)
  software_products.annual_cost   -- List/catalog price (fallback)
)
```

### With Allocation (Future)

```sql
Effective_Cost = COALESCE(
  junction.annual_cost,
  software_products.annual_cost
) * COALESCE(junction.allocation_percent, 100) / 100
```

### Example

| Scenario | Catalog Price | Junction Cost | Allocation % | Effective Cost |
|----------|---------------|---------------|--------------|----------------|
| Simple (catalog only) | $12,000 | NULL | NULL | $12,000 |
| Override (negotiated) | $12,000 | $10,800 | NULL | $10,800 |
| Partial allocation | $12,000 | NULL | 40 | $4,800 |
| Override + allocation | $12,000 | $10,800 | 40 | $4,320 |

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

### Dashboard Widget

**"Software Contracts Expiring Soon"**

| Timeframe | Count |
|-----------|-------|
| Next 30 days | 2 |
| 31-90 days | 5 |
| 91-180 days | 8 |

### Detail Report

```sql
SELECT 
  sp.name AS product,
  o.name AS vendor,
  dps.contract_reference,
  dps.contract_end_date,
  dps.annual_cost,
  dps.contract_end_date - CURRENT_DATE AS days_until_expiry
FROM deployment_profile_software_products dps
JOIN software_products sp ON sp.id = dps.software_product_id
LEFT JOIN organizations o ON o.id = dps.vendor_org_id
WHERE dps.contract_end_date IS NOT NULL
  AND dps.contract_end_date <= CURRENT_DATE + INTERVAL '180 days'
ORDER BY dps.contract_end_date;
```

### Sample Output

| Product | Vendor | Reference | Expires | Annual Cost | Days |
|---------|--------|-----------|---------|-------------|------|
| Adobe Creative Cloud | CDW | PO-2024-1234 | 2026-03-15 | $10,800 | 52 |
| Sage 300 | Meridian | AGR-5678 | 2026-04-01 | $24,000 | 69 |
| Microsoft 365 E3 | Microsoft | EA-9999 | 2026-06-30 | $43,200 | 159 |

### Notification (Future)

When `contract_end_date - renewal_notice_days <= CURRENT_DATE`:
- Flag in UI
- Optional email notification (future)
- Export for procurement team

---

## 8. Allocation Model (Stubbed)

### Current State: Stubbed

Columns exist but are not enforced in calculations or UI.

### Future Behavior

When `allocation_percent` is set:
- UI shows allocation controls
- Cost calculation applies percentage
- Validation: Sum of allocations for same software product should ≤ 100% (warning, not error)

### Use Case

**Shared Microsoft 365 tenant across multiple applications:**

| Application | DP | Software Product | Allocation | Cost |
|-------------|-----|------------------|------------|------|
| HR System | HR-Prod | Microsoft 365 E3 | 40% | $17,280 |
| Finance App | Fin-Prod | Microsoft 365 E3 | 35% | $15,120 |
| CRM | CRM-Prod | Microsoft 365 E3 | 25% | $10,800 |
| **Total** | | | **100%** | **$43,200** |

### Why Stubbed

- Most organizations don't need this level of detail
- Adds complexity to UI
- Can be enabled via tier gating (Enterprise/Full)

---

## 9. View Updates

### vw_deployment_profile_costs (Updated)

The existing view needs modification to use the cost override logic.

**Current Logic:**
```sql
-- Software cost (current)
SELECT SUM(sp.annual_cost) AS software_cost
FROM deployment_profile_software_products dps
JOIN software_products sp ON sp.id = dps.software_product_id
WHERE dps.deployment_profile_id = dp.id
```

**Updated Logic:**
```sql
-- Software cost (with override and allocation)
SELECT SUM(
  COALESCE(dps.annual_cost, sp.annual_cost) 
  * COALESCE(dps.allocation_percent, 100) / 100
) AS software_cost
FROM deployment_profile_software_products dps
JOIN software_products sp ON sp.id = dps.software_product_id
WHERE dps.deployment_profile_id = dp.id
```

### New View: vw_software_contract_expiry

```sql
CREATE OR REPLACE VIEW vw_software_contract_expiry AS
SELECT 
  dps.id,
  dp.id AS deployment_profile_id,
  dp.name AS deployment_profile_name,
  a.id AS application_id,
  a.name AS application_name,
  a.workspace_id,
  sp.id AS software_product_id,
  sp.name AS software_product_name,
  mfr.id AS manufacturer_id,
  mfr.name AS manufacturer_name,
  v.id AS vendor_id,
  v.name AS vendor_name,
  dps.contract_reference,
  dps.contract_start_date,
  dps.contract_end_date,
  dps.renewal_notice_days,
  dps.contract_end_date - CURRENT_DATE AS days_until_expiry,
  CASE 
    WHEN dps.contract_end_date IS NULL THEN 'no_contract'
    WHEN dps.contract_end_date < CURRENT_DATE THEN 'expired'
    WHEN dps.contract_end_date <= CURRENT_DATE + (dps.renewal_notice_days || ' days')::INTERVAL THEN 'renewal_due'
    WHEN dps.contract_end_date <= CURRENT_DATE + INTERVAL '180 days' THEN 'expiring_soon'
    ELSE 'active'
  END AS contract_status,
  COALESCE(dps.annual_cost, sp.annual_cost) AS effective_annual_cost,
  dps.cost_confidence
FROM deployment_profile_software_products dps
JOIN deployment_profiles dp ON dp.id = dps.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
JOIN software_products sp ON sp.id = dps.software_product_id
LEFT JOIN organizations mfr ON mfr.id = sp.manufacturer_org_id
LEFT JOIN organizations v ON v.id = dps.vendor_org_id
WHERE dp.dp_type = 'application';
```

### New View: vw_vendor_spend

```sql
CREATE OR REPLACE VIEW vw_vendor_spend AS
SELECT 
  v.id AS vendor_id,
  v.name AS vendor_name,
  COUNT(DISTINCT dps.id) AS product_count,
  COUNT(DISTINCT dp.application_id) AS application_count,
  SUM(COALESCE(dps.annual_cost, sp.annual_cost)) AS total_annual_spend,
  MIN(dps.contract_end_date) AS earliest_expiry,
  COUNT(CASE WHEN dps.contract_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 1 END) AS contracts_expiring_90_days
FROM deployment_profile_software_products dps
JOIN software_products sp ON sp.id = dps.software_product_id
JOIN deployment_profiles dp ON dp.id = dps.deployment_profile_id
JOIN organizations v ON v.id = dps.vendor_org_id
GROUP BY v.id, v.name;
```

---

## 10. UI Implications

### Software Product Link Dialog (Enhanced)

When linking a Software Product to a Deployment Profile:

**Basic (always visible):**
- Software Product (dropdown)
- Vendor (organization picker, filtered to is_vendor=true)
- Annual Cost (optional, placeholder shows catalog price)
- Notes

**Contract Details (collapsible section):**
- Contract Reference (text)
- Start Date (date picker)
- End Date (date picker)
- Renewal Notice Days (number, default 90)

**Advanced (tier-gated or collapsible):**
- Quantity (number)
- Allocation % (number)
- Allocation Basis (dropdown)
- Cost Confidence (dropdown)

### Application Edit Modal

The existing "Software Products" section needs update:
- Show vendor name alongside product name
- Show effective cost (junction or catalog)
- Visual indicator for contract expiry status

### New Reports/Pages

| Report | Tier | Content |
|--------|------|---------|
| Contract Expiry | Pro+ | List of expiring contracts with filters |
| Vendor Spend | Enterprise+ | Spend by vendor with drill-down |

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
| features/cost-budget/cost-model.md | Three cost channels, view logic |
| catalogs/software-product.md | Catalog structure, manufacturer |
| core/involved-party.md | Organization entity, is_vendor flag |
| catalogs/csdm-application-attributes.md | CSDM alignment (updated to remove vendor from app) |

---

## 14. Implementation Phases

| Phase | Scope | Effort |
|-------|-------|--------|
| **23-pre** | Junction schema enhancement (this doc) | 1 hr |
| **23-pre** | View updates (vw_deployment_profile_costs) | 30 min |
| **23-pre** | New views (contract_expiry, vendor_spend) | 30 min |
| **23a** | CSDM attributes on applications (minus vendor) | 30 min |
| **23b** | CSDM attributes on deployment_profiles | 30 min |
| **UI** | Software link dialog enhancement | 2 hrs |
| **UI** | Contract expiry report | 2 hrs |

---

## 15. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-22 | Initial version — junction enhancement, SAM-lite scope, cost override logic |

---

*Document: features/cost-budget/software-contract.md*
*January 2026*
