# GetInSync NextGen - Budget Alerts Architecture
**Version:** 1.0  
**Date:** January 28, 2026  
**Status:** Design Approved, Implementation Pending  
**Author:** Stuart Holtby

---

## Overview

The Budget Alerts system provides configurable dashboard alerts for budget health issues across workspaces. The system is designed to be flexible, allowing namespace and workspace administrators to customize what constitutes an "alert" and how severe different conditions should be treated.

**Key Principle:** Organizations have different priorities. What's critical for one organization may be informational for another. The alert system must be configurable without requiring code changes.

---

## Business Requirements

### Primary Use Cases

1. **Financial Governance:** Alert administrators when workspaces exceed their allocated budgets
2. **Portfolio Optimization:** Highlight applications in the "Eliminate" quadrant that are consuming resources
3. **Budget Planning:** Remind administrators which workspaces still need budgets set
4. **Dashboard Awareness:** Provide at-a-glance budget health status on the main dashboard

### User Stories

**As a Namespace Administrator:**
- I want to set default alert policies for all workspaces in my organization
- I want to decide whether missing budgets are treated as critical, warning, or informational
- I want to control whether budget alerts are visible to all users or just admins

**As a Workspace Administrator:**
- I want to override namespace alert settings for my specific workspace
- I want to hide budget status if my workspace prefers privacy
- I want to customize what "critical" means for my workspace's context

**As a Portfolio Viewer:**
- I want to see budget health status on the dashboard at a glance
- I want to filter the dashboard to see only applications with budget issues
- I don't want to be overwhelmed with alerts during initial setup

---

## Alert Types

### 1. Over Budget Alert

**Trigger:** Workspace's committed run rate exceeds the set budget amount  
**Source:** `vw_workspace_budget_summary` where `budget_health = 'over'`  
**Default Severity:** CRITICAL  
**Configurable:** Can be disabled entirely

**Example:**
- Ministry of Finance has $600K budget
- Committed run rate is $793K
- Alert: "Ministry of Finance (over by $193K / 132%)"

### 2. No Budget Set Alert

**Trigger:** Workspace has no current budget record in `workspace_budgets` table  
**Source:** `vw_workspace_budget_summary` where `budget_health = 'no_budget'`  
**Default Severity:** INFO (not critical)  
**Configurable:** Can be set to INFO, WARNING, or CRITICAL, or disabled entirely

**Example:**
- Central IT workspace has no budget set
- Alert: "3 workspaces need budgets set"

**Rationale for INFO default:** Missing budgets are a setup task, not an emergency. Organizations just starting with GetInSync shouldn't be alarmed by red alerts for incomplete configuration.

### 3. Eliminate Quadrant Alert

**Trigger:** One or more applications are in the "Eliminate" TIME quadrant  
**Source:** `portfolio_assignments` where `time_quadrant = 'eliminate'`  
**Default Severity:** WARNING  
**Configurable:** Can be set to INFO, WARNING, or CRITICAL, or disabled entirely

**Example:**
- 5 applications in Eliminate quadrant
- Combined spend: $23K/year
- Alert: "5 applications to eliminate (spending $23K/year)"

**Rationale for WARNING default:** Eliminate quadrant represents optimization opportunity, not immediate crisis. Tech debt that should be addressed but not emergency-level.

---

## Database Schema

### alert_preferences Table

