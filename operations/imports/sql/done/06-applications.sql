-- ============================================================================
-- Script 06: Applications
-- Records: 21
-- Source: Applications.json
-- Purpose: Create the 21 showcase applications
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Applications (21 records)
-- --------------------------------------------------------------------------

INSERT INTO applications (id, workspace_id, name, description, short_description, operational_status, lifecycle_status)
VALUES
  -- Customer Service & Utilities (ws_csu)
  ('65cd4b69-33f2-480a-b26b-2926c3c2b881', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Infinity CIS',
   'Utility billing and customer information system for water, electric, and gas services.',
   'Utility billing and CIS',
   'operational', NULL),  -- OG ID: 20ac4bbc-9da9-4902-c912-08dcc2c003eb

  ('d6e3197f-915b-4c31-b73f-8c723f7fcf17', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Inovah',
   'Payment processing and cashiering system for utility and municipal payments.',
   'Payment processing',
   'operational', NULL),  -- OG ID: 3f2b6a34-ab05-4fd4-f9e3-08dcc1fa2f15

  ('839ed0f0-4a93-47bb-a932-6e20ed238455', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'FCS - Itron',
   'Fixed-network AMI meter reading and field collection system for utility metering.',
   'AMI meter reading',
   'operational', NULL),  -- OG ID: f0077b55-45d6-47d0-f9c5-08dcc1fa2f15

  ('632c606f-1904-4110-91b2-dc9b3427c08e', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Selectron IVR',
   'Interactive voice response system for automated customer self-service and payment by phone.',
   'IVR self-service',
   'operational', NULL),  -- OG ID: 4632c125-37f0-4d57-f9d3-08dcc1fa2f15

  ('79b5afd9-7335-4c9c-ab99-fdff74dc1a7a', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Service Link',
   'Service order management and work dispatch system for utility field operations.',
   'Service order management',
   'operational', NULL),  -- OG ID: 6d89a380-ad88-43a0-c914-08dcc2c003eb

  ('65d84b68-55c4-4054-8150-9c3e8579e990', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Bill Image Files',
   'Document imaging and archival system for storing scanned utility bill images.',
   'Bill image archival',
   'operational', NULL),  -- OG ID: f2434349-a7f5-4bd3-2878-08dcd102e1dc

  ('42e8273c-ec08-4fe2-b485-44ee90620ab0', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'MAM File',
   'Meter asset management file system for tracking utility meter inventory and lifecycle.',
   'Meter asset management',
   'operational', NULL),  -- OG ID: 7689cede-fffc-4d74-2879-08dcd102e1dc

  ('49c6f40f-8398-4f7c-9ac1-69352584aa89', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Aperta',
   'Cloud-based open records and public information request management portal.',
   'Open records management',
   'operational', NULL),  -- OG ID: 4c7c8049-31ee-42d4-0015-08dcc15d11ee

  -- Finance & Budget (ws_fb)
  ('86bf1db4-42e9-47ef-8352-bc43ce97f516', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Cayenta (Finance)',
   'Enterprise financial management and accounting system including general ledger, AP, AR, and purchasing.',
   'Financial management and ERP',
   'operational', NULL),  -- OG ID: 429c1102-9498-4add-f9aa-08dcc1fa2f15

  ('1663a230-bc33-4e98-ae11-71df77aeea2e', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Questica',
   'Budget preparation, management, and performance reporting platform.',
   'Budget management',
   'operational', NULL),  -- OG ID: 8aafbff5-192e-4a0f-f9fc-08dcc1fa2f15

  ('5f0a1732-9373-414a-b580-fac581972d43', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Caseware',
   'Audit working papers and financial statement preparation software for year-end reporting.',
   'Audit and financial reporting',
   'operational', NULL),  -- OG ID: b49565fc-225d-469e-f9a8-08dcc1fa2f15

  ('d58cf0bf-8016-4ab8-a054-28fbdbe747e1', '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Courts Plus',
   'Municipal court case management system for citation tracking, dockets, and fine processing.',
   'Court case management',
   'operational', NULL),  -- OG ID: 8f241cb6-2e82-4908-f9b4-08dcc1fa2f15

  -- Police & Public Safety (ws_pol)
  ('f46c922a-e7b0-49bd-a856-7b8fd53c68e8', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Hexagon OnCall',
   'Computer-aided dispatch and records management system for police and fire emergency response.',
   'CAD and records management',
   'operational', NULL),  -- OG ID: a4488843-e03f-4944-f9db-08dcc1fa2f15

  ('34876796-d6e9-4f93-9dff-88fb030ec5b5', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Eticket Citation Writer (Brazos)',
   'Mobile electronic citation writing system for field officers issuing traffic and parking tickets.',
   'Electronic citation writing',
   'operational', NULL),  -- OG ID: f8382ea9-92eb-4f5d-f9c1-08dcc1fa2f15

  ('a7055029-f856-4bae-a377-9da52d173cfd', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'ProQa & Aqua',
   'Protocol-based call-taking and quality assurance system for 911 dispatch centers.',
   '911 dispatch protocol QA',
   'operational', NULL),  -- OG ID: 2fdd342d-28ad-47d3-0017-08dcc15d11ee

  -- IT & Corporate Services (ws_it)
  ('6244a5b8-5581-44ff-be67-48332102fc07', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'OnBase',
   'Enterprise content management and workflow automation platform for document imaging and business process management.',
   'ECM and workflow automation',
   'operational', NULL),  -- OG ID: 96168f97-908a-44af-f9f3-08dcc1fa2f15

  ('ef6b4c4b-0312-4fe4-8fc2-fa5263dcc98a', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Workday',
   'Cloud-based human capital management system for HR, payroll, benefits, and talent management.',
   'HCM and payroll',
   'operational', NULL),  -- OG ID: a76bba69-3c76-4891-fa0e-08dcc1fa2f15

  ('10d2d61f-7e1a-44f3-bd2a-3b939118666a', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Genetec Video',
   'Enterprise video surveillance management system for city-wide security camera infrastructure.',
   'Video surveillance management',
   'operational', NULL),  -- OG ID: 5f774444-3953-4068-f9d2-08dcc1fa2f15

  ('4d1d564f-8f0c-4329-8566-086bf09ea1f8', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'CRM (2016)',
   'Customer relationship management system built on Microsoft Dynamics for citizen service requests.',
   'CRM for citizen services',
   'operational', NULL),  -- OG ID: 978e2725-0156-4743-f9b8-08dcc1fa2f15

  ('3ca20ec2-3b1b-4cee-984d-276270b85b98', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Nintex Sharepoint Workflow',
   'SharePoint-integrated workflow automation for forms, approvals, and business process automation.',
   'SharePoint workflow automation',
   'operational', NULL),  -- OG ID: 7f7a16e5-2fcb-4046-fdf2-08dd3b1c2144

  ('834398a6-ad10-433a-96ab-eae000c666a0', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'ArcGIS - ESRI',
   'Geographic information system platform for spatial analysis, mapping, and asset management across city departments.',
   'GIS and spatial analysis',
   'operational', NULL);  -- OG ID: 11fc61b5-75e3-423a-0018-08dcc15d11ee

COMMIT;

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------
SELECT a.name, w.name AS workspace
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY w.name, a.name;
