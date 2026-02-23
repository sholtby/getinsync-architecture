# catalogs/it-service.md
GetInSync IT Services NextGen Architecture and ServiceNow Alignment
Last updated: 2025-12-12

---

## 1. Purpose

Define how IT Services function in the GetInSync Next-Gen architecture and how they align to **ServiceNow CSDM 5**.

This version introduces:
- **Federated Visibility:** How Central IT shares infrastructure services (e.g., "Gov Private Cloud") with Ministries.
- **Stranded Cost Logic:** How to handle unallocated service costs without creating dummy Deployment Profiles.
- **IsInternalOnly Flag:** Explicit visibility control for shared services.

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
- **IsInternalOnly (Boolean, Default: TRUE)** <-- Visibility Control
- LifecycleState
- sn_service_instance_sys_id (optional CSDM mapping)

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

### 4.4 ProductContract

- Contracts fund the **Software** running on the IT Service, or the MSP managing it.
- Modeled separately in the Software Product domain.

---

## 5. ASCII ERD (Conceptual)

```
Shared Infrastructure Model

+----------------------------+       +-----------------------------+
|         ITService          | <---- |     Publisher Workspace     |
+----------------------------+       |    (Central IT)             |
| ITServiceId (PK)           |       +-----------------------------+
| WorkspaceId (FK)           | <---- OWNER
| Name                       |
| TotalAnnualCost (Pool)     |
| IsInternalOnly (Bool)      | <---- DEFAULT TRUE (Private)
+------------+---------------+
             ^
             | Visible IF (Shared Group + Publisher + !InternalOnly)
             | Linked by Consumers
             |
+------------------------------+     +-----------------------------+
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
| DeploymentProfileId (PK)   |
| WorkspaceId (FK)           |
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

## 9. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.3 | 2025-12-12 | Added IsInternalOnly field to ITService entity (was referenced in visibility rules but missing from field list). Standardized join table name to DeploymentProfileITService (was inconsistently called DeploymentProfileITServiceAllocation). |
| v1.2 | 2025-12-08 | Previous version with missing IsInternalOnly field. |

End of file.
