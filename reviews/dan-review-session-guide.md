# Dan Warfield UX Review — Claude Code Session Guide

**Version:** 1.0
**Date:** April 4, 2026
**Companion to:** `reviews/dan-warfield-ux-review-findings.md`

---

## How to Use This Document

Each "chunk" below is a self-contained Claude Code session. Copy the prompt block into a new Claude Code window.

**Rules:**
- Run chunks in order — each lists prerequisites
- Chunk 4 produces a SQL script for Stuart to review and execute in Supabase SQL Editor
- After running SQL, tell Claude "schema done" — it will run the checkpoint automatically
- Frontend chunks create feature branches — merge to `dev` when complete
- If a session runs out of context, start a new window with the continuation prompt provided
- Chunks 1 and 2 can be combined into a single session if desired

**Estimated total:** 5 chunks across ~6-10 hours of Claude Code time

---

## Chunk 1 — Frontend: Quick Wins (Icon + Card Order)

**Prerequisites:** None
**Findings Report:** Points 5 and 6
**Branch:** `feat/dan-review-quick-wins`
**Effort:** XS (~30 min)

```
Read this before starting:
- docs-architecture/reviews/dan-warfield-ux-review-findings.md (Points 5 and 6)

We're implementing two quick UX fixes from an external review.
Create a feature branch from dev: feat/dan-review-quick-wins

Task 1 — Filter icon swap (Point 6)

In src/constants/icons.ts, the ACTION_ICONS.filter currently maps to
lucide's Filter (funnel icon). Change it to SlidersHorizontal.

Verify: grep for all usages of ACTION_ICONS.filter across the codebase
to confirm this single change propagates correctly. Also check that
SlidersHorizontal is already imported from lucide-react — if not, add
the import.

Note: SlidersHorizontal is already used in some filter DRAWER headers.
This change makes filter buttons consistent with drawer headers.

Task 2 — KPI card reorder (Point 5)

In src/components/overview/OverviewKpiCards.tsx, reorder the KPI cards
from the current order:
  1. Applications  2. Fully Assessed  3. Annual Run Rate  4. Crown Jewels  5. At Risk

To this order (leading with action):
  1. At Risk  2. Applications  3. Fully Assessed  4. Crown Jewels  5. Annual Run Rate

This is an array reorder — the card definitions should already be in
an array or sequential JSX. Reorder them.

After both tasks, run tsc --noEmit to verify clean compile.
Merge to dev when complete.
```

---

## Chunk 2 — Frontend: Scope Bar UX (Overview Clarity + Namespace Grouping)

**Prerequisites:** Chunk 1 merged to dev
**Findings Report:** Points 1 and 7
**Branch:** `feat/dan-review-scope-bar`
**Effort:** S (~1-2 hours)

```
Read this before starting:
- docs-architecture/reviews/dan-warfield-ux-review-findings.md (Points 1 and 7)

We're fixing two related scope bar issues from an external UX review.
Create a feature branch from dev: feat/dan-review-scope-bar

Context: The Overview tab is intentionally namespace-level — it always
shows aggregated data across all workspaces. The page heading already says
"All of My Workspaces" with subtitle "Aggregated view across your workspaces."
But a first-time user tested the product and expected the scope bar (workspace
+ portfolio dropdowns) to filter the Overview. The existing 40% opacity
dimming was not enough to communicate that the scope bar doesn't apply here.

Task 1 — Hide scope bar on Overview tab (Point 7)

In src/App.tsx (around line 606), the scope bar container currently gets
opacity-40 and pointer-events-none when activeTab === 'overview'.

Change this: instead of dimming the scope bar, HIDE it entirely on the
Overview tab. The "All of My Workspaces" heading and card sublabels
already communicate the namespace-level scope — the dimmed scope bar
contradicts that message by implying a filtered view.

Implementation: conditionally render the scope bar container only when
activeTab !== 'overview'. Keep the Search, Help, AI icons, and User
Menu visible — only hide the WorkspaceSwitcher and SmartPortfolioHeader.

Verify: Navigate between Overview and other tabs — scope bar should
appear/disappear smoothly. Confirm the header doesn't collapse or
shift awkwardly when the scope bar is hidden.

Task 2 — Add namespace name to scope bar (Point 1)

When the scope bar IS visible (all tabs except Overview), add the
namespace name as a prefix label before the WorkspaceSwitcher. Use
a subtle divider between the namespace name and the dropdowns:

  [City of Riverside  |  Workspace ▼  Portfolio ▼]

The namespace name should be styled as a non-interactive label
(text-sm text-gray-500 or similar — not a dropdown, not clickable).
It serves as context, not a control. Use a border-r border-gray-300
or similar divider.

Find the namespace name: it's already available in the app — check
how WorkspaceBanner.tsx accesses it (likely from ScopeContext or a
namespace query).

After both tasks:
- Verify Overview shows no scope bar, just the heading
- Verify App Health / Tech Health / etc. show namespace + scope bar
- Run tsc --noEmit
- Merge to dev when complete
```

