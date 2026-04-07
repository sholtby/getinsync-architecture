# IT Service Catalog — Bulk Import (Chunk B, PARKED)

## CC Prompt — Copy and paste into a new Claude Code session when ready

```
IT Service Catalog — Bulk Import of App-to-Service Mappings

Read docs-architecture/planning/it-service-catalog-enhancements.md for the full spec. This is Chunk B: bulk import of application-to-IT Service mappings from an Excel template.

Branch: feat/catalog-bulk-import
Session-end: Merge feat/catalog-bulk-import → dev → main. Full session-end checklist, no overrides.

Read these files before planning:
- src/pages/settings/ITServiceCatalogSettings.tsx (where the import button will live)
- src/pages/ImportApplications.tsx or similar (check if a bulk import pattern already exists)
- src/types/index.ts (DeploymentProfileITService interface)
- package.json (check if SheetJS/xlsx is already a dependency)

Impact analysis:
grep -r "import\|Import\|upload\|Upload\|xlsx\|SheetJS\|csv" src/ --include="*.ts" --include="*.tsx"
grep -r "bulk\|batch\|template" src/ --include="*.ts" --include="*.tsx"

Task: Add bulk import of app-to-IT Service mappings.

1. "Import Mappings" button in the IT Service Catalog header (next to "+ Add IT Service")
   - Opens a modal with:
     a. Download template link (.xlsx with 3 columns: Application Name, Deployment Profile, IT Service + 1 example row)
     b. File upload dropzone

2. Template generation:
   - 3 columns: Application Name | Deployment Profile | IT Service
   - First row is an example using real data from the namespace
   - Sheet name: "Service Mappings"
   - Use SheetJS (xlsx library) to generate — add to dependencies if not present

3. Upload + validation:
   - Parse xlsx with SheetJS
   - For each row, validate:
     a. Application Name matches an existing app in the namespace (case-insensitive)
     b. Deployment Profile matches a DP for that app (if blank, use primary DP)
     c. IT Service matches an existing service in the namespace (case-insensitive)
     d. DP is not SaaS (SaaS guard — same as Chunk 2)
     e. Link doesn't already exist (duplicate check)
   - Fuzzy match: if no exact match but a close match exists (Levenshtein distance ≤ 3), suggest it as yellow row

4. Preview screen (modal step 2):
   - Table showing all rows with status column:
     - Green checkmark: all 3 fields matched, ready to import
     - Yellow warning: fuzzy match found, user must confirm or correct
     - Red X: field not found, row will be skipped
   - User can toggle individual rows on/off
   - Summary line: "Ready to import: X of Y rows"

5. Confirm + insert:
   - Bulk INSERT into deployment_profile_it_services with source = 'manual', relationship_type = 'depends_on'
   - ON CONFLICT DO NOTHING (safety net for any races)
   - Summary toast: "Linked X services across Y applications. Z rows skipped."

6. Scope: all operations scoped to the current namespace

Plan mode only. Show me the plan — do not start coding until I approve.
```
