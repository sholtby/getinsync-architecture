# catalogs/application-reference-model.md
Application Reference Model - Controlled Vocabulary Approach
Last updated: 2026-01-26

---

## 1. Purpose

> **"Business Capability Models fail in practice. Tags without governance go bananas. We need something in between."**

This document defines GetInSync's **pragmatic approach to Application Reference Model (ARM)** - achieving 80% of ARM's value with 20% of the complexity through controlled vocabulary instead of hierarchical Business Capability Models.

**Core Principle:** Enable "do we already have this?" governance queries without requiring the multi-year BCM implementations that nobody can sustain.

**What We're Building:**
- Primary classification (required, single-select)
- Secondary tags (optional, multi-select, admin-governed)
- Integration with existing Portfolios and Workspace Groups
- AI-powered semantic search over controlled vocabulary

**What We're NOT Building:**
- Hierarchical Business Capability Model (L1 → L2 → L3)
- Free-form tagging (leads to chaos)
- Complex EA frameworks that require consultants

**Status:** Design complete. Not yet implemented.

**Audience:** Internal architects, developers, product team.

---

## 2. Design Overview

### 2.1 The Problem ARM Solves

**Governance Scenario:**
```
Finance Director: "We need to buy a new budgeting tool."
IT: "Do we already have something?"
Without ARM: Search app names, ask around, hope someone remembers
With ARM: Query applications by category + tags, find existing tools
```

**The Core Question:** "What applications support [business function]?"

### 2.2 Why Traditional ARM Fails

| Approach | Problem |
|----------|---------|
| **Full BCM (LeanIX/Ardoq)** | Requires 3-6 months of workshops, business leader buy-in, continuous maintenance |
| **Industry templates** | Don't fit specific organizational structures, still require heavy customization |
| **Free-form tags** | Becomes chaos: "finance", "financial", "Finance & Accounting", "fin", "money stuff" |

**Reality from 30 years of APM:** Nobody can pull off a Business Capability Model that survives contact with reality.

### 2.3 GetInSync's Pragmatic Solution

**Three-Tier Classification:**

| Level | Type | Control | Purpose |
|-------|------|---------|---------|
| **Primary** | Category (required) | Namespace Admin managed | "What part of the business?" |
| **Secondary** | Tags (optional) | Admin-approved vocabulary | "What does it do specifically?" |
| **Custom** | Portfolios (optional) | Workspace user-defined | "How do we group for our needs?" |

This approach:
- ✅ Prevents tag chaos (controlled vocabulary)
- ✅ Provides governance queries (category + tags)
- ✅ Scales to organization (admin manages taxonomy)
- ✅ Stays simple (no BCM hierarchy complexity)
- ✅ Aligns with "18-year-old test" (understandable UI)

### 2.4 How It Relates to Existing Features

| Feature | Scope | Use Case | ARM Adds |
|---------|-------|----------|----------|
| **Portfolios** | Workspace-specific | Custom grouping, reporting views | Nothing (complementary) |
| **Workspace Groups** | Namespace-wide | Federated visibility, shared services | Nothing (complementary) |
| **Application Categories** | Namespace-wide | Standardized classification | **NEW** |
| **Application Tags** | Namespace-wide | Controlled descriptors | **NEW** |

### 2.5 Competitive Positioning

Against LeanIX/Ardoq, this approach differentiates by:
- Simpler: No BCM overhead
- Faster: Works day one with seed data
- Maintainable: Governance without complexity
- AI-Ready: Structured for semantic search

---

## 3. Core Entities or Components

### 3.1 ApplicationCategory (Primary Classification)

Namespace-scoped, admin-managed taxonomy for primary classification.

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| namespace_id | UUID | Foreign key to namespaces |
| category_code | TEXT | Internal code ('FINANCE', 'HR', 'CITIZEN_SERVICES') |
| category_name | TEXT | Display name ('Financial Management', 'Human Resources') |
| description | TEXT | What applications in this category do |
| sort_order | INTEGER | Display ordering |
| is_active | BOOLEAN | Soft delete support |
| created_at | TIMESTAMPTZ | Audit trail |
| updated_at | TIMESTAMPTZ | Audit trail |

**Constraints:**
- UNIQUE(namespace_id, category_code)
- Every application MUST have one category

**UI Label:** "Application Category" (not "Service Domain" - avoid ARM jargon)

**Seeded Values (Government):**
1. Financial Management
2. Human Resources
3. Citizen Services
4. IT Infrastructure
5. Program Delivery
6. Business Intelligence
7. Collaboration & Communication
8. Compliance & Risk

### 3.2 ApplicationTagVocabulary (Secondary Tags)

Namespace-scoped, controlled vocabulary for descriptive tags.

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| namespace_id | UUID | Foreign key to namespaces |
| tag_name | TEXT | Tag value ('budgeting', 'public-facing', 'saas') |
| description | TEXT | What this tag means |
| is_active | BOOLEAN | Soft delete support |
| created_by | UUID | Contact who requested/created tag |
| approved_by | UUID | Namespace Admin who approved |
| created_at | TIMESTAMPTZ | Audit trail |
| updated_at | TIMESTAMPTZ | Audit trail |

**Constraints:**
- UNIQUE(namespace_id, tag_name)
- tag_name is lowercase, hyphenated (no spaces)

**Seeded Values:**
```
Core Business:
- budgeting
- reporting
- compliance
- public-facing
- internal-only
- workflow-automation
- data-analytics

Lifecycle:
- legacy-system
- strategic-platform
- pilot-program
- sunset-planned

Technology:
- saas
- on-premise
- cloud-native
- vendor-hosted
```

### 3.3 ApplicationTags (Junction)

Many-to-many relationship between applications and tags.

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| application_id | UUID | Foreign key to applications |
| tag_id | UUID | Foreign key to application_tag_vocabulary |
| created_at | TIMESTAMPTZ | Audit trail |

**Constraints:**
- UNIQUE(application_id, tag_id)

### 3.4 ApplicationTagRequest (Governance)

Workflow for users to request new tags.

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| namespace_id | UUID | Foreign key to namespaces |
| requested_tag_name | TEXT | Proposed tag name |
| reason | TEXT | Why this tag is needed |
| requested_by | UUID | Contact making request |
| status | TEXT | 'pending', 'approved', 'denied', 'merged' |
| response_notes | TEXT | Admin's decision rationale |
| approved_by | UUID | Namespace Admin |
| approved_tag_id | UUID | If approved, resulting tag |
| created_at | TIMESTAMPTZ | Audit trail |
| resolved_at | TIMESTAMPTZ | When admin responded |

**Constraints:**
- status CHECK IN ('pending', 'approved', 'denied', 'merged')

### 3.5 Applications Table Changes

