# Architecture Reconciliation Report
## AS-DESIGNED vs AS-BUILT — Full Audit
**Date:** 2026-03-30
**Author:** Stuart Holtby / Claude
**Schema snapshot:** 101 tables, 40 views, 388 RLS policies, 59 audit triggers

---

## Methodology

Cross-referenced all 29 🟡 AS-DESIGNED documents and 3 ⏸ PARKED documents against the production database schema (via `$DATABASE_READONLY_URL`). Each document classified as READY TO BUILD, BLOCKED, NEEDS DECISION, DEFERRED, or STALE.

---

## Section A: Architecture Debt

### A1. CSDM Export Readiness (ADR: adr-csdm-export-readiness.md)

| Designed | Deployed | Gap |
|----------|----------|-----|
| `teams` table | Does not exist | Full table missing |
| `deployment_profiles.support_team_id` | Does not exist | Column missing |
| `deployment_profiles.change_team_id` | Does not exist | Column missing |
| `deployment_profiles.managing_team_id` | Does not exist | Column missing |
| `deployment_profile_contacts` CHECK includes `change_control` | CHECK = `operational_owner, technical_sme, support, vendor_rep, other` | Role missing |
| `application_integrations.source_deployment_profile_id` | **EXISTS** | Deployed Mar 20 |
| `application_integrations.target_deployment_profile_id` | **EXISTS** | Deployed Mar 20 |

**CSDM gap scorecard:** 14 of 28 fields ready (per gap analysis). ADR would move this to 19/28.

### A2. Composite Application (core/composite-application.md v2.0)

| Designed | Deployed | Gap |
|----------|----------|-----|
| `architecture_types` reference table | Does not exist | Full table missing |
| `applications.architecture_type` column | Does not exist | Column missing |
| `deployment_profiles.inherits_tech_from` FK | Does not exist | Column missing |
| `application_relationships` table | Does not exist | Full table missing |

### A3. Gamification (features/gamification/architecture.md v1.2)

| Designed | Deployed | Gap |
|----------|----------|-----|
| `gamification_achievements` table | Does not exist | Full table missing |
| `gamification_user_progress` table | Does not exist | Full table missing |
| `gamification_user_stats` table | Does not exist | Full table missing |
| `flags` table | Does not exist | Full table missing |
| `namespaces.enable_achievement_digests` | Does not exist | Column missing |
| `flag_summary_by_workspace` view | Does not exist | View missing |
| 9 RPC functions | Do not exist | Functions missing |

### A4. Cost Model Reunification (features/cost-budget/ v3.0 + ADR)

| Designed | Deployed | Gap |
|----------|----------|-----|
| `it_service_software_products` junction | **EXISTS** | Deployed |
| `it_services` contract fields (`contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`) | **ALL EXIST** | Deployed |
| `vw_it_service_contract_expiry` view | Does not exist | View missing |
| Legacy DP cost columns deprecated | Still in schema + 16 files reference them | Migration not started |

### A5. Business Capability (catalogs/business-capability.md v1.0)

| Designed | Deployed | Gap |
|----------|----------|-----|
| `business_capabilities` table | Does not exist | Full table missing |
| `business_capability_applications` junction | Does not exist | Full table missing |
| Seed taxonomy (25 generic + 12 govt L1s) | Not loaded | Data missing |

### A6. Power BI Export (features/technology-health/power-bi-export.md v1.0)

| Designed | Deployed | Gap |
|----------|----------|-----|
| 6 `vw_pbi_*` views | Do not exist | All 6 views missing |
| Service account auth | Not configured | Auth missing |

### A7. Realtime Subscriptions (features/realtime-subscriptions/ v1.0)

| Designed | Deployed | Gap |
|----------|----------|-----|
| Supabase Realtime infrastructure | **EXISTS** (Supabase-native) | Infrastructure ready |
| 3 React hooks (`useRealtimeSync`, `usePresence`, `useBroadcast`) | Do not exist | Frontend missing |
| P1 consumer: Initiative Kanban | Not built | UI missing |

### A8. Integration-DP Alignment (ADR: adr-integration-dp-alignment.md)

