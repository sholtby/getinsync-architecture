# Session Prompt 02 — AI Chat System Prompt Rewrite (Batch 1, Part 2 of 2)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session rewrites `supabase/functions/ai-chat/system-prompt.ts` on the `feat/ai-chat-harness-eval` branch. It does NOT modify tool code (that is Session 01).

---

## Task: Rewrite the AI Chat system prompt to close prompt-layer harness gaps

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code until you have completed Step 1 (read required context).

### Why this work exists

The GetInSync NextGen AI Chat Edge Function at `supabase/functions/ai-chat/` was evaluated on 2026-04-10 against 10 Enterprise Architect questions. It scored 2 of 10 acceptable. The full eval results, trace evidence, and ranked gap list live in `docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md`. Read that file in Step 1.

Session 01 implemented the code-layer fixes (new tools, iteration limit, fallback synthesis, unstubbing technology-risk). This session addresses the **prompt-layer gaps**:

- **Gap 3** — Model uses cost as a proxy for risk
- **Gap 5** — Single-tool reflex instead of multi-tool orchestration for analytical frames
- **Gap 7** — Hallucinated statistics propagate across turns
- **Gap 8** — Wasted tool calls on unnecessary workspace discovery

Plus the prompt needs to mention the new tools Session 01 added (`list-applications`, real `technology-risk`).

You are Session 2 of 3. Focus only on `system-prompt.ts`. Do NOT edit tool code.

### Hard rules (read before touching anything)

1. **You MUST work on the `feat/ai-chat-harness-eval` branch.** Verify with `git branch --show-current`. If Session 01 hasn't pushed yet, pull it first: `git pull origin feat/ai-chat-harness-eval`.
2. **You MAY only edit one file:** `supabase/functions/ai-chat/system-prompt.ts`
3. **You MUST NOT edit:**
   - `supabase/functions/ai-chat/tools.ts` (owned by Session 01, possibly already committed)
   - `supabase/functions/ai-chat/index.ts` (owned by Session 01)
   - `supabase/functions/ai-chat/types.ts`
   - any file outside `supabase/functions/ai-chat/`
4. **You MUST verify Session 01 has landed** before beginning. If `list-applications` and the real `technology-risk` tool are not in `tools.ts`, STOP and tell Stuart that Session 01 needs to run first.
5. **You MUST run `npx tsc --noEmit` after your change** — the system prompt is a TypeScript function, so type errors are possible if you break template literal syntax.
6. **You MUST NOT deploy.** Stuart will deploy after this session merges.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md
   - Read the full Ranked Gap List. Your gaps are 3, 5, 7, and 8.
   - Pay attention to the trace evidence for each — quote the evidence in your prompt revisions where useful as few-shot reinforcement.

2. docs-architecture/planning/ai-chat-harness-optimization/README.md
   - Understand the execution order and session split.

3. supabase/functions/ai-chat/system-prompt.ts (entire file)
   - Current prompt is 79 lines, built as a single template literal in a
     buildSystemPrompt(namespaceName, appCount, workspaceCount) function.
   - Note the existing structure: scope → tools list → cost rules →
     assessment rules → tech rules → data scope → response rules.
   - Your rewrite PRESERVES this structure and ADDS to it. Do not
     wholesale replace the existing guidance.

4. supabase/functions/ai-chat/tools.ts (entire file)
   - Read the CURRENT tool definitions so the system prompt description
     of each tool matches its actual input_schema after Session 01's changes.
   - Verify list-applications and technology-risk are both real tools
     (Session 01 should have added/unstubbed them). If they are missing,
     STOP and tell Stuart Session 01 didn't land.

5. docs-architecture/features/ai-chat/semantic-layer.yaml (IF IT EXISTS)
   - The current system-prompt.ts comment says it was "hardcoded from"
     this file. If it exists, check whether any canonical rules belong
     there that should be reflected in the prompt.
   - If the file does not exist, skip this step.

6. docs-architecture/CLAUDE.md
   - Read "Architecture Rules" and the "Data Model" section to
     understand the authoritative source-of-truth rules you are
     encoding in the prompt.
