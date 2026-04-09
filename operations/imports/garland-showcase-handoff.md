# City of Garland — Showcase Demo Handoff

**Date:** April 9, 2026
**For:** Delta (Customer Success)
**Namespace:** City of Garland (`nextgen.getinsync.ca`)

---

## What's Been Loaded

21 applications across 4 workspaces, pulled from Garland's OG export and curated to demonstrate NextGen's IT Service cost model, server infrastructure tracking, cross-workspace integrations, and technology lifecycle tagging.

**This is a showcase subset** — Garland has ~370 apps total in OG. These 21 were selected to demonstrate key platform capabilities to Susan and the Garland team.

---

## Workspaces (4)

| Workspace | Apps | IT Service Spend | Leader |
|-----------|------|-----------------|--------|
| Customer Service & Utilities | 8 | $701,289 | Kevin Slay (Business Owner) |
| Finance & Budget | 4 | $351,901 | Matt Watson (Leader), Allyson BellSteadman (Budget Owner) |
| Police | 3 | $467,810 | Jeff Bryan (Leader) |
| Information Technology | 6 | $1,810,550 | Justin Fair (Leader) |
| **Total** | **21** | **$3,331,550** | |

---

## Applications by Workspace

### Customer Service & Utilities (8 apps)

| Application | Hosting | Vendor | Servers | IT Service | Annual Cost |
|------------|---------|--------|---------|-----------|------------|
| Infinity CIS | On-Prem | Advanced Utility System (AUS) | UTIL-APP3, UTIL-AVL, UTIL-BILLARCH2, UTIL-SQLDBS, UTIL-SRVLNK | AUS — Infinity CIS Platform Support | $512,996 |
| Inovah | On-Prem | System Innovators | COG-SQL16DBS, COG-SQLRS3, UTIL-INOVAH | System Innovators — Inovah Payment Platform | $84,123 |
| Selectron IVR | On-Prem | Selectron Technologies | COG-SELDB, COG-SELIVR1, COG-SELIVR2, COG-SELIVR3, COG-SELPOP, COURT-SELIVR | Selectron — IVR System License & Support | $104,170 |
| FCS - Itron | On-Prem | Itron | CGSHRDBPRDV22 | — | — |
| Service Link | On-Prem | Service-Link | UTIL-SQLDBS, UTIL-SRVLNK | — | — |
| Aperta | SaaS | Aperta | — | — | — |
| Bill Image Files | On-Prem | City of Garland | — | — | — |
| MAM File | On-Prem | City of Garland | — | — | — |

### Finance & Budget (4 apps)

| Application | Hosting | Vendor | Servers | IT Service | Annual Cost |
|------------|---------|--------|---------|-----------|------------|
| Cayenta (Finance) | On-Prem | Harris Computer Corporation | COG-LINPRT, FIN-ORADB, FIN-APP | Harris Computer — Cayenta Finance Suite | $351,901 |
| Questica | SaaS | Euna Solutions | — | — | — |
| Caseware | Desktop | CaseWare | — | — | — |
| Courts Plus | On-Prem | City of Garland | court-ifx1 | — | — |

### Police (3 apps)

| Application | Hosting | Vendor | Servers | IT Service | Annual Cost |
|------------|---------|--------|---------|-----------|------------|
| Hexagon OnCall | On-Prem | Integraph Corporation | GFD-FIRECOMM, GPD-POLICECOMM, GPD-SQLAO, GPD-SQLARC, GPD-SQLCAD1, GPD-SQLCAD2, GPD-WRMSAPP1, GPD-WRMSAPP2 | Integraph — Hexagon OnCall RMS/CAD | $467,810 |
| Eticket Citation Writer (Brazos) | On-Prem | Tyler Technology | GPD-INTERFACE | — | — |
| ProQa & Aqua | On-Prem | Priority Dispatch | GPD-PROQA | — | — |

### Information Technology (6 apps)

