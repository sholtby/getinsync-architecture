# core/workspace-group.md
GetInSync Architecture Specification

Last updated: 2025-12-12

## 1. Purpose

WorkspaceGroup provides a clean, non-invasive way to support **cross-workspace reporting** and **federated catalog sharing** inside a single Namespace without weakening workspace isolation.

## 2. Design Overview

### 2.1 Key principles
1. **Workspace isolation remains absolute** for normal operations.
2. **WorkspaceGroup enables Federated Sharing** via a Publisher/Consumer model.
3. **No Namespace Overloading:** Namespace is strictly for billing/tenancy. Sharing is handled by Groups.
4. **No separate WorkspaceGroup Admin role:** Only Namespace Admins can view cross-workspace aggregated reports via WorkspaceGroup views.

## 3. Core Entities or Components

### 3.1 WorkspaceGroup

Logical grouping of Workspaces under a single Namespace.
Conceptual fields:
- WorkspaceGroupId (PK)
- NamespaceId (FK)
- Name
- Description

### 3.2 WorkspaceGroupWorkspace (The Link Table)

Join linking Workspaces to a WorkspaceGroup.
**This table controls the sharing logic.**

Conceptual fields:
- WorkspaceGroupWorkspaceId (PK)
- WorkspaceGroupId (FK)
- WorkspaceId (FK)
- **IsCatalogPublisher (Boolean, Default: False)**

**Usage:**
- **True (Publisher):** This Workspace shares its Catalog (Software, IT Services, Organizations) with the group.
- **False (Consumer):** This Workspace consumes shared data but keeps its own data private.

### 3.3 Visibility Propagation Rules

#### 3.3.1 SoftwareProduct Visibility
In a WorkspaceGroup context, a Workspace sees a SoftwareProduct if:
1. **It created it** (Local), OR
2. **The Owner Workspace is in the same Group** AND:
   - The Owner is a **Publisher** (`IsCatalogPublisher = true`), AND
   - The Product is explicitly marked as **Shared** (`IsInternalOnly = false`).

#### 3.3.2 ITService Visibility (Infrastructure Catalog)
*Critical for Centralized IT environments.*
A Workspace sees an ITService if:
1. **It created it** (Local/Private infrastructure), OR
2. **The Owner Workspace is in the same Group** AND:
   - The Owner is a **Publisher**, AND
   - The Service is explicitly marked as **Shared** (`IsInternalOnly = false`).

*Example:*
- **Central IT (Publisher):** Creates "Gov Private Cloud Hosting" (IsInternalOnly=False).
- **Justice (Consumer):** Sees "Gov Private Cloud Hosting" in the dropdown.
- **Result:** Explicit dependency tracking between Ministry Apps and Central Infrastructure.

#### 3.3.3 Organization Visibility
Organizations are **Namespace-Scoped** (see core/involved-party.md).
Within a Namespace, a Workspace sees an Organization if:
1. It created it, OR
2. A Contact in that Workspace references it, OR
3. A domain object in that Workspace references it (via SupplierOrgId, ManufacturerOrgId, etc.)

## 4. Relationships to Other Domains

### 4.1 WorkspaceGroup <-> SoftwareProduct / ITService
- **WorkspaceGroup is the Visibility Engine.**
- It allows the visibility to flow from Publisher to Consumer for both Software and Infrastructure.
- Both SoftwareProduct and ITService must have `IsInternalOnly = false` to be visible to Consumers.

### 4.2 WorkspaceGroup <-> Reporting
- **Only Namespace Admins** can view cross-workspace aggregated reports via WorkspaceGroup views.
- There is no separate "WorkspaceGroup Admin" role.

## 5. ASCII ERD (Conceptual)

```
               +-----------------------+
               |    WorkspaceGroup     |
               +-----------------------+
               | WorkspaceGroupId (PK) |
               | NamespaceId (FK)      |
               | Name                  |
               | Description           |
               +-----------+-----------+
                           |
                           | 1..*
                           v
          +------------------------------------+
          |      WorkspaceGroupWorkspace       |
          +------------------------------------+
          | WorkspaceGroupWorkspaceId (PK)     |
          | WorkspaceGroupId (FK)              |
          | WorkspaceId (FK)                   |
          | IsCatalogPublisher (Boolean)       |  <-- Controls Visibility
          +-------------------+----------------+
                              |
                              | 1..*
                              v
                      +---------------+
                      |   Workspace   |
                      +---------------+
```

```
Visibility Flow (Federated Catalog)

+-------------------------+                    +-------------------------+
|   Publisher Workspace   |                    |   Consumer Workspace    |
|  (IsCatalogPublisher=1) |                    |  (IsCatalogPublisher=0) |
+-------------------------+                    +-------------------------+
           |                                              ^
           | Owns                                         | Sees (if shared)
           v                                              |
+-------------------------+                               |
|    SoftwareProduct      |-------------------------------+
|  (IsInternalOnly=False) |  Visible via WorkspaceGroup
+-------------------------+

+-------------------------+                               |
|       ITService         |-------------------------------+
|  (IsInternalOnly=False) |  Visible via WorkspaceGroup
+-------------------------+
```

## 6. Advanced Configuration Patterns

### 6.1 The "Sidecar Group" (Limited Sharing)
**Problem:** Two Workspaces (e.g., Justice and Social Services) want to share a specific IT Service or Software Product, but they do NOT want it visible to the entire "All Ministries" group.

**Solution:** Create a specific, overlapping WorkspaceGroup.
1. Create Group: **"Justice-SS Shared"**.
2. Add **Justice** as `IsCatalogPublisher = true`.
3. Add **Social Services** as `IsCatalogPublisher = false`.

**Result:**
- Social Services sees Justice's shared catalog (via the Sidecar Group).
- Education (not in the group) sees nothing.
- *Note: A Workspace can belong to multiple groups. Visibility is additive.*

### 6.2 The "Project Cluster"
**Problem:** A temporary project involves 3 distinct ministries needing shared access to a specific dataset or tool.
**Solution:** Create a temporary WorkspaceGroup (e.g., "Project Delta"). Add all 3 workspaces. Flag the "Lead Ministry" as the Publisher. Delete the group when the project ends.

## 7. Migration Considerations

### 7.1 Configure Publishers
- Explicitly flag "Central IT" workspaces as `IsCatalogPublisher = true`.

### 7.2 IT Service consolidation
- Migrate "Shadow" IT Services (e.g., Justice manually typing "Central Hosting") to real links pointing to the Central IT service record.
- Ensure Central IT's shared services have `IsInternalOnly = false`.

### 7.3 Software Product consolidation
- Move shared products (e.g., "O365") to Publisher Workspace.
- Set `IsInternalOnly = false` on products intended for sharing.

## 8. Open Questions

- **Multiple Publishers:** Can a group have multiple publishers? (Yes).

## 9. Out of Scope

- Hosting Applications or Portfolios directly within WorkspaceGroup.
- WorkspaceGroup Admin role (only Namespace Admins can use WorkspaceGroup views).

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.6 | 2025-12-12 | Clarified that only Namespace Admins can use WorkspaceGroup views (no separate WorkspaceGroup Admin role). Added explicit note that ITService requires IsInternalOnly field. Updated Organization visibility to reference Namespace-Scoped model. |
| v1.5 | 2025-12-09 | Previous version. |

End of file.
