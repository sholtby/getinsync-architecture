# Server Name Test Plan — City of Riverside

**Version:** 1.0
**Date:** March 19, 2026
**Status:** 🟡 READY TO EXECUTE
**Feature:** `server_name` field on deployment profiles (inline edit + modal edit + autocomplete)

---

## Context

Server name edit field is live on deployment profiles (On-Prem, Hybrid, Third-Party-Hosted, Cloud). All 88 Riverside profiles currently have NULL server_name. Manually populate realistic server names to validate: inline edit, modal edit, autocomplete suggestions, conditional visibility, filtering, CSV export, and Global Search.

## Riverside Data Summary

| Hosting Type | Count | Server Name Visible? |
|---|---|---|
| On-Prem | 27 | YES |
| SaaS | 36 | NO |
| NULL (not set) | 16 | NO (field hidden) |
| Cloud | 4 | YES |
| Hybrid | 3 | YES |
| Third-Party-Hosted | 1 | YES |
| Desktop | 1 | NO |

**35 profiles** can have server names entered.

---

## Recommended Test Data — 10 Apps to Populate

Enter these server names to create a realistic demo with autocomplete overlap and variety across all 4 eligible hosting types.

### On-Prem (6 apps — core municipal systems on city servers)

| App | Server Name | Why |
|---|---|---|
| **Cayenta Financials** | `PROD-FIN-01` | Core ERP — obvious on-prem server |
| **Great Plains ERP** | `PROD-FIN-01` | **Same server** — tests autocomplete + co-location |
| **Hyland OnBase** | `PROD-ECM-01` | Document management — separate server |
| **Genetec Security Center** | `PROD-SEC-01` | Physical security — isolated infra |
| **Tyler Incode Court** | `PROD-COURTS-01` | Court system — compliance-isolated |
| **ServiceDesk Plus** | `PROD-ITSM-01` | IT service desk |

### Hybrid (2 apps)

| App | Server Name | Why |
|---|---|---|
| **Esri ArcGIS Enterprise** | `PROD-GIS-01` | Classic hybrid — on-prem server + cloud services |
| **NG911 System** | `PROD-911-01` | Emergency — dedicated infra |

### Cloud (1 app)

| App | Server Name | Why |
|---|---|---|
| **Emergency Response System** | `PROD-ERS-EC2-01` | EC2 instance — validates cloud hosting scenario |

### Third-Party-Hosted (1 app)

| App | Server Name | Why |
|---|---|---|
| **Grant Management Portal** | `VENDOR-GRANTS-01` | Vendor-managed — different naming convention |

---

## Test Script

### Test 1: Inline Edit on DP Card
1. Navigate to **Cayenta Financials** → Deployments tab
2. Expand the On-Prem deployment profile card
3. Confirm **Server Name** field visible with placeholder "e.g. PROD-SQL-01"
4. Type `PROD-FIN-01` → click away (blur)
5. **Expected:** Saves silently, field shows value
6. Refresh page — value persists

### Test 2: Autocomplete Suggestions
1. Navigate to **Great Plains ERP** → Deployments tab
2. In Server Name field, type `PROD`
3. **Expected:** Datalist shows `PROD-FIN-01` (from Cayenta)
4. Select it → blur
5. **Expected:** Two apps now share a server name

### Test 3: Modal Edit
1. On any On-Prem app, open the DP edit modal
2. Confirm Server Name field appears after DR Status
3. Enter a value → Save
4. **Expected:** Modal closes, card reflects value

### Test 4: Conditional Visibility — Hosting Types
1. **SaaS app** → Server Name field NOT shown
2. **Cloud app** (Emergency Response System) → Server Name field IS shown
3. **NULL hosting type app** → Server Name field NOT shown
4. **Desktop app** → Server Name field NOT shown

### Test 5: Hosting Type Toggle
1. Open a SaaS app's DP modal → change hosting type to On-Prem
2. **Expected:** Server Name field appears
3. Change back to SaaS
4. **Expected:** Field disappears

### Test 6: Cloud Server (EC2 Scenario)
1. Navigate to **Emergency Response System** (Cloud / AWS)
2. Confirm Server Name visible alongside Cloud Provider + Region
3. Enter `PROD-ERS-EC2-01` → save
4. **Expected:** Saves correctly

### Test 7: Filtering / Reports
1. Go to App Health or Tech Health reports
2. Check if server_name appears as filter/column
3. If filterable — filter by `PROD-FIN-01`, expect 2 apps

### Test 8: CSV Export
1. Export infrastructure report to CSV
2. Confirm `server_name` column populated for edited apps

### Test 9: Global Search
1. Type `PROD-FIN-01` in Global Search
2. **Expected:** Cayenta Financials and Great Plains ERP appear

### Test 10: Clear Value
1. Go to any app with server name populated
2. Clear field completely → blur
3. **Expected:** Saves as NULL, shows placeholder

---

## What Makes This Good Demo Data

- **Shared server** (PROD-FIN-01 on 2 apps) — autocomplete + co-location story
- **Varied naming** — `PROD-*`, `VENDOR-*`, `*-EC2-*` — realistic municipal IT
- **All 4 hosting types** covered
- **Cross-department** — Finance, GIS, Courts, Security, Emergency, IT
- **10 of 35 eligible** — enough to demo without clutter

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-19 | Initial test plan. 10 test scripts, 10 apps across 4 hosting types. City of Riverside namespace. |
