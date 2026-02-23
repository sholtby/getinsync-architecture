# features/integrations/servicenow-alignment.md
GetInSync ServiceNow Alignment Architecture
Last updated: 2025-12-12

---

## 1. Purpose

This file defines how the GetInSync Next-Gen architecture aligns with ServiceNow's CSDM 5 and related domains (APM, ITSM, ITAM, SPM).

This version introduces **Federated Catalog Alignment**:
- How **Shared IT Services** (Publisher) map to **Technical Service Offerings** (TSO).
- How **Consumer Deployment Profiles** create CSDM-compliant dependencies on those Offerings.
- How **Internal Contracts** (Chargeback) are handled to avoid polluting the legal Contract repository.

Audience: internal architects and developers.

---

## 2. Design Overview

### 2.1 Alignment Strategy

GetInSync operates as the "Planning & Curation" workspace sitting upstream of ServiceNow.
- **GetInSync:** Manages the logical architecture, internal chargeback, and federated visibility.
- **ServiceNow:** Manages the operational CMDB, legal contracts (SAM), and incident flows.

### 2.2 The "Publisher" Pattern in CSDM

The GetInSync "Publisher/Consumer" model maps cleanly to the CSDM "Provider/Consumer" relationship:
- **Publisher (Central IT):** Owns the **Technical Service Offering** (TSO).
- **Consumer (Ministry):** Owns the **Application Service** (App Service) that consumes the TSO.

---

## 3. Core Entities or Components

### 3.1 BusinessApplication -> cmdb_ci_business_app

**Upstream Source:** GetInSync `BusinessApplication`.
**Downstream Target:** ServiceNow `cmdb_ci_business_app`.

Mapping:
- Name -> name
- Description -> description
- Portfolio tagging -> capability references or custom fields
- Lifecycle -> operational_status / lifecycle_stage

### 3.2 DeploymentProfile -> Application Service / Technical Service

**Upstream Source:** GetInSync `DeploymentProfile`.
**Downstream Target:** Depends on `ServiceNowSyncScope` setting.

**ServiceNowSyncScope Values:**
| Scope Value | ServiceNow Target | Use Case |
|-------------|-------------------|----------|
| None | (No sync) | DP not synced to ServiceNow |
| ApplicationService | `cmdb_ci_service_auto` | DPs linked to BusinessApplications |
| TechnicalService | `cmdb_ci_service_technical` | Private infrastructure DPs |
| TechnicalServiceOffering | `service_offering` | Shared/published infrastructure (Publisher scenario) |

Mapping (ApplicationService):
- DeploymentProfileId -> correlation_id / sys_id
- Name -> name (e.g., "Sage 300 - Justice - Prod")
- Environment -> environment
- BusinessApplicationId -> 'Consumed by' Business Application relationship

### 3.3 ITService (Infrastructure) -> Technical Service / Technical Service Offering

*Critical Update for Shared Services.*

**Scenario A: Shared Service (Publisher)**
- **GetInSync:** `ITService` (Owned by Central IT, `IsCatalogPublisher=True` on WorkspaceGroupWorkspace, `IsInternalOnly=False` on ITService).
- **ServiceNow:** **Technical Service Offering** (`service_offering` table, classification=Technical).
- *Example:* "Gov Private Cloud - Gold Tier".
- **Sync Scope:** Use `TechnicalServiceOffering`.

**Scenario B: Local Service (Private)**
- **GetInSync:** `ITService` (Owned by Justice, `IsInternalOnly=True` or not in a Publisher Workspace).
- **ServiceNow:** **Technical Service** (`cmdb_ci_service_technical`) OR **Dynamic CI Group** (if mapping to specific CIs).
- **Sync Scope:** Use `TechnicalService`.

**Relationship Mapping:**
- When a Justice DP links to a Central IT Service in GetInSync...
- ...Sync creates a `Depends on::Used by` relationship between the **Application Service** (Justice) and the **Technical Service Offering** (Central IT).

### 3.4 SoftwareProduct -> Software Model

