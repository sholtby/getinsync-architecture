# Session Prompt 01 — Integration Field Parity: Schema + Lifecycle Dates + Notes/SLA UI

> **Copy everything below the `---` line into a fresh Claude Code session.**
> This session generates SQL, updates types, and adds 4 form fields to AddConnectionModal (~45-60 min).
> Stuart must apply the SQL before the TypeScript/UI work begins.

---

## Task: Add lifecycle dates, surface notes/SLA, and expand method types for the integration form

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

A field-by-field comparison of GetInSync OG integration screens against NextGen revealed several gaps. OG captures lifecycle start/end dates, SFTP transport details, and contact SMEs — most of which end up in free-text Notes fields in the OG app. NextGen has `notes` and `sla_description` columns in the database but doesn't render them in the UI form. Additionally, method types like "BIRT" (report engine) have no matching code in `integration_method_types`. Full spec at `docs-architecture/features/integrations/integration-field-parity-design.md`.

This is Phase 1 of 2: schema changes + low-hanging UI fruit (lifecycle dates, notes, SLA description). Phase 2 (Session 02) adds the SFTP transport section and integration contacts in the form.

### Hard rules

1. **Branch:** `feat/integration-field-parity-p1`. Create from `dev`.
2. **SQL generation:** Create a `.sql` file in `docs-architecture/planning/sql/integration-field-parity/`. Stuart applies manually. Do NOT execute SQL.
3. **After Stuart confirms SQL applied**, proceed with TypeScript and UI changes.
4. **Run `npx tsc --noEmit` AND `npm run build` before committing.**
5. **You MAY only modify:**
   - SQL output file (generated, not executed)
   - `src/types/view-contracts.ts`
   - `src/types/integration-types.ts`
   - `src/components/integrations/AddConnectionModal.tsx`
6. **Do NOT build the SFTP transport section or contacts UI** — that is Session 02.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/integrations/integration-field-parity-design.md
   - Full spec. Focus on "Schema Changes" and the Phase 1 scope.

2. src/components/integrations/AddConnectionModal.tsx (full file, 728 lines)
   - Understand the current form layout, state management, save flow
   - Note where Description textarea is rendered (~line 686)
   - Note the save payload construction (~lines 279-310)

3. src/types/view-contracts.ts
   - VwIntegrationDetail interface (find it — ~30 fields)

4. src/types/integration-types.ts
   - NewIntegrationInput interface

5. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "application_integrations" to see current table definition
   - Search for "vw_integration_detail" to see current view definition
```

### Step 2 — Generate SQL script

Create `docs-architecture/planning/sql/integration-field-parity/01-schema-updates.sql`:

```sql
-- Integration Field Parity — Phase 1 Schema Changes
-- Apply via Supabase SQL Editor

BEGIN;

-- 1. Add lifecycle date columns
ALTER TABLE public.application_integrations
  ADD COLUMN IF NOT EXISTS lifecycle_start_date date,
  ADD COLUMN IF NOT EXISTS lifecycle_end_date date;

-- 2. Add SFTP transport columns (UI in Phase 2, but schema now)
ALTER TABLE public.application_integrations
  ADD COLUMN IF NOT EXISTS sftp_required boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sftp_host text,
  ADD COLUMN IF NOT EXISTS sftp_credentials_status text;

-- Add CHECK constraint for sftp_credentials_status
ALTER TABLE public.application_integrations
  ADD CONSTRAINT application_integrations_sftp_credentials_check
  CHECK (sftp_credentials_status IS NULL OR sftp_credentials_status IN ('configured', 'pending', 'not_required'));

-- 3. Add new integration method type seeds
INSERT INTO public.integration_method_types (id, code, name, description, display_order, is_active, is_system, created_at)
VALUES
  (gen_random_uuid(), 'report', 'Report Engine', 'BIRT, Crystal Reports, SSRS, JasperReports', 80, true, true, now()),
  (gen_random_uuid(), 'etl', 'ETL Pipeline', 'SSIS, Informatica, Talend, DataStage', 90, true, true, now()),
  (gen_random_uuid(), 'message_queue', 'Message Queue', 'RabbitMQ, Kafka, Azure Service Bus', 100, true, true, now())
ON CONFLICT (code) DO NOTHING;

-- 4. Update vw_integration_detail to include new columns
-- First check current definition, then CREATE OR REPLACE
-- NOTE: If columns were added, CREATE OR REPLACE should work.
-- If it doesn't (column count changed), use DROP + CREATE.

COMMIT;
```

**Important:** Before writing the view update, use the read-only DB connection to get the current view definition:

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -c "SELECT pg_get_viewdef('vw_integration_detail', true)"
```

