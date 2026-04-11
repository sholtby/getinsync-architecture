# Session Prompt 03 — AI Chat Harness Re-Evaluation (Batch 1 measurement)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session measures the effect of Sessions 01 and 02 by re-running the 10 eval queries against the deployed Edge Function and producing a Batch 1 vs Batch 0 comparison report.

---

## Task: Re-run the 10 AI Chat eval queries and produce a Batch 1 comparison report

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code or deploy anything — this session is evaluation-only.

### Why this work exists

The GetInSync NextGen AI Chat Edge Function was evaluated on 2026-04-10 in Batch 0 and scored 2 of 10 acceptable answers. The full baseline results are in `docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md`.

Session 01 shipped code-layer fixes (new `list-applications` tool, expanded `application-detail` integration list, real `technology-risk` tool, raised iteration limit, synthesis-on-exhaustion fallback). Session 02 rewrote the system prompt with tool-selection guidance, multi-tool orchestration rules, and anti-hallucination safeguards.

This session measures the combined effect of Sessions 01 and 02 by running the same 10 queries again against the deployed Edge Function and comparing the results head-to-head against Batch 0.

The deliverable is a new file: `docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md`.

### Prerequisites — verify before you begin

**Stop if any of these are not true:**

1. **Sessions 01 and 02 have both been committed and pushed** to `feat/ai-chat-harness-eval`. Verify with:
   ```bash
   cd ~/Dev/getinsync-nextgen-ag
   git fetch origin
   git log origin/feat/ai-chat-harness-eval --oneline -20
   ```
   You should see at least two commits with messages mentioning "Batch 1" code and system prompt changes. If not, STOP and tell Stuart.

