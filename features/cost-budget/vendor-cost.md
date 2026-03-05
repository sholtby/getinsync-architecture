# features/cost-budget/vendor-cost.md
Vendor Attribution & Run Rate Architecture
Last updated: 2026-03-04
Version: 2.0

---

## 1. Purpose

> **"Every dollar needs a home and an owner."**

This document defines the architecture for tracking vendor relationships and costs across the two cost channels in GetInSync NextGen. It ensures complete vendor attribution for run rate reporting and budget analysis.

> **v2.0 Change:** Software Products are now inventory-only — no cost channel. Vendor attribution operates on two cost channels: IT Services and Cost Bundles. See `adr-cost-model-reunification.md`.

**Core Principle:** No orphaned spend. Every dollar flows through a defined channel, is attributed to a vendor, and rolls up to a business application.

**Scope:**
- Vendor attribution on two cost channels (IT Service, Cost Bundle)
- Run rate definition (operational vs. project costs)
- SAM-lite contract fields (on IT Services)
- Unified run rate views

**Audience:** Internal architects, developers, and implementers.

---

## 2. The Two Cost Channels

> **v2.0 Change:** Software Products are inventory-only (no cost). Two cost channels remain.

GetInSync has two channels through which costs flow to applications:

| Channel | Source Table | Cost Field | Use For |
|---------|--------------|------------|---------|
| **IT Services** | `deployment_profile_it_services` | `allocation_value` | Infrastructure AND software licensing (via IT Service cost pool) |
| **Cost Bundles** | `deployment_profiles` (dp_type='cost_bundle') | `annual_cost` | Everything else |

**Software Products** are inventory-only — they record what software is deployed but carry no cost. Software licensing costs flow through IT Services (e.g., an IT Service "Microsoft 365 E5 Enterprise Agreement" holds the contract total and allocates to DPs).

**Vendor attribution:** Both cost channels have vendor attribution via `vendor_org_id` on their respective tables (`it_services` and `deployment_profiles`), enabling complete "Who are we paying?" analysis.

---

## 3. Key Distinction: Manufacturer vs. Vendor

| Role | Question | Example | Stability |
|------|----------|---------|-----------|
| **Manufacturer** | Who makes the software? | Microsoft, Adobe, SAP | Fixed per product |
| **Vendor/Reseller** | Who sells it to you? Who has your contract? | CDW, SHI, Insight, Microsoft Direct | Varies by deployment |

> **"Microsoft makes it. CDW sells it. Those are different questions with different answers."**

### Why This Matters

1. **Same product, different pricing:** Ministry A pays list price direct; Ministry B has volume discount via CDW
2. **Contract consolidation:** "We have 12 Microsoft products through 4 different resellers"
3. **Vendor management:** "Which vendors have contracts expiring?" requires knowing WHO you're paying
4. **Cost analysis:** "How much are we spending with CDW across all products?"

---

## 4. Architectural Decision: Vendor on Cost Channel, Not Application

### Decision

**DO NOT add `vendor_organization_id` to the `applications` table.**

Vendor relationship is captured at the cost channel level:
- IT Services → `it_services.vendor_org_id`
- Cost Bundles → `deployment_profiles.vendor_org_id`

> **v2.0 Note:** The Software Products junction (`dpsp.vendor_org_id`) is DEPRECATED. Vendor attribution for software costs is via the IT Service that funds the software.

### Rationale

| Approach | Problem |
|----------|---------|
| Vendor on Application | Conflates software maker, reseller, and support provider |
| Vendor on Application | Creates redundancy with cost channel paths |
| Vendor on Application | One app can have costs from multiple vendors |
| **Vendor on Cost Channel** | Captures the actual purchase relationship |
| **Vendor on Cost Channel** | Same product/service can have different vendors per deployment |
| **Vendor on Cost Channel** | Enables accurate vendor spend analysis |

---

## 5. Run Rate Definition

### What Is Run Rate?

