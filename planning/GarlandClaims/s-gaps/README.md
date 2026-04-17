# Garland Presentation — S-Sized Gap Closure

**Source:** `planning/GarlandClaims/garland-presentation-audit-response.md`
**Created:** April 13, 2026

---

## What This Is

Three S-sized gaps (1–4 hours each) identified during the Garland presentation claim audit. These convert soft/partial implementations into features that match the slide claims.

## Execution Order & Dependencies

```
01-double-count-hard-block       UI only, no schema changes
02-lifecycle-auto-lookup          UI only, Edge Function already deployed
03-soc2-evidence-automation       SQL scripts for Stuart to apply (pg_cron + storage table)
```

No dependencies between sessions. All three can run in parallel.

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On | Parallel? |
|---|--------|--------|-----------|------------|-----------|
| 01 | `01-session-prompt-double-count-hard-block.md` | `fix/double-count-hard-block` | 1-2 hrs | None | 02, 03 |
| 02 | `02-session-prompt-lifecycle-auto-lookup.md` | `fix/lifecycle-auto-lookup` | 1-2 hrs | None | 01, 03 |
| 03 | `03-session-prompt-soc2-evidence-automation.md` | `fix/soc2-evidence-cron` | 1-2 hrs | None (SQL output for Stuart) | 01, 02 |

**Total:** ~3-6 hours sequential, ~2 hours with parallel worktrees.

## Non-Overlapping File Sets (Safe for Parallel)

| Session | Files Owned |
|---------|-------------|
| 01 | `src/components/applications/CostBundleSection.tsx`, `src/components/ITServiceDependencyList.tsx` |
| 02 | `src/components/TechnologyProductModal.tsx`, `src/components/SoftwareProductModal.tsx` |
| 03 | `planning/sql/GarlandClaims/s-gaps/` (SQL output only — no src/ changes) |

## Gap Inventory

| # | Gap | Slide | Size | Type |
|---|-----|-------|------|------|
| 1 | Double-count guard is a soft warning with "Add anyway" bypass — slide says "never" | 3 | S | UI |
| 2 | Lifecycle lookup requires user confirmation — slide says "automatically" | 6 | S | UI |
| 3 | SOC2 evidence collection is a manual RPC — slide says "automated" | 7 | S | SQL |

## Post-Completion

- Session 01: The "never attributed to both" claim becomes accurate — no bypass possible
- Session 02: The "automatically" claim becomes accurate — lookup fires on save without confirmation
- Session 03: Stuart applies SQL scripts, evidence snapshots are generated monthly by pg_cron
- Update `garland-presentation-audit-response.md` to mark these yellow flags as resolved
