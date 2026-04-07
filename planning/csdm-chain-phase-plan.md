# CSDM Chain Phase — Implementation Plan

**Version:** 1.0
**Date:** April 7, 2026
**Status:** COMPLETE
**Branch:** `feat/csdm-chain-phase`
**Supersedes:** `planning/csdm-auto-wiring-session-guide.md`

---

## Context

The CSDM chain is: Application → Deployment Profile → Technology Products → IT Services → Infrastructure → Cost. The Visual tab shows it. IT Spend monetizes it. Explorer reports on it. They all read from the same wiring, and that wiring had gaps. This phase closes all of them in 4 chunks delivered in order, each leaving the system in a working state.

**Goal:** "The CSDM chain works, visibly, from top to bottom, with no dead ends."

**Companion spec:** `planning/csdm-auto-wiring-spec.md` (detailed behavior spec for auto-wiring + Visual Level 4)

---

## Chunk 1: Validate Demo Data — COMPLETE

Ran 7 validation queries against COR namespace (`a1b2c3d4-e5f6-7890-abcd-ef1234567890`).

### Results (post-fix)

| # | Validation | Result | Status |
|---|-----------|--------|--------|
| Q1 | Dead-end apps (no IT Service AND no cost bundle) | 0 rows | PASS |
| Q2 | IT Services with no consumers | 1: ITSM Platform | ACCEPTED — consumers are people/processes, not app deployments |
| Q3 | IT Services with no tech composition | 3: Collaboration & Conferencing, IAM, Network Infrastructure | ACCEPTED — SaaS/hardware services with no software tech stack |
| Q4 | IT Services with no infrastructure provider | 4: Collaboration & Conferencing, IAM, ITSM Platform, M365 Enterprise | ACCEPTED — vendor-managed SaaS, correct by design |
| Q5 | DPs with tech but no IT Service links | 0 rows | PASS |
| Q6 | Apps missing portfolio assignments | 5 cost_bundle DPs (application DPs all assigned) | PASS — cost_bundle DPs don't need portfolio assignments |
| Q7 | Double-count (both cost bundle AND IT Service) | 0 rows | PASS |

### Fixes Applied

1. **Q7:** Deleted 5 IAM service links from cost-bundle-path apps (Axon Evidence, Brazos eCitation, Flock Safety LPR, ImageTrend Elite, Workday HCM)
2. **Q2:** Wired Collaboration & Conferencing → Microsoft 365 DP
3. **Q3:** Created 2 tech products (Esri ArcGIS Enterprise 11.2, ServiceNow Vancouver). Wired GIS Platform → ArcGIS, ITSM Platform → ServiceNow
4. **Q4:** Wired GIS Platform → Azure Subscription + Windows Server Farm infrastructure providers
5. **Q6:** Assigned 7 SaaS apps to their workspace default portfolios (application DPs only)

### Design Decisions

- **ITSM Platform stays with zero app consumers.** Its consumers are IT staff (people/processes), not application deployments. An app doesn't "depend on" ITSM to function.
- **Collaboration & Conferencing, IAM, Network Infrastructure accepted with no tech composition.** These are SaaS or hardware services — valid CSDM pattern, not a gap.
- **Vendor-managed SaaS services accepted with no infrastructure provider.** Infrastructure is the vendor's responsibility.

---

## Chunk 2: Auto-Wiring with Cost Awareness

**Prerequisites:** Chunk 1 PASS
**Branch:** `feat/csdm-chain-phase`

### Schema Change (Stuart runs in SQL Editor)

```sql
ALTER TABLE deployment_profile_it_services
ADD COLUMN source text NOT NULL DEFAULT 'manual'
CHECK (source IN ('auto', 'manual'));

COMMENT ON COLUMN deployment_profile_it_services.source IS
'How this link was created. auto = created by tech product auto-wiring. manual = user explicitly linked.';
```

### Key Files

| File | Current Role | Change |
|------|-------------|--------|
| `src/components/LinkedTechnologyProductsList.tsx` | Tech product add (L85-132) / remove (L176-199) handlers | Add auto-wiring logic after insert/delete |
| `src/components/ITServiceDependencyList.tsx` | IT service link add (L96-130) / remove (L153-183) | Add `source` column awareness, refresh after auto-wire |
| `src/components/LinkTechnologyProductModal.tsx` | Tech product picker modal | No change needed |
| `src/components/ServicePickerModal.tsx` | IT service picker modal | No change needed |
| `src/types/index.ts` | `DeploymentProfileITService` interface (L604-613) | Add `source: 'auto' \| 'manual'` field |

