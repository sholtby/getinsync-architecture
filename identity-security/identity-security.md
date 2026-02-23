# identity-security/identity-security.md
GetInSync Identity, Security, and Compliance Architecture
Last updated: 2025-12-26

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
- core/core-architecture.md (Platform structure)
- core/involved-party.md (Individual, Contact, Organization)
- core/workspace-group.md (WorkspaceGroup visibility rules)

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
┌─────────────────────────────────────────────────────────────────┐
│                    GetInSync Global                             │
│  (Customer Registration, Billing, License Management,           │
│   Region Selection, Support Portal)                             │
│  Hosted: Single region (e.g., AWS us-east-1)                    │
│  Data: No customer content - only billing/license metadata      │
└─────────────────────────────────────────────────────────────────┘
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
┌─────────────────────────────────────────────────────────────────┐
│                      REGION                                     │
│                   (e.g., Canada)                                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    INDIVIDUAL                             │  │
│  │         (Platform-Scoped within Region)                   │  │
│  │  Stuart Holtby, ExternalIdentityKey = Entra OID          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│           ┌───────────────┼───────────────┐                     │
│           ▼               ▼               ▼                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  CONTACT    │  │  CONTACT    │  │  CONTACT    │             │
│  │ (Police WS) │  │  (Fire WS)  │  │ (Parks WS)  │             │
│  │ Role:Editor │  │Role:ReadOnly│  │ Role:Admin  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Key Entities

| Entity | Scope | Purpose |
|--------|-------|---------|
| **Individual** | Region (Platform) | Real person identity; Entra ID anchor |
| **Contact** | Workspace | Person as seen in a Workspace; holds WorkspaceRole |
| **Organization** | Namespace | Companies, vendors, agencies |

---

## 5. Authorization Model (RBAC)

### 5.1 Role Hierarchy

```
Platform Admin (Internal Only)
└── Full system access across all Namespaces

Namespace Admin
├── Full control over Namespace
├── Manage all Workspaces, users, billing
├── See "All Workspaces" aggregated view
└── Configure assessment factors, thresholds

Workspace Admin
├── Full control within assigned Workspace(s)
├── Invite users to Workspace
├── Manage Workspace settings
└── Cannot see other Workspaces

Workspace Editor
├── Create/edit Applications, DPs, assessments
├── Cannot manage users or Workspace settings
└── Cannot see other Workspaces

Steward (Derived from Owner/Delegate Contact)
├── Edit Business Fit (B1-B10) on owned Applications
├── Edit app metadata, contacts, lifecycle
├── Edit licensing cost, vendor contacts
├── View all in Workspace
└── Cannot edit Tech Health, DPs, infrastructure

Read-Only
├── View all in assigned Workspace(s)
├── View dashboards, reports, charts
└── Cannot modify anything

Restricted
├── View assigned Portfolios only
├── No dashboard access
└── Cannot see unassigned data
```

### 5.2 Cross-Workspace Visibility

| Role | See Other Workspaces? | "All Workspaces" View? |
|------|----------------------|------------------------|
| Namespace Admin | Yes (all) | Yes |
| Workspace Admin | No | No |
| Workspace Editor | No | No |
| Steward | No | No |
| Read-Only | No | No |
| Restricted | No | No |

### 5.3 Tier-Based User Limits

| Tier | Users | Workspaces | Notes |
|------|-------|------------|-------|
| **Free** | 1 | 2 | Solo evaluator |
| **Pro** | 3 | 5 | Small team |
| **Enterprise** | Unlimited | Unlimited | Organization-wide |
| **Full** | Unlimited | Unlimited | Full platform |

### 5.10 Billing Model

For detailed pricing, tiers, and commercial terms, see **marketing/pricing-model.md**.

**Summary of Billable Roles:**

| Role | Billable? | Notes |
|------|-----------|-------|
| Platform Admin | N/A | Internal only |
| Namespace Admin | Yes | Included in tier |
| Workspace Admin | Yes | Consumes Editor license |
| Workspace Editor | Yes | Consumes Editor license |
| Steward | No | Derived from contact, all tiers |
| Read-Only | No | Unlimited, all tiers |
| Restricted | Conditional | If has edit capability |

**License Pool Model:**
- Editors are pooled at Namespace level
- One user can be Editor in multiple Workspaces (counts as 1 license)
- Steward rights derived from Owner/Delegate contact (no explicit license)

### 5.11 Role Summary Table

