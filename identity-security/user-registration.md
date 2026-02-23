# GetInSync NextGen — User Registration & Invitation Architecture

**Version:** 1.0  
**Date:** February 9, 2026  
**Status:** 🟢 AS-BUILT | Last validated: 2026-02-09  
**Stack:** Supabase Auth + PostgreSQL | Netlify | React + TypeScript  
**SOC2 Controls:** CC6.1 (Logical Access), CC6.6 (Audit Logging), C1.1 (Tenant Isolation)

---

## 1. Overview

GetInSync NextGen supports two user registration paths:

| Path | Trigger | Result |
|------|---------|--------|
| **Self-Signup** | User registers directly at /signup | New namespace + workspace + user created |
| **Invitation Signup** | User clicks invite link /signup?token=xxx | User joins existing namespace + assigned workspaces |

Both paths use Supabase Auth for credential management (email/password) with PostgreSQL triggers and RPC functions handling the business logic.

---

## 2. Self-Signup Flow

**Route:** `/signup` (no token parameter)

```
┌─────────────┐     ┌──────────────┐     ┌────────────────────────┐
│  User fills  │────▶│ Supabase Auth │────▶│ handle_new_user()      │
│  signup form │     │ signUp()      │     │ trigger fires          │
└─────────────┘     └──────────────┘     └────────────────────────┘
                                                    │
                          ┌─────────────────────────┼─────────────────────────┐
                          ▼                         ▼                         ▼
                   ┌──────────────┐    ┌───────────────────┐    ┌──────────────────┐
                   │ CREATE       │    │ CREATE             │    │ CREATE           │
                   │ namespace    │    │ workspace          │    │ users record     │
                   │ (free tier)  │    │ ("General")        │    │ (admin role)     │
                   └──────────────┘    └───────────────────┘    └──────────────────┘
                                                                        │
                                                                        ▼
                                                               ┌──────────────────┐
                                                               │ CREATE           │
                                                               │ workspace_users  │
                                                               │ (admin role)     │
                                                               └──────────────────┘
```

### 2.1 Trigger: handle_new_user()

**Type:** AFTER INSERT on auth.users  
**Security:** SECURITY DEFINER (runs as postgres, bypasses RLS)

**Logic:**
1. Extract email from `NEW.email`
2. Generate organization name from email domain (e.g., `acme.com` → `Acme`)
3. Generate slug from org name + first 8 chars of user UUID
4. INSERT into `namespaces` (name, slug, tier='free')
5. INSERT into `workspaces` (namespace_id, name='General', is_default=true)
6. INSERT into `users` (id=auth.uid, namespace_id, email, name, namespace_role='admin')
7. INSERT into `workspace_users` (workspace_id, user_id, role='admin')

**Result:** User is immediately the admin of their own namespace with one default workspace.

### 2.2 Self-Signup Data Created

| Table | Record | Details |
|-------|--------|---------|
| auth.users | Auth credential | Supabase managed |
| namespaces | New namespace | Free tier, name from email domain |
| workspaces | "General" | Default workspace, is_default=true |
| users | User profile | namespace_role='admin' |
| workspace_users | Membership | role='admin' in General workspace |

---

## 3. Invitation Signup Flow

**Route:** `/signup?token=<hex_token>`

### 3.1 Flow Diagram

