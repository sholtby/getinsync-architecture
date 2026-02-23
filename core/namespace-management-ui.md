# Work Package: Namespace Management UI (Phase 25.10)

**Version:** 1.0  
**Date:** February 7, 2026  
**Phase:** 25.10  
**Priority:** CRITICAL — Delta 100% Operational Independence  
**Effort:** 3-4 days (Stuart: schema + RPCs + testing | AG: UI)  
**Dependencies:** Phase 25.8 (Super Admin Provisioning) ✅ | Phase 25.9 (RLS) ✅  
**Status:** Ready to Execute

---

## 1. Executive Summary

Phase 25.8 gave Delta the ability to **create** new namespaces. Phase 25.10 gives her the ability to **manage** existing ones — view, edit, add workspaces, manage users, change tiers. This eliminates all remaining SQL-dependent operations and achieves the Q1 milestone: **Delta 100% operationally independent**.

**Success Metric:** Delta can handle any customer operations request without asking Stuart to run SQL.

---

## 2. What Delta Needs (User Stories)

### 2.1 Namespace List
> *"As a platform admin, I need to see all namespaces at a glance so I can find and manage any customer."*

- View all namespaces in a searchable, filterable table
- See key stats at a glance: tier, workspace count, user count, app count, created date
- Search by name or slug
- Filter by tier (Free / Pro / Enterprise / Full)
- Sort by name, tier, created date, app count
- Click a namespace to open its detail view

### 2.2 Namespace Detail — Overview Tab
> *"As a platform admin, I need to see a customer's status at a glance and update their tier."*

- Namespace name (editable), slug (read-only), tier (editable via dropdown)
- Created date, last updated
- Summary stats: workspaces, users, applications, deployment profiles
- Organization settings (name, max budget)
- Tier change with confirmation dialog ("Are you sure you want to change City of Garland from Pro to Enterprise?")

### 2.3 Namespace Detail — Workspaces Tab
> *"As a platform admin, I need to add workspaces to existing customers without running SQL."*

- List of all workspaces in the namespace with: name, slug, user count, app count, is_default flag
- **Add Workspace** button → form: name, slug (auto-generated from name)
- Edit workspace name (inline or modal)
- Cannot delete workspaces (too dangerous — future phase with safety checks)

### 2.4 Namespace Detail — Users Tab
> *"As a platform admin, I need to see who has access and manage their roles."*

- List of all users in the namespace: name, email, namespace_role, workspace assignments, last login
- **Invite User** button → existing invitation flow
- Change namespace_role (admin ↔ editor ↔ steward ↔ read_only ↔ restricted)
- View workspace memberships per user
- Add/remove user from specific workspaces
- Change workspace role per user

---

## 3. Routes & Navigation

Extends the existing `/super-admin` section from Phase 25.8.

| Route | Component | Purpose |
|-------|-----------|---------|
| `/super-admin/namespaces` | NamespaceList | Searchable list of all namespaces |
| `/super-admin/namespaces/new` | CreateNamespace | **EXISTS** (Phase 25.8) |
| `/super-admin/namespaces/:id` | NamespaceDetail | Tabbed detail view |

**Navigation within NamespaceDetail:**
- Tab: Overview (default)
- Tab: Workspaces
- Tab: Users

**Header breadcrumb:** Super Admin → Namespaces → {Namespace Name}

---

## 4. Database Changes

### 4.1 New View: `vw_namespace_summary`

Provides the stats needed for the Namespace List page in a single query. Platform admins only.

```sql
-- Summary statistics per namespace for the super admin list view
CREATE OR REPLACE VIEW vw_namespace_summary AS
SELECT
  n.id,
  n.name,
  n.slug,
  n.tier,
  n.created_at,
  n.updated_at,
  os.name AS org_display_name,
  os.max_project_budget,
  COALESCE(ws.workspace_count, 0) AS workspace_count,
  COALESCE(us.user_count, 0) AS user_count,
  COALESCE(ap.app_count, 0) AS app_count,
  COALESCE(dp.dp_count, 0) AS dp_count
FROM namespaces n
LEFT JOIN organization_settings os ON os.namespace_id = n.id
LEFT JOIN (
  SELECT namespace_id, COUNT(*) AS workspace_count
  FROM workspaces
  GROUP BY namespace_id
) ws ON ws.namespace_id = n.id
LEFT JOIN (
  SELECT namespace_id, COUNT(*) AS user_count
  FROM users
  GROUP BY namespace_id
) us ON us.namespace_id = n.id
LEFT JOIN (
  SELECT w.namespace_id, COUNT(*) AS app_count
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  GROUP BY w.namespace_id
) ap ON ap.namespace_id = n.id
LEFT JOIN (
  SELECT w.namespace_id, COUNT(*) AS dp_count
  FROM deployment_profiles d
  JOIN workspaces w ON w.id = d.workspace_id
  GROUP BY w.namespace_id
) dp ON dp.namespace_id = n.id;
```

