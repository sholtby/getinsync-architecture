# TIME Quadrant Explanation

The TIME framework answers one question: **"What should we do with this application?"**

It plots every application on a two-axis chart — Business Fit on one axis, Technical Health on the other — and sorts them into four quadrants. Each quadrant maps to a clear strategic action.

---

## The Four Quadrants

### Invest (High Business Fit + High Technical Health)

This application is strategically important AND technically sound. It deserves continued investment — expand features, grow the user base, allocate budget for enhancements.

**Action:** Fund and grow.

### Tolerate (Low Business Fit + High Technical Health)

The technology is fine, but the business case is weak. The app works, but it is not a strategic priority. Keep the lights on with minimal investment — do not pour money into something the business does not need.

**Action:** Maintain, but do not invest.

### Modernize (High Business Fit + Low Technical Health)

The business depends on this application, but the technology is failing. The platform may be end-of-life, the architecture outdated, or the infrastructure fragile. This is your highest-risk quadrant — the app matters, but the foundation is crumbling.

**Action:** Replatform, re-architect, or replace the technology while preserving the business capability.

### Eliminate (Low Business Fit + Low Technical Health)

Neither the business case nor the technology justifies keeping this application. Plan a controlled decommission — migrate any remaining users and data, then retire it.

**Action:** Plan and execute retirement.

---

## How Scores Are Calculated

Each application receives two scores (0–100):

### Business Fit Score

Based on **business factors** (B1–B10) that measure how well the application serves the organization:

- Strategic alignment — Does it support business goals?
- User satisfaction — Are users happy with it?
- Functional coverage — Does it do what people need?
- Revenue or cost impact — Does it drive revenue or reduce costs?
- Regulatory necessity — Is it required for compliance?

Each factor is rated 1–5 by an assessor, then combined using weighted averages.

### Technical Health Score

Based on **technical factors** (T01–T14) that measure the application's infrastructure quality:

- Platform currency — Is the underlying technology current?
- Security controls — Are proper security measures in place?
- Scalability — Can it handle growth?
- Integration quality — Does it connect well with other systems?
- Vendor support status — Is the vendor still providing updates?

These are also rated 1–5 and weighted.

---

## Reading the Bubble Chart

On the App Health tab, you will see applications plotted as bubbles:

- **Position** — Where the bubble sits determines the quadrant (Invest, Tolerate, Modernize, Eliminate)
- **Size** — Bubble size represents the application's user base or cost weight
- **Color** — Indicates lifecycle status or assessment freshness

Hover over any bubble to see the application name and scores. Click to open its detail view.

---

## What To Do Next

Each quadrant maps naturally to a type of Roadmap initiative:

| Quadrant | Initiative Type |
|----------|----------------|
| Invest | Enhancement, expansion |
| Tolerate | Maintain as-is (no initiative needed) |
| Modernize | Migration, replatform, re-architecture |
| Eliminate | Retirement, decommission |

See [Creating and Managing Initiatives](roadmap-initiatives.md) to turn your TIME analysis into funded action plans.

---

## Common Misconceptions

- **TIME is not a risk framework.** It answers "what to do" (strategic direction), not "how urgent." For urgency, see the [PAID framework](paid-framework.md).
- **End-of-support does not automatically mean low Technical Health.** An assessor considers many factors — vendor support is only one of them.
- **Scores are not permanent.** Reassess applications whenever circumstances change (new deployment, vendor acquisition, business pivot).
