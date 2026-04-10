# Claude Code Session Prompt — CLAUDE.md Cost-Channel Clarity Fix

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — assumes no prior conversation context.
> This is a **small, surgical doc fix**. No schema work, no code work, no feature work. Expected session length: 15-30 minutes.

---

## Task: Add a clarity pointer to both CLAUDE.md files so future sessions can't misread the `dp_type = 'cost_bundle'` pattern

You are starting fresh. Read this entire brief before touching anything.

### Why this work exists

During the GitBook rollout Phase 0 readiness walk (see `docs-architecture/planning/gitbook-phase-0-readiness.md`), a competent Claude Code session with full read access to the schema file and the architecture docs made the following mistake:

- It read the CLAUDE.md rule: **"Cost data lives on cost channels (SoftwareProduct / ITService / CostBundle), NEVER on applications directly."**
- It read the parent GitBook rollout plan §4 which mentioned a "cost bundles panel" for Article 4.3.
- It queried `pg_tables` for `cost_bundles` — no result — and concluded the table did not exist.
- It wrote the Phase 0 readiness report §4.3 saying `cost_bundles` was "referenced in parent plan §4 but not implemented."
- It propagated the error into an enrichment session prompt with the instruction "**Do NOT create or reference `cost_bundles`**."
- It then wrote a schema-debt cleanup prompt framing cost_bundles as aspirational tech debt and investigating whether to build it (Option A) or delete it from the docs (Option B).

**All of the above was wrong.** Cost Bundle is already shipped. It is implemented as `deployment_profiles.dp_type = 'cost_bundle'` — a discriminator value on the DP table, not a separate table. The schema has full support for it: `annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, and `renewal_notice_days` columns all carry comments explicitly saying "Primarily for cost_bundle DPs." Views `vw_portfolio_costs` and `vw_portfolio_costs_rollup` already aggregate `WHERE dp_type = 'cost_bundle' AND cost_recurrence = 'recurring'` into a `bundle_cost` column. The canonical definition lives at `docs-architecture/features/cost-budget/cost-model.md` §3.3 and the ERD at §12 — and both are clear.

The **single root cause** of the error is that neither CLAUDE.md file mentions the implementation pattern. A session that reads CLAUDE.md plus the schema (two files that are de-facto required reading for any substantive work) sees "CostBundle" as one of three cost channels and will naturally look for a `cost_bundles` table. They will not find it. They will conclude the feature is aspirational. They will propagate that wrong conclusion into other artifacts.

**This is a rule-to-schema naming mismatch that needs a single explicit pointer.** Add the pointer, and no future session can repeat this mistake from cold context.

### Hard rules

1. **No schema changes.** No ALTER, no CREATE, no DROP.
2. **No database writes.** No INSERT/UPDATE/DELETE. Read-only SELECT verification only if needed.
3. **Scope is limited to TWO files:** `CLAUDE.md` (code repo) and `docs-architecture/CLAUDE.md` (architecture repo). Do not edit `cost-model.md`, `budget-management.md`, or any other doc — `cost-model.md` has been verified in a prior session to already document the pattern correctly at §3.3 and §12.
4. **No code changes.** You may grep `src/` read-only to confirm nothing further needs updating, but you will not modify any file under `src/`.
5. **Evidence-based edit.** Before writing the final edit text, verify two things with `grep`: (a) both CLAUDE.md files actually contain the "cost channels" rule, (b) `cost-model.md` §3.3 still contains the `dp_type = 'cost_bundle'` definition you will be pointing to. If either verification fails, stop and report.

### Step 1 — Read the required context

In this order:

```
1. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/schema-debt-cleanup-session-prompt.md
   - (you are here — this file)

2. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/planning/gitbook-phase-0-readiness.md
   - Re-read §4.3 including the "Correction (2026-04-10)" block. That block is the
     primary evidence that the rule-to-schema mismatch exists and that a session read it
     wrong already.

3. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/features/cost-budget/cost-model.md
   - Read §2 (Design Principles), §3.1, §3.2, §3.3, §4.1, §12 (ERD).
   - Confirm §3.3 clearly says: "Cost Bundle is a special DP type (dp_type = 'cost_bundle')
     for costs that don't fit the Software Product or IT Service model."
   - Note the exact section numbers you will cite in your CLAUDE.md edit.

4. /Users/stuartholtby/Dev/getinsync-nextgen-ag/CLAUDE.md
   - Find the "Architecture Rules — ALWAYS FOLLOW" section and the "Data Model" subsection.
   - Find the exact line that says "Cost data lives on cost channels..."
   - Note the line number.

5. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/CLAUDE.md
   - Find the same rule. It should be phrased similarly or identically.
   - Note the line number.
   - Note any phrasing drift between the two files — if they diverge, the fix must be
     applied to both.

6. /Users/stuartholtby/Dev/getinsync-nextgen-ag/docs-architecture/schema/nextgen-schema-current.sql
   - Grep for `dp_type`. Confirm:
     * The check constraint on deployment_profiles.dp_type includes 'cost_bundle'
     * Comments on contract_reference, contract_start_date, contract_end_date,
       renewal_notice_days, vendor_org_id, cost_recurrence all mention cost_bundle DPs
   - These are your "evidence of shipped feature" citations.
