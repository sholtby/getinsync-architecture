-- =============================================================================
-- GetInSync NextGen — pgTAP RLS Coverage Test Suite
-- =============================================================================
-- Version: 1.1
-- Date: 2026-02-23
-- Purpose: Automated regression tests for security posture across all 90 tables + 27 views
--
-- What this tests:
--   1. RLS enabled on all 90 public tables
--   2. GRANT (SELECT at minimum) for authenticated + service_role on all tables
--   3. Audit trigger present on 37 designated tables
--   4. security_invoker=true on all 27 views
--   5. GRANT SELECT for authenticated + service_role on all 27 views
--   6. No orphaned tables/views (new ones without security coverage)
--
-- How to run:
--   Option A (pgTAP installed): SELECT * FROM run_tests();
--   Option B (standalone):      Paste into Supabase SQL Editor, run, read output
--
-- Prerequisites:
--   CREATE EXTENSION IF NOT EXISTS pgtap;
-- =============================================================================

-- Enable pgTAP if not already present
CREATE EXTENSION IF NOT EXISTS pgtap;

-- Start the test plan
BEGIN;

-- ============================================================
-- SECTION 1: RLS ENABLED ON ALL PUBLIC TABLES
-- ============================================================
-- Every public table must have RLS enabled. A table without RLS
-- is a multi-tenant data leak waiting to happen.

SELECT plan(90 + 90 + 90 + 37 + 27 + 27 + 27 + 3);
-- 90 = RLS enabled checks
-- 90 = authenticated GRANT checks (tables)
-- 90 = service_role GRANT checks (tables)
-- 37 = audit trigger checks
-- 27 = view security_invoker checks
-- 27 = authenticated GRANT checks (views)
-- 27 = service_role GRANT checks (views)
--  3 = summary/sentinel checks

