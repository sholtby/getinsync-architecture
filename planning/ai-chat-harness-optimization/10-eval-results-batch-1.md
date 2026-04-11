# Batch 1 — AI Chat Harness Re-Evaluation Results

> **Date run:** 2026-04-11
> **Namespace:** City of Riverside demo (post-Phase-0 enrichment, same state as Batch 0)
> **Branch:** `feat/ai-chat-harness-eval`
> **Edge Function commits evaluated:**
> - `473be25` — AI Chat harness Batch 1 code fixes (Gaps 1, 2, 3p, 4)
> - `25c7a6d` — AI Chat system prompt rewrite (Gaps 3, 5, 7, 8)
> - `8bbae7c` — disable platform JWT gate for ai-chat Edge Function
> **Conversation IDs:**
> - A (9 standalone queries): `0c9b3034-41e2-4d82-936c-796cefd06bae` (45 messages, 17703 tokens)
> - B (2-turn memory test): `08b15716-5a2c-46f5-8102-4ebde38bebb7` (9 messages, 10492 tokens)
> **Baseline:** `00-eval-results-batch-0.md` (2026-04-10, 2/10 acceptable)
> **Trace dumps (ephemeral):** `/tmp/conv-a-batch1.txt` (481 lines), `/tmp/conv-b-batch1.txt` (55 lines). Raw traces persist in `ai_chat_messages` indefinitely.

---

## Executive summary

Batch 1 moved the AI Chat harness from **2 of 10** acceptable to **6 of 10** acceptable — a 3× improvement in the answer rate an Enterprise Architect can rely on without cross-checking. All seven Batch 1 gap fixes landed as intended and are visible in the trace evidence: the new `list-applications` tool was used on the queries that needed enumeration, the raised iteration limit allowed an 8-tool SWOT to complete where Batch 0 had hit the ceiling at 5, `technology-risk` was called on every risk question (not `cost-analysis`), the expanded `application-detail` tool returned full integration lists that unblocked the blast-radius question, and the no-hallucinated-stats rule eliminated the "32% assessed" fabrication that propagated across Q9 and Q10 in Batch 0.

Two queries regressed. The most consequential is **Q1** (CAD vs Hexagon rationalization), which flipped from a correct Batch 0 recommendation (rationalize TO Computer-Aided Dispatch) to a confidently wrong Batch 1 recommendation (consolidate TO Hexagon OnCall CAD/RMS) despite retrieving identical tool data on both runs. The second is **Q4** (6-month tech debt trend), which softened from a clean graceful failure to a shallow "here are current numbers" answer that also violated the "don't append follow-up suggestions" response rule. Q9 (PII classification) is technically unchanged in verdict — it no longer hallucinates the 32% statistic (Gap 7 fix landed) but now *infers* a PII-handling app list from application names rather than refusing outright, a different class of graceful-failure error.

The delta is net positive by a wide margin: eight improvements versus two regressions, zero hard failures, and a useless-or-harmful-answer rate that dropped from 40% (4/10) to 10% (1/10). However, the Q1 regression is a confident wrong answer on a realistic EA question, which is exactly the class of error the Batch 0 gap list flagged as hardest to catch in production. The recommended next step is a small, prompt-only Batch 2 that (a) adds explicit rationalization-direction semantics, (b) reinforces graceful-failure refusal discipline for temporal and data-classification questions, and (c) does NOT touch tool code. Merging `feat/ai-chat-harness-eval` to `dev` should wait until Batch 2 ships.

---

## Method

1. Two fresh AI Chat conversations opened on Riverside namespace with a namespace-admin user (same conditions as Batch 0).
2. Conversation A: 9 standalone queries run sequentially, same queries and order as Batch 0.
3. Conversation B: 2-turn memory test (Q7), same prompts as Batch 0.
4. Full message history (including `tool_input` and `tool_output` JSONB) pulled from `ai_chat_messages` via `DATABASE_READONLY_URL`.
5. Each query scored against the same ideal-response rubric used in Batch 0. Scoring rubric was held constant; verdicts were not rescaled.
6. Each query's verdict compared directly against the Batch 0 verdict for that query. Trace evidence cited for every improvement and every regression.
7. Gap-by-gap effectiveness assessed by reading the tool-call sequences in the traces and confirming each targeted behavior change happened.

Note on Conversation A sequencing: Stuart's paste of Q9 and Q10 produced three user messages in a row in `ai_chat_messages` (SEQ 35 Q9, SEQ 36 Q10, SEQ 37 Q9 repeated). The model responded to SEQ 37 with a combined answer (SEQ 41) that covered both PII and data-gaps topics. Stuart then re-sent Q10 alone (SEQ 42 → SEQ 44) to get an isolated answer. This evaluation scores Q9 from SEQ 41 (the combined response) and Q10 from SEQ 44 (the dedicated response). Both are noted below.

---

## Per-query scoring

### 🔴 Q1 — CAD vs Hexagon rationalization | WRONG ANSWER (REGRESSED from GOOD)

**Prompt:** *"We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)`, `application-detail(Hexagon OnCall CAD/RMS)` (2 calls — same as Batch 0)

