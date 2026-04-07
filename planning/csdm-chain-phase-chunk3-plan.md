# Chunk 3: Visual Tab Level 4 — IT Service Drill-Down

## Context

The Visual tab currently supports 3 drill-down levels (App → DPs → DP detail with IT Services). Chunk 3 adds Level 4: double-click an IT Service on Level 3 to see its technology products. This completes the CSDM chain visualization from Application → Deployment Profile → IT Service → Technology Product.

Also removes: tech count pills from ServiceNode (replaced by drill-down), Technology Lifecycle section from ITServiceModal (lifecycle will be derived from component tech products per Chunk 4).

---

## Files to Modify

| File | Change |
|------|--------|
| `src/hooks/useVisualGraphData.ts` | Add tech product detail + DP tech link fetching |
| `src/components/visual/nodes/TechProductNode.tsx` | **NEW** — teal tech product node |
| `src/components/visual/graphBuilders.ts` | Add `buildLevel4()` |
| `src/components/integrations/ConnectionsVisual.tsx` | ViewLevel L4, NODE_TYPES, handlers, breadcrumb |
| `src/components/visual/nodes/ServiceNode.tsx` | Remove tech count pill |
| `src/components/visual/nodes/LegendNode.tsx` | Add Level 4 legend |
| `src/components/ITServiceModal.tsx` | Remove Technology Lifecycle section (L517–850) |

---

## Step 1: Data Layer — `useVisualGraphData.ts`

**Add interfaces** (after `ITServiceInfo`):

```typescript
export interface ITServiceTechDetail {
  it_service_id: string;
  tech_product_id: string;
  tech_product_name: string;
  version: string | null;
  lifecycle_status: string | null;   // from technology_lifecycle_reference.current_status
  eos_date: string | null;           // from technology_lifecycle_reference.end_of_life_date
  category_name: string | null;      // from technology_product_categories.name
}

export interface DPTechLink {
  deployment_profile_id: string;
  technology_product_id: string;
  deployed_version: string | null;
}
```

**Add to `VisualGraphData`**: `itServiceTechDetails: ITServiceTechDetail[]` and `dpTechLinks: DPTechLink[]`.

**New queries** (inside existing `if (svcIds.size > 0)` block, after tech count map, ~line 129):

1. `it_service_technology_products` with join: `it_service_id, technology_product:technology_products(id, name, version, category:technology_product_categories(name), lifecycle_reference:technology_lifecycle_reference(current_status, end_of_life_date))` filtered by `.in('it_service_id', svcIds)`
2. `deployment_profile_technology_products` selecting `deployment_profile_id, technology_product_id, deployed_version` filtered by `.in('deployment_profile_id', dpIds)`

Run both with `Promise.all`. Map results into the two new arrays. Pass through to `setData`.

---

## Step 2: New `TechProductNode.tsx`

**File:** `src/components/visual/nodes/TechProductNode.tsx` (new)

- **Interface:** `TechProductNodeData` — `label`, `version`, `lifecycleStatus`, `categoryName`, `usedByDp`, `deployedVersion`, `[key: string]: unknown`
- **Color:** Left border `#14b8a6`, bg `#f0fdfa`, border `#ccfbf1`
- **Dimmed:** When `!usedByDp`, apply `opacity: 0.5`
- **Layout:** Row 1: `Cpu` icon + name. Row 2: version + `LifecycleBadge` (from `../../technology-health/LifecycleBadge`). Row 3: deployed version/server info or "Not used by this deployment"
- **Handle:** Single `target` at `Position.Top`
- **Size:** minWidth 180, maxWidth 220
- Pattern: follow `ServiceNode.tsx` conventions (inline styles, memo wrapper)

---

## Step 3: `buildLevel4()` — `graphBuilders.ts`

**Constants:** `NODE_WIDTH_TECH = 220`, `NODE_HEIGHT_TECH = 80`

**Update `getNodeDimensions`** to handle `type === 'techProduct'`.

**Function signature:**
```typescript
export function buildLevel4(
  selectedService: ITServiceInfo,
  selectedDp: DPInfo,
  techDetails: ITServiceTechDetail[],
  dpTechLinks: DPTechLink[],
): { nodes: Node[]; edges: VisualEdge[] }
```

**Logic:**
1. Build `Set<string>` of tech product IDs used by selectedDp from dpTechLinks
2. Build `Map<string, string | null>` of deployed versions from dpTechLinks
3. Filter techDetails to `it_service_id === selectedService.id`
4. Create service hero node (type `'service'`, positioned top-center)
5. Create tech product nodes (type `'techProduct'`) with `usedByDp`, `deployedVersion` from maps
6. Dashed structural edges: service → each tech product (via `makeStructuralEdge` + `TB_HANDLES`)
7. "BUILT ON" tier label via `makeTierLabel`
8. Legend via `makeLegendNode(allContentNodes, 4)`
9. Position: service hero centered above; tech products in horizontal row below with 20px gap

