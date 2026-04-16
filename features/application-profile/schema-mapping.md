# Application Profile — Data Shape Mapping Against GetInSync Schema

**Version:** v1.0
**Status:** 🟡 AS-DESIGNED
**Last updated:** 2026-04-16

---

## Context

The **Application Profile** is a canonical, one-page, business-language summary of an application's footprint. It is the atomic unit of GetInSync NextGen APM — rendered standalone in the UI and embedded as per-app sections inside a Published Portfolio Report.

An 11-block proposal was drafted (Identity, Business Purpose, User Community, Information Domains, Ownership, Criticality, Lifecycle Position, App Context, Cost, Tech Debt & Remediation, Assessment Context). This document maps each proposed field against the existing schema to determine what EXISTS, can be DERIVED, needs NEW storage, or should be AI-generated — and aligns the shape with the Publish Assessment RPC already specified in architecture (`get_workspace_assessment_report_data`, not yet implemented).

The Publish Assessment architecture is **specified but unshipped**. That is the opportunity: if we define the Application Profile now, it can become the single data shape the portfolio RPC returns for each app, so the RPC becomes "get profiles + workspace aggregates" rather than a separate assembly pipeline.

### Authoritative Source Files Referenced

- `schema/nextgen-schema-current.sql` — schema source of truth (T01–T15 confirmed on `deployment_profiles`, lines 7452–7466)
- `features/publish-assessment/architecture.md` — RPC spec, snapshot strategy
- `core/involved-party.md` — PartyRole codes
- `core/time-paid-methodology.md` — score derivation
- `src/types/view-contracts.ts` (code repo) — `VwExplorerDetail` interface (current best summary row)
- `supabase/functions/ai-chat/tools.ts` (code repo) — the `application-detail` tool (existing bundle pattern)
- `src/components/applications/ApplicationDetailDrawer.tsx` (code repo) — existing UI to evolve, not replace

---

## 1. Field-by-Field Mapping

Status codes: **EXISTS** (direct column), **DERIVED** (computed from existing data), **RELATIONSHIP** (via join), **NEW-STORED** (new column/table needed), **NEW-AI** (AI-generated, cache strategy required).

### Block 1 — Identity

| Field | Status | Location / Notes |
|---|---|---|
| `application_name` | EXISTS | `applications.name` |
| `acronym` | NEW-STORED | Add `applications.acronym text` (nullable, short). Currently embedded in `name` inconsistently. |
| `plain_language_description` | EXISTS (partial) | `applications.short_description` (160 char) is the closest. `short_description` today is used as display description, not guaranteed to be business-only / jargon-free. Recommend: keep `short_description` as is, add `plain_language_summary` with NEW-AI first-draft + human approval flag. |
| `operational_status` | EXISTS | `applications.operational_status` (enum: operational, pipeline, retired) |

### Block 2 — Business Purpose

| Field | Status | Location / Notes |
|---|---|---|
| `business_outcome` | NEW-STORED | Add `applications.business_outcome text`. Distinct from description; semantically "what outcome does this exist to enable." Candidate for NEW-AI draft. |
| `capability_mappings[]` | NEW-STORED | **No capability model exists** in shipped or planned schema. Requires: `capabilities` table + `application_capabilities` junction. See Q3 below. |

### Block 3 — User Community

| Field | Status | Location / Notes |
|---|---|---|
| `user_groups[]` | NEW-STORED | No representation today. Suggest JSONB array `applications.user_groups jsonb` with shape `[{group_name, role_description}]`, or reference table `user_group_types` + junction. JSONB is simpler given the free-text nature. |
| `estimated_user_count` | NEW-STORED | Add `applications.estimated_user_count text` as a bucket enum (`<10`, `10-100`, `100-1000`, `1000+`). Not an integer — users want scale, not precision. |
| `serving_areas[]` | EXISTS (partial) | `applications.branch text` exists but is single-value free text. To support multi-branch/region, either promote to array column or create `application_serving_areas` junction against a new `serving_area_types` reference table. |

