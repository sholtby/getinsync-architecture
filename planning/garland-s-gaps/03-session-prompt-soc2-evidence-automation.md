# Session Prompt 03 — SOC2 Evidence Collection: Automate via pg_cron

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 1-2 hours

---

## Task: Generate SQL scripts to automate SOC2 evidence collection with pg_cron and a storage table

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 7) claims: "Evidence collection is automated."

Currently, `generate_soc2_evidence()` is a manually-invoked RPC that returns a JSONB blob. Stuart runs it from the SQL Editor, copies the output, and saves it as a JSON file in `soc2-evidence/`. We need to automate this: a pg_cron job runs monthly, calls the function, and stores the snapshot in a database table with proper sequencing and variance detection.

**This session generates SQL scripts only** — Stuart applies them via the Supabase SQL Editor. No application code changes.

### Hard rules

1. **Branch:** `fix/soc2-evidence-cron`. Create from `dev`.
2. **Output SQL files only** to `planning/sql/garland-s-gaps/`. Do NOT execute any SQL.
3. **Do NOT modify application code** — no `src/` changes.
4. **Follow the project's new-table checklist:** RLS enabled, audit trigger, GRANT to authenticated + service_role.
5. **Use the existing `generate_soc2_evidence()` function** — do NOT rewrite it. Wrap it.
6. **Fix the two known data quality issues** in `generate_soc2_evidence()` before automating (see Step 3).

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/schema/audit-logging-functions.sql
   - generate_soc2_evidence() function — lines ~195-318
   - Note: requires platform admin (check_is_platform_admin())
   - Note: returns JSONB

2. docs-architecture/operations/new-table-checklist.md
   - Table creation pattern: RLS, audit trigger, grants

3. soc2-evidence/GIS-SOC2-EV-002-2026-04-09.json
   - Current snapshot format: metadata envelope + report + variance

4. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "pg_cron" or "cron" to find existing cron infrastructure
   - Search for "grant_pg_cron_access" — the access-granting function

5. docs-architecture/operations/session-end-checklist.md
   - Lines ~507-519: current manual SOC2 evidence process
```

### Step 2 — Verify existing infrastructure via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm generate_soc2_evidence exists
psql "$DATABASE_READONLY_URL" -c "SELECT proname, pronargs FROM pg_proc WHERE proname = 'generate_soc2_evidence'"

# Confirm pg_cron extension is available
psql "$DATABASE_READONLY_URL" -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron'"

# Check if any cron jobs already exist
psql "$DATABASE_READONLY_URL" -c "SELECT jobid, schedule, command FROM cron.job" 2>/dev/null || echo "pg_cron not accessible or no jobs"

# Get current evidence function definition for reference
psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'generate_soc2_evidence'" -t
```

### Step 3 — Generate SQL Script 01: Fix known data quality issues

**File:** `planning/sql/garland-s-gaps/01-fix-evidence-quality.sql`

Two known issues in `generate_soc2_evidence()` need fixing before we automate:

**Issue 1 (item #84):** `last_manual_backup` is hardcoded to `'2026-02-08'`. Replace with a dynamic lookup. Options:
- Query `pg_stat_archiver` for latest archive timestamp
- Or create a small `platform_metadata` key-value table to store the last backup date (Stuart updates this when he runs pg_dump)
- Recommend the key-value approach — it's explicit and auditable

**Issue 2 (item #85):** `schema_function_count` jumped from 50 to 1,283 because the query includes extension functions. Scope the count to user-defined functions only:
```sql
-- Before (broken):
SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public'

-- After (fixed):
SELECT count(*) FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.prokind = 'f'
AND p.proname NOT LIKE 'pg_%'
AND p.proname NOT LIKE '_pg_%'
```

Generate a `CREATE OR REPLACE FUNCTION generate_soc2_evidence()` that fixes both issues while keeping all other logic identical. Include the existing function's full body — patch the two queries in place.

### Step 4 — Generate SQL Script 02: Create evidence storage table

**File:** `planning/sql/garland-s-gaps/02-evidence-storage.sql`

Create a `soc2_evidence_snapshots` table:

```sql
CREATE TABLE public.soc2_evidence_snapshots (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  sequence_number integer NOT NULL,
  collection_date timestamptz NOT NULL DEFAULT now(),
  evidence_data jsonb NOT NULL,
  variance_from_previous jsonb,
  generated_by text NOT NULL DEFAULT 'pg_cron',  -- 'pg_cron' or 'manual'
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Unique sequence numbers
ALTER TABLE public.soc2_evidence_snapshots
  ADD CONSTRAINT uq_soc2_evidence_sequence UNIQUE (sequence_number);

-- Index for date-range queries
CREATE INDEX idx_soc2_evidence_date ON public.soc2_evidence_snapshots (collection_date DESC);
```

Follow the new-table checklist:
- `ALTER TABLE public.soc2_evidence_snapshots ENABLE ROW LEVEL SECURITY;`
- RLS policy: platform admins only (SELECT, INSERT)
- `GRANT ALL ON public.soc2_evidence_snapshots TO authenticated, service_role;`
- Audit trigger: `CREATE TRIGGER ... fn_audit_trigger()`
- Comment: `COMMENT ON TABLE public.soc2_evidence_snapshots IS 'Monthly SOC2 Type II evidence snapshots generated by pg_cron';`

### Step 5 — Generate SQL Script 03: Create wrapper function + cron job

**File:** `planning/sql/garland-s-gaps/03-cron-schedule.sql`

Create a wrapper function that pg_cron calls:

```sql
CREATE OR REPLACE FUNCTION public.fn_collect_soc2_evidence()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_evidence jsonb;
  v_previous jsonb;
  v_variance jsonb;
  v_next_seq integer;
BEGIN
  -- Generate evidence
  -- Note: We bypass check_is_platform_admin() because this runs as pg_cron (superuser context)
  -- The original function's admin check will pass in SECURITY DEFINER context
  v_evidence := generate_soc2_evidence();

  -- Get next sequence number
  SELECT COALESCE(MAX(sequence_number), 0) + 1
  INTO v_next_seq
  FROM soc2_evidence_snapshots;

  -- Get previous snapshot for variance calculation
  SELECT evidence_data
  INTO v_previous
  FROM soc2_evidence_snapshots
  ORDER BY sequence_number DESC
  LIMIT 1;

  -- Calculate variance (key metrics delta)
  IF v_previous IS NOT NULL THEN
    v_variance := jsonb_build_object(
      'user_count_delta',
        (v_evidence->'cc6_1_logical_access'->>'total_users')::int -
        (v_previous->'cc6_1_logical_access'->>'total_users')::int,
      'rls_policy_delta',
        (v_evidence->'cc6_1_logical_access'->>'rls_policy_count')::int -
        (v_previous->'cc6_1_logical_access'->>'rls_policy_count')::int,
      'audit_entry_delta',
        (v_evidence->'cc6_6_audit_logging'->>'total_entries')::int -
        (v_previous->'cc6_6_audit_logging'->>'total_entries')::int,
      'table_count_delta',
        (v_evidence->'a1_2_backup_recovery'->'schema_objects'->>'tables')::int -
        (v_previous->'a1_2_backup_recovery'->'schema_objects'->>'tables')::int
    );
  END IF;

  -- Store snapshot
  INSERT INTO soc2_evidence_snapshots (sequence_number, evidence_data, variance_from_previous)
  VALUES (v_next_seq, v_evidence, v_variance);
END;
$$;
```

**Important:** Read the actual `generate_soc2_evidence()` function definition from Step 2 output. The variance calculation above uses assumed JSON paths — verify they match the actual JSONB structure from the function. Adjust the paths if needed.

Schedule the cron job:

```sql
-- Run at 01:00 UTC on the 1st of every month
SELECT cron.schedule(
  'soc2-evidence-monthly',
  '0 1 1 * *',
  'SELECT fn_collect_soc2_evidence()'
);
```

Add a consolidated verification query at the bottom:

```sql
-- Verification (single SELECT for Supabase SQL Editor)
WITH cron_check AS (
  SELECT jobid, schedule, command FROM cron.job WHERE jobname = 'soc2-evidence-monthly'
),
table_check AS (
  SELECT count(*) AS snapshot_count FROM soc2_evidence_snapshots
),
function_check AS (
  SELECT proname FROM pg_proc WHERE proname = 'fn_collect_soc2_evidence'
)
SELECT ord, section, details FROM (
  SELECT 1 AS ord, 'cron_job' AS section,
         jsonb_build_object('jobid', jobid, 'schedule', schedule, 'command', command) AS details
  FROM cron_check
  UNION ALL
  SELECT 2, 'storage_table',
         jsonb_build_object('snapshot_count', snapshot_count)
  FROM table_check
  UNION ALL
  SELECT 3, 'wrapper_function',
         jsonb_build_object('exists', proname IS NOT NULL)
  FROM function_check
) x
ORDER BY ord;
```

### Step 6 — Generate SQL Script 04: Seed initial snapshot

**File:** `planning/sql/garland-s-gaps/04-seed-initial-snapshot.sql`

Run the wrapper once immediately to create the first automated snapshot:

```sql
-- Seed the first automated snapshot (run after scripts 01-03 are applied)
SELECT fn_collect_soc2_evidence();

-- Verify it was stored
SELECT sequence_number, collection_date, generated_by,
       evidence_data->'cc6_1_logical_access'->>'total_users' AS users,
       evidence_data->'cc6_1_logical_access'->>'rls_policy_count' AS rls_policies
FROM soc2_evidence_snapshots
ORDER BY sequence_number DESC
LIMIT 1;
```

### Step 7 — Update security posture validation sentinels

Check if `docs-architecture/testing/security-posture-validation.sql` needs the new table added to its table count sentinel. The sentinel currently expects 106 tables — adding `soc2_evidence_snapshots` will make it 107. Note this in the SQL file header as a comment for Stuart.

### Step 8 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
mkdir -p planning/sql/garland-s-gaps
# The SQL files should already be in planning/sql/garland-s-gaps/
git add planning/sql/garland-s-gaps/
git commit -m "fix: SQL scripts for automated SOC2 evidence collection via pg_cron

Creates soc2_evidence_snapshots table, wrapper function, and monthly
cron schedule. Fixes two data quality issues in generate_soc2_evidence()
(hardcoded backup date, inflated function count).
Closes Garland audit yellow flag (Slide 7, 'automated evidence')."
git push -u origin fix/soc2-evidence-cron
```

### Done criteria checklist

- [ ] `01-fix-evidence-quality.sql` — fixes hardcoded backup date and function count scope
- [ ] `02-evidence-storage.sql` — creates `soc2_evidence_snapshots` with RLS, audit trigger, grants
- [ ] `03-cron-schedule.sql` — creates `fn_collect_soc2_evidence()` wrapper + pg_cron job (monthly 1st at 01:00 UTC)
- [ ] `04-seed-initial-snapshot.sql` — runs wrapper once + verification query
- [ ] All verification SELECTs use consolidated CTE+UNION ALL pattern (Supabase SQL Editor single-result rule)
- [ ] Variance calculation JSON paths match actual `generate_soc2_evidence()` output structure
- [ ] Security posture sentinel delta noted (106 → 107 tables)
- [ ] `npx tsc --noEmit` passes (should be no-op since no src/ changes)
- [ ] No application code modified

### What NOT to do

- Do NOT execute any SQL — generate scripts only, Stuart applies them
- Do NOT modify `src/` — this session produces SQL files only
- Do NOT rewrite `generate_soc2_evidence()` from scratch — patch the two broken queries only
- Do NOT delete the existing `soc2-evidence/` directory or JSON files — those are the historical baseline
- Do NOT create Edge Functions — pg_cron handles this entirely within the database
