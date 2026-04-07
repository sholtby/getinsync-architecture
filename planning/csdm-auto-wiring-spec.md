# Spec: CSDM Auto-Wiring + Visual Tab Level 4 Drill-Down

## Context

The "QuickBooks for CSDM" vision means users shouldn't need to understand CSDM layers. Today, users must manually:
1. Add technology products to a DP ("What Does It Run On?")
2. Separately link IT Services to the same DP
3. Understand which tech products compose which IT services

This creates data quality issues (wrong links, missing links, contradictions like SaaS apps linked to Azure Cloud Hosting) and cognitive load. The fix is two-part: auto-derive IT Service links from technology products, and make the relationship visible in the Visual tab.

## Part A: Auto-Assignment (DP Tech Product → IT Service)

### Behavior

**When a user adds a technology product to a DP:**
1. Look up which IT Services that tech product powers (from `it_service_technology_products`)
2. For each matching IT Service, check if `deployment_profile_it_services` already has a link for this DP
3. If not, auto-create the link with `relationship_type = 'depends_on'`
4. Show a toast: "Automatically linked to Windows Server Hosting"

**When a user removes the last tech product that powers a specific IT Service from a DP:**
1. Check if any remaining tech products on this DP still power that IT Service
2. If none remain, prompt: "This deployment no longer uses any technology from Windows Server Hosting. Remove the service dependency?"
3. If confirmed, delete the `deployment_profile_it_services` row

### Where This Happens

The user adds/removes tech products on the **Deployments & Costs tab** → "What Does It Run On?" section → `+ Link Technology` button. This writes to `deployment_profile_technology_products`.

**File:** The save handler for `deployment_profile_technology_products` — likely in the DP section of `ApplicationPage.tsx` or a hook like `useDeploymentProfiles.ts`.

### Data Queries

```
-- On tech product add: find IT services this tech product powers
SELECT its.id, its.name
FROM it_service_technology_products istp
JOIN it_services its ON istp.it_service_id = its.id
WHERE istp.technology_product_id = :added_tech_product_id
AND its.namespace_id = :namespace_id;

-- Check if DP already linked to each service
SELECT id FROM deployment_profile_it_services
WHERE deployment_profile_id = :dp_id
AND it_service_id = :service_id;

-- Auto-insert if missing
INSERT INTO deployment_profile_it_services (deployment_profile_id, it_service_id, relationship_type)
VALUES (:dp_id, :service_id, 'depends_on')
ON CONFLICT DO NOTHING;
```

### Edge Cases

- **Tech product not linked to any IT Service:** No auto-assignment. The tech product just sits on the DP. This is fine — not all tech products are part of shared IT Services.
- **Tech product powers multiple IT Services:** Auto-link all of them. E.g., if a security tool powers both Cybersecurity Operations and Identity & Access Management, link both.
- **Manually added IT Service links:** Don't touch them. Auto-assignment is additive only. If a user manually linked an IT Service that isn't powered by any of the DP's tech products, leave it alone.
- **SaaS DPs:** Auto-assignment still works. If someone adds a tech product to a SaaS DP (unusual but valid), the service link is created. The logic is hosting-type-agnostic.

---

## Part B: Visual Tab — Level 4 IT Service Drill-Down

### Interaction

On Level 3 (DP drill-down), the user sees IT Services in a horizontal row at the bottom. **Double-clicking an IT Service node** drills into Level 4.

### Level 4 Layout

```
  [IT Service Node - expanded hero card]
  Windows Server Hosting
  Compute · Active · Windows Server Farm — City Hall

  ── BUILT ON ─────────────────────────
  [Win Server 2019]          [Win Server 2022]
  Extended Support           Mainstream
  HEX-PROD-01               —
  ✓ Used by this DP          ✗ Not used
```

**Key elements:**
- **IT Service hero card** (top): Expanded view of the service showing name, service type, status, infrastructure provider (from `it_service_providers`), cost
- **"BUILT ON" row** (bottom): Technology products that compose this IT Service (from `it_service_technology_products`)
- **Per-DP context**: Each tech product node shows whether *this* DP uses it (cross-reference with `dp_technology_products`) and the server name if applicable

### Breadcrumb

```
Hexagon OnCall CAD/RMS > Hexagon OnCall CAD/RMS - PROD - CHDC > Windows Server Hosting
```

