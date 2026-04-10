# Findings Report — workspaces.budget_amount Cleanup

**Date:** 2026-04-10
**Investigator:** Claude Code (read-only investigation session)
**Verdict:** **GREEN — already dropped**

---

## Executive Summary

The `workspaces.budget_amount` column that both `CLAUDE.md` files forbid reading **does not exist on the live database**. `information_schema.columns` returns zero rows for it, and `pg_attribute` shows a dropped-column placeholder (`........pg.dropped.9........`) at attnum=9 between `budget_fiscal_year` (attnum=8) and `budget_notes` (attnum=10) — the forensic signature of an `ALTER TABLE workspaces DROP COLUMN budget_amount` that ran at some prior point.

The CLAUDE.md forbid-rules are therefore vestigial. Zero TypeScript files, zero views, zero functions, and zero data rows reference the legacy column. The two bullets in each CLAUDE.md file (four bullets total across both repos) can be removed without risk, and no DROP-COLUMN migration is needed.

---

## Scope correction — the brief's "three tables" framing

The task brief states that the column name `budget_amount` appears on three tables (`workspaces`, `workspace_budgets`, `it_services`). Live-DB introspection shows `budget_amount` actually exists on **four** live tables plus two views:

| Table / View | budget_amount role |
|--------------|---------------------|
| `applications` | Per-app budget allocation (LIVE) |
| `it_services` | Per-IT-service budget capacity (LIVE) |
| `programs` | Per-program (roadmap) budget (LIVE) |
| `workspace_budgets` | Year-over-year workspace budget — the replacement for the dead column (LIVE) |
| `vw_program_summary` | Exposes `programs.budget_amount` (LIVE) |
| `vw_workspace_budget_history` | Exposes `workspace_budgets.budget_amount` (LIVE) |

The `workspaces` table does NOT appear in this list. All code and view references in this investigation were classified against the four-live-table reality, not the brief's three-table framing. The brief's framing caused no misclassification because the only live-but-missed tables (`applications`, `programs`) are in the same "LIVE — do not touch" category as the ones the brief named.

Evidence:

```
postgres=> SELECT table_name, column_name
           FROM information_schema.columns
           WHERE table_schema='public' AND column_name='budget_amount'
           ORDER BY table_name;

        table_name          |  column_name
----------------------------+---------------
 applications               | budget_amount
 it_services                | budget_amount
 programs                   | budget_amount
 vw_program_summary         | budget_amount
 vw_workspace_budget_history| budget_amount
 workspace_budgets          | budget_amount
(6 rows)
```

---

## Step 1 — Required Context Review

Files read:

1. **`~/Dev/getinsync-nextgen-ag/CLAUDE.md`** — contains the two vestigial forbid-rules:
   - Line 101 (Data Model): *"**Budget data lives in workspace_budgets table**, NOT workspaces.budget_amount (that column is legacy — do not read or write to it)."*
   - Line 293 (What You Must NOT Do): *"Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table"*
   - Lines 197-198 (Why This Matters) contain the scar-tissue rationale about the original view-rewrite incident. This rationale is general (view/interface drift) and remains valuable — it does **not** need to be removed.

2. **`~/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md`** — contains the same two rules with identical phrasing:
   - Line 82 (Data Model) — identical wording to code-repo line 101.
   - Line 274 (What You Must NOT Do) — identical wording to code-repo line 293.
   - Lines 178-179 (Why This Matters) — identical scar-tissue text, keep.

3. **`docs-architecture/features/cost-budget/budget-management.md`** — already documents the as-built state correctly. Line 87: *"The original spec called for `budget_amount` on the `workspaces` table. The actual implementation uses a separate `workspace_budgets` table, which is a superior design — it supports multi-year budget history and year-over-year comparison."* Line 92: *"`budget_amount` — does NOT exist (per CLAUDE.md: do NOT read from this column)"*. Line 366: *"The actual view reads workspace budget from `workspace_budgets` table (not `workspaces.budget_amount`)..."* The doc already describes the column as non-existent, but still defers to the CLAUDE.md rule for authority. After the rule is removed, this doc can stop hedging — or can simply be left alone (it is already correct).

4. **`docs-architecture/schema/nextgen-schema-current.sql`** — the `CREATE TABLE public.workspaces` statement at line 8805 lists columns `id`, `namespace_id`, `name`, `slug`, `is_default`, `created_at`, `updated_at`, `budget_fiscal_year`, `budget_notes`, `description`. **No `budget_amount` column.** This matches the live DB and provides independent confirmation.

---

## Step 2 — Code Reference Investigation

```bash
grep -rn "budget_amount" src/ --include="*.ts" --include="*.tsx"
```

