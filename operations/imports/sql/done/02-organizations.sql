-- =============================================================================
-- Script 02: Organizations (Vendors & Manufacturers)
-- Records: 21
-- Source: Suppliers.json
-- Purpose: Create vendor/manufacturer organizations for the showcase
-- =============================================================================

BEGIN;

INSERT INTO organizations (id, namespace_id, owner_workspace_id, name, website, primary_email, primary_phone, is_vendor, is_manufacturer, is_partner, is_government, is_internal, is_msp, is_active, primary_workspace_id) VALUES

-- Customer Service & Utilities workspace orgs
('14054f77-7251-4501-920e-f8cc060b52a8', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'Advanced Utility System (AUS)', 'https://advancedutility.com/', 'support@advancedutility.com', '8883557772',
 true, true, false, false, false, false, true, NULL), -- OG ID: ac4d688e-2e72-4303-b8f8-7cde4d5cf023

('646b8473-56e1-4bca-beff-9ec1caa58508', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'System Innovators', 'www.systeminnovators.com', 'clientservices@systeminnovators.com', '8009635000',
 true, false, false, false, false, false, true, NULL), -- OG ID: 513103cd-8929-4343-9759-97142220314b

('97c6d3e0-735d-4823-ba3d-9c8051741a7a', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'Itron', 'https://customer.itron.com', 'support@itron.com', '8774876602',
 true, false, false, false, false, false, true, NULL), -- OG ID: e0fa7233-7fe7-4d4f-a004-c3dd204da8da

('3beff1dc-bb99-460a-830f-ac14200013de', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'Selectron Technologies, Inc.', 'https://www.selectrontechnologies.com/', 'sengel@Selectron.com', '5035973304',
 true, false, false, false, false, false, true, NULL), -- OG ID: d060a5f1-e6a3-4d1a-9692-687c3c96aab6

('3299780e-5180-421c-963b-e42cf54ff861', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'Aperta', 'www.aperta.com', 'd.chalfant@aperta.com', '8663273782',
 true, true, false, false, false, false, true, NULL), -- OG ID: c9cdb2f1-784c-49ec-9405-ea22e8fa54ff

('19779711-9c47-4c11-8434-394e63d9016c', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
 'Service-Link', 'https://www.service-link.us/', 'info@service-link.us', '6049820600',
 true, true, false, false, false, false, true, NULL), -- OG ID: bfe31976-7fd8-43cd-bf3d-99d761dd4721

-- Finance & Budget workspace orgs
('adac475c-2204-4d06-8bbf-d160f2534084', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '7240552a-0c39-4898-a4d7-32af799e46b3',
 'Harris Computer Corporation', 'https://www.cayenta.com/', NULL, NULL,
 true, false, false, false, false, false, true, NULL), -- OG ID: 080ba9cf-6290-44f5-b515-f79974a89314

('4ab23d81-a025-4c01-a0f7-fda657e04903', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '7240552a-0c39-4898-a4d7-32af799e46b3',
 'Euna Solutions (formerly Questica)', NULL, 'billing@eunasolutions.com', NULL,
 true, false, false, false, false, false, true, NULL), -- OG ID: f93265e0-7ac5-46a2-9a54-11b8789147f4

('4a475ad3-399c-46d2-8303-4af292e491e4', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '7240552a-0c39-4898-a4d7-32af799e46b3',
 'CaseWare', 'www.caseware.com', 'support@caseware.com', '8002671317',
 true, true, false, false, false, false, true, NULL), -- OG ID: af5cc1c4-29c4-41d3-bc5f-47fa524392c6

-- Police workspace orgs
('690d899f-fd2e-4822-b3e4-a1165d3b6189', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
 'Integraph Corporation', NULL, NULL, NULL,
 true, false, false, false, false, false, true, NULL), -- OG ID: 4edad1d3-9227-4499-aef3-faf633bcbfec

('e942bac6-5cbb-4b83-b2d0-eb7483026d32', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
 'Tyler Technology', 'https://www.tylertech.com/', 'Jon.Atkin@tylertech.com', '8007722260',
 true, false, false, false, false, false, true, NULL), -- OG ID: adb65606-16b6-4d18-9a1f-a9077ad75a9c

('28c7a0cf-72ba-4767-9df0-da9e64a067b6', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'effe3eb0-93fb-49fa-a478-9140e2c194b7',
 'Priority Dispatch', 'https://www.prioritydispatch.net', 'support@prioritydispatch.net', '8663773911',
 true, true, false, false, false, false, true, NULL), -- OG ID: f4ca7df4-bdd2-4be2-92f0-e1397e192473

-- Information Technology workspace orgs
('5981fceb-d20c-44d5-8a42-32fb88f32a34', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'City of Garland', 'www.garlandtx.gov', 'garland@garlandtx.gov', '9722052000',
 true, true, false, false, false, false, true, NULL), -- OG ID: ac54e950-b097-46f8-8107-442786293e04

('9ea0f8c6-a156-4cb4-8c30-fa3487bed13c', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Databank', 'https://www.databankimx.com/', 'support@databankimx.com', '8447414636',
 true, false, false, false, false, false, true, NULL), -- OG ID: 609886aa-4ce6-4828-8981-501296d232f4

('56978d87-8390-4eb1-b86b-b09d87c3accc', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Hyland', 'https://community.hyland.com', NULL, NULL,
 false, true, false, false, false, false, true, NULL), -- OG ID: 55b51a01-6887-428e-9118-801c43701341

('5373e57a-e7a6-47ff-89df-9c2ccf2e2bb1', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Precision Task Group', NULL, 'accounting@ptg.com', '7137871117',
 true, false, false, false, false, false, true, NULL), -- OG ID: d804dbe7-2379-4c35-bdd0-de91d82cd03a

('f2349c7d-3a30-41a5-a379-122f5ef480c0', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Workday', 'www.workday.com', NULL, NULL,
 false, true, false, false, false, false, true, NULL), -- OG ID: e31714ab-6ca8-42c6-ad8d-e6a0c9b5c212

('cfe434a6-5c93-439e-94ae-7b8c1eb05f76', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Convergint Technologies', 'https://www.convergint.com/', 'Sean.hamilton@convergint.com', '4692501982',
 true, false, false, false, false, false, true, NULL), -- OG ID: 25eaf8c5-c8a7-47b6-a7e6-4eb812560669

('90a8991c-3a7c-4665-a134-757746c99d5e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'ESRI', 'www.esri.com', NULL, '8883774575',
 true, false, false, false, false, false, true, NULL), -- OG ID: c66737f6-7bc1-455a-b73a-254dea952d00

('d049eb94-aa41-4dc8-a5b9-94aedb22bdff', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Microsoft Corp', 'http://www.microsoft.com', NULL, NULL,
 false, true, false, false, false, false, true, NULL), -- OG ID: b7bd986d-8da0-462c-8e9b-417bc2354a02

('d9f3be77-66e3-474d-a1e0-4c625092f52e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
 'Nintex', NULL, NULL, NULL,
 false, true, false, false, false, false, true, NULL); -- OG ID: d78418ef-24e6-429c-9d57-31d180359d80

COMMIT;

-- -------------------------------------------------------------------------
-- Validation
-- -------------------------------------------------------------------------

SELECT name, is_vendor, is_manufacturer
FROM organizations
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY name;
