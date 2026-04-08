-- ============================================================
-- COR Demo Data — SirsiDynix Symphony (supplemental app)
-- ============================================================
-- Purpose: Add SirsiDynix Symphony so the roadmap seed's
--          Finding #1 and Initiative #1 reference an actual app.
--
-- Run:     Supabase SQL Editor (Stuart) — BEFORE roadmap seed
-- Idempotent: ON CONFLICT DO NOTHING
-- ============================================================

-- Namespace guard
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM namespaces WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  ) THEN
    RAISE EXCEPTION 'COR namespace not found — aborting';
  END IF;
END $$;

-- ============================================================
-- 1. Vendor organization
-- ============================================================
-- SirsiDynix is the manufacturer/vendor (library ILS company)

INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_active)
VALUES
  ('d1000019-0000-0000-0000-000000000019', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'SirsiDynix', true, true, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. Software Product
-- ============================================================
-- Continues b3 series: next after b3000010 is b3000011

INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, manufacturer_org_id, is_internal_only, is_org_wide, annual_cost)
VALUES
  ('b3000011-0000-0000-0000-000000000011', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'SirsiDynix Symphony',
   'd1000019-0000-0000-0000-000000000019', false, false, NULL)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. Application
-- ============================================================
-- Continues b1 series: next after b100001e is b100001f
-- Placed in IT workspace (IT manages shared infrastructure; no Library workspace exists)

INSERT INTO applications (id, workspace_id, name, description, operational_status, lifecycle_stage_status)
VALUES
  ('b100001f-0000-0000-0000-00000000001f', 'a1b2c3d4-0001-0000-0000-000000000001',
   'SirsiDynix Symphony', 'Integrated library system (ILS) for catalog management, circulation, acquisitions, and patron services',
   'operational', 'active')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. Deployment Profile (application DP)
-- ============================================================
-- Continues b5 series: next after b500001e is b500001f
-- On-prem, runs on RHEL in City Hall data center

INSERT INTO deployment_profiles (id, application_id, workspace_id, name, environment, dp_type, is_primary, hosting_type, cloud_provider, data_center_id, server_name)
VALUES
  ('b500001f-0000-0000-0000-00000000001f', 'b100001f-0000-0000-0000-00000000001f',
   'a1b2c3d4-0001-0000-0000-000000000001', 'SirsiDynix Symphony - PROD - CHDC',
   'PROD', 'application', true, 'On-Prem', NULL,
   'fb337a78-b1ec-4227-9404-56a52ce3ff72', 'SYM-PROD-01')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. DP → Technology Products (runs on RHEL 8 + PostgreSQL)
-- ============================================================
-- b2000003 = RHEL 8, b2000007 = PostgreSQL 16

INSERT INTO deployment_profile_technology_products (id, deployment_profile_id, technology_product_id)
VALUES
  (gen_random_uuid(), 'b500001f-0000-0000-0000-00000000001f', 'b2000003-0000-0000-0000-000000000003'),
  (gen_random_uuid(), 'b500001f-0000-0000-0000-00000000001f', 'b2000007-0000-0000-0000-000000000007')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 6. DP → Software Products (links to SirsiDynix Symphony SW)
-- ============================================================

INSERT INTO deployment_profile_software_products (id, deployment_profile_id, software_product_id)
VALUES
  (gen_random_uuid(), 'b500001f-0000-0000-0000-00000000001f', 'b3000011-0000-0000-0000-000000000011')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 7. DP → IT Services (depends on Windows Server Hosting)
-- ============================================================
-- b4000001 = Windows Server Hosting (RHEL VMs co-hosted)

INSERT INTO deployment_profile_it_services (id, deployment_profile_id, it_service_id, relationship_type, source)
VALUES
  (gen_random_uuid(), 'b500001f-0000-0000-0000-00000000001f', 'b4000001-0000-0000-0000-000000000001',
   'depends_on', 'manual')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 8. Portfolio Assignment
-- ============================================================
-- IT workspace portfolio: ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85 (from Phase 2o)

INSERT INTO portfolio_assignments (portfolio_id, application_id, deployment_profile_id, relationship_type)
VALUES
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100001f-0000-0000-0000-00000000001f',
   'b500001f-0000-0000-0000-00000000001f', 'publisher')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Verification
-- ============================================================
SELECT 'organization' AS entity, count(*) FROM organizations WHERE id = 'd1000019-0000-0000-0000-000000000019'
UNION ALL
SELECT 'software_product', count(*) FROM software_products WHERE id = 'b3000011-0000-0000-0000-000000000011'
UNION ALL
SELECT 'application', count(*) FROM applications WHERE id = 'b100001f-0000-0000-0000-00000000001f'
UNION ALL
SELECT 'deployment_profile', count(*) FROM deployment_profiles WHERE id = 'b500001f-0000-0000-0000-00000000001f'
ORDER BY entity;

-- Expected: all counts = 1
