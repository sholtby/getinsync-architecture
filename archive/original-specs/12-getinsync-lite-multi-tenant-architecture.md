# GetInSync Lite - Multi-Tenant Architecture
Version: 1.0
Last updated: 2025-12-21

## 1. Purpose

This document defines the simplified multi-tenant architecture for GetInSync Lite. It follows the same hierarchical patterns as GetInSync (full) but removes complexity around workspace-to-workspace sharing and portfolio nesting.

**GetInSync Lite is designed for:**
- Single-organization deployments
- Departmental portfolio management
- Entry point to the GetInSync ecosystem

---

## 2. Design Overview

### 2.1 Key Principles

1. **Region â†’ Namespace â†’ Workspace hierarchy** (same as GetInSync)
2. **Workspace isolation is absolute** â€” no cross-workspace sharing
3. **No portfolio nesting** â€” portfolios are flat within a workspace
4. **No WorkspaceGroups** â€” that's a GetInSync (full) feature
5. **Simple upgrade path** â€” data model compatible with GetInSync (full)

### 2.2 What's IN GetInSync Lite

| Feature | Included |
|---------|----------|
| Multi-tenant (Region/Namespace/Workspace) | âœ… |
| Application Pool per Workspace | âœ… |
| Multiple Portfolios per Workspace | âœ… (limit 3 in free tier) |
| TIME/PAID Assessment | âœ… |
| CSV Import/Export | âœ… |
| Basic reporting (dashboard cards) | âœ… |

### 2.3 What's NOT in GetInSync Lite (GetInSync Full features)

| Feature | GetInSync Lite | GetInSync Full |
|---------|----------------|----------------|
| WorkspaceGroups | âŒ | âœ… |
| Cross-workspace catalog sharing | âŒ | âœ… |
| Portfolio nesting | âŒ | âœ… |
| IT Service catalog | âŒ | âœ… |
| Software Product catalog | âŒ | âœ… |
| Advanced reporting (QuickSight) | âŒ | âœ… |
| API access | âŒ | âœ… |

---

## 3. Core Entities

### 3.1 Entity Hierarchy

```
Region (AWS Region)
    â””â”€â”€ Namespace (Tenant/Organization)
            â””â”€â”€ Workspace (Department/Team)
                    â”œâ”€â”€ Application (Pool)
                    â”œâ”€â”€ Portfolio
                    â”‚       â””â”€â”€ PortfolioAssignment (App + Scores)
                    â”œâ”€â”€ Contact (Business Owner, Support)
                    â””â”€â”€ Settings (T-shirt sizing, etc.)
```

### 3.2 Region

**Purpose:** AWS deployment region for data residency compliance.

| Field | Type | Notes |
|-------|------|-------|
| RegionId | PK | e.g., `ca-central-1` |
| Name | String | e.g., "Canada (Central)" |
| IsActive | Boolean | Enable/disable region |

**GetInSync Lite initial deployment:** `ca-central-1` (Canada) only.

---

### 3.3 Namespace

**Purpose:** Tenant/Organization boundary. All billing and administration happens here.

| Field | Type | Notes |
|-------|------|-------|
| NamespaceId | PK (UUID) | |
| RegionId | FK | Data residency |
| Name | String | Organization name (e.g., "Acme Corp") |
| Slug | String | URL-safe identifier (e.g., "acme-corp") |
| Tier | Enum | `free`, `pro`, `enterprise` |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

**Tier Limits:**

| Limit | Free | Pro | Enterprise |
|-------|------|-----|------------|
| Workspaces | 1 | 5 | Unlimited |
| Portfolios per Workspace | 3 | 10 | Unlimited |
| Applications per Workspace | 20 | 100 | Unlimited |
| Users | 3 | 20 | Unlimited |

---

### 3.4 Workspace

**Purpose:** Isolated working environment for a team/department. All data is scoped to a Workspace.

| Field | Type | Notes |
|-------|------|-------|
| WorkspaceId | PK (UUID) | |
| NamespaceId | FK | Parent tenant |
| Name | String | e.g., "Finance IT", "Corporate Systems" |
| Slug | String | URL-safe identifier |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

**Workspace isolation rules:**
- Users can only see data within their assigned Workspace(s)
- No data flows between Workspaces
- Namespace Admins can see all Workspaces (for billing/admin)

---

### 3.5 User & Access

