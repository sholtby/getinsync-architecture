# GetInSync — Power BI Export Layer Architecture

**Version:** 1.1
**Date:** March 13, 2026
**Status:** 🟡 AS-DESIGNED
**Companion to:** features/technology-health/dashboard.md, infrastructure/edge-functions-layer-architecture.md

---

## 1. Purpose

Define the architecture for external BI access to GetInSync data. Customers want to:

1. Connect Power BI (or other BI tools) to their namespace's data
2. Build custom management dashboards with their own slicer/filter layouts
3. Publish reports to SharePoint via Power Automate
4. Run scheduled data refreshes without opening the GetInSync application

This addresses the "mega slicer" pattern seen in Government of Saskatchewan's Power BI dashboard — 15 dropdown filters, 3 technology lifecycle panels, KPI cards, and a filterable detail table.

**Origin:** Customer built a Power BI "Application Portfolio Management Internal Reports" dashboard from CMDB spreadsheet extracts. GetInSync already replicates this natively (Technology Health dashboard, 5 tabs), but customers also want the data accessible in their existing BI toolchain for executive reporting and SharePoint publishing.

---

## 2. Design Principles

1. **Flat views for BI tools** — No joins required on the consumer side. One row = one fact. Human-readable column names.
2. **RLS-respected** — All views use `security_invoker = true`. External access sees only what the authenticated user can see.
3. **No application changes** — PBI views are database-only. No React code changes needed.
4. **Tier-gated** — Enterprise tier only (per dashboard.md §7).
5. **Read-only** — Export layer provides SELECT access only. No INSERT/UPDATE/DELETE.

---

## 3. Power BI Views

Six `vw_pbi_*` views, each designed as a flat/wide table optimized for BI consumption.

### 3.1 Application Portfolio

One row per application with all slicer-relevant fields.

```sql
CREATE OR REPLACE VIEW vw_pbi_application_portfolio
WITH (security_invoker = true) AS
SELECT
  a.id AS application_id,
  'APP' || lpad(a.app_id::text, 7, '0') AS app_number,
  a.name AS application_name,
  COALESCE(a.operational_status, 'unknown') AS operational_status,
  COALESCE(a.lifecycle_status, 'incomplete_data') AS lifecycle_status,
  COALESCE(a.management_classification, 'apm') AS management_classification,
  a.csdm_stage,
  a.branch,
  w.id AS workspace_id,
  w.name AS ministry,
  w.namespace_id,
  -- Crown jewel (computed from portfolio criticality)
  EXISTS (
    SELECT 1 FROM portfolio_assignments pa
    WHERE pa.application_id = a.id
      AND pa.criticality IS NOT NULL
      AND pa.criticality >= 50
  ) AS is_crown_jewel,
  -- Contacts (first of each role)
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'owner'
   LIMIT 1) AS owned_by,
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'support'
   LIMIT 1) AS supported_by,
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'manager'
   LIMIT 1) AS managed_by,
  -- Counts
  (SELECT count(*) FROM deployment_profiles dp
   WHERE dp.application_id = a.id) AS deployment_count,
  (SELECT count(DISTINCT dp.server_name) FROM deployment_profiles dp
   WHERE dp.application_id = a.id AND dp.server_name IS NOT NULL) AS server_count,
  a.created_at,
  a.updated_at
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id;
```

**Power BI slicer columns:** ministry, branch, lifecycle_status, management_classification, csdm_stage, is_crown_jewel, owned_by, supported_by, managed_by.

### 3.2 Deployment Technology

One row per DP-technology tag combination. Granular view for technology-level analysis.