**Continuation prompt (if session runs out of context):**

```
Continuing work from a previous session.
Branch: feat/dan-review-scope-bar
Read: docs-architecture/reviews/dan-warfield-ux-review-findings.md (Points 1 and 7)

Completed: [list what was done]
Remaining: [list what's left from tasks 1-2]
```

---

## Chunk 3 — Frontend: Overview Card Drill-Down to Explorer

**Prerequisites:** Chunk 2 merged to dev
**Findings Report:** Points 3, 4, and 5 (click targets)
**Branch:** `feat/dan-review-card-drilldown`
**Effort:** M (~3-5 hours)

```
Read this before starting:
- docs-architecture/reviews/dan-warfield-ux-review-findings.md (Points 3, 4, and 5)
- src/components/overview/OverviewKpiCards.tsx (the cards)
- src/hooks/useExplorerData.ts (ExplorerFilters interface)
- src/contexts/ScopeContext.tsx (current scope state)

We're making all 5 Overview KPI cards clickable, with drill-down to
Explorer (or IT Spend for the cost card). This is the highest-impact
UX fix from the external review.

Create a feature branch from dev: feat/dan-review-card-drilldown

The work has two parts: plumbing (filter state passing) and wiring
(card click handlers).

Part A — Filter state plumbing

Explorer currently reads filters from component-level useState only.
There is no mechanism to pass initial filters when navigating from
another tab.

Add a pendingExplorerFilters field to ScopeContext:
- Type: Partial<ExplorerFilters> | null
- Default: null
- Setter: setPendingExplorerFilters

In the Explorer component (find the main Explorer page component),
on mount:
- Check if pendingExplorerFilters is non-null
- If so, merge it into the local filter state
- Clear pendingExplorerFilters after consuming (so it doesn't
  persist on re-render)

This pattern allows any component to pre-set Explorer filters
before navigating to the Explorer tab.

Part B — Card click handlers

In OverviewKpiCards.tsx, add onClick handlers to all 5 cards:

| Card | Click Action |
|------|-------------|
| At Risk | setPendingExplorerFilters({ timeQuadrant: ['Modernize', 'Eliminate'] }) → setActiveTab('explorer') |
| Applications | setPendingExplorerFilters({}) → setActiveTab('explorer') (no filter — show all) |
| Fully Assessed | setPendingExplorerFilters({ techAssessmentStatus: 'complete' }) → setActiveTab('explorer') |
| Crown Jewels | setPendingExplorerFilters({ crownJewel: 'yes' }) → setActiveTab('explorer') |
| Annual Run Rate | setActiveTab('itspend') (no Explorer filter — navigate to IT Spend tab) |

Important: Check the ExplorerFilters interface for exact field names
and types. The timeQuadrant filter currently takes a single string —
for "At Risk" we need Modernize + Eliminate. If timeQuadrant is
string | null, you'll need to change it to string[] | null to support
multi-select. Update useExplorerData.ts filtering logic accordingly.

Similarly, check if techAssessmentStatus is already a filter field
in ExplorerFilters. If not, add it.

Part C — Visual affordance

Add interactive styling to all 5 cards:
  cursor-pointer hover:shadow-md hover:border-teal-200 transition-all

Cards should feel clickable — subtle scale or shadow on hover.

After all tasks:
- Test each card click: does it navigate to Explorer with the
  correct filter pre-applied?
- Test Annual Run Rate: does it navigate to IT Spend?
- Test that Explorer clears the pending filters after consuming
  (navigating away and back should show unfiltered Explorer)
- Run tsc --noEmit
- Merge to dev when complete
```

**Continuation prompt (if session runs out of context):**

```
Continuing work from a previous session.
Branch: feat/dan-review-card-drilldown
Read: docs-architecture/reviews/dan-warfield-ux-review-findings.md (Points 3, 4, 5)

Completed: [list what was done]
Remaining: [list what's left from Parts A-C]

ScopeContext changes: [describe what was added — pendingExplorerFilters
field, type, setter]
```

---

## Chunk 4 — DB: Assessment Staleness Schema

