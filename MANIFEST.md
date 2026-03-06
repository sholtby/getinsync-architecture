# MANIFEST.md
GetInSync NextGen Architecture Manifest
Last updated: 2026-03-05 (v1.41)

---

## Purpose

This manifest serves as the master index of all architecture documents for GetInSync NextGen. Use this to navigate the architecture documentation and understand the current state of the system.

### Document Status Convention

Every document is tagged with its relationship to the production system:

| Tag | Meaning |
|-----|---------|
| 🟢 AS-BUILT | Accurately describes production |
| 🟡 AS-DESIGNED | Architecture approved, not yet implemented |
| 🟠 NEEDS UPDATE | Concept valid, contains stale stack references |
| ☪ REFERENCE | Stack-agnostic methodology or reference material |

---

## Document Sources — Two Environments

Architecture docs are maintained in a **git repo** (`~/getinsync-architecture`). This is the single source of truth — version history is tracked by git, not by filename suffixes.

Stuart keeps a subset of key files synced to the **Claude Opus project** for context. These are the 9 project files Opus can read:

| Opus Project Filename | Grab From (~/getinsync-architecture/) | Purpose |
|----------------------|----------------------------------------|---------|
| `MANIFEST.md` | `MANIFEST.md` | This file — document index |
| `CLAUDE.md` | `CLAUDE.md` | Claude Code rules (auto-read) |
| `development-rules.md` | `operations/development-rules.md` | Dev workflow rules |
| `session-end-checklist.md` | `operations/session-end-checklist.md` | Session-end validation |
| `open-items-priority-matrix.md` | `planning/open-items-priority-matrix.md` | Living backlog |
| `nextgen-schema-current.sql` | `schema/nextgen-schema-current.sql` | Latest schema reference |
| `session-summary-current.md` | `sessions/2026-02-23-complete.md` | Latest session context |
| `it-value-creation-v2.jsx` | `features/roadmap/mockup-v2.jsx` | Active UI mockup |
| `Q1-2026-Gantt-v2.xlsx` | `planning/q1-2026-gantt-v2.xlsx` | Project timeline |

**Retired filenames** (do not reference these):
- `gis-architecture-manifest-v1_25.md` → now `MANIFEST.md`
- `getinsync-development-rules-v1_4.md` → now `development-rules.md`
- `gis-session-end-checklist-v1_3.md` / `v1_4` → now `session-end-checklist.md`
- `gis-open-items-priority-matrix.md` → now `open-items-priority-matrix.md`
- `getinsync-nextgen-schema-2026-02-22.sql` → now `nextgen-schema-current.sql`
- `session-summary-2026-02-22-complete.md` → now `session-summary-current.md`

**Rules:**
- The **repo** is always authoritative. If a project file conflicts with the repo, the repo wins.
- Stuart syncs project files manually after Claude Code sessions.
- Version history is tracked by git. Project filenames do not carry version numbers or dates.
- The full document library (86 docs) lives in the repo. Opus sees only the 9 files above.

---

## Technology Stack

| Component | Technology | Region |
|-----------|-----------|--------|
| Frontend | React + TypeScript + Vite + Tailwind | N/A |
| Backend | Supabase (PostgreSQL 17.6) | ca-central-1 |
| Auth | Supabase Auth (email/password + OAuth) | ca-central-1 |
| Storage | Supabase Storage | ca-central-1 |
| Hosting | Netlify (production + dev) | Global CDN |
| Version Control | GitHub (sholtby/getinsync-nextgen-ag) | N/A |
| UI Development | Claude Code (v2.1.44) — replaced AG Feb 17 | N/A |
| UI Development (fallback) | Antigravity (bolt.new) | N/A |
| Architecture | Claude (Opus 4.5) | N/A |

### What We Don't Use (Deprecated Feb 8, 2026)
- ~~AWS Elastic Beanstalk~~ → Netlify
- ~~Amazon RDS SQL Server~~ → Supabase PostgreSQL
- ~~Amazon QuickSight~~ → Frontend React charts
- ~~Approximated.app~~ → Netlify custom domains
- ~~Entra ID / Azure AD~~ → Supabase Auth
- ~~.NET Core~~ → React + TypeScript
- ~~Amazon Bedrock~~ → Claude API (direct)

---

## Core Architecture Documents

### Core Data Model

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| core/core-architecture.md | v2.5 | 🟡 | Core architecture — ProductContract merged into IT Service, two cost channels (updated Mar 4) |
| core/conceptual-erd.md | v2.0 | 🟡 | Conceptual ERD — ProductContract replaced by ITServiceSoftwareProduct junction (updated Mar 4) |
| core/composite-application.md | v1.1 | 🟡 | Composite applications (Supabase-native) |
| core/composite-application-erd.md | v1.0 | 🟡 | Composite application ERD |
| core/deployment-profile.md | v1.8 | 🟢 | DP-centric assessment, clone/move, naming |
| core/workspace-group.md | v1.6 | 🟢 | Workspace groups — stack-agnostic, no AWS refs found |
| features/technology-health/technology-stack-erd.md | v1.0 | 🟢 | CSDM-aligned ERD — SP, TP, IT Services parallel to DPs |
| features/technology-health/technology-stack-erd-addendum.md | v1.1 | 🟢 | **Two-path model: inventory tags vs IT Service cost/blast radius — DEPLOYED** |
| catalogs/application-reference-model.md | v2.0 | ☪ | Reference model methodology |
| catalogs/application-reference-model-erd.md | v2.0 | ☪ | Reference model ERD |

### Catalogs & Classification

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| catalogs/software-product.md | v3.0 | 🟡 | Software Product Catalog — now inventory-only, ProductContract merged into IT Service (updated Mar 4) |
| catalogs/it-service.md | v2.0 | 🟡 | IT Services — shared infrastructure + software contracts. Contract lifecycle fields, `it_service_software_products` junction (updated Mar 4) |
| catalogs/business-application.md | v1.2 | 🟢 | Business Application entity — IdP refs generalized (Entra as example, not only) |
| catalogs/business-application-identification.md | v1.0 | ☪ | Criteria for business apps vs tech services |
| catalogs/csdm-application-attributes.md | v1.0 | ☪ | CSDM mandatory fields alignment |
| catalogs/technology-catalog.md | v1.0 | 🟢 | Technology product catalog structure |
| catalogs/business-capability.md | v1.0 | 🟡 | Business Capabilities (Phase 1, build) + Business Services (Phase 2, design only). Seed taxonomy: 13 generic + 12 government L1s. |

