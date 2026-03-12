# In-App Support — Implementation Plan

**Version:** 1.0
**Status:** PLANNING
**Date:** March 2026
**Architecture ref:** `features/support/in-app-support-architecture.md` (v1.0)

---

## 1. Codebase Validation Results

Validated against the live codebase on 2026-03-09. All file paths and line numbers reference actual code.

### 1.1 Existing Infrastructure

| Check | Result |
|-------|--------|
| Existing support/chat/tour code | **None.** No `src/support/`, `src/help/`, `src/tour/`, or `src/onboarding/` directories. Zero files related to chat widgets, product tours, or help systems. |
| Chat/tour npm packages | **None.** No `crisp-sdk-web`, `shepherd.js`, `react-shepherd`, or similar in `package.json`. |
| Support-related env vars | **None.** Only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` exist in `.env` and `src/vite-env.d.ts`. No conflicts with proposed vars. |
| `.env.example` file | **Does not exist.** Only `.env` is present. |
| `data-testid` / `data-tour` attributes | **None anywhere in the codebase.** Tour selectors need to be added. |
| localStorage wrapper utility | **None.** 18 files use `localStorage` directly (getItem/setItem). No abstraction layer. |
| `user_preferences` table | **Not referenced anywhere in TypeScript.** Tour completion via localStorage fits existing patterns. |

### 1.2 Provider Hierarchy (App.tsx:904-960)

```
App()                                    ← line 904
  AuthProvider                           ← line 906, provides: user, namespace, currentWorkspace
    Toaster (react-hot-toast, top-right) ← line 907
    ErrorBoundary                        ← line 908
      Routes                             ← line 909
        ProtectedRoute → WorkspaceScopedMainApp
          ScopeProvider                  ← line 898, provides: activeTab, selectedPortfolio, mainView
            Outlet → MainApp             ← line 899/954
