# Proposed CLAUDE.md Rule Removal — workspaces.budget_amount

**Status:** DRAFT — not yet applied to either live CLAUDE.md file.
**Applies to:** Both `~/Dev/getinsync-nextgen-ag/CLAUDE.md` (code repo) and `~/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md` (architecture repo).
**Safety precondition:** Verdict from `findings-report.md` is GREEN — the column already does not exist. Run `verify-workspaces-budget-amount-absent.sql` once before applying these diffs to re-confirm.

Both files carry two vestigial bullets that forbid reading a column (`workspaces.budget_amount`) that does not exist on the live database. The column was dropped via `ALTER TABLE ... DROP COLUMN` at some unrecorded prior date (forensic evidence: the `........pg.dropped.9........` placeholder in `pg_attribute`). The forbid-rules remain in the CLAUDE.md files but cannot be violated in practice — any attempt to read a non-existent column would fail at query time with a column-does-not-exist error. The rules no longer protect against a real failure mode and can be removed.

The general "Why This Matters" paragraph about view-to-interface drift (code-repo lines 197-198, arch-repo lines 178-179) is **NOT** being removed — it is a general warning useful for every future view-backed query, not specific to this column.

---

## File 1 — `~/Dev/getinsync-nextgen-ag/CLAUDE.md`

### Edit A — Data Model bullet (around line 101)

**BEFORE** (lines 98-103):

```markdown
### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly. CostBundle is **not a separate table** — it is implemented as `deployment_profiles.dp_type = 'cost_bundle'` with cost/contract columns (`annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`). Canonical definition: `docs-architecture/features/cost-budget/cost-model.md` §3.3.
- **Budget data lives in workspace_budgets table**, NOT workspaces.budget_amount (that column is legacy — do not read or write to it).
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.
```

**AFTER** (remove the `workspaces.budget_amount` bullet; keep neighbours verbatim):

```markdown
### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly. CostBundle is **not a separate table** — it is implemented as `deployment_profiles.dp_type = 'cost_bundle'` with cost/contract columns (`annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`). Canonical definition: `docs-architecture/features/cost-budget/cost-model.md` §3.3.
- **Budget data lives in the workspace_budgets table** (year-over-year, one row per fiscal year). Canonical definition: `docs-architecture/features/cost-budget/budget-management.md`.
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.
```

> Rationale: rather than deleting the budget-data bullet entirely, reshape it as a positive pointer to the live table and its canonical doc. This preserves the "where does budget data live" signal (which is useful for onboarding new sessions) while dropping the forbid-clause that references the dead column.

### Edit B — What You Must NOT Do bullet (around line 293)

**BEFORE** (lines 285-300):

```markdown
## What You Must NOT Do

- Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- Do NOT create database migrations, tables, columns, or constraints
- Do NOT use `sudo` for npm installs
- Do NOT hardcode dropdown values — always fetch from reference tables
- Do NOT use `alert()` or `confirm()` — use toast/modal components
- Do NOT create separate CSS/JS files — keep everything in single component files
- Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table
- Do NOT assume schema from memory — check actual table/view definitions via Supabase queries
- Do NOT search for a literal `cost_bundles` table — CostBundle is a deployment-profile type (`dp_type = 'cost_bundle'`), not a separate table (see Data Model rule above)
- Do NOT create a data table without pagination — use the shared TablePagination component
- Do NOT show duplicate count displays (e.g. filter count at top AND pagination count at bottom)
- Do NOT ship feature changes without updating the corresponding architecture doc
- Do NOT refactor existing code to match Bulletproof React patterns unless Stuart asks
```

**AFTER** (delete the `workspaces.budget_amount` line; all other lines unchanged):

```markdown
## What You Must NOT Do

- Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- Do NOT create database migrations, tables, columns, or constraints
- Do NOT use `sudo` for npm installs
- Do NOT hardcode dropdown values — always fetch from reference tables
- Do NOT use `alert()` or `confirm()` — use toast/modal components
- Do NOT create separate CSS/JS files — keep everything in single component files
- Do NOT assume schema from memory — check actual table/view definitions via Supabase queries
- Do NOT search for a literal `cost_bundles` table — CostBundle is a deployment-profile type (`dp_type = 'cost_bundle'`), not a separate table (see Data Model rule above)
- Do NOT create a data table without pagination — use the shared TablePagination component
- Do NOT show duplicate count displays (e.g. filter count at top AND pagination count at bottom)
- Do NOT ship feature changes without updating the corresponding architecture doc
- Do NOT refactor existing code to match Bulletproof React patterns unless Stuart asks
```

---

## File 2 — `~/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md`

### Edit C — Data Model bullet (around line 82)

**BEFORE** (lines 79-84):

```markdown
### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly. CostBundle is **not a separate table** — it is implemented as `deployment_profiles.dp_type = 'cost_bundle'` with cost/contract columns (`annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`). Canonical definition: `docs-architecture/features/cost-budget/cost-model.md` §3.3.
- **Budget data lives in workspace_budgets table**, NOT workspaces.budget_amount (that column is legacy — do not read or write to it).
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.
```

