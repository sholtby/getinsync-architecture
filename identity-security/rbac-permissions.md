# identity-security/rbac-permissions.md
GetInSync NextGen — RBAC & Permission Architecture

Last updated: 2026-03-11

---

## 1. Purpose

This document is the **single authoritative source** for GetInSync NextGen role-based access control (RBAC), permission matrices, tier-to-feature mapping, and enforcement status. It consolidates and supersedes:

| Previous Source | Status | Disposition |
|----------------|--------|-------------|
| identity-security/identity-security.md (Sections 5.1–5.13) | 🟠 Stale role/tier references | Sections 5.1–5.13 superseded by this document. Remainder (auth, SSO, SOC2) still authoritative. |
| archive (superseded by identity-security/rbac-permissions.md) | ⚪ Never versioned | Fully superseded. Archive. |
| archive (superseded by identity-security/rbac-permissions.md) | ⚪ Working document | Decisions incorporated here. Archive. |

**Cross-references (still authoritative for their domains):**
- `core/involved-party.md` — Contact model, Steward derivation, namespace-scoped contacts
- `identity-security/rls-policy-addendum.md` — RLS enforcement patterns, 72-table coverage
- `marketing/pricing-model.md` — Tier pricing and commercial terms
- `identity-security/identity-security.md` — Authentication, SSO, SOC2 (non-RBAC sections)

---

## 2. Design Philosophy

> **"Why are you in GetInSync if you are limited?"**

GetInSync is built on **transparency by default**. The platform exists to enable discovery, break down silos, and provide whole-of-organization visibility. Restriction is the **exception**, not the norm.

**Key principles:**
1. **Namespace = hard boundary.** Nothing crosses namespaces except platform admin operations.
2. **Workspace = collaboration boundary.** Users see everything in their assigned workspaces.
3. **Roles control writes, not reads.** All workspace members can see all data. Roles gate who can change it.
4. **Steward is derived, not assigned.** Steward rights come from contact role assignments, not workspace role.
5. **Flags are governance, not data edits.** Any workspace member — including viewers — can create data quality flags.

---

## 3. Role Hierarchy

### 3.1 Two-Level Role Model

GetInSync has roles at two levels:

| Level | Table | Purpose | Role Values |
|-------|-------|---------|-------------|
| **Namespace** | `users.namespace_role`, `namespace_users.role` | Controls cross-workspace visibility and admin functions | admin, editor, steward, viewer, restricted |
| **Workspace** | `workspace_users.role` | Controls what user can do within a workspace | admin, editor, viewer |

**Effective Permission = Namespace Role ceiling applied to Workspace Role.**

A user with namespace_role='viewer' cannot be workspace admin even if workspace_users says 'admin'. The namespace role is the ceiling.

### 3.2 Role Definitions

#### Platform Admin
- **Scope:** Global (all namespaces)
- **Table:** `platform_admins` + `users.is_super_admin`
- **License:** Internal (GetInSync staff only)
- **Purpose:** Provisioning, support, system operations
- **Key:** Bypasses all RLS via `is_platform_admin()` function

#### Namespace Admin
- **Scope:** One namespace, all workspaces
- **Tables:** `users.namespace_role = 'admin'`, `namespace_users.role = 'admin'`
- **License:** Editor seat
- **Purpose:** Tenant administrator — manages workspaces, users, settings, assessment configuration
- **Key:** Can see cross-workspace views (WorkspaceGroup aggregates)

#### Workspace Admin
- **Scope:** Assigned workspace(s)
- **Table:** `workspace_users.role = 'admin'`
- **License:** Editor seat
- **Purpose:** Structural control — create/delete apps, manage DPs, technical assessments, portfolio management
- **Key:** Full CRUD within workspace including DELETE

#### Workspace Editor
- **Scope:** Assigned workspace(s)
- **Table:** `workspace_users.role = 'editor'`
- **License:** Editor seat
- **Purpose:** Business contributor — business assessments, lifecycle status, annual cost
- **Key:** INSERT/UPDATE but not DELETE. Cannot create/delete apps or manage structure.