**Prerequisites:** None (can run independently or alongside Chunks 1-3)
**Findings Report:** Point 2 (schema portion)
**Output:** SQL script for Stuart to run in Supabase SQL Editor
**Effort:** S (~1 hour)

```
Read this before starting:
- docs-architecture/reviews/dan-warfield-ux-review-findings.md (Point 2)
- docs-architecture/schema/nextgen-schema-current.sql (current schema)

Task: Generate a SQL script for assessment staleness schema changes.
I will review and run this in Supabase SQL Editor — do NOT execute any SQL.

Context: deployment_profiles already has an assessed_at column (timestamptz,
set when tech assessment is saved). However, portfolio_assignments has NO
equivalent timestamp for business assessment. And no view currently exposes
assessed_at for staleness queries.

The script must include, in order:

1. ALTER TABLE portfolio_assignments — add column:
   - business_assessed_at (timestamptz, nullable)
   COMMENT: 'Timestamp of last business assessment save (b1-b10 scores)'

2. Verify deployment_profiles.assessed_at exists (SELECT from
   information_schema.columns). If it exists, proceed. If not, flag
   for Stuart — do NOT create it without verification.

3. ALTER VIEW vw_explorer_detail — add two columns:
   - assessed_at (from deployment_profiles)
   - business_assessed_at (from portfolio_assignments)
   Read the current view definition via DATABASE_READONLY_URL first.
   Recreate the view with the two new columns appended. Preserve
   security_invoker = true and all existing GRANTs.

4. ALTER VIEW vw_dashboard_summary_scoped — add staleness aggregates:
   - oldest_tech_assessment (MIN of dp.assessed_at across namespace)
   - stale_tech_count (COUNT where assessed_at < NOW() - interval '90 days'
     AND assessed_at IS NOT NULL — only count assessed items that are stale,
     not items never assessed)
   Read the current view definition first. Recreate with new columns.
   Preserve security_invoker = true and all existing GRANTs.

5. Update view-contracts.ts types — output the TypeScript interface
   changes needed for VwExplorerDetail and VwDashboardSummaryScoped
   (do NOT modify the file — just output what needs to change so I can
   verify alignment).

After generating the script:
- Verify all column references against the current schema
- Confirm the views compile by checking JOIN paths
- Output the complete script in a single code block ready for copy-paste

Do NOT create a feature branch. This is a DB-only session.
```

**After Stuart runs the SQL:**

```
Schema done for Assessment Staleness. The following were applied:
- business_assessed_at column on portfolio_assignments
- vw_explorer_detail updated with assessed_at + business_assessed_at
- vw_dashboard_summary_scoped updated with staleness aggregates

Run mid-session schema checkpoint.
```

---

## Chunk 5 — Frontend: Assessment Status + Staleness UI

**Prerequisites:** Chunk 4 SQL applied and checkpoint passed. Chunk 3 merged to dev (Explorer filter infrastructure in place).
**Findings Report:** Point 2 (frontend portion)
**Branch:** `feat/dan-review-assessment-staleness`
**Effort:** M (~2-4 hours)

```
Read this before starting:
- docs-architecture/reviews/dan-warfield-ux-review-findings.md (Point 2)
- src/components/overview/AssessmentCompletionBar.tsx (current component)
- src/hooks/useExplorerData.ts (Explorer filters — should already have
  pendingExplorerFilters support from Chunk 3)

Context: The schema now includes:
- deployment_profiles.assessed_at (already existed)
- portfolio_assignments.business_assessed_at (newly added)
- vw_explorer_detail now exposes both timestamps
- vw_dashboard_summary_scoped now has oldest_tech_assessment and
  stale_tech_count aggregates

Create a feature branch from dev: feat/dan-review-assessment-staleness

Task 1 — Rename "Assessment Progress" to "Assessment Status"

In AssessmentCompletionBar.tsx, change the heading from
"Assessment Progress" to "Assessment Status".

Task 2 — Add staleness indicator

Below the existing progress bar, add a staleness summary row.
Query the stale_tech_count from the dashboard summary view.

If stale_tech_count > 0, show:
  ⚠️ X assessments older than 90 days

Style: amber/warning color, text-sm. If stale_tech_count is 0, show:
  ✓ All assessments current

Style: green/success color, text-sm.

Clicking the staleness warning should drill down to Explorer
filtered to show stale items. Use the same pendingExplorerFilters
pattern from Chunk 3. You'll need to add a staleness filter to
ExplorerFilters — something like:
  staleOnly: boolean (filters where assessed_at < NOW() - 90 days)

Task 3 — Set business_assessed_at on save

Find where business scores (b1-b10) are saved to portfolio_assignments.
Check useDeploymentProfiles.ts or similar hooks — look for the UPDATE
that writes b1-b10 scores. Add business_assessed_at: new Date().toISOString()
to that same UPDATE call.

Verify: Check how assessed_at is set on deployment_profiles for
the tech assessment save — mirror that pattern exactly for
business_assessed_at on portfolio_assignments.

Task 4 — Explorer: "Last Assessed" column

In the Explorer table, add a "Last Assessed" column showing the
most recent of assessed_at and business_assessed_at (whichever is
more recent, or whichever exists). Format as relative time
("3 days ago", "2 months ago") or date.

Make the column sortable. Default sort order should be oldest-first
when this column is actively sorted (surface the stalest items).

Task 5 — Update TypeScript types

Update src/types/view-contracts.ts:
- VwExplorerDetail: add assessed_at (string | null) and
  business_assessed_at (string | null)
- VwDashboardSummaryScoped: add oldest_tech_assessment (string | null)
  and stale_tech_count (number)

Grep for all consumers to verify no type errors.

After all tasks:
- Verify "Assessment Status" label on Overview
- Verify staleness warning appears when stale items exist
- Verify Explorer "Last Assessed" column sorts correctly
- Verify clicking the staleness warning navigates to Explorer
  with stale items filtered
- Run tsc --noEmit
- Merge to dev when complete
```