### Block 4 — Information Domains

| Field | Status | Location / Notes |
|---|---|---|
| `data_domains[]` | NEW-STORED | **No application-level data-domain taxonomy exists.** `application_data_assets` captures record-level classification (PII/PHI/financial flags, sensitivity) — useful but record-level, not domain-level. Requires new `data_domain_types` reference table + `application_data_domains` junction. See Q4. |

### Block 5 — Ownership (via PartyRole pattern)

Existing `application_contacts.role_type` enum: `business_owner`, `technical_owner`, `steward`, `sponsor`, `sme`, `support`, `vendor_rep`, `other`.

| Proposed Role | Status | Mapping |
|---|---|---|
| Business Owner | EXISTS (RELATIONSHIP) | `application_contacts` where `role_type='business_owner'` |
| Application Owner | EXISTS (RELATIONSHIP) | `application_contacts` where `role_type='technical_owner'` (naming mismatch — see Q1) |
| Accountable Executive | NEW-STORED | Not a current `role_type` enum value. Must add `accountable_executive` to the CHECK constraint, or reuse `sponsor`. Recommend add `accountable_executive` explicitly — governance/funding authority is distinct from sponsor. |
| Technical Contact | EXISTS (RELATIONSHIP) | `application_contacts` where `role_type IN ('technical_owner','sme','support')`. Profile should pick the one marked `is_primary=true`. |

### Block 6 — Criticality

| Field | Status | Location / Notes |
|---|---|---|
| `criticality_score` | EXISTS | `portfolio_assignments.criticality` (0–100, derived from B-factors) |
| `business_impact_statement` | NEW-AI | Not currently stored. One-sentence generated statement of the form "If unavailable, ___". Best as NEW-AI cached per DP/portfolio assignment. |
| `crown_jewel` | DERIVED | `is_crown_jewel = criticality >= 50`. Already computed in `vw_explorer_detail.is_crown_jewel`. |

### Block 7 — Lifecycle Position

| Field | Status | Location / Notes |
|---|---|---|
| `time_quadrant` | EXISTS | `portfolio_assignments.time_quadrant` (eliminate/modernize/tolerate/invest) |
| `paid_action` | EXISTS | `deployment_profiles.paid_action` (plan/address/delay/ignore — NOTE: CHECK constraint does **not** include `improve` or `divest` per the proposal wording; methodology doc uses PLAN/ADDRESS/DELAY/IGNORE. Proposal text says "Plan/Address/Improve/Divest" — **mismatch needs reconciliation**) |
| `lifecycle_status` | EXISTS | `applications.lifecycle_status` (Mainstream/Extended/End of Support) + `vw_explorer_detail.worst_lifecycle_status` for roll-up across the tech stack |
| `time_paid_tension` | NEW-AI | Conflict flag — no stored computation today. Rule is deterministic (e.g., time_quadrant='tolerate' && paid_action='address' → tension). Recommend: compute deterministically in a view column `time_paid_tension_flag boolean` + NEW-AI narrative. Not everything needs AI; the flag is a rule, the sentence is the AI part. |

### Block 8 — Application Context (Visual + Data)

| Field | Status | Location / Notes |
|---|---|---|
| `upstream_apps[]` | EXISTS (RELATIONSHIP) | `application_integrations` filtered where `target_application_id = this_app` (they send TO us). Also via `target_deployment_profile_id` post-Phase 1+2 DP-alignment. |
| `downstream_apps[]` | EXISTS (RELATIONSHIP) | `application_integrations` filtered where `source_application_id = this_app`. |
| edge labels (business-language) | NEW-STORED | `application_integrations.name` and `.description` exist but are not guaranteed business-language. No dedicated `business_purpose` / `edge_label` field. Recommend adding `application_integrations.business_purpose text` (e.g., "receives client referrals from"). Candidate for NEW-AI draft. |
| `integration_summary` | NEW-AI | One-two sentence generated summary of integration posture. Derived from counts + criticality mix. Cache per app. |
| Visual diagram | EXISTS (DERIVED) | Rendering concern — `vw_integration_detail` already supports 1-hop query (see `src/hooks/useVisualGraphData.ts:109`). No new data needed. |

