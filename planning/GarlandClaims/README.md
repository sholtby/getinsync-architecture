# Garland Presentation — Claim Audit & Gap Closure

**Created:** April 13, 2026
**Status:** ✅ AUDIT COMPLETE — presentation language fixed. Session prompts PARKED.
**Presentation deck:** `marketing/garland-presentation-content.md`
**Audit response:** `garland-presentation-audit-response.md` (this directory)
**Open items matrix:** #100 in `planning/open-items-priority-matrix.md`

---

## What Happened

The City of Garland presentation (11 slides) was audited claim-by-claim against the deployed codebase and database schema. The audit found 3 red flags and 10 yellow flags. **All were resolved by adjusting the slide language and talking points** in the audit response document — no code changes were needed to make the presentation accurate.

One code fix (XS-1: ai-chat-owner-filter) was shipped as v2026.4.11 because it was a genuine product gap independent of the presentation.

Session prompts were written for all remaining gaps (S through L), but on review these are real product features that belong on the roadmap, not presentation blockers. They are **parked** — the prompts remain here as ready-to-execute backlog if priorities change.

## Audit Summary

| Verdict | Count | Resolution |
|---------|-------|------------|
| ❌ Red flags | 3 | Fixed via slide language (Slides 5, 8, 9) |
| ⚠️ Yellow flags | 10 | Fixed via slide language or softened |
| ✅ Confirmed | 24 | No changes needed |
| Roadmap items | 3 | Tracked in product roadmap (XL/2XL) |

Full findings: [`garland-presentation-audit-response.md`](garland-presentation-audit-response.md)

---

## Gap Inventory

| # | Gap | Slide | Size | Status | Directory |
|---|-----|-------|------|--------|-----------|
| XS-1 | AI chat has no filter for missing business owner | 5 | XS | ✅ Applied (v2026.4.11) | `xs-gaps/` |
| XS-2 | Tech Product categories: 16 not 15 | 9 | XS | ⊘ Skipped (immaterial) | `xs-gaps/` |
| S-1 | Double-count guard is a bypassable soft warning | 3 | S | ⏸️ Parked | `s-gaps/` |
| S-2 | Lifecycle lookup requires user confirmation | 6 | S | ⏸️ Parked | `s-gaps/` |
| S-3 | SOC2 evidence collection is a manual RPC | 7 | S | ⏸️ Parked | `s-gaps/` |
| M-1 | Contract expiry has no automated notifications | 3 | M | ⏸️ Parked | `m-gaps/` |
| M-2 | YoY budget trend view exists but no frontend chart | 3 | M | ⏸️ Parked | `m-gaps/` |
| M-3 | Restricted role has no portfolio-scoped visibility | 8 | M | ⏸️ Parked | `m-gaps/` |
| L-1 | Steward role has no scoped behavior (= Editor) | 8 | L | ⏸️ Parked | `l-gaps/` |
| L-2 | AI chat refuses YoY budget questions | 5 | L | ⏸️ Parked | `l-gaps/` |

### Roadmap Items (No Session Prompts — Tracked in Product Roadmap)

| Feature | Slide | Size | Roadmap Phase |
|---------|-------|------|---------------|
| ITSM / ServiceNow sync | 9 (replaced) | 2XL | Phase 37 + 51, Q3 2026 |
| Enterprise SSO (SAML/OIDC) | 7 (softened) | XL | Phase 40, Q2 2026 |
| Multi-region data residency | 7 (reframed) | 2XL | Phase 43, Q4 2026 |

---

## Why Parked

The audit response document already fixed the presentation — every claim now matches reality through language adjustments. The remaining gaps (S through L) are genuine product improvements, but:

1. **Not MVP blockers** — the presentation is accurate without them
2. **Over-engineered for this stage** — writing features to match sales claims puts the cart before the horse
3. **Better as roadmap items** — these should be prioritized against the full backlog, not rushed for one presentation

The session prompts remain ready to execute if any of these features become a priority.

---

## Execution Dependencies (Reference)

If you do decide to execute any of these sessions in the future:

```
XS-1  ai-chat-owner-filter          ── ✅ DONE
XS-2  presentation-text-fixes       ── ⊘ SKIPPED

S-1   double-count-hard-block        ─┐
S-2   lifecycle-auto-lookup           ├── All independent, run in any order
S-3   soc2-evidence-automation        │
M-1   contract-notifications          │
M-2   budget-trend-chart              │
L-2   budget-ai-tool                 ─┘

M-3   restricted-role               ─┐
                                      ├── CONFLICT: both touch usePermissions.ts
L-1   steward-role                  ─┘   Run sequentially, not in parallel
```

## Effort Summary (Reference)

| Size | Sessions | Time Estimate | Status |
|------|----------|---------------|--------|
| XS (< 1 hr) | 2 | ~40 min | 1 applied, 1 skipped |
| S (1-4 hrs) | 3 | ~3-6 hrs | All parked |
| M (4 hrs-1 day) | 3 | ~14-20 hrs | All parked |
| L (1-2 days) | 2 | ~2-3.5 days | All parked |
| **Total remaining** | **8** | **~4.5-6.5 days** | **Parked** |

## How to Execute (If Needed Later)

1. Open a fresh Claude Code session
2. Open the session prompt file from the appropriate subdirectory
3. Copy everything **below the `---` line**
4. Paste into the fresh session
5. Claude executes the full prompt (read context → implement → commit)

Sessions that generate SQL scripts output to `planning/sql/GarlandClaims/`. Stuart applies these via Supabase SQL Editor.

See each subdirectory's README for session-specific details, branch names, file ownership, and parallelism notes.

---

## Directory Contents

```
GarlandClaims/
├── README.md                               ← You are here
├── garland-presentation-audit-response.md  ← Full audit findings + recommendations
├── xs-gaps/                                ← 1 applied, 1 skipped
├── s-gaps/                                 ← 3 sessions, all parked
├── m-gaps/                                 ← 3 sessions, all parked
└── l-gaps/                                 ← 2 sessions, all parked
```
