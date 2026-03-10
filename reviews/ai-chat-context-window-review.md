# AI Chat — Context Window & Conversation Lifecycle Review

> **Status:** 🟡 REVIEW
> **Date:** 2026-03-09
> **Subject:** AI Chat architecture across MVP (v1.0), v2, and v3-multicloud
> **Author:** Claude Code (research session)

---

## Purpose

Cross-reference the three AI Chat architecture documents against the Edge Functions layer (§15 MCP tools, §15.4 handoff contract) and Global Search (§10 progressive upgrade path) to assess readiness in two areas:

1. **Context window management** — how context is budgeted, truncated, and counted
2. **Conversation lifecycle** — how conversations are stored, scoped, retained, and resumed

## Documents Reviewed

| Document | Version | Key Content |
|----------|---------|-------------|
| `features/ai-chat/mvp.md` | v1.0 | MVP blueprint: Edge Function, hybrid search, SSE streaming, React panel |
| `features/ai-chat/v2.md` | — | Query intent classifier, SWOT analysis, richer content builders |
| `features/ai-chat/v3-multicloud.md` | v3.0 | Provider Abstraction Layer (Supabase/Azure/AWS), namespace AI settings |
| `infrastructure/edge-functions-layer-architecture.md` | v1.2 | §15 MCP tools, §15.4 search-to-chat handoff contract |
| `features/global-search/architecture.md` | v1.1 | §10 progressive upgrade path, §10.3 search-to-chat UX |

---

## 1. Architecture Summary

### MVP (v1.0)

- **Data flow:** React → `POST /functions/v1/apm-chat` → embed query (OpenAI `text-embedding-3-small`) → hybrid search (`search_apm` RPC: pgvector cosine + full-text + RRF) → build prompt with context → call Claude → SSE stream response
- **Search pattern:** Hybrid — vector similarity + full-text search combined via Reciprocal Rank Fusion, namespace-scoped
- **Entity types in embeddings:** 4 (application, deployment_profile, software_product, it_service)
- **Embedding model:** OpenAI `text-embedding-3-small`, 1536 dimensions
- **LLM:** Claude (`claude-sonnet-4-20250514`), `max_tokens: 2048`
- **Streaming:** SSE via `ReadableStream` encoder
- **Usage tracking:** `apm_chat_usage` table (query count per namespace per day, NOT conversation content)
- **Auth:** `auth.getUser()` — deprecated pattern (see edge functions §6.5)

### v2

- **Additions over MVP:** Query intent classifier (swot, assessment_status, budget, general), `generateWorkspaceSwot()` structured analysis, richer content builders with T-score summaries and IT service consumer/provider relationships
- **Search pattern:** Vector-only (`search_apm_context` RPC), not hybrid — a regression from MVP's hybrid approach
- **Entity types in embeddings:** 6 (adds technology_product, portfolio_assignment)
- **LLM:** Same Claude model, same `max_tokens: 2048`
- **Auth:** Same deprecated `auth.getUser()` pattern

### v3 — Multi-Cloud

- **Provider Abstraction Layer:** `ApmAiProvider` interface with factory `getProviderForNamespace()`
- **Three providers:** Supabase (pgvector + Claude), Azure (AI Search + OpenAI), AWS (OpenSearch + Bedrock)
- **Namespace-level config:** `namespace_ai_settings` table with `chat_enabled`, `ai_provider_config`, `monthly_chat_limit`, `current_month_usage`
- **Hybrid search restored:** Supabase provider uses vector + FTS with optional Cohere reranking
- **Data sync:** `pg_notify` → Edge Function worker → provider-specific storage (Azure AI Search index, AWS OpenSearch index)
- **LLM:** All providers use `max_tokens: 2048`
- **Auth:** Same deprecated `auth.getUser()` pattern (line 1521)

---

## 2. Context Window Strategy

### Current State: No Strategy Documented