### Block 9 — Cost

Cost lives on **cost channels**, not on applications (per CLAUDE.md). Cost channels are SoftwareProduct, ITService, and CostBundle-as-DP (`dp_type='cost_bundle'`).

| Field | Status | Location / Notes |
|---|---|---|
| `annual_licensing_cost` | EXISTS | `deployment_profiles.annual_licensing_cost` for the app's primary DP, + rollup from attached SoftwareProducts |
| `annual_infrastructure_cost` | EXISTS | `deployment_profiles.annual_tech_cost` + `annual_cost` on `cost_bundle` DPs linked to infrastructure |
| `annual_support_cost` | NEW-STORED (partial) | No dedicated column. Today this is captured as a cost_bundle DP with contract fields, but there is no explicit "support" cost channel type. Could introduce `service_types` code for support, or add `deployment_profiles.annual_support_cost` on primary DPs. Simpler: treat as a cost_bundle with a designated category. |
| `total_cost_of_ownership` | DERIVED | `vw_application_run_rate.total_run_rate` already aggregates. **Missing TypeScript interface** — `vw_application_run_rate` is used in `tools.ts` but not declared in `src/types/view-contracts.ts`. Fix that alongside profile work. |
| `cost_trend` | NEW-STORED | No historical cost data. Would need time-series (an `application_cost_history` table or snapshots). **Recommend deferring this field from v1** — the platform doesn't yet track prior-year costs. |
| `cost_notes` | EXISTS (partial) | `deployment_profiles` has `contract_reference`, `renewal_notice_days`, `contract_end_date`. No general-purpose `cost_notes`. Add `applications.cost_notes text` OR surface contract-derived text. |

**Role gating:** Today nothing gates cost visibility. If cost needs to be role-gated on the profile, implement via RLS on the view or via a frontend permission check against a new `can_view_costs` capability. Out of scope for schema; flag for UX team.

### Block 10 — Tech Debt & Remediation

Existing: `deployment_profiles.tech_debt_description`, `deployment_profiles.estimated_tech_debt` (marked LEGACY per cost-model v3.0), `deployment_profiles.remediation_effort`, and crucially the `initiatives` + `initiative_deployment_profiles` tables which already model remediation plans with owner, status, theme, cost ranges, time horizon.

| Field | Status | Location / Notes |
|---|---|---|
| `tech_debt_items[]` | NEW-STORED | Today: one free-text `tech_debt_description` per DP. No list structure. Recommend new `application_tech_debt` table: `id`, `application_id`, `deployment_profile_id` (nullable), `description`, `business_impact`, `severity`, `created_at`. List, not JSONB — they have their own lifecycle and each should be linkable to an initiative. |
| `remediation_status` | EXISTS (DERIVED) | `initiatives.status` via `initiative_deployment_profiles` join. Roll up to app-level status: "in progress" if any active initiative, "approved" if any planned, etc. |
| `remediation_summary` | NEW-AI | Generated from linked initiatives. Cache per app. |
| `estimated_remediation_cost` | EXISTS (DERIVED) | Sum of `initiatives.one_time_cost_low`–`_high` across linked initiatives → ROM range. |
| `target_state` | NEW-STORED | Not modeled. Add `applications.target_state text` (one-sentence) — not on DP because "the desired end state for this application" is application-scoped even if execution is DP-scoped. |
| `remediation_alignment` | NEW-AI | Deterministic flag ("does any initiative's theme match the TIME placement?") + AI narrative sentence. |

### Block 11 — Assessment Context