**RLS for the view:** The view inherits from the `namespaces` table RLS. Platform admins can see all namespaces. If needed, add an explicit policy:

```sql
-- Grant access to the view (views use the underlying table's RLS)
-- Platform admins already have SELECT on namespaces → this just works.
-- No additional RLS policy needed.
```

### 4.2 New View: `vw_namespace_workspace_detail`

Stats per workspace within a namespace, for the Workspaces tab.

```sql
CREATE OR REPLACE VIEW vw_namespace_workspace_detail AS
SELECT
  w.id,
  w.namespace_id,
  w.name,
  w.slug,
  w.is_default,
  w.created_at,
  COALESCE(wu.user_count, 0) AS user_count,
  COALESCE(ap.app_count, 0) AS app_count,
  COALESCE(dp.dp_count, 0) AS dp_count,
  COALESCE(pf.portfolio_count, 0) AS portfolio_count
FROM workspaces w
LEFT JOIN (
  SELECT workspace_id, COUNT(*) AS user_count
  FROM workspace_users
  GROUP BY workspace_id
) wu ON wu.workspace_id = w.id
LEFT JOIN (
  SELECT workspace_id, COUNT(*) AS app_count
  FROM applications
  GROUP BY workspace_id
) ap ON ap.workspace_id = w.id
LEFT JOIN (
  SELECT workspace_id, COUNT(*) AS dp_count
  FROM deployment_profiles
  GROUP BY workspace_id
) dp ON dp.workspace_id = w.id
LEFT JOIN (
  SELECT workspace_id, COUNT(*) AS portfolio_count
  FROM portfolios
  GROUP BY workspace_id
) pf ON pf.workspace_id = w.id;
```

### 4.3 New View: `vw_namespace_user_detail`

User details for the Users tab, including workspace assignments.

```sql
CREATE OR REPLACE VIEW vw_namespace_user_detail AS
SELECT
  u.id,
  u.namespace_id,
  u.email,
  u.name,
  u.namespace_role,
  u.created_at,
  u.updated_at,
  COALESCE(
    json_agg(
      json_build_object(
        'workspace_id', wu.workspace_id,
        'workspace_name', w.name,
        'role', wu.role
      )
    ) FILTER (WHERE wu.workspace_id IS NOT NULL),
    '[]'::json
  ) AS workspace_assignments
FROM users u
LEFT JOIN workspace_users wu ON wu.user_id = u.id
LEFT JOIN workspaces w ON w.id = wu.workspace_id AND w.namespace_id = u.namespace_id
GROUP BY u.id, u.namespace_id, u.email, u.name, u.namespace_role, u.created_at, u.updated_at;
```

### 4.4 RPC: `update_namespace_tier`

Safe tier change with validation.

