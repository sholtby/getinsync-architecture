-- =============================================================================
-- Script 01: Namespace & Workspaces
-- Records: 4 workspaces, 4 workspace_users
-- Source: garland-showcase-demo-plan.md Phase 1
-- Purpose: Delete existing stale workspace data and create the 4 showcase workspaces
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 1. Cleanup: Remove stale data
--    Cascade deletes fire audit triggers that try to INSERT audit_logs with
--    the workspace_id being deleted → FK violation. Disable ALL user triggers
--    during cleanup, then re-enable.
-- -------------------------------------------------------------------------

-- Disable all user triggers to prevent audit_log FK violations during cascade
SET session_replication_role = 'replica';

DELETE FROM audit_logs
WHERE workspace_id IN (
  SELECT id FROM workspaces
  WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
);

DELETE FROM contacts
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';

DELETE FROM organizations
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';

DELETE FROM workspaces
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523';

-- Re-enable all triggers
SET session_replication_role = 'origin';

-- -------------------------------------------------------------------------
-- 2. Insert 4 workspaces
-- -------------------------------------------------------------------------

INSERT INTO workspaces (id, namespace_id, name, slug) VALUES
  ('6ef929d4-8505-43a3-b9ba-2e25c326dbca', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'Customer Service & Utilities', 'customer-service-utilities'),
  ('7240552a-0c39-4898-a4d7-32af799e46b3', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'Finance & Budget', 'finance-budget'),
  ('effe3eb0-93fb-49fa-a478-9140e2c194b7', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'Police', 'police'),
  ('1219e4bf-9ae5-4f92-b46f-782bc71f379e', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523', 'Information Technology', 'information-technology');

-- -------------------------------------------------------------------------
-- 3. Insert 4 workspace_users (admin role for namespace user)
-- -------------------------------------------------------------------------

INSERT INTO workspace_users (workspace_id, user_id, role) VALUES
  ('6ef929d4-8505-43a3-b9ba-2e25c326dbca', 'f4bd97ab-3b86-4e65-a3ce-5cf6b39d7803', 'admin'),
  ('7240552a-0c39-4898-a4d7-32af799e46b3', 'f4bd97ab-3b86-4e65-a3ce-5cf6b39d7803', 'admin'),
  ('effe3eb0-93fb-49fa-a478-9140e2c194b7', 'f4bd97ab-3b86-4e65-a3ce-5cf6b39d7803', 'admin'),
  ('1219e4bf-9ae5-4f92-b46f-782bc71f379e', 'f4bd97ab-3b86-4e65-a3ce-5cf6b39d7803', 'admin');

COMMIT;

-- -------------------------------------------------------------------------
-- Validation
-- -------------------------------------------------------------------------

SELECT name
FROM workspaces
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY name;
