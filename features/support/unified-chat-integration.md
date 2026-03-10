# Unified Chat Integration Architecture

**Version:** 1.0.1
**Status:** 🟡 AS-DESIGNED
**Author:** Stuart Holtby
**Date:** March 2026

---

## 1. Purpose

GetInSync NextGen has three features in design that converge into a single user experience:

1. **In-App Support** — live chat (Crisp/Chatwoot), product tours (Shepherd.js), help content (GitBook). Documented in `features/support/in-app-support-architecture.md` (v1.1).
2. **AI Chat** — natural language portfolio queries via Claude + MCP tools. Documented in `features/ai-chat/mvp.md`, `v2.md`, `v3-multicloud.md`.
3. **Edge Functions Layer** — server-side execution for AI Chat, lifecycle lookup, email digest. Documented in `infrastructure/edge-functions-layer-architecture.md` (v1.2).

Each feature is **atomic** — it ships independently, delivers value on its own, and has no hard dependency on the others. But when all three are live, they merge into a unified experience: one chat bubble, AI-first responses, human escalation, contextual help, product tours — all feeling like a single integrated product, not three bolted-on tools.

**This document defines the composition architecture** — how the features merge, not how each works individually. It specifies the shared context model, routing logic, native chat panel, UI coordination, conversation lifecycle, and five-step sequencing plan.

**Design principle:** The user clicks the help bubble, types a question, and gets an answer. They don't know or care whether Claude, Stuart, Delta, or a help article answered it. One panel, one conversation, one experience.

---

## 2. Prerequisites

### 2.1 Required Before Unification

| # | Prerequisite | Status | Source Document |
|---|-------------|--------|-----------------|
| P1 | In-App Support S.1–S.4 (abstraction layer, Shepherd, Crisp, HelpMenu) | Planned (3.25 dev days) | `features/support/implementation-plan.md` |
| P2 | AI Chat E1+E2 (Edge Function scaffold + ai-chat function with MCP tools) | Planned (Q2 2026) | `infrastructure/edge-functions-layer-architecture.md` §18 |
| P3 | Global Search (Ctrl+K overlay, `global_search` RPC) | Deployed | `features/global-search/architecture.md` |
| P4 | `_shared/auth.ts` — jose/JWKS JWT validation utility | Planned (E1 scaffold) | `infrastructure/edge-functions-layer-architecture.md` §6.2 |
| P5 | Conversation persistence tables (`apm_conversations`, `apm_conversation_messages`) | Gap — needs design | `reviews/ai-chat-context-window-review.md` Gap 2 |

### 2.2 Optional Prerequisites

- **Impersonation (Phase 25.12)** — "View as User" mode in namespace management. Enhances the unified experience (Step 5) but does not block Steps 1–4. See `core/namespace-management-ui.md` §12.

### 2.3 Prerequisite Gaps from AI Chat Review

The AI Chat context window review (`reviews/ai-chat-context-window-review.md`) identified gaps that affect this integration design. These are acknowledged here as prerequisites — solutions belong in the AI Chat architecture docs, not this document.

**Gap 4 (HIGH): RAG vs MCP architectural mismatch.**
- AI Chat docs use an embed→search→stuff-context pattern (RAG). Edge Functions §15.3 defines 6 MCP tools assuming a tool-use pattern.
- This design assumes AI Chat resolves Gap 4 in favor of MCP tool-use (or a hybrid where RAG provides baseline context and MCP tools provide on-demand structured data).
- If AI Chat ships as RAG-only, §5 (Native Chat Panel) degrades to plain-text/markdown rendering. The native panel can still display responses, but loses the structured data that enables portfolio cards, score badges, and inline charts.

**Gaps 1–3 (HIGH): No context budget, no conversation persistence, no token counting.**
- This design requires `apm_conversations` and `apm_conversation_messages` tables (or equivalent) to be implemented as part of AI Chat E2.
- Conversation persistence is a prerequisite for Steps 3–5, not a nice-to-have. Persistence enables:
  - (a) Continuous thread across AI and human segments
  - (b) Passing conversation history to Crisp on escalation
  - (c) Isolating impersonation conversations from customer history
  - (d) Conversation resumption after page refresh

