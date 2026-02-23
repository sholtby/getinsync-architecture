# GetInSync Development Rules & Workflow Standards

**Version:** 1.5  
**Date:** February 23, 2026  
**Status:** 🟢 ACTIVE  
**Purpose:** Codified rules for Claude Project ↔ Stuart ↔ Claude Code collaboration

---

## 1. Frontend Development Rules (Claude Code)

> **As of February 17, 2026, Claude Code is the primary frontend development tool.** AG (Antigravity/bolt.new) remains available as a fallback but is no longer the default. Claude Code reads `CLAUDE.md` in the repo root automatically at session start — that file contains architecture rules, impact analysis requirements, and the "do not" list.

### 1.1 Claude Code Is Frontend Only
Claude Code does not modify the database schema. Stuart handles all schema changes via Supabase SQL Editor. Claude Code builds React/TypeScript/Tailwind UI components against the existing schema.

**Exception:** Claude Code can run `SELECT` queries for diagnostic purposes (e.g., checking view definitions, verifying data shapes).

### 1.2 Always Run Impact Analysis Before Changes
Before modifying any view, type, interface, or shared component, Claude Code must:

```bash
grep -r "name_being_changed" src/ --include="*.ts" --include="*.tsx"
```

Then update ALL affected files — not just the one being worked on. This is enforced in `CLAUDE.md` and prevents the class of bug where changing one thing silently breaks another (e.g., the budget view incident).

### 1.3 Never Hardcode What Belongs in the Database
Dropdowns, option lists, role labels, status values, categories, and any other enumerable data must come from database reference tables — never from hardcoded arrays in React components or TypeScript constants.

If a dropdown doesn't have a reference table yet, the correct answer is "we need to create one" — not `const options = ['Active', 'Planned', 'Deprecated']`.

**Reference tables (as of Feb 17, 2026):**
- `criticality_types` — integration criticality levels
- `integration_direction_types` — upstream/downstream/bidirectional
- `integration_method_types` — api/file/database/sso/manual/event/other
- `integration_frequency_types` — real_time/batch_daily/weekly/monthly/on_demand
- `integration_status_types` — planned/active/deprecated/retired
- `data_format_types` — json/xml/csv/xlsx/etc
- `sensitivity_types` — low/moderate/high/confidential
- `data_classification_types` — public/internal/confidential/restricted
- `data_tag_types` — data classification tags
- `namespace_role_options` — namespace-level roles
- `workspace_role_options` — workspace-level roles
- `countries` — ISO country codes
- `environments` — PROD, DEV, TEST, etc.
- `hosting_types` — SaaS, On-Prem, Cloud, etc.
- `cloud_providers` — AWS, Azure, GCP, etc.
- `dr_statuses` — disaster recovery statuses
- `lifecycle_statuses` — application lifecycle stages
- `remediation_efforts` — XS/S/M/L/XL/2XL t-shirt sizes
- `service_types` — IT Service categories

### 1.4 View-to-TypeScript Contract Enforcement
`src/types/view-contracts.ts` is the single source of truth for view-to-TypeScript mappings. When a database view changes:

1. Stuart updates the view in Supabase
2. Stuart updates `view-contracts.ts` to match the new columns
3. TypeScript compiler catches every consumer that needs updating

**Rule:** Components must import view types from `view-contracts.ts`, not define inline interfaces that duplicate view shapes.

### 1.5 Always Verify Clean Compile
Before completing any task, Claude Code must run:

```bash
npx tsc --noEmit
```

Zero errors required. If in doubt, also run `npm run build`.

### 1.6 Review Complex Implementation Plans Before Coding
For complex changes (new pages, multi-component features, architectural changes), present a brief implementation plan covering:
- Components to create/modify
- Data flow (what queries, what state)
- Key UX decisions
- Known risks or ambiguities

Get confirmation before writing code.

---

## 1A. AG Fallback Rules (When Using Antigravity)

> These rules apply only when AG is used as a fallback. They are retained from v1.3 for reference.

### 1A.1 Chunk AG Prompts
Never send AG a monolithic prompt with 10+ changes. Break into logical chunks of 3–5 related items. When possible, output to a code block vs. a file.

### 1A.2 Always Tell AG: No Schema, Only UI
Every AG prompt must include:

