# features/reference-data/hybrid-reference-table-migration.md
GetInSync Reference Table Unification — Hybrid Pattern Migration
Last updated: 2026-03-06 (v1.0)

**Status:** PARKED — Execute after City of Garland import (March 2026)

---

## 1. Purpose

Unify all 18 reference/category tables into a single **hybrid pattern**: OOTB system rows (locked, visible to all tenants) + namespace-extensible rows that tenants can add themselves.

### Current State (Two Broken Patterns)

| Pattern | Tables | Problem |
|---|---|---|
| **Namespace-scoped** (Group A) | 5 tables | System defaults duplicated across 17 namespaces (238+ rows per table). No `is_system` protection. Adding a new category requires 17 inserts. |
| **System-only** (Group B) | 13 tables | No way for tenants to add custom values. Global only. |

### Target State (Unified Hybrid Pattern)

| Row Type | `is_system` | `namespace_id` | Who can edit? |
|---|---|---|---|
| OOTB | `true` | `NULL` | Nobody (locked, visible to all) |
| Tenant-added | `false` | `<namespace_id>` | Namespace admins only |

**Query pattern:** `WHERE (namespace_id IS NULL OR namespace_id = :user_ns) AND is_active = true`

---

## 2. Motivation

- **endoflife.date alignment:** Adding Framework and Language/Runtime technology categories requires inserting into all 17 namespaces under current pattern
- **Composite applications (Phase 22):** Composite tech stack aggregation needs framework/language categories to surface runtime lifecycle risks (Node.js EOL, .NET EOL) in composite risk rollups
- **SOC2 consistency:** Reference data should be centrally managed with audit trail, not duplicated per tenant
- **Tenant extensibility:** Enterprise tenants need custom categories (e.g., "Mainframe", "IoT Gateway") without modifying system defaults

---

## 3. Group A: 5 Namespace-Scoped Tables

These currently duplicate system defaults across every namespace. Migration requires deduplication, schema changes, FK re-pointing, and frontend updates.

### 3.1 `technology_product_categories` — HIGH complexity

- **Current:** 238 rows, 14 distinct names, 17 namespaces
- **Issues:** Missing `code` column, missing `is_system`, unique on `(namespace_id, name)` not code
- **Frontend bug:** `TechnologyProductModal.tsx` queries with NO namespace filter (data leakage)
- **New categories to add:** Framework (display_order 15), Language/Runtime (display_order 16)
- **FK:** `technology_products.category_id`
- **Frontend files:** `TechnologyProductModal.tsx`, `TechnologyCatalogSettings.tsx`, `TechnologyStackList.tsx`, `LinkTechnologyProductModal.tsx`, `LinkedTechnologyProductsList.tsx`, `ConnectionsVisual.tsx`

### 3.2 `application_categories` — MEDIUM complexity

- **Current:** 238 rows, 14 distinct codes, 17 namespaces
- **Has:** code column, proper unique on `(namespace_id, code)`
- **FK:** `application_category_assignments.category_id` (junction table)
- **Frontend:** `useApplicationCategories.ts` hook + consumers

### 3.3 `software_product_categories` — MEDIUM complexity

- **Current:** 204 rows, 12 distinct codes, 17 namespaces
- **Has:** code column, proper unique on `(namespace_id, code)`
- **FK:** `software_products.category_id`
- **Frontend:** `SoftwareProductModal.tsx`

### 3.4 `service_type_categories` — LOW-MEDIUM complexity

- **Current:** 75 rows, 5 distinct codes, 15 namespaces
- **Has:** code column, proper unique on `(namespace_id, code)`
- **FK:** `service_types.category_id`
- **Frontend:** `ITServiceCatalogSettings.tsx`

### 3.5 `service_types` — MEDIUM complexity

- **Current:** 226 rows, 17 distinct codes, 17 namespaces
- **Has:** code column, `category_id` FK to `service_type_categories`
- **FK:** `it_services.service_type_id`
- **Frontend:** `ITServiceCatalogSettings.tsx`, `ServicePickerModal.tsx`

### NOT migrating: `it_service_providers`

This is a junction table (links IT Services to Deployment Profiles), not a reference table. Namespace-scoped is correct for RLS. Leave as-is.

---

## 4. Group A Migration Steps (Stuart SQL — per table)

### Step 1: Schema changes

```sql
-- For each of the 5 tables:
ALTER TABLE <table> ADD COLUMN is_system BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE <table> ALTER COLUMN namespace_id DROP NOT NULL;

-- technology_product_categories only (missing code column):
ALTER TABLE technology_product_categories ADD COLUMN code TEXT;
```

### Step 2: Identify and deduplicate system rows

```sql
-- Strategy: Pick one namespace's rows as the canonical "system" set
-- For each distinct code/name:
--   1. Choose one row as the system row (set is_system = true, namespace_id = NULL)
--   2. Update all FK references from duplicate rows to point to the system row
--   3. Delete duplicate rows

-- Example for technology_product_categories:
-- First, identify one canonical row per distinct name
WITH canonical AS (
  SELECT DISTINCT ON (name) id, name
  FROM technology_product_categories
  ORDER BY name, created_at ASC  -- oldest row wins
)
UPDATE technology_product_categories
SET is_system = true, namespace_id = NULL
WHERE id IN (SELECT id FROM canonical);

-- Then re-point FKs and delete duplicates
-- (Full script to be generated at execution time with actual IDs)
```