```sql
CREATE OR REPLACE FUNCTION update_namespace_tier(
  p_namespace_id uuid,
  p_new_tier text
) RETURNS jsonb AS $$
DECLARE
  v_old_tier text;
  v_namespace_name text;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can change namespace tiers';
  END IF;

  -- Validate tier
  IF p_new_tier NOT IN ('free', 'pro', 'enterprise', 'full') THEN
    RAISE EXCEPTION 'Invalid tier: %. Must be free, pro, enterprise, or full', p_new_tier;
  END IF;

  -- Get current state
  SELECT tier, name INTO v_old_tier, v_namespace_name
  FROM namespaces
  WHERE id = p_namespace_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Namespace not found: %', p_namespace_id;
  END IF;

  -- No-op if same tier
  IF v_old_tier = p_new_tier THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Tier unchanged',
      'namespace_id', p_namespace_id,
      'tier', p_new_tier
    );
  END IF;

  -- Update tier
  UPDATE namespaces
  SET tier = p_new_tier, updated_at = now()
  WHERE id = p_namespace_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', format('Tier changed from %s to %s', v_old_tier, p_new_tier),
    'namespace_id', p_namespace_id,
    'namespace_name', v_namespace_name,
    'old_tier', v_old_tier,
    'new_tier', p_new_tier
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.5 RPC: `add_workspace_to_namespace`

Creates a workspace within an existing namespace, bypassing the trigger that auto-adds the current user.

```sql
CREATE OR REPLACE FUNCTION add_workspace_to_namespace(
  p_namespace_id uuid,
  p_workspace_name text,
  p_workspace_slug text
) RETURNS jsonb AS $$
DECLARE
  v_workspace_id uuid;
  v_namespace_name text;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can add workspaces';
  END IF;

  -- Verify namespace exists
  SELECT name INTO v_namespace_name
  FROM namespaces
  WHERE id = p_namespace_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Namespace not found: %', p_namespace_id;
  END IF;

  -- Check for duplicate slug within namespace
  IF EXISTS (
    SELECT 1 FROM workspaces
    WHERE namespace_id = p_namespace_id AND slug = p_workspace_slug
  ) THEN
    RAISE EXCEPTION 'Workspace slug "%" already exists in this namespace', p_workspace_slug;
  END IF;

  -- Insert workspace
  -- Note: create_default_portfolio_trigger will auto-create "Core" portfolio
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (p_namespace_id, p_workspace_name, p_workspace_slug, false)
  RETURNING id INTO v_workspace_id;

  -- Add all namespace admins to the new workspace
  INSERT INTO workspace_users (workspace_id, user_id, role)
  SELECT v_workspace_id, u.id, 'admin'
  FROM users u
  WHERE u.namespace_id = p_namespace_id
    AND u.namespace_role = 'admin'
  ON CONFLICT (workspace_id, user_id) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'workspace_id', v_workspace_id,
    'workspace_name', p_workspace_name,
    'namespace_name', v_namespace_name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.6 RPC: `update_user_namespace_role`

Change a user's namespace-level role.

```sql
CREATE OR REPLACE FUNCTION update_user_namespace_role(
  p_user_id uuid,
  p_new_role text
) RETURNS jsonb AS $$
DECLARE
  v_user_email text;
  v_old_role text;
  v_admin_count integer;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can change user roles';
  END IF;

  -- Validate role
  IF p_new_role NOT IN ('admin', 'editor', 'steward', 'read_only', 'restricted') THEN
    RAISE EXCEPTION 'Invalid role: %. Must be admin, editor, steward, read_only, or restricted', p_new_role;
  END IF;

  -- Get current state
  SELECT email, namespace_role INTO v_user_email, v_old_role
  FROM users
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found: %', p_user_id;
  END IF;

  -- Safety: prevent removing the last admin
  IF v_old_role = 'admin' AND p_new_role != 'admin' THEN
    SELECT COUNT(*) INTO v_admin_count
    FROM users
    WHERE namespace_id = (SELECT namespace_id FROM users WHERE id = p_user_id)
      AND namespace_role = 'admin'
      AND id != p_user_id;

    IF v_admin_count = 0 THEN
      RAISE EXCEPTION 'Cannot remove the last namespace admin. Promote another user first.';
    END IF;
  END IF;

  -- Update role
  UPDATE users
  SET namespace_role = p_new_role, updated_at = now()
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_email', v_user_email,
    'old_role', v_old_role,
    'new_role', p_new_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.7 RPC: `update_workspace_user_role`

Change a user's role within a specific workspace.

```sql
CREATE OR REPLACE FUNCTION update_workspace_user_role(
  p_workspace_id uuid,
  p_user_id uuid,
  p_new_role text
) RETURNS jsonb AS $$
DECLARE
  v_old_role text;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can change workspace roles';
  END IF;

  -- Validate role
  IF p_new_role NOT IN ('admin', 'editor', 'steward', 'read_only', 'restricted') THEN
    RAISE EXCEPTION 'Invalid workspace role: %', p_new_role;
  END IF;

  -- Get current state
  SELECT role INTO v_old_role
  FROM workspace_users
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User is not a member of this workspace';
  END IF;

  -- Update
  UPDATE workspace_users
  SET role = p_new_role
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'old_role', v_old_role,
    'new_role', p_new_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.8 RPC: `add_user_to_workspace`

Add an existing namespace user to a workspace.

