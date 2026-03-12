# Standards Intelligence — Phase 1 Implementation Plan

**Document:** `features/technology-health/standards-intelligence-phase1-plan.md`
**Version:** v1.0
**Status:** Validated against live schema
**Date:** 2026-03-11
**Parent:** `standards-intelligence.md` v1.1

---

## 1. Schema Validation Summary

### Confirmed OK

| Check | Result |
|-------|--------|
| `technology_products.product_family` | Exists, text, nullable |
| Join path: dptp → tp → dp → w → namespace | All FK columns confirmed |
| `applications.operational_status` | Exists |
| No `technology_standards` table | Safe to create |
| PostgreSQL 17.6 | `MODE() WITHIN GROUP` supported |
| Data volume | 63 tags, 30 DPs, 23 products, 8 categories |
| `technology_product_categories` columns | id, namespace_id, name, description, display_order, is_active, created_at (no `code` column — view uses `tpc.name`, correct) |
| 16 template categories | Compute, Operating System, Network, Storage, Database, Data Warehouse, Data Integration, Middleware, Runtime/PaaS, Container/Kubernetes, Identity & Access, Network Security, Data Protection, Web Server, Framework, Language/Runtime |

### Issues Found

#### Issue 1: T15 Column Exists (Architecture Doc Error)

**Doc §6.1 says:** "No T15 column exists on deployment_profiles"
**Reality:** `deployment_profiles.t15` exists (integer). 11 DPs have values (scores 2–5), 193 are NULL.

**Impact on Phase 1:** None. Phase 1 doesn't touch T-scores.
**Action:** Update §6.1 to acknowledge T15 exists with sparse data. The derived modifier approach (§6.2) is still correct — standards conformance is computed from data, not a human-answered question.

#### Issue 2: Empty String Bug in View SQL

5 products have `product_family = ''` (empty string, not NULL). The view uses `COALESCE(tp.product_family, tp.name)` which only catches NULL.

**Affected products:**
- Microsoft SQL Server (empty `''`) — won't group with "SQL Server" family
- Oracle Database (empty `''`) — won't group with "Oracle Database" family
- MySQL (empty `''`) — becomes its own family
- PostgreSQL ×2 (empty `''`) — becomes its own family

**Fix:** Change to `COALESCE(NULLIF(tp.product_family, ''), tp.name)` in both CTEs.

#### Issue 3: product_family Data Fragmentation

6 products have NULL product_family, including:
- Windows Server (NULL) — separate from "Windows Server" family (3 products)
- Microsoft Azure, Microsoft Power Apps, Microsoft SharePoint, Oracle Cloud (NULL)

**Action:** Stuart runs a data cleanup pass (Chunk 0) to set correct product_family values before creating views.

#### Issue 4: RLS Pattern — Validated as Correct

The proposed 4-policy namespace-filtered pattern differs from `technology_product_categories` (7 policies, public SELECT). This is **intentional and correct**: categories use a template/inheritance pattern (public read), while standards are namespace-specific data (namespace-filtered read). The doc's RLS design is sound.

---

## 2. Recommended Architecture Doc Changes

| Section | Change |
|---------|--------|
| §6.1 | Correct: T15 column exists with sparse data (11/204 DPs). Add: "The derived modifier approach is preferred regardless." |
| §3.3 view SQL | Both CTEs: `COALESCE(tp.product_family, tp.name)` → `COALESCE(NULLIF(tp.product_family, ''), tp.name)` |
| §3.4 summary view | Note: `implied_pending_review` uses hardcoded `>= 40`. Fine for Phase 1, but Phase 2 should read from namespace-level config. |

---

## 3. SQL Chunks for Stuart (ordered)

### Chunk 0: Product Family Data Cleanup (prerequisite)

