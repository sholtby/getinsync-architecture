-- Chunk: 00-verify-baseline.sql
-- Purpose: Confirm starting state BEFORE any enrichment chunks run.
-- Read-only — no BEGIN/COMMIT, no writes.
-- Expected output (single row, jsonb):
--   total_apps          = 32
--   apps_with_categories = 0
--   total_assignments   = 0
--   active_categories   = 14
-- If anything differs, STOP and reconcile with Stuart before running 01..05.

\pset pager off

WITH counts AS (
  SELECT
    (SELECT COUNT(*)
       FROM applications a
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_apps,
    (SELECT COUNT(DISTINCT aca.application_id)
       FROM application_category_assignments aca
       JOIN applications a ON a.id = aca.application_id
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS apps_with_categories,
    (SELECT COUNT(*)
       FROM application_category_assignments aca
       JOIN applications a ON a.id = aca.application_id
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_assignments,
    (SELECT COUNT(*)
       FROM application_categories
      WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
        AND is_active = true) AS active_categories
)
SELECT
  1 AS ord,
  'baseline' AS section,
  jsonb_build_object(
    'total_apps',           total_apps,
    'apps_with_categories', apps_with_categories,
    'total_assignments',    total_assignments,
    'active_categories',    active_categories
  ) AS details
FROM counts;
