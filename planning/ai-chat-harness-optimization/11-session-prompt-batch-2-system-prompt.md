# Session Prompt 11 — AI Chat System Prompt Batch 2 (rationalization, temporal, classification refusals)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session adds three new subheadings to `supabase/functions/ai-chat/system-prompt.ts` on the `feat/ai-chat-harness-eval` branch. It does NOT modify tool code, index code, types, or anything else.

---

## Task: Add Batch 2 prompt-only fixes to the AI Chat system prompt

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code until you have completed Step 1 (read required context).

### Why this work exists

The GetInSync NextGen AI Chat Edge Function at `supabase/functions/ai-chat/` was re-evaluated on 2026-04-11 after Batch 1 shipped (Sessions 01 + 02). Batch 1 moved the harness from 2/10 acceptable answers to **6/10 acceptable** — a 3× improvement — but introduced two regressions and one shape-shift that block merging `feat/ai-chat-harness-eval` to `dev`. The full Batch 1 report, trace evidence, and the Batch 2 fix recommendation live in `docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md`. Read that file in Step 1.

The three issues this session fixes:

- **Q1 (CAD vs Hexagon rationalization) — REGRESSION** from GOOD to WRONG. The model now recommends consolidating TO Hexagon (extended lifecycle, XL remediation effort, tech health 32, no assigned owner) instead of TO Computer-Aided Dispatch (mainstream lifecycle, L remediation, tech health 48.75, named owner). Identical tool data on both Batch 0 and Batch 1 runs. The Batch 1 system prompt added orchestration rules but did not encode rationalization-direction semantics.

- **Q4 (6-month tech debt trend) — REGRESSION** from GOOD (graceful failure) to SHALLOW. The model now wastes a `portfolio-summary` call before producing an implicit "no historical data" framing. Root cause: the new no-hallucinated-stats rule over-corrected toward "always call a tool" and the model lost the graceful-failure reflex on questions whose correct answer is "no such data exists in the schema."

- **Q9 (PII applications) — SHAPE CHANGE** (verdict unchanged at SHALLOW). The hallucinated "32% assessed" stat is gone (Gap 7 fix worked), but the model now infers PII classifications from application names instead of refusing outright. This looks like classification but is not, and an EA might act on the inferred list as if it were authoritative.

All three are **prompt-layer** issues. None require code, schema, or tool changes. The Batch 1 report drafted the three prompt additions verbatim and projected Batch 2 to land at **9/10 acceptable**.

You are Session 11 (the only session in Batch 2 — there is no Session 12 yet because re-evaluation will reuse the existing `03-session-prompt-re-evaluation.md` template).

### Hard rules (read before touching anything)

1. **You MUST work on the `feat/ai-chat-harness-eval` branch.** Verify with `git branch --show-current`. The branch already has Sessions 01 and 02 merged plus the JWT gate fix — do not rebase or reset it.
2. **You MAY only edit one file:** `supabase/functions/ai-chat/system-prompt.ts`
3. **You MUST NOT edit:**
   - `supabase/functions/ai-chat/tools.ts`
   - `supabase/functions/ai-chat/index.ts`
   - `supabase/functions/ai-chat/types.ts`
   - any database schema, migrations, or views
   - any file in `docs-architecture/` (the architecture repo — the re-eval session will write the next results file there)
   - any file outside `supabase/functions/ai-chat/`
4. **You MUST NOT touch any existing rule in `system-prompt.ts`.** This session only INSERTS new subheadings under `## Tool selection rules`. No edits to existing sections, no deletions, no rewording, no "while I'm here" cleanup.
5. **You MUST NOT remove or weaken the no-hallucinated-stats rule** in the existing `## Response rules` section. Addition 2 below is the carve-out that complements it — the rule itself stays unchanged.
6. **You MUST NOT remove or weaken the negative example** in the existing `### Risk questions` subsection. Addition 1 below adds a *different* negative example for rationalization, sitting alongside the cost-as-risk one.
7. **You MUST NOT add a new tool, change a tool description, or change `TOOL_DEFINITIONS` in any way.** Stuart has not approved a real `data-quality` tool yet, and Addition 3 specifically tells the model to refuse rather than infer.
8. **You MUST run `npx tsc --noEmit` after your change** and it must pass with zero errors. The system prompt is a TypeScript template literal, so backticks, dollar signs, and curly braces are easy to break.
9. **You MUST NOT deploy the Edge Function.** Stuart deploys manually via `supabase functions deploy ai-chat` after this session merges.
10. **You MUST NOT merge `feat/ai-chat-harness-eval` to `dev`.** Re-evaluation must run first to confirm the Batch 2 additions land cleanly with no new regressions.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md
   - The source of truth for what regressed and why.
   - Pay close attention to:
     * The per-query sections for Q1, Q4, and Q9 (trace evidence and root-cause hypotheses)
     * The "Recommended Batch 2 scope" section near the end — it contains the three
       prompt additions you will be inserting. The text in this brief matches that
       section verbatim; if you find any drift between this brief and the Batch 1
       report, the Batch 1 report wins.

2. docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md
   - For context on the baseline failure modes the existing rules were designed to
     prevent. Useful when reasoning about whether your additions might interfere with
     existing rules.

3. docs-architecture/planning/ai-chat-harness-optimization/README.md
   - For execution-order context and the Batch 1 → Batch 2 decision log.

4. supabase/functions/ai-chat/system-prompt.ts (entire file)
   - The file you will edit. Note the existing `## Tool selection rules` section
     and its current subheadings: "Listing and ranking", "Risk questions",
     "Analytical framework questions", "Workspace-scoped questions". Your three
     additions go between "Risk questions" and "Analytical framework questions"
     (see the insertion-order spec below).

5. supabase/functions/ai-chat/tools.ts (read-only — DO NOT edit)
   - Read this only to confirm the tool names and behaviors referenced in the
     existing prompt still match what's in the code. If you find a drift, STOP
     and tell Stuart — do NOT silently update tool descriptions in the prompt.

6. CLAUDE.md (at repo root)
   - Read "Architecture Rules", "Database Access", and "What You Must NOT Do".
```

You do NOT need to use `DATABASE_READONLY_URL` for this session — there are no new SQL queries, no new tools, no schema work.

### Step 2 — Understand the insertion structure

The current relevant structure of `system-prompt.ts` (verified by the planning session that produced this brief):

```
## Available tools           ← do not touch
## Tool selection rules      ← three new subheadings inserted under this section
  ### Listing and ranking questions    [existing — do not touch]
  ### Risk questions                    [existing — do not touch]
  ### Rationalization and consolidation questions    [NEW Addition 1]
  ### Temporal and historical questions               [NEW Addition 2]
  ### Data classification and compliance questions    [NEW Addition 3]
  ### Analytical framework questions    [existing — do not touch]
  ### Workspace-scoped questions        [existing — do not touch]
## Cost rules                ← do not touch
## Assessment rules          ← do not touch
## Technology rules          ← do not touch
## Data scope and access     ← do not touch
## Response rules            ← do not touch (already has the no-hallucinated-stats rule)
```

**Order matters.** The three new subheadings go AFTER `### Risk questions` and BEFORE `### Analytical framework questions`. The reason: the rationalization rule needs to be visible to the model before it kicks into SWOT-style multi-tool orchestration, because Q6 SWOT in the Batch 1 trace carries the same rationalization-direction error as Q1 (its Opportunities section implicitly recommends consolidating TO Hexagon).

### Step 3 — The three prompt additions to insert

These three blocks are taken verbatim from the "Recommended Batch 2 scope" section of `10-eval-results-batch-1.md`. Insert them in the order shown, as three new `### subheading` blocks under `## Tool selection rules`, in the position spec'd above.

