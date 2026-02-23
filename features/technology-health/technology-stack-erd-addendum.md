# GetInSync — Technology Stack ERD Addendum (Inventory vs. Cost Separation)

**Version:** 1.1 (Addendum to features/technology-health/technology-stack-erd.md)  
**Date:** February 13, 2026  
**Status:** 🟡 PROPOSED — Supersedes Section 5.2 of v1.0

---

## 1. What Changed and Why

The corrected ERD (v1.0) recommended **dropping** `deployment_profile_technology_products` as a CSDM violation. This addendum reverses that recommendation and reframes the table as the **simple inventory entry point** — the QuickBooks layer that hides CSDM complexity.

### The Problem v1.0 Created

Requiring technology to flow through IT Services before it could be associated with a DP imposed an organizational prerequisite on what should be a simple inventory question. Three common scenarios broke:

1. **Solo app owner cataloging 20 apps.** Knows "this runs on SQL Server" but has no concept of an IT Service. Shouldn't need to create one to record a technology fact.
2. **SaaS-only applications.** No infrastructure, no IT Service — just software. The IT Service layer is meaningless here.
3. **Lifecycle dashboard consumers.** Want to know "how many apps run EOL technology?" Don't need cost allocation or blast radius — just a flat count.

### The Reframe

| v1.0 Position | v1.1 Position |
|---|---|
| `deployment_profile_technology_products` is WRONG — violates CSDM | `deployment_profile_technology_products` is the SIMPLE ENTRY POINT — inventory only |
| Drop the table | Keep the table, ensure it has NO cost columns |
| Technology only links through IT Services | Technology links directly for inventory; IT Services add cost and blast radius |
| IT Service is prerequisite | IT Service is maturity layer |

---

## 2. The Two-Path Model

Technology products relate to deployment profiles through **two parallel paths** serving different purposes:

```
PATH 1: INVENTORY (Simple — all tiers)
─────────────────────────────────────────
DP ──── deployment_profile_technology_products ──── Technology Product
        (deployed_version, notes)
        NO COST COLUMNS

Purpose: "What technology does this deployment run on?"
Feeds:   Lifecycle dashboard, EOL alerts, tech health reports, slicer views
User:    18-year-old tags SQL Server on a DP. Done.


PATH 2: COST & BLAST RADIUS (Structured — Enterprise tier)
──────────────────────────────────────────────────────────────
DP ──── deployment_profile_it_services ──── IT Service ──── it_service_technology_products ──── Technology Product
        (allocation_value, cost)             (annual_cost pool)   (relationship_type)

Purpose: "What shared service provides this capability, what does it cost, and who else depends on it?"
Feeds:   Cost allocation, stranded cost, blast radius analysis, chargeback
User:    Central IT creates services, links technology, allocates costs.
```

### Key Design Rule

**Path 1 has NO cost columns.** This is non-negotiable. If `deployment_profile_technology_products` carried cost, it would become a shadow fourth cost channel, violating the three-channel model (Software Product, IT Service, Cost Bundle). Technology tagging is inventory. Cost flows through proper channels.

---

## 3. Schema: deployment_profile_technology_products (RETAINED)

```sql
-- RETAINED from original schema — reframed as inventory entry point
-- CRITICAL: No cost columns. This is a tagging/inventory table only.
CREATE TABLE deployment_profile_technology_products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    deployment_profile_id UUID NOT NULL REFERENCES deployment_profiles(id) ON DELETE CASCADE,
    technology_product_id UUID NOT NULL REFERENCES technology_products(id) ON DELETE CASCADE,
    deployed_version TEXT,          -- actual version running (may differ from catalog)
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(deployment_profile_id, technology_product_id)
);

-- RLS, audit trigger, grants per standard checklist
```

**Explicitly excluded columns:** `annual_cost`, `allocation_value`, `allocation_basis`, `allocation_percent` — these belong on cost channel junctions only.

---

## 4. Schema: it_service_technology_products (NEW — unchanged from v1.0)

```sql
-- NEW junction — links technology to the IT Service that manages it
CREATE TABLE it_service_technology_products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    it_service_id UUID NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
    technology_product_id UUID NOT NULL REFERENCES technology_products(id) ON DELETE CASCADE,
    deployed_version TEXT,
    relationship_type TEXT DEFAULT 'built_on' 
        CHECK (relationship_type IN ('built_on', 'depends_on', 'includes')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(it_service_id, technology_product_id)
);
```

