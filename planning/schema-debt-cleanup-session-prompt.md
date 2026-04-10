# Claude Code Session Prompt — Schema Debt Cleanup Investigation

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — assumes no prior conversation context.
> This is a **research + recommendation** session, not an implementation session. Its job is to investigate two specific CLAUDE.md rules that exist because of underlying schema debt, produce an evidence-based recommendation for each, and draft (but not apply) the cleanup artifacts. Stuart decides whether to execute.

---

## Task: Investigate and recommend fixes for two CLAUDE.md "forbid" rules that exist only because of unresolved schema debt

You are starting fresh. Read this entire brief before doing anything. Do not touch the filesystem or database until you have read Steps 1-3 in full.

### Why this work exists

`CLAUDE.md` (both the code-repo one and the architecture-repo one) contains two "do not touch" rules that exist because the underlying schema has unresolved ambiguity, not because the rules themselves reflect correct design:

1. **`workspaces.budget_amount` — legacy dead column.** The rule says "do not read or write to it; use the `workspace_budgets` table instead." The rule exists because budget data was migrated to a new dedicated table but the original column was left behind, and at least one page broke in the past when consumers kept reading the old column after the view behind it was rewritten. This is **pure tech debt** — the column almost certainly has no living consumers.

2. **`cost_bundles` — aspirational table that was never built.** CLAUDE.md's cost-model rule declares CostBundle as a valid cost channel ("Cost data lives on cost channels — SoftwareProduct / ITService / CostBundle — never on applications directly"), and the Phase 0 GitBook rollout plan references a "cost bundles" panel in Article 4.3. But the Phase 0 readiness walk confirmed the `cost_bundles` table **does not exist** in the schema. The concept was documented as if it existed, but the feature was never shipped. This is a **product decision masquerading as schema debt**.

Both rules could be eliminated by fixing the underlying cause. Your job is to investigate both, gather evidence, and produce a recommendation for each. You may draft cleanup artifacts (SQL migration, doc patches, architecture decisions) but **you must not apply them** — no schema changes, no database writes, no commits to the code repo, no edits to CLAUDE.md or other live architecture docs beyond the deliverables under `planning/schema-debt-cleanup/`.

### Hard rules

1. **READ-ONLY database access.** Use `$DATABASE_READONLY_URL` from `.env` for SELECT queries only. Never run INSERT/UPDATE/DELETE/CREATE/ALTER/DROP/TRUNCATE.
2. **No schema changes.** You may draft a `.sql` file with the proposed migration inside the deliverables directory; you may NOT execute it.
3. **No edits to CLAUDE.md, architecture feature docs, or rollout plans.** You may draft proposed diffs to those files inside the deliverables directory as separate `.md` files (e.g. `proposed-claudemd-diff.md`). Do not edit the live files.
4. **No code changes.** You may grep the code repo read-only. Do not modify any file under `src/`.
5. **Do not start or continue the GitBook rollout, the enrichment session, or any Phase 1+ work.** Those are separate sessions with their own prompts.
6. **Evidence before recommendation.** Every recommendation in your final report must cite specific grep counts, specific query results, and specific file paths. No speculation.

### Step 1 — Read the required context

In this order:

```
1. /Users/stuartholtby/Dev/getinsync-nextgen-ag/CLAUDE.md
   - Find the two rules in question:
     * "Budget data lives in workspace_budgets table, NOT workspaces.budget_amount"
     * "Cost data lives on cost channels (SoftwareProduct / ITService / CostBundle)"
   - Read the Impact Analysis section ("The budget page broke because...") for the scar-tissue rationale.
   - Read the Database Access section for the read-only contract.

2. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md
   - Confirm this file contains the same or similar rules. Note any divergence between the two CLAUDE.md files — that's itself a finding.

3. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/cost-model.md
   - The canonical cost model doc. Look for every mention of CostBundle / cost_bundles / bundle.
   - Note whether the doc treats CostBundle as "shipped" or "planned."

4. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/budget-management.md
   - The canonical budget doc. Confirm it treats workspace_budgets as the source of truth.

5. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/schema/nextgen-schema-current.sql
   - Source of truth for what actually exists. Confirm:
     * workspaces table definition — is budget_amount still in it? What type / nullability / default?
     * cost_bundles table — does it exist at all? Any related objects (views, triggers, junction tables)?
   - Note the line numbers of whatever you find (or don't find).

6. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/gitbook-phase-0-readiness.md
   - The Phase 0 walk that surfaced these two items. §4.3 flags cost_bundles as non-existent.
   - The readiness report is the most recent primary source — its conclusions are your baseline.

7. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/gitbook-complete-rollout-plan.md
   - Find the reference to "cost bundles" in §4 of the rollout plan. Article 4.3 has a dependency on this concept that needs to be resolved one way or the other.
```

