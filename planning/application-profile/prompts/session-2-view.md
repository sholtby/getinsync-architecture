# Session 2: `vw_application_profile` View

**Effort:** 2.5–3 hrs. **Prerequisite:** Session 1 merged and validated. **Committable:** yes — view exists but no consumer yet.

## Goal

Design, deploy, and verify `vw_application_profile` — the single projection that backs both the UI drawer (Session 5) and the Publish Assessment RPC (Session 6). This is the atomic-unit data shape of the platform.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` §Section 1 Session 2 — full concrete-changes list.
2. `docs-architecture/features/application-profile/schema-mapping.md` v1.1 — field-by-field mapping. Every EXISTS / DERIVED / RELATIONSHIP row becomes a column or a derived column in this view.
3. `docs-architecture/schema/nextgen-schema-current.sql` — verify every column referenced below actually exists with the type expected (especially the Session 1 additions).
4. `src/components/dashboard/DashboardPage.tsx:79` — pattern to reuse for `application_category_assignments` + `application_categories` join.
5. `src/hooks/useVisualGraphData.ts:109` — pattern for upstream/downstream integration aggregation.
6. `supabase/functions/ai-chat/tools.ts` lines 1018–1196 — the existing "application-detail" bundle, today's best reference for how we assemble an app.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** The view must not emit `Improve` or `Divest` in any text column (e.g., if you construct a derived label).
- **`WITH (security_invoker = true)`** on the view — non-negotiable. RLS inheritance from base tables is how we maintain access control.
- Stuart applies the view SQL via Supabase SQL Editor; you author the file and hand it off.

## Concrete changes

### Write the SQL file

Author `docs-architecture/features/application-profile/vw_application_profile.sql` (new file). The view columns must cover **every Tier 1 field** in the mapping doc. Structure:

```sql
CREATE OR REPLACE VIEW vw_application_profile
WITH (security_invoker = true) AS
SELECT
  -- Identity (Block 1)
  a.id                                AS application_id,
  a.namespace_id,
  a.workspace_id,
  a.name                              AS application_name,
  a.acronym,
  a.short_description,
  -- future: plain_language_summary (from narrative cache, fetched separately by UI hook)
  a.operational_status,
  a.management_classification,        -- missing-from-proposal; surface per schema-mapping §5
  a.csdm_stage,
  a.is_internal_only,
  -- Business Purpose (Block 2)
  a.business_outcome,
  -- Categories (NEW in v1.1) — jsonb aggregate, never null
  COALESCE(cats.category_names, '[]'::jsonb) AS category_names,
  -- User Community (Block 3)
  a.user_groups,
  a.estimated_user_count,
  a.branch                            AS serving_area,
  -- Ownership (Block 5) — four contact roles
  bo.contact_id                       AS business_owner_contact_id,
  bo.display_name                     AS business_owner_name,
  ao.contact_id                       AS application_owner_contact_id,
  ao.display_name                     AS application_owner_name,
  ae.contact_id                       AS accountable_executive_contact_id,
  ae.display_name                     AS accountable_executive_name,
  tc.contact_id                       AS technical_contact_id,
  tc.display_name                     AS technical_contact_name,
  -- Criticality (Block 6)
  pa.criticality,
  (pa.criticality >= 50)              AS is_crown_jewel,
  -- Lifecycle Position (Block 7)
  pa.time_quadrant,
  dp.paid_action,
  a.lifecycle_status,
  -- derived tension flag (deterministic rule)
  CASE
    WHEN pa.time_quadrant = 'tolerate' AND dp.paid_action = 'address' THEN true
    WHEN pa.time_quadrant = 'invest'   AND dp.paid_action = 'ignore'  THEN true
    WHEN pa.time_quadrant = 'eliminate' AND dp.paid_action = 'plan'   THEN true
    ELSE false
  END                                 AS time_paid_tension_flag,
  -- Response Plan (NEW in v1.2 — from portfolio_assignments)
  pa.has_plan,
  pa.plan_note,
  pa.plan_document_url,
  pa.planned_remediation_date,
  -- Application Context (Block 8) — integration counts
  COALESCE(ints.upstream_count, 0)       AS upstream_count,
  COALESCE(ints.downstream_count, 0)     AS downstream_count,
  COALESCE(ints.integration_count, 0)    AS integration_count,
  COALESCE(ints.critical_integration_count, 0) AS critical_integration_count,
  -- Cost (Block 9) — from primary DP + linked channels; TCO via existing vw_application_run_rate
  dp.annual_licensing_cost,
  dp.annual_tech_cost,
  rr.total_run_rate                   AS total_cost_of_ownership,
  a.cost_notes,
  -- Tech Debt & Remediation (Block 10)
  dp.tech_debt_description,
  dp.remediation_effort,
  COALESCE(inits.linked_initiative_count, 0) AS linked_initiative_count,
  inits.remediation_status_rollup,
  inits.estimated_remediation_cost_low,
  inits.estimated_remediation_cost_high,
  a.target_state,
  -- Assessment Context (Block 11)
  pa.business_fit,
  dp.tech_health,
  dp.tech_risk,
  -- near-threshold: within 5 points of the namespace's configured thresholds
  threshold_check(pa.business_fit, pa.criticality, dp.tech_health, dp.tech_risk, a.namespace_id) AS near_threshold_flag,
  GREATEST(dp.assessed_at, pa.business_assessed_at) AS latest_assessed_at,
  CASE
    WHEN dp.tech_assessment_status = 'complete' AND pa.business_assessment_status = 'complete' THEN 'complete'
    WHEN dp.tech_assessment_status != 'not_started' OR pa.business_assessment_status != 'not_started' THEN 'partial'
    ELSE 'not_started'
  END                                 AS assessment_completeness_rollup,
  dp.assessed_at,
  pa.business_assessed_at,
  -- Primary DP location fields (per schema-mapping §5 recommendations)
  dp.id                               AS primary_deployment_profile_id,
  dp.environment,
  dp.hosting_type,
  dp.cloud_provider,
  dp.region,
  dp.dr_status,
  dp.server_name,
  dp.data_center_id,
  dp.contract_end_date,
  dp.renewal_notice_days,
  dp.vendor_org_id
