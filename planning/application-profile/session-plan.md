# Application Profile Tier 1 — Session Plan

**Version:** v1.2
**Status:** 🟡 AS-DESIGNED
**Last updated:** 2026-04-16
**Authoring context:** Session plan for the Application Profile Tier 1 build. Depends on `features/application-profile/schema-mapping.md` v1.0 for the field-by-field schema mapping. Each session below is a 2–4 hour Claude Code sitting with a clear entry/exit.

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.2 | 2026-04-16 | **Plan-status tracking added to Tier 1.** Four new columns on `portfolio_assignments` — `has_plan boolean NULLABLE` (tri-state: null=not yet asked, false=explicitly no plan, true=plan documented), `plan_note text`, `plan_document_url text`, `planned_remediation_date date` — capture workshop-surfaced information about whether an application has a documented plan. Session 1 adds the columns. Session 2 projects them in `vw_application_profile`. Session 3 adds them to `VwApplicationProfile`. Session 5 renders them as a "Response Plan" sub-section of Block 7 (Lifecycle Position) with inline edit capability. **NEW Session 5b** adds a post-completion capture panel to `PortfolioAssessmentWizard.tsx` (deferrable to Tier 1.5). Session 6 updates the Publish Assessment RPC spec to include plan status in the per-app profile shape and documents EA Handoff auto-finding patterns (e.g., "N Eliminate apps have no plan"). Plan status does NOT affect PAID derivation — it contextualizes PAID, not scores it. |
| v1.1 | 2026-04-16 | **(a) Application Categories pulled into Tier 1.** `application_categories` taxonomy + `application_category_assignments` junction already exist (namespace-scoped, full coverage for Riverside). Session 2 adds `category_names jsonb` to `vw_application_profile`. Session 3 adds the field to the TS interface. Session 5 renders it as tag chips in Block 2 (Business Purpose). Capabilities remain a Tier 2 placeholder — categories answer "what type of software" (ERP, GIS, ANALYTICS); capabilities will answer "what business function it enables." Different concepts, both belong in Block 2. **(b) Session 5 subcomponent extraction is now mandatory** (not "possibly"). Eleven blocks in one file will cross the 800-line threshold; extract up front. New `src/components/applications/profile/` directory with one component per block; `ApplicationDetailDrawer.tsx` becomes a thin orchestrator (<400 lines). |
| v1.0 | 2026-04-16 | Initial session plan — 6 sessions, bundled #86/#87/#94 Phase 1 schema into Session 1, #97 into Session 3. |

---

## Tier 1 Scope (recap)

Tier 1 delivers the **data plumbing and UI consumption** for the Application Profile, without the AI narrative generation pipeline and without the new Tier 2 concept tables (capabilities, data domains, tech debt items).

In scope:
- Schema additions to `applications`, `application_integrations`, `application_contacts.role_type` CHECK constraint, and `portfolio_assignments` (plan-status columns)
- New `application_narrative_cache` table (structure only — no generation pipeline yet)
- `vw_application_profile` view — includes `category_names jsonb` aggregate from existing `application_category_assignments` + `application_categories` tables, plus plan-status passthrough from `portfolio_assignments`
- `VwApplicationProfile` TypeScript interface
- Evolve `ApplicationDetailDrawer.tsx` into a thin orchestrator + one block component per profile section under `src/components/applications/profile/`
- Plan-status capture: four new columns on `portfolio_assignments` (`has_plan`, `plan_note`, `plan_document_url`, `planned_remediation_date`), rendered in the drawer's Block 7 (Lifecycle Position) as a "Response Plan" sub-section with inline edit; included in the Publish Assessment RPC's per-app profile shape
- Architecture-doc updates (publish-assessment RPC alignment, application.md, MANIFEST)

Explicitly out of scope for Tier 1 (deferred to Tier 2+):
- `capabilities` + `application_capabilities` tables (Feature Roadmap Tier 2) — distinct from categories; answers "what business function it enables"
- `data_domain_types` + `application_data_domains` tables
- `application_tech_debt` table
- AI narrative generation (Edge Function that populates the cache)
- Renaming `application_contacts.role_type='technical_owner'` → `application_owner` (requires data migration of existing rows)
- `cost_trend` time-series (deferred — no historical cost data exists)
- Role-gated cost visibility on the profile

---

## Section 1 — Session Plan

### Session 1: Schema Migration + Data Cleanup

**Scope**
Apply the complete Tier 1 schema delta in one SQL-Editor session, gated by data-quality cleanup of pre-existing title-case legacy values that would otherwise make the post-migration validation fail.

**Files touched**
- `supabase/migrations/` (code repo) — migration SQL
- `docs-architecture/schema/nextgen-schema-current.sql` — refresh the backup after migration applies
- `docs-architecture/testing/security-posture-validation.sql` — bump table/policy/trigger sentinels (106 → 107 tables, policies +4, audit triggers +1)
- `docs-architecture/testing/pgtap-rls-coverage.sql` — extend for `application_narrative_cache` RLS assertions