```

### Step 2 — Draft the edit

The goal is a **single-line pointer** added to the existing cost-channels rule in each CLAUDE.md file. Not a paragraph. Not a new section. A parenthetical or a footnote.

**Example of what the edit should look like (illustrative — you may adjust phrasing):**

Before:
```markdown
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly.
```

After:
```markdown
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly. CostBundle is not a separate table — it is implemented as `deployment_profiles.dp_type = 'cost_bundle'` with columns `annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`. Full definition: `docs-architecture/features/cost-budget/cost-model.md` §3.3.
```

Requirements for the edit text:

- Must fit on 1-3 lines (CLAUDE.md has a 200-line auto-load budget — every line matters; the memory-management rule in `.claude/rules/memory-management.md` is instructive here).
- Must include the literal string `dp_type = 'cost_bundle'` so a future `grep` lands on it directly.
- Must cite the canonical doc by path (`docs-architecture/features/cost-budget/cost-model.md`) and section number (§3.3).
- Must NOT invent new rules or requirements — it is a **pointer**, not a new policy.
- Should be phrased identically in both CLAUDE.md files if both files have the same rule. If phrasing already drifts between them, match the existing style of each file and flag the drift as an open item in your final report.

### Step 3 — Also check the "What You Must NOT Do" list

In `CLAUDE.md`, there is a bullet: **"Do NOT assume schema from memory — check actual table/view definitions via Supabase queries"**. That bullet is correct and needs no change. But consider whether to add a new bullet:

> **"Do NOT search for a literal `cost_bundles` table — CostBundle is a deployment-profile type (`dp_type = 'cost_bundle'`), not a separate table. See the cost-channels rule above."**

Decide based on cost/benefit: if the cost-channels rule already says it (after your Step 2 edit), this bullet may be redundant. If the cost-channels rule is many lines away from the "What NOT to do" list (different section), the redundancy is worth it because a session scanning "What NOT to do" as a checklist may not cross-reference the rules section. Use your judgment. Err toward redundancy if in doubt — this is a checklist rule, not prose.

### Step 4 — Verify and apply

1. Apply the edit to **both** CLAUDE.md files.
2. Run `wc -l` on both files. Neither should have grown by more than 3 lines.
3. Run `grep -n "dp_type = 'cost_bundle'" CLAUDE.md docs-architecture/CLAUDE.md` — both should return a match.
4. Run `grep -n "cost_bundles" CLAUDE.md docs-architecture/CLAUDE.md` — there should be no matches referencing a literal table, only (if anywhere) your edit's reference to `deployment_profiles.dp_type = 'cost_bundle'`.

### Step 5 — Commit

Two repos, two commits:

```bash
# Code repo — new feature branch off dev (per CLAUDE.md git workflow)
cd ~/Dev/getinsync-nextgen-ag
git status  # confirm starting state
git checkout dev
git pull origin dev
git checkout -b docs/claudemd-cost-bundle-clarity
git add CLAUDE.md
git commit -m "docs: add dp_type = 'cost_bundle' pointer to cost-channels rule"
git push -u origin docs/claudemd-cost-bundle-clarity

# Architecture repo — always on main
cd ~/getinsync-architecture
git add CLAUDE.md
git commit -m "docs: add dp_type = 'cost_bundle' pointer to cost-channels rule"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

You will need Stuart to merge the code-repo branch into `dev` later — mention that in your final report. Do NOT merge to `dev` yourself unless Stuart explicitly tells you to.

### Step 6 — Final session report

In your final chat message:

1. Show the diff you applied to `CLAUDE.md` (3-5 lines each file, the "after" text is fine — no need for full diff format)
2. Confirm both `grep` checks in Step 4 passed
3. Note whether you also added the "What You Must NOT Do" bullet (Step 3) and your reasoning
4. Flag any phrasing drift between the two CLAUDE.md files that existed before your edit
5. Note the code-repo feature branch name so Stuart can merge it to `dev` later
6. Remind Stuart that the companion `workspaces.budget_amount` cleanup (legacy column) was deliberately NOT included in this session — it can be a separate session if desired

### Done criteria checklist

- [ ] Both CLAUDE.md files contain the `dp_type = 'cost_bundle'` pointer with a path+section citation
- [ ] Neither CLAUDE.md file grew by more than 3 lines
- [ ] `cost-model.md` was NOT edited (verified still correct in this investigation)
- [ ] No schema changes, no database writes, no code changes
- [ ] Code repo committed on a new `docs/` feature branch and pushed
- [ ] Architecture repo committed on `main` and pushed
- [ ] Final report delivered with diff visible

### What NOT to do

- Do NOT edit `cost-model.md`, `budget-management.md`, or any other feature doc.
- Do NOT modify the schema, create migrations, or draft any SQL.
- Do NOT investigate `workspaces.budget_amount` in this session — it is out of scope. It can be its own session later.
- Do NOT expand the scope to a "full audit of rule-to-schema naming mismatches." This session is one targeted fix. If you find another suspicious mismatch while grepping, note it in your final report as an open item, do not act on it.
- Do NOT start Phase 1 of the GitBook rollout, the enrichment session, or any other in-flight work stream.
- Do NOT merge the code-repo feature branch into `dev` — leave that for Stuart.
- Do NOT rename or delete the current `docs-architecture/planning/schema-debt-cleanup-session-prompt.md` file. It is this prompt; leave it in place as historical context.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
