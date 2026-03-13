# Edge Functions Infrastructure Layer

**Version:** 1.3
**Date:** March 13, 2026
**Status:** 🟢 PARTIALLY DEPLOYED (shared scaffold + lifecycle-lookup auth fix deployed)  
**Repo path:** `infrastructure/edge-functions-layer.md`  
**Prerequisite:** None — foundational infrastructure document

---

## 1. Why This Document Exists

GetInSync NextGen has operated as a client-only stack: React/TypeScript → Supabase Client → PostgreSQL. Eight planned features require server-side execution where API keys, service role access, or external system credentials cannot touch the browser. This document establishes Edge Functions as a first-class infrastructure layer — not an ad hoc addition per feature.

### 1.1 Features Requiring Server-Side Execution

| # | Feature | Why Server-Side | Secrets Required | Priority |
|---|---------|----------------|-----------------|----------|
| 1 | **AI Chat** (MVP → v3) | Claude API calls for natural language APM queries | `ANTHROPIC_API_KEY` | Q2 2026 |
| 2 | **Lifecycle Intelligence** automation | Vendor EOL API lookups, web scraping for GA/EOL dates | Vendor API keys (varies) | Q2 2026 |
| 3 | **Email Digest** (Gamification) | Weekly digest, 14-day re-engagement, achievement notifications | `RESEND_API_KEY` | Q2–Q3 2026 |
| 4 | **Session Enforcement** (Enterprise) | Hard single-session revocation via Auth Admin API | `SUPABASE_SERVICE_ROLE_KEY` (built-in) | Q2 2026 |
| 5 | **ServiceNow Integration** | Subscribe/publish CSDM data to customer instances | Customer-scoped ServiceNow OAuth tokens | Q3 2026 |
| 6 | **HaloITSM Integration** | Pull/push ITSM data for secondary market | `HALOITSM_API_KEY` + per-customer tokens | Q3 2026 |
| 7 | **Cloud Discovery** (Phase 27) | AWS/Azure/GCP resource enumeration | Customer cloud IAM credentials | Q3–Q4 2026 |
| 8 | **SSO/SAML** | Identity provider callbacks, assertion parsing | SAML certificates, IdP metadata | Q2 2026 |

**First consumer:** AI Chat (Global Search → AI Chat handoff is already architected). Session Enforcement is simplest to build but AI Chat delivers the most customer value.

---

## 2. Architecture Overview

### 2.1 Current Stack (Client-Only)

```
Browser (React/TypeScript)
  → Supabase JS Client
    → PostgREST (auto-generated REST API)
    → Realtime (WebSocket)
    → PostgreSQL (RLS-enforced)
```

### 2.2 Target Stack (With Edge Functions Layer)

```
Browser (React/TypeScript)
  → Supabase JS Client
    → PostgREST (auto-generated REST API)         ← unchanged
    → Realtime (WebSocket)                         ← unchanged
    → PostgreSQL (RLS-enforced)                    ← unchanged
    → Edge Functions (Deno runtime, global edge)   ← NEW
        → Claude API (AI Chat)
        → Vendor APIs (Lifecycle)
        → Resend (Email)
        → Auth Admin API (Session Enforcement)
        → ServiceNow / HaloITSM APIs
        → Cloud Provider APIs (Discovery)
```

### 2.3 Key Architectural Property

Edge Functions are **stateless, short-lived, and idempotent**. They receive a request, do work (call an API, query the database, orchestrate a multi-step flow), and return a response. No persistent state, no background threads, no long-running connections.

For long-running operations (e.g., bulk Cloud Discovery scan across 500 AWS resources), the pattern is: Edge Function kicks off the work → writes progress to a database table → client polls or subscribes via Realtime for completion.

---

## 3. Runtime Environment

### 3.1 Supabase Edge Functions Specifics

| Property | Value |
|---|---|
| **Runtime** | Deno (TypeScript-first, WASM support) |
| **Deployment** | Global edge distribution (automatic, no CDN config) |
| **Invocation** | HTTP (GET/POST/PUT/PATCH/DELETE/OPTIONS) |
| **Max execution time** | 150s (wall clock) per invocation |
| **Concurrency** | Multiple isolates per edge location, auto-scaled |
| **Cold starts** | Possible — design for short-lived, idempotent operations |
| **File system** | `/tmp` only (write), ephemeral per invocation |
| **HTML responses** | Not supported (text/html rewritten to text/plain) |
| **Background work** | `EdgeRuntime.waitUntil(promise)` for fire-and-forget tasks |

### 3.2 Built-In Environment Variables

Every Edge Function automatically receives:

| Variable | Description | Security |
|---|---|---|
| `SUPABASE_URL` | Project API URL | Public |
| `SUPABASE_ANON_KEY` | Anonymous/public API key | Public |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key — **bypasses RLS** | Secret — never expose to browser |
| `SUPABASE_DB_URL` | Direct PostgreSQL connection string | Secret |

### 3.3 Coding Standards

Per Supabase best practices:

