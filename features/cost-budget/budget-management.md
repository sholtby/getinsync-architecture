# features/cost-budget/budget-management.md
Budget Management Architecture with IT Service Budgets
Last updated: 2026-03-04

---

## 1. Overview

This document defines the budget management capabilities in GetInSync NextGen. As of v1.3, budget management extends to both Applications AND IT Services, enabling provider workspaces to track infrastructure budget health.

**Version History:**
- v1.4 (2026-03-04): Reconciliation — workspace_budgets table, threshold update, as-built views
- v1.3 (2026-01-31): Add IT Service budget tracking
- v1.2 (2026-01-15): Application budgets and workspace budgets
- v1.0: Initial version

---

## 2. Core Principle

**"Every dollar needs a home and an owner."**

Budget management enables organizations to:
- Track what they've allocated vs what they're actually spending
- Identify over-budget applications and services
- Forecast budget gaps before they become crises
- Support financial planning and rationalization decisions

---

## 3. Budget Hierarchy

```
Namespace Budget (not tracked in system)
│
├── Workspace Budget
│   ├── Application Budgets
│   │   └── Deployment Profile Costs (run rate)
│   │
│   └── IT Service Budgets (NEW v1.3)
│       └── IT Service Allocations (committed capacity)
│
└── Unallocated Budget = Workspace - (Apps + Services)
```

---

## 4. Schema

### 4.1 Application Budgets

```sql
ALTER TABLE applications
ADD COLUMN budget_amount numeric(12,2),
ADD COLUMN budget_fiscal_year integer DEFAULT 2025;
```

> **As-built (2026-03-04):** `budget_amount`, `budget_locked` (boolean), and `budget_notes` (text) exist on the `applications` table. `budget_fiscal_year` was NOT added — fiscal year tracking is at the workspace level via `workspace_budgets` table (see §4.3). The ALTER shown is partially implemented.

**Budget vs Run Rate:**
- `budget_amount`: What finance allocated for this application
- `budget_locked`: Whether the budget can be modified (boolean)
- Run rate: Sum of deployment profile costs (software + services + recurring)
- Status: Comparison of budget vs run rate

### 4.2 IT Service Budgets (NEW v1.3)

```sql
ALTER TABLE it_services
ADD COLUMN budget_amount numeric(12,2),
ADD COLUMN budget_fiscal_year integer DEFAULT 2025;
```

**Budget vs Committed:**
- `budget_amount`: Capacity budget for this IT Service
- Committed: Sum of allocations from deployment_profile_it_services
- Status: Comparison of budget vs committed

### 4.3 Workspace Budgets

> **As-built (2026-03-04):** The original spec called for `budget_amount` on the `workspaces` table. The actual implementation uses a separate `workspace_budgets` table, which is a superior design — it supports multi-year budget history and year-over-year comparison.

**What exists on `workspaces` table:**
- `budget_fiscal_year` (integer) — EXISTS
- `budget_notes` (text) — EXISTS
- `budget_amount` — does NOT exist (per CLAUDE.md: do NOT read from this column)

**`workspace_budgets` table (as-built, 9 columns):**

