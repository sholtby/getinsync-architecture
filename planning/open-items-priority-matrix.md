# GetInSync NextGen — Open Items Priority Matrix
**As of:** March 5, 2026 (Phase 27b Lifecycle UI Complete)
**Rule:** HIGH = Blockers / Schema | MED = Security / Compliance | LOW = UI / Polish

---

## HIGH — Blockers & Schema Issues

| # | Category | Item | Why HIGH | Blocked By | Assigned |
|---|----------|------|----------|------------|----------|
| 2 | SOC2 Policy | Information Security Policy | Required for SOC2 — umbrella policy covering all controls. ~2-3 hrs. **OVERDUE (due Feb 27).** | -- | Delta (GPD-528) |
| 3 | SOC2 Policy | Change Management Policy | Required for SOC2 — codify existing Git/architecture workflow. ~1-2 hrs. Also enable GitHub branch protection on `main` (no force push, no deletion) as CC8.1 evidence. **OVERDUE (due Feb 27).** | -- | Delta (GPD-529) + Stuart (branch protection) |
| 4 | SOC2 Policy | Incident Response Plan | Required for SOC2 — detect > assess > contain > notify runbook. ~2-3 hrs. **OVERDUE (due Feb 27).** | -- | Delta (GPD-530) |
| 40 | RBAC | UI role gating — 13 actions lack frontend role checks | Security debt — RLS protects DB but UI shows create/delete/edit buttons to all roles. Demo risk + principle violation. See identity-security/rbac-permissions.md §8.4. ~2-3 days. | -- | Stuart + Claude Code |
| 62 | Refactoring | Edit Application tab refactoring — extract Deployments + Costs tabs | General tab overloaded with DPs, costs, and identity. Lift Deployments and Costs into their own tabs. Tab bar already built (6 tabs), Integrations + Visual already live. Create mode = no tab bar (single-scroll). ~4-6 hrs across 2 Claude Code segments. Assessment tab parked (needs #43 resolved). | -- | Stuart + Claude Code |

---

## MEDIUM — Security & Compliance

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
| 18 | Analytics | Power BI Foundation — deploy 14 views | 14 vw_pbi_* views exist but not deployed. First dashboard build. | -- | Stuart |
| 37 | Demo | Riverside demo data refresh | Demo namespace needs updated data for sales demos. Tech tagging done (#19 closed). Remaining: hosting_type fill, assessment scores. | -- | Stuart |
| 41 | RBAC | Permission-aware Supabase hooks | Custom hooks (useCanEdit, useCanDelete, useCanCreate) that read user role. Foundation for #40. ~1-2 days. | -- | Stuart |
| 42 | RBAC | Role-gated settings sidebar | Some settings visible to viewers that should be admin-only. ~0.5 day. | #41 | Stuart |
| 43 | RBAC | Assessment permission split — who can assess vs edit app | Currently same permission. Should be separable. Architecture decision needed. Blocks Assessment tab (#62). ~1-2 days. | #41 | Stuart |
| 44 | RBAC | Flag CREATE viewer exception — flags INSERT policy allows any workspace member | ADR: Flags are governance, not data edits. Viewer can create but not update/delete. Part of gamification Phase 1. | Gamification Phase 1 | Stuart |
| 55 | UX | Filter drawer pattern → push to other dashboards | Extract TechnologyHealth FilterDrawer as reusable component. Apply to: main Dashboard, Portfolios, By Application list, Integration Management. Consistent UX pattern across app. ~1-2 days. Partially addressed by Dashboard Refresh Phase D. | -- | Stuart + Claude Code |
| 57 | UX | Scope indicator — show user's data visibility | Display "N of M workspaces" indicator in tab bar or header. Users who don't see all workspaces should know their view is filtered. Prevents confusion where partial data looks like complete data. ~0.5 day. | Dashboard Refresh C.1 | Stuart + Claude Code |
| 58 | Bug | Cost Analysis crashes when portfolioId='all' | Cost Analysis page passes selectedPortfolioId directly to Supabase queries without checking for the special 'all' value. .eq('portfolio_id', 'all') returns 400. Pre-existing bug exposed by "All Portfolios" mode. ~1 hr. | -- | Stuart + Claude Code |

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
| 51 | Feature | Surface Technology Health on Application Detail page | Option C: General tab gets summary badge (worst lifecycle status + tag count line). Deployments tab gets per-DP OS/DB/Web columns with LifecycleBadge. Data from vw_application_infrastructure_report filtered by application_id. ~1-2 days. Fits naturally into #62 General tab cleanup (Project 3). | #62 | Stuart + Claude Code |
| 60 | Refactoring | ChartsView.tsx decomposition (984 lines) | Over 800-line threshold. Grew with filter drawer integration, DP labels, bubble fixes, and getEntryKey() helper. Candidates: extract BubbleChart sub-component, extract filter logic into a hook, extract Priority Backlog table section. ~0.5-1 day. | -- | Stuart + Claude Code |
| 61 | Bug | Tech Health CSV export labels rows as "applications" but exports at DP level | Screen shows "15 applications" but CSV has 16 rows because Hexagon OnCall has 2 DPs. Fix: change column header and count label in export to say "deployment profiles" not "applications". One-liner. | -- | Stuart + Claude Code |

---

## Completed This Session (Mar 5 — Session 3)

| Item | Resolution |
|------|------------|
| Phase 27b.4 — IT Service lifecycle linking | ✅ COMPLETE. ITServiceModal rewritten with lifecycle reference search/create/display. LifecycleBadge added to IT Service catalog grid. Schema gaps deployed (lifecycle_reference_id FK on it_services). |
| Phase 27b.5 — Software Product lifecycle linking | ✅ COMPLETE. SoftwareProductModal rewritten with lifecycle reference search/create/display. Lifecycle join added to SoftwareProductsSettings fetch. Schema gaps deployed (lifecycle_reference_id FK on software_products). |
| Phase 27 schema gaps (5 scripts) | ✅ DEPLOYED. it_services.lifecycle_reference_id FK, software_products.lifecycle_reference_id FK, it_service_technology_products junction table (with GRANT/RLS/audit), vw_it_service_lifecycle_risk view, vw_dp_lifecycle_risk_combined view. |

## Completed Mar 5 — Session 2

| Item | Resolution |
|------|------------|
| Cost Model Reunification Phase 3F | ✅ COMPLETE. Quick Calculator for IT Service allocation — inline Unit Price × Quantity = Total popover in IT Service dependency table. Saves as `allocation_basis='fixed'`. |
| Cost Model Reunification (all phases) | ✅ ALL PHASES COMPLETE (0–3). Phase 3 shipped: TypeScript types, ITServiceModal contract fields, IT Service→Software Product linking, cost component verification, Contract Expiry Widget, Quick Calculator. |
| phase3-handover.md cleanup | ✅ Deleted temporary handover doc as instructed. |

## Completed Mar 5 — Session 1

| Item | Resolution |
|------|------------|
| Per-workspace portfolio memory | ✅ COMPLETE. Workspace switching now restores last-used portfolio per workspace. `user_sessions.portfolio_by_workspace` JSONB column added. localStorage map with DB sync for cross-device persistence. Three timing bugs fixed (stale data detection, effect ordering, 'all' leaking). |
| Per-DP assessment buttons in drawer | ✅ COMPLETE. ApplicationDetailDrawer shows per-deployment-profile "Assess" buttons. Each button navigates to the correct DP's assessment. |
| Consumer assessment label fix | ✅ COMPLETE. Assessment columns now show correct labels matching DP-level assessment data. |
| pgTAP plan count alignment | ✅ FIXED. Plan count updated from 416 → 423 to match actual test count (93 tables, 51 audit triggers, 30 views). |

## Completed Mar 3

| Item | Resolution |
|------|------------|
| #53 Pagination | ✅ CLOSED. By Application grouped table has 10/25/50/100/All page size selector. Confirmed working. |
| #54 KPI reframe | ✅ CLOSED. At Risk / Extended Support / Mainstream KPI cards count applications, not tags. Donut charts count tags (intentional — tag-level composition). |
| #56 Back arrow | ✅ CLOSED. Tech Health back arrow navigates correctly. |
| #52 Workspace Tech Health | ✅ CLOSED. Workspace filter in Tech Health filter drawer is sufficient. No dedicated route needed. |
| #38 Documentation | ✅ CLOSED. security-posture-overview updated to v1.2 (48 triggers, 29/29 custom views). |
| #39 Documentation | ✅ CLOSED. soc2-evidence-index updated to v1.2 (48 triggers). |

## Completed Prior Sessions

| Item | Resolution |
|------|------------|
| #59 ChartsView duplicate key warning | ✅ FIXED Mar 2. Root cause: `application.id` used as React key, but multiple portfolio assignments share the same app. Solution: `getEntryKey()` helper using `portfolioAssignment.id` as unique key. Also fixed wrong DP links and tooltips. |
| Filter persistence Dashboard → Charts | ✅ COMPLETE Mar 2. `AppHealthFilterState` snapshot captured on "View full analysis" click, passed as `initialFilters` to ChartsView. |
| PAID filter label fix | ✅ FIXED Mar 2. "Improve" → "Ignore", "Divest" → "Delay". |
| Warning badge indentation | ✅ FIXED Mar 2. AlertTriangle moved to inline after app name. |
| #35 IT Value Creation implementation | ✅ COMPLETE Feb 22. Phase 21 deployed. 8 tables, 4 views, seed data. |
| #34 Technology Health Dashboard | ✅ COMPLETE. All 4 tabs functional. Promoted to main tab bar. |
| Dashboard Refresh Phases A–C.4 | ✅ COMPLETE. Views deployed, decomposition done, KPI bar wired, tab bar deployed, filter persistence done. |

---

## Summary

| Priority | Count | Theme |
|----------|-------|-------|
| **HIGH** | 5 | 3 SOC2 policies (OVERDUE) + RBAC UI gating + Edit App refactoring |
| **MEDIUM** | 19 | Identity rewrite, compliance (3 more OVERDUE), Delta enablement, demo data, website, RBAC enforcement, filter drawer, scope indicator, Cost Analysis bug |
| **LOW** | 13 | Doc cleanup, OAuth cosmetic, polish, RBAC naming, cron job, ChartsView decomposition, CSV export label, Tech Health on app detail |
| **Total Open** | 37 | No new open items this session. Phase 27b lifecycle UI complete (all 5 sub-items). |

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
*Replaces: March 5, 2026 Session 2 version*