1. Use Web APIs and Deno core APIs over external dependencies (e.g., `fetch` not Axios)
2. Shared utilities go in `supabase/functions/_shared/` — import via relative path
3. No cross-dependencies between Edge Functions
4. No bare specifiers — prefix with `npm:` or `jsr:` (e.g., `npm:@supabase/supabase-js@2`)
5. Always pin dependency versions
6. Use Hono for multi-route functions (recommended by Supabase for readability)
7. File writes only in `/tmp`
8. Use `EdgeRuntime.waitUntil()` for background tasks (e.g., audit logging after response sent)

---

## 4. Secret Management

### 4.1 Two Secret Stores

GetInSync uses two complementary secret management mechanisms:

| Store | Scope | Access Pattern | Use Case |
|---|---|---|---|
| **Edge Function Secrets** | Edge Functions only | `Deno.env.get('KEY')` | API keys for external services (Anthropic, Resend, etc.) |
| **Supabase Vault** | Database (PL/pgSQL) | `SELECT * FROM vault.decrypted_secrets` | Secrets needed by database functions, triggers, webhooks |

### 4.2 Edge Function Secrets (Primary)

Set via CLI:

```bash
# Single secret
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

# From env file (preferred for multiple secrets)
supabase secrets set --env-file ./supabase/.env

# List current secrets (shows names only, not values)
supabase secrets list
```

Access in function code:

```typescript
const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY');
if (!anthropicKey) throw new Error('ANTHROPIC_API_KEY not configured');
```

### 4.3 Supabase Vault (Database-Level)

Already installed (`supabase_vault` extension confirmed in schema). Used when database functions or triggers need secrets (e.g., a PL/pgSQL function that calls `pg_net` to hit an external API).

```sql
-- Store a secret
SELECT vault.create_secret('sk-ant-...', 'anthropic_api_key', 'Anthropic API key for AI chat');

-- Retrieve (only accessible by roles with GRANT on vault.decrypted_secrets)
SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'anthropic_api_key';
```

**Vault is authenticated-encrypted** (libsodium) — data is encrypted at rest and signed to prevent forgery.

### 4.4 Secret Inventory

| Secret Name | Store | Consumer(s) | Rotation Policy |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | Edge Function Secrets | AI Chat function | Annual or on compromise |
| `RESEND_API_KEY` | Edge Function Secrets | Email Digest function | Annual |
| `SERVICENOW_CLIENT_ID` | Vault | ServiceNow integration | Per customer onboarding |
| `SERVICENOW_CLIENT_SECRET` | Vault | ServiceNow integration | Per customer onboarding |
| `HALOITSM_API_KEY` | Edge Function Secrets | HaloITSM integration | Per customer onboarding |
| `SUPABASE_SERVICE_ROLE_KEY` | Built-in (automatic) | Session Enforcement | Managed by Supabase |

**Customer-scoped secrets** (ServiceNow OAuth tokens, cloud IAM credentials) are stored in Vault with a namespace-level association so each tenant's credentials are isolated. This is a Q3 concern — the Vault table structure for per-customer secrets will be designed when the first integration feature is built.

### 4.5 Secret Rules

1. **Never hardcode secrets** in function code or commit to Git
2. **Never log secrets** — log truncated versions only for debugging (`key.slice(0, 8) + '...'`)
3. `.env` files in `.gitignore` — always
4. Edge Function Secrets for function-scoped API keys; Vault for database-scoped or customer-scoped secrets
5. Service role key is **pre-injected** — no manual configuration needed

---

## 5. Function Registry

### 5.1 Naming Convention

```
supabase/functions/{function-name}/index.ts
```

Function names use kebab-case. Each function is a single entry point that may handle multiple routes via Hono.

### 5.2 Function Registry

| Function Name | Consumer Feature | Routes | Auth Required | Status |
|---|---|---|---|---|
| `lifecycle-lookup` | Lifecycle Intelligence | `POST /lifecycle-lookup` | Yes (JWT) | 🟢 **Deployed** (Phase 27c). Three-tier pipeline: DB cache → endoflife.date → Claude. |
| `ai-chat` | AI Chat MVP → v3 | `POST /ai-chat` | Yes (JWT) | 🟡 Planned — first new function to build |
| `email-digest` | Gamification | `POST /email-digest/weekly`, `POST /email-digest/re-engage` | Service role (cron trigger) | 🟡 Planned |
| `session-enforce` | Session Enforcement | `POST /session-enforce/revoke` | Yes (JWT) | 🟡 Planned |
| `integration-sync` | ServiceNow + HaloITSM | `POST /integration-sync/servicenow`, `POST /integration-sync/halo` | Yes (JWT) + customer credentials | 🟡 Planned |
| `cloud-discovery` | Cloud Discovery | `POST /cloud-discovery/scan` | Yes (JWT) + cloud credentials | 🟡 Planned |

**Retired functions:**

| Function Name | Reason | Replacement |
|---|---|---|
| `technology-catalog-search` | 401 auth failures (see §6.5). endoflife.date API supports CORS, no proxy needed. | `src/lib/endoflife-client.ts` — direct browser client. Delete from Supabase deployment. |

### 5.3 Shared Utilities (`_shared/`)

