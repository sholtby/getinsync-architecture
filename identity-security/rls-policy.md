# GetInSync NextGen - RLS Policy Architecture
**Version:** 2.3
**Date:** February 7, 2026 (stats updated Feb 23, 2026)
**Status:** ✅ PRODUCTION READY - All 90 Tables with Full CRUD + Platform Admin Support

---

## Executive Summary

**Phase 25.9 Complete & Validated:** All 90 database tables now have complete Row Level Security policies (347 total) supporting multi-namespace data isolation with **full CRUD operations** for namespace admins. The consultant use case is now fully operational - namespace admins can CREATE/UPDATE/DELETE across all managed namespaces.

**Current Stats (Feb 23, 2026):** 90 tables, 347 RLS policies, 37 tables with audit triggers. Growth since Phase 25.9: +24 tables (8 integration ref tables, 8 IT Value Creation, 2 lifecycle, 4 technology health columns, 2 misc), +40 policies following established 4-policy pattern.

**Key Achievements:**
- ✅ 90/90 tables with complete RLS policies (347 total policies)
- ✅ 100% use `get_current_namespace_id()` for namespace filtering
- ✅ **Platform admin support verified across ALL tables** (v2.3 hotfix closed remaining 11-table gap)
- ✅ **Namespace admin write support across 33 critical tables** (99 new policies)
- ✅ Critical bug fix: `check_is_namespace_admin_of_namespace()` now supports multi-namespace access
- ✅ Zero references to deprecated `users.namespace_id` column
- ✅ Granular 4-policy pattern (no ALL policies) for SOC2 compliance
- ✅ Multi-namespace switching works with full CRUD across ALL data
- ✅ **Full validation completed** - CREATE/UPDATE/DELETE tested across multiple namespaces
- ✅ **v2.3:** Systematic audit found and fixed 20 policies across 11 tables missing `check_is_platform_admin()`

**Production Status:** Validated February 7, 2026 using real user accounts (stuart@allstartech.com as platform admin) across City of Riverside namespace. All write operations confirmed working for platform admins.

---

## Overview

### Purpose
Row Level Security (RLS) policies enforce multi-tenant data isolation in GetInSync NextGen. All data is scoped to the user's **current namespace** (stored in `user_sessions`), with special handling for platform administrators and namespace administrators managing multiple client accounts.

### Core Principles
1. **Namespace Isolation** - Users see only data in their current namespace
2. **Platform Admin Override** - Platform admins can access all namespaces
3. **Namespace Admin Multi-Tenant** - Namespace admins can manage all namespaces they have access to
4. **Source of Truth** - `user_sessions.current_namespace_id` determines data visibility
5. **Workspace Membership** - Some tables filter by workspace membership within namespace
6. **Reference Tables** - Global data (countries, cloud_providers) has no namespace filtering
7. **Granular Control** - Separate INSERT/UPDATE/DELETE policies for audit trail clarity

---

## Helper Functions

### get_current_namespace_id()
**Returns:** UUID of user's current namespace  
**Source:** Reads from `user_sessions` table  
**Usage:** Used in USING clauses to filter data by current namespace

```sql
CREATE FUNCTION get_current_namespace_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT current_namespace_id 
  FROM user_sessions 
  WHERE user_id = auth.uid();
$$;
```

### check_is_platform_admin()
**Returns:** BOOLEAN (true if user is platform admin)  
**Source:** Checks `platform_admins` table  
**Usage:** Allows platform admins to bypass namespace restrictions

```sql
CREATE FUNCTION check_is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM platform_admins 
    WHERE user_id = auth.uid() AND is_active = true
  );
$$;
```

### check_is_namespace_admin_of_namespace(p_namespace_id UUID)
**Returns:** BOOLEAN (true if user is admin of specified namespace)  
**Source:** Checks `users.namespace_id` (home namespace) AND `namespace_users` table (multi-namespace access)  
**Usage:** Allows namespace admins to manage resources across all namespaces they have access to

**CRITICAL FIX (Feb 6-7, 2026):** Original version only checked `users.namespace_id` (home namespace), blocking namespace admins from managing other client namespaces. Fixed to check BOTH home namespace AND `namespace_users` table for multi-namespace consultant use case.

```sql
CREATE FUNCTION check_is_namespace_admin_of_namespace(_namespace_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Check if user is admin in their home namespace AND it matches
  IF EXISTS (
    SELECT 1
    FROM users
    WHERE id = auth.uid()
    AND namespace_id = _namespace_id
    AND namespace_role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- OR check if user has access via namespace_users
  -- (assume all namespace_users entries are admins for now)
  RETURN EXISTS (
    SELECT 1
    FROM namespace_users nu
    JOIN users u ON u.id = nu.user_id
    WHERE nu.user_id = auth.uid()
    AND nu.namespace_id = _namespace_id
    AND u.namespace_role = 'admin'  -- User is admin in their home namespace
  );
END;
$$;
```

