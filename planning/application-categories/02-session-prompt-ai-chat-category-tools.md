# Session Prompt 02 — AI Chat Category Tools (Application Categories, Part 2 of 3)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session adds three new tools and one new system prompt subheading to the AI Chat Edge Function on a NEW branch `feat/ai-chat-category-tools`, branched from `dev`. It does NOT touch the `feat/ai-chat-harness-eval` branch which carries the parallel Batch 2 work.

---

## Task: Add three category-aware tools to the AI Chat Edge Function

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any code until you have completed Step 1 (read required context) and Step 2 (verify Session 1 data is loaded).

### Why this work exists

The GetInSync NextGen AI Chat harness has zero awareness of application category data. Enterprise architects routinely ask "what apps do we have for CRM?", "which applications handle Human Resources?", "what's my portfolio breakdown by capability?" — and today the harness has no tool that answers any of these. The schema supports it (`application_categories` per-namespace catalog + `application_category_assignments` M:M junction), Session 1 of this initiative populates Riverside with real assignments, and this session adds the three tools that surface that data through chat.

The three tools, all queued together because they compose:

1. **`list-application-categories`** — discoverability tool. Returns the catalog (code, name, description, app count per category) so the model can find the right category before drilling in. Mirrors the `list-workspaces` pattern.
2. **`category` filter on `list-applications`** — additive parameter. The existing `list-applications` tool gains an optional `category` parameter that joins through the assignments junction. Lets the model answer "list my CRM apps" in a single call once it knows the category code.
3. **`category-rollup`** — aggregate breakdown tool. Returns one row per category with `app_count`, `assessed_count`, `crown_jewel_count`, and `total_run_rate`. Single-call answer to "show me my portfolio by capability" or "which categories carry the most apps/cost."

You are Session 2 of 3 in the Application Categories initiative. Session 1 (`01-session-prompt-riverside-category-data.md`) populates Riverside data. Session 3 (`03-session-prompt-category-eval.md`) re-evaluates the harness after this session ships and Stuart deploys.

### Hard rules (read before touching anything)

1. **You MUST work on a NEW branch `feat/ai-chat-category-tools`, branched from `dev`.** NOT branched from `feat/ai-chat-harness-eval`. The two branches are intentionally independent and Stuart will deploy and merge them separately.

   ```bash
   cd ~/Dev/getinsync-nextgen-ag
   git fetch origin
   git checkout dev
   git pull origin dev
   git checkout -b feat/ai-chat-category-tools
   git branch --show-current  # MUST output: feat/ai-chat-category-tools
   ```

2. **You MAY only edit two files:**
   - `supabase/functions/ai-chat/tools.ts`
   - `supabase/functions/ai-chat/system-prompt.ts`

3. **You MUST NOT edit:**
   - `supabase/functions/ai-chat/index.ts` (orchestration is fine as-is)
   - `supabase/functions/ai-chat/types.ts`
   - any database schema, migrations, or views (no schema changes — query existing tables directly)
   - any file in `docs-architecture/`
   - any file outside `supabase/functions/ai-chat/`

4. **You MUST NOT touch the `feat/ai-chat-harness-eval` branch.** That branch carries Batch 2 (rationalization, temporal, classification refusals) and ships independently. Do not check it out, do not rebase against it, do not cherry-pick from it. The two branches will eventually converge through `dev`.

5. **You MUST NOT add new dependencies, imports, or types.** Use what's already in `tools.ts`. The new tools follow the same shape as existing tools — `executeFooBar(toolUseId, namespaceId, userToken, input)` returning `Promise<ToolResultContent>`.

6. **You MUST use the JWT-scoped Supabase client** (`createUserClient(userToken)`) for every new query. RLS enforcement is non-negotiable. Do NOT use the admin client.

7. **You MUST run `npx tsc --noEmit` before committing** and it must pass with zero errors.

8. **You MUST verify Session 1 data is loaded before starting** (Step 2 below). If Riverside has 0 category assignments, the new tools will return empty results during your dev verification and you won't know whether the code is broken or the data is missing. STOP and tell Stuart if Session 1's verifier passed but the data isn't visible.

9. **You MUST NOT deploy the Edge Function.** Stuart deploys with `supabase functions deploy ai-chat` after the branch is pushed.