| Field | Type | Notes |
|-------|------|-------|
| UserId | PK (UUID) | |
| NamespaceId | FK | User belongs to a Namespace |
| Email | String | Login identifier |
| Name | String | Display name |
| Role | Enum | `namespace_admin`, `workspace_admin`, `member` |
| CreatedAt | Timestamp | |

**WorkspaceUser (Join Table):**

| Field | Type | Notes |
|-------|------|-------|
| WorkspaceUserId | PK | |
| WorkspaceId | FK | |
| UserId | FK | |
| Role | Enum | `admin`, `editor`, `viewer` |

**Role Matrix:**

| Permission | Namespace Admin | Workspace Admin | Editor | Viewer |
|------------|-----------------|-----------------|--------|--------|
| View all Workspaces | âœ… | âŒ | âŒ | âŒ |
| Create Workspace | âœ… | âŒ | âŒ | âŒ |
| Manage Users | âœ… | Workspace only | âŒ | âŒ |
| Manage Portfolios | âœ… | âœ… | âœ… | âŒ |
| Perform Assessments | âœ… | âœ… | âœ… | âŒ |
| View Dashboard | âœ… | âœ… | âœ… | âœ… |
| Export CSV | âœ… | âœ… | âœ… | âœ… |

---

### 3.6 Application (Pool)

**Purpose:** Master inventory of applications. Workspace-scoped.

| Field | Type | Notes |
|-------|------|-------|
| ApplicationId | PK (UUID) | |
| WorkspaceId | FK | **All apps scoped to Workspace** |
| Name | String | Required |
| Description | Text | |
| BusinessOwnerId | FK â†’ Contact | |
| PrimarySupportId | FK â†’ Contact | |
| AnnualCost | Decimal | |
| LifecycleStatus | Enum | `mainstream`, `extended`, `end_of_support` |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

---

### 3.7 Portfolio

**Purpose:** Logical grouping for assessment context. Workspace-scoped.

| Field | Type | Notes |
|-------|------|-------|
| PortfolioId | PK (UUID) | |
| WorkspaceId | FK | **All portfolios scoped to Workspace** |
| Name | String | |
| Description | Text | |
| IsDefault | Boolean | One per Workspace, cannot be deleted |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

**No nesting:** Portfolios are flat. No parent/child relationships.

---

### 3.8 PortfolioAssignment

**Purpose:** Links an Application to a Portfolio with assessment scores.

| Field | Type | Notes |
|-------|------|-------|
| PortfolioAssignmentId | PK (UUID) | |
| PortfolioId | FK | |
| ApplicationId | FK | |
| AssessmentStatus | Enum | `not_started`, `in_progress`, `complete` |
| RemediationEffort | Enum | `xs`, `s`, `m`, `l`, `xl`, `xxl` |
| B1 - B10 | Integer (1-5) | Business factor scores |
| T01 - T15 | Integer (1-5) | Technical factor scores |
| BusinessFit | Decimal | Computed (0-100) |
| TechHealth | Decimal | Computed (0-100) |
| Criticality | Decimal | Computed (0-100) |
| TechRisk | Decimal | Computed (0-100) |
| TimeQuadrant | Enum | `tolerate`, `invest`, `migrate`, `eliminate` |
| PaidAction | Enum | `plan`, `address`, `ignore`, `delay` |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

**Unique constraint:** (PortfolioId, ApplicationId) â€” an app can only be in a portfolio once.

---

### 3.9 Contact

**Purpose:** People who own or support applications. Workspace-scoped.

| Field | Type | Notes |
|-------|------|-------|
| ContactId | PK (UUID) | |
| WorkspaceId | FK | |
| Name | String | |
| Email | String | Optional |
| Title | String | Optional |
| CreatedAt | Timestamp | |

---

### 3.10 WorkspaceSettings

**Purpose:** Configuration per Workspace.

| Field | Type | Notes |
|-------|------|-------|
| WorkspaceSettingsId | PK | |
| WorkspaceId | FK | |
| MaxProjectBudget | Decimal | For T-shirt sizing thresholds |
| CreatedAt | Timestamp | |
| UpdatedAt | Timestamp | |

---

## 4. ASCII ERD

