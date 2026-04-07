# COR Demo Data — Cost Seeding Plan

## Context

The COR (City of Riverside) demo namespace has IT Services with realistic costs ($2.98M total across 11 services) but **zero cost allocation** to individual applications. The `deployment_profile_it_services.allocation_value` is NULL on all 56 rows, so every app's Cost Summary shows "$0" for IT Services. Additionally, 10 SaaS/Cloud apps are missing cost bundles entirely.

**Goal:** Every COR app should show a non-zero Total Run Rate in its Cost Summary so demos look realistic.

## Current State

### Cost paths in the data model
1. **Cost Bundles** (SaaS apps) — direct annual cost on a `cost_bundle` DP → shows in "Recurring Costs"
2. **IT Service allocation** (on-prem/hybrid apps) — `dpis.allocation_value` percentage of IT Service `annual_cost` → shows in "IT Services"
3. **Software Products** — `deployment_profile_technology_products.annual_cost` → shows in "Software Products" (all currently $0, out of scope)

### What's missing
| Gap | Count | Fix |
|-----|-------|-----|
| SaaS/Cloud apps with no cost bundle | 10 | Create cost_bundle DPs with realistic annual costs |
| IT Service allocations all NULL | 56 rows | Set allocation_value (percentage) on each dpis row |

---

## Plan

### Part 1: Cost Bundles for SaaS/Cloud Apps (10 apps)

Create a `cost_bundle` DP for each SaaS/Cloud app that doesn't have one. Costs based on typical municipal SaaS pricing.

| App | Hosting | Annual Cost | Vendor |
|-----|---------|-------------|--------|
| Accela Civic Platform | SaaS | $75,000 | (no org — skip vendor) |
| CivicPlus Website | SaaS | $12,000 | (no org) |
| CopLogic Online Reporting | SaaS | $8,000 | (no org) |
| Microsoft 365 | SaaS | $0 | Skip — costs flow through M365 Enterprise IT Service |
| NEOGOV | SaaS | $22,000 | (no org) |
| NG911 System | Cloud | $180,000 | (no org) |
| Questica Budget | SaaS | $35,000 | (no org) |
| Samsara Fleet | SaaS | $15,000 | (no org) |
| SeeClickFix | SaaS | $18,000 | (no org) |
| Sensus FlexNet | SaaS | $45,000 | (no org) |

**Microsoft 365 note:** This app's cost comes through the M365 Enterprise IT Service ($1.038M, per_user allocation). Adding a cost bundle would double-count. Set IT Service allocation instead.

**SQL pattern per app:**
```sql
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, dp_type, annual_cost, environment)
VALUES (gen_random_uuid(), (SELECT id FROM applications WHERE name = 'X' AND workspace_id IN (...)), workspace_id, 'X — SaaS License', 'cost_bundle', NNNN, 'Production');
```

### Part 2: IT Service Cost Allocations (56 dpis rows)

Set `allocation_value` (percentage) and `allocation_basis` ('percent') on each `deployment_profile_it_services` row. The formula: `app_cost_from_service = service.annual_cost * (allocation_value / 100)`.

**Allocation strategy by cost_model:**

| Cost Model | Service | Annual Cost | Allocation Logic |
|------------|---------|-------------|-----------------|
| per_instance | Windows Server Hosting | $180,000 | Equal split across 10 consumers → 10% each |
| per_instance | SQL Server Database Services | $120,000 | Equal split across 7 consumers → ~14% each |
| per_instance | Oracle Database Services | $95,000 | Equal split across 1 consumer → 100% (Cayenta only) |
| per_instance | GIS Platform | $100,000 | 1 consumer → 100% (Esri ArcGIS) |
| per_user | Identity & Access Management | $327,000 | Split by org size: large apps 15%, medium 10%, small 5% |
| per_user | Collaboration & Conferencing | $24,000 | 50% each to 2 consumers |
| per_user | Microsoft 365 Enterprise | $1,038,000 | 50% each to 2 consumers |
| consumption | Azure Cloud Hosting | $500,000 | Split by resource intensity: Esri 40%, Emergency 30%, NG911 30% |
| fixed | Enterprise Backup & Recovery | $142,000 | Equal split across 4 consumers → 25% each |
| fixed | Network Infrastructure | $250,000 | 0 consumers (overhead) — no allocation needed |
| fixed | Cybersecurity Operations | $200,000 | 0 consumers (overhead) — no allocation needed |

**SQL pattern:**
```sql
UPDATE deployment_profile_it_services
SET allocation_value = NN, allocation_basis = 'percent'
WHERE deployment_profile_id = (SELECT id FROM deployment_profiles WHERE application_id = (SELECT id FROM applications WHERE name = 'X' AND ...) AND is_primary = true)
AND it_service_id = (SELECT id FROM it_services WHERE name = 'Y' AND namespace_id = '...');
```

### Part 3: Detailed Allocation Table

