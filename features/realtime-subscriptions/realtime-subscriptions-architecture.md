# Realtime Subscriptions Architecture

**Version:** 1.0  
**Date:** March 4, 2026  
**Status:** 🟡 DESIGNED  
**Repo path:** `features/realtime-subscriptions/architecture.md`  
**Prerequisite:** IT Value Creation frontend (IVC Kanban is first consumer)

---

## 1. Overview

GetInSync NextGen uses Supabase Realtime to deliver three categories of live experience:

| Capability | Supabase Feature | Pattern | Use Cases |
|---|---|---|---|
| **Data Sync** | Postgres Changes | Server → Client | Kanban status, assessment scores, cost updates |
| **Presence** | Presence | Client ↔ Client (shared state) | Who's online, active editors, workspace awareness |
| **Messaging** | Broadcast | Client → Client (ephemeral) | Multi-session alerts, view-switch prompts |

These are three distinct Supabase Realtime features exposed through a single WebSocket connection per client. They share a channel but serve different purposes and must be architecturally separated in the frontend.

---

## 2. Infrastructure Status

**Already deployed — no backend work required:**

- `realtime.subscription` table with RLS-aware filtering
- `realtime.messages` table (partitioned) for broadcast persistence
- WAL-based change detection with `realtime.apply_rls()` function
- Publication configuration on public schema tables
- Filter validation via `realtime.subscription_check_filters()`

**Frontend work required:**

- React hooks for each capability (§4)
- Channel naming convention (§3)
- Subscription lifecycle management (§5)
- UI components for presence indicators and session alerts (§7, §8)

---

## 3. Channel Naming Convention

All channels are tenant-scoped to prevent cross-namespace data leakage.

```
Pattern: {scope}:{namespace_id}:{resource}
```

| Channel | Pattern | Example |
|---|---|---|
| Workspace data sync | `ws:{namespace_id}:{workspace_id}` | `ws:abc123:def456` |
| Initiative kanban | `kanban:{namespace_id}:{program_id}` | `kanban:abc123:prog1` |
| Assessment session | `assess:{namespace_id}:{dp_id}` | `assess:abc123:dp789` |
| User presence | `presence:{namespace_id}` | `presence:abc123` |
| User sessions | `session:{user_id}` | `session:user123` |

**Security notes:**

- Namespace ID in every channel name ensures Supabase RLS filters apply correctly
- The `session:{user_id}` channel is the only user-scoped (not namespace-scoped) channel — it tracks a single user's browser sessions across all namespaces
- Presence channels carry no sensitive data — only user ID, display name, current view, and connection metadata

---

## 4. React Hook Architecture

Three hooks, one per capability. All hooks handle subscribe/unsubscribe lifecycle via `useEffect` cleanup.

### 4.1 `useRealtimeSync(table, filters, callback)`

**Purpose:** Subscribe to INSERT/UPDATE/DELETE on a specific table, scoped by filters.

```typescript
// Usage: Kanban board watching initiative status changes
const { isConnected } = useRealtimeSync('initiatives', {
  filter: `program_id=eq.${programId}`,
  event: '*',  // INSERT, UPDATE, DELETE
  schema: 'public'
}, (payload) => {
  // payload.eventType: 'INSERT' | 'UPDATE' | 'DELETE'
  // payload.new: updated row (INSERT/UPDATE)
  // payload.old: previous row (UPDATE/DELETE)
  handleInitiativeChange(payload);
});
```

**Optimistic update pattern:**

1. User drags card → UI updates immediately (setState)
2. Supabase mutation fires (UPDATE initiative.status)
3. Realtime subscription confirms change → no-op (state already correct)
4. If mutation fails → rollback UI to previous state
5. Other users' clients receive the subscription event → update their UI

### 4.2 `usePresence(channelName, userData)`

**Purpose:** Track who's online and what they're looking at.

```typescript
// Usage: Show active users in workspace
const { presentUsers, isConnected } = usePresence(
  `presence:${namespaceId}`,
  {
    userId: currentUser.id,
    displayName: currentUser.display_name,
    avatarUrl: currentUser.avatar_url,
    currentView: 'app-health',      // which tab/page
    currentEntity: dpId || null,      // which DP they're editing
    workspaceId: currentWorkspaceId,
    joinedAt: new Date().toISOString()
  }
);

// presentUsers = Map<userId, { ...userData, onlineAt }>
```

