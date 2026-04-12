# Session Prompt 02 — Integration Field Parity: SFTP Transport + Integration Contacts

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: Session 01 must be merged to `dev` (schema applied, types updated, dates/notes in form).
> Estimated: 60-75 min.

---

## Task: Add collapsible SFTP transport section and integration contacts UI to the AddConnectionModal

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

Session 01 added lifecycle dates, notes, and SLA description to the integration form. This session completes the field parity work by adding: (1) a collapsible SFTP transport section with 3 fields, and (2) integration contact management inline in the form. The `integration_contacts` junction table already exists in the database with proper role types — it just needs UI wiring. Full spec at `docs-architecture/features/integrations/integration-field-parity-design.md`.

### Hard rules

1. **Branch:** `feat/integration-field-parity-p2`. Create from `dev`.
2. **Run `npx tsc --noEmit` AND `npm run build` before committing.**
3. **Reuse existing components:** `ContactPicker.tsx` for contact selection. Do NOT build a new contact picker.
4. **Contact saves go directly to `integration_contacts` table** — NOT part of the main form save payload. Each add/remove is an immediate DB operation (same pattern as `ApplicationContactsEditor`).
5. **All dropdowns fetch from reference tables.** No hardcoded values.
6. **You MAY only modify:**
   - `src/components/integrations/AddConnectionModal.tsx`
   - `src/components/integrations/` (can create new sub-components if needed)
   - `docs-architecture/features/integrations/architecture.md`
   - `docs-architecture/MANIFEST.md`
7. **Dual-repo commit** for the architecture doc updates.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/integrations/integration-field-parity-design.md
   - Sections "Transport Section Detail" and "Contacts UI Detail"

2. src/components/integrations/AddConnectionModal.tsx (full file)
   - Updated in Session 01 — note where lifecycle dates and notes were inserted
   - Note the save payload structure

3. src/components/applications/ApplicationContactsEditor.tsx (full file)
   - Pattern for per-role contact management with inline add/remove
   - This is your primary reference for the contacts section

4. src/components/shared/LeadershipEditor.tsx
   - Alternative pattern: role assignment + primary indicator (Crown icon)

5. src/components/ContactPicker.tsx
   - Contact search/selection component to reuse

6. docs-architecture/schema/nextgen-schema-current.sql
   - Search for "integration_contacts" — the table already exists
   - Note role_type CHECK: 'integration_owner', 'technical_sme', 'data_steward',
     'vendor_contact', 'support_contact', 'other'
```

### Step 2 — Verify integration_contacts table

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm table structure
psql "$DATABASE_READONLY_URL" -c "\d public.integration_contacts"

# Check existing data
psql "$DATABASE_READONLY_URL" -c "SELECT count(*) FROM integration_contacts"

# Confirm SFTP columns exist from Session 01
psql "$DATABASE_READONLY_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'application_integrations' AND column_name LIKE '%sftp%'"
```

### Step 3 — Impact analysis

```bash
grep -r "integration_contacts" src/ --include="*.ts" --include="*.tsx" -n
grep -r "ContactPicker" src/ --include="*.tsx" -n
grep -r "ApplicationContactsEditor" src/ --include="*.tsx" -n
grep -r "sftp" src/ --include="*.ts" --include="*.tsx" -n
```

### Step 4 — Add SFTP transport section to AddConnectionModal

Insert after the Data Classification / Sensitivity row, before Data Tags. Use progressive disclosure:

**Add state variables:**
```typescript
const [sftpRequired, setSftpRequired] = useState(false);
const [sftpHost, setSftpHost] = useState('');
const [sftpCredentialsStatus, setSftpCredentialsStatus] = useState('');
const [transportExpanded, setTransportExpanded] = useState(false);
```

**Pre-populate in edit mode:**
```typescript
setSftpRequired(initialData.sftp_required || false);
setSftpHost(initialData.sftp_host || '');
setSftpCredentialsStatus(initialData.sftp_credentials_status || '');
setTransportExpanded(initialData.sftp_required || false);
```