| Application | Hosting | Vendor | Servers | IT Service | Annual Cost |
|------------|---------|--------|---------|-----------|------------|
| Workday | SaaS | Precision Task Group | — | Precision Task Group — Workday Implementation | $1,299,416 |
| OnBase | On-Prem | Databank | COG-IMAGEWS2, IMAGE-APP3, IMAGE-APP4, IMAGE-COMP2, IMAGE-DIPPER2, IMAGE-FTS, IMAGE-SQLDBS2, IMAGE-WKFLW3, IMAGE-WKFLW4 | Databank — OnBase Managed Hosting | $398,984 |
| Genetec Video | On-Prem | Convergint Technologies | 21 servers (COG-VIDARC1 through COG-VIDWEB) | — | — |
| Nintex Sharepoint Workflow | On-Prem | Databank | COG-SPWEB | Databank — SharePoint Hosting | $112,150 |
| ArcGIS - ESRI | On-Prem | ESRI | GIS-COGMAP-WAT, GIS-COGMAP2, GIS-COGMAP4, GIS-DBS1, GIS-SQLDB, GIS-WS | — | — |
| CRM (2016) | On-Prem | — | COG-DYNAPP, COG-SQL14DBS, COG-SQLRS, DYN-WS | — | — |

---

## IT Services — Cost Model (8 services, $3.33M)

This is the showcase centerpiece. Costs flow through IT Services (vendor contracts), not through application DPs. This answers Susan's question: **"How much do we spend with each vendor?"**

| IT Service | Vendor | Annual Cost | Linked App |
|-----------|--------|------------|-----------|
| Precision Task Group — Workday Implementation | Precision Task Group | $1,299,416 | Workday |
| AUS — Infinity CIS Platform Support | Advanced Utility System | $512,996 | Infinity CIS |
| Integraph — Hexagon OnCall RMS/CAD | Integraph Corporation | $467,810 | Hexagon OnCall |
| Databank — OnBase Managed Hosting | Databank | $398,984 | OnBase |
| Harris Computer — Cayenta Finance Suite | Harris Computer Corp | $351,901 | Cayenta (Finance) |
| Databank — SharePoint Hosting | Databank | $112,150 | Nintex Sharepoint |
| Selectron — IVR System License & Support | Selectron Technologies | $104,170 | Selectron IVR |
| System Innovators — Inovah Payment Platform | System Innovators | $84,123 | Inovah |

### Vendor Consolidation Demo

The Run Rate by Vendor view automatically consolidates:
- **Databank:** $511,134 (OnBase $398,984 + SharePoint $112,150) — two services, one vendor row

---

## Integrations (16 links)

### Cross-Workspace Integrations (6) — the demo highlight

These show data flowing between departments:

| Source | Source Workspace | Target | Target Workspace | Direction |
|--------|-----------------|--------|------------------|-----------|
| OnBase | Information Technology | Cayenta (Finance) | Finance & Budget | upstream |
| OnBase | Information Technology | Eticket Citation Writer | Police | upstream |
| OnBase | Information Technology | Inovah | Customer Service & Utilities | upstream |
| Courts Plus | Finance & Budget | Eticket Citation Writer | Police | upstream |
| Courts Plus | Finance & Budget | OnBase | Information Technology | upstream |
| Selectron IVR | Customer Service & Utilities | CRM (2016) | Information Technology | downstream |

### Within-Workspace Integrations (10)

| Source | Target | Workspace | Direction |
|--------|--------|-----------|-----------|
| Bill Image Files | Inovah | Customer Service & Utilities | upstream |
| FCS - Itron | Infinity CIS | Customer Service & Utilities | upstream |
| FCS - Itron | Infinity CIS | Customer Service & Utilities | downstream |
| Inovah | Infinity CIS | Customer Service & Utilities | upstream |
| MAM File | Infinity CIS | Customer Service & Utilities | upstream |
| Selectron IVR | Infinity CIS | Customer Service & Utilities | downstream |
| Service Link | Infinity CIS | Customer Service & Utilities | downstream |
| Caseware | Questica | Finance & Budget | upstream |
| Genetec Video | Workday | Information Technology | downstream |
| Hexagon OnCall | Hexagon OnCall | Police | downstream |

**Note:** Infinity CIS is the integration hub — 6 apps feed into/out of it within Customer Service.

---

## Assessment Scores

### Technology Scores (T01-T15)

