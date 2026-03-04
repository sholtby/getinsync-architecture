# GetInSync NextGen — Global Search Architecture

> **Document:** features/global-search/architecture.md
> **Version:** v1.1
> **Status:** 🟡 AS-DESIGNED (RPC deployed, frontend pending)
> **Date:** February 28, 2026
> **Author:** Stuart Holtby + Claude (Opus 4.6)

---

## 1. Problem Statement

GetInSync has 90 database tables and zero way to find anything by typing a word. Users managing portfolios of 50–500+ applications cannot quickly locate an application, a deployment profile, a contact, or an initiative without navigating to the correct tab and scrolling. This is a fundamental usability gap — every enterprise tool in the space (ServiceNow, LeanIX, Orbus) has global search. For a product whose UX principle is "QuickBooks simple," the inability to type a name and jump to it is a credibility problem in demos and daily use.

---

## 2. Design — ServiceNow-Style Categorized Search

### User Experience

1. **Trigger:** User clicks the search icon in the top nav bar (or presses `Ctrl+K` / `⌘+K` as keyboard shortcut)
2. **Input:** A search overlay appears — full-width input field at the top with "Search applications, services, contacts..." placeholder
3. **Live results:** After 2+ characters, results appear in a categorized panel below the input
4. **Categories:** Results grouped by entity type with hit counts:
   ```
   ┌──────────────────────────────────────────────────┐
   │ 🔍  "quickbooks"                              ✕  │
   ├──────────────────────────────────────────────────┤
   │                                                   │
   │ Applications (2)                             ▸    │
   │ ┌─────────────────────────────────────────────┐  │
   │ │ 📋 QuickBooks Online                        │  │
   │ │    Finance Department · Invest · SaaS        │  │
   │ ├─────────────────────────────────────────────┤  │
   │ │ 📋 QuickBooks Desktop                       │  │
   │ │    Accounting Division · Eliminate · On-Prem  │  │
   │ └─────────────────────────────────────────────┘  │
   │                                                   │
   │ Software Products (1)                        ▸    │
   │ ┌─────────────────────────────────────────────┐  │
   │ │ 📦 Intuit QuickBooks                        │  │
   │ │    Intuit Inc. · Suite                       │  │
   │ └─────────────────────────────────────────────┘  │
   │                                                   │
   │ Contacts (1)                                 ▸    │
   │ ┌─────────────────────────────────────────────┐  │
   │ │ 👤 Jane Smith                               │  │
   │ │    QuickBooks Administrator · Finance        │  │
   │ └─────────────────────────────────────────────┘  │
   │                                                   │
   └──────────────────────────────────────────────────┘
   ```
5. **Category expand:** Clicking the ▸ arrow (or category header) expands to show all results for that category
6. **Navigation:** Clicking any result navigates to that entity's detail page and closes search
7. **Dismiss:** Escape key or clicking outside closes the overlay

### Result Display Per Category

Each result row shows:
- **Entity icon** (per category — lucide-react icon, see §3)
- **Primary text** — entity name/title (with search term **highlighted** in bold)
- **Secondary text** — contextual breadcrumb (workspace, status, type — varies by entity)

### Behavior Rules

- **Minimum 2 characters** before searching (avoids noise)
- **Debounce 300ms** — don't fire on every keystroke
- **Max 5 results per category** in collapsed view, "Show all N" link to expand
- **Categories with 0 hits are hidden** — don't show empty sections
- **Category sort order is fixed** (see §3) — most commonly searched entities first
- **Results within a category** sorted by relevance (exact name match → prefix match → substring match)
- **Workspace-scoped via RLS** — users only see entities from workspaces they're members of
- **Independent of scope picker** — search spans ALL accessible workspaces regardless of current scope bar selection
- **Keyboard navigation** — arrow keys to move between results, Enter to select

---

## 3. Searchable Entities (Priority Order)

Categories appear in this fixed order (most useful first). Each category searches specific text columns.

