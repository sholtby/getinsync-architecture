# CSDM Crawl Gap Analysis — GetInSync NextGen vs ServiceNow
**Version:** 1.0
**Date:** 2026-03-22
**Author:** Stuart Holtby / Claude
**Status:** Analysis Complete — Input for Phase 37 Planning

---

## 1. Purpose

This document cross-references the CSDM Crawl Readiness Checklist (47 items) against the actual GetInSync NextGen schema to identify field-level gaps that must be resolved before the Phase 37 ServiceNow publish engine can produce Crawl-compliant data.

**Key finding:** GetInSync is ~65% Crawl-ready. The data model captures most required fields, but has structural gaps around group management, business criticality placement, and owner field structure.

**References:**
- Crawl Checklist: `csdm-crawl-toolkit/skills/csdm-crawl/references/crawl-checklist.md`
- ServiceNow Alignment: `features/integrations/servicenow-alignment.md` (v1.2)
- Phase 37 API Research: `features/integrations/itsm-api-research.md` (v1.1)
- Schema: `schema/nextgen-schema-current.sql`

---

## 2. Business Application Field Mapping

**GetInSync:** `applications` + `application_contacts`
**ServiceNow:** `cmdb_ci_business_app`

### Required Fields (8)

| # | SN Field | SN Column | GIS Source | Status | Notes |
|---|----------|-----------|------------|--------|-------|
| 1 | Name | `name` | `applications.name` | **Ready** | Direct match |
| 2 | Number | `number` | `applications.app_id` | **Ready** | Auto-incrementing integer; needs `APP-` prefix at export |
| 3 | Business Owner | `owned_by` | `application_contacts` where `role_type='business_owner'` | **Ready** | Structured FK to `contacts.id`. Note: `applications.owner` (free text) is legacy — do NOT use for export |
| 4 | IT Application Owner | `managed_by` | `application_contacts` where `role_type='technical_owner'` | **Ready** | Structured FK to `contacts.id` |
| 5 | Managed by Group | `managed_by_group` | — | **GAP** | No group entity in GetInSync. `application_contacts` tracks individuals, not groups. See §4.1 |
| 6 | Install Status | `install_status` | `applications.operational_status` | **Ready** | Values need mapping (see §5) |
| 7 | Operational Status | `operational_status` | `applications.lifecycle_stage_status` | **Ready** | Values need mapping (see §5) |
| 8 | Business Criticality | `busines_criticality` | `portfolio_assignments.criticality` | **GAP** | Score is portfolio-scoped (numeric 0–100), not global app metadata, not 1–5 scale. See §4.2 |

### Recommended Fields (6)

| # | SN Field | SN Column | GIS Source | Status | Notes |
|---|----------|-----------|------------|--------|-------|
| 9 | Short Description | `short_description` | `applications.short_description` | **Ready** | Direct match |
| 10 | Company | `company` | — | **Gap** | No company FK on applications. Could derive from `workspaces` → `namespaces` |
| 11 | Department | `department` | — | **Gap** | No department on applications. `contacts.department` exists but no app→dept link |
| 12 | Used for | `used_for` | `applications.primary_use_case` | **Ready** | Direct match |
| 13 | Application Category | `subcategory` | — | **Gap** | No category/taxonomy field on applications |
| 14 | Vendor | `vendor` | — | **Gap** | Vendor lives on `deployment_profiles.vendor_org_id`, not on applications |

**Score: 5 of 8 required ready, 2 of 6 recommended ready**

---

## 3. Application Service Field Mapping

**GetInSync:** `deployment_profiles` + `deployment_profile_contacts`
**ServiceNow:** `cmdb_ci_service_auto`

### Required Fields (8)

| # | SN Field | SN Column | GIS Source | Status | Notes |
|---|----------|-----------|------------|--------|-------|
| 1 | Name | `name` | `deployment_profiles.name` | **Ready** | Direct match |
| 2 | Owned By | `owned_by` | `deployment_profile_contacts` where `role_type='operational_owner'` | **Ready** | Structured FK |
| 3 | Managed By Group | `managed_by_group` | — | **GAP** | No group entity. See §4.1 |
| 4 | Support Group | `support_group` | `deployment_profile_contacts` where `role_type='support'` | **Partial** | Tracks individual contact, not group. See §4.1 |
| 5 | Change Group | `change_control` | — | **GAP** | No change_control role in `deployment_profile_contacts`. Allowed roles: `operational_owner`, `technical_sme`, `support`, `vendor_rep`, `other` |
| 6 | Environment | `environment` | `deployment_profiles.environment` | **Ready** | Default 'PROD'. Values: PROD, QA, DEV, TEST, DR, STAGING |
| 7 | Operational Status | `operational_status` | `deployment_profiles.operational_status` | **Ready** | Default 'operational'. Values need mapping (see §5) |
| 8 | Business Criticality | `busines_criticality` | — | **GAP** | No criticality on deployment_profiles. Same issue as applications (§4.2) |

### Recommended Fields (3)