```

**SupportProvider insertion:** After `AuthProvider` (line 906), wrapping Toaster + ErrorBoundary + Routes. Has access to `useAuth()` but NOT `useScope()`.

### 1.3 Two Header Implementations

| Header | File | Used On | Lines |
|--------|------|---------|-------|
| Inline header | `src/App.tsx` | Main dashboard (MainApp) | 552–621 |
| Shared AppHeader | `src/components/shared/AppHeader.tsx` | Detail/edit pages (ApplicationPage, etc.) | 1–149 |

Both share the same visual pattern: `sticky top-0 z-40`, right side has Search → context selectors → UserMenu.

**HelpMenu insertion point (Stuart's decision):** Between Search button and WorkspaceSwitcher.
- In App.tsx: after line 585 (Search button closing tag), before line 586 (WorkspaceSwitcher div)
- In AppHeader.tsx: after line 117 (Search button closing tag), before line 120 (context pills div)

### 1.4 Z-Index Landscape

| Layer | Z-Index | Source |
|-------|---------|--------|
| Overlay backdrops (dropdowns) | z-10 | WorkspaceSwitcher, UserMenu |
| Dropdown panels | z-20 | WorkspaceSwitcher, UserMenu |
| Sticky block (banner + tabs) | z-30 | Screen building guidelines |
| Global header, filter drawer backdrop | z-40 | AppHeader, App.tsx inline header |
| Modal overlays, filter drawer panel | z-50 | Modals, filter drawer |
| Stacked modals (confirmations above modals) | z-[60] | ApplicationPage, ContactPicker, UnsavedChangesModal, link modals |
| Deep-stacked modals (dependency confirmations) | z-[70] | ITServiceDependencyList |

### 1.5 Tour Target Elements (Current Selectors)

| Element | Component | Current Identifier |
|---------|-----------|-------------------|
| Workspace picker | `WorkspaceSwitcher` in App.tsx:587 | Class-based only (fragile) |
| Main nav tabs | `MainTabBar.tsx` buttons | `key={tab.id}` but no DOM attribute |
| Global Search button | App.tsx:579–585, AppHeader.tsx:111–117 | `title="Search (⌘K)"` |
| User menu | `UserMenu.tsx` button | Class-based only |
| Help menu | Does not exist yet | Will add in S.4 |

**All need `data-tour` attributes added for robust tour targeting.**

---

## 2. Phase Breakdown

### Phase S.1 — Abstraction Layer + NullChatService + SupportProvider

**Effort:** 0.5 day
**Dependencies:** None

#### Files to Create

| File | Purpose |
|------|---------|
| `src/support/types.ts` | All shared interfaces: `SupportConfig`, `ChatProviderConfig`, `TourProviderConfig`, `HelpProviderConfig`, `ChatUser`, `ChatService`, `TourService`, `HelpLinkService` |
| `src/support/config.ts` | `getSupportConfig()` — reads `import.meta.env.VITE_*` vars |
| `src/support/SupportProvider.tsx` | React context composing chat + tour + help services |
| `src/support/useSupport.ts` | Consumer hook: `const { chat, tours, help } = useSupport()` |
| `src/support/chat/NullChatService.ts` | No-op implementation for dev/tests |
| `src/support/chat/CrispChatService.ts` | _(created here, wired in S.3)_ |
| `src/support/chat/ChatwootChatService.ts` | Chatwoot implementation (ships unused — proves abstraction) |
| `src/support/chat/crisp.d.ts` | Window type declarations for `$crisp`, `CRISP_WEBSITE_ID` |
| `src/support/chat/chatwoot.d.ts` | Window type declarations for `chatwootSettings`, `chatwootSDK` |
| `src/support/tours/NullTourService.ts` | No-op placeholder (replaced in S.2) |
| `src/support/help/HelpLinkService.ts` | GitBook implementation: `getArticleUrl()`, `openArticle()`, `getSearchUrl()` |
| `src/support/help/articles.ts` | Slug-to-path registry (8 initial slugs from architecture §6.2) |

#### Files to Modify

| File | Change |
|------|--------|
| `src/vite-env.d.ts` | Add 6 optional env var declarations to `ImportMetaEnv` |
| `.env` | Add `VITE_CHAT_PROVIDER=none`, `VITE_HELP_BASE_URL=https://docs.getinsync.ca`, `VITE_TOURS_AUTO_START=false` |
| `src/App.tsx` | Wrap AuthProvider's children with `<SupportProvider>` at line 907 |

#### Codebase-Specific Adjustments

1. **Feature module pattern.** `src/support/` stays as the architecture specifies (not `src/contexts/`). This is a self-contained feature module with services + components, consistent with `src/components/search/`.
2. **Import convention.** Use relative imports (`from '../support/useSupport'`), not `@/` alias. The alias is configured but unused throughout the project.
3. **ChatwootChatService loads widget via `<script>` tag** (no npm package). The `initialize()` method dynamically creates a script element pointing to `${config.baseUrl}/packs/js/sdk.js` and waits for the `chatwoot:ready` event.

#### Risks

- **None significant.** Purely additive. SupportProvider wrapping is a single-element addition to App.tsx.

---

### Phase S.2 — Shepherd.js Integration + Welcome Tour

**Effort:** 1 day
**Dependencies:** S.1

#### Dependencies to Install

```bash
npm install shepherd.js
```

> **Note:** Evaluate whether `react-shepherd` is also needed. Since our `TourService` abstraction manages the Shepherd instance directly, `shepherd.js` alone may suffice. If so, skip `react-shepherd` to avoid wrapper-over-wrapper.

#### Files to Create