-- RLS enabled on all 90 tables
SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'alert_preferences'),
  true,
  'RLS enabled: alert_preferences'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_compliance'),
  true,
  'RLS enabled: application_compliance'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_contacts'),
  true,
  'RLS enabled: application_contacts'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_data_assets'),
  true,
  'RLS enabled: application_data_assets'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_documents'),
  true,
  'RLS enabled: application_documents'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_integrations'),
  true,
  'RLS enabled: application_integrations'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_roadmap'),
  true,
  'RLS enabled: application_roadmap'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'application_services'),
  true,
  'RLS enabled: application_services'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'applications'),
  true,
  'RLS enabled: applications'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'assessment_factor_options'),
  true,
  'RLS enabled: assessment_factor_options'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'assessment_factors'),
  true,
  'RLS enabled: assessment_factors'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'assessment_history'),
  true,
  'RLS enabled: assessment_history'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'assessment_thresholds'),
  true,
  'RLS enabled: assessment_thresholds'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'audit_logs'),
  true,
  'RLS enabled: audit_logs'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'budget_transfers'),
  true,
  'RLS enabled: budget_transfers'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'business_assessments'),
  true,
  'RLS enabled: business_assessments'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cloud_providers'),
  true,
  'RLS enabled: cloud_providers'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'contact_organizations'),
  true,
  'RLS enabled: contact_organizations'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'contacts'),
  true,
  'RLS enabled: contacts'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'countries'),
  true,
  'RLS enabled: countries'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'criticality_types'),
  true,
  'RLS enabled: criticality_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'custom_field_definitions'),
  true,
  'RLS enabled: custom_field_definitions'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'custom_field_values'),
  true,
  'RLS enabled: custom_field_values'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'data_centers'),
  true,
  'RLS enabled: data_centers'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'data_classification_types'),
  true,
  'RLS enabled: data_classification_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'data_format_types'),
  true,
  'RLS enabled: data_format_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'data_tag_types'),
  true,
  'RLS enabled: data_tag_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'deployment_profile_contacts'),
  true,
  'RLS enabled: deployment_profile_contacts'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'deployment_profile_it_services'),
  true,
  'RLS enabled: deployment_profile_it_services'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'deployment_profile_software_products'),
  true,
  'RLS enabled: deployment_profile_software_products'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'deployment_profile_technology_products'),
  true,
  'RLS enabled: deployment_profile_technology_products'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'deployment_profiles'),
  true,
  'RLS enabled: deployment_profiles'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'dr_statuses'),
  true,
  'RLS enabled: dr_statuses'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'environments'),
  true,
  'RLS enabled: environments'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'findings'),
  true,
  'RLS enabled: findings'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'hosting_types'),
  true,
  'RLS enabled: hosting_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ideas'),
  true,
  'RLS enabled: ideas'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'individuals'),
  true,
  'RLS enabled: individuals'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'initiative_dependencies'),
  true,
  'RLS enabled: initiative_dependencies'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'initiative_deployment_profiles'),
  true,
  'RLS enabled: initiative_deployment_profiles'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'initiative_it_services'),
  true,
  'RLS enabled: initiative_it_services'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'initiatives'),
  true,
  'RLS enabled: initiatives'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integration_contacts'),
  true,
  'RLS enabled: integration_contacts'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integration_direction_types'),
  true,
  'RLS enabled: integration_direction_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integration_frequency_types'),
  true,
  'RLS enabled: integration_frequency_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integration_method_types'),
  true,
  'RLS enabled: integration_method_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integration_status_types'),
  true,
  'RLS enabled: integration_status_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'invitation_workspaces'),
  true,
  'RLS enabled: invitation_workspaces'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'invitations'),
  true,
  'RLS enabled: invitations'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'it_service_providers'),
  true,
  'RLS enabled: it_service_providers'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'it_services'),
  true,
  'RLS enabled: it_services'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'lifecycle_statuses'),
  true,
  'RLS enabled: lifecycle_statuses'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'namespace_role_options'),
  true,
  'RLS enabled: namespace_role_options'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'namespace_users'),
  true,
  'RLS enabled: namespace_users'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'namespaces'),
  true,
  'RLS enabled: namespaces'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notification_rules'),
  true,
  'RLS enabled: notification_rules'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications'),
  true,
  'RLS enabled: notifications'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'operational_statuses'),
  true,
  'RLS enabled: operational_statuses'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organization_settings'),
  true,
  'RLS enabled: organization_settings'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organizations'),
  true,
  'RLS enabled: organizations'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'platform_admins'),
  true,
  'RLS enabled: platform_admins'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolio_assignments'),
  true,
  'RLS enabled: portfolio_assignments'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolio_settings'),
  true,
  'RLS enabled: portfolio_settings'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolios'),
  true,
  'RLS enabled: portfolios'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'program_initiatives'),
  true,
  'RLS enabled: program_initiatives'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'programs'),
  true,
  'RLS enabled: programs'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'remediation_efforts'),
  true,
  'RLS enabled: remediation_efforts'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'sensitivity_types'),
  true,
  'RLS enabled: sensitivity_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'service_type_categories'),
  true,
  'RLS enabled: service_type_categories'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'service_types'),
  true,
  'RLS enabled: service_types'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'software_product_categories'),
  true,
  'RLS enabled: software_product_categories'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'software_products'),
  true,
  'RLS enabled: software_products'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'standard_regions'),
  true,
  'RLS enabled: standard_regions'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'technical_assessments'),
  true,
  'RLS enabled: technical_assessments'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'technology_lifecycle_reference'),
  true,
  'RLS enabled: technology_lifecycle_reference'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'technology_product_categories'),
  true,
  'RLS enabled: technology_product_categories'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'technology_products'),
  true,
  'RLS enabled: technology_products'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_sessions'),
  true,
  'RLS enabled: user_sessions'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users'),
  true,
  'RLS enabled: users'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'vendor_lifecycle_sources'),
  true,
  'RLS enabled: vendor_lifecycle_sources'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workflow_definitions'),
  true,
  'RLS enabled: workflow_definitions'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workflow_instances'),
  true,
  'RLS enabled: workflow_instances'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_budgets'),
  true,
  'RLS enabled: workspace_budgets'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_group_members'),
  true,
  'RLS enabled: workspace_group_members'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_group_publications'),
  true,
  'RLS enabled: workspace_group_publications'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_groups'),
  true,
  'RLS enabled: workspace_groups'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_role_options'),
  true,
  'RLS enabled: workspace_role_options'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_settings'),
  true,
  'RLS enabled: workspace_settings'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspace_users'),
  true,
  'RLS enabled: workspace_users'
);