| Role | Create Entities | Edit All | Edit Assigned | Edit Owned (Steward Scope) | View | Dashboards | License |
|------|-----------------|----------|---------------|----------------------------|------|------------|---------|
| Workspace Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Editor |
| Workspace Editor | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | Editor |
| Steward | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | None (all tiers) |
| Read-Only | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | None |
| Restricted | ✗ | ✗ | Conditional | Conditional | Assigned | ✗ | Conditional |

### 5.12 Steward Role (Business Application Owners)

#### 5.12.1 Problem Statement

GetInSync offers unlimited free View Users to enable "google your environment" discovery. However, Application Owners who need to update Business Fit scores (TIME model) require Edit licenses, which creates cost barriers. Organizations respond by creating shadow spreadsheets, defeating the purpose of GetInSync.

**The real problem:** IT evaluators shouldn't have to chase down Business Owners to get tribal knowledge about business fit, licensing costs, and vendor relationships. Business Owners know this information — they should be empowered to enter it directly with zero friction.

#### 5.12.2 Solution: The Steward Role

A **Steward** is an Application or IT Service Owner who can edit **business-domain data** for entities they own, without requiring a full Editor license.

Steward is a **workflow feature**, not a capacity feature. It's available on **all tiers**.

```
┌─────────────────────────────────────────────────────────────────┐
│                      STEWARD                                    │
│        (Application Owner / Business Owner)                     │
│                                                                 │
│    • Edit Business Fit (B1-B10) for owned Applications          │
│    • Edit basic metadata (name, description, lifecycle)         │
│    • Edit contacts (Owner, Primary Support, Vendor Contact)     │
│    • Edit annual licensing cost                                 │
│    • Add Delegates (max 2 per Application)                      │
│    • View everything in Workspace (transparency)                │
│    • Access Workspace dashboards                                │
│    • Cannot edit Tech Health (T01-T15)                          │
│    • Cannot edit DP infrastructure (hosting, cloud, region, DR) │
│    • Cannot edit annual tech cost or tech debt                  │
│    • Cannot create/delete Applications                          │
│    • Cannot manage Portfolios                                   │
│                                                                 │
│    BILLABLE: No - available on all tiers                        │
└─────────────────────────────────────────────────────────────────┘
```

#### 5.12.3 Steward Scope (v1.1 - Expanded)

**Design Principle:** If a Business Owner would reasonably know it or own it, they can edit it. If it requires IT/technical expertise, they can view but not edit.

| Domain | View | Edit | Rationale |
|--------|------|------|-----------|
| **Business Fit (B1-B10)** | ✓ | ✓ | Core Steward purpose |
| **Application Metadata** (name, description, lifecycle) | ✓ | ✓ | Business owns this knowledge |
| **Contacts** (Owner, Primary Support, Vendor Contact) | ✓ | ✓ | Business knows who's who |
| **Annual Licensing Cost** | ✓ | ✓ | Business often owns this budget |
| **Vendor Contact** | ✓ | ✓ | Business manages vendor relationship |
| **Delegates** (add up to 2) | ✓ | ✓ | Owner can delegate Steward rights |
| Technology Fit (T01-T15) | ✓ | ✗ | IT/technical domain |
| Deployment Profiles | ✓ | ✗ | IT/technical domain |
| DP Infrastructure (hosting, cloud, region, DR) | ✓ | ✗ | IT/technical domain |
| Annual Tech Cost | ✓ | ✗ | IT budget domain |
| Tech Debt Estimates | ✓ | ✗ | IT/technical domain |
| IT Service Links | ✓ | ✗ | IT/technical domain |
| Contracts (except vendor contact) | ✓ | ✗ | Procurement/IT domain |
| Integrations | ✓ | ✗ | IT/technical domain |
| Dashboards | ✓ | ✗ | View only |

#### 5.12.4 Owner and Delegate Model

Steward rights are **derived from Contact assignment**, not explicitly granted:

