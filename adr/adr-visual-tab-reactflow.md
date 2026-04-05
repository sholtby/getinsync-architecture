# ADR: Visual Tab — React Flow Rewrite

**Version:** 1.1
**Date:** April 5, 2026
**Status:** COMPLETE
**Author:** Stuart Holtby + Claude
**Relates to:** `core/visual-diagram.md`, `adr/adr-integration-dp-alignment.md`
**Branch:** `feat/visual-tab-reactflow`

---

## Context

The Visual tab was built as a hand-rolled 1,371-line D3/SVG component (`ConnectionsVisual.tsx`) with manual layout calculation, 354 lines of magic numbers, no graph layout algorithm, and jank zoom/pan behaviour. A React Flow rewrite was completed on `feat/visual-tab-reactflow` but parked before merging when a data model gap was discovered during testing.

---

## Why D3 Was Replaced

| Problem | Detail |
|---|---|
| 354-line `calculateLayout()` | Two independent layout paths sharing no logic |
| 38 magic numbers | Hardcoded pixel values throughout — fragile to viewport changes |
| Level 1/2 inconsistency | One path uses proportional Y, other uses absolute pixels |
| No graph algorithm | All layout is manual arithmetic |
| Zoom/pan jank | D3 transforms SVG elements instead of CSS transforms — slower repaint |
| Extension resistance | Adding Level 3 blast radius would require a third independent layout path |

---

## Why React Flow

- CSS transform pan/zoom — hardware accelerated, 60fps
- Nodes are React components — full access to hooks, Tailwind, design system
- Dagre layout algorithm eliminates manual arithmetic entirely
- Built-in Controls, MiniMap, Background
- First-class TypeScript support
- `smoothstep` edges with `borderRadius: 0` for orthogonal right-angle routing

---

## What Was Built on the Branch

| File | Lines | Role |
|---|---|---|
| `ConnectionsVisual.tsx` | 224 (was 1,371) | Main canvas, breadcrumbs, navigation, layout persistence |
| `graphBuilders.ts` | 175 | Dagre layout + node/edge builders for all three levels |
| `AppNode.tsx` | 68 | App/external system nodes |
| `DPNode.tsx` | 80 | Deployment profile nodes |
| `useVisualGraphData.ts` | 128 | All Supabase queries extracted from component |

### Dependencies

- **Added:** `@xyflow/react`, `@dagrejs/dagre`, `@types/dagre`
- **Removed:** `d3`, `@types/d3`
- **License verified:** No React Flow Pro components used — free tier only

---

## Why the Branch Is Parked

During testing, Level 3 blast radius was found to be misleading — every DP for the same application showed identical integrations because `application_integrations` has no `deployment_profile_id` FK. This is a data model gap, not a renderer problem. The D3 version has the same gap — it was not visible because Level 3 was never built in D3.

See `adr/adr-integration-dp-alignment.md` for the full problem statement and resolution.

---

## Resume Conditions

1. `adr-integration-dp-alignment.md` Phase 1 complete — `source_deployment_profile_id` and `target_deployment_profile_id` columns added to `application_integrations`
2. Phase 2 complete — `vw_integration_detail` updated, TypeScript types updated
3. Then resume `feat/visual-tab-reactflow` and wire Level 3 to DP-scoped integration data

---

## Three-Level Architecture (as Built on Branch)

| Level | Nodes | Edges | Layout | Entry |
|---|---|---|---|---|
| 1 — App Graph | Apps + externals | `application_integrations` | TB | Default |
| 2 — DP Overview | Deployment profiles | `inherits_tech_from` | TB | Click focused app |
| 3 — Blast Radius | Connected apps + externals | DP-scoped integrations | LR | Double-click DP |

### Layout Persistence

`applications.visual_layout` JSONB column — keyed by level (`level1`, `level2`, `level3`). Dagre runs only when no saved layout exists for that level. Reset Layout button per level. Viewport save debounced 500ms.

---

## Known Gaps (Resolved)

All gaps identified at parking have been resolved:

- ~~Level 1 layout direction needs to be TB not LR~~ — Fixed: manual three-tier positioning (commit ef753e1)
- ~~Double-click on DP for Level 3 (currently single-click)~~ — Fixed (commit 7c8976f)
- ~~Hover tooltip on app nodes lost from D3 version~~ — Fixed (commit 7c8976f)
- ~~Level 3 blast radius data inaccurate~~ — Fixed: Level 3 now filters integrations by `source_deployment_profile_id` / `target_deployment_profile_id` matching the selected DP

---

## Risks

| Risk | Mitigation |
|---|---|
| Branch diverges from dev while parked | Rebase onto dev before resuming |
| D3 version accumulates more fixes while parked | Keep D3 fixes minimal — don't invest in code marked for replacement |
| Resume conditions delayed beyond MVP | Visual tab ships as D3 two-level; React Flow is enhancement not blocker |

---

## Changelog

- **v1.1 — April 5, 2026** — Rebased onto dev. Level 3 blast radius wired to DP-scoped integration data. Integration count added to Level 2 DP nodes. All known gaps resolved. Status → COMPLETE.
- **v1.0 — March 19, 2026** — Initial ADR. Branch parked.
