# GetInSync — Technology Health Dashboard Architecture

**Version:** 1.0  
**Date:** February 13, 2026  
**Status:** 🟡 PROPOSED  
**Companion to:** features/technology-health/technology-stack-erd-addendum.md, features/technology-health/lifecycle-intelligence.md

---

## 1. Purpose

Define the architecture to replicate (and improve upon) a customer's Power BI "Application Portfolio Management Internal Reports" dashboard. The customer built this from spreadsheet data with 479+ business applications across 25+ ministries, tracking OS/DB/Web technology per server with lifecycle stages.

**Goal:** Native dashboard in GetInSync that replaces this Power BI report with structured data, automatic lifecycle lookups, and CSDM-aligned relationships.

---

## 2. Complete Field Mapping

### 2.1 Application-Level Fields

| Their Field | Our Entity.Field | Status | Notes |
|---|---|---|---|
| Business Application Name | `applications.name` | ✅ Exists | |
| App Number (APP0000496) | `applications.app_id` | ✅ Exists | Auto-generated integer. Format as `APP{zero-padded}` in UI |
| Operational Status | `applications.operational_status` | 🟡 Designed | Values: operational, retired, pipeline. See CSDM attributes doc |
| Application Lifecycle Status | `applications.lifecycle_status` | ✅ Exists | Values: Mainstream, Extended Support, End of Support, Business/Vendor Managed, Incomplete Data |
| Crown Jewel | `applications.is_crown_jewel` | ❌ NEW | Boolean. See §3.1 |
| APM/ALM | `applications.management_classification` | ❌ NEW | Values: apm, alm, other. See §3.2 |
| Stages (Stage-1/2/3) | `applications.csdm_stage` | ❌ NEW | CSDM maturity stage. See §3.3 |
| Ministry | `workspaces.name` | ✅ Exists | Workspace = Ministry |
| Branch | `applications.branch` | ❌ NEW | Sub-division text field. See §3.4 |
| Application Technology | `software_products.name` via junction | ✅ Exists | "Microsoft Dynamics" = linked Software Product |
| Owned By | Contact with role `owner` | ✅ Exists | Via `application_contacts` |
| Supported By | Contact with role `support` | ✅ Exists | Via `application_contacts` |
| Managed By | Contact with role `manager` | ✅ Exists | Via `application_contacts` |
| Support Group | Contact with role `support_group` or team name | 🟡 Partial | See §3.5 |

### 2.2 Server / Deployment Profile Fields

| Their Field | Our Entity.Field | Status | Notes |
|---|---|---|---|
| Server Name (SKGOVW072P) | `deployment_profiles.server_name` | ❌ NEW | Optional hostname reference. See §3.6 |
| Server Operational Status | `deployment_profiles.operational_status` | 🟡 Designed | Values: operational, non_operational |
| Environment | `deployment_profiles.environment` | ✅ Exists | Production, Development, etc. |
| Count of Server | Derived: COUNT of DPs per app | ✅ Computable | |
| Total Business Application Count (per server) | Derived: COUNT of apps sharing a server name | ✅ Computable | Only relevant if server_name is populated |
| Vulnerabilities Count | OUT OF SCOPE | ❌ Skip | CMDB/security scanner territory |

### 2.3 Technology Layer Fields (Per Server/DP)

