-- =============================================================================
-- PAID Framework Terminology Cleanup
-- Date: 2026-04-18
-- Author: Claude + Stuart
-- Branch: fix/paid-framework-terminology
--
-- PURPOSE
-- -------
-- The PAID APM framework acronym stands for:
--   P = Plan, A = Address, I = Ignore, D = Delay
--
-- Earlier work incorrectly introduced `improve` (for Ignore) and `divest`
-- (for Delay) into the CHECK constraint on deployment_profiles.paid_action
-- and into aggregation views. Compensating workarounds (dual-label CASE
-- expressions) were then added across the frontend and AI chat, cementing
-- the bug.
--
-- Live DB has ZERO rows storing 'improve' or 'divest' — see verification
-- at end. This chunk does:
--   1. Normalize mixed-case paid_action values to lowercase
--   2. Replace the CHECK constraint with the canonical 4-value set
--   3. Rename view columns improve_count -> ignore_count and
--      divest_count -> delay_count (ALTER VIEW ... RENAME COLUMN),
--      then replace view bodies to drop the dual-label fallbacks.
--
-- vw_explorer_detail is not rebuilt here: it passes paid_action through
-- as-is (no aggregation), so lowercase normalization is sufficient.
--
-- PREREQUISITE DEPENDENCY CHECK (already verified 2026-04-18):
--   No other views or rules depend on vw_dashboard_summary,
--   vw_dashboard_summary_scoped, or vw_dashboard_workspace_breakdown.
--   If that changes in the future, re-check before running a similar
--   column-rename chunk.
--
-- WHY ALTER VIEW ... RENAME COLUMN, NOT JUST CREATE OR REPLACE?
--   Postgres rejects CREATE OR REPLACE VIEW when column names differ
--   ("cannot change name of view column X to Y — use ALTER VIEW RENAME").
--   We therefore do the rename first, then REPLACE the body.
--
-- RUN INSTRUCTIONS
-- ----------------
-- Paste into Supabase SQL Editor (ca-central-1 project). The whole chunk
-- is wrapped in a transaction, so a mid-run failure rolls back cleanly.
-- Final verification SELECT uses CTE + UNION ALL + jsonb so all sections
-- render in one result set (SQL Editor only shows the last result).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Step 1: Normalize existing paid_action data to lowercase
-- -----------------------------------------------------------------------------
UPDATE deployment_profiles
   SET paid_action = lower(paid_action)
 WHERE paid_action IS NOT NULL
   AND paid_action <> lower(paid_action);

-- -----------------------------------------------------------------------------
-- Step 2: Replace CHECK constraint — drop the permissive 10-value version,
--         add the canonical 4-value lowercase-only version.
-- -----------------------------------------------------------------------------
ALTER TABLE deployment_profiles
  DROP CONSTRAINT IF EXISTS deployment_profiles_paid_action_check;

ALTER TABLE deployment_profiles
  ADD CONSTRAINT deployment_profiles_paid_action_check
  CHECK (
    paid_action IS NULL
    OR paid_action = ANY (ARRAY['plan', 'address', 'ignore', 'delay'])
  );

-- -----------------------------------------------------------------------------
-- Step 3: Rename the two mis-named columns on each of the 3 views.
--         ALTER VIEW ... RENAME COLUMN only changes the exposed column
--         name; the existing view body still references the old CTE alias.
--         Step 4 replaces the body with the correct references.
-- -----------------------------------------------------------------------------
ALTER VIEW vw_dashboard_summary
  RENAME COLUMN improve_count TO ignore_count;
ALTER VIEW vw_dashboard_summary
  RENAME COLUMN divest_count TO delay_count;

ALTER VIEW vw_dashboard_summary_scoped
  RENAME COLUMN improve_count TO ignore_count;
ALTER VIEW vw_dashboard_summary_scoped
  RENAME COLUMN divest_count TO delay_count;

ALTER VIEW vw_dashboard_workspace_breakdown
  RENAME COLUMN improve_count TO ignore_count;