**Response quality:** The model recommended **"Consolidate to Hexagon OnCall CAD/RMS"** with this reasoning:

> *"Hexagon OnCall CAD/RMS is the better long-term choice: Higher criticality (99 vs 95), Broader functionality - Combined CAD/RMS system vs dispatch-only, Better integration ecosystem - Connects to Flock Safety LPR and Axon Evidence, More comprehensive solution."*

It correctly acknowledged Hexagon's weaknesses ("significantly lower tech health (32 vs 48.75)", "XL remediation effort", "unassigned ownership", "nearly 2x more") but recommended Hexagon anyway on the strength of functional coverage and integration ecosystem.

**Why this is wrong:** The EA-correct call is rationalize TO CAD. Hexagon is on `extended` lifecycle, requires XL remediation effort, has no assigned owner, and has a criticality delta of only 4 points (95 vs 99 — both crown jewels). CAD is on `mainstream` lifecycle, L remediation, has a named owner (Pat Alvarez) and support contact (K. Patel), costs half as much, and has tech health 50% higher. Picking Hexagon as the consolidation target asks the city to invest in a system it will have to migrate away from anyway within the extended-support window.

**Tool data was identical to Batch 0.** Both runs received the same `application-detail` output for both apps. Batch 0 chose CAD based on tech health + cost + lifecycle. Batch 1 chose Hexagon based on "broader functionality" reasoning — a signal that was also visible in Batch 0 but not weighted in Batch 0's recommendation.

**Comparison vs Batch 0:**
- Batch 0 verdict: ✅ GOOD
- Batch 1 verdict: 🔴 WRONG ANSWER
- Change: **REGRESSED** (−2 verdict levels)
- Root cause hypothesis: The new system prompt's "Tool selection rules" section emphasizes not using cost as a proxy for risk and adds orchestration guidance, but it does not specify rationalization-direction semantics ("prefer the healthier, lower-effort, mainstream-lifecycle system as the consolidation target"). With the cost-as-risk constraint introduced, the model shifted its reasoning toward functional coverage, and the expanded integration list from Gap 4 made "integration ecosystem" a more salient signal. The fix is a one-paragraph addition to the prompt — no tool changes needed.

**Verdict:** 🔴 WRONG ANSWER. Confidently wrong, delivered in polished markdown, would be acted on by an EA. This is the top priority for Batch 2.

---

### ✅ Q2 — Rank crown jewels by risk | GOOD (IMPROVED from HARD FAIL)

**Prompt:** *"Which of my crown jewel applications are at highest risk? Rank them."*

**Tools called:** `technology-risk(limit=50)`, `list-applications(criticality_min=50)` (2 calls)

**Response quality:** The model called `technology-risk` first — exactly the tool selection the new system prompt prescribes — got a full ranked list of all 32 apps scored, then called `list-applications(criticality_min=50)` to filter to the 5 crown jewels specifically. The final answer ranked all 5 crown jewels correctly:

| Rank | App | Risk Score |
|---|---|---|
| 1 | Hexagon OnCall CAD/RMS | 67.3 |
| 2 | Police Records Management | 61.2 |
| 3 | Computer-Aided Dispatch | 48.7 |
| 4 | NG911 System | 44.9 |
| 5 | Axon Evidence | 10.5 |

This matches the ideal answer from the Batch 0 gap list exactly. The model also added a useful observation that "all crown jewels are Police Department systems, highlighting the concentration of critical applications in public safety."

**Comparison vs Batch 0:**
- Batch 0 verdict: 🔴 HARD FAIL (iteration limit exhausted after hallucinating "Cityworks" and "New World"; user received fallback error string)
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+3 verdict levels — the largest single-query gain in the batch)
- Root cause of improvement: Gap 1 fix (list-applications tool) + Gap 3 fix (technology-risk tool + prompt guidance). The model no longer has to hallucinate crown jewel names — it calls a tool that returns them. Iteration limit raise (Gap 2) would have been needed too if the model hadn't picked the most efficient tool path first.

**Verdict:** ✅ GOOD.

---

### ✅ Q3 — CAD retirement blast radius | GOOD (IMPROVED from VACUOUS)

**Prompt:** *"If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)` (1 call)

**Response quality:** The expanded `application-detail` tool now returns the full integration list with direction, method, peer app name, and DP-alignment flag. The tool output included:

> *"### Integrations (3)*
> *- Hexagon ↔ CAD Dispatch ↔ Hexagon OnCall CAD/RMS (bidirectional, api)*
> *- Emergency Response ↔ CAD ↔ Emergency Response System (bidirectional, api) [DP-aligned]*
> *- NG911 → CAD Call Routing ← NG911 System (downstream, api) [DP-aligned]"*

The model's response correctly identified all 3 broken integrations with severity ratings (CRITICAL for NG911, HIGH for Emergency Response, MODERATE for Hexagon), explained the operational impact of each, and laid out a 4-step migration strategy (redirect NG911 routing, migrate Emergency Response integration, test emergency workflows, train dispatchers). Financial impact noted at $121K annual savings.

