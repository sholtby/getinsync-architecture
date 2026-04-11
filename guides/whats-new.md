# What's New

Recent updates to GetInSync NextGen.

---

## April 11, 2026

- **AI Assistant — Smarter answers across the board** — A multi-batch tuning effort raised the AI Assistant's answer-quality score from 2/10 to 10/10 on a fixed evaluation set. Six concrete improvements you'll notice: (1) **rationalization questions** like "which of two overlapping systems should we consolidate to" now correctly recommend the system with better tech health, lower remediation effort, mainstream lifecycle, and assigned ownership — instead of the older system with broader functional coverage; (2) **risk questions** correctly call the technology-risk tool instead of the cost-analysis tool, so high-cost-but-healthy apps no longer get flagged as risks; (3) **listing questions** like "list my crown jewels" now return real names instead of failing; (4) **vendor consolidation questions** sum both cost channels (cost bundles + IT service allocations) so vendor totals aren't understated by half; (5) **multi-tool analyses like SWOT** now correctly orchestrate multiple data sources before answering; (6) **graceful refusals** for questions the portfolio model can't answer (historical trends, PII classification) now happen cleanly instead of producing inferred or fabricated answers.
- **AI Assistant — Better error messages** — When the underlying AI provider rate-limits a request or is temporarily unavailable, the chat now shows a specific actionable message ("Claude is rate-limited right now. Please wait about 5 minutes and try again.") instead of the generic "Sorry, something went wrong." Network errors and expired sessions also get specific messages. When the AI provider returns extra detail about why a request failed (e.g. "exceeded daily input token limit"), that detail is appended to the message so you can see exactly what happened.
- **Help — AI Assistant article updated** — The AI Assistant help article now reflects the six tools the assistant can access (was four), shows example questions for the new question categories (rationalization, multi-dimensional analysis, risk ranking), and explains how the assistant fails gracefully on questions it can't answer.

---

## April 9, 2026

- **Custom T-Shirt Size Ranges (Enterprise)** — Enterprise users can now customize the remediation effort T-shirt size boundaries (XS through XL) on the Organization Settings page. Click "Edit Ranges" to adjust the upper-bound percentages for each size relative to your maximum remediation budget. The resulting dollar ranges update in real time as you type. Non-enterprise users see a "Customize in Full" button that explains the feature is available on the Enterprise plan. Custom ranges apply across the platform — deployment profile dropdowns, the PAID chart, tech debt breakdowns, and CSV exports all reflect your custom boundaries.
- **CSV Import v2 — Bulk Application Onboarding** — A redesigned import wizard lets namespace administrators upload a CSV of applications with a full preview before committing. The preview table shows green (ready), yellow (duplicate, will skip), and red (validation error, must fix) rows so you know exactly what will be created. Supported columns include Application Name, Description, Business Owner, Technical Owner, External ID, Hosting Type, Cloud Provider, Environment, Lifecycle Status, Annual Cost, Remediation Effort, and assessment scores (B1-B10, T01-T15). A downloadable template includes instructions and valid values. Import history tracks past uploads with an Undo button that can revert an entire import — with a warning if applications have been modified since import.
- **Import Access Control** — CSV import is now restricted to namespace administrators and platform administrators. Workspace administrators and regular members no longer see the import option in the sidebar or on empty workspace screens.
- **Empty State Import Button** — When a workspace has no applications, the dashboard now shows an "Import from CSV" button alongside "New Application" for quick onboarding.
- **IT Spend — KPI Card Click-Through** — All eight metric cards on the IT Spend namespace overview (4 KPI cards + 4 allocation cards) are now clickable. Click any card to smooth-scroll to the Budget by Workspace table with the relevant sort applied. Total Budget sorts by budget descending, Run Rate by run rate descending, Remaining by unallocated ascending (worst-first). Cards show a hover effect with shadow lift and "View" hint matching the Overview KPI pattern.
- **IT Spend — Budget Alerts Fix** — The Budget Alerts KPI card now correctly counts individual workspaces with budget issues (over budget or 80%+ utilization) instead of checking only the aggregate namespace status. Previously it always showed "0" even when individual workspaces were tight or over budget.
- **IT Spend — Budget Alerts Filter** — Clicking the Budget Alerts card filters the workspace table to show only problem workspaces (tight or over budget). A teal info bar appears above the table showing "Showing N workspaces with budget issues" with a "Show all workspaces" dismiss link. Clicking Budget Alerts again toggles the filter off.
- **IT Spend — TypeScript Contract Fix** — The `workspace_status` TypeScript union now includes both database view values (`over_allocated`, `under_10`) and client-derived values, preventing silent type mismatches.

