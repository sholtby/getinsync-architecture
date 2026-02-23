# catalogs/software-product.md
GetInSync Architecture Specification

Last updated: 2025-12-12

## 1. Purpose

This file defines the SoftwareProduct and ProductContract architecture for the Next-Gen GetInSync platform.
It establishes a unified software inventory and contract model where ownership remains **Workspace-scoped**.
Catalog sharing is managed via **WorkspaceGroups** using a **Federated Publisher/Consumer model** with explicit sharing controls.

## 2. Design Overview

### 2.1 Goals
- One authoritative inventory of software products, owned by specific Workspaces.
- Ability to share "Sanctioned" catalogs (e.g., from Central IT) without exposing local "Niche" applications.
- **Secure by Default:** Items are private unless explicitly marked for sharing.
- A consistent path for cost flow into DeploymentProfiles: `Contract -> DeploymentProfile`.

### 2.2 Core Ideas
- **SoftwareProduct is Workspace-Owned.**
  - Every product is created by and belongs to a specific Workspace.
  - `WorkspaceId` is **Mandatory** (NOT NULL).

- **Visibility is Asymmetric & Explicit.**
  - **I see my own products.**
  - **I see products from Publishers** in my WorkspaceGroups **IF** they are marked as Shared.
  - **I do NOT see products from Peer Consumers.**

- **ProductContract is Private.**
  - Contracts are strictly local to the Workspace that pays for them.
  - A Consumer Workspace links its Local Contract to a Publisher's Shared Product.

- **DeploymentProfile is the Cost Anchor.**
  - Cost flows: **ProductContract -> DeploymentProfileContract -> DeploymentProfile**.

## 3. Core Entities or Components

### 3.1 SoftwareProduct

Represents a logical product family or SKU.

Key fields:
- SoftwareProductId (PK)
- **WorkspaceId (FK, NOT NULL)** <-- OWNERSHIP ANCHOR
- Name
- ProductFamilyName (optional)
- Category (Suite, SaaS, Platform, Plugin, ManagedService, Other)
- ManufacturerOrgId (FK)
- **IsInternalOnly (Boolean, Default: TRUE)** <-- THE SAFETY VALVE
- IsDeprecated (boolean)

**Visibility Rule (The Anti-Pollution Logic):**
A User in Workspace A can see/select a SoftwareProduct if:
1. The Product.WorkspaceId == Workspace A (**Local**), OR
2. The Product is owned by Workspace B, AND:
   - Workspace A and B share a **WorkspaceGroup**, AND
   - Workspace B is flagged as **`IsCatalogPublisher = true`** in that group, AND
   - The Product is flagged as **`IsInternalOnly = false`**.

### 3.2 ProductContract (Local Liability)

Represents the commercial agreement. Strictly local.

Key fields:
- ProductContractId (PK)
- **WorkspaceId (FK)**
- SoftwareProductId (FK) <-- Can point to Local or Publisher Product
- ContractName
- SupplierOrgId (FK)
- TermStart / TermEnd
- TotalCostPerBillingPeriod

**Usage:**
- Ministry of Justice (Consumer) creates a contract.
- They link it to "Microsoft Office 365" (Owned by Central IT Publisher).
- The cost remains in Justice's budget.
- The inventory report for Central IT shows Justice is a consumer.

### 3.3 DeploymentProfileContract (Cost Allocation)

Allocates ProductContract cost into DeploymentProfiles.

Key fields:
- DeploymentProfileContractId (PK)
- DeploymentProfileId (FK)
- ProductContractId (FK)
- AllocationPercent (0-100)

**Allocation Rules:**
- Sum of AllocationPercent for a given ProductContractId should not exceed 100% (warning) or 105% (error).
- A single ProductContract may be allocated to multiple DeploymentProfiles **WITHIN THE SAME WORKSPACE**.
- **Cross-Workspace allocation is prohibited** - Consumers must create their own local Contracts.

**Example (Valid Within-Workspace Split):**
- "O365 Enterprise Agreement" Contract ($100k):
  - 70% allocated to Corporate DP ($70k)
  - 30% allocated to Operations DP ($30k)

### 3.4 Internal Chargeback (The "Internal Vendor" Pattern)

To handle shared costs (e.g., Central IT pays a $1M Enterprise Agreement and charges back to Ministries), GetInSync uses the **Internal Vendor Pattern**.

