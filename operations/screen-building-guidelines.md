# Screen-Building Guidelines — GetInSync NextGen
> Version 1.0 — 2026-03-03
> Status: 🟢 AS-BUILT
> Owner: Stuart Holtby

These rules govern how every page and panel in the GetInSync NextGen frontend is structured, styled, and composed. Follow them when building new screens or refactoring existing ones.

**Stack:** React + TypeScript + Tailwind CSS + Lucide React icons
**Reference implementations:** See "Canonical Files" column in each section.

---

## Table of Contents

1. [Page Layout Zones](#1-page-layout-zones)
2. [Workspace Banner](#2-workspace-banner)
3. [Sub-tab Navigation](#3-sub-tab-navigation)
4. [Toolbar Row](#4-toolbar-row)
4a. [Filter Drawer](#4a-filter-drawer)
5. [KPI / Stat Cards](#5-kpi--stat-cards)
6. [Data Tables](#6-data-tables)
7. [Collapsible Panels & Lists](#7-collapsible-panels--lists)
8. [Charts & Visualizations](#8-charts--visualizations)
9. [Form / Edit Pages](#9-form--edit-pages)
10. [Typography Scale](#10-typography-scale)
11. [Button Hierarchy](#11-button-hierarchy)
12. [Icons](#12-icons)
13. [Color System](#13-color-system)
14. [Spacing & Grid](#14-spacing--grid)
15. [Empty & Loading States](#15-empty--loading-states)
16. [Responsive Behavior](#16-responsive-behavior)

---

## 1. Page Layout Zones

Every dashboard page follows this vertical stacking order. No zone may be skipped or reordered.

```
┌─────────────────────────────────────────────┐
│  Global Header (sticky top-0 z-40, 77px)    │  ← App shell, not per-page
│  Logo · Workspace selector · Portfolio · User│
├─────────────────────────────────────────────┤
│  Main Tab Bar                               │  ← Scrolls with content
├═════════════════════════════════════════════╡
│ ┌─ Sticky Block (top-[77px] z-30) ───────┐ │
│ │  Workspace Banner                       │ │  ← Workspace + portfolio
│ │  Sub-tab Navigation (if applicable)     │ │  ← e.g., Initiatives | Scorecard
│ │  Toolbar Row                            │ │  ← Filters · Actions
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│  Content Area                               │  ← KPI cards, tables, charts
└─────────────────────────────────────────────┘
```

**Rules:**
- The **Workspace Banner** appears on App Health, Tech Health, and Roadmap. The Overview tab has its own namespace-level context and is unchanged.
- The Workspace Banner, Sub-tabs, and Toolbar Row form a **single sticky block** at `sticky top-[77px] z-30 bg-gray-50 -mx-6 px-6`. They stick together below the global header while the user scrolls.
- The **Main Tab Bar** (Overview | App Health | Tech Health | Roadmap) scrolls with content — it is not sticky.
- **Sub-tabs** only appear on pages with multiple sub-views (Tech Health, Roadmap)
- The **Toolbar Row** is always a dedicated row — never embed filters or actions inside the tab bar or the banner
- **Content Area** uses `max-w-7xl mx-auto` for centered content, or `max-w-[95vw] mx-auto` for wide tables

---

## 2. Workspace Banner

The banner anchors the user's context. It appears on App Health, Tech Health, and Roadmap.

```
┌─────────────────────────────────────────────┐
│  GOS Workspace                              │
│  All Portfolios                             │
└─────────────────────────────────────────────┘
```

**Tailwind classes:**
```
Sticky wrapper: sticky top-[77px] z-30 bg-gray-50 -mx-6 px-6
               (this div wraps banner + sub-tabs + toolbar as a single sticky block)
Banner inner:   pt-4 pb-2
Title:          text-2xl font-semibold text-gray-900
Subtitle:       text-lg text-gray-500
```

**Rules:**
- Part of the sticky block at `top-[77px]`. The outer wrapper is shared with the sub-tabs and toolbar row.
- Use the shared `WorkspaceBanner` component — it reads workspace/portfolio context from `useAuth()` and `useScope()` internally, no props needed.
- When the workspace selector or portfolio selector changes in the global header, the banner updates reactively.

| Canonical File | Notes |
|---|---|
| `src/components/shared/WorkspaceBanner.tsx` | Shared banner component (text only, no wrapper styling) |
| `src/components/dashboard/DashboardPage.tsx` | Sticky block: banner + toolbar |
| `src/components/technology-health/TechnologyHealthPage.tsx` | Sticky block: banner + sub-tabs + toolbar |
| `src/components/value-creation/ValueCreationPage.tsx` | Sticky block: banner + sub-tabs + toolbar |

---

## 3. Sub-tab Navigation

For pages with multiple sub-views (Tech Health, Roadmap). Not used on Overview or App Health.

```
┌─────────────────────────────────────────────┐
│  Initiatives · Scorecard · Ideas · Programs │
└─────────────────────────────────────────────┘
```

**Tailwind classes:**
```
Container:      flex items-center gap-0 border-b border-gray-200
Tab button:     px-4 py-2 text-sm font-medium border-b-2 whitespace-nowrap transition-colors
  Active:       border-teal-600 text-teal-700
  Inactive:     border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300
  Disabled:     text-gray-400 cursor-not-allowed
Tier badge:     ml-1.5 text-[10px] font-semibold text-gray-400 uppercase
```

**Rules:**
- Sub-tabs sit directly below the Workspace Banner
- **No action buttons inside the tab bar** — filters, exports, and create buttons go in the Toolbar Row below
- Tier-gated tabs show a lock icon + tier label (e.g., "Plus", "Enterprise") and are non-clickable
- Active tab uses `border-b-2 border-teal-600` underline indicator

| Canonical File | Notes |
|---|---|
| `src/components/technology-health/TechnologyHealthPage.tsx` | Sub-tab implementation |
| `src/components/value-creation/ValueCreationPage.tsx` | Sub-tab implementation |

---

## 4. Toolbar Row

The toolbar is the single row where all page-level actions live. It appears below the sub-tabs (or below the banner if no sub-tabs).

```
┌──────────────────────────────────────────────────────┐
│  [search / icons]       Export · + Create · 🔽 Filters │
└──────────────────────────────────────────────────────┘
```

**Tailwind classes:**
```
Container:     flex items-center justify-between gap-4 px-6 py-3
Left group:    flex items-center gap-2
Right group:   flex items-center gap-3
```

**Layout rules:**

| Position | Content | Button Style |
|----------|---------|-------------|
| Left | Search input, inline filter icons (if any) | Icon buttons with badge |
| Right | Export CSV | Secondary button (white + border) |
| Right | "Create X" (primary CTA) | Primary button (teal, with Plus icon) |
| Right (rightmost) | Filter drawer toggle (with active count badge) | Ghost button with teal highlight (see §4a) |

**Right-group ordering** (left to right):

```
[Export CSV]  →  [+ Create X]  →  [🔽 Filters]
 secondary        primary CTA      always rightmost
```

Omit any button that doesn't apply to the current page. The Filters button is always pinned to the far-right edge regardless of how many other buttons are present.

**Rules:**
- The Toolbar Row is part of the **sticky block** (§2) — it does not have its own `sticky` positioning. The parent sticky wrapper controls stickiness for the entire banner + sub-tabs + toolbar group.
- **One toolbar row per page** — never split actions across multiple rows
- **Filter drawer toggle is always rightmost** — see §4a for the full filter drawer pattern
- Export CSV is always **secondary** style; Create X is always **primary** teal
- If the page has no filters, the right side contains only Export and/or Create
- If the page has no create action, only show Export (or nothing) before Filters
- The "Filters" label text is optional — an icon-only button with badge is acceptable

| Canonical File | Notes |
|---|---|
| `src/components/technology-health/TechnologyHealthPage.tsx` | Toolbar Row with Filters rightmost |

---

## 4a. Filter Drawer

When a page uses multi-faceted filtering (more than a simple search or single dropdown), the filters live in a right-side drawer panel that slides in from the viewport edge.

```
┌──────────────────────────────────────────────────────┐
│  [left group]           Export · + Create · 🔽 Filters │  ← Toolbar Row (§4)
├──────────────────────────────────────────┬───────────┤
│                                          │  Filter   │
│           Content Area                   │  Drawer   │  ← Overlays right edge
│           (does not shift)               │  300px    │
│                                          │           │
├──────────────────────────────────────────┴───────────┤
│  ░░░░░░░░░░░░ semi-transparent backdrop ░░░░░░░░░░░░ │  ← Click to close
└──────────────────────────────────────────────────────┘
```

### Filter Button

The filter toggle button is always the **rightmost** item in the Toolbar Row right group (see §4). This positions it adjacent to the drawer it controls.

**Tailwind classes:**
```
Button:       relative flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg transition-colors
  Active:     text-teal-700 bg-teal-50 hover:bg-teal-100
  Inactive:   text-gray-500 hover:text-gray-700 hover:bg-gray-100
Badge:        ml-0.5 w-5 h-5 bg-teal-600 text-white text-[10px] font-bold rounded-full
              flex items-center justify-center
```

### Drawer Panel

**Tailwind classes:**
```
Backdrop:      fixed inset-0 z-40 bg-black/15 transition-opacity duration-[250ms]
               (pointer-events-auto when open, pointer-events-none when closed)
Drawer panel:  fixed top-0 right-0 bottom-0 w-[300px] z-50 bg-white shadow-xl
               border-l border-gray-200 transform transition-transform duration-[250ms] ease-in-out
               (translate-x-0 when open, translate-x-full when closed)
Drawer header: flex items-center justify-between px-4 py-3 border-b border-gray-200
Drawer title:  text-sm font-semibold text-gray-900
Close button:  p-1 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600 (X icon, w-4 h-4)
Drawer body:   px-4 py-3 overflow-y-auto (scrolls internally)
```

### Rules

- **Overlay, not push:** The drawer uses `position: fixed` and overlays content — main content does NOT shift, resize, or reflow
- **Backdrop required:** Semi-transparent `bg-black/15` overlay covers the content area, clickable to close the drawer
- **Drawer width:** Standard `w-[300px]` (300px) on all screens
- **Z-index layering:** Backdrop `z-40`, drawer panel `z-50`
- **Close triggers:** Four ways to close: (1) click backdrop, (2) click X button, (3) press Escape key, (4) switch tabs
- **Active filter count:** Display a teal badge on the Filters button showing the number of active filters; hide badge when count is zero
- **Tab switching:** Close the filter drawer automatically when the user switches sub-tabs

| Canonical File | Notes |
|---|---|
| `src/components/technology-health/TechnologyHealthPage.tsx` | Toolbar Row with Filters button rightmost |
| `src/components/technology-health/TechnologyHealthSummary.tsx` | Filter drawer overlay + backdrop implementation |
| `src/components/technology-health/TechnologyHealthFilterSidebar.tsx` | Filter sidebar content (collapsible sections) |

---

## 5. KPI / Stat Cards

Two standardized variants. Choose based on context.

### Variant A — Full Dashboard Cards

Used on main dashboard summaries: Overview, App Health, Tech Health.

```
┌──────────────────┐
│ 🎯  Applications │  ← icon in colored bg pill + label
│                  │
│ 10               │  ← large value
│ across 3 wsps    │  ← sublabel
└──────────────────┘
```

**Tailwind classes:**
```
Grid:         grid grid-cols-1 md:grid-cols-2 lg:grid-cols-{n} gap-4
              (n = number of cards, typically 5 or 6)
Card:         bg-white rounded-xl p-5 shadow-sm border border-gray-100
Icon wrapper: p-2 rounded-lg {iconBg}          (e.g., bg-teal-50, bg-amber-50)
Icon:         w-5 h-5 {iconColor}              (e.g., text-teal-600, text-amber-600)
Label:        text-sm text-gray-500
Value:        text-2xl font-semibold text-gray-900
Sublabel:     text-xs text-gray-400 mt-1
```

**Interactive cards** (clickable to drill down) add:
```
cursor-pointer hover:shadow-md hover:border-gray-200 transition-all
```

**Loading skeleton:**
```
Same card dimensions with animate-pulse, gray-100 rectangles matching layout
```

| Canonical File | Notes |
|---|---|
| `src/components/overview/OverviewKpiCards.tsx` | Reference implementation |
| `src/components/technology-health/TechnologyHealthSummary.tsx` (line ~948) | Same pattern, 6 cards |

### Variant B — Compact Sub-view Cards

Used on sub-views where KPIs are secondary to the main content: Initiatives, Scorecard.

```
┌────────────────┐
│ Active Init.   │  ← label
│ 4 / 6          │  ← value (with optional trend icon)
└────────────────┘
```

**Tailwind classes:**
```
Grid:      grid grid-cols-2 md:grid-cols-4 gap-3
Card:      bg-white rounded-lg border border-gray-200 p-3
Label:     text-xs text-gray-500 mb-1
Value:     text-lg font-semibold {color}          (text-gray-900 default, or semantic color)
Icon:      w-4 h-4 {color}                        (optional, inline with value)
```

| Canonical File | Notes |
|---|---|
| `src/components/value-creation/ValueCreationKpiBar.tsx` | Reference implementation |

### When to Use Which

| Variant | When |
|---------|------|
| **A (Full)** | Top-level dashboard tabs where KPIs are the primary summary (Overview, App Health, Tech Health) |
| **B (Compact)** | Sub-views within a tab where KPIs provide context but the main content is a table/grid/chart |

---

## 6. Data Tables

All data tables must be sortable and paginated.

**Table structure:**
```
┌──────────────────────────────────────────┐
│  Column A ↕ │ Column B ↕ │ Actions      │  ← Header row
├──────────────────────────────────────────┤
│  Row 1      │ Data       │ ⋮            │
│  Row 2      │ Data       │ ⋮            │
│  ...        │            │              │
├──────────────────────────────────────────┤
│  Showing 1–10 of 42   [< 1 2 3 4 5 >]  │  ← Pagination
│                              Show [10▾] │
└──────────────────────────────────────────┘
```

**Tailwind classes:**
```
Table container: overflow-x-auto
Table:           w-full
Header cell:     px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider
Body cell:       px-6 py-4 text-sm text-gray-900
Row hover:       hover:bg-gray-50
Row border:      border-b border-gray-100
Sort icons:      w-4 h-4 text-gray-400 (ArrowUpDown for unsorted, ArrowUp/ArrowDown for active)
```

**Pagination rules:**
- **Default page size: 10** for all tables
- Use `TablePagination` component from `src/components/ui/TablePagination.tsx`
- Page size options: 10, 25, 50, 100, All
- Active page button: `bg-teal-600 text-white`

**Column sorting:**
- All data columns must be sortable (click header to toggle)
- Sort indicator icons from `ACTION_ICONS.sort` (ArrowUpDown) when unsorted
- Show `ArrowUp` or `ArrowDown` when actively sorted
- Default sort: most relevant column descending (e.g., name ascending for lists, date descending for logs)

**Row actions:**
- Use icon buttons (`p-1.5 text-gray-400 hover:text-gray-600`) for row-level actions
- Common actions: Edit (Pencil), Delete (Trash2), View (ChevronRight)
- Show on hover via `group` / `group-hover:opacity-100` if more than 2 actions

| Canonical File | Notes |
|---|---|
| `src/components/ui/TablePagination.tsx` | Shared pagination component |
| `src/components/dashboard/DashboardAppTable.tsx` | Sortable table with pagination |
| `src/components/technology-health/SummaryApplicationTable.tsx` | Table with search + filters |

---

## 7. Collapsible Panels & Lists

Used for secondary content that can be hidden (e.g., Unassessed Applications, Needs Attention).

**Structure:**
```
┌─────────────────────────────────────────────┐
│  Unassessed Applications  [5]          ▼    │  ← Header (clickable)
├─────────────────────────────────────────────┤
│  Google Analytics                      →    │
│  Slack                                 →    │
│  Zoom                                  →    │
│                          Show all (5) →     │
└─────────────────────────────────────────────┘
```

**Tailwind classes:**
```
Container:     bg-white rounded-xl border border-gray-200 overflow-hidden
Header:        flex items-center justify-between px-5 py-4 cursor-pointer hover:bg-gray-50
Title:         text-lg font-semibold text-gray-900
Count badge:   ml-2 px-2 py-0.5 text-xs font-medium rounded-full bg-amber-100 text-amber-800
Chevron:       w-5 h-5 text-gray-400 transition-transform (rotate-180 when open)
List item:     px-5 py-3 flex items-center justify-between border-t border-gray-100 hover:bg-gray-50
Item text:     text-sm text-gray-900
Item action:   w-4 h-4 text-gray-400 (ChevronRight)
Show all:      text-sm text-teal-600 hover:text-teal-700 font-medium
```

**Rules:**
- Show a maximum of 5 items by default; provide "Show all (n)" link to expand
- Count badge uses contextual color: amber for warnings/attention, teal for informational
- Panels default to **collapsed** unless they contain items requiring action

| Canonical File | Notes |
|---|---|
| `src/components/dashboard/DashboardPage.tsx` | UnassessedPanel, NeedsAttentionPanel |

---

## 8. Charts & Visualizations

All charts and visualizations are wrapped in a standard card.

**Tailwind classes:**
```
Card:          bg-white rounded-xl border border-gray-200 p-6
Title:         text-lg font-semibold text-gray-900 mb-1
Subtitle:      text-sm text-gray-500 mb-4
Chart area:    (component-specific)
Footer link:   text-sm text-teal-600 hover:text-teal-700 font-medium flex items-center gap-1
               (e.g., "View full analysis →")
```

**Rules:**
- Every chart card has a title and optional subtitle
- If the chart links to a deeper view, include a footer link with arrow
- Side-by-side charts use `grid grid-cols-1 lg:grid-cols-2 gap-6`
- The chart area itself uses component-specific rendering (SVG, canvas, etc.)
- Empty state inside chart cards: centered "No data" text in `text-gray-400`

| Canonical File | Notes |
|---|---|
| `src/components/overview/TimeDistributionPanel.tsx` | Chart card with donut + table |
| `src/components/ui/DonutChart.tsx` | Reusable SVG donut chart |

---

## 9. Form / Edit Pages

Edit pages follow a different layout from dashboards. They are full-width detail views.

**Page structure:**
```
┌─────────────────────────────────────────────┐
│  ← Back   Edit Time Tracker    [Start Asmt] │  ← Header
│           📍 GOS Workspace → Central IT      │  ← Breadcrumb
├─────────────────────────────────────────────┤
│  General · Deployments · Costs · ...         │  ← Tab bar
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │  ABOUT THIS APPLICATION             │    │  ← Section heading
│  │  ─────────────────────────          │    │
│  │  Application Name *                 │    │
│  │  [________________________]         │    │
│  │                                     │    │
│  │  Description         Generate w/ AI │    │
│  │  [________________________]         │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ┌────────────────────┐                     │
│  │       Cancel  Save │                     │  ← Footer
│  └────────────────────┘                     │
└─────────────────────────────────────────────┘
```

**Header:**
```
Back button:    p-2 text-gray-400 hover:text-gray-600 (ArrowLeft icon, w-5 h-5)
Page title:     text-2xl font-semibold text-gray-900
Breadcrumb:     text-sm text-gray-500 with teal links
Action button:  top-right, e.g., "Start Assessment" (amber-outlined or primary)
```

**Form container:**
```
Container:      bg-white rounded-xl shadow-sm border border-gray-200
Form:           p-6 space-y-8
```

**Section heading:**
```
Wrapper:        flex items-center justify-between pb-4 border-b border-gray-100
Heading:        text-lg font-bold text-gray-900 uppercase tracking-wide
```

**Form fields:**
```
Label:          block text-sm font-medium text-gray-700 mb-1.5
Required:       <span className="text-red-500">*</span>
Input:          w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors
Textarea:       same as input + resize-y
Select:         same as input (add bg-white for browser consistency)
Disabled:       disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed
Grid (2-col):   grid grid-cols-1 md:grid-cols-2 gap-6
```

**Footer:**
```
Container:      flex items-center justify-end gap-3 pt-6 border-t border-gray-100
Cancel:         Secondary button
Save:           Primary button (disabled while saving, shows Loader2 spinner)
```

| Canonical File | Notes |
|---|---|
| `src/pages/ApplicationPage.tsx` | Edit page header + tab bar |
| `src/components/ApplicationForm.tsx` | Form sections, fields, footer |

---

## 10. Typography Scale

Use this hierarchy consistently. Never invent new text sizes.

| Role | Tailwind Classes | Example |
|------|-----------------|---------|
| **Page title** | `text-2xl font-semibold text-gray-900` | "GOS Workspace" |
| **Section heading** | `text-lg font-semibold text-gray-900` | "Portfolio Analysis" |
| **Form section heading** | `text-lg font-bold text-gray-900 uppercase tracking-wide` | "ABOUT THIS APPLICATION" |
| **Card title** | `text-lg font-bold text-gray-900` | Cost Summary card title |
| **KPI value (large)** | `text-2xl font-semibold text-gray-900` | "10" |
| **KPI value (compact)** | `text-lg font-semibold text-gray-900` | "$12,400" |
| **Label** | `text-sm font-medium text-gray-700` | Form field labels |
| **Body text** | `text-sm text-gray-600` | Descriptions, paragraphs |
| **Button text** | `text-sm font-medium` | All buttons |
| **KPI label** | `text-sm text-gray-500` | "Applications" |
| **Table header** | `text-xs font-medium text-gray-500 uppercase tracking-wider` | Column headers |
| **Hint / sublabel** | `text-xs text-gray-500` | Helper text below fields |
| **Tertiary / muted** | `text-xs text-gray-400` | KPI sublabels, timestamps |

**Rules:**
- Never use `text-base` for UI text — use `text-sm` (14px) as the standard body size
- Never use `text-lg` or larger for body paragraphs
- Uppercase + tracking-wide is **only** for form section headings and table column headers
- Font weights: `font-medium` for interactive elements, `font-semibold` for headings, `font-bold` for form section headings and card titles

---

## 11. Button Hierarchy

Four button tiers plus icon-only. All buttons use `rounded-lg`.

### Primary (Main CTA)
```
inline-flex items-center gap-2 px-4 py-2
bg-teal-600 text-white text-sm font-medium rounded-lg
hover:bg-teal-700 transition-colors
disabled:opacity-50 disabled:cursor-not-allowed
```
Use for: Create, Save, Submit. One per toolbar row (rightmost).

### Secondary (Supporting actions)
```
inline-flex items-center gap-2 px-4 py-2
bg-white text-gray-700 text-sm font-medium rounded-lg
border border-gray-300 hover:bg-gray-50 transition-colors
disabled:opacity-50 disabled:cursor-not-allowed
```
Use for: Cancel, Export CSV, secondary actions.

### Destructive
```
inline-flex items-center gap-2 px-4 py-2
bg-red-600 text-white text-sm font-medium rounded-lg
hover:bg-red-700 transition-colors
```
Use for: Delete, Remove. Always require confirmation.

### Ghost (Text-only)
```
inline-flex items-center gap-1 px-3 py-1.5
text-sm font-medium text-teal-600 hover:text-teal-700 hover:bg-teal-50 rounded-lg transition-colors
```
Use for: "Show all", "View full analysis", inline links that look like buttons.

### Icon-Only
```
p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded transition-colors
```
Icon size: `w-4 h-4`
Use for: Row actions (edit, delete), filter toggles, close buttons.

**Rules:**
- Only **one primary button** per toolbar row
- Export buttons are always secondary
- Destructive buttons never appear in the toolbar — only in modals/confirmations or inline row actions
- Loading state: replace label with `<Loader2 className="w-4 h-4 animate-spin" />` + "Saving..." text, disable button

---

## 12. Icons

**Mandatory:** All icons must come from `src/constants/icons.ts`. Never import Lucide icons directly in components.

### Available registries

| Registry | Import | Purpose |
|----------|--------|---------|
| `ENTITY_STYLES` | `getEntityStyle('application')` | Entity icons + colors (app, DP, vendor, etc.) |
| `ACTION_ICONS` | `ACTION_ICONS.add` | UI actions (add, edit, delete, search, filter, sort) |
| `NAV_ICONS` | `NAV_ICONS.workspaces` | Navigation/sidebar icons |
| `INTEGRATION_TYPE_ICONS` | `getIntegrationIcon('api')` | Integration method icons |
| `DIRECTION_ICONS` | `DIRECTION_ICONS.downstream` | Data flow direction |

### Sizing rules

| Context | Size | Example |
|---------|------|---------|
| Inline with button text | `w-4 h-4` | Plus icon in "Create Initiative" |
| Table cell actions | `w-4 h-4` | Edit, delete row actions |
| KPI cards / dashboard | `w-5 h-5` | Icon inside colored pill |
| Page-level indicators | `w-6 h-6` | Error boundary, empty states |
| Small UI accents | `w-3 h-3` | "Add Contact" inline link |

**Rules:**
- If you need an icon not in `icons.ts`, add it there first — never import Lucide directly
- Entity icons always use their paired colors from `ENTITY_STYLES`
- Action icons use `text-gray-400` default, `text-gray-600` on hover
- Never mix icon libraries — Lucide React only

| Canonical File | Notes |
|---|---|
| `src/constants/icons.ts` | Single source of truth for all icons |

---

## 13. Color System

### Brand / Primary
| Token | Tailwind | Usage |
|-------|----------|-------|
| Primary | `teal-600` | Buttons, active tabs, focus rings, pagination active |
| Primary hover | `teal-700` | Button hover states |
| Primary light | `teal-50` | Active filter backgrounds, ghost button hover |

### Status / Semantic
| Status | Background | Text | Border | Usage |
|--------|-----------|------|--------|-------|
| Success | `bg-green-50` | `text-green-800` | `border-green-200` | Completion, active |
| Warning | `bg-amber-50` | `text-amber-800` | `border-amber-200` | Needs attention, in-progress |
| Error | `bg-red-50` | `text-red-800` | `border-red-200` | At risk, failed, destructive |
| Info | `bg-blue-50` | `text-blue-800` | `border-blue-200` | Informational banners |

### Neutral / Gray Scale
| Role | Class | Usage |
|------|-------|-------|
| Primary text | `text-gray-900` | Headings, values, strong labels |
| Secondary text | `text-gray-700` | Form labels, descriptions |
| Body text | `text-gray-600` | Paragraph text |
| Muted text | `text-gray-500` | KPI labels, hints, secondary info |
| Tertiary text | `text-gray-400` | Sublabels, timestamps, disabled icons |
| Card background | `bg-white` | Cards, modals, panels |
| Section background | `bg-gray-50` | Page background, table pagination, sticky headers |
| Card border | `border-gray-100` | Light card borders (KPI cards, panels) |
| Input border | `border-gray-300` | Form inputs, secondary buttons |
| Divider | `border-gray-200` | Section dividers, table borders, tab underlines |

### Entity Colors
Always use `ENTITY_STYLES` from `src/constants/icons.ts`. Entity colors are defined there and should never be hardcoded in components.

### Lifecycle Colors
Use `LIFECYCLE_COLORS` from `src/lib/colors.ts` for technology lifecycle status indicators.

---

## 14. Spacing & Grid

### Vertical Rhythm
| Context | Class | Pixels |
|---------|-------|--------|
| Between major sections | `space-y-6` | 24px |
| Between related items | `space-y-4` | 16px |
| Between tight items | `space-y-2` | 8px |
| Form field internal | `mb-1.5` | 6px (label to input) |
| Padding inside cards | `p-5` (Variant A) / `p-3` (Variant B) | 20px / 12px |
| Padding inside forms | `p-6` | 24px |

### Grid Gaps
| Context | Class |
|---------|-------|
| KPI cards | `gap-4` |
| Compact KPI cards | `gap-3` |
| Form columns | `gap-6` |
| Side-by-side panels | `gap-6` |

### Container Width
| Context | Class |
|---------|-------|
| Standard page content | `max-w-7xl mx-auto` |
| Wide tables | `max-w-[95vw] mx-auto` |
| Modal sm | `max-w-sm` |
| Modal md | `max-w-md` |
| Modal lg | `max-w-lg` |
| Modal xl | `max-w-xl` |

### Responsive Grid Patterns
| Content | Grid Classes |
|---------|-------------|
| KPI cards (5) | `grid-cols-1 md:grid-cols-2 lg:grid-cols-5` |
| KPI cards (6) | `grid-cols-1 md:grid-cols-2 lg:grid-cols-6` |
| Compact KPI (4) | `grid-cols-2 md:grid-cols-4` |
| Side-by-side panels | `grid-cols-1 lg:grid-cols-2` |
| Form fields (2-col) | `grid-cols-1 md:grid-cols-2` |
| Technology categories | `grid-cols-1 md:grid-cols-3` |

---

## 15. Empty & Loading States

### Empty State

Used when a section has no data to display.

```
┌─────────────────────────────────────┐
│                                     │
│           📋                        │  ← Icon (w-6 h-6, text-gray-300)
│                                     │
│      No Initiatives                 │  ← Title
│  Strategic initiatives will appear  │  ← Description
│  here once they are created from    │
│  findings or ideas.                 │
│                                     │
│       [+ Create Initiative]         │  ← Optional CTA
│                                     │
└─────────────────────────────────────┘
```

**Tailwind classes:**
```
Container:    flex flex-col items-center justify-center py-12 text-center
Icon:         w-8 h-8 text-gray-300 mb-3
Title:        text-lg font-semibold text-gray-900 mb-1
Description:  text-sm text-gray-500 max-w-md
CTA button:   mt-4 (use primary button style)
```

**Rules:**
- Always provide a title and description
- Include a CTA button when the user can create the missing content
- Icon should relate to the entity type (use `ENTITY_STYLES` icon with gray-300 color)
- Empty state sits inside the card/container that would hold the data

### Loading State — Skeleton

Match the shape and dimensions of the real content using pulse placeholders.

**Tailwind classes:**
```
Skeleton card: same dimensions as real card + animate-pulse
Skeleton bar:  h-{n} w-{n} bg-gray-200 rounded
```

**Rules:**
- Skeletons must match the layout of the real content (same grid, same card dimensions)
- Use `bg-gray-200 rounded` for skeleton bars, `bg-gray-100 rounded-lg` for larger blocks
- Always animate with `animate-pulse`
- Show the correct number of skeleton items (e.g., 5 KPI card skeletons if there are 5 cards)

### Render Path Consistency Rule

Most components have **three render paths**: loading, empty, and data-present. When updating typography, padding, or card styles, **all three paths must be updated together**.

```
// ❌ Common mistake — only updating one render path
if (loading) return <div className="p-6">...</div>       // ← updated
if (data.length === 0) return <div className="p-6">...</div>  // ← updated
return <div className="p-5">...</div>                     // ← MISSED — still old style

// ✅ Correct — all paths use the same card + title pattern
if (loading) return <div className="bg-white rounded-xl border border-gray-200 p-6 animate-pulse">...
if (data.length === 0) return <div className="bg-white rounded-xl border border-gray-200 p-6">
  <h3 className="text-lg font-semibold text-gray-900 mb-1">...
return <div className="bg-white rounded-xl border border-gray-200 p-6">
  <h3 className="text-lg font-semibold text-gray-900 mb-1">...
```

**Checklist when modifying a component's styling:**
1. Search the file for every `return` statement
2. Verify the card wrapper classes match across all paths
3. Verify title/subtitle classes match across all paths

### Loading State — Spinner

For inline loading (buttons, small areas).

```
<Loader2 className="w-4 h-4 animate-spin" />
```

Use `ACTION_ICONS` — never import Loader2 directly. (Add to `icons.ts` if not present.)

---

## 16. Responsive Behavior

### Breakpoint Strategy

| Breakpoint | Tailwind Prefix | Usage |
|-----------|-----------------|-------|
| Mobile | (default) | Single column, stacked layout |
| Tablet | `md:` (768px) | 2-column grids, side-by-side panels |
| Desktop | `lg:` (1024px) | Full multi-column layouts, wide tables |

**Rules:**
- Mobile-first: write mobile styles as defaults, add `md:` and `lg:` for wider screens
- KPI cards collapse to `grid-cols-1` on mobile, `grid-cols-2` on tablet
- Side-by-side panels stack vertically below `lg:`
- Tables get `overflow-x-auto` for horizontal scrolling on small screens
- Form fields stack to single column below `md:`
- Modal max-widths automatically constrain on small screens (`max-w-lg` etc.)

---

## Quick Reference: Common Patterns

### Dashboard Page Skeleton
```tsx
// Sticky block: Banner + Sub-tabs (if applicable) + Toolbar
<div className="sticky top-[77px] z-30 bg-gray-50 -mx-6 px-6">
  {/* 1. Banner */}
  <div className="pt-4 pb-2">
    <WorkspaceBanner />
  </div>

  {/* 2. Sub-tabs (if applicable) */}
  <div className="flex items-center gap-0 border-b border-gray-200">
    {tabs.map(tab => (
      <button className={`px-4 py-2 text-sm font-medium border-b-2 ${
        active ? 'border-teal-600 text-teal-700' : 'border-transparent text-gray-500'
      }`}>{tab.label}</button>
    ))}
  </div>

  {/* 3. Toolbar Row */}
  <div className="flex items-center justify-between gap-4 py-3">
    <div className="flex items-center gap-2">
      {/* Search / filter icons */}
    </div>
    <div className="flex items-center gap-3">
      {/* Export + Create + Filters (rightmost) */}
    </div>
  </div>
</div>

// 4. Content Area
<div className="pt-6 pb-8">
  {/* KPI cards, tables, charts */}
</div>
```

### Modal Skeleton
```tsx
<ModalShell isOpen={open} onClose={onClose} title="Create X" maxWidth="lg">
  <form className="px-6 py-4 space-y-5">
    {/* Fields */}
  </form>
  <ModalFooter onCancel={onClose} onSubmit={handleSave} saving={saving} />
</ModalShell>
```

---

## Appendix: What This Document Does NOT Cover

- **Database schema rules** → see `CLAUDE.md`
- **Supabase query patterns** → see `CLAUDE.md`
- **RLS / security policies** → see `identity-security/rls-policy-addendum.md`
- **Component file organization** → see `CLAUDE.md` (Open Items — UI Refactoring Backlog)
- **Modal migration** → see `CLAUDE.md` (ModalShell + ModalFooter backlog item)

---

*Last updated: 2026-03-03*
*Update this file when new UI patterns are introduced or existing rules change.*
