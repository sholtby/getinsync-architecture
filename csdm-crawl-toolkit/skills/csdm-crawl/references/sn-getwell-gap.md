# What sn_getwell Measures vs What Crawl Requires

> The CMDB and CSDM Data Foundations Dashboard (sn_getwell) is a free ServiceNow Store app.
> It is useful but dangerously incomplete for Crawl validation.

---

## The Crawl tab: exactly three indicators

The sn_getwell CSDM Data Foundations Dashboard → Crawl tab checks exactly three things:

| # | Indicator | What it checks | Result table |
|---|-----------|---------------|-------------|
| 1 | Business App with App Service Relationship | Does each `cmdb_ci_business_app` have ≥ 1 CI relationship to `cmdb_ci_service_auto`? | `sn_getwell_biz_app_missing_app_svc` |
| 2 | App Service with correct relationship type | Is the relationship type "Consumes::Consumed By" (not some other type)? | `sn_getwell_app_svc_incorrect_biz_app_rel` |
| 3 | App Service with Business App relationship | Does each `cmdb_ci_service_auto` have ≥ 1 relationship back to a `cmdb_ci_business_app`? | `sn_getwell_app_svc_missing_biz_app` |

That is the complete Crawl measurement scope.

## What sn_getwell does NOT check

| Gap | Why it matters |
|-----|---------------|
| Field completeness on Business Applications | A Business App with only a name and no owner, criticality, or lifecycle is useless |
| Field completeness on Application Services | An Application Service with no support group cannot receive incidents |
| Owner fields populated | Nobody is accountable for data quality |
| Business Criticality set | Cannot prioritize incident response or change risk |
| Environment field on Application Services | Cannot distinguish Production from Dev |
| Support Group on Application Services | Incidents cannot be routed |
| Change Group on Application Services | Change risk assessment is blind |
| Infrastructure CIs below Application Services | No visibility into what runs the service |
| ITSM form configuration | Incident/Change/Problem forms may not reference Application Services |
| Data governance process | No ongoing maintenance = data decay in 6 months |

## The dangerous scenario: 100% green, 0% useful

An organization can achieve 100% on all three sn_getwell Crawl indicators by:
1. Creating one `cmdb_ci_business_app` per application (name only, all other fields blank)
2. Creating one `cmdb_ci_service_auto` per application (name only, all other fields blank)
3. Creating "Consumes::Consumed By" relationships between them

Result: Three green indicators. Zero operational value. Incidents can't route. Changes
can't assess risk. Nobody owns anything. The CMDB is technically "Crawl" but functionally
empty.

## Complementary dashboards

**CMDB Health Dashboard** (built-in, not sn_getwell) provides CI-level quality scoring:
- **Completeness** (34% weight) — checks required/recommended fields per CI class
- **Correctness** (33% weight) — checks orphans, stale CIs, duplicates
- **Compliance** (33% weight) — checks field values against Desired State audits

This dashboard DOES check field-level completeness, configured through CI Class Manager.
Use it alongside sn_getwell to get a fuller picture.

**How to configure:** Navigate to CI Class Manager → select `cmdb_ci_business_app` →
set Required Fields (owned_by, managed_by_group, busines_criticality) → CMDB Health
Dashboard will then include these in Completeness scoring.

## The real Crawl test

Instead of trusting sn_getwell alone, validate with these questions:

1. Can a service desk agent create an incident and select the correct Application Service?
2. Does that Application Service have a support group so the incident auto-routes?
3. Can a change manager assess risk by seeing which Business Applications are affected?
4. Can a CIO pull a report showing all applications, their owners, and criticality?
5. Is there a human being who will notice and fix it when data goes stale?

If the answer to any of these is "no," you're not at Crawl — regardless of what the
dashboard says.

---

*The validation scripts in `references/validation-scripts.md` check the gaps sn_getwell
misses. For automated, ongoing data quality monitoring across your full application
portfolio, see GetInSync NextGen at getinsync.ca.*
