-- =============================================================================
-- CSDM Demo Data Consistency — "18-Year-Old Test" Readiness
-- Date: 2026-04-05
-- Purpose: Populate junction tables, fix manufacturers, add is_org_wide flag
-- Prerequisite: A.1.1 and A.1.2 already applied (contract columns + vw_contract_expiry)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: Create missing vendor organizations
-- ─────────────────────────────────────────────────────────────────────────────
-- Namespace: b00adf2d-4584-4bb4-a889-6931782960dc (City of Riverside)
-- Existing: Microsoft Corporation (3be083be), Oracle Corporation (99226739),
--           Okta Inc. (acbb0246), Commvault Systems Inc. (a33078be),
--           Broadcom Inc./VMware (13e90c9b), SAP SE (e7b6ffbe), Avaya Inc. (a67fd6ce)

INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_active) VALUES
  ('d0000001-0000-0000-0000-000000000001', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Adobe Inc.', true, true, true),
  ('d0000002-0000-0000-0000-000000000002', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Autodesk Inc.', true, true, true),
  ('d0000003-0000-0000-0000-000000000003', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Bentley Systems Inc.', true, true, true),
  ('d0000004-0000-0000-0000-000000000004', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Nemetschek Group (Bluebeam)', true, true, true),
  ('d0000005-0000-0000-0000-000000000005', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Box Inc.', true, true, true),
  ('d0000006-0000-0000-0000-000000000006', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'DocuSign Inc.', true, true, true),
  ('d0000007-0000-0000-0000-000000000007', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Esri Inc.', true, true, true),
  ('d0000008-0000-0000-0000-000000000008', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Mimecast Ltd.', true, true, true),
  ('d0000009-0000-0000-0000-000000000009', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'ServiceNow Inc.', true, true, true),
  ('d0000010-0000-0000-0000-000000000010', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Smartsheet Inc.', true, true, true),
  ('d0000011-0000-0000-0000-000000000011', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Tenable Inc.', true, true, true),
  ('d0000012-0000-0000-0000-000000000012', 'b00adf2d-4584-4bb4-a889-6931782960dc', 'Zoom Video Communications Inc.', true, true, true)
ON CONFLICT (id) DO NOTHING;

-- GitHub is owned by Microsoft — use Microsoft Corporation
-- Crystal Reports is SAP — use SAP SE (e7b6ffbe)
-- VMware vSphere is Broadcom — use Broadcom Inc. (13e90c9b)

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: Set manufacturer_org_id on orphaned software products
-- ─────────────────────────────────────────────────────────────────────────────

-- Adobe products → Adobe Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000001-0000-0000-0000-000000000001'
WHERE id IN ('c0000020-0000-0000-0000-000000000020', 'c0000006-0000-0000-0000-000000000006');
-- Adobe Acrobat Pro, Adobe Creative Cloud

-- AutoCAD → Autodesk Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000002-0000-0000-0000-000000000002'
WHERE id = 'c0000019-0000-0000-0000-000000000019';

-- Avaya OneCloud → Avaya Inc.
UPDATE software_products SET manufacturer_org_id = 'a67fd6ce-b52b-40d9-ab41-9f6bcc9a396c'
WHERE id = 'c0000003-0000-0000-0000-000000000003';

-- Bentley MicroStation → Bentley Systems Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000003-0000-0000-0000-000000000003'
WHERE id = 'c0000009-0000-0000-0000-000000000009';

-- Bluebeam Revu → Nemetschek Group
UPDATE software_products SET manufacturer_org_id = 'd0000004-0000-0000-0000-000000000004'
WHERE id = 'c0000018-0000-0000-0000-000000000018';

-- Box Enterprise → Box Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000005-0000-0000-0000-000000000005'
WHERE id = 'c0000013-0000-0000-0000-000000000013';

-- Commvault → Commvault Systems Inc. (existing)
UPDATE software_products SET manufacturer_org_id = 'a33078be-9e6a-4a6e-acc5-92156421a699'
WHERE id = 'c0000004-0000-0000-0000-000000000004';

-- Crystal Reports → SAP SE (existing)
UPDATE software_products SET manufacturer_org_id = 'e7b6ffbe-7184-4846-aece-85f1ba36b073'
WHERE id = 'c0000016-0000-0000-0000-000000000016';

-- DocuSign → DocuSign Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000006-0000-0000-0000-000000000006'
WHERE id = 'c0000015-0000-0000-0000-000000000015';

-- Esri ArcGIS Pro → Esri Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000007-0000-0000-0000-000000000007'
WHERE id = 'c0000012-0000-0000-0000-000000000012';

-- GitHub → Microsoft Corporation (existing)
UPDATE software_products SET manufacturer_org_id = '3be083be-9a01-4f53-9b3a-405535ac6e5d'
WHERE id = '08701b09-f51f-457c-88af-912baf734f2e';

-- Microsoft 365, Microsoft Dynamics GP → Microsoft Corporation (existing)
UPDATE software_products SET manufacturer_org_id = '3be083be-9a01-4f53-9b3a-405535ac6e5d'
WHERE id IN ('c0000001-0000-0000-0000-000000000001', 'c0000021-0000-0000-0000-000000000021');

-- Mimecast → Mimecast Ltd.
UPDATE software_products SET manufacturer_org_id = 'd0000008-0000-0000-0000-000000000008'
WHERE id = 'c0000011-0000-0000-0000-000000000011';

-- Okta → Okta Inc. (existing)
UPDATE software_products SET manufacturer_org_id = 'acbb0246-d508-4369-9ca0-8c0d67cc5383'
WHERE id = 'c0000002-0000-0000-0000-000000000002';

-- Oracle Database → Oracle Corporation (existing)
UPDATE software_products SET manufacturer_org_id = '99226739-086b-406b-a5d9-81ef09937b32'
WHERE id = 'c0000007-0000-0000-0000-000000000007';

-- ServiceNow → ServiceNow Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000009-0000-0000-0000-000000000009'
WHERE id = 'c0000008-0000-0000-0000-000000000008';

-- Smartsheet → Smartsheet Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000010-0000-0000-0000-000000000010'
WHERE id = 'c0000010-0000-0000-0000-000000000010';

-- Tenable Nessus → Tenable Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000011-0000-0000-0000-000000000011'
WHERE id = 'c0000017-0000-0000-0000-000000000017';

-- VMware vSphere → Broadcom Inc. (existing)
UPDATE software_products SET manufacturer_org_id = '13e90c9b-974a-4e9c-95a8-a7931a1cd922'
WHERE id = 'c0000005-0000-0000-0000-000000000005';

-- Zoom → Zoom Video Communications Inc.
UPDATE software_products SET manufacturer_org_id = 'd0000012-0000-0000-0000-000000000012'
WHERE id = 'c0000014-0000-0000-0000-000000000014';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3: Populate it_service_technology_products (CRITICAL GAP)
-- ─────────────────────────────────────────────────────────────────────────────
-- This connects the CSDM chain: IT Service ↔ Technology Product

INSERT INTO it_service_technology_products (id, it_service_id, technology_product_id, notes) VALUES

  -- Application Hosting → Windows Server 2019, 2022
  (gen_random_uuid(), 'e0000005-0000-0000-0000-000000000005', '5bba4fe9-653d-493b-b6b4-93ed5cd4e93e', 'Primary VM host OS'),
  (gen_random_uuid(), 'e0000005-0000-0000-0000-000000000005', 'f0000002-0000-0000-0000-000000000002', 'Target migration OS'),

  -- Server Hosting - Windows → Windows Server 2016, 2019, 2022
  (gen_random_uuid(), '15630fde-e994-4474-a070-a5e8519c5798', 'ed3632ed-c675-4ad6-aef6-1f71688ff4c3', 'Legacy servers'),
  (gen_random_uuid(), '15630fde-e994-4474-a070-a5e8519c5798', '5bba4fe9-653d-493b-b6b4-93ed5cd4e93e', 'Standard server OS'),
  (gen_random_uuid(), '15630fde-e994-4474-a070-a5e8519c5798', 'f0000002-0000-0000-0000-000000000002', 'Current standard'),

  -- Azure Cloud Hosting (e0000001) → Microsoft Azure
  (gen_random_uuid(), 'e0000001-0000-0000-0000-000000000001', 'ca9f9dc4-a634-4098-a679-ce9fa7798ac9', 'Azure cloud platform'),
  -- Azure Cloud Hosting (544dfd0b) → Microsoft Azure
  (gen_random_uuid(), '544dfd0b-6276-433e-b1de-b5e20f964f6e', 'ca9f9dc4-a634-4098-a679-ce9fa7798ac9', 'Azure cloud platform'),

  -- Cloud Hosting - AWS → Amazon Web Services
  (gen_random_uuid(), 'c6e3dd41-836c-41fa-a42c-f3d64811d905', '397a260e-031f-4022-b18e-cae368f33fc9', 'AWS cloud platform'),

  -- Cloud Hosting - Azure → Microsoft Azure
  (gen_random_uuid(), 'cd3c516f-802b-4a6d-bb08-94f80a91217d', 'ca9f9dc4-a634-4098-a679-ce9fa7798ac9', 'Azure cloud platform'),

  -- Cloud Hosting - Oracle → Oracle Cloud
  (gen_random_uuid(), '19b3ff5c-088f-4083-818c-8a2adfa06cb9', 'b70b8951-126b-4307-a6b4-1529c16de90f', 'Oracle cloud platform'),

  -- Database Hosting - SQL Server → SQL Server 2016, 2019, 2022
  (gen_random_uuid(), '5b5af98b-91ba-43c0-b872-feb1f01f0814', '7dcc4b6b-14a6-4455-832d-6b666a3f00c9', 'SQL Server 2016 instances'),
  (gen_random_uuid(), '5b5af98b-91ba-43c0-b872-feb1f01f0814', 'f0000001-0000-0000-0000-000000000001', 'SQL Server 2019 instances'),
  (gen_random_uuid(), '5b5af98b-91ba-43c0-b872-feb1f01f0814', '744c6cc4-912a-4561-9774-843a191c5e35', 'SQL Server 2022 instances'),

  -- Enterprise SQL Server Cluster → SQL Server 2019
  (gen_random_uuid(), 'cb4befd1-6923-4d76-897f-5f9a9df6f688', 'f0000001-0000-0000-0000-000000000001', 'Clustered SQL Server 2019'),
  -- Also Windows Server 2019 as host
  (gen_random_uuid(), 'cb4befd1-6923-4d76-897f-5f9a9df6f688', '5bba4fe9-653d-493b-b6b4-93ed5cd4e93e', 'Cluster host OS'),

  -- Shared SQL Server Cluster → SQL Server 2019
  (gen_random_uuid(), '670b38cd-aaa0-41ff-b4f0-c187adddcea9', 'f0000001-0000-0000-0000-000000000001', 'Shared SQL Server 2019'),
  (gen_random_uuid(), '670b38cd-aaa0-41ff-b4f0-c187adddcea9', '5bba4fe9-653d-493b-b6b4-93ed5cd4e93e', 'Cluster host OS'),

  -- MySQL Database Cluster → MySQL 9.6
  (gen_random_uuid(), 'd82483bd-5fa5-498b-a698-c076d8bac3e5', 'ff9036b9-ccf5-4398-8fe7-336b495feb24', 'MySQL 9.6 cluster'),

  -- Oracle RAC Cluster → Oracle Database 19c (both entries)
  (gen_random_uuid(), 'd36d2450-0816-463c-9408-efaa76e8b2a1', 'eaae321e-4d4f-486b-baf2-b1f95ed74f4b', 'Oracle 19c RAC'),
  (gen_random_uuid(), 'd36d2450-0816-463c-9408-efaa76e8b2a1', 'fa38182b-8565-42d7-9a6d-7649a9885db0', 'RAC host OS - RHEL 8'),

  -- Database Services → SQL Server 2019, 2022, PostgreSQL 16
  (gen_random_uuid(), 'e0000008-0000-0000-0000-000000000008', 'f0000001-0000-0000-0000-000000000001', 'SQL Server 2019'),
  (gen_random_uuid(), 'e0000008-0000-0000-0000-000000000008', '744c6cc4-912a-4561-9774-843a191c5e35', 'SQL Server 2022'),
  (gen_random_uuid(), 'e0000008-0000-0000-0000-000000000008', '8b0f8d5b-3317-4bf7-aa50-04745ae1ebe2', 'PostgreSQL 16'),

  -- Enterprise Backup (cc733c64) → Windows Server 2022
  (gen_random_uuid(), 'cc733c64-60dc-4594-8671-d34269ecee5f', 'f0000002-0000-0000-0000-000000000002', 'Backup server OS'),

  -- Enterprise Backup (e0000007) → Windows Server 2022
  (gen_random_uuid(), 'e0000007-0000-0000-0000-000000000007', 'f0000002-0000-0000-0000-000000000002', 'Backup server OS'),

  -- IT Operations Monitoring → Windows Server 2022
  (gen_random_uuid(), '62f1b7d8-3c47-4461-8421-9ef92c83d92f', 'f0000002-0000-0000-0000-000000000002', 'Monitoring server OS'),

  -- Collaboration Platform → Microsoft SharePoint Online
  (gen_random_uuid(), 'c034848b-51a8-4308-90bd-4c9a3c818ab2', '1ba9aaca-e2a1-4bf4-b19e-dc9e5abebee7', 'SharePoint Online'),

  -- Low-Code Application Platform → Microsoft Power Apps
  (gen_random_uuid(), '06620a13-bdc8-4754-8b03-95aca6bed383', '8617b2d5-aa6a-425b-a542-a4c091e6ea45', 'Power Apps Online'),

  -- Cybersecurity Operations → Red Hat Enterprise Linux 8 (security appliance OS)
  (gen_random_uuid(), 'e0000003-0000-0000-0000-000000000003', 'fa38182b-8565-42d7-9a6d-7649a9885db0', 'Security appliance OS')

ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4: Populate it_service_software_products
-- ─────────────────────────────────────────────────────────────────────────────
-- Links IT Services to the software products that compose them

INSERT INTO it_service_software_products (id, it_service_id, software_product_id, notes) VALUES

  -- Application Hosting → VMware vSphere (hypervisor management)
  (gen_random_uuid(), 'e0000005-0000-0000-0000-000000000005', 'c0000005-0000-0000-0000-000000000005', 'VMware hypervisor platform'),

  -- Enterprise Backup → Commvault
  (gen_random_uuid(), 'cc733c64-60dc-4594-8671-d34269ecee5f', 'c0000004-0000-0000-0000-000000000004', 'Enterprise backup software'),
  (gen_random_uuid(), 'e0000007-0000-0000-0000-000000000007', 'c0000004-0000-0000-0000-000000000004', 'Enterprise backup software'),

  -- Cybersecurity Operations → Tenable Nessus
  (gen_random_uuid(), 'e0000003-0000-0000-0000-000000000003', 'c0000017-0000-0000-0000-000000000017', 'Vulnerability scanner'),

  -- Collaboration Platform → Microsoft 365
  (gen_random_uuid(), 'c034848b-51a8-4308-90bd-4c9a3c818ab2', 'c0000001-0000-0000-0000-000000000001', 'M365 collaboration suite'),

  -- Help Desk Services → ServiceNow
  (gen_random_uuid(), 'e0000004-0000-0000-0000-000000000004', 'c0000008-0000-0000-0000-000000000008', 'ITSM platform'),

  -- IT Operations Monitoring → ServiceNow (monitoring integration)
  (gen_random_uuid(), '62f1b7d8-3c47-4461-8421-9ef92c83d92f', 'c0000008-0000-0000-0000-000000000008', 'Event management')

ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5: Add is_org_wide column to software_products
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE software_products ADD COLUMN IF NOT EXISTS is_org_wide boolean NOT NULL DEFAULT false;

-- Mark org-wide licenses (these don't need DP associations)
UPDATE software_products SET is_org_wide = true
WHERE id IN (
  'c0000001-0000-0000-0000-000000000001',  -- Microsoft 365
  'c0000006-0000-0000-0000-000000000006',  -- Adobe Creative Cloud
  'c0000014-0000-0000-0000-000000000014',  -- Zoom
  'c0000013-0000-0000-0000-000000000013',  -- Box Enterprise
  'c0000010-0000-0000-0000-000000000010',  -- Smartsheet
  'c0000015-0000-0000-0000-000000000015',  -- DocuSign
  'c0000020-0000-0000-0000-000000000020',  -- Adobe Acrobat Pro
  'c0000018-0000-0000-0000-000000000018',  -- Bluebeam Revu
  'c0000009-0000-0000-0000-000000000009',  -- Bentley MicroStation
  'c0000019-0000-0000-0000-000000000019'   -- AutoCAD
);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6: Grant + RLS for is_org_wide column (inherits existing table policies)
-- ─────────────────────────────────────────────────────────────────────────────
-- No new grants needed — column inherits table-level GRANT ALL to authenticated, service_role
-- No new RLS policies needed — column inherits existing row-level policies on software_products


-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────────────

-- Check 1: IT Service → Technology links populated
-- SELECT its.name as service, tp.name as technology, tp.version
-- FROM it_service_technology_products istp
-- JOIN it_services its ON istp.it_service_id = its.id
-- JOIN technology_products tp ON istp.technology_product_id = tp.id
-- ORDER BY its.name, tp.name;

-- Check 2: No orphaned manufacturers
-- SELECT name, manufacturer_org_id IS NULL as missing_mfr
-- FROM software_products
-- WHERE manufacturer_org_id IS NULL
-- ORDER BY name;

-- Check 3: Org-wide products flagged
-- SELECT name, is_org_wide, annual_cost
-- FROM software_products
-- WHERE is_org_wide = true
-- ORDER BY name;

-- Check 4: IT Service → Software links populated
-- SELECT its.name as service, sp.name as software
-- FROM it_service_software_products issp
-- JOIN it_services its ON issp.it_service_id = its.id
-- JOIN software_products sp ON issp.software_product_id = sp.id
-- ORDER BY its.name, sp.name;