```sql
-- This is the actual table that stores workspace budget amounts
CREATE TABLE workspace_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id),
  fiscal_year INTEGER,
  budget_amount NUMERIC(12,2),
  actual_run_rate NUMERIC(12,2),
  budget_notes TEXT,
  is_current BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**Benefits of this design over the original spec:**
- Multi-year budget tracking (one row per workspace per fiscal year)
- `is_current` flag marks the active fiscal year
- `actual_run_rate` snapshot enables year-end variance analysis
- Year-over-year comparison via `vw_workspace_budget_history` (window functions)

**Workspace Budget Components:**
- **Consumer workspaces:** Sum of application budgets vs workspace budget
- **Provider workspaces:** Sum of IT Service budgets vs workspace budget
- **Mixed workspaces:** Sum of both application and service budgets

---

## 5. Budget Status Logic

### 5.1 Status Values

> **Updated (v1.4):** Thresholds aligned to as-built `vw_budget_status` view. The as-built thresholds give a wider "healthy" band and only flag "over_critical" at 110%+.

| Status | Condition | Color | Priority |
|--------|-----------|-------|----------|
| over_critical | >110% of budget | Red | 1 |
| over_10 | 100-110% of budget | Orange | 2 |
| tight | 80-100% of budget | Yellow | 3 |
| healthy | ≤80% of budget | Green | 4 |
| no_costs | No run rate data | Gray | 5 |
| no_budget | budget_amount IS NULL or 0 | Gray | 6 |

### 5.2 Application Budget Status

**Logic (as-built):**
```sql
CASE
  WHEN a.budget_amount IS NULL OR a.budget_amount = 0 THEN 'no_budget'
  WHEN run_rate IS NULL OR run_rate = 0 THEN 'no_costs'
  WHEN run_rate <= (a.budget_amount * 0.8) THEN 'healthy'
  WHEN run_rate <= a.budget_amount THEN 'tight'
  WHEN run_rate <= (a.budget_amount * 1.1) THEN 'over_10'
  ELSE 'over_critical'
END as budget_status
```

**Example:**
- Budget: $100,000
- Run rate: $95,000
- Status: `tight` (yellow — between 80% and 100%)

### 5.3 IT Service Budget Status (NEW v1.3)

**Logic:**
```sql
CASE
  WHEN its.budget_amount IS NULL THEN 'no_budget'
  WHEN committed > its.budget_amount THEN 'over_critical'
  WHEN committed > (its.budget_amount * 0.90) THEN 'over_10'
  WHEN committed > (its.budget_amount * 0.75) THEN 'under_25'
  ELSE 'healthy'
END as budget_status
```

**Committed Calculation:**
```sql
SUM(
  CASE dpis.allocation_basis
    WHEN 'percent' THEN 
      -- Handle legacy: >100 means dollars, ≤100 means percentage
      CASE 
        WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
        ELSE (its.annual_cost * dpis.allocation_value / 100)
      END
    WHEN 'fixed' THEN dpis.allocation_value
    ELSE 0
  END
) as committed
```

**Example:**
- Budget: $500,000
- Committed: $475,000 (multiple DPs allocating percentages)
- Status: `under_25` (yellow)

### 5.4 Workspace Budget Status

**Logic:**
```sql
CASE
  WHEN w.budget_amount IS NULL THEN 'no_budget'
  WHEN total_allocated > w.budget_amount THEN 'over_allocated'
  WHEN total_allocated > (w.budget_amount * 0.90) THEN 'under_10'
  ELSE 'healthy'
END as workspace_status
```

Where:
- `total_allocated = app_budget_allocated + service_budget_allocated`
- Consumer workspace: app_budget_allocated only
- Provider workspace: service_budget_allocated only
- Mixed workspace: both

**Example:**
- Workspace budget: $1,100,000
- App budgets: $600,000
- Service budgets: $1,060,000
- Total allocated: $1,660,000
- Status: `over_allocated` (red)

---

## 6. Views

### 6.1 vw_budget_status (Applications)

**Purpose:** Show budget health for each application.

> **As-built differs from original spec.** The view reads `budget_amount`, `budget_locked`, `budget_notes` from the `applications` table, uses `vw_application_run_rate` for cost data, includes `percent_used`, and filters by `operational_status = 'operational'`. Thresholds updated to 80/100/110% (see §5.1).

```sql
-- AS-BUILT view (simplified — see actual via pg_get_viewdef)
CREATE VIEW vw_budget_status AS
SELECT
  a.id as application_id,
  a.name as application_name,
  a.workspace_id,
  w.name as workspace_name,
  w.namespace_id,
  a.operational_status,
  COALESCE(a.budget_amount, 0) as budget,
  a.budget_locked,
  a.budget_notes,
  COALESCE(rr.total_run_rate, 0) as committed,
  COALESCE(a.budget_amount, 0) - COALESCE(rr.total_run_rate, 0) as remaining,
  CASE
    WHEN a.budget_amount IS NULL OR a.budget_amount = 0 THEN 'no_budget'
    WHEN rr.total_run_rate IS NULL OR rr.total_run_rate = 0 THEN 'no_costs'
    WHEN rr.total_run_rate <= (a.budget_amount * 0.8) THEN 'healthy'
    WHEN rr.total_run_rate <= a.budget_amount THEN 'tight'
    WHEN rr.total_run_rate <= (a.budget_amount * 1.1) THEN 'over_10'
    ELSE 'over_critical'
  END as budget_status,
  CASE
    WHEN a.budget_amount IS NULL OR a.budget_amount = 0 THEN NULL
    ELSE round(COALESCE(rr.total_run_rate, 0) / a.budget_amount * 100, 1)
  END as percent_used
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN vw_application_run_rate rr ON rr.application_id = a.id
WHERE a.operational_status = 'operational';
```

**Usage:**
```sql
-- Applications over budget
SELECT * FROM vw_budget_status 
WHERE budget_status = 'over_critical'
ORDER BY run_rate - budget_amount DESC;