---

## Step 4: Wire Up — `ConnectionsVisual.tsx`

**4a. ViewLevel** (line 60): Add `| { level: 4; dpId: string; dpName: string; serviceId: string; serviceName: string }`

**4b. Imports**: Add `TechProductNode`, `buildLevel4`

**4c. NODE_TYPES** (line 32): Add `techProduct: TechProductNode`

**4d. levelKey** (lines 80-82): Add Level 4 case → `` `level4:${viewLevel.serviceId}` ``

**4e. Graph build switch** (lines 119-127): Change final `else` to `else if (viewLevel.level === 3)`, add new `else` for Level 4:
- Look up service from `data.itServices` by `viewLevel.serviceId`
- Look up DP from `data.deploymentProfiles` by `viewLevel.dpId`
- Call `buildLevel4(svc, dp, data.itServiceTechDetails, data.dpTechLinks)`

**4f. onNodeDoubleClick** (lines 173-180): Add `service` node type handling when `viewLevel.level === 3`:
- Strip `svc-` prefix from `node.id` to get raw service ID
- Set `{ level: 4, dpId: viewLevel.dpId, dpName: viewLevel.dpName, serviceId, serviceName: node.data.label }`

**4g. onNodeClick**: Add Level 4 block — clicking service hero returns to Level 3

**4h. Breadcrumb** (lines 234-242): Level 4 shows: App name (→ L2) > DP name (→ L3) > Service name (current)

---

## Step 5: Remove Tech Count Pill — `ServiceNode.tsx`

- Remove `Cpu` from lucide-react import (line 3)
- Remove `const techCount` destructuring (line 18)
- Remove pill JSX block (lines 44-48)
- Keep `techCount?` in `ServiceNodeData` interface (optional, backward compat)
- **Add** "Double-click to explore" hover tooltip (follow DPNode pattern at DPNode.tsx:176-179)

---

## Step 6: Remove Technology Lifecycle — `ITServiceModal.tsx`

- Remove JSX block lines 517–850 (entire Technology Lifecycle collapsible section)
- Remove state: `lifecycleExpanded`, `lifecycleMode`, `linkedLifecycle`, `aiLookupLoading`, `aiLookupResult`, `aiLookupError`, `lifecycleSearchQuery`, `lifecycleSearchResults`, `newLifecycleEntry`
- Remove handlers: `handleVerifyLifecycle`, `handleUnlinkLifecycle`, `handleLinkLifecycle`, `handleAiLookup`, `handleCreateLifecycle`
- Remove `useEffect` blocks for lifecycle search/fetch
- Clean imports: remove `Sparkles`, `Link2`, `Unlink`, `CheckCircle`, `LifecycleBadge` if unused
- **Keep** `lifecycle_reference_id` in form data and save logic

---

## Step 7: Level 4 Legend — `LegendNode.tsx`

Add `isL4 = d.viewLevel === 4` check. New legend items:
1. Teal tech product box (left border `#14b8a6`, bg `#f0fdfa`) + label "Tech product"
2. Lifecycle dots: green `#17B41D` (Mainstream), amber `#FBDD3F` (Extended), red `#D74550` (End of Support)
3. Dashed structural line = "Composition" (reuse existing `LineSample`)

---

## Execution Order

```
Step 1 (data) → Step 2 (node) → Step 3 (builder) → Step 4 (wiring)
                 Steps 5, 6, 7 (independent — can be done any time)
```

---

## Verification

1. `npx tsc --noEmit` — zero errors
2. `npm run build` — production build succeeds
3. Manual test flow:
   - Navigate to an application with deployment profiles linked to IT services that have technology products
   - Visual tab → Level 1 → double-click app → Level 2 → double-click DP → Level 3
   - Verify IT Service nodes no longer show tech count pills
   - Verify "Double-click to explore" hover tooltip on service nodes
   - Double-click IT Service → Level 4 shows service hero + tech product row
   - Tech products used by this DP are full-color; unused are dimmed
   - Lifecycle badges render correctly (Mainstream/Extended/End of Support)
   - Breadcrumb shows 3 segments; clicking each navigates back correctly
   - Legend shows teal tech product box + lifecycle colors
4. Open IT Service modal from catalog → confirm Technology Lifecycle section is gone
5. Impact check: `grep -r "techCount\|tech_count\|Cpu" src/components/visual/` — only in graphBuilders.ts data prop, not in ServiceNode rendering