Returned **18 hits across 6 files**. Full classification table below. **Zero DEAD-COLUMN READ hits. Zero TYPE DEFINITION hits on a `Workspace`-shaped interface.** All 18 hits are LIVE-TABLE READS against `workspace_budgets`, `programs`, or a view that wraps one of those tables.

| # | file:line | Bucket | Evidence (`.from(...)` / type origin) |
|---|-----------|--------|---------------------------------------|
| 1 | `src/types/roadmap.ts:91` | LIVE-TABLE READ | `ProgramSummaryRow` interface — maps to `vw_program_summary` (derives from `programs.budget_amount`) |
| 2 | `src/types/roadmap.ts:398` | LIVE-TABLE READ | `ProgramFormData` form-state interface for program create/edit modal (writes to `programs`) |
| 3 | `src/types/roadmap.ts:413` | LIVE-TABLE READ | `EMPTY_PROGRAM_FORM` initial value, same form as above |
| 4 | `src/components/roadmap/ProgramModal.tsx:57` | LIVE-TABLE READ | Form hydration from `ProgramSummaryRow` (ultimately `programs` table) |
| 5 | `src/components/roadmap/ProgramModal.tsx:109` | LIVE-TABLE READ | Payload built for `.from('programs').update(payload)` / `.insert(payload)` at lines 121-129 |
| 6 | `src/components/roadmap/ProgramModal.tsx:275` | LIVE-TABLE READ | Form input `value={formData.budget_amount}` (programs form) |
| 7 | `src/components/roadmap/ProgramModal.tsx:276` | LIVE-TABLE READ | Form input `onChange` updater for programs form |
| 8 | `src/components/roadmap/ProgramDetailDrawer.tsx:128` | LIVE-TABLE READ | `program?.budget_amount ?? 0` where `program` is a `ProgramSummaryRow` (vw_program_summary / programs) |
| 9 | `src/components/roadmap/ProgramsTab.tsx:216` | LIVE-TABLE READ | `program.budget_amount ?? 0` inside a map over `ProgramSummaryRow[]` (vw_program_summary / programs) |
| 10 | `src/components/roadmap/InitiativeDetailDrawer.tsx:41` | LIVE-TABLE READ | `LinkedProgram` interface — used only to type the result of `.from('programs').select(...)` at line 207-208 |
| 11 | `src/components/roadmap/InitiativeDetailDrawer.tsx:208` | LIVE-TABLE READ | `supabase.from('programs').select('id, title, budget_amount')` — explicit programs read |
| 12 | `src/components/roadmap/InitiativeDetailDrawer.tsx:529` | LIVE-TABLE READ | `prog.budget_amount != null` render guard (programs result) |
| 13 | `src/components/roadmap/InitiativeDetailDrawer.tsx:530` | LIVE-TABLE READ | `formatCurrency(prog.budget_amount)` (programs result) |
| 14 | `src/components/EditBudgetModal.tsx:45` | LIVE-TABLE READ | `supabase.from('workspace_budgets').select('budget_amount')` — fetches current FY row |
| 15 | `src/components/EditBudgetModal.tsx:50` | LIVE-TABLE READ | `setBudget(currentData?.budget_amount || '')` — state set from workspace_budgets result |
| 16 | `src/components/EditBudgetModal.tsx:54` | LIVE-TABLE READ | `supabase.from('workspace_budgets').select('budget_amount')` — fetches prior FY row |
| 17 | `src/components/EditBudgetModal.tsx:59` | LIVE-TABLE READ | `setPreviousYearBudget(prevData?.budget_amount || null)` |
| 18 | `src/components/EditBudgetModal.tsx:79` | LIVE-TABLE READ | `.upsert({ ..., budget_amount: Number(budget), ... })` against `workspace_budgets` (confirmed at line 75) |

**Interface-level cross-check.** A separate grep (`interface\s+Workspace\b|type\s+Workspace\b`) identified five `Workspace` interface definitions across the codebase:

- `src/contexts/AuthContext.tsx:5` — fields: `id, name, namespace_id, is_default`. No `budget_amount`.
- `src/pages/settings/import/types.ts:5` — fields: `id, name`. No `budget_amount`.
- `src/pages/settings/WorkspacesSettings.tsx:8` — fields: `id, name, slug, namespace_id, is_default, created_at, updated_at`. No `budget_amount`.
- `src/pages/settings/TeamsSettings.tsx:22` — fields: `id, name`. No `budget_amount`.
- `src/components/ManageGroupMembersModal.tsx:11` — fields: `id, name`. No `budget_amount`.

**Conclusion (Step 2):** Zero code paths read or write `workspaces.budget_amount`. Zero Workspace-typed interfaces carry the field. The code is fully clean.

