# Category Tools — AI Chat Harness Re-Evaluation Results

> **Date run:** 2026-04-11 (eval queries titled `Eval Categories 2026-04-11 A` / `B`)
> **Namespace:** City of Riverside demo (post-Phase-0 enrichment + post-Session-1 category enrichment)
> **Branch:** `feat/ai-chat-category-tools`
> **Edge Function commit evaluated:**
> - `30b08ec` — feat: AI Chat category tools — list-application-categories, category filter, category-rollup
> **Branch parent:** `dev` (which includes the merged Batch 1 + Batch 2 harness-optimization fixes — `25c7a6d`, `473be25`, `b17075a`, `2fd5393`, `3df564c`)
> **Conversation IDs:**
> - A (14 scoring entries — 9 regression + 5 new category): `80ddd76e-ea00-4c30-860b-1d2f08062283` (56 messages, 59,749 tokens)
> - B (4 scoring entries — Q7 Turn 1 + Turn 2 + 2 cross-tool): `e7531577-2e78-4717-a04a-169dbe0072f4` (21 messages, 41,329 tokens)
> **Baselines:**
> - `../ai-chat-harness-optimization/20-eval-results-batch-2.md` (2026-04-11, 10/10 acceptable on the regression set) — **this is the regression baseline because Batch 2 is already merged to `dev` and `feat/ai-chat-category-tools` was branched from `dev` after that merge.**
> - `../ai-chat-harness-optimization/10-eval-results-batch-1.md` (6/10 acceptable — superseded by Batch 2)
> - `../ai-chat-harness-optimization/00-eval-results-batch-0.md` (2/10 acceptable — superseded)
> **Trace dumps (ephemeral):** `/tmp/conv-a-categories.txt` (543 lines), `/tmp/conv-b-categories.txt` (156 lines). Raw traces persist in `ai_chat_messages` indefinitely.

---

## Executive summary

**11 of 11 regression entries held steady at GOOD except one — Q9 (data missing for review) regressed from GOOD to WRONG ANSWER** because the model cited "100% assessment coverage across all 32 applications" as a portfolio fact. The root cause is a **semantic bug in `category-rollup`**: the tool's `assessed_count` column is computed as `criticality !== null AND tech_health !== null` (tools.ts line 720), which counts apps with default-0 scores as "assessed." Riverside has 24 of 32 apps at `criticality=0 | tech_health=0` (clearly unassessed — they show as `— | —` in every other tool), but `category-rollup` reports them as "assessed" because the fields are non-null. The model faithfully reported what the tool said, then used the misleading framing to answer Q9. This is a tool-layer bug, not a model reasoning failure.

**Of the 5 new category queries (Q10–Q14), 3 are GOOD and 2 are SHALLOW.** The `list-application-categories` + `list-applications(category=...)` pattern works cleanly on the discovery-and-list workflow: Q10 ("what apps for CRM"), Q11 ("list Finance apps"), and Q14 ("citizen service requests") all return correct, useful, substantive answers. The `category-rollup` tool works mechanically but its misleading "Assessed" column shows up again in Q12 ("portfolio by capability") — the model reports the category breakdown correctly and then adds the unwarranted framing *"100% assessed across all categories — excellent portfolio visibility,"* which is factually wrong. Q13 ("categories with no crown jewels") has a minor off-by-one counting error: the model's summary says *"6 capability categories"* but then lists 7 items.

**Of the 2 cross-tool queries (Q17, Q18), 1 is WRONG and 1 is SHALLOW.** The cross-tool orchestration pattern did fire — Q17 called `category-rollup` + `technology-risk` (2 tools) and Q18 called `list-workspaces` + `list-applications × 2` + `category-rollup` (4 tools) — so the prompt's cross-tool subheading (*"category-rollup composes well with other tools"*) is landing. But the **synthesis is wrong in both cases** because the model inferred category membership instead of verifying it. Q17 confidently claims *"Legal & Regulatory carries the most technical debt"* citing Hexagon OnCall CAD/RMS + Police Records Management + Computer-Aided Dispatch as *"3 Legal & Regulatory applications."* Ground truth per the database: CAD is in `CRM` + `GIS_SPATIAL`, not `LEGAL`. The LEGAL crown jewels are actually Hexagon OnCall CAD/RMS, Police Records Management, and Axon Evidence (risk 10.5 — low). By sum of risk scores, **CRM** carries the most technical debt (Hexagon 67.3 + CAD 48.7 + NG911 44.9 = 160.9), not LEGAL. The model didn't call `list-applications(category=LEGAL)` to verify. Q18 has multiple arithmetic errors ("6 of 8 Police apps in LEGAL, 75% concentration" when the actual is 5 of 8, 62.5%; "Infrastructure & Operations dominates with 40% of IT's applications (3 of 8)" while its own bullet list shows 4 infrastructure items).

**The category tools themselves work.** The data is correct, the SQL shapes are sound, the tool descriptions are accurate, and the model picks the right tool on the right prompt 6 of 7 times on the new query set. The failures cluster around **two fixable issues**: (1) the `category-rollup` "Assessed" column misleads the model on portfolio assessment state (one Q9 regression + one Q12 quality ding), and (2) cross-tool synthesis guessing at category membership instead of verifying (one Q17 wrong answer + one Q18 shallow answer with arithmetic errors).

