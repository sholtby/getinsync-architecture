# IT Service Catalog Enhancements — Feasibility Review

**Date:** April 7, 2026
**Reviewed by:** Claude Code
**Source:** `planning/it-service-catalog-enhancements.md` v1.0
**Status:** Review complete — both chunks feasible with noted caveats

---

## Chunk A: Inline Catalog Editing

### A1. Consumer Rendering — Can We Add "+ Add Consumer"?

**Verdict: Yes, clean fit.**

Consumers render as a vertical list under each IT service in `ITServiceCatalogSettings.tsx:687-700`:

```
┌─ IT Service Name (count)
│  ├── 🖥 App Name • via DP Name
│  ├── 🖥 App Name • via DP Name
│  └── [+ Add Consumer]  ← fits here
```

Each consumer row shows: Monitor icon, linked app name, bullet separator, italic DP name. The list uses a left-border indent (`border-l-2 border-gray-200 pl-3`) with `space-y-1` spacing. A "+ Add Consumer" link placed after the `.map()` block (or after the `apps.length > 0` conditional to also show it on empty services) would follow the existing visual pattern.

**No layout changes needed** — just append the link inside the indented container.

---

### A2. Picker Reuse — Existing App/DP Pickers

**Verdict: Need a new composite picker. ~150 lines, reuses existing patterns.**

Existing pickers found:

| Component | Pattern | Reusable? |
|-----------|---------|-----------|
| `AddApplicationsModal.tsx` | Multi-select apps with search, checkboxes, bulk actions | Too heavy — we need single-select |
| `LinkInfrastructureModal.tsx` | Single DP picker with search, "Link" button per row | Close but no app context |
| `ServicePickerModal.tsx` | Hierarchical: type dropdown → service list → tech filter | Good UX pattern to follow |
| `ContactPicker.tsx` | Searchable single-select dropdown with inline creation | Good for simple cases |

**What we need:** A two-step modal:
1. Select application (searchable list, namespace-filtered, exclude SaaS hosting types)
2. Select deployment profile for that app (auto-selects if only one non-SaaS DP exists)
3. Confirm → insert

Follow `ServicePickerModal`'s hierarchical pattern. Scope: ~150 lines for `AddConsumerModal.tsx`. Accepts `excludeDpIds` prop to hide already-linked DPs.

---

### A3. Source Column in Catalog Query

**Verdict: Not currently included. Small query change needed.**

The dependencies query (`ITServiceCatalogSettings.tsx:177-188`) fetches:
```typescript
.from('deployment_profile_it_services')
.select(`
    it_service_id,
    deployment_profile:deployment_profiles (
        name,
        application:applications ( id, name )
    )
`)
```

**Missing:** `source` column and `id` (needed for delete). Fix:
```typescript
.select(`
    id,
    it_service_id,
    source,
    deployment_profile:deployment_profiles (
        name,
        application:applications ( id, name )
    )
`)
```

Then pass `source` to consumer rows to:
- Show an "auto" badge on auto-wired links
- Control delete behavior (manual = simple delete, auto = cost-aware confirm)

**Side note:** This query has no namespace filter (line 189 comment acknowledges this). RLS handles it, but tightening the query would be prudent.

---

### A4. Cost-Aware Delete — Extractable?

**Verdict: Yes, extract into shared hook.**

The cost-aware delete lives in `LinkedTechnologyProductsList.tsx`:
- `checkAutoUnwireTargets()` (lines 163-232): Finds orphaned auto-wired IT services when removing a tech product, fetches cost data
- Confirmation modal (lines 631-666): Shows service name, cost impact, "Keep Service Link" / "Remove Both" buttons

**Current coupling:** The function checks which OTHER tech products still power a service. In the catalog context, the question is simpler: "This DP has cost allocated to this service — removing it reduces cost by $X/year."

**Recommendation:** Extract a lightweight shared utility:
- `src/hooks/useITServiceUnlinkConfirm.ts` — checks if the link has cost allocation, returns `{ serviceName, annualCost }` for the confirm modal
- Reuse the same modal UI pattern (amber icon, cost display, two-button confirm)
- Both `LinkedTechnologyProductsList` and the catalog can consume it

