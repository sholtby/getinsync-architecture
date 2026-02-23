# core/composite-application.md
GetInSync Application Relationships Architecture  
Last updated: 2026-01-18

---

## 1. Purpose

Define the architecture for **Application Relationships** - how applications relate to each other through suites, composites, succession, and integrations.

This document covers:
- Suite/Family (parent-child modules from same vendor)
- Composite Applications (bill of materials from multiple systems)
- Application Succession (replacement tracking)
- Integration with existing architecture (internal/external integrations)

**Status:** Design complete. Not yet built.

---

## 2. Design Principles

### 2.1 Unified Relationship Model

Instead of separate tables for each relationship type, use a single `application_relationships` table aligned with **ServiceNow CSDM 5** relationship patterns:

| Relationship Type | CSDM Equivalent | Description |
|-------------------|-----------------|-------------|
| `constitutes` | Constitutes / Decomposes | Parent contains child (suite) |
| `depends_on` | Depends On / Used By | Composite needs component |
| `replaces` | Replaces / Is Replaced By | Succession tracking |

### 2.2 Integration Separation

**Data flow relationships** (`communicates_with`) are NOT in `application_relationships`. They are handled by the existing integrations architecture:

| Relationship | Table | Why Separate |
|--------------|-------|--------------|
| `constitutes` | application_relationships | Simple hierarchy |
| `depends_on` | application_relationships | Simple dependency |
| `replaces` | application_relationships | Simple succession |
| Data exchange | internal_integrations | Rich metadata (method, format, cadence, sensitivity) |
| External data flow | external_integrations + external_entities | External system placeholder |

**Reference:** features/integrations/architecture.md

### 2.3 External Systems

External systems (APIs, SaaS endpoints, partner systems) are **NOT** modeled as applications. They use:
- `external_entities` - Placeholder for the external system
- `external_integrations` - Data flow to/from external systems

This aligns with ServiceNow where external endpoints are tracked in integration records, not as full Business Applications.

---

## 3. Concepts

### 3.1 Suite/Family (`constitutes`)

