# core/composite-application.md
GetInSync Application Relationships Architecture
Last updated: 2026-03-08

---

## 1. Purpose

Define the architecture for **Application Relationships** — how applications relate to each other through suites, composites, succession, and integrations.

This document covers:
- Suite/Family (parent-child modules from same vendor) — **Phase 1 (active)**
- Composite Applications (bill of materials from multiple systems) — **Phase 2 (not yet scoped)**
- Application Succession (replacement tracking) — **Phase 2 (not yet scoped)**
- Integration with existing architecture (internal/external integrations)

**Status:** Design revised (v2.0). Not yet built. Phase 1 = Suites only.

---

## 2. Design Principles

### 2.1 Unified Relationship Model

Instead of separate tables for each relationship type, use a single `application_relationships` table aligned with **ServiceNow CSDM 4-5** relationship patterns:

| Relationship Type | CSDM Equivalent | Description | Phase |
|-------------------|-----------------|-------------|-------|
| `constitutes` | Constitutes / Decomposes | Parent contains child (suite) | **1** |
| `depends_on` | Depends On / Used By | Composite needs component | 2 |
| `replaces` | Replaces / Is Replaced By | Succession tracking | 2 |

The schema supports all three types from day one. UI is gated by phase — Phase 1 builds only the Suite (`constitutes`) experience.

### 2.2 Every Module Is a Full Application (CSDM Alignment)

Following ServiceNow CSDM 4-5 community consensus:
- Every module is a **full Business Application** in `applications` — not a second-class record
- ServiceNow differentiates via an **Architecture Type** field on `cmdb_ci_business_app`:
  - `Platform Host` = the parent (e.g., Microsoft 365, Sage 300 GL)
  - `Platform Application` = the module (e.g., Teams, Sage 300 Payroll)
- Each module CAN have its own Application Service (our DP equivalent) if independently deployed
- The relationship is expressed through `cmdb_rel_ci` (their generic relationship table), not by withholding records

**Rationale:** Each licensed component should be modeled as its own Business Application because over time each has independent version history, may be deployed differently at different locations, and needs independent lifecycle management.

### 2.3 Integration Separation

**Data flow relationships** (`communicates_with`) are NOT in `application_relationships`. They are handled by the existing integrations architecture:

| Relationship | Table | Why Separate |
|--------------|-------|--------------|
| `constitutes` | application_relationships | Simple hierarchy |
| `depends_on` | application_relationships | Simple dependency |
| `replaces` | application_relationships | Simple succession |
| Data exchange | internal_integrations | Rich metadata (method, format, cadence, sensitivity) |
| External data flow | external_integrations + external_entities | External system placeholder |

**Reference:** features/integrations/architecture.md

### 2.4 External Systems

External systems (APIs, SaaS endpoints, partner systems) are **NOT** modeled as applications. They use:
- `external_entities` — Placeholder for the external system
- `external_integrations` — Data flow to/from external systems

This aligns with ServiceNow where external endpoints are tracked in integration records, not as full Business Applications.

---

## 3. Concepts

### 3.1 Suite/Family (`constitutes`) — Phase 1

