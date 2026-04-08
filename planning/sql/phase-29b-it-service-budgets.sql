-- Phase 29b: Set realistic IT Service budgets for COR demo namespace
-- Run in Supabase SQL Editor
-- Namespace: a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- IT Workspace: a1b2c3d4-0001-0000-0000-000000000001

BEGIN;

-- 1. Set budget_amount on each IT service (~105% of annual_cost for healthy status)
UPDATE it_services SET budget_amount = 525000, budget_fiscal_year = 2026
WHERE id = 'b4000002-0000-0000-0000-000000000002'; -- Azure Cloud Hosting ($500K annual)

UPDATE it_services SET budget_amount = 25000, budget_fiscal_year = 2026
WHERE id = 'b400000c-0000-0000-0000-00000000000c'; -- Collaboration & Conferencing ($24K annual)

UPDATE it_services SET budget_amount = 210000, budget_fiscal_year = 2026
WHERE id = 'b4000007-0000-0000-0000-000000000007'; -- Cybersecurity Operations ($200K annual)

UPDATE it_services SET budget_amount = 150000, budget_fiscal_year = 2026
WHERE id = 'b4000005-0000-0000-0000-000000000005'; -- Enterprise Backup & Recovery ($142K annual)

UPDATE it_services SET budget_amount = 105000, budget_fiscal_year = 2026
WHERE id = 'b400000b-0000-0000-0000-00000000000b'; -- GIS Platform ($100K annual)

UPDATE it_services SET budget_amount = 340000, budget_fiscal_year = 2026
WHERE id = 'b4000008-0000-0000-0000-000000000008'; -- Identity & Access Management ($327K annual)

UPDATE it_services SET budget_amount = 1090000, budget_fiscal_year = 2026
WHERE id = 'b400000a-0000-0000-0000-00000000000a'; -- Microsoft 365 Enterprise ($1.038M annual)

UPDATE it_services SET budget_amount = 260000, budget_fiscal_year = 2026
WHERE id = 'b4000006-0000-0000-0000-000000000006'; -- Network Infrastructure ($250K annual)

UPDATE it_services SET budget_amount = 100000, budget_fiscal_year = 2026
WHERE id = 'b4000004-0000-0000-0000-000000000004'; -- Oracle Database Services ($95K annual)

UPDATE it_services SET budget_amount = 125000, budget_fiscal_year = 2026
WHERE id = 'b4000003-0000-0000-0000-000000000003'; -- SQL Server Database Services ($120K annual)

UPDATE it_services SET budget_amount = 190000, budget_fiscal_year = 2026
WHERE id = 'b4000001-0000-0000-0000-000000000001'; -- Windows Server Hosting ($180K annual)

-- Total IT service budgets: $3,120,000

-- 2. Update IT workspace budget to match
INSERT INTO workspace_budgets (workspace_id, fiscal_year, budget_amount, is_current)
VALUES ('a1b2c3d4-0001-0000-0000-000000000001', 2026, 3120000, true)
ON CONFLICT (workspace_id, fiscal_year)
DO UPDATE SET budget_amount = EXCLUDED.budget_amount, is_current = true;

-- 3. Verify
SELECT its.name, its.annual_cost, its.budget_amount,
  v.committed, v.remaining, v.budget_status
FROM it_services its
JOIN vw_it_service_budget_status v ON v.it_service_id = its.id
WHERE its.owner_workspace_id = 'a1b2c3d4-0001-0000-0000-000000000001'
ORDER BY its.name;

COMMIT;
