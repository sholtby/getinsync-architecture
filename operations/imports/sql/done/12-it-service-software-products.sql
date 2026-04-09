-- ============================================================================
-- Script 12: IT Service → Software Product Links
-- Records: 6
-- Purpose: Link IT services to the software products they cover
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- IT Service → Software Product links (6 records)
-- --------------------------------------------------------------------------

INSERT INTO it_service_software_products
  (id, it_service_id, software_product_id)
VALUES
  -- AUS → Infinity CIS
  (gen_random_uuid(),
   '9e0473da-7249-421b-bddc-b3f148690af2',  -- its_aus
   '6752fde3-56b2-4958-be22-43cad4fb9feb'),  -- sp_infinity_cis

  -- System Innovators → Inovah
  (gen_random_uuid(),
   '5b439756-1ea9-42c7-862b-0365dd9852e3',  -- its_system_innovators
   '4a5f6e5c-c20c-4180-83b9-784045667e1e'),  -- sp_inovah

  -- Harris → Cayenta
  (gen_random_uuid(),
   'cd4702cf-de59-4fc4-a073-a8311be841c8',  -- its_harris
   '963de413-4b35-4c0f-b0e0-81129938e292'),  -- sp_cayenta

  -- Integraph → Hexagon
  (gen_random_uuid(),
   '9ea120b7-153c-43d1-a3e6-a8a470b9b57d',  -- its_integraph
   '313c644d-590b-4dd3-ab5c-589bf5fc0a83'),  -- sp_hexagon

  -- Databank OnBase → OnBase
  (gen_random_uuid(),
   'f5aa0a1e-7fd0-4596-9438-fa540f14e330',  -- its_databank_onbase
   'c5b969bb-cfb3-4ebb-943c-a98289440168'),  -- sp_onbase

  -- Precision Task Group → Workday
  (gen_random_uuid(),
   '128fc24b-15a4-41ac-873b-3e7ec39e3d9e',  -- its_precision
   'a5195986-9783-4ebf-b9b8-fcba282f7153');  -- sp_workday

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------

SELECT count(*) AS it_service_software_product_count
FROM it_service_software_products issp
JOIN it_services its ON its.id = issp.it_service_id
WHERE its.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';
-- Expected: 6

COMMIT;