10. **You MUST NOT merge `feat/ai-chat-category-tools` to `dev`.** Session 3 re-eval ships first, then Stuart decides on merge.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/application-categories/README.md
   - Tracker, schema reference, Riverside category catalog (14 rows).
   - Pay attention to the schema reference and the catalog table —
     you will reference both code and name in tool descriptions.

2. docs-architecture/planning/application-categories/01-session-prompt-riverside-category-data.md
   - Session 1 brief (the data session). Read this so you know what
     state Riverside is in by the time your session runs.

3. supabase/functions/ai-chat/tools.ts (entire file, ~790 lines)
   - Read every existing TOOL_DEFINITION and executeTool case.
   - Note the existing list-workspaces and list-applications shapes —
     you will mirror them.
   - Note the createUserClient(userToken) helper and the truncate()
     helper. Use both.

4. supabase/functions/ai-chat/system-prompt.ts (entire file, ~160 lines)
   - Read the current ## Available tools list and the ## Tool selection
     rules section. You will add to both.
   - Note the structure: each tool selection rule is a ### subheading
     with a paragraph and bullets. Mirror this format.

5. docs-architecture/planning/ai-chat-harness-optimization/11-session-prompt-batch-2-system-prompt.md
   - The Batch 2 brief that runs in parallel on feat/ai-chat-harness-eval.
   - Read this so you know what subheadings Batch 2 is adding under
     Tool selection rules. Your subheading must NOT collide with the
     names Batch 2 is adding (Rationalization, Temporal, Data classification).
     Your new subheading is "Capability and category questions" — distinct
     from all of Batch 2's subheadings.
   - You do NOT need to coordinate or rebase. The two branches will
     converge through dev later. Just don't pick a colliding name.

6. CLAUDE.md (at repo root)
   - Read "Architecture Rules", "Database Access", and "What You Must NOT Do".
```

You do NOT need to use `DATABASE_READONLY_URL` for SQL discovery — the tables you query are simple (`application_categories`, `application_category_assignments`, `applications`, `workspaces`) and their schemas are documented in the README. But you MAY use it to confirm Session 1's data landed (Step 2).

### Step 2 — Verify Session 1 data is loaded

Run this read-only query to confirm Riverside has category assignments before you start coding:

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)

psql "$DATABASE_READONLY_URL" -c "
SELECT
  (SELECT COUNT(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_apps,
  (SELECT COUNT(DISTINCT aca.application_id) FROM application_category_assignments aca
    JOIN applications a ON a.id = aca.application_id
    JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS apps_with_categories,
  (SELECT COUNT(*) FROM application_category_assignments aca
    JOIN applications a ON a.id = aca.application_id
    JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_assignments;
"
```

Expected: `total_apps = 32`, `apps_with_categories = 32`, `total_assignments >= 32` (will be ~50-80 if multi-category assignments are common).

If `apps_with_categories = 0`, STOP. Session 1 has not been deployed yet — tell Stuart "Session 1's SQL chunks have not been pasted into the SQL Editor yet, please run those first" and exit.

### Step 3 — Implement the three tool changes

Edit `supabase/functions/ai-chat/tools.ts`. Three changes, in this order:

#### 3.1 — Add `list-application-categories` to TOOL_DEFINITIONS

Insert into `TOOL_DEFINITIONS` array after the existing `list-workspaces` entry (the file already has this entry):

```typescript
{
  name: 'list-application-categories',
  description:
    'List all application categories in the namespace catalog with their codes, names, descriptions, and current app count per category. Use this to discover what capability categories exist before drilling in. Each application can belong to MULTIPLE categories (M:M). Use for "what categories exist", "what is my portfolio capability map", or as a discovery step before calling list-applications with a category filter.',
  input_schema: {
    type: 'object',
    properties: {},
  },
},
```

#### 3.2 — Add `category` parameter to existing `list-applications` TOOL_DEFINITION

Find the existing `list-applications` entry in `TOOL_DEFINITIONS`. Add a new property `category` to its `input_schema.properties`:

```typescript
category: {
  type: 'string',
  description: 'Optional category filter — accepts either the category code (e.g. "CRM", "FINANCE", "GIS_SPATIAL") or the category name (e.g. "CRM & Citizen Services", "Finance & Accounting"). Case-insensitive partial match. Use list-application-categories first if you do not know the available codes.',
},
```

Do NOT change the description of `list-applications` itself, do not reorder existing properties, do not remove the existing `criticality_min` / `tech_health_max` / `time_quadrant` / `paid_action` / `limit` / `workspace_name` properties.

