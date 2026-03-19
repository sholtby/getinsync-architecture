# What's New

Recent updates to GetInSync NextGen.

---

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

- **Server Name on Deployment Profiles** — You can now set and edit a Server Name on deployment profiles with On-Premises, Hybrid, Third-Party Hosted, or Cloud hosting types. As you type, existing server names from your organization are suggested to prevent duplicates. Server names appear in Tech Health reports and CSV exports.
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
