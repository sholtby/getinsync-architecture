# GetInSync NextGen — Visual Diagram Architecture (Phase 28c)

**Version:** 1.0  
**Date:** February 10, 2026  
**Status:** 🟡 SPEC — Not yet implemented

---

## Concept: Three-Level Walkable Visual

Each level is focused on ONE entity in the center. Users walk between 
levels by double-clicking nodes. Every level uses the same D3 component 
pattern: top tier → center → bottom tier.

```
Level 1: App Visual          Level 2: DP Visual           Level 3: Service Visual
─────────────────           ──────────────────           ─────────────────────
  Connected Apps              Parent Application           All DPs using this
  + External Systems              (one node)               service/product
       |                            |                           |
  [FOCUSED APP]              [FOCUSED DP]               [FOCUSED SERVICE]
       |                            |                           |
  Deployment                  Tech Stack:                  Vendor, Cost,
  Profiles                    Software, Services,          Budget info
                              Hosting, Cloud, DR
```

---

## Level 1: Application Visual (CURRENT — needs correction)

**Center node:** Application  
**Top tier:** Connected apps + external systems (from integrations)  
**Bottom tier:** Deployment Profiles (NOT tech stack)

### Bottom Tier DP Nodes

Each DP is a card-style node showing:
```
┌──────────────────────────────────┐
│ 🖥  Great Plains ERP             │
│    ● Production · Primary        │
│    📍 City Hall DC · 🇺🇸 USA     │
└──────────────────────────────────┘
```

**Fields displayed:**
- Line 1: DP name (bold)
- Line 2: Environment (with color dot) + "Primary" badge if is_primary
- Line 3: Data center name + country flag (if data_center_id set)
- If no data center: show hosting_type + cloud_provider instead

**DP node style:**
- Use ENTITY_STYLES.deployment_profile from icons.ts
- Icon: Server
- Fill: slate-100, stroke: slate-300

**Query for DPs:**
```sql
SELECT dp.id, dp.name, dp.environment, dp.is_primary,
       dp.hosting_type, dp.cloud_provider, dp.data_center_id,
       dc.name as dc_name, dc.city, dc.country_code
FROM deployment_profiles dp
LEFT JOIN data_centers dc ON dc.id = dp.data_center_id
WHERE dp.application_id = :applicationId
ORDER BY dp.is_primary DESC, dp.name;
```

**Interactions:**
- Double-click connected app → navigate to that app's Visual tab (existing)
- Double-click external system → no action (not walkable)
- Double-click DP node → navigate to Level 2 (DP Visual)
- Double-click center app → navigate to Connections tab (existing)

### What MOVES to Level 2:
- ❌ Software Products (currently bottom tier)
- ❌ IT Services (currently bottom tier)  
- ❌ Environment node (currently bottom tier)
- ❌ Hosting Type node (currently bottom tier)
- ❌ Cloud Provider node (currently bottom tier)
- ❌ DR Status node (currently bottom tier)

All of the above belong under the DP, not under the App.

---

## Level 2: Deployment Profile Visual (NEW)

**Route:** Same app detail page, but triggered by double-click on DP  
**Implementation:** Reuse ConnectionsVisual component with a mode prop  
or create a separate DPVisual component.

**Center node:** Deployment Profile
```
┌──────────────────────────────────┐
│ 🖥  Great Plains ERP             │
│    ● Production · Primary        │
│    📍 City Hall DC · 🇺🇸 USA     │
└──────────────────────────────────┘
```

**Top tier:** Parent application (single node)
```
┌──────────────────────────────────┐
│ 📱 Great Plains ERP              │
│    (Finance)                     │
└──────────────────────────────────┘
```
- Double-click → go back to Level 1 (App Visual)

**Bottom tier:** Tech stack — all technology linked to this DP

### Software Products (blue nodes)
```
┌──────────────────────────────────┐
│ 📦 Microsoft Dynamics GP         │
│    Software · v18.6 · Perpetual  │
└──────────────────────────────────┘
```
**Query:**
```sql
SELECT dpsp.*, sp.name, sp.version, sp.license_type
FROM deployment_profile_software_products dpsp
JOIN software_products sp ON sp.id = dpsp.software_product_id
WHERE dpsp.deployment_profile_id = :dpId;
```
- Double-click → navigate to Level 3 (Software Product Visual)