### Implementation Approach

1. **Update TypeScript interface** in `src/types/index.ts` — add `source` field to `DeploymentProfileITService`

2. **Add auto-wiring helper** (new function in LinkedTechnologyProductsList.tsx or extracted to a hook):
   - `autoWireITServices(dpId, techProductId, namespaceId)`:
     - Query `it_service_technology_products` joined with `it_services` where `technology_product_id = techProductId` AND `it_services.namespace_id = namespaceId`
     - For each matching IT service, check if `deployment_profile_it_services` already has a row for this DP + service
     - If not, insert with `relationship_type = 'depends_on'`, `source = 'auto'`
     - Return array of newly linked service names for toast display
   - If zero matches → toast: "[Tech Product Name] added. No IT Service covers this technology yet."
   - If matches found → toast per link: "Automatically linked to [Service Name]"

3. **Add auto-unwire helper** for tech product removal:
   - `autoUnwireITServices(dpId, techProductId, namespaceId)`:
     - Find IT services powered by the removed tech product
     - For each, check if any OTHER tech products still on this DP also power that service
     - If none remain AND link `source = 'auto'`:
       - Query IT service annual cost
       - Show confirm dialog with cost impact if cost > 0
       - On confirm, delete the `deployment_profile_it_services` row
     - If `source = 'manual'`, leave untouched

4. **Wire into existing handlers:**
   - `handleLinkProduct()` (LinkedTechnologyProductsList.tsx L85-132): After successful insert at L124, call `autoWireITServices()`
   - `handleDelete()` (LinkedTechnologyProductsList.tsx L176-199): Before/after delete at L189, call `autoUnwireITServices()`

5. **ITServiceDependencyList.tsx changes:**
   - Display `source` badge (auto/manual) on each linked service
   - Manual inserts via `doInsertDependency()` explicitly set `source = 'manual'`
   - Prevent deletion of auto-created links from the manual UI (or show warning)

6. **Refresh coordination:** After auto-wire inserts, the ITServiceDependencyList needs to refresh. Lift refresh callback from parent (DeploymentProfileCard.tsx) or use shared event/context.

### Edge Cases

- Tech product powers multiple IT Services → auto-link all, toast for each
- Tech product powers zero IT Services → informational toast only, no link changes
- Existing manual link also matches a tech product → skip (don't create duplicate, don't change source)
- User manually deletes an auto-created link → stays deleted (no re-creation on next load)

### Verification

1. Add a tech product to a DP that powers an IT Service → verify toast + auto-link with `source = 'auto'`
2. Add a tech product with no IT Service coverage → verify informational toast
3. Remove a tech product → verify confirm dialog with cost info → verify auto-link removed
4. Verify manual links untouched by auto-wiring
5. `npx tsc --noEmit` — zero errors

---

## Chunk 3: Visual Tab Level 4 — IT Service Drill-Down

**Prerequisites:** Chunk 2 complete
**Branch:** `feat/csdm-chain-phase` (continue)

### Key Files

| File | Lines | Change |
|------|-------|--------|
| `src/components/visual/graphBuilders.ts` | 386-525 (buildLevel3) | Add `buildLevel4()` following same pattern |
| `src/hooks/useVisualGraphData.ts` | 103-144 (IT service tech fetch) | Expand query to return full tech product details, not just counts |
| `src/components/integrations/ConnectionsVisual.tsx` | 60, 150-180, 233-242 | Add Level 4 type, drill-down handler, breadcrumb |
| `src/components/visual/nodes/ServiceNode.tsx` | 44-49 | Remove tech count pill |
| `src/components/visual/nodes/TechProductNode.tsx` | NEW | Teal node for tech products |
| `src/components/visual/nodes/LegendNode.tsx` | 65-106 | Add Level 4 legend content |
| `src/components/ITServiceModal.tsx` | 517-850 | Remove Technology Lifecycle section |

### Implementation Approach

1. **Extend ViewLevel type** (ConnectionsVisual.tsx L60):
   ```typescript
   type ViewLevel =
     | { level: 1 }
     | { level: 2 }
     | { level: 3; dpId: string; dpName: string }
     | { level: 4; dpId: string; dpName: string; serviceId: string; serviceName: string };
   ```