-- Applications approaching budget limit
SELECT * FROM vw_budget_status 
WHERE budget_status IN ('over_10', 'under_25')
ORDER BY budget_status, remaining;
```

### 6.2 vw_it_service_budget_status (NEW v1.3)

**Purpose:** Show budget health for IT Services.

```sql
CREATE VIEW vw_it_service_budget_status AS
SELECT 
  its.id as it_service_id,
  its.name as service_name,
  its.owner_workspace_id as workspace_id,
  its.budget_amount,
  its.budget_fiscal_year,
  COALESCE(SUM(
    CASE dpis.allocation_basis
      WHEN 'percent' THEN 
        CASE 
          WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
          ELSE (its.annual_cost * dpis.allocation_value / 100)
        END
      WHEN 'fixed' THEN dpis.allocation_value
      ELSE 0
    END
  ), 0) as committed,
  its.budget_amount - COALESCE(SUM(
    CASE dpis.allocation_basis
      WHEN 'percent' THEN 
        CASE 
          WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
          ELSE (its.annual_cost * dpis.allocation_value / 100)
        END
      WHEN 'fixed' THEN dpis.allocation_value
      ELSE 0
    END
  ), 0) as remaining,
  CASE
    WHEN its.budget_amount IS NULL THEN 'no_budget'
    WHEN COALESCE(SUM(
      CASE dpis.allocation_basis
        WHEN 'percent' THEN 
          CASE 
            WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
            ELSE (its.annual_cost * dpis.allocation_value / 100)
          END
        WHEN 'fixed' THEN dpis.allocation_value
        ELSE 0
      END
    ), 0) > its.budget_amount THEN 'over_critical'
    WHEN COALESCE(SUM(
      CASE dpis.allocation_basis
        WHEN 'percent' THEN 
          CASE 
            WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
            ELSE (its.annual_cost * dpis.allocation_value / 100)
          END
        WHEN 'fixed' THEN dpis.allocation_value
        ELSE 0
      END
    ), 0) > (its.budget_amount * 0.90) THEN 'over_10'
    WHEN COALESCE(SUM(
      CASE dpis.allocation_basis
        WHEN 'percent' THEN 
          CASE 
            WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
            ELSE (its.annual_cost * dpis.allocation_value / 100)
          END
        WHEN 'fixed' THEN dpis.allocation_value
        ELSE 0
      END
    ), 0) > (its.budget_amount * 0.75) THEN 'under_25'
    ELSE 'healthy'
  END as budget_status
FROM it_services its
LEFT JOIN deployment_profile_it_services dpis ON dpis.it_service_id = its.id
GROUP BY its.id, its.name, its.owner_workspace_id, its.budget_amount, 
         its.budget_fiscal_year, its.annual_cost;