ALTER VIEW vw_dashboard_workspace_breakdown
  RENAME COLUMN divest_count TO delay_count;

-- -----------------------------------------------------------------------------
-- Step 4a: Replace vw_dashboard_summary body
--   - Drop the ('ignore','improve') / ('delay','divest') dual-label filters
--   - Column names now align with the renamed view columns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_summary WITH (security_invoker = true) AS
WITH dp_base AS (
  SELECT
    w.namespace_id,
    w.id AS workspace_id,
    a.id AS application_id,
    dp.id AS dp_id,
    dp.tech_assessment_status,
    dp.tech_health,
    dp.tech_risk,
    dp.paid_action,
    dp.annual_licensing_cost,
    dp.annual_cost,
    dp.estimated_tech_debt
  FROM deployment_profiles dp
  JOIN applications a ON a.id = dp.application_id
  JOIN workspaces w ON w.id = dp.workspace_id
  WHERE a.operational_status = 'operational'
),
dp_agg AS (
  SELECT
    dp_base.namespace_id,
    count(DISTINCT dp_base.application_id) AS total_applications,
    count(DISTINCT dp_base.dp_id) AS total_dps,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'complete') AS assessed_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'in_progress') AS needs_profiling_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'not_started') AS not_started_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'plan')    AS plan_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'address') AS address_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'ignore')  AS ignore_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'delay')   AS delay_count,
    round(avg(dp_base.tech_health) FILTER (WHERE dp_base.tech_health IS NOT NULL), 1) AS avg_tech_health,
    COALESCE(sum(dp_base.annual_licensing_cost), 0::numeric) AS total_annual_licensing_cost,
    COALESCE(sum(dp_base.annual_cost), 0::numeric) AS total_annual_cost,
    COALESCE(sum(dp_base.estimated_tech_debt), 0::numeric) AS total_estimated_tech_debt
  FROM dp_base
  GROUP BY dp_base.namespace_id
),
pa_base AS (
  SELECT
    w.namespace_id,
    pa.id AS pa_id,
    pa.application_id,
    pa.deployment_profile_id,
    pa.time_quadrant,
    pa.business_fit,
    pa.criticality,
    pa.business_assessment_status
  FROM portfolio_assignments pa
  JOIN applications a ON a.id = pa.application_id
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE a.operational_status = 'operational'
),
pa_agg AS (
  SELECT
    pa_base.namespace_id,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'invest')    AS invest_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'tolerate')  AS tolerate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'modernize') AS modernize_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'eliminate') AS eliminate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE pa_base.criticality >= 50::numeric) AS crown_jewel_count,
    round(avg(pa_base.business_fit) FILTER (WHERE pa_base.business_fit IS NOT NULL), 1) AS avg_business_fit,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'complete')    AS business_assessed_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'in_progress') AS business_in_progress_count
  FROM pa_base
  GROUP BY pa_base.namespace_id
),
risk_agg AS (
  SELECT
    w.namespace_id,
    count(DISTINCT a.id) AS at_risk_count
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  LEFT JOIN portfolio_assignments pa ON pa.application_id = a.id AND pa.relationship_type = 'publisher'
  LEFT JOIN LATERAL (
    SELECT min(CASE tlr.lifecycle_status
                 WHEN 'end_of_support' THEN 1
                 ELSE 2
               END) AS worst_rank
    FROM vw_technology_tag_lifecycle_risk tlr
    WHERE tlr.application_id = a.id
      AND tlr.app_operational_status = 'operational'
  ) lc ON true
  WHERE a.operational_status = 'operational'
    AND (lower(pa.time_quadrant) = 'eliminate' OR lc.worst_rank = 1)
  GROUP BY w.namespace_id
)
SELECT
  d.namespace_id,
  COALESCE(d.total_applications, 0::bigint) AS total_applications,
  COALESCE(d.total_dps, 0::bigint) AS total_dps,
  COALESCE(d.assessed_count, 0::bigint) AS assessed_count,
  COALESCE(d.needs_profiling_count, 0::bigint) AS needs_profiling_count,
  COALESCE(d.not_started_count, 0::bigint) AS not_started_count,
  COALESCE(p.crown_jewel_count, 0::bigint) AS crown_jewel_count,
  COALESCE(p.invest_count, 0::bigint) AS invest_count,
  COALESCE(p.tolerate_count, 0::bigint) AS tolerate_count,
  COALESCE(p.modernize_count, 0::bigint) AS modernize_count,
  COALESCE(p.eliminate_count, 0::bigint) AS eliminate_count,
  COALESCE(r.at_risk_count, 0::bigint) AS at_risk_count,
  COALESCE(d.plan_count, 0::bigint) AS plan_count,
  COALESCE(d.address_count, 0::bigint) AS address_count,
  COALESCE(d.ignore_count, 0::bigint) AS ignore_count,
  COALESCE(d.delay_count, 0::bigint) AS delay_count,
  COALESCE(p.avg_business_fit, 0::numeric) AS avg_business_fit,
  COALESCE(d.avg_tech_health, 0::numeric) AS avg_tech_health,
  COALESCE(d.total_annual_licensing_cost, 0::numeric) AS total_annual_licensing_cost,
  COALESCE(d.total_annual_cost, 0::numeric) AS total_annual_cost,
  COALESCE(d.total_estimated_tech_debt, 0::numeric) AS total_estimated_tech_debt,
  COALESCE(p.business_assessed_count, 0::bigint) AS business_assessed_count,
  COALESCE(p.business_in_progress_count, 0::bigint) AS business_in_progress_count