2. **The Edge Function has been deployed to the dev environment** by Stuart. You cannot verify this directly, but you can check the deployed version by looking at recent messages in `ai_chat_messages` for the conversation titles "Eval Batch 2026-04-11 A" and "Eval Batch 2026-04-11 B" (or whatever today's date is). If those conversations don't exist, STOP and tell Stuart to run the eval queries first.

3. **Stuart has run the 10 eval queries** against the deployed function. The new conversations should have today's date in the title.

### Hard rules

1. **This session is READ-ONLY.** Do not write code, do not modify any Edge Function file, do not create feature branches.
2. **You MAY write one file:** `docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md` — the comparison report.
3. **You MAY query the database via `DATABASE_READONLY_URL`** to pull traces. SELECT only, no writes.
4. **You MAY update the MEMORY.md auto-memory file** to reflect the new status of the initiative (move from "Batch 1 pending" to whatever the Batch 1 outcome is).
5. **You MUST NOT merge `feat/ai-chat-harness-eval` into `dev`.** That's Stuart's decision based on your report.
6. **You MUST preserve the Batch 0 file unchanged.** Do not edit `00-eval-results-batch-0.md`.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/ai-chat-harness-optimization/README.md
   - Understand the initiative state and decision log

2. docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md
   - The baseline you are comparing against. Read the full per-query
     scoring section and the ranked gap list. You will reproduce the
     same scoring format for Batch 1.

3. docs-architecture/planning/ai-chat-harness-optimization/01-session-prompt-harness-code.md
   - Understand what Session 01 was supposed to ship

4. docs-architecture/planning/ai-chat-harness-optimization/02-session-prompt-system-prompt.md
   - Understand what Session 02 was supposed to ship

5. supabase/functions/ai-chat/tools.ts
   supabase/functions/ai-chat/system-prompt.ts
   supabase/functions/ai-chat/index.ts
   - Read the CURRENT (Sessions 01 + 02 merged) state of the code on
     feat/ai-chat-harness-eval. You need to know what the harness looks
     like now to reason about why Batch 1 succeeded or failed where it did.

6. docs-architecture/planning/ai-chat-harness-eval-instructions.md
   - The original runbook Stuart used. Queries are listed here verbatim.
     Use the SAME 10 queries for Batch 1.
```

### Step 2 — Find the Batch 1 conversations in ai_chat_messages

Stuart should have run the 10 queries into two fresh conversations with titles like `"This is eval batch 2026-04-11 A"` and `"This is eval batch 2026-04-11 B"` (the date will be whatever today is, not 04-10).

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

psql "$DATABASE_READONLY_URL" <<'SQL'
\pset pager off
SELECT id, title, message_count, total_tokens, created_at
FROM ai_chat_conversations
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND title ILIKE '%eval batch%'
ORDER BY created_at DESC
LIMIT 10;
SQL
```

Look for two conversations newer than `2026-04-10 23:44` (the end of Batch 0). The two newest should be Batch 1 A and B.

If you find multiple runs or ambiguous titles, ask Stuart which two conversation_ids are Batch 1 before proceeding. Do not guess.

### Step 3 — Pull the full traces for both conversations

Use the same SQL pattern Batch 0 used. Dump each conversation to a temp file for analysis.

```bash
psql "$DATABASE_READONLY_URL" -At <<SQL > /tmp/conv-a-batch1.txt
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
WHERE conversation_id = '<BATCH_1_A_CONVERSATION_ID>'
ORDER BY created_at;
SQL
```

Do the same for Conversation B. Read both files in full. These are your primary evidence.

### Step 4 — Score each query against the same rubric

For each of the 10 queries, produce a scoring entry in the same format as Batch 0:

```markdown
### [VERDICT ICON] Q[N] — [Query short name] | [VERDICT LABEL]

**Prompt:** *"[verbatim prompt]"*

**Tools called:** `tool1(args)`, `tool2(args)` (N calls)

**Response quality:** [Summary of the response content and whether it is correct, shallow, wrong, or a graceful failure. Quote specific numbers or claims from the response.]

**Comparison vs Batch 0:**
- Batch 0 verdict: [verdict from 00-eval-results-batch-0.md]
- Batch 1 verdict: [new verdict]
- Change: [IMPROVED / UNCHANGED / REGRESSED]
- Root cause of change: [which gap fix is responsible, or why the expected fix didn't help]

**Verdict:** [Good / Shallow / Wrong / Graceful failure / Hard fail]
```

**Verdict icons and labels:**
- ✅ GOOD — an EA would rely on this without cross-checking
- 🟡 SHALLOW — partially correct or missing important data, but not actively harmful
- 🟡 GRACEFUL FAILURE — correct refusal with useful alternative
- 🔴 WRONG ANSWER — confidently incorrect
- 🔴 HARD FAIL — no useful output (fallback string, tool errors, empty response)

**Scoring discipline:**
- Use the same rubric you would have used for Batch 0. Do not move goalposts.
- If Batch 1 answers are more verbose, that is not automatically better — shallower with more words still scores as Shallow.
- If Batch 1 uses the new tools (`list-applications`, `technology-risk`) correctly, note that explicitly.
- If Batch 1 still hallucinates statistics, call it out — Gap 7 was in scope and a regression means the prompt fix didn't take.

### Step 5 — Produce the comparison summary

After all 10 per-query entries, produce:

1. **Batch 0 vs Batch 1 scorecard** (side by side):

   ```
   | # | Query | Batch 0 | Batch 1 | Change |
   |---|-------|---------|---------|--------|
   | 1 | CAD vs Hexagon rationalization | ✅ GOOD | ? | ? |
   ...
   ```

2. **Aggregate metrics:**
   - Acceptable-answer rate: `X/10` (Batch 0 was 2/10)
   - Useless-or-harmful rate: `X/10` (Batch 0 was 4/10)
   - Improvements: N queries moved from fail/wrong to good
   - Regressions: N queries moved from good to worse (should be 0)
   - Unchanged: N queries stayed at the same verdict

3. **Gap-by-gap effectiveness assessment:**
   For each of the Batch 1 fix gaps (1, 2, 3, 4, 5, 7, 8), report:
   - Did the fix land as intended?
   - Which query did it unblock?
   - Trace evidence of the fix working (e.g., "Q2 now called list-applications and received 5 crown jewel names in one call")
   - Any side effects (positive or negative)

4. **Recommended Batch 2 scope** (if any):
   - If any queries are still failing, propose the next fix batch
   - If the acceptable-answer rate is ≥70%, propose moving to production rollout discussion instead
   - If regressions occurred, propose a rollback or partial rollback
   - If a gap fix didn't have the expected effect, propose a root-cause investigation session

5. **Decision point for Stuart:**
   - Merge `feat/ai-chat-harness-eval` to `dev`? (recommended if acceptable rate ≥60% with zero regressions)
   - Iterate further on a Batch 2?
   - Roll back?

### Step 6 — Write the deliverable

Write the full comparison report to:
`~/getinsync-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md`

Use the same document structure as `00-eval-results-batch-0.md`:
- Frontmatter (date, namespace, branch, commit, conversation IDs)
- Executive summary (2-3 paragraphs)
- Method
- Per-query scoring (all 10)
- Scoring summary
- Comparison vs Batch 0 (the scorecard and aggregate metrics)
- Gap-by-gap effectiveness
- Batch 2 scope (if recommended)
- Decision point

Aim for ~400-600 lines — same weight as Batch 0. This report is the frozen-in-time artifact that future sessions will reference.

### Step 7 — Update the tracker and auto-memory

1. **Update README.md** in `docs-architecture/planning/ai-chat-harness-optimization/`:
   - Change Batch 1 status from "PENDING" to the actual outcome
   - Add a new row or section: Batch 1 completed [date], result: [X/10 acceptable]
   - Link to `10-eval-results-batch-1.md`

2. **Update the auto-memory file** at `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md`:
   - Change status line from "PAUSED" or "Batch 1 pending" to "Batch 1 complete — [X/10] acceptable, [merged to dev / iterating to Batch 2 / rolled back]"
   - Append a short outcome section with date and top-line metrics

3. **Do NOT update MEMORY.md** unless the pointer text needs to change (usually it doesn't).

### Step 8 — Commit to the architecture repo

The new Batch 1 results file and the README update live in `docs-architecture/` which is the architecture repo on `main`. Do NOT commit them to the code repo.

```bash
cd ~/getinsync-architecture
git add planning/ai-chat-harness-optimization/10-eval-results-batch-1.md planning/ai-chat-harness-optimization/README.md
git status --short
git commit -m "$(cat <<'EOF'
planning: AI Chat harness Batch 1 re-evaluation results

Measured the effect of Sessions 01 and 02 (code changes + system
prompt rewrite) against the Batch 0 baseline. Re-ran the same 10
eval queries against the deployed Edge Function on feat/ai-chat-harness-eval.

Batch 1 results: [X/10 acceptable] (was 2/10 in Batch 0)
[Brief one-line outcome summary]

Full comparison, per-query scoring, and Batch 2 scope recommendation
in the linked document.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Step 9 — Final session summary

Produce a short chat message for Stuart listing:

1. Batch 1 acceptable-answer rate vs Batch 0
2. The count of improvements, regressions, and unchanged
3. Top 3 notable findings (could be wins, regressions, or surprises)
4. Recommended next action (merge / Batch 2 / rollback)
5. Link to the comparison file: `planning/ai-chat-harness-optimization/10-eval-results-batch-1.md`

### Done criteria checklist

- [ ] Verified Sessions 01 and 02 landed on feat/ai-chat-harness-eval
- [ ] Verified Stuart deployed the Edge Function and ran the 10 queries
- [ ] Pulled full traces for both Batch 1 conversations
- [ ] Scored all 10 queries using the same rubric as Batch 0
- [ ] Produced per-query comparison entries showing Batch 0 → Batch 1 change
- [ ] Written `10-eval-results-batch-1.md` to the architecture repo
- [ ] Updated `README.md` with Batch 1 status
- [ ] Updated auto-memory with outcome
- [ ] Committed and pushed architecture repo on main
- [ ] Recommended next action (merge / Batch 2 / rollback)
- [ ] Session summary delivered

### What NOT to do

- Do NOT edit any Edge Function code. This session is measurement-only.
- Do NOT deploy anything. Stuart handles deployment.
- Do NOT merge `feat/ai-chat-harness-eval` into `dev`. Even if Batch 1 is a huge success, the merge decision is Stuart's, not yours.
- Do NOT modify the Batch 0 file (`00-eval-results-batch-0.md`). It is the frozen baseline.
- Do NOT move goalposts on the scoring rubric. If Batch 1 answers are longer but still wrong, they are still wrong.
- Do NOT skip quoting trace evidence for any regression. Regressions must be explained with specific trace content.
- Do NOT write a new Batch 2 session prompt unless Stuart explicitly asks for one — recommend it, but let him decide whether to proceed.
- Do NOT touch files outside `docs-architecture/planning/ai-chat-harness-optimization/` and the auto-memory file.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