```

### Step 2 — Understand what must change

Your goal is to produce a revised `buildSystemPrompt` function. The new version must:

1. **Preserve all existing domain-knowledge rules** — cost model (IT Services + Cost Bundles channels only), assessment model (scores on deployment_profiles for tech, portfolio_assignments for business), tech lifecycle, response formatting, etc. Do not delete any existing rule unless it is actively wrong.

2. **Update the `## Available tools` section** to reflect the Session 01 changes:
   - Add `list-applications` as a new entry with clear "use this when..." guidance
   - Remove the "(Coming soon)" marker from `technology-risk` and describe its real behavior
   - Keep the other stubbed tools (`roadmap-status`, `data-quality`) marked as "(Coming soon)" since they haven't been unstubbed
   - Rewrite each tool description to clarify WHEN to use it vs when to prefer another tool

3. **Add a new section before `## Response rules` called `## Tool selection rules`** that encodes:

   **For LISTING or RANKING questions** ("list X", "which apps are Y", "rank by Z", "top N", "how many X match Y"):
   - Call `list-applications` with filters. Do NOT try to enumerate by calling `application-detail` repeatedly on guessed names. If `list-applications` returns no results, say so — do not hallucinate app names.

   **For RISK questions** ("top risk", "riskiest", "at risk", "which apps need attention", "biggest risks"):
   - Call `technology-risk`. Do NOT use `cost-analysis` — **cost is NOT risk**. Risk signals are tech_health (low = risky), paid_action (Address = risky), and criticality + tech_health combined. A crown jewel with low tech_health is the highest risk; a high-cost app with good tech_health is not.
   - Explicit negative example: "If asked 'what is the top risk in Police Department?' do NOT call cost-analysis. Call technology-risk with workspace_name=Police Department."

   **For ANALYTICAL FRAMEWORK questions** (SWOT, risk matrix, scenario analysis, cross-app comparison, vendor consolidation):
   - You MUST call multiple tools and synthesize. Specifically:
     - Call `portfolio-summary` first for aggregate context
     - If costs are involved, call `cost-analysis` with BOTH `focus=run_rate` AND `focus=vendor` to capture full spend (cost bundles AND IT service allocations)
     - Call `list-applications` and/or `technology-risk` to identify key apps
     - Call `application-detail` on every specific app named or referenced
     - Only THEN compose the answer
   - Include a worked example:

     ```
     Example: "SWOT analysis of Police Department portfolio"
     Correct tool sequence:
       1. portfolio-summary()
       2. cost-analysis(focus=overview, workspace_name=Police Department)
       3. technology-risk(workspace_name=Police Department)
       4. list-applications(workspace_name=Police Department, criticality_min=50)
       5. application-detail() on the top 2-3 crown jewels returned
       6. Synthesize into S/W/O/T quadrants

     Incorrect tool sequence (what NOT to do):
       1. cost-analysis only, then guess everything else from memory
     ```

   **For WORKSPACE-SCOPED questions** where the user names the workspace:
   - Do NOT call `list-workspaces` first. The user already told you the workspace. Pass the name directly to `cost-analysis`, `list-applications`, `technology-risk`, or `application-detail`.
   - Only call `list-workspaces` if the user says "what workspaces do I have?" or "which departments..." or otherwise omits a specific workspace name.

4. **Add a new rule in `## Response rules — FOLLOW STRICTLY`** about statistical grounding:

   ```
   - **NEVER cite a specific percentage, count, dollar amount, or other statistic unless you retrieved it from a tool call in the CURRENT turn.** Do not reuse specific numbers from prior turns — always re-fetch. If the user asks a follow-up that depends on numbers, call the relevant tool again. Memory is not a source of truth for statistics.
   ```

5. **Add a new rule about vendor cost completeness:**

   ```
   - **When asked about a vendor's total cost or "what if we dropped vendor X", you MUST sum BOTH sides of the cost model:**
     - The cost bundle side (from cost-analysis focus=vendor)
     - The IT service allocation side (from cost-analysis focus=run_rate where the app or service uses that vendor)
     NEVER report a vendor total from the cost bundle side alone — that is only half the picture. If IT service vendor attribution shows "Unknown" (a known data gap), explicitly note that vendor attribution on IT services is incomplete and the reported number may understate total spend.
   ```

6. **Preserve the `## Response rules` discipline about being concise** — don't volunteer extra sections, lead with numbers, 2-4 sentences for simple questions, etc. Those rules are good and should stay.

### Step 3 — Write the revised prompt

Rewrite `buildSystemPrompt` to incorporate the changes above. Keep the function signature unchanged:

```typescript
export function buildSystemPrompt(
  namespaceName: string,
  appCount: number,
  workspaceCount: number,
): string
```

The return value is a single template literal. Do not restructure the function to return an object or take additional parameters.

**Organizational guidance:**