---

### A5. Missing Concerns

| Concern | Assessment |
|---------|-----------|
| **Auth/RLS** | INSERT into `deployment_profile_it_services` requires **namespace admin or platform admin** (not workspace editors). The settings page already gates on `canManageSettings = isNamespaceAdmin`. **Aligned — no changes needed.** |
| **Refresh** | After add/remove, re-fetch the dependencies query. Simple `await fetchData()` call. No optimistic UI needed for v1. |
| **Duplicate check** | A unique constraint `deployment_profile_it_services_unique` on `(deployment_profile_id, it_service_id)` already exists in the schema. The frontend should still pre-check before insert for UX purposes — show an "Already linked" toast instead of letting the user hit a raw Postgres 23505 error. |
| **Namespace filter** | The deps query fetches ALL deployment_profile_it_services globally (RLS filters). Should add explicit namespace filter for correctness and performance. |
| **SaaS guard** | Spec says "Only show non-SaaS DPs." Need to filter by `hosting_type != 'SaaS'` in the picker query — same guard used in auto-wiring (Chunk 2). |
| **Empty state** | If a service has zero consumers, should still show "+ Add Consumer" (not hidden behind `apps.length > 0`). |

---

## Chunk B: Bulk Import

### B1. Existing Import Patterns

**Verdict: Strong existing pattern to reuse.**

Two CSV import implementations exist:

| Component | Pattern | Notes |
|-----------|---------|-------|
| `CSVImportModal.tsx` | Modal-based, single workspace target | Click-to-upload, row-by-row insert |
| `ImportApplications.tsx` | Full-page wizard: select target → upload → importing | Multi-step with workspace/portfolio selection |
| `src/lib/csv-parser.ts` | Shared parser with column aliases, validation, assessment scores | Robust — handles quoted fields, multipliers (K/M), t-shirt sizes |
| `src/utils/csv-export.ts` | CSV generation + download with UTF-8 BOM | Reusable for template download |

**Recommendation:** Follow the `CSVImportModal` pattern (modal, not full page) since the import is scoped to the current namespace. Reuse `csv-export.ts` for template generation.

---

### B2. SheetJS / Spreadsheet Library

**Verdict: Not installed. Recommend CSV-only for v1.**

`package.json` has no spreadsheet library — no `xlsx`, `exceljs`, or `papaparse`.

| Option | Size Impact | Pros | Cons |
|--------|------------|------|------|
| `xlsx` (SheetJS CE) | ~500KB minified | Reads .xlsx natively | Large bundle addition, license concerns |
| `papaparse` | ~16KB minified | Fast CSV parsing | CSV only (which is what we want) |
| Built-in `csv-parser.ts` | 0KB (already exists) | Zero new deps, proven in prod | CSV only |

**Recommendation:** Use existing `csv-parser.ts` for v1. Template is a .csv file (generated via `csv-export.ts`). Users can save Excel as CSV — this is the same pattern as Import Applications. Add .xlsx support in v2 only if customers request it.

---

### B3. Fuzzy Matching — Worth It for V1?

**Verdict: No. Exact match with suggestions for v1.**

Levenshtein distance adds:
- New dependency or custom implementation (~50-100 lines)
- Edge cases (short names, abbreviations, multiple close matches)
- UX complexity (yellow "fuzzy match" rows need confirm/reject per row)

**V1 approach:** Case-insensitive exact match. On mismatch, query all apps/services and find the closest by simple `includes()` or prefix match. Error message: "Application 'Hexagn OnCall' not found. Similar: 'Hexagon OnCall CAD/RMS'." User fixes the CSV and re-uploads.

**V2 upgrade path:** Add Levenshtein if users report frequent typo issues. The preview table infrastructure (green/yellow/red rows) built in v1 supports this naturally.

---

### B4. RLS for Bulk Inserts

**Verdict: Feasible but needs batching for large imports.**