A **Suite** is a group of application modules from the **same vendor** sharing:
- Single Software Product license (linked via parent's DP)
- Common T-scores (inherited from parent's DP via `inherits_tech_from` FK)
- Different B-scores (assessed independently per module per portfolio)

**Key difference from v1.1:** Suite children now have their **own Deployment Profile** with an `inherits_tech_from` FK pointing to the parent's primary DP. This avoids null-DP edge cases across the entire frontend — every component that does `LEFT JOIN deployment_profiles` continues to work.

**Example: Sage 300 Suite**
```
Sage 300 General Ledger (architecture_type = platform_host)
├── constitutes → Sage 300 Accounts Receivable (platform_application)
├── constitutes → Sage 300 Accounts Payable (platform_application)
└── constitutes → Sage 300 Inventory Control (platform_application)

Parent owns:
  └── Deployment Profile: "Sage 300 GL - PROD" (is_primary = true)
        ├── T01-T14 assessed here (once for suite)
        ├── tech_health = 72.5, tech_risk = 35.2
        ├── IT Services: Cloud Hosting - AWS, Database Hosting - SQL Server
        └── Software Product: Sage 300 Bundle

Each child has:
  └── Own Deployment Profile: "Sage 300 AR - PROD"
        ├── inherits_tech_from = [parent's primary DP id]
        ├── T01-T14 = NULL (all scores inherited from parent)
        ├── tech_health = NULL, tech_risk = NULL (trigger returns NULL)
        ├── UI displays parent's T-scores with "(inherited)" indicator
        └── Own hosting_type, region, etc. (matches parent typically)
  └── Own B-scores (different business value per module per portfolio)
  └── Can be in different Portfolios
```

**Key Rules:**
- Parent is flagged via `architecture_type = 'platform_host'` on the `applications` record
- Children are flagged via `architecture_type = 'platform_application'`
- Children have their own DP with `inherits_tech_from` set — T-scores stay NULL, inherited from parent
- Each child can have different B-scores in different portfolios
- Publishing is manual per app (parent shared does NOT auto-share children)
- Single parent only (no app has multiple parents)
- Scoring patterns are NOT offered on child DPs (T-scores come from parent)

### 3.2 Composite Application (`depends_on`) — Phase 2 (not yet scoped)

A **Composite** is a business capability assembled from **multiple independent applications**:
- Different vendors/systems
- Each component has own DP and assessments
- Risk inherited from components (weakest link)
- Composite has own B-score assessment

**Example: Customer Portal**
```
Customer Portal (Composite)
├── depends_on → Sage 300 AR (critical)
├── depends_on → SharePoint Tenant (required)
└── depends_on → Custom API Gateway (critical)

Composite may have:
  └── Optional DP for orchestration layer (glue code, custom UI)

Components have:
  └── Own DPs, own T-scores, own B-scores
  └── May be in different workspaces
```

**Key Rules:**
- Composite is a real application (can have own DP)
- Components are full applications with their own assessments
- T-Risk derived from MAX of component T-Risks (weakest link)
- B-scores assessed independently on the composite
- Child of a suite (`constitutes` target) CANNOT be a composite source

### 3.3 Succession (`replaces`) — Phase 2 (not yet scoped)

Track application replacement for migration planning:

```
New CRM ──replaces──► Legacy CRM

Both exist during transition period.
```

**Key Rules:**
- Source = new application, Target = old application
- Both applications maintain their own assessments
- Useful for migration tracking and impact analysis

---

## 4. Data Model

### 4.1 Architecture Types Reference Table (NEW in v2.0)

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

-- GRANT + RLS (system reference table — all users can read)
GRANT ALL ON architecture_types TO authenticated, service_role;
ALTER TABLE architecture_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view architecture_types"
  ON architecture_types FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Platform admins can manage architecture_types"
  ON architecture_types FOR ALL TO authenticated
  USING (check_is_platform_admin())
  WITH CHECK (check_is_platform_admin());

-- Seed data
INSERT INTO architecture_types (code, name, description, display_order) VALUES
  ('standalone', 'Standalone', 'Independent application with no suite or module relationships', 1),
  ('platform_host', 'Platform Host', 'Parent application that hosts modules (e.g., Microsoft 365, Sage 300 GL)', 2),
  ('platform_application', 'Platform Application', 'Module within a parent platform (e.g., Teams, Sage 300 Payroll)', 3);
```

**CSDM Mapping:** Maps directly to ServiceNow `Architecture Type` field on `cmdb_ci_business_app`.

### 4.2 Applications Table Changes (NEW in v2.0)

```sql
ALTER TABLE applications
  ADD COLUMN architecture_type TEXT DEFAULT 'standalone'
  REFERENCES architecture_types(code);
```

### 4.3 Deployment Profiles Table Changes (NEW in v2.0)

```sql
ALTER TABLE deployment_profiles
  ADD COLUMN inherits_tech_from UUID REFERENCES deployment_profiles(id) ON DELETE SET NULL;

-- Index for inheritance lookups
CREATE INDEX idx_dp_inherits_tech_from ON deployment_profiles(inherits_tech_from)
  WHERE inherits_tech_from IS NOT NULL;
```

**Behavior when `inherits_tech_from` is set:**
- T01-T14 columns stay NULL on the child DP
- `tech_health` and `tech_risk` remain NULL (auto-calculate trigger returns NULL when all factors are NULL — confirmed)
- Frontend resolves the FK to display parent's T-scores with "(inherited)" indicator
- Scoring patterns are NOT offered (T-scores come from parent)
- B-scores on portfolio assignments remain independent (assessed via child's DP)

**ON DELETE SET NULL rationale:** If the parent DP is deleted, the child reverts to a standalone DP with no inherited scores. The child's T-scores will show as unassessed until re-linked or independently scored.

### 4.4 Application Relationships Table

```sql
CREATE TABLE application_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  source_application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  target_application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'constitutes',   -- Suite: parent contains child
    'depends_on',    -- Composite: needs component (Phase 2)
    'replaces'       -- Succession: new replaces old (Phase 2)
  )),
  dependency_criticality TEXT CHECK (dependency_criticality IN (
    'critical',   -- Composite fails if component fails
    'required',   -- Needed but may have fallback
    'optional'    -- Enhances but not essential
  )),  -- Only for depends_on
  notes TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(source_application_id, target_application_id, relationship_type),
  CHECK (source_application_id != target_application_id)
);

