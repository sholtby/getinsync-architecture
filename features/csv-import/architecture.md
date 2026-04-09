# CSV Import — Self-Serve Application Onboarding

**Version:** 2.0
**Status:** AS-BUILT
**Author:** Stuart Holtby / Claude Code
**Date:** 2026-04-09
**Requested by:** Dan Warfield

---

## 1. Purpose

Enable customers to self-serve bulk import of applications via CSV upload. Target user: an Enterprise Architect with a spreadsheet of 50-300 apps who wants to get started quickly without GetInSync involvement.

---

## 2. Implementation Summary

### 2.1 Components

| Component | Path | Purpose |
|-----------|------|---------|
| Import orchestrator | `src/pages/settings/import/ImportApplications.tsx` | Thin orchestrator wiring hook + step components |
| Import wizard hook | `src/pages/settings/import/useImportWizard.ts` | All state, data loading, import execution, undo logic |
| Shared types | `src/pages/settings/import/types.ts` | ImportStep, Workspace, PreviewRow, ImportBatch, MAX_ROWS |
| Step 1: Select Target | `src/pages/settings/import/StepSelectTarget.tsx` | Workspace/portfolio dropdowns, template download |
| Step 2: Upload File | `src/pages/settings/import/StepUploadFile.tsx` | File drag-drop, format info |
| Step 3: Preview | `src/pages/settings/import/StepPreview.tsx` | Validation table with green/yellow/red rows |
| Import History | `src/pages/settings/import/ImportHistory.tsx` | Paginated history table with undo buttons |
| Undo Confirm Modal | `src/pages/settings/import/UndoConfirmModal.tsx` | Undo confirmation dialog (uses ModalShell) |
| Error Banner | `src/pages/settings/import/ErrorBanner.tsx` | Error list display |
| CSV parser | `src/lib/csv-parser.ts` | Parsing, column mapping, validation with reference data |
| CSV export utilities | `src/utils/csv-export.ts` | Used for template generation |
| Sidebar nav | `src/components/Sidebar.tsx` | Gated to namespace admin + platform admin |
| Empty state button | `src/components/ApplicationsPool.tsx` | "Import from CSV" on zero-app state |
| Route | `/settings/import` in `src/App.tsx` | Settings route |

### 2.2 Architecture

- **Client-side only** — no Edge Function. CSV parsed in browser, rows inserted via Supabase client.
- **Row-by-row import** with per-row error handling (not all-or-nothing).
- **DB trigger** `create_deployment_profile_on_app_create` auto-creates primary DP; frontend updates it with retry loop.
- **Batch tracking** via `import_batches` table for audit trail and undo capability.

---

## 3. Access Control

**Namespace admin + platform admin only.** Workspace admins and regular members cannot access.

- Sidebar nav: `isNamespaceAdmin || isPlatformAdmin` gate (`src/components/Sidebar.tsx`)
- Page component: Access Denied block if neither condition met (`ImportApplications.tsx`)
- Empty state button: same `canImport` check (`ApplicationsPool.tsx`)
- RLS on `import_batches`: INSERT/UPDATE restricted to namespace admins and platform admins

---

## 4. CSV Column Specification

### 4.1 Supported Columns

| CSV Column | Target | Required | Default | Validation |
|------------|--------|----------|---------|------------|
| Application Name | `applications.name` | **Yes** | -- | Max 200 chars |
| Description | `applications.description` | No | `''` | Max 2000 chars |
| Business Owner | `applications.owner` | No | `''` | Free text |
| Technical Owner | `applications.primary_support` | No | `''` | Free text |
| External ID | `applications.external_id` | No | NULL | Free text (aliases: Source ID, Sys ID) |
| Portfolio | Portfolio assignment | No | Pre-selected | Portfolio name |
| Annual Cost | `deployment_profiles.annual_tech_cost` | No | 0 | Positive number, max 100M, currency parsing |
| Lifecycle Status | `applications.lifecycle_status` | No | Mainstream | CHECK constraint |
| Hosting Type | `deployment_profiles.hosting_type` | No | NULL | Reference table `hosting_types` |
| Cloud Provider | `deployment_profiles.cloud_provider` | No | NULL | Reference table `cloud_providers` (case-insensitive, normalized to lowercase) |
| Environment | `deployment_profiles.environment` | No | PROD | Reference table `environments` |
| Remediation Effort | `deployment_profiles.remediation_effort` | No | NULL | XS/S/M/L/XL/2XL |
| B1-B10 | `portfolio_assignments` (business scores) | No | NULL | 1-5 integer scale |
| T01-T15 | `deployment_profiles` (tech scores) | No | NULL | 1-5 integer scale |

### 4.2 Column Auto-Mapping

The parser uses case-insensitive alias matching (`csv-parser.ts` COLUMN_ALIASES). Users don't need exact header names.

