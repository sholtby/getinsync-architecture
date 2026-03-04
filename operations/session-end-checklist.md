# GetInSync NextGen — Session-End Checklist

**Version:** 1.9
**Date:** March 3, 2026
**Status:** 🟢 ACTIVE  
**Purpose:** Master checklist Claude executes at session end — dispatches to individual validation skills  
**Trigger:** End of every session with database changes, or when Stuart says "run session-end checklist"

---

## How To Use

Claude reads this document at the end of every productive session. Each section determines whether it applies based on what changed during the session, then dispatches to the appropriate skill document for the actual queries and procedures.

**Workflow:**
```
Session ending → Read this checklist → Run applicable sections → Report pass/fail → Produce handover doc
```

---

## Section 1: What Changed This Session?

Before running checks, Claude identifies what was touched. Check all that apply:

| Changed? | Category | Triggers |
|----------|----------|----------|
| ☐ | New tables created | → Run Section 2 (New Table) + Section 3 (Database Validation) + Section 6d (Security Regression) |
| ☐ | Existing tables modified (columns, constraints) | → Run Section 3 (Database Validation) + Section 6d (Security Regression) |
| ☐ | RLS policies added or changed | → Run Section 3 (Database Validation) + Section 6d (Security Regression) |
| ☐ | GRANTs added or changed | → Run Section 3 (Database Validation) + Section 6d (Security Regression) |
| ☐ | New views created | → Run Section 4 (Security Validation) + Section 6d (Security Regression) |
| ☐ | New functions created | → Run Section 4 (Security Validation) |
| ☐ | Audit triggers added | → Run Section 3 (Database Validation) + Section 6d (Security Regression) |
| ☐ | Architecture documents created or updated | → Run Section 5 (Manifest) + Section 6c (Architecture Repo) |
| ☐ | Claude Code changes (UI/frontend) | → Run Section 6 (Deploy Reminder) + Section 6e (Code Quality Gate) + Section 6f (Bulletproof React Spot Check) + Section 6g (Data Quality) |
| ☐ | Data seeded, migrated, or enum/status columns touched | → Run Section 6g (Data Quality) |
| ☐ | Any database changes at all | → Run Section 6b (Schema Backup) + Section 6c (Architecture Repo) + Section 6d (Security Regression) + Section 6g (Data Quality) + Section 9 (Stats Alignment) |
| ☐ | Any work done at all | → Run Section 7 (Handover) + Section 10 (Open Items) |
| ☐ | No database changes | → Skip to Section 7 (Handover) + Section 10 (Open Items) |

---

## Section 2: New Table Validation

**When:** Any new table was created this session.  
**Skill:** `operations/new-table-checklist.md`

For each new table, verify:

| # | Check | Query |
|---|-------|-------|
| 1 | Table exists | `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = '{table}';` |
| 2 | GRANTs exist | `SELECT grantee, privilege_type FROM information_schema.table_privileges WHERE table_name = '{table}' AND grantee IN ('authenticated', 'service_role');` |
| 3 | RLS enabled | `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = '{table}';` |
| 4 | RLS policies exist | `SELECT policyname, cmd FROM pg_policies WHERE tablename = '{table}';` |
| 5 | Audit trigger (if applicable) | `SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = '{table}' AND trigger_name LIKE '%audit%';` |
| 6 | updated_at trigger (if applicable) | `SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.{table}'::regclass AND tgname LIKE 'update_%_updated_at';` |

**Pass criteria:** All applicable checks return expected results.

---

## Section 3: Database Change Validation

**When:** Any table, column, RLS, GRANT, trigger, or constraint changes.  
**Skill:** `operations/database-change-validation.md`

Run the applicable sections from the validation skill:

| Condition | Validation Skill Section |
|-----------|-------------------------|
| New tables | Section 1: Tables without GRANTs, RLS, policies, triggers |
| Column/constraint changes | Section 2: CHECK constraint alignment |
| RLS policy changes | Section 3: Policy inventory for affected tables |
| Role/enum changes | Section 4: Role alignment with lookup tables |
| FK changes | Section 5: Foreign key ON DELETE review |
| Namespace changes | Section 6: Namespace default workspace check |
| Any DB change | Section 7: Full validation summary |

**Pass criteria:** All validation queries return empty result (no violations).

---

## Section 4: Security Posture Validation

