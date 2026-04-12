# Integration Field Parity Design — OG to NextGen

**Version:** 1.0
**Date:** April 12, 2026
**Status:** DRAFT
**Author:** Stuart Holtby + Claude
**Relates to:** `features/integrations/architecture.md`, `adr/adr-dp-infrastructure-boundary.md`

---

## Problem Statement

Comparison of GetInSync OG integration screens against NextGen reveals several gaps where structured data is either missing from the schema or present in the database but not exposed in the UI. The most significant issue is that customers are capturing structured information (contact SMEs, SFTP transport details, lifecycle dates) in free-text Notes fields, orphaning data that should be queryable and reportable.

### Evidence from OG Screenshots (City of Garland)

**External Integration (BIRT-03 Customer Invoice) — Notes field contains:**
- `Description: BIRT: Customer Invoice Layout...` → Should be in `description` field (exists in NextGen)
- `Customer Contact SME: Elizabeth Morales` → Should be in `integration_contacts` table (table exists, no UI)
- `Schedule: On demand` → Should be in `frequency` field (exists in NextGen)
- `SFTP Setup: Not required` → No structured field exists
- `SFTP Credentials: Not required` → No structured field exists

**Internal Integration (Workday) — Notes field contains:**
- `provide employee pictures into workday.` → Should be in `description` field (exists in NextGen)

---

## Goals

1. **Close field gaps** between OG and NextGen integration forms
2. **Rescue structured data from Notes** by adding proper fields for lifecycle dates, SFTP transport, and contact SMEs
3. **Surface existing DB columns** (`notes`, `sla_description`) that are stored but not rendered in the UI
4. **Expand method types** to cover report-engine and ETL integration patterns seen in Garland data

---

## Non-Goals

- Direction vocabulary change (OG "Publish/Subscribe" vs NextGen "upstream/downstream") — cosmetic, defer
- Inline organization creation from the form ("+ Add New Company") — low priority, defer
- Integration scoring or health metrics
- Bulk import of integration records

---

## Scope Summary

| Change | Type | Complexity |
|--------|------|------------|
| Lifecycle start/end dates | New columns + UI | Low |
| SFTP transport fields | New columns + UI (collapsible section) | Medium |
| Contact SME in form | Wire existing table to existing UI components | Medium |
| Notes + SLA Description in form | Surface existing columns | Low |
| Expand method types | Seed data + reference table | Low |
| Update view + TypeScript types | Schema + types | Low |

---

## Schema Changes

### New Columns on `application_integrations`

| Column | Type | Default | Nullable | Notes |
|--------|------|---------|----------|-------|
| `lifecycle_start_date` | date | — | YES | When integration went live or is planned to start |
| `lifecycle_end_date` | date | — | YES | When integration is expected to retire |
| `sftp_required` | boolean | `false` | NO | Whether the integration uses SFTP transport |
| `sftp_host` | text | — | YES | SFTP endpoint (relevant only when sftp_required = true) |
| `sftp_credentials_status` | text | — | YES | CHECK: `'configured'`, `'pending'`, `'not_required'` |

No new tables needed. The `integration_contacts` junction table already exists with appropriate role types.

### Seed Data: `integration_method_types`

Add 3 new method codes to cover patterns seen in Garland data:

| code | name | description | display_order |
|------|------|-------------|---------------|
| `report` | Report Engine | BIRT, Crystal Reports, SSRS, JasperReports | 80 |
| `etl` | ETL Pipeline | SSIS, Informatica, Talend, DataStage | 90 |
| `message_queue` | Message Queue | RabbitMQ, Kafka, Azure Service Bus | 100 |

### View Update: `vw_integration_detail`

Add to the SELECT list:
- `ai.lifecycle_start_date`
- `ai.lifecycle_end_date`
- `ai.sftp_required`
- `ai.sftp_host`
- `ai.sftp_credentials_status`

---

## UI Changes: AddConnectionModal

**File:** `src/components/integrations/AddConnectionModal.tsx`

### Current Form Layout
1. Mode toggle (Internal/External)
2. Connection Name
3. Source DP (conditional)
4. Target Application / External System Name + Organization
5. 6-field grid: Direction, Method, Frequency, Criticality, Status, Data Format
6. 2-field grid: Sensitivity, Data Classification
7. Data Tags (multi-select)
8. Description (textarea)
9. Save/Cancel buttons

### Updated Form Layout (changes marked with -->)