#### 3.3 — Add `category-rollup` to TOOL_DEFINITIONS

Insert after `list-application-categories` (or after `list-applications` — your choice, but keep the category-related tools clustered together for readability):

```typescript
{
  name: 'category-rollup',
  description:
    'Aggregate breakdown of the portfolio by application category. Returns ONE row per category with: app_count (apps assigned), assessed_count (apps with both criticality and tech_health), crown_jewel_count (apps with criticality >= 50), total_run_rate (sum of run rates across assigned apps). Sorted by app_count descending. Use for "show me my portfolio by capability", "which categories have the most apps", "which capability area carries the most cost or technical debt", or "where is my portfolio investment concentrated". Apps in multiple categories are counted in EACH category they belong to — totals across categories will exceed total app count.',
  input_schema: {
    type: 'object',
    properties: {},
  },
},
```

### Step 4 — Implement the three executors

Add three new functions to `tools.ts` (and three new cases to the `executeTool` switch). Place them in the same area as `executeListApplications` and `executeTechnologyRisk`.

#### 4.1 — `executeListApplicationCategories`

```typescript
async function executeListApplicationCategories(
  toolUseId: string,
  namespaceId: string,
  userToken: string,
): Promise<ToolResultContent> {
  const client = createUserClient(userToken);

  // Fetch active categories
  const { data: catData, error: catErr } = await client
    .from('application_categories')
    .select('id, code, name, description, display_order')
    .eq('namespace_id', namespaceId)
    .eq('is_active', true)
    .order('display_order');

  if (catErr) throw new Error(`Categories query failed: ${catErr.message}`);

  const categories = (catData || []) as Array<{
    id: string;
    code: string;
    name: string;
    description: string | null;
    display_order: number;
  }>;

  if (categories.length === 0) {
    return { type: 'tool_result', tool_use_id: toolUseId, content: 'No application categories defined for this namespace.' };
  }

  // Fetch app counts per category, scoped to namespace via junction → app → workspace
  const catIds = categories.map((c) => c.id);
  const { data: countData, error: countErr } = await client
    .from('application_category_assignments')
    .select('category_id, applications!inner(workspace_id, workspaces!inner(namespace_id))')
    .in('category_id', catIds);

  if (countErr) throw new Error(`Category assignment counts query failed: ${countErr.message}`);

  // Filter to assignments where the app's workspace namespace matches
  const counts: Record<string, number> = {};
  for (const row of (countData || []) as Array<{ category_id: string; applications: { workspaces: { namespace_id: string } } }>) {
    if (row.applications?.workspaces?.namespace_id === namespaceId) {
      counts[row.category_id] = (counts[row.category_id] || 0) + 1;
    }
  }

  const lines: string[] = ['## Application Categories', ''];
  for (const cat of categories) {
    const count = counts[cat.id] || 0;
    lines.push(`- **${cat.name}** (\`${cat.code}\`): ${count} application${count !== 1 ? 's' : ''}`);
    if (cat.description) lines.push(`  _${cat.description}_`);
  }
  lines.push('', `**Total categories:** ${categories.length}`);

  return { type: 'tool_result', tool_use_id: toolUseId, content: truncate(lines.join('\n')) };
}
```

#### 4.2 — Modify `executeListApplications` to honor the new `category` filter

Find the existing `executeListApplications` function. After the `paidAction` extraction, add:

```typescript
const categoryFilter = (input.category as string) || '';
```

Resolve the category to an ID (similar to how the function already resolves `workspaceName`):

```typescript
let categoryId: string | null = null;
let resolvedCategoryName = '';
if (categoryFilter) {
  // Try exact code match first, then partial name match
  let { data: catData } = await client
    .from('application_categories')
    .select('id, name, code')
    .eq('namespace_id', namespaceId)
    .eq('is_active', true)
    .ilike('code', categoryFilter)
    .limit(1)
    .maybeSingle();

  if (!catData) {
    const { data: nameMatch } = await client
      .from('application_categories')
      .select('id, name, code')
      .eq('namespace_id', namespaceId)
      .eq('is_active', true)
      .ilike('name', `%${categoryFilter}%`)
      .limit(1)
      .maybeSingle();
    catData = nameMatch;
  }

  if (!catData) {
    return {
      type: 'tool_result',
      tool_use_id: toolUseId,
      content: `No category found matching "${categoryFilter}". Use the list-application-categories tool to see available categories.`,
    };
  }
  categoryId = catData.id;
  resolvedCategoryName = catData.name;
}
```

When `categoryId` is non-null, the existing query against `vw_explorer_detail` cannot directly filter by category (the view does not have a category column). Instead, fetch the app IDs for that category first via the junction table, then add an `.in('application_id', appIds)` predicate to the main query. The `vw_explorer_detail` view exposes `application_id`, so this works:

```typescript
let categoryAppIds: string[] | null = null;
if (categoryId) {
  const { data: assignmentRows, error: assignmentErr } = await client
    .from('application_category_assignments')
    .select('application_id')
    .eq('category_id', categoryId);

  if (assignmentErr) throw new Error(`Category assignment query failed: ${assignmentErr.message}`);

  categoryAppIds = ((assignmentRows || []) as Array<{ application_id: string }>).map((r) => r.application_id);

  if (categoryAppIds.length === 0) {
    return {
      type: 'tool_result',
      tool_use_id: toolUseId,
      content: `## Applications (filtered: category=${resolvedCategoryName})\n\nNo applications are assigned to this category yet.`,
    };
  }
}
```

Then in the existing query builder, add (right after the existing `if (paidAction) query = query.eq('paid_action', paidAction);` line):

```typescript
if (categoryAppIds) query = query.in('application_id', categoryAppIds);
```

And add the resolved category name to the existing `filters` array used for the heading:

```typescript
if (resolvedCategoryName) filters.push(`category=${resolvedCategoryName}`);
```

**Important:** Verify by re-reading the existing `executeListApplications` function that the view `vw_explorer_detail` is selected with at least `application_id` in its column list — if not, add `application_id` to the `.select(...)` so the `.in('application_id', ...)` predicate works. Most existing list tools select `application_name` etc. but not necessarily `application_id`. Add the column if needed; do not remove any existing column.

#### 4.3 — `executeCategoryRollup`

```typescript
async function executeCategoryRollup(
  toolUseId: string,
  namespaceId: string,
  userToken: string,
): Promise<ToolResultContent> {
  const client = createUserClient(userToken);

  // Fetch active categories
  const { data: catData, error: catErr } = await client
    .from('application_categories')
    .select('id, code, name, display_order')
    .eq('namespace_id', namespaceId)
    .eq('is_active', true)
    .order('display_order');

  if (catErr) throw new Error(`Categories query failed: ${catErr.message}`);

  const categories = (catData || []) as Array<{ id: string; code: string; name: string; display_order: number }>;
  if (categories.length === 0) {
    return { type: 'tool_result', tool_use_id: toolUseId, content: 'No application categories defined for this namespace.' };
  }

  // Fetch all assignments with the joined application metrics from vw_explorer_detail
  // Strategy: fetch assignments scoped to this namespace (via app→workspace join), then
  // fetch metric rows from vw_explorer_detail and join in memory.
  const { data: assignRows, error: assignErr } = await client
    .from('application_category_assignments')
    .select('category_id, application_id, applications!inner(workspace_id, workspaces!inner(namespace_id))')
    .returns<Array<{ category_id: string; application_id: string; applications: { workspaces: { namespace_id: string } } }>>();

  if (assignErr) throw new Error(`Category assignments query failed: ${assignErr.message}`);

  const nsAssignments = (assignRows || []).filter((r) => r.applications?.workspaces?.namespace_id === namespaceId);

  if (nsAssignments.length === 0) {
    return {
      type: 'tool_result',
      tool_use_id: toolUseId,
      content: '## Portfolio by Category\n\nNo applications are assigned to any category yet. Use the application form to assign categories to apps.',
    };
  }

  // Get the set of unique app IDs assigned to any category, fetch their metrics
  const appIds = Array.from(new Set(nsAssignments.map((r) => r.application_id)));

  const { data: metricRows, error: metricErr } = await client
    .from('vw_explorer_detail')
    .select('application_id, criticality, tech_health, total_run_rate, is_crown_jewel')
    .eq('namespace_id', namespaceId)
    .in('application_id', appIds);

  if (metricErr) throw new Error(`App metrics query failed: ${metricErr.message}`);

  // Index metrics by app_id
  const metrics: Record<string, { criticality: number | null; tech_health: number | null; total_run_rate: number | null; is_crown_jewel: boolean }> = {};
  for (const m of (metricRows || []) as Array<Record<string, unknown>>) {
    metrics[m.application_id as string] = {
      criticality: m.criticality !== null && m.criticality !== undefined ? Number(m.criticality) : null,
      tech_health: m.tech_health !== null && m.tech_health !== undefined ? Number(m.tech_health) : null,
      total_run_rate: m.total_run_rate !== null && m.total_run_rate !== undefined ? Number(m.total_run_rate) : null,
      is_crown_jewel: !!m.is_crown_jewel,
    };
  }

  // Roll up per category
  type Rollup = { app_count: number; assessed_count: number; crown_jewel_count: number; total_run_rate: number };
  const rollups: Record<string, Rollup> = {};
  for (const cat of categories) {
    rollups[cat.id] = { app_count: 0, assessed_count: 0, crown_jewel_count: 0, total_run_rate: 0 };
  }
  for (const r of nsAssignments) {
    const ru = rollups[r.category_id];
    if (!ru) continue;
    const m = metrics[r.application_id];
    ru.app_count += 1;
    if (m) {
      if (m.criticality !== null && m.tech_health !== null) ru.assessed_count += 1;
      if (m.is_crown_jewel) ru.crown_jewel_count += 1;
      if (m.total_run_rate !== null) ru.total_run_rate += m.total_run_rate;
    }
  }

  // Build rows sorted by app_count descending, then by display_order
  const rows = categories
    .map((c) => ({ cat: c, ...rollups[c.id] }))
    .filter((r) => r.app_count > 0)
    .sort((a, b) => b.app_count - a.app_count || a.cat.display_order - b.cat.display_order);

  const lines: string[] = ['## Portfolio by Category', ''];
  lines.push('| Category | Apps | Assessed | Crown Jewels | Run Rate |');
  lines.push('|----------|------|----------|--------------|----------|');
  for (const r of rows) {
    lines.push(
      `| **${r.cat.name}** (\`${r.cat.code}\`) | ${r.app_count} | ${r.assessed_count} | ${r.crown_jewel_count} | $${formatCurrency(r.total_run_rate)} |`,
    );
  }
  lines.push('', `_Note: applications can belong to multiple categories. Counts in this table sum across categories — total > unique app count is expected._`);

  return { type: 'tool_result', tool_use_id: toolUseId, content: truncate(lines.join('\n')) };
}
```

#### 4.4 — Wire the new tools into `executeTool`

In the `executeTool` switch statement, add three new cases:

```typescript
case 'list-application-categories':
  return await executeListApplicationCategories(id, namespaceId, userToken);
