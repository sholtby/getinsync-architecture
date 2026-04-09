-- ============================================================================
-- Script 14: Portfolio Assignments with B-Scores
-- Records: 21
-- Purpose: Assign apps/DPs to portfolios and populate B1-B10 business scores
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Customer Service & Utilities — Utility CIS & Revenue (6 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_assignments
  (id, portfolio_id, application_id, deployment_profile_id,
   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10,
   business_assessment_status, relationship_type)
VALUES
  -- Infinity CIS → port_csu_utility (scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '65cd4b69-33f2-480a-b26b-2926c3c2b881',  -- app_infinity_cis
   '3fe2a39a-28bb-4cf5-badd-320cec96bfb2',  -- dp_infinity_cis
   5, 2, 2, 4, 5, 5, 4, 4, 3, 3,
   'in_progress', 'publisher'),

  -- Inovah → port_csu_utility (scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   'd6e3197f-915b-4c31-b73f-8c723f7fcf17',  -- app_inovah
   '02136b36-f9ac-4fee-8122-0746423bc28e',  -- dp_inovah
   4, 2, NULL, 2, 5, 5, 3, 5, 5, 4,
   'in_progress', 'publisher'),

  -- FCS - Itron → port_csu_utility (not scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '839ed0f0-4a93-47bb-a932-6e20ed238455',  -- app_fcs_itron
   '7f5c9a62-0db2-4752-a803-666b3eca7be2',  -- dp_fcs_itron
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- Service Link → port_csu_utility (not scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '79b5afd9-7335-4c9c-ab99-fdff74dc1a7a',  -- app_service_link
   '318f7068-6db1-40de-ba88-60d508e7bd7a',  -- dp_service_link
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- Bill Image Files → port_csu_utility (not scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '65d84b68-55c4-4054-8150-9c3e8579e990',  -- app_bill_image
   '3fde389f-b704-452d-ba88-37e5b9305fea',  -- dp_bill_image
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- MAM File → port_csu_utility (not scored)
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '42e8273c-ec08-4fe2-b485-44ee90620ab0',  -- app_mam_file
   '88ad89b0-7887-4156-b3be-d5a5ada91597',  -- dp_mam_file
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher');

-- --------------------------------------------------------------------------
-- Customer Service & Utilities — CSU Root (2 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_assignments
  (id, portfolio_id, application_id, deployment_profile_id,
   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10,
   business_assessment_status, relationship_type)
VALUES
  -- Selectron IVR → port_csu_general (scored)
  (gen_random_uuid(),
   'b1a2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',  -- port_csu_general
   '632c606f-1904-4110-91b2-dc9b3427c08e',  -- app_selectron
   '5668512a-7405-4a29-99de-bd07552ff23f',  -- dp_selectron
   4, 5, 1, 4, 4, 4, 3, 5, 5, 4,
   'in_progress', 'publisher'),

  -- Aperta → port_csu_general (scored)
  (gen_random_uuid(),
   'b1a2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',  -- port_csu_general
   '49c6f40f-8398-4f7c-9ac1-69352584aa89',  -- app_aperta
   '8cc68b80-18b0-4e82-8927-ad399c2edbc6',  -- dp_aperta
   3, 2, 2, 2, 5, 5, 3, 4, 5, 4,
   'in_progress', 'publisher');

-- --------------------------------------------------------------------------
-- Finance & Budget (4 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_assignments
  (id, portfolio_id, application_id, deployment_profile_id,
   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10,
   business_assessment_status, relationship_type)
VALUES
  -- Cayenta (Finance) → port_fb_finance (scored)
  (gen_random_uuid(),
   '807efa6b-8b64-4888-aa88-603e4f1d5d5e',  -- port_fb_finance
   '86bf1db4-42e9-47ef-8352-bc43ce97f516',  -- app_cayenta
   'd63a3f92-e52a-4485-8960-f8a75a9d0886',  -- dp_cayenta
   3, 2, 1, 5, 5, 5, 5, 4, 2, 3,
   'in_progress', 'publisher'),

  -- Questica → port_fb_budget (scored)
  (gen_random_uuid(),
   'a5496c85-2686-4293-a70f-e94fe5797b83',  -- port_fb_budget
   '1663a230-bc33-4e98-ae11-71df77aeea2e',  -- app_questica
   '7bc0971b-1152-4d21-bc59-48db4b7fd348',  -- dp_questica
   4, 2, 1, 4, 5, 5, 5, 5, 5, 5,
   'in_progress', 'publisher'),

  -- Caseware → port_fb_budget (scored)
  (gen_random_uuid(),
   'a5496c85-2686-4293-a70f-e94fe5797b83',  -- port_fb_budget
   '5f0a1732-9373-414a-b580-fac581972d43',  -- app_caseware
   '33f3e9eb-3a91-4092-b8d0-e7a742fc7469',  -- dp_caseware
   4, 2, 1, 4, 5, 4, 4, 4, 5, 4,
   'in_progress', 'publisher'),

  -- Courts Plus → port_fb_general (not scored)
  (gen_random_uuid(),
   'c2b3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',  -- port_fb_general
   'd58cf0bf-8016-4ab8-a054-28fbdbe747e1',  -- app_courts_plus
   '9abb5a77-40a9-4138-8218-988948bc2a1e',  -- dp_courts_plus
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher');

-- --------------------------------------------------------------------------
-- Police Department (3 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_assignments
  (id, portfolio_id, application_id, deployment_profile_id,
   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10,
   business_assessment_status, relationship_type)
VALUES
  -- Hexagon OnCall → port_pol_root (scored)
  (gen_random_uuid(),
   'c8deafa8-b407-4304-a374-636f78562410',  -- port_pol_root
   'f46c922a-e7b0-49bd-a856-7b8fd53c68e8',  -- app_hexagon
   '51ef02de-1627-4674-8f2c-551e15f363a3',  -- dp_hexagon
   3, 2, 1, 2, 5, 5, 2, 4, 5, 4,
   'in_progress', 'publisher'),

  -- Eticket Citation Writer → port_pol_root (scored)
  (gen_random_uuid(),
   'c8deafa8-b407-4304-a374-636f78562410',  -- port_pol_root
   '34876796-d6e9-4f93-9dff-88fb030ec5b5',  -- app_eticket
   '1f8db15b-425c-4dd6-b6f0-94c8413ec395',  -- dp_eticket
   4, 2, 1, 1, 3, 3, 3, 5, 5, 4,
   'in_progress', 'publisher'),

  -- ProQa & Aqua → port_pol_root (scored)
  (gen_random_uuid(),
   'c8deafa8-b407-4304-a374-636f78562410',  -- port_pol_root
   'a7055029-f856-4bae-a377-9da52d173cfd',  -- app_proqa
   '4c3fda02-694d-4b4c-857a-2b30b04c7f1e',  -- dp_proqa
   3, 2, 1, 2, 5, 5, 2, 5, 5, 4,
   'in_progress', 'publisher');

-- --------------------------------------------------------------------------
-- Information Technology (6 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_assignments
  (id, portfolio_id, application_id, deployment_profile_id,
   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10,
   business_assessment_status, relationship_type)
VALUES
  -- OnBase → port_it_root (scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   '6244a5b8-5581-44ff-be67-48332102fc07',  -- app_onbase
   '3d43d741-7d1b-47d5-b72d-7b99d8dbf218',  -- dp_onbase
   4, 5, 1, 4, 5, 5, 1, 4, 5, 4,
   'in_progress', 'publisher'),

  -- Workday → port_it_root (not scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   'ef6b4c4b-0312-4fe4-8fc2-fa5263dcc98a',  -- app_workday
   '58e64b12-4ffa-414c-932b-1438b3ad0855',  -- dp_workday
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- Genetec Video → port_it_root (scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   '10d2d61f-7e1a-44f3-bd2a-3b939118666a',  -- app_genetec
   '62090be1-26a6-4659-a319-56527e0fb67a',  -- dp_genetec
   3, 5, 1, 4, 5, 5, 1, 4, 5, 5,
   'in_progress', 'publisher'),

  -- CRM (2016) → port_it_root (not scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   '4d1d564f-8f0c-4329-8566-086bf09ea1f8',  -- app_crm
   'f62dd081-3f3b-4d41-8df9-fef3eae2a421',  -- dp_crm
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- Nintex Sharepoint → port_it_root (not scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   '3ca20ec2-3b1b-4cee-984d-276270b85b98',  -- app_nintex
   '744d890d-b49b-4b99-9c6c-9bb24f48116c',  -- dp_nintex
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher'),

  -- ArcGIS - ESRI → port_it_root (not scored)
  (gen_random_uuid(),
   '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',  -- port_it_root
   '834398a6-ad10-433a-96ab-eae000c666a0',  -- app_arcgis
   '82b64ecb-dc7e-4586-8771-bca32d3592c9',  -- dp_arcgis
   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   'Not Started', 'publisher');

COMMIT;

-- ============================================================================
-- Validation
-- ============================================================================

SELECT
  pa.business_assessment_status,
  COUNT(*) AS assignment_count,
  COUNT(pa.b1) AS scored_count
FROM portfolio_assignments pa
JOIN portfolios p ON p.id = pa.portfolio_id
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
GROUP BY pa.business_assessment_status
ORDER BY pa.business_assessment_status;

SELECT
  p.name AS portfolio,
  a.name AS application,
  pa.b1, pa.b2, pa.b3, pa.b4, pa.b5, pa.b6, pa.b7, pa.b8, pa.b9, pa.b10,
  pa.business_assessment_status
FROM portfolio_assignments pa
JOIN portfolios p ON p.id = pa.portfolio_id
JOIN applications a ON a.id = pa.application_id
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY p.name, a.name;
