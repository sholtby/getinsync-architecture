# GetInSync ITSM API Integration Research
## ServiceNow & HaloITSM — Publish/Subscribe Architecture
**Version:** 1.1  
**Date:** 2026-02-20  
**Author:** Stuart Holtby / Claude  
**Status:** Research / Discovery  
**Changes (v1.1):** Corrected Phase 37b publish sequence (7-step), added Subscribe-first IT Service matching (Sections 8.2-8.4), updated effort estimates.

---

## 1. Executive Summary

This document captures API research for connecting GetInSync NextGen to **ServiceNow** and **HaloITSM** as downstream ITSM targets. The goal is to **publish** GetInSync objects (applications, deployment profiles, software products, IT services, contracts) to these platforms, and **subscribe** to their data (CI discovery, infrastructure baselines) to keep GetInSync current.

GetInSync already has a comprehensive CSDM 5.0 alignment architecture (features/integrations/servicenow-alignment.md) and field-level mapping (catalogs/csdm-application-attributes.md). This research focuses on the **transport layer** — the actual API mechanics for both platforms.

---

## 2. GetInSync Objects to Sync

Based on existing architecture docs, here are the primary objects and their sync directions:

| GetInSync Entity | Sync Direction | ServiceNow Target | HaloITSM Target |
|------------------|---------------|-------------------|-----------------|
| BusinessApplication | **Publish** (push) | `cmdb_ci_business_app` | `/api/Asset` (as Application asset type) |
| DeploymentProfile | **Publish** (push) | `cmdb_ci_service_auto` / `cmdb_ci_service_technical` / `service_offering` | `/api/Asset` (linked to parent) |
| SoftwareProduct | **Publish** (push) | `alm_product_model` | `/api/Asset` (Software type) |
| ITService (shared) | **Publish** (push) | `service_offering` (TSO) | `/api/Service` |
| ITService (local) | **Publish** (push) | `cmdb_ci_service_technical` | `/api/Service` |
| ProductContract (vendor only) | **Publish** (push) | `ast_contract` | `/api/Supplier` + `/api/Contract` |
| Infrastructure CIs | **Subscribe** (pull) | `cmdb_ci_server`, `cmdb_ci_computer` | `/api/Asset` (discovered devices) |
| Users / Contacts | **Bi-directional** | `sys_user` | `/api/Users` |

**Key rule from existing architecture:** Internal chargeback contracts (Ministry → Central IT) must **never** sync to ServiceNow's `ast_contract` table.

---

## 3. ServiceNow REST API

### 3.1 API Landscape

ServiceNow offers multiple API approaches for CMDB integration:

**Table API** (simplest, most common for APM data):
- Base URL: `https://{instance}.service-now.com/api/now/table/{tableName}`
- Standard CRUD via GET, POST, PUT, PATCH, DELETE
- JSON request/response
- Pagination via `sysparm_limit` (default 1000) and `sysparm_offset`
- Field filtering via `sysparm_fields` and `sysparm_query`

**CMDB Instance API** (recommended for CI operations):
- Base URL: `https://{instance}.service-now.com/api/now/cmdb/instance/{className}`
- 7 endpoints for CRUD operations on CIs
- Respects Identification and Reconciliation Engine (IRE) — the preferred path for data integrity
- Handles duplicate detection and data source authority automatically

**Import Set API** (for batch operations):
- Staging table approach for bulk data loads
- Transform maps convert staged data to target tables
- Better for initial loads and large batch syncs

### 3.2 Authentication

ServiceNow supports multiple auth methods. For GetInSync, **OAuth 2.0** is the recommended approach:

**OAuth 2.0 Setup:**
1. Customer creates OAuth API endpoint in ServiceNow: `System OAuth > Application Registry > New > Create an OAuth API endpoint for external clients`
2. This generates a **Client ID** and **Client Secret**
3. Token endpoint: `https://{instance}.service-now.com/oauth_token.do`
4. Grant type: `password` (resource owner) or `client_credentials`
5. Access tokens have configurable expiration; refresh tokens available

**Token Request:**
```
POST https://{instance}.service-now.com/oauth_token.do
Content-Type: application/x-www-form-urlencoded

grant_type=password
&client_id={client_id}
&client_secret={client_secret}
&username={integration_user}
&password={integration_password}
```

**Required ServiceNow Setup (customer side):**
- Dedicated integration user with minimum `cmdb_read` + `cmdb_write` roles
- OAuth plugin active (`com.snc.platform.security.oauth.is.active = true`)
- ACL grants for target tables (e.g., `cmdb_ci_business_app`, `cmdb_ci_business_app.*`)

### 3.3 Key Endpoints for GetInSync

**Publishing Business Applications:**
```
POST https://{instance}.service-now.com/api/now/table/cmdb_ci_business_app
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "name": "LegalEdge",
  "number": "APP-0042",
  "operational_status": "1",
  "life_cycle_stage": "active",
  "life_cycle_stage_status": "active",
  "description": "Legal case management system",
  "short_description": "Legal case management",
  "vendor": "{vendor_sys_id}"
}
```

