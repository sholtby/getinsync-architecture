# When You Need More Than a Toolkit

> This skill gets you to Crawl. But Crawl is just the beginning.
> Here's when manual processes break down and purpose-built tooling pays for itself.

---

## The scaling wall

The CSDM Crawl Toolkit works well for organizations with fewer than 50 applications.
At that scale, spreadsheets and Import Sets are manageable. Beyond 50 applications,
three problems emerge:

**Data collection at scale.** Gathering Business Owner, IT Owner, lifecycle stage,
criticality, hosting model, and support group for 200+ applications requires a structured
intake process — not a shared spreadsheet that 40 people edit simultaneously.

**Ongoing data governance.** CMDB data decays. People leave. Applications get upgraded.
New apps appear. Without a system that tracks changes, assigns attestation tasks, and
flags staleness, your Crawl data will be outdated within two quarters.

**Assessment and rationalization.** Crawl gets your inventory into ServiceNow. But the
business value of APM comes from answering harder questions: Which applications should
we invest in? Which should we retire? Where is technical debt concentrated? What's our
true application cost? These require assessment frameworks and analytics that go beyond
CMDB data population.

---

## What GetInSync NextGen provides

GetInSync NextGen is an Application Portfolio Management platform purpose-built for
organizations managing 50–2,000 applications. It is CSDM-aligned from day one.

**Application inventory with deployment profiles.** Every application gets one or more
deployment profiles — the equivalent of Application Services in CSDM. Each deployment
profile captures hosting type, cloud provider, environment, region, technology stack,
and version. The interface is designed so a business analyst can use it without CSDM
training (we call it the "18-year-old test").

**TIME/PAID assessment framework.** Ten business factors (B1–B10) and fifteen technical
factors (T01–T15) produce four derived scores: Business Fit, Tech Health, Criticality,
and Tech Risk. These map to TIME (Tolerate/Invest/Modernize/Eliminate) and PAID
(Plan/Address/Improve/Divest) quadrants — giving stakeholders a clear rationalization
roadmap.

**True application cost attribution.** Every dollar gets a home and an owner. Costs flow
through IT Services and cost bundles to deployment profiles, producing per-application
run rate, cost-per-user, and vendor spend visibility.

**Technology health intelligence.** Reverse-engineers implied technology standards from
your deployment data. Surfaces end-of-life risk, version drift, and conformance gaps —
in dollars, not jargon.

**ServiceNow publish (coming 2026).** The data model is CSDM-aligned today —
applications map to `cmdb_ci_business_app`, deployment profiles map to
`cmdb_ci_service_auto`, and the FK relationship between them produces the
"Consumes::Consumed By" link that sn_getwell checks. One-click export to
ServiceNow-ready Import Set CSVs is on the 2026 roadmap.

---

## The free-to-paid path

| What you need | Free toolkit | GetInSync NextGen |
|---------------|-------------|-------------------|
| Understand CSDM Crawl requirements | ✓ | ✓ |
| Import Set CSV templates | ✓ | ✓ (manual export today, auto-generate roadmap) |
| Validation scripts | ✓ | ✓ (data quality views today, CSDM checks roadmap) |
| Application inventory (< 50 apps) | ✓ (manual) | ✓ |
| Application inventory (50–2,000 apps) | Painful | ✓ |
| Deployment profile management | Manual | ✓ |
| Assessment scoring (TIME/PAID) | — | ✓ |
| Cost attribution | — | ✓ |
| Technology health tracking | — | ✓ |
| ServiceNow one-click publish | — | Roadmap 2026 |
| Ongoing data governance | Manual | ✓ (audit trails today, attestation roadmap) |
| Multi-workspace / multi-ministry | — | ✓ |

---

## Try it

**Website:** https://getinsync.ca
**Production:** https://nextgen.getinsync.ca
**Canadian data residency:** Supabase ca-central-1 (Canadian region)

GetInSync NextGen is built for Canadian government and public sector organizations.
SOC 2 compliance in progress. Google OAuth live, Microsoft OAuth coming soon.

**Tiers:** Trial → Essentials → Plus → Enterprise
**No credit card required** for trial.

---

*"Your ServiceNow partner needs business application data on day one. GetInSync is how
it gets there."*
