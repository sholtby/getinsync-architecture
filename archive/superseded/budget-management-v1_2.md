# gis-budget-management-architecture-v1.2
Budget Management & Run Rate Tracking
Last updated: 2026-01-28

---

## 1. Purpose

> **"How much do I have left? Can I borrow from that pot?"**

This document defines the architecture for tracking IT budgets against run rate, enabling reallocation between applications and IT services, and providing audit trails for budget movements.

**The Problem We Solve:** The "ninja spreadsheet" — multiple Excel files with budget tracking, no audit trail, manual updates, formula errors, and the eternal question "which version is current?"

**Core Principle:** Budget is a constraint. Run rate is reality. The gap is either opportunity or problem.

**Scope:**
- Workspace-level budget pools
- Application-level budget allocations (consumer workspaces)
- IT Service-level budget allocations (provider workspaces)
- Budget vs. committed (run rate) comparison
- Budget transfers with audit trail
- Dashboard widgets and reports

**Audience:** Internal architects, developers, and implementers.

---

## 2. Key Concepts

### Definitions

| Term | Definition | Source |
|------|------------|--------|
| **Budget** | What you're allowed to spend | Set by user |
| **Committed** | Run rate (contracts, licenses, services) | Calculated from cost model |
| **Remaining** | Budget minus Committed | Calculated |
| **Unallocated** | Workspace budget not assigned to apps/services | Calculated |

### The Hierarchy (Two Models)

**Consumer Workspace (e.g., Ministry of Finance):**
```
Workspace Budget Pool (Total IT Budget)
    ├── Application Budget (allocated portion)
    ├── Application Budget (allocated portion)
    ├── Application Budget (allocated portion)
    └── Unallocated Reserve
```

**Provider Workspace (e.g., Central IT):**
```
Workspace Budget Pool (Total IT Budget)
    ├── IT Service Budget (Azure Cloud Platform)
    ├── IT Service Budget (VMware Cluster)
    ├── IT Service Budget (Network Infrastructure)
    └── Unallocated Reserve
```

**Hybrid Workspace (rare):**
```
Workspace Budget Pool
    ├── Application Budgets (if they consume apps)
    ├── IT Service Budgets (if they provide services)
    └── Unallocated Reserve
```

### Budget vs. Run Rate

| Concept | Question | Update Frequency |
|---------|----------|------------------|
| **Budget** | How much CAN we spend? | Annually (or when revised) |
| **Run Rate** | How much ARE we spending? | Real-time (from cost model) |
| **Variance** | Are we over or under? | Real-time (calculated) |

---

## 3. Integration with Cost Model

Budget management depends on the run rate calculations from `gis-vendor-cost-architecture-v1.0`:

### Run Rate Definition

**Run Rate** = Operational applications/services + Recurring costs only

```sql
WHERE (application.operational_status = 'operational' OR it_service.operational_status = 'operational')
  AND (dp.dp_type != 'cost_bundle' OR dp.cost_recurrence = 'recurring')
```

### Three Cost Channels

| Channel | Included in Run Rate |
|---------|---------------------|
| Software Products | Always (recurring by nature) |
| IT Services | Always (recurring by nature) |
| Cost Bundles | Only if `cost_recurrence = 'recurring'` |

### Dependencies

- Application budgets use `vw_application_run_rate`
- IT Service budgets use IT Service total_annual_cost

---

## 4. Schema

### 4.1 Workspace Budget

```sql
-- ============================================
-- WORKSPACE BUDGET (The Total Pot)
-- ============================================

ALTER TABLE workspaces
ADD COLUMN budget_fiscal_year INTEGER;

ALTER TABLE workspaces
ADD COLUMN budget_amount DECIMAL(12,2);

ALTER TABLE workspaces
ADD COLUMN budget_notes TEXT;

-- Comments
COMMENT ON COLUMN workspaces.budget_fiscal_year IS 
'Fiscal year for the budget (e.g., 2026). NULL if no budget set.';

COMMENT ON COLUMN workspaces.budget_amount IS 
'Total IT budget for this workspace for the fiscal year.';

COMMENT ON COLUMN workspaces.budget_notes IS 
'Notes about the budget (assumptions, constraints, etc.).';
```

### 4.2 Application Budget