**Gap 7 (MEDIUM): Deprecated auth pattern in all AI Chat docs.**
- All three AI Chat versions use `auth.getUser()` which causes intermittent 401 failures due to network round-trips.
- Edge Functions §6.2 defines the replacement: jose JWKS local JWT verification via `_shared/auth.ts`.
- AI Chat E2 ships with the jose JWKS auth pattern. The deprecated `auth.getUser()` pattern in the AI Chat architecture docs is superseded.

---

## 3. Shared Context Model

Three features currently define separate context objects for three different consumers:
- **ChatContextBridge** (in-app support, implementation-plan.md S.3) pushes `currentPage`, `namespace`, `workspace`, `tier`, `role`, `appCount` to Crisp
- **AiChatRequest** (edge functions §15.4) accepts `searchContext` from Global Search
- **Impersonation** (namespace-management-ui.md §12) will add an impersonation banner and session context

The `UnifiedChatContext` replaces these with a single shape that all three consumers produce and consume.

### 3.1 UnifiedChatContext Interface

```typescript
interface UnifiedChatContext {
  // ── User identity ──
  userId: string;
  email: string;
  displayName: string;
  namespaceRole: 'admin' | 'editor' | 'steward' | 'viewer' | 'restricted';
  namespaceTier: 'trial' | 'essentials' | 'plus' | 'enterprise';

  // ── Navigation ──
  currentPage: string;      // e.g., '/app-health', '/applications/uuid'
  activeTab: 'overview' | 'dashboard' | 'technology-health' | 'roadmap';

  // ── Workspace scope ──
  namespaceId: string;
  workspaceId: string | null;      // null when 'All Workspaces' selected
  workspaceName: string | null;

  // ── Portfolio context ──
  portfolioId: string | null;      // null when 'All Portfolios' selected
  portfolioName: string | null;

  // ── Stats (for AI grounding) ──
  appCount: number;
  assessmentCompletion: number;    // percentage (0–100)

  // ── Impersonation (Step 5) ──
  isImpersonating: boolean;
  platformAdminId: string | null;
}
```

### 3.2 Field Source Mapping

| Field | Source Hook/Context | Access Path | Notes |
|-------|-------------------|-------------|-------|
| `userId` | `useAuth()` | `user.id` | `src/contexts/AuthContext.tsx` |
| `email` | `useAuth()` | `user.email` | Supabase `User` type |
| `displayName` | Separate query | `users.name` or `user.email` fallback | AuthContext doesn't expose user name directly |
| `namespaceRole` | Separate query | AuthContext queries `users.namespace_role` internally but only exposes `isNamespaceAdmin: boolean`. ChatContextBridge queries independently. | Candidate for AuthContext extension in future refactor |
| `namespaceTier` | `useTierLimits()` | `tier` field | `src/hooks/useTierLimits.ts` queries `namespaces.tier` |
| `currentPage` | `useLocation()` | `location.pathname` | react-router-dom |
| `activeTab` | `useScope()` | `activeTab` | `src/contexts/ScopeContext.tsx` |
| `namespaceId` | `useAuth()` | `namespace.id` | AuthContext |
| `workspaceId` | `useAuth()` | `currentWorkspace?.id` | Normalize: if sentinel value `'all-workspaces'`, set to `null` |
| `workspaceName` | `useAuth()` | `currentWorkspace?.name` | Same normalization |
| `portfolioId` | `useScope()` | `selectedPortfolioId` | ScopeContext — `null` when "All Portfolios" |
| `portfolioName` | `useScope()` | `selectedPortfolio?.name` | Derived from portfolios array in ScopeContext |
| `appCount` | Dashboard query | Lightweight count query | ChatContextBridge fetches independently |
| `assessmentCompletion` | Dashboard query | `Math.round((assessed_count / total_dps) * 100)` from `vw_dashboard_summary` | Computed from `assessed_count` / `total_dps`. Falls back to 0 when no DPs exist. Same view used by dashboard KPI cards. |
| `isImpersonating` | Future `ImpersonationContext` | Default `false` until Phase 25.12 | No impersonation code exists yet |
| `platformAdminId` | Future `ImpersonationContext` | Default `null` | No impersonation code exists yet |

### 3.3 Context Consumers

