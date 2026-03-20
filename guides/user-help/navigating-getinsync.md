# Navigating GetInSync

GetInSync organizes your application portfolio across six main sections, each designed for a specific audience and purpose. This guide explains what you'll find in each section and when to use it.

## Main navigation

When you log in, you'll see six tabs across the top of the screen. Each one answers a different set of questions about your portfolio.

### Overview

**Who it's for:** Everyone — your first stop after logging in.

The Overview gives you a snapshot of your entire portfolio at a glance. You'll see how many applications you manage, how many have been assessed, your total annual run rate, and how many crown jewel applications you have.

Key cards on this page include an assessment progress bar showing how much of your portfolio has been evaluated, a Portfolio Health donut showing your TIME distribution (Invest, Tolerate, Modernize, Eliminate), and a Technology Lifecycle Risk donut showing how your technology stack breaks down by support status.

Below the donuts, you'll find a workspace breakdown table showing assessment progress per workspace with business and technical completion rates.

**Use this page when:** You need a quick health check, you're preparing for a leadership briefing, or you want to see which workspaces need attention.

### Application Health

**Who it's for:** Portfolio managers and business analysts responsible for application rationalization.

Application Health is where you do the hands-on work of assessing and managing applications. It shows your workspace's application list with assessment status, TIME and PAID quadrant positioning, and cost data per application.

At the top, you'll see bubble charts plotting your assessed applications on the TIME (Business Fit vs Tech Health) and PAID (Risk vs Impact) quadrants. These charts are interactive — the size of each bubble represents the application's criticality.

Below the charts, quick-filter pills let you focus on specific groups: applications needing assessment, those needing attention, or your crown jewels (applications with criticality 50 or above).

The application list shows each app with its hosting type, category tags, lifecycle status, TIME and PAID positioning, and annual run rate. Click any application name to open its detail page.

**Use this page when:** You're running assessment workshops, reviewing which applications to invest in or retire, or checking a specific application's scores.

### Technology Health

**Who it's for:** Infrastructure teams, security analysts, and technology standards leads.

Technology Health helps you understand what technology is deployed across your portfolio and where lifecycle risk exists. It has five sub-tabs, each offering a different lens on the same underlying data.

**Analysis** shows the big picture: how many applications are profiled, how many crown jewels have technology data, and a breakdown of your lifecycle composition by technology layer (Operating Systems, Databases, Web Servers). The OS, Database, and Web Server donut charts show lifecycle status distribution with counts of products approaching end of life within 12 months.

**By Application** lists every application with its primary OS, database, and web server technology, each tagged with a lifecycle status badge. This is useful for finding which applications are running on unsupported technology.

**By Technology** flips the view: instead of "what tech does each app use," it shows "what apps use each technology product." Click a technology to see every deployment profile running that product, with environment, workspace, and extended support dates.

**By Server** groups deployment profiles by server name, showing what technology stack is running on each server. This tab requires server names on deployment profiles — if your organization hasn't populated these yet, you'll see an empty state with guidance.

**Standards** shows your implied technology standards — what GetInSync detects as your de facto standards based on prevalence across deployment profiles. Products used by 40% or more of deployments in a category are flagged as candidate standards. Administrators can assert whether these are approved standards, non-standard, under review, or retiring.

**Use this page when:** You need to report on technology lifecycle risk, identify unsupported software, review upgrade candidates, or assess standards compliance before a governance review.

### Roadmap

**Who it's for:** IT leaders, program managers, and anyone responsible for improvement initiatives.

The Roadmap section connects assessment findings to action. It has four sub-tabs.

**Initiatives** is where you create and track improvement efforts. Each initiative has cost estimates (one-time and recurring), a run rate impact forecast, target dates, and links to the deployment profiles and IT services it affects. You can view initiatives as a sortable grid, a Gantt timeline chart showing quarterly phasing, or a Kanban board organized by status (Identified, Planned, In Progress, Completed).

**Scorecard** groups your findings by assessment domain (Business Process & Applications, Technology Infrastructure, Cybersecurity Risk, IT Operating Model & Spend, Data Quality & Analytics). Each domain card shows severity breakdown and finding count, helping you see where the biggest gaps are.

**Ideas** is a lightweight intake pipeline. Anyone can submit an idea for improvement. Ideas move through New, Under Review, Approved, and Declined stages. Approved ideas can be promoted to full initiatives.

**Programs** groups related initiatives into strategic programs with budgets, timelines, and owner assignments. Program cards show initiative count, completion rate, aggregate cost, and net run rate impact.

**Use this page when:** You're planning modernization efforts, building a business case for investment, tracking initiative delivery, or reporting program status to leadership.

### IT Spend

**Who it's for:** Budget owners, finance liaisons, and anyone responsible for IT cost management.

IT Spend gives you a financial view of your portfolio. At the top, three KPI cards show your total budget, current run rate, and remaining headroom. Below that, you'll see how costs are allocated across applications, IT services, and unallocated reserve.

The Budget Utilization bar shows a visual gauge of how much of your workspace budget is committed. A Projected IT Spend section (collapsed by default) shows how planned roadmap initiatives would affect your future run rate.

The Run Rate by Quadrant chart breaks down spending by TIME positioning — so you can see how much you're spending on applications marked for elimination versus those marked for investment.

The application table at the bottom shows each app's budget, actual run rate, variance, and budget status (Healthy, Tight, or Over Budget).

**Use this page when:** You're preparing budget submissions, reviewing spending variance, identifying cost optimization opportunities, or quantifying the cost of technical debt.

### Explorer

**Who it's for:** Enterprise architects and senior leaders who need the cross-cutting view.

The Explorer is the power user's dashboard — it combines portfolio health, technology risk, and cost data into a single view that the other pages show separately.

The KPI bar across the top gives you eight metrics at a glance: total applications, crown jewels, average tech health, average business fit, end-of-support count, estimated tech debt, annual run rate, and technology tag count.

Below the KPIs, two visualization panels sit side by side. The left panel shows a lifecycle distribution donut. The right panel shows annual run rate broken down by technology support status — how much of your spending is on end-of-support technology versus mainstream.

The detail table at the bottom shows every application with its full profile: workspace, crown jewel status, TIME and PAID positioning, tech health score, criticality, worst technology lifecycle status, estimated tech debt, run rate, and owner. The table is searchable, sortable by any column, and exportable to CSV.

Use the filter drawer (click Filters) to slice the data by workspace, lifecycle status, crown jewel flag, TIME quadrant, or PAID action. All KPIs, charts, and the table update in real time as you filter.

**Use this page when:** You need to answer questions that span multiple domains — "how much are we spending on end-of-life technology?", "which crown jewels have the worst tech health?", "what does our modernize backlog cost?" — or when you're preparing an enterprise architecture review.

## Scope bar

The workspace and portfolio selectors in the header control what data you see across all pages. When set to a specific workspace, every page filters to that workspace's data. When set to "All Workspaces" (available to namespace administrators), you see the aggregated view across your entire organization.

## Quick access

**Global Search (⌘K):** Press ⌘K (or Ctrl+K) to search across applications, deployment profiles, IT services, contacts, and more from anywhere in the app.

**Help & Support (?):** Click the question mark icon to access help articles, product tours, and live chat support.

**AI Analyst (✨):** Click the sparkles icon to ask questions about your portfolio in natural language. The AI analyst can pull data from any of the views described above and generate summaries, comparisons, and recommendations.
