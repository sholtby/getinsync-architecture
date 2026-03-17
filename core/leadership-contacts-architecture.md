# Workspace & Portfolio Leadership Contacts

**Version:** 1.0
**Date:** 2026-03-16
**Status:** 🟡 DESIGNED — awaiting implementation
**Location:** `core/leadership-contacts.md`
**Depends on:** contacts table (deployed), application_contacts pattern (deployed)

---

## Problem

NextGen has accountability at the application level (`application_contacts` with business_owner, technical_owner, steward roles) but no concept of leadership at the workspace or portfolio level. There's no way to express:

- "Matt Watson (ACM) is accountable for everything in Financial Services"
- "Allyson Steadman (CFO) leads the Finance portfolio"
- "Deputy Minister of Justice leads the Ministry of Justice workspace"

`workspace_users` handles RBAC (who can see/edit) but not governance (who is responsible).

**Real-world impact:** City of Garland's org chart has clear leadership hierarchy — ACMs own workspaces, Managing Directors own departments (portfolios), Directors own sub-departments. Government of Saskatchewan has Ministers → Deputy Ministers → ADMs → Directors. Without leadership contacts, this governance structure is invisible in the platform.

---

## Solution

Extend the existing `application_contacts` junction pattern to workspace and portfolio scopes.

### New Tables

#### `workspace_contacts`

```sql
CREATE TABLE public.workspace_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    contact_id uuid NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    role_type text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT workspace_contacts_pkey PRIMARY KEY (id),
    CONSTRAINT workspace_contacts_unique UNIQUE (workspace_id, contact_id, role_type),
    CONSTRAINT workspace_contacts_role_check CHECK (role_type = ANY (ARRAY[
        'leader'::text,
        'business_owner'::text,
        'technical_owner'::text,
        'steward'::text,
        'budget_owner'::text,
        'sponsor'::text,
        'other'::text
    ]))
);
```

#### `portfolio_contacts`

```sql
CREATE TABLE public.portfolio_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    portfolio_id uuid NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
    contact_id uuid NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    role_type text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT portfolio_contacts_pkey PRIMARY KEY (id),
    CONSTRAINT portfolio_contacts_unique UNIQUE (portfolio_id, contact_id, role_type),
    CONSTRAINT portfolio_contacts_role_check CHECK (role_type = ANY (ARRAY[
        'leader'::text,
        'business_owner'::text,
        'technical_owner'::text,
        'steward'::text,
        'budget_owner'::text,
        'sponsor'::text,
        'other'::text
    ]))
);
```

### Role Types

| Role | Meaning | Example (Garland) | Example (GoS) |
|---|---|---|---|
| `leader` | Executive accountable for this scope | Matt Watson (ACM) on Financial Services WS | Deputy Minister on Ministry WS |
| `business_owner` | Day-to-day business authority | Allyson Steadman (CFO) on Finance portfolio | ADM on Courts & Tribunals portfolio |
| `technical_owner` | Technical authority | Justin Fair (CIO) on IT workspace | CIO on Shared Services workspace |
| `steward` | Data quality / ongoing maintenance | Analyst assigned to maintain the portfolio | Portfolio coordinator |
| `budget_owner` | Financial accountability | CFO on Finance portfolio | ADM with budget authority |
| `sponsor` | Executive sponsor (advisory) | City Manager on cross-cutting initiatives | Minister |
| `other` | Freeform | — | — |

### Design Decisions

1. **Junction table, not FK.** A workspace can have multiple leaders (a business leader and a technical leader). A single `leader_contact_id` FK would be too restrictive.

2. **Same role_type vocabulary as `application_contacts`** plus `leader` and `budget_owner`. The `leader` role is new — it means "the person whose name would appear on this scope in an org chart." Keeping the vocabulary aligned means the same UI components can render contacts at all three scopes.

3. **`is_primary` flag.** When a workspace has multiple contacts with the same role (e.g., two stewards), `is_primary` identifies the default/primary one for display purposes.

4. **Contacts, not users.** These reference the `contacts` table, not `users` or `workspace_users`. A leader may not have a login — they're a governance contact, not necessarily a platform user. This is consistent with `application_contacts`.

5. **Cascade delete.** If a workspace or portfolio is deleted, the leadership assignments go with it. If a contact is deleted, their assignments are removed.

---

## UI Impact

### Workspace Settings

Add a "Leadership" section to workspace settings showing assigned contacts by role. Simple table: Name | Role | Primary | Actions (add/remove).

### Portfolio Detail

Add a "Leader" display to portfolio headers — show the primary leader contact name and title inline, similar to how application detail shows business owner.

