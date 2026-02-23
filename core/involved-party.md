# core/involved-party.md
GetInSync Architecture Specification

Last updated: 2026-01-11

## 1. Purpose

This file defines the Next-Gen Involved Party model for GetInSync:

- Individuals (people) - Platform-scoped identity
- **Contacts (namespace-scoped views of people)** - Including optional Primary Workspace for filtering
- Organizations (companies, agencies, vendors, customers)
- Addresses and email channels
- Contact roles on applications, deployment profiles, IT services, integrations, and contracts
- **Licensing model** - Editor Pool at Namespace level
- **Steward rights** - Derived from Owner/Delegate contact assignments

It clarifies:

- How people and organizations are shared (or not) across Workspaces
- How Namespace admins access WorkspaceGroup views
- How we future-proof for Entra ID and external identity systems
- **How licensing (Editor Pool) relates to RBAC (Workspace Roles)**
- **How Steward rights are derived from Contact assignments**
- **How Contacts are visible across Workspaces within a Namespace (v1.9)**

This model underpins:

- Supplier and vendor management
- Integration contacts
- Business Application owners
- Deployment Profile and IT Service contacts
- Product and ProductContract contacts
- **User licensing and role-based access control**

For detailed RBAC rules, see **identity-security/identity-security.md**.
For pricing and tier details, see **marketing/pricing-model.md**.

## 2. Design Overview

### 2.1 Core ideas

1. **Individual is Platform-Scoped (Global)**
   One Individual per real-world person (per platform), not per Workspace or Namespace.

2. **Contact is Namespace-Scoped** *(Changed in v1.9)*
   - Contact is the person "as seen in this Namespace".
   - **All contacts are visible across all Workspaces within the same Namespace.**
   - All domain objects (Applications, DeploymentProfiles, ITServices, Integrations, etc.) reference ContactId, not IndividualId.
   - **PrimaryWorkspaceId (optional)** indicates the contact's "home" workspace for UI filtering purposes.
   - **Contact includes WorkspaceRole** (Admin, Editor, Steward, Read-Only, Restricted).

3. **Organization is Namespace-Scoped**
   - **NamespaceId (FK, NOT NULL) is mandatory.**
   - Organizations are shared across Workspaces within the same Namespace.
   - Visibility within a Workspace is filtered by usage (referenced via SupplierOrgId, ManufacturerOrgId, or ContactOrganization).
   - Supplier, Vendor, Manufacturer, Customer are roles, not separate tables.

4. **WorkspaceGroup is reporting-only**
   - Groups multiple Workspaces for roll-up views.
   - Does not own data; it points at existing Workspaces.
   - **Only Namespace Admins can view cross-workspace aggregated reports via WorkspaceGroup views.** There is no separate "WorkspaceGroup Admin" role.

5. **Privacy is enforced at Namespace level for Contacts** *(Changed in v1.9)*
   - A user in a Namespace sees:
     - **All Contacts in that Namespace** (scoped to namespace_id)
     - Organizations used in their Workspaces (filtered by usage)
   - **UI filtering** via PrimaryWorkspaceId allows users to see "My Workspace Contacts" by default, reducing noise.
   - Namespace isolation remains strict - users in one Namespace cannot see Contacts in another Namespace.

6. **Future identity integration**
   - Individual is the natural place to map external identities (for example, Entra ID user).
   - User (login) will reference Individual.
   - Contacts are namespace-local wrappers around Individuals.

7. **Licensing: Editor Pool at Namespace Level**
   - Editor licenses are pooled at Namespace level, not per Workspace.
   - One Individual can be Editor in multiple Workspaces (counts as 1 license).
   - License type is derived from the user's highest Workspace Role across all Workspaces.
   - See Section 3.10 for details.

8. **Steward Rights: Derived from Contact Assignment**
   - Steward is a special role for Application/IT Service Owners.
   - Steward rights are granted automatically when a user is assigned as Owner or Delegate contact on an Application or IT Service.
   - **Steward is available on all tiers** (Free, Pro, Enterprise, Full) — it's a workflow feature, not a capacity gate. *(Changed in v1.8)*
   - See Section 3.11 for details.

