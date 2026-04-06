# COR Demo Data Reset — Session Guide

**Version:** 1.0
**Date:** April 6, 2026
**Companion to:** `planning/cor-demo-data-reset.md` (design doc) and `planning/cor-demo-data-reset-implementation-plan.md` (plan)

---

## How to Use This Document

Each "chunk" below is a self-contained Claude Code session prompt. Copy the prompt block into a new Claude Code window.

**Rules:**
- Run chunks in order — each lists prerequisites
- Stuart applies SQL scripts in Supabase SQL Editor — Claude Code does NOT execute SQL
- After running SQL, tell Claude "schema done" or "data applied" — it will run validation
- The feature branch `feat/csdm-demo-data-consistency` has UI code already committed
- If a session runs out of context, start a new window with the next chunk

**Important files:**
- Design doc: `docs-architecture/planning/cor-demo-data-reset.md`
- Implementation plan: `docs-architecture/planning/cor-demo-data-reset-implementation-plan.md`
- Phase 1 DELETE: `docs-architecture/schema/cor-demo-data-reset-phase1-delete.sql`
- Phase 2 INSERT: `docs-architecture/schema/cor-demo-data-reset-phase2-insert.sql`

**Estimated total:** 4 chunks across ~3-4 hours

---

## Chunk 1 — DB: Apply Phase 1 DELETE (Stuart runs SQL)

**Prerequisites:** None
**Output:** Empty COR namespace (all apps, DPs, IT services, products deleted)

Stuart runs `docs-architecture/schema/cor-demo-data-reset-phase1-delete.sql` in Supabase SQL Editor. This is a single transaction with 31 DELETE statements. The script has a pre-flight check that aborts if the namespace UUID doesn't match "City of Riverside."

**After Stuart runs the DELETE script:**

```
The COR demo data Phase 1 DELETE has been applied. All applications, deployment
profiles, IT services, software products, technology products, integrations,
contacts, findings, ideas, initiatives, assessments, and portfolio assignments
have been deleted from the City of Riverside namespace
(a1b2c3d4-e5f6-7890-abcd-ef1234567890).

Preserved: workspaces (18 + AGL), users, workspace_users, organizations (31
vendor orgs), data centers, technology_lifecycle_reference (82 global records),
service type categories, technology product categories, portfolios, teams,
assessment factors/thresholds, reference tables.

Run the Phase 1 verification queries from the bottom of the DELETE script to
confirm all counts are zero:

Using DATABASE_READONLY_URL, run:
SELECT 'applications' as tbl, count(*) FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'deployment_profiles', count(*) FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'it_services', count(*) FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'software_products', count(*) FROM software_products
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'technology_products', count(*) FROM technology_products
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

All counts should be 0. Report results.
```

---

## Chunk 2 — DB: Apply Phase 2 INSERT (Stuart runs SQL)

**Prerequisites:** Chunk 1 complete (COR namespace empty)
**Output:** 30 apps, 42 DPs, 12 IT services, full CSDM wiring

Stuart runs `docs-architecture/schema/cor-demo-data-reset-phase2-insert.sql` in Supabase SQL Editor. This is a single transaction with 16 INSERT phases.

**After Stuart runs the INSERT script:**

```
The COR demo data Phase 2 INSERT has been applied. Read the implementation plan
at docs-architecture/planning/cor-demo-data-reset-implementation-plan.md for
context on what was created.

Run mid-session schema checkpoint:
1. Security posture validation (zero FAIL rows = pass)
2. TypeScript check (zero errors = pass)

Then run these verification queries against DATABASE_READONLY_URL:

-- Count all major entities
SELECT 'applications' as entity, count(*) FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'deployment_profiles', count(*) FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'it_services', count(*) FROM it_services
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'software_products', count(*) FROM software_products
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'technology_products', count(*) FROM technology_products
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'infra_dps', count(*) FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND dp.dp_type = 'infrastructure'
UNION ALL SELECT 'cost_bundle_dps', count(*) FROM deployment_profiles dp
  JOIN workspaces w ON dp.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND dp.dp_type = 'cost_bundle'
UNION ALL SELECT 'it_svc_providers', count(*) FROM it_service_providers isp
  JOIN it_services its ON isp.it_service_id = its.id
  WHERE its.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'it_svc_tech_links', count(*) FROM it_service_technology_products istp
  JOIN it_services its ON istp.it_service_id = its.id
  WHERE its.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL SELECT 'integrations', count(*) FROM application_integrations ai
  JOIN applications a ON ai.source_application_id = a.id
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

Expected targets:
- applications: ~30
- deployment_profiles: ~42 (30 app + 7 infra + 5 cost bundle)
- it_services: 12
- software_products: 16
- technology_products: 13
- infra_dps: 7
- cost_bundle_dps: 5
- it_svc_providers: 7
- it_svc_tech_links: ~11
- integrations: 8

Report results and flag any that are significantly off.
```

---

## Chunk 3 — Browser Verification (18-Year-Old Test)

**Prerequisites:** Chunk 2 complete, dev server running (`npm run dev`)
**Output:** Visual confirmation that every CSDM layer traces end-to-end

