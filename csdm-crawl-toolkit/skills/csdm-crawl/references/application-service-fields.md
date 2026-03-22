# Application Service Fields Reference
## `cmdb_ci_service_auto` — Field guide for CSDM Crawl

---

## Required fields for Crawl

| Field Label | Column Name | Type | Import CSV Header | Notes |
|-------------|-------------|------|-------------------|-------|
| Name | `name` | String (255) | `name` | Convention: "{App Name} - {Environment}" |
| Owned By | `owned_by` | Reference (sys_user) | `owned_by` | Person accountable for this deployment |
| Managed By Group | `managed_by_group` | Reference (sys_user_group) | `managed_by_group` | Day-to-day operations team |
| Support Group | `support_group` | Reference (sys_user_group) | `support_group` | Team that handles incidents — drives ITSM routing |
| Change Group | `change_control` | Reference (sys_user_group) | `change_control` | Team that approves changes (can = Support Group) |
| Environment | `environment` | String | `environment` | Production / QA / Development / Test / DR / Staging |
| Operational Status | `operational_status` | Integer | `operational_status` | 1=Operational, 2=Non-Operational |
| Business Criticality | `busines_criticality` | String | `busines_criticality` | Align with parent Business Application |

## Recommended fields

| Field Label | Column Name | Type | Notes |
|-------------|-------------|------|-------|
| Version | `version` | String | Current deployed version |
| Service Classification | `service_classification` | String | Application Service / Business Service / Technical Service |
| Number | `number` | String | Auto-generated |
| Short Description | `short_description` | String | What this specific deployment does |

## Import Set CSV template

```csv
name,owned_by,managed_by_group,support_group,change_control,environment,operational_status,busines_criticality,short_description
SAP Finance - Production,bob.itlead@org.com,Finance IT Team,Finance Support,Finance CAB,Production,1,1 - most critical,Production instance of SAP Finance ERP
SAP Finance - QA,bob.itlead@org.com,Finance IT Team,Finance Support,Finance CAB,QA,1,3 - less critical,QA/testing instance of SAP Finance ERP
Salesforce CRM - Production,mike.admin@org.com,CRM Support Team,CRM Support Team,IT CAB,Production,1,2 - somewhat critical,Production Salesforce org
```

## Subtypes of cmdb_ci_service_auto

| Subtype | Table | Created By | When to Use |
|---------|-------|-----------|-------------|
| (parent) | `cmdb_ci_service_auto` | Manual / Import Set | Crawl — default, always valid |
| Discovered | `cmdb_ci_service_discovered` | Service Mapping | Walk/Run — auto-discovered topology |
| Calculated | `cmdb_ci_service_calculated` | CI relationships | Walk — auto-built from existing CIs |
| Query-based | `cmdb_ci_query_based_service` | Dynamic CI Group | Walk — query-defined membership |
| Tag-based | `cmdb_ci_service_by_tags` | Cloud tag mapping | Run — cloud resource tags |

At Crawl, use the parent table `cmdb_ci_service_auto`. Do not worry about subtypes.

## Naming conventions

| Pattern | Example | When |
|---------|---------|------|
| Single environment | `SAP Finance` | Only Production exists |
| Multi-environment | `SAP Finance - Production` | Multiple environments |
| Multi-region | `SAP Finance - Production - CA-Central` | Multiple regions |
| Multi-tenant | `SAP Finance - Production - Ministry of Finance` | Shared software, separate tenants |

---

*In GetInSync, Deployment Profiles map directly to Application Services. Each DP captures
environment, hosting type, cloud provider, region, and technology stack — ready for
ServiceNow publish. See getinsync.ca.*
