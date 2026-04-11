# AI Chat Harness Optimization — Tracker

> **Purpose:** Hub directory for the Meta-Harness Option B initiative — auditing and iteratively improving the GetInSync NextGen AI Chat Edge Function based on real eval data.
>
> **Branch:** All code changes land on `feat/ai-chat-harness-eval` in `~/Dev/getinsync-nextgen-ag`.
>
> **Method:** Stanford Meta-Harness paper (Lee et al., arXiv 2603.28052, Mar 2026), adapted to a manual iterative loop — run eval, score, identify gaps, apply fixes, re-run eval, measure improvement.

---

## Status

- **Batch 0** — Baseline eval COMPLETE (10 queries run on Riverside post-Phase-0). See `00-eval-results-batch-0.md`. Result: **2/10 acceptable**.
- **Batch 1** — COMPLETE 2026-04-11. All 3 sessions shipped; Edge Function deployed; re-eval run. See `10-eval-results-batch-1.md`. Result: **6/10 acceptable** (3× improvement from Batch 0). 8 improvements, 2 regressions (Q1 rationalization direction, Q4 temporal refusal).
- **Batch 2** — COMPLETE 2026-04-11. Prompt-only Session 11 shipped (commit `b17075a`); Edge Function deployed; re-eval run. See `20-eval-results-batch-2.md`. Result: **10/10 acceptable** (perfect score). Both Batch 1 regressions resolved, Q9 shape change resolved, Q10 unexpectedly improved from SHALLOW to GOOD. Zero regressions. **Branch `feat/ai-chat-harness-eval` is now ready to merge to `dev`.**

---

## Files in this directory

| File | Purpose | Status |
|---|---|---|
| `README.md` | This file — tracker and index | Current |
| `00-eval-results-batch-0.md` | Frozen-in-time baseline eval: 10 queries, per-query scoring, ranked gap list, fix batching recommendation | Complete (2/10 acceptable) |
| `01-session-prompt-harness-code.md` | Standalone session prompt — implements code-layer fixes (new tool, iteration limit, fallback, unstub technology-risk) | Shipped (commit `473be25`) |
| `02-session-prompt-system-prompt.md` | Standalone session prompt — rewrites `system-prompt.ts` to address tool-selection, hallucination, and orchestration gaps | Shipped (commit `25c7a6d`) |
| `03-session-prompt-re-evaluation.md` | Standalone session prompt — reruns the 10 queries and produces a comparison report (template, used for both Batch 1 and Batch 2 re-evals) | Reusable template |
| `10-eval-results-batch-1.md` | Frozen-in-time Batch 1 re-eval: all 10 queries scored against Batch 0, gap-by-gap effectiveness, recommended Batch 2 scope | Complete (6/10 acceptable, 8 improvements, 2 regressions) |
| `11-session-prompt-batch-2-system-prompt.md` | Standalone session prompt — adds three subheadings to `system-prompt.ts` (rationalization, temporal, classification refusals) | Shipped (commit `b17075a`) |
| `20-eval-results-batch-2.md` | Frozen-in-time Batch 2 re-eval: all 10 queries scored against Batch 1, effectiveness of the three Batch 2 prompt additions, merge recommendation | Complete (10/10 acceptable, 4 improvements, 0 regressions) |

## Related files (not in this directory)

- `planning/ai-chat-harness-eval-instructions.md` — the Batch 0 "what Stuart needs to do" runbook (executed 2026-04-10)
- `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md` — Claude auto-memory for the initiative (pointer in MEMORY.md)
- `supabase/functions/ai-chat/` — the actual harness code in the NextGen repo

---

## Execution order

The three session prompts in this directory are designed to run **in strict order**:

```
┌────────────────────────────────────────────────────┐
│  1. Open 01-session-prompt-harness-code.md         │
│     → paste into fresh Claude Code session          │
│     → session commits code to feat/ai-chat-harness-eval │
│     → session pushes branch, reports done           │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────┐
│  2. Open 02-session-prompt-system-prompt.md        │
│     → paste into fresh Claude Code session          │
│     → session commits prompt rewrite to same branch │
│     → session pushes branch, reports done           │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────┐
│  [Stuart deploys ai-chat Edge Function to dev]     │
│     supabase functions deploy ai-chat              │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────┐
│  [Stuart runs the 10 queries against dev AI Chat]  │
│     uses conversation titles "Eval Batch 2026-XX-YY A/B" │
│     same queries as Batch 0, different batch date  │
└────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────┐
│  3. Open 03-session-prompt-re-evaluation.md        │
│     → paste into fresh Claude Code session          │
│     → session pulls new traces from ai_chat_messages│
│     → produces Batch 1 vs Batch 0 comparison       │
│     → writes 10-eval-results-batch-1.md             │
└────────────────────────────────────────────────────┘
```

