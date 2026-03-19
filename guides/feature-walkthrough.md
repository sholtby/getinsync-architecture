# GetInSync NextGen — Feature Walk-Through

> **Audience:** Enterprise Architects managing application portfolios, particularly those operating ServiceNow and looking to rationalize their application landscape.
>
> **How to use this document:** Open GetInSync NextGen alongside this guide. Each section maps to a screen or panel you can see in the application. Section numbers follow the navigation order — start at the header and work through the tabs left to right.
>
> GetInSync NextGen models the same entities as ServiceNow's Common Service Data Model (CSDM) but uses plain-English names. CSDM table references appear inline on first mention so you can map concepts directly.

---

## Why GetInSync NextGen

- **Portfolio rationalization without a full CMDB deployment.** Assess your application landscape using TIME and PAID quadrant models, track cost and technology health, and produce actionable roadmaps — without requiring ServiceNow ITSM or CMDB to be in place first.
- **Assessment-to-Action pipeline.** Most APM tools stop at "what do we have?" and "what condition is it in?" GetInSync adds: "So what do we do about it?" Findings from assessments flow into Initiatives, which group into Programs with dependencies and cost projections.
- **Deployment Profile as the cost and assessment anchor.** Costs and technical assessments attach to the Deployment Profile *(CSDM: `cmdb_ci_service_auto` / Application Service)*, not the Business Application. This means one application with a production and DR deployment carries distinct scores and costs per environment.
- **Editor Pool licensing.** Editor seats are pooled at the namespace level — one person with Editor access across five workspaces consumes one license. The Steward role allows application owners to complete business-fit assessments without consuming an Editor seat.
- **CSDM-native data model.** Direct mapping to ServiceNow tables means future synchronization requires no schema translation.

---

## Key Concepts

| Term | Definition |
|------|-----------|
| **Namespace** | Your organization tenant. All workspaces, users, catalogs, and configuration live here. |
| **Workspace** | A division or business unit within the namespace. Applications and portfolios are scoped to a workspace. |
| **Portfolio** | A logical grouping of applications within a workspace (e.g., "Finance Apps", "Citizen Services"). Supports nested hierarchies. |
| **Business Application** | The application record itself *(CSDM: `cmdb_ci_business_app`)*. Represents a business capability, not a technical instance. |
| **Deployment Profile** | A per-environment instance of a Business Application *(CSDM: `cmdb_ci_service_auto`)*. All costs and technical assessments attach here. |
| **Publisher / Consumer** | When an application is shared across workspaces via Workspace Groups, the originating workspace is the Publisher; subscribing workspaces are Consumers. Consumers can assess business fit but not technical health. |
| **TIME / PAID** | Two complementary assessment quadrant models. TIME (Tolerate, Invest, Modernize, Eliminate) maps business fit against technical health. PAID (Plan, Address, Ignore, Delay) maps impact against technical risk. |

---

## 1. Header Bar

The header is always visible and provides global context controls.

<!-- Screenshot: Full header bar showing logo, search, workspace switcher, portfolio selector, and user menu -->

**Organization name and logo** (top-left) — click to return to the default tab.

**Global Search** — click the magnifying glass icon or press `Cmd+K` / `Ctrl+K` to open a search overlay. Searches across 12 entity types: Applications, Deployment Profiles, Contacts, IT Services, Software Products, Technology Products, Portfolios, Initiatives, Findings, Ideas, Programs, and Integrations. Results are grouped by category with keyboard navigation (arrow keys + Enter).

**Workspace Switcher** — dropdown showing all workspaces you have access to. Select "My Workspaces" for a cross-workspace aggregate view. The selected workspace scopes everything on the Application Health and Technology Health tabs.

**Portfolio Selector** (SmartPortfolioHeader) — appears when a specific workspace is selected. Shows the current portfolio with breadcrumbs for nested hierarchies. Select "All Portfolios" for a workspace-wide view, or choose a specific portfolio to narrow the dashboard. Quick-access links to "Add Portfolio" and "Manage Portfolios" are available from the dropdown.

**User Menu** — profile settings, workspace switching, and sign-out.

---

## 2. Navigation Tabs

A horizontal tab bar sits below the header with four main views:

| Tab | Label | Visible When | Scope |
|-----|-------|-------------|-------|
| 1 | **Overview** | 2+ workspaces exist in the namespace | Namespace-wide |
| 2 | **Application Health** | Always (default tab) | Workspace + Portfolio scoped |
| 3 | **Technology Health** | Always | Workspace or Namespace scoped |
| 4 | **Roadmap** | Always | Namespace-wide |

