# gis-identity-security-architecture-v1.0
GetInSync Identity, Security, and Compliance Architecture
Last updated: 2025-12-12

---

## 1. Purpose

This document defines the identity, authentication, authorization, and security architecture for GetInSync NextGen. It addresses:

- Multi-region SaaS deployment model
- Multi-IdP authentication (Entra ID, Saskatchewan Account, future providers)
- Role-Based Access Control (RBAC) across Platform, Namespace, Workspace, and WorkspaceGroup
- Analytics authorization (QuickSight integration)
- SOC 2 compliance controls
- Audit logging and data residency requirements

**Audience:** Internal architects, developers, and security/compliance teams.

**Related Documents:**
- gis-core-architecture-v2.4 (Platform structure)
- gis-involved-party-architecture-v1.5 (Individual, Contact, Organization)
- gis-workspace-group-architecture-v1.6 (WorkspaceGroup visibility rules)

---

## 2. Multi-Region Architecture

### 2.1 Design Principles

GetInSync is deployed as **regional instances** to satisfy data residency requirements (e.g., Canadian government data must stay in Canada).

**Key Principles:**
1. **Customer data never leaves its region**
2. **Each region is a self-contained deployment**
3. **Thin global layer handles non-sensitive operations only**
4. **Regions can be launched incrementally**

### 2.2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GetInSync Global                         │
│  (Customer Registration, Billing, License Management,       │
│   Region Selection, Support Portal)                         │
│  Hosted: Single region (e.g., AWS us-east-1)                │
│  Data: No customer content - only billing/license metadata  │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│ GetInSync Canada  │ │  GetInSync US     │ │ GetInSync EU      │
│ (AWS ca-central-1)│ │ (AWS us-east-1)   │ │ (AWS eu-west-1)   │
│                   │ │                   │ │                   │
│ ┌───────────────┐ │ │ ┌───────────────┐ │ │ ┌───────────────┐ │
│ │ Namespace:GoS │ │ │ │ Namespace:X   │ │ │ │ Namespace:Y   │ │
│ │ (Workspaces)  │ │ │ │ (Workspaces)  │ │ │ │ (Workspaces)  │ │
│ └───────────────┘ │ │ └───────────────┘ │ │ └───────────────┘ │
│                   │ │                   │ │                   │
│ ┌───────────────┐ │ │ ┌───────────────┐ │ │ ┌───────────────┐ │
│ │  QuickSight   │ │ │ │  QuickSight   │ │ │ │  QuickSight   │ │
│ │ (ca-central)  │ │ │ │ (us-east)     │ │ │ │ (eu-west)     │ │
│ └───────────────┘ │ │ └───────────────┘ │ │ └───────────────┘ │
│                   │ │                   │ │                   │
│ All data stays    │ │ All data stays    │ │ All data stays    │
│ in Canada         │ │ in US             │ │ in EU             │
└───────────────────┘ └───────────────────┘ └───────────────────┘
```

### 2.3 Scoping by Level

| Level | Scope | Examples |
|-------|-------|----------|
| **Global** | Billing, licensing, region routing | Customer signup, subscription management |
| **Region** | Isolated deployment with full stack | GetInSync Canada (ca-central-1) |
| **Namespace** | Customer tenant within a region | Government of Saskatchewan |
| **Workspace** | Department/division within Namespace | Ministry of Justice, Central IT |
| **WorkspaceGroup** | Reporting view across Workspaces | "All Ministries" rollup |

### 2.4 Cross-Region Considerations

- **No cross-region data access:** A user in GetInSync-Canada cannot query data in GetInSync-US
- **No cross-region identity:** Individual records are Region-scoped (not Platform-scoped as originally planned)
- **Multinational customers:** Must create separate Namespaces in each required region

---

## 3. Authentication Architecture

### 3.1 Design Principles

1. **No custom identity management** - leverage enterprise IdPs only
2. **IdP configuration at Namespace level** - each customer uses their own IdP
3. **MFA required** - enforced for all users
4. **SSO mandatory** - no GetInSync-managed passwords for production

### 3.2 Supported Identity Providers

| IdP Type | Protocol | Use Case | Status |
|----------|----------|----------|--------|
| Microsoft Entra ID | OIDC / OAuth 2.0 | Government employees, enterprise | Supported |
| Saskatchewan Account | SAML 2.0 | Citizens and businesses | Supported |
| Azure AD B2B | OIDC | Partner organizations | Supported |
| Okta | OIDC / SAML 2.0 | Enterprise customers | Future |
| Google Workspace | OIDC | Enterprise customers | Future |

### 3.3 Authentication Flow

```
┌──────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│  User    │────▶│  GetInSync   │────▶│  Namespace IdP  │────▶│  MFA Check   │
│ Browser  │     │  Login Page  │     │  (Entra ID)     │     │  (Entra/MFA) │
└──────────┘     └──────────────┘     └─────────────────┘     └──────────────┘
                                                                      │
     ┌────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  IdP Returns    │────▶│  GetInSync       │────▶│  Session Created │
│  Token + Claims │     │  Token Validation │     │  User Logged In  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

### 3.4 Namespace IdP Configuration

Each Namespace stores its IdP configuration:

```
NamespaceIdentityProvider
├── NamespaceIdentityProviderId (PK)
├── NamespaceId (FK)
├── ProviderType (EntraID, SaskatchewanAccount, SAML, OIDC)
├── DisplayName
├── ClientId
├── TenantId (for Entra ID)
├── Authority / MetadataUrl
├── ClientSecret (encrypted)
├── IsEnabled
├── IsPrimary (one primary per Namespace)
├── AllowedDomains (e.g., "gov.sk.ca")
└── CreatedDate / ModifiedDate
```

**Multi-IdP per Namespace:**
- Government of Saskatchewan could have:
  - Primary: Entra ID (for employees)
  - Secondary: Saskatchewan Account (for citizen-facing features)
