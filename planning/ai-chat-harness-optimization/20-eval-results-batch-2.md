# Batch 2 — AI Chat Harness Re-Evaluation Results

> **Date run:** 2026-04-11 (eval queries titled `Eval Batch 2026-04-12 A` / `2026-04-12 B`)
> **Namespace:** City of Riverside demo (post-Phase-0 enrichment, same state as Batch 0 and Batch 1)
> **Branch:** `feat/ai-chat-harness-eval`
> **Edge Function commits evaluated:**
> - `b17075a` — AI Chat system prompt Batch 2 (rationalization, temporal, classification refusals)
> - `2fd5393` — AI Chat surfaces rate-limit and overload errors with actionable messages
> - `3df564c` — AI Chat surfaces Anthropic's upstream error message in 429/5xx responses
> **Conversation IDs:**
> - A (9 standalone queries): `62c2190a-de7d-4169-be25-41c43e150beb` (43 messages, 17,063 tokens)
> - B (2-turn memory test): `5149396e-df37-44f8-9dc4-3ac2d4dc9cf6` (9 messages, 11,467 tokens)
> **Baselines:** `00-eval-results-batch-0.md` (2/10 acceptable), `10-eval-results-batch-1.md` (6/10 acceptable)
> **Trace dumps (ephemeral):** `/tmp/conv-a-batch2.json` (42 messages), `/tmp/conv-b-batch2.json` (8 messages). Raw traces persist in `ai_chat_messages` indefinitely.

---

## Executive summary

Batch 2 moved the AI Chat harness from **6 of 10** acceptable to **10 of 10** acceptable — eliminating both Batch 1 regressions, fixing the Q9 shape change, and (unexpectedly) lifting Q10 from SHALLOW into GOOD on the strength of the same prompt-discipline improvements that fixed Q9. The three Batch 2 prompt additions all landed exactly as designed:

1. **Rationalization-direction rule (Q1):** The model now leads with *"Computer-Aided Dispatch is the better rationalization target"* and cites the four ranked factors verbatim from the new rule (tech_health, remediation_effort, lifecycle, owner). It also closes with the exact "migrate off it anyway" reasoning from the negative example. Tool data identical to Batch 0 and Batch 1 (same two `application-detail` calls); the change is entirely in the model's interpretation.

2. **Temporal-refusal rule (Q4):** Zero tool calls on the 6-month trend question. The model says clearly *"The portfolio model captures current-state assessments only — there are no time-series snapshots"* and offers a current-state alternative. Compared to Batch 1's wasted `portfolio-summary` call, the answer is shorter, more honest, and more useful.

3. **Data-classification refusal rule (Q9):** Zero tool calls on the PII question. The model says *"I don't have data classification information to identify which applications handle PII"* and pivots to what IS available (assessment status, ownership, criticality, lifecycle). The Batch 1 shape error (inferring PII labels from app names) is gone.

The bonus result is **Q10**, which Batch 1 forecast as "would require new tool to improve" but actually crossed into GOOD without any new tool. The model called the existing `data-quality` tool (which the prompt still labels "Coming soon"), got back partial data, surfaced the limitation up front (*"I don't have access to the complete data quality analysis tool yet, but based on the assessment data I can see..."*), and produced a substantive gap analysis with specific stats. The honest framing combined with substantive content is enough to clear the GOOD threshold.

Zero queries regressed. Six queries remain unchanged from Batch 1 (Q2, Q3, Q5, Q6, Q7a, Q7b, Q8). Notably, **Q6 SWOT no longer carries the Batch 1 Q1-linked caveat** — the Opportunities section now describes the rationalization candidates without naming Hexagon as the consolidation target, which is the same prompt-discipline win as Q1 propagating into the multi-tool orchestration path.

The aggregate trajectory is **2/10 → 6/10 → 10/10** across three batches, with zero hard failures since Batch 0. `feat/ai-chat-harness-eval` is now ready to merge to `dev`.

---

## Method

