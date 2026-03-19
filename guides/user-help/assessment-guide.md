# How to Assess an Application

An assessment scores an application's business value and technical health. The results place it on the TIME and PAID quadrants, giving you a clear picture of what to do with it and how urgently.

This guide walks you through the process step by step.

---

## Before You Start

Make sure the application has at least one **deployment profile**. A deployment profile describes where and how the application runs (e.g., "SaaS on AWS" or "On-premises in Toronto data center"). Technical factors are scored per deployment profile, so you need at least one.

If the application has no deployment profile, add one first. See [What Are Deployment Profiles?](deployment-profiles.md).

---

## Starting an Assessment

1. Open any application from the dashboard or search results
2. Navigate to the **Assessment** section
3. Click **Start Assessment** (or **Update Assessment** if one already exists)

You will see two groups of factors to score: **Business** and **Technical**.

---

## Scoring Business Factors (B1–B10)

Business factors measure how well the application serves your organization. Rate each factor from **1** (poor) to **5** (excellent).

Here are the key factors and what they ask:

| Factor | Question |
|--------|----------|
| Strategic Alignment | Does this application support current business goals and strategy? |
| User Satisfaction | Are the people using this application satisfied with it? |
| Functional Coverage | Does the application do everything users need, or do they work around gaps? |
| Revenue / Cost Impact | Does this application directly drive revenue or significantly reduce costs? |
| Regulatory Necessity | Is this application required by law, regulation, or contractual obligation? |
| Organizational Reach | How broadly is this application used across the organization? |
| Data Quality | How reliable and accurate is the data this application produces? |

**Tip:** Business factor scores reflect business judgment, not technical opinion. If you are unsure, ask the application's business owner — they know the business value better than IT does.

---

## Scoring Technical Factors (T01–T14)

Technical factors measure the quality and risk of the application's infrastructure. These are scored **per deployment profile** — if your application runs in two locations, you assess each one separately.

| Factor | Question |
|--------|----------|
| Platform Currency | Is the underlying technology (OS, runtime, framework) current and supported? |
| Security Controls | Are proper authentication, authorization, and encryption measures in place? |
| Scalability | Can the application handle increased load without degradation? |
| Disaster Recovery | Is there a tested backup and recovery plan? |
| Integration Quality | Does the application connect cleanly with other systems? |
| Code Quality | Is the codebase maintainable, documented, and testable? |
| Vendor Support | Is the vendor actively supporting this version with patches and updates? |

**Tip:** Use the **Tech Health** tab to inform your scores. If GetInSync shows that a technology product is end-of-life, that is a strong signal for a low Platform Currency or Vendor Support score.

---

## Viewing Your Results

After scoring, you will see:

### TIME Quadrant Placement

Your application is plotted on the TIME chart (Business Fit vs. Technical Health). The quadrant tells you the recommended strategic action:

- **Invest** — Strategically important and technically sound. Fund and grow.
- **Tolerate** — Technically fine but low business value. Maintain only.
- **Modernize** — Business-critical but technically failing. Replatform or replace.
- **Eliminate** — Low value and poor technology. Plan retirement.

See [TIME Quadrant Explanation](time-framework.md) for details.

### PAID Quadrant Placement

The same scores also feed the PAID chart (Business Criticality vs. Technical Risk), which tells you how urgently to act. See [PAID Quadrant Explanation](paid-framework.md).

### Numeric Scores

You will also see the raw scores:
- **Business Fit** — 0 to 100
- **Technical Health** — 0 to 100
- **Business Criticality** — 0 to 100
- **Technical Risk** — 0 to 100

---

## Reassessing an Application

Assessments are not permanent. Reassess whenever circumstances change:

- A new version is deployed
- The vendor is acquired or changes support policy
- Business priorities shift
- A technology reaches end-of-life

Assessment history is tracked, so you can see how scores change over time.

---

## Tips for Better Assessments

1. **Involve the business owner.** Technical staff often undervalue business factors. Get input from the people who rely on the application daily.
2. **Use real data.** Check the Tech Health tab for lifecycle dates. Check usage logs for user counts. Do not guess when data is available.
3. **Be consistent.** Use the same scoring standards across all applications so comparisons are meaningful.
4. **Assess regularly.** Annual assessments keep your portfolio picture current. Set a calendar reminder.

---

## Next Steps

- [What Are Deployment Profiles?](deployment-profiles.md) — Make sure profiles exist before assessing
- [Reading Tech Health Indicators](tech-health.md) — Use lifecycle data to inform technical scores
- [Creating and Managing Initiatives](roadmap-initiatives.md) — Turn assessment results into action
