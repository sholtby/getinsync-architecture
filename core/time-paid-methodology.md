# core/time-paid-methodology.md
GetInSync TIME & PAID Analysis Methodology
Last updated: 2026-01-08

---

## 1. Purpose

Define the scoring algorithms, decision matrices, and weighted factors used to calculate TIME and PAID quadrants in GetInSync NextGen.

This document clarifies:
- **TIME Analysis** — Strategic portfolio rationalization (what to do with each app)
- **PAID Analysis** — Technical debt remediation prioritization (how urgently to fix)
- **The distinction between Technical Fitness and Technology Lifecycle**
- **How IT Services inform assessments without overriding them**

Audience: Product team, implementers, and customers configuring assessments.

---

## 2. Framework Overview

### 2.1 Two Frameworks, Two Questions

| Framework | Question Being Asked | Output |
|-----------|---------------------|--------|
| **TIME** | "What should we *do* with this application?" | Strategic direction |
| **PAID** | "How urgently do we need to *fix* technical debt?" | Remediation priority |

Both frameworks use the same underlying assessment factors (B1-B10, T01-T15) but with **different weightings** and **different derived scores**.

### 2.2 Key Conceptual Distinction

**Technical Fitness ≠ Technology Lifecycle**

| Concept | Definition | Example |
|---------|------------|---------|
| **Technical Fitness** | Is this technology the *right choice* for this application's requirements? | "Is Microsoft Access suitable for storing medical records?" (No — poor fitness) |
| **Technology Lifecycle** | Is this technology still supported by the vendor? | "Is Windows Server 2012 R2 supported?" (No — End of Support) |

- **Fitness** is a subjective judgment by the assessor based on application context
- **Lifecycle** is an objective fact based on vendor announcements

Both matter, but they are assessed differently:
- Fitness → T-scores on the Deployment Profile
- Lifecycle → Attributes on IT Services (which inform T-score assessments)

---

## 3. TIME Analysis

### 3.1 Purpose

Rationalizes the application portfolio by balancing **Business Fit** (value to the organization) against **Technical Health** (quality of the technology).

### 3.2 The TIME Matrix

|  | Low Business Fit | High Business Fit |
|--|------------------|-------------------|
| **High Tech Health** | **TOLERATE** (Top-Left) | **INVEST** (Top-Right) |
| **Low Tech Health** | **ELIMINATE** (Bottom-Left) | **MODERNIZE** (Bottom-Right) |

**Quadrant Definitions:**

| Quadrant | Characteristics | Recommended Action |
|----------|-----------------|-------------------|
| **INVEST** | High quality, high value | Expand & innovate; strategic priority |
| **TOLERATE** | High quality, low value | Keep lights on; maintain but don't enhance |
| **MODERNIZE** | Low quality, high value | Refactor, replatform, or replace; the app matters but tech is failing |
| **ELIMINATE** | Low quality, low value | Decommission; not worth fixing |

### 3.3 TIME Axes

- **X-Axis:** Business Fit (Value) — How well does this application serve business needs?
- **Y-Axis:** Technical Health (Quality) — How sound is the technology implementation?

### 3.4 Business Fit Calculation

Business Fit is a weighted average of business factors (B1-B10):

| Factor | Code | Weight |
|--------|------|--------|
| Alignment with Strategic Goals | B1 | 15% |
| Support for Regional Growth | B2 | 15% |
| Scope of Use | B4 | 15% |
| Business Process Criticality | B5 | 15% |
| Future Business Needs | B9 | 15% |
| Current Business Needs | B8 | 10% |
| User Satisfaction | B10 | 10% |
| Impact on Public Confidence | B3 | 5% |

**Formula:** `Business_Fit = Σ(Factor_Score × Weight) / Σ(Weights)`, normalized to 0-100

### 3.5 Technical Health Calculation

Technical Health is a weighted average of technical factors (T01-T15, excluding T12):

| Factor | Code | Weight |
|--------|------|--------|
| Platform Footprint | T01 | 10% |
| Vendor Support Status | T02 | 10% |
| Security Controls | T04 | 10% |
| Data Accessibility | T15 | 9% |
| Resilience & Recovery | T05 | 8% |
| Observability | T06 | 8% |
| Integration Capabilities | T07 | 8% |
| Integration Count | T14 | 7% |
| Identity Assurance | T08 | 6% |
| Development Platform Currency | T03 | 5% |
| Platform Portability | T09 | 5% |
| Configurability | T10 | 5% |
| Data Sensitivity Controls | T11 | 5% |
| Modern UX | T13 | 4% |

**Formula:** `Tech_Health = Σ(Factor_Score × Weight) / Σ(Weights)`, normalized to 0-100

### 3.6 TIME Quadrant Assignment

Default thresholds (configurable per Namespace):