```sql
CREATE OR REPLACE VIEW vw_pbi_deployment_technology
WITH (security_invoker = true) AS
SELECT
  a.id AS application_id,
  a.name AS application_name,
  w.name AS ministry,
  w.namespace_id,
  dp.id AS deployment_profile_id,
  dp.name AS deployment_profile_name,
  dp.server_name,
  dp.environment,
  dp.hosting_type,
  dp.cloud_provider,
  tpc.name AS technology_category,
  tp.name AS technology_name,
  tp.product_family,
  COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
  dptp.edition,
  -- Lifecycle
  CASE
    WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'End of Support'
    WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'End of Support'
    WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'Extended Support'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'Mainstream'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'Preview'
    WHEN tlr.id IS NOT NULL THEN 'Incomplete Data'
    ELSE 'Not Linked'
  END AS lifecycle_stage,
  -- Risk level
  CASE
    WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'High'
    WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'High'
    WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE
      AND tlr.extended_support_end IS NOT NULL
      AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'High'
    WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'Medium'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'Low'
    ELSE 'Unknown'
  END AS risk_level,
  -- Key dates
  tlr.ga_date,
  tlr.mainstream_support_end,
  tlr.extended_support_end,
  tlr.end_of_life_date,
  CASE
    WHEN tlr.end_of_life_date IS NOT NULL THEN tlr.end_of_life_date - CURRENT_DATE
    ELSE NULL
  END AS days_to_eol,
  tlr.maintenance_type
FROM deployment_profile_technology_products dptp
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = dp.workspace_id
LEFT JOIN technology_product_categories tpc ON tpc.id = tp.category_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id;
```

**Power BI slicer columns:** ministry, technology_category, product_family, lifecycle_stage, risk_level, environment, hosting_type, maintenance_type.

### 3.3 Infrastructure Report (Wide)

One row per deployment profile with OS/DB/Web flattened into columns. Mirrors the application infrastructure detail table in the Power BI screenshot.

```sql
CREATE OR REPLACE VIEW vw_pbi_infrastructure_report
WITH (security_invoker = true) AS
SELECT
  a.id AS application_id,
  'APP' || lpad(a.app_id::text, 7, '0') AS app_number,
  a.name AS application_name,
  COALESCE(a.operational_status, 'unknown') AS operational_status,
  COALESCE(a.lifecycle_status, 'incomplete_data') AS application_lifecycle_status,
  a.management_classification,
  a.csdm_stage,
  a.branch,
  w.name AS ministry,
  w.namespace_id,
  dp.id AS deployment_profile_id,
  dp.name AS deployment_profile_name,
  dp.server_name,
  dp.environment,
  dp.hosting_type,
  dp.cloud_provider,
  -- Crown jewel
  ir.is_crown_jewel,
  -- OS layer
  ir.os_name,
  ir.os_version,
  ir.os_edition,
  ir.os_lifecycle_status AS os_stage,
  ir.os_days_to_eol,
  -- DB layer
  ir.db_name,
  ir.db_version,
  ir.db_edition,
  ir.db_lifecycle_status AS db_stage,
  ir.db_days_to_eol,
  -- Web layer
  ir.web_name,
  ir.web_version,
  ir.web_edition,
  ir.web_lifecycle_status AS web_stage,
  ir.web_days_to_eol,
  -- Worst lifecycle
  ir.worst_lifecycle_status,
  -- Contacts (from application portfolio)
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'owner'
   LIMIT 1) AS owned_by,
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'support'
   LIMIT 1) AS supported_by,
  (SELECT c.display_name FROM application_contacts ac
   JOIN contacts c ON c.id = ac.contact_id
   WHERE ac.application_id = a.id AND ac.role_type = 'manager'
   LIMIT 1) AS managed_by
FROM vw_application_infrastructure_report ir
JOIN applications a ON a.id = ir.application_id
JOIN workspaces w ON w.id = ir.workspace_id
JOIN deployment_profiles dp ON dp.id = ir.deployment_profile_id;
```

**Note:** This view wraps `vw_application_infrastructure_report` to add human-readable column aliases and contact information. The underlying view already does the lateral joins for OS/DB/Web technology layers.

### 3.4 Lifecycle Summary

