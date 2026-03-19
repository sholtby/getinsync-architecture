# What Are Deployment Profiles?

A deployment profile describes **where and how** a specific instance of an application runs. It is one of the most important concepts in GetInSync — and the one that often surprises people.

---

## The Core Idea

The same application software can be deployed in multiple ways. SAP running in your Toronto data center has different technical health characteristics than SAP running as SaaS in AWS. You need to assess each deployment separately to get an accurate picture.

A deployment profile captures the specifics of one deployment:

- **Where** it runs (on-premises, cloud, SaaS, hybrid)
- **Which cloud** or data center it uses
- **What environment** it serves (production, DR, test, development)
- **How much** it costs to operate

---

## Why It Matters

Without deployment profiles, you would have one set of scores for "SAP" — but that does not reflect reality. Your cloud-hosted SAP instance might be technically healthy, while your legacy on-premises one is running on an end-of-life operating system.

Deployment profiles let you:

- **Assess each deployment independently** — Technical factors (T01–T15) are scored per profile
- **Track costs per deployment** — Know what each instance actually costs
- **Identify infrastructure risk** — See which specific deployments are running on unsupported platforms
- **Plan migrations** — Document the target state alongside the current state

---

## What a Profile Contains

Each deployment profile captures:

| Field | Description |
|-------|-------------|
| **Environment** | Production, Disaster Recovery, Test, Development, or Staging |
| **Hosting Type** | SaaS, Cloud (IaaS/PaaS), On-Premises, Hybrid, Third-Party Hosted, or Desktop |
| **Cloud Provider** | AWS, Azure, GCP, Oracle Cloud, or other (if cloud-hosted) |
| **Region** | The geographic region or data center where it runs |
| **Data Center** | Your organization's specific data center (for on-premises or hybrid) |
| **Server Name** | Optional label for the physical or virtual server (for on-premises, hybrid, third-party hosted, or cloud deployments) |

The hosting type drives what other fields are relevant. For example, if you select "SaaS," you do not need to specify a data center. If you select "On-Premises," you do not need a cloud provider. The Server Name field only appears for hosting types where a long-lived server is expected (On-Premises, Hybrid, Third-Party Hosted, Cloud).

As you type a server name, suggestions from existing server names in your organization appear automatically. This helps maintain consistency — for example, if someone already entered "PROD-SQL-01," you will see it suggested rather than accidentally typing "Prod-SQL-1."

---

## Primary vs. Additional Profiles

Every application has one **primary** deployment profile. This is the main production deployment — the one that drives the default TIME and PAID quadrant scores.

You can add **additional** profiles for:

- Disaster recovery environments
- Test or staging environments
- Secondary deployments in other regions
- Legacy deployments being migrated away from

The primary profile's technical scores appear on the App Health dashboard by default. Additional profiles are visible in the application's detail view.

---

## Creating a Deployment Profile

1. Open the application from the dashboard or search
2. Go to the **Deployments** tab
3. Click **Add Deployment Profile**
4. Select the hosting type — the form adapts to show relevant fields
5. Fill in environment, provider, region, or data center as applicable
6. If your hosting type involves a long-lived server (On-Premises, Hybrid, Third-Party Hosted, or Cloud), you can optionally enter a **Server Name** — suggestions from existing server names in your organization appear as you type, helping you stay consistent
7. Save

The first profile you create automatically becomes the primary. You can change which profile is primary at any time.

---

## Relationship to Assessments

When you assess an application:

- **Business factors** (B1–B10) are scored once for the application as a whole — business value does not change based on where the app runs
- **Technical factors** (T01–T15) are scored per deployment profile — each deployment has its own infrastructure characteristics

This means a single application can have different technical health scores for different deployments. The primary profile's scores determine the application's position on the TIME and PAID quadrants.

---

## Data Residency and Compliance

Deployment profiles also support compliance tracking. By recording where each application's data is stored (cloud region, data center location), you can audit for:

- **Data residency requirements** — Ensure Canadian citizen data stays in Canadian regions
- **Regulatory compliance** — Demonstrate that sensitive workloads run in approved locations
- **Vendor risk** — Know which applications depend on specific cloud providers or regions

---

## Next Steps

- [How to Assess an Application](assessment-guide.md) — Score your deployment profiles
- [Reading Tech Health Indicators](tech-health.md) — See infrastructure risk across all deployments
- [Getting Started](getting-started.md) — Back to the onboarding guide
