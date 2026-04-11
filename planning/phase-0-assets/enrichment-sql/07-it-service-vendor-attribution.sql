-- Chunk: 07-it-service-vendor-attribution.sql
-- Purpose: Data repair — populate vendor_org_id on all 11 Riverside IT
--          services. Currently 100% are NULL, which makes vendor cost
--          analysis report "Unknown (IT Service): $2.56M" (73% of
--          total namespace spend) and breaks vendor-consolidation
--          questions in the AI Chat harness.
-- Context: Discovered during AI Chat harness testing (2026-04-10). Cost
--          bundles have real vendor attribution post-Phase-0; IT services
--          were left blank. This chunk closes that gap.
-- Preconditions:
--   - Tables touched: it_services (UPDATE only)
--   - All target vendor organizations already exist in Riverside
--     (d6774bf5..., etc). No new orgs are created by this chunk.
--   - Idempotent via WHERE vendor_org_id IS NULL guards.
--   - Does NOT change annual_cost / budget_amount / contract fields —
--     the overview $3.0M Annual Run Rate KPI is preserved.
--   - Namespace scoping: it_services HAS namespace_id, so every UPDATE
--     filters on namespace_id directly (unlike apps/DPs — Garland lesson
--     12 does not apply here).
--   - applications has NO namespace_id column (Garland lesson 12),
--     but this chunk does not touch applications.
-- Namespace scope: a1b2c3d4-e5f6-7890-abcd-ef1234567890 (City of Riverside)

BEGIN;

-- Microsoft — 4 services ($1,838,000 combined, 61.8% of IT service spend)
UPDATE it_services SET vendor_org_id = '7d738823-9033-45f6-b26b-0d435b86ac9a', updated_at = now()
WHERE id = 'b400000a-0000-0000-0000-00000000000a'  -- Microsoft 365 Enterprise
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

UPDATE it_services SET vendor_org_id = '7d738823-9033-45f6-b26b-0d435b86ac9a', updated_at = now()
WHERE id = 'b4000002-0000-0000-0000-000000000002'  -- Azure Cloud Hosting
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

UPDATE it_services SET vendor_org_id = '7d738823-9033-45f6-b26b-0d435b86ac9a', updated_at = now()
WHERE id = 'b4000001-0000-0000-0000-000000000001'  -- Windows Server Hosting
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

UPDATE it_services SET vendor_org_id = '7d738823-9033-45f6-b26b-0d435b86ac9a', updated_at = now()
WHERE id = 'b4000003-0000-0000-0000-000000000003'  -- SQL Server Database Services
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Okta — Identity & Access Management ($327,000)
UPDATE it_services SET vendor_org_id = 'acbb0246-d508-4369-9ca0-8c0d67cc5383', updated_at = now()
WHERE id = 'b4000008-0000-0000-0000-000000000008'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Cisco Systems — Network Infrastructure ($250,000)
UPDATE it_services SET vendor_org_id = 'd1000016-0000-0000-0000-000000000016', updated_at = now()
WHERE id = 'b4000006-0000-0000-0000-000000000006'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Tenable Inc. — Cybersecurity Operations ($200,000)
UPDATE it_services SET vendor_org_id = 'd1000011-0000-0000-0000-000000000011', updated_at = now()
WHERE id = 'b4000007-0000-0000-0000-000000000007'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Commvault Systems Inc. — Enterprise Backup & Recovery ($142,000)
UPDATE it_services SET vendor_org_id = 'a33078be-9e6a-4a6e-acc5-92156421a699', updated_at = now()
WHERE id = 'b4000005-0000-0000-0000-000000000005'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Esri Inc. — GIS Platform ($100,000)
UPDATE it_services SET vendor_org_id = 'd1000007-0000-0000-0000-000000000007', updated_at = now()
WHERE id = 'b400000b-0000-0000-0000-00000000000b'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Oracle Corporation — Oracle Database Services ($95,000)
UPDATE it_services SET vendor_org_id = '99226739-086b-406b-a5d9-81ef09937b32', updated_at = now()
WHERE id = 'b4000004-0000-0000-0000-000000000004'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Zoom Video Communications Inc. — Collaboration & Conferencing ($24,000)
UPDATE it_services SET vendor_org_id = 'd1000012-0000-0000-0000-000000000012', updated_at = now()
WHERE id = 'b400000c-0000-0000-0000-00000000000c'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND vendor_org_id IS NULL;

-- Verification: consolidated into ONE SELECT (Supabase SQL Editor shows
-- only the last result set — see CLAUDE.md Database Access rule).
-- Returns: (a) per-service attribution, (b) vendor rollup with % of total,
-- (c) overall counts.
WITH riverside_its AS (
  SELECT its.id, its.name, its.annual_cost, its.vendor_org_id,
         o.name AS vendor_name
  FROM it_services its
  LEFT JOIN organizations o ON o.id = its.vendor_org_id
  WHERE its.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
total AS (SELECT sum(annual_cost)::numeric AS grand_total FROM riverside_its),
vendor_rollup AS (
  SELECT COALESCE(vendor_name, '(unattributed)') AS vendor_name,
         count(*)            AS service_count,
         sum(annual_cost)    AS annual_spend,
         round((sum(annual_cost) * 100.0 / (SELECT grand_total FROM total)), 1) AS pct_of_total
  FROM riverside_its
  GROUP BY COALESCE(vendor_name, '(unattributed)')
)
SELECT ord, section, details FROM (
  SELECT 1 AS ord, '07a counts' AS section,
         jsonb_build_object(
           'total_services',        count(*),
           'services_attributed',   count(*) FILTER (WHERE vendor_org_id IS NOT NULL),
           'services_unattributed', count(*) FILTER (WHERE vendor_org_id IS NULL),
           'unchanged_annual_cost', sum(annual_cost)
         ) AS details
  FROM riverside_its
  UNION ALL
  SELECT 2, '07b ' || name,
         jsonb_build_object(
           'annual_cost', annual_cost,
           'vendor',      vendor_name
         )
  FROM riverside_its
  UNION ALL
  SELECT 3, '07c vendor rollup: ' || vendor_name,
         jsonb_build_object(
           'services',     service_count,
           'annual_spend', annual_spend,
           'pct_of_total', pct_of_total
         )
  FROM vendor_rollup
) x
ORDER BY ord, section;

COMMIT;

-- Rollback: UPDATE it_services SET vendor_org_id = NULL WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' AND id IN ('b400000a-0000-0000-0000-00000000000a','b4000002-0000-0000-0000-000000000002','b4000001-0000-0000-0000-000000000001','b4000003-0000-0000-0000-000000000003','b4000008-0000-0000-0000-000000000008','b4000006-0000-0000-0000-000000000006','b4000007-0000-0000-0000-000000000007','b4000005-0000-0000-0000-000000000005','b400000b-0000-0000-0000-00000000000b','b4000004-0000-0000-0000-000000000004','b400000c-0000-0000-0000-00000000000c');