**Publishing Application Services (Deployment Profiles):**
```
POST https://{instance}.service-now.com/api/now/table/cmdb_ci_service_auto
Content-Type: application/json

{
  "name": "LegalEdge — HRT — Prod",
  "operational_status": "1",
  "environment": "Production",
  "version": "4.2.1"
}
```

**Creating Relationships (DP → Business App):**
```
POST https://{instance}.service-now.com/api/now/table/cmdb_rel_ci

{
  "parent": "{business_app_sys_id}",
  "child": "{app_service_sys_id}",
  "type": "{depends_on_rel_type_sys_id}"
}
```

**Subscribing — Reading CIs:**
```
GET https://{instance}.service-now.com/api/now/table/cmdb_ci_business_app
  ?sysparm_query=operational_status=1
  &sysparm_fields=sys_id,name,number,operational_status,life_cycle_stage
  &sysparm_limit=100
  &sysparm_offset=0
```

### 3.4 ServiceNow Field Mapping (from existing architecture)

| GetInSync Field | ServiceNow Field | SN Table |
|-----------------|------------------|----------|
| `applications.name` | `name` | `cmdb_ci_business_app` |
| `applications.app_id` | `number` | `cmdb_ci_business_app` |
| `applications.operational_status` | `operational_status` | `cmdb_ci_business_app` |
| `applications.lifecycle_status` | `life_cycle_stage` | `cmdb_ci_business_app` |
| `applications.lifecycle_stage_status` | `life_cycle_stage_status` | `cmdb_ci_business_app` |
| `applications.description` | `description` | `cmdb_ci_business_app` |
| `applications.short_description` | `short_description` | `cmdb_ci_business_app` |
| `deployment_profiles.name` | `name` | `cmdb_ci_service_auto` |
| `deployment_profiles.operational_status` | `operational_status` | `cmdb_ci_service_auto` |
| `deployment_profiles.environment` | `environment` | `cmdb_ci_service_auto` |
| `deployment_profiles.version` | `version` | `cmdb_ci_service_auto` |
| `software_products.name` | `name` | `alm_product_model` |
| `product_contracts.name` | `short_description` | `ast_contract` |

### 3.5 ServiceNow — Important Considerations

**Identification & Reconciliation Engine (IRE):**
- Best practice is to use the CMDB Instance API which flows through IRE rather than direct Table API writes
- IRE uses identification rules to detect duplicates and reconciliation rules to determine which data source has authority
- GetInSync should register as a named "data source" in ServiceNow for reconciliation

**Sync Strategy (from existing architecture):**
- Push-first (GetInSync → ServiceNow) for business intent and ownership data
- Pull (ServiceNow → GetInSync) for CMDB baseline data (later phase)
- Schedule-based, not real-time — APM data doesn't change hourly
- Daily or triggered-on-change sync is sufficient

**ServiceNowSyncScope:** Each Deployment Profile needs a configurable sync scope:
- `None` — not synced
- `ApplicationService` — sync as `cmdb_ci_service_auto`
- `TechnicalService` — sync as `cmdb_ci_service_technical`
- `TechnicalServiceOffering` — sync as `service_offering`

---

## 4. HaloITSM REST API

### 4.1 API Overview

HaloITSM provides a modern REST API over HTTPS with JSON payloads. The API exposes most objects visible in the HaloITSM UI.

**Base URL:** `{your_halo_url}/api`

**Key Endpoints:**
| Resource | Endpoint | Methods | Auth Level |
|----------|----------|---------|------------|
| Tickets | `/api/Tickets` | GET, POST, DELETE | Agent |
| Assets | `/api/Asset` | GET, POST, DELETE | Agent |
| Users | `/api/Users` | GET, POST, DELETE | Agent |
| Clients (Organizations) | `/api/Client` | GET, POST, DELETE | Agent |
| Sites | `/api/Site` | GET, POST, DELETE | Agent |
| Suppliers | `/api/Supplier` | GET, POST, DELETE | Agent |
| Services | `/api/Service` | GET, POST, DELETE | Agent |
| Contracts/Agreements | `/api/ClientContract` | GET, POST, DELETE | Agent |
| Knowledge Articles | `/api/KBArticle` | GET, POST, DELETE | Agent |
| Actions (ticket updates) | `/api/Actions` | GET, POST | Agent |

**API Behavior:**
- `GET` — returns dataset based on query parameters
- `POST` — accepts an array of objects to add or update (upsert behavior — include `id` field to update)
- `DELETE` — requires an ID, removes the resource

**Interactive API docs:** Append `/apidoc` to any HaloITSM instance URL (e.g., `https://yourinstance.haloitsm.com/apidoc`) for Swagger-style documentation specific to that instance's configuration.

### 4.2 Authentication

HaloITSM uses OAuth 2.0 with Client ID and Client Secret:

**Setup (in HaloITSM admin):**
1. Navigate to `Configuration > Integrations > HaloITSM API`
2. Note the **Resource Server**, **Authorisation Server**, and **Tenant** values
3. Click `View Applications > New`
4. Set Authentication Method: `Client ID & Secret`
5. Set Agent to Log in as (determines permissions)
6. Configure permissions on the Permissions tab
7. Copy the Client Secret (shown only once)

