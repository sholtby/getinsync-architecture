# CSV Import — Self-Serve Application Onboarding

**Version:** 1.0
**Status:** AS-DESIGNED
**Author:** Stuart Holtby / Claude Code
**Date:** 2026-04-09
**Requested by:** Dan Warfield

---

## 1. Purpose

Enable customers to self-serve bulk import of applications via CSV upload. Target user: an Enterprise Architect with a spreadsheet of 50-300 apps who wants to get started quickly without GetInSync involvement.

---

## 2. Current State Audit

### 2.1 Existing Implementation

A CSV import feature **already exists** in the codebase:

| Component | Path | Status |
|-----------|------|--------|
| Import page (multi-step wizard) | `src/pages/settings/ImportApplications.tsx` | Implemented |
| Import modal (simpler) | `src/components/CSVImportModal.tsx` | Implemented |
| Custom CSV parser | `src/lib/csv-parser.ts` | Implemented |
| CSV export utility | `src/utils/csv-export.ts` | Implemented |
| Route | `/settings/import` | Wired in `src/App.tsx` |

**No external CSV library** -- uses a custom parser with quoted field support, column auto-mapping with aliases, and currency parsing.

**No backend processing** -- all import logic runs client-side via direct Supabase inserts.

### 2.2 Current CSV Columns Supported

| Column | Target | Notes |
|--------|--------|-------|
| name | `applications.name` | Required, max 200 chars |
| description | `applications.description` | Max 2000 chars |
| owner | `applications.owner` | Text field (NOT a contact link) |
| primary_support | `applications.primary_support` | Text field (NOT a contact link) |
| annual_cost | `deployment_profiles.annual_tech_cost` | Currency parsing (CAD/USD, K/M) |
| lifecycle_status | `applications.lifecycle_status` | Mainstream/Extended/End of Support |
| portfolio | Portfolio assignment | Assigns to named portfolio |
| b1-b10 | Business assessment scores | 1-5 scale |
| t01-t15 | Technical assessment scores | 1-5 scale |
| remediation_effort | T-shirt sizes | XS/S/M/L/XL/2XL |

### 2.3 Existing Features

- Drag-and-drop file upload
- Workspace and portfolio selection (multi-step wizard)
- Duplicate detection by application name within workspace
- Error/skip reporting with summary
- Column auto-mapping with aliases

### 2.4 Application Creation Flow (Reference)

1. **UI** -> `ApplicationForm.tsx` -> `usePortfolios.createApplication()` (`src/hooks/usePortfolios.ts:839-897`)
2. **Insert** -> `supabase.from('applications').insert(...)` -- requires `workspace_id` + `name`
3. **DB trigger** -> `create_deployment_profile_on_app_create` fires AFTER INSERT, creates primary deployment profile (`is_primary=true`, name = `"[App] -- Region-PROD"`, environment = `PROD`, region = `CA`)
4. **Frontend waits ~100ms** -> updates deployment profile with additional fields
5. **Portfolio assignment** -> inserts into `portfolio_assignments`
6. **Contacts** -> saved separately via `application_contacts` junction table (not part of current import)

### 2.5 Contact Handling (Current)

Contacts use a lookup-or-create pattern via `ContactPicker.tsx`. The existing import does NOT create or link contact records -- `owner` and `primary_support` are stored as plain text on the `applications` table, not linked to the `contacts` table.

---

## 3. Gap Analysis

| Capability | Current | Needed for v1 | Gap |
|------------|---------|---------------|-----|
| CSV upload + parsing | Done | Done | None |
| Application creation | Done | Done | None |
| Deployment profile fields (hosting, cloud, env) | **Missing** | Yes | Parser + post-insert DP update |
| Client-side preview before commit | **Missing** | Yes | Key UX gap |
| Duplicate detection | Done (by name) | Done | Minor refinement |
| Portfolio assignment | Done | Done | None |
| Row limit enforcement | **Missing** | Yes | Cap at 500 |
| Assessment scores | Done | Optional | Already supported |
| External ID mapping | **Missing** | Deferred | Schema column does not exist |
| Contact lookup-or-create | **Missing** | v2 | Text fields work for now |

---

## 4. v1 CSV Column Specification

### 4.1 Column Map (Validated Against Schema)

| CSV Column | Target Table.Column | Required | Default | Validation |
|------------|-------------------|----------|---------|------------|
| Application Name | `applications.name` | **Yes** | -- | Max 200 chars, must not be empty |
| Description | `applications.description` | No | `''` | Max 2000 chars |
| Business Owner | `applications.owner` | No | `''` | Free text (not a contact link) |
| Technical Owner | `applications.primary_support` | No | `''` | Free text (not a contact link) |
| Hosting Type | `deployment_profiles.hosting_type` | No | NULL | Must match `hosting_types` reference table |
| Cloud Provider | `deployment_profiles.cloud_provider` | No | NULL | Must match `cloud_providers` reference table |
| Environment | `deployment_profiles.environment` | No | `'PROD'` | Must match `environments` reference table |
| Lifecycle Status | `applications.lifecycle_status` | No | `'Mainstream'` | CHECK constraint on applications table |
| Annual Cost | `deployment_profiles.annual_tech_cost` | No | 0 | Positive number, max 100M. Currency parsing. |