**Parallelism note:** Sessions 1 and 2 touch different files and could in principle run in parallel on the same branch, but to avoid merge conflicts and keep the changeset reviewable, run them sequentially in the same Claude Code window OR in separate git worktrees. Session 3 MUST wait for deploy.

---

## Why split into three sessions instead of one

1. **Smaller blast radius.** Each session has a focused goal. If Session 1 fails, Session 2 isn't contaminated.
2. **Different review surfaces.** Code changes (Session 1) need `npx tsc --noEmit` and possibly Deno import checks. Prompt changes (Session 2) need prose review, not type checking.
3. **Test-driven iteration.** Session 3 measures the combined effect of 1 + 2. If results are disappointing, we know to iterate on the prompt (cheap) before iterating on the tools (expensive).
4. **Matches the paper's feedback loop.** Meta-Harness proposes discrete candidate harnesses and evaluates each. Splitting sessions mimics that discrete structure.

---

## Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-04-10 | Option B (manual iterative loop) over Option A (full Meta-Harness outer loop) | Lower cost, faster feedback, sufficient signal to start |
| 2026-04-10 | Pivot queries to match Riverside post-Phase-0 reality, skip supplemental SQL enrichment | Touching shared reference tables is cross-namespace risk; real partial data is a realistic test |
| 2026-04-10 | 3-session batching for fix implementation | See "Why split into three sessions" above |
| 2026-04-11 | Batch 1 re-eval complete: 6/10 acceptable (3× improvement from 2/10 baseline) | All 7 Batch 1 gap fixes landed. 8 improvements offset by 2 regressions (Q1 rationalization direction, Q4 temporal refusal). See `10-eval-results-batch-1.md` |
| 2026-04-11 | Recommend Batch 2 before merging to `dev` | Q1 regression is a confident wrong answer on a realistic EA question. Batch 2 is small (~20 lines of prompt additions, no code changes). Projected 9/10 acceptable. |
| 2026-04-11 | Batch 2 re-eval complete: **10/10 acceptable** (perfect score) | Three Batch 2 prompt additions all worked exactly as designed. Both Batch 1 regressions resolved (Q1, Q4), Q9 shape change resolved, Q10 unexpectedly improved from SHALLOW to GOOD. Zero regressions. Beats projected 9/10 by one query. See `20-eval-results-batch-2.md` |
| 2026-04-11 | Approve `feat/ai-chat-harness-eval` for merge to `dev` | All eval criteria met. Five commits ready: `b17075a` (Batch 2 prompt), `2fd5393` + `3df564c` (rate-limit error UX), plus prior Batch 1 commits. No further AI Chat work needed before users can rely on the harness. |

---

## Expected outcome from Batch 1

Per the gap list in `00-eval-results-batch-0.md`, Batch 1 is projected to convert these queries:

- **Q2** (rank crown jewels): hard fail → good
- **Q5** (Police top risk): wrong answer → good
- **Q6** (Police SWOT): shallow → acceptable
- **Q7** (list Finance apps): hard fail → acceptable
- **Q8** (drop Hexagon): wrong answer → acceptable (still capped by data gap on IT-service vendor attribution)

That's 5 of 10 queries moving from fail/wrong to working. Queries 1, 3, 4, 9, 10 are expected to be unchanged (already good or already graceful failures).

If Batch 1 achieves the projected conversion rate, we proceed to Batch 2 targeting Gap 4 (integration list) and Gap 6 (IT service vendor attribution — data gap, not harness gap). If Batch 1 underperforms, we iterate on the system prompt only (Session 2 deliverable) before touching tools again.

---

*Last updated: 2026-04-11 (Batch 2 complete — 10/10 acceptable, ready to merge)*
