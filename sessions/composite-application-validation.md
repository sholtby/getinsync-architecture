# Composite Application v2.0 — Validation Report

Date: 2026-03-08
Prepared by: Claude Code (Opus 4.6)
Context: Validate revised Suite/Family design decisions against live codebase and database before updating architecture docs.

---

## 1. Schema Compatibility

| # | Proposed Change | Status | Notes |
|---|----------------|--------|-------|
| 1 | Add `architecture_type TEXT DEFAULT 'standalone'` to `applications` | **PASS** | No existing column. Clean addition. Requires new reference table `architecture_types` per CLAUDE.md rules. |
| 2 | Add `inherits_tech_from UUID REFERENCES deployment_profiles(id) ON DELETE SET NULL` to `deployment_profiles` | **PASS** | No existing column. Self-referencing FK is compatible with existing schema. ON DELETE SET NULL is safe — if parent DP deleted, child reverts to standalone. |
| 3 | `application_relationships` table (constitutes / depends_on / replaces) | **PASS** | Table designed in v1.1, NOT yet deployed. Schema is forward-compatible with v2.0 changes. No conflicts. |
| 4 | New reference table `architecture_types` (standalone, platform_host, platform_application) | **PASS** | Standard reference table pattern. Required by CLAUDE.md: "ALL dropdowns MUST fetch from database reference tables." |

### Reference Table: `architecture_types` (NEW)

Per CLAUDE.md standard reference table pattern:

```sql
CREATE TABLE architecture_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_system BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed data
INSERT INTO architecture_types (code, name, description, display_order) VALUES
  ('standalone', 'Standalone', 'Independent application with no suite or module relationships', 1),
  ('platform_host', 'Platform Host', 'Parent application that hosts modules (e.g., Microsoft 365, Sage 300 GL)', 2),
  ('platform_application', 'Platform Application', 'Module within a parent platform (e.g., Teams, Sage 300 Payroll)', 3);
```

**CSDM Mapping:** Maps directly to ServiceNow `Architecture Type` field on `cmdb_ci_business_app`.

---

## 2. Auto-Calculate Trigger — NULL Handling

**Function:** `auto_calculate_deployment_profile_tech_scores()`
**Delegates to:** `calculate_tech_health(t01..t14)` and `calculate_tech_risk(t02, t03, t04, t05, t11)`

**Confirmed behavior:**
- Each T-factor is guarded by `IF p_tXX IS NOT NULL THEN` — NULL factors are skipped
- Weight accumulates only for non-NULL factors
- **If ALL factors are NULL:** `v_total_weight = 0` → function returns `NULL`
- Suite children with `inherits_tech_from` set will have all T01-T14 as NULL
- Result: `tech_health = NULL`, `tech_risk = NULL` — correct behavior
- Frontend displays parent's scores via the `inherits_tech_from` FK join

**Verdict: PASS** — No trigger modifications needed for suite children.

---

## 3. Live Data Analysis

### 3.1 Suite Candidates (Apps Sharing Same Software Product)

```
namespace                      | software_product            | app_count
-------------------------------+-----------------------------+----------
City of Riverside              | Okta                        | 3
Government of Alberta (Test)   | Azure App Service           | 3
City of Riverside              | VMware vSphere              | 2
Government of Alberta (Test)   | Azure SQL Database          | 2
Government of Alberta (Test)   | Custom Internal Application | 2
```

**Analysis:** 5 groups across 2 namespaces where multiple applications share the same software product — natural suite candidates once the feature ships.

### 3.2 Hosting Type Distribution

```
hosting_type        | count
--------------------+------
SaaS                | 84
On-Prem             | 77
Hybrid              | 12
Cloud               | 11
Desktop             | 1
Third-Party-Hosted  | 1
```

**Total DPs with hosting_type set:** 186. SaaS and On-Prem dominate (87%). This confirms scoring patterns and suite features will primarily serve these two hosting types.

---

## 4. Frontend Impact Analysis

### CRITICAL (Must change, blocks other work)

| File | Change Required |
|------|----------------|
| `src/types/index.ts` | Add `architecture_type` to Application interface. Add `inherits_tech_from` to DeploymentProfile interface. |
| `src/hooks/useApplications.ts` | Fetch `architecture_type`. Handle suite parent/child display logic. |

### MAJOR (Significant changes)

| File | Change Required |
|------|----------------|
| `src/components/dashboard/DashboardAppTable.tsx` | Badge/tag display for suite parents ("Sage 300 x4"). Filter by architecture_type. |
| `src/components/dashboard/rows/AppTableRow.tsx` | Suite badge rendering, inherited T-score display. |
| `src/components/ApplicationForm.tsx` | Add `architecture_type` dropdown, parent application picker (when platform_application). |
| `src/components/PortfolioAssessmentWizard.tsx` | When assessing child: T-scores read-only (inherited), B-scores editable. |
| `src/pages/ApplicationPage.tsx` | Show parent/child relationships. Suite tab or section. |
| `src/components/applications/DeploymentsTab.tsx` | Show inherited T-scores with "(from parent)" indicator. |
| `src/hooks/useDeploymentProfiles.ts` | When child DP has `inherits_tech_from`, fetch parent DP's T-scores for display. |
| `src/components/dashboard/DashboardPage.tsx` | Suite-aware counts, architecture_type filter. |
| `src/components/dashboard/AppHealthFilterDrawer.tsx` | Add architecture_type filter option. |
| `src/lib/scoring.ts` | Suite-aware TIME/PAID: child uses parent's T-scores for quadrant placement. |
| `src/pages/settings/ImportApplications.tsx` | Add `architecture_type` to CSV import schema. |

