-- Chunk: 06-cost-bundle-dps-showcase.sql
-- Purpose: Article 4.3 (Cost Analysis) — Cost Bundle channel.
--          The CAD showcase app's "Recurring Costs" section currently reads
--          $0 because no cost_bundle DPs link to it. This chunk seeds two
--          realistic cost_bundle deployment profiles on the Police Dept
--          showcase apps (Computer-Aided Dispatch and Hexagon OnCall CAD/RMS)
--          so the article can screenshot the three-channel cost story
--          (Software Product inventory → IT Service cost pool → Cost Bundle).
--
--          NG911 System already has a cost_bundle DP ("NG911 System — Cloud
--          License", $180,000/yr, id e53432ea-115e-4e96-ab1c-7601de48c310),
--          so it is NOT re-seeded here.
--
-- Preconditions:
--   - Tables touched: organizations (INSERT one vendor), deployment_profiles (INSERT two)
--   - Cost Bundle is NOT a separate table — it is deployment_profiles.dp_type = 'cost_bundle'
--     per docs-architecture/features/cost-budget/cost-model.md §3.3 and §12.
--   - dp_type check constraint: 'application','platform_tenant','infrastructure','cost_bundle'
--   - cost_recurrence check constraint: 'recurring','one_time'
--   - Views vw_portfolio_costs / vw_portfolio_costs_rollup aggregate
--     cost_bundle DPs with cost_recurrence='recurring' into bundle_cost.
--   - Idempotent via WHERE NOT EXISTS guards on both the vendor org and
--     the DPs (keyed by (application_id, name, dp_type)).
-- Namespace scope: all IDs below belong to Riverside. vendor org INSERT
--                  is scoped by namespace_id. deployment_profiles itself
--                  has NO namespace_id column — see Garland lesson 12;
--                  scoping to Riverside is enforced by targeting specific
--                  application_id and workspace_id values.
-- Trigger audit (per Garland lessons review, 2026-04-10):
--   - create_deployment_profile_on_app_create (Garland lesson 5) fires only
--     on applications INSERT. This chunk inserts directly into
--     deployment_profiles, so that auto-DP trigger is not in play and
--     there is no risk of doubled DPs.
--   - trigger_auto_calculate_tech_scores (BEFORE INSERT OR UPDATE OF t01..t15
--     on deployment_profiles) fires on every INSERT. The cost_bundle rows
--     below have all t-scores NULL; calculate_tech_health() and
--     calculate_tech_risk() both return NULL for all-NULL input, so
--     tech_health and tech_risk will be NULL on the new rows — matching the
--     14 pre-existing cost_bundle DPs already in Riverside.
--   - audit_deployment_profiles audit trigger reads NEW.namespace_id via
--     to_jsonb; since deployment_profiles has no such column, the audit
--     row lands with namespace_id NULL (audit_logs.namespace_id is nullable
--     — safe).

BEGIN;

-- Step 1: Seed a CentralSquare vendor org for the CAD bundle if it doesn't
-- already exist in Riverside. Hexagon AB already exists and is reused below.
INSERT INTO organizations (
  id, namespace_id, owner_workspace_id, name, legal_name, website,
  primary_email, is_vendor, is_active, is_shared, notes
)
SELECT
  gen_random_uuid(),
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',                -- Riverside namespace
  'a1b2c3d4-0001-0000-0000-000000000001',                -- owned by IT workspace
  'CentralSquare Technologies',
  'CentralSquare Technologies, LLC',
  'https://www.centralsquare.com',
  'support@centralsquare-demo.example',
  true,
  true,
  false,
  'Demo vendor seed for Phase 0 cost-bundle showcase'
WHERE NOT EXISTS (
  SELECT 1 FROM organizations
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND lower(name)  = lower('CentralSquare Technologies')
);

-- Step 2: Cost bundle #1 — CAD support contract (CentralSquare)
-- Anchored to Computer-Aided Dispatch application in Police Department workspace.
-- Contract dates: started 2024-07-01, ends 2027-06-30 (safe horizon).
INSERT INTO deployment_profiles (
  application_id, workspace_id, name, dp_type, cost_recurrence,
  annual_cost, vendor_org_id, contract_reference,
  contract_start_date, contract_end_date, renewal_notice_days,
  is_primary, environment, operational_status
)
SELECT
  'b1000006-0000-0000-0000-000000000006',   -- Computer-Aided Dispatch
  'a1b2c3d4-0006-0000-0000-000000000006',   -- Police Department workspace
  'CentralSquare CAD Support Contract',
  'cost_bundle',
  'recurring',
  85000.00,
  (SELECT id FROM organizations
   WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
     AND lower(name)  = lower('CentralSquare Technologies')
   LIMIT 1),
  'CS-2024-CAD-0412',
  DATE '2024-07-01',
  DATE '2027-06-30',
  90,
  false,
  'PROD',
  'operational'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE application_id = 'b1000006-0000-0000-0000-000000000006'
    AND dp_type        = 'cost_bundle'
    AND name           = 'CentralSquare CAD Support Contract'
);

