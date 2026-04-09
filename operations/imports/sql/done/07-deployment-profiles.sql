-- ============================================================================
-- Script 07: Deployment Profiles
-- Records: 21
-- Source: Applications.json, ApplicationITServices.json, ApplicationHostingTypes.json
-- Purpose: Create primary DPs with hosting, server names, vendor org, and T-scores
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Deployment Profiles (21 records)
-- --------------------------------------------------------------------------

INSERT INTO deployment_profiles (
  id, application_id, workspace_id, name, is_primary,
  hosting_type, server_name, vendor_org_id, environment, dp_type,
  operational_status, annual_cost, annual_licensing_cost, annual_tech_cost, cost_recurrence,
  t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12, t13, t14, t15,
  tech_assessment_status
)
VALUES
  -- Customer Service & Utilities (ws_csu)
  ('3fe2a39a-28bb-4cf5-badd-320cec96bfb2',
   '65cd4b69-33f2-480a-b26b-2926c3c2b881', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Infinity CIS - PROD - On-Prem', true,
   'On-Prem', 'UTIL-APP3, UTIL-AVL, UTIL-BILLARCH2, UTIL-SQLDBS, UTIL-SRVLNK',
   '14054f77-7251-4501-920e-f8cc060b52a8', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 2, NULL, 1, NULL, 3, NULL, 2, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 20ac4bbc

  ('02136b36-f9ac-4fee-8122-0746423bc28e',
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Inovah - PROD - On-Prem', true,
   'On-Prem', 'COG-SQL16DBS, COG-SQLRS3, UTIL-INOVAH',
   '646b8473-56e1-4bca-beff-9ec1caa58508', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 4, 1, NULL, 1, NULL, 4, NULL, 5, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 3f2b6a34

  ('7f5c9a62-0db2-4752-a803-666b3eca7be2',
   '839ed0f0-4a93-47bb-a932-6e20ed238455', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'FCS - Itron - PROD - On-Prem', true,
   'On-Prem', 'CGSHRDBPRDV22',
   '97c6d3e0-735d-4823-ba3d-9c8051741a7a', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 1, NULL, 4, NULL, 4, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: f0077b55

  ('5668512a-7405-4a29-99de-bd07552ff23f',
   '632c606f-1904-4110-91b2-dc9b3427c08e', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Selectron IVR - PROD - On-Prem', true,
   'On-Prem', 'COG-SELDB, COG-SELIVR1, COG-SELIVR2, COG-SELIVR3, COG-SELPOP, COURT-SELIVR',
   '3beff1dc-bb99-460a-830f-ac14200013de', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 4, 1, NULL, 1, NULL, 4, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 4632c125

  ('318f7068-6db1-40de-ba88-60d508e7bd7a',
   '79b5afd9-7335-4c9c-ab99-fdff74dc1a7a', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Service Link - PROD - On-Prem', true,
   'On-Prem', 'UTIL-SQLDBS, UTIL-SRVLNK',
   '19779711-9c47-4c11-8434-394e63d9016c', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 2, NULL, 4, NULL, 2, 3, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 6d89a380

  ('3fde389f-b704-452d-ba88-37e5b9305fea',
   '65d84b68-55c4-4054-8150-9c3e8579e990', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Bill Image Files - PROD - On-Prem', true,
   'On-Prem', NULL,
   '5981fceb-d20c-44d5-8a42-32fb88f32a34', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 1, 1, NULL, 4, NULL, 4, NULL, 5, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: f2434349

  ('88ad89b0-7887-4156-b3be-d5a5ada91597',
   '42e8273c-ec08-4fe2-b485-44ee90620ab0', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'MAM File - PROD - On-Prem', true,
   'On-Prem', NULL,
   '5981fceb-d20c-44d5-8a42-32fb88f32a34', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 1, 1, NULL, 1, NULL, 4, NULL, 5, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 7689cede

  ('8cc68b80-18b0-4e82-8927-ad399c2edbc6',
   '49c6f40f-8398-4f7c-9ac1-69352584aa89', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Aperta - PROD - SaaS', true,
   'SaaS', NULL,
   '3299780e-5180-421c-963b-e42cf54ff861', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 1, NULL, 4, NULL, 5, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 4c7c8049

  -- Finance & Budget (ws_fb)
  ('d63a3f92-e52a-4485-8960-f8a75a9d0886',
   '86bf1db4-42e9-47ef-8352-bc43ce97f516', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Cayenta (Finance) - PROD - On-Prem', true,
   'On-Prem', 'COG-LINPRT, FIN-ORADB, FIN-APP',
   'adac475c-2204-4d06-8bbf-d160f2534084', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   2, 4, 2, NULL, NULL, NULL, 3, NULL, 5, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 429c1102

  ('7bc0971b-1152-4d21-bc59-48db4b7fd348',
   '1663a230-bc33-4e98-ae11-71df77aeea2e', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Questica - PROD - SaaS', true,
   'SaaS', NULL,
   '4ab23d81-a025-4c01-a0f7-fda657e04903', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 3, NULL, 4, NULL, 5, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 8aafbff5

  ('33f3e9eb-3a91-4092-b8d0-e7a742fc7469',
   '5f0a1732-9373-414a-b580-fac581972d43', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Caseware - PROD - Desktop', true,
   'Desktop', NULL,
   '4a475ad3-399c-46d2-8303-4af292e491e4', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 2, NULL, 4, NULL, 5, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: b49565fc

  ('9abb5a77-40a9-4138-8218-988948bc2a1e',
   'd58cf0bf-8016-4ab8-a054-28fbdbe747e1', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Courts Plus - PROD - On-Prem', true,
   'On-Prem', 'court-ifx1',
   '5981fceb-d20c-44d5-8a42-32fb88f32a34', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   1, 4, 1, NULL, 1, NULL, 4, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 8f241cb6

  -- Police & Public Safety (ws_pol)
  ('51ef02de-1627-4674-8f2c-551e15f363a3',
   'f46c922a-e7b0-49bd-a856-7b8fd53c68e8', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Hexagon OnCall - PROD - On-Prem', true,
   'On-Prem', 'GFD-FIRECOMM, GPD-POLICECOMM, GPD-SQLAO, GPD-SQLARC, GPD-SQLCAD1, GPD-SQLCAD2, GPD-WRMSAPP1, GPD-WRMSAPP2',
   '690d899f-fd2e-4822-b3e4-a1165d3b6189', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 4, 1, NULL, 1, NULL, 4, NULL, 4, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: a4488843

  ('1f8db15b-425c-4dd6-b6f0-94c8413ec395',
   '34876796-d6e9-4f93-9dff-88fb030ec5b5', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Eticket Citation Writer (Brazos) - PROD - On-Prem', true,
   'On-Prem', 'GPD-INTERFACE',
   'e942bac6-5cbb-4b83-b2d0-eb7483026d32', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 4, 1, NULL, 1, NULL, 4, NULL, 5, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: f8382ea9

  ('4c3fda02-694d-4b4c-857a-2b30b04c7f1e',
   'a7055029-f856-4bae-a377-9da52d173cfd', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'ProQa & Aqua - PROD - On-Prem', true,
   'On-Prem', 'GPD-PROQA',
   '28c7a0cf-72ba-4767-9df0-da9e64a067b6', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 5, NULL, 4, NULL, 5, 4, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 2fdd342d

  -- IT & Corporate Services (ws_it)
  ('3d43d741-7d1b-47d5-b72d-7b99d8dbf218',
   '6244a5b8-5581-44ff-be67-48332102fc07', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'OnBase - PROD - On-Prem', true,
   'On-Prem', 'COG-IMAGEWS2, IMAGE-APP3, IMAGE-APP4, IMAGE-COMP2, IMAGE-DIPPER2, IMAGE-FTS, IMAGE-SQLDBS2, IMAGE-WKFLW3, IMAGE-WKFLW4',
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 4, 1, NULL, 2, NULL, 4, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 96168f97

  ('58e64b12-4ffa-414c-932b-1438b3ad0855',
   'ef6b4c4b-0312-4fe4-8fc2-fa5263dcc98a', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Workday - PROD - SaaS', true,
   'SaaS', NULL,
   '5373e57a-e7a6-47ff-89df-9c2ccf2e2bb1', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   5, 4, NULL, NULL, 2, NULL, 3, NULL, 5, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: a76bba69 | vendor: Precision Task Group

  ('62090be1-26a6-4659-a319-56527e0fb67a',
   '10d2d61f-7e1a-44f3-bd2a-3b939118666a', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Genetec Video - PROD - On-Prem', true,
   'On-Prem', 'COG-VIDARC1, COG-VIDARC10, COG-VIDARC11, COG-VIDARC12, COG-VIDARC13, COG-VIDARC14, COG-VIDARC15, COG-VIDARC16, COG-VIDARC2, COG-VIDARC3, COG-VIDARC4, COG-VIDARC5, COG-VIDARC6, COG-VIDARC7, COG-VIDARC8, COG-VIDARC9, COG-VIDAPP, COG-VIDDIR1, COG-VIDDIR2, COG-VIDSQL, COG-VIDWEB',
   'cfe434a6-5c93-439e-94ae-7b8c1eb05f76', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 1, NULL, 1, NULL, 4, NULL, 5, 1, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 5f774444

  ('f62dd081-3f3b-4d41-8df9-fef3eae2a421',
   '4d1d564f-8f0c-4329-8566-086bf09ea1f8', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'CRM (2016) - PROD - On-Prem', true,
   'On-Prem', 'COG-DYNAPP, COG-SQL14DBS, COG-SQLRS, DYN-WS',
   NULL, 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   2, 3, 2, NULL, 1, NULL, 3, NULL, 3, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 978e2725

  ('744d890d-b49b-4b99-9c6c-9bb24f48116c',
   '3ca20ec2-3b1b-4cee-984d-276270b85b98', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Nintex Sharepoint Workflow - PROD - On-Prem', true,
   'On-Prem', 'COG-SPWEB',
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   4, 3, 2, NULL, 1, NULL, 5, NULL, 5, 3, NULL, NULL, NULL, NULL, NULL,
   'in_progress'),  -- OG App ID: 7f7a16e5

  ('82b64ecb-dc7e-4586-8771-bca32d3592c9',
   '834398a6-ad10-433a-96ab-eae000c666a0', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'ArcGIS - ESRI - PROD - On-Prem', true,
   'On-Prem', 'GIS-COGMAP-WAT, GIS-COGMAP2, GIS-COGMAP4, GIS-DBS1, GIS-SQLDB, GIS-WS',
   '90a8991c-3a7c-4665-a134-757746c99d5e', 'PROD', 'application',
   'operational', 0, 0, 0, 'recurring',
   5, 3, 1, NULL, 5, NULL, 4, NULL, 4, 2, NULL, NULL, NULL, NULL, NULL,
   'in_progress');  -- OG App ID: 11fc61b5

-- --------------------------------------------------------------------------
-- Remove auto-generated "Region-PROD" DPs created by the
-- create_deployment_profile_on_app_create trigger in script 06.
-- We only want the hand-curated DPs inserted above.
-- --------------------------------------------------------------------------
DELETE FROM deployment_profiles
WHERE workspace_id IN (
  SELECT id FROM workspaces
  WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
)
AND name LIKE '%Region-PROD%';

COMMIT;

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------
SELECT dp.name, dp.hosting_type, dp.server_name IS NOT NULL AS has_server, dp.t01, dp.tech_assessment_status
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY dp.name;
