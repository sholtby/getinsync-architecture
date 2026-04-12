# Multi-Server Deployment Profiles — Session Prompt Index

**Feature spec:** `docs-architecture/features/technology-health/multi-server-dp-design.md`
**Open item:** #93 in `planning/open-items-priority-matrix.md`
**Created:** April 12, 2026

---

## Execution Order & Dependencies

```
01-sql-scripts          Stuart applies SQL manually
      |
02-types-hooks          Sequential (needs schema applied)
      |
03-ui-forms             Sequential (needs types merged)
      |
      +---- 04-visual-tab       \
      |                          } Can run in PARALLEL via git worktrees
      +---- 05-dashboards       }
      |                          }
      +---- 06-aichat-docs      /
```

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On | Parallel? |
|---|--------|--------|-----------|------------|-----------|
| 01 | `01-session-prompt-sql-scripts.md` | `feat/multi-server-schema` | 30-45 min | None | -- |
| 02 | `02-session-prompt-types-hooks.md` | `feat/multi-server-types` | 30-45 min | 01 SQL applied by Stuart | -- |
| 03 | `03-session-prompt-ui-forms.md` | `feat/multi-server-ui` | 60-90 min | 02 merged to dev | -- |
| 04 | `04-session-prompt-visual-tab.md` | `feat/multi-server-visual` | 30-45 min | 02 merged to dev | 05, 06 |
| 05 | `05-session-prompt-dashboards.md` | `feat/multi-server-dashboards` | 45-60 min | 01+02 | 04, 06 |
| 06 | `06-session-prompt-aichat-docs.md` | `feat/multi-server-aichat-docs` | 30-45 min | 01 SQL applied | 04, 05 |

**Total:** ~4-5 hours sequential, ~3.5 hours with parallel worktrees for 04/05/06.

## Critical Path

1. Run Session 01 → Stuart applies SQL via Supabase SQL Editor → confirm "schema done"
2. Run Session 02 → merge to dev
3. Run Session 03 → merge to dev
4. Run Sessions 04, 05, 06 in parallel (git worktrees) → merge each to dev

## Non-Overlapping File Sets (Safe for Parallel)

| Session | Files Owned |
|---------|-------------|
| 04 | `src/components/visual/`, `src/hooks/useVisualGraphData.ts` |
| 05 | `src/components/technology-health/` |
| 06 | `supabase/functions/ai-chat/`, `docs-architecture/` (4 docs + MANIFEST) |

## Cleanup (Not in These Sessions)

The `server_name` column on `deployment_profiles` is NOT dropped in any of these sessions. Schedule a separate cleanup task after all 6 sessions are merged and verified.
