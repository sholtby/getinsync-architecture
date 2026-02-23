# CHANGELOG.md
GetInSync NextGen Architecture Change Log

Last updated: 2026-02-14

---

## Purpose

This document tracks significant architectural decisions, schema changes, and feature additions to GetInSync NextGen. Each entry includes the rationale, implementation details, and impact.

**Note:** For current document versions and status, see **gis-architecture-manifest** (latest version).

---

## Recent Changes (2026-02-01 to present)

### Gamification & Data Governance Architecture (Feb 14, 2026)

**Trigger:** Need for user engagement, data quality governance, and re-engagement mechanisms. Audit_logs infrastructure (17+ triggers, 4 categories) identified as pre-built event source for achievement computation — three products from one table: SOC2 compliance, gamification, and activity feed.

**New document created:**

| Document | Version | Description |
|----------|---------|-------------|
| features/gamification/architecture.md | v1.2 | Complete gamification architecture: achievements, data quality flags, activity feed, email digest, re-engagement |

**Schema changes designed (not yet implemented):**

| Table | Change | Purpose |
|-------|--------|---------|
| *(new)* gamification_achievements | Namespace-scoped achievement definitions | Rules engine for what actions earn points/badges |
| *(new)* gamification_user_progress | Per-user per-achievement state | Track progress toward thresholds |
| *(new)* gamification_user_stats | Denormalized per-user summary | Dashboard reads, includes opt-out controls and streak tracking |
| *(new)* flags | Data quality flags with polymorphic entity reference | Contextual governance observations with assignment and resolution lifecycle |
| namespaces | +`enable_achievement_digests` (boolean, default true) | Master switch for all gamification emails in a namespace |
| *(new view)* flag_summary_by_workspace | Aggregate flag metrics per workspace | Namespace admin reporting, customer success metrics |

**Functions designed:**

| Function | Purpose |
|----------|---------|
| check_achievements() | Main engine RPC — reads audit_logs, updates progress, awards badges |
| count_qualifying_events() | Audit_log query builder with JSONB condition matching |
| refresh_user_stats() | Recompute denormalized stats rollup |
| update_streak() | Login streak computation (called on dashboard load) |
| get_gamification_level() | Pure function mapping points to level (1-10) |
| tier_meets_minimum() | Check if namespace tier meets achievement minimum |
| generate_activity_feed() | Personalized "what's new" feed with time-bucketed aggregation |
| assign_flag_default() | Auto-assign flags to entity business/technical owner from contact roles |
| compute_flag_resolution_hours() | Auto-compute resolution time on flag state transitions |

**Architectural decisions:**

1. **Audit-log-driven event sourcing.** Achievements computed from existing audit_logs — no new instrumentation on business tables. Zero write overhead on user actions. Enables retroactive achievement computation.

2. **Silent computation.** Achievement engine runs regardless of user opt-out. Progress rows always current for re-engagement emails and instant opt-back-in.

3. **Three-level opt-out.** Namespace master switch (email only) → User gamification UI toggle → User email digest toggle. Each level independent. Flag assignments always visible regardless of gamification opt-out (governance, not gamification).

4. **Flags, not comments.** Four-state lifecycle (open → acknowledged → resolved/dismissed). One table, no threading. Smart defaults via contact role lookup. Resolution time tracked but no SLAs imposed — GRC territory per existing ADR.

5. **Activity feed as engagement hub.** "What happened while you were away" generated on demand (not materialized). Time bucketing adapts to absence duration: day/week/month. RLS-native via workspace_users join.

6. **Resend email integration.** Weekly achievement digest + re-engagement emails for dormant users (14-day threshold, 30-day cooldown). Signed-token unsubscribe. CASL/CAN-SPAM compliant.

**Tier alignment:**

| Tier | Gamification | Flags | Feed |
|------|-------------|-------|------|
| Free | Onboarding achievements | View only | Own workspace |
| Pro | Data quality achievements | Full lifecycle | Multi-workspace |
| Enterprise | Collaboration achievements, leaderboard | Cross-workspace, admin reporting | Full namespace |
| Full | Mastery achievements | Analytics, category trends | Everything + super admin |

**Implementation planned:** 7 phases from foundation to advanced features. Phase 1 targets Knowledge 2026 demo readiness (2-3 days).

---

### Infrastructure Boundary & Lifecycle Intelligence Update (Feb 14, 2026)

**Trigger:** City of Garland import prep raised the question: should we import 637 server records? Required a crisp boundary rubric for what infrastructure data belongs in APM vs CMDB. Also identified that the Technology Lifecycle Intelligence architecture (v1.0) predated the two-path model and needed updating.

**New documents created:**