| # | Category | Table | Lucide Icon | Searchable Columns | Namespace Scope Via |
|---|----------|-------|-------------|-------------------|-------------------|
| 1 | **Applications** | `applications` | `file-text` | `name`, `short_description`, `description`, `owner` | `workspaces.namespace_id` |
| 2 | **Deployment Profiles** | `deployment_profiles` | `settings` | `name`, `server_name`, `version` | `workspaces.namespace_id` |
| 3 | **Contacts** | `contacts` | `user` | `display_name`, `email`, `job_title` | Direct `namespace_id` |
| 4 | **IT Services** | `it_services` | `server` | `name`, `description` | Direct `namespace_id` |
| 5 | **Software Products** | `software_products` | `package` | `name`, `product_family_name` | Direct `namespace_id` |
| 6 | **Technology Products** | `technology_products` | `cpu` | `name`, `description` | Direct `namespace_id` |
| 7 | **Integrations** | `application_integrations` | `link` | `name`, `external_system_name`, `description` | `workspaces.namespace_id` (via source app) |
| 8 | **Initiatives** | `initiatives` | `target` | `title`, `description` | Direct `namespace_id` |
| 9 | **Findings** | `findings` | `search` | `title`, `rationale` | Direct `namespace_id` |
| 10 | **Ideas** | `ideas` | `lightbulb` | `title`, `description` | Direct `namespace_id` |
| 11 | **Programs** | `programs` | `bar-chart-2` | `title`, `description` | Direct `namespace_id` |
| 12 | **Portfolios** | `portfolios` | `folder` | `name`, `description` | `workspaces.namespace_id` |

### Secondary Text (contextual breadcrumb per category)

Since search spans all accessible workspaces, the **workspace name is always shown** in the secondary line so users know where the result lives. This is especially important for multi-workspace users who may see the same application name in different departments.

| Category | Secondary Line | Join Notes |
|----------|---------------|------------|
| Applications | `{workspace.name} · {time_quadrant} · {hosting_type}` | LATERAL join to `portfolio_assignments` (limit 1) for TIME; left join to primary DP for hosting |
| Deployment Profiles | `{application.name} · {workspace.name} · {hosting_type}` | Direct columns + app join |
| Contacts | `{job_title} · {primary_workspace.name}` | `primary_workspace_id` → workspaces (LEFT JOIN — contacts may lack workspace) |
| IT Services | `{service_type.name} · {owner_workspace.name}` | `service_type_id` → `service_types`; `owner_workspace_id` → workspaces |
| Software Products | `{organization.name} · {category.name}` | `manufacturer_org_id` → `organizations`; `category_id` → `software_product_categories` |
| Technology Products | `{category.name}` | `category_id` → `technology_product_categories`. No workspace — namespace-level catalog. |
| Integrations | `{source_app.name} → {target_app.name or external_system_name}` | Both apps joined; target may be null (external) |
| Initiatives | `{status} · {priority} · {workspace.name}` | `workspace_id` optional (LEFT JOIN) |
| Findings | `{impact} · {assessment_domain}` | Direct columns; no workspace join |
| Ideas | `{status} · {workspace.name}` | `workspace_id` optional (LEFT JOIN) |
| Programs | `{status} · {strategic_theme}` | Direct columns; no workspace join |
| Portfolios | `{workspace.name}` | Via `workspace_id` |

---

## 4. Database Implementation

### Approach: ILIKE with Relevance Ranking

At GetInSync's current scale (tens to hundreds of records per entity per namespace), ILIKE with existing B-tree indexes is fast enough (<100ms). This avoids the complexity of maintaining `tsvector` columns or expression indexes across 12 tables.

The RPC uses a three-tier relevance ranking within each category:
- **Rank 0:** Exact name match (case-insensitive)
- **Rank 1:** Prefix match (query is start of name)
- **Rank 2:** Substring match (query appears anywhere)

### Deployed RPC: `global_search(text, integer)`

**Signature:** `global_search(p_query text, p_limit integer DEFAULT 5) RETURNS jsonb`
**Security:** `SECURITY INVOKER` — RLS enforced on every table queried
**Volatility:** `STABLE`
**GRANTs:** `authenticated` + `service_role`

**Returns:** JSONB array of category objects. Categories with zero hits are excluded. Each category contains:

```json
[
  {
    "category": "Applications",
    "icon": "file-text",
    "total": 2,
    "results": [
      {
        "id": "uuid",
        "primary_text": "QuickBooks Online",
        "secondary_text": "Finance Department · Invest · SaaS",
        "operational_status": "operational"
      }
    ]
  },
  {
    "category": "Contacts",
    "icon": "user",
    "total": 1,
    "results": [
      {
        "id": "uuid",
        "primary_text": "Jane Smith",
        "secondary_text": "Administrator · Finance Department"
      }
    ]
  }
]
```

**Special fields per category:**
- Applications include `operational_status` for retired/non-operational dimming in the UI
- Deployment Profiles include `application_id` for navigation routing (DPs navigate to their parent app)

### Schema Corrections (from v1.0 draft)

