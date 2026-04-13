# core/deployment-profile.md
Deployment Profile Architecture - Data Residency & Location Tracking
Last updated: 2026-04-13

---

## 1. Overview

This document defines the Deployment Profile entity and its role in tracking WHERE and HOW applications are deployed. Key enhancement in v1.8: proper data residency tracking through namespace-scoped data centers and standard cloud regions.

**Version History:**
- v1.8 (2026-01-31): Add data_centers table, standard_regions table, context-sensitive location tracking
- v1.7: Previous version with static region dropdown
- v1.0-v1.6: Earlier iterations

---

## 2. Core Principle

**Deployment Profile is the assessment anchor, not Application.**

The same application software can be deployed multiple ways with different technical realities:
- Production vs DR vs Test
- Cloud vs On-Premises vs SaaS
- Different regions with different compliance requirements

**Each deployment is assessed separately.**

---

## 3. Schema

### 3.1 deployment_profiles Table

```sql
CREATE TABLE deployment_profiles (
  id uuid PRIMARY KEY,
  application_id uuid NOT NULL REFERENCES applications(id),
  workspace_id uuid NOT NULL REFERENCES workspaces(id),
  name text NOT NULL,
  environment text,
  is_primary boolean DEFAULT false,
  hosting_type text,
  cloud_provider text,
  region text,                    -- For Cloud/SaaS/Third-Party: standard region code
  data_center_id uuid REFERENCES data_centers(id),  -- For On-Prem/Hybrid: org data center
  dp_type text DEFAULT 'application',
  cost_recurrence text,
  annual_cost numeric(12,2),
  -- Assessment scores (T01-T15)
  -- ... other fields
);
```

**Key Fields for Location Tracking:**
- `hosting_type`: WHERE it runs (see §3.1.3)
- `cloud_provider`: WHICH cloud (for Cloud/SaaS)
- `region`: Standard region code (for Cloud/SaaS/Third-Party)
- `data_center_id`: Org-specific data center (for On-Prem/Hybrid)

**Business Rule:** Only ONE location field should be populated:
- If `hosting_type IN ('On-Prem', 'Hybrid')` → Use `data_center_id`
- If `hosting_type IN ('Cloud', 'SaaS', 'Third-Party-Hosted')` → Use `region`
- If `hosting_type = 'Desktop'` → Set `region = 'LOCAL'`

---

### 3.2 data_centers Table (NEW in v1.8)

```sql
CREATE TABLE data_centers (
  id uuid PRIMARY KEY,
  namespace_id uuid NOT NULL REFERENCES namespaces(id),
  name text NOT NULL,
  code text NOT NULL,
  location text NOT NULL,
  country_code text NOT NULL,
  type text NOT NULL CHECK (type IN ('primary', 'dr', 'colocation', 'edge')),
  is_active boolean DEFAULT true,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT data_centers_unique_code UNIQUE(namespace_id, code)
);
```

**Purpose:** Organization-specific data centers for on-premises deployments.

**Scope:** Namespace-scoped (each organization defines their own).

**Examples:**
- "Edmonton Data Center" (EDM-DC1) - Primary
- "Calgary DR Site" (CGY-DR1) - DR
- "Regina Colocation" (RGN-CO1) - Colocation

---

### 3.3 standard_regions Table (NEW in v1.8)

```sql
CREATE TABLE standard_regions (
  code text PRIMARY KEY,
  name text NOT NULL,
  provider text CHECK (provider IN ('aws', 'azure', 'gcp', 'oracle', 'generic')),
  country_code text NOT NULL,
  sort_order integer DEFAULT 999,
  created_at timestamptz DEFAULT now()
);
```

**Purpose:** Reference data for cloud provider regions.

**Scope:** Global (no RLS, reference data).

**Providers:**
- Generic: Vendor-agnostic regions (Canada, US East, Europe West)
- AWS: ca-central-1, us-east-1, etc.
- Azure: Canada Central, East US, etc.
- GCP: northamerica-northeast1, us-east1, etc.
- Oracle: ca-toronto-1, us-ashburn-1, etc.