**Upstream Source:** GetInSync `SoftwareProduct`.
**Downstream Target:** ServiceNow `alm_product_model` (Software Model).

Notes:
- Central IT "Shared" products (IsInternalOnly=False) map to global Models.
- Local products map to models with Model Categories restricting visibility (if SN config allows) or simply exist as global models used only by specific assets.

### 3.5 ProductContract -> Contract

**Scenario A: External Vendor Contract (Real Legal Paper)**
- **GetInSync:** `ProductContract` (Supplier = Microsoft).
- **ServiceNow:** `ast_contract` (Contract Management).
- *Sync Rule:* **SYNC ENABLED.**

**Scenario B: Internal Chargeback Contract (Ministry pays Central IT)**
- **GetInSync:** `ProductContract` (Supplier = Central IT).
- **ServiceNow:** **DO NOT SYNC** to `ast_contract`.
- *Reason:* These are not legal entities. Syncing them pollutes the legal repository used by SAM/Legal teams.
- *Alternative:* Sync to a custom "Internal Chargeback" table if ServiceNow financial modeling is used.

---

## 4. ASCII ERD (Conceptual Mapping)

```
GetInSync Domain                        ServiceNow CSDM 5.0
================                        ===================

[BusinessApplication] ----------------> [Business Application]
       |                                         ^
       | (Owns)                                  | (Consumes)
       v                                         |
[DeploymentProfile] ------------------> [Application Service]
       |                                 (SyncScope=ApplicationService)
       |
       | Link (Consumer -> Publisher)
       v
[ITService (Shared)] -----------------> [Technical Service Offering]
  (IsInternalOnly=False)                 (SyncScope=TechnicalServiceOffering)
       |
       | Contains
       v
[ITService (Private)] ----------------> [Technical Service]
  (IsInternalOnly=True)                  (SyncScope=TechnicalService)
                                                 |
                                                 | Contains
                                                 v
                                        [Infrastructure CIs]
                                        (Servers, DBs - Managed by Discovery)
```

```
Contract Logic:

[Ext. Contract] ----------------------> [ast_contract]
  (Supplier = External Vendor)           (SYNC ENABLED)

[Int. Contract] --X (No Sync) X------> [ (Keep in GIS) ]
  (Supplier = Central IT)                (Internal Chargeback only)
```

## 5. Migration Considerations

### 5.1 Service Stub Creation
- For every Shared `ITService` in GetInSync (IsInternalOnly=False, Publisher Workspace), ensure a corresponding **Technical Service Offering** exists in ServiceNow.
- Store the SN `sys_id` on the GetInSync `ITService` record to maintain the link.

### 5.2 Relationship Building
- The sync engine must iterate through `DeploymentProfileITService` records.
- For each link, verify if the downstream object is a TSO.
- Create the `cmdb_rel_ci` record (`Used by` :: `Depends on`).

### 5.3 Sync Scope Configuration
- Review all DeploymentProfiles and set appropriate `ServiceNowSyncScope` values.
- Use `TechnicalServiceOffering` for shared infrastructure.
- Use `TechnicalService` for private infrastructure.

## 6. Open Questions

- **Directionality:** Should GetInSync push relationships, or should ServiceNow Discovery push relationships back to GetInSync?
  - *Recommendation:* GetInSync pushes the **Logical Dependency** (Intent). Discovery pushes the **Physical Dependency** (Reality).
- **TSO Granularity:** Does Central IT have TSOs defined (Gold/Silver)? If not, they may map to a parent **Technical Service**.

## 7. Out of Scope

- Syncing raw Infrastructure CIs (Servers, Switches) into GetInSync.
- Incident Management integration.

## 8. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.2 | 2025-12-12 | Added TechnicalServiceOffering to ServiceNowSyncScope documentation. Clarified mapping between IsInternalOnly flag and sync scope selection. Added sync scope configuration guidance. |
| v1.1 | 2025-12-08 | Previous version with incomplete sync scope documentation. |

End of file.
