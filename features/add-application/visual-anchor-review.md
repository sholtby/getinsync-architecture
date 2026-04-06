# Visual Anchor — Add Application Wizard: Feasibility Review

**Reviewer:** Claude Code
**Date:** April 6, 2026
**Spec reviewed:** `features/add-application/visual-anchor-add-application.md` v1.0
**Status:** Review of PARKED concept — no code written

---

## 1. Feasibility — File Paths, Components, Props

### 1.1 Proposed File Structure: VIABLE

The proposed paths (`src/components/applications/visual-anchor/` and `src/components/applications/add-wizard/`) follow existing conventions. Current `src/components/applications/` contains flat files (e.g., `ApplicationDetailDrawer.tsx`, `DeploymentSummaryCard.tsx`, `CostBundleSection.tsx`), so introducing subdirectories is a minor pattern shift but a reasonable one given the component count.

### 1.2 Props Interface: NEEDS CORRECTIONS

**VisualAnchorProps (spec §6, Phase 1):**

| Field | Issue | Fix |
|-------|-------|-----|
| `workspace?: string` | Should be `workspaceName?: string` for clarity — the existing `AppNodeData.workspace_name` uses the display name, not the workspace ID | Rename to `workspaceName` |
| `lifecycleStatus?: string` | OK but should use the `LifecycleStatus` type if one exists, or at minimum document expected values | Check for existing type |
| `deploymentProfile.hostingType` | Casing mismatch — DB column is `hosting_type`, existing TS type `HostingType` uses PascalCase values (`'SaaS' \| 'On-Prem' \| 'Cloud' \| ...`). Form state will use one convention; be explicit about which | Use `HostingType` from `src/types/index.ts` |
| `integrations[].direction` | Spec says `'upstream' \| 'downstream' \| 'bidirectional'` — matches `integration_direction_types` reference table codes | OK |
| `costPath?: 'bundle' \| 'it_services' \| null` | Good signal for ghost vs. lit state on service tier. Consider adding `'skipped'` to distinguish "user chose to skip" from "user hasn't reached step 3 yet" (`null`) | Add `'skipped'` value |
| `onNodeClick` callback | Good — matches the bidirectional navigation goal in §3.4 | OK |