| File | Purpose |
|------|---------|
| `src/support/tours/ShepherdTourService.ts` | Shepherd.js implementation of `TourService`. Creates `Shepherd.Tour` instances, tracks completion in localStorage key `gis_completed_tours`. |
| `src/support/tours/registry.ts` | Tour definition types + registry map |
| `src/support/tours/tours/welcome.ts` | Welcome tour — **6 steps** (step 7 added in S.4 when HelpMenu exists) |
| `src/support/tours/tours/first-assessment.ts` | Stub only (implemented in S.6) |
| `src/support/tours/shepherd-theme.css` | Custom Shepherd theme: teal-600 primary, gray-900 text, rounded-lg cards. **CSS file exception** — Shepherd creates tooltip DOM outside React, so Tailwind classes can't be applied directly. Import in SupportProvider.tsx. |

#### Files to Modify

| File | Change |
|------|--------|
| `src/support/SupportProvider.tsx` | Replace `NullTourService` with `ShepherdTourService`. Import shepherd-theme.css. |
| `src/App.tsx` | Add `data-tour="search-button"` to Search button (line 579). Add `data-tour="scope-bar"` to the WorkspaceSwitcher+Portfolio container div (line 586). |
| `src/components/shared/AppHeader.tsx` | Add `data-tour="search-button"` to Search button (line 111). |
| `src/components/navigation/MainTabBar.tsx` | Add `data-tour={`tab-${tab.id}`}` to each tab button (line 15). Produces: `data-tour="tab-overview"`, `data-tour="tab-dashboard"`, `data-tour="tab-technology-health"`, `data-tour="tab-roadmap"`. |
| `src/components/UserMenu.tsx` | Add `data-tour="user-menu"` to the menu trigger button. |
| `package.json` | Add `shepherd.js` dependency. |

#### Welcome Tour Steps (6 of 7)

| # | Target Selector | Content Summary |
|---|----------------|-----------------|
| 1 | `[data-tour="scope-bar"]` | "Start here — select your workspace" |
| 2 | `[data-tour="tab-overview"]` or `[data-tour="tab-dashboard"]` | "Overview shows your portfolio at a glance" |
| 3 | `[data-tour="tab-dashboard"]` | "App Health plots TIME quadrant" |
| 4 | `[data-tour="tab-technology-health"]` | "Tech Health shows infrastructure risk" |
| 5 | `[data-tour="tab-roadmap"]` | "Roadmap turns findings into initiatives" |
| 6 | `[data-tour="search-button"]` | "Press Ctrl+K to search across everything" |

Step 7 (help menu) added in S.4.

#### Tour Auto-Start Logic

- On authenticated mount, check `localStorage.getItem('gis_completed_tours')`
- If `welcome` not in completed set AND `config.tours.autoStartOnFirstLogin === true`, start after 500ms delay (let UI render)
- Production: `VITE_TOURS_AUTO_START=true`. Dev: `false`.

#### Z-Index Allocation

| Element | Z-Index |
|---------|---------|
| Shepherd overlay (backdrop) | `z-[9000]` via shepherd-theme.css |
| Shepherd tooltip | `z-[9001]` via shepherd-theme.css |

#### Risks

- **Tour step 2 (Overview tab):** Only visible when user has 2+ workspaces. Tour definition should fall back to `[data-tour="tab-dashboard"]` if Overview tab is absent. Use Shepherd's `showOn` callback to conditionally display.
- **Sticky header positioning:** Search button and tabs are inside `sticky top-0 z-40` header. Shepherd uses Floating UI which handles sticky elements correctly. Verify during implementation.

---

### Phase S.3 — Crisp Integration + Chat Context Enrichment

**Effort:** 0.5 day
**Dependencies:** S.1 + Crisp account setup (Stuart, ~10 min external)

#### Dependencies to Install

```bash
npm install crisp-sdk-web
```

> `crisp-sdk-web` is a thin loader (~5KB) that dynamically loads the full widget from Crisp's CDN. Minimal bundle impact.

#### Files to Create

