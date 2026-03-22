# Import Set Guide for CSDM Crawl Data

---

## Overview

ServiceNow Import Sets are the standard mechanism for bulk-loading CMDB data.
For Crawl, you need three imports in sequence:

1. **Business Applications** → `cmdb_ci_business_app`
2. **Application Services** → `cmdb_ci_service_auto`
3. **Relationships** → `cmdb_rel_ci`

## Step-by-step: Business Applications

1. **Prepare CSV** — use template from `references/business-app-fields.md`
2. Navigate to **System Import Sets → Load Data**
3. **Table:** Create new table (e.g., `u_import_business_apps`)
4. Upload CSV, click **Submit**
5. Click **Create Transform Map**
6. Map source columns to `cmdb_ci_business_app` target fields
7. **Coalesce field:** Set `name` as coalesce = true (enables update on reimport)
8. For reference fields: set Choice Action = **reject** (catches bad data)
9. **Run Transform**
10. Check results: **System Import Sets → Import Set Runs**

### Common transform errors and fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "No records found" on owned_by | Email doesn't match sys_user | Check exact email/username in sys_user |
| "No records found" on managed_by_group | Group name mismatch | Check exact name in sys_user_group |
| "Multiple records found" | Duplicate names in target table | Add second coalesce field or deduplicate source |
| "Transform error" on busines_criticality | Wrong value format | Use full string: "1 - most critical" |

## Step-by-step: Application Services

Same process, targeting `cmdb_ci_service_auto`. Use template from
`references/application-service-fields.md`.

**Important:** Import Application Services AFTER Business Applications so you can
reference them in the relationship import.

## Step-by-step: Relationships

Import into `cmdb_rel_ci` to create "Consumes::Consumed By" links.

```csv
parent,child,type
SAP Finance,SAP Finance - Production,Consumes::Consumed by
```

Transform map:
- `parent` → `parent` (Reference to cmdb_ci), coalesce on display value
- `child` → `child` (Reference to cmdb_ci), coalesce on display value
- `type` → `type` (Reference to cmdb_rel_type), coalesce on display value

**Tip:** If parent/child names are ambiguous (same name in different CI classes),
use sys_id instead of display value in the CSV.

## Automating reimports

For ongoing data loads (e.g., weekly sync from GetInSync):
1. Create a **Scheduled Import** (System Import Sets → Scheduled Imports)
2. Point to a data source (FTP, HTTP, email attachment, or MID Server file)
3. Scheduled imports reuse the existing Transform Map
4. Set frequency based on data change rate (weekly is typical for APM data)

## Data source alternatives to CSV

| Method | Best for | Notes |
|--------|----------|-------|
| CSV Upload | One-time or occasional loads | Manual, simple |
| JDBC Import Set | Direct database connection | Requires MID Server |
| REST IntegrationHub | API-driven sync | Requires IntegrationHub license |
| Excel Import | Spreadsheet users | Converts to CSV internally |
| LDAP | User/group data | Not for CMDB CIs |

---

*GetInSync NextGen exports ServiceNow-ready CSVs with pre-mapped column headers,
eliminating Transform Map guesswork. For automated sync via REST API, see the
GetInSync Enterprise tier at getinsync.ca.*
