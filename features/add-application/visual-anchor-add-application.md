# Visual Anchor — Add Application Wizard

**Version:** 1.0  
**Date:** April 6, 2026  
**Status:** 🟡 AS-DESIGNED (PARKED — concept captured, not scheduled)  
**Depends on:** COR demo data reset (complete first)  
**Schema impact:** None — pure frontend

---

## 1. Problem

The current Edit Application screen (4 tabs: General, Deployments & Costs, Integrations, Visual) is a data entry form with no spatial metaphor. Users fill in fields without understanding how those fields connect to the architecture model. There is no progressive disclosure — a business owner who just wants to record "we use Workday and it costs $95K/year" sees the same interface as an IT architect wiring 6 IT Services.

## 2. Solution

Two changes, delivered together:

1. **Visual Anchor** — A persistent right-panel diagram (React Flow) that builds itself as the user completes form steps. Ghost placeholder nodes show what *could* be filled in. Nodes light up with real data as fields are completed.

2. **Simple/Advanced Forms** — Simple form is default for "Add Application." Surfaces only mandatory + common fields. Advanced form = today's Edit tabs, accessed via opt-in or auto-triggered by choosing the IT Service cost path.

---

## 3. Visual Anchor Specification

### 3.1 Layout

The Add/Edit Application screen splits into two panels:

```
┌─────────────────────────────────────────────────────┐
│  Edit Hexagon OnCall CAD/RMS                        │
│  📍 Publishing From: Police Department → Core       │
├──────────────────────┬──────────────────────────────┤
│                      │                              │
│   FORM PANEL         │   VISUAL ANCHOR              │
│   (left, ~340px)     │   (right, flex)              │
│                      │                              │
│   Step 1: Name It    │   ┌─────────────────┐       │
│   Step 2: Deploy It  │   │  App Node        │       │
│   Step 3: Cost It    │   └────────┬────────┘       │
│   Step 4: Connect It │            │                 │
│                      │   ┌────────┴────────┐       │
│                      │   │  DP Node         │       │
│                      │   └────────┬────────┘       │
│                      │      ┌─────┼─────┐          │
│                      │   [Svc] [Svc] [Svc]         │
│                      │                              │
│   [Back] [Next →]    │   "Architecture Preview"     │
│                      │                              │
├──────────────────────┴──────────────────────────────┤
│  Cancel                              Save Application│
└─────────────────────────────────────────────────────┘
```

### 3.2 Progressive Reveal States

The anchor diagram has 4 tiers. **All 4 tiers are visible as ghost nodes from the moment the wizard opens** — the user sees the complete skeleton of what they're building before typing anything. As each form step is completed, the corresponding tier's ghost nodes are replaced with lit nodes showing real data.

| Form Step | Tier Label | Ghost State | Lit State |
|-----------|-----------|-------------|-----------|
| **Step 1: Name It** | APPLICATION | Dashed box: "Your application appears here" | Solid teal border, app name, workspace, lifecycle badge |
| **Step 2: Deploy It** | DEPLOYMENT | Dashed box: "deployment profile added here" | Amber border, green env bar, "PROD · On-Prem", server name, region flag |
| **Step 3: Cost It** | SERVICES | 3 dashed boxes: "IT Service" | Blue border, service name, type label. OR single cost badge if Cost Bundle path |
| **Step 4: Connect It** | INTEGRATIONS | Dashed boxes above app node | Amber border, app name, direction arrow, method label |

### 3.3 Node Styling

Follow the existing ArchiMate-informed design system from the Visual tab:

- **App node:** `border-radius: 8px`, teal border (`#0d9488`), white fill
- **DP node:** `border-radius: 3px`, amber border (`#f59e0b`), light amber fill. Green env bar at top for Production
- **IT Service node:** `border-radius: 6px`, blue border (`#3b82f6`), light blue fill
- **Integration node:** Same as app node but amber border for connected apps
- **Ghost nodes:** Same shapes but dashed `1.5px` borders in `gray-300`, `gray-50` fill, italic gray text
- **Connectors:** Dotted gray when ghost, solid when lit. App→DP = structural (gray). DP→Service = structural (gray). Integration = amber with directional arrows

Color references: TIME quadrant colors from `src/lib/scoring.ts` lines 231–250. TOLERATE = `#9da3af`.

### 3.4 Clickability

Clicking a node in the anchor jumps the form panel to the corresponding step. This provides bidirectional navigation: form drives diagram, diagram drives form.

### 3.5 React Flow Reuse

The anchor is a **simplified, read-only** version of the Visual tab's Level 2 layout. It reuses:
- `@xyflow/react` (already in `package.json`)
- Dagre layout (already used in Visual tab)
- The existing node shape/color conventions

It does NOT reuse the full Visual tab component — it's a new lightweight component that reads from form state, not from database queries.

### 3.6 Collapsible Panel