```sql
-- ============================================
-- APPLICATION BUDGET (Consumer Workspaces)
-- ============================================

ALTER TABLE applications
ADD COLUMN budget_amount DECIMAL(12,2) DEFAULT 0;

ALTER TABLE applications
ADD COLUMN budget_locked BOOLEAN DEFAULT false;

ALTER TABLE applications
ADD COLUMN budget_notes TEXT;

-- Comments
COMMENT ON COLUMN applications.budget_amount IS 
'Budget allocated to this application from the workspace pool. Used by consumer workspaces (ministries, departments).';

COMMENT ON COLUMN applications.budget_locked IS 
'If true, budget cannot be reallocated without admin override.';

COMMENT ON COLUMN applications.budget_notes IS 
'Notes about this application budget.';
```

### 4.3 IT Service Budget (NEW in v1.2)

```sql
-- ============================================
-- IT SERVICE BUDGET (Provider Workspaces)
-- ============================================

ALTER TABLE it_services
ADD COLUMN budget_amount DECIMAL(12,2) DEFAULT 0;

ALTER TABLE it_services
ADD COLUMN budget_locked BOOLEAN DEFAULT false;

ALTER TABLE it_services
ADD COLUMN budget_notes TEXT;

-- Comments
COMMENT ON COLUMN it_services.budget_amount IS 
'Budget allocated to this IT Service from the workspace pool. Used by provider workspaces (Central IT, infrastructure teams) to budget for platforms and shared services they operate.';

COMMENT ON COLUMN it_services.budget_locked IS 
'If true, budget cannot be reallocated without admin override.';

COMMENT ON COLUMN it_services.budget_notes IS 
'Notes about this IT Service budget (capacity planning, growth assumptions, etc.).';
```

### 4.4 Budget Transfers (Audit Trail)

```sql
-- ============================================
-- BUDGET TRANSFERS (The Audit Trail)
-- ============================================

CREATE TABLE budget_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  fiscal_year INTEGER NOT NULL,
  
  -- From (NULL = unallocated reserve)
  from_application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
  from_it_service_id UUID REFERENCES it_services(id) ON DELETE SET NULL,
  
  -- To (NULL = back to unallocated)
  to_application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
  to_it_service_id UUID REFERENCES it_services(id) ON DELETE SET NULL,
  
  -- The movement
  amount DECIMAL(12,2) NOT NULL,
  
  -- Why
  reason TEXT NOT NULL,
  
  -- Who/When
  transferred_by UUID NOT NULL REFERENCES users(id),
  transferred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Optional approval (for future workflow)
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT now(),
  
  -- Constraints: Must have valid from/to pair
  CONSTRAINT budget_transfers_valid_from CHECK (
    (from_application_id IS NOT NULL AND from_it_service_id IS NULL) OR
    (from_application_id IS NULL AND from_it_service_id IS NOT NULL) OR
    (from_application_id IS NULL AND from_it_service_id IS NULL)  -- from unallocated
  ),
  CONSTRAINT budget_transfers_valid_to CHECK (
    (to_application_id IS NOT NULL AND to_it_service_id IS NULL) OR
    (to_application_id IS NULL AND to_it_service_id IS NOT NULL) OR
    (to_application_id IS NULL AND to_it_service_id IS NULL)  -- to unallocated
  )
);

-- Indexes
CREATE INDEX idx_budget_transfers_workspace ON budget_transfers(workspace_id, fiscal_year);
CREATE INDEX idx_budget_transfers_from_app ON budget_transfers(from_application_id);
CREATE INDEX idx_budget_transfers_from_service ON budget_transfers(from_it_service_id);
CREATE INDEX idx_budget_transfers_to_app ON budget_transfers(to_application_id);
CREATE INDEX idx_budget_transfers_to_service ON budget_transfers(to_it_service_id);
CREATE INDEX idx_budget_transfers_date ON budget_transfers(transferred_at);

-- RLS
ALTER TABLE budget_transfers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view budget transfers in their workspaces"
ON budget_transfers FOR SELECT
USING (workspace_id IN (
  SELECT wu.workspace_id FROM workspace_users wu WHERE wu.user_id = auth.uid()
));

CREATE POLICY "Editors can create budget transfers"
ON budget_transfers FOR INSERT
WITH CHECK (workspace_id IN (
  SELECT wu.workspace_id FROM workspace_users wu 
  WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
));

-- Comment
COMMENT ON TABLE budget_transfers IS 
'Audit trail for budget reallocations between applications and IT services.';
```