-- Single parent constraint: an app can only have ONE parent (constitutes)
CREATE UNIQUE INDEX idx_app_rel_single_parent
ON application_relationships(target_application_id)
WHERE relationship_type = 'constitutes';

-- Indexes for queries
CREATE INDEX idx_app_rel_source ON application_relationships(source_application_id);
CREATE INDEX idx_app_rel_target ON application_relationships(target_application_id);
CREATE INDEX idx_app_rel_type ON application_relationships(relationship_type);
CREATE INDEX idx_app_rel_namespace ON application_relationships(namespace_id);

-- GRANT + audit trigger (standard pattern)
GRANT ALL ON application_relationships TO authenticated, service_role;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON application_relationships
  FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');

CREATE TRIGGER audit_application_relationships
  AFTER INSERT OR UPDATE OR DELETE ON application_relationships
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### 4.5 RLS Policies

Using current namespace-based pattern (updated from v1.1):

```sql
ALTER TABLE application_relationships ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can view relationships in current namespace + platform admins
CREATE POLICY "Users can view application_relationships in current namespace"
  ON application_relationships FOR SELECT TO authenticated
  USING (
    namespace_id = get_current_namespace_id()
    OR check_is_platform_admin()
  );

-- INSERT: Admins, editors, and stewards in current namespace
CREATE POLICY "Admins can insert application_relationships in current namespace"
  ON application_relationships FOR INSERT TO authenticated
  WITH CHECK (
    (namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())))
    OR check_is_platform_admin()
  );

-- UPDATE: Admins, editors, and stewards in current namespace
CREATE POLICY "Admins can update application_relationships in current namespace"
  ON application_relationships FOR UPDATE TO authenticated
  USING (
    (namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())))
    OR check_is_platform_admin()
  )
  WITH CHECK (
    (namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())))
    OR check_is_platform_admin()
  );

-- DELETE: Admins only
CREATE POLICY "Admins can delete application_relationships in current namespace"
  ON application_relationships FOR DELETE TO authenticated
  USING (
    (namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(get_current_namespace_id())))
    OR check_is_platform_admin()
  );
```

### 4.6 Application Validation Rules

Enforce in triggers:

```sql
-- Child of constitutes cannot be source of depends_on
-- (A suite child cannot also be a composite parent)
CREATE OR REPLACE FUNCTION check_child_not_composite()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.relationship_type = 'depends_on' THEN
    IF EXISTS (
      SELECT 1 FROM application_relationships
      WHERE target_application_id = NEW.source_application_id
      AND relationship_type = 'constitutes'
    ) THEN
      RAISE EXCEPTION 'A suite child cannot be a composite source';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = 'public';

CREATE TRIGGER trg_check_child_not_composite
BEFORE INSERT OR UPDATE ON application_relationships
FOR EACH ROW EXECUTE FUNCTION check_child_not_composite();
```