```

**Usage:**
```sql
-- Services over capacity
SELECT * FROM vw_it_service_budget_status 
WHERE budget_status = 'over_critical'
ORDER BY committed - budget_amount DESC;

-- Services with no budget set
SELECT * FROM vw_it_service_budget_status 
WHERE budget_status = 'no_budget' AND committed > 0;
```

### 6.3 vw_workspace_budget_summary (Updated v1.4)

**Purpose:** Show budget health for entire workspace, including both applications and IT Services.

> **As-built differs from original spec.** The actual view reads workspace budget from `workspace_budgets` table (not `workspaces.budget_amount`), includes `budget_fiscal_year`, and adds `no_costs` status. The spec SQL below is retained for reference but does not match production.

```sql
-- SPEC ONLY — as-built reads from workspace_budgets table, not workspaces.budget_amount
-- See vw_workspace_budget_summary via pg_get_viewdef for actual definition
CREATE VIEW vw_workspace_budget_summary AS
...
```

**As-built return columns** (from `src/types/view-contracts.ts`):
- `workspace_id`, `workspace_name`, `namespace_id`
- `workspace_budget` (from workspace_budgets.budget_amount)
- `budget_fiscal_year`
- `app_budget_allocated`, `app_run_rate`
- `service_budget_allocated`, `service_run_rate`
- `total_allocated`, `unallocated`
- `workspace_status` ('no_budget' | 'no_costs' | 'healthy' | 'tight' | 'over')

### 6.4 Additional As-Built Views and Tables (not in original spec)

The following budget infrastructure was built beyond the original v1.3 spec:

**`budget_transfers` table (14 columns):**

Supports inter-application AND inter-service budget transfers with approval workflow.

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | PK |
| workspace_id | UUID | FK to workspaces |
| fiscal_year | INTEGER | Budget year |
| from_application_id | UUID | Source app (nullable) |
| to_application_id | UUID | Destination app (nullable) |
| from_it_service_id | UUID | Source service (nullable) |
| to_it_service_id | UUID | Destination service (nullable) |
| amount | NUMERIC | Transfer amount |
| reason | TEXT | Justification |
| transferred_by | UUID | Who initiated |
| transferred_at | TIMESTAMPTZ | When initiated |
| approved_by | UUID | Who approved |
| approved_at | TIMESTAMPTZ | When approved |
| created_at | TIMESTAMPTZ | Audit |

**`vw_budget_alerts`:**
Built on top of `vw_budget_status`. Adds `alert_type` (over_budget, nearly_exhausted, significant_unbudgeted) and `alert_priority` (1–5). Uses hardcoded thresholds: $5,000 for nearly_exhausted, $10,000 for significant_unbudgeted.

**`vw_workspace_budget_history`:**
Year-over-year comparison using window functions over `workspace_budgets`. Returns variance, variance_percent, prior_year_budget, prior_year_actual, budget_yoy_change.

**`vw_budget_transfer_history`:**
Transfer audit trail joining budget_transfers with application names and user emails. Note: currently ignores `from_it_service_id` / `to_it_service_id` columns (IT service transfers not yet displayed).

**Usage:**
```sql
-- Workspaces over budget
SELECT * FROM vw_workspace_budget_summary 
WHERE workspace_status = 'over_allocated';

-- Provider workspaces (have service budgets)
SELECT * FROM vw_workspace_budget_summary 
WHERE service_budget_allocated > 0
ORDER BY service_run_rate DESC;

