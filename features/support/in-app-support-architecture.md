# In-App Support & Engagement Architecture

**Version:** 1.3
**Status:** 🟢 PARTIALLY IMPLEMENTED (S.1–S.5, S.7 complete; S.6 remaining)
**Author:** Stuart Holtby
**Date:** March 2026

---

## 1. Purpose

Define the architecture for in-app support, onboarding tours, and help content in GetInSync NextGen. The design uses a **provider abstraction layer** so the underlying tools can be swapped without touching application code.

**Design goals:**
- Live chat support (Stuart + Delta as agents)
- Product tours / onboarding walkthroughs (code-native, no external dependency)
- Knowledge base / help articles (external hosted docs site)
- Zero monthly cost at launch; clear upgrade path
- Canadian data residency preferred but not blocking for support tooling

---

## 2. Architecture Overview

Three concerns, three tools, one abstraction:

```
┌─────────────────────────────────────────────────┐
│  GetInSync NextGen (React/TypeScript)            │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │  SupportProvider (abstraction layer)         │ │
│  │                                               │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │ │
│  │  │ ChatSvc  │ │ TourSvc  │ │ HelpLinkSvc  │ │ │
│  │  └────┬─────┘ └────┬─────┘ └──────┬───────┘ │ │
│  └───────┼─────────────┼──────────────┼─────────┘ │
│          │             │              │            │
└──────────┼─────────────┼──────────────┼────────────┘
           │             │              │
     ┌─────▼─────┐ ┌────▼────┐  ┌──────▼──────┐
     │  Crisp    │ │Shepherd │  │   GitBook   │
     │  (chat)   │ │  .js    │  │   (docs)    │
     │           │ │(tours)  │  │             │
     └─────┬─────┘ └─────────┘  └─────────────┘
           │
     ┌─────▼─────┐
     │ Chatwoot  │  ← swap target (Canadian VPS)
     │ (chat)    │
     └───────────┘
```

---

## 3. Provider Abstraction Layer

### 3.1 SupportProvider Context

A React context that wraps the app and exposes chat, tour, and help operations. All components interact with support features through this context — never directly with Crisp, Shepherd, or any provider SDK.

```typescript
// src/support/SupportProvider.tsx

interface SupportConfig {
  chat: ChatProviderConfig;
  tours: TourProviderConfig;
  help: HelpProviderConfig;
}

interface ChatProviderConfig {
  provider: 'crisp' | 'chatwoot' | 'intercom' | 'none';
  siteId?: string;        // Crisp website ID
  baseUrl?: string;       // Chatwoot instance URL
  websiteToken?: string;  // Chatwoot website token
}

interface TourProviderConfig {
  provider: 'shepherd';   // Only one option — code-native
  autoStartOnFirstLogin: boolean;
}

interface HelpProviderConfig {
  provider: 'gitbook' | 'custom';
  baseUrl: string;        // e.g., https://docs.getinsync.ca
}
```

### 3.2 Chat Service Interface

```typescript
// src/support/chat/ChatService.ts

interface ChatService {
  initialize(config: ChatProviderConfig): void;
  shutdown(): void;
  open(): void;
  close(): void;
  sendMessage(text: string): void;
  identify(user: ChatUser): void;
  setCustomData(data: Record<string, string>): void;
  onUnreadCountChange(callback: (count: number) => void): void;
}

interface ChatUser {
  email: string;
  name: string;
  namespace?: string;
  role?: string;
  tier?: string;
}
```

**Two implementations ship:**

| File | Provider | When |
|------|----------|------|
| `src/support/chat/CrispChatService.ts` | Crisp | Default — free tier |
| `src/support/chat/ChatwootChatService.ts` | Chatwoot | Swap-in when Canadian residency required |

### 3.3 Tour Service Interface

```typescript
// src/support/tours/TourService.ts

interface TourService {
  initialize(): void;
  startTour(tourId: string): void;
  cancelTour(): void;
  isTourActive(): boolean;
  markTourComplete(tourId: string): void;
  hasCompletedTour(tourId: string): boolean;
}
```

Single implementation: `ShepherdTourService.ts`. Tour definitions are declarative JSON — see §5.