Aggregated lifecycle counts per technology category and lifecycle stage. Feeds KPI cards and donut charts.

```sql
CREATE OR REPLACE VIEW vw_pbi_lifecycle_summary
WITH (security_invoker = true) AS
SELECT
  w.namespace_id,
  tpc.name AS technology_category,
  -- Lifecycle stage (human-readable)
  CASE
    WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'End of Support'
    WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'End of Support'
    WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'Extended Support'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'Mainstream'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'Preview'
    WHEN tlr.id IS NOT NULL THEN 'Incomplete Data'
    ELSE 'Not Linked'
  END AS lifecycle_stage,
  -- Counts
  count(DISTINCT tp.id) AS version_count,
  count(DISTINCT dptp.id) AS instance_count,
  count(DISTINCT dp.id) AS deployment_count,
  count(DISTINCT dp.application_id) AS application_count,
  count(DISTINCT dp.server_name) FILTER (WHERE dp.server_name IS NOT NULL) AS server_count
FROM deployment_profile_technology_products dptp
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
LEFT JOIN technology_product_categories tpc ON tpc.id = tp.category_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
GROUP BY w.namespace_id, tpc.name, 3;
```

### 3.5 Server Inventory

One row per server with technology stack and application counts.

```sql
CREATE OR REPLACE VIEW vw_pbi_server_inventory
WITH (security_invoker = true) AS
SELECT
  dp.server_name,
  w.name AS ministry,
  w.namespace_id,
  dp.environment,
  count(DISTINCT dp.application_id) AS application_count,
  count(DISTINCT dp.id) AS deployment_count,
  -- Aggregated tech stack (comma-separated for BI display)
  string_agg(DISTINCT
    CASE WHEN tpc.name = 'Operating System'
      THEN tp.name || COALESCE(' ' || dptp.deployed_version, '')
    END, ', ') AS operating_systems,
  string_agg(DISTINCT
    CASE WHEN tpc.name = 'Database'
      THEN tp.name || COALESCE(' ' || dptp.deployed_version, '')
    END, ', ') AS databases,
  string_agg(DISTINCT
    CASE WHEN tpc.name = 'Web Server'
      THEN tp.name || COALESCE(' ' || dptp.deployed_version, '')
    END, ', ') AS web_servers,
  -- Worst lifecycle
  CASE
    WHEN bool_or(tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE) THEN 'End of Support'
    WHEN bool_or(tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE) THEN 'End of Support'
    WHEN bool_or(tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE) THEN 'Extended Support'
    WHEN bool_or(tlr.id IS NOT NULL) THEN 'Mainstream'
    ELSE 'Incomplete Data'
  END AS worst_lifecycle_status,
  count(DISTINCT dptp.id) FILTER (
    WHERE tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE
       OR tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE
  ) AS end_of_support_tech_count,
  min(tlr.end_of_life_date) FILTER (WHERE tlr.end_of_life_date >= CURRENT_DATE) AS next_eol_date
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
LEFT JOIN deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp.id
LEFT JOIN technology_products tp ON tp.id = dptp.technology_product_id
LEFT JOIN technology_product_categories tpc ON tpc.id = tp.category_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
WHERE dp.server_name IS NOT NULL
GROUP BY dp.server_name, w.name, w.namespace_id, dp.environment;
```

### 3.6 Workspace Summary

One row per workspace (ministry) with portfolio-level counts for executive dashboards.

