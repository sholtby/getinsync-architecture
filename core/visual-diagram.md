# GetInSync NextGen — Visual Diagram Architecture

**Version:** 2.1
**Date:** March 19, 2026
**Status:** ✅ IMPLEMENTED

---

## Overview

The Visual tab on the Application Detail page renders an interactive graph using **React Flow** (@xyflow/react) with **dagre** (@dagrejs/dagre) for automatic layout. Users navigate three drill-down levels via click interactions (single-click for apps, double-click for DPs). Breadcrumb navigation provides level context and backtracking.

### Technology Stack

| Library | Purpose |
|---------|---------|
| `@xyflow/react` | Graph rendering, pan/zoom, node dragging |
| `@dagrejs/dagre` | Automatic directed-graph layout (LR or TB) |
| Custom nodes | `AppNode` (apps/externals), `DPNode` (deployment profiles) |

### Key Files

| File | Purpose |
|------|---------|
| `src/components/integrations/ConnectionsVisual.tsx` | Main component — ReactFlow canvas, breadcrumbs, layout persistence, navigation |
| `src/components/visual/graphBuilders.ts` | Dagre layout + node/edge construction for all three levels |
| `src/components/visual/nodes/AppNode.tsx` | Custom node for applications and external systems |
| `src/components/visual/nodes/DPNode.tsx` | Custom node for deployment profiles |
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

Dagre enforces three-tier separation: integration edges flow from connected apps (top) into the focused app (center), and dashed edges flow from the focused app down to DP nodes (bottom).

- Integration edges from `vw_integration_detail`
- Edge color indicates criticality: critical (#ef4444), important (#f59e0b), nice_to_have (#94a3b8)
- Edge style: dashed for deprecated/retired integrations
- Edge labels show integration_type
- App-to-DP edges: dashed gray (#94a3b8), 1px
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

- Excludes `dp_type = 'cost_bundle'` profiles
- Dashed edges connect app to each DP
- DPs ordered: is_primary DESC, then name ASC

**Click actions:**
- Click app node → back to Level 1
- Single-click DP → select only
- Double-click DP → drill to Level 3 for that DP

### Level 3 — Blast Radius

**Center:** Selected deployment profile
**Surrounding:** All connected apps + external systems (same integration data as Level 1)
**Layout direction:** Left-to-right (LR)

Shows the "blast radius" — what other systems are affected if this DP goes down.

**Click actions:**
- Click connected app → navigate to that app's page

---

## Custom Node Types

### AppNode (`src/components/visual/nodes/AppNode.tsx`)

Renders applications and external systems with consistent styling.

**Icons (locked per type):**
- Applications: `Monitor` (lucide-react)
- External systems: `Globe` (lucide-react)

**Visual indicators:**
- TIME quadrant color stripe on left border: Invest (#10b981), Modernize (#f59e0b), Tolerate (#6b7280), Eliminate (#ef4444)
- Crown jewel star icon when criticality >= 50
- Focused app has teal border; others have gray
- Shows workspace name below app name

**Hover tooltip:** Non-focused app nodes show a tooltip on hover with app name, workspace name, TIME quadrant, and criticality score. Tooltip is an absolutely-positioned div inside the node component (not a portal).

**Handles:** All four sides (Left, Right, Top, Bottom) for flexible edge routing.

### DPNode (`src/components/visual/nodes/DPNode.tsx`)

Renders deployment profiles with hosting-aware icons.

**Icons (by hosting_type):**
- `SaaS` → `Cloud`
- `Hybrid` → `GitMerge`
- Default/On-Prem → `Server`

**Visual indicators:**
- PRIMARY badge (indigo) for is_primary DPs
- Environment color dot (from `getEnvironmentColor()`)
- Hosting type badge
- Server name (truncated)
- Tech health percentage with color coding (green >=70, amber >=40, red <40)

**Hover hint:** Shows "Double-click to explore" text below the node on hover.

**Handles:** All four sides.

---

## Edge Styling

All edges use `type: 'smoothstep'` with `pathOptions: { borderRadius: 0 }` for orthogonal right-angle routing.

| Edge Type | Color | Style | Marker |
|-----------|-------|-------|--------|
| Integration (critical) | #ef4444 | solid, 2px | ArrowClosed |
| Integration (important) | #f59e0b | solid, 2px | ArrowClosed |
| Integration (nice_to_have) | #94a3b8 | solid, 2px | ArrowClosed |
| Integration (deprecated/retired) | per criticality | dashed (6 3) | ArrowClosed |
| App-to-DP (Level 2) | #94a3b8 | dashed (6 3), 1px | none |
| DP-to-App (Level 3) | per criticality | solid/dashed, 2px | ArrowClosed |

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

## Future Enhancements (Not Yet Built)

- **Level 2 tech stack nodes:** Software products, IT services, hosting, cloud provider, DR status as nodes under each DP
- **Level 3 service/product visual:** Blast radius centered on a service or product (all DPs using it)
- **Inter-DP edges:** Show relationships between DPs (requires `inherits_tech_from` or similar)
- **Legend bar:** Visual legend for edge colors, node types, TIME quadrant colors
- **Export:** PNG/SVG export of current view