---

## Step 3 — Database View and Function Investigation

### Views

```sql
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND pg_get_viewdef(viewname::regclass, true) ILIKE '%budget_amount%'
ORDER BY viewname;
```

Returned **5 views**. Classification (the qualifier column was obtained by `regexp_matches(..., '(\w+)\.budget_amount', 'g')`):

| # | View | Qualifier(s) | Bucket | Notes |
|---|------|--------------|--------|-------|
| 1 | `vw_budget_status` | `a` (10 occurrences) | LIVE | `a` = `applications` alias |
| 2 | `vw_it_service_budget_status` | `its` (8 occurrences) | LIVE | `its` = `it_services` alias |
| 3 | `vw_program_summary` | `p` (1 occurrence) | LIVE | `p` = `programs` alias |
| 4 | `vw_workspace_budget_history` | `wb` (8 occurrences) | LIVE | `wb` = `workspace_budgets` alias |
| 5 | `vw_workspace_budget_summary` | `wb` (7), `a` (5), `its` (5) | LIVE | joins `workspaces w` but reads budget from `wb`; `w` is only used for `w.id`, `w.name`, `w.namespace_id` |

**No view references `workspaces.budget_amount` (qualifier `w`).** A targeted regex check confirmed this:

```sql
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND pg_get_viewdef(viewname::regclass, true) ~* '(workspaces\.budget_amount|w\.budget_amount)';
-- 0 rows
```

The full definition of `vw_workspace_budget_summary` was read to verify — it joins `workspaces w LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id AND wb.is_current = true LEFT JOIN applications a ON a.workspace_id = w.id` and uses `wb.budget_amount AS workspace_budget`, `COALESCE(wb.budget_amount, 0)` in the status CASE, and similar. The `w` alias is only used for `w.id`, `w.name`, `w.namespace_id` in SELECT and GROUP BY. This view is the as-built state described in `budget-management.md` §4.3 and is the one whose rewrite originally triggered the CLAUDE.md scar-tissue rule.

### Functions

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.prosrc ILIKE '%budget_amount%'
ORDER BY p.proname;
```

Returned **2 functions**:

| # | Function | Reference | Bucket |
|---|----------|-----------|--------|
| 1 | `initialize_app_budgets(uuid)` | `UPDATE applications a SET budget_amount = ... WHERE a.workspace_id = p_workspace_id AND a.budget_amount = 0;` | LIVE (`applications.budget_amount`) |
| 2 | `initialize_it_service_budgets(uuid, text)` | `UPDATE it_services its SET budget_amount = ROUND(srr.run_rate * 1.10, 2) ...` | LIVE (`it_services.budget_amount`) |

**No function references `workspaces.budget_amount`.**

**Conclusion (Step 3):** Zero dead-column references in any view or function. All 5 views and both functions reference live tables only.

---

## Step 4 — Data Preservation Check

The brief's row-count queries would error against the live database because the target column does not exist. Substitute introspection queries were run instead.

### Column presence

```sql
-- information_schema: does the column exist?
SELECT column_name FROM information_schema.columns
WHERE table_schema='public' AND table_name='workspaces' AND column_name='budget_amount';
-- 0 rows

-- pg_attribute: is there a NON-dropped attribute by that name?
SELECT attname FROM pg_attribute
WHERE attrelid = 'public.workspaces'::regclass
  AND attname = 'budget_amount'
  AND NOT attisdropped;
-- 0 rows
```

Both sources confirm the column does not exist in any queryable form.

### Forensic check — was the column dropped or never created?

```sql
SELECT attname, atttypid::regtype, attnum, attisdropped
FROM pg_attribute
WHERE attrelid = 'public.workspaces'::regclass
  AND attnum > 0
ORDER BY attnum;

           attname            |         atttypid         | attnum | attisdropped
------------------------------+--------------------------+--------+--------------
 id                           | uuid                     |      1 | f
 namespace_id                 | uuid                     |      2 | f
 name                         | text                     |      3 | f
 slug                         | text                     |      4 | f
 is_default                   | boolean                  |      5 | f
 created_at                   | timestamp with time zone |      6 | f
 updated_at                   | timestamp with time zone |      7 | f
 budget_fiscal_year           | integer                  |      8 | f
 ........pg.dropped.9........ | -                        |      9 | t
 budget_notes                 | text                     |     10 | f
 description                  | text                     |     11 | f
