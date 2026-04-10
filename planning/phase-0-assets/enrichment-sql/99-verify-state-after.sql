-- Chunk: 99-verify-state-after.sql
-- Purpose: Post-enrichment validation. Runs the same SELECTs as
--          00-verify-state-before.sql so you can diff the two outputs and
--          confirm every chunk landed. READ-ONLY — no BEGIN/COMMIT, no
--          mutations. Safe to run any time.
-- Preconditions: Run after chunks 01-06 (05 is optional).
-- Expected AFTER counts (when all mandatory chunks applied):
--   - Chunk 01: cad_app_contacts = 3 ; applications.owner/primary_support/expert_contacts populated
--   - Chunk 02: both_dps_set = 3 ; unnamed_integrations = 0
--   - Chunk 03: fy2026_budgets_in_riverside = 5 (IT, Police, Fire, Public Works, Finance)
--   - Chunk 04: services_with_contract_ref = 3 ; services_with_end_date = 3
--   - Chunk 05 (optional): CAD PROD DP has data_center_id and server_name populated
--   - Chunk 06: cost_bundle_count for CAD = 1, Hexagon = 1, NG911 = 1 (pre-existing)
--              recurring_bundle_total: CAD = 85000, Hexagon = 110000, NG911 = 180000

\echo '================================================================'
\echo 'Riverside enrichment — AFTER snapshot'
\echo '================================================================'

-- Namespace sanity
SELECT id, name, slug
FROM namespaces
WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

\echo ''
\echo '--- Chunk 01 result: contacts on showcase app (expect 3 rows) ---'
SELECT
  (SELECT count(*) FROM application_contacts WHERE application_id = 'b1000006-0000-0000-0000-000000000006') AS cad_app_contacts,
  (SELECT owner            FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_owner,
  (SELECT primary_support  FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_primary_support,
  (SELECT expert_contacts  FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_expert_contacts,
  (SELECT left(primary_use_case, 80) FROM applications WHERE id = 'b1000006-0000-0000-0000-000000000006') AS cad_use_case_preview;

SELECT ac.role_type, c.display_name, c.email, ac.is_primary
FROM application_contacts ac
JOIN contacts c ON c.id = ac.contact_id
WHERE ac.application_id = 'b1000006-0000-0000-0000-000000000006'
ORDER BY ac.role_type;

SELECT count(*) AS riverside_contacts_total_after
FROM contacts
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

\echo ''
\echo '--- Chunk 02 result: integrations DP alignment (expect 3 aligned, 0 unnamed) ---'
SELECT
  count(*)                                                                    AS total_integrations,
  count(*) FILTER (WHERE ai.source_deployment_profile_id IS NOT NULL
                    AND ai.target_deployment_profile_id IS NOT NULL)          AS both_dps_set,
  count(*) FILTER (WHERE ai.name IS NULL OR ai.name = '')                     AS unnamed_integrations
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
WHERE sa.workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

SELECT ai.name, sa.name AS source_app, ta.name AS target_app,
       (ai.source_deployment_profile_id IS NOT NULL
         AND ai.target_deployment_profile_id IS NOT NULL) AS dp_aligned
FROM application_integrations ai
LEFT JOIN applications sa ON sa.id = ai.source_application_id
LEFT JOIN applications ta ON ta.id = ai.target_application_id
WHERE sa.workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
ORDER BY dp_aligned DESC, sa.name, ta.name;

\echo ''
\echo '--- Chunk 03 result: FY2026 workspace budgets (expect 5 rows) ---'
SELECT w.name, wb.fiscal_year, wb.budget_amount, wb.is_current
FROM workspace_budgets wb
JOIN workspaces w ON w.id = wb.workspace_id
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND wb.fiscal_year = 2026
ORDER BY w.name;

\echo ''
\echo '--- Chunk 04 result: IT services contract data (expect 3 with contract) ---'
SELECT
  count(*) FILTER (WHERE contract_reference IS NOT NULL) AS services_with_contract_ref,
  count(*) FILTER (WHERE contract_end_date  IS NOT NULL) AS services_with_end_date,
  count(*)                                               AS total_services,
  sum(annual_cost)                                       AS unchanged_annual_cost_total
FROM it_services
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT name, annual_cost, contract_reference, contract_start_date, contract_end_date
FROM it_services
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND contract_reference IS NOT NULL
ORDER BY annual_cost DESC;

\echo ''
\echo '--- Chunk 05 result (OPTIONAL): CAD PROD DP ops fields ---'
SELECT dp.id, dp.name, dp.data_center_id, dc.name AS data_center_name, dp.server_name
FROM deployment_profiles dp
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
WHERE dp.id = 'b5000006-0000-0000-0000-000000000006';

\echo ''
\echo '--- Chunk 06 result: cost_bundle DPs on showcase apps (expect 3 rows) ---'
SELECT
  a.name          AS app_name,
  dp.name         AS bundle_name,
  dp.cost_recurrence,
  dp.annual_cost,
  o.name          AS vendor,
  dp.contract_reference,
  dp.contract_end_date
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
LEFT JOIN organizations o ON o.id = dp.vendor_org_id
WHERE dp.dp_type = 'cost_bundle'
  AND a.id IN (
    'b1000006-0000-0000-0000-000000000006',
    'b1000001-0000-0000-0000-000000000001',
    'b1000007-0000-0000-0000-000000000007'
  )
ORDER BY a.name, dp.name;

SELECT
  a.name                                                                              AS app_name,
  count(dp.id)                                                                        AS cost_bundle_count,
  COALESCE(sum(dp.annual_cost) FILTER (WHERE dp.cost_recurrence = 'recurring'), 0)    AS recurring_bundle_total
FROM applications a
LEFT JOIN deployment_profiles dp
       ON dp.application_id = a.id
      AND dp.dp_type        = 'cost_bundle'
WHERE a.id IN (
  'b1000006-0000-0000-0000-000000000006',
  'b1000001-0000-0000-0000-000000000001',
  'b1000007-0000-0000-0000-000000000007'
)
GROUP BY a.name
ORDER BY a.name;

SELECT
  application_name,
  deployment_profile_name,
  software_cost,
  service_cost,
  bundle_cost,
  total_cost
FROM vw_deployment_profile_costs
WHERE application_id IN (
  'b1000006-0000-0000-0000-000000000006',
  'b1000001-0000-0000-0000-000000000001',
  'b1000007-0000-0000-0000-000000000007'
)
ORDER BY application_name, deployment_profile_name;

\echo ''
\echo 'AFTER snapshot complete. Compare against BEFORE snapshot to confirm.'
