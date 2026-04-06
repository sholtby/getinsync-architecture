# COR Demo Data Reset — Design Document

**Version:** 0.2 (DRAFT — for Stuart's review before any SQL is written)
**Date:** April 5, 2026
**Purpose:** Define the complete demo dataset for the City of Riverside namespace, designed holistically against cost model v3.0 and the deployed contract-aware cost bundles architecture.

---

## 1. Design Principles

1. **Every app traces end-to-end.** Pick any app → Visual tab → see IT Services → see tech composition → see infrastructure providers. No dead ends.
2. **Cost model v3.0 only.** IT Services carry cost pools. Cost Bundles for simple costs. Software Products are inventory-only (zero cost on `deployment_profile_software_products`).
3. **No legacy fields.** Don't populate `annual_licensing_cost`, `annual_tech_cost`, or cost fields on software product junctions.
4. **Infrastructure DPs are portfolio-level.** Named infrastructure an ITSM person recognizes (SQL Cluster, Windows Server Farm, Azure Subscription) — NOT a server inventory.
5. **Realistic city gov.** On-prem Windows/SQL in a city data center, Azure hybrid for newer apps, SaaS for vendor-managed.
6. **CSDM-aligned but QuickBooks-simple.** The data tells the CSDM story without requiring the user to understand CSDM.
7. **Lifecycle data is preserved and linked.** Every tech product links to its `technology_lifecycle_reference` record so the Technology Catalog shows real vendor EOL dates (Mainstream / Extended Support / End of Support badges).
8. **Maturity levels coexist cleanly.** Some apps use Cost Bundles (Day 1 maturity — "I roughly know what I pay"). Some use IT Service allocations (Day 90 maturity — "I need to allocate shared costs"). The demo shows both paths, never mixed on the same app.

---

## 2. What Gets Deleted

**Full COR namespace reset.** DELETE in dependency order:

- `deployment_profile_it_services` (app DP → IT Service links)
- `deployment_profile_software_products` (app DP → software links)
- `deployment_profile_technology_products` (app DP → tech links)
- `it_service_technology_products` (IT Service → tech composition)
- `it_service_software_products` (IT Service → software inventory)
- `it_service_providers` (IT Service → infrastructure providers)
- `deployment_profiles` (all DPs including cost bundles and infrastructure)
- `application_integrations` (connections between apps)
- `applications` (all 76 apps)
- `it_services` (all 11 IT services)
- `software_products` (all COR software products)
- `technology_products` (all COR tech products)
- `portfolio_assignments` (all portfolio links)
- Organizations created for this demo (the d0000/d1000 series vendor orgs)

**Preserved:**
- Workspaces (18), workspace groups, namespace config
- Service type categories, technology product categories
- Data centers (City Hall Data Center)
- Reference tables (all)
- Teams, users, portfolios
- **`technology_lifecycle_reference` records (82 global records)** — these are the vendor EOL dates that power lifecycle badges. They're namespace-independent and must not be touched.

---

## 2b. Technology Lifecycle Handling

### Tech Products → Lifecycle References (PRESERVE + LINK)

The 82 `technology_lifecycle_reference` records contain real vendor data (SQL Server 2016 extended support ending July 2026, Windows Server 2022 mainstream until October 2026, etc.). When we rebuild tech products, each one must link to its matching lifecycle reference via `lifecycle_reference_id`.

| Tech Product | Version | Lifecycle Status | EOL Date |
|-------------|---------|-----------------|----------|
| Microsoft Windows Server | 2019 | Extended Support | Jan 2029 |
| Microsoft Windows Server | 2022 | Mainstream | Oct 2031 |
| Microsoft SQL Server | 2016 | Extended Support | Jul 2026 |
| Microsoft SQL Server | 2019 | Extended Support | Jan 2030 |
| Microsoft SQL Server | 2022 | Mainstream | Jan 2033 |
| Oracle Database | 19c | Extended Support | Apr 2027 |
| Red Hat Enterprise Linux | 8 | Extended Support | May 2029 |
| Microsoft IIS | 10 | Extended Support | Oct 2031 |
| Apache Tomcat | 9.0 | Mainstream | Sep 2027 |

This data tells the risk story: "SQL Server 2016 goes end-of-support in 3 months" — which is exactly what the ITSM person cares about.

### IT Service → Lifecycle Reference (REMOVE FROM MODAL)

The IT Service Modal currently has a "Technology Lifecycle" collapsible section that links a single `lifecycle_reference_id` to the IT Service itself. **Zero services use this field** and it's architecturally wrong: "SQL Server Database Services" runs both SQL Server 2019 (extended, EOL 2030) and SQL Server 2022 (mainstream, EOL 2033). Pinning one lifecycle to the service is meaningless.

**Decision:** The lifecycle risk of an IT Service should be derived from its component tech products (via the "Built on:" chips we just built). Each tech product already carries its own lifecycle badge. The IT Service inherits the *worst* lifecycle status from its components — that's a UI/reporting concern, not a data field on the IT Service.

**Code task (separate from data reset):** Remove the Technology Lifecycle section from `ITServiceModal.tsx`. The lifecycle story is told through "Built on:" → tech product → lifecycle badge. This simplifies the modal and removes a confusing field that nobody uses.

### Software Products → Lifecycle References

Some software products also link to lifecycle references. In the rebuild, we'll link software products to their lifecycle references where applicable (e.g., Dynamics GP → lifecycle data).

---

## 3. The Cast of Characters

### 3.1 Workspaces (existing — no changes)

Focus workspaces for fully wired demo data:

| Workspace | Role | App Count (target) |
|-----------|------|-------------------|
| **Information Technology** | IT shared services publisher | 6 apps |
| **Police Department** | Primary consumer — public safety | 8 apps |
| **Finance** | Consumer — back office | 4 apps |
| **Fire Department** | Consumer — public safety | 3 apps |
| **Human Resources** | Consumer — back office | 3 apps |

Remaining 13 workspaces: 0-2 apps each, lightly wired. Total target: ~35-40 apps (down from 76 — quality over quantity).

### 3.2 Vendor Organizations (COR namespace)

| Vendor | Products/Services |
|--------|-------------------|
| Microsoft | M365, Windows Server, SQL Server, Azure, Dynamics GP, SharePoint, Power Apps, IIS |
| Hexagon AB | OnCall CAD/RMS |
| Axon Enterprise | Evidence.com, Body Cameras |
| Tyler Technologies | Brazos eCitation, CopLogic, Incode Court |
| Oracle Corporation | Oracle Database |
| Broadcom (VMware) | VMware vSphere |
| Commvault Systems | Commvault Backup |
| Okta Inc. | Okta Identity |
| ServiceNow Inc. | ServiceNow ITSM |
| Esri Inc. | ArcGIS Enterprise |
| Adobe Inc. | Creative Cloud, Acrobat Pro |
| Zoom Communications | Zoom |
| Cisco Systems | Network infrastructure |
| Tenable Inc. | Nessus vulnerability scanner |
| Red Hat | RHEL |
| ManageEngine | ServiceDesk Plus |

### 3.3 IT Services (owned by Information Technology workspace)

These are the shared cost pools. Every IT Service has: name, annual cost, cost model, and at minimum one technology product and one infrastructure provider.

| # | IT Service | Category → Type | Annual Cost | Cost Model | Tech Composition | Software Provided |
|---|-----------|----------------|-------------|------------|-----------------|-------------------|
| 1 | **Windows Server Hosting** | Infrastructure → Compute | $180,000 | Per Instance | Windows Server 2019, 2022 | VMware vSphere |
| 2 | **Azure Cloud Hosting** | Infrastructure → Compute | $500,000 | Consumption | Microsoft Azure | — |
| 3 | **SQL Server Database Services** | Data → Database | $120,000 | Per Instance | SQL Server 2019, SQL Server 2022, Windows Server 2022 | — |
| 4 | **Oracle Database Services** | Data → Database | $95,000 | Per Instance | Oracle Database 19c, Red Hat Enterprise Linux 8 | — |
| 5 | **Enterprise Backup & Recovery** | Infrastructure → Storage | $142,000 | Fixed | Windows Server 2022 | Commvault |
| 6 | **Network Infrastructure** | Infrastructure → Network | $250,000 | Fixed | — | — |
| 7 | **Cybersecurity Operations** | Security → Network Security | $200,000 | Fixed | Red Hat Enterprise Linux 8 | Tenable Nessus |
| 8 | **Identity & Access Management** | Security → Identity & Access | $327,000 | Per User | — | Okta |
| 9 | **ITSM Platform** | Managed Service → Managed Service | $85,000 | Fixed | — | ServiceNow |
| 10 | **Microsoft 365 Enterprise** | Platform → Runtime/PaaS | $1,038,000 | Per User | Microsoft SharePoint Online | Microsoft 365 |
| 11 | **GIS Platform** | Platform → Runtime/PaaS | $100,000 | Per Instance | — | Esri ArcGIS Pro |
| 12 | **Collaboration & Conferencing** | Platform → Runtime/PaaS | $24,000 | Per User | — | Zoom |

### 3.4 Infrastructure DPs (owned by Information Technology workspace)

These are `dp_type = 'infrastructure'` — named infrastructure that ITSM people recognize. **This is the layer that was completely missing** and caused the confusion: IT Services existed as abstract cost pools with no physical home. The ITSM person opens "SQL Server Database Services" and sees a cost number but has no idea where it runs.

Each infrastructure DP is linked to its IT Service via `it_service_providers`. The IT Service Modal's "Link Infrastructure" section (currently empty for all services) will populate with these. The Visual tab's Level 3 blast radius can eventually trace down to these.

| # | Infrastructure DP | Environment | Hosting | Data Center | Provides IT Service |
|---|-------------------|-------------|---------|-------------|---------------------|
| 1 | **Windows Server Farm — City Hall** | PROD | On-Prem | City Hall Data Center | Windows Server Hosting |
| 2 | **SQL Server Cluster — City Hall** | PROD | On-Prem | City Hall Data Center | SQL Server Database Services |
| 3 | **Oracle RAC — City Hall** | PROD | On-Prem | City Hall Data Center | Oracle Database Services |
| 4 | **Azure Subscription — COR** | PROD | Cloud (Azure) | — | Azure Cloud Hosting |
| 5 | **Backup Infrastructure — City Hall** | PROD | On-Prem | City Hall Data Center | Enterprise Backup & Recovery |
| 6 | **Core Network — City Hall** | PROD | On-Prem | City Hall Data Center | Network Infrastructure |
| 7 | **Security Appliances — City Hall** | PROD | On-Prem | City Hall Data Center | Cybersecurity Operations |

### 3.5 Technology Products (namespace catalog)

| Tech Product | Version | Category |
|-------------|---------|----------|
| Microsoft Windows Server | 2019 | Operating System |
| Microsoft Windows Server | 2022 | Operating System |
| Red Hat Enterprise Linux | 8 | Operating System |
| Microsoft SQL Server | 2019 | Database |
| Microsoft SQL Server | 2022 | Database |
| Oracle Database | 19c | Database |
| PostgreSQL | 16 | Database |
| MySQL | 8.0 | Database |
| Microsoft Azure | — | Compute |
| Microsoft IIS | 10 | Web Server |
| Apache Tomcat | 9.0 | Web Server |
| Microsoft SharePoint | Online | Middleware |
| Microsoft Power Apps | Online | Runtime/PaaS |

### 3.6 Software Products (namespace catalog — inventory only, NO cost)

| Software Product | Manufacturer | is_org_wide | Notes |
|-----------------|-------------|-------------|-------|
| Microsoft 365 | Microsoft | YES | Org-wide license |
| Adobe Creative Cloud | Adobe Inc. | YES | Org-wide license |
| Zoom | Zoom Communications | YES | Org-wide license |
| Okta | Okta Inc. | NO | Managed via IT Service |
| ServiceNow | ServiceNow Inc. | NO | Managed via IT Service |
| VMware vSphere | Broadcom (VMware) | NO | Managed via IT Service |
| Commvault | Commvault Systems | NO | Managed via IT Service |
| Tenable Nessus | Tenable Inc. | NO | Managed via IT Service |
| Esri ArcGIS Pro | Esri Inc. | NO | Managed via IT Service |
| Hexagon OnCall CAD/RMS | Hexagon AB | NO | App-specific |
| Axon Evidence.com | Axon Enterprise | NO | App-specific |
| Microsoft Dynamics GP | Microsoft | NO | App-specific |
| Tyler Brazos eCitation | Tyler Technologies | NO | App-specific |
| Tyler CopLogic | Tyler Technologies | NO | App-specific |
| ManageEngine ServiceDesk Plus | ManageEngine | NO | App-specific |
| Flock Safety ALPR | Flock Safety | NO | App-specific |

---

## 4. Application Wiring — The 18-Year-Old Trace

### 4.1 Police Department (8 apps, all fully wired)

| App | Hosting | DP Tech Stack | IT Services (depends_on) | Software on DP |
|-----|---------|--------------|--------------------------|----------------|
| **Hexagon OnCall CAD/RMS** | On-Prem | Windows Server 2019, SQL Server 2019, IIS 10 | Windows Server Hosting, SQL Server DB Services, Enterprise Backup, Cybersecurity Ops, Network Infra, Identity & Access | Hexagon OnCall CAD/RMS |
| **Axon Evidence** | SaaS | — | Azure Cloud Hosting, Identity & Access, ITSM Platform | Axon Evidence.com |
| **Flock Safety LPR** | SaaS | — | Azure Cloud Hosting, Identity & Access | Flock Safety ALPR |
| **Brazos eCitation** | SaaS | — | Identity & Access | Tyler Brazos eCitation |
| **CopLogic Online Reporting** | SaaS | — | Identity & Access | Tyler CopLogic |
| **Computer-Aided Dispatch** | On-Prem | Windows Server 2022, SQL Server 2022 | Windows Server Hosting, SQL Server DB Services, Network Infra, Cybersecurity Ops | — |
| **NG911 System** | Hybrid | Windows Server 2022 | Azure Cloud Hosting, Network Infra, Cybersecurity Ops | — |
| **Police Records Management** | On-Prem | Windows Server 2019, SQL Server 2019 | Windows Server Hosting, SQL Server DB Services, Enterprise Backup | — |

**Pattern:** On-prem apps get Windows Server Hosting + DB Services + Backup + Cyber + Network. SaaS apps get Identity & Access (SSO via Okta). Cloud/hybrid get Azure.

### 4.2 Information Technology (6 apps)

| App | Hosting | DP Tech Stack | IT Services | Software on DP |
|-----|---------|--------------|-------------|----------------|
| **ServiceDesk Plus** | On-Prem | Windows Server 2022, MySQL 8.0, Apache Tomcat 9.0 | Windows Server Hosting, Network Infra, Cybersecurity Ops | ServiceDesk Plus |
| **Active Directory Services** | On-Prem | Windows Server 2022 | Windows Server Hosting, Network Infra | — |
| **Esri ArcGIS Enterprise** | Hybrid | Windows Server 2022, SQL Server 2022, IIS 10 | Windows Server Hosting, SQL Server DB Services, Azure Cloud Hosting, GIS Platform | Esri ArcGIS Pro |
| **PRTG Network Monitor** | On-Prem | Windows Server 2022 | Windows Server Hosting, Network Infra | — |
| **Microsoft 365** | SaaS | — | Microsoft 365 Enterprise | Microsoft 365 |
| **Hyland OnBase** | On-Prem | Windows Server 2019, SQL Server 2019, IIS 10 | Windows Server Hosting, SQL Server DB Services, Enterprise Backup | — |

### 4.3 Finance (4 apps)

| App | Hosting | DP Tech Stack | IT Services | Software on DP |
|-----|---------|--------------|-------------|----------------|
| **Microsoft Dynamics GP** | On-Prem | Windows Server 2019, SQL Server 2019 | Windows Server Hosting, SQL Server DB Services, Enterprise Backup, Identity & Access | Microsoft Dynamics GP |
| **Cayenta Financials** | On-Prem | Windows Server 2019, Oracle Database 19c | Windows Server Hosting, Oracle DB Services, Enterprise Backup | — |
| **Questica Budget** | SaaS | — | Azure Cloud Hosting, Identity & Access | — |
| **Sage 300 GL** | On-Prem | Windows Server 2019, SQL Server 2019 | Windows Server Hosting, SQL Server DB Services | — |

### 4.4 Fire Department (3 apps)

| App | Hosting | DP Tech Stack | IT Services | Software on DP |
|-----|---------|--------------|-------------|----------------|
| **Emergency Response System** | Hybrid | Windows Server 2022 | Azure Cloud Hosting, Windows Server Hosting, Network Infra, Cybersecurity Ops | — |
| **Fire Records Management** | On-Prem | Windows Server 2019, SQL Server 2019 | Windows Server Hosting, SQL Server DB Services, Enterprise Backup | — |
| **ImageTrend Elite** | SaaS | — | Azure Cloud Hosting, Identity & Access | — |

### 4.5 Human Resources (3 apps)

| App | Hosting | DP Tech Stack | IT Services | Software on DP |
|-----|---------|--------------|-------------|----------------|
| **Workday HCM** | SaaS | — | Azure Cloud Hosting, Identity & Access, ITSM Platform | — |
| **NEOGOV** | SaaS | — | Identity & Access | — |
| **Kronos Workforce Central** | On-Prem | Windows Server 2019, SQL Server 2019 | Windows Server Hosting, SQL Server DB Services, Identity & Access | — |

### 4.6 Remaining Workspaces (lightly wired, 1-2 apps each)

These get basic wiring — at least one IT Service link per app, but not the full treatment.

---

## 5. Integrations (Key Connections)

Rebuild the most important data flows between apps:

| Source App | Target App | Direction | Method | Frequency |
|-----------|-----------|-----------|--------|-----------|
| Hexagon OnCall CAD/RMS | Computer-Aided Dispatch | Bidirectional | API | Real-time |
| Hexagon OnCall CAD/RMS | Axon Evidence | Downstream | API | Real-time |
| Hexagon OnCall CAD/RMS | Flock Safety LPR | Upstream | API | Real-time |
| Microsoft Dynamics GP | Cayenta Financials | Bidirectional | Database | Batch Daily |
| ServiceDesk Plus | Active Directory Services | Upstream | SSO | Real-time |
| Emergency Response System | Computer-Aided Dispatch | Bidirectional | API | Real-time |
| NG911 System | Computer-Aided Dispatch | Downstream | API | Real-time |
| Workday HCM | Microsoft Dynamics GP | Downstream | File | Batch Daily |

---

## 6. Cost Model Maturity — Showing Both Paths

The demo must show the maturity graduation from the Contract-Aware Cost Bundles ADR. **Critical rule: never mix both paths on the same app.** An app uses Cost Bundles OR IT Service allocations, not both — to avoid triggering double-count warnings in the demo and to show the clean progression.

### Path A: Cost Bundle apps (Day 1 maturity — "I roughly know what I pay")

These apps have a Cost Bundle DP with contract details but NO IT Service allocations. This is the QuickBooks-simple path.

| App | Cost Bundle Name | Annual Cost | Vendor | Contract Ref | Contract End |
|-----|-----------------|-------------|--------|--------------|-------------|
| Axon Evidence | Axon Evidence SaaS License | $120,000 | Axon Enterprise | AXN-2025-003 | 2028-01-15 |
| Flock Safety LPR | Flock Safety Annual License | $48,000 | Flock Safety | FS-2024-112 | 2027-03-31 |
| Brazos eCitation | Tyler Brazos SaaS | $18,000 | Tyler Technologies | TYL-2024-007 | 2026-09-30 |
| ImageTrend Elite | ImageTrend Annual SaaS | $35,000 | ImageTrend | IMG-2025-001 | 2027-12-31 |
| Workday HCM | Workday Enterprise License | $95,000 | Workday | WD-2024-456 | 2027-06-30 |

### Path B: IT Service apps (Day 90 maturity — "I need to allocate shared costs")

These apps have IT Service allocations (via `deployment_profile_it_services`) but NO Cost Bundles. Cost comes from the IT Service cost pool.

All Police on-prem apps (Hexagon, CAD, Police Records), IT apps (ServiceDesk Plus, ArcGIS, OnBase), Finance apps (Dynamics GP, Cayenta, Sage 300), Fire on-prem apps — these use the IT Service path.

### The Demo Conversation

"See how Axon Evidence just has a simple $120K license cost with a contract date? That's all you need on Day 1. Now look at Hexagon OnCall — that one depends on 6 shared IT Services (hosting, database, backup, security, network, identity). The cost comes from those service pools, allocated across everyone who uses them. When you're ready to mature from Axon's simple model to Hexagon's detailed model, you graduate from Cost Bundles to IT Services."

---

## 7. Verification Checklist (the 18-year-old test)

After data is loaded, verify each trace:

1. **Pick Hexagon OnCall CAD/RMS** → Visual tab Level 3 → see 6 IT Services at bottom with tech count pills → IT Service Catalog → expand "SQL Server Database Services" → see "Built on: SQL Server 2019, SQL Server 2022, Windows Server 2022" → see infrastructure provider "SQL Server Cluster — City Hall"

2. **Pick Axon Evidence (SaaS)** → Visual tab → see Azure Cloud Hosting + Identity & Access → IT Service Catalog → see infrastructure "Azure Subscription — COR"

3. **Software Catalog** → All products grouped by manufacturer → No "No Manufacturer" group → Org-wide badges on M365, Adobe CC, Zoom

4. **Technology Catalog** → SQL Server 2019 → "Powers: SQL Server Database Services" → deployments: Hexagon, CAD, Police Records, Dynamics GP, Fire Records, Kronos

5. **IT Service Catalog** → Every service has: tech composition chips, at least one consumer app, infrastructure provider linked

6. **Cost dashboard** → IT Service costs flow through to app DPs → Cost Bundles show separately → Double-count warning fires if both exist on same app

---

## 8. Open Questions for Stuart

1. **App count:** Target is ~35-40 apps across 18 workspaces. The 5 focus workspaces get full wiring. Should the remaining workspaces get 0, 1, or 2 apps each?

2. **Integrations:** Should we rebuild all 19 existing integrations or start with the ~8 key ones listed above?

3. **Portfolios:** Do we need portfolio assignments (cost allocation %) on DPs, or is that a separate data exercise?

4. **Cost Bundle amounts:** The $485K on Hexagon's Cost Bundle — should that be the real-ish app cost, or should it be lower to not conflict with IT Service allocations?

5. **Teams:** Should we populate the teams table (from CSDM Export Readiness) with demo teams, or leave that for later?
