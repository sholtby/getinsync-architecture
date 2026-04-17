# Session 5: `ApplicationDetailDrawer` Evolution + Block Extraction

**Effort:** 3–4 hrs. **Prerequisite:** Session 4 merged. **Committable:** yes — ships the full drawer.

## Goal

Evolve `ApplicationDetailDrawer.tsx` to consume `useApplicationProfile` and render every Tier 1 field. **Subcomponent extraction is mandatory** — one component per block under `src/components/applications/profile/`. Drawer becomes a thin orchestrator (<400 lines).

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` §Section 1 Session 5 — the full block list with specific rendering instructions per block.
2. `docs-architecture/features/application-profile/schema-mapping.md` v1.1 — field-by-field source of truth for what renders where.
3. `src/components/applications/ApplicationDetailDrawer.tsx` — today's drawer. Refactor in place; do not fork.
4. `src/hooks/useApplicationProfile.ts`, `src/hooks/useApplicationNarrativeCache.ts`, `src/hooks/useUpdatePortfolioPlan.ts` — Session 4 hooks.
5. `src/hooks/useApplicationDetail.ts` — keep for cost/server data (not migrated to the profile view).
6. `src/components/SoftwareProductModal.tsx`, `src/components/TechnologyProductModal.tsx` — established `<a target="_blank" rel="noopener noreferrer">` pattern for external document links (reused for `plan_document_url`).
7. `src/components/dashboard/DashboardPage.tsx` — category rendering pattern.
8. `CLAUDE.md` — error handling, no `alert()`/`confirm()`, grid pagination rules (not applicable here), loading state rules.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** The Block 7 renderer must never emit `Improve` or `Divest`. Use the `PaidAction` union from Session 3.
- **Mandatory subcomponent extraction.** Do NOT cram blocks into the drawer file. 11 blocks in one file crosses 800 lines — extract up front.
- **Block components receive data via props.** They do not call hooks themselves. The drawer orchestrates hook calls and passes the relevant slice of `VwApplicationProfile` plus any matching narrative cache entry.
- **PAID/TIME placement:** canonical strings are lowercase in DB. When rendering, title-case for display.

## Concrete changes

### 1. Create `src/components/applications/profile/` directory

One file per block (mandatory). Files to create:

| File | Block | Renders |
|---|---|---|
| `IdentityBlock.tsx` | 1 Identity | `application_name`, `acronym` (parenthetical if present), `operational_status` badge, `plain_language_summary` from narrative cache (approved) → fallback to `short_description` → empty-state CTA. |
| `BusinessPurposeBlock.tsx` | 2 Business Purpose | `business_outcome` text + `category_names` as tag chips (`category_name` label, `category_code` tooltip). Small "Capabilities — coming in Tier 2" placeholder beneath. |
| `UserCommunityBlock.tsx` | 3 User Community | `user_groups` as chips, `estimated_user_count` bucket, `serving_area`. |
| `OwnershipBlock.tsx` | 5 Ownership | Four contact roles (business owner, application owner, accountable executive, technical contact). Role badges. Click-to-edit link. |
| `CriticalityBlock.tsx` | 6 Criticality | `criticality`, `is_crown_jewel` badge, `business_impact_statement` narrative. |
| `LifecyclePositionBlock.tsx` | 7 Lifecycle Position | `time_quadrant`, `paid_action` (use `PaidAction` union — Plan/Address/Delay/Ignore only), `lifecycle_status`, `time_paid_tension_flag` visual cue + narrative. **Response Plan sub-section** — see below. |
| `ApplicationContextBlock.tsx` | 8 Context | Upstream/downstream integration lists with `business_purpose` edge labels (fallback to `integration.name`). `integration_summary` narrative. Visual diagram unchanged (keep `vw_integration_detail` 1-hop query). |
| `CostSummaryBlock.tsx` | 9 Cost | `annual_licensing_cost`, `annual_tech_cost`, `total_cost_of_ownership`, `cost_notes`. No role gating this session. |
| `TechDebtBlock.tsx` | 10 Tech Debt & Remediation | `remediation_status_rollup` badge, `linked_initiative_count`, `estimated_remediation_cost_{low,high}` ROM range, `target_state`, `remediation_summary` + `remediation_alignment` narratives. Tech debt ITEMS list → "Item-level tech debt coming in Tier 2" placeholder. |
| `AssessmentContextBlock.tsx` | 11 Assessment Context | Four scores (business_fit, tech_health, tech_risk, criticality) with `near_threshold_flag` indicators. `latest_assessed_at`, `assessment_completeness_rollup` badge. |

Block 4 Information Domains is a one-liner — inline a "Information domain tagging coming in Tier 2." placeholder in the drawer itself, no separate file.

### 2. Refactor `ApplicationDetailDrawer.tsx` to orchestrator shape

Target shape (pseudocode):

```tsx
export function ApplicationDetailDrawer({ applicationId, onClose }: Props) {
  const { profile, loading, error } = useApplicationProfile(applicationId);
  const { narratives, ...narrativeActions } = useApplicationNarrativeCache(applicationId);
  // existing cost/server hooks
  const costDetail = useApplicationDetail(applicationId);

  if (loading) return <Spinner />;
  if (error) return <ErrorState error={error} />;
  if (!profile) return <EmptyState />;

  return (
    <Drawer onClose={onClose}>
      <IdentityBlock profile={profile} narratives={narratives} />
      <BusinessPurposeBlock profile={profile} />
      <UserCommunityBlock profile={profile} />
      <InformationDomainsPlaceholder />
      <OwnershipBlock profile={profile} />
      <CriticalityBlock profile={profile} narratives={narratives} />
      <LifecyclePositionBlock
        profile={profile}
        narratives={narratives}
        portfolioAssignmentId={/* resolve from profile */}
      />
      <ApplicationContextBlock profile={profile} narratives={narratives} />
      <CostSummaryBlock profile={profile} costDetail={costDetail} />
      <TechDebtBlock profile={profile} narratives={narratives} />
      <AssessmentContextBlock profile={profile} />
    </Drawer>
  );
}
```

The drawer stays **under 400 lines**. Each block component aims for under 150 lines as a soft target.

### 3. `LifecyclePositionBlock` — Response Plan sub-section detail

This is the only interactive sub-section in Tier 1. Render tri-state + inline edit:

- `has_plan === null` → grey "Plan status: not yet asked" with CTA button "Capture plan status".
- `has_plan === false` → amber "No plan" badge; show `plan_note` if present, labeled "Context".
- `has_plan === true` → green "Plan documented" badge; show `plan_note`, `plan_document_url` as `<a target="_blank" rel="noopener noreferrer">View plan document</a>`, and `planned_remediation_date` if set.

Clicking the sub-section opens an inline edit form — tri-state toggle (Yes/No/Unknown → `true`/`false`/`null`), textarea for `plan_note`, URL input for `plan_document_url` (basic URL validation), date picker for `planned_remediation_date`. Save calls `useUpdatePortfolioPlan(portfolioAssignmentId).update(...)`, then the drawer refetches.

**Tier 2 enhancement (deferred, do not build):** when `has_plan === true` but no `initiative_deployment_profiles` row links this DP, surface "Link an initiative?" prompt. Deferred because Block 10 initiative-to-DP rendering is Tier 2.

### 4. Narrative empty-states

Where a block expects a narrative (e.g., `plain_language_summary` in Identity, `business_impact_statement` in Criticality, `integration_summary` in Context, `time_paid_tension` narrative in Block 7, `remediation_summary` + `remediation_alignment` in Block 10):

- If the narrative cache has an entry for that key → render `content`.
- Else → render placeholder "No summary yet. [Generate]" with the Generate button **disabled** and a tooltip "Narrative generation ships in Tier 2."

The Generate button does nothing in Tier 1 — it's a visual affordance only.

### 5. Category chip pattern (Block 2)

Reuse the pattern from [src/components/dashboard/DashboardPage.tsx:79](src/components/dashboard/DashboardPage.tsx:79). Map `profile.category_names` to chip components. Empty array → render nothing (no placeholder). Always sort by `category_name` for stable ordering.

### 6. Preview verification

Start the dev server and open the drawer on three test apps:

- Fully populated app (most blocks non-empty).
- Sparse app (many blocks empty — verify empty states, not broken).
- Crown jewel app (verify badge renders).

Capture screenshots via the Claude Preview MCP tools if available, or manually. Regression check: open the drawer from Explorer, Dashboard, Visual tab — all entry points still work.

## Exit criteria

1. `cd ~/Dev/getinsync-nextgen-ag && npx tsc --noEmit` → zero errors.
2. `ApplicationDetailDrawer.tsx` is under 400 lines.
3. Each block file exists and is under ~250 lines.
4. Dev server at `http://localhost:5173` — drawer renders every block for at least 3 test apps without regressions.
5. Inline edit of Response Plan (Block 7) round-trips: write from drawer → re-open drawer → values persisted.
6. `grep -rn "alert(\|confirm(" src/components/applications/` — zero new occurrences.
7. `grep -rn "Improve\|Divest" src/components/applications/profile/` — zero occurrences (except canonical-rule comments).
8. Existing drawer users (Explorer, Dashboard, Visual tab entry points) still work.

## Git

- **Code repo:** commit on `feat/application-profile-tier-1`. Suggested chunking: one commit for block-component extraction (mechanical refactor, no behavior change), a second commit for the Response Plan sub-section + inline edit. Message examples:
  - `refactor: extract ApplicationProfile block components (Session 5 of 6)`
  - `feat: Block 7 Response Plan sub-section with inline edit (Session 5 of 6)`
- **Architecture repo:** no changes this session.

## Stuck?

- If a block is growing past 250 lines, split its data presentation from its edit interactions (`LifecyclePositionBlock.tsx` + `ResponsePlanEditor.tsx`, for example).
- If the drawer's re-render performance degrades, memoize block props with `useMemo` — cheap win.
- For the inline edit form styling, reuse existing form primitives in `src/components/` (label, input, textarea, date picker). Don't introduce a new form library.
- Narrative rendering empty-states should feel inviting, not broken. "No summary yet — generation lands in Tier 2" beats "Loading...".
