# GetInSync — Risk Management Boundary Decision

**Version:** 1.0  
**Date:** February 13, 2026  
**Status:** ✅ DECIDED  
**Decision:** Risk registers are GRC territory. GetInSync surfaces computed risk indicators from technology lifecycle data.

---

## 1. Decision

GetInSync will **not** build a risk register, risk acceptance workflow, or TRA tracking capability. These are Governance, Risk & Compliance (GRC) concerns served by purpose-built tools (ServiceNow GRC, Archer, LogicGate, OneTrust).

GetInSync **will** surface computed risk indicators automatically from technology lifecycle data, replacing manual risk identification with structured, real-time detection.

---

## 2. Context

A prospective customer shared their SharePoint-based cyber risk register (131 entries, 120 apps, ~80% citing EOL technology as the risk). Key observations:

- 122 of 131 risks (93%) are "Not Mitigated"
- 93 of 131 (71%) are stuck in "Draft" lifecycle stage
- The dominant risk description pattern is "EOL DB, OS" — a technology lifecycle fact, not a nuanced risk assessment
- The register is not being actively managed as a workflow — it's a list of known problems linked to applications

**Root cause:** The risk register exists because there's no structured system connecting applications to technology to lifecycle status. Someone has to manually look up "what does this app run on?" and "is that technology still supported?" then type the answer into SharePoint. GetInSync eliminates that manual step entirely.

---

## 3. What We Build (Computed Risk Indicators)

### 3.1 Automatic EOL Risk Detection

When technology is tagged on a deployment profile (Path 1 inventory) and lifecycle data is populated (Phase 38 AI lookup or manual entry), the system automatically computes risk:

```
Risk Level = f(lifecycle_status, time_to_eol)

  end_of_life / end_of_support           → Critical (red)
  extended, EOL < 6 months               → High (orange)  
  extended, EOL < 12 months              → Medium (amber)
  extended, EOL > 12 months              → Low (yellow)
  mainstream                             → None (green)
  unknown / no lifecycle data            → Unknown (gray)
```

This appears as:
- A risk badge on the Deployment Profile card
- A risk column in the Technology Health dashboard
- Summary KPIs: "47 deployments on EOL technology across 31 applications"
- Filterable by workspace (ministry), technology category, risk level

### 3.2 Blast Radius for Risk

When a technology product's lifecycle status changes (e.g., SQL Server 2016 moves from Extended to EOL), every deployment profile tagged with it is automatically flagged. The Technology Health dashboard shows:

```
SQL Server 2016 — END OF LIFE
├── 15 deployment profiles affected
├── 12 unique applications  
├── 6 workspaces (ministries)
├── 4 Crown Jewel applications
└── [View affected applications]
```

This is the "blast radius" query that their SharePoint list cannot answer.

### 3.3 Findings (IT Value Creation — Phase 21)

The IT Value Creation architecture already defines a "Findings" concept — observations linked to applications with severity, recommendation, and status. Technology lifecycle risks are auto-generated findings:

```
Finding: "EOL Technology — SQL Server 2016"
Severity: High
Application: Great Plains ERP
Deployment: Production — On-Premises  
Recommendation: "Upgrade to SQL Server 2019 or later"
Status: Open
Generated: Automatic (from lifecycle data)
```

Findings can also be manually created from TRA results, audits, or security reviews. But the key insight is: **most findings that would appear in a risk register are computable from data we already have.**

### 3.4 Data Classification (Application Attribute)

Their risk register tracks Data Classification (Class A/B/C/Public) per application. This is an application attribute, not a risk register field:

```sql
-- Already designed in application_data_assets stub
-- Can also be a direct field on applications for simplicity
ALTER TABLE applications
ADD COLUMN data_classification TEXT
  CHECK (data_classification IS NULL OR data_classification IN 
    ('public', 'internal', 'confidential', 'restricted'));
```

This feeds into risk prioritization: an EOL deployment running a Class A (confidential) application is higher priority than one running a Public application.

---

## 4. What We Explicitly Don't Build

| Capability | Why Not | Where It Belongs |
|---|---|---|
| Risk register (manual entry) | GRC workflow, not APM | ServiceNow GRC, Archer, LogicGate |
| Risk Acceptance Letters (RAL) | Document workflow | SharePoint, DocuSign, GRC tool |
| TRA tracking and links | Security assessment workflow | GRC tool |
| Risk Notice Memos | Communication workflow | Email, GRC tool |
| Risk Status lifecycle (Not Mitigated → Remediated) | Remediation tracking | ServiceNow GRC, ITSM |
| Security Officer assignment per risk | User/role management beyond APM | GRC tool, ITSM |
| Vendor vulnerability response tracking | Security operations | ServiceNow VR, Qualys, Tenable |

---

## 5. The Integration Story

GetInSync feeds GRC tools, it doesn't replace them:

```
GetInSync (APM)                          GRC Tool
──────────────                          ────────
Applications           ──export──→      Business Application CIs
Technology tags        ──export──→      Technology CI relationships
Lifecycle risk         ──export──→      Auto-generated risk entries
Data classification    ──export──→      Data asset classification
Blast radius           ──export──→      Impact analysis input

                       ←─import──      TRA results (as findings)
                       ←─import──      Audit findings
                       ←─import──      Compliance status
```

When the customer gets ServiceNow GRC, our CSDM-aligned data exports cleanly as the application context that GRC workflows reference. The risk register in ServiceNow GRC links to the Business Application CI that came from GetInSync.

---

## 6. Customer Pitch

### For the SharePoint Risk Register Customer

"Your risk register has 131 entries, and 80% of them say the same thing: this app runs on end-of-life technology. That's not a risk register problem — it's a data problem. Someone is manually looking up what technology each app runs on, checking if it's still supported, and typing that into SharePoint. That's why 93% of your entries are stuck in Draft.

GetInSync eliminates that manual step entirely. When you tag technology on a deployment, the system automatically shows lifecycle risk — in real time, across every application, with blast radius analysis. Your security team gets a live dashboard showing every EOL dependency, which applications are affected, which are Crown Jewels, and what data classification is at risk. No SharePoint list maintenance required.

For the 20% of risks that aren't technology lifecycle issues — the TRA findings, vendor vulnerabilities, audit results — those belong in a purpose-built GRC tool. When you're ready for ServiceNow GRC, our data feeds it directly because it's CSDM-aligned. We give you the application context. They give you the risk workflow."

### One-Liner

> "We detect the risks. GRC tools manage the response."

---

## 7. References

| Document | Relationship |
|---|---|
| `features/technology-health/dashboard.md` | Dashboard that surfaces computed risk indicators |
| `features/technology-health/technology-stack-erd-addendum.md` | Path 1 inventory that feeds risk detection |
| `features/technology-health/lifecycle-intelligence.md` | AI lifecycle lookup that populates status |
| `features/it-value-creation/architecture.md` | Findings concept for auto-generated observations |
| `catalogs/csdm-application-attributes.md` | Data classification, crown jewel attributes |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-02-13 | Initial decision. Risk register is GRC territory. Computed indicators replace 80% of manual risk identification. |