```
You are responsible for FRONTEND ONLY (React, TypeScript, Tailwind).
DO NOT create database migrations, modify tables, or write SQL.
The database schema is already deployed. Use the tables and views
described below exactly as specified.

DO NOT hardcode dropdown options, status values, or category lists
in the frontend. All option lists must be fetched from their
corresponding database reference table at runtime.
```

### 1A.3 Always Include Schema Context in AG Prompts
AG has no database access. Every prompt must include the relevant table definitions, view column lists, and Supabase query patterns. Don't assume AG remembers schema from previous prompts.

### 1A.4 Chunk Longer AG Prompts into Sequences
When an AG prompt exceeds ~500 lines, split into numbered chunks (1 of N, 2 of N). Each chunk should be self-contained and testable.

### 1A.5 Always Include a Test Script
End AG prompts with a manual testing checklist:

```
## Testing
- [ ] Create new record → verify save succeeds
- [ ] Edit existing record → verify correct record updated
- [ ] Check console for errors
- [ ] Test with empty state (no data)
```

---

## 2. SQL Rules

### 2.1 Always Chunk SQL Scripts as Sequential Code Blocks
Never paste a 200-line migration as a single block. Break into logical chunks and render each chunk as a **separate code block** in sequence. Each SQL code block must be immediately followed by a validation query code block. Stuart runs the chunk, confirms the validation passes, then Claude proceeds to the next chunk.

**Standard pattern:**
```
Chunk 1: Table/column changes → VERIFY
Chunk 2: Constraints and indexes → VERIFY
Chunk 3: RLS policies and GRANTs → VERIFY
Chunk 4: Seed data → VERIFY
Chunk 5: Views → VERIFY
```

**Do not** bundle all chunks into a single downloadable file. Present them inline as sequential code blocks so Stuart can execute and validate one at a time.

### 2.2 Always Validate After Major Changes
Run validation queries after any change to RLS, GRANTs, tables, or security. Use the validation skill (`operations/database-change-validation.md`) for the full checklist.

**Minimum post-change checks:**
```sql
-- After new table
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = 'new_table';

-- After GRANT
SELECT grantee, privilege_type FROM information_schema.table_privileges
WHERE table_name = 'new_table' AND grantee IN ('authenticated', 'service_role');

-- After RLS
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'new_table';

-- After audit trigger
SELECT trigger_name FROM information_schema.triggers
WHERE event_object_table = 'new_table' AND trigger_name LIKE '%audit%';
```

### 2.3 pgTAP Security Regression Suite
After any session with database changes, run the pgTAP security regression suite to verify no regressions across all tables. This supplements (not replaces) the manual validation in §2.2.

**Test suite location:** `testing/pgtap-rls-coverage.sql` in the architecture repo.

**What it tests (391 assertions):**
- RLS enabled on all 90 tables
- GRANT SELECT to `authenticated` on all 90 tables
- GRANT SELECT to `service_role` on all 90 tables
- Audit trigger present on 37 designated tables
- `security_invoker=true` on all 27 views
- GRANT SELECT to `authenticated` on all 27 views
- GRANT SELECT to `service_role` on all 27 views
- Sentinel checks: flags any new table/view added without test coverage

**Quick alternative:** `testing/security-posture-validation.sql` — standalone version requiring no extensions. Produces a single PASS/FAIL results table.

**When to update the test suite:**
- After adding a new table → add RLS + GRANT tests, update sentinel count
- After adding a new view → add security_invoker + GRANT tests, update sentinel count
- After adding a new audit trigger → add audit trigger test, update sentinel count

---

## 3. Schema Awareness

### 3.1 Always Read the Latest Schema
Before designing any feature that touches the database, read the current schema dump from project files:

```
nextgen-schema-current.sql
```

Never assume column names, types, or constraints from memory — verify against the schema.

---

## 4. Session Management

### 4.1 Always End with a Handover Document
When the context window is getting low on tokens (or at the end of a productive session), produce a session handover document covering:

1. **What was completed** — SQL applied, Claude Code changes, architecture decisions
2. **What's still open** — bugs, next steps, pending work
3. **Database changes** — tables created/modified, RLS, triggers, functions
4. **Frontend changes** — Claude Code commits, components modified
5. **Files created** — architecture docs, skills
6. **Context for next session** — what the next Claude instance needs to know