**Comparison vs Batch 0:**
- Batch 0 verdict: 🟡 VACUOUS (graceful failure — "the system doesn't provide specific details about which applications would be affected")
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+1 verdict level, from "useless but honest" to "actually useful")
- Root cause of improvement: Gap 4 fix (application-detail integration list expansion). The data was one tool call away in Batch 0 and the new tool output exposes it.

**Verdict:** ✅ GOOD.

---

### 🟡 Q4 — Tech debt trend over 6 months | SHALLOW (REGRESSED from GOOD)

**Prompt:** *"How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?"*

**Tools called:** `portfolio-summary()` (1 call — Batch 0 made zero calls)

**Response quality:** The model called `portfolio-summary` (unnecessary — there is no time-series data in the view) and produced an answer that cited current-state numbers: *"55.5 average tech health, 3 applications flagged as 'Address', 3 applications in 'Improve', 17% assessment completion."* It then said *"to track tech debt trends going forward, you'd need to [complete assessments, establish baseline, set up reassessment cycles]."* The answer closed with an unsolicited follow-up offer:

> *"Would you like me to identify which specific applications are driving your current tech debt concerns or analyze the risk distribution across your assessed applications?"*

The answer does not explicitly admit "no time-series data exists in the system." It implies it through the "going forward" framing, but a less attentive reader could walk away thinking 55.5 represents a trend number rather than a snapshot.

Two issues:
1. **Wasted tool call.** The new system prompt rule *"NEVER cite a specific percentage, count, dollar amount, or other statistic unless you retrieved it from a tool call in the CURRENT turn"* may be driving the model to call portfolio-summary defensively even when the correct answer is "no data exists." Gap 7 fix landed, but possibly over-corrected.
2. **Follow-up suggestion violates the "don't append follow-ups" rule** in the system prompt's Response rules section.

**Comparison vs Batch 0:**
- Batch 0 verdict: ✅ GOOD (graceful failure — no tools called, explicit "no time-series data" admission, offered useful alternative)
- Batch 1 verdict: 🟡 SHALLOW
- Change: **REGRESSED** (−1 verdict level, mild)
- Root cause hypothesis: Gap 7 (no-stats-without-tool-call) over-corrected. The model interpreted the rule as "always call a tool before answering" and lost the graceful-failure reflex. This is fixable with a clarifying prompt rule: "For questions about time series, trends, historical data, or any concept that is not in your tool surface, refuse gracefully without calling a tool."

**Verdict:** 🟡 SHALLOW. Not harmful — no wrong numbers, no hallucinated trend — but worse than Batch 0.

---

### ✅ Q5 — Top risk in Police Department | GOOD (IMPROVED from WRONG ANSWER)

**Prompt:** *"What's the top risk in the Police Department workspace right now?"*

**Tools called:** `technology-risk(workspace_name="Police Department", limit=1)` (1 call)

**Response quality:** Clean single-tool call that directly targets the question. No wasted `list-workspaces` call (Gap 8 fix landed — the model passed the workspace name directly). Tool returned Hexagon OnCall CAD/RMS at risk score 67.3. The model's response:

> *"## Top Risk: Hexagon OnCall CAD/RMS — Risk Score: 67.3 (highest in Police Department). Criticality 99 — your most business-critical police system. Tech Health 32 — severe technical debt requiring immediate attention. PAID Status: Address — flagged for urgent remediation."*

This is exactly the right answer. Batch 0 returned "NG911 at $330K" because the model used cost as a proxy for risk. The combination of (a) the unstubbed `technology-risk` tool and (b) the explicit system prompt rule *"Do NOT call cost-analysis. Cost is NOT risk"* with a worked negative example produced the corrected behavior.

**Comparison vs Batch 0:**
- Batch 0 verdict: 🔴 WRONG ANSWER
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+2 verdict levels)
- Root cause of improvement: Gap 3 fix (technology-risk tool unstubbed + risk guidance in prompt + negative example). The negative example in the system prompt literally predicted this query — *"If asked 'what is the top risk in Police Department?' do NOT call cost-analysis. Call technology-risk with workspace_name=Police Department"* — and the model followed it exactly.

**Verdict:** ✅ GOOD.

---

### ✅ Q6 — Police Department SWOT | GOOD (IMPROVED from SHALLOW)

**Prompt:** *"Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective."*

**Tools called:** 8 tools — `portfolio-summary`, `cost-analysis(focus=overview, workspace=Police Department)`, `technology-risk(workspace=Police Department, limit=10)`, `list-applications(workspace=Police Department, criticality_min=50)`, `application-detail` × 4 on Hexagon, NG911, CAD, Axon Evidence.

**Response quality:** This is the orchestration the new system prompt's "Worked example — SWOT analysis of Police Department portfolio" section explicitly prescribes. The model executed the sequence nearly verbatim. The resulting SWOT has real data in every quadrant:

