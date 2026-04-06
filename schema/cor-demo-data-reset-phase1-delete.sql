-- =============================================================================
-- COR Demo Data Reset — Phase 1: DELETE all COR namespace data
-- =============================================================================
-- Namespace: COR (City of Riverside)
-- Namespace ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
--
-- Purpose: Remove ALL demo data from the COR namespace so it can be
--          re-seeded with consistent, presentation-ready data.
--
-- Safety:
--   - Every DELETE is scoped to the COR namespace via subqueries
--   - Wrapped in a transaction — nothing commits until COMMIT runs
--   - To abort: replace COMMIT with ROLLBACK (or just close the session)
--
-- Run in: Supabase SQL Editor (service_role context bypasses RLS)
-- Author: Claude Code + Stuart Holtby
-- Date: 2026-04-06
-- =============================================================================

BEGIN;

-- =============================================================================
-- Phase 1a: Pre-flight namespace check
-- =============================================================================
-- Verify the COR namespace exists and we have the right UUID.
-- If this returns 0 rows, STOP — the UUID is wrong.

DO $$
DECLARE
  ns_name text;
BEGIN
  SELECT name INTO ns_name
  FROM namespaces
  WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  IF ns_name IS NULL THEN
    RAISE EXCEPTION 'ABORT: Namespace a1b2c3d4-e5f6-7890-abcd-ef1234567890 not found. Check the UUID.';
  END IF;

  RAISE NOTICE 'Pre-flight OK — namespace: %', ns_name;
END $$;


-- =============================================================================
-- Phase 1b: RESTRICT/NO ACTION FK blockers
-- =============================================================================
-- These tables have RESTRICT FKs that would block parent deletes.
-- Must be deleted BEFORE their parent tables.