**When:** New views created, new functions created, or Supabase Security Advisor email received.  
**Skill:** `identity-security/security-validation-runbook.md`

| Check | Runbook Section | Quick Query |
|-------|----------------|-------------|
| Views: security_invoker | Section 1.1 | All views should have `security_invoker=true` |
| Functions: search_path | Section 2.1 | All SECURITY DEFINER functions should have `search_path` set |
| Tables: RLS enabled | Section 3.1 | No public tables with `rowsecurity = false` |
| Tables: RLS has policies | Section 3.2 | No tables with RLS enabled but zero policies |
| Tables: GRANTs exist | Section 3.3 | No tables missing authenticated GRANT |

**One-shot posture query:** Run Section 4 "Full Security Posture Summary" for a single-query dashboard.

**Pass criteria:** All categories show ✅.

---

## Section 5: Architecture Manifest Update

**When:** Any new architecture documents, skills, or runbooks were created or versioned this session.  
**Document:** `MANIFEST.md` (architecture repo root)

| Check | Action |
|-------|--------|
| New documents created? | Add to manifest with version, status, description |
| Existing documents versioned? | Update version number in manifest |
| Documents superseded? | Move old version to archive section, update status |
| Manifest version bumped? | Increment version, add changelog entry |

**Pass criteria:** All documents produced this session are cataloged in the manifest.

---

## Section 6: Deploy Reminder

**When:** Claude Code commits were made that modify production-visible features.

Remind Stuart to:
1. **Commit** changes in Claude Code / local repo
2. **Push** to `dev` branch on GitHub
3. **Merge** `dev` → `main` to trigger Netlify production deployment
4. **Verify** the change is live on `nextgen.getinsync.ca`

**Skip if:** Changes were localhost-only testing or database-only (no UI).

---

## Section 6b: Schema Backup

**When:** Any database changes this session (new tables, columns, constraints, triggers, functions, views).

### pg_dump Command

```bash
cd ~/Dev/getinsync-nextgen-ag
pg_dump --schema-only --no-owner --no-privileges \
  "postgresql://postgres.zwwuogquncqvwuzbppiq:DB_PASSWORD@aws-1-ca-central-1.pooler.supabase.com:5432/postgres" \
  > getinsync-nextgen-schema-YYYY-MM-DD.sql
```

**Connection details:**
- **User:** `postgres.zwwuogquncqvwuzbppiq`
- **Host:** `aws-1-ca-central-1.pooler.supabase.com`
- **Port:** `5432`
- **Database:** `postgres`
- **Password:** Stuart provides per session — DO NOT store in docs. Roll after use.

### Verify Dump

```bash
ls -la getinsync-nextgen-schema-YYYY-MM-DD.sql
head -20 getinsync-nextgen-schema-YYYY-MM-DD.sql
```

Expected: ~500-700KB file, starts with `-- PostgreSQL database dump`.

### Commit to Code Repo

```bash
git add getinsync-nextgen-schema-YYYY-MM-DD.sql
git commit -m "Schema backup YYYY-MM-DD: [brief description of changes]"
git push origin dev
```

### Copy to Architecture Repo

```bash
cp getinsync-nextgen-schema-YYYY-MM-DD.sql ~/getinsync-architecture/schema/nextgen-schema-current.sql
```

This ensures the architecture repo always has the latest schema. The dated copy stays in the code repo for history.

### Post-Backup

- **Roll database password** in Supabase Dashboard → Settings → Database
- **Update Claude Code `.env` file** — `~/Dev/getinsync-nextgen-ag/.env` contains the DB password for read-only access. Update it with the new password after rolling.
- Claude Code/Netlify are NOT affected by password changes (use API keys, not DB password)

---

## Section 6c: Architecture Repo Sync

**When:** Architecture documents were created or updated this session (from this chat OR Claude Code), OR schema backup was taken.

### Two Repos, Two Commits

| Repo | Path | Branch | Contains |
|------|------|--------|----------|
| **Code** | `~/Dev/getinsync-nextgen-ag` | `dev` | Application code, schema backups |
| **Architecture** | `~/getinsync-architecture` | `main` | Architecture docs, current schema, manifest |

Claude Code accesses architecture docs via the symlink `./docs-architecture/` → `~/getinsync-architecture/`.

### Checklist

