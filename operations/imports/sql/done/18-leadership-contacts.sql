-- ============================================================================
-- Script 18: Leadership Contacts (Workspace & Portfolio)
-- Records: 5 workspace_contacts + 3 portfolio_contacts
-- Purpose: Assign leadership roles to workspace and portfolio contacts
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- 1. Workspace Contacts (5 records)
-- --------------------------------------------------------------------------

INSERT INTO workspace_contacts
  (id, workspace_id, contact_id, role_type, is_primary, notes)
VALUES
  -- Finance & Budget — Matt Watson (CFO) as leader
  (gen_random_uuid(),
   '7240552a-0c39-4898-a4d7-32af799e46b3',  -- ws_fb
   '32c5d023-1b5e-47ab-a9d4-433f9851af76',  -- ct_matt_watson
   'leader', true, NULL),

  -- Finance & Budget — Allyson BellSteadman as budget owner
  (gen_random_uuid(),
   '7240552a-0c39-4898-a4d7-32af799e46b3',  -- ws_fb
   '49766cfb-967f-49ee-ae7d-8e693ca8539e',  -- ct_allyson
   'budget_owner', true, NULL),

  -- Customer Service & Utilities — Kevin Slay as business owner
  (gen_random_uuid(),
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',  -- ws_csu
   '39749c0e-da95-471d-a7b6-93759e6890e0',  -- ct_kevin_slay
   'business_owner', true, NULL),

  -- Police Department — Jeff Bryan as leader
  (gen_random_uuid(),
   'effe3eb0-93fb-49fa-a478-9140e2c194b7',  -- ws_pol
   '3117a32d-db15-4ed0-b9dc-d137e6813c62',  -- ct_jeff_bryan
   'leader', true, NULL),

  -- Information Technology — Justin Fair as leader
  (gen_random_uuid(),
   '1219e4bf-9ae5-4f92-b46f-782bc71f379e',  -- ws_it
   '431784bd-62af-4fcc-ad1e-83d556b859c2',  -- ct_justin_fair
   'leader', true, NULL);

-- --------------------------------------------------------------------------
-- 2. Portfolio Contacts (3 records)
-- --------------------------------------------------------------------------

INSERT INTO portfolio_contacts
  (id, portfolio_id, contact_id, role_type, is_primary, notes)
VALUES
  -- Finance portfolio — Allyson BellSteadman as leader
  (gen_random_uuid(),
   '807efa6b-8b64-4888-aa88-603e4f1d5d5e',  -- port_fb_finance
   '49766cfb-967f-49ee-ae7d-8e693ca8539e',  -- ct_allyson
   'leader', true, NULL),

  -- Budget & Research portfolio — Allyson BellSteadman as leader
  (gen_random_uuid(),
   'a5496c85-2686-4293-a70f-e94fe5797b83',  -- port_fb_budget
   '49766cfb-967f-49ee-ae7d-8e693ca8539e',  -- ct_allyson
   'leader', true, NULL),

  -- Utility CIS & Revenue portfolio — Kevin Slay as leader
  (gen_random_uuid(),
   '7d93c668-ceb8-4cae-84fa-5e253c69014b',  -- port_csu_utility
   '39749c0e-da95-471d-a7b6-93759e6890e0',  -- ct_kevin_slay
   'leader', true, NULL);

COMMIT;

-- ============================================================================
-- Validation — Workspace Contacts
-- ============================================================================

SELECT
  w.name   AS workspace,
  c.display_name AS contact,
  wc.role_type,
  wc.is_primary
FROM workspace_contacts wc
JOIN workspaces w ON w.id = wc.workspace_id
JOIN contacts c   ON c.id = wc.contact_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY w.name, wc.role_type;

-- ============================================================================
-- Validation — Portfolio Contacts
-- ============================================================================

SELECT
  p.name   AS portfolio,
  c.display_name AS contact,
  pc.role_type,
  pc.is_primary
FROM portfolio_contacts pc
JOIN portfolios p ON p.id = pc.portfolio_id
JOIN contacts c   ON c.id = pc.contact_id
WHERE p.workspace_id IN (
  SELECT id FROM workspaces
  WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
)
ORDER BY p.name, pc.role_type;