**Run Rate** = The annual cost to operate your application portfolio.

| Included in Run Rate | Excluded from Run Rate |
|---------------------|------------------------|
| Software licenses (recurring) | Migration projects (one-time) |
| SaaS subscriptions (recurring) | Implementation consulting (one-time) |
| IT Service allocations (recurring) | Hardware purchases (one-time) |
| MSP support contracts (recurring) | One-time upgrades |
| Maintenance agreements (recurring) | Capital expenditures |

### Two Dimensions

**Dimension 1: Application Operational Status**

| Status | Meaning | Costs Are... |
|--------|---------|--------------|
| `operational` | Running in production | **Current Run Rate** |
| `pipeline` | Planned, not yet deployed | **Projected Run Rate** |
| `retired` | Decommissioned | Should be $0 (historical) |

**Dimension 2: Cost Recurrence (Cost Bundles only)**

| Recurrence | Meaning | Included in Run Rate? |
|------------|---------|----------------------|
| `recurring` | Ongoing operational cost | ✅ Yes |
| `one_time` | Project/implementation/capital | ❌ No |

### The Matrix

| App Status | Cost Type | Category |
|------------|-----------|----------|
| operational | Software/IT Service | **Current Run Rate** |
| operational | Cost Bundle (recurring) | **Current Run Rate** |
| operational | Cost Bundle (one_time) | Current Project |
| pipeline | Software/IT Service | **Projected Run Rate** |
| pipeline | Cost Bundle (recurring) | **Projected Run Rate** |
| pipeline | Cost Bundle (one_time) | Implementation Cost |
| retired | Any | Historical / Should be $0 |

---

## 6. Schema Changes

### 6.1 Software Products Junction — DEPRECATED COST COLUMNS

> **v2.0 Change:** All cost/vendor/contract columns on the `deployment_profile_software_products` junction are DEPRECATED. The junction is now inventory-only. Vendor attribution for software costs flows through IT Services.

**Retained (inventory):** `software_product_id`, `deployed_version`, `quantity`, `notes`

**DEPRECATED (pending drop in Phase 5):**
- `vendor_org_id` — vendor attribution is on IT Service
- `annual_cost` — cost is via IT Service allocation
- `allocation_percent`, `allocation_basis` — allocation is on `dpis`
- `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days` — contract lifecycle is on IT Service
- `cost_confidence` — data quality tracking is on IT Service

See `software-contract.md` §4 for the full deprecation list and `adr-cost-model-reunification.md` §4.5 for the migration plan.

### 6.2 IT Services (Vendor Attribution)

```sql
-- ============================================
-- CHANNEL 2: IT SERVICES
-- ============================================

-- Vendor Organization FK (external provider)
ALTER TABLE it_services
ADD COLUMN vendor_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

-- Index
CREATE INDEX idx_it_services_vendor ON it_services(vendor_org_id);

-- Comment
COMMENT ON COLUMN it_services.vendor_org_id IS 
'External vendor providing this service (e.g., Microsoft for Azure hosting). NULL for purely internal services.';
```

**Example Usage:**

| IT Service | Vendor | Meaning |
|------------|--------|---------|
| Azure SQL Hosting | Microsoft | External cloud provider |
| AWS EC2 Compute | Amazon | External cloud provider |
| Internal Help Desk | NULL | Purely internal service |
| Managed Firewall | Palo Alto | External security vendor |

### 6.3 Cost Bundles (Vendor + Recurrence)

