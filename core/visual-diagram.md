# GetInSync NextGen — Visual Diagram Architecture

**Version:** 2.4
**Date:** April 5, 2026
**Status:** ✅ SHIPPED

---

## Overview

The Visual tab on the Application Detail page renders an interactive graph using **React Flow** (@xyflow/react) with **dagre** (@dagrejs/dagre) for automatic layout. Users navigate three drill-down levels via click interactions (single-click for apps, double-click for DPs). Breadcrumb navigation provides level context and backtracking.

### Technology Stack

| Library | Purpose |
|---------|---------|
| `@xyflow/react` | Graph rendering, pan/zoom, node dragging |
| `@dagrejs/dagre` | Automatic directed-graph layout (LR or TB) |
| Custom nodes | `AppNode`, `DPNode`, `TierLabelNode`, `LegendNode` |

### Key Files

| File | Purpose |
|------|---------|
| `src/components/integrations/ConnectionsVisual.tsx` | Main component — ReactFlow canvas, breadcrumbs, layout persistence, navigation |
| `src/components/visual/graphBuilders.ts` | Layout + node/edge construction for all three levels (manual 3-tier for L1, dagre for L2/L3) |
| `src/components/visual/nodes/AppNode.tsx` | Custom node for applications and external systems |
| `src/components/visual/nodes/DPNode.tsx` | Custom node for deployment profiles |
| `src/components/visual/nodes/TierLabelNode.tsx` | Non-interactive tier label with dashed rule |
| `src/components/visual/nodes/LegendNode.tsx` | Non-interactive legend (level-aware) |
| `src/hooks/useVisualGraphData.ts` | Data fetching hook — all Supabase queries |

---

## Three-Level Drill-Down

```
Level 1: App Graph (TB)         Level 2: DP Overview (TB)       Level 3: Blast Radius (LR)
─────────────────────          ──────────────────              ─────────────────────
  Connected App 1                [FOCUSED APP]                  Connected Apps ──┐
  Connected App 2                     |                         External Systems─┤
  External System 1              ├── DP 1                                        ├──[SELECTED DP]
       |                         ├── DP 2                       Connected Apps ──┤
  [FOCUSED APP]                  └── DP 3                       External Systems─┘
       |
  DP 1   DP 2   DP 3

Layout: TB (top-bottom)        Layout: TB (top-bottom)         Layout: LR (left-right)
```

### Level 1 — App Graph (Three-Tier Vertical)

**Top tier:** Connected apps + external systems (from integrations)
**Center tier:** Focused application
**Bottom tier:** Deployment profiles for the focused app
**Layout direction:** Top-to-bottom (TB)

Manual three-tier positioning (not dagre — dagre merges ranks in this topology). Nodes are centered horizontally per tier with 140px vertical gap. Integration edges use `sourceHandle: 'bottom'` → `targetHandle: 'top'` for clean vertical routing; DP edges use `sourceHandle: 'bottom'` on the focused app.