Add category reference to existing applications table:

**New Fields:**
| Field | Type | Description |
|-------|------|-------------|
| category_id | UUID | Foreign key to application_categories (REQUIRED) |

**Migration:** Existing applications get a default category during migration (e.g., "Uncategorized" or most common category).

---

## 4. Tag Governance Workflow

### 4.1 User Experience

**When creating/editing an application:**

```
┌─────────────────────────────────────────────┐
│ Application Details                          │
│                                              │
│ Name: [Oracle Hyperion Planning___________] │
│                                              │
│ Category: [Financial Management ▼] *required│
│                                              │
│ Tags: [x] budgeting                          │
│       [x] reporting                          │
│       [x] cloud-native                       │
│       [ ] compliance                         │
│       [ ] public-facing                      │
│                                              │
│ [+ Request new tag]                          │
└─────────────────────────────────────────────┘
```

**When requesting a new tag:**

```
┌─────────────────────────────────────────────┐
│ Request New Tag                              │
│                                              │
│ Tag name: [procurement-automation_________] │
│                                              │
│ Why do you need this tag?                    │
│ [We need to track procurement applications  │
│  separately from general workflow tools]     │
│                                              │
│ Similar existing tags:                       │
│ • procurement (used by 3 apps)              │
│ • workflow-automation (used by 12 apps)     │
│                                              │
│ [Submit Request]  [Cancel]                   │
└─────────────────────────────────────────────┘
```

### 4.2 Namespace Admin Experience

**Tag request review:**

```
┌─────────────────────────────────────────────┐
│ Tag Request from Stuart Holtby               │
│ Ministry of Finance • Jan 26, 2026           │
│                                              │
│ Requested: "procurement-automation"          │
│ Reason: "We need to track procurement apps  │
│          separately from general workflow"   │
│                                              │
│ Similar existing tags:                       │
│ • procurement (3 apps)                      │
│ • workflow-automation (12 apps)             │
│ • workflow (8 apps)                         │
│                                              │
│ Decision:                                    │
│ ○ Approve as-is                             │
│ ○ Approve as "procurement" (rename)         │
│ ○ Suggest using "workflow-automation"       │
│ ○ Deny                                      │
│                                              │
│ Response notes (optional):                   │
│ [We already have 'procurement' tag. Use     │
│  that instead of creating similar tags.]     │
│                                              │
│ [Submit Decision]                            │
└─────────────────────────────────────────────┘
```

### 4.3 Tag Management Dashboard

**For Namespace Admins:**

```
Application Tags Management
─────────────────────────────────────────
Active Tags (47)                    [+ Add Tag Manually]

Filter: [All ▼]  [____Search tags____]  [Show: Active ▼]

Tag Name              Usage  Category      Actions
──────────────────────────────────────────────────────
budgeting               23   Business      [Edit] [Deactivate]
reporting               45   Business      [Edit] [Deactivate]
compliance              18   Business      [Edit] [Deactivate]
public-facing           12   Business      [Edit] [Deactivate]
saas                    34   Technology    [Edit] [Deactivate]
legacy-system            8   Lifecycle     [Edit] [Deactivate]
unused-tag-example       0   Business      [Edit] [Delete]

Pending Requests (3)                [Review All]
──────────────────────────────────────────────────────
procurement-automation  Stuart H.  Finance    [Review]
data-governance        Jane D.    IT         [Review]
gdpr-compliant        Mike T.    Legal      [Review]
```

### 4.4 Tag Cleanup Process

Admins can identify and clean up unused tags:

```sql
-- Find tags with zero usage
SELECT tv.tag_name, COUNT(at.id) as usage_count
FROM application_tag_vocabulary tv
LEFT JOIN application_tags at ON tv.id = at.tag_id
WHERE tv.is_active = true
GROUP BY tv.tag_name
HAVING COUNT(at.id) = 0
ORDER BY tv.created_at DESC;

-- Find duplicate/similar tags that should be merged
SELECT tag_name 
FROM application_tag_vocabulary
WHERE tag_name LIKE 'budget%'
  AND is_active = true;
-- Results: budgeting, budget, budgets, budget-planning
-- Admin can merge these into single "budgeting" tag
```

---

## 5. Relationships to Other Domains

### 5.1 Applications

- Applications MUST have one category_id (primary classification)
- Applications MAY have zero or more tags via junction table
- Applications still belong to Portfolios (unchanged)
- Applications still link to Workspace Groups via SoftwareProducts (unchanged)

### 5.2 Portfolios

- Portfolios remain workspace-scoped, user-defined groupings
- ARM categories/tags are complementary, not replacement
- User can create portfolio "Critical Finance Apps" containing applications with category='FINANCE'
- Portfolios provide custom views; ARM provides standardized taxonomy

### 5.3 Workspace Groups

- Workspace Groups provide federated visibility across workspaces
- ARM categories/tags are orthogonal to workspace grouping
- Example: "Shared Services Group" can contain apps from any category
- ARM enables "Show me all Infrastructure apps across all workspaces in this group"

### 5.4 Deployment Profiles

- DPs inherit application's category/tags (not stored redundantly)
- Dashboard can filter by category: "Show all Finance DPs in Invest quadrant"
- Cost rollup by category: "What's our annual spend on Citizen Services?"

### 5.5 Software Products

- Software Products (in catalog) do NOT have categories/tags
- Categories/tags are on Applications (the business context)
- Same product (e.g., "Microsoft SQL Server") might support:
  - Finance apps (category='FINANCE', tags=['reporting', 'compliance'])
  - HR apps (category='HR', tags=['data-analytics'])

### 5.6 Integrations

- Integration queries can leverage ARM: "Show integrations between Finance and HR apps"
- `internal_integrations` already exist; ARM adds semantic layer
- "Show public-facing apps and their external integrations"

### 5.7 Cost Model

- Cost rollup by category: "Annual spend by business area"
- Budget allocation by category
- "Show me high-cost applications in Citizen Services category"

---

## 6. ASCII ERD (Conceptual)