---

## 5. Views

### 5.1 vw_budget_status (Application Level)

```sql
CREATE OR REPLACE VIEW vw_budget_status AS
SELECT 
  a.id AS application_id,
  a.name AS application_name,
  a.workspace_id,
  w.name AS workspace_name,
  w.namespace_id,
  a.operational_status,
  
  -- Budget
  COALESCE(a.budget_amount, 0) AS budget,
  a.budget_locked,
  a.budget_notes,
  
  -- Committed (run rate from cost model)
  COALESCE(rr.total_run_rate, 0) AS committed,
  
  -- Remaining
  COALESCE(a.budget_amount, 0) - COALESCE(rr.total_run_rate, 0) AS remaining,
  
  -- Status
  CASE
    WHEN COALESCE(a.budget_amount, 0) = 0 THEN 'no_budget'
    WHEN COALESCE(rr.total_run_rate, 0) > (a.budget_amount * 1.1) THEN 'over_critical'
    WHEN COALESCE(rr.total_run_rate, 0) > a.budget_amount THEN 'over_10'
    WHEN COALESCE(rr.total_run_rate, 0) > (a.budget_amount * 0.9) THEN 'tight'
    ELSE 'healthy'
  END AS budget_status,
  
  -- Percent used
  CASE
    WHEN COALESCE(a.budget_amount, 0) = 0 THEN NULL
    ELSE ROUND((COALESCE(rr.total_run_rate, 0) / a.budget_amount) * 100, 1)
  END AS percent_used
  
FROM applications a
LEFT JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN vw_application_run_rate rr ON rr.application_id = a.id
WHERE a.operational_status != 'retired';
```

**Consumed By:**
- Budget Settings page (Settings > Budget > Applications tab)
- BudgetHealthCard component (for eliminate quadrant filtering)
- Application detail pages
- QuickSight budget reports (future)

---

### 5.2 vw_it_service_budget_status (IT Service Level - NEW in v1.2)

```sql
CREATE OR REPLACE VIEW vw_it_service_budget_status AS
SELECT 
  its.id AS it_service_id,
  its.name AS it_service_name,
  its.workspace_id,
  w.name AS workspace_name,
  w.namespace_id,
  its.operational_status,
  its.service_type,
  
  -- Budget
  COALESCE(its.budget_amount, 0) AS budget,
  its.budget_locked,
  its.budget_notes,
  
  -- Committed (total annual cost of IT Service)
  COALESCE(its.total_annual_cost, 0) AS committed,
  
  -- Allocated to consumers
  COALESCE(
    (SELECT SUM(itsa.allocated_cost) 
     FROM it_service_allocations itsa 
     WHERE itsa.it_service_id = its.id),
    0
  ) AS allocated_to_consumers,
  
  -- Stranded (unallocated cost)
  COALESCE(its.total_annual_cost, 0) - COALESCE(
    (SELECT SUM(itsa.allocated_cost) 
     FROM it_service_allocations itsa 
     WHERE itsa.it_service_id = its.id),
    0
  ) AS stranded_cost,
  
  -- Remaining budget
  COALESCE(its.budget_amount, 0) - COALESCE(its.total_annual_cost, 0) AS remaining,
  
  -- Status
  CASE
    WHEN COALESCE(its.budget_amount, 0) = 0 THEN 'no_budget'
    WHEN COALESCE(its.total_annual_cost, 0) > (its.budget_amount * 1.1) THEN 'over_critical'
    WHEN COALESCE(its.total_annual_cost, 0) > its.budget_amount THEN 'over_10'
    WHEN COALESCE(its.total_annual_cost, 0) > (its.budget_amount * 0.9) THEN 'tight'
    ELSE 'healthy'
  END AS budget_status,
  
  -- Percent used
  CASE
    WHEN COALESCE(its.budget_amount, 0) = 0 THEN NULL
    ELSE ROUND((COALESCE(its.total_annual_cost, 0) / its.budget_amount) * 100, 1)
  END AS percent_used
  
FROM it_services its
LEFT JOIN workspaces w ON w.id = its.workspace_id
WHERE its.operational_status != 'retired';
```

**Consumed By:**
- Budget Settings page (Settings > Budget > IT Services tab)
- Provider workspace dashboards
- Infrastructure cost reports
- QuickSight budget reports (future)