```sql
CREATE OR REPLACE FUNCTION add_user_to_workspace(
  p_workspace_id uuid,
  p_user_id uuid,
  p_role text DEFAULT 'editor'
) RETURNS jsonb AS $$
DECLARE
  v_workspace_namespace uuid;
  v_user_namespace uuid;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can add users to workspaces';
  END IF;

  -- Validate role
  IF p_role NOT IN ('admin', 'editor', 'steward', 'read_only', 'restricted') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  -- Verify user and workspace are in the same namespace
  SELECT namespace_id INTO v_workspace_namespace FROM workspaces WHERE id = p_workspace_id;
  SELECT namespace_id INTO v_user_namespace FROM users WHERE id = p_user_id;

  IF v_workspace_namespace IS NULL THEN
    RAISE EXCEPTION 'Workspace not found';
  END IF;
  IF v_user_namespace IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;
  IF v_workspace_namespace != v_user_namespace THEN
    RAISE EXCEPTION 'User and workspace must be in the same namespace';
  END IF;

  -- Insert (ignore if already exists)
  INSERT INTO workspace_users (workspace_id, user_id, role)
  VALUES (p_workspace_id, p_user_id, p_role)
  ON CONFLICT (workspace_id, user_id) DO NOTHING;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.9 RPC: `remove_user_from_workspace`

```sql
CREATE OR REPLACE FUNCTION remove_user_from_workspace(
  p_workspace_id uuid,
  p_user_id uuid
) RETURNS jsonb AS $$
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can remove users from workspaces';
  END IF;

  DELETE FROM workspace_users
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. Schema Change Summary

| Change | Type | Notes |
|--------|------|-------|
| `vw_namespace_summary` | New View | Namespace list with rollup stats |
| `vw_namespace_workspace_detail` | New View | Workspace stats per namespace |
| `vw_namespace_user_detail` | New View | User + workspace assignments |
| `update_namespace_tier()` | New RPC | Safe tier change with validation |
| `add_workspace_to_namespace()` | New RPC | Create workspace, auto-add admins |
| `update_user_namespace_role()` | New RPC | Change user role, last-admin guard |
| `update_workspace_user_role()` | New RPC | Change workspace-level role |
| `add_user_to_workspace()` | New RPC | Add user to workspace (same-namespace check) |
| `remove_user_from_workspace()` | New RPC | Remove user from workspace |

**No new tables.** All operations use existing tables.  
**No migration needed.** Views and functions are additive.

---

## 6. UI Specifications

### 6.1 Namespace List Page (`/super-admin/namespaces`)

```
┌──────────────────────────────────────────────────────────────────┐
│ Super Admin → Namespaces                    [+ Create Namespace] │
├──────────────────────────────────────────────────────────────────┤
│ Search: [________________]   Tier: [All ▼]                       │
├──────────────────────────────────────────────────────────────────┤
│ Name               │ Tier       │ Workspaces │ Users │ Apps │ Created     │
│────────────────────┼────────────┼────────────┼───────┼──────┼─────────────│
│ City of Riverside  │ Enterprise │ 17         │ 3     │ 56   │ Jan 15 2026 │
│ Gov of Alberta Test│ Enterprise │ 3          │ 2     │ 10   │ Jan 22 2026 │
│ Delta's OrgSpace   │ Enterprise │ 1          │ 1     │ 0    │ Feb 3 2026  │
│ Default Org        │ Trial      │ 1          │ 0     │ 0    │ Dec 22 2025 │
└──────────────────────────────────────────────────────────────────┘
```

**Behavior:**
- Click row → navigate to `/super-admin/namespaces/:id`
- "+ Create Namespace" → navigate to `/super-admin/namespaces/new` (existing page)
- Search filters as-you-type on name and slug
- Tier filter dropdown: All, Free, Pro, Enterprise, Full
- Default sort: name ascending
- Column headers clickable for sort toggle

### 6.2 Namespace Detail — Overview Tab