```sql
CREATE TABLE alert_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope: Hierarchical configuration (namespace OR workspace)
  namespace_id uuid REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE,
  
  -- Alert Type Configuration
  show_over_budget boolean NOT NULL DEFAULT true,
  show_no_budget boolean NOT NULL DEFAULT true,
  no_budget_severity text NOT NULL DEFAULT 'info',
    CHECK (no_budget_severity IN ('info', 'warning', 'critical')),
  show_eliminate_apps boolean NOT NULL DEFAULT true,
  eliminate_severity text NOT NULL DEFAULT 'warning',
    CHECK (eliminate_severity IN ('info', 'warning', 'critical')),
  
  -- Future: Budget threshold configuration
  -- tight_budget_threshold numeric DEFAULT 0.8,  -- 80% of budget = tight
  -- critical_budget_threshold numeric DEFAULT 1.0,  -- 100% of budget = critical
  
  -- Visibility Controls
  visible_to_all boolean NOT NULL DEFAULT true,
    -- If false, only admins see budget health card
  
  -- Audit Fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  
  -- Constraints
  CONSTRAINT alert_preferences_scope_check 
    CHECK (
      (namespace_id IS NOT NULL AND workspace_id IS NULL) OR 
      (namespace_id IS NULL AND workspace_id IS NOT NULL)
    ),
  CONSTRAINT alert_preferences_namespace_unique 
    UNIQUE(namespace_id),
  CONSTRAINT alert_preferences_workspace_unique 
    UNIQUE(workspace_id)
);

-- Indexes
CREATE INDEX idx_alert_preferences_namespace ON alert_preferences(namespace_id);
CREATE INDEX idx_alert_preferences_workspace ON alert_preferences(workspace_id);

-- Updated_at trigger
CREATE TRIGGER update_alert_preferences_updated_at
  BEFORE UPDATE ON alert_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE alert_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view alert preferences in their namespace"
ON alert_preferences FOR SELECT
TO authenticated
USING (
  namespace_id IN (SELECT get_user_namespace_ids())
  OR workspace_id IN (
    SELECT w.id FROM workspaces w 
    WHERE w.namespace_id IN (SELECT get_user_namespace_ids())
  )
);

CREATE POLICY "Admins can manage alert preferences"
ON alert_preferences FOR ALL
TO authenticated
USING (
  namespace_id IN (
    SELECT nu.namespace_id FROM namespace_users nu
    WHERE nu.user_id = auth.uid() AND nu.role = 'admin'
  )
  OR workspace_id IN (
    SELECT wu.workspace_id FROM workspace_users wu
    WHERE wu.user_id = auth.uid() AND wu.role = 'admin'
  )
)
WITH CHECK (
  namespace_id IN (
    SELECT nu.namespace_id FROM namespace_users nu
    WHERE nu.user_id = auth.uid() AND nu.role = 'admin'
  )
  OR workspace_id IN (
    SELECT wu.workspace_id FROM workspace_users wu
    WHERE wu.user_id = auth.uid() AND wu.role = 'admin'
  )
);
```

### Seed Data

```sql
-- Create default preferences for all existing namespaces
INSERT INTO alert_preferences (
  namespace_id, 
  show_over_budget, 
  show_no_budget, 
  no_budget_severity, 
  show_eliminate_apps, 
  eliminate_severity,
  visible_to_all
)
SELECT 
  id,
  true,              -- show_over_budget
  true,              -- show_no_budget
  'info',            -- no_budget_severity (informational, not alarming)
  true,              -- show_eliminate_apps
  'warning',         -- eliminate_severity
  true               -- visible_to_all
FROM namespaces
ON CONFLICT (namespace_id) DO NOTHING;
```

### Namespace Seeding Trigger

```sql
-- Auto-create default alert preferences when new namespace is created
CREATE OR REPLACE FUNCTION seed_alert_preferences_for_namespace()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO alert_preferences (
    namespace_id,
    show_over_budget,
    show_no_budget,
    no_budget_severity,
    show_eliminate_apps,
    eliminate_severity,
    visible_to_all
  ) VALUES (
    NEW.id,
    true,
    true,
    'info',
    true,
    'warning',
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER seed_alert_preferences
  AFTER INSERT ON namespaces
  FOR EACH ROW
  EXECUTE FUNCTION seed_alert_preferences_for_namespace();
```

---

## Configuration Hierarchy

### Cascading Preferences

**Resolution Order:**
1. Workspace-level preferences (if set)
2. Namespace-level preferences (fallback)
3. System defaults (if neither is set)