**Presence state updates:** When user navigates (changes tab, opens a DP, switches workspace), call `updatePresence({ currentView, currentEntity, workspaceId })`. This is a lightweight state sync — no database writes.

### 4.3 `useSessionAwareness(userId)`

**Purpose:** Detect when the same user has multiple active browser sessions.

```typescript
// Usage: App shell (runs once, globally)
const { activeSessions, isCurrentPrimary } = useSessionAwareness(
  currentUser.id
);

// activeSessions = [
//   { sessionId: 'abc', device: 'Chrome/Win', ip: '192.168.1.10', 
//     connectedAt: '...', currentView: 'kanban' },
//   { sessionId: 'def', device: 'Safari/Mac', ip: '10.0.0.5',
//     connectedAt: '...', currentView: 'overview' }
// ]
```

This hook uses **both** Presence (to track active sessions) and **Broadcast** (to send cross-session messages like "switch to this view").

---

## 5. Subscription Lifecycle

### 5.1 Connection Management

Each browser tab opens **one** Supabase Realtime WebSocket connection. Multiple channel subscriptions multiplex over that single connection.

```
Browser Tab
  └── WebSocket Connection (1 per tab)
       ├── Channel: presence:{ns_id}          (Presence)
       ├── Channel: session:{user_id}         (Presence + Broadcast)
       ├── Channel: ws:{ns_id}:{ws_id}        (Postgres Changes)
       └── Channel: kanban:{ns_id}:{prog_id}  (Postgres Changes)
```

### 5.2 Subscribe/Unsubscribe Rules

| Event | Action |
|---|---|
| Component mount | Subscribe to relevant channels |
| Component unmount | Unsubscribe (useEffect cleanup) |
| Workspace switch | Unsubscribe old `ws:` channel, subscribe new |
| Tab/browser close | Automatic cleanup (WebSocket disconnect) |
| Network interruption | Supabase client auto-reconnects with exponential backoff |
| Token refresh | Supabase JS client handles re-auth transparently |

### 5.3 Performance Budget

| Metric | Target | Rationale |
|---|---|---|
| Max channels per tab | 5 | Workspace data + kanban + presence + session + 1 reserve |
| Max concurrent subscribers per namespace | 200 | Supabase Pro plan limit; Free = 200, Team/Enterprise = higher |
| Presence heartbeat interval | 30s | Supabase default; sufficient for "who's online" |
| Stale presence timeout | 60s | After 2 missed heartbeats, consider user offline |

---

## 6. Use Case Specifications

### 6.1 Initiative Kanban — Data Sync (Priority: P1 — build with IVC frontend)

**Tables watched:** `initiatives`  
**Channel:** `kanban:{namespace_id}:{program_id}`  
**Events:** UPDATE (status column drives kanban columns)

| Status Value | Kanban Column |
|---|---|
| `identified` | Identified |
| `planned` | Planned |
| `in_progress` | In Progress |
| `completed` | Completed |

**Behavior:**

- User A drags initiative from "Planned" to "In Progress"
- Optimistic update: User A's UI updates immediately
- Supabase mutation: `UPDATE initiatives SET status = 'in_progress' WHERE id = ...`
- Realtime event fires to all subscribers on that program's channel
- User B's kanban re-renders with card in new column
- If mutation fails: User A's card snaps back to original column with toast error

**Conflict handling:** Last-write-wins. If two users drag the same card simultaneously, the second mutation overwrites the first and both clients converge on the final state via the subscription event.

### 6.2 Assessment Progress — Data Sync (Priority: P2)

**Tables watched:** `deployment_profiles` (score columns b1–b10, t01–t15)  
**Channel:** `ws:{namespace_id}:{workspace_id}`  
**Events:** UPDATE

**Behavior:**

- User A is scoring DP "Quickbooks Online" on factor B3
- User B is scoring the same DP on factor T07
- Both see each other's scores appear in real time
- Dashboard aggregate scores (TIME quadrant position) recalculate on each received event

