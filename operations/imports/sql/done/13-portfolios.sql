-- ============================================================================
-- Script 13: Portfolios
-- Records: 4 updates + 3 inserts = 7 portfolios
-- Purpose: Rename auto-generated default portfolios and add child portfolios
-- Note: Workspace creation trigger auto-creates a "Core" default portfolio
--       per workspace. We rename those and update their IDs to match our
--       pre-generated UUIDs so downstream scripts (14, 18) can reference them.
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- 1. Update auto-generated "Core" default portfolios — rename and re-ID
--    to match our pre-generated UUIDs for downstream FK consistency.
-- --------------------------------------------------------------------------

-- CSU root
UPDATE portfolios
SET id = 'e738fc1b-c7be-4482-ad0e-8106beddfb40',
    name = 'Customer Service & Utilities'
WHERE id = 'a89951c7-9af0-476d-9800-2493af985ec1';

-- FB root
UPDATE portfolios
SET id = '9582c5bf-31fc-4cce-995b-c15f490a7b41',
    name = 'Finance & Budget'
WHERE id = '06b62eab-a4d2-4940-b4f6-3e89c17587eb';

-- Police root
UPDATE portfolios
SET id = 'c8deafa8-b407-4304-a374-636f78562410',
    name = 'Police Department'
WHERE id = '8744c4c1-a05e-431d-8ba5-31fe17b19749';

-- IT root
UPDATE portfolios
SET id = '34f79c22-d56d-425c-bf84-bebf8bb9f3b3',
    name = 'Information Technology'
WHERE id = 'f6aa9180-587b-45c8-9de0-0de7c319b00b';

-- --------------------------------------------------------------------------
-- 2. Remove default flag on CSU and FB roots so they can accept children.
--    The child portfolios will serve as the assignment targets instead.
-- --------------------------------------------------------------------------

UPDATE portfolios SET is_default = false
WHERE id IN (
  'e738fc1b-c7be-4482-ad0e-8106beddfb40',  -- CSU root
  '9582c5bf-31fc-4cce-995b-c15f490a7b41'   -- FB root
);

-- --------------------------------------------------------------------------
-- 3. Child portfolios (3 records — under CSU and FB roots)
-- --------------------------------------------------------------------------

INSERT INTO portfolios
  (id, workspace_id, name, description, is_default, parent_portfolio_id)
VALUES
  -- Utility CIS & Revenue — child of CSU root
  ('7d93c668-ceb8-4cae-84fa-5e253c69014b',
   '6ef929d4-8505-43a3-b9ba-2e25c326dbca',
   'Utility CIS & Revenue',
   NULL,
   false,
   'e738fc1b-c7be-4482-ad0e-8106beddfb40'),

  -- Finance — child of FB root
  ('807efa6b-8b64-4888-aa88-603e4f1d5d5e',
   '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Finance',
   NULL,
   false,
   '9582c5bf-31fc-4cce-995b-c15f490a7b41'),

  -- Budget & Research — child of FB root
  ('a5496c85-2686-4293-a70f-e94fe5797b83',
   '7240552a-0c39-4898-a4d7-32af799e46b3',
   'Budget & Research',
   NULL,
   false,
   '9582c5bf-31fc-4cce-995b-c15f490a7b41');

COMMIT;

-- ============================================================================
-- Validation
-- ============================================================================

SELECT
  p.name,
  w.name AS workspace,
  p.is_default,
  p.parent_portfolio_id IS NOT NULL AS has_parent
FROM portfolios p
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY w.name, p.name;
