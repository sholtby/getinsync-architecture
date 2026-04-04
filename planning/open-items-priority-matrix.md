# GetInSync NextGen — Open Items Priority Matrix
**As of:** March 20, 2026
**Rule:** HIGH = Blockers / Schema | MED = Security / Compliance | LOW = UI / Polish

---

## HIGH — Blockers & Schema Issues

| # | Category | Item | Why HIGH | Blocked By | Assigned |
|---|----------|------|----------|------------|----------|
| 2 | SOC2 Policy | Information Security Policy | Required for SOC2 — umbrella policy covering all controls. ~2-3 hrs. **OVERDUE (due Feb 27).** | -- | Delta (GPD-528) |
| 3 | SOC2 Policy | Change Management Policy | Required for SOC2 — codify existing Git/architecture workflow. ~1-2 hrs. Also enable GitHub branch protection on `main` (no force push, no deletion) as CC8.1 evidence. **OVERDUE (due Feb 27).** | -- | Delta (GPD-529) + Stuart (branch protection) |
| 4 | SOC2 Policy | Incident Response Plan | Required for SOC2 — detect > assess > contain > notify runbook. ~2-3 hrs. **OVERDUE (due Feb 27).** | -- | Delta (GPD-530) |
| ~~67~~ | ~~Architecture~~ | ~~Integration-to-DP alignment~~ | ✅ **CLOSED Mar 20.** Phase 1+2 deployed (Stage 1). source/target_deployment_profile_id FKs on application_integrations, vw_integration_detail rebuilt with DP columns. | -- | Stuart |

---

## MEDIUM — Security, Compliance & Features