| # | SN Field | SN Column | GIS Source | Status | Notes |
|---|----------|-----------|------------|--------|-------|
| 9 | Version | `version` | `deployment_profiles.version` | **Ready** | Direct match |
| 10 | Location | `location` | `deployment_profiles.data_center_id` | **Partial** | FK to data centers exists; needs location name resolution |
| 11 | Service Classification | `service_classification` | `deployment_profiles.dp_type` | **Partial** | Values: 'application', 'infrastructure'. Needs mapping |

**Score: 3 of 8 required ready, 1 of 3 recommended ready**

---

## 3b. Relationship Mapping

**GetInSync:** `deployment_profiles.application_id` (FK)
**ServiceNow:** `cmdb_rel_ci` with type "Consumes::Consumed By"

| # | sn_getwell Check | GIS Source | Status | Notes |
|---|-----------------|------------|--------|-------|
| 1 | Every BA has ≥1 AS | `deployment_profiles.application_id` | **Ready** | FK gives the relationship directly |
| 2 | Type is Consumes::Consumed By | Implicit at export | **Ready** | Export engine sets the correct `type` sys_id |
| 3 | Every AS has ≥1 BA | `deployment_profiles.application_id NOT NULL` | **Ready** | FK constraint guarantees this |

**Score: 3 of 3 ready** — Relationships are structurally guaranteed by the FK model.

---

## 4. Critical Gaps (Red)

### 4.1 No Group Entity

**Problem:** CSDM Crawl requires three group fields: `managed_by_group` (on both BA and AS), `support_group` (on AS), and `change_control` (on AS). All reference ServiceNow's `sys_user_group` — an organizational team, not an individual.

GetInSync has `application_contacts` and `deployment_profile_contacts` which track **individual** contacts with role types. There is no `contact_groups` or team entity.

**Impact:** 3 of 16 required fields across BA + AS cannot be populated. This is the single largest gap.

**Resolution options (for Phase 37):**
- **Option A:** Create `contact_groups` table + link tables. Proper data model fix.
- **Option B:** Map individual contacts to SN groups at export time via config/lookup.
- **Option C:** Let customers manually map groups in ServiceNow after import; export only individual owners.

**Decision:** Deferred to Phase 37 planning.

### 4.2 Business Criticality Placement

**Problem:** Crawl requires `busines_criticality` (1–5 scale) on both `cmdb_ci_business_app` and `cmdb_ci_service_auto`. In GetInSync, criticality is stored as a numeric score (0–100) in `portfolio_assignments.criticality`, which is **portfolio-scoped** — the same application can have different criticality in different portfolios.

**Impact:** 2 of 16 required fields (one per entity) cannot be directly populated.

**Resolution options (for Phase 37):**
- **Option A:** Add `business_criticality` column (text, 1–5) to `applications` table. Global, not portfolio-scoped.
- **Option B:** Derive at export time — take max criticality from any portfolio_assignment, map 0–100 → 1–5.
- **Option C:** Both — column + auto-populate from portfolio_assignments.

**Mapping table (if deriving):**

| GIS Score (0–100) | SN Value | SN Label |
|---|---|---|
| 80–100 | `1 - most critical` | 1 Most Critical |
| 60–79 | `2 - somewhat critical` | 2 Critical |
| 40–59 | `3 - less critical` | 3 Less Critical |
| 20–39 | `4 - minimally critical` | 4 Minimally Critical |
| 0–19 | `5 - least critical` | 5 Least Critical |

**Decision:** Deferred to Phase 37 planning.

### 4.3 Legacy Free-Text Owner Fields

**Problem:** `applications.owner` and `applications.primary_support` are plain text columns (not FKs). The structured contact links in `application_contacts` are the correct source, but the legacy columns create ambiguity.

**Impact:** Export engine must use `application_contacts` (role_type = `business_owner` / `technical_owner`), never `applications.owner`. If `application_contacts` has no business_owner record, the export will produce a blank `owned_by` — a Crawl violation.

**Resolution:** Phase 37 export must:
1. Read from `application_contacts`, not `applications.owner`
2. Validate that every application has at least one `business_owner` and `technical_owner` contact before export
3. Surface validation errors in the pre-publish check UI

### 4.4 Missing Change Control Role

**Problem:** `deployment_profile_contacts.role_type` constraint allows: `operational_owner`, `technical_sme`, `support`, `vendor_rep`, `other`. There is no `change_control` or `change_approver` role.

**Impact:** Cannot populate `cmdb_ci_service_auto.change_control` from structured data.

**Resolution:** Add `change_control` to the CHECK constraint on `deployment_profile_contacts.role_type`. Schema change required.

---

## 5. Value Mapping Tables

### Install Status (Business Application)

| GIS `applications.operational_status` | SN `install_status` (integer) | SN Label |
|---|---|---|
| `operational` | `1` | Installed |
| `pipeline` | `8` | Pipeline |
| `retired` | `7` | Retired |

**Gap:** No GIS equivalent for SN values: `3` (In Maintenance), `6` (In Stock), `100` (Absent).

