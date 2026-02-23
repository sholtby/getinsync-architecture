# gis-architecture-manifest-v1.24
GetInSync NextGen Architecture Manifest
Last updated: 2026-02-17

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
| gis-core-architecture-v2_4.md | v2.4 | 🟠 | Core architecture (14 AWS refs, Supabase-aligned) |
| gis-nextgen-conceptual-erd-v1_2.md | v1.2 | 🟠 | Conceptual ERD (Supabase-aligned, 8 AWS refs) |
| gis-composite-application-architecture-v1_1.md | v1.1 | 🟡 | Composite applications (Supabase-native) |
| gis-composite-application-erd.md | v1.0 | 🟡 | Composite application ERD |
| gis-deployment-profile-architecture-v1_8.md | v1.8 | 🟢 | DP-centric assessment, clone/move, naming |
| gis-workspace-group-architecture-v1_6.md | v1.6 | 🟠 | Workspace groups (3 AWS refs) |
| gis-technology-stack-erd-corrected-v1_0.md | v1.0 | 🟢 | CSDM-aligned ERD — SP, TP, IT Services parallel to DPs |
| gis-technology-stack-erd-addendum-v1_1.md | v1.1 | 🟡 | **Two-path model: inventory tags vs IT Service cost/blast radius** |
| gis-application-reference-model-architecture-v2_0.md | v2.0 | ☪ | Reference model methodology |
| gis-application-reference-model-erd-v2_0.md | v2.0 | ☪ | Reference model ERD |

### Catalogs & Classification

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-software-product-architecture-v2_1.md | v2.1 | 🟠 | Software Product Catalog (10 AWS refs, tables built) |
| gis-it-service-architecture-v1_3.md | v1.3 | 🟠 | IT Services — shared infrastructure (13 AWS refs, tables built) |
| gis-business-application-architecture-v1_2.md | v1.2 | 🟠 | Business Application entity (4 AWS refs) |
| gis-business-application-identification-v1_0.md | v1.0 | ☪ | Criteria for business apps vs tech services |
| gis-csdm-application-attributes-v1_0.md | v1.0 | ☪ | CSDM mandatory fields alignment |
| gis-technology-catalog-architecture-v1_0.md | v1.0 | 🟢 | Technology product catalog structure |

### Cost & Budget Management

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-cost-model-architecture-v2_5.md | v2.5 | 🟠 | Cost flow, allocation, TBM-lite (2 AWS refs) |
| gis-cost-model-addendum-v2_5_1.md | v2.5.1 | 🟡 | **Confirms zero cost model impact from Path 1 technology tagging** |
| gis-budget-management-architecture-v1_3.md | v1.3 | 🟠 | Application and workspace budgets (8 AWS refs, tables built) |
| gis-budget-alerts-architecture-v1_0.md | v1.0 | 🟢 | Budget health monitoring |
| gis-vendor-cost-architecture-v1_0.md | v1.0 | 🟢 | Vendor management, contracts |
| gis-software-contract-architecture-v1_0.md | v1.0 | 🟡 | Software contract lifecycle management |

### Identity, Security & Access

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-identity-security-architecture-v1_1.md | v1.1 | 🟠 | **MAJOR REWRITE NEEDED** — Entra ID/QuickSight refs throughout. RBAC concepts valid, implementation wrong. |
| gis-rls-policy-architecture-v2_3.md | v2.3 | 🟢 | Complete RLS policies — 307 policies, 80 tables, platform admin bypass |
| gis-rls-policy-architecture-v2_4-addendum.md | v2.4 | 🟢 | RLS v2.4 addendum — updated patterns for new table checklist |
| gis-rbac-permission-architecture-v1_0.md | v1.0 | 🟢 | RBAC permission matrix — role-action mapping for all entities |
| gis-involved-party-architecture-v1_9.md | v1.9 | 🟠 | Contacts, organizations (10 AWS refs, tables built) |
| gis-super-admin-provisioning-v0_2.md | v0.2 | 🟢 | Platform admin namespace provisioning |
| gis-user-registration-invitation-architecture-v1_0.md | v1.0 | 🟢 | Signup and invitation flows |