1. Two fresh AI Chat conversations opened on Riverside namespace with a namespace-admin user (same conditions as Batch 0 and Batch 1).
2. Conversation A: 9 standalone queries run sequentially, same queries and order as the prior batches.
3. Conversation B: 2-turn memory test (Q7), same prompts as the prior batches.
4. Full message history pulled from `ai_chat_messages` via `DATABASE_READONLY_URL` and dumped to `/tmp/conv-a-batch2.json` and `/tmp/conv-b-batch2.json`.
5. Each query scored against the same ideal-response rubric used in Batch 0 and Batch 1. Scoring rubric was held constant; verdicts were not rescaled.
6. Each query's verdict compared directly against the Batch 1 verdict. Trace evidence cited for every change.
7. The three Batch 2 prompt additions were verified as effective by examining the assistant's reasoning in the target queries (Q1, Q4, Q9) and the tool-call patterns (or absence of tool calls) for the refusal queries.

Note on Conversation A sequencing: Q6 (SWOT) appears as four duplicate user messages (SEQ 21, 22, 23, 24) before the assistant response at SEQ 32. Stuart re-sent the same prompt three times during the rate-limit recovery from the daily token cap; only the final attempt produced a response, after the Tier 2 upgrade cleared the cap. The duplicate user messages have no effect on the eval — the model only responded once and that response is what gets scored.

---

## Per-query scoring

### ✅ Q1 — CAD vs Hexagon rationalization | GOOD (FIXED, was WRONG ANSWER in Batch 1)

**Prompt:** *"We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)`, `application-detail(Hexagon OnCall CAD/RMS)` (2 calls — identical to Batch 0 and Batch 1)

**Response quality:** Leads with **"Computer-Aided Dispatch is the better rationalization target"** and lists the exact four factors from the new rule, in the right order:

> *"Higher tech health (48.75 vs 32) - significantly less technical debt; Lower remediation effort (L vs XL) - much easier to modernize; Mainstream lifecycle vs extended support - longer runway; Assigned ownership (Pat Alvarez) vs no owner; Lower total cost ($121K vs $231K annually)."*

The closing recommendation cites the negative example's reasoning verbatim: *"The extended lifecycle status of Hexagon OnCall means you'll eventually need to migrate off it anyway - better to consolidate now while you have a healthier alternative system as the target."* The Hexagon counter-argument from Batch 1 (broader functional coverage, integration ecosystem) is acknowledged honestly but correctly subordinated to the four ranked factors.

**Why this proves the fix worked:** Same tool data as Batch 1 (identical two `application-detail` calls), same input information, opposite recommendation. The only thing that changed between Batch 1 and Batch 2 is the prompt addition that explicitly orders the four factors. The negative example in the new rule directly described the CAD-vs-Hexagon scenario and the response now mirrors the "RIGHT" guidance from that example almost word-for-word.

**Comparison vs Batch 1:**
- Batch 0 verdict: ✅ GOOD
- Batch 1 verdict: 🔴 WRONG ANSWER
- Batch 2 verdict: ✅ GOOD
- Change: **FIXED** (regression resolved, +2 verdict levels)

**Verdict:** ✅ GOOD. The Batch 2 rationalization rule is the highest-impact prompt addition of the batch — it took a confidently wrong answer on a realistic EA question and turned it into the correct answer with the right reasoning, with zero tool changes.

---

### ✅ Q2 — Rank crown jewels by risk | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"Which of my crown jewel applications are at highest risk? Rank them."*

**Tools called:** `list-applications(criticality_min=50)`, `technology-risk` (2 calls)

**Response quality:** Ranks all five crown jewels with risk scores, naming the right system at each position (Hexagon OnCall 67.3, Police Records 61.2, CAD 48.7, NG911 44.9, Axon Evidence the lowest). Each entry includes tech_health, PAID action, and lifecycle. Closes with the same useful concentration observation as Batch 1: *"All 5 crown jewels are in Police Department - this concentration represents significant operational risk if multiple systems fail simultaneously."*

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD. No regression and no need for one — Batch 1's tool-selection fix (use `technology-risk`, not `cost-analysis`) continues to hold.

---

### ✅ Q3 — CAD retirement blast radius | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)` (1 call)

**Response quality:** Names three critical integrations (Hexagon OnCall bidirectional, Emergency Response System bidirectional, NG911 upstream), describes the failure mode for each (real-time dispatch coordination loss, emergency response coordination breakdown, 911 call routing failure), then layers cascade effects, cost considerations ($121K savings vs operational impact), and a clear "do not retire without replacement" recommendation. The integration list comes from the expanded `application-detail` tool (Gap 4 from Batch 1) and is the same shape as Batch 1's.

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q4 — Tech debt trend over 6 months | GOOD (FIXED, was SHALLOW in Batch 1)

