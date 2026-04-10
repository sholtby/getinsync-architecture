# AI Chat Harness Evaluation — What I Need From Stuart

> **Purpose:** Step-by-step instructions for running the 10 eval queries that feed the Meta-Harness Option B audit of the GetInSync NextGen AI Chat.
>
> **Context:** This evaluation is the input to a ranked gap list that will drive targeted fixes to `supabase/functions/ai-chat/`. See the Meta-Harness paper (Lee et al., arXiv 2603.28052) for the research method; we are running the pragmatic manual version of it.
>
> **Related docs:**
> - `~/.claude/projects/-Users-stuartholtby-Dev-getinsync-nextgen-ag/memory/ai-chat-harness-optimization.md` — full project context and history
> - `planning/phase-0-assets/enrichment-session-prompt.md` — the Phase 0 demo enrichment that this eval depends on
> - `planning/gitbook-phase-0-readiness.md` — source for the enrichment gaps Phase 0 addressed

---

## Background — why we are doing this

GetInSync NextGen's AI Chat is a Supabase Edge Function that wraps Claude Sonnet 4 with 7 tools and a custom system prompt. The Stanford Meta-Harness paper shows that the **harness** — the code that decides what to store, retrieve, and show the model — can produce up to a 6× performance gap on the same benchmark without changing the model.

Stuart's hypothesis is that the current AI Chat harness is undertuned. To find out, we need to run a set of 10 intentionally challenging queries against the real AI Chat, capture the full execution traces (prompts, tool calls, tool outputs, final responses), and analyze where the harness fails or succeeds.

The key insight from the paper (Table 3 ablation): **raw execution traces are the single most valuable input to harness optimization.** Scores-only condition reached 34.6 median accuracy; scores-plus-summaries reached 34.9; full trace access reached 50.0. We therefore want to capture everything the model saw and did.

The good news: the AI Chat Edge Function already persists every user message, every tool call (with full `tool_input` and `tool_output` JSONB), and every assistant response to the `ai_chat_messages` table. **We do not need to instrument anything — we just need to run the queries and then read the traces from the database.**

---

## What you need to do — executive summary

1. Log into Riverside as a namespace admin (see **Step 1**)
2. Start **two** fresh AI Chat conversations with specific titles (see **Step 2**)
3. Paste **9 queries into Conversation A** one at a time, in order, waiting for each response (see **Step 3**)
4. Paste **2 queries into Conversation B** as a 2-turn sequence (see **Step 4**)
5. Come back to this chat session and say "done, ready for analysis" (see **Step 5**)

Estimated wall-clock time: **15–25 minutes**. Most of that is waiting for AI Chat responses.

**You do not need to copy/paste anything back to me.** I will read the full traces directly from `ai_chat_messages` via the read-only database connection.

---

## Step 1 — Log in as Riverside admin

1. Open a browser (incognito/private tab recommended to avoid cached auth)
2. Go to either:
   - **Production:** https://nextgen.getinsync.ca
   - **Local dev:** http://localhost:5173 (if you have the dev server running)
3. Log in with an account that is a **namespace admin** on the City of Riverside namespace (so RLS does not restrict what the chat tools can see)
4. Navigate to the Riverside workspace context — use the namespace switcher at the top of the app
5. Confirm you are viewing Riverside data — the Overview page should show roughly 32 applications across 18 workspaces

---

## Step 2 — Start two fresh AI Chat conversations with specific titles

The eval needs **two separate conversations** because Query 7 tests multi-turn memory and must not be contaminated by prior context.

### Conversation A — "Eval Batch 2026-04-10 A"

1. Open the AI Chat panel (check the help menu or the chat icon — location varies)
2. Start a **new conversation** (not continuing any existing thread)
3. The first message you send will auto-generate the title from the first ~50 characters. To make the title predictable, send this as your very first message:

   ```
   This is eval batch A 2026-04-10. Please respond "Ready" and wait for the eval queries.
   ```

   You can ignore whatever the model responds with — we just need the conversation to exist with a predictable title prefix so I can find it.

### Conversation B — "Eval Batch 2026-04-10 B"

1. Start a **second new conversation** (separate from A — do not continue A)
2. Send this as your first message:

   ```
   This is eval batch B 2026-04-10. Please respond "Ready" and wait for the eval queries.
   ```

You now have two fresh conversations, each with one priming exchange. The priming messages will be ignored during analysis — I will look at messages 2+ in each conversation.

---

## Step 3 — Paste the 9 queries into Conversation A

**Rules:**

- One query at a time
- Wait for the AI Chat response to fully finish streaming before sending the next
- Do **not** edit the queries — paste them exactly as written, even if the phrasing feels awkward
- Do **not** add your own follow-up clarifications — we want to see how the harness handles the raw prompt
- If the model asks a clarifying question back, **do not answer it** — let the turn end with the clarifying question, then move on to the next query. The fact that it had to ask is part of the signal.
- If AI Chat errors out or returns a blank response, note which query it was but still move on to the next one

