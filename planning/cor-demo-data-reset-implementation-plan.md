# COR Demo Data Reset — Implementation Plan

## Context

The City of Riverside (COR) demo namespace has accumulated piecemeal data across 20+ sessions, each built with different architectural understanding. The result: cross-namespace vendor orgs, $1.7M of legacy costs on inventory-only software product junctions, 70 of 76 apps completely disconnected from IT Services, zero infrastructure DPs, and duplicate data between DP-level and IT Service-level relationships. Rather than continuing to patch, we're doing a full reset — delete all app/service/cost data in COR and rebuild ~30 apps with full end-to-end CSDM wiring against the current architecture (cost model v3.0, contract-aware cost bundles, deployed double-count guardrails).

The design document at `docs-architecture/planning/cor-demo-data-reset.md` (v0.2) defines the target state.

---

## Pre-Flight Validation (completed)

### Dan Warfield's Data — SAFE
- **User ID:** `97c5315a-e8bd-444c-98ff-29824f350937`
- **Activity:** Page views only (13 dashboard, 2 app detail, 1 assessment). **Zero data modifications.** No assessments, no apps created/edited, no DPs touched.
- **Workspace memberships:** Admin on all 18 COR workspaces — preserved (workspace_users not in delete path).
- **AGL Workspace:** Dan created workspace "AGL" (`611af8a0`) on April 2, 2026. It has 4 admin users (Demo Admin, Kip Fanta, Delta Holtby, Dan Warfield) and **0 apps**. The workspace itself is preserved (we only delete data inside workspaces). AGL remains as-is with its memberships intact.
- **Conclusion:** Nothing of Dan's to preserve beyond his user record, workspace memberships, and the AGL workspace — all untouched by the reset.

### Users/Auth — SAFE
- `users` and `workspace_users` are NOT referenced by any table in the delete path.
- Core tables (applications, deployment_profiles, it_services, software_products, technology_products) have **no `created_by`/`updated_by` columns**.
- The `audit_logs` table records activity by `user_id` but is namespace-scoped — it can be cleaned up separately or left as historical.

### FK Cascade Analysis — 3 Blockers Identified

| Table | FK Target | Delete Rule | Issue |
|-------|-----------|-------------|-------|
| `contacts` | `namespaces` | NO ACTION | 7 contacts exist — must delete explicitly before apps |
| `deployment_profile_it_services` | `it_services` | RESTRICT | 19 rows — must delete before IT services |
| `application_services` | `it_services` | RESTRICT | 0 rows — safe, but still must clear before IT services |

### Additional Tables to Delete (missing from design doc §2)

The FK analysis found these dependent tables not listed in the original design doc:

| Table | COR Row Count | FK Cascade From | Notes |
|-------|--------------|-----------------|-------|
| `application_contacts` | ~varies | CASCADE from applications | Auto-cascades |
| `application_compliance` | ~varies | CASCADE from applications | Auto-cascades |
| `application_data_assets` | ~varies | CASCADE from applications | Auto-cascades |
| `application_documents` | ~varies | CASCADE from applications | Auto-cascades |
| `application_roadmap` | ~varies | CASCADE from applications | Auto-cascades |
| `application_services` | 0 | RESTRICT from it_services | Must delete explicitly |
| `application_category_assignments` | ~varies | CASCADE from applications | Auto-cascades |
| `business_assessments` | ~varies | CASCADE from applications | Auto-cascades |
| `technical_assessments` | ~varies | CASCADE from applications | Auto-cascades |
| `deployment_profile_contacts` | ~varies | CASCADE from deployment_profiles | Auto-cascades |
| `initiative_deployment_profiles` | ~varies | CASCADE from deployment_profiles | Auto-cascades |
| `initiative_it_services` | ~varies | CASCADE from it_services | Must delete before IT services |
| `workspace_group_publications` | 2 | CASCADE from deployment_profiles | Auto-cascades |
| `contacts` | 7 | NO ACTION from namespaces | **Must delete explicitly** |
| `contact_organizations` | ~varies | CASCADE from contacts | Auto-cascades |
| `integration_contacts` | ~varies | CASCADE from integrations | Auto-cascades |
| `findings` | 8 | namespace-scoped | Must delete explicitly |
| `ideas` | 10 | namespace-scoped | Must delete explicitly |
| `initiatives` | 14 | namespace-scoped | Must delete explicitly |
| `technology_standards` | 1 | SET NULL from tech products | Safe but cleanup |
| `assessment_history` | ~varies | CASCADE from portfolio_assignments | Auto-cascades |

