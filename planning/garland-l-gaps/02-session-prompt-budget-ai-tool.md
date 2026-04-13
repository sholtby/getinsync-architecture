# Session Prompt 02 — AI Chat: Budget Trends Tool

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 1-1.5 days

---

## Task: Add a `budget-trends` tool to the AI chat that queries Year-over-Year budget data

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 5) shows the example query: "What's our year-over-year spend trend in Public Safety?" The AI chat system prompt **explicitly refuses** this type of question (line 81-85 of `system-prompt.ts`):

> "The portfolio model does not store historical snapshots — there is no time-series data anywhere in your tool surface."

This was accurate when written — but it's no longer true. The `workspace_budgets` table stores per-fiscal-year data, and `vw_workspace_budget_history` already computes YoY deltas with `prior_year_budget`, `prior_year_actual`, and `budget_yoy_change` columns via LAG window functions. The data layer is complete — the AI chat just doesn't know about it.

This session:
1. Adds a `budget-trends` tool to query `vw_workspace_budget_history`
2. Removes the system prompt prohibition on trend/YoY questions
3. Adds budget-specific guidance to the system prompt

### Hard rules

1. **Branch:** `feat/budget-ai-tool`. Create from `dev`.
2. **You MAY only modify files in `supabase/functions/ai-chat/`:**
   - `tools.ts` — tool definition + executor
   - `system-prompt.ts` — remove prohibition, add budget guidance
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Follow existing tool patterns exactly** — same structure as `cost-analysis`, `list-applications`, etc.
5. **Use the user's JWT for queries** — RLS-enforced, same as all other tools.
6. **Do NOT modify the database** — the view already exists and has all needed columns.

### Step 1 — Read the required context (in this order)

```
1. supabase/functions/ai-chat/system-prompt.ts
   - Lines 81-85: the prohibition on trend/YoY questions — THIS MUST BE REMOVED
   - Read the full system prompt to understand the AI's context about the data model
   - Note how other data domains are described (cost model, applications, etc.)

2. supabase/functions/ai-chat/tools.ts
   - TOOL_DEFINITIONS array (lines ~21-178): schema for all existing tools
   - executeTool() switch/case (lines ~184-225): dispatch pattern
   - executeCostAnalysis() function: closest analog to what we're building
   - createUserClient() helper (lines ~1002-1008): JWT-scoped Supabase client
   - Note the output formatting pattern: tools return structured text, not raw JSON

3. supabase/functions/ai-chat/index.ts
   - Tool loop pattern (lines ~202-222): how tool results flow back to Claude
   - Note: TOOL_DEFINITIONS is imported and passed directly to the API call

4. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "vw_workspace_budget_history" (~line 11118)
   - Columns: workspace_id, workspace_name, namespace_id, fiscal_year,
     budget_amount, actual_run_rate, variance, variance_percent,
     prior_year_budget, prior_year_actual, budget_yoy_change, is_current
```

### Step 2 — Verify view data via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm view definition
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_workspace_budget_history' ORDER BY ordinal_position"

# Check actual data volume and shape
psql "$DATABASE_READONLY_URL" -c "SELECT workspace_name, fiscal_year, budget_amount, actual_run_rate, budget_yoy_change FROM vw_workspace_budget_history ORDER BY workspace_name, fiscal_year LIMIT 30"

# Check how many fiscal years exist per workspace
psql "$DATABASE_READONLY_URL" -c "SELECT workspace_name, count(*) as years, min(fiscal_year) as earliest, max(fiscal_year) as latest FROM vw_workspace_budget_history GROUP BY workspace_name ORDER BY workspace_name"
```

### Step 3 — Add tool definition to TOOL_DEFINITIONS

Add to the `TOOL_DEFINITIONS` array in `tools.ts`:

```typescript
{
  name: 'budget-trends',
  description: 'Query year-over-year budget data across fiscal years. Returns budget amounts, actual run rates, variance, and YoY changes for each workspace. Use this when the user asks about budget trends, spending over time, year-over-year comparisons, or fiscal year history.',
  input_schema: {
    type: 'object',
    properties: {
      workspace_name: {
        type: 'string',
        description: 'Optional — filter to a specific workspace name (partial match). Omit to see all workspaces.',
      },
      fiscal_year: {
        type: 'integer',
        description: 'Optional — filter to a specific fiscal year. Omit to see all years.',
      },
      current_only: {
        type: 'boolean',
        description: 'If true, return only the current fiscal year row per workspace. Default false.',
      },
    },
  },
},
```

### Step 4 — Add case to executeTool switch

In the `executeTool()` function, add the new case:

```typescript
case 'budget-trends':
  return await executeBudgetTrends(id, namespaceId, userToken, input);