**Total Regions:** 37 (12 generic + 8 Azure + 7 AWS + 4 GCP + 6 Oracle)

---

## 4. Location Tracking by Hosting Type

### 4.1 Environment Values (Unchanged)
| Code | Display |
|------|---------|
| PROD | Production |
| SBX | Sandbox |
| UAT | UAT |
| TEST | Test |
| DEV | Development |
| STG | Staging |
| DR | Disaster Recovery |

### 4.2 Hosting Type Values (Unchanged)

Aligned with ServiceNow CSDM:

| Code | Display | Location Field Used |
|------|---------|---------------------|
| SaaS | SaaS | `region` (standard_regions) |
| Third-Party-Hosted | Third-Party Hosted | `region` (standard_regions) |
| Cloud | Cloud | `region` (standard_regions, filtered by cloud_provider) |
| On-Prem | On-Premises | `data_center_id` (data_centers) |
| Hybrid | Hybrid | `data_center_id` (data_centers) |
| Desktop | Desktop | `region = 'LOCAL'` (auto-set) |

### 4.3 Cloud Provider Values (Updated)
| Code | Display |
|------|---------|
| aws | AWS |
| azure | Azure |
| gcp | Google Cloud |
| oracle | Oracle Cloud |
| ibm | IBM Cloud |
| other | Other |
| na | N/A |

**Note:** IBM Cloud doesn't have specific regions in standard_regions yet (can be added as needed).

### 4.4 Region Field Usage (UPDATED in v1.8)

**REMOVED:** "N/A (Vendor Managed)" - This was confusing as it conflated location with management.

**NEW APPROACH:** Region always represents physical location, hosting_type indicates management.

**Context-Sensitive Behavior:**

| Hosting Type | Field Shown | Data Source | Stored In |
|--------------|-------------|-------------|-----------|
| On-Prem | "Data Center" dropdown | `data_centers` WHERE `namespace_id = current` | `data_center_id` |
| Hybrid | "Data Center" dropdown | `data_centers` WHERE `namespace_id = current` | `data_center_id` |
| Cloud | "Region" dropdown | `standard_regions` WHERE `provider IN ('generic', cloud_provider)` | `region` |
| SaaS | "Vendor Region" dropdown | `standard_regions` WHERE `provider = 'generic'` | `region` |
| Third-Party-Hosted | "Hosting Location" dropdown | `standard_regions` WHERE `provider = 'generic'` | `region` |
| Desktop | "Local" (disabled) | Auto-set | `region = 'LOCAL'` |

**Example SaaS Application (Salesforce):**
- Hosting Type: SaaS
- Cloud Provider: other (or "salesforce" if we add it)
- Region: US East (where Salesforce actually hosts your instance)
- Display: "SaaS · Salesforce · US East"

**Example On-Prem Application (SaskPower):**
- Hosting Type: On-Prem
- Data Center: Regina Data Center (RGN-DC1)
- Display: "On-Premises · Regina Data Center"

---

## 5. Data Residency Compliance

### 5.1 Purpose

**Legal Requirements:**
- Canada: PIPEDA requires knowing where personal data is stored
- Europe: GDPR requires data to stay in approved jurisdictions
- Government: Mandates for Canadian data on Canadian soil

**Audit Questions:**
- "Where is our citizen data physically located?"
- "Which applications store data outside Canada?"
- "Do we have any EU data in non-EU regions?"

### 5.2 Compliance Queries