```
┌────────────────────┐
│ PHASE 1: CREATE    │     Platform admin or namespace admin
│ (Admin action)     │     creates invitation via Super Admin UI
└────────┬───────────┘
         │
         ▼
┌────────────────────┐     ┌─────────────────────────────────┐
│ provision_namespace│────▶│ INSERT invitations               │
│ () RPC             │     │   namespace_id, email, name,     │
│                    │     │   namespace_role, token,          │
│ — OR —             │     │   expires_at (7 days)            │
│                    │     ├─────────────────────────────────┤
│ Manual invitation  │     │ INSERT invitation_workspaces     │
│ via UI             │     │   workspace_id, role             │
└────────────────────┘     └─────────────────────────────────┘
                                        │
                                        ▼
                           ┌─────────────────────────────────┐
                           │ Email/link sent to invitee:     │
                           │ nextgen.getinsync.ca/signup     │
                           │   ?token=<hex_token>            │
                           └─────────────────────────────────┘

┌────────────────────┐
│ PHASE 2: LOAD PAGE │     Invitee opens link (unauthenticated)
│ (Anon user)        │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐     ┌─────────────────────────────────┐
│ Frontend calls     │────▶│ get_invitation_details(token)   │
│ RPC (anon-safe)    │     │ SECURITY DEFINER                │
│                    │     │ Returns: namespace_name, email,  │
│                    │     │   name, role, invited_by,        │
│                    │     │   expires_at, status             │
└────────────────────┘     └─────────────────────────────────┘
                                        │
                                        ▼
                           ┌─────────────────────────────────┐
                           │ Signup page displays:           │
                           │  "You've been invited to join   │
                           │   Government of Saskatchewan"   │
                           │  Pre-filled: name, email        │
                           └─────────────────────────────────┘

┌────────────────────┐
│ PHASE 3: REGISTER  │     Invitee creates account
│ (Auth + accept)    │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐     ┌─────────────────────────────────┐
│ Supabase Auth      │────▶│ handle_new_user() fires         │
│ signUp()           │     │ Creates namespace + workspace    │
│                    │     │ (temporary — gets overwritten)   │
└────────────────────┘     └─────────────────────────────────┘
         │
         ▼
┌────────────────────┐     ┌─────────────────────────────────┐
│ Frontend calls     │────▶│ accept_invitation(token) RPC    │
│ accept_invitation  │     │ SECURITY DEFINER                │
│                    │     │                                  │
│                    │     │ 1. Validate token (pending,      │
│                    │     │    not expired)                  │
│                    │     │ 2. UPDATE users: set namespace_id│
│                    │     │    + namespace_role from invite  │
│                    │     │ 3. INSERT namespace_users        │
│                    │     │ 4. INSERT workspace_users        │
│                    │     │    (from invitation_workspaces)  │
│                    │     │ 5. UPDATE invitation status      │
│                    │     │    = 'accepted'                  │
└────────────────────┘     └─────────────────────────────────┘
```

### 3.2 Token Security

| Property | Value |
|----------|-------|
| Generation | `encode(gen_random_bytes(32), 'hex')` — 64 hex characters |
| Storage | `invitations.token` column |
| Expiry | 7 days from creation (`now() + interval '7 days'`) |
| Single-use | Status changes to 'accepted' on use |
| Lookup | Via `get_invitation_details()` SECURITY DEFINER RPC |
| Anon access | RPC is executable by anon role — no direct table access |

### 3.3 RPC: get_invitation_details(token)

**Purpose:** Allow unauthenticated users to load invitation details on the signup page.  
**Security:** SECURITY DEFINER — bypasses RLS, runs as postgres.  
**Access:** GRANT EXECUTE to both `anon` and `authenticated`.

**Returns:**
```json
{
  "invitation_id": "uuid",
  "email": "user@example.com",
  "name": "Invited User Name",
  "namespace_name": "Government of Saskatchewan",
  "namespace_id": "uuid",
  "namespace_role": "member",
  "invited_by": "Admin Name",
  "expires_at": "2026-02-15T23:33:20Z",
  "status": "pending"
}
```

**Validation:** Only returns data for `status = 'pending'` AND `expires_at > now()`. Returns empty `{}` for invalid/expired tokens.

**Why not direct table access?** The `anon` role has no GRANT on `namespace_users`, `invitations`, or `namespaces`. Granting anon access to these tables would be a security hole. The RPC exposes only the minimum data needed for the signup page.

### 3.4 RPC: accept_invitation(token)

**Purpose:** Associate a newly registered user with the invited namespace.  
**Security:** SECURITY DEFINER — bypasses RLS.  
**Access:** Authenticated users only.