```sql
-- ============================================
-- CHANNEL 3: COST BUNDLES
-- ============================================

-- Vendor Organization FK
ALTER TABLE deployment_profiles
ADD COLUMN vendor_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

-- Cost Recurrence (run rate vs. one-time)
ALTER TABLE deployment_profiles
ADD COLUMN cost_recurrence TEXT DEFAULT 'recurring';

-- Constraints
ALTER TABLE deployment_profiles
ADD CONSTRAINT chk_dp_cost_recurrence
CHECK (cost_recurrence IN ('recurring', 'one_time'));

-- Index
CREATE INDEX idx_dp_vendor ON deployment_profiles(vendor_org_id);

-- Comments
COMMENT ON COLUMN deployment_profiles.vendor_org_id IS 
'Vendor for Cost Bundle DPs. Not used for application/infrastructure DPs.';

COMMENT ON COLUMN deployment_profiles.cost_recurrence IS 
'For Cost Bundle DPs: recurring = run rate, one_time = project/capital.';
```

**Example Usage:**

| Cost Bundle | Vendor | Recurrence | Run Rate? |
|-------------|--------|------------|-----------|
| Acme MSP Annual Support | Acme Consulting | recurring | ✅ Yes |
| Cloud Migration Project | Deloitte | one_time | ❌ No |
| Annual Maintenance Agreement | Vendor X | recurring | ✅ Yes |
| Hardware Refresh 2026 | Dell | one_time | ❌ No |

---

## 7. Cost Logic (v2.0)

### Principle

**IT Service is the cost pool. Software Products are inventory only.**

### IT Services (includes software licensing)

```sql
Effective_Cost = allocation_value  -- The recovered amount from the IT Service pool
```

### Cost Bundles

```sql
Effective_Cost = deployment_profiles.annual_cost
WHERE cost_recurrence = 'recurring'  -- For run rate only
```

### DEPRECATED: Software Product Cost Override

The junction-level cost override formula (`COALESCE(junction.annual_cost, sp.annual_cost)`) is DEPRECATED. Software costs flow through IT Service allocations.

---

## 8. SAM-Lite Scope

### What We Track ✅

| Field | Table | Purpose |
|-------|-------|---------|
| vendor_org_id | IT Services / Cost Bundle DPs | Who you pay |
| annual_cost | IT Services / Cost Bundle DPs | What you pay (total pool or bundle amount) |
| contract_reference | IT Services | PO#, Contract# |
| contract_end_date | IT Services | Expiration |
| renewal_notice_days | IT Services | Alert threshold |
| quantity | dpsp (inventory) | How many seats (reference only) |
| cost_recurrence | Cost Bundle DPs | Run rate vs. project |

### What We Do NOT Track ❌

| Feature | Why Avoid |
|---------|-----------|
| License entitlements | Requires discovery tools |
| Usage/consumption data | Needs identity integration |
| True-up calculations | Legal complexity |
| Compliance status | Liability concerns |
| Contract terms & conditions | Document management scope |
| Renewal workflows | Workflow engine scope |
| Approval chains | Procurement system territory |

> GetInSync answers: "What do we have, who do we pay, how much, and when does it expire?"
>
> GetInSync does NOT answer: "Are we compliant with our license terms?"

---

## 9. Views

### 9.1 vw_deployment_profile_costs (Updated)

Update existing view to use cost override logic:

