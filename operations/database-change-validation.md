# GetInSync NextGen — Database Change Validation Skill

**Version:** 1.0  
**Date:** February 9, 2026  
**Status:** 🟢 AS-BUILT  
**Purpose:** Session-end validation — run against all database changes to get a clear ✅/❌ signal

---

## How To Use This Skill

At the end of any session that involved database changes, run through the applicable sections below. Each section has:

1. **When to run** — which changes trigger this check
2. **Validation query** — copy-paste SQL
3. **Expected result** — what pass/fail looks like

**Workflow:**
```
Session ends → List all tables touched → Run applicable checks → Fix any ❌ → Confirm all ✅
```

---

## Quick Reference: The 5 Things Every New Table Needs

| # | Requirement | Symptom If Missing |
|---|-------------|-------------------|
| 1 | GRANT SELECT to authenticated | Frontend gets empty results, no error |
| 2 | RLS enabled + policies | All queries return empty |
| 3 | Audit trigger | SOC2 gap — changes not logged |
| 4 | updated_at trigger | Stale timestamps, no change tracking |
| 5 | CHECK constraints aligned | Insert fails with constraint violation |

---

## Section 1: New Tables

**When to run:** Any session that created a new table.

### 1.1 — List All Tables Without GRANTs

```sql
-- VALIDATION: Tables missing authenticated GRANT
-- Expected: Empty result = PASS
-- Any rows = FAIL (table invisible to frontend)
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.tablename NOT IN (
    SELECT table_name FROM information_schema.role_table_grants
    WHERE grantee = 'authenticated' AND table_schema = 'public'
  )
ORDER BY t.tablename;
```

### 1.2 — List All Tables Without RLS Enabled

```sql
-- VALIDATION: Tables with RLS disabled
-- Expected: Only system/Supabase tables = PASS
-- Any GetInSync table without RLS = FAIL
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
ORDER BY tablename;
```

### 1.3 — List All Tables Without RLS Policies

```sql
-- VALIDATION: Tables with RLS enabled but NO policies
-- Expected: Empty result = PASS
-- Any rows = FAIL (RLS blocks everything)
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p WHERE p.tablename = t.tablename
  )
ORDER BY t.tablename;
```

### 1.4 — List All Tables Without Audit Trigger

```sql
-- VALIDATION: Data/access tables missing audit trigger
-- Expected: Only lookup/reference/config tables = PASS
-- Core data or access control tables without = FAIL
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND NOT EXISTS (
    SELECT 1 FROM pg_trigger tr
    WHERE tr.tgrelid = ('public.' || t.tablename)::regclass
      AND tr.tgname LIKE 'audit_%'
  )
ORDER BY t.tablename;
```

**Note:** Not every table needs an audit trigger. Use this classification:

| Table Type | Needs Audit Trigger? | Examples |
|-----------|---------------------|----------|
| Core data | ✅ Yes | applications, deployment_profiles, portfolios |
| Access control | ✅ Yes | users, namespace_users, workspace_users, invitations |
| Junction tables | ✅ Yes | portfolio_assignments, application_contacts |
| Lookup/reference | ❌ No | countries, cloud_providers, namespace_role_options |
| Audit table itself | ❌ No (recursion) | audit_logs |
| System/config | ⚠️ Optional | assessment_factors, organization_settings |

### 1.5 — List All Mutable Tables Without updated_at Trigger

```sql
-- VALIDATION: Tables with updated_at column but no trigger
-- Expected: Empty result = PASS
SELECT t.tablename
FROM pg_tables t
JOIN information_schema.columns c
  ON c.table_name = t.tablename AND c.column_name = 'updated_at'
WHERE t.schemaname = 'public'
  AND c.table_schema = 'public'
  AND NOT EXISTS (
    SELECT 1 FROM pg_trigger tr
    WHERE tr.tgrelid = ('public.' || t.tablename)::regclass
      AND tr.tgname LIKE 'update_%_updated_at'
  )
ORDER BY t.tablename;
```

---

## Section 2: Column/Constraint Changes

**When to run:** Any session that added columns, changed defaults, or modified CHECK constraints.

### 2.1 — CHECK Constraint Alignment