During implementation against the live schema (Feb 26 dump), these corrections were applied:

| Entity | v1.0 Draft Assumed | Actual Schema |
|--------|-------------------|---------------|
| Contacts | `workspace_id` | `primary_workspace_id` + direct `namespace_id` on table |
| IT Services | `workspace_id` | `owner_workspace_id` + direct `namespace_id` |
| Software Products | `vendor_name` column, `description` searchable | `manufacturer_org_id` → JOIN `organizations.name`; no `description` column; search `product_family_name` instead |
| Technology Products | Scoped via workspace | Direct `namespace_id`, no workspace column |
| Findings | `domain` column | `assessment_domain` |
| Programs | `theme` column | `strategic_theme` |
| Applications (PA join) | Direct JOIN | LATERAL join with LIMIT 1 (apps may have multiple portfolio assignments) |

### Future Upgrade: Full-Text Search

When AI chat deploys and `apm_embeddings` exists with its `content_tsv tsvector` column, the `global_search` RPC can detect that table and switch to `ts_rank_cd` for better result ranking (stemming, prefix matching). The frontend interface stays identical — only the SQL internals change. See §10.2 for the progressive upgrade path.

### Future Upgrade: Trigram Fuzzy Matching

For typo-tolerant search, add `pg_trgm` (already planned for AI chat MVP):
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_applications_name_trgm ON applications USING gin (name gin_trgm_ops);
```
This enables similarity matching: "quickboks" still finds "QuickBooks". Evaluate after MVP launch based on user feedback.

---

## 5. Frontend Implementation

### Component Structure

```
src/
  components/
    search/
      GlobalSearchOverlay.tsx    — full overlay with input + results
      SearchResultCategory.tsx   — collapsible category section
      SearchResultRow.tsx        — individual result row
  hooks/
    useGlobalSearch.ts           — debounced RPC call + state
```

### GlobalSearchOverlay.tsx

- **Trigger:** Search icon in top nav + `Ctrl+K` / `⌘+K` keyboard shortcut
- **Overlay:** Centered modal (max-w-2xl) with semi-transparent backdrop (like Spotlight / VS Code command palette)
- **Input:** Autofocused, large text, clear button
- **Results area:** Scrollable, categorized
- **Keyboard:** `↑`/`↓` navigate results, `Enter` selects, `Escape` closes

```tsx
<div className="fixed inset-0 z-50 bg-black/40">
  <div className="mx-auto mt-20 max-w-2xl bg-white rounded-xl shadow-2xl overflow-hidden">
    {/* Search input */}
    <div className="flex items-center px-4 py-3 border-b">
      <Search className="w-5 h-5 text-gray-400 mr-3" />
      <input
        autoFocus
        placeholder="Search applications, services, contacts..."
        value={query}
        onChange={e => setQuery(e.target.value)}
        className="flex-1 text-lg outline-none"
      />
      {query && <X className="w-5 h-5 cursor-pointer" onClick={() => setQuery('')} />}
    </div>
    
    {/* Results */}
    <div className="max-h-96 overflow-y-auto">
      {categories.map(cat => (
        <SearchResultCategory key={cat.category} {...cat} onSelect={handleNavigate} />
      ))}
    </div>
    
    {/* Footer hint */}
    <div className="px-4 py-2 border-t text-xs text-gray-400">
      ↑↓ Navigate · Enter Select · Esc Close
    </div>
  </div>
</div>
```

### useGlobalSearch.ts

```typescript
import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';

interface SearchCategory {
  category: string;
  icon: string;
  results: SearchResult[];
  total: number;
}

interface SearchResult {
  id: string;
  application_id?: string;       // DPs — for navigation routing
  primary_text: string;
  secondary_text: string;
  operational_status?: string;    // Applications — for retired dimming
}