**Key Insight:** Unlike applications, IT Services show both `allocated_to_consumers` and `stranded_cost` to help provider workspaces understand utilization.

---

### 5.3 vw_workspace_budget_summary (Workspace Level - UPDATED in v1.2)

```sql
CREATE OR REPLACE VIEW vw_workspace_budget_summary AS
SELECT 
  w.id AS workspace_id,
  w.name AS workspace_name,
  w.namespace_id,
  wb.fiscal_year AS budget_fiscal_year,
  
  -- Workspace Budget
  COALESCE(wb.budget_amount, 0) AS total_budget,
  
  -- Applications (consumer side)
  COALESCE(SUM(a.budget_amount), 0) AS allocated_to_apps,
  COALESCE(SUM(abs.committed), 0) AS apps_committed,
  
  -- IT Services (provider side)
  COALESCE(SUM(its.budget_amount), 0) AS allocated_to_services,
  COALESCE(SUM(itsbs.committed), 0) AS services_committed,
  
  -- Combined Allocations
  (COALESCE(SUM(a.budget_amount), 0) + COALESCE(SUM(its.budget_amount), 0)) AS total_allocated,
  
  -- Unallocated Reserve
  (COALESCE(wb.budget_amount, 0) - 
   COALESCE(SUM(a.budget_amount), 0) - 
   COALESCE(SUM(its.budget_amount), 0)) AS unallocated_reserve,
  
  -- Committed (actual spending)
  (COALESCE(SUM(abs.committed), 0) + COALESCE(SUM(itsbs.committed), 0)) AS total_committed,
  
  -- Remaining
  (COALESCE(wb.budget_amount, 0) - 
   COALESCE(SUM(abs.committed), 0) - 
   COALESCE(SUM(itsbs.committed), 0)) AS total_remaining,
  
  -- Counts
  COUNT(DISTINCT a.id) AS app_count,
  COUNT(DISTINCT its.id) AS service_count,
  COUNT(CASE WHEN abs.budget_status = 'healthy' THEN 1 END) AS apps_healthy_count,
  COUNT(CASE WHEN abs.budget_status = 'tight' THEN 1 END) AS apps_tight_count,
  COUNT(CASE WHEN abs.budget_status IN ('over_10', 'over_critical') THEN 1 END) AS apps_over_count,
  COUNT(CASE WHEN abs.budget_status = 'no_budget' THEN 1 END) AS apps_no_budget_count,
  COUNT(CASE WHEN itsbs.budget_status = 'healthy' THEN 1 END) AS services_healthy_count,
  COUNT(CASE WHEN itsbs.budget_status IN ('over_10', 'over_critical') THEN 1 END) AS services_over_count,
  COUNT(CASE WHEN itsbs.budget_status = 'no_budget' THEN 1 END) AS services_no_budget_count,
  
  -- Overall health
  CASE
    WHEN (wb.budget_amount IS NULL OR wb.budget_amount = 0) THEN 'no_budget'
    WHEN (SUM(abs.committed) + SUM(itsbs.committed)) IS NULL THEN 'no_costs'
    WHEN (SUM(abs.committed) + SUM(itsbs.committed)) <= (wb.budget_amount * 0.8) THEN 'healthy'
    WHEN (SUM(abs.committed) + SUM(itsbs.committed)) <= wb.budget_amount THEN 'tight'
    ELSE 'over'
  END AS budget_health,
  
  -- Percent used
  CASE
    WHEN (wb.budget_amount IS NULL OR wb.budget_amount = 0) THEN NULL
    ELSE ROUND((COALESCE(SUM(abs.committed), 0) + COALESCE(SUM(itsbs.committed), 0)) / wb.budget_amount * 100, 1)
  END AS percent_used

FROM workspaces w
LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id AND wb.is_current = true
LEFT JOIN applications a ON a.workspace_id = w.id AND a.operational_status != 'retired'
LEFT JOIN vw_budget_status abs ON abs.application_id = a.id
LEFT JOIN it_services its ON its.workspace_id = w.id AND its.operational_status != 'retired'
LEFT JOIN vw_it_service_budget_status itsbs ON itsbs.it_service_id = its.id
GROUP BY w.id, w.name, w.namespace_id, wb.fiscal_year, wb.budget_amount;
```

