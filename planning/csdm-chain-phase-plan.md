# CSDM Chain Phase — Implementation Plan

**Version:** 1.0
**Date:** April 7, 2026
**Status:** IN PROGRESS
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

## Chunk 4: IT Service Lifecycle Derivation + Architecture Docs

**Prerequisites:** Chunk 3 complete
**Branch:** `feat/csdm-chain-phase` (continue)

### Derived Lifecycle Status

Compute worst lifecycle from component tech products: End of Support > Extended Support > Mainstream > Not Set

Display in:
- IT Service card in catalog
- ServiceNode in Visual Level 3
- IT Service hero card on Level 4

Implementation: Frontend-only derivation using `it_service_technology_products` → `technology_products` → `technology_lifecycle_reference`. Compute at render time or in the data hook. No stored column.

### Architecture Docs to Update

1. `docs-architecture/core/visual-diagram.md` — Add Level 4 docs, update level descriptions
2. `docs-architecture/core/deployment-profile.md` — Document auto-wiring behavior
3. `docs-architecture/MANIFEST.md` — Bump version, changelog entry
4. `docs-architecture/guides/whats-new.md` — Entry for CSDM auto-wiring + Level 4
5. `docs-architecture/guides/user-help/` — Update relevant help articles

### Merge Sequence

```bash
git checkout dev && git pull origin dev
git merge feat/csdm-chain-phase && git push origin dev
git checkout main && git merge dev && git push origin main
```

Run session-end checklist.

### Verification

1. Verify derived lifecycle shows on IT Service cards
2. Verify derived lifecycle on ServiceNode (Level 3)
3. Verify derived lifecycle on IT Service hero (Level 4)
4. Architecture docs accurate and committed
5. `npm run build` — passes
6. Session-end checklist passes

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-07 | Initial plan. Chunk 1 complete (validation + fixes). Chunks 2-4 planned. Supersedes csdm-auto-wiring-session-guide.md. |