| # | Check | Action |
|---|-------|--------|
| 1 | New docs produced in this chat? | Stuart copies to `~/getinsync-architecture/` in correct folder |
| 2 | Claude Code modified `docs-architecture/`? | Verify Claude Code committed and pushed the architecture repo |
| 3 | Schema backup taken (Section 6b)? | Copy dated schema to `~/getinsync-architecture/schema/nextgen-schema-current.sql` |
| 4 | Manifest updated (Section 5)? | Ensure `MANIFEST.md` in architecture repo reflects changes |
| 5 | Architecture repo clean? | Run verification below |

### Verification

```bash
cd ~/getinsync-architecture && git status && git log --oneline -3 && cd ~/Dev/getinsync-nextgen-ag
```

**Expected:** Clean working tree, latest commit matches this session's work.

### When This Chat Produces Documents

This Claude Project chat cannot push to git. When architecture docs are created here:

1. Stuart downloads the file from this chat
2. Stuart copies it to the correct folder in `~/getinsync-architecture/`
3. Stuart commits and pushes:
   ```bash
   cd ~/getinsync-architecture
   git add -A
   git commit -m "docs: [description of new/updated doc]"
   git push
   cd ~/Dev/getinsync-nextgen-ag
   ```

**Pass criteria:** `git status` in `~/getinsync-architecture` shows clean working tree, latest commit matches this session's work.

---

## Section 6d: Automated Security Regression

**When:** Any database changes this session (tables, columns, RLS, GRANTs, triggers, views).  
**Test files:** `testing/pgtap-rls-coverage.sql` or `testing/security-posture-validation.sql`  
**Rule reference:** `operations/development-rules.md` §2.3

Run the security regression suite to verify no regressions across all tables, views, and triggers.

### Option A — Standalone (no extension required)

Paste `testing/security-posture-validation.sql` into Supabase SQL Editor.

- Expected: All rows show `PASS`, zero `FAIL` rows.
- Failures sort to top — investigate any before closing session.

### Option B — pgTAP (if extension enabled)

Paste `testing/pgtap-rls-coverage.sql` into Supabase SQL Editor.

- Expected: `Looks like you passed all 391 tests.`
- Any `not ok` line = FAIL → investigate before closing session.

### Option C — Via Claude Code read-only connection

```bash
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/security-posture-validation.sql
```

If the SQL file cannot run directly via psql, run the core checks individually:

```sql
-- RLS enabled on all tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND NOT rowsecurity;

-- Views without security_invoker
SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'v'
AND (c.reloptions IS NULL OR NOT c.reloptions::text[] @> ARRAY['security_invoker=true']);

-- Tables missing GRANT to authenticated
SELECT t.tablename FROM pg_tables t
WHERE t.schemaname = 'public'
AND NOT EXISTS (
  SELECT 1 FROM information_schema.table_privileges tp
  WHERE tp.table_schema = 'public' AND tp.table_name = t.tablename
  AND tp.grantee = 'authenticated' AND tp.privilege_type = 'SELECT'
);
```

All three queries must return **empty results** = PASS.

### If Sentinel Checks Fail

Sentinel checks detect new tables or views added without updating the test suite. If sentinel count mismatches appear, update the test files before committing — see development-rules.md §2.3 for the update procedure.

| Check | Result |
|-------|--------|
| Security regression (Option A or B) | ☐ All PASS |

**Pass criteria:** Zero failures across all checks.

---

## Section 6e: Code Quality Gate

**When:** Any session that modified frontend code (components, hooks, pages, utilities).

### 6e.1 — TypeScript Check

```bash
npx tsc --noEmit
```

**Expected:** Zero errors. This is the primary defense against type regressions.

### 6e.2 — ESLint Check

```bash
npm run lint
```

**Expected:** Zero errors. Warnings are tracked (baseline: 513 as of Feb 28, 2026) — new sessions must not increase the warning count.

| Rule | Severity | Baseline | Notes |
|------|----------|----------|-------|
| `no-debugger` | error | 0 | Never ship debugger statements |
| `no-var` | error | 0 | Use const/let |
| `prefer-const` | error | 0 | Use const when not reassigned |
| `no-console` (log only) | warn | 33 | Replace with proper logging over time |
| `no-alert` | warn | 32 | Replace with toast/modal (CLAUDE.md rule) |
| `eqeqeq` | warn | 42 | Should be === everywhere |
| `@typescript-eslint/no-explicit-any` | warn | 239 | Type properly over time |
| `@typescript-eslint/no-non-null-assertion` | warn | 86 | Add proper null checks |
| `react-hooks/exhaustive-deps` | warn | 79 | Fix dependency arrays |