```
┌──────────────────────────┐
│   application_categories │
│   (namespace-scoped)     │
├──────────────────────────┤
│ id                   [PK]│
│ namespace_id         [FK]│───┐
│ category_code            │   │
│ category_name            │   │
│ description              │   │
│ sort_order               │   │
│ is_active                │   │
└──────────────────────────┘   │
            │                   │
            │ 1:N                │
            │                   │
            │                   │
┌──────────────────────────┐   │         ┌──────────────────────────┐
│      applications        │   │         │          namespaces      │
├──────────────────────────┤   │         ├──────────────────────────┤
│ id                   [PK]│   │         │ id                   [PK]│◄──┐
│ name                     │   │         │ name                     │   │
│ workspace_id         [FK]│   │         └──────────────────────────┘   │
│ category_id          [FK]│◄──┘                      ▲                 │
│ ...existing fields...    │                           │                 │
└──────────────────────────┘                           │ N:1             │
            │                                           │                 │
            │ 1:N                                       │                 │
            │                                           │                 │
            ▼                                           │                 │
┌──────────────────────────┐                           │                 │
│    application_tags      │                           │                 │
│     (junction)           │                           │                 │
├──────────────────────────┤                           │                 │
│ id                   [PK]│                           │                 │
│ application_id       [FK]│                           │                 │
│ tag_id               [FK]│───┐                       │                 │
│ created_at               │   │                       │                 │
└──────────────────────────┘   │                       │                 │
                                │                       │                 │
                                │ N:1                   │                 │
                                │                       │                 │
                                ▼                       │                 │
┌───────────────────────────────────┐                  │                 │
│  application_tag_vocabulary       │                  │                 │
│      (controlled vocab)           │                  │                 │
├───────────────────────────────────┤                  │                 │
│ id                            [PK]│                  │                 │
│ namespace_id                  [FK]│──────────────────┘                 │
│ tag_name                          │                                    │
│ description                       │                                    │
│ is_active                         │                                    │
│ created_by                    [FK]│                                    │
│ approved_by                   [FK]│                                    │
└───────────────────────────────────┘                                    │
                                                                          │
┌───────────────────────────────────┐                                    │
│  application_tag_requests         │                                    │
│    (governance workflow)          │                                    │
├───────────────────────────────────┤                                    │
│ id                            [PK]│                                    │
│ namespace_id                  [FK]│────────────────────────────────────┘
│ requested_tag_name                │
│ reason                            │
│ requested_by                  [FK]│
│ status                            │
│ response_notes                    │
│ approved_by                   [FK]│
│ approved_tag_id               [FK]│
│ created_at                        │
│ resolved_at                       │
└───────────────────────────────────┘
```

## 7. Queries Enabled by ARM

### 7.1 Governance Queries

**"Do we already have budgeting applications?"**
```sql
SELECT a.name, a.owning_organization_id
FROM applications a
JOIN application_tags at ON a.id = at.application_id
JOIN application_tag_vocabulary tv ON at.tag_id = tv.id
WHERE tv.tag_name = 'budgeting'
  AND a.lifecycle_status = 'active';
```

**"What Financial Management applications are strategic (Invest quadrant)?"**
```sql
SELECT a.name, dp.time_classification
FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
JOIN deployment_profiles dp ON a.id = dp.application_id
WHERE ac.category_code = 'FINANCE'
  AND dp.time_classification = 'invest'
  AND dp.is_primary = true;
```

**"Show public-facing applications with compliance tags"**
```sql
SELECT DISTINCT a.name
FROM applications a
JOIN application_tags at1 ON a.id = at1.application_id
JOIN application_tag_vocabulary tv1 ON at1.tag_id = tv1.id
JOIN application_tags at2 ON a.id = at2.application_id
JOIN application_tag_vocabulary tv2 ON at2.tag_id = tv2.id
WHERE tv1.tag_name = 'public-facing'
  AND tv2.tag_name = 'compliance';
```

### 7.2 Cost Analysis Queries

**"Annual spend by business category"**
```sql
SELECT 
  ac.category_name,
  SUM(COALESCE(dp_costs.total_cost, 0)) as annual_spend
FROM application_categories ac
JOIN applications a ON ac.id = a.category_id
JOIN deployment_profiles dp ON a.id = dp.application_id
LEFT JOIN vw_deployment_profile_costs dp_costs ON dp.id = dp_costs.deployment_profile_id
GROUP BY ac.category_name
ORDER BY annual_spend DESC;
```

**"Show legacy SaaS applications by cost"**
```sql
SELECT 
  a.name,
  dp_costs.total_cost as annual_cost
FROM applications a
JOIN application_tags at1 ON a.id = at1.application_id
JOIN application_tag_vocabulary tv1 ON at1.tag_id = tv1.id
JOIN application_tags at2 ON a.id = at2.application_id
JOIN application_tag_vocabulary tv2 ON at2.tag_id = tv2.id
JOIN deployment_profiles dp ON a.id = dp.application_id
JOIN vw_deployment_profile_costs dp_costs ON dp.id = dp_costs.deployment_profile_id
WHERE tv1.tag_name = 'legacy-system'
  AND tv2.tag_name = 'saas'
  AND dp.is_primary = true
ORDER BY annual_cost DESC;
```

### 7.3 Portfolio Health Queries

**"TIME distribution across Citizen Services category"**
```sql
SELECT 
  dp.time_classification,
  COUNT(*) as app_count,
  AVG(dp.technical_health_score) as avg_tech_health,
  AVG(dp.business_fit_score) as avg_business_fit
FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
JOIN deployment_profiles dp ON a.id = dp.application_id
WHERE ac.category_code = 'CITIZEN_SERVICES'
  AND dp.is_primary = true
GROUP BY dp.time_classification;
```

### 7.4 Integration Analysis Queries

**"Show integrations between Finance and HR applications"**
```sql
SELECT 
  a_source.name as source_app,
  a_target.name as target_app,
  ii.direction,
  ii.method,
  ii.cadence
FROM internal_integrations ii
JOIN applications a_source ON ii.source_application_id = a_source.id
JOIN applications a_target ON ii.target_application_id = a_target.id
JOIN application_categories ac_source ON a_source.category_id = ac_source.id
JOIN application_categories ac_target ON a_target.category_id = ac_target.id
WHERE ac_source.category_code = 'FINANCE'
  AND ac_target.category_code = 'HR';
```

### 7.5 Tag Usage Analytics

**"Most popular tags"**
```sql
SELECT 
  tv.tag_name,
  COUNT(at.id) as usage_count,
  tv.description
FROM application_tag_vocabulary tv
LEFT JOIN application_tags at ON tv.id = at.tag_id
WHERE tv.is_active = true
GROUP BY tv.tag_name, tv.description
ORDER BY usage_count DESC
LIMIT 20;
```

**"Unused tags (candidates for cleanup)"**
```sql
SELECT 
  tv.tag_name,
  tv.created_at,
  c.display_name as created_by_name
FROM application_tag_vocabulary tv
LEFT JOIN application_tags at ON tv.id = at.tag_id
LEFT JOIN contacts c ON tv.created_by = c.id
WHERE tv.is_active = true
  AND at.id IS NULL
ORDER BY tv.created_at DESC;
```

---

## 8. AI Integration Opportunities

### 8.1 Tag Suggestion