### Step 2 — Investigate `workspaces.budget_amount`

Gather three specific pieces of evidence:

**2a. Code references.** Grep the code repo:

```bash
cd ~/Dev/getinsync-nextgen-ag
grep -rn "budget_amount" src/ --include="*.ts" --include="*.tsx" | grep -v "workspace_budgets" > /tmp/budget_amount_code_refs.txt
```

For every match, determine whether it is reading `workspaces.budget_amount` (the dead column) or `workspace_budgets.budget_amount` (the live table's column). The column name is unfortunately the same on both tables, so context matters — look at the `.from(...)` or FROM clause immediately preceding each match.

Classify each hit into:
- **DEAD-COLUMN READ** — code that queries `workspaces` and selects `budget_amount`. These are bugs waiting to happen.
- **LIVE-TABLE READ** — code that queries `workspace_budgets` and selects `budget_amount`. These are correct and must not be touched.
- **STRING MATCH ONLY** — type definition, comment, or documentation reference with no functional impact.

**2b. Database view references.** Use the read-only connection:

```sql
-- Find any view whose definition references workspaces.budget_amount
SELECT viewname, pg_get_viewdef(viewname::regclass, true) AS def
FROM pg_views
WHERE schemaname = 'public'
  AND pg_get_viewdef(viewname::regclass, true) ILIKE '%budget_amount%';
```

For each view, determine the same DEAD/LIVE/STRING classification. Any view selecting `workspaces.budget_amount` must be rebuilt before the column can be dropped safely.

**2c. Data preservation.** Use the read-only connection:

```sql
-- Is there orphaned data sitting in the legacy column?
SELECT
  count(*) FILTER (WHERE budget_amount IS NOT NULL) AS non_null_rows,
  count(*) AS total_rows,
  sum(budget_amount) AS total_value,
  min(budget_amount) AS min_value,
  max(budget_amount) AS max_value
FROM workspaces;

-- Cross-check: for every workspace with a non-null legacy budget_amount,
-- is there a corresponding row in workspace_budgets?
SELECT
  w.id, w.name, w.namespace_id, w.budget_amount AS legacy_amount,
  wb.budget_amount AS migrated_amount, wb.fiscal_year
FROM workspaces w
LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id
WHERE w.budget_amount IS NOT NULL
ORDER BY w.namespace_id, w.name;
```

If any rows come back with `legacy_amount IS NOT NULL` and `migrated_amount IS NULL`, that's orphaned data — the DROP COLUMN cannot run safely without a migration script that copies surviving values into `workspace_budgets` first.

**2d. Safety determination.**

Based on 2a / 2b / 2c, classify the `DROP COLUMN workspaces.budget_amount` migration as one of:

- **GREEN — safe to drop immediately.** Zero dead-column reads in code, zero views reference it, zero orphaned rows. Draft the `DROP COLUMN` SQL as a deliverable.
- **YELLOW — safe to drop after a data migration.** Zero dead-column reads in code, zero views reference it, but orphaned rows exist. Draft both the data-migration SQL (copy into `workspace_budgets` with sensible defaults) and the `DROP COLUMN` SQL, and specify that the data migration must run first.
- **RED — not safe yet.** Living code or view references exist. Name each one and explain what would need to change in the code/view before the drop becomes safe. Do NOT draft a DROP COLUMN migration in this case — Stuart needs to fix the living references first, and that's a separate session.

### Step 3 — Investigate `cost_bundles`

Gather two specific pieces of evidence:

**3a. Confirm non-existence.** Use the read-only connection:

```sql
-- Does the table exist?
SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cost_bundles';

-- Any table name containing "bundle"?
SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' AND tablename ILIKE '%bundle%';

-- Any view referencing "cost_bundle" in its definition?
SELECT viewname FROM pg_views WHERE schemaname = 'public' AND pg_get_viewdef(viewname::regclass, true) ILIKE '%cost_bundle%';

-- Any function referencing it?
SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND pg_get_functiondef(p.oid) ILIKE '%cost_bundle%';
```

Confirm the table does not exist and no database object depends on it.

**3b. Mention inventory.** Grep both repos for every mention of CostBundle / cost_bundles / cost bundle:

```bash
cd ~/Dev/getinsync-nextgen-ag
grep -rn -i "cost_bundle\|cost bundle\|costbundle" \
  src/ \
  docs-architecture/ \
  --include="*.ts" --include="*.tsx" --include="*.md" --include="*.sql" \
  > /tmp/cost_bundles_mentions.txt
```

Classify each hit as:
- **RULE** — CLAUDE.md (either file) — the forbid rules that exist because of this gap
- **DOC** — architecture feature doc treating it as shipped (these docs are wrong and need correcting if we choose Option B)
- **PLAN** — rollout plan or planning doc referencing the concept as a future dependency
- **CODE** — any actual TypeScript or React reference (there should be none; if there are, that's a finding)
- **SQL** — any schema definition or migration file (there should be none)

Produce a clean table of hits with file path, line number, and classification.

**3c. Decision framing — Option A vs Option B.**

The decision is a product decision, not a technical one. You must **present both options fairly with evidence** and may suggest which seems better based on findings, but the final call is Stuart's. Do not write as if you've decided.

- **Option A — Build `cost_bundles`.** Describes what the table would need (columns, FKs, junction to software products / IT services, view rollup into `vw_portfolio_costs_rollup`, RLS, audit trigger). Estimate the work as a rough t-shirt size (S/M/L) based on the new-table checklist at `docs-architecture/operations/new-table-checklist.md`. Identify the real-world use cases it would serve (Microsoft E5 bundles, Adobe CC, Oracle ULA, managed-service contracts). Do NOT draft the actual schema SQL — just list the columns and relationships in prose + a markdown table.

- **Option B — Delete the concept from the docs.** List every file that would need to change to remove CostBundle references. Draft the specific edits (as a proposed-diff markdown file, not a live edit) for:
  - `CLAUDE.md` (both copies)
  - `docs-architecture/features/cost-budget/cost-model.md`
  - `docs-architecture/planning/gitbook-complete-rollout-plan.md` §4 and Article 4.3 scope
  - Any other doc that treats CostBundle as shipped
  - Draft a new `docs-architecture/decisions/` entry explaining why CostBundle was removed from the model (use the existing decisions folder if it exists, or flag its absence if it doesn't). The entry must name the date, the decision, the rationale, and explicitly mention "revisit when a customer asks for bundled-contract modeling."

**Weigh the options using evidence from 3b:** if the mention inventory is small and contained (rule + cost-model doc + rollout plan §4 + one article scope), Option B is cheap. If CostBundle is woven through many feature docs and implied by existing views/junctions, Option A becomes relatively more attractive because the concept is already "half in." Base your recommendation on the inventory count, not on taste.

### Step 4 — Produce deliverables

Create this directory and put everything in it:

```
/Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/schema-debt-cleanup/
```

Required files:

```
README.md
  - One paragraph explaining what this directory is
  - Execution order for Stuart (read findings, decide, run the drafted SQL/edits)
  - Cross-link back to this prompt file

findings-report.md
  - Executive summary (2-4 sentences)
  - Item 1: workspaces.budget_amount investigation
    * 2a Code reference scan — counts and classified hits
    * 2b View reference scan — counts and classified hits
    * 2c Data preservation query results — row counts, sums, orphan list
    * 2d Safety determination — GREEN / YELLOW / RED with rationale
    * Recommendation
  - Item 2: cost_bundles investigation
    * 3a Non-existence confirmation — query results
    * 3b Mention inventory — table of every hit, classified
    * 3c Option A vs Option B comparison — pros/cons of each, with evidence-based weighting
    * Recommendation (fairly presented, with "final call is Stuart's")
  - Open questions (anything the investigation revealed but could not resolve)

budget-amount-drop-migration.sql  [GREEN or YELLOW only — omit if RED]
  - Header comment: purpose, preconditions, rollback notes
  - If YELLOW: the data migration copy-into-workspace_budgets block first
  - The DROP COLUMN workspaces.budget_amount statement
  - Wrapped in BEGIN; ... COMMIT; with a pre-commit verification SELECT
  - Fully idempotent where possible (DROP COLUMN IF EXISTS)

cost-bundles-option-a-schema-sketch.md  [only if Option A is recommended or close to it]
  - Prose description of the proposed cost_bundles table
  - Column list as a markdown table (column, type, nullability, FK, notes)
  - Junction tables needed
  - Views that would need updating
  - New-table-checklist alignment

cost-bundles-option-b-doc-patches.md  [only if Option B is recommended or close to it]
  - Proposed diff for each CLAUDE.md file (before/after blocks)
  - Proposed diff for cost-model.md
  - Proposed diff for gitbook-complete-rollout-plan.md §4 and Article 4.3 scope
  - Proposed new decisions/ entry (full markdown content)

proposed-claudemd-diff.md  [always, even if only budget_amount changes]
  - Show the exact before/after for the budget_amount rule removal if the investigation says GREEN or YELLOW
  - Show the exact before/after for the cost_bundles rule removal only if Option B is recommended
  - Do NOT edit the live CLAUDE.md files. Drafts only.
```

Every deliverable must cite evidence from Steps 2 and 3. No unsourced claims.

### Step 5 — Final session report

In your final chat message, tell Stuart:

1. The safety classification for `budget_amount` (GREEN / YELLOW / RED) and the one-line reason
2. The recommendation for `cost_bundles` (Option A or Option B) and the one-line reason
3. The location of the deliverables directory
4. Any open questions you couldn't resolve read-only
5. Confirmation that you did NOT edit CLAUDE.md, did NOT edit the live feature docs, did NOT commit to the code repo, and did NOT execute any database writes

### Step 6 — Commit

Commit the deliverables directory to the architecture repo (always on `main`):

```bash
cd ~/getinsync-architecture
git add planning/schema-debt-cleanup/
git status  # confirm only planning/schema-debt-cleanup/ files are staged
git commit -m "planning: schema debt cleanup investigation — budget_amount + cost_bundles"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

If `git status` shows anything else staged or modified outside `planning/schema-debt-cleanup/`, STOP and tell Stuart — you've accidentally touched something you shouldn't have.

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] `workspaces.budget_amount` — code grep, view query, and data-preservation query all executed; classified GREEN/YELLOW/RED with evidence
- [ ] `cost_bundles` — non-existence confirmed via pg_tables + pg_views + pg_proc; mention inventory complete
- [ ] `planning/schema-debt-cleanup/` directory created with README + findings report + proposed diffs + (conditionally) drafted migration SQL or option docs
- [ ] Every claim in the findings report cites a specific grep count, query result, or file:line reference
- [ ] Option A vs Option B for cost_bundles presented fairly, with recommendation flagged as "Stuart's final call"
- [ ] No live CLAUDE.md edits, no live feature doc edits, no code-repo commits, no database writes
- [ ] Architecture repo committed and pushed on `main` with only the new directory's files staged
- [ ] Final session report delivered

### What NOT to do

- Do NOT execute the drafted `DROP COLUMN` migration. You only draft it.
- Do NOT edit CLAUDE.md, feature docs, or the rollout plan in place. You only draft proposed diffs inside the deliverables directory.
- Do NOT start implementing Option A (building the cost_bundles table). That's a separate feature session if it ever happens.
- Do NOT start Phase 1 of the GitBook rollout or continue the demo-data enrichment work. Those are separate sessions with their own prompts.
- Do NOT modify any file under `~/Dev/getinsync-nextgen-ag/src/`. This session is read-only on code.
- Do NOT touch any file outside `docs-architecture/planning/schema-debt-cleanup/`.
- Do NOT decide for Stuart on Option A vs Option B. Recommend, don't decide.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