The active tab is persisted across sessions. If the namespace has only one workspace, the Overview tab is hidden and Application Health becomes the landing page.

<!-- Screenshot: Main tab bar showing all four tabs -->

---

## 3. Overview

The Overview tab provides a namespace-wide snapshot across all workspaces. Use this to compare business units and identify where assessment effort or risk is concentrated.

<!-- Screenshot: Full Overview tab -->

### 3.1 KPI Cards

Four cards in a row providing namespace-level metrics:

| Card | Metric | Detail |
|------|--------|--------|
| **Applications** | Total count of Business Applications | Shows "across N workspaces" |
| **Fully Assessed** | Count of fully assessed Deployment Profiles | Shows "of N deployments" |
| **Crown Jewels** | Applications with criticality score >= 50 | High-criticality applications requiring special attention |
| **At Risk** | Applications in Modernize or Eliminate quadrants | TIME quadrant indicators of action needed |

### 3.2 Assessment Completion

A horizontal progress bar showing the percentage of Deployment Profiles with completed assessments across the namespace.

### 3.3 TIME Distribution & Lifecycle Risk

Two side-by-side panels:

- **TIME Distribution** (left) — Quadrant distribution (Tolerate / Invest / Modernize / Eliminate) with a per-workspace breakdown table. Quickly see which business units carry the most modernization or elimination candidates.
- **Lifecycle Risk** (right) — Technology lifecycle risk summary showing how many Technology Products are in mainstream support, extended support, end-of-life, or unsupported status. Sourced from the Technology Health data.

---

## 4. Application Health

This is the primary working view for portfolio assessment and management. It is scoped to the workspace and portfolio selected in the header.

<!-- Screenshot: Application Health dashboard — full view -->

### 4.1 Dashboard (Default View)

The default view when you select Application Health.

**Title bar** — shows the organization/workspace name and current portfolio. Action buttons include:
- **Export CSV** — download the current filtered view
- **Publish Apps** — share applications to other workspaces via Workspace Groups (visible when publishing is configured)
- **Browse Shared Apps** — subscribe to applications published by other workspaces
- **Add Existing App** — assign an unassigned application to the current portfolio
- **New Application** — create a new Business Application

**Filter controls** — filter by workspace (in cross-workspace view), portfolio (in All Portfolios view), operational status (Operational, Planned, Retired), and App Health filters (lifecycle status, hosting type, application category, operational status, business owner, TIME quadrant, PAID action, assessment status, crown jewel, business fit, criticality, remediation effort).

**Portfolio Analysis** — two side-by-side mini scatter charts showing TIME and PAID quadrant positioning of assessed applications. Click "View Full Charts" to enter the Charts View. Only appears when assessed applications exist.

**KPI Bar** — five clickable metric cards. Each card drills into a detailed panel:

| Card | Metric | Drill-In View |
|------|--------|--------------|
| **Business Applications** | App count + deployment count | Apps Overview |
| **Annual Run Rate** | Total cost across all cost channels | Cost Analysis |
| **Est. Tech Debt** | Summed estimated technical debt | Tech Debt |
| **Avg Business Fit** | Weighted average business fit score | Business Fit |
| **Avg Tech Health** | Weighted average technical health score | Tech Health |

**Action Panels** — two panels showing applications needing attention:
- **Unassessed** — applications that have not yet been assessed
- **Needs Attention** — applications flagged for action based on assessment results

**Application Table** — sortable, paginated table of applications in the current scope. Columns: Application (name + operational status dot + hosting badge + owner), Category (application category badges), Lifecycle (lifecycle status), Assessment (TIME/PAID quadrants or "Not Started"), Remediation (t-shirt size XS–2XL), and Run Rate (annual cost). Click any row to open the Application Detail Drawer.

Expandable rows reveal Deployment Profiles beneath each application.

### 4.2 KPI Drill-In Panels

Clicking a KPI card replaces the dashboard with a detailed panel. Each panel has a back arrow to return to the dashboard.

#### 4.2.1 Apps Overview

Deployment-profile-level breakdown showing assessment status, TIME quadrant, PAID action, and ownership. Donut charts display TIME and PAID distribution. Clickable chart segments filter the table.

#### 4.2.2 Cost Analysis

Per-application cost breakdown organized by the three cost channels:

| Channel | What It Tracks | CSDM Equivalent |
|---------|---------------|-----------------|
| **Software Products** | Licensed/SaaS annual costs | `alm_product_model` |
| **IT Services** | Shared infrastructure allocations | `service_offering` / `cmdb_ci_service_technical` |
| **Cost Bundles** | Everything else (consulting, MSP, one-time costs) | — |

All costs flow through Deployment Profiles — never directly to the Business Application. Expandable rows reveal the deployment-profile-level allocation. A vendor spend section aggregates costs by vendor/partner *(CSDM: `cmdb_ci_company`)*.

<!-- Screenshot: Cost Analysis panel showing three cost channels -->

#### 4.2.3 Tech Debt

Lists applications with estimated technical debt, sortable by amount. Shows remediation effort using T-shirt sizing (XS through 2XL), derived from configurable thresholds set in Assessment Configuration.

#### 4.2.4 Business Fit

Lists applications with their business fit scores. A quick-assess action on each row launches the Assessment Wizard directly to the Business Fit tab.

#### 4.2.5 Tech Health

Lists applications with their technical health scores. A quick-assess action on each row launches the Assessment Wizard directly to the Technical Health tab.

### 4.3 Charts View

Full-page scatter plot visualization accessible from the "View Full Charts" link on the Portfolio Analysis section.

- **TIME Chart** — Business Fit (x-axis) vs. Tech Health (y-axis). Bubble size represents criticality; color indicates TIME quadrant.
- **PAID Chart** — Impact Score (x-axis) vs. Technical Risk (y-axis). Bubble size represents remediation effort; color indicates PAID action.

A companion data table below each chart is sortable by all score dimensions. Click any bubble to assess or edit the application.

<!-- Screenshot: TIME scatter plot with quadrant labels -->

### 4.4 Applications Pool

Lists all Business Applications in the workspace regardless of portfolio assignment. Shows how many portfolios each application belongs to. From here you can create new applications or edit existing ones. Use this view to find "orphaned" applications not yet assigned to a portfolio.

### 4.5 Portfolios List

Manage portfolios within the current workspace: create, rename, delete. Shows application count per portfolio and supports nested (hierarchical) portfolio structures. Click a portfolio name to switch the dashboard to that portfolio's context.

### 4.6 Assessment Wizard

A two-tab wizard for assessing a Deployment Profile's business and technical health:

- **Business Fit tab** — assessment factors related to business value, criticality, user adoption, and strategic alignment. Each factor is scored on a 1–5 scale with configurable weights.
- **Technical Health tab** — assessment factors for technology recency, system quality, infrastructure stability, and security posture. Scored the same way.

Assessment factors are defined at the namespace level (Settings > Assessment Configuration), ensuring consistent criteria across all workspaces. Derived scores are calculated automatically: Business Fit, Tech Health, Criticality, Technical Risk, TIME Quadrant, and PAID Action.

For Consumer applications (shared from another workspace), only the Business Fit tab is editable — Technical Health is read-only from the Publisher.

Score overrides allow administrators to manually adjust an auto-calculated score with a documented reason.

<!-- Screenshot: Assessment Wizard showing Business Fit tab with factor scoring -->

---

## 5. Technology Health

The Technology Health tab provides visibility into the technology stack powering your applications. It helps identify end-of-life risks, version sprawl, and infrastructure dependencies.

<!-- Screenshot: Technology Health — Analysis tab -->

Four sub-tabs:

### 5.1 Analysis

The summary view showing an infrastructure matrix of applications by technology category (Operating System, Database, Web/Application Server). Each cell displays a lifecycle status badge:

| Badge | Meaning |
|-------|---------|
| **Current** | Mainstream vendor support |
| **Extended** | Extended/limited support |
| **EOL** | Past end-of-life |
| **Unknown** | Lifecycle data not available |

Crown Jewel indicators highlight high-criticality applications. The filter sidebar supports filtering by technology category, version, and lifecycle status. CSV export is available. Clickable categories and lifecycle badges navigate to the By Technology or By Application sub-tabs.

### 5.2 By Application

Application-centric view of technology stack assignments. Each application row shows its linked Technology Products with lifecycle status badges. Filter by Crown Jewel status and lifecycle status.

### 5.3 By Technology

Technology-centric view grouped by Technology Product. Shows which applications use each technology, their versions, and lifecycle positions. Pre-filtered when navigated from the Analysis tab via a category or lifecycle click.

### 5.4 By Server (Plus tier)

Server/infrastructure-centric view mapping physical and virtual servers to applications and their technology stacks. This sub-tab is available on Plus tier and above. On lower tiers, a lock icon and upgrade prompt are shown.

