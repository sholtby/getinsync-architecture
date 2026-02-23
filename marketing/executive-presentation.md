# GetInSync NextGen
## Leadership Presentation
### December 2025

---

# Agenda

| Section | Topic | Time |
|---------|-------|------|
| 1 | The Problem: Why We're Changing | 10 min |
| 2 | The Opportunity: Who We're Building For | 10 min |
| 3 | The Solution: What NextGen Is | 15 min |
| 4 | The Business Model: How We Make Money | 10 min |
| 5 | The Roadmap: How We Get There | 10 min |
| 6 | The Ask: What We Need | 5 min |

**Total: 60 minutes (including discussion)**

*Please interrupt with questions—this is a conversation, not a lecture.*

---

# Part 1: The Problem

## Why We're Changing Everything

---

## Legacy GetInSync Was Vitamins

**Vitamins:** Nice to have. Take them if you remember. Skip them if you're busy.

That's how the market saw us:

- "APM is interesting, but we have spreadsheets"
- "Maybe next quarter"
- "What's the ROI again?"

**Result:**
- Long sales cycles for small deals
- MSP channel didn't gain traction
- High support burden for low revenue

---

## The SME Market Didn't Work

| What We Expected | What Happened |
|------------------|---------------|
| MSPs would resell to their clients | MSPs didn't see the value |
| SMEs would self-serve | SMEs wanted spreadsheets |
| Quick sales, quick wins | Long cycles, constant negotiation |

**The hard truth:** We were selling vitamins to people who didn't feel sick.

---

## Meanwhile, ServiceNow Customers Are Drowning

ServiceNow APM (Application Portfolio Management) is powerful. It's also:

| Factor | Reality |
|--------|---------|
| Cost | $150K - $500K+ per year |
| Implementation | $200K+ professional services |
| Timeline | 6-12 months to implement |
| Time to Value | 12-18 months before ROI |
| Complexity | Requires dedicated admin |
| CSDM 5.0 | Coming soon, even more complex |

**These organizations need APM. They just can't afford ServiceNow's version of it.**

---

## Pain Relief vs. Vitamins

| Vitamins (Legacy) | Pain Relief (NextGen) |
|-------------------|----------------------|
| "APM is best practice" | "Escape ServiceNow complexity" |
| "You should track your apps" | "Your 50 app owners can update their own data" |
| "Nice dashboards" | "Pass your security assessment" |
| "Maybe someday" | "We need this now" |

**NextGen is pain relief for organizations that need ServiceNow capabilities but can't justify ServiceNow costs.**

---

## Discussion: The Problem

- Does this match what you're seeing in the market?
- Are there other pain points we should address?

---

# Part 2: The Opportunity

## Who We're Building For Now

---

## The New Target Customer

**Organizations that could buy ServiceNow but want simpler, faster, cheaper.**

| Characteristic | Description |
|----------------|-------------|
| Size | 1,000 - 10,000+ employees |
| Structure | Multiple departments/divisions/ministries |
| IT Maturity | Has ITSM, considering or using ServiceNow |
| Pain | Needs APM, overwhelmed by ServiceNow complexity |
| Budget | $50K - $150K for APM (not $500K) |

---

## Why Government is Our Beachhead

Government organizations are ideal early customers:

| Factor | Why It Matters |
|--------|----------------|
| Multiple ministries | Natural fit for Namespace/Workspace model |
| ServiceNow presence | They understand CSDM, feel the pain |
| Compliance requirements | Forces them to track applications |
| Stable budgets | Multi-year contracts possible |
| Reference value | "Province of Saskatchewan uses GetInSync" |

**Saskatchewan is our pilot target.**

---

## The Saskatchewan Opportunity

| Attribute | Value |
|-----------|-------|
| Ministries | 27 (= 27 Workspaces) |
| Applications | Hundreds across government |
| App Owners | 200+ people who need to update data |
| Current State | Spreadsheets, fragmented tracking |
| ServiceNow | Have it for ITSM, APM too expensive |

