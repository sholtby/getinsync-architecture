# catalogs/application-reference-model-erd.md
GetInSync Architecture Specification - Application Reference Model ERD
Last updated: 2026-01-26

---

## Overview

This ERD represents the **v2.0 Controlled Vocabulary Approach** to Application Reference Model, replacing the abandoned v1.0 BCM hierarchical model.

**Key Design Principles:**
- Primary classification via `application_categories` (required, single-select)
- Secondary classification via controlled `application_tag_vocabulary` (optional, multi-select)
- Namespace-scoped taxonomy (each namespace has own categories/tags)
- Tag governance workflow prevents vocabulary chaos
- No hierarchical decomposition (no L1→L2→L3 complexity)

**What Changed from v1.0:**
- ❌ Removed: SERVICE_DOMAIN (horizontal categories)
- ❌ Removed: CAPABILITY_CATEGORY (strategic classification)
- ❌ Removed: APP_CAPABILITY_MAP (BCM junction table)
- ❌ Removed: BUSINESS_CAPABILITY (hierarchical L1→L2→L3)
- ✅ Added: application_categories (simple primary classification)
- ✅ Added: application_tag_vocabulary (controlled tags)
- ✅ Added: application_tags (many-to-many junction)
- ✅ Added: application_tag_requests (governance workflow)

---

## ASCII ERD (Conceptual)

```
+-------------------+
|    NAMESPACE      |
+-------------------+
| id            [PK]|
| name              |
| industry_type     |  (GOVERNMENT, HEALTHCARE, HIGHER_ED)
+-------------------+
         |
         | 1:N (owns taxonomy)
         |
         +---------------------------+---------------------------+
         |                           |                           |
         v                           v                           v
+------------------------+  +------------------------+  +------------------------+
| APPLICATION_CATEGORY   |  |APP_TAG_VOCABULARY      |  |APP_TAG_REQUEST         |
+------------------------+  +------------------------+  +------------------------+
| id                 [PK]|  | id                 [PK]|  | id                 [PK]|
| namespace_id       [FK]|  | namespace_id       [FK]|  | namespace_id       [FK]|
| category_code          |  | tag_name               |  | requested_tag_name     |
| category_name          |  | tag_description        |  | justification          |
| category_description   |  | tag_group              |  | requested_by       [FK]|
| sort_order             |  | sort_order             |  | status                 |
| created_at             |  | usage_count            |  | reviewed_by        [FK]|
| is_active              |  | created_at             |  | review_notes           |
+------------------------+  | is_active              |  | created_at             |
         |                  +------------------------+  | reviewed_at            |
         | N:1                       |                  +------------------------+
         |                           | N:M                       |
         |                           |                           | (workflow)
         |                           |                           v
         |                           |               +------------------------+
         |                           |               |   NAMESPACE_ADMIN      |
         |                           |               +------------------------+
         |                           |               | (approves tag requests)|
         |                           |               +------------------------+
         |                           |
         |                           |
         v                           v
+-------------------+       +-------------------+
|   APPLICATION     |<----->| APPLICATION_TAGS  |  (Many-to-Many Junction)
+-------------------+  1:N  +-------------------+
| id            [PK]|       | id            [PK]|
| workspace_id  [FK]|       | application_id[FK]|----+
| name              |       | tag_id        [FK]|<---+
| description       |       | tagged_by     [FK]|    |
| category_id   [FK]|-------| tagged_at         |    |
| lifecycle_status  |  N:1  +-------------------+    |
| owning_org    [FK]|                                |
| created_at        |                                |
+-------------------+                                |
         |                                           |
         | (category is required)                    |
         +-------------------------------------------+
                           |
                           | (tags are optional, multi-select)
                           v
                  APP_TAG_VOCABULARY


+-------------------+
|   WORKSPACE       |
+-------------------+
| id            [PK]|
| namespace_id  [FK]|<---- (applications belong to workspace)
| name              |
+-------------------+
         |
         | 1:N
         v
+-------------------+
|   APPLICATION     |
+-------------------+
```

