# Session Prompt 05 — Multi-Server DP: Technology Health Dashboards + CSV Export

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: Sessions 01 SQL applied + Session 02 types merged. Can run in PARALLEL with Sessions 04 and 06 (use git worktree).
> Estimated: 45-60 min.

---

## Task: Update Technology Health dashboard components for multi-server display and entity-based server grouping

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Technology Health dashboards currently display a single `server_name` text field and group servers by that free-text string. With the new `servers` table and junction, the "By Server" view should group by `server_id` (showing OS, data center, status from the entity), and the other tables should display comma-separated server lists instead of a single name.

### Hard rules

1. **Branch:** `feat/multi-server-dashboards`. Create from `dev`.
2. **You MAY only modify files in `src/components/technology-health/`.**
3. **Run `npx tsc --noEmit` AND `npm run build` before committing.**
4. **Use the read-only DB connection** to verify the rewritten view columns before updating TypeScript.
5. **Pagination must still work** after changing the data shape.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - Section "Technology Health Dashboards"

2. docs-architecture/features/technology-health/dashboard.md
   - Overall dashboard architecture

3. src/types/view-contracts.ts
   - Updated ServerTechnologyReportRow (Session 02 added server_id, server_os, server_status, data_center_name)
   - Updated VwApplicationInfrastructureReportRow (Session 02 added server_names)

4. src/components/technology-health/TechnologyHealthByServer.tsx (full file)
   - Current grouping by server_name text
   - SortField type (lines 23-25)
   - Fetch query (lines 90-117)
   - Table rendering (lines 250+)

5. src/components/technology-health/SummaryApplicationTable.tsx (lines 420, 760-770)
   - Current server_name display in secondary text

6. src/components/technology-health/TechnologyHealthByApplication.tsx (lines 560, 950-960)
   - Current server_name display in secondary text

7. src/components/technology-health/TechnologyHealthSummary.tsx (line 479)
   - CSV export including server_name
```

### Step 2 — Verify view columns via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm rewritten view has new columns
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_server_technology_report' ORDER BY ordinal_position"

# Confirm infrastructure report has server_names
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vw_application_infrastructure_report' ORDER BY ordinal_position"
```

### Step 3 — Impact analysis

```bash
grep -r "server_name" src/components/technology-health/ --include="*.tsx" -n
grep -r "ServerTechnologyReportRow" src/ --include="*.ts" --include="*.tsx" -n
grep -r "vw_server_technology_report" src/ --include="*.ts" --include="*.tsx" -n
```

### Step 4 — Rewrite TechnologyHealthByServer

This is the major change. The component currently groups by free-text `server_name`. Rewrite to:

1. **Query:** Fetch from the rewritten `vw_server_technology_report` which now has `server_id` as the primary key instead of `server_name` text grouping.
2. **SortField type:** Add `server_os`, `server_status`, `data_center_name` to the sort field union.
3. **Table columns:** Add OS, Data Center, Status columns (from the `servers` entity). Keep existing columns (deployment_count, application_count, primary_os, worst_lifecycle_status, etc.).
4. **Status column rendering:** Show `active` / `decommissioned` as a badge (green/gray).
5. **Search:** Filter by server name (same as before, but now matching against the entity name).
6. **CSV export:** Include the new columns.

### Step 5 — Update TechHealthByServerFilterDrawer

If a filter drawer component exists for the server view, add filter options for:
- OS (text search or distinct values)
- Data Center (dropdown from distinct values in the data)
- Status (active/decommissioned toggle)

### Step 6 — Update SummaryApplicationTable

In `src/components/technology-health/SummaryApplicationTable.tsx`:

- Find where `server_name` is displayed as secondary gray text (~line 763)
- Replace with `server_names` from the updated view (comma-separated by the view)
- If the server list is long (>3), truncate: show first 2 + "+N more"
- Update CSV export columns if server_name is included

### Step 7 — Update TechnologyHealthByApplication

In `src/components/technology-health/TechnologyHealthByApplication.tsx`:

- Same change as Step 6: replace `server_name` with `server_names` in secondary text (~line 955)
- Same truncation logic for long lists

### Step 8 — Update TechnologyHealthSummary CSV Export

In `src/components/technology-health/TechnologyHealthSummary.tsx`:

- Update CSV export (~line 479) to include all servers per DP
- If the view provides `server_names` as comma-separated, use that directly
- Column header: "Servers" (plural)

### Step 9 — Verify

```bash
npx tsc --noEmit
npm run build
```

### Step 10 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/technology-health/
git commit -m "feat: multi-server dashboard updates (entity grouping, multi-server display, CSV export)"
git push -u origin feat/multi-server-dashboards
```

### Done criteria checklist

- [ ] `npx tsc --noEmit` passes
- [ ] `npm run build` succeeds
- [ ] TechnologyHealthByServer groups by `server_id`, shows OS/data center/status columns
- [ ] SummaryApplicationTable shows multi-server list per DP (truncated if >3)
- [ ] TechnologyHealthByApplication shows multi-server list per DP
- [ ] CSV export includes all servers per DP
- [ ] Pagination still works correctly
- [ ] Filter drawers work with new columns
- [ ] No duplicate count displays (pagination count at bottom only)

### What NOT to do

- Do NOT change the dashboard tab structure or KPI cards
- Do NOT touch `src/components/visual/` (Session 04)
- Do NOT touch `supabase/functions/` or `docs-architecture/` (Session 06)
- Do NOT remove server_name fallback until migration is confirmed complete
