-- Phase 29b: Seed Part 1 cost bundles for COR SaaS apps
-- Run in Supabase SQL Editor
-- Namespace: a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- 9 apps, $410K total (M365 excluded — costs flow via IT Service)

BEGIN;

-- Pre-flight: verify no cost bundles already exist for these apps
DO $$
DECLARE
  cnt integer;
BEGIN
  SELECT count(*) INTO cnt FROM deployment_profiles
  WHERE dp_type = 'cost_bundle'
  AND application_id IN (
    'b1000019-0000-0000-0000-000000000019', -- Accela
    'b100001a-0000-0000-0000-00000000001a', -- CivicPlus
    'b1000005-0000-0000-0000-000000000005', -- CopLogic
    'b1000017-0000-0000-0000-000000000017', -- NEOGOV
    'b1000007-0000-0000-0000-000000000007', -- NG911
    'b1000011-0000-0000-0000-000000000011', -- Questica
    'b100001b-0000-0000-0000-00000000001b', -- Samsara
    'b100001c-0000-0000-0000-00000000001c', -- SeeClickFix
    'b100001d-0000-0000-0000-00000000001d'  -- Sensus
  );
  IF cnt > 0 THEN
    RAISE EXCEPTION 'Found % existing cost bundles — aborting to prevent duplicates', cnt;
  END IF;
END $$;

-- Accela Civic Platform — $75,000 (Development Services workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b1000019-0000-0000-0000-000000000019', 'a1b2c3d4-0011-0000-0000-000000000011',
  'Accela Civic Platform — SaaS License', 'cost_bundle', 75000, 'Production', 'operational');

-- CivicPlus Website — $12,000 (Customer Operations workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b100001a-0000-0000-0000-00000000001a', 'a1b2c3d4-0013-0000-0000-000000000013',
  'CivicPlus Website — SaaS License', 'cost_bundle', 12000, 'Production', 'operational');

-- CopLogic Online Reporting — $8,000 (Police Department workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b1000005-0000-0000-0000-000000000005', 'a1b2c3d4-0006-0000-0000-000000000006',
  'CopLogic Online Reporting — SaaS License', 'cost_bundle', 8000, 'Production', 'operational');

-- NEOGOV — $22,000 (Human Resources workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b1000017-0000-0000-0000-000000000017', 'a1b2c3d4-0002-0000-0000-000000000002',
  'NEOGOV — SaaS License', 'cost_bundle', 22000, 'Production', 'operational');

-- NG911 System — $180,000 (Police Department workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b1000007-0000-0000-0000-000000000007', 'a1b2c3d4-0006-0000-0000-000000000006',
  'NG911 System — Cloud License', 'cost_bundle', 180000, 'Production', 'operational');

-- Questica Budget — $35,000 (Finance workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b1000011-0000-0000-0000-000000000011', 'a1b2c3d4-0003-0000-0000-000000000003',
  'Questica Budget — SaaS License', 'cost_bundle', 35000, 'Production', 'operational');

-- Samsara Fleet — $15,000 (Public Works workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b100001b-0000-0000-0000-00000000001b', 'a1b2c3d4-0012-0000-0000-000000000012',
  'Samsara Fleet — SaaS License', 'cost_bundle', 15000, 'Production', 'operational');

-- SeeClickFix — $18,000 (Customer Operations workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b100001c-0000-0000-0000-00000000001c', 'a1b2c3d4-0013-0000-0000-000000000013',
  'SeeClickFix — SaaS License', 'cost_bundle', 18000, 'Production', 'operational');

-- Sensus FlexNet — $45,000 (Water Utilities workspace)
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment, operational_status)
VALUES (gen_random_uuid(), 'b100001d-0000-0000-0000-00000000001d', 'a1b2c3d4-0009-0000-0000-000000000009',
  'Sensus FlexNet — SaaS License', 'cost_bundle', 45000, 'Production', 'operational');

-- Total: $410,000 across 9 cost bundles

-- Verify
SELECT a.name AS app, dp.name AS bundle, dp.annual_cost
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
WHERE dp.dp_type = 'cost_bundle'
AND dp.application_id IN (
  'b1000019-0000-0000-0000-000000000019',
  'b100001a-0000-0000-0000-00000000001a',
  'b1000005-0000-0000-0000-000000000005',
  'b1000017-0000-0000-0000-000000000017',
  'b1000007-0000-0000-0000-000000000007',
  'b1000011-0000-0000-0000-000000000011',
  'b100001b-0000-0000-0000-00000000001b',
  'b100001c-0000-0000-0000-00000000001c',
  'b100001d-0000-0000-0000-00000000001d'
)
ORDER BY a.name;

COMMIT;