**Continuation prompt (if session runs out of context):**

```
Continuing work from a previous session.
Branch: feat/dan-review-assessment-staleness
Read: docs-architecture/reviews/dan-warfield-ux-review-findings.md (Point 2)

Completed: [list what was done]
Remaining: [list what's left from tasks 1-5]

Schema is deployed: business_assessed_at on portfolio_assignments,
vw_explorer_detail and vw_dashboard_summary_scoped updated with
staleness columns. Do NOT generate SQL.
```

---

## Quick Reference — Post-Implementation Verification

After all 5 chunks are complete, do a full walkthrough as Dan would:

```
Verification checklist:
1. Open Overview — no scope bar visible, heading says "All of My Workspaces"
2. Navigate to App Health — scope bar appears with namespace name prefix
3. On Overview, click "At Risk" card — lands on Explorer filtered to
   Modernize + Eliminate
4. On Overview, click "Crown Jewels" — lands on Explorer filtered to
   crown jewels
5. On Overview, click "Applications" — lands on Explorer, no filter
6. On Overview, click "Annual Run Rate" — lands on IT Spend tab
7. Filter icons across all tabs show sliders, not funnels
8. KPI card order: At Risk first, Annual Run Rate last
9. Assessment section says "Assessment Status" not "Assessment Progress"
10. If stale assessments exist, warning shows with drill-down link
11. Explorer has "Last Assessed" column, sortable
```

---

## Items NOT in This Session Guide

These items from Dan's review are **narrative/strategic**, not code tasks:

- **Data import UX** (Point 8 from triage) — self-serve spreadsheet import is a roadmap item. Import infrastructure exists (Garland pipeline, Import Set templates) but user-facing upload workflow is not in current scope.
- **ServiceNow integration story** (Point 9) — already architected (subscribe-first, IRE gatekeeper). No code action needed.
- **Sales narrative sequence** (Point 10) — demo script and pitch deck territory. Inform Framer website content and sales conversations.
- **Assessment Snapshots & Trending** (future architecture) — `assessment_snapshots` table for period-over-period comparison. Documented in findings report as future consideration. Depends on staleness (Chunk 4/5) being implemented first.

---

## Session Lifecycle Reminders

**Starting a session:**
- Claude Code reads CLAUDE.md automatically
- The prompt above tells it which findings/files to read
- Name the CC session descriptively (e.g., "Dan Review — Chunk 3 Card Drill-Down")

**Mid-session — after Stuart applies SQL (Chunk 4 only):**
- Say "schema done" + list what was applied
- Claude runs: security-posture-validation.sql + `npx tsc --noEmit`

**Ending a session — chunk complete:**
- Claude merges branch to dev per CLAUDE.md git workflow
- Stuart says "run session-end checklist" if it's the last session of the day

**Ending a session — chunk in progress:**
- Claude pushes the feature branch
- Use the continuation prompt template to resume in a new window

**Parallel sessions:**
- Chunk 4 (DB) can run alongside Chunks 1-3 (frontend) — different files entirely
- Chunks 1 and 2 can be combined into a single session (~2 hours)
- Do NOT parallelize Chunks 3 and 5 — both modify Explorer and ScopeContext

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-04-04 | Initial session guide — 5 chunks from Dan Warfield UX review findings |