SELECT is(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workspaces'),
  true,
  'RLS enabled: workspaces'
);


-- ============================================================
-- SECTION 2: GRANT CHECKS — authenticated role
-- ============================================================
-- Every public table must grant at least SELECT to authenticated.
-- This is checked via information_schema.table_privileges.

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='alert_preferences'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: alert_preferences'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_compliance'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_compliance'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_contacts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_data_assets'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_data_assets'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_documents'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_documents'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_integrations'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_integrations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_roadmap'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_roadmap'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_services'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: application_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='applications'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: applications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_factor_options'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: assessment_factor_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_factors'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: assessment_factors'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_history'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: assessment_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_thresholds'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: assessment_thresholds'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='audit_logs'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: audit_logs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='budget_transfers'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: budget_transfers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='business_assessments'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: business_assessments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='cloud_providers'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: cloud_providers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='contact_organizations'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: contact_organizations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='contacts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='countries'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: countries'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='criticality_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: criticality_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='custom_field_definitions'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: custom_field_definitions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='custom_field_values'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: custom_field_values'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_centers'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: data_centers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_classification_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: data_classification_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_format_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: data_format_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_tag_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: data_tag_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_contacts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: deployment_profile_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_it_services'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: deployment_profile_it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_software_products'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: deployment_profile_software_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_technology_products'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: deployment_profile_technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profiles'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='dr_statuses'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: dr_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='environments'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: environments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='findings'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: findings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='hosting_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: hosting_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='ideas'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: ideas'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='individuals'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: individuals'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_dependencies'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: initiative_dependencies'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_deployment_profiles'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: initiative_deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_it_services'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: initiative_it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiatives'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_contacts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: integration_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_direction_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: integration_direction_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_frequency_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: integration_frequency_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_method_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: integration_method_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_status_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: integration_status_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='invitation_workspaces'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: invitation_workspaces'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='invitations'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: invitations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='it_service_providers'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: it_service_providers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='it_services'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='lifecycle_statuses'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: lifecycle_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespace_role_options'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: namespace_role_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespace_users'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: namespace_users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespaces'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: namespaces'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='notification_rules'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: notification_rules'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='notifications'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: notifications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='operational_statuses'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: operational_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='organization_settings'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: organization_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='organizations'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: organizations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='platform_admins'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: platform_admins'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolio_assignments'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: portfolio_assignments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolio_settings'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: portfolio_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolios'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: portfolios'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='program_initiatives'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: program_initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='programs'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: programs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='remediation_efforts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: remediation_efforts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='sensitivity_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: sensitivity_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='service_type_categories'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: service_type_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='service_types'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: service_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='software_product_categories'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: software_product_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='software_products'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: software_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='standard_regions'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: standard_regions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technical_assessments'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: technical_assessments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_lifecycle_reference'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: technology_lifecycle_reference'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_product_categories'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: technology_product_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_products'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='user_sessions'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: user_sessions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='users'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='vendor_lifecycle_sources'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vendor_lifecycle_sources'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workflow_definitions'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workflow_definitions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workflow_instances'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workflow_instances'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_budgets'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_budgets'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_group_members'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_group_members'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_group_publications'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_group_publications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_groups'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_groups'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_role_options'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_role_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_settings'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_users'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspace_users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspaces'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: workspaces'
);


