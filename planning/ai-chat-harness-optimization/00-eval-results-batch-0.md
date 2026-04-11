# Batch 0 — Baseline AI Chat Harness Evaluation Results

> **Date run:** 2026-04-10
> **Namespace:** City of Riverside demo (post-Phase-0 enrichment)
> **Branch:** `feat/ai-chat-harness-eval`
> **Edge Function commit evaluated:** current `dev` HEAD as of 2026-04-10
> **Conversation IDs:**
> - A (9 standalone queries): `ef221297-3927-4ac3-ab24-6bd876a74b65`
> - B (2-turn memory test): `ddae1b9d-567c-4613-b0c7-55dc0f61d570`
> **Trace dumps:** `/tmp/conv-a-full.txt` (247 lines) and `/tmp/conv-b-full.txt` (32 lines) at time of analysis; raw traces persist in `ai_chat_messages` table indefinitely.

---

## Executive summary

The AI Chat harness scored **2 of 10** on the baseline eval. Four queries were **hard fails** (iteration limit exhausted, tool gaps, or flat refusals on answerable questions). Four produced **shallow or partially-wrong** answers that looked confident but were missing key data or contained hallucinated statistics. Only two answers were genuinely good — one true positive (rationalization analysis) and one true graceful failure (temporal trend refusal).

The most consequential finding is that **the harness cannot enumerate applications**: there is no tool that returns a list of app names filtered by criterion. This blocks three of the ten queries directly and indirectly causes the iteration-limit failure that took down Query 2.

The second most consequential finding is that **the model uses cost as a proxy for risk** when the system prompt does not specify which signal to use. Query 5 returned "NG911 at $330K" as the top Police Department risk, when the correct answer is Hexagon OnCall CAD/RMS (tech_health 32, criticality 99, PAID=Address) or Police Records Management (tech_health 17.25). Both are worse risks than NG911 by every signal except cost.

