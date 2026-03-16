# What's New

Recent updates to GetInSync NextGen.

---

## March 16, 2026

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