When user creates/edits application:
```javascript
// User enters app name and description
app_name: "Oracle Hyperion Planning"
description: "Enterprise budgeting and financial planning tool"

// AI suggests:
category: "Financial Management"
tags: ["budgeting", "reporting", "cloud-native"]

// User accepts, modifies, or ignores suggestions
```

### 8.2 Natural Language Queries

```javascript
// User asks in plain English:
"Show me all our budgeting tools"

// AI translates to SQL:
SELECT a.name 
FROM applications a
JOIN application_tags at ON a.id = at.application_id
JOIN application_tag_vocabulary tv ON at.tag_id = tv.id
WHERE tv.tag_name IN ('budgeting', 'budget-planning', 'financial-planning')
   OR a.category_id IN (
     SELECT id FROM application_categories 
     WHERE category_code = 'FINANCE'
   );
```

### 8.3 Duplicate Detection

```javascript
// When user requests new tag "budget-management"
// AI checks for similar existing tags:

existing_tags: ["budgeting", "budget", "financial-planning"]

// AI suggests:
"Did you mean 'budgeting'? (used by 23 apps)"
"Or 'financial-planning'? (used by 12 apps)"
```

### 8.4 Semantic Search

```javascript
// User searches: "procurement"
// AI expands to include semantically related:
- Applications with tag "procurement"
- Applications with tag "purchasing"
- Applications with tag "vendor-management"
- Applications with category "Financial Management" AND description containing "procure"
```

---

## 9. Seed Data

> **Data Source:** Derived from analyzing a large public sector organization's application portfolio. These categories and tags reflect actual production portfolio patterns, not theoretical taxonomies.

### 9.1 Evidence-Based Design

**Key Findings from Public Sector Analysis:**
- **55% of apps were uncategorized** by simple keyword matching - validates that UNCATEGORIZED is expected, not a failure
- **11% naturally matched multiple categories** - validates multi-tag approach over single BCM hierarchy
- **Strong category signals:** Case Management (10%), IT Infrastructure (9%), Finance (5%)
- **Technology patterns:** Windows/SQL Server dominant, 10% have end-of-life components
- **Simple keyword matching** correctly classified a substantial portion of apps - sufficient for Phase 1 AI

### 9.2 Default Categories (Government Industry Preset)

**14 categories including required UNCATEGORIZED catchall**

```sql
-- Seeded via namespace creation trigger
-- Template namespace_id: 00000000-0000-0000-0000-000000000001
INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
VALUES
  -- Financial Management
  (@namespace_id, 'FINANCE', 'Financial Management', 
   'Budgeting, accounting, procurement, grants, payments, revenue management', 100),
  
  -- Human Resources
  (@namespace_id, 'HR', 'Human Resources', 
   'Payroll, benefits, recruiting, training, performance management, workforce planning', 200),
  
  -- Citizen Services
  (@namespace_id, 'CITIZEN_SERVICES', 'Citizen Services', 
   'Public-facing portals, online services, licensing, permits, registrations', 300),
  
  -- Program Delivery
  (@namespace_id, 'PROGRAM_DELIVERY', 'Program Delivery', 
   'Health, education, social services, child welfare, disability programs', 400),
  
  -- Case & Matter Management
  (@namespace_id, 'CASE_MGMT', 'Case & Matter Management', 
   'Case tracking, CRM, appeals, complaints, investigations, enforcement', 500),
  
  -- Geospatial & Land Management
  (@namespace_id, 'GIS', 'Geospatial & Land Management', 
   'Mapping, GIS, land registry, surveying, spatial analysis, crown lands', 600),
  
  -- Asset & Facility Management
  (@namespace_id, 'ASSET_MGMT', 'Asset & Facility Management', 
   'Infrastructure assets, buildings, equipment, maintenance, fleet, property', 700),
  
  -- IT Infrastructure & Operations
  (@namespace_id, 'IT_INFRA', 'IT Infrastructure & Operations', 
   'Servers, networks, databases, monitoring, security, identity management', 800),
  
  -- Business Intelligence & Reporting
  (@namespace_id, 'BI', 'Business Intelligence & Reporting', 
   'Dashboards, analytics, reporting, data warehouses, KPIs', 900),
  
  -- Compliance & Risk Management
  (@namespace_id, 'COMPLIANCE', 'Compliance & Risk Management', 
   'Audit, regulatory compliance, inspections, safety, certifications', 1000),
  
  -- Records & Document Management
  (@namespace_id, 'RECORDS', 'Records & Document Management', 
   'Document management, records retention, archives, imaging, ECM', 1100),
  
  -- Collaboration & Communication
  (@namespace_id, 'COLLABORATION', 'Collaboration & Communication', 
   'Email, SharePoint, intranet, portals, messaging, knowledge management', 1200),
  
  -- Legal & Justice
  (@namespace_id, 'LEGAL', 'Legal & Justice', 
   'Court systems, legal case management, prosecution, judicial, tribunals', 1300),
  
  -- Uncategorized (Required)
  (@namespace_id, 'UNCATEGORIZED', 'Uncategorized', 
   'Applications not yet classified or do not fit standard categories', 9999);
```

**Category Coverage Patterns (Public Sector Evidence):**

| Category | Typical Coverage | Common Patterns |
|----------|-----------------|-----------------|
| CASE_MGMT | High | Appeals, investigations, CRM systems |
| IT_INFRA | High | Servers, databases, monitoring, security |
| PROGRAM_DELIVERY | Medium | Child services, education, health programs |
| FINANCE | Medium | Procurement, grants, accounting systems |
| BI | Medium | Reporting platforms, analytics |
| ASSET_MGMT | Medium | Facilities, fleet, property management |
| GIS | Medium | Land management, mapping systems |
| HR | Low-Medium | Payroll, training, workforce systems |
| CITIZEN_SERVICES | Low-Medium | Online portals, licensing, permits |
| COMPLIANCE | Low-Medium | Inspections, enforcement, auditing |
| LEGAL | Low | Court systems, legal case management |
| RECORDS | Low | Document management, archives |
| COLLABORATION | Low | Email, intranets, knowledge systems |
| **UNCATEGORIZED** | **High (~50%)** | Domain-specific, specialized systems |

**Key Insight:** Expect approximately 50% of applications to remain UNCATEGORIZED - this validates our "BCM fails in practice" thesis. Most public sector apps are domain-specific and don't fit neat categories.

### 9.3 Default Tag Vocabulary (All Industry Presets)

**42 tags across 6 groups - manageable vocabulary with room for growth**

