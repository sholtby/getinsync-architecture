# Main App Navigation Architecture v1.0

**Date:** February 26, 2026  
**Author:** Stuart Holtby  
**Status:** 🟡 PLANNED  
**Depends on:** Main Dashboard Refresh Architecture v1.0  
**Resolves:** Technology Health and Value Creation hidden in Settings

---

## 1. Problem Statement

The main application has no persistent navigation. Users switch between Dashboard, Charts, Applications, and Portfolios via contextual buttons embedded in each view. Technology Health and Value Creation dashboards are only reachable through Settings > Organization, making them invisible to most users.

This creates three problems:

- **Discoverability** — Directors cannot find the dashboards that demonstrate GetInSync's value proposition
- **Demo friction** — showing Technology Health requires navigating to Settings, which breaks the demo narrative
- **No namespace-level landing page** — the main view is always scoped to a single workspace, with no whole-of-organization view

---

## 2. Solution: Top-Level Tab Bar

Add a persistent horizontal tab bar at the top of the main content area with four tabs. This is the primary navigation for the application's analytical views.

```
┌──────────────────────────────────────────────────────────────┐
│  [Logo]  ──────────  [Workspace Switcher] [Portfolio] [User] │
├──────────────────────────────────────────────────────────────┤
│  [Overview]   [Dashboard]   [Technology Health]   [Value Creation]  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│                    Main Content Area                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Tab Definitions

### 3.1 Overview (NEW)

| Attribute | Value |
|-----------|-------|
| **Scope** | Namespace (all workspaces) |
| **Audience** | Director / CIO / CSDM Lead |
| **Content** | KPI cards, assessment completion bar, TIME donut + Technology Lifecycle donut, Needs Attention + Unassessed + Recent Activity |
| **Data source** | `vw_dashboard_summary`, `vw_dashboard_workspace_breakdown`, `vw_technology_health_summary`, `audit_logs` |
| **Filter drawer** | Workspace, TIME Quadrant, Assessment Status, Hosting Type |
| **Header chrome** | Workspace switcher HIDDEN, Portfolio picker HIDDEN |
| **Design spec** | Main Dashboard Refresh Architecture v1.0, §4 |

This is the new landing page after login. Answers "How is my entire portfolio doing?"

### 3.2 Dashboard (EXISTING — renamed from current main view)

| Attribute | Value |
|-----------|-------|
| **Scope** | Workspace + Portfolio |
| **Audience** | Team Lead / Steward / Editor |
| **Content** | KPI cards, TIME/PAID distribution bars, application table (3 patterns), "View Charts" action |
| **Data source** | `portfolio_assignments` joined with `applications` + `deployment_profiles` (via parent `usePortfolioAssignments`) |
| **Filters** | Portfolio, Workspace (when "All"), Lifecycle, Operational Status (via `useDashboardFilters`) |
| **Header chrome** | Workspace switcher VISIBLE, Portfolio picker VISIBLE |
| **Charts sub-view** | "View Charts" button flips to ChartsView (bubble charts). Back button returns to table. Internal to this tab, not a separate tab. |

This is today's dashboard, unchanged in behavior. Answers "How is my department doing?"

### 3.3 Technology Health (PROMOTED from Settings)

| Attribute | Value |
|-----------|-------|
| **Scope** | Namespace (filterable to workspace via built-in filter drawer) |
| **Audience** | All roles with namespace access |
| **Content** | Lifecycle risk donuts, By Application/By Technology/By Server tabs, Needs Profiling intelligence |
| **Data source** | `vw_technology_health_summary`, `vw_technology_tag_lifecycle_risk`, `vw_application_infrastructure_report` |
| **Filter drawer** | Already built — workspace, lifecycle status, hosting type, category |
| **Header chrome** | Workspace switcher HIDDEN (filter drawer handles workspace filtering) |
| **Current route** | `/technology-health` (no change needed) |
| **Current component** | `src/components/technology-health/TechnologyHealthPage.tsx` |

Promoted from Settings > Organization. No component changes needed — just navigation wiring.

### 3.4 Value Creation (PROMOTED from Settings)

| Attribute | Value |
|-----------|-------|
| **Scope** | Namespace (self-organizing scoping via initiative membership) |
| **Audience** | All roles with namespace access |
| **Content** | Initiatives (Gantt/Kanban/Grid), Scorecard, Ideas, Programs |
| **Data source** | `vw_finding_summary`, `vw_initiative_summary`, `vw_idea_summary`, `vw_program_summary` |
| **Filter drawer** | TBD (built during IT Value Creation frontend phase) |
| **Header chrome** | Workspace switcher HIDDEN (scoping is self-organizing per Principle 13) |
| **Current route** | `/value-creation` (no change needed) |
| **Current component** | `src/components/value-creation/ValueCreationPage.tsx` |

Promoted from Settings > Organization. No component changes needed — just navigation wiring.

---

## 4. Header Chrome Behavior

The workspace switcher and portfolio picker in the top header bar change visibility based on the active tab.

| Active Tab | Workspace Switcher | Portfolio Picker | Rationale |
|------------|-------------------|-----------------|-----------|
| Overview | Hidden | Hidden | Namespace scope — no workspace/portfolio filtering needed |
| Dashboard | Visible | Visible | Workspace + portfolio scoping is the core interaction |
| Technology Health | Hidden | Hidden | Has its own filter drawer with workspace filter |
| Value Creation | Hidden | Hidden | Self-organizing scoping, no workspace picker needed |

**Implementation:** The tab bar component communicates the active tab to MainApp, which conditionally renders the workspace switcher and portfolio picker. Alternatively, each tab's page component can signal its header requirements via a prop or context.

---

## 5. Drill-Through Behavior

The Overview tab provides drill-through links into the workspace-scoped Dashboard tab.

| Click Target (in Overview) | Action |
|---------------------------|--------|
| Workspace name in any breakdown table | Set `currentWorkspace` to clicked workspace, switch to Dashboard tab, set portfolio to "All" |
| App name in Needs Attention panel | Navigate to application detail page |
| Activity feed entry | Navigate to affected entity |
| KPI card (Total Applications) | Scroll to breakdown or switch to Dashboard tab |
| Donut slice (TIME distribution) | Apply TIME filter within Overview |
| Donut slice (Technology Lifecycle) | Switch to Technology Health tab with filter applied |

**Key interaction:** Clicking a workspace name in Overview → Dashboard is the primary drill-through. This bridges the namespace "what's happening" view to the workspace "let me work on it" view.

**Implementation:** Drill-through sets state in MainApp:
```typescript
const handleDrillToWorkspace = (workspaceId: string) => {
  setCurrentWorkspace(workspaceId);  // AuthContext
  setSelectedPortfolioId('all');      // Show all portfolios in that workspace
  setActiveTab('dashboard');          // Switch tab
};
```

---

## 6. Routing Changes

### 6.1 Current State

| View | Mechanism |
|------|-----------|
| Dashboard | `mainView === 'dashboard'` (state, no URL) |
| Charts | `mainView === 'charts'` (state, no URL) |
| Applications | `mainView === 'applications'` (state, no URL) |
| Technology Health | `/technology-health` (React Router) |
| Value Creation | `/value-creation` (React Router) |
| Settings | `/settings/*` (React Router) |

Main app views use `mainView` state — no URL routing. This means you can't bookmark or deep-link to a specific tab.

### 6.2 Target State — Phase C (Minimal)

Keep `mainView` pattern, extend it with `activeTab`:

```typescript
type ActiveTab = 'overview' | 'dashboard' | 'technology-health' | 'value-creation';
const [activeTab, setActiveTab] = useState<ActiveTab>('overview');
```

Technology Health and Value Creation render inline (like Dashboard) instead of via React Router. Remove them from Settings sidebar.

### 6.3 Future State (Post-Q1)

Replace `mainView` + `activeTab` with proper URL routing:

| Tab | Route |
|-----|-------|
| Overview | `/` or `/overview` |
| Dashboard | `/workspace/:id` or `/workspace/:id/portfolio/:id` |
| Technology Health | `/technology-health` |
| Value Creation | `/value-creation` |

This enables bookmarking and deep-linking. Deferred to avoid a large routing refactor during Q1.

---

## 7. Settings Sidebar Changes

Remove Technology Health and Value Creation from the Settings > Organization section. They are dashboards, not configuration.

**Before:**
```
ORGANIZATION
├── Namespace
├── Users
├── Vendors & Partners
├── Audit Log
├── Contacts
├── Assessment Configuration
├── Budget
├── Data Centers
├── Technology Health        ← REMOVE
├── Value Creation           ← REMOVE
```

**After:**
```
ORGANIZATION
├── Namespace
├── Users
├── Vendors & Partners
├── Audit Log
├── Contacts
├── Assessment Configuration
├── Budget
├── Data Centers
```

---

## 8. Tab Bar Component Specification

### 8.1 Visual Design

- Horizontal bar below the main header, above content area
- Active tab: bold text, bottom border accent (teal-600 to match existing app accent)
- Inactive tabs: normal weight, gray text
- Match the sub-tab pattern used in Application Detail (General/Deployments/Costs/Integrations/Assessment)
- No icons in tabs — text only, clean and simple

### 8.2 Component Structure

```
src/components/navigation/
├── MainTabBar.tsx          # Tab bar component
└── tabConfig.ts            # Tab definitions (id, label, gating)
```

### 8.3 Role Gating

| Tab | Minimum Role | Tier Gate |
|-----|-------------|-----------|
| Overview | Any namespace member | None |
| Dashboard | Any workspace member | None |
| Technology Health | Any namespace member | None |
| Value Creation | Any namespace member | None |

All tabs visible to all authenticated users. Content within tabs is further gated by workspace role and RLS.

---

## 9. Impact on Existing mainView

The `mainView` type currently has 6 values: `dashboard`, `applications`, `portfolios`, `charts`, `assessment`, `budget`.

**What happens to each:**

| Current mainView | Disposition |
|-----------------|------------|
| `dashboard` | Becomes the "Dashboard" tab content |
| `charts` | Sub-view within Dashboard tab (unchanged — "View Charts" button) |
| `applications` | Remains as a sub-view accessible from Dashboard (or becomes a tab later) |
| `portfolios` | Remains as a sub-view accessible from Dashboard |
| `assessment` | Remains as a sub-view triggered from Dashboard |
| `budget` | Dead code — no rendering logic. Remove. |

**Phase C implementation:** Add `activeTab` state alongside `mainView`. When `activeTab` is `'dashboard'`, the existing `mainView` logic runs as-is. Other tabs render their own page components directly. This avoids rewriting the mainView system.

---

## 10. Implementation Sequence

### Phase C.1: Tab Bar + Overview Shell (0.5 day)
- Create `MainTabBar.tsx`
- Add `activeTab` state to MainApp
- Render tab bar below header
- Overview tab shows placeholder content
- Dashboard tab renders existing mainView logic
- Technology Health tab renders `TechnologyHealthPage` inline
- Value Creation tab renders `ValueCreationPage` inline
- Header chrome (workspace/portfolio pickers) conditionally hidden per §4

### Phase C.2: Remove from Settings (0.5 day)
- Remove Technology Health and Value Creation from Settings sidebar
- Remove their React Router routes (they render inline via tab now)
- Verify Settings page still works without them
- Verify direct URL access (`/technology-health`, `/value-creation`) redirects to main app with correct tab

### Phase C.3: Overview Content (1 day)
- Build the four-row layout from Dashboard Refresh Architecture §4
- KPI cards from `vw_dashboard_summary`
- Assessment completion bar
- TIME donut + Technology Lifecycle donut
- This is the Phase C described in the original architecture doc

### Phase C.4: Action Panels (1 day)
- Needs Attention panel with severity scoring (§6)
- Unassessed Applications panel
- Recent Activity feed
- Filter drawer
- This is Phase D from the original architecture doc

---

## 11. Success Criteria

- [ ] User logs in → lands on Overview tab showing namespace KPIs
- [ ] Tab bar visible on all four tabs, active state clear
- [ ] Clicking workspace name in Overview → switches to Dashboard tab with that workspace selected
- [ ] Workspace switcher and portfolio picker hidden on Overview, visible on Dashboard
- [ ] Technology Health accessible from tab bar (no longer requires Settings)
- [ ] Value Creation accessible from tab bar (no longer requires Settings)
- [ ] Settings sidebar no longer shows Technology Health or Value Creation
- [ ] "View Charts" still works within Dashboard tab
- [ ] All existing Dashboard functionality preserved
- [ ] Passes 18-year-old test — new user understands the four tabs immediately

---

## 12. Document History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | Feb 26, 2026 | Initial architecture. Tab bar structure, drill-through, routing, settings cleanup. |