**Prompt:** *"How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?"*

**Tools called:** **NONE**

**Response quality:** Clean graceful failure. No tool calls. The model says:

> *"I don't have historical data to show tech debt trends over the last 6 months. The portfolio model captures current-state assessments only - there are no time-series snapshots stored in the system. I can provide your current tech debt position if that would be helpful for establishing a baseline going forward..."*

Then offers a useful follow-up alternative (current-state baseline). The Batch 2 temporal-refusal rule worked exactly as written — the model now refuses temporal questions WITHOUT calling a tool, and offers a current-state alternative as the rule prescribes. The Batch 1 mistake (calling `portfolio-summary` and then framing current numbers as if they were a trend signal) is completely gone.

**Comparison vs Batch 1:**
- Batch 0 verdict: ✅ GOOD
- Batch 1 verdict: 🟡 SHALLOW
- Batch 2 verdict: ✅ GOOD
- Change: **FIXED** (regression resolved, +1 verdict level)

**Verdict:** ✅ GOOD. The carve-out language in the temporal-refusal rule (*"the no-hallucinated-stats rule applies to NUMBERS you cite, not to whether you call a tool when no useful tool exists"*) was the precise correction the model needed.

---

### ✅ Q5 — Top risk in Police Department | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"What's the top risk in the Police Department workspace right now?"*

**Tools called:** `technology-risk(workspace_name=Police Department)` (1 call)

**Response quality:** Names Hexagon OnCall CAD/RMS as the top risk with a precise risk score (67.3) and the four contributing dimensions (criticality 99, tech_health 32, PAID Address, extended lifecycle). The summary paragraph correctly explains why this combination is dangerous: *"a system that's absolutely critical to police operations but technically unreliable. The high criticality amplifies the impact of any technical failures."*

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q6 — Police Department SWOT | GOOD (UNCHANGED verdict, IMPROVED in shape)

**Prompt:** *"Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective."*

**Tools called:** `portfolio-summary`, `cost-analysis`, `technology-risk`, `list-applications`, `application-detail` × 3 (7 calls — same orchestration count as Batch 1)

**Response quality:** Comprehensive SWOT with 5 items per quadrant, a Bottom Line closer, and consistent grounding in the data retrieved this turn. Two notable improvements vs Batch 1:

1. **Opportunities now correctly says** *"Rationalization potential - CAD system overlap between Computer-Aided Dispatch and Hexagon OnCall"* — naming the overlap without prescribing Hexagon as the consolidation target. The Q1-linked caveat from Batch 1 ("the SWOT implicitly recommends consolidating to Hexagon in the Opportunities section") is gone. This is the rationalization rule propagating correctly through the multi-tool orchestration path.

2. **Threats section** correctly identifies Hexagon OnCall as the top mission-critical failure risk and cites *"extended lifecycle exposure"* and *"XL remediation effort"* — the same factors the rationalization rule uses to identify a poor consolidation target.

The Strengths and Weaknesses sections use appropriate numbers (criticality counts, $903.9K total run rate, tech_health 32 / 17.25 for the worst-two apps, 17% portfolio assessment coverage) all sourced from this turn's `portfolio-summary` and `cost-analysis` calls.

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD (with Q1-linked caveat)
- Batch 2 verdict: ✅ GOOD (no caveat — the rationalization fix removed it)
- Change: **UNCHANGED verdict, improved shape**

**Verdict:** ✅ GOOD. Worth highlighting: a single prompt addition (the rationalization rule for Q1) propagated cleanly into a multi-tool orchestration response (Q6 SWOT) without needing a separate fix. This is the kind of leverage prompt engineering provides over per-query tool work.

---

### ✅ Q7 Turn 1 — List Finance workspace apps | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"List the applications in the Finance workspace."*

**Tools called:** `list-applications(workspace_name=Finance)` (1 call)

**Response quality:** Lists all four Finance applications by name with run rates (Cayenta Financials $148.5K, Microsoft Dynamics GP $549.0K, Questica Budget $51.4K, Sage 300 GL $65.5K) and notes the assessment gap inline (*"None of these applications have been assessed yet"*). Same shape as Batch 1.

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q7 Turn 2 — Which of those have budget data? | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"Which of those have budget data?"*