export function useGlobalSearch(query: string, limit = 5) {
  const [categories, setCategories] = useState<SearchCategory[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout>>();

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (query.trim().length < 2) {
      setCategories([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);

    debounceRef.current = setTimeout(async () => {
      const { data, error } = await supabase.rpc('global_search', {
        p_query: query.trim(),
        p_limit: limit,
      });

      if (!error && data) {
        setCategories(data as SearchCategory[]);
      }
      setIsLoading(false);
    }, 300);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query, limit]);

  return { categories, isLoading };
}
```

### Search Term Highlighting

```typescript
function highlightMatch(text: string, query: string): React.ReactNode {
  const index = text.toLowerCase().indexOf(query.toLowerCase());
  if (index === -1) return text;
  return (
    <>
      {text.slice(0, index)}
      <strong className="text-gray-900">{text.slice(index, index + query.length)}</strong>
      {text.slice(index + query.length)}
    </>
  );
}
```

### Navigation Routing

```typescript
const ROUTE_MAP: Record<string, (result: SearchResult) => string> = {
  'Applications': (r) => `/app/${r.id}`,
  'Deployment Profiles': (r) => `/app/${r.application_id}`,
  'Contacts': (r) => `/contacts/${r.id}`,
  'IT Services': (r) => `/settings/it-services/${r.id}`,
  'Software Products': (r) => `/settings/software-products/${r.id}`,
  'Technology Products': (r) => `/settings/technology-products/${r.id}`,
  'Integrations': (r) => `/integrations/${r.id}`,
  'Initiatives': (r) => `/roadmap/initiatives/${r.id}`,
  'Findings': (r) => `/roadmap/findings/${r.id}`,
  'Ideas': (r) => `/roadmap/ideas/${r.id}`,
  'Programs': (r) => `/roadmap/programs/${r.id}`,
  'Portfolios': (r) => `/portfolios/${r.id}`,
};
```
**Note:** Route paths above are approximate — verify against actual router config before implementing.

---

## 6. Top Nav Integration

Add search trigger to the existing top navigation bar:

```
┌─────────────────────────────────────────────────────────────┐
│ 🔷 City of Riverside          [🔍] [🏢 Police Dept ▾] [📁 Core ▾] │
│   Application Portfolio Management                           │
├─────────────────────────────────────────────────────────────┤
│ Overview | Application Health | Technology Health | Roadmap   │
└─────────────────────────────────────────────────────────────┘
```

- Search icon `[🔍]` placed to the left of the workspace picker
- Clicking it opens the overlay
- `Ctrl+K` / `⌘+K` global keyboard shortcut registered at app root level
- Works on all tabs — search is independent of scope picker state
- Search spans all workspaces the user has access to (RLS-enforced), regardless of which workspace is selected in the scope bar
- Workspace name shown on every result so users know where things live

---

## 7. Security Considerations

- **RLS enforcement:** The RPC uses `SECURITY INVOKER` so RLS policies on each table apply automatically. Users only see entities from workspaces they're members of — this is the workspace access boundary. A user with access to Police Department and Fire Department but not Public Works will never see Public Works results. The search intentionally does NOT further restrict by the scope picker's current selection — it searches across all of the user's accessible workspaces so they can find things outside their current focus.
- **Input sanitization:** The `p_query` parameter is used in ILIKE patterns via PL/pgSQL parameter binding (not string concatenation), which is safe from SQL injection.
- **Rate limiting:** The 300ms frontend debounce prevents excessive queries. At the database level, the per-category LIMIT caps result sizes to `p_limit` (default 5) per entity type.
- **No audit logging needed:** Search is a read-only operation. No state changes. Logging search queries would be a privacy concern without clear value.

---

## 8. Performance Budget

| Metric | Target |
|--------|--------|
| Time to first result | < 200ms (including 300ms debounce = ~500ms perceived) |
| Total RPC execution | < 100ms for namespace with 500 apps |
| Max result payload | ~20KB (5 results × 12 categories × ~300 bytes each) |
| Frontend re-render | < 16ms (no layout thrash) |

### Indexes Already In Place
- `idx_applications_name` — B-tree on `applications.name`
- `idx_applications_workspace` — B-tree on `applications.workspace_id`
- Namespace-id indexes on `contacts`, `it_services`, `software_products`, `technology_products`, `initiatives`, `findings`, `ideas`, `programs`
- Workspace-id indexes on `deployment_profiles`, `portfolios`

### Indexes to Add (if needed)
```sql
-- Only add these if query times exceed 100ms
CREATE INDEX idx_contacts_display_name ON contacts USING btree (display_name);
CREATE INDEX idx_it_services_name ON it_services USING btree (name);
CREATE INDEX idx_software_products_name ON software_products USING btree (name);
CREATE INDEX idx_initiatives_title ON initiatives USING btree (title);
```

---

## 9. Phased Delivery

### Phase 1: MVP (1–2 days) ← CURRENT
- ✅ `global_search` RPC deployed (all 12 entity types)
- `GlobalSearchOverlay` with categorized results
- `useGlobalSearch` hook with debounce
- Navigation routing on result click
- `Ctrl+K` / `⌘+K` shortcut
- Search icon in top nav
- Search term highlighting in primary text

### Phase 2: Polish (0.5 day)
- "Show all N" expand per category (re-calls RPC with higher limit)
- Keyboard arrow navigation within results
- Empty state with suggestions ("Try searching for an application name or contact")
- Retired/non-operational apps shown dimmed with badge

### Phase 3: Future Enhancements
- `pg_trgm` fuzzy matching for typo tolerance
- `tsvector` full-text search if scale demands it
- Search analytics (what do users search for most?)
- Scoped search option ("search within this workspace only")
- Recent searches (in-memory state, not localStorage)

---

## 10. AI Chat Integration Path

### 10.1 The Relationship: Navigation vs Discovery

Global search and AI chat serve different needs but operate on the same entity universe:

| Capability | Global Search | AI Chat |
|-----------|--------------|---------|
| **Purpose** | Navigation — "take me to X" | Discovery — "what should I do about X?" |
| **Input** | Entity name or keyword | Natural language question |
| **Output** | Categorized links | Analytical narrative |
| **Latency** | <200ms (instant feel) | 2–5s (streaming acceptable) |
| **Infrastructure** | ILIKE on existing tables | pgvector + embeddings + LLM |
| **Dependencies** | Zero new tables | `apm_embeddings`, Edge Functions, API keys |
| **Ship timeline** | Now (1–2 days) | Later (AI roadmap) |

They should NOT be built as competing systems. Global search ships now with zero dependencies. When AI chat deploys, global search upgrades its internals and the search overlay gains an AI handoff.

### 10.2 Progressive Upgrade Path

The `global_search` RPC is designed to upgrade its internals without changing the frontend interface. Three stages:

**Stage 1: ILIKE (deployed)**
```
User types → global_search RPC → ILIKE across 12 tables → categorized results
```
- Zero new tables or extensions
- Sub-100ms at current scale
- Good enough for exact and substring matching

**Stage 2: Full-Text Search (when `apm_embeddings` deploys)**

When the AI chat MVP deploys `apm_embeddings` with its `content_tsv tsvector` column and `pg_trgm` extension, the `global_search` RPC gains two upgrades for free:

```sql
-- Upgrade 1: tsvector for ranked results (stemming, prefix matching)
-- "migrate" now matches "migration", "migrating"
WHERE content_tsv @@ to_tsquery('english', p_query || ':*')
ORDER BY ts_rank_cd(content_tsv, to_tsquery('english', p_query || ':*')) DESC

-- Upgrade 2: pg_trgm for fuzzy matching (typo tolerance)
-- "quickboks" still finds "QuickBooks"
WHERE similarity(name, p_query) > 0.3
ORDER BY similarity(name, p_query) DESC
```

The RPC can detect which infrastructure is available and use the best strategy:

```sql
v_has_embeddings := EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_name = 'apm_embeddings' AND table_schema = 'public'
);

