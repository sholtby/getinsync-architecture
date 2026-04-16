# Session Prompt 01 — AI Chat Harness Code Changes (Batch 1, Part 1 of 2)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session writes TypeScript code to `supabase/functions/ai-chat/` on the `feat/ai-chat-harness-eval` branch. It does NOT modify the system prompt (that is Session 02).

---

## Task: Implement Batch 1 code-layer fixes to the AI Chat Edge Function

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code until you have completed Step 1 (read required context).

### Why this work exists

The GetInSync NextGen AI Chat Edge Function at `supabase/functions/ai-chat/` was evaluated on 2026-04-10 against 10 Enterprise Architect questions in the City of Riverside demo namespace. It scored 2 of 10 acceptable. The full eval results, trace evidence, and ranked gap list live in `docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md`. Read that file in Step 1 — it is the authoritative description of what is broken and why.

This session implements the **code-layer fixes** identified in Batch 1 of the gap list. A second session (`02-session-prompt-system-prompt.md`) will rewrite the system prompt to address the prompt-layer gaps. A third session (`03-session-prompt-re-evaluation.md`) will re-run the 10 queries and measure improvement after both code and prompt changes ship.

You are Session 1 of 3. Focus only on code changes. Do NOT edit `system-prompt.ts`.

### Hard rules (read before touching anything)

1. **You MUST work on the `feat/ai-chat-harness-eval` branch.** Do not check out `dev` or `main`. Do not create a new branch. The branch already exists at `~/Dev/getinsync-nextgen-ag` and should be the current branch when you begin. Verify with `git branch --show-current`.
2. **You MAY only edit these files:**
   - `supabase/functions/ai-chat/tools.ts`
   - `supabase/functions/ai-chat/index.ts`
   - `supabase/functions/ai-chat/types.ts` (only if strictly needed for new types)
3. **You MUST NOT edit:**
   - `supabase/functions/ai-chat/system-prompt.ts` (reserved for Session 02)
   - any database schema, migrations, or views
   - any file in `docs-architecture/` (the architecture repo — Session 03 will write the re-eval results there)
   - any file outside `supabase/functions/ai-chat/`
4. **You MUST run `npx tsc --noEmit` before committing** and it must pass with zero errors.
5. **You MUST NOT deploy the Edge Function.** Stuart deploys manually via `supabase functions deploy ai-chat` after both Session 01 and Session 02 are merged.
6. **You MUST read actual view definitions via `DATABASE_READONLY_URL`** before writing any SQL in new tools. Do not assume column names from memory. Use the read-only connection.
7. **You MAY run `DATABASE_READONLY_URL` SELECT queries only.** No writes, no DDL. The connection is for schema introspection and view validation only.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md
   - The canonical source for what is broken and why.
   - Pay attention to the "Ranked gap list" section — Gaps 1, 2, 3 (partial), and 4.
   - The "Batch 1 — Recommended fix set" table tells you which gaps belong to which session. You own the rows assigned to "Session 1 (code)".

2. docs-architecture/planning/ai-chat-harness-optimization/README.md
   - Understand the execution order and why sessions are split.

3. supabase/functions/ai-chat/index.ts (entire file)
   - Read the current orchestrator. Note MAX_TOOL_ITERATIONS on line 32.
   - Note the tool-use loop at lines 197-234. Note the fallback on lines 237-240.

4. supabase/functions/ai-chat/tools.ts (entire file)
   - Read every existing TOOL_DEFINITION and executeTool case.
   - Pay attention to the shape of tool descriptions, input schemas, and the text format of tool_output.

5. supabase/functions/ai-chat/types.ts
   - Understand ContentBlock, ToolUseBlock, ToolResultContent types.

6. CLAUDE.md (at repo root)
   - Read "Architecture Rules", "Database Access", and "What You Must NOT Do".
```

Do not read any other files unless a specific fix below requires it.

### Step 2 — Discover view definitions you will need

Before writing any new tool code, use the read-only DB connection to verify column names and types for the views you will query.

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

# Inspect the views that existing tools already use (so you know what's available):
psql "$DATABASE_READONLY_URL" -c "\d vw_portfolio_overview"
psql "$DATABASE_READONLY_URL" -c "\d vw_application_detail"
psql "$DATABASE_READONLY_URL" -c "\d vw_integration_detail"
psql "$DATABASE_READONLY_URL" -c "\d vw_portfolio_costs"

# Also inspect the application_integrations base table — you will need this for Gap 4:
psql "$DATABASE_READONLY_URL" -c "\d application_integrations"
```

If any view name is wrong (views get renamed), grep for the real name in the existing `tools.ts` — the current tools already query the correct views. Use those as your source of truth.