## April 8, 2026

- **Dashboard — Server Count on Expand** — Expanding a deployment profile row on the Dashboard now shows the server name alongside environment and hosting details, giving quick infrastructure visibility without navigating to the detail page.
- **IT Spend — Sortable Columns** — All columns in the IT Services table on IT Spend are now sortable (click column headers). Default sort is by Committed cost descending so the largest spending items appear first.
- **IT Spend — Budget Status from Run Rate** — IT Service budget status badges now derive from actual run rate vs. budget allocation rather than static data. Services over budget show "OVER CRITICAL" or "OVER 10" badges; healthy services show green "HEALTHY" badges. A new "UNDER 25" warning badge appears when less than 25% of budget remains.
- **IT Spend — View Contract Fix** — Fixed a mismatch between the IT Service budget view and the TypeScript interface that could cause incorrect data display. The Consumers column has been removed (data not available at the view level). Status color coding now properly distinguishes between over-budget severity levels.
- **Tech Health — "End of Support" Label** — The Tech Health dashboard now uses "End of Support" instead of "At Risk" for the lifecycle status label, distinguishing technology lifecycle risk from the Overview page's business-level "At Risk" metric.
- **Overview KPI Reorder** — KPI cards on the Overview page have been reordered to place "At Risk" first, prioritizing the most actionable metric.

## April 7, 2026

- **Assessment Staleness Awareness** — "Assessment Progress" is now "Assessment Status" on the Overview page. Below the progress bar, a staleness indicator warns when assessments are older than 180 days. Click the warning to jump to Explorer filtered to stale items. When all assessments are current, clicking the green status text opens Application Health. The Explorer now has a "Last Assessed" column showing relative timestamps ("3d ago", "2mo ago"), sortable to surface the stalest items first. A "Stale assessments only" checkbox in the Explorer filter drawer lets you isolate overdue assessments.
- **Overview Drill-Down Navigation** — Portfolio Health workspace rows are now clickable — click any workspace name to jump directly to Application Health for that workspace (auto-switches to All Portfolios). The Technology Lifecycle Risk panel is fully interactive: click any legend item (Mainstream, Extended Support, etc.) to open Technology Health filtered by that lifecycle status. Click a category name (Operating System, Database) to filter by category. Click individual cell counts to filter by both lifecycle status and category. The "View affected technologies" link in the EOL warning callout now navigates to Technology Health filtered to End of Support.
- **Overview KPI Card Drill-Down** — All five Overview KPI cards are now clickable. Click "At Risk" to jump to Explorer filtered for Eliminate or End of Support apps. Click "Applications" for an unfiltered Explorer view. Click "Fully Assessed" to see only completed assessments. Click "Crown Jewels" to filter to high-criticality apps. Click "Annual Run Rate" to go straight to IT Spend. Cards show a hover effect and "View" hint on mouseover.
- **At Risk Redefined** — The "At Risk" KPI card now counts apps marked Eliminate (business decision) or End of Support (technology risk). Previously it counted Modernize + Eliminate, which overstated risk since Modernize is a strategic action, not a risk signal.
- **TIME Quadrant Multi-Select** — The Explorer filter drawer now uses checkboxes for TIME Quadrant instead of a single-select dropdown, allowing you to filter by multiple quadrants at once (e.g., Modernize + Eliminate together).
- **Assessment Status Filter** — A new "Assessment Status" filter in the Explorer drawer lets you filter apps by their technical assessment status (Complete, In Progress, Not Started).
- **Scope Bar Clarity** — The scope bar (workspace and portfolio selectors) is now hidden on the Overview tab, which always shows namespace-level data. Previously it appeared dimmed, which confused first-time users into thinking it should filter the Overview. On all other tabs, the scope bar now displays your namespace name as a label before the workspace selector, providing clear organizational context.
- **UX Polish — Filter Icon & KPI Card Order** — Filter buttons across the app now use the sliders icon (matching SaaS convention used by Notion, Linear, Figma) instead of the funnel icon. Overview KPI cards reordered to lead with "At Risk" so the most actionable metric is first.
- **IT Service Catalog Cleanup** — Network Infrastructure and Cybersecurity Operations are now classified as overhead services with no per-app dependency links. Their costs ($250K and $200K) remain in the catalog but no longer appear on individual app dependency lists. ITSM Platform has been converted to a business application ("ServiceNow ITSM") in the IT workspace with an $85K SaaS cost bundle. Microsoft 365 Enterprise and Collaboration & Conferencing have been reclassified from Managed Service to Platform > Runtime/PaaS.
- **IT Service Catalog — Wider Name Column** — The Name column in the IT Service Catalog has been widened so service names like "Enterprise Backup & Recovery" fit on 1-2 lines instead of wrapping to 3.