| Their Field | Our Entity.Field | Status | Notes |
|---|---|---|---|
| Operating System | `technology_products.name` (category='operating_system') | ✅ Designed | Via `deployment_profile_technology_products` |
| OS Class | `technology_products.subcategory` or derived from name | 🟡 Partial | See §3.7 |
| OS Lifecycle Stage | `technology_lifecycle_reference.current_status` | ✅ Designed | Via technology_products.lifecycle_reference_id |
| OS Risk | Derived from lifecycle stage | ✅ Computable | See §4.2 |
| OS Maintenance Type | `technology_lifecycle_reference.maintenance_type` | ❌ NEW | Values: mandatory, regular_low, regular_high. See §3.8 |
| OS Count (instances) | Derived: COUNT of DPs with this OS tagged | ✅ Computable | |
| DB Major Product Version | `technology_products.name` + `.version` (category='database') | ✅ Designed | |
| Database Class | `technology_products.manufacturer` or subcategory | 🟡 Partial | "Oracle Database" = manufacturer+type |
| Database Version | `deployment_profile_technology_products.deployed_version` | ✅ Designed | Version on the junction, may differ from catalog |
| DB Product Edition | `deployment_profile_technology_products.edition` | ❌ NEW | See §3.9 |
| DB Lifecycle Stage | Same as OS pattern | ✅ Designed | |
| DB Risk | Derived | ✅ Computable | |
| DB Maintenance Type | Same as OS pattern | ❌ NEW | |
| Database Count | Derived: COUNT of DPs | ✅ Computable | |
| Web Type and Version | `technology_products.name` + `.version` (category='web_server') | ✅ Designed | |
| Web Lifecycle Stage | Same pattern | ✅ Designed | |

---

## 3. Schema Changes Required

### 3.1 Crown Jewel Flag

```sql
-- On applications table
ALTER TABLE applications 
ADD COLUMN is_crown_jewel BOOLEAN DEFAULT false;

-- Index for filtering
CREATE INDEX idx_applications_crown_jewel ON applications(is_crown_jewel) WHERE is_crown_jewel = true;
```

**Design note:** Their Crown Jewel is a static boolean. We also derive criticality from B-scores (our differentiator). The static flag serves as a quick filter for executives who don't want to understand scoring — it's the "QuickBooks checkbox" that happens to align with CSDM's `business_criticality` field. Users can mark it manually or we can suggest it when criticality scores are high.

### 3.2 Management Classification

```sql
ALTER TABLE applications
ADD COLUMN management_classification TEXT DEFAULT 'apm'
  CHECK (management_classification IN ('apm', 'alm', 'other'));
```

**What it means:** APM = managed through application portfolio management. ALM = managed through application lifecycle management (different tooling/process). This is a classification flag for filtering, not a functional difference in our tool.

### 3.3 CSDM Stage

```sql
ALTER TABLE applications
ADD COLUMN csdm_stage TEXT
  CHECK (csdm_stage IS NULL OR csdm_stage IN ('stage_0', 'stage_1', 'stage_2', 'stage_3', 'stage_4'));
```

**What it means:** CSDM maturity stages indicate how fully the application's data has been populated:
- Stage 0: Identified (name only)
- Stage 1: Cataloged (basic attributes)
- Stage 2: Managed (contacts, costs assigned)
- Stage 3: Optimized (assessments complete, integrations mapped)
- Stage 4: Strategic (value creation, roadmap)

**Auto-computation option:** Could be derived from data completeness rather than manually set. Future enhancement.

### 3.4 Branch Field

```sql
ALTER TABLE applications
ADD COLUMN branch TEXT;
```

**What it means:** Sub-division within a Ministry/Workspace. Examples: "SaskBuilds and Procurement", "Trade and Export Development". This is a free-text field, not a structural entity — creating nested workspaces for branches would be over-engineering for a label that's only used in reporting.

### 3.5 Support Group

Support Group maps to either:
- A contact role_type on `application_contacts` (role_type = 'support_group'), OR
- A team/group name field on the application

**Recommendation:** Add to `application_contacts` as a role, using the existing contact's organization or display_name as the group name. This keeps it in the existing contact model rather than adding another field.

```sql
-- Extend contact role types if needed (check current constraint)
-- role_type values should include: owner, support, manager, support_group, steward
```

No schema change needed if the constraint already allows flexible role types.

### 3.6 Server Name on Deployment Profile

```sql
ALTER TABLE deployment_profiles
ADD COLUMN server_name TEXT;

CREATE INDEX idx_dp_server_name ON deployment_profiles(server_name) WHERE server_name IS NOT NULL;
```

