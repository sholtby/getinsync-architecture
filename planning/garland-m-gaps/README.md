# Garland Presentation — M-Sized Gap Closure

**Source:** `marketing/garland-presentation-audit-response.md`
**Created:** April 13, 2026

---

## What This Is

Three M-sized gaps (4 hours–1 day each) identified during the Garland presentation claim audit. These add missing UI features and a role-scoping mechanism to match slide claims.

## Execution Order & Dependencies

```
01-contract-notifications    SQL + UI (independent)
02-budget-trend-chart        UI only (independent)
03-restricted-role           SQL + RLS + UI (independent)
```

All three can run in parallel — no dependencies between sessions.

**⚠️ Cross-size conflict:** Session 03 modifies `src/hooks/usePermissions.ts`. The L-gap Steward session (`garland-l-gaps/01`) also modifies this file. Do NOT run M-03 and L-01 in parallel.

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On | Parallel? |
|---|--------|--------|-----------|------------|-----------|
| 01 | `01-session-prompt-contract-notifications.md` | `feat/contract-notifications` | 4-6 hrs | None | 02, 03 |
| 02 | `02-session-prompt-budget-trend-chart.md` | `feat/budget-trend-chart` | 4-6 hrs | None | 01, 03 |
| 03 | `03-session-prompt-restricted-role.md` | `feat/restricted-role` | 6-8 hrs | None | 01, 02 |

**Total:** ~14-20 hours sequential, ~6-8 hours with parallel worktrees.

## Non-Overlapping File Sets (Safe for Parallel)

| Session | Files Owned |
|---------|-------------|
| 01 | `planning/sql/garland-m-gaps/01-*`, `src/components/notifications/`, `src/components/layout/` (notification bell) |
| 02 | `src/components/budget/BudgetTrendChart.tsx`, `src/components/budget/useBudgetHistory.ts`, `src/components/budget/BudgetNamespaceOverview.tsx` |
| 03 | `planning/sql/garland-m-gaps/03-*`, `src/hooks/usePermissions.ts`, `src/hooks/useApplications.ts` |

## Gap Inventory

| # | Gap | Slide | Size | Type |
|---|-----|-------|------|------|
| 1 | Contract expiry has dashboard widget but no automated notifications | 3 | M | SQL + UI |
| 2 | YoY budget trend view exists in DB but no frontend chart | 3 | M | UI |
| 3 | Restricted role has no portfolio-scoped visibility — read access is namespace-wide | 8 | M | SQL + RLS + UI |

## Post-Completion

- Session 01: "Automated alerts before contracts expire" becomes accurate (in-app notifications)
- Session 02: "Year-over-Year Budget Trends" becomes accurate (trend chart on IT Spend page)
- Session 03: "Restricted — read-only limited to assigned applications only" becomes accurate
- Update `garland-presentation-audit-response.md` to mark yellow flags as resolved

## SQL Script Delivery

Sessions 01 and 03 generate SQL scripts in `planning/sql/garland-m-gaps/`. Stuart applies these via Supabase SQL Editor before the UI code is merged.

```
planning/sql/garland-m-gaps/
├── 01-contract-notification-function.sql
├── 01-contract-notification-cron.sql
├── 03-restricted-role-schema.sql
└── 03-restricted-role-rls.sql
```
