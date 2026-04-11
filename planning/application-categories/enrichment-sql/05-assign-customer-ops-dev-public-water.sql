-- Chunk: 05-assign-customer-ops-dev-public-water.sql
-- Purpose: Assign categories to remaining workspaces — Customer Operations (2 apps),
--          Development Services (1 app), Public Works (1 app), Water Utilities (1 app).
-- Apps in this chunk (5 apps, 7 assignments):
--   CivicPlus Website        -> CRM, RECORDS              (Customer Operations)
--   SeeClickFix              -> CRM                       (Customer Operations)
--   Accela Civic Platform    -> CRM, LEGAL                (Development Services)
--   Samsara Fleet            -> ERP, GIS_SPATIAL          (Public Works)
--   Sensus FlexNet           -> INFRASTRUCTURE, ANALYTICS (Water Utilities)
--
-- NOTE: Samsara Fleet (EAM-shaped) and Sensus FlexNet (AMI / OT) are both
-- shoehorned into the closest available umbrellas. A future Phase 2 catalog
-- refinement should add `EAM` and these would re-tag cleanly.
--
-- Idempotent (ON CONFLICT DO NOTHING). Re-running this chunk is safe.
-- Namespace-scoped via the workspace.namespace_id join.

\pset pager off

BEGIN;

WITH ns AS (
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid AS id
),
mapping (workspace_name, app_name, category_codes) AS (
  VALUES
    ('Customer Operations',  'CivicPlus Website',     ARRAY['CRM', 'RECORDS']),
    ('Customer Operations',  'SeeClickFix',           ARRAY['CRM']),
    ('Development Services', 'Accela Civic Platform', ARRAY['CRM', 'LEGAL']),
    ('Public Works',         'Samsara Fleet',         ARRAY['ERP', 'GIS_SPATIAL']),
    ('Water Utilities',      'Sensus FlexNet',        ARRAY['INFRASTRUCTURE', 'ANALYTICS'])
),
expanded AS (
  SELECT m.workspace_name, m.app_name, unnest(m.category_codes) AS category_code
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
    AND w.name = e.workspace_name
)
INSERT INTO application_category_assignments (application_id, category_id)
SELECT application_id, category_id FROM resolved
ON CONFLICT (application_id, category_id) DO NOTHING;

COMMIT;

-- Consolidated verifier (single result set).
WITH chunk_apps AS (
  SELECT a.id, a.name, w.name AS workspace_name
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND (
      (w.name = 'Customer Operations'  AND a.name IN ('CivicPlus Website', 'SeeClickFix'))
      OR (w.name = 'Development Services' AND a.name = 'Accela Civic Platform')
      OR (w.name = 'Public Works'         AND a.name = 'Samsara Fleet')
      OR (w.name = 'Water Utilities'      AND a.name = 'Sensus FlexNet')
    )
),
per_app AS (
  SELECT
    ca.workspace_name,
    ca.name AS app_name,
    COALESCE(
      array_agg(ac.code ORDER BY ac.display_order)
        FILTER (WHERE ac.code IS NOT NULL),
      ARRAY[]::text[]
    ) AS assigned_codes
  FROM chunk_apps ca
  LEFT JOIN application_category_assignments aca ON aca.application_id = ca.id
  LEFT JOIN application_categories ac ON ac.id = aca.category_id
  GROUP BY ca.workspace_name, ca.name
)
SELECT
  1 AS ord,
  workspace_name || ' / ' || app_name AS section,
  jsonb_build_object('codes', to_jsonb(assigned_codes)) AS details
FROM per_app
ORDER BY workspace_name, app_name;
