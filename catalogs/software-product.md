# catalogs/software-product.md
GetInSync Architecture Specification

Last updated: 2026-03-04
Version: 3.0

## 1. Purpose

This file defines the SoftwareProduct architecture for the Next-Gen GetInSync platform.
It establishes a unified software **inventory** where ownership remains **Workspace-scoped**.
Catalog sharing is managed via **WorkspaceGroups** using a **Federated Publisher/Consumer model** with explicit sharing controls.

> **v3.0 Change:** Software Products are now **inventory-only** — they track what software exists and where it's deployed, but carry no cost. All software licensing costs, vendor relationships, and contract lifecycle data live on **IT Services**. ProductContract has been merged into IT Service. See `adr-cost-model-reunification.md`.

## 2. Design Overview

### 2.1 Goals
- One authoritative inventory of software products, owned by specific Workspaces.
- Ability to share "Sanctioned" catalogs (e.g., from Central IT) without exposing local "Niche" applications.
- **Secure by Default:** Items are private unless explicitly marked for sharing.
- A consistent path for cost flow into DeploymentProfiles: `ITService → dpis → DeploymentProfile`.

### 2.2 Core Ideas
- **SoftwareProduct is Workspace-Owned.**
  - Every product is created by and belongs to a specific Workspace.
  - `WorkspaceId` is **Mandatory** (NOT NULL).

- **Visibility is Asymmetric & Explicit.**
  - **I see my own products.**
  - **I see products from Publishers** in my WorkspaceGroups **IF** they are marked as Shared.
  - **I do NOT see products from Peer Consumers.**

- **Software Products are Inventory Only (v3.0).**
  - Software Products track what software exists — not what it costs.
  - Cost flows through IT Services: **ITService → DeploymentProfileITService → DeploymentProfile**.
  - IT Services link to the Software Products they provide via `it_service_software_products`.

- **DeploymentProfile is the Cost Anchor.**
  - Cost flows: **ITService → dpis allocation → DeploymentProfile**.

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

### 3.2 ProductContract — Merged into IT Service (v3.0)

> **v3.0 Decision:** ProductContract is no longer a separate entity. Its role has been absorbed by IT Services. See `adr-cost-model-reunification.md` for the full rationale.

**IT Service as the commercial agreement:**

| ProductContract field | Now lives on |
|----------------------|-------------|
| SupplierOrgId (vendor) | `it_services.vendor_org_id` |
| TermStart / TermEnd | `it_services.contract_start_date / contract_end_date` |
| TotalCostPerBillingPeriod | `it_services.annual_cost` |
| ContractName | `it_services.name` |
| WorkspaceId | `it_services.owner_workspace_id` |

**Usage (v3.0):**
- Central IT creates an IT Service: "Microsoft 365 E5 Enterprise Agreement"
- Sets `annual_cost = $240,000`, `vendor_org_id = Microsoft`, `contract_end_date = 2027-06-30`
- Links to Software Products via `it_service_software_products` (e.g., "Microsoft 365 E5", "Microsoft Teams")
- Consumer workspaces allocate from this IT Service via `deployment_profile_it_services`
- Budget tracking, stranded cost, and contract expiry all work through existing IT Service infrastructure

### 3.3 Cost Allocation via IT Services (v3.0)

Allocates IT Service cost into DeploymentProfiles. Uses existing `deployment_profile_it_services` junction.

**Allocation modes:**
- **Fixed:** `allocation_basis = 'fixed'`, `allocation_value = $36,000` (e.g., 300 seats x $120)
- **Percent:** `allocation_basis = 'percent'`, `allocation_value = 15` (15% of the IT Service pool)

**Example (v3.0):**
- IT Service: "Microsoft 365 E5 EA" (pool: $240,000)
  - Justice DP: fixed $36,000 (300 seats)
  - Heritage DP: fixed $360 (3 seats)
  - Finance DP: percent 15% ($36,000)
  - Stranded: $24,000 (200 unallocated seats)

### 3.4 Internal Chargeback (The "IT Service" Pattern — v3.0)