### Cost & Budget Management

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/cost-budget/cost-model.md | v3.0 | 🟡 | Cost flow — two channels (IT Services + Cost Bundles), Software Products inventory-only, ProductContract merged into IT Service (updated Mar 4) |
| features/cost-budget/cost-model-addendum.md | v2.5.1 | 🟢 | **Confirms zero cost model impact from Path 1 technology tagging — DEPLOYED** |
| features/cost-budget/budget-management.md | v1.5 | 🟡 | Application and workspace budgets — software costs flow through IT Service allocations (updated Mar 4) |
| features/cost-budget/budget-alerts.md | v1.0 | 🟢 | Budget health monitoring — Phase 1 DB layer DEPLOYED |
| features/cost-budget/vendor-cost.md | v2.0 | 🟡 | Vendor attribution — two channels (IT Services + Cost Bundles), dpsp vendor DEPRECATED (updated Mar 4) |
| features/cost-budget/software-contract.md | v2.0 | 🟡 | Software contracts — contracts live on IT Services, dpsp cost columns DEPRECATED (updated Mar 4) |
| features/cost-budget/cost-model-validation-2026-03-04.md | — | 🟢 | **Cost model validation report — schema debt, view bugs, frontend audit, refactoring plan** |
| features/cost-budget/cost-model-primer.md (.docx) | v3.0 | 🟢 | **Cost model primer — end-to-end guide: 2 channels, Quick Calculator, Contract Expiry Widget, IT Service→Software Product linking, data flow, maturity levels (rewritten Mar 5)** |
| features/cost-budget/adr-cost-model-reunification.md | v1.0 | ☪ | **ADR: IT Services absorb contract role. Software Products become inventory. Reverses v2.5 fork. Schema changes, migration path, budget impact analysis.** |

### Identity, Security & Access

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| identity-security/identity-security.md | v1.2 | 🟢 | Identity, auth, RBAC, Steward role, SOC 2 controls, data residency — cleaned Feb 23 |
| identity-security/rls-policy.md | v2.3 | 🟢 | RLS policies — 92 tables, 357 policies. Header stats updated Mar 4 (detail catalog covers Phase 25.9 tables) |
| identity-security/rls-policy-addendum.md | v2.4 | 🟢 | RLS v2.4 addendum — updated patterns for new table checklist |
| identity-security/rbac-permissions.md | v1.0 | 🟢 | RBAC permission matrix — role-action mapping for all entities |
| core/involved-party.md | v1.9 | 🟢 | Contacts, organizations — tier names + role names corrected (updated Feb 23) |
| planning/super-admin-provisioning.md | v0.2 | 🟢 | Platform admin namespace provisioning |
| identity-security/user-registration.md | v1.0 | 🟢 | Signup and invitation flows |

### Security & Operations

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| identity-security/security-posture-overview.md | v1.3 | 🟡 | Security posture overview — stats stale (92→93 tables, 357→361 RLS, 50→51 triggers, 31→32 views) |
| identity-security/security-validation-runbook.md | v1.1 | 🟠 | ~~Security validation~~ — DEPRECATED, superseded by session-end-checklist §2.1 + §6d. Retained for INC-001 history. |
| operations/database-change-validation.md | v1.1 | 🟢 | Deep database validation (CHECK constraints, roles, FKs, namespaces). Section 1 superseded by session-end-checklist §2.1. |
| operations/new-table-checklist.md | v1.0 | 🟢 | New table creation checklist (GRANT/RLS/triggers) |
| identity-security/soc2-evidence-collection.md | v1.2 | 🟢 | SOC2 monthly evidence collection — 50 triggers, 92 tables (updated Mar 4) |
| identity-security/soc2-evidence-index.md | v1.3 | 🟡 | SOC2 evidence index — stats stale (92→93 tables, 357→361 RLS, 50→51 triggers) |
| operations/session-end-checklist.md | **v1.11** | 🟢 | **Master session-end compliance checklist — v1.11: §2.1 unified bulk safety net (6 checks), Section 4 removed, Section 3 narrowed** |

### Testing

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| testing/pgtap-rls-coverage.sql | v1.5 | 🟢 | pgTAP security regression — 425 assertions: RLS, GRANTs (93 tables + 30 views), audit triggers (51), view security, sentinel checks |
| testing/security-posture-validation.sql | v1.3 | 🟢 | Standalone security validation — PASS/FAIL output for all 92 tables + 29 views (incl. view GRANTs) |

### Integration & Alignment

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/integrations/servicenow-alignment.md | v1.2 | 🟢 | CSDM mapping, sync strategy — stack-agnostic, no AWS refs found |
| features/integrations/architecture.md | v1.2 | ☪ | External integrations (stack-agnostic) |
| features/integrations/itsm-api-research.md | **v1.0** | 🟡 | **ITSM API research — ServiceNow + HaloITSM publish/subscribe patterns. Phase 37 scoping.** |

### Visualization

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| core/visual-diagram.md | v1.0 | 🟢 | Three-level walkable Visual tab (App → DP → Blast Radius) |

### Technology Health & Risk

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/technology-health/dashboard.md | v1.0 | 🟢 | **Technology Health dashboard — DEPLOYED Feb 21. Filter drawer, CSV export, SaaS indicators, Needs Profiling.** |
| features/technology-health/risk-boundary.md | v1.0 | ☪ | **ADR: Risk registers = GRC territory. GetInSync = computed risk indicators.** |
| features/technology-health/infrastructure-boundary-rubric.md | v1.0 | ☪ | **What infrastructure data belongs in APM vs CMDB. Decision tree, staleness principle, server_name governance.** |

### Roadmap

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/roadmap/architecture.md | **v1.3** | 🟢 | **Roadmap — DEPLOYED. 8 tables, 4 views, seed data. Self-organizing scoping, Gantt/Kanban/Grid UI spec. Supersedes v1.0–v1.2.** |

### Gamification & Data Governance

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/gamification/architecture.md | v1.2 | 🟡 | **Achievements, data quality flags, activity feed, email digest, re-engagement. Audit-log-driven.** |