2. **Expand data fetching** (useVisualGraphData.ts):
   - Change `it_service_technology_products` query from count-only to full details:
     - technology_product name, version
     - technology_lifecycle_reference (lifecycle_stage, eos_date)
     - technology_categories (name)
   - Also fetch `deployment_profile_technology_products` for the focused app's DPs to cross-reference `used_by_this_dp` and `server_name`
   - New interface `ITServiceTechDetail`: tech_product_id, name, version, lifecycle_status, eos_date, category_name, used_by_this_dp, server_name

3. **Create TechProductNode.tsx:**
   - Teal color scheme (left border `#14b8a6`, bg `#f0fdfa`)
   - Shows: product name, version, lifecycle status badge (Mainstream green / Extended amber / End of Support red)
   - Full color if `used_by_this_dp`, show server_name
   - Dimmed/grayed if not used by this DP, show "Not used by this deployment"
   - Size: ~200x80px

4. **Add buildLevel4()** to graphBuilders.ts:
   - IT Service hero card at top (name, service type, annual cost, infrastructure provider)
   - "BUILT ON" tier label
   - TechProductNode row below
   - Dashed structural edges from service → each tech product
   - DP-used tech products full color; unused dimmed

5. **ConnectionsVisual.tsx updates:**
   - Double-click handler for `service` node type → `setViewLevel({ level: 4, ... })`
   - Breadcrumb: App > DP > IT Service with click-back navigation
   - Register `TechProductNode` in `NODE_TYPES`
   - Level 4 case in graph build switch

6. **Remove tech count pills** from ServiceNode.tsx (L44-49) — users drill in instead

7. **Remove Technology Lifecycle section** from ITServiceModal.tsx (L517-850) — lifecycle is derived from component tech products per Chunk 4

8. **Update LegendNode.tsx** for Level 4 content (teal tech product box + lifecycle badge legend)

### Verification

1. Visual tab → double-click DP → see IT Services (no count pills)
2. Double-click IT Service → Level 4 with tech products
3. Verify breadcrumb navigation (3 segments, click-back works)
4. Verify DP-used tech products full color, unused dimmed
5. Verify IT Service modal no longer has Technology Lifecycle section
6. `npx tsc --noEmit` — zero errors

---

## Chunk 4: IT Service Lifecycle Derivation + Architecture Docs — COMPLETE

**Prerequisites:** Chunk 3 complete
**Branch:** `feat/csdm-chain-phase` (continue)

### Part A — Derived Lifecycle Status

Compute worst lifecycle from an IT Service's component tech products. Hierarchy (worst to best): End of Support > Extended Support > Mainstream > Not Set. IT Services with zero tech composition = "Not Set" (correct — they have no tech to age).

Frontend-only derivation — no new database column. Replaces the stored `lifecycle_reference_id` FK on `it_services` for display purposes (column stays in DB for future cleanup).

#### Step 1: Add `deriveWorstLifecycle()` utility

**File:** `src/utils/technology-health.ts`

New function after existing lifecycle helpers. Takes array of `{ lifecycle_status: string | null }`, returns worst status using priority map: `end_of_support: 3`, `extended: 2`, `mainstream: 1`. All other statuses (`preview`, `business_vendor_managed`, `incomplete_data`, `null`) score 0. Returns `null` for empty array or all-zero scores. `LifecycleBadge` renders nothing for `null`.

#### Step 2: Add `derived_lifecycle` to `ITServiceInfo` in data hook

**File:** `src/hooks/useVisualGraphData.ts`

- Add `derived_lifecycle: string | null` to `ITServiceInfo` interface (line 43)
- Import `deriveWorstLifecycle` from `../utils/technology-health`
- At service building loop (line 197-204), filter `itServiceTechDetails` per service and compute:
  ```typescript
  derived_lifecycle: deriveWorstLifecycle(svcTechForThis)
  ```

#### Step 3: Pass lifecycle through `buildLevel3`

**File:** `src/components/visual/graphBuilders.ts` (line 495)

Add `derivedLifecycle: svc.derived_lifecycle` to service node data in `buildLevel3()`.

#### Step 4: Update `ServiceNode` component

**File:** `src/components/visual/nodes/ServiceNode.tsx`

- Add `derivedLifecycle?: string | null` to `ServiceNodeData` interface
- Import `LifecycleBadge` from `../../technology-health/LifecycleBadge`
- After service type display (line 46), render lifecycle badge when present
- Increase `NODE_HEIGHT_SERVICE` from `60` to `75` in `graphBuilders.ts` (line 17)

#### Step 5: Pass lifecycle through `buildLevel4` hero card

**File:** `src/components/visual/graphBuilders.ts` (lines 557-561)

