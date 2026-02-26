# Business Capability & Business Services Architecture

**Version:** 1.0
**Status:** 🟡 AS-DESIGNED
**Date:** 2026-02-25
**Author:** Stuart Holtby / Claude Opus 4.6

---

## Purpose

This document defines two new architectural layers for GetInSync NextGen:

1. **Business Capabilities** — a hierarchical taxonomy of what the organization does, mapped to applications for portfolio analysis. Available to all customers.
2. **Business Services** — an operational service layer that bridges capabilities to the CSDM service model. Available to ServiceNow-integrated customers.

These layers are additive. No existing tables, views, RLS policies, or UI components are modified.

---

## Problem Statement

Every GetInSync customer eventually asks: *"Show me all applications that support Finance"* or *"How many applications do we have supporting Public Safety?"*

Today there is no structured way to answer this. Applications exist in workspaces and portfolios, but neither represents a business function. Workspaces are organizational (Ministry of Finance), portfolios are analytical groupings (Critical Applications). Neither answers "what business capability does this application enable?"

Additionally, ServiceNow-integrated customers pursuing CSDM maturity need a Business Service layer that populates the **Service** field on the incident form. This is the Walk-stage requirement that connects portfolio data to ITSM operations. GetInSync's IT Services table covers Technical Services (infrastructure), but the business-facing service concept has no home.

---

## Design Principles

1. **A tag, not a project.** Business capability mapping in GetInSync is a dropdown on a record the user is already maintaining — not a standalone enterprise architecture exercise. If it takes more than 30 seconds to map an application to a capability, the design is wrong.

2. **Seed and customize.** Ship a reference taxonomy (L1/L2) that customers can use immediately or customize. Don't force them to build from scratch, and don't lock them into a rigid structure.

3. **Two tracks, one schema.** Non-ServiceNow clients use capabilities for portfolio analysis. ServiceNow clients add business services for CSDM integration. Neither track requires the other.

4. **No premature depth.** Seed L1 and L2. Support unlimited depth via self-referencing parent_id. Customers fill L3+ when they're ready. L4 and beyond is process territory — out of scope for APM.

5. **18-year-old test.** The UI label is "Business Function" or "What does this app support?" — not "Business Capability." No CSDM jargon in the interface.

---

## Architecture

### Entity Relationship

```
Business Capability (hierarchical taxonomy)
  └── mapped to → Application (via junction)
        └── deployed as → Deployment Profile (Application Service)
              ├── built on → IT Service (Technical Service)
              └── supports → Business Service (optional, CSDM Walk)
                    └── part of → Business Capability
```

### CSDM Layer Mapping

| GetInSync Entity | CSDM Equivalent | ServiceNow Table | CSDM Stage |
|---|---|---|---|
| Business Capability | Business Capability | cmdb_ci_business_capability | Fly |
| Business Service | Business Service | cmdb_ci_service_business | Walk |
| Application | Business Application | cmdb_ci_business_app | Crawl |
| Deployment Profile | Application Service | cmdb_ci_service_auto | Crawl |
| IT Service | Technical Service | cmdb_ci_service_technical | Walk |

### Two-Track Usage Model

**Track 1: Portfolio Analysis (all customers)**

Applications → mapped to → Business Capabilities. Enables:

- Filter/group portfolio by business function
- Investment analysis: "How much do we spend on Finance applications?"
- Rationalization: "We have 12 apps supporting Procurement — consolidate?"
- Impact analysis: "Which capabilities are affected if we retire App X?"

No ServiceNow required. No Business Services required.

**Track 2: CSDM Service Model (ServiceNow customers)**

Business Services sit between Capabilities and Applications. Enables:

- Publish Business Services → cmdb_ci_service_business
- Populate the **Service** field on ServiceNow incident form
- Service-based incident routing and impact roll-up
- Service Portfolio Management (SPM) as defined in customer budgets

Requires Track 1 (capabilities) as the parent classification.

---

## Schema: Phase 1 — Business Capabilities (Build Now)

### Table: business_capabilities

