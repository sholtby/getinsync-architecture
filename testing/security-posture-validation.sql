-- =============================================================================
-- GetInSync NextGen — Security Posture Validation (No pgTAP Required)
-- =============================================================================
-- Version: 1.1 | Date: 2026-02-23
-- Run in Supabase SQL Editor — produces a single results table
-- No extensions needed. Read-only (no data changes).
-- =============================================================================

WITH expected_tables AS (
  SELECT unnest(ARRAY[
    'alert_preferences','application_compliance','application_contacts',
    'application_data_assets','application_documents','application_integrations',
    'application_roadmap','application_services','applications',
    'assessment_factor_options','assessment_factors','assessment_history',
    'assessment_thresholds','audit_logs','budget_transfers',
    'business_assessments','cloud_providers','contact_organizations',
    'contacts','countries','criticality_types',
    'custom_field_definitions','custom_field_values','data_centers',
    'data_classification_types','data_format_types','data_tag_types',
    'deployment_profile_contacts','deployment_profile_it_services',
    'deployment_profile_software_products','deployment_profile_technology_products',
    'deployment_profiles','dr_statuses','environments',
    'findings','hosting_types','ideas',
    'individuals','initiative_dependencies','initiative_deployment_profiles',
    'initiative_it_services','initiatives','integration_contacts',
    'integration_direction_types','integration_frequency_types',
    'integration_method_types','integration_status_types',
    'invitation_workspaces','invitations','it_service_providers',
    'it_services','lifecycle_statuses','namespace_role_options',
    'namespace_users','namespaces','notification_rules',
    'notifications','operational_statuses','organization_settings',
    'organizations','platform_admins','portfolio_assignments',
    'portfolio_settings','portfolios','program_initiatives',
    'programs','remediation_efforts','sensitivity_types',
    'service_type_categories','service_types','software_product_categories',
    'software_products','standard_regions','technical_assessments',
    'technology_lifecycle_reference','technology_product_categories',
    'technology_products','user_sessions','users',
    'vendor_lifecycle_sources','workflow_definitions','workflow_instances',
    'workspace_budgets','workspace_group_members','workspace_group_publications',
    'workspace_groups','workspace_role_options','workspace_settings',
    'workspace_users','workspaces'
  ]) AS table_name
),

expected_audit_tables AS (
  SELECT unnest(ARRAY[
    'application_integrations','applications','contacts',
    'criticality_types','data_classification_types','data_format_types',
    'data_tag_types','deployment_profile_technology_products','deployment_profiles',
    'findings','ideas','initiative_dependencies',
    'initiative_deployment_profiles','initiative_it_services','initiatives',
    'integration_contacts','integration_direction_types','integration_frequency_types',
    'integration_method_types','integration_status_types','invitations',
    'it_services','namespace_users','operational_statuses',
    'organizations','platform_admins','portfolio_assignments',
    'portfolios','program_initiatives','programs',
    'sensitivity_types','technology_lifecycle_reference','technology_products',
    'user_sessions','users','vendor_lifecycle_sources',
    'workspace_users'
  ]) AS table_name
),

expected_views AS (
  SELECT unnest(ARRAY[
    'vw_application_infrastructure_report','vw_application_integration_summary',
    'vw_application_run_rate','vw_budget_alerts','vw_budget_status',
    'vw_budget_transfer_history','vw_deployment_profile_costs',
    'vw_finding_summary','vw_idea_summary','vw_initiative_summary',
    'vw_integration_contacts','vw_integration_detail',
    'vw_it_service_budget_status','vw_namespace_summary',
    'vw_namespace_user_detail','vw_namespace_workspace_detail',
    'vw_portfolio_costs','vw_portfolio_costs_rollup',
    'vw_program_summary','vw_run_rate_by_vendor',
    'vw_server_technology_report','vw_service_type_picker',
    'vw_software_contract_expiry','vw_technology_health_summary',
    'vw_technology_tag_lifecycle_risk','vw_workspace_budget_history',
    'vw_workspace_budget_summary'
  ]) AS view_name
),

-- CHECK 1: RLS enabled
rls_check AS (
  SELECT
    et.table_name,
    'RLS enabled' AS check_type,
    CASE WHEN pt.rowsecurity = true THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_tables et
  LEFT JOIN pg_tables pt ON pt.schemaname = 'public' AND pt.tablename = et.table_name
),

-- CHECK 2: GRANT SELECT to authenticated
auth_grant_check AS (
  SELECT
    et.table_name,
    'GRANT authenticated' AS check_type,
    CASE WHEN tp.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_tables et
  LEFT JOIN information_schema.table_privileges tp
    ON tp.table_schema = 'public'
    AND tp.table_name = et.table_name
    AND tp.grantee = 'authenticated'
    AND tp.privilege_type = 'SELECT'
),

