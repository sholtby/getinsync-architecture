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

- **Assess each deployment independently** — Technical factors (T01–T14) are scored per profile
- **Track costs per deployment** — Know what each instance actually costs
- **Identify infrastructure risk** — See which specific deployments are running on unsupported platforms
- **Plan migrations** — Document the target state alongside the current state

---

## What a Profile Contains

Each deployment profile captures:

| Field | Description |
|-------|-------------|
| **Environment** | Production, Disaster Recovery, Test, Development, or Staging |
| **Hosting Type** | SaaS, Cloud (IaaS/PaaS), On-Premise, Hybrid, Third-Party Hosted, or Desktop |
| **Cloud Provider** | AWS, Azure, GCP, Oracle Cloud, or other (if cloud-hosted) |
| **Region** | The geographic region or data center where it runs |
| **Data Center** | Your organization's specific data center (for on-premises or hybrid) |
| **Servers** | One or more servers linked to this deployment, each with a role (database, web, application, file, utility) and an optional primary designation |

The hosting type drives what other fields are relevant. For example, if you select "SaaS," you do not need to specify a data center. If you select "On-Premise," you do not need a cloud provider. The Servers field only appears for hosting types where long-lived servers are expected (On-Premise, Hybrid, Third-Party Hosted, Cloud).

The server picker lets you search existing servers in your organization by name. Select a server to link it — it appears as a chip showing the server name, a role dropdown, and a star toggle to mark it as the primary server. You can link multiple servers to a single deployment profile (e.g., a database server, a web server, and an application server). If the server you need does not exist yet, type the name and select "Create server" to add it inline.

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
6. If your hosting type involves long-lived servers (On-Premise, Hybrid, Third-Party Hosted, or Cloud), you can optionally link **Servers** — search for existing servers or create new ones inline, assign a role to each (database, web, application, etc.), and mark one as primary
7. Save

The first profile you create automatically becomes the primary. You can change which profile is primary at any time.

---

## Relationship to Assessments

When you assess an application:

- **Business factors** (B1–B10) are scored once for the application as a whole — business value does not change based on where the app runs
- **Technical factors** (T01–T14) are scored per deployment profile — each deployment has its own infrastructure characteristics

This means a single application can have different technical health scores for different deployments. The primary profile's scores determine the application's position on the TIME and PAID quadrants.

---

## Data Residency and Compliance

Deployment profiles also support compliance tracking. By recording where each application's data is stored (cloud region, data center location), you can audit for:

- **Data residency requirements** — Ensure Canadian citizen data stays in Canadian regions
- **Regulatory compliance** — Demonstrate that sensitive workloads run in approved locations
- **Vendor risk** — Know which applications depend on specific cloud providers or regions

---

## Operations — Team Assignments

Each deployment profile has an **Operations** section where you assign the teams responsible for supporting and managing that deployment. This section appears below the IT Services section on the Deployments & Costs tab.

Three questions guide the assignments:

| Question | What It Means |
|----------|---------------|
| **Who fixes it when it breaks?** | The support team responsible for incident response |
| **Who approves changes?** | The change advisory board or team that reviews change requests |
| **Which team manages this day-to-day?** | The team that handles ongoing operations and maintenance |

Teams are selected from a dropdown that shows your organization's defined teams. If the team you need does not exist, select **"+ Add new team..."** at the bottom of the dropdown to create one inline.

Teams are grouped in the dropdown: namespace-wide teams (labeled "All workspaces") appear first, followed by teams scoped to the current workspace.

### Managing Teams

Namespace administrators can manage teams in **Settings > Teams**. From there you can:

- Create teams with a name, optional description, and workspace scope
- Edit team names and descriptions
- Delete teams that are not assigned to any deployment profiles (in-use teams show a usage count and cannot be deleted)

Teams scoped to "All workspaces" are available across your entire organization. Teams scoped to a specific workspace are only visible within that workspace.

---

## Recurring Costs (Cost Bundles)

Below your deployment profiles on the Deployments & Costs tab, you will find the **Recurring Costs** section. This is where you track annual costs that are not tied to a specific software product or IT service — things like support contracts, consulting agreements, or estimated subscription costs.

Each recurring cost entry has an optional **Contract Details** section you can expand to record:

- **Contract Reference** — Your purchase order or agreement number
- **Start Date** and **End Date** — The contract term
- **Renewal Notice Days** — How many days before expiry you want to be alerted (defaults to 90)

If you fill in an end date, the contract will appear on the **Contract Expiry** widget on the IT Spend tab, alongside any IT Service contracts. This gives you a single view of all upcoming renewals across your portfolio.

### Double-Count Awareness

GetInSync helps you avoid accidentally counting the same cost twice:

- **Adding a recurring cost** to an application that already receives costs from IT Services will show a brief warning reminding you to check for overlap
- **Linking an IT Service** to an application that has recurring costs with contract details will prompt you to review those costs, in case the IT Service replaces them

These prompts are informational — they do not prevent you from proceeding. Both cost types can legitimately coexist (for example, an IT Service for hosting plus a separate recurring cost for consulting).

---

## Next Steps

- [How to Assess an Application](assessment-guide.md) — Score your deployment profiles
- [Reading Tech Health Indicators](tech-health.md) — See infrastructure risk across all deployments
- [Getting Started](getting-started.md) — Back to the onboarding guide
