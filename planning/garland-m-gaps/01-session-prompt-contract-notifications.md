# Session Prompt 01 — Contract Expiry Notifications (In-App)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 4-6 hours

---

## Task: Build automated in-app notifications for contract expiry events, plus a notification bell UI

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 3) claims "automated alerts before contracts expire or auto-renew." Currently, a `ContractExpiryWidget` shows status badges on the dashboard, but there are no notifications — users must manually check. We need:

1. A pg_cron function that scans contracts daily and inserts rows into the existing `notifications` table
2. A notification bell icon in the app header that shows unread count and a dropdown list
3. Clicking a notification navigates to the relevant contract/cost view

The `notifications` and `notification_rules` tables already exist in the schema — this is about wiring them up.

### Hard rules

1. **Branch:** `feat/contract-notifications`. Create from `dev`.
2. **SQL scripts go to `planning/sql/garland-m-gaps/`** — do NOT execute SQL.
3. **No email infrastructure** — in-app notifications only (the `channels` column defaults to `["in_app"]`).
4. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
5. **Follow existing component patterns** — lucide-react icons, Tailwind styling, toast for errors.
6. **Do NOT modify the ContractExpiryWidget** — it stays as the dashboard visualization. Notifications are a separate channel.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "notification_rules" (~line 8182) — table structure
   - Search for "notifications" (~line 8199) — table structure
   - Search for "vw_contract_expiry" — view definition and columns
   - Note: trigger_type CHECK includes 'license_expiry'

2. src/components/dashboard/ContractExpiryWidget.tsx
   - Status computation logic (lines 10-16): expired, renewal_due, expiring_soon, active, no_contract
   - View query pattern (line 45)

3. src/components/layout/ — find the main app header/navbar component
   - This is where the notification bell will be placed
   - Note the existing layout pattern (icons, dropdowns)

4. docs-architecture/features/cost-budget/cost-model.md
   - Contract fields: contract_reference, contract_start_date, contract_end_date, renewal_notice_days

5. docs-architecture/operations/new-table-checklist.md
   - Pattern for new database functions and cron jobs
```

### Step 2 — Verify schema via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm notifications tables exist
psql "$DATABASE_READONLY_URL" -c "\d public.notifications"
psql "$DATABASE_READONLY_URL" -c "\d public.notification_rules"

# Check vw_contract_expiry columns
psql "$DATABASE_READONLY_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'vw_contract_expiry' ORDER BY ordinal_position"

# Check for any existing RLS on notifications
psql "$DATABASE_READONLY_URL" -c "SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'notifications'"
```

### Step 3 — Generate SQL: Contract notification scanner function

**File:** `planning/sql/garland-m-gaps/01-contract-notification-function.sql`

Create a SECURITY DEFINER function that:

```sql
CREATE OR REPLACE FUNCTION public.fn_scan_contract_expiry_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_contract RECORD;
  v_admin_users uuid[];
  v_user_id uuid;
BEGIN
  -- Scan vw_contract_expiry for contracts that are:
  --   'expired' or 'renewal_due' or 'expiring_soon'
  -- And have NOT already been notified in the last 7 days (dedup)

  FOR v_contract IN
    SELECT
      source_type,          -- 'it_service' or 'cost_bundle'
      source_id,
      source_name,
      vendor_name,
      contract_end_date,
      days_until_expiry,
      status,               -- expired, renewal_due, expiring_soon
      namespace_id,
      workspace_id
    FROM vw_contract_expiry
    WHERE status IN ('expired', 'renewal_due', 'expiring_soon')
  LOOP
    -- Get workspace admins + editors for this workspace
    SELECT array_agg(DISTINCT nu.user_id)
    INTO v_admin_users
    FROM namespace_users nu
    JOIN workspace_users wu ON wu.user_id = nu.user_id
    WHERE wu.workspace_id = v_contract.workspace_id
    AND wu.role IN ('admin', 'editor');

    -- Check for recent duplicate notification (same source_id, same status, within 7 days)
    -- Skip if already notified
    IF EXISTS (
      SELECT 1 FROM notifications
      WHERE link LIKE '%' || v_contract.source_id::text || '%'
      AND title LIKE '%' || v_contract.status || '%'
      AND created_at > now() - interval '7 days'
    ) THEN
      CONTINUE;
    END IF;

    -- Insert notification for each admin/editor user
    IF v_admin_users IS NOT NULL THEN
      FOREACH v_user_id IN ARRAY v_admin_users LOOP
        INSERT INTO notifications (user_id, title, message, link)
        VALUES (
          v_user_id,
          CASE v_contract.status
            WHEN 'expired' THEN 'Contract Expired'
            WHEN 'renewal_due' THEN 'Contract Renewal Due'
            WHEN 'expiring_soon' THEN 'Contract Expiring Soon'
          END,
          v_contract.source_name
            || COALESCE(' (' || v_contract.vendor_name || ')', '')
            || ' — '
            || CASE v_contract.status
                 WHEN 'expired' THEN 'expired ' || abs(v_contract.days_until_expiry) || ' days ago'
                 WHEN 'renewal_due' THEN 'renewal due in ' || v_contract.days_until_expiry || ' days'
                 WHEN 'expiring_soon' THEN 'expires in ' || v_contract.days_until_expiry || ' days'
               END,
          '/budget?highlight=' || v_contract.source_id::text
        );
      END LOOP;
    END IF;
  END LOOP;
END;
$$;
```