### 6e.3 — Production Build

```bash
npm run build
```

**Expected:** Build succeeds. Catches Vite-specific issues that tsc alone misses.

### 6e.4 — File Size Check

If you modified a file this session, check if it's getting too large:

```bash
wc -l [modified files]
```

| Threshold | Action |
|-----------|--------|
| Under 500 lines | ✅ Fine |
| 500–800 lines | ⚠️ Consider splitting on next touch |
| Over 800 lines | ❌ Flag for refactoring — add to open items |

### 6e.5 — Impact Scan (repeat of CLAUDE.md cardinal rule)

If you changed a shared type, interface, view, or component:

```bash
grep -r "ChangedName" src/ --include="*.ts" --include="*.tsx"
```

Verify all consumers were updated. This prevents the "silent undefined" class of bug.

### Summary

| # | Check | Command | Pass Criteria |
|---|-------|---------|---------------|
| 1 | TypeScript | `npx tsc --noEmit` | Zero errors |
| 2 | ESLint | `npm run lint` | Zero errors, warnings ≤ baseline |
| 3 | Build | `npm run build` | Succeeds |
| 4 | File size | `wc -l` on modified files | No file > 800 lines without flagging |
| 5 | Impact scan | `grep` shared changes | All consumers updated |

**Pass criteria:** Checks 1-3 pass. Check 4 flags added to open items if needed. Check 5 confirmed.

---

## Section 6f: Bulletproof React Spot Check

**When:** Any session that modified frontend code (components, hooks, pages, utilities).
**This is informational only** — report findings but do not block the session or start fixing them.

### What to Scan

Run these checks against files **modified this session only** (not the entire codebase):

```bash
# 6f.1 — New any types in files you touched?
grep -rn ": any" [modified .ts and .tsx files]

# 6f.2 — Direct supabase calls in components (should be in hooks)?
grep -rn "supabase\.from\|supabase\.rpc" [modified .tsx files]

# 6f.3 — Components over 300 lines?
wc -l [modified .tsx files]
```

### How to Report

For each finding, note:
- **File and line number**
- **Whether it is NEW this session or PRE-EXISTING** (check git diff to determine)

Pre-existing violations are noted in the report but are not actionable. New violations are flagged for Stuart's awareness.

### What NOT to Do

- Do NOT fix violations unless Stuart explicitly asks
- Do NOT refactor existing code to match these patterns
- Do NOT block the session or delay handover for these findings
- This is a **health check**, not a **refactoring trigger**

### Summary

| # | Check | What to Report |
|---|-------|---------------|
| 1 | New `any` types | Count + file:line for new-this-session only |
| 2 | Direct supabase in components | Count + file:line for new-this-session only |
| 3 | Oversized components (over 300 lines) | List files + line counts |

**Pass criteria:** Report produced. No blocking — all findings are informational.

---

## Section 6g: Data Quality Spot Check

**When:** Any session where data was seeded, migrated, or enum/status columns were touched. Also run as a periodic health check.
**Test file:** `testing/data-quality-validation.sql`
**Added:** March 3, 2026 — after discovering two silent data bugs: enum casing mismatch (`business_assessment_status = 'Not Started'` vs `'not_started'`) and deployment profile naming violations (`dp.name = app.name`).

### Why This Exists

Schema constraints (CHECK, NOT NULL, FK) validate structure but cannot catch:
- **Casing mismatches** — `'Not Started'` passes a CHECK for `IN ('not_started', 'Not Started')` but the frontend compares against `'not_started'` only
- **Naming convention violations** — `dp.name = app.name` is valid text but breaks the prefix-stripping display logic
- **Placeholder values** — `'UNKNOWN'` or empty strings are valid text but produce broken UI

These bugs are **silent** — no compile error, no runtime error, just wrong data on screen.

### How to Run

#### Option A — Supabase SQL Editor (recommended)

Paste the contents of `testing/data-quality-validation.sql` into Supabase SQL Editor.