```sql
CREATE OR REPLACE VIEW vw_pbi_workspace_summary
WITH (security_invoker = true) AS
SELECT
  w.id AS workspace_id,
  w.name AS ministry,
  w.namespace_id,
  count(DISTINCT a.id) AS application_count,
  count(DISTINCT dp.id) AS deployment_count,
  count(DISTINCT dp.server_name) FILTER (WHERE dp.server_name IS NOT NULL) AS server_count,
  count(DISTINCT a.id) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM portfolio_assignments pa
      WHERE pa.application_id = a.id AND pa.criticality >= 50
    )
  ) AS crown_jewel_count,
  count(DISTINCT dptp.id) FILTER (
    WHERE tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE
       OR tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE
  ) AS eol_tech_count,
  count(DISTINCT sp.id) AS software_product_count
FROM workspaces w
LEFT JOIN applications a ON a.workspace_id = w.id
LEFT JOIN deployment_profiles dp ON dp.application_id = a.id
LEFT JOIN deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp.id
LEFT JOIN technology_products tp ON tp.id = dptp.technology_product_id
LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
LEFT JOIN deployment_profile_software_products dpsp ON dpsp.deployment_profile_id = dp.id
LEFT JOIN software_products sp ON sp.id = dpsp.software_product_id
GROUP BY w.id, w.name, w.namespace_id;
```

---

## 4. External Access — Authentication

### 4.1 Approach A: Edge Function API (Recommended for Production)

A dedicated Edge Function that authenticates via per-namespace API keys and returns view data.

**Endpoint:** `GET /functions/v1/pbi-export`

**Query parameters:**
- `view` — View name without prefix (e.g., `application_portfolio`, `deployment_technology`)
- `format` — Response format: `json` (default) or `csv`
- `workspace` — Optional workspace filter (name or ID)

**Authentication:** `X-API-Key` header with a namespace-scoped API key.

**New table:**

```sql
CREATE TABLE namespace_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  api_key_hash TEXT NOT NULL,           -- bcrypt hash of the key
  label TEXT NOT NULL,                   -- "Power BI Production", "SharePoint Sync"
  allowed_views TEXT[] DEFAULT '{}',     -- empty = all views, or specific view names
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,               -- NULL = no expiry
  rate_limit_per_hour INTEGER DEFAULT 60
);

-- Index for fast lookup
CREATE INDEX idx_namespace_api_keys_hash ON namespace_api_keys(api_key_hash) WHERE is_active = true;

-- RLS: only namespace admins can manage keys
ALTER TABLE namespace_api_keys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage API keys" ON namespace_api_keys
  FOR ALL USING (
    namespace_id IN (
      SELECT namespace_id FROM namespace_members
      WHERE user_id = auth.uid() AND role IN ('admin')
    )
  );

-- Audit trigger
CREATE TRIGGER audit_namespace_api_keys
  AFTER INSERT OR UPDATE OR DELETE ON namespace_api_keys
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

**Edge Function pseudocode:**

```typescript
// supabase/functions/pbi-export/index.ts
import { handleCors } from '../_shared/cors.ts';
import { createClient } from '@supabase/supabase-js';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return handleCors(req);

  const apiKey = req.headers.get('X-API-Key');
  if (!apiKey) return new Response('Missing API key', { status: 401 });

  // Verify API key and get namespace
  const supabase = createClient(URL, SERVICE_ROLE_KEY);
  const { data: keyRecord } = await supabase
    .from('namespace_api_keys')
    .select('namespace_id, allowed_views, rate_limit_per_hour')
    .eq('api_key_hash', await bcryptHash(apiKey))
    .eq('is_active', true)
    .single();

  if (!keyRecord) return new Response('Invalid API key', { status: 401 });

  // Check rate limit, expiry, allowed views...

  const url = new URL(req.url);
  const viewName = url.searchParams.get('view');
  const format = url.searchParams.get('format') || 'json';

  // Query the PBI view filtered by namespace
  const { data, error } = await supabase
    .from(`vw_pbi_${viewName}`)
    .select('*')
    .eq('namespace_id', keyRecord.namespace_id);

  // Update last_used_at
  await supabase
    .from('namespace_api_keys')
    .update({ last_used_at: new Date().toISOString() })
    .eq('api_key_hash', await bcryptHash(apiKey));

  if (format === 'csv') {
    return new Response(toCsv(data), {
      headers: { 'Content-Type': 'text/csv', ...corsHeaders }
    });
  }
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  });
});
```

**Pros:**
- Full control over authentication, rate limiting, audit
- API keys are revocable and expirable
- Works with Power BI Web connector, Power Automate HTTP action, any REST client
- Format flexibility (JSON or CSV)
- View-level permissions (allowed_views array)

**Cons:**
- Requires Edge Function deployment
- API key management UI needed in namespace settings
- Depends on Edge Functions shared scaffold being ready

### 4.2 Approach B: Service Account (Simpler, Near-Term)

Create a Supabase auth user per namespace that Power BI authenticates as.

**Setup per namespace:**
1. Admin creates a "report user" via the GetInSync invite flow with `viewer` role
2. Report user gets email/password credentials
3. Customer configures Power BI to authenticate via Supabase REST API

**Power BI connection:**
1. Power BI → Web connector → `https://<project>.supabase.co/rest/v1/vw_pbi_application_portfolio`
2. Headers: `apikey: <anon_key>`, `Authorization: Bearer <jwt_token>`
3. JWT obtained via `POST /auth/v1/token?grant_type=password` with report user credentials

