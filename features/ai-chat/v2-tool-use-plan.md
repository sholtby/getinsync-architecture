# AI Chat v2 — Tool-Use Upgrade Plan

## Context

The AI Chat MVP is deployed and working (443 entities embedded, streaming responses, backfill complete). However, the AI only sees the **top 10 embedding matches** per query — it cannot answer aggregate/analytical questions like "Who is our largest vendor?", "What individual owns the most apps?", or "What's our total tech debt?" because those require scanning ALL data.

**Solution:** Give Claude **tool-use with database access** — a `query_database` tool that lets it write SELECT queries against the portfolio, scoped to the user's namespace. Combined with the existing `search_portfolio` embedding tool, Claude can answer both specific ("tell me about SAP") and analytical ("rank vendors by spend") questions.

**Branch:** `feat/ai-chat-mvp` (continue existing branch)

---

## Part 1: Database Function (Stuart runs in SQL Editor)

Create `chat_query_portfolio()` — a read-only SQL execution function callable only by service_role.

**SQL to provide Stuart** (save as `scripts/ai-chat-v2-db-setup.sql`):

```sql
CREATE OR REPLACE FUNCTION chat_query_portfolio(
  p_namespace_id uuid,
  p_query text,
  p_max_rows int DEFAULT 50
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- Block non-SELECT queries
  IF p_query ~* '^\s*(insert|update|delete|drop|alter|create|truncate|grant|revoke|copy|execute|call)' THEN
    RAISE EXCEPTION 'Only SELECT queries are allowed';
  END IF;
  -- Block dangerous patterns
  IF p_query ~* '(;|\binto\b.*\bfrom\b|\bcopy\b|\bpg_read_file\b|\bpg_write_file\b)' THEN
    RAISE EXCEPTION 'Query contains disallowed patterns';
  END IF;
  -- Execute with row limit
  EXECUTE format(
    'SELECT COALESCE(jsonb_agg(row_to_json(t)), ''[]''::jsonb) FROM (SELECT * FROM (%s) sub LIMIT %s) t',
    p_query, p_max_rows
  ) INTO v_result;
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION chat_query_portfolio(uuid, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION chat_query_portfolio(uuid, text, int) TO service_role;
```

**Security layers:**
- Function validates SELECT-only + blocks dangerous keywords
- Edge Function validates namespace_id literal appears in SQL
- System prompt instructs Claude to always filter by namespace_id
- Max 50 rows prevents data exfiltration
- Only service_role can call it (end users cannot)

---

## Part 2: Update Types

**File:** `supabase/functions/apm-chat/types.ts`

Add types for Anthropic tool-use API:
- `ToolDefinition` — tool name, description, input_schema
- `ToolUseBlock` — type: 'tool_use', id, name, input
- `TextBlock` — type: 'text', text
- `ToolResultContent` — type: 'tool_result', tool_use_id, content, is_error
- `ClaudeResponse` — id, role, content: ContentBlock[], stop_reason, usage

Existing types (`ApmChatRequest`, `SearchResult`, `ConversationMessage`) unchanged.

---

## Part 3: Rewrite Edge Function (main work)

**File:** `supabase/functions/apm-chat/index.ts`

### New Flow (replaces current embed→search→stream)

1. **Auth** — unchanged (`authenticateRequest(req)`)
2. **Parse request** — unchanged (query, workspace_id, namespace_id, conversation_history)
3. **Define tools** — two tools:
   - `search_portfolio` — existing embedding search (semantic/keyword), best for finding specific entities
   - `query_database` — SQL SELECT via `chat_query_portfolio()` RPC, best for aggregates/rankings/counts
4. **Build system prompt** — expanded with:
   - Schema reference (tables, key columns, relationships, useful views)
   - Current namespace_id injected so Claude includes it in SQL
   - SQL guidelines (SELECT only, always filter namespace_id, use views for aggregations)
   - Forbidden tables (users, auth.users, secrets)
5. **First Claude call** — **non-streaming**, with tools defined
6. **Tool execution loop** (max 3 iterations):
   - If `stop_reason === 'tool_use'`: execute tool(s), send results back, call Claude again
   - `search_portfolio`: generate embedding → call `search_apm()` RPC
   - `query_database`: validate namespace_id in SQL → call `chat_query_portfolio()` RPC
   - Truncate tool results to 4000 chars to prevent token overflow