**What it means:** Optional hostname reference (e.g., "SKGOVW072P"). This is a reference label, not a CMDB CI link. For organizations that track individual servers, this enables the "By Server" report. For SaaS apps or cloud deployments, this stays NULL.

**Important:** One DP can represent one server. If an app runs on 3 servers, it has 3 DPs (or we accept that one DP = one environment which may span multiple servers, and server_name is the primary/representative hostname).

**Alternative:** `server_names` as TEXT[] (array) to allow multiple hostnames per DP. Simpler for the common case where one environment runs on multiple servers.

**Recommendation:** Single `server_name` TEXT field. If they need multi-server, create multiple DPs. This aligns with CSDM where each cmdb_ci_service_auto maps to infrastructure CIs individually.

### 3.7 Technology Subcategory / Class

The "OS Class" (AIX Server, Linux Server, Windows Server) and "Database Class" (Oracle Database, SQL Server) map to a grouping level above the specific version.

Our `technology_products` table already has a `category` field tied to `technology_product_categories`. We need a subcategory or "product family" concept:

```sql
ALTER TABLE technology_products
ADD COLUMN product_family TEXT;

-- Examples:
-- category = 'operating_system', product_family = 'Windows Server'
-- category = 'operating_system', product_family = 'Linux Server'  
-- category = 'operating_system', product_family = 'AIX Server'
-- category = 'database', product_family = 'Oracle Database'
-- category = 'database', product_family = 'SQL Server'
-- category = 'web_server', product_family = 'Apache'
-- category = 'web_server', product_family = 'Microsoft IIS'
```

**Alternative:** Derive from manufacturer + category (e.g., Microsoft + database = "SQL Server family"). But explicit is better for reporting grouping.

### 3.8 Maintenance Type on Lifecycle Reference

```sql
ALTER TABLE technology_lifecycle_reference
ADD COLUMN maintenance_type TEXT
  CHECK (maintenance_type IS NULL OR maintenance_type IN ('mandatory', 'regular_high', 'regular_low', 'none'));
```

**What it means:** Organizational policy about how urgently patches must be applied for this technology. This is a customer-specific classification (their "Mandatory" vs "Regular - Low" in the screenshots), not a vendor fact. Could alternatively live on the junction table if it varies per deployment.

**Recommendation:** Put on `technology_lifecycle_reference` as default, allow override on `deployment_profile_technology_products` via a `maintenance_override` column if needed later.

### 3.9 Edition on Technology Junction

```sql
ALTER TABLE deployment_profile_technology_products
ADD COLUMN edition TEXT;

-- Examples: 'Enterprise', 'Standard', 'Express', 'Community'
```

**What it means:** The specific product edition deployed. Oracle Database has Enterprise/Standard/Express. SQL Server has Enterprise/Standard/Developer. This matters for lifecycle (different editions may have different support timelines) and cost (Enterprise vs Standard licensing).

---

## 4. Computed / Derived Fields

### 4.1 App Number Display Format

Their "APP0000496" is our `applications.app_id` (integer) formatted in the UI:

```typescript
function formatAppNumber(appId: number): string {
  return `APP${String(appId).padStart(7, '0')}`;
}
```

No schema change needed — this is a UI formatting concern.

### 4.2 Technology Risk (Derived from Lifecycle Stage)

Their "OS Risk" and "DB Risk" (High/Low) are derived from lifecycle stage:

```sql
CASE
  WHEN tlr.current_status IN ('end_of_life', 'end_of_support') THEN 'high'
  WHEN tlr.current_status = 'extended' 
    AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'high'
  WHEN tlr.current_status = 'extended' THEN 'medium'
  WHEN tlr.current_status = 'mainstream' THEN 'low'
  WHEN tlr.current_status = 'preview' THEN 'low'
  ELSE 'unknown'
END AS technology_risk
```

No schema change — computed in views/queries.