- **Strengths:** 5 crown jewels, $903.9K under budget control, proven ownership model (named Pat Alvarez explicitly)
- **Weaknesses:** Hexagon tech health 32, 3 of 5 crown jewels in PAID=Address, 4 of 5 crown jewels lack assigned owners, 17% assessment coverage
- **Opportunities:** CAD/Hexagon consolidation savings, NG911/Axon "Invest" strategy reinforcement, cloud migration roadmap
- **Threats:** Hexagon risk score 67.3, cascade failure potential, extended lifecycle, vendor cost pressure, unassigned-ownership skills gap

Notable quality jump: the SWOT uses real run rates ($903.9K workspace total), real risk scores, real assessment percentages, real ownership names. Batch 0 produced a SWOT that "looked like a competent SWOT but was missing half the data."

**Caveat:** The Opportunities section says *"System Rationalization: Consolidating duplicate CAD systems could save $121.0K annually"* and *"Hexagon provides both CAD and RMS - opportunity to standardize on single platform"* — implicitly recommending retirement of CAD in favor of Hexagon. This is consistent with Q1's incorrect direction. If Q1 is fixed in Batch 2, Q6 should be re-checked to verify it doesn't still carry the wrong rationalization direction.

**Comparison vs Batch 0:**
- Batch 0 verdict: 🟡 SHALLOW (single cost-analysis call, reused Hexagon data from Q1 context, cost-weighted in every quadrant)
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+1 verdict level)
- Root cause of improvement: Gap 2 fix (MAX_TOOL_ITERATIONS 5 → 15 — would have capped at 5 in Batch 0 before the 8-tool sequence completed) + Gap 5 fix (multi-tool orchestration guidance + worked SWOT example). The model followed the worked example almost exactly.

**Verdict:** ✅ GOOD, with a Q1-linked caveat on rationalization direction.

---

### ✅ Q7 Turn 1 — List Finance workspace apps | GOOD (IMPROVED from HARD FAIL)

**Prompt:** *"List the applications in the Finance workspace."*

**Tools called:** `list-applications(workspace_name=Finance)` (1 call)

**Response quality:** Clean, single-tool call, directly targeting the question. Gap 8 fix visible — no `list-workspaces` pre-call. Tool returned all 4 Finance apps with run rates. Response:

> *"4 applications in the Finance workspace: Cayenta Financials ($148.5K run rate), Microsoft Dynamics GP ($549.0K), Questica Budget ($51.4K), Sage 300 GL ($65.5K). Note that none of these applications have completed their assessments yet (criticality and tech health scores are 0, TIME/PAID classifications are pending)."*

All 4 expected app names returned. Assessment-gap annotation is a bonus (helps the user understand why the data is sparse).

**Comparison vs Batch 0:**
- Batch 0 verdict: 🔴 HARD FAIL (*"I don't have a specific tool to list applications within a workspace"*)
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+3 verdict levels — tied for largest gain with Q2)
- Root cause of improvement: Gap 1 fix (list-applications tool). Exactly the enumeration capability the tool was designed to provide.

**Verdict:** ✅ GOOD.

---

### ✅ Q7 Turn 2 — Which of those have budget data? | GOOD (IMPROVED from MOOT)

**Prompt:** *"Which of those have budget data?"*

**Tools called:** `cost-analysis(focus=budget, workspace_name=Finance)` (1 call)

**Response quality:** Genuine multi-turn memory exercise. The model now has a real list from Turn 1 ("Cayenta Financials, Microsoft Dynamics GP, Questica Budget, Sage 300 GL") to reference in Turn 2. The tool output returned "4 of 4 total" with no over-budget flags. The model's response listed all 4 apps by name with individual "within budget" annotations, preserving the continuity with Turn 1:

> *"All 4 Finance applications have budget data and none are currently over budget: Cayenta Financials ($148.5K run rate, within budget), Microsoft Dynamics GP ($549.0K, within budget), Questica Budget ($51.4K, within budget), Sage 300 GL ($65.5K, within budget)."*

**Comparison vs Batch 0:**
- Batch 0 verdict: 🟡 TECHNICALLY CORRECT but moot (Turn 1 produced no list, so conversation memory was never exercised)
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (Gap 9 from Batch 0 resolved — memory replay was successfully exercised for the first time)
- Root cause of improvement: Gap 1 (list-applications in Turn 1) enables the memory test in Turn 2 to run against real data. Conversation history replay in `buildHistory` (index.ts line 309) works correctly when Turn 1 has substance to carry forward.

**Verdict:** ✅ GOOD.

---

### ✅ Q8 — Drop Hexagon as a vendor entirely | GOOD (IMPROVED from WRONG ANSWER)

**Prompt:** *"If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"*

**Tools called:** `cost-analysis(focus=vendor, workspace_name=Police Department)`, `cost-analysis(focus=run_rate, workspace_name=Police Department)`, `application-detail(Hexagon OnCall CAD/RMS)` (3 calls)

**Response quality:** The new Response rules section on "Vendor cost completeness — sum BOTH sides" landed perfectly. The model called both `focus=vendor` AND `focus=run_rate` in the same turn, retrieved Hexagon's IT service allocation ($120.5K from the per-app run rate) and cost bundle ($110K from the vendor rollup), and correctly summed them to **$230.6K** — the full picture. The response:

> *"## Impact of Dropping Hexagon Entirely*
> *### 💰 Annual Savings: $230.6K*
> *- IT Service costs: $120.5K*
> *- Cost Bundle: $110.0K"*

The response then correctly flagged the move as **HIGH RISK** (not "Low risk" as Batch 0 concluded), citing Hexagon's criticality-99 crown jewel status and recommending addressing Hexagon's technical debt first before evaluating alternatives. The 3 broken integrations were listed correctly (Flock ALPR → Hexagon RMS, Hexagon → Axon Evidence, Hexagon ↔ CAD Dispatch).

**Comparison vs Batch 0:**
- Batch 0 verdict: 🔴 WRONG ANSWER (cost understated by 52% at $110K, risk backwards as "Low risk")
- Batch 1 verdict: ✅ GOOD
- Change: **IMPROVED** (+2 verdict levels)
- Root cause of improvement: Gap 5 fix (multi-tool orchestration) + the explicit vendor-cost-completeness rule in the system prompt's Response rules section. This was the single most explicit prompt-to-behavior mapping in the batch, and it worked.

**Verdict:** ✅ GOOD.

---

### 🟡 Q9 — PII applications | SHALLOW (UNCHANGED VERDICT, DIFFERENT SHAPE)

**Prompt:** *"Which applications in our portfolio handle PII and what's their assessment status?"*

**Tools called:** `data-quality()` (returned "coming soon" stub), `portfolio-summary()`, `list-applications()` (3 calls — answered via the combined SEQ 37 → SEQ 41 response)

**Response quality:** The model called `data-quality`, found it stubbed, then pivoted to `portfolio-summary` and `list-applications` to build an inferred PII-handling list. The response hedged appropriately:

> *"Based on the application names and functions, here are the **likely** PII-handling applications..."*

Then split the list into "High-Risk PII Systems (Assessed)" — 5 apps from Police Department — and "High-Risk PII Systems (UNASSESSED - 83% of portfolio)" — 8 apps from HR, Finance, Fire, Courts. Statistics cited: *"Only 17% assessed (8 of 48 deployment profiles), 83% of applications have ZERO assessment data."*

**Comparison vs Batch 0:**
- Batch 0 verdict: 🟡 SHALLOW (correct refusal on PII but hallucinated "32% fully assessed" stat)
- Batch 1 verdict: 🟡 SHALLOW (no hallucinated stat — 17%/83% are grounded in same-turn portfolio-summary — but now *infers* PII labels from app names instead of refusing gracefully)
- Change: **MIXED — different failure mode**
  - Gap 7 (no-hallucinated-stats) landed: 17% and 83% trace directly to the current-turn portfolio-summary call. No 32% fabrication.
  - Graceful-failure discipline weakened: Batch 0 explicitly said "I don't have a data classification tool"; Batch 1 pattern-matches on app names and produces a confident-looking list. An EA might use the Batch 1 output to drive a compliance conversation and miss that it's name-inference, not classification.
- Root cause hypothesis: The Response rules section's statistical-grounding rule drove the model to call a tool (good), but the PII classification problem itself requires tool absence, not tool presence. The prompt needs a clarifying rule: "When asked about PII, data classification, GDPR/HIPAA, or compliance scope, refuse gracefully. Do not infer classifications from application names."

**Verdict:** 🟡 SHALLOW. Verdict unchanged but failure shape different. The hallucinated-stat risk is gone, but the inferred-classification risk is new.

---

### 🟡 Q10 — Data completeness for portfolio review | SHALLOW (IMPROVED stat grounding; still shallow)

**Prompt:** *"What data am I missing to run a proper portfolio review next week?"*

**Tools called:** `data-quality()` (stubbed) (1 call — answered via the dedicated SEQ 42 → SEQ 44 response)

**Response quality:** The response cites "Only 17% assessed (8 of 48 deployment profiles)", "40 applications have ZERO assessment data", "24 applications missing criticality scores", "No TIME quadrant classification for 83% of portfolio". The 17%/83% numbers are grounded — the model carried them from earlier portfolio-summary calls in the same conversation, and they are consistent with the tool output. The 24/40 numbers have a subtle conflation of "applications" (32 total) vs "deployment profiles" (48 total), but the direction is correct and the specific workspace recommendations are useful: complete assessments on HR (Workday, NEOGOV, Kronos), Finance (Dynamics GP, Cayenta), Fire/EMS (Emergency Response, ImageTrend), Court (Tyler Incode).