case 'category-rollup':
  return await executeCategoryRollup(id, namespaceId, userToken);
```

(Note: `list-applications` is already wired — you only added a parameter to its existing executor, not a new case.)

### Step 5 — Update the system prompt

Edit `supabase/functions/ai-chat/system-prompt.ts`. Two changes:

#### 5.1 — Add the new tools to `## Available tools`

Find the existing numbered list under `## Available tools`. Add two new entries (one for `list-application-categories`, one for `category-rollup`) and update the existing `list-applications` entry to mention the new `category` parameter. Keep the numbering tidy.

The existing entries you must not modify the SUBSTANCE of: portfolio-summary, cost-analysis, application-detail, technology-risk, list-workspaces, roadmap-status, data-quality. You may renumber them as you insert new entries — that's fine — but do not change their descriptions.

For the new entries:

```
N. **list-application-categories** — Returns the namespace's application category catalog (e.g. CRM & Citizen Services, Finance & Accounting, GIS & Spatial). Each entry has a code, name, description, and current app count. Use this to discover what categories exist before drilling in. Apps can belong to MULTIPLE categories.

N+1. **category-rollup** — Aggregate portfolio breakdown by application category. Returns one row per category with app count, assessed count, crown jewel count, and total run rate. Sorted by app count descending. Use for "what does my portfolio look like by capability", "which categories carry the most apps/cost/risk". Apps in multiple categories are counted in each — totals across categories exceed total app count.
```

