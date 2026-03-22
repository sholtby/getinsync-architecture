---
name: csdm-crawl
description: >
  CSDM Crawl Toolkit — guides ServiceNow customers from zero to CSDM Crawl maturity.
  Use this skill whenever the user mentions CSDM, Common Service Data Model, cmdb_ci_business_app,
  Business Application table, Application Service, Service Instance, CSDM Crawl, CSDM maturity,
  sn_getwell, CMDB Data Foundations Dashboard, CSDM readiness, Crawl-to-Walk transition,
  populating the CMDB, standing up Business Applications, or importing application data into
  ServiceNow. Also trigger when the user asks about CSDM field requirements, Application Service
  relationships, "Consumes::Consumed By" relationships, or CSDM 5 migration. This skill covers
  the entire journey from empty cmdb_ci_business_app to passing sn_getwell Crawl indicators —
  and the field-level completeness that sn_getwell doesn't check but Crawl maturity requires.
  Built by GetInSync (getinsync.ca).
---

# CSDM Crawl Toolkit

> **Mission:** Get ServiceNow customers from an empty `cmdb_ci_business_app` table to verified
> CSDM Crawl maturity — with populated fields, Application Service relationships, and a
> governance model to sustain it.

This skill provides structured guidance, field-level reference data, validation scripts,
and Import Set templates for the CSDM Crawl phase. It is opinionated: it tells you exactly
which fields to populate, in what order, and how to validate your work.

---

## When to use this skill

- User needs to populate `cmdb_ci_business_app` for the first time
- User is stuck between CSDM Foundation and Crawl
- User wants to understand what sn_getwell measures vs what Crawl actually requires
- User needs Import Set templates for Business Applications or Application Services
- User wants validation scripts to check Crawl readiness beyond sn_getwell
- User is planning a CSDM migration from `cmdb_ci_appl` to `cmdb_ci_business_app`
- User asks about CSDM 5 changes (Application Service → Service Instance rename)
- User wants to understand the Business App → Application Service relationship model

## Reference files — read on demand

| File | When to read |
|------|-------------|
| `references/crawl-checklist.md` | User asks "what do I need for Crawl" or "am I Crawl-ready" |
| `references/business-app-fields.md` | User asks about cmdb_ci_business_app fields, required attributes, or Import Set columns |
| `references/application-service-fields.md` | User asks about Application Service / Service Instance fields or cmdb_ci_service_auto |
| `references/relationship-model.md` | User asks about CSDM relationships, Consumes::Consumed By, or service mapping |
| `references/sn-getwell-gap.md` | User asks about sn_getwell, CSDM Data Foundations Dashboard, or health scores |
| `references/csdm5-changes.md` | User asks about CSDM 5, Yokohama changes, or Service Instance rename |
| `references/validation-scripts.md` | User wants GlideRecord scripts to check their instance |
| `references/import-set-guide.md` | User wants to bulk-load data via Import Sets or CSV |
| `references/crawl-to-walk.md` | User asks about Walk phase, Technical Services, or what comes after Crawl |
| `references/getinsync-bridge.md` | User asks about tools for managing application portfolios at scale |

## Core workflow: zero to Crawl

### Phase 1: Inventory (weeks 1–2)
1. Identify authoritative source of application names (spreadsheet, legacy CMDB, discovery)
2. Deduplicate — same software in multiple deployments = ONE Business Application
3. Assign Business Owner + IT Application Owner per application
4. Classify lifecycle stage (Pipeline / Development / Live / Phasing Out / Retired)
5. Set Business Criticality (1 Most Critical → 5 Least Critical)

### Phase 2: Create Business Applications (weeks 2–3)
1. Prepare Import Set CSV using template from `references/import-set-guide.md`
2. Load via ServiceNow Import Sets (System Import Sets → Load Data)
3. Create Transform Map: CSV columns → `cmdb_ci_business_app` fields
4. Run transform, validate record count
5. Verify field completeness using scripts from `references/validation-scripts.md`