**Conflict handling:** Factor-level granularity. Two users scoring different factors = no conflict. Two users scoring the same factor = last-write-wins with visual indicator ("Score updated by [name]" toast).

### 6.3 Cost Model Updates — Data Sync (Priority: P3)

**Tables watched:** `dp_software_products`, `dp_it_services`, `cost_bundles`  
**Channel:** `ws:{namespace_id}:{workspace_id}`  
**Events:** INSERT, UPDATE, DELETE

**Behavior:**

- Workspace admin updates a software product annual cost
- Run rate views (vw_run_rate_by_vendor, vw_run_rate_by_app) reflect change on all open dashboards without page reload

**Note:** This requires the dashboard components to refetch their view data when a cost table mutation event is received — not a direct subscription to the view itself (views aren't subscribable).

### 6.4 Activity Feed — Data Sync (Priority: P4, depends on Gamification build)

**Tables watched:** `audit_logs`  
**Channel:** `ws:{namespace_id}:{workspace_id}`  
**Events:** INSERT

**Behavior:**

- New audit log entry triggers activity feed update
- Achievement engine evaluates new entry → if achievement unlocked, INSERT to `gamification_user_progress`
- Second subscription event fires → achievement toast appears

---

## 7. Presence UI Specification

### 7.1 Workspace Presence Bar

**Location:** Workspace banner area (right side)  
**Shows:** Avatar stack of users currently in this workspace  
**Max visible:** 5 avatars + "+N" overflow  
**Click:** Expands to show full list with current view per user

```
[ Overview | App Health | Tech Health | Roadmap ]
                                          [👤👤👤 +2 online]
```

### 7.2 Entity-Level Editing Indicators

**Location:** Deployment profile detail view, initiative detail view  
**Shows:** When another user is currently viewing/editing the same entity  
**Display:** "[Name] is viewing this" banner below the entity header  
**Color:** Amber warning band (not blocking — informational only)

### 7.3 Presence Data Shape

```typescript
interface PresenceState {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  currentView: 'overview' | 'app-health' | 'tech-health' | 'roadmap' | 'ivc' | 'settings';
  currentEntity: string | null;  // DP ID, initiative ID, etc.
  workspaceId: string;
  joinedAt: string;  // ISO timestamp
}
```

---

## 8. Multi-Session Awareness Specification

### 8.1 Problem Statement

A user opens GetInSync on their office desktop, then later opens it on their laptop at home. Both sessions are valid (Supabase Auth allows concurrent sessions — `auth.sessions` tracks each with `user_agent` and `ip`). The user may not realize they have two active sessions, or they may want to "continue where I left off" on the new device.

### 8.2 Detection Pattern

Uses `session:{user_id}` channel with **Presence** to track active tabs.

Each tab announces itself on mount:

```typescript
{
  sessionId: crypto.randomUUID(),       // unique per tab
  device: navigator.userAgent,          // parsed to "Chrome/Win" etc.
  ip: null,                             // populated via lightweight /api/ip endpoint or Supabase edge function
  currentView: 'kanban',
  currentWorkspaceId: 'ws_abc',
  connectedAt: new Date().toISOString()
}
```

When a **second session joins** the channel, both sessions receive the presence sync event.

### 8.3 User Experience

**New session opens (second device/browser):**

1. New tab detects existing session(s) via presence state
2. Toast notification appears (non-blocking):  
   _"You're also signed in on Chrome/Windows. [Switch to that view] [Dismiss]"_
3. "Switch to that view" sends a **Broadcast** message to the other session with the current view context
4. Receiving session shows toast:  
   _"Your other session wants to switch you to Kanban view. [Go there] [Ignore]"_

**Session closes:**

- Presence automatically removes the session on WebSocket disconnect
- No explicit "logout other sessions" — that's a security feature, not a Realtime feature
- If needed later: Supabase Auth's `signOut({ scope: 'others' })` handles forced logout of other sessions

### 8.4 Broadcast Message Schema

```typescript
interface SessionBroadcast {
  type: 'switch_view' | 'ping' | 'force_refresh';
  from: {
    sessionId: string;
    device: string;
  };
  payload: {
    targetView?: string;
    targetWorkspaceId?: string;
    targetEntityId?: string;
    message?: string;
  };
}
```

### 8.5 Edge Cases

| Scenario | Behavior |
|---|---|
| 3+ sessions active | Toast shows count: "You have 2 other active sessions" |
| Same device, two tabs | Still detected (different sessionId per tab), but lower priority notification |
| VPN changes IP mid-session | No impact — session tracked by sessionId, not IP |
| Offline → reconnect | Supabase re-establishes presence automatically |
| User on Free tier | Session awareness still works — this is client-side only, no DB cost |

---

## 9. Implementation Priority

| Phase | Use Case | Hook | Depends On | Effort |
|---|---|---|---|---|
| **P1** | Initiative Kanban sync | `useRealtimeSync` | IVC frontend build | S — ~30 lines per subscribed component |
| **P2** | Workspace presence bar | `usePresence` | P1 (proves the pattern) | M — new UI component + hook |
| **P3** | Assessment live scoring | `useRealtimeSync` | P1 hook exists | S — reuse hook, wire to assessment modal |
| **P4** | Multi-session awareness | `useSessionAwareness` | P2 (presence hook exists) | M — broadcast logic + toast UX |
| **P5** | Cost model live refresh | `useRealtimeSync` | P1 hook exists | S — reuse hook, wire to dashboard refetch |
| **P6** | Activity feed push | `useRealtimeSync` | Gamification build (Phase 22+) | S — reuse hook |

**P1 ships with IVC frontend. P2–P4 are polish-phase candidates. P5–P6 depend on other features.**

---

## 10. What NOT to Use Realtime For

| Scenario | Why Not | Instead |
|---|---|---|
| Overview/App Health/Tech Health dashboards | Read-heavy, viewed periodically | Refetch on focus (`visibilitychange` event) |
| Global Search results | One-shot queries, not persistent views | Standard RPC call |
| Settings/admin pages | Low frequency, single-user context | Normal CRUD |
| Report generation / CSV export | Batch operation, not streaming | Edge function or client-side |
| Audit log history view | Historical data, not live stream | Paginated query |

**Principle:** Subscribe to tables where **multiple users modify data concurrently** and other users need to see those changes within seconds. Everything else uses standard fetch patterns.

---

## 11. Security Considerations

| Concern | Mitigation |
|---|---|
| Cross-namespace data leakage | Namespace ID in every channel name; Supabase Realtime enforces RLS on Postgres Changes |
| Presence data exposure | Only display name + current view — no sensitive data in presence state |
| Broadcast spoofing | Broadcast messages are ephemeral and informational only; no mutations triggered by broadcast |
| Channel enumeration | Channel names require namespace_id which is UUID — not guessable |
| Connection flooding | Supabase rate limits WebSocket connections per project; monitor via dashboard |

---

## 12. Supabase Realtime Publication Setup

**Verification query** (run in Supabase SQL Editor to confirm tables are published):

```sql
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

**Tables to add to publication** (if not already present):

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE 
  public.initiatives,
  public.deployment_profiles,
  public.dp_software_products,
  public.dp_it_services,
  public.cost_bundles,
  public.audit_logs;
```

**Note:** Only add tables that will have active subscriptions. Every published table generates WAL overhead on every write, even if no one is listening.

---

## 13. Testing Strategy

| Test | Method |
|---|---|
| Subscription receives events | Two browser tabs, same workspace — mutate in one, observe in other |
| RLS enforcement | Two users in different namespaces — confirm no cross-tenant events |
| Presence join/leave | Open/close tabs, verify presence list updates within 30s |
| Multi-session detection | Open on two browsers/devices, verify toast appears |
| Optimistic rollback | Simulate mutation failure (e.g., RLS deny), verify UI reverts |
| Reconnection | Kill network briefly, verify auto-reconnect and state resync |
| Channel cleanup | Navigate away from Kanban, verify channel unsubscribed (browser devtools → WS frames) |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-03-04 | Initial architecture. Three capabilities (Data Sync, Presence, Session Awareness). Six use cases prioritized. React hook architecture. Channel naming convention. |
