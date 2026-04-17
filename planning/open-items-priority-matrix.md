# GetInSync NextGen — Open Items Priority Matrix
**As of:** April 17, 2026
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
| 37 | Demo | Riverside demo data refresh | Demo namespace needs updated data for sales demos. Tech tagging done (#19 closed). Roadmap data restored (Apr 8: 8 findings, 6 initiatives, 6 ideas, 2 programs, 4 dependencies + SirsiDynix app). Remaining: hosting_type fill, assessment scores. | -- | Stuart |
| 43 | RBAC | Assessment permission split — who can assess vs edit app | Currently same permission. Should be separable. Architecture decision needed. ~1-2 days. | -- | Stuart |
| 44 | RBAC | Flag CREATE viewer exception — flags INSERT policy allows any workspace member | ADR: Flags are governance, not data edits. Viewer can create but not update/delete. Part of gamification Phase 1. | Gamification Phase 1 | Stuart |
| 57 | UX | Scope indicator — show user's data visibility | Display "N of M workspaces" indicator in tab bar or header. Users who don't see all workspaces should know their view is filtered. ~0.5 day. | -- | Stuart + Claude Code |
| 63 | Feature | ~~Servers on Visual Diagram + Dashboard~~ | ✅ **SUPERSEDED by #93** (Multi-Server DP). Original single `server_name` display on Visual tab DP nodes shipped Mar 19. Now evolving to full many-to-many server model. | -- | Stuart + Claude Code |
| 93 | Feature | Multi-Server Deployment Profiles | **Phase 1 COMPLETE (Apr 12).** Schema deployed: `servers` (106th table), `server_role_types`, `deployment_profile_servers`. 10 RLS policies, 2 audit triggers. Migration: 73 servers extracted, 75 junction links. 4 views updated/created. **Phase 2 types/hooks COMPLETE (Apr 12).** `Server`, `ServerRoleType`, `DeploymentProfileServer` interfaces added. `useServerManagement` hook created. `useDeploymentProfileEditor` refactored for server entity fetch. View contracts updated. **Phase 3 dashboards COMPLETE (Apr 12).** `TechnologyHealthByServer` rewritten for entity-based grouping (server_id, OS, data center, status columns). `SummaryApplicationTable` + `TechnologyHealthByApplication` updated for multi-server display with truncation. CSV exports updated. Filter drawer updated (data center + status filters). **Phase 4 visual tab COMPLETE (Apr 12).** DPNode renders multi-server at 3 zoom levels (L1 primary, L2 +badge, L3 all with roles). Remaining: Phase 2 UI (tag picker + server mgmt page), Phase 5 (drop `server_name`, docs), view-contract fix (#97). Spec: `features/technology-health/multi-server-dp-design.md`. | #63 (superseded) | Stuart + Claude Code |
| 94 | Feature | Integration Field Parity — OG to NextGen | OG-vs-NextGen field comparison identified 6 gaps: (1) lifecycle start/end dates missing from schema, (2) SFTP transport fields missing (sftp_required, sftp_host, sftp_credentials_status), (3) `notes` + `sla_description` columns exist in DB but not rendered in AddConnectionModal UI, (4) integration contacts (`integration_contacts` table exists with roles but no UI in form), (5) `integration_method_types` missing report/etl/message_queue codes for Garland data patterns, (6) direction vocab mismatch (cosmetic, deferred). 2-phase delivery: Phase 1 (schema + dates + notes/SLA UI), Phase 2 (transport section + contacts in form). Spec: `features/integrations/integration-field-parity-design.md`. ~2-3 hrs total. | -- | Stuart + Claude Code |
| 64 | Feature | Namespace Management UI completion | Phase 25.10 partially built. Remaining scope TBD. Prerequisites met (25.8, 25.9 complete). | -- | Stuart + Claude Code |
| 65 | Feature | Budget Alerts frontend | DB layer deployed (alert_preferences table, vw_budget_alerts view). Frontend pending. ~1-2 days. | -- | Stuart + Claude Code |
| 66 | Feature | In-App Support S.6 — Assessment tour | Shepherd.js already integrated (S.2 complete). Step-by-step assessment walkthrough. ~0.5 day. | -- | Stuart + Claude Code |
| ~~68~~ | ~~Feature~~ | ~~TypeScript types — update `VwIntegrationDetail` for 4 new DP columns~~ | ✅ **CLOSED Apr 4.** Full 34-column sync deployed. DP selector in Add Connection modal + DP name in connections list. `data_sensitivity` bug fixed. Cost bundle DPs excluded. Integration-DP Phase 3 complete. | -- | Stuart + Claude Code |
| 70 | Feature | AI Chat: add teams query tool | `teams` table not discoverable by AI Chat. Add `search_teams` tool to `ai-chat/tools.ts` exposing team name, scope, DP assignment counts. Example questions: "what teams support SAP?", "which team manages Finance apps?" ~1 hr. | -- | Stuart + Claude Code |
| 71 | Feature | Global Search: add teams entity | `teams` table not in `global_search` RPC. Add `team_results` WITH clause searching by team name. Requires SQL script + AppHeader.tsx routing. ~1 hr. | -- | Stuart + Claude Code |
| 95 | Feature | AI Chat: add server query tool | `servers` and `vw_server_deployment_summary` not discoverable by AI Chat. Add tool querying `vw_server_deployment_summary` to answer "what apps run on PROD-SQL-01?", "which servers does AppX use?", "show all database servers". Part of multi-server Phase 4. ~1 hr. | #93 Phase 4 | Stuart + Claude Code |
| 83 | Database | audit_logs.workspace_id FK blocks orphan cleanup | `audit_log_trigger()` tries to INSERT the deleted row's workspace_id into audit_logs, but audit_logs has its own FK to workspaces — DELETE of orphaned workspace_users fails. Discovered during EV-002 cleanup (Apr 9). Fix: make `audit_logs.workspace_id` FK ON DELETE SET NULL, or drop the FK (audit logs should survive entity deletion). ~15 min SQL. | -- | Stuart |
| 84 | SOC2 | generate_soc2_evidence RPC — last_manual_backup hardcoded | RPC returns hardcoded `last_manual_backup: "2026-02-08"` — 60+ days stale as of EV-002. Options: make dynamic (query pg_stat_backup?), or update on each manual pg_dump. Flagged in both EV-001 and EV-002 validation. ~15 min. | -- | Stuart |
| 85 | SOC2 | generate_soc2_evidence RPC — schema_function_count scope | Function count jumped from 50 (EV-001) to 1,283 (EV-002). Likely now includes pg_catalog/extension functions instead of just public schema user functions. Review RPC query and scope correctly. ~15 min. | -- | Stuart |

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
| 69 | UX | IT Spend tab UX overhaul | BudgetPage layout, CostAnalysisPanel discoverability (hidden drill-in from Dashboard KPI), Contract Expiry widget placement, overall navigation and information hierarchy. **Phase 1 spec written:** `features/cost-budget/it-spend-kpi-clickthrough.md` — KPI click-to-scroll + Budget Alerts fix. Discuss with Stuart. | -- | Stuart + Claude Code |
| 72 | Bug | ConnectionsVisual.tsx sensitivity value mismatch | `isSensitive` check (line 481) tests for `pii/pci/phi` but `sensitivity_types` ref table has `low/moderate/high/confidential`. Lock icon in ApplicationConnections tests `high/confidential`. The Visual tab check may never match. Pre-existing — not a regression. ~15 min fix. | -- | Stuart + Claude Code |
| 73 | Documentation | Visual tab user help article | No user help article in `guides/user-help/` covers the Visual diagram tab (three-level drill-down, blast radius, layout persistence). ~1 hr to write. | -- | Stuart + Claude Code |
| 75 | Maintenance | npm audit fix — 14 Dependabot alerts (7 high, 7 moderate) | All in dev dependencies (undici, flatted, picomatch, brace-expansion) — not shipped to production. Run `npm audit fix` to pick up patched versions. Remaining resolve when Vite/tooling releases updates. No production impact. ~15 min. | -- | Stuart + Claude Code |
| 76 | Database | Supabase linter — move pgtap/vector/pg_trgm extensions out of public schema | Supabase recommends a dedicated `extensions` schema. Low risk — cosmetic warning. Moving extensions can break existing queries. `search_path` fix on `copy_application_categories_to_new_namespace` already applied (Apr 5). | -- | Stuart |
| ~~77~~ | ~~Data~~ | ~~Dashboard vs Explorer at_risk_count mismatch~~ | ✅ **CLOSED Apr 7.** All 3 dashboard views fixed: app-level counts, At Risk redefined as Eliminate OR End of Support, explorer `primary_pa` picks worst-case quadrant. | -- | Stuart |
| 78 | Feature | At Risk: add contract expiry signal | Consider adding expired/expiring_soon contracts (`vw_contract_expiry`) to the At Risk KPI card count. Data exists in cost bundles. Requires: threshold decision (expired only? expiring_soon?), SQL change to `risk_agg` CTE in 3 dashboard views, add contract columns to `vw_explorer_detail`, frontend filter update. Effort: M (~2-3 hrs). | -- | Stuart + Claude Code |
| 79 | Bug | VwWorkspaceBudgetSummary.workspace_status TypeScript mismatch | DB view returns `no_budget`/`over_allocated`/`under_10`/`healthy` but TS union declares `no_budget`/`no_costs`/`healthy`/`tight`/`over`. Table re-derives client-side so no visible bug, but contract is wrong. Fix in KPI click-through implementation. ~15 min. | -- | Stuart + Claude Code |
| 80 | Bug | ESLint config error — BudgetNamespaceOverview.tsx:21 | Malformed eslint-disable comment includes rule description text. ESLint parses it as a rule name → 1 error. ~1 min fix. | -- | Stuart + Claude Code |
| 81 | RBAC | "New Application" button visible to viewers and restricted users | DashboardAppTable.tsx and ApplicationsPool.tsx show "New Application" in empty state without role-gating. Viewers and restricted users see the button but inserts would fail at RLS. Gate behind `canCreateApp` from `usePermissions()`. ~15 min. | -- | Stuart + Claude Code |
| 74 | Feature | Lifecycle Diagram — dual lifecycle view (app + technology) | Two distinct lifecycles per application: (1) Business Application lifecycle (vendor support status for the software product version), (2) Technology lifecycle (worst-case EOL/EOS from underlying technology stack via `deployment_profile_technology_products` → `technology_lifecycle_reference`). Should be a table/timeline view similar to GetInSync OG's Lifecycle Diagram tab — shows dependencies with Gantt-style bars, highlights EOS items in red. Current `applications.lifecycle_status` is manually set and misleading — remove from Visual tab tooltip until derived version is built. Requires: schema for derived lifecycle computation, UI for timeline view, auto-derivation logic from technology EOL dates. ~3-5 days. | -- | Stuart + Claude Code |
| 86 | Data Quality | Legacy title-case `deployment_profiles.paid_action` | 11 DP rows still hold `'Plan'`, `'Address'`, `'Ignore'` (title case). CLAUDE.md constraint allows both forms but `testing/data-quality-validation.sql` §casing:paid_action FAILs. Pre-existing — predates 2026-04-10. ~15 min `UPDATE deployment_profiles SET paid_action = lower(paid_action) WHERE paid_action IN ('Plan','Address','Ignore','Delay')`. Flagged during Phase 0 session-end checklist. | -- | Stuart |
| 87 | Data Quality | Legacy title-case `portfolio_assignments.business_assessment_status` | 33 portfolio_assignment rows still hold `'Not Started'` (title case with space). Check constraint allows both forms. `testing/data-quality-validation.sql` §assessment:business_assessment_status FAILs. Pre-existing — predates 2026-04-10. ~15 min `UPDATE portfolio_assignments SET business_assessment_status = 'not_started' WHERE business_assessment_status = 'Not Started'`. Flagged during Phase 0 session-end checklist. | -- | Stuart |
| 88 | Refactoring | `supabase/functions/ai-chat/index.ts` reaching 579 lines | Edge Function orchestrator now in the 500-800 "consider splitting on next touch" band after Batch 1+2 work added the tool execution loop, UpstreamError handling, and the vendor-cost completeness logic. Candidates for extraction: Anthropic API call wrappers (`callClaude`/`callClaudeForSynthesis` + UpstreamError class) into `_shared/anthropic-client.ts`; SSE streaming (`streamResponse`) into `_shared/sse.ts`. Not urgent — file is still maintainable, no test coverage yet so risk of refactoring is moderate. ~1-2 hr if done with care. | -- | Stuart + Claude Code |
| 89 | Future Feature | AI Chat — real `data-quality` tool | The current `data-quality` tool is labeled "Coming soon" in the prompt but is wired up enough that the model calls it and gets back partial data. Q10 in the harness eval (data completeness) ended at GOOD on the strength of "honest about limitations" framing rather than substantive specificity. To push Q10 from GOOD to EXCELLENT and properly handle the broader "what data am I missing?" category, build a real `data-quality` tool that returns: (a) per-workspace assessment coverage, (b) IT services with no contract, (c) workspaces with no budget, (d) integrations not DP-aligned, (e) apps with $0 run rate flagged as data gap not zero cost. ~1-2 days. | -- | Stuart + Claude Code |
| 90 | Hardening | AI Chat — strict same-turn stat grounding | The no-hallucinated-stats rule in `system-prompt.ts` forbids fabricated numbers but tolerates accurate numbers reused from earlier turns in the same conversation. The Batch 2 eval observed Q9 and Q10 both citing "17% assessed portfolio-wide" without a same-turn tool call (the number was correct, sourced from a prior turn's `portfolio-summary`). Not a blocker — neither answer was wrong — but if a future iteration wants strict per-turn grounding, the prompt would need an additional rule forbidding cross-turn stat reuse and the response rules would need a "if you need a number you cited earlier, call the tool again" clause. Trade-off: this could over-correct and force unnecessary tool calls on follow-up questions where the prior turn's data is genuinely fresh. ~30 min prompt change + re-eval. | -- | Stuart + Claude Code |
| 91 | Future Feature | AI Chat — historical snapshot capability | The Batch 2 temporal-refusal rule turns "trend over 6 months" questions into clean graceful refusals because the portfolio model captures current state only. If users start asking temporal questions frequently enough that the refusal becomes unsatisfying, build a historical snapshot capability: nightly cron that captures `portfolio_summary` + per-workspace stats into a `portfolio_snapshots` table with a `snapshot_date` column, plus a new `portfolio-trend` AI Chat tool that queries it. ~3-5 days including cron setup, table, view, tool, and UI. Not blocking. | -- | Stuart + Claude Code |
| 96 | Refactoring | `src/types/index.ts` at 818 lines (over 800 threshold) | Grew past 800 with multi-server DP interfaces (Server, ServerRoleType, DeploymentProfileServer). Consider splitting into `src/types/deployment-profiles.ts` and `src/types/servers.ts`. Not urgent — single-file types are easy to navigate with search. ~30 min. | -- | Stuart + Claude Code |
| 97 | Bug | `ServerTechnologyReportRow` view-contract mismatch | `src/types/view-contracts.ts` declares `workspace_id` and `workspace_name` on `ServerTechnologyReportRow` but `vw_server_technology_report` groups by `server_id` + `namespace_id` only — those columns don't exist in the view. Component adapted to avoid them (Apr 12), but the interface needs 2 fields removed. ~5 min. | -- | Stuart + Claude Code |
| 98 | Feature | Tech Health By Server — server detail modal | OS, Data Center, and EOS columns hidden from the table (Apr 13) to fix column cramping. Build a click-through server detail modal showing full server attributes (name, OS, data center, status, notes, linked DPs with roles, EOS tech count). Similar to contact/team detail modals. Data available from `servers` table + `deployment_profile_servers` junction. ~2-3 hrs. | -- | Stuart + Claude Code |
| 99 | Bug | Tech Health By Server — filter drawer incomplete | Filter drawer only exposes Server Status and Lifecycle Status filters. Should also include: OS filter, Data Center filter, Primary Tech filter, and EOS count threshold. Pattern: match the By Application tab's filter set. ~1-2 hrs. | -- | Stuart + Claude Code |
| 92 | Future Feature | Application Categories catalog refinement (Phase 2) — add ITSM, EAM, FSM codes | Identified during the 2026-04-11 application-categories Session 1 Gartner MQ level-set. Three Gartner-tracked software markets have no clean home in the existing 14-row `application_categories` catalog and are being shoehorned into the closest umbrellas: (a) **ITSM** (IT Service Management Platforms MQ) — ServiceNow ITSM + ServiceDesk Plus currently tagged only as INFRASTRUCTURE, which is wrong-shaped (ITSM is case/process management, not ops monitoring); (b) **EAM** (Enterprise Asset Management MQ) — Samsara Fleet and Sensus FlexNet currently squishily tagged as ERP+GIS_SPATIAL and INFRASTRUCTURE+ANALYTICS respectively; (c) **FSM** (Field Service Management MQ) — not biting Riverside today but the next municipal customer with dispatched field crews will hit the gap. Work required: add 3 rows to the template namespace `application_categories` (id `00000000-0000-0000-0000-000000000001`) with sensible descriptions + display_order after HEALTH (13) but before UNCATEGORIZED (99); update `copy_application_categories_to_new_namespace()` seed function if needed; backfill all existing namespaces with the 3 new rows; re-map the 4 shoehorned Riverside apps (ServiceNow ITSM → ITSM, ServiceDesk Plus → ITSM, Samsara Fleet → EAM+GIS_SPATIAL, Sensus FlexNet → EAM+ANALYTICS). Catalog stays flat at 17 categories (16 real + UNCATEGORIZED), still scannable. ~2-3 hrs schema + ~1 hr re-map. Not blocking Sessions 2 or 3. | -- | Stuart + Claude Code |

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

## Completed Apr 17

| Item | Resolution |
|------|------------|
| AI Chat — Garland audit yellow flag (Slide 5: ownership-gap query) | ✅ COMPLETE. Two related fixes shipped in v2026.4.11 on branch `fix/ai-chat-owner-filter` (merged to dev + main, Edge Function deployed). **Fix 1 (commit b6e1233):** added `has_owner` boolean filter to `list-applications` tool. `true` = apps where `owner_name IS NOT NULL`; `false` = apps where `owner_name IS NULL`. Fills the gap where the existing `owner` ilike filter could not detect missing owners. **Fix 2 (commit ce548c8):** verification of the Garland query exposed that `vw_explorer_detail` returns `0` (not NULL) as the unassessed sentinel for criticality / tech_health / business_fit. Tools were treating `0` as a real low score, leading the AI to mislabel unassessed apps as "low-scoring" and pollute risk/struggling-apps results. Updated `list-applications` (select assessment_status fields, render `[unassessed]` tag and "Status: Not assessed" line, show "(N assessed, M unassessed)" breakdown, exclude unassessed from `tech_health_max` filter), `application-detail` (treat 0 as 'Not assessed' for criticality/tech_health/tech_risk/business_fit, crown-jewel marker only fires when criticality > 0), and `technology-risk` (replaced `.not('criticality', 'is', null)` with `.gt('criticality', 0)` — NULL filter alone passed unassessed apps through). Verified end-to-end against Riverside namespace: AI now correctly reports "31 unowned: 7 assessed (4 crown jewels + 3 others) + 24 unassessed". Memory updated with `vw_explorer_detail` zero-sentinel gotcha. User docs updated: `whats-new.md` Apr 17 entry, `ai-assistant.md` ownership-and-assessment-gap example questions added. |

---

## Completed Apr 11

| Item | Resolution |
|------|------------|
| Application Categories — Session 1 (Riverside data enrichment) | ✅ EXECUTED. 3-session initiative kicked off (`planning/application-categories/`). Session 1 seeded 53 category assignments across 32 of 32 Riverside apps (100% coverage, 0 UNCATEGORIZED misuse, 12 of 13 real categories used — DEVELOPMENT unused by design). Chunked CTE-driven SQL pattern: 7 files in `enrichment-sql/` (00 baseline verifier, 5 assignment chunks grouped by workspace cluster, 99 final verifier). Apps resolved by name + categories by code — no UUIDs embedded. ON CONFLICT DO NOTHING idempotency. All verifiers consolidated as CTE+UNION ALL with `(ord, section, jsonb)` shape per the CLAUDE.md SQL Editor rule. Mid-session bug fix: `\pset pager off` meta-commands removed from all 7 files because the Supabase SQL Editor rejects psql meta-commands (Phase 0 precedent was psql-first, this initiative is SQL-Editor-first). Gartner MQ level-set identified 3 missing codes (ITSM/EAM/FSM) — filed as item #92 for Phase 2 catalog refinement. Schema metadata fix: `application_categories` table comment corrected to reflect M:M (stale ARM v2.0 "one category" comment). Sessions 2 (AI Chat category tools) and 3 (category eval) ready to run. Arch repo: `aca430f` (SQL files) + `89feb89` (meta-command fix) + `fd3a429` (README mark complete). |
| AI Chat Harness Optimization — Batch 2 (final) | ✅ COMPLETE. Three-batch Meta-Harness Option B initiative ended at **10/10 acceptable answers** (trajectory 2/10 → 6/10 → 10/10). Batch 2 added three prompt subheadings to `system-prompt.ts` (rationalization-direction semantics, temporal-question refusal, data-classification refusal) — all three landed effectively in re-eval. Both Batch 1 regressions (Q1 CAD vs Hexagon, Q4 6-month trend) resolved. Q9 PII shape change resolved. Q10 unexpectedly improved from SHALLOW to GOOD as a downstream effect of the same prompt-discipline tightening. Q6 SWOT no longer carries the Q1-linked caveat from Batch 1. Frozen results: `planning/ai-chat-harness-optimization/20-eval-results-batch-2.md`. Branch `feat/ai-chat-harness-eval` merged to `dev` (fast-forward, 8 commits, 731 insertions). Edge Function deployed twice (Batch 2 prompt + upstream message extraction). Version bumped 2026.4.8 → 2026.4.9. AI Assistant help article rewritten to reflect 6 tools and graceful-failure modes. What's New entry added. |
| AI Chat — Rate-limit and overload error UX | ✅ COMPLETE. Replaced the generic "Sorry, something went wrong" with structured, actionable error messages. Server side: new `UpstreamError` class in `supabase/functions/ai-chat/index.ts` parses Anthropic's `retry-after` header (numeric or HTTP-date), classifies 429 vs 529 vs other 5xx, extracts Anthropic's own error text from the response body, and surfaces all of it through the structured error response. Shared `errorResponse()` helper in `_shared/error-handler.ts` extended with optional `details` parameter (backwards-compat for the other 4 Edge Functions). Frontend: new `ChatRequestError` class in `src/hooks/useAiChat.ts` preserves status, code, retry_after_seconds, and upstream_message. New `formatChatError()` helper produces friendly messages by code. Both the toast and the in-chat assistant bubble now show actionable text like "Claude is rate-limited right now. Please wait about 5 minutes and try again." with Anthropic's precise reason appended when available. Stuart upgraded Anthropic to Tier 2 mid-eval after hitting daily token cap, and the new error handling helped diagnose the issue. |
| `secrets-inventory.md` ANTHROPIC_API_KEY consumer fix | ✅ FIXED. The `ai-chat` Edge Function (shipped Mar 20) was missing from the consumer list — it was using `ANTHROPIC_API_KEY` but only `lifecycle-lookup`, `apm-chat`, and `ai-generate` were listed. Added `ai-chat` to the row. Stale-doc cleanup, no functional change. |

## Completed Apr 10

| Item | Resolution |
|------|------------|
| GitBook Phase 0 — Riverside demo data enrichment | ✅ EXECUTED. All 4 NEEDS-ENRICHMENT articles (2.1, 2.4, 4.2, 4.3) unblocked + optional 1.4 covered. 9 idempotent SQL chunks in `planning/phase-0-assets/enrichment-sql/` (BEGIN/COMMIT, consolidated verification SELECTs, Supabase-SQL-Editor safe, rollback comments, Garland-lessons-informed). Landed in Riverside: 3 CAD contacts (Pat Alvarez / K. Patel / Jordan Chen), 3 DP-aligned integrations + ServiceNow CMDB Sync named, 3 new FY2026 workspace budgets (Fire/PW/Finance = +$3.65M), top-3 IT services contracted + Azure pulled into renewal window (2026-06-30), CAD PROD DP data_center+server_name populated, 2 new cost_bundle DPs (CentralSquare CAD Support $85K + Hexagon OnCall Managed Services $110K). CLAUDE.md: new "Supabase SQL Editor — Multi-statement output semantics" rule added after discovering the Editor only shows the last result set. Manifest v2.07→v2.08. |

## Completed Apr 5

| Item | Resolution |
|------|------------|
| Visual Tab React Flow resume (Chunk 7) | ✅ COMPLETE. Rebased `feat/visual-tab-reactflow` onto dev. Level 3 blast radius wired to DP-scoped integrations (filters by source/target_deployment_profile_id). Integration count added to Level 2 DP nodes. All known ADR gaps resolved. Version 2026.4.3 deployed. |
| Integration-DP Phase 4 data migration (Chunk 6) | ✅ NO-OP. All 23 existing integrations already had DPs assigned from Phase 1-3 UI work. Migration script validated but nothing to migrate. |

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
| **MEDIUM** | 24 | Identity rewrite, compliance (3 more OVERDUE), Delta enablement, demo data, website, RBAC assessment split, scope indicator, **multi-server DPs (#93)**, **integration field parity (#94)**, namespace UI, budget alerts, assessment tour |
| **LOW** | 15 | Doc cleanup, OAuth cosmetic, polish, RBAC naming, cron job, ChartsView decomposition, CSV export label, Tech Health on app detail, **+2 data-quality legacy casing items (#86, #87) flagged Apr 10** |
| **Feature Roadmap** | 11 | Edge Functions (T1), AI Chat (T1), Gamification (T2), Scoring Patterns (T2), Realtime (T2), Business Capability (T2), App Relationships (T2), Standards Ph2 (T2), Cloud Discovery (Future), Unified Chat (Future), ITSM (Future) |
| **Total Open** | 42 | Apr 12: +2 features (#93 multi-server DP, #94 integration field parity). #63 superseded by #93. |

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