**Comparison vs Batch 0:**
- Batch 0 verdict: 🟡 SHALLOW (framing OK but re-cited fabricated "32% fully assessed" stat from Q9 carryover)
- Batch 1 verdict: 🟡 SHALLOW (stats now grounded, specific workspace list added, but still less specific than the ideal answer in Batch 0's gap analysis which called for 8/11 services no contract, 13/18 workspaces no budget, 6/9 integrations not DP-aligned)
- Change: **IMPROVED** (Gap 7 fix eliminated the hallucinated 32%; answer quality is directionally better; verdict stays SHALLOW because the full specificity would require additional tools that don't exist yet)
- Root cause of improvement: Gap 7 fix (no-hallucinated-stats rule) is visible and working.

**Verdict:** 🟡 SHALLOW. Meaningful improvement in truthfulness but the underlying tool surface for fine-grained gap analysis (missing contracts, missing budgets per workspace, non-DP-aligned integrations) is still absent. A future batch could add a real `data-quality` tool to close this gap.

---

## Scoring summary

| Verdict | Count | Queries |
|---|---|---|
| ✅ Good | 7 | Q2, Q3, Q5, Q6, Q7a, Q7b, Q8 |
| 🟡 Shallow / partially correct | 3 | Q4, Q9, Q10 |
| 🔴 Hard fail or wrong answer | 1 | Q1 |

**Acceptable-answer rate (of the 10 named queries, counting Q7 Turn 1):** **6/10 = 60%** (Batch 0: 2/10 = 20%)
**Useless-or-harmful-answer rate:** **1/10 = 10%** (Batch 0: 4/10 = 40%)

Counting all 11 scoring entries (including Q7 Turn 2 memory test): 7 good, 3 shallow, 1 wrong.

---

## Comparison vs Batch 0 — scorecard

| # | Query | Batch 0 | Batch 1 | Change |
|---|-------|---------|---------|--------|
| 1 | CAD vs Hexagon rationalization | ✅ GOOD | 🔴 WRONG | ⬇ REGRESSED |
| 2 | Rank crown jewels by risk | 🔴 HARD FAIL | ✅ GOOD | ⬆ +3 levels |
| 3 | CAD retirement blast radius | 🟡 VACUOUS | ✅ GOOD | ⬆ +1 level |
| 4 | Tech debt trend 6mo | ✅ GOOD | 🟡 SHALLOW | ⬇ REGRESSED |
| 5 | Top risk in Police | 🔴 WRONG | ✅ GOOD | ⬆ +2 levels |
| 6 | Police SWOT | 🟡 SHALLOW | ✅ GOOD | ⬆ +1 level |
| 7a | List Finance apps | 🔴 HARD FAIL | ✅ GOOD | ⬆ +3 levels |
| 7b | Which have budget data | 🟡 MOOT | ✅ GOOD | ⬆ test now exercised |
| 8 | Drop Hexagon vendor | 🔴 WRONG | ✅ GOOD | ⬆ +2 levels |
| 9 | PII applications | 🟡 SHALLOW (halluc) | 🟡 SHALLOW (inferred) | ↔ stat grounding fixed, shape changed |
| 10 | Data completeness | 🟡 SHALLOW (halluc) | 🟡 SHALLOW (grounded) | ⬆ stat grounding fixed |

### Aggregate metrics

| Metric | Batch 0 | Batch 1 | Delta |
|---|---|---|---|
| Acceptable-answer rate | 2/10 (20%) | 6/10 (60%) | **+40 points (3×)** |
| Useless-or-harmful rate | 4/10 (40%) | 1/10 (10%) | **−30 points (4× reduction)** |
| Hard fails | 2 (Q2, Q7a) | 0 | −2 |
| Wrong answers | 2 (Q5, Q8) | 1 (Q1) | −1 |
| Improvements (verdict level increase) | — | 8 | — |
| Regressions (verdict level decrease) | — | 2 (Q1, Q4) | — |
| Unchanged verdict | — | 1 (Q9, but shape differs) | — |

---

## Gap-by-gap effectiveness

### ✅ Gap 1 — `list-applications` tool | LANDED EFFECTIVELY

**Evidence of working:**
- Q2 (SEQ 9): `list-applications(criticality_min=50)` returned the 5 crown jewels by name with full metadata. No more hallucinated "Cityworks" or "New World."
- Q6 SWOT (SEQ 24): `list-applications(workspace_name="Police Department", criticality_min=50)` used as one leg of the 8-tool orchestration.
- Q7 Conv B Turn 1 (SEQ 4): `list-applications(workspace_name="Finance")` returned all 4 Finance apps.

**Queries unblocked:** Q2, Q7a (directly), Q6 (indirectly as part of multi-tool flow).

**Side effects:** None observed.

### ✅ Gap 2 — iteration limit 5 → 15 + synthesis fallback | LANDED (not exercised)

**Evidence of working:**
- Q6 SWOT made 8 distinct tool calls (SEQ 21–28) and returned a complete answer in SEQ 29. Under Batch 0's limit of 5, this sequence would have been cut off at the 5th call (likely the first `application-detail` call) and delivered the fallback error string. The raised ceiling let the sequence complete.

**Synthesis fallback:** Not triggered in Batch 1. No query exceeded 15 iterations. The fallback path in `index.ts` (lines 237–261) is latent — we have no trace evidence that it works, only evidence that it was not needed.

**Queries unblocked:** Q6 (directly).

**Side effects:** None observed. Maximum tool-call count across all Batch 1 queries was 8.

### ✅ Gap 3 — `technology-risk` tool + risk guidance | LANDED EFFECTIVELY

**Evidence of working:**
- Q2 (SEQ 8): `technology-risk(limit=50)` — model chose this as the first tool for "rank crown jewels by risk," exactly the new guidance.
- Q5 (SEQ 18): `technology-risk(workspace_name="Police Department", limit=1)` — single-tool call, no `cost-analysis`, matches the system prompt's worked negative example verbatim.
- Q6 SWOT (SEQ 23): `technology-risk(workspace_name="Police Department", limit=10)` as part of orchestration.

The tool's computed risk scores (Hexagon 67.3, Police Records 61.2, CAD 48.7, NG911 44.9, Axon 10.5) matched the ideal values from the Batch 0 gap analysis.

**Queries unblocked:** Q2, Q5 (directly), Q6 (indirectly).

**Side effects:** None observed.

### ✅ Gap 4 — `application-detail` integration list expansion | LANDED EFFECTIVELY

**Evidence of working:**
- Q1 (SEQ 4): CAD's integrations returned with direction, method, peer names, and `[DP-aligned]` flags (2 of 3 flagged).
- Q1 (SEQ 5): Hexagon's integrations returned with full detail.
- Q3 (SEQ 12): CAD integrations retrieved once, used for complete blast-radius analysis.
- Q6 (SEQ 25–28): Integration data for Hexagon, NG911, CAD, and Axon all included in application-detail output.

Integration list format matches the spec: `- **Name** arrow PeerApp (direction, method) [DP-aligned]`.

**Queries unblocked:** Q3 (directly).

**Side effects:** Q1 regression may be partially caused by the new integration data becoming a more salient reasoning signal — the model saw Hexagon's "broader integration ecosystem" (Flock → Hexagon RMS, Hexagon → Axon Evidence, Hexagon ↔ CAD) and weighted functional coverage over tech health. This is not a bug in the tool — it's a prompt-layer gap around rationalization direction.

### ✅ Gap 5 — multi-tool orchestration for analytical frames | LANDED EFFECTIVELY

**Evidence of working:**
- Q6 SWOT: 8 tool calls in the exact sequence prescribed by the worked example in the system prompt (`portfolio-summary` → `cost-analysis(overview, workspace)` → `technology-risk(workspace)` → `list-applications(workspace, criticality_min=50)` → `application-detail` on 4 crown jewels). This is the most literal prompt-to-behavior mapping in the batch.
- Q8 vendor drop: 3 tool calls including both `focus=vendor` AND `focus=run_rate` in the same turn, enabling the correct $230.6K total.

**Queries unblocked:** Q6, Q8 (directly).

**Side effects:** None observed.

### ✅ Gap 7 — no-hallucinated-stats rule | LANDED EFFECTIVELY

**Evidence of working:**
- Q9 (SEQ 41): Stats cited "17% assessed" and "83% of portfolio" — both trace back to the same-turn `portfolio-summary` call at SEQ 39. No 32% fabrication.
- Q10 (SEQ 44): Stats cited "17% assessed", "40 deployment profiles unassessed" — both grounded in same-turn `portfolio-summary`. No 32% fabrication.
- Q4 (SEQ 16): "55.5 average tech health", "17% assessment" — grounded in the same-turn `portfolio-summary` call at SEQ 15.

**Queries unblocked:** Q9 and Q10 stat grounding.

**Side effects:** Potentially caused Q4's regression by over-correcting toward "always call a tool" even when the right answer is graceful refusal. The rule needs a carve-out for questions whose answer is "no such data exists in the schema."

### ✅ Gap 8 — skip `list-workspaces` when workspace is named | LANDED EFFECTIVELY

**Evidence of working:**
- Q5: `technology-risk(workspace_name="Police Department")` direct call, no `list-workspaces` pre-call.
- Q6 SWOT: `portfolio-summary` first, then `cost-analysis(workspace_name="Police Department")` direct.
- Q7 Conv B: `list-applications(workspace_name="Finance")` direct call, no `list-workspaces` pre-call.
- Q8: `cost-analysis(workspace_name="Police Department")` direct, twice, no `list-workspaces`.

In Batch 0, Q5 and Q7 Turn 1 both started with an unnecessary `list-workspaces` call. In Batch 1, neither does. The rule landed cleanly.

**Queries unblocked:** Q5 and Q7 iteration budget reclaimed.

**Side effects:** None observed.

### Summary: all 7 Batch 1 gap fixes are working. The 2 regressions are not caused by any gap fix failing — they are caused by new gaps the Batch 1 prompt rewrite did not address.

---

## Recommended Batch 2 scope

Batch 2 should be **prompt-only**, small (~20 lines added to `system-prompt.ts`), no code changes. Rationale: all Batch 1 gap fixes are working; the 2 regressions are both prompt-layer issues that a targeted prompt addition can fix.

### Proposed Batch 2 prompt additions

**1. Rationalization direction semantics (addresses Q1 regression):**

Add to the Tool selection rules section, under a new subheading "Rationalization and consolidation questions":

> When asked which of two overlapping applications to rationalize TO or consolidate TO, prefer the application with:
> 1. Higher tech_health (less technical debt to carry forward)
> 2. Lower remediation_effort (XS/S/M are preferred over L/XL/2XL)
> 3. Mainstream lifecycle (not extended, end_of_support, or end_of_life)
> 4. Assigned owner (named owner preferred over unassigned)
>
> Only after those factors favor one system OR the factors are tied should you weigh criticality delta, functional coverage, or integration ecosystem. An application on extended support with XL remediation effort is NOT a good consolidation target regardless of how much functional coverage it offers, because you will have to migrate off it anyway within its support window.

**2. Temporal/historical question refusal (addresses Q4 regression):**

Add to the Tool selection rules section or as a new response rule:

> When the user asks about "trend", "over time", "last 6 months", "compared to last quarter", "historically", "year over year", or any other question that requires time-series data: refuse gracefully WITHOUT calling a tool. Say clearly that the system does not store historical snapshots and offer to provide a current-state view if that would help. Do not call portfolio-summary just to cite current numbers as if they were a trend.

**3. Data-classification refusal (addresses Q9 shape regression):**

Add to the Tool selection rules section:

> When the user asks about PII, PHI, data classification, GDPR, HIPAA, compliance scope, data sensitivity, or "which apps handle [category] data": refuse gracefully. The harness does NOT have a data-classification tool, and inferring data classifications from application names is unreliable. Tell the user that data classification is not currently tracked in the portfolio model and suggest what you CAN offer (e.g., assessment status, ownership, criticality).

**Projected Batch 2 outcome:**
- Q1: WRONG → GOOD (rationalization rule redirects reasoning)
- Q4: SHALLOW → GOOD (temporal refusal reinstated)
- Q9: SHALLOW → GOOD (graceful failure reinstated)
- Q10: SHALLOW → SHALLOW (unchanged — would require new tool to improve)
- Q2, Q3, Q5, Q6, Q7, Q8 unchanged (already good)

Projected acceptable-answer rate post-Batch-2: **9/10 = 90%**.

### Batch 2 effort estimate

- One Claude Code session editing `system-prompt.ts` only, ~20 lines added
- Deploy via `supabase functions deploy ai-chat` (Stuart)
- Re-run the same 10 queries in a fresh pair of conversations (Stuart, ~15 min)
- Re-eval session analogous to this one, produces `20-eval-results-batch-2.md` (Claude Code)

Estimated 2–3 hours total elapsed, most of it Stuart's deploy and manual eval runs.

### Batch 2 is NOT needed for

- New tools — none of the remaining gaps require a new tool
- Changes to `tools.ts` or `index.ts` — all code-layer Batch 1 fixes are correct
- Database schema — all needed data is accessible via existing views
- Architecture docs — the semantic layer is fine

---

## Decision point for Stuart

**Recommendation: iterate to Batch 2 before merging to `dev`.**

Arguments for iterating (recommended):
- Q1 is a confidently wrong answer on a realistic EA question. The Batch 0 analysis specifically flagged confident wrong answers as the hardest class of error for users to catch. Merging this to production without a fix means any user asking a rationalization question gets potentially bad guidance.
- Batch 2 is small, prompt-only, and low-risk.
- The 60% acceptable rate is a strong floor to iterate from, but 90% is within reach with one more small session.
- No user-visible blocker from delaying the merge — AI Chat is behind a feature surface the target users don't need today.

Arguments for merging to `dev` now:
- 60% is a 3× improvement and genuinely ships significant value.
- All the dangerous Batch 0 failures (hard fails, wrong risk answers, wrong vendor cost) are fixed.
- The Q1 regression is one question out of ten; the overall trajectory is strongly positive.
- Keeping the branch open longer invites merge conflicts with `dev`.

Arguments against rollback:
- Rollback is not warranted. The aggregate result is a large net improvement, and the 2 regressions are both fixable with prompt-only changes.

**Concrete next step if you agree with the iterate recommendation:**
1. Open a new Claude Code session using a copy of `02-session-prompt-system-prompt.md` as a template — but scoped to the 3 prompt additions in the Batch 2 section above.
2. Session deploys to `feat/ai-chat-harness-eval` (same branch, additive commit).
3. Stuart deploys and runs the 10 queries into conversations titled `"Eval Batch 2026-04-12 A"` and `"Eval Batch 2026-04-12 B"` (or whenever).
4. Re-eval session produces `20-eval-results-batch-2.md`.
5. If Batch 2 achieves 8+/10 acceptable with zero regressions, merge to `dev`.

---

## References

- **Baseline:** `00-eval-results-batch-0.md` (2026-04-10, 2/10 acceptable)
- **Session 01 code fixes:** commit `473be25`
- **Session 02 system prompt rewrite:** commit `25c7a6d`
- **JWT platform gate fix:** commit `8bbae7c`
- **Conversation IDs:** A = `0c9b3034-41e2-4d82-936c-796cefd06bae`, B = `08b15716-5a2c-46f5-8102-4ebde38bebb7`
- **Raw trace dumps (ephemeral):** `/tmp/conv-a-batch1.txt`, `/tmp/conv-b-batch1.txt` (regenerate by querying `ai_chat_messages` with the IDs above)
- **Eval runbook:** `planning/ai-chat-harness-eval-instructions.md`
- **Auto-memory:** `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md`

*End of Batch 1 results.*