`deployment_profile_it_services` has 14 RLS policies. Each INSERT checks:
```sql
deployment_profile_id IN (
    SELECT dp.id FROM deployment_profiles dp
    JOIN workspaces w ON w.id = dp.workspace_id
    WHERE w.namespace_id = get_current_namespace_id()
) AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(...))
```

**Performance estimates:**
- 50 rows: <1 sec (negligible)
- 200 rows: ~2-3 sec (acceptable with progress indicator)
- 1000 rows: ~10-15 sec (needs batching + progress bar)

**Mitigation:** Batch inserts in chunks of 50 rows. Supabase `.insert([array])` sends one HTTP request per batch, but RLS checks each row server-side. Show a progress bar: "Importing... 150/200 rows".

**Auth alignment:** INSERT policy requires namespace admin — matches the settings page gate.

---

### B5. Missing Concerns

| Concern | Recommendation |
|---------|---------------|
| **File size limit** | Cap at 1MB / 5,000 rows. Show error: "File too large. Maximum 5,000 rows per import." |
| **Row count limit** | Display row count after parse, before confirm. Warn at >500 rows: "Large import — this may take a moment." |
| **Progress indicator** | Show progress bar for imports >50 rows. Update per batch completion. |
| **Error recovery** | Insert per batch. If a batch fails, report which rows failed and let user retry or skip. Don't roll back successful batches. The preview table must clearly distinguish three states: **green** = will be inserted, **grey** = already linked (skipped as duplicate), **red** = errored (unresolved app/DP/service name, or SaaS primary DP). After import completes, the summary retains these colors so users understand partial success and can retry with a corrected CSV without risk of re-importing duplicates (the unique constraint on `(deployment_profile_id, it_service_id)` is the backstop). |
| **Template download** | Generate .csv via `csv-export.ts`: 3 columns (Application Name, Deployment Profile, IT Service) + 2 example rows. Button: "Download Template" at top of import modal. |
| **Blank DP column** | Spec says "if blank, use primary DP." Use `deployment_profiles.is_primary = true` to resolve. If the primary DP has SaaS hosting type, error the row: "Primary deployment profile for [App Name] is SaaS — specify a non-SaaS deployment profile." This aligns with cost bundle logic (cost bundle attaches to primary DP). |
| **Duplicate handling** | Pre-query existing links for all DPs in the import. Skip duplicates silently in preview (grey rows: "Already linked"). |
| **Encoding** | Existing CSV parser handles UTF-8 BOM. Test with Excel-generated CSVs (which use Windows-1252 by default). |

---

## Cross-Chunk Dependencies

| Dependency | Details |
|-----------|---------|
| **Source column** | Both chunks need the `source` column in the catalog query. Add it once in Chunk A. |
| **Cost-aware delete** | Both chunks share the delete confirmation pattern. Extract shared hook in Chunk A; Chunk B reuses it for manual removals post-import. |
| **Namespace filter** | Both chunks benefit from tightening the deps query with an explicit namespace filter. |
| **SaaS guard** | Both chunks exclude SaaS deployment profiles from selection/import. |

**Recommended build order:** Chunk A first (establishes source column query, picker pattern, shared delete hook). Chunk B second (reuses all of those).

---

## Risk Summary

| Risk | Severity | Mitigation |
|------|----------|-----------|
| No composite app/DP picker exists | Low | ~150 lines, follows existing `ServicePickerModal` pattern |
| Cost-aware delete tightly coupled | Low | Extract ~100 lines into shared hook during Chunk A |
| RLS slow for bulk imports >500 rows | Medium | Batch in chunks of 50, progress bar, cap at 5,000 rows |
| No .xlsx support | Low | CSV-only for v1, matches existing Import Applications pattern |
| Deps query has no namespace filter | Low | Add filter in Chunk A, low risk since RLS already enforces |

---

*Review complete. Both chunks are feasible. Chunk A is straightforward (S-M estimate is accurate). Chunk B is M effort if we skip fuzzy matching and use CSV-only.*
