-- ============================================================================
-- Script 11: DP → IT Service Allocation Links
-- Records: 8
-- Purpose: Link deployment profiles to IT services with fixed cost allocations
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Deployment Profile → IT Service allocations (8 records)
-- --------------------------------------------------------------------------

INSERT INTO deployment_profile_it_services
  (id, deployment_profile_id, it_service_id, relationship_type, allocation_basis, allocation_value, source)
VALUES
  -- dp_infinity_cis → AUS support ($512,996)
  (gen_random_uuid(),
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   '9e0473da-7249-421b-bddc-b3f148690af2',  -- its_aus
   'depends_on', 'fixed', 512996, 'manual'),

  -- dp_inovah → System Innovators ($84,123)
  (gen_random_uuid(),
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   '5b439756-1ea9-42c7-862b-0365dd9852e3',  -- its_system_innovators
   'depends_on', 'fixed', 84123, 'manual'),

  -- dp_selectron → Selectron IVR ($104,170)
  (gen_random_uuid(),
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   '404aab68-95f4-46ec-9c4b-25edd06765ea',  -- its_selectron
   'depends_on', 'fixed', 104170, 'manual'),

  -- dp_cayenta → Harris Cayenta ($351,901)
  (gen_random_uuid(),
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   'cd4702cf-de59-4fc4-a073-a8311be841c8',  -- its_harris
   'depends_on', 'fixed', 351901, 'manual'),

  -- dp_hexagon → Integraph Hexagon ($467,810)
  (gen_random_uuid(),
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon
   '9ea120b7-153c-43d1-a3e6-a8a470b9b57d',  -- its_integraph
   'depends_on', 'fixed', 467810, 'manual'),

  -- dp_onbase → Databank OnBase ($398,984)
  (gen_random_uuid(),
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   'f5aa0a1e-7fd0-4596-9438-fa540f14e330',  -- its_databank_onbase
   'depends_on', 'fixed', 398984, 'manual'),

  -- dp_nintex → Databank SharePoint ($112,150)
  (gen_random_uuid(),
   '744d890d-b49b-4b99-9c6c-9bb24f48116c',  -- dp_nintex
   'e2b35bf6-501b-4027-a3a7-e7d241406dc5',  -- its_databank_sp
   'depends_on', 'fixed', 112150, 'manual'),

  -- dp_workday → Precision Task Group ($1,299,416)
  (gen_random_uuid(),
   '58e64b12-4ffa-414c-932b-1438b3ad0855',  -- dp_workday
   '128fc24b-15a4-41ac-873b-3e7ec39e3d9e',  -- its_precision
   'depends_on', 'fixed', 1299416, 'manual');

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------

SELECT count(*) AS dp_it_service_count
FROM deployment_profile_it_services dpis
JOIN deployment_profiles dp ON dp.id = dpis.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';
-- Expected: 8

COMMIT;