#### Steward (Derived Role)
- **Scope:** Specific applications where assigned as Owner or Delegate contact
- **Table:** NOT a workspace_users role. Derived from `application_contacts.role_type IN ('business_owner', 'steward')` + delegation chain
- **License:** None consumed (available on all tiers)
- **Purpose:** Delegated business data authority on owned applications
- **Key:** Can edit business assessment (B1-B10), lifecycle status, annual licensing cost on assigned apps only

#### Viewer (Read-Only)
- **Scope:** Assigned workspace(s)
- **Table:** `workspace_users.role = 'viewer'`
- **License:** None consumed
- **Purpose:** View all data in assigned workspaces, dashboards, reports
- **Key:** Cannot modify any entity data. **CAN create data quality flags** (governance exception — see Section 7).

#### Restricted
- **Scope:** Assigned portfolio(s) only
- **Tables:** `users.namespace_role = 'restricted'`, `namespace_users.role = 'restricted'`
- **License:** Conditional (editor seat if granted edit via portfolio role)
- **Purpose:** Limited visibility — sees only assigned portfolios, no dashboard
- **Key:** Designed but NOT yet enforced at workspace level (see Section 8)

### 3.3 Naming Inconsistency (Known Debt)

| Concept | workspace_users | contacts | namespace_users / users | invitations |
|---------|----------------|----------|------------------------|-------------|
| View-only | `viewer` | `read_only` | `viewer` | `viewer` |

The `contacts.workspace_role` uses `read_only` where all other tables use `viewer`. This should be standardized to `viewer` in a future migration.

---

## 4. Permission Matrix

### 4.1 Application Management

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Create new application | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Add existing app to portfolio | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Browse & subscribe to shared apps | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Remove app from portfolio | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Unsubscribe from shared app | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete application | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

**Rationale:** Application creation and deletion are structural operations. Admin-only prevents sprawl.

### 4.2 Deployment Profile

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Edit DP (hosting, cloud, region, DR) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Edit annual licensing cost | ✅ | ✅ | ✅ | ✅ | ✅* | ❌ | ❌ |
| Edit lifecycle status | ✅ | ✅ | ✅ | ✅ | ✅* | ❌ | ❌ |

*Steward = assigned applications only

**Rationale:** DP infrastructure fields (hosting, cloud, DR) are technical domain — admin only. Cost and lifecycle are business domain — open to editors and stewards.

### 4.3 Assessments

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Complete technical assessment (T01-T15) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| View technical assessment | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ~portfolio |
| Complete business assessment (B01-B10) | ✅ | ✅ | ✅ | ✅ | ✅* | ❌ | ❌ |
| View business assessment | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ~portfolio |

*Steward = assigned applications only. ~portfolio = within assigned portfolios only.

**Rationale:** Technical assessments require admin authority (infrastructure knowledge). Business assessments are open to business users. This separation enables the "organizational dysfunction detection" pattern — different stakeholders rating the same application reveals disagreements.

### 4.4 Portfolio Management

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Create portfolio | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete portfolio | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Edit portfolio settings | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| View portfolio | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ~assigned |

### 4.5 Publishing (Enterprise Tier)

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Create WorkspaceGroup | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage WorkspaceGroup members | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Publish apps to WorkspaceGroup | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Browse shared apps catalog | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

### 4.6 Data Quality Flags (NEW — Gamification v1.2)

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| View flags | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ~portfolio |
| **Create flag** | ✅ | ✅ | ✅ | ✅ | ✅ | **✅** | ❌ |
| Update flag (reporter/assignee) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Update flag (admin) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete flag | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

**ADR: Flags are exempt from Read-Only RBAC.** A flag is a governance observation, not a data edit. Creating a flag doesn't modify the entity — it raises a sticky note about it. This solves the "person who notices ≠ person who fixes" problem. Without this exception, viewers who spot stale data (wrong owner, retired staff, decommissioned app) have no mechanism to report it. The data stays wrong.