### IT Services (purple nodes)
```
┌──────────────────────────────────┐
│ ☰  Database Services             │
│    Built On · Per Instance       │
└──────────────────────────────────┘
```
**Query:**
```sql
SELECT dpis.*, its.name, its.cost_model
FROM deployment_profile_it_services dpis
JOIN it_services its ON its.id = dpis.it_service_id
WHERE dpis.deployment_profile_id = :dpId;
```
- Double-click → navigate to Level 3 (IT Service Visual)

### Infrastructure nodes (from DP fields directly)
- Environment: e.g., "Production" (green, with status dot)
- Hosting Type: e.g., "On-Premises" (slate, with flag if data center)
- Cloud Provider: e.g., "AWS · us-east-1" (sky blue)
- DR Status: e.g., "Backup Only" (orange)
- These are NOT walkable (no double-click)

### Bottom tier node order (left to right):
1. Software Products (blue)
2. IT Services (purple)  
3. Environment (green)
4. Hosting (slate)
5. Cloud Provider (sky, if present)
6. DR Status (orange, if present)

---

## Level 3: IT Service / Software Product Visual (NEW)

**Route:** New page or modal — `/it-services/:id/visual` or inline

**Center node:** IT Service or Software Product

### IT Service Visual:
```
Center: Database Services (IT Service)
Top:    All DPs that depend on it
Bottom: Vendor, cost model, budget
```

**Top tier query (blast radius):**
```sql
SELECT dpis.deployment_profile_id, dpis.relationship_type,
       dp.name as dp_name, dp.environment,
       a.name as app_name, a.id as app_id,
       w.name as workspace_name
FROM deployment_profile_it_services dpis
JOIN deployment_profiles dp ON dp.id = dpis.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
WHERE dpis.it_service_id = :serviceId
ORDER BY a.name;
```

**Top tier DP nodes show:**
- App name (bold) + DP name if not primary
- Workspace name (second line)
- Relationship badge: "Built On" or "Depends On"
- Double-click → navigate to Level 2 (DP Visual) or Level 1 (App Visual)

**Bottom tier: Service details**
- Vendor (if vendor_org_id set): organization name
- Cost model: fixed/per_user/per_instance/consumption/tiered
- Annual cost: formatted
- Budget: amount + status (if budget tracking enabled)

### Software Product Visual (same pattern):
```
Center: Microsoft Dynamics GP (Software Product)
Top:    All DPs running this product
Bottom: Manufacturer, license type, annual cost
```

**Top tier query:**
```sql
SELECT dpsp.deployment_profile_id, dpsp.deployed_version,
       dp.name as dp_name, dp.environment,
       a.name as app_name, a.id as app_id,
       w.name as workspace_name
FROM deployment_profile_software_products dpsp
JOIN deployment_profiles dp ON dp.id = dpsp.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
WHERE dpsp.software_product_id = :productId
ORDER BY a.name;
```

---

## Walk Navigation Summary

| From | Double-Click | Goes To |
|------|-------------|---------|
| Level 1 (App) | Connected app node | Level 1 of that app |
| Level 1 (App) | External system | No action |
| Level 1 (App) | DP node | Level 2 of that DP |
| Level 1 (App) | Center app | Connections tab |
| Level 2 (DP) | Parent app node | Level 1 of that app |
| Level 2 (DP) | Software product | Level 3 of that product |
| Level 2 (DP) | IT service | Level 3 of that service |
| Level 2 (DP) | Infra nodes | No action |
| Level 3 (Service) | DP/App node | Level 2 or Level 1 |
| Level 3 (Service) | Vendor node | No action |

---

## Implementation Sequence

### Step 1: Fix App Visual (Level 1 correction)
- Remove software products, IT services, infra from bottom tier
- Replace with DP nodes
- Add double-click on DP → Level 2 navigation

### Step 2: Build DP Visual (Level 2 — new)
- New component or mode in ConnectionsVisual
- Center: DP, Top: parent app, Bottom: tech stack
- Wire double-click navigation

### Step 3: Build Service/Product Visual (Level 3 — new)
- Blast radius view
- Center: service/product, Top: consuming DPs, Bottom: details
- Wire double-click navigation

### Step 4: Breadcrumb trail
- Show navigation path: App → DP → Service
- Click breadcrumb segments to jump back

---

## Shared Component Strategy

All three levels should share:
- Same D3 layout engine (three-tier vertical)
- Same pan/zoom behavior
- Same icon constants from icons.ts
- Same node rendering functions
- Same tooltip patterns
- Same legend bar

Differentiated by:
- Data queries (what to fetch)
- Node types in each tier
- Walk navigation targets
- Center node styling
