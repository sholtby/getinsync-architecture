-- =============================================================================
-- COR Cost Seeding Part 2: IT Service Allocations
-- =============================================================================
-- Purpose:  Set allocation_basis + allocation_value on deployment_profile_it_services
--           rows so IT service costs flow through to app Cost Summaries and the
--           Overview dashboard run rate.
--
-- Scope:    COR namespace only (a1b2c3d4-e5f6-7890-abcd-ef1234567890)
-- Action:   UPDATE existing rows + INSERT ~8 missing links
-- Safety:   Idempotent — UPDATEs overwrite, INSERTs use ON CONFLICT DO NOTHING
-- Run in:   Supabase SQL Editor
-- =============================================================================

BEGIN;

-- =============================================================================
-- Section 1: UPDATE existing dpis rows — set allocation_basis + allocation_value
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Windows Server Hosting (b4000001) — $180,000, per_instance, 10 consumers × 10%
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000001-0000-0000-0000-000000000001'
  AND deployment_profile_id IN (
    'b500000a-0000-0000-0000-00000000000a',  -- Active Directory
    'b5000010-0000-0000-0000-000000000010',  -- Cayenta Financials
    'b5000006-0000-0000-0000-000000000006',  -- Computer-Aided Dispatch
    'b5000013-0000-0000-0000-000000000013',  -- Emergency Response System
    'b500000b-0000-0000-0000-00000000000b',  -- Esri ArcGIS Enterprise
    'b5000014-0000-0000-0000-000000000014',  -- Fire Records Management
    'b5000001-0000-0000-0000-000000000001',  -- Hexagon OnCall CAD/RMS
    'b500000e-0000-0000-0000-00000000000e',  -- Hyland OnBase
    'b5000018-0000-0000-0000-000000000018',  -- Kronos Workforce Central
    'b500000f-0000-0000-0000-00000000000f'   -- Microsoft Dynamics GP
  );
-- Expected: 10 rows updated

-- ---------------------------------------------------------------------------
-- SQL Server Database Services (b4000003) — $120,000, per_instance
-- 6 consumers × 15% + 1 consumer × 10%
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 15, updated_at = now()
WHERE it_service_id = 'b4000003-0000-0000-0000-000000000003'
  AND deployment_profile_id IN (
    'b5000006-0000-0000-0000-000000000006',  -- Computer-Aided Dispatch
    'b500000b-0000-0000-0000-00000000000b',  -- Esri ArcGIS Enterprise
    'b5000014-0000-0000-0000-000000000014',  -- Fire Records Management
    'b5000001-0000-0000-0000-000000000001',  -- Hexagon OnCall CAD/RMS
    'b500000e-0000-0000-0000-00000000000e',  -- Hyland OnBase
    'b5000018-0000-0000-0000-000000000018'   -- Kronos Workforce Central
  );
-- Expected: 6 rows updated

UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000003-0000-0000-0000-000000000003'
  AND deployment_profile_id = 'b5000008-0000-0000-0000-000000000008';  -- Police Records Management
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- Oracle Database Services (b4000004) — $95,000, per_instance, 1 consumer
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 100, updated_at = now()
WHERE it_service_id = 'b4000004-0000-0000-0000-000000000004'
  AND deployment_profile_id = 'b5000010-0000-0000-0000-000000000010';  -- Cayenta Financials
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- GIS Platform (b400000b) — $100,000, per_instance, 1 consumer
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 100, updated_at = now()
WHERE it_service_id = 'b400000b-0000-0000-0000-00000000000b'
  AND deployment_profile_id = 'b500000b-0000-0000-0000-00000000000b';  -- Esri ArcGIS Enterprise
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- Identity & Access Management (b4000008) — $327,000, per_user
-- Split by org size: large 15%, medium 10%, small 5%
-- ---------------------------------------------------------------------------
-- Large apps (15%)
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 15, updated_at = now()
WHERE it_service_id = 'b4000008-0000-0000-0000-000000000008'
  AND deployment_profile_id IN (
    'b5000001-0000-0000-0000-000000000001',  -- Hexagon OnCall CAD/RMS
    'b5000018-0000-0000-0000-000000000018'   -- Kronos Workforce Central
  );
-- Expected: 2 rows updated

-- Medium apps (10%)
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000008-0000-0000-0000-000000000008'
  AND deployment_profile_id IN (
    'b5000019-0000-0000-0000-000000000019',  -- Accela Civic Platform
    'b5000017-0000-0000-0000-000000000017'   -- NEOGOV
  );