FROM applications a
LEFT JOIN deployment_profiles dp
  ON dp.application_id = a.id AND dp.is_primary = true AND dp.dp_type = 'application'
LEFT JOIN portfolio_assignments pa
  ON pa.application_id = a.id AND pa.relationship_type = 'publisher'
-- Categories aggregate
LEFT JOIN LATERAL (
  SELECT jsonb_agg(jsonb_build_object('category_code', ac.code, 'category_name', ac.name) ORDER BY ac.display_order)
           FILTER (WHERE ac.id IS NOT NULL) AS category_names
  FROM application_category_assignments aca
  JOIN application_categories ac ON ac.id = aca.category_id AND ac.is_active = true
  WHERE aca.application_id = a.id
) cats ON true
-- Ownership contact joins (one LATERAL per role, pulling primary first)
LEFT JOIN LATERAL (
  SELECT c.id AS contact_id, c.display_name
  FROM application_contacts ac
  JOIN contacts c ON c.id = ac.contact_id
  WHERE ac.application_id = a.id AND ac.role_type = 'business_owner'
  ORDER BY ac.is_primary DESC, ac.created_at ASC
  LIMIT 1
) bo ON true
-- Repeat pattern for ao (technical_owner), ae (accountable_executive), tc (sme OR support, pick primary)
-- ...
-- Integration aggregate
LEFT JOIN LATERAL (
  SELECT
    COUNT(*) AS integration_count,
    COUNT(*) FILTER (WHERE source_application_id = a.id) AS downstream_count,
    COUNT(*) FILTER (WHERE target_application_id = a.id) AS upstream_count,
    COUNT(*) FILTER (WHERE criticality = 'critical') AS critical_integration_count
  FROM application_integrations
  WHERE source_application_id = a.id OR target_application_id = a.id
) ints ON true
-- Initiative aggregate (via DP junction)
LEFT JOIN LATERAL (
  SELECT
    COUNT(DISTINCT i.id) AS linked_initiative_count,
    CASE
      WHEN MAX(CASE WHEN i.status = 'in_progress' THEN 1 ELSE 0 END) = 1 THEN 'in_progress'
      WHEN MAX(CASE WHEN i.status IN ('planned','identified') THEN 1 ELSE 0 END) = 1 THEN 'planned'
      WHEN MAX(CASE WHEN i.status = 'completed' THEN 1 ELSE 0 END) = 1 THEN 'completed'
      ELSE 'none_planned'
    END AS remediation_status_rollup,
    SUM(i.one_time_cost_low) AS estimated_remediation_cost_low,
    SUM(i.one_time_cost_high) AS estimated_remediation_cost_high
  FROM initiative_deployment_profiles idp
  JOIN initiatives i ON i.id = idp.initiative_id
  WHERE idp.deployment_profile_id = dp.id
) inits ON true
-- TCO
LEFT JOIN vw_application_run_rate rr ON rr.application_id = a.id;