Hierarchical reference taxonomy. Same architectural pattern as technology_product_categories, service_type_categories, and software_product_categories — namespace-scoped, seeded from template on namespace creation.

```sql
CREATE TABLE business_capabilities (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    parent_id uuid REFERENCES business_capabilities(id) ON DELETE CASCADE,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    level integer NOT NULL DEFAULT 1,
    tier text CHECK (tier IN ('strategic', 'core', 'supporting')),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT business_capabilities_namespace_code_key UNIQUE (namespace_id, code)
);

CREATE INDEX idx_business_capabilities_namespace 
    ON business_capabilities(namespace_id);
CREATE INDEX idx_business_capabilities_parent 
    ON business_capabilities(parent_id);

COMMENT ON TABLE business_capabilities IS 
    'Hierarchical business capability taxonomy. L1/L2 seeded from template. Customers customize.';
COMMENT ON COLUMN business_capabilities.tier IS 
    'BIZBOK stratification: strategic (direction), core (customer-facing), supporting (back-office)';
COMMENT ON COLUMN business_capabilities.level IS 
    'Hierarchy depth: 1=top-level domain, 2=sub-capability, 3+=customer-defined';
COMMENT ON COLUMN business_capabilities.code IS 
    'Stable identifier for seed matching (e.g., FIN, FIN.AP, FIN.AP.REC)';
```

### Table: business_capability_applications

Junction linking applications to capabilities. An application can support multiple capabilities. A capability can have multiple applications.

```sql
CREATE TABLE business_capability_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    business_capability_id uuid NOT NULL REFERENCES business_capabilities(id) ON DELETE CASCADE,
    application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    is_primary boolean DEFAULT false,
    notes text,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT business_capability_applications_unique 
        UNIQUE (business_capability_id, application_id)
);

CREATE INDEX idx_bca_capability ON business_capability_applications(business_capability_id);
CREATE INDEX idx_bca_application ON business_capability_applications(application_id);
CREATE INDEX idx_bca_namespace ON business_capability_applications(namespace_id);

COMMENT ON TABLE business_capability_applications IS 
    'Maps applications to business capabilities. An app can support multiple capabilities.';
COMMENT ON COLUMN business_capability_applications.is_primary IS 
    'TRUE if this is the primary business function the application serves';
```

### RLS Policies

Follow existing patterns (347 policies across 90 tables):

```sql
-- business_capabilities: namespace-scoped read, admin write
ALTER TABLE business_capabilities ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON business_capabilities TO authenticated;

CREATE POLICY "Users can view capabilities in current namespace"
    ON business_capabilities FOR SELECT
    USING (namespace_id = get_current_namespace_id());

CREATE POLICY "Admins can manage capabilities in current namespace"
    ON business_capabilities FOR ALL
    USING (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
        )
    );

-- business_capability_applications: namespace-scoped read, editor+ write
ALTER TABLE business_capability_applications ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON business_capability_applications TO authenticated;

CREATE POLICY "Users can view capability mappings in current namespace"
    ON business_capability_applications FOR SELECT
    USING (namespace_id = get_current_namespace_id());

CREATE POLICY "Editors can manage capability mappings in current namespace"
    ON business_capability_applications FOR INSERT
    WITH CHECK (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(get_current_namespace_id())
            OR EXISTS (
                SELECT 1 FROM workspace_users wu
                JOIN applications a ON a.workspace_id = wu.workspace_id
                WHERE a.id = business_capability_applications.application_id
                AND wu.user_id = auth.uid()
                AND wu.role IN ('admin', 'editor')
            )
        )
    );

-- DELETE and UPDATE policies follow same pattern as INSERT
```

### Audit Trigger

