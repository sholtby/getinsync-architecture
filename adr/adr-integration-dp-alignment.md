# ADR: Integration-to-Deployment-Profile Alignment

**Version:** 1.2
**Date:** March 19, 2026
**Status:** ACCEPTED
**Author:** Stuart Holtby + Claude
**Relates to:** `features/integrations/architecture.md`, `core/deployment-profile.md`, `core/visual-diagram.md`

---

## Context

During development of the Visual tab (React Flow rewrite, branch `feat/visual-tab-reactflow`), a fundamental data model gap was discovered: **integrations attach to applications, but CSDM requires them to attach to deployment profiles (service instances).**

The Visual tab's Level 3 "Blast Radius" view attempted to show integrations radiating from a selected deployment profile, but since `application_integrations` has no `deployment_profile_id` FK, every DP for the same application showed an identical blast radius. This is misleading and architecturally incorrect.

The React Flow branch was parked (not merged) pending Phase 2 completion. The renderer is correct; the data model underneath Level 3 is what needs fixing first.

---

## The Problem

### Current State

```
application_integrations
├── source_application_id  (FK → applications)
├── target_application_id  (FK → applications, nullable)
└── (no deployment_profile_id)
```

Integrations describe data movement between **applications**, not between **deployment instances**. This was a deliberate early design choice (see `architecture.md` section 2: "Integrations attach directly to the BusinessApplication, not to DeploymentProfiles").

### Why This Is Wrong

ServiceNow's CSDM (v4.0/v5.0) — the industry standard GetInSync aligns with — models integrations at the **Service Instance** (Application Service) level, not the Business Application level:

| CSDM Entity | GetInSync Equivalent | Integration Ownership |
|---|---|---|
| Software Product Model | `software_products` | N/A |
| Business Application | `applications` | Current (incorrect) |
| Application Service / Service Instance | `deployment_profiles` | Correct per CSDM |

**CSDM rationale:** Different deployments of the same product have different integrations. "ProLaws - Justice" may integrate with a case management system, while "ProLaws - Courts" integrates with a scheduling system. These are distinct data flows on distinct infrastructure.

### The "ProLaws Problem"

When one software product is deployed multiple times (e.g., ProLaws deployed for Justice, Courts, and Highways):

- **Today's workaround:** Create 3 separate `applications` records. Works but duplicates vendor info, software product links, and creates ownership ambiguity.
- **Correct model:** One `applications` record with 3 `deployment_profiles`, each with its own integrations, owner, support group, and SLA.
- **Current blocker:** Integrations can't be scoped to a DP because `application_integrations` has no DP FK.

### Impact on Workspace Group Publishing

The consumer/publisher model (via `workspace_group_publications`) publishes **deployment profiles**, not applications. Consumers subscribe to a specific DP and create their own portfolio assignment against it. If integrations lived on DPs, consumers could see what integrations affect the specific deployment they subscribed to — not an undifferentiated blob of all app-level integrations.

---

## CSDM Alignment Evidence

### CSDM Entity Chain

```
Software Product Model (what you buy)
    → Business Application (portfolio/design-time entity)
        → Service Instance / Application Service (operational deployment)
            → Integration connections (data flows between service instances)
```

### Key CSDM Principles

1. **Integrations are "Sends data to / Receives data from" relationships between Service Instances** — not between Business Applications
2. **Each Service Instance carries its own:** owner, support group, SLA, business criticality, operational status, environment
3. **CSDM 5.0 (Yokohama)** introduced "Connection Service Instance" as a first-class entity for modeling integrations
4. **Ownership is per-deployment** — Justice-ProLaws can have a different support group and SLA than Courts-ProLaws

### Sources

- ServiceNow CSDM 4.0 White Paper
- ServiceNow Community: "How to model integrations/interfaces within CMDB"
- ServiceNow Community: "CSDM relationship between Service Instances"
- ServiceNow Community: "Application Service and Service Instance: What is new in Yokohama and CSDM v5"

---

## Proposed Solution

### Phase 1: Schema Migration (Database)

Add a nullable FK to `application_integrations`:

```sql
ALTER TABLE application_integrations
  ADD COLUMN source_deployment_profile_id uuid
    REFERENCES deployment_profiles(id) ON DELETE SET NULL,
  ADD COLUMN target_deployment_profile_id uuid
    REFERENCES deployment_profiles(id) ON DELETE SET NULL;
```

**Why nullable:** Backward compatibility. Existing integrations remain valid at the app level. New integrations can optionally specify DP-level granularity. Migration can be gradual.

**Default behavior:** When creating an integration, if no DP is specified, auto-assign to the primary DP (`is_primary = true`). This matches Stuart's MVP guidance: "attach to the default/first DP."

### Phase 2: View + Type Updates

