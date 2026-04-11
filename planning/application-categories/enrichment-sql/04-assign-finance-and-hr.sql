-- Chunk: 04-assign-finance-and-hr.sql
-- Purpose: Assign categories to Finance (4 apps) and Human Resources (3 apps).
-- Apps in this chunk (7 apps, 11 assignments):
--   Cayenta Financials      -> FINANCE, CRM       (Finance)
--   Microsoft Dynamics GP   -> FINANCE, ERP       (Finance)
--   Questica Budget         -> FINANCE            (Finance)
--   Sage 300 GL             -> FINANCE            (Finance)
--   Kronos Workforce Central -> HR                (Human Resources)
--   NEOGOV                  -> HR                 (Human Resources)
--   Workday HCM             -> HR, FINANCE        (Human Resources)
--
-- Idempotent (ON CONFLICT DO NOTHING). Re-running this chunk is safe.
-- Namespace-scoped via the workspace.namespace_id join.

BEGIN;

WITH ns AS (
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid AS id
),
mapping (workspace_name, app_name, category_codes) AS (
  VALUES
    ('Finance',         'Cayenta Financials',       ARRAY['FINANCE', 'CRM']),
    ('Finance',         'Microsoft Dynamics GP',    ARRAY['FINANCE', 'ERP']),
    ('Finance',         'Questica Budget',          ARRAY['FINANCE']),
    ('Finance',         'Sage 300 GL',              ARRAY['FINANCE']),
    ('Human Resources', 'Kronos Workforce Central', ARRAY['HR']),
    ('Human Resources', 'NEOGOV',                   ARRAY['HR']),
    ('Human Resources', 'Workday HCM',              ARRAY['HR', 'FINANCE'])
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
      (w.name = 'Finance' AND a.name IN (
        'Cayenta Financials',
        'Microsoft Dynamics GP',
        'Questica Budget',
        'Sage 300 GL'
      ))
      OR (w.name = 'Human Resources' AND a.name IN (
        'Kronos Workforce Central',
        'NEOGOV',
        'Workday HCM'
      ))
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