---

## 5. Relationship Direction Reference

| Type | Source | Target | Example |
|------|--------|--------|---------|
| `constitutes` | Parent | Child | Sage GL → Sage AR |
| `depends_on` | Composite | Component | Portal → Sage GL |
| `replaces` | New App | Old App | New CRM → Legacy CRM |

---

## 6. DP Ownership Model

### 6.1 Suite (constitutes) — Revised in v2.0

```
Parent Application (e.g., Sage 300 GL)
  └── architecture_type = 'platform_host'
  └── Owns DP: "Sage 300 GL - PROD" (is_primary = true)
        ├── T01-T14 assessed here (once for suite)
        ├── tech_health = 72.5, tech_risk = 35.2
        ├── IT Services linked here
        ├── Software Product linked here
        └── inherits_tech_from = NULL (this IS the source)

Child Application (e.g., Sage 300 AR)
  └── architecture_type = 'platform_application'
  └── Own DP: "Sage 300 AR - PROD"
        ├── inherits_tech_from = [parent's primary DP id]
        ├── T01-T14 = NULL (inherited from parent)
        ├── tech_health = NULL, tech_risk = NULL
        ├── hosting_type, region = same as parent (typically)
        └── Can link own IT Services if needed (e.g., add-on licensing)
  └── B-scores: Own portfolio assignment (independent)
```

**Query for child's displayed T-scores (via inherits_tech_from):**
```sql
SELECT
  child.name AS child_app,
  child_dp.id AS child_dp_id,
  parent_dp.t01, parent_dp.t02, parent_dp.t03, parent_dp.t04,
  parent_dp.t05, parent_dp.t06, parent_dp.t07, parent_dp.t08,
  parent_dp.t09, parent_dp.t10, parent_dp.t11, parent_dp.t12,
  parent_dp.t13, parent_dp.t14,
  parent_dp.tech_health,
  parent_dp.tech_risk
FROM applications child
JOIN deployment_profiles child_dp ON child_dp.application_id = child.id AND child_dp.is_primary = true
JOIN deployment_profiles parent_dp ON parent_dp.id = child_dp.inherits_tech_from
WHERE child.id = :child_app_id;
```

**Future view consideration:** A `vw_deployment_profile_with_inheritance` view that automatically resolves `inherits_tech_from` would simplify frontend queries. Design during build phase.

### 6.2 Composite (depends_on) — Phase 2

```
Composite Application (e.g., Customer Portal)
  └── Optional DP for orchestration layer
  └── T-Risk: Derived from MAX of component T-Risks

Component Application (e.g., Sage 300 AR)
  └── Own DP with own T-scores
  └── Own B-scores
```

---

## 7. Risk Inheritance (Composites Only) — Phase 2

### 7.1 T-Risk Calculation (Weakest Link)

```
Composite T-Risk = MAX(component T-Risk scores)

Example:
  Customer Portal (Composite)
  ├── Salesforce CRM      T-Risk: 25
  ├── Legacy ERP          T-Risk: 78 ← Weakest link
  └── Custom API          T-Risk: 40

  Composite T-Risk = 78
```

### 7.2 T-Score Calculation

```
Composite T-Score = MIN(component T-Scores)

Rationale: Composite is only as healthy as its weakest component.
```

### 7.3 Query for Composite Risk

```sql
SELECT
  c.name as composite_name,
  MAX(dp.tech_risk) as derived_tech_risk,
  MIN(dp.tech_health) as derived_tech_health,
  COUNT(*) as component_count
FROM applications c
JOIN application_relationships ar
  ON ar.source_application_id = c.id
  AND ar.relationship_type = 'depends_on'
JOIN applications comp ON comp.id = ar.target_application_id
JOIN deployment_profiles dp ON dp.application_id = comp.id AND dp.is_primary = TRUE
WHERE c.id = :composite_id
GROUP BY c.id, c.name;
```

---

## 8. Aggregated Views (Composites) — Phase 2

### 8.1 Composite IT Services