1. Update `vw_integration_detail` to include `source_deployment_profile_id`, `target_deployment_profile_id`, and DP names
2. Update `VwIntegrationDetail` TypeScript interface
3. Update all consumers of this view (grep for `vw_integration_detail`)

### Phase 3: UI Updates — COMPLETE (2026-04-04)

1. **Add Connection modal:** Optional DP selector (dropdown of DPs for the source/target app)
2. **Connections list tab:** Show DP name alongside app name when DP is specified
3. **Visual tab (React Flow rebuild):**
   - Level 1: App Graph — show integrations at app level (aggregate), edges connect to apps (double-click to navigate)
   - Level 2: DP Overview — show app's DPs with integration counts per DP
   - Level 3: DP Blast Radius — show only integrations for the selected DP (now accurate)

### Phase 4: Data Migration

For existing data:
1. Assign all existing integrations to the primary DP of their source application
2. Flag integrations that couldn't be auto-assigned (no primary DP) for manual review
3. Add to open items: review non-production DP integrations with customers

---

## Visual Tab Architecture (Future State)

### Level 1 — App Graph

```
Connected App 1 ──┐
Connected App 2 ──┤──→ [FOCUSED APP]
External System ──┘        |
                     DP 1   DP 2   DP 3
```

- Integration edges connect to the **application node** (not DPs)
- This is correct because Level 1 shows the portfolio view
- Double-click connected app → navigate to that app's page
- Double-click focused app → drill to Level 2
- DPs shown below for context, with integration count badges

### Level 2 — DP Overview

```
        [FOCUSED APP]
             |
    DP 1 (4 int)   DP 2 (2 int)   DP 3 (1 int)
```

- Shows integration count per DP
- Double-click DP → drill to Level 3 (now with accurate, DP-scoped data)

### Level 3 — DP Blast Radius (Accurate)

```
Connected App A ──┐
External System ──┤──→ [SELECTED DP]
Connected App B ──┘
```

- Shows ONLY integrations where `source_deployment_profile_id` or `target_deployment_profile_id` matches the selected DP
- Each DP now shows a different, accurate blast radius
- This is the view that was misleading before and is now correct

---

## Decision

**Accepted approach:** Phased migration (Phases 1-4 above).

**Immediate actions:**
1. Park `feat/visual-tab-reactflow` — do not merge yet. Resume after Phase 2 is complete. The React Flow renderer is correct; the data model underneath Level 3 is what needs fixing first. The D3 version has the same data gap — Level 3 blast radius was always misleading for multi-DP apps regardless of renderer.
2. Keep existing D3 two-level visual on `dev` (server_name added via `feat/dp-server-name-visual`)
3. Add to open items priority matrix as HIGH priority architecture item
4. Phase 1 + Phase 2 delivered as a single unit (schema + view + types, March 2026). Phase 3 (UI — DP selector + list display) delivered April 2026. React Flow rebuild (Visual tab Level 3) deferred to Stage C.

**Deferred:**
- React Flow visual tab rebuild (after Phase 2 is complete)
- Multi-deployment ownership model (DP-level owner, support group, SLA fields) — separate ADR if needed, though `deployment_profiles` already supports per-DP ownership via involved parties

---

## Risks

| Risk | Mitigation |
|---|---|
| Existing integrations lose context during migration | Nullable FK + auto-assign to primary DP |
| UI complexity for DP-level integration creation | Make DP optional in Add Connection modal; default to primary |
| Multiple DPs per app is rare today | Design for it now, avoid costly data migration later |
| Breaking change to `vw_integration_detail` | Additive columns only (new nullable fields) |

---

## Open Question Resolutions

1. **`target_deployment_profile_id` is always optional.** Never required for internal integrations. Data fidelity improves over time as customers refine their integration mappings.
2. **Partial specification allowed.** Source DP optional, target DP optional, both optional. An integration can specify one side, both sides, or neither. This supports gradual enrichment without blocking initial data entry.
3. **Show DP selector only when the app has multiple DPs.** Single-DP apps auto-assign to primary silently — no UI change needed. This keeps the Add Connection modal simple for the majority case.
4. **Yes — consumers subscribed to a published DP should see that DP's integrations in their portfolio view.** This is the core value proposition of DP-level scoping and a meaningful differentiator for the workspace group publishing model. Ministry B subscribing to Ministry A's "ProLaws - Justice (Prod)" DP sees only the integrations relevant to that specific deployment, not all ProLaws integrations across all ministries.

---

## Changelog

- **v1.2 — March 19, 2026** — Status promoted to ACCEPTED. Context section updated to reflect branch is parked not abandoned.
- **v1.1 — March 19, 2026** — Revised decision: React Flow branch parked not abandoned. Phase 1+2 sequencing clarified. Open questions resolved.
- **v1.0 — March 19, 2026** — Initial ADR.

---

*This ADR supersedes the "Future enhancement" note in `features/integrations/architecture.md` section 7, item 4.*