### 4.3 Business Application Count Per Technology

```sql
-- How many apps use each technology version?
SELECT 
  tp.product_family,
  tp.name,
  dptp.deployed_version,
  dptp.edition,
  COUNT(DISTINCT a.id) AS business_application_count,
  COUNT(DISTINCT dp.id) AS deployment_count
FROM deployment_profile_technology_products dptp
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
GROUP BY tp.product_family, tp.name, dptp.deployed_version, dptp.edition;
```

---

## 5. Database Views for Dashboard

### 5.1 Technology Health Summary (replaces their summary dashboard)

```sql
CREATE OR REPLACE VIEW vw_technology_health_summary 
WITH (security_invoker = true) AS
SELECT
  w.namespace_id,
  tp.category AS technology_layer,       -- operating_system, database, web_server
  tp.product_family,                      -- Windows Server, Oracle Database, etc.
  tp.name AS technology_name,
  dptp.deployed_version,
  dptp.edition,
  tlr.current_status AS lifecycle_stage,  -- mainstream, extended, end_of_support, end_of_life
  tlr.mainstream_support_end,
  tlr.extended_support_end,
  tlr.end_of_life_date,
  tlr.maintenance_type,
  -- Risk derivation
  CASE
    WHEN tlr.current_status IN ('end_of_life', 'end_of_support') THEN 'high'
    WHEN tlr.current_status = 'extended' 
      AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'high'
    WHEN tlr.current_status = 'extended' THEN 'medium'
    WHEN tlr.current_status = 'mainstream' THEN 'low'
    ELSE 'unknown'
  END AS technology_risk,
  -- Counts
  COUNT(DISTINCT dp.id) AS deployment_count,
  COUNT(DISTINCT a.id) AS application_count,
  COUNT(DISTINCT w.id) AS workspace_count
FROM deployment_profile_technology_products dptp
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN technology_lifecycle_reference tlr ON tp.lifecycle_reference_id = tlr.id
GROUP BY 
  w.namespace_id, tp.category, tp.product_family, tp.name,
  dptp.deployed_version, dptp.edition,
  tlr.current_status, tlr.mainstream_support_end, 
  tlr.extended_support_end, tlr.end_of_life_date, tlr.maintenance_type;
```

### 5.2 Application Infrastructure Report (replaces their flat report)