**Token refresh flow:**
- Supabase JWTs expire after 1 hour (configurable)
- Power Automate flow: Step 1 = get token, Step 2 = call view with token
- Or: configure longer JWT expiry in Supabase Auth settings for report users

**Pros:**
- No custom infrastructure — uses existing Supabase auth + PostgREST
- RLS naturally scopes to the report user's namespace
- Works today with no code changes (just deploy the views)

**Cons:**
- JWT expiry requires refresh logic in Power BI / Power Automate
- Managing report users across namespaces
- Less granular control (no view-level permissions, no rate limiting)
- Password management overhead

### 4.3 Recommendation

| Phase | Approach | When |
|-------|----------|------|
| **Phase 1 (Now)** | Deploy PBI views + Approach B | Immediate. Views are SQL-only. Service account is zero-code. |
| **Phase 2 (Q2)** | Build Approach A (Edge Function API) | When Edge Functions shared scaffold is production-ready and a customer requests it. |

---

## 5. SharePoint Integration Pattern

For customers who want GetInSync data on SharePoint dashboards:

### 5.1 Power Automate Flow (Approach B)

```
┌─────────────────────────────────────────────────────┐
│ Power Automate — Recurrence (Daily 6 AM)            │
│                                                      │
│ 1. HTTP POST: Supabase /auth/v1/token               │
│    Body: { email, password }                         │
│    → Extract access_token                            │
│                                                      │
│ 2. HTTP GET: Supabase /rest/v1/vw_pbi_*             │
│    Headers: Authorization: Bearer <token>            │
│    → Parse JSON array                                │
│                                                      │
│ 3. Apply to each row:                                │
│    → Create/Update item in SharePoint List           │
│    OR                                                │
│    → Update Excel file in SharePoint                 │
│                                                      │
│ 4. (Optional) Refresh Power BI dataset               │
└─────────────────────────────────────────────────────┘
```

### 5.2 Power Automate Flow (Approach A — Future)

```
┌─────────────────────────────────────────────────────┐
│ Power Automate — Recurrence (Daily 6 AM)            │
│                                                      │
│ 1. HTTP GET: GetInSync /functions/v1/pbi-export     │
│    ?view=infrastructure_report&format=json           │
│    Headers: X-API-Key: <namespace_api_key>           │
│    → Parse JSON array                                │
│                                                      │
│ 2. Apply to each row:                                │
│    → Create/Update item in SharePoint List           │
│                                                      │
│ 3. (Optional) Refresh Power BI dataset               │
└─────────────────────────────────────────────────────┘
```

### 5.3 Power BI Direct Connection

For Power BI Desktop / Power BI Service:

1. **Data source:** Web / REST API
2. **URL:** Supabase REST endpoint or Edge Function endpoint
3. **Authentication:** API key header or Bearer token
4. **Refresh:** Scheduled refresh in Power BI Service (gateway not required for cloud endpoints)
5. **Slicers:** Built from the flat view columns — ministry, lifecycle_stage, technology_category, etc.