```
┌──────────────────────────────────────────────────────────────────┐
│ ← Back to Namespaces                                             │
│                                                                  │
│ City of Riverside (Demo)                                         │
│ Slug: city-of-riverside-demo                                     │
├──────────────────────────────────────────────────────────────────┤
│ [Overview]  [Workspaces]  [Users]                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │   17    │ │    3    │ │   56    │ │   72    │               │
│  │Workspaces│ │  Users  │ │  Apps   │ │  DPs    │               │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘               │
│                                                                  │
│  Tier:     [Enterprise ▼]  [Save]                                │
│  Name:     [City of Riverside (Demo)___]  [Save]                 │
│  Created:  January 15, 2026                                      │
│  Updated:  February 6, 2026                                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Behavior:**
- Tier dropdown: Free, Pro, Enterprise, Full → Save calls `update_namespace_tier()` RPC
- Tier change shows confirmation dialog before saving
- Name edit saves directly to `namespaces.name` via Supabase update
- Slug is read-only (displayed but not editable)
- Stats cards are read-only, pulled from `vw_namespace_summary`

### 6.3 Namespace Detail — Workspaces Tab

```
┌──────────────────────────────────────────────────────────────────┐
│ [Overview]  [Workspaces]  [Users]                                │
├──────────────────────────────────────────────────────────────────┤
│                                                    [+ Add Workspace]│
│                                                                  │
│ Name                    │ Slug             │ Users │ Apps │ Default│
│─────────────────────────┼──────────────────┼───────┼──────┼────────│
│ Central IT              │ central-it       │ 3     │ 24   │ ★      │
│ Human Resources         │ human-resources  │ 2     │ 12   │        │
│ Finance                 │ finance          │ 2     │ 20   │        │
└──────────────────────────────────────────────────────────────────┘
```

**Add Workspace modal:**
```
┌──────────────────────────────────────┐
│ Add Workspace                        │
│                                      │
│ Name: [____________________]         │
│ Slug: [____________________]  (auto) │
│                                      │
│        [Cancel]  [Add Workspace]     │
└──────────────────────────────────────┘
```

**Behavior:**
- Slug auto-generates from name (lowercase, hyphens, strip special chars)
- Slug is editable (user can override)
- Add calls `add_workspace_to_namespace()` RPC
- On success, refresh workspace list
- No delete button (deliberate — too dangerous for v1)

### 6.4 Namespace Detail — Users Tab

```
┌──────────────────────────────────────────────────────────────────┐
│ [Overview]  [Workspaces]  [Users]                                │
├──────────────────────────────────────────────────────────────────┤
│                                                   [+ Invite User]│
│                                                                  │
│ Name          │ Email              │ NS Role  │ Workspaces        │
│───────────────┼────────────────────┼──────────┼───────────────────│
│ Stuart Holtby │ stuart@allstar...  │ admin ▼  │ Central IT (admin)│
│               │                    │          │ Finance (admin)   │
│───────────────┼────────────────────┼──────────┼───────────────────│
│ Jane Doe      │ jane@riverside.ca  │ editor ▼ │ Finance (editor)  │
│               │                    │          │ HR (read_only)    │
└──────────────────────────────────────────────────────────────────┘
```

**Behavior:**
- Namespace role dropdown inline: admin / editor / steward / read_only / restricted
- Change calls `update_user_namespace_role()` RPC
- Confirmation dialog when demoting admin
- Workspace assignments shown as chips/badges
- Click workspace chip → could expand to change workspace role (stretch)
- "+ Invite User" → navigates to existing invitation flow or opens invite modal

**Expandable row (click user to expand):**
```
│ ▼ Jane Doe   │ jane@riverside.ca  │ editor ▼ │                   │
│   ┌───────────────────────────────────────────────────────────┐  │
│   │ Workspace Assignments:                                    │  │
│   │  Finance        [editor ▼]  [Remove]                      │  │
│   │  HR             [read_only ▼]  [Remove]                   │  │
│   │  [+ Add to Workspace ▼]                                   │  │
│   └───────────────────────────────────────────────────────────┘  │
```

---

## 7. Safety & Validation Rules

| Operation | Safety Check |
|-----------|-------------|
| Change tier | Confirmation dialog with old → new tier |
| Demote admin | Must have ≥1 remaining admin (enforced in RPC) |
| Remove user from workspace | Confirmation: "Remove {name} from {workspace}?" |
| Add workspace | Validate slug uniqueness within namespace |
| Delete workspace | **NOT AVAILABLE in v1** — too risky |
| Delete user | **NOT AVAILABLE in v1** — use role change to restricted |

---

## 8. Technical Notes for AG

### 8.1 Supabase Queries

**Namespace List:**
```typescript
const { data } = await supabase
  .from('vw_namespace_summary')
  .select('*')
  .order('name');