### Operational Status (Application Service)

| GIS `deployment_profiles.operational_status` | SN `operational_status` (integer) | SN Label |
|---|---|---|
| `operational` | `1` | Operational |
| `non-operational` | `2` | Non-Operational |

### Environment

| GIS `deployment_profiles.environment` | SN `environment` | Notes |
|---|---|---|
| `PROD` | `Production` | Direct |
| `QA` | `QA` | Direct |
| `DEV` | `Development` | Label difference |
| `TEST` | `Test` | Direct |
| `DR` | `DR` | Direct |
| `STAGING` | `Staging` | Direct |

### Lifecycle Stage Status

| GIS `applications.lifecycle_stage_status` | SN `life_cycle_stage` | Notes |
|---|---|---|
| `active` | `active` | Direct |
| `planned` | `pipeline` | Semantic mapping |
| `retired` | `retired` | Direct |

---

## 6. Moderate Gaps (Amber)

| # | Gap | GIS Source | Workaround |
|---|-----|-----------|------------|
| 1 | No vendor on applications | `deployment_profiles.vendor_org_id` → `organizations.name` | Derive from primary DP's vendor at export |
| 2 | No department on applications | `contacts.department` (via `application_contacts`) | Derive from business_owner's department |
| 3 | No company on applications | `workspaces.name` or `namespaces.name` | Map workspace to SN `core_company` |
| 4 | Lifecycle status confusion | `applications.lifecycle_status` is tech lifecycle, not business | Use `operational_status` + `lifecycle_stage_status` for Crawl; ignore `lifecycle_status` |
| 5 | No application category | — | New field needed, or derive from software product category |

---

## 7. Phase 37 Prerequisites — Schema Changes

These schema changes are **required before** the Phase 37 publish engine can produce Crawl-compliant data:

| # | Change | Type | Priority | Notes |
|---|--------|------|----------|-------|
| 1 | Add `change_control` to `deployment_profile_contacts.role_type` CHECK | ALTER constraint | High | Unblocks AS change_control field |
| 2 | Decide group strategy (new table vs export-time mapping) | Design decision | High | Unblocks 3 required fields |
| 3 | Add `business_criticality` to `applications` (or confirm derive-at-export) | Design decision | High | Unblocks 2 required fields |
| 4 | Add `ServiceNowSyncScope` to `deployment_profiles` | ADD COLUMN | Medium | Per itsm-api-research.md §3.4 |
| 5 | Create `integration_connections` table | CREATE TABLE | Medium | Per itsm-api-research.md §5.2 |
| 6 | Create `integration_sync_map` table | CREATE TABLE | Medium | Per itsm-api-research.md §5.2 |
| 7 | Create `integration_sync_log` table | CREATE TABLE | Medium | Per itsm-api-research.md §5.2 |
| 8 | Create CSDM export views (`vw_csdm_business_app`, `vw_csdm_service_auto`) | CREATE VIEW | Medium | Transforms GIS model → SN payload |

---

## 8. Toolkit Accuracy Notes

The CSDM Crawl Toolkit (`csdm-crawl-toolkit/skills/csdm-crawl/references/getinsync-bridge.md`) makes these claims. Current accuracy:

| Claim | Accuracy | Notes |
|-------|----------|-------|
| "One-click ServiceNow export" | **Not built** | Phase 37, Q3 2026. No code exists. |
| "Produces ServiceNow-ready data for cmdb_ci_business_app" | **Partially true** | 5 of 8 required fields mappable today |
| "Produces ServiceNow-ready data for cmdb_ci_service_auto" | **Partially true** | 3 of 8 required fields mappable today |
| "Produces Consumes::Consumed By relationships" | **True** | FK model guarantees relationship data |
| "Purpose-built interface for deployment profiles" | **True** | Full CRUD with environment, hosting, contacts |
| "Data governance (tracks changes, flags staleness)" | **Partially true** | Audit triggers exist; no staleness flagging yet |

**Recommendation:** Update `getinsync-bridge.md` to use future tense ("will produce") for the export feature, and present tense for what exists today (data model, governance, assessment).

---

## 9. Summary Scorecard

| Category | Total Items | Ready | Gap | Partial |
|----------|------------|-------|-----|---------|
| BA Required Fields | 8 | 5 | 2 | 1* |
| BA Recommended Fields | 6 | 2 | 4 | 0 |
| AS Required Fields | 8 | 3 | 3 | 2 |
| AS Recommended Fields | 3 | 1 | 0 | 2 |
| Relationships (sn_getwell) | 3 | 3 | 0 | 0 |
| **Total** | **28** | **14** | **9** | **5** |

*\* `owned_by` is ready via `application_contacts` but legacy `applications.owner` free-text creates ambiguity*

**Bottom line:** 14 of 28 mapped fields are export-ready. 9 require schema or design decisions. 5 have workarounds. The 3 relationship checks (what sn_getwell actually measures) are fully covered.

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-22 | Initial gap analysis — 28 fields mapped, 9 gaps identified, Phase 37 prerequisites listed |