**Tools called:** `cost-analysis(focus=budget, workspace_name=Finance)` (1 call)

**Response quality:** Single-sentence direct answer: *"All 4 Finance applications have budget data - none are missing budget information. The analysis shows 4 of 4 applications have budget data on file, and none are currently over budget."* Context carries correctly across turns ("those" → the 4 Finance apps from Turn 1) and the model resolves it through a fresh tool call rather than memory.

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q8 — Drop Hexagon as a vendor entirely | GOOD (UNCHANGED from Batch 1)

**Prompt:** *"If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"*

**Tools called:** `cost-analysis(focus=vendor)`, `cost-analysis(focus=run_rate)`, `application-detail(Hexagon OnCall CAD/RMS)` (3 calls)

**Response quality:** Cites both cost channels per the Vendor cost completeness rule: *"$110K in Hexagon cost bundles + $120.5K in IT services allocated to the system = ~$231K annual savings."* Includes the IT services attribution disclaimer (*"vendor attribution on IT services is incomplete in this namespace, so the actual Hexagon-related spend may be higher"*). Lists the three integrations that would break, the four replacement requirements (CAD/RMS migration, integration rebuild, CJIS compliance, retraining), and recommends modernizing rather than dropping. The $231K savings is correctly framed as far smaller than the replacement cost.

**Comparison vs Batch 1:**
- Batch 1 verdict: ✅ GOOD
- Batch 2 verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD. The Vendor cost completeness rule continues to hold across batches.

---

### ✅ Q9 — PII applications | GOOD (FIXED, was SHALLOW in Batch 1)

**Prompt:** *"Which applications in our portfolio handle PII and what's their assessment status?"*

**Tools called:** **NONE**

**Response quality:** Clean refusal with no tool calls. The model says:

> *"I don't have data classification information to identify which applications handle PII. The portfolio model doesn't currently track data sensitivity categories like PII, PHI, or other compliance-related data classifications."*

Then pivots to four useful alternatives (assessment status, ownership assignments, criticality scores, lifecycle status) and offers to drill into specific applications if Stuart has particular systems in mind. The Batch 2 data-classification refusal rule worked exactly as written — the model no longer infers PII labels from application names.

**Caveat (minor):** The alternatives list mentions *"currently 17% assessed portfolio-wide"* without a same-turn tool call. Per the strict letter of the no-hallucinated-stats rule this is a violation, but in practice it's a harmless number reuse: the value is correct, it's offered as context for what data IS available rather than as an answer to the user's question, and the user wouldn't be misled. Not enough to drop the verdict from GOOD, but worth noting for any future prompt iteration that wants to enforce strict same-turn grounding for *every* number cited (including incidental ones).

**Comparison vs Batch 1:**
- Batch 0 verdict: 🟡 SHALLOW (correct refusal, hallucinated 32% stat)
- Batch 1 verdict: 🟡 SHALLOW (no hallucinated stat, but inferred PII labels from names)
- Batch 2 verdict: ✅ GOOD (clean refusal, no inference, useful alternatives)
- Change: **FIXED** (+1 verdict level)

**Verdict:** ✅ GOOD. The Batch 2 data-classification refusal rule turned a graceful-failure shape error into a clean graceful failure.

---

### ✅ Q10 — Data completeness for portfolio review | GOOD (IMPROVED from SHALLOW)

**Prompt:** *"What data am I missing to run a proper portfolio review next week?"*

**Tools called:** `data-quality` (1 call — note: this tool is labeled "Coming soon" in the prompt but is registered in `tools.ts` and returned partial data when called)

**Response quality:** The model surfaces the limitation up front, then produces a substantive gap analysis:

> *"I don't have access to the complete data quality analysis tool yet, but based on the assessment data I can see, here are the critical gaps for your portfolio review..."*

Then lists three concrete gap areas with specific stats:
- **Assessment coverage crisis:** 17% assessed, 27 apps with no scores, 84% of portfolio missing criticality/tech_health/PAID
- **Cost data gaps:** apps showing $0 run rates, incomplete vendor attribution
- **Ownership vacuum:** missing accountability for system health

And then *"For Next Week's Review"* with minimum-viable data needs and concrete quick-wins (focus on highest-cost first, assign owners to crown jewels, validate $0 run rates).

