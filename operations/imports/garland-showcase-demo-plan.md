# City of Garland — Showcase Demo Import Plan

**Version:** 1.0
**Date:** 2026-03-16
**Purpose:** Hand-curated import of ~25 Garland apps across 4 workspaces to demonstrate NextGen's full data model — IT Service cost channels, cross-workspace integrations, server infrastructure, and technology tagging.
**Audience:** Claude Code (execution), Stuart (review), Delta (Garland liaison)

---

## Overview

This is NOT a bulk import. This is a curated showcase demo that models Garland's data **the right way** — showing Susan at Garland what NextGen can do when costs flow through proper IT Service channels, not flat estimates on DPs.

**What gets created:**
- 1 Namespace: "City of Garland"
- 4 Workspaces (mapped from OG Areas, not person-named portfolios)
- 21 Applications with primary Deployment Profiles
- ~8 IT Services with vendor attribution and DP allocations (the cost model showcase)
- ~12 Organizations (vendors/manufacturers)
- Software Product + Technology Product catalog entries
- Server names on DPs
- 33 integration links (cross-workspace dependencies)
- B1–B10 and T01–T15 assessment scores
- Portfolio hierarchy within each workspace

**What does NOT get created:**
- `dp.annual_cost` on application DPs — stays at 0 (dead field for application DPs)
- `dp.annual_licensing_cost` / `dp.annual_tech_cost` — stays at 0 (costs live on IT Services)
- Cost Bundles — not needed for this demo
- Projects, Programs, Ideas, Capabilities — stale data, deferred

---

## Task Boundaries

- **Claude Code:** Generate SQL scripts as output files. DO NOT execute SQL. DO NOT modify any existing production data.
- **Stuart:** Reviews SQL, runs in Supabase SQL Editor chunk by chunk per development-rules.md §2.1.
- **Schema changes:** NONE. This import uses existing tables only.

---

## Phase 1: Namespace & Workspaces

### 1.1 Namespace

```
Name: "City of Garland"
Region: 'ca'
Tier: 'enterprise'
```

The namespace trigger `create_default_assessment_factors` will auto-fire and seed default B1–B10 / T01–T15 factors.

### 1.2 Workspaces (4)

OG uses person-named portfolios ("Asst City Manager - Andy Hesser") as its org structure. NextGen uses workspaces for org boundaries. We map OG **Areas** (department names) to workspaces.

| Workspace | OG Area Source | Apps | Total Cost | Demo Purpose |
|-----------|---------------|------|-----------|--------------|
| Customer Service & Utilities | Customer Service | 8 | ~$763K | Integration hub, utility billing |
| Finance & Budget | Finance, Budget & Research | 4 | ~$538K | Cross-workspace dependencies |
| Police | Police Department | 3 | ~$498K | High-value on-prem, server farms |
| Information Technology | Information Technology | 6 | ~$2.2M | Shared services, vendor consolidation |

### 1.3 Workspace Users