- User's email domain determines which IdP is used

### 3.5 Token Claims Mapping

| IdP Claim | GetInSync Field | Behavior |
|-----------|-----------------|----------|
| `oid` (Entra ID Object ID) | `Individual.ExternalIdentityKey` | Primary lookup key |
| `email` / `upn` | `Individual.PrimaryEmail` | Soft match / sync |
| `name` | `Individual.DisplayName` | Sync on login |
| `groups` | Role assignment | Map to Workspace roles |

### 3.6 Just-In-Time (JIT) Provisioning

When a user authenticates:

1. **Lookup:** Query `Individual` where `ExternalIdentityKey = token.oid`
2. **If found:** Update DisplayName, Email from token; continue to authorization
3. **If not found:**
   - Search by `PrimaryEmail` (soft match)
   - If email match: Link the OID to existing Individual
   - If no match: Create new Individual (if self-registration enabled for Namespace)
4. **Contact Resolution:** Ensure Contact exists in user's Workspace(s)
5. **Role Assignment:** Apply default role or mapped group roles

---

## 4. Identity Model

### 4.1 Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                      REGION                                 │
│                   (e.g., Canada)                            │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    NAMESPACE                          │  │
│  │              (e.g., Gov of Saskatchewan)              │  │
│  │                                                       │  │
│  │  ┌─────────────────┐      ┌─────────────────────┐    │  │
│  │  │   Individual    │      │    Organization     │    │  │
│  │  │ (Region-scoped) │      │ (Namespace-scoped)  │    │  │
│  │  │                 │      │                     │    │  │
│  │  │ IndividualId    │      │ OrganizationId      │    │  │
│  │  │ ExternalIdKey   │      │ NamespaceId (FK)    │    │  │
│  │  │ PrimaryEmail    │      │ Name                │    │  │
│  │  │ DisplayName     │      │ IsSupplier          │    │  │
│  │  └────────┬────────┘      └─────────────────────┘    │  │
│  │           │                                          │  │
│  │           │ 1..*                                     │  │
│  │           ▼                                          │  │
│  │  ┌─────────────────────────────────────────────┐     │  │
│  │  │              WORKSPACE                      │     │  │
│  │  │        (e.g., Ministry of Justice)          │     │  │
│  │  │                                             │     │  │
│  │  │  ┌─────────────────┐                        │     │  │
│  │  │  │     Contact     │                        │     │  │
│  │  │  │(Workspace-scoped)│                        │     │  │
│  │  │  │                 │                        │     │  │
│  │  │  │ ContactId       │                        │     │  │
│  │  │  │ WorkspaceId(FK) │                        │     │  │
│  │  │  │ IndividualId(FK)│                        │     │  │
│  │  │  │ JobTitle        │                        │     │  │
│  │  │  └─────────────────┘                        │     │  │
│  │  └─────────────────────────────────────────────┘     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Identity Scoping Summary

| Entity | Scope | Rationale |
|--------|-------|-----------|
| Individual | Region | Isolated per regional deployment; ties to IdP |
| Organization | Namespace | Shared across Workspaces within customer tenant |
| Contact | Workspace | "Stuart as seen in Justice Ministry" |

---

## 5. Role-Based Access Control (RBAC)

### 5.1 Design Philosophy

GetInSync is built on a principle of **transparency by default**:

> **"Why are you in GetInSync if you are limited?"**

The platform exists to enable discovery ("google your environment"), break down silos, and provide whole-of-organization visibility. Restriction should be the **exception**, not the norm.

**Core Principles:**
1. **Transparency by default** - All entities visible unless explicitly restricted
2. **Workspace Role = Ceiling** - Maximum possible permissions
3. **Portfolio Role = Scope** - Which entities you can edit
4. **Restricted is rare** - Only for external contractors, auditors, focused tasks

### 5.2 Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    PLATFORM ADMIN                           │
│         (GetInSync Operations / SRE Team)                   │
│    • Manage all regions, namespaces                         │
│    • System configuration                                   │
│    • No routine customer data access (break-glass only)     │
│    • Internal only - not billable                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    NAMESPACE ADMIN                          │
│           (Customer IT Admin / Enterprise Admin)            │
│    • Create/delete Workspaces                               │
│    • Configure IdP settings                                 │
│    • Manage billing/licensing                               │
│    • View cross-Workspace reports (WorkspaceGroup)          │
│    • Assign Workspace Admins                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   WORKSPACE ADMIN                           │
│           (Ministry IT Lead / Department Admin)             │
│    • Full CRUD on all entities in Workspace                 │
│    • Manage users and role assignments                      │
│    • Configure Workspace settings                           │
│    • Create/delete Portfolios                               │
│    • Delete Applications (only Admin can delete)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   WORKSPACE EDITOR                          │
│           (Business Analyst / IT Analyst)                   │
│    • Create entities, edit assigned Portfolios              │
│    • Edit Technology Fit, DPs, Services, Contracts          │
│    • Full edit capability within Portfolio scope            │
│    • Cannot delete Applications                             │
│    • Cannot manage users or settings                        │
│    • BILLABLE: Full license                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      STEWARD (NEW)                          │
│        (Application Owner / Business Owner)                 │
│    • Edit Business Fit (TIME) for owned apps only           │
│    • Edit basic metadata and contacts                       │
│    • Can delegate to subordinates (max 2 per app)           │
│    • Max 10 apps as Owner (unlimited as Delegate)           │
│    • View all Workspace data (transparency)                 │
│    • Access Workspace dashboards                            │
│    • BILLABLE: Included in tier allocation                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      READ-ONLY                              │
│              (Executive / Stakeholder)                      │
│    • View all Workspace data                                │
│    • View all dashboards                                    │
│    • No create/update/delete                                │
│    • BILLABLE: Free (unlimited)                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     RESTRICTED                              │
│        (External Contractor / Auditor / Limited Scope)      │
│    • View ONLY assigned Portfolios                          │
│    • Edit only if has Portfolio role + ceiling allows       │
│    • NO dashboard access (uses UI navigation only)          │
│    • Exception role - not the norm                          │
│    • BILLABLE: Conditional                                  │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Workspace Role Definitions

