# APM Assessment Factor Labels

## Business Fit Factors (B1–B10)

| Code | Factor Name |
|------|-------------|
| B1 | Strategic Contribution |
| B2 | Regional Growth Support |
| B3 | Public Confidence Impact |
| B4 | Scope of Use |
| B5 | Business Process Criticality |
| B6 | Business Interruption Tolerance |
| B7 | Essential Service Impact |
| B8 | Current Needs Fulfillment |
| B9 | Future Needs Adaptability |
| B10 | User Satisfaction |

**Score scale:** 1 (lowest) → 5 (highest), normalized 0–100.

**Business Fit Score:** Weighted average of B1–B10.

**Criticality Score:** Derived from B5 (Business Process Criticality), B6 (Business Interruption Tolerance), and B7 (Essential Service Impact). Represents operational dependency, not strategic value.

---

## Technical Fit Factors (T01–T14)

| Code | Factor Name |
|------|-------------|
| T01 | Platform / Product Footprint |
| T02 | Application Development Platform |
| T03 | Platform Portability |
| T04 | Configurability & Extensibility |
| T05 | Support for Modern UX |
| T06 | Security Controls |
| T07 | Security Controls for Data Sensitivity |
| T08 | Identity Assurance |
| T09 | Resilience & Recovery |
| T10 | Observability & Manageability |
| T11 | Vendor and Support Availability |
| T12 | Integration Capabilities |
| T13 | Integrations |
| T14 | Data Accessibility |

**Score scale:** 1 (lowest) → 5 (highest), normalized 0–100.

**Technical Fit Score:** Weighted average of T01–T14.

---

## TIME Quadrant Definitions (SaskBuilds)

| Quadrant | Business Fit | Technical Fit | Interpretation |
|----------|-------------|---------------|----------------|
| **Invest** | ≥ 50 | ≥ 50 | Core asset — enhance and protect |
| **Modernize** | ≥ 50 | < 50 | Business value intact, platform aging — re-platform or upgrade |
| **Tolerate** | < 50 | ≥ 50 | Technically sound, limited strategic value — maintain, watch for exit |
| **Eliminate** | < 50 | < 50 | Limited value on both dimensions — plan retirement or consolidation |

**Note:** SaskBuilds uses "Modernize" in place of Gartner's original "Migrate" designation.

**Criticality as urgency modifier:** In the absence of PAID (Tech Risk) data, Criticality score determines urgency within each quadrant:

| Range | Meaning |
|-------|---------|
| 0–25 | Low dependency — change carries minimal risk |
| 26–50 | Moderate dependency — requires planning and coordination |
| 51–75 | Significant dependency — sequenced delivery needed |
| 76–100 | High dependency — immediate and material impact on operations |