```sql
CREATE OR REPLACE VIEW vw_application_infrastructure_report
WITH (security_invoker = true) AS
SELECT
  a.id AS application_id,
  a.app_id,
  a.name AS application_name,
  a.operational_status,
  a.lifecycle_status AS application_lifecycle_status,
  a.is_crown_jewel,
  a.management_classification,
  a.csdm_stage,
  a.branch,
  w.id AS workspace_id,
  w.name AS workspace_name,    -- Ministry
  w.namespace_id,
  dp.id AS deployment_profile_id,
  dp.name AS dp_name,
  dp.environment,
  dp.server_name,
  dp.hosting_type,
  dp.cloud_provider,
  dp.region,
  dc.name AS data_center_name,
  -- OS (first tagged, or NULL)
  os_tp.name AS os_name,
  os_dptp.deployed_version AS os_version,
  os_tlr.current_status AS os_lifecycle_stage,
  -- DB (first tagged, or NULL)
  db_tp.name AS db_name,
  db_dptp.deployed_version AS db_version,
  db_dptp.edition AS db_edition,
  db_tlr.current_status AS db_lifecycle_stage,
  -- Web (first tagged, or NULL)
  web_tp.name AS web_name,
  web_dptp.deployed_version AS web_version,
  web_tlr.current_status AS web_lifecycle_stage,
  -- Contacts
  owner_contact.display_name AS owned_by,
  support_contact.display_name AS supported_by,
  manager_contact.display_name AS managed_by
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
JOIN deployment_profiles dp ON dp.application_id = a.id
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
-- OS technology (lateral join for first match per category)
LEFT JOIN LATERAL (
  SELECT dptp.deployed_version, tp.name, tp.id AS tp_id
  FROM deployment_profile_technology_products dptp
  JOIN technology_products tp ON tp.id = dptp.technology_product_id
  WHERE dptp.deployment_profile_id = dp.id AND tp.category = 'operating_system'
  LIMIT 1
) os_dptp ON true
LEFT JOIN technology_products os_tp ON os_tp.id = os_dptp.tp_id
LEFT JOIN technology_lifecycle_reference os_tlr ON os_tlr.id = os_tp.lifecycle_reference_id
-- DB technology
LEFT JOIN LATERAL (
  SELECT dptp.deployed_version, dptp.edition, tp.name, tp.id AS tp_id
  FROM deployment_profile_technology_products dptp
  JOIN technology_products tp ON tp.id = dptp.technology_product_id
  WHERE dptp.deployment_profile_id = dp.id AND tp.category = 'database'
  LIMIT 1
) db_dptp ON true
LEFT JOIN technology_products db_tp ON db_tp.id = db_dptp.tp_id
LEFT JOIN technology_lifecycle_reference db_tlr ON db_tlr.id = db_tp.lifecycle_reference_id
-- Web technology
LEFT JOIN LATERAL (
  SELECT dptp.deployed_version, tp.name, tp.id AS tp_id
  FROM deployment_profile_technology_products dptp
  JOIN technology_products tp ON tp.id = dptp.technology_product_id
  WHERE dptp.deployment_profile_id = dp.id AND tp.category = 'web_server'
  LIMIT 1
) web_dptp ON true
LEFT JOIN technology_products web_tp ON web_tp.id = web_dptp.tp_id
LEFT JOIN technology_lifecycle_reference web_tlr ON web_tlr.id = web_tp.lifecycle_reference_id
-- Contacts (first of each role)
LEFT JOIN LATERAL (
  SELECT c.display_name FROM application_contacts ac 
  JOIN contacts c ON c.id = ac.contact_id
  WHERE ac.application_id = a.id AND ac.role_type = 'owner'
  LIMIT 1
) owner_contact ON true
LEFT JOIN LATERAL (
  SELECT c.display_name FROM application_contacts ac 
  JOIN contacts c ON c.id = ac.contact_id
  WHERE ac.application_id = a.id AND ac.role_type = 'support'
  LIMIT 1
) support_contact ON true
LEFT JOIN LATERAL (
  SELECT c.display_name FROM application_contacts ac 
  JOIN contacts c ON c.id = ac.contact_id
  WHERE ac.application_id = a.id AND ac.role_type = 'manager'
  LIMIT 1
) manager_contact ON true;
```

### 5.3 Server View (replaces their "By Server" table)

```sql
CREATE OR REPLACE VIEW vw_server_technology_report
WITH (security_invoker = true) AS
SELECT
  dp.server_name,
  dp.operational_status AS server_status,
  dp.environment,
  w.namespace_id,
  w.name AS workspace_name,
  -- Count of apps on this server
  COUNT(DISTINCT a.id) AS business_application_count,
  -- Aggregate technology (first of each category for display)
  -- For a full server view, UI would query deployment_profile_technology_products directly
  string_agg(DISTINCT 
    CASE WHEN tp.category = 'operating_system' THEN tp.name || ' ' || COALESCE(dptp.deployed_version, '') END, 
    ', ') AS operating_systems,
  string_agg(DISTINCT 
    CASE WHEN tp.category = 'database' THEN tp.name || ' ' || COALESCE(dptp.deployed_version, '') END, 
    ', ') AS databases,
  string_agg(DISTINCT 
    CASE WHEN tp.category = 'web_server' THEN tp.name || ' ' || COALESCE(dptp.deployed_version, '') END, 
    ', ') AS web_servers
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp.id
LEFT JOIN technology_products tp ON tp.id = dptp.technology_product_id
WHERE dp.server_name IS NOT NULL
GROUP BY dp.server_name, dp.operational_status, dp.environment, w.namespace_id, w.name;
```

