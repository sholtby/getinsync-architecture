# Task: Re-evaluate the AI Chat harness with the new category tools and produce a frozen results doc

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. This session is measurement-only — do not write code, do not deploy, do not merge.

### Why this work exists

Session 1 of this initiative populated Riverside with application category assignments. Session 2 shipped three new AI Chat tools (`list-application-categories`, `category` filter on `list-applications`, `category-rollup`) on the `feat/ai-chat-category-tools` branch. Stuart has deployed that branch and run a 15-query eval against the deployed Edge Function — 10 queries from the existing Batch 1 set (regression check) plus 5 new category-specific queries plus 2 cross-tool orchestration queries.

This session pulls those traces, scores them against the same rubric used in Batch 0 and Batch 1 of the AI Chat harness optimization initiative, and produces `10-eval-results-category-tools.md` — the frozen results doc that tells Stuart whether the category tools are merge-ready and whether they introduced any regressions.

You are Session 3 of 3 in the Application Categories initiative.

### Prerequisites — verify before you begin

**Stop if any of these are not true:**

1. **Session 1 SQL chunks have been pasted into the Supabase SQL Editor.** Verify with:
   ```bash
   cd ~/Dev/getinsync-nextgen-ag
   export $(grep DATABASE_READONLY_URL .env | xargs)
   psql "$DATABASE_READONLY_URL" -c "
     SELECT
       (SELECT COUNT(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id
         WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_apps,
       (SELECT COUNT(DISTINCT aca.application_id) FROM application_category_assignments aca
         JOIN applications a ON a.id = aca.application_id
         JOIN workspaces w ON a.workspace_id = w.id
         WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS apps_with_categories;
   "
   ```
   Expected: `total_apps = 32`, `apps_with_categories = 32`. If `apps_with_categories = 0`, STOP — Session 1 has not been deployed.

2. **Session 2 has been committed and pushed.** Verify with:
   ```bash
   cd ~/Dev/getinsync-nextgen-ag
   git fetch origin
   git log origin/feat/ai-chat-category-tools --oneline -5
   ```
   You should see at least one commit mentioning "AI Chat category tools" or similar. If the branch does not exist, STOP and tell Stuart Session 2 has not run.

3. **Stuart has deployed `feat/ai-chat-category-tools` to the dev environment.** You cannot verify this directly, but you can confirm by checking that the eval conversations exist in `ai_chat_messages` (Step 2 below). If they don't, Stuart hasn't deployed and run the queries yet.

4. **Stuart has run the 15 eval queries** into two fresh conversations titled like `Eval Categories YYYY-MM-DD A` and `Eval Categories YYYY-MM-DD B`. The exact date will be whatever today is.

### Hard rules