| Field | Status | Location / Notes |
|---|---|---|
| `business_fit_score` | EXISTS | `portfolio_assignments.business_fit` |
| `tech_health_score` | EXISTS | `deployment_profiles.tech_health` |
| `tech_risk_score` | EXISTS | `deployment_profiles.tech_risk` |
| `near_threshold_flag` | DERIVED | Compute from scores (within 5 of threshold). Thresholds live in `assessment_thresholds` (namespace-scoped). Put in the profile view. |
| `last_assessed_date` | EXISTS | `deployment_profiles.assessed_at` (tech) + `portfolio_assignments.business_assessed_at` (business). Profile should surface the later of the two, labeled. |
| `assessment_completeness` | EXISTS (DERIVED) | `deployment_profiles.tech_assessment_status` + `portfolio_assignments.business_assessment_status`. Roll up: both complete → "complete"; one in progress → "partial"; neither → "not started". |

---

## 2. Gap Analysis Summary

**New storage required (7 areas):**
1. `applications.acronym` (column)
2. `applications.business_outcome` (column)
3. `applications.target_state` (column)
4. `applications.cost_notes` (column)
5. `applications.user_groups jsonb` + `estimated_user_count` (columns)
6. `accountable_executive` added to `application_contacts.role_type` CHECK constraint
7. `application_integrations.business_purpose` (column, for business-language edge labels)

**New tables required (3):**
1. `capabilities` + `application_capabilities` (capability model, currently missing entirely)
2. `data_domain_types` + `application_data_domains` (information-domain taxonomy)
3. `application_tech_debt` (list of debt items with business-impact framing)

**Optionally new:**
- `serving_area_types` + `application_serving_areas` (if multi-area support is needed; else keep `applications.branch` as-is)

**AI-generated, cached fields (6):**
- `plain_language_summary` (first-draft assist; human-approved, flagged)
- `business_impact_statement`
- `integration_summary`
- `time_paid_tension` narrative
- `remediation_summary`
- `remediation_alignment` narrative

**Deterministic (rule-based, not AI):**
- `near_threshold_flag`, `is_crown_jewel`, `time_paid_tension_flag`, `remediation_status` rollup — compute in the view.

**Fields to defer from v1:**
- `cost_trend` — no historical cost data exists; would require a new time-series table first.

---

## 3. Schema Recommendations

### 3.1 Implement as a VIEW, not a table (primary recommendation)

Build `vw_application_profile` that assembles all EXISTS / DERIVED / RELATIONSHIP fields. Reasons:
- Authoritative data continues to live on its natural tables (applications, DPs, portfolio_assignments, initiatives, integrations) — the profile is a projection, not a new source of truth.
- RLS is already solved on the underlying tables; a `security_invoker=true` view inherits that automatically.
- No duplication, no sync problems.

Add NEW-STORED columns to their natural homes (application-scoped → `applications`; DP-scoped → `deployment_profiles`; integration-scoped → `application_integrations`; plan-scoped → `initiatives`). Do **not** create a new `application_profiles` table to hold them all.

### 3.2 AI narrative caching — use a new table, not `snapshot_data`

`assessment_history.snapshot_data` is the right place for **point-in-time snapshots** taken at publish. It is not the right place for always-fresh narrative fragments that render standalone in the UI.

Recommend a new `application_narrative_cache` table:
```
application_id uuid, deployment_profile_id uuid nullable,
narrative_key text  -- 'plain_language_summary' | 'business_impact' | 'integration_summary' | 'time_paid_tension' | 'remediation_summary' | 'remediation_alignment'
content text,
generated_at timestamptz,
input_hash text      -- hash of the inputs used (scores, integration counts, etc.) — regenerate when hash changes
approved boolean default false,
approved_by uuid, approved_at timestamptz
```

Invalidation: recompute `input_hash` on render; if stale, regenerate. Human-approved narratives (e.g., `plain_language_summary`) get `approved=true` and skip regeneration unless explicitly re-drafted.

### 3.3 Keep the NEW-STORED additions to `applications` minimal

The `applications` table is already wide. Add only the 4 simple columns (`acronym`, `business_outcome`, `target_state`, `cost_notes`). For `user_groups` prefer JSONB over a new junction unless reporting across groups is needed.

