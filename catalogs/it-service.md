# catalogs/it-service.md
GetInSync IT Services NextGen Architecture and ServiceNow Alignment
Last updated: 2026-04-05
Version: 2.1

---

## 1. Purpose

Define how IT Services function in the GetInSync Next-Gen architecture and how they align to **ServiceNow CSDM 5**.

This version introduces:
- **Federated Visibility:** How Central IT shares infrastructure services (e.g., "Gov Private Cloud") with Ministries.
- **Stranded Cost Logic:** How to handle unallocated service costs without creating dummy Deployment Profiles.
- **IsInternalOnly Flag:** Explicit visibility control for shared services.

> **v2.0 Change:** IT Services now also serve as the **commercial agreement** for Software Products. Contract lifecycle fields (vendor, contract dates, renewal notice) live directly on the IT Service. The former ProductContract entity has been merged into IT Service. A new `it_service_software_products` junction links IT Services to the Software Products they provide. See `adr-cost-model-reunification.md`.

Goals:
- Replace the legacy "everything not an application goes into IT Services" pattern.
- Align to CSDM's layers: BusinessApplication -> **Application Service Instance** -> **Technology Service Instance** -> Infrastructure.
- Support **Shared Infrastructure** scenarios (Central IT Publisher / Ministry Consumer).
- Enable accurate cost recovery reporting without double-counting.

Audience: internal architects and developers.

---

## 2. Design Overview

### 2.1 Current State (Legacy)

IT Services currently contain a mixed list of OS versions, database versions, and cloud service identifiers. Visibility is often siloed or manually duplicated across workspaces.

### 2.2 Target State (NextGen)

IT Services become a **logical technology catalogue**.
They describe:
- Shared Platforms (e.g., "Central SQL Cluster 01")
- Standard Technologies (e.g., "Windows Server 2022 Standard")
- Identity Platforms (e.g., "Entra ID Tenant", "Google Workspace")

**Visibility Model:**
- IT Services are **Workspace-Owned**.
- **Publisher Workspaces** (e.g., Central IT) share their services with the Group.
- **Consumer Workspaces** (e.g., Ministries) can link to these shared services.
- Consumer Workspaces CANNOT see each other's local IT Services.

**Cost Model (Stranded Cost):**
- The IT Service holds the **Total Cost Pool** (e.g., Invoice Amount).
- DeploymentProfiles hold the **Allocated Cost** (Consumption).
- The difference is **Stranded Cost** (Overhead), borne by the Service Owner.

---

## 3. Core Entities or Components

### 3.1 ITService

Represents a logical technology capability or shared platform.

Fields:
- ITServiceId (PK)
- **WorkspaceId (FK, NOT NULL)** <-- Ownership Anchor
- Name
- Description
- ITServiceType
- **TotalAnnualCost** (The full cost of running this service, e.g., $100k)
- **VendorOrgId (FK)** <-- Who supplies this service (v2.0)
- **IsInternalOnly (Boolean, Default: TRUE)** <-- Visibility Control
- LifecycleState
- sn_service_instance_sys_id (optional CSDM mapping)

**Contract Lifecycle Fields (v2.0):**
- **contract_reference** (TEXT) — PO number, agreement ID, or contract reference
- **contract_start_date** (DATE) — When the contract term begins
- **contract_end_date** (DATE) — When the contract term expires
- **renewal_notice_days** (INTEGER, Default: 90) — Days before expiry to trigger renewal alert

**IsInternalOnly Field:**
- Controls visibility to other Workspaces in the same WorkspaceGroup.
- When **TRUE** (default): The service is private to this Workspace.
- When **FALSE**: The service is visible to Consumers in the same WorkspaceGroup (if owner is a Publisher).

**Visibility Rule:**
A Workspace sees an ITService if:
1. It created it (**Local**), OR
2. The Owner Workspace is in the same WorkspaceGroup AND:
   - The Owner is flagged as **IsCatalogPublisher = true**, AND
   - The ITService is flagged as **IsInternalOnly = false**.

### 3.2 ITServiceType

Required classification.
Values:
- PlatformService (e.g., SQL Cluster, Private Cloud)
- TechnologyProduct (e.g., Windows Server Standard)
- IdentityService (e.g., Entra ID, Google Workspace, Okta)
- IntegrationService
- EndUserPlatform