---

## Detailed Entity-Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NAMESPACE                                   │
│         (Multi-tenant container for public sector org)              │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N (owns taxonomy)
               ┌──────────────┴──────────────┐
               │                             │
               v                             v
┌─────────────────────────────┐   ┌─────────────────────────────┐
│  APPLICATION_CATEGORY       │   │  APP_TAG_VOCABULARY         │
│  (Primary Classification)   │   │  (Secondary Classification) │
├─────────────────────────────┤   ├─────────────────────────────┤
│ • FINANCE                   │   │ Tag Groups:                 │
│ • HR                        │   │ • Core Functions (10 tags)  │
│ • CITIZEN_SERVICES          │   │ • Service Model (5 tags)    │
│ • PROGRAM_DELIVERY          │   │ • Tech Platform (8 tags)    │
│ • CASE_MGMT                 │   │ • Lifecycle (7 tags)        │
│ • GIS                       │   │ • Data & Integration (6)    │
│ • ASSET_MGMT                │   │ • Security & Compliance (6) │
│ • IT_INFRA                  │   │                             │
│ • BI                        │   │ Examples:                   │
│ • COMPLIANCE                │   │ • budgeting                 │
│ • RECORDS                   │   │ • saas                      │
│ • COLLABORATION             │   │ • legacy-system             │
│ • LEGAL                     │   │ • api-enabled               │
│ • UNCATEGORIZED (required)  │   │ • pii-data                  │
└─────────────────────────────┘   └─────────────────────────────┘
               │                             │
               │ N:1                         │ N:M (via junction)
               │ (required)                  │ (optional)
               │                             │
               │                             │
               └──────────┬──────────────────┘
                          │
                          v
              ┌─────────────────────────┐
              │     APPLICATION         │
              ├─────────────────────────┤
              │ • category_id [FK]      │ ───── REQUIRED (single-select)
              │ • tags (via junction)   │ ───── OPTIONAL (multi-select)
              ├─────────────────────────┤
              │ Example:                │
              │                         │
              │ App: "Budget Manager"   │
              │ Category: FINANCE       │
              │ Tags: budgeting,        │
              │       saas,             │
              │       api-enabled,      │
              │       financial-data    │
              └─────────────────────────┘
                          │
                          │ 1:N
                          v
              ┌─────────────────────────┐
              │  APPLICATION_TAGS       │
              │  (Junction Table)       │
              ├─────────────────────────┤
              │ • application_id [FK]   │
              │ • tag_id         [FK]   │
              │ • tagged_by      [FK]   │
              │ • tagged_at             │
              └─────────────────────────┘


┌────────────────────────────────────────────────────────────────────┐
│                    TAG GOVERNANCE WORKFLOW                         │
└────────────────────────────────────────────────────────────────────┘

         User wants new tag not in vocabulary
                     │
                     v
         ┌────────────────────────┐
         │ APPLICATION_TAG_REQUEST│
         ├────────────────────────┤
         │ • requested_tag_name   │
         │ • justification        │
         │ • status: PENDING      │
         └────────────────────────┘
                     │
                     v
         Namespace Admin reviews
                     │
         ┌───────────┴───────────┐
         │                       │
         v                       v
    APPROVED                 DENIED
         │                       │
         v                       │
┌─────────────────────┐          │
│ Create new tag in   │          │
│ APP_TAG_VOCABULARY  │          │
└─────────────────────┘          │
         │                       │
         └───────────┬───────────┘
                     v
         User notified of decision