#### 9.3.1 Core Functions (10 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'budgeting', 'Budget planning, allocation, tracking', 'Core Functions', 100),
  (@namespace_id, 'payroll', 'Employee compensation processing', 'Core Functions', 110),
  (@namespace_id, 'reporting', 'Report generation and distribution', 'Core Functions', 120),
  (@namespace_id, 'case-management', 'Case/matter tracking and workflow', 'Core Functions', 130),
  (@namespace_id, 'licensing', 'License issuance and renewal', 'Core Functions', 140),
  (@namespace_id, 'permit-processing', 'Permit applications and approvals', 'Core Functions', 150),
  (@namespace_id, 'workflow-automation', 'Business process automation', 'Core Functions', 160),
  (@namespace_id, 'scheduling', 'Appointment and resource scheduling', 'Core Functions', 170),
  (@namespace_id, 'inventory-management', 'Stock and asset inventory', 'Core Functions', 180),
  (@namespace_id, 'inspection', 'Inspection tracking and compliance', 'Core Functions', 190);
```

#### 9.3.2 Service Model (5 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'saas', 'Software as a Service, vendor-hosted', 'Service Model', 200),
  (@namespace_id, 'on-premise', 'Self-hosted in own data center', 'Service Model', 210),
  (@namespace_id, 'cloud-native', 'Built for cloud (AWS, Azure, GCP)', 'Service Model', 220),
  (@namespace_id, 'vendor-hosted', 'Hosted by vendor but not true SaaS', 'Service Model', 230),
  (@namespace_id, 'hybrid', 'Mix of on-premise and cloud', 'Service Model', 240);
```

#### 9.3.3 Technology Platform (8 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'microsoft-365', 'Microsoft 365 ecosystem', 'Technology Platform', 300),
  (@namespace_id, 'sharepoint', 'SharePoint-based solution', 'Technology Platform', 310),
  (@namespace_id, 'dynamics-365', 'Microsoft Dynamics 365', 'Technology Platform', 320),
  (@namespace_id, 'oracle', 'Oracle platform (DB, Apps, etc)', 'Technology Platform', 330),
  (@namespace_id, 'sql-server', 'Microsoft SQL Server database', 'Technology Platform', 340),
  (@namespace_id, 'open-source', 'Built on open source stack', 'Technology Platform', 350),
  (@namespace_id, 'mobile-app', 'Mobile application (iOS/Android)', 'Technology Platform', 360),
  (@namespace_id, 'web-application', 'Browser-based application', 'Technology Platform', 370);
```

**Public Sector Evidence:** SQL Server and Oracle databases are dominant platforms, with IIS and Apache as common web servers - validates these technology tags.

#### 9.3.4 Lifecycle & Strategic (7 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'legacy-system', 'Legacy technology needing modernization', 'Lifecycle & Strategic', 400),
  (@namespace_id, 'strategic-platform', 'Key strategic investment', 'Lifecycle & Strategic', 410),
  (@namespace_id, 'enterprise-service', 'Shared across organization', 'Lifecycle & Strategic', 420),
  (@namespace_id, 'system-of-record', 'Authoritative source for data domain', 'Lifecycle & Strategic', 430),
  (@namespace_id, 'end-of-life', 'Vendor support ending', 'Lifecycle & Strategic', 440),
  (@namespace_id, 'cloud-migration-candidate', 'Target for cloud migration', 'Lifecycle & Strategic', 450),
  (@namespace_id, 'consolidation-candidate', 'Potential for consolidation', 'Lifecycle & Strategic', 460);
```

**Public Sector Evidence:** Significant portion of applications have end-of-life technology components - validates `end-of-life` and `legacy-system` tags.

#### 9.3.5 Data & Integration (6 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'master-data', 'Manages master data entities', 'Data & Integration', 500),
  (@namespace_id, 'data-warehouse', 'Centralized data repository', 'Data & Integration', 510),
  (@namespace_id, 'api-enabled', 'Provides API for integration', 'Data & Integration', 520),
  (@namespace_id, 'integration-hub', 'Central integration point', 'Data & Integration', 530),
  (@namespace_id, 'batch-processing', 'Batch/overnight processing', 'Data & Integration', 540),
  (@namespace_id, 'real-time-processing', 'Real-time transaction processing', 'Data & Integration', 550);
```

#### 9.3.6 Security & Compliance (6 tags)

```sql
INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
VALUES
  (@namespace_id, 'pii-data', 'Handles personally identifiable information', 'Security & Compliance', 600),
  (@namespace_id, 'phi-data', 'Protected health information (healthcare)', 'Security & Compliance', 610),
  (@namespace_id, 'financial-data', 'Sensitive financial information', 'Security & Compliance', 620),
  (@namespace_id, 'public-facing', 'Accessible to public/citizens', 'Security & Compliance', 630),
  (@namespace_id, 'internal-only', 'Internal staff use only', 'Security & Compliance', 640),
  (@namespace_id, 'mfa-required', 'Multi-factor authentication required', 'Security & Compliance', 650);
```

### 9.4 Industry-Specific Category Variations

#### 9.4.1 Healthcare Additional Categories (4)

```sql
-- For HEALTHCARE industry preset (includes all 13 core + these 4)
INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
VALUES
  (@namespace_id, 'CLINICAL_SYSTEMS', 'Clinical Systems', 
   'EMR, EHR, patient records, clinical workflows, CPOE, nursing documentation', 1400),
  
  (@namespace_id, 'MEDICAL_IMAGING', 'Medical Imaging', 
   'PACS, radiology, imaging systems, picture archiving', 1500),
  
  (@namespace_id, 'LAB_SYSTEMS', 'Laboratory Systems', 
   'Laboratory information systems, pathology, specimen tracking', 1600),
  
  (@namespace_id, 'PHARMACY', 'Pharmacy Systems', 
   'Medication management, dispensing, formulary, drug interaction', 1700);
```

#### 9.4.2 Higher Education Additional Categories (4)

```sql
-- For HIGHER_ED industry preset (includes all 13 core + these 4)
INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
VALUES
  (@namespace_id, 'STUDENT_INFO', 'Student Information Systems', 
   'SIS, registration, grades, transcripts, student records', 1400),
  
  (@namespace_id, 'LEARNING_MGMT', 'Learning Management', 
   'LMS, online courses, content delivery, e-learning platforms', 1500),
  
  (@namespace_id, 'RESEARCH_ADMIN', 'Research Administration', 
   'Grant management, research compliance, IRB, sponsored programs', 1600),
  
  (@namespace_id, 'ADMISSIONS', 'Admissions & Enrollment', 
   'Recruitment, applications, enrollment management, CRM', 1700);