v_has_trgm := EXISTS (
  SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm'
);
```

**Stage 3: Semantic Search (future)**

When the full AI pipeline is running, the search overlay could optionally use the `search_apm_context` vector search RPC for semantically rich queries. Example: user types "apps with security risk" — ILIKE finds nothing, but vector search finds apps with high T-scores or vulnerability findings. This is a tier-gated feature — semantic search costs tokens (embedding the query), so it only activates for Plus/Enterprise tiers.

### 10.3 Search-to-Chat Handoff

The search overlay becomes the front door to AI chat. When search results are displayed, the bottom section offers contextual AI prompts based on the search term:

```
┌──────────────────────────────────────────────────┐
│ 🔍  "quickbooks"                              ✕  │
├──────────────────────────────────────────────────┤
│                                                   │
│ Applications (2)                             ▸    │
│ ┌─────────────────────────────────────────────┐  │
│ │ 📋 QuickBooks Online                        │  │
│ │    Finance Department · Invest · SaaS        │  │
│ ├─────────────────────────────────────────────┤  │
│ │ 📋 QuickBooks Desktop                       │  │
│ │    Accounting Division · Eliminate · On-Prem  │  │
│ └─────────────────────────────────────────────┘  │
│                                                   │
│ ─────────────────── Ask AI ─────────────────────  │
│ 💬 "What depends on QuickBooks?"                  │
│ 💬 "Compare QuickBooks Online vs Desktop"         │
│ 💬 "What's the migration plan for QuickBooks?"    │
└──────────────────────────────────────────────────┘
```

**Implementation:**
- The "Ask AI" section only appears when AI chat is enabled for the namespace's tier
- Clicking an AI prompt opens the `<ApmChatPanel />` with the query pre-filled
- Prompts are generated from templates based on entity type and search results:

```typescript
function generateAiPrompts(searchTerm: string, categories: SearchCategory[]): string[] {
  const prompts: string[] = [];

  const hasApps = categories.some(c => c.category === 'Applications' && c.total > 0);
  const hasMultipleApps = categories.some(c => c.category === 'Applications' && c.total > 1);

  if (hasApps) {
    prompts.push(`What depends on ${searchTerm}?`);
    prompts.push(`What's the risk profile for ${searchTerm}?`);
  }
  if (hasMultipleApps) {
    prompts.push(`Compare the ${searchTerm} deployments`);
  }

  prompts.push(`Tell me everything about ${searchTerm}`);

  return prompts.slice(0, 3);
}
```

### 10.4 Shared Entity Type Registry

Both global search and AI chat need to know about entity types, their searchable fields, and their navigation routes. Define this once:

```typescript
// lib/entity-registry.ts — shared between global search and AI chat