**Missing from props:**
- `costBundle?: { name?: string; annualCost?: number; vendor?: string }` — needed to show a lit cost badge node in the anchor when Path A is chosen
- `currentStep?: number` — the anchor needs to know which step is active to highlight the corresponding tier (spec §3.2 implies visual distinction per step but props don't carry step state)

### 1.3 React Flow Configuration

The spec proposes `interactionMode="none"` — this is not a valid React Flow prop. The correct approach for a read-only canvas is:

```tsx
<ReactFlow
  nodesDraggable={false}
  nodesConnectable={false}
  elementsSelectable={false}
  panOnDrag={false}
  zoomOnScroll={false}
  zoomOnPinch={false}
  zoomOnDoubleClick={false}
  preventScrolling={false}
/>
```

Or use `<ReactFlow ... proOptions={{ hideAttribution: true }}>` with the above flags. The existing `ConnectionsVisual.tsx` does not use `interactionMode` either — it uses individual flags.

### 1.4 Existing Patterns to Reuse

| What | Where | Reuse strategy |
|------|-------|----------------|
| Node color/border conventions | `src/components/visual/nodes/AppNode.tsx`, `DPNode.tsx`, `ServiceNode.tsx` | Extract shared color constants; anchor nodes share palette but are simpler (no score badges) |
| Dagre layout | `src/components/visual/graphBuilders.ts` `buildLevel2()` | The anchor layout is simpler (always TB, single DP) — write a new lightweight layout function, don't import the full builder |
| `@xyflow/react` | Already in `package.json` | Direct reuse |
| `ApplicationForm.tsx` | `src/components/ApplicationForm.tsx` | The wizard's StepNameIt fields overlap ~80% with ApplicationForm's general section. Extract shared field definitions or accept duplication for now |
| `useDeploymentProfiles` hook | `src/hooks/useDeploymentProfiles.ts` | Reuse `createDeploymentProfile` and update methods |
| `useApplicationPool.createApplication` | `src/hooks/usePortfolios.ts` line 843 | Reuse for step 1 save |

---

## 2. Conflicts with Existing Flows

### 2.1 Edit Application Flow: LOW CONFLICT

The spec (§5.2) says Advanced form = today's Edit Application tabs. This is correct — `ApplicationPage.tsx` renders tabs `general | deployments | connections | visual`. The anchor would be added as a right panel alongside these tabs (Phase 4).

**Potential conflict:** The current `ApplicationPage` is a full-page route. Adding a persistent right panel (340px form + flex anchor) requires reworking the page layout. The existing form uses full page width. This is Phase 4 work and is correctly sized at S effort for the wiring, but the CSS restructuring of `ApplicationPage` into a two-panel layout could ripple into responsive breakpoints.

### 2.2 Visual Tab React Flow: NO CONFLICT

The spec explicitly states (§7): "The full Visual tab remains as a separate feature. The anchor is a lightweight summary, not a replacement." The anchor creates new components (`AnchorAppNode.tsx`, etc.) — it does not modify `ConnectionsVisual.tsx` or the existing node components in `src/components/visual/nodes/`.

The only tension: when anchor is shown in Edit mode (Phase 4), the existing Visual tab becomes redundant for that page. The spec acknowledges this in §5.2 ("Visual Anchor panel replaces the current Visual tab" in wizard mode). Clarify: does Edit mode keep both the Visual tab AND the anchor, or does the anchor replace the Visual tab in Edit mode too?

### 2.3 Add Application Modal: CLARIFICATION NEEDED

The spec references `ApplicationList.tsx` needing modification to open the wizard instead of "current modal." Currently, there is no "add application modal" — the add flow is a full-page route via `ApplicationPage` with no `id` param. The `AddApplicationsModal.tsx` that exists is for adding **existing** apps to a portfolio, not creating new ones.

**Fix:** The spec should say "Add Application button navigates to wizard route `/applications/add`" (or renders the wizard as a full-page overlay), not "opens wizard instead of current modal."

---

## 3. Auto-Create Logic (§4.3) — INSERT ORDER REVIEW

### 3.1 Step 1: applications INSERT — CORRECT

Insert into `applications` with `name, description, lifecycle_status, workspace_id`. RLS requires the user to be a **namespace admin or platform admin** (not just a workspace editor). This is more restrictive than the spec implies.

### 3.2 Step 2: deployment_profiles INSERT — INCORRECT

**Critical finding:** The spec says to INSERT a `deployment_profiles` row. However, a DB trigger (`create_default_deployment_profile`) fires `AFTER INSERT` on `applications` and **automatically creates a primary DP** named `"{app.name} — Region-PROD"`.

The existing code in `ApplicationPage.tsx` handles this with a `setTimeout(100)` wait, then **updates** the auto-created DP rather than inserting a new one:

```typescript
// Current pattern (ApplicationPage line ~523)
await supabase
  .from('deployment_profiles')
  .update({ environment, region, hosting_type, cloud_provider, ... })
  .eq('application_id', newApp.id)
  .eq('is_primary', true);
```

**Fix for spec §4.3 step 2:** Change from "create deployment_profiles row" to "UPDATE the trigger-created primary DP with hosting_type, environment, region, cloud_provider." Or consider disabling the trigger for wizard-created apps and inserting explicitly (more control but higher schema impact — against the "no schema changes" constraint).

**Race condition:** The 100ms setTimeout is a known fragile pattern. The wizard should query for the primary DP after application insert and retry if not yet created, rather than relying on a fixed delay.

### 3.3 Step 3: portfolio_assignments INSERT — CORRECT WITH CAVEATS

The insert order is correct (application and DP must exist first). Two caveats:

1. **RLS blocks NULL deployment_profile_id.** The INSERT policy checks `deployment_profile_id IN (SELECT ...)`. NULL never satisfies an IN clause, so inserts with `deployment_profile_id = NULL` are silently rejected (permission denied, not an error). The wizard must always provide the primary DP's ID.

2. **Namespace trigger validation.** `check_portfolio_assignment_namespace()` fires BEFORE INSERT and verifies that the DP's namespace (via `dp.application_id -> application.workspace_id -> workspace.namespace_id`) matches the portfolio's namespace. Both must be in the current namespace.

### 3.4 Step 4: Cost Bundle DP — TERMINOLOGY FIX

The spec says "cost bundle DP (is_cost_bundle=true)." There is no `is_cost_bundle` column. The correct approach is:

```typescript
await supabase.from('deployment_profiles').insert({
  application_id: appId,
  workspace_id: workspaceId,
  name: `${appName} License`,
  dp_type: 'cost_bundle',      // NOT is_cost_bundle=true
  is_primary: false,
  annual_licensing_cost: amount,
  vendor_org_id: vendorId,
  contract_reference: ref,
  contract_end_date: endDate,
});
```

Cost bundles are `deployment_profiles` rows with `dp_type = 'cost_bundle'`. The existing `DeploymentProfileType` union is `'application' | 'platform_tenant' | 'infrastructure' | 'cost_bundle'`.

### 3.5 Step 5: application_integrations INSERT — CORRECT

Insert `application_integrations` with `source_application_id`, `target_application_id`, `direction`, `integration_method`. The spec correctly notes using primary DPs of both apps for `source_deployment_profile_id` and `target_deployment_profile_id`.

RLS note: this is the only table in the chain where workspace editors (not just namespace admins) can INSERT.

### 3.6 Transaction Support — MISSING FROM SPEC

The spec (§6 Phase 2) mentions "All inserts in a single transaction if possible (Supabase JS `rpc` call), or sequential with error handling." Supabase JS client does **not** support multi-statement transactions. Options:

1. **Sequential inserts with manual rollback** — if step 3 fails, delete the records from steps 1-2. This is the current pattern used elsewhere in the codebase.
2. **Server-side RPC function** — a PostgreSQL function that wraps all inserts in a transaction. This requires a schema change (new function), which conflicts with the spec's "no schema impact" claim.
3. **Accept partial state** — if a later step fails, the user has a partially created application they can complete by editing. This is the pragmatic choice given the "no schema changes" constraint.

**Recommendation:** Option 3 (accept partial state) with clear error toasts at each step. The wizard should save progress incrementally — each step saves its data immediately, not all at the end. This matches user expectations ("I filled in 3 steps, crashed, and lost nothing").

---

## 4. Effort Estimates (§6)

| Phase | Spec Estimate | My Assessment | Rationale |
|-------|---------------|---------------|-----------|
| **Phase 1:** Visual Anchor Component | M | **M** — correct | 6 new files, React Flow integration, ghost/lit state management, Dagre layout, CSS transitions. M is right. |
| **Phase 2:** Simple Form Wizard | S-M | **M** — upgrade from S-M | 6 new files + auto-create logic with trigger race condition, form validation, cost path branching, integration picker with app search, error handling for 5 sequential inserts. This is solidly M. |
| **Phase 3:** Advanced Form Wiring | S | **S** — correct | Mostly wiring existing Edit tabs to detect Simple vs Advanced mode. The "I need more options" link and mode detection are straightforward. |
| **Phase 4:** Edit Mode Integration | S | **S-M** — upgrade from S | Restructuring `ApplicationPage` into a two-panel layout touches a critical page. The anchor must read from database (not form state), requiring a new hook or adapting `useVisualGraphData`. Live updates as user edits means wiring onChange handlers from every form field to anchor props. |

**Total: M + M + S + S-M = approximately L overall** (significant feature, multi-sprint).

---

## 5. Missing Concerns

### 5.1 Authorization / RLS Role Gap — HIGH PRIORITY

The spec does not mention role requirements. Current RLS policies restrict `applications`, `deployment_profiles`, and `portfolio_assignments` INSERT to **namespace admins and platform admins only**. Workspace editors cannot create applications.

If the wizard targets business owners (per Success Criteria §8: "Business owner can add Workday in 60 seconds"), those users are likely workspace editors, not namespace admins. The wizard will fail silently at step 1 with a permission denied error.

**Options:**
1. Accept that only admins can create apps (current behavior)
2. Add RLS INSERT policies for editors on `applications` and `deployment_profiles` (schema change)
3. Use an RPC function with `SECURITY DEFINER` to bypass RLS (schema change)

This must be decided before implementation.

### 5.2 Form Validation — NOT SPECIFIED

The spec lists required fields (Name, Workspace, Hosting Type) but doesn't specify:
- When validation fires (on blur, on step change, on save?)
- Error display pattern (inline, toast, step indicator badges?)
- Whether steps can be visited out of order (clicking step 4 before completing step 1)

**Recommendation:** Validate on "Next" click. Block forward navigation if required fields are empty. Allow backward navigation always. Show inline field errors below each input.

### 5.3 Unsaved Changes Warning — NOT SPECIFIED

No mention of a "You have unsaved changes" prompt when navigating away mid-wizard. The existing `ApplicationForm` uses `onDirtyChange` prop to track this. The wizard should implement the same pattern with `beforeunload` and React Router navigation blocking.

### 5.4 Error Handling / Partial Failure — UNDERSPECIFIED

The spec mentions "error handling" in passing but doesn't define:
- What happens if the application INSERT succeeds but the DP update fails?
- What happens if the integration insert fails for one of N integrations?
- Can the user retry a failed step without starting over?

See §3.6 above — recommend incremental save with partial state acceptance.

### 5.5 Mobile / Responsive — BRIEFLY MENTIONED

The spec says (§3.6): "On viewports below 900px, the anchor is hidden by default." This is fine for the anchor, but doesn't address the wizard form itself. Four-step wizards on mobile need:
- Full-width form fields
- Step indicator that doesn't consume too much vertical space
- Touch-friendly "Next" / "Back" buttons

Not blocking, but should be spec'd before Phase 2.

### 5.6 Accessibility — NOT ADDRESSED

Missing from spec:
- **Keyboard navigation:** Can the user Tab through wizard steps? Arrow-key through the anchor nodes?
- **Screen reader:** Ghost nodes should have `aria-label` text ("Step 2: deployment profile, not yet completed"). Lit nodes should announce their data.
- **Focus management:** When clicking a node to jump to a form step, focus should move to the first field in that step.
- **Step announcements:** `aria-live` region to announce step changes for screen readers.

React Flow has limited built-in a11y. The anchor being read-only simplifies this (no drag interactions to make accessible), but node click-to-navigate needs keyboard support.

### 5.7 Duplicate Application Names — NOT ADDRESSED

No mention of checking for duplicate application names within the workspace before insert. Current `ApplicationForm` doesn't check either, but the wizard's simplified flow makes accidental duplicates more likely (e.g., user doesn't realize "Workday" already exists).

**Recommendation:** On step 1 blur of the name field, query `applications` for existing names in the workspace and show a warning (not a block — duplicates may be intentional for different DPs).

### 5.8 "Default Portfolio" Detection — VAGUE

§4.3 step 3 says "portfolio_assignments row if a default portfolio exists for the workspace." How is the default portfolio determined? There is no `is_default` flag on the `portfolios` table. Options:
- First portfolio in the workspace (by `created_at`)
- Portfolio the user navigated from (if they came from a portfolio page)
- User's "home" portfolio (not currently a concept)

This needs a design decision.

### 5.9 Back-Navigation from Advanced to Simple — EDGE CASE

§5.3 says switching Advanced -> Simple is allowed only if no Advanced-level data exists. But what if the user:
1. Starts in Simple mode
2. Clicks "I need more options" (switches to Advanced)
3. Adds an IT Service
4. Deletes the IT Service
5. Tries to go back to Simple

Is this allowed? The data is gone, but the user "touched" Advanced mode. Recommend: check actual data state, not mode history.

---

## 6. Summary of Required Corrections

| # | Section | Severity | Issue | Fix |
|---|---------|----------|-------|-----|
| 1 | §4.3 step 2 | **HIGH** | Spec says INSERT DP; trigger auto-creates it | Change to UPDATE the trigger-created primary DP |
| 2 | §4.3 step 4 | **MED** | `is_cost_bundle=true` doesn't exist | Use `dp_type = 'cost_bundle'` |
| 3 | §6 Phase 1 | **MED** | `interactionMode="none"` not a valid React Flow prop | Use individual flags: `nodesDraggable={false}`, etc. |
| 4 | §6 Phase 2 | **MED** | Spec references "current modal" for ApplicationList | No modal exists; add flow is a full-page route |
| 5 | §4.3 step 3 | **MED** | "Default portfolio" concept undefined | Define how default portfolio is determined |
| 6 | — | **HIGH** | RLS restricts app creation to namespace admins only | Decide if editors should create apps; may need schema change |
| 7 | §4.3 | **MED** | No transaction support; partial failure unhandled | Design incremental save with error recovery |
| 8 | §6 | **LOW** | Phase 2 undersized at S-M; Phase 4 undersized at S | Phase 2 = M, Phase 4 = S-M |
| 9 | Props | **LOW** | Missing `costBundle` and `currentStep` props | Add to interface |
| 10 | — | **LOW** | No duplicate name check, no unsaved changes warning | Add to spec |

---

## 7. Verdict

The concept is solid and well-structured. The Visual Anchor as a teaching tool is a strong UX idea, and the Simple/Advanced split correctly addresses the "QuickBooks for CSDM" vision. The 4-step wizard maps cleanly to the data model.

**Before scheduling for implementation, resolve:**
1. The DP auto-create trigger interaction (§3.2 above) — this is the most likely source of bugs
2. The RLS role gap for non-admin users (§5.1) — blocks the primary persona
3. The "default portfolio" logic (§5.8) — affects auto-create chain
4. Transaction/partial-failure strategy (§3.6) — affects wizard save architecture

Everything else can be resolved during implementation.

---

*Review complete. No code written.*
