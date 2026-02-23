# GetInSync NextGen — Open Items Priority Matrix
**As of:** February 21, 2026 (session 6)
**Rule:** HIGH = Blockers / Schema | MED = Security / Compliance | LOW = UI / Polish

---

## HIGH — Blockers & Schema Issues

| # | Category | Item | Why HIGH | Blocked By | Assigned |
|---|----------|------|----------|------------|----------|
| 2 | SOC2 Policy | Information Security Policy | Required for SOC2 — umbrella policy covering all controls. ~2-3 hrs. | -- | Delta (GPD-528, due Feb 27) |
| 3 | SOC2 Policy | Change Management Policy | Required for SOC2 — codify existing Git/architecture workflow. ~1-2 hrs. | -- | Delta (GPD-529, due Feb 27) |
| 4 | SOC2 Policy | Incident Response Plan | Required for SOC2 — detect > assess > contain > notify runbook. ~2-3 hrs. | -- | Delta (GPD-530, due Feb 27) |
| 35 | Feature | IT Value Creation implementation | 4 tables + junctions + findings/initiatives UI. Week 5-6. ~5-6 days. Benefits from Tech Health data. | -- | Stuart + Claude Code |
| 40 | RBAC | UI role gating — 13 actions lack frontend role checks | Security debt — RLS protects DB but UI shows create/delete/edit buttons to all roles. Demo risk + principle violation. See identity-security/rbac-permissions.md §8.4. ~2-3 days. | -- | Stuart + Claude Code |
| 53 | UX | By Application grouped table + pagination | Grouped table with expandable DPs is IN. Pagination (10/25/50/100/All selector) status TBD — confirm with Stuart. Apply same pagination to By Technology and By Server. ~1-2 hrs if pagination remains. | -- | Stuart + Claude Code |
| 54 | UX | Technology Health KPI cards — reframe to applications | "Needs Profiling" card counts apps ✅. At Risk / Extended Support / Mainstream cards — confirm if reframed from tag counts to app counts. ~1 hr if remaining. | -- | Stuart + Claude Code |

---

## MEDIUM — Security & Compliance

