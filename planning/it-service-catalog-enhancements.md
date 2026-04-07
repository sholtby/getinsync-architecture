# IT Service Catalog — Bidirectional Editing & Bulk Import

**Version:** 1.0  
**Date:** April 7, 2026  
**Status:** 🟡 AS-DESIGNED  
**Schema impact:** None (Chunk A). Bulk import TBD (Chunk B).

---

## Problem

The IT Service Catalog is read-only. Users can see which apps consume a service but can't wire them from here — they have to navigate to each app's Deployments & Costs tab and add the IT Service link one at a time. This is backwards for the ITSM person whose mental model is service-centric: "SQL Server DB Services is consumed by these 10 apps."

New customers have spreadsheets listing app-to-service mappings. There's no way to load them in bulk — every link must be clicked through individually.

---

## Solution: Two Chunks

### Chunk A: Inline Catalog Editing (S-M effort)

**The QuickBooks principle:** In QuickBooks you can assign expenses to categories from the expense view OR from the category view. Both directions work.

Add a "+ Add Consumer" button to each IT Service in the catalog. Clicking it opens a picker to select an application and deployment profile. On confirm, insert into `deployment_profile_it_services` with `source = 'manual'`, `relationship_type = 'depends_on'`.

Also add a remove button (trash icon) on each consumer row to delete the link, with the same cost-awareness confirm dialog from Chunk 2's auto-unwire logic.

**Behavior:**

| Action | What Happens |
|--------|-------------|
| + Add Consumer | Opens app/DP picker → inserts `deployment_profile_it_services` row with `source = 'manual'` |
| Remove consumer (manual link) | Confirm → delete row |
| Remove consumer (auto link) | Cost-aware confirm dialog (same as Chunk 2 auto-unwire) → delete row |
| Duplicate check | If DP already linked to this service, show "Already linked" toast and skip. DB unique constraint `deployment_profile_it_services_unique` on `(deployment_profile_id, it_service_id)` is the backstop. |

**Scope rules:**
- Only show apps/DPs from the same namespace
- Only show non-SaaS DPs (SaaS apps don't consume internal IT Services — same guard as Chunk 2)
- Don't show DPs that are already linked to this service

**UI placement:**
- "+ Add Consumer" link below the last consumer in each service's expanded row
- Trash icon on each consumer row (only visible on hover, same pattern as other list delete actions)
- Consumer count updates immediately after add/remove

**No schema changes.** Uses existing `deployment_profile_it_services` table with the `source` column from Chunk 2.

### Chunk B: Bulk Import Template (M effort, PARKED)

**The Day 1 accelerator.** A new customer uploads a spreadsheet mapping apps to IT Services. The system validates, previews, and bulk inserts.

**Template format (3 columns):**

| Application Name | Deployment Profile | IT Service |
|-----------------|-------------------|------------|
| Hexagon OnCall CAD/RMS | Hexagon OnCall CAD/RMS - PROD - CHDC | SQL Server Database Services |
| Hexagon OnCall CAD/RMS | Hexagon OnCall CAD/RMS - PROD - CHDC | Windows Server Hosting |
| Microsoft Dynamics GP | Microsoft Dynamics GP - PROD - CHDC | SQL Server Database Services |

**Validation rules:**
- Application Name must match an existing app in the namespace (fuzzy match with suggestions for close misses)
- Deployment Profile must belong to that application (if blank, use `is_primary = true` DP; if primary DP is SaaS, error the row)
- IT Service must match an existing service in the namespace
- Skip duplicates (DP already linked to service)
- Flag rows that can't be resolved → user reviews and fixes or skips

**Upload flow:**
1. Download template (.xlsx with headers + example row)
2. Fill out and upload
3. Preview screen: **green** = will be inserted, **grey** = already linked (skipped as duplicate), **red** = errored (unresolved name or SaaS primary DP)
4. Confirm → bulk insert into `deployment_profile_it_services` with `source = 'manual'` (batched, no rollback of successful batches)
5. Summary retains preview colors so users understand partial success. Safe to retry with corrected CSV — unique constraint prevents duplicate inserts.

**Maturity model alignment:**
- Day 1: Bulk import from spreadsheet (this feature)
- Day 30: Power users add links from catalog (Chunk A)
- Day 90: Auto-wiring handles it from tech products (Chunk 2, already built)

**Implementation notes:**
- Reuse the existing Import Applications pattern if one exists (check `src/pages/` for import components)
- SheetJS for xlsx parsing (already available in React artifacts)
- Preview table with row-level status badges
- Transaction: all-or-nothing per confirmed batch

---

## Chunk A — CC Prompt

See `planning/it-service-catalog-inline-editing-prompt.md`

## Chunk B — CC Prompt

See `planning/it-service-catalog-bulk-import-prompt.md` (PARKED — execute after Chunk A)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-07 | Initial concept. Chunk A (inline editing) ready for implementation. Chunk B (bulk import) parked. |