**The Rule:** Do NOT distribute a single "Central Deployment Profile" to multiple workspaces.
**The Fix:** Distribute the **Vendor**.

**How it works:**
1. **The Publisher (Central IT):**
   - Pays the real external contract.
   - Creates a Group-visible `Organization` representing themselves (e.g., "Government Central IT").
   - Publishes the shared `SoftwareProduct` (IsInternalOnly = False).

2. **The Consumer (Ministry):**
   - Creates a local `ProductContract`.
   - Sets `SupplierOrgId` = "Government Central IT".
   - Links to the shared `SoftwareProduct`.
   - Allocates this local contract to their local DeploymentProfiles.

## 4. Relationships to Other Domains

### 4.1 With BusinessApplication
BA does **not** directly reference SoftwareProduct.
Path: **BA -> DeploymentProfile -> DeploymentProfileSoftwareProduct -> SoftwareProduct**

### 4.2 With WorkspaceGroup
- **WorkspaceGroup is the Visibility Engine.**
- The `IsCatalogPublisher` flag combined with `IsInternalOnly` determines *what* is shared.

### 4.3 With ProductContract
- ProductContract references SoftwareProduct (Local or Shared).
- ProductContract allocates cost to DPs via DeploymentProfileContract.
- Cross-Workspace allocation is prohibited.

## 5. ASCII ERD (Conceptual)

```
Publisher-Consumer Catalog Model (Secure by Default)

+-------------------------+       +-----------------------------+
|     SoftwareProduct     | <---- |     Publisher Workspace     |
+-------------------------+       |    (IsCatalogPublisher=1)   |
| SoftwareProductId (PK)  |       +-----------------------------+
| WorkspaceId (FK)        | <---- OWNER
| Name                    |
| IsInternalOnly (Bool)   | <---- DEFAULT TRUE (Private)
+------------+------------+
             ^
             | Visible IF (Shared Group + Publisher + !InternalOnly)
             |
+-------------------------+       +-----------------------------+
|     ProductContract     | <---- |     Consumer Workspace      |
+-------------------------+       |    (IsCatalogPublisher=0)   |
| ProductContractId (PK)  |       +-----------------------------+
| WorkspaceId (FK)        |
| SoftwareProductId (FK)  |
+------------+------------+
             |
             | Allocates via DeploymentProfileContract
             | (Within-Workspace only)
             v
+------------------------------+
|      DeploymentProfile       |
+------------------------------+
```

## 6. Worked Example - Preventing Pollution

**Scenario:**
- **Group:** "Justice-SS Shared"
- **Workspace A (Justice):** Flagged as **Publisher**.
    - Creates "CaseLink Pro" (`IsInternalOnly = False`).
    - Creates "MyCrappyApp" (`IsInternalOnly = True`).
- **Workspace B (Social Services):** Flagged as **Consumer**.

**The Result:**
- **Social Services** sees "CaseLink Pro".
- **Social Services** does *not* see "MyCrappyApp" (The Internal flag screens it out).

## 7. Migration Considerations

### 7.1 "Catalog Workspace" Strategy
- Create a dedicated Workspace (e.g., "Global Catalog" or "Central IT").
- Add this Workspace to all relevant WorkspaceGroups with `IsCatalogPublisher = true`.

### 7.2 Data Cleanup
- Move "O365" to Central IT.
- **Critical:** Explicitly set `IsInternalOnly = False` for these global records during migration, or no one will see them.

### 7.3 Contract Migration
- Ensure all ProductContracts have proper WorkspaceId set.
- Verify no contracts are attempting cross-Workspace allocation.

## 8. Open Questions

- **Write Permissions:** Can a Publisher "push" a product into a Consumer's local list? (No, pull only).
- **Versioning:** If Publisher updates O365, do Consumers see it immediately? (Yes, it's a reference).

## 9. Out of Scope

- Namespace-level data ownership (SoftwareProduct is Workspace-owned).
- Cross-Namespace sharing.

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.1 | 2025-12-12 | Added explicit contract allocation rules (within-workspace only, sum validation). Added DeploymentProfileContract entity documentation. Clarified terminology consistency with "Federated Catalog" model. |
| v2.0 | 2025-12-08 | Previous version. |

End of file.