### Step 3 — Implement the four fixes

Implement these in order. Commit incrementally if you want, but a single squashed commit at the end is also fine.

#### Fix 3.1 — GAP 2: Raise iteration limit and fix the fallback

**File:** `supabase/functions/ai-chat/index.ts`

**What to change:**

1. On line 32, change:
   ```typescript
   const MAX_TOOL_ITERATIONS = 5;
   ```
   to:
   ```typescript
   const MAX_TOOL_ITERATIONS = 15;
   ```

2. In the tool-use loop around lines 197-240, replace the current fallback behavior. Current code sets `finalText` to a hardcoded error string if the loop exhausts without producing text. This discards all tool data the model gathered.

   New behavior: if the loop exhausts (`iteration === MAX_TOOL_ITERATIONS + 1` and `stop_reason` was still `tool_use` on the last call), make **one final call** to Claude with a special synthesis instruction prepended to the system prompt:

   ```
   ORCHESTRATION BUDGET EXHAUSTED: You have used all tool-call iterations for this turn. Do NOT request any more tool calls. Synthesize the best answer you can from the tool data already in the conversation history above. If the data is incomplete, say so explicitly and tell the user what would require additional investigation. Do not produce a blank or generic fallback.
   ```

   This final call should have `tools` OMITTED from the payload (force text response), `max_tokens: 4096`, same messages array, same model. The resulting text becomes `finalText`.

   If even that synthesis call fails (API error, network), fall back to a message that includes a summary of what tools were called:
   ```
   I gathered data from [tool1, tool2, tool3] but was unable to complete the analysis. Please try a more specific question or ask me to focus on one aspect at a time.
   ```
   (where the tool names come from the `toolCalls` array).

**Why:** Query 2 in the baseline eval gathered real data from portfolio-summary, application-detail(CAD), and application-detail(Hexagon) before hitting the limit. The user received a useless fallback string and lost all that data. This fix ensures the model gets a chance to synthesize whatever it has.

**Type check:** after the change, run `npx tsc --noEmit` and confirm zero errors.

#### Fix 3.2 — GAP 1: Add `list-applications` tool

**File:** `supabase/functions/ai-chat/tools.ts`

**What to add:**

1. A new entry in `TOOL_DEFINITIONS` array:

   ```typescript
   {
     name: 'list-applications',
     description:
       'List applications matching optional filters. Returns a structured list with name, workspace, criticality, tech health, PAID action, and run rate for each matching app. Use this for "list X", "rank X by Y", "which apps are Z", "how many apps match Z", or any question that requires enumerating applications. This is the ONLY tool that returns a list of application NAMES (portfolio-summary returns counts only).',
     input_schema: {
       type: 'object',
       properties: {
         workspace_name: {
           type: 'string',
           description: 'Optional workspace filter (e.g. "Police Department"). Omit to list across all workspaces in the namespace.',
         },
         criticality_min: {
           type: 'number',
           description: 'Minimum criticality score. Use 50 to find crown jewels.',
         },
         tech_health_max: {
           type: 'number',
           description: 'Maximum tech health score. Use this to find struggling apps (e.g. tech_health_max=40 returns apps needing attention).',
         },
         time_quadrant: {
           type: 'string',
           description: 'Filter by TIME quadrant: Tolerate, Invest, Migrate, or Eliminate.',
           enum: ['Tolerate', 'Invest', 'Migrate', 'Eliminate'],
         },
         paid_action: {
           type: 'string',
           description: 'Filter by PAID action: Plan, Address, Delay, or Ignore.',
           enum: ['Plan', 'Address', 'Delay', 'Ignore'],
         },
         limit: {
           type: 'number',
           description: 'Max number of results (default 50, max 200).',
         },
       },
     },
   }
   ```

2. A new case in `executeTool` that handles `name === 'list-applications'`. Use the existing tool-handler pattern — create a user-scoped Supabase client using the JWT, query the appropriate view with filters applied, format the result as markdown.

3. **Which view to query:** the existing `application-detail` tool reads from a view (determine the name by reading the existing case in tools.ts). The same view is likely suitable for listing with filters applied. If the columns you need are not on that view, check `vw_portfolio_overview` or equivalent. If you cannot find a suitable view, STOP and tell Stuart "list-applications needs a view with columns X, Y, Z that I cannot find" rather than guessing.

4. **Output format:** markdown, one app per line, under `MAX_TOOL_RESULT_CHARS`. Example:

   ```
   ## Applications (filtered: workspace=Police Department, criticality_min=50)

   **5 matches:**

   - **Hexagon OnCall CAD/RMS** (Police Department)
     Criticality: 99 | Tech Health: 32 | TIME: Modernize | PAID: Address | Run Rate: $230.6K
   - **Computer-Aided Dispatch** (Police Department)
     Criticality: 95 | Tech Health: 48.75 | TIME: Modernize | PAID: Address | Run Rate: $121K
   ...
   ```

   Truncate to the first 50 results (or the `limit` parameter) and append `"... plus N more"` if truncated.