```

### Step 5 — Implement executeBudgetTrends

```typescript
async function executeBudgetTrends(
  toolId: string,
  namespaceId: string,
  userToken: string,
  input: Record<string, unknown>,
): Promise<ToolResultContent> {
  const client = createUserClient(userToken);

  const workspaceFilter = (input.workspace_name as string) || '';
  const fiscalYear = input.fiscal_year !== undefined ? Number(input.fiscal_year) : null;
  const currentOnly = Boolean(input.current_only);

  let query = client
    .from('vw_workspace_budget_history')
    .select('workspace_name, fiscal_year, budget_amount, actual_run_rate, variance, variance_percent, prior_year_budget, prior_year_actual, budget_yoy_change, is_current')
    .eq('namespace_id', namespaceId)
    .order('workspace_name', { ascending: true })
    .order('fiscal_year', { ascending: false });

  if (workspaceFilter) {
    query = query.ilike('workspace_name', `%${workspaceFilter}%`);
  }
  if (fiscalYear !== null) {
    query = query.eq('fiscal_year', fiscalYear);
  }
  if (currentOnly) {
    query = query.eq('is_current', true);
  }

  const { data, error } = await query;

  if (error) {
    return {
      type: 'tool_result',
      tool_use_id: toolId,
      content: `Error querying budget trends: ${error.message}`,
      is_error: true,
    };
  }

  if (!data || data.length === 0) {
    return {
      type: 'tool_result',
      tool_use_id: toolId,
      content: 'No budget data found for the specified filters.',
    };
  }

  // Build filter description
  const filters: string[] = [];
  if (workspaceFilter) filters.push(`workspace matches "${workspaceFilter}"`);
  if (fiscalYear !== null) filters.push(`fiscal_year=${fiscalYear}`);
  if (currentOnly) filters.push('current year only');

  // Format output
  const formatCurrency = (n: number | null) => {
    if (n === null || n === undefined) return 'N/A';
    return '$' + n.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  };

  const formatPercent = (n: number | null) => {
    if (n === null || n === undefined) return 'N/A';
    return n.toFixed(1) + '%';
  };

  // Group by workspace for readability
  const byWorkspace = new Map<string, typeof data>();
  for (const row of data) {
    const ws = row.workspace_name;
    if (!byWorkspace.has(ws)) byWorkspace.set(ws, []);
    byWorkspace.get(ws)!.push(row);
  }

  let output = `## Budget Trends\n`;
  if (filters.length > 0) output += `Filters: ${filters.join(', ')}\n`;
  output += `${data.length} rows across ${byWorkspace.size} workspace(s)\n\n`;

  for (const [wsName, rows] of byWorkspace) {
    output += `### ${wsName}\n`;
    output += `| Year | Budget | Actual | Variance | Var % | YoY Budget Δ |\n`;
    output += `|------|--------|--------|----------|-------|---------------|\n`;

    for (const row of rows) {
      const currentFlag = row.is_current ? ' ◀' : '';
      output += `| ${row.fiscal_year}${currentFlag} | `;
      output += `${formatCurrency(row.budget_amount)} | `;
      output += `${formatCurrency(row.actual_run_rate)} | `;
      output += `${formatCurrency(row.variance)} | `;
      output += `${formatPercent(row.variance_percent)} | `;
      output += `${formatCurrency(row.budget_yoy_change)} |\n`;
    }
    output += '\n';
  }

  // Add summary insights
  const currentRows = data.filter(r => r.is_current);
  if (currentRows.length > 0) {
    const totalBudget = currentRows.reduce((sum, r) => sum + (r.budget_amount || 0), 0);
    const totalActual = currentRows.reduce((sum, r) => sum + (r.actual_run_rate || 0), 0);
    const totalYoY = currentRows.reduce((sum, r) => sum + (r.budget_yoy_change || 0), 0);

    output += `### Current Year Summary\n`;
    output += `- Total budget: ${formatCurrency(totalBudget)}\n`;
    output += `- Total actual: ${formatCurrency(totalActual)}\n`;
    output += `- Total variance: ${formatCurrency(totalBudget - totalActual)}\n`;
    output += `- Total YoY budget change: ${formatCurrency(totalYoY)}\n`;
  }

  return {
    type: 'tool_result',
    tool_use_id: toolId,
    content: output,
  };
}
```

### Step 6 — Update system prompt

In `system-prompt.ts`, make two changes:

**6a. Remove the YoY prohibition:**

Find and remove the block at lines ~81-85 that says:
```
When the user asks about "trend", "over time", "last 6 months"...
refuse gracefully WITHOUT calling a tool...
```

**6b. Add budget trends guidance:**

In the data model description section, add:

```
### Budget & Fiscal Year Data
The platform stores budget data per workspace per fiscal year. You can query year-over-year trends using the budget-trends tool. Available data includes:
- Budget amount and actual run rate per fiscal year
- Variance (budget minus actual) and variance percentage
- Prior year comparisons via LAG window functions
- Year-over-year budget change