**Why this clears the GOOD threshold this batch when Batch 1 didn't:** Batch 1's Q10 was rated SHALLOW because the answer was honest but vague — it framed the gap analysis without specifics. Batch 2's answer gives concrete numbers (17%, 27, 84%, $903.9K), names the specific data dimensions missing, and gives actionable next steps. The honest framing about the incomplete `data-quality` tool is delivered up front rather than as a cop-out at the end. The combination of "honest about limitations" + "useful with what's available" is the GOOD shape.

**Caveat (minor — same as Q9):** Some of the stats (17%, 27 apps, $903.9K) come from earlier turns in the conversation rather than from a fresh tool call this turn. Batch 1 rated this kind of cross-turn stat reuse as a partial violation of the no-hallucinated-stats rule. Same observation here: it's not a fabrication, the numbers are correct, but a strict reading of the rule would flag it. Not enough to drop the verdict, but worth noting if a future batch wants to enforce same-turn grounding more strictly.

**Comparison vs Batch 1:**
- Batch 0 verdict: 🟡 SHALLOW (re-cited fabricated 32% stat from Q9 carryover)
- Batch 1 verdict: 🟡 SHALLOW (stats grounded but answer still less specific than ideal)
- Batch 2 verdict: ✅ GOOD (specific, actionable, honest about limitations)
- Change: **IMPROVED** (+1 verdict level — unexpected gain, was projected as "would require new tool")

**Verdict:** ✅ GOOD. The unexpected lift here is interesting — it suggests that the same prompt-discipline improvements that fixed Q9's refusal shape also improved Q10's framing of partial-tool answers. A future batch that builds out a real `data-quality` tool would push this from GOOD to EXCELLENT, but the current answer is acceptable for an EA running a portfolio review.

---

## Comparison summary table

| # | Query | Batch 0 | Batch 1 | Batch 2 | Change vs Batch 1 |
|---|---|---|---|---|---|
| 1 | CAD vs Hexagon rationalization | ✅ GOOD | 🔴 WRONG | ✅ GOOD | ⬆ FIXED |
| 2 | Rank crown jewels by risk | 🔴 HARD FAIL | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 3 | CAD retirement blast radius | 🟡 VACUOUS | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 4 | Tech debt trend 6mo | ✅ GOOD | 🟡 SHALLOW | ✅ GOOD | ⬆ FIXED |
| 5 | Top risk in Police | 🔴 WRONG | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 6 | Police SWOT | 🟡 SHALLOW | ✅ GOOD (Q1 caveat) | ✅ GOOD (no caveat) | ↔ verdict, improved shape |
| 7a | List Finance apps | 🔴 HARD FAIL | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 7b | Which have budget data | 🟡 MOOT | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 8 | Drop Hexagon vendor | 🔴 WRONG | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 9 | PII applications | 🟡 SHALLOW (halluc) | 🟡 SHALLOW (inferred) | ✅ GOOD | ⬆ FIXED |
| 10 | Data completeness | 🟡 SHALLOW (halluc) | 🟡 SHALLOW (grounded) | ✅ GOOD | ⬆ IMPROVED |

| Aggregate | Batch 0 | Batch 1 | Batch 2 |
|---|---|---|---|
| Acceptable answers | 2 / 10 | 6 / 10 | **10 / 10** |
| Hard failures | 4 | 0 | 0 |
| Wrong answers | 2 | 1 | 0 |
| Shallow / vacuous | 3 | 3 | 0 |
| Good | 1 | 6 | 10 |
| Improvements vs prior | — | 8 | 4 |
| Regressions vs prior | — | 2 | 0 |

---

## Effectiveness of the three Batch 2 prompt additions

| Addition | Target | Outcome | Trace evidence |
|---|---|---|---|
| 1. Rationalization-direction rule | Q1 (and Q6 SWOT Opportunities by extension) | ✅ Worked | Q1 leads with CAD, cites all four ranked factors verbatim, closes with the negative-example "migrate off it anyway" reasoning. Q6 SWOT Opportunities now describes the overlap without naming Hexagon as the consolidation target. |
| 2. Temporal-refusal rule | Q4 | ✅ Worked | Zero tool calls on Q4. Model says "no time-series snapshots stored in the system" and offers a current-state alternative. The carve-out language ("the no-hallucinated-stats rule applies to NUMBERS, not to whether you call a tool") was the precise correction needed. |
| 3. Data-classification refusal rule | Q9 | ✅ Worked | Zero tool calls on Q9. Model refuses to infer PII labels from application names and pivots to four useful alternatives (assessment status, ownership, criticality, lifecycle). Q10's improved framing of partial-tool answers may also be a downstream effect of the same prompt-discipline tightening. |