```sql
SELECT DISTINCT its.id, its.name, comp.name as via_component
FROM application_relationships ar
JOIN applications comp ON comp.id = ar.target_application_id
JOIN deployment_profiles dp ON dp.application_id = comp.id
JOIN deployment_profile_it_services dpis ON dpis.deployment_profile_id = dp.id
JOIN it_services its ON its.id = dpis.it_service_id
WHERE ar.source_application_id = :composite_id
AND ar.relationship_type = 'depends_on';
```

### 8.2 Composite Technology Stack

```sql
SELECT DISTINCT tp.name, tp.version, tpc.name as category, comp.name as via_component
FROM application_relationships ar
JOIN applications comp ON comp.id = ar.target_application_id
JOIN deployment_profiles dp ON dp.application_id = comp.id
JOIN deployment_profile_it_services dpis ON dpis.deployment_profile_id = dp.id
JOIN it_services its ON its.id = dpis.it_service_id
JOIN deployment_profiles dp_infra ON dp_infra.id = its.powered_by_deployment_profile_id
JOIN deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp_infra.id
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN technology_product_categories tpc ON tpc.id = tp.category_id
WHERE ar.source_application_id = :composite_id
AND ar.relationship_type = 'depends_on';
```

---

## 9. UI Considerations

### 9.1 Application List View — Badge/Tag Pattern (Revised in v2.0)

The application list uses a **flat list with badge/tag indicators** rather than a tree/hierarchy expansion. This reduces visual noise while still conveying suite membership.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Applications                                         [Filter ▼]      │
├──────────────────────────────────────────────────────────────────────┤
│ Sage 300 General Ledger    [Suite ×4]     Finance     TIME   72.5   │
│ Sage 300 Accounts Receivable (module)     Sales       TIME   72.5*  │
│ Sage 300 Accounts Payable    (module)     Finance     TIME   72.5*  │
│ Sage 300 Inventory Control   (module)     Warehouse   TIME   72.5*  │
│                                                                      │
│ SharePoint Online                         Central     TIME   85.0   │
│ Custom API Gateway                        IT          PAID   40.0   │
│ Standalone App                            HR          TIME   60.0   │
└──────────────────────────────────────────────────────────────────────┘

* = inherited from parent
[Suite ×4] = badge on parent showing child count
(module) = subtle tag on child rows
```

**Key UI decisions:**
- Flat list (no tree expansion in main table)
- Parent row shows `[Suite ×4]` badge with child count
- Child rows show `(module)` tag and inherited T-scores with asterisk or "(inherited)" indicator
- Filter drawer includes architecture_type filter (Standalone / Platform Host / Platform Application)
- Relationship detail only in Edit App drawer / Application detail page

### 9.2 Relationships Section in Application Detail

```
┌──────────────────────────────────────────────────────────────────────┐
│ Sage 300 General Ledger                                              │
├──────────────────────────────────────────────────────────────────────┤
│ [General] [Deployments] [Assessment] [Connections] [Relationships]   │
│                                                                      │
│ Suite Members                                        [+ Add Module]  │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ APPLICATION              │ PORTFOLIOS        │ ASSESSED │ ×     │ │
│ │ Sage 300 AR              │ Finance, Sales    │ ✓ (B)    │ ×     │ │
│ │ Sage 300 AP              │ Finance           │ ✓ (B)    │ ×     │ │
│ │ Sage 300 IC              │ Warehouse         │ ✗        │ ×     │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ Integrations                                        [+ Add]          │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ NAME              │ TARGET           │ DIRECTION │ METHOD       │ │
│ │ GL to SP Sync     │ SharePoint       │ Publish   │ API          │ │
│ │ CRA Tax Feed      │ CRA (External)   │ Publish   │ SFTP         │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 10. Derivation Helpers

### 10.1 Is Parent (has constitutes relationships)?

```sql
SELECT DISTINCT a.* FROM applications a
JOIN application_relationships ar ON ar.source_application_id = a.id
WHERE ar.relationship_type = 'constitutes';
```

**Or via architecture_type:**
```sql
SELECT * FROM applications WHERE architecture_type = 'platform_host';
```

### 10.2 Is Child (is target of constitutes)?