| File | Purpose |
|------|---------|
| `src/support/chat/CrispChatService.ts` | Full Crisp implementation: `initialize()` (load widget), `identify()` (user email/name), `setCustomData()`, `open()`/`close()`, `onUnreadCountChange()`. |
| `src/support/chat/ChatContextBridge.tsx` | Render-null component placed inside MainApp. Reads `useScope()` + `useAuth()` + `useLocation()` and pushes context to `chat.setCustomData()` on every navigation. |

#### Files to Modify

| File | Change |
|------|--------|
| `src/support/SupportProvider.tsx` | Wire `CrispChatService` when `config.chat.provider === 'crisp'`. Call `chat.identify()` in useEffect when user authenticates. |
| `src/App.tsx` | Add `<ChatContextBridge />` inside MainApp function (before JSX return, ~line 549). This component has access to both ScopeContext and AuthContext. |
| `package.json` | Add `crisp-sdk-web` dependency. |

#### Codebase-Specific Adjustments

**ChatContextBridge pattern.** SupportProvider sits above ScopeProvider in the component tree, so it cannot read `useScope()`. Rather than restructuring the provider hierarchy, a render-null bridge component inside MainApp reads scope context and pushes it to the chat service:

```typescript
// Pseudocode — src/support/chat/ChatContextBridge.tsx
function ChatContextBridge() {
  const { chat } = useSupport();
  const { activeTab, selectedPortfolio } = useScope();
  const { currentWorkspace, namespace } = useAuth();
  const location = useLocation();

  useEffect(() => {
    chat.setCustomData({
      currentPage: location.pathname,
      activeTab,
      namespace: namespace?.name ?? '',
      workspace: currentWorkspace?.name ?? 'all',
      portfolio: selectedPortfolio?.name ?? 'All Portfolios',
    });
  }, [location.pathname, activeTab, currentWorkspace, selectedPortfolio]);

  return null;
}
```

#### Risks

- **Crisp account prerequisite.** Stuart needs to create a Crisp account and obtain `VITE_CRISP_SITE_ID`. Code can be written and merged with `VITE_CHAT_PROVIDER=none`; Crisp widget only loads when configured.
- **Widget z-index.** Crisp manages its own z-index (~10000). No conflict with our z-10 through z-50 landscape. The Toaster (top-right) and Crisp widget (bottom-right) don't overlap.

---

### Phase S.4 — HelpMenu Component + Contextual HelpLink

**Effort:** 0.75 day (adjusted from 0.5 — two headers + tour step 7 patch)
**Dependencies:** S.1

#### Files to Create

| File | Purpose |
|------|---------|
| `src/support/components/HelpMenu.tsx` | Dropdown triggered by `HelpCircle` icon (lucide-react). Items: "Help Articles" → GitBook, "Start a Conversation" → `chat.open()`, "Replay Welcome Tour" → `tours.startTour('welcome')`, "Keyboard Shortcuts" → opens search overlay, "What's New" → changelog link. Uses same dropdown pattern as UserMenu (fixed backdrop + absolute panel). |
| `src/support/components/HelpLink.tsx` | Inline contextual help icon. `<HelpLink article="time-framework" />` renders a small `HelpCircle` icon that opens GitBook article in new tab via `window.open()`. |
| `src/support/components/ChatBadge.tsx` | Unread message count indicator. Red dot with count, shown on HelpMenu icon when `chat.onUnreadCountChange()` fires with count > 0. |

#### Files to Modify

| File | Change |
|------|--------|
| `src/App.tsx` | Add `<HelpMenu />` after Search button (line 585), before WorkspaceSwitcher div (line 586). Add `data-tour="help-menu"` to HelpMenu trigger. Match icon button style: `p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg`. |
| `src/components/shared/AppHeader.tsx` | Add `<HelpMenu />` after Search button (line 117), before context pills div (line 120). Same style. |
| `src/support/tours/tours/welcome.ts` | Add step 7 targeting `[data-tour="help-menu"]`: "Need help? Access docs, start a chat, or replay this tour anytime." |

