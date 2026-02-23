# features/technology-health/lifecycle-intelligence.md
GetInSync Technology Lifecycle Intelligence Architecture
Last updated: 2026-02-14

---

## 1. Purpose

Define the architecture for AI-powered technology lifecycle data collection, storage, and alerting within GetInSync NextGen.

**Goals:**
- Eliminate dependency on expensive third-party lifecycle data subscriptions (Flexera, Snow, ServiceNow ITAM)
- Auto-populate support status and end dates for Technology Products, IT Services, and Software Products
- Provide proactive alerts for upcoming end-of-support milestones
- Maintain the "QuickBooks for CSDM" simplicity -- users enter a platform name, we find the lifecycle data
- **v1.1:** Support both Path 1 (direct inventory tags) and Path 2 (IT Service structured) entry points

**Non-Goals:**
- Replace human judgment for T02 (Vendor Support Status) scoring
- Provide legal/contractual advice about support agreements
- Track custom/extended support contracts (user-managed exceptions)
- Build a risk register (see `features/technology-health/risk-boundary.md`)

---

## 2. Business Case

### 2.1 Current Market

| Provider | Annual Cost | What You Get |
|----------|-------------|--------------|
| Flexera | $20K-100K+ | Normalized lifecycle catalog, regular updates |
| Snow Software | $15K-50K+ | Similar catalog, license optimization bundle |
| ServiceNow ITAM | Platform cost | Lifecycle data bundled with full ITSM suite |
| Gartner/IDC | $10K-30K | Analyst reports, lifecycle research |

### 2.2 The Reality