- Integration edges from `vw_integration_detail`
- Edge color: amber (#BA7517) for all data flow edges
- Edge style: dashed for deprecated/retired integrations
- Edge labels show integration_type (11px)
- App-to-DP edges: dashed gray (#94a3b8), 1px, no arrowhead (structural)
- Tier labels: "Connected applications" and "Focused application" above their respective tiers
- MiniMap shown on Level 1 only

**Click actions:**
- Click focused app → drill to Level 2
- Click connected app → navigate to that app's page
- Click external system → no action
- Single-click DP → select only (React Flow default)
- Double-click DP → drill to Level 3 (blast radius for that DP)

### Level 2 — Deployment Profiles

**Top:** Focused application (single node)
**Below:** All deployment profiles for this application
**Layout direction:** Top-to-bottom (TB)

- Includes connected apps/externals with integration edges (amber #BA7517)
- Excludes `dp_type = 'cost_bundle'` profiles
- Dashed structural edges connect app to each DP
- DPs ordered: is_primary DESC, then name ASC
- Each DP node shows enriched view: tech health bar, integration count amber pill, "1°" badge
- Tier labels: "Connected applications", "Focused application", "Deployment profiles"

**Click actions:**
- Click app node → back to Level 1
- Single-click DP → select only
- Double-click DP → drill to Level 3 for that DP

### Level 3 — Blast Radius

**Center:** Selected deployment profile
**Surrounding:** Connected apps + external systems filtered to integrations scoped to this DP
**Layout direction:** Left-to-right (LR)

Shows the "blast radius" — what other systems are affected if this specific DP goes down. Only integrations where `source_deployment_profile_id` or `target_deployment_profile_id` matches the selected DP are shown (not all app-level integrations).

- Subtitle: "Showing N integrations for this deployment only"
- DP rendered as hero card with integration summary (sends/receives/bidirectional counts)
- Directional edge coloring: outbound amber (#BA7517), inbound blue (#185FA5), bidirectional amber with arrows both ends

**Click actions:**
- Click connected app → navigate to that app's page

---

## Custom Node Types

### AppNode (`src/components/visual/nodes/AppNode.tsx`)

Renders applications and external systems with ArchiMate-informed shape semantics.

**Shape semantics (corner radius):**
- Internal applications: `border-radius: 8px` (rounded — application layer)
- External systems: `border-radius: 2px` with dashed 1.5px border (outside boundary)
- No icon for external systems — the dashed border is the sole differentiator
- Internal applications show `Monitor` icon (lucide-react)

**TIME quadrant coloring:** Uses authoritative hex colors from `scoring.ts`:
- Focused app: 2px solid border in TIME color, light wash background, scale-110
- Connected apps with TIME: 1px border in TIME color, light wash background
- Tolerate text override: #9da3af
- Crown jewel star icon when criticality >= 50
- Shows workspace name below app name

**Hover tooltip:** Non-focused app nodes show a tooltip on hover with app name, workspace name, TIME quadrant, and criticality score.

**Handles:** All four sides (Left, Right, Top, Bottom) for flexible edge routing.

### DPNode (`src/components/visual/nodes/DPNode.tsx`)

Renders deployment profiles with ArchiMate-informed shape (nearly square, `border-radius: 3px`).

**Left-edge environment bar (4px wide, full height):**
- PROD: teal/green (#10b981)
- TEST: amber (#f59e0b)
- DEV: blue (#3b82f6)
- DR/default: gray (#6b7280)

**Icons (by hosting_type):**
- `SaaS` → `Cloud`
- `Hybrid` → `GitMerge`
- Default/On-Prem → `Server`

**Level-aware rendering (via `viewLevel` in node data):**
- **Level 1 (compact):** Name, "1°" teal badge, environment · hosting, server name, tech health %
- **Level 2 (enriched):** Min-width 240px, tech health progress bar (8px, colored fill), integration count amber pill
- **Level 3 (hero card):** Min-width 300px, crown jewel star, server_name, tech health bar, divider, integration summary (sends/receives/bidirectional)

**ServiceNode technology count pill:**
- IT Service nodes (ServiceNode) display a teal pill with a `Cpu` icon showing the count of technology products that compose the service
- Data source: count of rows in `it_service_technology_products` for the service, fetched in `useVisualGraphData.ts`
- Only shown when count > 0

**Hover hint:** Shows "Double-click to explore" text below the node on hover (L1/L2).

**Handles:** All four sides.

### TierLabelNode (`src/components/visual/nodes/TierLabelNode.tsx`)

Non-interactive layout element that labels horizontal tiers. Implemented as a React Flow node (survives zoom/pan/export).

- `draggable: false, selectable: false, focusable: false`
- 11px uppercase text (#6b7280) with dashed horizontal rule (0.5px dashed #d1d5db)
- L1: "Connected applications", "Focused application"
- L2: "Connected applications", "Focused application", "Deployment profiles"
- L3: none

### LegendNode (`src/components/visual/nodes/LegendNode.tsx`)

Compact horizontal legend rendered as a non-interactive React Flow node at the bottom of the canvas.

- L1/L2: External dashed rect, internal solid rect, dashed gray line "Structural", solid amber arrow "Data flow"
- L3: Amber arrow "Sends data", blue arrow "Receives data"

---

## Edge Styling

All edges use `type: 'smoothstep'` with `pathOptions: { borderRadius: 0 }` for orthogonal right-angle routing.

**Two visually distinct edge types:**

| Edge Type | Color | Style | Marker | Label |
|-----------|-------|-------|--------|-------|
| Data flow (L1/L2) | #BA7517 amber | solid, 1.5px | ArrowClosed | integration_type (11px) |
| Data flow (deprecated) | #BA7517 amber | dashed (6 3), 1.5px | ArrowClosed | integration_type |
| Structural (app→DP) | #94a3b8 gray | dashed (6 4), 1px | none | none |
| L3 outbound (sends) | #BA7517 amber | solid, 1.5px | ArrowClosed (away) | integration_type |
| L3 inbound (receives) | #185FA5 blue | solid, 1.5px | ArrowClosed (toward DP) | integration_type |
| L3 bidirectional | #BA7517 amber | solid, 1.5px | ArrowClosed (both ends) | integration_type |

**Edge tooltips:** Hovering over an integration edge shows a tooltip with integration name, type, frequency, and data classification.

---

## Layout Persistence

User-arranged node positions persist in `applications.visual_layout` (JSONB column).

### Schema

```sql
-- Column on applications table
visual_layout jsonb DEFAULT NULL
```

### Data Structure

```typescript
interface SavedLayout {
  level1?: SavedLevelLayout;
  level2?: SavedLevelLayout;
  level3?: SavedLevelLayout;
}

interface SavedLevelLayout {
  nodes: { id: string; position: { x: number; y: number } }[];
  viewport: { x: number; y: number; zoom: number };
}
```

Each level's layout is saved independently. When a user drags nodes or pans/zooms, positions are saved to the appropriate level key.

### Save Triggers

- **Node drag stop:** Immediate save of all node positions + viewport
- **Viewport move end:** Debounced save (500ms) of positions + viewport

### Load Behavior

1. Dagre computes default layout
2. If `visual_layout[levelKey]` exists with saved node positions, override matching node positions
3. Non-matching nodes (new integrations added since last save) keep dagre positions

### Reset Layout

Breadcrumb bar includes a "Reset Layout" button (right-aligned). Clicking it:
1. Deletes the current level's key from `visual_layout`
2. Saves the updated layout to DB
3. Re-fetches data, triggering dagre to recompute positions

---

## Data Queries (`useVisualGraphData`)

### Focused Application
```sql
SELECT id, name, visual_layout, workspaces.name
FROM applications
WHERE id = :applicationId
```

### Integrations
```sql
SELECT * FROM vw_integration_detail
WHERE source_application_id = :applicationId
   OR target_application_id = :applicationId
```

### Deployment Profiles
```sql
SELECT id, name, application_id, environment, hosting_type,
       server_name, is_primary, tech_health, dp_type
FROM deployment_profiles
WHERE application_id = :applicationId
  AND dp_type != 'cost_bundle'
ORDER BY is_primary DESC, name
```

### Connected Apps (parallel queries)
```sql
-- App info
SELECT id, name, workspaces.name FROM applications WHERE id IN (:connectedIds)

-- TIME quadrant + criticality
SELECT application_id, time_quadrant, criticality
FROM portfolio_assignments WHERE application_id IN (:connectedIds)
```

### Focused App TIME Data
```sql
SELECT time_quadrant, criticality
FROM portfolio_assignments
WHERE application_id = :applicationId
LIMIT 1
```

---

## Zoom Configuration

| Property | Value |
|----------|-------|
| fitView padding | 0.4 |
| minZoom | 0.2 |
| maxZoom | 2 |
| fitView minZoom | 0.4 |
| fitView maxZoom | 1.2 |
| defaultViewport | { x: 0, y: 0, zoom: 0.75 } |
| Level transition animation | 300ms duration |

---

## Navigation: Breadcrumbs

Breadcrumb bar at top of canvas:

```
Level 1: All Apps
Level 2: All Apps > [App Name]
Level 3: All Apps > [App Name] > [DP Name]
```

Each segment is clickable to navigate back. "Reset Layout" button is right-aligned in the breadcrumb bar.

---

## Empty States

| Condition | Message |
|-----------|---------|
| No integrations AND no DPs (Level 1) | "No integrations recorded — Add connections in the Integrations tab." |
| No DPs (Level 2) | "No deployment profiles found" + back link |
| Loading | "Loading visualization..." |
| Error | Error message + Retry button |

---

## ArchiMate-Informed Design Language

The visual vocabulary borrows from ArchiMate conventions to be recognizable to enterprise architects while remaining readable for non-technical users.

**Shape semantics (corner radius):**
- Applications: rounded (8px) — ArchiMate application layer
- External systems: nearly square (2px) + dashed border — ArchiMate external entity convention
- Deployment profiles: nearly square (3px) — ArchiMate technology layer

**Environment signaling:** DP nodes use a 4px left-edge color bar for instant environment recognition (PROD=teal, TEST=amber, DEV=blue, DR/default=gray).

**Edge differentiation:**
- Data flow (integration): solid amber with directional arrowhead
- Structural (composition): dashed gray with no arrowhead
- Level 3 adds directional coloring: outbound=amber, inbound=blue, bidirectional=amber with dual arrows

**Tier labels:** Non-interactive React Flow nodes labeling each horizontal tier. Survive zoom/pan/screenshots/export.

**Legend:** Compact horizontal React Flow node at canvas bottom showing edge and node type key, adapting to the current level.

Design source: ArchiMate-informed visual polish prompt (April 2026).

---

## Future Enhancements (Not Yet Built)

- **Level 2 tech stack nodes:** Software products, IT services, hosting, cloud provider, DR status as nodes under each DP
- **Level 3 service/product visual:** Blast radius centered on a service or product (all DPs using it)
- **Inter-DP edges:** Show relationships between DPs (requires `inherits_tech_from` or similar)
- **Export:** PNG/SVG export of current view
