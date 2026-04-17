# Garland Presentation — L-Sized Gap Closure

**Source:** `planning/GarlandClaims/garland-presentation-audit-response.md`
**Created:** April 13, 2026

---

## What This Is

Two L-sized gaps (1–2 days each) identified during the Garland presentation claim audit. These implement the Steward role's distinctive behavior and enable Year-over-Year budget queries in the AI chat.

## Execution Order & Dependencies

```
01-steward-role              SQL + RLS + UI (independent)
02-budget-ai-tool            Edge Function + system prompt (independent)
```

Both can run in parallel — no file overlap. However:

**⚠️ Cross-size conflict:** Session 01 modifies `src/hooks/usePermissions.ts`. The M-gap Restricted session (`GarlandClaims/m-gaps/03`) also modifies this file. Do NOT run L-01 and M-03 in parallel. Sequence: merge one, then start the other.

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On | Parallel? |
|---|--------|--------|-----------|------------|-----------|
| 01 | `01-session-prompt-steward-role.md` | `feat/steward-role` | 1-2 days | None (but not parallel with M-03) | 02 |
| 02 | `02-session-prompt-budget-ai-tool.md` | `feat/budget-ai-tool` | 1-1.5 days | None | 01 |

**Total:** ~2-3.5 days sequential, ~2 days with parallel worktrees.

## Non-Overlapping File Sets (Safe for Parallel between L-01 and L-02)

| Session | Files Owned |
|---------|-------------|
| 01 | `planning/sql/GarlandClaims/l-gaps/01-*`, `src/hooks/usePermissions.ts`, `src/hooks/useStewardScope.ts`, `src/components/applications/` (assessment gating) |
| 02 | `planning/sql/GarlandClaims/l-gaps/02-*`, `supabase/functions/ai-chat/tools.ts`, `supabase/functions/ai-chat/system-prompt.ts` |

## Gap Inventory

| # | Gap | Slide | Size | Type |
|---|-----|-------|------|------|
| 1 | Steward role has no scoped behavior — behaves identically to Editor | 8 | L | SQL + RLS + UI |
| 2 | AI chat refuses YoY budget questions — no tool exists to query budget history | 5 | L | Edge Function |

## SQL Script Delivery

Session 01 generates SQL scripts in `planning/sql/GarlandClaims/l-gaps/`. Stuart applies via Supabase SQL Editor.

```
planning/sql/GarlandClaims/l-gaps/
├── 01-steward-rls-policies.sql
└── 02-budget-ai-tool.sql       (only if schema changes needed)
```

## Post-Completion

- Session 01: "Steward — business owners assess their own applications" becomes accurate
- Session 02: "What's our year-over-year spend trend?" example becomes a working AI query
- Update `garland-presentation-audit-response.md` to mark red flags as resolved