**Restricted users cannot create flags** because they have limited entity visibility and the flag auto-assignment mechanism requires workspace-level contact role lookups.

### 4.7 Other Operations

| Action | Platform Admin | Namespace Admin | Workspace Admin | Workspace Editor | Steward | Viewer | Restricted |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| View dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Export CSV | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ~portfolio |
| Invite users to workspace | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage assessment configuration | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View activity feed | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| View achievement wall | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| View namespace leaderboard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

---

## 5. Tier-to-Feature Mapping

### 5.1 Tier Values (As-Built)

Database constraint: `namespaces_tier_check CHECK (tier IN ('trial','essentials','plus','enterprise'))`

| Tier | DB Value | Annual Price | Purpose |
|------|----------|-------------|---------|
| Trial | `trial` | Free | Prospect evaluation, time/capacity limited |
| Essentials | `essentials` | $15,000 | Core platform, 5 workspaces, 5 editors |
| Plus | `plus` | $30,000 | + SSO, Restricted role, 10 workspaces, 10 editors |
| Enterprise | `enterprise` | $62,500 | + Steward, API, custom analytics, 25 workspaces, 25 editors |

### 5.2 Capacity Limits

| Resource | Trial | Essentials | Plus | Enterprise |
|----------|-------|------------|------|------------|
| Workspaces | 2 | 5 | 10 | 25 |
| Editors | 1 | 5 | 10 | 25 |
| Read-Only Users | Unlimited | Unlimited | Unlimited | Unlimited |
| Applications | 20 | Unlimited | Unlimited | Unlimited |
| Portfolios per Workspace | 3 | 10 | Unlimited | Unlimited |
| CSV Import Rows | 20 | 100 | Unlimited | Unlimited |

### 5.3 Feature Gating by Tier

| Feature | Trial | Essentials | Plus | Enterprise |
|---------|-------|------------|------|------------|
| TIME/PAID Assessment | ✅ | ✅ | ✅ | ✅ |
| Edit DP fields (hosting, cloud, DR) | 🔒 | ✅ | ✅ | ✅ |
| Edit assessment config (questions, weights) | 🔒 | ✅ | ✅ | ✅ |
| Add/remove assessment factors | 🔒 | 🔒 | ✅ | ✅ |
| Multiple DPs per app | 🔒 | 🔒 | ✅ | ✅ |
| SSO (when built) | 🔒 | 🔒 | ✅ | ✅ |
| Restricted role | 🔒 | 🔒 | ✅ | ✅ |
| IT Service Catalog | 🔒 view | ✅ | ✅ | ✅ |
| Software Product Catalog | 🔒 view | ✅ | ✅ | ✅ |
| Cost Model | 🔒 view | ✅ | ✅ | ✅ |
| Technology Health Dashboard | 🔒 view | ✅ | ✅ | ✅ |
| WorkspaceGroups / Publishing | 🔒 | 🔒 | 🔒 | ✅ |
| Steward role | 🔒 | 🔒 | 🔒 | ✅ |
| API Access | 🔒 | 🔒 | 🔒 | ✅ |
| Custom Analytics / White Labeling | 🔒 | 🔒 | 🔒 | ✅ |
| Dedicated CSM | ❌ | ❌ | ❌ | ✅ |

### 5.4 Gamification by Tier

| Feature | Trial | Essentials | Plus | Enterprise |
|---------|-------|------------|------|------------|
| Onboarding achievements | ✅ | ✅ | ✅ | ✅ |
| Data quality achievements | 🔒 | ✅ | ✅ | ✅ |
| View flags | ✅ | ✅ | ✅ | ✅ |
| Create/resolve flags | 🔒 | ✅ | ✅ | ✅ |
| Collaboration achievements | 🔒 | 🔒 | 🔒 | ✅ |
| Namespace leaderboard | 🔒 | 🔒 | 🔒 | ✅ |
| Cross-workspace flag reporting | 🔒 | 🔒 | 🔒 | ✅ |
| Mastery achievements | 🔒 | 🔒 | 🔒 | ✅ |