**Recommendation: ITERATE on a small Batch 3 fix before merging.** The Q9 regression would ship a confidently wrong answer to the exact question an EA asks before a portfolio review (*"what data am I missing?"*). The fix is ~5 lines in `tools.ts` (tighten the `assessed_count` predicate to match `portfolio-summary`'s definition) plus a ~15-line prompt addition guarding cross-tool category synthesis. Session 4 scope is small. Full merge recommendation with fix proposals is in the final section.

---

## Deviation from the brief

The session brief in `03-session-prompt-category-eval.md` stated: *"This branch is `feat/ai-chat-category-tools` from `dev`, which does not have the Batch 2 changes from `feat/ai-chat-harness-eval`. So the regression baseline is the Batch 1 verdict, not a hypothetical post-Batch-2 state."*

This assumption is **wrong about the branch topology**. The Batch 2 harness-optimization work was merged to `dev` in commit `b17075a` before Session 2 ran, and `feat/ai-chat-category-tools` was branched from `dev` after that merge. `git log` on `feat/ai-chat-category-tools` shows all five Batch-2-era commits (`b17075a`, `2fd5393`, `3df564c`, `25c7a6d`, `473be25`) in the history, and the current `system-prompt.ts` on this branch contains the Batch 2 prompt additions (rationalization-direction rule at §Tool selection rules → Rationalization and consolidation, temporal-refusal rule, data-classification refusal rule).

**The correct regression baseline is Batch 2's 10/10 acceptable state, not Batch 1's 6/10.** This is the baseline this report uses. The scoring below treats any query with a Batch-2-post-fix verdict as the reference — a Q1/Q4/Q9 regression here means a drop from Batch 2 GOOD, not a persistence of Batch 1 SHALLOW.

---

## Method

1. Two fresh AI Chat conversations opened on Riverside namespace with a namespace-admin user after Stuart deployed `feat/ai-chat-category-tools` to the dev Edge Function. Conversation titles: *"Eval Categories 2026-04-11 A"* and *"Eval Categories 2026-04-11 B"*.
2. Conversation A: 9 regression queries (Q1–Q6, Q7=drop Hexagon, Q8=PII, Q9=data missing — using this eval's renumbering where Batch 1's Q7 moves to Conv B) followed by 5 new category queries (Q10–Q14). 14 scoring entries total.
3. Conversation B: Q7 Turn 1 (list Finance workspace apps) + Q7 Turn 2 (which have budget data) + Q17 (cross-tool #1 — which category carries most tech debt) + Q18 (cross-tool #2 — most sprawl and over-represented categories). 4 scoring entries total.
4. Full message history (including `tool_input` and `tool_output` JSONB) pulled from `ai_chat_messages` via `DATABASE_READONLY_URL` and dumped to `/tmp/conv-a-categories.txt` and `/tmp/conv-b-categories.txt`. Category assignments ground-truthed via direct SELECT on `application_category_assignments` to verify the cross-tool answers.
5. Each query scored against the same ideal-response rubric used in Batches 0/1/2. Scoring rubric held constant; verdicts not rescaled.
6. Each regression query compared directly against its Batch 2 verdict. Trace evidence cited for the single regression. Each new query scored on its own merits against an EA-reliability bar (*"would an EA act on this without cross-checking?"*).
7. Tool-by-tool and cross-tool effectiveness assessed by reading the tool-call sequences and confirming each targeted behavior.

**Note on Conversation A sequencing:** Stuart pasted the conversation title *"Eval Categories 2026-04-11 A"* as the first user message. The model interpreted this as a prompt and autonomously called `list-application-categories` + `category-rollup` at SEQ 2 and SEQ 3, producing an unsolicited portfolio overview at SEQ 4. Same pattern in Conv B (SEQ 2, 3, 4). This is the model being over-eager, not a bug in the eval setup. But the pre-loaded context matters: the unsolicited `category-rollup` output at SEQ 3 exposed the model to the "Assessed: 11/11" framing for every category, which later bled into Q9's wrong answer. **Note the session-poisoning side effect:** conversations that begin with a short title are vulnerable to the model treating the title as a prompt and pre-loading context with whichever tool output it chose. Future evals should either start with an explicit "Ready" ack or avoid short titles entirely.

**Query total:** 14 entries in Conv A + 4 entries in Conv B = **18 scoring entries** across **15 distinct prompts** (Q7 contributes two turns). The session brief stated "17 scoring entries" but this appears to be a miscount — the full entry set is 18 by the same math Batches 0/1/2 used.

---

## Per-query scoring

### ✅ Q1 — CAD vs Hexagon rationalization | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)`, `application-detail(Hexagon OnCall CAD/RMS)` (2 calls)

**Response quality:** Leads with *"Rationalize TO Computer-Aided Dispatch"* and cites the Batch 2 rationalization-direction rule verbatim — higher tech health (48.75 vs 32), lower remediation effort (L vs XL), mainstream vs extended lifecycle, assigned owner (Pat Alvarez) vs unassigned. Closes with the exact negative-example reasoning: *"Hexagon's extended lifecycle status and XL remediation effort make it a poor long-term consolidation target, regardless of its broader functional scope. You'd need to migrate off it eventually anyway."*

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED** — Batch 2 rationalization rule continues to hold on this branch

**Verdict:** ✅ GOOD.

---

### ✅ Q2 — Rank crown jewels by risk | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"Which of my crown jewel applications are at highest risk? Rank them."*

**Tools called:** `technology-risk(limit=50)` (1 call — slightly more efficient than Batch 2's 2-call pattern which also called `list-applications(criticality_min=50)` as a double-check)

**Response quality:** Ranks all 4 scored crown jewels correctly (Hexagon 67.3, Police Records Management 61.2, CAD 48.7, NG911 44.9) and observes *"All four crown jewel applications are flagged for Address or Plan actions, indicating they need active management."* The model correctly skipped calling `list-applications(criticality_min=50)` because the `technology-risk` output with `limit=50` already includes the full ranked list — the top 5 rows cover all crown jewels. Axon Evidence (risk 10.5) was omitted from the narrative summary (model only named top 4), but the observation that the top 2 (Hexagon, PRM) are severe risks is correct.

**Minor caveat:** The response only names 4 of the 5 crown jewels. Axon Evidence was ranked #8 in the tool output (risk 10.5) and the model should have acknowledged it as the 5th crown jewel with "low risk — well maintained." This is a mild completeness ding, not a verdict drop.

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED** (one fewer tool call, slightly less complete summary)

**Verdict:** ✅ GOOD.

---

### ✅ Q3 — CAD retirement blast radius | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?"*

**Tools called:** `application-detail(Computer-Aided Dispatch)` (1 call)

**Response quality:** All three integrations correctly identified from the expanded `application-detail` tool output — Hexagon OnCall CAD/RMS (bidirectional), Emergency Response System (bidirectional, DP-aligned), NG911 System (downstream, DP-aligned). The response lists the cascade effects (call routing failure, emergency coordination breakdown, Hexagon isolation) and closes with a clear recommendation: *"ensure all three integrations are re-established with the remaining CAD system to maintain operational continuity."*

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q4 — Tech debt trend over 6 months | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?"*

**Tools called:** **NONE** (zero tool calls — clean graceful failure)

**Response quality:** *"I don't have historical data to show tech debt trends over time. The portfolio model contains current-state assessments only, without time-series snapshots to track changes over the past 6 months."* Offers a useful current-state alternative. The Batch 2 temporal-refusal rule is holding cleanly on this branch — the model did not call `portfolio-summary` defensively.

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q5 — Top risk in Police Department | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"What's the top risk in the Police Department workspace right now?"*

**Tools called:** `technology-risk(workspace_name="Police Department", limit=1)` (1 call)

**Response quality:** Direct single-tool call with the workspace pre-named (no `list-workspaces` preamble). Returns Hexagon OnCall CAD/RMS at risk score 67.3 with the four contributing dimensions (criticality 99, tech_health 32, PAID Address, extended lifecycle). The summary sentence captures the key insight: *"a system that's essential for emergency dispatch operations but has significant technical vulnerabilities that need immediate attention."*

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q6 — Police Department SWOT | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective."*

**Tools called:** `portfolio-summary`, `cost-analysis(focus=overview, workspace_name="Police Department")`, `technology-risk(workspace_name="Police Department", limit=10)`, `list-applications(workspace_name="Police Department", criticality_min=50)`, `application-detail(NG911 System)`, `application-detail(Axon Evidence)` (6 tool calls — consistent with the worked-example orchestration in the system prompt)

**Response quality:** Comprehensive SWOT with multiple items per quadrant and a Strategic Recommendation closer. The **Opportunities section correctly does NOT prescribe Hexagon as the consolidation target** — it says *"CAD consolidation potential: Two overlapping dispatch systems present opportunity to eliminate $121K-$230K in annual costs while reducing complexity."* This is the rationalization-direction rule propagating into the multi-tool orchestration path, same as Batch 2.

Strengths: 5 crown jewels, $903.9K annual investment, complete assessment coverage, strong vendor partnerships, budget discipline. Weaknesses: top 2 risk apps (Hexagon 32, PRM 17.25), 3 of 5 crown jewels flagged Address, ownership gaps on NG911 and Axon Evidence. Opportunities: rationalization, vendor optimization, cloud migration. Threats: Hexagon extended-lifecycle exposure, records management vulnerability, compliance/continuity risks.

**Note:** The response uses *"Complete assessment coverage (8/8 apps) provides full visibility into portfolio health"* for the Police Department subset, which is correct (the `technology-risk` workspace filter returned 8 scored apps from Police). This is different from the portfolio-wide "100% assessed" claim in Q9 — here the number is scoped correctly to the workspace.

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q7 — Drop Hexagon as a vendor entirely | GOOD (UNCHANGED from Batch 2, different tool pattern)

**Prompt:** *"If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?"*

**Tools called:** `cost-analysis(focus=overview, workspace_name="Police Department")` (1 call — Batch 2 used 2 calls with `focus=vendor` + `focus=run_rate`, but `focus=overview` returns both sections in a single call so the single-call pattern is equivalent)

**Response quality:** The model correctly sums both sides of the Hexagon cost: *"Annual Savings: $230.6K — Cost bundles: $110.0K (direct Hexagon vendor spend), IT services allocation: $120.5K (infrastructure supporting the system), Total elimination: $230.6K annual run rate."* This matches Batch 2's answer exactly. The Vendor cost completeness rule (*"sum BOTH sides"*) lands the same way whether the model uses two `focus=vendor/focus=run_rate` calls or one `focus=overview` call.

Integration impact correctly lists the 3 broken integrations (CAD bidirectional, Emergency Response, NG911). Migration requirements correctly enumerated (scale CAD, re-establish integrations, staff transition, data migration). The response closes with the vendor-attribution disclaimer: *"However, vendor attribution on IT services shows some gaps, so actual vendor-related savings could be slightly higher."*

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED** (one-call pattern instead of two-call, same synthesized answer)

**Verdict:** ✅ GOOD.

---

### ✅ Q8 — PII applications | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"Which applications in our portfolio handle PII and what's their assessment status?"*

**Tools called:** **NONE** (zero tool calls — clean refusal)

**Response quality:** *"I cannot provide data classification information about which applications handle PII. Data classification and compliance scope (including PII, PHI, GDPR, HIPAA, or SOX) are not currently tracked in the portfolio model. Inferring PII handling from application names alone would be unreliable — for example, a system named 'Police Records Management' might or might not store PII in the way you're defining it for compliance purposes."* Then pivots to four useful alternatives (assessment status, ownership, lifecycle, criticality).

The Batch 2 data-classification refusal rule is holding cleanly on this branch. The model did not fall back to name-inference (the Batch 1 failure mode) or call any tool defensively.

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### 🔴 Q9 — Data missing for portfolio review | WRONG ANSWER (REGRESSED from GOOD in Batch 2)

**Prompt:** *"What data am I missing to run a proper portfolio review next week?"*

**Tools called:** `data-quality()` (1 call — stubbed, returned "coming soon")

**Response quality:** The model correctly noted the `data-quality` stub and pivoted to building the answer from observable data. But **the "observable data" it used was poisoned.** The response opens with:

> *"**Strong Foundation**
> - **100% assessment coverage** across all 32 applications
> - **Complete criticality scoring** (all apps have business fit scores)
> - **Full technical health data** (all apps have tech health scores)
> - **Clear PAID actions** assigned to every application"*

**This is factually wrong.** Riverside has **17% assessed (5 of 32 apps with real scores per Q2 evidence; 8 of 48 deployment profiles per `portfolio-summary`).** 24 apps show `criticality=0 | tech_health=0 | PAID=—` in every other tool output this session (visible at SEQ 10 in the `technology-risk(limit=50)` output where ranks 9-32 are all 0/0/—). An EA reading this answer would walk into a portfolio review believing their assessment is complete when it isn't, and that is exactly the class of confidently-wrong answer Batch 2 was supposed to eliminate.

**Root cause — category-rollup semantic bug:** The model's "100% assessment coverage" claim traces back to the unsolicited `category-rollup` call at SEQ 3 (triggered by Stuart pasting the conversation title as the first message). The `category-rollup` output showed *"Records & Document Mgmt: 11 apps / 11 assessed"*, *"CRM & Citizen Services: 10 apps / 10 assessed"*, etc. — every category reporting 100% assessed. The model interpreted this as "100% assessment coverage" for the portfolio.

Looking at `tools.ts` line 720:

```typescript
if (m.criticality !== null && m.tech_health !== null) ru.assessed_count += 1;
```

The condition is `criticality !== null && tech_health !== null`. This counts apps with default-0 scores as "assessed" because 0 is not null. The 24 Riverside apps with `criticality=0 | tech_health=0` defaults are **counted as assessed in `category-rollup` but shown as unassessed in `portfolio-summary` and `technology-risk`.** The column name "Assessed" misrepresents what is actually "has non-null fields."

**This is a concrete tool-layer bug.** The fix is a 1-line predicate change:

```typescript
// Current (wrong):
if (m.criticality !== null && m.tech_health !== null) ru.assessed_count += 1;

// Fixed:
if (m.criticality !== null && m.criticality > 0 && m.tech_health !== null && m.tech_health > 0) ru.assessed_count += 1;
```

This aligns `category-rollup`'s definition of "assessed" with `portfolio-summary`'s definition.

**Contributing factor — session context bleed:** The unsolicited `category-rollup` call at SEQ 3 was triggered by Stuart pasting the conversation title as a user message. The model interpreted the short title as a prompt and auto-called the discovery tools. The resulting category-rollup output with its "100% assessed" framing then contaminated the session context for every later query that touched assessment state. This is a failure mode specific to short-title first messages — it didn't trigger in Conv B even though Conv B has the same title pattern, because Conv B's queries didn't ask about portfolio-level assessment state.

**Comparison vs Batch 2:**
- Batch 0 verdict: 🟡 SHALLOW (re-cited fabricated "32% assessed")
- Batch 1 verdict: 🟡 SHALLOW (17%/83% grounded, but answer still vague)
- Batch 2 verdict: ✅ GOOD (17% assessed, 27 apps with no scores, 84% of portfolio missing, actionable gap list)
- This run verdict: 🔴 WRONG ANSWER (*"100% assessment coverage across all 32 applications"*)
- Change: **REGRESSED** (−2 verdict levels — the single biggest regression in this run)

**Verdict:** 🔴 WRONG ANSWER. This is the top priority for a Batch 3 iteration. The fix is a tool-layer 1-liner plus a prompt rule guarding cross-category assessment claims.

---

### ✅ Q10 — CRM capability discovery | GOOD (new query — meets EA bar)

**Prompt:** *"What applications do we have for Customer Relationship Management?"*

**Tools called:** `list-application-categories()`, `list-applications(category="CRM")` (2 calls — the prompt's "Capability and category questions" subsection prescribes exactly this discovery-then-drill pattern)

**Response quality:** Returns all 10 apps in the CRM category with a useful structural split into "Crown Jewel CRM Systems (3 apps)" and "Other CRM & Citizen Service Systems (7 apps)." Each entry has run rate and brief context. The response observes the public-safety concentration (*"3 of your 4 assessed CRM systems support police/emergency operations"*) and flags the assessment gap (*"6 of 10 CRM applications lack assessment scores"*).

The model followed the prescribed discovery pattern exactly — call `list-application-categories` first to confirm CRM is the right category, then `list-applications(category="CRM")` to drill in. This is the EA workflow the category tools were designed to support, and it works cleanly.

**Caveat:** The "$1.18M annual run rate" total is read from the earlier unsolicited `category-rollup` call at SEQ 3, not from a fresh calculation in this turn. This is a minor no-hallucinated-stats rule violation but the number is correct.

**Verdict:** ✅ GOOD. The core category-tool workflow works.

---

### ✅ Q11 — List Finance applications | GOOD (new query — meets EA bar)

**Prompt:** *"List my Finance applications."*

**Tools called:** `list-application-categories()`, `list-applications(category="FINANCE")` (2 calls — the extra `list-application-categories` call is unnecessary since the model already saw the catalog at SEQ 2 and Q10's SEQ 37, but it's harmless)

**Response quality:** Returns all 5 apps in FINANCE category: Cayenta Financials, Microsoft Dynamics GP, Questica Budget, Sage 300 GL, and **Workday HCM** (workspace: Human Resources). The last entry might surprise an EA who expected only Finance-workspace apps, but it's correct — Workday HCM is tagged with both FINANCE and HR categories in the database (verified via `application_category_assignments` SELECT), because Workday handles both payroll (finance) and HR. The category filter works correctly, and the response correctly annotates Workday's workspace: *"Workday HCM - $95.0K (HR/Finance hybrid system)."*

The response also observes the total cost ($909.4K), the assessment gap (all 5 apps unassessed), and offers a thoughtful rationalization hook (*"Multiple overlapping systems (Dynamics GP, Sage GL) suggest potential rationalization opportunities"*).

**Caveat:** The extra `list-application-categories` call was wasteful — Q11 could have gone directly to `list-applications(category="FINANCE")` since the model already had the catalog in context from the earlier calls. Minor efficiency ding, not a verdict drop.

**Verdict:** ✅ GOOD. The category filter on `list-applications` works, correctly includes multi-category apps, and the EA explanation is substantive.

---

### 🟡 Q12 — Portfolio by capability | SHALLOW (new query — category data correct, framing misleading)

**Prompt:** *"Show me my portfolio by capability."*

**Tools called:** `category-rollup()` (1 call — exactly the tool the prompt's "Capability and category questions" subsection prescribes for this type of question)

**Response quality:** The category-rollup data is reported correctly — all 12 categories with apps, in descending-app-count order, with run rates and crown jewel counts. The top investment areas are named correctly (CRM $1.18M, RECORDS $1.16M, FINANCE $909K). The crown jewel distribution observation (*"75% concentration: 9 of your 11 crown jewels are in just 3 categories"*) is correct.

**The failure mode is the same as Q9.** The response adds this framing:

> *"**Assessment Coverage**
> - **100% assessed** across all categories - excellent portfolio visibility"*

This is factually wrong by the same category-rollup semantic bug: the tool's "Assessed" column reports apps with non-null fields, which includes default-0 scores. Real portfolio assessment is 17%, not 100%. An EA reading *"excellent portfolio visibility"* here would believe their data is complete when it isn't.

The core category breakdown is useful. The assessment-coverage claim is misleading and not caveated. If the user's only question is "which category has the most apps," they'd get a correct answer. If they want to know "how mature is my portfolio," they'd get the wrong answer.

**Verdict:** 🟡 SHALLOW. The category-rollup data layer works, but the model's faithful reporting of the misleading "Assessed" column drives a quality regression.

---

### 🟡 Q13 — Categories with no crown jewels | SHALLOW (new query — off-by-one counting)

**Prompt:** *"Which categories have no crown jewels assigned?"*

**Tools called:** `category-rollup()` (1 call)

**Response quality:** Correctly identifies the categories with zero crown jewels from the category-rollup output: FINANCE, ERP, COLLABORATION, HR, ANALYTICS, INFRASTRUCTURE, SECURITY = **7 categories**. The model's structured list is correct and useful (High-Investment: 4 categories; Lower-Investment: 3 categories; total = 7).

**The failure mode is the summary count.** The response opens with *"**6 capability categories** have no crown jewel applications assigned"* and then lists 7 items. Off-by-one error in the intro — the list below it is complete and correct.

The insight ("$2.3M in annual spend across these categories lacks crown jewel designation, particularly concerning for Finance ($909K) and ERP ($580K) systems") is substantive and useful. An EA would catch the 6-vs-7 discrepancy on first read and lose slight confidence, but would still get the right list.

**Verdict:** 🟡 SHALLOW. Data layer and structural answer correct; summary count wrong. Minor quality ding, not a wrong-answer failure.

---

### ✅ Q14 — Citizen service requests | GOOD (new query — semantic match works)

**Prompt:** *"What do I have to manage citizen service requests?"*

**Tools called:** `list-applications(category="CRM")`, `application-detail(SeeClickFix)`, `application-detail(Accela Civic Platform)`, `application-detail(CivicPlus Website)` (4 calls)

**Response quality:** The model correctly interpreted "citizen service requests" as a semantic subset of CRM & Citizen Services, called `list-applications(category="CRM")` to get the full CRM list (10 apps), then selected the 3 citizen-facing apps (SeeClickFix, Accela Civic Platform, CivicPlus Website) and drilled into each with `application-detail`. The response lists each with its purpose, hosting model, assessment status, and run rate, then identifies a "Critical Gap: All Systems Unassessed" with the $154K combined investment figure.

The semantic filter (picking 3 of 10 CRM apps as "citizen service request" tools) is a judgment call. SeeClickFix is the canonical citizen-reporting tool, Accela handles permit requests, CivicPlus handles website-based engagement — all three are defensible. The model excluded Emergency Response System, CopLogic Online Reporting, and the CAD/RMS/NG911 trio, which is also defensible (those are emergency-response, not general-purpose citizen service requests).

**Caveat:** The model could have included SirsiDynix Symphony (library — a form of citizen service) or CopLogic (police online reporting — a form of citizen request channel). The narrower interpretation is defensible but an EA might want a broader view. Not enough to drop the verdict.

**Verdict:** ✅ GOOD. The category tools enabled a useful semantic-filter workflow, and the application-detail drill-down supplied substantive per-app context.

---

### ✅ Q15 — Q7 Turn 1 — List Finance workspace apps | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"List the applications in the Finance workspace."*

**Tools called:** `list-applications(workspace_name="Finance")` (1 call — direct workspace call, no `list-workspaces` preamble)

**Response quality:** Lists all 4 Finance workspace apps with run rates (Microsoft Dynamics GP $549K, Cayenta Financials $148.5K, Sage 300 GL $65.5K, Questica Budget $51.4K). Combined run rate correctly computed ($814K). Dynamics GP's 67% workspace-spend share noted correctly. Assessment gap annotated inline (*"All applications are currently unassessed"*).

Note: This is the **workspace** filter (Q15 asks for Finance workspace), which is different from Q11's **category** filter (which also included Workday HCM from the HR workspace). The two tools behave correctly when given different filter types.

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### ✅ Q16 — Q7 Turn 2 — Which have budget data | GOOD (UNCHANGED from Batch 2)

**Prompt:** *"Which of those have budget data?"*

**Tools called:** `cost-analysis(focus="budget", workspace_name="Finance")` (1 call)

**Response quality:** Multi-turn memory test — the model correctly carried "those" forward from Turn 1's Finance workspace list and looked up budget data for all 4 apps. Tool returned *"4 of 4 total"* with no over-budget flags. Response lists each app by name with individual "budget status tracked" annotation, preserving Turn 1 continuity: *"None are currently over budget, indicating good financial controls within the Finance workspace."*

**Comparison vs Batch 2:**
- Batch 2 verdict: ✅ GOOD
- This run verdict: ✅ GOOD
- Change: **UNCHANGED**

**Verdict:** ✅ GOOD.

---

### 🔴 Q17 — Cross-tool #1: Which category carries the most technical debt | WRONG ANSWER (new query — synthesis failure)

**Prompt:** *"Which application category carries the most technical debt?"*

**Tools called:** `category-rollup()`, `technology-risk(limit=20)` (2 calls — the cross-tool orchestration pattern fired as prescribed by the prompt's "Cross-tool orchestration" note)

**Response quality:** The model confidently answers:

> *"**Legal & Regulatory** carries the most technical debt, with **3 of the top 5 highest-risk applications** in the portfolio:
> 1. **Hexagon OnCall CAD/RMS** — 99 criticality, 32 tech health (Risk Score: 67.3)
> 2. **Police Records Management** — 74 criticality, 17 tech health (Risk Score: 61.2)
> 3. **Computer-Aided Dispatch** — 95 criticality, 49 tech health (Risk Score: 48.7)
>
> These three Legal & Regulatory applications represent crown jewels with severe technical health deficits..."*

**This is wrong on the ground truth.** Verified via direct SELECT on `application_category_assignments`:

| App | Actual categories | Model claimed |
|---|---|---|
| Hexagon OnCall CAD/RMS | `CRM`, `LEGAL`, `RECORDS` | LEGAL ✓ (but also CRM + RECORDS) |
| Police Records Management | `LEGAL`, `RECORDS` | LEGAL ✓ (but also RECORDS) |
| **Computer-Aided Dispatch** | **`CRM`, `GIS_SPATIAL`** | **LEGAL ✗** |
| NG911 System | `CRM`, `HEALTH` | (not mentioned) |
| Axon Evidence | `LEGAL`, `RECORDS` | (not mentioned) |

**Computer-Aided Dispatch is not in the LEGAL category.** It's in CRM and GIS_SPATIAL. The model assigned it to LEGAL because it saw the `category-rollup` output showing "LEGAL: 7 apps, 3 crown jewels" and inferred that the top-3 risk apps must be those 3 LEGAL crown jewels. But the 3 LEGAL crown jewels are actually Hexagon, Police Records Management, and **Axon Evidence** (risk 10.5 — low) — not CAD.

**By sum of top risk scores per category, CRM carries more technical debt than LEGAL:**

| Category | Crown jewels in top 10 risk | Sum of risk scores |
|---|---|---|
| **CRM** | Hexagon (67.3), CAD (48.7), NG911 (44.9) | **160.9** |
| LEGAL | Hexagon (67.3), PRM (61.2), Axon (10.5) | 139.0 |
| RECORDS | Hexagon (67.3), PRM (61.2), Axon (10.5) | 139.0 |

The directionally correct answer is **CRM** (or "CRM and RECORDS/LEGAL tied with Hexagon as the dominant contributor"). The model picked LEGAL based on a guess.

**Root cause — cross-tool synthesis gap:** The model called `category-rollup` and `technology-risk` correctly but did not call `list-applications(category=X)` on any category to verify which apps belong to which category. The system prompt's cross-tool subheading says *"category-rollup composes well with other tools"* and gives two examples, but does not require verifying category membership. The model filled the gap with inference — *"LEGAL has 3 crown jewels AND the top 3 risk apps are crown jewels, therefore those 3 must be the LEGAL crown jewels."* This reasoning is invalid because apps can belong to multiple categories (the same rule that makes the category sums exceed the unique app count — which the model acknowledged in its own description of the tool).

**Proposed fix — prompt addition under "Cross-tool orchestration":**

> When a cross-tool answer requires knowing WHICH apps belong to WHICH category, always call `list-applications(category=X)` for each relevant category before asserting category membership. Do not infer category from app names, crown-jewel counts, or by counting how many of the top-risk apps "must" belong to a category with N crown jewels. Apps can belong to multiple categories; the crown-jewel count in `category-rollup` is a per-category aggregate, not a per-app assignment.

**Verdict:** 🔴 WRONG ANSWER. The cross-tool orchestration pattern fired but the synthesis is confidently wrong on a realistic EA question, and the error propagates into the closing insight (*"3 Legal & Regulatory applications represent crown jewels with severe technical health deficits"*). This is the same class of failure as Batch 1's Q1 — polished markdown, wrong conclusion, actionable-looking.

---

### 🟡 Q18 — Cross-tool #2: Most sprawl and over-represented categories | SHALLOW (new query — arithmetic errors)

**Prompt:** *"Which workspace has the most application sprawl, and what categories are over-represented there?"*

**Tools called:** `list-workspaces()`, `list-applications(workspace_name="Information Technology")`, `list-applications(workspace_name="Police Department")`, `category-rollup()` (4 calls — the cross-tool orchestration pattern definitely fired, with the right tool selection)

**Response quality — directional conclusion correct, specific numbers wrong.** The model correctly identified that Information Technology and Police Department are tied for the most application sprawl (8 apps each) using `list-workspaces`. It then correctly called `list-applications` for each of those workspaces to get the app lists, and called `category-rollup` to get the portfolio-wide category distribution.

**But the synthesis contains multiple arithmetic errors**, verified against ground truth from direct SELECT on `application_category_assignments`:

**Ground truth — Police Department category distribution (8 apps):**

| App | Categories | In LEGAL? | In CRM? | In RECORDS? |
|---|---|---|---|---|
| Hexagon OnCall CAD/RMS | CRM, LEGAL, RECORDS | ✓ | ✓ | ✓ |
| Computer-Aided Dispatch | CRM, GIS_SPATIAL | ✗ | ✓ | ✗ |
| NG911 System | CRM, HEALTH | ✗ | ✓ | ✗ |
| Police Records Management | LEGAL, RECORDS | ✓ | ✗ | ✓ |
| Axon Evidence | LEGAL, RECORDS | ✓ | ✗ | ✓ |
| Flock Safety LPR | LEGAL | ✓ | ✗ | ✗ |
| CopLogic Online Reporting | CRM, RECORDS | ✗ | ✓ | ✓ |
| Brazos eCitation | LEGAL | ✓ | ✗ | ✗ |
| **Police in LEGAL** | | **5 of 8 (62.5%)** | | |
| **Police in CRM** | | | **4 of 8 (50%)** | |
| **Police in RECORDS** | | | | **4 of 8 (50%)** |

**Model claimed:**
- *"Legal & Regulatory: 6 of 8 applications (75% concentration)"* — wrong (actual is 5 of 8, 62.5%)
- *"CRM & Citizen Services: 3 applications"* — wrong (actual is 4 of 8)
- *"Records & Document Management: 2 applications"* — wrong (actual is 4 of 8)

**Ground truth — Information Technology category distribution (8 apps):**

| App | Categories |
|---|---|
| Active Directory Services | INFRASTRUCTURE, SECURITY |
| Esri ArcGIS Enterprise | GIS_SPATIAL |
| Hyland OnBase | RECORDS |
| Microsoft 365 | COLLABORATION, RECORDS |
| PRTG Network Monitor | INFRASTRUCTURE |
| ServiceDesk Plus | INFRASTRUCTURE |
| ServiceNow ITSM | INFRASTRUCTURE |
| SirsiDynix Symphony | CRM, RECORDS |
| **IT in INFRASTRUCTURE** | **4 of 8 (50%)** |

**Model claimed:** *"Infrastructure & Operations dominates with 40% of IT's applications (3 of 8)"* — wrong twice. It's 4 of 8 (50%), not 3 of 8 (40%). The model's own bullet list even names 4 infrastructure items (AD, PRTG, ServiceDesk, ServiceNow) but then the summary says "3 of 8." Internal inconsistency.

**Why the synthesis is wrong despite correct tool calls:** The model called `list-applications(workspace_name="Information Technology")` and `list-applications(workspace_name="Police Department")` correctly to get the app lists, and called `category-rollup` to get the portfolio category distribution. But **it did not call `list-applications(category=X)` for any category to get the list of apps in each category.** Instead, it inferred category membership from **app names** — "Active Directory Services → Infrastructure" by string match, "Hexagon OnCall CAD/RMS → Legal & Regulatory" by guess. This is the same synthesis failure mode as Q17.

**Directional conclusion:** The model correctly named Police and IT as tied for most sprawl at 8 apps each, correctly identified that LEGAL is over-represented in Police Department (even though the percentage was wrong), and correctly identified that INFRASTRUCTURE is the dominant category in IT (even though the count was wrong). The narrative insights (*"Police Department's sprawl is more problematic than IT's because it contains 5 crown jewels with significant technical debt"*) are correct and useful.

**Verdict:** 🟡 SHALLOW. The cross-tool orchestration pattern fired with the right tool selection, the directional conclusion is correct, but multiple arithmetic errors in the category counts erode trust. Same root cause as Q17 (inferred category membership, didn't verify with `list-applications(category=X)`).

---

## Regression scorecard (11 entries)

| # | Query | Batch 2 | This run | Change |
|---|---|---|---|---|
| 1 | CAD vs Hexagon rationalization | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 2 | Rank crown jewels by risk | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 3 | CAD retirement blast radius | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 4 | Tech debt trend 6mo | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 5 | Top risk in Police | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 6 | Police SWOT | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 7 | Drop Hexagon vendor | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 8 | PII applications | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 9 | Data completeness | ✅ GOOD | 🔴 WRONG | ⬇ **REGRESSED** |
| 15 | Q7 Turn 1 — List Finance workspace | ✅ GOOD | ✅ GOOD | ↔ unchanged |
| 16 | Q7 Turn 2 — Which have budget data | ✅ GOOD | ✅ GOOD | ↔ unchanged |

**Regression count: 1 of 11** (Q9 — data missing for portfolio review)
**Regression root cause:** `category-rollup` tool's `assessed_count` predicate uses `!== null` instead of `> 0`, reporting default-0 apps as "assessed." The model faithfully propagated this into Q9's answer (*"100% assessment coverage across all 32 applications"*), plus a contributing session-poisoning effect from the title-paste auto-triggering `category-rollup` at the start of the conversation.

---

## New query scorecard (7 entries)

| # | Query | Verdict | Tools used | Notes |
|---|---|---|---|---|
| 10 | CRM capability discovery | ✅ GOOD | list-application-categories, list-applications(category=CRM) | Discovery-then-drill pattern, all 10 CRM apps named with crown jewel split |
| 11 | List Finance applications | ✅ GOOD | list-application-categories, list-applications(category=FINANCE) | All 5 FINANCE apps including multi-category Workday HCM |
| 12 | Portfolio by capability | 🟡 SHALLOW | category-rollup | Breakdown correct; *"100% assessed across all categories"* is factually wrong (same category-rollup bug as Q9) |
| 13 | Categories with no crown jewels | 🟡 SHALLOW | category-rollup | Correct list of 7 categories; intro says "6" (off-by-one counting error) |
| 14 | Citizen service requests | ✅ GOOD | list-applications(category=CRM), application-detail × 3 | Semantic filter on CRM category, 3 citizen-facing apps drilled |
| 17 | Which category carries most tech debt (cross-tool) | 🔴 WRONG | category-rollup, technology-risk | Cross-tool pattern fired but synthesis wrong — CAD is not in LEGAL |
| 18 | Most sprawl + over-represented (cross-tool) | 🟡 SHALLOW | list-workspaces, list-applications × 2, category-rollup | Cross-tool pattern fired; directional conclusion correct; multiple arithmetic/count errors |

**GOOD count: 3 of 7** (Q10, Q11, Q14)
**SHALLOW count: 3 of 7** (Q12, Q13, Q18)
**WRONG count: 1 of 7** (Q17)
**Acceptable rate (GOOD or graceful failure): 3 / 7 = 43%**

---

## Aggregate metrics

| Metric | Batch 2 | This run | Delta |
|---|---|---|---|
| Acceptable-answer rate on regression set | 10/10 (100%) | 10/11 (91%) | −9 pp (1 regression) |
| Wrong answers on regression set | 0 | 1 (Q9) | +1 |
| Shallow on regression set | 0 | 0 | — |
| New-query acceptable rate | — | 3/7 (43%) | — |
| New-query wrong answers | — | 1 (Q17) | — |
| New-query shallow | — | 3 (Q12, Q13, Q18) | — |
| Total scoring entries | 11 | 18 | +7 |
| Overall GOOD count | 11/11 | 13/18 | — |
| Overall acceptable rate | 100% | 72% | — |

---

## Tool-by-tool effectiveness

### ✅ `list-application-categories` | LANDED EFFECTIVELY

**Evidence of working:**
- Auto-called at Conv A SEQ 2 and Conv B SEQ 2 (title-paste responses)
- Q10 (SEQ 37): called as the discovery step before `list-applications(category=CRM)`, exactly per the prompt's "Capability and category questions" subsection
- Q11 (SEQ 41): called as discovery (unnecessary — the model already had the catalog in context — but harmless)

**Tool output shape:** Markdown list with name, code, description, and current app count per category. Model parses it correctly and picks the right category code for filtering. No parse failures or misinterpretation.

**Side effects:** None observed. The tool is discoverable by name and the prompt's capability-questions subsection routes the model to it reliably.

### ✅ `list-applications` category filter | LANDED EFFECTIVELY

**Evidence of working:**
- Q10 (SEQ 38): `category="CRM"` → 10 matches (correct per database)
- Q11 (SEQ 42): `category="FINANCE"` → 5 matches including multi-category Workday HCM (correct)
- Q14 (SEQ 51): `category="CRM"` → 10 matches, used as basis for semantic-filter workflow
- Tool accepts both code (e.g., `CRM`) and name forms per the schema description

**Tool output shape:** Same as non-category `list-applications` — name, workspace, criticality, tech health, TIME, PAID, run rate per app, with the filter description in the header.

**Side effects:** None observed. The filter works correctly with multi-category apps (an app tagged with both CRM and FINANCE appears in both filters), which is the right behavior for M:M category tagging but may occasionally surprise users who expected workspace-like scoping.

### 🟡 `category-rollup` | LANDED MECHANICALLY, SEMANTIC BUG IN OUTPUT

**Evidence of working mechanically:**
- Auto-called at Conv A SEQ 3 and Conv B SEQ 3 (title-paste responses)
- Q12 (SEQ 45): called as the primary tool for "portfolio by capability" — exactly per the prompt's "Capability and category questions" subsection
- Q13 (SEQ 48): called again for "categories with no crown jewels"
- Q17 (SEQ 12): called as part of the cross-tool orchestration for tech-debt-by-category
- Q18 (SEQ 19): called as part of the cross-tool orchestration for sprawl analysis

**Tool output shape:** Markdown table with Category / Apps / Assessed / Crown Jewels / Run Rate columns, sorted by app count descending, with a footer note about M:M counting.

**Semantic bug — `assessed_count` predicate is too loose:**

```typescript
// tools.ts line 720 (current — wrong):
if (m.criticality !== null && m.tech_health !== null) ru.assessed_count += 1;
```

This counts apps with default-0 scores as "assessed." Riverside has 24 of 32 apps at `criticality=0 | tech_health=0` (visible as `— | —` in every other tool output), but `category-rollup` reports them as assessed because 0 is not null. The "Assessed" column in the tool output then misleadingly shows every category at 100% assessment when real portfolio assessment is 17%.

**Downstream effects:**
- Q9 (REGRESSED to WRONG): model cited *"100% assessment coverage across all 32 applications"* based on this tool output
- Q12 (SHALLOW): model cited *"100% assessed across all categories — excellent portfolio visibility"* based on this tool output
- Q10/Q14 (GOOD): not affected because these queries don't touch portfolio assessment state
- Q13/Q17/Q18: not affected because these queries don't reference the "assessed" column

**Proposed fix:**

```typescript
// tools.ts line 720 (fixed):
if (m.criticality !== null && m.criticality > 0 && m.tech_health !== null && m.tech_health > 0) {
  ru.assessed_count += 1;
}
```

This aligns with the definition used by `portfolio-summary` (which reports 17% assessed on the same data).

**Side effects:** The M:M counting footer is well-handled by the model (never confused by "total > unique" totals). But the "Assessed" column is a trap.

---

## Cross-tool orchestration assessment

**Did the system prompt's "Cross-tool orchestration" subheading fire?**

Yes. The prompt addition from Session 2 (*"category-rollup composes well with other tools. 'Which application category carries the most technical debt?' → call category-rollup AND technology-risk, then synthesize..."*) landed as designed at the tool-selection level:

- **Q17** called the exact tool pair named in the example: `category-rollup` + `technology-risk` (2 tools)
- **Q18** called `list-workspaces` + `list-applications × 2` + `category-rollup` (4 tools, following the second worked example in the prompt)
- Both queries demonstrate the model is willing to call multiple tools for a cross-cutting synthesis — the orchestration rule is not just decorative

**But the synthesis is wrong in both cases** because the model guessed at category membership instead of verifying it.

**Root cause — missing verification step:** The prompt's cross-tool subheading says *"category-rollup composes well with other tools"* and provides two examples. It does NOT say *"verify category membership with `list-applications(category=X)` before asserting which apps belong to which category."* Without that guardrail, the model infers category membership from:

- App names (e.g., "Active Directory Services" → INFRASTRUCTURE) — works by coincidence sometimes
- Crown-jewel counts (e.g., "LEGAL has 3 crown jewels, and the top 3 risk apps are crown jewels, so those must be the LEGAL ones") — invalid reasoning because of M:M category tagging

**Q17 evidence:** The model's answer names Hexagon + Police Records Management + Computer-Aided Dispatch as *"3 Legal & Regulatory applications."* Actual LEGAL crown jewels are Hexagon + Police Records Management + Axon Evidence. The model got the first two right by luck (Hexagon and PRM are in fact multi-tagged with LEGAL) and the third wrong (CAD is in CRM + GIS_SPATIAL, not LEGAL). The model never called `list-applications(category=LEGAL)` to verify — a single tool call that would have caught the error.

**Q18 evidence:** The model says *"Infrastructure & Operations dominates with 40% of IT's applications (3 of 8)"* — the tool-fetched IT workspace list at SEQ 17 clearly shows 4 INFRASTRUCTURE apps (AD, PRTG, ServiceDesk, ServiceNow) but the model wrote 3. The model also says *"Police Department: Legal & Regulatory 6 of 8 (75%)"* — actual is 5 of 8 (62.5%). In both cases, the model had the data in context from its own tool calls but miscounted when aggregating. The `list-applications(category=LEGAL)` verification pattern would have caught this: call the tool, get the 7 LEGAL apps, intersect with the 8 Police apps, count = 5.

**Proposed prompt fix — ~15 lines added under "Cross-tool orchestration":**

> **Verify category membership before naming apps.** When answering a question that requires knowing WHICH apps belong to WHICH category (e.g., *"which category carries the most risk"*, *"what categories are over-represented in Workspace X"*), always call `list-applications(category=X)` for each relevant category before asserting category membership. Do not infer category membership from:
>
> - **App names** ("Active Directory Services must be in INFRASTRUCTURE" — might be, might not; verify first)
> - **Crown-jewel counts from `category-rollup`** ("LEGAL has 3 crown jewels AND the top 3 risk apps are crown jewels, therefore those 3 must be the LEGAL crown jewels" — this is invalid reasoning because apps can belong to multiple categories)
>
> `category-rollup` gives you aggregate counts per category but does NOT tell you which specific apps are in each category. For that, use `list-applications(category=X)`. The two tools compose: category-rollup first to see the shape, then list-applications(category=X) to drill into a specific category, then synthesize.
>
> **Worked example — *"Which category carries the most technical debt?"*:**
>
> 1. `category-rollup()` — see which categories have crown jewels and high run rates
> 2. `technology-risk(limit=20)` — see the top risk apps by score
> 3. For each candidate category with crown jewels: `list-applications(category=X, criticality_min=50)` — get the specific crown jewels in that category
> 4. Cross-reference: which category has the most crown jewels that ALSO appear in the top-10 risk list?
> 5. Only after the cross-reference is complete, synthesize the answer naming apps in the correct category.

---

## Merge recommendation for `feat/ai-chat-category-tools`

**Recommendation: ITERATE on a small Batch 3, then merge.**

### Scoring against the brief's criteria

| Criterion | Result | Pass/Fail |
|---|---|---|
| 0 regressions on Batch 2 baseline | 1 regression (Q9 WRONG) | ❌ Fail |
| ≥5/7 new queries acceptable (GOOD or graceful failure) | 3/7 acceptable | ❌ Fail |
| Both cross-tool queries used multiple tools | 2/2 cross-tool queries used ≥2 tools | ✅ Pass |
| No cross-tool query is confidently wrong | Q17 is confidently wrong | ❌ Fail |

**Three of the four pass/fail criteria fail.** Under a strict reading, this would be a rollback recommendation. But rollback would throw away genuinely useful new capability (Q10, Q11, Q14 all work cleanly), and the failures cluster around two **concretely fixable root causes** — one tool-layer 1-line fix and one prompt addition. The ITERATE option is a small Session 4 (scoped like Batches 1 and 2) that addresses both root causes and then re-runs the eval.

### Proposed Session 4 scope

**Fix 1 — tools.ts `category-rollup` assessed_count predicate (1 line):**

```typescript
// Change line 720 from:
if (m.criticality !== null && m.tech_health !== null) ru.assessed_count += 1;

// To:
if (m.criticality !== null && m.criticality > 0 && m.tech_health !== null && m.tech_health > 0) {
  ru.assessed_count += 1;
}
```

This aligns with `portfolio-summary`'s definition of assessed. After this fix, the category-rollup output for Riverside will show non-100% assessed counts (e.g., maybe RECORDS: 11 apps / 3 assessed — because only 3 of 11 RECORDS apps have real scores). The model will then reason correctly about category assessment state in Q12 and the tool output will no longer poison Q9.

**Projected effect:**
- Q9 regression resolved → back to ✅ GOOD
- Q12 "100% assessed" framing eliminated → back to ✅ GOOD (the rest of Q12's answer is already correct)

**Fix 2 — system-prompt.ts cross-tool verification rule (~15 lines):**

Add the "Verify category membership before naming apps" subsection (see "Proposed prompt fix" in the Cross-tool orchestration section above) under the existing "Capability and category questions" subsection in `system-prompt.ts`.

**Projected effect:**
- Q17 → model calls `list-applications(category=X)` before asserting category membership → correctly identifies CRM as the category carrying the most tech debt → ✅ GOOD
- Q18 → model verifies Police/IT category memberships with `list-applications(category=X)` for each candidate → arithmetic errors eliminated → ✅ GOOD (or 🟡 SHALLOW if some counting errors persist)

**Fix 3 (optional) — better category-rollup column labeling:**

Rename the "Assessed" column in the category-rollup output to "With Scores" and add a brief inline note. This is defensive — even with Fix 1, a future EA could be confused by the column meaning if their namespace has unusual assessment patterns. Low-priority, defer unless Fix 1 doesn't fully resolve Q9/Q12.

**Projected Session 4 outcome:**
- Regression rate: 0/11 (Q9 resolved)
- New-query acceptable rate: 5/7 or 6/7 (Q17 → GOOD, Q18 → GOOD or SHALLOW, Q12 → GOOD)
- Overall acceptable rate: ~16/18 or 17/18 (≥ 90%)

This matches the merge threshold. Session 4 is estimated at ~1–2 hours elapsed (code session + Stuart deploy + 15-minute eval paste + re-eval session analogous to this one).

### Why rollback is NOT recommended

Rollback would throw away useful, working capability:
- Q10, Q11, Q14 all cleanly demonstrate the core EA workflow (*"what do I have for capability X?"*) working end-to-end
- `list-application-categories` and `list-applications(category=X)` are mechanically correct, returning correct data, correctly integrating with the existing `list-applications` tool
- The cross-tool orchestration pattern fired as designed — the model IS willing to call multiple tools when the prompt tells it to. The synthesis failures are a missing verification step, not a refusal to orchestrate.
- The single regression (Q9) traces to a 1-line tool bug, not a fundamental problem with the category tools

### Why merging now is NOT recommended

Merging would ship a confidently wrong answer on *"what data am I missing to run a proper portfolio review next week?"* — exactly the type of question an EA asks before a portfolio review. The Q9 answer (*"100% assessment coverage across all 32 applications"*) would walk an EA into a review with a false sense of data completeness, and the failure is silent (no error, no caveat, just wrong). This is the class of failure Batch 1→Batch 2 explicitly fixed and it would be a visible regression for users who already saw Batch 2's clean Q9 answer. The 1-line fix is too easy to skip.

---

## Decision point for Stuart

**Recommended path:**

1. **Do NOT merge `feat/ai-chat-category-tools` to `dev` yet.**
2. **Open a Session 4** using this doc as context. Scope:
   - Fix `tools.ts` line 720 (1-line predicate change for `category-rollup.assessed_count`)
   - Add cross-tool verification rule to `system-prompt.ts` (~15 lines under "Capability and category questions → Cross-tool orchestration")
   - Optionally rename the "Assessed" column to "With Scores" with inline note (defensive)
3. **Stuart deploys** the Session 4 changes via `supabase functions deploy ai-chat` from the `feat/ai-chat-category-tools` branch.
4. **Stuart re-runs the 18 queries** (or at minimum Q9, Q12, Q13, Q17, Q18 — the 5 problematic entries) into two new conversations.
5. **Session 5** (re-eval analogous to this one) produces `11-eval-results-category-tools-post-fix.md` with the comparison.
6. If Session 5 achieves ≥16/18 acceptable with 0 regressions on the Batch 2 baseline, merge to `dev`.

**Alternative path — merge as-is and file follow-ups:**

If Stuart's appetite is to ship capability now and iterate later:
1. Merge `feat/ai-chat-category-tools` to `dev` now.
2. File two follow-up tickets:
   - T1: Fix `category-rollup.assessed_count` predicate (tool bug)
   - T2: Add cross-tool category-membership verification rule (prompt gap)
3. Accept that Q9 and the 3 shallow/wrong new queries are production bugs until T1 and T2 ship.

This alternative is **not recommended** but is internally consistent if Stuart prioritizes shipping velocity over answer quality on the specific queries that fail.

**Recommended: iterate.** The fix is small, the path is well-defined, and the resulting harness would be the first category-aware AI Chat on a 16/18+ baseline — the kind of floor that Batch 2 established and that Stuart has said is the bar for user-visible features.

---

## References

- **Baselines:**
  - `../ai-chat-harness-optimization/20-eval-results-batch-2.md` — Batch 2 regression baseline (10/10 acceptable, the state this run is compared against)
  - `../ai-chat-harness-optimization/10-eval-results-batch-1.md` — Batch 1 (6/10 acceptable, superseded)
  - `../ai-chat-harness-optimization/00-eval-results-batch-0.md` — Batch 0 (2/10 acceptable, superseded)
- **Session prompts:**
  - `01-session-prompt-riverside-category-data.md` (Session 1 — data enrichment, executed 2026-04-11)
  - `02-session-prompt-ai-chat-category-tools.md` (Session 2 — Edge Function tools, executed 2026-04-11)
  - `03-session-prompt-category-eval.md` (Session 3 — this eval)
- **Edge Function commit evaluated:** `30b08ec` on `feat/ai-chat-category-tools`
- **Conversation IDs:**
  - A = `80ddd76e-ea00-4c30-860b-1d2f08062283` (Eval Categories 2026-04-11 A)
  - B = `e7531577-2e78-4717-a04a-169dbe0072f4` (Eval Categories 2026-04-11 B)
- **Raw trace dumps (ephemeral):** `/tmp/conv-a-categories.txt` (543 lines), `/tmp/conv-b-categories.txt` (156 lines). Regenerate by querying `ai_chat_messages` with the IDs above.
- **Ground-truth category assignments** (used to evaluate Q17 and Q18): verified via direct SELECT on `application_category_assignments` for Police Department and Information Technology apps plus LEGAL/CRM/RECORDS categories.
- **Category-rollup tool source:** `supabase/functions/ai-chat/tools.ts` lines 641–742 (executeCategoryRollup) — the `assessed_count` predicate bug is at line 720.
- **System prompt source:** `supabase/functions/ai-chat/system-prompt.ts` — the "Capability and category questions" subsection is around lines 126–137, cross-tool orchestration note at line 136.
- **Auto-memory:** `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md` + new entry in `MEMORY.md` for this initiative.

*End of category tools eval results.*
