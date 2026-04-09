-- ============================================================================
-- Script 17: Application Contacts
-- Records: 28 (after deduplication)
-- Source: ApplicationContacts.json
-- Purpose: Link contacts to their assigned applications
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Application Contacts (28 records)
--
-- role_type: 'technical_owner' for all (OG data does not differentiate)
-- is_primary: true for first contact per app, false for additional contacts
-- --------------------------------------------------------------------------

INSERT INTO application_contacts
  (id, application_id, contact_id, role_type, is_primary)
VALUES
  -- app_arcgis — GIS Services
  (gen_random_uuid(),
   '834398a6-ad10-433a-96ab-eae000c666a0',  -- app_arcgis
   'f36ce78f-c5ad-48a7-8865-6400071fb741',  -- ct_gis_svc
   'technical_owner', true),

  -- app_caseware — Allyson BellSteadman
  (gen_random_uuid(),
   '5f0a1732-9373-414a-b580-fac581972d43',  -- app_caseware
   '49766cfb-967f-49ee-ae7d-8e693ca8539e',  -- ct_allyson
   'technical_owner', true),

  -- app_infinity_cis — Mandy Harrell (primary)
  (gen_random_uuid(),
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '6a1b5f45-3c70-43d0-9172-3c74491cbda7',  -- ct_mandy_harrell
   'technical_owner', true),

  -- app_infinity_cis — Enterprise Services
  (gen_random_uuid(),
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', false),

  -- app_infinity_cis — Andrea Williams
  (gen_random_uuid(),
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '25e4eb5d-8fd6-4da7-9726-db47995f7d5e',  -- ct_andrea_williams
   'technical_owner', false),

  -- app_questica — Allyson BellSteadman
  (gen_random_uuid(),
   '1663a230-bc33-4e98-ae11-71df77aeea2e',  -- app_questica
   '49766cfb-967f-49ee-ae7d-8e693ca8539e',  -- ct_allyson
   'technical_owner', true),

  -- app_onbase — Enterprise Services
  (gen_random_uuid(),
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_fcs_itron — Enterprise Services (primary)
  (gen_random_uuid(),
   '839ed0f0-4a93-47bb-a932-6e20ed238455',  -- app_fcs_itron
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_fcs_itron — Andrea Williams
  (gen_random_uuid(),
   '839ed0f0-4a93-47bb-a932-6e20ed238455',  -- app_fcs_itron
   '25e4eb5d-8fd6-4da7-9726-db47995f7d5e',  -- ct_andrea_williams
   'technical_owner', false),

  -- app_inovah — Enterprise Services (primary)
  (gen_random_uuid(),
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_inovah — Andrea Williams
  (gen_random_uuid(),
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '25e4eb5d-8fd6-4da7-9726-db47995f7d5e',  -- ct_andrea_williams
   'technical_owner', false),

  -- app_courts_plus — Enterprise Services
  (gen_random_uuid(),
   'd58cf0bf-8016-4ab8-a054-28fbdbe747e1',  -- app_courts_plus
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_crm — Enterprise Services
  (gen_random_uuid(),
   '4d1d564f-8f0c-4329-8566-086bf09ea1f8',  -- app_crm
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_proqa — Gary Cummings
  (gen_random_uuid(),
   'a7055029-f856-4bae-a377-9da52d173cfd',  -- app_proqa
   '6c3d5007-f33f-499b-adc6-ae6793b09b6b',  -- ct_gary_cummings
   'technical_owner', true),

  -- app_service_link — Enterprise Services
  (gen_random_uuid(),
   '79b5afd9-7335-4c9c-ab99-fdff74dc1a7a',  -- app_service_link
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_workday — Enterprise Services
  (gen_random_uuid(),
   'ef6b4c4b-0312-4fe4-8fc2-fa5263dcc98a',  -- app_workday
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_cayenta — Enterprise Services
  (gen_random_uuid(),
   '86bf1db4-42e9-47ef-8352-bc43ce97f516',  -- app_cayenta
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_eticket — Gary Cummings
  (gen_random_uuid(),
   '34876796-d6e9-4f93-9dff-88fb030ec5b5',  -- app_eticket
   '6c3d5007-f33f-499b-adc6-ae6793b09b6b',  -- ct_gary_cummings
   'technical_owner', true),

  -- app_hexagon — Gary Cummings
  (gen_random_uuid(),
   'f46c922a-e7b0-49bd-a856-7b8fd53c68e8',  -- app_hexagon
   '6c3d5007-f33f-499b-adc6-ae6793b09b6b',  -- ct_gary_cummings
   'technical_owner', true),

  -- app_nintex — Application Solution Services
  (gen_random_uuid(),
   '3ca20ec2-3b1b-4cee-984d-276270b85b98',  -- app_nintex
   'dfcfa36e-e138-49b9-9722-22c70a17b96f',  -- ct_app_solution_svc
   'technical_owner', true),

  -- app_bill_image — Application Solution Services
  (gen_random_uuid(),
   '65d84b68-55c4-4054-8150-9c3e8579e990',  -- app_bill_image
   'dfcfa36e-e138-49b9-9722-22c70a17b96f',  -- ct_app_solution_svc
   'technical_owner', true),

  -- app_mam_file — Application Solution Services
  (gen_random_uuid(),
   '42e8273c-ec08-4fe2-b485-44ee90620ab0',  -- app_mam_file
   'dfcfa36e-e138-49b9-9722-22c70a17b96f',  -- ct_app_solution_svc
   'technical_owner', true),

  -- app_aperta — Enterprise Services (primary)
  (gen_random_uuid(),
   '49c6f40f-8398-4f7c-9ac1-69352584aa89',  -- app_aperta
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true),

  -- app_aperta — Andrea Williams
  (gen_random_uuid(),
   '49c6f40f-8398-4f7c-9ac1-69352584aa89',  -- app_aperta
   '25e4eb5d-8fd6-4da7-9726-db47995f7d5e',  -- ct_andrea_williams
   'technical_owner', false),

  -- app_selectron — Infrastructure Services
  (gen_random_uuid(),
   '632c606f-1904-4110-91b2-dc9b3427c08e',  -- app_selectron
   '8a7d8985-8900-4c9a-a56e-f765005f693e',  -- ct_infra_svc
   'technical_owner', true),

  -- app_genetec — Enterprise Services
  (gen_random_uuid(),
   '10d2d61f-7e1a-44f3-bd2a-3b939118666a',  -- app_genetec
   '8ee50c98-541c-41c9-acd0-aa35e6f525ff',  -- ct_enterprise_svc
   'technical_owner', true);

COMMIT;

-- ============================================================================
-- Validation
-- ============================================================================

SELECT
  a.name   AS application,
  c.display_name AS contact,
  ac.role_type,
  ac.is_primary
FROM application_contacts ac
JOIN applications a ON a.id = ac.application_id
JOIN contacts c     ON c.id = ac.contact_id
JOIN workspaces w   ON w.id = a.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY a.name, ac.is_primary DESC, c.display_name;
