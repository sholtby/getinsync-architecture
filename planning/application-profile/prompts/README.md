# Application Profile Tier 1 — Session Prompts

This directory contains **atomic, paste-ready prompts** for each session in the Application Profile Tier 1 build. Each prompt is self-contained: open a fresh Claude Code session, paste the file content, and the model has everything it needs to execute that session — nothing else required.

## The master plan

The full session plan lives at `../session-plan.md` (v1.2). It covers scope, cross-references with open items, sequencing, and the Publish Assessment RPC alignment. These prompts implement it.

## The files

| # | File | Goal | Prereq | Effort |
|---|---|---|---|---|
| 1 | `session-1-schema-migration.md` | Apply the full schema delta + data cleanup | PAID canonical rule acknowledged | 2–2.5 hrs |
| 2 | `session-2-view.md` | Deploy `vw_application_profile` | Session 1 merged | 2.5–3 hrs |
| 3 | `session-3-typescript.md` | `VwApplicationProfile` interface + view-contract cleanup | Session 2 merged | 1–1.5 hrs |
| 4 | `session-4-hooks.md` | `useApplicationProfile` + narrative-cache hook | Session 3 merged | 1.5 hrs |
| 5 | `session-5-drawer.md` | Evolve `ApplicationDetailDrawer` + extract block components | Session 4 merged | 3–4 hrs |
| 5b | `session-5b-wizard-optional.md` | Plan-status capture in the assessment wizard (deferrable to Tier 1.5) | Session 5 merged | 1 hr |
| 6 | `session-6-docs-rpc.md` | Architecture doc updates + Publish Assessment RPC spec reshape | Session 5 merged | 1–1.5 hrs |

Total Tier 1: ~13–15 hours across 5 sittings (+1 hr if 5b is included).

## How to run a session

1. Start a fresh Claude Code session in the code repo: `cd ~/Dev/getinsync-nextgen-ag`.
2. Confirm you're on the correct feature branch. Recommended flow: one long-lived branch `feat/application-profile-tier-1` off `dev`, with each session adding one or two commits.
3. Open the session's prompt file in this directory. Copy its entire contents.
4. Paste as the first message of the Claude Code session.
5. Let Claude execute. Intervene only for decisions the prompt explicitly flags as needing your input.
6. Verify the session's exit criteria before committing.
7. Merge to `dev` only at the end of Session 6 (per CLAUDE.md CalVer rule — bump version when user-visible changes merge).

## Rules every session obeys

Every prompt reinforces the following constants (copied from CLAUDE.md and the PAID canonicalization rule shipped 2026-04-16):

- **PAID = Plan / Address / Delay / Ignore.** Never Improve or Divest.
- **TIME = Tolerate / Invest / Modernize / Eliminate.**
- Stuart applies all schema changes via Supabase SQL Editor — prompts prepare the SQL, Stuart runs it.
- Dual-repo commits: code repo on feature branch, architecture repo on `main` (no feature branches for docs).
- After any doc change: bump `MANIFEST.md` version and add a changelog entry.
- Impact analysis before touching shared types/views/components.
- No `alert()` / `confirm()` — toast notifications only.
- All dropdowns fetch from reference tables — never hardcode.

## If you get stuck

- The master `session-plan.md` has the full context and decision rationale.
- `features/application-profile/schema-mapping.md` v1.1 is the field-by-field source of truth.
- `operations/new-table-checklist.md` governs `application_narrative_cache` creation in Session 1.
- The open-items cross-reference in `session-plan.md` §2 shows what each session bundles.

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-04-16 | Initial prompt split from session-plan v1.2. Seven atomic prompts (Sessions 1, 2, 3, 4, 5, 5b, 6) plus this README. |