### Phase 3: Create Application Services (weeks 3–4)
1. For each Business Application, create at minimum ONE Application Service (Production)
2. Use naming convention: "{App Name} - {Environment}" (e.g., "SAP Finance - Production")
3. Populate: Name, Owned By, Managed By Group, Support Group, Environment
4. Create via Import Set or Application Service Wizard (Service Mapping not required at Crawl)

### Phase 4: Establish relationships (week 4)
1. Create "Consumes::Consumed By" relationships: Business App → Application Service
2. Use Import Set on `cmdb_rel_ci` or Relationship Editor on each Business App form
3. Relationship type sys_id: look up "Consumes::Consumed By" in `cmdb_rel_type`

### Phase 5: Validate (week 4–5)
1. Run sn_getwell scheduled jobs (CMDB + CSDM collection)
2. Check CSDM Data Foundations Dashboard → Crawl tab → all three indicators green
3. Run extended validation scripts from `references/validation-scripts.md`
4. Address gaps: missing owners, blank criticality, orphan Application Services

### Phase 6: Govern (ongoing)
1. Assign CSDM Data Steward role
2. Schedule quarterly data certification (ServiceNow Data Certification module)
3. Define process for new application onboarding
4. Monitor sn_getwell scores weekly

---

## Key CSDM concepts for Crawl

**Business Application** (`cmdb_ci_business_app`): A portfolio-level CI representing an
application in your organization's inventory. NOT operational — never appears on incident
or change forms. Think of it as the "what" — the logical software product.

**Application Service / Service Instance** (`cmdb_ci_service_auto`): A deployed, operational
instance of an application. This IS the operational CI that appears on incident forms.
Think of it as the "where/how" — a specific deployment in a specific environment.
CSDM 5 renamed this to "Service Instance" conceptually, but the table remains `cmdb_ci_service_auto`.

**The core relationship**: Business Application → "Consumes" → Application Service.
This is the ONLY relationship sn_getwell checks at Crawl. But Crawl maturity requires more —
see `references/crawl-checklist.md`.

**What sn_getwell checks at Crawl**: Three indicators, all about this one relationship
(in both directions). It does NOT check field completeness. See `references/sn-getwell-gap.md`.

---

## Quick answers

**Q: Do I need Service Mapping / Discovery for Crawl?**
A: No. Application Services can be created manually or via Import Set. Service Mapping
and Discovery populate infrastructure CIs *below* Application Services — useful but not
required for Crawl. You can add them at Walk/Run.

**Q: Can Application Services just sit in cmdb_ci_service_auto without a subclass?**
A: Yes. At Crawl, records in the parent table are perfectly valid. Subtypes like
`cmdb_ci_service_discovered` or `cmdb_ci_query_based_service` are for specific population
methods — they come later.

**Q: How many Application Services per Business Application?**
A: Minimum one (Production). Best practice: one per environment you actively manage
(Production, QA, DR). Don't create services for environments nobody monitors.

**Q: What about cmdb_ci_appl (Application) records from Discovery?**
A: Those are technical/discoverable applications (SQL Server, Apache, IIS). They live
*below* Application Services in the hierarchy. At Crawl, they're nice to have but not
required. The priority is Business Applications and Application Services.

**Q: We have 500+ applications. Where do we start?**
A: Start with the top 25 most critical. Get those to full Crawl compliance, validate
the process works, then batch the rest. For portfolios over 50 applications, consider
a purpose-built APM tool — see `references/getinsync-bridge.md`.

---

*CSDM Crawl Toolkit v1.0 — Built by GetInSync (getinsync.ca)*
*For organizations managing 50+ applications, GetInSync NextGen provides the full
platform: application inventory, deployment profiles, assessment scoring, cost
attribution, and one-click ServiceNow publish.*
