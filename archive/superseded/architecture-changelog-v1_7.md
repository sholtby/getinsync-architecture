# gis-architecture-changelog-v1.7
GetInSync NextGen Architecture Change Log

Last updated: 2026-01-31

---

## Purpose

This document tracks significant architectural decisions, schema changes, and feature additions to GetInSync NextGen. Each entry includes the rationale, implementation details, and impact.

**Note:** For current document versions and status, see **gis-architecture-manifest** (latest version).

---

## Recent Changes (2026-02-01 to present)

*No changes yet. This section will be updated with new architectural changes as they occur.*

---

## Pending Changes

| Document | Planned Change | Target Date | Status |
|----------|---------------|-------------|--------|
| gis-quicksight-reporting-architecture | Add cross-reference to NextGen doc | TBD | Backlog |
| Database views | Implement vwQS_ApplicationScores, TIME, PAID | Q1 2026 | In Progress |
| gis-involved-party-architecture | Add is_customer boolean flag | TBD | Backlog |
| gis-reference-tables-design-debt | Implement reference tables for dropdown values | Q1 2026 | Backlog |
| gis-application-wizard | 5-step guided creation workflow | Q1 2026 | Planned (Phase 26) |
| gis-composite-application-architecture | Implementation (designed, not implemented) | TBD | Awaiting customer validation |
| gis-technology-lifecycle-intelligence | AI-powered EOL tracking via Claude API | Q2 2026 | Backlog |

---

## Review Schedule

| Review Type | Frequency | Next Review |
|-------------|-----------|-------------|
| Architecture Board | Monthly | 2026-02-28 |
| Security Review | Quarterly | 2026-03-01 |
| Compliance Audit | Annual | 2026-06-01 |
| Manifest Update | As needed | After major milestones |

---

## Architecture Change Archive

*For detailed change entries from previous periods:*

### Recent History (2026)
- **2026-01-15 to 2026-01-31:** See **gis-architecture-changelog-v1_6.md**
  - Phase 25: IT Service Budgets
  - Phase 25.1: Data Centers & Standard Regions
  - Cost Summary UI Enhancements
  - Namespace Boundary Enforcement
  - Composite Applications Architecture (designed)
  - Budget Management Architecture

### Earlier History (2025)
- **2025-12-01 to 2026-01-29:** See **gis-architecture-changelog-v1_5.md**
  - Cost Analysis UI & Assessment Configuration
  - Riverside Demo Namespace Architecture
  - Budget Alerts Architecture
  - Test Data & Operational Documentation
  - Organizations Boolean Role Flags
  - Analytics & Regional Architecture Updates

- **2025-12-12 to 2025-12-21:** See **gis-architecture-changelog-v1_2.md** through **v1_4.md**
  - Initial architecture corrections (10 inconsistencies resolved)
  - Architecture Decision Records (ADRs)
  - Federated Catalog model
  - Namespace/Workspace scoping rules
  - NextGen multi-region architecture
  - QuickSight integration

---

## Document Version History

For current document versions, architecture principles, technology stack, and schema statistics, see:

**→ gis-architecture-manifest-v1_15.md** (or latest version)

The manifest provides:
- Complete document version matrix (53+ documents)
- Architecture principles and golden rules
- Technology stack details
- Current schema statistics
- Implementation roadmap
- Document conventions

---

## Change Log Maintenance

### When to Update This Document

**Add new entry** when:
- New architecture document created
- Significant document version update (major/minor)
- Schema changes affecting multiple tables
- New architectural patterns introduced
- Major bug fixes with architectural implications

**Update Pending Changes** when:
- New work items identified
- Status changes (Backlog → Planned → In Progress → Complete)
- Target dates change
- Items are completed (move to Recent Changes, remove from Pending)

**Update Review Schedule** when:
- Governance cadence changes
- Review dates are rescheduled
- New review types added

### Versioning Strategy

**Create new changelog version** when:
- Approximately 3 months of changes accumulated
- File exceeds ~500 lines
- Major milestone reached (e.g., Phase 30, production launch)

**Archive older versions** when:
- Versions are 2+ years old
- Moving to /archive/changelogs/ directory
- Consolidating into annual archives (e.g., gis-architecture-changelog-2024-2025.md)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.7 | 2026-01-31 | Restructured to hybrid reference-based approach. Preserved Pending Changes and Review Schedule. Added clear references to v1.6, v1.5, and earlier versions. Added maintenance guidelines. |
| v1.6 | 2026-01-31 | Phase 25 (IT Service budgets), Phase 25.1 (data centers), Cost Summary enhancements, namespace boundary enforcement |
| v1.5 | 2026-01-29 | Cost Analysis UI, Riverside demo, budget alerts, test data documentation |
| v1.2-v1.4 | 2025-12 to 2026-01 | Earlier cumulative versions with complete history |

---

*Document: gis-architecture-changelog-v1_7.md*  
*Last Updated: January 31, 2026*  
*Next Update: As architectural changes occur*
