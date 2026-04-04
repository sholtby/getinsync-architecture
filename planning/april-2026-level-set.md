# April 2026 Level Set — Feature Sequencing & ADR Roadmap

**Version:** 1.0
**Date:** April 3, 2026
**Author:** Stuart Holtby + Claude

---

## 1. Purpose

This document sequences all outstanding ADRs, major features, and architectural work into a phased delivery plan. It establishes dependencies, groups work that shares schema or UI surface area, and identifies independent work that can fill gaps or run in parallel.

**Scope:** Everything in the ADR backlog, open items priority matrix, and feature roadmap as of April 2026.

---

## 2. Current State (as of April 3, 2026)

### What's Deployed

| Milestone | Date | Key Deliverables |
|---|---|---|
| Cost Model Reunification (all phases) | Mar 5 | IT Services absorb contract role. Contract fields on IT Services. Contract Expiry Widget. Quick Calculator. |
| Integration-DP Alignment Phase 1-2 | Mar 20 | `source/target_deployment_profile_id` FKs on `application_integrations`. `vw_integration_detail` rebuilt. |
| AI Chat V2 | Mar 13 | Tool-use upgrade — `search_portfolio` + `query_database` tools. Edge Functions shared scaffold. |
| Explorer Tab | Mar 20 | Top-level navigation tab. `vw_explorer_detail` view. |
| Standards Intelligence Phase 1-2 | Mar 8 | Standards sub-tab, conformance badges, lifecycle linking on IT Services + Software Products. |
| RBAC UI Gating | Mar 12 | `usePermissions` hook, role-gated settings, read-only mode for non-admins. |

### What's Designed but Not Built

| ADR / Feature | Status | Doc |
|---|---|---|
| Contract-Aware Cost Bundles | PROPOSED | `adr/adr-contract-aware-cost-bundles.md` v1.0 |
| CSDM Export Readiness | PROPOSED | `adr/adr-csdm-export-readiness.md` v1.0 |
| Integration-DP Phase 3-4 | PENDING | `adr/adr-integration-dp-alignment.md` v1.2 |
| Visual Tab React Flow | PARKED (branch exists) | `adr/adr-visual-tab-reactflow.md` v1.0 |
| Gamification & Data Quality | DESIGNED | `features/gamification/architecture.md` v1.2 |
| Entra ID / Enterprise SSO | DEFERRED to Q2 | `identity-security/identity-security.md` |
| ITSM Integration (Phase 37) | FUTURE | `features/integrations/itsm-api-research.md` |

### Production Stats

- **Version:** 2026.3.4
- **Schema:** 99 tables, 38 views, 60 functions, 380 RLS policies, 57 audit triggers
- **pgTAP:** 437 assertions

---

## 3. Dependency Map

