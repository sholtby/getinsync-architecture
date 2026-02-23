# GetInSync NextGen: The Why Behind the What
## What Was Broken, How We Fixed It, Where We're Going

**Version:** 1.7
**Date:** February 2026
**Status:** ☪ REFERENCE

---

## Introduction

This document explains *why* we built NextGen the way we did. It's not a feature list—it's a story about problems and solutions.

Every architectural decision traces back to something that was broken in Legacy GetInSync. If you understand the pain, you'll understand the fix.

---

## 1. Tenancy & Scoping

### What Was Broken

**No data residency control.** All customer data lived in AWS Oregon. When Canadian government prospects asked "Where is our data stored?", we had one answer: the United States. Deal over.

**Flat account structure.** GetInSync couldn't "roll up" Workspaces to a Namespace—for example, all the PortCo companies to the P&E Investment Parent. A CIO couldn't see across all their ministries or portfolio companies without manual exports.

**No portfolio-level data curtaining.** Within a Workspace, every portfolio was shared. That's fine for transparency—until you have a confidential M&A project or a security audit that needs limited visibility. Or you want to squelch the "noise" for other org units: the Fire Department doesn't want to see the Library's apps, and the Library doesn't want to see the Fire Department's apps. Too much noise, no way to filter.

**Shared dropdowns polluted.** When Central IT published its software catalog, every portfolio displayed every item in its dropdowns—including "MyCrappyTestApp," which was never meant to be shared. There was no way to control what was visible to whom.

### How We Fixed It

**Region → Namespace → Workspace → WorkspaceGroup**

```
Region (Platform Scope)
│   Data residency enforcement
│   Canada, US, EU deployments
│
└── Namespace (Billing/Tenant Boundary)
    │   Editor Pool lives here
    │   Organizations shared here
    │
    └── Workspace (Isolation Boundary)
        │   Ministry/Department level
        │   Contacts scoped here
        │
        └── WorkspaceGroup (Reporting/Sharing)
                Roll-up reporting
                Federated Catalog visibility
```

**Region** solves data residency. Canadian data stays in `ca-central-1`. No cross-region access. Compliance solved.

**Namespace** is the customer boundary. One Province of Saskatchewan = one Namespace. Billing, licensing, and Organizations all scoped here.

**Workspace** is the data isolation boundary. Ministry of Justice can't see Ministry of Health's applications—unless explicitly shared.

**WorkspaceGroup** enables controlled sharing. The Federated Catalog uses WorkspaceGroups with `IsCatalogPublisher` to determine what's visible. Central IT publishes; ministries consume. No more polluted dropdowns.

**The Visibility Rule:** A Workspace sees a shared item IF AND ONLY IF:
1. They share a WorkspaceGroup with the owner
2. The owner is flagged as `IsCatalogPublisher = true`
3. The item is flagged as `IsInternalOnly = false`

Three conditions. All must be true. No more "MyCrappyTestApp" in everyone's dropdown.

---

## 2. Identity & Access

### What Was Broken

**No enterprise SSO.** We had Forms Authentication. When enterprise prospects asked about Entra ID, SAML, or MFA, we had nothing. Security assessments failed. Deals died.

**User ≠ Contact confusion.** The identity model conflated "the person who logs in" with "the person as seen in this Workspace." This made cross-Workspace scenarios messy. One human being shouldn't need multiple login accounts.

**Implicit role boundaries.** Authorization existed, but it wasn't cleanly enforced through explicit, documented roles. What could an "Application Manager" actually do? It wasn't always clear.

**No external contractor support.** When a consulting firm needed access to work on a project, they got the same visibility as internal staff. No way to say "you can only see the applications in Portfolio X."

### How We Fixed It

**Individual + Contact + WorkspaceRole**

| Entity | Scope | Purpose |
|--------|-------|---------|
| **Individual** | Platform | The real person. Links to external IdP via identity key. One per human. |
| **Contact** | Workspace | The person *as seen in this Workspace*. Holds `WorkspaceRole`. |
| **WorkspaceRole** | Contact | What they can do *here*. Admin, Editor, Steward, Viewer, Restricted. |

**One person, many Workspaces, different roles.** Stuart can be Admin in the Justice Workspace and Viewer in Health. One login (Individual), different permissions per Workspace (Contact.WorkspaceRole).

**SSO via Supabase Auth.** Supports OIDC/SAML providers including Entra ID, Google, and custom SAML. JIT provisioning on first login. MFA enforced via the customer's IdP. Enterprise security requirements met.

**Five explicit roles:**