A **Suite** is a group of application modules from the **same vendor** sharing:
- Single Software Product license
- Single Deployment Profile (parent owns)
- Common T-scores (inherited from parent's DP)
- Different B-scores (assessed per module)

**Example: Sage 300 Suite**
```
Sage 300 General Ledger (Parent)
├── constitutes → Sage 300 Accounts Receivable
├── constitutes → Sage 300 Accounts Payable
└── constitutes → Sage 300 Inventory Control

Parent owns:
  └── Deployment Profile: Sage 300 - PROD
        ├── T-scores assessed here (once for suite)
        ├── IT Services: Cloud Hosting - AWS, Database Hosting - SQL Server
        └── Software Product: Sage 300 Bundle

Children have:
  └── NO Deployment Profile (they ARE part of parent's deployment)
  └── Own B-scores (different business value per module)
  └── Can be in different Portfolios
```

**Key Rules:**
- Parent is a real application (e.g., GL), flagged via relationship
- Children have NO DP - they inherit parent's DP for T-scores
- Each child can have different B-scores in different portfolios
- Publishing is manual per app (parent shared ≠ children auto-shared)
- Single parent only (no app has multiple parents)

### 3.2 Composite Application (`depends_on`)

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

### 3.3 Succession (`replaces`)

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

### 4.1 Application Relationships Table

```sql
CREATE TABLE application_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  source_application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  target_application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'constitutes',   -- Suite: parent contains child
    'depends_on',    -- Composite: needs component
    'replaces'       -- Succession: new replaces old
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
```

### 4.2 RLS Policies

```sql
ALTER TABLE application_relationships ENABLE ROW LEVEL SECURITY;

-- Users can view relationships in their namespace
CREATE POLICY "Users can view relationships in their namespace"
  ON application_relationships FOR SELECT
  USING (namespace_id IN (
    SELECT w.namespace_id FROM workspaces w
    JOIN workspace_users wu ON wu.workspace_id = w.id
    WHERE wu.user_id = auth.uid()
  ));

-- Editors can manage relationships
CREATE POLICY "Editors can manage relationships"
  ON application_relationships FOR ALL
  USING (namespace_id IN (
    SELECT w.namespace_id FROM workspaces w
    JOIN workspace_users wu ON wu.workspace_id = w.id
    WHERE wu.user_id = auth.uid() 
    AND wu.role IN ('admin', 'owner', 'editor')
  ));
```

### 4.3 Application Validation Rules

Enforce in application code or triggers:

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
$$ LANGUAGE plpgsql;

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

### 6.1 Suite (constitutes)

```
Parent Application (e.g., Sage 300 GL)
  └── Owns DP: Sage 300 - PROD
        ├── T-scores assessed here
        ├── IT Services linked here
        └── Software Product linked here

Child Application (e.g., Sage 300 AR)
  └── NO DP
  └── T-scores: Query via parent's DP
  └── B-scores: Own portfolio assignment
```

**Query for child's T-scores:**
```sql
SELECT 
  child.name as child_app,
  parent_dp.t01_score, parent_dp.t02_score, -- etc
  parent_dp.tech_health_score,
  parent_dp.tech_risk_score
FROM applications child
JOIN application_relationships ar 
  ON ar.target_application_id = child.id 
  AND ar.relationship_type = 'constitutes'
JOIN applications parent 
  ON parent.id = ar.source_application_id
JOIN deployment_profiles parent_dp 
  ON parent_dp.application_id = parent.id
WHERE child.id = :child_app_id;
```

### 6.2 Composite (depends_on)

```
Composite Application (e.g., Customer Portal)
  └── Optional DP for orchestration layer
  └── T-Risk: Derived from MAX of component T-Risks

Component Application (e.g., Sage 300 AR)
  └── Own DP with own T-scores
  └── Own B-scores
```

---

## 7. Risk Inheritance (Composites Only)

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
  MAX(dp.tech_risk_score) as derived_tech_risk,
  MIN(dp.tech_health_score) as derived_tech_health,
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

## 8. Aggregated Views (Composites)

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

### 9.1 Application List View

```
┌─────────────────────────────────────────────────────────────────┐
│ Applications                                      [Filter ▼]    │
├─────────────────────────────────────────────────────────────────┤
│ ▼ Sage 300 General Ledger    [Parent]      Finance    TIME     │
│   ├── Sage 300 AR            (child)       Sales      TIME     │
│   ├── Sage 300 AP            (child)       Finance    TIME     │
│   └── Sage 300 IC            (child)       Warehouse  TIME     │
│                                                                 │
│ ▼ Customer Portal            [Composite]   IT         PAID     │
│   ├── Sage 300 GL            (depends on)  Finance    TIME     │
│   ├── SharePoint             (depends on)  Central    TIME     │
│   └── Custom API             (depends on)  IT         TIME     │
│                                                                 │
│   Standalone App                           HR         TIME     │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 Relationships Tab in Application Detail

```
┌─────────────────────────────────────────────────────────────────┐
│ Sage 300 General Ledger                                         │
├─────────────────────────────────────────────────────────────────┤
│ [General] [Assessment] [Services] [Relationships]               │
│                                                                 │
│ Relationships                                    [+ Add]        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ TYPE          │ APPLICATION        │ DIRECTION   │ 🗑ï¸       │ │
│ │ Constitutes   │ Sage 300 AR        │ Parent of   │ ×        │ │
│ │ Constitutes   │ Sage 300 AP        │ Parent of   │ ×        │ │
│ │ Constitutes   │ Sage 300 IC        │ Parent of   │ ×        │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Integrations                                     [+ Add]        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ NAME          │ TARGET             │ DIRECTION │ METHOD     │ │
│ │ GL to SP Sync │ SharePoint         │ Publish   │ API        │ │
│ │ CRA Tax Feed  │ CRA (External)     │ Publish   │ SFTP       │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Derivation Helpers

### 10.1 Is Parent (has constitutes relationships)?

```sql
SELECT DISTINCT a.* FROM applications a
JOIN application_relationships ar ON ar.source_application_id = a.id
WHERE ar.relationship_type = 'constitutes';
```

### 10.2 Is Child (is target of constitutes)?

```sql
SELECT DISTINCT a.* FROM applications a
JOIN application_relationships ar ON ar.target_application_id = a.id
WHERE ar.relationship_type = 'constitutes';
```

### 10.3 Is Composite (has depends_on relationships)?

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

---

## 11. Decisions Log

| Question | Decision | Rationale |
|----------|----------|-----------|
| Cross-workspace relationships? | Yes, within same namespace | WorkspaceGroup may manage subscription |
| Child can have multiple parents? | No | Keep simple |
| Child can be composite source? | No | Keep simple, avoid complexity |
| `communicates_with` in this table? | No | Use internal_integrations with rich metadata |
| Composite has own DP? | Optional | For orchestration layer if exists |
| Suite children have DPs? | No | Inherit from parent |
| Publishing auto-shares children? | No | Manual per app |
| B-scores inherited? | No | Each app assessed independently |

---

## 12. ServiceNow CSDM Alignment

| GetInSync | ServiceNow CSDM | Table |
|-----------|-----------------|-------|
| `constitutes` | Constitutes / Decomposes | cmdb_rel_ci |
| `depends_on` | Depends On / Used By | cmdb_rel_ci |
| `replaces` | Replaces / Is Replaced By | cmdb_rel_ci |
| Internal data flow | (Digital Integration Management) | internal_integrations |
| External data flow | (External endpoint) | external_integrations + external_entities |
| Business Application | cmdb_ci_business_app | applications |
| External Entity | (Not a Business App) | external_entities |

---

## 13. Related Documents

| Document | Relevance |
|----------|-----------|
| features/integrations/architecture.md | Internal/External integration model |
| catalogs/business-application-identification.md | What qualifies as an app |
| core/core-architecture.md | Overall system architecture |
| core/time-paid-methodology.md | Scoring methodology |

---

## 14. Implementation Phases

| Phase | Scope | Effort |
|-------|-------|--------|
| **22a** | application_relationships schema + RLS | 2 hrs |
| **22b** | Suite UI (parent-child in list, relationships tab) | 4 hrs |
| **22c** | T-score inheritance for children (query via parent) | 2 hrs |
| **22d** | Composite UI (depends_on, risk display) | 4 hrs |
| **22e** | Risk inheritance calculations (views) | 2 hrs |
| **22f** | Aggregated views (services, tech, cost) | 2 hrs |

**Total estimate:** ~16 hours

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-18 | Initial design with separate tables |
| v1.1 | 2026-01-18 | Unified relationship model, CSDM alignment, integration separation |

---

*Document: core/composite-application.md*  
*January 2026*