### Dashboard / Overview

Optionally show workspace leader name in workspace cards or breakdown tables. Low priority for initial implementation.

### Navigation / Breadcrumbs

No immediate impact. Future: could show "Financial Services (Matt Watson)" in workspace picker.

---

## Security

### RLS Policies

Follow the 4-policy pattern:

```
workspace_contacts_select: workspace members can read (via workspace_users join)
workspace_contacts_insert: workspace admins only
workspace_contacts_update: workspace admins only
workspace_contacts_delete: workspace admins only

portfolio_contacts_select: workspace members can read (portfolio → workspace → workspace_users)
portfolio_contacts_insert: workspace admins only
portfolio_contacts_update: workspace admins only
portfolio_contacts_delete: workspace admins only
```

### GRANTs

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON workspace_contacts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON workspace_contacts TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON portfolio_contacts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON portfolio_contacts TO service_role;
```

### Audit Triggers

Add audit triggers on both tables (standard pattern from existing `application_contacts`).

---

## Reorg Resilience — Future Consideration

Leadership contacts are cheap to change — swapping a person on a workspace or portfolio is a single junction row update. The fragility risk isn't here. It's in the structural operations underneath: moving apps between workspaces, merging departments, splitting portfolios during a reorganization.

**Current state:** Workspace and portfolio restructuring (moving apps, merging workspaces, reassigning portfolios) is a **backend operation** performed by Stuart or Delta via SQL. This is appropriate for the current customer base and maturity level. Customers request a reorg, we execute it.

**What a reorg requires today (SQL):**
- Update `applications.workspace_id` for affected apps
- Update `deployment_profiles.workspace_id` for associated DPs
- Reassign `portfolio_assignments` to new portfolios
- Update `workspace_contacts` and `portfolio_contacts` to reflect new leadership
- Verify RLS still grants correct access post-move

**Future self-service features (not in scope for v1.0):**

| Feature | What It Does | When |
|---|---|---|
| Move Application | UI function to move an app + its DPs between workspaces atomically | Open item #(TBD) |
| Merge Workspace | Move all apps from workspace A → B, reassign portfolios, archive A | Future |
| Reassign Portfolio | Move a portfolio (and its app assignments) to a different workspace | Future |
| Bulk Reassign | Select multiple apps and move to a new workspace/portfolio in one operation | Future |

These are workspace administration tools that would make reorgs self-service. They don't block the leadership contacts feature — they complement it. Leadership contacts tell you *who* is accountable. The move tools let you restructure *what* they're accountable for.

**Design principle:** Leadership contacts should never make reorgs harder. The junction table pattern ensures they don't — deleting or reassigning contacts has zero impact on the app/DP/portfolio data underneath.

---

## Schema Impact

| Change | Type | Tables Affected |
|---|---|---|
| New table `workspace_contacts` | CREATE TABLE | +1 table |
| New table `portfolio_contacts` | CREATE TABLE | +1 table |
| RLS policies (8 total) | CREATE POLICY | +8 policies |
| Audit triggers (2) | CREATE TRIGGER | +2 triggers |
| GRANTs (4) | GRANT | — |
| pgTAP update | UPDATE | Plan count +2 tables, +2 triggers |

No changes to existing tables. No migration needed.

---

## Implementation Estimate

| Task | Effort |
|---|---|
| Schema (2 tables + RLS + triggers + GRANTs) | 1 hour (Stuart, SQL Editor) |
| TypeScript types | 15 min (Claude Code) |
| Workspace settings UI (leadership section) | 2-3 hours (Claude Code) |
| Portfolio header leader display | 1 hour (Claude Code) |
| pgTAP test updates | 30 min (Stuart) |
| **Total** | **~5 hours** |

---

## Garland Import Usage

With these tables deployed, the Garland showcase import adds:

| Workspace | Leader Contact | Role |
|---|---|---|
| Financial Services | Matt Watson | leader |
| Financial Services | Allyson Steadman | budget_owner |
| Public Safety & Administration | Phillip Urrutia | leader |
| Public Safety & Administration | Kevin Slay | business_owner |
| Public Safety - Police | Jeff Bryan | leader |
| Information Technology | Justin Fair | leader |

| Portfolio | Leader Contact | Role |
|---|---|---|
| Finance | Allyson Steadman | leader |
| Budget & Research | Allyson Steadman | leader |
| Utility CIS & Revenue | Kevin Slay | leader |

This makes the org chart visible in the platform without baking person names into workspace names.

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-03-16 | Initial design. Triggered by City of Garland import — need to represent org chart leadership hierarchy without person-named workspaces. |