### MEDIUM (Notable changes, isolated)

| File | Change Required |
|------|----------------|
| `src/components/applications/ApplicationDetailDrawer.tsx` | Show parent badge if child, child count if parent. |
| `src/components/applications/CostSnapshotCard.tsx` | Suite cost aggregation display. |
| `src/components/ApplicationCostSummary.tsx` | Parent: show breakdown including child costs. |
| `src/components/dashboard/AppsOverviewPanel.tsx` | Adjust KPI counts for suite-aware view. |
| `src/components/dashboard/NeedsAttentionPanel.tsx` | Exclude children (parent is responsible). |
| `src/components/dashboard/DistributionPanel.tsx` | Suite-aware quadrant placement. |
| `src/components/technology-health/TechnologyHealthByApplication.tsx` | Group children by parent suite. |
| `src/hooks/useApplicationDetail.ts` | If child, fetch parent relationship. If parent, fetch children. |
| `src/components/AssessmentScoreCard.tsx` | Show "(inherited)" on tech health for children. |
| `src/pages/ApplicationConnections.tsx` | Inherited integrations display. |

### LOW (Minimal impact)

| File | Change Required |
|------|----------------|
| `src/components/dashboard/rows/AppNameCell.tsx` | Suite icon/badge next to name. |
| `src/components/dashboard/rows/AppExpandableRow.tsx` | Expand to show children. |
| `src/components/technology-health/TechnologyHealthSummary.tsx` | Adjust aggregation. |
| `src/components/modals/TechDebtModal.tsx` | Show parent's tech debt if child. |
| `src/components/LinkSoftwareProductModal.tsx` | Parent DP context for children. |
| `src/components/LinkedTechnologyProductsList.tsx` | Inherited attribution. |
| `src/types/view-contracts.ts` | Add interfaces for suite-aware views. |

---

## 5. Cross-Document Impact

28 files in `docs-architecture/` reference composite/suite/constitutes patterns. Key docs requiring updates:

| Document | Update Required |
|----------|----------------|
| `core/composite-application.md` | **MAJOR REWRITE** → v2.0. All 8 design decisions. |
| `core/composite-application-erd.md` | **FULL REWRITE** → v2.0. Replace `parent_application_id` with relationship table + `inherits_tech_from`. |
| `core/deployment-profile.md` | Add `inherits_tech_from` section → v1.9. |
| `features/assessment/tech-scoring-patterns.md` | Update §12 suite interaction. |
| `MANIFEST.md` | Version bumps, pending schema changes. |
| `core/core-architecture.md` | Minor: mention architecture_type in §4.1. No immediate update needed — can wait for build phase. |
| `catalogs/business-application.md` | Minor: reference architecture_type field. Can wait for build phase. |
| `features/cost-budget/cost-model.md` | Minor: suite cost aggregation note. Can wait for build phase. |

---

## 6. Scoring Patterns Interaction

**Confirmed:**
- `tech-scoring-patterns.md` §12 already has "Suite auto-suggestion" future item (line 725)
- Cross-reference table at line 710 links to `core/composite-application.md`

**Rule documented in both docs:**
- When `inherits_tech_from` is set on a child DP, the child is **NOT offered a scoring pattern** — its T-scores come from the parent
- The parent DP uses scoring patterns normally
- If the parent's pattern changes, the child's displayed scores change automatically (no re-apply needed — the child has no local T-scores)

---

## 7. Recommendations

1. **Reference table required:** Create `architecture_types` before adding the column to `applications`. Per CLAUDE.md, all dropdowns must fetch from reference tables.

2. **ERD needs full rewrite:** The current `composite-application-erd.md` uses the superseded `parent_application_id` self-referencing FK pattern from an earlier design. Must be replaced with the relationship table + `inherits_tech_from` model.

3. **Deferred docs:** `core-architecture.md`, `business-application.md`, and `cost-model.md` have minor cross-references that can be updated when the feature is actually built. The 4 primary docs (composite-application, ERD, deployment-profile, tech-scoring-patterns) are updated now.

4. **Suite child validation trigger:** Consider adding a trigger or RPC that prevents setting T-scores directly on a DP that has `inherits_tech_from` set. This is a "nice-to-have" enforcement — the frontend would already prevent this, but DB-level enforcement adds safety.

5. **View consideration:** A `vw_deployment_profile_with_inheritance` view that automatically resolves `inherits_tech_from` to the parent's T-scores would simplify all frontend queries. Design this during build phase.

---

*Report: sessions/composite-application-validation.md*
*March 2026*
