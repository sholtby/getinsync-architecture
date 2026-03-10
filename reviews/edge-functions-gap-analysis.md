# Edge Functions Layer — Gap Analysis

> **Status:** 🟡 REVIEW
> **Date:** 2026-03-09
> **Subject:** `infrastructure/edge-functions-layer-architecture.md` v1.1
> **Author:** Claude Code (research session)

---

## Purpose

Cross-reference the Edge Functions Layer Architecture (v1.1) against related architecture documents to identify gaps before AI Chat development begins. Three areas examined:

1. US/EU data residency implications
2. Inbound API for external consumers
3. MCP strategy and Global Search integration

## Documents Cross-Referenced

| Document | Version | Key Content |
|----------|---------|-------------|
| `infrastructure/edge-functions-layer-architecture.md` | v1.1 | Edge Function infra blueprint, auth, MCP (§15) |
| `planning/work-package-multi-region.md` | — | Option C hybrid: CA live, US/EU on-demand, separate Supabase projects |
| `MANIFEST.md` — Architecture Principle #6 | v1.50 | Data residency: region column on namespaces (ca/us/eu) |
| `features/integrations/architecture.md` | v1.2 | Internal/External integration entity model |
| `features/integrations/itsm-api-research.md` | v1.1 | ServiceNow + HaloITSM API transport, Phase 37 plan |
| `features/ai-chat/mvp.md` | v1.0 | AI Chat Edge Function blueprint, embeddings, streaming |
| `features/global-search/architecture.md` | v1.1 | Global Search with progressive AI upgrade path (§10) |

---

## Q1: US/EU Data Residency in Edge Functions

### Finding

The edge functions doc states: *"Edge Functions run globally but data at rest stays in ca-central-1."* The multi-region work package establishes that each region (ca/us/eu) is a **separate Supabase project** with complete data isolation. Architecture Principle #6 confirms the three-region strategy.

**The edge functions doc does not address what happens when US/EU regional Supabase projects are deployed.** The entire document assumes a single Supabase project with single-valued environment variables.

### Gaps

