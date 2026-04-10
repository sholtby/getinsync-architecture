-- Chunk: 05-deployment-profile-ops-fields.sql
-- OPTIONAL — only run if Stuart wants the 1.4 Deployment Profiles article
-- to showcase on-prem operational depth (data_center, server_name, team IDs).
--
-- Purpose: Article 1.4 (Deployment Profiles) — populate operational fields
--          on one on-prem PROD DP so the article can screenshot a filled-in
--          example rather than the SaaS-only Accela case.
-- Preconditions:
--   - Tables touched: deployment_profiles (UPDATE only)
--   - data_centers lookup: Riverside has exactly one data center today:
--     "City Hall Data Center" (fb337a78-b1ec-4227-9404-56a52ce3ff72).
--   - teams lookup: Riverside has exactly one team today ("Test Team",
--     05a6630d-842b-43fb-ad8a-7d3e7c362f8c). Not a realistic team name for
--     a screenshot, so support_team_id / change_team_id / managing_team_id
--     are LEFT NULL here — see NOTE below. Article 1.4 can still showcase
--     data_center_id + server_name, which is the main visible change.
--   - Idempotent via WHERE ... IS NULL guards. Safe to re-run.
-- Namespace scope: target DP belongs to Computer-Aided Dispatch (Riverside).

BEGIN;

-- Target: Computer-Aided Dispatch - PROD - CHDC  (b5000006-...)
-- Currently: On-Prem, PROD, data_center_id NULL, server_name NULL, all team FKs NULL.
UPDATE deployment_profiles
SET
  data_center_id = COALESCE(data_center_id, 'fb337a78-b1ec-4227-9404-56a52ce3ff72'),
  server_name    = COALESCE(server_name, 'riv-cad-prod-01'),
  updated_at     = now()
WHERE id = 'b5000006-0000-0000-0000-000000000006';

-- NOTE: support_team_id / change_team_id / managing_team_id intentionally
-- left NULL. The only team in Riverside today is "Test Team", which would
-- read poorly in an article screenshot. Seed realistic teams first, then
-- re-run this chunk to attach them.

-- Verification: show the target DP's populated ops fields.
SELECT
  dp.id,
  dp.name,
  dp.hosting_type,
  dp.environment,
  dc.name AS data_center_name,
  dp.server_name,
  dp.support_team_id,
  dp.change_team_id,
  dp.managing_team_id
FROM deployment_profiles dp
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
WHERE dp.id = 'b5000006-0000-0000-0000-000000000006';

COMMIT;

-- Rollback: UPDATE deployment_profiles SET data_center_id = NULL, server_name = NULL WHERE id = 'b5000006-0000-0000-0000-000000000006';