### 3.4 Integration `business_purpose`

Add `application_integrations.business_purpose text`. Keep existing technical fields (`integration_type`, `direction`, `frequency`). The profile renders `business_purpose` when present, falls back to a generated label otherwise.

---

## 4. Answers to the 8 Design Questions

**Q1. Involved Party coverage.** Three of the four proposed ownership roles map to existing `application_contacts.role_type` enum values (`business_owner`, `technical_owner` ≈ "Application Owner", `sme`/`support` ≈ "Technical Contact"). **Accountable Executive is missing** — either add to the CHECK constraint or reuse `sponsor`. Recommend adding `accountable_executive` explicitly: a sponsor is not always the person with governance/funding accountability. Naming mismatch: "Application Owner" in the proposal is `technical_owner` in the enum — consider renaming the enum value to `application_owner` for clarity (requires data migration on `application_contacts`).

**Q2. Application-to-application relationships.** `application_integrations` exists and supports both app-level (`source_application_id`, `target_application_id`) and DP-level (`source_deployment_profile_id`, `target_deployment_profile_id`) linking — the DP columns are recent (Phase 1+2 integration-DP alignment closed Mar 20). Edge direction is supported via `direction` enum. **Business-language edge labels do not yet have a dedicated field.** Add `application_integrations.business_purpose text`. Today the `name` and `description` fields are mixed-use.

**Q3. Capability model.** Does not exist in shipped or planned schema — confirmed via grep of `docs-architecture/`. Requires a design decision before build: simple junction (`capabilities` + `application_capabilities`), or richer model with capability hierarchy (parent capabilities, enabling/realizing distinction)? Recommend starting simple: a flat `capabilities` reference table + `application_capabilities` junction, with `namespace_id` on the reference table so each customer can maintain their own capability taxonomy.

**Q4. Data domains.** No application-level taxonomy exists. `application_data_assets` captures record-level classification (sensitivity, PII/PHI/financial flags) and `data_tag_types` tags integrations. Neither is a replacement — data domains are coarser ("client records", "case files", "geospatial data"). Introduce `data_domain_types` (namespace-scoped reference table) + `application_data_domains` junction.

**Q5. View vs. table.** VIEW. Rationale in §3.1. The one exception is narrative cache (§3.2), which is a new table because it has write semantics (generated content, approval flags) that views can't support.

**Q6. AI-generated field caching.** Use `application_narrative_cache` with an `input_hash` column (§3.2). Regenerate only when the inputs that drive a given narrative change — e.g., `integration_summary` invalidates when integration count/criticality mix changes, not when a DP score changes. Approved narratives (`plain_language_summary`) are locked until explicitly re-drafted. Do **not** regenerate on every render — Claude calls are expensive and most profile renders will want cached text.

**Q7. Cost data.** Costs live on cost channels — confirmed from CLAUDE.md, cost-model.md, and the schema. The four proposed cost fields map as: `annual_licensing_cost` (exists on DP), `annual_infrastructure_cost` (= `annual_tech_cost` on DP, plus cost_bundle DPs), `annual_support_cost` (no dedicated column — use cost_bundle or add a column), `total_cost_of_ownership` (derived via `vw_application_run_rate`). **Do not add cost columns directly to `applications`** — it breaks the channel model. Cost notes (free text) can go on `applications.cost_notes` since they are application-scoped commentary, not amounts. Historical `cost_trend` requires a new time-series table; defer from v1.

**Q8. Tech debt and remediation.** Partial existing support. `deployment_profiles.tech_debt_description` (single free-text), `deployment_profiles.estimated_tech_debt` (legacy, migration risk), `deployment_profiles.remediation_effort` (t-shirt size). The `initiatives` table is rich (status, theme, cost ranges, time horizon, benefit type) and `initiative_deployment_profiles` junction links plans to DPs. **Debt items should be a separate table** (`application_tech_debt`) — items have their own lifecycle and should link to initiatives. **Remediation status/summary/target_state are singular per application** — `target_state` goes on `applications`, remediation status/summary are derived from linked initiatives + AI.