- Run all statements sequentially
- Expected: All checks show `PASS`
- Any `FAIL` row shows the bad value and affected row count

#### Option B — Via Claude Code read-only connection

```bash
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/data-quality-validation.sql
```

#### Option C — Quick Summary Only

Run just the `SUMMARY` section at the bottom of the script for a single-glance dashboard. If any row shows `FAIL`, run the individual check for details.

### What It Checks

| # | Check | What It Catches |
|---|-------|-----------------|
| 1 | Assessment status values | Casing mismatches: `'Not Started'` vs `'not_started'` |
| 2 | DP naming convention | Primary DPs where `name = app name` (missing env/region suffix) |
| 3 | Placeholder detection | Region/environment with `UNKNOWN`, empty string, `N/A`, `TBD` |
| 4 | Operational status | Invalid values in `deployment_profiles` or `applications` |
| 5 | Lifecycle status | Invalid values in `applications.lifecycle_status` |
| 6 | Remediation effort casing | Lowercase `'xs'` instead of `'XS'` across 3 tables |
| 7 | PAID action casing | Title-case `'Plan'` instead of `'plan'` |
| 8 | Hosting type values | Invalid hosting types in `deployment_profiles` |
| 9 | Namespace tier | Legacy tier names (`free`, `pro`, `full`) instead of `trial`/`essentials`/`plus`/`enterprise` |
| 10 | Contact categories | Invalid values in `contacts.contact_category` |
| 11 | Initiative/idea/program status | Invalid status values in value creation tables |
| 12 | Integration status | Invalid status values in `application_integrations` |
| 13 | DP type | Invalid `dp_type` values |
| 14 | Role values | Invalid roles in `namespace_users` and `workspace_users` |

### If Checks Fail

1. Identify the bad values from the detailed check output
2. Write a repair SQL script (UPDATE + WHERE clause targeting bad values)
3. Run the repair in Supabase SQL Editor
4. Re-run the validation to confirm all PASS
5. Add the root cause to Common Pitfalls in `database-change-validation.md`

### Summary

| Check | Result |
|-------|--------|
| Data quality (14 checks) | All PASS |

**Pass criteria:** All 14 checks return PASS. Zero FAIL rows.

---

## Section 7: Session Handover Document

**When:** Always — every session that did meaningful work.

Produce a `session-summary-YYYY-MM-DD.md` covering:

| Section | What to include |
|---------|-----------------|
| **Completed** | SQL applied, Claude Code changes, architecture decisions made |
| **Database changes** | Tables created/modified, RLS policies, triggers, functions, views |
| **Frontend changes** | Claude Code commits, components modified |
| **Files created** | Architecture docs, skills, runbooks |
| **Validation results** | Pass/fail for each check run from Sections 2–6g |
| **Repo status** | Both repos committed and pushed? |
| **Still open** | Bugs, next steps, pending work |
| **Context for next session** | What the next Claude instance needs to know |

---

## Section 8: Monthly SOC2 Evidence (If Applicable)

**When:** First session of each month, or when explicitly requested.  
**Skill:** `identity-security/soc2-evidence-collection.md`

| Check | Action |
|-------|--------|
| Run `generate_soc2_evidence()` RPC | Produces monthly snapshot JSON |
| Name file per convention | `GIS-SOC2-EV-{seq}-{YYYY}-{MM}-{DD}.json` |
| Compare to previous month | Note any variance in table/policy/trigger counts |
| Log in evidence index | Update `identity-security/soc2-evidence-index.md` if it exists |

**Pass criteria:** Snapshot collected, named correctly, variance explained.

---

## Section 9: Cross-Document Stats Alignment

**When:** Any database changes this session (tables, triggers, views, policies, functions).  
**Purpose:** Prevent stat drift across documents that reference database counts.

### 9.1 — Collect Current Stats

Run this single query to get the source of truth:

```sql
SELECT
  (SELECT count(*) FROM pg_tables WHERE schemaname = 'public') as tables,
  (SELECT count(*) FROM pg_policies WHERE schemaname = 'public') as rls_policies,
  (SELECT count(DISTINCT trigger_name) FROM information_schema.triggers 
   WHERE trigger_schema = 'public' AND trigger_name LIKE 'audit_%') as audit_triggers,
  (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace 
   WHERE n.nspname = 'public' AND c.relkind = 'v') as views,
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
   AND NOT EXISTS (
     SELECT 1 FROM pg_depend d
     WHERE d.objid = p.oid AND d.deptype = 'e'
   )) as functions;
```