```
supabase/functions/_shared/
├── cors.ts                 # Standard CORS headers + handleCors() helper (DEPLOYED)
├── supabase-admin.ts       # Service-role client factory (DEPLOYED)
├── lifecycle-utils.ts      # Lifecycle status computation (DEPLOYED)
├── auth.ts                 # JWT validation via jose/JWKS — see §6.2 (DEPLOYED)
├── error-handler.ts        # Standardized error responses — see §12 (DEPLOYED)
├── audit.ts                # Write to audit_logs via service role (PLANNED)
└── rate-limit.ts           # Per-user rate limiting (PLANNED)
```

---

## 6. Authentication & Authorization

### 6.1 Client Invocation Pattern

```typescript
// From React frontend — Supabase JS client handles auth automatically
const { data, error } = await supabase.functions.invoke('ai-chat', {
  body: { 
    query: 'Show me applications with EOL technologies',
    workspaceId: currentWorkspaceId
  }
});
```

The Supabase client automatically attaches the user's JWT to the `Authorization` header. The Edge Function validates it.

### 6.2 JWT Validation Inside Functions

> **March 2026 update:** Supabase has deprecated implicit JWT verification in favor of explicit local verification using the `jose` library. The old pattern (`auth.getUser(token)`) made a network round-trip from the edge isolate back to the Auth service — this was slow and caused intermittent 401 failures (see §6.5). The new pattern verifies JWTs locally using the project's JWKS endpoint, with no network call.

**Recommended pattern (local JWKS verification):**

```typescript
// supabase/functions/_shared/auth.ts
import * as jose from 'jsr:@panva/jose@6';

const SUPABASE_JWT_ISSUER =
  Deno.env.get('SB_JWT_ISSUER') ??
  Deno.env.get('SUPABASE_URL')! + '/auth/v1';

const SUPABASE_JWT_KEYS = jose.createRemoteJWKSet(
  new URL(Deno.env.get('SUPABASE_URL')! + '/auth/v1/.well-known/jwks.json'),
);

export async function authenticateRequest(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new AuthError('Missing Authorization header');

  const [bearer, token] = authHeader.split(' ');
  if (bearer !== 'Bearer' || !token) throw new AuthError('Invalid Authorization header');

  const { payload } = await jose.jwtVerify(token, SUPABASE_JWT_KEYS, {
    issuer: SUPABASE_JWT_ISSUER,
  });

  return {
    user: { id: payload.sub!, email: payload.email, role: payload.role },
    token,
  };
}
```

**Usage in an Edge Function:**

```typescript
import { authenticateRequest, AuthError } from '../_shared/auth.ts';
import { createAdminClient } from '../_shared/supabase-admin.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user } = await authenticateRequest(req);

    // user.id available for RLS-scoped queries or audit logging
    // Use createAdminClient() for service-role operations
    const supabaseAdmin = createAdminClient();

    // ... function logic
  } catch (err) {
    if (err instanceof AuthError) {
      return new Response(JSON.stringify({ error: 'unauthorized', message: err.message }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    return new Response(JSON.stringify({ error: 'internal_error' }), { status: 500 });
  }
});
```