```

**Namespace Detail (single):**
```typescript
const { data } = await supabase
  .from('vw_namespace_summary')
  .select('*')
  .eq('id', namespaceId)
  .single();
```

**Workspaces for a namespace:**
```typescript
const { data } = await supabase
  .from('vw_namespace_workspace_detail')
  .select('*')
  .eq('namespace_id', namespaceId)
  .order('name');
```

**Users for a namespace:**
```typescript
const { data } = await supabase
  .from('vw_namespace_user_detail')
  .select('*')
  .eq('namespace_id', namespaceId)
  .order('name');
```

**RPC calls:**
```typescript
// Change tier
const { data } = await supabase.rpc('update_namespace_tier', {
  p_namespace_id: namespaceId,
  p_new_tier: 'enterprise'
});

// Add workspace
const { data } = await supabase.rpc('add_workspace_to_namespace', {
  p_namespace_id: namespaceId,
  p_workspace_name: 'New Department',
  p_workspace_slug: 'new-department'
});

// Change namespace role
const { data } = await supabase.rpc('update_user_namespace_role', {
  p_user_id: userId,
  p_new_role: 'editor'
});

// Change workspace role
const { data } = await supabase.rpc('update_workspace_user_role', {
  p_workspace_id: workspaceId,
  p_user_id: userId,
  p_new_role: 'admin'
});

// Add user to workspace
const { data } = await supabase.rpc('add_user_to_workspace', {
  p_workspace_id: workspaceId,
  p_user_id: userId,
  p_role: 'editor'
});

// Remove user from workspace
const { data } = await supabase.rpc('remove_user_from_workspace', {
  p_workspace_id: workspaceId,
  p_user_id: userId
});
```

### 8.2 Access Control

All pages are behind the `is_platform_admin()` check. The existing super admin middleware from Phase 25.8 handles this:

```typescript
// Already exists from Phase 25.8
async function requirePlatformAdmin() {
  const { data: isAdmin } = await supabase.rpc('is_platform_admin');
  if (!isAdmin) {
    navigate('/'); // or show 403
  }
}
```

### 8.3 Slug Generation Helper

```typescript
function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
}
```

---

## 9. AG Prompt

Below is the prompt to give AG (Antigravity / bolt.new) to build the frontend.

---

### AG PROMPT START

```
# Feature: Namespace Management UI (Phase 25.10)

## Context
We're building a Super Admin section that lets platform admins (Delta, Stuart) manage 
all customer namespaces. Phase 25.8 already created the "Create Namespace" page at 
/super-admin/namespaces/new. Now we need to add:

1. Namespace List page (/super-admin/namespaces)
2. Namespace Detail page with 3 tabs (/super-admin/namespaces/:id)

These are INTERNAL admin pages — only visible to platform admins. They don't need to 
be flashy, they need to be functional and reliable.