```

#### 9.4.3 Industry Preset Summary

| Industry | Total Categories | Core | Industry-Specific |
|----------|------------------|------|-------------------|
| **GOVERNMENT** | 14 | 13 + UNCATEGORIZED | LEGAL, CITIZEN_SERVICES |
| **HEALTHCARE** | 18 | 13 + UNCATEGORIZED | CLINICAL, IMAGING, LAB, PHARMACY (+4) |
| **HIGHER_ED** | 18 | 13 + UNCATEGORIZED | STUDENT_INFO, LEARNING, RESEARCH, ADMISSIONS (+4) |

All presets share the same 42 tag vocabulary.

### 9.5 AI-Powered Category Suggestion (Phase 3)

#### 9.5.1 Keyword-Based Matching Rules

**Derived from public sector portfolio analysis - these patterns have high predictive power:**

```python
# Phase 1 AI: Simple keyword matching (correctly classifies substantial portion of apps)
CATEGORY_KEYWORDS = {
    'FINANCE': ['budget', 'finance', 'accounting', 'payroll', 'payment', 'invoice', 
                'purchase', 'procurement', 'grant', 'rebate', 'revenue', 'fiscal'],
    'HR': ['hr', 'human resource', 'employee', 'personnel', 'recruitment', 
           'staffing', 'training', 'apprentice', 'workforce', 'pension'],
    'CASE_MGMT': ['case', 'tracking', 'registry', 'crm', 'complaint', 'appeal', 
                  'investigation', 'enforcement'],
    'GIS': ['gis', 'map', 'geospatial', 'spatial', 'land', 'cadastral', 'parcel'],
    'CITIZEN_SERVICES': ['online', 'portal', 'licensing', 'permit', 'registration', 
                         'public-facing', 'e-service'],
    'PROGRAM_DELIVERY': ['education', 'health', 'social', 'child', 'student', 
                         'disability', 'foster'],
    'BI': ['reporting', 'analytics', 'dashboard', 'bi', 'cognos', 'data warehouse'],
    'IT_INFRA': ['server', 'network', 'database', 'monitoring', 'security', 
                 'infrastructure', 'identity'],
    'COMPLIANCE': ['compliance', 'audit', 'inspection', 'regulatory', 'safety'],
    'ASSET_MGMT': ['asset', 'facility', 'building', 'maintenance', 'equipment', 
                   'fleet', 'property']
}
```

#### 9.5.2 Confidence Scoring

```
HIGH (80%+):    Direct keyword match in application name
                Example: "AccPac Finance" → FINANCE (95% confidence)

MEDIUM (50-79%): Keyword in description + context clues
                Example: "Child Care System" → PROGRAM_DELIVERY (85% confidence)

LOW (30-49%):   Weak signals, suggest UNCATEGORIZED
                Example: "Bridge Management" → ASSET_MGMT (75% confidence)

NONE (<30%):    Auto-assign UNCATEGORIZED
                Example: "Account Check" → UNCATEGORIZED (25% confidence)
```

#### 9.5.3 Real-World Classification Examples

| Application Name | Suggested Category | Confidence | Reasoning |
|------------------|-------------------|------------|-----------|
| AccPac - Finance | FINANCE | 95% | Direct keyword: "finance" |
| Child Care System | PROGRAM_DELIVERY | 85% | Keywords: "child", "care" |
| Building Permit Tracker | CITIZEN_SERVICES | 80% | Keywords: "permit", "tracker" |
| Bridge Management System | ASSET_MGMT | 75% | Keywords: "management", "asset" (inferred) |
| COGNOS Reporting Environment | BI | 90% | Keywords: "cognos", "reporting" |
| Criminal Justice Information System | LEGAL | 90% | Keywords: "justice", "criminal" |
| Account Check | UNCATEGORIZED | 25% | Generic name, insufficient context |

### 9.6 Seeding Strategy Implementation

#### 9.6.1 Database Trigger Approach

```sql
-- Trigger on namespace INSERT to seed categories and tags
CREATE OR REPLACE FUNCTION seed_namespace_taxonomy()
RETURNS TRIGGER AS $$
DECLARE
  template_namespace_id UUID := '00000000-0000-0000-0000-000000000001';
  industry_preset TEXT;
BEGIN
  -- Determine industry preset from namespace metadata
  industry_preset := COALESCE(NEW.industry_type, 'GOVERNMENT');
  
  -- Seed categories based on industry preset
  IF industry_preset = 'GOVERNMENT' THEN
    -- Government: 13 core + UNCATEGORIZED = 14 categories
    INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
    SELECT NEW.id, category_code, category_name, category_description, sort_order
    FROM application_categories
    WHERE namespace_id = template_namespace_id
      AND category_code IN ('FINANCE', 'HR', 'CITIZEN_SERVICES', 'PROGRAM_DELIVERY', 
                            'CASE_MGMT', 'GIS', 'ASSET_MGMT', 'IT_INFRA', 'BI', 
                            'COMPLIANCE', 'RECORDS', 'COLLABORATION', 'LEGAL', 'UNCATEGORIZED');
  
  ELSIF industry_preset = 'HEALTHCARE' THEN
    -- Healthcare: All GOVERNMENT categories + 4 healthcare-specific = 18 total
    INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
    SELECT NEW.id, category_code, category_name, category_description, sort_order
    FROM application_categories
    WHERE namespace_id = template_namespace_id;
  
  ELSIF industry_preset = 'HIGHER_ED' THEN
    -- Higher-Ed: All GOVERNMENT categories + 4 higher-ed-specific = 18 total
    INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
    SELECT NEW.id, category_code, category_name, category_description, sort_order
    FROM application_categories
    WHERE namespace_id = template_namespace_id;
  END IF;
  
  -- Seed default tags (same 42 tags for all industries)
  INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
  SELECT NEW.id, tag_name, tag_description, tag_group, sort_order
  FROM application_tag_vocabulary
  WHERE namespace_id = template_namespace_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_seed_namespace_taxonomy
  AFTER INSERT ON namespaces
  FOR EACH ROW
  EXECUTE FUNCTION seed_namespace_taxonomy();
```

#### 9.6.2 Migration for Existing Namespaces

```sql
-- Example: Seed namespace with GOVERNMENT preset
DO $$
DECLARE
  target_namespace_id UUID := '<target-namespace-uuid>';
  template_namespace_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Seed categories
  INSERT INTO application_categories (namespace_id, category_code, category_name, category_description, sort_order)
  SELECT target_namespace_id, category_code, category_name, category_description, sort_order
  FROM application_categories
  WHERE namespace_id = template_namespace_id
    AND category_code IN ('FINANCE', 'HR', 'CITIZEN_SERVICES', 'PROGRAM_DELIVERY', 
                          'CASE_MGMT', 'GIS', 'ASSET_MGMT', 'IT_INFRA', 'BI', 
                          'COMPLIANCE', 'RECORDS', 'COLLABORATION', 'LEGAL', 'UNCATEGORIZED');
  
  -- Seed tags
  INSERT INTO application_tag_vocabulary (namespace_id, tag_name, tag_description, tag_group, sort_order)
  SELECT target_namespace_id, tag_name, tag_description, tag_group, sort_order
  FROM application_tag_vocabulary
  WHERE namespace_id = template_namespace_id;
  
  -- Optional: AI-classify existing apps (Phase 3)
  -- UPDATE applications SET category_id = ai_suggest_category(application_name, description)
  -- WHERE namespace_id = target_namespace_id;