- Aim for 150-200 lines total (up from 79). Concise but comprehensive.
- Keep existing section headers where they make sense. Add new sections as described above.
- Order matters — put tool selection rules BEFORE the detailed domain rules (cost, assessment, tech) because tool selection is the most common failure mode we are fixing.
- Use `## Headers` with markdown consistently (the current prompt already does this).
- Use bullet lists, not paragraphs, for rules.
- When quoting an example from the Batch 0 trace evidence, keep it short and focused on the pattern being taught.

**Do not embed large data dumps in the prompt.** The dynamic `namespaceName`, `appCount`, `workspaceCount` values already inject live stats. Do not hardcode Riverside-specific data.

### Step 4 — Verify and commit

1. Run `npx tsc --noEmit` from the repo root. Zero errors required. A common failure mode is breaking template literal escaping when adding backticks, dollar signs, or curly braces — check carefully.

2. Run `git status` to confirm you only modified `supabase/functions/ai-chat/system-prompt.ts`. Nothing else.

3. Run `git diff supabase/functions/ai-chat/system-prompt.ts` and sanity-check the output. The diff should show:
   - New `## Tool selection rules` section added
   - New rules added to `## Response rules`
   - Updated tool descriptions in `## Available tools`
   - Everything else preserved

4. Commit with a HEREDOC message:

   ```bash
   git add supabase/functions/ai-chat/system-prompt.ts

   git commit -m "$(cat <<'EOF'
   feat: AI Chat system prompt rewrite (Batch 1 Gaps 3, 5, 7, 8)

   Addresses the prompt-layer gaps identified in Batch 0 eval
   (docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md):

   - Gap 3: explicit tool-selection rules for risk questions
     (technology-risk, NOT cost-analysis) with negative example
   - Gap 5: multi-tool orchestration rules for analytical frames
     (SWOT, vendor consolidation) with worked SWOT example
   - Gap 7: no-statistic-without-current-turn-tool-call rule to
     prevent confident hallucination propagation
   - Gap 8: skip list-workspaces when user has named the workspace

   Also updates tool descriptions to reflect Session 01 changes
   (new list-applications tool, unstubbed technology-risk tool).

   System prompt grew from 79 to ~180 lines.

   Next: Session 03 re-eval after Stuart deploys the Edge Function.

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

5. Push:
   ```bash
   git push origin feat/ai-chat-harness-eval
   ```

### Step 5 — Session summary

Produce a short final message listing:

1. Confirmation that `npx tsc --noEmit` passed
2. The line count before and after
3. The new section headers you added
4. Any domain rules from the original prompt you adjusted or removed (and why)
5. A one-line summary of next steps: *"Ready for Stuart to deploy the Edge Function and run Session 03 (re-evaluation). Deploy with: `supabase functions deploy ai-chat` from the repo root."*

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] Verified Session 01 landed (list-applications and real technology-risk exist in tools.ts)
- [ ] Revised prompt preserves all existing domain-knowledge rules
- [ ] `## Tool selection rules` section added with risk, listing, analytical, workspace-scoped guidance
- [ ] Worked SWOT example included as few-shot reinforcement
- [ ] Statistical-grounding rule added to `## Response rules`
- [ ] Vendor-cost-completeness rule added
- [ ] Tool descriptions updated to reflect Session 01 changes
- [ ] `technology-risk` no longer marked "(Coming soon)"
- [ ] `list-applications` included in tool list
- [ ] `npx tsc --noEmit` passes
- [ ] Only `system-prompt.ts` was modified
- [ ] Changes committed to `feat/ai-chat-harness-eval`
- [ ] Branch pushed to origin
- [ ] Session summary produced

### What NOT to do

- Do NOT edit `tools.ts` or `index.ts`. Session 01 owns those.
- Do NOT deploy the Edge Function.
- Do NOT merge `feat/ai-chat-harness-eval` into `dev`.
- Do NOT hardcode Riverside-specific data into the prompt (namespaceName, appCount, workspaceCount are already injected dynamically).
- Do NOT delete the existing cost rules, assessment rules, or tech rules sections. They are correct and will still apply.
- Do NOT shorten the response rules. Keep the "lead with number", "2-4 sentences", "no unsolicited sections" discipline — those are good.
- Do NOT add new domain knowledge that isn't in the existing prompt or the gap list. If you see a gap not covered by the eval, flag it to Stuart rather than improvising.
- Do NOT touch any `technology-*` or `roadmap-*` or `data-quality` mention in the prompt beyond what is specified. Stubbed tools stay stubbed except `technology-risk`.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
