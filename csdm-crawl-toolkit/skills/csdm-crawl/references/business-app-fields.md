# Business Application Fields Reference
## `cmdb_ci_business_app` — Complete field guide for CSDM Crawl

> This reference maps every Crawl-relevant field on `cmdb_ci_business_app` to its
> ServiceNow column name, data type, and Import Set CSV header.

---

## Required fields for Crawl

| Field Label | Column Name | Type | Import CSV Header | Notes |
|-------------|-------------|------|-------------------|-------|
| Name | `name` | String (100) | `name` | Canonical application name. No abbreviations. |
| Number | `number` | String (40) | *Auto-generated* | Do not import — ServiceNow auto-assigns. |
| Business Owner | `owned_by` | Reference (sys_user) | `owned_by` | Import by email or user_name, not sys_id. |
| IT Application Owner | `managed_by` | Reference (sys_user) | `managed_by` | Import by email or user_name. |
| Managed by Group | `managed_by_group` | Reference (sys_user_group) | `managed_by_group` | Import by group name. |
| Install Status | `install_status` | Integer | `install_status` | 1=Installed, 3=In Maintenance, 7=Retired, 8=Pipeline |
| Operational Status | `operational_status` | Integer | `operational_status` | 1=Operational, 2=Non-Operational, 6=Retired |
| Business Criticality | `busines_criticality` | String | `busines_criticality` | Note: ServiceNow typo — one 's'. Values: 1 - most critical, 2 - somewhat critical, 3 - less critical, 4 - not critical, 5 - unclassified |

## Recommended fields for Crawl

| Field Label | Column Name | Type | Import CSV Header | Notes |
|-------------|-------------|------|-------------------|-------|
| Short Description | `short_description` | String (1000) | `short_description` | 1–2 sentence summary of what the app does. |
| Company | `company` | Reference (core_company) | `company` | Import by company name. |
| Department | `department` | Reference (cmn_department) | `department` | Import by department name. |
| Used for | `used_for` | String (40) | `used_for` | Production / Staging / QA / Development / DR |
| IT Application Owner Group | `it_application_owner_group` | Reference (sys_user_group) | `it_application_owner_group` | Optional if managed_by_group is set. |
| Vendor | `vendor` | Reference (core_company) | `vendor` | Software vendor. Import by company name. |

## Walk-phase fields (not needed for Crawl, but plan ahead)

| Field Label | Column Name | Type | Notes |
|-------------|-------------|------|-------|
| Portfolio | `portfolio` | Reference | Links to spm_portfolio for SPM integration |
| Business Unit | `business_unit` | Reference | Organization-level grouping |
| Platform | `platform` | String | Hosting model (On-premise / Cloud / Hybrid) |
| IT Function | `it_function` | String | IT4IT function category |

---

## Import Set CSV template

```csv
name,short_description,owned_by,managed_by,managed_by_group,install_status,operational_status,busines_criticality,company,department,vendor,used_for
SAP Finance,"Enterprise financial management and reporting",jane.cfo@org.com,bob.itlead@org.com,Finance IT Team,1,1,1 - most critical,Our Organization,Finance,SAP SE,Production
Salesforce CRM,"Customer relationship management platform",sarah.vpsales@org.com,mike.admin@org.com,CRM Support Team,1,1,2 - somewhat critical,Our Organization,Sales,Salesforce,Production
Legacy HR System,"Employee records and payroll processing",hr.director@org.com,legacy.team@org.com,HR IT Team,3,1,2 - somewhat critical,Our Organization,Human Resources,Custom Built,Production
```

### Import Set steps

1. Navigate to **System Import Sets → Load Data**
2. Create new table or select existing staging table
3. Upload CSV file
4. Create **Transform Map**: map CSV columns to `cmdb_ci_business_app` fields
5. For reference fields (owned_by, managed_by, etc.): use **Choice Action = create** or **reject**
6. Set **Coalesce = true** on `name` field to enable update-on-reimport
7. Run transform
8. Check **Import Set Runs** for errors

### Transform Map field mapping tips

**Reference fields** (owned_by, managed_by, managed_by_group, company, vendor):
- Source column contains the display value (email, name)
- Transform map auto-resolves to sys_id
- Use Choice Action "reject" to catch mismatches rather than creating garbage data

**Business Criticality** — import the full string value:
- `1 - most critical`
- `2 - somewhat critical`
- `3 - less critical`
- `4 - not critical`
- `5 - unclassified`

**Install Status** — import as integer:
- `1` = Installed (active, in use)
- `3` = In Maintenance (being patched/upgraded)
- `7` = Retired (no longer in use)
- `8` = Pipeline (planned, not yet deployed)

---

## Field mapping from common source systems

### From spreadsheet / Excel inventory

| Your Spreadsheet Column | Maps To | Transform Notes |
|------------------------|---------|----------------|
| Application Name | `name` | Direct map |
| Description | `short_description` | Truncate to 1000 chars |
| Business Owner | `owned_by` | Must match sys_user.email or user_name |
| Technical Owner | `managed_by` | Must match sys_user.email or user_name |
| Support Team | `managed_by_group` | Must match sys_user_group.name exactly |
| Status | `install_status` | Map: Active→1, Retired→7, Planned→8 |
| Criticality / Priority | `busines_criticality` | Map to 1–5 scale |
| Department | `department` | Must match cmn_department.name |
| Vendor | `vendor` | Must match core_company.name |

### From GetInSync NextGen

| GetInSync Field | Maps To | Transform Notes |
|----------------|---------|----------------|
| applications.name | `name` | Direct map |
| applications.short_description | `short_description` | Direct map |
| applications.operational_status | `operational_status` | operational→1, retired→6, pipeline→1 |
| applications.lifecycle_status | `install_status` | Mainstream→1, End of Support→3, (retired)→7 |
| applications.csdm_stage | — | Internal tracking, not imported to SN |
| deployment_profiles.name | → `cmdb_ci_service_auto.name` | Separate import to Application Service |
| deployment_profiles.hosting_type | → `cmdb_ci_service_auto.platform` | SaaS/Cloud/On-Prem/Hybrid |
| deployment_profiles.environment | → `cmdb_ci_service_auto.environment` | Production/QA/Dev/DR |

---

*For automated field mapping and one-click ServiceNow publish, see GetInSync NextGen
at getinsync.ca — designed to produce ServiceNow-ready data from day one.*