```sql
-- Step 1: Fix empty strings to NULL
UPDATE technology_products
SET product_family = NULL
WHERE product_family = '';

-- Step 2: Set correct product_family values
-- Review these and adjust as needed:
UPDATE technology_products SET product_family = 'Windows Server' WHERE name LIKE 'Windows Server%' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'SQL Server' WHERE name LIKE '%SQL Server%' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'Oracle Database' WHERE name = 'Oracle Database' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'MySQL' WHERE name = 'MySQL' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'PostgreSQL' WHERE name = 'PostgreSQL' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'Microsoft Azure' WHERE name = 'Microsoft Azure' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'Microsoft Power Apps' WHERE name = 'Microsoft Power Apps' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'Microsoft SharePoint' WHERE name = 'Microsoft SharePoint' AND product_family IS NULL;
UPDATE technology_products SET product_family = 'Oracle Cloud' WHERE name = 'Oracle Cloud' AND product_family IS NULL;

-- Step 3: Verify — should return 0 rows
SELECT id, name, product_family FROM technology_products WHERE product_family IS NULL OR product_family = '';
```

**Dependencies:** None. Run first.

### Chunk 1: Create `technology_standards` table + security (S.1)

DDL from architecture doc §3.1, plus:
- RLS enable + 4 policies from §3.2
- `GRANT SELECT ON technology_standards TO authenticated;`
- `GRANT INSERT, UPDATE, DELETE ON technology_standards TO authenticated;`
- Audit trigger: `audit_log_trigger()`
- Updated_at trigger: `set_updated_at()`

**Dependencies:** After Chunk 0.

### Chunk 2: Create `vw_implied_technology_standards` view (S.2)

DDL from §3.3 **with NULLIF fix applied** to both CTEs:
```sql
COALESCE(NULLIF(tp.product_family, ''), tp.name) AS product_family
```

Plus:
- `GRANT SELECT ON vw_implied_technology_standards TO authenticated, service_role;`

**Dependencies:** Chunk 1 (view LEFT JOINs to `technology_standards`).

### Chunk 3: Create `vw_technology_standards_summary` view (S.3)

DDL from §3.4, plus:
- `GRANT SELECT ON vw_technology_standards_summary TO authenticated, service_role;`

**Dependencies:** Chunk 2 (queries `vw_implied_technology_standards`).

### Chunk 4: Create `assert_technology_standard()` RPC (S.4)

DDL from §4.2, plus:
- `GRANT EXECUTE ON FUNCTION assert_technology_standard TO authenticated;`

**Dependencies:** Chunk 1.

### Chunk 5: Create `refresh_technology_standard_prevalence()` RPC (S.5)

DDL from §4.3, plus:
- `GRANT EXECUTE ON FUNCTION refresh_technology_standard_prevalence TO authenticated;`

**Dependencies:** Chunks 1, 2.

### Post-SQL: Schema Checkpoint

```bash
# Security posture validation
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/security-posture-validation.sql

# TypeScript check
npx tsc --noEmit
```

---

## 4. Frontend Implementation (S.6)

### New Files

| File | Purpose | Est. Lines |
|------|---------|------------|
| `src/components/technology-health/StandardsIntelligencePage.tsx` | Main page: KPI cards, category table, expandable family detail | ~400 |
| `src/components/technology-health/StandardsAssertModal.tsx` | Assert/review modal: status, preferred version, notes, sunset date | ~200 |
| `src/components/technology-health/StandardsBadge.tsx` | Status badge component (5 states) | ~60 |

### Modified Files

| File | Change |
|------|--------|
| `src/components/technology-health/TechnologyHealthPage.tsx` | Add `'standards'` to `TechHealthTab`, add tab entry, add conditional render |
| `src/types/view-contracts.ts` | Add `ImpliedTechnologyStandardRow` + `TechnologyStandardsSummaryRow` |

### TypeScript View Contracts