---

## 5. Fields in the Existing Schema Missing from the Proposal

Worth considering for v1:
- **`hosting_type`, `cloud_provider`, `region`, `server_name`, `data_center_id`** on primary DP — the profile claims to be the atomic unit the portfolio report composes, and the RPC spec includes these. If they are excluded from the profile, the portfolio RPC can't be "get profiles + aggregate."
- **`dr_status`** on DP — criticality pairs naturally with DR posture.
- **`contract_end_date`, `renewal_notice_days`** on cost_bundle DPs — often the single most actionable field for a business reader.
- **`management_classification`, `csdm_stage`** on `applications` — CSDM alignment is part of the platform's value prop; omitting it from the profile hides a differentiator.
- **`is_internal_only`** on `applications` — distinguishes internally-built vs vendor software, which changes the remediation story.
- **`vendor_org_id`** via cost_bundle DP — "who sells this to us" is a profile-level question.
- **Integration counts by criticality / sensitivity** — from `vw_application_integration_summary` (`critical_count`, `high_sensitivity_count`). The proposal has `integration_summary` narrative but not the underlying tallies.

Recommend adding these as an "Operational Footprint" mini-block or folding into existing blocks (hosting/DR into Block 8 Context; contracts into Block 9 Cost; CSDM/management_classification into Block 1 Identity).

Worth considering for v2:
- **Portfolio membership** — what portfolio(s) the app belongs to, with relationship_type (publisher vs consumer). Useful for readers navigating from portfolio → profile → back.
- **Assessment factor values (B1–B10, T01–T15)** — the RPC spec includes these. For the profile UI these may be too granular, but for the portfolio RPC shape they must be present.

---

## 6. Publish Assessment RPC Alignment Report

The per-app bundle that `get_workspace_assessment_report_data` is specified to assemble (`features/publish-assessment/architecture.md` §Step 1, lines 45–62):

- Application metadata: `name`, `description`, `lifecycle`, `operational_status`, `crown_jewel`
- Production DP metadata: `name`, `environment`, `hosting_type`, `cloud_provider`, `region`, `server_name`/`data_center_id`
- Portfolio assignment: `b1`–`b10`, `business_fit`, `criticality`, `time_quadrant`
- DP: `t01`–`t15` (the architecture doc references T01–T14 in places — **but the schema has T01–T15**, confirmed from `schema/nextgen-schema-current.sql:7452`), `tech_health`, `tech_risk`, `paid_action`
- Factor labels from `assessment_factors` (namespace-scoped)
- ITSM counts (if available)
- Integration count