**Auth Info Endpoint:** `{halo_url}/api/authinfo` — returns tenant name, resource server, and auth server URLs.

**Token Request:**
```
POST {authorisation_server}/auth/token?tenant={tenant_name}
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id={client_id}
&client_secret={client_secret}
&scope=all
```

**Required Credentials (5 total):**
1. Resource Server URL
2. Authorisation Server URL
3. Tenant Name
4. Client ID
5. Client Secret

### 4.3 Key Endpoints for GetInSync

**Publishing Applications (as Assets):**
```
POST {resource_server}/api/Asset
Content-Type: application/json
Authorization: Bearer {access_token}

[{
  "inventory_number": "APP-0042",
  "asset_name": "LegalEdge",
  "assettype_id": {application_asset_type_id},
  "status_id": {active_status_id},
  "client_id": {client_org_id},
  "notes": "Legal case management system"
}]
```

**Publishing Software (as Assets):**
```
POST {resource_server}/api/Asset
Content-Type: application/json

[{
  "asset_name": "Microsoft SQL Server 2019",
  "assettype_id": {software_asset_type_id},
  "status_id": {active_status_id}
}]
```

**Creating Asset Relationships (parent/child):**
HaloITSM supports linking assets via relationship types. The exact field names vary by instance configuration, but typically:
```
POST {resource_server}/api/Asset
[{
  "id": {child_asset_id},
  "linked_assets": [{
    "asset_id": {parent_asset_id},
    "relationship_type_id": {rel_type_id}
  }]
}]
```

**Subscribing — Reading Assets:**
```
GET {resource_server}/api/Asset
  ?assettype_id={type_id}
  &search=LegalEdge
  &count=100
  &page_no=1
```

### 4.4 HaloITSM Data Model Mapping

HaloITSM uses a flexible asset/CI model. Unlike ServiceNow's CSDM with specific tables per CI type, Halo uses **Asset Types** and **Asset Groups** to classify CIs. Mapping requires configuring matching asset types in HaloITSM:

| GetInSync Entity | HaloITSM Target | Asset Type (suggested) |
|------------------|-----------------|----------------------|
| BusinessApplication | Asset | "Business Application" (custom type) |
| DeploymentProfile | Asset (linked to parent) | "Application Instance" (custom type) |
| SoftwareProduct | Asset | "Software" (built-in) |
| ITService | Service | Direct mapping to HaloITSM Services |
| ProductContract | Client Contract | Direct mapping |
| Contacts | Users | Direct mapping |

### 4.5 HaloITSM — Important Considerations

**No CSDM Equivalent:** HaloITSM doesn't have ServiceNow's CSDM framework. It uses a flatter asset model with customizable types and groups. This means:
- GetInSync needs to define asset types in HaloITSM that mirror the CSDM hierarchy
- Relationships between assets are more generic (parent/child, linked)
- The mapping is simpler but less semantically rich

**Webhook Support:** HaloITSM supports webhooks that can trigger on asset changes, enabling near-real-time subscribe flows from Halo → GetInSync.

**Runbooks:** HaloITSM has built-in Runbook automation that can make API calls to external systems, which could be used for Halo → GetInSync push notifications.

**Lansweeper Integration:** Many HaloITSM customers use Lansweeper for asset discovery. GetInSync could potentially read the same discovered data via HaloITSM's API rather than integrating with Lansweeper directly.

---

## 5. Unified Integration Architecture

### 5.1 GetInSync Integration Service Design

```
GetInSync NextGen
      │
      ├── Integration Configuration (per namespace)
      │   ├── Target: ServiceNow | HaloITSM | None
      │   ├── Connection: OAuth credentials (encrypted)
      │   ├── Sync Direction: Publish | Subscribe | Both
      │   ├── Sync Schedule: Manual | Daily | On-Change
      │   └── Field Mapping: Default + Custom overrides
      │
      ├── Sync Engine
      │   ├── Outbound Queue (publish changes)
      │   ├── Inbound Queue (subscribe changes)
      │   ├── Conflict Resolution (last-write-wins or manual)
      │   └── Audit Log (all sync operations)
      │
      └── Platform Adapters
          ├── ServiceNow Adapter
          │   ├── Auth: OAuth 2.0 (password grant)
          │   ├── API: Table API + CMDB Instance API
          │   └── Mapping: CSDM 5.0 aligned
          │
          └── HaloITSM Adapter
              ├── Auth: OAuth 2.0 (client credentials)
              ├── API: REST API (/api/*)
              └── Mapping: Asset Type based
```

### 5.2 Database Schema Additions

The existing architecture hints at needed schema. Key additions for integration:

```sql
-- Integration connection configuration per namespace
CREATE TABLE integration_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id),
  platform TEXT NOT NULL CHECK (platform IN ('servicenow', 'haloitsm')),
  instance_url TEXT NOT NULL,
  auth_type TEXT DEFAULT 'oauth2',
  -- Encrypted credential storage (Supabase Vault)
  client_id_vault_id UUID,
  client_secret_vault_id UUID,
  username_vault_id UUID,
  password_vault_id UUID,
  -- Sync config
  sync_direction TEXT DEFAULT 'publish' CHECK (sync_direction IN ('publish', 'subscribe', 'both')),
  sync_schedule TEXT DEFAULT 'manual' CHECK (sync_schedule IN ('manual', 'daily', 'on_change')),
  is_active BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(namespace_id, platform)
);

-- Sync mapping — tracks which GIS record maps to which external record
CREATE TABLE integration_sync_map (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID NOT NULL REFERENCES integration_connections(id),
  entity_type TEXT NOT NULL, -- 'application', 'deployment_profile', etc.
  entity_id UUID NOT NULL,
  external_id TEXT NOT NULL, -- sys_id (SN) or id (Halo)
  external_table TEXT, -- 'cmdb_ci_business_app', 'Asset', etc.
  sync_direction TEXT NOT NULL CHECK (sync_direction IN ('published', 'subscribed')),
  last_synced_at TIMESTAMPTZ,
  last_sync_hash TEXT, -- detect changes
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(connection_id, entity_type, entity_id)
);

-- Sync audit log
CREATE TABLE integration_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID NOT NULL REFERENCES integration_connections(id),
  operation TEXT NOT NULL, -- 'create', 'update', 'delete', 'read'
  entity_type TEXT NOT NULL,
  entity_id UUID,
  external_id TEXT,
  status TEXT NOT NULL, -- 'success', 'error', 'skipped'
  request_payload JSONB,
  response_payload JSONB,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 5.3 Sync Scope on Deployment Profiles

Add to `deployment_profiles` table (from existing architecture):

```sql
ALTER TABLE deployment_profiles
ADD COLUMN sn_sync_scope TEXT DEFAULT 'none'
  CHECK (sn_sync_scope IN ('none', 'application_service', 'technical_service', 'technical_service_offering'));