| # | Category | Item | Why MED | Blocked By | Assigned |
|---|----------|------|---------|------------|----------|
| 1 | Architecture | Identity/Security rewrite v1.1 > v2.0 | SSO deferred to Q2. SOC2 CC6.1 evidence gap remains but not Q1 blocker. | -- | Stuart |
| 6 | Database | Audit log workspace index | workspace_id column exists but no index — filter will table-scan | -- | Stuart |
| 7 | Database | users.is_super_admin design debt | Duplicates platform_admins — security logic split across two sources | -- | Stuart |
| 9 | SOC2 Policy | Acceptable Use Policy (internal/SOC2) | Required for SOC2 — for internal team (Stuart, Delta). ~1 hr. **OVERDUE (due Feb 27).** | -- | Delta (GPD-531) |
| 10 | SOC2 Policy | Data Classification Policy | Required for SOC2 — Public/Internal/Confidential/Restricted. ~1 hr. **OVERDUE (due Mar 6).** | -- | Delta (GPD-532) |
| 11 | SOC2 Policy | Business Continuity Plan | Required for SOC2 — DR procedures, communication plan. ~2 hrs. **OVERDUE (due Mar 6).** | -- | Delta (GPD-533) |
| 12 | SOC2 | Backup restore test | A1.2 gap — never tested restore from pg_dump. ~2 hrs. Target: before first enterprise deal. | -- | Stuart |
| 14 | SOC2 | Uptime monitoring setup | CC7.2 gap — no monitoring beyond Supabase/Netlify defaults. ~1 hr. | -- | Stuart |
| 15 | SOC2 | auth.audit_log_entries empty (0 rows) | CC6.6 gap — Supabase auth audit log not populating. Investigate. | -- | Stuart |
| 16 | Enablement | Delta training on Namespace UI | Delta must be independent for Garland import. ~2 hrs walkthrough. | -- | Stuart + Delta |
| 17 | Marketing | Website update | Professional credibility. Claude Code task. ~1 day. | -- | Stuart + Claude Code |
| 18 | Analytics | Power BI Export Layer — deploy 6 vw_pbi_* views | Architecture doc written (power-bi-export.md v1.0). 6 views designed. Phase 1: deploy views + service account. Phase 2: Edge Function API. | -- | Stuart |
| 37 | Demo | Riverside demo data refresh | Demo namespace needs updated data for sales demos. Tech tagging done (#19 closed). Remaining: hosting_type fill, assessment scores. | -- | Stuart |
| 43 | RBAC | Assessment permission split — who can assess vs edit app | Currently same permission. Should be separable. Architecture decision needed. ~1-2 days. | -- | Stuart |
| 44 | RBAC | Flag CREATE viewer exception — flags INSERT policy allows any workspace member | ADR: Flags are governance, not data edits. Viewer can create but not update/delete. Part of gamification Phase 1. | Gamification Phase 1 | Stuart |
| 57 | UX | Scope indicator — show user's data visibility | Display "N of M workspaces" indicator in tab bar or header. Users who don't see all workspaces should know their view is filtered. ~0.5 day. | -- | Stuart + Claude Code |
| 63 | Feature | Servers on Visual Diagram + Dashboard | Server_name now shows on Visual tab DP nodes + tooltip (Mar 19, branch `feat/dp-server-name-visual`). Remaining: surface on Overview dashboard. ~0.5 day. | -- | Stuart + Claude Code |
| 64 | Feature | Namespace Management UI completion | Phase 25.10 partially built. Remaining scope TBD. Prerequisites met (25.8, 25.9 complete). | -- | Stuart + Claude Code |
| 65 | Feature | Budget Alerts frontend | DB layer deployed (alert_preferences table, vw_budget_alerts view). Frontend pending. ~1-2 days. | -- | Stuart + Claude Code |
| 66 | Feature | In-App Support S.6 — Assessment tour | Shepherd.js already integrated (S.2 complete). Step-by-step assessment walkthrough. ~0.5 day. | -- | Stuart + Claude Code |
| 68 | Feature | TypeScript types — update `VwIntegrationDetail` for 4 new DP columns | source/target_deployment_profile_id + names. Consumers: IntegrationDetail components. ~0.5 day. | Stage 1 SQL deployed | Stuart + Claude Code |

---

## LOW — UI & Polish

| # | Category | Item | Why LOW | Blocked By | Assigned |
|---|----------|------|---------|------------|----------|
| 8 | Architecture | Doc cleanup (WBS 1.8) — 12 docs with stale AWS refs | Cosmetic — deferred to Q2. SOC2 risk low (auditors see manifest status tags). | -- | Stuart |
| 21 | OAuth | Microsoft Publisher Verification | MPN Business Verification rejected, docs resubmitted Feb 13. OAuth WORKS for external users — verification is cosmetic (removes "unverified app" warning). 3 max doc attempts. | Microsoft review | Stuart |
| 22 | SOC2 Policy | Vendor Management Policy | Required for SOC2 — Supabase/Netlify/GitHub evaluation. ~1 hr. Target: before SOC2 audit. | -- | Delta (GPD-534, due Mar 27) |
| 23 | SOC2 Policy | Data Retention Policy | Required for SOC2 — already enforced in code. ~30 min to document. | -- | Delta (GPD-535, due Mar 27) |
| 24 | Architecture | Document retention policy for architecture docs | Some docs superseded but not archived. Manifest tracks status but no formal policy. | -- | Stuart |
| 25 | Database | Orphaned portfolio_assignments cleanup | Some PAs may reference deleted DPs. Run FK integrity check. | -- | Stuart |
| 45 | RBAC | contacts.workspace_role naming — rename read_only to viewer | Cosmetic inconsistency. contacts uses read_only where all other tables use viewer. ~30 min migration. | -- | Stuart |
| 46 | Documentation | Archive RBAC draft + Excel; update identity-security cross-refs | Superseded by identity-security/rbac-permissions.md. Update identity-security v1.1 §5 to point to new doc. ~30 min. | -- | Stuart |
| 49 | Database | Drop CHECK constraints on application_integrations | criticality, direction, integration_type, frequency, status, data_format, sensitivity, data_classification columns still have CHECK constraints. Now redundant since values come from reference tables. Low risk — constraints don't hurt, but they block adding new values to reference tables. | -- | Stuart |
| 50 | Database | Lifecycle status cron refresh | current_status is trigger-computed, not auto-refreshing when date boundaries cross. Add weekly cron: `UPDATE technology_lifecycle_reference SET updated_at = now();` or Supabase pg_cron. | -- | Stuart |
| 51 | Feature | Surface Technology Health on Application Detail page | Option C: General tab gets summary badge (worst lifecycle status + tag count line). Deployments tab gets per-DP OS/DB/Web columns with LifecycleBadge. Data from vw_application_infrastructure_report filtered by application_id. ~1-2 days. | -- | Stuart + Claude Code |
| 60 | Refactoring | ChartsView.tsx decomposition (984 lines) | Over 800-line threshold. Grew with filter drawer integration, DP labels, bubble fixes, and getEntryKey() helper. Candidates: extract BubbleChart sub-component, extract filter logic into a hook, extract Priority Backlog table section. ~0.5-1 day. | -- | Stuart + Claude Code |
| 61 | Bug | Tech Health CSV export labels rows as "applications" but exports at DP level | Screen shows "15 applications" but CSV has 16 rows because Hexagon OnCall has 2 DPs. Fix: change column header and count label in export to say "deployment profiles" not "applications". One-liner. | -- | Stuart + Claude Code |
| 69 | UX | IT Spend tab UX overhaul | BudgetPage layout, CostAnalysisPanel discoverability (hidden drill-in from Dashboard KPI), Contract Expiry widget placement, overall navigation and information hierarchy. Discuss with Stuart. | -- | Stuart + Claude Code |

---

## Feature Roadmap — Designed, Not Yet Built

These features have complete architecture documents but no code implementation. See MANIFEST.md for document links.

| Feature | Architecture Doc | Effort | Priority | Notes |
|---------|-----------------|--------|----------|-------|
| **Edge Functions Infrastructure** | infrastructure/edge-functions-layer-architecture.md v1.2 | 3-5 days | **TIER 1** | **Phase 1 COMPLETE (Mar 13).** Shared scaffold deployed (_shared/auth.ts, cors.ts, error-handler.ts). lifecycle-lookup redeployed with JWKS auth. Deploy with `--no-verify-jwt` (ES256 gateway issue). Remaining: 7 more functions planned, 4 HIGH gaps in multi-region routing. |
| **AI Chat** | features/ai-chat/mvp.md, v2.md, v3-multicloud.md | 3-5 days | **TIER 1** | **V2 COMPLETE (Mar 13).** MVP + tool-use upgrade deployed. Two tools: `search_portfolio` (hybrid search) + `query_database` (SQL SELECT via `chat_query_portfolio()` RPC). Non-streaming tool loop (max 3 iterations) + SSE streaming of final text. V3 planned: multi-cloud cost lookup. |
| **Gamification & Data Quality** | features/gamification/architecture.md v1.2 | 2-3 days | TIER 2 | Audit-log-driven achievements, streaks, data quality flags. Self-contained. |
| **Tech Scoring Patterns** | features/assessment/tech-scoring-patterns.md | 1-2 days | TIER 2 | Pre-fill T-score defaults from hosting type + pattern. Reduces assessment fatigue. |
| **Realtime Subscriptions** | features/realtime-subscriptions/architecture.md v1.0 | 2-3 days | TIER 2 | Backend deployed (WAL, publication config). Frontend hooks + components pending. |
| **Business Capability** | catalogs/business-capability.md v1.0 | 2-3 days | TIER 2 | Hierarchical taxonomy, tag-based app mapping. Additive, no breaking changes. |
| **Application Relationships (Suites)** | core/composite-application.md v2.0 | 2-3 days | TIER 2 | Suite/family relationships. Schema changes needed. Phase 1 scoped. |
| **Standards Intelligence Ph2** | features/technology-health/standards-intelligence.md | 2-3 days | TIER 2 | T-score integration. Phase 1 deployed. |
| **Cloud Discovery** | features/cloud-discovery/architecture.md | Large | FUTURE | AWS/Azure/GCP connectors. Enterprise feature. |
| **Unified Chat** | features/support/unified-chat-integration.md | Large | FUTURE | Blocked on Edge Functions + AI Chat + conversation persistence tables. |
| **ITSM Integration (Phase 37)** | features/integrations/itsm-api-research.md | 15-20 days | FUTURE | ServiceNow + HaloITSM publish/subscribe. Q3+. |

---

## Completed Mar 20

| Item | Resolution |
|------|------------|
| #67 Integration-to-DP alignment (CSDM gap) | ✅ CLOSED. Phase 1+2 deployed (Stage 1). source/target_deployment_profile_id FKs on application_integrations, vw_integration_detail rebuilt with DP columns. ADR: adr-integration-dp-alignment.md v1.2 ACCEPTED. |
| AI Chat persistence tables | ✅ DEPLOYED. ai_chat_conversations + ai_chat_messages tables (8 RLS policies, 2 audit triggers). Stage 1 data layer. |

## Completed Mar 13

| Item | Resolution |
|------|------------|
| AI Chat V2 — Tool-Use Database Access | ✅ DEPLOYED. `chat_query_portfolio()` RPC + Edge Function rewrite with Anthropic tool-use API. Two tools: `search_portfolio` + `query_database`. Sentinel updates (tables 97, triggers 55). |

## Completed Mar 8–12

| Item | Resolution |
|------|------------|
| #40 — RBAC UI role gating | ✅ COMPLETE. `usePermissions` hook at `src/hooks/usePermissions.ts`. UI gating on ApplicationDetailDrawer + other components. |
| #41 — Permission-aware hooks | ✅ COMPLETE. Centralized `usePermissions` returns all permission flags (canEditDP, canEditLifecycle, canEditCost, canCreateApp, etc). |
| #42 — Role-gated settings sidebar | ✅ COMPLETE. `feat/settings-readonly-non-admin` merged. Read-only mode for non-admins with info banner + disabled inputs + hidden save button. |
| #55 — Filter drawer reusable | ✅ COMPLETE. `TechHealthFilterDrawerShell` shared component + 7 implementations (Tech Health x3, App Health, IT Spend, Roadmap, Charts). |
| #58 — Cost Analysis crash (portfolioId='all') | ✅ FIXED. `CostAnalysisPanel.tsx` handles both undefined and 'all' with `isAllPortfolios` guard. |
| #62 — Edit Application tab refactoring | ✅ COMPLETE. Deployments & Costs extracted to `DeploymentsTab` in `ApplicationPage.tsx`. |
| Standards Intelligence Phase 1 (S.1–S.6) | ✅ DEPLOYED. 2 tables, 2 views, 2 RPCs. Standards sub-tab with KPI cards + category table + assert modal. |
| Standards Phase 2 — conformance badges | ✅ DEPLOYED. `feat/standards-phase2-badges` merged. Badges on Tech Health tables. |
| In-App Support S.1–S.5, S.7 | ✅ DEPLOYED. Provider abstraction, Shepherd.js tours, Crisp, HelpMenu, GitBook, Chatwoot. |
| Roadmap workspace-aware filtering | ✅ DEPLOYED. Global workspace selector sync + membership filtering. KPI bar fix included. |
| User avatar + first name display | ✅ DEPLOYED. `feat/user-avatar` merged. Photo upload, 4-tier fallback, Supabase Storage bucket. |
| Settings sidebar restructure | ✅ COMPLETE. My Profile link added, Organization Settings renamed. |
| Main Dashboard Refresh | ✅ DONE / SUPERSEDED. Dashboard reworked. |
| Main App Navigation | ✅ DONE / SUPERSEDED. Navigation implemented. |
| Global Search (Ctrl+K) | ✅ FULLY BUILT. RPC + frontend overlay. |
| Roadmap UI | ✅ FULLY BUILT. Schema + Gantt/Kanban/Grid UI. |
| Visual Diagram 3-level | ✅ BUILT. App → DP → Blast Radius walkable. Servers pending (#63). |

## Completed Mar 8

| Item | Resolution |
|------|------------|
| Phase 28a — Catalog Search Edge Function | ✅ COMPLETE. `technology-catalog-search` Edge Function deployed with search + get-cycles endpoints. Vendor map for 461 endoflife.date products. |
| Phase 28b — Version Picker + Auto-Population | ✅ COMPLETE. `TechnologyCatalogSearchModal` with search-first flow + version picker. `TechnologyProductModal` prePopulated prop with auto-match for manufacturer/category/lifecycle. Bug fix: namespace_id filter on category query. |
| Phase 28c — DP Technology Linking Flow | ✅ COMPLETE. `LinkTechnologyProductModal` enhanced with "Search catalog & create new" escape hatch. Chained modal flow with z-index fix. IT Service/Software Product deferred (already have AI Lookup). |

## Completed Mar 5

| Item | Resolution |
|------|------------|
| Phase 27b.4 — IT Service lifecycle linking | ✅ COMPLETE. ITServiceModal rewritten with lifecycle reference search/create/display. LifecycleBadge added to IT Service catalog grid. Schema gaps deployed (lifecycle_reference_id FK on it_services). |
| Phase 27b.5 — Software Product lifecycle linking | ✅ COMPLETE. SoftwareProductModal rewritten with lifecycle reference search/create/display. Lifecycle join added to SoftwareProductsSettings fetch. Schema gaps deployed (lifecycle_reference_id FK on software_products). |
| Phase 27 schema gaps (5 scripts) | ✅ DEPLOYED. it_services.lifecycle_reference_id FK, software_products.lifecycle_reference_id FK, it_service_technology_products junction table (with GRANT/RLS/audit), vw_it_service_lifecycle_risk view, vw_dp_lifecycle_risk_combined view. |
| Cost Model Reunification (all phases) | ✅ ALL PHASES COMPLETE (0–3). Phase 3 shipped: TypeScript types, ITServiceModal contract fields, IT Service→Software Product linking, cost component verification, Contract Expiry Widget, Quick Calculator. |
| Per-workspace portfolio memory | ✅ COMPLETE. Workspace switching restores last-used portfolio per workspace. |
| Per-DP assessment buttons in drawer | ✅ COMPLETE. ApplicationDetailDrawer shows per-DP "Assess" buttons. |
| Consumer assessment label fix | ✅ COMPLETE. Assessment columns show correct labels. |
| pgTAP plan count alignment | ✅ FIXED. Plan count 416 → 423. |

## Completed Mar 3 and Prior

| Item | Resolution |
|------|------------|
| #53 Pagination | ✅ CLOSED. By Application grouped table has page size selector. |
| #54 KPI reframe | ✅ CLOSED. KPI cards count applications, donuts count tags. |
| #56 Back arrow | ✅ CLOSED. Tech Health back arrow navigates correctly. |
| #52 Workspace Tech Health | ✅ CLOSED. Workspace filter in filter drawer is sufficient. |
| #38, #39 Documentation | ✅ CLOSED. security-posture-overview and soc2-evidence-index updated. |
| #59 ChartsView duplicate key warning | ✅ FIXED Mar 2. |
| Filter persistence Dashboard → Charts | ✅ COMPLETE Mar 2. |
| PAID filter label fix | ✅ FIXED Mar 2. |
| Warning badge indentation | ✅ FIXED Mar 2. |
| #35 IT Value Creation implementation | ✅ COMPLETE Feb 22. Phase 21 deployed. |
| #34 Technology Health Dashboard | ✅ COMPLETE. All 4 tabs functional. |
| Dashboard Refresh Phases A–C.4 | ✅ COMPLETE. |

---

## Summary

| Priority | Count | Theme |
|----------|-------|-------|
| **HIGH** | 3 | 3 SOC2 policies (OVERDUE) — Delta-assigned |
| **MEDIUM** | 22 | Identity rewrite, compliance (3 more OVERDUE), Delta enablement, demo data, website, RBAC assessment split, scope indicator, servers on visual/dashboard, namespace UI, budget alerts, assessment tour, VwIntegrationDetail DP columns |
| **LOW** | 13 | Doc cleanup, OAuth cosmetic, polish, RBAC naming, cron job, ChartsView decomposition, CSV export label, Tech Health on app detail |
| **Feature Roadmap** | 11 | Edge Functions (T1), AI Chat (T1), Gamification (T2), Scoring Patterns (T2), Realtime (T2), Business Capability (T2), App Relationships (T2), Standards Ph2 (T2), Cloud Discovery (Future), Unified Chat (Future), ITSM (Future) |
| **Total Open** | 38 | #67 closed Mar 20, #68 added. 12 items completed Mar 8–12. Feature Roadmap section added. |

### SOC2 Policy Scorecard

| Policy | Priority | Jira | Due | Status | Effort |
|--------|----------|------|-----|--------|--------|
| Information Security Policy | HIGH | GPD-528 | Feb 27 | ⚠️ **OVERDUE** — Assigned to Delta | 2-3 hrs |
| Change Management Policy | HIGH | GPD-529 | Feb 27 | ⚠️ **OVERDUE** — Assigned to Delta | 1-2 hrs |
| Incident Response Plan | HIGH | GPD-530 | Feb 27 | ⚠️ **OVERDUE** — Assigned to Delta | 2-3 hrs |
| Acceptable Use Policy (internal) | MED | GPD-531 | Feb 27 | ⚠️ **OVERDUE** — Assigned to Delta | 1 hr |
| Data Classification Policy | MED | GPD-532 | Mar 6 | ⚠️ **OVERDUE** — Assigned to Delta | 1 hr |
| Business Continuity Plan | MED | GPD-533 | Mar 6 | ⚠️ **OVERDUE** — Assigned to Delta | 2 hrs |
| Vendor Management Policy | LOW | GPD-534 | Mar 27 | Assigned to Delta | 1 hr |
| Data Retention Policy | LOW | GPD-535 | Mar 27 | Assigned to Delta | 30 min |
| **Total** | | | | **0 of 8 complete, 6 overdue** | **~12-15 hrs** |

### OAuth Scorecard

| Provider | Status | Notes |
|----------|--------|-------|
| Google | ✅ Verified & Live | Published to production, branding verified, no user warnings |
| Microsoft | ⚠️ Working (cosmetic warning) | OAuth functional for all users. Publisher verification rejected, docs resubmitted Feb 13. |

---

*Document: planning/open-items-priority-matrix.md*
*Replaces: March 8, 2026 version*