**AFTER** (identical reshape to Edit A):

```markdown
### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly. CostBundle is **not a separate table** — it is implemented as `deployment_profiles.dp_type = 'cost_bundle'` with cost/contract columns (`annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`). Canonical definition: `docs-architecture/features/cost-budget/cost-model.md` §3.3.
- **Budget data lives in the workspace_budgets table** (year-over-year, one row per fiscal year). Canonical definition: `docs-architecture/features/cost-budget/budget-management.md`.
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.
```

### Edit D — What You Must NOT Do bullet (around line 274)

**BEFORE** (lines 265-282):

```markdown
## What You Must NOT Do

- When running parallel sessions, use `git worktree` so each session has its own working directory — never `git checkout` to switch branches if other sessions may be active
- Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- Do NOT create database migrations, tables, columns, or constraints
- Do NOT use `sudo` for npm installs
- Do NOT hardcode dropdown values — always fetch from reference tables
- Do NOT use `alert()` or `confirm()` — use toast/modal components
- Do NOT create separate CSS/JS files — keep everything in single component files
- Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table
- Do NOT assume schema from memory — check actual table/view definitions via Supabase queries
- Do NOT search for a literal `cost_bundles` table — CostBundle is a deployment-profile type (`dp_type = 'cost_bundle'`), not a separate table (see Data Model rule above)
- Do NOT create a data table without pagination — use the shared TablePagination component
- Do NOT show duplicate count displays (e.g. filter count at top AND pagination count at bottom)
- Do NOT ship feature changes without updating the corresponding architecture doc
- Do NOT refactor existing code to match Bulletproof React patterns unless Stuart asks
- Do NOT put non-publishable files in `guides/` — that directory syncs live to docs.getinsync.ca. Screenshots referenced by published user-help articles are allowed under `guides/user-help/images/` (see GitBook section)
```

**AFTER** (delete the `workspaces.budget_amount` line; all other lines unchanged):

```markdown
## What You Must NOT Do

- When running parallel sessions, use `git worktree` so each session has its own working directory — never `git checkout` to switch branches if other sessions may be active
- Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- Do NOT create database migrations, tables, columns, or constraints
- Do NOT use `sudo` for npm installs
- Do NOT hardcode dropdown values — always fetch from reference tables
- Do NOT use `alert()` or `confirm()` — use toast/modal components
- Do NOT create separate CSS/JS files — keep everything in single component files
- Do NOT assume schema from memory — check actual table/view definitions via Supabase queries
- Do NOT search for a literal `cost_bundles` table — CostBundle is a deployment-profile type (`dp_type = 'cost_bundle'`), not a separate table (see Data Model rule above)
- Do NOT create a data table without pagination — use the shared TablePagination component
- Do NOT show duplicate count displays (e.g. filter count at top AND pagination count at bottom)
- Do NOT ship feature changes without updating the corresponding architecture doc
- Do NOT refactor existing code to match Bulletproof React patterns unless Stuart asks
- Do NOT put non-publishable files in `guides/` — that directory syncs live to docs.getinsync.ca. Screenshots referenced by published user-help articles are allowed under `guides/user-help/images/` (see GitBook section)
```

---

## What is NOT changing

- The "Impact Analysis" section and its "Why This Matters" scar-tissue paragraph (code-repo lines 170-198, arch-repo lines 151-179) are **kept verbatim** in both files. The paragraph is a general warning about view-to-interface drift and remains valuable independent of whether `workspaces.budget_amount` exists.
- The 18 legitimate code references to `budget_amount` on `programs`, `applications`, `it_services`, and `workspace_budgets` are all LIVE and must not be touched. See `findings-report.md` §2 for the classification table.
- `docs-architecture/features/cost-budget/budget-management.md` is not included in this diff. It already documents the as-built state correctly (see `findings-report.md` Open Items §1 for an optional follow-up phrasing tweak Stuart can make later).

## Apply order

1. Run `verify-workspaces-budget-amount-absent.sql` and visually confirm all five checks pass (see script header for expectations).
2. Apply Edits A and B to `~/Dev/getinsync-nextgen-ag/CLAUDE.md`.
3. Apply Edits C and D to `~/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md`.
4. Commit the code repo on the current feature branch and the architecture repo on `main` per dual-repo commit rules.
5. (Optional, separate commit) Update `budget-management.md` line 92 to drop the "per CLAUDE.md" phrase as described in `findings-report.md` Open Items §1.

## If Stuart prefers a purely deletive diff

If the positive-pointer reshape of Edits A / C feels like scope creep, the alternative is to simply delete the `workspaces.budget_amount` bullet entirely with no replacement. Both approaches remove the forbid-rule; the reshape just preserves the "where does budget data live" signal for future sessions. Stuart's call.