```

---

## 6. Implementation Phases

### Phase 37a: Integration Framework (3-4 days)
- `integration_connections` table + RLS
- `integration_sync_map` table + RLS
- `integration_sync_log` table + RLS
- Supabase Vault integration for credential storage
- Connection test UI (verify OAuth, validate endpoint)

### Phase 37b: ServiceNow Publish (6-8 days)

**Prerequisites:** Update Set installed on customer instance (Section 9.6). Subscribe-first matching completed for IT Services and Software Products (Section 8.2).

**Publish order matters** — relationships cannot be created until both ends exist. The sync engine executes in this exact sequence:

| Step | Entity | ServiceNow Target | API | Notes |
|------|--------|-------------------|-----|-------|
| 1 | IT Services (shared) | `service_offering` | CMDB Instance API | New or matched. Use existing `sys_id` for matched services. |
| 2 | IT Services (private) | `cmdb_ci_service_technical` | CMDB Instance API | Only if sync scope = TechnicalService |
| 3 | Software Products | `alm_product_model` | Table API | New or matched. Store `sys_id` for relationship wiring. |
| 4 | Business Applications | `cmdb_ci_business_app` | CMDB Instance API | Always include `correlation_id`, `discovery_source: "GetInSync"`, `operational_status`, `life_cycle_stage`. Never set `model_id` or `model_category`. |
| 5 | Deployment Profiles | `cmdb_ci_service_auto` | CMDB Instance API | One per DP. Include `correlation_id` (DP UUID), `environment`, `operational_status`. |
| 6 | Consumes relationships | `cmdb_rel_ci` | Table API | `parent` = Business App `sys_id`, `child` = Application Service `sys_id`, `type` = Consumes rel_type `sys_id` |
| 7a | Depends_on relationships | `cmdb_rel_ci` | Table API | `parent` = Application Service `sys_id`, `child` = TSO `sys_id`, `type` = Depends on rel_type `sys_id` |
| 7b | Runs_on relationships | `cmdb_rel_ci` | Table API | `parent` = Application Service `sys_id`, `child` = Product Model `sys_id`, `type` = Runs on rel_type `sys_id` |

**Implementation tasks:**
- ServiceNow adapter (OAuth auth, token refresh, error handling)
- 7-step publish orchestrator with dependency-ordered execution
- Sync preview mode: dry-run against IRE showing CREATE/UPDATE/MISMATCH counts before first real push
- Rollback capability: log all created `sys_id`s for potential cleanup
- Manual sync trigger + sync status UI with per-step progress
- Batch handling for large portfolios (100+ applications)

### Phase 37c: ServiceNow Subscribe (3-4 days)
- Pull existing Business Applications from ServiceNow (for delta sync / merge)
- Pull CI relationships for baseline data
- Merge/conflict handling UI
- Scheduled sync (daily)
- **Note:** Subscribe-first matching for IT Services and Software Products is handled in the Phase 37b setup wizard, not here. Phase 37c covers ongoing operational subscribe (pulling changes back from ServiceNow into GetInSync).

### Phase 37d: HaloITSM Publish (3-4 days)
- HaloITSM adapter (auth, token management)
- Asset type setup guidance/wizard
- Publish Applications → Assets
- Publish Deployment Profiles → linked Assets
- Publish Contracts → Client Contracts

### Phase 37e: HaloITSM Subscribe (2-3 days)
- Pull discovered assets from HaloITSM
- Map to GetInSync applications/deployment profiles
- Webhook listener for real-time updates (if customer has Halo webhooks)

**Total estimated effort: 18-23 days** (increased from original 15-20 due to corrected Phase 37b scope)

---

## 7. Customer Prerequisites

### For ServiceNow Integration
1. ServiceNow instance URL (e.g., `acme.service-now.com`)
2. OAuth Application Registry entry created
3. Dedicated integration user with roles: `cmdb_read`, `cmdb_write`, `import_admin` (for Import Sets)
4. ACLs configured for target tables
5. Identification rules configured for GetInSync as a data source

### For HaloITSM Integration
1. HaloITSM instance URL
2. API application created (Configuration > Integrations > HaloITSM API > View Applications)
3. Resource Server, Authorisation Server, and Tenant values
4. Client ID and Client Secret
5. Asset Types configured to match GetInSync entity types

---

## 8. Competitive Positioning

This integration capability directly supports GetInSync's "CSDM Agent" positioning:

- **Path A customers** (stepping stone to ServiceNow APM): GetInSync publishes clean, CSDM-aligned data to ServiceNow, proving the data model works before the customer invests in ServiceNow APM licensing.
- **Path B customers** (permanent alternative): GetInSync serves as the APM tool with optional ServiceNow/Halo sync for operational data.
- **HaloITSM angle**: Many smaller government organizations and mid-market companies use HaloITSM instead of ServiceNow. Supporting both platforms dramatically expands the addressable market.

The fact that GetInSync can push CSDM-compliant data to ServiceNow **without requiring the customer to purchase ServiceNow APM** is a significant differentiator against both Orbus iServer and native ServiceNow APM.

### 8.1 Application Service Population — Key Differentiator

The single most common CSDM compliance gap is **empty Application Services.** Most organizations manage to populate `cmdb_ci_business_app` (Business Applications) but struggle with `cmdb_ci_service_auto` (Application Services) and the `Consumes` relationships between them. ServiceNow community forums are filled with questions about how to populate Application Services — the standard answers are the Application Service Wizard (one at a time, manually) or import sets with manual relationship creation.

GetInSync solves this structurally because **Deployment Profiles ARE Application Services.** The DP-centric architecture means every application already has one or more deployment-context records with environment, hosting, and assessment data attached. When GetInSync publishes, it pushes three things per application:

1. **Business Application** → `cmdb_ci_business_app`
2. **Application Service(s)** → `cmdb_ci_service_auto` (one per Deployment Profile)
3. **Consumes relationship** → `cmdb_rel_ci` (wiring them together)

This is the exact relationship chain that CMDB Health compliance checks for. GetInSync doesn't just push applications — it delivers the most common CSDM compliance gap already solved.

**DP → Application Service field mapping:**

| GetInSync DP Field | ServiceNow Application Service Field | Notes |
|--------------------|--------------------------------------|-------|
| `name` | `name` | e.g., "Sage 300 — Justice — Prod" |
| `environment` | `environment` | Production / Dev / DR / Test |
| `hosting_type` | (hosted_on context) | Cloud / On-Premise / Hybrid |
| `cloud_provider` | (custom or relationship) | Azure / AWS / GCP |
| `region` | (custom) | ca-central-1 |
| `operational_status` | `operational_status` | Active / Retired |
| GIS record ID | `correlation_id` | For IRE identification |

When IT Service links exist, GetInSync also publishes `Depends on` relationships between Application Services and Technical Service Offerings — the CSDM Walk phase relationship that organizations spend months building manually.

**Marketing angle:** *"Most organizations have Business Applications in their CMDB but empty Application Services. GetInSync fills both tables and wires the relationships — in one sync."*

### 8.2 Subscribe-First Matching for IT Services

Before GetInSync can publish `depends_on` relationships between Deployment Profiles (Application Services) and IT Services (Technical Service Offerings), it must know which IT Services **already exist** in the customer's ServiceNow instance. This is the "Subscribe-first" pattern.

**Why Subscribe-first:** If the customer's Central IT has already defined "Database Services" as a TSO in ServiceNow, GetInSync must wire `depends_on` relationships to that existing record — not create a duplicate "Database Services" TSO.

#### Scenario A: Customer Already Has TSOs (CSDM Walk Stage)

The customer's Central IT has already defined shared infrastructure services as Technical Service Offerings. This is common for organizations at CSDM Walk stage or beyond — built by Service Mapping, ITSM team, or consulting engagement.

**Flow:**
1. **Pull** existing Technical Service Offerings from ServiceNow via:
   ```
   GET /api/now/table/service_offering
     ?sysparm_query=type=technical
     &sysparm_fields=sys_id,name,number,operational_status,classification
   ```
2. **Match** to GetInSync IT Services — integration setup wizard presents a mapping table:
   ```
   ┌─────────────────────────────┬───────────────────────────────────┐
   │  GetInSync IT Service       │  ServiceNow TSO                   │
   ├─────────────────────────────┼───────────────────────────────────┤
   │  Database Services          │  Database Services - Gold    ✓    │
   │  Application Hosting        │  Cloud Hosting - Standard    ✓    │
   │  Network Infrastructure     │  Network Services            ✓    │
   │  Cybersecurity Operations   │  (no match - will create)         │
   │  Enterprise Backup          │  Backup & Recovery           ✓    │
   │  Help Desk Services         │  (no match - will create)         │
   └─────────────────────────────┴───────────────────────────────────┘
   ```
3. **Store** mappings in `integration_sync_map`:
   - `entity_type = 'it_service'`
   - `entity_id = {GIS IT Service UUID}`
   - `external_id = {SN TSO sys_id}`
   - `sync_direction = 'subscribed'` (for matched) or `'published'` (for new)
4. **Publish** DPs as Application Services with `depends_on` relationships pointing to the resolved `sys_id`s

**Result:** 4 matched (use existing `sys_id`), 2 new (create as TSOs in ServiceNow). All 6 `depends_on` relationships wire correctly.

#### Scenario B: Customer Doesn't Have TSOs Yet (CSDM Crawl Stage)

This is the more common case — the majority of the target market. The customer has Business Applications (maybe) but the service layer is empty.

**Flow:**
1. **Skip** the pull step (nothing to match)
2. **Push** all GetInSync IT Services → `service_offering` (creating new TSOs)
3. **Push** DPs → `cmdb_ci_service_auto` (creating Application Services)
4. **Push** `depends_on` relationships (wiring the CSDM chain)
5. **Push** Business Apps → `cmdb_ci_business_app`
6. **Push** `Consumes` relationships

**Result:** Customer's ServiceNow goes from empty Application Services AND empty Technical Service Offerings to a full three-layer CSDM chain. Crawl-to-Walk in one sync.

#### Matching Also Applies to Software Products

The same subscribe-first pattern applies to Software Products → `alm_product_model`. If the customer's SAM team has already created Software Models (common if they have SAM Pro or Software Asset Management), GetInSync must match to existing records rather than creating duplicates.

The integration setup wizard should have two matching steps:
1. **IT Service → TSO matching** (for `depends_on` relationships)
2. **Software Product → Product Model matching** (for `runs_on` relationships)

### 8.3 Multi-Layer Publish Sequence

The full CSDM relationship chain that GetInSync publishes per application:

```
Level 0: Business Application
    │
    │  Consumes (cmdb_rel_ci)
    │
    ├──► Level 1: Application Service (DP: "PROD - AWS-US-WEST-2")
    │       │
    │       ├── Depends_on ──► IT Service: "Application Hosting" (TSO)
    │       ├── Depends_on ──► IT Service: "Database Services" (TSO)
    │       ├── Depends_on ──► IT Service: "Network Infrastructure" (TSO)
    │       ├── Depends_on ──► IT Service: "Cybersecurity Operations" (TSO)
    │       ├── Depends_on ──► IT Service: "Enterprise Backup" (TSO)
    │       ├── Depends_on ──► IT Service: "Help Desk Services" (TSO)
    │       │
    │       ├── Runs_on ──► Software Product: "Oracle Database 19c" (Product Model)
    │       ├── Runs_on ──► Software Product: "VMware vSphere 8" (Product Model)
    │       └── Runs_on ──► Software Product: "Commvault Backup" (Product Model)
    │
    └──► Level 1: Application Service (DP: "PROD - CA")
            │
            ├── Depends_on ──► (same IT Services, different environment)
            └── Runs_on ──► (same or different Software Products)