```
                    ┌─────────────────────────────┐
                    │  DEPLOYED (Mar 20)           │
                    │  Integration-DP Phase 1-2    │
                    │  Cost Model Reunification    │
                    └──────────┬──────────────────┘
                               │
            ┌──────────────────┼──────────────────────┐
            │                  │                      │
            ▼                  ▼                      ▼
   ┌─────────────────┐ ┌──────────────┐  ┌───────────────────────┐
   │ Stage A          │ │ Stage A       │  │ Stage B               │
   │ Contract-Aware   │ │ CSDM Export   │  │ Integration-DP        │
   │ Cost Bundles     │ │ Readiness     │  │ Phase 3-4             │
   │ (4 DP cols +     │ │ (teams +      │  │ (DP selector +        │
   │  UNION view)     │ │  3 DP FKs)    │  │  data migration)      │
   └────────┬─────────┘ └──────┬───────┘  └───────────┬───────────┘
            │                  │                      │
            │    ┌─────────────┘                      │
            │    │  Share DP card UI                   │
            │    │  — ship together                    │
            ▼    ▼                                    ▼
   ┌─────────────────────────┐           ┌───────────────────────┐
   │ Stage A Frontend         │           │ Stage C               │
   │ Cost Bundle contract UI  │           │ Visual Tab            │
   │ + Teams/Operations UI    │           │ React Flow resume     │
   │ + Double-count guardrails│           │ (Level 3 now accurate)│
   └─────────┬───────────────┘           └───────────────────────┘
             │
             ▼
   ┌─────────────────────────┐
   │ Stage D (FUTURE — Q3+)  │
   │ CSDM Export Engine       │
   │ Phase 37: ServiceNow     │
   │ Publish                  │
   └─────────────────────────┘


   INDEPENDENT (no dependencies on above chain):
   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
   │ Gamification      │  │ Entra ID / SSO   │  │ Open Items       │
   │ Phase 1           │  │ (Q2)             │  │ (interleave)     │
   └──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 4. Staged Delivery Plan

### Stage A: DP Enhancement — Contract Awareness + CSDM Teams

**Rationale:** Both ADRs add columns to `deployment_profiles` and share the DP card UI. Ship schema together in one DB session, then frontend in 1-2 sessions. Avoids two rounds of DP card redesign.

#### A.1 — Database Session (~3 hours)

| # | Work | ADR Source | Estimate |
|---|---|---|---|
| A.1.1 | Add 4 contract columns on `deployment_profiles` + partial index | Contract-Aware Cost Bundles §4.1 | 30 min |
| A.1.2 | Create `vw_contract_expiry` UNION view + grants | Contract-Aware Cost Bundles §4.2 | 30 min |
| A.1.3 | Create `teams` table + RLS + audit + grants | CSDM Export Readiness §4.1 | 1 hr |
| A.1.4 | Add 3 team FK columns on `deployment_profiles` | CSDM Export Readiness §4.2 | 30 min |
| A.1.5 | Update `deployment_profile_contacts` CHECK constraint (add `change_control`) | CSDM Export Readiness §4.3 | 15 min |
| A.1.6 | Run schema checkpoint (security posture + tsc) | — | 15 min |

**Schema delta:** +1 table (`teams`), +1 view (`vw_contract_expiry`), +7 columns on `deployment_profiles`, +1 CHECK update. Expected new stats: 100 tables, 39 views.

#### A.2 — Frontend Session: Contract-Aware Cost Bundles (~5 hours)

| # | Work | Estimate |
|---|---|---|
| A.2.1 | Contract details section on Cost Bundle card (collapsible, 4 fields) | 2 hrs |
| A.2.2 | Update `ContractExpiryWidget` to query `vw_contract_expiry` (UNION view) | 1 hr |
| A.2.3 | Double-count warning: Add Cost Bundle → check for IT Service allocations | 1 hr |
| A.2.4 | Double-count prompt: Add IT Service → check for contract-bearing Cost Bundles | 1 hr |

#### A.3 — Frontend Session: CSDM Teams + Operations (~5 hours) ✅ DEPLOYED 2026-04-04

| # | Work | Estimate | Status |
|---|---|---|---|
| A.3.1 | Team management screen (namespace admin settings — CRUD list) | 2 hrs | ✅ Done |
| A.3.2 | Operations section on DP card (3 team dropdowns with plain-English labels) | 3 hrs | ✅ Done |

**Note:** A.2 and A.3 can run as **parallel sessions** if files don't overlap. The Cost Bundle card changes (A.2) and the Operations section (A.3) are different parts of the DP card. Verify file ownership before parallelizing.

**Stage A total: ~13 hours (1 DB session + 2 frontend sessions)**

---

### Stage B: Integration-DP Phase 3 — DP Selector in Connections

**Rationale:** Completes the integration-DP ADR. The DP selector in the Add Connection modal was designed to ship alongside the CSDM Export DP card changes (§6.3). After Stage A, the DP card has its final layout.

| # | Work | Estimate |
|---|---|---|
| B.1 | Update `VwIntegrationDetail` TypeScript types for 4 DP columns (open item #68) | 0.5 day |
| B.2 | DP selector in Add Connection modal (show only when app has multiple DPs) | 3 hrs |
| B.3 | Connections list: show DP name alongside app name when DP specified | 1 hr |
| B.4 | Data migration: assign existing integrations to primary DP | 1 hr (DB) |

**Stage B total: ~1.5 days (1 frontend session + 1 small DB task)**

---

### Stage C: Visual Tab React Flow — Resume Parked Branch

**Rationale:** The branch was parked waiting for DP-level integrations (Stage B). After Stage B, Level 3 blast radius has accurate, DP-scoped data.

| # | Work | Estimate |
|---|---|---|
| C.1 | Rebase `feat/visual-tab-reactflow` onto dev (branch diverged since Mar 19) | 0.5 hr |
| C.2 | Wire Level 3 blast radius to DP-scoped integration data | 1 day |
| C.3 | Fix known gaps: TB layout direction, double-click for L3, hover tooltips | 0.5 day |
| C.4 | QA and merge | 0.5 day |

**Stage C total: ~2.5 days (1-2 frontend sessions)**

---

### Stage D: CSDM Export Engine (Phase 37 — FUTURE, Q3+)

**Rationale:** Export views and publish engine depend on teams (Stage A), contracts (Stage A), and DP-level integrations (Stage B). This is the "big one" — ServiceNow + HaloITSM publish/subscribe. Scoped at 15-20 days in the open items matrix.

| # | Work | Estimate |
|---|---|---|
| D.1 | Export views: `vw_csdm_business_app` with criticality derivation | 2 hrs |
| D.2 | Export views: `vw_csdm_service_auto` with team→group mapping | 2 hrs |
| D.3 | Cost Bundle → `ast_contract` export mapping | 2 hrs |
| D.4 | ServiceNow publish API integration | 10-15 days |
| D.5 | HaloITSM publish/subscribe | 5 days |

**Stage D total: 15-20 days. Not scheduled for April/May.**

---

## 5. Independent Work — Interleave Between Stages

These features have **no dependencies** on the ADR chain and can fill gaps between stages or run in parallel sessions.

### Tier 1: High Customer Value / Low Effort

| Item | Source | Effort | Notes |
|---|---|---|---|
| #57 Scope indicator | Open items | 0.5 day | "N of M workspaces" visibility indicator. Quick win. |
| #65 Budget alerts frontend | Open items | 1-2 days | DB layer deployed. Frontend pending. |
| #66 Assessment tour (Shepherd.js) | Open items | 0.5 day | Shepherd already integrated. |
| #63 Servers on dashboard | Open items | 0.5 day | Visual tab done. Dashboard remaining. |

### Tier 2: Designed Features

| Feature | Doc | Effort | Notes |
|---|---|---|---|
| **Gamification Phase 1** | `features/gamification/architecture.md` v1.2 | 2-3 days | Audit-log-driven achievements + data quality flags. Schema: 4 new tables, 1 view, 9 functions. Includes #44 (flag CREATE viewer exception). Self-contained — no dependencies on ADR chain. **Consider scheduling between Stage A and B for variety.** |
| Tech Scoring Patterns | `features/assessment/tech-scoring-patterns.md` | 1-2 days | Pre-fill T-score defaults. Reduces assessment fatigue. |
| Business Capability | `catalogs/business-capability.md` v1.0 | 2-3 days | Hierarchical taxonomy. Additive. |
| Application Relationships (Suites) | `core/composite-application.md` v2.0 | 2-3 days | Suite/family relationships. Schema changes needed. |
| Standards Intelligence Phase 2 | `features/technology-health/standards-intelligence.md` | 2-3 days | T-score integration. Phase 1 deployed. |
| Realtime Subscriptions | `features/realtime-subscriptions/architecture.md` v1.0 | 2-3 days | Backend deployed. Frontend hooks pending. |

### Tier 3: Larger Initiatives (Q2+)

| Feature | Doc | Effort | Notes |
|---|---|---|---|
| **Entra ID / Enterprise SSO** | `identity-security/identity-security.md` | TBD | Identity/Security rewrite v1.1 → v2.0. Namespace-level IdP config, JIT provisioning, SAML support (Saskatchewan Account). **Deferred to Q2.** Not blocked by ADR chain. Enterprise sales enabler — "do you support SSO?" |
| R.8 Legacy cost column migration | `cost-model-validation-2026-03-04.md` | 12-14 hrs | Replace 16-file dependency on `annual_licensing_cost`/`annual_tech_cost` with cost channel views. **Best scheduled after Stage A** (contract-aware Cost Bundles reduce the cost entry confusion during migration). |
| Cloud Discovery | `features/cloud-discovery/architecture.md` | Large | AWS/Azure/GCP connectors. Enterprise feature. |
| Unified Chat | `features/support/unified-chat-integration.md` | Large | Depends on Edge Functions + AI Chat + persistence. |
| AI Chat V3 | `features/ai-chat/v3-multicloud.md` | 3-5 days | Multi-cloud cost lookup. |

---

## 6. SOC2 & Compliance Track (Parallel — Delta-Assigned)

These run independently of all engineering work. Stuart's only action item is GitHub branch protection (#3).

| Policy | Jira | Status | Assigned |
|---|---|---|---|
| Information Security Policy | GPD-528 | OVERDUE (Feb 27) | Delta |
| Change Management Policy | GPD-529 | OVERDUE (Feb 27) | Delta + Stuart (branch protection) |
| Incident Response Plan | GPD-530 | OVERDUE (Feb 27) | Delta |
| Acceptable Use Policy | GPD-531 | OVERDUE (Feb 27) | Delta |
| Data Classification Policy | GPD-532 | OVERDUE (Mar 6) | Delta |
| Business Continuity Plan | GPD-533 | OVERDUE (Mar 6) | Delta |
| Vendor Management Policy | GPD-534 | Due Mar 27 | Delta |
| Data Retention Policy | GPD-535 | Due Mar 27 | Delta |

**Scorecard: 0 of 8 complete, 6 overdue.**

---

## 7. OAuth Scorecard

| Provider | Status | Action Needed |
|---|---|---|
| Google | ✅ Verified & Live | None |
| Microsoft | ⚠️ Working (cosmetic warning) | Publisher verification — docs resubmitted Feb 13. Awaiting Microsoft review. |

---

## 8. Recommended April–May Calendar

```
Week 1 (Apr 7-11):   Stage A.1 — DB session (contracts + teams schema)
                      #61 Tech Health CSV fix (1 hr, quick win)