90% of lifecycle data is **publicly available** on vendor websites:
- Microsoft: [Product Lifecycle Search](https://learn.microsoft.com/en-us/lifecycle/products/)
- Oracle: [Lifetime Support Policy](https://www.oracle.com/support/lifetime-support/)
- VMware: [Product Lifecycle Matrix](https://lifecycle.vmware.com/)
- Red Hat: [Product Life Cycle](https://access.redhat.com/product-life-cycles)
- Adobe: [Enterprise Product Support Periods](https://helpx.adobe.com/support/programs/eol-matrix.html)

**What you're paying for:** Aggregation, normalization, and regular updates.

### 2.3 AI Changes the Economics

| Traditional Approach | AI-Powered Approach |
|---------------------|---------------------|
| Human researchers maintain database | LLM extracts data from vendor pages |
| Brittle web scraping rules | Semantic understanding of page content |
| Months to add new vendors | Hours to add new vendors |
| $20K+/year subscription | Pennies per lookup |

---

## 3. Architecture Overview

```
+-------------------------------------------------------------------------+
|                     TECHNOLOGY LIFECYCLE INTELLIGENCE                    |
+-------------------------------------------------------------------------+
|                                                                         |
|  +-------------+     +-------------+     +---------------------+       |
|  |   Vendor    |     |  AI Skill   |     |  Reference Table    |       |
|  |  Websites   |---->|  (Extract)  |---->|  (Store)            |       |
|  +-------------+     +-------------+     +---------------------+       |
|                                                   |                     |
|                                    +--------------+--------------+      |
|                                    v              v              v      |
|                          +--------------+ +------------+ +----------+  |
|                          | Technology   | | IT Service | | Software |  |
|                          | Products     | | (Path 2)   | | Products |  |
|                          | (Path 1)     | |            | |          |  |
|                          +------+-------+ +-----+------+ +----------+  |
|                                 |               |                       |
|                                 v               v                       |
|                          +------------------------------+               |
|                          |   Deployment Profiles        |               |
|                          |   (via Path 1 direct tags    |               |
|                          |    OR Path 2 IT Services)    |               |
|                          +--------------+---------------+               |
|                                         |                               |
|                                         v                               |
|                          +------------------------------+               |
|                          |  Alerts, Dashboard, Risk     |               |
|                          |  Indicators, T02 Guidance    |               |
|                          +------------------------------+               |
|                                                                         |
+-------------------------------------------------------------------------+
```

### 3.1 Components

| Component | Description |
|-----------|-------------|
| **Vendor Registry** | List of known vendors with lifecycle page URLs |
| **AI Extraction Skill** | Claude-powered skill that fetches and parses lifecycle pages |
| **Reference Table** | Normalized lifecycle data (vendor + product + version --> dates) |
| **Technology Products** | Catalog entries linked to lifecycle reference (Path 1 entry point) |
| **IT Services** | Service entities linked to lifecycle reference (Path 2 entry point) |
| **Software Products** | Software catalog entries linked to lifecycle reference |
| **Auto-Population** | When technology is tagged on a DP, IT Service created, or Software Product created, lookup lifecycle |
| **Alert Engine** | Proactive notifications for EOL milestones |

### 3.2 Two-Path Model (v1.1)

Lifecycle data reaches deployment profiles through two parallel paths. See `features/technology-health/technology-stack-erd-addendum.md` for full ERD.

| Path | Chain | User Action | Maturity Level |
|------|-------|-------------|----------------|
| **Path 1: Inventory** | DP --> `deployment_profile_technology_products` --> `technology_products` --> `technology_lifecycle_reference` | 18-year-old tags "SQL Server 2016" on a DP | Level 1 -- anyone can do it |
| **Path 2: Cost and Blast Radius** | DP --> `deployment_profile_it_services` --> `it_services` --> `it_service_technology_products` --> `technology_products` --> `technology_lifecycle_reference` | Central IT creates IT Service, links technology, assigns cost | Level 3 -- organizational maturity required |

**Both paths converge on the same `technology_products` catalog and the same `technology_lifecycle_reference` table.** The lifecycle dates are shared -- whether you reach them through a direct DP tag or through an IT Service, the data is identical. The difference is context: Path 1 gives you lifecycle risk; Path 2 adds cost allocation and blast radius.

### 3.3 Why Path 1 Matters for Lifecycle Intelligence

The v1.0 architecture only connected lifecycle data through IT Services and Software Products. This created a barrier: organizations couldn't get lifecycle risk visibility until they had built out IT Service definitions -- an organizational maturity prerequisite that most GetInSync customers don't have on day one.

Path 1 removes that barrier. The moment a user tags "Windows Server 2019" on a deployment profile, the system can:
1. Match to the technology_products catalog
2. Follow the lifecycle_reference_id to technology_lifecycle_reference
3. Show "Extended Support ends Oct 2028" immediately
4. Surface this on the Technology Health Dashboard

No IT Service definition required. No organizational maturity required. Just inventory facts feeding lifecycle intelligence.

---

## 4. Data Model

### 4.1 Vendor Registry

Stores known vendors and their lifecycle information sources.

```sql
-- ============================================
-- VENDOR REGISTRY
-- ============================================

CREATE TABLE vendor_lifecycle_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Vendor identification
    vendor_name TEXT NOT NULL,                    -- "Microsoft", "Oracle", "VMware"
    vendor_aliases TEXT[],                        -- ["MS", "MSFT", "Microsoft Corporation"]
    
    -- Lifecycle data source
    lifecycle_url TEXT,                           -- Primary lifecycle page URL
    lifecycle_url_pattern TEXT,                   -- URL pattern for product-specific pages
    
    -- Extraction configuration
    extraction_strategy TEXT DEFAULT 'general',   -- 'microsoft', 'oracle', 'general'
    last_crawl_at TIMESTAMPTZ,
    crawl_frequency_days INTEGER DEFAULT 30,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Seed major vendors
INSERT INTO vendor_lifecycle_sources (vendor_name, vendor_aliases, lifecycle_url, extraction_strategy) VALUES
('Microsoft', ARRAY['MS', 'MSFT'], 'https://learn.microsoft.com/en-us/lifecycle/products/', 'microsoft'),
('Oracle', ARRAY['Oracle Corporation'], 'https://www.oracle.com/support/lifetime-support/', 'oracle'),
('VMware', ARRAY['VMware by Broadcom'], 'https://lifecycle.vmware.com/', 'vmware'),
('Red Hat', ARRAY['RedHat', 'RHEL'], 'https://access.redhat.com/product-life-cycles', 'redhat'),
('Adobe', ARRAY['Adobe Systems'], 'https://helpx.adobe.com/support/programs/eol-matrix.html', 'adobe'),
('SAP', ARRAY['SAP SE'], 'https://support.sap.com/en/release-upgrade-maintenance.html', 'sap'),
('Cisco', ARRAY['Cisco Systems'], 'https://www.cisco.com/c/en/us/products/eos-eol-listing.html', 'cisco'),
('IBM', ARRAY['International Business Machines'], 'https://www.ibm.com/support/pages/lifecycle/', 'ibm'),
('Salesforce', ARRAY['SFDC'], 'https://help.salesforce.com/s/articleView?id=000387644', 'salesforce'),
('AWS', ARRAY['Amazon Web Services'], 'https://aws.amazon.com/blogs/aws/', 'aws'),
('Google', ARRAY['Google Cloud', 'GCP'], 'https://cloud.google.com/products', 'google');
```

### 4.2 Technology Lifecycle Reference

The core reference table storing normalized lifecycle data.

```sql
-- ============================================
-- TECHNOLOGY LIFECYCLE REFERENCE
-- ============================================

CREATE TABLE technology_lifecycle_reference (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Product identification
    vendor_name TEXT NOT NULL,                    -- Normalized vendor name
    product_name TEXT NOT NULL,                   -- "SQL Server", "Windows Server", "Oracle Database"
    product_family TEXT,                          -- "Database", "Operating System", "Middleware"
    version TEXT NOT NULL,                        -- "2019", "2022", "19c"
    edition TEXT,                                 -- "Standard", "Enterprise", "Express"
    
    -- Lifecycle dates
    ga_date DATE,                                 -- General Availability
    mainstream_support_end DATE,                  -- End of mainstream/premier support
    extended_support_end DATE,                    -- End of extended support
    end_of_life_date DATE,                        -- Complete EOL (no patches)
    
    -- Current status (derived from dates, cached for queries)
    current_status TEXT GENERATED ALWAYS AS (
        CASE
            WHEN end_of_life_date IS NOT NULL AND end_of_life_date < CURRENT_DATE THEN 'end_of_life'
            WHEN extended_support_end IS NOT NULL AND extended_support_end < CURRENT_DATE THEN 'end_of_support'
            WHEN mainstream_support_end IS NOT NULL AND mainstream_support_end < CURRENT_DATE THEN 'extended'
            WHEN ga_date IS NOT NULL AND ga_date <= CURRENT_DATE THEN 'mainstream'
            WHEN ga_date IS NOT NULL AND ga_date > CURRENT_DATE THEN 'preview'
            ELSE 'unknown'
        END
    ) STORED,
    
    -- Data quality
    confidence_level TEXT DEFAULT 'medium',       -- 'high', 'medium', 'low', 'unverified'
    source_url TEXT,                              -- Where we found this data
    last_verified_at TIMESTAMPTZ,
    verification_notes TEXT,
    
    -- Manual override tracking
    is_manually_overridden BOOLEAN DEFAULT false,
    override_reason TEXT,
    overridden_by UUID REFERENCES auth.users(id),
    overridden_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    CONSTRAINT tlr_unique_product UNIQUE (vendor_name, product_name, version, edition),
    CONSTRAINT tlr_confidence_check CHECK (confidence_level IN ('high', 'medium', 'low', 'unverified')),
    CONSTRAINT tlr_status_check CHECK (current_status IN ('preview', 'mainstream', 'extended', 'end_of_support', 'end_of_life', 'unknown'))
);

-- Indexes for common queries
CREATE INDEX idx_tlr_vendor ON technology_lifecycle_reference(vendor_name);
CREATE INDEX idx_tlr_product ON technology_lifecycle_reference(product_name);
CREATE INDEX idx_tlr_status ON technology_lifecycle_reference(current_status);
CREATE INDEX idx_tlr_eol_date ON technology_lifecycle_reference(end_of_life_date);
CREATE INDEX idx_tlr_extended_end ON technology_lifecycle_reference(extended_support_end);

-- Full-text search for fuzzy matching
CREATE INDEX idx_tlr_search ON technology_lifecycle_reference 
USING gin(to_tsvector('english', vendor_name || ' ' || product_name || ' ' || COALESCE(version, '')));
```

### 4.3 Lifecycle Status Enum

For reference, the lifecycle status progression:

```
preview --> mainstream --> extended --> end_of_support --> end_of_life
   |           |            |              |              |
   |           |            |              |              +-- No patches, no support
   |           |            |              +-- Security patches only (often paid)
   |           |            +-- Limited support, security focus
   |           +-- Full support, new features
   +-- Pre-release, not for production
```

### 4.4 IT Service Integration (Path 2)

Extend `it_services` to link to lifecycle reference.

```sql
-- Add lifecycle reference link to it_services
ALTER TABLE it_services
ADD COLUMN lifecycle_reference_id UUID REFERENCES technology_lifecycle_reference(id) ON DELETE SET NULL;

-- Add computed lifecycle fields (for quick access without join)
ALTER TABLE it_services
ADD COLUMN lifecycle_status TEXT,                 -- Cached from reference
ADD COLUMN lifecycle_status_updated_at TIMESTAMPTZ;

-- Index for lifecycle queries
CREATE INDEX idx_it_services_lifecycle ON it_services(lifecycle_reference_id);
CREATE INDEX idx_it_services_lifecycle_status ON it_services(lifecycle_status);
```

### 4.5 Software Product Integration

Extend `software_products` to link to lifecycle reference.

```sql
-- Add lifecycle reference link to software_products
ALTER TABLE software_products
ADD COLUMN lifecycle_reference_id UUID REFERENCES technology_lifecycle_reference(id) ON DELETE SET NULL;

-- Add computed lifecycle fields
ALTER TABLE software_products
ADD COLUMN lifecycle_status TEXT,
ADD COLUMN lifecycle_status_updated_at TIMESTAMPTZ;

-- Index for lifecycle queries
CREATE INDEX idx_software_products_lifecycle ON software_products(lifecycle_reference_id);
```

### 4.6 Technology Product Integration (Path 1 -- NEW in v1.1)

Extend `technology_products` to link to lifecycle reference. This is the **primary entry point** for most users -- when they tag a technology product on a deployment profile, the lifecycle data becomes immediately available.

```sql
-- Add lifecycle reference link to technology_products
ALTER TABLE technology_products
ADD COLUMN lifecycle_reference_id UUID REFERENCES technology_lifecycle_reference(id) ON DELETE SET NULL;

-- Index for lifecycle queries
CREATE INDEX idx_technology_products_lifecycle ON technology_products(lifecycle_reference_id);
```

**Design note:** Unlike IT Services and Software Products, Technology Products do NOT get cached `lifecycle_status` and `lifecycle_status_updated_at` columns. The `technology_lifecycle_reference.current_status` is a GENERATED ALWAYS column that auto-computes from dates, so caching is unnecessary -- the reference table is always current. IT Services and Software Products have cached columns for historical reasons; these should be deprecated in favor of always joining to the reference table.

### 4.7 How Path 1 Tags Reach Lifecycle Data

The complete chain for a Path 1 inventory tag:

```sql
-- Example: Find lifecycle status for all technology tagged on a deployment profile
SELECT 
    dp.name AS deployment_name,
    tp.name AS technology_name,
    dptp.deployed_version,
    tlr.current_status,
    tlr.mainstream_support_end,
    tlr.extended_support_end,
    tlr.end_of_life_date
FROM deployment_profiles dp
JOIN deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp.id
JOIN technology_products tp ON tp.id = dptp.technology_product_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
WHERE dp.id = '<dp-uuid>';
```

**Important:** The `deployed_version` on the junction table may differ from the version in the technology_products catalog. Example: catalog has "SQL Server 2019" but the DP is running a specific CU (Cumulative Update). The lifecycle reference links at the product level, not the patch level -- lifecycle dates apply to the major version regardless of CU.

---

## 5. AI Extraction Skill

### 5.1 Skill Overview

The lifecycle extraction skill uses Claude to:
1. Fetch vendor lifecycle pages
2. Extract structured data using semantic understanding
3. Normalize to reference table schema
4. Handle edge cases (renamed products, complex edition matrices)

### 5.2 Skill Interface

```typescript
interface LifecycleLookupRequest {
  vendor: string;           // "Microsoft", "Oracle"
  product: string;          // "SQL Server", "Oracle Database"
  version?: string;         // "2019", "19c" (optional for discovery)
  edition?: string;         // "Enterprise", "Standard"
}

interface LifecycleLookupResponse {
  found: boolean;
  confidence: 'high' | 'medium' | 'low';
  data?: {
    vendor_name: string;
    product_name: string;
    version: string;
    edition?: string;
    ga_date?: string;
    mainstream_support_end?: string;
    extended_support_end?: string;
    end_of_life_date?: string;
    current_status: string;
    source_url: string;
  };
  alternatives?: LifecycleLookupResponse[];  // Similar products found
  extraction_notes?: string;
}
```

### 5.3 Extraction Strategy

**General Pattern:**

```
1. Identify vendor from registry (fuzzy match vendor_name + aliases)
2. Fetch lifecycle_url for vendor
3. Search page for product/version
4. If not found, try lifecycle_url_pattern with product name
5. Extract dates using LLM with structured output
6. Normalize status based on date logic
7. Return structured result with confidence score
```

**Vendor-Specific Strategies:**

| Vendor | Strategy | Notes |
|--------|----------|-------|
| Microsoft | API-first | Microsoft has a lifecycle API, use when available |
| Oracle | Table parsing | Lifecycle data in HTML tables |
| VMware | Matrix parsing | Product/version matrix format |
| Red Hat | Structured page | Well-organized lifecycle pages |
| General | LLM extraction | For vendors without structured data |

### 5.4 Skill Implementation Sketch

```python
# Pseudo-code for lifecycle extraction skill

async def lookup_lifecycle(request: LifecycleLookupRequest) -> LifecycleLookupResponse:
    # Step 1: Find vendor in registry
    vendor = await find_vendor(request.vendor)
    if not vendor:
        return LifecycleLookupResponse(found=False, confidence='low',
            extraction_notes=f"Vendor '{request.vendor}' not in registry")
    
    # Step 2: Fetch lifecycle page
    page_content = await fetch_page(vendor.lifecycle_url)
    
    # Step 3: Use Claude to extract lifecycle data
    extraction_prompt = f"""
    Extract technology lifecycle information from this vendor page.
    
    Looking for:
    - Vendor: {vendor.vendor_name}
    - Product: {request.product}
    - Version: {request.version or 'any'}
    - Edition: {request.edition or 'any'}
    
    Page content:
    {page_content}
    
    Return JSON with:
    - product_name: Exact product name as shown
    - version: Version number
    - edition: Edition if applicable
    - ga_date: General availability date (YYYY-MM-DD)
    - mainstream_support_end: End of mainstream support (YYYY-MM-DD)
    - extended_support_end: End of extended support (YYYY-MM-DD)
    - end_of_life_date: Complete end of life (YYYY-MM-DD)
    - confidence: 'high' if exact match, 'medium' if inferred, 'low' if uncertain
    - notes: Any important caveats
    
    If product not found, return {{"found": false, "suggestions": [...]}}
    """
    
    result = await claude.extract(extraction_prompt, response_format="json")
    
    # Step 4: Normalize and validate
    if result.found:
        return LifecycleLookupResponse(
            found=True,
            confidence=result.confidence,
            data=normalize_lifecycle_data(result, vendor),
            source_url=vendor.lifecycle_url
        )
    else:
        return LifecycleLookupResponse(
            found=False,
            confidence='low',
            alternatives=result.suggestions,
            extraction_notes="Product not found on lifecycle page"
        )
```

### 5.5 Confidence Scoring

| Confidence | Criteria |
|------------|----------|
| **High** | Exact product/version match, dates clearly stated, official vendor page |
| **Medium** | Fuzzy match on product name, dates inferred from related versions |
| **Low** | No direct match, dates estimated from patterns |
| **Unverified** | Manual entry, not validated against vendor source |

---

## 6. Integration Points

### 6.1 Technology Product Tagging Flow (Path 1 -- NEW in v1.1)

This is the **most common entry point** for lifecycle intelligence. When a user tags a technology product on a deployment profile, the system checks for lifecycle data.

```
User tags technology on DP edit screen:
  Selects "SQL Server 2016" from technology catalog
           |
           v
+------------------------------------------+
| Lifecycle Lookup Triggered               |
|                                          |
| 1. Check technology_products for         |
|    lifecycle_reference_id                |
| 2. If linked: show lifecycle badge       |
|    inline on the tag                     |
|    "SQL Server 2016 [EXTENDED]           |
|     Extended support ends Jul 2026"      |
| 3. If NOT linked: search reference table |
|    for match by vendor+product+version   |
| 4. If found in reference: auto-link      |
|    technology_products.lifecycle_ref_id  |
| 5. If NOT in reference: offer AI lookup  |
|    "Look up lifecycle data for           |
|     SQL Server 2016?"                    |
| 6. If AI finds data: save to reference,  |
|    link to technology product            |
+------------------------------------------+
           |
           v
DP tag shows lifecycle badge:
  "SQL Server 2016" [EXTENDED - EOL Jul 2026]
```

**Key UX principle:** Lifecycle data should appear **inline on the technology tag** without any extra clicks. The user sees "SQL Server 2016 [EXTENDED]" the moment they tag it. Clicking the badge shows the full dates.

### 6.2 IT Service Creation Flow (Path 2)

```
User creates IT Service:
  platform_name: "SQL Server"
  platform_version: "2019"
           |
           v
+------------------------------------------+
| Lifecycle Lookup Triggered               |
|                                          |
| 1. Search reference table for match      |
| 2. If not found, invoke AI skill         |
| 3. Present results to user:              |
|    "SQL Server 2019 mainstream support   |
|     ends Jan 2025, extended Jan 2030.    |
|     Apply this lifecycle data?"          |
| 4. If confirmed, save to reference +     |
|    link to IT Service                    |
+------------------------------------------+
           |
           v
IT Service saved with:
  lifecycle_reference_id: [uuid]
  lifecycle_status: "mainstream"
  support_end_date: "2030-01-08"
```

### 6.3 Bulk Refresh Flow

```
Scheduled job (monthly):
           |
           v
+------------------------------------------+
| For each vendor in registry:             |
|                                          |
| 1. Fetch current lifecycle page          |
| 2. Compare to stored reference data      |
| 3. Flag any changes (new dates, etc.)    |
| 4. Queue changes for review OR           |
|    auto-apply if confidence = high       |
+------------------------------------------+
           |
           v
Generate change report:
  "3 products have updated lifecycle dates"
  "2 new products detected"
```

### 6.4 Assessment Integration

T02 (Vendor Support Status) assessment guidance. **Updated in v1.1** to show both Path 1 direct tags and Path 2 IT Service dependencies.

```
Assessor opens DP assessment:
           |
           v
+------------------------------------------+
| System shows technology lifecycle from   |
| BOTH paths:                              |
|                                          |
| Path 1 - Direct Technology Tags:         |
| +-- SQL Server 2016 [EXTENDED]           |
| |   +-- Extended support until Jul 2026  |
| +-- Windows Server 2019 [MAINSTREAM]     |
|     +-- Extended support until Jan 2029  |
|                                          |
| Path 2 - IT Service Dependencies:        |
| +-- Database Hosting (shared service)    |
| |   +-- Oracle 11g [END OF SUPPORT]      |
| |       +-- Expired 2021                 |
| +-- Server Hosting (shared service)      |
|     +-- Windows Server 2022 [MAINSTREAM] |
|         +-- Extended support until 2031  |
|                                          |
| Worst lifecycle status: END OF SUPPORT   |
| Suggested T02 score: 2 (due to Oracle)   |
+------------------------------------------+
```

**Important:** Lifecycle data **informs** T02 scoring but does not **override** assessor judgment. An assessor may score T02 higher if:
- Custom extended support contract exists
- System is air-gapped (reduced risk)
- Migration is already planned

**T02 score suggestion logic:** Takes the WORST lifecycle status across all technology linked to the DP (both paths combined):

| Worst Lifecycle Status | Suggested T02 Score | Rationale |
|---|---|---|
| end_of_life | 1 (Critical) | No patches, no support whatsoever |
| end_of_support | 2 (Poor) | Security patches may exist but no guarantees |
| extended | 3 (Adequate) | Limited support, should plan upgrade |
| mainstream | 4-5 (Good/Excellent) | Full support, no action needed |
| unknown | 3 (Adequate) | Unknown = assume moderate risk |

---

## 7. Alert Engine

### 7.1 Alert Types

| Alert Type | Trigger | Audience |
|------------|---------|----------|
| **EOL Imminent** | Technology reaches end_of_support within 12 months | Technology owners, Namespace admins |
| **EOL Reached** | Technology passes end_of_support date | Technology owners, Namespace admins |
| **Mainstream Ending** | Mainstream support ending within 6 months | Technology owners |
| **New Version Available** | Newer version detected in lifecycle data | Technology owners |

**v1.1 note:** Alert audience expanded from "IT Service owners" to "Technology owners" -- alerts now trigger for both Path 1 direct tags and Path 2 IT Service links. Any DP with a technology tag approaching EOL generates an alert, regardless of whether an IT Service is involved.

### 7.2 Alert Configuration

```sql
-- ============================================
-- LIFECYCLE ALERTS CONFIGURATION
-- ============================================

CREATE TABLE lifecycle_alert_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    
    -- Alert thresholds (months before event)
    eol_warning_months INTEGER DEFAULT 12,
    eol_critical_months INTEGER DEFAULT 6,
    mainstream_warning_months INTEGER DEFAULT 6,
    
    -- Notification preferences
    notify_workspace_admins BOOLEAN DEFAULT true,
    notify_service_owners BOOLEAN DEFAULT true,
    notify_namespace_admins BOOLEAN DEFAULT false,
    
    -- Email digest settings
    send_weekly_digest BOOLEAN DEFAULT true,
    digest_day_of_week INTEGER DEFAULT 1,        -- Monday
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    CONSTRAINT las_namespace_unique UNIQUE (namespace_id)
);
```

### 7.3 Alert Dashboard Widget

```
+----------------------------------------------------------+
| [!] Technology Lifecycle Alerts                    [gear] |
+----------------------------------------------------------+
|                                                          |
| CRITICAL (End of Support)                                |
| +-- Oracle 11g Cluster         EOL: 2021-12-31  [red]   |
| |   +-- 12 DPs affected (4 via direct tag, 8 via svc)   |
| +-- Windows Server 2012 R2     EOL: 2023-10-10  [red]   |
|     +-- 8 DPs affected (8 via direct tag)                |
|                                                          |
| WARNING (Support Ending Soon)                            |
| +-- SQL Server 2016            Extended: 2026-07-14 [y]  |
| |   +-- 5 DPs affected (6 months remaining)              |
| +-- Adobe ColdFusion 2018      Extended: 2026-07-01 [y]  |
|     +-- 2 DPs affected (5 months remaining)              |
|                                                          |
| HEALTHY                                                  |
| +-- 47 technology products on supported platforms  [grn] |
|                                                          |
| [View Full Report]  [Configure Alerts]                   |
+----------------------------------------------------------+
```

**v1.1 change:** DP affected counts now include both Path 1 (direct tag) and Path 2 (via IT Service) sources. The detail view can show the breakdown.

### 7.4 Lifecycle Risk Views

**v1.1: Two views, one per path, plus a unified view.**

#### Path 2 View (original from v1.0):

```sql
-- View: IT Services with lifecycle risk
CREATE VIEW vw_it_service_lifecycle_risk AS
SELECT 
    its.id,
    its.name AS service_name,
    its.owner_workspace_id,
    w.name AS workspace_name,
    tlr.vendor_name,
    tlr.product_name,
    tlr.version,
    tlr.current_status,
    tlr.mainstream_support_end,
    tlr.extended_support_end,
    tlr.end_of_life_date,
    
    CASE 
        WHEN tlr.extended_support_end IS NOT NULL 
        THEN tlr.extended_support_end - CURRENT_DATE
        ELSE NULL
    END AS days_until_eol,
    
    CASE
        WHEN tlr.current_status IN ('end_of_support', 'end_of_life') THEN 'critical'
        WHEN tlr.extended_support_end IS NOT NULL 
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '6 months' THEN 'high'
        WHEN tlr.extended_support_end IS NOT NULL 
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'medium'
        ELSE 'low'
    END AS lifecycle_risk,
    
    (SELECT COUNT(*) FROM deployment_profile_it_services dpis 
     WHERE dpis.it_service_id = its.id) AS dependent_dp_count

FROM it_services its
LEFT JOIN technology_lifecycle_reference tlr ON its.lifecycle_reference_id = tlr.id
LEFT JOIN workspaces w ON its.owner_workspace_id = w.id
WHERE its.lifecycle_reference_id IS NOT NULL;
```

#### Path 1 View (NEW in v1.1):

```sql
-- View: Technology products tagged on DPs with lifecycle risk
CREATE VIEW vw_technology_tag_lifecycle_risk AS
SELECT 
    tp.id AS technology_product_id,
    tp.name AS technology_name,
    tp.category,
    tp.product_family,
    tlr.vendor_name,
    tlr.version,
    tlr.current_status,
    tlr.mainstream_support_end,
    tlr.extended_support_end,
    tlr.end_of_life_date,
    
    CASE 
        WHEN tlr.extended_support_end IS NOT NULL 
        THEN tlr.extended_support_end - CURRENT_DATE
        ELSE NULL
    END AS days_until_eol,
    
    CASE
        WHEN tlr.current_status IN ('end_of_support', 'end_of_life') THEN 'critical'
        WHEN tlr.extended_support_end IS NOT NULL 
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '6 months' THEN 'high'
        WHEN tlr.extended_support_end IS NOT NULL 
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'medium'
        WHEN tlr.current_status = 'unknown' THEN 'unknown'
        ELSE 'low'
    END AS lifecycle_risk,
    
    COUNT(DISTINCT dptp.deployment_profile_id) AS tagged_dp_count,
    COUNT(DISTINCT dp.application_id) AS affected_application_count,
    COUNT(DISTINCT dp.workspace_id) AS affected_workspace_count

FROM technology_products tp
JOIN deployment_profile_technology_products dptp ON dptp.technology_product_id = tp.id
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
GROUP BY tp.id, tp.name, tp.category, tp.product_family,
         tlr.vendor_name, tlr.version, tlr.current_status,
         tlr.mainstream_support_end, tlr.extended_support_end, tlr.end_of_life_date;
```

#### Unified View (NEW in v1.1):

```sql
-- View: Combined lifecycle risk across both paths
-- Answers: "For a given DP, what is the worst lifecycle risk from ANY source?"
CREATE VIEW vw_dp_lifecycle_risk_combined AS
WITH path1_risk AS (
    -- Direct technology tags on DPs
    SELECT 
        dptp.deployment_profile_id,
        'direct_tag' AS source_type,
        tp.name AS technology_name,
        tlr.current_status,
        tlr.extended_support_end,
        tlr.end_of_life_date
    FROM deployment_profile_technology_products dptp
    JOIN technology_products tp ON tp.id = dptp.technology_product_id
    LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
    WHERE tp.lifecycle_reference_id IS NOT NULL
),
path2_risk AS (
    -- Technology via IT Services
    SELECT 
        dpis.deployment_profile_id,
        'it_service' AS source_type,
        tp.name AS technology_name,
        tlr.current_status,
        tlr.extended_support_end,
        tlr.end_of_life_date
    FROM deployment_profile_it_services dpis
    JOIN it_service_technology_products istp ON istp.it_service_id = dpis.it_service_id
    JOIN technology_products tp ON tp.id = istp.technology_product_id
    LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
    WHERE tp.lifecycle_reference_id IS NOT NULL
),
all_risk AS (
    SELECT * FROM path1_risk
    UNION ALL
    SELECT * FROM path2_risk
)
SELECT 
    dp.id AS deployment_profile_id,
    dp.name AS deployment_name,
    a.name AS application_name,
    dp.workspace_id,
    -- Worst status across all linked technology
    MIN(CASE ar.current_status
        WHEN 'end_of_life' THEN 1
        WHEN 'end_of_support' THEN 2
        WHEN 'extended' THEN 3
        WHEN 'mainstream' THEN 4
        WHEN 'preview' THEN 5
        ELSE 6
    END) AS worst_status_rank,
    -- Count by source
    COUNT(DISTINCT CASE WHEN ar.source_type = 'direct_tag' THEN ar.technology_name END) AS direct_tag_count,
    COUNT(DISTINCT CASE WHEN ar.source_type = 'it_service' THEN ar.technology_name END) AS it_service_count,
    -- Earliest EOL date
    MIN(ar.extended_support_end) AS earliest_eol
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
LEFT JOIN all_risk ar ON ar.deployment_profile_id = dp.id
GROUP BY dp.id, dp.name, a.name, dp.workspace_id;
```

---

## 8. Tier Availability

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| Manual lifecycle entry | Yes | Yes | Yes |
| View lifecycle status on technology tags (Path 1) | Yes | Yes | Yes |
| View lifecycle status on IT Services (Path 2) | Yes | Yes | Yes |
| On-demand AI lookup | No | Yes | Yes |
| Auto-populate on technology tagging (Path 1) | No | Yes | Yes |
| Auto-populate on IT Service creation (Path 2) | No | Yes | Yes |
| Lifecycle alerts (dashboard) | No | Yes | Yes |
| Email alert digests | No | No | Yes |
| Bulk refresh / scheduled crawl | No | No | Yes |
| Custom vendor registry | No | No | Yes |

**v1.1 change:** Added Path 1 technology tagging auto-populate (Pro+) and lifecycle badge display (all tiers). Free tier users can see lifecycle status if data exists in the catalog but cannot trigger AI lookups to populate missing data.

---

## 9. Implementation Phases

### Phase 27a: Reference Table Schema (2 hrs)
- Create `vendor_lifecycle_sources` table
- Create `technology_lifecycle_reference` table
- Add FK columns to `it_services` and `software_products`
- **v1.1:** Add FK column to `technology_products` (lifecycle_reference_id)
- Seed major vendors

### Phase 27b: Manual Lifecycle Entry UI (3 hrs)
- Add lifecycle fields to IT Service edit modal
- Add lifecycle fields to Software Product edit modal
- **v1.1:** Add lifecycle fields to Technology Product catalog admin
- Display lifecycle status badges throughout UI
- **v1.1:** Show lifecycle badge inline on DP technology tags

### Phase 27c: AI Lookup Skill (4 hrs)
- Implement extraction skill using Claude
- Vendor-specific strategies for major vendors
- Confidence scoring logic
- Reference table upsert

### Phase 27d: Auto-Population Flow (3 hrs -- was 2 hrs, expanded for Path 1)
- Trigger lookup on IT Service creation (Path 2)
- **v1.1:** Trigger lookup on technology product tagging on DP (Path 1)
- **v1.1:** Trigger lookup on technology product catalog entry creation
- User confirmation dialog
- Save to reference table on confirm

### Phase 27e: Dashboard Widget (3 hrs -- was 2 hrs, expanded for combined view)
- Lifecycle risk summary widget
- EOL alerts list
- **v1.1:** Combined view showing both Path 1 and Path 2 sources
- Link to affected DPs

### Phase 27f: Alert Configuration (2 hrs)
- Namespace-level alert settings
- Alert threshold configuration
- Weekly digest job (Enterprise)

### Phase 27g: Lifecycle Risk Views (NEW in v1.1, 2 hrs)
- Create `vw_technology_tag_lifecycle_risk` (Path 1)
- Create `vw_dp_lifecycle_risk_combined` (unified)
- Verify existing `vw_it_service_lifecycle_risk` (Path 2)

**Total Estimate:** ~17 hours (was ~15 hours in v1.0)

---

## 10. Security Considerations

### 10.1 Data Source Trust

- Only fetch from known vendor URLs in registry
- Validate URLs before fetching (no arbitrary URL execution)
- Rate limit requests to vendor sites
- Cache aggressively to minimize external calls

### 10.2 Data Quality

- All AI-extracted data marked with confidence level
- Human review queue for low-confidence extractions
- Manual override capability with audit trail
- Regular verification against source URLs

### 10.3 Multi-Tenant Isolation

- Reference table is **namespace-scoped** OR **global shared**
- Decision: Start with global shared (vendor lifecycle is universal)
- Manual overrides are namespace-scoped (custom support contracts)
- **v1.1 note:** Technology products are namespace-scoped, so the lifecycle_reference_id FK on technology_products inherits the namespace boundary. The shared reference table means two namespaces with "SQL Server 2019" both link to the same lifecycle dates.

---

## 11. Open Questions

1. **Global vs Namespace-Scoped Reference:** Should lifecycle data be shared across all namespaces or namespace-scoped? Recommendation: Global for vendor data, namespace override table for custom contracts.

2. **API vs Skill:** Should lifecycle lookup be an API endpoint or a Claude skill? Recommendation: Start as skill, promote to API if performance requires.

3. **Vendor Coverage:** How many vendors to seed initially? Recommendation: Top 20 enterprise vendors, add more based on customer demand.

4. **Stale Data Handling:** What happens if vendor page changes format? Recommendation: Extraction failures trigger manual review queue.

5. **(v1.1) Deployed Version vs Catalog Version:** When `deployment_profile_technology_products.deployed_version` differs from the catalog version (e.g., specific CU or patch), should lifecycle lookup use the catalog version or attempt to match the deployed version? Recommendation: Lifecycle dates apply at major version level; deployed_version is informational only.

6. **(v1.1) Duplicate Technology Across Paths:** When a technology product appears both as a direct DP tag (Path 1) and through an IT Service (Path 2), should alerts deduplicate? Recommendation: Yes -- the unified view (`vw_dp_lifecycle_risk_combined`) handles this, but alert generation should also deduplicate to avoid sending two alerts for the same technology on the same DP.

---

## 12. Success Metrics

| Metric | Target |
|--------|--------|
| % of technology products with lifecycle data | >80% within 6 months |
| % of DPs with at least one lifecycle-linked technology tag | >60% within 6 months |
| Average lookup latency | <5 seconds |
| Extraction accuracy (high confidence) | >90% |
| Customer cost savings vs Flexera | >$15K/year |

**v1.1 change:** Added DP coverage metric. Previous metric only measured IT Services; Path 1 tags are expected to be the more common entry point, so DP-level coverage is the better indicator.

---

## 13. References

- `core/time-paid-methodology.md` -- T02 scoring context
- `catalogs/it-service.md` -- IT Service catalog
- `catalogs/software-product.md` -- Software Product catalog
- `features/cost-budget/budget-alerts.md` -- Alert engine pattern
- `features/technology-health/technology-stack-erd-addendum.md` -- Two-path model (Path 1 inventory vs Path 2 cost)
- `features/technology-health/dashboard.md` -- Dashboard that consumes lifecycle data
- `features/technology-health/risk-boundary.md` -- Risk detection boundary (computed indicators, not risk register)
- `features/technology-health/infrastructure-boundary-rubric.md` -- What infrastructure data enters the system (feeds Path 1)
- `catalogs/technology-catalog.md` -- Technology product catalog structure

---

## 14. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-28 | Initial document |
| v1.1 | 2026-02-14 | Two-path model integration. Added: Path 1 technology product entry point (S4.6), technology tagging flow (S6.1), Path 1 lifecycle risk view (S7.4), unified combined risk view (S7.4), updated architecture diagram, assessment integration shows both paths, alert engine covers both paths, implementation phases updated (+2 hrs), new open questions for deployed version and deduplication, T02 suggestion scoring table. References expanded with 5 new companion docs. |