None of the three documents define a context window budget or token management approach. The following table shows what each version does:

| Aspect | MVP | v2 | v3 |
|--------|-----|----|----|
| **Response token limit** | `max_tokens: 2048` | `max_tokens: 2048` | `max_tokens: 2048` (all providers) |
| **System prompt size** | Unbounded — built dynamically from RAG results | Unbounded — larger with intent-specific templates | Unbounded — varies by provider |
| **RAG context injection** | Top-N search results joined as text, injected into system prompt | Same pattern, richer per-entity content builders | Same pattern, provider-specific search |
| **History truncation** | `conversation_history.slice(-10)` (Edge Function) + `messages.slice(-10)` (frontend) | Full history passed — no truncation in Edge Function | `messages.slice(-10)` (frontend only) |
| **Token counting** | None | None | None |
| **Budget allocation** | None | None | None |

### Risk

Claude's context window is large but finite. Without budget allocation, the system prompt + RAG context + conversation history + user query can silently exceed limits. Current mitigations are accidental (the `slice(-10)` cap in MVP) rather than intentional.

The most likely failure mode: a long conversation with rich RAG context causes the total input to approach the model's context limit, degrading response quality as earlier context gets crowded out, with no visibility into why answers deteriorate.

---

## 3. Conversation Lifecycle

### Storage: Client-Side Only

All three versions store conversation history exclusively in React component state (`useState<Message[]>([])`). No database table exists for conversation content.

| Aspect | MVP | v2 | v3 |
|--------|-----|----|----|
| **Storage location** | React `useState` | React `useState` | React `useState` |
| **Database persistence** | None | None (checklist item: "Add conversation history persistence (optional)" — unchecked) | None |
| **What IS persisted** | `apm_chat_usage`: query count per namespace/day | Same `apm_chat_usage` | `apm_chat_usage` + `namespace_ai_settings.current_month_usage` |

### Scoping

Conversations are implicitly scoped to a namespace (via JWT) and optionally filtered by `workspace_id`. There is no conversation-level scoping model — no conversation ID, no thread concept, no multi-conversation support.

### Retention

Conversations are lost on:
- Page refresh
- Tab close
- Navigation away from the chat panel
- Session expiry

No conversation survives beyond the current browser tab's lifecycle.

### Resumption

Not possible. There is no mechanism to resume a prior conversation. Each page load starts a fresh, empty conversation.

---

## 4. Version Progression

| Capability | MVP (v1.0) | v2 | v3 |
|-----------|------------|----|----|
| Entity types | 4 | 6 | 6 (per-provider synced) |
| Search method | Hybrid (vector + FTS + RRF) | Vector-only | Hybrid restored (provider-specific) |
| Intent classification | None | 4 intents (swot, assessment_status, budget, general) | Inherited from v2 |
| Structured analysis | None | SWOT generation | SWOT generation |
| Provider support | Supabase only | Supabase only | Supabase / Azure / AWS |
| Namespace config | None | None | `namespace_ai_settings` table |
| Usage limits | Per-day counter | Per-day counter | Monthly limit with enforcement |
| History truncation | `slice(-10)` both ends | No truncation (Edge Function) | `slice(-10)` frontend only |
| Conversation persistence | None | None (optional, unchecked) | None |
| Token counting | None | None | None |
| Context budget | None | None | None |
| Auth pattern | `auth.getUser()` | `auth.getUser()` | `auth.getUser()` |
| Streaming | SSE | SSE | SSE |
| Model | Claude Sonnet | Claude Sonnet | Claude/OpenAI/Bedrock (per provider) |

### Observation

The version progression adds breadth (more entity types, intent classification, multi-cloud) but does not deepen the context management or conversation lifecycle. All three versions share the same fundamental limitations: no persistence, no token awareness, no context budgeting.

---

## 5. Alignment with Edge Functions Layer

### §15.3 MCP Tool Registry vs RAG Pattern

