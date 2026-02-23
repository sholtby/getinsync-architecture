# Multi-Tenant Phase 4: User Management UI

## Overview

Add UI for managing workspaces and users. This enables **Namespace Admins (Central IT)** to create workspaces for ministries/departments and invite users.

**Prerequisites:** Phases 1-3 must be complete.

**Goal:** Central IT can create workspaces, invite ministry leads, and see cross-workspace summary.

---

## Central IT / Shared Services Model

This is the typical government/enterprise pattern:

```
SaskBuilds (Namespace)                         â† Central IT / Namespace Admin
â”œâ”€â”€ Ministry of Justice (Workspace)            â† Workspace Admin: Justice IT lead
â”‚     â””â”€â”€ Applications, Portfolios
â”œâ”€â”€ Ministry of Advanced Education (Workspace) â† Workspace Admin: AdvEd IT lead
â”‚     â””â”€â”€ Applications, Portfolios
â”œâ”€â”€ Ministry of Finance (Workspace)            â† Workspace Admin: Finance IT lead
â”‚     â””â”€â”€ Applications, Portfolios
â””â”€â”€ Shared Services (Workspace)                â† Optional: Central IT's own apps
      â””â”€â”€ Applications, Portfolios
```

---

## Role Hierarchy

| Role | Scope | Capabilities |
|------|-------|--------------|
| **Namespace Admin** | Entire tenant | Create/delete workspaces, invite any user, assign users to any workspace, view all workspaces, manage billing, see cross-workspace reports |
| **Workspace Admin** | Single workspace | Manage portfolios in their workspace, invite users to their workspace only, perform assessments |
| **Editor** | Single workspace | Add apps, perform assessments, edit data |
| **Viewer** | Single workspace | Read-only access to workspace data |

---

## Typical Workflow

1. **Central IT (SaskBuilds)** signs up â†’ becomes Namespace Admin
2. Central IT creates workspaces: "Justice", "Advanced Education", "Finance"
3. Central IT invites Ministry IT leads by email â†’ assigns them as Workspace Admins
4. Ministry IT leads log in â†’ see only their workspace
5. Ministry IT leads invite their own staff as Editors/Viewers
6. Each Ministry only sees their own workspace data
7. Central IT can view aggregate dashboard across all workspaces

---

## New Screens

### 1. Settings Navigation Structure

```
Settings (accessed from user menu)
â”œâ”€â”€ Organization (Namespace Admin only)
â”‚   â”œâ”€â”€ Organization Name
â”‚   â””â”€â”€ Billing/Tier info
â”œâ”€â”€ Workspaces (Namespace Admin only)
â”‚   â”œâ”€â”€ List all workspaces with stats
â”‚   â”œâ”€â”€ Create workspace
â”‚   â””â”€â”€ Edit/Delete workspace
â”œâ”€â”€ Users (Namespace Admin only)
â”‚   â”œâ”€â”€ List all users across namespace
â”‚   â”œâ”€â”€ Invite user (assign to workspace + role)
â”‚   â””â”€â”€ Manage user roles
â””â”€â”€ Workspace Settings (Workspace Admin+)
    â”œâ”€â”€ T-shirt sizing config
    â””â”€â”€ Workspace name (if admin)
```

---

## Namespace Admin Dashboard

When a **Namespace Admin** views the dashboard, they should see an option to view **all workspaces**:

**Workspace Selector Dropdown (for Namespace Admins):**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ ðŸ“ All Workspaces (Admin View)      â”‚  â† Only visible to Namespace Admins
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ ðŸ“ Justice                          â”‚
â”‚ ðŸ“ Advanced Education               â”‚
â”‚ ðŸ“ Finance                          â”‚
â”‚ ðŸ“ Shared Services          Default â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ âš™ï¸ Manage Workspaces...              â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**"All Workspaces" Admin View shows:**
- Total applications across all workspaces
- Total annual cost (aggregate)
- Assessment completion by workspace (table or chart)
- Applications table with "Workspace" column