```sql
-- All applications with data in Canada
SELECT 
  a.name,
  CASE 
    WHEN dp.data_center_id IS NOT NULL THEN dc.location
    ELSE sr.name
  END as location,
  CASE 
    WHEN dp.data_center_id IS NOT NULL THEN dc.country_code
    ELSE sr.country_code
  END as country
FROM applications a
JOIN deployment_profiles dp ON dp.application_id = a.id
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
LEFT JOIN standard_regions sr ON sr.code = dp.region
WHERE dp.dp_type = 'application'
  AND dp.is_primary = true
  AND (dc.country_code = 'CA' OR sr.country_code = 'CA');

-- Applications outside Canada (potential compliance risk)
SELECT 
  a.name,
  w.name as workspace,
  CASE 
    WHEN dp.data_center_id IS NOT NULL THEN dc.location
    ELSE sr.name
  END as location,
  CASE 
    WHEN dp.data_center_id IS NOT NULL THEN dc.country_code
    ELSE sr.country_code
  END as country
FROM applications a
JOIN deployment_profiles dp ON dp.application_id = a.id
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
LEFT JOIN standard_regions sr ON sr.code = dp.region
WHERE dp.dp_type = 'application'
  AND dp.is_primary = true
  AND COALESCE(dc.country_code, sr.country_code) != 'CA';
```

### 5.3 Reporting

**Dashboard Widget Idea:** Data Residency Summary
```
Data Residency
├─ Canada: 42 applications (85%)
├─ United States: 6 applications (12%)
├─ Europe: 1 application (2%)
└─ Unknown: 1 application (2%)
```

---

## 6. RLS Policies

### 6.1 deployment_profiles RLS (Unchanged)

Users can only see/edit DPs for applications in their workspaces.

### 6.2 data_centers RLS (NEW in v1.8)

```sql
-- Users can view data centers in their namespace
CREATE POLICY "Users can view data centers in their namespace" ON data_centers
  FOR SELECT TO authenticated
  USING (namespace_id IN (
    SELECT DISTINCT w.namespace_id 
    FROM workspaces w
    JOIN workspace_users wu ON wu.workspace_id = w.id
    WHERE wu.user_id = auth.uid()
  ));

-- Workspace admins can manage data centers
CREATE POLICY "Workspace admins can insert data centers" ON data_centers
  FOR INSERT TO authenticated
  WITH CHECK (namespace_id IN (
    SELECT DISTINCT w.namespace_id 
    FROM workspaces w
    JOIN workspace_users wu ON wu.workspace_id = w.id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'owner')
  ));

-- Similar policies for UPDATE and DELETE
```

**Key Points:**
- Data centers are namespace-scoped
- Only admins/owners can create/edit/delete
- All users can view data centers in their namespace
- Cross-namespace access is blocked

---

## 7. Migration Notes

### 7.1 Backward Compatibility

**Existing Data:**
- All existing DPs with `region = 'N/A'` were migrated to proper values
- Desktop apps set to `region = 'LOCAL'`
- SaaS apps defaulted to appropriate regions based on cloud_provider
- Unknown values set to `region = 'UNKNOWN'`

**No Breaking Changes:**
- `region` field still exists and works for Cloud/SaaS
- New `data_center_id` field is nullable
- Old data continues to work

### 7.2 Sample Data Centers Created

**Government of Alberta (Test):**
- Edmonton Data Center (EDM-DC1) - Primary
- Calgary DR Site (CGY-DR1) - DR

**City of Riverside:**
- City Hall Data Center (RIV-DC1) - Primary

---

## 8. UI Behavior

### 8.1 Edit Application Modal

**Location Field - Context Sensitive:**

1. User selects `hosting_type = 'On-Prem'`
   - Show "Data Center" dropdown
   - Populate from namespace data_centers
   - Save to `data_center_id`

2. User selects `hosting_type = 'Cloud'`
   - Show "Region" dropdown
   - If cloud_provider selected, filter regions
   - Save to `region`

3. User selects `hosting_type = 'Desktop'`
   - Auto-set `region = 'LOCAL'`
   - Show disabled field

### 8.2 Data Center Admin (NEW)

**Location:** Settings → Organization → Data Centers

**Features:**
- List all data centers for namespace
- Add/Edit/Delete data centers
- Shows: Name, Code, Location, Country, Type
- Admin/Owner only

**Empty State:**
- "No data centers defined"
- Prompt to add first data center
- Explain it's for on-premises deployments

