# catalogs/csdm-application-attributes.md
CSDM Application Attributes Alignment
Last updated: 2026-01-21

---

## 1. Purpose

This document defines schema enhancements to align GetInSync NextGen with ServiceNow CSDM 5.0 mandatory fields for Business Applications and Application Service Instances (Deployment Profiles).

**Context:** Competitive positioning against Orbus iServer for government APM implementations. Organizations using Orbus for APM have struggled to deliver value (28+ months without production data in one case). GetInSync can demonstrate CSDM alignment with faster time-to-value.

**Audience:** Internal architects and developers.

---

## 2. CSDM Alignment Strategy

### 2.1 What We're Aligning To

ServiceNow CSDM 5.0 defines mandatory fields for:
- `cmdb_ci_business_app` — Business Application
- `cmdb_ci_service_auto` — Application Service Instance

Our mapping:
| CSDM Entity | GetInSync Entity |
|-------------|------------------|
| Business Application | `applications` |
| Application Service Instance | `deployment_profiles` |

### 2.2 What We're NOT Doing

We are **not** replicating ServiceNow's infrastructure CI tables:
- `cmdb_ci_server` — Servers
- `cmdb_ci_db_instance` — Databases
- `cmdb_ci_appl_web` — Web servers
- `cmdb_ci_network_gear` — Network devices

**Rationale:** ServiceNow Discovery masters infrastructure CIs. GetInSync provides APM context (hosting_type, cloud_provider, region) without duplicating CMDB data. When integrated, GetInSync pushes Business Application data; ServiceNow provides infrastructure relationships.

---

## 3. Current State vs. CSDM Requirements

### 3.1 Business Application (applications table)

| CSDM Field | Required | GetInSync Current | Status |
|------------|----------|-------------------|--------|
| name | Yes | `name` | ✅ Have |
| number | Yes | `app_id` (auto-generated) | ✅ Have |
| operational_status | Yes | — | ❌ Gap |
| life_cycle_stage | Yes | `lifecycle_status` | ✅ Have |
| life_cycle_stage_status | Yes | — | ❌ Gap |
| owned_by | Yes | `workspace_id` (structural) | ✅ Have |
| managed_by_group | Yes | `application_contacts` (role_type=support) | ✅ Have |
| vendor | No | — | ❌ Gap |
| description | No | `description` | ✅ Have |
| short_description | No | — | ⚠️ Nice-to-have |

### 3.2 Application Service Instance (deployment_profiles table)

| CSDM Field | Required | GetInSync Current | Status |
|------------|----------|-------------------|--------|
| name | Yes | `name` | ✅ Have |
| operational_status | Yes | — | ❌ Gap |
| environment | No | `environment` | ✅ Have |
| version | No | — | ❌ Gap |
| hosted_on | No | `hosting_type`, `cloud_provider`, `region` | ✅ Sufficient |

### 3.3 Assessment Extensions (GetInSync Advantage)

CSDM does not define TIME/PAID assessment. This is GetInSync's value-add:

| GetInSync Field | Location | Notes |
|-----------------|----------|-------|
| T01-T15 scores | `deployment_profiles` | Technical assessment factors |
| B01-B10 scores | `portfolio_assignments` | Business assessment factors |
| tech_health | `deployment_profiles` | Derived 0-100 |
| tech_risk | `deployment_profiles` | Derived 0-100 |
| business_fit | `portfolio_assignments` | Derived 0-100 |
| criticality | `portfolio_assignments` | Derived 0-100 |
| time_quadrant | `portfolio_assignments` | Tolerate/Invest/Modernize/Eliminate |
| paid_action | `deployment_profiles` | Plan/Address/Improve/Divest |

---

## 4. Architectural Decisions

### 4.1 Derived vs. Static Criticality

**Decision:** Criticality is DERIVED from B-scores, not a static field.

**Rationale:**
- Static "crown jewel" or "criticality" flags become stale theater
- Derived criticality stays current through active assessment
- Assessment-driven approach forces periodic review
- Differentiator vs. Orbus/ServiceNow static fields