| Consumer | What It Receives | How |
|----------|-----------------|-----|
| AI Chat Edge Function | Full `UnifiedChatContext` serialized as JSON | Sent with `AiChatRequest` body to ground Claude's system prompt |
| Crisp/Chatwoot | Flattened subset: `currentPage`, `namespaceId`, `workspaceName`, `namespaceTier`, `namespaceRole`, `appCount` | `ChatService.setCustomData()` on every navigation change |
| Help content (HelpLinkService) | `activeTab` + `currentPage` | Used to suggest contextually relevant GitBook articles |

---

## 4. ChatRouter Architecture

The ChatRouter sits between the native chat panel UI and the two backends (AI Chat edge function, Crisp/Chatwoot). It decides where each message goes based on tier, availability, user intent, and impersonation state.

### 4.1 Routing Decision Tree

```
User sends message
  │
  ├─ Is AI Chat available?
  │   (tier = plus|enterprise AND ai-chat Edge Function healthy)
  │   │
  │   ├─ NO (tier = trial|essentials, OR Edge Function unavailable)
  │   │   └─ Route to Crisp/Chatwoot via ChatService.sendMessage()
  │   │
  │   └─ YES
  │       │
  │       ├─ Explicit human-agent request?
  │       │   (user clicked "Talk to a human" or "Report a bug")
  │       │   ├─ YES → Route to Crisp/Chatwoot
  │       │   └─ NO
  │       │       │
  │       │       ├─ Is the user impersonating? (Step 5)
  │       │       │   ├─ YES → Route to AI Chat
  │       │       │   │   • Suppress human escalation button
  │       │       │   │   • Flag conversation: is_impersonated = true
  │       │       │   │   • Track tokens against platformAdminId
  │       │       │   │   • Rate limits use platform admin quotas
  │       │       │   │
  │       │       │   └─ NO → Route to AI Chat
  │       │       │       • Normal flow, escalation available
  │       │       │
  │       │       [AI Chat response arrives]
  │       │       │
  │       │       ├─ AI responded successfully → Display response
  │       │       ├─ AI signaled "I can't help" → Offer escalation
  │       │       └─ AI failed (timeout/error) → Toast + "Talk to a human" fallback
```

### 4.2 Routing Categories

| Category | Route Target | Examples |
|----------|-------------|---------|
| Portfolio / application queries | AI Chat | "Which apps should we migrate?", "Show Tolerate apps" |
| Technology / lifecycle | AI Chat | "What SQL Server versions are deployed?", "EOL technologies" |
| Cost / budget | AI Chat | "How much do we spend on Oracle?", "Over-budget workspaces" |
| Assessment status | AI Chat | "What hasn't been assessed yet?", "Unscored deployment profiles" |
| Account / billing | Crisp (human) | "Change my plan", "Invoice question" |
| Bug reports | Crisp (human) | "Something broke", "I see an error" |
| Feature requests | Crisp (human) | "Can you add...", "I wish I could..." |
| User-initiated escalation | Crisp (human) | "Talk to a human", "I need help from support" |
| AI failure fallback | Crisp (human) | Edge Function 5xx, rate limit exceeded, timeout |

**Note:** The ChatRouter does not perform intent classification on the message text. All messages go to AI Chat first (when available). The routing categories above describe the expected behavior: Claude naturally handles portfolio queries and signals when it cannot help with billing/account questions, triggering the escalation path.

### 4.3 Escalation Contract

When the conversation escalates from AI to human, the ChatRouter packages the full context for the human agent:

```typescript
interface EscalationPayload {
  conversationId: string;
  messages: ConversationMessage[];   // full AI conversation history
  context: UnifiedChatContext;       // user's current state
  escalationReason: 'user_requested' | 'ai_cannot_help' | 'ai_error';
  timestamp: string;                 // ISO 8601
}
```

This payload is formatted as a summary message and passed to `ChatService.sendMessage()` so the human agent (Stuart/Delta) sees the full context in their Crisp/Chatwoot dashboard.

### 4.4 Impersonation Rules (Step 5)

| Rule | Behavior |
|------|----------|
| Human escalation | Suppressed — "Talk to a human" button hidden (Delta IS the human during impersonation) |
| Conversation flagging | `is_impersonated = true` on `apm_conversations` record |
| Token tracking | Usage tracked against `platformAdminId`, not the impersonated user |
| Rate limits | Platform admin quotas apply, not customer quotas |
| Conversation history | Excluded from customer conversation history; visible in platform admin audit trail |