---

## 6. Native "Explorer" Tab (Companion Feature)

In parallel with external BI access, the Technology Health dashboard gains an **Explorer** tab that mimics the Power BI mega slicer layout natively — always-visible filter sidebar, technology count panels, KPI grid, and filterable detail table.

**See:** Plan file for full layout wireframe and implementation details.

**Key difference:** The Explorer tab uses the same data views that power the PBI export, ensuring consistency between native and external reporting.

---

## 7. Tier Availability

| Feature | Trial | Essentials | Plus | Enterprise |
|---------|-------|------------|------|------------|
| Technology Health dashboard (native) | - | - | Partial | Full |
| PBI views (SQL deployed) | - | - | - | Full |
| Service account access (Approach B) | - | - | - | Full |
| API key access (Approach A) | - | - | - | Full |
| SharePoint integration | - | - | - | Full |

---

## 8. Deployment Checklist

### Phase 1: Views + Service Account (Now)

- [ ] Deploy 6 `vw_pbi_*` views (Stuart — SQL Editor)
- [ ] GRANT SELECT on all views to `authenticated, service_role`
- [ ] Verify `security_invoker = true` on all views
- [ ] Test: query each view as a namespace member — confirm RLS scoping
- [ ] Test: query as member of different namespace — confirm no cross-namespace data
- [ ] Document connection instructions for customers
- [ ] Add to pgTAP regression suite (GRANT + RLS assertions)

### Phase 2: Edge Function API (Future)

- [ ] Create `namespace_api_keys` table (Stuart — SQL Editor)
- [ ] Add GRANT + RLS + audit trigger
- [ ] Build `pbi-export` Edge Function
- [ ] Build API key management UI in namespace settings
- [ ] Rate limiting + audit logging
- [ ] Customer documentation

---

## 9. Security Model — Data Access Boundaries