| Role | Create | Edit | View | Dashboards |
|------|--------|------|------|------------|
| **Admin** | ✅ All | ✅ All | ✅ All | ✅ |
| **Editor** | ✅ All | ✅ Assigned Portfolios | ✅ All | ✅ |
| **Steward** | ┌ | ✅ Owned Apps (Business Fit) | ✅ All | ✅ |
| **Viewer** | ┌ | ┌ | ✅ All | ✅ |
| **Restricted** | ┌ | ┌ | ⚠️ Assigned only | ┌ |

**Restricted role for contractors.** External consultants get Restricted. They see only the Portfolios they're assigned to. No dashboards. No wandering. Confidential projects stay confidential.

**Philosophy:** "Why are you in GetInSync if you're limited?" Transparency is the default. Restriction is the exception.

---

## 3. Licensing & Data Collection

### What Was Broken

**Shadow spreadsheets.** This was the killer. Editor licenses cost money. Organizations with 50 Application Owners faced a choice: pay for 50 Editor licenses, or track the data in spreadsheets outside GetInSync.

They chose spreadsheets.

The tool designed to eliminate spreadsheets was *creating* spreadsheets. The licensing model defeated the product's purpose.

Or worse: users shared logins. Susan, a licensed user, gave her credentials to Alex, a "ghost" account. When Alex edited data, it looked like Susan edited it. This invalidated SOC 2 compliance, created revenue leakage, and built a "quiet" underground user group that IT didn't know existed.

**Per-seat everywhere.** Every person who needed to update data needed a license. No pooling. No sharing. 50 people = 50 licenses.

**No self-service for app owners.** Business users who owned applications couldn't update basic information (like "is this app still business critical?") without full Editor access. IT became the bottleneck.

**Data collection is a barrier.** No sync from ServiceNow. No CMDB import. Every piece of data entered manually. High friction = stale data.

### How We Fixed It

**Editor Pool + Steward Role**

**Editor Pool at Namespace level.** Licenses are pooled, not per-seat-per-Workspace. One user with Editor role in 5 Workspaces = 1 license consumed. Simple.

```
Namespace: Province of Saskatchewan
├── Editor Pool: 25 licenses
│
├── Stuart (Individual)
│   ├── Editor in Justice, Health, Finance
│   └── License consumed: 1
│
└── Maria (Individual)
    ├── Editor in Education only
    └── License consumed: 1

Total consumed: 2 (not 4)
```

**Steward role solves shadow spreadsheets.** Application Owners don't need Editor licenses. They get Steward rights automatically when they're assigned as Owner or Delegate on an application.

Steward can:
- Edit Business Fit (TIME scores)
- Edit application metadata
- Add up to 2 Delegates

Steward cannot:
- Edit Technology Fit
- Edit Deployment Profiles
- Create or delete applications

**The economics:**

| Scenario | Without Steward | With Steward |
|----------|-----------------|--------------|
| 50 App Owners need to update data | 50 × $2,000 = $100,000/year | $0 (included in Enterprise) |

Steward is the Enterprise differentiator. It's not a feature—it's a business model fix.

**ServiceNow sync.** NextGen aligns with CSDM. We can pull from `cmdb_ci_business_app` and push back. Data collection friction reduced. More on this in Section 6.

---

## 4. Cost Model (TBM-lite)

### What Was Broken

**Costs not traceable to apps.** Where do application costs actually land? Legacy had no clear answer. Costs floated around without a definitive anchor point.

**"Guess costs" on IT Services.** IT Service had a `TotalAnnualCost` field, but it was just a number someone typed in. Not tied to contracts. Not validated. A guess.

**No stranded cost visibility.** Central IT runs shared infrastructure. Some of that cost gets allocated to applications. Some doesn't. The unallocated portion—stranded cost—was invisible. CFOs hate invisible costs.

**Double-counting risk.** If you show infrastructure costs in both the "IT Services" view and the "Application" view, you count the same dollar twice. Total IT spend looks inflated. CFOs lose trust.

**No cost categories.** No way to answer "What are we spending on Infrastructure vs. Applications vs. Security?" Everything was one undifferentiated pile.

**No ServiceNow alignment.** The legacy data model didn't have a concept of Deployment Profiles. This meant no clean mapping to ServiceNow's CSDM (Application → Application Service → Technical Service). Organizations with ServiceNow couldn't sync cleanly.

### How We Fixed It

**DeploymentProfile as the cost anchor.**

