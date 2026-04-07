# GetInSync NextGen — Session-End Checklist

**Version:** 1.20
**Date:** April 4, 2026
**Status:** ACTIVE
**Purpose:** Master checklist Claude executes at session end — dispatches to individual validation skills
**Trigger:** End of every session with database changes, or when Stuart says "run session-end checklist"

> **Note:** Do NOT run this full checklist after every mid-session database change. Use the **Mid-Session Schema Checkpoint** (CLAUDE.md) for that. This checklist runs once at session end.

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
| - | New tables created | → Run Section 2 (Security Posture, incl. §2.3 Namespace Seeding) + Section 6d (Security Regression) + Section 6j (AI Chat & Search Discovery) |
| - | Existing tables modified (columns, constraints) | → Run Section 3 (Deep Validation) + Section 6d (Security Regression) |
| - | RLS policies added or changed | → Run Section 6d (Security Regression) |
| - | GRANTs added or changed | → Run Section 6d (Security Regression) |
| - | New views or functions created | → Run Section 6d (Security Regression) + Section 6j (AI Chat & Search Discovery) |
| - | Audit triggers added | → Run Section 6d (Security Regression) |
| - | Role/enum changes, FK changes, namespace changes | → Run Section 3 (Deep Validation) |
| - | Architecture documents created or updated | → Run Section 5 (Manifest) + Section 6c (Architecture Repo) |
| - | Claude Code changes (UI/frontend) | → Run Section 6 (Deploy Reminder) + Section 6e (Code Quality Gate) + Section 6f (Bulletproof React Spot Check) + Section 6g (Data Quality) + Section 6h (User Documentation) + Section 6j (AI Chat & Search Discovery) |
| - | Data seeded, migrated, or enum/status columns touched | → Run Section 6g (Data Quality) |
| - | Any database changes at all | → Run Section 2 (Security Posture) + Section 6b (Schema Backup) + Section 6c (Architecture Repo) + Section 6d (Security Regression) + Section 6g (Data Quality) + Section 9 (Stats Alignment) |
| - | Secrets added/rotated, auth changes, Edge Function deploys | → Run Section 6i (SOC2 Evidence Checkpoint) |
| - | Any work done at all | → Run Section 7 (Handover) + Section 10 (Open Items) |
| - | No database changes | → Skip to Section 7 (Handover) + Section 10 (Open Items) |

---

## Section 2: Security Posture Validation

**When:** Any database changes this session (always run — not just when new tables are created).

### 2.1 — Bulk Safety Net (run every session with DB changes)

Run `testing/security-posture-validation.sql` via `$DATABASE_READONLY_URL`. It returns only violations — empty result = PASS.

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/security-posture-validation.sql
```

Covers 6 checks: table GRANTs (authenticated + service_role), RLS enablement, RLS policies, view security_invoker, DEFINER function search_path.

**Pass criteria:** Query returns zero rows. Any row = FAIL — investigate immediately.

**Why this runs every session:** Section 6d uses sentinel counts that must be updated manually. This bulk query catches violations regardless of sentinel freshness. It also catches accidental drops.

### 2.2 — Per-Table Checks (only when new tables are created)

When new tables are created this session, also verify these per-table checks:

| # | Check | Query |
|---|-------|-------|
| 1 | Audit trigger exists | `SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = '{table}' AND trigger_name LIKE '%audit%';` |
| 2 | updated_at trigger exists | `SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.{table}'::regclass AND tgname LIKE 'update_%_updated_at';` |

- **Audit trigger:** Required on business entity tables. Not required on reference tables, system tables, or junction tables.
- **updated_at trigger:** Required on tables with an `updated_at` column.

### 2.3 — Namespace Seeding Validation (only when new namespace-scoped tables are created)

When new tables with a `namespace_id` column are created, verify they have a seeding trigger.

```sql
-- Step 1: List all seeding trigger functions on the namespaces table
SELECT p.proname as seed_function
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class cl ON t.tgrelid = cl.oid
WHERE cl.relname = 'namespaces'
AND p.proname NOT LIKE 'RI_FKey_%'
AND p.proname NOT IN ('audit_log_trigger', 'update_updated_at_column')
ORDER BY p.proname;

-- Step 2: List all namespace-scoped reference-like tables (has namespace_id + is_active)
SELECT c.table_name as namespace_ref_table
FROM information_schema.columns c
WHERE c.column_name = 'namespace_id' AND c.table_schema = 'public'
AND c.table_name NOT LIKE 'vw_%'
AND EXISTS (
  SELECT 1 FROM information_schema.columns c2
  WHERE c2.table_name = c.table_name AND c2.column_name = 'is_active' AND c2.table_schema = 'public'
)
ORDER BY c.table_name;
```