### 4.5 Tier Gating

| Tier | AI Chat Access | Chat Routing Behavior |
|------|---------------|----------------------|
| trial | No | All messages route to Crisp/Chatwoot |
| essentials | No | All messages route to Crisp/Chatwoot |
| plus | Yes | AI-first with human fallback on escalation |
| enterprise | Yes | AI-first with human fallback on escalation |

Rate limits per tier align with `infrastructure/edge-functions-layer-architecture.md` §14.1.

---

## 5. Native Chat Panel

The native chat panel replaces the Crisp/Chatwoot widget chrome for AI conversations. It renders structured, rich responses that the third-party widget cannot support.

### 5.1 Design Requirements

| Property | Value | Rationale |
|----------|-------|-----------|
| Position | Fixed, bottom-right | Industry-standard chat widget placement |
| Dimensions | 400px wide × 500px tall | Comfortable for reading; resizable via drag handle |
| Collapsed state | 48px circular bubble with GetInSync logo + unread count badge | Minimal footprint when not in use |
| Z-index | `z-[8000]` | Above all app content (max z-70), below Shepherd tours (z-[9000]) |
| Portal | `ReactDOM.createPortal(panel, document.body)` | Z-index independent of React component tree |
| Styling | `teal-600` header, `rounded-lg`, `shadow-lg`, `bg-white` body | Per `operations/screen-building-guidelines.md` |
| Mobile | Full-screen takeover at viewport width < 640px | Standard responsive pattern |
| Accessibility | Focus trap when open, keyboard navigation (Esc to close, Tab through messages), `aria-live="polite"` on message list | WCAG compliance |

### 5.2 Message Rendering

| Message Type | Alignment | Background | Avatar |
|-------------|-----------|------------|--------|
| AI response | Left | `bg-gray-100` | Sparkle icon (or GetInSync logo) |
| Human agent | Left | `bg-blue-100` | Human avatar (from Crisp agent profile) |
| User message | Right | `bg-teal-600 text-white` | None |
| System message | Center | None (inline `text-gray-500`) | None |

**Rich content rendering (when MCP tool-use is active):**
- Portfolio cards with TIME quadrant badges and assessment scores
- Lifecycle risk indicators with EOL dates
- Cost summary tables with run rate breakdowns
- Inline mini charts for budget variance

**Degraded rendering (if AI Chat ships as RAG-only — Gap 4 unresolved):**
- Plain text and markdown rendering only
- No structured data cards or inline charts
- Functional but not visually rich

### 5.3 Panel Interactions

| Interaction | Behavior |
|-------------|----------|
| Send message | Enter key (Shift+Enter for newline) |
| Streaming indicator | Three-dot animation during AI response streaming |
| Minimize | Header button — collapses to bubble |
| Close | Header button — closes panel, stops any streaming |
| Escalate | "Talk to a human" in panel footer — hidden during impersonation |
| Clear conversation | Header overflow menu — starts fresh thread |
| Conversation history | Header overflow menu — shows past conversations (read-only for closed) |

---

## 6. UI Surface Coordination

### 6.1 Mutual Exclusion Rules

| Action | Effect |
|--------|--------|
| Open chat panel | Closes GlobalSearchOverlay (if open) |
| Open GlobalSearchOverlay (Ctrl+K) | Minimizes chat panel to bubble (if open) |
| Open chat panel | Closes HelpMenu dropdown (if open) |
| Shepherd tour starts | Chat panel remains open (different z-layer, tours are above) |
| Open modal (z-50) | Chat panel remains visible behind modal (z-[8000] > z-50) — user can dismiss modal and return to chat |

**Coordination mechanism:** The Global Search overlay is toggled via `searchOpen` / `setSearchOpen` state in `App.tsx` (line 98). The NativeChatPanel (portaled to `document.body`) needs a callback to close the search overlay when opening. Recommended: pass a `closeSearch` callback through `ChatContextBridge`. Implementation decision deferred to Step 3.

### 6.2 Complete Z-Index Stacking Order