| Document | Version | Description |
|----------|---------|-------------|
| features/technology-health/infrastructure-boundary-rubric.md | v1.0 | What infrastructure data belongs in GetInSync vs CMDB. Decision tree, worked examples, server_name governance. Companion to business application identification rubric. |

**Documents updated:**

| Document | Change | Description |
|----------|--------|-------------|
| gis-technology-lifecycle-intelligence-architecture | v1.0 --> v1.1 | Two-path model integration. Path 1 technology product entry point, technology tagging flow, Path 1 + unified lifecycle risk views, T02 suggestion table. +2 hrs implementation estimate. |

**Architectural decisions:**

1. **Staleness Principle (new).** "If the data changes faster than a portfolio review cycle (quarterly), it doesn't belong in APM." This is the litmus test for all infrastructure data inclusion decisions.

2. **server_name RETAINED (correction from Feb 13).** The Feb 13 session initially recommended dropping server_name from deployment_profiles. The Infrastructure Boundary Rubric reverses this: `server_name` is retained as an optional text reference label for on-prem/long-lived servers. It is NOT a managed entity, NOT a foreign key, and NOT required. Condition: only populate for servers that will exist in 2+ years.

3. **Lifecycle Intelligence now covers Path 1.** The v1.0 architecture only connected lifecycle data through IT Services (Path 2). v1.1 adds: technology_products.lifecycle_reference_id FK, technology tagging flow (SS6.1), Path 1 lifecycle risk view (vw_technology_tag_lifecycle_risk), unified combined risk view (vw_dp_lifecycle_risk_combined), T02 score suggestion logic.

4. **Four-document pipeline confirmed.** Infrastructure Boundary Rubric (what enters) --> Lifecycle Intelligence (enriches with dates) --> Risk Boundary Decision (computes indicators) --> IT Value Creation Findings (actionable observations). Each document now cross-references the others.

**Schema changes designed (additions to existing pending):**

| Table | Change | Purpose | Correction |
|-------|--------|---------|------------|
| deployment_profiles | ADD `server_name` (text, optional) | Reference label for on-prem servers | **Corrects Feb 13 decision to DROP** |
| technology_products | ADD `lifecycle_reference_id` (UUID FK) | Path 1 entry point for lifecycle intelligence | New in Lifecycle Intelligence v1.1 |

**New database views designed (Lifecycle Intelligence v1.1):**

| View | Purpose |
|------|---------|
| vw_technology_tag_lifecycle_risk | Path 1: technology products tagged on DPs with lifecycle risk level |
| vw_dp_lifecycle_risk_combined | Unified: worst lifecycle risk across both Path 1 and Path 2 for each DP |

---

### Technology Health Dashboard Architecture (Feb 13, 2026)

**Trigger:** Customer (Government of Saskatchewan) built Power BI dashboard from 8 ServiceNow CMDB spreadsheet extracts to track OS/DB/Web lifecycle across 479 applications. Identified as replicable product feature.

**New documents created:**

| Document | Version | Description |
|----------|---------|-------------|
| features/technology-health/dashboard.md | v1.0 | Complete dashboard spec: field mapping, schema changes, database views, UI wireframes |
| features/technology-health/technology-stack-erd-addendum.md | v1.1 | Two-path model: Path 1 (inventory tags on DP) + Path 2 (IT Service cost/blast radius) |
| features/cost-budget/cost-model-addendum.md | v2.5.1 | Confirms zero cost model impact from technology tagging changes |
| features/technology-health/risk-boundary.md | v1.0 | ADR: Risk registers are GRC territory; GetInSync provides computed risk indicators |
| gis-marketing-explainer-v1_6-additions.md | v1.6 | New sections 9 (Technology Health) and 10 (Risk Boundary), updated buyer personas |

**Schema changes designed (not yet implemented):**

| Table | Change | Purpose |
|-------|--------|---------|
| applications | Add `is_crown_jewel` (boolean) | Flag critical apps for Technology Health dashboard |
| applications | Add `management_classification` (apm/alm/other) | Distinguish APM-managed vs ALM-managed apps |
| applications | Add `csdm_stage` (stage_0 through stage_4) | Track CSDM maturity per application |
| applications | Add `branch` (text) | Ministry/division filter for government customers |
| deployment_profiles | ~~DROP `server_name`~~ **CORRECTED Feb 14: ADD `server_name` (optional text)** | Reference label for on-prem servers per Infrastructure Boundary Rubric v1.0 |
| technology_products | Add `product_family` (text) | Group versions (e.g., "Windows Server", "Oracle Database") |
| deployment_profile_technology_products | Add `edition` (text) | Track Enterprise/Standard/Express per junction |
| technology_lifecycle_entries | Add `maintenance_type` (enum) | mandatory/regular_high/regular_low per vendor lifecycle model |