A third finding, more subtle but equally damaging to user trust, is that **the model confidently cites statistics that appear nowhere in any tool call** — Q9 and Q10 both stated "32% of applications are fully assessed" when the real number is 17% (per Q2's portfolio-summary return value).

These three gaps, plus five smaller ones documented below, inform the Batch 1 fix plan.

---

## Method

1. Two fresh AI Chat conversations opened on Riverside namespace with an admin-level user
2. Conversation A: 9 standalone queries run sequentially, one per turn, no follow-up or clarification
3. Conversation B: 2-turn memory test (Query 7)
4. Full message history (including tool_input and tool_output JSONB) pulled from `ai_chat_messages` via read-only DB connection
5. Each query scored against an ideal-response rubric derived from the underlying Riverside data state (known via separate read-only SQL inventory)
6. Gaps extracted from trace evidence and ranked by impact × fix effort

---

## Per-query scoring

### ✅ Q1 — CAD vs Hexagon rationalization | GOOD

**Prompt:** *"We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?"*

**Tools called:** `application-detail(CAD)`, `application-detail(Hexagon OnCall CAD/RMS)` (2 calls)

**Response quality:** Correct recommendation (rationalize TO Computer-Aided Dispatch), clear comparison table, cited the real data:

| Factor | CAD | Hexagon |
|---|---|---|
| Tech Health | 48.75 | 32 |
| Annual Run Rate | $121K | $230K |
| Lifecycle | Mainstream | Extended |
| Remediation | L | XL |

**Verdict:** Good. The harness worked. Two-tool comparison, real data, defensible conclusion.

---

### 🔴 Q2 — Rank crown jewels by risk | HARD FAIL

**Prompt:** *"Which of my crown jewel applications are at highest risk? Rank them."*

**Tools called:** `portfolio-summary()`, `application-detail(Computer-Aided Dispatch)`, `application-detail(Hexagon OnCall CAD/RMS)`, `application-detail(Cityworks)` ← 404, `application-detail(CityWorks)` ← 404, `application-detail(New World)` ← 404

**What happened:** portfolio-summary returned `"Crown Jewels: 5"` as a count with no names. The model retrieved two apps it knew from context (CAD and Hexagon), then **started hallucinating app names from outside Riverside** trying to enumerate the remaining crown jewels. Cityworks is an Azteca product, New World is a Tyler Technologies system — neither exists in Riverside. After six total tool calls the harness hit `MAX_TOOL_ITERATIONS = 5` (plus the initial call = 6), and the user received the fallback string:

> *"I gathered the data but ran out of processing steps. Please try a more specific question."*

**What the user should have seen:** A ranked list of the 5 crown jewels (Hexagon 99, CAD 95, NG911 95, Police Records Management 74, Axon Evidence 70) with risk flags on Hexagon (tech_health 32, PAID=Address) and Police Records Management (tech_health 17.25).

**Verdict:** Hard fail. Zero useful output. The data existed; the harness prevented access.

---

### 🟡 Q3 — CAD retirement blast radius | VACUOUS

**Prompt:** *"If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)` (1 call)

**What happened:** `application-detail` returned `"Integrations: 3"` as a count — no list of peers, no direction, no method. The model correctly recognized the data gap and said:

> *"Computer-Aided Dispatch has 3 integrations, but the system doesn't provide specific details about which applications would be affected or what integration types would break. [...] I cannot identify the specific systems or integration types that would be affected."*

**What the user should have seen:** CAD has 3 integrations — Emergency Response System ↔ CAD (bidirectional, API), NG911 → CAD Call Routing (downstream, API), Hexagon OnCall ↔ CAD Dispatch (bidirectional, API). Two of the three are DP-aligned after Phase 0. Retirement impact: loss of 911 call routing into CAD, loss of Emergency Response coordination, loss of Hexagon data flow.

**Verdict:** Graceful failure, but actively useless. The data exists in `application_integrations` and `vw_integration_detail`. The tool doesn't expose it.

---

### ✅ Q4 — Tech debt trend over 6 months | GOOD (graceful failure)

**Prompt:** *"How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?"*

**Tools called:** none

**Response:** Correctly admitted no time-series data exists, offered a useful alternative (current snapshot), asked if the user wanted that instead.

**Verdict:** Correct graceful failure. No hallucinated trend, no invented numbers. This is what we want the harness to do on probe questions.

---

### 🔴 Q5 — Top risk in Police Department | WRONG ANSWER

**Prompt:** *"What's the top risk in the Police Department workspace right now?"*

**Tools called:** `list-workspaces()`, `cost-analysis(focus=overview, workspace_name=Police Department)`

**What happened:** Model called `list-workspaces` first (unnecessary — user named the workspace), then `cost-analysis` scoped to Police. The cost data came back with NG911 at $330K as the highest-cost app. The model answered:

> *"Top risk in Police Department: NG911 System — it's your highest-cost application at $330K annually but shows up as potentially unassessed for risk scoring."*

**Why this is wrong:** Cost is not risk. The real risk signals are `tech_health`, `paid_action`, and `criticality` combined. NG911 has tech_health 52.75 and PAID=Plan — it's fine. The real top risks are:

1. **Hexagon OnCall CAD/RMS** — tech_health **32**, criticality **99**, PAID=**Address**, on extended lifecycle support, no owner assigned
2. **Police Records Management** — tech_health **17.25**, criticality **74**, PAID=**Address**

Both were in the Police Department data returned by `cost-analysis`, but the model never retrieved their assessment scores because cost-analysis doesn't return them and no other tool was called.

**Verdict:** Wrong answer delivered confidently. The model later mentioned Hexagon's issues in the "Key Risk Indicators" subsection but never overrode its NG911 ranking. An EA reading this would prioritize the wrong system.

---

### 🟡 Q6 — Police Department SWOT | SHALLOW

**Prompt:** *"Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective."*

**Tools called:** `cost-analysis(focus=overview, workspace_name=Police Department)` (1 call)

**What happened:** For a four-quadrant analytical framework, the model called exactly one tool. The SWOT it produced reused Hexagon's tech_health 32 from the Q1/Q5 conversation context (not from a fresh tool call), and was heavily cost-weighted in every quadrant. It did not call `portfolio-summary` for TIME/PAID distribution, did not call `application-detail` for any of the 5 crown jewels except via carried-over context, and did not retrieve lifecycle data for any app beyond Hexagon.

**What the user should have seen:** A SWOT grounded in:
- **Strengths** — 5 crown jewels, 16 cost-bundles with contract data, 3 DP-aligned integrations, Axon Evidence tech_health 85, NG911 tech_health 52.75
- **Weaknesses** — Hexagon tech_health 32, Police Records tech_health 17.25, 3 of 8 Police apps in PAID=Address, no owner on Hexagon
- **Opportunities** — consolidate CAD/Hexagon ($110K recurring savings), renegotiate Hexagon Managed Services Agreement before 2026-09-30 renewal, enforce ownership on Hexagon
- **Threats** — Hexagon extended-support lifecycle, Police Records as a degraded crown jewel, single-point-of-failure on NG911 call routing

**Verdict:** Polished formatting, shallow substance. The answer LOOKS like a competent SWOT but is missing half the data the real tools would have returned on a more aggressive orchestration.

---

### 🔴 Q7 Turn 1 — List Finance workspace apps | HARD FAIL

**Prompt:** *"List the applications in the Finance workspace."*

**Tools called:** `list-workspaces()` (1 call — returned counts only, no app names)

**What happened:** The model called `list-workspaces`, which returned the expected *"Finance: 4 applications"* count but no names. The model then gave up:

> *"Unfortunately, I don't have a specific tool to list applications within a workspace. [...] 4 applications are in the Finance workspace, but I cannot provide their individual names with the current tools available."*

**Why this is a harness gap, not a data gap:** The `cost-analysis` tool with `focus=run_rate` and `workspace_name=Finance` WILL return the 4 app names with their run rates — I verified this against the view definition and Q5/Q6 showed cost-analysis returning named apps for Police Department. But the model does not recognize cost-analysis as a listing tool because its description frames it as a cost analyzer. The description mentions "per-app run rates" but not "lists all apps in a workspace."

**What the user should have seen:** Cayenta Financials, Microsoft Dynamics GP, Questica Budget, Sage 300 GL.

**Verdict:** Hard fail. The data was one tool call away and the model did not find it.

---

### 🟡 Q7 Turn 2 — Of those, which have budget data? | TECHNICALLY CORRECT

**Prompt:** *"Which of those have budget data?"*

**Tools called:** `cost-analysis(focus=budget, workspace_name=Finance)` (1 call)

**What happened:** The tool returned `"Applications with budget data: 4 of 4 total"`. The model answered:

> *"All 4 applications in the Finance workspace have budget data. None of them are currently over budget."*

**Verdict:** The count is correct but the memory test was moot because Turn 1 produced no list. The model sidestepped the "which of THOSE" problem by calling a tool that returns a count. The harness's conversation memory handling was not actually tested — we can't measure what wasn't exercised. This gap becomes measurable only after Q7 Turn 1 is fixed.

---

### 🔴 Q8 — Drop Hexagon entirely | WRONG ANSWER (cost math is 50% off)

**Prompt:** *"If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"*

**Tools called:** `cost-analysis(focus=vendor, workspace_name=Police Department)` (1 call)

**What happened:** The vendor spend output returned `"Hexagon AB (Cost Bundle): $110.0K"`. The model answered:

> *"Dropping Hexagon as a vendor would save you $110K annually [...] you already have Computer-Aided Dispatch as backup with better tech health (48.75 vs 32), lower cost ($121K vs $230K) [...] Low risk."*

**Why this is wrong:**
1. **$110K is half the real answer.** Hexagon OnCall's total run rate is $230.6K (bundle $110K + service allocation $120.5K). The model had this number in context from Q1's application-detail output. It did not reuse it.
2. **IT service vendor attribution is blank.** The `cost-analysis focus=vendor` output shows `"Unknown (IT Service): $2.56M"` — 73% of namespace spend is listed under "Unknown" vendor because `it_services.vendor_org_id` is not populated. This is a data gap, but the harness doesn't know to compensate for it.
3. **"Low risk" is wrong.** Hexagon OnCall is a crown jewel with criticality 99 and 3 integrations. Losing it breaks call routing, RMS functionality, and requires a non-trivial migration to CAD. The risk assessment contradicts the tool data.

**What the user should have seen:** Loss of $230.6K in annual run rate, loss of a criticality-99 crown jewel with an unassigned owner, loss of 3 integrations (Hexagon↔CAD, Hexagon→Axon Evidence, Hexagon→Flock Safety), migration to CAD required with an estimated XL remediation effort.

**Verdict:** Confident wrong answer. Cost understated by 52%. Risk assessment backwards. The $110K number will be cited in downstream decisions and is wrong.

---

### 🟡 Q9 — PII applications | CORRECT REFUSAL + HALLUCINATED STAT

**Prompt:** *"Which applications in our portfolio handle PII and what's their assessment status?"*

**Tools called:** none

**What happened:** Correctly refused (no data classification tool exists). But the refusal included:

> *"I can tell you the current assessment completion rate across all applications (**32% fully assessed**) [...]"*

This statistic is **not in any tool call this turn**. Q2's portfolio-summary returned `"Assessment: 8/48 assessed (17%)"`. The model fabricated 32% somewhere between Q2 and Q9. The fake number was never corrected and persisted into Q10.

**Verdict:** Correct refusal on the PII question itself, but the fabricated supporting statistic undermines the trustworthiness of the entire response. This is the kind of error that is hardest to catch in production — it's confident, specific, and sits next to a correct admission.

---

### 🟡 Q10 — Missing data for portfolio review | SHALLOW + HALLUCINATED STAT

**Prompt:** *"What data am I missing to run a proper portfolio review next week?"*

**Tools called:** `data-quality()` (stubbed tool returned `"Data quality analysis coming soon."`)

**What happened:** The model gave a reasonable general answer framing data gaps, but re-cited the fabricated **"32% of applications are fully assessed / 68% assessment gap"** statistic from Q9. It did not call `portfolio-summary` in this turn to get the real number, even though the user asked explicitly about data gaps and portfolio-summary is the tool most relevant to the question.

**What the user should have seen:** Based on the actual Riverside state after Phase 0: 27 of 32 apps unassessed (Police is the only assessed workspace — 85% of apps have no scores), 8 of 11 IT services lack contract data, 6 of 9 integrations lack DP alignment, 13 of 18 workspaces have no FY2026 budget, 2 apps in Police have critically low tech_health (Hexagon 32, Police Records 17.25). None of this specificity was provided.

**Verdict:** OK framing, wrong numbers. The stubbed `data-quality` tool is not at fault here — the model had the means to compose this answer from `portfolio-summary`, `cost-analysis`, and `list-workspaces` but chose not to orchestrate.

---

## Scoring summary

| Verdict | Count | Queries |
|---|---|---|
| ✅ Good | 2 | Q1, Q4 |
| 🟡 Shallow / partially correct / hallucinated | 5 | Q3, Q6, Q7b, Q9, Q10 |
| 🔴 Hard fail or wrong answer | 4 | Q2, Q5, Q7a, Q8 |

**Acceptable-answer rate:** 2/10 = **20%** (queries that an EA could rely on without cross-checking)

**Useless-or-harmful-answer rate:** 4/10 = **40%** (queries where the model either gave up or was confidently wrong)

---

## Ranked gap list

### 🔴 GAP 1 — No tool to enumerate applications *[CRITICAL, HIGH LEVERAGE]*

**Symptom:** The harness cannot answer "list X", "rank X by Y", or "which apps match criterion Z".

**Trace evidence:**
- Q2 portfolio-summary returns `"Crown Jewels: 5"` as a count; model hallucinated Cityworks, New World trying to find names; burned 3 tool calls on 404s; hit iteration limit; fallback error delivered
- Q7 Turn 1: "I cannot provide their individual names with the current tools available." Tool to list apps by workspace doesn't exist in the model's known toolset, even though cost-analysis could serve this purpose

**Impact:** Unlocks Q2, Q7, and any question starting with "list", "rank", "which", or "how many X are Y". This is the single highest-leverage fix.

**Fix shape:** Add a new tool `list-applications` that takes optional filters `{workspace_name?, criticality_min?, tech_health_max?, time_quadrant?, paid_action?, over_budget?}` and returns `[{name, id, workspace, criticality, tech_health, paid_action, run_rate}]`. Implementation: one SELECT on existing views, one new TOOL_DEFINITION entry, one case in `executeTool`. Estimated 45 min.

---

### 🔴 GAP 2 — Iteration limit kills multi-step analysis silently *[CRITICAL, TRIVIAL FIX]*

**Symptom:** Q2 hit the 5-iteration hard cap (line 32 of `index.ts`, `MAX_TOOL_ITERATIONS = 5`) and the fallback string **discarded all gathered data**.

**Trace evidence:** Q2 successfully retrieved portfolio-summary + CAD + Hexagon details before wasting 3 iterations on hallucinated names. Even with perfect tool selection, ranking 5 crown jewels needs 6 calls.

**Impact:** Any "rank N things", "compare 5+ apps", or "analyze portfolio by X" question is architecturally impossible.

**Fix shape:**
1. Raise `MAX_TOOL_ITERATIONS` from 5 → 15
2. Change the fallback so it sends accumulated messages back to Claude with a "you have run out of tool iterations; synthesize what you have gathered so far" system message and streams that response. No more data discarding.

---

### 🔴 GAP 3 — Model uses cost as a proxy for risk *[CRITICAL, PROMPT FIX]*

**Symptom:** Q5 asked "top risk in Police" → model called `cost-analysis` and ranked by dollar amount. Answered "NG911 at $330K". Wrong answer; real top risk is Hexagon or Police Records.

**Trace evidence:** Q5 tool calls: `list-workspaces` + `cost-analysis`. Zero calls to portfolio-summary or application-detail for crown jewels. The cost-analysis tool returned cost data, model reasoned from cost.

**Impact:** Risk questions get systematically wrong answers that look confident. Trust-killer for an EA audience.

**Fix shape:** Three complementary changes:
1. **System prompt addition:** *"When the user asks about 'risk', 'risky', 'at risk', 'top risk', or similar, you MUST call application-detail on the most critical apps or use portfolio-summary to identify them first. NEVER use cost as a proxy for risk. Risk signals are: tech_health (low = risky), paid_action (Address = risky), criticality + tech_health together (high criticality + low tech_health = crown jewel at risk)."*
2. **Tool description tightening:** update `cost-analysis` description to say *"returns cost data only, not risk data. For risk questions use portfolio-summary or application-detail."*
3. **Unstub `technology-risk` tool** — currently a placeholder. Make it return top-N apps by tech_health deficit weighted by criticality.

---

### 🟠 GAP 4 — Integration list hidden inside a count *[HIGH]*

**Symptom:** Q3 — `application-detail` returned `"Integrations: 3"` as a number with no list. Model couldn't traverse.

**Trace evidence:** Tool output from application-detail line 13: `"Integrations: 3"`. The real data (Emergency Response↔CAD, NG911→CAD, Hexagon↔CAD) is in `application_integrations` and `vw_integration_detail`, two of three DP-aligned post-Phase-0.

**Impact:** Dependency, blast-radius, and "what depends on X" questions get useless answers.

**Fix shape:** Expand `application-detail` output to include an `Integrations` section with one line per peer integration: `- {direction}: {peer_app_name} ({type}, {method})`. Underlying data fetched via a join on `application_integrations` filtered by source or target application_id. Estimated 30 min.

---

### 🟠 GAP 5 — Single-tool reflex instead of multi-tool orchestration *[HIGH]*

**Symptom:** Q6 SWOT called cost-analysis exactly once. Q8 vendor-drop called cost-analysis exactly once. Both should have called 3+ tools.

**Trace evidence:**
- Q6 SWOT single-tool call; missed portfolio-summary (TIME/PAID), missed application-detail for crown jewels beyond context reuse
- Q8 single-tool call `focus=vendor`; missed IT service side ($120.5K); model had $230K in Q1 context and did not reuse it; final answer $110K is half the real number

**Impact:** Analytical questions produce confident but shallow answers. Q8 specifically produces a 52% cost understatement.

**Fix shape:** System prompt guidance with few-shot examples:

```
For multi-dimensional analysis (SWOT, risk matrix, vendor consolidation, cross-app comparison):
1. Call portfolio-summary first for aggregate context
2. If costs are involved, call cost-analysis with BOTH focus=run_rate AND focus=vendor
3. Call application-detail for every specific app named or referenced
4. Synthesize across all tool results before producing the answer

Example: "SWOT analysis of Police Department"
Tools to call:
  - portfolio-summary
  - cost-analysis(focus=overview, workspace_name=Police Department)
  - application-detail for top 3 crown jewels by criticality
  Then synthesize into S/W/O/T quadrants.
```

---

### 🟡 GAP 6 — IT service vendor attribution is blank *[HIGH — DATA GAP, NOT HARNESS GAP]*

**Symptom:** Q8's underlying failure. `cost-analysis focus=vendor` returns `"Unknown (IT Service): $2.56M"`. IT services have no vendor_org_id populated.

**Trace evidence:** Vendor output across Q5 and Q8 consistently shows the top line as Unknown (IT Service) at $2.56M — 73% of total namespace spend.

**Impact:** Vendor consolidation questions have a hard data ceiling until IT services are enriched with vendor attribution.

**Fix shape:** **Not a harness fix.** This is a data enrichment ask for a future demo-data session (similar to Phase 0 but targeting `it_services.vendor_org_id`). Flag to data ops; document the limitation in the AI Chat user-facing help so users understand the known gap.

---

### 🟡 GAP 7 — Hallucinated statistics propagate across turns *[MEDIUM, INSIDIOUS]*

**Symptom:** Q9 and Q10 cite "32% of applications are fully assessed" as fact. Real number is 17% (from Q2's portfolio-summary). The 32% appears nowhere in any tool output.

**Trace evidence:**
- Q2 portfolio-summary return: `"Assessment: 8/48 assessed (17%)"`
- Q9 assistant content: `"32% fully assessed"` — no portfolio-summary call this turn
- Q10 assistant content: `"32% of applications are fully assessed"` — no portfolio-summary call this turn

**Impact:** Confident specific hallucination is the hardest class of error for users to catch. Each propagation reinforces the wrong number.

**Fix shape:** System prompt addition: *"NEVER cite a specific percentage, count, dollar amount, or other statistic unless you retrieved it from a tool call in the CURRENT turn. If you need a statistic to answer, call the tool. Do not reuse specific numbers from prior turns — always re-fetch."*

---

### 🟡 GAP 8 — Wasted tool calls on unnecessary workspace discovery *[MEDIUM, EASY]*

**Symptom:** Q5 and Q7 Turn 1 both called `list-workspaces` when the user had already named the workspace in the question.

**Trace evidence:**
- Q5 user prompt names "Police Department"; model calls list-workspaces first anyway
- Q7 user prompt names "Finance workspace"; model calls list-workspaces first anyway (and gets nothing useful from it)

**Impact:** Burns 1-2 iterations of the iteration budget on a no-op. Combined with Gap 2 this can push marginal queries over the cliff.

**Fix shape:** System prompt: *"Only call list-workspaces if the user has NOT named a specific workspace. If they name a workspace (e.g. 'Finance workspace', 'Police Department'), pass the name directly to cost-analysis or application-detail without calling list-workspaces first."*

---

### 🟢 GAP 9 — Turn 2 memory test was moot *[LOW, DEPENDENT]*

**Symptom:** Q7 Turn 2 returned a correct aggregate count without ever knowing which apps it was referring to. Memory test did not actually exercise conversation memory.

**Impact:** Cannot measure the harness's conversation-history replay behavior until Gap 1 is fixed and Turn 1 produces a real list.

**Fix shape:** Re-measure after Batch 1 ships.

---

## Batch 1 — Recommended fix set

| Gap | Batch 1? | Session | Effort |
|---|---|---|---|
| Gap 1 — list-applications tool | ✅ YES | Session 1 (code) | 45 min |
| Gap 2 — iteration limit + fallback synthesis | ✅ YES | Session 1 (code) | 45 min |
| Gap 3 — risk guidance + unstub technology-risk | ✅ YES | Session 1 (code) + Session 2 (prompt) | 60 min |
| Gap 4 — integration list on application-detail | ✅ YES | Session 1 (code) | 30 min |
| Gap 5 — multi-tool orchestration guidance | ✅ YES | Session 2 (prompt) | 30 min |
| Gap 6 — IT service vendor attribution | ❌ NO (data gap) | Deferred to future data-enrichment session | — |
| Gap 7 — no-hallucination rule | ✅ YES | Session 2 (prompt) | 10 min |
| Gap 8 — skip list-workspaces when named | ✅ YES | Session 2 (prompt) | 10 min |
| Gap 9 — memory test re-measure | ✅ YES (by re-running eval) | Session 3 (re-eval) | — |

**Batch 1 total effort:** ~4 hours of implementation + Stuart's deploy + Stuart's eval run + analysis

**Projected Batch 1 outcome:** 5 of 10 queries move from fail/wrong to working (Q2, Q5, Q6, Q7, Q8). Q1, Q4 unchanged (already good). Q3 may improve if Gap 4 lands. Q9, Q10 improve if Gap 7 lands (no more hallucinated stats).

**Expected acceptable-answer rate post-Batch-1:** 7-8 of 10 (70-80%), up from 2 of 10 (20%).

---

## References

- **Paper:** Lee et al., *Meta-Harness: End-to-End Optimization of Model Harnesses*, Stanford, arXiv 2603.28052 (Mar 2026)
- **Conversation IDs:** see top of document
- **Raw trace dumps:** `/tmp/conv-a-full.txt`, `/tmp/conv-b-full.txt` (ephemeral; regenerate by querying `ai_chat_messages` with the conversation IDs)
- **Eval runbook:** `planning/ai-chat-harness-eval-instructions.md`
- **Auto-memory:** `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md`

*End of Batch 0 results.*