---

## 5. Progressive Maturity Model

| Maturity | What the user does | CSDM alignment | Cost tracking |
|---|---|---|---|
| **Level 1: Inventory** | Tags technology directly on DPs | Flat | None (or Cost Bundle estimate) |
| **Level 2: Managed Services** | Creates IT Services, links technology to services | Partial | IT Service cost pool exists |
| **Level 3: Attributed** | Links DPs to IT Services | Full CSDM | Cost allocated from pool to DPs |
| **Level 4: Reconciled** | System surfaces DPs with direct tags but no service link | Full CSDM + clean | All costs flow through channels |

### Reconciliation View (Level 3→4 bridge)

The system can detect the gap between Path 1 and Path 2:

```sql
-- Find technology products tagged directly on DPs but NOT covered by an IT Service
SELECT 
    tp.name AS technology,
    tp.version,
    COUNT(DISTINCT dptp.deployment_profile_id) AS direct_tagged_dps,
    COUNT(DISTINCT dpis_covered.deployment_profile_id) AS service_covered_dps
FROM deployment_profile_technology_products dptp
JOIN technology_products tp ON tp.id = dptp.technology_product_id
-- Check if a covering IT Service exists for this DP + technology combo
LEFT JOIN LATERAL (
    SELECT dpis.deployment_profile_id
    FROM deployment_profile_it_services dpis
    JOIN it_service_technology_products istp ON istp.it_service_id = dpis.it_service_id
    WHERE dpis.deployment_profile_id = dptp.deployment_profile_id
      AND istp.technology_product_id = dptp.technology_product_id
) dpis_covered ON true
GROUP BY tp.name, tp.version
HAVING COUNT(DISTINCT dptp.deployment_profile_id) > COUNT(DISTINCT dpis_covered.deployment_profile_id);
```

This query powers the reconciliation nudge: _"8 DPs have SQL Server tagged directly but aren't linked to an IT Service yet."_

---

## 6. CSDM Alignment Summary (Updated)

| Relationship | CSDM Pattern | GetInSync Junction | Purpose | Status |
|---|---|---|---|---|
| App → DP | Business App → App Service Instance | `applications → deployment_profiles` | Identity | ✅ Exists |
| DP → Software | App Service → Product Model (software) | `deployment_profile_software_products` | Licensing cost | ✅ Exists |
| DP → IT Service | App Service → Tech Service Offering | `deployment_profile_it_services` | Infrastructure cost | ✅ Exists |
| IT Service → Tech Product | Tech Service → Product Model (infra) | `it_service_technology_products` | Service composition | 🟡 NEW |
| DP → Tech Product (direct) | _(not in CSDM)_ | `deployment_profile_technology_products` | **Inventory/lifecycle** | ✅ RETAINED |

The direct DP → Technology Product link is acknowledged as outside CSDM's relational model. It exists as the **onramp to CSDM maturity**, not a replacement for it. The reconciliation view shows users the path from flat inventory to full CSDM alignment.

---

## 7. Impact on Visual Diagram Architecture

No changes to the three-level walkable visual. Technology products tagged directly on a DP appear in the **Level 2 (DP Visual) bottom tier** alongside IT Services:

```
Level 2: DP Visual
──────────────────
Top:    Parent Application
Center: Deployment Profile
Bottom: Software Products (blue)
        IT Services (purple)
        Technology Products (amber) ← direct tags shown here
```

Technology products that also appear through an IT Service show a "managed" badge. Unmanaged technology products show a subtle indicator suggesting the user link them to a service.

---

## 8. References

| Document | Update Required |
|---|---|
| `features/technology-health/technology-stack-erd.md` | Section 5.2 superseded by this addendum |
| `features/cost-budget/cost-model.md` | No change — see companion addendum confirming no impact |
| `catalogs/technology-catalog.md` | No change — catalog structure unchanged |
| `core/visual-diagram.md` | Minor — add amber technology nodes to Level 2 |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.1 | 2026-02-13 | Addendum: Retain `deployment_profile_technology_products` as inventory entry point. Two-path model. Reconciliation view. Progressive maturity. |