**Naming convention:** `session-summary-YYYY-MM-DD.md`

### 4.2 Remind to Commit, Push, and Deploy After Major UI Changes
After any significant UI change that needs to be accessible on production (`nextgen.getinsync.ca` via Netlify), remind Stuart to:

1. **Commit** changes in Claude Code / local repo
2. **Push** to `dev` branch on GitHub
3. **Merge** `dev` → `main` to trigger Netlify production deployment
4. **Verify** the change is live on `nextgen.getinsync.ca`

This applies when the change needs to be publicly accessible — not for localhost-only testing.

### 4.3 Session-End Compliance Pass
At the end of every session with database changes, execute the master checklist:

**→ `operations/session-end-checklist.md`**

This checklist determines which checks apply based on what changed, dispatches to the correct validation skills, and produces a pass/fail report in the session summary.

**Includes:** pgTAP security regression suite (§2.3) or standalone validation — run after any session with DB changes.

---

## 5. Quick Reference

| Rule | When | What |
|------|------|------|
| Impact analysis | Every Claude Code change | grep affected files before modifying views/types/components |
| View contracts | Every view change | Update view-contracts.ts, let TypeScript catch consumers |
| No hardcoded options | Every UI change | Dropdowns from reference tables, never arrays |
| Clean compile | Every Claude Code task | `npx tsc --noEmit` must pass |
| CLAUDE.md | Every Claude Code session | Auto-read — architecture rules + do-not list |
| Review complex plans | New pages, multi-component features | Implementation plan before coding |
| Chunk SQL as code blocks | Every migration | Sequential blocks + validation after each |
| Validate SQL | After RLS/GRANT/table/security changes | Run validation queries |
| **pgTAP regression** | **After any DB changes** | **Run `testing/pgtap-rls-coverage.sql` or standalone — all green** |
| Read latest schema | Before any DB design | `nextgen-schema-current.sql` |
| Handover document | Session end / low tokens | Full context for next session |
| Commit/push/deploy | After UI changes for production | dev → main → Netlify verify |
| Session-end checklist | Session end (if DB changes) | `operations/session-end-checklist.md` |

---

## 6. Tool Roles

| Tool | Role | When to Use |
|------|------|-------------|
| **Claude Project (Opus)** | Architecture, planning, SQL design, session management | Database design, architecture docs, complex decisions |
| **Claude Code** | Frontend development (React/TypeScript/Tailwind) | UI components, bug fixes, type migrations, refactoring |
| **AG (fallback)** | Frontend development | Only when Claude Code is unavailable |
| **Supabase SQL Editor** | Database changes | Stuart executes all schema changes directly |

**Key difference:** Claude Code reads the full codebase and runs `tsc`. AG works from prompts with no codebase access. Claude Code catches cross-file impacts; AG cannot.

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-09 | Initial document. AG rules, SQL rules, schema awareness, session management. |
| v1.1 | 2026-02-09 | Updated section 4.3 reference to overview doc (incorrect). |
| v1.2 | 2026-02-10 | Fixed section 4.3: compliance pass references runbook instead of overview. |
| v1.3 | 2026-02-10 | Replaced section 4.3 inline logic with dispatch to `operations/session-end-checklist.md`. Single source of truth for session-end process. |
| v1.4 | 2026-02-17 | **Claude Code replaces AG as primary frontend tool.** Section 1 rewritten for Claude Code workflow (impact analysis, view contracts, clean compile). AG rules moved to Section 1A as fallback. Added Section 6 (Tool Roles). Updated reference table list (+8 integration tables). Updated session-end checklist ref to v1_2. Updated session management language (AG → Claude Code). |
| v1.5 | 2026-02-23 | **Automated testing.** Added §2.3 (pgTAP security regression suite — 391 assertions across 90 tables, 27 views, 37 audit triggers). Updated §3.1 schema filename to stable name (no date suffix). Updated §4.3 to include pgTAP in session-end compliance pass. Added pgTAP regression row to Quick Reference table. Explicit GRANTs applied to all 90 tables (authenticated + service_role) — converted implicit schema defaults to auditable per-table grants. |

---

*Document: operations/development-rules.md*