**Query Pattern:**
```typescript
// Fetch preferences with workspace override capability
const { data: prefs } = await supabase
  .from('alert_preferences')
  .select('*')
  .or(`workspace_id.eq.${workspaceId},namespace_id.eq.${namespaceId}`)
  .order('workspace_id', { ascending: false, nullsFirst: false })
  .limit(1);

// First result will be workspace-level if it exists, 
// otherwise namespace-level
const config = prefs?.[0] || DEFAULT_CONFIG;
```

### Use Cases

**Scenario 1: Namespace Default**
- Government of Saskatchewan sets namespace preference: `no_budget_severity = 'critical'`
- All workspaces inherit this by default
- Budget setup is mandatory for this organization

**Scenario 2: Workspace Override**
- Most workspaces use namespace default
- "R&D Lab" workspace sets `visible_to_all = false`
- R&D budget data is private, hidden from non-admins

**Scenario 3: Phased Rollout**
- Namespace initially sets `show_eliminate_apps = false`
- Once TIME/PAID assessments are mature, enable eliminate alerts
- No code changes required

---

## Severity Levels

### INFO (Blue/Teal Icon)

**Visual:** ℹï¸ Information icon, blue/teal color scheme  
**Meaning:** Awareness item, not urgent  
**Use Cases:**
- Budgets need to be set (initial setup)
- Informational eliminate quadrant (low priority tech debt)

**Card Display:**
```
┌─────────────────────┐
│ ℹï¸  Budget Health   │
│                     │
│   3 Need Setup      │
│   Set budgets →     │
└─────────────────────┘
```

### WARNING (Yellow/Orange Icon)

**Visual:** ⚠ï¸ Warning triangle, yellow/orange color scheme  
**Meaning:** Attention needed, should be addressed  
**Use Cases:**
- Approaching budget limit (80-100%)
- Eliminate quadrant applications (default)
- Mix of issues requiring review

**Card Display:**
```
┌─────────────────────┐
│ ⚠ï¸  Budget Health   │
│                     │
│     2 Issues        │
│   Review needed →   │
└─────────────────────┘
```

### CRITICAL (Red Icon)

**Visual:** 🔴 Alert circle, red color scheme  
**Meaning:** Immediate action required  
**Use Cases:**
- Over budget (default)
- Multiple serious issues
- Configurable: No budget set (if organization requires it)

**Card Display:**
```
┌─────────────────────┐
│ 🔴  Budget Health   │
│                     │
│   3 Critical        │
│  Action needed →    │
└─────────────────────┘
```

### Severity Aggregation Logic

**When multiple issues exist with different severities:**
- CRITICAL takes precedence (show red card)
- If no CRITICAL issues, WARNING takes precedence (show yellow card)
- If only INFO issues, show blue card
- If no issues at all, show green "All Healthy" card

**Example:**
- 2 over-budget workspaces (CRITICAL)
- 5 eliminate apps (WARNING)
- 1 workspace with no budget (INFO)
- **Result:** Red card showing "3 Critical" (2 over + 1 eliminate counted as critical due to config change)

---

## Dashboard Integration

### BudgetHealthCard Component

**Location:** Dashboard.tsx metric card grid (6th card)  
**Visibility:** Controlled by `alert_preferences.visible_to_all`

**Component Logic:**
```typescript
interface BudgetHealthCardProps {
  currentWorkspace: Workspace;
  currentUser: User;
}

const BudgetHealthCard: React.FC<BudgetHealthCardProps> = ({ 
  currentWorkspace, 
  currentUser 
}) => {
  // 1. Fetch alert preferences (workspace overrides namespace)
  const config = useAlertPreferences(
    currentWorkspace.id, 
    currentWorkspace.namespace_id
  );
  
  // 2. Check visibility
  if (!config.visible_to_all && !currentUser.isAdmin) {
    return null; // Hide from non-admins
  }
  
  // 3. Fetch alert data based on configuration
  const issues = useAlertData(currentWorkspace.namespace_id, config);
  
  // 4. Determine card state based on highest severity
  const cardState = determineCardState(issues);
  
  // 5. Render card with appropriate styling and content
  return <MetricCard state={cardState} onClick={handleClick} />;
};
```