### 3.3 DeploymentProfileITService (Allocation)

Join table connecting DeploymentProfiles to ITServices.
**This is the "Recovery" mechanism.**

Fields:
- DeploymentProfileITServiceId (PK)
- DeploymentProfileId (FK)
- ITServiceId (FK)
- AllocationBasis (Percent, Units, Flat)
- **AllocationValue** (The calculated cost recovered from this specific DP)

**Note:** This table was previously referred to as "DeploymentProfileITServiceAllocation" in some documents. The canonical name is **DeploymentProfileITService** to match the naming convention of DeploymentProfileContract and DeploymentProfilePortfolio.

### 3.5 ITServiceSoftwareProduct (v2.0)

Links IT Services to the Software Products they provide. This is the inventory relationship — it answers "which software products does this IT Service cover?"

Fields:
- ITServiceSoftwareProductId (PK)
- **ITServiceId (FK)** — The IT Service providing the software
- **SoftwareProductId (FK)** — The Software Product covered
- Notes (optional)
- CreatedAt

**Constraints:**
- UNIQUE(it_service_id, software_product_id)
- RLS enabled, namespace-scoped policies
- Audit trigger

**Example:**
- IT Service: "Microsoft 365 E5 Enterprise Agreement" ($240,000)
  - → Microsoft 365 E5 (Software Product)
  - → Microsoft Teams (Software Product)
  - → Microsoft SharePoint (Software Product)

**Why this exists:** Software Products are now inventory-only (v3.0). This junction makes IT Services the funding source for software — you can see which IT Service pays for which software products, and which DPs consume that IT Service.

### 3.6 Contract Expiry View (v2.0)

The view `vw_it_service_contract_expiry` provides contract lifecycle tracking across all IT Services with contract dates.

**Status buckets:**
| Status | Logic |
|--------|-------|
| `expired` | `contract_end_date < CURRENT_DATE` |
| `renewal_due` | Within `renewal_notice_days` of end date |
| `expiring_soon` | Within 90 days of end date (but not yet in renewal window) |
| `active` | Contract end date is in the future |
| `no_contract` | No contract dates set |

**Key columns:** it_service_id, name, vendor_name, contract_end_date, renewal_notice_days, days_until_expiry, status

### 3.4 Cost Reconciliation Logic (The "Stranded Cost" Pattern)

To avoid double-counting and dummy records:

1. **Total Pool:** Defined on `ITService.TotalAnnualCost`. (e.g., $100k).
2. **Recovered Cost:** Sum of `AllocationValue` across all linked DeploymentProfiles.
   - Justice DP: $10k
   - Education DP: $20k
   - **Total Recovered:** $30k
3. **Stranded Cost (Overhead):**
   - `Stranded = TotalPool - RecoveredCost`
   - Result: $70k.
   - *This amount is reported as "Unallocated Overhead" against the Central IT Workspace.*

**Rule:** Do NOT create a "Dummy Deployment Profile" to hold the $70k. The system calculates it automatically.

---

## 4. Relationships to Other Domains

### 4.1 BusinessApplication

No direct link.
Path: BusinessApplication -> DeploymentProfile -> ITService.

### 4.2 DeploymentProfile

- DeploymentProfile represents the **Consumer**.
- ITService represents the **Provider** (or technical dependency).
- Links cross workspace boundaries when consuming Shared Services (e.g., Justice DP links to Central IT Service).

### 4.3 WorkspaceGroup

- **WorkspaceGroup is the Visibility Engine.**
- The `IsCatalogPublisher` flag on WorkspaceGroupWorkspace determines if an IT Service is visible to other workspaces in the group.
- The `IsInternalOnly` flag on ITService determines if a specific service is shared.

### 4.4 SoftwareProduct (v2.0)

- IT Services are now the **funding source** for Software Products.
- The `it_service_software_products` junction links an IT Service to the Software Products it covers.
- Software Products are inventory-only — they carry no cost. Cost lives on the IT Service.
- See `catalogs/software-product.md` for the Software Product architecture.

---

## 5. ASCII ERD (Conceptual — v2.0)

