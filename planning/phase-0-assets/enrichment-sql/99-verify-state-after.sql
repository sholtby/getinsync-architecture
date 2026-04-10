-- Chunk: 99-verify-state-after.sql
-- Purpose: Post-enrichment validation returned as ONE result set so the
--          Supabase SQL Editor shows every row in a single table. Diff
--          against 00-verify-state-before.sql to confirm every chunk
--          landed. READ-ONLY — no BEGIN/COMMIT, no mutations.
-- Preconditions: Run after chunks 01-06 (05 is optional).
-- Editor: Pure SQL — no psql meta-commands. Single trailing SELECT so
--         the Editor renders all verification rows (the Editor only
--         shows the LAST result set of a multi-statement query — see
--         CLAUDE.md Database Access rule).
-- Expected AFTER counts (when all mandatory chunks applied):
--   - 01: cad_app_contacts = 3; owner/primary_support/expert_contacts populated
--   - 02: both_dps_set = 3; unnamed_integrations = 0
--   - 03: fy2026_budgets_in_riverside = 5 (IT, Police, Fire, Public Works, Finance)
--   - 04: services_with_contract_ref = 3; services_with_end_date = 3
--   - 05 (optional): CAD PROD DP has data_center_id and server_name populated
--   - 06: CAD / Hexagon each gain 1 bundle; NG911 already has 1 pre-existing