#### Codebase-Specific Adjustments

- **Dropdown z-index.** Match UserMenu pattern: `fixed inset-0 z-10` backdrop + `absolute right-0 top-full mt-1 z-20` panel. Since it's inside the `z-40` header, the panel renders above content. This is identical to how UserMenu.tsx (lines 89–96) and WorkspaceSwitcher already work.
- **Icon choice.** Use `HelpCircle` from lucide-react (already installed). Consistent with the icon library used throughout.

#### Risks

- **HelpMenu on detail pages.** AppHeader.tsx (used on ApplicationPage, edit pages) will also show HelpMenu. This is desired — help should be available everywhere.

---

### Phase S.5 — GitBook Setup + Initial 8 Articles — COMPLETE

**Effort:** 2 days (Delta's authoring — runs in parallel with dev work)
**Dependencies:** None
**Status:** COMPLETE (Mar 10, 2026)

#### Setup

- GitBook Free plan (1 user, custom domain included)
- Custom domain: `docs.getinsync.ca`
- 8 articles authored as markdown drafts in `guides/user-help/` (architecture repo) and imported to GitBook

#### No Code Changes Required

The existing `config.ts` default (`https://docs.getinsync.ca`) already matches. `VITE_HELP_BASE_URL` env var on Netlify points to the same URL.

#### Article Slugs

| Slug | Topic | Draft File |
|------|-------|------------|
| `getting-started` | Onboarding guide | `guides/user-help/getting-started.md` |
| `time-framework` | TIME quadrant explanation | `guides/user-help/time-framework.md` |
| `paid-framework` | PAID quadrant explanation | `guides/user-help/paid-framework.md` |
| `assessment-guide` | How to assess an application | `guides/user-help/assessment-guide.md` |
| `deployment-profiles` | What deployment profiles are | `guides/user-help/deployment-profiles.md` |
| `tech-health` | Reading tech health indicators | `guides/user-help/tech-health.md` |
| `roadmap-initiatives` | Creating and managing initiatives | `guides/user-help/roadmap-initiatives.md` |
| `integrations` | Managing application integrations | `guides/user-help/integrations.md` |

---

### Phase S.6 — First Assessment Tour

**Effort:** 0.5 day
**Dependencies:** S.2 (tour infrastructure)

#### Files to Modify

| File | Change |
|------|--------|
| `src/support/tours/tours/first-assessment.ts` | Complete the 5-step assessment tour definition (stubbed in S.2). |

#### Files to Modify for Tour Targets

Exact files depend on which components render the application list and assessment wizard. Likely candidates:

| File | Change |
|------|--------|
| Dashboard content area (App.tsx ~line 639+) | Add `data-tour="app-list"` to applications grid container |
| Assessment CTA button | Add `data-tour="assessment-cta"` |
| Assessment wizard business factors | Add `data-tour="business-factors"` |
| Assessment wizard technical factors | Add `data-tour="technical-factors"` |
| TIME quadrant result | Add `data-tour="time-result"` |

> **Implementation note:** Exact component file paths need verification during S.6 — the assessment wizard may be a mainView state within MainApp or a separate component. The tour's `beforeShow` hooks need access to navigation functions to move between dashboard and assessment views.

#### Tour Trigger

- Manual only — triggered from HelpMenu ("Tour: First Assessment") or from an empty-state CTA when a workspace has 0 assessed applications.
- NOT auto-started on first login (that's the welcome tour).

#### Risks

- **Cross-view navigation.** This tour spans dashboard → assessment wizard (different `mainView` states). Shepherd's `beforeShow` hooks need to invoke `setMainView('assessment')` or similar. The `ShepherdTourService.startTour()` may need a navigation callback parameter.
- **Recommend deferring detailed design of S.6 until S.2 is implemented** — the tour infrastructure will clarify how `beforeShow` hooks interact with the ScopeContext.

---

### Phase S.7 — ChatwootChatService Implementation

**Effort:** 0.5 day
**Dependencies:** S.1

> **Stuart's decision:** Build with S.1 to prove the abstraction. Ships as dead code until `VITE_CHAT_PROVIDER=chatwoot`.

#### Files

Already created in S.1: `src/support/chat/ChatwootChatService.ts` and `src/support/chat/chatwoot.d.ts`.

Implementation details:
- `initialize()`: dynamically create `<script src="${config.baseUrl}/packs/js/sdk.js">`, set `window.chatwootSettings`, wait for `chatwoot:ready` event
- `identify()`: call `window.$chatwoot.setUser()` with email, name, custom attributes
- `setCustomData()`: call `window.$chatwoot.setCustomAttributes()`
- `open()`/`close()`: call `window.$chatwoot.toggle()`
- No npm package needed — Chatwoot widget is script-loaded

#### Risks

- **None.** Second implementation of an already-defined interface. Chatwoot's widget API is stable and well-documented.

---

## 3. Cross-Cutting Concerns

### 3.1 Environment Variables

Add to `src/vite-env.d.ts`:

```typescript
interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string;
  readonly VITE_SUPABASE_ANON_KEY: string;
  // In-app support (§ features/support/in-app-support-architecture.md)
  readonly VITE_CHAT_PROVIDER?: string;         // 'crisp' | 'chatwoot' | 'none'
  readonly VITE_CRISP_SITE_ID?: string;
  readonly VITE_CHATWOOT_BASE_URL?: string;
  readonly VITE_CHATWOOT_WEBSITE_TOKEN?: string;
  readonly VITE_HELP_BASE_URL?: string;         // default: https://docs.getinsync.ca
  readonly VITE_TOURS_AUTO_START?: string;      // 'true' | 'false'
}
```

### 3.2 Z-Index Allocation (Final)

| Layer | Z-Index | Status |
|-------|---------|--------|
| Overlay backdrops (dropdowns) | z-10 | Existing |
| Dropdown panels | z-20 | Existing |
| Sticky block | z-30 | Existing |
| Global header, filter drawer backdrop | z-40 | Existing |
| Modal overlays, filter drawer panel | z-50 | Existing |
| Stacked modals (confirmations above modals) | z-[60] | Existing |
| Deep-stacked modals (dependency confirmations) | z-[70] | Existing |
| Crisp/Chatwoot chat widget | ~10000 (managed by SDK) | New |
| Shepherd tour overlay | z-[9000] (shepherd-theme.css) | New |
| Shepherd tour tooltip | z-[9001] (shepherd-theme.css) | New |

### 3.3 Complete File Tree

```
src/support/
├── types.ts                          # S.1
├── config.ts                         # S.1
├── SupportProvider.tsx                # S.1
├── useSupport.ts                     # S.1
├── chat/
│   ├── NullChatService.ts            # S.1
│   ├── CrispChatService.ts           # S.1 (created) / S.3 (wired)
│   ├── ChatwootChatService.ts        # S.1 / S.7
│   ├── ChatContextBridge.tsx         # S.3
│   ├── crisp.d.ts                    # S.1
│   └── chatwoot.d.ts                 # S.1
├── tours/
│   ├── NullTourService.ts            # S.1
│   ├── ShepherdTourService.ts        # S.2
│   ├── registry.ts                   # S.2
│   ├── shepherd-theme.css            # S.2
│   └── tours/
│       ├── welcome.ts               # S.2 (6 steps) → S.4 (add step 7)
│       └── first-assessment.ts      # S.2 (stub) → S.6 (complete)
├── help/
│   ├── HelpLinkService.ts           # S.1
│   └── articles.ts                  # S.1
└── components/
    ├── HelpMenu.tsx                  # S.4
    ├── HelpLink.tsx                  # S.4
    └── ChatBadge.tsx                 # S.4
```

### 3.4 Existing Files Modified (All Phases)

| File | Phases | Changes |
|------|--------|---------|
| `src/vite-env.d.ts` | S.1 | Add 6 env var declarations |
| `.env` | S.1 | Add 3 dev defaults |
| `src/App.tsx` | S.1, S.2, S.3, S.4 | SupportProvider wrapper; data-tour attrs on header elements; ChatContextBridge in MainApp; HelpMenu in header |
| `src/components/shared/AppHeader.tsx` | S.2, S.4 | data-tour on Search button; HelpMenu insertion |
| `src/components/navigation/MainTabBar.tsx` | S.2 | data-tour on tab buttons |
| `src/components/UserMenu.tsx` | S.2 | data-tour on trigger button |
| `package.json` | S.2, S.3 | Add shepherd.js, crisp-sdk-web |

### 3.5 npm Packages to Add

| Package | Phase | Size Impact |
|---------|-------|-------------|
| `shepherd.js` | S.2 | ~45KB gzipped (includes Floating UI) |
| `crisp-sdk-web` | S.3 | ~5KB (thin loader; full widget loaded from CDN at runtime) |

---

## 4. Execution Order

```
S.1 (0.5d) ─┬─> S.2 (1d) ──> S.4 (0.75d) ──> S.6 (0.5d)
             ├─> S.3 (0.5d)
             └─> S.7 (0.5d)

S.5 (2d, Delta, parallel) ─────────────────────>
```

- **S.1** is the foundation — all phases depend on it
- **S.2 → S.4** are sequential (S.4 adds HelpMenu that tour step 7 targets)
- **S.3** and **S.7** can run in parallel with S.2 or after S.1
- **S.5** is external (Delta + GitBook) and runs in parallel with all dev work
- **S.6** depends on S.2 (tour infrastructure must exist)

### Recommended Build Order (Single Developer)

1. S.1 + S.7 together (0.5 day) — abstraction layer + both chat implementations
2. S.2 (1 day) — Shepherd + welcome tour (6 steps)
3. S.3 (0.5 day) — Crisp integration + ChatContextBridge
4. S.4 (0.75 day) — HelpMenu + HelpLink + ChatBadge + tour step 7
5. S.6 (0.5 day) — First assessment tour

---

## 5. Effort Summary

| Phase | Architecture Estimate | Adjusted Estimate | Delta |
|-------|----------------------|-------------------|-------|
| S.1 | 0.5 day | 0.5 day | — |
| S.2 | 1 day | 1 day | — |
| S.3 | 0.5 day | 0.5 day | — |
| S.4 | 0.5 day | 0.75 day | +0.25 (two headers + tour step 7 patch) |
| S.5 | 2 days | 2 days (Delta) | — |
| S.6 | 0.5 day | 0.5 day | — |
| S.7 | 0.5 day | 0.5 day | — |
| **Total dev** | **3.5 days** | **3.75 days** | **+0.25 day** |
| **Total with GitBook** | **5.5 days** | **5.75 days** | **+0.25 day** |

**Pre-Knowledge Conference target (May 2026):** S.1 + S.2 + S.3 + S.4 + S.6 = 3.25 days dev. S.5 parallel.

---

## 6. Open Questions for Stuart

| # | Question | Impact |
|---|----------|--------|
| 1 | Create a `.env.example` to document the new support env vars? Currently no `.env.example` exists. | Low — documentation hygiene |
| 2 | GitBook domain: `docs.getinsync.ca` or `help.getinsync.ca`? Architecture uses `docs`. | Affects HelpLinkService default URL |
| 3 | First-assessment tour (S.6): should it auto-select an application, or wait for user click? | Affects tour `beforeShow` complexity |
| 4 | Should `react-shepherd` be installed alongside `shepherd.js`, or use Shepherd.js standalone API? | Minor — evaluate during S.2 implementation |

---

*Document: features/support/implementation-plan.md*
*March 2026*