export interface EntityTypeConfig {
  key: string;
  label: string;
  icon: string;                    // lucide-react icon name
  table: string;
  searchFields: string[];
  embeddingEntityType?: string;    // matching value in apm_embeddings.entity_type
  routeBuilder: (result: any) => string;
  secondaryTextBuilder: (result: any) => string;
}

export const ENTITY_TYPES: EntityTypeConfig[] = [
  {
    key: 'applications',
    label: 'Applications',
    icon: 'file-text',
    table: 'applications',
    searchFields: ['name', 'short_description', 'description', 'owner'],
    embeddingEntityType: 'application',
    routeBuilder: (r) => `/app/${r.id}`,
    secondaryTextBuilder: (r) =>
      `${r.workspace_name} · ${r.time_quadrant || ''} · ${r.hosting_type || ''}`,
  },
  {
    key: 'deployment_profiles',
    label: 'Deployment Profiles',
    icon: 'settings',
    table: 'deployment_profiles',
    searchFields: ['name', 'server_name', 'version'],
    embeddingEntityType: 'deployment_profile',
    routeBuilder: (r) => `/app/${r.application_id}`,
    secondaryTextBuilder: (r) => `${r.application_name} · ${r.workspace_name}`,
  },
  // ... remaining 10 entity types follow same pattern
];
```

### 10.5 Implementation Order

```
NOW (Global Search MVP)          LATER (AI Chat MVP)           FUTURE
─────────────────────           ───────────────────           ───────
global_search RPC (ILIKE)  →    apm_embeddings table     →    Semantic search in overlay
GlobalSearchOverlay.tsx    →    embed-entity Edge Fn     →    "Ask AI" prompts in search
Ctrl+K shortcut            →    apm-chat Edge Fn         →    Search-to-chat handoff
12 entity types            →    ApmChatPanel.tsx         →    Unified search + chat UX
                           →    Backfill embeddings
                           →    DB triggers for sync
```

Global search is a prerequisite for a good AI chat experience. Users will want to navigate to the entities the AI is talking about. The search overlay provides that navigation layer. Ship it first, AI chat builds on top.

---

## 11. Open Questions

| # | Question | Answer |
|---|----------|--------|
| 1 | Should search respect workspace scope or always be namespace-wide? | **Respects user's workspace access boundaries.** The RPC uses `SECURITY INVOKER`, so existing RLS policies enforce that users only see results from workspaces they're members of. Search does NOT further narrow by the scope picker's current workspace selection — it always searches across all of the user's accessible workspaces. The scope picker is for dashboard focus, search is for "find anything I can see." |
| 2 | Should we show retired/non-operational apps? | **Yes, but dimmed.** Searching for a retired app and finding nothing is confusing. Show it with a "Retired" badge. The RPC returns `operational_status` on application results for this purpose. |
| 3 | Where does the search icon go relative to the scope pickers? | **To the left** of the workspace picker. Search is always available regardless of scope state. |
| 4 | What about the "18-year-old test"? | Search is inherently intuitive. The placeholder text guides expectations. Category labels use plain English (not CSDM jargon). |

---

## 12. Database Deployment Log

| Date | Chunk | Objects | Status |
|------|-------|---------|--------|
| 2026-02-28 | Chunk 1 | `global_search` RPC + GRANTs (authenticated, service_role) | ⏳ Deploying (function count 53→54) |

---

*Document: features/global-search/architecture.md*
*Version: v1.1 — RPC deploying, frontend pending*