Add `derivedLifecycle: selectedService.derived_lifecycle` to hero node data. Same `ServiceNode` component renders badge automatically.

#### Step 6: Replace stored lifecycle with derived in IT Service Catalog

**File:** `src/pages/settings/ITServiceCatalogSettings.tsx`

- Expand tech composition query (line 194-206) to join `lifecycle_reference:technology_lifecycle_reference(current_status)` inside `technology_products`
- Update `ServiceNode` interface `techs` type to include `lifecycle_status: string | null`
- Extract `current_status` from nested lifecycle reference during tech mapping (lines 270-283)
- Import `deriveWorstLifecycle`, compute per service node
- Replace `node.service.lifecycle_reference.current_status` LifecycleBadge (line 722) with derived lifecycle badge

#### Step 7: Remove TODO comment

**File:** `src/components/ITServiceModal.tsx` (line 124)

Remove: `// TODO: Chunk 4 will derive lifecycle from component tech products — lifecycle_reference_id stored field becomes redundant.`

### Part B — Architecture Documentation

#### Step 8: Update `docs-architecture/core/visual-diagram.md`

Bump to v2.6. Add derived lifecycle badge to ServiceNode docs, Level 3, Level 4. Document derivation logic.

#### Step 9: Update `docs-architecture/core/deployment-profile.md`

Bump to v2.0. Add §10 "CSDM Auto-Wiring": tech product add/remove triggers, `source` column (`auto`/`manual`), SaaS DPs skip auto-wiring, cost confirmation dialog on remove.

#### Step 10: Update `docs-architecture/MANIFEST.md`

Bump v1.97 → v1.98. Update visual-diagram (v2.5→v2.6), deployment-profile (v1.9→v2.0). Changelog for CSDM Chain Phase.

#### Step 11: Update `docs-architecture/guides/whats-new.md`

Entry for IT Service Derived Lifecycle under April 6 section.

#### Step 12: Mark this plan COMPLETE

Update status to COMPLETE, add changelog entry.

### Part C — Verification + Merge

#### Step 13: Build verification

```bash
npx tsc --noEmit    # zero errors
npm run build       # production build passes
```

#### Step 14: Commit both repos

```bash
# Code repo (feature branch)
cd ~/Dev/getinsync-nextgen-ag && git add -A && git commit -m "feat: Chunk 4 — derived IT Service lifecycle + architecture docs"

# Architecture repo (main)
cd ~/getinsync-architecture && git add -A && git commit -m "docs: CSDM Chain Phase complete — auto-wiring, Visual Level 4, derived lifecycle" && git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

#### Step 15: Merge

```bash
git checkout dev && git pull origin dev
git merge feat/csdm-chain-phase && git push origin dev
git checkout main && git merge dev && git push origin main
```

#### Step 16: Session-end checklist — no overrides

### Key Files

| File | Change |
|------|--------|
| `src/utils/technology-health.ts` | New `deriveWorstLifecycle()` |
| `src/hooks/useVisualGraphData.ts` | `ITServiceInfo.derived_lifecycle` + populate |
| `src/components/visual/graphBuilders.ts` | Pass lifecycle in Level 3/4, adjust `NODE_HEIGHT_SERVICE` |
| `src/components/visual/nodes/ServiceNode.tsx` | `LifecycleBadge` in node UI |
| `src/pages/settings/ITServiceCatalogSettings.tsx` | Expand query, derive lifecycle, replace badge |
| `src/components/ITServiceModal.tsx` | Remove TODO |
| `docs-architecture/core/visual-diagram.md` | Lifecycle badge docs |
| `docs-architecture/core/deployment-profile.md` | Auto-wiring section |
| `docs-architecture/MANIFEST.md` | Version bump + changelog |
| `docs-architecture/guides/whats-new.md` | Derived lifecycle entry |

### Reused Utilities

| Utility | Path |
|---------|------|
| `LifecycleBadge` | `src/components/technology-health/LifecycleBadge.tsx` |
| `getLifecycleLabel` | `src/utils/technology-health.ts` |
| `ITServiceTechDetail` | `src/hooks/useVisualGraphData.ts:52-60` |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-07 | Initial plan. Chunk 1 complete (validation + fixes). Chunks 2-4 planned. Supersedes csdm-auto-wiring-session-guide.md. |
| v1.1 | 2026-04-06 | Chunk 4 detailed implementation plan added. 16 steps across 3 parts. |
| v1.2 | 2026-04-06 | Chunk 4 COMPLETE. All 4 chunks delivered. CSDM Chain Phase closed. |