-- ============================================================
-- SECTION 3: GRANT CHECKS — service_role
-- ============================================================
-- Every public table must grant at least SELECT to service_role.

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='alert_preferences'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: alert_preferences'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_compliance'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_compliance'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_contacts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_data_assets'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_data_assets'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_documents'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_documents'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_integrations'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_integrations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_roadmap'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_roadmap'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='application_services'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: application_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='applications'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: applications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_factor_options'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: assessment_factor_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_factors'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: assessment_factors'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_history'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: assessment_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='assessment_thresholds'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: assessment_thresholds'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='audit_logs'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: audit_logs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='budget_transfers'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: budget_transfers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='business_assessments'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: business_assessments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='cloud_providers'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: cloud_providers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='contact_organizations'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: contact_organizations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='contacts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='countries'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: countries'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='criticality_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: criticality_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='custom_field_definitions'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: custom_field_definitions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='custom_field_values'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: custom_field_values'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_centers'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: data_centers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_classification_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: data_classification_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_format_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: data_format_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='data_tag_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: data_tag_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_contacts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: deployment_profile_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_it_services'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: deployment_profile_it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_software_products'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: deployment_profile_software_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profile_technology_products'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: deployment_profile_technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='deployment_profiles'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='dr_statuses'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: dr_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='environments'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: environments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='findings'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: findings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='hosting_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: hosting_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='ideas'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: ideas'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='individuals'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: individuals'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_dependencies'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: initiative_dependencies'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_deployment_profiles'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: initiative_deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiative_it_services'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: initiative_it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='initiatives'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_contacts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: integration_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_direction_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: integration_direction_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_frequency_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: integration_frequency_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_method_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: integration_method_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='integration_status_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: integration_status_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='invitation_workspaces'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: invitation_workspaces'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='invitations'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: invitations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='it_service_providers'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: it_service_providers'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='it_services'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='lifecycle_statuses'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: lifecycle_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespace_role_options'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: namespace_role_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespace_users'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: namespace_users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='namespaces'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: namespaces'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='notification_rules'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: notification_rules'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='notifications'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: notifications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='operational_statuses'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: operational_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='organization_settings'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: organization_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='organizations'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: organizations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='platform_admins'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: platform_admins'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolio_assignments'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: portfolio_assignments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolio_settings'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: portfolio_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='portfolios'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: portfolios'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='program_initiatives'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: program_initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='programs'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: programs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='remediation_efforts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: remediation_efforts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='sensitivity_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: sensitivity_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='service_type_categories'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: service_type_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='service_types'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: service_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='software_product_categories'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: software_product_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='software_products'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: software_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='standard_regions'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: standard_regions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technical_assessments'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: technical_assessments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_lifecycle_reference'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: technology_lifecycle_reference'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_product_categories'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: technology_product_categories'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='technology_products'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='user_sessions'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: user_sessions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='users'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='vendor_lifecycle_sources'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vendor_lifecycle_sources'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workflow_definitions'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workflow_definitions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workflow_instances'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workflow_instances'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_budgets'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_budgets'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_group_members'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_group_members'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_group_publications'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_group_publications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_groups'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_groups'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_role_options'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_role_options'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_settings'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_settings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspace_users'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspace_users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.table_privileges
   WHERE table_schema='public' AND table_name='workspaces'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: workspaces'
);


-- ============================================================
-- SECTION 4: AUDIT TRIGGER CHECKS (37 tables)
-- ============================================================
-- These 37 tables must have an audit trigger. The trigger name
-- follows the pattern: audit_{tablename} or {tablename}_audit_trigger
-- We check for ANY trigger containing 'audit' on the table.

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='application_integrations'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: application_integrations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='applications'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: applications'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='contacts'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='criticality_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: criticality_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='data_classification_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: data_classification_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='data_format_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: data_format_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='data_tag_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: data_tag_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='deployment_profile_technology_products'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: deployment_profile_technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='deployment_profiles'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='findings'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: findings'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='ideas'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: ideas'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='initiative_dependencies'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: initiative_dependencies'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='initiative_deployment_profiles'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: initiative_deployment_profiles'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='initiative_it_services'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: initiative_it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='initiatives'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='integration_contacts'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: integration_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='integration_direction_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: integration_direction_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='integration_frequency_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: integration_frequency_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='integration_method_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: integration_method_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='integration_status_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: integration_status_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='invitations'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: invitations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='it_services'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: it_services'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='namespace_users'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: namespace_users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='operational_statuses'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: operational_statuses'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='organizations'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: organizations'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='platform_admins'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: platform_admins'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='portfolio_assignments'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: portfolio_assignments'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='portfolios'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: portfolios'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='program_initiatives'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: program_initiatives'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='programs'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: programs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='sensitivity_types'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: sensitivity_types'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='technology_lifecycle_reference'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: technology_lifecycle_reference'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='technology_products'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: technology_products'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='user_sessions'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: user_sessions'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='users'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: users'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='vendor_lifecycle_sources'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: vendor_lifecycle_sources'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.triggers
   WHERE event_object_schema='public' AND event_object_table='workspace_users'
   AND trigger_name LIKE '%audit%'),
  0,
  'Audit trigger: workspace_users'
);


