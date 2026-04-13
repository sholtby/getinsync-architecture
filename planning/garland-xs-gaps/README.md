# Garland Presentation — XS Gap Closure

**Source:** `marketing/garland-presentation-audit-response.md`
**Created:** April 13, 2026

---

## What This Is

Three XS-sized gaps identified during the Garland presentation claim audit. Each is under 1 hour of Claude Code effort. Two are doc-only edits, one is a small Edge Function change.

## Execution Order & Dependencies

```
01-ai-chat-owner-filter       Code change (Edge Function)
                                |
02-presentation-text-fixes     Doc-only (can run in parallel with 01)
```

No dependencies between sessions. Both can run in parallel.

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On | Parallel? |
|---|--------|--------|-----------|------------|-----------|
| 01 | `01-session-prompt-ai-chat-owner-filter.md` | `fix/ai-chat-owner-filter` | 20-30 min | None | 02 |
| 02 | `02-session-prompt-presentation-text-fixes.md` | n/a (architecture repo, main) | 10 min | None | 01 |

**Total:** ~30-40 minutes. Both can run in parallel.

## Non-Overlapping File Sets (Safe for Parallel)

| Session | Files Owned |
|---------|-------------|
| 01 | `supabase/functions/ai-chat/tools.ts` |
| 02 | `docs-architecture/marketing/garland-presentation-content.md` |

## Gap Inventory

| # | Gap | Slide | Size | Type |
|---|-----|-------|------|------|
| 1 | AI chat `list-applications` tool has no filter for null/missing business owner | 5 | XS | Code |
| 2 | Technology Product categories count says 15, actual is 16 | 9 | XS | Doc |
| 3 | Competitor pricing "$60K+" cherry-picks from a wide range ($15K-$100K+) | 6 | XS | Doc |

## Post-Completion

After Session 01 merges, the AI chat can answer "Show me all applications with no assigned business owner" as a first-class query. Update the audit response to mark this yellow flag as resolved.