7. **Stream final response** — extract text from final non-streaming response, emit as SSE chunks (preserves typing animation without extra API call)
8. **Log usage** — fire-and-forget (unchanged)

### Helper Functions to Add

- `executeTool(toolUse, namespaceId, workspaceId, supabaseAdmin)` → ToolResultContent
- `generateEmbedding(text)` → number[] (extracted from current inline code)
- `truncate(text, maxChars)` → string

### Schema Reference in System Prompt

Concise listing of queryable tables/views with key columns:

```
## Direct namespace-scoped tables (WHERE namespace_id = '{ns_id}'):
- software_products (id, name, version, annual_cost, namespace_id, manufacturer_org_id)
- it_services (id, name, annual_cost, namespace_id, service_type_id)
- organizations (id, name, namespace_id)
- contacts (id, display_name, email, namespace_id)

## Workspace-scoped tables (WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '{ns_id}')):
- applications (id, name, app_id, lifecycle_status, annual_cost, workspace_id)
- deployment_profiles (id, name, hosting_type, estimated_tech_debt, application_id, workspace_id)
- portfolio_assignments (application_id, time_quadrant, paid_quadrant, business_fit, criticality)

## Join tables:
- application_contacts (application_id, contact_id, role_type, is_primary)
- deployment_profile_software_products (deployment_profile_id, software_product_id, annual_cost)
- workspace_budgets (workspace_id, fiscal_year, budget_amount)

## Useful views:
- vw_dashboard_summary, vw_workspace_budget_summary, vw_portfolio_costs
- vw_technology_health_summary, vw_dp_lifecycle_risk_combined
```

---

## Part 4: Frontend Updates (minimal)

**File:** `src/components/chat/ApmChatPanel.tsx`

Update `SUGGESTIONS` array only:

```typescript
const SUGGESTIONS = [
  'Who is our largest software vendor by spend?',
  'Which applications have the highest tech debt?',
  'How many apps are in each TIME quadrant?',
  'What are the biggest risks in our portfolio?',
];
```

**No other frontend changes.** The SSE protocol is identical — tool-use happens entirely server-side. The frontend still receives `data: {"text": "..."}\n\n` chunks.

---

## Execution Order

```
Part 1: Stuart runs SQL function         (prerequisite)
Part 2: Update types.ts                  (5 min)
Part 3: Rewrite apm-chat/index.ts        (30 min — bulk of work)
Part 4: Update suggestions               (2 min)
Deploy: supabase functions deploy apm-chat --no-verify-jwt
```

---

## Verification

1. `npx tsc --noEmit` — zero errors
2. Deploy Edge Function
3. Test analytical queries:
   - "Who is our largest vendor?" → should use `query_database` tool
   - "Tell me about SAP" → should use `search_portfolio` tool
   - "How many apps per workspace?" → should use `query_database`
   - "Generate a SWOT" → may use both tools
4. Check Supabase Edge Function logs — verify tool calls execute without errors
5. Verify streaming still works (typing animation)
6. Verify namespace isolation — queries should only return current namespace's data

---

## Architecture Doc Updates

After completion, update:
- `docs-architecture/features/ai-chat/mvp.md` — note v2 tool-use upgrade
- `docs-architecture/guides/whats-new.md` — append changelog entry
- `docs-architecture/MANIFEST.md` — bump version

---

## Key Files

| File | Change |
|------|--------|
| `supabase/functions/apm-chat/index.ts` | **Major rewrite** — tool-use flow |
| `supabase/functions/apm-chat/types.ts` | Add tool types |
| `src/components/chat/ApmChatPanel.tsx` | Update suggestions array |
| `scripts/ai-chat-v2-db-setup.sql` | **New** — SQL for Stuart to run |

## Latency Note

Tool-use adds round-trips. A query needing 2 tool calls = 3 Claude API calls. Expected: 5-10 seconds vs current 2-3. The chunked SSE output makes the wait less noticeable once streaming begins.