Compare Step 1 against Step 2. Every table in Step 2 should have a seeding function OR be a known exception.

**Known exceptions:** `contacts`, `data_centers`, `organizations` (user-created data), `notification_rules`, `workflow_definitions` (future features).

---

## Section 3: Deep Database Validation (situational)

**When:** Column/constraint changes, role/enum changes, FK changes, or namespace changes.
**Skill:** `operations/database-change-validation.md`

| Condition | Validation Skill Section |
|-----------|-------------------------|
| Column/constraint changes | Section 2: CHECK constraint alignment |
| Role/enum changes | Section 3: Role consistency with lookup tables |
| FK changes | Section 4: Foreign key ON DELETE review |
| Namespace changes | Section 6: Namespace default workspace check |

**Pass criteria:** All validation queries return empty result (no violations).

> **Note:** Validation skill Section 1 (GRANTs, RLS, triggers) is redundant with §2.1 above. Skip it.

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
2. **Merge** feature branch into `dev` and push
3. **Merge** `dev` → `main` to trigger Netlify production deployment
4. **Verify** the change is live on `nextgen.getinsync.ca`

**Skip if:** Changes were localhost-only testing or database-only (no UI).

---

## Section 6b: Schema Backup

**When:** Any database changes this session (new tables, columns, constraints, triggers, functions, views).

### Option A — Using DATABASE_READONLY_URL (preferred, no password exchange needed)

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)
pg_dump --schema-only --no-owner --no-privileges "$DATABASE_READONLY_URL" \
  > getinsync-nextgen-schema-$(date +%Y-%m-%d).sql
```

> **Note:** `DATABASE_READONLY_URL` in `.env` already has credentials. If the read-only role lacks `pg_dump` permissions, use Option B.

### Option B — Using direct connection (requires Stuart to provide password)

```bash
cd ~/Dev/getinsync-nextgen-ag
pg_dump --schema-only --no-owner --no-privileges \
  "postgresql://postgres.zwwuogquncqvwuzbppiq:DB_PASSWORD@aws-1-ca-central-1.pooler.supabase.com:5432/postgres" \
  > getinsync-nextgen-schema-$(date +%Y-%m-%d).sql
```

**Password:** Stuart provides per session — DO NOT store in docs. Roll after use.

### Post-Dump Steps

1. Verify: `ls -la` and `head -20` — expect ~800-900KB, starts with `-- PostgreSQL database dump`
2. Commit to code repo: `git add getinsync-nextgen-schema-$(date +%Y-%m-%d).sql && git commit -m "chore: schema backup $(date +%Y-%m-%d)"`
3. **CRITICAL — Copy to architecture repo (this step has been missed before, causing stale schema refs):**
   ```bash
   cp getinsync-nextgen-schema-$(date +%Y-%m-%d).sql ~/getinsync-architecture/schema/nextgen-schema-current.sql
   cd ~/getinsync-architecture
   git add schema/nextgen-schema-current.sql
   git commit -m "chore: schema backup $(date +%Y-%m-%d)"
   git push origin main
   cd ~/Dev/getinsync-nextgen-ag
   ```
4. *(Option B only)* Roll database password in Supabase Dashboard → Settings → Database
5. *(Option B only)* Update `~/Dev/getinsync-nextgen-ag/.env` with new password

### Validation — Verify Both Files Match

After completing the dump and copy, verify the two files are identical:

```bash
diff getinsync-nextgen-schema-$(date +%Y-%m-%d).sql docs-architecture/schema/nextgen-schema-current.sql
```

If `diff` produces output, the copy step failed — re-run step 3.

---

## Section 6c: Architecture Repo Sync

**When:** Architecture documents were created or updated this session, OR schema backup was taken.

Follow the **Dual-Repo Commits** procedure in CLAUDE.md. Then verify:

```bash
cd ~/getinsync-architecture && git status && git log --oneline -3 && cd ~/Dev/getinsync-nextgen-ag
```

**Pass criteria:** Clean working tree, latest commit matches this session's work.

**When this chat (not Claude Code) produces documents:** Stuart downloads and copies to `~/getinsync-architecture/`, then commits and pushes manually.

---

## Section 6d: Automated Security Regression

**When:** Any database changes this session.
**Test files:** `testing/pgtap-rls-coverage.sql` and `testing/security-posture-validation.sql`

Run both scripts via `$DATABASE_READONLY_URL`:

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

# Script 1 — Standalone security validation
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/security-posture-validation.sql

# Script 2 — pgTAP regression suite (strip CREATE EXTENSION on line 25)
sed '25d' ./docs-architecture/testing/pgtap-rls-coverage.sql > /tmp/pgtap-noext.sql
psql "$DATABASE_READONLY_URL" -f /tmp/pgtap-noext.sql
```

