-- Chunk: 04-it-service-contracts.sql
-- Purpose: Article 4.3 (Cost Analysis) — add contract metadata to the top
--          three highest-cost IT services in Riverside so the IT-service
--          contract expiry widget and vw_it_service_contract_expiry view
--          have content to render. Zero of 11 services have contract data
--          today.
-- Preconditions:
--   - Tables touched: it_services (UPDATE only)
--   - Do NOT touch annual_cost or budget_amount — those feed the $3.0M
--     Annual Run Rate KPI card on the overview dashboard and must not move.
--   - Do NOT touch software_products.annual_cost — per cost-model.md §3.1,
--     Software Products are inventory-only; cost lives on IT Service
--     allocations and Cost Bundle DPs (two cost channels).
--   - Idempotent via WHERE contract_reference IS NULL guards. Safe to re-run.
-- Namespace scope: all three it_services rows are scoped to Riverside via
--                  it_services.namespace_id in the WHERE clause.

BEGIN;

-- Top #1 by annual_cost: Microsoft 365 Enterprise — $1,038,000 — safe horizon
-- (contract ends 2027-01-31, ~9 months out from 2026-04-10)
UPDATE it_services
SET
  contract_reference  = 'MSA-2024-M365-0412',
  contract_start_date = DATE '2024-02-01',
  contract_end_date   = DATE '2027-01-31',
  renewal_notice_days = 90,
  updated_at          = now()
WHERE id           = 'b400000a-0000-0000-0000-00000000000a'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND contract_reference IS NULL;

-- Top #2 by annual_cost: Azure Cloud Hosting — $500,000 — near-expiry
-- (contract ends 2026-08-31, ~5 months out — will show a renewal alert)
UPDATE it_services
SET
  contract_reference  = 'MSA-2023-AZURE-0183',
  contract_start_date = DATE '2023-09-01',
  contract_end_date   = DATE '2026-08-31',
  renewal_notice_days = 90,
  updated_at          = now()
WHERE id           = 'b4000002-0000-0000-0000-000000000002'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND contract_reference IS NULL;

-- Top #3 by annual_cost: Identity & Access Management — $327,000 — safe horizon
-- (contract ends 2027-02-28, ~10 months out)
UPDATE it_services
SET
  contract_reference  = 'CR-2025-IAM-0087',
  contract_start_date = DATE '2025-03-01',
  contract_end_date   = DATE '2027-02-28',
  renewal_notice_days = 90,
  updated_at          = now()
WHERE id           = 'b4000008-0000-0000-0000-000000000008'
  AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND contract_reference IS NULL;

-- Verification: consolidated into ONE SELECT (Supabase SQL Editor shows
-- only the last result set of a multi-statement query).
WITH riverside_its AS (
  SELECT
    name,
    annual_cost,
    contract_reference,
    contract_start_date,
    contract_end_date,
    CASE
      WHEN contract_end_date IS NULL THEN 'no_contract'
      WHEN contract_end_date <  CURRENT_DATE THEN 'expired'
      WHEN contract_end_date <= CURRENT_DATE + (renewal_notice_days * INTERVAL '1 day')
           THEN 'renewal_window'
      ELSE 'safe'
    END AS renewal_state
  FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
)
SELECT ord, section, details FROM (
  SELECT 1 AS ord, '04a counts' AS section,
         jsonb_build_object(
           'services_with_contract', count(*) FILTER (WHERE contract_reference IS NOT NULL),
           'total_services',         count(*),
           'unchanged_annual_cost',  sum(annual_cost)
         ) AS details
  FROM riverside_its
  UNION ALL
  SELECT
    2 + row_number() OVER (ORDER BY annual_cost DESC),
    '04b ' || name,
    jsonb_build_object(
      'annual_cost',         annual_cost,
      'contract_reference',  contract_reference,
      'contract_start_date', contract_start_date,
      'contract_end_date',   contract_end_date,
      'renewal_state',       renewal_state
    )
  FROM riverside_its
) x
ORDER BY ord, section;

COMMIT;

-- Rollback: UPDATE it_services SET contract_reference = NULL, contract_start_date = NULL, contract_end_date = NULL WHERE id IN ('b400000a-0000-0000-0000-00000000000a','b4000002-0000-0000-0000-000000000002','b4000008-0000-0000-0000-000000000008') AND namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