## April 6, 2026

- **Visual Tab Level 4 — IT Service Technology Drill-Down** — Click any IT service on the Visual tab blast radius (Level 3) to see the technology products that compose it. A teal "Built on" row shows each technology product with lifecycle status badges (Mainstream, Extended, End of Support). Products used by the current deployment profile appear in full color; unused products are dimmed. Services with no technology products linked show an informational empty state. Breadcrumb navigation lets you click back through App > Deployment Profile > IT Service.
- **Single-Click Navigation** — All drill-down actions on the Visual tab now use single-click instead of double-click, including deployment profile and IT service exploration. Hover tooltips read "Click to explore."
- **IT Service Modal Simplified** — The Technology Lifecycle section has been removed from the IT Service edit modal. Lifecycle data will be derived from component technology products in a future update.
- **CSDM Auto-Wiring** — Adding or removing a technology product from a SaaS deployment profile now automatically links or unlinks the corresponding IT service. An informational toast confirms the action.
- **IT Service Derived Lifecycle** — IT services now display a lifecycle badge derived from their component technology products. The worst lifecycle status across all linked tech products is shown (End of Support > Extended Support > Mainstream). Visible on Visual tab Level 3 service nodes, Level 4 hero card, and the IT Service Catalog. Replaces the previously stored lifecycle reference with a live aggregation.

## April 5, 2026

- **CSDM Demo Data Consistency** — IT Service Catalog now shows technology composition via teal "Built on:" chips under each service. Technology Catalog now shows IT Service usage via purple "Powers:" chips under each technology product. Software Catalog displays an amber "Org-wide" badge for organization-wide licenses that don't require DP associations. Visual tab ServiceNode shows a teal technology count pill (Cpu icon) indicating how many technologies compose the service. All cross-reference data sourced from the `it_service_technology_products` junction table.
- **Visual Tab Upgrade — DP-Scoped Blast Radius** — The Visual diagram on the Application Detail page has been rebuilt with React Flow for smoother pan/zoom and cleaner layout. Level 3 "Blast Radius" now shows only the integrations that flow through the selected deployment profile, not all app-level integrations. Level 2 DP nodes display an integration count so you can see at a glance which profiles handle the most connections. Double-click any deployment profile to drill into its blast radius.
- **Visual Tab — ArchiMate-Informed Design** — The Visual diagram now uses enterprise architecture visual conventions: distinct node shapes for applications (rounded), external systems (dashed border), and deployment profiles (square with colored environment bar). Integration edges use solid lines for one-way data flow and dashed lines for bidirectional connections. Hovering any application shows the business owner, business score, and criticality. Level 3 blast radius now includes IT service dependency nodes below the deployment profile, showing which infrastructure services each deployment depends on.

