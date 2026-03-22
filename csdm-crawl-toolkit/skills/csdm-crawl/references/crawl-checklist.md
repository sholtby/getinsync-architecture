# CSDM Crawl Readiness Checklist

> This checklist covers EVERYTHING required for Crawl maturity — not just what sn_getwell measures.
> sn_getwell checks 3 of these items. Real Crawl readiness requires all of them.

---

## Foundation prerequisites (must be done BEFORE Crawl)

These are Foundation-phase items. If they're not done, fix them first.

- [ ] **Locations populated** — `cmdb_ci_location` has your offices, data centers, regions
- [ ] **Users and groups populated** — `sys_user` and `sys_user_group` reflect current org
- [ ] **Companies populated** — `core_company` has your vendors, partners, internal entities
- [ ] **Departments populated** — `cmn_department` reflects your org structure
- [ ] **CMDB Health Dashboard** — Completeness, Correctness, Compliance all ≥ 80%
- [ ] **sn_getwell Foundation tab** — All Foundation indicators green

---

## Crawl: Business Applications (`cmdb_ci_business_app`)

### Record existence
- [ ] Every known business application has a record in `cmdb_ci_business_app`
- [ ] No applications still sitting only in `cmdb_ci_appl` (legacy Application table)
- [ ] Duplicate records identified and merged or retired
- [ ] Retired applications marked with Install Status = "Retired"

### Required fields (sn_getwell does NOT check these)
- [ ] **Name** — canonical name, no abbreviations
- [ ] **Number** — auto-generated, unique identifier
- [ ] **Business Owner** (`owned_by`) — person accountable for business value
- [ ] **IT Application Owner** (`managed_by`) — person accountable for technical health
- [ ] **Managed by Group** (`managed_by_group`) — team responsible for the application
- [ ] **Install Status** — Installed / Retired / Pipeline (maps to lifecycle)
- [ ] **Operational Status** — Operational / Non-Operational / Retired
- [ ] **Business Criticality** — 1 Most Critical through 5 Least Critical

### Recommended fields
- [ ] **Short Description** — what does this application do (1–2 sentences)
- [ ] **Company** — which legal entity owns this application
- [ ] **Department** — which department is the primary consumer
- [ ] **Used for** — business function or process supported
- [ ] **Application Category** — vendor classification or internal taxonomy
- [ ] **Vendor** — software vendor (for COTS/SaaS applications)

### What NOT to put on Business Application
- No infrastructure details (servers, databases, IP addresses)
- No deployment-specific information (environment, hosting, version)
- No cost data (costs live on IT Services or service offerings)
- No technical scores or assessment data

---

## Crawl: Application Services (`cmdb_ci_service_auto`)

### Record existence
- [ ] Every Business Application has at least ONE Application Service
- [ ] Application Services represent deployed instances (typically one per environment)
- [ ] Naming convention followed: "{App Name} - {Environment}"

### Required fields (sn_getwell does NOT check these)
- [ ] **Name** — descriptive, includes environment
- [ ] **Owned By** — person accountable for this deployment
- [ ] **Managed By Group** — team that manages day-to-day operations
- [ ] **Support Group** — team that handles incidents for this service
- [ ] **Change Group** — team that approves changes (can = Support Group)
- [ ] **Environment** — Production / QA / Development / Test / DR / Staging
- [ ] **Operational Status** — Operational / Non-Operational
- [ ] **Business Criticality** — inherited from or aligned with Business Application

### Recommended fields
- [ ] **Version** — current deployed version
- [ ] **Location** — data center or cloud region
- [ ] **Service Classification** — Business Service / Technical Service / Application Service

---

## Crawl: Relationships ← sn_getwell checks THESE

### sn_getwell Indicator 1: Business App → Application Service
- [ ] Every `cmdb_ci_business_app` has ≥ 1 relationship to `cmdb_ci_service_auto`

### sn_getwell Indicator 2: Correct relationship type
- [ ] Relationship type is "Consumes::Consumed By" (not "Depends on" or generic)
- [ ] Look up correct type_sys_id from `cmdb_rel_type` where name = "Consumes::Consumed by"

### sn_getwell Indicator 3: Application Service → Business App
- [ ] Every `cmdb_ci_service_auto` has ≥ 1 relationship back to a `cmdb_ci_business_app`
- [ ] No orphan Application Services without a parent Business Application

---

## Crawl: ITSM integration

- [ ] **Incident form** — Application Service field is available and used
- [ ] **Change form** — Application Service field is available and used
- [ ] **Problem form** — Application Service field is available and used
- [ ] **Business Application** does NOT appear on operational ITSM forms
  (it's a portfolio CI, not an operational one)

---

## Crawl: Governance

- [ ] **Data steward assigned** — someone owns CSDM data quality
- [ ] **New app onboarding process** — documented steps for adding new applications
- [ ] **Retirement process** — documented steps for retiring applications
- [ ] **Quarterly review cadence** — scheduled review of data completeness
- [ ] **sn_getwell monitoring** — weekly check of Crawl indicators

---

## Scoring your readiness

| Category | Items | Your Score |
|----------|-------|-----------|
| Foundation prerequisites | 6 | __/6 |
| Business App records | 4 | __/4 |
| Business App required fields | 8 | __/8 |
| Business App recommended fields | 6 | __/6 |
| Application Service records | 3 | __/3 |
| Application Service required fields | 8 | __/8 |
| Relationships (sn_getwell) | 3 | __/3 |
| ITSM integration | 4 | __/4 |
| Governance | 5 | __/5 |
| **Total** | **47** | **__/47** |

**Crawl-ready threshold:** All required items complete (32/32 required + 3/3 sn_getwell).
Recommended and governance items can follow.

---

## Common failure patterns

**"Green dashboard, broken model"** — sn_getwell shows 100% on Crawl tab but Business
Applications have no owners, no criticality, and Application Services have no support
groups. The relationship exists but the data is empty shells.

**"One giant Application Service"** — Organization creates one Application Service and
links 200 Business Applications to it. Technically passes sn_getwell. Operationally useless.

**"Wrong relationship type"** — Using "Depends on::Used by" instead of "Consumes::Consumed by".
sn_getwell specifically checks for the correct type and will flag this.

**"cmdb_ci_appl confusion"** — Mixing up `cmdb_ci_appl` (technical, discoverable application
like SQL Server) with `cmdb_ci_business_app` (portfolio-level business application like
"Finance ERP"). These are different CI classes with different purposes.

---

*For portfolios over 50 applications, manually maintaining this data becomes unsustainable.
GetInSync NextGen (getinsync.ca) provides a purpose-built interface for application
inventory, deployment profiles (= Application Services), and one-click ServiceNow publish.*