```sql
CREATE TRIGGER audit_business_capabilities
    AFTER INSERT OR UPDATE OR DELETE ON business_capabilities
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_business_capability_applications
    AFTER INSERT OR UPDATE OR DELETE ON business_capability_applications
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

### Seed Function

Same pattern as `copy_service_types_to_new_namespace()`:

```sql
CREATE OR REPLACE FUNCTION copy_business_capabilities_to_new_namespace()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM business_capabilities 
        WHERE namespace_id = v_template_namespace_id
    ) THEN
        RETURN NEW;
    END IF;

    -- Copy L1 capabilities (parent_id IS NULL)
    INSERT INTO business_capabilities (
        namespace_id, parent_id, code, name, description, 
        level, tier, display_order, is_active
    )
    SELECT
        NEW.id, NULL, code, name, description,
        level, tier, display_order, is_active
    FROM business_capabilities
    WHERE namespace_id = v_template_namespace_id
    AND parent_id IS NULL;

    -- Copy L2 capabilities, linking to new namespace's L1 parents
    INSERT INTO business_capabilities (
        namespace_id, parent_id, code, name, description,
        level, tier, display_order, is_active
    )
    SELECT
        NEW.id,
        new_parent.id,
        child.code,
        child.name,
        child.description,
        child.level,
        child.tier,
        child.display_order,
        child.is_active
    FROM business_capabilities child
    JOIN business_capabilities old_parent 
        ON old_parent.id = child.parent_id
    JOIN business_capabilities new_parent 
        ON new_parent.namespace_id = NEW.id 
        AND new_parent.code = old_parent.code
    WHERE child.namespace_id = v_template_namespace_id
    AND child.parent_id IS NOT NULL;

    RETURN NEW;
END;
$$;

CREATE TRIGGER seed_business_capabilities_on_namespace_create
    AFTER INSERT ON namespaces
    FOR EACH ROW
    EXECUTE FUNCTION copy_business_capabilities_to_new_namespace();
```

---

## Schema: Phase 2 — Business Services (Document Now, Build Later)

> **Status: Design only.** Deploy when ServiceNow integration (Phase 37) reaches Walk stage or when a customer explicitly requests Service Portfolio Management.

### Table: business_services

```sql
CREATE TABLE business_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    owner_workspace_id uuid NOT NULL REFERENCES workspaces(id),
    business_capability_id uuid REFERENCES business_capabilities(id),
    name text NOT NULL,
    description text,
    service_owner_id uuid REFERENCES individuals(id),
    is_customer_facing boolean DEFAULT false,
    lifecycle_state text DEFAULT 'active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE business_services IS 
    'Business-facing services. Maps to cmdb_ci_service_business in CSDM. Phase 2 — deploy when needed.';
COMMENT ON COLUMN business_services.business_capability_id IS
    'Links this service to the business capability it delivers. Optional.';
COMMENT ON COLUMN business_services.is_customer_facing IS 
    'TRUE = external/citizen-facing. FALSE = internal/employee-facing.';
```

### Table: business_service_applications

```sql
CREATE TABLE business_service_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    business_service_id uuid NOT NULL REFERENCES business_services(id) ON DELETE CASCADE,
    application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    is_primary boolean DEFAULT false,
    notes text,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT bsa_unique UNIQUE (business_service_id, application_id)
);

COMMENT ON TABLE business_service_applications IS 
    'Maps applications to business services they support. Phase 2 — deploy when needed.';
