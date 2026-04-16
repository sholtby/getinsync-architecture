# Publish Assessment Report — Native GetInSync Feature

## Context

SaskBuilds currently generates APM portfolio reports through a manual, external process: export data to CSV/XLSX, run Python/Node scripts, manually assemble narratives, generate Word documents. This works but doesn't scale.

GetInSync already has the full assessment data model (B1-B10 on `portfolio_assignments`, T01-T15 on `deployment_profiles`), computed TIME/PAID scores, configurable factors per namespace, an AI edge function (`ai-chat`), and an `assessment_history` table designed for point-in-time snapshots. The goal is to build a native "Publish Assessment" feature that generates a formal report directly from the platform — leveraging the existing AI infrastructure.

The user's initial prompt (included in the conversation) defines the report structure: 4 sections (Snapshot, Assessment Results, Factor Highlights, EA Handoff) with specific tone/style rules. This is a **per-deployment-profile** report (not portfolio-wide like the SaskBuilds skill), triggered when a user clicks "Publish Assessment."

## Architecture Decision: Scope

Stuart clarified: the report scope is **all apps in a workspace, using their production deployment profile**. This is a workspace-level portfolio report — directly analogous to the SaskBuilds ministry reports but generated natively from GetInSync data.

- **Trigger:** User clicks "Publish Assessment" at the workspace level
- **Scope:** All applications in the workspace that have a production DP with complete assessments
- **Data source:** Production DP's T-scores + the portfolio_assignment's B-scores for each app
- **Output:** Portfolio-wide report with TIME/PAID distribution, per-app sections, EA handoff
- **Prompt:** Hardcoded in the Edge Function (version-controlled, not namespace-editable)
- **PDF:** Server-side generation (not browser print-to-PDF)

## Key Data Relationships

- **B-scores** live on `portfolio_assignments` (same DP can have different B-scores per portfolio)
- **T-scores** live on `deployment_profiles` (shared across portfolios)
- **Derived scores:** `business_fit`, `criticality` (on `portfolio_assignments`), `tech_health`, `tech_risk` (on `deployment_profiles`)
- **TIME quadrant** derived from business_fit + tech_health thresholds
- **PAID action** derived from criticality + tech_risk thresholds
- **Factor config** in `assessment_factors` + `assessment_factor_options` (namespace-scoped)
- **Snapshots** in `assessment_history` (has `snapshot_data` JSONB for full context capture)

## Implementation Plan

### Step 1 — Design the report data assembly RPC

Create a Supabase RPC function that gathers all assessed apps in a workspace:

```sql
-- Returns JSON array of all assessed apps in a workspace (production DP only)
create function get_workspace_assessment_report_data(
  p_workspace_id uuid
) returns jsonb
```

This RPC assembles per-app:
- Application metadata (name, description, lifecycle, operational status, crown_jewel)
- Production deployment profile metadata (name, environment, hosted type, region, servers)
- Portfolio assignment scores (business_fit, criticality, time_quadrant) from `portfolio_assignments`
- DP scores (tech_health, tech_risk, paid_action) from `deployment_profiles`
- All B-factor scores (b1-b10) from `portfolio_assignments`
- All T-factor scores (t01-t15) from `deployment_profiles`
- Factor labels/questions from `assessment_factors` (namespace-scoped)
- ITSM counts if available

Plus workspace-level context:
- Assessment thresholds (namespace-scoped)
- Namespace and workspace names
- TIME/PAID distribution counts
- Crown Jewel count
- Assessment completion stats
- Publishing user info

**Output:** A JSON structure matching the SaskBuilds `ministry_data.json` shape — ready to pass to the AI for narrative generation and to the PDF generator for layout.

**Files to create:**
- SQL: `docs-architecture/features/publish-assessment/get_workspace_assessment_report_data.sql` (Stuart applies via SQL Editor)

### Step 2 — Create the report generation Edge Function