### 2.2 Goals

- Single, consistent way to model people and organizations.
- Clear separation between global identity (Individual) and namespace view (Contact).
- Support multi-workspace scenarios (ministries, portcos, MSP clients).
- Enable 360-degree "Contact footprint" per Namespace without leaking cross-client data.
- Keep the schema simple enough for implementation and migration.
- **Clear separation between licensing (capacity) and RBAC (permissions).**
- **Support shared applications across Workspaces with visible contacts.** *(Added in v1.9)*

### 2.3 Rationale for Namespace-Scoped Contacts *(New in v1.9)*

**Previous design (v1.7 and earlier):** Contacts were workspace-scoped. Each Contact belonged to exactly one Workspace.

**Problem discovered:** When an Application is published from Workspace A and subscribed to by Workspace B:
- The Business Owner contact lives in Workspace A
- Users in Workspace B cannot see the contact due to RLS
- Contact information was invisible to consumers

**Solution:** Make Contacts namespace-scoped:
- All contacts visible within their Namespace
- Matches GetInSync OG behavior
- Supports the Publisher/Consumer model for shared applications
- UI filtering via PrimaryWorkspaceId handles "noise"

**Alternative considered but rejected:**
- `portfolio_assignment_contacts` table for per-portfolio business contacts
- Rejected because: "If you need different owners, create a different application"
- Business contacts come WITH the shared app and are read-only for consumers

## 3. Core Entities or Components

### 3.1 Individual

Represents a real person at platform level.

Example: "Stuart Holtby" as a human being, independent of which Workspace he appears in.

Key fields (conceptual):

- IndividualId (PK)
- DisplayName
- LegalName (optional)
- PrimaryEmail (optional, for matching)
- ExternalIdentityKey (optional, for Entra ID / SSO mapping)
- Notes
- IsActive

Characteristics:

- No WorkspaceId or NamespaceId on Individual.
- One Individual can be reused in many Workspaces via Contacts.
- Platform super admins can see Individuals across Namespaces; Workspace users cannot.

### 3.1.1 Identity Mapping Strategy (Entra ID / OIDC)

This section defines how the **Individual** entity acts as the anchor for external identity providers (specifically Microsoft Entra ID).

**1. The Immutable Key**
- **ExternalIdentityKey** MUST store the Identity Provider's immutable identifier, typically the `oid` (Object ID) from the Entra ID token.
- *Reasoning:* Email addresses and names change (marriages, domain rebrands). The OID is immutable for the lifetime of the identity.

**2. Token Claim Mapping**

| Entra ID Token Claim | GetInSync Individual Column | Behavior |
| :--- | :--- | :--- |
| `oid` (Object ID) | `ExternalIdentityKey` | **Hard Match.** Primary lookup key on login. |
| `name` | `DisplayName` | **Sync.** Updates local display name on successful login to keep data fresh. |
| `email` or `upn` | `PrimaryEmail` | **Soft Match / Sync.** Used for system notifications and initial account linking. |

**3. JIT (Just-in-Time) Provisioning Logic**
When a user authenticates via Entra ID, the application middleware performs the following:
1. **Lookup:** Query `Individual` where `ExternalIdentityKey == Token.oid`.
2. **Update (if found):** Update `DisplayName` and `PrimaryEmail` from the token claims.
3. **Link (if not found):**
   - Search for an existing `Individual` by `PrimaryEmail` (Soft Match).
   - If found, save the token `oid` into `ExternalIdentityKey` to finalize the link.
   - If not found, create a new `Individual` record (if Self-Registration is enabled) or reject the login.

### 3.2 Contact *(Updated in v1.9)*

Represents an Individual inside a Namespace, with an optional "home" Workspace.

Example: "Stuart Holtby - Pal's Pets namespace contact (primary: IT Workspace)".

Key fields:

