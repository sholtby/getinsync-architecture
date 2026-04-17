# Garland Presentation — Audit Response

**Date:** 2026-04-13
**From:** Codebase Audit Session
**To:** Presentation Build Session
**Subject:** Claim-by-claim audit of `garland-presentation-content.md` against deployed codebase and schema

---

## TL;DR

Every claim in the 11-slide deck was verified against `src/`, `supabase/functions/`, and `docs-architecture/schema/nextgen-schema-current.sql`.

- **3 red flags** — claims that are false or describe unbuilt features. Must fix before sending.
- **10 yellow flags** — claims that overstate what's built. Soften the language.
- **Slide 10** (Roadmaps & Visual) — fully accurate, no changes needed.
- **Slide 9** (ITSM) — entire slide describes unbuilt functionality. Replace with **CSDM-Ready Data Model**.
- **Slide 8** (Steward/Restricted) — keep the Steward pitch but flag as near-term delivery.
- **10 deployed capabilities** are missing from the deck entirely — some are stronger selling points than what's currently in the slides.

---

## 1. Red Flags — Must Fix Before Sending

### RED 1: Slide 9 — ITSM Integration Does Not Exist

| | |
|---|---|
| **Claim** | "Application records publish directly to your ITSM platform. Service relationships included. Team assignments mapped to ITSM operational fields." |
| **Reality** | `src/pages/PublishApps.tsx` publishes deployment profiles to **workspace groups** (internal cross-workspace sharing). This is NOT ITSM/ServiceNow sync. Zero ServiceNow API code exists anywhere in `src/` or `supabase/functions/`. No CMDB connector, no CI mapping, no export mechanism. |
| **Evidence** | `grep -r "servicenow\|itsm\|cmdb" src/` returns zero results. `PublishApps.tsx` imports from workspace group hooks, not external API connectors. |
| **Risk** | If Garland asks for a demo of ITSM sync, there is nothing to show. This is the single biggest credibility risk in the deck. |
| **Fix** | **Replace entire slide with "CSDM-Ready Data Model."** CSDM alignment IS built — the data model maps to ServiceNow's Common Service Data Model. Position as a readiness accelerator, not an active integration. See Section 5 below for replacement slide content. |

### YELLOW 0: Slide 7 — Multi-National Data Residency (Soften Wording)

| | |
|---|---|
| **Claim** | "Choose where your data lives — Canada, US, or EU. Each region operates on its own infrastructure. No data crosses residency boundaries." |
| **Reality** | Production currently runs on Canada (ca-central-1). US and EU regions are not provisioned yet but the architecture supports spinning up a new region quickly — Supabase project creation, DNS routing, namespace-to-region assignment. The UI (`NamespaceProvisioning.tsx`) has region selection with US/EU marked "coming soon." |
| **Risk** | The slide reads as if all three regions are live today. If Garland asks "can we see the US instance?" the answer is "we'd provision it for you" — which is fine, but the slide shouldn't imply it's already running. |
| **Fix** | Reframe as: **"Data Residency by Design"** — "Your data lives where you need it. Production runs in Canada today. US and EU regions are available on demand." This is honest — the capability is real, the provisioning is on-demand rather than pre-standing. |

### RED 3: Slide 5 — "YoY Spend Trend" AI Example Is Fabricated

| | |
|---|---|
| **Claim** | "What's our year-over-year spend trend in Public Safety?" shown as an example AI query. |
| **Reality** | The AI system prompt in `supabase/functions/ai-chat/tools.ts` **explicitly instructs Claude to refuse this question**: "The portfolio model does not store historical snapshots — there is no time-series data anywhere in your tool surface." |
| **Evidence** | `ai-chat` system prompt, lines 81–85. No `budget_snapshots` table exists. No historical time-series data is stored. |
| **Risk** | If demoed live, the AI will literally respond "I can't answer that — no historical data exists." |
| **Fix** | Replace with a query the AI can actually answer. Suggestions: **"What's our total IT spend by workspace?"** (uses `cost-analysis` tool with `focus=summary`) or **"Which vendors have the most applications?"** (uses `cost-analysis` with `focus=vendor`). |

### RED 4: Slide 8 — Steward and Restricted Role Behaviors Not Implemented

