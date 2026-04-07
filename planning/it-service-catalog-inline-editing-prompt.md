# IT Service Catalog — Inline Editing (Chunk A)

## CC Prompt — Copy and paste into a new Claude Code session

```
IT Service Catalog — Inline Consumer Editing

Read docs-architecture/planning/it-service-catalog-enhancements.md for the full spec. This is Chunk A: add and remove IT Service consumer links directly from the IT Service Catalog.

Branch: feat/catalog-inline-editing
Session-end: Merge feat/catalog-inline-editing → dev → main. Full session-end checklist, no overrides.

Read these files before planning:
- src/pages/settings/ITServiceCatalogSettings.tsx (the catalog page — find where consumers are rendered)
- src/components/ITServiceDependencyList.tsx (existing add/remove pattern for service links)
- src/components/ServicePickerModal.tsx (existing picker pattern)
- src/types/index.ts (DeploymentProfileITService interface — has source column from Chunk 2)

Impact analysis:
grep -r "ITServiceCatalog\|service-catalog\|it_service" src/pages/settings/ --include="*.ts" --include="*.tsx"
grep -r "deployment_profile_it_services" src/ --include="*.ts" --include="*.tsx"
grep -r "ServicePickerModal\|AppPickerModal\|ApplicationPicker" src/ --include="*.ts" --include="*.tsx"

Task: Add bidirectional editing to the IT Service Catalog.

1. "+ Add Consumer" link below each service's consumer list
   - Opens a picker to select an application, then a deployment profile for that app
   - Only show apps/DPs from the same namespace
   - Only show non-SaaS DPs (SaaS apps don't consume internal IT Services)
   - Don't show DPs already linked to this service
   - On confirm: INSERT into deployment_profile_it_services with source = 'manual', relationship_type = 'depends_on'
   - Toast: "Linked [App Name] to [Service Name]"

2. Remove button (trash icon) on each consumer row
   - On hover only (same pattern as other list delete actions in the app)
   - If source = 'manual': simple confirm → delete
   - If source = 'auto': cost-aware confirm dialog (same pattern as Chunk 2 auto-unwire — show cost impact if service has annual_cost > 0)
   - Toast: "Removed [App Name] from [Service Name]"

3. Consumer count in the category header updates immediately after add/remove

4. Duplicate check: if the selected DP is already linked to this service, show "Already linked" toast and skip

Check what picker components already exist — reuse rather than build new. If there's an ApplicationPicker or similar, use it. If not, build a minimal one following the ServicePickerModal pattern.

Plan mode only. Show me the plan — do not start coding until I approve.
```