---

## 6. UI Architecture: Technology Health Page

### 6.1 New Top-Level Navigation Item

```
Dashboard | Applications | Portfolios | Integrations | Technology Health | ...
```

**Route:** `/technology-health`
**Scope:** Namespace-wide (crosses workspaces, like their report crosses ministries)

### 6.2 Page Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Technology Health                                     [Export] [Filters]│
│                                                                         │
│ Workspace: [All ▼]  Lifecycle: [All ▼]  Category: [All ▼]              │
│                                                                         │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│ │ Total    │ │ Crown    │ │ EOL      │ │ Extended │ │ Mainstream│      │
│ │ Apps     │ │ Jewels   │ │ ⚠️ 91    │ │ ⚠️ 122   │ │ ✅ 165   │      │
│ │ 488      │ │ 25       │ │ 18.7%    │ │ 25.0%    │ │ 33.8%    │      │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                                                                         │
│ ┌─────────────── By Technology Layer ──────────────────────────────┐    │
│ │                                                                  │    │
│ │   ┌─ Operating Systems ──┐ ┌── Databases ────────┐ ┌── Web ──┐ │    │
│ │   │ 41 versions          │ │ 19 versions          │ │ 33 ver  │ │    │
│ │   │ 746 instances        │ │ 121 instances         │ │ 252 ins │ │    │
│ │   │ ■ EOL: 10 (57 svr)  │ │ ■ EOL: 9 (35 svr)   │ │ ...     │ │    │
│ │   │ ■ Ext: 17 (421 svr) │ │ ■ Ext: 5 (67 svr)   │ │         │ │    │
│ │   │ ■ MS:  8 (218 svr)  │ │ ■ MS:  2 (14 svr)   │ │         │ │    │
│ │   └──────────────────────┘ └──────────────────────┘ └─────────┘ │    │
│ └──────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│ ┌──── Lifecycle Status ────┐                                            │
│ │  [Pie/Donut Chart]       │   By Workspace (Ministry)                  │
│ │  EOL: 91 (18.7%)         │   ┌─────────────────────────────────┐     │
│ │  At Risk: 122 (25.0%)    │   │ Advanced Education         13   │     │
│ │  In Jeopardy: 102 (20.9%)│   │ Agriculture                16   │     │
│ │  Incomplete: 165 (33.8%) │   │ Apprenticeship              6   │     │
│ │                           │   │ ...                              │     │
│ └───────────────────────────┘   └─────────────────────────────────┘     │
│                                                                         │
│ ┌──── Application Infrastructure Detail ───────────────────────────┐    │
│ │ [Filterable table - vw_application_infrastructure_report]        │    │
│ │ App | Status | Crown Jewel | Ministry | OS | OS Stage | DB | ...│    │
│ └──────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Sub-tabs or Toggle Views

| View | Source | Matches Their Report |
|---|---|---|
| **Summary** (default) | Aggregate counts + charts | Their summary dashboard |
| **By Application** | `vw_application_infrastructure_report` | Their "By App to Server(Many)" + "For Ministry by App" |
| **By Technology** | `vw_technology_health_summary` | Their "By OS" + "By DB" tables |
| **By Server** | `vw_server_technology_report` | Their "By Server" table |

### 6.4 Filters (Replaces Their 15 Slicers)

| Our Filter | Replaces Their Slicers | Behavior |
|---|---|---|
| Workspace | Ministry, Branch | Cascading: pick workspace, branch auto-scopes |
| Lifecycle Stage | OS/DB/Web Lifecycle Stage | Filter all views by technology lifecycle |
| Technology Category | OS Class, Database Product, Web Class | Filter to specific technology layer |
| Operational Status | Operational Status | Hide retired by default |
| Crown Jewel | Crown Jewel | Quick filter to critical apps only |