5. **RLS:** like all other tools, this MUST use a JWT-scoped Supabase client, not the admin client. RLS enforcement is non-negotiable.

**Why:** Query 2 in the baseline eval hallucinated app names ("Cityworks", "New World") because there was no way to enumerate crown jewels. Query 7 Turn 1 failed because there was no way to list apps in a workspace. This tool directly unblocks both.

**Type check:** run `npx tsc --noEmit`, must pass.

#### Fix 3.3 — GAP 4: Expand application-detail to include integration list

**File:** `supabase/functions/ai-chat/tools.ts`

**What to change:**

Find the existing `application-detail` executor. It currently returns a count like `"Integrations: 3"`. Replace this with a list.

**Implementation:**

1. After fetching the main application detail row, run a second query against `application_integrations` filtered by `source_application_id = $APP_ID OR target_application_id = $APP_ID`
2. Join on `applications` table to get peer app names (for the app that is NOT the current app on each integration)
3. Format the result as:

   ```
   ### Integrations (3)
   - **ServiceNow CMDB Sync** → Active Directory Services (upstream, api)
   - **Emergency Response ↔ CAD** ↔ Emergency Response System (bidirectional, api) [DP-aligned]
   - **NG911 → CAD Call Routing** ← NG911 System (downstream, api) [DP-aligned]
   ```

   Where:
   - The arrow indicates direction from the CURRENT app's perspective
   - `[DP-aligned]` appears only when `source_deployment_profile_id` AND `target_deployment_profile_id` are both set
   - If integration has no name, use the peer app name as the label: `"(unnamed) ↔ Active Directory Services"`

4. If the app has zero integrations, output `"### Integrations (0)\n_No integrations on record._"`
5. Keep the total `tool_output` under `MAX_TOOL_RESULT_CHARS` (4000). If integrations push over the limit, truncate the integration list to the first 10 with `"... plus N more"`.

**Why:** Query 3 in the baseline eval received `"Integrations: 3"` and had to admit defeat on the blast-radius question. The real integration data was one query away.

**Type check:** `npx tsc --noEmit`, must pass.

#### Fix 3.4 — GAP 3 (partial): Unstub the `technology-risk` tool

**File:** `supabase/functions/ai-chat/tools.ts`

**What to change:**

Find the existing stubbed `technology-risk` entry. Currently the TOOL_DEFINITION says it's "coming soon" and the executor returns a placeholder. Implement it as a real tool.

**Implementation:**

1. Update the TOOL_DEFINITION description to describe its actual behavior:

   ```
   'Analyze technology risk by ranking applications by tech_health deficit weighted by criticality. Use this for "top risks", "riskiest apps", "at risk", "which apps need attention", or any risk-ranking question. Returns top N apps with low tech_health AND high criticality. This is the CORRECT tool for risk questions — DO NOT use cost-analysis for risk.'
   ```

2. Give it an input schema with optional `workspace_name` and `limit` (default 10):

   ```typescript
   input_schema: {
     type: 'object',
     properties: {
       workspace_name: {
         type: 'string',
         description: 'Optional workspace filter (e.g. "Police Department").',
       },
       limit: {
         type: 'number',
         description: 'Number of top-risk apps to return (default 10, max 50).',
       },
     },
   }
   ```

3. Implement the executor. Query the same view `application-detail` uses, but SELECT the columns `name, workspace_name, criticality, tech_health, paid_action, time_quadrant`. Apply the workspace filter if present. Filter out apps with NULL criticality or NULL tech_health (only assessed apps can have a "risk score"). Compute a risk score in SQL or in memory:

   ```
   risk_score = criticality * (100 - tech_health) / 100
   ```

   A crown jewel (criticality 100) with tech_health 0 gets risk_score 100. A crown jewel with tech_health 100 gets risk_score 0. A criticality-50 app with tech_health 50 gets risk_score 25.

4. Sort descending by risk_score. Return the top `limit` as markdown:

   ```
   ## Technology Risk Ranking
   **Filter:** workspace=Police Department
   **Scored apps:** 10 of 10 assessed

   | Rank | Application | Criticality | Tech Health | PAID | Risk Score |
   |------|-------------|-------------|-------------|------|------------|
   | 1 | Hexagon OnCall CAD/RMS | 99 | 32 | Address | 67.3 |
   | 2 | Police Records Management | 74 | 17.25 | Address | 61.2 |
   | 3 | Computer-Aided Dispatch | 95 | 48.75 | Address | 48.7 |
   ...
   ```