1. **This session is READ-ONLY.** No code, no Edge Function changes, no schema changes, no feature branches.
2. **You MAY write one file in the architecture repo:** `docs-architecture/planning/application-categories/10-eval-results-category-tools.md` — the frozen results doc.
3. **You MAY also update `docs-architecture/planning/application-categories/README.md`** to reflect the eval outcome and merge recommendation.
4. **You MAY query the database via `DATABASE_READONLY_URL`** to pull traces. SELECT only, no writes.
5. **You MAY update the auto-memory file** at `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md` to reflect the new state of the harness (or create a new memory file specific to the application-categories initiative if that fits better — Claude's judgment).
6. **You MUST NOT merge `feat/ai-chat-category-tools` into `dev`.** That's Stuart's decision based on your report.
7. **You MUST preserve the Batch 0 and Batch 1 result files unchanged.** Do not edit `00-eval-results-batch-0.md` or `10-eval-results-batch-1.md` in the `ai-chat-harness-optimization/` directory.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/application-categories/README.md
   - Initiative tracker, decision log, Riverside catalog, schema reference

2. docs-architecture/planning/application-categories/01-session-prompt-riverside-category-data.md
   - Session 1 brief — what data should be loaded

3. docs-architecture/planning/application-categories/02-session-prompt-ai-chat-category-tools.md
   - Session 2 brief — what tools should be available now

4. docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md
   - The Batch 1 results doc. Read the per-query scoring section IN
     FULL — it is the regression baseline for the 10 existing queries
     in the Step 4 scoring. The Batch 1 verdicts are what you compare
     against for regression analysis.

5. docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md
   - The Batch 0 baseline. Read the rubric (verdict definitions) and
     the format of per-query entries. You will reproduce the same
     scoring format for the category eval.

6. supabase/functions/ai-chat/tools.ts
   supabase/functions/ai-chat/system-prompt.ts
   - Read the CURRENT state on feat/ai-chat-category-tools. You need to
     know what tools the deployed harness has and what the prompt says
     so you can reason about why the eval succeeded or failed where it
     did. Check out the branch first if needed:
       git fetch origin && git checkout feat/ai-chat-category-tools
     Then read the files. Switch back to your working branch (or stay
     on this branch — you are not editing code).

7. docs-architecture/planning/application-categories/README.md
   - The 15 eval queries are listed below in Step 3 of this brief, but
     verify against the README's "Decision log" entry on the eval set
     in case Stuart edited the queries before running them.
```

### Step 2 — Find the eval conversations in ai_chat_messages

Stuart should have run the queries into two fresh conversations with titles like `Eval Categories 2026-04-XX A` and `Eval Categories 2026-04-XX B` where the date is whatever today is.

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

psql "$DATABASE_READONLY_URL" <<'SQL'
\pset pager off
SELECT id, title, message_count, total_tokens, created_at
FROM ai_chat_conversations
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND title ILIKE '%eval categories%'
ORDER BY created_at DESC
LIMIT 10;
SQL
```

If the search by title `'eval categories'` returns nothing, try a broader match like `'eval%'` and look for conversations newer than the Batch 1 conversations (the most recent eval conversations were created on 2026-04-11).

If you find multiple runs or ambiguous titles, ask Stuart which two conversation_ids are the category eval before proceeding. Do not guess.

### Step 3 — The 15 queries (verbatim, in order)

Stuart should have pasted these into the two conversations in this order. Conversation A holds the 10 regression queries (1-10) and the 5 new category queries (11-15). Conversation B holds the 2 cross-tool queries (16-17). Numbering keeps the Batch 1 ordering for the regression set.

**Conversation A — regression + category queries:**

1. *"We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?"* (Q1 from Batch 1 — regression)
2. *"Which of my crown jewel applications are at highest risk? Rank them."* (Q2 from Batch 1 — regression)
3. *"If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?"* (Q3 from Batch 1 — regression)
4. *"How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?"* (Q4 from Batch 1 — regression)
5. *"What's the top risk in the Police Department workspace right now?"* (Q5 from Batch 1 — regression)
6. *"Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective."* (Q6 from Batch 1 — regression)
7. *"If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"* (Q8 from Batch 1 — regression. Note: Q7 is in Conversation B per the original eval design.)
8. *"Which applications in our portfolio handle PII and what's their assessment status?"* (Q9 from Batch 1 — regression)
9. *"What data am I missing to run a proper portfolio review next week?"* (Q10 from Batch 1 — regression)
10. *"What applications do we have for Customer Relationship Management?"* (Q11 — new category query, EA "what do I have for X")
11. *"List my Finance applications."* (Q12 — new category query, simple list with category filter)
12. *"Show me my portfolio by capability."* (Q13 — new category query, category-rollup direct)
13. *"Which categories have no crown jewels assigned?"* (Q14 — new category query, requires category-rollup + crown_jewel_count interpretation)
14. *"What do I have to manage citizen service requests?"* (Q15 — new category query, semantic match against CRM & Citizen Services)

**Conversation B — Q7 multi-turn memory test (preserved from Batch 1) + 2 cross-tool queries:**

15. **Q7 Turn 1:** *"List the applications in the Finance workspace."* (regression)
16. **Q7 Turn 2:** *"Which of those have budget data?"* (regression — multi-turn memory)
17. *"Which application category carries the most technical debt?"* (Q16 — cross-tool: category-rollup + technology-risk)
18. *"Which workspace has the most application sprawl, and what categories are over-represented there?"* (Q17 — cross-tool: list-workspaces + list-applications per workspace + category-rollup)

That's 17 scoring entries total across 15 distinct prompts (Q7 has Turn 1 and Turn 2 both scored), matching the Batch 1 entry count plus the new category and cross-tool additions.

If Stuart pasted the queries in a different order or split between conversations differently, adapt the scoring to whatever sequence the traces show. Document any deviation in the final report.

### Step 4 — Pull the full traces for both conversations

Use the same SQL pattern Batch 1 used. Dump each conversation to a temp file.

```bash
psql "$DATABASE_READONLY_URL" -At <<SQL > /tmp/conv-a-categories.txt
SELECT
  '=== SEQ ' || ROW_NUMBER() OVER (ORDER BY created_at) ||
  ' | role=' || role ||
  COALESCE(' | tool=' || tool_name, '') ||
  ' | tokens=' || token_count || ' ===' || E'\n' ||
  COALESCE('[CONTENT] ' || content, '') ||
  COALESCE(E'\n[TOOL_INPUT] ' || tool_input::text, '') ||
  COALESCE(E'\n[TOOL_OUTPUT] ' || tool_output::text, '') ||
  E'\n'
FROM ai_chat_messages
WHERE conversation_id = '<CONV_A_ID>'
ORDER BY created_at;
SQL
```

Same for Conversation B. Read both files in full. These are your primary evidence.

### Step 5 — Score each query against the same rubric

For each of the 17 scoring entries, produce an entry in the same format as Batch 1:

```markdown
### [VERDICT ICON] Q[N] — [Query short name] | [VERDICT LABEL]

**Prompt:** *"[verbatim prompt]"*

**Tools called:** `tool1(args)`, `tool2(args)` (N calls)

**Response quality:** [Summary of the response content. Quote specific numbers or claims.]

**Comparison vs Batch 1 (regression queries) OR vs ideal (new queries):**
- For Q1-Q10 and Q7a/b: Batch 1 verdict, this run's verdict, change (IMPROVED / UNCHANGED / REGRESSED), root cause if changed
- For Q11-Q15 and Q16-Q17: ideal answer, this run's answer, gap analysis if any

**Verdict:** [Good / Shallow / Wrong / Graceful failure / Hard fail]
```

**Verdict icons and labels (held constant from Batch 0):**
- ✅ GOOD — an EA would rely on this without cross-checking
- 🟡 SHALLOW — partially correct or missing important data, but not actively harmful
- 🟡 GRACEFUL FAILURE — correct refusal with useful alternative
- 🔴 WRONG ANSWER — confidently incorrect
- 🔴 HARD FAIL — no useful output

**Scoring discipline:**
- Hold the rubric constant. Do not move goalposts.
- For the regression set (Q1-Q10, Q7a, Q7b): note explicitly whether Batch 2 prompt fixes are present in this build. They probably are NOT (this branch is `feat/ai-chat-category-tools` from `dev`, which does not have the Batch 2 changes from `feat/ai-chat-harness-eval`). So the regression baseline is the *Batch 1* verdict, not a hypothetical post-Batch-2 state. Q1, Q4, Q9 may still show their Batch 1 regressions/shape-changes — that's expected, NOT a category tool failure.
- For the new category queries: the bar is whether an EA could rely on the answer. Empty result sets are a failure if the data exists; "no apps in this category" is a graceful failure if the data is genuinely empty.
- For the cross-tool queries: the model must call AT LEAST 2 tools and synthesize across them. A single-tool answer to a cross-tool prompt is a failure (it means the orchestration rule didn't fire).

### Step 6 — Produce the comparison summary

After all 17 per-query entries, produce:

1. **Regression scorecard (10 Batch 1 queries + Q7a + Q7b):**
   ```
   | # | Query | Batch 1 | This run | Change |
   |---|-------|---------|----------|--------|
   ...
   ```

2. **New query scorecard (5 category + 2 cross-tool):**
   ```
   | # | Query | Verdict | Notes |
   |---|-------|---------|-------|
   ...
   ```

3. **Aggregate metrics:**
   - Regression rate: how many of the 12 regression entries changed verdict (target: 0)
   - Category-tool acceptable rate: of the 7 new queries (5 category + 2 cross-tool), how many are GOOD or GRACEFUL FAILURE
   - Tool-usage stats: how many of the 7 new queries used `list-application-categories`, `list-applications(category=...)`, `category-rollup` correctly

4. **Tool-by-tool effectiveness:**
   For each of the three new tools:
   - Was it called when expected?
   - Did the output look correct?
   - Did the model use the output to compose a useful answer?
   - Trace evidence

5. **Cross-tool orchestration assessment:**
   - Did the cross-tool subheading in the system prompt ("category-rollup composes well with other tools…") fire on Q16 and Q17?
   - If not, what stopped the model from orchestrating? (Was it tool-selection guidance gap, missing description, bad rollup output shape, etc.)

6. **Merge recommendation for `feat/ai-chat-category-tools`:**
   - Merge to `dev` if: 0 regressions AND ≥5/7 of the new queries are GOOD AND both cross-tool queries used multiple tools
   - Iterate if: 0 regressions but new queries are shallow → propose specific prompt or tool fixes
   - Roll back if: any regression in the Batch 1 baseline OR a cross-tool query gave a confidently wrong answer

7. **Decision point for Stuart**

### Step 7 — Write the deliverable

Write the full report to:
`~/getinsync-architecture/planning/application-categories/10-eval-results-category-tools.md`

Use the same document structure as Batch 0 / Batch 1:
- Frontmatter (date, namespace, branch, commit SHAs, conversation IDs)
- Executive summary (2-3 paragraphs)
- Method
- Per-query scoring (all 17)
- Regression scorecard
- New query scorecard
- Aggregate metrics
- Tool-by-tool effectiveness
- Cross-tool orchestration assessment
- Merge recommendation
- Decision point

Aim for 400-600 lines, same weight as the Batch 1 report.

### Step 8 — Update the tracker and auto-memory

1. **Update `application-categories/README.md`** with the eval outcome and merge recommendation.

2. **Update auto-memory.** Either edit the existing `ai-chat-harness-optimization.md` memory file to add a section on the application-categories initiative, OR create a new memory file `application-categories.md` and add a pointer to it from `MEMORY.md`. Use whichever is more readable.

### Step 9 — Commit to the architecture repo

```bash
cd ~/getinsync-architecture
git add planning/application-categories/10-eval-results-category-tools.md planning/application-categories/README.md
git status --short

git commit -m "$(cat <<'EOF'
planning: AI Chat category tools eval results

Re-evaluated the AI Chat harness after Sessions 1 and 2 of the
application-categories initiative shipped (Riverside category data
loaded, three new category tools deployed on feat/ai-chat-category-tools).

Eval set: 17 scoring entries
- 10 regression queries from Batch 1 (Q1-Q10 minus Q7, plus Q8 numbering shift)
- Q7 Turn 1 + Turn 2 (multi-turn memory regression check)
- 5 new category queries (list/filter/rollup direct probes)
- 2 cross-tool queries (category-rollup + other tools)

Result summary: [REGRESSION COUNT] regressions of [N] baseline queries,
[X/7] new queries acceptable, [Y/2] cross-tool queries used multiple
tools as instructed.

Merge recommendation: [MERGE / ITERATE / ROLLBACK]

Full per-query scoring, tool-by-tool effectiveness, and merge decision
in the linked document.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)" && git push origin main

cd ~/Dev/getinsync-nextgen-ag
```

### Step 10 — Final session summary

Produce a short chat message for Stuart listing:

1. Regression count vs Batch 1 baseline (target 0)
2. New query acceptable rate (5 category + 2 cross-tool)
3. Top 3 notable findings (could be wins, regressions, or surprises)
4. Recommended next action (merge / iterate / rollback)
5. Link to the comparison file: `planning/application-categories/10-eval-results-category-tools.md`

### Done criteria checklist

- [ ] Verified Session 1 SQL is loaded (32 apps with category assignments)
- [ ] Verified Session 2 branch exists and has commits
- [ ] Verified Stuart deployed and ran the 15 queries (eval conversations exist)
- [ ] Pulled full traces for both eval conversations
- [ ] Read the current `feat/ai-chat-category-tools` state of `tools.ts` and `system-prompt.ts`
- [ ] Scored all 17 entries using the same Batch 0/1 rubric
- [ ] Produced regression scorecard (12 entries: Q1-Q6, Q8-Q10, Q7a, Q7b)
- [ ] Produced new-query scorecard (7 entries: Q11-Q17)
- [ ] Produced tool-by-tool effectiveness analysis
- [ ] Produced cross-tool orchestration assessment
- [ ] Written `10-eval-results-category-tools.md` to the architecture repo
- [ ] Updated `application-categories/README.md` with results
- [ ] Updated auto-memory with outcome
- [ ] Committed and pushed architecture repo on main
- [ ] Recommended next action (merge / iterate / rollback)
- [ ] Session summary delivered

### What NOT to do

- Do NOT edit any Edge Function code. This session is measurement-only.
- Do NOT deploy anything. Stuart handles deployment.
- Do NOT merge `feat/ai-chat-category-tools` into `dev`. Even if the eval is a huge success, the merge decision is Stuart's.
- Do NOT modify Batch 0 or Batch 1 results files. They are frozen baselines.
- Do NOT move goalposts on the scoring rubric. If a regression query is shallower in this run than in Batch 1, that's a regression — score it as such.
- Do NOT skip quoting trace evidence for any regression. Regressions must be explained with specific trace content.
- Do NOT confuse the absence of Batch 2's prompt fixes with category-tool failures. The Batch 1 verdicts on Q1, Q4, Q9 are expected to persist on this branch because Batch 2 is on a different branch. Note this explicitly in the report so the reader does not blame the category tools.
- Do NOT touch files outside `docs-architecture/planning/application-categories/` and the auto-memory file.
- Do NOT create new categories or modify the catalog. The catalog is the catalog.
- Do NOT ship a Session 4 prompt unless Stuart explicitly asks for one — propose it in the merge recommendation if needed.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
