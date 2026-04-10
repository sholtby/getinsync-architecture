# Claude Code Session Prompt — `workspaces.budget_amount` Cleanup Investigation

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — assumes no prior conversation context.
> This is a **research + draft** session, not an implementation session. Its job is to determine whether the legacy `workspaces.budget_amount` column can be safely dropped, and to draft (but not apply) the DROP COLUMN migration SQL and the companion CLAUDE.md rule removal. Stuart decides whether to execute.
> Expected session length: 30-45 minutes.

---

## Task: Determine safety and draft cleanup artifacts for dropping the legacy `workspaces.budget_amount` column

You are starting fresh. Read this entire brief before touching anything.

### Why this work exists

Both CLAUDE.md files (`CLAUDE.md` in the code repo and `docs-architecture/CLAUDE.md`) contain a hard-forbid rule about a single legacy database column:

> **Budget data lives in workspace_budgets table**, NOT `workspaces.budget_amount` (that column is legacy — do not read or write to it).

And in the "What You Must NOT Do" list:

> Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table.

This rule exists because of scar tissue: the budget page broke in the past when `vw_workspace_budget_summary` was rewritten to read from the new `workspace_budgets` table, but some TypeScript consumers still expected the old column layout. Silent data drift — no error, just wrong values. The fix at the time was to migrate budget data to a dedicated table (`workspace_budgets`) and forbid further reads of the legacy column.

But the legacy column was never actually dropped. It still sits on the `workspaces` table, accepting writes that nothing reads, and the CLAUDE.md rule exists solely to warn sessions away from a dead column that could be removed entirely.

**The right fix is to drop the column** — which makes the rule self-enforcing (you can't read or write a column that doesn't exist), lets both CLAUDE.md files shrink by two bullets each, and eliminates the silent-failure surface permanently.

**But before dropping, three things must be verified:**
1. No TypeScript / React code still reads `workspaces.budget_amount`
2. No database view still references it
3. No orphaned data lives in the column that was never migrated to `workspace_budgets`

Your job is to verify all three, classify the DROP COLUMN migration as GREEN / YELLOW / RED, and draft the cleanup artifacts. You do not execute anything.

### ⚠ Critical gotcha — column-name collision

The column name `budget_amount` appears on **three different tables**:

1. `workspaces.budget_amount` — the legacy dead column (YOUR TARGET)
2. `workspace_budgets.budget_amount` — the live budget table's column (DO NOT TOUCH)
3. `it_services.budget_amount` — IT service budget allocation (DO NOT TOUCH — different concept entirely)

Every `grep` hit and every view definition match has to be classified by which table it reads from, not by the column name alone. A `SELECT budget_amount FROM workspace_budgets` hit is LIVE and must not be removed. A `SELECT budget_amount FROM workspaces` hit is DEAD and is the thing blocking the drop. Misclassifying these will produce wrong findings — be deliberate.

### Hard rules

1. **READ-ONLY database access.** Use `$DATABASE_READONLY_URL` from `.env` for SELECT introspection only. Never run INSERT / UPDATE / DELETE / CREATE / ALTER / DROP / TRUNCATE.
2. **No schema execution.** You may write a `.sql` file containing the proposed DROP COLUMN migration into the deliverables directory; you may NOT execute it.
3. **No live edits to CLAUDE.md.** You may draft a proposed diff as a separate markdown file in the deliverables directory. Do not edit either live CLAUDE.md file.
4. **No code changes.** You may grep `src/` read-only. Do not modify any TypeScript, React, or hook file.
5. **No edits to architecture feature docs** (`core/`, `features/`, `catalogs/`, `identity-security/`). This session is planning-directory-only.
6. **Evidence before recommendation.** Every claim in your findings must cite a specific grep count, file:line reference, or query result. No speculation.

### Step 1 — Read the required context

In this order:

```
1. /Users/stuartholtby/Dev/getinsync-nextgen-ag/CLAUDE.md
   - Find the two rules about workspaces.budget_amount (one in the "Architecture Rules
     — Data Model" subsection, one in the "What You Must NOT Do" list).
   - Read the "Impact Analysis — BEFORE EVERY CHANGE" section including the "Why This
     Matters" subsection, which recounts the original budget-page breakage. That's the
     scar tissue this rule protects against.
   - Note line numbers for both rule locations.

2. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md
   - Find the same rules in this file. Note any phrasing drift.
   - Note line numbers.

3. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/budget-management.md
   - Confirm the canonical budget doc treats workspace_budgets as the source of truth.
   - Look for any mention of workspaces.budget_amount — if the doc still references it,
     that's itself a finding.

4. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/schema/nextgen-schema-current.sql
   - Search for `CREATE TABLE public.workspaces` and read the column list.
   - Confirm budget_amount still exists, note its type, nullability, default, and any
     COMMENT ON COLUMN text.
   - Also search for `CREATE TABLE public.workspace_budgets` and `CREATE TABLE public.it_services`
     to confirm both the live-column cases exist (so you can classify grep hits correctly).
```

### Step 2 — Code reference investigation

Grep the code repo for every reference to `budget_amount`:

```bash
cd ~/Dev/getinsync-nextgen-ag
grep -rn "budget_amount" src/ --include="*.ts" --include="*.tsx" > /tmp/budget_amount_hits.txt
wc -l /tmp/budget_amount_hits.txt
```

For **every** hit in that file, read enough surrounding context (the `.from(...)` or `FROM` clause, the TypeScript interface name, the variable assignment) to classify it into one of four buckets:

| Bucket | Meaning | Example |
|--------|---------|---------|
| **DEAD-COLUMN READ** | Code reads `workspaces.budget_amount` (or a type that originates from it). Bug waiting to happen. | `supabase.from('workspaces').select('id, budget_amount')` |
| **LIVE-TABLE READ** | Code reads `workspace_budgets.budget_amount` or `it_services.budget_amount`. Correct, must not be touched. | `supabase.from('workspace_budgets').select('budget_amount, fiscal_year')` |
| **TYPE DEFINITION** | A TypeScript interface `Workspace` that still has `budget_amount?: number` as a field, but nothing actually reads it. Latent bug — the interface lies about the column's relevance. | `interface Workspace { ... budget_amount?: number; }` |
| **STRING MATCH ONLY** | Comment, docs string, test fixture, or unrelated context (e.g. a variable literally named `budget_amount` that's unrelated to the column). | `// TODO: remove budget_amount from legacy workspaces` |

Produce a single table in your findings report listing every hit with its `file:line`, a short code excerpt, and its bucket classification. Aim for completeness — if the grep returns 40 hits, your table has 40 rows.

**Key per-bucket rules:**

- **DEAD-COLUMN READ** count > 0 → the DROP COLUMN is **RED** (blocked). Living code references must be fixed first. Name every offending file.
- **TYPE DEFINITION** > 0 → may still be GREEN/YELLOW, but flag these as required follow-up cleanup: after the column is dropped, the `Workspace` TypeScript interface must also have `budget_amount` removed from its field list. Draft the proposed `Workspace` interface diff as part of the deliverables.
- **LIVE-TABLE READ** count can be any number — those are correct and do not block the drop.
- **STRING MATCH ONLY** hits are noise; list them but don't let them block anything.

### Step 3 — Database view reference investigation

Use the read-only connection:

```sql
-- Every view whose definition references budget_amount
SELECT viewname, pg_get_viewdef(viewname::regclass, true) AS def
FROM pg_views
WHERE schemaname = 'public'
  AND pg_get_viewdef(viewname::regclass, true) ILIKE '%budget_amount%'
ORDER BY viewname;
```

For **every** view returned, read its full definition and classify whether the `budget_amount` reference is against `workspaces`, `workspace_budgets`, or `it_services`. Same four-bucket scheme as Step 2 (but TYPE DEFINITION doesn't apply to views, so it's DEAD / LIVE / STRING-MATCH only).

**Key rules:**
- Any view with a DEAD-COLUMN READ (reading `workspaces.budget_amount`) → DROP COLUMN is **RED** until that view is rebuilt. Name the view and quote the offending SQL fragment.
- LIVE views (reading `workspace_budgets.budget_amount` or `it_services.budget_amount`) are fine — they don't block anything.

Also check for functions and triggers:

```sql
-- Any function referencing budget_amount
SELECT proname, pg_get_functiondef(p.oid) AS def
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND pg_get_functiondef(p.oid) ILIKE '%budget_amount%';
```

Same classification. A function reading `workspaces.budget_amount` is also a blocker.

### Step 4 — Data preservation check

Use the read-only connection:

```sql
-- Is there data sitting in the legacy column?
SELECT
  count(*) AS total_workspaces,
  count(*) FILTER (WHERE budget_amount IS NOT NULL) AS non_null_count,
  count(*) FILTER (WHERE budget_amount IS NOT NULL AND budget_amount != 0) AS non_zero_count,
  sum(budget_amount) AS total_value,
  min(budget_amount) AS min_value,
  max(budget_amount) AS max_value
FROM workspaces;

-- Cross-check: any workspace has a non-null legacy value but NO matching workspace_budgets row?
SELECT
  w.id, w.name, w.namespace_id,
  w.budget_amount AS legacy_amount,
  (SELECT count(*) FROM workspace_budgets wb WHERE wb.workspace_id = w.id) AS migrated_row_count
FROM workspaces w
WHERE w.budget_amount IS NOT NULL
  AND w.budget_amount != 0
ORDER BY w.namespace_id, w.name;
```

**Key rules:**
- Zero non-null rows → no data to preserve → **GREEN** is still possible.
- Non-null rows exist but **all** of them have a matching `workspace_budgets` row → the data is already migrated → **GREEN** is still possible (the legacy column is just redundant).
- Non-null rows exist **without** matching `workspace_budgets` rows → **orphaned data** → the drop is **YELLOW** at best. The cleanup must include a data-migration block that inserts those orphan values into `workspace_budgets` before the DROP COLUMN runs.

For the orphan case, decide on a sensible default for the fields `workspace_budgets` needs that `workspaces.budget_amount` doesn't carry:
- `fiscal_year` — pick the current FY based on namespace conventions (the demo namespaces look like they use calendar years; query `workspace_budgets` for the most common `fiscal_year` value and match that)
- `is_current` — default `true` only if no other row is marked current for that workspace, else `false`
- `actual_run_rate` — leave NULL (the overview computes run rate from IT services, not this column)
- Any other NOT NULL columns — discover from the schema file and fill with safe defaults

### Step 5 — Safety classification

Based on Steps 2, 3, and 4, classify the `ALTER TABLE workspaces DROP COLUMN budget_amount` migration as exactly one of:

- **GREEN** — safe to drop immediately. Zero dead-column code reads, zero dead-column view/function references, zero orphaned rows.
- **YELLOW** — safe to drop after a data migration. Zero dead-column code reads, zero dead-column view/function references, but orphaned rows exist. Deliverable includes both the migration SQL and the DROP COLUMN SQL, with a required run order.
- **RED** — not safe yet. Living code, view, or function references exist. Name each one and explain what would need to change first. Do NOT draft the DROP COLUMN SQL — Stuart has to fix the living references in a separate session before the drop becomes safe.

### Step 6 — Produce deliverables

Create this directory:

```
/Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/workspaces-budget-amount-cleanup/
```

Required files:

```
README.md
  - One paragraph: what this directory is, safety classification summary, execution order
  - Cross-link back to this prompt file

findings-report.md
  - Executive summary (2-4 sentences) including GREEN/YELLOW/RED verdict
  - Step 2 results: complete grep classification table with file:line references
  - Step 3 results: complete view / function classification table
  - Step 4 results: row counts, orphan query output, data-preservation verdict
  - Step 5 verdict with one-sentence rationale per input
  - Open questions / follow-ups (if any)

drop-column-budget-amount.sql  [ONLY if GREEN or YELLOW]
  - Header comment block: purpose, preconditions, safety classification, Stuart's
    required verification steps before running
  - If YELLOW: a data-migration block first (INSERT INTO workspace_budgets ... FROM
    workspaces WHERE budget_amount IS NOT NULL AND NOT EXISTS ...) — idempotent
  - The ALTER TABLE ... DROP COLUMN budget_amount statement
  - Wrapped in BEGIN; ... COMMIT; with a pre-commit verification SELECT that confirms
    the column is gone and workspace_budgets row count increased by the expected amount
    (if YELLOW)
  - Idempotency: use DROP COLUMN IF EXISTS so re-running the file is a no-op
  - Footer: -- Rollback: notes. Dropping a column is not reversible via simple SQL —
    document that restoration requires ALTER TABLE workspaces ADD COLUMN budget_amount
    numeric(12,2) followed by a data restore from backup. Flag this as a one-way door.

proposed-claudemd-rule-removal.md  [ALWAYS, even if RED]
  - For each CLAUDE.md file (code repo and architecture repo), show a before/after block
    for the two rule locations:
    (a) the "Architecture Rules — Data Model" bullet mentioning workspaces.budget_amount
    (b) the "What You Must NOT Do" bullet mentioning workspaces.budget_amount
  - If GREEN or YELLOW: the diff removes both bullets entirely
  - If RED: the diff leaves both bullets in place and adds a date-stamped note saying
    "the column cannot be dropped yet because X" — Stuart will update the rule text
    only after the living references are fixed
  - Do NOT edit the live CLAUDE.md files. Drafts only.

proposed-workspace-interface-diff.md  [ONLY if Step 2 found TYPE DEFINITION hits]
  - Show the before/after for each TypeScript interface that has a `budget_amount`
    field on a Workspace-typed interface
  - Note that this code change has to be applied AFTER the DROP COLUMN runs, not before
    (otherwise the interface will drift from the live column during the gap)
  - Do NOT edit the live files. Drafts only.
```

Every deliverable must cite specific evidence from the investigation (grep counts, file:line, query results). No unsourced claims.

### Step 7 — Final session report

In your final chat message:

1. **Verdict** — GREEN / YELLOW / RED with a one-line reason
2. **Headline counts** — DEAD code reads, DEAD view refs, orphan rows
3. **Deliverables** — list every file you wrote
4. **Next step** — what Stuart should do (run the SQL, fix living refs first, etc.)
5. **Confirmations** — you did NOT execute the migration, did NOT edit live CLAUDE.md, did NOT modify code, did NOT commit to the code repo

### Step 8 — Commit

Commit the deliverables directory to the architecture repo (always on `main`):

```bash
cd ~/getinsync-architecture
git add planning/workspaces-budget-amount-cleanup/
git status  # verify ONLY planning/workspaces-budget-amount-cleanup/ files are staged
git commit -m "planning: workspaces.budget_amount cleanup investigation — [GREEN|YELLOW|RED]"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

If `git status` shows anything else modified outside that directory, STOP and tell Stuart — you've accidentally touched something you shouldn't have.

### Done criteria checklist

- [ ] All four required-reading files in Step 1 have been read
- [ ] Step 2 grep executed; every hit classified into a bucket; table written to findings report
- [ ] Step 3 view and function queries executed; every reference classified; table written to findings report
- [ ] Step 4 data-preservation queries executed; row counts and orphan list written to findings report
- [ ] Step 5 classification (GREEN / YELLOW / RED) assigned with rationale
- [ ] `planning/workspaces-budget-amount-cleanup/` directory created with README + findings + drafted SQL (if not RED) + proposed CLAUDE.md diff (always) + proposed interface diff (if applicable)
- [ ] Every claim in findings cites a specific grep count, file:line, or query result
- [ ] No live CLAUDE.md edits, no feature doc edits, no code-repo commits, no database writes
- [ ] Architecture repo committed and pushed on `main` with only the new directory's files staged
- [ ] Final session report delivered

### What NOT to do

- Do NOT run the drafted DROP COLUMN migration. You only draft it.
- Do NOT touch the `workspace_budgets` or `it_services` tables — only `workspaces`.
- Do NOT misclassify `workspace_budgets.budget_amount` or `it_services.budget_amount` hits as dead-column reads — those are live and correct. Read each grep hit's `.from(...)` / `FROM` clause carefully.
- Do NOT edit CLAUDE.md, `budget-management.md`, or any other live doc. Drafts only, in the deliverables directory.
- Do NOT modify any TypeScript file under `src/`. The proposed Workspace-interface diff is a draft only.
- Do NOT expand scope beyond `workspaces.budget_amount`. If you discover other legacy columns during grep, note them in the findings report as open items, do not investigate them in this session.
- Do NOT start the GitBook rollout, the enrichment session, the cost-channel clarity session, or any other in-flight work stream.
- Do NOT unilaterally decide to fix living code references yourself. If the classification is RED, the deliverable is a RED findings report — Stuart runs a separate session to fix the living references first.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