1. Mode toggle (Internal/External)
2. Connection Name
3. Source DP (conditional)
4. Target Application / External System Name + Organization
5. 6-field grid: Direction, Method, Frequency, Criticality, Status, Data Format
6. **--> 2-field grid: Lifecycle Start Date (date picker), Lifecycle End Date (date picker)**
7. 2-field grid: Sensitivity, Data Classification
8. **--> Transport section (collapsible, default collapsed):**
   - SFTP Required (toggle checkbox)
   - If checked: SFTP Host (text input, placeholder "sftp.example.com")
   - If checked: SFTP Credentials Status (dropdown: Configured / Pending / Not Required)
9. Data Tags (multi-select)
10. **--> Contacts section:**
    - List existing integration contacts as chips: `Name (Role)` with X remove button
    - "Add Contact" button → opens ContactPicker with role selector dropdown
    - Roles: Integration Owner, Technical SME, Data Steward, Vendor Contact, Support Contact, Other
    - Reuse existing `ContactPicker.tsx` component
11. Description (textarea)
12. **--> SLA Description (textarea, optional)**
13. **--> Notes (textarea, optional)**
14. Save/Cancel buttons

### Contacts UI Detail

The `integration_contacts` table already exists with these role types: `integration_owner`, `technical_sme`, `data_steward`, `vendor_contact`, `support_contact`, `other`.

**Rendering pattern:** Follow the `ApplicationContactsEditor.tsx` / `LeadershipEditor.tsx` pattern:
- Contacts displayed as compact rows with name, role badge, and remove icon
- "Add Contact" opens existing `ContactPicker` (namespace-scoped search)
- Role assigned via dropdown on the contact row
- Primary toggle (star icon) — one primary contact per integration
- Save/delete calls go directly to `integration_contacts` table (not part of the main form save payload)

### Transport Section Detail

The SFTP section uses progressive disclosure:
- Default: collapsed section header "Transport" with a chevron
- When expanded: shows the SFTP Required toggle
- When SFTP Required is checked: reveals Host and Credentials Status fields
- This keeps the form clean for integrations that don't use SFTP (majority)

---

## TypeScript Type Changes

### `src/types/view-contracts.ts` — VwIntegrationDetail

Add fields:
```typescript
lifecycle_start_date: string | null;
lifecycle_end_date: string | null;
sftp_required: boolean;
sftp_host: string | null;
sftp_credentials_status: string | null;
```

### `src/types/integration-types.ts` — NewIntegrationInput

Add fields:
```typescript
lifecycleStartDate?: string | null;
lifecycleEndDate?: string | null;
sftpRequired?: boolean;
sftpHost?: string | null;
sftpCredentialsStatus?: string | null;
slaDescription?: string | null;
notes?: string | null;
```

---

## Impact Analysis

### Files Requiring Changes

**Schema (Stuart applies via SQL Editor):**
- ALTER TABLE `application_integrations` — add 5 columns
- INSERT into `integration_method_types` — 3 new seed rows
- ALTER VIEW `vw_integration_detail` — add 5 columns to SELECT

**TypeScript:**
- `src/types/view-contracts.ts` — update VwIntegrationDetail (add 5 fields)
- `src/types/integration-types.ts` — update NewIntegrationInput (add 6 fields)
- `src/components/integrations/AddConnectionModal.tsx` — add lifecycle dates, transport section, contacts section, notes/SLA fields

**Reused Components (no changes needed):**
- `src/components/ContactPicker.tsx` — reused for integration contact selection
- `src/components/shared/SearchableSelect.tsx` — already used in the form

**Architecture Docs:**
- `docs-architecture/features/integrations/architecture.md` — update field list, add transport section, note contact UI availability
- `docs-architecture/MANIFEST.md` — bump version

---

## Phased Delivery

### Phase 1: Schema + Low-Hanging Fruit (1 session)
- SQL: Add 5 columns, 3 method seeds, update view
- TypeScript: Update types
- UI: Surface `notes` and `sla_description` textareas in form (already in DB)
- UI: Add lifecycle date pickers

### Phase 2: Transport + Contacts (1 session)
- UI: Build collapsible transport section with SFTP fields
- UI: Wire integration contacts into the form using ContactPicker
- Integration contact CRUD (save/delete directly to `integration_contacts` table)

---

## Changelog

- **v1.0 — April 12, 2026** — Initial design spec based on OG-to-NextGen field comparison.