When you insert these into the template literal in `system-prompt.ts`, remember:
- The whole prompt is one big template literal returned from `buildSystemPrompt(...)`. Markdown headers, lists, and bold tags pass through as plain text.
- Backticks inside the template literal must be escaped with a backslash (\\\`) — the existing prompt already does this for the worked example in "Risk questions" and the inline code references like `cost-analysis`. Match the existing escaping style.
- Dollar signs are NOT escaped in the existing prompt (because no `${}` interpolation appears inside the prose). Check that none of the additions below introduce a literal `${` pattern that would be interpreted as a template expression. If you need a literal `$` sign, plain `$` is fine; only `${...}` needs escaping as `\\${...}`.

#### Addition 1 — Rationalization direction semantics (fixes Q1)

New subheading: `### Rationalization and consolidation questions`

Body text (insert verbatim, formatted as the existing subheadings are — short paragraph + bullet list + worked negative example):

> When asked which of two overlapping applications to rationalize TO or consolidate TO, prefer the application with:
>
> 1. Higher tech_health (less technical debt to carry forward)
> 2. Lower remediation_effort (XS/S/M are preferred over L/XL/2XL)
> 3. Mainstream lifecycle (not extended, end_of_support, or end_of_life)
> 4. Assigned owner (named owner preferred over unassigned)
>
> Only after those factors favor one system OR are tied should you weigh criticality delta, functional coverage, or integration ecosystem. An application on extended support with XL remediation effort is NOT a good consolidation target regardless of how much functional coverage it offers — you will have to migrate off it anyway within its support window.
>
> **Negative example (what NOT to do):**
> User: "We have CAD (tech health 48.75, mainstream, L effort, owner assigned) and Hexagon (tech health 32, extended, XL effort, no owner). Which one should we rationalize to?"
> WRONG: recommend Hexagon because it has broader functional coverage.
> RIGHT: recommend CAD because it is healthier, lower-effort, mainstream-lifecycle, and has a named owner. Hexagon's extended lifecycle and XL remediation effort make it a poor consolidation target.

#### Addition 2 — Temporal and historical question refusal (fixes Q4)

New subheading: `### Temporal and historical questions`

Body text:

> When the user asks about "trend", "over time", "last 6 months", "compared to last quarter", "year over year", "historically", or any other question that requires time-series data: **refuse gracefully WITHOUT calling a tool**. The portfolio model does not store historical snapshots — there is no time-series data anywhere in your tool surface. Say so clearly and offer to provide a current-state view if that would help.
>
> Do NOT call portfolio-summary just to cite current numbers as if they were a trend. Calling a tool when the answer is "no historical data exists" is a worse outcome than a clean refusal — it implies a trend answer that the data cannot support. The no-hallucinated-stats rule (see Response rules) applies to NUMBERS you cite, not to whether you call a tool when no useful tool exists.

#### Addition 3 — Data classification and compliance refusal (fixes Q9)

New subheading: `### Data classification and compliance questions`

Body text:

> When the user asks about PII, PHI, data classification, GDPR, HIPAA, SOX, compliance scope, data sensitivity, or "which apps handle [category] data": **refuse gracefully**. The harness does NOT have a data-classification tool, and inferring data classifications from application names is unreliable (a system named "Police Records Management" might or might not store PII the way the user means it).
>
> Tell the user that data classification is not currently tracked in the portfolio model, and suggest what you CAN offer instead (e.g., assessment status, ownership, criticality, lifecycle status). Do not produce a "likely PII-handling applications" list inferred from names — this looks like classification but is not, and an EA may act on it as if it were.

### Step 4 — Implementation approach

1. Open `supabase/functions/ai-chat/system-prompt.ts` with the Read tool first (required before Edit).
2. Locate the existing `### Risk questions` subheading and read forward through to `### Analytical framework questions` so you understand the existing escape style for inline `code spans`, the existing bullet-list style, and the existing negative-example formatting.
3. Use a single Edit tool call (or three sequential Edit calls — your choice) to insert the three new subheadings in the spec'd order between "Risk questions" and "Analytical framework questions". Make sure the surrounding blank lines match the rest of the file's spacing — the existing prompt uses one blank line between subheadings.
4. Do NOT reformat anything else. Do NOT touch any other section.

### Step 5 — Verify and commit

1. Run `npx tsc --noEmit` from the repo root. Zero errors required. A common failure mode is breaking template literal syntax — check that no unescaped `${` was introduced and that backticks inside the literal are still escaped where they were before.

2. Run `git status` and confirm the only modified file is `supabase/functions/ai-chat/system-prompt.ts`. Nothing else.

3. Run `git diff supabase/functions/ai-chat/system-prompt.ts` and sanity-check the diff:
   - Should show ONLY additions under `## Tool selection rules`, between "Risk questions" and "Analytical framework questions"
   - Should show ZERO deletions (no `-` lines)
   - Should show ZERO changes to any other section

4. Commit with this HEREDOC message:

```bash
git add supabase/functions/ai-chat/system-prompt.ts

git commit -m "$(cat <<'EOF'
feat: AI Chat system prompt Batch 2 (rationalization, temporal, classification refusals)

Addresses the regressions and shape-changes identified in Batch 1 re-eval
(docs-architecture/planning/ai-chat-harness-optimization/10-eval-results-batch-1.md):

- Q1 (REGRESSION): rationalization-direction semantics added to prefer
  the healthier/lower-effort/mainstream-lifecycle/owned system as the
  consolidation target. Includes negative example matching the actual
  Batch 1 Q1 failure pattern.
- Q4 (REGRESSION): temporal/historical question refusal rule reinstates
  graceful failure for trend / time-series questions and explicitly carves
  this out from the no-hallucinated-stats rule.
- Q9 (SHAPE CHANGE): data-classification refusal rule prevents inferring
  PII labels from application names. Tells the model to suggest what
  assessment data IS available instead.

All three are prompt-only additions to the Tool selection rules section.
No tool, code, or schema changes. tools.ts and index.ts unchanged.

Next: Stuart deploys with \`supabase functions deploy ai-chat\`, runs
the 10 eval queries against fresh conversations titled "Eval Batch
2026-04-12 A" / "Eval Batch 2026-04-12 B", then a re-eval session
produces 20-eval-results-batch-2.md.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

5. Push:
```bash
git push origin feat/ai-chat-harness-eval
```

### Step 6 — Session summary

Produce a short final message listing:

1. Confirmation that `npx tsc --noEmit` passed with zero errors
2. The line count of `system-prompt.ts` before and after
3. The three new subheading names you inserted, in order
4. Confirmation that no existing rules were touched
5. A one-line summary of next steps:
   *"Ready for Stuart to deploy the Edge Function and re-run the 10 eval queries. Deploy with: `supabase functions deploy ai-chat` from the repo root. After Stuart runs the queries into fresh conversations titled 'Eval Batch 2026-04-12 A' and 'Eval Batch 2026-04-12 B', use the existing `03-session-prompt-re-evaluation.md` template (with the conversation IDs and date updated) to produce `20-eval-results-batch-2.md`."*

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] Existing `### Risk questions` and `### Analytical framework questions` subheadings located in `system-prompt.ts`
- [ ] `### Rationalization and consolidation questions` subheading inserted with verbatim text from Addition 1
- [ ] `### Temporal and historical questions` subheading inserted with verbatim text from Addition 2
- [ ] `### Data classification and compliance questions` subheading inserted with verbatim text from Addition 3
- [ ] All three new subheadings sit between "Risk questions" and "Analytical framework questions" in the order spec'd
- [ ] No existing rule, header, bullet, or example was modified or removed
- [ ] No-hallucinated-stats rule in `## Response rules` is unchanged
- [ ] Risk-questions negative example is unchanged
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `git status` shows only `supabase/functions/ai-chat/system-prompt.ts` modified
- [ ] `git diff` shows only additions, zero deletions
- [ ] `tools.ts`, `index.ts`, `types.ts` are UNCHANGED
- [ ] Changes committed to `feat/ai-chat-harness-eval` branch
- [ ] Branch pushed to origin
- [ ] Session summary produced

### What NOT to do

- Do NOT edit `tools.ts`, `index.ts`, or `types.ts`. Batch 2 is prompt-only.
- Do NOT touch any existing rule in `system-prompt.ts`. Insertions only.
- Do NOT remove or weaken the no-hallucinated-stats rule in Response rules. Addition 2 is the carve-out, but the rule itself stays.
- Do NOT remove or weaken the cost-as-risk negative example in the existing "Risk questions" section.
- Do NOT add a new tool. Stuart has not approved a real `data-quality` tool yet, and Addition 3 specifically tells the model to refuse rather than infer.
- Do NOT deploy the Edge Function. Stuart deploys after this session lands.
- Do NOT merge `feat/ai-chat-harness-eval` to `dev`. Re-evaluation must run first.
- Do NOT modify the Batch 0 or Batch 1 results files. They are frozen baselines.
- Do NOT modify `docs-architecture/` at all — Batch 2 results will be written there by the re-eval session, not this one.
- Do NOT touch `supabase/functions/ai-generate/`, `supabase/functions/apm-chat/`, or any other Edge Function. Only `ai-chat` is in scope.
- Do NOT add new dependencies, imports, or types.
- Do NOT reformat the file. Match the existing whitespace style exactly.
- Do NOT write tests, scaffolding, or new docs. The re-eval session measures the effect.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