- ContactId (PK)
- **NamespaceId (FK, NOT NULL)** *(Changed in v1.9 - was WorkspaceId)*
- **PrimaryWorkspaceId (FK, NULLABLE)** *(New in v1.9 - optional "home" workspace for filtering)*
- IndividualId (FK)
- **WorkspaceRole** (Admin, Editor, Steward, ReadOnly, Restricted)
- DisplayNameOverride (optional)
- JobTitle (workspace-specific)
- ContactCategory (optional: InternalStaff, Vendor, Contractor, Customer, Other)
- IsActive
- Notes

**WorkspaceRole Values:**

| Role | Description | License Consumed |
|------|-------------|------------------|
| Admin | Full CRUD, user management, settings | Editor |
| Editor | Create entities, edit in assigned Portfolios | Editor |
| Steward | Edit Business Fit + business data on owned Applications only | None (all tiers) |
| ReadOnly | View all, no edit | None |
| Restricted | View assigned Portfolios only | None |

Characteristics:

- **All Contacts in a Namespace are visible to all users in that Namespace.** *(Changed in v1.9)*
- **PrimaryWorkspaceId is used for UI filtering** ("My Workspace Contacts" vs "All Contacts").
- All domain objects inside a Namespace (Applications, DPs, IT Services, Integrations, ProductContracts, etc.) reference ContactId.
- A single Individual can have many Contacts (one per Namespace, potentially multiple if MSP scenario).
- **WorkspaceRole determines what the user can do.** The role may be workspace-specific in future implementations.
- **A user can have different WorkspaceRoles in different Workspaces** (e.g., Editor in Justice, ReadOnly in Health).

### 3.2.1 Contact RLS Policies *(New in v1.9)*

**SELECT Policy:** `Users can view namespace contacts`
```sql
USING (
  namespace_id IN (
    SELECT u.namespace_id FROM users u WHERE u.id = auth.uid()
  )
)
```

**ALL (INSERT/UPDATE/DELETE) Policy:** `Admins can manage namespace contacts`
```sql
USING (
  namespace_id IN (
    SELECT u.namespace_id FROM users u 
    WHERE u.id = auth.uid() 
    AND (
      u.namespace_role = 'admin'
      OR EXISTS (
        SELECT 1 FROM workspace_users wu
        WHERE wu.user_id = u.id
        AND wu.role IN ('admin', 'editor')
      )
    )
  )
)
```

### 3.2.2 Contact UI Filtering *(New in v1.9)*

To reduce "noise" when selecting contacts, the UI provides filtering options:

| Filter | Query |
|--------|-------|
| My Workspace (default) | `WHERE primary_workspace_id = currentWorkspaceId` |
| All Contacts | No filter (all namespace contacts) |
| No Home Workspace | `WHERE primary_workspace_id IS NULL` |

### 3.3 Organization

Represents a legal or logical organization.

Example: City of Garland, SaskBuilds, Microsoft, Sage, MSP X.

Key fields:

- OrganizationId (PK)
- **NamespaceId (FK, NOT NULL)** - Organization belongs to exactly one Namespace
- Name
- OrganizationType (optional: PublicSector, Private, NonProfit, etc.)
- IsSupplier (boolean)
- IsManufacturer (boolean)
- IsCustomer (boolean)
- IsInternalOrg (boolean)
- Website (optional)
- Notes
- IsActive

Characteristics:

- Organizations are namespace-scoped, shared across all Workspaces in that Namespace.
- UI shows contextual labels:
  - "Vendors" view → Organizations where IsSupplier = true
  - "Manufacturers" view → Organizations where IsManufacturer = true
  - "Organizations" view → Admin-only, shows all
- Multiple flags can be true (e.g., Microsoft is both Supplier and Manufacturer).

### 3.3.1 UI Presentation (Filtered Views)

Organizations appear differently based on context:

| Context | Label | Filter |
|---------|-------|--------|
| Contract/Invoice screens | "Vendor" | IsSupplier = true |
| Software Product screens | "Manufacturer" | IsManufacturer = true |
| Admin Settings | "Organizations" | No filter (all) |

This matches government user expectations (e.g., City of Garland feedback: "We think of these as Vendors").

## 4. Application Contacts *(New section in v1.9)*

### 4.1 application_contacts Table

Links applications to contacts with a specific role.

Key fields:

- id (PK)
- application_id (FK)
- contact_id (FK)
- role_type (CHECK constraint: 'business_owner', 'technical_owner', 'steward', 'sponsor', 'sme', 'support', 'vendor_rep', 'other')
- is_primary (boolean)
- notes (optional)
- created_at

### 4.2 Publisher/Consumer Model for Contacts

When an Application is published from Workspace A and subscribed to by Workspace B:

| Data | Who Can Edit | Where Stored |
|------|--------------|--------------|
| Application name, description | Publisher only | `applications` |
| Deployment Profile | Publisher only | `deployment_profiles` |
| Technical Assessment (T-scores) | Publisher only | `deployment_profiles` |
| **Business Owner, Support contacts** | **Publisher only** | `application_contacts` |
| Business Assessment (B-scores) | Each consumer | `portfolio_assignments` |

**Key principle:** Contacts follow the Application. Consumers see the publisher's contacts as read-only.

**Rationale:** If a consumer needs different owners, they should create a separate Application. Shared app = shared ownership.

## 5. Entity Diagrams

```
Individuals and Contacts

+------------------------+
|      Individual        |  <-- Platform-Global
+------------------------+
| IndividualId PK        |
| DisplayName            |
| LegalName (opt)        |
| PrimaryEmail (opt)     |
| ExternalIdentityKey    |
| IsActive               |
| ...                    |
+-----------+------------+
            |
            | 1:M  (one Individual -> many Contacts)
            v
+------------------------+
|        Contact         |  <-- Namespace-Scoped (v1.9)
+------------------------+
| ContactId PK           |
| NamespaceId FK         | <-- NOT NULL (changed from WorkspaceId)
| PrimaryWorkspaceId FK  | <-- NULLABLE (new in v1.9)
| IndividualId FK        |
| WorkspaceRole          |
| DisplayNameOverride    |
| JobTitle               |
| ContactCategory        |
| IsActive               |
| ...                    |
+-----------+------------+
            |
            | M:N via ContactOrganization
            v
+------------------------+
|      Organization      |  <-- Namespace-Scoped
+------------------------+
| OrganizationId PK      |
| NamespaceId FK         | <-- NOT NULL
| Name                   |
| OrganizationType       |
| IsSupplier             |
| IsManufacturer         |
| IsCustomer             |
| IsInternalOrg          |
| IsActive               |
| ...                    |
+-----------+------------+
```

```
Application Contacts

+------------------------+
|      Application       |
+------------------------+
| ApplicationId PK       |
| WorkspaceId FK         |
| Name                   |
| ...                    |
+-----------+------------+
            |
            | 1:M
            v
+------------------------+
|  application_contacts  |
+------------------------+
| id PK                  |
| application_id FK      |
| contact_id FK          |  --> Contact (namespace-scoped)
| role_type              |
| is_primary             |
| notes                  |
+------------------------+
```

## 6. Migration Considerations (AS-IS -> Next-Gen)

### 6.1 Extract existing Contacts
- Identify all current Contact records per Workspace.
- Create one Individual per unique person (email and name matching where possible).
- Backfill Contact.IndividualId.

### 6.2 Migrate Contacts to Namespace-Scoped *(New in v1.9)*

```sql
-- 1. Add namespace_id column
ALTER TABLE contacts ADD COLUMN namespace_id uuid REFERENCES namespaces(id);

-- 2. Populate from existing workspace relationship
UPDATE contacts c
SET namespace_id = w.namespace_id
FROM workspaces w
WHERE w.id = c.workspace_id;

-- 3. Make namespace_id NOT NULL
ALTER TABLE contacts ALTER COLUMN namespace_id SET NOT NULL;

-- 4. Rename workspace_id to primary_workspace_id
ALTER TABLE contacts RENAME COLUMN workspace_id TO primary_workspace_id;

-- 5. Make primary_workspace_id nullable
ALTER TABLE contacts ALTER COLUMN primary_workspace_id DROP NOT NULL;

-- 6. Update RLS policies (see Section 3.2.1)
```