### Security & Operations

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-security-posture-automated-overview-v1_1.md | v1.1 | 🟠 | Security posture overview for prospects/sales — **stats stale (72→80 tables, 17→25 triggers)** |
| gis-security-validation-runbook-v1_0.md | v1.0 | 🟢 | Operational SQL queries for security validation |
| gis-database-change-validation-skill-v1_0.md | v1.0 | 🟢 | Session-end database validation skill |
| gis-new-table-checklist-v1_0.md | v1.0 | 🟢 | New table creation checklist (GRANT/RLS/triggers) |
| gis-soc2-evidence-collection-skill.md | v1.0 | 🟠 | SOC2 monthly evidence collection — **trigger list stale (11→25 tables), stats stale** |
| gis-soc2-evidence-index-v1_1.md | v1.1 | 🟢 | SOC2 evidence index — trust criteria → evidence mapping |
| gis-session-end-checklist-v1_2.md | v1.2 | 🟢 | Master session-end compliance checklist |

### Integration & Alignment

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-servicenow-alignment-v1_2.md | v1.2 | 🟠 | CSDM mapping, sync strategy (9 AWS refs, core mapping valid) |
| gis-integrations-architecture-v1_2.md | v1.2 | ☪ | External integrations (stack-agnostic) |

### Visualization

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-visual-diagram-architecture-v1_0.md | v1.0 | 🟢 | Three-level walkable Visual tab (App → DP → Blast Radius) |

### Technology Health & Risk

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-technology-health-dashboard-architecture-v1_0.md | v1.0 | 🟡 | **Technology Health dashboard: field mapping, schema, views, UI spec** |
| gis-risk-management-boundary-decision-v1_0.md | v1.0 | ☪ | **ADR: Risk registers = GRC territory. GetInSync = computed risk indicators.** |
| gis-infrastructure-boundary-rubric-v1_0.md | v1.0 | ☪ | **What infrastructure data belongs in APM vs CMDB. Decision tree, staleness principle, server_name governance.** |

### Gamification & Data Governance

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-gamification-architecture-v1_2.md | v1.2 | 🟡 | **Achievements, data quality flags, activity feed, email digest, re-engagement. Audit-log-driven.** |

### Multi-Region & Infrastructure

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-work-package-multi-region-v1_0.md | v1.0 | 🟢 | **Supabase multi-region** — region column implemented Feb 8 |
| gis-work-package-privacy-oauth-v1_0.md | v1.0 | 🟢 | Privacy Policy + OAuth work package |
| gis-namespace-management-ui-v1_0.md | v1.0 | 🟢 | Phase 25.10 namespace management UI |
| gis-namespace-workspace-ui-architecture-v1_0.md | v1.0 | ☪ | Namespace/Workspace UI patterns |

### AI & Technology Intelligence (Future)

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-technology-lifecycle-intelligence-architecture-v1_1.md | v1.1 | 🟡 | AI-powered EOL tracking via Claude API. **v1.1: Two-path model integration, Path 1 entry point, unified risk views** |
| gis-apm-AI-chat-mvp.md | MVP | 🟢 | Natural language APM queries — Supabase-native |
| gis-apm-AI-chat-v2.md | v2 | 🟢 | AI chat v2 |
| gis-apm-AI-chat-v3-multicloud.md | v3 | 🟡 | Multi-cloud AI chat (designed, mixed refs) |
| gis-it-value-creation-architecture-v1_0.md | v1.0 | 🟡 | IT Value Creation module (Q1 Week 5-6) |

### Cloud Discovery (Future — Phase 27)

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-cloud-discovery-architecture-v1_0.md | v1.0 | 🟡 | Cloud resource discovery — AWS/Azure/GCP (mixed refs, needs cleanup when built) |

### Business & Product

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-pricing-model-v1_0.md | v1.0 | ☪ | Tier structure, licensing |
| gis-nextgen-presentation-v1_0.md | v1.0 | ☪ | Executive presentation |
| gis-q1-2026-master-plan-v1_4.md | v1.4 → **v2.0** | 🟢 | Q1 2026 strategic roadmap — **v2.0 xlsx replaces markdown** |
| gis-marketing-explainer-v1_5.md | v1.5 → **v1.7** | ☪ | **Product explainer — Technology Health, Risk Boundary, buyer personas, Data Governance** |
| gis-marketing-positioning-statements-v1_0.md | v1.0 | ☪ | Positioning statements |
| gis-marketing-product-roadmap-2026.md | v1.0 | ☪ | 2026 product roadmap |
| gis-phase-work-plan-23-25.md | v1.0 | ☪ | Historical work plan |

### Development Workflow

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| getinsync-development-rules-v1_4.md | **v1.4** | 🟢 | **Development rules — Claude Code as primary, AG as fallback. Impact analysis, view contracts, clean compile.** |
| getinsync-team-workflow-skill.md | v1.0 | 🟠 | Team workflow — **references AG as primary, needs update for Claude Code** |
| CLAUDE.md | v1.0 | 🟢 | **Claude Code auto-read rules file — architecture rules, impact analysis, do-not list, DB access** |