The anchor panel is collapsible via a toggle handle on its left edge. When collapsed, the form panel expands to full width. Behavior:

- **Default for new users:** Open (the anchor is a teaching tool — first-time users need it)
- **Persisted:** Collapse state saved to `localStorage` (`gis-anchor-collapsed`). Once a power user collapses it, it stays collapsed across sessions
- **Always available:** A small "Show architecture preview" button remains visible in the collapsed state so the user can reopen it at any time
- **Responsive:** On viewports below 900px, the anchor is hidden by default (mobile/tablet — form takes full width)

---

## 4. Simple Form Specification

### 4.1 When It Appears

- **Add Application** → Always starts in Simple form
- **Edit Application** → Opens in the mode matching current complexity:
  - App has only 1 DP + Cost Bundles or no cost → Simple
  - App has IT Service links, multiple DPs, tech products, or integrations → Advanced

### 4.2 Simple Form Fields

The form is a 4-step wizard. Steps 3 and 4 are skippable.

**Step 1: What's the application?**

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| Application Name | ✅ | text | |
| Workspace | ✅ | select | Pre-filled if user is scoped to one workspace |
| Description | | textarea | |
| Business Owner | | contact picker | |
| Lifecycle Status | | select | Default: "Mainstream" |

**Step 2: Where does it run?**

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| Hosting Type | ✅ | select | SaaS / On-Premise / Cloud (IaaS/PaaS) / Hybrid |
| Environment | | select | Default: "Production" |
| Region | | select | Default: namespace region |
| Cloud Provider | | select | Only shown if Hosting = Cloud or Hybrid |

**Step 3: What does it cost?** (skippable — "I'll add this later")

Two paths presented as cards:

**Path A: "I know the annual cost" (Cost Bundle)**

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| Cost Bundle Name | | text | Auto-generated: "{App Name} License" |
| Annual Cost | | currency | |
| Vendor | | org picker | |
| Contract Reference | | text | |
| Contract End Date | | date | |