---

## 9. Suite Tech Score Inheritance (NEW in v1.9)

### 9.1 `inherits_tech_from` Column

```sql
ALTER TABLE deployment_profiles
  ADD COLUMN inherits_tech_from UUID REFERENCES deployment_profiles(id) ON DELETE SET NULL;

CREATE INDEX idx_dp_inherits_tech_from ON deployment_profiles(inherits_tech_from)
  WHERE inherits_tech_from IS NOT NULL;
```

**Purpose:** When a suite child application (architecture_type = `platform_application`) has its own DP, that DP's `inherits_tech_from` points to the parent's primary DP. This allows the child to exist as a full DP record (avoiding null-DP edge cases) while inheriting its parent's T-scores.

### 9.2 Behavior

When `inherits_tech_from` IS NOT NULL:

| Aspect | Behavior |
|--------|----------|
| T01-T14 columns | Stay NULL on child DP |
| tech_health | NULL (auto-calculate trigger returns NULL when all factors NULL) |
| tech_risk | NULL (same — returns NULL when all factors NULL) |
| Frontend display | Resolves `inherits_tech_from` FK to show parent's T-scores with "(inherited)" indicator |
| Scoring patterns | NOT offered — T-scores come from parent |
| B-scores | Independent — assessed via child's DP portfolio assignment |
| hosting_type, region | Set independently (typically matches parent) |
| IT Services | Can be linked independently (for add-on module costs) |
| Cost Bundles | Can be linked independently |

### 9.3 Auto-Calculate Trigger Compatibility

The existing `auto_calculate_deployment_profile_tech_scores()` trigger is compatible:
- `calculate_tech_health()` skips NULL factors (`IF p_tXX IS NOT NULL THEN`)
- Returns NULL if `v_total_weight = 0` (all factors NULL)
- Suite children with all-NULL T-scores correctly get `tech_health = NULL`, `tech_risk = NULL`
- No trigger modifications needed

### 9.4 ON DELETE SET NULL Rationale

If the parent DP is deleted, `inherits_tech_from` becomes NULL. The child reverts to a standalone DP with no inherited scores — T-scores show as unassessed until re-linked or independently scored.

### 9.5 Cross-References

- `core/composite-application.md` v2.0 — Full suite architecture, design decisions
- `features/assessment/tech-scoring-patterns.md` §12 — Suite auto-suggestion future enhancement

---

## 10. CSDM Auto-Wiring (NEW in v2.0)

When a technology product is added to or removed from a deployment profile, the system automatically manages IT service links via the `deployment_profile_it_services` junction table.

### 10.1 Add Tech Product → Auto-Link IT Services

1. Query `it_service_technology_products` joined with `it_services` to find IT services powered by the added tech product (filtered to same namespace)
2. For each match, check if `deployment_profile_it_services` already has a row for this DP + service
3. If not, insert with `relationship_type = 'depends_on'` and `source = 'auto'`
4. Toast per link: "Automatically linked to [Service Name]"
5. If zero matches: informational toast "[Tech Product] added. No IT Service covers this technology yet."

### 10.2 Remove Tech Product → Auto-Unlink IT Services

1. Find IT services powered by the removed tech product
2. For each, check if any OTHER tech products still on this DP also power that service
3. If none remain AND `source = 'auto'`:
   - Query IT service annual cost
   - If cost > 0: show confirm dialog with cost impact
   - On confirm: delete the `deployment_profile_it_services` row
4. Manual links (`source = 'manual'`) are never touched by auto-wiring

### 10.3 Source Column

The `source` column on `deployment_profile_it_services` tracks link provenance:

| Value | Meaning |
|-------|---------|
| `auto` | Created by tech product auto-wiring |
| `manual` | User explicitly linked via IT Service dependency picker |

### 10.4 SaaS Deployment Profiles

SaaS deployment profiles skip auto-wiring. Adding a tech product shows an informational toast only — no IT service links are created or removed automatically.

---