Create a namespace admin user for Delta to access the demo:
- Email: `delta@getinsync.ca` (or whatever Delta's account is)
- Namespace role: admin
- Added to all 4 workspaces as admin

---

## Phase 2: Organizations (Vendors & Manufacturers)

Create these organizations from OG `Suppliers.json`. Use the Excel export (`suppliers.xlsx`) for address fields where available.

| Organization | is_vendor | is_manufacturer | Referenced By |
|---|---|---|---|
| Advanced Utility System (AUS) | ✅ | ✅ | Infinity CIS |
| System Innovators | ✅ | — | Inovah |
| Itron | ✅ | — | FCS - Itron |
| Selectron Technologies, Inc. | ✅ | — | Selectron IVR |
| Harris Computer Corporation | ✅ | — | Cayenta |
| Euna Solutions (formerly Questica) | ✅ | — | Questica |
| CaseWare | ✅ | ✅ | Caseware |
| City of Garland | ✅ | ✅ | Courts Plus, Bill Image Files, MAM File, etc. |
| Integraph Corporation | ✅ | — | Hexagon OnCall |
| Tyler Technology | ✅ | — | Eticket Citation Writer |
| Priority Dispatch | ✅ | ✅ | ProQa & Aqua |
| Databank | ✅ | — | OnBase, Nintex SharePoint |
| Hyland | — | ✅ | OnBase (manufacturer) |
| Precision Task Group | ✅ | — | Workday |
| Workday | — | ✅ | Workday (manufacturer) |
| Convergint Technologies | ✅ | — | Genetec Video |
| ESRI | ✅ | — | ArcGIS |
| Aperta | ✅ | ✅ | Aperta |
| Service-Link | ✅ | ✅ | Service Link |

Populate from `suppliers.xlsx`: name, website, email, phone, address_line1, address_city, address_region, address_country, address_postal.

Set `owner_workspace_id` = Information Technology workspace for shared vendors, or the relevant workspace for single-department vendors.

---

## Phase 3: Software Product Catalog

Create catalog entries for the software products these apps represent. These are namespace-scoped.

| Software Product | Manufacturer Org | Category | License Type |
|---|---|---|---|
| Infinity CIS | Advanced Utility System | platform | subscription |
| Inovah | System Innovators | other | subscription |
| Itron FCS | Itron | other | subscription |
| Selectron IVR | Selectron Technologies | other | subscription |
| Cayenta Finance | Harris Computer Corporation | platform | subscription |
| Questica Budget | Euna Solutions | saas | subscription |
| CaseWare Working Papers | CaseWare | other | perpetual |
| Courts Plus | City of Garland | other | other |
| Hexagon OnCall RMS/CAD | Integraph Corporation | platform | subscription |
| Brazos eCitation | Tyler Technology | other | subscription |
| ProQa & Aqua | Priority Dispatch | other | subscription |
| Hyland OnBase | Hyland | platform | subscription |
| Workday HCM | Workday | saas | subscription |
| Genetec Security Center | Convergint Technologies | platform | subscription |
| Microsoft Dynamics CRM 2016 | (Microsoft — create if needed) | platform | perpetual |
| Nintex Workflow | (Nintex — create if needed) | plugin | subscription |
| ArcGIS | ESRI | platform | subscription |

Link each to the corresponding app's DP via `deployment_profile_software_products`:
- `vendor_org_id` = the vendor org (who Garland buys from — may differ from manufacturer)
- Leave `annual_cost` NULL on the junction (costs live on IT Services, not here)
- Set `cost_confidence` = 'estimated'

---

## Phase 4: Technology Product Catalog

Create technology product entries for the platforms found on Garland's servers. These feed the Tech Health dashboard and lifecycle intelligence.

| Technology Product | Category | Product Family |
|---|---|---|
| Windows Server 2012 R2 | Operating System | Windows Server |
| Windows Server 2012 Standard | Operating System | Windows Server |
| Windows Server 2016 Standard | Operating System | Windows Server |
| Windows Server 2019 Standard | Operating System | Windows Server |
| Windows Server 2022 Standard | Operating System | Windows Server |
| Linux Red Hat Enterprise 6.1 | Operating System | Red Hat Enterprise Linux |
| Linux Red Hat 6.5 | Operating System | Red Hat Enterprise Linux |

Check if these already exist in the namespace's technology product catalog before creating. If the demo namespace is new, they won't exist yet.

Link to DPs via `deployment_profile_technology_products` based on the server platform data:

| DP (App) | Technology Product | Edition |
|---|---|---|
| Infinity CIS | Windows Server 2016 Standard | Standard |
| Infinity CIS | Windows Server 2022 Standard | Standard |
| Inovah | Windows Server 2016 Standard | Standard |
| FCS - Itron | Windows Server 2022 Standard | Standard |
| Selectron IVR | Windows Server 2016 Standard | Standard |
| Cayenta (Finance) | Windows Server 2019 Standard | Standard |
| Cayenta (Finance) | Linux Red Hat Enterprise 6.1 | — |
| Courts Plus | Linux Red Hat 6.5 | — |
| Hexagon OnCall | Windows Server 2016 Standard | Standard |
| Eticket Citation Writer | Windows Server 2019 Standard | Standard |
| ProQa & Aqua | Windows Server 2016 Standard | Standard |
| OnBase | Windows Server 2019 Standard | Standard |
| OnBase | Windows Server 2022 Standard | Standard |
| Genetec Video | Windows Server 2022 Standard | Standard |
| CRM (2016) | Windows Server 2012 R2 | — |
| CRM (2016) | Windows Server 2019 Standard | Standard |
| Nintex SharePoint | Windows Server 2012 Standard | Standard |
| ArcGIS - ESRI | Windows Server 2012 R2 | — |
| ArcGIS - ESRI | Windows Server 2016 Standard | Standard |
| ArcGIS - ESRI | Windows Server 2019 Standard | Standard |
| ArcGIS - ESRI | Windows Server 2022 Standard | Standard |

---

## Phase 5: Applications & Deployment Profiles

### 5.1 Workspace: Customer Service & Utilities

| Application | DP hosting_type | server_name | Vendor Org |
|---|---|---|---|
| Infinity CIS | On-Prem | UTIL-APP3, UTIL-AVL, UTIL-BILLARCH2, UTIL-SQLDBS, UTIL-SRVLNK | Advanced Utility System |
| Inovah | On-Prem | COG-SQL16DBS, COG-SQLRS3, UTIL-INOVAH | System Innovators |
| FCS - Itron | On-Prem | CGSHRDBPRDV22 | Itron |
| Selectron IVR | On-Prem | COG-SELDB, COG-SELIVR1, COG-SELIVR2, COG-SELIVR3, COG-SELPOP, COURT-SELIVR | Selectron Technologies |
| Service Link | On-Prem | UTIL-SQLDBS, UTIL-SRVLNK | Service-Link |
| Bill Image Files | On-Prem | (none) | City of Garland |
| MAM File | On-Prem | (none) | City of Garland |
| Aperta | SaaS | (none) | Aperta |

### 5.2 Workspace: Finance & Budget

| Application | DP hosting_type | server_name | Vendor Org |
|---|---|---|---|
| Cayenta (Finance) | On-Prem | COG-LINPRT, FIN-ORADB, FIN-APP | Harris Computer Corporation |
| Questica | SaaS | (none) | Euna Solutions |
| Caseware | Desktop | (none) | CaseWare |
| Courts Plus | On-Prem | court-ifx1 | City of Garland |

### 5.3 Workspace: Police

| Application | DP hosting_type | server_name | Vendor Org |
|---|---|---|---|
| Hexagon OnCall | On-Prem | GFD-FIRECOMM, GPD-POLICECOMM, GPD-SQLAO, GPD-SQLARC, GPD-SQLCAD1, GPD-SQLCAD2, GPD-WRMSAPP1, GPD-WRMSAPP2 | Integraph Corporation |
| Eticket Citation Writer (Brazos) | On-Prem | GPD-INTERFACE | Tyler Technology |
| ProQa & Aqua | On-Prem | GPD-PROQA | Priority Dispatch |

### 5.4 Workspace: Information Technology

| Application | DP hosting_type | server_name | Vendor Org |
|---|---|---|---|
| OnBase | On-Prem | COG-IMAGEWS2, IMAGE-APP3, IMAGE-APP4, IMAGE-COMP2, IMAGE-DIPPER2, IMAGE-FTS, IMAGE-SQLDBS2, IMAGE-WKFLW3, IMAGE-WKFLW4 | Databank |
| Workday | SaaS | (none) | Precision Task Group |
| Genetec Video | On-Prem | COG-VIDARC1, COG-VIDARC10, COG-VIDARC11, COG-VIDARC12, COG-VIDARC13, COG-VIDARC14, COG-VIDARC15, COG-VIDARC16, COG-VIDARC2, COG-VIDARC3, COG-VIDARC4, COG-VIDARC5, COG-VIDARC6, COG-VIDARC7, COG-VIDARC8, COG-VIDARC9, COG-VIDAPP, COG-VIDDIR1, COG-VIDDIR2, COG-VIDSQL, COG-VIDWEB | Convergint Technologies |
| CRM (2016) | On-Prem | COG-DYNAPP, COG-SQL14DBS, COG-SQLRS, DYN-WS | (none) |
| Nintex Sharepoint Workflow | On-Prem | COG-SPWEB | Databank |
| ArcGIS - ESRI | On-Prem | GIS-COGMAP-WAT, GIS-COGMAP2, GIS-COGMAP4, GIS-DBS1, GIS-SQLDB, GIS-WS | ESRI |

### 5.5 DP Common Fields

For ALL 21 DPs:
- `is_primary`: true
- `dp_type`: 'application'
- `environment`: 'PROD'
- `operational_status`: 'operational'
- `annual_cost`: 0 (costs live on IT Services)
- `annual_licensing_cost`: 0
- `annual_tech_cost`: 0
- `cost_recurrence`: 'recurring'

---

## Phase 6: IT Services — The Cost Model Showcase

This is the heart of the demo. Each IT Service represents a real vendor relationship with cost, contract lifecycle, and allocation to DPs.

### 6.1 IT Services to Create

| IT Service Name | Vendor Org | annual_cost | Linked DPs | Allocation |
|---|---|---|---|---|
| AUS — Infinity CIS Platform Support | Advanced Utility System | $512,996 | Infinity CIS | fixed: 512996 |
| System Innovators — Inovah Payment Platform | System Innovators | $84,123 | Inovah | fixed: 84123 |
| Selectron — IVR System License & Support | Selectron Technologies | $104,170 | Selectron IVR | fixed: 104170 |
| Harris Computer — Cayenta Finance Suite | Harris Computer Corporation | $351,901 | Cayenta (Finance) | fixed: 351901 |
| Integraph — Hexagon OnCall RMS/CAD | Integraph Corporation | $467,810 | Hexagon OnCall | fixed: 467810 |
| Databank — OnBase Managed Hosting | Databank | $398,984 | OnBase | fixed: 398984 |
| Databank — SharePoint Hosting | Databank | $112,150 | Nintex SharePoint | fixed: 112150 |
| Precision Task Group — Workday Implementation | Precision Task Group | $1,299,416 | Workday | fixed: 1299416 |

**Total modeled through IT Services: ~$3.3M** (the top-spend apps)

### 6.2 IT Service Fields

For each IT Service:
- `namespace_id`: Garland namespace
- `owner_workspace_id`: the workspace that manages the vendor relationship (usually IT for shared, or the department for dedicated)
- `lifecycle_state`: 'active'
- `cost_model`: 'fixed' (for now — these are annual contract estimates)

### 6.3 IT Service → Software Product Links

Link each IT Service to the Software Product it covers via `it_service_software_products`:

| IT Service | Software Product |
|---|---|
| AUS — Infinity CIS Platform Support | Infinity CIS |
| System Innovators — Inovah Payment Platform | Inovah |
| Harris Computer — Cayenta Finance Suite | Cayenta Finance |
| Integraph — Hexagon OnCall RMS/CAD | Hexagon OnCall RMS/CAD |
| Databank — OnBase Managed Hosting | Hyland OnBase |
| Precision Task Group — Workday Implementation | Workday HCM |

### 6.4 IT Service → DP Links (dp_it_services)

For each link in the table above:
- `allocation_basis`: 'fixed'
- `allocation_value`: the dollar amount from the IT Service
- This makes `vw_deployment_profile_costs.service_cost` populate correctly

### 6.5 Demo Highlight: Vendor Consolidation

After import, `vw_run_rate_by_vendor` will show:
- **Databank**: $511,134 (OnBase $398,984 + Nintex SharePoint $112,150) — two IT Services, one vendor row
- **Precision Task Group**: $1,299,416
- **Advanced Utility System**: $512,996

This answers Susan's question: **"How much do we spend with Databank?"**

---

## Phase 7: Assessment Scores

### 7.1 Technology Scores (on DPs)

Map OG tech question answers to NextGen T-factors. OG uses a weighted 0-10 scale; NextGen uses 1-5 integers.

**OG → NextGen T-factor mapping:**

| OG Question (QuestionId) | Attribute | NextGen Column |
|---|---|---|
| 1f2b4ad8-c383-476a-9488-a3f019cb9047 | Adherence to Architecture | t01 |
| 2d505302-650a-4af1-be35-0309ba3114da | Technical Platforms / Products | t09 |
| 68a586f0-bb74-4e47-840f-d42263fa644c | DBMS Adaptability | t03 |
| 6d404eb4-fcc2-4238-9c4b-95e6cecda298 | Compute Adaptability | t10 |
| 07084a5a-6724-4530-9874-10a5eb36cc66 | Complexity of Interfaces | t07 |
| 0dd639e2-7ee2-4431-90fb-9e4b0b1c7f88 | Supportability | t02 |
| 99ea8652-a73e-44ed-9267-67ded13ef126 | Reconstruction Efforts | t05 |

**Score conversion:** OG records `AnswerValue` on `ApplicationQuestionAnswers` (where `PortfolioId IS NULL` = tech answers). The answer options are 1.0–5.0 on the non-cost questions. However, OG also stores weighted values (0–10 scale). Use the raw `AnswerValue` from the `QuestionAnswers` reference table matching via `QuestionAnswerId`, not the weighted value. ROUND to integer.

**Cost questions (ONGOING-*):** Skip entirely. Do not map to T-scores or cost fields.

**Unmapped T-factors (will be NULL):** t04, t06, t08, t11, t12, t13, t14, t15.

Set `tech_assessment_status`:
- 'in_progress' if any T-scores populated
- 'not_started' if all NULL

### 7.2 Business Scores (on Portfolio Assignments)

Map OG business question answers to NextGen B-factors on `portfolio_assignments`.

**OG → NextGen B-factor mapping:**

| OG Attribute | NextGen Column |
|---|---|
| Strategic Support Capabilities | b1 |
| Geographical Impact | b2 |
| Competitive Advantage | b3 |
| Financial/Business Impact | b4 |
| Business Process Operation | b5 |
| Business Interruption Tolerance | b6 |
| Decision Support | b7 |
| Current Needs (1-2 yrs) | b8 |
| Future Needs (3-5 yrs) | b9 |
| User Satisfaction | b10 |

**Resolution path:** `ApplicationQuestionAnswers` (where `PortfolioId IS NOT NULL`) → join to `AccountQuestions` (maps QuestionId to PortfolioId) → join to `Questions` (get Attribute name) → match Attribute to B-factor above.

**Score conversion:** Same as tech — raw AnswerValue from answer options (1.0–5.0), ROUND to integer.

Set `business_assessment_status`:
- 'in_progress' if any B-scores populated
- 'Not Started' if all NULL

---

## Phase 8: Portfolios

Create portfolio hierarchy within each workspace. Use OG Depth 2–3 portfolios (the department-level ones), not Depth 0–1 (person-named).

### Customer Service & Utilities Workspace

| Portfolio | Parent | Source (OG) |
|---|---|---|
| Customer Service & Utilities | (root, is_default=true) | — |
| Utility CIS & Revenue | root | OG "Customer Service - Utility CIS & Revenue" |

Assign apps: Infinity CIS, Inovah, FCS - Itron, Service Link, Bill Image Files, MAM File → Utility CIS & Revenue. Selectron IVR, Aperta → root.

### Finance & Budget Workspace

| Portfolio | Parent |
|---|---|
| Finance & Budget | (root, is_default=true) |
| Finance | root |
| Budget & Research | root |

Assign: Cayenta → Finance. Questica, Caseware → Budget & Research. Courts Plus → root.

### Police Workspace

| Portfolio | Parent |
|---|---|
| Police Department | (root, is_default=true) |

All 3 apps → root portfolio.

### Information Technology Workspace

| Portfolio | Parent |
|---|---|
| Information Technology | (root, is_default=true) |

All 6 apps → root portfolio.

---

## Phase 9: Integrations

Map all 33 OG `ApplicationIntegrations` where both source and target are in our 21-app showcase set. For integrations where one end is outside our set, still create them with the app we have — the other end will be populated when the bulk import happens later.

**Direction mapping:**
- OG "Publish" → NextGen `direction` = 'downstream'
- OG "Subscribe" → NextGen `direction` = 'upstream'
- OG "" (blank) → NextGen `direction` = 'bidirectional'

**Key cross-workspace integrations to highlight:**

| Source (Workspace) | Target (Workspace) | Direction |
|---|---|---|
| Cayenta Finance (Finance) | Cityworks (not in demo) | upstream |
| OnBase (IT) | Cayenta Finance (Finance) | upstream |
| OnBase (IT) | Inovah (Cust Service) | upstream |
| OnBase (IT) | Eticket (Police) | upstream |
| Courts Plus (Finance) | OnBase (IT) | upstream |
| Courts Plus (Finance) | Eticket (Police) | upstream |
| Selectron IVR (Cust Service) | Infinity CIS (Cust Service) | downstream |
| Selectron IVR (Cust Service) | CRM 2016 (IT) | downstream |
| FCS - Itron (Cust Service) | Infinity CIS (Cust Service) | downstream |
| Inovah (Cust Service) | Infinity CIS (Cust Service) | upstream |

---

## Phase 10: Contacts

Create contacts from OG `Contacts.json` for contacts referenced by our 21 apps.

Contacts appearing in the data:
- **Enterprise Services** — generic team name (map as internal contact)
- **Application Solution Services** — generic team name
- **Infrastructure Services** — generic team name
- **GIS Services** — generic team name
- **Mandy Harrell** — Infinity CIS contact
- **Gary Cummings** — Police apps contact
- **Allyson BellSteadman** — Budget apps contact

Create as `contacts` with:
- `namespace_id` = Garland namespace
- `contact_category` = 'internal'
- `primary_workspace_id` = most relevant workspace

Link via `application_contacts` with `role_type` = 'technical_owner' (default — OG doesn't distinguish well).

---

## SQL Script Structure

Generate these files, each as a separate SQL script per development-rules.md §2.1:

```
sql/01-namespace-workspace.sql      — Namespace, workspaces, workspace_users
sql/02-organizations.sql            — Vendor/manufacturer orgs
sql/03-software-product-catalog.sql — Software product entries + categories
sql/04-technology-product-catalog.sql — Technology products + categories
sql/05-contacts.sql                 — Contact records
sql/06-applications.sql             — 21 applications
sql/07-deployment-profiles.sql      — 21 primary DPs with hosting, server_name, vendor_org_id
sql/08-dp-software-products.sql     — DP → Software Product junction
sql/09-dp-technology-products.sql   — DP → Technology Product junction (tags)
sql/10-it-services.sql              — 8 IT Services with cost, vendor
sql/11-dp-it-services.sql           — DP → IT Service allocation links
sql/12-it-service-software-products.sql — IT Service → Software Product links
sql/13-portfolios.sql               — Portfolio hierarchy per workspace
sql/14-portfolio-assignments.sql    — App/DP → Portfolio with B1–B10 scores
sql/15-tech-scores.sql              — T01–T15 scores on DPs
sql/16-integrations.sql             — Application integrations
sql/17-application-contacts.sql     — Contact assignments
sql/99-validation.sql               — Post-import validation queries
```

Each script:
- Starts with a comment block (record count, source, purpose)
- Uses pre-generated UUIDs with `-- OG ID: xxx` comments for traceability
- Chunks INSERTs at 50 rows max per statement
- Ends with a validation query

### Execution Order Dependencies

```
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08, 09, 10 → 11, 12 → 13 → 14 → 15 → 16 → 17
```

Scripts 08/09/10 can run in parallel (all depend on 07). Scripts 11/12 depend on 10.

---

## Validation Checklist (sql/99-validation.sql)

```sql
-- 1. Record counts
SELECT 'namespaces' AS entity, count(*) FROM namespaces WHERE name = 'City of Garland';
SELECT 'workspaces' AS entity, count(*) FROM workspaces w JOIN namespaces n ON n.id = w.namespace_id WHERE n.name = 'City of Garland';
SELECT 'applications' AS entity, count(*) FROM applications a JOIN workspaces w ON w.id = a.workspace_id JOIN namespaces n ON n.id = w.namespace_id WHERE n.name = 'City of Garland';
SELECT 'deployment_profiles' AS entity, count(*) FROM deployment_profiles dp JOIN workspaces w ON w.id = dp.workspace_id JOIN namespaces n ON n.id = w.namespace_id WHERE n.name = 'City of Garland';
SELECT 'it_services' AS entity, count(*) FROM it_services its JOIN namespaces n ON n.id = its.namespace_id WHERE n.name = 'City of Garland';
SELECT 'organizations' AS entity, count(*) FROM organizations o JOIN namespaces n ON n.id = o.namespace_id WHERE n.name = 'City of Garland';

-- 2. Cost model validation — the key test
SELECT 'run_rate_by_vendor' AS test, vendor_name, cost_channel, total_cost
FROM vw_run_rate_by_vendor
WHERE namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
ORDER BY total_cost DESC;

-- 3. Dashboard summary — should show $0 for total_annual_cost (costs are on IT Services, not DPs)
SELECT total_annual_cost, total_applications, total_dps
FROM vw_dashboard_summary
WHERE namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland');

-- 4. DP costs — should show service_cost populated, bundle_cost = 0
SELECT dp.name, dpc.service_cost, dpc.bundle_cost, dpc.total_cost
FROM vw_deployment_profile_costs dpc
JOIN deployment_profiles dp ON dp.id = dpc.deployment_profile_id
WHERE dpc.application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN namespaces n ON n.id = w.namespace_id
  WHERE n.name = 'City of Garland'
)
ORDER BY dpc.total_cost DESC;

-- 5. Server names populated
SELECT dp.name, dp.server_name, dp.hosting_type
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland' AND dp.server_name IS NOT NULL;

-- 6. Technology tags
SELECT a.name AS app, tp.name AS tech_product, dptp.edition
FROM deployment_profile_technology_products dptp
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland'
ORDER BY a.name, tp.name;

-- 7. Cross-workspace integrations
SELECT sa.name AS source, ta.name AS target, ai.direction,
       sw.name AS source_ws, tw.name AS target_ws
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
JOIN applications ta ON ta.id = ai.target_application_id
JOIN workspaces sw ON sw.id = sa.workspace_id
JOIN workspaces tw ON tw.id = ta.workspace_id
JOIN namespaces n ON n.id = sw.namespace_id
WHERE n.name = 'City of Garland';
```

---

## Source Data Files

Claude Code will need access to these JSON files from the OG export:

- `Applications.json` — app records (filter to the 21 showcase apps by ApplicationId)
- `ApplicationQuestionAnswers.json` — assessment answers
- `Questions.json` — question definitions (for attribute mapping)
- `QuestionAnswers.json` — answer option definitions
- `AccountQuestions.json` — portfolio-scoped question config
- `ApplicationIntegrations.json` — integration links
- `ApplicationITServices.json` — app-to-IT-service links (for server names)
- `ITServices.json` — IT service records (for server name strings)
- `ITServiceComputingTypes.json` — computing type classification
- `ITServicePlatforms.json` — platform/OS on servers
- `RefComputingTypes.json` — computing type reference
- `RefPlatforms.json` — platform reference
- `ApplicationContacts.json` — contact assignments
- `Contacts.json` — contact records
- `Suppliers.json` — vendor/manufacturer records
- `suppliers.xlsx` — enriched supplier data with addresses
- `PortfolioApplications.json` — portfolio assignments (for B-scores)
- `Portfolios.json` — portfolio hierarchy
- `ApplicationHostingTypes.json` — hosting type assignments
- `RefHostingTypes.json` — hosting type reference

---

## Known Gaps & Future Work

| Gap | Resolution | When |
|---|---|---|
| Remaining 343 apps not in showcase | Phase 2 bulk import (separate prompt) | After demo approval |
| IT Services for non-showcase apps | Delta + Garland build with real contract data | Post-onboarding |
| 166 unclassified OG IT Services | AI classification → Delta review | Phase 2 |
| Projects (144) and Programs (10) | Stale — confirm with Garland before importing | TBD |
| Capabilities (91) | No NextGen target yet | Deferred |
| `vw_dashboard_summary.total_annual_cost` shows $0 | Known — this view reads `dp.annual_cost` which we leave at 0. Run rate views show correct IT Service costs. Dashboard view may need future update to include IT Service channel. | Open item |
| OG person-named portfolios | Not imported — replaced by workspace structure. Full portfolio hierarchy rebuild in Phase 2. | Phase 2 |

---

## Rollback Plan

All data is scoped to the "City of Garland" namespace. To rollback:

```sql
-- DANGER: This deletes ALL Garland demo data
DELETE FROM namespaces WHERE name = 'City of Garland';
-- CASCADE will handle all child tables
```

Verify cascade covers: workspaces, applications, deployment_profiles, portfolios, portfolio_assignments, it_services, organizations, contacts, all junction tables.