### Demo & Testing

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-demo-namespace-template-v2_0.sql | v2.0 | 🟢 | Demo data SQL script |
| gis-demo-namespace-checklist-v2.md | v2.0 | 🟢 | Demo setup checklist |
| gis-demo-credentials-v1_1.md | v1.1 | 🟢 | Demo environment credentials |
| test-data-load-green-fields-v2.txt | v2.0 | ☪ | Green field test data |

### Change Management

| Document | Version | Status | Description |
|----------|---------|--------|-------------|
| gis-architecture-changelog-v1_9.md | v1.9 | 🟢 | Architecture change log (current) |
| **THIS FILE: gis-architecture-manifest-v1.24.md** | **v1.24** | 🟢 | **Architecture manifest** |

---

## 🗴 Deprecated Documents (Removed Feb 8, 2026)

The following documents were removed during the architecture audit. They described legacy AWS infrastructure (Elastic Beanstalk, RDS SQL Server, QuickSight, Approximated.app) that has been replaced by the Supabase + Netlify stack.

| Document | Replaced By |
|----------|-------------|
| gis-approximated-api-routing-architecture-v1_2.md | Netlify custom domains |
| gis-next-gen-multi-region-paas-architecture-v1_4.md | gis-work-package-multi-region-v1_0.md |
| gis-quicksight-reporting-architecture-v1_1.md | Frontend React charts |
| gis-quicksight-nextgen-architecture-v1_0.md | Frontend React charts |
| gis-rls-policy-architecture-v2_2.md | gis-rls-policy-architecture-v2_3.md |
| gis-architecture-changelog-v1_2.md through v1_6.md | gis-architecture-changelog-v1_7.md |
| getinsync-development-rules-v1_3.md | getinsync-development-rules-v1_4.md |

---

## Schema Statistics (as of 2026-02-17)

| Category | Count |
|----------|-------|
| **Tables** | 80 |
| **Views** | 19 |
| **Functions (RPCs)** | 85+ |
| **RLS Policies** | 307 |
| **Audit Triggers** | 25 |
| **Schema backup** | getinsync-nextgen-schema-2026-02-17.sql |
| **Standard Regions** | 37 |
| **Demo Namespaces** | 2 (Gov of Alberta Test, City of Riverside) |
| **Production Namespaces** | 17 (all region = 'ca') |

### Pending Schema Changes (Designed, Not Deployed)

| Target Table | Change | Source Document |
|-------------|--------|-----------------|
| applications | +`is_crown_jewel` (boolean) | Technology Health Dashboard v1.0 |
| applications | +`management_classification` (apm/alm/other) | Technology Health Dashboard v1.0 |
| applications | +`csdm_stage` (stage_0 through stage_4) | Technology Health Dashboard v1.0 |
| applications | +`branch` (text) | Technology Health Dashboard v1.0 |
| deployment_profiles | ADD `server_name` (text, optional) | Infrastructure Boundary Rubric v1.0 (corrects Feb 13 DROP decision) |
| technology_products | +`product_family` (text) | Technology Stack ERD Addendum v1.1 |
| technology_products | +`lifecycle_reference_id` (UUID FK) | Lifecycle Intelligence v1.1 (Path 1 entry point) |
| dp_technology_products | +`edition` (text) | Technology Stack ERD Addendum v1.1 |
| technology_lifecycle_entries | +`maintenance_type` (enum) | Technology Health Dashboard v1.0 |
| *(new views)* | vw_technology_health_summary | Technology Health Dashboard v1.0 |
| *(new views)* | vw_application_infrastructure_report | Technology Health Dashboard v1.0 |
| *(new views)* | vw_server_technology_report | Technology Health Dashboard v1.0 |
| *(new views)* | vw_technology_tag_lifecycle_risk | Lifecycle Intelligence v1.1 (Path 1) |
| *(new views)* | vw_dp_lifecycle_risk_combined | Lifecycle Intelligence v1.1 (unified) |
| *(new table)* | gamification_achievements | Gamification Architecture v1.2 |
| *(new table)* | gamification_user_progress | Gamification Architecture v1.2 |
| *(new table)* | gamification_user_stats | Gamification Architecture v1.2 |
| *(new table)* | flags | Gamification Architecture v1.2 |
| namespaces | +`enable_achievement_digests` (boolean) | Gamification Architecture v1.2 |
| *(new view)* | flag_summary_by_workspace | Gamification Architecture v1.2 |
| *(new functions x9)* | check_achievements, generate_activity_feed, etc. | Gamification Architecture v1.2 |

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