**Steps:**
1. Look up invitation by token — validate `status = 'pending'` and `expires_at > now()`
2. UPDATE `users` — set `namespace_id` and `namespace_role` from invitation
3. INSERT into `namespace_users` — with invitation role (ON CONFLICT updates role)
4. INSERT into `workspace_users` — from `invitation_workspaces` junction table
5. UPDATE invitation — set `status = 'accepted'`

**Returns:**
```json
{
  "success": true,
  "namespace_id": "uuid",
  "workspace_count": 2
}
```

### 3.5 Known Issue: Orphaned Self-Signup Namespace

When an invited user registers, `handle_new_user()` fires first and creates a temporary namespace. Then `accept_invitation()` overwrites the user's namespace_id. The temporary namespace + workspace remain as orphans.

**Impact:** Low — orphaned namespaces are empty (no apps, no data).  
**Detection:** SOC2 evidence RPC checks `orphaned_records` count.  
**Future fix:** Modify `handle_new_user()` to check for pending invitation before creating a namespace, or clean up orphans in `accept_invitation()`.

---

## 4. Invitation Lifecycle

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ PENDING  │────▶│ ACCEPTED │     │ EXPIRED  │
│          │     │          │     │          │
│ Created  │     │ User     │     │ 7 days   │
│ by admin │     │ signed   │     │ passed   │
│          │     │ up       │     │          │
└──────────┘     └──────────┘     └──────────┘
     │                                  ▲
     └──────────────────────────────────┘
              (automatic expiry)
```

| Status | Meaning | Transition |
|--------|---------|------------|
| pending | Invitation sent, awaiting signup | Created by admin |
| accepted | User registered and joined namespace | accept_invitation() RPC |
| expired | Token passed 7-day window | Checked at query time (expires_at > now()) |

**Note:** Expiry is checked at query time, not via a cron job. The `get_invitation_details()` RPC filters on `expires_at > now()`, so expired tokens simply return empty results.

---

## 5. Database Tables

### 5.1 invitations

| Column | Type | Default | Constraints |
|--------|------|---------|-------------|
| id | uuid | gen_random_uuid() | PK |
| namespace_id | uuid | — | FK → namespaces, NOT NULL |
| email | text | — | NOT NULL |
| name | text | — | Nullable |
| namespace_role | text | 'member' | CHECK: admin, member, viewer |
| invited_by | uuid | — | FK → users, NOT NULL |
| status | text | 'pending' | CHECK: pending, accepted, expired |
| token | text | encode(gen_random_bytes(32), 'hex') | NOT NULL, unique |
| created_at | timestamptz | now() | — |
| expires_at | timestamptz | now() + 7 days | — |

### 5.2 invitation_workspaces

| Column | Type | Default | Constraints |
|--------|------|---------|-------------|
| id | uuid | gen_random_uuid() | PK |
| invitation_id | uuid | — | FK → invitations, NOT NULL |
| workspace_id | uuid | — | FK → workspaces, NOT NULL |
| role | text | 'editor' | CHECK: admin, editor, viewer |

### 5.3 RLS on invitations

| Policy | Command | Logic |
|--------|---------|-------|
| Users can view invitations in current namespace | SELECT | namespace_id = get_current_namespace_id() OR platform admin |
| Admins can insert invitations in current namespace | INSERT | platform admin OR namespace admin |
| Admins can update invitations in current namespace | UPDATE | platform admin OR namespace admin |
| Admins can delete invitations in current namespace | DELETE | platform admin OR namespace admin |

**Anon access:** None. Anon users use `get_invitation_details()` RPC only.

---

## 6. RPC Functions Summary

| Function | Security | Caller | Purpose |
|----------|----------|--------|---------|
| provision_namespace() | DEFINER | Platform admin (authenticated) | Creates namespace + workspace + invitation in one call |
| get_invitation_details(token) | DEFINER | Anon or authenticated | Load invitation info for signup page |
| accept_invitation(token) | DEFINER | Authenticated (new user) | Join namespace + workspaces from invitation |
| handle_new_user() | DEFINER | Trigger (auth.users INSERT) | Auto-create namespace + workspace for self-signup |

---

## 7. SOC2 Compliance Notes

### CC6.1 — Logical Access

- All user accounts created through Supabase Auth (email/password)
- Invitation tokens are cryptographically random (32 bytes, hex-encoded)
- Tokens expire after 7 days
- Tokens are single-use (status changes to 'accepted')
- Role assignment controlled by invitation (not user-selected)
- Namespace isolation enforced by RLS from first login

### CC6.6 — Audit Logging

- `invitations` table has audit trigger (`audit_invitations`)
- `invitation_workspaces` table has audit trigger
- `users` table has audit trigger
- `namespace_users` table has audit trigger
- All INSERT/UPDATE/DELETE operations logged with user_id, timestamp, old/new values
- Invitation acceptance is traceable: invitation status change + user namespace assignment

### C1.1 — Tenant Isolation

- New self-signup users are immediately isolated in their own namespace
- Invited users are scoped to the inviting namespace
- No cross-namespace data leakage possible via RLS
- The orphaned namespace from invitation signup is empty (no data exposure risk)

### Access Review Evidence

Track invitation lifecycle for quarterly access reviews:

```sql
-- All accepted invitations in last 90 days
SELECT i.email, i.name, i.namespace_role, n.name as namespace_name,
       i.created_at, i.status, u.name as invited_by_name