### 9.2 — Check for Drift

Compare the query results against these documents. If any are stale, flag for update:

| Document | Section | What to Check |
|----------|---------|---------------|
| `MANIFEST.md` | Schema Statistics | tables, views, functions, RLS policies, audit triggers, schema backup date |
| `identity-security/soc2-evidence-index.md` | Current Readiness Score + CC6.6 rows | table count, trigger count, policy count |
| `identity-security/security-posture-overview.md` | Timeline section + body stats | table count, trigger count, policy count, view count |
| Claude memory | SOC2 + RLS memory entries | table count, trigger count |

### 9.3 — Auto-Update Drifted Docs

| Scenario | Action |
|----------|--------|
| Stats match everywhere | PASS — no action |
| Stats drifted in any doc | **Update the doc now** with correct counts from the live query. Do not defer. |
| Schema backup date is stale | Flag in Section 6b |

After updating, commit the architecture repo:
```bash
cd ~/getinsync-architecture
git add -A
git commit -m "docs: stats alignment"
git push
cd ~/Dev/getinsync-nextgen-ag
```

If running in Claude Project chat (no git access), produce the updated doc sections for Stuart to copy.

**Pass criteria:** All documents reference the same table/trigger/policy counts. No drift deferred.

---

## Section 10: Open Items Maintenance

**When:** Every session — this is how the backlog stays alive.  
**Document:** `planning/open-items-priority-matrix.md`

### 10.1 — Harvest New Items

Review the session for anything that was:
- Discovered but not fixed (bugs, design debt, data quality issues)
- Deferred deliberately ("parked", "future", "not today")
- Promised but not delivered (Claude Code changes sent but unconfirmed)
- Dependencies identified (X blocks Y)

### 10.2 — Classify New Items

| Priority | Criteria |
|----------|----------|
| **HIGH** | Blockers, schema issues, critical path items |
| **MED** | Security/compliance gaps, SOC2 policy gaps, enablement blockers |
| **LOW** | UI polish, cosmetic bugs, future features |

### 10.3 — Close Completed Items

Move items to the "Completed This Session" section with resolution notes. Don't just delete them — the audit trail matters.

### 10.4 — SOC2 Policy Gap Check

Reference `identity-security/soc2-evidence-index.md` § "Policy Documents Needed":

| Policy | Status | Priority |
|--------|--------|----------|
| Information Security Policy | ⬜ Not started | HIGH — before Knowledge |
| Change Management Policy | ⬜ Not started | HIGH — before Knowledge |
| Incident Response Plan | ⬜ Not started | HIGH — before Knowledge |
| Acceptable Use Policy | ⬜ Not started | MED — before first enterprise deal |
| Data Classification Policy | ⬜ Not started | MED — before first enterprise deal |
| Business Continuity Plan | ⬜ Not started | MED — before first enterprise deal |
| Vendor Management Policy | ⬜ Not started | LOW — before SOC2 audit |
| Data Retention Policy | ⬜ Not started | LOW — already enforced in code |

When any policy is drafted, update both this table AND the evidence index.

### 10.5 — Reproduce Updated List

If items were added or completed, produce an updated open items priority matrix (no date suffix — one file, always current) and present it to Stuart for upload to the project.

**Pass criteria:** All new items captured, completed items closed, SOC2 policy gap status current.

---

## Quick Reference: Document Map

