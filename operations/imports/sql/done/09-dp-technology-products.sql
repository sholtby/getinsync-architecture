-- ============================================================================
-- Script 09: DP → Technology Product Links
-- Records: 21
-- Purpose: Tag deployment profiles with their server OS technology products
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Deployment Profile → Technology Product links (21 records)
-- --------------------------------------------------------------------------

INSERT INTO deployment_profile_technology_products
  (id, deployment_profile_id, technology_product_id, edition)
VALUES
  -- dp_infinity_cis — Windows Server 2016 + 2022
  (gen_random_uuid(),
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  (gen_random_uuid(),
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   '746faf67-14c6-43b3-81ea-24296a2679f9',  -- tp_ws2022std
   'Standard'),

  -- dp_inovah — Windows Server 2016
  (gen_random_uuid(),
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  -- dp_fcs_itron — Windows Server 2022
  (gen_random_uuid(),
   '7f5c9a62-0db2-4752-a803-666b3eca7be2',  -- dp_fcs_itron
   '746faf67-14c6-43b3-81ea-24296a2679f9',  -- tp_ws2022std
   'Standard'),

  -- dp_selectron — Windows Server 2016
  (gen_random_uuid(),
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  -- dp_cayenta — Windows Server 2019 + RHEL 6.1
  (gen_random_uuid(),
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   'be95d3d5-3cdc-43fc-bc3a-908864fc910b',  -- tp_ws2019std
   'Standard'),

  (gen_random_uuid(),
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   'e3f536e4-504f-42e2-a653-3d0af7b9ff76',  -- tp_rhel61
   NULL),

  -- dp_courts_plus — RHEL 6.5
  (gen_random_uuid(),
   '9abb5a77-40a9-4138-8218-988948bc2a1e',  -- dp_courts_plus
   '50c9dfbb-4174-4f18-9993-428e56c2939f',  -- tp_rhel65
   NULL),

  -- dp_hexagon — Windows Server 2016
  (gen_random_uuid(),
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  -- dp_eticket — Windows Server 2019
  (gen_random_uuid(),
   '1f8db15b-425c-4dd6-b6f0-94c8413ec395',  -- dp_eticket
   'be95d3d5-3cdc-43fc-bc3a-908864fc910b',  -- tp_ws2019std
   'Standard'),

  -- dp_proqa — Windows Server 2016
  (gen_random_uuid(),
   '4c3fda02-694d-4b4c-857a-2b30b04c7f1e',  -- dp_proqa
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  -- dp_onbase — Windows Server 2019 + 2022
  (gen_random_uuid(),
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   'be95d3d5-3cdc-43fc-bc3a-908864fc910b',  -- tp_ws2019std
   'Standard'),

  (gen_random_uuid(),
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   '746faf67-14c6-43b3-81ea-24296a2679f9',  -- tp_ws2022std
   'Standard'),

  -- dp_genetec — Windows Server 2022
  (gen_random_uuid(),
   '62090be1-26a6-4659-a319-56527e0fb67a',  -- dp_genetec
   '746faf67-14c6-43b3-81ea-24296a2679f9',  -- tp_ws2022std
   'Standard'),

  -- dp_crm — Windows Server 2012 R2 + 2019
  (gen_random_uuid(),
   'f62dd081-3f3b-4d41-8df9-fef3eae2a421',  -- dp_crm
   '187c9e0d-c907-4ebb-a069-830491ccc804',  -- tp_ws2012r2
   NULL),

  (gen_random_uuid(),
   'f62dd081-3f3b-4d41-8df9-fef3eae2a421',  -- dp_crm
   'be95d3d5-3cdc-43fc-bc3a-908864fc910b',  -- tp_ws2019std
   'Standard'),

  -- dp_nintex — Windows Server 2012 Standard
  (gen_random_uuid(),
   '744d890d-b49b-4b99-9c6c-9bb24f48116c',  -- dp_nintex
   'dea5a0ac-6cff-4733-9a4b-f9f77249dcac',  -- tp_ws2012std
   'Standard'),

  -- dp_arcgis — Windows Server 2012 R2 + 2016 + 2019 + 2022
  (gen_random_uuid(),
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   '187c9e0d-c907-4ebb-a069-830491ccc804',  -- tp_ws2012r2
   NULL),

  (gen_random_uuid(),
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   '7d8959fa-a9be-4bd6-bba6-53562f1ea91b',  -- tp_ws2016std
   'Standard'),

  (gen_random_uuid(),
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   'be95d3d5-3cdc-43fc-bc3a-908864fc910b',  -- tp_ws2019std
   'Standard'),

  (gen_random_uuid(),
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   '746faf67-14c6-43b3-81ea-24296a2679f9',  -- tp_ws2022std
   'Standard');

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------

SELECT count(*) AS dp_technology_product_count
FROM deployment_profile_technology_products dptp
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';
-- Expected: 21

COMMIT;