### Multi-Region & Infrastructure

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| planning/work-package-multi-region.md | v1.0 | 🟢 | **Supabase multi-region** — region column implemented Feb 8 |
| planning/work-package-privacy-oauth.md | v1.0 | 🟢 | Privacy Policy + OAuth work package |
| core/namespace-management-ui.md | v1.0 | 🟢 | Phase 25.10 namespace management UI |
| core/namespace-workspace-ui.md | v1.0 | ☪ | Namespace/Workspace UI patterns |
| features/realtime-subscriptions/realtime-subscriptions-architecture.md | v1.0 | 🟡 | **Supabase Realtime** — Postgres Changes, Presence, Broadcast. 6 use cases (P1–P6), 3 React hooks. P1 ships with Roadmap Kanban. |
| infrastructure/edge-functions-layer-architecture.md | v1.0 | 🟡 | **Edge Functions layer** — Deno runtime, 8 consumers, 6 functions. Secret mgmt, two-client auth, MCP inline tools. E1+E2 ship with AI Chat MVP. |

### Global Search

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/global-search/architecture.md | v1.0 | 🟡 | **Global search — Ctrl+K overlay, 12 entity types, categorized results, cascading to AI chat. Prerequisite for AI chat UX.** |

### AI & Technology Intelligence (Future)

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/technology-health/lifecycle-intelligence.md | v1.1 | 🟢 | **AI-powered EOL tracking — DEPLOYED. Two-path model, Path 1 entry point, unified risk views** |
| features/ai-chat/mvp.md | MVP | 🟢 | Natural language APM queries — Supabase-native |
| features/ai-chat/v2.md | v2 | 🟢 | AI chat v2 |
| features/ai-chat/v3-multicloud.md | v3 | 🟡 | Multi-cloud AI chat (designed, mixed refs) |

### Cloud Discovery (Future — Phase 27)

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| features/cloud-discovery/architecture.md | v1.0 | 🟡 | Cloud resource discovery — AWS/Azure/GCP (mixed refs, needs cleanup when built) |

### Business & Product

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| marketing/pricing-model.md | v1.0 | ☪ | Tier structure, licensing |
| marketing/executive-presentation.md | v1.0 | ☪ | Executive presentation |
| planning/q1-2026-master-plan.md | v1.4 → **v2.0** | 🟢 | Q1 2026 strategic roadmap — **v2.0 xlsx replaces markdown** |
| marketing/explainer.md | v1.7.1 | ☪ | **Product explainer — merged v1.5 base + v1.7 additions. Tenancy, identity, licensing, cost, CSDM, technology health, risk boundary, data governance, buyer personas** |
| marketing/positioning-statements.md | v1.0 | ☪ | Positioning statements |
| marketing/product-roadmap-2026.md | v1.0 | ☪ | 2026 product roadmap |
| gis-phase-work-plan-23-25.md | v1.0 | ☪ | Historical work plan |

### Development Workflow

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| operations/development-rules.md | **v1.5** | 🟢 | **Development rules — added §2.3 pgTAP regression suite (391 assertions), explicit GRANTs on all 90 tables** |
| operations/team-workflow.md | v2.0 | 🟢 | Team workflow — Stuart + Claude Code two-role model, dual-repo commits, impact analysis (rewritten Feb 23) |
| operations/screen-building-guidelines.md | v1.1 | 🟢 | **Screen-building guidelines — page layout zones, AppHeader common element, typography, buttons, KPI cards, tables, forms, spacing, icons, colors** |
| CLAUDE.md | v1.0 | 🟢 | **Claude Code auto-read rules file — architecture rules, impact analysis, do-not list, DB access** |

### Demo & Testing

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| schema/demo-namespace-template.sql | v2.0 | 🟢 | Demo data SQL script |
| operations/demo-namespace-checklist.md | v2.0 | 🟢 | Demo setup checklist |
| operations/demo-credentials.md | v1.1 | 🟢 | Demo environment credentials |
| test-data-load-green-fields-v2.txt | v2.0 | ☪ | Green field test data |

### Change Management

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| CHANGELOG.md | v1.9 | 🟢 | Architecture change log (current) |
| **THIS FILE: MANIFEST.md** | **v1.36** | 🟢 | **Architecture manifest — v1.36: Cost Model Reunification Phase 0 (9 docs updated)** |

---

## 🗴 Deprecated Documents (Removed Feb 8, 2026)

The following documents were removed during the architecture audit. They described legacy AWS infrastructure (Elastic Beanstalk, RDS SQL Server, QuickSight, Approximated.app) that has been replaced by the Supabase + Netlify stack.

| Document | Replaced By |
|----------|-------------|
| gis-approximated-api-routing-architecture-v1_2.md | Netlify custom domains |
| gis-next-gen-multi-region-paas-architecture-v1_4.md | planning/work-package-multi-region.md |
| gis-quicksight-reporting-architecture-v1_1.md | Frontend React charts |
| archive (superseded — frontend React charts) | Frontend React charts |
| identity-security/rls-policy.md | identity-security/rls-policy.md |
| gis-architecture-changelog-v1_2.md through v1_6.md | archive/superseded/architecture-changelog-v1_7.md |
| getinsync-development-rules-v1_3.md | operations/development-rules.md |
| features/roadmap/architecture.md | features/roadmap/architecture.md |
| archive/superseded/it-value-creation-v1_1.md | features/roadmap/architecture.md |
| features/roadmap/architecture.md | features/roadmap/architecture.md |

---

## Schema Statistics (as of 2026-03-05)

| Category | Count |
|----------|-------|
| **Tables** | 93 |
| **Views** | 32 |
| **Functions (RPCs)** | 55 |
| **RLS Policies** | 361 |
| **Audit Triggers** | 51 |
| **Explicit GRANTs** | 93 tables × 2 roles (authenticated + service_role) |
| **Schema backup** | schema/nextgen-schema-current.sql (PENDING) |
| **Standard Regions** | 37 |
| **Demo Namespaces** | 2 (Gov of Alberta Test, City of Riverside) |
| **Production Namespaces** | 17 (all region = 'ca') |

### Pending Schema Changes (Designed, Not Deployed)