### 4. Cost Attribution
- Every dollar needs a home and an owner
- Three cost channels: Software Products, IT Services, Cost Bundles
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

---

## Roadmap

### ✓ Phase 25.8: Super Admin Provisioning (COMPLETE — Feb 3, 2026)
### ✓ Phase 25.9: Multi-Namespace RLS Migration (COMPLETE — Feb 6-7, 2026)
### ✓ Phase 25.10: Namespace Management UI (COMPLETE — Feb 7-8, 2026)
- 3 views, 6 RPCs, 2 trigger fixes
- Region column added to namespaces
- AG built frontend with health pins, filters, tabs

### 🟢 Q1 2026 Strategic Features (Feb-Mar 2026)
1. Integration Management (Week 2) ✓ SHIPPED EARLY
2. **Phase 28: Integration UI Bugs (Week 3) ✓ ALL 13 BUGS CLOSED Feb 17**
3. Phase 28c: Visual Tab — Level 1 complete, Level 2 in progress
4. **Technology Health Dashboard (Week 4-5)**
5. **IT Value Creation (Week 5-6)**
6. SSO Implementation (blocked — identity-security rewrite needed, deferred Q2)
7. Multi-region deployment capability (infrastructure ready)
8. **Gamification & Data Governance (designed Feb 14 — Phase 1 targets early Q2)**

### 🔵 Phase 27: Cloud Discovery (Designed — Future)
### 🔵 Phase 28+: Composite Applications, Advanced Reporting, ServiceNow Sync
### 🟢 Phase 28c: Visual Tab (IN PROGRESS — Level 1 complete, Level 2 WIP)
### 🟡 Phase 38: Technology Lifecycle Intelligence (Designed — prerequisite for dashboard)
### 🟡 Gamification & Data Governance (Designed — Feb 14, 7 phases planned)

---

## Recent Changes (v1.23 → v1.24)

### Claude Code Cutover & Phase 28 Completion (Feb 17, 2026)

**Tooling change:**
- **Claude Code (v2.1.44) replaces AG (Antigravity/bolt.new) as primary frontend development tool.** AG remains as fallback.
- `CLAUDE.md` created in repo root — auto-read by Claude Code at session start. Contains architecture rules, impact analysis requirements, database access policy, and do-not list.
- `src/types/view-contracts.ts` created — 10 TypeScript interfaces matching every Supabase view the app queries. Single source of truth for view-to-TypeScript mappings.
- `getinsync-development-rules-v1_4.md` — rewritten for Claude Code workflow. AG rules moved to fallback section.
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
- `gis-infrastructure-boundary-rubric-v1_0.md` — **NEW.** What infrastructure data belongs in APM vs CMDB. Decision tree, staleness principle, worked examples, server_name governance. Added to "Technology Health & Risk" section.
- `gis-technology-lifecycle-intelligence-architecture-v1_1.md` — **v1.0 → v1.1.** Two-path model integration: Path 1 technology product entry point, technology tagging flow, 2 new risk views (vw_technology_tag_lifecycle_risk, vw_dp_lifecycle_risk_combined), T02 score suggestion table.

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
- `gis-gamification-architecture-v1_2.md` — Achievements, data quality flags, activity feed, email digest, re-engagement. Audit-log-driven event sourcing from existing audit_logs infrastructure.

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
- `gis-technology-health-dashboard-architecture-v1_0.md` — Dashboard spec: field mapping, schema changes, database views, UI wireframes
- `gis-technology-stack-erd-addendum-v1_1.md` — Two-path model: Path 1 (inventory tags, no cost) + Path 2 (IT Service cost/blast radius)
- `gis-cost-model-addendum-v2_5_1.md` — Confirms zero cost model impact from technology tagging
- `gis-risk-management-boundary-decision-v1_0.md` — ADR: Risk registers = GRC territory; GetInSync = computed risk indicators
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
| 🟢 AS-BUILT | 31 |
| 🟡 AS-DESIGNED | 11 |
| 🟠 NEEDS UPDATE | 14 |
| ☪ REFERENCE | 17 |
| 🗴 DEPRECATED (removed) | 11 |
| **Total tracked** | **83** |

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
**Last Review:** 2026-02-17
**Next Review:** 2026-03-10

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

*Document: gis-architecture-manifest-v1.24.md*
*February 2026*