```
+------------------+
|     Region       |
+------------------+
| RegionId (PK)    |
| Name             |
+--------+---------+
         |
         | 1..*
         v
+------------------+
|    Namespace     |
+------------------+
| NamespaceId (PK) |
| RegionId (FK)    |
| Name             |
| Tier             |
+--------+---------+
         |
         | 1..*
         v
+------------------+        +------------------+
|    Workspace     |        |       User       |
+------------------+        +------------------+
| WorkspaceId (PK) |        | UserId (PK)      |
| NamespaceId (FK) |        | NamespaceId (FK) |
| Name             |        | Email            |
+--------+---------+        | Role             |
         |                  +--------+---------+
         |                           |
         +-------------+-------------+
                       |
              +--------v---------+
              |  WorkspaceUser   |
              +------------------+
              | WorkspaceId (FK) |
              | UserId (FK)      |
              | Role             |
              +------------------+

+------------------+
|    Workspace     |
+--------+---------+
         |
    +----+----+----+----+
    |         |         |
    v         v         v
+-------+ +-------+ +----------+
|Contact| |Portfol| |Application|
+-------+ +-------+ +----------+
    ^         |           |
    |         |           |
    +---------+-----------+
              |
              v
    +-------------------+
    |PortfolioAssignment|
    +-------------------+
    | PortfolioId (FK)  |
    | ApplicationId (FK)|
    | B1-B10, T01-T15   |
    | Scores (computed) |
    +-------------------+
```

---

## 5. URL Structure

```
https://lite.getinsync.io/{namespace-slug}/{workspace-slug}/...

Examples:
https://lite.getinsync.io/acme-corp/finance-it/dashboard
https://lite.getinsync.io/acme-corp/finance-it/portfolios
https://lite.getinsync.io/acme-corp/finance-it/applications
https://lite.getinsync.io/acme-corp/finance-it/charts?portfolio=general
```

---

## 6. Authentication Flow

### 6.1 Options

| Option | Pros | Cons |
|--------|------|------|
| **Email/Password** | Simple, works everywhere | Password management |
| **Magic Link** | No passwords | Email deliverability |
| **OAuth (Google/Microsoft)** | Familiar, secure | Requires OAuth setup |
| **AWS Cognito** | Integrates with AWS | More complex |

**Recommendation for Lite:** Start with **Email/Password + Magic Link** via AWS Cognito or Auth.js.

### 6.2 Signup Flow

```
1. User signs up with email
2. System creates:
   - Namespace (named after email domain or user input)
   - Default Workspace ("General")
   - User record (Namespace Admin)
3. User lands on Dashboard
```

### 6.3 Invite Flow

```
1. Namespace Admin invites user by email
2. Invitee receives email with link
3. Invitee creates password / logs in
4. Invitee added to specified Workspace(s)
```

---

## 7. Upgrade Path to GetInSync (Full)

GetInSync Lite data model is a **subset** of GetInSync Full. Migration is additive:

| Lite Entity | Full Entity | Migration |
|-------------|-------------|-----------|
| Namespace | Namespace | 1:1 |
| Workspace | Workspace | 1:1 |
| Application | Application | 1:1, add catalog fields |
| Portfolio | Portfolio | 1:1, add nesting fields |
| PortfolioAssignment | PortfolioAssignment | 1:1 |
| Contact | Contact | 1:1, link to Organization |

**New entities in Full:**
- WorkspaceGroup
- SoftwareProduct
- ITService
- Organization (expanded)

---

## 8. AWS Deployment (ca-central-1)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚                     ca-central-1 (Canada)                       â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐  â”‚
â”‚  â”‚  Route 53   â”‚â”€â”€â”€â–¶â”‚ App Runner  â”‚â”€â”€â”€â–¶â”‚  RDS PostgreSQL     â”‚  â”‚
â”‚  â”‚  (DNS)      â”‚    â”‚ (App)       â”‚    â”‚  db.t3.micro        â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘    â””â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€┘    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘  â”‚
â”‚                            â”‚                                    â”‚
â”‚                     â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€┐    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐  â”‚
â”‚                     â”‚  S3 Bucket  â”‚    â”‚  Cognito            â”‚  â”‚
â”‚                     â”‚  (Assets)   â”‚    â”‚  (Auth)             â”‚  â”‚
â”‚                     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘  â”‚
â”‚                                                                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## 9. Open Questions

1. **Billing integration:** Stripe for Pro/Enterprise tiers?
2. **Custom domains:** Allow `portfolio.acme.com` for Enterprise?
3. **SSO:** SAML/OIDC for Enterprise tier?
4. **Data export:** Full export for migration to self-hosted?

---

## 10. Out of Scope for v1.0

- WorkspaceGroups (cross-workspace sharing)
- Portfolio nesting
- IT Service catalog
- Software Product catalog
- API access
- Advanced analytics (QuickSight)
- Mobile app

---

## 11. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-12-21 | Initial draft |
