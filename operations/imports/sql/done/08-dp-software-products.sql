-- ============================================================================
-- Script 08: DP → Software Product Links
-- Records: 17
-- Purpose: Link each deployment profile to its software product
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Deployment Profile → Software Product links (17 records)
-- --------------------------------------------------------------------------

INSERT INTO deployment_profile_software_products
  (id, deployment_profile_id, software_product_id, vendor_org_id, annual_cost, cost_confidence)
VALUES
  -- Customer Service & Utilities (ws_csu)
  (gen_random_uuid(),
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   '6752fde3-56b2-4958-be22-43cad4fb9feb',  -- sp_infinity_cis
   '14054f77-7251-4501-920e-f8cc060b52a8',  -- org_aus
   NULL, 'estimated'),

  (gen_random_uuid(),
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   '4a5f6e5c-c20c-4180-83b9-784045667e1e',  -- sp_inovah
   '646b8473-56e1-4bca-beff-9ec1caa58508',  -- org_system_innovators
   NULL, 'estimated'),

  (gen_random_uuid(),
   '7f5c9a62-0db2-4752-a803-666b3eca7be2',  -- dp_fcs_itron
   '99d0b362-1047-4eaf-9086-88e5017da074',  -- sp_itron_fcs
   '97c6d3e0-735d-4823-ba3d-9c8051741a7a',  -- org_itron
   NULL, 'estimated'),

  (gen_random_uuid(),
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   '77feb1ce-1c8f-4eae-8d83-fb6b44db52b8',  -- sp_selectron_ivr
   '3beff1dc-bb99-460a-830f-ac14200013de',  -- org_selectron
   NULL, 'estimated'),

  -- Finance & Budget (ws_fb)
  (gen_random_uuid(),
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   '963de413-4b35-4c0f-b0e0-81129938e292',  -- sp_cayenta
   'adac475c-2204-4d06-8bbf-d160f2534084',  -- org_harris
   NULL, 'estimated'),

  (gen_random_uuid(),
   '7bc0971b-1152-4d21-bc59-48db4b7fd348',  -- dp_questica
   'a617863f-7eba-424a-9654-fa8947a24df4',  -- sp_questica
   '4ab23d81-a025-4c01-a0f7-fda657e04903',  -- org_euna
   NULL, 'estimated'),

  (gen_random_uuid(),
   '33f3e9eb-3a91-4092-b8d0-e7a742fc7469',  -- dp_caseware
   '9b655e71-6e73-485e-aed6-31738f0523ca',  -- sp_caseware
   '4a475ad3-399c-46d2-8303-4af292e491e4',  -- org_caseware
   NULL, 'estimated'),

  -- Police & Public Safety (ws_pol)
  (gen_random_uuid(),
   '9abb5a77-40a9-4138-8218-988948bc2a1e',  -- dp_courts_plus
   '4636f201-34b7-4958-a876-e0935f9fbaa4',  -- sp_courts_plus
   '5981fceb-d20c-44d5-8a42-32fb88f32a34',  -- org_garland (in-house)
   NULL, 'estimated'),

  (gen_random_uuid(),
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon
   '313c644d-590b-4dd3-ab5c-589bf5fc0a83',  -- sp_hexagon
   '690d899f-fd2e-4822-b3e4-a1165d3b6189',  -- org_integraph
   NULL, 'estimated'),

  (gen_random_uuid(),
   '1f8db15b-425c-4dd6-b6f0-94c8413ec395',  -- dp_eticket
   'ad90f2be-eb96-4dcc-855b-eace3db552f5',  -- sp_brazos
   NULL,                                      -- org_tyler (inline UUID not provided, use NULL)
   NULL, 'estimated'),

  (gen_random_uuid(),
   '4c3fda02-694d-4b4c-857a-2b30b04c7f1e',  -- dp_proqa
   '9f4ac581-58ac-4c89-90f5-1b105e312f51',  -- sp_proqa
   '28c7a0cf-72ba-4767-9df0-da9e64a067b6',  -- org_priority_dispatch
   NULL, 'estimated'),

  -- IT / Corporate (ws_it)
  (gen_random_uuid(),
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   'c5b969bb-cfb3-4ebb-943c-a98289440168',  -- sp_onbase
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c',  -- org_databank
   NULL, 'estimated'),

  (gen_random_uuid(),
   '58e64b12-4ffa-414c-932b-1438b3ad0855',  -- dp_workday
   'a5195986-9783-4ebf-b9b8-fcba282f7153',  -- sp_workday
   '5373e57a-e7a6-47ff-89df-9c2ccf2e2bb1',  -- org_precision_task
   NULL, 'estimated'),

  (gen_random_uuid(),
   '62090be1-26a6-4659-a319-56527e0fb67a',  -- dp_genetec
   '425df097-90b2-4627-8f00-aefcdf34c75a',  -- sp_genetec
   'cfe434a6-5c93-439e-94ae-7b8c1eb05f76',  -- org_convergint
   NULL, 'estimated'),

  (gen_random_uuid(),
   'f62dd081-3f3b-4d41-8df9-fef3eae2a421',  -- dp_crm
   'df19bd06-92c9-4868-af21-a1b8530aef63',  -- sp_dynamics_crm
   NULL,                                      -- no vendor in OG data
   NULL, 'estimated'),

  (gen_random_uuid(),
   '744d890d-b49b-4b99-9c6c-9bb24f48116c',  -- dp_nintex
   'b0767c84-546b-4923-a859-6d7c6799860d',  -- sp_nintex
   '9ea0f8c6-a156-4cb4-8c30-fa3487bed13c',  -- org_databank
   NULL, 'estimated'),

  (gen_random_uuid(),
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   '9e1b1c4f-09d3-45b0-b1b0-29b2e7a708e0',  -- sp_arcgis
   '90a8991c-3a7c-4665-a134-757746c99d5e',  -- org_esri
   NULL, 'estimated');

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------

SELECT count(*) AS dp_software_product_count
FROM deployment_profile_software_products dpsp
JOIN deployment_profiles dp ON dp.id = dpsp.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';
-- Expected: 17

COMMIT;