Click breadcrumb segments to navigate back to Level 1 (app name) or Level 3 (DP name).

### New Node: TechProductNode

**File:** `src/components/visual/nodes/TechProductNode.tsx` (new)

**Visual design:**
- Teal color scheme (consistent with technology product identity)
- Shows: product name, version, lifecycle badge (Extended Support / Mainstream / End of Life)
- Server name (from `dp_technology_products.server_name` or similar) if this DP uses it
- Dimmed/grayed if not used by this DP (part of the service but not on this deployment)

**Size:** ~200×80px (similar to ServiceNode but taller to accommodate lifecycle badge + server name)

### Data Requirements

**Already fetched in `useVisualGraphData.ts`:**
- ✅ `deployment_profile_it_services` → which IT services each DP consumes
- ✅ `it_service_technology_products` → tech count per service (currently just count — need full records)

**Need to enhance:**
- Expand `it_service_technology_products` query to return full tech product details (name, version, lifecycle status), not just count
- Fetch `deployment_profile_technology_products` for the selected DP to cross-reference which tech products this DP directly uses

**New data shape:**
```typescript
interface ITServiceTechDetail {
  tech_product_id: string;
  tech_product_name: string;
  version: string | null;
  lifecycle_status: string | null;
  eos_date: string | null;
  category_name: string | null;
  used_by_this_dp: boolean;  // cross-referenced with dp_technology_products
  server_name: string | null;  // from dp_technology_products if used
}
```

### Graph Builder Changes

**File:** `src/components/visual/graphBuilders.ts`

Add `buildLevel4(selectedService, selectedDp, techProducts)`:
- Service hero card centered at top
- Tech product nodes in horizontal row below with "BUILT ON" tier label
- Dashed structural edges from service → each tech product
- Tech products used by this DP are full-color; unused ones are dimmed

### ConnectionsVisual.tsx Changes

- Add `onNodeDoubleClick` handler for `service` node type → sets `viewLevel: 4`
- Add breadcrumb segment for Level 4
- Register `TechProductNode` in `nodeTypes` map

### ServiceNode Changes

- **Remove tech count pills** — no longer needed since users can drill in to see actual tech products
- Keep: name + service type badge

---

## Files to Modify

| File | Change |
|------|--------|
| `src/hooks/useVisualGraphData.ts` | Expand IT service tech query to return full details; add `dp_technology_products` query |
| `src/components/visual/graphBuilders.ts` | Add `buildLevel4()` function |
| `src/components/visual/nodes/TechProductNode.tsx` | **New file** |
| `src/components/visual/nodes/ServiceNode.tsx` | Remove tech count pill |
| `src/components/integrations/ConnectionsVisual.tsx` | Add Level 4 handling, breadcrumb, node type registration |
| `src/components/visual/nodes/LegendNode.tsx` | Add tech product to Level 4 legend |
| DP tech product save handler (TBD — need to locate) | Add auto-assignment logic after tech product add/remove |

## What NOT to Change

- Levels 1 and 2 — untouched
- IT Service Catalog "Built on:" chips — still correct
- Technology Catalog "Powers:" chips — still correct
- Database schema — no new tables or columns
- IT Service Modal — no changes

## Verification

### Part A (Auto-Assignment)
1. Go to any On-Prem app → Deployments & Costs → expand DP → "What Does It Run On?"
2. Click "+ Link Technology" → add a tech product that powers an IT Service (e.g., add SQL Server 2019)
3. Verify toast "Automatically linked to SQL Server Database Services"
4. Check IT Services section on the DP — SQL Server Database Services should appear
5. Remove SQL Server 2019 → confirm prompt → verify IT Service link removed

### Part B (Visual Drill-Down)
1. Hexagon → Visual → double-click DP → see IT Services (no count pills)
2. Double-click "Windows Server Hosting" → see Level 4
3. Verify breadcrumb: Hexagon > DP name > Windows Server Hosting
4. Verify tech products shown: Win Server 2019 (used, HEX-PROD-01), Win Server 2022 (not used, dimmed)
5. Click breadcrumb "DP name" → returns to Level 3
6. Axon Evidence (SaaS) → Visual → double-click DP → only Identity & Access Management shown
7. `npx tsc --noEmit` — zero errors