| # | Severity | Gap |
|---|----------|-----|
| 1.1 | **HIGH** | **No multi-region Edge Function deployment strategy.** `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are single-valued secrets. When US/EU regions deploy, Edge Functions need to route to the correct regional Supabase project. The doc describes no per-region secret management, no routing logic, and no strategy for deploying Edge Functions per regional project. |
| 1.2 | **HIGH** | **JWKS endpoint is region-specific.** The new `jose` auth pattern (§6.2) uses `${SUPABASE_URL}/.well-known/jwks.json`. Each regional Supabase project has its own JWKS signing keys. Edge Functions must verify tokens against the **correct region's** JWKS, but the current pattern hardcodes a single JWKS URL. A CA token verified against EU JWKS would fail. |
| 1.3 | **MEDIUM** | **Global edge execution vs data residency compliance.** Deno Deploy executes at the nearest edge node worldwide. A EU user's request may execute on a US edge node, then reach back to the EU Supabase project. The doc does not clarify whether this data-in-transit pattern is acceptable for EU data residency compliance (GDPR) or whether region-pinned execution is needed. |
| 1.4 | **LOW** | **AI Chat embeddings are region-scoped.** The AI Chat MVP creates `apm_embeddings` in one database. Multi-region means separate embedding tables per regional project — no cross-region search is possible. This is primarily an AI Chat doc gap but surfaces through the edge functions layer. |

### Recommended Actions

1. Add **§16 "Multi-Region Deployment"** to the edge functions doc covering:
   - Per-region Supabase project secrets (naming convention: `SUPABASE_URL_CA`, `SUPABASE_URL_US`, `SUPABASE_URL_EU` or dynamic resolution from request context)
   - JWKS routing: derive JWKS URL from the token's `iss` claim or from a region header
   - Edge Function deployment strategy: one set of functions per Supabase project (each project gets its own Edge Functions) vs shared functions with region routing
2. Clarify **data-in-transit residency posture** — document whether global edge execution is acceptable or whether Supabase's region-pinned deployment is required for EU
3. Coordinate with **AI Chat MVP doc** to note embedding isolation per region

---

## Q2: Inbound API for External Consumers

### Finding

The ITSM API research doc (Phase 37) describes **outbound** integration: GetInSync pushes data **to** ServiceNow and HaloITSM using Edge Functions. The integrations architecture doc defines the entity model for tracking integration metadata (direction, method, format, cadence).

**Neither document addresses inbound API — external systems calling into GetInSync.** The edge functions doc lists 8 planned features; none are inbound API endpoints for external consumers.

### Gaps

| # | Severity | Gap |
|---|----------|-----|
| 2.1 | **HIGH** | **No inbound API architecture.** The 8 planned Edge Functions (§5.1) serve internal consumers only (browser client, cron). There is no design for external systems (ServiceNow, HaloITSM, or future ITSM tools) pulling data **from** GetInSync or pushing updates **into** GetInSync. |
| 2.2 | **HIGH** | **No external consumer authentication pattern.** The `jose` JWKS auth (§6.2) validates Supabase user JWTs. External systems won't have Supabase user accounts. The doc has no pattern for: API keys, OAuth 2.0 client credentials grants, service accounts, or any service-to-service authentication mechanism. |
| 2.3 | **MEDIUM** | **No rate limiting or API gateway design.** Rate limiting is mentioned only for AI Chat (per-user usage tracking in `apm_chat_usage`). There is no general rate limiting strategy, throttling, IP allowlisting, or abuse prevention for endpoints exposed to external consumers. |
| 2.4 | **MEDIUM** | **No webhook receiver pattern.** The ITSM research doc notes HaloITSM supports webhooks for near-real-time sync. The edge functions doc has no webhook receiver design: no signature verification, no idempotency key handling, no retry/dedup logic, no dead letter queue. |

### Recommended Actions

1. Add **§17 "Inbound API Layer"** to the edge functions doc covering:
   - Endpoint design: RESTful resource endpoints for external consumers (e.g., `GET /api/v1/applications`, `POST /api/v1/sync`)
   - External auth patterns: API key validation (stored in `integration_connections` table from ITSM research), OAuth 2.0 client credentials for enterprise consumers
   - Rate limiting: per-API-key rate limits, configurable per integration connection
   - Versioning: URL-based API versioning (`/v1/`) for stability
2. Add **webhook receiver pattern** to `_shared/` utilities plan:
   - HMAC signature verification
   - Idempotency key tracking (dedup table)
   - Retry-safe processing (acknowledge before processing)
3. Cross-reference with **ITSM Phase 37c** (ServiceNow Subscribe) — that phase will be the first consumer of inbound API endpoints

---

## Q3: MCP Strategy + Global Search → AI Chat Handoff

### Finding

The edge functions doc §15 covers MCP basics: inline tools first within the `ai-chat` function, extract to separate Edge Functions only when reused by multiple consumers. Global Search §10.2–10.4 describes the progressive upgrade path (ILIKE → full-text → semantic) and the search-to-chat handoff UX (contextual AI prompts in search overlay). The AI Chat MVP spec provides the implementation blueprint.

**The MCP strategy is thin (2 example tools) and the handoff mechanism is split across documents with no single source of truth for the AI Chat tool contract.**

### Gaps

| # | Severity | Gap |
|---|----------|-----|
| 3.1 | **MEDIUM** | **MCP tool inventory is incomplete.** §15 shows only 2 example tools (`query_applications`, `get_lifecycle_risk`). The AI Chat MVP implies many more are needed to answer portfolio questions: search entities, get deployment details, get cost data, get contacts, get integrations, get lifecycle status. The edge functions doc should define the **initial MCP tool set** that ships with AI Chat MVP. |
| 3.2 | **MEDIUM** | **No MCP tool for Global Search RPC.** Global Search has a deployed `global_search(text, int)` RPC returning categorized results across 12 entity types. This is an obvious MCP tool for AI Chat ("search the portfolio") but neither doc explicitly connects them. The proposed shared `entity-registry.ts` (Global Search §10.4) would serve both systems but is not referenced in the edge functions doc. |
| 3.3 | **LOW** | **Search-to-chat handoff UX is documented but the Edge Function contract is not.** Global Search §10.3 describes the UI handoff (contextual prompts appear in search overlay). But the edge functions doc doesn't specify whether the `ai-chat` function accepts a `searchContext` parameter, whether it receives the search query + results as initial context, or how the handoff is structured at the API level. |
| 3.4 | **LOW** | **No MCP tool versioning or discovery pattern.** As tools grow (lifecycle lookup, global search, ITSM publish, cost analysis, etc.), there is no documented pattern for tool versioning, capability discovery, or deprecation. This is not urgent for MVP but will matter as the tool set expands. |

### Recommended Actions

1. Expand **§15** with complete initial MCP tool inventory aligned with AI Chat MVP context-building needs:
   - `search_portfolio` — wraps deployed `global_search` RPC
   - `get_application_detail` — application + deployment profiles + scores
   - `get_lifecycle_risk` — technology lifecycle status for a DP or product
   - `get_cost_summary` — cost channels for a workspace or application
   - `get_integration_map` — upstream/downstream integrations for an application
   - `get_contacts` — involved parties for an entity
2. Add **`global_search`** as an explicit MCP tool, referencing the deployed RPC and its return schema
3. Define the **AI Chat Edge Function API contract** for search-to-chat handoff:
   - `POST /ai-chat` body accepts optional `searchContext: { query: string, results: SearchResult[], entityType?: string }`
   - When present, AI Chat uses search context as conversation seed
4. Add **`entity-registry.ts`** as a shared dependency in §5.3, referenced by both Global Search and AI Chat

---

## Summary

| Area | HIGH | MEDIUM | LOW | Total |
|------|------|--------|-----|-------|
| Q1 — Data Residency | 2 | 1 | 1 | 4 |
| Q2 — Inbound API | 2 | 2 | 0 | 4 |
| Q3 — MCP + Search Handoff | 0 | 2 | 2 | 4 |
| **Total** | **4** | **5** | **3** | **12** |

### Priority Actions (HIGH gaps)

1. **§16 Multi-Region Deployment** — per-region secrets, JWKS routing, deployment strategy
2. **§17 Inbound API Layer** — endpoint design, external auth (API keys + OAuth client credentials), rate limiting
3. **JWKS region routing** — derive verification endpoint from token issuer or region context
4. **External consumer auth pattern** — service-to-service authentication independent of Supabase user JWTs

---

*This review should be addressed before AI Chat Edge Function development begins. The 4 HIGH gaps represent architectural decisions that affect the Edge Function infrastructure layer design.*