```
Application: "CAD System"
├── Contacts:
│   ├── Owner: Sarah Chen (VP, Police Operations)
│   │   └── Has Steward Rights: ✓
│   │   └── Can Delegate To: Up to 2 people
│   │
│   ├── Delegate: Mike Johnson (Business Analyst)
│   │   └── DelegatedBy: Sarah Chen
│   │   └── Has Steward Rights: ✓ (inherited)
│   │
│   └── SME: Lisa Park
│       └── Has Steward Rights: ✗ (SME doesn't grant Steward)
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

-- Default: Only "Owner" and "Delegate" grant Steward rights
UPDATE RefContactTypes SET GrantsStewardRights = 1 WHERE Name IN ('Owner', 'Delegate')

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

#### 5.12.7 Steward Availability

| Tier | Steward Available | Rationale |
|------|-------------------|-----------|
| Free | ✓ | Workflow feature, not capacity (moot with 1 user) |
| Pro | ✓ | Enables 3-user teams with distributed ownership |
| Enterprise | ✓ | Full organizational scale |
| Full | ✓ | Full platform |

**Rationale for all-tier availability:**
- Steward rights are *derived* from ownership, not explicitly licensed
- Gating derived permissions feels artificially punitive
- The *problem* Steward solves exists at every scale
- Pro/Enterprise differentiation is elsewhere (user count, workspaces, SSO, API)

#### 5.12.8 Quick Entry Form (v1 Feature)

A simplified UI for Stewards to enter TIME Business Fit scores:

```
┌─────────────────────────────────────────────────────────────────┐
│  Quick Entry: Business Fit Assessment                           │
│  Application: CAD System                                        │
│  Due: December 20, 2025 (5 days remaining)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Business Criticality         [====◆=====] 7/10                 │
│  How critical is this app to business operations?               │
│                                                                 │
│  Business Value               [======◆===] 8/10                 │
│  What value does this app provide?                              │
│                                                                 │
│  User Satisfaction            [===◆======] 5/10                 │
│  How satisfied are users?                                       │
│                                                                 │
│  Strategic Alignment          [=====◆====] 6/10                 │
│  How aligned with strategic goals?                              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Annual Licensing Cost: $_______________                        │
│  Vendor Contact: [Select or Add Contact]                        │
│                                                                 │
│  Notes: ________________________________________________        │
│                                                                 │
│                              [Save Draft]  [Submit Final]       │
└─────────────────────────────────────────────────────────────────┘
```

**Features:**
- Focused, simple interface for Business Owners
- Direct link: `getinsync.com/assess/app/{id}?token={token}`
- Expiry date with email reminders
- Includes licensing cost and vendor contact (new in v1.1)

---

## 9. Audit Logging

### 9.1 Events Logged

All security-relevant events:

| Event Category | Examples |
|----------------|----------|
| Authentication | Login, logout, failed login, MFA challenge |
| Authorization | Role assignment, permission change, access denied |
| Data Access | View, export, report generation |
| Data Modification | Create, update, delete (all entities) |
| Admin Actions | User invite, Workspace creation, settings change |

### 9.2 Log Record Structure

```json
{
  "eventId": "uuid",
  "timestamp": "2025-01-15T10:30:00Z",
  "eventType": "DATA_MODIFICATION",
  "action": "UPDATE",
  "actorId": "individual-uuid",
  "actorEmail": "stuart@example.com",
  "namespaceId": "namespace-uuid",
  "workspaceId": "workspace-uuid",
  "resourceType": "Application",
  "resourceId": "app-uuid",
  "changes": {
    "field": "lifecycle_status",
    "oldValue": "Active",
    "newValue": "Retiring"
  },
  "ipAddress": "192.168.1.1",
  "userAgent": "Mozilla/5.0..."
}
```

### 9.3 Retention

| Environment | Retention | Storage |
|-------------|-----------|---------|
| Production | 1 year | S3 + Glacier |
| Non-Production | 90 days | S3 |

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
| v1.0 | 2025-12-14 | Separated pricing into marketing/pricing-model.md; This document now focuses on technical architecture only |
| **v1.1** | **2025-12-26** | **Expanded Steward scope:** Added annual licensing cost, vendor contact to editable fields. **Steward now available on all tiers** (Free, Pro, Enterprise, Full) — it's a workflow feature, not a capacity gate. Updated tier user limits: Free=1, Pro=3, Enterprise/Full=Unlimited. Updated rationale explaining Steward as derived permissions that shouldn't be tier-gated. |

---

## 17. Related Documents

| Document | Description |
|----------|-------------|
| marketing/pricing-model.md | Commercial pricing, tiers, discounts, contract terms |
| core/involved-party.md | Individual, Contact, Organization, Steward details |
| MANIFEST.md | Architecture manifest and document index |
| archive (superseded by identity-security/rbac-permissions.md) | Detailed permission matrix |

End of file.