**Windows Server Hosting ($180K, per_instance, 10 consumers):**
| App | Allocation |
|-----|-----------|
| Active Directory Services | 10% |
| Cayenta Financials | 10% |
| Computer-Aided Dispatch | 10% |
| Emergency Response System | 10% |
| Esri ArcGIS Enterprise | 10% |
| Fire Records Management | 10% |
| Hexagon OnCall CAD/RMS | 10% |
| Hyland OnBase | 10% |
| Kronos Workforce Central | 10% |
| Microsoft Dynamics GP | 10% |

**SQL Server Database Services ($120K, per_instance, 7 consumers):**
| App | Allocation |
|-----|-----------|
| Computer-Aided Dispatch | 15% |
| Esri ArcGIS Enterprise | 15% |
| Fire Records Management | 15% |
| Hexagon OnCall CAD/RMS | 15% |
| Hyland OnBase | 15% |
| Kronos Workforce Central | 15% |
| Police Records Management | 10% |

**Oracle Database Services ($95K, per_instance, 1 consumer):**
| App | Allocation |
|-----|-----------|
| Cayenta Financials | 100% |

**GIS Platform ($100K, per_instance, 1 consumer):**
| App | Allocation |
|-----|-----------|
| Esri ArcGIS Enterprise | 100% |

**Identity & Access Management ($327K, per_user):**
| App | Allocation |
|-----|-----------|
| Accela Civic Platform | 10% |
| CivicPlus Website | 5% |
| CopLogic Online Reporting | 5% |
| Hexagon OnCall CAD/RMS | 15% |
| Kronos Workforce Central | 15% |
| NEOGOV | 10% |

**Collaboration & Conferencing ($24K, per_user, 2 consumers):**
| App | Allocation |
|-----|-----------|
| Microsoft 365 | 50% |
| Microsoft Dynamics GP | 50% |

**Microsoft 365 Enterprise ($1.038M, per_user, 2 consumers):**
| App | Allocation |
|-----|-----------|
| Microsoft 365 | 50% |
| Microsoft Dynamics GP | 50% |

**Azure Cloud Hosting ($500K, consumption, 3 consumers):**
| App | Allocation |
|-----|-----------|
| Esri ArcGIS Enterprise | 40% |
| Emergency Response System | 30% |
| NG911 System (if linked) | 30% |

Note: NG911 is Cloud-hosted but not currently linked to Azure Cloud Hosting IT Service. Need to check if it should be.

**Enterprise Backup & Recovery ($142K, fixed, 4 consumers):**
| App | Allocation |
|-----|-----------|
| Cayenta Financials | 25% |
| Fire Records Management | 25% |
| Hexagon OnCall CAD/RMS | 25% |
| Hyland OnBase | 25% |

**Remaining services with dpis links:**
| Service | App | Allocation |
|---------|-----|-----------|
| PRTG Network Monitor | Identity & Access Management | 5% |
| Questica Budget | Identity & Access Management | 5% |
| Sage 300 GL | Oracle Database Services or Windows Server Hosting | 10% each |
| SeeClickFix | Identity & Access Management | 5% |
| ServiceDesk Plus | Windows Server Hosting | (already counted above) |
| Tyler Incode Court | SQL Server Database Services + Windows Server Hosting | 10% each |

Wait — reviewing the dpis data again:

Additional links not yet covered:
- PRTG Network Monitor → Identity & Access Management (5%)
- Questica Budget → Identity & Access Management (5%)
- Sage 300 GL → Oracle Database Services (50%) + Windows Server Hosting (already in 10%)
- SeeClickFix → Identity & Access Management (5%)
- Samsara Fleet → Identity & Access Management (5%)
- Sensus FlexNet → Identity & Access Management (5%)
- ServiceDesk Plus → Windows Server Hosting (already in 10%)
- Tyler Incode Court → SQL Server Database Services + Windows Server Hosting (10% each)

### Execution

1. Stuart reviews the cost numbers for realism
2. Generate a single SQL script with all INSERTs (cost bundles) and UPDATEs (allocations)
3. Stuart runs in SQL Editor
4. Validate: spot-check 3-4 apps in the UI — Cost Summary should show non-zero totals
5. No code changes needed — the `ApplicationCostSummary` component already reads `allocation_value`

### Namespace Guard

All SQL scoped to: `namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'`

---

## Verification

1. Open Hexagon OnCall CAD/RMS → Deployments & Costs → Cost Summary should show:
   - IT Services: Windows Server Hosting (10% of $180K = $18K), SQL Server DB (15% of $120K = $18K), Enterprise Backup (25% of $142K = $35.5K), IAM (15% of $327K = $49K) → ~$120K total
   - Total Run Rate: ~$120K
2. Open Microsoft 365 → should show IT Services from M365 Enterprise + Collab & Conferencing
3. Open Accela Civic Platform → should show both cost bundle ($75K) and IAM allocation
4. IT Spend dashboard totals should still reconcile (no double-counting)