-- Expected: 2 rows updated

-- Small apps (5%)
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 5, updated_at = now()
WHERE it_service_id = 'b4000008-0000-0000-0000-000000000008'
  AND deployment_profile_id IN (
    'b5000005-0000-0000-0000-000000000005',  -- CopLogic Online Reporting
    'b5000011-0000-0000-0000-000000000011',  -- Questica Budget
    'b500001c-0000-0000-0000-00000000001c',  -- SeeClickFix
    'b500001b-0000-0000-0000-00000000001b'   -- Samsara Fleet
  );
-- Expected: 4 rows updated

-- ---------------------------------------------------------------------------
-- Collaboration & Conferencing (b400000c) — $24,000, per_user, 2 consumers × 50%
-- Note: Neither link exists yet — handled in INSERT section below
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Microsoft 365 Enterprise (b400000a) — $1,038,000, per_user, 2 consumers × 50%
-- Only M365 app link exists; Dynamics GP link is inserted below
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 50, updated_at = now()
WHERE it_service_id = 'b400000a-0000-0000-0000-00000000000a'
  AND deployment_profile_id = 'b500000d-0000-0000-0000-00000000000d';  -- Microsoft 365
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- Azure Cloud Hosting (b4000002) — $500,000, consumption
-- ArcGIS 40%, Emergency Response 30%, NG911 30%
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 40, updated_at = now()
WHERE it_service_id = 'b4000002-0000-0000-0000-000000000002'
  AND deployment_profile_id = 'b500000b-0000-0000-0000-00000000000b';  -- Esri ArcGIS Enterprise
-- Expected: 1 row updated

UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 30, updated_at = now()
WHERE it_service_id = 'b4000002-0000-0000-0000-000000000002'
  AND deployment_profile_id IN (
    'b5000013-0000-0000-0000-000000000013',  -- Emergency Response System
    'b5000007-0000-0000-0000-000000000007'   -- NG911 System
  );
-- Expected: 2 rows updated

-- ---------------------------------------------------------------------------
-- Enterprise Backup & Recovery (b4000005) — $142,000, fixed, 4 consumers × 25%
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 25, updated_at = now()
WHERE it_service_id = 'b4000005-0000-0000-0000-000000000005'
  AND deployment_profile_id IN (
    'b5000010-0000-0000-0000-000000000010',  -- Cayenta Financials
    'b5000014-0000-0000-0000-000000000014',  -- Fire Records Management
    'b5000001-0000-0000-0000-000000000001',  -- Hexagon OnCall CAD/RMS
    'b500000e-0000-0000-0000-00000000000e'   -- Hyland OnBase
  );
-- Expected: 4 rows updated

