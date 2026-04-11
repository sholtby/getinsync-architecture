-- Chunk: 99-verify-final.sql
-- Purpose: Confirm final state AFTER all enrichment chunks (01..05) have run.
-- Read-only — no BEGIN/COMMIT, no writes.
--
-- Pass criteria (single consolidated result set, sections by `ord`):
--   ord=1 totals             total_apps = apps_with_categories = 32, total_assignments = 53
--   ord=2 unassigned_apps_count       count = 0  (no app left without a category)
--   ord=3 uncategorized_misuse_count  count = 0  (UNCATEGORIZED never used)
--   ord=4..N per_category    one row per category with app_count
--
-- Expected per-category app_counts (sum = 53, matches the proposed mapping):
--   FINANCE        5    HR             3    CRM           10    ERP            2
--   COLLABORATION  1    ANALYTICS      2    SECURITY       1    INFRASTRUCTURE 5
--   DEVELOPMENT    0    GIS_SPATIAL    3    RECORDS       11    LEGAL          7
--   HEALTH         3    UNCATEGORIZED  0
--
-- DEVELOPMENT and UNCATEGORIZED intentionally show 0.

\pset pager off

WITH ns AS (
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid AS id
),
totals AS (
  SELECT
    (SELECT COUNT(*)
       FROM applications a
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS total_apps,
    (SELECT COUNT(DISTINCT aca.application_id)
       FROM application_category_assignments aca
       JOIN applications a ON a.id = aca.application_id
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS apps_with_categories,
    (SELECT COUNT(*)
       FROM application_category_assignments aca
       JOIN applications a ON a.id = aca.application_id
       JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS total_assignments
),
unassigned AS (
  SELECT a.name
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  LEFT JOIN application_category_assignments aca ON aca.application_id = a.id
  WHERE w.namespace_id = (SELECT id FROM ns)
    AND aca.id IS NULL
),
uncategorized_misuse AS (
  SELECT a.name AS app_name
  FROM application_category_assignments aca
  JOIN applications a ON a.id = aca.application_id
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN application_categories ac ON ac.id = aca.category_id
  WHERE w.namespace_id = (SELECT id FROM ns)
    AND ac.code = 'UNCATEGORIZED'
),
per_category AS (
  SELECT
    ac.code,
    ac.name,
    ac.display_order,
    COUNT(aca.id) FILTER (
      WHERE aca.id IS NOT NULL
        AND w.namespace_id = (SELECT id FROM ns)
    ) AS app_count
  FROM application_categories ac
  LEFT JOIN application_category_assignments aca ON aca.category_id = ac.id
  LEFT JOIN applications a ON a.id = aca.application_id
  LEFT JOIN workspaces w ON w.id = a.workspace_id
  WHERE ac.namespace_id = (SELECT id FROM ns)
  GROUP BY ac.code, ac.name, ac.display_order
)
SELECT ord, section, details FROM (
  SELECT
    1 AS ord,
    'totals' AS section,
    jsonb_build_object(
      'total_apps',           total_apps,
      'apps_with_categories', apps_with_categories,
      'total_assignments',    total_assignments
    ) AS details
  FROM totals

  UNION ALL

  SELECT
    2,
    'unassigned_apps_count',
    jsonb_build_object(
      'count', (SELECT COUNT(*) FROM unassigned),
      'names', COALESCE((SELECT jsonb_agg(name ORDER BY name) FROM unassigned), '[]'::jsonb)
    )

  UNION ALL

  SELECT
    3,
    'uncategorized_misuse_count',
    jsonb_build_object(
      'count', (SELECT COUNT(*) FROM uncategorized_misuse),
      'app_names', COALESCE((SELECT jsonb_agg(app_name ORDER BY app_name) FROM uncategorized_misuse), '[]'::jsonb)
    )

  UNION ALL

  SELECT
    3 + display_order,
    code,
    jsonb_build_object('name', name, 'app_count', app_count)
  FROM per_category
) x
ORDER BY ord, section;