| Designed | Deployed | Gap |
|----------|----------|-----|
| Phase 1: DB FKs on `application_integrations` | **DEPLOYED Mar 20** | Done |
| Phase 2: `vw_integration_detail` rebuilt | **DEPLOYED Mar 20** | Done |
| Phase 3: Integration edit UI with DP selectors | Not built | UI missing |
| Phase 4: Data migration (backfill existing integrations) | Not run | Migration pending |

---

## Section B: Sequenced Implementation Plan

### Immediate (no blockers, high value, <1 day each)

| # | Item | Source Doc | What to Do | Effort |
|---|------|-----------|------------|--------|
| 1 | `change_control` role type | ADR: CSDM Export Readiness | ALTER CHECK on `deployment_profile_contacts` | 15 min (Stuart SQL) |
| 2 | `vw_it_service_contract_expiry` view | it-service.md v2.0 | CREATE VIEW with status buckets | 30 min (Stuart SQL) |
| 3 | TypeScript update for integration DP columns | Priority matrix #68 | Update `VwIntegrationDetail` type + consumers | 0.5 day |
| 4 | Assessment tour (S.6) | Priority matrix #66 | Shepherd.js steps for assessment walkthrough | 0.5 day |
| 5 | Security stats revalidation | security-posture-overview + soc2-evidence-index | Update stale counts (101 tables, 388 RLS, 59 triggers, 40 views) | 30 min |

### Near-term (1–5 days, soft dependencies)

| # | Item | Source Doc | Dependencies | Effort |
|---|------|-----------|-------------|--------|
| 6 | `teams` table + 3 DP FK columns | ADR: CSDM Export Readiness | None (standalone schema) | 1 day (Stuart SQL + Claude UI) |
| 7 | DP card Operations section UI | dp-card-wireframe.html | #6 (teams table must exist) | 1 day |
| 8 | Integration edit UI with DP selectors (Phase 3) | adr-integration-dp-alignment | Phase 1+2 deployed ✅ | 1–2 days |
| 9 | Integration data migration (Phase 4) | adr-integration-dp-alignment | #8 (UI for manual assignment) | 0.5 day |
| 10 | Budget Alerts frontend | Priority matrix #65 | DB layer deployed ✅ | 1–2 days |
| 11 | `business_capabilities` + junction table | business-capability.md | None (standalone) | 1 day (Stuart SQL) |
| 12 | Business capability seed data | business-capability.md | #11 | 0.5 day |
| 13 | Business capability UI (admin + mapping) | business-capability.md | #11, #12 | 2–3 days |
| 14 | 6 Power BI export views | power-bi-export.md | None | 1 day (Stuart SQL) |
| 15 | Composite application Phase 1 schema | composite-application.md | None | 1 day (Stuart SQL) |
| 16 | Composite application Phase 1 UI (suite badges) | composite-application.md | #15 | 2–3 days |

### Phase 37 scope (ServiceNow export — future)

| # | Item | Source Doc | Dependencies | Effort |
|---|------|-----------|-------------|--------|
| 17 | `integration_connections` table | itsm-api-research.md | None | 0.5 day |
| 18 | `integration_sync_map` + `integration_sync_log` tables | itsm-api-research.md | #17 | 0.5 day |
| 19 | CSDM export views (`vw_csdm_business_app`, `vw_csdm_service_auto`) | csdm-crawl-gap-analysis.md | #6 (teams must exist) | 1 day |
| 20 | ServiceNow publish Edge Function (7-step orchestrator) | itsm-api-research.md | #17, #18, #19 | 5–7 days |
| 21 | Publish UI (connection config, sync status, pre-publish validation) | itsm-api-research.md | #20 | 3–5 days |
| 22 | Export-time criticality derivation (0–100 → 1–5) | csdm-crawl-gap-analysis.md §4.2 | #19 | Included in #19 |
| **Phase 37 total** | | | | **~15–20 days** |

### Deferred (nice-to-have, no urgency)