-- Consumer workspaces (have app budgets)
SELECT * FROM vw_workspace_budget_summary 
WHERE app_budget_allocated > 0
ORDER BY app_run_rate DESC;
```

---

## 7. Functions

### 7.1 initialize_application_budgets()

**Purpose:** Set application budgets to 110% of current run rate for apps without budgets.

```sql
CREATE FUNCTION initialize_application_budgets(
  p_workspace_id uuid,
  p_fiscal_year integer DEFAULT 2025
)
RETURNS TABLE(
  application_id uuid,
  application_name text,
  current_run_rate numeric,
  new_budget numeric,
  status text
) AS $$
BEGIN
  -- Update applications without budgets
  UPDATE applications a
  SET 
    budget_amount = ROUND((
      SELECT COALESCE(SUM(dpc.total_cost), 0) * 1.10
      FROM vw_deployment_profile_costs dpc
      WHERE dpc.application_id = a.id
        AND dpc.dp_type = 'application'
    ), 2),
    budget_fiscal_year = p_fiscal_year
  WHERE a.workspace_id = p_workspace_id
    AND a.budget_amount IS NULL;
  
  -- Return initialized applications
  RETURN QUERY
  SELECT 
    a.id,
    a.name,
    COALESCE(SUM(dpc.total_cost), 0) as run_rate,
    a.budget_amount as budget,
    CASE 
      WHEN COALESCE(SUM(dpc.total_cost), 0) = 0 THEN 'no_costs'
      ELSE 'initialized'
    END as status
  FROM applications a
  LEFT JOIN vw_deployment_profile_costs dpc ON dpc.application_id = a.id
    AND dpc.dp_type = 'application'
  WHERE a.workspace_id = p_workspace_id
    AND a.budget_fiscal_year = p_fiscal_year
  GROUP BY a.id, a.name, a.budget_amount;
END;
$$ LANGUAGE plpgsql;
```

**Usage:**
```sql
-- Initialize all apps in a workspace
SELECT * FROM initialize_application_budgets('workspace-uuid', 2025);
```

### 7.2 initialize_it_service_budgets() (NEW v1.3)

**Purpose:** Set IT Service budgets to 110% of current committed allocations for services without budgets.

```sql
CREATE FUNCTION initialize_it_service_budgets(
  p_workspace_id uuid,
  p_fiscal_year integer DEFAULT 2025
)
RETURNS TABLE(
  it_service_id uuid,
  service_name text,
  current_committed numeric,
  new_budget numeric,
  status text
) AS $$
BEGIN
  -- Update IT Services without budgets
  UPDATE it_services its
  SET 
    budget_amount = ROUND((
      SELECT COALESCE(SUM(
        CASE dpis.allocation_basis
          WHEN 'percent' THEN 
            CASE 
              WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
              ELSE (its.annual_cost * dpis.allocation_value / 100)
            END
          WHEN 'fixed' THEN dpis.allocation_value
          ELSE 0
        END
      ), 0) * 1.10
      FROM deployment_profile_it_services dpis
      WHERE dpis.it_service_id = its.id
    ), 2),
    budget_fiscal_year = p_fiscal_year
  WHERE its.owner_workspace_id = p_workspace_id
    AND its.budget_amount IS NULL;
  
  -- Return initialized services
  RETURN QUERY
  SELECT 
    its.id,
    its.name,
    COALESCE(SUM(
      CASE dpis.allocation_basis
        WHEN 'percent' THEN 
          CASE 
            WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
            ELSE (its.annual_cost * dpis.allocation_value / 100)
          END
        WHEN 'fixed' THEN dpis.allocation_value
        ELSE 0
      END
    ), 0) as committed,
    its.budget_amount as budget,
    CASE 
      WHEN COALESCE(SUM(
        CASE dpis.allocation_basis
          WHEN 'percent' THEN 
            CASE 
              WHEN dpis.allocation_value > 100 THEN dpis.allocation_value
              ELSE (its.annual_cost * dpis.allocation_value / 100)
            END
          WHEN 'fixed' THEN dpis.allocation_value
          ELSE 0
        END
      ), 0) = 0 THEN 'no_costs'
      ELSE 'initialized'
    END as status
  FROM it_services its
  LEFT JOIN deployment_profile_it_services dpis ON dpis.it_service_id = its.id
  WHERE its.owner_workspace_id = p_workspace_id
    AND its.budget_fiscal_year = p_fiscal_year
  GROUP BY its.id, its.name, its.budget_amount;