**Click Behavior:**
- Applies filters to current dashboard view
- Shows only applications/workspaces with budget issues
- Updates URL params for shareability: `?budgetFilter=issues`
- Displays "Clear Filters" button to reset view

**Filter Logic:**
```typescript
const applyBudgetFilter = (issues: Alert[]) => {
  const overBudgetWorkspaceIds = issues
    .filter(i => i.type === 'over_budget')
    .map(i => i.workspace_id);
    
  const eliminateAppIds = issues
    .filter(i => i.type === 'eliminate')
    .flatMap(i => i.application_ids);
    
  // Show apps that are either:
  // 1. In over-budget workspaces, OR
  // 2. In eliminate quadrant
  const filteredApps = allApps.filter(app => 
    overBudgetWorkspaceIds.includes(app.workspace_id) ||
    eliminateAppIds.includes(app.id)
  );
  
  setFilteredApplications(filteredApps);
};
```

---

## Phase Rollout Plan

### Phase 1: Foundation (Current - Phase 25)

**Goal:** Establish database structure and default behavior

**Deliverables:**
- [x] `alert_preferences` table created
- [x] Default preferences seeded for existing namespaces
- [x] Namespace seeding trigger configured
- [x] BudgetHealthCard component reads from preferences
- [x] Dashboard displays budget health based on configuration
- [ ] RLS policies tested and verified

