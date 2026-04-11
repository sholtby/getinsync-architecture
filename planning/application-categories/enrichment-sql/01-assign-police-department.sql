-- Chunk: 01-assign-police-department.sql
-- Purpose: Assign categories to all 8 Police Department applications.
-- Apps in this chunk (8 apps, 17 assignments):
--   Axon Evidence              -> LEGAL, RECORDS
--   Brazos eCitation           -> LEGAL
--   Computer-Aided Dispatch    -> CRM, GIS_SPATIAL
--   CopLogic Online Reporting  -> CRM, RECORDS
--   Flock Safety LPR           -> LEGAL
--   Hexagon OnCall CAD/RMS     -> LEGAL, RECORDS, CRM
--   NG911 System               -> CRM, HEALTH
--   Police Records Management  -> LEGAL, RECORDS
--
-- Idempotent (ON CONFLICT DO NOTHING). Re-running this chunk is safe.
-- Namespace-scoped via the workspace.namespace_id join — cross-namespace
-- contamination is impossible.

BEGIN;

WITH ns AS (
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid AS id
),
mapping (app_name, category_codes) AS (
  VALUES
    ('Axon Evidence',             ARRAY['LEGAL', 'RECORDS']),
    ('Brazos eCitation',          ARRAY['LEGAL']),
    ('Computer-Aided Dispatch',   ARRAY['CRM', 'GIS_SPATIAL']),
    ('CopLogic Online Reporting', ARRAY['CRM', 'RECORDS']),
    ('Flock Safety LPR',          ARRAY['LEGAL']),
    ('Hexagon OnCall CAD/RMS',    ARRAY['LEGAL', 'RECORDS', 'CRM']),
    ('NG911 System',              ARRAY['CRM', 'HEALTH']),
    ('Police Records Management', ARRAY['LEGAL', 'RECORDS'])
),
expanded AS (
  SELECT m.app_name, unnest(m.category_codes) AS category_code
  FROM mapping m
),
resolved AS (
  SELECT
    a.id AS application_id,
    ac.id AS category_id
  FROM expanded e
  JOIN applications a ON a.name = e.app_name
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN application_categories ac
    ON ac.namespace_id = w.namespace_id
   AND ac.code = e.category_code
  WHERE w.namespace_id = (SELECT id FROM ns)
    AND w.name = 'Police Department'
)
INSERT INTO application_category_assignments (application_id, category_id)
SELECT application_id, category_id FROM resolved
ON CONFLICT (application_id, category_id) DO NOTHING;

COMMIT;

-- Consolidated verifier (single result set, jsonb-shaped per-row).
-- Expected: each app in this chunk shows its assigned codes in display_order.
WITH chunk_apps AS (
  SELECT a.id, a.name
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND w.name = 'Police Department'
    AND a.name IN (
      'Axon Evidence',
      'Brazos eCitation',
      'Computer-Aided Dispatch',
      'CopLogic Online Reporting',
      'Flock Safety LPR',
      'Hexagon OnCall CAD/RMS',
      'NG911 System',
      'Police Records Management'
    )
),
per_app AS (
  SELECT
    ca.name AS app_name,
    COALESCE(
      array_agg(ac.code ORDER BY ac.display_order)
        FILTER (WHERE ac.code IS NOT NULL),
      ARRAY[]::text[]
    ) AS assigned_codes
  FROM chunk_apps ca
  LEFT JOIN application_category_assignments aca ON aca.application_id = ca.id
  LEFT JOIN application_categories ac ON ac.id = aca.category_id
  GROUP BY ca.name
)
SELECT
  1 AS ord,
  app_name AS section,
  jsonb_build_object('codes', to_jsonb(assigned_codes)) AS details
FROM per_app
ORDER BY app_name;