**Consumed By:**
- Budget Settings page (Settings > Budget)
- **BudgetHealthCard component on Dashboard** (see gis-budget-alerts-architecture-v1.0.md)
- QuickSight budget reports (future)

**Key Changes in v1.2:**
- Now includes `allocated_to_services` and `services_committed`
- Counts for both apps and services
- Total calculations include both applications and IT services

---

### 5.4 vw_budget_transfer_history (UPDATED in v1.2)

```sql
CREATE OR REPLACE VIEW vw_budget_transfer_history AS
SELECT 
  bt.id,
  bt.workspace_id,
  w.name AS workspace_name,
  bt.fiscal_year,
  
  -- From
  bt.from_application_id,
  from_app.name AS from_application_name,
  bt.from_it_service_id,
  from_service.name AS from_it_service_name,
  CASE
    WHEN bt.from_application_id IS NOT NULL THEN 'application'
    WHEN bt.from_it_service_id IS NOT NULL THEN 'it_service'
    ELSE 'unallocated'
  END AS from_type,
  
  -- To
  bt.to_application_id,
  to_app.name AS to_application_name,
  bt.to_it_service_id,
  to_service.name AS to_it_service_name,
  CASE
    WHEN bt.to_application_id IS NOT NULL THEN 'application'
    WHEN bt.to_it_service_id IS NOT NULL THEN 'it_service'
    ELSE 'unallocated'
  END AS to_type,
  
  -- Transfer details
  bt.amount,
  bt.reason,
  
  -- Who/When
  bt.transferred_by,
  u.email AS transferred_by_email,
  bt.transferred_at,
  
  -- Approval (future)
  bt.approved_by,
  bt.approved_at

FROM budget_transfers bt
LEFT JOIN workspaces w ON w.id = bt.workspace_id
LEFT JOIN applications from_app ON from_app.id = bt.from_application_id
LEFT JOIN applications to_app ON to_app.id = bt.to_application_id
LEFT JOIN it_services from_service ON from_service.id = bt.from_it_service_id
LEFT JOIN it_services to_service ON to_service.id = bt.to_it_service_id
LEFT JOIN users u ON u.id = bt.transferred_by
ORDER BY bt.transferred_at DESC;
```

---

## 6. Business Logic

### 6.1 Budget Reallocation

**Flow:**
1. User selects "Reallocate Budget"
2. UI shows:
   - Source (app, service, or unallocated)
   - Destination (app, service, or unallocated)
   - Amount slider/input
3. User enters:
   - Amount
   - Reason (required, min 10 chars)
4. UI validates:
   - Amount > 0
   - Source has sufficient funds (warning if not)
   - Destination not locked
   - Valid source/destination combination
5. System executes in transaction:
   - Decrement source budget
   - Increment destination budget
   - Insert transfer record
6. UI shows updated balances

### Validation Rules

| Rule | Behavior |
|------|----------|
| Amount > 0 | Required |
| Source ≠ Destination | Required |
| Source has sufficient funds | Warning if from app/service, skip if from reserve |
| Destination is locked | Block transfer, show message |
| Reason provided | Required (min 10 chars) |
| Valid type combination | Can transfer between apps, between services, or to/from unallocated. Cannot transfer app ↔ service directly. |

### Transaction

```sql
-- Example transfer: $50,000 from Azure IT Service to VMware IT Service
BEGIN;

-- Decrement source
UPDATE it_services 
SET budget_amount = budget_amount - 50000,
    updated_at = now()
WHERE id = 'azure-service-id';

-- Increment destination
UPDATE it_services 
SET budget_amount = budget_amount + 50000,
    updated_at = now()
WHERE id = 'vmware-service-id';

-- Record transfer
INSERT INTO budget_transfers (
  workspace_id, fiscal_year,
  from_it_service_id, to_it_service_id,
  amount, reason, transferred_by
) VALUES (
  'central-it-workspace-id', 2026,
  'azure-service-id', 'vmware-service-id',
  50000, 'Migrate workloads from Azure to on-prem VMware', auth.uid()
);

COMMIT;
```

---

## 7. UI Components

### 7.1 Dashboard Widget: Budget Health