FROM invitations i
JOIN namespaces n ON n.id = i.namespace_id
LEFT JOIN users u ON u.id = i.invited_by
WHERE i.status = 'accepted'
  AND i.created_at > now() - interval '90 days'
ORDER BY i.created_at DESC;

-- Pending invitations (should be reviewed/expired)
SELECT i.email, i.name, n.name as namespace_name,
       i.created_at, i.expires_at,
       CASE WHEN i.expires_at < now() THEN 'EXPIRED' ELSE 'ACTIVE' END as actual_status
FROM invitations i
JOIN namespaces n ON n.id = i.namespace_id
WHERE i.status = 'pending'
ORDER BY i.created_at DESC;
```

---

## 8. Frontend Routes

| Route | Auth Required | Component | Purpose |
|-------|--------------|-----------|---------|
| /signup | No | Signup | Self-signup (no token) |
| /signup?token=xxx | No | Signup | Invitation signup (with token) |
| /login | No | Login | Existing user login |

**Signup page behavior:**
- If `token` param present → call `get_invitation_details()` → show org name, pre-fill email/name
- If no `token` → standard self-signup form
- After registration → if token present, call `accept_invitation()` → redirect to dashboard
- After registration → if no token, redirect to dashboard (namespace already created by trigger)

---

## 9. Bug Fix Log

### Feb 9, 2026 — 403 on Invitation Signup Page

**Symptom:** Unauthenticated user opening `/signup?token=xxx` gets `permission denied for table namespace_users` (42501).

**Root Cause:** Frontend was querying `namespace_users` table directly to load invitation context. The `anon` role has no GRANT on this table (by design).

**Fix:**
1. Created `get_invitation_details(token)` SECURITY DEFINER RPC
2. Granted EXECUTE to `anon` and `authenticated`
3. Frontend updated to call RPC instead of direct table query

**RLS Lesson:** Signup/invitation pages run as `anon` — they must never query tables directly. All pre-auth data access must go through SECURITY DEFINER RPCs that expose only the minimum required data.

---

## 10. Future Enhancements

| Enhancement | Priority | Notes |
|-------------|----------|-------|
| Invitation resend | Medium | Regenerate token, reset expires_at |
| Invitation cancel | Medium | Set status = 'expired' manually |
| Bulk invite (CSV) | Low | Enterprise tier — import user list |
| OAuth signup | Medium | Google/Microsoft sign-in creates account |
| Orphan cleanup | Low | Delete empty namespaces from invitation signups |
| Email notification | Medium | Send actual email (currently manual link sharing) |
| Invitation expiry cron | Low | Background job to mark expired invitations |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-09 | Initial as-built documentation. Both signup paths documented. get_invitation_details() RPC added. 403 bug fix documented. SOC2 compliance notes added. |

---

*Document: identity-security/user-registration.md*  
*February 2026*
