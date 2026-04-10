# workspaces.budget_amount cleanup

Investigation of whether the legacy `workspaces.budget_amount` column can be safely dropped, along with the CLAUDE.md rules that forbid reading from it.

## Verdict

**GREEN — already dropped.** The column does not exist on the live database. It was removed via `ALTER TABLE workspaces DROP COLUMN budget_amount` at some unknown prior point, but neither CLAUDE.md file was updated. Both files still contain two forbid-rules warning against reading a column that is already gone. No code references, no view references, no function references, no orphaned data.

The scar-tissue incident the rules exist to prevent (budget page reading the wrong column after a view rewrite) cannot recur, because the column itself is gone.

## Files in this directory

| File | Purpose |
|------|---------|
| `README.md` | This file |
| `findings-report.md` | Full investigation evidence: code grep classifications, view/function classifications, data state, and classification rationale |
| `verify-workspaces-budget-amount-absent.sql` | Read-only verification script — Stuart can run this at any time to re-confirm the column is absent. Safe to execute (SELECT-only, no side effects). Drop/migration SQL is NOT provided because the drop has already happened. |
| `proposed-claudemd-rule-removal.md` | Draft before/after diffs for both CLAUDE.md files. Removes the vestigial `workspaces.budget_amount` rules (two bullets per file, four bullets total). Not yet applied — Stuart decides. |

## Execution order (when Stuart is ready)

1. Run `verify-workspaces-budget-amount-absent.sql` against the read-only connection to confirm the column is still absent (idempotent, safe to re-run).
2. Apply the CLAUDE.md diffs from `proposed-claudemd-rule-removal.md` to `~/Dev/getinsync-nextgen-ag/CLAUDE.md` and `~/getinsync-architecture/CLAUDE.md`.
3. Commit code repo (feature branch) and architecture repo (`main`) per dual-repo commit rules.

## What this session did NOT do

- Did not execute any SQL.
- Did not edit either live `CLAUDE.md` file.
- Did not touch any TypeScript, React, or hook file.
- Did not modify architecture feature docs.
- Did not commit anything outside this planning directory.

## Related prior context

The rules being removed are at:
- `~/Dev/getinsync-nextgen-ag/CLAUDE.md` line 101 (Data Model) and line 293 (What You Must NOT Do)
- `~/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md` line 82 (Data Model) and line 274 (What You Must NOT Do)

The "Why This Matters" rationale at `~/Dev/getinsync-nextgen-ag/CLAUDE.md` lines 197-198 (and the architecture-repo copy at lines 178-179) does not need to be removed — it is a general parable about view/interface drift and remains useful even after the specific column is gone. See `findings-report.md` §5 for discussion.
