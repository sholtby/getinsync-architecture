# Session 1: Schema Migration + Data Cleanup

**Effort:** 2–2.5 hrs. **Prerequisite:** none (first session). **Committable:** yes — additive schema, no consumers yet.

## Goal

Apply the complete Application Profile Tier 1 schema delta — **as one coordinated SQL-Editor session** — gated by data-quality cleanup of pre-existing title-case legacy values that would otherwise fail post-migration validation. All changes are additive; no destructive migrations.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` — master plan, especially §Section 1 Session 1 for full scope, and §2 Open Items Cross-Reference for what this session bundles.
2. `docs-architecture/features/application-profile/schema-mapping.md` v1.1 — field-by-field source of truth.
3. `docs-architecture/operations/new-table-checklist.md` — governs `application_narrative_cache` creation. Every step applies.
4. `docs-architecture/schema/nextgen-schema-current.sql` — before writing any migration, confirm current column lists for `applications`, `application_integrations`, `application_contacts`, `portfolio_assignments`, `deployment_profiles`.
5. `CLAUDE.md` — project rules, especially the PAID canonical rule and dual-repo commits.
6. `docs-architecture/testing/security-posture-validation.sql`, `testing/pgtap-rls-coverage.sql`, `testing/data-quality-validation.sql` — the three validators that must pass at exit.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** Never Improve/Divest.
- **Stuart applies all SQL via Supabase SQL Editor.** Your job is to author the migration, chunked safely, and hand it to him.
- Multi-statement output semantics: only the LAST result set renders in the Editor. Any chunk with multiple verification SELECTs must consolidate via CTE + UNION ALL with a `(ord, section, details jsonb)` shape (see CLAUDE.md §"Supabase SQL Editor — Multi-statement output semantics").
- Dry-run every verification query via `$DATABASE_READONLY_URL` in `.env` before handing to Stuart.

## Concrete changes (chunks, applied in order)

Author each chunk as a separate file in the code repo under `supabase/migrations/` with the next available timestamp prefix. Each chunk wraps in `BEGIN; ... COMMIT;` with a consolidated verification SELECT at the end.

### Chunk 1: Data cleanup (must run first)

- `UPDATE deployment_profiles SET paid_action = lower(paid_action) WHERE paid_action IN ('Plan','Address','Ignore','Delay');` — bundles open item **#86** (11 rows expected).
- `UPDATE portfolio_assignments SET business_assessment_status = 'not_started' WHERE business_assessment_status = 'Not Started';` — bundles **#87** (33 rows expected).
- Verification: run the sections of `testing/data-quality-validation.sql` that check `§casing:paid_action` and `§assessment:business_assessment_status` — both must PASS after this chunk.

### Chunk 2: `applications` columns

```sql
ALTER TABLE applications
  ADD COLUMN acronym text,
  ADD COLUMN business_outcome text,
  ADD COLUMN target_state text,
  ADD COLUMN cost_notes text,
  ADD COLUMN user_groups jsonb,
  ADD COLUMN estimated_user_count text
    CHECK (estimated_user_count IS NULL OR estimated_user_count IN ('<10','10-100','100-1000','1000+'));
```

### Chunk 3: `application_integrations` columns (bundles #94 Phase 1 schema)

```sql
ALTER TABLE application_integrations
  ADD COLUMN business_purpose text,
  ADD COLUMN lifecycle_start_date date,
  ADD COLUMN lifecycle_end_date date,
  ADD COLUMN sftp_required boolean,
  ADD COLUMN sftp_host text,
  ADD COLUMN sftp_credentials_status text;
```

### Chunk 3b: `portfolio_assignments` plan-status columns

```sql
ALTER TABLE portfolio_assignments
  ADD COLUMN has_plan boolean,                -- NULLABLE, tri-state
  ADD COLUMN plan_note text,
  ADD COLUMN plan_document_url text,
  ADD COLUMN planned_remediation_date date;