**Concrete changes (SQL lanes)**
1. Data cleanup (must run first so validators pass):
   - `UPDATE deployment_profiles SET paid_action = lower(paid_action) WHERE paid_action IN ('Plan','Address','Ignore','Delay');` (**bundles #86**)
   - `UPDATE portfolio_assignments SET business_assessment_status = 'not_started' WHERE business_assessment_status = 'Not Started';` (**bundles #87**)
2. `applications` columns: `acronym text`, `business_outcome text`, `target_state text`, `cost_notes text`, `user_groups jsonb`, `estimated_user_count text` (CHECK in `('<10','10-100','100-1000','1000+')`)
3. `application_integrations` columns: `business_purpose text` (AP) + `lifecycle_start_date date`, `lifecycle_end_date date`, `sftp_required boolean`, `sftp_host text`, `sftp_credentials_status text` (**bundles #94 Phase 1 schema**)
3b. `portfolio_assignments` columns (plan-status tracking): `has_plan boolean NULLABLE` (tri-state: null = not yet asked, false = explicitly no plan, true = plan documented), `plan_note text`, `plan_document_url text`, `planned_remediation_date date`. No CHECK constraints — `has_plan` uses NULL semantics intentionally; the other three are free text / date. No reference table needed.
4. `application_contacts.role_type` CHECK constraint: drop and re-add with `accountable_executive` added to the allowed values list
5. New table `application_narrative_cache` per `operations/new-table-checklist.md`:
   - Columns: `id uuid PK`, `namespace_id uuid NOT NULL FK`, `application_id uuid NOT NULL FK`, `deployment_profile_id uuid FK NULLABLE`, `narrative_key text CHECK IN ('plain_language_summary','business_impact','integration_summary','time_paid_tension','remediation_summary','remediation_alignment')`, `content text`, `generated_at timestamptz`, `input_hash text`, `approved boolean DEFAULT false`, `approved_by uuid FK users`, `approved_at timestamptz`, `created_at`, `updated_at`
   - UNIQUE `(application_id, deployment_profile_id, narrative_key)` (DP-nullable — use `COALESCE`-indexed unique via `CREATE UNIQUE INDEX` on two expressions)
   - GRANTs: `SELECT, INSERT, UPDATE, DELETE TO authenticated`
   - RLS: namespace-scoped `SELECT` for all, `INSERT/UPDATE/DELETE` for admin+editor; platform admin bypass in every policy
   - Triggers: `update_updated_at`, `audit_log_trigger`

**Open Items bundled**
- **#86** (legacy title-case `paid_action`, 11 rows) — `deployment_profiles` touched anyway, 15 min cleanup, closes the data-quality-validation §casing FAIL.
- **#87** (legacy title-case `business_assessment_status`, 33 rows) — `portfolio_assignments` touched anyway, 15 min cleanup, closes the §assessment FAIL.
- **#94 Phase 1 schema additions** (lifecycle_start_date/end_date, sftp_* columns) — `application_integrations` is already being touched to add `business_purpose`; the schema portions of #94 Phase 1 ride the same migration. #94 Phase 1 *UI work* (notes/sla rendering in `AddConnectionModal`) does **not** bundle here — it lands in a separate session since it's not `ApplicationDetailDrawer`.

**Prerequisites**
- CLAUDE.md PAID terminology rule acknowledged (commit `7f51786` on `main`).
- `schema-mapping.md` v1.0 on `main` as the authoritative field list.
- No in-flight branches touching `applications`, `application_integrations`, or `application_contacts` schemas (confirmed — no merge conflicts).

**Exit criteria**
1. `psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/security-posture-validation.sql` → zero FAIL rows.
2. `psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/pgtap-rls-coverage.sql` → all assertions pass, including new ones for `application_narrative_cache`.
3. `psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/data-quality-validation.sql` → §casing:paid_action and §assessment:business_assessment_status PASS.
4. `npx tsc --noEmit` → zero errors (no app code changed, but sanity check).
5. `SELECT count(*) FROM information_schema.columns WHERE table_name IN ('applications','application_integrations','application_contacts','portfolio_assignments');` confirms new columns across all four tables, including the four plan-status columns on `portfolio_assignments`.
6. `SELECT conrelid::regclass, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname ~ 'role_type';` confirms `accountable_executive` in the CHECK.
7. Manually insert a test row into `application_narrative_cache` as a namespace admin → succeeds; as a viewer → blocked.
8. Schema stats updated in `security-posture-validation.sql` and `MEMORY.md`: tables 106→107, RLS policies +4, audit triggers +1.

**Effort estimate:** 2–2.5 hrs (most of it is Stuart running chunked SQL in the SQL Editor plus validator runs).

**Committable state at end:** yes — new schema is additive and has no consumers yet. Safe to land on `main` in the architecture repo and on a feature branch in the code repo.

---

### Session 2: `vw_application_profile` View

**Scope**
Design, deploy, and verify `vw_application_profile` — the single projection that backs both the UI drawer and the Publish Assessment RPC.

**Files touched**
- `docs-architecture/features/application-profile/vw_application_profile.sql` (new — SQL source of truth, applied via SQL Editor)
- `docs-architecture/features/application-profile/schema-mapping.md` — update status to "view deployed"
- `docs-architecture/schema/nextgen-schema-current.sql` — refresh backup (views 42 → 43)
- `docs-architecture/testing/security-posture-validation.sql` — bump views sentinel to 43, confirm `security_invoker = true`

**Concrete changes**
- Base joins: `applications a` + primary `deployment_profiles dp` (where `is_primary=true`) + `portfolio_assignments pa` (publisher row) + `namespaces ns` + `workspaces w`.
- Aggregated columns:
  - `integration_count`, `upstream_count`, `downstream_count`, `critical_integration_count` from `vw_application_integration_summary`.
  - `linked_initiative_count`, `remediation_status_rollup` (`in_progress` if any linked initiative is `in_progress`; `planned` if any `planned`/`identified`; else `none_planned`) from `initiative_deployment_profiles` + `initiatives`.
  - `estimated_remediation_cost_low`, `estimated_remediation_cost_high` from summed `initiatives.one_time_cost_low`/`_high`.
  - `latest_assessed_at` = `greatest(dp.assessed_at, pa.business_assessed_at)`.
  - `assessment_completeness_rollup` computed from `dp.tech_assessment_status` + `pa.business_assessment_status`.
  - `category_names jsonb` — array of `{category_code, category_name}` objects, one entry per category assigned to the app. Source: `application_category_assignments` junction → `application_categories` reference table (namespace-scoped, filter `is_active = true`, order by `display_order`). Follow the pattern already used in [src/components/dashboard/DashboardPage.tsx:79](src/components/dashboard/DashboardPage.tsx:79) (`application_category_assignments` select with nested `category:application_categories(...)`); SQL-side, aggregate with `jsonb_agg(jsonb_build_object('category_code', ac.code, 'category_name', ac.name) ORDER BY ac.display_order) FILTER (WHERE ac.id IS NOT NULL)` in a LEFT JOIN so apps with no categories yield `'[]'::jsonb` instead of NULL.
  - `has_plan`, `plan_note`, `plan_document_url`, `planned_remediation_date` — passthrough from `portfolio_assignments` (publisher row). The view surfaces the tri-state `has_plan` directly; downstream consumers decide how to bucket null vs false (e.g., `COUNT(*) FILTER (WHERE has_plan = true)` for "apps with documented plans", `COUNT(*) FILTER (WHERE has_plan IS NOT TRUE)` for "apps where a plan has not been confirmed").
- Derived flag columns:
  - `is_crown_jewel` = `pa.criticality >= 50`.
  - `near_threshold_flag` = any of (`business_fit`, `tech_health`, `criticality`, `tech_risk`) within 5 of the namespace-scoped threshold in `assessment_thresholds`.
  - `time_paid_tension_flag` = deterministic rule (e.g., `(time_quadrant = 'tolerate' AND paid_action = 'address')` OR other conflict cases).
- Primary contact pulls: `owner_contact_id`, `owner_name`, `accountable_executive_contact_id`, `accountable_executive_name`, `technical_contact_id`, `technical_contact_name` — each via subquery on `application_contacts` filtered by `role_type` and `is_primary = true`.
- Lookup fallbacks: `business_purpose` on integrations falls back to `name` when null; profile itself surfaces the chosen value.
- `CREATE VIEW ... WITH (security_invoker = true)` + `GRANT SELECT ON vw_application_profile TO authenticated;`
- NOT included in this session: individual narrative text (Tier 2) — the view has a `narrative_last_generated_at` aggregate but does not join `application_narrative_cache` content (that's fetched separately by the hook, since cache is per-narrative-key and the view stays row-per-application).

**Open Items bundled**
None — the view is net-new and doesn't overlap open matrix items beyond what Session 1 already covered.

**Prerequisites**
- Session 1 merged (schema columns exist).

**Exit criteria**
1. `SELECT * FROM vw_application_profile WHERE application_id = '<known-good>'` returns a well-populated row with all flag columns non-null.
2. `SELECT security_invoker FROM pg_views WHERE viewname = 'vw_application_profile'` → `true`.
3. Run a query as a viewer on a namespace with restricted access → RLS-inherited result set is properly limited.
4. Security-posture validator passes with views sentinel at 43.
5. `EXPLAIN ANALYZE` on a 500-app workspace completes in under 500 ms (rough bar — indexes already in place on the join columns).

**Effort estimate:** 2.5–3 hrs (view SQL is meaty; a couple of iterations on derived-column logic).

**Committable state at end:** yes — view is queryable but no consumer reads it yet. Safe standalone commit.

---

### Session 3: TypeScript Interfaces + View-Contract Cleanup

**Scope**
Declare `VwApplicationProfile` in `view-contracts.ts`, fix two pre-existing view-contract gaps flagged during prior exploration, and optionally split `src/types/index.ts`.

**Files touched**
- `src/types/view-contracts.ts` — add `VwApplicationProfile`, add missing `VwApplicationRunRate`, fix `ServerTechnologyReportRow`.
- Optionally `src/types/index.ts` → split into `src/types/deployment-profiles.ts`, `src/types/servers.ts` (**#96** — only if sizing still argues for it after the rest lands).

**Concrete changes**
1. New interface `VwApplicationProfile` — field-for-field match to `vw_application_profile` columns. Include all 40+ fields; strict types (`string | null`, `number | null` as appropriate). Include `category_names` as `Array<{ category_code: string; category_name: string }>` (non-null — empty array when the app has no categories, per the view's COALESCE to `'[]'::jsonb`). Include plan-status fields: `has_plan: boolean | null`, `plan_note: string | null`, `plan_document_url: string | null`, `planned_remediation_date: string | null` (ISO date string — use `string` not `Date` to match the raw view output).
2. New interface `VwApplicationRunRate` — matches `vw_application_run_rate` (used in `supabase/functions/ai-chat/tools.ts` today without a type declaration).
3. `ServerTechnologyReportRow`: remove `workspace_id`, `workspace_name` (they don't exist in the underlying view) — **closes #97**.
4. Optional: `index.ts` split when (a) it's still past 800 lines after other Tier 1 work lands, and (b) refactoring doesn't touch interfaces being added in Sessions 4–5. Otherwise defer to its own session.

**Open Items bundled**
- **#97** (`ServerTechnologyReportRow` mismatch) — 5 min, same file, no reason to ship it separately.
- **#96** (`index.ts` refactor) — optional; only if it fits without risking Session 4/5 type imports.
- Implicit: `vw_application_run_rate` missing interface — noted in `schema-mapping.md` §Block 9, cleanup-of-opportunity while touching the file.

**Prerequisites**
- Session 2 merged (view deployed, column list finalized).

**Exit criteria**
1. `npx tsc --noEmit` → zero errors.
2. `VwApplicationProfile` exported from `src/types/view-contracts.ts` and imports resolve.
3. `ServerTechnologyReportRow` callers still compile (component was already adapted per #97 notes).
4. If #96 included: `src/types/index.ts` splits land with no changes to external import paths (barrel re-export from `index.ts` preserves public API).

**Effort estimate:** 1–1.5 hrs (2 hrs if #96 included).

**Committable state at end:** yes — types are additive; no runtime behavior changes.

---

### Session 4: Hooks (`useApplicationProfile` + `useApplicationNarrativeCache`)

**Scope**
Create the hooks that the UI will consume. No component integration yet — Session 5 wires them up.

**Files touched**
- `src/hooks/useApplicationProfile.ts` (new)
- `src/hooks/useApplicationNarrativeCache.ts` (new)
- `src/hooks/__tests__/` (if the repo has hook tests — skim first; if none today, don't introduce a test harness unilaterally).

**Concrete changes**
1. `useApplicationProfile(applicationId)` — selects `* FROM vw_application_profile WHERE application_id = $1`. Returns `{ data: VwApplicationProfile | null, loading, error, refetch }`. Uses the existing Supabase query pattern (match `useApplicationDetail.ts`).
2. `useApplicationNarrativeCache(applicationId)` — selects all narrative rows for an app, groups by `narrative_key`. Returns `{ narratives: Record<NarrativeKey, CachedNarrative | null>, loading, error, refetch }` where `NarrativeKey` is the 6-value union. Exposes `updateNarrative(key, content, inputHash)` and `approveNarrative(key)` mutations. Does NOT call the generation Edge Function (that's Tier 2).
3. Input-hash helper in the hook: `computeNarrativeInputHash(profile, key)` — deterministic string hash (e.g., JSON of the subset of fields that drive each narrative_key) so the UI can display "stale, regenerate" badges.

**Open Items bundled**
None — these are net-new hooks for a new concept.

**Prerequisites**
- Session 3 merged (types available).

**Exit criteria**
1. `npx tsc --noEmit` → zero errors.
2. Hooks can be imported in a throwaway test component and return data against a known application.
3. Narrative mutation path: inserting a `plain_language_summary` via the hook, refetching, and rendering the new content works against the dev DB.

**Effort estimate:** 1.5 hrs.

**Committable state at end:** yes — hooks exist and compile; no component renders them yet.

---

### Session 5: `ApplicationDetailDrawer` Evolution

**Scope**
Evolve the existing drawer to render every Block 1–11 field from the profile. Do not fork into a new component — per `schema-mapping.md` §8, we evolve in place.

**Files touched**
- `src/components/applications/ApplicationDetailDrawer.tsx` — refactored into a thin orchestrator. Target: well under 400 lines. Responsibilities: call hooks, pass sliced data to block components, handle loading/error/close states.
- **New directory: `src/components/applications/profile/`** — one file per block (mandatory, not optional). Files to create:
  - `IdentityBlock.tsx`
  - `BusinessPurposeBlock.tsx`
  - `UserCommunityBlock.tsx` (render `user_groups` + `estimated_user_count` + serving areas; no inline placeholder workaround)
  - `InformationDomainsBlock.tsx` — one-liner Tier 2 placeholder; inline in the drawer if a full file is gratuitous, but otherwise keep parallel structure
  - `OwnershipBlock.tsx`
  - `CriticalityBlock.tsx`
  - `LifecyclePositionBlock.tsx`
  - `ApplicationContextBlock.tsx`
  - `CostSummaryBlock.tsx`
  - `TechDebtBlock.tsx`
  - `AssessmentContextBlock.tsx`
- Each block component receives its data via props: the relevant slice of `VwApplicationProfile` plus, where applicable, the matching `CachedNarrative | null` from `useApplicationNarrativeCache`. Blocks do NOT call hooks themselves — the drawer orchestrates. This keeps blocks pure, easy to test, and easy to storybook later.
- `src/hooks/useApplicationDetail.ts` — reconcile with new `useApplicationProfile` hook. Recommend: keep `useApplicationDetail` for non-profile data (costs, servers) and combine in the drawer. Cost aggregation still uses `vw_deployment_profile_costs` per DP, not the profile view.

**Concrete changes**
1. Create `src/components/applications/profile/` directory and extract block components up front — do not start by growing the existing drawer. Each block gets one file per the list above.
2. `ApplicationDetailDrawer.tsx` becomes the orchestrator: calls `useApplicationProfile(applicationId)`, `useApplicationNarrativeCache(applicationId)`, and existing cost/server hooks; passes props into block components; handles loading/error/empty states; wires close/back buttons. Aim for <400 lines.
3. Render each block per `schema-mapping.md`:
   - **Block 1 Identity** (`IdentityBlock`): name + acronym (parenthetical if present), operational_status badge, plain_language_summary (from cache if approved; fallback to `short_description`; empty-state CTA otherwise).
   - **Block 2 Business Purpose** (`BusinessPurposeBlock`): **`business_outcome`** as a text block (empty-state CTA if not set) **and `category_names`** rendered as tag chips using `category_name` for the label and `category_code` for the tooltip/aria-label. Always render the category chips when the array is non-empty (full Riverside coverage already exists). Do **not** show a "Not yet mapped" placeholder for categories. Below the category chips, render a small "Capabilities — coming in Tier 2" placeholder to signal the related-but-distinct concept. Categories = *what type of software this is* (ERP, GIS, ANALYTICS). Capabilities = *what business function it enables* (case management, financial reporting). Both belong here; categories ship now, capabilities later.
   - **Block 3 User Community** (`UserCommunityBlock`): user_groups JSONB rendered as tag chips, estimated_user_count bucket, serving_areas from `branch`.
   - **Block 4 Information Domains** (inline placeholder — no separate file for a one-liner): "Information domain tagging coming in Tier 2."
   - **Block 5 Ownership** (`OwnershipBlock`): four contact roles pulled from the view's join columns. Role badges. Link to edit.
   - **Block 6 Criticality** (`CriticalityBlock`): criticality_score, crown_jewel badge, business_impact_statement from cache with empty-state.
   - **Block 7 Lifecycle Position** (`LifecyclePositionBlock`): time_quadrant + paid_action (**use Plan/Address/Delay/Ignore — never Improve/Divest**), worst_lifecycle_status, time_paid_tension_flag visual cue + narrative from cache. **New "Response Plan" sub-section** rendering the four plan-status fields:
     - `has_plan = null` → grey "Plan status: not yet asked" placeholder with a CTA to capture
     - `has_plan = false` → amber "No plan" badge; show `plan_note` if present as "context"
     - `has_plan = true` → green "Plan documented" badge; show `plan_note`, a link to `plan_document_url` using the established `<a target="_blank" rel="noopener noreferrer">` pattern, and `planned_remediation_date` if set
     - Inline edit capability: clicking the sub-section opens a small edit form writing all four fields to `portfolio_assignments` via a new `useUpdatePortfolioPlan(portfolioAssignmentId)` mutation hook.
     - Tier 2 enhancement (deferred): when `has_plan = true` but no `initiative_deployment_profiles` row exists for this app's DP, surface a "Link an initiative?" prompt. Deferred because the initiative-to-DP linkage isn't fully rendered in the drawer in Tier 1 — that's Block 10 Tier 2 scope.
   - **Block 8 Context** (`ApplicationContextBlock`): upstream/downstream integration lists with business_purpose edge labels (fallback to integration.name); integration_summary narrative from cache. Visual diagram — keep current `vw_integration_detail` 1-hop rendering.
   - **Block 9 Cost** (`CostSummaryBlock`): four cost lines + TCO from existing cost hooks; cost_notes text block. No role gating this session.
   - **Block 10 Tech Debt & Remediation** (`TechDebtBlock`): remediation_status_rollup badge, linked initiative count, estimated_remediation_cost ROM range, target_state text, remediation_summary + remediation_alignment narratives from cache. Tech debt ITEMS list — "Item-level tech debt coming in Tier 2" placeholder.
   - **Block 11 Assessment Context** (`AssessmentContextBlock`): four scores with near-threshold indicators, last_assessed_date, assessment_completeness_rollup badge.
4. Narrative empty-states: show "No summary yet. [Generate] button" as a placeholder. The Generate button is disabled with a tooltip "Narrative generation ships in Tier 2." (Tier 2 wires the Edge Function.)
5. Verify: dev server at `http://localhost:5173`, open drawer on a well-populated app, then a bare app, then a crown-jewel app — no regressions, all blocks render, categories chip row shows. Each block file stays focused (<150 lines each is a reasonable soft target).

**Open Items bundled**
None directly. (#94 Phase 1 *UI* work in `AddConnectionModal` is a related but separate drawer/modal — bundle it into a later integration-specific session, not here.)

**Prerequisites**
- Session 4 merged (hooks available).

**Exit criteria**
1. Dev server renders every block with real data for at least 3 test apps (one fully populated, one sparse, one crown jewel).
2. Existing drawer users (clicks from Explorer, Dashboard, Visual tab) still work — no regressions.
3. `preview_snapshot` + `preview_screenshot` of the drawer captured and shared.
4. `npx tsc --noEmit` clean.
5. No use of `alert()` / `confirm()`; toasts for errors; loading states for fetches.

**Effort estimate:** 3–4 hrs.

**Committable state at end:** yes — ships the full UI. Tier 2 is purely additive (generation + new catalogs).

---

### Session 5b (optional, deferrable to Tier 1.5): Wizard Plan Capture Panel

**Scope**
Add a post-completion summary card to `PortfolioAssessmentWizard.tsx` that appears after both the Business and Technical assessments reach `complete`. Captures plan-status fields inline with the assessment flow so the data gets created during the workshop rather than as a follow-up edit in the drawer.

**Files touched**
- `src/components/PortfolioAssessmentWizard.tsx` — new summary card component after the Save panel (~lines 720–740).
- `src/hooks/useUpdatePortfolioPlan.ts` — reused from Session 5 (mutation hook is shared; this session does not create a new hook).

**Concrete changes**
1. When `business_assessment_status === 'complete'` AND `tech_assessment_status === 'complete'`, render a "Plan status" card below the wizard's current Save area.
2. Card fields: tri-state toggle (Yes / No / Unknown mapped to `true` / `false` / `null` for `has_plan`), textarea for `plan_note`, URL input for `plan_document_url` (basic URL format validation), date picker for `planned_remediation_date`.
3. Save writes to `portfolio_assignments` via the same `useUpdatePortfolioPlan` mutation hook used by the drawer's inline edit in Session 5. No new backend surface.
4. Reuse the textarea control pattern already used for `cost_allocation_notes` on the same table — same column type, same edit semantics.
5. Toast on save success/failure per CLAUDE.md error handling rules.

**Open Items bundled**
None.

**Prerequisites**
- Session 5 merged (shared mutation hook `useUpdatePortfolioPlan` exists).

**Exit criteria**
1. Completing a portfolio assessment in the wizard with both tabs at `complete` reveals the plan-status card.
2. Saving the card persists the four fields to `portfolio_assignments`; re-opening the wizard shows the persisted values.
3. The drawer's Block 7 Response Plan sub-section reflects the same values (round-trip through `vw_application_profile`).
4. `npx tsc --noEmit` clean.

**Effort estimate:** ~1 hr.

**Committable state at end:** yes — additive to the wizard; does not disturb existing assessment flow.

---

### Session 6: Doc Alignment + Publish-Assessment RPC Reshape

**Scope**
Close the loop: update architecture docs to reflect what shipped, reshape the Publish Assessment RPC spec so the profile is the canonical per-app shape.

**Files touched**
- `docs-architecture/features/publish-assessment/architecture.md` — §Step 1 rewritten so `get_workspace_assessment_report_data` is "`vw_application_profile` projection + workspace aggregates + assessment_detail block for raw factor values." Fix T14/T15 references (`schema-mapping.md` §6 flag).
- `docs-architecture/features/application-profile/schema-mapping.md` — status 🟡 → 🟢 for Tier 1 fields (others stay 🟡); add "Tier 1 shipped 2026-MM-DD" note; add pointer to this session plan; note that `category_names` was added to Block 2 (Business Purpose) in Tier 1 by consuming the existing `application_categories` taxonomy.
- `docs-architecture/core/application.md` — add new columns.
- `docs-architecture/core/deployment-profile.md` — cross-reference profile view.
- `docs-architecture/core/involved-party.md` — document `accountable_executive` role.
- `docs-architecture/catalogs/application-categories.md` (if present) — cross-reference that the profile view now surfaces category names.
- `docs-architecture/guides/user-help/` — update any user-help article whose app-detail section is now different (per CLAUDE.md §6h).
- `docs-architecture/guides/whats-new.md` — append entry (note category chips on the drawer as a visible user-facing change).
- `docs-architecture/MANIFEST.md` — version bump, changelog entry, any new doc files listed.

**Open Items bundled**
None (doc-only).

**Prerequisites**
- Session 5 shipped to dev.

**Exit criteria**
1. `get_workspace_assessment_report_data` spec documents three layers: (a) workspace aggregates, (b) per-app `profile` matching `vw_application_profile`, (c) per-app `assessment_detail` with B1–B10 / T01–T15 factor values and per-namespace factor labels.
2. The Publish Assessment spec's §System Prompt Strategy continues to use canonical PAID (Plan / Address / Delay / Ignore).
3. T14/T15 ambiguity in publish-assessment/architecture.md resolved — all references say T01–T15.
4. MANIFEST changelog entry describes: Tier 1 shipped + publish-assessment spec realigned to consume profile view.
5. `grep -ri "Improve\|Divest" docs-architecture/` finds zero new occurrences.

**Effort estimate:** 1–1.5 hrs.

**Committable state at end:** yes — docs only.

---

## Section 2 — Open Items Cross-Reference

| Item # | Item Name | Relationship | Action |
|---|---|---|---|
| **#86** | Legacy title-case `deployment_profiles.paid_action` (11 rows) | **bundle** | Session 1, SQL step 1a. Same table as profile schema migration; 15-min cleanup closes data-quality-validation §casing FAIL. |
| **#87** | Legacy title-case `portfolio_assignments.business_assessment_status` (33 rows) | **bundle** | Session 1, SQL step 1b. Same rationale as #86. |
| **#94** | Integration Field Parity Phase 1 (schema: lifecycle/sftp fields) | **bundle (schema only)** | Session 1, SQL step 1d. `application_integrations` is already being touched for `business_purpose`. Phase 1 UI (notes/sla rendering in `AddConnectionModal.tsx`) is a separate session — NOT bundled with Session 5 (that's the drawer, not the modal). |
| **#96** | `src/types/index.ts` split (818 lines) | **overlap (optional)** | Session 3, optional. Do only if it fits without risking Session 4–5 type imports. Otherwise defer. |
| **#97** | `ServerTechnologyReportRow` view-contract mismatch | **bundle** | Session 3. Same file as `VwApplicationProfile`; 5 min. |
| **Business Capability** (Feature Roadmap Tier 2) | Capability model with tag-based app mapping | **future** | Defer to Tier 2. Schema-mapping §Block 2 left `capability_mappings[]` as NEW-STORED pending a Tier 2 session. |
| **Application Relationships (Suites)** (Feature Roadmap Tier 2) | Suite/family schema on `applications` | **future** | Defer to Tier 2. Would add `suite_id` etc. to `applications` — coordinate with Tier 2 to avoid double-migration. |
| **#18** | Power BI Export Layer (6 vw_pbi_* views) | **future** | Flag only. Power BI views should probably consume `vw_application_profile` once stable — capture in the Phase 1 deployment notes for #18 when it's picked up. |
| **#7** | `users.is_super_admin` → `is_platform_admin()` design debt | **defer** | Not related to Application Profile. Defer. |
| **#57** | Scope indicator (N of M workspaces) | **defer** | Header UX; no file overlap. Defer. |
| **#64** | Namespace Management UI completion | **defer** | Admin UI; no overlap. Defer. |
| **#65** | Budget Alerts frontend | **defer** | Cost module; DB done; no overlap with drawer. Defer. |
| **#66** | Assessment Tour (S.6) | **defer** | Onboarding UX; no overlap. Defer. |
| **#68** | `VwIntegrationDetail` DP columns | **dependency — already satisfied** | Closed Apr 4. Tier 1 depends on it for upstream/downstream rendering; the dependency is already met. |
| **#93** | Multi-Server DP (Phases 1–4 complete) | **dependency — already satisfied** | Closed Apr 12. Tier 1 surfaces server info in Block 8 via existing `vw_application_infrastructure_report` joins. |
| **#49** | DROP CHECK constraints on `application_integrations` (redundant vs. reference tables) | **overlap (coordinate)** | Session 1 will add NEW CHECK constraints on new columns. Coordinate with #49: any new CHECK should match the reference-table approach if that direction is taken — or use text columns without CHECK where a reference table is intended. Flag for Stuart during Session 1 planning. |
| **#88** | `ai-chat/index.ts` size refactor | **defer** | Unrelated to profile; separate refactor track. |
| **#51** | Surface Technology Health on App Detail | **overlap (future)** | Not bundled. Session 5 already surfaces `tech_health` score in Block 11. If #51 designs a richer tech-health subview for the drawer, coordinate with Session 5 outputs. |
| **#74** | Lifecycle Diagram (dual timeline) | **future** | Not bundled. Likely Tier 2+ UI feature. |
| **Code-repo PAID violations** (noted in commit `7f51786`) | `tools.ts` enum, `system-prompt.ts` legacy note, `DerivedScoresTab.tsx`, `apm-chat/index.ts`, `vw_dashboard_summary.improve_count/.divest_count` columns, `deployment_profiles_paid_action_check` tightening | **separate session** | Not bundled with Tier 1. These need sequencing with a data migration that purges any remaining lowercase `improve`/`divest` values. Queue as "PAID hygiene" session after Tier 1 Session 1 confirms data quality passes. |

---

## Section 3 — Sequencing

### Dependency graph

```
Session 1 (Schema + data cleanup, includes plan-status columns)
    |
    v
Session 2 (vw_application_profile view, projects plan-status passthrough)
    |
    v
Session 3 (TypeScript interfaces + #97 fix, includes plan-status fields)
    |
    v
Session 4 (Hooks)
    |
    v
Session 5 (ApplicationDetailDrawer evolution, renders Response Plan in Block 7)
    |    \
    |     v
    |   Session 5b (OPTIONAL, deferrable to Tier 1.5): Wizard plan capture panel
    |
    v
Session 6 (Doc alignment + publish-assessment RPC reshape + EA Handoff auto-findings)
```

Sessions 1–6 remain **strictly serial** — each consumes the output of the previous. Session 5b is a branch off Session 5 that can ship in parallel with Session 6 (different files: 5b touches the wizard; 6 touches architecture docs) or be deferred to Tier 1.5 without blocking the rest.

### Branch strategy

- Recommended: one long-lived feature branch `feat/application-profile-tier-1` off `dev`, with each session = one or two commits on that branch, until Session 6 completes. Then merge to `dev`, bump CalVer (CLAUDE.md rule), merge to `main`.
- Architecture-repo commits always land on `main` per CLAUDE.md Dual-Repo Commits rule — no branching needed there.
- Session 1 and Session 2 apply SQL via SQL Editor (Stuart-applied); the migration text is committed to `supabase/migrations/` on the feature branch.

### Known conflict risk

**None identified.** Matrix review confirms:
- No in-flight branches touch `applications`, `application_integrations`, `application_contacts`, or `deployment_profiles` schemas.
- Multi-server DP (#93) and Integration-DP alignment (#67) are already merged to `main` — both are prerequisites for Tier 1, and both are satisfied.
- The parked `feat/visual-tab-reactflow` branch is pending integration-DP alignment (now unblocked) — if Stuart resumes it in parallel, it touches `core/visual-diagram.md` and Visual tab components, not the drawer. No conflict.

### Suggested cadence

- Session 1 standalone sitting (2–2.5 hrs, heavy SQL).
- Sessions 2 + 3 can sit back-to-back in one day (combined ~4 hrs).
- Session 4 standalone (1.5 hrs).
- Session 5 standalone sitting (3–4 hrs, heaviest UI work).
- Session 6 standalone (1–1.5 hrs).

Total Tier 1 effort: ~13–15 hours across 5 sittings (including ~80 min of plan-status additions distributed across Sessions 1/2/3/5/6). Add ~1 hr if Session 5b is included in Tier 1 rather than deferred to Tier 1.5.

---

## Section 4 — Publish Assessment RPC Alignment

The Publish Assessment RPC (`get_workspace_assessment_report_data`) is specified but unshipped. Tier 1 delivers the `vw_application_profile` view that the RPC should consume. Alignment happens in **Session 6**, doc-side only:

1. **Session 6** rewrites `docs-architecture/features/publish-assessment/architecture.md` §Step 1 so the RPC description reads:
   > "The RPC returns a three-layer JSON: (1) `workspace_aggregates` — TIME/PAID distribution counts, Crown Jewel count, assessment completion stats, publishing user; (2) `applications[]` — each entry is a row from `vw_application_profile` projected to JSONB (the canonical Application Profile shape, shared with the UI drawer); (3) `applications[].assessment_detail` — raw B1–B10 and T01–T15 factor values plus namespace-scoped factor labels from `assessment_factors` (needed for the PDF factor tables; not surfaced in the UI drawer)."
2. **Session 6** fixes the T14/T15 ambiguity in the same doc (several places say "T01–T14"; schema has T01–T15).
3. **Future (post-Tier-1) session** implements the RPC itself. It becomes thin: `SELECT jsonb_build_object('aggregates', (...aggregates SELECT...), 'applications', (SELECT jsonb_agg(row_to_json(p)) FROM vw_application_profile p WHERE p.workspace_id = $1), 'applications_assessment_detail', (...factor-values SELECT...))`.
3a. **The per-app `profile` block includes plan status.** Since `vw_application_profile` exposes `has_plan`, `plan_note`, `plan_document_url`, `planned_remediation_date` after Session 2, the RPC picks them up automatically once it projects the view. Additionally, the RPC's workspace-aggregate block should expose plan-coverage counts per quadrant (e.g., `eliminate_apps_without_plan_count`, `modernize_apps_with_target_date_count`, `address_apps_with_plan_no_initiative_count`) so the Edge Function doesn't need to re-count. The EA Handoff section should auto-generate findings like "N of M Eliminate applications have no documented plan — governance review recommended" and "N Modernize applications have plans targeting FY2027; M have no target date." Session 6 documents these patterns as examples the Edge Function's system prompt can generate.
4. **Snapshot alignment (future):** when `assessment_history.snapshot_data` is written on publish, include the current `application_narrative_cache` rows AND the plan-status values for each app — so the snapshot is immutable regardless of future cache invalidation or plan edits. This is a Tier 2 concern (lands when generation pipeline lands).

No Tier 1 session implements the RPC itself — that stays deferred. Tier 1 only aligns the **spec** so the shape is ready when the RPC is built.

---

## Self-Review Notes

- **Scope coverage:** Every field in `schema-mapping.md` §1 that is marked NEW-STORED (Tier 1 subset) or requires a view column is covered by Sessions 1–2. NEW-AI fields are covered at the cache-table level (Session 1) and the UI placeholder level (Session 5); actual generation is explicitly Tier 2.
- **PAID terminology:** Only canonical Plan / Address / Delay / Ignore used throughout. Session 5 Block 7 notes this explicitly; Session 6 closes the spec-side gap.
- **New-table checklist:** Session 1 exit criteria include every step from `operations/new-table-checklist.md` §1–§5 for `application_narrative_cache`.
- **Committability:** Each session exit leaves the code in a working state. Additions only — no destructive migrations, no "half-built" UI.
- **Unbundled items flagged up front:** #94 UI (modal), #49 CHECK constraint strategy, code-repo PAID hygiene — all noted with clear rationale for exclusion.