```sql
SELECT DISTINCT a.* FROM applications a
JOIN application_relationships ar ON ar.target_application_id = a.id
WHERE ar.relationship_type = 'constitutes';
```

**Or via architecture_type:**
```sql
SELECT * FROM applications WHERE architecture_type = 'platform_application';
```

### 10.3 Is Composite (has depends_on relationships)? — Phase 2

```sql
SELECT DISTINCT a.* FROM applications a
JOIN application_relationships ar ON ar.source_application_id = a.id
WHERE ar.relationship_type = 'depends_on';
```

### 10.4 Get Parent of Child

```sql
SELECT parent.* FROM applications parent
JOIN application_relationships ar ON ar.source_application_id = parent.id
WHERE ar.target_application_id = :child_id
AND ar.relationship_type = 'constitutes';
```

### 10.5 Get Child's Inherited T-Scores (NEW in v2.0)

```sql
SELECT
  child.name AS child_app,
  parent_dp.tech_health AS inherited_tech_health,
  parent_dp.tech_risk AS inherited_tech_risk,
  parent.name AS inherited_from
FROM applications child
JOIN deployment_profiles child_dp
  ON child_dp.application_id = child.id AND child_dp.is_primary = true
JOIN deployment_profiles parent_dp
  ON parent_dp.id = child_dp.inherits_tech_from
JOIN applications parent
  ON parent.id = parent_dp.application_id
WHERE child.id = :child_app_id;
```

---

## 11. Decisions Log

### v1.1 Decisions (January 2026)

| Question | Decision | Rationale |
|----------|----------|-----------|
| Cross-workspace relationships? | Yes, within same namespace | WorkspaceGroup may manage subscription |
| Child can have multiple parents? | No | Keep simple |
| Child can be composite source? | No | Keep simple, avoid complexity |
| `communicates_with` in this table? | No | Use internal_integrations with rich metadata |
| Composite has own DP? | Optional | For orchestration layer if exists |
| Publishing auto-shares children? | No | Manual per app |

### v2.0 Decisions (March 2026)