**If we can win Saskatchewan, we can win any provincial/state government.**

---

## What Saskatchewan Needs

From their RFP requirements:

| Requirement | Our Answer |
|-------------|------------|
| Canadian data hosting | ✅ AWS Canada region |
| Entra ID SSO / MFA | ✅ Planned for Q1 2026 |
| RBAC | ✅ Designed, building Q2 2026 |
| 99.9% availability | ⚠️ We're targeting 99.5% (discuss) |
| WAF, SIEM integration | ✅ AWS native services |
| SOC 2 | ⚠️ Q2 2027 target |

**Key insight: Security is the gate. Features come second.**

---

## Discussion: The Opportunity

- Is Saskatchewan the right pilot customer?
- Are there other enterprise targets we should pursue?
- What concerns do you have about the government market?

---

# Part 3: The Solution

## What NextGen Actually Is

---

## The Big Picture

NextGen isn't a rewrite. It's an evolution with strategic enhancements:

| What Stays | What Changes |
|------------|--------------|
| Core APM functionality | Multi-tenant hierarchy |
| .NET platform | Identity model (Individual + Contact) |
| SQL Server database | RBAC (5 roles, not implicit) |
| Swagger API | Licensing model (Editor Pool) |
| | Steward role (new) |
| | Entra ID SSO (new) |
| | Canadian data residency (new) |

---

## Change 1: Multi-Tenant Hierarchy

**Legacy:** Account (flat or loosely hierarchical)

**NextGen:**

```
Region (Data Residency - e.g., Canada, US)
  └── Namespace (Customer/Billing - e.g., Province of Saskatchewan)
        └── Workspace (Department - e.g., Ministry of Justice)
              └── WorkspaceGroup (Reporting - e.g., "All Ministries")
```

**Why it matters:**
- Data residency compliance (Canada stays in Canada)
- Clear billing boundary (Namespace)
- Department autonomy (Workspace)
- Cross-department reporting (WorkspaceGroup)

---

## Change 2: Identity Model

**Legacy:** User and Contact somewhat conflated

**NextGen:**

| Entity | Scope | Purpose |
|--------|-------|---------|
| **Individual** | Platform | The real person (links to Entra ID) |
| **Contact** | Workspace | The person as seen in THIS Workspace |
| **WorkspaceRole** | Contact | What they can do HERE |

**Why it matters:**
- One person can have different roles in different Workspaces
- Clean SSO integration (Individual.ExternalIdentityKey = Entra OID)
- License counting at the right level

---

## Change 3: RBAC (Role-Based Access Control)

**Legacy:** Implicit, somewhat unclear boundaries

**NextGen:** Five explicit roles

| Role | Create | Edit | View | Dashboards | License |
|------|--------|------|------|------------|---------|
| **Admin** | ✅ All | ✅ All | ✅ All | ✅ | Editor |
| **Editor** | ✅ All | ✅ Assigned | ✅ All | ✅ | Editor |
| **Steward** | ❌ | ✅ Owned (Business Fit) | ✅ All | ✅ | Free* |
| **Read-Only** | ❌ | ❌ | ✅ All | ✅ | Free |
| **Restricted** | ❌ | ❌ | ⚠️ Assigned | ❌ | Free |

*Steward is Enterprise tier only

**Philosophy:** "Why are you in GetInSync if you're limited?" Transparency is the default.

---

## Change 4: The Steward Role

**The problem Steward solves:**

Without Steward:
- 50 Application Owners need to update their app data
- 50 Application Owners need Editor licenses
- 50 × $2,500 = $125,000 in additional licensing
- OR: Shadow spreadsheets, stale data, defeated purpose

With Steward:
- 50 Application Owners get Steward rights (free, Enterprise tier)
- They update Business Fit (TIME) for THEIR apps only
- 5-10 power users are Editors (included in base)
- No spreadsheets. Data stays accurate.

---

## What Steward Can (and Can't) Do