| Role | Scope | Billable | Key Capabilities |
|------|-------|----------|------------------|
| **Platform Admin** | All Regions | N/A (internal) | System config; break-glass only |
| **Namespace Admin** | All Workspaces in Namespace | Yes | Create Workspaces; IdP config; billing; cross-WS reports |
| **Workspace Admin** | Single Workspace | Yes | Full CRUD; user management; settings; delete rights |
| **Workspace Editor** | Single Workspace | Yes | Create entities; full edit in assigned Portfolios; Technology Fit |
| **Steward** | Owned Applications/Services | Tier allocation | Business Fit only; metadata; contacts; view all |
| **Read-Only** | Single Workspace | No | View all; dashboards; no edit |
| **Restricted** | Assigned Portfolios only | Conditional | Limited visibility; no dashboards; exception use only |

### 5.4 Portfolio Roles

Portfolio roles determine **edit scope** within the ceiling set by Workspace role.

| Role | Scope | Capabilities |
|------|-------|--------------|
| **Portfolio Owner** | Named Portfolio(s) | Full edit; add/remove Applications; assign Contributors/Viewers; create child Portfolios |
| **Contributor** | Named Portfolio(s) | Edit Applications (Global + Portfolio tabs); **cannot add/remove Applications** |
| **Viewer** | Named Portfolio(s) | View only; required for Restricted users to see a Portfolio |

**Key Change from As-Is:** Contributor (formerly Author) **cannot** add/remove Applications. Only Portfolio Owner has this right. This fixes the governance gap identified in the current system.

### 5.5 Effective Permission Calculation

**Rule:** `Effective Permission = MIN(Workspace Role Ceiling, Portfolio Role Grant)`

| Workspace Role | Maximum Portfolio Capability |
|----------------|------------------------------|
| Workspace Admin | Full (any Portfolio, no assignment needed) |
| Workspace Editor | Owner or Contributor (requires assignment) |
| Read-Only | Viewer only (ceiling blocks edit even if assigned higher) |
| Restricted | Viewer only + visibility limited to assigned |

**Examples:**

| User | Workspace Role | Portfolio Role | Effective Permission |
|------|----------------|----------------|----------------------|
| Alice | Workspace Admin | (none) | Full edit all Portfolios |
| Bob | Workspace Editor | Owner (Police) | Full edit Police Portfolio only |
| Carol | Workspace Editor | Contributor (Fire) | Edit Fire Portfolio (no add/remove apps) |
| Dan | Workspace Editor | (none) | View all; edit nothing |
| Eve | Read-Only | Owner (Police) | **View only** (ceiling blocks edit) |
| Frank | Restricted | Contributor (Police) | Edit Police only; cannot see other Portfolios |
| Grace | Restricted | (none) | Cannot see anything; effectively locked out |

### 5.6 Program and Project Permissions

Programs and Projects are **Workspace-scoped** (cross-cutting across Portfolios).

**Schema Additions:**
```
Program
├── OwnerContactId (FK) ← Explicit owner
└── IsRestricted (Boolean, Default: FALSE)

Project
├── OwnerContactId (FK) ← Explicit owner
└── IsRestricted (Boolean, Default: FALSE)
```

**Permission Rules:**

| Role | View Programs/Projects | Edit Programs/Projects |
|------|------------------------|------------------------|
| Workspace Admin | All | All |
| Workspace Editor | All (unless IsRestricted=TRUE) | If Owner or Workspace Admin |
| Read-Only | All (unless IsRestricted=TRUE) | None |
| Restricted | Only if linked to assigned Portfolio | Only if Owner |

**Default:** `IsRestricted = FALSE` (transparency by default)

### 5.7 Publisher/Consumer Authorization Rules

**Rule:** Consumer Workspace users have **read-only** access to shared catalog items.

| Action | Publisher Workspace | Consumer Workspace |
|--------|--------------------|--------------------|
| View shared SoftwareProduct | ✅ Full | ✅ Read-only |
| Edit shared SoftwareProduct | ✅ Full | ❌ Denied |
| Create local Contract for shared Product | N/A | ✅ Full |
| View shared ITService | ✅ Full | ✅ Read-only |
| Edit shared ITService | ✅ Full | ❌ Denied |
| Link DP to shared ITService | N/A | ✅ Full |

### 5.8 Entra ID Security Group Mapping

Entra ID Security Groups map to **Workspace Roles** (not Portfolio roles in v1).

```
NamespaceGroupMapping
├── MappingId (PK)
├── NamespaceId (FK)
├── EntraGroupId (GUID from Entra ID)
├── EntraGroupName (for display)
├── WorkspaceRole (Namespace Admin, Workspace Admin, Workspace Editor, Read-Only, Restricted)
├── WorkspaceId (FK, nullable) ← If null, applies to all Workspaces
└── IsEnabled
```

**Example Mappings:**

| Entra ID Group | Workspace Role | Workspace |
|----------------|----------------|-----------|
| `GIS-GoS-Admins` | Namespace Admin | (all) |
| `GIS-Justice-Admins` | Workspace Admin | Justice |
| `GIS-Justice-Users` | Workspace Editor | Justice |
| `GIS-Justice-Viewers` | Read-Only | Justice |
| `GIS-Contractors` | Restricted | (all) |

**Portfolio Assignment:** Manual by Portfolio Owner or Workspace Admin (v1). Group-based Portfolio mapping deferred to v2.

### 5.9 Detailed Permission Matrix

#### Account / Namespace Operations

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| CREATE_NAMESPACES | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| CREATE_WORKSPACES | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| EDIT_WORKSPACE_SETTINGS | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| CONFIGURE_IDP | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| VIEW_BILLING | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