-- ============================================================
-- SECTION 5: VIEW SECURITY — security_invoker=true (27 views)
-- ============================================================
-- All views must use security_invoker=true to enforce RLS through
-- the calling user's permissions, not the view definer's.

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_application_infrastructure_report'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_application_infrastructure_report'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_application_integration_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_application_integration_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_application_run_rate'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_application_run_rate'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_budget_alerts'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_budget_alerts'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_budget_status'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_budget_status'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_budget_transfer_history'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_budget_transfer_history'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_deployment_profile_costs'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_deployment_profile_costs'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_finding_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_finding_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_idea_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_idea_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_initiative_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_initiative_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_integration_contacts'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_integration_contacts'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_integration_detail'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_integration_detail'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_it_service_budget_status'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_it_service_budget_status'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_namespace_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_namespace_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_namespace_user_detail'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_namespace_user_detail'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_namespace_workspace_detail'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_namespace_workspace_detail'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_portfolio_costs'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_portfolio_costs'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_portfolio_costs_rollup'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_portfolio_costs_rollup'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_program_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_program_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_run_rate_by_vendor'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_run_rate_by_vendor'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_server_technology_report'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_server_technology_report'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_service_type_picker'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_service_type_picker'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_software_contract_expiry'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_software_contract_expiry'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_technology_health_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_technology_health_summary'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_technology_tag_lifecycle_risk'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_technology_tag_lifecycle_risk'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_workspace_budget_history'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_workspace_budget_history'
);

SELECT is(
  (SELECT count(*)::int FROM pg_views v
   JOIN pg_class c ON c.relname = v.viewname AND c.relnamespace = 'public'::regnamespace
   WHERE v.schemaname = 'public'
   AND v.viewname = 'vw_workspace_budget_summary'
   AND c.reloptions @> ARRAY['security_invoker=true']),
  1,
  'security_invoker=true: vw_workspace_budget_summary'
);


-- ============================================================
-- SECTION 5b: VIEW GRANT CHECKS — authenticated role (27 views)
-- ============================================================
-- Views with security_invoker=true still need explicit GRANT SELECT
-- for the caller to access the view itself.

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_infrastructure_report'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_application_infrastructure_report'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_integration_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_application_integration_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_run_rate'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_application_run_rate'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_alerts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_budget_alerts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_status'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_budget_status'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_transfer_history'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_budget_transfer_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_deployment_profile_costs'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_deployment_profile_costs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_finding_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_finding_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_idea_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_idea_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_initiative_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_initiative_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_integration_contacts'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_integration_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_integration_detail'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_integration_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_it_service_budget_status'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_it_service_budget_status'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_namespace_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_user_detail'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_namespace_user_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_workspace_detail'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_namespace_workspace_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_portfolio_costs'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_portfolio_costs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_portfolio_costs_rollup'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_portfolio_costs_rollup'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_program_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_program_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_run_rate_by_vendor'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_run_rate_by_vendor'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_server_technology_report'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_server_technology_report'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_service_type_picker'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_service_type_picker'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_software_contract_expiry'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_software_contract_expiry'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_technology_health_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_technology_health_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_technology_tag_lifecycle_risk'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_technology_tag_lifecycle_risk'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_workspace_budget_history'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_workspace_budget_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_workspace_budget_summary'
   AND grantee='authenticated' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to authenticated: vw_workspace_budget_summary'
);