### 3.4 Help Link Service

```typescript
// src/support/help/HelpLinkService.ts

interface HelpLinkService {
  getArticleUrl(articleSlug: string): string;
  openArticle(articleSlug: string): void;  // opens in new tab
  getSearchUrl(query: string): string;
}
```

Maps feature-area slugs to documentation URLs. Allows any component to link to contextual help:

```typescript
// Usage in any component
const { help } = useSupport();
help.openArticle('time-framework');  // → https://docs.getinsync.ca/time-framework
```

---

## 4. Tool Selection & Rationale

### 4.1 Live Chat — Crisp (Primary) / Chatwoot (Escape Hatch)

**Crisp free tier provides:**
- 2 agent seats (Stuart + Delta)
- Chat widget with visitor tracking
- Shared inbox
- React SDK: `crisp-sdk-web`
- Mobile apps for agent responses

**Crisp limitations (free):**
- No knowledge base (Pro tier, $25/mo)
- No chatbot flows
- No CRM integrations
- EU data processing (France HQ)

**Chatwoot as escape hatch — honest effort assessment:**

| Item | Effort | Notes |
|------|--------|-------|
| VPS provisioning (Canadian DC) | 2 hrs | OVHcloud Montreal or DigitalOcean Toronto. $20–40/mo. |
| Docker Compose deployment | 2–4 hrs | Rails + PostgreSQL + Redis + Sidekiq. Official docker-compose.yaml. |
| SSL + domain setup | 1 hr | `support.getinsync.ca` via Let's Encrypt |
| Agent account setup | 30 min | Stuart + Delta accounts, inbox configuration |
| Widget swap in codebase | 30 min | Change `ChatProviderConfig.provider` from `'crisp'` to `'chatwoot'`, supply `baseUrl` + `websiteToken` |
| **Total stand-up** | **~1 day** | One-time effort |
| **Ongoing ops** | **~2 hrs/month** | Updates, monitoring, backups. Rails upgrades quarterly. |

**Decision trigger for Chatwoot:** A government RFP or enterprise contract explicitly requires Canadian-hosted support tooling. Until then, Crisp is the pragmatic choice.

**What Chatwoot can NOT do:** Run on Supabase. It needs its own PostgreSQL instance + Redis + Rails runtime. "Self-hosted on your infrastructure" means a separate Canadian VPS, not the Supabase project.

### 4.2 Product Tours — Shepherd.js

**Why Shepherd.js:**
- MIT licensed, actively maintained (~12K GitHub stars)
- Pure JavaScript — no external service, no data leaves the app
- Declarative step definitions attached to DOM elements
- Built-in positioning (Floating UI), smooth scrolling, overlay/highlight
- React wrapper available: `react-shepherd`
- Tours ship with the code — always in sync with UI changes
- Zero data residency concern

**Alternatives considered and rejected:**

| Tool | Why Not |
|------|---------|
| Intercom Product Tours | $199/mo add-on. Overkill for current stage. |
| Appcues | $249/mo minimum. Enterprise pricing. |
| UserGuiding | Free tier exists but limited. External dependency. |
| Intro.js | Less maintained, weaker React integration. |

### 4.3 Knowledge Base — GitBook

**Why GitBook:**
- Free plan: 1 user, unlimited pages, search, versioning
- Clean reading experience at `docs.getinsync.ca`
- Notion-like editor — Delta can author without code
- Custom domain support on free plan (1 user limit; Premium $65/mo for additional users)
- Government buyers expect a standalone help center (signals maturity)
- Markdown-based — content is portable if we outgrow it

**Current deployment (S.5):** GitBook Free at `https://docs.getinsync.ca`. Custom domain configured. 8 initial articles matching the slug registry in `src/support/help/articles.ts`.

**Alternative considered:** Docusaurus (open source, self-hosted). Better if we want docs-as-code in the same repo. More ops overhead. GitBook wins on Delta-friendliness.

---

## 5. Tour Definitions

Tours are defined as JSON and registered at app startup. Completion state is tracked per-user via `localStorage` (keyed by `user.id + tourId`).

### 5.1 Tour Registry

