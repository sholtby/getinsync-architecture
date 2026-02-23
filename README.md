# GetInSync NextGen — Architecture Documentation

> **Single source of truth** for all architecture, design, and operational documentation.  
> Clean up docs via PRs. Git history replaces version suffixes.

## Quick Links

| What | Where |
|------|-------|
| Master Document Index | [MANIFEST.md](MANIFEST.md) |
| Change Log | [CHANGELOG.md](CHANGELOG.md) |
| Claude Code Rules | [CLAUDE.md](CLAUDE.md) |
| Current Schema | [schema/nextgen-schema-current.sql](schema/nextgen-schema-current.sql) |
| Open Items | [planning/open-items-priority-matrix.md](planning/open-items-priority-matrix.md) |

## Folder Guide

| Folder | Contents |
|--------|----------|
| `core/` | Core data model, ERDs, deployment profiles, workspaces |
| `catalogs/` | Software products, IT services, technology catalog, reference models |
| `features/` | Feature-specific architecture (cost, tech health, AI chat, etc.) |
| `identity-security/` | RLS, RBAC, SOC2, auth, security runbooks |
| `operations/` | Dev rules, checklists, skills, demo setup |
| `marketing/` | Explainer, positioning, pricing, roadmap |
| `planning/` | Q1 plan, Gantt, work packages, open items |
| `sessions/` | Session summaries (recent only) |
| `schema/` | SQL schema dumps, audit logging DDL, demo templates |
| `prd/` | PRD-style execution specs for new phases |
| `archive/` | Superseded versions + original Phase 1-16 specs |

## Status Tags (in document headers)

| Tag | Meaning |
|-----|---------|
| 🟢 AS-BUILT | Accurately describes production |
| 🟡 AS-DESIGNED | Architecture approved, not yet implemented |
| 🟠 NEEDS UPDATE | Concept valid, contains stale references |
| ☪ REFERENCE | Stack-agnostic methodology or reference material |

## Migration Note

This repo was created 2026-02-22 by consolidating architecture documents from the Claude Project and local disk. The initial commit imports all documents as-is with updated cross-references. Some documents still contain AWS/Entra references that need cleanup — see MANIFEST.md status tags for details.

Cleanup is tracked as a series of focused PRs (see migration guide in `operations/`).