### 6.3 Normalize Organizations
- Map existing Supplier/Vendor records to Organization.
- **Ensure NamespaceId is populated** for all Organization records.
- Create missing Organization entries.
- Populate OrganizationEmail and OrganizationAddress where data exists.

### 6.4 Populate ContactOrganization
For each Contact with an existing "Company" or Supplier field:
- Create ContactOrganization linking Contact to Organization.
- Set IsPrimaryForWorkspace when appropriate.

### 6.5 Migrate Legacy Application Owner/Support *(Updated in v1.9)*
- Existing text fields (owner, primary_support, secondary_support) on applications table
- Convert to application_contacts records:
  - owner → role_type = 'business_owner', is_primary = true
  - primary_support → role_type = 'support', is_primary = true
  - secondary_support → role_type = 'support', is_primary = false

## 7. Open Questions or Follow-Up Work

- Do we need PhoneChannel + ContactPhone for v1?
- Should ContactCategory be a lookup table for filtering?
- Should Individuals support pronouns or identity metadata?
- Should Organizations support classification (PublicSector, Private, NonProfit)?
- ~~Final UI/UX rules for Namespace admin cross-workspace visibility.~~ *(Resolved in v1.9)*
- Validation of Entra ID "Group" claim mapping to WorkspaceGroup roles.

## 8. Out of Scope

- Full schemas for BusinessApplication, DeploymentProfile, ITService, Integration, SoftwareProduct, ProductContract (defined in separate architecture files).
- Full RBAC permission matrices (see identity-security/identity-security.md).
- ServiceNow contact/user mapping.
- Full UI design for Contact 360 or WorkspaceGroup dashboards.
- Pricing and tier details (see marketing/pricing-model.md).

## 9. Related Documents

| Document | Relevance |
|----------|-----------|
| identity-security/identity-security.md | Full RBAC model, Steward role details, Entra ID mapping |
| marketing/pricing-model.md | Tier pricing, Editor Pool allocation |
| features/integrations/architecture.md | IntegrationContactRole definitions |
| catalogs/business-application.md | Application Contact types |
| core/workspace-group.md | Publisher/Consumer model |

## 10. Change Log

| Version | Date | Changes |
|---------|------|---------|
| **v1.9** | **2026-01-11** | **BREAKING CHANGE: Contacts are now Namespace-Scoped.** Renamed `workspace_id` to `primary_workspace_id` (nullable). Added `namespace_id` (required). Updated RLS policies. Added Section 2.3 (Rationale). Added Section 3.2.1 (RLS Policies). Added Section 3.2.2 (UI Filtering). Added Section 4 (Application Contacts). Updated entity diagrams. This change supports the Publisher/Consumer model where shared applications need visible contacts across workspaces. |
| v1.8 | 2025-12-26 | Expanded Steward scope: Added annual licensing cost, vendor contact to editable fields. **Steward now available on all tiers** (Free, Pro, Enterprise, Full) — it's a workflow feature, not a capacity gate. Updated tier user limits: Free=1, Pro=3, Enterprise/Full=Unlimited. Added rationale explaining Steward as derived permissions. |
| v1.7 | 2025-12-19 | Added Section 3.3.1 UI Presentation (Filtered Views). Organizations appear as "Vendors" and "Manufacturers" in UI based on boolean flags. Unfiltered "Organizations" view is admin-only. Contextual field labels (Vendor on contracts, Manufacturer on products). Validated with City of Garland feedback. |
| v1.6 | 2025-12-14 | Added licensing model (Editor Pool at Namespace level). Added Steward rights (derived from Owner/Delegate contacts). Added WorkspaceRole to Contact entity. Cross-references to identity-security/identity-security.md and marketing/pricing-model.md. |
| v1.5 | 2025-12-12 | Clarified Organization is Namespace-Scoped with mandatory NamespaceId. Added explicit visibility rules for Organizations. Removed references to undefined "WorkspaceGroup admin" role - only Namespace Admins can use WorkspaceGroup views. Added note that IntegrationContactRole is defined in features/integrations/architecture.md. |
| v1.4 | 2025-12-08 | Previous version with scoping ambiguity. |

End of file.