Week 2 (Apr 14-18):  Stage A.2 — Contract-Aware Cost Bundles UI
                      Stage A.3 — Teams + Operations UI (parallel if possible)

Week 3 (Apr 21-25):  Stage B — Integration-DP Phase 3 + #68 types
                      #57 Scope indicator (0.5 day fill)

Week 4 (Apr 28-May 2): Gamification Phase 1 (2-3 days)

Week 5 (May 5-9):    Stage C — Visual Tab React Flow resume
                      #65 Budget alerts frontend (if time)

Week 6 (May 12-16):  Stage C completion + polish
                      #66 Assessment tour (0.5 day fill)

Ongoing:             SOC2 policies (Delta)
                     Microsoft OAuth verification (waiting)

Q2 (Jun+):           Entra ID / Enterprise SSO
                     R.8 Legacy cost migration
                     Phase 37 CSDM Export (Q3)
```

---

## 9. Success Criteria — End of May Check-In

By end of May, the following should be true:

- [ ] Contract-aware Cost Bundles deployed — customers can enter contract dates on Cost Bundles and see them on the expiry widget
- [ ] Teams entity deployed — DPs have support/change/managing team assignments
- [ ] Integration-DP Phase 3 complete — Add Connection modal has DP selector
- [ ] Visual Tab React Flow merged — Level 3 blast radius shows DP-scoped integrations
- [ ] Gamification Phase 1 deployed — achievements and data quality flags live
- [ ] At least 3 of 8 SOC2 policies completed (Delta)
- [ ] `vw_contract_expiry` answers: "Which applications have contracts expiring in the next 18 months?"

---

## 10. What This Document Does NOT Cover

- Sprint-level task breakdowns (use open items matrix)
- Individual session planning (Claude Code sessions are self-organizing)
- Database migration scripts (Stuart handles via SQL Editor)
- Pricing or commercial decisions
- Customer-specific implementation details

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-04-03 | Initial level set — 4 stages (A-D), dependency map, independent work tiers, April-May calendar, success criteria |