| # | Original Design | Revised Design | Rationale |
|---|----------------|----------------|-----------|
| 1 | Suite children have NO Deployment Profile | Suite children GET their own DP with `inherits_tech_from` FK pointing to parent's primary DP | Avoids null-DP edge cases across entire frontend. Every component that does `LEFT JOIN deployment_profiles` continues to work. CSDM-aligned — ServiceNow gives every module its own Application Service. |
| 2 | No `architecture_type` field | Add `architecture_type` to `applications` table: `standalone` (default), `platform_host`, `platform_application` | Direct CSDM alignment. Maps to ServiceNow's Architecture Type field. Enables UI to distinguish parent/child/standalone without querying relationships table. |
| 3 | T-scores "query via parent's DP" with no DP on child | T-scores on child's DP are inherited from parent's DP via `inherits_tech_from` reference. Child's own T-score columns stay NULL — computed/displayed from parent's DP at query time. | Same outcome (child shows parent's tech scores) but child has a real DP record. Inheritance is explicit via FK, not implicit via absence. |
| 4 | Build suites + composites + succession together (Phase 22a-22f) | Build suites ONLY as Phase 1. Composites and succession deferred to Phase 2. | Suites are simpler, more common in real portfolios. Validate with customers before adding complexity. |
| 5 | Ship constitutes + depends_on + replaces in `application_relationships` table | Ship `application_relationships` table with all three types in the schema, but only build Suite UI (`constitutes`) in Phase 1. | Table supports future types. Schema is forward-compatible. UI complexity is gated. |
| 6 | UI: tree/hierarchy expansion in app list | UI: badge/tag pattern (flat list with visual indicators). Relationship detail only in Edit App drawer. | Reduces noise. "Sage 300 x4" badge on parent row. Detail on click/expand. |
| 7 | B-scores assessed on child via portfolio assignment (unchanged) | Same — B-scores remain independently assessed per portfolio assignment | Each module has different business value to different stakeholders. This was correct in the original design. |
| 8 | RLS policies join through `workspaces → workspace_users` | RLS policies must use current namespace pattern: `get_current_namespace_id()`, `check_is_platform_admin()`, `check_is_namespace_admin_of_namespace()` | Original doc had outdated RLS pattern. Must match established conventions used across all 93 tables. |

---

## 12. ServiceNow CSDM Alignment

| GetInSync | ServiceNow CSDM 4-5 | Table |
|-----------|---------------------|-------|
| `applications.architecture_type` | `cmdb_ci_business_app.architecture_type` | applications |
| `platform_host` | Platform Host | applications |
| `platform_application` | Platform Application | applications |
| `standalone` | (no Architecture Type set) | applications |
| `constitutes` | Constitutes / Decomposes | cmdb_rel_ci → application_relationships |
| `depends_on` | Depends On / Used By | cmdb_rel_ci → application_relationships |
| `replaces` | Replaces / Is Replaced By | cmdb_rel_ci → application_relationships |
| `deployment_profiles` | Application Service | deployment_profiles |
| `inherits_tech_from` | (App Service references parent App Service) | deployment_profiles |
| Internal data flow | Digital Integration Management | internal_integrations |
| External data flow | External endpoint | external_integrations + external_entities |
| Business Application | cmdb_ci_business_app | applications |
| External Entity | (Not a Business App) | external_entities |

---

## 13. Scoring Pattern Interaction

When a suite child has `inherits_tech_from` set on its DP:

1. **T-scores are NOT independently assessed** — they come from the parent's DP
2. **Scoring patterns are NOT offered** to the child DP during assessment
3. The **parent DP can use scoring patterns normally**
4. If the parent's pattern changes and is re-applied, the child's displayed scores update automatically (no re-apply needed — the child has no local T-scores)

**Cross-reference:** `features/assessment/tech-scoring-patterns.md` §12 Future Enhancements

---

## 14. Related Documents

| Document | Relevance |
|----------|-----------|
| core/composite-application-erd.md | Visual ERD for this architecture |
| core/deployment-profile.md | DP entity, `inherits_tech_from` column |
| features/assessment/tech-scoring-patterns.md | Scoring patterns — suite interaction documented in §12 |
| features/integrations/architecture.md | Internal/External integration model |
| catalogs/business-application-identification.md | What qualifies as an app |
| core/core-architecture.md | Overall system architecture |
| core/time-paid-methodology.md | Scoring methodology |
| sessions/composite-application-validation.md | v2.0 validation report |

---

## 15. Implementation Phases

### Phase 1: Suite Relationships (Active)

| Step | Scope | Effort |
|------|-------|--------|
| **1a** | `architecture_types` reference table + `applications.architecture_type` column | 1 hr |
| **1b** | `deployment_profiles.inherits_tech_from` column + index | 0.5 hr |
| **1c** | `application_relationships` table + RLS + triggers + audit | 2 hrs |
| **1d** | Suite UI — badge/tag in app list, relationships section in app detail | 4 hrs |
| **1e** | T-score inheritance display (resolve `inherits_tech_from` in frontend) | 2 hrs |
| **1f** | Assessment wizard — read-only T-scores for children, B-scores editable | 2 hrs |

**Phase 1 total:** ~11.5 hours

### Phase 2: Composites + Succession (Not Yet Scoped)

| Step | Scope | Effort |
|------|-------|--------|
| **2a** | Composite UI (`depends_on`, risk display) | 4 hrs |
| **2b** | Risk inheritance calculations (views) | 2 hrs |
| **2c** | Aggregated views (services, tech, cost) | 2 hrs |
| **2d** | Succession UI (`replaces`, migration tracking) | 3 hrs |

**Phase 2 total:** ~11 hours (estimate — will be refined when scoped)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-18 | Initial design with separate tables |
| v1.1 | 2026-01-18 | Unified relationship model, CSDM alignment, integration separation |
| v2.0 | 2026-03-08 | **Major revision:** Suite children get own DP with `inherits_tech_from` FK. Added `architecture_type` field on applications. Updated RLS to namespace-based patterns. Badge/tag UI instead of tree. Suite-only Phase 1. 8 revised design decisions. Added scoring pattern interaction section. |

---

*Document: core/composite-application.md*
*March 2026*