```

---

## Relationship Summary

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| NAMESPACE : APPLICATION_CATEGORY | 1:N | Each namespace has its own category taxonomy |
| NAMESPACE : APP_TAG_VOCABULARY | 1:N | Each namespace has its own controlled tag vocabulary |
| APPLICATION : APPLICATION_CATEGORY | N:1 | Each app has ONE required category |
| APPLICATION : APPLICATION_TAGS | 1:N | Apps can have multiple tags |
| APPLICATION_TAGS : APP_TAG_VOCABULARY | N:1 | Tags reference controlled vocabulary |
| NAMESPACE : APP_TAG_REQUEST | 1:N | Tag requests are namespace-scoped |
| WORKSPACE : APPLICATION | 1:N | Apps belong to workspaces within namespace |

---

## Entity Descriptions

### NAMESPACE
Multi-tenant container representing a public sector organization. Each namespace has its own isolated taxonomy (categories and tags).

**Key Fields:**
- `industry_type`: GOVERNMENT, HEALTHCARE, HIGHER_ED (determines category seed data)

### APPLICATION_CATEGORY
**Primary classification (required, single-select)**

Namespace-scoped lookup table for primary application classification. Each namespace gets seeded with 14 default categories for public sector (FINANCE, HR, CITIZEN_SERVICES, etc.) or 18 categories for healthcare/higher-ed.

**Key Fields:**
- `category_code`: Unique code within namespace (e.g., 'FINANCE', 'HR')
- `category_name`: Display name (e.g., 'Financial Management')
- `category_description`: Full description of what belongs in this category
- `sort_order`: Controls display order in UI dropdowns
- `is_active`: Soft delete flag (categories can be deprecated but not deleted)

**Design Notes:**
- ~50% of applications typically end up in UNCATEGORIZED - this is expected
- Categories are admin-managed, not user-editable
- Categories are seeded at namespace creation via database trigger

### APP_TAG_VOCABULARY
**Secondary classification (optional, multi-select)**

Namespace-scoped controlled vocabulary of approved tags. Prevents free-form tag chaos while allowing flexibility.

**Key Fields:**
- `tag_name`: Lowercase kebab-case (e.g., 'budgeting', 'legacy-system')
- `tag_description`: What this tag means
- `tag_group`: Grouping for UI organization (Core Functions, Service Model, etc.)
- `sort_order`: Display order within tag group
- `usage_count`: How many apps use this tag (denormalized for analytics)
- `is_active`: Soft delete flag

**Tag Groups:**
1. Core Functions (10 tags): budgeting, payroll, reporting, etc.
2. Service Model (5 tags): saas, on-premise, cloud-native, etc.
3. Technology Platform (8 tags): sql-server, oracle, dynamics-365, etc.
4. Lifecycle & Strategic (7 tags): legacy-system, end-of-life, etc.
5. Data & Integration (6 tags): api-enabled, data-warehouse, etc.
6. Security & Compliance (6 tags): pii-data, public-facing, etc.

**Design Notes:**
- Start with 42 default tags, grow to 80-100 through governance
- Tags are namespace-scoped (Org A's "budgeting" ≠ Org B's "budgeting")
- Usage count helps identify unused tags for cleanup

### APPLICATION
Core application entity. Each app has ONE required category and ZERO or more optional tags.

**Key Fields:**
- `category_id [FK]`: Required foreign key to application_categories
- Tags accessed via many-to-many junction table

**Example:**
```
Application: "Budget Manager"
Category: FINANCE (required, single-select)
Tags: budgeting, saas, api-enabled, financial-data (optional, multi-select)
```

### APPLICATION_TAGS
**Many-to-many junction table** linking applications to tags.

**Key Fields:**
- `application_id [FK]`: Which application
- `tag_id [FK]`: Which tag from vocabulary
- `tagged_by [FK]`: User who applied the tag (audit trail)
- `tagged_at`: Timestamp (audit trail)

**Design Notes:**
- One row per application-tag combination
- Multiple tags per application allowed
- Deleting a tag from vocabulary cascades to remove from all applications

### APP_TAG_REQUEST
**Governance workflow** for requesting new tags not in the controlled vocabulary.

**Key Fields:**
- `requested_tag_name`: User's proposed tag name
- `justification`: Why this tag is needed
- `requested_by [FK]`: User making request
- `status`: PENDING, APPROVED, DENIED, MERGED
- `reviewed_by [FK]`: Namespace Admin who reviewed
- `review_notes`: Admin's notes (if denied, why? if merged, with what?)

**Workflow:**
1. User wants tag "procurement" but it doesn't exist
2. User submits APP_TAG_REQUEST with justification
3. Namespace Admin reviews:
   - APPROVED → Create new tag in APP_TAG_VOCABULARY
   - DENIED → Explain why (e.g., "too specific, use 'budgeting' instead")
   - MERGED → "Similar to existing 'purchasing' tag - merged"
4. User notified of decision

**Design Notes:**
- Prevents duplicate tags ("finance" vs "financial" vs "Finance")
- Admin sees similar existing tags during review
- Approved requests auto-create vocabulary entries

### WORKSPACE
Organizational unit within namespace (e.g., Department, Division).

**Relationship to ARM:**
- Applications belong to workspaces
- Categories and tags are namespace-scoped (shared across all workspaces)

---

## Queries Enabled by This Model

### 1. Find Duplicate Applications
```sql
-- "Do we already have budgeting applications?"
SELECT a.name, a.owning_organization, w.name as workspace
FROM applications a
JOIN application_tags at ON a.id = at.application_id
JOIN application_tag_vocabulary tv ON at.tag_id = tv.id
JOIN workspaces w ON a.workspace_id = w.id
WHERE tv.tag_name = 'budgeting'
  AND a.lifecycle_status = 'active';
