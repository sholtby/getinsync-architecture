# GetInSync NextGen: The Why Behind the What (v1.5)
## What Was Broken, How We Fixed It, Where We're Going

### February 2026

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
| **Individual** | Platform | The real person. Links to Entra ID via `ExternalIdentityKey` (OID). One per human. |
| **Contact** | Workspace | The person *as seen in this Workspace*. Holds `WorkspaceRole`. |
| **WorkspaceRole** | Contact | What they can do *here*. Admin, Editor, Steward, Read-Only, Restricted. |

**One person, many Workspaces, different roles.** Stuart can be Admin in the Justice Workspace and Read-Only in Health. One login (Individual), different permissions per Workspace (Contact.WorkspaceRole).

**Entra ID SSO.** Individual.ExternalIdentityKey stores the Entra OID. JIT provisioning on first login. MFA enforced via the customer's IdP. Enterprise security requirements met.

**Five explicit roles:**

| Role | Create | Edit | View | Dashboards |
|------|--------|------|------|------------|
| **Admin** | ✅ All | ✅ All | ✅ All | ✅ |
| **Editor** | ✅ All | ✅ Assigned Portfolios | ✅ All | ✅ |
| **Steward** | ┌ | ✅ Owned Apps (Business Fit) | ✅ All | ✅ |
| **Read-Only** | ┌ | ┌ | ✅ All | ✅ |
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

**No WAF/SIEM integration.** Enterprise security teams require Web Application Firewall, Security Information and Event Management integration, audit logging. We had none.

### How We Fixed It

**Multi-region deployment.**

| Region | Location | Use Case |
|--------|----------|----------|
| Canada | ca-central-1 | Canadian government, data residency |
| US | us-west-2 | US customers (existing) |
| EU | eu-west-1 | Future, GDPR compliance |

Data never leaves designated region. Namespace is pinned to Region at creation.

**Entra ID SSO with JIT provisioning.** OIDC/SAML support. MFA enforced via customer's IdP. Individual.ExternalIdentityKey stores the immutable Entra OID.

**Security infrastructure:**
- AWS WAF enabled
- CloudWatch logging + SIEM export capability
- 30-day backup retention via AWS Backup
- RTO 1 hour, RPO 1 hour (exceeds typical government requirements)

**SOC 2 Type II roadmap:** Target Q2 2027. Gap assessment Q4 2026, audit period Q1 2027.

**The security story changed from "we don't have that" to "here's our compliance roadmap."** That's the difference between a closed door and a conversation.

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

**New customer profile:**
- ServiceNow customers who want APM but can't justify the cost/risk
- Multiple departments/ministries needing cross-workspace visibility
- Compliance requirements (SOC 2, data residency)
- 50+ application owners who need self-service

**ServiceNow customers are the target. Government is a beachhead.** Provincial/state/municipal governments have the right profile: multiple ministries, compliance requirements, ServiceNow presence, stable budgets. They're ServiceNow customers who fit our model perfectly. Saskatchewan is our pilot.

**MSPs preserved at entry tier.** Essentials tier ($15K) allows MSPs to hold a Namespace with 5 client Workspaces. Channel not abandoned, just right-sized.

---

## Where We're Going

### The Roadmap

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 1** | Q1 2026 | Features & Core (RBAC, Steward, Editor Pool, Namespace/Workspace) |
| **Phase 2** | Q2 2026 | Security & Polish (Canada region, SSO, WAF, testing) |
| **Phase 3** | Q3 2026 | Pilot (Saskatchewan live) |
| **Phase 4** | Q4 2026-Q2 2027 | Compliance (SOC 2 Type II) |

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
- Auto-generates compliance findings for Phase 21 (IT Value Creation)
- Data residency tracking works out of the box

**Example Initiative (Phase 21):**
- **Finding:** "We have 47 applications and don't know where data is physically located for PIPEDA compliance"
- **Initiative:** "Establish data residency compliance baseline"
  - Status: In Progress
  - Theme: Risk (red)
  - Horizon: 0-3 months
  - Owner: Legal/IT
  - Action: Use GetInSync's region tracking to identify all Canadian vs US data
  - Value: Avoid regulatory penalties, enable government contracts

**Sales angle:** Government and regulated industries require data sovereignty reporting. ServiceNow needs expensive ITOM discovery + consulting hours to build compliance reports. GetInSync has it built-in, day one.

**Win scenario:** "How will you prove PIPEDA compliance for your next audit?" → ServiceNow requires discovery tools + custom reports. GetInSync: click button, export report.

---

## Summary: The Fixes at a Glance

| What Was Broken | The Fix |
|-----------------|---------|
| No data residency | Region-scoped deployment |
| No cross-Workspace reporting | WorkspaceGroup roll-ups |
| Polluted shared dropdowns | Federated Catalog with IsCatalogPublisher + IsInternalOnly |
| No portfolio-level curtaining | Restricted role + Portfolio scoping |
| No enterprise SSO | Entra ID via Individual.ExternalIdentityKey |
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
| No SOC 2 | Roadmap to Q2 2027 |
| No Canadian hosting | AWS ca-central-1 |
| SME market didn't work | Pivot to enterprise |
| Vitamins, not pain relief | ServiceNow coopetition positioning |

---

## Related Documents

| Document | Content |
|----------|---------|
| gis-nextgen-conceptual-erd-v1.2.md | Full data model with TBM-lite cost model |
| gis-involved-party-architecture-v1.7.md | Organization UI presentation, filtered views |
| gis-identity-security-architecture-v1.0.md | RBAC, SSO, security |
| gis-pricing-model-v1.0.md | Tiers, licensing, Steward economics |
| gis-nextgen-development-roadmap-v1.1.md | Sprint details, timeline |
| gis-cost-model-architecture-v2.4.md | Cost flow rules |
| gis-servicenow-alignment-v1.2.md | CSDM mapping |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.5 | 2026-02-01 | Added "Competitive Advantages (Marketing Nuggets)" section. Data residency & compliance advantage vs ServiceNow. Phase 21 initiative example. |
| v1.4 | 2025-12-19 | Added UI terminology section in Vendor & Software Management. Filtered views (Vendors, Manufacturers), contextual labels, admin-only unfiltered view. City of Garland validation. |
| v1.3 | 2025-12-16 | Expanded Cost Model section with TBM-lite details. Added Free-Standing DPs, cost flow diagrams, stranded cost explanation. |
| v1.2 | 2025-12-14 | Added Cost Model section. |
| v1.1 | 2025-12-12 | Initial version. |

---

*Document: gis-nextgen-explainer-v1.5.md*
*February 2026*