GRANT SELECT ON vw_application_profile TO authenticated;
```

**Notes for your authoring:**
- The `threshold_check(...)` helper doesn't exist yet — you have two options: (a) inline the logic in the view with a `CROSS JOIN LATERAL (SELECT thresholds FROM assessment_thresholds WHERE namespace_id = a.namespace_id)` + CASE expression, or (b) create a small SECURITY INVOKER SQL function `threshold_check()` as part of this session. Option (a) keeps the surface smaller — recommended.
- The four contact-role LATERAL joins are repetitive. Inline them — this is a view, not a programming language. Keep the SQL linear.
- `time_paid_tension_flag`: the tension matrix is simplified above. Before shipping, confirm with Stuart which quadrant pairs count as tension — the inline CASE is editable. `core/time-paid-methodology.md` does NOT currently specify this matrix (see schema-mapping §6 and publish-assessment architecture §System Prompt Strategy).

### Dry-run the view

Against `$DATABASE_READONLY_URL` before handing to Stuart:

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -c "$(cat docs-architecture/features/application-profile/vw_application_profile.sql)"
```

This will fail because read-only — that's expected. But the SQL parse must succeed; any syntax error aborts with `ERROR:`.

### Files to update in the architecture repo after Stuart applies

1. `docs-architecture/schema/nextgen-schema-current.sql` — refresh backup (views 42 → 43).
2. `docs-architecture/testing/security-posture-validation.sql` — bump views sentinel to 43.
3. `docs-architecture/features/application-profile/schema-mapping.md` — status note: "view deployed".
4. `docs-architecture/MANIFEST.md` — bump + changelog entry.

## Exit criteria

1. `psql "$DATABASE_READONLY_URL" -c "SELECT * FROM vw_application_profile WHERE application_id = '<known-good-app-id>';"` returns a populated row — every flag column non-null, `category_names` non-null (array or `[]`), four contact-role name columns populated or clearly null.
2. `psql "$DATABASE_READONLY_URL" -c "SELECT security_invoker FROM pg_views WHERE viewname = 'vw_application_profile';"` → `true`.
3. Query the view as a namespace viewer (switch `current_user` or use a JWT with restricted role) and confirm the result set respects RLS on base tables.
4. Security-posture validator passes with views sentinel at 43.
5. `EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM vw_application_profile WHERE workspace_id = '<500-app workspace>';` completes in under 500 ms. If slower, examine index usage on the LATERAL subqueries — most commonly missing indexes on `application_contacts.role_type` or `application_category_assignments.application_id`.
6. `npx tsc --noEmit` in the code repo — still zero errors (no code changes, sanity check).

## Git

- **Architecture repo:** commit the new `vw_application_profile.sql`, updated schema backup, and MANIFEST bump to `main`. Dual-repo rule applies.
- **Code repo:** nothing committed this session — view exists in the DB but no TypeScript reads it until Session 3.

## Stuck?

- If a LATERAL subquery is awkward, try a CTE-based rewrite (they're semantically equivalent). The view does not need to be "optimal" — it needs to be correct and under 500 ms on typical workspaces.
- `vw_application_run_rate` interface is missing in `src/types/view-contracts.ts` today (flagged in schema-mapping §Block 9). Don't fix that here — Session 3 does.