END;
$$ LANGUAGE plpgsql;
```

**Usage:**
```sql
-- Initialize all services in a workspace
SELECT * FROM initialize_it_service_budgets('central-it-workspace-uuid', 2025);
```

---

## 8. UI Components

### 8.1 Budget Settings Page

**Location:** Settings → Budget

**Features:**
- Workspace budget input at top
- Tab switcher: "Applications" | "IT Services"
- Initialize button per tab
- Table showing budget vs run rate/committed
- Status indicators (colored badges)

**Applications Tab:**
- Shows all applications in workspace
- Columns: Name, Budget, Run Rate, Remaining, Status
- Initialize button: "Set Budgets to 110% of Run Rate"

**IT Services Tab (NEW v1.3):**
- Shows all IT Services owned by workspace
- Columns: Name, Budget, Committed, Remaining, Status
- Initialize button: "Set Budgets to 110% of Committed"
- Only visible in provider workspaces (workspaces that own IT Services)

### 8.2 BudgetHealthCard Widget

**Purpose:** Show count of budget alerts on dashboard.

**Display:**
- Total items with budget issues
- Count by status (over_critical, over_10, under_25)
- Click to filter dashboard by budget status

**Updated Logic (v1.3):**
```typescript
// Count both application AND IT Service budget alerts
const { data: appAlerts } = await supabase
  .from('vw_budget_status')
  .select('application_id')
  .eq('workspace_id', currentWorkspaceId)
  .in('budget_status', ['over_critical', 'over_10', 'under_25']);

const { data: serviceAlerts } = await supabase
  .from('vw_it_service_budget_status')
  .select('it_service_id')
  .eq('workspace_id', currentWorkspaceId)
  .in('budget_status', ['over_critical', 'over_10', 'under_25']);

const totalAlerts = (appAlerts?.length || 0) + (serviceAlerts?.length || 0);
```

**Display:**
```
Budget Health
12 items need attention

Over Budget: 3
Approaching Limit: 7
Under 25%: 2
```

---

## 9. Business Rules

### 9.1 Budget Initialization

**110% Buffer Rationale:**
- Provides small cushion for growth
- Accounts for cost variance and fluctuation
- Prevents immediate "over budget" status
- Can be adjusted manually after initialization

### 9.2 Budget Allocation

**Workspace Budget >= Sum of App/Service Budgets:**
- Workspace budget should be sufficient for all allocations
- Unallocated budget = workspace budget - total allocated
- Negative unallocated = workspace is over-allocated

### 9.3 Consumer vs Provider Workspaces

**Consumer Workspaces:**
- Manage application budgets
- Track run rate against budgets
- Allocate to IT Services (creates committed on provider side)

**Provider Workspaces:**
- Manage IT Service budgets
- Track committed allocations against budgets
- Cannot create applications (typically)

**Mixed Workspaces:**
- Both applications and IT Services
- Total budget covers both types
- Example: Central IT owns services AND applications

---

## 10. Reporting & Analytics

### 10.1 Budget Variance Report

```sql
-- Applications with largest budget variance
SELECT 
  application_name,
  budget_amount,
  run_rate,
  (run_rate - budget_amount) as variance,
  ROUND((run_rate / NULLIF(budget_amount, 0) - 1) * 100, 1) as percent_variance
FROM vw_budget_status
WHERE budget_amount IS NOT NULL
ORDER BY ABS(run_rate - budget_amount) DESC
LIMIT 20;
```

### 10.2 Capacity Utilization Report (IT Services)

```sql
-- IT Services by capacity utilization
SELECT 
  service_name,
  budget_amount as capacity,
  committed as utilized,
  remaining as available,
  ROUND((committed / NULLIF(budget_amount, 0)) * 100, 1) as utilization_percent,
  budget_status
