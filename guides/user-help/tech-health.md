# Reading Tech Health Indicators

The Tech Health tab gives you a dashboard view of infrastructure risk across your entire portfolio. It answers the question: **"Where are we running on unsupported, end-of-life, or at-risk technology?"**

---

## What Is Tech Health?

Every application runs on technology — operating systems, databases, web servers, frameworks, runtimes. Each of those technology products has a lifecycle: the vendor supports it for a while, then stops. When support ends, you are exposed to security vulnerabilities, compliance gaps, and operational risk.

Tech Health tracks these lifecycles automatically and alerts you before problems arrive.

---

## The Dashboard View

When you open the Tech Health tab, you see:

### KPI Cards

Summary metrics across your portfolio:

- **Total Technologies** — How many distinct technology products are deployed across all applications
- **At Risk** — Technologies that are end-of-life or approaching end-of-life
- **Coverage** — What percentage of your technology stack has lifecycle data linked

### Lifecycle Status Breakdown

A chart showing how your technologies are distributed across lifecycle stages:

| Status | What It Means |
|--------|---------------|
| **Mainstream Support** | Fully supported by the vendor — regular patches, updates, and feature releases |
| **Extended Support** | Limited support, typically security patches only. No new features. Vendor is winding down. |
| **End of Support** | The vendor has stopped providing updates. No security patches. Running this is a risk. |
| **Unknown** | No lifecycle data linked — GetInSync does not yet know this product's support status |

---

## Filtering Data

Each data tab (By Application, By Technology, By Server) has a **Filters** button in the toolbar. Clicking it opens a slide-in panel from the right with multi-select checkboxes grouped by category.

- **By Application** — Filter by Workspace, Data Center, Lifecycle Status, or Crown Jewels
- **By Technology** — Filter by Category (Operating System, Database, Web Server) or Lifecycle Status
- **By Server** — Filter by Workspace or Lifecycle Status

You can select multiple values within each group. The filter badge in the toolbar shows how many filter groups are active. Click "Clear all" in the drawer to reset all filters.

Clicking a KPI card on the Analysis tab (e.g., "Extended Support") automatically switches to the By Technology tab with that filter pre-selected.

---

## By Technology View

Switch to the "By Technology" view to see risks grouped by technology product. For example:

- **Windows Server 2012 R2** — End of Support — used by 4 applications
- **Java 8** — Extended Support — used by 12 applications
- **PostgreSQL 14** — Mainstream Support — used by 6 applications

This view helps you identify which technology upgrades will have the biggest portfolio impact.

---

## Lifecycle Statuses Explained

### Mainstream Support

The vendor is actively developing this product. You receive:
- Security patches
- Bug fixes
- Feature updates
- Full technical support

**Action needed:** None. You are in a healthy state.

### Extended Support

The vendor has stopped adding features but still provides security patches (often for an additional fee). This is a warning sign — plan your upgrade.

**Action needed:** Begin planning migration to a supported version. See [Creating and Managing Initiatives](/roadmap-initiatives).

### End of Support (EoS)

The vendor no longer provides any updates. Known security vulnerabilities will not be patched. Running end-of-support technology is a compliance risk and an operational risk.

**Action needed:** Prioritize remediation. Create a Roadmap initiative to upgrade or replace.

---

## What the Badges Mean

Technology products in GetInSync may show verification badges:

| Badge | Meaning |
|-------|---------|
| **Verified** | Lifecycle dates confirmed against the vendor's official documentation or a trusted data source |
| **Unverified** | Lifecycle dates exist but have not been cross-checked against an authoritative source |
| **Stale** | Lifecycle data has not been refreshed in over 90 days — may be outdated |

Verified data gives you higher confidence when making decisions. If you see unverified or stale data, consider re-validating the lifecycle dates.

---

## How Lifecycle Data Gets Into GetInSync

GetInSync collects lifecycle data through multiple channels:

1. **Automatic lookup** — When you add a technology product, GetInSync searches public databases for lifecycle information
2. **Manual entry** — You can enter lifecycle dates directly if you have vendor documentation
3. **AI-assisted lookup** — For products not found in public databases, an AI lookup can search vendor sources

The more technologies you link to your deployment profiles, the more complete your Tech Health dashboard becomes.

---

## Taking Action on Findings

When you identify an at-risk technology:

1. **Check which applications are affected** — Click the technology to see all applications using it
2. **Assess the impact** — Is this technology running in production? How many users are affected?
3. **Create a Roadmap initiative** — Document the upgrade plan, timeline, and budget

See [Creating and Managing Initiatives](/roadmap-initiatives) for how to turn Tech Health findings into funded projects.

---

## Next Steps

- [What Are Deployment Profiles?](/deployment-profiles) — Understand where technologies are deployed
- [How to Assess an Application](/assessment-guide) — Use lifecycle data to inform technical scores
- [Creating and Managing Initiatives](/roadmap-initiatives) — Plan upgrades for at-risk technologies
- [Getting Started](/getting-started) — Back to the onboarding guide
