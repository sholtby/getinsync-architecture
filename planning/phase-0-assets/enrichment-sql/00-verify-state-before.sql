-- Chunk: 00-verify-state-before.sql
-- Purpose: Capture the pre-enrichment state of the City of Riverside demo
--          namespace as a single result set that the Supabase SQL Editor
--          can display in one shot. READ-ONLY — no BEGIN/COMMIT, no
--          INSERT/UPDATE/DELETE. Safe to run any time.
-- Preconditions: None. Run this before 01-06 to establish a baseline.
-- Namespace scope: City of Riverside demo (a1b2c3d4-e5f6-7890-abcd-ef1234567890)
-- Editor: Pure SQL — no psql backslash meta-commands. All baseline metrics
--         are returned by ONE trailing SELECT so the Editor shows every
--         row (the Editor only renders the LAST result set of a
--         multi-statement query — see CLAUDE.md Database Access rule).

-- =============================================================
-- Riverside enrichment — BEFORE snapshot (2026-04-10 baseline)
-- =============================================================
WITH
ns AS (
  SELECT id, name, slug
  FROM namespaces
  WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
cad_row AS (
  SELECT id, owner, primary_support, expert_contacts, primary_use_case
  FROM applications
  WHERE id = 'b1000006-0000-0000-0000-000000000006'
),
cad_ac AS (
  SELECT count(*) AS n
  FROM application_contacts
  WHERE application_id = 'b1000006-0000-0000-0000-000000000006'
),
contacts_ns AS (
  SELECT count(*) AS n
  FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
riverside_ai AS (
  SELECT ai.*
  FROM application_integrations ai
  JOIN applications sa ON sa.id = ai.source_application_id
  WHERE sa.workspace_id IN (
    SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  )
),
ws_budgets AS (
  SELECT w.name AS workspace_name, wb.fiscal_year, wb.budget_amount, wb.is_current
  FROM workspaces w
  LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id AND wb.fiscal_year = 2026
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
its_ns AS (
  SELECT *
  FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
its_top3 AS (
  SELECT name, annual_cost, contract_reference, contract_end_date
  FROM its_ns
  ORDER BY annual_cost DESC
  LIMIT 3
),
cad_dp AS (
  SELECT id, name, data_center_id, server_name,
         support_team_id, change_team_id, managing_team_id
  FROM deployment_profiles
  WHERE id = 'b5000006-0000-0000-0000-000000000006'
),
showcase_bundles AS (
  SELECT a.name AS app_name,
         count(dp.id)                                                                        AS cost_bundle_count,
         COALESCE(sum(dp.annual_cost) FILTER (WHERE dp.cost_recurrence = 'recurring'), 0)    AS recurring_bundle_total
  FROM applications a
  LEFT JOIN deployment_profiles dp
         ON dp.application_id = a.id AND dp.dp_type = 'cost_bundle'
  WHERE a.id IN (
    'b1000006-0000-0000-0000-000000000006',
    'b1000001-0000-0000-0000-000000000001',
    'b1000007-0000-0000-0000-000000000007'
  )
  GROUP BY a.name
)
SELECT ord, section, details FROM (
  SELECT 0 AS ord, '00 namespace' AS section,
         jsonb_build_object('id', id, 'name', name, 'slug', slug) AS details
  FROM ns
  UNION ALL
  SELECT 1, '01 baseline — CAD showcase app fields',
         jsonb_build_object(
           'cad_app_contacts',  (SELECT n FROM cad_ac),
           'owner',             owner,
           'primary_support',   primary_support,
           'expert_contacts',   expert_contacts,
           'primary_use_case',  primary_use_case,
           'riverside_contacts_total', (SELECT n FROM contacts_ns)
         )
  FROM cad_row
  UNION ALL
  SELECT 2, '02 baseline — integrations DP alignment',
         jsonb_build_object(
           'total_integrations', count(*),
           'both_dps_set', count(*) FILTER (
             WHERE source_deployment_profile_id IS NOT NULL
               AND target_deployment_profile_id IS NOT NULL),
           'unnamed_integrations', count(*) FILTER (WHERE name IS NULL OR name = '')
         )
  FROM riverside_ai
  UNION ALL
  SELECT 3, '03 baseline — fy2026 budgets counts',
         jsonb_build_object(
           'fy2026_budgets_in_riverside',
             (SELECT count(*) FROM ws_budgets WHERE fiscal_year = 2026)
         )
  UNION ALL
  SELECT 4, '03 baseline — ' || workspace_name,
         jsonb_build_object('fiscal_year', fiscal_year, 'budget', budget_amount, 'is_current', is_current)
  FROM ws_budgets
  UNION ALL
  SELECT 5, '04 baseline — IT services contract coverage',
         jsonb_build_object(
           'services_with_contract_ref', count(*) FILTER (WHERE contract_reference IS NOT NULL),
           'services_with_end_date',     count(*) FILTER (WHERE contract_end_date  IS NOT NULL),
           'total_services',             count(*),
           'annual_cost_total',          sum(annual_cost)
         )
  FROM its_ns
  UNION ALL
  SELECT 6, '04 baseline — top3 ' || name,
         jsonb_build_object('annual_cost', annual_cost,
                            'contract_reference', contract_reference,
                            'contract_end_date', contract_end_date)
  FROM its_top3
  UNION ALL
  SELECT 7, '05 baseline (optional) — CAD PROD DP ops fields',
         jsonb_build_object(
           'id', id, 'name', name,
           'data_center_id', data_center_id, 'server_name', server_name,
           'support_team_id', support_team_id,
           'change_team_id', change_team_id,
           'managing_team_id', managing_team_id
         )
  FROM cad_dp
  UNION ALL
  SELECT 8, '06 baseline — ' || app_name,
         jsonb_build_object('cost_bundle_count', cost_bundle_count,
                            'recurring_bundle_total', recurring_bundle_total)
  FROM showcase_bundles
) x
ORDER BY ord, section;