| Layer | Z-Index | Source | Status |
|-------|---------|--------|--------|
| Overlay backdrops (dropdowns) | `z-10` | WorkspaceSwitcher, UserMenu | Existing |
| Dropdown panels | `z-20` | WorkspaceSwitcher, UserMenu, HelpMenu | Existing (HelpMenu added in S.4) |
| Sticky block (banner + tabs + toolbar) | `z-30` | `operations/screen-building-guidelines.md` §1.4 | Existing |
| Global header, filter drawer backdrop | `z-40` | AppHeader, App.tsx inline header | Existing |
| Modal overlays, filter drawer panel, GlobalSearchOverlay | `z-50` | Various modals, filter drawer, search | Existing |
| Stacked modals (confirmations above modals) | `z-[60]` | ApplicationPage, ContactPicker, UnsavedChangesModal, link modals | Existing |
| Deep-stacked modals (dependency confirmations) | `z-[70]` | ITServiceDependencyList | Existing |
| **Native chat panel** | **`z-[8000]`** | `NativeChatPanel.tsx` (portal to body) | **New — Step 3** |
| **Shepherd tour overlay** | **`z-[9000]`** | `shepherd-theme.css` | New — S.2 |
| **Shepherd tour tooltip** | **`z-[9001]`** | `shepherd-theme.css` | New — S.2 |
| Crisp/Chatwoot widget (SDK-managed) | ~10000 | Crisp SDK default | New — S.3, hidden after Step 3 replaces it |

### 6.3 Tour-to-Chat Integration

Shepherd tour steps can include an action that opens the chat panel with a pre-filled query:

```typescript
// Example: tour step on Technology Health tab
{
  text: 'Want to explore your technology risk? Ask the AI.',
  buttons: [
    {
      text: 'Ask AI',
      action: () => {
        chatRouter.openWithQuery('What technologies are approaching end-of-life?');
        tour.next();
      }
    },
    { text: 'Skip', action: tour.next },
  ]
}
```

This creates a natural bridge between guided onboarding and AI-powered exploration.

### 6.4 Help-to-Chat Integration

AI Chat responses can cite specific GitBook help articles via `HelpLinkService.getArticleUrl()`:

- The article slug registry (`src/support/help/articles.ts`, defined in implementation-plan.md S.1) maps topic slugs to GitBook URLs
- The AI Chat system prompt includes available article slugs so Claude can reference them
- Response format: "For more about TIME quadrant placement, see [TIME Framework](https://docs.getinsync.ca/time-framework)"

---

## 7. Conversation Lifecycle

### 7.1 Persistence Model

Conversations are stored in two database tables (prerequisite P5 — table design belongs in the AI Chat architecture docs, cross-reference `reviews/ai-chat-context-window-review.md` Gaps 1–3):

**`apm_conversations`:**

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID PK | Conversation identifier |
| `namespace_id` | UUID FK → namespaces | Namespace isolation (RLS) |
| `user_id` | UUID FK → users | Conversation owner |
| `workspace_id` | UUID FK → workspaces (nullable) | Workspace context at conversation start |
| `title` | TEXT | Auto-generated from first message |
| `status` | TEXT | `active` / `escalated` / `closed` |
| `source` | TEXT | `ai` / `human` / `mixed` |
| `is_impersonated` | BOOLEAN | `true` when created during impersonation |
| `platform_admin_id` | UUID FK → users (nullable) | Who was impersonating |
| `escalation_reason` | TEXT (nullable) | `user_requested` / `ai_cannot_help` / `ai_error` |
| `context_snapshot` | JSONB | `UnifiedChatContext` at conversation start |
| `created_at` | TIMESTAMPTZ | Conversation start |
| `updated_at` | TIMESTAMPTZ | Last message timestamp |

**`apm_conversation_messages`:**

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID PK | Message identifier |
| `conversation_id` | UUID FK → apm_conversations | Parent conversation |
| `role` | TEXT | `user` / `assistant` / `system` |
| `source` | TEXT | `ai` / `human_agent` / `system` |
| `content` | TEXT | Message body |
| `tool_calls` | JSONB (nullable) | MCP tool calls made for this response |
| `token_count` | INTEGER (nullable) | Estimated tokens for budget tracking |
| `created_at` | TIMESTAMPTZ | Message timestamp |

**RLS:** Namespace isolation via `namespace_id = (auth.jwt()->>'namespace_id')::uuid`. Impersonated conversations additionally require `is_platform_admin()` for access.

### 7.2 Unified Thread Model