FROM vw_it_service_budget_status
WHERE budget_amount IS NOT NULL
ORDER BY utilization_percent DESC;
```

### 10.3 Workspace Budget Summary

```sql
-- All workspaces with budget summary
SELECT 
  workspace_name,
  workspace_budget,
  app_budget_allocated,
  service_budget_allocated,
  total_allocated,
  unallocated,
  workspace_status
FROM vw_workspace_budget_summary
WHERE workspace_budget IS NOT NULL
ORDER BY workspace_status, total_allocated DESC;
```

---

## 11. Integration with Other Features

### 11.1 TIME/PAID Assessments

**Budget status informs rationalization decisions:**
- Applications in "Eliminate" quadrant + over budget = priority candidates
- Applications in "Invest" quadrant + under budget = opportunity to scale

**Query:**
```sql
SELECT a.name, dp.time_action, bs.budget_status, bs.run_rate, bs.budget_amount
FROM applications a
JOIN deployment_profiles dp ON dp.application_id = a.id AND dp.is_primary = true
LEFT JOIN vw_budget_status bs ON bs.application_id = a.id
WHERE dp.time_action = 'Eliminate' AND bs.budget_status = 'over_critical';
```

### 11.2 Cost Optimization

**IT Services with low utilization = consolidation opportunities:**
```sql
-- Services with <50% utilization
SELECT * FROM vw_it_service_budget_status
WHERE (committed / NULLIF(budget_amount, 0)) < 0.50
  AND budget_amount > 50000
ORDER BY budget_amount - committed DESC;
```

---

## 12. Future Enhancements

### 12.1 Multi-Year Budgets — DEPLOYED

> Implemented via `workspace_budgets` table (see §4.3) and `vw_workspace_budget_history` view (see §6.4). Supports year-over-year comparison, variance analysis, and budget_yoy_change.

- ~~Track budget_amount by fiscal year~~ DONE
- ~~Compare year-over-year trends~~ DONE (vw_workspace_budget_history)
- Forecast future years based on run rate — FUTURE

### 12.2 Budget Alerts — DEPLOYED (Phase 1)

> Implemented via `alert_preferences` table with namespace seeding trigger. See `features/cost-budget/budget-alerts.md` for full architecture. `vw_budget_alerts` view generates alerts from `vw_budget_status`.

- ~~Configurable alert rules per workspace~~ DONE (alert_preferences)
- Email notifications — FUTURE (Phase 2/3)
- Slack integration — FUTURE (Phase 3)

### 12.3 Budget Approvals
- Workflow for budget increase requests
- Approval chain (workspace admin → finance)
- Audit trail of budget changes

---

## Related Documents

| Document | Content |
|----------|---------|
| features/cost-budget/cost-model.md | Cost flow and allocation |
| core/deployment-profile.md | Run rate calculation |
| catalogs/it-service.md | IT Services and allocations |
| features/cost-budget/budget-alerts.md | Alert configuration |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.4 | 2026-03-04 | Reconciled with production schema (dump 2026-03-03). §4.1: application budget columns clarified (budget_locked, budget_notes exist; budget_fiscal_year not added). §4.3: corrected to workspace_budgets table (workspaces.budget_amount does not exist). §5.1: thresholds updated to as-built (80/100/110%, added tight and no_costs statuses). §6.1: vw_budget_status SQL updated to match as-built. §6.3: noted as-built reads from workspace_budgets. §6.4: new section documenting budget_transfers, vw_budget_alerts, vw_workspace_budget_history, vw_budget_transfer_history. §12.1: marked DEPLOYED. §12.2: marked DEPLOYED with cross-reference to budget-alerts.md. |
| v1.3 | 2026-01-31 | Add IT Service budget tracking, vw_it_service_budget_status, initialize_it_service_budgets(), update vw_workspace_budget_summary |
| v1.2 | 2026-01-15 | Application budgets, workspace budgets, initialize function |
| v1.0 | 2025-12-10 | Initial version |

---

*Document: features/cost-budget/budget-management.md*
*January 2026*