END $$;
```

### 9.7 Success Metrics & Adoption Targets

#### 9.7.1 Category Adoption Timeline

| Timeframe | Target | Metric |
|-----------|--------|--------|
| Month 1 | 30% | Apps moved from UNCATEGORIZED |
| Month 3 | 60% | Apps with non-UNCATEGORIZED category |
| Month 6 | 80% | Apps properly categorized |
| Month 12 | 95% | Apps with category |

**Note:** ~50% UNCATEGORIZED is expected initially with keyword-based classification - this is reality, not failure.

#### 9.7.2 Tag Governance Metrics

| Metric | Target | Purpose |
|--------|--------|---------|
| Tag request turnaround | <48 hours | User satisfaction |
| Tag approval rate | 60-80% | Balance governance vs. flexibility |
| Duplicate tag detection | >90% | Prevent vocabulary chaos |
| Tag usage (30 days) | >10 uses per tag | Identify unused tags for cleanup |

#### 9.7.3 Query Usage Metrics

Track how often users execute these governance queries:

```sql
-- "Do we already have budgeting applications?"
SELECT COUNT(*) FROM applications a
JOIN application_tags at ON a.id = at.application_id
JOIN application_tag_vocabulary tv ON at.tag_id = tv.id
WHERE tv.tag_name = 'budgeting';

-- "Show all Financial apps across workspaces"
SELECT COUNT(*) FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
WHERE ac.category_code = 'FINANCE';
```

**Success indicator:** >10 governance queries per week suggests ARM is delivering value.

### 9.8 Key Takeaways for Implementation

1. **~50% UNCATEGORIZED is expected** - Don't try to force-fit everything into categories. This validates our "BCM fails in practice" thesis.

2. **Multi-category support validated** - Significant portion of public sector apps naturally span 2+ categories. Tags handle this elegantly.

3. **Tag governance is essential** - Start with 42 controlled tags, expect to grow to 80-100 over first year through governance workflow.

4. **AI keyword matching works** - Simple keyword rules can correctly classify a substantial portion of applications. Good enough for Phase 1.

5. **Industry presets matter** - Public sector needs LEGAL/CITIZEN_SERVICES, Healthcare needs CLINICAL/IMAGING, Higher-Ed needs STUDENT_INFO/LEARNING.

6. **Technology tags valuable** - SQL Server, Oracle, Dynamics patterns strong in real data - validates platform tags.

7. **Evidence trumps theory** - This seed data is based on real public sector portfolio analysis, not theoretical ARM taxonomies.

---

## 10. Migration Considerations

### 10.1 From Nothing (Greenfield)

**Phase 1: Create Tables (Week 1)**
- Add `application_categories` table
- Add `application_tag_vocabulary` table
- Add `application_tags` junction table
- Add `application_tag_requests` table
- Seed default categories and tags for namespace type (government, healthcare, etc.)

**Phase 2: Modify Applications Table (Week 1)**
- Add `category_id` column to applications (nullable initially)
- Backfill existing applications with 'UNCATEGORIZED' category
- Make `category_id` required for new applications

**Phase 3: UI Implementation (Weeks 2-3)**
- Category dropdown on application form
- Tag multi-select with "Request new tag" option
- Tag request review UI for Namespace Admins
- Tag management dashboard

**Phase 4: Reporting Views (Week 4)**
- Add category/tag filters to application list
- Cost rollup by category
- TAG usage analytics for admins

### 10.2 Existing Applications Migration

**Scenario:** 500 existing applications need classification.

**Option A: Manual Classification (Gradual)**
- Default all to 'UNCATEGORIZED'
- Workspace users classify their own apps over time
- Dashboard shows "X applications need classification"

**Option B: AI-Assisted Bulk Classification**
```javascript
// For each application:
app = {
  name: "Oracle E-Business Suite",
  description: "Financial management system for general ledger, accounts payable, and reporting"
}

// AI suggests:
category: "Financial Management"
tags: ["reporting", "compliance", "on-premise"]

