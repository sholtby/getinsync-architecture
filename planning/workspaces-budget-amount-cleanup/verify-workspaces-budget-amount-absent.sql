-- ============================================================================
-- verify-workspaces-budget-amount-absent.sql
-- ============================================================================
--
-- Purpose:
--   Read-only verification that the legacy `public.workspaces.budget_amount`
--   column does not exist on the live database. Produced as part of the
--   planning/workspaces-budget-amount-cleanup investigation on 2026-04-10.
--
-- Safety classification:
--   GREEN — already dropped. No DROP-COLUMN statement is needed or provided.
--   This file is SELECT-only and has no side effects. It is safe to run
--   against the read-only connection (`DATABASE_READONLY_URL`) as many times
--   as desired. It is idempotent.
--
-- What this file does:
--   1. Confirms `workspaces.budget_amount` is absent per `information_schema`.
--   2. Confirms no live attribute by that name exists in `pg_attribute`.
--   3. Surfaces the dropped-column placeholder that PostgreSQL retains after
--      an ALTER TABLE ... DROP COLUMN (forensic record of the prior drop).
--   4. Lists every table where `budget_amount` actually does exist (live
--      replacements: applications, it_services, programs, workspace_budgets).
--   5. Confirms no view or function still references `workspaces.budget_amount`.
--
-- What this file does NOT do:
--   - Does NOT drop any column (the drop has already happened).
--   - Does NOT migrate any data (nothing to migrate — column is gone).
--   - Does NOT write, update, or delete anything.
--
-- Stuart's required verification before applying the CLAUDE.md rule removal:
--   Run this file and visually confirm:
--     - Check 1 returns 0 rows.
--     - Check 2 returns 0 rows.
--     - Check 3 shows exactly one `........pg.dropped.N........` entry
--       between `budget_fiscal_year` and `budget_notes`.
--     - Check 4 lists 4 tables (applications, it_services, programs,
--       workspace_budgets) plus the two views, and does NOT list `workspaces`.
--     - Check 5 returns 0 rows.
--
-- Rollback notes:
--   Not applicable — this script performs no mutations. If, for any reason,
--   Stuart needs to restore the `workspaces.budget_amount` column in the
--   future (e.g. to re-import historical data), the operation would be:
--     ALTER TABLE public.workspaces ADD COLUMN budget_amount numeric(12,2);
--     -- then restore values from a prior backup
--   This is a one-way door historically — the original drop also cannot be
--   undone without a backup restore. Nothing in this file risks either door.
--
-- Execution:
--   cd ~/Dev/getinsync-nextgen-ag
--   export $(grep DATABASE_READONLY_URL .env | xargs)
--   psql "$DATABASE_READONLY_URL" -f \
--     ./docs-architecture/planning/workspaces-budget-amount-cleanup/verify-workspaces-budget-amount-absent.sql
--
-- ============================================================================

\echo '--- Check 1: information_schema should return 0 rows ---'
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'workspaces'
  AND column_name  = 'budget_amount';

\echo
\echo '--- Check 2: pg_attribute (live, not-dropped) should return 0 rows ---'
SELECT attname
FROM pg_attribute
WHERE attrelid = 'public.workspaces'::regclass
  AND attname  = 'budget_amount'
  AND NOT attisdropped;

\echo
\echo '--- Check 3: dropped-column forensic record (expect one ........pg.dropped.N........ row between budget_fiscal_year and budget_notes) ---'
SELECT attname,
       atttypid::regtype,
       attnum,
       attisdropped
FROM pg_attribute
WHERE attrelid = 'public.workspaces'::regclass
  AND attnum > 0
ORDER BY attnum;

\echo
\echo '--- Check 4: live locations of budget_amount (expect applications, it_services, programs, workspace_budgets, plus views vw_program_summary and vw_workspace_budget_history) ---'
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name  = 'budget_amount'
ORDER BY table_name;

\echo
\echo '--- Check 5: views/functions referencing workspaces.budget_amount (expect 0 rows) ---'
SELECT viewname AS object_name, 'view' AS object_type
FROM pg_views
WHERE schemaname = 'public'
  AND pg_get_viewdef(viewname::regclass, true) ~* '(workspaces\.budget_amount|\Wws\.budget_amount|\Ww\.budget_amount)'
  AND pg_get_viewdef(viewname::regclass, true) !~* '(wb\.budget_amount)';
-- Note: the guard on `wb.budget_amount` excludes false positives from views
-- that alias `workspace_budgets` as `wb` — the substring `w.budget_amount`
-- would otherwise match `wb.budget_amount`. Callers that want a fully manual
-- check should read `pg_get_viewdef()` for each of the 5 views returned by
-- the companion listing (see findings-report.md Step 3).

\echo
\echo '--- Check 5b: functions referencing budget_amount (inspect each to confirm none target workspaces.budget_amount) ---'
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prosrc ILIKE '%budget_amount%'
ORDER BY p.proname;
-- As of 2026-04-10 this returns initialize_app_budgets and
-- initialize_it_service_budgets, both of which target live tables only.

\echo
\echo '--- workspace_budgets state (informational) ---'
SELECT count(*)                               AS total_rows,
       count(*) FILTER (WHERE is_current)     AS current_rows,
       count(DISTINCT workspace_id)           AS workspaces_with_budget,
       min(fiscal_year)                       AS earliest_fy,
       max(fiscal_year)                       AS latest_fy
FROM public.workspace_budgets;

\echo
\echo '--- Verification complete. ---'
