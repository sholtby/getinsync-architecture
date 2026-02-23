# GetInSync — Corrected Technology Stack ERD (CSDM-Aligned)

**Version:** 1.0  
**Date:** February 10, 2026  
**Status:** 🟡 PROPOSED — Requires schema change

---

## 1. The CSDM Source of Truth

ServiceNow CSDM defines these layers:

```
CSDM Layer              ServiceNow Table              GetInSync Entity
─────────────           ────────────────              ────────────────
Business App            cmdb_ci_business_app          Application
App Service Instance    cmdb_ci_service_auto          Deployment Profile
Tech Service Offering   service_offering              IT Service
Product Model           alm_product_model             Software Product / Technology Product
```

The relationship chain in CSDM is:

```
Business App
 └── App Service Instance (DP)
      └── depends_on / built_on → Tech Service Offering (IT Service)
                                    └── contains → Product Model (Technology Product)
```

**Technology Products live INSIDE IT Services. Not on DPs.**

---

## 2. The QuickBooks Translation

What CSDM says → What the user sees:

| CSDM Concept | QuickBooks Plain English |
|-------------|-------------------------|
| cmdb_ci_business_app | "My Application" |
| cmdb_ci_service_auto | "Where it runs" (Deployment) |
| service_offering | "What services support it" |
| alm_product_model (software) | "What software is installed" |
| alm_product_model (infra) | "What technology powers the service" |

The user never sees "Technical Service Offering" or "alm_product_model."
They see: "Database Services runs on SQL Server 2019."

---

## 3. Corrected Entity Relationship Diagram

```
                    ┌─────────────────────────┐
                    │     APPLICATION          │
                    │  (cmdb_ci_business_app)  │
                    │                          │
                    │  Great Plains ERP        │
                    └────────────┬─────────────┘
                                 │
                    owns / deployed as
                                 │
                    ┌────────────▼─────────────┐
                    │   DEPLOYMENT PROFILE      │
                    │  (cmdb_ci_service_auto)   │
                    │                           │
                    │  Region-PROD · Primary    │
                    │  On-Prem · Production     │
                    │  City Hall DC · 🇺🇸        │
                    └──┬────────────────────┬───┘
                       │                    │
              runs on (direct)      consumes (service)
                       │                    │
          ┌────────────▼─────┐   ┌──────────▼──────────────┐
          │ SOFTWARE PRODUCT │   │      IT SERVICE          │
          │ (alm_product_    │   │  (service_offering)      │
          │  model:software) │   │                          │
          │                  │   │  Database Services       │
          │ Microsoft        │   │  $75K · Per Instance     │
          │ Dynamics GP      │   │                          │
          │ v18.6 · $42K     │   │  Financial System Spt    │
          └──────────────────┘   │  $50K · Fixed            │
                                 └──────────┬───────────────┘
                                            │
                                   built with / powered by
                                            │
                                 ┌──────────▼───────────────┐
                                 │   TECHNOLOGY PRODUCT      │
                                 │  (alm_product_model:      │
                                 │   infrastructure)         │
                                 │                           │
                                 │  SQL Server 2019          │
                                 │  Windows Server 2022      │
                                 │  VMware vSphere 8         │
                                 │  NetApp Storage           │
                                 └───────────────────────────┘
```

---

## 4. The Key Relationships

### 4.1 DP → Software Product (DIRECT — exists ✅)

"What software is installed on this deployment?"

- Junction: `deployment_profile_software_products`
- This is a DIRECT link. The software runs ON the DP.
- Cost: licensing cost flows directly to the DP.
- Example: GP v18.6 is installed on the Region-PROD deployment.

### 4.2 DP → IT Service (DIRECT — exists ✅)

"What shared services does this deployment consume?"

- Junction: `deployment_profile_it_services`
- Relationship types: `depends_on` or `built_on`
- Cost: IT Service cost pool allocated to DP via junction.
- Example: Region-PROD depends on Database Services.

### 4.3 IT Service → Technology Product (NEW — missing ❌)

"What technology powers this service?"

- Junction needed: `it_service_technology_products` (DOES NOT EXIST)
- This tells you: Database Services runs SQL Server 2019, Oracle 19c, etc.
- Cost: Technology Product cost rolls INTO the IT Service cost pool.
- Example: Database Services is built with SQL Server 2019.

### 4.4 DP → Technology Product (EXISTS — but WRONG ⚠️)

- Junction: `deployment_profile_technology_products` (EXISTS in schema)
- This BYPASSES the IT Service layer — violates CSDM.
- Decision needed: deprecate or repurpose.

---

## 5. Schema Changes Required

### 5.1 NEW: it_service_technology_products

```sql
CREATE TABLE it_service_technology_products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    it_service_id UUID NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
    technology_product_id UUID NOT NULL REFERENCES technology_products(id) ON DELETE CASCADE,
    deployed_version TEXT,
    relationship_type TEXT DEFAULT 'built_on' 
        CHECK (relationship_type IN ('built_on', 'depends_on', 'includes')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(it_service_id, technology_product_id)
);
```