For the `list-applications` entry, add a sentence at the end of its existing description:

```
... [existing description text] Now also accepts an optional `category` parameter (code or name) to filter by application category — see list-application-categories for the available catalog.
```

#### 5.2 — Add a new subheading under `## Tool selection rules`

Insert a new subheading `### Capability and category questions` after the existing `### Workspace-scoped questions` subheading (or wherever feels structurally consistent — but NOT between Risk and Analytical framework, because Batch 2 on the parallel branch is inserting subheadings in that gap and you should avoid colliding with Batch 2's space).

The text:

> When the user asks "what do I have for [capability]" — e.g. "what apps do we have for CRM?", "which applications handle Human Resources?", "what GIS systems do we run?" — discover the catalog first, then drill in:
>
> 1. Call **list-application-categories** to see the available categories and pick the one matching the user's intent. Match by name OR by description — "Customer Relationship Management" maps to the CRM category, "mapping" maps to GIS_SPATIAL, "general ledger" maps to FINANCE.
> 2. Call **list-applications** with the matching `category` parameter (use the category code, e.g. `CRM`, `FINANCE`, `GIS_SPATIAL`) and any relevant additional filters (e.g. `workspace_name`).
> 3. If the user asks "show me my portfolio by capability", "which categories carry the most apps/cost/risk", or "where is my portfolio concentrated", call **category-rollup** instead — it returns the full breakdown in one call.
>
> Applications can belong to multiple categories. Do NOT assume a one-to-one mapping. Do NOT confuse CAPABILITY questions ("what apps do we have for X") with DATA CLASSIFICATION questions ("which apps handle PII") — capability questions get the category tools; data classification questions get refused (the harness has no data classification tool).
>
> **Cross-tool orchestration:** category-rollup composes well with other tools. "Which application category carries the most technical debt?" → call category-rollup AND technology-risk, then synthesize. "Which workspace has the most application sprawl, and what categories are over-represented there?" → call list-workspaces, list-applications per workspace, AND category-rollup. Do not stop at a single tool when a real EA question requires combining category data with risk, cost, or workspace signals.

### Step 6 — Verify and commit

1. Run `npx tsc --noEmit` from the repo root. Zero errors required. Common failure modes:
   - The `.returns<...>()` generic on the assignments query may need adjustment if the Supabase client types reject the inline workspace join shape. If TypeScript complains, simplify by querying the assignments without the inner join and instead pre-fetching the namespace's app IDs first.
   - Template literal escaping in `system-prompt.ts` — backticks for inline code spans must be escaped as `\\\``.

2. Run `git status` and confirm only `supabase/functions/ai-chat/tools.ts` and `supabase/functions/ai-chat/system-prompt.ts` are modified. Nothing else.

3. Run `git diff --stat` to sanity-check the scope.

4. Smoke-test the new tool shapes with a quick read-only DB check (no Edge Function call):

   ```bash
   psql "$DATABASE_READONLY_URL" -c "
     SELECT ac.name, COUNT(aca.id) AS apps
     FROM application_categories ac
     LEFT JOIN application_category_assignments aca ON aca.category_id = ac.id
     LEFT JOIN applications a ON a.id = aca.application_id
     LEFT JOIN workspaces w ON w.id = a.workspace_id
     WHERE ac.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
       AND ac.is_active = true
       AND (aca.id IS NULL OR w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
     GROUP BY ac.name, ac.display_order
     ORDER BY ac.display_order;
   "
   ```

   Confirm the per-category counts look reasonable for the data Session 1 loaded. This is the same shape `category-rollup` will return.

5. Commit with a HEREDOC message:

```bash
git add supabase/functions/ai-chat/tools.ts supabase/functions/ai-chat/system-prompt.ts

git commit -m "$(cat <<'EOF'
feat: AI Chat category tools — list-application-categories, category filter, category-rollup

Adds three new category-aware capabilities to the AI Chat Edge Function
to surface application_category data through the harness:

- list-application-categories: discoverability tool returning the
  per-namespace catalog with app counts per category. Mirrors
  list-workspaces shape.
- category filter on list-applications: optional `category` parameter
  (accepts code or partial name) joins through application_category_assignments
  to filter results to apps in the matching category.
- category-rollup: aggregate breakdown returning one row per category
  with app_count, assessed_count, crown_jewel_count, total_run_rate.
  Sorted by app_count desc.

System prompt updated with a new "Capability and category questions"
subheading under Tool selection rules, including guidance on cross-tool
orchestration (combining category-rollup with technology-risk for
"which categories carry the most tech debt", or with list-workspaces
for "which workspace has the most application sprawl by category").

No view changes, no schema changes, no index.ts changes. All new
queries use the JWT-scoped Supabase client (RLS enforced).

Branched from dev (NOT from feat/ai-chat-harness-eval). The Batch 2
prompt rewrite on feat/ai-chat-harness-eval is independent and ships
on its own deploy. Stuart deploys this branch separately.

Next: Stuart deploys with `supabase functions deploy ai-chat`, runs
the Session 3 eval (15 queries: 10 Batch 1 regression + 5 new
category + 2 cross-tool), produces 10-eval-results-category-tools.md.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"

git push -u origin feat/ai-chat-category-tools
```

### Step 7 — Session summary

Produce a short final message listing:

1. Confirmation that `npx tsc --noEmit` passed with zero errors
2. The lines added to `tools.ts` and `system-prompt.ts` (use `git diff --stat`)
3. The three new tool names in the order they were inserted
4. Confirmation that no existing tool description, executor, or system prompt rule was modified beyond the documented additions
5. Confirmation that `index.ts`, `types.ts`, and the `feat/ai-chat-harness-eval` branch are untouched
6. The smoke-test SQL output showing per-category app counts (so Stuart can sanity check before deploying)
7. A one-line summary of next steps:
   *"Ready for Stuart to deploy: `cd ~/Dev/getinsync-nextgen-ag && supabase functions deploy ai-chat` (with feat/ai-chat-category-tools checked out). Then run the 15 eval queries (10 from Batch 1 + 5 new + 2 cross-tool) into fresh conversations titled 'Eval Categories YYYY-MM-DD A' and 'Eval Categories YYYY-MM-DD B'. Then run Session 3 (`03-session-prompt-category-eval.md`) to produce the results doc."*

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] Branch `feat/ai-chat-category-tools` created from `dev` (NOT from `feat/ai-chat-harness-eval`)
- [ ] `git branch --show-current` confirms `feat/ai-chat-category-tools`
- [ ] Step 2 verification passed (Riverside has 32 apps with category assignments)
- [ ] `list-application-categories` added to TOOL_DEFINITIONS
- [ ] `category` parameter added to existing `list-applications` TOOL_DEFINITION
- [ ] `category-rollup` added to TOOL_DEFINITIONS
- [ ] `executeListApplicationCategories` function added
- [ ] `executeListApplications` modified to honor the `category` parameter
- [ ] `executeCategoryRollup` function added
- [ ] Three new cases added to the `executeTool` switch (or two if list-applications was already wired)
- [ ] All new queries use `createUserClient(userToken)` — never the admin client
- [ ] System prompt `## Available tools` section updated with new entries (and the list-applications entry mentions the new category parameter)
- [ ] System prompt `## Tool selection rules` section has a new `### Capability and category questions` subheading with the cross-tool orchestration guidance
- [ ] No collision with the Batch 2 subheading names on `feat/ai-chat-harness-eval` (Rationalization, Temporal, Data classification)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `git status` shows only `tools.ts` and `system-prompt.ts` modified
- [ ] Smoke-test SQL produced reasonable per-category counts
- [ ] Branch committed and pushed to origin
- [ ] `feat/ai-chat-harness-eval` branch UNTOUCHED
- [ ] Session summary produced

