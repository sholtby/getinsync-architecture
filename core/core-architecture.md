# core/core-architecture.md
GetInSync Architecture Specification

Last updated: 2025-12-12

## 1. Purpose

This file defines the core conceptual architecture for NextGen GetInSync.
It describes:

- The central role of BusinessApplications
- How DeploymentProfiles, ITServices, SoftwareProducts, ProductContracts, and Portfolios work together
- The Involved Party model at a high level
- How Namespaces, Workspaces, and WorkspaceGroups structure tenant and reporting views

Detailed fields and behaviours live in domain specific Skills files.

## 2. Design Overview

### 2.1 Goals

- Make BusinessApplication the centre of APM
- Separate application intent from runtime deployment and cost
- Treat ITServices as logical technical capabilities rather than individual CIs
- Treat SoftwareProduct and ProductContract as the home of licences and commercial agreements
- Use DeploymentProfile as the runtime and cost anchor
- Use Portfolios for organisational and TIME / PAID views
- Use Involved Party for Organizations, Individuals, Contacts, and their relationships
- Use WorkspaceGroup for cross workspace reporting without changing isolation

### 2.2 Core ideas

- BusinessApplication is the anchor for APM, TIME, PAID, APQC, and ownership.
- DeploymentProfile represents a specific deployment context or cost bundle.
- ITService represents logical technical capabilities that support DeploymentProfiles.
- SoftwareProduct is **Workspace-Owned** with **Federated Catalog** visibility via WorkspaceGroups.
- ProductContract represents the **Local** commercial agreement.
- Costs flow into DeploymentProfiles, then into Portfolios.
- Integrations model data flows between internal applications and external entities.
- Namespace and Workspace define a multi-tenant structure.
- WorkspaceGroup provides an enterprise-level reporting lens across multiple Workspaces inside a Namespace.

## 3. Core Entities or Components

### 3.1 Platform structure

Conceptual only. Physical details live in core platform Skills.

- Namespace
  - Top-level tenant container.
  - **Hard Isolation Boundary:** Workspaces in different Namespaces share nothing (no Catalog, no Identity).
  - A Namespace does NOT own a catalog; visibility is controlled through WorkspaceGroups.

- Workspace
  - Logical work area inside a Namespace.
  - Typical pattern: one Workspace per ministry or per portfolio company.
  - Owns Portfolios, BusinessApplications, DeploymentProfiles, SoftwareProducts, ITServices, Contracts, and Costs.

- WorkspaceGroup
  - Reporting and sharing construct.
  - Groups multiple Workspaces in the same Namespace for cross-workspace reporting.
  - Enables **Federated Catalog** visibility via Publisher/Consumer model.
  - Does not own data; it points at existing Workspaces.

### 3.2 BusinessApplication

- Conceptual business system such as Sage 300 Justice, Workday HCM, Online Ordering.
- Portfolio scoped via PortfolioBusinessApplication mapping.
- Holds high-level fields:
  - Name, Description
  - Business owner and sponsor (high level, not operational)
  - APQC classification
  - Lifecycle and risk summary
- **No direct cost fields.**
- Connects to DeploymentProfiles for runtime and cost.

The detailed schema is in the catalogs/business-application.md.

### 3.3 DeploymentProfile

- Represents one deployment context or cost bundle.
- Examples:
  - Sage 300 Justice Prod
  - Online Ordering Prod Oregon
  - O365 Org Wide
- Key behaviours:
  - Holds environment and hosting attributes.
  - Links to ITServices that provide runtime capabilities.
  - Links to SoftwareProducts via DeploymentProfileSoftwareProduct.
  - Receives cost from ProductContracts via DeploymentProfileContract.
  - Allocates cost into Portfolios via DeploymentProfilePortfolio.
  - Carries EstimatedAnnualCost for legacy or approximate costs.
  - May or may not reference a BusinessApplication.

Detailed schema is in core/deployment-profile.md.

### 3.4 ITService

- Logical technical capability that supports DeploymentProfiles.
- Examples:
  - AWS EC2 Windows Server platform
  - SQL Server database platform
  - Network firewall service
  - Endpoint management service
- Stores runtime cost and lifecycle state.
- Attached to DeploymentProfiles via DeploymentProfileITService.

Detailed schema is in catalogs/it-service.md.

### 3.5 SoftwareProduct (Federated Catalog)