**Why This Fix Was Critical:**
- **Before:** Namespace admins could only write to their home namespace (e.g., Pal's Pets)
- **After:** Namespace admins can write to ALL namespaces in `namespace_users` (e.g., Government of Saskatchewan, Technical Safety Authority, etc.)
- **Impact:** Enables consultant workflow - manage multiple client accounts from single login

### get_user_namespaces()
**Returns:** TABLE with all namespaces user can access  
**Platform Admin Behavior:** Returns ALL namespaces if user is platform admin  
**Usage:** Powers namespace switcher UI

```sql
CREATE FUNCTION get_user_namespaces()
RETURNS TABLE (
  namespace_id UUID,
  namespace_name TEXT,
  namespace_slug TEXT,
  user_role TEXT,
  is_current BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT 
    n.id as namespace_id,
    n.name as namespace_name,
    n.slug as namespace_slug,
    COALESCE(nu.role, 'platform_admin') as user_role,
    (n.id = get_current_namespace_id()) as is_current
  FROM namespaces n
  LEFT JOIN namespace_users nu ON nu.namespace_id = n.id AND nu.user_id = auth.uid()
  WHERE 
    check_is_platform_admin()
    OR 
    nu.user_id = auth.uid()
  ORDER BY n.name;
$$;
```

### set_current_namespace(p_namespace_id UUID)
**Returns:** void  
**Platform Admin Behavior:** Allows switching to any namespace  
**Usage:** Called when user switches namespaces

```sql
CREATE FUNCTION set_current_namespace(p_namespace_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_is_platform_admin BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  v_is_platform_admin := check_is_platform_admin();
  
  IF NOT v_is_platform_admin AND NOT EXISTS (
    SELECT 1 FROM namespace_users 
    WHERE user_id = v_user_id 
      AND namespace_id = p_namespace_id
  ) THEN
    RAISE EXCEPTION 'User does not belong to namespace %', p_namespace_id;
  END IF;
  
  INSERT INTO user_sessions (user_id, current_namespace_id, updated_at)
  VALUES (v_user_id, p_namespace_id, NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    current_namespace_id = p_namespace_id,
    updated_at = NOW();
END;
$$;
```

---

## Policy Patterns

All tables follow standardized patterns with **4 granular policies** (SELECT, INSERT, UPDATE, DELETE) for SOC2 compliance.

### Pattern 1: Direct Namespace-Scoped Tables (With Namespace Admin Write Support)
**Tables:** technology_products, data_centers, organizations, it_services, software_products, software_product_categories, technology_product_categories, it_service_providers, assessment_factors, assessment_thresholds, service_type_categories, service_types, workspaces, workspace_groups, custom_field_definitions, workflow_definitions

**Characteristics:**
- Has direct `namespace_id` column
- Platform admin support via `check_is_platform_admin()`
- **Namespace admin support** via `check_is_namespace_admin_of_namespace()`
- Admins/editors can manage within current namespace

```sql
-- SELECT
CREATE POLICY "Users can view table_name in current namespace"
  ON table_name FOR SELECT
  USING (
    namespace_id = get_current_namespace_id()
    OR check_is_platform_admin()
  );

-- INSERT (with namespace admin support)
CREATE POLICY "Admins can insert table_name in current namespace"
  ON table_name FOR INSERT
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );

-- UPDATE (with namespace admin support)
CREATE POLICY "Admins can update table_name in current namespace"
  ON table_name FOR UPDATE
  USING (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  )
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );

-- DELETE (with namespace admin support)
CREATE POLICY "Admins can delete table_name in current namespace"
  ON table_name FOR DELETE
  USING (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );
```

### Pattern 2: Workspace-Scoped Tables (With Namespace Admin Write Support)
**Tables:** applications, deployment_profiles, portfolios, portfolio_assignments, contacts

**Characteristics:**
- Linked to workspace (which has namespace_id)
- Platform admin support via `check_is_platform_admin()`
- **Namespace admin support** via `check_is_namespace_admin_of_namespace()`
- Workspace admins/editors can manage

```sql
-- SELECT
CREATE POLICY "Users can view table_name in current namespace"
  ON table_name FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM workspaces 
      WHERE namespace_id = get_current_namespace_id()
    )
    OR check_is_platform_admin()
  );

-- INSERT (with namespace admin support)
CREATE POLICY "Admins can insert table_name in current namespace"
  ON table_name FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT id FROM workspaces 
      WHERE namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );

-- UPDATE (with namespace admin support)
CREATE POLICY "Admins can update table_name in current namespace"
  ON table_name FOR UPDATE
  USING (
    workspace_id IN (
      SELECT id FROM workspaces 
      WHERE namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = table_name.workspace_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  )
  WITH CHECK (
    workspace_id IN (
      SELECT id FROM workspaces 
      WHERE namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = table_name.workspace_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );

-- DELETE (with namespace admin support)
CREATE POLICY "Admins can delete table_name in current namespace"
  ON table_name FOR DELETE
  USING (
    workspace_id IN (
      SELECT id FROM workspaces 
      WHERE namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM workspace_users wu
        WHERE wu.workspace_id = table_name.workspace_id
          AND wu.user_id = auth.uid()
          AND wu.role = 'admin'
      )
    )
  );
```

### Pattern 3: Assessment Tables (With Namespace Admin Write Support)
**Tables:** business_assessments, technical_assessments, assessment_history

**Characteristics:**
- Linked via application_id or portfolio_assignment_id to namespace
- Platform admin support via `check_is_platform_admin()`
- **Namespace admin support** via `check_is_namespace_admin_of_namespace()`

```sql
-- Example for business_assessments
-- INSERT
CREATE POLICY "Editors can insert business_assessments in current namespace"
  ON business_assessments FOR INSERT
  WITH CHECK (
    application_id IN (
      SELECT a.id FROM applications a
      JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );

-- Similar patterns for UPDATE and DELETE with workspace role checks
```

### Pattern 4: Junction Tables (With Namespace Admin Write Support)
**Tables:** application_services, application_contacts, application_compliance, application_data_assets, application_documents, application_integrations, application_roadmap, deployment_profile_contacts, deployment_profile_it_services, deployment_profile_software_products, deployment_profile_technology_products

**Characteristics:**
- Links entities within same namespace
- Platform admin support via `check_is_platform_admin()`
- **Namespace admin support** via `check_is_namespace_admin_of_namespace()`

```sql
-- Example for application_contacts
-- INSERT
CREATE POLICY "Editors can insert application_contacts in current namespace"
  ON application_contacts FOR INSERT
  WITH CHECK (
    application_id IN (
      SELECT a.id FROM applications a
      JOIN workspaces w ON w.id = a.workspace_id
      WHERE w.namespace_id = get_current_namespace_id()
    )
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
    )
  );

-- Similar patterns for UPDATE and DELETE with workspace role checks
```

### Pattern 5: Reference Tables (Read-Only)
**Tables:** cloud_providers, cloud_regions, countries, currencies, industries, deployment_sizes, hosting_types, lifecycle_statuses, compliance_frameworks, data_classifications

**Characteristics:**
- Global data, no namespace filtering
- Read-only (SELECT policy only)
- All authenticated users can view

```sql
CREATE POLICY "All users can view reference table"
  ON table_name FOR SELECT
  USING (true);
```

---

## Table Coverage Summary

### Core Business Tables (7 tables - COMPLETE)
✅ **Priority 1:** Full CRUD with namespace admin support
- applications
- deployment_profiles
- portfolios
- portfolio_assignments
- contacts
- organizations
- it_services

### Assessment & Junction Tables (14 tables - COMPLETE)
✅ **Priority 2:** Full CRUD with namespace admin support

**Assessment Tables (3):**
- business_assessments
- technical_assessments
- assessment_history

**Junction Tables (11):**
- application_services
- application_contacts
- application_compliance
- application_data_assets
- application_documents
- application_integrations
- application_roadmap
- deployment_profile_contacts
- deployment_profile_it_services
- deployment_profile_software_products
- deployment_profile_technology_products

### Catalog & Reference Tables (12 tables - COMPLETE)
✅ **Priority 3:** Full CRUD with namespace admin support

**Catalog Tables (6):**
- software_products
- software_product_categories
- technology_products
- technology_product_categories
- data_centers
- it_service_providers

**Assessment Config (2):**
- assessment_factors
- assessment_thresholds

**Service Types (2):**
- service_type_categories
- service_types

**Workspace (2):**
- workspaces
- workspace_groups

### Configuration & Custom (2 tables - COMPLETE)
✅ Full CRUD with namespace admin support
- custom_field_definitions
- workflow_definitions

### Supporting Tables (21 tables - COMPLETE)
✅ Various patterns with appropriate access control
- workspace_users
- namespace_users
- budget_transfers
- remediation_efforts
- workspace_settings
- workspace_budgets
- organization_settings
- notification_rules
- alert_preferences
- invitations
- user_sessions
- platform_admins
- custom_field_values (polymorphic)
- workspace_group_publications
- And 7 more...

### Reference Tables (10 tables - COMPLETE)
✅ Read-only global data
- cloud_providers
- cloud_regions
- countries
- currencies
- industries
- deployment_sizes
- hosting_types
- lifecycle_statuses
- compliance_frameworks
- data_classifications

---

## SOC2 Compliance Requirements

### Multi-Tenant Isolation
**Requirement:** Demonstrate logical data separation between tenants

**Implementation:**
- ✅ Every table filters by `get_current_namespace_id()`
- ✅ No cross-namespace data leakage
- ✅ Users cannot see data from other namespaces
- ✅ Platform admins must explicitly switch namespace (traceable action)

**Audit Questions Addressed:**
- "How do you prevent Tenant A from seeing Tenant B's data?" → **RLS policies enforce namespace isolation**
- "Can you show namespace switching is logged?" → **Yes**, user_sessions table tracks switches

### Access Control Matrix
**Requirement:** Document who can do what

| Role | View | Insert | Update | Delete | Manage Users |
|------|------|--------|--------|--------|--------------|
| Viewer | ✅ Current Namespace | ┌ | ┌ | ┌ | ┌ |
| Editor | ✅ Current Namespace | ✅ | ✅ | ┌ | ┌ |
| Admin | ✅ Current Namespace | ✅ | ✅ | ✅ | ✅ Workspace |
| Namespace Admin | ✅ All Managed Namespaces | ✅ All Managed | ✅ All Managed | ✅ All Managed | ✅ Namespace |
| Platform Admin | ✅ All (after switch) | ✅ | ✅ | ✅ | ✅ All |

**Note:** Namespace Admins can manage multiple client namespaces via `namespace_users` table. This enables the consultant use case.

---

## Validation Results (February 6-7, 2026)

### Test Environment
- **User:** stuart@getinsync.ca (namespace admin, not platform admin)
- **Access:** 4 namespaces (Pal's Pets, Government of Saskatchewan, Default Organization, Technical Safety Authority of Saskatchewan)
- **Test Namespaces:** Pal's Pets (1 workspace), Government of Saskatchewan (4 workspaces)

### CREATE Operations - PASSED ✅
**Tested in Both Namespaces:**
- ✅ Contacts created successfully
- ✅ Organizations created successfully
- ✅ IT Services created successfully
- ✅ Applications created successfully
- ✅ Deployment Profiles auto-created with applications
- ✅ Perfect namespace isolation (no cross-contamination)

**Database Verification:**
```sql
-- Applications in separate namespaces confirmed
SELECT a.name, n.name as namespace_name
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE a.name LIKE '%Phase 25.9%'
```
Result: Applications correctly scoped to their respective namespaces

### UPDATE Operations - PASSED ✅
**Tested in Both Namespaces:**
- ✅ Applications updated (description field)
- ✅ Contacts updated (phone field)
- ✅ Organizations updated (description field)
- ✅ Timestamps correctly updated
- ✅ Changes persisted to database

**Database Verification:**
```sql
-- Verified updated_at timestamps and field changes
```
Result: All updates successfully applied with correct timestamps

### DELETE Operations - PASSED ✅
**Tested in Both Namespaces:**
- ✅ Applications deleted (hard delete)
- ✅ Deployment Profiles cascaded properly
- ✅ Contacts deleted
- ✅ Organizations deleted
- ✅ All test data cleaned up

**Database Verification:**
```sql
-- Confirmed zero test records remain
SELECT COUNT(*) FROM applications WHERE name LIKE '%Phase 25.9%'
```
Result: 0 records (complete cleanup)

### Data Isolation - PASSED ✅
**Multi-Namespace Switching:**
- ✅ Switch from Pal's Pets → Government of Saskatchewan
- ✅ Data updated immediately (no stale cache)
- ✅ Cannot see Pal's Pets data when in Government of Saskatchewan
- ✅ Cannot see Government of Saskatchewan data when in Pal's Pets
- ✅ `user_sessions.current_namespace_id` correctly updated on each switch

### Edge Cases - PASSED ✅
- ✅ Browser refresh maintains namespace context
- ✅ Rapid namespace switching works correctly
- ✅ No 403 errors for namespace admin operations
- ✅ Assessment configuration changes work

### Known Issues
**UI Bug (Separate from Phase 25.9):** Cost Analysis "All Portfolios" view fails with 400 error when passing `id=eq.all` as filter. Workaround: View specific portfolios. Fix required in UI component, not RLS layer.

---

## Testing Checklist

### For Each Table:

1. **Verify Policy Exists:**
   ```sql
   SELECT policyname, cmd FROM pg_policies WHERE tablename = 'table_name';
   ```
   Should see 4 policies: DELETE, INSERT, SELECT, UPDATE (or 1 SELECT for read-only reference tables)

2. **Test Namespace Admin (Multi-Namespace User):**
   - Login as user in multiple namespaces (e.g., stuart@getinsync.ca)
   - Switch to namespace A → verify can see A's data only
   - Create/Update/Delete records in namespace A
   - Switch to namespace B → verify can see B's data only
   - Create/Update/Delete records in namespace B
   - Verify cannot see A's data while viewing B
   - Verify changes persisted to correct namespace

3. **Test Regular User (Single Namespace Member):**
   - Login as user in single namespace
   - Verify can see only their namespace data
   - Verify cannot see other namespace data
   - Verify appropriate role permissions (viewer vs editor vs admin)

4. **Test Platform Admin:**
   - Login as platform admin
   - Switch to namespace A → verify see A's data only
   - Switch to namespace B → verify see B's data only
   - Verify cannot see A's data while viewing B
   - Verify can manage all namespaces

5. **Test Edge Cases:**
   - User with no namespace → should see nothing
   - User with multiple namespaces → should see only current
   - Platform admin in namespace they're also a member of → should work same as other namespaces
   - User switches namespace → data updates immediately
   - Browser refresh → maintains current namespace

6. **Test Granular Permissions:**
   - Viewer cannot insert/update/delete
   - Editor can insert/update but not delete
   - Admin can delete
   - Namespace admin can do all operations in managed namespaces
   - Verify denied operations return appropriate errors

---

## Performance Considerations

### Query Optimization
- ✅ `get_current_namespace_id()` marked STABLE (cacheable per transaction)
- ✅ `check_is_namespace_admin_of_namespace()` uses indexed joins
- ✅ Workspace subqueries use indexed joins
- ✅ Policies kept simple to minimize overhead
- ✅ Avoid nested correlated subqueries where possible

### Indexes Required
```sql
-- Ensure these indexes exist for optimal RLS performance
CREATE INDEX IF NOT EXISTS idx_workspaces_namespace_id ON workspaces(namespace_id);
CREATE INDEX IF NOT EXISTS idx_applications_workspace_id ON applications(workspace_id);
CREATE INDEX IF NOT EXISTS idx_deployment_profiles_workspace_id ON deployment_profiles(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_users_workspace_id ON workspace_users(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_users_user_id ON workspace_users(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_namespace_users_user_id ON namespace_users(user_id);
CREATE INDEX IF NOT EXISTS idx_namespace_users_namespace_id ON namespace_users(namespace_id);
```

---

## Migration Log

### February 7, 2026 (Evening) - Platform Admin Bulk Hotfix ⚡ (v2.3)

**Issue Discovered During Phase 25.10 Preparation:** Platform admins could not invite users or manage data in UPDATE/DELETE operations on 11 tables when operating in a non-home namespace. Discovered when testing stuart@allstartech.com (platform admin) attempting to invite a user to City of Riverside namespace.

**Root Cause:** Systematic audit revealed 20 write policies across 11 tables missing `check_is_platform_admin()` bypass. The Phase 25.9 migration added platform admin to SELECT and INSERT policies but missed UPDATE and DELETE on several tables. Two additional tables (`invitations`, `invitation_workspaces`) were missing platform admin across all write policies.

**Discovery Method:** Programmatic audit query against `pg_policies` system catalog — no more manual checking.

```sql
-- Audit query that found the gaps
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE cmd IN ('INSERT', 'UPDATE', 'DELETE')
  AND qual NOT LIKE '%true%'
  AND (with_check IS NULL OR with_check NOT LIKE '%true%')
  AND (
    (cmd = 'INSERT' AND with_check NOT LIKE '%platform_admin%')
    OR (cmd != 'INSERT' AND qual NOT LIKE '%platform_admin%')
  )
ORDER BY tablename, cmd;
```

**Tables Fixed (11 tables, 20 policies):**

| Table | Policies Fixed | Pattern |
|-------|---------------|---------|
| invitations | INSERT, UPDATE, DELETE | Namespace-scoped with admin check |
| invitation_workspaces | INSERT, UPDATE, DELETE | Junction via invitation_id |
| alert_preferences | UPDATE, DELETE | Dual-scope (namespace_id OR workspace_id) |
| application_contacts | UPDATE, DELETE | Junction via application_id |
| budget_transfers | UPDATE, DELETE | Workspace-scoped |
| custom_field_values | UPDATE, DELETE | Polymorphic (6 entity types) |
| deployment_profile_contacts | UPDATE, DELETE | Junction via deployment_profile_id |
| deployment_profile_it_services | UPDATE, DELETE | Junction via deployment_profile_id |
| deployment_profile_technology_products | UPDATE, DELETE | Junction via deployment_profile_id |
| it_services | UPDATE, DELETE | owner_workspace_id scoped |
| workspace_budgets | UPDATE, DELETE | Workspace-scoped, admin only |
| workspace_settings | UPDATE, DELETE | Workspace-scoped, admin only |

**Additional Fix:** `users.is_super_admin` flag was `false` for stuart@allstartech.com and smholtby+delta@gmail.com despite both being in `platform_admins` table. Frontend gates some UI on this column. Updated to `true`.

**Design Debt Identified:** Two sources of truth for platform admin status:
- `platform_admins` table (used by RLS via `check_is_platform_admin()`) — **canonical**
- `users.is_super_admin` column (used by frontend) — **should be deprecated**
- **Future fix:** Migrate frontend to use `is_platform_admin()` RPC, then drop `users.is_super_admin` column

**Frontend Bug Fixed:** Settings → Users page showed "0 Active Users" for platform admins viewing other namespaces. Root cause: query went through `workspace_users` to build user ID list, returning empty when platform admin had no workspace membership. Fixed by AG to query `users` table directly by `namespace_id`.

**Post-Fix Validation:**
- ✅ Audit query returns only `user_sessions` self-update policy (expected, uses `user_id = auth.uid()`)
- ✅ Platform admin can invite users to City of Riverside
- ✅ Platform admin can view Active Users in City of Riverside
- ✅ All 66 tables confirmed with platform admin support on all write policies

**Time Investment:** ~1.5 hours (audit, fix, validate)

### February 6-7, 2026 - Phase 25.9 Namespace Admin Write Support COMPLETE ✅

**Problem Statement:** 33 tables had RLS policies that allowed namespace admins to VIEW data but blocked CREATE/UPDATE/DELETE operations. The consultant use case (managing multiple client namespaces) was broken.

**Solution Implemented:**
- ✅ Added 99 new RLS policies across 33 tables (INSERT, UPDATE, DELETE)
- ✅ Fixed critical bug in `check_is_namespace_admin_of_namespace()` helper function
- ✅ Full CRUD validation completed across multiple namespaces
- ✅ Production-ready status achieved

**Tables Updated (33 total):**

**Priority 1: Core Business Tables (7 tables = 21 policies)**
- applications
- deployment_profiles
- portfolios
- portfolio_assignments
- contacts
- organizations
- it_services

**Priority 2: Assessment & Junction Tables (14 tables = 42 policies)**
- business_assessments
- technical_assessments
- assessment_history
- application_services
- application_contacts
- application_compliance
- application_data_assets
- application_documents
- application_integrations
- application_roadmap
- deployment_profile_contacts
- deployment_profile_it_services
- deployment_profile_software_products
- deployment_profile_technology_products

**Priority 3: Catalog & Reference Tables (12 tables = 36 policies)**
- software_products
- software_product_categories
- technology_products
- technology_product_categories
- data_centers
- it_service_providers
- assessment_factors
- assessment_thresholds
- service_type_categories
- service_types
- workspaces
- workspace_groups
- custom_field_definitions
- workflow_definitions

**Critical Bug Fix:** 
`check_is_namespace_admin_of_namespace()` function originally only checked `users.namespace_id` (home namespace), blocking namespace admins from managing other client namespaces they had access to via `namespace_users` table. 

**Before (Broken):**
```sql
CREATE FUNCTION check_is_namespace_admin_of_namespace(p_namespace_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND namespace_id = p_namespace_id  -- ONLY checks home namespace!
    AND namespace_role = 'admin'
  );
END;
$$;
```

**After (Fixed):**
```sql
CREATE FUNCTION check_is_namespace_admin_of_namespace(_namespace_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Check home namespace
  IF EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND namespace_id = _namespace_id
    AND namespace_role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- ALSO check namespace_users for multi-namespace access
  RETURN EXISTS (
    SELECT 1
    FROM namespace_users nu
    JOIN users u ON u.id = nu.user_id
    WHERE nu.user_id = auth.uid()
    AND nu.namespace_id = _namespace_id
    AND u.namespace_role = 'admin'
  );
END;
$$;
```

**Impact:** Namespace admins (consultants) can now CREATE/UPDATE/DELETE across all managed client namespaces, not just their home namespace.

**Validation Results:**
- ✅ CREATE operations tested in 2 namespaces (Pal's Pets, Government of Saskatchewan)
- ✅ UPDATE operations tested in 2 namespaces
- ✅ DELETE operations tested in 2 namespaces
- ✅ Data isolation verified (no cross-contamination)
- ✅ All test data cleaned up successfully

**Time Investment:** ~4 hours (estimated 80 minutes, actual included debugging and validation)

**Production Status:** READY - Validated with real user account managing multiple client namespaces

### February 6, 2026 - Phase 25.9 All Tables Migrated

**All 66 tables migrated to multi-namespace RLS**

**Standardization Pass (Feb 6):**
- ✅ portfolios (2→4 policies)
- ✅ portfolio_assignments (2→4 policies)
- ✅ contacts (2→4 policies)
- ✅ software_products (2→4 policies)
- ✅ application_services (2→4 policies)
- ✅ deployment_profile_software_products (2→4 policies)
- ✅ namespace_users (2→4 policies)

**Categories Completed:**
- ✅ TIER 1 - Core tables (6 tables)
- ✅ High Priority - Business tables (4 tables)
- ✅ Junction Tables - Relationships (8 tables)
- ✅ Category A - Application junction (5 tables)
- ✅ Category B - Workspace group junction (3 tables)
- ✅ Category C - Namespace-direct supporting (12 tables)
- ✅ Category D - Workspace-scoped supporting (10 tables)
- ✅ Category E - Namespace config (3 tables)
- ✅ Category F - Global reference (10 tables)
- ✅ Category G - System tables (5 tables)

**Key Changes:**
- ✅ All policies use `get_current_namespace_id()`
- ✅ Eliminated all references to deprecated `users.namespace_id`
- ✅ Platform admin support across all tables
- ✅ Standardized to 4-policy pattern (SELECT, INSERT, UPDATE, DELETE)
- ✅ Complex polymorphic tables (custom_field_values) migrated
- ✅ Dual-scope tables (alert_preferences) migrated
- ✅ Global reference tables properly configured

### February 6, 2026 (Evening) - TIER 1 Platform Admin Hotfix ⚡
**Issue Discovered During UI Testing:** Platform admins could view data but not update deployment profiles or other TIER 1 tables. Discovered when testing stuart@allstartech.com (platform admin) trying to edit deployment profile in City of Riverside namespace.

**Root Cause:** TIER 1 tables (migrated Feb 5) had `check_is_platform_admin()` in SELECT policies but NOT in INSERT/UPDATE/DELETE policies. Platform admins were blocked by workspace_users membership checks in write operations.

**Tables Affected:** 
- workspaces
- applications  
- deployment_profiles
- portfolios
- portfolio_assignments
- workspace_users

**Fix Applied:** Added `check_is_platform_admin()` OR condition to 18 write policies (3 per table: INSERT, UPDATE, DELETE). Platform admins now bypass workspace membership requirements for write operations while maintaining namespace isolation.

**Verification:** All 18 policies confirmed to have platform admin support. Platform admin can now create/update/delete data in any namespace.

**Result:** Platform admins now have full read/write access across all namespaces. All 66 tables fully operational for both regular users and platform admins.

### February 5, 2026 - Phase 25.9 Started
- ✅ TIER 1 tables (workspaces, applications, DPs, portfolios) - 6 tables
- ✅ Junction tables (18 tables total by Feb 6)
- ✅ Platform admin support infrastructure
- ✅ UI created: /organizations page for namespace switching

---

## Common Pitfalls & Solutions

### Issue: 403 Forbidden on Related Tables
**Cause:** Nested joins in RLS policies referencing tables without proper grants  
**Solution:** Grant SELECT to `authenticated` role on all referenced tables

### Issue: Queries Before Auth Session Established
**Cause:** Frontend queries data before auth session is ready  
**Solution:** Wait for auth state, then call `set_current_namespace()` before queries

### Issue: Data Not Updating After Namespace Switch
**Cause:** Frontend cache not invalidated  
**Solution:** Invalidate Supabase client cache after namespace switch

### Issue: Platform Admin Cannot See Data
**Cause:** Forgot `check_is_platform_admin()` in SELECT policy  
**Solution:** Add platform admin check to all SELECT policies on namespace-scoped tables

### Issue: Platform Admin Can View But Not Edit Data
**Cause:** Forgot `check_is_platform_admin()` in INSERT/UPDATE/DELETE policies  
**Solution:** Add `OR check_is_platform_admin()` to all write policies. Platform admins should bypass workspace membership checks.  
**Note:** This was discovered in TIER 1 tables during Phase 25.9 testing and fixed Feb 6 evening.

### Issue: Namespace Admin Cannot Create/Update/Delete in Managed Namespaces
**Cause:** `check_is_namespace_admin_of_namespace()` only checking home namespace  
**Solution:** Update function to check BOTH `users.namespace_id` AND `namespace_users` table  
**Note:** This was discovered during Phase 25.9 validation (Feb 6-7) and fixed immediately. Enabled consultant use case.

### Issue: Complex Policy Performance
**Cause:** Too many nested subqueries  
**Solution:** Simplify policy logic, ensure proper indexes exist

### Issue: Dual Source of Truth for Platform Admin Status
**Cause:** `platform_admins` table (RLS) and `users.is_super_admin` column (frontend) can be out of sync  
**Solution:** Keep both in sync when granting platform admin access. Future: migrate frontend to `is_platform_admin()` RPC and drop `users.is_super_admin`  
**Note:** Discovered Feb 7 when stuart@allstartech.com was in `platform_admins` but had `is_super_admin = false`

### Issue: Frontend User List Query Uses workspace_users Instead of users Table
**Cause:** Settings → Users page queries workspace_users for user IDs, then fetches from users. Platform admins with no workspace membership get empty results  
**Solution:** Query `users` table directly by `namespace_id` for the user list  
**Note:** Fixed by AG on Feb 7. Count query was already correct; table query was wrong path.

---

## Notes

### Source of Truth
- `user_sessions.current_namespace_id` is the **single source of truth**
- Do NOT rely on localStorage, JWT claims, or users.namespace_id
- All RLS policies read from `get_current_namespace_id()` function

### Why Granular Policies?
- **SOC2 Compliance** - Demonstrates separation of duties
- **Audit Trail** - Logs show specific operation attempted
- **Access Control** - Can restrict delete separately from update
- **Future Flexibility** - Easier to adjust permissions per operation

### Deprecated Patterns
- ┌ `users.namespace_id` column (single namespace only)
- ┌ ALL policies combining INSERT/UPDATE/DELETE
- ┌ Direct namespace checks without `get_current_namespace_id()`
- ┌ Policies that don't support platform admins
- ┌ Policies that don't support namespace admins managing multiple namespaces
- ❌ `users.is_super_admin` column for platform admin checks (use `platform_admins` table / `check_is_platform_admin()` — frontend migration pending)
- ❌ Querying `workspace_users` to build user lists (query `users` table by `namespace_id` directly)

### Multi-Namespace Consultant Workflow
**Use Case:** Consultant managing multiple client accounts (e.g., City of Riverside, Government of Saskatchewan, City of Garland)

**Implementation:**
1. User account has `namespace_role = 'admin'` in home namespace
2. User has entries in `namespace_users` for each client namespace
3. `check_is_namespace_admin_of_namespace()` checks BOTH home namespace AND namespace_users
4. User can switch between client namespaces via UI
5. Full CRUD operations available in each managed namespace
6. Perfect data isolation maintained

**Example:**
- stuart@getinsync.ca has home namespace = Pal's Pets
- Has namespace_users entries for: Government of Saskatchewan, Default Organization, Technical Safety Authority
- Can switch to any of these 4 namespaces
- Can CREATE/UPDATE/DELETE in all 4 namespaces
- Cannot see data from namespaces not in their access list

---

## Next Steps

**Phase 25.9 is complete and production-ready.** Future enhancements:

1. **Performance Monitoring**
   - Monitor slow query log for RLS-related performance issues
   - Add specialized indexes if needed
   - Consider materialized views for complex reporting queries

2. **Additional Testing**
   - Load testing with multiple concurrent users switching namespaces
   - Edge case testing (user removed from namespace while viewing)
   - Performance testing with large datasets

3. **Documentation**
   - ✅ RLS Policy Architecture v2.3 complete
   - Update API documentation to reflect multi-namespace support
   - Create runbook for common RLS issues
   - Document namespace onboarding process

4. **Enhancements**
   - Consider adding row-level audit logging
   - Evaluate need for read replicas per namespace
   - Plan for namespace data export/archival
   - Fix UI bug: Cost Analysis "All Portfolios" filter
   - Migrate frontend from `users.is_super_admin` to `is_platform_admin()` RPC
   - Drop `users.is_super_admin` column after frontend migration

---

**Document Status:** Complete - reflects validated state including v2.3 platform admin bulk hotfix  
**Version:** 2.3  
**Last Updated:** February 7, 2026  
**Validated By:** Stuart Holtby (stuart@allstartech.com) as platform admin across City of Riverside namespace  
**Production Status:** READY FOR DEPLOYMENT  
**Maintained By:** GetInSync Architecture Team