---

## 6. Steward Model (Derived Permissions)

### 6.1 How Steward Rights Are Granted

Steward is NOT a workspace role. It's derived from contact assignments:

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

### 6.2 Steward Rules

| Rule | Value |
|------|-------|
| Contact types granting Steward | `business_owner`, `steward` (via `application_contacts.role_type`) |
| Max applications as Owner | 10 |
| Max applications as Delegate | Unlimited |
| Max Delegates per Owner | 2 |
| Owner removal cascades | Delegates lose rights |
| Steward available on tier | Enterprise only (all tiers have the schema, Enterprise unlocks the feature) |

### 6.3 Steward Editable Fields

| Field | Steward Can Edit | Rationale |
|-------|:---:|-----------|
| Business Assessment (B1-B10) | ✅ | Business knowledge lives with owners |
| Lifecycle Status | ✅ | Owners know retirement plans |
| Annual Licensing Cost | ✅ | Owners know their budget |
| Vendor Contact | ✅ | Owners manage vendor relationships |
| Application Name/Description | ❌ | Structural — admin only |
| DP Infrastructure Fields | ❌ | Technical domain — admin only |
| Technical Assessment (T01-T15) | ❌ | Technical domain — admin only |
| Portfolio Assignment | ❌ | Structural — admin only |

### 6.4 The Facilitator Pattern

Use case: Bob is the Ministry SME gathering TIME data for 30 applications across 15 owners.

Solution: Bob is Delegate on all 30 applications. He has edit rights on all 30 but counts as 1 Steward license. No limit on Delegate assignments.

---

## 7. RBAC Exceptions

### 7.1 Flag Creation — Viewer Exception

**ADR (Feb 14, 2026):** Data quality flags are exempt from Read-Only RBAC restrictions.

**What:** Any workspace member including Viewers can INSERT into the `flags` table.

**Why:** The "person who notices ≠ person who fixes" problem. A Finance analyst reviewing a portfolio report sees that an application's owner retired six months ago. Without this exception, they can't report it. The data stays wrong.

**Boundary:** Viewers can CREATE flags. They cannot UPDATE or DELETE flags (that requires reporter/assignee/admin). They cannot modify the flagged entity itself.

**RLS Implementation:**
- `flags` SELECT: any workspace member (standard pattern)
- `flags` INSERT: any workspace member (exception — no role check)
- `flags` UPDATE: reporter_id = auth.uid() OR assignee_id = auth.uid() OR workspace admin
- `flags` DELETE: workspace admin or namespace admin only

**Restricted users CANNOT create flags** — their portfolio-scoped visibility makes flag auto-assignment unreliable.

### 7.2 Future Exceptions

No other exceptions are planned. If additional governance-layer tables are added (e.g., comments, annotations), the same "governance observation ≠ data edit" principle should be evaluated case-by-case.

---

## 8. As-Built vs As-Designed Gap Analysis

### 8.1 Schema Ground Truth (Feb 13, 2026 Schema)

| Table | Role Values (CHECK constraint) | Notes |
|-------|-------------------------------|-------|
| `workspace_users.role` | admin, editor, **viewer** | **Only 3 values.** All RLS policies check this. |
| `users.namespace_role` | admin, editor, steward, viewer, restricted | 5 values |
| `namespace_users.role` | admin, editor, steward, viewer, restricted | 5 values |
| `contacts.workspace_role` | admin, editor, steward, **read_only**, restricted | 5 values, uses `read_only` not `viewer` |
| `invitation_workspaces.role` | admin, editor, **viewer** | 3 values (feeds workspace_users) |
| `invitations.namespace_role` | admin, editor, steward, viewer, restricted | 5 values |