```

**API call sequence for one application with 2 DPs, 6 IT Services, and 3 Software Products:**

| # | Operation | Endpoint | Count |
|---|-----------|----------|-------|
| 1 | Create/update IT Services | `POST /api/now/cmdb/instance/service_offering` | 6 (or 0 if all matched) |
| 2 | Create/update Software Products | `POST /api/now/table/alm_product_model` | 3 (or 0 if all matched) |
| 3 | Create/update Business Application | `POST /api/now/cmdb/instance/cmdb_ci_business_app` | 1 |
| 4 | Create/update Application Services | `POST /api/now/cmdb/instance/cmdb_ci_service_auto` | 2 |
| 5 | Create Consumes relationships | `POST /api/now/table/cmdb_rel_ci` | 2 |
| 6 | Create Depends_on relationships | `POST /api/now/table/cmdb_rel_ci` | 12 (2 DPs × 6 services) |
| 7 | Create Runs_on relationships | `POST /api/now/table/cmdb_rel_ci` | 6 (2 DPs × 3 products) |
| | **Total API calls per application** | | **~32** |

**For a portfolio of 300 applications:** ~9,600 API calls. At ServiceNow's typical rate limit of 60 calls/minute for an integration user, that's approximately 2.7 hours for a full initial sync. Subsequent delta syncs will be much smaller (only changed records).

**Optimization opportunities:**
- Batch relationship creation (multiple `cmdb_rel_ci` records per call if using Import Sets)
- IT Services and Software Products only push once (shared across applications)
- Delta detection via `last_sync_hash` on `integration_sync_map` — skip unchanged records
- Parallel calls where dependency ordering allows (e.g., IT Services and Software Products can push concurrently)

### 8.4 Application Service Wizard — Why This Matters Competitively

For context on the pain GetInSync eliminates, here's what ServiceNow customers face when trying to populate Application Services manually.

**The Wizard:** A three-panel guided form at `CSDM > Manage Technical Service > Application Service` (URL: `$csdm_app_service.do`). ServiceNow forces this wizard view in CSDM-enabled instances.

- **Panel 1 — "Provide Basic Details":** Name, description, operational status. Relate to Business Application(s) and Service Offering(s) — by hand, clicking lookup fields, searching, selecting.
- **Panel 2 — "Populate the Application Service":** Choose population method: Top-Down Discovery (requires Service Mapping licensed + mature Discovery), Tag-Based, Dynamic CI Group, or Manual.
- **Panel 3 — "Preview the Service":** Summary and save.

**Friction points:**
- **One-at-a-time:** 300 apps × 2 deployments = 600 wizard runs. Panel 1, Panel 2, Panel 3, save. No bulk wizard exists.
- **Private page:** `$csdm_app_service.do` starts with `$` — cannot customize. Custom fields must go on the classic form separately.
- **Environment is a choice list, not a reference:** Community calls this "poor, probably historical design." The Environment table exists but no reference field links to it from the Application Service form.
- **Consumes relationships not built by Service Mapping:** Even with top-down discovery for infrastructure, the Business Application → Application Service relationship must be manually created.

**GetInSync eliminates all of this.** Customers don't realize they've been building their CSDM Application Service layer the whole time — they think they're doing APM assessments. Application Services are a structural byproduct of the DP-centric model.

---

## 9. ServiceNow Auto-Trigger Risks

When GetInSync inserts records into `cmdb_ci_business_app` and `cmdb_ci_service_auto`, several layers of automatic ServiceNow behavior fire. The integration must account for these to avoid unexpected side effects.

### 9.1 Inherited Business Rules from `cmdb_ci` (Parent Table)

Both target tables extend `cmdb_ci`, so all parent table business rules execute on child table operations:

| Business Rule | Type | Risk to GetInSync | Mitigation |
|---------------|------|-------------------|------------|
| **Create Asset from CI** | After Insert | Creates phantom `alm_asset` records if the CI has a Model Category with a mapped Asset Class. Business Apps typically don't have one OOB, but SAM-heavy orgs may have customized this. | Do NOT set `model_id` or `model_category` on pushed records. Document that GetInSync does not create asset records. |
| **Asset-CI Synchronizer** | After Insert/Update | If an asset record IS created, this synchronizes `install_status`, `hardware_status`, and `asset.state` bidirectionally. Status fields GetInSync sets could cascade to assets and bounce back. | Avoid triggering asset creation (above). If detected, document as customer customization to review. |
| **Protect cmdb_ci_class** | Before Update | Prevents modification of `sys_class_name` after insert. Not a conflict if GetInSync targets the correct table, but blocks reclassification attempts. | Always insert to the correct child table (`cmdb_ci_business_app` or `cmdb_ci_service_auto`), never to parent `cmdb_ci`. |

### 9.2 IRE-Specific Behavior

When using the CMDB Instance API (recommended), IRE processing occurs before business rules:

| IRE Step | Behavior | Risk | Mitigation |
|----------|----------|------|------------|
| **Identification** | OOB rule for `cmdb_ci_business_app` matches on `name`. | Name mismatches ("Microsoft 365" vs "Microsoft Office 365") create duplicates. | Include `correlation_id` (GetInSync record ID) in identification rules via Update Set. Match on correlation_id first, name second. |
| **Reconciliation** | Determines which data source can write to which attributes. | Without reconciliation rules, Discovery or Service Mapping can overwrite GetInSync data. | Update Set establishes GetInSync as authoritative for business attributes; defers to Discovery for infrastructure attributes. |
| **Data Source Stamping** | IRE sets `discovery_source` based on API payload. | If not explicitly set, appears as "ImportSet" or blank — invisible to CMDB governance. | Always include `discovery_source: "GetInSync"` in every payload. Update Set registers this as a valid data source choice. |

### 9.3 CMDB Health and Compliance (Background Jobs)

These don't fire on insert but flag GetInSync-created records on scheduled checks:

| Check | Trigger | Risk | Mitigation |
|-------|---------|------|------------|
| **Completeness** | Scheduled | Business Apps missing `managed_by`, `owned_by`, `life_cycle_stage`, `life_cycle_stage_status` show as "incomplete." CMDB governance team blames the integration. | Always populate `operational_status` and `life_cycle_stage` (GetInSync has both). Map application contacts to `managed_by`/`owned_by` where possible. |
| **Compliance** | Scheduled | Desired State audits check for required relationships. Historically, a Business App without an Application Service relationship would fail. | **Not a risk for GetInSync.** Deployment Profiles sync as Application Services with `Consumes` relationships already wired. This is a differentiator, not a gap. |
| **Attestation** | Policy-driven | If customer has attestation policies on `cmdb_ci_business_app`, newly created CIs generate attestation tasks assigned to the `managed_by`/`owned_by` user. | Document that first sync may trigger attestation tasks. Recommend customer reviews attestation policies before initial sync. |

### 9.4 Customer-Specific Flow Designer / Workflow Triggers

Many customers have custom automation on `cmdb_ci_business_app` insert/update. Common patterns:

- **Notification flows** — "Email the APM team when a new business application is registered"
- **Approval flows** — Some orgs require approval before a business app goes to "Operational" status
- **Auto-relationship flows** — "When a business app is created, auto-create a placeholder Application Service" (GetInSync already provides real Application Services, so this would create duplicates)
- **APM workspace triggers** — If ServiceNow APM module is licensed, new business apps can trigger assessment workflows

These are unpredictable. The **sync preview mode** (see Section 9.5) is the primary mitigation.

### 9.5 Recommended Safeguards

1. **Always use CMDB Instance API (IRE), never raw Table API.** Table API bypasses identification rules, guaranteeing duplicates.
2. **Pre-built Update Set** (see Section 9.6) registers GetInSync as a data source with proper identification and reconciliation rules.
3. **Always set `operational_status` and `life_cycle_stage`** on every push to avoid CMDB Health completeness failures.
4. **Never set `model_id` or `model_category`** to avoid triggering phantom asset creation.
5. **Sync Preview mode:** Before first real push, dry-run against IRE identification to show: "These 12 apps will UPDATE existing CIs. These 44 will CREATE new CIs. These 3 have name mismatches needing resolution."
6. **Document customer-side review checklist:** Before enabling sync, customer should review their custom business rules, Flow Designer flows, and attestation policies on target tables.

### 9.6 Resolved: Pre-Built Update Set

**Decision:** Start with a downloadable Update Set (XML package). Design for eventual Scoped App on the ServiceNow Store.

The Update Set includes:

| Component | Table | Purpose |
|-----------|-------|---------|
| **Data Source** | `cmdb_ci_data_source` | Registers "GetInSync" as a named CMDB data source |
| **Identification Rule** (Business App) | `cmdb_identification_rule` | Match `cmdb_ci_business_app` on `correlation_id` (priority 1), `name` (priority 2) |
| **Identification Rule** (App Service) | `cmdb_identification_rule` | Match `cmdb_ci_service_auto` on `correlation_id` |
| **Reconciliation Rules** | `cmdb_reconciliation_rule` | GetInSync authoritative for: `operational_status`, `life_cycle_stage`, `life_cycle_stage_status`, `description`, `short_description`, `owned_by`, `managed_by_group`. Defers to Discovery for infrastructure attributes. |
| **Data Source Precedence** | `cmdb_datasource_priority` | GetInSync at configurable priority (default 200, below Discovery at 100) |
| **Choice Value** | `sys_choice` | Adds "GetInSync" to `discovery_source` dropdown on `cmdb_ci` |

**Distribution:** Hosted for download from GetInSync. Integration setup wizard offers "Download ServiceNow Configuration Package" button that generates a customized Update Set with the customer's GetInSync instance URL pre-populated in the REST Message endpoint.

**Why not a Scoped App yet:** ServiceNow certification mandates CMDB integrations use the pull mechanism (ServiceNow pulls from GetInSync). GetInSync's architecture is push-first. Also, IRE identification rules for global CMDB tables cannot be shipped inside a scoped app — they must be documented as manual post-install steps or shipped via Update Set. Scoped App is the right long-term target once the pull API is built (Phase 37c).

---

## 10. Open Questions

1. **Supabase Edge Functions vs. Server-side:** Should sync operations run as Supabase Edge Functions (Deno) or as a separate Node.js service? Edge Functions have a 150-second timeout which may be too short for large syncs.

2. **Rate Limiting:** ServiceNow has configurable rate limits per instance. HaloITSM also rate-limits. Need to implement backoff and batching strategies.

3. **Credential Storage:** Supabase Vault is the natural choice for encrypted credential storage. Need to validate it meets SOC2 requirements for storing customer ServiceNow/Halo credentials.

4. **Tier Gating:** Integration capability is Full tier only? Or Enterprise+ for ServiceNow and Pro+ for HaloITSM?

---

## 11. Related Documents

| Document | Relevance |
|----------|-----------|
| features/integrations/servicenow-alignment.md | Full CSDM entity mapping |
| catalogs/csdm-application-attributes.md | Field-level mapping + CSDM gap analysis |
| features/integrations/architecture.md | Internal/external integration model |
| marketing/product-roadmap-2026.md | Phase 37 (ServiceNow), Phase 51 (CSDM publish) |
| archive/superseded/marketing-explainer-v1_5.md | Two-path positioning (stepping stone vs. permanent) |

---

*Document: features/integrations/itsm-api-research.md*  
*February 2026*
