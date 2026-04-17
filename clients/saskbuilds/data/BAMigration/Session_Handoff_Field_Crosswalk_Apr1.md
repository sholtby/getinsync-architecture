# Session Handoff — Field Crosswalk: CJIMS BA Migration
## April 1, 2026

---

## Context for Next Session

Stuart is preparing for the SaskBuilds April 1 CSDM Crawl workshop. This session focused entirely on Priority 1 from the previous handoff: Leanne's field-level crosswalk (cmdb_ci_appl → cmdb_ci_business_app).

---

## What Was Accomplished This Session

### Deliverables Produced

1. **ServiceNow_Field_Crosswalk_BA_Migration.xlsx** — 5-tab workbook:
   - **Field Crosswalk** — 69 fields from the CJIMS cmdb_ci_appl form, each with: row #, form section, field label, ServiceNow field name, current table, custom flag, disposition (color-coded), target BA field, data type, CJIMS example value, plain-English description, reports using the field, migration notes
   - **Screen Map 1** — Stuart's annotated screenshot (top of form) with numbered pins + matching field data rows beneath (12pt, 21 rows)
   - **Screen Map 2** — Stuart's annotated screenshot (middle of form) with numbered pins + matching field data rows beneath (12pt, 36 rows)
   - **Summary** — Disposition counts: ~35 map to BA, ~12 stay on cmdb_ci_appl, ~10 custom (SaskBuilds), ~7 not applicable, 2 new for Crawl
   - **Report Impact** — All 10 Power BI reports ranked by migration impact (By Ministry = HIGH, By DB/By OS = NONE)

2. **Teams DM to Darwin** — Sent via MS Teams asking 3 questions:
   - Is ministry modeled as `company` or `department` in their instance?
   - Confirm actual `u_` field names for the 10 custom fields
   - Confirm the Application_Ministry M2M table name

3. **Annotated screenshots** (4 PNGs) — Pin numbers color-coded by disposition (green=maps to BA, yellow=stays, purple=custom, grey=N/A). Stuart took these, improved the pin styling/positioning, and inserted them into the workbook himself.

### Key Decisions / Findings

- **10 custom (u_) fields identified:** u_ministry, u_application_coordinator, u_support_staff, u_offered_to_clients, u_deployment_method, u_who_provisions_access, u_is_two_factor_auth, u_local_admin_required, u_notes, plus the Application_Ministry M2M table
- **Ministry field mapping is the biggest decision** — drives the By Ministry and For Ministry by App reports. Depends on whether SaskBuilds models ministries as `core_company` records or `cmn_department` records. Darwin's answer will resolve this.
- **Application Coordinator → it_application_owner** was the recommended mapping (only mandatory BA field), but `application_manager` is an alternative if coordinator is more operational than strategic
- **CJIMS chosen as example application** — rich data (4 ministries, 40+ URLs, named people, real operational status), good showcase of multi-ministry complexity

### Stuart's Knowledge Notes

- Stuart asked for and received an explanation of company vs department in ServiceNow (organizational hierarchy levels). He's using Claude as a knowledge centre and wants to understand everything before presenting it as his own work. If he asks "explain X to me" in future sessions, give the full picture — he's building his ServiceNow fluency.

---

## What Needs to Happen Next

### Immediate — Awaiting Darwin's Response
- Darwin's reply to the Teams DM will confirm: (a) u_ field names, (b) ministry→company or department, (c) M2M table name
- Once received, update the crosswalk workbook with actual field names and lock the ministry mapping decision

### Priority 2: 47-Item Crawl Checklist Gap Analysis
Cross-reference the curated 490-app list metadata against the 47-item Crawl checklist. The CSDM_Field_CrossReference_Apr1_Workshop.xlsx has the 50 fields × 10 reports matrix.

### Priority 3: Import Set Templates
Build three CSV templates for ServiceNow Import Sets:
- CSV 1: cmdb_ci_business_app (490 rows)
- CSV 2: cmdb_ci_service_auto (~550 rows)
- CSV 3: cmdb_rel_ci Consumes::Consumed by (~550 rows)
The csdm-crawl-import-templates.xlsx already has the structure with CJIMS as example row — needs to be populated with full data.

### Priority 4: Architecture Reconciliation
Claude Code completed the reconciliation report (confirmed at session start). Review it.

### Remaining from Previous Handoff
- Priority 5: Thank Joseph Salazar (still pending)

---

## Key Files

| File | Location | Purpose |
|---|---|---|
| ServiceNow_Field_Crosswalk_BA_Migration.xlsx | Stuart's local (he edited/enhanced it) | The main deliverable — 5 tabs, annotated screenshots embedded |
| CSDM_Field_CrossReference_Apr1_Workshop.xlsx | Uploaded this session | 50 fields × 10 reports matrix (input to crosswalk) |
| csdm-crawl-import-templates.xlsx | Uploaded this session | Import Set template with CJIMS example row |
| csdm-data-dictionary.html | Uploaded this session | 124 BA + 99 AP field reference from erm4sn.com |
| SNOW_Field_Mapping_1.png / _2.png | Stuart's annotated versions (uploaded back) | The improved pin screenshots he inserted into the workbook |

---

## Chinese Wall Reminder
All crosswalk work is SaskBuilds EA hat. No GetInSync product references in any materials shared with Leanne, Darwin, or the workshop participants. The field crosswalk is a ServiceNow migration planning document, not a GetInSync feature.