```

No CHECK constraints — tri-state `has_plan` relies on NULL semantics. No reference table needed.

### Chunk 4: `application_contacts.role_type` CHECK constraint

Drop the existing CHECK constraint and re-add with `accountable_executive` appended to the allowed values list. Do NOT drop other values or legacy rows. Query `information_schema.check_constraints` for the existing definition first, then `ALTER TABLE application_contacts DROP CONSTRAINT <name>, ADD CONSTRAINT <name> CHECK (role_type IN (...))` with the full new list.

### Chunk 5: `application_narrative_cache` table

Follow `operations/new-table-checklist.md` §1–§5 completely. Shape:

```sql
CREATE TABLE application_narrative_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  deployment_profile_id uuid REFERENCES deployment_profiles(id) ON DELETE CASCADE,
  narrative_key text NOT NULL CHECK (narrative_key IN (
    'plain_language_summary',
    'business_impact',
    'integration_summary',
    'time_paid_tension',
    'remediation_summary',
    'remediation_alignment'
  )),
  content text,
  generated_at timestamptz,
  input_hash text,
  approved boolean NOT NULL DEFAULT false,
  approved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Uniqueness: one row per (app, dp, key). DP-nullable — use expression index:
CREATE UNIQUE INDEX application_narrative_cache_unique_idx
  ON application_narrative_cache (application_id, COALESCE(deployment_profile_id, '00000000-0000-0000-0000-000000000000'::uuid), narrative_key);

-- Helpful read index
CREATE INDEX application_narrative_cache_app_idx
  ON application_narrative_cache (application_id);
```

Then:
- Enable RLS: `ALTER TABLE application_narrative_cache ENABLE ROW LEVEL SECURITY;`
- Four policies, all with platform-admin bypass via `check_is_platform_admin()` and namespace scoping via `namespace_id = get_current_namespace_id()`:
  - SELECT: all authenticated users in namespace
  - INSERT: admin + editor (use `check_is_namespace_admin_of_namespace(namespace_id)` pattern seen in new-table-checklist)
  - UPDATE: admin + editor
  - DELETE: admin only
- GRANTs: `GRANT SELECT, INSERT, UPDATE, DELETE ON application_narrative_cache TO authenticated;`
- Triggers:
  - `CREATE TRIGGER update_application_narrative_cache_updated_at BEFORE UPDATE ON application_narrative_cache FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();`
  - `CREATE TRIGGER audit_application_narrative_cache AFTER INSERT OR UPDATE OR DELETE ON application_narrative_cache FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();`

## Files to update in the architecture repo

After Stuart applies the migration:

1. `docs-architecture/schema/nextgen-schema-current.sql` — refresh via `pg_dump` against the dev DB (standard process).
2. `docs-architecture/testing/security-posture-validation.sql` — bump sentinels: tables 106 → 107, RLS policies +4, audit triggers +1, views unchanged (42).
3. `docs-architecture/testing/pgtap-rls-coverage.sql` — add RLS assertions for `application_narrative_cache` (4 policies).

## Exit criteria

All must pass:

1. `export $(grep DATABASE_READONLY_URL .env | xargs); psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/security-posture-validation.sql` → zero FAIL rows.
2. `psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/pgtap-rls-coverage.sql` → all assertions PASS, including new ones.
3. `psql "$DATABASE_READONLY_URL" -f docs-architecture/testing/data-quality-validation.sql` → `§casing:paid_action` and `§assessment:business_assessment_status` PASS.
4. `cd ~/Dev/getinsync-nextgen-ag && npx tsc --noEmit` → zero errors.
5. `psql "$DATABASE_READONLY_URL" -c "SELECT count(*) FROM information_schema.columns WHERE table_name IN ('applications','application_integrations','application_contacts','portfolio_assignments','application_narrative_cache');"` confirms all new columns + the new table columns.
6. `psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname LIKE '%role_type%';"` shows `accountable_executive` in the CHECK.
7. Manually: insert a test row into `application_narrative_cache` as a namespace admin — succeeds; as a viewer — blocked.

## Git

- **Code repo:** Start or continue `feat/application-profile-tier-1` off `dev`. Commit the migration file(s) with message `feat: Application Profile Tier 1 — schema migration (Session 1 of 6)`. Push with `-u`.
- **Architecture repo:** Commit refreshed schema backup + validator sentinel bumps to `main` directly. Dual-repo rule applies.
- **MANIFEST.md bump:** minor entry noting the schema backup refresh and stats update.
- Do NOT merge to `dev` yet — Session 1 is the first of six on the feature branch. Merge at end of Session 6.

## Stuck?

- Chunking rules for SQL Editor: CLAUDE.md §"Supabase SQL Editor — Multi-statement output semantics".
- Check-constraint ALTER pattern: existing migration `20251222205239_add_assessment_columns_to_deployment_profiles.sql` (read-only reference).
- If any validator fails: STOP and report to Stuart before proceeding. Do not force-proceed.