```
┌─────────────────────────────────┐
│  FY26 BUDGET HEALTH             │
├─────────────────────────────────┤
│                                 │
│  Total Budget:     $3,000,000   │
│  Committed:        $2,800,000   │
│  ████████████████████ 93%       │
│                                 │
│  Remaining:        $200,000     │
│  Unallocated:      $100,000     │
│                                 │
│  ● 5 services healthy           │
│  ● 2 services tight             │
│  ● 1 service over budget        │
└─────────────────────────────────┘
```

**Note:** Consumer workspaces show apps, provider workspaces show services, hybrid show both.

---

### 7.2 Budget Settings Page

**Tab Structure:**

```
Settings > Budget
  
[ Applications ] [ IT Services ]

(Show Applications tab for consumer workspaces)
(Show IT Services tab for provider workspaces)
(Show both tabs for hybrid workspaces)
```

**Applications Tab (existing):**
- Shows vw_budget_status data
- Initialize button for apps with $0 budgets
- Edit/reallocate capabilities

**IT Services Tab (NEW in v1.2):**

```
┌─────────────────────────────────────────────────────────────────┐
│  BUDGET: $3,000,000         RUN RATE: $2,800,000 (93%)        │
│  REMAINING: $200,000        ✓ HEALTHY                           │
└─────────────────────────────────────────────────────────────────┘

IT Services

SERVICE NAME             | BUDGET      | RUN RATE    | STRANDED  | VARIANCE   | STATUS
------------------------ | ----------- | ----------- | --------- | ---------- | -----------
Azure Cloud Platform     | $2,000,000  | $2,000,000  | $300,000  | $0         | ON TARGET
VMware Cluster           | $500,000    | $480,000    | $120,000  | $20,000    | HEALTHY
Network Infrastructure   | $300,000    | $320,000    | $50,000   | -$20,000   | ⚠️ OVER

TOTALS:
Allocated to Services:   $2,800,000
Unallocated Reserve:     $200,000
Total Workspace:         $3,000,000

[ Initialize from Current Spending ]
```

**Key Differences from Applications Tab:**
- Shows "Stranded" column (unallocated capacity)
- Run Rate = total_annual_cost of IT Service
- Used by provider workspaces (Central IT)

---

### 7.3 Initialize Function for IT Services

```typescript
const handleInitializeServiceBudgets = async () => {
  setIsInitializing(true);
  try {
    const { data, error } = await supabase.rpc('initialize_it_service_budgets', {
      p_workspace_id: selectedWorkspace.id
    });
    
    if (error) throw error;
    
    const count = data?.[0]?.updated_count || 0;
    toast.success(`Initialized ${count} IT Service budgets to current spending`);
    
    await refetchServices();
    
  } catch (error) {
    console.error('Error initializing budgets:', error);
    toast.error('Failed to initialize IT Service budgets');
  } finally {
    setIsInitializing(false);
  }
};
```

---

## 8. What This Replaces

| Spreadsheet Problem | GetInSync Solution |
|--------------------|-------------------|
| "Which version is current?" | Single source of truth |
| "Who changed that?" | Audit trail on every transfer |
| "What's really committed?" | Live run rate from cost model |
| "Do I have room for this?" | Remaining = Budget - Committed |
| "Can I borrow from that pot?" | Reallocation with tracking |
| "Show me YTD transfers" | Transfer history view |
| "What's my infrastructure costing?" | IT Service budgets show total + stranded |
| Manual formula updates | Automatic calculations |
| No approval trail | Who/when/why on every change |

---

## 9. What We're NOT Building

| Feature | Why Not | Alternative |
|---------|---------|-------------|
| Invoice tracking | ERP territory | Use contract_reference |
| Actual vs. accrued | Accounting complexity | Use run rate as proxy |
| GL integration | ERP territory | Export reports |
| Approval workflows | Keep it simple | Notes + audit trail |
| Multi-currency | Scope creep | Single currency per namespace |
| Forecasting/projections | Phase 2 | Use pipeline apps |
| Budget versioning | Complexity | Fiscal year tracking only |

---

## 10. Tier Gating

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| View budget vs. committed | ✅ | ✅ | ✅ |
| Set app budgets | ❌ | ✅ | ✅ |
| Set IT Service budgets | ❌ | ✅ | ✅ |
| Set workspace budget | ❌ | ✅ | ✅ |
| Reallocate between apps/services | ❌ | ❌ | ✅ |
| Transfer history | ❌ | ❌ | ✅ |
| Budget alerts dashboard | ❌ | ✅ | ✅ |