**Adapt the above based on what you find in the actual schema.** The `vw_contract_expiry` column names may differ — verify in Step 2. The notification `link` field should point to the budget page with a query parameter that highlights the relevant contract.

### Step 4 — Generate SQL: Cron schedule

**File:** `planning/sql/garland-m-gaps/01-contract-notification-cron.sql`

```sql
-- Run daily at 06:00 UTC (midnight CST for Garland)
SELECT cron.schedule(
  'contract-expiry-notifications-daily',
  '0 6 * * *',
  'SELECT fn_scan_contract_expiry_notifications()'
);

-- Verification
SELECT jobid, schedule, command FROM cron.job WHERE jobname = 'contract-expiry-notifications-daily';
```

Also ensure the `notifications` table has proper RLS:
```sql
-- Users can only see their own notifications
CREATE POLICY notifications_select ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

-- Users can mark their own as read
CREATE POLICY notifications_update ON public.notifications
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Only service_role (cron) can insert
CREATE POLICY notifications_insert ON public.notifications
  FOR INSERT WITH CHECK (true);  -- SECURITY DEFINER function handles auth
```

Check existing policies first (Step 2) — don't duplicate.

### Step 5 — Build notification bell component

Create `src/components/notifications/NotificationBell.tsx`:

**Requirements:**
- Bell icon from lucide-react (`Bell`)
- Unread count badge (red dot with number, max "9+")
- Click opens a dropdown panel (not a full page)
- Dropdown shows most recent 20 notifications, newest first
- Each notification shows: title (bold), message, relative time ("2 hours ago")
- Unread notifications have a subtle background highlight
- Click a notification: mark as read + navigate to `notification.link`
- "Mark all as read" button at bottom of dropdown
- Close dropdown on click outside

**Data fetching:**
```typescript
// Fetch unread count (poll every 60 seconds)
const { data: unreadCount } = await supabase
  .from('notifications')
  .select('id', { count: 'exact', head: true })
  .eq('is_read', false);

// Fetch recent notifications (on dropdown open)
const { data: notifications } = await supabase
  .from('notifications')
  .select('*')
  .order('created_at', { ascending: false })
  .limit(20);

// Mark as read
await supabase
  .from('notifications')
  .update({ is_read: true })
  .eq('id', notificationId);

// Mark all as read
await supabase
  .from('notifications')
  .update({ is_read: true })
  .eq('is_read', false);
```

**Polling pattern:** Use `setInterval` in a `useEffect` with cleanup. 60-second interval for unread count. Full fetch only when dropdown opens.

### Step 6 — Integrate bell into app header

Find the main layout/header component and add `<NotificationBell />` next to the existing header icons (user menu, workspace selector, etc.). Position it to the left of the user/profile menu.

### Step 7 — Impact analysis and type check

```bash
# Verify no naming conflicts
grep -r "NotificationBell\|useNotifications" src/ --include="*.ts" --include="*.tsx"

# Type check
npx tsc --noEmit
```

### Step 8 — Update architecture doc

Update `docs-architecture/features/cost-budget/cost-model.md`:
- Add a section on contract expiry notifications
- Document the pg_cron schedule and notification recipients (workspace admins + editors)
- Document the 7-day dedup window

### Step 9 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
mkdir -p planning/sql/garland-m-gaps
git add planning/sql/garland-m-gaps/01-* src/components/notifications/
git commit -m "feat: contract expiry in-app notifications with notification bell

Adds pg_cron function to scan vw_contract_expiry daily and insert
notifications for expired/renewal_due/expiring_soon contracts.
Adds NotificationBell component with unread count badge and dropdown.
Closes Garland audit yellow flag (Slide 3, 'automated alerts')."
git push -u origin feat/contract-notifications
```

### Done criteria checklist

- [ ] SQL: `fn_scan_contract_expiry_notifications()` function created
- [ ] SQL: pg_cron job scheduled daily at 06:00 UTC
- [ ] SQL: RLS policies on `notifications` table (if not already present)
- [ ] SQL: 7-day dedup prevents duplicate notifications
- [ ] UI: `NotificationBell.tsx` with unread badge, dropdown, mark-as-read
- [ ] UI: Bell integrated into app header
- [ ] UI: Click notification navigates to budget page
- [ ] 60-second polling for unread count
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] Architecture doc updated

### What NOT to do

- Do NOT build email notifications — in-app only for now
- Do NOT modify `ContractExpiryWidget.tsx` — the widget and notifications are independent
- Do NOT execute SQL scripts — generate them for Stuart
- Do NOT create a notifications page — the dropdown is sufficient for MVP
- Do NOT add push notifications or service workers