The user sees **one continuous conversation thread** regardless of backend. Each message is tagged with `source` (`ai` | `human_agent` | `system`). The UI renders different avatars per source but presents a single scrollable thread.

**Escalation flow (user perspective):**
1. User is chatting with AI
2. User clicks "Talk to a human" (or AI signals it can't help)
3. System message appears: "Connecting you to a team member..."
4. Human agent messages appear in the same thread with a different avatar
5. Conversation continues seamlessly — no page change, no modal, no mode switch

### 7.3 Impersonation Isolation

When `is_impersonated = true`:
- Conversation is excluded from the customer's conversation history
- Visible only to platform admins (via `is_platform_admin()` RLS policy)
- Token usage attributed to `platform_admin_id`
- Conversation appears in the platform admin audit trail

### 7.4 Retention Policy

| Tier | Retention Period | Max Active Conversations |
|------|-----------------|------------------------|
| trial | 7 days | 5 |
| essentials | 30 days | 20 |
| plus | 90 days | Unlimited |
| enterprise | 365 days | Unlimited |

Expired conversations are soft-deleted (status → `archived`). A scheduled cleanup function removes archived conversations older than the retention period.

---

## 8. Provider Tree Integration

### 8.1 Updated Provider Hierarchy

```
App()                                        [src/App.tsx, line 904]
  AuthProvider                               [line 906]
    SupportProvider                          [NEW — after AuthProvider, wraps all children]
      Toaster (position="top-right")         [line 907]
      ErrorBoundary                          [line 908]
        Routes                               [line 909]
          ProtectedRoute
            WorkspaceScopedMainApp
              ScopeProvider                  [line 898]
                Outlet → MainApp
                  ChatContextBridge          [NEW — reads all contexts, produces UnifiedChatContext]
                  NativeChatPanel (portal)   [NEW — portaled to document.body, receives context]
```

### 8.2 Context Dependencies

| Component | Has Access To | Does NOT Have Access To |
|-----------|--------------|------------------------|
| `SupportProvider` | `useAuth()` (user, workspace, namespace) | `useScope()` (tab, portfolio) — ScopeProvider is a descendant |
| `ChatContextBridge` | `useAuth()`, `useScope()`, `useLocation()`, `useTierLimits()` | — (has access to everything, placed inside MainApp) |
| `NativeChatPanel` | `UnifiedChatContext` via prop/ref from ChatContextBridge | Direct hook access not needed — receives assembled context |

### 8.3 Why the Bridge Pattern

SupportProvider must sit above ScopeProvider in the tree (it needs to be available on non-workspace routes like login). But it cannot access `useScope()` because ScopeProvider is a descendant. Rather than restructuring the entire provider hierarchy (a high-risk change touching every route component), a render-null `ChatContextBridge` component inside MainApp reads all contexts and pushes the assembled `UnifiedChatContext` to both the ChatRouter and the native chat panel.

This pattern is already established in `features/support/implementation-plan.md` S.3 for pushing Crisp context. The unification step extends it to also produce the full `UnifiedChatContext`.

---

## 9. Knowledge Base as AI Source

### 9.1 Article Registry

The `src/support/help/articles.ts` file (created in S.1) provides a slug-to-URL mapping for initial help articles. This registry becomes accessible to the AI Chat system as an MCP tool.

### 9.2 MCP Tool Extension

| Tool | Description | Data Source |
|------|-------------|-------------|
| `help_article_lookup` | Given a topic keyword, returns matching article slugs and URLs from the help registry | `src/support/help/articles.ts` slug-to-URL map |

This extends the 6-tool MCP registry from Edge Functions §15.3 to 7 tools.

### 9.3 AI Response Pattern

When the AI references concepts covered in the knowledge base, the system prompt instructs Claude to include a deep link:

> "Your Finance workspace has 3 applications in the Modernize quadrant. For more about how TIME quadrant placement works, see [TIME Framework](https://docs.getinsync.ca/time-framework)."

The system prompt includes the available article slugs so Claude can reference them naturally. Article freshness is code-deployed (slugs added to `articles.ts` with each release). If the article count exceeds 50 in the future, migrate to a database-backed registry.

---

## 10. Sequencing

### 10.1 Five-Step Implementation

| Step | Name | Timing | Effort | Dependencies |
|------|------|--------|--------|-------------|
| 1 | In-App Support S.1–S.7 | May 2026 (pre-Knowledge Conference) | 3.75 dev days | None |
| 2 | AI Chat E1+E2 | Q2 2026 | TBD | Global Search deployed, `_shared/auth.ts` |
| 3 | ChatRouter + Native Chat Panel | Q2 2026 (2 weeks after E2 stabilizes) | 3–4 dev days | Steps 1 + 2 |
| 4 | Impersonation Phase 25.12 | Q2–Q3 2026 (independent track) | TBD | None (independent) |
| 5 | Impersonation + Chat Intelligence | Q3 2026 (after Steps 3 + 4) | 1–2 dev days | Steps 3 + 4 |

### 10.2 Dependency Graph

```
Step 1 (In-App Support) ─────────────────────┐
                                              ├──→ Step 3 (ChatRouter + Panel) ──→ Step 5 (Impersonation + Chat)
Step 2 (AI Chat E1+E2) ──────────────────────┘                                      ↑
                                                                                      │
Step 4 (Impersonation) ───────────────────────────────────────────────────────────────┘
```

### 10.3 Step Triggers

| Transition | Trigger Condition |
|-----------|-------------------|
| Step 2 → Step 3 | AI Chat E2 error rate < 5% for 2 consecutive weeks (measured via Edge Function dashboard) |
| Steps 3 + 4 → Step 5 | Both Step 3 and Step 4 stable in production for 1 week |

### 10.4 What Users See at Each Milestone

| Milestone | User Experience |
|-----------|----------------|
| After Step 1 | Crisp chat bubble (bottom-right), Shepherd welcome tour, HelpMenu with GitBook links, contextual help icons |
| After Step 2 | "Ask AI" prompt appears in Ctrl+K search overlay (GlobalSearchOverlay) when AI results could enhance the search |
| After Step 3 | Native chat panel replaces Crisp bubble chrome for AI conversations. AI-first routing — Claude answers, human escalation available. Crisp becomes the escalation backend, not the user-facing widget. |
| After Step 4 | "View as User" mode in namespace admin UI. No chat changes. |
| After Step 5 | Impersonated sessions suppress human escalation. AI conversations during impersonation flagged and isolated from customer history. |

---

## 11. Codebase Impact Assessment

### 11.1 Files Created Per Step

| Step | New Files | Directory |
|------|-----------|-----------|
| 1 | ~20 files (types, config, providers, chat services, tour services, help services, components) | `src/support/` (new directory) |
| 2 | `supabase/functions/ai-chat/index.ts`, `supabase/functions/_shared/auth.ts`, `src/components/search/AiChatPrompt.tsx` | Edge Function + search component |
| 3 | `src/support/chat/ChatRouter.ts`, `src/support/chat/AiChatClient.ts`, `src/support/components/NativeChatPanel.tsx`, `src/support/components/ChatBubble.tsx` | Support + chat components |
| 4 | Namespace management files (TBD — independent of chat) | `src/components/super-admin/` |
| 5 | None (modifications only) | — |

### 11.2 Files Modified Per Step

| Step | File | Change |
|------|------|--------|
| **1** | `src/App.tsx` | Add `<SupportProvider>` wrapper after AuthProvider, add `<ChatContextBridge />` inside MainApp, add `data-tour` attributes to header elements |
| 1 | `src/components/shared/AppHeader.tsx` | Add `<HelpMenu />` component, add `data-tour="search-button"` |
| 1 | `src/components/navigation/MainTabBar.tsx` | Add `data-tour` attributes on tab buttons |
| 1 | `src/components/UserMenu.tsx` | Add `data-tour="user-menu"` |
| 1 | `package.json` | Add `shepherd.js`, `crisp-sdk-web` |
| **2** | `src/components/search/GlobalSearchOverlay.tsx` | Add "Ask AI" contextual prompt below search results |
| **3** | `src/support/SupportProvider.tsx` | Add ChatRouter initialization, pass AI Chat client reference |
| 3 | `src/App.tsx` | Add `<NativeChatPanel>` portal mount |
| 3 | `src/support/chat/ChatContextBridge.tsx` | Extend from Crisp-only context push to produce full `UnifiedChatContext` |
| **5** | `src/support/chat/ChatRouter.ts` | Add impersonation detection (`UnifiedChatContext.isImpersonating`) |
| 5 | `src/support/components/NativeChatPanel.tsx` | Conditionally hide escalation button during impersonation |

### 11.3 Coordination Risks

| File | Modified By | Risk |
|------|------------|------|
| `src/App.tsx` | Steps 1, 3 | Step 3 builds on Step 1's `SupportProvider`. Must be sequenced (Step 1 first). |
| `src/support/SupportProvider.tsx` | Steps 1, 3 | Step 3 adds ChatRouter to the provider created in Step 1. Must be sequenced. |
| `src/support/chat/ChatContextBridge.tsx` | Steps 1, 3 | Step 3 extends the bridge created in Step 1. Must be sequenced. |

No other files are modified by multiple steps.

---

## 12. What This Document Does NOT Cover

| Topic | Owner Document |
|-------|---------------|
| AI Chat conversation flow, prompt engineering, system prompt design | `features/ai-chat/mvp.md` |
| Edge Function infrastructure, deployment, secrets management | `infrastructure/edge-functions-layer-architecture.md` |
| In-App Support S.1–S.7 implementation details | `features/support/implementation-plan.md` |
| Impersonation core feature ("View as User" mode) | `core/namespace-management-ui.md` §12 |
| Gamification integration (tour completion feeds achievements) | `features/gamification/architecture.md` |
| RAG vs MCP architectural resolution | AI Chat architecture docs, informed by `reviews/ai-chat-context-window-review.md` Gap 4 |
| Conversation persistence table schema design (DDL) | AI Chat architecture docs, informed by `reviews/ai-chat-context-window-review.md` Gaps 1–3 |
| Context window token budget allocation | AI Chat architecture docs |
| Multi-region Edge Function deployment | `infrastructure/edge-functions-layer-architecture.md` §16.4 |

---

## 13. Decision Log

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| D1 | Unified widget over two entry points | One chat bubble, not separate "AI Chat" and "Support" buttons. The user doesn't know or care which backend answers — that distinction is an implementation detail, not a product feature. | 2026-03-09 |
| D2 | AI-first routing (Claude answers before human sees it) | Reduces human support load for portfolio, technology, and cost questions that Claude handles well. Government buyers (target market) still have a guaranteed path to a human agent. | 2026-03-09 |
| D3 | Native chat panel over Crisp widget chrome | Rich AI responses (portfolio cards, lifecycle badges, cost tables) require native React rendering. Crisp/Chatwoot widget chrome cannot display structured data components. | 2026-03-09 |
| D4 | Single conversation thread (user never sees backend boundary) | No "AI mode" vs "human mode" toggle. Escalation happens seamlessly within the same thread with only an avatar change to indicate who's responding. Reduces cognitive load. | 2026-03-09 |
| D5 | Impersonation suppresses human escalation (Delta IS the human) | During impersonation, the platform admin IS the human support agent. Generating support tickets from an impersonation session would be nonsensical and confusing. | 2026-03-09 |
| D6 | Five-step sequencing (atomic features first, integration after) | Each step delivers independent value. If later steps never ship, earlier steps still work. No step creates a hard dependency on a future step. | 2026-03-09 |
| D7 | Rich rendering depends on MCP tool-use (degrades gracefully to plain text) | Structured data components (portfolio cards, badges) require MCP tool responses. If Gap 4 resolves to RAG-only, the panel still functions with markdown rendering. No hard dependency. | 2026-03-09 |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0.1 | 2026-03-10 | Accuracy fixes from 360° harmonization review: §6.2 z-index table now includes z-[60] and z-[70] existing layers. §6.1 names the UI coordination mechanism (`searchOpen` state in App.tsx). §3.2 specifies `assessmentCompletion` source (`vw_dashboard_summary.assessed_count / total_dps`). §5.1 z-index note corrected from "max z-50" to "max z-70". |
| v1.0 | 2026-03-09 | Initial version. Composition architecture for unified support + AI chat + impersonation convergence. 13 sections covering shared context model, ChatRouter, native chat panel, UI coordination, conversation lifecycle, provider tree, knowledge base integration, 5-step sequencing, codebase impact assessment, decision log. Acknowledges 4 HIGH prerequisite gaps from AI Chat context window review. |

---

*Document: features/support/unified-chat-integration.md*
*March 2026*