- Script 1: All rows `PASS`, zero `FAIL`.
- Script 2: All assertions `ok N`, zero `not ok`. Sentinel checks (last 3) confirm table/view/trigger counts.
- **If sentinel checks fail:** Update sentinel values in both test files before committing (see `development-rules.md` §2.3).
- **Fallback:** Supabase SQL Editor if psql unavailable.

**Pass criteria:** Zero failures across both scripts.

---

## Section 6e: Code Quality Gate

**When:** Any session that modified frontend code.

### Checks

| # | Check | Command | Pass Criteria |
|---|-------|---------|---------------|
| 1 | TypeScript | `npx tsc --noEmit` | Zero errors |
| 2 | ESLint | `npm run lint` | Zero errors, warnings <= baseline (513) |
| 3 | Build | `npm run build` | Succeeds |
| 4 | File size | `wc -l` on modified files | No file > 800 lines without flagging |
| 5 | Impact scan | `grep` shared changes | All consumers updated |

### ESLint Rule Reference

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

### File Size Thresholds

| Threshold | Action |
|-----------|--------|
| Under 500 lines | Fine |
| 500-800 lines | Consider splitting on next touch |
| Over 800 lines | Flag for refactoring — add to open items |

**Pass criteria:** Checks 1-3 pass. Check 4 flags added to open items if needed. Check 5 confirmed.

---

## Section 6f: Bulletproof React Spot Check

**When:** Any session that modified frontend code.
**This is informational only** — report findings but do not block the session or start fixing them.

Run against files **modified this session only**:

```bash
# New any types?
grep -rn ": any" [modified .ts and .tsx files]

# Direct supabase calls in components (should be in hooks)?
grep -rn "supabase\.from\|supabase\.rpc" [modified .tsx files]

# Components over 300 lines?
wc -l [modified .tsx files]
```

For each finding, note file:line and whether it is NEW this session or PRE-EXISTING (check git diff).

**Do NOT fix violations unless Stuart asks. Do NOT block the session for these findings.**

---

## Section 6g: Data Quality Spot Check

**When:** Data seeded, migrated, or enum/status columns touched. Also run as periodic health check.
**Test file:** `testing/data-quality-validation.sql`

```bash
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/data-quality-validation.sql
```

14 checks covering: enum casing (assessment status, remediation effort, PAID actions), DP naming conventions, placeholder detection, operational/lifecycle status values, hosting types, namespace tiers, contact categories, integration status, DP types, role values, initiative/idea/program status. See script for full details.

**If checks fail:** Identify bad values, write repair SQL, run in Supabase SQL Editor, re-validate, add root cause to `database-change-validation.md`.

**Pass criteria:** All 14 checks return PASS. Zero FAIL rows.

---

## Section 6h: User Documentation — Write It Now

**When:** Any session that added or changed user-facing behavior.
**Full procedure:** `operations/session-end-user-docs.md`

**Quick checklist:**
1. Did this session change user-facing behavior? (new screens, changed workflows, renamed labels, new features, changed permissions)
2. If yes: determine tier (Minor/Moderate/Major) per the procedure doc
3. Find and update the right guide in `guides/user-help/` or `guides/`
4. Append a What's New entry to `guides/whats-new.md`
5. Update `feature-walkthrough.md` if applicable (Moderate/Major changes)
6. Bump version in `package.json` if user-visible features shipped (CalVer: `YYYY.MM.patch`)
7. Commit to architecture repo

**Pass criteria:** All user-facing changes have corresponding documentation written and committed this session. No deferred flags.

---

## Section 6j: AI Chat & Global Search Discovery Check

**When:** Any session that created new tables, views, or added queryable columns to existing tables.
**Purpose:** AI Chat and Global Search are both hardcoded — new schema objects are invisible until explicitly registered. This check prevents features from shipping without discoverability.

### What to Check

Neither AI Chat nor Global Search auto-discovers new schema objects. Both must be manually updated:

