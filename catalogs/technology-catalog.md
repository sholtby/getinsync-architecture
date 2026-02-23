# catalogs/technology-catalog.md
GetInSync Technology Catalog Architecture
Last updated: 2026-01-16

---

## 1. Purpose

Define the separation of **Software Catalog** (end-user software) from **Technology Catalog** (IT enablers) and how they support the ministry user's understanding of IT Run Rate.

This document introduces:
- **Technology Catalog:** Infrastructure and platform software that powers IT Services
- **Software Catalog:** End-user software that people use directly
- **Technology Stack:** UI component showing what technologies run an application

Goals:
- Clear mental model for non-technical users
- Accurate Run Rate visibility per application
- ServiceNow CSDM alignment (Software Model vs. Technical Service components)

---

## 2. The Mental Model

### What Ministry Users Need to Understand

| Category | Plain English | Examples | Cost Flow |
|----------|---------------|----------|-----------|
| **Applications** | "Systems that run my business" | Payroll, Case Management, Expense Tracker | License + IT Services + Consulting |
| **Software** | "Tools my people use" | Word, Excel, Canva, Chrome | Direct license cost |
| **IT Services** | "Infrastructure that runs my apps" | Database Hosting, Server Hosting | Allocated to applications |

### The Run Rate View

```
Business Application: Sage 300 (Finance)              $57,000/yr
│
├── DP: Sage 300 - PROD                               $45,000/yr
│       ├── License (Contract)            $25,000
│       ├── Database Hosting (IT Service) $12,000
│       └── Server Hosting (IT Service)    $8,000
│
└── DP: Sage 300 Consulting                           $12,000/yr
        └── EstimatedAnnualCost           $12,000

Software: Microsoft 365                               $22,500/yr
├── Contract: M365 E5 License (150 users)

Software: Adobe Creative Cloud                         $7,200/yr
├── Contract: Adobe CC License (12 users)

                                   TOTAL RUN RATE: $86,700/yr
```

---

## 3. Catalog Separation

### 3.1 Software Catalog (End-User Software)

**Purpose:** Track commercial software that people use directly.

**Examples:**
- Microsoft Word, Excel, PowerPoint
- Adobe Creative Cloud
- Canva Pro
- Google Chrome
- Slack

**Cost Flow:**
```
ProductContract → Software Product → DeploymentProfile (direct)
```

**Audience:** Ministry users, license managers

**Location:** Settings > Software Catalog

### 3.2 Technology Catalog (IT Enablers)

**Purpose:** Track infrastructure and platform software that powers IT Services.

**Examples:**
- Microsoft SQL Server 2016, 2019
- Oracle Database 19c
- Windows Server 2019, 2022
- Microsoft Power Apps
- Microsoft SharePoint
- VMware vSphere
- Red Hat Enterprise Linux

**Cost Flow:**
```
ProductContract → Technology Product → Technology Deployment DP → IT Service → Consumer DP
```

**Audience:** Central IT administrators

**Location:** Settings > Technology Catalog

### 3.3 Distinguishing Criteria

| Question | Software Catalog | Technology Catalog |
|----------|------------------|-------------------|
| Does a person use it directly? | ✅ Yes | ❌ No |
| Do applications run ON it? | ❌ No | ✅ Yes |
| Does it power an IT Service? | ❌ No | ✅ Yes |
| Would a ministry "order" it? | ✅ Yes (license request) | ❌ No (request IT Service instead) |

### 3.4 Edge Cases

| Product | Catalog | Rationale |
|---------|---------|-----------|
| Microsoft Outlook | Software | End-user email client |
| Microsoft Exchange | Technology | Email server infrastructure |
| SharePoint (end-user sites) | Software | User-created team sites |
| SharePoint (platform) | Technology | Powers collaboration IT Service |
| Power BI Desktop | Software | End-user analytics tool |
| Power BI Service | Technology | Powers analytics IT Service |

---

## 4. Data Model Changes

### 4.1 New Table: technology_products

```sql
CREATE TABLE technology_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id),
  name TEXT NOT NULL,
  manufacturer_id UUID REFERENCES organizations(id),
  category TEXT NOT NULL,  -- Database, Platform, Operating System, Infrastructure, Security
  version TEXT,
  description TEXT,
  is_internal_only BOOLEAN DEFAULT FALSE,
  is_deprecated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(namespace_id, name, version)
);
```

### 4.2 New Table: technology_product_categories

```sql
CREATE TABLE technology_product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id),
  name TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(namespace_id, name)
);
```

**Seed Data:**
| Name | Description |
|------|-------------|
| Database | Database management systems (SQL Server, Oracle, PostgreSQL) |
| Platform | Application platforms (Power Apps, SharePoint, Salesforce) |
| Operating System | Server and client operating systems |
| Infrastructure | Cloud and virtualization (Azure, AWS, VMware) |
| Security | Security infrastructure (firewalls, IAM, SIEM) |
| Network | Network infrastructure (load balancers, DNS) |
| Storage | Storage systems (SAN, NAS, backup) |

### 4.3 New Junction Table: deployment_profile_technology_products

```sql
CREATE TABLE deployment_profile_technology_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_profile_id UUID NOT NULL REFERENCES deployment_profiles(id) ON DELETE CASCADE,
  technology_product_id UUID NOT NULL REFERENCES technology_products(id),
  deployed_version TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(deployment_profile_id, technology_product_id)
);
```