5. If the user's filter produces zero assessed apps, return:
   ```
   ## Technology Risk Ranking
   No assessed applications match the filter. Risk ranking requires both criticality and tech_health scores to be present. Recommend running a business and technical assessment on apps in this workspace first.
   ```

**Why:** Query 5 in the baseline eval gave the wrong answer ("NG911 at $330K") because the model used cost as a risk proxy. With this tool in place + the system prompt changes in Session 02, the model should call technology-risk for risk questions and get the right answer (Hexagon, Police Records, CAD as the top 3 Police risks).

**Type check:** `npx tsc --noEmit`, must pass.

### Step 4 — Verify everything compiles and commit

1. Run `npx tsc --noEmit` from the repo root. Zero errors required.
2. Run `git status` to confirm you only modified `supabase/functions/ai-chat/index.ts`, `supabase/functions/ai-chat/tools.ts`, and possibly `types.ts`. Nothing else.
3. Run `git diff --stat` to sanity-check the scope of changes.
4. Commit with a HEREDOC message:

   ```bash
   git add supabase/functions/ai-chat/index.ts supabase/functions/ai-chat/tools.ts
   # if you edited types.ts, add it too

   git commit -m "$(cat <<'EOF'
   feat: AI Chat harness Batch 1 code fixes (Gaps 1, 2, 3p, 4)

   Addresses the code-layer gaps identified in Batch 0 eval
   (docs-architecture/planning/ai-chat-harness-optimization/00-eval-results-batch-0.md):

   - Gap 1: new list-applications tool for enumeration queries
   - Gap 2: MAX_TOOL_ITERATIONS 5 → 15 and synthesis-on-exhaustion fallback
   - Gap 3 (partial): unstub technology-risk tool with risk-scored ranking
   - Gap 4: application-detail now returns full integration list with
     direction, type, peer app name, and DP-alignment flag

   System prompt changes (Gaps 3, 5, 7, 8) land in Session 02.
   Re-evaluation lands in Session 03 after both sessions merge and deploy.

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

5. Push:
   ```bash
   git push -u origin feat/ai-chat-harness-eval
   ```

### Step 5 — Session summary

Produce a short final message listing:

1. Confirmation that `npx tsc --noEmit` passed with zero errors
2. The files you edited and the number of lines changed in each
3. The view name(s) you chose for `list-applications` and `technology-risk` (so Stuart can verify)
4. The view name you used for the integration expansion in `application-detail`
5. Any gaps or assumptions you had to make (e.g. "the view `vw_app_ranking` didn't exist so I used `vw_application_detail` instead")
6. A one-line summary of next steps: *"Ready for Session 02 (system prompt rewrite). Do NOT deploy yet — Stuart should run Session 02 first, then deploy both changes together."*

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] `DATABASE_READONLY_URL` was used for schema verification before writing new SQL
- [ ] `MAX_TOOL_ITERATIONS` raised from 5 to 15 in `index.ts`
- [ ] Exhaustion fallback now calls Claude one more time to synthesize partial data
- [ ] `list-applications` tool added to `TOOL_DEFINITIONS` and `executeTool`
- [ ] `application-detail` tool output now includes an `Integrations (N)` section with per-integration details
- [ ] `technology-risk` tool no longer returns "coming soon" — it returns a real risk-scored ranking
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `system-prompt.ts` is UNCHANGED (Session 02 owns that file)
- [ ] No files outside `supabase/functions/ai-chat/` have been modified
- [ ] Changes committed to `feat/ai-chat-harness-eval` branch
- [ ] Branch pushed to origin
- [ ] Session summary produced

### What NOT to do

- Do NOT edit `system-prompt.ts`. Session 02 owns that file and will conflict if you touch it.
- Do NOT deploy the Edge Function. Stuart will deploy manually after Session 02 lands.
- Do NOT merge `feat/ai-chat-harness-eval` into `dev`. Session 03 will re-eval first.
- Do NOT modify any database schema. All new tools query existing views.
- Do NOT add hardcoded dropdown values to new tools. If you need enum values, fetch them from reference tables.
- Do NOT add new dependencies to `package.json` or `import_map.json`. Use what's already imported.
- Do NOT write new tests or scaffolding. Session 03 will re-run the Batch 0 eval queries against the deployed changes.
- Do NOT read files in `docs-architecture/guides/` — those are user-facing and not relevant here.
- Do NOT touch `supabase/functions/ai-generate/`, `supabase/functions/apm-chat/`, or any other Edge Function. Only `ai-chat` is in scope.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