### Step 3: Unique constraints

```sql
-- Drop old composite unique constraint:
ALTER TABLE <table> DROP CONSTRAINT <old_unique_constraint>;

-- Add new partial unique indexes:
CREATE UNIQUE INDEX idx_<table>_system_code
  ON <table>(code) WHERE namespace_id IS NULL;
CREATE UNIQUE INDEX idx_<table>_ns_code
  ON <table>(namespace_id, code) WHERE namespace_id IS NOT NULL;
```

### Step 4: RLS policy replacement

```sql
-- Drop all existing policies (7 per table currently)
DROP POLICY "..." ON <table>;

-- Add 4 new policies:

-- 1. SELECT: authenticated sees system rows + own namespace rows
CREATE POLICY "View system and own namespace categories"
  ON <table> FOR SELECT TO authenticated
  USING (
    namespace_id IS NULL  -- system rows
    OR namespace_id IN (
      SELECT DISTINCT w.namespace_id FROM workspaces w
      JOIN workspace_users wu ON wu.workspace_id = w.id
      WHERE wu.user_id = auth.uid()
    )
  );

-- 2. INSERT: namespace admins, must be non-system
CREATE POLICY "Namespace admins can add custom categories"
  ON <table> FOR INSERT TO authenticated
  WITH CHECK (
    is_system = false
    AND namespace_id IS NOT NULL
    AND namespace_id IN (
      SELECT DISTINCT w.namespace_id FROM workspaces w
      JOIN workspace_users wu ON wu.workspace_id = w.id
      WHERE wu.user_id = auth.uid() AND wu.role IN ('admin')
    )
  );

-- 3. UPDATE/DELETE: namespace admins on own non-system rows
CREATE POLICY "Namespace admins can manage their custom categories"
  ON <table> FOR UPDATE TO authenticated
  USING (
    is_system = false
    AND namespace_id IN (
      SELECT DISTINCT w.namespace_id FROM workspaces w
      JOIN workspace_users wu ON wu.workspace_id = w.id
      WHERE wu.user_id = auth.uid() AND wu.role IN ('admin')
    )
  );

CREATE POLICY "Namespace admins can delete their custom categories"
  ON <table> FOR DELETE TO authenticated
  USING (
    is_system = false
    AND namespace_id IN (
      SELECT DISTINCT w.namespace_id FROM workspaces w
      JOIN workspace_users wu ON wu.workspace_id = w.id
      WHERE wu.user_id = auth.uid() AND wu.role IN ('admin')
    )
  );

-- 4. Platform admins: full access (via is_platform_admin RPC)
CREATE POLICY "Platform admins can manage all categories"
  ON <table> FOR ALL TO authenticated
  USING (is_platform_admin(auth.uid()))
  WITH CHECK (is_platform_admin(auth.uid()));
```

### Step 5: Add new categories (technology_product_categories)

```sql
INSERT INTO technology_product_categories (code, name, description, display_order, is_system, namespace_id)
VALUES
  ('framework', 'Framework', 'Application frameworks and runtime platforms (.NET, Spring, React, Django)', 15, true, NULL),
  ('language_runtime', 'Language/Runtime', 'Programming languages and runtime environments (Java, Python, Node.js, Go)', 16, true, NULL);
```

---

## 5. Group B: 13 System-Only Tables

These already have `is_system` and `code`. They need `namespace_id` (nullable) added + RLS updated to allow tenant extensions.

| Table | Current Rows | Extension Use Cases |
|---|---|---|
| `hosting_types` | ~8 | "Co-located", "Edge", "Sovereign Cloud" |
| `environments` | ~5 | "STAGING", "DR", "SANDBOX", "PERF" |
| `lifecycle_statuses` | ~6 | Custom lifecycle stages |
| `criticality_types` | ~4 | Custom severity levels |
| `cloud_providers` | ~5 | Regional/niche providers |
| `dr_statuses` | ~4 | Custom DR classifications |
| `remediation_efforts` | ~6 | Custom effort sizes |
| `operational_statuses` | ~4 | Custom operational states |
| `sensitivity_types` | ~4 | Custom sensitivity levels |
| `data_classification_types` | ~4 | Custom data classifications |
| `data_format_types` | ~8 | Custom data formats |
| `data_tag_types` | ~8 | Custom data tags |
| `integration_direction_types` | ~3 | Unlikely, but consistent pattern |
| `integration_method_types` | ~7 | Custom integration methods |
| `integration_frequency_types` | ~5 | Custom frequencies |
| `integration_status_types` | ~4 | Custom statuses |

### Migration per table (simpler than Group A):