-- 1. technology_standards (has direct namespace_id)
DELETE FROM technology_standards
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 2. initiative_it_services (scoped through initiative → namespace)
DELETE FROM initiative_it_services
WHERE initiative_id IN (
  SELECT id FROM initiatives
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 3. initiative_deployment_profiles (scoped through initiative → namespace)
DELETE FROM initiative_deployment_profiles
WHERE initiative_id IN (
  SELECT id FROM initiatives
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 4. application_services (RESTRICT FK on it_service_id — must delete before it_services)
--    Scoped through it_service → namespace
DELETE FROM application_services
WHERE it_service_id IN (
  SELECT id FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 5. deployment_profile_it_services (RESTRICT FK on it_service_id — must delete before it_services)
--    Scoped through DP → workspace → namespace
DELETE FROM deployment_profile_it_services
WHERE deployment_profile_id IN (
  SELECT dp.id FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 6. integration_contacts (scoped through integration → source_app → workspace → namespace)
--    Note: Also cascades from application_integrations, but deleting explicitly for safety
DELETE FROM integration_contacts
WHERE integration_id IN (
  SELECT ai.id FROM application_integrations ai
  JOIN applications a ON ai.source_application_id = a.id
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 7. deployment_profile_contacts (scoped through DP → workspace → namespace)
--    Note: Also cascades from deployment_profiles, but deleting explicitly for safety
DELETE FROM deployment_profile_contacts
WHERE deployment_profile_id IN (
  SELECT dp.id FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 8. application_contacts (scoped through app → workspace → namespace)
--    Note: Also cascades from applications, but deleting explicitly for safety
DELETE FROM application_contacts
WHERE application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 9. contact_organizations (cascades from contacts, but deleting explicitly)
DELETE FROM contact_organizations
WHERE contact_id IN (
  SELECT id FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 10. portfolio_contacts (scoped through portfolio → workspace → namespace)
DELETE FROM portfolio_contacts
WHERE contact_id IN (
  SELECT id FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 11. workspace_contacts (scoped through contact → namespace)
DELETE FROM workspace_contacts
WHERE contact_id IN (
  SELECT id FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 12. contacts (has direct namespace_id)
DELETE FROM contacts
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- Phase 1c: Junction tables
-- =============================================================================
-- These cascade from their parents, but deleting explicitly ensures clean
-- ordering and avoids surprises if cascade behavior changes.

-- 13. deployment_profile_software_products (scoped through DP → workspace → namespace)
DELETE FROM deployment_profile_software_products
WHERE deployment_profile_id IN (
  SELECT dp.id FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 14. deployment_profile_technology_products (scoped through DP → workspace → namespace)
DELETE FROM deployment_profile_technology_products
WHERE deployment_profile_id IN (
  SELECT dp.id FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 15. it_service_technology_products (scoped through it_service → namespace)
DELETE FROM it_service_technology_products
WHERE it_service_id IN (
  SELECT id FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 16. it_service_software_products (scoped through it_service → namespace)
DELETE FROM it_service_software_products
WHERE it_service_id IN (
  SELECT id FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 17. it_service_providers (has direct namespace_id)
DELETE FROM it_service_providers
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- Phase 1d: Roadmap data
-- =============================================================================
-- findings, ideas, initiatives all have direct namespace_id.
-- Initiative junction tables already deleted in Phase 1b.

-- 18. findings
DELETE FROM findings
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 19. ideas
DELETE FROM ideas
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 20. initiatives (junction tables already gone from Phase 1b)
DELETE FROM initiatives
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- Phase 1e: Assessments and portfolio links
-- =============================================================================

-- 21. portfolio_assignments (scoped through DP → workspace OR app → workspace)
--     assessment_history cascades from portfolio_assignments (ON DELETE CASCADE),
--     so no explicit delete needed for assessment_history.
DELETE FROM portfolio_assignments
WHERE deployment_profile_id IN (
  SELECT dp.id FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
OR application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 22. business_assessments (scoped through app → workspace → namespace)
--     Also cascades from applications, but deleting explicitly
DELETE FROM business_assessments
WHERE application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 23. technical_assessments (scoped through app → workspace → namespace)
--     Also cascades from applications, but deleting explicitly
DELETE FROM technical_assessments
WHERE application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 24. assessment_history — SKIPPED (cascades from portfolio_assignments via ON DELETE CASCADE)


-- =============================================================================
-- Phase 1f: Core tables
-- =============================================================================

-- 25. application_integrations (scoped through source_app → workspace → namespace)
--     Also handle rows where only target_application_id references a COR app
--     (source might be in another namespace). target_app FK is SET NULL on delete,
--     but we want to remove integrations owned by COR.
DELETE FROM application_integrations
WHERE source_application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 26. deployment_profiles (scoped through workspace → namespace)
--     Catches ALL dp_types: application, infrastructure, cost_bundle
--     Children that cascade: dp_contacts, dp_it_services, dp_software_products,
--     dp_technology_products, portfolio_assignments, workspace_group_publications
DELETE FROM deployment_profiles
WHERE workspace_id IN (
  SELECT id FROM workspaces
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 27. applications (scoped through workspace → namespace)
--     Children that cascade: app_contacts, app_data_assets, app_documents,
--     app_integrations, app_roadmap, app_services, business_assessments,
--     technical_assessments, portfolio_assignments
DELETE FROM applications
WHERE workspace_id IN (
  SELECT id FROM workspaces
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 28. it_services (has direct namespace_id)
--     RESTRICT blockers (application_services, deployment_profile_it_services)
--     already deleted in Phase 1b. Other children cascade.
DELETE FROM it_services
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 29. software_products (has direct namespace_id)
DELETE FROM software_products
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 30. technology_products (has direct namespace_id)
DELETE FROM technology_products
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- Phase 1g: Optional cleanup
-- =============================================================================

-- 31. workspace_group_publications (scoped through workspace_group → namespace)
--     Most already cascaded from deployment_profiles delete, but catch any orphans
DELETE FROM workspace_group_publications
WHERE workspace_group_id IN (
  SELECT id FROM workspace_groups
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

-- 32. audit_logs (optional — comment out if you want to preserve audit trail)
--     Has direct namespace_id
-- DELETE FROM audit_logs
-- WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- Phase 1h: Verification — all counts should be 0
-- =============================================================================

SELECT 'technology_standards' AS table_name, count(*) AS remaining
FROM technology_standards WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'contacts', count(*)
FROM contacts WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'findings', count(*)
FROM findings WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'ideas', count(*)
FROM ideas WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'initiatives', count(*)
FROM initiatives WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'it_services', count(*)
FROM it_services WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'software_products', count(*)
FROM software_products WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'technology_products', count(*)
FROM technology_products WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'applications', count(*)
FROM applications WHERE workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
UNION ALL
SELECT 'deployment_profiles', count(*)
FROM deployment_profiles WHERE workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
UNION ALL
SELECT 'portfolio_assignments', count(*)
FROM portfolio_assignments WHERE application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
UNION ALL
SELECT 'application_integrations', count(*)
FROM application_integrations WHERE source_application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
UNION ALL
SELECT 'it_service_providers', count(*)
FROM it_service_providers WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';


-- =============================================================================
-- COMMIT or ROLLBACK
-- =============================================================================
-- Review the verification counts above. If all are 0, commit.
-- If anything looks wrong, replace COMMIT with ROLLBACK.

COMMIT;

-- To abort instead: ROLLBACK;
