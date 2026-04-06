# CSDM Auto-Wiring + Visual Drill-Down — Session Guide

**Version:** 1.0
**Date:** April 6, 2026
**Companion to:** `planning/moonlit-prancing-pinwheel.md` (spec)

---

## How to Use This Document

Each "chunk" below is a self-contained Claude Code session. Copy the prompt block into a new Claude Code window.

**Rules:**
- Run chunks in order — each lists prerequisites
- Frontend chunks create feature branches — merge to `dev` when complete
- If a session runs out of context, start a new window with the next chunk
- No database schema changes — this is all frontend logic

**Important files:**
- Spec: `.claude/plans/moonlit-prancing-pinwheel.md`
- Visual graph builder: `src/components/visual/graphBuilders.ts`
- Visual data hook: `src/hooks/useVisualGraphData.ts`
- Visual container: `src/components/integrations/ConnectionsVisual.tsx`
- Node components: `src/components/visual/nodes/`
- DP detail page: `src/pages/ApplicationPage.tsx`
- Technology link handler: `src/hooks/useDeploymentProfiles.ts`

**Estimated total:** 4 chunks across ~6-8 hours of Claude Code time

---

## Chunk 1 — Auto-Assignment: Tech Product → IT Service Link

**Prerequisites:** None
**Branch:** `feat/csdm-auto-wiring`
**Output:** When a user adds a tech product to a DP, IT Service links are auto-created

```
Read these files before starting:
- .claude/plans/moonlit-prancing-pinwheel.md (full spec — focus on Part A)
- docs-architecture/planning/csdm-auto-wiring-session-guide.md (this guide)
- src/hooks/useDeploymentProfiles.ts (or wherever dp_technology_products writes happen)
- src/pages/ApplicationPage.tsx (Deployments & Costs tab, "What Does It Run On?" section)

Task: Implement auto-assignment of IT Service links when a technology product
is added to a deployment profile.

Behavior:
1. User adds a tech product to a DP via "What Does It Run On?" → "+ Link Technology"
2. After the dp_technology_products insert succeeds, query it_service_technology_products
   to find which IT Services that tech product powers (scoped to the namespace)
3. For each matching IT Service, check if deployment_profile_it_services already
   has a link for this DP + service
4. If not, auto-insert with relationship_type = 'depends_on'
5. Show toast: "Automatically linked to [Service Name]" for each new link

Also implement the reverse:
1. User removes a tech product from a DP
2. For each IT Service that tech product powers, check if any OTHER tech products
   on this DP still power that same service
3. If none remain, show a confirm dialog: "This deployment no longer uses any
   technology from [Service Name]. Remove the service dependency?"
4. If confirmed, delete the deployment_profile_it_services row

Edge cases:
- Tech product not linked to any IT Service → no auto-assignment, no toast
- Tech product powers multiple IT Services → auto-link all of them
- Manually added IT Service links (not powered by any DP tech) → leave alone
- Auto-assignment is additive only — never auto-delete without user confirmation

Impact analysis first:
grep -r "deployment_profile_technology_products" src/ --include="*.ts" --include="*.tsx"
grep -r "Link Technology\|Link Tech\|addTech" src/ --include="*.ts" --include="*.tsx"

Find the exact save/delete handlers for dp_technology_products and add the
auto-assignment logic after the primary operation succeeds.

Type check + build after changes.
```

---

## Chunk 2 — Visual Tab: Remove Tech Count Pills from ServiceNode

**Prerequisites:** Chunk 1 complete (or can run independently)
**Branch:** `feat/csdm-auto-wiring` (continue from Chunk 1, or new branch)
**Output:** ServiceNode simplified — no more tech count pills

```
Read these files before starting:
- .claude/plans/moonlit-prancing-pinwheel.md (spec — Part B, ServiceNode changes)
- src/components/visual/nodes/ServiceNode.tsx

Task: Remove the tech count pill from ServiceNode.

The tech count pills (e.g., "⚙ 2" on Windows Server Hosting) show the total
number of technology products composing that IT service. This is misleading in
the DP drill-down context because it shows the service's total composition,
not what this specific DP uses. Users will be able to drill into the IT Service
(Chunk 3) to see actual tech products instead.

Changes:
1. Remove the techCount prop rendering from ServiceNode.tsx
2. Remove the Cpu icon import if no longer used
3. Keep: service name, service type badge, and purple color scheme
4. Update LegendNode.tsx if it references tech count pills

Also clean up the data hook:
1. In useVisualGraphData.ts, the it_service_technology_products query currently
   only fetches counts. Keep the query but simplify if the count is no longer
   passed to the UI. (We will expand this query in Chunk 3 to fetch full
   tech product details.)

Do NOT remove the tech_count from the ITServiceInfo interface yet — Chunk 3
will repurpose it.

Type check + build after changes.
```