#### User / Role Management

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| ASSIGN_Namespace_Admin | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| ASSIGN_Workspace_Admin | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ASSIGN_Workspace_Editor | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ASSIGN_Read_Only | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ASSIGN_Restricted | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ASSIGN_Portfolio_Owner | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ASSIGN_Contributor | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| ASSIGN_Viewer | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| INVITE_USER | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| REMOVE_USER | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |

#### Portfolio Operations

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| CREATE_PORTFOLIO | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| EDIT_PORTFOLIO | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| DELETE_PORTFOLIO | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ADD_REMOVE_PORTFOLIO_APP | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| EDIT_PORTFOLIO_DATA | ✅ | ✅ | ✅ | If Owner/Contributor | ❌ | If assigned |
| MARK_PORTFOLIO_RESTRICTED | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

#### Applications

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| CREATE_APPLICATION | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| EDIT_APPLICATION_GLOBAL | ✅ | ✅ | ✅ | If in assigned Portfolio | ❌ | If assigned |
| EDIT_APPLICATION_PORTFOLIO | ✅ | ✅ | ✅ | If Owner/Contributor | ❌ | If assigned |
| DELETE_APPLICATION | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| VIEW_APPLICATION | ✅ | ✅ | ✅ | ✅ | ✅ | If assigned |

#### IT Services, Contacts, Ideas, Programs, Projects

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| CREATE_* | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| EDIT_* | ✅ | ✅ | ✅ | ✅ (or if Owner) | ❌ | If assigned |
| DELETE_* | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| VIEW_* | ✅ | ✅ | ✅ | ✅ | ✅ | If assigned |

#### Analytics / Dashboards

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| VIEW_WORKSPACE_DASHBOARDS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| VIEW_NAMESPACE_DASHBOARDS | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| VIEW_WORKSPACEGROUP_DASHBOARDS | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| CONFIGURE_DASHBOARDS | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

#### Import / Export

| Right | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Read-Only | Restricted |
|-------|----------------|-----------------|-----------------|------------------|-----------|------------|
| IMPORT_DATA | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| EXPORT_DATA | ✅ | ✅ | ✅ | If Portfolio Owner | ❌ | ❌ |
| DOWNLOAD_BACKUP | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

### 5.10 Billing Model

For detailed pricing, tiers, and commercial terms, see **gis-pricing-model-v1.0.md**.

**Summary of Billable Roles:**

| Role | Billable? | Notes |
|------|-----------|-------|
| Platform Admin | N/A | Internal only |
| Namespace Admin | Yes | Included in tier |
| Workspace Admin | Yes | Consumes Editor license |
| Workspace Editor | Yes | Consumes Editor license |
| Steward | Enterprise only | Unlimited, included in Enterprise tier |
| Read-Only | No | Unlimited, all tiers |
| Restricted | Conditional | If has edit capability |

**License Pool Model:**
- Editors are pooled at Namespace level
- One user can be Editor in multiple Workspaces (counts as 1 license)
- Steward rights derived from Owner/Delegate contact (no explicit license)

### 5.11 Role Summary Table

| Role | Create Entities | Edit All | Edit Assigned | Edit Owned (Business Fit) | View | Dashboards | License |
|------|-----------------|----------|---------------|---------------------------|------|------------|---------|
| Workspace Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Editor |
| Workspace Editor | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | Editor |
| Steward | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | Steward (Enterprise) |
| Read-Only | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | Free |
| Restricted | ❌ | ❌ | Conditional | Conditional | Assigned | ❌ | Conditional |

### 5.12 Steward Role (Business Application Owners)

#### 5.12.1 Problem Statement

GetInSync offers unlimited free View Users to enable "google your environment" discovery. However, Application Owners who need to update Business Fit scores (TIME model) require Edit licenses, which creates cost barriers. Organizations respond by creating shadow spreadsheets, defeating the purpose of GetInSync.

#### 5.12.2 Solution: The Steward Role

A **Steward** is an Application or IT Service Owner who can edit **Business Fit data only** for entities they own, without requiring a full Editor license.

```
┌─────────────────────────────────────────────────────────────┐
│                      STEWARD                                │
│        (Application Owner / Business Owner)                 │
│                                                             │
│    • Edit Business Fit (TIME) for owned Applications        │
│    • Edit basic metadata (name, description, lifecycle)     │
│    • Add Delegates (max 2 per Application)                  │
│    • View everything in Workspace (transparency)            │
│    • Access Workspace dashboards                            │
│    • Cannot edit Technology Fit, DPs, Services, Contracts   │
│    • Cannot create/delete Applications                      │
│    • Cannot manage Portfolios                               │
│                                                             │
│    BILLABLE: Included in subscription tier allocation       │
└─────────────────────────────────────────────────────────────┘
```

#### 5.12.3 Steward Scope (v1)

| Domain | View | Edit |
|--------|------|------|
| Business Fit (TIME questions) | ✅ | ✅ |
| Technology Fit (TIME questions) | ✅ | ❌ |
| Application Metadata (name, description, lifecycle) | ✅ | ✅ |
| Contacts (add Delegates, update SMEs) | ✅ | ✅ |
| Integrations | ✅ | ❌ |
| Project Links | ✅ | ❌ |
| Documents | ✅ | ❌ |
| Deployment Profiles | ✅ | ❌ |
| IT Service Links | ✅ | ❌ |
| Contracts | ✅ | ❌ |
| Dashboards | ✅ | ❌ |

**Design Principle:** Steward handles business knowledge. Technical and financial data requires Workspace Editor.

#### 5.12.4 Owner and Delegate Model

Steward rights are **derived from Contact assignment**, not explicitly granted:

```
Application: "CAD System"
├── Contacts:
│   ├── Owner: Sarah Chen (VP, Police Operations)
│   │   └── Has Steward Rights: ✅
│   │   └── Can Delegate To: Up to 2 people
│   │
│   ├── Delegate: Mike Johnson (Business Analyst)
│   │   └── DelegatedBy: Sarah Chen
│   │   └── Has Steward Rights: ✅ (inherited)
│   │
│   └── SME: Lisa Park
│       └── Has Steward Rights: ❌ (SME doesn't grant Steward)
```

**Rules:**

| Rule | Implementation |
|------|----------------|
| Owner gets Steward rights automatically | Contact Type = "Owner" grants rights |
| Owner can assign up to 2 Delegates | Delegation tracked via `DelegatedByContactId` |
| Delegate inherits Steward rights | Same edit scope as Owner |
| Owner removal cascades | If Owner removed, their Delegates lose rights |
| Max 10 Applications as Owner | Prevents gaming; encourages proper ownership |
| Unlimited Applications as Delegate | Supports Facilitator pattern (see below) |

#### 5.12.5 Schema Extensions

```sql
-- Contact Types that grant Steward rights
ALTER TABLE RefContactTypes ADD
  GrantsStewardRights bit NOT NULL DEFAULT 0

-- Default: Only "Owner" grants Steward rights
UPDATE RefContactTypes SET GrantsStewardRights = 1 WHERE Name = 'Owner'

-- Delegation support
ALTER TABLE Contacts ADD
  DelegatedByContactId uniqueidentifier NULL,
  DelegationExpiresAt datetime NULL,
  CONSTRAINT FK_Contact_DelegatedBy 
    FOREIGN KEY (DelegatedByContactId) REFERENCES Contacts(ContactId)

-- Workspace settings for Steward limits
ALTER TABLE Accounts ADD
  MaxOwnersPerApplication int NOT NULL DEFAULT 1,
  MaxDelegatesPerOwner int NOT NULL DEFAULT 2,
  MaxApplicationsPerStewardOwner int NOT NULL DEFAULT 10
```

#### 5.12.6 The Facilitator Pattern

**Use Case:** Bob is the Ministry SME responsible for gathering TIME data for 30 Applications across 15 Owners.

**Solution:** Bob can be **Delegate** on unlimited Applications:

| Limit Type | Owner | Delegate |
|------------|-------|----------|
| Max Applications | 10 | Unlimited |

```
Ministry of Justice:
├── 15 Application Owners (each owns 1-5 apps)
│   └── Each Owner delegates to Bob
│
└── Bob (Facilitator)
    ├── Delegate on 30 Applications
    ├── Can edit Business Fit on all 30
    ├── Counts as 1 Steward (not 30)
    └── No limit on Delegate assignments
```

**Counting Rule:** Stewards are counted as **users**, not user-application pairs.

#### 5.12.7 Quick Entry Form (v1 Feature)

A simplified UI for Stewards to enter TIME Business Fit scores:

```
┌─────────────────────────────────────────────────────────────┐
│  Quick Entry: Business Fit Assessment                       │
│  Application: CAD System                                    │
│  Due: December 20, 2025 (5 days remaining)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Business Criticality         [====●=====] 7/10            │
│  How critical is this app to business operations?           │
│                                                             │
│  Business Value               [======●===] 8/10            │
│  What value does this app provide?                          │
│                                                             │
│  User Satisfaction            [===●======] 5/10            │
│  How satisfied are users?                                   │
│                                                             │
│  Strategic Alignment          [=====●====] 6/10            │
│  How aligned with strategic goals?                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Notes: ________________________________________________   │
│                                                             │
│                              [Save Draft]  [Submit Final]   │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Focused, simple interface for Business Owners
- Direct link: `getinsync.com/assess/app/{id}?token={token}`
- Expiry date with email reminders
- Mobile-friendly
- Save draft capability

#### 5.12.8 Steward Availability

**Steward is an Enterprise-only feature.** See **gis-pricing-model-v1.0.md** for tier details.

| Tier | Steward Available |
|------|-------------------|
| Essentials | ❌ |
| Plus | ❌ |
| Enterprise | ✅ Unlimited |

**Rationale:** Organizations that need Steward functionality are typically large enough to have dedicated Application Owners and mature enough to care about TIME model accuracy. These are Enterprise customers by definition.

#### 5.12.9 IT Services: Same Model

IT Services use the same Owner/Delegate pattern:

| Setting | Application | IT Service |
|---------|-------------|------------|
| Max Owners | 1 | 1 |
| Max Delegates per Owner | 2 | 2 |
| Steward can edit Business Fit | ✅ | ✅ |
| Steward can edit Technology Fit | ❌ | ❌ |

#### 5.12.10 Future: TIME Assessment Workflow (v2)

For scenarios where multiple stakeholders need to contribute scores:

| Feature | Description |
|---------|-------------|
| Assessment Campaign | Facilitator initiates assessment for an Application |
| Stakeholder Invites | One-time link with expiry (no account required) |
| Score Collection | Each stakeholder enters their view of Business Fit |
| Aggregation | Average, weighted, or consensus (configurable) |
| Review & Finalize | Facilitator reviews variance, approves final scores |
| Reminders | Automated email reminders before expiry |

**Stakeholder Access:** One-time link with expiry; no GetInSync account required.

This feature addresses the "Bob collecting from 10 stakeholders" use case and will be prioritized based on customer demand.

### 5.13 Role Migration from As-Is

| As-Is Role | NextGen Role | Migration Action |
|------------|--------------|------------------|
| Enterprise Admin | Platform Admin | Reclassify to internal only |
| Certified Provider Admin | Namespace Admin | Rename |
| Global Admin | Workspace Admin | Rename |
| Company Admin | Workspace Admin | Merge (remove distinction) |
| Application Manager | Workspace Editor | Rename; review Portfolio assignments |
| View User | Read-Only or Steward | Assess if user needs Business Fit edit; assign Steward if Owner |
| Portfolio Manager | Portfolio Owner | Rename |
| Author | Contributor | Rename; **remove add/remove app rights** |
| (blank portfolio) | Viewer | Explicit for Restricted Portfolios only |

---

## 6. Analytics Authorization (QuickSight)

### 6.1 Design Philosophy

Dashboard access follows the **transparency by default** principle:
- Most users see all Workspace dashboards
- Restricted users get **no dashboard access** (use UI navigation only)
- This simplifies QuickSight configuration and avoids complex per-Portfolio RLS

### 6.2 Dashboard Access by Role

| Role | Workspace Dashboards | Namespace Dashboards | WorkspaceGroup Dashboards |
|------|---------------------|----------------------|---------------------------|
| Platform Admin | ✅ All | ✅ All | ✅ All |
| Namespace Admin | ✅ All Workspaces | ✅ | ✅ |
| Workspace Admin | ✅ | ❌ | ❌ |
| Workspace Editor | ✅ | ❌ | ❌ |
| Read-Only | ✅ | ❌ | ❌ |
| **Restricted** | **❌ None** | **❌** | **❌** |

**Rationale:** If you need dashboards, you shouldn't be Restricted. Elevate to Read-Only or higher.

### 6.3 Current Architecture

- **QuickSight Namespace:** One per GetInSync Namespace (shared across Workspaces)
- **User Provisioning:** QuickSight users created via `AnalyticsUsers` table
- **Data Source:** Direct connection to GetInSync database
- **Billing:** Per-session (rollup views = 1 session)

### 6.4 User-to-Group Assignment

| GetInSync Role | QuickSight Group Assignment |
|----------------|----------------------------|
| Namespace Admin | Namespace group + all Workspace groups |
| Workspace Admin | Own Workspace group |
| Workspace Editor | Own Workspace group |
| Read-Only | Own Workspace group |
| Restricted | **No QuickSight user provisioned** |

### 6.5 Analytics Group Model

```
┌─────────────────────────────────────────────────────────────┐
│              QuickSight Namespace: "gos-prod"               │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Analytics Groups                     │   │
│  │                                                      │   │
│  │  ┌──────────────┐  Type: Workspace                  │   │
│  │  │   "justice"  │  → Sees: workspace_id = 'justice' │   │
│  │  └──────────────┘                                    │   │
│  │                                                      │   │
│  │  ┌──────────────┐  Type: Workspace                  │   │
│  │  │  "education" │  → Sees: workspace_id = 'education'│   │
│  │  └──────────────┘                                    │   │
│  │                                                      │   │
│  │  ┌──────────────┐  Type: Workspace                  │   │
│  │  │  "centralit" │  → Sees: workspace_id = 'centralit'│   │
│  │  └──────────────┘                                    │   │
│  │                                                      │   │
│  │  ┌──────────────────────┐  Type: WorkspaceGroup     │   │
│  │  │ "all-ministries"     │  → Sees: All member WS    │   │
│  │  └──────────────────────┘                            │   │
│  │                                                      │   │
│  │  ┌──────────────────────┐  Type: Namespace          │   │
│  │  │ "namespace-admin"    │  → Sees: All Workspaces   │   │
│  │  └──────────────────────┘                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 Extended Schema

```sql
-- Extend AnalyticsGroups for NextGen
ALTER TABLE AnalyticsGroups ADD
  WorkspaceGroupId uniqueidentifier NULL,
  NamespaceId uniqueidentifier NULL,
  GroupType nvarchar(50) NOT NULL DEFAULT 'Workspace'
  -- Values: 'Workspace', 'WorkspaceGroup', 'Namespace'

-- Map which Workspaces an AnalyticsGroup can see
CREATE TABLE AnalyticsGroupWorkspaces (
  AnalyticsGroupWorkspaceId uniqueidentifier PRIMARY KEY,
  AnalyticsGroupId uniqueidentifier NOT NULL,
  WorkspaceId uniqueidentifier NOT NULL,
  CONSTRAINT FK_AGW_AnalyticsGroup 
    FOREIGN KEY (AnalyticsGroupId) REFERENCES AnalyticsGroups(AnalyticsGroupId),
  CONSTRAINT FK_AGW_Workspace 
    FOREIGN KEY (WorkspaceId) REFERENCES Accounts(AccountId) -- or Workspaces table
)

-- Population rules:
-- GroupType = 'Workspace': One row, WorkspaceId = own Workspace
-- GroupType = 'WorkspaceGroup': Rows for each member of the WorkspaceGroup
-- GroupType = 'Namespace': Rows for all Workspaces in Namespace
```

### 6.4 Row-Level Security (RLS)

QuickSight datasets include RLS based on user's group memberships:

```sql
-- RLS Rule: User sees data for Workspaces they have access to
SELECT * FROM dataset
WHERE workspace_id IN (
  SELECT agw.WorkspaceId
  FROM AnalyticsGroupWorkspaces agw
  INNER JOIN AnalyticsUserGroups aug ON aug.AnalyticsGroupId = agw.AnalyticsGroupId
  INNER JOIN AnalyticsUsers au ON au.AnalyticsUserId = aug.AnalyticsUserId
  WHERE au.QuickSightUserName = '{{UserName}}'
)
```

### 6.5 Preventing Double-Counting in Rollups

**Problem:** If Justice has 50 Applications and Education has 30, the "All Ministries" rollup should show 80, not duplicated counts.

**Solution:** Data lives at Workspace level only. Rollup is aggregation, not duplication.

```sql
-- Correct: Aggregate from Workspace-level data
SELECT 
  wsg.WorkspaceGroupName,
  COUNT(DISTINCT a.ApplicationId) AS TotalApplications,
  SUM(pa.TotalCost) AS TotalCost
FROM WorkspaceGroups wsg
INNER JOIN WorkspaceGroupWorkspace wsgw ON wsgw.WorkspaceGroupId = wsg.WorkspaceGroupId
INNER JOIN Applications a ON a.AccountId = wsgw.WorkspaceId
INNER JOIN PortfolioApplications pa ON pa.ApplicationId = a.ApplicationId
WHERE wsg.WorkspaceGroupId = @WorkspaceGroupId
GROUP BY wsg.WorkspaceGroupName

-- Note: Applications exist in ONE Workspace only
-- PortfolioApplications may exist in leaf Portfolios only (enforced by app)
```