**Database views designed:**

| View | Purpose |
|------|---------|
| vw_technology_health_summary | Aggregate counts by technology layer, lifecycle status, risk level |
| vw_application_infrastructure_report | Flat report: one row per app with OS/DB/Web columns |
| vw_server_technology_report | Server-centric view (optional, if server_name retained on DP) |

**Architectural decisions:**

1. **Two-path technology model:** Path 1 = direct inventory tags on deployment_profile_technology_products (NO cost columns). Path 2 = IT Service cost/blast radius as maturity layer. Reconciliation view bridges the gap. Zero impact on cost model v2.5.

2. **Risk management boundary (ADR):** Risk registers are GRC territory. GetInSync surfaces computed risk indicators from technology lifecycle data. Does NOT build risk acceptance workflow, TRA tracking, or document management. "We detect the risks. GRC tools manage the response."

3. **Server names RETAINED (corrected Feb 14).** Originally dropped from deployment_profiles. Infrastructure Boundary Rubric v1.0 reverses this: `server_name` retained as optional text reference label for on-prem/long-lived servers. Not a managed entity. See rubric for decision tree and worked examples.

4. **Crown Jewel flag on applications (not DPs):** Business criticality is an organizational decision, not a deployment characteristic. Same application = same Crown Jewel designation regardless of how many DPs it has.

**Economic buyer personas identified:**

| Persona | Trigger | Budget Source |
|---------|---------|---------------|
| ServiceNow Platform Owner / CSDM Program Lead | Empty cmdb_ci_business_app blocking APM | ServiceNow program budget |
| CIO / ADM of IT | Can't answer Treasury Board / Auditor General queries | Modernization initiative |
| CISO / Director of Cyber Security | Can't quantify EOL exposure | Security budget |

**The crawl-to-walk positioning:** GetInSync fills the gap between ServiceNow Discovery (finds cmdb_ci_appl) and ServiceNow APM (needs cmdb_ci_business_app). Discovery finds SQL Server on a server. It can't add business context: what program it supports, who depends on it, what it costs, whether it's a Crown Jewel. GetInSync is the curation layer where cmdb_ci_appl becomes cmdb_ci_business_app.

**ServiceNow Knowledge 2026 pitch:** "Your ServiceNow partner needs business application data on day one. We're how it gets there."

---

## Pending Changes

| Document | Planned Change | Target Date | Status |
|----------|---------------|-------------|--------|
| Gamification Architecture | Phase 1: Deploy 4 tables, 9 functions, toast, dashboard widget | Q1 2026 | Designed — awaiting implementation |
| Gamification Architecture | Phase 2: Achievement wall + flags UI | Q1 2026 | Designed — awaiting implementation |
| Gamification Architecture | Phase 3: Activity feed + leaderboard | Q1 2026 | Designed — awaiting implementation |
| Gamification Architecture | Phase 4-5: Resend email digest + re-engagement | Q2 2026 | Designed — awaiting implementation |
| Gamification Architecture | Phase 6-7: Flag reporting + advanced achievements | Q2 2026 | Designed — awaiting implementation |
| Technology Health Dashboard | Schema implementation (~5 hours) | Q1 2026 | Designed ‗ awaiting implementation |
| Technology Health Dashboard | Three database views (~2 hours) | Q1 2026 | Designed ‗ awaiting implementation |
| Technology Health Dashboard | UI page (AG, 3-4 days) | Q1 2026 | Designed ‗ awaiting implementation |
| Technology catalog seeding | Populate lifecycle data for common products (~2 hours) | Q1 2026 | Designed ‗ awaiting implementation |
| CSV import | Bulk application import for 400+ app portfolios | Q1 2026 | Priority increased ‗ required for large customers |
| gis-quicksight-reporting-architecture | Add cross-reference to NextGen doc | TBD | Backlog |
| Database views | Implement vwQS_ApplicationScores, TIME, PAID | Q1 2026 | In Progress |
| gis-involved-party-architecture | Add is_customer boolean flag | TBD | Backlog |
| gis-reference-tables-design-debt | Implement reference tables for dropdown values | Q1 2026 | Backlog |
| gis-application-wizard | 5-step guided creation workflow | Q1 2026 | Planned (Phase 26) |
| gis-composite-application-architecture | Implementation (designed, not implemented) | TBD | Awaiting customer validation |
| gis-technology-lifecycle-intelligence | v1.1 architecture complete (two-path model). Implementation pending. | Q2 2026 | AS-DESIGNED (v1.1 Feb 14) |

---

## Review Schedule

