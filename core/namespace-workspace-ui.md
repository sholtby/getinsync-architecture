# GetInSync NextGen - Namespace & Workspace UI Architecture

**Version:** 1.0  
**Status:** Planned  
**Last Updated:** 2026-01-02

---

## 1. Overview

This document defines how Namespaces and Workspaces are displayed and navigated in the UI, including visibility rules, naming conventions, and future multi-namespace support.

---

## 2. Hierarchy Recap

```
Namespace (Tenant/Customer)
├── Workspace 1
│   ├── Applications
│   ├── Portfolios
│   └── Contacts
├── Workspace 2
│   └── ...
└── Workspace N
    └── ...
```

| Entity | Scope | Example |
|--------|-------|---------|
| Namespace | Tenant/Customer | "Government of Saskatchewan" |
| Workspace | Department/Division | "Ministry of Finance" |
| WorkspaceGroup | Reporting subset (future) | "Finance Division" |

---

## 3. Current State

### Header Display
- Shows: Workspace name only
- Missing: Namespace name

### Workspace Dropdown
- Shows: "All Workspaces" + list of workspaces
- Issue: "All Workspaces" is misleading if user doesn't have access to all

### Settings
- No visible namespace information

---

## 4. Target State

### 4.1 Header Display

```
┌─────────────────────────────────────────────────────────────────┐
│ [Logo] Government of Saskatchewan                               │
│        ┌──────────────────────────┐                             │
│        │ My Workspaces          ▼ │  [Dashboard] [Settings]     │
│        └──────────────────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

**Elements:**
1. **Namespace name** in header (e.g., "Government of Saskatchewan")
2. **Logo placeholder** for future branding
3. **Workspace dropdown** with "My Workspaces" as aggregate option

### 4.2 Workspace Dropdown

**Current:**
```
┌──────────────────────────┐
│ All Workspaces         ▼ │
├──────────────────────────┤
│ All Workspaces           │
│ GOS Workspace            │
│ Ministry of Finance      │
└──────────────────────────┘
```

**Target:**
```
┌──────────────────────────┐
│ My Workspaces          ▼ │
├──────────────────────────┤
│ My Workspaces            │  ← Aggregate view
│ ─────────────────────────│
│ GOS Workspace            │
│ Ministry of Finance      │
└──────────────────────────┘
```

### 4.3 Settings - Namespace Info

In Organization/Namespace settings (read-only display):

```
┌─────────────────────────────────────────────────────────────────┐
│ Organization Settings                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Organization Name: Government of Saskatchewan                   │
│ Namespace ID: gov-of-sask (read-only)                          │
│                                                                 │
│ Workspaces: 3                                                   │
│ Users: 12                                                       │
│ Applications: 47                                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Visibility Rules

### 5.1 "My Workspaces" View

Shows aggregate data from ALL workspaces the user has access to in the current namespace.

| User Role | Sees |
|-----------|------|
| Namespace Admin | All workspaces in namespace |
| Workspace Admin | Only their assigned workspaces |
| Editor/Steward | Only their assigned workspaces |

### 5.2 Single Workspace View

Shows data only from the selected workspace.

### 5.3 Data Aggregation in "My Workspaces"

| Data Type | Aggregation |
|-----------|-------------|
| Applications | Union of all apps from accessible workspaces |
| Portfolios | Grouped by workspace or flattened |
| Deployment Profiles | Rolled up under applications |
| Contacts | Union (may show duplicates if same person in multiple workspaces) |
| Organizations | Shared orgs appear once; local orgs grouped by workspace |

---

## 6. Multi-Namespace Support (Enterprise - Future)

### 6.1 When User Has Access to Multiple Namespaces

Add namespace selector above workspace selector:

```
┌─────────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────┐                                    │
│ │ Government of Sask.    ▼ │  ← Namespace selector              │
│ └──────────────────────────┘                                    │
│ ┌──────────────────────────┐                                    │
│ │ My Workspaces          ▼ │  ← Workspace selector              │
│ └──────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────┘
```

**Namespace dropdown (when multi-namespace):**
```
┌──────────────────────────┐
│ Government of Sask.    ▼ │
├──────────────────────────┤
│ Government of Sask.      │
│ Pal's Pets               │
│ City of Garland          │
└──────────────────────────┘
```

### 6.2 MSP/Consultant Scenario

A consultant working for multiple clients:
- Each client = separate Namespace
- Consultant has workspace access in each
- Must switch namespace context to see different client's data
- Data is NEVER mixed across namespaces

### 6.3 Tier Gating

| Tier | Namespace Access |
|------|------------------|
| Free | 1 namespace only |
| Pro | 1 namespace only |
| Enterprise | Multiple namespaces |

---

## 7. Database Implications

### 7.1 Current Schema

```sql
-- Users can access multiple workspaces
workspace_users (
  user_id,
  workspace_id,
  role
)

-- Workspaces belong to one namespace
workspaces (
  id,
  namespace_id,
  name
)
```

### 7.2 Determining User's Namespaces

```sql
-- Get all namespaces a user has access to
SELECT DISTINCT n.id, n.name
FROM namespaces n
JOIN workspaces w ON w.namespace_id = n.id
JOIN workspace_users wu ON wu.workspace_id = w.id
WHERE wu.user_id = :current_user_id;
```

### 7.3 Determining User's Workspaces in a Namespace

```sql
-- Get all workspaces user can access in a namespace
SELECT w.id, w.name
FROM workspaces w
JOIN workspace_users wu ON wu.workspace_id = w.id
WHERE wu.user_id = :current_user_id
AND w.namespace_id = :current_namespace_id;
```

---

## 8. Implementation Phases

### Phase 1: Basic Namespace Display (Now)
- [ ] Show namespace name in header
- [ ] Rename "All Workspaces" → "My Workspaces"
- [ ] Show namespace name in Settings (read-only)

### Phase 2: Namespace Branding (Later)
- [ ] Logo upload for namespace
- [ ] Color theme customization
- [ ] Custom domain (Enterprise)

### Phase 3: Multi-Namespace Selector (Enterprise)
- [ ] Namespace dropdown in header
- [ ] Switch namespace context
- [ ] Maintain separate "current workspace" per namespace

---

## 9. UI Components to Update

| Component | Change |
|-----------|--------|
| `Header.tsx` or `AppHeader.tsx` | Add namespace name display |
| `WorkspaceSelector.tsx` | Rename "All Workspaces" → "My Workspaces" |
| `SettingsLayout.tsx` | Add namespace info section |
| `useAuth.tsx` or `AuthContext.tsx` | Expose `currentNamespace` |

---

## 10. Open Questions

1. **Should "My Workspaces" be the default selection?** Or remember last selected workspace?

2. **What happens if user is removed from all workspaces in a namespace?** Show "No access" message?

3. **Should namespace admins see workspaces they don't explicitly have workspace_users records for?** Or must they be explicitly added?

4. **WorkspaceGroups** — How do they fit into the dropdown?
   - Separate section?
   - Replace "My Workspaces" for users with group access?

---

## 11. Related Documents

- `core/workspace-group.md` - WorkspaceGroup model
- `archive/superseded/identity-security-v1_0.md` - RBAC model
- `marketing/pricing-model.md` - Tier limits

