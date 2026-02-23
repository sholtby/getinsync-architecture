# GetInSync NextGen - RLS Policy Architecture v2.4 Changelog Addendum

**Version:** 2.4  
**Date:** February 8, 2026  
**Status:** ✅ PRODUCTION — 68 Tables, ~286 RLS Policies

---

## What Changed from v2.3 → v2.4

### Summary

During Integration Management deployment (Feb 8, 2026), three RLS issues were discovered on the pre-existing `application_integrations` table, plus two new tables were added with full RLS from Day 1.

**Table Count:** 66 → 68 (+integration_contacts, +data_tag_types)  
**Policy Count:** ~360 → ~370 (approximate — 4 new on integration_contacts, 2 on data_tag_types, 2 replaced on application_integrations)

---

### February 8, 2026 — Integration Management RLS Fixes & New Tables

#### Bug 1: Missing GRANT on application_integrations ⚠️

**Symptom:** 403 Forbidden on INSERT — `permission denied for table application_integrations`  
**Root Cause:** The `application_integrations` table (created in an earlier phase) never had `GRANT ALL ... TO authenticated` applied. RLS policies existed but the role couldn't access the table at all.  
**Fix:**
```sql
GRANT ALL ON TABLE public.application_integrations TO authenticated;
GRANT ALL ON TABLE public.application_integrations TO service_role;
```
**Lesson:** Always verify GRANTs exist, not just RLS policies. A table can have perfect policies and still 403 if the role doesn't have base access.

#### Bug 2: INSERT policy missing workspace editor/admin path

**Symptom:** Workspace editors and admins could not create integrations — only platform admins and namespace admins could.  
**Root Cause:** The INSERT policy's WITH CHECK only included `check_is_platform_admin()` and `check_is_namespace_admin_of_namespace()`. Unlike the UPDATE policy (which had the workspace_users EXISTS check), INSERT had no workspace-level role check.  
**Fix:** Replaced INSERT policy to include workspace admin/editor check matching UPDATE policy pattern:
```sql
DROP POLICY "Editors can insert application_integrations in current namespac" ON application_integrations;

CREATE POLICY "Editors can insert application_integrations in current namespace"
  ON application_integrations FOR INSERT
  WITH CHECK (
    source_application_id IN (
      SELECT a.id FROM applications a
      JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM applications a
        JOIN workspace_users wu ON wu.workspace_id = a.workspace_id
        WHERE a.id = application_integrations.source_application_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );
```

#### Bug 3: SELECT policy blocking external integrations (NULL target)

**Symptom:** External integrations (where `target_application_id IS NULL`) would never be visible because the SELECT policy required BOTH `source_application_id` AND `target_application_id` to match namespace subqueries. NULL never matches an IN subquery.  
**Root Cause:** Original SELECT policy used AND between source and target checks without handling NULL targets.  
**Fix:** Replaced SELECT policy to handle NULL target_application_id:
```sql
DROP POLICY "Users can view application_integrations in current namespace" ON application_integrations;

CREATE POLICY "Users can view application_integrations in current namespace"
  ON application_integrations FOR SELECT
  USING (
    (
      source_application_id IN (
        SELECT a.id FROM applications a
        JOIN workspaces w ON w.id = a.workspace_id
        WHERE w.namespace_id = get_current_namespace_id()
      )
      AND (
        target_application_id IS NULL
        OR target_application_id IN (
          SELECT a.id FROM applications a
          JOIN workspaces w ON w.id = a.workspace_id
          WHERE w.namespace_id = get_current_namespace_id()
        )
      )
    )
    OR check_is_platform_admin()
  );
```
**Also added:** Platform admin bypass was missing from the original SELECT policy.

---

#### New Table: integration_contacts (4 policies)

**Pattern:** Junction table via integration_id → application_integrations → applications → workspaces → namespace  
**Policies:**

| Policy | Cmd | Logic |
|--------|-----|-------|
| Users can view integration_contacts in current namespace | SELECT | Via integration chain + platform admin bypass |
| Editors can insert integration_contacts in current namespace | INSERT | Via integration chain + platform/namespace admin |
| Editors can update integration_contacts in current namespace | UPDATE | Via integration chain + platform/namespace admin |
| Admins can delete integration_contacts in current namespace | DELETE | Via integration chain + platform/namespace admin |

**GRANTs:** ✅ Applied at creation

---

#### New Table: data_tag_types (2 policies)

**Pattern:** Global reference table with platform admin management  
**Policies:**

| Policy | Cmd | Logic |
|--------|-----|-------|
| Anyone can view data_tag_types | SELECT | USING (true) — all authenticated users |
| Platform admins can manage data_tag_types | ALL | check_is_platform_admin() |

**GRANTs:** ✅ SELECT to authenticated, ALL to service_role

---

### New Common Pitfall Added

#### Issue: NULL Foreign Keys Blocked by RLS
**Cause:** SELECT policy requires related entity (e.g., `target_application_id`) to match namespace, but nullable FK means NULL never matches IN subquery.  
**Solution:** Add `IS NULL OR` check before the IN subquery for any nullable FK used in RLS filtering.  
**Example:** `target_application_id IS NULL OR target_application_id IN (SELECT ...)`  
**Note:** Discovered on application_integrations.target_application_id — external integrations have NULL target.

#### Issue: Missing GRANTs on Pre-existing Tables
**Cause:** Table created before GRANT standards were established. RLS policies exist but role has no base table access.  
**Solution:** Always verify `GRANT ALL ON TABLE ... TO authenticated` exists. Check with:
```sql
SELECT grantee, privilege_type 
FROM information_schema.table_privileges 
WHERE table_name = 'table_name'
AND grantee IN ('authenticated', 'service_role');
```
**Note:** Discovered on application_integrations — no rows returned from grants query.

---

### Updated Table Count

| Category | v2.3 | v2.4 | Change |
|----------|------|------|--------|
| Core Business | 7 | 7 | — |
| Assessment & Junction | 14 | 15 | +integration_contacts |
| Catalog & Reference | 12 | 13 | +data_tag_types |
| User & Session | 10 | 10 | — |
| System & Config | 8 | 8 | — |
| Global Reference | 10 | 10 | — |
| Workspace Groups | 5 | 5 | — |
| **Total** | **66** | **68** | **+2** |

---

### Validation

**Verified Feb 8, 2026:**
- ✅ Workspace editor can INSERT application_integrations (was 403, now works)
- ✅ External integrations visible in SELECT (was hidden due to NULL target)
- ✅ Platform admin bypass on SELECT (was missing)
- ✅ integration_contacts full CRUD via RLS
- ✅ data_tag_types readable by all, manageable by platform admin
- ✅ Test data: 2 integrations + 2 contacts in Gov of Alberta (Test) namespace validated through views

---

**Document Status:** Addendum to identity-security/rls-policy.md  
**Action:** Merge this changelog into v2_3 and rename to v2_4, or maintain as separate addendum  
**Version:** 2.4  
**Last Updated:** February 8, 2026  
**Validated By:** Stuart Holtby  
**Maintained By:** GetInSync Architecture Team