### The 9 queries (in order, copy one at a time)

**Query 1 — Rationalization between two real apps**

```
We have two police systems that seem to overlap — Computer-Aided Dispatch and Hexagon OnCall CAD/RMS. Which one should we rationalize to?
```

**Query 2 — Crown jewel risk ranking**

```
Which of my crown jewel applications are at highest risk? Rank them.
```

**Query 3 — Retirement blast radius**

```
If we retired Computer-Aided Dispatch tomorrow, what integrations break and what other systems are affected?
```

**Query 4 — Temporal trend (graceful failure test)**

```
How has our portfolio tech debt changed over the last 6 months? Are we trending better or worse?
```

**Query 5 — Workspace context assumption**

```
What's the top risk in the Police Department workspace right now?
```

**Query 6 — SWOT analysis**

```
Give me a SWOT analysis of my Police Department portfolio from a CIO's perspective.
```

**Query 8 — Vendor consolidation scenario**

```
If I dropped Hexagon as a vendor entirely, what would I lose and how much would I save annually?
```

> Note: Query 7 is run separately in Conversation B (see Step 4). That is why the numbering skips here.

**Query 9 — PII compliance (graceful failure test)**

```
Which applications in our portfolio handle PII and what's their assessment status?
```

**Query 10 — Data completeness self-assessment**

```
What data am I missing to run a proper portfolio review next week?
```

After Query 10, Conversation A is done. Do **not** send anything else in Conversation A.

---

## Step 4 — Paste the 2-turn sequence into Conversation B

Conversation B tests whether the harness carries meaningful context from one turn to the next.

**Turn 1 of Query 7 — Baseline list**

```
List the applications in the Finance workspace.
```

Wait for the response to complete.

**Turn 2 of Query 7 — Contextual follow-up**

```
Which of those have budget data?
```

That is the entire Conversation B. Do **not** send anything else after Turn 2.

---

## Step 5 — Tell me you are done

Come back to the Claude Code chat session where we have been working and say something like:

> "Eval queries are done. Conversations are titled 'Eval Batch 2026-04-10 A' and 'Eval Batch 2026-04-10 B'."

If the auto-generated conversation titles ended up looking different than you expected, just tell me what they actually say. I will search for any conversations in the Riverside namespace created today and match by title prefix.

I will then:

1. Query `ai_chat_messages` directly via the read-only database connection, filtering by `namespace_id = Riverside` and `created_at >= today`
2. Pull the full message traces for both conversations — user messages, tool calls (with full input and output JSONB), and assistant responses
3. Score each query against the "ideal response" rubric I have for it (see the memory file)
4. Produce a **ranked gap list** — each gap with a symptom, trace evidence, impact assessment, and proposed fix shape
5. Present that gap list to you. You pick the top 1–2 gaps to fix.
6. I implement the fixes on the `feat/ai-chat-harness-eval` branch (already created) and we re-run this same eval to measure improvement.

---

## What I will NOT do with your data

- I will not touch any message outside the two conversations you create today
- I will not modify, delete, or annotate `ai_chat_messages` rows — read-only access only
- I will not share the traces outside this session
- I will not use your personal queries as training data for anything

If you want to clean up the eval conversations afterward, you can soft-delete them from the AI Chat UI once the analysis is complete. The `ai_chat_conversations` table has a `status` field for that.

---

## Troubleshooting

**"AI Chat does not know what a 'crown jewel' is"**
That is part of the signal. Do not add clarifications. Move on.

**"The model refused to answer"**
Note which query, move on. Graceful refusal is also a data point.

**"The model is producing weird formatting"**
Also part of the signal. Do not intervene.

**"I sent a query to the wrong conversation"**
Not a dealbreaker — tell me when you come back and I will filter accordingly. Worst case we re-run the one that drifted.

**"AI Chat is really slow today"**
Normal. The tool-use loop makes up to 5 sequential Claude API calls per query. Some of these queries (especially #6 SWOT and #8 vendor consolidation) will hit the iteration limit.

**"I want to quit mid-eval and come back later"**
Fine. The memory file tracks state. Just tell me where you stopped and we can resume from that query number.

---

## Done criteria

- [ ] Logged in as Riverside namespace admin
- [ ] Conversation A created with priming message
- [ ] Conversation B created with priming message
- [ ] 9 queries run in Conversation A in order (Q1, Q2, Q3, Q4, Q5, Q6, Q8, Q9, Q10)
- [ ] 2-turn sequence run in Conversation B (Q7 turn 1, Q7 turn 2)
- [ ] You have returned to this Claude Code session and said "done"

That is it. Over to you.