**Path B: "Link to shared IT Services"**
- Switches to Advanced form automatically (can't wire IT Services in Simple mode)

**Step 4: What connects to it?** (skippable — "I'll add these later")

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| Connected App | | app picker | Search existing apps |
| Direction | | select | Sends to / Receives from / Bidirectional |
| Method | | select | API / File / Database / SSO |

Can add multiple. Each one lights up a node in the anchor.

**Graduated scope:** Simple form captures the connection (which app, direction, method) — enough to draw the line on the anchor and the Visual tab. Advanced fields (data tags, sensitivity classification, frequency, DP-level scoping, criticality) are only available in Advanced mode. This matches the maturity model: Day 1 = "we talk to Workday." Day 90 = "we send PII to Workday via daily SFTP batch using their Production API endpoint."

### 4.3 Auto-Created Records

When the user saves from Simple form, the system creates:

1. `applications` row (name, description, lifecycle_status, workspace_id)
2. `deployment_profiles` row (is_primary=true, name=app name, hosting_type, environment, region, cloud_provider)
3. `portfolio_assignments` row if a default portfolio exists for the workspace
4. If cost entered: cost bundle DP (is_cost_bundle=true) with contract fields
5. If integrations added: `application_integrations` rows with source/target DP IDs (using the primary DPs of both apps)

### 4.4 Labels — The 18-Year-Old Test

No CSDM jargon in Simple form. Labels use plain questions:

| Internal Concept | Simple Form Label |
|-----------------|-------------------|
| Deployment Profile | *(not mentioned — auto-created)* |
| Cost Bundle | "Annual Cost" |
| IT Service | *(not available in Simple — triggers Advanced)* |
| Hosting Type | "Where does it run?" |
| Environment | "Which environment?" |
| Integration | "What connects to it?" |
| Portfolio Assignment | *(auto-assigned if default portfolio exists)* |

---

## 5. Advanced Form Specification

### 5.1 Entry Points

- User clicks "I need more options" at bottom of any Simple step
- User chooses "Link to shared IT Services" in Step 3
- System detects app already has Advanced-level data on Edit

### 5.2 Content

The Advanced form is **today's Edit Application tabs** (General, Deployments & Costs, Integrations, Visual) with two additions:

1. The Visual Anchor panel replaces the current Visual tab (the anchor IS the visual — no separate tab needed in wizard mode)
2. Step indicators at top showing which section the user is in

### 5.3 Transition

Switching Simple → Advanced preserves all data entered so far. The wizard expands to show all fields. No data loss.

Switching Advanced → Simple is allowed only if the app has no Advanced-level data (IT Services, multiple DPs, tech products). If it does, the option is grayed out with tooltip: "This application uses advanced features. Use the full editor."

---

## 6. Implementation Plan

### Phase 1: Visual Anchor Component (M effort)

**New files:**
- `src/components/applications/visual-anchor/VisualAnchor.tsx` — Main component
- `src/components/applications/visual-anchor/AnchorAppNode.tsx` — App node (ghost + lit states)
- `src/components/applications/visual-anchor/AnchorDPNode.tsx` — DP node
- `src/components/applications/visual-anchor/AnchorServiceNode.tsx` — IT Service node
- `src/components/applications/visual-anchor/AnchorIntegrationNode.tsx` — Integration node
- `src/components/applications/visual-anchor/anchor-layout.ts` — Dagre layout config

**Props interface:**
```typescript
interface VisualAnchorProps {
  appName?: string;
  workspace?: string;
  lifecycleStatus?: string;
  deploymentProfile?: {
    hostingType?: string;
    environment?: string;
    region?: string;
    serverName?: string;
    cloudProvider?: string;
  };
  itServices?: Array<{ id: string; name: string; serviceType?: string }>;
  integrations?: Array<{
    appName: string;
    direction: 'upstream' | 'downstream' | 'bidirectional';
    method?: string;
  }>;
  costPath?: 'bundle' | 'it_services' | null;
  onNodeClick?: (section: 'app' | 'dp' | 'cost' | 'integrations') => void;
}
```

**Rules:**
- Component receives form state as props — no database queries
- Uses `@xyflow/react` with `interactionMode="none"` (read-only, no drag/zoom — keep it simple)
- Ghost nodes render when prop is undefined/null; lit nodes render when prop has data
- CSS transitions for ghost → lit (0.3s fade + slight scale)

### Phase 2: Simple Form Wizard (S-M effort)

**New files:**
- `src/components/applications/add-wizard/AddApplicationWizard.tsx` — Wizard shell with step state
- `src/components/applications/add-wizard/StepNameIt.tsx`
- `src/components/applications/add-wizard/StepDeployIt.tsx`
- `src/components/applications/add-wizard/StepCostIt.tsx`
- `src/components/applications/add-wizard/StepConnectIt.tsx`
- `src/components/applications/add-wizard/wizard-types.ts` — Form state interface

**Modified files:**
- `src/components/applications/ApplicationList.tsx` — "Add Application" button opens wizard instead of current modal
- Route: new route `/applications/add` or modal overlay (TBD based on current routing pattern)

**Auto-create logic** (in `wizard-types.ts` or a dedicated `wizard-actions.ts`):
- On save, call Supabase inserts in order: application → deployment_profile → portfolio_assignment → cost bundle DP (if cost entered) → integrations
- All inserts in a single transaction if possible (Supabase JS `rpc` call), or sequential with error handling

### Phase 3: Advanced Form Wiring (S effort)

**Modified files:**
- `src/pages/EditApplication.tsx` (or equivalent) — Add Visual Anchor to right panel
- Detect Simple vs Advanced mode based on app data complexity
- "I need more options" link in Simple mode
- Step indicators in Advanced mode

### Phase 4: Edit Mode Integration (S effort)

- Edit Application opens with Visual Anchor in right panel (always visible)
- Existing tab content shifts to left panel
- Anchor reads from saved data (database queries), not form state
- Anchor updates live as user edits fields

---

## 7. What This Does NOT Change

- **Database schema** — Zero new tables, columns, views, or RLS policies
- **Existing Edit tabs** — They become the "Advanced" form, unchanged in functionality
- **Visual tab** — The full Visual tab (React Flow, 3-level drill-down) remains as a separate feature. The anchor is a lightweight summary, not a replacement
- **Assessment workflow** — Scoring (B1-B10, T01-T15) is not part of Add Application. That's a separate flow triggered from the dashboard
- **Bulk import** — CSV/API import paths are unaffected

---

## 8. Success Criteria

1. **Business owner can add Workday in 60 seconds:** Name → SaaS → $95,000 → Save. Three clicks after typing the name. The anchor shows an app node connected to a cost badge.

2. **IT architect can add Hexagon OnCall in 3 minutes:** Name → On-Prem → skip cost (will use IT Services) → switches to Advanced → wires 6 IT Services → adds 4 integrations. The anchor shows the full blast radius.

3. **The anchor teaches the model:** A new user who has never seen CSDM sees ghost nodes labeled "deployment profile added here" and "IT Service" and absorbs the architecture without reading documentation.

4. **No 18-year-old test failures:** Simple form uses zero jargon. "Where does it run?" not "Hosting Type." "What does it cost?" not "Annual Run Rate."

---

## 9. Design Reference

An interactive HTML mockup demonstrating the progressive reveal is available at:

`features/add-application/visual-anchor-add-application.html`

This mockup shows all 4 steps with the anchor diagram building in real-time. Use it as the visual specification for node styling, colors, and transitions.

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-06 | Initial concept capture. Visual anchor + Simple/Advanced forms. PARKED status — concept only, not scheduled. |