-- Step 3: Cost bundle #2 — Hexagon OnCall managed services (Hexagon AB)
-- Anchored to Hexagon OnCall CAD/RMS in Police Department workspace.
-- Contract dates: started 2023-10-01, ends 2026-09-30 (near-expiry window,
-- ~5 months out — drives a renewal alert for the article screenshot).
INSERT INTO deployment_profiles (
  application_id, workspace_id, name, dp_type, cost_recurrence,
  annual_cost, vendor_org_id, contract_reference,
  contract_start_date, contract_end_date, renewal_notice_days,
  is_primary, environment, operational_status
)
SELECT
  'b1000001-0000-0000-0000-000000000001',   -- Hexagon OnCall CAD/RMS
  'a1b2c3d4-0006-0000-0000-000000000006',   -- Police Department workspace
  'Hexagon OnCall Managed Services Agreement',
  'cost_bundle',
  'recurring',
  110000.00,
  'c9245885-829e-45a3-bffb-7b6df92c4b34',   -- Hexagon AB (existing vendor)
  'HEX-2023-ONCALL-0904',
  DATE '2023-10-01',
  DATE '2026-09-30',
  90,
  false,
  'PROD',
  'operational'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE application_id = 'b1000001-0000-0000-0000-000000000001'
    AND dp_type        = 'cost_bundle'
    AND name           = 'Hexagon OnCall Managed Services Agreement'
);

-- Verification: consolidated into ONE SELECT (Supabase SQL Editor shows
-- only the last result set of a multi-statement query). Combines the
-- cost-bundle listing, per-app recurring total, and the view rollup.
WITH showcase_apps(app_id) AS (
  VALUES
    ('b1000006-0000-0000-0000-000000000006'::uuid),  -- CAD
    ('b1000001-0000-0000-0000-000000000001'::uuid),  -- Hexagon OnCall CAD/RMS
    ('b1000007-0000-0000-0000-000000000007'::uuid)   -- NG911 System
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
  SELECT 1 AS ord, '06a ' || app_name || ' — ' || bundle_name AS section,
         jsonb_build_object(
           'cost_recurrence', cost_recurrence,
           'annual_cost',     annual_cost,
           'vendor',          vendor,
           'contract_ref',    contract_reference,
           'contract_end',    contract_end_date
         ) AS details
  FROM bundles
  UNION ALL
  SELECT 2, '06b ' || app_name,
         jsonb_build_object(
           'cost_bundle_count',      cost_bundle_count,
           'recurring_bundle_total', recurring_bundle_total
         )
  FROM per_app
  UNION ALL
  SELECT 3, '06c ' || application_name || ' / ' || deployment_profile_name,
         jsonb_build_object(
           'software_cost', software_cost,
           'service_cost',  service_cost,
           'bundle_cost',   bundle_cost,
           'total_cost',    total_cost
         )
  FROM view_rollup
) x
ORDER BY ord, section;

COMMIT;

-- Rollback: DELETE FROM deployment_profiles WHERE dp_type = 'cost_bundle' AND application_id IN ('b1000006-0000-0000-0000-000000000006','b1000001-0000-0000-0000-000000000001') AND name IN ('CentralSquare CAD Support Contract','Hexagon OnCall Managed Services Agreement'); DELETE FROM organizations WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' AND name = 'CentralSquare Technologies';