| Document | What It Does | When Referenced |
|----------|-------------|-----------------|
| `operations/new-table-checklist.md` | Per-table creation checklist | New tables (Section 2) |
| `operations/database-change-validation.md` | SQL validation queries for DB changes | Any DB change (Section 3) |
| `identity-security/security-validation-runbook.md` | View/function/posture checks | New views/functions (Section 4) |
| `MANIFEST.md` | Master document catalog | New/updated docs (Section 5) |
| `identity-security/rls-policy-addendum.md` | RLS policy reference | Policy changes (Section 3) |
| `testing/pgtap-rls-coverage.sql` | pgTAP security regression (391 assertions) | Any DB change (Section 6d) |
| `testing/security-posture-validation.sql` | Standalone security validation (no extension) | Any DB change (Section 6d) |
| `testing/data-quality-validation.sql` | Enum casing, naming conventions, placeholder detection (14 checks) | Data seeding/migration (Section 6g) |
| `identity-security/soc2-evidence-collection.md` | Monthly evidence procedure | Monthly (Section 8) |
| `identity-security/soc2-evidence-index.md` | Trust criteria → evidence mapping | Stats alignment (Section 9), policy gaps (Section 10.4) |
| `identity-security/security-posture-overview.md` | External security overview | Stats alignment (Section 9) |
| `identity-security/user-registration.md` | Signup/invitation flows | SOC2 CC6.1 evidence |
| `planning/open-items-priority-matrix.md` | Prioritized backlog (living doc, overwritten each session) | Open items (Section 10) |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-10 | Initial document. 8 sections, dispatches to 6 skill documents. Replaces prose in dev rules section 4.3 with executable checklist. |
| v1.1 | 2026-02-11 | Added Section 6b: Schema Backup with pg_dump command, connection details, verify steps, git commit, and post-backup password roll. Added "Any database changes" trigger to Section 1. |
| v1.2 | 2026-02-12 | Added Section 9: Cross-Document Stats Alignment — prevents stat drift across manifest, evidence index, security overview, and memory. Added Section 10: Open Items Maintenance — harvests new items, classifies by priority, closes completed items, tracks SOC2 policy gaps, reproduces updated matrix. Updated Section 1 triggers to include "any work done" → Sections 9+10. Updated Document Map with evidence index, security overview, user registration, and open items matrix. |
| v1.3 | 2026-02-18 | Section 6b Post-Backup: Added reminder to update Claude Code `.env` file after rolling database password. Clarified AG/Netlify not affected. |
| v1.4 | 2026-02-23 | **Added Section 6c: Architecture Repo Sync** — dual-repo commit verification for `~/getinsync-architecture`. Covers docs produced in this chat (Stuart copies manually) and docs modified by Claude Code (via `./docs-architecture/` symlink). Includes schema backup copy step. Updated Section 1 triggers: architecture docs now trigger 6c, DB changes now trigger 6c. Updated Section 6b: added schema copy to architecture repo step. Updated Section 6 language: AG → Claude Code. Updated Section 7: added repo status row. Updated manifest reference to v1_25. Fixed mojibake throughout (CP1252 encoding artifacts). |
| v1.5 | 2026-02-23 | **Added Section 6d: Automated Security Regression.** Dispatches to `testing/pgtap-rls-coverage.sql` (391 assertions) or `testing/security-posture-validation.sql` (standalone). Updated Section 1 triggers: all DB change categories now include Section 6d. Updated Section 7: validation results reference updated to Sections 2–6d. Updated Document Map: added both test files, modernized all document paths from versioned filenames to stable repo paths. |
| v1.6 | 2026-02-28 | **Added Section 6e: Code Quality Gate.** 5 checks: TypeScript (`tsc --noEmit`), ESLint (`npm run lint`), production build, file size threshold, impact scan. ESLint + Prettier installed in codebase (eslint.config.js, .prettierrc). Baseline: 0 errors, 513 warnings. Updated Section 1 triggers: frontend changes now trigger Section 6e. |
| v1.7 | 2026-03-03 | **Added Section 6f: Bulletproof React Spot Check** (informational, non-blocking). **Added Section 6d Option C** (Claude Code psql). **Section 9.3:** mandatory auto-update, no more deferring drift. Updated Section 1 triggers and Section 7 to include 6f. |
| v1.8 | 2026-03-03 | **Added Section 6g: Data Quality Spot Check** — 14 checks for enum casing, DP naming conventions, placeholder values, role consistency. New test file `testing/data-quality-validation.sql`. Added data seeding trigger to Section 1. Updated Document Map. Born from two silent bugs: `business_assessment_status` casing mismatch and `dp.name = app.name` naming violation. |
| v1.9 | 2026-03-03 | **Section 9.1:** Fixed functions count query to exclude extension-owned functions (`pg_depend.deptype = 'e'`). Previous query returned ~1,128 (including Supabase/PostGIS built-ins); now returns ~54 (custom functions only). |

---

*Document: operations/session-end-checklist.md*  
*Trigger: End of every productive session, or when Stuart says "run session-end checklist"*  
*March 2026*