- **Workspace-Owned:** Every SoftwareProduct is created by and belongs to a specific Workspace.
- **WorkspaceId is Mandatory** (NOT NULL).
- Visibility is controlled via WorkspaceGroups using a **Federated Publisher/Consumer** model.
- Includes:
  - Platforms: WordPress, Excel, PowerApps, SharePoint
  - SaaS: Canva, DocuSign, Monday.com, Shopify, PowerBI
  - Suites: O365 E3, Adobe Creative Cloud
  - Managed services: Managed Sage 300 Service MSP X
- Supports "Define Once, Use Everywhere" for common tools (e.g., O365) via Publisher visibility.

Detailed schema is in catalogs/software-product.md.

### 3.6 ProductContract (Local Commercial)

- **Workspace-Scoped:** Represents a specific commercial agreement or subscription.
- Stores:
  - Supplier and manufacturer Organisations
  - Term, renewal, billing frequency
  - Cost per billing period
  - Seats purchased if known
- **Directly allocates cost into DeploymentProfiles** using DeploymentProfileContract.

Detailed schema is in catalogs/software-product.md.

### 3.7 Portfolio

- Hierarchical organisational container. Up to five levels deep.
- Typical pattern:
  - Enterprise
  - Ministry or business unit
  - Division
  - Branch
  - Team or program
- Holds TIME and PAID scoring at Portfolio x BusinessApplication level.
- Receives cost by allocation from DeploymentProfiles.

The portfolio schema and TIME/PAID details are in their own Skills file.

### 3.8 Involved Party (Organizations, Individuals, Contacts)

- Organization
  - **Namespace-Scoped.**
  - NamespaceId (FK, NOT NULL) is mandatory.
  - Customers, vendors, suppliers, manufacturers, partners.
  - Visibility within a Workspace is filtered by usage.

- Individual
  - **Platform-Scoped (Global).**
  - One Individual can appear in many Workspaces.
  - Ties to the Entra ID OID (ExternalIdentityKey).

- Contact
  - Workspace-Scoped.
  - Represents "Stuart as seen in the Justice Workspace."
  - Linked to BusinessApplications, DeploymentProfiles, and Integrations.

Detailed schema is in core/involved-party.md.

### 3.9 Integrations

- InternalIntegration
  - Data flow between two internal BusinessApplications.
- ExternalIntegration
  - Data flow between a BusinessApplication and an external Organization or system.
- IntegrationContact
  - Ties Contacts to integrations with roles such as Integration Owner, Technical SME.

Detailed schema is in the integrations Skills file.

## 4. Relationships to Other Domains

### 4.1 BusinessApplication, DeploymentProfile, ITService

- BusinessApplication can have many DeploymentProfiles.
- Each DeploymentProfile can attach many ITServices.
- ITService cost is rolled up into DeploymentProfiles.
- BusinessApplication sees its runtime and cost through its DeploymentProfiles.

### 4.2 SoftwareProduct, ProductContract, DeploymentProfile

- SoftwareProduct (Workspace-Owned) has many ProductContracts (Local).
- ProductContract cost is allocated directly into DeploymentProfiles using DeploymentProfileContract.
- DeploymentProfile may be application-specific or generic.
- Combined, this supports:
  - Application-specific deployments such as Sage 300 Justice Prod
  - Generic SaaS spend such as O365 Org Wide

### 4.3 DeploymentProfile and Portfolios

- DeploymentProfilePortfolio expresses how a DP is shared between Portfolios.
- AllocationPercent on DeploymentProfilePortfolio defines cost splitting.
- Portfolio cost reports aggregate DP-level cost according to these allocations.

### 4.4 Portfolios, TIME, PAID

- TIME and PAID scores live at Portfolio x BusinessApplication.
- They do not live on BusinessApplication itself.

### 4.5 Involved Party relationships

- Organizations are Namespace-Scoped.
- Individuals are Platform-Scoped (Global).
- Contacts are Workspace-specific.
- Contacts link to:
  - BusinessApplications (Owners)
  - Integrations (Technical Contacts)
  - Contracts (Local Owners)

### 4.6 WorkspaceGroup and reporting

- WorkspaceGroup groups Workspaces for reporting inside a single Namespace.
- WorkspaceGroup does not host Portfolios, BusinessApplications, or DeploymentProfiles.
- WorkspaceGroup views can:
  - Aggregate Portfolios, Applications, DeploymentProfiles, ITServices, and cost across member Workspaces
  - Provide "all ministries" or "all portcos" dashboards