| Condition | Quadrant |
|-----------|----------|
| Business Fit ≥ 50 AND Tech Health ≥ 50 | INVEST |
| Business Fit < 50 AND Tech Health ≥ 50 | TOLERATE |
| Business Fit ≥ 50 AND Tech Health < 50 | MODERNIZE |
| Business Fit < 50 AND Tech Health < 50 | ELIMINATE |

---

## 4. PAID Analysis

### 4.1 Purpose

Prioritizes **technical debt remediation** by balancing **Business Criticality** (impact if it fails) against **Technical Risk** (likelihood of failure or vulnerability).

### 4.2 The PAID Matrix

|  | Low Tech Risk | High Tech Risk |
|--|---------------|----------------|
| **High Criticality** | **PLAN** (Top-Left) | **ADDRESS** (Top-Right) |
| **Low Criticality** | **IGNORE** (Bottom-Left) | **DELAY** (Bottom-Right) |

**Quadrant Definitions:**

| Quadrant | Characteristics | Recommended Action |
|----------|-----------------|-------------------|
| **ADDRESS** | Critical app, high risk | Immediate remediation; top priority |
| **PLAN** | Critical app, low risk | Schedule improvements; proactive maintenance |
| **DELAY** | Non-critical, high risk | Fix when able; lower priority than ADDRESS |
| **IGNORE** | Non-critical, low risk | Accept the risk; minimal investment |

### 4.3 PAID Axes

- **X-Axis:** Technical Risk — How vulnerable is this application to failure or security issues?
- **Y-Axis:** Business Criticality — What's the impact if this application fails?

### 4.4 Business Criticality Calculation

Criticality uses a **subset** of business factors with different weightings:

| Factor | Code | Weight |
|--------|------|--------|
| Business Process Criticality | B5 | 20% |
| Essential Service Delivery | B7 | 20% |
| Impact on Public Confidence | B3 | 15% |
| Scope of Use | B4 | 15% |
| Tolerance for Interruption | B6 | 15% |
| Alignment with Strategic Goals | B1 | 10% |
| Support for Regional Growth | B2 | 5% |

**Formula:** `Criticality = Σ(Factor_Score × Weight) / Σ(Weights)`, normalized to 0-100

### 4.5 Technical Risk Calculation

Technical Risk uses a **subset** of technical factors, **inverted** (low health = high risk):

| Factor | Code | Weight |
|--------|------|--------|
| Security Controls | T04 | 25% |
| Vendor Support Status | T02 | 20% |
| Resilience & Recovery | T05 | 20% |
| Data Sensitivity Controls | T11 | 20% |
| Development Platform Currency | T03 | 15% |

**Formula:** `Tech_Risk = 100 - (Σ(Factor_Score × Weight) / Σ(Weights))`, normalized to 0-100

Note: The inversion means a low T-score (poor fitness) results in a high Tech Risk score.

### 4.6 PAID Quadrant Assignment

Default thresholds (configurable per Namespace):

| Condition | Quadrant |
|-----------|----------|
| Criticality ≥ 50 AND Tech Risk ≥ 50 | ADDRESS |
| Criticality ≥ 50 AND Tech Risk < 50 | PLAN |
| Criticality < 50 AND Tech Risk ≥ 50 | DELAY |
| Criticality < 50 AND Tech Risk < 50 | IGNORE |

---

## 5. IT Services and Lifecycle

### 5.1 Role of IT Services

IT Services represent shared technology platforms (databases, servers, identity systems) that Deployment Profiles depend on.

**IT Services provide:**
- Reference data for assessors (what platform, what version, what support status)
- Cost allocation (stranded cost model)
- Dependency visibility (which DPs rely on which services)

**IT Services do NOT:**
- Automatically override T-scores
- Replace assessor judgment
- Calculate scores independently

### 5.2 Lifecycle Status on IT Services

Each IT Service carries lifecycle attributes:

| Attribute | Description | Example |
|-----------|-------------|---------|
| `platform_name` | Technology name | "SQL Server", "Oracle", "Windows Server" |
| `platform_version` | Specific version | "2019", "11g", "2022" |
| `support_status` | Vendor support tier | `mainstream`, `extended`, `end_of_support` |
| `support_end_date` | When support ends/ended | "2030-01-14" |

### 5.3 How Lifecycle Informs Assessment

When an assessor evaluates a Deployment Profile, they can see the linked IT Services and their lifecycle status. This **informs** their T-score judgments:

**Example 1: Healthy Infrastructure**
```
DP: "Sage 300 GL - PROD"
└── Linked IT Service: "Central SQL Cluster 01"
    ├── Platform: SQL Server 2019
    └── Support Status: Mainstream (until 2030)

Assessor sees healthy infrastructure → Scores T02 (Vendor Support) = 4 or 5
```