-- CHECK 3: GRANT SELECT to service_role
sr_grant_check AS (
  SELECT
    et.table_name,
    'GRANT service_role' AS check_type,
    CASE WHEN tp.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_tables et
  LEFT JOIN information_schema.table_privileges tp
    ON tp.table_schema = 'public'
    AND tp.table_name = et.table_name
    AND tp.grantee = 'service_role'
    AND tp.privilege_type = 'SELECT'
),

-- CHECK 4: Audit triggers on designated tables
audit_check AS (
  SELECT
    eat.table_name,
    'Audit trigger' AS check_type,
    CASE WHEN t.event_object_table IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_audit_tables eat
  LEFT JOIN (
    SELECT DISTINCT event_object_table
    FROM information_schema.triggers
    WHERE event_object_schema = 'public' AND trigger_name LIKE '%audit%'
  ) t ON t.event_object_table = eat.table_name
),

-- CHECK 5: security_invoker on views
view_check AS (
  SELECT
    ev.view_name AS table_name,
    'security_invoker' AS check_type,
    CASE WHEN c.oid IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_views ev
  LEFT JOIN pg_class c
    ON c.relname = ev.view_name
    AND c.relnamespace = 'public'::regnamespace
    AND c.reloptions @> ARRAY['security_invoker=true']
),

-- CHECK 5b: GRANT SELECT to authenticated on views
view_auth_grant_check AS (
  SELECT
    ev.view_name AS table_name,
    'VIEW GRANT authenticated' AS check_type,
    CASE WHEN rtg.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_views ev
  LEFT JOIN information_schema.role_table_grants rtg
    ON rtg.table_schema = 'public'
    AND rtg.table_name = ev.view_name
    AND rtg.grantee = 'authenticated'
    AND rtg.privilege_type = 'SELECT'
),

-- CHECK 5c: GRANT SELECT to service_role on views
view_sr_grant_check AS (
  SELECT
    ev.view_name AS table_name,
    'VIEW GRANT service_role' AS check_type,
    CASE WHEN rtg.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_views ev
  LEFT JOIN information_schema.role_table_grants rtg
    ON rtg.table_schema = 'public'
    AND rtg.table_name = ev.view_name
    AND rtg.grantee = 'service_role'
    AND rtg.privilege_type = 'SELECT'
),

-- CHECK 6: Sentinel — new tables without coverage
new_tables AS (
  SELECT
    pt.tablename AS table_name,
    'NEW TABLE (uncovered)' AS check_type,
    'FAIL' AS result
  FROM pg_tables pt
  WHERE pt.schemaname = 'public'
    AND pt.tablename NOT IN (SELECT table_name FROM expected_tables)
),

-- CHECK 7: Sentinel — new views without coverage
new_views AS (
  SELECT
    pv.viewname AS table_name,
    'NEW VIEW (uncovered)' AS check_type,
    'FAIL' AS result
  FROM pg_views pv
  WHERE pv.schemaname = 'public'
    AND pv.viewname NOT IN (SELECT view_name FROM expected_views)
    AND pv.viewname NOT IN ('pg_all_foreign_keys', 'tap_funky')
),

-- Combine all results
all_results AS (
  SELECT * FROM rls_check
  UNION ALL SELECT * FROM auth_grant_check
  UNION ALL SELECT * FROM sr_grant_check
  UNION ALL SELECT * FROM audit_check
  UNION ALL SELECT * FROM view_check
  UNION ALL SELECT * FROM view_auth_grant_check
  UNION ALL SELECT * FROM view_sr_grant_check
  UNION ALL SELECT * FROM new_tables
  UNION ALL SELECT * FROM new_views
)

-- Final output: show failures first, then summary
SELECT
  result,
  check_type,
  table_name,
  CASE result
    WHEN 'FAIL' THEN '⛔ SECURITY GAP — needs immediate attention'
    ELSE ''
  END AS action_needed
FROM all_results
ORDER BY
  result DESC,  -- FAILs first
  check_type,
  table_name;

-- =============================================================================
-- SUMMARY QUERY (run separately for a quick dashboard)
-- =============================================================================
-- SELECT
--   check_type,
--   count(*) FILTER (WHERE result = 'PASS') AS passed,
--   count(*) FILTER (WHERE result = 'FAIL') AS failed,
--   count(*) AS total
-- FROM (
--   << paste the CTE above >>
-- ) summary
-- GROUP BY check_type
-- ORDER BY failed DESC;
-- =============================================================================