To handle shared costs (e.g., Central IT pays a $240K Enterprise Agreement and charges back to Ministries), GetInSync uses the **IT Service Pattern**.

**How it works (v3.0):**
1. **The Publisher (Central IT):**
   - Creates an IT Service with the contract cost pool and vendor.
   - Links the IT Service to the Software Products it provides via `it_service_software_products`.
   - Sets `is_internal_only = false` to allow cross-workspace allocation.

2. **The Consumer (Ministry):**
   - Allocates from the shared IT Service via `deployment_profile_it_services`.
   - Their DP also links to the Software Product via `dpsp` for inventory tracking (no cost on this link).

## 4. Relationships to Other Domains

### 4.1 With BusinessApplication
BA does **not** directly reference SoftwareProduct.
Path: **BA -> DeploymentProfile -> DeploymentProfileSoftwareProduct -> SoftwareProduct**

### 4.2 With WorkspaceGroup
- **WorkspaceGroup is the Visibility Engine.**
- The `IsCatalogPublisher` flag combined with `IsInternalOnly` determines *what* is shared.

### 4.3 With IT Service (v3.0)
- IT Services provide the commercial agreement layer for Software Products.
- IT Service links to Software Products via `it_service_software_products` junction.
- IT Service cost is allocated to DPs via `deployment_profile_it_services`.
- Cross-Workspace allocation is supported when `is_internal_only = false`.
- See `catalogs/it-service.md` for full IT Service architecture.

## 5. ASCII ERD (Conceptual — v3.0)

```
Inventory + IT Service Cost Model (Secure by Default)

+-------------------------+       +-----------------------------+
|     SoftwareProduct     | <---- |     Publisher Workspace     |
+-------------------------+       |    (IsCatalogPublisher=1)   |
| SoftwareProductId (PK)  |       +-----------------------------+
| WorkspaceId (FK)        | <---- OWNER
| Name                    |
| IsInternalOnly (Bool)   | <---- DEFAULT TRUE (Private)
+-------+-------+---------+
        ^       ^
        |       | it_service_software_products (inventory link)
        |       |
        |  +----+--------------------+
        |  |        ITService        |
        |  +-------------------------+
        |  | ITServiceId (PK)        |
        |  | annual_cost (Pool)      |
        |  | vendor_org_id           |
        |  | contract_start/end_date |
        |  +------------+------------+
        |               |
        |               | deployment_profile_it_services (cost allocation)
        |               |
        |  +------------v------------+
        |  | DeploymentProfile       |
        |  +-------------------------+
        |
        | deployment_profile_software_products (inventory only — no cost)
        |
+-------+-------+---------+
|   DeploymentProfile      |
+--------------------------+
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

### 7.3 Contract Migration (v3.0)
- ProductContract has been merged into IT Service — no standalone contract entity exists.
- Existing cost/vendor/contract data on `deployment_profile_software_products` must be migrated to IT Services.
- For each dpsp with cost data: create an IT Service, set cost + vendor + contract fields, create `deployment_profile_it_services` allocation.
- See `adr-cost-model-reunification.md` §5 for the full migration path.

## 8. Open Questions

- **Write Permissions:** Can a Publisher "push" a product into a Consumer's local list? (No, pull only).
- **Versioning:** If Publisher updates O365, do Consumers see it immediately? (Yes, it's a reference).

## 9. Out of Scope

- Namespace-level data ownership (SoftwareProduct is Workspace-owned).
- Cross-Namespace sharing.

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v3.0 | 2026-03-04 | **Cost Model Reunification:** Software Products are now inventory-only — no cost fields. ProductContract merged into IT Service. Cost flows through `ITService → dpis → DeploymentProfile`. Added `it_service_software_products` junction for IT Service → Software Product link. Updated ERD, relationships, and chargeback pattern. See `adr-cost-model-reunification.md`. |
| v2.1 | 2025-12-12 | Added explicit contract allocation rules (within-workspace only, sum validation). Added DeploymentProfileContract entity documentation. Clarified terminology consistency with "Federated Catalog" model. |
| v2.0 | 2025-12-08 | Previous version. |

End of file.
