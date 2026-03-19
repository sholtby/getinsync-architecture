# Creating and Managing Initiatives

The Roadmap turns assessment findings into funded action plans. Every APM tool can tell you what condition your applications are in — the Roadmap tells you **what to do about it**.

---

## What Is an Initiative?

An initiative is a planned project that addresses one or more applications in your portfolio. It has:

- A **name** and description
- A **type** (what kind of work)
- A **priority** level
- A **timeline** (start and end dates)
- An **estimated cost**
- An **owner** responsible for delivery
- **Linked applications** that it addresses

Initiatives are how assessment results become action. A "Modernize" placement on the TIME quadrant becomes a funded migration project. An "Address" urgency on the PAID quadrant becomes a prioritized remediation effort.

---

## Initiative Types

Each initiative has a type that describes the nature of the work:

| Type | When to Use |
|------|-------------|
| **Modernize** | Upgrade the technology stack while keeping the application. Replatform, re-architect, or update to a current version. |
| **Migrate** | Move the application to a new hosting environment — cloud migration, data center consolidation, or SaaS transition. |
| **Consolidate** | Merge multiple applications that serve similar purposes into one. Reduce duplication and licensing costs. |
| **Retire** | Decommission the application. Migrate users and data to alternatives, then shut it down. |
| **Enhance** | Add features or capabilities to an application that is already healthy. Fund growth for strategic apps. |

---

## Creating an Initiative

1. Open the **Roadmap** tab from the main navigation
2. Click **Add Initiative**
3. Fill in the details:
   - **Name** — A clear, specific title (e.g., "Migrate HR System to SaaS" not "Fix HR stuff")
   - **Type** — Select from the types above
   - **Priority** — P1 (urgent) through P4 (backlog)
   - **Timeline** — Target start and end dates
   - **Estimated Cost** — Budget allocation for this work
   - **Owner** — The person accountable for delivery
4. **Link applications** — Select the applications this initiative addresses
5. Save

### Linking From Assessment Results

You can also create initiatives directly from assessment results:

- On the **App Health** tab, click an application in the Modernize or Eliminate quadrant
- In the application detail view, look for the "Create Initiative" option
- The initiative will be pre-linked to that application

---

## Tracking Progress

Each initiative moves through a status workflow:

| Status | Meaning |
|--------|---------|
| **Proposed** | Idea captured, not yet approved or funded |
| **Approved** | Approved by stakeholders, budget allocated |
| **In Progress** | Work has started |
| **Completed** | Work finished, results verified |
| **Cancelled** | Initiative abandoned (reason documented) |

Update the status as work progresses. The Roadmap dashboard reflects current status across all initiatives.

---

## The Roadmap Dashboard

The Roadmap tab provides several views of your initiatives:

### KPI Cards

- Total initiatives (active, completed, proposed)
- Budget allocated vs. spent
- Applications addressed

### Grid View

A filterable, sortable table of all initiatives. Use the filter drawer to narrow by type, priority, status, or owner.

### Dependencies

Some initiatives depend on others. For example, you might need to migrate a database before retiring the application that uses it. Document dependencies to ensure the right sequencing.

---

## Tips for Effective Roadmap Management

1. **Start with the PAID "Address" quadrant.** These are your highest-urgency items — business-critical applications with serious technical risk.
2. **Group related work.** If five applications all run on Windows Server 2012, create one "Windows Server Upgrade" initiative rather than five separate ones.
3. **Be realistic about timelines.** A migration initiative that spans 18 months is harder to track than three phased initiatives of 6 months each.
4. **Assign clear ownership.** Every initiative needs one accountable person, not a committee.
5. **Review quarterly.** Priorities change. Review your Roadmap each quarter to re-prioritize based on new assessment data, budget changes, or business shifts.

---

## Next Steps

- [TIME Quadrant Explanation](/user-help/time-framework) — Understand what drives the "what to do" decision
- [PAID Quadrant Explanation](/user-help/paid-framework) — Understand what drives the "how urgent" decision
- [Reading Tech Health Indicators](/user-help/tech-health) — Find at-risk technologies that need initiatives
- [Getting Started](/user-help/getting-started) — Back to the onboarding guide