### Organizations — PRESERVE AND REUSE

31 vendor organizations exist in COR. Most are correctly scoped. We'll keep them all and reference their existing IDs in the rebuild INSERT statements. No organization deletions needed.

---

## Implementation — Phased SQL

### File: `docs-architecture/schema/cor-demo-data-reset-phase1-delete.sql`

Namespace-scoped DELETE statements in FK-safe dependency order. Every statement scoped to `a1b2c3d4-e5f6-7890-abcd-ef1234567890`.

**Phase 1a: Pre-flight check**
```sql
SELECT id, name FROM namespaces WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
-- Expected: "City of Riverside". If anything else, STOP.
```

**Phase 1b: Delete blockers (RESTRICT/NO ACTION tables)**
1. `technology_standards` WHERE namespace_id = COR
2. `initiative_it_services` WHERE initiative_id IN (initiatives in COR)
3. `initiative_deployment_profiles` WHERE initiative_id IN (initiatives in COR)
4. `application_services` WHERE it_service_id IN (it_services in COR)
5. `deployment_profile_it_services` scoped through DP → app → workspace → COR
6. `integration_contacts` scoped through integration → app → workspace → COR
7. `deployment_profile_contacts` scoped through DP → app → workspace → COR
8. `application_contacts` scoped through app → workspace → COR
9. `contact_organizations` WHERE contact_id IN (contacts in COR)
10. `portfolio_contacts` WHERE contact_id IN (contacts in COR)
11. `workspace_contacts` WHERE contact_id IN (contacts in COR)
12. `contacts` WHERE namespace_id = COR

**Phase 1c: Delete junction tables (before parent tables)**
13. `deployment_profile_software_products` scoped through DP → app → workspace → COR
14. `deployment_profile_technology_products` scoped through DP → app → workspace → COR
15. `it_service_technology_products` scoped through it_service → COR
16. `it_service_software_products` scoped through it_service → COR
17. `it_service_providers` scoped through it_service → COR

**Phase 1d: Delete roadmap data**
18. `findings` WHERE namespace_id = COR
19. `ideas` WHERE namespace_id = COR
20. `initiatives` WHERE namespace_id = COR (cascades initiative_dependencies)

**Phase 1e: Delete assessments and portfolio links**
21. `portfolio_assignments` scoped through DP → app → workspace → COR (cascades assessment_history)
22. `business_assessments` scoped through app → workspace → COR
23. `technical_assessments` scoped through app → workspace → COR

**Phase 1f: Delete core tables (CASCADE handles remaining children)**
24. `application_integrations` scoped through source_app → workspace → COR
25. `deployment_profiles` scoped through app → workspace → COR PLUS infrastructure DPs via workspace → COR
26. `applications` scoped through workspace → COR
27. `it_services` WHERE namespace_id = COR
28. `software_products` WHERE namespace_id = COR
29. `technology_products` WHERE namespace_id = COR

**Phase 1g: Cleanup**
30. `workspace_group_publications` WHERE workspace_group_id in COR groups
31. `audit_logs` WHERE namespace_id = COR (optional — historical cleanup)

**Phase 1h: Verification**
```sql
SELECT 'applications' as tbl, count(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id WHERE w.namespace_id = 'a1b2c3d4-...'
UNION ALL SELECT 'deployment_profiles', count(*) FROM deployment_profiles dp JOIN workspaces w ON dp.workspace_id = w.id WHERE w.namespace_id = 'a1b2c3d4-...'
UNION ALL SELECT 'it_services', count(*) FROM it_services WHERE namespace_id = 'a1b2c3d4-...'
-- etc. All should be 0.
```

### File: `docs-architecture/schema/cor-demo-data-reset-phase2-insert.sql`

Rebuild in dependency order (parents first, then children, then junctions).

**Phase 2a: Technology Products** (13 products, linked to existing lifecycle references)
- Look up lifecycle_reference_id from `technology_lifecycle_reference` by vendor_name + product_name + version
- All in COR namespace, linked to existing categories