| Target Table | Change | Source Document |
|-------------|--------|-----------------|
| *(new table)* | gamification_achievements | Gamification Architecture v1.2 |
| *(new table)* | gamification_user_progress | Gamification Architecture v1.2 |
| *(new table)* | gamification_user_stats | Gamification Architecture v1.2 |
| *(new table)* | flags | Gamification Architecture v1.2 |
| namespaces | +`enable_achievement_digests` (boolean) | Gamification Architecture v1.2 |
| it_services | +`contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days` | ADR: Cost Model Reunification |
| *(new table)* | it_service_software_products | ADR: Cost Model Reunification |
| *(new view)* | vw_it_service_contract_expiry | ADR: Cost Model Reunification |
| *(new view)* | flag_summary_by_workspace | Gamification Architecture v1.2 |
| *(new functions x9)* | check_achievements, generate_activity_feed, etc. | Gamification Architecture v1.2 |

**Deployed since v1.24 (removed from pending):**
- ✅ applications: management_classification, csdm_stage, branch — deployed Feb 18
- ✅ deployment_profiles: server_name — deployed Feb 18
- ✅ technology_products: lifecycle_reference_id — deployed Feb 18
- ✅ dp_technology_products: edition — deployed Feb 18
- ✅ vw_technology_health_summary, vw_application_infrastructure_report, vw_server_technology_report, vw_technology_tag_lifecycle_risk — deployed Feb 18–21
- ✅ findings, initiatives, initiative_deployment_profiles, initiative_it_services — deployed Feb 22 (Phase 21 v1.1)
- ✅ ideas, programs, program_initiatives, initiative_dependencies — deployed Feb 22 (Phase 21 v1.2)
- ✅ vw_finding_summary, vw_initiative_summary, vw_idea_summary, vw_program_summary — deployed Feb 22

---

## Architecture Principles

### 1. Namespace = Hard Boundary
- Nothing crosses namespace boundaries except platform admin operations
- RLS enforces isolation at database level
- Each namespace is a separate legal entity
- Multi-namespace access via `namespace_users` table

### 2. CSDM-Aligned from Day One
- Map directly to ServiceNow tables
- No migration needed when syncing
- Business Application vs Application Service pattern

### 3. DP-Centric Assessment
- Deployment Profile is the assessment anchor, not Application
- Same app can have different technical scores in different deployments

### 4. Cost Attribution (Updated Mar 4, 2026)
- Every dollar needs a home and an owner
- Two cost channels: IT Services, Cost Bundles. Software Products are inventory-only (no cost).
- No cost fields on Application or Deployment Profile directly

### 5. Progressive Disclosure
- Tier-based feature gating (trial/essentials/plus/enterprise)
- Features unlock at higher tiers
- Upgrade teasers show value

### 6. Data Residency
- Region column on namespaces (ca/us/eu)
- Canada live, US/EU on-demand when first customer requires
- Multi-region = separate Supabase projects per region

### 7. Granular Security
- 4-policy pattern: Separate SELECT, INSERT, UPDATE, DELETE policies
- Platform admin override across all namespaces
- Namespace admin multi-tenant support
- Workspace-level roles: admin/editor/steward/viewer/restricted

### 8. As-Designed ≠ As-Built
- Every document must declare its status (🟢/🟡/🟠/☪)
- "Last validated against production" date required
- Architecture docs that reference deprecated tech are a liability, not documentation

### 9. Two-Path Technology Model (Feb 13, 2026)
- **Path 1:** Direct inventory tags on deployment profiles (NO cost columns) — simple, all tiers
- **Path 2:** IT Service cost/blast radius as maturity layer — structured, Enterprise tier
- Technology tagging is inventory; cost flows through established channels only
- Reconciliation view bridges the gap between paths

### 10. Risk Boundary — APM vs GRC (Feb 13, 2026)
- GetInSync surfaces **computed risk indicators** from technology lifecycle data
- Risk registers, TRA tracking, and risk acceptance workflows are **GRC territory**
- "We detect the risks. GRC tools manage the response."
- Server hostnames, IPs, vulnerability counts are **CMDB/Discovery territory**

### 11. Audit-Log-Driven Event Sourcing (Feb 14, 2026)
- Single `audit_logs` table serves three purposes: SOC2 compliance, gamification achievements, activity feed
- No new instrumentation on business tables — achievements computed from existing audit data
- Silent computation: engine runs regardless of user opt-out, enabling instant opt-back-in
- Same pattern extensible to future features (anomaly detection, usage analytics)

### 12. View-to-TypeScript Contract Enforcement (Feb 17, 2026)
- `src/types/view-contracts.ts` is single source of truth for view-to-TypeScript mappings
- When a database view changes, update the contract file; TypeScript catches all consumers
- Prevents silent mismatches where UI reads undefined columns (budget view class of bug)

### 13. Self-Organizing Dashboard Scoping (Feb 22, 2026)
- Programs visible to workspace users via initiative membership — no manual WorkspaceGroup tagging required
- Full program context always shown (total budget, all initiatives) — never sliced by workspace filter
- NULL workspace_id = namespace-wide scope for findings and programs
- WorkspaceGroups remain for catalog sharing (publisher/consumer) only — not overloaded for entity visibility

