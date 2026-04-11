-- Chunk: 03-assign-information-technology.sql
-- Purpose: Assign categories to all 8 Information Technology applications.
-- Apps in this chunk (8 apps, 11 assignments):
--   Active Directory Services  -> SECURITY, INFRASTRUCTURE
--   Esri ArcGIS Enterprise     -> GIS_SPATIAL
--   Hyland OnBase              -> RECORDS
--   Microsoft 365              -> COLLABORATION, RECORDS
--   PRTG Network Monitor       -> INFRASTRUCTURE
--   ServiceDesk Plus           -> INFRASTRUCTURE
--   ServiceNow ITSM            -> INFRASTRUCTURE
--   SirsiDynix Symphony        -> CRM, RECORDS
--
-- NOTE: ServiceNow ITSM and ServiceDesk Plus are both single-tagged as
-- INFRASTRUCTURE. This is the load-bearing gap from the catalog level-set —
-- a future Phase 2 catalog refinement should add an `ITSM` code and these
-- two apps should be re-tagged then.
--
-- Idempotent (ON CONFLICT DO NOTHING). Re-running this chunk is safe.
-- Namespace-scoped via the workspace.namespace_id join.

BEGIN;

WITH ns AS (
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid AS id
),
mapping (app_name, category_codes) AS (
  VALUES
    ('Active Directory Services', ARRAY['SECURITY', 'INFRASTRUCTURE']),
    ('Esri ArcGIS Enterprise',    ARRAY['GIS_SPATIAL']),
    ('Hyland OnBase',             ARRAY['RECORDS']),
    ('Microsoft 365',             ARRAY['COLLABORATION', 'RECORDS']),
    ('PRTG Network Monitor',      ARRAY['INFRASTRUCTURE']),
    ('ServiceDesk Plus',          ARRAY['INFRASTRUCTURE']),
    ('ServiceNow ITSM',           ARRAY['INFRASTRUCTURE']),
    ('SirsiDynix Symphony',       ARRAY['CRM', 'RECORDS'])
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
    AND w.name = 'Information Technology'
)
INSERT INTO application_category_assignments (application_id, category_id)
SELECT application_id, category_id FROM resolved
ON CONFLICT (application_id, category_id) DO NOTHING;

COMMIT;

-- Consolidated verifier (single result set).
WITH chunk_apps AS (
  SELECT a.id, a.name
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND w.name = 'Information Technology'
    AND a.name IN (
      'Active Directory Services',
      'Esri ArcGIS Enterprise',
      'Hyland OnBase',
      'Microsoft 365',
      'PRTG Network Monitor',
      'ServiceDesk Plus',
      'ServiceNow ITSM',
      'SirsiDynix Symphony'
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