### 6.6 Publisher/Consumer Reporting

**Scenario:** Central IT (Publisher) wants to see all consumers of their shared ITService.

```sql
-- Stranded Cost Report for Publisher
SELECT 
  its.Name AS ITServiceName,
  its.TotalAnnualCost AS TotalPool,
  SUM(dpits.AllocationValue) AS Recovered,
  its.TotalAnnualCost - SUM(dpits.AllocationValue) AS StrandedCost,
  COUNT(DISTINCT dp.AccountId) AS ConsumerWorkspaceCount
FROM ITServices its
LEFT JOIN DeploymentProfileITService dpits ON dpits.ITServiceId = its.ITServiceId
LEFT JOIN DeploymentProfiles dp ON dp.DeploymentProfileId = dpits.DeploymentProfileId
WHERE its.AccountId = @PublisherWorkspaceId
  AND its.IsInternalOnly = 0  -- Shared services only
GROUP BY its.ITServiceId, its.Name, its.TotalAnnualCost
```

---

## 7. Session Management

### 7.1 Token Architecture

| Token Type | Lifetime | Purpose |
|------------|----------|---------|
| ID Token | 1 hour | User identity claims from IdP |
| Access Token | 1 hour | API authorization |
| Refresh Token | 24 hours | Obtain new access tokens |
| Session Cookie | 8 hours | Browser session (sliding expiration) |

### 7.2 Session Rules

- **Idle Timeout:** 30 minutes of inactivity
- **Absolute Timeout:** 8 hours (force re-authentication)
- **Concurrent Sessions:** Allowed (user may have multiple browsers/devices)
- **Session Revocation:** Admin can revoke all sessions for a user

### 7.3 Session Storage

```
UserSessions
├── SessionId (PK)
├── UserId (FK → Users)
├── IndividualId (FK → Individual)
├── WorkspaceId (FK) -- Last active Workspace
├── NamespaceId (FK)
├── IdPSessionId (from IdP token)
├── CreatedAt
├── LastActivityAt
├── ExpiresAt
├── IPAddress
├── UserAgent
├── IsRevoked
└── RevokedBy / RevokedAt
```

---

## 8. API Security

### 8.1 API Authentication

All API requests require authentication via one of:

| Method | Use Case | Token Location |
|--------|----------|----------------|
| Bearer Token (OAuth 2.0) | User-context API calls | `Authorization: Bearer {token}` |
| API Key | Service-to-service, integrations | `X-API-Key: {key}` |

### 8.2 API Key Management

```
ApiKeys
├── ApiKeyId (PK)
├── WorkspaceId (FK) -- Scoped to Workspace
├── Name
├── KeyHash (hashed, never stored plaintext)
├── KeyPrefix (first 8 chars for identification)
├── Scopes (JSON array: ["read:applications", "write:applications"])
├── CreatedBy (UserId)
├── CreatedAt
├── ExpiresAt
├── LastUsedAt
├── IsRevoked
└── RevokedBy / RevokedAt
```

**Scope Examples:**
- `read:applications` - Read Applications in Workspace
- `write:applications` - Create/Update Applications
- `read:portfolios` - Read Portfolios
- `admin:users` - Manage users (Workspace Admin only)

### 8.3 Rate Limiting

| Tier | Requests/Minute | Requests/Day |
|------|-----------------|--------------|
| Standard | 100 | 10,000 |
| Premium | 500 | 50,000 |
| Enterprise | 2,000 | Unlimited |

Rate limits apply per API Key or per User.

---

## 9. Audit Logging

### 9.1 Audit Events

| Category | Events |
|----------|--------|
| Authentication | Login success/failure, logout, MFA challenge, session timeout |
| Authorization | Permission denied, role change, group mapping change |
| Data Access | View, create, update, delete on entities |
| Admin Actions | User management, IdP config, Workspace settings |
| API Access | API key usage, rate limit hits |
| Analytics | Dashboard embed, report generation |
| Export | Data export, backup download |

### 9.2 Audit Log Schema

```
AuditLogs
├── AuditLogId (PK)
├── Timestamp (UTC)
├── RegionId
├── NamespaceId
├── WorkspaceId
├── UserId / IndividualId
├── SessionId
├── EventCategory
├── EventType
├── EventDescription
├── EntityType (Application, Portfolio, etc.)
├── EntityId
├── OldValues (JSON, for updates)
├── NewValues (JSON, for updates)
├── IPAddress
├── UserAgent
├── RequestId (correlation)
└── Outcome (Success, Failure, Denied)
```

### 9.3 Retention Policy

| Log Type | Retention | Rationale |
|----------|-----------|-----------|
| Security Events | 1 year | SOC 2 requirement |
| Data Access | 1 year | SOC 2 requirement |
| Admin Actions | 1 year | SOC 2 requirement |
| API Access | 90 days | Operational |
| Debug/Trace | 30 days | Troubleshooting |

### 9.4 Export for Compliance

GoS and other customers can export audit logs:

- **Format:** JSON, CSV
- **Scope:** Namespace or Workspace
- **Date Range:** Up to 1 year
- **Delivery:** Download or push to customer SIEM

---

## 10. SOC 2 Controls Mapping

### 10.1 Trust Service Criteria Coverage