### 14. Realtime Capability Separation (Mar 4, 2026)
- Postgres Changes (data sync), Presence (who's online), and Broadcast (cross-session messaging) are three distinct capabilities sharing one WebSocket connection
- Subscribe only to tables where multiple users modify data concurrently; reporting dashboards use refetch-on-focus instead
- Tenant-scoped channel naming: `namespace:{id}:table:{name}` pattern prevents cross-tenant data leakage

### 15. Edge Functions as Shared Infrastructure (Mar 4, 2026)
- Server-side execution is a shared infrastructure layer, not per-feature — all functions share `_shared/` utilities (auth, CORS, error handling, audit)
- Secrets via Edge Function Secrets (function-scoped) or Vault (database/customer-scoped)
- Two-client auth pattern: user JWT for user-context calls, service role for background/system operations
- First consumer: AI Chat (E1+E2)

---

## Roadmap

### ✔ Phase 25.8: Super Admin Provisioning (COMPLETE — Feb 3, 2026)
### ✔ Phase 25.9: Multi-Namespace RLS Migration (COMPLETE — Feb 6-7, 2026)
### ✔ Phase 25.10: Namespace Management UI (COMPLETE — Feb 7-8, 2026)
- 3 views, 6 RPCs, 2 trigger fixes
- Region column added to namespaces
- AG built frontend with health pins, filters, tabs

### ✔ Phase 28: Integration UI Bugs (COMPLETE — Feb 17, 2026)
- All 13 bugs closed
- 8 reference tables, dropdowns DB-driven

### ✔ Technology Health Dashboard (COMPLETE — Feb 18-21, 2026)
- 4 views, lifecycle seed data (76 rows, 16 vendors)
- Filter drawer, CSV export, SaaS indicators, Needs Profiling
- Riverside demo: 12 tech products, 52 tags across 20 DPs

### ✔ Roadmap Phase 21 (COMPLETE — Feb 22, 2026)
- v1.1: findings, initiatives, 2 junction tables, 2 views
- v1.2: ideas, programs, program_initiatives, initiative_dependencies, 2 views
- 8 tables, 32 RLS policies, 8 audit triggers, 4 views total
- Riverside seed: 8 findings, 6 initiatives, 6 ideas, 2 programs, 6 assignments, 4 dependencies
- Architecture v1.3: self-organizing scoping, Gantt/Kanban/Grid UI spec

### 🟢 Q1 2026 Remaining (Feb–Mar 2026)
1. **Roadmap Frontend** — Claude Code build against v1.3 spec (next)
2. **Polish Pass** — Week 7-8 per Q1 plan
3. SSO Implementation — deferred Q2 (identity-security rewrite needed)
4. **Gamification & Data Governance** — designed Feb 14, Phase 1 targets early Q2

### 🔵 Phase 27: Cloud Discovery (Designed — Future)
### 🔵 Phase 37: ServiceNow ITSM Integration (Designed — 15-20 days, Phase 37a-e)
### 🟡 Gamification & Data Governance (Designed — Feb 14, 7 phases planned)

---

## Recent Changes (v1.25 → v1.26)

### Automated Testing & Explicit GRANTs (Feb 23, 2026)

**Database changes (no schema, GRANTs only):**
- Explicit `GRANT SELECT, INSERT, UPDATE, DELETE` applied to all 90 tables for both `authenticated` and `service_role` roles
- Previously relied on implicit schema-level default privileges — now explicit and auditable per SOC2 requirements
- Baseline validated: 297/297 checks PASS (90 RLS + 90 auth GRANTs + 90 service_role GRANTs + 37 audit triggers + 27 security_invoker views)

**New documents (2):**
- `testing/pgtap-rls-coverage.sql` — **NEW (🟢).** Full pgTAP regression suite: 391 assertions covering RLS, GRANTs, audit triggers, view security, sentinel checks for drift detection.
- `testing/security-posture-validation.sql` — **NEW (🟢).** Standalone validator requiring no extensions. Paste into Supabase SQL Editor, produces PASS/FAIL table with failures sorted to top.

**Document updates (3):**
- `operations/development-rules.md` — **v1.4 → v1.5.** Added §2.3 (pgTAP security regression suite). Updated §3.1 schema filename to stable name. Updated §4.3 to include pgTAP in session-end compliance pass. Added pgTAP row to Quick Reference table.
- `operations/session-end-checklist.md` — **v1.4 → v1.5.** Added §6d automated security regression step (pgTAP or standalone).
- `MANIFEST.md` — **v1.25 → v1.26.** New "Testing" section. Updated dev-rules + checklist entries. Updated document count.

**New manifest section:** "Testing" added between "Security & Operations" and "Integration & Alignment".

**Schema statistics:** No table/view/function changes. Explicit GRANTs row added to stats table.

**Document count:** 84 → 86 (+2 test files).

---

## Previous Changes (v1.24 → v1.25)

### IT Value Creation Deployed + Technology Health Deployed (Feb 18–22, 2026)

**Two major features shipped to production:**

**1. Technology Health Dashboard (Feb 18–21):**
- Schema: `technology_lifecycle_reference`, `vendor_lifecycle_sources` tables + 76 lifecycle rows + 16 vendors
- Column additions: `applications` (+3), `deployment_profiles` (+1), `technology_products` (+1), `dp_technology_products` (+2)
- 4 new views: vw_technology_tag_lifecycle_risk, vw_technology_health_summary, vw_application_infrastructure_report, vw_server_technology_report
- `compute_lifecycle_status()` function + trigger (status trigger-computed, not generated column)
- Riverside demo: 12 tech products, 52 deployment tags across 20 DPs
- UI: Filter drawer, CSV export, SaaS indicators, Needs Profiling intelligence — all deployed via Claude Code
- Status change: 🟡 → 🟢 AS-BUILT

**2. IT Value Creation Phase 21 (Feb 22):**
- v1.1 deployment: `findings` (11 cols), `initiatives` (30 cols), `initiative_deployment_profiles`, `initiative_it_services`
- v1.2 deployment: `ideas` (12 cols), `programs` (17 cols), `program_initiatives`, `initiative_dependencies`
- 4 reporting views: vw_finding_summary, vw_initiative_summary, vw_idea_summary, vw_program_summary
- All 8 tables with full security posture (4 RLS each, GRANTs, audit triggers)
- Architecture v1.3 produced: self-organizing dashboard scoping, Gantt/Kanban/Grid view modes, KPI bar spec
- Riverside seed data: 8 findings, 6 initiatives, 6 ideas, 2 programs, 6 assignments, 4 dependencies
- IT Value Creation section created in manifest (extracted from AI & Technology Intelligence)
- v1.0, v1.1, v1.2 architecture docs archived → superseded by v1.3

**Document changes:**
- `features/roadmap/architecture.md` — **NEW (🟢).** Complete spec: 8 tables, 4 views, scoping model, UI spec. Supersedes v1.0–v1.2.
- `features/integrations/itsm-api-research.md` — **NEW (🟡).** ServiceNow + HaloITSM API patterns for Phase 37.
- `operations/session-end-checklist.md` → `v1_3.md` — **UPDATED.** Added Claude Code .env password reminder.
- `features/technology-health/dashboard.md` — **🟡 → 🟢.** Deployed.
- `features/technology-health/lifecycle-intelligence.md` — **🟡 → 🟢.** Lifecycle data deployed.
- `features/technology-health/technology-stack-erd-addendum.md` — **🟡 → 🟢.** Two-path model deployed.
- `features/cost-budget/cost-model-addendum.md` — **🟡 → 🟢.** Confirmed by deployment.
- `identity-security/rls-policy.md` — **🟢 → 🟠.** Now stale: documents 307 policies, production has 347.
- `identity-security/soc2-evidence-index.md` — **🟢 → 🟠.** Stats stale (307→347 policies, 25→37 triggers).

**New architecture principle:**
- Principle 13: Self-Organizing Dashboard Scoping — programs visible via initiative membership, full context always shown, no WorkspaceGroup overloading.

**Schema statistics:**
- Tables: 80 → 90 (+8 IT Value Creation, +2 lifecycle reference — deployed across Feb 18-22)
- RLS policies: 307 → 347 (+32 on IT Value Creation tables, +8 on lifecycle tables)
- Audit triggers: 25 → 37 (+8 IT Value Creation, +4 lifecycle/tech)
- Views: 19 → 27 (+4 Tech Health, +4 IT Value Creation)
- Functions: 53 (unchanged — lifecycle status is trigger, not standalone function... actually +1: compute_lifecycle_status)
- Schema backup: 2026-02-17 → 2026-02-22 (PENDING)

**Pending schema cleaned up:** 17 items removed (all deployed). Only Gamification items remain pending.

**Documents archived:** IT Value Creation v1.0, v1.1, v1.2 (superseded by v1.3).

**Document count:** 83 → 85 (+2: IT Value Creation v1.3, ITSM API Research v1.0).

---

## Previous Changes (v1.23 → v1.24)

### Claude Code Cutover & Phase 28 Completion (Feb 17, 2026)

**Tooling change:**
- **Claude Code (v2.1.44) replaces AG (Antigravity/bolt.new) as primary frontend development tool.** AG remains as fallback.
- `CLAUDE.md` created in repo root — auto-read by Claude Code at session start. Contains architecture rules, impact analysis requirements, database access policy, and do-not list.
- `src/types/view-contracts.ts` created — 10 TypeScript interfaces matching every Supabase view the app queries. Single source of truth for view-to-TypeScript mappings.
- `operations/development-rules.md` — rewritten for Claude Code workflow. AG rules moved to fallback section.
- Read-only database access configured for Claude Code (SELECT-only via policy).

**Phase 28 Integration Bugs — ALL 13 CLOSED:**
- 8 reference tables created (criticality_types, integration_direction_types, integration_method_types, integration_frequency_types, integration_status_types, data_format_types, sensitivity_types, data_classification_types)
- All integration dropdowns now DB-driven (dev rule 1.4 compliance)
- Data tags multi-select added to integration modal
- Integration count badges on app list rows
- 9 inline TypeScript types migrated to view-contracts.ts
- Stale NamespaceUser role type fixed (admin|member|viewer → admin|editor|steward|viewer|restricted)

**View fix:**
- `vw_workspace_budget_summary` rewritten to read from `workspace_budgets` table instead of legacy `workspaces.budget_amount` column.

**Schema statistics:**
- Tables: 72 → 80 (+8 integration reference tables)
- Audit triggers: 17 → 25 (+8 on new reference tables)
- RLS policies: 279+ → 307 (+16 on new tables, +12 from prior sessions)
- Schema backup: 2026-02-13 → 2026-02-17

**New architecture principle:**
- Principle 12: View-to-TypeScript Contract Enforcement

**New manifest sections:**
- "Development Workflow" — tracks development rules, team workflow, CLAUDE.md

**Documents marked stale:**
- security-posture-overview v1.1 → 🟠 (stats reference 72 tables/17 triggers, now 80/25)
- soc2-evidence-collection-skill v1.0 → 🟠 (trigger list says 11 tables, now 25)
- team-workflow-skill v1.0 → 🟠 (references AG as primary)

**Document count:** 80 → 83 (+3: development-rules-v1_4, CLAUDE.md, view-contracts.ts as tracked code artifact).

---

## Previous Changes (v1.22 → v1.23)

### Infrastructure Boundary & Lifecycle Intelligence Update (Feb 14, 2026)

**2 document changes:**
- `features/technology-health/infrastructure-boundary-rubric.md` — **NEW.** What infrastructure data belongs in APM vs CMDB. Decision tree, staleness principle, worked examples, server_name governance. Added to "Technology Health & Risk" section.
- `features/technology-health/lifecycle-intelligence.md` — **v1.0 → v1.1.** Two-path model integration: Path 1 technology product entry point, technology tagging flow, 2 new risk views (vw_technology_tag_lifecycle_risk, vw_dp_lifecycle_risk_combined), T02 score suggestion table.

**Pending schema corrections:**
- `deployment_profiles.server_name`: Changed from DROP to ADD (text, optional). Infrastructure Boundary Rubric establishes server_name is retained as conditional reference label for on-prem servers, not dropped.
- `technology_products.lifecycle_reference_id`: Added (UUID FK to technology_lifecycle_reference). Path 1 entry point for lifecycle intelligence.
- 2 new views added to pending: vw_technology_tag_lifecycle_risk, vw_dp_lifecycle_risk_combined.

**Architecture changelog** updated v1.9 to include both parallel sessions' work.

**Document count:** 79 → 80.

---

## Previous Changes (v1.21 → v1.22)

### Gamification & Data Governance Architecture (Feb 14, 2026)

**1 new document created:**
- `features/gamification/architecture.md` — Achievements, data quality flags, activity feed, email digest, re-engagement. Audit-log-driven event sourcing from existing audit_logs infrastructure.

**New manifest section:** "Gamification & Data Governance" added to track gamification architecture.

**Pending schema changes added:** 4 new tables (gamification_achievements, gamification_user_progress, gamification_user_stats, flags), 1 table modification (namespaces +enable_achievement_digests), 1 new view (flag_summary_by_workspace), 9 new functions.

**1 new architecture principle:**
- Principle 11: Audit-Log-Driven Event Sourcing — single audit_logs table serves SOC2, gamification, and activity feed

**Key architectural decisions:**
- Achievement engine reads existing audit_logs — no new instrumentation, zero write overhead
- Silent computation: runs regardless of opt-out for instant re-activation
- Three-level opt-out: namespace master → user gamification UI → user email digest
- Data quality flags use polymorphic entity reference (same pattern as audit_logs)
- Flags separate from risk management per existing ADR — governance, not GRC
- Activity feed generated on-demand with adaptive time bucketing (not materialized)
- Resend email integration: weekly digest + 14-day dormancy re-engagement with 30-day cooldown

**Marketing explainer** updated v1.6 → v1.7: Data Governance & User Engagement value proposition.

**Architecture changelog** updated v1.8 → v1.9.

---

## Previous Changes (v1.20 → v1.21)

### Technology Health Architecture (Feb 13, 2026)

**5 new documents created:**
- `features/technology-health/dashboard.md` — Dashboard spec: field mapping, schema changes, database views, UI wireframes
- `features/technology-health/technology-stack-erd-addendum.md` — Two-path model: Path 1 (inventory tags, no cost) + Path 2 (IT Service cost/blast radius)
- `features/cost-budget/cost-model-addendum.md` — Confirms zero cost model impact from technology tagging
- `features/technology-health/risk-boundary.md` — ADR: Risk registers = GRC territory; GetInSync = computed risk indicators
- `gis-marketing-explainer-v1_6-additions.md` — New sections 9 (Technology Health), 10 (Risk Boundary), updated buyer personas

**New manifest section:** "Technology Health & Risk" added to track dashboard architecture and risk boundary ADR.

**Pending schema changes section added** — 8 table modifications and 3 new views designed but not deployed.

**2 new architecture principles:**
- Principle 9: Two-Path Technology Model (inventory vs cost/blast radius)
- Principle 10: Risk Boundary — APM vs GRC

**Key architectural decisions:**
- Two-path technology model: simple inventory tags (Path 1) + IT Service maturity layer (Path 2)
- Risk registers are GRC territory; GetInSync provides computed risk indicators only
- Server names/IPs are CMDB/Discovery territory; excluded from deployment profiles
- Crown Jewel flag lives on applications (not deployment profiles)

**Marketing explainer** updated v1.5 → v1.6: Technology Health, Risk Boundary, crawl-to-walk positioning, economic buyer personas (ServiceNow Platform Owner, CIO, CISO).

**Architecture changelog** updated v1.7 → v1.8.

---

## Document Count Summary

| Status | Count |
|--------|-------|
| 🟢 AS-BUILT | 54 |
| 🟡 AS-DESIGNED | 9 |
| 🟠 NEEDS UPDATE | 0 |
| ☪ REFERENCE | 16 |
| 🗴 DEPRECATED (removed) | 14 |
| **Total tracked** | **93** |

---

## Related Resources

### External Documentation
- ServiceNow CSDM 5.0: https://docs.servicenow.com/csdm
- Supabase Docs: https://supabase.com/docs
- PostgreSQL RLS: https://www.postgresql.org/docs/current/ddl-rowsecurity.html

### Internal Resources
- GitHub: https://github.com/sholtby/getinsync-nextgen-ag
- Production: https://nextgen.getinsync.ca
- Dev: https://dev--relaxed-kataifi-57d630.netlify.app

---

## Maintenance

**Document Owner:** Stuart Holtby
**Review Frequency:** Monthly
**Last Review:** 2026-02-28
**Next Review:** 2026-03-15

**Change Process:**
1. Implement feature/change
2. Update relevant architecture document(s)
3. Add entry to changelog
4. Update manifest version and summary
5. Commit to GitHub

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.41 | 2026-03-05 | Session-end checklist v1.13: Added "Next Session Setup" section — handoff documents must include phase-numbered opening message for scannable Claude Code session history. |
| v1.40 | 2026-03-05 | Mid-Session Schema Checkpoint. Added to CLAUDE.md (both repos): lightweight security posture + tsc gate after every DB change. Updated session-end-checklist.md with "do not run mid-session" note. Updated development-rules.md §2.2.1. |
| v1.39 | 2026-03-05 | Git workflow: feature branches for parallel Claude Code windows. Updated CLAUDE.md (both repos), development-rules.md, team-workflow.md, session-end-checklist.md. Deleted operations/CLAUDE.md (stale v24 Feb copy). Branch strategy: feature-branch → dev → main. Architecture repo stays on main. |
| v1.38 | 2026-03-05 | Cost model primer v2.0→v3.0 (full rewrite). Removed all migration/legacy language, rewritten UI sections to match shipped Phase 3 components: Quick Calculator, Contract Expiry Widget, IT Service→Software Product linking, ITServiceDependencyList allocation column. Regenerated .docx. Status 🟡→🟢. |
| v1.37 | 2026-03-04 | ADR: Cost Model Reunification. IT Services absorb contract role; Software Products become pure inventory. Reverses v2.5 fork that created two parallel cost streams. Documents: rationale for original fork (budget management complexity), schema changes needed (4 cols on it_services, new junction it_service_software_products), migration path (5 phases), budget impact (none — IT Service track already handles it). Document count 92→93, REFERENCE 15→16. |
| v1.36 | 2026-03-04 | Realtime + Edge Functions architecture. Added features/realtime-subscriptions/realtime-subscriptions-architecture.md v1.0 🟡 and infrastructure/edge-functions-layer-architecture.md v1.0 🟡. Principles 14–15 added. Cross-refs in roadmap, ai-chat, gamification docs. Document count 90→92, AS-DESIGNED 7→9. |
| v1.35 | 2026-03-04 | Feature rename: "IT Value Creation" → "Roadmap". Updated section heading, file paths (it-value-creation → roadmap), component references, route paths across 10 architecture docs. Lexicon change only — no database or schema changes. |
| v1.34 | 2026-03-04 | Cost model primer v1.0 (.md + .docx). Internal team guide: 3 cost channels, data flow diagram, UI locations, maturity levels, legacy fields, quick reference. Document count 89→90. |
| v1.34 | 2026-03-04 | Stats alignment: 90→92 tables, 347→357 RLS, 48→50 triggers, 54→55 functions. New tables: application_categories, application_category_assignments (Application Categories feature). Updated 4 docs: security-posture-overview v1.2→v1.3, soc2-evidence-collection v1.1→v1.2, soc2-evidence-index v1.2→v1.3. pgTAP + security-posture-validation marked 🟠 (sentinel checks stale). |
| v1.33 | 2026-03-04 | Cost model reconciliation (SOC2 CC2.3). 5 docs updated against schema dump 2026-03-03: cost-model v2.5→v2.6 (legacy columns documented as LEGACY not REMOVED, dpis marked DEPLOYED, cost override formula added), budget-management v1.3→v1.4 (workspace_budgets table reality, thresholds updated to 80/100/110%, as-built views documented), vendor-cost v1.0→v1.1 (vw_run_rate_by_vendor bugs C.1/C.2 documented with corrective SQL), software-contract v1.0→v1.1 (partial deployment documented, missing updated_at/constraint noted). budget-alerts confirmed Phase 1 DEPLOYED. New doc: cost-model-validation-2026-03-04.md (validation report with refactoring plan). software-contract 🟡→🟢. Document count 88→89. |
| v1.32 | 2026-03-04 | AppHeader common element. screen-building-guidelines v1.0→v1.1: §9 updated with AppHeader global header bar for edit/detail pages. New shared component `src/components/shared/AppHeader.tsx` renders logo, search (⌘K), static workspace/portfolio context pills, UserMenu. Applied to ApplicationPage. |
| v1.31 | 2026-03-03 | Validation consolidation. session-end-checklist v1.10→v1.11: §2.1 unified bulk safety net (6 checks: GRANTs, RLS, views, functions), Section 4 removed, Section 3 narrowed. security-validation-runbook 🟢→🟠 DEPRECATED (superseded by §2.1 + §6d). database-change-validation §1 noted as superseded. |
| v1.30 | 2026-03-03 | Audit trigger expansion 37→48. Stats alignment across 6 docs: security-posture-overview, soc2-evidence-collection, soc2-evidence-index, pgTAP regression (397→408 assertions), session-end-checklist v1.9→v1.10 (§2 bulk table security posture validation). |
| v1.29 | 2026-03-03 | Stats alignment: session-end-checklist v1.5→v1.9 in manifest. Schema stats corrected: Views 29→31, Functions 53→54. §9.1 functions query now excludes extension-owned functions. |
| v1.28 | 2026-03-03 | Added 1 document: Screen-Building Guidelines v1.0 (🟢). Defines page layout zones, workspace banner, toolbar, sub-tabs, KPI card variants (A/B), data tables (default 10 rows), typography scale, button hierarchy, icon rules, color system, spacing, empty/loading states. Resolves UX inconsistencies across Overview/App Health/Tech Health/Roadmap pages. Repo path: operations/screen-building-guidelines.md. Document count: 87→88. |
| v1.27 | 2026-02-28 | Added 1 document: Global Search Architecture v1.0 (🟡). New "Global Search" manifest section. Ctrl+K overlay, 12 searchable entity types, categorized results with workspace breadcrumbs, ILIKE→FTS→semantic progressive upgrade path, AI chat integration handoff. Repo path: features/global-search/architecture.md. Document count: 86→87. |
| v1.26 | 2026-02-23 | Automated testing. New "Testing" section (2 files: pgTAP regression + standalone validator). development-rules v1.4→v1.5 (§2.3 pgTAP). session-end-checklist v1.4→v1.5 (§6d regression step). Explicit GRANTs on all 90 tables (authenticated + service_role). Document count: 84→86. |
| v1.25 | 2026-02-22 | Technology Health Dashboard + IT Value Creation Phase 21 both DEPLOYED. Schema: 80→90 tables, 307→347 RLS, 25→37 triggers, 19→27 views. IT Value Creation v1.3 (🟢) — 8 tables, 4 views, self-organizing scoping, Gantt/Kanban/Grid UI. New "IT Value Creation" manifest section. ITSM API Research v1.0 added. Principle 13 (Self-Organizing Scoping). 5 docs 🟡→🟢, 2 docs 🟢→🟠 (stale stats). Pending schema cleaned (17 items deployed). v1.0–v1.2 IT Value archived. Session-end checklist v1.2→v1.3. Document count: 83→85. |
| v1.24 | 2026-02-17 | Claude Code replaces AG as primary UI dev tool. Phase 28 all 13 bugs closed. 8 reference tables (80 tables, 25 triggers, 307 policies). Budget view rewrite. view-contracts.ts + Principle 12. New "Development Workflow" section. 3 docs marked stale. Document count: 80→83. |
| v1.23 | 2026-02-14 | Added Infrastructure Boundary Rubric v1.0 (new doc). Lifecycle Intelligence v1.0→v1.1 (two-path model). server_name correction: ADD not DROP. 2 new pending views. technology_products.lifecycle_reference_id FK added to pending. Document count: 79→80. |
| v1.22 | 2026-02-14 | Added 1 document: Gamification Architecture v1.2. New "Gamification & Data Governance" section. Added Architecture Principle 11 (Audit-Log-Driven Event Sourcing). Pending schema: 4 new tables, 1 modification, 1 view, 9 functions. Updated changelog v1.8 → v1.9, explainer v1.6 → v1.7. Document count: 78 → 79. |
| v1.21 | 2026-02-13 | Added 5 documents: Technology Health Dashboard v1.0, Technology Stack ERD Addendum v1.1, Cost Model Addendum v2.5.1, Risk Management Boundary v1.0, Marketing Explainer v1.6. New "Technology Health & Risk" section. New "Pending Schema Changes" subsection. Added Architecture Principles 9 (Two-Path Technology Model) and 10 (Risk Boundary). Updated changelog v1.7 → v1.8. Document count: 71 → 78. |
| v1.20 | 2026-02-12 | Version corrections: identity-security v1.1, budget-mgmt v1.3, RLS v2.4 addendum, software-contract v1.0. New Security & Operations section (6 docs). Schema stats: 72 tables, 17 triggers, Feb 11 backup. Tab rename: Connections → Integrations. Session-end checklist v1.1 → v1.2. |
| v1.19 | 2026-02-10 | Added visual diagram architecture v1.0, technology stack ERD v1.0. New "Visualization" section. Roadmap updates: Integration Mgmt shipped, Phase 28c in progress, SSO blocked. |
| v1.18 | 2026-02-08 | Architecture audit: deprecated 10 legacy AWS docs, added status tags, Phase 25.10 complete, region column, schema backup |
| v1.17 | 2026-02-07 | Phase 25.9 complete: RLS v2.3, 279 policies |
| v1.16 | 2026-01-31 | Cloud discovery architecture v1.0 |
| v1.15 | 2026-01-31 | Deployment profile v1.8, Phase 25 summary |
| v1.14 | 2026-01-24 | Reference model architecture v2.0 |
| v1.13 | 2026-01-21 | Composite applications, vendor cost |
| v1.12 | 2026-01-16 | Demo template v2.0, budget alerts v1.0 |
| v1.0-v1.11 | 2025-12 to 2026-01 | Earlier versions |

---

*Document: MANIFEST.md*
*February 2026*