**"All Workspaces" does NOT show:**
- Combined TIME/PAID bubble charts (that's a GetInSync full feature)
- "View Charts" button switches to default workspace first

---

## Organization Settings Page

```tsx
// src/pages/settings/OrganizationSettings.tsx

// Only Namespace Admins can access
```

**UI:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Organization Settings                                           â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Organization Name                                               â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ SaskBuilds                                                  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ Current Tier                                                    â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ ðŸ¢ Pro                                    [Manage Billing â†’] â”‚ â”‚
â”‚ â”‚ 5 workspaces Â· 20 users Â· 100 apps per workspace            â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                 â”‚
â”‚ T-Shirt Sizing (applies to all workspaces)                      â”‚
â”‚ Maximum Single-Project Budget                                   â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ $ 1,000,000                                                 â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Save Changes         â”‚                â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Workspaces Management Page (Namespace Admin Only)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Workspaces                                    [+ Create Workspace] â”‚
â”‚ 4 of 5 workspaces used (Pro tier)                               â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Name              Applications  Assessed  Users    Actions  â”‚ â”‚
â”‚ â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤ â”‚
â”‚ â”‚ Justice           12            8 (67%)   3        Edit â”‚ ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ Advanced Ed       8             8 (100%)  2        Edit â”‚ ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ Finance           15            10 (67%)  4        Edit â”‚ ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ Shared Services   5             5 (100%)  2        Edit â”‚ â”€ â”‚ â”‚
â”‚ â”‚ [Default]                                                   â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ Note: Default workspace cannot be deleted                       â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Create Workspace Modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Create Workspace                       âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                             â”‚
â”‚ Workspace Name *                            â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Ministry of Health                      â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                             â”‚
â”‚ Description                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Health ministry application portfolio   â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                             â”‚
â”‚ Assign Workspace Admin (optional)           â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ jane.smith@gov.sk.ca                 â–¼  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚ Or invite new user after creating           â”‚
â”‚                                             â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐    â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Create       â”‚    â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘    â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Users Management Page (Namespace Admin Only)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Users                                           [+ Invite User] â”‚
â”‚ 11 of 20 users (Pro tier)                                       â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ User                  Org Role    Workspaces        Actions â”‚ â”‚
â”‚ â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤ â”‚
â”‚ â”‚ stuart@saskbuilds.ca  Admin       All (admin)       Edit    â”‚ â”‚
â”‚ â”‚ jane@gov.sk.ca        Member      Justice (admin)   Edit â”‚ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ bob@gov.sk.ca         Member      Justice (editor)  Edit â”‚ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ alice@gov.sk.ca       Member      Finance (admin)   Edit â”‚ðŸ—‘ï¸â”‚ â”‚
â”‚ â”‚ ...                                                         â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Invite User Modal (Namespace Admin)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Invite User                                                âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Email Address *                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ john.doe@gov.sk.ca                                          â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ Organization Role                                               â”‚
â”‚ â—‹ Member â€” Can only access assigned workspaces                  â”‚
â”‚ â—‹ Admin â€” Can manage all workspaces and users                   â”‚
â”‚                                                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                 â”‚
â”‚ Assign to Workspaces                                            â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ â˜‘ Justice                          Role: [Admin â–¼]          â”‚ â”‚
â”‚ â”‚ â˜ Advanced Education               Role: [Editor â–¼]         â”‚ â”‚
â”‚ â”‚ â˜ Finance                          Role: [Editor â–¼]         â”‚ â”‚
â”‚ â”‚ â˜ Shared Services                  Role: [Viewer â–¼]         â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ An invitation email will be sent to the user.                   â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Send Invitation      â”‚                â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Workspace Admin: Limited User Management

**Workspace Admins** (not Namespace Admins) can only invite users to **their own workspace**:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Invite User to Justice                                     âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Email Address *                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ newuser@gov.sk.ca                                           â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ Role in Justice workspace                                       â”‚
â”‚ â—‹ Admin â€” Full access, can invite others                        â”‚
â”‚ â—‹ Editor â€” Can add apps and perform assessments                 â”‚
â”‚ â—‹ Viewer â€” Read-only access                                     â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Send Invitation      â”‚                â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**What Workspace Admins CANNOT do:**
- Create new workspaces
- See other workspaces
- Invite users to other workspaces
- Change organization settings
- Access billing

---

## User Menu Updates

**For Namespace Admins:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Stuart Holtby                       â”‚
â”‚ stuart@saskbuilds.ca                â”‚
â”‚ Namespace Admin                     â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ âš™ï¸ Organization Settings             â”‚
â”‚ ðŸ‘¥ Manage Users                      â”‚
â”‚ ðŸ“ Manage Workspaces                 â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ ðŸšª Sign Out                          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**For Workspace Admins/Members:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Jane Smith                          â”‚
â”‚ jane@gov.sk.ca                      â”‚
â”‚ Justice (Admin)                     â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ âš™ï¸ Workspace Settings                â”‚
â”‚ ðŸ‘¥ Manage Users (workspace only)    â”‚  â† Only if Workspace Admin
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ ðŸšª Sign Out                          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Database: Invitation Flow

Since Supabase Auth requires users to exist before we can add them to tables, we need an invitations table:

```sql
CREATE TABLE public.invitations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  email text NOT NULL,
  namespace_role text NOT NULL DEFAULT 'member',
  invited_by uuid NOT NULL REFERENCES users(id),
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz DEFAULT (now() + interval '7 days'),
  CONSTRAINT invitations_pkey PRIMARY KEY (id),
  CONSTRAINT invitations_status_check CHECK (status IN ('pending', 'accepted', 'expired'))
);

CREATE TABLE public.invitation_workspaces (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  invitation_id uuid NOT NULL REFERENCES invitations(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'editor',
  CONSTRAINT invitation_workspaces_pkey PRIMARY KEY (id),
  CONSTRAINT invitation_workspaces_role_check CHECK (role IN ('admin', 'editor', 'viewer'))
);
```

**Invitation Flow:**
1. Admin creates invitation â†’ row in `invitations` + `invitation_workspaces`
2. Email sent to invitee with signup link (includes invitation ID)
3. Invitee clicks link â†’ goes to `/signup?invitation=xxx`
4. On signup, trigger checks for invitation:
   - If found: Add user to existing namespace + specified workspaces
   - If not found: Create new namespace (normal signup)
5. Mark invitation as 'accepted'

---

## Routes

```tsx
// Add to App.tsx routes

<Route path="/settings" element={<SettingsLayout />}>
  <Route index element={<Navigate to="/settings/workspace" />} />
  <Route path="organization" element={<OrganizationSettings />} />   {/* Namespace Admin only */}
  <Route path="workspaces" element={<WorkspacesSettings />} />       {/* Namespace Admin only */}
  <Route path="users" element={<UsersSettings />} />                 {/* Namespace Admin only */}
  <Route path="workspace" element={<WorkspaceSettings />} />         {/* All users */}
  <Route path="workspace/users" element={<WorkspaceUsersSettings />} /> {/* Workspace Admin only */}
</Route>
```

---

## Verification

After implementing:

1. **As Namespace Admin (Central IT):**
   - Can see all workspaces in dropdown
   - Can create new workspace
   - Can invite user and assign to any workspace
   - Can see "All Workspaces" aggregate view

2. **As Workspace Admin (Ministry lead):**
   - Can only see their workspace in dropdown
   - Cannot create new workspaces
   - Can invite users to their workspace only
   - Cannot see Organization Settings

3. **As Editor/Viewer:**
   - Can only see assigned workspace
   - Cannot invite users
   - Cannot access any settings except personal preferences

---

## What's NOT in This Phase

- Email sending (use Supabase Auth emails or mock for now)
- Password reset flow
- SSO/SAML (Enterprise tier feature)

---

## Next Phase

Proceed to **Phase 5: Tier Limits** to enforce workspace/user/application limits by tier.