```typescript
// src/support/tours/registry.ts

interface TourStep {
  id: string;
  target: string;          // CSS selector
  title: string;
  text: string;
  position: 'top' | 'bottom' | 'left' | 'right' | 'auto';
  advanceOn?: {            // auto-advance when user performs action
    selector: string;
    event: string;
  };
  beforeShow?: () => void; // navigate to correct page, open drawer, etc.
}

interface TourDefinition {
  id: string;
  name: string;
  trigger: 'first_login' | 'manual' | 'feature_gate';
  steps: TourStep[];
}
```

### 5.2 Initial Tours (Knowledge Conference Ready)

**Tour 1: "Welcome to GetInSync" (first_login)**

| Step | Target | Content |
|------|--------|---------|
| 1 | Scope bar (workspace picker) | "Start here — select your workspace to see its applications." |
| 2 | Overview tab | "The Overview tab shows your portfolio at a glance — health scores, cost summary, and key metrics." |
| 3 | App Health tab | "App Health plots your applications on the TIME quadrant — Tolerate, Invest, Modernize, Eliminate." |
| 4 | Tech Health tab | "Tech Health shows infrastructure risk — end-of-life platforms, unsupported versions, and missing profiles." |
| 5 | Roadmap tab | "The Roadmap turns findings into funded initiatives — track what to fix and when." |
| 6 | Global Search (Ctrl+K) | "Press Ctrl+K anytime to search across applications, services, contacts, and more." |
| 7 | Help menu | "Need help? Access docs, start a chat, or replay this tour anytime." |

**Tour 2: "Your First Assessment" (manual — triggered from empty state)**

| Step | Target | Content |
|------|--------|---------|
| 1 | Application list | "Let's assess your first application. Click any app to open it." |
| 2 | Assessment CTA | "Click 'Start Assessment' to begin scoring business fit and technical health." |
| 3 | Business factors | "Rate each business factor from 1 to 5. These determine where the app lands on the TIME quadrant." |
| 4 | Technical factors | "Now rate the technical factors. These measure infrastructure risk and supportability." |
| 5 | TIME quadrant result | "Your app is now plotted. The quadrant tells you the recommended action: Tolerate, Invest, Modernize, or Eliminate." |

### 5.3 Tour Completion Tracking

For the initial implementation, tour completion is tracked in `localStorage`:

```typescript
const TOUR_STORAGE_KEY = 'gis_completed_tours';

// Future: migrate to user_preferences table in Supabase
// when gamification Phase 1 ships (achievement tracking
// provides the same per-user state infrastructure)
```

**Migration path:** When gamification ships (achievements table + `audit_log` event sourcing), tour completions move to a `user_tour_completions` table or piggyback on the achievements system. The `TourService.markTourComplete()` / `hasCompletedTour()` interface stays the same — only the storage backend changes.

---

## 6. Integration Points

### 6.1 Help Menu

A persistent help icon (bottom-right or in the AppHeader) provides a dropdown:

| Action | Handler |
|--------|---------|
| "Search help articles" | `help.openArticle('search')` → GitBook search |
| "Start a conversation" | `chat.open()` → Crisp widget |
| "Replay welcome tour" | `tours.startTour('welcome')` |
| "Keyboard shortcuts" | Opens Ctrl+K overlay with shortcuts panel |
| "What's new" | Links to changelog (GitBook or in-app) |

### 6.2 Contextual Help Links

Components can provide context-aware help links:

```typescript
// In any page component
<HelpLink article="time-framework" />
// Renders: ℹ️ icon → opens https://docs.getinsync.ca/time-framework
```

**Article slug registry (initial):**

| Slug | Topic | Used On |
|------|-------|---------|
| `time-framework` | TIME quadrant explanation | App Health tab |
| `paid-framework` | PAID quadrant explanation | App Health tab |
| `assessment-guide` | How to assess an application | Assessment modal |
| `deployment-profiles` | What deployment profiles are | Edit App → Deployments tab |
| `tech-health` | Reading tech health indicators | Tech Health tab |
| `roadmap-initiatives` | Creating and managing initiatives | Roadmap tab |
| `getting-started` | Onboarding guide | Welcome tour final step |
| `integrations` | Managing application integrations | Integrations tab |