```

### 2. Portfolio Rationalization by Category
```sql
-- "Show all Financial Management apps across organization"
SELECT a.name, w.name as workspace, a.lifecycle_status
FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
JOIN workspaces w ON a.workspace_id = w.id
WHERE ac.category_code = 'FINANCE'
ORDER BY a.name;
```

### 3. Technology Stack Analysis
```sql
-- "What apps use legacy technology?"
SELECT a.name, ac.category_name
FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
JOIN application_tags at ON a.id = at.application_id
JOIN application_tag_vocabulary tv ON at.tag_id = tv.id
WHERE tv.tag_name IN ('legacy-system', 'end-of-life');
```

### 4. Tag Governance Analytics
```sql
-- "Which tags are unused and should be cleaned up?"
SELECT tag_name, usage_count, created_at
FROM application_tag_vocabulary
WHERE namespace_id = @namespace_id
  AND usage_count = 0
  AND created_at < NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;
```

### 5. Categorization Progress
```sql
-- "How many apps are still uncategorized?"
SELECT 
  ac.category_name,
  COUNT(*) as app_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM applications a
JOIN application_categories ac ON a.category_id = ac.id
WHERE a.namespace_id = @namespace_id
GROUP BY ac.category_name
ORDER BY app_count DESC;
```

---

## Migration from v1.0 to v2.0

### What Happens to Existing Data

**If you had v1.0 BCM implementation:**

| v1.0 Entity | v2.0 Migration |
|-------------|----------------|
| SERVICE_DOMAIN | Map to closest APPLICATION_CATEGORY or UNCATEGORIZED |
| CAPABILITY_CATEGORY | Ignore (Core/Shared/Enabling doesn't map to new model) |
| BUSINESS_CAPABILITY | Export for reference, don't migrate |
| APP_CAPABILITY_MAP | Analyze to seed initial application tags |

**Migration Strategy:**
1. Seed v2.0 categories (14 for public sector)
2. Seed v2.0 tags (42 default)
3. AI-classify existing apps using keyword matching
4. Review UNCATEGORIZED apps manually (expect ~50%)
5. Deprecate v1.0 tables (don't delete immediately)

---

## Comparison: v1.0 vs v2.0

| Aspect | v1.0 (BCM Hierarchy) | v2.0 (Controlled Vocabulary) |
|--------|----------------------|------------------------------|
| **Primary Classification** | SERVICE_DOMAIN + CAPABILITY_CATEGORY | APPLICATION_CATEGORY (single, required) |
| **Secondary Classification** | APP_CAPABILITY_MAP → BUSINESS_CAPABILITY (L1→L2→L3) | APPLICATION_TAGS → Controlled vocabulary |
| **Complexity** | High (hierarchical BCM) | Low (flat categories + tags) |
| **Maintenance** | Requires EA team | Namespace Admin can manage |
| **Implementation Time** | 3-6 months (workshops + mapping) | 2 weeks (seed data + UI) |
| **User Experience** | Complex (must understand BCM) | Simple (dropdown + multi-select) |
| **Governance** | Rigid (BCM changes are major) | Flexible (tag requests approved quickly) |
| **Typical Coverage** | ~30% (too hard to classify everything) | ~50% (UNCATEGORIZED is acceptable) |

---

## Key Design Decisions

### 1. Why Category is Required
**Decision:** Every application MUST have a category (even if UNCATEGORIZED).

**Rationale:**
- Forces minimal classification effort
- UNCATEGORIZED is a valid state for domain-specific apps
- Enables basic portfolio reporting without tags

### 2. Why Tags are Optional
**Decision:** Tags are completely optional (many-to-many).

**Rationale:**
- Apps can have 0 tags and still be useful in portfolio
- Tags provide incremental value, not all-or-nothing
- Users can add tags over time as they learn the system

### 3. Why Namespace-Scoped Taxonomy
**Decision:** Each namespace has its own categories and tags.

**Rationale:**
- Multi-tenant SaaS requires data isolation
- Different organizations may define categories differently
- Industry-specific categories (CLINICAL for healthcare, STUDENT_INFO for higher-ed)

### 4. Why Tag Governance Workflow
**Decision:** Users can't create tags freely - must request via workflow.

**Rationale:**
- Prevents tag chaos ("finance", "financial", "Finance", "fin")
- Admin can merge duplicates ("purchasing" → "procurement")
- Usage analytics identify unused tags for cleanup
- Maintains controlled vocabulary over time

### 5. Why No Hierarchical Decomposition
**Decision:** No L1→L2→L3 capability hierarchies.

**Rationale:**
- BCM hierarchies fail in practice (substantial uncategorized apps in real portfolios)
- Maintenance burden requires dedicated EA team
- Simple categories + tags achieve 80% of value with 20% of complexity
- Tag groups provide enough structure without hierarchy

---

## Success Metrics

### Category Adoption
- **Month 1:** 30% of apps moved from UNCATEGORIZED
- **Month 6:** 50% of apps properly categorized
- **Month 12:** ~50% remain UNCATEGORIZED (expected, not failure)

### Tag Usage
- **Month 3:** Average 2 tags per categorized app
- **Month 6:** 60% of apps have at least 1 tag
- **Tag vocabulary:** Grow from 42 → 80-100 tags via governance

### Governance Health
- **Tag request turnaround:** <48 hours
- **Tag approval rate:** 60-80% (balance governance vs. flexibility)
- **Duplicate detection:** >90% of similar tags caught by admin review
- **Tag cleanup:** Unused tags (0 usage, 30+ days old) reviewed quarterly

---

## Related Documents

- **catalogs/application-reference-model.md** - Full architecture specification
- **core/core-architecture.md** - Core namespace/workspace model
- **catalogs/business-application.md** - Application entity details

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v2.0 | 2026-01-26 | Complete rewrite. Replaced v1.0 BCM hierarchy with controlled vocabulary approach. Added application_categories, application_tag_vocabulary, application_tags junction table, and tag governance workflow. Based on real public sector portfolio analysis. |
| v1.0 | 2026-01-26 | Initial version with BCM hierarchy (SERVICE_DOMAIN, CAPABILITY_CATEGORY, BUSINESS_CAPABILITY). Abandoned due to implementation complexity. |

---

End of ERD specification.