| Criteria | Category | GetInSync Controls |
|----------|----------|-------------------|
| CC6.1 | Security | RBAC, MFA, IdP integration |
| CC6.2 | Security | Encryption at rest (AES-256) and in transit (TLS 1.2+) |
| CC6.3 | Security | API authentication, rate limiting |
| CC6.6 | Security | Audit logging, session management |
| CC6.7 | Security | Vulnerability scanning, patching |
| CC7.1 | Security | Intrusion detection (AWS GuardDuty) |
| CC7.2 | Security | Security event monitoring |
| A1.1 | Availability | Multi-AZ deployment, auto-scaling |
| A1.2 | Availability | Backup and recovery (30-day retention) |
| C1.1 | Confidentiality | Data classification, access controls |
| C1.2 | Confidentiality | Encryption, data residency |

### 10.2 Key Controls Detail

**CC6.1 - Logical Access:**
- All users authenticate via customer IdP (Entra ID)
- MFA required for all accounts
- RBAC enforced at Workspace level
- No shared accounts permitted

**CC6.6 - Audit Logging:**
- All authentication events logged
- All data modifications logged
- Logs retained 1 year
- Logs immutable (append-only)
- Customer can export logs

**A1.2 - Recovery:**
- Daily automated backups
- 30-day backup retention
- Customer-downloadable backups
- RTO: 4 hours, RPO: 1 hour

**C1.2 - Data Protection:**
- Data encrypted at rest (AWS KMS, AES-256)
- Data encrypted in transit (TLS 1.2+)
- Regional data residency enforced
- No cross-region data transfer

---

## 11. Data Residency

### 11.1 Regional Data Boundaries

| Region | AWS Region | Data Types |
|--------|------------|------------|
| Canada | ca-central-1 | All customer data for Canadian customers |
| US | us-east-1 | All customer data for US customers |
| EU | eu-west-1 | All customer data for EU customers (future) |
| Global | us-east-1 | Billing metadata only (no customer content) |

### 11.2 Data Residency Enforcement

- Customer selects region at Namespace creation
- Region cannot be changed after creation
- All data (DB, files, backups, logs) stays in region
- QuickSight instance in same region as data

### 11.3 Compliance Certifications by Region

| Region | Certifications |
|--------|---------------|
| Canada | SOC 2, CSA STAR, Canadian Privacy Laws |
| US | SOC 2, HIPAA eligible (future) |
| EU | SOC 2, GDPR compliant (future) |

---

## 12. Future Considerations

### 12.1 B2B Federation

For partner organizations accessing GetInSync:

- Azure AD B2B delegation
- Partner users authenticate via their own IdP
- GetInSync trusts GoS Azure AD, which trusts partner IdP
- Partner users mapped to specific Workspace with limited role

### 12.2 B2C (Citizen Access)

For public-facing features:

- Saskatchewan Account integration (SAML 2.0)
- Citizen users have limited, scoped access
- Separate role: "Public User" with read-only to specific data

### 12.3 PAM Integration

For privileged access management:

- Integration hooks for CyberArk or similar
- Break-glass access for Platform Admins
- Session recording for admin actions
- Just-in-time access provisioning

### 12.4 SIEM Integration

For security monitoring:

- Push audit logs to customer SIEM (Microsoft Sentinel, Splunk)
- Webhook integration for real-time alerts
- Standard formats (CEF, JSON)

---

## 13. Migration from As-Is

### 13.1 Identity Migration

| As-Is | NextGen | Migration Action |
|-------|---------|------------------|
| `Users` | `Individual` | Map User to Individual; populate ExternalIdentityKey from IdP |
| `Contacts.UserId` | `Contact.IndividualId` | Update FK reference |
| `UserRoles` | Enhanced `UserRoles` | Add Namespace-level roles |
| `Accounts` | `Workspace` + `Namespace` | Create Namespace for parent accounts |

### 13.2 Analytics Migration

| As-Is | NextGen | Migration Action |
|-------|---------|------------------|
| `AnalyticsGroups.AccountId` | `AnalyticsGroups.WorkspaceId` + `GroupType` | Add GroupType column |
| (none) | `AnalyticsGroupWorkspaces` | Create new table; populate for existing groups |
| (none) | WorkspaceGroup Analytics Groups | Create groups for each WorkspaceGroup |

---

## 14. Open Questions

1. **Self-Registration:** Should new users from allowed domains auto-provision, or require admin approval?
2. **Session Concurrency:** Should we limit concurrent sessions per user?
3. **API Key Rotation:** Should API keys auto-expire and require rotation?
4. **Citizen Role Scope:** What data should "Public User" role access?

---

## 15. Out of Scope

- Detailed IdP configuration UI/UX
- Specific SIEM integration implementations
- PCI-DSS compliance (not handling payment card data directly)
- HIPAA compliance (future consideration)

---

## 16. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-12-12 | Initial version covering multi-region, authentication, RBAC, QuickSight, SOC 2, and data residency |
| v1.0 | 2025-12-12 | Finalized RBAC model: 5 Workspace roles (Admin, Editor, Read-Only, Restricted) + 3 Portfolio roles (Owner, Contributor, Viewer); Ceiling/Scope permission model; Transparency by default; Restricted users get no dashboard access; Program/Project Owner model with IsRestricted flag; Entra ID group-to-Workspace-role mapping |
| v1.0 | 2025-12-14 | Added Steward role for Application/IT Service Owners; Business Fit edit only; Owner/Delegate model with limits (max 10 apps as Owner, unlimited as Delegate, max 2 Delegates per Owner); Quick Entry Form for TIME data collection; Steward is Enterprise-only (unlimited) |
| v1.0 | 2025-12-14 | Separated pricing into gis-pricing-model-v1.0.md; This document now focuses on technical architecture only |

---

## 17. Related Documents

| Document | Description |
|----------|-------------|
| gis-pricing-model-v1.0.md | Commercial pricing, tiers, discounts, contract terms |
| gis-architecture-manifest-v1.2.md | Architecture manifest and document index |
| gis-nextgen-rbac-matrix-draft.md | Detailed permission matrix |

End of file.