### 6.3 Chat Context Enrichment

When the chat widget opens, the abstraction layer automatically passes context to help Stuart/Delta respond faster:

```typescript
// Automatic on every page navigation
chat.setCustomData({
  currentPage: '/app-health',
  namespace: user.namespace_id,
  workspace: selectedWorkspace?.name ?? 'all',
  tier: namespace.tier,
  role: user.namespace_role,
  appCount: dashboardSummary?.total_apps?.toString() ?? '0',
});
```

Both Crisp and Chatwoot support custom data on conversations — the `ChatService.setCustomData()` method abstracts the provider-specific API.

---

## 7. File Structure

```
src/support/
├── SupportProvider.tsx          # React context + provider composition
├── useSupport.ts                # Hook: const { chat, tours, help } = useSupport()
├── config.ts                    # Environment-driven provider selection
├── chat/
│   ├── ChatService.ts           # Interface
│   ├── CrispChatService.ts      # Crisp implementation
│   ├── ChatwootChatService.ts   # Chatwoot implementation (ships day 1)
│   └── NullChatService.ts       # No-op for local dev / tests
├── tours/
│   ├── TourService.ts           # Interface
│   ├── ShepherdTourService.ts   # Shepherd.js implementation
│   ├── registry.ts              # Tour definitions (JSON)
│   └── tours/
│       ├── welcome.ts           # Welcome tour steps
│       └── first-assessment.ts  # Assessment tour steps
├── help/
│   ├── HelpLinkService.ts       # Interface + implementation
│   └── articles.ts              # Slug → URL registry
└── components/
    ├── HelpMenu.tsx             # Help dropdown (AppHeader)
    ├── HelpLink.tsx             # Inline contextual help icon
    └── ChatBadge.tsx            # Unread message indicator
```

---

## 8. Configuration

Provider selection is environment-driven:

```typescript
// src/support/config.ts

export function getSupportConfig(): SupportConfig {
  return {
    chat: {
      provider: (import.meta.env.VITE_CHAT_PROVIDER as ChatProviderConfig['provider']) || 'none',
      siteId: import.meta.env.VITE_CRISP_SITE_ID,
      baseUrl: import.meta.env.VITE_CHATWOOT_BASE_URL,
      websiteToken: import.meta.env.VITE_CHATWOOT_WEBSITE_TOKEN,
    },
    tours: {
      provider: 'shepherd',
      autoStartOnFirstLogin: import.meta.env.VITE_TOURS_AUTO_START !== 'false',
    },
    help: {
      provider: 'gitbook',
      baseUrl: import.meta.env.VITE_HELP_BASE_URL || 'https://docs.getinsync.ca',
    },
  };
}
```

**.env files:**

```bash
# .env.production
VITE_CHAT_PROVIDER=crisp
VITE_CRISP_SITE_ID=<crisp-website-id>
VITE_HELP_BASE_URL=https://docs.getinsync.ca
VITE_TOURS_AUTO_START=true

# .env.development
VITE_CHAT_PROVIDER=none
VITE_TOURS_AUTO_START=false
```

**Switching to Chatwoot (future):**

```bash
# .env.production — after Chatwoot deployment
VITE_CHAT_PROVIDER=chatwoot
VITE_CHATWOOT_BASE_URL=https://support.getinsync.ca
VITE_CHATWOOT_WEBSITE_TOKEN=<chatwoot-token>
```

That's it. One env var change, zero code changes.

---

## 9. Implementation Phases