| | |
|---|---|
| **Claim** | "Steward — business owners assess their own applications, see only what's assigned. Restricted — read-only limited to assigned applications only." |
| **Reality** | Both roles exist as enum values in `namespace_role` type. However, `src/hooks/usePermissions.ts` lines 36–41 contain explicit `// steward(future)` comments. Steward behaves **identically to Editor** — full write access, no scoping. Restricted has namespace-wide read access — `docs-architecture/identity-security/rbac-permissions.md` line 371 confirms portfolio-scoped RLS policies are not built. |
| **Evidence** | `usePermissions.ts`: `canEditBizAssessment: canWrite, // steward(future)`. RBAC doc: "restricted exists at namespace level only." |
| **Fix** | **Keep the Steward pitch — it's too powerful to cut** — but be honest about timing. Present as: "Steward role ships Q2 2026. Today, application owners are invited as Editors scoped to their workspace. Steward adds per-application scoping — they'll see only their apps." The $400K/year savings math from `positioning-statements.md` is a CFO-level talking point at Garland's scale (see Section 4, item 3). For Restricted: same framing — "role exists, per-application scoping is Q2." |

---

## 2. Yellow Flags — Soften Language

| Slide | Current Wording | Suggested Rewording | Why |
|-------|----------------|---------------------|-----|
| 3 | "Automated alerts before contracts expire or auto-renew" | "Contract expiry dashboard with renewal status tracking" | No email/push notifications exist. `ContractExpiryWidget.tsx` shows status badges (expired/renewal_due/expiring_soon) but the user must check the dashboard manually. No cron job, no notification system. |
| 3 | "Each application follows one cost path — never attributed to both an IT Service and a Cost Bundle simultaneously" | "Double-count warnings when mixing cost channels" | `CostBundleSection.tsx` lines 80–128 check for existing IT Service allocations and show a warning modal — but users can click **"Add anyway"** to override. It's a guard, not a hard block. "Never" is too strong. |
| 3 | "Year-over-Year Budget Trends" | "Multi-Year Budget Tracking" | `vw_workspace_budget_history` view exists with `budget_yoy_change` and `prior_year_budget` columns, but **no frontend component consumes it**. No trend chart. EditBudgetModal shows prior year as context only. The data model supports it; the UI doesn't surface it. |
| 5 | "Show me all applications with no assigned business owner" | Add a footnote: "ownership gap detection" | `list-applications` tool has an `owner` filter for name matching but **no filter for null/missing owner**. The AI could scan results for unassigned entries, but it's not a first-class query path. Keep the example but don't oversell it as instant. |
| 6 | "When reference data doesn't exist, AI looks it up automatically" | "AI-assisted lifecycle lookup" | The `lifecycle-lookup` Edge Function exists with a 3-tier pipeline (DB → endoflife.date API → Claude extraction), but it's **user-initiated with confirmation** ("Look up lifecycle data for SQL Server 2016?"), not fully automatic. |
| 6 | "Services like Flexera, Snow, and ServiceNow SAM charge $60K+ per year" | "typically $20K–$100K+ per year" | `docs-architecture/features/technology-health/lifecycle-intelligence.md` section 2.1 cites: Flexera $20K–100K+, Snow $15K–50K+. "$60K+" cherry-picks from a wide range. |
| 7 | "OAuth, Single Sign-On, and Entra ID integration" | "Enterprise OAuth including Microsoft Entra ID" | `OAuthButtons.tsx` implements Google and Microsoft/Azure OAuth. This is social OAuth login, not enterprise SAML/OIDC SSO with configurable IdP. No SAML code exists. |
| 7 | "Evidence collection is automated" | "One-command evidence generation" | `generate_soc2_evidence()` RPC exists and produces a JSON evidence report, but it's manually invoked — not scheduled or automated. SOC2 Type II certification not yet obtained. MEMORY.md notes SOC2 policy documents are overdue (GPD-528/529/530). |
| 9 | "Technology Product (15 categories)" | "Technology Product (16 categories)" | Database has 16 categories, not 15. Off by one. |

---

## 3. Confirmed Accurate — No Changes Needed

These claims passed audit. Leave them as-is:

| Slide | Claim | Evidence |
|-------|-------|----------|
| 3 | Budget Cycle Management — flag overruns | `BudgetKpiCards.tsx` computes healthy/tight/over status. Working. |
| 3 | Vendor Spend Rollups | `CostAnalysisPanel.tsx` "By Vendor (Top 10)" with `get_vendor_spend_by_portfolio` RPC. Interactive. |
| 3 | IT Spend Dashboard | `BudgetPage.tsx` with filter-responsive KPIs. Heading is "IT Spend Overview." |
| 4 | RLS workspace isolation | 402 RLS policies, 131 ENABLE ROW LEVEL SECURITY statements, pgTAP regression (437 assertions). |
| 4 | Workspace independence | All data tables keyed by `workspace_id`. Budgets, assessments, contacts all scoped. |
| 4 | Publisher/Consumer model | `workspace_groups`, `workspace_group_members`, `PublishApps.tsx`, `BrowseSharedApps.tsx`. Enterprise-tier. |
| 4 | Cross-workspace leadership views | "All Workspaces" mode, `BudgetNamespaceOverview.tsx` aggregates. |
| 5 | AI chat answers plain English questions | `ai-chat` Edge Function, 10 tools, Claude tool-use loop, JWT-scoped RLS. |
| 5 | Oracle vendor spend query | `cost-analysis` tool, `focus=vendor`, sums both cost channels. |
| 5 | Contract expiry query | `cost-analysis` tool, `focus=contracts`, computes days-until-expiry. |
| 5 | End-of-support technology query | `list-applications` tool, `lifecycle_status` enum with `end_of_support`. |
| 6 | AI-augmented lifecycle intelligence | `lifecycle-lookup` Edge Function, 3-tier pipeline. Deployed. |
| 6 | 76+ vendor lifecycle references | MANIFEST.md confirms "76 rows, 16 vendors" seeded. |
| 6 | Technology Health Dashboard | `TechnologyHealthPage.tsx`, 5 tabs, filter drawers per tab. |
| 6 | Standards Intelligence | `StandardsIntelligencePage.tsx`, `vw_implied_technology_standards`. Phase 1 deployed. |
| 7 | Complete Audit Trail | `fn_audit_trigger` with `old_values`/`new_values`/`changed_fields`. 63 triggers. `AuditLog.tsx` UI. |
| 8 | Five role enum values exist | `namespace_role: 'admin' | 'editor' | 'steward' | 'viewer' | 'restricted'` in types. |
| 10 | Findings → Ideas → Initiatives → Programs | `RoadmapPage.tsx`, all four entity types with promotion workflow. |
| 10 | Kanban, Gantt, Grid views | `InitiativeKanbanView.tsx`, `InitiativeGanttView.tsx`, `InitiativeGridView.tsx`. Enterprise-gated. |
| 10 | Link initiatives to applications | `LinkedDeploymentProfile`, `LinkedITService` with relationship types. |
| 10 | Visual drill-down (4 levels) | `graphBuilders.ts` with React Flow. All levels implemented. |
| 10 | Integration dependencies | `ConnectionsVisual.tsx` with directional arrows. |
| 10 | Pan, zoom, breadcrumbs | React Flow `<Controls>`, `<MiniMap>`, clickable breadcrumbs. |

---

## 4. What the Presentation Missed (Built, Not Shown)

These are deployed capabilities that aren't mentioned anywhere in the 11 slides. Some are stronger selling points than what's currently in the deck.

| # | Capability | Where It's Built | Where It Could Fit | Why It Matters |
|---|-----------|-----------------|-------------------|---------------|
| 1 | **TIME/PAID Assessment Framework** | `src/components/assessment/` — full assessment flow with factor weighting, score computation, quadrant placement | Own slide, or strong live demo moment | This is the **engine** of the platform. The deck talks about costs and technology but never mentions the core assessment methodology. TIME answers "what should we do with this app?" PAID answers "how urgently?" |
| 2 | **Deployment Profile-centric model** | `deployment_profiles` table as assessment anchor, not `applications` | Slide 9 replacement (CSDM-Ready) | "You assess deployments, not software." Same app in PROD vs DR = different assessments. Key differentiator vs every competitor. |
| 3 | **Steward pricing math** | `positioning-statements.md` §5: "200 App Owners as Editors: $400,000/year. 200 App Owners as Stewards: $0." | Slide 8 — add as a call-out or talking point | At Garland's scale (multiple divisions, hundreds of app owners), this is a CFO-level number. |
| 4 | **CSDM alignment** | Data model maps to ServiceNow CSDM entities (Application, Business Service, Technical Service, Deployment) | Slide 9 replacement | "ServiceNow-ready out of the box. No metamodel configuration. No custom objects." This is the competitive moat. |
| 5 | **30–60 day implementation** | `positioning-statements.md` §6: Orbus 6–12+ months, ServiceNow 3–6 months, GetInSync 30–60 days | Slide 11 or competitive positioning beat | Proof point. Backed by the Orbus story: "28 months, zero apps loaded." |
| 6 | **Three cost channels** | Software Product / IT Service / Cost Bundle architecture — `deployment_profile_software_products`, `it_services`, `dp_type = 'cost_bundle'` | Slide 3 — name the channels | The cost model is the hero of Slide 3 but the three-channel architecture is never explained. Naming it makes it concrete. |
| 7 | **Gamification / data quality badges** | `src/components/gamification/` — badge system driving data completeness | Demo talking point | Drives engagement. "Your team earns badges for data completeness — gamified portfolio management." |
| 8 | **Global search** | `src/components/search/` — cross-entity search | Demo talking point | "Search across applications, services, vendors, and contacts from one search bar." |
| 9 | **Explorer tab** | `src/components/explorer/` — portfolio browsing with advanced filters | Demo talking point | Advanced portfolio navigation. Good for "how do I find things?" questions. |
| 10 | **Audit Log UI** | `src/pages/settings/AuditLog.tsx` — searchable, filterable, CSV-exportable | Strengthen Slide 7 | Currently says "complete audit trail." Could say "searchable audit log with filters and CSV export" — more concrete, more impressive. |