### What NOT to do

- Do NOT branch from `feat/ai-chat-harness-eval`. Branch from `dev`.
- Do NOT touch `feat/ai-chat-harness-eval` in any way. Do not check it out, rebase against it, or cherry-pick from it.
- Do NOT edit `index.ts` or `types.ts`. The new tools fit the existing tool-use loop and types.
- Do NOT add a new view or modify `vw_explorer_detail`, `vw_dashboard_summary`, or any other view. Query existing tables directly.
- Do NOT add a new database migration, schema change, or column. The schema already supports everything you need.
- Do NOT use the admin Supabase client. All new queries must go through `createUserClient(userToken)` to enforce RLS.
- Do NOT hardcode the Riverside namespace ID. The functions take `namespaceId` as a parameter and pass it through to queries.
- Do NOT use the `Uncategorized` category in any assertion or filter. It exists in the catalog but should be invisible to users — it's the default for unclassified apps. If the catalog query returns it, that's expected; just present it like any other category.
- Do NOT add new dependencies, imports, or types.
- Do NOT change existing tool descriptions beyond the documented additions to `list-applications`.
- Do NOT collide with Batch 2's subheading names. Your new subheading is `### Capability and category questions`.
- Do NOT deploy. Stuart deploys.
- Do NOT merge to `dev`. Session 3 re-eval ships first.
- Do NOT modify any file in `docs-architecture/`. Session 3 will write the results doc there, not this session.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
