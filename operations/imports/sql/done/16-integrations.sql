-- ============================================================================
-- Script 16: Application Integrations
-- Records: 16 (both ends in showcase) + 10 skipped partial integrations
-- Source: ApplicationIntegrations.json
-- Purpose: Create integration links between showcase apps
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Application Integrations (16 records — both ends in showcase)
--
-- Direction mapping from OG data:
--   OG "Publish"   → 'downstream'  (source pushes to target)
--   OG "Subscribe"  → 'upstream'    (source pulls from target)
--   OG blank        → 'bidirectional'
--
-- NOTE: 10 partial integrations (one end outside showcase) are skipped.
-- These involve external systems: Cityworks (f0251f99), 3462f815,
-- 3839759a, 13a2a29d, fbc6aa14, dfb5fa97.
-- They can be added later via the application_integrations.external_system_name
-- column once the external app catalog is populated.
-- --------------------------------------------------------------------------

INSERT INTO application_integrations
  (id, source_application_id, target_application_id,
   source_deployment_profile_id, target_deployment_profile_id,
   external_system_name, direction, status)
VALUES
  -- service_link → infinity_cis (Publish → downstream)
  (gen_random_uuid(),
   '79b5afd9-7335-4c9c-ab99-fdff74dc1a7a',  -- app_service_link
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '318f7068-6db1-40de-ba88-60d508e7bd7a',  -- dp_service_link
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'downstream', 'active'),

  -- fcs_itron → infinity_cis (Subscribe → upstream)
  (gen_random_uuid(),
   '839ed0f0-4a93-47bb-a932-6e20ed238455',  -- app_fcs_itron
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '7f5c9a62-0db2-4752-a803-666b3eca7be2',  -- dp_fcs_itron
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'upstream', 'active'),

  -- fcs_itron → infinity_cis (Publish → downstream)
  (gen_random_uuid(),
   '839ed0f0-4a93-47bb-a932-6e20ed238455',  -- app_fcs_itron
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '7f5c9a62-0db2-4752-a803-666b3eca7be2',  -- dp_fcs_itron
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'downstream', 'active'),

  -- inovah → infinity_cis (Subscribe → upstream)
  (gen_random_uuid(),
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'upstream', 'active'),

  -- selectron → crm (Publish → downstream)
  (gen_random_uuid(),
   '632c606f-1904-4110-91b2-dc9b3427c08e',  -- app_selectron
   '4d1d564f-8f0c-4329-8566-086bf09ea1f8',  -- app_crm
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   'f62dd081-3f3b-4d41-8df9-fef3eae2a421',  -- dp_crm
   NULL, 'downstream', 'active'),

  -- selectron → infinity_cis (Publish → downstream)
  (gen_random_uuid(),
   '632c606f-1904-4110-91b2-dc9b3427c08e',  -- app_selectron
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'downstream', 'active'),

  -- courts_plus → eticket (Subscribe → upstream)
  (gen_random_uuid(),
   'd58cf0bf-8016-4ab8-a054-28fbdbe747e1',  -- app_courts_plus
   '34876796-d6e9-4f93-9dff-88fb030ec5b5',  -- app_eticket
   '9abb5a77-40a9-4138-8218-988948bc2a1e',  -- dp_courts_plus
   '1f8db15b-425c-4dd6-b6f0-94c8413ec395',  -- dp_eticket
   NULL, 'upstream', 'active'),

  -- courts_plus → onbase (Subscribe → upstream)
  (gen_random_uuid(),
   'd58cf0bf-8016-4ab8-a054-28fbdbe747e1',  -- app_courts_plus
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   '9abb5a77-40a9-4138-8218-988948bc2a1e',  -- dp_courts_plus
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   NULL, 'upstream', 'active'),

  -- onbase → eticket (Subscribe → upstream)
  (gen_random_uuid(),
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   '34876796-d6e9-4f93-9dff-88fb030ec5b5',  -- app_eticket
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   '1f8db15b-425c-4dd6-b6f0-94c8413ec395',  -- dp_eticket
   NULL, 'upstream', 'active'),

  -- onbase → inovah (Subscribe → upstream)
  (gen_random_uuid(),
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   NULL, 'upstream', 'active'),

  -- onbase → cayenta (Subscribe → upstream)
  (gen_random_uuid(),
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   '86bf1db4-42e9-47ef-8352-bc43ce97f516',  -- app_cayenta
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   NULL, 'upstream', 'active'),

  -- caseware → questica (Subscribe → upstream)
  (gen_random_uuid(),
   '5f0a1732-9373-414a-b580-fac581972d43',  -- app_caseware
   '1663a230-bc33-4e98-ae11-71df77aeea2e',  -- app_questica
   '33f3e9eb-3a91-4092-b8d0-e7a742fc7469',  -- dp_caseware
   '7bc0971b-1152-4d21-bc59-48db4b7fd348',  -- dp_questica
   NULL, 'upstream', 'active'),

  -- bill_image → inovah (Subscribe → upstream)
  (gen_random_uuid(),
   '65d84b68-55c4-4054-8150-9c3e8579e990',  -- app_bill_image
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '3fde389f-b704-452d-ba88-37e5b9305fea',  -- dp_bill_image
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   NULL, 'upstream', 'active'),

  -- mam_file → infinity_cis (Subscribe → upstream)
  (gen_random_uuid(),
   '42e8273c-ec08-4fe2-b485-44ee90620ab0',  -- app_mam_file
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '88ad89b0-7887-4156-b3be-d5a5ada91597',  -- dp_mam_file
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   NULL, 'upstream', 'active'),

  -- genetec → workday (Publish → downstream)
  (gen_random_uuid(),
   '10d2d61f-7e1a-44f3-bd2a-3b939118666a',  -- app_genetec
   'ef6b4c4b-0312-4fe4-8fc2-fa5263dcc98a',  -- app_workday
   '62090be1-26a6-4659-a319-56527e0fb67a',  -- dp_genetec
   '58e64b12-4ffa-414c-932b-1438b3ad0855',  -- dp_workday
   NULL, 'downstream', 'active'),

  -- hexagon → hexagon (Publish → downstream, self-integration)
  (gen_random_uuid(),
   'f46c922a-e7b0-49bd-a856-7b8fd53c68e8',  -- app_hexagon
   'f46c922a-e7b0-49bd-a856-7b8fd53c68e8',  -- app_hexagon (self)
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon (self)
   NULL, 'downstream', 'active');

COMMIT;

-- ============================================================================
-- Validation
-- ============================================================================

SELECT
  sa.name  AS source_app,
  ta.name  AS target_app,
  ai.direction,
  ai.status
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
JOIN applications ta ON ta.id = ai.target_application_id
JOIN workspaces w ON w.id = sa.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY sa.name, ta.name;