---

## 11. Implementation Phases

| Phase | Scope | Effort |
|-------|-------|--------|
| **25a** | Workspace budget fields | 30 min |
| **25b** | Application budget fields | 30 min |
| **25c** | budget_transfers table + RLS | 1 hr |
| **25d** | vw_budget_status | 30 min |
| **25e** | vw_workspace_budget_summary | 30 min |
| **25f** | vw_budget_transfer_history | 30 min |
| **25g** | vw_budget_alerts | 30 min |
| **25.5a** | IT Service budget fields (v1.2) | 15 min |
| **25.5b** | vw_it_service_budget_status (v1.2) | 30 min |
| **25.5c** | Update vw_workspace_budget_summary (v1.2) | 30 min |
| **25.5d** | Update budget_transfers (v1.2) | 30 min |
| **25.5e** | initialize_it_service_budgets function (v1.2) | 15 min |
| **UI** | Budget health widget | 2 hrs |
| **UI** | Budget alerts widget | 2 hrs |
| **UI** | IT Services tab (v1.2) | 2 hrs |
| **UI** | Initialize IT Services button (v1.2) | 30 min |
| **UI** | Reallocation modal | 3 hrs |
| **UI** | Transfer history panel | 2 hrs |
| **UI** | App/Service budget editing | 2 hrs |

**Total Phase 25:** ~15 hours  
**Total Phase 25.5 (v1.2 additions):** ~3 hours  
**Combined Total:** ~18 hours

---

## 12. Database Functions

### 12.1 initialize_app_budgets (Existing)

```sql
CREATE OR REPLACE FUNCTION initialize_app_budgets(p_workspace_id uuid)
RETURNS TABLE(updated_count integer) AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE applications a
  SET 
    budget_amount = COALESCE(
      (SELECT total_run_rate 
       FROM vw_application_run_rate 
       WHERE application_id = a.id),
      0
    ),
    updated_at = now()
  WHERE a.workspace_id = p_workspace_id
  AND a.budget_amount = 0;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 12.2 initialize_it_service_budgets (NEW in v1.2)

```sql
CREATE OR REPLACE FUNCTION initialize_it_service_budgets(p_workspace_id uuid)
RETURNS TABLE(updated_count integer) AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE it_services its
  SET 
    budget_amount = COALESCE(its.total_annual_cost, 0),
    updated_at = now()
  WHERE its.workspace_id = p_workspace_id
  AND its.budget_amount = 0;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION initialize_it_service_budgets(uuid) TO authenticated;

COMMENT ON FUNCTION initialize_it_service_budgets(uuid) IS 
'Initializes IT Service budgets to their current total annual cost for services with budget_amount = 0. Used by provider workspaces (Central IT).';
```

---

## 13. Related Documents

| Document | Relevance |
|----------|-----------|
| gis-vendor-cost-architecture-v1.0.md | Run rate calculation, cost channels |
| gis-cost-model-architecture-v2.5.md | Cost model foundation |
| gis-pricing-model-v1.0.md | Tier gating definitions |
| **gis-budget-alerts-architecture-v1.0.md** | **Dashboard alerts, configurable display rules, alert_preferences table** |
| gis-workspace-group-architecture-v1.6.md | Workspace permissions for budget management |
| gis-deployment-profile-architecture-v1.7.md | Deployment profile costs (source of run rate) |
| gis-it-service-architecture-v1.3.md | IT Service cost model, stranded cost calculation |

---

## 14. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-22 | Initial version — workspace/app budgets, transfers, views |
| v1.1 | 2026-01-28 | Added cross-references to Budget Alerts architecture (gis-budget-alerts-architecture-v1.0.md). Updated vw_workspace_budget_summary documentation to note usage by BudgetHealthCard. Added note in section 7.2 that dashboard budget health card is now defined in separate architecture document. Updated related documents section. |
| v1.2 | 2026-01-28 | **Added IT Service budgets** for provider workspaces. Added budget_amount fields to it_services table. Created vw_it_service_budget_status view. Updated vw_workspace_budget_summary to include IT Services. Updated budget_transfers to support both applications and IT services. Added initialize_it_service_budgets() function. Updated UI specs to show Applications and IT Services tabs. Added Phase 25.5 implementation plan (3 hours). |

---

*Document: gis-budget-management-architecture-v1.2.md*
*January 2026*