**Key simplification:** Their 15 independent dropdowns become 5 cascading filters because our data is relationally linked. Selecting a workspace automatically scopes all technology, contacts, and applications.

---

## 7. Tier Availability

| Feature | Free | Pro | Enterprise |
|---|---|---|---|
| Technology tagging on DPs | ✅ | ✅ | ✅ |
| Technology Health summary page | ✅ | ✅ | ✅ |
| Lifecycle stage display | ✅ | ✅ | ✅ |
| AI lifecycle auto-populate | ❌ | ✅ | ✅ |
| By Server view | ❌ | ✅ | ✅ |
| Cross-workspace rollup | ❌ | ❌ | ✅ |
| Export to Power BI dataset | ❌ | ❌ | ✅ |

---

## 8. What We Explicitly Skip

| Their Field | Why We Skip It | Alternative |
|---|---|---|
| Vulnerabilities Count | Security scanner territory, not APM | Integration with Qualys/Nessus (future) |
| Server hardware details | CMDB discovery (ServiceNow's job) | Our hosting_type + data_center covers location |
| IP Address | Infrastructure detail below our abstraction | Server name is sufficient reference |
| APM Status / APM Comments | Internal workflow fields | Our assessment_status covers this |

---

## 9. Implementation Sequence

| Step | Scope | Effort | Dependency |
|---|---|---|---|
| **9a** | Schema: Add application fields (crown_jewel, branch, management_classification, csdm_stage) | 1 hour | None |
| **9b** | Schema: Add DP fields (server_name) | 30 min | None |
| **9c** | Schema: Add technology_products fields (product_family) | 30 min | None |
| **9d** | Schema: Add deployment_profile_technology_products fields (edition) | 30 min | None |
| **9e** | Schema: Add technology_lifecycle_reference fields (maintenance_type) | 30 min | None |
| **9f** | Create database views (3 views) | 2 hours | 9a-9e |
| **9g** | RLS policies for new columns and views | 1 hour | 9f |
| **9h** | Seed technology_products catalog (common OS/DB/Web families) | 2 hours | 9c |
| **9i** | UI: Technology Health page (summary + By Application table) | 3-4 days AG | 9f |
| **9j** | UI: By Technology and By Server sub-views | 2 days AG | 9i |
| **9k** | UI: Technology tagging on DP edit screen | 2 days AG | 9c, 9d |
| **Total** | | ~8-9 days | |

**Critical path:** 9a-9f (schema + views, ~5 hours) unblocks all UI work. Technology catalog seeding (9h) can happen in parallel.

---

## 10. Data Import Considerations

For the customer who built this Power BI report, their data import would be:

1. **Applications:** CSV with App Number, Name, Ministry (→workspace), Branch, Lifecycle Status, Operational Status, Crown Jewel, Owned By, Supported By, Managed By
2. **Servers:** CSV with Server Name, Environment, OS, OS Version, DB, DB Version, DB Edition, Web, Web Version → creates DPs with technology tags
3. **Technology Catalog:** Pre-seed with their known OS/DB/Web products and versions, link to lifecycle reference

This is a natural extension of the City of Garland import workflow — similar CSV structure, different columns.

---

## 11. References

| Document | Relationship |
|---|---|
| `features/technology-health/technology-stack-erd-addendum.md` | Two-path model (inventory vs cost) — this dashboard uses Path 1 |
| `features/cost-budget/cost-model-addendum.md` | Confirms no cost impact from technology tagging |
| `features/technology-health/lifecycle-intelligence.md` | AI lifecycle lookup feeds lifecycle_stage |
| `catalogs/technology-catalog.md` | Technology product catalog structure |
| `core/deployment-profile.md` | DP fields, data centers, hosting |
| `catalogs/csdm-application-attributes.md` | Application fields (operational_status, lifecycle_stage_status) |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-02-13 | Initial. Complete field mapping from customer Power BI. Schema changes, views, UI architecture. |