```

### Future: Service Offerings (Phase 3, Run Stage)

```sql
-- Design placeholder — not for immediate implementation
CREATE TABLE service_offerings (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    business_service_id uuid NOT NULL REFERENCES business_services(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);
```

Service Offerings are the sub-level that populates the **Service Offering** field on the ServiceNow incident form. "Disaster Assistance Claims Processing" (Business Service) might offer "Claims Submission" and "Appeal Processing" (Service Offerings). This is CSDM Run territory and should not be built until a customer has functioning Walk-stage integration.

---

## Seed Taxonomy: Generic L1/L2

Seeded into template namespace `00000000-0000-0000-0000-000000000001`. Copied to new namespaces automatically.

### Strategic Tier (Direction-Setting)

| Code | L1 Capability | L2 Capabilities |
|---|---|---|
| STR | Strategy & Planning | Strategic Planning, Performance Management, Risk Management, Innovation Management |
| POL | Policy & Governance | Policy Development, Regulatory Compliance, Standards Management, Ethics & Conduct |
| RES | Research & Analysis | Research Planning, Data Analysis, Market/Sector Analysis, Knowledge Management |

### Core Tier (Customer/Citizen-Facing)

| Code | L1 Capability | L2 Capabilities |
|---|---|---|
| CUS | Customer/Constituent Management | Customer Registration, Case Management, Communications, Feedback Management |
| PRD | Product & Service Delivery | Service Design, Service Delivery, Channel Management, Quality Assurance |
| SAL | Sales & Revenue | Revenue Collection, Billing, Accounts Receivable, Pricing |
| MKT | Marketing & Outreach | Campaign Management, Brand Management, Digital Marketing, Public Relations |
| PAR | Partner & Vendor Management | Partner Onboarding, Vendor Performance, Relationship Management |

### Supporting Tier (Back-Office)

| Code | L1 Capability | L2 Capabilities |
|---|---|---|
| FIN | Finance Management | Budget Management, Accounts Payable, Accounts Receivable, Financial Reporting, Treasury, General Ledger |
| HR | Human Resource Management | Recruitment, Employee Relations, Compensation & Benefits, Performance Management, Learning & Development, Workforce Planning |
| IT | Information Technology | Application Portfolio Management, Infrastructure Management, Service Management, Security Management, Data Management, Enterprise Architecture |
| PRO | Procurement | Sourcing, Contract Management, Purchase Orders, Supplier Performance |
| OPS | Operations Management | Facility Management, Fleet Management, Asset Management, Supply Chain, Quality Management |
| LEG | Legal & Compliance | Legal Matters, Contract Review, Litigation, Intellectual Property |
| COM | Communications | Internal Communications, External Communications, Media Relations, Crisis Communications |

**Total generic seed: 13 L1 capabilities, ~60 L2 capabilities.**

### Government Extension

Applied when namespace sector = 'government' (future namespace attribute) or manually via `seed_government_capabilities(namespace_id)`.

| Code | L1 Capability | L2 Capabilities |
|---|---|---|
| CON | Constituent Services | Citizen Registration, Benefits Administration, Case Management, Accessibility Services |
| PLS | Policy & Legislation | Legislative Drafting, Policy Impact Assessment, Regulatory Enforcement, Gazette Management |
| PUB | Public Safety | Emergency Response, Law Enforcement, Corrections, Disaster Management, Fire Services |
| HLT | Public Health | Health Program Delivery, Disease Surveillance, Health Inspection, Mental Health Services |
| EDU | Education | Curriculum Management, Student Services, Institutional Oversight, Credentialing |
| ENV | Environment & Resources | Environmental Protection, Resource Management, Land Management, Parks & Wildlife |
| INF | Infrastructure & Transport | Road Management, Transit Planning, Infrastructure Planning, Traffic Management |
| AGR | Agriculture | Crop Management, Agricultural Inspection, Food Safety, Rural Development |
| JUS | Justice & Courts | Court Administration, Case Filing, Sentencing, Alternative Dispute Resolution |
| REV | Revenue & Taxation | Tax Assessment, Tax Collection, Audit & Enforcement, Tax Policy |
| SOC | Social Services | Income Support, Child & Family Services, Housing Assistance, Disability Services |
| LIC | Licensing & Permits | License Issuance, Permit Management, Inspection & Enforcement, Renewal Processing |

**Total government extension: 12 L1 capabilities, ~48 L2 capabilities.**

### Source Attribution

The L1 taxonomy structure is informed by the Business Architecture Guild's Government Reference Model (Ottawa 2018 workshop, BIZBOK Guide v7.0). The specific L2 decompositions are GetInSync-original, simplified from BIZBOK patterns for practical APM use. The Guild's model uses "X Management" naming (e.g., "Customer Management"); GetInSync's seed uses plain language where possible (e.g., "Customer/Constituent Management") per the 18-year-old test.

---

## CSDM Publish Mapping

When GetInSync publishes to ServiceNow (Phase 37), business capabilities and services map as follows:

| GetInSync Source | ServiceNow Target | Publish Stage | Key Fields |
|---|---|---|---|
| business_capabilities | cmdb_ci_business_capability | Fly | name, description, parent (hierarchy) |
| business_services | cmdb_ci_service_business | Walk | name, description, service_owner, lifecycle |
| business_service_applications | cmdb_rel_ci | Walk | type="Consumes::Consumed by", parent=service, child=BA |
| business_capability_applications | cmdb_rel_ci | Fly | type=TBD, parent=capability, child=BA |

### Publish Sequence (Order Matters)

1. **business_capabilities** → cmdb_ci_business_capability (create reference data)
2. **applications** → cmdb_ci_business_app (create BAs)
3. **deployment_profiles** → cmdb_ci_service_auto (create Application Services)
4. **business_services** → cmdb_ci_service_business (create Business Services)
5. **it_services** → cmdb_ci_service_technical (create Technical Services)
6. **All junction tables** → cmdb_rel_ci (wire relationships)

---

## Impact Assessment

### What Changes

| Area | Impact |
|---|---|
| Schema | +2 tables (Phase 1), +2 tables (Phase 2, future) |
| RLS | +4 policies (Phase 1) |
| Audit triggers | +2 triggers (Phase 1) |
| Seed functions | +1 function, +1 trigger on namespaces |
| pgTAP | +8-10 assertions for new tables |
| Manifest | +1 document (this file) |

### What Does NOT Change

- All 90 existing tables — untouched
- All 347 existing RLS policies — untouched
- All 27 existing views — untouched
- IT Services table and its relationships — untouched
- Cost model — untouched
- Frontend — no UI changes in Phase 1
- Deployment profiles — untouched
- Assessment framework — untouched

---

## UI Considerations (Future — Not Phase 1)

When the UI is built, the capability mapping interaction should be:

1. **Application detail page** — new section or tab: "Business Function"
2. **Dropdown or typeahead** from business_capabilities filtered to current namespace
3. **Multi-select** — an application can map to multiple capabilities
4. **One marked primary** — is_primary flag
5. **Dashboard grouping** — existing dashboards gain a "Group by Business Function" option

The capability taxonomy admin (add/edit/reorder capabilities) follows the same pattern as the existing IT Service type categories admin.

---

## Typical Government Customer Adoption Path

Government IT Planning divisions commonly define three internal services during budget cycles:

| Typical IT Planning Service | GetInSync Equivalent |
|---|---|
| Application Portfolio Management | Application layer + TIME/PAID assessment |
| Technology Portfolio Management | Technology catalog + lifecycle management |
| Service Portfolio Management | Business Services layer (this document, Phase 2) |

In practice, most government organizations have APM partially functioning, TPM aspirational, and SPM unfunded. The capability-to-application mapping (Phase 1) delivers immediate value for their APM practice without requiring SPM infrastructure. When SPM matures, Business Services (Phase 2) is ready to deploy.

The practical CSDM adoption path for a pre-Crawl organization:

1. **Now:** GetInSync maps applications to business capabilities (portfolio analysis)
2. **Crawl:** GetInSync publishes BA + Application Service records to ServiceNow
3. **Walk:** GetInSync publishes Business Services, populating the incident form Service field
4. **Run:** Service Offerings added if needed
5. **Fly:** Business Capabilities published to cmdb_ci_business_capability

---

## Open Questions

1. **Namespace sector attribute.** The government seed extension needs a trigger. Options: explicit `sector` column on namespaces (enum: government, enterprise, nonprofit, education), or manual function call `seed_government_capabilities(namespace_id)`. Recommend the column — it's useful metadata beyond just seeding.

2. **Capability admin UI timing.** Phase 1 deploys tables with seed data. When does the admin UI ship? Likely Q2 alongside the Application detail page "Business Function" section.

3. **Service Offerings scope.** Documented here as Phase 3/Run but not designed in detail. Defer until a customer has functioning Walk-stage integration.

4. **Heatmap visualization.** Business capability maps are traditionally visualized as heatmaps (capability grid colored by investment, health, or app count). This is a high-value dashboard component but not in scope for Phase 1 schema work.

---

## Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-02-25 | Stuart Holtby / Claude Opus 4.6 | Initial architecture — business_capabilities (Phase 1) + business_services (Phase 2 design) |