```sql
CREATE OR REPLACE VIEW vw_deployment_profile_costs AS
SELECT 
  dp.id AS deployment_profile_id,
  dp.name AS deployment_profile_name,
  dp.application_id,
  a.name AS application_name,
  a.workspace_id,
  a.operational_status,
  
  -- Software costs (with override and allocation)
  COALESCE(sw.software_cost, 0) AS software_cost,
  
  -- IT Service costs
  COALESCE(its.service_cost, 0) AS service_cost,
  
  -- Cost Bundle costs (recurring only, from primary DP)
  COALESCE(cb.bundle_cost, 0) AS bundle_cost,
  
  -- Total
  COALESCE(sw.software_cost, 0) + 
  COALESCE(its.service_cost, 0) + 
  COALESCE(cb.bundle_cost, 0) AS total_cost

FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id

-- Software Products (with override)
LEFT JOIN (
  SELECT 
    dps.deployment_profile_id,
    SUM(
      COALESCE(dps.annual_cost, sp.annual_cost, 0) 
      * COALESCE(dps.allocation_percent, 100) / 100
    ) AS software_cost
  FROM deployment_profile_software_products dps
  JOIN software_products sp ON sp.id = dps.software_product_id
  GROUP BY dps.deployment_profile_id
) sw ON sw.deployment_profile_id = dp.id

-- IT Services
LEFT JOIN (
  SELECT 
    deployment_profile_id,
    SUM(COALESCE(allocation_value, 0)) AS service_cost
  FROM deployment_profile_it_services
  GROUP BY deployment_profile_id
) its ON its.deployment_profile_id = dp.id

-- Cost Bundles (recurring only, attributed to primary DP)
LEFT JOIN (
  SELECT 
    primary_dp.id AS deployment_profile_id,
    SUM(bundle_dp.annual_cost) AS bundle_cost
  FROM deployment_profiles primary_dp
  JOIN deployment_profiles bundle_dp 
    ON bundle_dp.application_id = primary_dp.application_id
    AND bundle_dp.dp_type = 'cost_bundle'
    AND bundle_dp.cost_recurrence = 'recurring'
  WHERE primary_dp.is_primary = true
    AND primary_dp.dp_type = 'application'
  GROUP BY primary_dp.id
) cb ON cb.deployment_profile_id = dp.id

WHERE dp.dp_type = 'application';
```

### 9.2 vw_application_run_rate

```sql
CREATE OR REPLACE VIEW vw_application_run_rate AS
SELECT 
  a.id AS application_id,
  a.name AS application_name,
  a.workspace_id,
  w.name AS workspace_name,
  a.operational_status,
  
  -- By channel
  COALESCE(costs.software_cost, 0) AS software_run_rate,
  COALESCE(costs.service_cost, 0) AS it_service_run_rate,
  COALESCE(costs.bundle_cost, 0) AS other_run_rate,
  
  -- Total
  COALESCE(costs.software_cost, 0) + 
  COALESCE(costs.service_cost, 0) + 
  COALESCE(costs.bundle_cost, 0) AS total_run_rate

FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN (
  SELECT 
    application_id,
    SUM(software_cost) AS software_cost,
    SUM(service_cost) AS service_cost,
    SUM(bundle_cost) AS bundle_cost
  FROM vw_deployment_profile_costs
  GROUP BY application_id
) costs ON costs.application_id = a.id

WHERE a.operational_status IN ('operational', 'pipeline');
```

### 9.3 vw_run_rate_by_vendor (v2.0 — Two UNION Legs)

> **v2.0 Change:** The Software Product UNION leg has been removed. Software costs now flow through the IT Service channel. Bugs C.1 (software channel) and C.2 (IT Service channel) documented in v1.1 are resolved by the reunification — C.1 is moot (software leg removed), C.2 was already fixed in R.2.

**Spec SQL (v2.0):**

```sql
CREATE OR REPLACE VIEW vw_run_rate_by_vendor AS

-- IT Service spend by vendor (includes software licensing costs)
SELECT
  'IT Service' AS cost_type,
  COALESCE(v.name, '(Internal)') AS vendor_name,
  v.id AS vendor_id,
  a.workspace_id,
  SUM(
    CASE
      WHEN dpis.allocation_basis = 'fixed' THEN COALESCE(dpis.allocation_value, 0)
      WHEN dpis.allocation_basis = 'percent' AND dpis.allocation_value > 100 THEN COALESCE(dpis.allocation_value, 0)
      WHEN dpis.allocation_basis = 'percent' THEN COALESCE(its.annual_cost * dpis.allocation_value / 100, 0)
      ELSE COALESCE(dpis.allocation_value, 0)
    END
  ) AS annual_spend
FROM deployment_profile_it_services dpis
JOIN it_services its ON its.id = dpis.it_service_id
JOIN deployment_profiles dp ON dp.id = dpis.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
LEFT JOIN organizations v ON v.id = its.vendor_org_id
WHERE dp.dp_type = 'application'
  AND a.operational_status = 'operational'
GROUP BY v.id, v.name, a.workspace_id

UNION ALL

-- Cost Bundle spend by vendor (recurring only)
SELECT
  'Other Recurring',
  COALESCE(v.name, '(Unattributed)'),
  v.id,
  a.workspace_id,
  SUM(dp.annual_cost)
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
LEFT JOIN organizations v ON v.id = dp.vendor_org_id
WHERE dp.dp_type = 'cost_bundle'
  AND dp.cost_recurrence = 'recurring'
  AND a.operational_status = 'operational'
GROUP BY v.id, v.name, a.workspace_id;
```

