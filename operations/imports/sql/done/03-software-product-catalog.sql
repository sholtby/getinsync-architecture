-- =============================================================================
-- Script 03: Software Product Catalog
-- Records: 17
-- Source: garland-showcase-demo-plan.md Phase 3
-- Purpose: Create software product entries for the showcase applications
-- =============================================================================

BEGIN;

INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, manufacturer_org_id, category, license_type, is_internal_only, is_deprecated, is_org_wide) VALUES

-- OG App: Infinity CIS
('6752fde3-56b2-4958-be22-43cad4fb9feb', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Infinity CIS', '14054f77-7251-4501-920e-f8cc060b52a8', 'platform', 'subscription', false, false, false),

-- OG App: Inovah
('4a5f6e5c-c20c-4180-83b9-784045667e1e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Inovah', '646b8473-56e1-4bca-beff-9ec1caa58508', 'other', 'subscription', false, false, false),

-- OG App: FCS - Itron
('99d0b362-1047-4eaf-9086-88e5017da074', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Itron FCS', '97c6d3e0-735d-4823-ba3d-9c8051741a7a', 'other', 'subscription', false, false, false),

-- OG App: Selectron IVR
('77feb1ce-1c8f-4eae-8d83-fb6b44db52b8', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Selectron IVR', '3beff1dc-bb99-460a-830f-ac14200013de', 'other', 'subscription', false, false, false),

-- OG App: Cayenta (Finance)
('963de413-4b35-4c0f-b0e0-81129938e292', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Cayenta Finance', 'adac475c-2204-4d06-8bbf-d160f2534084', 'platform', 'subscription', false, false, false),

-- OG App: Questica
('a617863f-7eba-424a-9654-fa8947a24df4', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Questica Budget', '4ab23d81-a025-4c01-a0f7-fda657e04903', 'saas', 'subscription', false, false, false),

-- OG App: Caseware
('9b655e71-6e73-485e-aed6-31738f0523ca', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'CaseWare Working Papers', '4a475ad3-399c-46d2-8303-4af292e491e4', 'other', 'perpetual', false, false, false),

-- OG App: Courts Plus
('4636f201-34b7-4958-a876-e0935f9fbaa4', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Courts Plus', '5981fceb-d20c-44d5-8a42-32fb88f32a34', 'other', 'other', false, false, false),

-- OG App: Hexagon OnCall
('313c644d-590b-4dd3-ab5c-589bf5fc0a83', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Hexagon OnCall RMS/CAD', '690d899f-fd2e-4822-b3e4-a1165d3b6189', 'platform', 'subscription', false, false, false),

-- OG App: Eticket Citation Writer (Brazos)
('ad90f2be-eb96-4dcc-855b-eace3db552f5', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Brazos eCitation', 'e942bac6-5cbb-4b83-b2d0-eb7483026d32', 'other', 'subscription', false, false, false),

-- OG App: ProQa & Aqua
('9f4ac581-58ac-4c89-90f5-1b105e312f51', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'ProQa & Aqua', '28c7a0cf-72ba-4767-9df0-da9e64a067b6', 'other', 'subscription', false, false, false),

-- OG App: OnBase
('c5b969bb-cfb3-4ebb-943c-a98289440168', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Hyland OnBase', '56978d87-8390-4eb1-b86b-b09d87c3accc', 'platform', 'subscription', false, false, false),

-- OG App: Workday
('a5195986-9783-4ebf-b9b8-fcba282f7153', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Workday HCM', 'f2349c7d-3a30-41a5-a379-122f5ef480c0', 'saas', 'subscription', false, false, false),

-- OG App: Genetec Video
('425df097-90b2-4627-8f00-aefcdf34c75a', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Genetec Security Center', 'cfe434a6-5c93-439e-94ae-7b8c1eb05f76', 'platform', 'subscription', false, false, false),

-- OG App: CRM (2016)
('df19bd06-92c9-4868-af21-a1b8530aef63', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Microsoft Dynamics CRM 2016', 'd049eb94-aa41-4dc8-a5b9-94aedb22bdff', 'platform', 'perpetual', false, false, false),

-- OG App: Nintex Sharepoint Workflow
('b0767c84-546b-4923-a859-6d7c6799860d', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Nintex Workflow', 'd9f3be77-66e3-474d-a1e0-4c625092f52e', 'plugin', 'subscription', false, false, false),

-- OG App: ArcGIS - ESRI
('9e1b1c4f-09d3-45b0-b1b0-29b2e7a708e0', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'ArcGIS', '90a8991c-3a7c-4665-a134-757746c99d5e', 'platform', 'subscription', false, false, false);

COMMIT;

-- -------------------------------------------------------------------------
-- Validation
-- -------------------------------------------------------------------------

SELECT name, category, license_type
FROM software_products
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY name;