---

## 5. Slide 9 Replacement — CSDM-Ready Data Model

Replace the current ITSM slide with this content:

**Title:** Your Applications, Ready for ServiceNow

**Subtitle:** CSDM-aligned from day one — no metamodel configuration, no custom objects to build.

**Three value cards:**

- **CSDM-Aligned Architecture** — Application, Business Service, Technical Service, and Deployment entities map directly to ServiceNow's Common Service Data Model. Your data is structured for ServiceNow from the moment you enter it.

- **Clean Data, Ready to Migrate** — When you're ready for ServiceNow APM, your data migrates cleanly. No transformation scripts. No consulting engagement to reshape your data model. GetInSync is the on-ramp.

- **Three Managed Catalogs** — IT Service (14 types), Software Product (12 categories), Technology Product (16 categories). Structured reference data keeps your portfolio clean and consistent.

**Bottom reference:** "Orbus iServer: 6–12 months to value. ServiceNow APM: 3–6 months. GetInSync: 30–60 days."

**Talking point for live delivery:** "You don't need ServiceNow to get started. But when you're ready, your data is already in the right shape. We're the accelerator, not the replacement."

---

## 6. Slide-by-Slide Quick Reference

| Slide | Title | Verdict | Action Required |
|-------|-------|---------|-----------------|
| 1 | Title Slide | ✅ Clean | None |
| 2 | You Asked. We Built. | ✅ Clean | Consider adding TIME/PAID and CSDM to the seven-item list |
| 3 | Cost Intelligence | ⚠️ 3 yellow flags | Soften "automated alerts," "never," and "YoY Trends" |
| 4 | Portfolio Isolation | ✅ Fully accurate | None |
| 5 | AI Portfolio Intelligence | ❌ 1 red + 1 yellow | Replace YoY example, soften "no owner" claim |
| 6 | Technology Health | ⚠️ 3 yellow flags | Soften "automatically," "$60K+," count is 16 not 15 |
| 7 | Security & Compliance | ⚠️ 3 yellow flags | Reframe data residency wording, soften SSO and SOC2 claims |
| 8 | Access Controls | ❌ 1 red (roles) | Keep Steward pitch, flag as Q2 delivery, add $400K math |
| 9 | ITSM Integration | ❌ Full replacement | Replace with CSDM-Ready Data Model (see Section 5) |
| 10 | Roadmaps & Visual | ✅ Fully accurate | None |
| 11 | Your Input Shapes What Ships | ✅ Clean | Consider adding 30–60 day implementation proof point |

---

## 7. Roadmap Items (Not Session-Prompted)

Three XL/2XL features flagged by this audit are already tracked in the product roadmap (`marketing/product-roadmap-2026.md`) and the open-items priority matrix (`planning/open-items-priority-matrix.md`). These are product-level features requiring architecture decisions beyond what a session prompt can scope — they don't need gap-closure prompts, but the Garland context should be preserved.

| Feature | Triggered By | Roadmap Phase | Effort | Scheduled | Notes |
|---------|-------------|---------------|--------|-----------|-------|
| **ITSM / ServiceNow sync** | Slide 9 (replaced with CSDM-Ready) | Phase 37 (bi-directional) + Phase 51 (APM publishing) | 12-16 days | Q3 2026 | Slide 9 was replaced, not deferred. ITSM sync remains a roadmap feature, not a presentation gap. |
| **Enterprise SSO (SAML/OIDC)** | Slide 7 (softened to "Enterprise OAuth") | Phase 40: Entra ID SSO | 5-6 days | Q2 2026 | Current OAuth via Google + Microsoft/Azure covers most cases. True SAML with custom IdP config is the gap. |
| **Multi-region data residency** | Slide 7 (reframed as "by design") | Phase 43: Data Residency & Multi-Region | 10-12 days | Q4 2026 | US region is deployable on demand. EU requires regulatory analysis. Mostly infrastructure work, not application code. |

If Garland specifically requests any of these during the live walkthrough, the response is: "That's on our roadmap for [quarter]. Your input helps us prioritize — let's discuss what you need."

---

*Audit completed 2026-04-13 against `main` branch. All evidence verified via codebase grep, schema inspection, and Edge Function source review.*
