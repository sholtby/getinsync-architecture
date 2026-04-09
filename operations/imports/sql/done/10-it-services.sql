-- ============================================================================
-- Script 10: IT Services
-- Records: 8
-- Purpose: Create IT services with hand-curated vendor costs (cost model showcase)
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- IT Services (8 records)
-- --------------------------------------------------------------------------

INSERT INTO it_services
  (id, namespace_id, owner_workspace_id, name, description, annual_cost, cost_model, is_internal_only, lifecycle_state, vendor_org_id)
VALUES
  -- Customer Service & Utilities (ws_csu)
  ('9e0473da-7249-421b-bddc-b3f148690af2',  -- its_aus
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',  -- namespace
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',  -- ws_csu
   'AUS — Infinity CIS Platform Support',
   'Annual maintenance and support contract for the Infinity CIS utility billing platform.',
   512996, 'fixed', false, 'active',
   '14054f77-7251-4501-920e-f8cc060b52a8'),  -- org_aus

  ('5b439756-1ea9-42c7-862b-0365dd9852e3',  -- its_system_innovators
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',  -- ws_csu
   'System Innovators — Inovah Payment Platform',
   'License and support for the Inovah cashiering and payment processing platform.',
   84123, 'fixed', false, 'active',
   '646b8473-56e1-4bca-beff-9ec1caa58508'),  -- org_system_innovators

  ('404aab68-95f4-46ec-9c4b-25edd06765ea',  -- its_selectron
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',  -- ws_csu
   'Selectron — IVR System License & Support',
   'Annual license and support for the Selectron interactive voice response system.',
   104170, 'fixed', false, 'active',
   '3beff1dc-bb99-460a-830f-ac14200013de'),  -- org_selectron

  -- Finance & Budget (ws_fb)
  ('cd4702cf-de59-4fc4-a073-a8311be841c8',  -- its_harris
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '7240552a-0c39-4898-a4d7-32af799e46b3',  -- ws_fb
   'Harris Computer — Cayenta Finance Suite',
   'Annual license and support for the Cayenta financial management and payroll suite.',
   351901, 'fixed', false, 'active',
   'adac475c-2204-4d06-8bbf-d160f2534084'),  -- org_harris

  -- Police & Public Safety (ws_pol)
  ('9ea120b7-153c-43d1-a3e6-a8a470b9b57d',  -- its_integraph
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'effe3eb0-93fb-49fa-a478-9140e2c194b7',  -- ws_pol
   'Integraph — Hexagon OnCall RMS/CAD',
   'Annual license and managed service for the Hexagon OnCall records and dispatch platform.',
   467810, 'fixed', false, 'active',
   '690d899f-fd2e-4822-b3e4-a1165d3b6189'),  -- org_integraph

  -- IT / Corporate (ws_it)
  ('f5aa0a1e-7fd0-4596-9438-fa540f14e330',  -- its_databank_onbase
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',  -- ws_it
   'Databank — OnBase Managed Hosting',
   'Managed hosting and support for the Hyland OnBase document management platform.',
   398984, 'fixed', false, 'active',
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c'),  -- org_databank

  ('e2b35bf6-501b-4027-a3a7-e7d241406dc5',  -- its_databank_sp
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',  -- ws_it
   'Databank — SharePoint Hosting',
   'Managed hosting and support for SharePoint and Nintex workflow platform.',
   112150, 'fixed', false, 'active',
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c'),  -- org_databank

  ('128fc24b-15a4-41ac-873b-3e7ec39e3d9e',  -- its_precision
   'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',  -- ws_it
   'Precision Task Group — Workday Implementation',
   'Implementation services and first-year subscription for the Workday HCM platform.',
   1299416, 'fixed', false, 'active',
   '5373e57a-e7a6-47ff-89df-9c2ccf2e2bb1');  -- org_precision_task

COMMIT;

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------

SELECT name, annual_cost
FROM it_services
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY annual_cost DESC;
-- Expected: 8 rows, Precision Task Group at top ($1,299,416)