-- ---------------------------------------------------------------------------
-- Tyler Incode Court — Windows + SQL (10% each, already covered above?
-- Windows 10% is in the 10-consumer list above. SQL needs its own update.
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000003-0000-0000-0000-000000000003'
  AND deployment_profile_id = 'b500001e-0000-0000-0000-00000000001e';  -- Tyler Incode Court → SQL Server
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- Sage 300 GL — Windows 10% per plan. Oracle 50% handled in INSERT section.
-- Sage → SQL Server link exists but plan doesn't specify allocation — left NULL.
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000001-0000-0000-0000-000000000001'
  AND deployment_profile_id = 'b5000012-0000-0000-0000-000000000012';  -- Sage 300 → Windows
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- Tyler Incode Court — Windows 10% (not in the 10-consumer Windows list above,
-- but plan says 10% each for Windows + SQL)
-- ---------------------------------------------------------------------------
UPDATE deployment_profile_it_services
SET allocation_basis = 'percent', allocation_value = 10, updated_at = now()
WHERE it_service_id = 'b4000001-0000-0000-0000-000000000001'
  AND deployment_profile_id = 'b500001e-0000-0000-0000-00000000001e';  -- Tyler Incode Court → Windows
-- Expected: 1 row updated

-- ---------------------------------------------------------------------------
-- ServiceDesk Plus — Windows 10% (in 10-consumer list above, already covered)
-- PRTG — Windows (not in plan's 10-consumer list — leave as dependency only)
-- ---------------------------------------------------------------------------


-- =============================================================================
-- Section 2: INSERT new dpis rows for missing links
-- =============================================================================

INSERT INTO deployment_profile_it_services
  (deployment_profile_id, it_service_id, relationship_type, allocation_basis, allocation_value, source, notes)
VALUES
  -- IAM links (5% small apps)
  ('b500001a-0000-0000-0000-00000000001a', 'b4000008-0000-0000-0000-000000000008', 'depends_on', 'percent', 5, 'manual', 'CivicPlus → IAM (cost seeding part 2)'),
  ('b500000c-0000-0000-0000-00000000000c', 'b4000008-0000-0000-0000-000000000008', 'depends_on', 'percent', 5, 'manual', 'PRTG → IAM (cost seeding part 2)'),
  ('b500001d-0000-0000-0000-00000000001d', 'b4000008-0000-0000-0000-000000000008', 'depends_on', 'percent', 5, 'manual', 'Sensus FlexNet → IAM (cost seeding part 2)'),
  ('b500001e-0000-0000-0000-00000000001e', 'b4000008-0000-0000-0000-000000000008', 'depends_on', 'percent', 10, 'manual', 'Tyler Incode Court → IAM (cost seeding part 2)'),

  -- M365 Enterprise link for Dynamics GP (50%)
  ('b500000f-0000-0000-0000-00000000000f', 'b400000a-0000-0000-0000-00000000000a', 'depends_on', 'percent', 50, 'manual', 'Dynamics GP → M365 Enterprise (cost seeding part 2)'),

  -- Collaboration & Conferencing links (50% each)
  ('b500000d-0000-0000-0000-00000000000d', 'b400000c-0000-0000-0000-00000000000c', 'depends_on', 'percent', 50, 'manual', 'Microsoft 365 → Collab & Conf (cost seeding part 2)'),
  ('b500000f-0000-0000-0000-00000000000f', 'b400000c-0000-0000-0000-00000000000c', 'depends_on', 'percent', 50, 'manual', 'Dynamics GP → Collab & Conf (cost seeding part 2)'),

  -- Sage 300 → Oracle Database Services (50%)
  ('b5000012-0000-0000-0000-000000000012', 'b4000004-0000-0000-0000-000000000004', 'depends_on', 'percent', 50, 'manual', 'Sage 300 GL → Oracle DB (cost seeding part 2)')

ON CONFLICT (deployment_profile_id, it_service_id) DO NOTHING;
-- Expected: 8 rows inserted


-- =============================================================================
-- Section 3: Verification
-- =============================================================================

-- Count of rows with non-NULL allocations (should be ~45 after updates + 8 inserts)
SELECT 'dpis_with_allocations' AS check,
       count(*) AS total
FROM deployment_profile_it_services
WHERE allocation_value IS NOT NULL
  AND deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001';

-- Spot-check: Hexagon OnCall — expect ~$120K IT service cost
SELECT 'hexagon_it_cost' AS check,
       sum(CASE
         WHEN dpis.allocation_basis = 'percent'
         THEN (its.annual_cost * dpis.allocation_value) / 100
         ELSE dpis.allocation_value
       END) AS total_it_cost
FROM deployment_profile_it_services dpis
JOIN it_services its ON its.id = dpis.it_service_id
WHERE dpis.deployment_profile_id = 'b5000001-0000-0000-0000-000000000001'
  AND dpis.allocation_value IS NOT NULL;

-- Spot-check: Microsoft 365 — expect ~$531K (M365 Enterprise 50% + Collab 50%)
SELECT 'microsoft_365_it_cost' AS check,
       sum(CASE
         WHEN dpis.allocation_basis = 'percent'
         THEN (its.annual_cost * dpis.allocation_value) / 100
         ELSE dpis.allocation_value
       END) AS total_it_cost
FROM deployment_profile_it_services dpis
JOIN it_services its ON its.id = dpis.it_service_id
WHERE dpis.deployment_profile_id = 'b500000d-0000-0000-0000-00000000000d'
  AND dpis.allocation_value IS NOT NULL;

-- Total allocated IT service cost across all COR apps
SELECT 'total_allocated_it_cost' AS check,
       sum(CASE
         WHEN dpis.allocation_basis = 'percent'
         THEN (its.annual_cost * dpis.allocation_value) / 100
         ELSE dpis.allocation_value
       END) AS total
FROM deployment_profile_it_services dpis
JOIN it_services its ON its.id = dpis.it_service_id
WHERE dpis.deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001'
  AND dpis.allocation_value IS NOT NULL;

COMMIT;
