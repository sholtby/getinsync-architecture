-- ============================================================================
-- Script 05: Contacts
-- Records: 13
-- Source: Contacts.json, garland-showcase-demo-plan.md Phase 10
-- Purpose: Create contact records for application owners and leadership
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Contacts (13 records)
-- --------------------------------------------------------------------------

INSERT INTO contacts (id, namespace_id, primary_workspace_id, display_name, job_title, department, email, phone, workspace_role, contact_category, is_active)
VALUES
  ('8ee50c98-541c-41c9-acd0-aa35e6f525ff', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Enterprise Services', 'IT Team', NULL, NULL, NULL, 'read_only', 'internal', true),  -- OG ID: 3fccd1ed

  ('dfcfa36e-e138-49b9-9722-22c70a17b96f', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Application Solution Services', 'IT Team', NULL, NULL, NULL, 'read_only', 'internal', true),  -- OG ID: e7eca670

  ('8a7d8985-8900-4c9a-a56e-f765005f693e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Infrastructure Services', 'IT Team', NULL, NULL, NULL, 'read_only', 'internal', true),  -- OG ID: 6f5e61a8

  ('f36ce78f-c5ad-48a7-8865-6400071fb741', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'GIS Services', 'IT Team', NULL, NULL, NULL, 'read_only', 'internal', true),  -- OG ID: 615a34d8

  ('6a1b5f45-3c70-43d0-9172-3c74491cbda7', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Mandy Harrell', NULL, NULL, 'Mharrell@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: e605cbdc

  ('6c3d5007-f33f-499b-adc6-ae6793b09b6b', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Gary Cummings', NULL, NULL, 'cummingsg@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: 46709e6f

  ('49766cfb-967f-49ee-ae7d-8e693ca8539e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Allyson BellSteadman', 'Director', NULL, 'abellsteadman@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: edfbf855

  ('25e4eb5d-8fd6-4da7-9726-db47995f7d5e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Andrea Williams', NULL, NULL, NULL, NULL, 'read_only', 'internal', true),  -- OG ID: (found in data)

  ('32c5d023-1b5e-47ab-a9d4-433f9851af76', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Matt Watson', 'Chief Financial Officer', NULL, 'mwatson@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: 807264dd

  ('d31d9411-130d-491a-95b5-37ec72094418', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Phillip Urrutia', 'Assistant City Manager', NULL, 'purrtia@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: 6de1b514

  ('39749c0e-da95-471d-a7b6-93759e6890e0', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Kevin Slay', 'Managing Director', NULL, 'kslay@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: ed98f724

  ('3117a32d-db15-4ed0-b9dc-d137e6813c62', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'effe3eb0-93fb-49fa-a478-9140e2c194b7',
   'Jeff Bryan', 'Police Chief', NULL, 'bryanj@garlandtx.gov', NULL, 'read_only', 'internal', true),  -- OG ID: 03dd1ff5

  ('431784bd-62af-4fcc-ad1e-83d556b859c2', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',
   'Justin Fair', 'Chief Information Officer', NULL, 'jfair@garlandtx.gov', NULL, 'read_only', 'internal', true);  -- OG ID: d088644c

COMMIT;

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------
SELECT display_name, job_title, email
FROM contacts
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY display_name;
