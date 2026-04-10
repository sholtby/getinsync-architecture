-- Chunk: 02-integrations-dp-alignment.sql
-- Purpose: Article 2.4 (Managing Integrations) — refresh showcases the
--          Phase-2 DP-aligned integrations feature. Today only 1 of 9
--          Riverside integrations has both DPs set, and that row has no
--          name. This chunk:
--            (a) Names the unnamed ServiceNow ITSM → Active Directory row.
--            (b) Sets source/target deployment profile FKs on two more
--                integrations (Emergency Response ↔ CAD, NG911 → CAD).
-- Preconditions:
--   - Tables touched: application_integrations (UPDATE only)
--   - Reference tables confirmed: direction/frequency/integration_type/
--     criticality/status values already pass existing check constraints.
--   - DP IDs used below are PROD primary DPs discovered by pre-audit.
--   - Idempotent via WHERE <col> IS NULL guards. Safe to re-run.
-- Namespace scope: all three integrations belong to Riverside apps.

BEGIN;

-- Task A: Name the unnamed ServiceNow ITSM → Active Directory integration.
-- Current state: id=128e700b-45d5-48c8-8fa4-df51405afaa8, name IS NULL,
-- both DPs already populated (source=ServiceNow ITSM — Region-PROD,
-- target=Active Directory Services - PROD - CHDC).
UPDATE application_integrations
SET
  name        = 'ServiceNow CMDB Sync',
  description = COALESCE(description, 'Daily sync of CMDB configuration items from ServiceNow ITSM into Active Directory for identity/device reconciliation.'),
  updated_at  = now()
WHERE id = '128e700b-45d5-48c8-8fa4-df51405afaa8'
  AND (name IS NULL OR name = '');

-- Task B1: DP-align Emergency Response ↔ CAD.
-- source=Emergency Response System - PROD - Hybrid (b5000013-...)
-- target=Computer-Aided Dispatch - PROD - CHDC       (b5000006-...)
UPDATE application_integrations
SET
  source_deployment_profile_id = 'b5000013-0000-0000-0000-000000000013',
  target_deployment_profile_id = 'b5000006-0000-0000-0000-000000000006',
  updated_at                   = now()
WHERE id = 'c1000006-0000-0000-0000-000000000006'
  AND source_deployment_profile_id IS NULL
  AND target_deployment_profile_id IS NULL;

-- Task B2: DP-align NG911 → CAD Call Routing.
-- source=NG911 System - PROD - Azure              (b5000007-...)
-- target=Computer-Aided Dispatch - PROD - CHDC    (b5000006-...)
UPDATE application_integrations
SET
  source_deployment_profile_id = 'b5000007-0000-0000-0000-000000000007',
  target_deployment_profile_id = 'b5000006-0000-0000-0000-000000000006',
  updated_at                   = now()
WHERE id = 'c1000007-0000-0000-0000-000000000007'
  AND source_deployment_profile_id IS NULL
  AND target_deployment_profile_id IS NULL;

-- Verification: show all Riverside integrations and which are DP-aligned.
SELECT
  ai.id,
  ai.name,
  sa.name AS source_app,
  ta.name AS target_app,
  (ai.source_deployment_profile_id IS NOT NULL
   AND ai.target_deployment_profile_id IS NOT NULL) AS dp_aligned,
  ai.integration_type,
  ai.direction,
  ai.status
FROM application_integrations ai
LEFT JOIN applications sa ON sa.id = ai.source_application_id
LEFT JOIN applications ta ON ta.id = ai.target_application_id
WHERE sa.workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
ORDER BY dp_aligned DESC, sa.name, ta.name;

SELECT
  count(*)                                                                 AS total,
  count(*) FILTER (WHERE source_deployment_profile_id IS NOT NULL
                    AND target_deployment_profile_id IS NOT NULL)          AS aligned_after
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
WHERE sa.workspace_id IN (
  SELECT id FROM workspaces WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
);

COMMIT;

-- Rollback: UPDATE application_integrations SET name = NULL, description = NULL WHERE id = '128e700b-45d5-48c8-8fa4-df51405afaa8'; UPDATE application_integrations SET source_deployment_profile_id = NULL, target_deployment_profile_id = NULL WHERE id IN ('c1000006-0000-0000-0000-000000000006','c1000007-0000-0000-0000-000000000007');
