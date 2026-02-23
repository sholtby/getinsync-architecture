# GetInSync NextGen: The Why Behind the What (v1.7 Additions)

## Changes from v1.6 → v1.7


**New Section 11:** Data Governance & User Engagement  
**Updated Section 12:** Competitive Advantages — added Data Governance nugget  
**Updated Summary Table:** Added new rows for data quality and user adoption  
**Updated Related Documents:** Added gamification architecture document  

---

## Changes from v1.5 → v1.6

**New Section 9:** Technology Health & Lifecycle Intelligence  
**New Section 10:** Risk Detection (and What We Don't Build)  
**Updated Section 6a:** CSDM Challenge — added crawl-to-walk gap and economic buyer  
**Updated Section 8:** Market Positioning — sharpened persona and trigger events  
**Updated Section 12:** Competitive Advantages — added Technology Health nugget  
**Updated Summary Table:** Added new rows for technology tracking and risk boundary  
**Updated Related Documents:** Added new architecture documents

---

## 9. Technology Health & Lifecycle Intelligence

### What Was Broken

**Technology tracking didn't exist.** Legacy GetInSync had no way to record what technology an application runs on. You could assess an app's business fit and technical health through questionnaires, but you couldn't answer the most basic infrastructure question: "What operating system? What database? What version? Is it still supported?"

**Organizations maintained this in spreadsheets.** One customer pulled 8 spreadsheets from ServiceNow's CMDB, manually joined them, and built a Power BI dashboard with 15 dropdown filters to track OS/DB/Web lifecycle stages across 479 applications. Another maintained a SharePoint risk register with 131 entries ‗ 80% of which just said "this app runs on end-of-life technology."

**The CSDM crawl-to-walk gap.** Every organization we talk to has the same story. They bought ServiceNow, Discovery is running, and the CMDB is full of servers, databases, and network gear. But when they try to move from crawl to walk ‗ from infrastructure CIs to business applications ‗ everything stalls. Because that step requires *human judgment*. Discovery can find that SQL Server 2016 is running on SKGOVW072P. It can't tell you that server supports the Graduate Retention Program, that three ministries depend on it, that it's a Crown Jewel, or that it costs $240K a year. That context lives in people's heads, in spreadsheets, and in SharePoint lists that are 93% stuck in Draft. So they extract data into spreadsheets, build Power BI dashboards, and maintain risk registers that nobody actions ‗ all because there's no structured place to do the curation work between "what Discovery found" and "what the business needs to know."

**That's the gap we fill.** GetInSync is where `cmdb_ci_appl` becomes `cmdb_ci_business_app` ‗ where discovered technology gets linked to business context, assessed, costed, and made ready for ServiceNow APM. Weeks, not months. And in the meantime, they get portfolio intelligence they've never had: lifecycle risk dashboards, blast radius analysis, and cost attribution ‗ from the same data they were manually cross-referencing in spreadsheets.

### How We Fixed It

**Two-path technology model.** Technology products relate to deployments through two parallel paths:

```
PATH 1: INVENTORY (Simple ‗ all tiers)
DP → deployment_profile_technology_products → Technology Product
     (version, notes ‗ NO cost columns)

Purpose: "What technology does this run on?"
Feeds:   Lifecycle dashboard, EOL alerts, tech health reports

PATH 2: COST & BLAST RADIUS (Structured ‗ Enterprise tier)
DP → IT Service → it_service_technology_products → Technology Product
     (cost allocation)  (cost pool)  (relationship type)

Purpose: "What shared service provides this, what does it cost,
          and who else depends on it?"
```

**Path 1 is the QuickBooks entry point.** An 18-year-old intern picks SQL Server 2019 from a catalog and tags it on a deployment. Done. No understanding of IT Services required. No organizational prerequisites. This immediately feeds the Technology Health dashboard.

**Path 2 is the CSDM maturity layer.** When Central IT is ready to define shared services, allocate costs, and track blast radius, the IT Service model is there. But it's not a prerequisite ‗ it's a graduation.

**Key design rule:** Path 1 has NO cost columns. Technology tagging is inventory. Cost flows through the three established channels (Software Product, IT Service, Cost Bundle). This prevents technology tagging from becoming a shadow fourth cost channel.

**The reconciliation bridge.** The system shows users where they are on the maturity journey:

```
SQL Server 2019 ‗ 15 deployments tagged
◜◀◀ 8 linked via "Database Hosting" service → $65,000 allocated
◗◀◀ 7 tagged directly (no cost attribution yet)
    ◗◀◀ [Link to existing service] or [Add Cost Bundle]
```

No scolding. No blocking. Just helpful nudges from flat inventory to structured CSDM alignment.

**Technology Health Dashboard.** A new top-level navigation page showing:
- Summary KPIs: Total apps, Crown Jewels, EOL count, Extended Support count, Mainstream count
- Technology layer breakdown: OS versions + lifecycle, DB versions + lifecycle, Web versions + lifecycle  
- Lifecycle status distribution (pie/donut chart)
- Workspace (ministry) breakdown
- Filterable application infrastructure table

This replaces Power BI dashboards built from spreadsheet extracts with a native, structured, real-time view that requires zero maintenance.

**Progressive maturity:**

| Level | What the user does | What they see |
|-------|-------------------|---------------|
| 1. Inventory | Tags technology on deployments | Lifecycle dashboard, EOL alerts |
| 2. Services | Creates IT Services, assigns technology | Service catalog with tech composition |
| 3. Attributed | Links deployments to IT Services | Blast radius + cost allocation |
| 4. Reconciled | System flags gaps between direct tags and service links | Full CSDM alignment |

**Technology Lifecycle Intelligence.** AI-powered lookup of vendor support dates. User tags "SQL Server 2016" ‗ we look up Microsoft's published lifecycle page and auto-populate: Mainstream ended Oct 2021, Extended Support ends Jul 2026, End of Life. Eliminates the manual lifecycle research that makes spreadsheets stale on day two.

**Server names are CMDB territory.** We explicitly do not track server hostnames, IP addresses, vulnerability counts, or server hardware details. Those are infrastructure CIs maintained by ServiceNow Discovery. Our abstraction level is: Application → Deployment Profile (environment + hosting + technology tags) → IT Service. We tell you "15 deployments use SQL Server 2016 in production." Discovery tells you which specific servers are involved. Together, the complete picture. Separately, each still valuable.

---

## 10. Risk Detection (and What We Don't Build)

### What Was Broken

**Risk registers lived in SharePoint.** One customer had 131 cyber risk entries in Microsoft Lists. 93% were stuck in "Draft" lifecycle stage. 93% were "Not Mitigated." 80% of the risk descriptions said the same thing: "EOL DB, OS." Someone was manually looking up what technology each app runs on, checking if it's still supported, and typing that finding into SharePoint. That's not a risk management problem ‗ it's a data problem.

### How We Fixed It

**Computed risk indicators, not a risk register.** When technology is tagged on a deployment profile and lifecycle data shows end-of-life, the system automatically flags the risk:

| Lifecycle Status | Risk Level | Badge |
|-----------------|------------|-------|
| End of Life / End of Support | Critical | 🗴 |
| Extended, EOL < 6 months | High | ðŸŸÂ  |
| Extended, EOL < 12 months | Medium | 🟡 |
| Mainstream | None | 🟢 |
| No lifecycle data | Unknown | ⚪ |

This appears as a risk badge on deployment profiles, a risk column in the Technology Health dashboard, and summary KPIs: "47 deployments on EOL technology across 31 applications."

**Blast radius for risk.** When a technology product's lifecycle changes (SQL Server 2016 moves to EOL), every deployment tagged with it is automatically flagged:

```
SQL Server 2016 ‗ END OF LIFE
◜◀◀ 15 deployment profiles affected
◜◀◀ 12 unique applications
◜◀◀ 6 workspaces (ministries)
◜◀◀ 4 Crown Jewel applications
◗◀◀ [View affected applications]
```

That's the query a SharePoint list can never answer.

### What We Explicitly Don't Build

**Risk registers are GRC territory.** We do not build risk acceptance workflows, TRA tracking, Risk Notice Memos, or remediation lifecycle management. Those belong in purpose-built GRC tools (ServiceNow GRC, Archer, LogicGate, OneTrust).

| We Build (APM) | They Build (GRC) |
|----------------|-------------------|
| Technology inventory + lifecycle status | Risk acceptance letters |
| Computed risk indicators | Risk remediation workflow |
| Blast radius analysis | TRA tracking + document links |
| Data classification on applications | Compliance evidence management |
| Auto-generated findings | Audit response workflow |

**The one-liner: "We detect the risks. GRC tools manage the response."**

**The integration story:** GetInSync feeds GRC tools. Our CSDM-aligned application data, technology tags, and computed risk indicators export cleanly as the context that GRC workflows reference. When they get ServiceNow GRC, our Business Application CIs are what the risk entries link to.

---

## 11. Data Governance & User Engagement

### What Was Broken

**Portfolio data goes stale.** Every APM tool has the same failure mode: someone loads 400 applications into a spreadsheet, spends three months enriching the data, uploads it, and then nobody touches it again. Six months later, the portfolio is 30% wrong — owners have moved, applications have been decommissioned, new deployments went live, and licensing changed. The data was accurate for exactly one day: the day it was imported.

**Nobody fills in the tool.** Government organizations in particular struggle with getting staff to complete assessments. The assessment questionnaire sits untouched because there's no feedback loop — no visibility into what's changed, no recognition for completing work, and no mechanism for the person who *notices* a problem to tell the person who *can fix it*. The result: a subset of power users maintains data for 400 applications while 50 registered users log in once and never return.

**The person who notices ≠ the person who fixes.** A Finance analyst reviewing a portfolio report sees that an application's owner retired six months ago. But the analyst can't fix it — they don't have edit permissions, and even if they did, they don't know the correct replacement. So they do nothing. The data stays wrong. Multiply by hundreds of applications across dozens of workspaces, and you get portfolio decay.

### How We Fixed It

**Three interlocking mechanisms** that create a self-sustaining data governance cycle:

```
ACHIEVEMENTS reward completing work
    ↓ drives action
FLAGS surface what needs fixing
    ↓ creates accountability
ACTIVITY FEED provides context
    ↓ brings people back
    → which earns more ACHIEVEMENTS
```

**Data quality flags.** Any user can raise a lightweight contextual flag on any entity — "wrong owner," "stale data," "planned change," "missing info." The system auto-assigns it to the entity's business or technical owner from existing contact roles. Four states: open → acknowledged → resolved/dismissed. Resolution time tracked. No SLAs, no escalation, no approval workflows — that's GRC territory. Just a simple, friction-free way for the person who notices to tell the person who owns it.

This solves the "person who notices ≠ person who fixes" problem. The Finance analyst flags the retired owner. The workspace admin gets notified. The fix takes 30 seconds. Without flags, that data stays wrong for months.

**Achievement engine.** Gamification that rewards *useful* work, not engagement theater. Achievements are earned by completing assessments, assigning owners, tagging technology, resolving flags — actions that directly improve data quality. The engine reads from the existing audit log (the same one used for SOC2 compliance), so there's zero additional overhead on business tables.

Achievements map to tiers. Free users earn onboarding badges ("First Application," "First Assessment"). Pro users earn data quality badges ("All Owners Assigned," "Hosting Complete"). Enterprise users earn collaboration badges ("Multi-Workspace," "Invite 5 Users"). Higher-tier badges are visible but locked — gamified upgrade teasers that show users what they could earn with a higher plan.

**Activity feed.** "What happened while I was away" — a personalized, time-bucketed summary of team activity. Instead of 47 individual audit log entries, you see: "Sarah added 12 applications to Finance workspace this week." Prioritized: your own entities first, then flags assigned to you, then team activity, then milestones.

The feed adapts to how long you've been away. Gone for a day? See individual items. Gone for two weeks? See weekly rollups. Gone for a month? See monthly summaries. This replaces the "log in and see nothing has changed" experience with "log in and see what matters."

**Re-engagement emails.** Dormant users (14+ days inactive) receive personalized "pick up where you left off" emails. Not generic reminders — they include the user's closest unfinished achievement ("You're 2 applications away from 'Data Watchdog'") and any open flags assigned to them ("Stuart flagged Oracle EBS: 'Owner retired last month'"). That's a genuine business reason to log in, not just a notification.

**Three-level opt-out.** Namespace admins can disable achievement emails entirely. Individual users can hide gamification UI (no toasts, no badges, no wall) while still earning progress silently. Users can separately opt out of email digests. Flag assignments are always visible — governance isn't optional.

### Why This Matters for Sales

**For Delta's customer success conversations:** Resolution time metrics ("flag resolution improved from 8 days to 3 days this quarter"), assessment completion trends, and unassigned flag counts provide concrete data quality health indicators. These aren't vanity metrics — they measure whether the tool is actually keeping data fresh.

**For Knowledge 2026 demos:** The achievement wall, activity feed, and flag lifecycle are visual, interactive, and immediately differentiated from competitors. No other APM tool in this market has built-in gamified data governance.

**For the "staff don't fill it in" objection:** "GetInSync tracks data quality as a first-class metric. Achievements reward completing work. Flags create accountability. The activity feed gives every user a reason to log in. Your data doesn't go stale because there's a living governance process, not just a static questionnaire."

---


## Updates to Existing Sections

### Section 6a Addition: The Crawl-to-Walk Buyer

**Who is the economic buyer?**

The buyer isn't someone avoiding risk. Risk gets accepted by inaction ‗ the 93%-Draft risk register proves that. The buyer is someone who's been **told to do something** and has no tool to do it with. Three trigger events:

**"We just bought ServiceNow APM and need to populate it."** The money is already spent. A partner is on contract. Week 3, someone asks "where's the business application data?" and the room goes quiet. That project lead is our buyer ‗ they have budget, a deadline, and an empty table. We're the rescue.

**"The Auditor General / Treasury Board said rationalize."** A directive came down: reduce the portfolio by 20%, justify your IT spend, produce a modernization plan. You can't rationalize what you can't see. The ADM who received that mandate needs to produce something ‗ and they can't do it from 8 spreadsheets.

**"We're doing a major migration / consolidation."** Post-merger, cloud migration, data center exit. Someone needs to know what exists, what depends on what, and what order to move. That program lead has transformation budget and a hard deadline.

In all three cases, the buyer isn't avoiding a risk. They're **delivering a mandate that requires portfolio data they don't have.**

**Economic buyer personas:**

| Persona | Why They Care | Budget Source |
|---------|--------------|---------------|
| ServiceNow Platform Owner / CSDM Program Lead | Empty `cmdb_ci_business_app` is blocking CSDM maturity, APM rollout, service mapping | ServiceNow program budget |
| CIO / ADM of IT | Can't answer "how many apps are at risk?" for Treasury Board / Auditor General | Modernization or transformation initiative |
| CISO / Director of Cyber Security | Can't quantify EOL exposure across the portfolio | Security budget |

**The Platform Owner is the economic buyer. The CISO co-signs. The CIO sponsors.**

**For ServiceNow Knowledge 2026:** We're targeting ServiceNow Platform Owners and CSDM program leads who are stuck in the crawl-to-walk transition ‗ who want more intelligence about their own applications. The message: "Your CMDB has the infrastructure. Your `cmdb_ci_business_app` is empty. We fill it ‗ assessed, costed, CSDM-aligned ‗ in weeks, not months."

### Section 8 Update: Sharpened Customer Profile

**New customer profile (replaces v1.5):**

- ServiceNow customers stuck in CSDM crawl-to-walk
- Have `cmdb_ci_appl` (Discovery) but not `cmdb_ci_business_app` (APM)
- Multiple departments/ministries needing cross-workspace visibility
- Currently maintaining application data in spreadsheets extracted from ServiceNow
- Compliance requirements (SOC 2, data residency)
- 50+ application owners who need self-service
- May have a stalled ServiceNow APM project or an unfunded one

**ServiceNow Knowledge conference pitch:**

> "Your ServiceNow partner needs business application data on day one. We're how it gets there."

### Section 12 Addition: Technology Health Competitive Advantage

**Problem competitors can't solve:** "What technology are our 479 applications running on, what's end-of-life, and what's the blast radius?"

**Spreadsheet + Power BI approach:**
- 8 spreadsheet extracts from ServiceNow CMDB
- Manual lifecycle status lookup per technology version
- 15 dropdown filters in Power BI
- Stale on day two, requires monthly manual refresh
- Can't answer blast radius ("if SQL Server 2016 goes EOL, what apps are affected?")

**ServiceNow APM approach:**
- Requires APM licensing ($150K-$500K/year)
- Requires CSDM alignment (12-18 month implementation)
- Requires `cmdb_ci_business_app` to be populated (the gap)
- Full capability once running, but time-to-value measured in years

**GetInSync approach:**
- Import existing spreadsheet extract → live in days
- Technology tagging on deployment profiles → lifecycle auto-populated
- Technology Health dashboard → native, real-time, zero maintenance
- Blast radius with one click → "show me everything that depends on SQL Server 2016"
- CSDM-aligned → clean push to ServiceNow when ready
- 10% of ServiceNow APM cost, 10% of implementation time

**Win scenario:** "You extracted 8 spreadsheets from ServiceNow to build a Power BI dashboard. Import that spreadsheet into GetInSync once, and you'll never need to extract it again."

### Section 12 Addition: Data Governance Competitive Advantage

**Problem competitors can't solve:** "Our portfolio data was accurate on the day we loaded it. Six months later, 30% is wrong and nobody's maintaining it."

**Spreadsheet approach:**
- Data goes stale the moment it's exported
- No feedback mechanism when information changes
- No way to flag problems without edit access
- Re-collection requires another multi-month manual effort

**Enterprise APM tools (LeanIX, Ardoq):**
- Survey-based collection with no gamification
- No built-in data quality flagging
- Rely on integrations for freshness, not human governance
- Activity tracking is system logs, not team context

**GetInSync approach:**
- Data quality flags: anyone can raise, auto-assigned to entity owner
- Achievement engine rewards completing assessments, assigning owners, resolving flags
- Activity feed: "what happened while you were away" with time-bucketed team context
- Re-engagement emails with specific unfinished work — not generic reminders
- Resolution time metrics for customer success conversations
- Built-in, not bolted-on — zero additional licensing

**Win scenario:** "Your staff loaded 400 applications last year. How many are still accurate? GetInSync tracks data quality as a living metric — not a snapshot."

### Updated Summary Table (additions)

| What Was Broken | The Fix |
|-----------------|---------|
| No technology tracking on apps | Two-path model: simple inventory tags + IT Service maturity layer |
| Manual lifecycle status research | AI-powered Technology Lifecycle Intelligence |
| Risk registers stuck in Draft | Computed risk indicators from technology lifecycle data |
| Risk register in SharePoint | "We detect the risks. GRC tools manage the response." |
| No blast radius analysis | Technology Health dashboard with one-click blast radius |
| CSDM crawl-to-walk gap | GetInSync is where cmdb_ci_appl becomes cmdb_ci_business_app |
| Server-level tracking in APM | Explicit boundary: servers are CMDB/Discovery territory |
| Portfolio data goes stale after initial load | Data quality flags + activity feed keep data alive |
| Staff don't fill in the tool | Achievement engine rewards useful work, re-engagement emails bring dormant users back |
| Person who notices ≠ person who fixes | Flags auto-assign to entity owner from contact roles |

### Updated Related Documents

| Document | Content |
|----------|---------|
| features/technology-health/dashboard.md | Technology Health dashboard: field mapping, schema, views, UI |
| features/technology-health/technology-stack-erd-addendum.md | Two-path model: inventory tags vs IT Service cost/blast radius |
| features/cost-budget/cost-model-addendum.md | Confirms zero cost model impact from technology tagging |
| features/technology-health/risk-boundary.md | Risk register is GRC territory; computed indicators replace manual tracking |
| features/technology-health/lifecycle-intelligence.md | AI-powered EOL tracking (v1.1: two-path model) |
| catalogs/technology-catalog.md | Technology product catalog structure |
| features/gamification/architecture.md | Achievements, data quality flags, activity feed, email re-engagement |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.7 | 2026-02-14 | Added Section 11 (Data Governance & User Engagement). Updated Section 12 (Data Governance competitive advantage). Updated Summary Table and Related Documents. |
| v1.6 | 2026-02-13 | Added Section 9 (Technology Health), Section 10 (Risk Boundary). Updated Section 6a (crawl-to-walk gap, economic buyer personas). Updated Section 8 (sharpened customer profile, Knowledge conference pitch). Updated Section 12 (Technology Health competitive advantage). |
| v1.5 | 2026-02-01 | Added "Competitive Advantages (Marketing Nuggets)" section. |

---

*Document: marketing/explainer.md*  
*February 14, 2026*