FROM dp_agg d
FULL JOIN pa_agg p ON p.namespace_id = d.namespace_id
LEFT JOIN risk_agg r ON r.namespace_id = d.namespace_id;

-- -----------------------------------------------------------------------------
-- Step 4b: Replace vw_dashboard_summary_scoped body
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_summary_scoped WITH (security_invoker = true) AS
WITH dp_base AS (
  SELECT
    w.namespace_id,
    w.id AS workspace_id,
    a.id AS application_id,
    dp.id AS dp_id,
    dp.tech_assessment_status,
    dp.tech_health,
    dp.tech_risk,
    dp.paid_action,
    dp.annual_licensing_cost,
    dp.annual_cost,
    dp.estimated_tech_debt,
    dp.assessed_at
  FROM workspaces w
  JOIN applications a ON a.workspace_id = w.id
  JOIN deployment_profiles dp ON dp.application_id = a.id AND dp.workspace_id = w.id
  WHERE a.operational_status = 'operational'
),
dp_agg AS (
  SELECT
    dp_base.namespace_id,
    count(DISTINCT dp_base.application_id) AS total_applications,
    count(DISTINCT dp_base.dp_id) AS total_dps,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'complete')    AS assessed_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'in_progress') AS needs_profiling_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'not_started') AS not_started_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'plan')    AS plan_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'address') AS address_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'ignore')  AS ignore_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'delay')   AS delay_count,
    round(avg(dp_base.tech_health) FILTER (WHERE dp_base.tech_health IS NOT NULL), 1) AS avg_tech_health,
    COALESCE(sum(dp_base.annual_licensing_cost), 0::numeric) AS total_annual_licensing_cost,
    COALESCE(sum(dp_base.annual_cost), 0::numeric) AS total_annual_cost,
    COALESCE(sum(dp_base.estimated_tech_debt), 0::numeric) AS total_estimated_tech_debt,
    min(dp_base.assessed_at) AS oldest_tech_assessment,
    count(DISTINCT dp_base.dp_id) FILTER (
      WHERE dp_base.assessed_at IS NOT NULL
        AND dp_base.assessed_at < (now() - interval '180 days')
    ) AS stale_tech_count
  FROM dp_base
  GROUP BY dp_base.namespace_id
),
pa_base AS (
  SELECT
    w.namespace_id,
    pa.id AS pa_id,
    pa.application_id,
    pa.deployment_profile_id,
    pa.time_quadrant,
    pa.business_fit,
    pa.criticality,
    pa.business_assessment_status
  FROM workspaces w
  JOIN applications a ON a.workspace_id = w.id
  JOIN portfolio_assignments pa ON pa.application_id = a.id
  WHERE a.operational_status = 'operational'
),
pa_agg AS (
  SELECT
    pa_base.namespace_id,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'invest')    AS invest_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'tolerate')  AS tolerate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'modernize') AS modernize_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'eliminate') AS eliminate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE pa_base.criticality >= 50::numeric) AS crown_jewel_count,
    round(avg(pa_base.business_fit) FILTER (WHERE pa_base.business_fit IS NOT NULL), 1) AS avg_business_fit,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'complete')    AS business_assessed_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'in_progress') AS business_in_progress_count
  FROM pa_base
  GROUP BY pa_base.namespace_id
),
risk_agg AS (
  SELECT
    w.namespace_id,
    count(DISTINCT a.id) AS at_risk_count
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  LEFT JOIN portfolio_assignments pa ON pa.application_id = a.id AND pa.relationship_type = 'publisher'
  LEFT JOIN LATERAL (
    SELECT min(CASE tlr.lifecycle_status
                 WHEN 'end_of_support' THEN 1
                 ELSE 2
               END) AS worst_rank
    FROM vw_technology_tag_lifecycle_risk tlr
    WHERE tlr.application_id = a.id
      AND tlr.app_operational_status = 'operational'
  ) lc ON true
  WHERE a.operational_status = 'operational'
    AND (lower(pa.time_quadrant) = 'eliminate' OR lc.worst_rank = 1)
  GROUP BY w.namespace_id
)
SELECT
  d.namespace_id,
  COALESCE(d.total_applications, 0::bigint) AS total_applications,
  COALESCE(d.total_dps, 0::bigint) AS total_dps,
  COALESCE(d.assessed_count, 0::bigint) AS assessed_count,
  COALESCE(d.needs_profiling_count, 0::bigint) AS needs_profiling_count,
  COALESCE(d.not_started_count, 0::bigint) AS not_started_count,
  COALESCE(p.crown_jewel_count, 0::bigint) AS crown_jewel_count,
  COALESCE(p.invest_count, 0::bigint) AS invest_count,
  COALESCE(p.tolerate_count, 0::bigint) AS tolerate_count,
  COALESCE(p.modernize_count, 0::bigint) AS modernize_count,
  COALESCE(p.eliminate_count, 0::bigint) AS eliminate_count,
  COALESCE(r.at_risk_count, 0::bigint) AS at_risk_count,
  COALESCE(d.plan_count, 0::bigint) AS plan_count,
  COALESCE(d.address_count, 0::bigint) AS address_count,
  COALESCE(d.ignore_count, 0::bigint) AS ignore_count,
  COALESCE(d.delay_count, 0::bigint) AS delay_count,
  COALESCE(p.avg_business_fit, 0::numeric) AS avg_business_fit,
  COALESCE(d.avg_tech_health, 0::numeric) AS avg_tech_health,
  COALESCE(d.total_annual_licensing_cost, 0::numeric) AS total_annual_licensing_cost,
  COALESCE(d.total_annual_cost, 0::numeric) AS total_annual_cost,
  COALESCE(d.total_estimated_tech_debt, 0::numeric) AS total_estimated_tech_debt,
  COALESCE(p.business_assessed_count, 0::bigint) AS business_assessed_count,
  COALESCE(p.business_in_progress_count, 0::bigint) AS business_in_progress_count,
  d.oldest_tech_assessment,
  COALESCE(d.stale_tech_count, 0::bigint) AS stale_tech_count