## April 4, 2026

- **Deployment Profile Scoping for Integrations** — When creating or editing a connection, if the application has multiple deployment profiles, a "Deployment Profile" dropdown now appears so you can specify which instance the integration runs through. Single-deployment apps assign automatically. The connections list now shows the DP name alongside the app name when specified.
- **Teams Management** — Namespace admins can now manage teams in Settings > Teams. Define support groups, change advisory boards, and management teams with optional workspace scoping. In-use teams are protected from deletion.
- **Operations Section on Deployment Profiles** — Each deployment profile now includes an Operations section with three team-assignment dropdowns: "Who fixes it when it breaks?", "Who approves changes?", and "Which team manages this day-to-day?" These map to CSDM support groups for ServiceNow export readiness.
- **Contract Details on Recurring Costs** — Recurring cost entries (cost bundles) now have an expandable Contract Details section where you can record a contract reference, start and end dates, and renewal notice period. Contracts with end dates appear on the Contract Expiry widget.
- **Contract Expiry Widget** — The IT Spend tab now shows a Contract Expiry table listing all upcoming contract renewals from both IT Services and recurring costs in one view, with status indicators (Active, Expiring Soon, Renewal Due, Expired) and source badges.
- **Double-Count Awareness** — When adding a recurring cost to an application that already has IT Service costs (or vice versa), a brief prompt helps you check for overlapping cost entries.

## April 3, 2026

- **Tech Health CSV Export Fix** — CSV exports from the Tech Health "By Application" and "Analysis" tabs now use the filename "deployment-profiles" instead of "applications", correctly reflecting that each row represents a deployment profile.

## March 20, 2026

- **Portfolio AI Assistant** — New Chat tab with a conversational AI assistant that answers questions about your application portfolio. Ask about app counts, costs, vendor spend, budget status, or drill into any specific application by name. Supports workspace/department filtering ("show me Finance costs"), conversation history, markdown-formatted responses, and copy-to-clipboard. Data scope respects your role-based access.
- **Explorer Tab** — New top-level navigation tab that combines portfolio and technology data into a single cross-cutting dashboard. See your entire application landscape at a glance with 8 KPI cards, portfolio distribution donut chart, run-rate-by-lifecycle bar chart, and a searchable/sortable detail table. Filter by workspace, lifecycle status, crown jewel, TIME quadrant, and PAID action. Export to CSV.

## March 19, 2026

- **Server Name on Visual Tab** — Deployment profile nodes in the Visual diagram now display the server name (when set), making it easier to identify specific servers at a glance without opening the profile.
- **Deployment Count Fix** — The "X deployments" badge on the Application Health list no longer counts cost bundles, which are cost-tracking records rather than actual deployments.

## March 18, 2026

- **Application Category Column** — The Application Health table now shows each application's assigned categories as compact badges, making it easy to see portfolio segmentation at a glance.
- **Remediation Effort Column** — The Application Health table now displays the remediation effort t-shirt size (XS–2XL) for each application, previously only available as a filter.
- **Application Category Filter** — New filter in the App Health filter drawer lets you narrow applications by category (e.g., "Infrastructure & Ops", "Business Apps").
- **Operational Status Filter** — New filter to show or hide applications by their operational status (Operational, Planned, Retired) — previously only visible as a colored dot.
- **Business Owner Filter** — New filter to narrow the application list by business owner name, answering "which apps does this person own?"

## March 17, 2026

- **Leadership Contacts on Workspaces & Portfolios** — You can now assign leadership and governance contacts (Leader, Business Owner, Technical Owner, Steward, Budget Owner, Sponsor) directly from the Edit modal on the Workspaces in Namespace and Portfolios settings pages. Set a primary contact for each role — the primary leader's name appears on workspace cards.
- **Generate with AI — Description, Use Case & Category** — The "Generate with AI" button on the Application form now fills three fields at once: a concise description (under 300 characters), a detailed primary use case (2-paragraph technical abstract with manufacturer and website URL), and auto-selects the best-fit Application Category. If the AI doesn't recognize the application, the generated text appears in grey italic so you know it needs manual entry.
- **Primary Use Case Field** — New text field on the Application form for a detailed use case description. Can be filled manually or via the AI generate button.