**CSDM Note:** CSDM's `business_criticality` field is optional. Our derived approach satisfies the intent (knowing what's critical) without the staleness problem.

### 4.2 Operational Status Semantics

**Decision:** Add `operational_status` with values: `operational`, `retired`, `pipeline`

**Mapping to CSDM:**
| GetInSync Value | CSDM operational_status |
|-----------------|-------------------------|
| operational | Operational |
| retired | Retired |
| pipeline | Pipeline |

**Relationship to lifecycle_status:**
- `lifecycle_status` = vendor support phase (Mainstream/Extended/End-of-Support)
- `operational_status` = our operational state (running/retired/planned)

An app can be `operational` with `lifecycle_status = 'End of Support'` — it's running but unsupported.

### 4.3 Lifecycle Stage Status

**Decision:** Add `lifecycle_stage_status` with values: `active`, `planned`, `retired`

**Semantics:**
| Value | Meaning |
|-------|---------|
| active | Currently in this lifecycle stage |
| planned | Lifecycle transition planned |
| retired | No longer in active lifecycle management |

**Note:** This is CSDM's field for tracking lifecycle transitions. It complements `operational_status` and `lifecycle_status`.

### 4.4 Vendor as Organization FK

**Decision:** Add `vendor_organization_id` FK to `organizations` table.

**Rationale:**
- Organizations table already has `is_vendor` boolean flag
- Enables vendor filtering, reporting, contract linkage
- Aligns with CSDM's vendor reference

**Not doing:** Separate vendor table. Organizations with `is_vendor=true` are vendors.

### 4.5 Tech Debt Description

**Decision:** Add `tech_debt_description` text field to `deployment_profiles`.

**Rationale:**
- PAID assessment identifies technical debt priority
- Narrative field captures the "what" behind the scores
- Useful for remediation planning and reporting

### 4.6 Deployment Profile Version

**Decision:** Add `version` text field to `deployment_profiles`.

**Rationale:**
- Common ask: "What version is deployed?"
- Supports upgrade planning and compatibility tracking
- Aligns with CSDM's version field on Application Service

---

## 5. Schema Changes

### 5.1 applications table

```sql
-- Operational Status (CSDM mandatory)
ALTER TABLE applications
ADD COLUMN operational_status TEXT DEFAULT 'operational';

ALTER TABLE applications
ADD CONSTRAINT chk_app_operational_status
CHECK (operational_status IN ('operational', 'retired', 'pipeline'));

-- Lifecycle Stage Status (CSDM mandatory)
ALTER TABLE applications
ADD COLUMN lifecycle_stage_status TEXT DEFAULT 'active';

ALTER TABLE applications
ADD CONSTRAINT chk_app_lifecycle_stage_status
CHECK (lifecycle_stage_status IN ('active', 'planned', 'retired'));

-- Vendor Organization FK
ALTER TABLE applications
ADD COLUMN vendor_organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

CREATE INDEX idx_applications_vendor ON applications(vendor_organization_id);

-- Short Description (optional, for CSDM completeness)
ALTER TABLE applications
ADD COLUMN short_description VARCHAR(160);
```

### 5.2 deployment_profiles table

```sql
-- Operational Status
ALTER TABLE deployment_profiles
ADD COLUMN operational_status TEXT DEFAULT 'operational';

ALTER TABLE deployment_profiles
ADD CONSTRAINT chk_dp_operational_status
CHECK (operational_status IN ('operational', 'non-operational'));

-- Version
ALTER TABLE deployment_profiles
ADD COLUMN version TEXT;

-- Tech Debt Description
ALTER TABLE deployment_profiles
ADD COLUMN tech_debt_description TEXT;
```

---

## 6. UI Implications

### 6.1 Application Edit Modal

Add to "Basic Information" section:
- **Operational Status** — Dropdown: Operational / Retired / Pipeline
- **Lifecycle Stage Status** — Dropdown: Active / Planned / Retired
- **Vendor** — Organization picker (filtered to is_vendor=true)
- **Short Description** — Text input (160 char limit, optional)

### 6.2 Deployment Profile Edit

