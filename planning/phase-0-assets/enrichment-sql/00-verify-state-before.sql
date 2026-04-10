-- Chunk: 00-verify-state-before.sql
-- Purpose: Capture the pre-enrichment state of the City of Riverside demo namespace
--          so we can diff it against 99-verify-state-after.sql after each enrichment
--          chunk has been applied. This file is READ-ONLY — no BEGIN/COMMIT, no
--          INSERT/UPDATE/DELETE. Safe to run any time.
-- Preconditions: None. Run this before 01-06 to establish a baseline.
-- Namespace scope: City of Riverside demo (a1b2c3d4-e5f6-7890-abcd-ef1234567890)
-- Editor: Pure SQL — no psql backslash meta-commands. Safe to paste into the
--         Supabase SQL Editor in one go.

-- ============================================================
-- Riverside enrichment — BEFORE snapshot (2026-04-10 baseline)
-- ============================================================

-- Namespace sanity
SELECT id, name, slug
FROM namespaces
WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- --- Chunk 01 baseline: contacts on showcase app (Computer-Aided Dispatch) ---
SELECT
  '01 baseline — CAD showcase app fields' AS section,
  (SELECT count(*) FROM application_contacts WHERE application_id = 'b1000006-0000-0000-0000-000000000006') AS cad_app_contacts,
  (SELECT owner           FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_owner,
  (SELECT primary_support FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_primary_support,
  (SELECT expert_contacts FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_expert_contacts,
  (SELECT primary_use_case FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_primary_use_case;

SELECT
  '01 baseline — contacts in Riverside namespace' AS section,
  count(*) AS riverside_contacts_total
FROM contacts
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- --- Chunk 02 baseline: integrations DP alignment (9 total, expected 1 aligned) ---
SELECT
  '02 baseline — integrations DP alignment' AS section,
  count(*)                                                                              AS total_integrations,
  count(*) FILTER (WHERE ai.source_deployment_profile_id IS NOT NULL
                    AND ai.target_deployment_profile_id IS NOT NULL)                    AS both_dps_set,
  count(*) FILTER (WHERE ai.name IS NULL OR ai.name = '')                               AS unnamed_integrations
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
WHERE sa.workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- --- Chunk 03 baseline: workspace_budgets FY2026 (expected 2 of 18) ---
SELECT
  '03 baseline — FY2026 budget per workspace' AS section,
  w.name,
  wb.fiscal_year,
  wb.budget_amount,
  wb.is_current
FROM workspaces w
LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id AND wb.fiscal_year = 2026
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY w.name;

SELECT
  '03 baseline — total FY2026 budgets in Riverside' AS section,
  count(*) AS fy2026_budgets_in_riverside
FROM workspace_budgets wb
JOIN workspaces w ON w.id = wb.workspace_id
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND wb.fiscal_year = 2026;

-- --- Chunk 04 baseline: it_services contract data (expected 0 of 11) ---
SELECT
  '04 baseline — IT services contract coverage' AS section,
  count(*) FILTER (WHERE contract_reference IS NOT NULL) AS services_with_contract_ref,
  count(*) FILTER (WHERE contract_end_date  IS NOT NULL) AS services_with_end_date,
  count(*)                                               AS total_services
FROM it_services
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT
  '04 baseline — top 3 IT services by annual_cost' AS section,
  id, name, annual_cost, contract_reference, contract_end_date
FROM it_services
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY annual_cost DESC
LIMIT 3;

-- --- Chunk 05 baseline (OPTIONAL): CAD PROD DP operational fields ---
SELECT
  '05 baseline — CAD PROD DP ops fields' AS section,
  id, name, data_center_id, server_name, support_team_id, change_team_id, managing_team_id
FROM deployment_profiles
WHERE id = 'b5000006-0000-0000-0000-000000000006';

-- --- Chunk 06 baseline: cost_bundle DPs on CAD / Hexagon / NG911 showcase apps ---
SELECT
  '06 baseline — recurring cost bundles on showcase apps' AS section,
  a.name                                                                                     AS app_name,
  count(dp.id)                                                                               AS cost_bundle_count,
  COALESCE(sum(dp.annual_cost) FILTER (WHERE dp.cost_recurrence = 'recurring'), 0)           AS recurring_bundle_total
FROM applications a
LEFT JOIN deployment_profiles dp
       ON dp.application_id = a.id
      AND dp.dp_type        = 'cost_bundle'
WHERE a.id IN (
  'b1000006-0000-0000-0000-000000000006',  -- Computer-Aided Dispatch
  'b1000001-0000-0000-0000-000000000001',  -- Hexagon OnCall CAD/RMS
  'b1000007-0000-0000-0000-000000000007'   -- NG911 System
)
GROUP BY a.name
ORDER BY a.name;

-- BEFORE snapshot complete. Proceed to 01-06, then run 99-verify-state-after.sql.