### 8.2 RLS Enforcement Patterns (As-Built)

| Operation | RLS Check | Effect |
|-----------|-----------|--------|
| SELECT | Workspace membership (no role check) | All members see all data |
| INSERT | `wu.role IN ('admin','editor')` | Admin + Editor can create |
| UPDATE | `wu.role IN ('admin','editor')` | Admin + Editor can modify |
| DELETE | `wu.role = 'admin'` | Admin only can delete |

Viewer can see everything, change nothing. This is the correct behavior — enforced by omission (viewer doesn't match the INSERT/UPDATE/DELETE checks).

### 8.3 Implementation Gaps

| Feature | Designed In | As-Built | Gap | Priority |
|---------|------------|----------|-----|----------|
| **Steward at workspace level** | identity-security v1.1, Excel matrix | `workspace_users` constraint has no `steward` value. Steward exists only at namespace level and contacts. | YES — workspace_users needs `steward` added OR steward enforcement remains purely UI-level via contact role lookup | Medium — Enterprise tier feature |
| **Restricted at workspace level** | identity-security v1.1, Excel matrix | `workspace_users` constraint has no `restricted` value. Restricted exists at namespace level only. | YES — workspace_users needs `restricted` added with portfolio-scoped SELECT policies | Medium — Plus tier feature |
| **contacts.workspace_role naming** | All other tables use `viewer` | contacts uses `read_only` | YES — rename `read_only` to `viewer` for consistency | Low — cosmetic |
| **UI role gating** | Excel "Implementation Status" shows 13/16 gaps | Phase A complete (Mar 11, 2026): `usePermissions` hook + 13 UI gaps wired. See Section 8.4. | ✅ RESOLVED | High — security |
| **Flag CREATE for viewers** | Gamification v1.2 | Not yet built | Expected — new feature | Phase 1 of gamification |
| **Steward app-scoped edits** | identity-security v1.1 | No app-scoped RLS policies exist. Current INSERT/UPDATE policies check workspace role, not contact assignment. | YES — requires RLS policy changes or UI-only enforcement | Medium |

### 8.4 UI Enforcement Gaps — Phase A Resolution (Mar 11, 2026)

**Implementation:** `src/hooks/usePermissions.ts` — centralized permission hook combining namespace role + workspace role + tier.

**AuthContext changes:** `workspaceRole` and `namespaceRole` now exposed from `AuthContext` (previously only `isWorkspaceAdmin` boolean was available).

| Feature | Required Gating | Resolution | File(s) |
|---------|----------------|------------|---------|
| New Application button | Admin only | ✅ `canCreateApp` | `DashboardPage.tsx` |
| Add Existing App button | Admin only | ✅ `canAddExistingApp` | `DashboardPage.tsx` |
| Browse Shared Apps | Admin + Enterprise tier | ✅ `canBrowseSharedApps` + tier | `DashboardPage.tsx` |
| Publish Apps | Admin + Enterprise tier | Pre-existing `canPublish` tier check | `DashboardPage.tsx` |
| Remove from Portfolio | Admin only | Not yet built (feature pending) | — |
| Unsubscribe | Admin only | Not yet built (feature pending) | — |
| Delete Application | Admin only | Pre-existing `isWorkspaceAdmin` check | `ApplicationPage.tsx` |
| Technical Assessment | Admin only | ✅ `canEditBizAssessment` gates entry | `ApplicationDetailDrawer.tsx` |
| Business Assessment | Admin + Editor + Steward | ✅ `canEditBizAssessment` gates entry | `ApplicationDetailDrawer.tsx` |
| Edit DP fields | Admin only | ✅ `canEditDP` → `isReadOnly` | `ApplicationPage.tsx`, `DeploymentsTab.tsx` |
| Edit Lifecycle/Cost | Admin + Editor + Steward | ✅ `canWrite` → `isReadOnly` | `ApplicationForm.tsx` |
| Manage Portfolios | Admin only | ✅ `canCreatePortfolio` / `canDeletePortfolio` | `PortfoliosSettings.tsx` |
| Roadmap (Initiatives) | Tier + Role | ✅ `canEditRoadmap` | `RoadmapPage.tsx` |
| Roadmap (Ideas) | Tier + Role | ✅ `canEditRoadmap` | `IdeasTab.tsx`, `IdeaDetailDrawer.tsx` |
| Roadmap (Programs) | Tier + Role | ✅ `canEditRoadmap` | `ProgramsTab.tsx`, `ProgramDetailDrawer.tsx` |
| Settings: Software Products | Namespace Admin only | ✅ `canManageSettings` | `SoftwareProductsSettings.tsx` |
| Settings: Technology Catalog | Namespace Admin only | ✅ `canManageSettings` | `TechnologyCatalogSettings.tsx` |
| Settings: IT Services | Namespace Admin only | ✅ `canManageSettings` | `ITServiceCatalogSettings.tsx` |

---

## 9. Resolved Architecture Decisions

These decisions were made during the RBAC design process (originally tracked in archive (superseded by identity-security/rbac-permissions.md) Decisions Log).

| # | Category | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Remove from Portfolio | Workspace Admin only | Structural control belongs to Admin |
| 2 | Remove Last Assignment | Warn about orphaned DP | User should know DP will have no portfolio |
| 3 | Unsubscribe | Workspace Admin only | Structural control belongs to Admin |
| 4 | Technical Assessment | Workspace Admin only | Technical domain requires Admin authority |
| 5 | Business Assessment | Admin + Editor + Steward | Business domain open to business users |
| 6 | Steward App Addition | Steward cannot add apps to portfolio | Structural control belongs to Admin |
| 7 | Steward Subscribe | Steward cannot subscribe to shared apps | Structural control belongs to Admin |
| 8 | Delete Application | Workspace Admin only, must warn about consumer portfolios | Cascading impact requires awareness |
| 9 | Lifecycle Status | Admin + Editor + Steward | Business domain — owners know lifecycle |
| 10 | Portfolio CRUD | Workspace Admin only | Structural control prevents sprawl |
| 11 | Create Application | Workspace Admin only | Prevents sprawl, maintains control |
| 12 | Editor vs Steward | Editor = any app in workspace; Steward = assigned apps only | Steward is delegated authority from Owner |
| 13 | Flag Creation | **Any workspace member including Viewer** (Feb 14, 2026) | Governance observation, not data edit. Solves "person who notices ≠ person who fixes." |
| 14 | Namespace Role UI | **Admin toggle instead of role dropdown** (Mar 12, 2026) | Only 2 of 5 namespace roles active (admin, viewer). Dropdown with 2 options where one is almost always the default adds cognitive load. "Viewer" appearing at both namespace and workspace levels caused confusion. Toggle silently defaults to `viewer`; only surfaces a choice when granting admin. Schema still supports all 5 roles — when delegated authority is needed, toggle converts to role selector. **Prerequisite for delegation:** enforce permission ceiling in `usePermissions` and RLS before activating namespace `editor`. |

---

## 10. Licensing Model

### 10.1 Editor Pool

Editor licenses are pooled at the **namespace level**, not per workspace.

- One person editing in 3 workspaces = 1 editor license (not 3).
- License type derived from highest workspace role across all workspaces.
- Steward does NOT consume an editor license.

### 10.2 Billable Roles

| Role | Billable? | Notes |
|------|-----------|-------|
| Platform Admin | N/A | Internal |
| Namespace Admin | Yes | Always |
| Workspace Admin | Yes | Always |
| Workspace Editor | Yes | If active (logged in within billing period) |
| Steward | No | Derived from contact, not a seat |
| Viewer (Read-Only) | No | Never |
| Restricted (view only) | No | No edit capability |
| Restricted (with edit portfolio role) | Yes | If granted Owner/Contributor at portfolio level |

---

## 11. Implementation Roadmap

### Phase A: UI Role Gating (Priority: HIGH)
Close the 13 UI enforcement gaps from Section 8.4. This is security debt — the RLS layer protects data at the database level, but the UI should not present actions users can't perform.

### Phase B: Workspace Role Expansion (Priority: MEDIUM)
Add `steward` and `restricted` to `workspace_users.role` CHECK constraint. Update `invitation_workspaces.role` to match. Wire the invitation flow to support these roles.

### Phase C: Steward RLS Enforcement (Priority: MEDIUM)
Either add app-scoped RLS policies that check contact role assignments, or formally decide that Steward enforcement is UI-only (with RLS backstop at admin+editor level).

### Phase D: Restricted Portfolio Scoping (Priority: MEDIUM)
Add portfolio-scoped SELECT policies for restricted users. Currently all SELECT policies check workspace membership — restricted users need portfolio-filtered views.

### Phase E: Flag Viewer Exception (Priority: PHASE 1 of Gamification)
Implement the flags table with INSERT policy allowing any workspace member. See features/gamification/architecture.md.

### Phase F: Contact Naming Cleanup (Priority: LOW)
Rename `contacts.workspace_role` value `read_only` → `viewer` for consistency with all other tables.

---

## 12. Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Should Steward enforcement be RLS-level or UI-only? | Open — RLS is more secure but complex (requires contact role joins in every policy) |
| 2 | Should workspace_users support `steward` value, or should steward remain purely derived from contacts? | Open — adding it creates a sync obligation between workspace_users and application_contacts |
| 3 | Should Restricted users see the activity feed? | Decided: No (see gamification v1.2) |
| 4 | Should Restricted users be able to create flags within their assigned portfolios? | Decided: No (auto-assignment unreliable with limited visibility) |
| 5 | Portfolio-level roles (Owner, Contributor, Viewer) — are these still needed alongside workspace roles? | Open — the portfolio role system from identity-security v1.1 is designed but not built |
| 6 | Namespace role as permission ceiling: enforce or remove? | Parked — §3.1 describes namespace role as a ceiling on workspace role, but this is **not enforced** in code. `usePermissions` uses OR logic (`isNamespaceAdmin \|\| isWorkspaceAdmin`), and RLS policies check `workspace_users.role` directly without namespace ceiling. Decision needed: enforce the ceiling when delegation roles are activated, or simplify the model to make namespace role purely about namespace-level admin functions. Revisit when delegation is needed. |

---

## 13. Related Documents

| Document | Relationship |
|----------|-------------|
| identity-security/identity-security.md | Auth, SSO, SOC2 sections still authoritative. RBAC sections (5.1–5.13) superseded by this document. |
| core/involved-party.md | Contact model, Steward derivation from contact roles, namespace-scoped contacts |
| identity-security/rls-policy-addendum.md | Actual RLS enforcement layer — 72 tables, 4-policy pattern |
| marketing/pricing-model.md | Tier pricing and commercial terms |
| features/gamification/architecture.md | Flag RBAC exception, gamification tier gating |
| archive (superseded by identity-security/rbac-permissions.md) | **ARCHIVED** — superseded by this document |
| archive (superseded by identity-security/rbac-permissions.md) | **ARCHIVED** — decisions incorporated into this document |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-14 | Initial version. Consolidated from identity-security v1.1 (RBAC sections), permission-matrix-final.xlsx, and RBAC matrix draft. Added as-built gap analysis from Feb 13 schema. Added flag viewer exception (gamification v1.2 ADR). Added tier mapping using current trial/essentials/plus/enterprise values. Documented naming inconsistency (viewer vs read_only). |
| v1.1 | 2026-03-12 | ADR #14: Namespace role UI simplified to admin toggle. Open Question #6: Permission ceiling not enforced — parked for future delegation work. |

---

*Document: identity-security/rbac-permissions.md*
*Last Updated: March 12, 2026*
*Schema Reference: getinsync-nextgen-schema-2026-02-13.sql*
