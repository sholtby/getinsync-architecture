-- Chunk: 03-workspace-budgets-fy2026.sql
-- Purpose: Article 4.2 (Understanding IT Spend) — populate FY2026 budgets
--          for Fire Department, Public Works, and Finance so the workspace-
--          comparison view has more than 2 populated rows.
-- Preconditions:
--   - Tables touched: workspace_budgets (INSERT only)
--   - Unique constraint: (workspace_id, fiscal_year)
--   - Idempotent via INSERT ... WHERE NOT EXISTS.
--   - Do NOT touch workspaces.budget_amount — that column is legacy per CLAUDE.md.
-- Namespace scope: workspace IDs below all belong to Riverside.

BEGIN;

-- Fire Department (a1b2c3d4-0007-...) — $1,800,000
INSERT INTO workspace_budgets (workspace_id, fiscal_year, budget_amount, is_current, budget_notes)
SELECT
  'a1b2c3d4-0007-0000-0000-000000000007',
  2026,
  1800000.00,
  true,
  'FY2026 Fire Department operating IT budget (demo seed)'
WHERE NOT EXISTS (
  SELECT 1 FROM workspace_budgets
  WHERE workspace_id = 'a1b2c3d4-0007-0000-0000-000000000007'
    AND fiscal_year  = 2026
);

-- Public Works (a1b2c3d4-0012-...) — $1,200,000
INSERT INTO workspace_budgets (workspace_id, fiscal_year, budget_amount, is_current, budget_notes)
SELECT
  'a1b2c3d4-0012-0000-0000-000000000012',
  2026,
  1200000.00,
  true,
  'FY2026 Public Works IT budget (demo seed)'
WHERE NOT EXISTS (
  SELECT 1 FROM workspace_budgets
  WHERE workspace_id = 'a1b2c3d4-0012-0000-0000-000000000012'
    AND fiscal_year  = 2026
);

-- Finance (a1b2c3d4-0003-...) — $650,000
INSERT INTO workspace_budgets (workspace_id, fiscal_year, budget_amount, is_current, budget_notes)
SELECT
  'a1b2c3d4-0003-0000-0000-000000000003',
  2026,
  650000.00,
  true,
  'FY2026 Finance IT budget (demo seed)'
WHERE NOT EXISTS (
  SELECT 1 FROM workspace_budgets
  WHERE workspace_id = 'a1b2c3d4-0003-0000-0000-000000000003'
    AND fiscal_year  = 2026
);

-- Verification: consolidated into ONE SELECT (Supabase SQL Editor shows
-- only the last result set of a multi-statement query).
WITH riverside_fy2026 AS (
  SELECT w.name AS workspace_name, wb.fiscal_year, wb.budget_amount,
         wb.is_current, wb.budget_notes
  FROM workspace_budgets wb
  JOIN workspaces w ON w.id = wb.workspace_id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND wb.fiscal_year = 2026
)
SELECT ord, section, details FROM (
  SELECT 1 AS ord, '03a counts' AS section,
         jsonb_build_object(
           'fy2026_budgets_in_riverside', count(*),
           'total_budgeted_amount',       sum(budget_amount)
         ) AS details
  FROM riverside_fy2026
  UNION ALL
  SELECT 2, '03b ' || workspace_name,
         jsonb_build_object(
           'fiscal_year', fiscal_year,
           'budget',      budget_amount,
           'is_current',  is_current,
           'notes',       budget_notes
         )
  FROM riverside_fy2026
) x
ORDER BY ord, section;

COMMIT;

-- Rollback: DELETE FROM workspace_budgets WHERE fiscal_year = 2026 AND workspace_id IN ('a1b2c3d4-0007-0000-0000-000000000007','a1b2c3d4-0012-0000-0000-000000000012','a1b2c3d4-0003-0000-0000-000000000003');