| System | Registration Files | Discovery Method |
|--------|-------------------|------------------|
| **AI Chat** | `supabase/functions/ai-chat/tools.ts` (tool definitions + execution), `supabase/functions/ai-chat/system-prompt.ts` (tool descriptions) | Hardcoded tools that query specific views |
| **Global Search** | `global_search` RPC in database (entity type list), `src/components/shared/AppHeader.tsx` (navigation routing) | Hardcoded RPC with entity-specific WITH clauses |
| **Semantic Layer** | `docs-architecture/features/ai-chat/semantic-layer.yaml` | Reference doc — not enforced by code |

### 6j.1 — Identify New Schema Objects

List all tables, views, and significant columns added this session:

```bash
# Quick check: what did this session add?
# Compare against tools.ts and global_search to find gaps
grep -o "from('[^']*')" supabase/functions/ai-chat/tools.ts | sort -u
# → These are the views AI Chat knows about

# Check global_search entity types
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)
/opt/homebrew/opt/libpq/bin/psql "$DATABASE_READONLY_URL" -c "
  SELECT pg_get_functiondef(oid)
  FROM pg_proc
  WHERE proname = 'global_search'
  AND pronamespace = 'public'::regnamespace;" | grep -o "AS [a-z_]*_results" | sort
# → These are the entities Global Search knows about
```

### 6j.2 — Gap Analysis

For each new table or view created this session, answer:

| New Object | Should AI Chat query it? | Should Global Search include it? | Action |
|---|---|---|---|
| *[list each new table/view]* | Yes/No — would users ask natural language questions about this data? | Yes/No — would users search for these entities by name? | Add tool / Add RPC clause / No action needed |

**Guidance:**
- **New business entity tables** (e.g., `teams`, `contracts`) → likely need both AI Chat + Global Search
- **New reporting views** (e.g., `vw_contract_expiry`) → likely need AI Chat tool, not Global Search
- **Junction tables** (e.g., `it_service_software_products`) → usually neither
- **Reference tables** (e.g., `cost_model_types`) → usually neither
- **New columns on existing tables** → check if existing AI Chat tools should expose them

### 6j.3 — Action Items

If gaps are found:

1. **AI Chat gap:** Create an open item: "AI Chat: add [tool-name] tool for [view/table]" with the view name, key columns to expose, and example user questions it should answer. Include in the current session if time allows, or add to open items matrix.

2. **Global Search gap:** Create an open item: "Global Search: add [entity] to global_search RPC" with the table name, searchable columns, category label, and icon. Requires SQL script (Stuart runs) + `AppHeader.tsx` navigation update.

3. **Semantic Layer gap:** Update `docs-architecture/features/ai-chat/semantic-layer.yaml` with new view/table mappings. This is documentation-only but keeps the reference current.

**Pass criteria:** All new queryable schema objects have been assessed. Gaps are either resolved in-session or captured as open items with enough detail to implement later.

---

## Section 6i: SOC2 Evidence Checkpoint

**When:** Every session — quick scan for SOC2-relevant changes that need documentation.
**Reference:** `identity-security/soc2-evidence-index.md`, `identity-security/secrets-inventory.md`

| Change This Session | SOC2 Control | Action Required |
|---------------------|-------------|-----------------|
| New or rotated API keys / secrets | CC6.1, CC6.3, CC6.6 | Update `secrets-inventory.md` |
| New or modified RLS policies | CC6.1 | Verify evidence-index stats are current |
| New Edge Functions deployed | CC6.3 | Update `secrets-inventory.md` Consumer(s) column |
| Auth flow changes | CC6.1 | Update `identity-security/identity-security.md` |
| New tables with sensitive data | CC6.2, C1.1 | Verify data classification is documented |
| Infrastructure changes | A1.1, A1.2 | Update relevant evidence-index section |
| New third-party integrations | CC6.7 | Document in vendor management |

| Check | Result |
|-------|--------|
| Did this session create/rotate/add secrets? | Yes → Update `secrets-inventory.md` / No |
| Did this session change auth or access control? | Yes → Update `identity-security.md` / No |
| Did this session deploy new Edge Functions? | Yes → Update `secrets-inventory.md` consumers / No |
| Did this session close any SOC2 gaps? | Yes → Update `soc2-evidence-index.md` gap status / No |

**Pass criteria:** All SOC2-relevant changes captured in appropriate evidence documents.

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
| **Validation results** | Pass/fail for each check run from Sections 2-6i |
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

**When:** Any database changes this session.
**Purpose:** Prevent stat drift across documents that reference database counts.

### 9.1 — Collect Current Stats

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

Compare query results against these documents and update if stale:

