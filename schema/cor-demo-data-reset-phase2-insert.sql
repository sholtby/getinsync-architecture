-- =============================================================================
-- COR Demo Data Reset — Phase 2: INSERT consistent demo data
-- =============================================================================
-- Namespace: COR (City of Riverside)
-- Namespace ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
--
-- Purpose: Seed the COR namespace with a complete, presentation-ready
--          dataset after Phase 1 has cleared all existing data.
--
-- Safety:
--   - All INSERTs use ON CONFLICT DO NOTHING for idempotency
--   - Wrapped in a transaction — nothing commits until COMMIT runs
--   - To abort: replace COMMIT with ROLLBACK (or just close the session)
--   - Deterministic UUIDs (b1000001, b2000001, etc.) for easy cross-referencing
--
-- Run in: Supabase SQL Editor (service_role context bypasses RLS)
-- Prerequisites: Phase 1 (DELETE) must have been run first
-- Author: Claude Code + Stuart Holtby
-- Date: 2026-04-06
-- =============================================================================

BEGIN;

-- =============================================================================
-- Phase 2a: Pre-flight namespace check
-- =============================================================================

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
-- Phase 2a: Missing Vendor Organizations (4 new)
-- =============================================================================

INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_active)
VALUES
  ('d1000015-0000-0000-0000-000000000015', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'ManageEngine (Zoho Corp.)', true, true, true),
  ('d1000016-0000-0000-0000-000000000016', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Cisco Systems',            true, true, true),
  ('d1000017-0000-0000-0000-000000000017', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'ImageTrend Inc.',          true, true, true),
  ('d1000018-0000-0000-0000-000000000018', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Workday Inc.',             true, true, true)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2b: Technology Products (13)
-- =============================================================================

INSERT INTO technology_products (id, namespace_id, name, version, category_id, lifecycle_reference_id, manufacturer_id)
VALUES
  -- Operating Systems
  ('b2000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft Windows Server', '2019', '2c8a7767-7df1-4782-8b65-8e3b4f623dbe', '8fb18e2c-7992-4c05-acfc-d9adc55f87b3', '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  ('b2000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft Windows Server', '2022', '2c8a7767-7df1-4782-8b65-8e3b4f623dbe', '3ac3491f-3706-4ab5-b64e-96a2e78d7591', '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  ('b2000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Red Hat Enterprise Linux',  '8',    '2c8a7767-7df1-4782-8b65-8e3b4f623dbe', '77b201d0-d269-4d1b-b977-80ea2a5551d4', '9b44ad38-f14b-429f-b6ad-466b49defa8f'),
  -- Databases
  ('b2000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft SQL Server',     '2019', '68d37e67-6442-4cda-abbe-4b2dec62c69f', 'cf103888-97e0-467a-ab4b-63209f9feac2', '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  ('b2000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft SQL Server',     '2022', '68d37e67-6442-4cda-abbe-4b2dec62c69f', 'e6d4bb64-f2d1-46d3-a390-01e4ddd0c667', '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  ('b2000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Oracle Database',          '19c',  '68d37e67-6442-4cda-abbe-4b2dec62c69f', '9a4d8328-b841-4dd7-b027-00c65078966c', '99226739-086b-406b-a5d9-81ef09937b32'),
  ('b2000007-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'PostgreSQL',               '16',   '68d37e67-6442-4cda-abbe-4b2dec62c69f', '075656a5-4937-4371-bb8f-c8ac3873cea9', NULL),
  ('b2000008-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'MySQL',                    '8.0',  '68d37e67-6442-4cda-abbe-4b2dec62c69f', 'd66b97b5-fead-449f-80eb-652df5d30750', NULL),
  -- Compute
  ('b2000009-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft Azure',          NULL,   '2e7af92b-e5fc-48a9-bcd4-d3d4ad5d000b', NULL,                                    '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  -- Web Servers
  ('b200000a-0000-0000-0000-00000000000a', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft IIS',            '10',   '08938605-e0b6-434e-ab4e-823fec0afbdf', 'a1262a5d-d5fa-4d5f-9cb8-eea9f1ff32a5', '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  ('b200000b-0000-0000-0000-00000000000b', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Apache Tomcat',            '9.0',  '08938605-e0b6-434e-ab4e-823fec0afbdf', 'd4c7114a-2829-400f-b2d2-83f94186b68f', NULL),
  -- Middleware
  ('b200000c-0000-0000-0000-00000000000c', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft SharePoint',     'Online', 'a3b410df-0c6f-402d-9548-8c2744eae07b', NULL,                                  '7d738823-9033-45f6-b26b-0d435b86ac9a'),
  -- Runtime/PaaS
  ('b200000d-0000-0000-0000-00000000000d', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Microsoft Power Apps',     'Online', '7e8e7a17-744a-45f6-be39-2e3ab7575d01', NULL,                                  '7d738823-9033-45f6-b26b-0d435b86ac9a')
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2c: Software Products (16)
-- =============================================================================
-- All: namespace_id = COR, owner_workspace_id = IT, annual_cost = NULL
-- is_org_wide = true for org-wide licenses (M365, Adobe CC, Zoom)

INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, manufacturer_org_id, is_internal_only, is_org_wide, annual_cost)
VALUES
  ('b3000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Microsoft 365',                '7d738823-9033-45f6-b26b-0d435b86ac9a', false, true,  NULL),
  ('b3000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Adobe Creative Cloud',         'd1000001-0000-0000-0000-000000000001', false, true,  NULL),
  ('b3000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Zoom',                         'd1000012-0000-0000-0000-000000000012', false, true,  NULL),
  ('b3000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Okta',                         'acbb0246-d508-4369-9ca0-8c0d67cc5383', false, false, NULL),
  ('b3000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'ServiceNow',                   'd1000009-0000-0000-0000-000000000009', false, false, NULL),
  ('b3000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'VMware vSphere',               '13e90c9b-974a-4e9c-95a8-a7931a1cd922', false, false, NULL),
  ('b3000007-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Commvault',                    'a33078be-9e6a-4a6e-acc5-92156421a699', false, false, NULL),
  ('b3000008-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Tenable Nessus',               'd1000011-0000-0000-0000-000000000011', false, false, NULL),
  ('b3000009-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Esri ArcGIS Pro',              'd1000007-0000-0000-0000-000000000007', false, false, NULL),
  ('b300000a-0000-0000-0000-00000000000a', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Hexagon OnCall CAD/RMS',       'c9245885-829e-45a3-bffb-7b6df92c4b34', false, false, NULL),
  ('b300000b-0000-0000-0000-00000000000b', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Axon Evidence.com',            'c2d52176-4f4d-47e9-9a19-d6a045290632', false, false, NULL),
  ('b300000c-0000-0000-0000-00000000000c', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Microsoft Dynamics GP',         '7d738823-9033-45f6-b26b-0d435b86ac9a', false, false, NULL),
  ('b300000d-0000-0000-0000-00000000000d', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Tyler Brazos eCitation',       'c6456265-897b-4fe3-a1a1-5e6161668bc3', false, false, NULL),
  ('b300000e-0000-0000-0000-00000000000e', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Tyler CopLogic',               'c6456265-897b-4fe3-a1a1-5e6161668bc3', false, false, NULL),
  ('b300000f-0000-0000-0000-00000000000f', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'ManageEngine ServiceDesk Plus', 'd1000015-0000-0000-0000-000000000015', false, false, NULL),
  ('b3000010-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Flock Safety ALPR',            'ba76905c-4f52-45bc-8ab2-d3db7863e180', false, false, NULL)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2d: IT Services (12)
-- =============================================================================
-- All: namespace_id = COR, owner_workspace_id = IT, is_internal_only = false,
--      lifecycle_state = 'active'

INSERT INTO it_services (id, namespace_id, owner_workspace_id, name, service_type_id, annual_cost, cost_model, is_internal_only, lifecycle_state)
VALUES
  ('b4000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Windows Server Hosting',       '5aca4072-e946-4878-a7eb-a613fc5bafa1', 180000,  'per_instance', false, 'active'),
  ('b4000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Azure Cloud Hosting',          '5aca4072-e946-4878-a7eb-a613fc5bafa1', 500000,  'consumption',  false, 'active'),
  ('b4000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'SQL Server Database Services',  '967af450-cae2-42cb-9a01-c2389ea1a6b5', 120000,  'per_instance', false, 'active'),
  ('b4000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Oracle Database Services',      '967af450-cae2-42cb-9a01-c2389ea1a6b5', 95000,   'per_instance', false, 'active'),
  ('b4000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Enterprise Backup & Recovery',  '96a92a2e-e48f-4b8d-8bed-e4d598fd3552', 142000,  'fixed',        false, 'active'),
  ('b4000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Network Infrastructure',        'd63f9bca-7a19-446d-93df-aa59e9c4659d', 250000,  'fixed',        false, 'active'),
  ('b4000007-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Cybersecurity Operations',      '815e5b2a-ff3f-4e6e-85f8-9d4665264972', 200000,  'fixed',        false, 'active'),
  ('b4000008-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Identity & Access Management',  '6d4a7f95-64f1-4537-932e-8d8efde114cf', 327000,  'per_user',     false, 'active'),
  ('b4000009-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'ITSM Platform',                 '485e1e16-2916-4f35-a144-47a26922e976', 85000,   'fixed',        false, 'active'),
  ('b400000a-0000-0000-0000-00000000000a', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Microsoft 365 Enterprise',      'a5087a14-e3a3-4daa-ad2b-4b9d8c1da568', 1038000, 'per_user',     false, 'active'),
  ('b400000b-0000-0000-0000-00000000000b', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'GIS Platform',                  'a5087a14-e3a3-4daa-ad2b-4b9d8c1da568', 100000,  'per_instance', false, 'active'),
  ('b400000c-0000-0000-0000-00000000000c', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'a1b2c3d4-0001-0000-0000-000000000001', 'Collaboration & Conferencing',  'a5087a14-e3a3-4daa-ad2b-4b9d8c1da568', 24000,   'per_user',     false, 'active')
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2e: Applications (~30 apps)
-- =============================================================================
-- All apps: operational_status = 'operational', lifecycle_stage_status = 'active'

INSERT INTO applications (id, workspace_id, name, description, operational_status, lifecycle_stage_status)
VALUES
  -- Police Department (8)
  ('b1000001-0000-0000-0000-000000000001', 'a1b2c3d4-0006-0000-0000-000000000006', 'Hexagon OnCall CAD/RMS',    'Computer-aided dispatch and records management system for law enforcement', 'operational', 'active'),
  ('b1000002-0000-0000-0000-000000000002', 'a1b2c3d4-0006-0000-0000-000000000006', 'Axon Evidence',             'Digital evidence management and body-worn camera platform',                'operational', 'active'),
  ('b1000003-0000-0000-0000-000000000003', 'a1b2c3d4-0006-0000-0000-000000000006', 'Flock Safety LPR',          'Automated license plate recognition system for investigations',            'operational', 'active'),
  ('b1000004-0000-0000-0000-000000000004', 'a1b2c3d4-0006-0000-0000-000000000006', 'Brazos eCitation',          'Electronic citation issuance for field officers',                         'operational', 'active'),
  ('b1000005-0000-0000-0000-000000000005', 'a1b2c3d4-0006-0000-0000-000000000006', 'CopLogic Online Reporting', 'Citizen-facing online police report submission portal',                    'operational', 'active'),
  ('b1000006-0000-0000-0000-000000000006', 'a1b2c3d4-0006-0000-0000-000000000006', 'Computer-Aided Dispatch',   'Real-time dispatch and unit tracking for emergency response',             'operational', 'active'),
  ('b1000007-0000-0000-0000-000000000007', 'a1b2c3d4-0006-0000-0000-000000000006', 'NG911 System',              'Next-generation 911 call routing and management',                         'operational', 'active'),
  ('b1000008-0000-0000-0000-000000000008', 'a1b2c3d4-0006-0000-0000-000000000006', 'Police Records Management', 'Case management and police records repository',                           'operational', 'active'),

  -- Information Technology (6)
  ('b1000009-0000-0000-0000-000000000009', 'a1b2c3d4-0001-0000-0000-000000000001', 'ServiceDesk Plus',          'IT service management and helpdesk ticketing system',                     'operational', 'active'),
  ('b100000a-0000-0000-0000-00000000000a', 'a1b2c3d4-0001-0000-0000-000000000001', 'Active Directory Services', 'Enterprise identity and directory services',                              'operational', 'active'),
  ('b100000b-0000-0000-0000-00000000000b', 'a1b2c3d4-0001-0000-0000-000000000001', 'Esri ArcGIS Enterprise',    'Enterprise geographic information system platform',                       'operational', 'active'),
  ('b100000c-0000-0000-0000-00000000000c', 'a1b2c3d4-0001-0000-0000-000000000001', 'PRTG Network Monitor',      'Network infrastructure monitoring and alerting',                          'operational', 'active'),
  ('b100000d-0000-0000-0000-00000000000d', 'a1b2c3d4-0001-0000-0000-000000000001', 'Microsoft 365',             'Enterprise productivity and collaboration suite',                         'operational', 'active'),
  ('b100000e-0000-0000-0000-00000000000e', 'a1b2c3d4-0001-0000-0000-000000000001', 'Hyland OnBase',             'Enterprise content management and document workflow',                     'operational', 'active'),

  -- Finance (4)
  ('b100000f-0000-0000-0000-00000000000f', 'a1b2c3d4-0003-0000-0000-000000000003', 'Microsoft Dynamics GP',     'General ledger and financial management ERP',                             'operational', 'active'),
  ('b1000010-0000-0000-0000-000000000010', 'a1b2c3d4-0003-0000-0000-000000000003', 'Cayenta Financials',        'Municipal utility billing and financial management',                      'operational', 'active'),
  ('b1000011-0000-0000-0000-000000000011', 'a1b2c3d4-0003-0000-0000-000000000003', 'Questica Budget',           'Budget preparation and management platform',                              'operational', 'active'),
  ('b1000012-0000-0000-0000-000000000012', 'a1b2c3d4-0003-0000-0000-000000000003', 'Sage 300 GL',               'General ledger and financial reporting',                                   'operational', 'active'),

  -- Fire Department (3)
  ('b1000013-0000-0000-0000-000000000013', 'a1b2c3d4-0007-0000-0000-000000000007', 'Emergency Response System', 'Fire and EMS emergency response coordination platform',                   'operational', 'active'),
  ('b1000014-0000-0000-0000-000000000014', 'a1b2c3d4-0007-0000-0000-000000000007', 'Fire Records Management',   'Fire incident reporting and records system',                              'operational', 'active'),
  ('b1000015-0000-0000-0000-000000000015', 'a1b2c3d4-0007-0000-0000-000000000007', 'ImageTrend Elite',          'Fire and EMS data collection, reporting, and analytics',                  'operational', 'active'),

  -- Human Resources (3)
  ('b1000016-0000-0000-0000-000000000016', 'a1b2c3d4-0002-0000-0000-000000000002', 'Workday HCM',              'Human capital management and payroll',                                    'operational', 'active'),
  ('b1000017-0000-0000-0000-000000000017', 'a1b2c3d4-0002-0000-0000-000000000002', 'NEOGOV',                    'Government recruiting and onboarding platform',                           'operational', 'active'),
  ('b1000018-0000-0000-0000-000000000018', 'a1b2c3d4-0002-0000-0000-000000000002', 'Kronos Workforce Central',  'Time and attendance tracking',                                            'operational', 'active'),

  -- Other workspaces (6)
  ('b1000019-0000-0000-0000-000000000019', 'a1b2c3d4-0011-0000-0000-000000000011', 'Accela Civic Platform',     'Permitting, licensing, and code enforcement',                             'operational', 'active'),
  ('b100001a-0000-0000-0000-00000000001a', 'a1b2c3d4-0013-0000-0000-000000000013', 'CivicPlus Website',         'Municipal website content management system',                             'operational', 'active'),
  ('b100001b-0000-0000-0000-00000000001b', 'a1b2c3d4-0012-0000-0000-000000000012', 'Samsara Fleet',             'Fleet management and GPS vehicle tracking',                               'operational', 'active'),
  ('b100001c-0000-0000-0000-00000000001c', 'a1b2c3d4-0013-0000-0000-000000000013', 'SeeClickFix',              'Citizen request and issue reporting platform',                            'operational', 'active'),
  ('b100001d-0000-0000-0000-00000000001d', 'a1b2c3d4-0009-0000-0000-000000000009', 'Sensus FlexNet',            'Water utility AMI and smart metering platform',                           'operational', 'active'),
  ('b100001e-0000-0000-0000-00000000001e', 'a1b2c3d4-0008-0000-0000-000000000008', 'Tyler Incode Court',        'Court case management and adjudication system',                           'operational', 'active')
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2f: Application Deployment Profiles (one PROD DP per app)
-- =============================================================================
-- UUID scheme: b5000001 through b500001e (matching app UUIDs)

INSERT INTO deployment_profiles (id, application_id, workspace_id, name, environment, dp_type, is_primary, hosting_type, cloud_provider, data_center_id, server_name)
VALUES
  -- Police Department — On-Prem
  ('b5000001-0000-0000-0000-000000000001', 'b1000001-0000-0000-0000-000000000001', 'a1b2c3d4-0006-0000-0000-000000000006', 'Hexagon OnCall CAD/RMS - PROD - CHDC',    'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', 'HEX-PROD-01'),
  -- Police — SaaS
  ('b5000002-0000-0000-0000-000000000002', 'b1000002-0000-0000-0000-000000000002', 'a1b2c3d4-0006-0000-0000-000000000006', 'Axon Evidence - PROD - SaaS',             'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b5000003-0000-0000-0000-000000000003', 'b1000003-0000-0000-0000-000000000003', 'a1b2c3d4-0006-0000-0000-000000000006', 'Flock Safety LPR - PROD - SaaS',          'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b5000004-0000-0000-0000-000000000004', 'b1000004-0000-0000-0000-000000000004', 'a1b2c3d4-0006-0000-0000-000000000006', 'Brazos eCitation - PROD - SaaS',          'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b5000005-0000-0000-0000-000000000005', 'b1000005-0000-0000-0000-000000000005', 'a1b2c3d4-0006-0000-0000-000000000006', 'CopLogic Online Reporting - PROD - SaaS', 'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  -- Police — On-Prem
  ('b5000006-0000-0000-0000-000000000006', 'b1000006-0000-0000-0000-000000000006', 'a1b2c3d4-0006-0000-0000-000000000006', 'Computer-Aided Dispatch - PROD - CHDC',   'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', 'CAD-PROD-01'),
  -- Police — Cloud
  ('b5000007-0000-0000-0000-000000000007', 'b1000007-0000-0000-0000-000000000007', 'a1b2c3d4-0006-0000-0000-000000000006', 'NG911 System - PROD - Azure',             'PROD', 'application', true, 'Cloud',   'azure', NULL, NULL),
  -- Police — On-Prem
  ('b5000008-0000-0000-0000-000000000008', 'b1000008-0000-0000-0000-000000000008', 'a1b2c3d4-0006-0000-0000-000000000006', 'Police Records Management - PROD - CHDC', 'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),

  -- IT — On-Prem
  ('b5000009-0000-0000-0000-000000000009', 'b1000009-0000-0000-0000-000000000009', 'a1b2c3d4-0001-0000-0000-000000000001', 'ServiceDesk Plus - PROD - CHDC',          'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  ('b500000a-0000-0000-0000-00000000000a', 'b100000a-0000-0000-0000-00000000000a', 'a1b2c3d4-0001-0000-0000-000000000001', 'Active Directory Services - PROD - CHDC', 'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- IT — Hybrid
  ('b500000b-0000-0000-0000-00000000000b', 'b100000b-0000-0000-0000-00000000000b', 'a1b2c3d4-0001-0000-0000-000000000001', 'Esri ArcGIS Enterprise - PROD - Hybrid',  'PROD', 'application', true, 'Hybrid',  'azure', 'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- IT — On-Prem
  ('b500000c-0000-0000-0000-00000000000c', 'b100000c-0000-0000-0000-00000000000c', 'a1b2c3d4-0001-0000-0000-000000000001', 'PRTG Network Monitor - PROD - CHDC',      'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- IT — SaaS
  ('b500000d-0000-0000-0000-00000000000d', 'b100000d-0000-0000-0000-00000000000d', 'a1b2c3d4-0001-0000-0000-000000000001', 'Microsoft 365 - PROD - SaaS',             'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  -- IT — On-Prem
  ('b500000e-0000-0000-0000-00000000000e', 'b100000e-0000-0000-0000-00000000000e', 'a1b2c3d4-0001-0000-0000-000000000001', 'Hyland OnBase - PROD - CHDC',             'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),

  -- Finance — On-Prem
  ('b500000f-0000-0000-0000-00000000000f', 'b100000f-0000-0000-0000-00000000000f', 'a1b2c3d4-0003-0000-0000-000000000003', 'Microsoft Dynamics GP - PROD - CHDC',     'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  ('b5000010-0000-0000-0000-000000000010', 'b1000010-0000-0000-0000-000000000010', 'a1b2c3d4-0003-0000-0000-000000000003', 'Cayenta Financials - PROD - CHDC',        'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- Finance — SaaS
  ('b5000011-0000-0000-0000-000000000011', 'b1000011-0000-0000-0000-000000000011', 'a1b2c3d4-0003-0000-0000-000000000003', 'Questica Budget - PROD - SaaS',           'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  -- Finance — On-Prem
  ('b5000012-0000-0000-0000-000000000012', 'b1000012-0000-0000-0000-000000000012', 'a1b2c3d4-0003-0000-0000-000000000003', 'Sage 300 GL - PROD - CHDC',               'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),

  -- Fire — Hybrid
  ('b5000013-0000-0000-0000-000000000013', 'b1000013-0000-0000-0000-000000000013', 'a1b2c3d4-0007-0000-0000-000000000007', 'Emergency Response System - PROD - Hybrid','PROD', 'application', true, 'Hybrid',  'azure', 'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- Fire — On-Prem
  ('b5000014-0000-0000-0000-000000000014', 'b1000014-0000-0000-0000-000000000014', 'a1b2c3d4-0007-0000-0000-000000000007', 'Fire Records Management - PROD - CHDC',   'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),
  -- Fire — SaaS
  ('b5000015-0000-0000-0000-000000000015', 'b1000015-0000-0000-0000-000000000015', 'a1b2c3d4-0007-0000-0000-000000000007', 'ImageTrend Elite - PROD - SaaS',          'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),

  -- HR — SaaS
  ('b5000016-0000-0000-0000-000000000016', 'b1000016-0000-0000-0000-000000000016', 'a1b2c3d4-0002-0000-0000-000000000002', 'Workday HCM - PROD - SaaS',              'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  -- HR — SaaS
  ('b5000017-0000-0000-0000-000000000017', 'b1000017-0000-0000-0000-000000000017', 'a1b2c3d4-0002-0000-0000-000000000002', 'NEOGOV - PROD - SaaS',                    'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  -- HR — On-Prem
  ('b5000018-0000-0000-0000-000000000018', 'b1000018-0000-0000-0000-000000000018', 'a1b2c3d4-0002-0000-0000-000000000002', 'Kronos Workforce Central - PROD - CHDC',  'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL),

  -- Other workspaces — SaaS
  ('b5000019-0000-0000-0000-000000000019', 'b1000019-0000-0000-0000-000000000019', 'a1b2c3d4-0011-0000-0000-000000000011', 'Accela Civic Platform - PROD - SaaS',     'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b500001a-0000-0000-0000-00000000001a', 'b100001a-0000-0000-0000-00000000001a', 'a1b2c3d4-0013-0000-0000-000000000013', 'CivicPlus Website - PROD - SaaS',         'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b500001b-0000-0000-0000-00000000001b', 'b100001b-0000-0000-0000-00000000001b', 'a1b2c3d4-0012-0000-0000-000000000012', 'Samsara Fleet - PROD - SaaS',             'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b500001c-0000-0000-0000-00000000001c', 'b100001c-0000-0000-0000-00000000001c', 'a1b2c3d4-0013-0000-0000-000000000013', 'SeeClickFix - PROD - SaaS',               'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b500001d-0000-0000-0000-00000000001d', 'b100001d-0000-0000-0000-00000000001d', 'a1b2c3d4-0009-0000-0000-000000000009', 'Sensus FlexNet - PROD - SaaS',            'PROD', 'application', true, 'SaaS',    NULL,    NULL, NULL),
  ('b500001e-0000-0000-0000-00000000001e', 'b100001e-0000-0000-0000-00000000001e', 'a1b2c3d4-0008-0000-0000-000000000008', 'Tyler Incode Court - PROD - CHDC',        'PROD', 'application', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72', NULL)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2g: Infrastructure Deployment Profiles (7)
-- =============================================================================
-- All: workspace_id = IT, dp_type = 'infrastructure', application_id = NULL, is_primary = true

INSERT INTO deployment_profiles (id, application_id, workspace_id, name, environment, dp_type, is_primary, hosting_type, cloud_provider, data_center_id)
VALUES
  ('b6000001-0000-0000-0000-000000000001', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Windows Server Farm — City Hall',    'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  ('b6000002-0000-0000-0000-000000000002', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'SQL Server Cluster — City Hall',     'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  ('b6000003-0000-0000-0000-000000000003', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Oracle RAC — City Hall',             'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  ('b6000004-0000-0000-0000-000000000004', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Azure Subscription — COR',           'PROD', 'infrastructure', true, 'Cloud',   'azure', NULL),
  ('b6000005-0000-0000-0000-000000000005', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Backup Infrastructure — City Hall',  'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  ('b6000006-0000-0000-0000-000000000006', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Core Network — City Hall',           'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  ('b6000007-0000-0000-0000-000000000007', NULL, 'a1b2c3d4-0001-0000-0000-000000000001', 'Security Appliances — City Hall',    'PROD', 'infrastructure', true, 'On-Prem', NULL,    'fb337a78-b1ec-4227-9404-56a52ce3ff72')
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2h: Cost Bundle Deployment Profiles (5 — Path A apps)
-- =============================================================================

INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, environment, is_primary, annual_cost, vendor_org_id, contract_reference, contract_start_date, contract_end_date, renewal_notice_days)
VALUES
  ('b7000001-0000-0000-0000-000000000001', 'b1000002-0000-0000-0000-000000000002', 'a1b2c3d4-0006-0000-0000-000000000006', 'Axon Evidence SaaS License',   'cost_bundle', 'PROD', true, 120000, 'c2d52176-4f4d-47e9-9a19-d6a045290632', 'AXN-2025-003', '2027-01-15', '2028-01-15', 90),
  ('b7000002-0000-0000-0000-000000000002', 'b1000003-0000-0000-0000-000000000003', 'a1b2c3d4-0006-0000-0000-000000000006', 'Flock Safety Annual License',  'cost_bundle', 'PROD', true,  48000, 'ba76905c-4f52-45bc-8ab2-d3db7863e180', 'FS-2024-112',  '2026-03-31', '2027-03-31', 90),
  ('b7000003-0000-0000-0000-000000000003', 'b1000004-0000-0000-0000-000000000004', 'a1b2c3d4-0006-0000-0000-000000000006', 'Tyler Brazos SaaS',            'cost_bundle', 'PROD', true,  18000, 'c6456265-897b-4fe3-a1a1-5e6161668bc3', 'TYL-2024-007', '2025-09-30', '2026-09-30', 90),
  ('b7000004-0000-0000-0000-000000000004', 'b1000015-0000-0000-0000-000000000015', 'a1b2c3d4-0007-0000-0000-000000000007', 'ImageTrend Annual SaaS',       'cost_bundle', 'PROD', true,  35000, 'd1000017-0000-0000-0000-000000000017', 'IMG-2025-001', '2026-12-31', '2027-12-31', 90),
  ('b7000005-0000-0000-0000-000000000005', 'b1000016-0000-0000-0000-000000000016', 'a1b2c3d4-0002-0000-0000-000000000002', 'Workday Enterprise License',   'cost_bundle', 'PROD', true,  95000, 'd1000018-0000-0000-0000-000000000018', 'WD-2024-456',  '2026-06-30', '2027-06-30', 90)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2i: IT Service Providers (link infra DPs to IT services)
-- =============================================================================
-- Unique constraint: (it_service_id, deployment_profile_id)

INSERT INTO it_service_providers (it_service_id, deployment_profile_id, is_primary, namespace_id)
VALUES
  ('b4000001-0000-0000-0000-000000000001', 'b6000001-0000-0000-0000-000000000001', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- Windows Server Hosting ← Windows Server Farm
  ('b4000003-0000-0000-0000-000000000003', 'b6000002-0000-0000-0000-000000000002', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- SQL Server DB ← SQL Server Cluster
  ('b4000004-0000-0000-0000-000000000004', 'b6000003-0000-0000-0000-000000000003', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- Oracle DB ← Oracle RAC
  ('b4000002-0000-0000-0000-000000000002', 'b6000004-0000-0000-0000-000000000004', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- Azure Cloud ← Azure Subscription
  ('b4000005-0000-0000-0000-000000000005', 'b6000005-0000-0000-0000-000000000005', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- Backup ← Backup Infra
  ('b4000006-0000-0000-0000-000000000006', 'b6000006-0000-0000-0000-000000000006', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),  -- Network ← Core Network
  ('b4000007-0000-0000-0000-000000000007', 'b6000007-0000-0000-0000-000000000007', true, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')   -- Cybersecurity ← Security Appliances
ON CONFLICT (it_service_id, deployment_profile_id) DO NOTHING;


-- =============================================================================
-- Phase 2j: IT Service → Technology Products
-- =============================================================================
-- Unique constraint: (it_service_id, technology_product_id)

INSERT INTO it_service_technology_products (it_service_id, technology_product_id)
VALUES
  -- Windows Server Hosting
  ('b4000001-0000-0000-0000-000000000001', 'b2000001-0000-0000-0000-000000000001'),  -- Win Server 2019
  ('b4000001-0000-0000-0000-000000000001', 'b2000002-0000-0000-0000-000000000002'),  -- Win Server 2022
  -- Azure Cloud Hosting
  ('b4000002-0000-0000-0000-000000000002', 'b2000009-0000-0000-0000-000000000009'),  -- Azure
  -- SQL Server DB
  ('b4000003-0000-0000-0000-000000000003', 'b2000004-0000-0000-0000-000000000004'),  -- SQL Server 2019
  ('b4000003-0000-0000-0000-000000000003', 'b2000005-0000-0000-0000-000000000005'),  -- SQL Server 2022
  ('b4000003-0000-0000-0000-000000000003', 'b2000002-0000-0000-0000-000000000002'),  -- Win Server 2022
  -- Oracle DB
  ('b4000004-0000-0000-0000-000000000004', 'b2000006-0000-0000-0000-000000000006'),  -- Oracle 19c
  ('b4000004-0000-0000-0000-000000000004', 'b2000003-0000-0000-0000-000000000003'),  -- RHEL 8
  -- Backup
  ('b4000005-0000-0000-0000-000000000005', 'b2000002-0000-0000-0000-000000000002'),  -- Win Server 2022
  -- Cybersecurity
  ('b4000007-0000-0000-0000-000000000007', 'b2000003-0000-0000-0000-000000000003'),  -- RHEL 8
  -- M365 Enterprise
  ('b400000a-0000-0000-0000-00000000000a', 'b200000c-0000-0000-0000-00000000000c')   -- SharePoint Online
ON CONFLICT (it_service_id, technology_product_id) DO NOTHING;


-- =============================================================================
-- Phase 2k: IT Service → Software Products
-- =============================================================================
-- Unique constraint: (it_service_id, software_product_id)

INSERT INTO it_service_software_products (it_service_id, software_product_id)
VALUES
  ('b4000001-0000-0000-0000-000000000001', 'b3000006-0000-0000-0000-000000000006'),  -- Windows Server Hosting ← VMware vSphere
  ('b4000005-0000-0000-0000-000000000005', 'b3000007-0000-0000-0000-000000000007'),  -- Backup ← Commvault
  ('b4000007-0000-0000-0000-000000000007', 'b3000008-0000-0000-0000-000000000008'),  -- Cybersecurity ← Tenable Nessus
  ('b4000008-0000-0000-0000-000000000008', 'b3000004-0000-0000-0000-000000000004'),  -- Identity & Access ← Okta
  ('b4000009-0000-0000-0000-000000000009', 'b3000005-0000-0000-0000-000000000005'),  -- ITSM Platform ← ServiceNow
  ('b400000a-0000-0000-0000-00000000000a', 'b3000001-0000-0000-0000-000000000001'),  -- M365 Enterprise ← Microsoft 365
  ('b400000b-0000-0000-0000-00000000000b', 'b3000009-0000-0000-0000-000000000009'),  -- GIS Platform ← Esri ArcGIS Pro
  ('b400000c-0000-0000-0000-00000000000c', 'b3000003-0000-0000-0000-000000000003')   -- Collaboration ← Zoom
ON CONFLICT (it_service_id, software_product_id) DO NOTHING;


-- =============================================================================
-- Phase 2l: DP → Technology Products (on-prem app DPs only)
-- =============================================================================
-- Unique constraint: (deployment_profile_id, technology_product_id)
-- SaaS apps get NO tech products — they don't run on our infrastructure

INSERT INTO deployment_profile_technology_products (deployment_profile_id, technology_product_id)
VALUES
  -- Hexagon OnCall CAD/RMS: Win Server 2019, SQL Server 2019, IIS 10
  ('b5000001-0000-0000-0000-000000000001', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000001-0000-0000-0000-000000000001', 'b2000004-0000-0000-0000-000000000004'),
  ('b5000001-0000-0000-0000-000000000001', 'b200000a-0000-0000-0000-00000000000a'),
  -- CAD: Win Server 2022, SQL Server 2022
  ('b5000006-0000-0000-0000-000000000006', 'b2000002-0000-0000-0000-000000000002'),
  ('b5000006-0000-0000-0000-000000000006', 'b2000005-0000-0000-0000-000000000005'),
  -- Police Records: Win Server 2019, SQL Server 2019
  ('b5000008-0000-0000-0000-000000000008', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000008-0000-0000-0000-000000000008', 'b2000004-0000-0000-0000-000000000004'),
  -- NG911: Win Server 2022
  ('b5000007-0000-0000-0000-000000000007', 'b2000002-0000-0000-0000-000000000002'),
  -- ServiceDesk Plus: Win Server 2022, MySQL 8.0, Apache Tomcat 9.0
  ('b5000009-0000-0000-0000-000000000009', 'b2000002-0000-0000-0000-000000000002'),
  ('b5000009-0000-0000-0000-000000000009', 'b2000008-0000-0000-0000-000000000008'),
  ('b5000009-0000-0000-0000-000000000009', 'b200000b-0000-0000-0000-00000000000b'),
  -- Active Directory: Win Server 2022
  ('b500000a-0000-0000-0000-00000000000a', 'b2000002-0000-0000-0000-000000000002'),
  -- ArcGIS Enterprise: Win Server 2022, SQL Server 2022, IIS 10
  ('b500000b-0000-0000-0000-00000000000b', 'b2000002-0000-0000-0000-000000000002'),
  ('b500000b-0000-0000-0000-00000000000b', 'b2000005-0000-0000-0000-000000000005'),
  ('b500000b-0000-0000-0000-00000000000b', 'b200000a-0000-0000-0000-00000000000a'),
  -- PRTG: Win Server 2022
  ('b500000c-0000-0000-0000-00000000000c', 'b2000002-0000-0000-0000-000000000002'),
  -- OnBase: Win Server 2019, SQL Server 2019, IIS 10
  ('b500000e-0000-0000-0000-00000000000e', 'b2000001-0000-0000-0000-000000000001'),
  ('b500000e-0000-0000-0000-00000000000e', 'b2000004-0000-0000-0000-000000000004'),
  ('b500000e-0000-0000-0000-00000000000e', 'b200000a-0000-0000-0000-00000000000a'),
  -- Dynamics GP: Win Server 2019, SQL Server 2019
  ('b500000f-0000-0000-0000-00000000000f', 'b2000001-0000-0000-0000-000000000001'),
  ('b500000f-0000-0000-0000-00000000000f', 'b2000004-0000-0000-0000-000000000004'),
  -- Cayenta: Win Server 2019, Oracle Database 19c
  ('b5000010-0000-0000-0000-000000000010', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000010-0000-0000-0000-000000000010', 'b2000006-0000-0000-0000-000000000006'),
  -- Sage 300: Win Server 2019, SQL Server 2019
  ('b5000012-0000-0000-0000-000000000012', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000012-0000-0000-0000-000000000012', 'b2000004-0000-0000-0000-000000000004'),
  -- Emergency Response: Win Server 2022
  ('b5000013-0000-0000-0000-000000000013', 'b2000002-0000-0000-0000-000000000002'),
  -- Fire Records: Win Server 2019, SQL Server 2019
  ('b5000014-0000-0000-0000-000000000014', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000014-0000-0000-0000-000000000014', 'b2000004-0000-0000-0000-000000000004'),
  -- Kronos: Win Server 2019, SQL Server 2019
  ('b5000018-0000-0000-0000-000000000018', 'b2000001-0000-0000-0000-000000000001'),
  ('b5000018-0000-0000-0000-000000000018', 'b2000004-0000-0000-0000-000000000004'),
  -- Tyler Incode Court: Win Server 2019, SQL Server 2019 (on-prem)
  ('b500001e-0000-0000-0000-00000000001e', 'b2000001-0000-0000-0000-000000000001'),
  ('b500001e-0000-0000-0000-00000000001e', 'b2000004-0000-0000-0000-000000000004')
ON CONFLICT (deployment_profile_id, technology_product_id) DO NOTHING;


-- =============================================================================
-- Phase 2m: DP → Software Products (app-specific inventory only)
-- =============================================================================
-- Unique constraint: (deployment_profile_id, software_product_id)
-- All: deployed_version = NULL, annual_cost = NULL (inventory only, no cost allocation)

INSERT INTO deployment_profile_software_products (deployment_profile_id, software_product_id)
VALUES
  ('b5000001-0000-0000-0000-000000000001', 'b300000a-0000-0000-0000-00000000000a'),  -- Hexagon DP ← Hexagon OnCall CAD/RMS
  ('b5000002-0000-0000-0000-000000000002', 'b300000b-0000-0000-0000-00000000000b'),  -- Axon DP ← Axon Evidence.com
  ('b5000003-0000-0000-0000-000000000003', 'b3000010-0000-0000-0000-000000000010'),  -- Flock Safety DP ← Flock Safety ALPR
  ('b5000004-0000-0000-0000-000000000004', 'b300000d-0000-0000-0000-00000000000d'),  -- Brazos DP ← Tyler Brazos eCitation
  ('b5000005-0000-0000-0000-000000000005', 'b300000e-0000-0000-0000-00000000000e'),  -- CopLogic DP ← Tyler CopLogic
  ('b5000009-0000-0000-0000-000000000009', 'b300000f-0000-0000-0000-00000000000f'),  -- ServiceDesk Plus DP ← ManageEngine ServiceDesk Plus
  ('b500000b-0000-0000-0000-00000000000b', 'b3000009-0000-0000-0000-000000000009'),  -- ArcGIS DP ← Esri ArcGIS Pro
  ('b500000d-0000-0000-0000-00000000000d', 'b3000001-0000-0000-0000-000000000001'),  -- M365 DP ← Microsoft 365
  ('b500000f-0000-0000-0000-00000000000f', 'b300000c-0000-0000-0000-00000000000c')   -- Dynamics GP DP ← Microsoft Dynamics GP
ON CONFLICT (deployment_profile_id, software_product_id) DO NOTHING;


-- =============================================================================
-- Phase 2n: DP → IT Services (all apps — dependency tracking)
-- =============================================================================
-- Unique constraint: (deployment_profile_id, it_service_id)
-- Path A apps: allocation_value = NULL (cost comes from Cost Bundle, not IT Service)
-- Path B apps: allocation_value = NULL for now (can be set later for cost allocation)
-- All: relationship_type = 'depends_on'

INSERT INTO deployment_profile_it_services (deployment_profile_id, it_service_id, relationship_type, allocation_value)
VALUES
  -- -----------------------------------------------------------------------
  -- Police Department
  -- -----------------------------------------------------------------------
  -- Hexagon (on-prem, Path B)
  ('b5000001-0000-0000-0000-000000000001', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000001-0000-0000-0000-000000000001', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b5000001-0000-0000-0000-000000000001', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup
  ('b5000001-0000-0000-0000-000000000001', 'b4000007-0000-0000-0000-000000000007', 'depends_on', NULL),  -- Cybersecurity
  ('b5000001-0000-0000-0000-000000000001', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network
  ('b5000001-0000-0000-0000-000000000001', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Axon (SaaS, Path A — has Cost Bundle)
  ('b5000002-0000-0000-0000-000000000002', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000002-0000-0000-0000-000000000002', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access
  ('b5000002-0000-0000-0000-000000000002', 'b4000009-0000-0000-0000-000000000009', 'depends_on', NULL),  -- ITSM Platform

  -- Flock Safety (SaaS, Path A)
  ('b5000003-0000-0000-0000-000000000003', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000003-0000-0000-0000-000000000003', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Brazos (SaaS, Path A)
  ('b5000004-0000-0000-0000-000000000004', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- CopLogic (SaaS, Path B — no Cost Bundle)
  ('b5000005-0000-0000-0000-000000000005', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- CAD (on-prem, Path B)
  ('b5000006-0000-0000-0000-000000000006', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000006-0000-0000-0000-000000000006', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b5000006-0000-0000-0000-000000000006', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network
  ('b5000006-0000-0000-0000-000000000006', 'b4000007-0000-0000-0000-000000000007', 'depends_on', NULL),  -- Cybersecurity

  -- NG911 (Cloud, Path B)
  ('b5000007-0000-0000-0000-000000000007', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000007-0000-0000-0000-000000000007', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network
  ('b5000007-0000-0000-0000-000000000007', 'b4000007-0000-0000-0000-000000000007', 'depends_on', NULL),  -- Cybersecurity

  -- Police Records (on-prem, Path B)
  ('b5000008-0000-0000-0000-000000000008', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000008-0000-0000-0000-000000000008', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b5000008-0000-0000-0000-000000000008', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup

  -- -----------------------------------------------------------------------
  -- Information Technology
  -- -----------------------------------------------------------------------
  -- ServiceDesk Plus (on-prem)
  ('b5000009-0000-0000-0000-000000000009', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000009-0000-0000-0000-000000000009', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network
  ('b5000009-0000-0000-0000-000000000009', 'b4000007-0000-0000-0000-000000000007', 'depends_on', NULL),  -- Cybersecurity

  -- Active Directory (on-prem)
  ('b500000a-0000-0000-0000-00000000000a', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500000a-0000-0000-0000-00000000000a', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network

  -- ArcGIS Enterprise (hybrid)
  ('b500000b-0000-0000-0000-00000000000b', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500000b-0000-0000-0000-00000000000b', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b500000b-0000-0000-0000-00000000000b', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b500000b-0000-0000-0000-00000000000b', 'b400000b-0000-0000-0000-00000000000b', 'depends_on', NULL),  -- GIS Platform

  -- PRTG (on-prem)
  ('b500000c-0000-0000-0000-00000000000c', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500000c-0000-0000-0000-00000000000c', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network

  -- Microsoft 365 (SaaS)
  ('b500000d-0000-0000-0000-00000000000d', 'b400000a-0000-0000-0000-00000000000a', 'depends_on', NULL),  -- M365 Enterprise

  -- OnBase (on-prem)
  ('b500000e-0000-0000-0000-00000000000e', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500000e-0000-0000-0000-00000000000e', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b500000e-0000-0000-0000-00000000000e', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup

  -- -----------------------------------------------------------------------
  -- Finance
  -- -----------------------------------------------------------------------
  -- Dynamics GP (on-prem)
  ('b500000f-0000-0000-0000-00000000000f', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500000f-0000-0000-0000-00000000000f', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b500000f-0000-0000-0000-00000000000f', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup
  ('b500000f-0000-0000-0000-00000000000f', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Cayenta (on-prem)
  ('b5000010-0000-0000-0000-000000000010', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000010-0000-0000-0000-000000000010', 'b4000004-0000-0000-0000-000000000004', 'depends_on', NULL),  -- Oracle DB
  ('b5000010-0000-0000-0000-000000000010', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup

  -- Questica (SaaS)
  ('b5000011-0000-0000-0000-000000000011', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000011-0000-0000-0000-000000000011', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Sage 300 (on-prem)
  ('b5000012-0000-0000-0000-000000000012', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000012-0000-0000-0000-000000000012', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB

  -- -----------------------------------------------------------------------
  -- Fire Department
  -- -----------------------------------------------------------------------
  -- Emergency Response (hybrid)
  ('b5000013-0000-0000-0000-000000000013', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000013-0000-0000-0000-000000000013', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000013-0000-0000-0000-000000000013', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network
  ('b5000013-0000-0000-0000-000000000013', 'b4000007-0000-0000-0000-000000000007', 'depends_on', NULL),  -- Cybersecurity

  -- Fire Records (on-prem)
  ('b5000014-0000-0000-0000-000000000014', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000014-0000-0000-0000-000000000014', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b5000014-0000-0000-0000-000000000014', 'b4000005-0000-0000-0000-000000000005', 'depends_on', NULL),  -- Backup

  -- ImageTrend (SaaS, Path A)
  ('b5000015-0000-0000-0000-000000000015', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000015-0000-0000-0000-000000000015', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- -----------------------------------------------------------------------
  -- Human Resources
  -- -----------------------------------------------------------------------
  -- Workday (SaaS, Path A)
  ('b5000016-0000-0000-0000-000000000016', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000016-0000-0000-0000-000000000016', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access
  ('b5000016-0000-0000-0000-000000000016', 'b4000009-0000-0000-0000-000000000009', 'depends_on', NULL),  -- ITSM Platform

  -- NEOGOV (SaaS)
  ('b5000017-0000-0000-0000-000000000017', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Kronos (on-prem)
  ('b5000018-0000-0000-0000-000000000018', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b5000018-0000-0000-0000-000000000018', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL),  -- SQL Server DB
  ('b5000018-0000-0000-0000-000000000018', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- -----------------------------------------------------------------------
  -- Other Workspaces
  -- -----------------------------------------------------------------------
  -- Accela (SaaS)
  ('b5000019-0000-0000-0000-000000000019', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b5000019-0000-0000-0000-000000000019', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- CivicPlus (SaaS)
  ('b500001a-0000-0000-0000-00000000001a', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud

  -- Samsara (SaaS)
  ('b500001b-0000-0000-0000-00000000001b', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b500001b-0000-0000-0000-00000000001b', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- SeeClickFix (SaaS)
  ('b500001c-0000-0000-0000-00000000001c', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b500001c-0000-0000-0000-00000000001c', 'b4000008-0000-0000-0000-000000000008', 'depends_on', NULL),  -- Identity & Access

  -- Sensus (SaaS)
  ('b500001d-0000-0000-0000-00000000001d', 'b4000002-0000-0000-0000-000000000002', 'depends_on', NULL),  -- Azure Cloud
  ('b500001d-0000-0000-0000-00000000001d', 'b4000006-0000-0000-0000-000000000006', 'depends_on', NULL),  -- Network

  -- Tyler Incode Court (on-prem)
  ('b500001e-0000-0000-0000-00000000001e', 'b4000001-0000-0000-0000-000000000001', 'depends_on', NULL),  -- Windows Server Hosting
  ('b500001e-0000-0000-0000-00000000001e', 'b4000003-0000-0000-0000-000000000003', 'depends_on', NULL)   -- SQL Server DB
ON CONFLICT (deployment_profile_id, it_service_id) DO NOTHING;


-- =============================================================================
-- Phase 2o: Application Integrations (8 key connections)
-- =============================================================================

INSERT INTO application_integrations (id, source_application_id, target_application_id, source_deployment_profile_id, target_deployment_profile_id, name, direction, integration_type, frequency, data_classification, status, criticality)
VALUES
  ('c1000001-0000-0000-0000-000000000001',
   'b1000001-0000-0000-0000-000000000001', 'b1000006-0000-0000-0000-000000000006',
   'b5000001-0000-0000-0000-000000000001', 'b5000006-0000-0000-0000-000000000006',
   'Hexagon ↔ CAD Dispatch', 'bidirectional', 'api', 'real_time', 'internal', 'active', 'critical'),

  ('c1000002-0000-0000-0000-000000000002',
   'b1000001-0000-0000-0000-000000000001', 'b1000002-0000-0000-0000-000000000002',
   'b5000001-0000-0000-0000-000000000001', 'b5000002-0000-0000-0000-000000000002',
   'Hexagon → Axon Evidence', 'downstream', 'api', 'real_time', 'internal', 'active', 'important'),

  ('c1000003-0000-0000-0000-000000000003',
   'b1000001-0000-0000-0000-000000000001', 'b1000003-0000-0000-0000-000000000003',
   'b5000001-0000-0000-0000-000000000001', 'b5000003-0000-0000-0000-000000000003',
   'Flock ALPR → Hexagon RMS', 'upstream', 'api', 'real_time', 'internal', 'active', 'important'),

  ('c1000004-0000-0000-0000-000000000004',
   'b100000f-0000-0000-0000-00000000000f', 'b1000010-0000-0000-0000-000000000010',
   'b500000f-0000-0000-0000-00000000000f', 'b5000010-0000-0000-0000-000000000010',
   'Dynamics GP ↔ Cayenta GL Sync', 'bidirectional', 'database', 'batch_daily', 'internal', 'active', 'critical'),

  ('c1000005-0000-0000-0000-000000000005',
   'b1000009-0000-0000-0000-000000000009', 'b100000a-0000-0000-0000-00000000000a',
   'b5000009-0000-0000-0000-000000000009', 'b500000a-0000-0000-0000-00000000000a',
   'ServiceDesk ← Active Directory SSO', 'upstream', 'sso', 'real_time', 'internal', 'active', 'critical'),

  ('c1000006-0000-0000-0000-000000000006',
   'b1000013-0000-0000-0000-000000000013', 'b1000006-0000-0000-0000-000000000006',
   'b5000013-0000-0000-0000-000000000013', 'b5000006-0000-0000-0000-000000000006',
   'Emergency Response ↔ CAD', 'bidirectional', 'api', 'real_time', 'internal', 'active', 'critical'),

  ('c1000007-0000-0000-0000-000000000007',
   'b1000007-0000-0000-0000-000000000007', 'b1000006-0000-0000-0000-000000000006',
   'b5000007-0000-0000-0000-000000000007', 'b5000006-0000-0000-0000-000000000006',
   'NG911 → CAD Call Routing', 'downstream', 'api', 'real_time', 'internal', 'active', 'critical'),

  ('c1000008-0000-0000-0000-000000000008',
   'b1000016-0000-0000-0000-000000000016', 'b100000f-0000-0000-0000-00000000000f',
   'b5000016-0000-0000-0000-000000000016', 'b500000f-0000-0000-0000-00000000000f',
   'Workday → Dynamics GP Payroll', 'downstream', 'file', 'batch_daily', 'internal', 'active', 'important')
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Phase 2p: Portfolio Assignments
-- =============================================================================
-- Link each application DP to its workspace's default "Core" portfolio
-- Unique constraint: (portfolio_id, deployment_profile_id) + unique index on
--   deployment_profile_id WHERE relationship_type = 'publisher'

INSERT INTO portfolio_assignments (portfolio_id, application_id, deployment_profile_id, relationship_type)
VALUES
  -- Police (portfolio: 95cca834)
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000001-0000-0000-0000-000000000001', 'b5000001-0000-0000-0000-000000000001', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000002-0000-0000-0000-000000000002', 'b5000002-0000-0000-0000-000000000002', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000003-0000-0000-0000-000000000003', 'b5000003-0000-0000-0000-000000000003', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000004-0000-0000-0000-000000000004', 'b5000004-0000-0000-0000-000000000004', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000005-0000-0000-0000-000000000005', 'b5000005-0000-0000-0000-000000000005', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000006-0000-0000-0000-000000000006', 'b5000006-0000-0000-0000-000000000006', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000007-0000-0000-0000-000000000007', 'b5000007-0000-0000-0000-000000000007', 'publisher'),
  ('95cca834-3766-4419-8541-53638826abe3', 'b1000008-0000-0000-0000-000000000008', 'b5000008-0000-0000-0000-000000000008', 'publisher'),

  -- IT (portfolio: ed60eeb6)
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b1000009-0000-0000-0000-000000000009', 'b5000009-0000-0000-0000-000000000009', 'publisher'),
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100000a-0000-0000-0000-00000000000a', 'b500000a-0000-0000-0000-00000000000a', 'publisher'),
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100000b-0000-0000-0000-00000000000b', 'b500000b-0000-0000-0000-00000000000b', 'publisher'),
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100000c-0000-0000-0000-00000000000c', 'b500000c-0000-0000-0000-00000000000c', 'publisher'),
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100000d-0000-0000-0000-00000000000d', 'b500000d-0000-0000-0000-00000000000d', 'publisher'),
  ('ed60eeb6-b1ee-4e1f-9611-517e2e5d5e85', 'b100000e-0000-0000-0000-00000000000e', 'b500000e-0000-0000-0000-00000000000e', 'publisher'),

  -- Finance (portfolio: f3ca6cff)
  ('f3ca6cff-84db-4e6e-80a9-2a13c1cabe36', 'b100000f-0000-0000-0000-00000000000f', 'b500000f-0000-0000-0000-00000000000f', 'publisher'),
  ('f3ca6cff-84db-4e6e-80a9-2a13c1cabe36', 'b1000010-0000-0000-0000-000000000010', 'b5000010-0000-0000-0000-000000000010', 'publisher'),
  ('f3ca6cff-84db-4e6e-80a9-2a13c1cabe36', 'b1000011-0000-0000-0000-000000000011', 'b5000011-0000-0000-0000-000000000011', 'publisher'),
  ('f3ca6cff-84db-4e6e-80a9-2a13c1cabe36', 'b1000012-0000-0000-0000-000000000012', 'b5000012-0000-0000-0000-000000000012', 'publisher'),

  -- Fire (portfolio: a34b276e)
  ('a34b276e-a853-4151-a5a1-c5af431e72b5', 'b1000013-0000-0000-0000-000000000013', 'b5000013-0000-0000-0000-000000000013', 'publisher'),
  ('a34b276e-a853-4151-a5a1-c5af431e72b5', 'b1000014-0000-0000-0000-000000000014', 'b5000014-0000-0000-0000-000000000014', 'publisher'),
  ('a34b276e-a853-4151-a5a1-c5af431e72b5', 'b1000015-0000-0000-0000-000000000015', 'b5000015-0000-0000-0000-000000000015', 'publisher'),

  -- HR (portfolio: 7196e826)
  ('7196e826-8a65-4932-a420-009cdd63cec6', 'b1000016-0000-0000-0000-000000000016', 'b5000016-0000-0000-0000-000000000016', 'publisher'),
  ('7196e826-8a65-4932-a420-009cdd63cec6', 'b1000017-0000-0000-0000-000000000017', 'b5000017-0000-0000-0000-000000000017', 'publisher'),
  ('7196e826-8a65-4932-a420-009cdd63cec6', 'b1000018-0000-0000-0000-000000000018', 'b5000018-0000-0000-0000-000000000018', 'publisher'),

  -- Dev Services (portfolio: 452f1444)
  ('452f1444-a4bf-422a-83ac-64dac067098c', 'b1000019-0000-0000-0000-000000000019', 'b5000019-0000-0000-0000-000000000019', 'publisher'),

  -- Customer Operations — CivicPlus + SeeClickFix (no portfolio given — use a workspace that has one)
  -- Note: No "Customer Operations" portfolio in the reference list. Using the workspace ID to look up.
  -- CivicPlus and SeeClickFix are in Customer Operations workspace but there's no Core portfolio listed.
  -- Skipping these two until a portfolio is created for Customer Operations.

  -- Public Works (portfolio: c82d90b1)
  ('c82d90b1-7b83-4d80-bca4-9dab44a67ef0', 'b100001b-0000-0000-0000-00000000001b', 'b500001b-0000-0000-0000-00000000001b', 'publisher'),

  -- Water Utilities (portfolio: e4930c14)
  ('e4930c14-41dc-4f52-bd35-919e321126f0', 'b100001d-0000-0000-0000-00000000001d', 'b500001d-0000-0000-0000-00000000001d', 'publisher'),

  -- Municipal Court (portfolio: 0a029b6b)
  ('0a029b6b-5915-4621-8911-eed5dcf23560', 'b100001e-0000-0000-0000-00000000001e', 'b500001e-0000-0000-0000-00000000001e', 'publisher')
ON CONFLICT (portfolio_id, deployment_profile_id) DO NOTHING;


-- =============================================================================
-- Phase 2q: Verification Queries
-- =============================================================================

DO $$
DECLARE
  v_apps       int;
  v_app_dps    int;
  v_infra_dps  int;
  v_cost_dps   int;
  v_it_svc     int;
  v_tech       int;
  v_sw         int;
  v_providers  int;
  v_is_tech    int;
  v_is_sw      int;
  v_dp_tech    int;
  v_dp_sw      int;
  v_dp_is      int;
  v_integ      int;
  v_portfolio  int;
  v_orgs       int;
BEGIN
  -- Count new organizations (vendor orgs with d1000015-18 pattern)
  SELECT count(*) INTO v_orgs FROM organizations
  WHERE id IN ('d1000015-0000-0000-0000-000000000015','d1000016-0000-0000-0000-000000000016','d1000017-0000-0000-0000-000000000017','d1000018-0000-0000-0000-000000000018');

  -- Applications
  SELECT count(*) INTO v_apps FROM applications
  WHERE id >= 'b1000001-0000-0000-0000-000000000001' AND id <= 'b100001e-0000-0000-0000-00000000001e';

  -- Application DPs
  SELECT count(*) INTO v_app_dps FROM deployment_profiles
  WHERE id >= 'b5000001-0000-0000-0000-000000000001' AND id <= 'b500001e-0000-0000-0000-00000000001e';

  -- Infrastructure DPs
  SELECT count(*) INTO v_infra_dps FROM deployment_profiles
  WHERE id >= 'b6000001-0000-0000-0000-000000000001' AND id <= 'b6000007-0000-0000-0000-000000000007';

  -- Cost Bundle DPs
  SELECT count(*) INTO v_cost_dps FROM deployment_profiles
  WHERE id >= 'b7000001-0000-0000-0000-000000000001' AND id <= 'b7000005-0000-0000-0000-000000000005';

  -- IT Services
  SELECT count(*) INTO v_it_svc FROM it_services
  WHERE id >= 'b4000001-0000-0000-0000-000000000001' AND id <= 'b400000c-0000-0000-0000-00000000000c';

  -- Technology Products
  SELECT count(*) INTO v_tech FROM technology_products
  WHERE id >= 'b2000001-0000-0000-0000-000000000001' AND id <= 'b200000d-0000-0000-0000-00000000000d';

  -- Software Products
  SELECT count(*) INTO v_sw FROM software_products
  WHERE id >= 'b3000001-0000-0000-0000-000000000001' AND id <= 'b3000010-0000-0000-0000-000000000010';

  -- IT Service Providers
  SELECT count(*) INTO v_providers FROM it_service_providers
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND it_service_id >= 'b4000001-0000-0000-0000-000000000001';

  -- IT Service → Tech Products
  SELECT count(*) INTO v_is_tech FROM it_service_technology_products
  WHERE it_service_id >= 'b4000001-0000-0000-0000-000000000001';

  -- IT Service → Software Products
  SELECT count(*) INTO v_is_sw FROM it_service_software_products
  WHERE it_service_id >= 'b4000001-0000-0000-0000-000000000001';

  -- DP → Tech Products
  SELECT count(*) INTO v_dp_tech FROM deployment_profile_technology_products
  WHERE deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001';

  -- DP → Software Products
  SELECT count(*) INTO v_dp_sw FROM deployment_profile_software_products
  WHERE deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001';

  -- DP → IT Services
  SELECT count(*) INTO v_dp_is FROM deployment_profile_it_services
  WHERE deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001';

  -- Integrations
  SELECT count(*) INTO v_integ FROM application_integrations
  WHERE id >= 'c1000001-0000-0000-0000-000000000001' AND id <= 'c1000008-0000-0000-0000-000000000008';

  -- Portfolio Assignments
  SELECT count(*) INTO v_portfolio FROM portfolio_assignments
  WHERE deployment_profile_id >= 'b5000001-0000-0000-0000-000000000001';

  RAISE NOTICE '========================================';
  RAISE NOTICE 'COR Demo Data — Phase 2 Verification';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'New Vendor Orgs:          % (target: 4)',  v_orgs;
  RAISE NOTICE 'Applications:             % (target: 30)', v_apps;
  RAISE NOTICE 'Application DPs:          % (target: 30)', v_app_dps;
  RAISE NOTICE 'Infrastructure DPs:       % (target: 7)',  v_infra_dps;
  RAISE NOTICE 'Cost Bundle DPs:          % (target: 5)',  v_cost_dps;
  RAISE NOTICE 'IT Services:              % (target: 12)', v_it_svc;
  RAISE NOTICE 'Technology Products:      % (target: 13)', v_tech;
  RAISE NOTICE 'Software Products:        % (target: 16)', v_sw;
  RAISE NOTICE 'IT Service Providers:     % (target: 7)',  v_providers;
  RAISE NOTICE 'IT Svc → Tech Products:   % (target: 11)', v_is_tech;
  RAISE NOTICE 'IT Svc → Software:        % (target: 8)',  v_is_sw;
  RAISE NOTICE 'DP → Tech Products:       % (target: 32)', v_dp_tech;
  RAISE NOTICE 'DP → Software Products:   % (target: 9)',  v_dp_sw;
  RAISE NOTICE 'DP → IT Services:         % (target: 80)', v_dp_is;
  RAISE NOTICE 'Integrations:             % (target: 8)',  v_integ;
  RAISE NOTICE 'Portfolio Assignments:    % (target: 28)', v_portfolio;
  RAISE NOTICE '========================================';
END $$;


-- =============================================================================
-- COMMIT — uncomment to apply, or replace with ROLLBACK to abort
-- =============================================================================

COMMIT;
-- ROLLBACK;