```typescript
export interface ImpliedTechnologyStandardRow {
  namespace_id: string;
  category_id: string;
  category_name: string;
  product_family: string;
  dp_count: number;
  app_count: number;
  total_dps_in_category: number;
  prevalence_pct: number;
  most_common_product: string;
  version_count: number;
  best_lifecycle_status: string;
  standard_id: string | null;
  asserted_status: string | null;
  preferred_product_id: string | null;
  preferred_product_name: string | null;
}

export interface TechnologyStandardsSummaryRow {
  namespace_id: string;
  categories_with_data: number;
  implied_pending_review: number;
  asserted_standard_count: number;
  asserted_non_standard_count: number;
  under_review_count: number;
  retiring_count: number;
  strong_standard_categories: number;
}
```

### UI Structure

**KPI Bar (4 cards):**
1. Categories with data
2. Implied pending review (call-to-action)
3. Asserted standards
4. Strong standard categories (≥70%)

**Category Table:**
- Grouped by category from `vw_implied_technology_standards`
- Columns: Category | Dominant Family | Prevalence | Versions | Lifecycle | Status | Action
- Expandable rows → show all families per category
- "Assert" / "Review" buttons → open `StandardsAssertModal`

**Assert Modal (via `supabase.rpc('assert_technology_standard', ...)`):**
- Status: Standard / Non-Standard / Under Review / Retiring
- Preferred version: dropdown of `technology_products` in this family
- Sunset date: conditional on status = 'retiring'
- Notes: free text

**Empty State:**
"Tag deployment profiles with technology products to enable standards detection."

### Reused Components

- `LifecycleBadge` — best_lifecycle_status column
- `ModalShell` + `ModalFooter` — assertion modal chrome
- `TablePagination` — if >10 categories
- `useScopeContext()` — namespace_id
- Toast notifications — success/error feedback

---

## 5. pgTAP Assertions (S.8)

20 assertions for `technology_standards`:

| Policy | admin | editor | steward | viewer | restricted |
|--------|-------|--------|---------|--------|------------|
| SELECT own namespace | pass | pass | pass | pass | pass |
| INSERT own namespace | pass | fail | fail | fail | fail |
| UPDATE own namespace | pass | fail | fail | fail | fail |
| DELETE own namespace | pass | fail | fail | fail | fail |

Plus 4 cross-namespace isolation tests (admin cannot access other namespace's standards).

---

## 6. Risks & Blockers

| Risk | Severity | Mitigation |
|------|----------|------------|
| product_family data quality | HIGH | Chunk 0 cleanup required before views |
| Empty string vs NULL in COALESCE | HIGH | NULLIF fix in view SQL (Chunk 2) |
| T15 column confusion | LOW | Doc correction only, no Phase 1 impact |
| Low sample size for demo | MEDIUM | 63 tags sufficient for dev; consider seeding more for Knowledge Conference demo |

---

## 7. Effort Estimate

| Step | Estimate |
|------|----------|
| S.1–S.5 (SQL) | 1.5 hrs |
| S.6 (Frontend) | 4–5 hrs |
| S.7 (Validation) | 30 min |
| S.8 (pgTAP) | 30 min |
| **Total** | **~7–8 hrs** |

---

## 8. Implementation Order

1. Stuart: Chunk 0 (product_family cleanup)
2. Stuart: Chunks 1–5 (table, views, RPCs)
3. Stuart: Signal "schema done"
4. Claude: Mid-session schema checkpoint
5. Claude: TypeScript types → `view-contracts.ts`
6. Claude: `StandardsBadge.tsx`
7. Claude: `StandardsAssertModal.tsx`
8. Claude: `StandardsIntelligencePage.tsx`
9. Claude: Wire into `TechnologyHealthPage.tsx`
10. Claude: `npx tsc --noEmit` + browser verification
11. Stuart: S.7 validation against demo data
12. Stuart/Claude: S.8 pgTAP assertions

---

*Plan validated against live schema on 2026-03-11.*
*Parent architecture doc: `standards-intelligence.md` v1.1*