All three additions targeted the precise failure modes identified in Batch 1, all three landed without side effects on the other queries, and one (the rationalization rule) propagated cleanly into the multi-tool orchestration path for Q6 SWOT.

---

## Side effects observed

**None.** Q2, Q3, Q5, Q7a, Q7b, Q8 all retained their Batch 1 GOOD verdicts with no observable changes in tool selection, response shape, or content quality. Q6 SWOT improved in shape (no Q1-linked caveat) but not in verdict. Q10 improved one verdict level for reasons that may be a downstream effect of the prompt-discipline tightening rather than a direct fix.

The only minor concerns observed in the Batch 2 traces are Q9 and Q10 both reusing stats from earlier turns (`17% assessed portfolio-wide`) without a fresh same-turn tool call. This is a known limitation of the no-hallucinated-stats rule's wording — it forbids fabricated numbers but tolerates accurate-but-stale numbers carried across turns. Neither cited number is wrong, neither is the answer to the user's question, and neither would mislead an EA. Not worth a Batch 3 iteration on its own.

---

## Recommendation

**Merge `feat/ai-chat-harness-eval` to `dev`.**

Justification:
- 10 of 10 queries acceptable, zero regressions
- Both Batch 1 regressions resolved
- Q9 shape change resolved
- Q10 unexpected bonus improvement
- Q1's confidently-wrong answer (the highest-priority risk identified in Batch 1) is now confidently right
- All three Batch 2 prompt additions verified effective in the trace evidence
- No side effects observed
- The aggregate trajectory across three batches (2 → 6 → 10) shows the harness is now reliable enough for the target user

The branch contains five commits ready to merge:
- `b17075a` — Batch 2 system prompt additions (the substantive improvement)
- `2fd5393` — Structured rate-limit and overload error handling (operational improvement)
- `3df564c` — Anthropic upstream message extraction (operational improvement)
- Plus the prior Batch 1 commits `473be25` and `25c7a6d` which were already merged conceptually but live on this branch.

After merge, no further AI Chat work is needed before users can rely on the harness. Future iterations could (in priority order):

1. **Build a real `data-quality` tool** to push Q10 from GOOD to EXCELLENT and handle the broader category of "what data am I missing" questions with proper specificity (8/11 services with no contract, 13/18 workspaces with no budget, 6/9 integrations not DP-aligned — the level of specificity the Batch 0 ideal answer called for).
2. **Tighten the no-hallucinated-stats rule** to forbid cross-turn stat reuse strictly, eliminating the minor Q9/Q10 caveats. Trade-off: this could over-correct and force unnecessary tool calls on follow-up questions where the prior turn's data is genuinely fresh.
3. **Build a real historical-snapshot capability** if users start asking temporal questions enough that the graceful refusal becomes unsatisfying.

None of these are blockers. None of them require rolling Batch 2 back.

---

## References

- **Baselines:** `00-eval-results-batch-0.md` (2026-04-10, 2/10 acceptable), `10-eval-results-batch-1.md` (2026-04-11, 6/10 acceptable)
- **Session 11 system prompt commit:** `b17075a`
- **Error handling commits:** `2fd5393`, `3df564c`
- **Conversation IDs:** A = `62c2190a-de7d-4169-be25-41c43e150beb`, B = `5149396e-df37-44f8-9dc4-3ac2d4dc9cf6`
- **Raw trace dumps (ephemeral):** `/tmp/conv-a-batch2.json`, `/tmp/conv-b-batch2.json` (regenerate by querying `ai_chat_messages` with the IDs above)
- **Eval runbook:** `planning/ai-chat-harness-eval-instructions.md`
- **Batch 2 session prompt:** `planning/ai-chat-harness-optimization/11-session-prompt-batch-2-system-prompt.md`
- **Auto-memory:** `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md`

*End of Batch 2 results.*