| Phase | Scope | Effort | Dependencies | Status |
|-------|-------|--------|--------------|--------|
| S.1 | Abstraction layer + `NullChatService` + `SupportProvider` | 0.5 day | None | COMPLETE (Mar 10) |
| S.2 | Shepherd.js integration + Welcome tour (7 steps) | 1 day | S.1 | COMPLETE (Mar 10) |
| S.3 | Crisp integration + `ChatContextBridge` | 0.5 day | S.1 + Crisp account setup | COMPLETE (Mar 10). Crisp prod config (Netlify env vars) also done. |
| S.4 | HelpMenu component + contextual HelpLink + ChatBadge | 0.5 day | S.1 | COMPLETE (Mar 10) |
| S.5 | GitBook setup + initial 8 articles | 2 days | Delta authoring | COMPLETE (Mar 10). GitBook Free at docs.getinsync.ca. 8 draft articles authored. |
| S.6 | First Assessment tour | 0.5 day | S.2 | NOT STARTED |
| S.7 | ChatwootChatService implementation | 0.5 day | S.1 (ships with S.1, not deployed) | COMPLETE (Mar 10) |
| **Total** | | **~5.5 days** | | **6/7 complete** |

**Pre-Knowledge Conference (May 2026) target:** S.1–S.5 + S.7 complete as of Mar 10. Remaining: S.6 (first assessment tour).

---

## 10. SOC2 Implications

| Control | Impact | Action |
|---------|--------|--------|
| CC6.1 (Logical access) | Crisp agents = Stuart + Delta only | Document in Vendor Management Policy |
| CC2.3 (Change management) | Shepherd tours are code — covered by existing Git workflow | None |
| CC9.1 (Vendor management) | Crisp is a sub-processor (stores visitor email/name) | Add to vendor register; document EU data processing |
| A1.1 (Availability) | Crisp outage ≠ GetInSync outage (widget fails silently) | Document graceful degradation |

**If Chatwoot deployed:** CC6.1 coverage improves (self-hosted, full control). CC9.1 sub-processor removed. New A1.1 obligation (VPS uptime is our responsibility).

---

## 11. Decision Log

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| D1 | Provider abstraction from day 1 | Government contracts may mandate Canadian hosting; switching cost must be < 1 hour | Mar 2026 |
| D2 | Shepherd.js over commercial tour tools | Code-native = zero external dependency, zero data residency concern, zero cost | Mar 2026 |
| D3 | Crisp over Intercom for initial deployment | Free tier covers 2 agents; $0/mo vs $79+/mo; widget quality comparable | Mar 2026 |
| D4 | GitBook over Docusaurus for KB | Delta-friendliness > developer control; content portability via Markdown | Mar 2026 |
| D5 | Ship ChatwootChatService with v1 (unused) | Proves the abstraction works; ready to deploy when triggered | Mar 2026 |
| D6 | Tour completion in localStorage initially | Moves to Supabase when gamification ships; TourService interface unchanged | Mar 2026 |

---

## 12. Chatwoot Deployment Runbook (When Needed)

Reference procedure — execute only when a government RFP or contract requires Canadian-hosted support.

### 12.1 Infrastructure

```bash
# 1. Provision Canadian VPS
#    OVHcloud Montreal (BHS) or DigitalOcean Toronto (TOR1)
#    Minimum: 2 vCPU, 4GB RAM, 50GB SSD (~$24–40/mo)

# 2. DNS
#    support.getinsync.ca → VPS IP (A record)

# 3. Clone Chatwoot
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot

# 4. Configure environment
cp .env.example .env
# Edit: FRONTEND_URL, SECRET_KEY_BASE, POSTGRES_*, REDIS_URL, MAILER_*

# 5. Deploy via Docker Compose
docker compose up -d

# 6. SSL via Caddy or nginx + certbot
# (Chatwoot docker-compose includes nginx by default)

# 7. Create admin account
docker exec -it chatwoot_rails bundle exec rails console
# > SuperAdmin.create!(email: 'sholtby@allstartech.com', ...)
```

### 12.2 Application Switch

```bash
# .env.production — update these 3 values:
VITE_CHAT_PROVIDER=chatwoot
VITE_CHATWOOT_BASE_URL=https://support.getinsync.ca
VITE_CHATWOOT_WEBSITE_TOKEN=<token-from-chatwoot-admin>

# Remove (optional):
# VITE_CRISP_SITE_ID=...

# Deploy
git commit -am "feat: switch chat provider to Chatwoot"
git push  # Netlify auto-deploys
```

### 12.3 Ongoing Operations