**Phase 2b: Software Products** (16 products, inventory-only)
- All manufacturer_org_id references existing COR organizations
- `is_org_wide` set on M365, Adobe CC, Zoom
- `annual_cost = NULL` on all (cost model v3.0 — software is inventory only)

**Phase 2c: IT Services** (12 services, owned by IT workspace)
- All with annual_cost, cost_model, service_type_id
- Contract fields on services that represent vendor contracts
- `lifecycle_reference_id = NULL` (per design — lifecycle derives from tech composition)

**Phase 2d: Applications** (~30 apps across 5 focus workspaces + ~5 SaaS apps in other workspaces)

**Phase 2e: Deployment Profiles** — Application DPs
- One PROD DP per app
- Set hosting_type, environment, data_center_id or region, server_name where relevant
- dp_type = 'application'

**Phase 2f: Deployment Profiles** — Infrastructure DPs (7 infra DPs)
- dp_type = 'infrastructure', no application_id
- Linked to City Hall Data Center or Azure

**Phase 2g: Deployment Profiles** — Cost Bundle DPs (5 Cost Bundle DPs)
- dp_type = 'cost_bundle', with contract fields
- For Path A apps (Axon, Flock Safety, Brazos, ImageTrend, Workday)

**Phase 2h: IT Service Providers** (7 links: infra DP → IT Service)

**Phase 2i: IT Service → Technology Products** (~15-20 composition links)

**Phase 2j: IT Service → Software Products** (~8-10 links)

**Phase 2k: DP → Technology Products** (app DPs with on-prem tech stacks)

**Phase 2l: DP → Software Products** (app DPs with app-specific software inventory)

**Phase 2m: DP → IT Services** (app DPs consuming shared services)
- Path B apps only (on-prem/hybrid apps with IT Service allocations)
- relationship_type = 'depends_on' for most, 'built_on' for platform dependencies

**Phase 2n: Application Integrations** (8 key connections from design doc §5)

**Phase 2o: Portfolio Assignments** (link each app DP to its workspace's default portfolio)

**Phase 2p: Verification queries** (counts match design doc targets)

---

## Critical Files

| File | Purpose |
|------|---------|
| `docs-architecture/planning/cor-demo-data-reset.md` | Design document — the target state |
| `docs-architecture/schema/cor-demo-data-reset-phase1-delete.sql` | DELETE script (to be generated) |
| `docs-architecture/schema/cor-demo-data-reset-phase2-insert.sql` | INSERT script (to be generated) |
| `docs-architecture/schema/nextgen-schema-current.sql` | Schema reference |

---

## What NOT To Touch

- **Users, workspace_users, namespace_users, auth.users** — all preserved
- **Workspaces (18)** — preserved, we delete data inside them
- **Workspace groups** — preserved
- **Service type categories, technology product categories** — preserved
- **Data centers** (City Hall Data Center) — preserved
- **Technology lifecycle references** (82 global records) — preserved, tech products will link to them
- **Organizations** (31 vendor orgs) — preserved and reused
- **Teams** — preserved (deferred per Stuart's answer)
- **Portfolios** — preserved, portfolio_assignments recreated
- **Assessment factors/thresholds** — preserved
- **Reference tables** — all preserved

---

## Verification (after both phases applied)

1. Run security posture validation — zero FAIL rows
2. Run TypeScript check — zero errors
3. Counts: ~30 apps, ~37 DPs (30 app + 7 infra), 12 IT services, 13 tech products, 16 software products
4. Browser verification per design doc §7:
   - Hexagon OnCall → Visual L3 → IT Services with tech pills → Infrastructure providers linked
   - Axon Evidence → Cost Bundle with contract date visible
   - IT Service Catalog → every service has "Built on:" chips + infrastructure provider
   - Software Catalog → all grouped by manufacturer, org-wide badges
   - Technology Catalog → "Powers:" chips on tech products

---

## Separate Code Tasks (not in this SQL plan)

1. **Remove Technology Lifecycle section from ITServiceModal.tsx** — per design doc §2b, this field is architecturally wrong and unused
2. **Add ManageEngine/Cisco/ImageTrend/Workday vendor orgs** if not already in COR namespace (check before INSERT)
