# catalogs/business-application.md
GetInSync Business Application Architecture
Last updated: 2025-12-12

---

## 1. Purpose

This file defines the BusinessApplication object in the GetInSync Next-Gen architecture.
It explains the role of BusinessApplication as the central APM entity, how it relates to Deployment Profiles, IT Services, Software Products, ProductContracts, and the Involved Party model.
Audience: internal architects and developers.

---

## 2. Design Overview

### 2.1 Role of BusinessApplication

BusinessApplication is the primary APM anchor in GetInSync.
It represents a business-facing application used by one or more organizational units.
It is:

- the starting point for TIME and PAID assessments
- the owner of portfolio classification
- the container of business context
- the parent of Deployment Profiles
- the aggregator of cost (rolled up from Deployment Profiles and Product Contracts)

It is **not** a technical asset, CI, service, or deployment artifact.

### 2.2 Problems Solved

- Separates business applications from technical noise.
- Eliminates mixing of business and technical apps from ServiceNow `cmdb_ci_appl`.
- Creates a stable object for ownership, lifecycle, and portfolio planning.
- Moves technical configuration fields (environment, hosting) to Deployment Profiles.
- Allows clean mapping to CSDM's `cmdb_ci_business_app`.

### 2.3 BusinessApplication in the Next-Gen Shape

BusinessApplication sits at the top of this hierarchy:

BusinessApplication -> DeploymentProfile -> ITService

This aligns with CSDM's separation between an application and its deployed form.

---

## 3. Core Entities or Components

### 3.1 BusinessApplication

Fields (conceptual):

- BusinessApplicationId (PK)
- Name
- Description
- PrimaryUseCase
- Portfolio and APQC tags
- LifecycleState (Proposed, Active, SunsetPlanned, Retired)
- Dates (start, end, retirement)
- OwnerContactId (through ApplicationContact)
- SMEContactIds (through ApplicationContact)

Notes:
- One BusinessApplication may have multiple DeploymentProfiles.
- BusinessApplication does not contain cost directly.
- BusinessApplication does not hold environment or hosting information.

---

### 3.2 ApplicationContact

Links Contacts to BusinessApplications.

Fields:
- ApplicationContactId (PK)
- ApplicationId
- ContactId
- RoleType (Owner, SME, Coordinator)

Notes:
- A BusinessApplication may have multiple Contacts with different roles.
- **Identity Link:** `ContactId` refers to a **Workspace-scoped Contact**.
  - That Contact is linked to a **Platform-scoped Individual** (where the Entra ID OID lives).
  - This ensures that "Stuart (Global)" can be the Owner in Workspace A and a Vendor Contact in Workspace B without duplicating identity data.

---

### 3.3 ApplicationProductContract (future optional)

A join table linking BusinessApplications to ProductContracts.

Fields:
- ApplicationProductContractId (PK)
- ProductContractId
- ApplicationId
- Allocation rules (optional)

Notes:
- Not required if ProductContract allocations are handled at the portfolio or global level.

---

## 4. Relationships to Other Domains

### 4.1 Deployment Profiles

Each BusinessApplication may have one or more DeploymentProfiles.
DeploymentProfiles hold:
- environment
- hosting model
- region
- estimated annual cost (ADDITIVE to Contract and ITService allocations)
- ITService stack

BusinessApplication rolls up cost from all DeploymentProfiles.

### 4.2 IT Services

Indirect relationship:

BusinessApplication -> DeploymentProfiles -> ITServices

A BusinessApplication does not directly reference IT Services.

### 4.3 Software Products

A BusinessApplication may be backed by one or more SoftwareProducts through ProductContracts.
Indirect path:

BusinessApplication -> ProductContract -> SoftwareProduct

Manufacturer links through SoftwareProduct.

SoftwareProduct is **Workspace-Owned** with visibility controlled via **Federated Catalog** (WorkspaceGroups).

### 4.4 Product Contracts

ProductContracts provide:
- licence and vendor support cost
- renewal and notice dates
- vendor organization
- contract owner and vendor reps

BusinessApplication sees only aggregated cost.

**Allocation Rule:** A single ProductContract may be allocated to multiple DeploymentProfiles **within the same Workspace**. Cross-Workspace allocation is prohibited.

