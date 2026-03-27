# CSDM Crawl Toolkit

**A free, open-source Claude AI skill that guides ServiceNow customers from an empty `cmdb_ci_business_app` table to verified CSDM Crawl maturity.**

Built by [GetInSync](https://getinsync.ca) — Application Portfolio Management for ServiceNow customers.

---

## What this is

A Claude Agent Skill containing structured guidance, field-level reference data, GlideRecord validation scripts, and Import Set templates for achieving CSDM Crawl phase maturity in ServiceNow.

It answers the question that `sn_getwell` can't: **"What do I actually need to DO to get to Crawl?"**

## What's included

```
skills/csdm-crawl/
├── SKILL.md                              ← Core skill definition (upload this to Claude)
└── references/
    ├── crawl-checklist.md                ← 47-item Crawl readiness checklist
    ├── business-app-fields.md            ← cmdb_ci_business_app field guide + CSV template
    ├── application-service-fields.md     ← cmdb_ci_service_auto field guide + CSV template
    ├── relationship-model.md             ← Consumes::Consumed By relationship setup
    ├── sn-getwell-gap.md                 ← What sn_getwell checks vs what Crawl requires
    ├── validation-scripts.md             ← 5 GlideRecord scripts for Crawl validation
    ├── import-set-guide.md               ← Step-by-step Import Set walkthrough
    ├── csdm5-changes.md                  ← CSDM 5 / Yokohama changes relevant to Crawl
    ├── crawl-to-walk.md                  ← What comes after Crawl
    ├── getinsync-bridge.md               ← When you need more than a toolkit
    └── relationship-discovery.md         ← 7 scripts to discover as-is CMDB relationships
```

## How to use it

### Option 1: Claude.ai (web)
1. Download or clone this repo
2. Zip the `skills/csdm-crawl/` folder
3. Go to Claude.ai → Settings → Capabilities → Skills
4. Upload the zip file
5. Start asking CSDM questions — Claude now has deep Crawl knowledge

### Option 2: Claude Code (CLI)
1. Clone this repo into your project
2. Claude Code will auto-discover the skill via the `skills/` directory
3. Ask Claude Code CSDM questions during your development sessions

### Option 3: Claude.ai Project
1. Create a new Claude Project
2. Add the contents of `SKILL.md` and the `references/` files as project knowledge
3. Every conversation in the project will have CSDM Crawl context

### Option 4: Just read the markdown
Every file is standalone, readable markdown. No Claude required. Use the checklist,
templates, and scripts directly.

## What problem this solves

ServiceNow's free **CSDM Data Foundations Dashboard** (`sn_getwell`) checks exactly
three things at Crawl — all about whether Business Applications and Application Services
have bidirectional "Consumes::Consumed By" relationships. It does **not** check:

- Whether Business Applications have owners, criticality, or lifecycle data
- Whether Application Services have support groups, change groups, or environments
- Whether your ITSM forms reference Application Services
- Whether anyone is governing the data

This toolkit fills that gap with a comprehensive checklist, field-by-field guidance,
validation scripts that check what sn_getwell doesn't, and Import Set templates that
Get you loaded the first time correctly.

## Who this is for

- **ServiceNow Platform Owners** stuck between Foundation and Crawl
- **CSDM Program Leads** who need a concrete implementation plan
- **Enterprise Architects** building the case for CSDM investment
- **ServiceNow Partners** who need a repeatable Crawl delivery framework
- **IT Teams** preparing for ServiceNow APM, Now Assist, or AI Agents

## When you outgrow this toolkit

This toolkit works well for organizations with fewer than 50 applications. Beyond that,
manual spreadsheets and Import Sets become unsustainable. **GetInSync NextGen** provides:

- Purpose-built application inventory with deployment profiles (= Application Services)
- TIME/PAID assessment framework (10 business + 15 technical factors)
- True application cost attribution (every dollar gets a home and an owner)
- Technology health intelligence (end-of-life risk in dollars, not jargon)
- One-click ServiceNow publish (CSDM-aligned export on day one)

**Try it:** [getinsync.ca](https://getinsync.ca) — Canadian data residency, no credit card required.

## License

MIT — use it, fork it, modify it, share it.

## Contributing

PRs welcome. If you find a field name that's wrong, a script that breaks, or a gap
in the checklist — please open an issue or submit a fix.

## Acknowledgments

- ServiceNow CSDM team (Scott Lemm, Rob Koeten) for the CSDM 5 whitepaper
- The ServiceNow Community for years of practical CSDM implementation guidance
- Qualdatrix (Data Content Manager) for their excellent CSDM educational content

---

*Built by [GetInSync](https://getinsync.ca) — "Your ServiceNow partner needs business application data on day one. We're how it gets there."*