---

## Chunk 3 — Visual Tab: Level 4 IT Service Drill-Down

**Prerequisites:** Chunk 2 complete
**Branch:** `feat/csdm-auto-wiring` (continue)
**Output:** Double-clicking an IT Service on Level 3 shows its technology products

```
Read these files before starting:
- .claude/plans/moonlit-prancing-pinwheel.md (spec — Part B, Level 4 layout)
- src/components/visual/graphBuilders.ts (understand buildLevel3 pattern)
- src/hooks/useVisualGraphData.ts (data fetching)
- src/components/integrations/ConnectionsVisual.tsx (drill-down handlers, breadcrumb)
- src/components/visual/nodes/ (all node components)

Task: Add Level 4 drill-down — double-click an IT Service to see its
technology products.

### 1. New node component: TechProductNode.tsx
Create src/components/visual/nodes/TechProductNode.tsx:
- Teal color scheme (left border #14b8a6, background #f0fdfa)
- Shows: product name, version, lifecycle status badge
- If used by the current DP: full color, show server_name if available
- If NOT used by the current DP: dimmed/grayed, show "Not used by this deployment"
- Size: ~200×80px

### 2. Expand data fetching in useVisualGraphData.ts
Currently fetches it_service_technology_products as counts only. Expand to
fetch full tech product details:
- technology_product name, version
- lifecycle_reference (lifecycle_stage, eos_date)
- category name
Also fetch deployment_profile_technology_products for the focused app's DPs
so we can cross-reference which tech products this DP directly uses.

New interface:
interface ITServiceTechDetail {
  tech_product_id: string;
  tech_product_name: string;
  version: string | null;
  lifecycle_status: string | null;
  eos_date: string | null;
  category_name: string | null;
  used_by_this_dp: boolean;
  server_name: string | null;
}

### 3. Add buildLevel4() to graphBuilders.ts
Parameters: selectedService, selectedDp, techDetails[]
Layout:
- IT Service hero card at top (expanded: name, service type, status, infra provider)
- "BUILT ON" tier label below
- TechProductNode row below the tier label
- Dashed structural edges from service → each tech product
- Tech products used by this DP are full-color; unused ones dimmed

### 4. Update ConnectionsVisual.tsx
- Add double-click handler for 'service' node type → sets viewLevel 4
- Add viewLevel 4 case in the graph build switch
- Add breadcrumb segment: App > DP > IT Service
- Register TechProductNode in nodeTypes map
- Update LegendNode for Level 4 (show tech product node type)

### 5. Verification
- Hexagon → Visual → double-click DP → see IT Services (no count pills)
- Double-click "Windows Server Hosting" → Level 4
- See: Win Server 2019 (used, Extended Support, HEX-PROD-01), Win Server 2022 (dimmed, Mainstream)
- Breadcrumb shows 3 segments, click DP name → back to Level 3
- Axon Evidence → Visual → double-click DP → Identity & Access Mgmt only
- Double-click Identity & Access Mgmt → see tech products (if any linked)

Type check + build after changes.
```

---

## Chunk 4 — Architecture Docs + Merge

**Prerequisites:** Chunks 1-3 complete, all tests passing
**Output:** Feature merged to dev, architecture docs updated

```
All CSDM auto-wiring and visual drill-down work is complete.

Update architecture docs:
1. docs-architecture/core/visual-diagram.md — add Level 4 documentation,
   update level descriptions, note auto-wiring behavior
2. docs-architecture/core/deployment-profile.md — document auto-assignment
   of IT Service links when tech products are added/removed
3. docs-architecture/MANIFEST.md — bump version, add changelog entry
4. docs-architecture/guides/whats-new.md — add entry for CSDM auto-wiring
   and Visual Level 4 drill-down

Then merge:
cd ~/Dev/getinsync-nextgen-ag
git checkout dev
git pull origin dev
git merge feat/csdm-auto-wiring
git push origin dev

Commit architecture repo:
cd ~/getinsync-architecture
git add -A
git commit -m "docs: CSDM auto-wiring + visual Level 4 drill-down"
git push origin main
cd ~/Dev/getinsync-nextgen-ag

Run session-end checklist if this is the final session of the day.
```

---

## Quick Reference — What's Where

| Artifact | Location |
|----------|----------|
| Feature spec | `.claude/plans/moonlit-prancing-pinwheel.md` |
| This session guide | `docs-architecture/planning/csdm-auto-wiring-session-guide.md` |
| Graph builder | `src/components/visual/graphBuilders.ts` |
| Data hook | `src/hooks/useVisualGraphData.ts` |
| Visual container | `src/components/integrations/ConnectionsVisual.tsx` |
| Node components | `src/components/visual/nodes/*.tsx` |
| Visual architecture doc | `docs-architecture/core/visual-diagram.md` |