| Can Do | Cannot Do |
|--------|-----------|
| Edit Business Fit (TIME scores) | Edit Technology Fit |
| Edit app metadata (name, description) | Edit Deployment Profiles |
| Add up to 2 Delegates | Edit Contracts |
| View everything in Workspace | Create/Delete Applications |
| Access dashboards | Manage Portfolios |

**Steward is derived from ownership:** If you're the Owner or Delegate on an Application, you get Steward rights on that Application. No separate license needed.

---

## The Steward Value Proposition

**Saskatchewan example:**

| Scenario | Cost |
|----------|------|
| 200 App Owners as Editors | 200 × $2,000 = **$400,000/year** |
| 200 App Owners as Stewards | **$0** (included in Enterprise) |

**Steward saves Saskatchewan $400,000/year.**

That's not a feature. That's a business case.

---

## Change 5: CSDM Alignment

**CSDM** (Common Service Data Model) is ServiceNow's architecture. We align with it:

```
Business Application (What)
    "Payroll System"
         │
         ▼
Deployment Profile (Where)
    "Production in Azure"
    "DR in AWS"
         │
         ▼
IT Service (Infrastructure)
    "Azure SQL"
    "Shared Storage"
```

**Why it matters:**
- ServiceNow customers understand this immediately
- Clean separation of logical vs. physical
- Accurate cost allocation

---

## Change 6: Software Products Have a Home

**The old problem:** Where does Canva go? Adobe Creative Cloud? Snag-It?