### 9.1 Three-Layer Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: GetInSync RLS (our responsibility)                     │
│ ─────────────────────────────────────────────                   │
│ Enforced by PostgreSQL Row Level Security.                      │
│ All vw_pbi_* views use security_invoker = true.                 │
│ The authenticated user can ONLY see data in namespaces          │
│ where they are a member. Cross-namespace data is impossible.    │
│                                                                  │
│ Guarantee: No customer can ever see another customer's data.    │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: Service Account Role (our responsibility, customer's   │
│          choice)                                                 │
│ ─────────────────────────────────────────────                   │
│ The service account's role determines visibility WITHIN the     │
│ namespace:                                                       │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────┐     │
│ │ Namespace admin service account                         │     │
│ │ → Sees ALL workspaces (ministries) in the namespace     │     │
│ │ → "Open kimono" within the namespace boundary           │     │
│ │ → Typical for executive dashboards crossing ministries   │     │
│ └─────────────────────────────────────────────────────────┘     │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────┐     │
│ │ Workspace-scoped viewer service account                 │     │
│ │ → Sees ONLY workspaces they are a member of             │     │
│ │ → Useful for ministry-specific Power BI reports          │     │
│ │ → RLS naturally filters — no custom code needed          │     │
│ └─────────────────────────────────────────────────────────┘     │
│                                                                  │
│ Customer chooses the role at service account creation time.      │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: Presentation Security (customer's responsibility)      │
│ ─────────────────────────────────────────────                   │
│ Once data reaches Power BI, the CUSTOMER controls who sees      │
│ what using their existing tooling:                               │
│                                                                  │
│ • Power BI RLS — row-level roles filter by ministry column      │
│ • Power BI workspace access — who can view/edit the report      │
│ • SharePoint permissions — who can access the dashboard page    │
│ • Power Automate — which flows run and where data lands         │
│                                                                  │
│ GetInSync does NOT replicate the customer's internal org chart.  │
│ That is their Power BI RLS concern, not ours.                   │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 Typical Deployment: Saskatchewan Scenario

**Setup:**
1. GetInSync creates a namespace for Government of Saskatchewan
2. 25 workspaces (one per ministry) are created within that namespace
3. Customer requests Power BI access → Stuart provisions a service account with `admin` role

**What the service account sees:**
- All 488 applications across all 25 ministries
- All deployment profiles, technology tags, lifecycle data
- All contacts (owned by, supported by, managed by)
- All workspace names and IDs
- **Cannot see** data from any other namespace (e.g., City of Riverside)

**What the customer does in Power BI:**
- Creates Power BI RLS roles: "Agriculture" role filters `WHERE ministry = 'Agriculture'`
- Assigns users to roles: Ministry of Agriculture analysts get the Agriculture role
- Executive dashboards get no RLS filter → see everything (matches the service account's scope)
- Publishes to SharePoint with page-level permissions per ministry

**Security boundary summary:**

| What | Who Controls | How |
|------|-------------|-----|
| Cross-namespace isolation | GetInSync (RLS) | `security_invoker = true` + namespace membership |
| Within-namespace scope | Customer (service account role) | Admin = all workspaces, Viewer = assigned workspaces |
| Within-Power BI access | Customer (Power BI RLS) | Ministry column filtering, workspace access |
| SharePoint distribution | Customer (SharePoint permissions) | Page/list permissions per ministry |

### 9.3 Phase 2 Enhancement: Workspace-Scoped API Keys

For customers who want workspace-level segmentation at the API layer (e.g., each ministry gets its own API key that only returns their data):

```sql
-- Future: add workspace scoping to namespace_api_keys
ALTER TABLE namespace_api_keys
ADD COLUMN workspace_ids UUID[] DEFAULT '{}';
-- empty = all workspaces in the namespace
-- populated = only these workspaces
```

The Edge Function would add a workspace filter:
```typescript
if (keyRecord.workspace_ids.length > 0) {
  query = query.in('workspace_id', keyRecord.workspace_ids);
}
```

**Not needed for initial launch** — the admin-scoped service account + Power BI RLS covers the Saskatchewan use case. This becomes relevant when multiple departments within a customer want independent, isolated API access.

### 9.4 Credential Security

1. **Service account credentials** (Approach B) must be treated as secrets. Customers should use Power BI's credential store or Power Automate's secure inputs.
2. **API keys** (Approach A) are hashed at rest (bcrypt). Raw keys are shown only once at creation time.
3. **Rate limiting** prevents abuse. Default: 60 requests/hour per API key.
4. **View-level permissions** (Approach A) allow namespace admins to restrict which views an API key can access.
5. **Audit trail** — `last_used_at` on API keys + existing Supabase auth logs for service accounts.
6. **Key rotation** — API keys can be deactivated and new ones created without downtime (multiple active keys per namespace).
7. **Expiry** — API keys support optional `expires_at` for time-limited access (e.g., contractor engagement).

---

## 10. References

| Document | Relationship |
|----------|-------------|
| features/technology-health/dashboard.md | Native dashboard architecture — PBI views mirror these data models |
| infrastructure/edge-functions-layer-architecture.md | Shared scaffold for Edge Function API (Approach A) |
| identity-security/rls-policy.md | RLS patterns — PBI views must follow security_invoker pattern |
| operations/new-table-checklist.md | Checklist for namespace_api_keys table creation |
| planning/open-items-priority-matrix.md | Item #18 — "Power BI Foundation" |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-13 | Initial. 6 PBI views, 2 auth approaches (Edge Function API + Service Account), SharePoint integration pattern, deployment checklist. |
| v1.1 | 2026-03-15 | Added §9 three-layer security model: RLS namespace isolation → service account role scoping → customer-owned Power BI RLS. Saskatchewan deployment scenario. Workspace-scoped API keys (Phase 2 enhancement). |