```
Read the design doc at docs-architecture/planning/cor-demo-data-reset.md — focus
on §7 (Verification Checklist).

The COR namespace has been rebuilt with clean demo data. I need you to verify
the full CSDM chain in the browser using localhost:5173. The feature branch
feat/csdm-demo-data-consistency has UI code for "Built on:" chips, "Powers:"
chips, "Org-wide" badges, and ServiceNode tech pills.

Run these 6 verification tests using the browser automation tools:

1. HEXAGON TRACE (IT Service path — on-prem app):
   Navigate to the Hexagon OnCall CAD/RMS application.
   - Visual tab Level 3: verify IT Services appear at bottom with tech count pills
   - Verify at least 5 IT Services linked (Windows Server Hosting, SQL Server
     DB Services, Enterprise Backup, Cybersecurity, Network, Identity & Access)

2. AXON TRACE (Cost Bundle path — SaaS app):
   Navigate to Axon Evidence.
   - Deployments & Costs tab: verify Cost Bundle with $120K, contract date,
     vendor "Axon Enterprise"
   - Visual tab: verify Azure Cloud Hosting + Identity & Access shown

3. IT SERVICE CATALOG:
   Navigate to Settings → IT Service Catalog.
   - Expand Compute: verify Application Hosting shows "Built on:" chips
     (Windows Server 2019, Windows Server 2022)
   - Verify Infrastructure column shows "Windows Server Farm — City Hall"
   - Expand Database: verify SQL Server Database Services shows tech chips

4. TECHNOLOGY CATALOG:
   Navigate to Settings → Technology Catalog.
   - Find SQL Server 2019: verify "Powers: SQL Server Database Services" chip
   - Find Windows Server 2022: verify multiple "Powers:" chips
   - Verify lifecycle badges (Extended Support, Mainstream) appear

5. SOFTWARE CATALOG:
   Navigate to Settings → Software Catalog.
   - Verify all products grouped by manufacturer (no "No Manufacturer" group)
   - Verify "Org-wide" amber badges on Microsoft 365, Adobe Creative Cloud, Zoom

6. IT SERVICE MODAL:
   Click edit on "Application Hosting" in IT Service Catalog.
   - Verify Infrastructure Providers section shows "Windows Server Farm — City Hall"
   - Click "+ Link Infrastructure" and search — verify infrastructure DPs appear
     in the search results

Take screenshots of each test. Report any failures.
```

---

## Chunk 4 — Merge and Deploy

**Prerequisites:** Chunk 3 passes all 6 tests
**Output:** Feature merged to dev → main, Netlify deploys

```
All verification tests passed. Time to merge the feature branch.

Current state:
- Branch: feat/csdm-demo-data-consistency
- Contains: UI changes for catalog cross-references and ServiceNode enrichment
- Status: committed and pushed, type check + build passing

Merge to dev:
cd ~/Dev/getinsync-nextgen-ag
git checkout dev
git pull origin dev
git merge feat/csdm-demo-data-consistency
git push origin dev

Then merge dev to main for Netlify deploy:
git checkout main
git pull origin main
git merge dev
git push origin main

After push, verify Netlify deploys successfully. Then run the session-end
checklist:
- Read and execute docs-architecture/operations/session-end-checklist.md

Note: The version should bump to 2026.4.5 since this is a user-visible change
(new catalog cross-references, infrastructure provider visibility).
```

---

## Chunk 5 (SEPARATE) — Remove IT Service Modal Lifecycle Section

**Prerequisites:** None (independent of data reset, can run anytime)
**Output:** Simplified IT Service Modal

```
Read docs-architecture/planning/cor-demo-data-reset.md §2b for context on
why the Technology Lifecycle section is being removed from the IT Service Modal.

Summary: The IT Service Modal has a collapsible "Technology Lifecycle" section
that links a single lifecycle_reference_id to the IT Service. Zero services use
this field. It's architecturally wrong — an IT Service like "SQL Server Database
Services" runs multiple tech products (SQL Server 2019 + 2022), each with
different lifecycle dates. The lifecycle risk should derive from the component
tech products (shown via "Built on:" chips), not a direct field on the service.

Task: Remove the Technology Lifecycle section from ITServiceModal.tsx.
- Remove the lifecycle_reference_id field from the form
- Remove the collapsible Technology Lifecycle section UI
- Remove the lifecycle reference search/create/AI lookup logic
- Keep the lifecycle_reference_id column in the database (it's harmless, just unused)
- Do NOT touch the LifecycleBadge on IT Service Catalog rows — that can stay
  (it reads from it_services.lifecycle_reference, which is always NULL)

Impact analysis first:
grep -r "lifecycle_reference" src/ --include="*.ts" --include="*.tsx"

Verify no other component depends on the IT Service lifecycle reference
before removing.

Create a feature branch: feat/remove-it-service-lifecycle
Type check + build after changes.
Update docs-architecture/catalogs/it-service.md to note the removal.
```

---

## Quick Reference — What's Where

| Artifact | Location |
|----------|----------|
| Design doc (target state) | `docs-architecture/planning/cor-demo-data-reset.md` |
| Implementation plan | `docs-architecture/planning/cor-demo-data-reset-implementation-plan.md` |
| Phase 1 DELETE script | `docs-architecture/schema/cor-demo-data-reset-phase1-delete.sql` |
| Phase 2 INSERT script | `docs-architecture/schema/cor-demo-data-reset-phase2-insert.sql` |
| UI code branch | `feat/csdm-demo-data-consistency` (pushed to origin) |
| This session guide | `docs-architecture/planning/cor-demo-data-session-guide.md` |
| April level-set | `docs-architecture/planning/april-2026-level-set.md` |
| April session guide | `docs-architecture/planning/april-2026-session-guide.md` |