New Edge Function: `supabase/functions/publish-assessment/index.ts`

**Two-phase generation** (mirrors the SaskBuilds workflow but automated):

**Phase A — AI Narrative Generation:**
1. Authenticate user (reuse `_shared/auth.ts`)
2. Call `get_workspace_assessment_report_data` RPC
3. Build system prompt (hardcoded, refined from SaskBuilds lessons + user's initial prompt)
4. Call Claude API with the structured assessment data
5. Parse the structured JSON response (narratives, key insights, EA questions)

**Phase B — PDF Generation:**
6. Combine data + narratives into report layout
7. Generate PDF server-side (options: Puppeteer in Edge Function, or a dedicated PDF Edge Function that renders an HTML template)
8. Store the PDF in Supabase Storage (bucket: `assessment-reports`)
9. Write snapshot to `assessment_history` with report metadata in `snapshot_data`
10. Return the report URL + narrative JSON to the frontend

**Reuses:**
- `supabase/functions/_shared/auth.ts` — JWT validation
- `supabase/functions/_shared/cors.ts` — CORS headers
- `supabase/functions/_shared/supabase-admin.ts` — Backend DB access

**System prompt — hardcoded, incorporating SaskBuilds lessons:**
- Always use full application names, never bare acronyms
- Where TIME and PAID create tension, name it explicitly — this is the most valuable insight
- Crown Jewel status modifies urgency language
- Empty or near-threshold scores (within 5 points of 50) should be flagged
- Empty quadrants get a narrative explaining the absence
- Tone: APM surfaces insights, does not prescribe
- PAID interpretation added (Plan/Address/Improve/Divest) — the SaskBuilds reports only had TIME

**Config:** Add to `supabase/config.toml`:
```toml
[functions.publish-assessment]
verify_jwt = false
```

### Step 3 — PDF report template

Server-side PDF generation from an HTML/CSS template that mirrors the SaskBuilds Word doc structure:

- Page 1: Portfolio Snapshot (KPI banner, TIME/PAID bubble chart, distribution tables, key insights)
- Page 2: Abstract + methodology (factor tables with namespace-specific factor labels)
- Page 3: Assessment Team (from workspace membership data)
- Pages 4+: One section per TIME quadrant (header bar, definition callout, pattern narrative, app table, criticality insight)
- Incomplete Data section (apps with incomplete assessments)
- EA Handoff (open questions, next trigger)

**Chart generation:** The bubble chart can be generated server-side using a headless charting library, or pre-rendered by the frontend and uploaded. Given the Edge Function constraint, a lightweight SVG-based chart (no matplotlib dependency) is cleanest.

**PDF approach options:**
- **Option A:** HTML template → Puppeteer → PDF (rich layout, but Puppeteer is heavy for Edge Functions)
- **Option B:** Use a PDF library like `jsPDF` or `pdf-lib` in the Edge Function (lighter, but less layout control)
- **Option C:** Generate HTML, return it to the frontend, frontend calls `window.print()` or uses a print-specific stylesheet

**Recommendation:** Option A with a separate `generate-pdf` Edge Function that receives HTML and returns PDF. This keeps the AI function lean.

### Step 4 — Frontend: Workspace-level "Publish Assessment" UI

**Trigger location:** Workspace dashboard or assessment overview page

1. **Button:** "Publish Assessment Report" — only enabled when workspace has assessed apps
2. **Pre-publish summary:** Shows count of assessed apps, TIME/PAID distribution, incomplete apps
3. **Generation flow:** Calls Edge Function, shows progress (narrative generation → PDF layout → done)
4. **Report viewer:** Inline preview of the generated report
5. **Download:** Direct PDF download link from Supabase Storage
6. **History:** List of previously published reports for this workspace

**Files to create/modify:**
- `src/components/assessment/PublishWorkspaceReport.tsx` — Main publish flow
- `src/components/assessment/WorkspaceReportViewer.tsx` — Renders report inline
- `src/hooks/usePublishWorkspaceReport.ts` — Edge Function call + state
- Modify workspace dashboard to add the publish button

### Step 5 — Assessment history snapshot

On publish:
- Write a row to `assessment_history` per app (or a single workspace-level row) with `snapshot_data` containing:
  - Full input data (all scores, factor values, factor labels at time of publish)
  - Generated narratives
  - PDF storage URL
  - Publishing user and timestamp
- This creates an immutable record — scores and narrative locked at publish time
- Future publishes create new versions, never overwrite

**Likely needs:** A new `workspace_assessment_publications` table (or extend `assessment_history` with a workspace-level concept) since the current `assessment_history` is per-portfolio-assignment.

## System Prompt Strategy

The user's initial prompt is a strong starting point. Refinements based on SaskBuilds experience:

1. **Factor interpretation depth** — The prompt asks for top 2 strengths/concerns. Add: "Cite the factor question text and score. Explain why this factor matters for THIS application's position, not generically."
2. **TIME + PAID tension** — This is the killer insight. Add explicit examples: "Tolerate + Divest means the application is not strategically valuable but carries high technical risk — the risk may force action before the business case would."
3. **Crown Jewel handling** — "If crown_jewel is true, note this prominently in the snapshot and explain how it modifies the urgency of any concerns identified."
4. **Near-threshold awareness** — "If any axis score is within 5 points of the threshold (45-55), note that this application's quadrant position is sensitive to small score changes."
5. **Lifecycle context** — "End of Support lifecycle status combined with Modernize or Eliminate TIME position creates compounding urgency — name it."

## Verification

1. Create a test by publishing an assessment for an existing DP with complete B and T scores
2. Verify the report JSON structure matches the expected format
3. Verify the snapshot is written to `assessment_history`
4. Verify the report renders correctly in the frontend viewer
5. Verify Crown Jewel, near-threshold, and TIME/PAID tension cases produce appropriate narrative
6. Verify RLS — user can only publish assessments they have access to

## Critical Files

| File | Purpose |
|------|---------|
| `docs-architecture/core/time-paid-methodology.md` | Scoring logic (canonical) |
| `docs-architecture/core/deployment-profile.md` | DP schema |
| `supabase/functions/ai-chat/index.ts` | Reference: existing Edge Function pattern |
| `supabase/functions/ai-chat/tools.ts` | Reference: data query patterns |
| `supabase/functions/_shared/auth.ts` | Reuse: JWT validation |
| `supabase/config.toml` | Add: publish-assessment function config |
| `src/components/PortfolioAssessmentWizard.tsx` | Reference: assessment UI patterns |
| `src/pages/PublishApps.tsx` | Reference: existing publish UI |

## Resolved Decisions

- **Scope:** All apps in workspace, production DP — workspace-level portfolio report
- **Prompt storage:** Hardcoded in Edge Function
- **PDF:** Server-side generation

## Remaining Open Questions

1. **PDF generation approach:** Puppeteer in a separate Edge Function (rich layout) vs jsPDF/pdf-lib (lighter, less control)? Puppeteer may be too heavy for Supabase Edge Functions.
2. **Chart in PDF:** SVG-based chart generated server-side, or pre-render on frontend and pass as base64?
3. **New table needed?** `workspace_assessment_publications` to track workspace-level publishes, or extend existing `assessment_history`?

## Phased Delivery

Given complexity, suggest building in phases:

| Phase | Deliverable |
|-------|------------|
| **1** | RPC function + Edge Function for narrative generation (AI part only, returns JSON) |
| **2** | Frontend publish button + inline report viewer (renders JSON as styled HTML) |
| **3** | PDF generation + Supabase Storage + download |
| **4** | Bubble chart in report (SVG or canvas-based) |
| **5** | Publication history + snapshot immutability |