-- =============================================================
-- Riverside enrichment — AFTER snapshot
-- =============================================================
WITH
ns AS (
  SELECT id, name, slug FROM namespaces
  WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
cad_row AS (
  SELECT id, owner, primary_support, expert_contacts,
         left(primary_use_case, 80) AS primary_use_case_preview
  FROM applications
  WHERE id = 'b1000006-0000-0000-0000-000000000006'
),
cad_ac AS (
  SELECT ac.role_type, c.display_name, c.email, ac.is_primary
  FROM application_contacts ac
  JOIN contacts c ON c.id = ac.contact_id
  WHERE ac.application_id = 'b1000006-0000-0000-0000-000000000006'
),
contacts_ns_count AS (
  SELECT count(*) AS n
  FROM contacts WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
riverside_ai AS (
  SELECT ai.id, ai.name AS integration_name, sa.name AS source_app, ta.name AS target_app,
         (ai.source_deployment_profile_id IS NOT NULL
          AND ai.target_deployment_profile_id IS NOT NULL) AS dp_aligned
  FROM application_integrations ai
  LEFT JOIN applications sa ON sa.id = ai.source_application_id
  LEFT JOIN applications ta ON ta.id = ai.target_application_id
  WHERE sa.workspace_id IN (
    SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  )
),
fy2026_budgets AS (
  SELECT w.name AS workspace_name, wb.fiscal_year, wb.budget_amount, wb.is_current
  FROM workspace_budgets wb
  JOIN workspaces w ON w.id = wb.workspace_id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND wb.fiscal_year = 2026
),
its_ns AS (
  SELECT * FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
its_contracted AS (
  SELECT name, annual_cost, contract_reference, contract_start_date, contract_end_date
  FROM its_ns
  WHERE contract_reference IS NOT NULL
),
cad_dp AS (
  SELECT dp.id, dp.name, dp.data_center_id, dc.name AS data_center_name, dp.server_name
  FROM deployment_profiles dp
  LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
  WHERE dp.id = 'b5000006-0000-0000-0000-000000000006'
),
showcase_apps(app_id) AS (
  VALUES
    ('b1000006-0000-0000-0000-000000000006'::uuid),
    ('b1000001-0000-0000-0000-000000000001'::uuid),
    ('b1000007-0000-0000-0000-000000000007'::uuid)
),
bundles AS (
  SELECT a.name AS app_name, dp.name AS bundle_name, dp.cost_recurrence,
         dp.annual_cost, o.name AS vendor, dp.contract_reference,
         dp.contract_end_date
  FROM deployment_profiles dp
  JOIN applications a ON a.id = dp.application_id
  LEFT JOIN organizations o ON o.id = dp.vendor_org_id
  WHERE dp.dp_type = 'cost_bundle'
    AND a.id IN (SELECT app_id FROM showcase_apps)
),
per_app AS (
  SELECT a.name AS app_name,
         count(dp.id)                                                                        AS cost_bundle_count,
         COALESCE(sum(dp.annual_cost) FILTER (WHERE dp.cost_recurrence = 'recurring'), 0)    AS recurring_bundle_total
  FROM applications a
  LEFT JOIN deployment_profiles dp
         ON dp.application_id = a.id AND dp.dp_type = 'cost_bundle'
  WHERE a.id IN (SELECT app_id FROM showcase_apps)
  GROUP BY a.name
),
view_rollup AS (
  SELECT application_name, deployment_profile_name,
         software_cost, service_cost, bundle_cost, total_cost
  FROM vw_deployment_profile_costs
  WHERE application_id IN (SELECT app_id FROM showcase_apps)
)
SELECT ord, section, details FROM (
  SELECT 0 AS ord, '00 namespace' AS section,
         jsonb_build_object('id', id, 'name', name, 'slug', slug) AS details
  FROM ns
  UNION ALL
  SELECT 1, '01 result — CAD showcase app fields',
         jsonb_build_object(
           'cad_app_contacts', (SELECT count(*) FROM cad_ac),
           'owner', owner, 'primary_support', primary_support,
           'expert_contacts', expert_contacts,
           'primary_use_case_preview', primary_use_case_preview,
           'riverside_contacts_total', (SELECT n FROM contacts_ns_count)
         )
  FROM cad_row
  UNION ALL
  SELECT 2, '01 result — CAD contact: ' || role_type,
         jsonb_build_object('display_name', display_name, 'email', email, 'is_primary', is_primary)
  FROM cad_ac
  UNION ALL
  SELECT 3, '02 result — integrations counts',
         jsonb_build_object(
           'total', count(*),
           'both_dps_set', count(*) FILTER (WHERE dp_aligned),
           'unnamed', count(*) FILTER (WHERE integration_name IS NULL OR integration_name = '')
         )
  FROM riverside_ai
  UNION ALL
  SELECT 4, '02 result — ' || COALESCE(integration_name, '(unnamed)'),
         jsonb_build_object('source', source_app, 'target', target_app, 'dp_aligned', dp_aligned)
  FROM riverside_ai
  UNION ALL
  SELECT 5, '03 result — fy2026 budgets count',
         jsonb_build_object('fy2026_budgets_in_riverside', count(*),
                            'total_budgeted', sum(budget_amount))
  FROM fy2026_budgets
  UNION ALL
  SELECT 6, '03 result — ' || workspace_name,
         jsonb_build_object('fiscal_year', fiscal_year, 'budget', budget_amount, 'is_current', is_current)
  FROM fy2026_budgets
  UNION ALL
  SELECT 7, '04 result — IT services contract coverage',
         jsonb_build_object(
           'services_with_contract', count(*) FILTER (WHERE contract_reference IS NOT NULL),
           'total_services', count(*),
           'unchanged_annual_cost_total', sum(annual_cost)
         )
  FROM its_ns
  UNION ALL
  SELECT 8, '04 result — ' || name,
         jsonb_build_object(
           'annual_cost', annual_cost,
           'contract_reference', contract_reference,
           'contract_start_date', contract_start_date,
           'contract_end_date', contract_end_date
         )
  FROM its_contracted
  UNION ALL
  SELECT 9, '05 result (optional) — CAD PROD DP ops fields',
         jsonb_build_object(
           'id', id, 'name', name,
           'data_center_id', data_center_id,
           'data_center_name', data_center_name,
           'server_name', server_name
         )
  FROM cad_dp
  UNION ALL
  SELECT 10, '06 result — bundle: ' || app_name || ' — ' || bundle_name,
         jsonb_build_object(
           'cost_recurrence', cost_recurrence, 'annual_cost', annual_cost,
           'vendor', vendor, 'contract_ref', contract_reference,
           'contract_end', contract_end_date
         )
  FROM bundles
  UNION ALL
  SELECT 11, '06 result — per-app: ' || app_name,
         jsonb_build_object('cost_bundle_count', cost_bundle_count,
                            'recurring_bundle_total', recurring_bundle_total)
  FROM per_app
  UNION ALL
  SELECT 12, '06 result — view: ' || application_name || ' / ' || deployment_profile_name,
         jsonb_build_object(
           'software_cost', software_cost, 'service_cost', service_cost,
           'bundle_cost', bundle_cost, 'total_cost', total_cost
         )
  FROM view_rollup
) x
ORDER BY ord, section;