## Existing Infrastructure
- /super-admin/namespaces/new already exists (don't break it)
- is_platform_admin() RPC exists and returns boolean
- Supabase client is configured
- React Router is configured

## Database Views (already created by Stuart — just query them)

### vw_namespace_summary
Returns one row per namespace with:
- id, name, slug, tier, created_at, updated_at
- org_display_name, max_project_budget
- workspace_count, user_count, app_count, dp_count

### vw_namespace_workspace_detail
Returns one row per workspace with:
- id, namespace_id, name, slug, is_default, created_at
- user_count, app_count, dp_count, portfolio_count

### vw_namespace_user_detail
Returns one row per user with:
- id, namespace_id, email, name, namespace_role, created_at, updated_at
- workspace_assignments (JSON array of {workspace_id, workspace_name, role})

## RPC Functions (already created by Stuart — just call them)

1. update_namespace_tier(p_namespace_id uuid, p_new_tier text) → jsonb
2. add_workspace_to_namespace(p_namespace_id uuid, p_workspace_name text, p_workspace_slug text) → jsonb
3. update_user_namespace_role(p_user_id uuid, p_new_role text) → jsonb
4. update_workspace_user_role(p_workspace_id uuid, p_user_id uuid, p_new_role text) → jsonb
5. add_user_to_workspace(p_workspace_id uuid, p_user_id uuid, p_role text) → jsonb
6. remove_user_from_workspace(p_workspace_id uuid, p_user_id uuid) → jsonb

All RPCs return { success: boolean, message?: string, ... } on success.
All RPCs throw errors on failure (catch with try/catch).

## Page 1: Namespace List (/super-admin/namespaces)

### Layout
- Page title: "Namespaces" with breadcrumb "Super Admin → Namespaces"
- Top-right: "+ Create Namespace" button (links to /super-admin/namespaces/new)
- Below title: Search input + Tier filter dropdown (All / Free / Pro / Enterprise / Full)
- Table with columns: Name, Tier, Workspaces, Users, Apps, Created
- Click row → navigate to /super-admin/namespaces/:id
- Tier shown as colored badge (Free=gray, Pro=blue, Enterprise=purple, Full=gold)

### Data Source
```typescript
const { data } = await supabase
  .from('vw_namespace_summary')
  .select('*')
  .order('name');
```

Filter client-side by search text (name, slug) and tier dropdown.

## Page 2: Namespace Detail (/super-admin/namespaces/:id)

### Layout
- Breadcrumb: "Super Admin → Namespaces → {name}"
- Back button
- Namespace name (large heading)
- Slug shown below name (muted text)
- 3 tabs: Overview | Workspaces | Users

### Tab: Overview
- 4 stat cards in a row: Workspaces, Users, Apps, DPs (numeric value + label)
- Editable fields:
  - Name: text input with inline Save button
  - Tier: dropdown (free/pro/enterprise/full) with Save button
  - Tier change shows confirmation dialog: "Change {name} from {old} to {new}?"
- Read-only fields: Slug, Created, Updated

Data: Query vw_namespace_summary with .eq('id', namespaceId).single()

To save name: 
```typescript
await supabase.from('namespaces').update({ name: newName }).eq('id', namespaceId);
```

To save tier:
```typescript
await supabase.rpc('update_namespace_tier', { p_namespace_id: namespaceId, p_new_tier: newTier });
```

### Tab: Workspaces
- Table: Name, Slug, Users, Apps, Portfolios, Default (star icon)
- "+ Add Workspace" button opens modal with Name input + auto-slug
- Slug auto-generates from name (lowercase, hyphens, strip specials)
- Slug field is editable (override allowed)
- Add calls: supabase.rpc('add_workspace_to_namespace', {...})
- No delete or edit on existing workspaces (v1)
- Refresh list after add

Data: Query vw_namespace_workspace_detail where namespace_id = current

### Tab: Users
- Table: Name, Email, Namespace Role (dropdown), Workspace Assignments
- Namespace role dropdown inline on each row: admin/editor/steward/read_only/restricted
- Role change calls: supabase.rpc('update_user_namespace_role', {...})
- Show confirmation when demoting from admin
- Workspace assignments shown as badge chips: "Finance (editor)", "IT (admin)"
- Expandable row: click to show workspace management
  - Each workspace assignment: workspace name, role dropdown, Remove button
  - "+ Add to Workspace" dropdown (shows workspaces user is NOT in)
  - Add calls: supabase.rpc('add_user_to_workspace', {...})
  - Remove calls: supabase.rpc('remove_user_from_workspace', {...})
  - Role change calls: supabase.rpc('update_workspace_user_role', {...})
- Confirmation on remove: "Remove {user} from {workspace}?"

Data: Query vw_namespace_user_detail where namespace_id = current

## Styling
- Use existing Tailwind classes consistent with the rest of the app
- Cards with shadow-sm, rounded-lg, p-4
- Table with alternating row colors or border-bottom
- Badges for tier: gray=free, blue=pro, purple=enterprise, amber=full
- Toast notifications for success/error on mutations
- Loading spinners on data fetch and mutations

## Error Handling
- All RPC calls wrapped in try/catch
- Show error toast with the error message
- Revert UI state on error (e.g., revert dropdown selection)
- Loading state during mutations (disable buttons)

## DO NOT
- Do not modify any database schema (Stuart handles that)
- Do not create new Supabase tables or columns
- Do not modify the existing Create Namespace page
- Do not add delete namespace or delete workspace functionality
- Do not add user creation (use existing invite flow)
```

### AG PROMPT END

---

## 10. Implementation Plan

### Day 1: Stuart — Schema (2-3 hours)
1. Create `vw_namespace_summary` view
2. Create `vw_namespace_workspace_detail` view
3. Create `vw_namespace_user_detail` view
4. Create all 6 RPCs (tier, workspace, role management)
5. Test views and RPCs in Supabase SQL editor
6. Verify platform admin RLS works for views
7. Git commit schema changes

### Day 1-2: AG — Namespace List Page (3-4 hours)
1. Create NamespaceList component
2. Search + filter functionality
3. Tier badges
4. Click-to-navigate to detail page
5. Wire up to vw_namespace_summary

### Day 2-3: AG — Namespace Detail Page (4-6 hours)
1. Create NamespaceDetail component with tab navigation
2. Overview tab: stat cards, editable name/tier
3. Workspaces tab: list + add workspace modal
4. Users tab: role dropdowns, expandable rows, workspace management
5. Wire up all RPCs
6. Error handling + confirmations

### Day 3-4: Testing + Polish (2-3 hours)
1. Test with real production namespaces (City of Riverside, Gov Alberta Test)
2. Test tier changes
3. Test adding workspaces
4. Test user role changes
5. Test workspace assignment changes
6. Delta walkthrough and feedback
7. Fix issues, deploy

---

## 11. Testing Checklist

### Namespace List
- [ ] All namespaces visible to platform admin
- [ ] Search filters by name
- [ ] Search filters by slug
- [ ] Tier filter works (each tier + All)
- [ ] Sort by columns works
- [ ] Click navigates to detail page
- [ ] "+ Create Namespace" links to existing page

### Overview Tab
- [ ] Stats cards show correct counts
- [ ] Name edit + save works
- [ ] Tier change + confirmation + save works
- [ ] Tier change reflected in list after back navigation
- [ ] Slug is read-only
- [ ] Error handling on failed save

### Workspaces Tab
- [ ] Shows all workspaces for namespace
- [ ] Stats (users, apps) are accurate
- [ ] Default workspace shows star/indicator
- [ ] Add Workspace: slug auto-generates
- [ ] Add Workspace: duplicate slug shows error
- [ ] Add Workspace: new workspace appears in list
- [ ] Add Workspace: namespace admins auto-added to workspace

### Users Tab
- [ ] Shows all users in namespace
- [ ] Namespace role dropdown changes role
- [ ] Cannot demote last admin (error shown)
- [ ] Workspace assignments displayed correctly
- [ ] Expand row shows workspace management
- [ ] Can change workspace role
- [ ] Can add user to workspace
- [ ] Can remove user from workspace
- [ ] Confirmations shown for destructive actions

### Access Control
- [ ] Non-platform-admin gets redirected/403
- [ ] RLS prevents data leakage via views

---

## 12. What's NOT in This Phase

| Excluded | Reason | Future Phase |
|----------|--------|-------------|
| Delete namespace | Extremely dangerous, needs soft-delete + archival | Phase 29 |
| Delete workspace | Data loss risk, needs migration path | Phase 29 |
| Delete user | Use role=restricted instead | Phase 29 |
| Namespace branding (logo) | Nice-to-have, not operational | Phase 30+ |
| Audit log UI | Valuable but not blocking Delta | Phase 29 |
| Bulk operations | Scale feature, not needed yet | Phase 30+ |
| Namespace impersonation | "View as customer" — powerful but complex | Phase 30+ |

---

## 13. Success Criteria

Phase 25.10 is **COMPLETE** when:

- ✅ Delta can view all namespaces in a searchable list
- ✅ Delta can view namespace details (stats, workspaces, users)
- ✅ Delta can change a namespace's tier
- ✅ Delta can add a workspace to an existing namespace
- ✅ Delta can change a user's namespace role
- ✅ Delta can manage user workspace assignments
- ✅ All operations have confirmation dialogs for destructive actions
- ✅ Error handling prevents data corruption
- ✅ Delta confirms she can handle all routine operations without SQL

---

## 14. Related Documents

- `planning/phase-25-8-super-admin-plan.md` — Create Namespace (foundation)
- `planning/super-admin-provisioning.md` — Provisioning architecture
- `core/namespace-workspace-ui.md` — UI architecture patterns
- `identity-security/rls-policy.md` — RLS patterns (Phase 25.9)
- `archive/superseded/identity-security-v1_0.md` — RBAC model
- `operations/team-workflow.md` — Claude/Stuart/AG workflow

---

**Document:** core/namespace-management-ui.md  
**Last Updated:** February 7, 2026  
**Author:** Stuart Holtby / Claude