**(a) Fields in the profile that the RPC does NOT currently gather:**
- `acronym`, `business_outcome`, `target_state`, `cost_notes` (not proposed in RPC — need to be added to the RPC when the profile ships)
- User community fields (user_groups, estimated_user_count, serving_areas)
- Data domains
- Ownership contacts (RPC spec doesn't mention contacts at all — significant gap)
- Upstream/downstream integration detail with business-language edge labels
- Cost breakdown (RPC focuses on assessment, not cost) — the profile needs cost; the RPC will either need to gather it or the frontend stitches it
- Tech debt items and remediation-plan detail (only factor scores are in the RPC today)
- All NEW-AI narrative fields

**(b) Fields the RPC gathers that aren't in the profile proposal:**
- Raw B1–B10 and T01–T15 factor values (the profile has rolled-up scores only)
- Factor labels per namespace
- ITSM counts
- Production-DP location fields (hosting_type, cloud_provider, region, server_name, data_center_id) — §5 above recommends adding these to the profile

**(c) Recommendation — make the profile the single shape the RPC consumes:**

1. **Extend the RPC output per-app to return a `profile` JSONB** that matches `vw_application_profile` exactly, plus an `assessment_detail` block for the raw factor values (which the portfolio PDF needs but the profile UI doesn't show).
2. **The RPC becomes: `get workspace aggregates + for each app, call profile projection`.** Implement this literally: the RPC wraps `vw_application_profile` filtered by workspace_id, then computes the workspace-level TIME/PAID distribution and Crown Jewel count as aggregates over the profile rows.
3. **Write narrative fragments from the profile cache into the snapshot.** On publish, copy current cached narratives (`application_narrative_cache`) for each app into the `assessment_history.snapshot_data` JSONB — so the snapshot captures the narratives as they were at publish time, regardless of future cache invalidation.
4. **Fix the T14/T15 ambiguity in the RPC spec.** The architecture doc references T01–T14 in a few places; the schema has T01–T15. Reconcile before shipping.

This approach means:
- One data shape, two consumers (UI + portfolio report).
- Narrative caching is reused, not re-generated per publish.
- Snapshots remain point-in-time immutable.
- The RPC stays thin.

---

## 7. Verification (how to test the design end-to-end once built)

This is an analysis document, not an implementation plan, but when the schema/view/RPC are built the verification should be:

1. **Read-only verification of the view:**
   ```bash
   export $(grep DATABASE_READONLY_URL .env | xargs)
   psql "$DATABASE_READONLY_URL" -c "select * from vw_application_profile where application_id = '<known-app-id>';"
   ```
   Confirm every proposed field renders non-null for a well-populated app.

2. **Profile-UI integration:** wire `vw_application_profile` into `ApplicationDetailDrawer` (replace today's ad-hoc assembly at `src/components/applications/ApplicationDetailDrawer.tsx`). Dev server check at http://localhost:5173.

3. **Narrative cache hit path:** trigger profile render, confirm `application_narrative_cache` rows written with `input_hash`, re-render with unchanged inputs and confirm no new Claude call (via Edge Function logs).

4. **RPC parity:** once `get_workspace_assessment_report_data` is implemented on top of the view, diff a single app's profile row against the per-app portion of the RPC output — they should match field-for-field for EXISTS/DERIVED fields.

5. **Security posture:** run `./docs-architecture/testing/security-posture-validation.sql` — view must be `security_invoker=true`, any new tables need RLS + audit triggers per CLAUDE.md.

6. **Schema checkpoint:** `npx tsc --noEmit` + pgTAP regression (`testing/pgtap-rls-coverage.sql`).

---

## 8. Critical Files for Implementation

| File | Role |
|---|---|
| `schema/nextgen-schema-current.sql` | Source of truth for existing columns. Verify every EXISTS claim before writing the migration. |
| `features/publish-assessment/architecture.md` | Owner of the RPC spec. Must be updated when the profile becomes the RPC's shape. |
| `core/application.md`, `core/deployment-profile.md`, `core/involved-party.md`, `core/portfolio-assignment.md` | Update after the schema change lands — these are the feature docs for the entities being extended. |
| `src/types/view-contracts.ts` (code repo) | Add `VwApplicationProfile` interface. Also fix the missing `vw_application_run_rate` interface while here. |
| `supabase/functions/ai-chat/tools.ts` (code repo) | The `application-detail` tool bundle (lines 1018–1196) is today's best reference for assembling an app's footprint. The new view replaces that assembly logic. |
| `src/components/applications/ApplicationDetailDrawer.tsx` (code repo) | Primary UI site for the profile. Evolve in place, don't fork. |
| `operations/new-table-checklist.md` | Follow for every new table (capabilities, data_domain_types, application_tech_debt, application_narrative_cache). |

---

## 9. Out of Scope for this Document

- Implementation sequencing (migrations, view DDL, RPC body) — this document maps the shape; a follow-up plan will sequence the build.
- UI design for the profile page layout — design work, separate session.
- Role-gated cost visibility (flagged in Block 9).
- `cost_trend` time-series modeling (deferred).
- Capability model governance (who can define capabilities per namespace) — needs separate brainstorm.
