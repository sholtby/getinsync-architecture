# GetInSync NextGen — Security Validation Runbook

**Version:** 1.0  
**Date:** February 10, 2026  
**Status:** 🟢 AS-BUILT  
**Purpose:** Periodic security posture validation — run against Supabase Security Advisor findings and proactive checks  
**SOC2 Controls:** CC6.1, CC6.2, CC6.6, CC7.1

---

## How To Use This Skill

Run these checks:
- **After every Supabase Security Advisor email** (weekly)
- **After creating new views** (any session)
- **After creating new functions** (any session)
- **Monthly** as part of SOC2 evidence collection

**Workflow:**
```
Security Advisor email → Run all checks → Fix any ❌ → Re-run Security Advisor → Confirm 0 errors
```

**Relationship to Other Skills:**
| Skill | Scope |
|-------|-------|
| `operations/database-change-validation` | Session-end — tables, GRANTs, RLS, triggers |
| `identity-security/soc2-evidence-collection` | Monthly — evidence snapshots, audit log review |
| `identity-security/security-posture-overview` | External — sales/prospect-facing security posture |
| **This document** | Periodic — views, functions, Security Advisor alignment |

---

## Section 1: View Security (SECURITY INVOKER)

**Why it matters:** Views default to `SECURITY DEFINER` in PostgreSQL, meaning they run with the view creator's permissions (postgres superuser). This **bypasses all RLS policies** on underlying tables, creating a multi-tenant isolation gap. All views must use `security_invoker = true` so they respect the calling user's RLS.

### 1.1 — List All Views Without security_invoker

```sql
-- VALIDATION: Views missing security_invoker = true
-- Expected: Empty result = PASS
-- Any rows without security_invoker=true in options = FAIL
SELECT c.relname AS view_name,
       pg_catalog.array_to_string(c.reloptions, ', ') AS options
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'v'
  AND (c.reloptions IS NULL OR NOT c.reloptions::text[] @> ARRAY['security_invoker=true'])
ORDER BY c.relname;
```

**If FAIL — fix with:**
```sql
ALTER VIEW public.<view_name> SET (security_invoker = true);
```

### 1.2 — Count All Views and Their Security Status

```sql
-- AUDIT: Summary of all views and security_invoker status
SELECT c.relname AS view_name,
       CASE 
         WHEN c.reloptions::text[] @> ARRAY['security_invoker=true'] THEN '✅ invoker'
         ELSE '❌ definer (BYPASSES RLS)'
       END AS security_mode
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'v'
ORDER BY security_mode DESC, c.relname;
```

---

## Section 2: Function Security (SECURITY DEFINER with search_path)

**Why it matters:** Functions marked `SECURITY DEFINER` run with the creator's privileges. This is **intentional** for helper functions like `get_current_namespace_id()` and `check_is_platform_admin()` — they need to read system tables that users can't access directly. However, they MUST set `search_path` to prevent schema hijacking attacks.

### 2.1 — List SECURITY DEFINER Functions Without search_path

```sql
-- VALIDATION: SECURITY DEFINER functions missing search_path
-- Expected: Empty result = PASS
-- Any rows = REVIEW (may need SET search_path = 'public')
SELECT p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS args,
       p.proconfig AS config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosecdef = true
  AND (p.proconfig IS NULL OR NOT EXISTS (
    SELECT 1 FROM unnest(p.proconfig) AS c WHERE c LIKE 'search_path=%'
  ))
ORDER BY p.proname;
```

**If FAIL — fix with:**
```sql
ALTER FUNCTION public.<function_name>(<args>) SET search_path = 'public';
```

### 2.2 — Inventory of All SECURITY DEFINER Functions

```sql
-- AUDIT: All SECURITY DEFINER functions with search_path status
SELECT p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS args,
       CASE 
         WHEN EXISTS (SELECT 1 FROM unnest(p.proconfig) AS c WHERE c LIKE 'search_path=%')
         THEN '✅ search_path set'
         ELSE '⚠️ no search_path'
       END AS search_path_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosecdef = true
ORDER BY search_path_status, p.proname;
```

**Known intentional SECURITY DEFINER functions:**
| Function | Purpose | search_path Required |
|----------|---------|---------------------|
| `get_current_namespace_id()` | Read user session for RLS | ✅ Yes |
| `check_is_platform_admin()` | Check platform_admins table | ✅ Yes |
| `check_is_namespace_admin_of_namespace()` | Multi-namespace admin check | ✅ Already set |
| `check_is_workspace_member()` | Workspace membership check | ✅ Yes |
| `set_current_namespace()` | Namespace switching | ✅ Yes |
| `get_user_namespaces()` | Namespace list for switcher | ✅ Yes |
| `audit_log_trigger()` | Write to audit_logs table | ✅ Yes |

---

## Section 3: Table Security (RLS + GRANTs)

**Cross-reference with:** `operations/database-change-validation.md` Sections 1.1–1.3

These queries duplicate the validation skill but are included here for a complete Security Advisor sweep.

### 3.1 — Tables Without RLS Enabled

```sql
-- VALIDATION: Public tables with RLS disabled
-- Expected: Empty result = PASS (all tables should have RLS)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
ORDER BY tablename;
```

### 3.2 — Tables With RLS Enabled But No Policies

