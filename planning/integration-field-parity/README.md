# Integration Field Parity (OG → NextGen) — Session Prompt Index

**Feature spec:** `docs-architecture/features/integrations/integration-field-parity-design.md`
**Open item:** #94 in `planning/open-items-priority-matrix.md`
**Created:** April 12, 2026

---

## Execution Order & Dependencies

```
01-schema-low-hanging    Stuart applies SQL, then session adds UI for dates + notes/SLA
      |
02-transport-contacts    Sequential (needs Phase 1 merged)
```

## Session Summary

| # | Prompt | Branch | Est. Time | Depends On |
|---|--------|--------|-----------|------------|
| 01 | `01-session-prompt-schema-dates-notes.md` | `feat/integration-field-parity-p1` | 45-60 min | None (SQL applied by Stuart) |
| 02 | `02-session-prompt-transport-contacts.md` | `feat/integration-field-parity-p2` | 60-75 min | 01 merged to dev |

**Total:** ~2-2.5 hours.

## What Each Session Covers

**Session 01 — Schema + Lifecycle Dates + Notes/SLA UI:**
- SQL: 5 new columns on `application_integrations`, 3 method type seeds, view update
- TypeScript: Update VwIntegrationDetail + NewIntegrationInput types
- UI: Add lifecycle date pickers + surface notes/sla_description textareas in AddConnectionModal

**Session 02 — Transport Section + Integration Contacts:**
- UI: Build collapsible SFTP transport section in AddConnectionModal
- UI: Wire integration contacts into the form (ContactPicker + role selector)
- Contact CRUD directly on `integration_contacts` table

## Notes for Stuart

- **Between creating branch and Session 01:** Stuart applies the SQL script (ALTER TABLE + INSERT seeds + ALTER VIEW) via Supabase SQL Editor
- **Item #49 in open-items matrix** (DROP CHECK constraints on application_integrations) should ideally be done before or alongside Session 01, since the new `sftp_credentials_status` column has its own CHECK and the existing CHECK constraints on other columns block adding new reference table values. Not a hard blocker but recommended.