The Edge Functions doc (v1.2 §15.3) defines 6 MCP tools for AI Chat:

| MCP Tool | Description |
|----------|-------------|
| `search_portfolio` | Wraps `global_search` RPC (12 entity types) |
| `get_application_detail` | Application + DPs + scores |
| `get_lifecycle_risk` | Technology EOL status |
| `get_cost_summary` | Run rate by vendor/workspace |
| `get_integration_map` | Upstream/downstream integrations |
| `get_assessment_status` | Assessment completion |

**All three AI Chat docs use a fundamentally different pattern:** embed the user query → search an embeddings table → stuff matching content into the system prompt → let Claude reason over it. This is classic RAG (Retrieval-Augmented Generation).

The MCP tool pattern gives Claude explicit tools to call (tool-use API), letting the model decide what data to fetch. These are architecturally different approaches:

| Dimension | RAG (AI Chat docs) | MCP Tools (Edge Functions §15) |
|-----------|--------------------|---------------------------------|
| Data retrieval | Automatic — search runs before Claude sees the query | On-demand — Claude decides which tools to call |
| Context control | All-or-nothing: top-N results injected | Selective: Claude calls only relevant tools |
| Token efficiency | Potentially wasteful (irrelevant results in context) | More efficient (fetch only what is needed) |
| Implementation maturity | Documented with code in all 3 versions | Defined in registry only, no implementation in AI Chat docs |

**No document reconciles these two approaches.** The AI Chat docs do not reference MCP tools. The Edge Functions doc defines MCP tools assuming AI Chat will use them, but the AI Chat docs predate the MCP registry.

### §15.4 Search-to-Chat Handoff Contract

The Edge Functions doc (v1.2 §15.4) defines an `AiChatRequest` interface with:
- `conversationId?: string` — for multi-turn conversation tracking
- `searchContext?: { originalQuery, results, selectedEntityType }` — for Global Search handoff

**Neither field is implemented in any AI Chat doc.** The `conversationId` concept has no backing storage. The `searchContext` handoff is described in Global Search §10.3 (UI behavior) but the AI Chat Edge Function does not accept or use it.

---

## 6. Gaps and Recommendations

| # | Severity | Gap | Source |
|---|----------|-----|--------|
| 1 | **HIGH** | **No context window budget.** System prompt, RAG context, conversation history, and response tokens all compete for the same context window with no allocation, measurement, or overflow handling. Risk of silent quality degradation in long conversations. | All 3 AI Chat docs |
| 2 | **HIGH** | **No conversation persistence.** History lives in React `useState` only. Lost on refresh, navigation, or tab close. No audit trail, no resumption, no analytics on conversation content. The v2 checklist marks this as "optional" — it should be mandatory for production. | All 3 AI Chat docs |
| 3 | **HIGH** | **No token counting or estimation.** No version estimates token usage for system prompt, context, or history. The `max_tokens: 2048` response limit is the only token-aware parameter. Without counting, there is no basis for budget allocation or overflow prevention. | All 3 AI Chat docs |
| 4 | **HIGH** | **RAG vs MCP architectural mismatch.** AI Chat docs use embed→search→stuff-context pattern. Edge Functions §15.3 defines 6 MCP tools assuming tool-use integration. No document reconciles these approaches, defines a migration path, or states which pattern AI Chat will use at build time. | AI Chat docs vs Edge Functions v1.2 §15 |
| 5 | **MEDIUM** | **Inconsistent truncation across versions.** MVP truncates to 10 messages (both frontend and Edge Function). v2 passes full history with no limit. v3 truncates at the frontend only. No version documents why 10 was chosen or what the maximum safe history size is. | MVP §5 vs v2 §chat endpoint vs v3 §frontend |
| 6 | **MEDIUM** | **`AiChatRequest` contract not adopted.** Edge Functions §15.4 defines `conversationId` and `searchContext` fields. No AI Chat doc implements either. The handoff from Global Search to AI Chat has no Edge Function-level contract. | Edge Functions v1.2 §15.4 vs AI Chat docs |
| 7 | **MEDIUM** | **Deprecated auth pattern in all versions.** All 3 AI Chat docs use `auth.getUser(token)` which makes a network round-trip and causes intermittent 401s. Edge Functions §6.2 documents the replacement (`jose` JWKS local verification). AI Chat docs need updating. | Edge Functions v1.2 §6.2/§6.5 vs all AI Chat docs |
| 8 | **MEDIUM** | **`max_tokens: 2048` hardcoded everywhere.** All versions and all providers use the same 2048 response token limit with no rationale documented. For complex analysis (SWOT, budget summaries), 2048 tokens may be insufficient. No version makes this configurable. | All 3 AI Chat docs |
| 9 | **LOW** | **v2 search regression.** MVP uses hybrid search (vector + FTS + RRF). v2 uses vector-only search (`search_apm_context`). No rationale documented for dropping full-text search. v3 restores hybrid for the Supabase provider. | MVP `search_apm` vs v2 `search_apm_context` |
| 10 | **LOW** | **No conversation scoping model.** No concept of conversation threads, topics, or workspace-scoped conversations. All messages are a flat list in component state. As AI Chat matures, users will expect to maintain separate conversations per topic or workspace. | All 3 AI Chat docs |
| 11 | **LOW** | **Usage tracking is quantity-only.** `apm_chat_usage` counts queries. `namespace_ai_settings` tracks monthly usage. Neither captures conversation quality, user satisfaction, response latency, or context utilization metrics needed to optimize the system. | MVP §usage, v3 §namespace_ai_settings |

