# Session 5b (OPTIONAL): Assessment Wizard — Plan Capture Panel

**Effort:** 1 hr. **Prerequisite:** Session 5 merged (shared `useUpdatePortfolioPlan` hook exists). **Committable:** yes — additive to the wizard. **Deferrable to Tier 1.5** if the rest of Tier 1 needs to ship first.

## Goal

Add a post-completion summary card to `PortfolioAssessmentWizard.tsx` that appears after both Business and Technical assessments reach `complete`. Captures plan-status fields inline with the assessment flow so the data gets created during the workshop rather than as a follow-up drawer edit.

## Why this is optional

Session 5 already delivers plan-status data capture via the drawer's inline edit. Session 5b is a UX refinement — it puts capture at the natural point in the workflow (immediately after scoring). Users who assess first and plan later can use the drawer; users who want the full workshop in one place benefit from the wizard panel.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` §Section 1 Session 5b — full spec.
2. `src/components/PortfolioAssessmentWizard.tsx` — entire file. Wizard flow: two tabs (Business B1–B10, Technical T01–T15), linear factor flow, Save panel at the bottom.
3. `src/hooks/useUpdatePortfolioPlan.ts` — the mutation hook from Session 4.
4. `src/components/applications/profile/LifecyclePositionBlock.tsx` — reuse the Response Plan edit form components if they're already extracted; otherwise extract them first and reuse here.
5. `src/components/shared/` — existing form primitives (label, input, textarea, date picker) to reuse.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** Does not apply directly here (the wizard captures plan-status, not PAID), but never emit `Improve` or `Divest` anywhere.
- **Additive to the wizard.** Do not disturb factor-scoring behavior or the Save panel.
- **Reuse, don't re-write.** If Session 5 extracted an inline plan editor, extract it into a shared component and reuse it here. Do not duplicate the tri-state/textarea/URL/date controls.

## Concrete changes

### 1. Extract a shared `ResponsePlanEditor` (if not already done in Session 5)

If `src/components/applications/profile/LifecyclePositionBlock.tsx` has the edit form inlined, extract it:

- New file: `src/components/applications/profile/ResponsePlanEditor.tsx`.
- Props: `{ portfolioAssignmentId, initialValues, onSaved }`.
- Controls: tri-state toggle (Yes/No/Unknown → `true`/`false`/`null`), textarea for `plan_note`, URL input for `plan_document_url`, date picker for `planned_remediation_date`.
- Save button calls `useUpdatePortfolioPlan(portfolioAssignmentId).update(...)`, then `onSaved()`.
- Toast on success / error per CLAUDE.md.

Session 5's `LifecyclePositionBlock` then imports `ResponsePlanEditor` for its inline-edit path. No behavior change — this is mechanical refactor.

### 2. Add the wizard post-completion card

In `PortfolioAssessmentWizard.tsx`:

- Determine completion state from the existing wizard state — a "both complete" boolean:
  ```typescript
  const bothComplete =
    businessAssessmentStatus === 'complete' &&
    techAssessmentStatus === 'complete';
  ```
- When `bothComplete` is true, render a new "Plan status" card below the existing Save panel area (~lines 720–740 per exploration).
- The card uses `ResponsePlanEditor` with the current assessment's `portfolioAssignmentId` and the initial values fetched from `portfolio_assignments` (extend the existing wizard data fetch by one join, or add a small `useEffect` that reads the four plan fields when the card mounts).
- Heading: "Plan status". Subheading: "Capture workshop-surfaced information about whether this application has a documented plan."
- Once saved, the card stays visible with updated values — don't hide it. The user can edit again.

### 3. Wizard flow unchanged

- No new tab.
- No change to factor scoring.
- The card simply appears once both assessments are complete, at the bottom of the wizard.

### 4. Test the round-trip

- Complete both assessments for a test app.
- Fill in the plan-status card and save.
- Close the wizard.
- Open the drawer on the same app → Response Plan sub-section (Block 7) shows the persisted values.
- Re-open the wizard → card shows the persisted values.

## Exit criteria

1. `cd ~/Dev/getinsync-nextgen-ag && npx tsc --noEmit` → zero errors.
2. Completing a portfolio assessment in the wizard with both tabs `complete` reveals the plan-status card.
3. Saving the card persists the four fields to `portfolio_assignments`; re-opening the wizard shows persisted values.
4. The drawer's Block 7 Response Plan sub-section reflects the same values (round-trip through `vw_application_profile`).
5. `ResponsePlanEditor` is imported by both `LifecyclePositionBlock` and `PortfolioAssessmentWizard` — no duplicated form code.
6. No regression to the wizard's existing factor-scoring flow.

## Git

- **Code repo:** commit on `feat/application-profile-tier-1`. Message: `feat: wizard plan capture panel (Session 5b — Tier 1.5)`. Push.
- **Architecture repo:** no changes this session.

## Stuck?

- If the wizard's state shape makes "both complete" detection awkward, add a small derived selector or `useMemo` — don't refactor the state machine.
- If `ResponsePlanEditor` extraction causes churn in Session 5's drawer, consider timing: do Session 5b before Session 5 finalizes, so the extraction happens once.
- The wizard's existing Save button writes to both `portfolio_assignments` (business) and `deployment_profiles` (technical). The plan-status card writes ONLY to `portfolio_assignments` — do not try to coordinate with the wizard's Save. Independent mutation.