- Workspace security remains unchanged:
  - Normal users see only their Workspace.
  - Only Namespace Admins can view cross-workspace aggregated reports via WorkspaceGroup views.

## 5. ASCII ERD (Conceptual)

```
Platform and grouping

+-----------------------------+
|          Namespace          |
+-----------------------------+
             |
             | 1..*
             v
+-----------------------------+
|          Workspace          |  <-- Owns SoftwareProducts, ITServices,
+-----------------------------+      Contracts, DPs (Federated Catalog)
             ^
             |
             | 1..*
+-----------------------------+
|    WorkspaceGroupWorkspace  |
+-----------------------------+
             ^
             |
             | 1..*
+-----------------------------+
|       WorkspaceGroup        |  <-- Visibility Engine for Catalog Sharing
+-----------------------------+
```

```
Core APM and cost model

+-----------------------------+
|      BusinessApplication    |
+-----------------------------+
             |
             | 1..*
             v
+-----------------------------+
|      DeploymentProfile      |
+-----------------------------+
             |
   +---------+---------+
   |                   |
   | M:N               | M:N (via DeploymentProfileContract)
   v                   v
+----------------+   +---------------------------+
|    ITService   |   |      ProductContract      |
+----------------+   +---------------------------+
                         |
                         | many..1
                         v
                    +--------------------+
                    |  SoftwareProduct   | <-- Workspace-Owned / Federated
                    +--------------------+
```

```
DeploymentProfile to Portfolio

+-----------------------------+
|      DeploymentProfile      |
+-----------------------------+
             |
             | M:N
             v
+-----------------------------+
|  DeploymentProfilePortfolio |
+-----------------------------+
             |
             | many..1
             v
+-----------------------------+
|          Portfolio          |
+-----------------------------+
```

## 6. Migration Considerations (AS IS -> Next Gen)

High level only. Detailed steps belong in a dedicated Migration Skills file.

### 6.1 Consolidate Software Products (Federated Catalog Setup)
- **Key Step:** Identify duplicate "O365", "Office 365", and "Microsoft Office" records across legacy data.
- Create a single **SoftwareProduct** in the designated Publisher Workspace (e.g., "Central IT").
- Flag the Publisher Workspace with `IsCatalogPublisher = true` in relevant WorkspaceGroups.
- **Critical:** Set `IsInternalOnly = false` on shared products or no one will see them.
- Update all existing legacy contracts to point to this shared product ID.

### 6.2 Move environment and hosting to DeploymentProfile
- Create DeploymentProfiles for each application environment.
- Move technical attributes from BA to DP.

### 6.3 Cost Migration
- Move cost fields from BusinessApplications to **ProductContracts**.
- Allocate Contracts to DeploymentProfiles via **DeploymentProfileContract**.
- Use **EstimatedAnnualCost** on DeploymentProfile for balance-forward costs.
- **Note:** EstimatedAnnualCost is ADDITIVE (see Cost Model Architecture for details).

### 6.4 Identity Migration
- Map legacy Users to **Individuals** (Platform-Global) and **Contacts** (Workspace).
- Ensure Owners and SMEs are linked via the Contact record.

## 7. Open Questions or Follow-Up Work

- Governance workflow: Who approves new shared SoftwareProducts in Publisher Workspaces?
- Exact structure of advanced ProductContract pricing (per seat, tiered models).
- How far to go with modelling MSP and service contracts in early versions.
- Detailed ServiceNow alignment rules for Federated Catalog items.

## 8. Out of Scope

This core file does not define:

- Detailed field lists for each entity
- RBAC and permission rules
- Detailed ServiceNow mapping and API integration
- Detailed Involved Party and Contact models
- Reporting layout, dashboards, and visual design
- Full WorkspaceGroup RBAC and admin flows

These subjects are covered in separate domain-specific Skills files.

## 9. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.4 | 2025-12-12 | Resolved scoping contradiction: SoftwareProduct is now consistently described as Workspace-Owned with Federated Catalog visibility. Renamed "Global Catalog" to "Federated Catalog" throughout. Clarified Organization is Namespace-Scoped. Clarified only Namespace Admins can use WorkspaceGroup views. Added EstimatedAnnualCost clarification. |
| v2.3 | 2025-12-08 | Previous version with scoping ambiguity. |