## 11. Server Relationship (NEW in v2.1)

### 11.1 Overview

Deployment Profiles support a many-to-many relationship with servers via the `deployment_profile_servers` junction table. A single DP can reference multiple servers (e.g., a database server, web server, and application server), and a single server can host multiple DPs.

### 11.2 `servers` Table

Namespace-scoped server reference entity. Follows the same scoping pattern as `data_centers`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `namespace_id` | uuid | FK `namespaces(id)`, namespace scoping |
| `name` | text | Display name, e.g. "PROD-SQL-01" |
| `os` | text | Optional OS label, e.g. "Windows Server 2022" |
| `data_center_id` | uuid | Optional FK `data_centers(id)` |
| `status` | text | `active` / `decommissioned` (default `active`) |
| `notes` | text | Free-form |

UNIQUE on `(namespace_id, name)`. RLS: namespace-scoped. Audit trigger enabled.

### 11.3 `deployment_profile_servers` Junction

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `deployment_profile_id` | uuid | FK `deployment_profiles(id)` ON DELETE CASCADE |
| `server_id` | uuid | FK `servers(id)` ON DELETE RESTRICT |
| `server_role` | text | Role from `server_role_types` (database, web, application, file, utility, other) |
| `is_primary` | boolean | Default false. Marks the main server for display priority |

UNIQUE on `(deployment_profile_id, server_id)`. RLS: inherited from DP's workspace/namespace scope. Audit trigger enabled.

### 11.4 Backward Compatibility

The legacy `server_name` text column on `deployment_profiles` is retained during transition. Consumers should prefer the junction table; if no junction rows exist, fall back to `server_name`. The column will be dropped in a future release.

### 11.5 Related

- **ADR:** `adr/adr-dp-infrastructure-boundary.md` v2.0 — boundary rationale and migration details
- **Design spec:** `features/technology-health/multi-server-dp-design.md` — full schema, UI, and phased delivery plan
- **Dashboard:** `features/technology-health/dashboard.md` — server-centric views and "By Server" tab

---

## 12. Future Enhancements

### 12.1 Data Center Costs (Phase 26+)

Track costs associated with data centers:
```sql
ALTER TABLE data_centers
ADD COLUMN monthly_cost numeric(12,2),
ADD COLUMN cost_allocation_basis text; -- 'square_footage', 'rack_units', 'equal'
```

Then allocate to apps based on their presence in that DC.

### 12.2 Multi-Region Deployments (Phase 27+)

Some apps span multiple regions (e.g., global CDN):
```sql
CREATE TABLE deployment_profile_regions (
  deployment_profile_id uuid REFERENCES deployment_profiles(id),
  region_code text,
  percentage numeric(5,2),
  PRIMARY KEY (deployment_profile_id, region_code)
);
```

### 12.3 Additional Cloud Providers

As needed, add more providers to standard_regions:
- IBM Cloud (ibm)
- Alibaba Cloud (alibaba)
- Salesforce-specific (salesforce)
- Custom provider codes

---

## 13. Related Documents

| Document | Content |
|----------|---------|
| core/conceptual-erd.md | Full data model |
| core/composite-application.md | Suite relationships, `inherits_tech_from` usage |
| catalogs/csdm-application-attributes.md | CSDM alignment |
| CHANGELOG.md | Change history |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.1 | 2026-04-13 | Multi-server relationship. New §11: `servers` table, `deployment_profile_servers` junction (many-to-many with role and primary marker). Legacy `server_name` retained for backward compat. References ADR v2.0. |
| v1.9 | 2026-03-08 | Add `inherits_tech_from` column for suite T-score inheritance. New §9 documenting behavior, trigger compatibility, and cross-references. |
| v1.8 | 2026-01-31 | Add data_centers table, standard_regions table, data_center_id field, remove "N/A (Vendor Managed)", context-sensitive location tracking |
| v1.7 | 2026-01-15 | Previous version with static region dropdown |

---

*Document: core/deployment-profile.md*
*March 2026*