| Document | Section | What to Check |
|----------|---------|---------------|
| `MANIFEST.md` | Schema Statistics | tables, views, functions, RLS policies, audit triggers, schema backup date |
| `identity-security/soc2-evidence-index.md` | Current Readiness Score + CC6.6 rows | table count, trigger count, policy count |
| `identity-security/security-posture-overview.md` | Timeline section + body stats | table count, trigger count, policy count, view count |
| Claude memory | SOC2 + RLS memory entries | table count, trigger count |

### 9.3 — Auto-Update Drifted Docs

If stats drifted, **update the doc now** — do not defer. After updating, commit the architecture repo.

**Pass criteria:** All documents reference the same table/trigger/policy counts. No drift deferred.

---

## Section 10: Open Items Maintenance

**When:** Every session — this is how the backlog stays alive.
**Document:** `planning/open-items-priority-matrix.md`

### 10.1 — Harvest New Items

Review the session for: bugs discovered but not fixed, work deferred, promises undelivered, dependencies identified.

### 10.2 — Classify New Items

| Priority | Criteria |
|----------|----------|
| **HIGH** | Blockers, schema issues, critical path items |
| **MED** | Security/compliance gaps, SOC2 policy gaps, enablement blockers |
| **LOW** | UI polish, cosmetic bugs, future features |

### 10.3 — Close Completed Items

Move to "Completed This Session" with resolution notes. Don't delete — audit trail matters.

### 10.4 — SOC2 Policy Gap Check

Reference `identity-security/soc2-evidence-index.md` § "Policy Documents Needed" for the current status of required SOC2 policies. When any policy is drafted, update both the evidence index and the open items matrix.

### 10.5 — Reproduce Updated List

If items were added or completed, produce an updated open items priority matrix and present to Stuart.

**Pass criteria:** All new items captured, completed items closed, SOC2 policy gap status current.

---

## Next Session Setup

When producing the handoff document, always include a suggested opening message:

> **Phase [XX] — [Short Description]**  e.g. "Phase 27c — AI Lookup Edge Function"

This becomes the auto-title for the session in the Claude Code session list. The opening message should be the **FIRST** thing pasted into the new Claude Code session.

---

## Quick Reference: Document Map

| Document | What It Does | When Referenced |
|----------|-------------|-----------------|
| `operations/new-table-checklist.md` | Per-table creation checklist | New tables (Section 2) |
| `operations/database-change-validation.md` | Deep validation (CHECK, roles, FKs, namespaces) | Situational (Section 3) |
| `operations/session-end-user-docs.md` | Full user documentation procedure | User-facing changes (Section 6h) |
| `MANIFEST.md` | Master document catalog | New/updated docs (Section 5) |
| `identity-security/rls-policy-addendum.md` | RLS policy reference | Policy changes (Section 3) |
| `testing/pgtap-rls-coverage.sql` | pgTAP security regression | Any DB change (Section 6d) |
| `testing/security-posture-validation.sql` | Standalone security validation | Any DB change (Section 6d) |
| `testing/data-quality-validation.sql` | Enum casing, naming conventions (14 checks) | Data seeding/migration (Section 6g) |
| `identity-security/soc2-evidence-collection.md` | Monthly evidence procedure | Monthly (Section 8) |
| `identity-security/soc2-evidence-index.md` | Trust criteria → evidence mapping | Stats (Section 9), policy gaps (Section 10.4), SOC2 (Section 6i) |
| `identity-security/secrets-inventory.md` | API key/secret inventory + rotation | SOC2 checkpoint (Section 6i) |
| `identity-security/security-posture-overview.md` | External security overview | Stats alignment (Section 9) |
| `guides/user-help/*.md` | End-user help articles (9 articles for GitBook) | User doc check (Section 6h) |
| `supabase/functions/ai-chat/tools.ts` | AI Chat tool definitions + execution | AI Chat discovery (Section 6j) |
| `supabase/functions/ai-chat/system-prompt.ts` | AI Chat tool descriptions for Claude | AI Chat discovery (Section 6j) |
| `features/ai-chat/semantic-layer.yaml` | Business concept → view mapping reference | AI Chat discovery (Section 6j) |
| `src/components/shared/AppHeader.tsx` | Global Search navigation routing | Search discovery (Section 6j) |
| `planning/open-items-priority-matrix.md` | Prioritized backlog (living doc) | Open items (Section 10) |

---

*Change log: see `operations/session-end-checklist-changelog.md`*

*Document: operations/session-end-checklist.md*
*Trigger: End of every productive session, or when Stuart says "run session-end checklist"*
*April 2026*
