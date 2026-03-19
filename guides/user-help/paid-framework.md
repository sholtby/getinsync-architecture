# PAID Quadrant Explanation

The PAID framework answers a different question from TIME: **"How urgently do we need to address technical debt?"**

While TIME tells you *what to do* (Invest, Tolerate, Modernize, Eliminate), PAID tells you *how fast to do it* by measuring business criticality against technical risk.

---

## The Four Quadrants

### Plan (High Business Criticality + Low Technical Risk)

The application is critical to the business and technically healthy. Keep it that way. Plan proactive maintenance — scheduled refresh cycles, regular patching, planned upgrades before anything goes end-of-life.

**Action:** Proactive maintenance and planned upgrades.

### Address (High Business Criticality + High Technical Risk)

This application is business-critical AND has serious technical problems. It demands immediate, funded remediation. This is your fire alarm — act now before it becomes an outage or a breach.

**Action:** Immediate remediation with dedicated resources.

### Ignore (Low Business Criticality + Low Technical Risk)

Low business importance, low technical risk. This application needs minimal attention. Check in periodically but do not allocate remediation budget.

**Action:** Minimal monitoring, no active investment.

### Delay (Low Business Criticality + High Technical Risk)

The application has technical debt, but the business impact of failure is low. You can afford to defer remediation — document the risk, accept it formally, and revisit when resources are available or business criticality changes.

**Action:** Documented risk acceptance with periodic review.

---

## How PAID Differs From TIME

TIME and PAID use the same underlying assessment factors but apply different calculations:

| Aspect | TIME | PAID |
|--------|------|------|
| **Question** | What should we do with this app? | How urgently should we fix technical debt? |
| **X-Axis** | Business Fit (all business factors weighted) | Business Criticality (subset of business factors) |
| **Y-Axis** | Technical Health (all technical factors weighted) | Technical Risk (inverted subset of risk-critical factors) |
| **Output** | Strategic direction | Remediation urgency |

### Business Criticality vs. Business Fit

Business Fit is a broad measure — it includes user satisfaction, functional coverage, and strategic alignment. Business Criticality is narrower — it focuses on how much damage would occur if this application failed. An app can have low Business Fit (nobody loves it) but high Business Criticality (the business stops without it).

### Technical Risk vs. Technical Health

Technical Health measures overall quality across 14 factors. Technical Risk zooms in on the 5 factors most likely to cause failures — platform currency, security controls, disaster recovery, vendor support, and architectural soundness. An app can have decent overall Technical Health but high Technical Risk if its security posture is weak.

---

## Using PAID With Your Roadmap

The PAID quadrant helps you prioritize Roadmap initiatives:

| Quadrant | Priority Level |
|----------|---------------|
| Plan | Next quarter, scheduled proactively |
| Address | Immediate, this sprint/quarter |
| Ignore | No action needed |
| Delay | Backlog, revisit when resources free up |

Pair PAID with TIME for a complete picture: TIME tells you the *direction* (modernize vs. retire), PAID tells you the *urgency* (now vs. later).

---

## Switching Between TIME and PAID

On the App Health tab, use the view toggle to switch between TIME and PAID views. The same applications are plotted on both charts — only the axes and scoring change.

---

## Next Steps

- [TIME Quadrant Explanation](time-framework.md) — Understand strategic direction scoring
- [How to Assess an Application](assessment-guide.md) — The assessment process that feeds both frameworks
- [Creating and Managing Initiatives](roadmap-initiatives.md) — Turn PAID urgency into funded projects