```sql
-- VALIDATION: RLS enabled but no policies = blocks everything
-- Expected: Empty result = PASS
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p WHERE p.tablename = t.tablename
  )
ORDER BY t.tablename;
```

### 3.3 — Tables Without Authenticated GRANT

```sql
-- VALIDATION: Tables invisible to frontend
-- Expected: Empty result = PASS
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.tablename NOT IN (
    SELECT table_name FROM information_schema.role_table_grants
    WHERE grantee = 'authenticated' AND table_schema = 'public'
  )
ORDER BY t.tablename;
```

---

## Section 4: Full Security Posture Summary

Run this single query for a complete dashboard:

```sql
-- FULL POSTURE: One-shot security summary
WITH view_check AS (
  SELECT count(*) AS total_views,
         count(*) FILTER (WHERE c.reloptions::text[] @> ARRAY['security_invoker=true']) AS invoker_views
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'v'
),
func_check AS (
  SELECT count(*) AS total_definer,
         count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM unnest(p.proconfig) AS c WHERE c LIKE 'search_path=%'
         )) AS with_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prosecdef = true
),
table_check AS (
  SELECT count(*) AS total_tables,
         count(*) FILTER (WHERE rowsecurity = true) AS rls_enabled
  FROM pg_tables WHERE schemaname = 'public'
),
grant_check AS (
  SELECT count(DISTINCT table_name) AS granted_tables
  FROM information_schema.role_table_grants
  WHERE grantee = 'authenticated' AND table_schema = 'public'
)
SELECT 
  'Views' AS category,
  v.invoker_views || '/' || v.total_views || ' security_invoker' AS status,
  CASE WHEN v.invoker_views = v.total_views THEN '✅' ELSE '❌' END AS result
FROM view_check v
UNION ALL
SELECT 
  'Functions',
  f.with_search_path || '/' || f.total_definer || ' DEFINER w/ search_path',
  CASE WHEN f.with_search_path = f.total_definer THEN '✅' ELSE '⚠️' END
FROM func_check f
UNION ALL
SELECT 
  'RLS',
  t.rls_enabled || '/' || t.total_tables || ' tables with RLS',
  CASE WHEN t.rls_enabled = t.total_tables THEN '✅' ELSE '❌' END
FROM table_check t
UNION ALL
SELECT 
  'GRANTs',
  g.granted_tables || ' tables with authenticated GRANT',
  '📋 review'
FROM grant_check g;
```

---

## Incident Log

Track all Security Advisor findings and their remediation here.

### INC-001: SECURITY DEFINER Views (Feb 10, 2026)

**Source:** Supabase Security Advisor weekly email (report date: Feb 8, 2026)  
**Severity:** ERROR (32 reported — 16 unique view findings, possible duplicates or additional categories)  
**Finding:** 16 views defined with SECURITY DEFINER, bypassing RLS policies  
**Risk:** Multi-tenant data isolation gap — views could return cross-namespace data  
**Root Cause:** PostgreSQL defaults views to SECURITY DEFINER. Views were created before `security_invoker` standard was established.

**Affected Views (16):**
1. vw_application_integration_summary
2. vw_application_run_rate
3. vw_budget_alerts
4. vw_budget_status
5. vw_budget_transfer_history
6. vw_deployment_profile_costs
7. vw_integration_contacts
8. vw_integration_detail
9. vw_namespace_summary
10. vw_namespace_user_detail
11. vw_namespace_workspace_detail
12. vw_run_rate_by_vendor
13. vw_service_type_picker
14. vw_software_contract_expiry
15. vw_workspace_budget_history
16. vw_workspace_budget_summary

**Remediation Applied:**
```sql
ALTER VIEW public.<each_view> SET (security_invoker = true);
```

**Validation:** All 16 views confirmed with `security_invoker=true` after fix.  
**Impact:** None — all underlying tables have proper RLS policies with platform admin bypass on SELECT. Views now respect calling user's RLS context.  
**Prevention:** Added Section 1 checks to this document. All new views must include `security_invoker = true`.

---

## New View Checklist

When creating any new view, ensure:

| # | Requirement | How |
|---|-------------|-----|
| 1 | security_invoker = true | `CREATE VIEW ... WITH (security_invoker = true) AS ...` or `ALTER VIEW ... SET (security_invoker = true)` |
| 2 | Underlying tables have RLS | Check `identity-security/rls-policy-addendum.md` |
| 3 | Platform admin bypass on SELECT | Underlying tables must include `check_is_platform_admin()` |
| 4 | Test with non-admin user | Verify namespace isolation through the view |

**Create syntax with security_invoker:**
```sql
CREATE VIEW public.vw_example
WITH (security_invoker = true)
AS
SELECT ...
```

---

## New Function Checklist

When creating any new SECURITY DEFINER function:

| # | Requirement | How |
|---|-------------|-----|
| 1 | SET search_path = 'public' | Add to CREATE FUNCTION statement |
| 2 | Minimize privilege scope | Only access tables the function needs |
| 3 | Document in Section 2 table | Add to known DEFINER functions list |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-10 | Initial document. 4 validation sections, full posture summary query, INC-001 remediation (16 views → security_invoker). Born from Supabase Security Advisor weekly email. |

---

*Document: identity-security/security-validation-runbook.md*  
*Trigger: Supabase Security Advisor email, new view/function creation, monthly SOC2 cycle*  
*February 2026*