// Present to user for confirmation/modification
```

**Option C: Import from CSV**
```csv
application_name,category_code,tag1,tag2,tag3
"Oracle E-Business Suite","FINANCE","reporting","compliance","on-premise"
"Workday HCM","HR","saas","strategic-platform",
"ServiceNow","IT_INFRASTRUCTURE","workflow-automation","saas","strategic-platform"
```

### 10.3 Tag Vocabulary Evolution

**Year 1:** Start with 25-30 seeded tags
**Year 2:** Add 10-20 tags based on user requests
**Year 3:** Consolidate similar tags (merge "budget" → "budgeting")
**Ongoing:** Deactivate unused tags (0 usage after 6 months)

### 10.4 Integration with Existing Features

**Portfolios:**
- No migration needed
- Portfolios continue working as-is
- ARM categories/tags are additive

**Workspace Groups:**
- No migration needed
- Can add category-based filtering to workspace group views

**Deployment Profiles:**
- No schema changes
- Dashboard can filter by app category: "Show Finance DPs in Invest quadrant"

**Cost Model:**
- Add category rollup to cost views
- No data migration needed

---

## 11. Open Questions or Follow-Up Work

### 11.1 Tag Lifecycle Management

**Questions:**
- Auto-deactivate tags with 0 usage after N months?
- Tag versioning (e.g., rename "budget" to "budgeting" - affect historical data)?
- Tag approval SLA for requests?

**Proposal:** Start simple - admin manually reviews and cleans up. Add automation later if needed.

### 11.2 Category Customization

**Questions:**
- Should customers be able to add custom categories?
- Or only choose from industry templates?
- What's the risk of category sprawl?

**Proposal:** Start with fixed categories, allow custom categories in Enterprise tier only.

### 11.3 Tag Hierarchy

**Questions:**
- Should tags support parent-child? (e.g., "compliance" > "gdpr-compliance")
- Or keep flat to avoid complexity?

**Proposal:** Keep flat. If hierarchy is needed later, that's moving toward BCM (which we're avoiding).

### 11.4 Multi-Tenancy Edge Cases

**Questions:**
- If application moves to different workspace, does it keep its tags?
- If workspace joins different namespace, what happens to tags?

**Proposal:** Tags are namespace-scoped. App keeps tags if staying in same namespace. Loses tags if moving to different namespace.

### 11.5 AI-Powered Classification

**Questions:**
- Should AI auto-apply tags without user confirmation?
- What's the accuracy threshold to trust AI suggestions?
- How to handle AI suggesting tags that don't exist yet?

**Proposal:** 
- Phase 1: AI suggests, user confirms
- Phase 2: AI auto-applies high-confidence tags (>90% confidence)
- Phase 3: AI can request new tags on user's behalf (with reason)

---

## 12. Out of Scope

### 12.1 Full Business Capability Model

**Not Building:**
- Hierarchical L1 → L2 → L3 capability decomposition
- BCM maintenance workflows
- Capability gap analysis (which capabilities lack applications)
- Capability heat maps

**Rationale:** Too complex, nobody maintains it, ARM categories + tags provide 80% of value.

### 12.2 Application Feature Catalogs

**Not Building:**
- Detailed feature/function inventories
- "Oracle EBS has these 47 modules" documentation
- Feature-to-feature comparison across apps

**Rationale:** That's a software catalog, not ARM. Our focus is "what business function does this serve?"

### 12.3 Service Dependency Modeling

**Not Building:**
- Full dependency graphs with criticality scoring
- "If this app fails, these 12 apps are impacted" analysis
- Real-time availability correlation

**Rationale:** We have `internal_integrations` for basic dependency mapping. Full dependency analysis is CMDB/observability domain.

### 12.4 Enterprise Architecture Frameworks

**Not Building:**
- TOGAF compliance
- Zachman Framework alignment
- Full FEAF reference models (we're only doing ARM piece)

**Rationale:** GetInSync is APM, not full EA tool. Stay focused.

---

## 13. Competitive Analysis

### 13.1 vs. LeanIX

| Feature | LeanIX | GetInSync ARM |
|---------|--------|---------------|
| Business Capability Model | ✅ Full L1-L3 hierarchy | ❌ Categories + tags instead |
| Industry templates | ✅ 20+ industries | ✅ Government, healthcare, higher-ed |
| Tag management | ⚠️ Free-form tags | ✅ Controlled vocabulary |
| Implementation time | ⚠️ 3-6 months | ✅ Works day one with seeds |
| Maintenance overhead | ❌ Requires EA team | ✅ Namespace admin can manage |
| AI assistance | ⚠️ Basic | ✅ Planned for classification |
| Cost transparency | ⚠️ Basic | ✅ Full TBM-lite integration |

### 13.2 vs. Ardoq

| Feature | Ardoq | GetInSync ARM |
|---------|-------|---------------|
| Metamodel flexibility | ✅ Fully customizable | ⚠️ Fixed model (simpler) |
| Business Capability Model | ✅ Full support | ❌ Categories + tags instead |
| Graph visualization | ✅ Advanced | ⚠️ Basic (planned) |
| Learning curve | ❌ Steep | ✅ "18-year-old test" |
| CSDM alignment | ⚠️ Via mapping | ✅ Native |

### 13.3 vs. ServiceNow APM

| Feature | ServiceNow APM | GetInSync ARM |
|---------|----------------|---------------|
| Business Capability Model | ✅ Via BSM | ❌ Categories + tags instead |
| Integration with CMDB | ✅ Native | ⚠️ Sync to CMDB (planned) |
| Cost transparency | ⚠️ TBM module required | ✅ Built-in |
| Multi-tenant SaaS | ❌ No | ✅ Yes |
| Deployment Profile model | ❌ No | ✅ Unique differentiator |
| Standalone tool | ❌ Requires ServiceNow | ✅ Yes |

### 13.4 GetInSync Differentiators

**What makes our ARM better:**
1. **Pragmatic:** No BCM complexity tax
2. **Governed:** Controlled vocabulary prevents tag chaos
3. **Integrated:** Native cost transparency and DP model
4. **Simple:** "18-year-old test" - understandable UI
5. **Fast:** Works day one with seed data
6. **Maintainable:** Namespace admin can manage without EA consultants


## 14. Phasing Recommendation

### Phase 1: MVP (2 weeks)

**Scope:**
- application_categories table
- application_tag_vocabulary table
- application_tags junction
- Seed data for government namespace
- Basic UI (dropdown + multi-select)

**Effort:** 2 weeks
**Value:** Enables basic "do we already have this?" queries

### Phase 2: Governance (3 months later)

**Scope:**
- application_tag_requests table
- Tag request workflow UI
- Admin tag management dashboard
- Tag usage analytics

**Effort:** 1 week
**Value:** Prevents tag chaos, enables cleanup

### Phase 3: AI Integration (6 months later)

**Scope:**
- AI-suggested categories/tags
- Natural language queries
- Semantic search
- Duplicate detection

**Effort:** 3 weeks
**Value:** Reduces manual classification burden

### Phase 4: Advanced Reporting (12 months later)

**Scope:**
- Cost rollup by category dashboards
- Integration analysis by category
- Portfolio health by category
- Capability gap identification (simulated without BCM)

**Effort:** 2 weeks
**Value:** Full ARM competitive feature parity

---

## 15. Success Metrics

### Adoption Metrics
- % of applications with non-UNCATEGORIZED category (target: >95% after 6 months)
- Average tags per application (target: 2-3)
- % of active tags with >0 usage (target: >80%)

### Governance Metrics
- Tag request turnaround time (target: <48 hours)
- Tag approval rate (target: 60-80% approved, rest merged/denied)
- Unused tags cleaned up per quarter (target: review quarterly)

### Value Metrics
- "Do we already have X?" queries answered via ARM (track in product analytics)
- Redundant purchase prevented (user feedback)
- Time saved on portfolio analysis (qualitative)

---

## 16. Related Documents

| Document | Relationship |
|----------|--------------|
| core/core-architecture.md | Defines Namespace/Workspace hierarchy |
| core/workspace-group.md | Federated visibility (complementary to ARM) |
| catalogs/business-application.md | Application entity definition |
| features/integrations/architecture.md | Integration mapping (leveraged by ARM queries) |
| features/cost-budget/cost-model.md | Cost rollup by category |
| core/involved-party.md | Contacts (tag creators/approvers) |

---

## 17. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.0 | 2026-01-26 | Complete rewrite. Dropped full BCM in favor of controlled vocabulary approach. Added tag governance workflow, AI integration opportunities, and phased implementation plan. **Updated Section 9 with evidence-based seed data derived from real public sector portfolio analysis** - includes 14 public sector categories with coverage patterns, 42 tags across 6 groups, industry presets (Healthcare, Higher-Ed), AI keyword matching rules, and seeding strategy. |
| v1.0 | 2026-01-26 | Initial version based on FEAF ARM with full BCM. Abandoned due to implementation complexity. |

---

End of specification.
