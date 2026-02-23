# GetInSync NextGen — New Table Checklist

**Version:** 1.0  
**Date:** February 9, 2026  
**Status:** 🟢 Active  
**Lesson Source:** Repeated RLS/GRANT bugs during Q1 2026 development

---

## The Checklist

Every new table MUST complete all applicable steps before it's considered done.

### 1. Schema
- [ ] Table created with appropriate columns and types
- [ ] Primary key (uuid DEFAULT gen_random_uuid())
- [ ] Foreign keys with appropriate ON DELETE (CASCADE, SET NULL, or RESTRICT)
- [ ] CHECK constraints on enum-style columns
- [ ] Column defaults set (especially role columns — never default to a non-existent value)
- [ ] namespace_id column if tenant-scoped (FK → namespaces ON DELETE CASCADE)
- [ ] workspace_id column if workspace-scoped (FK → workspaces ON DELETE CASCADE)
- [ ] created_at (timestamptz DEFAULT now())
- [ ] updated_at (timestamptz DEFAULT now()) if mutable

### 2. GRANTs ⚠️ MOST FORGOTTEN STEP
- [ ] `GRANT SELECT ON {table} TO authenticated;`
- [ ] `GRANT INSERT ON {table} TO authenticated;` (if users create rows)
- [ ] `GRANT UPDATE ON {table} TO authenticated;` (if users edit rows)
- [ ] `GRANT DELETE ON {table} TO authenticated;` (if users delete rows)
- [ ] `GRANT SELECT ON {table} TO anon;` (only if anon access needed — rare)
- [ ] **Lookup/reference tables:** SELECT only, to both authenticated and anon

**Rule:** No GRANT = invisible to the frontend, regardless of RLS policies.

### 3. Row Level Security (RLS)
- [ ] `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
- [ ] SELECT policy (who can read)
- [ ] INSERT policy (who can create) — must include WITH CHECK
- [ ] UPDATE policy (who can edit) — must include both USING and WITH CHECK
- [ ] DELETE policy (who can delete)
- [ ] Platform admin bypass in each policy: `check_is_platform_admin()`
- [ ] Namespace scoping: `namespace_id = get_current_namespace_id()`

**Lookup tables shortcut:**
```sql
CREATE POLICY "Anyone can view {table}" ON {table} FOR SELECT USING (true);
```

### 4. Triggers
- [ ] `update_updated_at` trigger (if table has updated_at column):
```sql
CREATE TRIGGER update_{table}_updated_at
  BEFORE UPDATE ON {table}
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```
- [ ] Audit trigger (if table contains user data or access control):
```sql
CREATE TRIGGER audit_{table}
  AFTER INSERT OR UPDATE OR DELETE ON {table}
  FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

### 5. Validation Queries

Run after creation to verify everything:

```sql
-- Check GRANTs exist
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = '{table}' AND grantee IN ('authenticated', 'anon');

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = '{table}';

-- Check RLS policies exist
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = '{table}';

-- Check triggers exist
SELECT tgname, tgfoid::regproc 
FROM pg_trigger 
WHERE tgrelid = 'public.{table}'::regclass AND NOT tgisinternal;

-- Check constraints
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'public.{table}'::regclass;
```

---

## Table Categories

| Category | GRANT | RLS | Audit Trigger | updated_at |
|----------|-------|-----|---------------|------------|
| **Core data** (applications, DPs, portfolios) | CRUD to authenticated | Namespace + workspace scoped | ✅ Yes | ✅ Yes |
| **Access control** (users, namespace_users, workspace_users) | Varies | Namespace scoped | ✅ Yes | ✅ Yes |
| **Lookup/reference** (role_options, countries, regions) | SELECT only | `USING (true)` | ❌ No | ❌ No |
| **Junction tables** (portfolio_assignments, invitation_workspaces) | CRUD to authenticated | Namespace scoped | ✅ Yes | ✅ Yes |
| **Audit/logging** (audit_logs) | INSERT to authenticated | Namespace scoped SELECT | ❌ No (avoid recursion) | ❌ No |
| **Configuration** (assessment_factors, thresholds) | CRUD to authenticated | Namespace scoped | Optional | ✅ Yes |

---

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Missing GRANT | Frontend gets empty results, no error | Add GRANT SELECT |
| Missing GRANT on anon | Signup/public pages fail with 403 | Add GRANT to anon, or use SECURITY DEFINER RPC |
| RLS enabled but no policies | All queries return empty | Add appropriate policies |
| CHECK constraint mismatch | Insert fails with 23514 | Align CHECK values across related tables |
| Column default not in CHECK | Trigger inserts fail | Ensure default value passes CHECK constraint |
| Missing audit trigger | SOC2 gap — changes not logged | Add audit_log_trigger |
| FK without ON DELETE | Delete blocked by FK constraint | Use CASCADE, SET NULL, or RESTRICT intentionally |
| audit_logs FK to auth.users | User deletion blocked | Use ON DELETE SET NULL |

---

## Quick Copy Templates

### Lookup Table (minimal)
```sql
CREATE TABLE {table} (
  {key} TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);

ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view {table}" ON {table} FOR SELECT USING (true);
GRANT SELECT ON {table} TO authenticated, anon;
```

### Tenant-Scoped Data Table (full)
```sql
CREATE TABLE {table} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  -- add columns here
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view {table} in current namespace" ON {table}
  FOR SELECT USING (namespace_id = get_current_namespace_id());

CREATE POLICY "Admins can insert {table} in current namespace" ON {table}
  FOR INSERT WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
  );

CREATE POLICY "Admins can update {table} in current namespace" ON {table}
  FOR UPDATE USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
  ) WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
  );

CREATE POLICY "Admins can delete {table} in current namespace" ON {table}
  FOR DELETE USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO authenticated;

CREATE TRIGGER update_{table}_updated_at
  BEFORE UPDATE ON {table}
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER audit_{table}
  AFTER INSERT OR UPDATE OR DELETE ON {table}
  FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-09 | Initial checklist. Born from repeated GRANT/RLS bugs during invitation signup, role option tables, and integration management. |

---

*Document: operations/new-table-checklist.md*  
*February 2026*