| Task | Frequency | Effort |
|------|-----------|--------|
| Chatwoot version upgrade | Quarterly | 30 min (`docker compose pull && docker compose up -d`) |
| PostgreSQL backup | Daily (cron) | Automated |
| Redis persistence check | Monthly | 10 min |
| SSL renewal | Auto (certbot) | 0 |
| VPS OS patches | Monthly | 15 min |
| **Total ongoing** | | **~2 hrs/month** |

---

## 13. Future Considerations

- **Crisp Pro upgrade ($25/mo):** Consolidates knowledge base into Crisp (eliminates GitBook). Evaluate when monthly chat volume exceeds what free tier supports comfortably.
- **In-app changelog widget:** Lightweight "what's new" announcement. Could be a simple React component reading from a JSON file or GitBook API. Low effort, high polish value.
- **Tour analytics:** Track tour completion rates via audit log events. Feeds into gamification achievement system.
- **Intercom migration (if funded):** The abstraction layer supports an `IntercomChatService` implementation. If a funding round or enterprise deal justifies the cost, switching is a ~2 hour implementation task.

### 13.1 AI Chat Convergence (Post-S.7)

S.1–S.7 ship with **zero AI Chat dependency**. The support infrastructure is production-ready without any AI Chat code.

Once AI Chat (Edge Functions E1+E2) stabilizes in production, the three atomic features — in-app support, AI chat, and the edge functions layer — converge into a single unified chat experience. This convergence is documented in a separate architecture doc: `features/support/unified-chat-integration.md`.

**Integration seams designed into S.1–S.7:**

The following interfaces serve as the connection points for the post-S.7 unification. They exist in the S.1–S.7 codebase with no AI Chat awareness; the unification step wires them to the ChatRouter without modifying their contracts.

| Interface | Defined In | Integration Role |
|-----------|-----------|-----------------|
| `ChatService.sendMessage()` | §3 (this doc) | **Intercept point.** The ChatRouter wraps the active ChatService and routes messages to the AI Chat edge function before forwarding to Crisp/Chatwoot. The ChatService contract is unchanged — ChatRouter is a decorator, not a replacement. |
| `ChatContextBridge` | `features/support/implementation-plan.md` S.3 | **Shared context producer.** Currently pushes page context (currentPage, namespace, workspace, tier, role, appCount) to Crisp via `setCustomData()`. Extended in the unification step to produce a `UnifiedChatContext` that feeds both AI Chat and Crisp. |
| `SupportProvider` | §3 (this doc) | **Composition root.** The ChatRouter initializes inside SupportProvider alongside the existing ChatService, TourService, and HelpLinkService. SupportProvider's public API (`useSupport()`) is unchanged. |

**What the unification step adds (NOT part of S.1–S.7):**

- `ChatRouter` — routing layer that decides AI-first vs human-direct based on tier, availability, and user intent
- `NativeChatPanel` — React component replacing Crisp widget chrome for AI conversations (rich rendering of portfolio cards, lifecycle badges, cost tables)
- `UnifiedChatContext` — extended context shape consumed by AI Chat, Crisp, and help content
- Impersonation awareness — suppresses human escalation, isolates conversations, tracks platform admin tokens

The AI Chat integration is a separate implementation step with its own architecture doc. See `features/support/unified-chat-integration.md` for the complete unification architecture, sequencing, and codebase impact assessment.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.3 | 2026-03-10 | S.5 COMPLETE. GitBook Free at docs.getinsync.ca with 8 initial articles. §4.3 corrected: free plan supports custom domains (1 user). §9 phase statuses updated: S.1–S.5 + S.7 complete, S.3 Crisp prod config noted. |
| v1.2 | 2026-03-10 | S.2 + S.3 COMPLETE. Shepherd tours + ChatContextBridge deployed. S.1–S.4 + S.7 complete. |
| v1.1 | 2026-03-09 | Expanded §13 with §13.1 AI Chat Convergence subsection. Named integration seams (ChatService.sendMessage, ChatContextBridge, SupportProvider). References unified-chat-integration.md. S.1–S.7 unchanged. |
| v1.0 | 2026-03 | Initial version. Provider abstraction, S.1–S.7 implementation phases. |

---

*Document: features/support/in-app-support-architecture.md*
*March 2026*