---

## 6. Roadmap

The Roadmap tab is where assessment insights turn into action. It implements the Assessment-to-Action pipeline: Findings from assessments generate Initiatives, which group into Programs with cost projections and dependencies.

<!-- Screenshot: Roadmap — Initiatives tab in Grid view -->

Four sub-tabs:

### 6.1 Initiatives

Strategic transformation projects with three view modes:

- **Grid** — sortable, filterable table (default)
- **Gantt** — timeline view with scheduling (Enterprise tier)
- **Kanban** — status-column board (Enterprise tier)

**KPI bar** at the top shows:

| Metric | Description |
|--------|-------------|
| **Active Initiatives** | Count of non-cancelled/deferred initiatives out of total |
| **Total Investment** | Sum of one-time cost estimates (midpoint) |
| **New Recurring** | Sum of new recurring cost estimates per year |
| **Net Run Rate Delta** | Net change in annual run rate across all active initiatives |

Each initiative tracks: title, status (Identified / Planned / In Progress / Completed / Deferred / Cancelled), priority (Critical / High / Medium / Low), strategic theme (Optimize / Growth / Risk), time horizon (Q1–Q4, Beyond), one-time and recurring cost estimates (low/high range), run rate change, source finding, and linked programs.

The **filter drawer** supports filtering by workspace, assessment domain, strategic theme, priority, status, and time horizon. CSV export is available (Enterprise tier).

Click any initiative row to open the **Initiative Detail Drawer** — a slide-in panel from the right showing the full initiative record with edit capabilities.

### 6.2 Scorecard

Assessment findings grouped by domain. Six assessment domains are supported:

| Domain Code | Domain |
|-------------|--------|
| ICOMS | IT Cost & Optimization Management |
| BPA | Business Process Alignment |
| TI | Technology & Infrastructure |
| DQA | Data Quality & Architecture |
| CR | Compliance & Risk |
| Other | General observations |

Each domain card shows the finding count and impact distribution (High / Medium / Low). Expand a domain to see individual findings with title, rationale, and impact level. Findings are the input to the Assessment-to-Action pipeline — a finding can be promoted to an Initiative.

<!-- Screenshot: Scorecard showing domain cards with finding counts -->

### 6.3 Ideas

Lightweight idea capture for suggestions that haven't been formalized into initiatives. Ideas follow a status workflow: Submitted, Under Review, Approved, Declined, Deferred. Approved ideas can be promoted to Initiatives, maintaining the audit trail.

### 6.4 Programs (Enterprise tier)

Group related Initiatives into Programs with a budget envelope and business drivers. Programs provide the executive-level rollup: total investment, timeline, and strategic alignment across a set of related initiatives. Available on Enterprise tier only.

---

## 7. Application Detail

Accessed by clicking an application name anywhere in the app. Opens as a full page.

<!-- Screenshot: Application Detail page header with score badges -->

### 7.1 Header Banner

Shows the application name, publisher location (Workspace > Portfolio), and assessment score badges (Business Fit / Tech Health). A sharing indicator banner appears when the application is published to or consumed from other workspaces. The assessment button text reflects the current state: "Start Assessment", "Continue Assessment", or "Edit Assessment".

### 7.2 Tab Navigation

Six tabs along the top of the detail page:

| Tab | Status | Content |
|-----|--------|---------|
| **General** | Active | Application metadata and primary deployment profile |
| **Deployments** | Coming soon | Multi-deployment management |
| **Costs** | Coming soon | Dedicated cost breakdown |
| **Integrations** | Active | Internal and external data connections |
| **Visual** | Active | Integration topology diagram |
| **Assessment** | Coming soon | Embedded assessment view |

### 7.3 General Tab

The primary form for managing an application's metadata and its primary Deployment Profile.

**Application metadata** — Name, description (under 300 characters), primary use case (2-paragraph technical abstract), lifecycle status, application category, operational status. A "Generate with AI" button above the description fills description, use case, and category simultaneously using AI.

**Primary Deployment Profile** — Environment (Production, DR, Dev, etc.), region, hosting type (SaaS, On-Prem, Cloud, Hybrid), cloud provider, disaster recovery status, data center assignment, annual licensing cost, annual technology cost, estimated technical debt, and remediation effort (T-shirt size).

**Contacts & Ownership** *(CSDM: `cmdb_ci_contact`)* — role-based contact assignments: Business Owner, Technical Owner, Support Contact, and other roles. Each role can be flagged as primary.