**No UI for configuration** - uses sensible defaults:
- Over budget: CRITICAL (always show)
- No budget: INFO (show but don't alarm)
- Eliminate: WARNING (show as optimization opportunity)
- Visible to all users by default

**Timeline:** Complete by end of Phase 25 (January 28, 2026)

### Phase 2: Configuration UI (Future - Phase 27 or 28)

**Goal:** Allow administrators to customize alert preferences

**Deliverables:**
- Settings page: "Alert Settings" or "Budget Alerts"
- Namespace admin interface:
  - Toggle each alert type on/off
  - Set severity levels for configurable alerts
  - Control visibility (all users vs. admins only)
- Workspace admin interface:
  - Same controls as namespace level
  - "Use Namespace Default" option
  - Clear indication when workspace overrides namespace
- Preview of how alerts will appear
- Reset to defaults button

**Timeline:** Q1 2026 (after Phase 26 - Application Wizard)

### Phase 3: Advanced Features (Future - Phase 30+)

**Goal:** Extend alert system with additional capabilities

**Potential Features:**
- Custom threshold configuration (define "tight" budget percentage)
- Email/Slack notifications for critical alerts
- Alert history and trends
- Budget forecasting alerts ("projected to exceed in 3 months")
- Custom alert rules (e.g., "alert if eliminate quadrant > $50K")
- Per-user alert preferences (snooze, dismiss, customize)
- Alert escalation (notify workspace admin → namespace admin)

**Timeline:** Q2-Q3 2026 (based on user feedback)

---

## Future Extensibility

### Additional Alert Types (Potential)

**Tech Debt Threshold:**
- Trigger: Estimated tech debt exceeds $X
- Configurable threshold
- Severity: WARNING or CRITICAL

**Assessment Staleness:**
- Trigger: Applications haven't been assessed in X months
- Configurable staleness period
- Severity: INFO or WARNING

**Cost Trend:**
- Trigger: Run rate increasing by X% month-over-month
- Requires historical cost tracking
- Severity: WARNING

**Compliance:**
- Trigger: Applications missing required attributes
- Integration with CSDM validation
- Severity: WARNING or CRITICAL

### Configuration Expansion

**Threshold Controls:**
```sql
-- Future columns for alert_preferences table
tight_budget_threshold numeric DEFAULT 0.8,  -- 80%
critical_budget_threshold numeric DEFAULT 1.0,  -- 100%
eliminate_cost_threshold numeric,  -- Alert only if eliminate spend > $X
```

**Notification Channels:**
```sql
-- Future table for notification preferences
CREATE TABLE alert_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_preference_id uuid REFERENCES alert_preferences(id),
  channel text NOT NULL,  -- 'email', 'slack', 'webhook'
  enabled boolean NOT NULL DEFAULT false,
  config jsonb,  -- Channel-specific configuration
  ...
);
```

**Alert Schedule:**
```sql
-- Future columns for alert_preferences table
check_frequency text DEFAULT 'realtime',  -- 'realtime', 'daily', 'weekly'
quiet_hours_start time,
quiet_hours_end time,
```

---

## Data Model Relationships

### Entity Relationship Diagram

```
namespaces (1) ────┐
                   │
                   ├──→ (1) alert_preferences
                   │
workspaces (1) ────┘

alert_preferences
├── Determines display of BudgetHealthCard
├── Filters alert data sources
└── Controls visibility rules
```

### Data Flow

```
1. User loads Dashboard
   ↓
2. BudgetHealthCard fetches alert_preferences
   - Check workspace_id first
   - Fall back to namespace_id
   ↓
3. Query alert sources based on config:
   - vw_workspace_budget_summary (if show_over_budget OR show_no_budget)
   - portfolio_assignments (if show_eliminate_apps)
   ↓
4. Apply severity mappings from config
   ↓
5. Aggregate issues by highest severity
   ↓
6. Render card in appropriate state
   ↓
7. Apply dashboard filter on click (if issues exist)
```

---

## Security Considerations

### RLS Policy Design

**Principle:** Users can only see alert preferences for namespaces/workspaces they have access to.

**Read Access:**
- Any authenticated user can view preferences for their namespace
- Any workspace member can view preferences for their workspace

**Write Access:**
- Namespace admins can modify namespace-level preferences
- Workspace admins can modify workspace-level preferences (override)
- Regular users cannot modify preferences

### Visibility Controls

**`visible_to_all = false`:**
- Budget health card hidden from non-admin users
- Admins always see the card regardless of setting
- Workspace-level setting overrides namespace setting
- Use case: Sensitive budget data in competitive environments

**Data Exposure:**
- Alert card shows aggregated counts, not detailed amounts
- Click-through filter shows apps user already has access to
- No new data exposure through alert system
- Respects existing workspace_users and namespace_users RLS

---

## Testing Strategy

### Unit Tests

**alert_preferences Table:**
- [ ] Seed trigger creates preferences for new namespace
- [ ] Workspace preferences override namespace preferences
- [ ] RLS policies prevent unauthorized access
- [ ] Constraint checks enforce valid severity values
- [ ] Cannot have both namespace_id AND workspace_id set

**BudgetHealthCard Component:**
- [ ] Fetches correct preferences (workspace → namespace → default)
- [ ] Applies severity mappings correctly
- [ ] Aggregates issues by highest severity
- [ ] Respects visible_to_all setting
- [ ] Handles missing preferences gracefully

### Integration Tests

**Configuration Cascade:**
- [ ] Namespace default applies to all workspaces
- [ ] Workspace override takes precedence over namespace
- [ ] Changes to namespace preferences affect workspaces without overrides
- [ ] Changes to workspace preferences don't affect other workspaces

**Alert Display:**
- [ ] Card shows correct state for each severity combination
- [ ] Click behavior filters dashboard correctly
- [ ] URL params update for shareability
- [ ] "Clear Filters" resets to unfiltered view

### User Acceptance Tests

**Scenario 1: Financial Governance Org**
- Set `no_budget_severity = 'critical'`
- Verify all workspaces without budgets show as critical alerts
- Verify administrators are prompted to set budgets

**Scenario 2: Tech-Focused Org**
- Set `eliminate_severity = 'critical'`
- Set `show_over_budget = false`
- Verify eliminate quadrant is prioritized over budget status

**Scenario 3: Privacy-Conscious Workspace**
- Set workspace-level `visible_to_all = false`
- Login as non-admin user
- Verify budget health card is hidden
- Login as admin user
- Verify budget health card is visible

---

## Implementation Notes

### TypeScript Types

```typescript
type AlertSeverity = 'info' | 'warning' | 'critical';

type AlertType = 
  | 'over_budget' 
  | 'no_budget' 
  | 'eliminate';

interface AlertPreferences {
  id: string;
  namespace_id?: string;
  workspace_id?: string;
  show_over_budget: boolean;
  show_no_budget: boolean;
  no_budget_severity: AlertSeverity;
  show_eliminate_apps: boolean;
  eliminate_severity: AlertSeverity;
  visible_to_all: boolean;
  created_at: string;
  updated_at: string;
}

interface Alert {
  type: AlertType;
  severity: AlertSeverity;
  workspace_id?: string;
  workspace_name?: string;
  application_ids?: string[];
  amount_over?: number;
  count?: number;
  metadata?: Record<string, any>;
}

interface CardState {
  variant: 'healthy' | 'info' | 'warning' | 'critical';
  icon: string;
  title: string;
  value: string;
  subtitle: string;
  clickable: boolean;
  issues: Alert[];
}
```

### React Hooks

```typescript
// Custom hook for fetching alert preferences
const useAlertPreferences = (
  workspaceId: string, 
  namespaceId: string
): AlertPreferences => {
  // Implementation
};

// Custom hook for fetching and aggregating alert data
const useAlertData = (
  namespaceId: string, 
  config: AlertPreferences
): Alert[] => {
  // Implementation
};

// Custom hook for determining card state
const useCardState = (issues: Alert[]): CardState => {
  // Implementation
};
```

---

## Performance Considerations

### Query Optimization

**Alert Preferences:**
- Indexed on namespace_id and workspace_id
- Simple equality checks, highly cacheable
- Single row per namespace/workspace
- Query executes in <5ms

**Alert Data Sources:**
- vw_workspace_budget_summary: Already optimized view
- portfolio_assignments: Add index on time_quadrant for faster filtering
- Queries scoped by namespace_id (uses existing RLS)
- Typical response time: 10-50ms

**Suggested Index:**
```sql
CREATE INDEX idx_portfolio_assignments_time_quadrant 
ON portfolio_assignments(time_quadrant) 
WHERE time_quadrant IS NOT NULL;
```

### Caching Strategy

**Client-Side:**
- Cache alert preferences for 5 minutes (rarely change)
- Refresh alert data on dashboard mount and every 60 seconds
- Invalidate cache on workspace change

**Future: Server-Side (if needed):**
- Materialized view for alert aggregations
- Refresh on workspace_budgets or portfolio_assignments UPDATE
- Improves response time for large namespaces (1000+ apps)

---

## Migration Path

### Database Migration

```sql
-- Migration: Add alert preferences system
-- Version: 1.0
-- Date: January 28, 2026

BEGIN;

-- Create alert_preferences table
CREATE TABLE alert_preferences (
  -- [Full DDL from Database Schema section above]
);

-- Create indexes
CREATE INDEX idx_alert_preferences_namespace ON alert_preferences(namespace_id);
CREATE INDEX idx_alert_preferences_workspace ON alert_preferences(workspace_id);

-- Create updated_at trigger
CREATE TRIGGER update_alert_preferences_updated_at
  BEFORE UPDATE ON alert_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE alert_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view alert preferences in their namespace"
ON alert_preferences FOR SELECT
TO authenticated
USING (
  namespace_id IN (SELECT get_user_namespace_ids())
  OR workspace_id IN (
    SELECT w.id FROM workspaces w 
    WHERE w.namespace_id IN (SELECT get_user_namespace_ids())
  )
);

CREATE POLICY "Admins can manage alert preferences"
ON alert_preferences FOR ALL
TO authenticated
USING (
  namespace_id IN (
    SELECT nu.namespace_id FROM namespace_users nu
    WHERE nu.user_id = auth.uid() AND nu.role = 'admin'
  )
  OR workspace_id IN (
    SELECT wu.workspace_id FROM workspace_users wu
    WHERE wu.user_id = auth.uid() AND wu.role = 'admin'
  )
)
WITH CHECK (
  namespace_id IN (
    SELECT nu.namespace_id FROM namespace_users nu
    WHERE nu.user_id = auth.uid() AND nu.role = 'admin'
  )
  OR workspace_id IN (
    SELECT wu.workspace_id FROM workspace_users wu
    WHERE wu.user_id = auth.uid() AND wu.role = 'admin'
  )
);

-- Seed existing namespaces
INSERT INTO alert_preferences (
  namespace_id, 
  show_over_budget, 
  show_no_budget, 
  no_budget_severity, 
  show_eliminate_apps, 
  eliminate_severity,
  visible_to_all
)
SELECT 
  id,
  true,
  true,
  'info',
  true,
  'warning',
  true
FROM namespaces
ON CONFLICT (namespace_id) DO NOTHING;

-- Create namespace seeding trigger
CREATE OR REPLACE FUNCTION seed_alert_preferences_for_namespace()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO alert_preferences (
    namespace_id,
    show_over_budget,
    show_no_budget,
    no_budget_severity,
    show_eliminate_apps,
    eliminate_severity,
    visible_to_all
  ) VALUES (
    NEW.id,
    true,
    true,
    'info',
    true,
    'warning',
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER seed_alert_preferences
  AFTER INSERT ON namespaces
  FOR EACH ROW
  EXECUTE FUNCTION seed_alert_preferences_for_namespace();

-- Performance optimization: Index for eliminate quadrant queries
CREATE INDEX idx_portfolio_assignments_time_quadrant 
ON portfolio_assignments(time_quadrant) 
WHERE time_quadrant IS NOT NULL;

COMMIT;
```

### Rollback Plan

```sql
-- Rollback: Remove alert preferences system
BEGIN;

DROP TRIGGER IF EXISTS seed_alert_preferences ON namespaces;
DROP FUNCTION IF EXISTS seed_alert_preferences_for_namespace();
DROP INDEX IF EXISTS idx_portfolio_assignments_time_quadrant;
DROP TABLE IF EXISTS alert_preferences CASCADE;

COMMIT;
```

---

## Success Metrics

### Phase 1 (Foundation)
- [ ] alert_preferences table created and seeded
- [ ] Default preferences exist for 100% of namespaces
- [ ] BudgetHealthCard displays correctly based on configuration
- [ ] Zero console errors related to alert preferences
- [ ] RLS policies tested with multiple user roles

### Phase 2 (Configuration UI)
- [ ] Namespace admins can modify alert settings
- [ ] Workspace admins can override namespace settings
- [ ] Changes to preferences reflect immediately in dashboard
- [ ] User satisfaction score > 4/5 for configuration UX

### Phase 3 (Advanced Features)
- [ ] Email/Slack notifications functioning
- [ ] Alert history tracking implemented
- [ ] Custom threshold rules working
- [ ] 80% of users find alerts "useful" or "very useful"

---

## Open Questions

1. **Email Notifications:** Should Phase 2 include email alerts, or wait for Phase 3?
2. **Alert History:** Track dismissed/snoozed alerts? Store in separate table?
3. **Multi-Workspace View:** Should "All Workspaces" dashboard show aggregated alerts or per-workspace breakdown?
4. **Mobile Experience:** How should budget health card display on mobile dashboard?
5. **Internationalization:** Should alert messages be translatable? (Future consideration)

---

## References

- features/cost-budget/budget-management.md - Budget calculation and storage
- core/workspace-group.md - Workspace hierarchy and permissions
- core/core-architecture.md - RLS patterns and security model
- archive (superseded by identity-security/rbac-permissions.md) - Role-based access control for settings

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-28 | Stuart Holtby | Initial architecture document |

---

**Status:** Ready for implementation  
**Next Steps:** 
1. Review architecture with team
2. Implement Phase 1 database migration
3. Update BudgetHealthCard component to use alert_preferences
4. Test with multiple configuration scenarios
5. Document configuration options in user guide (Phase 2)