```sql
-- VALIDATION: All CHECK constraints on role/status columns
-- Review: Ensure defaults are allowed by their CHECK
SELECT conrelid::regclass AS table_name,
       conname,
       pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE contype = 'c'
  AND conrelid::regclass::text LIKE 'public.%'
  AND (conname LIKE '%role%' OR conname LIKE '%status%' OR conname LIKE '%tier%')
ORDER BY conrelid::regclass::text, conname;
```

### 2.2 — Column Default vs CHECK Validation

```sql
-- VALIDATION: Columns with defaults that might violate CHECK
-- Manual review: ensure each default value is in its CHECK constraint
SELECT c.table_name, c.column_name, c.column_default,
       cc.check_clause
FROM information_schema.columns c
JOIN information_schema.check_constraints cc
  ON cc.constraint_schema = c.table_schema
  AND cc.check_clause LIKE '%' || c.column_name || '%'
WHERE c.table_schema = 'public'
  AND c.column_default IS NOT NULL
  AND c.column_default NOT LIKE '%gen_random_uuid%'
  AND c.column_default NOT LIKE '%now()%'
ORDER BY c.table_name, c.column_name;
```

---

## Section 3: Role/Permission Changes

**When to run:** Any session that modified roles, permissions, or access control.

### 3.1 — Role Consistency Across Tables

```sql
-- VALIDATION: namespace_role values should match namespace_role_options
-- Expected: All roles exist in lookup table = PASS
SELECT DISTINCT u.namespace_role
FROM users u
WHERE u.namespace_role NOT IN (SELECT role FROM namespace_role_options)
UNION ALL
SELECT DISTINCT nu.role
FROM namespace_users nu
WHERE nu.role NOT IN (SELECT role FROM namespace_role_options);
```

```sql
-- VALIDATION: workspace_users roles should match workspace_role_options
SELECT DISTINCT wu.role
FROM workspace_users wu
WHERE wu.role NOT IN (SELECT role FROM workspace_role_options);
```

### 3.2 — Orphaned Users (No Namespace)

```sql
-- VALIDATION: Users without namespace assignment
-- Expected: Only brand-new users mid-signup = PASS
SELECT id, email, namespace_id, namespace_role
FROM users
WHERE namespace_id IS NULL;
```

### 3.3 — Users Without Any Workspace Access

```sql
-- VALIDATION: Users with namespace but no workspace_users entry
-- Expected: Empty or only viewers who haven't been assigned yet
SELECT u.email, u.namespace_role, n.name as namespace
FROM users u
JOIN namespaces n ON n.id = u.namespace_id
WHERE NOT EXISTS (
  SELECT 1 FROM workspace_users wu
  JOIN workspaces w ON w.id = wu.workspace_id
  WHERE wu.user_id = u.id AND w.namespace_id = u.namespace_id
);
```

---

## Section 4: Foreign Key Safety

**When to run:** Any session that added FK relationships or deleted data.

### 4.1 — FKs That Block Deletion

```sql
-- VALIDATION: FKs without ON DELETE action (will block deletes)
-- Review: Intentional RESTRICT is fine, accidental blocking is not
SELECT
  tc.table_name AS child_table,
  kcu.column_name AS child_column,
  ccu.table_name AS parent_table,
  rc.delete_rule
FROM information_schema.referential_constraints rc
JOIN information_schema.table_constraints tc ON tc.constraint_name = rc.constraint_name
JOIN information_schema.key_column_usage kcu ON kcu.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = rc.unique_constraint_name
WHERE tc.table_schema = 'public'
  AND rc.delete_rule = 'NO ACTION'
ORDER BY parent_table, child_table;
```

**Known issue:** `audit_logs.user_id → auth.users` should be ON DELETE SET NULL (fixed Feb 9).

---

## Section 5: Audit Logging Integrity

**When to run:** Any session, as a general health check.

### 5.1 — Audit Trigger Inventory

```sql
-- VALIDATION: All audit triggers and their functions
-- Review: All should use audit_log_trigger()
SELECT tgrelid::regclass AS table_name,
       tgname AS trigger_name,
       tgfoid::regproc AS function_name
FROM pg_trigger
WHERE tgname LIKE 'audit_%'
ORDER BY tgrelid::regclass::text;
```

