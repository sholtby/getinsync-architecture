# Garland Presentation — Claim Audit & Gap Closure

**Created:** April 13, 2026
**Presentation deck:** `marketing/garland-presentation-content.md`
**Audit response:** `garland-presentation-audit-response.md` (this directory)

---

## What This Is

The City of Garland presentation (11 slides) was audited claim-by-claim against the deployed codebase and database schema. This directory contains the audit findings and Claude Code session prompts to close every gap, organized by effort size.

## Audit Summary

| Verdict | Count | Action |
|---------|-------|--------|
| ❌ Red flags | 3 | Session prompts to fix (Slides 5, 8, 9) |
| ⚠️ Yellow flags | 10 | Session prompts to fix or soften language |
| ✅ Confirmed | 24 | No changes needed |
| Roadmap items | 3 | Tracked in product roadmap (XL/2XL) |

Full findings: [`garland-presentation-audit-response.md`](garland-presentation-audit-response.md)

---

## Gap Inventory

| # | Gap | Slide | Size | Directory |
|---|-----|-------|------|-----------|
| XS-1 | AI chat has no filter for missing business owner | 5 | XS | `xs-gaps/` |
| XS-2 | Tech Product categories: 16 not 15 | 9 | XS | `xs-gaps/` |
| S-1 | Double-count guard is a bypassable soft warning | 3 | S | `s-gaps/` |
| S-2 | Lifecycle lookup requires user confirmation | 6 | S | `s-gaps/` |
| S-3 | SOC2 evidence collection is a manual RPC | 7 | S | `s-gaps/` |
| M-1 | Contract expiry has no automated notifications | 3 | M | `m-gaps/` |
| M-2 | YoY budget trend view exists but no frontend chart | 3 | M | `m-gaps/` |
| M-3 | Restricted role has no portfolio-scoped visibility | 8 | M | `m-gaps/` |
| L-1 | Steward role has no scoped behavior (= Editor) | 8 | L | `l-gaps/` |
| L-2 | AI chat refuses YoY budget questions | 5 | L | `l-gaps/` |

### Roadmap Items (No Session Prompts)

| Feature | Slide | Size | Roadmap Phase |
|---------|-------|------|---------------|
| ITSM / ServiceNow sync | 9 (replaced) | 2XL | Phase 37 + 51, Q3 2026 |
| Enterprise SSO (SAML/OIDC) | 7 (softened) | XL | Phase 40, Q2 2026 |
| Multi-region data residency | 7 (reframed) | 2XL | Phase 43, Q4 2026 |

---

## Execution Dependencies

```
XS-1  ai-chat-owner-filter          ─┐
XS-2  presentation-text-fixes        ├── All independent, run in any order
S-1   double-count-hard-block        │
S-2   lifecycle-auto-lookup           │
S-3   soc2-evidence-automation        │
M-1   contract-notifications          │
M-2   budget-trend-chart              │
L-2   budget-ai-tool                 ─┘

M-3   restricted-role               ─┐
                                      ├── CONFLICT: both touch usePermissions.ts
L-1   steward-role                  ─┘   Run sequentially, not in parallel
```

## Effort Summary

| Size | Sessions | Time Estimate |
|------|----------|---------------|
| XS (< 1 hr) | 2 | ~40 min |
| S (1-4 hrs) | 3 | ~3-6 hrs |
| M (4 hrs-1 day) | 3 | ~14-20 hrs |
| L (1-2 days) | 2 | ~2-3.5 days |
| **Total** | **10** | **~5-7 days** |

## How to Execute

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
├── xs-gaps/                                ← 2 sessions, ~40 min
├── s-gaps/                                 ← 3 sessions, ~3-6 hrs
├── m-gaps/                                 ← 3 sessions, ~14-20 hrs
└── l-gaps/                                 ← 2 sessions, ~2-3.5 days
```