### 4.2 Valid Enum Values

| Field | Valid Values | Source |
|-------|-------------|--------|
| Hosting Type | SaaS, Third-Party-Hosted, Cloud, On-Prem, Hybrid, Desktop | `hosting_types` table |
| Cloud Provider | aws, azure, gcp, oracle, ibm, other | `cloud_providers` table |
| Environment | PROD, SBX, UAT, TEST, DEV, STG, DR | `environments` table |
| Lifecycle Status | Mainstream, Extended, End of Support | CHECK constraint on `applications.lifecycle_status` |

### 4.3 Auto-Populated Fields (Not in CSV)

| Field | Source | Value |
|-------|--------|-------|
| `applications.workspace_id` | Current workspace context | Selected workspace UUID |
| `applications.app_id` | DB sequence | Auto-incremented |
| `deployment_profiles.*` | DB trigger `create_deployment_profile_on_app_create` | Primary DP auto-created |
| `deployment_profiles.is_primary` | DB trigger | `true` |
| `deployment_profiles.environment` | DB trigger default | `PROD` (overwritten by CSV value if provided) |

### 4.4 Deferred Columns

| Column | Reason | Target |
|--------|--------|--------|
| External ID | `external_id` column does not exist on `applications` table. Requires schema change. | v1 if Stuart adds column; otherwise v2 |
| Contact linking | Lookup-or-create adds significant complexity (name ambiguity, namespace scoping, role assignment). Text fields sufficient for onboarding. | v2 |
| Assessment scores | Already supported by parser (T01-T15, B1-B10). Include in downloadable template but mark as optional/advanced. | v1 (already done) |

---

## 5. Architecture

### 5.1 Approach: Enhance Existing

**Do not rebuild from scratch.** The existing `ImportApplications.tsx` + `csv-parser.ts` provides a solid foundation. Extend with:

1. New column mappings in `csv-parser.ts` for hosting_type, cloud_provider, environment
2. Deployment profile update step after application insert (same 100ms wait pattern used in `ApplicationPage.tsx:521`)
3. Preview step UI -- parse CSV, show validation table, let user confirm before committing
4. Row limit enforcement (500 max)

### 5.2 Import Flow

```
Step 1: Configure
  - Select target workspace (existing)
  - Select target portfolio (existing, optional)
  - Upload CSV file (drag-and-drop, existing)

Step 2: Preview & Validate (NEW)
  - Parse CSV client-side (csv-parser.ts)
  - Auto-map columns using aliases (existing)
  - Query existing app names in workspace for duplicate check
  - Display preview table:
    - Green rows: ready to import
    - Yellow rows: warnings (duplicate name -- will skip)
    - Red rows: errors (invalid enum value, missing required field)
  - Show summary: "X ready, Y duplicates (will skip), Z errors (must fix)"
  - User can download error report or fix CSV and re-upload
  - "Import" button disabled until zero red rows

Step 3: Execute Import
  - Row-by-row insert (not all-or-nothing)
  - Per row:
    1. Insert into `applications` (name, description, owner, primary_support, lifecycle_status, workspace_id)
    2. Wait for DB trigger to create primary deployment profile
    3. Query deployment_profiles for the new primary DP
    4. Update primary DP with hosting_type, cloud_provider, environment, annual_tech_cost
    5. If portfolio selected: insert portfolio_assignment
  - Progress bar during execution
  - On completion: summary report
    - "Imported X of Y applications. Z skipped (duplicates). W failed."
    - Failed rows shown with error details

Step 4: Post-Import Summary
  - Link to workspace application list
  - Option to download error/skip report
  - Option to import another file
```

### 5.3 Validation Rules

**Client-side (before import):**

| Rule | Severity | Behavior |
|------|----------|----------|
| Application Name empty | Error (red) | Must fix before import |
| Application Name > 200 chars | Error (red) | Must fix |
| Application Name duplicate in CSV | Warning (yellow) | First occurrence imports, rest skip |
| Application Name exists in workspace | Warning (yellow) | Row skipped |
| Invalid Hosting Type value | Error (red) | Must fix or clear |
| Invalid Cloud Provider value | Error (red) | Must fix or clear |
| Invalid Environment value | Error (red) | Must fix or clear |
| Invalid Lifecycle Status value | Error (red) | Must fix or clear |
| Annual Cost negative or > 100M | Error (red) | Must fix or clear |
| Row count > 500 | Error | File rejected with message |