**Technology Stack** — linked Technology Products with lifecycle status badges. Tags the technologies powering this deployment.

**Cost Summary** — read-only rollup showing the three cost channels (Software Products, IT Services, Cost Bundles) with totals.

### 7.4 Integrations Tab

Maps data flows and dependencies to and from this application.

**Internal connections** — integrations with other Business Applications within the namespace. Each connection captures:

| Field | Description |
|-------|-------------|
| Direction | Upstream / Downstream / Bidirectional |
| Method | API / File / Database / SSO / Manual / Event / Other |
| Frequency | Real-time / Daily / Weekly / Monthly / On-demand |
| Status | Planned / Active / Deprecated / Retired |
| Data Format | JSON / XML / CSV / XLSX / etc. |
| Sensitivity | Low / Moderate / High / Confidential |
| Data Classification | Public / Internal / Confidential / Restricted |
| Data Tags | Employee / Citizen / Customer / Financial / Personal / etc. |
| Criticality | Integration criticality level |

**External connections** — integrations with systems outside the managed portfolio. Captures the same fields plus external entity type (Vendor, Partner, Agency, SaaS endpoint) and supplier/contact links.

All dropdown values are fetched from database reference tables — never hardcoded.

### 7.5 Visual Tab

A force-directed graph showing the application's integration topology. Connections are color-coded by status and direction. Provides a quick visual summary of an application's data flow dependencies.

<!-- Screenshot: Visual tab showing integration topology diagram -->

---

## 8. Settings

Accessed via the sidebar. Two-column layout: navigation on the left, content on the right.

<!-- Screenshot: Settings sidebar showing Organization and Workspace sections -->

### 8.1 Organization Settings

Visible to Namespace Administrators. These settings apply across all workspaces in the namespace.

#### 8.1.1 Namespace

Organization name, subscription tier, and namespace-level configuration.

#### 8.1.2 Users

Namespace-level user management. Invite users and assign roles:

| Role | Create Apps | Edit Assigned | Edit All | View All | Dashboards | License Cost |
|------|------------|---------------|----------|----------|------------|-------------|
| **Admin** | Yes | Yes | Yes | Yes | Yes | Editor seat |
| **Editor** | Yes | Assigned only | Yes | Yes | Yes | Editor seat |
| **Steward** | No | Owned apps (Business Fit only) | No | Yes | Yes | Free |
| **Viewer** | No | No | No | Yes | Yes | Free |
| **Restricted** | No | No | No | Assigned only | No | Free |

The **Steward** role is a key differentiator: application owners can complete Business Fit assessments without consuming an Editor license. In a 200-app portfolio with 50 application owners, this avoids 50 additional Editor seats.

#### 8.1.3 Vendors & Partners

Organization directory *(CSDM: `cmdb_ci_company`)*. Tracks internal departments and external vendors/partners. Each organization has role flags: Supplier, Manufacturer, Customer, Internal. One record per entity — "Microsoft" appears once and is referenceable from Software Products, IT Services, and integration contacts across all workspaces.

#### 8.1.4 Audit Log

Namespace-wide activity log tracking who did what, when, and to which entity. Supports SOC 2 compliance evidence collection.

#### 8.1.5 Contacts

Central contact directory *(CSDM: `cmdb_ci_contact`)*. Three categories: Internal, External, and Vendor Rep. Contacts are linked to applications via role-based assignments (Business Owner, Technical Owner, Support Contact, etc.).

#### 8.1.6 Assessment Configuration

Defines the assessment framework applied uniformly across the namespace. Three sub-tabs:

- **Assessment Factors** — define the business and technical questions used in the Assessment Wizard, with weights, sort order, and applicability rules (e.g., skip a factor for SaaS applications).
- **Derived Scores** — view how Business Fit, Tech Health, Criticality, Technical Risk, TIME Quadrant, and PAID Action are calculated from factor scores.
- **Thresholds** — configure scoring boundaries for TIME/PAID quadrant placement and remediation effort T-shirt sizing.

#### 8.1.7 Budget

Workspace-level budget configuration. Set annual budget amounts per workspace and track utilization against actual run rates.

#### 8.1.8 Data Centers

Physical data center locations. Linked to Deployment Profiles for infrastructure location tracking.

### 8.2 Workspace Settings

#### 8.2.1 Workspaces in Namespace

List and manage all workspaces (Namespace Admin only). Create new workspaces for additional business units or divisions. Click **Edit** on a workspace card to open the edit modal, which includes a **Leadership** section for assigning governance contacts (Leader, Business Owner, Technical Owner, Steward, Budget Owner, Sponsor). The primary leader's name appears on the workspace card.