| # | Item | Source Doc | Notes |
|---|------|-----------|-------|
| 23 | Gamification Phase 1 (4 tables, 9 functions) | gamification/architecture.md | Q2 target. Large but self-contained. |
| 24 | AI Chat v3 multi-cloud provider abstraction | ai-chat/v3-multicloud.md | Post-MVP. Current single-provider works. |
| 25 | Unified chat integration (support + AI convergence) | unified-chat-integration.md | Blocked by AI Chat conversation persistence. |
| 26 | Cloud Discovery (AWS/Azure/GCP) | cloud-discovery/architecture.md | Phase 27. Enterprise tier. |
| 27 | Realtime subscription hooks | realtime-subscriptions.md | Infrastructure ready; frontend when Kanban ships. |
| 28 | Semantic layer MCP tool implementations | semantic-layer.yaml | YAML written; tool build when AI Chat matures. |
| 29 | Visual tab unpark (React Flow) | visual-diagram.md / ADR | Blocked by integration-DP Phase 3 (#8). |
| 30 | Hybrid reference table migration | hybrid-reference-table-migration.md | Parked until after Garland import. |
| 31 | Legacy DP cost column removal | cost-model.md v3.0 | 16 file dependencies. High risk. Needs migration plan. |
| 32 | Garland showcase demo import | garland-showcase-demo-plan.md | Stuart executes. Delta training prerequisite. |

---

## Section C: Stale or Superseded

### Documents with stale statistics (fix by updating numbers, no architecture changes)

| Document | Stale Metric | Actual Value |
|----------|-------------|--------------|
| identity-security/security-posture-overview.md v1.3 | 92 tables, 357 RLS, 50 triggers, 31 views | 101 tables, 388 RLS, 59 triggers, 40 views |
| identity-security/soc2-evidence-index.md v1.3 | Same stale counts | Same actuals |
| identity-security/soc2-evidence-collection.md v1.2 | 50 triggers, 92 tables | 59 triggers, 101 tables |

**Action:** Batch-update all three docs with current schema stats. 30 minutes.

### Documents potentially superseded or needing refresh

| Document | Issue | Recommendation |
|----------|-------|----------------|
| features/support/implementation-plan.md | S.1–S.5 + S.7 complete per in-app-support-architecture v1.2. Only S.6 remains. | Update status or mark phases complete. |
| features/cost-budget/software-contract.md v2.0 | IT Services now own contracts. Schema already has contract fields on `it_services`. | Verify doc matches deployed state; may be promotable to 🟢. |
| features/cost-budget/vendor-cost.md v2.0 | Two-channel model documented but legacy DP cost columns still in use. | Keep 🟡 until legacy columns deprecated. |
| features/ai-chat/v3-multicloud.md v3.0 | References deprecated `auth.getUser()` pattern. | Update auth references when v3 work begins. |
| reviews/edge-functions-gap-analysis.md v1.0 | Some gaps closed (scaffold deployed, auth fix applied). | Re-review; close resolved gaps. |

### PARKED documents — status check

| Document | Parked Reason | Still Valid? |
|----------|--------------|--------------|
| core/visual-diagram.md v2.2 | Waiting for integration-DP Phase 3 | Yes — Phase 3 still pending (#8 above) |
| adr/adr-visual-tab-reactflow.md v1.0 | Same blocker | Yes |
| features/reference-data/hybrid-reference-table-migration.md v1.0 | Waiting for Garland import | Yes — Garland import not yet run |

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| 🟡 AS-DESIGNED documents audited | 29 |
| ⏸ PARKED documents audited | 3 |
| Classified READY TO BUILD | 5 (immediate) + 11 (near-term) |
| Classified BLOCKED | 4 (visual tab, unified chat, semantic tools, realtime hooks) |
| Classified DEFERRED | 10 (gamification, AI v3, cloud discovery, etc.) |
| Classified STALE stats | 3 (security/SOC2 docs) |
| Schema tables designed but not deployed | 8 (teams, 4× gamification, business_capabilities ×2, architecture_types, application_relationships) |
| Schema columns designed but not deployed | 7 (3× team FKs on DP, architecture_type + inherits_tech_from on apps/DPs, business_criticality) |
| Views designed but not deployed | 8+ (6× pbi_*, contract_expiry, CSDM export ×2) |
| Phase 37 estimated effort | 15–20 days |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-30 | Initial reconciliation — 29 AS-DESIGNED + 3 PARKED documents audited against 101-table production schema |