**Enum validation** must fetch valid values from reference tables at runtime (per CLAUDE.md rules -- no hardcoded arrays).

### 5.4 Transaction Safety

**Row-by-row with error reporting**, not all-or-nothing. Rationale:

- All-or-nothing means one bad row blocks 299 good ones
- Each row is independent -- no cross-row dependencies
- The DB trigger handles deployment profile creation atomically per row
- Summary report shows exactly which rows succeeded, skipped, or failed
- User can fix failed rows and re-import (duplicates will skip cleanly)

### 5.5 Duplicate Detection

**By application name within the workspace** (case-insensitive match).

- **v1:** Skip duplicates. If app name already exists in workspace, skip the row and report it.
- **v2 (future):** "Update existing" mode -- merge CSV data into existing application record.

Pre-import: query all existing app names in the target workspace and flag duplicates in the preview table.

### 5.6 Workspace Scoping

Import targets the user's currently selected workspace. This is correct -- applications require `workspace_id`, and the DB trigger copies it to the deployment profile. The existing wizard already includes a workspace selector.

### 5.7 Portfolio Assignment

Optional, as a pre-import selection (already in existing wizard). User picks a portfolio before import; all imported apps get assigned to it. Post-import assignment is also available through the normal UI.

### 5.8 Row Limits

**500 applications max per upload for v1.**

- Client-side parsing of 500 rows with validation is fast
- Direct Supabase inserts (no batch API) -- 500 sequential inserts take ~30-60 seconds
- Beyond 500, server-side processing (Edge Function) would be needed for reliability
- Display progress bar during execution to set expectations

---

## 6. Implementation Scope

### 6.1 v1 Work Items

| Item | Effort | Files Affected |
|------|--------|---------------|
| Add hosting_type / cloud_provider / environment column mappings to parser | Small | `src/lib/csv-parser.ts` |
| Add reference table validation (fetch valid values at runtime) | Small | `src/lib/csv-parser.ts` or new validation hook |
| Wire deployment profile update after import (hosting, cloud, env, cost) | Medium | `src/pages/settings/ImportApplications.tsx` |
| Add preview step with validation table UI | Medium | `src/pages/settings/ImportApplications.tsx` |
| Add row limit enforcement (500 max) | Small | `src/pages/settings/ImportApplications.tsx` |
| Downloadable CSV template with column headers + enum values in comments | Small | New static asset or generated download |
| Update route / navigation for discoverability | Small | `src/App.tsx`, sidebar/settings nav |

### 6.2 v2 Enhancements (Future)

| Item | Effort | Notes |
|------|--------|-------|
| `external_id` column on applications | Small (schema) | Requires Stuart to add column via SQL Editor |
| Contact lookup-or-create during import | Large | Match by display_name, create missing, link via application_contacts |
| "Update existing" duplicate mode | Medium | Merge CSV data into existing app records |
| Post-import "match contacts" wizard | Medium | Show unlinked owner/support names, map to contact records |
| Server-side import via Edge Function | Large | Needed if >500 row demand materializes |
| Import history / audit log | Medium | Track who imported what, when, with what file |

---

## 7. UX Considerations

### 7.1 Discoverability

The existing route (`/settings/import`) may be hard to find for new users. Consider:
- Adding an "Import from CSV" button on the Applications list page
- Adding it to the workspace onboarding flow (empty state)
- Keeping the Settings page route as an alternate path

### 7.2 Template Download

Provide a downloadable CSV template with:
- All supported column headers
- 2-3 example rows with realistic data
- Comments or a companion doc listing valid enum values
- Template should be available before upload (not just after errors)

### 7.3 Error Recovery

- User can fix errors in their spreadsheet and re-upload (duplicates skip cleanly)
- Downloadable error report includes row numbers and specific validation failures
- No partial state to clean up -- failed rows simply don't insert

---

## 8. Open Questions for Stuart

1. **External ID** -- add `external_id` column to `applications` table for v1, or defer to v2?
2. **Route placement** -- keep at `/settings/import`, or add a more prominent entry point (e.g., button on Applications list)?
3. **Assessment scores in template** -- the parser already supports T01-T15 and B1-B10. Include in the downloadable template or keep it simple with just app + DP fields for Dan's use case?
4. **Cloud provider codes** -- reference table uses lowercase codes (`aws`, `azure`, `gcp`). Should the parser accept case-insensitive input (e.g., "AWS" -> "aws")?

---

## 9. Security & Compliance

- All inserts go through Supabase client with user's auth token -- RLS policies enforced
- `workspace_id` comes from the user's current context, not from the CSV (prevents cross-workspace injection)
- No server-side file storage -- CSV is parsed in-browser and discarded after import
- Row-level errors do not expose other users' data
- Import activity should appear in the application audit log (existing `audit_log` trigger on `applications` table handles this)

---

*Last updated: 2026-04-09*