### 4.5 Involved Party Layer

BusinessApplication's Contacts and vendors rely on:

- Organization for vendor or manufacturer (Namespace-Scoped)
- Individual and Contact for ownership roles (Individual is Platform-Scoped, Contact is Workspace-Scoped)

This provides clear:

Application -> Vendor -> People
Application -> Owner/SME (Contact -> Individual)

---

## 5. ASCII ERD (Conceptual)

```
+----------------------------+
|    BusinessApplication     |
+----------------------------+
| BusinessApplicationId (PK) |
| Name                       |
| Description                |
| Portfolio                  |
| LifecycleState             |
+-------------+--------------+
              |
              | roles via contacts
              v
+----------------------------+
|     ApplicationContact     |
+----------------------------+
| ApplicationContactId (PK)  |
| ApplicationId (FK)         |
| ContactId (FK)             |
| RoleType                   |
+-------------+--------------+
              |
              v
+----------------------------+       +-------------------------+
|          Contact           | ----> |       Individual        |
+----------------------------+       +-------------------------+
| ContactId (PK)             |       | IndividualId (PK)       |
| WorkspaceId (FK)           |       | ExternalIdentityKey     | (Entra ID OID)
| IndividualId (FK)          |       | PrimaryEmail            |
+----------------------------+       +-------------------------+
  (Workspace-Scoped)                   (Platform-Scoped)
```

```
Deployment structure:

+----------------------------+
|     BusinessApplication    |
+----------------------------+
              |
              | 1-to-many
              v
+----------------------------+
|      DeploymentProfile     |
+----------------------------+
| DeploymentProfileId (PK)   |
| BusinessApplicationId (FK) |
| Environment                |
| Region                     |
| HostingModel               |
| EstimatedAnnualCost        |
+-------------+--------------+
              |
              | many-to-many
              v
+------------------------------+
|   DeploymentProfileITService |
+------------------------------+
| DeploymentProfileITServiceId |
| DeploymentProfileId          |
| ITServiceId                  |
| AllocationBasis              |
| AllocationValue              |
+------------------------------+
```

## 6. Migration Considerations

### 6.1 Move environment/hosting to DeploymentProfile
- Identify all environment, region, and hosting fields currently on the BusinessApplication.
- Create one default DeploymentProfile per environment detected in legacy data.
- Move technical configuration fields to the new DeploymentProfiles.

### 6.2 Convert Cost
- Convert legacy cost ranges/text to `DeploymentProfile.EstimatedAnnualCost`.
- Note: EstimatedAnnualCost is ADDITIVE to Contract and ITService allocations.

### 6.3 Normalize Application Ownership (Identity Migration)
To preserve Entra ID compatibility, legacy user fields (e.g., `owned_by` text or `sys_user` refs) must be migrated in three steps:

1. **Resolve Individual (Platform-Scoped):**
   - Extract the email from the legacy owner field.
   - Lookup or create an `Individual` record with that email.
   - (If `sys_user` OID is known, populate `Individual.ExternalIdentityKey`).

2. **Resolve Contact (Workspace-Scoped):**
   - Ensure a `Contact` record exists for that `Individual` in the current Workspace.

3. **Link Application:**
   - Create an `ApplicationContact` record linking the `BusinessApplication` to the `Contact`.
   - Set `RoleType = Owner`.

### 6.4 Clean up Vendors
- Replace legacy vendor/manufacturer dropdown strings with references to the `Organization` table.
- Note: Organization is Namespace-Scoped.

## 7. Open Questions or Follow-Up Work

- Should applications support parent/child hierarchy (Application Suite)?
- Should BusinessCapabilities become a relationship modeled here?
- Do we allow multiple owner roles or enforce one primary owner?

## 8. Out of Scope

- RBAC and permission decisions.
- SNOW sync mechanics.
- Detailed cost engine design.
- Project-level linking.

## 9. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.2 | 2025-12-12 | Clarified scoping terminology (Individual is Platform-Scoped, Contact is Workspace-Scoped, Organization is Namespace-Scoped). Added note that EstimatedAnnualCost is ADDITIVE. Added contract allocation rule (within-Workspace only). Standardized table name to DeploymentProfileITService. |
| v1.1 | 2025-12-08 | Previous version. |

End of file.