**Example 2: At-Risk Infrastructure**
```
DP: "Legacy Payroll - PROD"
└── Linked IT Service: "Oracle 11g Cluster"
    ├── Platform: Oracle 11g
    └── Support Status: End of Support (expired 2021) ⚠️

Assessor sees EoS dependency → Scores T02 (Vendor Support) = 1 or 2
```

The lifecycle status is an **input to human judgment**, not an automatic override.

### 5.4 Lifecycle Risk Reporting

IT Service lifecycle enables powerful reports without changing the assessment model:

**"DPs on End-of-Support Infrastructure"**

| IT Service | Support Status | Linked DPs | Avg Tech Risk |
|------------|---------------|------------|---------------|
| Oracle 11g Cluster | End of Support | 12 | 72 |
| Windows 2012 R2 | End of Support | 8 | 68 |
| SQL Server 2016 | Extended | 23 | 45 |

This gives Central IT visibility into exposure without overcomplicating the scoring model.

---

## 6. Configuration

### 6.1 Namespace-Level Settings

Assessment configuration is scoped to the **Namespace** level:

- **Factor Questions:** Customizable text for each B and T factor
- **Factor Weights:** Adjustable percentages (must sum to 100% per category)
- **Derived Score Formulas:** Which factors contribute to Criticality and Tech Risk
- **Quadrant Thresholds:** Adjustable boundary values (default: 50)

### 6.2 Tier Availability

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| View factor configuration | ✅ | ✅ | ✅ |
| Edit factor questions | ❌ | ✅ | ✅ |
| Edit factor weights | ❌ | ✅ | ✅ |
| Edit derived score formulas | ❌ | ❌ | ✅ |
| Add/remove factors | ❌ | ❌ | ✅ |

---

## 7. Score Placement Summary

### 7.1 Where Scores Live

| Score Type | Lives On | Reason |
|------------|----------|--------|
| B1-B10 (Business Factors) | Portfolio Assignment | Business context varies by portfolio |
| T01-T15 (Technical Factors) | Deployment Profile | Technical reality is deployment-specific |
| Business Fit | Portfolio Assignment | Derived from B-scores |
| Tech Health | Deployment Profile | Derived from T-scores |
| Criticality | Portfolio Assignment | Derived from subset of B-scores |
| Tech Risk | Deployment Profile | Derived from subset of T-scores |
| TIME Quadrant | Portfolio Assignment | Combines Business Fit + Tech Health |
| PAID Quadrant | Portfolio Assignment | Combines Criticality + Tech Risk |

### 7.2 Calculation Flow

```
Deployment Profile
├── T01-T15 scores (manual assessment)
├── Tech Health = weighted average of all T-scores
└── Tech Risk = inverted weighted average of risk-relevant T-scores

Portfolio Assignment
├── B01-B10 scores (manual assessment)
├── Business Fit = weighted average of all B-scores
├── Criticality = weighted average of criticality-relevant B-scores
├── TIME Quadrant = f(Business Fit, Tech Health from DP)
└── PAID Quadrant = f(Criticality, Tech Risk from DP)
```

---

## 8. Common Misconceptions

### 8.1 "TIME tells me what's risky"

**Incorrect.** TIME tells you what's *valuable* and what's *healthy*. An app in TOLERATE isn't necessarily risky — it's just not strategically important.

**Use PAID** to identify risk. ADDRESS quadrant = high criticality + high risk = urgent remediation.

### 8.2 "End of Support automatically means high Tech Risk"

**Incorrect.** End of Support is an **input** to the assessor's judgment on T02 (Vendor Support). The assessor still evaluates whether the lack of support actually creates risk in context.

Example: An air-gapped system on EoS Windows might score T02=3 if the isolation mitigates the risk.

### 8.3 "Tech Health and Tech Risk are the same thing"

**Incorrect.** They use the same factors but with different subsets and weightings:

- **Tech Health** = Overall quality (all 14 T-factors)
- **Tech Risk** = Vulnerability exposure (5 risk-critical T-factors, inverted)

An app can have moderate Tech Health but low Tech Risk if its weaknesses are in non-critical areas (e.g., poor UX doesn't create security risk).

---

## 9. References

- Gartner TIME Model (Application Portfolio Analysis)
- Gartner PAID Model (Technical Debt Prioritization)
- `core/core-architecture.md` — Overall system architecture
- `archive/superseded/deployment-profile-v1_7.md` — DP-centric assessment model
- `catalogs/it-service.md` — IT Service catalog and cost model
- `14-assessment-configuration-admin.md` — Admin UI for factor configuration

---

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-08 | Initial document. Consolidated TIME/PAID methodology, factor weightings, and clarified fitness vs lifecycle distinction. |

End of file.