| Review Type | Frequency | Next Review |
|-------------|-----------|-------------|
| Architecture Board | Monthly | 2026-02-28 |
| Security Review | Quarterly | 2026-03-01 |
| Compliance Audit | Annual | 2026-06-01 |
| Manifest Update | As needed | After major milestones |

---

## Architecture Change Archive

*For detailed change entries from previous periods:*

### Recent History (2026)
- **2026-02-01 to 2026-02-12:** See **archive/superseded/architecture-changelog-v1_7.md**
  - Phase 25.9: RLS completion (72 tables, all GRANT+RLS)
  - Manifest v1.18 → v1.20 version corrections
  - Session-end checklist v1.2
  - Operational statuses reference table
  - Open items priority matrix established

- **2026-01-15 to 2026-01-31:** See **CHANGELOG.md**
  - Phase 25: IT Service Budgets
  - Phase 25.1: Data Centers & Standard Regions
  - Cost Summary UI Enhancements
  - Namespace Boundary Enforcement
  - Composite Applications Architecture (designed)
  - Budget Management Architecture

### Earlier History (2025)
- **2025-12-01 to 2026-01-29:** See **gis-architecture-changelog-v1_5.md**
  - Cost Analysis UI & Assessment Configuration
  - Riverside Demo Namespace Architecture
  - Budget Alerts Architecture
  - Test Data & Operational Documentation
  - Organizations Boolean Role Flags
  - Analytics & Regional Architecture Updates

- **2025-12-12 to 2025-12-21:** See **gis-architecture-changelog-v1_2.md** through **v1_4.md**
  - Initial architecture corrections (10 inconsistencies resolved)
  - Architecture Decision Records (ADRs)
  - Federated Catalog model
  - Namespace/Workspace scoping rules
  - NextGen multi-region architecture
  - QuickSight integration

---

## Document Version History

For current document versions, architecture principles, technology stack, and schema statistics, see:

**→ gis-architecture-manifest-v1_22.md** (or latest version)

The manifest provides:
- Complete document version matrix (70+ documents)
- Architecture principles and golden rules
- Technology stack details
- Current schema statistics
- Implementation roadmap
- Document conventions

---

## Change Log Maintenance

### When to Update This Document

**Add new entry** when:
- New architecture document created
- Significant document version update (major/minor)
- Schema changes affecting multiple tables
- New architectural patterns introduced
- Major bug fixes with architectural implications

**Update Pending Changes** when:
- New work items identified
- Status changes (Backlog → Planned → In Progress → Complete)
- Target dates change
- Items are completed (move to Recent Changes, remove from Pending)

**Update Review Schedule** when:
- Governance cadence changes
- Review dates are rescheduled
- New review types added

### Versioning Strategy

**Create new changelog version** when:
- Approximately 3 months of changes accumulated
- File exceeds ~500 lines
- Major milestone reached (e.g., Phase 30, production launch)

**Archive older versions** when:
- Versions are 2+ years old
- Moving to /archive/changelogs/ directory
- Consolidating into annual archives (e.g., gis-architecture-changelog-2024-2025.md)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.9 | 2026-02-14 | **Two parallel sessions.** (1) Gamification & Data Governance architecture (features/gamification/architecture.md). Audit-log-driven achievements, data quality flags, activity feed, Resend email. 4 new tables, 9 functions, 1 view. Principle 11: Audit-Log-Driven Event Sourcing. (2) Infrastructure Boundary Rubric v1.0 (new doc). Lifecycle Intelligence v1.0-->v1.1 (two-path model, 2 new views, Path 1 entry point). server_name correction: RETAINED as optional ref (reverses Feb 13 DROP decision). Staleness Principle established. |
| v1.8 | 2026-02-13 | Technology Health Dashboard architecture (5 new documents). Two-path technology model. Risk management boundary ADR. Economic buyer personas. Crawl-to-walk positioning. Schema changes designed (8 table modifications, 3 views). Updated Pending Changes with implementation tasks. |
| v1.7 | 2026-01-31 | Restructured to hybrid reference-based approach. Preserved Pending Changes and Review Schedule. Added clear references to v1.6, v1.5, and earlier versions. Added maintenance guidelines. |
| v1.6 | 2026-01-31 | Phase 25 (IT Service budgets), Phase 25.1 (data centers), Cost Summary enhancements, namespace boundary enforcement |
| v1.5 | 2026-01-29 | Cost Analysis UI, Riverside demo, budget alerts, test data documentation |
| v1.2-v1.4 | 2025-12 to 2026-01 | Earlier cumulative versions with complete history |

---

*Document: CHANGELOG.md*  
*Last Updated: February 14, 2026*  
*Next Update: As architectural changes occur*