-- ============================================================
-- SECTION 5c: VIEW GRANT CHECKS — service_role (27 views)
-- ============================================================

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_infrastructure_report'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_application_infrastructure_report'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_integration_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_application_integration_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_application_run_rate'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_application_run_rate'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_alerts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_budget_alerts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_status'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_budget_status'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_budget_transfer_history'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_budget_transfer_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_deployment_profile_costs'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_deployment_profile_costs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_finding_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_finding_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_idea_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_idea_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_initiative_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_initiative_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_integration_contacts'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_integration_contacts'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_integration_detail'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_integration_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_it_service_budget_status'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_it_service_budget_status'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_namespace_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_user_detail'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_namespace_user_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_namespace_workspace_detail'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_namespace_workspace_detail'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_portfolio_costs'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_portfolio_costs'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_portfolio_costs_rollup'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_portfolio_costs_rollup'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_program_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_program_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_run_rate_by_vendor'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_run_rate_by_vendor'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_server_technology_report'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_server_technology_report'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_service_type_picker'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_service_type_picker'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_software_contract_expiry'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_software_contract_expiry'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_technology_health_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_technology_health_summary'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_technology_tag_lifecycle_risk'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_technology_tag_lifecycle_risk'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_workspace_budget_history'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_workspace_budget_history'
);

SELECT isnt(
  (SELECT count(*)::int FROM information_schema.role_table_grants
   WHERE table_schema='public' AND table_name='vw_workspace_budget_summary'
   AND grantee='service_role' AND privilege_type='SELECT'),
  0,
  'GRANT SELECT to service_role: vw_workspace_budget_summary'
);


-- ============================================================
-- SECTION 6: SENTINEL CHECKS — catch drift
-- ============================================================
-- These tests catch when new tables/views are added without
-- updating the test suite. If these fail, a new table or view
-- was added and needs security coverage.

-- Expected: 90 public tables
SELECT is(
  (SELECT count(*)::int FROM pg_tables WHERE schemaname = 'public'),
  90,
  'SENTINEL: Expected 90 public tables (update test suite if this changes)'
);

-- Expected: 27 public views (excluding pgTAP internal views)
SELECT is(
  (SELECT count(*)::int FROM pg_views WHERE schemaname = 'public'
   AND viewname NOT IN ('pg_all_foreign_keys', 'tap_funky')),
  27,
  'SENTINEL: Expected 27 public views (update test suite if this changes)'
);

-- Expected: 37 audit triggers (count distinct tables with audit triggers)
SELECT is(
  (SELECT count(DISTINCT event_object_table)::int FROM information_schema.triggers
   WHERE event_object_schema = 'public' AND trigger_name LIKE '%audit%'),
  37,
  'SENTINEL: Expected 37 tables with audit triggers (update test suite if this changes)'
);


-- ============================================================
-- FINISH
-- ============================================================
SELECT * FROM finish();
ROLLBACK;

-- =============================================================================
-- HOW TO RUN
-- =============================================================================
-- 1. Enable pgTAP in Supabase:
--      Go to Database → Extensions → Search "pgtap" → Enable
--    OR run: CREATE EXTENSION IF NOT EXISTS pgtap;
--
-- 2. Paste this entire file into Supabase SQL Editor
--
-- 3. Run it — output is TAP format:
--      ok 1 - RLS enabled: alert_preferences
--      ok 2 - RLS enabled: application_compliance
--      ...
--      not ok 91 - GRANT SELECT to authenticated: some_new_table
--
-- 4. Any "not ok" line = FAILED test = security gap
--
-- 5. The ROLLBACK at the end means this is read-only — no data changes
--
-- WHEN TO UPDATE THIS FILE:
--   - After adding a new table → add RLS + GRANT tests, update sentinel count
--   - After adding a new view → add security_invoker + GRANT tests, update sentinel count
--   - After adding a new audit trigger → add audit trigger test, update sentinel count
-- =============================================================================