FROM dp_agg d
FULL JOIN pa_agg p ON p.namespace_id = d.namespace_id
LEFT JOIN risk_agg r ON r.namespace_id = d.namespace_id;

-- -----------------------------------------------------------------------------
-- Step 4c: Replace vw_dashboard_workspace_breakdown body
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_workspace_breakdown WITH (security_invoker = true) AS
WITH dp_base AS (
  SELECT
    w.namespace_id,
    w.id AS workspace_id,
    w.name AS workspace_name,
    a.id AS application_id,
    dp.id AS dp_id,
    dp.tech_assessment_status,
    dp.tech_health,
    dp.tech_risk,
    dp.paid_action,
    dp.annual_licensing_cost,
    dp.annual_cost,
    dp.estimated_tech_debt
  FROM deployment_profiles dp
  JOIN applications a ON a.id = dp.application_id
  JOIN workspaces w ON w.id = dp.workspace_id
  WHERE a.operational_status = 'operational'
),
dp_agg AS (
  SELECT
    dp_base.namespace_id,
    dp_base.workspace_id,
    dp_base.workspace_name,
    count(DISTINCT dp_base.application_id) AS total_applications,
    count(DISTINCT dp_base.dp_id) AS total_dps,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'complete')    AS assessed_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'in_progress') AS needs_profiling_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.tech_assessment_status = 'not_started') AS not_started_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'plan')    AS plan_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'address') AS address_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'ignore')  AS ignore_count,
    count(DISTINCT dp_base.dp_id) FILTER (WHERE dp_base.paid_action = 'delay')   AS delay_count,
    round(avg(dp_base.tech_health) FILTER (WHERE dp_base.tech_health IS NOT NULL), 1) AS avg_tech_health,
    COALESCE(sum(dp_base.annual_licensing_cost), 0::numeric) AS total_annual_licensing_cost,
    COALESCE(sum(dp_base.annual_cost), 0::numeric) AS total_annual_cost,
    COALESCE(sum(dp_base.estimated_tech_debt), 0::numeric) AS total_estimated_tech_debt
  FROM dp_base
  GROUP BY dp_base.namespace_id, dp_base.workspace_id, dp_base.workspace_name
),
pa_base AS (
  SELECT
    w.namespace_id,
    w.id AS workspace_id,
    pa.id AS pa_id,
    pa.application_id,
    pa.deployment_profile_id,
    pa.time_quadrant,
    pa.business_fit,
    pa.criticality,
    pa.business_assessment_status
  FROM portfolio_assignments pa
  JOIN applications a ON a.id = pa.application_id
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE a.operational_status = 'operational'
),
pa_agg AS (
  SELECT
    pa_base.namespace_id,
    pa_base.workspace_id,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'invest')    AS invest_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'tolerate')  AS tolerate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'modernize') AS modernize_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.time_quadrant) = 'eliminate') AS eliminate_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE pa_base.criticality >= 50::numeric) AS crown_jewel_count,
    round(avg(pa_base.business_fit) FILTER (WHERE pa_base.business_fit IS NOT NULL), 1) AS avg_business_fit,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'complete')    AS business_assessed_count,
    count(DISTINCT pa_base.application_id) FILTER (WHERE lower(pa_base.business_assessment_status) = 'in_progress') AS business_in_progress_count
  FROM pa_base
  GROUP BY pa_base.namespace_id, pa_base.workspace_id
),
risk_agg AS (
  SELECT
    w.namespace_id,
    w.id AS workspace_id,
    count(DISTINCT a.id) AS at_risk_count
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  LEFT JOIN portfolio_assignments pa ON pa.application_id = a.id AND pa.relationship_type = 'publisher'
  LEFT JOIN LATERAL (
    SELECT min(CASE tlr.lifecycle_status
                 WHEN 'end_of_support' THEN 1
                 ELSE 2
               END) AS worst_rank
    FROM vw_technology_tag_lifecycle_risk tlr
    WHERE tlr.application_id = a.id
      AND tlr.app_operational_status = 'operational'
  ) lc ON true
  WHERE a.operational_status = 'operational'
    AND (lower(pa.time_quadrant) = 'eliminate' OR lc.worst_rank = 1)
  GROUP BY w.namespace_id, w.id
)
SELECT
  d.namespace_id,
  d.workspace_id,
  d.workspace_name,
  COALESCE(d.total_applications, 0::bigint) AS total_applications,
  COALESCE(d.total_dps, 0::bigint) AS total_dps,
  COALESCE(d.assessed_count, 0::bigint) AS assessed_count,
  COALESCE(d.needs_profiling_count, 0::bigint) AS needs_profiling_count,
  COALESCE(d.not_started_count, 0::bigint) AS not_started_count,
  COALESCE(p.crown_jewel_count, 0::bigint) AS crown_jewel_count,
  COALESCE(p.invest_count, 0::bigint) AS invest_count,
  COALESCE(p.tolerate_count, 0::bigint) AS tolerate_count,
  COALESCE(p.modernize_count, 0::bigint) AS modernize_count,
  COALESCE(p.eliminate_count, 0::bigint) AS eliminate_count,
  COALESCE(r.at_risk_count, 0::bigint) AS at_risk_count,
  COALESCE(d.plan_count, 0::bigint) AS plan_count,
  COALESCE(d.address_count, 0::bigint) AS address_count,
  COALESCE(d.ignore_count, 0::bigint) AS ignore_count,
  COALESCE(d.delay_count, 0::bigint) AS delay_count,
  COALESCE(p.avg_business_fit, 0::numeric) AS avg_business_fit,
  COALESCE(d.avg_tech_health, 0::numeric) AS avg_tech_health,
  COALESCE(d.total_annual_licensing_cost, 0::numeric) AS total_annual_licensing_cost,
  COALESCE(d.total_annual_cost, 0::numeric) AS total_annual_cost,
  COALESCE(d.total_estimated_tech_debt, 0::numeric) AS total_estimated_tech_debt,
  COALESCE(p.business_assessed_count, 0::bigint) AS business_assessed_count,
  COALESCE(p.business_in_progress_count, 0::bigint) AS business_in_progress_count