### 5.2 — Recent Audit Activity (Sanity Check)

```sql
-- VALIDATION: Audit logs being written
-- Expected: Recent entries for any tables you modified this session
SELECT event_category, event_type, entity_type, count(*)
FROM audit_logs
WHERE created_at > now() - interval '4 hours'
GROUP BY event_category, event_type, entity_type
ORDER BY event_category, entity_type;
```

### 5.3 — Event Category Distribution

```sql
-- VALIDATION: All 4 categories should have entries
-- Expected: access_control, data_change, session, usage
SELECT event_category, count(*), max(created_at) as latest
FROM audit_logs
GROUP BY event_category
ORDER BY event_category;
```

---

## Section 6: Namespace Default Safety

**When to run:** Any session that created namespaces or workspaces.

### 6.1 — Namespaces Without Default Workspace

```sql
-- VALIDATION: Every namespace needs a default workspace
-- Expected: Empty result = PASS
SELECT n.name, n.id
FROM namespaces n
WHERE NOT EXISTS (
  SELECT 1 FROM workspaces w
  WHERE w.namespace_id = n.id AND w.is_default = true
);
```

### 6.2 — Namespaces Without Default Portfolio

```sql
-- VALIDATION: Every workspace needs a default portfolio
-- Expected: Empty result = PASS
SELECT w.name as workspace, n.name as namespace
FROM workspaces w
JOIN namespaces n ON n.id = w.namespace_id
WHERE NOT EXISTS (
  SELECT 1 FROM portfolios p
  WHERE p.workspace_id = w.id AND p.is_default = true
);
```

---

## Section 7: Full Database Health Check

**When to run:** End of any significant session, or weekly.

### 7.1 — Master Statistics

```sql
-- VALIDATION: Database overview
SELECT
  (SELECT count(*) FROM pg_tables WHERE schemaname = 'public') as total_tables,
  (SELECT count(*) FROM pg_policies WHERE schemaname = 'public') as total_policies,
  (SELECT count(*) FROM pg_trigger t
   JOIN pg_class c ON c.oid = t.tgrelid
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND t.tgname LIKE 'audit_%') as audit_triggers,
  (SELECT count(*) FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public') as total_functions;
```

### 7.2 — Schema Backup Reminder

```sql
-- If significant changes were made, run a fresh backup:
-- pg_dump via session pooler → commit to GitHub
-- Last backup: getinsync-nextgen-schema-2026-02-08.sql
SELECT 'Schema backup needed if tables/functions/triggers changed' as reminder;
```

---

## New Table Quick Template

### Lookup Table (Read-Only Reference)
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
-- No audit trigger (lookup table)
-- No updated_at trigger (immutable reference)
```

### Tenant-Scoped Data Table
```sql
CREATE TABLE {table} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  -- add columns --
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view {table}" ON {table}
  FOR SELECT USING (namespace_id = get_current_namespace_id() OR check_is_platform_admin());

CREATE POLICY "Editors can insert {table}" ON {table}
  FOR INSERT WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = {table}.workspace_id
        AND wu.user_id = auth.uid()
        AND wu.role IN ('admin','editor')))
  );

CREATE POLICY "Editors can update {table}" ON {table}
  FOR UPDATE USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = {table}.workspace_id
        AND wu.user_id = auth.uid()
        AND wu.role IN ('admin','editor')))
  ) WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id))
  );

CREATE POLICY "Admins can delete {table}" ON {table}
  FOR DELETE USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = {table}.workspace_id
        AND wu.user_id = auth.uid()
        AND wu.role = 'admin'))
  );

-- GRANTs
GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO authenticated;

-- Triggers
CREATE TRIGGER update_{table}_updated_at
  BEFORE UPDATE ON {table}
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER audit_{table}
  AFTER INSERT OR UPDATE OR DELETE ON {table}
  FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

---

## Common Pitfalls (Lessons Learned)