### 5.2 DEPRECATE: deployment_profile_technology_products

Two options:

**Option A: Drop it** (clean break)
- Delete junction table entirely
- Technology only links through IT Services
- Simpler model, pure CSDM alignment

**Option B: Keep as override** (pragmatic)
- Rename to indicate it's for edge cases
- Use when a DP has a technology NOT covered by an IT Service
- Example: A one-off Oracle instance that isn't managed by any service team
- Add a flag: `is_direct_override BOOLEAN DEFAULT false`

**Recommendation:** Option A (drop it). If a technology isn't managed 
by an IT Service, that's an organizational gap the tool should surface, 
not paper over.

---

## 6. How This Affects the Visual

### Level 1: App Visual (unchanged)
```
Top:    Connected Apps + External Systems
Center: Application
Bottom: Deployment Profiles
```

### Level 2: DP Visual (simplified)
```
Top:    Parent Application
Center: Deployment Profile
Bottom: Software Products + IT Services
        (NO technology products here)
```

### Level 3: IT Service Visual (the blast radius + tech stack)
```
Top:    All DPs that consume this service (blast radius)
Center: IT Service
Bottom: Technology Products that power it + Vendor/Cost info
```

### Level 3 alt: Software Product Visual
```
Top:    All DPs running this product
Center: Software Product
Bottom: Manufacturer + License info
```

---

## 7. The "QuickBooks" User Experience

### What the 18-year-old sees on the DP edit screen:

```
WHAT SOFTWARE IS THIS?
┌─────────────────────────────────────────────┐
│  Microsoft Dynamics GP  v18.6    $42,000    │
│  + Link Software Product                    │
└─────────────────────────────────────────────┘

WHERE DOES IT RUN?
┌─────────────────────────────────────────────┐
│  Environment: Production                    │
│  Hosting: On-Premises                       │
│  Data Center: City Hall DC (🇺🇸 USA)        │
│  DR Status: Backup Only                     │
└─────────────────────────────────────────────┘

WHAT SERVICES SUPPORT THIS?
┌─────────────────────────────────────────────┐
│  Database Services    Built On    $12,000   │
│    └─ Powered by: SQL Server 2019,          │
│       Windows Server 2022                   │
│  Financial Sys Spt    Depends On  $8,000    │
│  + Link IT Service                          │
└─────────────────────────────────────────────┘
```

**The technology products are REVEALED through the IT Service**, not 
linked separately. The user links an IT Service. The service already 
knows what technology it's built on. Zero extra work for the user.

This is the "hide the credits and debits" moment. The user doesn't 
need to know about alm_product_model or cmdb_ci_service_technical.
They just see: "Database Services (powered by SQL Server 2019)."

---

## 8. Data Migration for Riverside Demo

### Current (wrong):
```
DP: Great Plains ERP — Region-PROD
 └── deployment_profile_technology_products
      ├── SQL Server 2019
      └── Windows Server 2022
```

### Corrected:
```
IT Service: Database Services
 └── it_service_technology_products  (NEW junction)
      ├── SQL Server 2019
      └── Windows Server 2022

DP: Great Plains ERP — Region-PROD
 └── deployment_profile_it_services
      └── Database Services (built_on)
          (technology products visible through the service)
```

### Migration steps:
1. Create `it_service_technology_products` table
2. Move SQL Server 2019 link: DP → IT Service "Database Services"
3. Move Windows Server 2022 link: DP → IT Service "Database Services"  
   (or to a new "Server Hosting" IT service if more appropriate)
4. Delete records from `deployment_profile_technology_products`
5. Decision: drop table or keep for edge cases

---

## 9. Impact on IT Service Catalog UI

The IT Service Catalog page (screenshot) already shows services with 
their consumer DPs. It needs ONE addition:

**"TECHNOLOGY" column** — show the technology products that power 
each service. Currently that column exists but is empty because the 
junction doesn't exist yet.

After creating `it_service_technology_products`, the catalog would show:

```
Database Services    $75,000    Operational
  └── Great Plains ERP · via Region-PROD
  └── Hexagon OnCall · via PROD - AWS-US-WEST-2
  └── IA Pro · via PROD - N/A
  TECHNOLOGY: SQL Server 2019, Windows Server 2022
```

---

## 10. CSDM Alignment Summary

| Relationship | CSDM Pattern | GetInSync Junction | Status |
|-------------|-------------|-------------------|--------|
| App → DP | Business App → App Service Instance | applications → deployment_profiles | ✅ Exists |
| DP → Software | App Service → Product Model (software) | deployment_profile_software_products | ✅ Exists |
| DP → IT Service | App Service → Tech Service Offering | deployment_profile_it_services | ✅ Exists |
| IT Service → Tech Product | Tech Service → Product Model (infra) | it_service_technology_products | ❌ MISSING |
| DP → Tech Product | (not in CSDM) | deployment_profile_technology_products | ⚠️ WRONG |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-10 | Initial. Corrected Technology Product placement per CSDM. |