### 4.3 Reference Table Validation

Hosting type, cloud provider, and environment values are fetched from reference tables at runtime (not hardcoded). Invalid values produce red-row errors in the preview step.

---

## 5. Import Flow

```
Step 1: Select Target
  - Pick workspace and portfolio
  - Reference data loaded in background

Step 2: Upload File
  - Drag-and-drop or click-to-upload CSV
  - Download template button (includes valid enum values as comments)
  - 500-row limit enforced

Step 3: Preview & Validate
  - Parse with csv-parser.ts (proper quote handling)
  - Auto-map columns
  - Validate each row against schema + reference tables
  - Duplicate check (case-insensitive name match against workspace)
  - Display table: green (ready) / yellow (duplicate, skip) / red (error, must fix)
  - Import button disabled if any red rows

Step 4: Import Execution
  - Create import_batches record
  - Per row:
    1. INSERT application (with import_batch_id, external_id)
    2. Wait for DB trigger → retry loop (3x, 50ms) to find primary DP
    3. UPDATE primary DP (hosting, cloud, env, cost, remediation, T-scores)
    4. INSERT portfolio_assignment (with B-scores if present)
  - Progress bar
  - Error collection per row

Step 5: Complete
  - Summary: imported / skipped / failed counts
  - Error list
  - Undo Import button
  - Import Another File / View Applications
```

---

## 6. Import Batch Tracking

### 6.1 Schema

**Table: `import_batches`**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | gen_random_uuid() |
| namespace_id | UUID FK | NOT NULL |
| workspace_id | UUID FK | NOT NULL |
| imported_by | UUID FK | auth.users, ON DELETE SET NULL |
| filename | TEXT | Original CSV filename |
| row_count | INTEGER | Successful imports |
| skipped_count | INTEGER | Duplicates skipped |
| failed_count | INTEGER | Rows that failed |
| status | TEXT | 'completed' or 'rolled_back' |
| created_at | TIMESTAMPTZ | Default now() |
| rolled_back_at | TIMESTAMPTZ | NULL until undo |

**Column on `applications`:** `import_batch_id UUID REFERENCES import_batches(id) ON DELETE SET NULL`

Partial index: `idx_applications_import_batch_id WHERE import_batch_id IS NOT NULL`

### 6.2 RLS

- SELECT: namespace members (namespace_id = get_current_namespace_id())
- INSERT/UPDATE: namespace admins + platform admins only
- DELETE: not granted (immutable audit trail)

---

## 7. Undo Import

### 7.1 Modification Detection

Before undo, the system checks for post-import modifications across:
- `application_contacts` (contacts linked)
- `application_integrations` (integration endpoints created)
- `application_documents` (documents attached)
- `application_roadmap` (roadmap entries)

Reports count of unique modified applications.

### 7.2 Confirmation Dialog

- **No modifications:** "This will permanently delete X applications and all associated data. This cannot be reversed."
- **With modifications:** "Warning: Y of X applications have been modified since import. All changes will be lost."

### 7.3 Execution

1. `DELETE FROM applications WHERE import_batch_id = :batchId` — CASCADE handles deployment_profiles, portfolio_assignments, contacts, assessments, etc.
2. `UPDATE import_batches SET status = 'rolled_back', rolled_back_at = now() WHERE id = :batchId`

---

## 8. Import History

Displayed on the main import page (Step 1 / select-target view). Table with pagination showing:
- Filename, date, imported/skipped/failed counts, status badge, undo action
- Uses `TablePagination` component

---

## 9. Entry Points

1. **Settings sidebar:** "Import Applications" nav link (namespace admin + platform admin only)
2. **Applications list empty state:** "Import from CSV" button alongside "New Application"
3. **Route:** `/settings/import`

---

## 10. Template Download

Generated in-browser. Includes:
- All supported column headers (core + assessment scores)
- Comment rows (prefixed `#`) listing valid enum values fetched from reference tables
- 2 example rows with realistic sample data

---

## 11. Security

- All inserts via Supabase client with user's auth token — RLS enforced
- `workspace_id` from context, not CSV (prevents cross-workspace injection)
- No server-side file storage — CSV parsed in browser and discarded
- Import activity logged via audit trigger on `applications` and `import_batches`
- Batch undo requires namespace admin (RLS on import_batches UPDATE)

---

## 12. Limitations & Future Work

| Item | Status | Notes |
|------|--------|-------|
| Contact lookup-or-create during import | v2 | Owner/primary_support are text fields, not linked contacts |
| "Update existing" duplicate mode | v2 | Currently skip-only |
| Server-side import via Edge Function | v2 | Needed if >500 row demand materializes |
| Import history export | v2 | Download past import details |
| CSVImportModal.tsx | Legacy | Simpler modal-based import; does not use batch tracking. Consider deprecating. |

---

*Last updated: 2026-04-09*
