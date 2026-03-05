# Phase 3 Handover — Cost Model Reunification Frontend

> **Created:** 2026-03-05
> **Purpose:** Handover context for a fresh Claude Code session to execute Phase 3.
> **Delete this file after Phase 3 is complete.**

---

## What Happened (Phases 0–2 Complete)

The **Cost Model Reunification** simplifies GetInSync from three cost channels to two:

| Before | After |
|--------|-------|
| Software Products (dpsp cost) | ❌ Removed — Software Products are now **inventory-only** |
| IT Services (dpis allocations) | ✅ Unchanged — also now carries **contract lifecycle** fields |
| Cost Bundles (cost_bundle DPs) | ✅ Unchanged |

**Key decision:** IT Services absorb the contract role (vendor, contract dates, cost pool). Software Products track what software exists, not what it costs. See `docs-architecture/features/cost-budget/adr-cost-model-reunification.md`.

### Phase 0 (Done): Architecture docs updated — 9 docs + MANIFEST
### Phase 1 (Done): Schema changes applied

| Object | Change |
|--------|--------|
| `it_services` + 4 columns | `contract_reference` (text), `contract_start_date` (date), `contract_end_date` (date), `renewal_notice_days` (int, default 90) |
| `it_service_software_products` table (NEW) | Junction: `id`, `it_service_id` (FK), `software_product_id` (FK), `notes`, `created_at`. UNIQUE(it_service_id, software_product_id). 4 RLS policies, audit trigger. |
| `vw_it_service_contract_expiry` view (NEW) | 13 columns. Status buckets: `expired`, `renewal_due`, `expiring_soon`, `active`, `no_contract`. `security_invoker = true`. |

### Phase 2 (Done): Views updated

| View | Change |
|------|--------|
| `vw_deployment_profile_costs` | Software cost subquery removed. `software_cost` column kept as hardcoded `0::numeric` for TypeScript backward compat. `total_cost = service_cost + bundle_cost`. |
| `vw_run_rate_by_vendor` | Software UNION leg removed. IT Service + Cost Bundle legs remain. |
| `vw_application_run_rate` | `software_cost` hardcoded to `0::numeric`. Reads clean `total_cost` from `vw_deployment_profile_costs`. |

**Updated stats:** Tables: 93 | Views: 32 | RLS policies: 361

---

## Phase 3: Frontend Work (This Session)

### 3A: TypeScript types (DO FIRST)

| File | Change |
|------|--------|
| `src/types/view-contracts.ts` | Add `VwItServiceContractExpiry` interface matching the 13-column view |
| `src/types/index.ts` | Add 4 contract fields to `ITService` interface; add `ITServiceSoftwareProduct` interface |

**View columns for `VwItServiceContractExpiry`:**
```
it_service_id (uuid), namespace_id (uuid), owner_workspace_id (uuid),
name (text), annual_cost (numeric), vendor_org_id (uuid),
vendor_name (text), contract_reference (text),
contract_start_date (date), contract_end_date (date),
renewal_notice_days (int), days_until_expiry (int), status (text)
```

**New `it_services` columns to add to ITService type:**
```
contract_reference (text | null), contract_start_date (string | null),
contract_end_date (string | null), renewal_notice_days (number | null)
```

**New `ITServiceSoftwareProduct` interface:**
```
id (string), it_service_id (string), software_product_id (string),
notes (string | null), created_at (string)
```

### 3B: ITServiceModal contract fields

| File | Change |
|------|--------|
| `src/components/ITServiceModal.tsx` | Add collapsible "Contract Details" section: `contract_reference` (text input), `contract_start_date` / `contract_end_date` (date inputs), `renewal_notice_days` (number input, default 90) |
| `src/pages/settings/ITServiceCatalogSettings.tsx` | Update `onSave` handler to persist the 4 new contract columns |

### 3C: IT Service → Software Product linking

| File | Change |
|------|--------|
| `src/components/ITServiceSoftwareProductsList.tsx` | **NEW** component — List/link/unlink software products from an IT Service. Pattern: similar to any existing linked-items list in the codebase. |
| `src/components/ITServiceModal.tsx` | Add "Software Products Provided" section using the new component |

### 3D: Cost component updates (minimal)

| File | Change |
|------|--------|
| `src/components/ApplicationCostSummary.tsx` | Software cost query returns 0 post-Phase 2 — likely no code change needed. Verify software section shows $0 or "no cost" correctly. |
| `src/components/dashboard/CostAnalysisPanel.tsx` | No change expected — `software_cost` column still exists as 0. Verify no errors. |
| `src/components/applications/CostSnapshotCard.tsx` | No change — queries `total_cost` only. |
| `src/lib/utils/costs.ts` | No change — legacy fallback fields are a separate concern. |

### 3E: Contract expiry widget

| File | Change |
|------|--------|
| `src/components/dashboard/ContractExpiryWidget.tsx` | **NEW** — Query `vw_it_service_contract_expiry`; show count by status; table with pagination. Placement TBD (ask Stuart — dashboard or IT Service settings page). |

### 3F: Quick calculator

| File | Change |
|------|--------|
| IT Service allocation dialog | Add "Unit price × Quantity = Total" convenience calculator. Saves result as fixed allocation on `dpis.allocation_value`. No data model change — purely UI. |

---

## Validation Checklist

After all Phase 3 work:
1. `npx tsc --noEmit` — zero errors
2. `npm run build` — succeeds
3. Manual test: ITServiceModal save/load with contract fields
4. Manual test: Link/unlink software products from IT Service
5. Manual test: Contract expiry widget renders
6. Architecture doc update if any UI behavior changed

---

## Key Architecture References

| Doc | Purpose |
|-----|---------|
| `docs-architecture/features/cost-budget/adr-cost-model-reunification.md` | The ADR driving everything |
| `docs-architecture/features/cost-budget/cost-model-primer.md` (v2.0) | Two-channel cost model overview |
| `docs-architecture/catalogs/it-service.md` (v2.0) | IT Service with contract fields + software junction |
| `docs-architecture/catalogs/software-product.md` (v3.0) | Software Products are inventory-only |
| `docs-architecture/features/cost-budget/cost-model.md` (v3.0) | Full cost architecture |

---

## Execution Order

1. **3A first** — types must be right before anything else compiles
2. **3B second** — ITServiceModal contract fields (most value, lowest risk)
3. **3C third** — Software Product linking (new component + modal integration)
4. **3D fourth** — Verify cost components still work (likely no-op)
5. **3E fifth** — Contract expiry widget (new, standalone)
6. **3F last** — Quick calculator (nice-to-have, can defer)