- Not IT Services (that's infrastructure)
- Not Applications (that's business capability)
- Result: IT Services polluted with software licenses

**NextGen:**

| Entity | What Goes Here |
|--------|----------------|
| **IT Service** | Infrastructure (Azure, AWS, shared storage) |
| **Software Product** | Commercial software (Adobe, Microsoft 365, Canva) |
| **Business Application** | Business capability (Payroll System, CRM) |

**Clean separation. No more pollution.**

---

## Discussion: The Solution

- Does the Steward concept resonate?
- Is the RBAC model clear?
- Questions about the architecture?

---

# Part 4: The Business Model

## How We Make Money

---

## Three Tiers

| Tier | Annual | Workspaces | Editors | Steward |
|------|--------|------------|---------|---------|
| **Essentials** | $15,000 | 5 | 5 | ❌ |
| **Plus** | $30,000 | 10 | 10 | ❌ |
| **Enterprise** | $62,500 | 25 | 25 | ✅ Unlimited |

**Baseline:** 1 Editor per Workspace (1:1 ratio)

**Steward is the Enterprise differentiator.** Organizations that need Steward are Enterprise customers by definition.

---

## Why This Pricing Works

### Validated Against City of Garland (Current Customer)

| Component | Calculation |
|-----------|-------------|
| Enterprise Base | $62,500 |
| Public Sector Discount (20%) | -$12,500 |
| **Customer Pays** | **$50,000** ✓ |
| Partner Margin (20%) | -$10,000 |
| **GetInSync Receives** | **$40,000** ✓ |

**Matches our current deal structure exactly.**

---

## Upgrade Economics

**When does Enterprise make sense?**

| Profile | Plus Cost | Enterprise Cost | Winner |
|---------|-----------|-----------------|--------|
| 10 WS, 10 Editors | $30,000 | $62,500 | Plus |
| 10 WS, 20 Editors | $55,000 | $62,500 | Plus (barely) |
| 10 WS, 24+ Editors | $65,000+ | $62,500 | **Enterprise** |
| Need Steward | N/A | $62,500 | **Enterprise** |
| Need API Access | N/A | $62,500 | **Enterprise** |

**Rule of thumb:** 24+ Editors or need Steward → Enterprise

---

## Contract Terms

| Term | Discount | Payment |
|------|----------|---------|
| 1-Year | None | Annual upfront |
| 3-Year | 15% | **All 3 years upfront** |

**Why 3-year prepay?**

NPV analysis at 5% discount rate:
- Customer saves ~$15,000 in real terms
- GetInSync gets cash upfront + zero churn risk

**Win-win.**

---

## vs. ServiceNow

| Factor | ServiceNow APM | GetInSync |
|--------|----------------|-----------|
| Annual Cost | $150K - $500K+ | $15K - $150K |
| Implementation | $200K+ | Included |
| Time to Value | 12-18 months | 30-60 days |
| Complexity | Dedicated admin required | Self-service |
| Steward-like feature | Costs extra | Included (Enterprise) |

**We're not the cheap option. We're the smart option.**

---

## Discussion: Business Model

- Does the pricing feel right?
- Concerns about the Enterprise tier at $62.5K?
- Questions about the Steward economics?

---

# Part 5: The Roadmap

## How We Get There

---

## The Timeline

```
Dec 2025    Q1 2026           Q2 2026           Q3 2026        Q4 2026 → Q2 2027
    |           |                 |                 |                 |
    |    [Phase 1: Security]  [Phase 2: Features]  [Phase 3]    [Phase 4]
    |     & Core               & Polish            Pilot        Compliance
    |           |                 |                 |                 |
    ▼           ▼                 ▼                 ▼                 ▼
  Plan     SSO + Canada       RBAC + Steward    Saskatchewan     SOC 2
  Now      Region Ready       MVP Complete        Live          Certified
```

---

## Phase 1: Security & Core (Q1 2026)

**Goal:** Pass Saskatchewan security assessment

| Sprint | Month | Focus | Key Deliverables |
|--------|-------|-------|------------------|
| 1 | January | Infrastructure | Canada region, WAF, backups, schema migrations |
| 2 | February | Authentication | Entra ID SSO, Individual entity |
| 3 | March | Hierarchy | Workspace rename, Namespace enforcement |

**Exit criteria:** Can pass government security assessment

---

## Phase 2: Features & Polish (Q2 2026)

**Goal:** Complete NextGen MVP

| Sprint | Month | Focus | Key Deliverables |
|--------|-------|-------|------------------|
| 4 | April | RBAC | WorkspaceRole enforcement, all 5 roles |
| 5 | May | Steward | Derived permissions, Quick Entry Form |
| 6 | June | Polish | Editor Pool, testing, documentation |

**Exit criteria:** Production-ready for pilot

---

## Phase 3: Pilot (Q3 2026)

**Goal:** Saskatchewan live

| Month | Activity |
|-------|----------|
| July | Onboarding kickoff, data migration planning |
| August | Data migration, Entra ID config, UAT |
| September | Go-live, hypercare |

---

## Phase 4: Compliance (Q4 2026 - Q2 2027)

**Goal:** SOC 2 Type II certification

| Milestone | Target |
|-----------|--------|
| Gap assessment | October 2026 |
| Remediation | Nov-Dec 2026 |
| Audit period | Jan-Mar 2027 |
| Report issued | April-May 2027 |

**Estimated cost:** $55-100K (auditor + tooling + remediation)

---

## The AI Advantage

**These estimates assume AI-assisted development (Claude, Codex).**

| Task Type | AI Leverage | Impact |
|-----------|-------------|--------|
| Schema migrations | Very High | 3-4x faster |
| Bulk refactoring | Very High | 4-6x faster |
| CRUD scaffolding | High | 3-5x faster |
| Authorization code | High | 2-3x faster |
| Test generation | High | 3-4x faster |
| Documentation | Very High | 5-10x faster |

**Without AI:** 12-18 months
**With AI:** 6 months

---

## Effort Estimate

| Phase | Hours | Jason @ 80 hrs/mo |
|-------|-------|-------------------|
| Phase 1 | 180-265 | ✅ Fits in Q1 |
| Phase 2 | 235-320 | ⚠️ Tight, may overflow |
| **Total Dev** | **415-585** | **6 months** |

**Buffer:** ~15% contingency built in

---

## Discussion: Roadmap

- Does this timeline feel achievable?
- What risks do you see?
- Questions about the sequencing?

---

# Part 6: The Ask

## What We Need

---

## The Key Decision

**We need Jason at 80 hours/month for 6 months.**

| Scenario | Timeline | Saskatchewan Ready |
|----------|----------|-------------------|
| Jason at 30 hrs/mo (current) | 12-16 months | Q4 2027 |
| **Jason at 80 hrs/mo** | **6 months** | **Q3 2026** |
| Jason at 160 hrs/mo | 2.5-3 months | Q1 2026 |

**Recommendation:** 80 hours/month balances speed with sustainability.

---

## Why This Investment Makes Sense

| Factor | Impact |
|--------|--------|
| Saskatchewan pilot | Anchor customer, reference, revenue |
| Enterprise positioning | Higher ACV, better margins |
| Steward differentiation | Unique in market |
| SOC 2 certification | Opens government market |
| ServiceNow alternative | Large addressable market |

**One pilot win validates the entire pivot.**

---

## What Else We Need

| Who | Ask |
|-----|-----|
| **Jason** | 80 hrs/month commitment, input on sprint sequencing |
| **Sales** | Focus on enterprise pipeline, pause SME pursuit |
| **Marketing** | Begin repositioning messaging |
| **Leadership** | Approve investment, support pivot |

---

## Next Steps

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Jason confirms 80 hr/month | Jason | This week |
| 2 | AWS Canada region scoping | Jason | January |
| 3 | Saskatchewan engagement begins | Stuart | January |
| 4 | Sprint 1 kickoff | Jason | January |
| 5 | Monthly progress reviews | All | Ongoing |

---

## The Bottom Line

**We're not just building features. We're repositioning the company.**

| From | To |
|------|-----|
| SME vitamins | Enterprise pain relief |
| Competing with spreadsheets | Competing with ServiceNow |
| Unclear differentiation | Steward as unique value |
| US-only hosting | Canadian data residency |
| Uncertain timeline | 6-month roadmap with pilot |

**The architecture is designed. The pricing is validated. The roadmap is clear.**

**We need Jason's time to make it real.**

---

## Discussion: The Ask

- Can we commit to Jason at 80 hours/month?
- What concerns need to be addressed?
- Are we aligned on the pivot?

---

# Appendix

## Supporting Documents

| Document | Content |
|----------|---------|
| core/conceptual-erd.md | Full data model |
| archive/superseded/identity-security-v1_0.md | RBAC, SSO, SOC 2 |
| marketing/pricing-model.md | Tiers, discounts, validation |
| planning/q1-2026-master-plan.md | Sprint details, estimates |
| features/integrations/servicenow-alignment.md | CSDM mapping |

---

## Saskatchewan Requirements (Detail)

| Requirement | Status |
|-------------|--------|
| Canadian data hosting | 🔴 Need Canada region |
| Entra ID SSO / MFA | 🔴 Need to build |
| RBAC | 🔴 Need to build |
| 99.9% availability | ⚠️ Targeting 99.5% |
| RTO 24h, RPO 12h | ✅ We exceed |
| 30-day backup | ✅ AWS Backup |
| WAF | 🟡 AWS WAF (enable) |
| SIEM | 🟡 CloudWatch + export |
| SOC 2 | ⚠️ Q2 2027 target |

---

## Pricing Validation (Detail)

### City of Garland

| Line | Amount |
|------|--------|
| Enterprise Base | $62,500 |
| Public Sector (20%) | -$12,500 |
| **Customer Pays** | **$50,000** |
| Partner Margin (20%) | -$10,000 |
| **GetInSync Receives** | **$40,000** |

### Province of Saskatchewan (Projected)

| Line | Amount |
|------|--------|
| Enterprise Base | $62,500 |
| +2 Workspaces | $6,000 |
| +25 Editors | $50,000 |
| **List Total** | **$118,500** |
| Public Sector (20%) | -$23,700 |
| **Customer Pays** | **$94,800** |

Plus unlimited Stewards (200+ app owners) at no additional cost.

---

# Thank You

Questions?

---

*Document: marketing/executive-presentation.md*
*Date: December 2025*