| # | Category | Item | Why MED | Blocked By | Assigned |
|---|----------|------|---------|------------|----------|
| 1 | Architecture | Identity/Security rewrite v1.1 > v2.0 | SSO deferred to Q2. SOC2 CC6.1 evidence gap remains but not Q1 blocker. | -- | Stuart |
| 6 | Database | Audit log workspace index | workspace_id column exists but no index — filter will table-scan | -- | Stuart |
| 7 | Database | users.is_super_admin design debt | Duplicates platform_admins — security logic split across two sources | -- | Stuart |
| 9 | SOC2 Policy | Acceptable Use Policy (internal/SOC2) | Required for SOC2 — for internal team (Stuart, Delta). ~1 hr. Target: before first enterprise deal. | -- | Delta (GPD-531, due Feb 27) |
| 10 | SOC2 Policy | Data Classification Policy | Required for SOC2 — Public/Internal/Confidential/Restricted. ~1 hr. Target: before first enterprise deal. | -- | Delta (GPD-532, due Mar 6) |
| 11 | SOC2 Policy | Business Continuity Plan | Required for SOC2 — DR procedures, communication plan. ~2 hrs. Target: before first enterprise deal. | -- | Delta (GPD-533, due Mar 6) |
| 12 | SOC2 | Backup restore test | A1.2 gap — never tested restore from pg_dump. ~2 hrs. Target: before first enterprise deal. | -- | Stuart |
| 14 | SOC2 | Uptime monitoring setup | CC7.2 gap — no monitoring beyond Supabase/Netlify defaults. ~1 hr. | -- | Stuart |
| 15 | SOC2 | auth.audit_log_entries empty (0 rows) | CC6.6 gap — Supabase auth audit log not populating. Investigate. | -- | Stuart |
| 16 | Enablement | Delta training on Namespace UI | Delta must be independent for Garland import. ~2 hrs walkthrough. | -- | Stuart + Delta |
| 17 | Marketing | Website update | Professional credibility. AG/Claude Code task. ~1 day. | -- | Stuart + Claude Code |
| 18 | Analytics | Power BI Foundation — deploy 14 views | 14 vw_pbi_* views exist but not deployed. First dashboard build. | -- | Stuart |
| 37 | Demo | Riverside demo data refresh | Demo namespace needs updated data for sales demos. Tech tagging done (#19 closed). Remaining: hosting_type fill, assessment scores. | -- | Stuart |
| 41 | RBAC | Permission-aware Supabase hooks | Custom hooks (useCanEdit, useCanDelete, useCanCreate) that read user role. Foundation for #40. ~1-2 days. | -- | Stuart |
| 42 | RBAC | Role-gated settings sidebar | Some settings visible to viewers that should be admin-only. ~0.5 day. | #41 | Stuart |
| 43 | RBAC | Assessment permission split — who can assess vs edit app | Currently same permission. Should be separable. Architecture decision needed. ~1-2 days. | #41 | Stuart |
| 44 | RBAC | Flag CREATE viewer exception — flags INSERT policy allows any workspace member | ADR: Flags are governance, not data edits. Viewer can create but not update/delete. Part of gamification Phase 1. | Gamification Phase 1 | Stuart |
| 55 | UX | Filter drawer pattern → push to other dashboards | Extract TechnologyHealth FilterDrawer as reusable component. Apply to: main Dashboard, Portfolios, By Application list, Integration Management. Consistent UX pattern across app. ~1-2 days. | -- | Stuart + Claude Code |

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
| 38 | Documentation | Update security-posture-overview v1.1 > v1.2 | Add CC6.7 Dependabot detail, update stats to 82 tables / 29 triggers / 315 policies, add Feb 18 timeline entry. ~30 min. | -- | Stuart |
| 39 | Documentation | Update soc2-evidence-index v1.1 > v1.2 | Mark Dependabot action done, bump CC6.7 20% > 50%, add `.github/dependabot.yml` as evidence. ~30 min. | -- | Stuart |
| 45 | RBAC | contacts.workspace_role naming — rename read_only to viewer | Cosmetic inconsistency. contacts uses read_only where all other tables use viewer. ~30 min migration. | -- | Stuart |
| 46 | Documentation | Archive RBAC draft + Excel; update identity-security cross-refs | archive (superseded by identity-security/rbac-permissions.md) and archive (superseded by identity-security/rbac-permissions.md) superseded by identity-security/rbac-permissions.md. Update identity-security v1.1 §5 to point to new doc. ~30 min. | -- | Stuart |
| 47 | Tooling | Evaluate Claude Code as primary dev tool | Installed Feb 17. Successfully replaced AG mid-session. Full cutover for Tech Health Dashboard. Test with one more complex build before retiring AG. | -- | Stuart |
| 49 | Database | Drop CHECK constraints on application_integrations | criticality, direction, integration_type, frequency, status, data_format, sensitivity, data_classification columns still have CHECK constraints. Now redundant since values come from reference tables. Low risk — constraints don't hurt, but they block adding new values to reference tables. | -- | Stuart |
| 50 | Database | Lifecycle status cron refresh | current_status is trigger-computed, not auto-refreshing when date boundaries cross. Add weekly cron: `UPDATE technology_lifecycle_reference SET updated_at = now();` or Supabase pg_cron. | -- | Stuart |
| 51 | Feature | Surface Technology Health on Application Detail page | Option C: General tab gets summary badge (worst lifecycle status + tag count line). Deployments tab gets per-DP OS/DB/Web columns with LifecycleBadge. Data from vw_application_infrastructure_report filtered by application_id. ~1-2 days. | -- | Stuart + Claude Code |
| 52 | Feature | Workspace-scoped Technology Health dashboard | Same components as namespace-wide dashboard but filtered to single workspace. Route: `/workspace/:id/technology-health`. Nav link in Workspace section. Workspace column hidden. Complements namespace-wide view in Organization section. ~0.5-1 day. | -- | Stuart + Claude Code |
| 56 | UX | Back arrow fix — TechnologyHealthPage.tsx | Back arrow navigates to home. Should use `navigate(-1)`. One-liner. Confirm if already fixed in Feb 20-21 sessions. | -- | Stuart + Claude Code |

---

## Completed This Session (Feb 20-21)

| Item | Resolution |
|------|------------|
| #34 Technology Health Dashboard implementation | ✅ COMPLETE. All 4 tabs functional. Filter drawer, sticky header, CSV export, donut slice click-through, Needs Profiling KPI, SaaS indicators, auto-expand multi-DP, responsive donut grid. Deployed to production (commit 8a6e80a). |

---

## PENDING VALIDATION

| Item | What to Confirm |
|------|-----------------|
| #53 Pagination | Was 10/25/50/100/All pagination selector implemented? Grouped table with expandable DPs is confirmed done. |
| #54 KPI reframe | Were At Risk / Extended Support / Mainstream cards reframed from tag counts to application counts? Needs Profiling counts apps ✅. |
| #56 Back arrow | Was this fixed during Feb 20-21 Claude Code sessions? |

---

## Summary

| Priority | Count | Theme |
|----------|-------|-------|
| **HIGH** | 7 | 3 SOC2 policies + IT Value Creation + RBAC UI gating + grouped table + KPI reframe |
| **MEDIUM** | 19 | Identity rewrite, compliance, Delta enablement, demo data, website, RBAC enforcement, filter drawer pattern |
| **LOW** | 14 | Doc cleanup, OAuth cosmetic, polish, security doc updates, RBAC naming, cron job, back arrow |
| **Pending Validation** | 3 | #53 pagination, #54 KPI reframe, #56 back arrow |
| **Total Open** | 40 | -1 from prior count (#34 closed, #55 + #56 added) |

### SOC2 Policy Scorecard

| Policy | Priority | Jira | Status | Effort |
|--------|----------|------|--------|--------|
| Information Security Policy | HIGH | GPD-528 (Feb 27) | Assigned to Delta | 2-3 hrs |
| Change Management Policy | HIGH | GPD-529 (Feb 27) | Assigned to Delta | 1-2 hrs |
| Incident Response Plan | HIGH | GPD-530 (Feb 27) | Assigned to Delta | 2-3 hrs |
| Acceptable Use Policy (internal) | MED | GPD-531 (Feb 27) | Assigned to Delta | 1 hr |
| Data Classification Policy | MED | GPD-532 (Mar 6) | Assigned to Delta | 1 hr |
| Business Continuity Plan | MED | GPD-533 (Mar 6) | Assigned to Delta | 2 hrs |
| Vendor Management Policy | LOW | GPD-534 (Mar 27) | Assigned to Delta | 1 hr |
| Data Retention Policy | LOW | GPD-535 (Mar 27) | Assigned to Delta | 30 min |
| **Total** | | | **0 of 8 complete** | **~12-15 hrs** |

### OAuth Scorecard

| Provider | Status | Notes |
|----------|--------|-------|
| Google | ✅ Verified & Live | Published to production, branding verified, no user warnings |
| Microsoft | ⚠️ Working (cosmetic warning) | OAuth functional for all users. Publisher verification rejected, docs resubmitted Feb 13. |

---

*Document: planning/open-items-priority-matrix.md*
*Replaces: February 18, 2026 version*