```
┌─────────────────────────────────────────────────────────────────┐
│                     COST FLOW DIAGRAM                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ProductContract ──────┐                                        │
│  (Direct license cost) │                                        │
│                        ├──► DeploymentProfile ──► Application   │
│  ITService ────────────┤    (Cost Anchor)          (TCO)        │
│  (Shared infra cost)   │                                        │
│                        │                                        │
│  DirectCost ───────────┘                                        │
│  (Manual entry)                                                 │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  For non-application costs:                                     │
│                                                                 │
│  ProductContract ──────┐                                        │
│  ITService ────────────┼──► Free-Standing DP ──► Portfolio      │
│  DirectCost ───────────┘    (ApplicationId = NULL)              │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ITService.StrandedCost ──► Reported against ServiceOwner       │
│  (Unallocated portion)      (Central IT accountability)         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Everything flows to DeploymentProfile. That's the anchor. No ambiguity.

**Three cost sources, clearly separated:**

| Source | What It Is | Example | Where It Lives |
|--------|------------|---------|----------------|
| **ProductContract** | Software/SaaS licensing | Microsoft 365 EA | DirectCost on contract |
| **ITService** | Shared infrastructure | Azure SQL Shared | Allocated via percentage |
| **DirectCost** | Manual costs | Consulting, one-time fees | Direct on DeploymentProfile |

**Direct vs. Allocated costs explicitly tracked:**

| Field | Description |
|-------|-------------|
| **DeploymentProfile.DirectCost** | Costs specific to this deployment |
| **DeploymentProfile.AllocatedContractCost** | Sum of contract allocations |
| **DeploymentProfile.AllocatedServiceCost** | Sum of IT service allocations |
| **DeploymentProfile.TotalCost** | DirectCost + AllocatedContractCost + AllocatedServiceCost |

This separation ensures we never count the same dollar twice.

**Five Cost Categories (TBM-lite):**

| Category | Examples |
|----------|----------|
| **Infrastructure & Cloud** | AWS, Azure, data centers, WAN/LAN |
| **Applications & Software** | Microsoft 365, Salesforce, SAP licenses |
| **IT Labor & Services** | FTEs, consultants, managed services |
| **End-User Computing** | Laptops, peripherals, help desk |
| **Security & Compliance** | SIEM, firewalls, audits, backup/DR |

CostCategory is Namespace-scoped. ITService and ProductContract each link to one category. Now we can answer "What are we spending on Security?"

**Stranded Cost Rule:**

```
ITService.StrandedCost = TotalAnnualCost - Sum(Allocations)
```

Stranded cost is:
- **Calculated automatically** — no manual tracking
- **Visible in reports** — CFO transparency
- **Attributed to Service Owner** — Central IT accountability
- **Optionally allocated** — to a Free-Standing Deployment Profile

**Free-Standing Deployment Profiles (The Rule):**

**NEVER** create "dummy" Business Applications to hold costs. BusinessApplication is reserved for business-facing applications used in TIME/PAID analysis.

Instead, use **Free-Standing Deployment Profiles** — DeploymentProfiles where `ApplicationId = NULL`:

| DP Name | What It Captures |
|---------|------------------|
| "O365 – Org Wide" | Microsoft 365 licenses not tied to one app |
| "Canva – Marketing" | SaaS spend for a specific department |
| "Azure Shared Infrastructure" | Cloud hosting for multiple apps |
| "IT Governance & Compliance" | Audit costs, compliance tools |

Why this matters:
- Keeps the Business Application portfolio **clean** for TIME analysis
- Prevents APM counts from being **skewed** by dummy apps
- Costs still **roll up** to Portfolio and Workspace reports

**Contract Allocation Rule:** A contract can be allocated to multiple Deployment Profiles, but *only within the same Workspace*. Cross-Workspace allocation is prohibited. Data integrity preserved.

**Validation:**

| Rule | Severity |
|------|----------|
| Sum of allocations ≤ 100% | Warning |
| Sum of allocations > 105% | Error |
| Cross-Workspace allocation | Error |
| Stranded cost > 20% | Review flag |

**The Bottom Line:** GetInSync NextGen is "TBM-lite"—the spirit of Technology Business Management (cost transparency, category reporting, application TCO) without the complexity of a full Apptio implementation.

---

## 5. Vendor & Software Management

### What Was Broken

**Vendor list duplicated everywhere.** Each Workspace maintained its own list of vendors. Microsoft appeared 15 times across 15 Workspaces. Updates required 15 edits. Data quality suffered.

**Software polluted IT Services.** Where does Adobe Creative Cloud go? Canva? Snag-It? They're not infrastructure. They're not business applications. People dumped them into IT Services because there was nowhere else. Result: IT Services are polluted with software licenses.

**No clean Software Product entity.** The data model didn't have a proper home for commercial software products.

### How We Fixed It

**Organization is Namespace-Scoped.**

```
Namespace: Province of Saskatchewan
└── Organizations (shared across all Workspaces)
    ├── Microsoft Corporation
    ├── Adobe Inc.
    ├── SaskTel
    └── Internal: Central IT Division