## March 16, 2026

- **Server Name on Deployment Profiles** — You can now set and edit a Server Name on deployment profiles with On-Premise, Hybrid, Third-Party Hosted, or Cloud hosting types. As you type, existing server names from your organization are suggested to prevent duplicates. Server names appear in Tech Health reports and CSV exports.
- **Admin Invite Fix** — Inviting a user as Organization Admin now automatically grants admin access to all workspaces. Previously, workspaces had to be selected manually, which could result in an admin with incomplete access.

## March 13, 2026

- **APM Assistant v2 — Analytical Queries** — The AI chat can now answer aggregate questions like "Who is our largest vendor by spend?" or "How many apps per TIME quadrant?" Claude automatically picks the right tool: semantic search for entity lookups, SQL queries for counts/rankings/comparisons.
- **APM Assistant** — New AI-powered chat drawer for asking questions about your portfolio. Click the sparkle icon in the top nav to open. Ask about applications, tech debt, lifecycle status, or request a SWOT analysis — the assistant searches your actual data and responds in context.
- **Edge Functions Shared Scaffold** — Deployed shared authentication, CORS, and error handling infrastructure for Edge Functions. JWT verification now uses local JWKS instead of network round-trips.
- **Lifecycle Lookup Fix** — The AI Lifecycle Lookup now works reliably with the updated Edge Function authentication.
- **Verify Lifecycle Data** — New "Verify" button on linked lifecycle data. Admins, editors, and stewards can confirm lifecycle dates are accurate. The grid badge updates from "Unverified" to "Verified" immediately.
- **Duplicate Key Fix** — Applying AI lifecycle results no longer fails when data already exists for that product.

## March 12, 2026

- **Chat Widget Tour Fix** — The Crisp onboarding tour no longer reappears after you dismiss it. Previously it would show up on every page load.
- **Profile Photo Upload** — Upload your own avatar from Settings → Profile. Supports JPEG, PNG, WebP, and GIF (max 2 MB).
- **Avatar Display** — The user menu now shows your photo and first name instead of your email address.
- **Technology Standards Badges** — Standards conformance badges now appear on Technology Products showing compliance status.
- **Organization Settings Read-Only** — Non-admin users can now view Organization Settings (read-only) with a clear info banner. Previously this page was hidden from non-admins.
- **My Profile in Settings** — Quick link to your profile added to the settings sidebar navigation.
- **Tech Health Filter Drawers** — By Application, By Technology, and By Server tabs now use slide-in filter drawers with multi-select checkboxes, replacing the inline dropdowns. Select multiple values per filter for more flexible analysis.
- **Simplified Invite & Edit User** — The Organization Role dropdown has been replaced with an Admin toggle checkbox. Non-admin users are silently assigned as viewers, removing the confusing dual "Viewer" label that appeared at both organization and workspace levels.

## March 11, 2026

- **Technology Standards** — New governance view showing technology standards compliance across your portfolio. Assert standards from your technology catalog and track adoption.
- **Workspace-Aware Roadmap** — The Roadmap tab now filters automatically when you switch workspaces.
- **IT Spend Filter Drawer** — Filter the IT Spend dashboard by category (Applications, IT Services, or All).

## March 10, 2026

- **In-App Help** — Access help articles, live chat, and a guided tour from the help menu (question-mark icon in the header).
- **Keyboard Shortcuts** — Press Ctrl+K (Cmd+K on Mac) to open Global Search.

## March 9, 2026

- **Budget Dashboard** — IT Spend promoted to a dedicated dashboard tab with namespace and workspace views, sortable tables, and projected spend from Roadmap initiatives.
- **Projected IT Spend** — See how Roadmap initiatives will impact your run rate with a current → projected comparison.