Add to "Deployment Details" section:
- **Operational Status** — Dropdown: Operational / Non-Operational
- **Version** — Text input

Add to "Assessment" section (or new "Technical Debt" section):
- **Tech Debt Description** — Textarea

### 6.3 Dashboard / List Views

- Filter by `operational_status` (hide retired by default?)
- Show version in DP cards/rows
- Vendor column in application list

---

## 7. Migration Considerations

### 7.1 Default Values

All new fields have sensible defaults:
- `operational_status` → 'operational' (assume apps are running)
- `lifecycle_stage_status` → 'active'
- `vendor_organization_id` → NULL (optional)
- `short_description` → NULL
- `version` → NULL
- `tech_debt_description` → NULL

### 7.2 Existing Data

No data migration required. New fields are additive with defaults or NULLable.

### 7.3 RLS Impact

New columns inherit existing RLS policies. No policy changes needed.

---

## 8. ServiceNow Sync Mapping

When GetInSync syncs to ServiceNow:

| GetInSync Field | ServiceNow Field | Table |
|-----------------|------------------|-------|
| `name` | `name` | cmdb_ci_business_app |
| `app_id` | `number` | cmdb_ci_business_app |
| `operational_status` | `operational_status` | cmdb_ci_business_app |
| `lifecycle_status` | `life_cycle_stage` | cmdb_ci_business_app |
| `lifecycle_stage_status` | `life_cycle_stage_status` | cmdb_ci_business_app |
| `vendor_organization_id` → org.name | `vendor` | cmdb_ci_business_app |
| `description` | `description` | cmdb_ci_business_app |
| `short_description` | `short_description` | cmdb_ci_business_app |
| DP `name` | `name` | cmdb_ci_service_auto |
| DP `operational_status` | `operational_status` | cmdb_ci_service_auto |
| DP `environment` | `environment` | cmdb_ci_service_auto |
| DP `version` | `version` | cmdb_ci_service_auto |

---

## 9. Competitive Positioning

### 9.1 vs. Orbus iServer

| Capability | Orbus | GetInSync | Advantage |
|------------|-------|-----------|-----------|
| CSDM Alignment | Requires custom metamodel | Native alignment | GetInSync |
| TIME/PAID Assessment | Custom objects to build | Built-in | GetInSync |
| Criticality | Static field | Derived from assessment | GetInSync |
| Time to Value | 6-12+ months | 30-60 days | GetInSync |
| App Owner Updates | Editor license or Central IT | Steward role (included) | GetInSync |
| Multi-deployment | One app = one assessment | DP-centric (per deployment) | GetInSync |

### 9.2 Key Messages

1. **"You've had Orbus for 28 months with zero apps loaded. That's a tool problem, not a team problem."**

2. **"Orbus is an EA modeling platform. You need APM. Different tools for different jobs."**

3. **"We're CSDM-aligned out of the box. No metamodel configuration. No custom objects to build."**

4. **"Criticality that stays current — derived from active assessment, not a stale checkbox."**

5. **"Same app, different deployments = different assessments. Because reality."**

---

## 10. Related Documents

| Document | Relevance |
|----------|-----------|
| features/integrations/servicenow-alignment.md | Full CSDM sync mapping |
| core/core-architecture.md | Entity relationships |
| archive/superseded/deployment-profile-v1_7.md | DP schema details |
| catalogs/business-application.md | Application schema |
| getinsync-nextgen-schema-2025-01-12.md | Current as-built schema |

---

## 11. Implementation Phases

| Phase | Scope | Effort |
|-------|-------|--------|
| **23a** | Database migration (7 columns) | 1 hr |
| **23b** | TypeScript types update | 30 min |
| **23c** | Application Edit Modal UI | 2 hrs |
| **23d** | Deployment Profile Edit UI | 1 hr |
| **23e** | List/Dashboard filters | 1 hr |

**Total estimate:** ~5.5 hours

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-21 | Initial version — CSDM gap analysis and schema proposal |

---

*Document: catalogs/csdm-application-attributes.md*
*January 2026*