### 4.4 Updated: it_services.powered_by

The existing `powered_by_deployment_profile_id` now explicitly links to Technology Deployment DPs:

```sql
-- No schema change needed, but enforce via UI:
-- powered_by dropdown shows only DPs where dp_type IN ('software_deployment', 'infrastructure')
-- AND the DP is linked to a technology_product
```

### 4.5 Software Product Categories (Add to existing table)

```sql
ALTER TABLE software_products 
ADD COLUMN IF NOT EXISTS category TEXT;

-- Update existing enum or add reference table
-- Categories: End User, Productivity, Development, Collaboration
```

---

## 5. UI Architecture

### 5.1 Navigation Structure

```
Settings
├── Software Catalog        ← End-user software (MS Word, Canva)
│   └── Filter by Category
├── Technology Catalog      ← IT enablers (MS SQL, Windows Server)  ← NEW
│   └── Filter by Category
├── IT Service Catalog      ← Service offerings
│   └── Shows "Powered By" technology
└── Deployment Profiles     ← All DP types
```

### 5.2 Technology Stack Component (Application View)

Read-only summary derived from IT Service dependencies:

```
┌─────────────────────────────────────────────────────────────────┐
│ TECHNOLOGY STACK                                                │
├─────────────────────────────────────────────────────────────────┤
│ CATEGORY         TECHNOLOGY           VIA SERVICE               │
│ Database         MS SQL 2016          Database Hosting Service  │
│ Operating Sys    Windows Server 2019  Server Hosting Service    │
│ Platform         AWS                  Cloud Hosting Service     │
└─────────────────────────────────────────────────────────────────┘
```

**Derivation Logic:**
```
For each IT Service Dependency on the Application DP:
  → Get IT Service
    → Get powered_by_deployment_profile_id
      → Get linked technology_product via deployment_profile_technology_products
        → Display: category, name, IT Service name
```

### 5.3 Quick-Add Flow

When linking IT Service to Application DP:

```
┌─────────────────────────────────────────────────────────────────┐
│ Link IT Service                                                 │
├─────────────────────────────────────────────────────────────────┤
│ ○ Select existing IT Service                                    │
│   [Dropdown: Database Hosting, Windows Hosting...]              │
│                                                                 │
│ ○ Quick add: "This app uses..."                                 │
│   [Dropdown: MS SQL 2016, Oracle 19c, Windows Server 2019...]   │
│   (System will find or create appropriate IT Service)           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Cost Flow Summary

### 6.1 End-User Software (Direct)

```
ProductContract ($22,500 M365 License)
    │
    └──► Software Product (Microsoft 365)
            │
            └──► DeploymentProfile (M365 - Ministry Bundle)
                    │
                    └──► Ministry Run Rate: $22,500
```

### 6.2 Technology / IT Service (Through IT Service)

```
ProductContract ($50K SQL License)
    │
    └──► Technology Deployment DP (MS SQL - Cluster A)
            │
            └──► IT Service (Database Hosting - $150K total)
                    │
                    ├──► App DP: Sage 300 ($12K allocated)
                    ├──► App DP: Case Mgmt ($18K allocated)
                    └──► Stranded: $70K (Central IT overhead)
```

---

## 7. ServiceNow CSDM Alignment

| GetInSync Entity | ServiceNow CSDM |
|------------------|-----------------|
| Software Product | `alm_product_model` (Software Model) |
| Technology Product | `alm_product_model` (Software Model, classified as infrastructure) |
| Technology Deployment DP | `cmdb_ci_service_auto` (Service Instance) |
| IT Service | `service_offering` (Technology Management Offering) |
| Business Application | `cmdb_ci_business_app` |
| Application DP | `cmdb_ci_service_auto` (Application Service Instance) |

---

## 8. Migration Considerations

### 8.1 Existing Software Products

Review existing `software_products` records and migrate IT enablers to `technology_products`:

| Current software_products | Action |
|---------------------------|--------|
| MS SQL 2016 | Move to technology_products |
| Oracle Database | Move to technology_products |
| Microsoft Power Apps | Move to technology_products |
| Microsoft SharePoint | Move to technology_products |
| MS Word | Keep in software_products |
| Canva | Keep in software_products |

### 8.2 Existing Deployment Profile Links

Update `deployment_profile_software_products` links:
- Links to IT enablers → migrate to `deployment_profile_technology_products`
- Links to end-user software → keep as-is

---

## 9. Open Questions

1. **Hybrid Products:** Some products (SharePoint, Power BI) can be both end-user and infrastructure. Handle via:
   - Duplicate entry in both catalogs, OR
   - Single entry with "usage context" flag

2. **Technology Categories:** Should categories be hardcoded or database-backed (like service_types discussion)?
   - Recommendation: Database-backed for extensibility

---

## 10. Implementation Phases

| Phase | Scope | Priority |
|-------|-------|----------|
| 20a | Create technology_products table, categories, junction | High |
| 20b | Technology Catalog UI (Settings page) | High |
| 20c | Migrate existing IT enablers from software_products | High |
| 20d | Technology Stack component on Application view | High |
| 20e | Quick-add flow for IT Service dependencies | Medium |
| 20f | Software Catalog category filter | Medium |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-16 | Initial version. Software/Technology catalog separation. |

---

*Document: catalogs/technology-catalog.md*
*January 2026*