When the user asks about spending trends, budget comparisons, or fiscal year history, use the budget-trends tool. You CAN answer trend questions — budget history is stored per fiscal year.

Note: Budget data is workspace-scoped. For cross-workspace trends, omit the workspace filter and the tool returns all workspaces. For "total organization" trends, sum across workspaces.
```

**6c. Keep the prohibition for NON-BUDGET time-series:**

Add a narrower prohibition:
```
For time-series questions that are NOT about budgets (e.g., "how has our application count changed over the last 6 months", "what was our tech health score last quarter"), these are still unsupported — no historical snapshots exist for application metrics. Refuse gracefully and offer the current-state view.
```

### Step 7 — Type check

```bash
npx tsc --noEmit
```

### Step 8 — Test the tool locally (if dev server available)

If the AI chat is testable locally, try these queries:
1. "What's our year-over-year spend trend?" → should call budget-trends tool
2. "How has spending changed in [workspace name]?" → should filter by workspace
3. "What was our budget for 2025?" → should filter by fiscal_year
4. "How has our application count changed?" → should still refuse (non-budget time-series)

### Step 9 — Update architecture docs

Update `docs-architecture/features/cost-budget/budget-management.md`:
- Add section on AI chat budget trends capability
- Document the `budget-trends` tool and its parameters

Update the What's New / changelog if applicable.

### Step 10 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add supabase/functions/ai-chat/tools.ts supabase/functions/ai-chat/system-prompt.ts
git commit -m "feat: AI chat budget-trends tool for YoY spend queries

Adds budget-trends tool querying vw_workspace_budget_history. Removes
the blanket prohibition on trend/YoY questions, replacing with a
narrower rule that only blocks non-budget time-series.
Closes Garland audit red flag (Slide 5, 'YoY spend trend')."
git push -u origin feat/budget-ai-tool
```

Also commit architecture doc:
```bash
cd ~/getinsync-architecture
git add features/cost-budget/budget-management.md
git commit -m "docs: add AI chat budget-trends tool to budget management doc"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] `budget-trends` tool added to TOOL_DEFINITIONS with workspace, fiscal_year, current_only params
- [ ] `executeBudgetTrends()` function queries `vw_workspace_budget_history` via user JWT
- [ ] Output formatted as markdown tables grouped by workspace
- [ ] Current year summary section with totals
- [ ] Switch case added in `executeTool()` dispatch
- [ ] System prompt: YoY prohibition REMOVED
- [ ] System prompt: budget data guidance ADDED
- [ ] System prompt: narrower prohibition for non-budget time-series ADDED
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] No database schema changes
- [ ] Architecture doc updated

### What NOT to do

- Do NOT create new database views or tables — `vw_workspace_budget_history` is complete
- Do NOT modify other existing tools — only add the new one
- Do NOT remove the prohibition for ALL time-series questions — only budget-related ones are now answerable
- Do NOT modify `index.ts` or `context.ts` — only `tools.ts` and `system-prompt.ts`
- Do NOT deploy the Edge Function — Stuart handles `supabase functions deploy ai-chat`
- Do NOT add budget data to the existing `cost-analysis` tool — keep it separate for clarity