### 9.4 vw_software_contract_expiry — DEPRECATED

> **v2.0:** This view is DEPRECATED. Replaced by `vw_it_service_contract_expiry` (see `software-contract.md` §9 for the new view definition). Will be dropped in Phase 5 of the reunification migration.

### 9.5 vw_vendor_spend_summary — NOT BUILT

> **Status (2026-03-04):** This view has NOT been created in the database. It depends on `vw_run_rate_by_vendor` which has bugs C.1 and C.2. Build after fixing the parent view.

```sql
CREATE OR REPLACE VIEW vw_vendor_spend_summary AS
SELECT 
  vendor_id,
  vendor_name,
  workspace_id,
  SUM(CASE WHEN cost_type = 'Software' THEN annual_spend ELSE 0 END) AS software_spend,
  SUM(CASE WHEN cost_type = 'IT Service' THEN annual_spend ELSE 0 END) AS it_service_spend,
  SUM(CASE WHEN cost_type = 'Other Recurring' THEN annual_spend ELSE 0 END) AS other_spend,
  SUM(annual_spend) AS total_spend
FROM vw_run_rate_by_vendor
GROUP BY vendor_id, vendor_name, workspace_id;
```

---

## 10. Example Queries

### Current Run Rate by Vendor

```sql
SELECT vendor_name, SUM(annual_spend) AS total_spend
FROM vw_run_rate_by_vendor
WHERE workspace_id = 'your-workspace-id'
GROUP BY vendor_name
ORDER BY total_spend DESC;
```

**Output:**

| Vendor | Total Spend |
|--------|-------------|
| Microsoft | $255,000 |
| CDW | $45,000 |
| Acme MSP | $36,000 |
| (Internal) | $50,000 |

### Contracts Expiring in 90 Days

```sql
SELECT application_name, software_product_name, vendor_name, 
       contract_end_date, effective_annual_cost
FROM vw_software_contract_expiry
WHERE contract_status IN ('renewal_due', 'expiring_soon')
ORDER BY contract_end_date;
```

### Run Rate: Current vs. Projected

```sql
SELECT 
  operational_status,
  COUNT(*) AS app_count,
  SUM(total_run_rate) AS total_run_rate
FROM vw_application_run_rate
GROUP BY operational_status;
```

**Output:**

| Status | Apps | Run Rate |
|--------|------|----------|
| operational | 45 | $1,250,000 |
| pipeline | 8 | $180,000 |

---

## 11. UI Implications

### Software Product Link Dialog

| Field | Always Visible | Notes |
|-------|---------------|-------|
| Software Product | ✅ | Dropdown |
| Vendor | ✅ | Organization picker (is_vendor=true) |
| Annual Cost | ✅ | Optional, placeholder shows catalog price |
| Contract Reference | Collapsible | Text |
| Start/End Date | Collapsible | Date pickers |
| Renewal Notice Days | Collapsible | Default 90 |
| Quantity | Advanced | Reference only |
| Allocation % | Advanced | Stubbed |

### Cost Bundle Edit

| Field | Notes |
|-------|-------|
| Vendor | Organization picker |
| Annual Cost | Required |
| Cost Recurrence | Dropdown: Recurring / One-Time |
| Notes | Free text |

### Dashboard Widgets