(11 rows)
```

**The dropped-column placeholder at attnum=9** sits exactly where a `budget_amount` column would historically have been (between `budget_fiscal_year` and `budget_notes` — the two adjacent budget-related columns). PostgreSQL retains dropped columns as `........pg.dropped.N........` entries to preserve `attnum` consistency for tuple-layout reasons. This is the forensic signature of an `ALTER TABLE public.workspaces DROP COLUMN budget_amount` that was executed at some unrecorded prior date. The column is definitively gone — not renamed, not never-created, not hidden.

### workspace_budgets state (live replacement)

```sql
SELECT count(*) AS total_rows,
       count(*) FILTER (WHERE is_current) AS current_rows,
       count(DISTINCT workspace_id) AS workspaces_with_budget,
       min(fiscal_year) AS earliest_fy,
       max(fiscal_year) AS latest_fy
FROM workspace_budgets;

 total_rows | current_rows | workspaces_with_budget | earliest_fy | latest_fy
------------+--------------+------------------------+-------------+-----------
         10 |            6 |                      8 |        2026 |      2027
```

```sql
SELECT count(*) AS total_workspaces FROM workspaces;
-- 45
```

The replacement table has 10 rows across 8 workspaces (6 marked as current), spanning fiscal years 2026-2027. 37 of 45 workspaces have no budget set, which is normal — budgets are opt-in. There is nothing to migrate from the dead column because the dead column is gone.

**Conclusion (Step 4):** Zero orphaned rows. Nothing to preserve. Nothing to migrate.

---

## Step 5 — Classification

### GREEN — already dropped

| Criterion | Required for GREEN | Found | Pass? |
|-----------|---------------------|-------|-------|
| DEAD-COLUMN code reads | 0 | 0 | ✅ |
| TYPE DEFINITION hits on Workspace | 0 | 0 | ✅ |
| DEAD-COLUMN view references | 0 | 0 | ✅ |
| DEAD-COLUMN function references | 0 | 0 | ✅ |
| Orphaned rows in dead column | 0 | N/A — column does not exist | ✅ |
| Column exists at all | (irrelevant for standard GREEN) | **No** | ✅ (stronger than GREEN) |

The condition for GREEN is a subset of reality here — not only are there zero living references that would block a DROP, but the DROP itself already happened. The deliverable therefore does **not** include a `drop-column-budget-amount.sql` file. Instead, a read-only verification SQL script is provided so Stuart can independently confirm the column's absence before applying the CLAUDE.md diff.

### Why the "Why This Matters" paragraph in CLAUDE.md should stay

The scar-tissue paragraph at `CLAUDE.md:197-198` (and the identical text in the architecture-repo file) recounts how the budget page broke because `vw_workspace_budget_summary` was rewritten but the TypeScript interface still expected the old column layout. This is a **general warning about view-to-interface drift**, not a rule specific to `workspaces.budget_amount`. Silent-drift bugs remain a risk on every view-backed query in the app, so the paragraph should be retained. Only the two specific `workspaces.budget_amount` bullets are vestigial.

---

## Open Items and Follow-Ups

1. **Other stale references in architecture docs.** `budget-management.md` still describes `workspaces.budget_amount` as "does NOT exist (per CLAUDE.md: do NOT read from this column)" at line 92, and references the CLAUDE.md rule as the authority. This is correct today; after the CLAUDE.md rule is removed, the doc will still be accurate (the column still does not exist) but the "per CLAUDE.md" phrasing becomes dangling. Recommended follow-up: when Stuart applies the CLAUDE.md diff, edit `budget-management.md` line 92 to something like *"`budget_amount` — does NOT exist (was dropped prior to 2026-04-10; workspace budgets live in `workspace_budgets` table)."* Not in scope for this planning session.

2. **Incidental schema-scope finding.** The task brief stated `budget_amount` exists on three tables; it actually exists on four live tables (`applications`, `it_services`, `programs`, `workspace_budgets`) plus two views. The brief's framing did not cause misclassification in this investigation but should be noted if similar investigations are run in the future — always introspect from `information_schema.columns` rather than trusting a prose enumeration.

3. **Schema-backup staleness.** `docs-architecture/schema/nextgen-schema-current.sql` already reflects the dropped column correctly (the `CREATE TABLE workspaces` at line 8805 omits `budget_amount`). The schema backup is in sync with the live DB for this column. No action needed.

4. **Session summary follow-up.** Noted but not acted on: an unrelated uncommitted file `session-summary-2026-04-09-soc2-evidence.md` exists in the code repo root. Not in scope for this session.

---

## Evidence checklist

- [x] Every row in the Step 2 table cites a `file:line`
- [x] Every row in the Step 3 view/function tables cites the qualifier source
- [x] Step 4 row counts are reproduced verbatim from psql output
- [x] The dropped-column placeholder evidence is reproduced verbatim from `pg_attribute`
- [x] No claim in this report is unsourced

---

*End of findings report.*