```
IT Service as Infrastructure Provider + Software Contract (v2.0)

+----------------------------+       +-----------------------------+
|         ITService          | <---- |     Publisher Workspace     |
+----------------------------+       |    (Central IT)             |
| ITServiceId (PK)           |       +-----------------------------+
| WorkspaceId (FK)           | <---- OWNER
| Name                       |
| TotalAnnualCost (Pool)     |
| VendorOrgId (FK)           | <---- Who supplies this
| contract_reference         |
| contract_start/end_date    | <---- Contract lifecycle (v2.0)
| renewal_notice_days        |
| IsInternalOnly (Bool)      | <---- DEFAULT TRUE (Private)
+------+----------+----------+
       |          |
       |          | it_service_software_products (v2.0)
       |          |
       |   +------v-----------------------+
       |   | ITServiceSoftwareProduct     |
       |   +------------------------------+
       |   | ITServiceId (FK)             |
       |   | SoftwareProductId (FK)       |
       |   +------+-----------------------+
       |          |
       |          v
       |   +------------------------------+
       |   |      SoftwareProduct         |
       |   +------------------------------+
       |   | (Inventory only — no cost)   |
       |   +------------------------------+
       |
       | deployment_profile_it_services (cost allocation)
       |
+------v-----------------------+     +-----------------------------+
|   DeploymentProfileITService | <---|     Consumer Workspace      |
+------------------------------+     |    (Ministry of Justice)    |
| DeploymentProfileITServiceId |     +-----------------------------+
| DeploymentProfileId (FK)     |
| ITServiceId (FK)             |
| AllocationBasis              |
| AllocationValue (Recovered)  |
+------------+-----------------+
             |
             v
+----------------------------+
|     DeploymentProfile      |
+----------------------------+
```

## 6. Migration Considerations

### 6.1 Consolidate Shared Services
- Identify "Shadow" IT Services (e.g., Justice manually typing "Central Hosting").
- Create authoritative IT Services in the **Central IT** workspace.
- Flag Central IT as a **Publisher** in the WorkspaceGroup.
- **Critical:** Set `IsInternalOnly = false` on services intended for sharing.
- Remap local DPs to point to the shared Central IT Service.

### 6.2 Cost Data Cleanup
- Move total operating costs to `ITService.TotalAnnualCost` in the Publisher workspace.
- Delete any "Dummy DPs" previously used to hold overhead costs.
- Allow the "Stranded Cost" report to highlight unallocated amounts initially.

## 7. Open Questions or Follow-Up Work

- **Unit Pricing:** Should ITService support "Cost Per Unit" (e.g., $50/VM) to auto-calculate allocations? (v2 Feature).
- **ServiceNow Sync:** Map Shared IT Services to **Technical Service Offerings** in CSDM.

## 8. Out of Scope

- Automated ingestion of cloud bills (FinOps).
- Real-time capacity monitoring.
- Incident/Change management integration.

## 9. Technology Composition Display

The IT Service Catalog UI shows the technology products that compose each service. Below each IT Service row, teal "Built on:" chips display the technology product names fetched from the `it_service_technology_products` junction table.

**Data source:** `it_service_technology_products` joined to `technology_products` for display names.

**UI behavior:**
- Chips render inline below the service name
- Chip color: teal background
- Label prefix: "Built on:"
- Only shown when the service has linked technology products

---

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.1 | 2026-04-05 | Added §9 Technology Composition Display — teal "Built on:" chips showing technology products per IT Service via `it_service_technology_products`. |
| v2.0 | 2026-03-04 | **Cost Model Reunification:** IT Services now serve as the commercial agreement for Software Products. Added 4 contract lifecycle fields (`contract_reference`, `contract_start_date`, `contract_end_date`, `renewal_notice_days`). Added `vendor_org_id` field. Added `it_service_software_products` junction table. Added `vw_it_service_contract_expiry` view. Updated ERD and relationship to SoftwareProduct. See `adr-cost-model-reunification.md`. |
| v1.3 | 2025-12-12 | Added IsInternalOnly field to ITService entity (was referenced in visibility rules but missing from field list). Standardized join table name to DeploymentProfileITService (was inconsistently called DeploymentProfileITServiceAllocation). |
| v1.2 | 2025-12-08 | Previous version with missing IsInternalOnly field. |

End of file.