| # | Pitfall | Symptom | Root Cause | Fix |
|---|---------|---------|------------|-----|
| 1 | Missing GRANT | Empty results, no error | Table created without GRANT | `GRANT SELECT ON {table} TO authenticated` |
| 2 | Missing GRANT on anon | Signup/public pages 403 | Public RPCs need anon access | `GRANT ... TO anon` or use SECURITY DEFINER RPC |
| 3 | RLS enabled, no policies | All queries empty | Forgot to add policies after enabling RLS | Add SELECT/INSERT/UPDATE/DELETE policies |
| 4 | CHECK default mismatch | 500 on INSERT via trigger | Default value not in CHECK constraint | Align default to CHECK allowed values |
| 5 | Role name mismatch | Signup fails, invitation fails | Different role names across tables | Use lookup tables, align CHECKs |
| 6 | NULL FK in RLS | Rows with NULL FK hidden | RLS requires FK to match namespace, NULL never matches | Add `IS NULL OR` before IN subquery |
| 7 | FK blocks delete | Cannot delete parent row | No ON DELETE clause on FK | Add CASCADE, SET NULL, or RESTRICT intentionally |
| 8 | audit_logs FK to auth.users | User deletion blocked | FK without ON DELETE SET NULL | Fix FK to ON DELETE SET NULL |
| 9 | Parameter name change | RPC 404 from frontend | DROP + CREATE changed param name | Coordinate frontend update with backend |
| 10 | Trigger fires during RPC | Duplicate audit entries | Both frontend and trigger log same event | Frontend: session/usage only. Trigger: data/access only |

---

## Related Architecture Documents

| Document | What It Covers | When to Consult |
|----------|---------------|-----------------|
| `identity-security/rls-policy.md` | RLS patterns for all 66+ tables, policy templates, SOC2 matrix | Writing new RLS policies |
| `identity-security/rls-policy-addendum.md` | GRANT lesson, NULL FK lesson, 2 new tables | Debugging RLS issues |
| `schema/audit-logging-ddl.sql` | audit_logs table DDL, indexes, RLS, GRANTs | Creating audit infrastructure |
| `schema/audit-logging-functions.sql` | audit_log_trigger(), SOC2 evidence RPCs | Understanding trigger function |
| `schema/audit-logging-triggers.sql` | Which tables have audit triggers attached | Adding triggers to new tables |
| `identity-security/soc2-evidence-collection.md` | Monthly evidence collection procedure | SOC2 audit prep |
| `MANIFEST.md` | Master document index with status tags | Finding any architecture doc |
| `identity-security/identity-security.md` | Auth, roles, audit log schema design | Security architecture decisions |
| `identity-security/user-registration.md` | Signup flows, invitation lifecycle | User onboarding changes |

---

## Future: Automated Validation

**Goal:** Single command → red/green signal for all checks.

**Phase 1 (Current):** Manual SQL queries, human reviews results  
**Phase 2:** SQL script that runs all queries, outputs pass/fail summary  
**Phase 3:** Supabase Edge Function that runs validation on demand  
**Phase 4:** CI/CD integration — validation runs on every schema migration

**Phase 2 target SQL script structure:**
```sql
DO $$
DECLARE
  v_result TEXT := '';
  v_count INT;
BEGIN
  -- Check 1: Tables without GRANTs
  SELECT count(*) INTO v_count FROM pg_tables t
  WHERE t.schemaname = 'public'
    AND t.tablename NOT IN (
      SELECT table_name FROM information_schema.role_table_grants
      WHERE grantee = 'authenticated' AND table_schema = 'public');
  v_result := v_result || 'Tables without GRANT: ' || v_count || E'\n';

  -- Check 2: Tables without RLS
  SELECT count(*) INTO v_count FROM pg_tables
  WHERE schemaname = 'public' AND rowsecurity = false;
  v_result := v_result || 'Tables without RLS: ' || v_count || E'\n';

  -- ... more checks ...

  RAISE NOTICE '%', v_result;
END $$;
```

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-09 | Initial skill. 7 validation sections, 15 queries, templates, pitfall registry. Born from repeated GRANT/RLS/CHECK bugs during invitation signup, role tables, and integration management. |

---

*Document: operations/database-change-validation.md*  
*Session-end validation: Run applicable sections → Fix any ❌ → Confirm all ✅*  
*February 2026*