#### 8.2.2 Workspace Groups

Group workspaces for application sharing via the publish/subscribe model (Namespace Admin only). A Workspace Group defines which workspaces can publish applications and which can subscribe. This enables cross-workspace application portfolio visibility without duplicating data.

#### 8.2.3 Workspace Users

Per-workspace user role assignments. A user can have different roles in different workspaces — Viewer in one, Editor in another.

#### 8.2.4 Portfolios

Manage portfolio hierarchy within the current workspace. Create, rename, delete, and nest portfolios. Click **Edit** on a portfolio to open the edit modal, which includes a **Leadership** section for assigning governance contacts. The primary leader's name appears in the portfolio header.

#### 8.2.5 Import Applications

CSV/Excel import for bulk application onboarding. Upload a spreadsheet of applications with their metadata and the system creates the corresponding Business Application and Deployment Profile records.

### 8.3 Enterprise Catalogs

Available on tiers with catalog features enabled. Displayed under the "Enterprise" heading in the sidebar.

#### 8.3.1 Software Catalog

Software Product records *(CSDM: `alm_product_model`)*. Track vendor, product name, version, and licensing model. Software Products are linked to Deployment Profiles as a cost channel — when you assign a Software Product to a deployment, its annual cost flows into the application's run rate.

#### 8.3.2 Technology Catalog

Technology Product records with lifecycle management. Each record tracks the product family, version, vendor lifecycle dates (mainstream support end, extended support end, end-of-life), and current lifecycle status. This catalog feeds the Technology Health tab — when a Technology Product is tagged to a Deployment Profile, its lifecycle status appears in the health analysis.

#### 8.3.3 IT Service Catalog

IT Service records *(CSDM: `service_offering` / `cmdb_ci_service_technical`)*. Define shared infrastructure services (e.g., Azure SQL, Network Services, Shared Hosting) with annual cost and service owner. IT Services are linked to Deployment Profiles as a cost channel. **Stranded cost visibility**: when an IT Service's total annual cost exceeds the sum of all allocations to Deployment Profiles, the unallocated amount is flagged as stranded cost — revealing shared infrastructure overhead that isn't attributed to any application.

### 8.4 Locked Features

On tiers below Enterprise, the sidebar shows locked placeholders for future capabilities: Custom Fields, Workflows, Notifications, and API Access.

---

## Appendix A: CSDM Entity Mapping

| GetInSync Entity | ServiceNow CSDM Table | Notes |
|-----------------|----------------------|-------|
| Business Application | `cmdb_ci_business_app` | The application record — represents a business capability |
| Deployment Profile | `cmdb_ci_service_auto` (Application Service) | Per-environment instance; cost and assessment anchor |
| IT Service | `service_offering` / `cmdb_ci_service_technical` | Shared infrastructure cost channel |
| Software Product | `alm_product_model` | Licensed/SaaS software cost channel |
| Contact | `cmdb_ci_contact` | Role-based assignment to applications |
| Organization | `cmdb_ci_company` | Vendor, partner, and internal organization directory |

---

## Appendix B: Pricing Tiers

| Feature | Trial | Essentials | Plus | Enterprise |
|---------|-------|------------|------|-----------|
| Application portfolio & assessment | Yes | Yes | Yes | Yes |
| TIME/PAID quadrant analysis | Yes | Yes | Yes | Yes |
| Technology Health (Analysis, By App, By Tech) | Yes | Yes | Yes | Yes |
| Technology Health — By Server | — | — | Yes | Yes |
| Cost tracking (three channels) | Yes | Yes | Yes | Yes |
| Roadmap — Initiatives (Grid view) | Yes | Yes | Yes | Yes |
| Roadmap — Initiatives (Gantt & Kanban) | — | — | — | Yes |
| Roadmap — Scorecard & Ideas | Yes | Yes | Yes | Yes |
| Roadmap — Programs | — | — | — | Yes |
| Software / Technology / IT Service Catalogs | — | — | — | Yes |
| Steward role (unlimited) | — | — | — | Yes |
| CSV Export (Initiatives) | — | — | — | Yes |
| Workspace Groups (Publish/Subscribe) | — | — | — | Yes |
| Custom Fields, Workflows, Notifications, API | — | — | — | Enterprise |

---

## Appendix C: Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+K` / `Ctrl+K` | Open Global Search |

---

*Last updated: March 2026*
