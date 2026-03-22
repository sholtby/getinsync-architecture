# CSDM Relationship Model for Crawl

---

## The Crawl hierarchy

```
cmdb_ci_business_app          (Portfolio CI — "the what")
    │
    │ ── Consumes::Consumed By ──
    │
    ▼
cmdb_ci_service_auto           (Operational CI — "the where/how")
    │
    │ ── Depends on::Used by ──     ← Walk/Run phase, not required at Crawl
    │
    ▼
cmdb_ci_appl / cmdb_ci_server  (Infrastructure CIs — "the runs-on")
```

## The critical relationship: Consumes::Consumed By

| Attribute | Value |
|-----------|-------|
| Parent CI class | `cmdb_ci_business_app` |
| Child CI class | `cmdb_ci_service_auto` |
| Relationship type | Consumes::Consumed By |
| Table | `cmdb_rel_ci` |
| Type lookup | `cmdb_rel_type` where `name = 'Consumes::Consumed by'` |
| Direction | Parent (Business App) consumes Child (Application Service) |
| Cardinality | 1 Business App : many Application Services |

**Why this specific type matters:** sn_getwell checks for exactly this relationship type.
Using "Depends on::Used by" or any other type will cause sn_getwell Indicator 2 to fail.

## Creating relationships via Import Set

To bulk-create relationships, import into `cmdb_rel_ci`:

```csv
parent,child,type
SAP Finance,SAP Finance - Production,Consumes::Consumed by
SAP Finance,SAP Finance - QA,Consumes::Consumed by
Salesforce CRM,Salesforce CRM - Production,Consumes::Consumed by
```

Transform map:
- `parent` → coalesce on `cmdb_ci_business_app.name`
- `child` → coalesce on `cmdb_ci_service_auto.name`
- `type` → coalesce on `cmdb_rel_type.name`

## Creating relationships via UI

1. Open the Business Application record
2. Scroll to **Related Items** → **CI Relationships**
3. Click **New**
4. Set Type = "Consumes::Consumed by"
5. Set Configuration Item = the Application Service
6. Save

## One Business App, multiple Application Services

A Business Application may have multiple Application Services for:
- Multiple environments (Production, QA, DR)
- Multiple regions (US-East, EU-West, CA-Central)
- Multiple instances of the same software for different business units

Each Application Service gets its own support group, change group, and incident routing.
This is where the operational value lives — incidents route to the right team based on
which specific deployment is affected.

## Relationships NOT required at Crawl (but plan for Walk)

| Relationship | Between | Phase |
|-------------|---------|-------|
| Depends on::Used by | Application Service → Server/Application | Walk |
| Depends on::Used by | Application Service → Database | Walk |
| Consumes::Consumed by | Technical Service Offering → Application Service | Walk |
| Provides::Provided by | Business Service → Business Service Offering | Run |

---

*GetInSync NextGen models this relationship natively: Application = Business Application,
Deployment Profile = Application Service. The publish feature generates `cmdb_rel_ci`
records with the correct "Consumes::Consumed By" type automatically.*