| Widget | Content |
|--------|---------|
| Run Rate by Vendor | Top 5 vendors by spend |
| Contracts Expiring | Count by timeframe |
| Run Rate Trend | Current vs. pipeline |

---

## 12. Migration Notes

### Existing Data

No data migration required. All new fields are NULLable or have defaults:
- `vendor_org_id` → NULL
- `cost_recurrence` → 'recurring' (safe default)
- Junction fields → NULL

### Behavioral Changes

| Before | After |
|--------|-------|
| Software cost = catalog price | Junction cost overrides if present |
| IT Services have no vendor | Vendor attribution enabled |
| Cost Bundles have no vendor | Vendor attribution enabled |
| All costs = run rate | Only recurring costs = run rate |

### RLS Impact

New columns inherit existing RLS policies. No policy changes needed.

New views need SELECT grants:
```sql
GRANT SELECT ON vw_deployment_profile_costs TO authenticated;
GRANT SELECT ON vw_application_run_rate TO authenticated;
GRANT SELECT ON vw_run_rate_by_vendor TO authenticated;
GRANT SELECT ON vw_software_contract_expiry TO authenticated;
GRANT SELECT ON vw_vendor_spend_summary TO authenticated;
```

---

## 13. Related Documents

| Document | Relevance |
|----------|-----------|
| features/cost-budget/adr-cost-model-reunification.md | ADR: IT Services absorb the contract role |
| features/cost-budget/cost-model.md | Two cost channels (v3.0) |
| features/cost-budget/budget-management.md | Budget vs. run rate |
| catalogs/it-service.md | IT Service expanded with contract role |
| catalogs/software-product.md | Catalog structure, manufacturer (inventory only) |
| core/involved-party.md | Organization entity, is_vendor flag |

---

## 14. Implementation Phases

| Phase | Scope | Effort | Status |
|-------|-------|--------|--------|
| **24a** | Vendor on all 3 channels (schema) | 2 hrs | DEPLOYED |
| **24b** | Cost recurrence on deployment_profiles | 30 min | DEPLOYED |
| **24c** | vw_deployment_profile_costs update | 1 hr | DEPLOYED |
| **24d** | vw_application_run_rate | 30 min | DEPLOYED |
| **24e** | vw_run_rate_by_vendor | 30 min | DEPLOYED (bugs C.1, C.2 — see §9.3) |
| **24f** | vw_software_contract_expiry | 30 min | DEPLOYED |
| **24g** | SAM-lite fields on junction | 1 hr | DEPLOYED (missing updated_at, constraint) |
| **UI** | Software link dialog enhancement | 3 hrs | DEPLOYED |
| **UI** | Cost bundle vendor/recurrence | 1 hr | DEPLOYED |
| **UI** | Vendor spend report | 2 hrs | NOT STARTED |
| **UI** | Contract expiry report | 2 hrs | NOT STARTED |

**Total:** ~14 hours (~10 hrs deployed, ~4 hrs remaining)

---

## 15. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.0 | 2026-03-04 | **Cost model reunification.** §2: three channels → two (Software Products now inventory-only). §4: vendor on IT Service (dpsp vendor DEPRECATED). §6.1: dpsp cost/vendor columns marked DEPRECATED. §7: software cost override DEPRECATED. §8: SAM-lite fields now on IT Services. §9.3: Software UNION leg removed from vw_run_rate_by_vendor. §9.4: vw_software_contract_expiry marked DEPRECATED. See `adr-cost-model-reunification.md`. |
| v1.1 | 2026-03-04 | Reconciled with production schema (dump 2026-03-03). §9.3: BUG callout for vw_run_rate_by_vendor. §9.5: vw_vendor_spend_summary marked NOT BUILT. §14: implementation status column added. |
| v1.0 | 2026-01-22 | Initial version — vendor attribution on all 3 cost channels, run rate definition, unified views |

---

*Document: features/cost-budget/vendor-cost.md*
*March 2026*