FROM dp_agg d
FULL JOIN pa_agg p ON p.namespace_id = d.namespace_id AND p.workspace_id = d.workspace_id
LEFT JOIN risk_agg r ON r.namespace_id = d.namespace_id AND r.workspace_id = d.workspace_id;

COMMIT;

-- =============================================================================
-- CONSOLIDATED VERIFICATION (single result set — SQL Editor shows only last)
-- Expected:
--   - Section 1: constraint definition lists exactly plan/address/ignore/delay
--   - Section 2: only lowercase canonical values, no 'Improve'/'Divest'
--   - Section 3: each view exposes ignore_count + delay_count (improve/divest columns gone)
-- =============================================================================
WITH
  constraint_def AS (
    SELECT pg_get_constraintdef(oid) AS def
    FROM pg_constraint
    WHERE conname = 'deployment_profiles_paid_action_check'
  ),
  action_counts AS (
    SELECT paid_action, count(*) AS n
    FROM deployment_profiles
    WHERE paid_action IS NOT NULL
    GROUP BY paid_action
  ),
  view_cols AS (
    SELECT table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name IN ('vw_dashboard_summary','vw_dashboard_summary_scoped','vw_dashboard_workspace_breakdown')
      AND column_name IN ('ignore_count','delay_count','improve_count','divest_count')
  )
SELECT ord, section, details FROM (
  SELECT 1 AS ord,
         'constraint definition' AS section,
         jsonb_build_object('def', def) AS details
  FROM constraint_def
  UNION ALL
  SELECT 2,
         'paid_action distribution (expect only plan/address/ignore/delay, all lowercase)',
         jsonb_build_object('paid_action', paid_action, 'n', n)
  FROM action_counts
  UNION ALL
  SELECT 3,
         'view columns (expect ignore_count + delay_count per view; improve/divest absent)',
         jsonb_build_object('view', table_name, 'column', column_name)
  FROM view_cols
) x
ORDER BY ord, section, details::text;