**Render collapsible section:**
```tsx
{/* Transport Section */}
<div className="border border-gray-200 rounded-lg">
  <button
    type="button"
    onClick={() => setTransportExpanded(!transportExpanded)}
    className="w-full flex items-center justify-between px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
  >
    <span>Transport</span>
    <ChevronDownIcon className={`w-4 h-4 transition-transform ${transportExpanded ? 'rotate-180' : ''}`} />
  </button>
  {transportExpanded && (
    <div className="px-4 pb-4 space-y-3">
      {/* SFTP Required toggle */}
      <label className="flex items-center gap-2">
        <input type="checkbox" checked={sftpRequired} onChange={(e) => setSftpRequired(e.target.checked)} />
        <span className="text-sm text-gray-700">SFTP Required</span>
      </label>
      {sftpRequired && (
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">SFTP Host</label>
            <input
              type="text"
              value={sftpHost}
              onChange={(e) => setSftpHost(e.target.value)}
              placeholder="sftp.example.com"
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Credentials Status</label>
            <select
              value={sftpCredentialsStatus}
              onChange={(e) => setSftpCredentialsStatus(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
            >
              <option value="">Not specified</option>
              <option value="configured">Configured</option>
              <option value="pending">Pending</option>
              <option value="not_required">Not Required</option>
            </select>
          </div>
        </div>
      )}
    </div>
  )}
</div>
```

**Update save payload** — add to the existing payload:
```typescript
sftp_required: sftpRequired,
sftp_host: sftpRequired ? (sftpHost || null) : null,
sftp_credentials_status: sftpRequired ? (sftpCredentialsStatus || null) : null,
```

### Step 5 — Add integration contacts section

Insert after Data Tags, before Description. This section manages `integration_contacts` rows directly — it does NOT batch with the main form save.

**Approach:** Create an inline `IntegrationContactsSection` component (either as a separate file in `src/components/integrations/` or inline in the modal). Follow the `ApplicationContactsEditor` pattern.

**For existing integrations (edit mode):**
1. Fetch contacts from `integration_contacts` joined with `contacts` table (or from `vw_integration_contacts` view) where `integration_id = initialData.id`
2. Display as compact rows: `Name (Role)` with primary star + remove icon
3. "Add Contact" button → opens `ContactPicker` with namespace scope
4. On contact selected → show role dropdown (Integration Owner, Technical SME, Data Steward, Vendor Contact, Support Contact, Other) → INSERT into `integration_contacts`
5. On remove → DELETE from `integration_contacts`
6. On primary toggle → UPDATE `integration_contacts` (unset old primary, set new)

**For new integrations (create mode):**
- Contacts section is hidden (or shows "Save the connection first to add contacts")
- Cannot add contacts until the integration record exists (need the `integration_id`)

**Role display names** (map from code to display):
| Code | Display Name |
|------|-------------|
| `integration_owner` | Integration Owner |
| `technical_sme` | Technical SME |
| `data_steward` | Data Steward |
| `vendor_contact` | Vendor Contact |
| `support_contact` | Support Contact |
| `other` | Other |

### Step 6 — Update architecture docs

**`docs-architecture/features/integrations/architecture.md`:**
- Update the field list to include lifecycle dates, SFTP transport fields, notes, SLA description
- Note that `integration_contacts` now has UI in the AddConnectionModal
- Reference the field parity design spec

**`docs-architecture/MANIFEST.md`:**
- Bump version for `integrations/architecture.md`
- Add changelog entry

### Step 7 — Verify

```bash
npx tsc --noEmit
npm run build
```

### Step 8 — Commit both repos

```bash
# Code repo
cd ~/Dev/getinsync-nextgen-ag
git add src/components/integrations/
git commit -m "feat: integration field parity Phase 2 — SFTP transport section, integration contacts UI"
git push -u origin feat/integration-field-parity-p2

# Architecture repo
cd ~/getinsync-architecture
git add -A
git commit -m "docs: integration architecture — field parity updates (SFTP, contacts, lifecycle dates)"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] `npx tsc --noEmit` passes
- [ ] `npm run build` succeeds
- [ ] Transport section is collapsible (collapsed by default)
- [ ] SFTP Required toggle shows/hides Host + Credentials Status fields
- [ ] SFTP fields save correctly to `application_integrations`
- [ ] SFTP fields pre-populate in edit mode
- [ ] Contacts section shows existing integration contacts (edit mode)
- [ ] "Add Contact" opens ContactPicker with role dropdown
- [ ] Contact add/remove saves directly to `integration_contacts` table
- [ ] Primary contact toggle works
- [ ] New integration mode shows "Save first to add contacts" message
- [ ] Architecture doc updated with field parity changes
- [ ] Both repos committed and pushed

### What NOT to do

- Do NOT build a new ContactPicker — reuse the existing one
- Do NOT batch contact operations with the main form save — contacts save immediately
- Do NOT add sftp_credentials_status options as hardcoded values if they can come from a reference table (but since this is a 3-value CHECK constraint, hardcoded is acceptable here — there is no reference table for this)
- Do NOT modify the integration reference tables (direction vocabulary change is deferred)
- Do NOT touch other integration components (ConnectionsVisual, etc.)
- Do NOT modify AI Chat tools (server context builder is separate work)