```sql
-- 1. Add nullable namespace_id
ALTER TABLE <table> ADD COLUMN namespace_id UUID REFERENCES namespaces(id) ON DELETE CASCADE;

-- 2. Existing rows are already system-level (is_system = true, namespace_id = NULL) — no data migration needed

-- 3. Add namespace-scoped unique index (system code uniqueness already enforced by existing UNIQUE on code)
CREATE UNIQUE INDEX idx_<table>_ns_code
  ON <table>(namespace_id, code) WHERE namespace_id IS NOT NULL;

-- 4. Update RLS policies to allow namespace-scoped inserts
-- Same 4-policy pattern as Group A (see Section 4, Step 4)
```

### Frontend impact (Group B): MINIMAL

- Existing queries already work (no namespace filter, `is_active = true`)
- No code changes needed for read paths — system rows still returned
- Settings pages would need "add custom" UI (future enhancement, not blocking)

---

## 6. Frontend Changes (Group A only)

### Query pattern update

```typescript
// Before (namespace-scoped):
.from('technology_product_categories')
.select('id, name, description, display_order')
.eq('namespace_id', namespaceId)
.eq('is_active', true)
.order('display_order')

// After (hybrid):
.from('technology_product_categories')
.select('id, code, name, description, display_order, is_system')
.or(`namespace_id.is.null,namespace_id.eq.${namespaceId}`)
.eq('is_active', true)
.order('display_order')
```

### Files to update

| File | Table(s) | Change |
|------|----------|--------|
| `src/components/TechnologyProductModal.tsx` | technology_product_categories | Fix namespace filter bug + new pattern |
| `src/pages/settings/TechnologyCatalogSettings.tsx` | technology_product_categories | New query pattern |
| `src/components/TechnologyStackList.tsx` | technology_product_categories | Join still works (via category_id) |
| `src/components/LinkTechnologyProductModal.tsx` | technology_product_categories | Join still works |
| `src/components/LinkedTechnologyProductsList.tsx` | technology_product_categories | Join still works |
| `src/components/integrations/ConnectionsVisual.tsx` | technology_product_categories | Join still works |
| `src/hooks/useApplicationCategories.ts` | application_categories | New query pattern |
| `src/components/SoftwareProductModal.tsx` | software_product_categories | New query pattern |
| `src/pages/settings/ITServiceCatalogSettings.tsx` | service_type_categories, service_types | New query pattern (2 tables) |
| `src/components/ServicePickerModal.tsx` | service_types | New query pattern |

### TypeScript type updates

Add `is_system: boolean` and `code: string` to category interfaces in relevant type files.

### Settings UI enhancement (future)

Category management pages should show system rows as read-only (greyed out / lock icon) and allow tenants to add/edit/delete only their custom rows.

---

## 7. Execution Order

### Batch 1 — Group A (5 namespace-scoped -> hybrid) — Stuart SQL + Claude frontend

1. **technology_product_categories** — highest impact, has frontend bug, needs code column, add Framework + Language/Runtime
2. **service_type_categories + service_types** together — parent-child FK dependency
3. **application_categories** — straightforward
4. **software_product_categories** — straightforward

### Batch 2 — Group B (13 system-only -> extensible) — Stuart SQL only

5. **All 13 system tables** in one script — add nullable namespace_id + namespace unique index + RLS update
6. No frontend changes needed (read paths unchanged, "add custom" UI is future)

---

## 8. Verification

### After Batch 1 (each table — Stuart SQL):

- Run security posture validation
- Verify row counts: system rows + namespace rows = expected total
- Verify no orphaned FK references
- Run mid-session schema checkpoint

### After Batch 1 (frontend — Claude Code):

- `npx tsc --noEmit` — zero errors
- Dev server: verify dropdowns show system + tenant categories
- Verify system rows appear non-editable in settings pages
- Technology catalog shows all 16 categories (14 existing + 2 new: Framework, Language/Runtime)
- Application category assignments still work
- Software product category dropdowns still populate
- IT service type hierarchy still displays
- `npm run build` — production build clean

### After Batch 2 (Stuart SQL — no frontend changes):

- Run security posture validation
- Verify all 13 tables have nullable namespace_id + namespace unique index
- Verify existing frontend queries still return system rows (no regressions)
- Run full session-end checklist

---

## 9. Architecture Doc Updates (post-migration)

- `docs-architecture/identity-security/rls-policy.md` — document new hybrid RLS pattern
- `docs-architecture/operations/new-table-checklist.md` — add "reference table" checklist variant
- `docs-architecture/MANIFEST.md` — bump version
- `CLAUDE.md` — update "Existing Reference Tables" section to note hybrid pattern + list new categories

---

## 10. Related Documents

| Document | Relevance |
|----------|-----------|
| `core/composite-application.md` | Composite tech stack aggregation (Section 8.2) needs framework/language categories |
| `features/technology-health/lifecycle-intelligence.md` | endoflife.date category alignment, Phase 27e vendor source health |
| `identity-security/rls-policy.md` | RLS policy patterns (will need hybrid pattern added) |
| `operations/new-table-checklist.md` | New table creation standards |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-06 | Initial document. Full migration plan for 18 reference tables (5 Group A + 13 Group B). Parked for post-City of Garland import execution. |