All 21 apps have partial T-scores populated (7 of 15 factors scored from OG data). Status: `in_progress`.

Scored factors: T01 (Architecture Adherence), T02 (Supportability), T03 (DBMS Adaptability), T05 (Reconstruction Effort), T07 (Interface Complexity), T09 (Technical Platforms), T10 (Compute Adaptability).

### Business Scores (B1-B10)

13 of 21 apps have full B-scores. 8 apps are `Not Started`:
- Bill Image Files, MAM File, FCS - Itron, Service Link (Customer Service)
- Courts Plus (Finance)
- Workday, CRM (2016), Nintex Sharepoint, ArcGIS - ESRI (IT)

---

## Technology Tags (Tech Health)

7 technology products tagged across DPs for the Tech Health dashboard:

| Technology | Status | Apps Using It |
|-----------|--------|--------------|
| Windows Server 2012 R2 | **EOL** | CRM (2016), ArcGIS |
| Windows Server 2012 Standard | **EOL** | Nintex Sharepoint |
| Windows Server 2016 Standard | Current | Infinity CIS, Inovah, Selectron IVR, Hexagon OnCall, ProQa & Aqua, ArcGIS |
| Windows Server 2019 Standard | Current | Cayenta, Eticket, OnBase, CRM (2016), ArcGIS |
| Windows Server 2022 Standard | Current | Infinity CIS, FCS - Itron, OnBase, Genetec Video, ArcGIS |
| Linux RHEL 6.1 | **EOL** | Cayenta |
| Linux RHEL 6.5 | **EOL** | Courts Plus |

**Demo talking point:** 4 EOL platforms flagged — CRM (2016) on Windows Server 2012 R2, Cayenta on RHEL 6.1, Courts Plus on RHEL 6.5, Nintex on Windows Server 2012 Standard.

---

## Portfolio Structure

| Workspace | Portfolios |
|-----------|-----------|
| Customer Service & Utilities | Customer Service & Utilities (root) → Utility CIS & Revenue, General |
| Finance & Budget | Finance & Budget (root) → Finance, Budget & Research, General |
| Police | Police Department (root, default) |
| Information Technology | Information Technology (root, default) |

---

## What's NOT Loaded (Future Phase 2)

- Remaining ~349 apps from OG (bulk import — separate effort)
- IT Service costs for non-showcase apps (need real contract data from Garland)
- 10 partial integrations where one end is outside the 21-app set (e.g., Cityworks)
- Projects, Programs, Ideas, Capabilities from OG (stale data — needs Garland confirmation)
- Cost Bundles (not needed for this demo)

---

## Organizations / Vendors (21)

All vendor and manufacturer orgs are loaded with contact info from OG Suppliers data (email, website, phone where available). Key vendors:

- **Advanced Utility System (AUS)** — Infinity CIS vendor + manufacturer
- **Databank** — OnBase + Nintex SharePoint hosting (vendor consolidation demo)
- **Precision Task Group** — Workday implementation partner
- **Hyland** — OnBase manufacturer (Databank is the vendor/reseller)
- **Workday** — Workday HCM manufacturer (Precision Task Group is the implementation vendor)

---

## Contacts (13)

| Contact | Role | Primary Apps |
|---------|------|-------------|
| Enterprise Services | IT Team | 10 apps (shared IT support) |
| Application Solution Services | IT Team | Bill Image Files, MAM File, Nintex |
| Infrastructure Services | IT Team | Selectron IVR |
| GIS Services | IT Team | ArcGIS |
| Mandy Harrell | — | Infinity CIS (primary) |
| Gary Cummings | — | Hexagon OnCall, Eticket, ProQa & Aqua |
| Allyson BellSteadman | Director | Caseware, Questica |
| Andrea Williams | — | Aperta, FCS-Itron, Infinity CIS, Inovah |
| Matt Watson | CFO | Workspace leader (Finance & Budget) |
| Kevin Slay | Managing Director | Workspace business owner (Customer Service) |
| Jeff Bryan | Police Chief | Workspace leader (Police) |
| Justin Fair | CIO | Workspace leader (IT) |
| Phillip Urrutia | Asst City Manager | Leadership contact (not assigned to specific workspace) |
