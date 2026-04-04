# Session-End Checklist — Change Log

Extracted from `session-end-checklist.md` to reduce file size.

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-10 | Initial document. 8 sections, dispatches to 6 skill documents. Replaces prose in dev rules section 4.3 with executable checklist. |
| v1.1 | 2026-02-11 | Added Section 6b: Schema Backup with pg_dump command, connection details, verify steps, git commit, and post-backup password roll. Added "Any database changes" trigger to Section 1. |
| v1.2 | 2026-02-12 | Added Section 9: Cross-Document Stats Alignment — prevents stat drift across manifest, evidence index, security overview, and memory. Added Section 10: Open Items Maintenance — harvests new items, classifies by priority, closes completed items, tracks SOC2 policy gaps, reproduces updated matrix. Updated Section 1 triggers to include "any work done" -> Sections 9+10. Updated Document Map with evidence index, security overview, user registration, and open items matrix. |
| v1.3 | 2026-02-18 | Section 6b Post-Backup: Added reminder to update Claude Code `.env` file after rolling database password. Clarified AG/Netlify not affected. |
| v1.4 | 2026-02-23 | Added Section 6c: Architecture Repo Sync. Dual-repo commit verification for `~/getinsync-architecture`. Updated Section 1 triggers, Section 6b schema copy step, Section 7 repo status row. Fixed mojibake throughout. |
| v1.5 | 2026-02-23 | Added Section 6d: Automated Security Regression. Dispatches to pgTAP (391 assertions) or standalone security validation. Updated Section 1 triggers, Section 7 validation range, Document Map. |
| v1.6 | 2026-02-28 | Added Section 6e: Code Quality Gate. 5 checks: TypeScript, ESLint, build, file size, impact scan. ESLint baseline: 0 errors, 513 warnings. |
| v1.7 | 2026-03-03 | Added Section 6f: Bulletproof React Spot Check (informational). Added Section 6d Option C (Claude Code psql). Section 9.3: mandatory auto-update. |
| v1.8 | 2026-03-03 | Added Section 6g: Data Quality Spot Check (14 checks). New test file `testing/data-quality-validation.sql`. |
| v1.9 | 2026-03-03 | Section 9.1: Fixed functions count query to exclude extension-owned functions. |
| v1.10 | 2026-03-03 | Section 2 rewrite: Bulk safety-net query (GRANTs, RLS, views, functions) runs on ANY database change. |
| v1.11 | 2026-03-03 | Consolidation: Section 2.1 expanded to 6 checks. Section 4 removed. Section 3 narrowed. pgTAP 391->408. Deprecated security-validation-runbook.md. |
| v1.12 | 2026-03-04 | Section 6d rewrite: Claude Code runs both test scripts directly via psql. Sentinel updates by Claude Code. |
| v1.13 | 2026-03-05 | Added "Next Session Setup" section for auto-titling sessions. |
| v1.14 | 2026-03-12 | Added Section 6h: User Documentation Check. Help articles moved to `guides/user-help/`. |
| v1.15 | 2026-03-12 | Section 6h rewrite: "Write It Now" replaces "Flag It". Three-tier scope system. Claude writes docs during session. |
| v1.16 | 2026-03-12 | Section 6h scope expansion: feature-walkthrough, whats-new, badge reference. Mandatory What's New entry. Version bump reminder. |
| v1.17 | 2026-03-12 | Added Section 2.3: Namespace Seeding Validation. SQL checks for missing seeding triggers on namespace-scoped reference tables. |
| v1.18 | 2026-03-13 | Added Section 6i: SOC2 Evidence Checkpoint. Per-session scan for SOC2-relevant changes. Quick 4-item checklist. |
| v1.19 | 2026-04-04 | Pruned checklist from 953 to ~700 lines. Extracted changelog and Section 6h to separate files. Removed inlined SQL duplicated in test scripts. |