Then add the 5 new columns (`lifecycle_start_date`, `lifecycle_end_date`, `sftp_required`, `sftp_host`, `sftp_credentials_status`) to the SELECT list. The view update goes after the COMMIT above (views can't be in a transaction that alters the table they reference).

Add a consolidated verification SELECT at the end of the script.

### Step 3 — Wait for Stuart to apply SQL

Tell Stuart: "SQL script ready at `docs-architecture/planning/sql/integration-field-parity/01-schema-updates.sql`. Please apply via Supabase SQL Editor and confirm."

### Step 4 — Verify schema via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm new columns exist
psql "$DATABASE_READONLY_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'application_integrations' AND column_name IN ('lifecycle_start_date', 'lifecycle_end_date', 'sftp_required', 'sftp_host', 'sftp_credentials_status') ORDER BY column_name"

# Confirm new method types exist
psql "$DATABASE_READONLY_URL" -c "SELECT code, name FROM integration_method_types WHERE code IN ('report', 'etl', 'message_queue')"

# Confirm view has new columns
psql "$DATABASE_READONLY_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'vw_integration_detail' AND column_name LIKE '%lifecycle%' OR column_name LIKE '%sftp%' ORDER BY column_name"
```

### Step 5 — Update TypeScript types

**`src/types/view-contracts.ts` — VwIntegrationDetail:**

Add 5 fields:
```typescript
lifecycle_start_date: string | null;
lifecycle_end_date: string | null;
sftp_required: boolean;
sftp_host: string | null;
sftp_credentials_status: string | null;
```

**`src/types/integration-types.ts` — NewIntegrationInput:**

Add 6 fields:
```typescript
lifecycleStartDate?: string | null;
lifecycleEndDate?: string | null;
sftpRequired?: boolean;
sftpHost?: string | null;
sftpCredentialsStatus?: string | null;
slaDescription?: string | null;
notes?: string | null;
```

### Step 6 — Update AddConnectionModal form

In `src/components/integrations/AddConnectionModal.tsx`:

**Add form state variables:**
```typescript
const [lifecycleStartDate, setLifecycleStartDate] = useState('');
const [lifecycleEndDate, setLifecycleEndDate] = useState('');
const [slaDescription, setSlaDescription] = useState('');
const [notes, setNotes] = useState('');
```

**Pre-populate in edit mode** (where `initialData` is loaded):
```typescript
setLifecycleStartDate(initialData.lifecycle_start_date || '');
setLifecycleEndDate(initialData.lifecycle_end_date || '');
setSlaDescription(initialData.sla_description || '');
setNotes(initialData.notes || '');
```

**Add lifecycle date pickers** — insert after the Status/Data Format row (after ~line 625, before the Sensitivity row):

```tsx
{/* Lifecycle Dates */}
<div className="grid grid-cols-2 gap-4">
  <div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Lifecycle Start Date</label>
    <input
      type="date"
      value={lifecycleStartDate}
      onChange={(e) => setLifecycleStartDate(e.target.value)}
      className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
      disabled={saving}
    />
  </div>
  <div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Lifecycle End Date</label>
    <input
      type="date"
      value={lifecycleEndDate}
      onChange={(e) => setLifecycleEndDate(e.target.value)}
      className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
      disabled={saving}
    />
  </div>
</div>
```

**Surface Notes and SLA Description** — insert after the Description textarea (~line 697), before the save button:

```tsx
{/* SLA Description */}
<div>
  <label className="block text-sm font-medium text-gray-700 mb-1">SLA Description</label>
  <textarea
    value={slaDescription}
    onChange={(e) => setSlaDescription(e.target.value)}
    rows={2}
    placeholder="Service level expectations, response times, uptime requirements..."
    className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
    disabled={saving}
  />
</div>

{/* Notes */}
<div>
  <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
  <textarea
    value={notes}
    onChange={(e) => setNotes(e.target.value)}
    rows={3}
    placeholder="Additional context, historical information, migration notes..."
    className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
    disabled={saving}
  />
</div>
```

**Update save payload** (~lines 279-310) — add to the payload object:

```typescript
lifecycle_start_date: lifecycleStartDate || null,
lifecycle_end_date: lifecycleEndDate || null,
sla_description: slaDescription || null,
notes: notes || null,
// Do NOT add sftp fields yet — that is Session 02
```

### Step 7 — Verify

```bash
npx tsc --noEmit
npm run build
```

### Step 8 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add docs-architecture/planning/sql/integration-field-parity/ src/types/view-contracts.ts src/types/integration-types.ts src/components/integrations/AddConnectionModal.tsx
git commit -m "feat: integration field parity Phase 1 — lifecycle dates, notes/SLA UI, method type seeds"
git push -u origin feat/integration-field-parity-p1
```

### Done criteria checklist

- [ ] SQL script generated at `docs-architecture/planning/sql/integration-field-parity/01-schema-updates.sql`
- [ ] SQL applied by Stuart (5 new columns, 3 method seeds, view updated)
- [ ] TypeScript types updated (VwIntegrationDetail + NewIntegrationInput)
- [ ] AddConnectionModal has lifecycle start/end date pickers
- [ ] AddConnectionModal has SLA Description textarea
- [ ] AddConnectionModal has Notes textarea
- [ ] All 4 new fields pre-populate correctly in edit mode
- [ ] Save payload includes all 4 new fields
- [ ] `npx tsc --noEmit` passes
- [ ] `npm run build` succeeds

### What NOT to do

- Do NOT build the SFTP transport section (collapsible) — that is Session 02
- Do NOT build the integration contacts UI — that is Session 02
- Do NOT execute SQL — Stuart applies manually
- Do NOT modify `docs-architecture/features/integrations/architecture.md` — defer to Session 02
- Do NOT drop CHECK constraints on existing columns (that is item #49, separate work)