### Recommended Actions

**Before AI Chat MVP development begins:**

1. **Define context window budget** — Allocate fixed token budgets: system prompt (N tokens), RAG context (N tokens), conversation history (N tokens), response (2048 tokens). Implement token estimation (character-based heuristic or tiktoken) to enforce budgets.

2. **Choose RAG vs MCP (or hybrid)** — Document whether AI Chat MVP will use the existing embed→search→stuff pattern, the MCP tool-use pattern from §15.3, or a hybrid. Update whichever doc loses to cross-reference the winning approach.

3. **Design conversation persistence** — Add `apm_conversations` and `apm_conversation_messages` tables. Scope conversations to namespace + user. Enable resumption, audit trail, and content analytics. Reference the `conversationId` field from `AiChatRequest` (§15.4).

4. **Standardize truncation** — Replace `slice(-10)` with token-budget-aware truncation. Summarize older messages rather than discarding them. Document the strategy.

5. **Update auth pattern** — Replace `auth.getUser()` with `jose` JWKS verification per Edge Functions §6.2 in all AI Chat Edge Function code blocks.

6. **Adopt `AiChatRequest` contract** — Update the AI Chat MVP doc to accept `searchContext` for Global Search handoff and `conversationId` for multi-turn tracking.

---

## Summary

| Area | HIGH | MEDIUM | LOW | Total |
|------|------|--------|-----|-------|
| Context Window Management | 2 | 2 | 0 | 4 |
| Conversation Lifecycle | 1 | 1 | 1 | 3 |
| Cross-Document Alignment | 1 | 1 | 1 | 3 |
| Implementation Consistency | 0 | 0 | 1 | 1 |
| **Total** | **4** | **4** | **3** | **11** |

### Priority Actions (HIGH gaps)

1. **Context window budget** — token allocation strategy for system prompt, RAG context, history, and response
2. **Conversation persistence** — database-backed conversation storage with resumption
3. **Token counting** — estimation mechanism to enforce budgets and prevent silent overflow
4. **RAG vs MCP resolution** — reconcile the two architectural approaches before development

---

*This review should be addressed before AI Chat Edge Function development begins. The 4 HIGH gaps represent foundational architectural decisions that affect the conversation experience and system reliability.*