```

One Microsoft. Shared by all Workspaces. Update once, visible everywhere (where used).

**Organizations have roles, not types.** An Organization can be:
- `IsSupplier = true`
- `IsManufacturer = true`
- `IsCustomer = true`
- `IsInternalOrg = true`

Microsoft is both Supplier and Manufacturer. Central IT is Internal. Flags, not separate tables.

**UI speaks the user's language.** The backend uses "Organization" for flexibility, but government users expect "Vendors." We present filtered views:

| UI View | Filter | Access |
|---------|--------|--------|
| **Vendors** | IsSupplier = true | All users |
| **Manufacturers** | IsManufacturer = true | All users |
| **Organizations** | No filter | Admins only |

On forms, contextual labels:
- ProductContract shows "Vendor" (not "Organization")
- SoftwareProduct shows "Manufacturer" (not "Organization")

**Why this matters:** City of Garland validated this approach. Their teams consistently refer to entities they purchase from as "Vendors." The architecture supports flexibility; the UI reduces confusion.

**Software Product is a proper entity.**

| Entity | What Goes Here | Example |
|--------|----------------|---------|
| **ITService** | Infrastructure | Azure SQL, Shared Storage, Network |
| **SoftwareProduct** | Commercial software | Adobe Creative Cloud, Microsoft 365, Canva |
| **BusinessApplication** | Business capability | Payroll System, CRM, Case Management |

Clean separation. No more pollution.

**SoftwareProduct links to:**
- `ManufacturerOrgId` → Who makes it (Adobe)
- `ProductContract` → How we license it (Enterprise Agreement)
- `DeploymentProfile` → Where it's used (via contract allocation)

Canva finally has a home.

---

## 6. Integrations & ServiceNow

### What Was Broken

**No CMDB sync.** Customers with ServiceNow already had application data in their CMDB. We asked them to re-enter it manually. High friction. Low adoption.

**No CSDM alignment.** Our data model didn't map cleanly to ServiceNow's Common Service Data Model. Syncing was not on the radar, and we avoided the conversation.

**Internal chargebacks mixed with real contracts.** When syncing to ServiceNow, internal chargeback "contracts" (Ministry pays Central IT) got pushed to `ast_contract` alongside real vendor contracts (Microsoft Enterprise Agreement). Polluted the legal contract repository.

### How We Fixed It

**CSDM-aligned data model.**

```
GetInSync                    ServiceNow CSDM
──────────                   ───────────────
BusinessApplication    →     cmdb_ci_business_app
DeploymentProfile      →     cmdb_ci_service_auto (Application Service)
ITService (Shared)     →     service_offering (Technical Service Offering)
ITService (Local)      →     cmdb_ci_service_technical (Technical Service)
SoftwareProduct        →     alm_product_model (Software Model)
ProductContract        →     ast_contract (Vendor contracts only)
```

**BusinessApplication is the CSDM anchor.** Not `cmdb_ci_appl` (that's legacy/technical noise). We push to `cmdb_ci_business_app` where business intent lives.

**DeploymentProfile maps to Application Service.** Prod, DR, Dev—each becomes an Application Service instance in ServiceNow.

**Internal Chargebacks MUST NOT sync to ast_contract.** Internal chargeback arrangements (Ministry → Central IT) are *not* legal contracts. They don't belong in ServiceNow's contract table. We track them locally but exclude from sync.

**Sync direction:** GetInSync → ServiceNow (push) for business intent and ownership. ServiceNow → GetInSync (pull) for CMDB baseline data. Bidirectional eventually, but push-first for v1.

**Schedule-based, not real-time.** APM data doesn't change hourly. Daily or triggered-on-change sync is sufficient.

---

## 6a. The CSDM Challenge

### What Is CSDM?

ServiceNow's **Common Service Data Model (CSDM)** is the required foundation for getting value from ServiceNow's platform. It's a standardized framework that defines how service-related data is structured, organized, and connected.

CSDM isn't optional—it's the way ServiceNow products expect data to be organized. Without CSDM alignment, organizations struggle with:
- Incident, Problem, and Change management
- Service mapping and discovery
- Application Portfolio Management
- Reporting and dashboards

### CSDM 5.0 Is Here

CSDM 5.0 was released in May 2025 at ServiceNow Knowledge. It expands the model significantly:

| Domain | What's New in 5.0 |
|--------|-------------------|
| **Strategy** | New domain connecting business objectives to technology investment |
| **Lifecycle** | Expanded lifecycle management (replacing legacy status fields) |
| **Value Streams** | Integration with business value delivery |
| **Service Instances** | Renamed from Application Services, expanded types |

The model now spans five domains: Strategy, Design, Build, Manage Technical Services, and Sell/Consume. It's more comprehensive—and more complex.

### The Pain Is Real

ServiceNow community forums are filled with migration struggles:

**Migration is not trivial.** Organizations with existing data face "complete rework of services and everything they're connected to—and all the people, process and technologies that use them."

**The staged approach doesn't fit everyone.** ServiceNow's crawl/walk/run/fly methodology "only makes sense if Business Apps, Capabilities, Processes, Services and Offerings are all empty." Organizations with existing data may need to implement most CSDM elements in one big bang.

**Features require CSDM.** New capabilities like CMDB Data Manager require lifecycle mapping to be enabled. Legacy status synchronization is being deprecated. Products work better—or only work—with CSDM alignment.

**Upgrades get harder.** An inconsistent data model makes upgrading ServiceNow instances complex and time-consuming. Organizations that delay CSDM adoption accumulate technical debt.

### The Soft Force

ServiceNow doesn't explicitly mandate CSDM adoption. But they create strong pressure:

| Pressure Point | Impact |
|----------------|--------|
| New features require CSDM | Can't use CMDB Data Manager without lifecycle mapping |
| Legacy sync deprecated | PI 2.0 eliminates legacy status synchronization |
| Products work better | ServiceNow products "deliver better benefits faster when using CSDM" |
| Upgrade friction | Non-CSDM implementations struggle with version upgrades |

**Bottom line:** It's not "adopt CSDM or your system stops working." It's "adopt CSDM or fall behind on features, struggle with upgrades, and accumulate technical debt."

### Where GetInSync Fits

GetInSync is CSDM-aligned from the start. Our data model maps directly to ServiceNow's:

| GetInSync Entity | ServiceNow CSDM Table |
|------------------|----------------------|
| BusinessApplication | cmdb_ci_business_app |
| DeploymentProfile | cmdb_ci_service_auto (Application Service) |
| ITService (Shared) | service_offering (Technical Service Offering) |
| ITService (Local) | cmdb_ci_service_technical (Technical Service) |
| SoftwareProduct | alm_product_model (Software Model) |
| ProductContract | ast_contract (vendor contracts only) |

### The Crawl-to-Walk Buyer

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

### Two Paths, One Solution

**Path A: Stepping Stone to ServiceNow APM**

For organizations that will eventually adopt ServiceNow APM:

1. **Start with GetInSync** — Build CSDM-aligned data without ServiceNow's complexity
2. **Prove value in 30-60 days** — Demonstrate APM benefits, get stakeholder buy-in
3. **Clean your data** — Use GetInSync as the staging area for clean Business Application data
4. **Sync when ready** — Push CSDM-aligned data to ServiceNow when you're ready
5. **Graduate to ServiceNow APM** — With clean data and proven value

**Path B: Alternative for Smaller Organizations**

For organizations where ServiceNow APM is overkill:

1. **Stay with GetInSync** — Full APM capability at 1/10th the cost
2. **CSDM-aligned** — If you ever need to integrate with ServiceNow, the data model is ready
3. **Steward for scale** — App owners self-serve without the $400K Editor license burden
4. **No dedicated admin** — Self-service, not ServiceNow complexity

### The De-Risk Story

GetInSync de-risks the ServiceNow APM journey:

| Risk | How GetInSync Mitigates |
|------|------------------------|
| $200K+ implementation fails | Prove value for $50K first |
| 12-18 month timeline slips | See results in 30-60 days |
| Data quality issues | Clean data in GetInSync before syncing |
| Stakeholder resistance | Build buy-in with working system |
| CSDM migration complexity | Start CSDM-aligned, skip the migration |

**Start with us, graduate to ServiceNow—or stay.**

---

## 7. Security & Compliance

### What Was Broken

**No SOC 2 certification.** Enterprise and government procurement requires SOC 2 Type II. We don't have it. Deals blocked at security review.

**No Canadian data residency.** AWS Oregon only. Canadian government requires Canadian soil. No region = no deal.

**No SSO/MFA.** Forms authentication only. Failed security questionnaires. "Do you support SAML/OIDC?" No. "Do you enforce MFA?" No. Next vendor please.

**No audit trail.** Enterprise security teams require audit logging, access reviews, and evidence of continuous monitoring. We had none.

### How We Fixed It

**Canadian-first deployment.**

| Region | Location | Use Case |
|--------|----------|----------|
| Canada | Montreal, Quebec (ca-central-1) | Canadian government, data residency |
| US | Available on demand | US customers |
| EU | Available on demand | Future, GDPR compliance |

Data never leaves designated region. Namespace is pinned to Region at creation.

**SSO via Supabase Auth.** OIDC/SAML support for enterprise IdPs (Entra ID, Google, custom SAML). MFA enforced via customer's IdP. JIT provisioning on first login.

**Database-enforced security:**
- Row-Level Security on every table (90 tables, 347 policies)
- Trigger-based audit logging on all critical tables (37 triggers, 365-day retention)
- TLS 1.2+ in transit, AES-256 at rest (Supabase managed)
- All views configured with `security_invoker = true` (27/27 views)
- Automated daily backups, schema versioned in GitHub

**SOC 2 Type II roadmap:** Audit logging activated Feb 2026. Baseline evidence snapshot collected. 6-month evidence threshold Aug 2026. Target Type II audit Q4 2026.

**The security story changed from "we don't have that" to "here's our compliance roadmap with evidence already accumulating."** That's the difference between a closed door and a conversation.

---

## 8. Market Positioning

### What Was Broken

**SME focus didn't work.** We targeted small-to-medium businesses. They had long sales cycles for small deals, competed with "just use a spreadsheet," and required high support for low revenue.

**MSP channel stalled.** We built for Managed Service Providers to resell. They didn't. The value proposition didn't resonate with their business model.

**"Vitamins" not "pain relief."** GetInSync was nice-to-have. "You should track your applications." "Best practice says..." Nobody wakes up at 3am worried about APM best practices. We were selling vitamins to people who didn't feel sick.

### How We Fixed It

**Pivot to enterprise.**

| Attribute | Legacy Target | NextGen Target |
|-----------|---------------|----------------|
| Company size | 50-500 employees | 1,000-10,000+ employees |
| Buyer | IT Manager | IT Director, CIO |
| Budget | $5-15K/year | $50-150K/year |
| Competition | Spreadsheets | ServiceNow APM |
| Value prop | Best practice | Pain relief / De-risk ServiceNow |

**ServiceNow is our "coopetition."** GetInSync accelerates ServiceNow APM adoption. ServiceNow APM costs $150K-$500K/year plus $200K+ implementation. Time to value: 12-18 months.

Organizations need ServiceNow APM capabilities but can't move forward because it's too risky until proven within the organization. GetInSync de-risks the endeavor. Start with GetInSync, prove the value, then graduate to ServiceNow APM—or stay with us.

**We're the pain relief.** Not "you should track applications." Instead: "Your 200 app owners can update their own data without 200 Editor licenses." That's $400K/year saved. That's pain relief.

**Customer profile:**
- ServiceNow customers stuck in CSDM crawl-to-walk
- Have `cmdb_ci_appl` (Discovery) but not `cmdb_ci_business_app` (APM)
- Multiple departments/ministries needing cross-workspace visibility
- Currently maintaining application data in spreadsheets extracted from ServiceNow
- Compliance requirements (SOC 2, data residency)
- 50+ application owners who need self-service
- May have a stalled ServiceNow APM project or an unfunded one

**ServiceNow customers are the target. Government is a beachhead.** Provincial/state/municipal governments have the right profile: multiple ministries, compliance requirements, ServiceNow presence, stable budgets. They're ServiceNow customers who fit our model perfectly. Saskatchewan is our pilot.

**ServiceNow Knowledge 2026 pitch:**

> "Your ServiceNow partner needs business application data on day one. We're how it gets there."

**MSPs preserved at entry tier.** Essentials tier ($15K) allows MSPs to hold a Namespace with 5 client Workspaces. Channel not abandoned, just right-sized.

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
| Extended, EOL < 6 months | High | 🟠 |
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

Achievements map to tiers. Trial users earn onboarding badges ("First Application," "First Assessment"). Plus users earn data quality badges ("All Owners Assigned," "Hosting Complete"). Enterprise users earn collaboration badges ("Multi-Workspace," "Invite 5 Users"). Higher-tier badges are visible but locked — gamified upgrade teasers that show users what they could earn with a higher plan.

**Activity feed.** "What happened while I was away" — a personalized, time-bucketed summary of team activity. Instead of 47 individual audit log entries, you see: "Sarah added 12 applications to Finance workspace this week." Prioritized: your own entities first, then flags assigned to you, then team activity, then milestones.

The feed adapts to how long you've been away. Gone for a day? See individual items. Gone for two weeks? See weekly rollups. Gone for a month? See monthly summaries. This replaces the "log in and see nothing has changed" experience with "log in and see what matters."

**Re-engagement emails.** Dormant users (14+ days inactive) receive personalized "pick up where you left off" emails. Not generic reminders — they include the user's closest unfinished achievement ("You're 2 applications away from 'Data Watchdog'") and any open flags assigned to them ("Stuart flagged Oracle EBS: 'Owner retired last month'"). That's a genuine business reason to log in, not just a notification.

**Three-level opt-out.** Namespace admins can disable achievement emails entirely. Individual users can hide gamification UI (no toasts, no badges, no wall) while still earning progress silently. Users can separately opt out of email digests. Flag assignments are always visible — governance isn't optional.

### Why This Matters for Sales

**For customer success conversations:** Resolution time metrics ("flag resolution improved from 8 days to 3 days this quarter"), assessment completion trends, and unassigned flag counts provide concrete data quality health indicators. These aren't vanity metrics — they measure whether the tool is actually keeping data fresh.

**For Knowledge 2026 demos:** The achievement wall, activity feed, and flag lifecycle are visual, interactive, and immediately differentiated from competitors. No other APM tool in this market has built-in gamified data governance.

**For the "staff don't fill it in" objection:** "GetInSync tracks data quality as a first-class metric. Achievements reward completing work. Flags create accountability. The activity feed gives every user a reason to log in. Your data doesn't go stale because there's a living governance process, not just a static questionnaire."

---

## Where We're Going

### The Roadmap

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 1** | Q1 2026 | Features & Core (RBAC, Steward, Editor Pool, Namespace/Workspace) |
| **Phase 2** | Q2 2026 | Security & Polish (Canada region, SSO, testing) |
| **Phase 3** | Q3 2026 | Pilot (Saskatchewan live) |
| **Phase 4** | Q4 2026 | Compliance (SOC 2 Type II) |

### What Success Looks Like

**For customers:**
- Application owners update their own data (Steward)
- No shadow spreadsheets
- Cross-ministry visibility without data leakage
- Pass security assessments
- ServiceNow capabilities at 1/3 the cost

**For GetInSync:**
- Enterprise deals ($50-150K ACV)
- Government references
- SOC 2 certified
- Sustainable growth

### The Investment

One developer (Jason), 80 hours/month, 6 months. AI-assisted development (Claude, Codex). Total effort: ~500 hours.

The architecture is designed. The pricing is validated. The roadmap is clear.

Now we build.

---

## 12. Competitive Advantages (Marketing Nuggets)

### Data Residency & Compliance

**Problem competitors can't solve:** "Where is our data physically located for PIPEDA/GDPR compliance?"

**ServiceNow:**
- Free-text location fields on CIs
- No validation, no standardization
- No country_code for compliance queries
- Requires custom discovery + manual data cleanup
- Complex CMDB queries across multiple CI relationships

**GetInSync:**
- `standard_regions` reference table with country_code
- Provider-specific regions (AWS, Azure, GCP, Oracle) + vendor-agnostic generic regions
- Simple compliance query: `SELECT * FROM apps WHERE region.country_code = 'CA'`
- Auto-generates compliance findings for IT Value Creation
- Data residency tracking works out of the box

**Sales angle:** Government and regulated industries require data sovereignty reporting. ServiceNow needs expensive ITOM discovery + consulting hours to build compliance reports. GetInSync has it built-in, day one.

**Win scenario:** "How will you prove PIPEDA compliance for your next audit?" → ServiceNow requires discovery tools + custom reports. GetInSync: click button, export report.

### Technology Health

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

### Data Governance

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

---

## Summary: The Fixes at a Glance

| What Was Broken | The Fix |
|-----------------|---------|
| No data residency | Region-scoped deployment |
| No cross-Workspace reporting | WorkspaceGroup roll-ups |
| Polluted shared dropdowns | Federated Catalog with IsCatalogPublisher + IsInternalOnly |
| No portfolio-level curtaining | Restricted role + Portfolio scoping |
| No enterprise SSO | Supabase Auth with external IdP support (Entra ID, SAML, OIDC) |
| Messy identity model | Individual (platform) + Contact (workspace) + WorkspaceRole |
| No contractor restriction | Restricted role with Portfolio-only visibility |
| Shadow spreadsheets | Steward role (free for app owners, Enterprise tier) |
| Shared logins / ghost users | Editor Pool + Steward eliminates the incentive |
| Per-seat licensing everywhere | Editor Pool at Namespace level |
| Costs not traceable | DeploymentProfile as cost anchor |
| Guess costs on IT Services | Contract allocations + Stranded Cost calculation |
| Double-counting risk | Direct vs. Allocated cost separation |
| No cost categories | Five TBM-lite categories (Namespace-scoped) |
| Stranded costs invisible | Calculated automatically, attributed to Service Owner |
| Non-app costs (overhead) | Free-Standing Deployment Profiles (ApplicationId = NULL) |
| No CSDM alignment | DeploymentProfile maps to Application Service |
| CSDM migration too complex | Start CSDM-aligned, skip the migration |
| Vendors duplicated | Organization scoped at Namespace |
| Software in IT Services | SoftwareProduct entity |
| No CMDB sync | CSDM-aligned model, ServiceNow push/pull |
| Internal chargebacks polluting contracts | Excluded from sync |
| No SOC 2 | Evidence collection active, target Q4 2026 |
| No Canadian hosting | Supabase ca-central-1 (Montreal) |
| SME market didn't work | Pivot to enterprise |
| Vitamins, not pain relief | ServiceNow coopetition positioning |
| CSDM crawl-to-walk gap | GetInSync is where cmdb_ci_appl becomes cmdb_ci_business_app |
| No technology tracking on apps | Two-path model: simple inventory tags + IT Service maturity layer |
| Manual lifecycle status research | AI-powered Technology Lifecycle Intelligence |
| Risk registers stuck in Draft | Computed risk indicators from technology lifecycle data |
| Risk register in SharePoint | "We detect the risks. GRC tools manage the response." |
| No blast radius analysis | Technology Health dashboard with one-click blast radius |
| Server-level tracking in APM | Explicit boundary: servers are CMDB/Discovery territory |
| Portfolio data goes stale after initial load | Data quality flags + activity feed keep data alive |
| Staff don't fill in the tool | Achievement engine rewards useful work, re-engagement emails bring dormant users back |
| Person who notices ≠ person who fixes | Flags auto-assign to entity owner from contact roles |

---

## Related Documents

| Document | Content |
|----------|---------|
| core/conceptual-erd.md | Full data model with TBM-lite cost model |
| core/involved-party.md | Organization UI presentation, filtered views |
| identity-security/identity-security.md | RBAC, SSO, security architecture |
| marketing/pricing-model.md | Tiers, licensing, Steward economics |
| features/cost-budget/cost-model.md | Cost flow rules |
| features/integrations/servicenow-alignment.md | CSDM mapping, sync strategy |
| features/technology-health/dashboard.md | Technology Health dashboard: field mapping, schema, views, UI |
| features/technology-health/technology-stack-erd-addendum.md | Two-path model: inventory tags vs IT Service cost/blast radius |
| features/cost-budget/cost-model-addendum.md | Confirms zero cost model impact from technology tagging |
| features/technology-health/risk-boundary.md | Risk register is GRC territory; computed indicators replace manual tracking |
| features/technology-health/lifecycle-intelligence.md | AI-powered EOL tracking (two-path model) |
| catalogs/technology-catalog.md | Technology product catalog structure |
| features/gamification/architecture.md | Achievements, data quality flags, activity feed, email re-engagement |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.7 | 2026-02-14 | Added Section 11 (Data Governance & User Engagement). Updated Section 12 (Data Governance competitive advantage). Updated Summary Table and Related Documents. |
| v1.6 | 2026-02-13 | Added Section 9 (Technology Health), Section 10 (Risk Boundary). Updated Section 6a (crawl-to-walk gap, economic buyer personas). Updated Section 8 (sharpened customer profile, Knowledge conference pitch). Updated Section 12 (Technology Health competitive advantage). |
| v1.5 | 2026-02-01 | Added "Competitive Advantages (Marketing Nuggets)" section. Data residency & compliance advantage vs ServiceNow. |
| v1.4 | 2025-12-19 | Added UI terminology section in Vendor & Software Management. Filtered views (Vendors, Manufacturers), contextual labels, admin-only unfiltered view. City of Garland validation. |
| v1.3 | 2025-12-16 | Expanded Cost Model section with TBM-lite details. Added Free-Standing DPs, cost flow diagrams, stranded cost explanation. |
| v1.2 | 2025-12-14 | Added Cost Model section. |
| v1.1 | 2025-12-12 | Initial version. |
| **v1.7.1** | **2026-02-23** | **Merged v1.5 base + v1.7 additions into single consolidated document. Updated Section 7 (Supabase security stack, SOC2 Q4 2026 target). Updated document references to new repo paths. Cleaned stale AWS infrastructure refs.** |

---

*Document: marketing/explainer.md*
*February 2026*