**Key points:**
- `createRemoteJWKSet()` fetches keys once and caches them — no per-request network call
- Falls back to `SUPABASE_URL + '/auth/v1'` if `SB_JWT_ISSUER` is not set (works for all hosted Supabase projects)
- Returns the raw `token` so callers can create user-scoped Supabase clients for RLS queries if needed
- This is the pattern Supabase recommends as of March 2026 (see [Securing Edge Functions](https://supabase.com/docs/guides/functions/auth))

**Deprecated pattern (do NOT use):**

```typescript
// ❌ OLD — makes network call back to Auth service, causes intermittent 401s
const anonClient = createClient(supabaseUrl, supabaseAnonKey);
const { data: { user }, error } = await anonClient.auth.getUser(token);
```

### 6.3 Two Client Pattern

Every function that touches the database maintains two Supabase clients:

| Client | Created With | Purpose | RLS |
|---|---|---|---|
| **User client** | Anon key + user's JWT | Read/write user-visible data | Enforced |
| **Admin client** | Service role key | Admin operations (session revoke, cross-tenant reads, audit writes) | Bypassed |

**Rule:** Default to user client. Only use admin client for specific operations that require it, and document why.

### 6.4 Functions Without JWT (Webhook Receivers)

Some functions receive external webhooks (e.g., ServiceNow callback, Stripe webhook). These use `--no-verify-jwt` in deployment config and validate authenticity via webhook signatures or shared secrets instead.

```toml
# supabase/config.toml
[functions.integration-sync]
verify_jwt = false  # Validates via webhook signature instead
```

### 6.5 Known Issue: `auth.getUser(token)` 401 Failures (March 2026)

**Status:** ✅ FIXED (March 13, 2026). `lifecycle-lookup` updated to use §6.2 jose/JWKS pattern. `_shared/auth.ts` deployed.

**Affected functions:**
- `technology-catalog-search` — **retired**, replaced by direct browser client (`src/lib/endoflife-client.ts`)
- `lifecycle-lookup` — **still uses deprecated pattern**, needs update

**Root cause:** Both Edge Functions used `auth.getUser(token)` which creates a standalone Supabase client inside the Edge Function and makes a **network round-trip** from the edge isolate back to the Supabase Auth service (hosted in `ca-central-1`) to validate the JWT. This pattern is:
1. **Slow** — adds 100-500ms latency per request
2. **Fragile** — network issues between global edge locations and `ca-central-1` Auth service cause intermittent 401s
3. **Unnecessary** — the JWT can be verified locally using the project's JWKS public keys

**Timeline:**
- `technology-catalog-search` was the first consumer of `supabase.functions.invoke()` (Phase 28b, Mar 8)
- 401 errors observed immediately after deployment
- Workaround (Mar 9): Bypassed Edge Function entirely — endoflife.date API supports CORS, so the browser calls it directly via `src/lib/endoflife-client.ts`
- `lifecycle-lookup` (Phase 27c, Mar 6) uses the same broken pattern but has not been heavily tested in production yet

**Fix:** Update `lifecycle-lookup/index.ts` to use the `jose` JWKS verification pattern in §6.2. Create `_shared/auth.ts` as a shared utility. Apply the same pattern to all future Edge Functions (including `ai-chat`).

**References:**
- [Supabase: Securing Edge Functions](https://supabase.com/docs/guides/functions/auth) — official docs recommending `jose` JWKS
- [GitHub Discussion #36548](https://github.com/orgs/supabase/discussions/36548) — community reports of same issue
- Commit `1433c2e` — the browser-direct workaround for `technology-catalog-search`

---

## 7. Database Access From Edge Functions

### 7.1 Preferred: Supabase JS Client (via PostgREST)

For most operations, use the Supabase JS client within Edge Functions. This provides type safety, automatic RLS enforcement, and familiar API surface.

```typescript
// User-scoped query (RLS enforced)
const { data: initiatives } = await supabaseUser
  .from('initiatives')
  .select('*')
  .eq('program_id', programId);

// Admin operation (RLS bypassed)
const { error } = await supabaseAdmin
  .from('audit_logs')
  .insert({ entity_type: 'initiative', action: 'ai_query', ... });
```

### 7.2 When Needed: Direct Postgres Connection

For operations requiring transactions (PostgREST doesn't support them), use direct Postgres connection via `SUPABASE_DB_URL`:

```typescript
import { Pool } from 'npm:pg@8.11.3';

const pool = new Pool({ connectionString: Deno.env.get('SUPABASE_DB_URL') });
const client = await pool.connect();

try {
  await client.query('BEGIN');
  await client.query('UPDATE initiatives SET status = $1 WHERE id = $2', ['completed', id]);
  await client.query('INSERT INTO audit_logs ...', [...]);
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
  throw e;
} finally {
  client.release();
}
```

**Use direct Postgres only when transactions are required.** PostgREST via Supabase JS is simpler, safer, and connection-pool-friendly.

### 7.3 Alternative: RPC for Transactional Logic

If the transactional logic is reusable, prefer database functions called via RPC:

```sql
-- Database function (created by Stuart in SQL Editor)
CREATE OR REPLACE FUNCTION complete_initiative(p_initiative_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE initiatives SET status = 'completed' WHERE id = p_initiative_id;
  INSERT INTO audit_logs (entity_type, entity_id, action) 
  VALUES ('initiative', p_initiative_id, 'completed');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

```typescript
// Edge Function calls via RPC
const { error } = await supabaseUser.rpc('complete_initiative', { 
  p_initiative_id: initiativeId 
});
```

**Decision tree:** Supabase JS (default) → RPC (if transactional + reusable) → Direct Postgres (if transactional + one-off + complex).

---

## 8. Project Structure

### 8.1 Directory Layout

```
getinsync-nextgen-ag/           # Existing code repo
├── src/                        # React frontend (existing)
├── supabase/
│   ├── config.toml             # Project config + function settings
│   ├── .env                    # Production secrets (gitignored)
│   ├── .env.local              # Local dev secrets (gitignored)
│   └── functions/
│       ├── _shared/            # Shared utilities
│       │   ├── supabase-client.ts
│       │   ├── cors.ts
│       │   ├── auth.ts
│       │   ├── error-handler.ts
│       │   └── audit.ts
│       ├── ai-chat/
│       │   └── index.ts
│       ├── lifecycle-lookup/
│       │   └── index.ts
│       ├── email-digest/
│       │   └── index.ts
│       ├── session-enforce/
│       │   └── index.ts
│       ├── integration-sync/
│       │   └── index.ts
│       └── cloud-discovery/
│           └── index.ts
├── CLAUDE.md                   # Existing
└── package.json                # Existing
```

### 8.2 Git Considerations

Add to `.gitignore`:

```
supabase/.env
supabase/.env.local
```

Edge Function code is committed to Git alongside the React frontend. This is intentional — it's the same product, same repo, same CI/CD pipeline.

---

## 9. Local Development

### 9.1 Prerequisites

```bash
# Install Supabase CLI (if not already)
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref <project-id>
```

### 9.2 Local Development Workflow

```bash
# Start local Supabase stack (Postgres, Auth, Realtime, etc.)
supabase start

# Serve Edge Functions locally (hot reload)
supabase functions serve --env-file ./supabase/.env.local

# Functions available at:
# http://localhost:54321/functions/v1/{function-name}
```

### 9.3 Testing Locally

```bash
# Invoke with curl
curl -X POST http://localhost:54321/functions/v1/ai-chat \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"query": "show me EOL applications"}'

# Or from React app — point Supabase client to local URL
# (handled by existing VITE_SUPABASE_URL env var)
```

---

## 10. Deployment Pipeline

### 10.1 Manual Deployment (Current Phase)

```bash
# Deploy single function
supabase functions deploy ai-chat

# Deploy all functions
supabase functions deploy

# Set production secrets
supabase secrets set --env-file ./supabase/.env
```

### 10.2 CI/CD (GitHub Actions — Future)

When the first Edge Function ships to production, add a deployment step to the existing GitHub Actions workflow:

```yaml
# .github/workflows/deploy.yml (addition to existing pipeline)
edge-functions:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: supabase/setup-cli@v1
      with:
        version: latest
    - run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
    - run: supabase functions deploy
  env:
    SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

### 10.3 Deployment Rules

1. **Test locally first** — always `supabase functions serve` before deploying
2. **Deploy functions independently** — don't deploy all when only one changed
3. **Secrets are set once** — they persist across function deployments
4. **No downtime** — new deployment replaces old atomically at the edge
5. **Rollback** — redeploy previous version from Git history

---

## 11. CORS Configuration

Edge Functions serving browser requests need CORS headers. Centralize in `_shared/cors.ts`:

```typescript
// supabase/functions/_shared/cors.ts
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',  // Tighten to domain in production
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

export function handleCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
}
```

**Production hardening:** Replace `'*'` with specific origins:

```typescript
const ALLOWED_ORIGINS = [
  'https://nextgen.getinsync.ca',
  'https://dev--relaxed-kataifi-57d630.netlify.app',
  'http://localhost:5173',
];
```

---

## 12. Error Handling Standard

All Edge Functions return consistent error shapes:

```typescript
// supabase/functions/_shared/error-handler.ts
interface ErrorResponse {
  error: {
    code: string;          // Machine-readable: 'AUTH_FAILED', 'RATE_LIMITED', etc.
    message: string;       // Human-readable
    details?: unknown;     // Optional debug info (omit in production)
  };
}

export function errorResponse(code: string, message: string, status: number): Response {
  return new Response(
    JSON.stringify({ error: { code, message } }),
    { status, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
  );
}
```

Standard error codes:

| Code | HTTP Status | Meaning |
|---|---|---|
| `AUTH_FAILED` | 401 | Missing or invalid JWT |
| `FORBIDDEN` | 403 | Valid JWT but insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `EXTERNAL_API_ERROR` | 502 | Upstream API (Claude, ServiceNow, etc.) failed |
| `INTERNAL_ERROR` | 500 | Unhandled function error |

---

## 13. Observability

### 13.1 Logging

Edge Functions write to Supabase's built-in log stream:

```typescript
console.log('AI Chat query received', { userId: user.id, workspaceId });
console.error('Claude API failed', { status: response.status });
```

Logs viewable in: Supabase Dashboard → Edge Functions → Logs.

### 13.2 Audit Trail

All Edge Function operations that modify data or access external systems write to `audit_logs` via the admin client:

```typescript
await supabaseAdmin.from('audit_logs').insert({
  entity_type: 'ai_chat',
  entity_id: null,
  action: 'query',
  user_id: user.id,
  namespace_id: namespaceId,
  details: { query: sanitizedQuery, tokens_used: tokenCount }
});
```

This integrates with the existing audit infrastructure (50 triggers, SOC2 evidence).

### 13.3 Metrics to Track

| Metric | Source | Alert Threshold |
|---|---|---|
| Function invocations / hour | Supabase Dashboard | > 1000 (investigate) |
| Average execution time | Supabase Dashboard | > 5s (optimize) |
| Error rate (4xx + 5xx) | Supabase Dashboard | > 5% (investigate) |
| External API failures | audit_logs | > 3 consecutive (alert) |
| Cold start frequency | Supabase Dashboard | Informational only |

---

## 14. Rate Limiting

### 14.1 Per-User Limits

Prevent abuse (especially on AI Chat, which has real API costs):

| Function | Limit | Window | Tier Override |
|---|---|---|---|
| `ai-chat` | 20 queries | 1 hour | Pro: 50, Enterprise: 200 |
| `lifecycle-lookup` | 100 lookups | 1 hour | Uniform |
| `email-digest` | N/A (cron-triggered) | — | — |
| `session-enforce` | 10 calls | 1 minute | Uniform |

### 14.2 Implementation

For MVP, use in-memory rate limiting per isolate (imperfect but sufficient for early stage). For production scale, add Upstash Redis or use the database:

```typescript
// Simple per-user rate check via database
const { count } = await supabaseAdmin
  .from('audit_logs')
  .select('*', { count: 'exact', head: true })
  .eq('entity_type', 'ai_chat')
  .eq('user_id', user.id)
  .gte('created_at', oneHourAgo.toISOString());

if (count >= limit) {
  return errorResponse('RATE_LIMITED', 'Query limit reached. Try again later.', 429);
}
```

---

## 15. MCP Server Considerations

### 15.1 What MCP Means for GetInSync

Model Context Protocol (MCP) standardizes how LLMs call external tools. In the AI Chat context:

- The **AI Chat Edge Function** orchestrates a conversation with Claude
- Claude can call **MCP tools** to query GetInSync data, look up lifecycle info, or search ServiceNow
- Each MCP tool is either an inline function within the Edge Function or a separate Edge Function called via HTTP

### 15.2 Architecture Decision: Inline vs Separate

| Approach | Pros | Cons |
|---|---|---|
| **Inline tools** (functions within ai-chat) | Simpler, single deployment, lower latency | Larger function, harder to test independently |
| **Separate Edge Functions as tools** | Independent deployment, reusable | HTTP overhead per tool call, more complex |

**Decision:** Start with **inline tools** in the `ai-chat` function. Extract to separate functions only when a tool is needed by multiple consumers (e.g., lifecycle lookup is used by both AI Chat and a standalone UI).

> **Extraction criteria:** A tool graduates from inline to standalone Edge Function when (a) it has 2+ consumers (e.g., `lifecycle-lookup` serves both AI Chat and the Technology Health UI), AND (b) it requires its own deployment lifecycle (independent versioning, different rate limits, or separate secret access).

### 15.3 MCP Tool Registry

**Initial MCP Tool Set (ships with AI Chat MVP):**

| Tool | Description | Data Source | Notes |
|------|-------------|-------------|-------|
| `search_portfolio` | Search across all entity types by keyword | `global_search` RPC (deployed, 12 entity types) | Primary discovery tool. Wraps the same RPC as Ctrl+K. |
| `get_application_detail` | Full application record with deployment profiles and scores | `applications` + `deployment_profiles` + `portfolio_assignments` | Returns app identity + all DPs with TIME/PAID scores |
| `get_lifecycle_risk` | Technology lifecycle/EOL status for a deployment profile | `vw_technology_tag_lifecycle_risk` view | Already in implementation example below |
| `get_cost_summary` | Run rate and cost breakdown for a workspace or application | `vw_run_rate_by_vendor` view | Answers "how much are we spending on X?" |
| `get_integration_map` | Upstream/downstream integrations for an application | `integration_instances` + junction tables | Answers "what does X connect to?" |
| `get_assessment_status` | Assessment completion across a portfolio or workspace | `deployment_profiles` assessment columns + `portfolio_assignments` | Answers "what hasn't been assessed yet?" |

> **Tool set is driven by user questions, not schema coverage.** Tools are added when AI Chat MVP user testing reveals questions that can't be answered with the current set. The 90-table schema has far more data than AI Chat needs in v1 — resist the urge to expose everything.

**Implementation Example:**

```typescript
// supabase/functions/ai-chat/index.ts (simplified)
const tools = [
  {
    name: 'query_applications',
    description: 'Search applications by name, status, or technology',
    input_schema: { type: 'object', properties: { query: { type: 'string' } } }
  },
  {
    name: 'get_lifecycle_risk',
    description: 'Check technology lifecycle/EOL status for a deployment profile',
    input_schema: { type: 'object', properties: { dp_id: { type: 'string' } } }
  }
];

// Claude calls tools → function executes them → returns results to Claude
async function handleToolCall(name: string, input: any, supabaseUser: any) {
  switch (name) {
    case 'query_applications':
      return await supabaseUser.rpc('global_search', { search_term: input.query });
    case 'get_lifecycle_risk':
      return await supabaseUser
        .from('vw_technology_tag_lifecycle_risk')
        .select('*')
        .eq('deployment_profile_id', input.dp_id);
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}
```

### 15.4 Global Search → AI Chat Handoff

The `POST /ai-chat` request body accepts an optional `searchContext` field that enables contextual handoff from the Global Search overlay:

```typescript
interface AiChatRequest {
  query: string;
  workspaceId: string;
  conversationId?: string;       // for multi-turn
  searchContext?: {
    originalQuery: string;       // what the user typed in Ctrl+K
    results: SearchResult[];     // top results from global_search
    selectedEntityType?: string; // if user filtered by entity type
  };
}
```

**When `searchContext` is present:** The AI Chat system prompt includes the search results as grounding context, so Claude can reference specific applications, deployment profiles, or other entities the user was already looking at. This avoids Claude re-searching for data the user has already found.

**When `searchContext` is absent:** AI Chat starts with a clean conversation and uses the `search_portfolio` tool (§15.3) to discover relevant entities on demand.

**Cross-references:**
- `features/global-search/architecture.md` §10.2–10.3 — frontend UX for the search-to-chat handoff (contextual AI prompts in search overlay)
- `features/ai-chat/mvp.md` — full conversation flow, streaming, and usage tracking

---

## 16. Data Residency

### 16.1 Edge Function Execution Location

Supabase Edge Functions run globally at the nearest edge location to the user. This means function **code execution** may happen outside Canada. However:

- **Data at rest** remains in `ca-central-1` (PostgreSQL)
- **Data in transit** is encrypted (TLS)
- **Function code** contains no customer data — it processes and returns, stateless

### 16.2 External API Calls

When an Edge Function calls Claude API or Resend, customer data transits through the external provider's infrastructure. This must be disclosed in the privacy policy and data processing agreements.

| External Service | Data Sent | Provider Location | Mitigation |
|---|---|---|---|
| Claude API (Anthropic) | Query text, potentially app names/descriptions | US | Anonymize where possible, document in DPA |
| Resend | Email addresses, digest content | US | Standard email processing, document in DPA |
| ServiceNow | CSDM data (customer-initiated sync) | Customer's instance region | Customer controls what syncs |
| Cloud Providers | IAM tokens (no data retrieved stored) | Provider regions | Read-only discovery, no data persisted outside CA |

### 16.3 Principle

> Edge Functions process data in flight but do not store it. All persistent data remains in Canadian-region PostgreSQL. External API calls are documented in the privacy policy and subject to customer consent.

### 16.4 Multi-Region Edge Function Deployment (Deferred)

The `namespaces.region` column supports `ca`, `us`, and `eu` values, and Architecture Principle #6 mandates separate Supabase projects per region for complete data isolation. However, **all current namespaces are `ca`**, all Edge Functions target the single `ca-central-1` Supabase project, and the multi-region Edge Function deployment pattern is not yet needed.

This section will be expanded into a full design before the first non-CA namespace is onboarded. The following design questions must be resolved:

1. **Per-region Edge Function deployment:** One set of functions per Supabase project (each regional project gets its own Edge Function deployment), or shared functions with region routing logic?
2. **Secret management:** Duplicate secrets per regional project (e.g., `ANTHROPIC_API_KEY` set on each), or centralized secret store with region-prefixed env vars (e.g., `SUPABASE_URL_CA`, `SUPABASE_URL_US`, `SUPABASE_URL_EU`)?
3. **JWKS routing:** The `jose` auth pattern (§6.2) hardcodes a single JWKS URL derived from `SUPABASE_URL`. Each regional project has its own signing keys. Resolution options: derive JWKS URL from the token's `iss` claim, or use region-prefixed env vars.
4. **GDPR implications for EU:** Data-in-transit through global edge nodes (Deno Deploy executes at nearest edge, which may be outside EU), right-to-erasure callbacks across Edge Function logs, data processing agreements with Supabase/Deno Deploy.
5. **AI Chat embeddings isolation:** The `apm_embeddings` table is per-project, meaning no cross-region semantic search. Confirm this is acceptable (EU customers cannot search CA data and vice versa).

**Trigger:** This section becomes active when the first US or EU customer onboards. Estimated effort: 3–5 days architecture, 1–2 days implementation per region.

---

## 17. Inbound API Layer (Planned)

The Edge Functions architecture (§1–§16) is entirely **outbound**: the browser calls Edge Functions, which call external APIs (Claude, endoflife.date, Resend, etc.). No current or planned functions expose GetInSync data to external consumers. This gap must be addressed for GetInSync's positioning as a "CSDM Agent" — external systems need to consume curated APM data.

### 17.1 Consumer Drivers

Two planned integrations will drive the inbound API design:

1. **ServiceNow Subscribe (Phase 37c, Q3 2026):** ServiceNow pulls curated CSDM-aligned data from GetInSync — applications, deployment profiles, technology stacks, lifecycle status. This is the primary use case and the core of the CSDM Agent value proposition.
2. **HaloITSM sync:** HaloITSM pushes and pulls ITSM data for the secondary (SMB/municipal) market. Includes both REST polling and webhook-based near-real-time sync.

### 17.2 Design Questions (To Resolve Before Q3)

1. **Curated API vs raw PostgREST:** Supabase auto-generates a REST API from the schema, but exposing raw tables (e.g., `portfolio_assignments`) to external consumers undermines the CSDM Agent value prop. A curated domain API with clean endpoints (e.g., `/v1/portfolios/{id}/applications`) is likely required. Decision needed.
2. **OpenAPI (Swagger) specification:** If curated API, generate an OpenAPI spec for developer documentation and client SDK generation. This becomes part of the product's value proposition — the spec IS the CSDM contract.
3. **External consumer authentication:** API keys (stored in `integration_connections`), OAuth 2.0 client credentials, or both. Must be independent of Supabase user JWTs (§6.2 pattern serves internal users only).
4. **API key issuance and management:** Per-namespace scoping, rotation policy, revocation, usage tracking.
5. **Rate limiting for external consumers:** Distinct from internal per-user limits in §14. Per-API-key throttling with configurable limits per integration connection.
6. **API versioning strategy:** URL path (`/v1/`) preferred for simplicity. Breaking changes require version bump.
7. **Webhook patterns:** Both outbound (GetInSync pushing change events to subscribers) and inbound (receiving callbacks from ServiceNow/HaloITSM). Inbound needs: HMAC signature verification, idempotency keys, retry/dedup logic, dead letter handling.
8. **Developer documentation / portal:** Even for partner-only API, need interactive docs (Swagger UI or similar) for integration developers.

**Trigger:** Design begins Q3 2026 alongside Phase 37c (ServiceNow Subscribe). Standalone document `infrastructure/api-gateway-architecture.md` will be created when design begins — this section serves as the requirements seed.

---

## 18. Implementation Sequence

| Phase | What | When | Depends On |
|---|---|---|---|
| **E1** | Scaffold `supabase/functions/` directory, `_shared/` utilities, CORS, error handling, auth pattern | With first function build | Nothing |
| **E2** | `ai-chat` — first production Edge Function | Q2 2026 (AI Chat MVP) | E1, Global Search deployed |
| **E3** | `session-enforce` — simplest standalone function | Q2 2026 (with Realtime P4) | E1 |
| **E4** | `email-digest` — cron-triggered, no JWT | Q2–Q3 2026 (Gamification) | E1 |
| **E5** | `lifecycle-lookup` — extract from ai-chat if reusable | Q2–Q3 2026 | E2 proves the pattern |
| **E6** | `integration-sync` — customer-scoped credentials pattern | Q3 2026 | E1, Vault per-customer secret design |
| **E7** | `cloud-discovery` — most complex, customer IAM | Q3–Q4 2026 | E6 (same credential pattern) |
| **E8** | CI/CD pipeline for Edge Functions | After E2 ships and stabilizes | E2 |

**E1 and E2 ship together.** There's no value in scaffolding without a consumer.

---

## 19. Relationship to Other Architecture Docs

| Document | Relationship |
|---|---|
| `features/realtime-subscriptions/architecture.md` | Realtime is client-only (P1–P4). Session enforcement (P4 hard mode) depends on this doc's `session-enforce` function. |
| `features/ai-chat/mvp.md` | AI Chat is the first consumer of this infrastructure layer. MVP spec defines query patterns; this doc defines how they execute server-side. |
| `features/global-search/architecture.md` | Global Search RPC is wrapped as `search_portfolio` MCP tool (§15.3). Search-to-chat handoff contract in §15.4. |
| `features/gamification/architecture.md` | Email digest and re-engagement use the `email-digest` function defined here. |
| `features/technology-health/lifecycle-intelligence.md` | Automated lifecycle lookups use the `lifecycle-lookup` function defined here. |
| `features/cloud-discovery/architecture.md` | Cloud Discovery uses the `cloud-discovery` function defined here. |
| `identity-security/identity-security.md` | SSO/SAML callbacks will be Edge Functions. Pattern established here, specifics in identity-security doc. |
| `operations/development-rules.md` | Needs update to add §3: Edge Function development rules (Deno, testing, deployment). |
| `infrastructure/api-gateway-architecture.md` | **Planned.** Inbound API design document — created when §17 design begins (Q3 2026). |
| `reviews/edge-functions-gap-analysis.md` | Gap analysis that prompted §16.4, §17, and §15.3–15.4 additions in v1.2. |

---

## 20. What This Layer Does NOT Cover

| Concern | Why Not | Where It Lives |
|---|---|---|
| Frontend UI for AI Chat | UI component design | `features/ai-chat/mvp.md` |
| Database schema changes | Schema is Stuart's domain via SQL Editor | Feature-specific architecture docs |
| Supabase Realtime subscriptions | Client-side only | `features/realtime-subscriptions/architecture.md` |
| CI/CD for frontend | Already exists (Netlify + GitHub Actions) | Existing pipeline |
| Infrastructure monitoring beyond Edge Functions | Supabase Dashboard handles DB, Auth, Storage | `operations/` docs |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.3 | 2026-03-13 | **Scaffold deployed.** `_shared/auth.ts` (jose JWKS verification) and `_shared/error-handler.ts` (standardized error responses) implemented. `_shared/cors.ts` updated with `handleCors()` helper. `lifecycle-lookup` updated to use new auth pattern — §6.5 401 bug fixed. §5.3 updated to reflect deployed status. |
| v1.2 | 2026-03-09 | **Gap analysis response.** Added §16.4 multi-region placeholder (deferred until first non-CA customer). Added §17 inbound API layer placeholder (design triggers Q3 with Phase 37c). Expanded §15.3 with 6-tool MCP registry table and extraction criteria. Added §15.4 search-to-chat handoff contract. Per `reviews/edge-functions-gap-analysis.md`. |
| v1.1 | 2026-03-09 | **Auth pattern update.** §6.2 rewritten: replaced `auth.getUser(token)` (network round-trip) with `jose` JWKS local verification (Supabase's March 2026 recommendation). Added §6.5 documenting 401 root cause, affected functions, and fix plan. §5.2 updated: `lifecycle-lookup` status → Deployed, `technology-catalog-search` → Retired (replaced by browser client). §5.3 updated to reflect actual deployed `_shared/` utilities vs planned. |
| v1.0 | 2026-03-04 | Initial architecture. Eight consumer features mapped. Secret management (Edge Secrets + Vault). Function registry. Auth pattern. MCP inline tool strategy. Canadian data residency analysis. Implementation sequence E1–E8. |
