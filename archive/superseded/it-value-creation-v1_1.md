# gis-it-value-creation-architecture-v1.1

**GetInSync IT Value Creation Module**  
**Phase 21 — Turning Assessment into Action**

Last updated: 2026-02-22

---

## 1. Executive Summary

### The Problem

Every APM tool stops at assessment. They answer:
- "What applications do we have?" ✅
- "What condition are they in?" ✅
- "Where do they fall on TIME/PAID?" ✅

But they fail to answer the question the business actually cares about:

> **"So what? What do we DO about it?"**

The CFO, CIO, PE partner, or board looks at a TIME quadrant with 47 bubbles and asks:
- What should we do?
- In what order?
- How much will it cost?
- Who's accountable?
- When should we start?
- What's the ROI?
- **What's the impact on our IT Run Rate?** *(v1.1)*

And the APM tool has no answer. The consultant goes back to PowerPoint.

### The Solution

The **IT Value Creation Module** extends GetInSync from assessment to action by adding:

1. **Findings** — Documented assessment observations by domain (manual + auto-generated)
2. **Initiatives** — Strategic recommendations tied to findings with cost and run rate impact
3. **Strategic Themes** — Growth, Optimize, Risk categorization
4. **Roadmap Timeline** — When to execute (3/6/9/12+ months)
5. **Investment Tracking** — One-time cost, recurring cost, and IT Run Rate impact
6. **Status Tracking** — Progress from Identified → Complete
7. **Value Dashboard** — Living scorecard, roadmap, and workspace-level planning view

### The Value Proposition

> **GetInSync: The only APM tool that answers "So What?"**

| For | Value |
|-----|-------|
| **IT Leaders** | Board-ready roadmap at any moment |
| **Consultants** | Deliver assessments into the client's system; ongoing engagement |
| **PE Firms** | Track value creation across portfolio companies (workspaces) |
| **Government CIOs** | Ministry-level IT intake and annual planning |
| **Enterprise CTOs** | Business unit budget cycle planning |
| **GetInSync** | Differentiation, stickiness, upsell path |

### v1.1 Origin — IT Run Rate & IT Ally Playbook

This module was inspired by gaps discovered in GetInSync OG (original), specifically:

1. **IT Run Rate Problem** — OG forced users to "guesstimate" IT Service costs at the application level with no structured methodology, no audit trail, and no enforcement of full cost allocation. NextGen's Cost Model v2.5 solved the cost plumbing with three channels (Software Products, IT Services, Cost Bundles) and the "every dollar needs a home and an owner" principle.

2. **IT Ally Playbook Gap** — The consulting engagement lifecycle (kickoff → portfolio review → weekly status → cyber assessment → roadmap update → vendor meetings → QBR) was entirely manual. IT Value Creation digitizes this lifecycle into a living system.

The connection: **Cost Model provides the baseline IT Run Rate. Findings identify where waste/risk/opportunity exists. Initiatives recommend what to do about it. Run Rate Impact projects the financial outcome.**

```
Baseline IT Run Rate ($600K/yr)
    ↓ Findings surface gaps
    ↓ Initiatives propose changes  
    ↓ Run Rate Impact projects outcome
Projected IT Run Rate ($520K/yr, with $80K one-time investment)
```

---

## 2. Multi-Persona Dashboard Architecture (v1.1)

### 2.1 Same Schema, Three Personas

The IT Value Creation dashboard serves three distinct buyer personas using identical schema with context-dependent labels:

| Persona | Namespace | Workspace = | Dashboard Label | Key Use Case |
|---------|-----------|-------------|-----------------|--------------|
| **PE Operating Partner** | PE Firm | Portfolio Company | "Portfolio Summary" | QBR with sponsors |
| **Government CIO** | Central IT | Ministry/Agency | "Ministry IT Summary" | Annual planning / IT intake |
| **Enterprise CTO** | Corporation | Business Unit | "Business Unit Summary" | Budget cycle planning |

### 2.2 PE Portfolio Model

In the PE model, each portfolio company is a **workspace** (not a namespace). This works because:

- **Assessment config** is namespace-level → PE firm applies standardized methodology across all companies (apples-to-apples comparison)
- **User isolation** → Company CIO sees only their workspace; PE Operating Partner (namespace admin) sees everything
- **Cost aggregation** → Roll up per-workspace = per-company run rate; roll up per-namespace = portfolio-wide
- **Findings/Initiatives** → workspace_id scopes to company; NULL = portfolio-wide observation

### 2.3 Government IT Intake Model

Central IT receives intake requests from ministries each budget cycle:

1. Each ministry workspace creates findings and initiatives (bottom-up)
2. Central IT reviews at namespace level, adjusts priorities, approves/defers
3. Initiative `status` workflow (`identified` → `planned` → `in_progress`) IS the intake workflow
4. Namespace-wide findings (`workspace_id = NULL`) capture cross-ministry observations

### 2.4 Namespace-Level Summary Dashboard

```
Portfolio / Ministry / Business Unit Summary
┌──────────────────┬──────────┬──────┬──────────┬─────────────┐
│ Unit             │ Run Rate │ Apps │ Findings │ Initiatives │
├──────────────────┼──────────┼──────┼──────────┼─────────────┤
│ Finance          │ $800K    │ 34   │ 🔴 3     │ 2 planned   │
│ Justice          │ $1.1M    │ 47   │ 🟡 2     │ 1 active    │
│ Municipal Affairs│ $450K    │ 19   │ 🔴 4     │ 1 planned   │
├──────────────────┼──────────┼──────┼──────────┼─────────────┤
│ All Units        │ $2.35M   │ 100  │ 9 total  │ 4 total     │
│ Projected Impact │          │      │          │ -$50K/yr    │
│ Investment Req'd │          │      │          │ $430K       │
└──────────────────┴──────────┴──────┴──────────┴─────────────┘
```

This is workspace-level aggregation within a single namespace — no cross-namespace queries needed. RLS already supports it. The "Projected Impact" row aggregates `estimated_run_rate_change` across all active initiatives. The "Investment Required" row sums `one_time_cost_mid` from `vw_initiative_summary`.

---

## 3. Relationship to Existing Architecture

### What Already Exists

| Entity | Purpose | Limitation |
|--------|---------|------------|
| `application_roadmap` (stub) | Lifecycle events per app | App-centric, not strategic; event types are tactical (upgrade, patch, decommission) |
| `remediation_effort` | T-shirt size for tech debt | Per-DP estimate, not tied to an actionable initiative |
| `assessment_history` (stub) | Track assessment changes over time | Historical, not forward-looking |
| `technology_lifecycle_reference` | EOL/EOS dates per technology | Source data for auto-generated findings (v1.1) |
| Cost Model v2.5 (3 channels) | Software Products, IT Services, Cost Bundles | Provides IT Run Rate baseline; initiatives project impact |

### What's Missing (Addressed by This Module)

| Need | Current State | v1.1 Solution |
|------|---------------|---------------|
| Strategic initiatives | No entity | `initiatives` table |
| Assessment findings by domain | Notes fields only (unstructured) | `findings` table with domain classification |
| Strategic theme tagging | No field | `strategic_theme` on initiatives |
| Time horizon planning | No field | `time_horizon` on initiatives |
| Initiative cost tracking | Costs are on DP, not on initiatives | One-time + recurring cost fields |
| IT Run Rate impact | No field | `estimated_run_rate_change` on initiatives (v1.1) |
| Initiative status workflow | No field | `status` with full lifecycle |
| Owner accountability | No assignment at initiative level | `owner_contact_id` FK |
| Linked DPs/ITServices | No junction tables | `initiative_deployment_profiles`, `initiative_it_services` |
| Auto-generated findings | Manual only | `source_type` + `source_reference_id` (v1.1) |

### How This Module Fits

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          GetInSync Architecture                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  EXISTING (Phases 1-20)                    NEW (Phase 21)                      │
│  ─────────────────────                     ────────────────                    │
│                                                                                │
│  ┌─────────────┐                           ┌─────────────────┐                │
│  │ Application │◄──────────────────────────┤ InitiativeDP    │                │
│  └──────┬──────┘                           │ (junction)      │                │
│         │                                  └────────┬────────┘                │
│         ▼                                           │                         │
│  ┌─────────────┐                           ┌───────▼─────────┐                │
│  │ Deployment  │◄──────────────────────────┤   Initiative    │◄─────         │
│  │ Profile     │                           └───────┬─────────┘      │         │
│  └──────┬──────┘                                   │                │         │
│         │                                          │                │         │
│         ▼                                          ▼                │         │
│  ┌─────────────┐                           ┌─────────────────┐      │         │
│  │ ITService   │◄──────────────────────────┤ InitiativeService│     │         │
│  └─────────────┘                           │ (junction)      │      │         │
│                                            └─────────────────┘      │         │
│                                                                     │         │
│  ┌─────────────┐                           ┌─────────────────┐      │         │
│  │ Portfolio   │                           │ Finding         │──────┘         │
│  └─────────────┘                           │ (by domain)     │                │
│                                            └─────────────────┘                │
│  ┌─────────────────┐                              ▲                           │
│  │ TechLifecycle   │──── auto-generates ──────────┘   (v1.1)                 │
│  │ Reference       │     (source_type='computed')                             │
│  └─────────────────┘                                                          │
│                                                                                │
│  ┌─────────────────┐                                                          │
│  │ Cost Model v2.5 │──── provides IT Run Rate baseline ──► Dashboard         │
│  └─────────────────┘                                                          │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Domain Model

### 4.1 Assessment Domains

Based on the IT Ally framework and common IT assessment structures:

| Domain Code | Domain Name | GetInSync Mapping |
|-------------|-------------|-------------------|
| `icoms` | IT Capability, Operating Model & Spend | IT cost/spend analysis, governance |
| `bpa` | Business Process & Applications | Application portfolio, TIME quadrant |
| `ti` | Technology Infrastructure | DP hosting, cloud, tech stack, lifecycle |
| `dqa` | Data Quality & Analytics | Data assets, reporting |
| `cr` | Cybersecurity Risk | Security posture, compliance |
| `other` | Other | Catch-all for domain-specific findings |

### 4.2 Strategic Themes

| Theme | Code | Description | Color |
|-------|------|-------------|-------|
| **Stabilize/Optimize** | `optimize` | Harden current environment, improve efficiency | 🟢 Green |
| **Growth** | `growth` | Enable expansion, new capabilities | 🔵 Blue |
| **Risk** | `risk` | Mitigate risk, preserve value | 🔴 Red |

### 4.3 Time Horizons

| Horizon | Code | Description |
|---------|------|-------------|
| **0-3 Months** | `q1` | Immediate / Quick wins |
| **3-6 Months** | `q2` | Near-term |
| **6-9 Months** | `q3` | Medium-term |
| **9-12 Months** | `q4` | End of year |
| **12+ Months** | `beyond` | Next year / Long-term |

### 4.4 Initiative Status

| Status | Code | Description |
|--------|------|-------------|
| **Identified** | `identified` | Discovered during assessment |
| **Planned** | `planned` | Approved, awaiting execution |
| **In Progress** | `in_progress` | Active work underway |
| **Completed** | `completed` | Done |
| **Deferred** | `deferred` | Postponed (with reason) |
| **Cancelled** | `cancelled` | Will not execute |

### 4.5 Priority Levels

| Priority | Code | Description |
|----------|------|-------------|
| **Critical** | `critical` | Must do immediately |
| **High** | `high` | Should do this quarter |
| **Medium** | `medium` | Plan for this year |
| **Low** | `low` | Nice to have |

---

## 5. Entity Definitions (Deployed DDL)

### 5.1 Finding

Captures a documented assessment observation for a specific domain. Findings can be manually entered, auto-generated from Technology Lifecycle data, or imported from external assessments.

```sql
CREATE TABLE public.findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- NULL = namespace-wide
  
  -- Classification
  assessment_domain TEXT NOT NULL,
  impact TEXT NOT NULL DEFAULT 'medium',
  
  -- Content
  title TEXT NOT NULL,
  rationale TEXT NOT NULL,
  as_of_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Source tracking (v1.1)
  source_type TEXT NOT NULL DEFAULT 'manual',
  source_reference_id UUID,  -- FK to technology_products, software_products, etc.
  
  -- Audit
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT findings_domain_check CHECK (
    assessment_domain IN ('icoms', 'bpa', 'ti', 'dqa', 'cr', 'other')
  ),
  CONSTRAINT findings_impact_check CHECK (
    impact IN ('high', 'medium', 'low')
  ),
  CONSTRAINT findings_source_type_check CHECK (
    source_type IN ('manual', 'computed', 'imported')
  )
);

CREATE INDEX idx_findings_namespace ON public.findings(namespace_id);
CREATE INDEX idx_findings_workspace ON public.findings(workspace_id);
CREATE INDEX idx_findings_domain ON public.findings(assessment_domain);
CREATE INDEX idx_findings_source_type ON public.findings(source_type);
CREATE INDEX idx_findings_source_ref ON public.findings(source_reference_id) 
  WHERE source_reference_id IS NOT NULL;
```

**Entity Description:**

| Field | Purpose |
|-------|---------|
| `assessment_domain` | Which area of IT does this finding relate to? |
| `impact` | How significant is this finding? (H/M/L) |
| `title` | Short summary ("RHEL 7 End of Support — SirsiDynix Symphony at Risk") |
| `rationale` | Full explanation with evidence |
| `as_of_date` | When was this finding recorded? |
| `workspace_id` | Optional — finding can be namespace-wide or workspace-specific |
| `source_type` | **v1.1** — `manual` (human entered), `computed` (auto-generated from lifecycle/cost data), `imported` (external CSV/assessment) |
| `source_reference_id` | **v1.1** — FK to the record that triggered a computed finding (e.g., `technology_products.id` for lifecycle findings, `software_products.id` for licensing findings). Provides pipeline traceability without adding enum values per pipeline. |

**Source Type Design Decision (v1.1):** `source_type` stays as three values (`manual`, `computed`, `imported`). The `source_reference_id` provides granularity — pointing to `technology_products` for lifecycle-generated findings vs `software_products` or `product_contracts` for cost-generated findings. This avoids enum maintenance burden while preserving traceability.

---

### 5.2 Initiative

The core entity that answers "So What?" — a recommended action with timeline, cost, and run rate impact.

```sql
CREATE TABLE public.initiatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- NULL = namespace-wide
  
  -- Classification
  assessment_domain TEXT NOT NULL,
  strategic_theme TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium',
  
  -- Content
  title TEXT NOT NULL,
  description TEXT,
  
  -- Timeline
  time_horizon TEXT NOT NULL DEFAULT 'q2',
  target_start_date DATE,
  target_end_date DATE,
  actual_start_date DATE,
  actual_end_date DATE,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'identified',
  status_notes TEXT,
  
  -- Ownership
  owner_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  
  -- Initiative costs (what it costs to execute)
  one_time_cost_low DECIMAL,
  one_time_cost_high DECIMAL,
  recurring_cost_low DECIMAL,
  recurring_cost_high DECIMAL,
  cost_frequency TEXT DEFAULT 'annual',
  
  -- Run rate impact (v1.1 — what it does to annual IT spend)
  estimated_run_rate_change DECIMAL,  -- positive = increase, negative = savings
  run_rate_change_rationale TEXT,     -- "Eliminates $45K QB licensing, adds $60K ERP"
  
  -- Value / Benefits
  expected_benefit TEXT,
  benefit_type TEXT,
  
  -- Source
  source_finding_id UUID REFERENCES findings(id) ON DELETE SET NULL,
  created_from_assessment BOOLEAN DEFAULT true,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT initiatives_domain_check CHECK (
    assessment_domain IN ('icoms', 'bpa', 'ti', 'dqa', 'cr', 'other')
  ),
  CONSTRAINT initiatives_theme_check CHECK (
    strategic_theme IN ('optimize', 'growth', 'risk')
  ),
  CONSTRAINT initiatives_priority_check CHECK (
    priority IN ('critical', 'high', 'medium', 'low')
  ),
  CONSTRAINT initiatives_horizon_check CHECK (
    time_horizon IN ('q1', 'q2', 'q3', 'q4', 'beyond')
  ),
  CONSTRAINT initiatives_status_check CHECK (
    status IN ('identified', 'planned', 'in_progress', 'completed', 'deferred', 'cancelled')
  ),
  CONSTRAINT initiatives_frequency_check CHECK (
    cost_frequency IS NULL OR cost_frequency IN ('monthly', 'quarterly', 'annual')
  ),
  CONSTRAINT initiatives_benefit_check CHECK (
    benefit_type IS NULL OR benefit_type IN (
      'cost_savings', 'risk_reduction', 'growth_enablement', 
      'efficiency', 'compliance', 'other'
    )
  )
);

CREATE INDEX idx_initiatives_namespace ON public.initiatives(namespace_id);
CREATE INDEX idx_initiatives_workspace ON public.initiatives(workspace_id);
CREATE INDEX idx_initiatives_domain ON public.initiatives(assessment_domain);
CREATE INDEX idx_initiatives_theme ON public.initiatives(strategic_theme);
CREATE INDEX idx_initiatives_status ON public.initiatives(status);
CREATE INDEX idx_initiatives_owner ON public.initiatives(owner_contact_id);
CREATE INDEX idx_initiatives_finding ON public.initiatives(source_finding_id) 
  WHERE source_finding_id IS NOT NULL;
```

**Entity Description:**

| Field | Purpose |
|-------|---------|
| `strategic_theme` | Optimize, Growth, or Risk |
| `priority` | Critical/High/Medium/Low |
| `time_horizon` | Q1/Q2/Q3/Q4/Beyond |
| `status` | Identified → Planned → In Progress → Completed |
| `owner_contact_id` | Who is accountable? |
| `one_time_cost_*` | Range estimate for non-recurring costs (what it costs to execute) |
| `recurring_cost_*` | Range estimate for ongoing costs of the initiative itself |
| `estimated_run_rate_change` | **v1.1** — Net annual impact on IT Run Rate. Positive = run rate increases, negative = savings. This is DIFFERENT from initiative cost — it captures the downstream effect. |
| `run_rate_change_rationale` | **v1.1** — Explanation of run rate impact (e.g., "Eliminates $45K QB licensing, adds $60K ERP SaaS = +$15K net") |
| `source_finding_id` | Links back to the finding that drove this initiative |
| `expected_benefit` | What value will this create? |

**Run Rate Impact Design Decision (v1.1):** Two explicit fields rather than computing from linked DP costs. The consultant or IT leader knows the run rate impact when creating the initiative — it's a number from their analysis. Computing it automatically from DP cost changes requires full cost model population AND meaningful relationship types, which is fragile for MVP. Automatic computation is a Phase 2 optimization.

---

### 5.3 Initiative ↔ Deployment Profile (Junction)

Links initiatives to the deployment profiles they affect.

```sql
CREATE TABLE public.initiative_deployment_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  deployment_profile_id UUID NOT NULL REFERENCES deployment_profiles(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL DEFAULT 'impacted',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT initiative_dps_unique UNIQUE (initiative_id, deployment_profile_id),
  CONSTRAINT initiative_dps_type_check CHECK (
    relationship_type IN ('impacted', 'replaced', 'modernized', 'retired', 'dependent')
  )
);

CREATE INDEX idx_initiative_dps_initiative ON public.initiative_deployment_profiles(initiative_id);
CREATE INDEX idx_initiative_dps_dp ON public.initiative_deployment_profiles(deployment_profile_id);
```

---

### 5.4 Initiative ↔ IT Service (Junction)

Links initiatives to IT services they affect.

```sql
CREATE TABLE public.initiative_it_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  it_service_id UUID NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL DEFAULT 'impacted',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT initiative_services_unique UNIQUE (initiative_id, it_service_id),
  CONSTRAINT initiative_services_type_check CHECK (
    relationship_type IN ('impacted', 'replaced', 'enhanced', 'dependent')
  )
);

CREATE INDEX idx_initiative_services_initiative ON public.initiative_it_services(initiative_id);
CREATE INDEX idx_initiative_services_service ON public.initiative_it_services(it_service_id);
```

---

### 5.5 Initiative Comments / Activity Log (Deferred)

Deferred to polish pass. The `initiative_comments` table adds status change tracking, cost update history, and discussion threading. Complexity of activity log management doesn't add demo value for MVP. Audit trail is covered by the existing `audit_log` trigger on all four deployed tables.

**Planned schema (for future implementation):**

```sql
CREATE TABLE public.initiative_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  comment_type TEXT NOT NULL DEFAULT 'comment',
  content TEXT NOT NULL,
  old_status TEXT,
  new_status TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT initiative_comments_type_check CHECK (
    comment_type IN ('comment', 'status_change', 'cost_update', 'date_change')
  )
);
```

---

## 6. Reporting Views (Deployed)

### 6.1 vw_finding_summary

Powers the Scorecard — one row per domain with aggregate impact.

```sql
CREATE OR REPLACE VIEW public.vw_finding_summary
WITH (security_invoker=true)
AS
SELECT
  f.namespace_id,
  f.assessment_domain,
  CASE f.assessment_domain
    WHEN 'icoms' THEN 'IT Operating Model & Spend'
    WHEN 'bpa'   THEN 'Business Process & Applications'
    WHEN 'ti'    THEN 'Technology Infrastructure'
    WHEN 'dqa'   THEN 'Data Quality & Analytics'
    WHEN 'cr'    THEN 'Cybersecurity Risk'
    WHEN 'other' THEN 'Other'
  END AS domain_name,
  CASE
    WHEN bool_or(f.impact = 'high') THEN 'high'
    WHEN bool_or(f.impact = 'medium') THEN 'medium'
    ELSE 'low'
  END AS domain_impact,
  count(*) AS finding_count,
  count(*) FILTER (WHERE f.impact = 'high') AS high_count,
  count(*) FILTER (WHERE f.impact = 'medium') AS medium_count,
  count(*) FILTER (WHERE f.impact = 'low') AS low_count,
  count(*) FILTER (WHERE f.source_type = 'computed') AS computed_count,
  count(*) FILTER (WHERE f.source_type = 'manual') AS manual_count,
  max(f.as_of_date) AS latest_finding_date
FROM findings f
GROUP BY f.namespace_id, f.assessment_domain;
```

### 6.2 vw_initiative_summary

Powers the Roadmap table, Investment Summary, and Workspace dashboard. Includes cost midpoints, run rate impact, linked entity counts, and owner information.

```sql
CREATE OR REPLACE VIEW public.vw_initiative_summary
WITH (security_invoker=true)
AS
SELECT
  i.namespace_id,
  i.workspace_id,
  w.name AS workspace_name,
  i.id AS initiative_id,
  i.title,
  i.assessment_domain,
  CASE i.assessment_domain
    WHEN 'icoms' THEN 'IT Operating Model & Spend'
    WHEN 'bpa'   THEN 'Business Process & Applications'
    WHEN 'ti'    THEN 'Technology Infrastructure'
    WHEN 'dqa'   THEN 'Data Quality & Analytics'
    WHEN 'cr'    THEN 'Cybersecurity Risk'
    WHEN 'other' THEN 'Other'
  END AS domain_name,
  i.strategic_theme,
  i.priority,
  i.time_horizon,
  i.status,
  i.owner_contact_id,
  c.display_name AS owner_name,
  ROUND((COALESCE(i.one_time_cost_low, 0) + COALESCE(i.one_time_cost_high, 0)) / 2) AS one_time_cost_mid,
  ROUND((COALESCE(i.recurring_cost_low, 0) + COALESCE(i.recurring_cost_high, 0)) / 2) AS recurring_cost_mid,
  i.one_time_cost_low,
  i.one_time_cost_high,
  i.recurring_cost_low,
  i.recurring_cost_high,
  COALESCE(i.estimated_run_rate_change, 0) AS run_rate_change,
  i.run_rate_change_rationale,
  i.source_finding_id,
  f.title AS source_finding_title,
  i.expected_benefit,
  i.benefit_type,
  (SELECT count(*) FROM initiative_deployment_profiles idp WHERE idp.initiative_id = i.id) AS linked_dp_count,
  (SELECT count(*) FROM initiative_it_services iis WHERE iis.initiative_id = i.id) AS linked_service_count,
  i.target_start_date,
  i.target_end_date,
  i.created_at
FROM initiatives i
LEFT JOIN workspaces w ON w.id = i.workspace_id
LEFT JOIN contacts c ON c.id = i.owner_contact_id
LEFT JOIN findings f ON f.id = i.source_finding_id;
```

---

## 7. Conceptual ERD

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                        IT VALUE CREATION MODULE                              │
└───────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐
│    Namespace    │         │    Workspace    │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │ 1:N                       │ 1:N (optional)
         ▼                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Finding                                    │
├─────────────────────────────────────────────────────────────────────┤
│ id, namespace_id, workspace_id                                     │
│ assessment_domain (icoms, bpa, ti, dqa, cr, other)                 │
│ impact (H/M/L)                                                     │
│ title, rationale, as_of_date                                       │
│ source_type (manual/computed/imported), source_reference_id  (v1.1)│
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N (Finding can spawn multiple Initiatives)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Initiative                                  │
├─────────────────────────────────────────────────────────────────────┤
│ id, namespace_id, workspace_id                                     │
│ assessment_domain, strategic_theme (Optimize/Growth/Risk)          │
│ priority (Critical/High/Medium/Low)                                │
│ title, description                                                 │
│ time_horizon (Q1/Q2/Q3/Q4/Beyond)                                  │
│ status (Identified → Planned → In Progress → Completed)            │
│ owner_contact_id                                                   │
│ one_time_cost_low, one_time_cost_high                              │
│ recurring_cost_low, recurring_cost_high, cost_frequency            │
│ estimated_run_rate_change, run_rate_change_rationale         (v1.1)│
│ expected_benefit, benefit_type                                     │
│ source_finding_id                                                  │
└─────────┬───────────────────────────────────────────────┬──────────┘
          │                                               │
          │ N:M                                           │ N:M
          ▼                                               ▼
┌─────────────────────────────┐                 ┌─────────────────────────┐
│ InitiativeDeployment        │                 │ InitiativeITService     │
│ Profiles (junction)         │                 │ (junction)              │
├─────────────────────────────┤                 ├─────────────────────────┤
│ initiative_id               │                 │ initiative_id           │
│ deployment_profile_id       │                 │ it_service_id           │
│ relationship_type           │                 │ relationship_type       │
│ (impacted/replaced/         │                 │ (impacted/replaced/     │
│  modernized/retired/        │                 │  enhanced/dependent)    │
│  dependent)                 │                 │                         │
└───────────┬─────────────────┘                 └───────────┬─────────────┘
            │                                               │
            ▼                                               ▼
┌─────────────────────────────┐                 ┌─────────────────────────┐
│   DeploymentProfile         │                 │       ITService         │
│   (existing)                │                 │       (existing)        │
└─────────────────────────────┘                 └─────────────────────────┘
```

---

## 8. UI Components

### 8.1 IT Value Creation Scorecard

The living version of IT Ally's scorecard. Powered by `vw_finding_summary`.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  IT VALUE CREATION SCORECARD                              As of: 2026-02-22│
├─────────────────────────┬────────┬──────────────────────────────────────────┤
│  Category               │ Impact │ Finding Summary                          │
├─────────────────────────┼────────┼──────────────────────────────────────────┤
│  Operating Model (ICOMS)│   🟡   │ IT Governance Limited to Operational...  │
│  Applications (BPA)     │   🔴   │ ERP System Cannot Scale Beyond Current...│
│  Infrastructure (TI)    │   🔴   │ RHEL 7 End of Support — SirsiDynix...   │
│  Data Quality (DQA)     │   🟢   │ Asset Inventory Partially Maintained     │
│  Cybersecurity (CR)     │   🔴   │ No Formal Vulnerability Management...    │
└─────────────────────────┴────────┴──────────────────────────────────────────┘

                   [Edit Findings]                    [Export Scorecard]
```

**Behavior:**
- Displays one row per `assessment_domain`
- Shows highest-impact finding per domain
- Impact indicator (🔴🟡🟢) from `domain_impact` in `vw_finding_summary`
- Click row to see all findings for that domain
- "Edit Findings" opens modal to add/edit findings
- Computed findings show source badge (e.g., "Auto-generated from Technology Health")

---

### 8.2 Initiative Roadmap Table

The living version of IT Ally's roadmap. Powered by `vw_initiative_summary`.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  VALUE CREATION ROADMAP                                               [+ Add Init.]│
├───────┬──────────┬─────────────────────────────┬────────┬────────┬───────┬──────────┤
│ Area  │  Theme   │ Initiative                  │Horizon │ Status │ Cost  │ Δ Run Rate│
├───────┼──────────┼─────────────────────────────┼────────┼────────┼───────┼──────────┤
│ TI    │ 🔴 Risk  │ Upgrade SirsiDynix Infra    │ Q1     │ 📋 Plan│ $35K  │ +$3K/yr  │
│ CR    │ 🔴 Risk  │ Vuln Management Program     │ Q1     │ 🔄 WIP │ $15K  │ +$10K/yr │
│ TI    │ 🔴 Risk  │ Migrate SQL Server 2016     │ Q2     │ 📋 Plan│ $23K  │ $0/yr    │
│ ICOMS │ 🟢 Opt   │ IT Strategic Planning       │ Q2     │ 📋 Plan│ $8K   │ $0/yr    │
│ TI    │ 🟢 Opt   │ Oracle 19c → 23ai Path      │ Q3     │ ⏳ ID  │ $60K  │ -$15K/yr │
│ BPA   │ 🔵 Grow  │ ERP Evaluation & Replace    │ Q3     │ ⏳ ID  │ $225K │ +$15K/yr │
├───────┴──────────┴─────────────────────────────┴────────┴────────┼───────┼──────────┤
│                                                    TOTALS        │ $366K │ +$13K/yr │
└──────────────────────────────────────────────────────────────────┴───────┴──────────┘

Filters: [All Themes ▼] [All Horizons ▼] [All Statuses ▼] [All Domains ▼]
```

**v1.1 Changes:**
- Added **Δ Run Rate** column showing `estimated_run_rate_change` per initiative
- Footer row shows totals: sum of `one_time_cost_mid` and sum of `run_rate_change`
- Status icons: ⏳ Identified, 📋 Planned, 🔄 In Progress, ✅ Completed, ⏸️ Deferred

---

### 8.3 Initiative Detail Panel

Slide-out panel when clicking an initiative.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  [←]  Upgrade SirsiDynix Symphony Infrastructure                       [Edit] │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  Status: 📋 Planned    Theme: 🔴 Risk    Priority: 🔴 Critical              │
│  Domain: TI             Horizon: Q1       Owner: TBD                           │
│                                                                                │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                │
│  DESCRIPTION                                                                   │
│  Migrate SirsiDynix Symphony from RHEL 7 to RHEL 9. Coordinate with vendor   │
│  for application compatibility certification. Include Oracle 19c upgrade       │
│  path assessment.                                                              │
│                                                                                │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                │
│  COSTS                                                                         │
│  ┌────────────────────────┬────────────────────────┬────────────────────────┐  │
│  │ One-Time               │ Recurring (Annual)     │ Run Rate Impact (v1.1)│  │
│  │ $25K - $45K            │ $2K - $5K              │ +$3,000/yr            │  │
│  └────────────────────────┴────────────────────────┴────────────────────────┘  │
│  Rationale: RHEL 9 support subscription slightly higher than legacy RHEL 7     │
│                                                                                │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                │
│  SOURCE FINDING                                                                │
│  🔴 RHEL 7 End of Support — SirsiDynix Symphony at Risk                      │
│                                                                                │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                │
│  LINKED DEPLOYMENT PROFILES                    LINKED IT SERVICES             │
│  (none yet — link via [+ Add DP])              (none yet)                     │
│                                                                                │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                │
│  EXPECTED BENEFIT                                                              │
│  Eliminates critical security exposure on EOL platform                         │
│  Type: Risk Reduction                                                          │
│                                                                                │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### 8.4 Value Creation Dashboard

Combined view with scorecard, initiative status, and investment summary.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  VALUE CREATION DASHBOARD                           City of Riverside           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  SCORECARD SUMMARY                    INITIATIVE STATUS                        │
│  ┌───────────────────────────┐       ┌───────────────────────────────────────┐ │
│  │ 🔴 High Impact:   3       │       │ ✅ Completed    0                     │ │
│  │ 🟡 Medium Impact: 4       │       │ 🔄 In Progress  █ 1                  │ │
│  │ 🟢 Low Impact:    1       │       │ 📋 Planned      ████ 3               │ │
│  └───────────────────────────┘       │ ⏳ Identified   ██ 2                  │ │
│                                      └───────────────────────────────────────┘ │
│                                                                                │
│  BY THEME                              BY TIME HORIZON                         │
│  ┌─────────────────────────┐          ┌─────────────────────────────────────┐  │
│  │ 🟢 Optimize    ██ 2     │          │ Q1  ██ 2 initiatives               │  │
│  │ 🔵 Growth      █ 1      │          │ Q2  ██ 2 initiatives               │  │
│  │ 🔴 Risk        ███ 3    │          │ Q3  ██ 2 initiatives               │  │
│  └─────────────────────────┘          └─────────────────────────────────────┘  │
│                                                                                │
│  INVESTMENT SUMMARY (v1.1 — includes Run Rate Impact)                         │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                           │ │
│  │  One-Time Investment:      $245K - $485K (midpoint: $366K)               │ │
│  │  Annual Recurring Cost:    $50K - $77K                                    │ │
│  │  Net Run Rate Impact:      +$13,000/yr                                    │ │
│  │                                                                           │ │
│  │  By Theme:                                                                │ │
│  │    Optimize:  $48K one-time    -$15K run rate                            │ │
│  │    Growth:    $225K one-time   +$15K run rate                            │ │
│  │    Risk:      $73K one-time    +$13K run rate                            │ │
│  │                                                                           │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                │
│  NEXT ACTIONS DUE                                                              │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │ • Upgrade SirsiDynix Infrastructure — Q1 — owner: TBD                    │ │
│  │ • Implement Vulnerability Management — Q1 — 🔄 In Progress              │ │
│  │ • Migrate SQL Server 2016 — Q2 — owner: TBD                             │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Calculation Rules

### 9.1 Investment Summary

```
Total One-Time (Low)  = Sum(Initiative.one_time_cost_low where status != 'cancelled')
Total One-Time (High) = Sum(Initiative.one_time_cost_high where status != 'cancelled')

Total Recurring (Low)  = Sum(Initiative.recurring_cost_low * annualization_factor)
Total Recurring (High) = Sum(Initiative.recurring_cost_high * annualization_factor)

Annualization Factor:
  - monthly: × 12
  - quarterly: × 4
  - annual: × 1
```

### 9.2 Run Rate Impact (v1.1)

```
Net Run Rate Impact = Sum(Initiative.estimated_run_rate_change where status != 'cancelled')

By Theme:
  Optimize Impact = Sum(estimated_run_rate_change where strategic_theme = 'optimize')
  Growth Impact   = Sum(estimated_run_rate_change where strategic_theme = 'growth')
  Risk Impact     = Sum(estimated_run_rate_change where strategic_theme = 'risk')

By Workspace (for namespace-level dashboard):
  Per-Workspace Impact = Sum(estimated_run_rate_change where workspace_id = :ws_id)
```

### 9.3 Progress Metrics

```
Completion Rate = Count(status = 'completed') / Count(all initiatives)

By Theme:
  Optimize Initiatives = Count(strategic_theme = 'optimize')
  Growth Initiatives   = Count(strategic_theme = 'growth')
  Risk Initiatives     = Count(strategic_theme = 'risk')

By Horizon:
  Q1 Initiatives = Count(time_horizon = 'q1')
  Q2 Initiatives = Count(time_horizon = 'q2')
  etc.
```

### 9.4 Scorecard Impact Roll-up

```
Domain Impact = MAX(Finding.impact) for each assessment_domain

Display Logic:
  - If any finding is 'high' → 🔴
  - Else if any finding is 'medium' → 🟡
  - Else → 🟢
```

---

## 10. RLS Policies (Deployed)

All four tables follow the standard GetInSync RLS pattern with `get_current_namespace_id()`, `check_is_platform_admin()`, and `check_is_namespace_admin_of_namespace()`.

### 10.1 Findings & Initiatives (Same Pattern)

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | All namespace members | `namespace_id = get_current_namespace_id()` AND (workspace_id IS NULL OR workspace visible) |
| INSERT | Namespace admins + workspace admins/editors | Same namespace check + role check via `workspace_users` |
| UPDATE | Namespace admins + workspace admins/editors | Same as INSERT |
| DELETE | Namespace admins + workspace admins only | Same namespace check + admin role only |

Platform admins bypass all restrictions.

### 10.2 Junction Tables (initiative_deployment_profiles, initiative_it_services)

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | Anyone who can see the parent initiative | `initiative_id IN (SELECT id FROM initiatives WHERE namespace_id = current)` |
| INSERT/UPDATE | Anyone who can edit the parent initiative | Same + workspace editor role check |
| DELETE | Namespace admins + workspace admins | Same + admin role only |

### 10.3 Namespace-Wide vs Workspace-Scoped

- Findings/Initiatives with `workspace_id = NULL` are **namespace-wide** — visible to all namespace members, editable only by namespace admins
- Findings/Initiatives with `workspace_id` set are **workspace-scoped** — visible/editable per workspace role
- This enables the PE/Government/Enterprise multi-persona model (Section 2)

---

## 11. Security Posture

| Table | RLS | Policies | GRANTs | Audit Trigger | Updated_at Trigger |
|-------|-----|----------|--------|---------------|-------------------|
| findings | ✅ | 4 (S/I/U/D) | 4 | ✅ | ✅ |
| initiatives | ✅ | 4 (S/I/U/D) | 4 | ✅ | ✅ |
| initiative_deployment_profiles | ✅ | 4 (S/I/U/D) | 4 | ✅ | N/A (no updated_at) |
| initiative_it_services | ✅ | 4 (S/I/U/D) | 4 | ✅ | N/A (no updated_at) |

Both views use `security_invoker=true` to enforce RLS through the view layer.

**Post-deployment stats:** 86 tables, 331 RLS policies, 33 audit triggers, 25 views, 53 functions.

---

## 12. Tier Gating

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| View Scorecard | ✅ | ✅ | ✅ | ✅ |
| View Initiatives (5 max) | ✅ | ✅ | ✅ | ✅ |
| Add Findings | ❌ | ✅ | ✅ | ✅ |
| Add Initiatives (unlimited) | ❌ | ❌ | ✅ | ✅ |
| Link to DPs/Services | ❌ | ❌ | ✅ | ✅ |
| Run Rate Impact | ❌ | ❌ | ✅ | ✅ |
| Activity Log | ❌ | ❌ | ✅ | ✅ |
| Export Roadmap | ❌ | ❌ | ✅ | ✅ |
| Cost Tracking | ❌ | ❌ | ❌ | ✅ |
| Benefit Tracking | ❌ | ❌ | ❌ | ✅ |
| Namespace Summary Dashboard | ❌ | ❌ | ❌ | ✅ |

---

## 13. Integration with Existing Entities

### 13.1 From TIME/PAID to Initiatives

When an application falls into certain quadrants, suggest initiatives:

| Quadrant | Suggested Initiative |
|----------|---------------------|
| **Eliminate** (TIME) | "Decommission [App Name]" |
| **Modernize** (TIME) | "Modernize [App Name] — Improve tech health" |
| **Address** (PAID) | "Address [App Name] — Mitigate technical risk" |
| **Divest** (PAID) | "Divest [App Name] — Reduce criticality or replace" |

### 13.2 From Technology Lifecycle to Findings (v1.1)

Auto-generated findings pipeline from Technology Health Dashboard:

```
technology_lifecycle_reference (EOL/EOS dates)
    → technology_products (deployed in namespace)
        → deployment_profile_technology_products (which DPs use it)
            → Finding (source_type='computed', source_reference_id=technology_products.id)
```

**Example:** "Your CMDB told us SQL Server 2016 reaches End of Support in July. GetInSync automatically created a finding and suggested an initiative to upgrade."

### 13.3 From Remediation Effort to Initiative Cost

When creating an initiative linked to a DP with `remediation_effort`:

```
Suggested One-Time Cost Range:
  XS → $0 - $25K
  S  → $25K - $100K
  M  → $100K - $250K
  L  → $250K - $500K
  XL → $500K - $1M
  2XL → $1M+
```

### 13.4 DP Cost Impact → Run Rate (v1.1)

When an initiative affects a DP's cost:
- Retiring a DP → **reduces** run rate (negative `estimated_run_rate_change`)
- Modernizing a DP → **increases** one-time cost, may change run rate
- Replacing a DP → **one-time cost** for migration, potential run rate change

The `estimated_run_rate_change` field captures the net annual impact explicitly rather than computing from DP costs (see Design Decision in Section 5.2).

### 13.5 ITSM Integration Readiness (v1.1)

IT Value Creation entities map cleanly to ServiceNow without schema changes:

| GIS Entity | SN Target | Sync Direction | Notes |
|------------|-----------|----------------|-------|
| Finding | sn_grc_issue or custom | Publish (future) | UUID PK = correlation_id |
| Initiative | pm_project / change_request / demand | Publish (future) | Status/priority/dates map directly |

**Initiative → ServiceNow Demand field mapping:**
- `title` → `short_description`
- `description` → `description`
- `priority` → `priority` (code mapping)
- `status` → `state` (code mapping)
- `owner_contact_id` → `requested_by` (contact → sys_user)
- `one_time_cost_high` → `estimated_cost`
- `target_start_date` → `start_date`
- `target_end_date` → `end_date`
- `strategic_theme` → `category` (mapping)

The `integration_sync_map` entity_type field (Phase 37) is generic — adding 'finding'/'initiative' is config, not schema change.

---

## 14. Seed Data (Riverside Demo)

Deployed to City of Riverside namespace for demo purposes:

### 14.1 Findings (8 records)

| Domain | Impact | Title | Source |
|--------|--------|-------|--------|
| ti | 🔴 High | RHEL 7 End of Support — SirsiDynix Symphony at Risk | computed |
| ti | 🟡 Medium | Oracle 19c Entering Extended Support Window | computed |
| ti | 🟡 Medium | SQL Server 2016 Approaching End of Support | computed |
| bpa | 🔴 High | ERP System Cannot Scale Beyond Current Operations | manual |
| bpa | 🟡 Medium | Redundant Systems in Public Safety | manual |
| cr | 🔴 High | No Formal Vulnerability Management Program | manual |
| icoms | 🟡 Medium | IT Governance Limited to Operational Support | manual |
| dqa | 🟢 Low | Asset Inventory Partially Maintained | manual |

### 14.2 Initiatives (6 records)

| Theme | Priority | Title | Cost Mid | Δ Run Rate |
|-------|----------|-------|----------|------------|
| 🔴 Risk | Critical | Upgrade SirsiDynix Symphony Infrastructure | $35K | +$3K/yr |
| 🔴 Risk | High | Migrate SQL Server 2016 to 2022 | $23K | $0/yr |
| 🔴 Risk | Critical | Implement Vulnerability Management Program | $15K | +$10K/yr |
| 🟢 Optimize | Medium | Plan Oracle 19c to 23ai Migration Path | $60K | -$15K/yr |
| 🟢 Optimize | Medium | Establish IT Strategic Planning Process | $8K | $0/yr |
| 🔵 Growth | High | ERP Evaluation and Replacement | $225K | +$15K/yr |

All 6 initiatives are linked to source findings via `source_finding_id`.

---

## 15. Relationship to `application_roadmap` (Existing Stub)

The existing `application_roadmap` table serves a **different purpose**:

| Aspect | `application_roadmap` | `initiatives` |
|--------|----------------------|---------------|
| **Scope** | Single application | Namespace or workspace-wide |
| **Focus** | Lifecycle events (upgrade, decommission) | Strategic initiatives (assess, recommend, execute) |
| **Timeline** | Specific date | Quarter / horizon |
| **Cost** | Not tracked | One-time + recurring + run rate impact |
| **Status** | Planned/In Progress/Completed | Full workflow with accountability |
| **Theme** | None | Optimize/Growth/Risk |

**Recommendation:** Keep both tables. `application_roadmap` is for **tactical app lifecycle**, while `initiatives` is for **strategic value creation**.

An initiative might *result* in an `application_roadmap` entry:
- Initiative: "Replace QuickBooks with scalable ERP"
- → Creates `application_roadmap` entry: `event_type='decommission'` for QuickBooks

---

## 16. Open Questions

1. ~~**Should initiatives be at Namespace or Workspace level?**~~
   **RESOLVED (v1.1):** Either. Workspace-scoped initiatives are visible only to that workspace. Namespace-scoped initiatives (`workspace_id = NULL`) are visible to all. This enables the PE/Government/Enterprise multi-persona model.

2. **Should we auto-generate initiatives from TIME/PAID quadrants?**
   Possible enhancement: "Suggest Initiatives" button that creates draft initiatives for all Eliminate/Modernize/Address apps.

3. **Should there be approval workflow for initiatives?**
   Future enhancement: Require Admin approval to move from Identified → Planned. The current status field supports this manually.

4. **Should we track actual spend vs. estimated?**
   Future enhancement: Add `actual_one_time_cost` and `actual_recurring_cost` fields for post-execution tracking.

5. ~~**How to handle PE cross-portfolio comparison?**~~
   **RESOLVED (v1.1):** Portfolio companies as workspaces within a PE firm namespace. Namespace-level dashboard aggregates across workspaces. No cross-namespace views needed.

6. **Should the namespace-level dashboard label be configurable?**
   Future enhancement: Allow namespace settings to control whether the summary is labeled "Portfolio," "Ministry," or "Business Unit." Currently context-dependent in code.

7. **Should auto-generated findings include remediation suggestions?**
   Future enhancement: Computed findings from Technology Lifecycle could auto-suggest initiatives (e.g., "SQL Server 2016 EOL → suggest upgrade initiative with cost estimate from remediation_effort t-shirt size").

---

## 17. API Endpoints (Future)

```
GET    /api/v1/namespaces/:ns_id/findings
POST   /api/v1/namespaces/:ns_id/findings
GET    /api/v1/namespaces/:ns_id/findings/:id
PUT    /api/v1/namespaces/:ns_id/findings/:id
DELETE /api/v1/namespaces/:ns_id/findings/:id

GET    /api/v1/namespaces/:ns_id/initiatives
POST   /api/v1/namespaces/:ns_id/initiatives
GET    /api/v1/namespaces/:ns_id/initiatives/:id
PUT    /api/v1/namespaces/:ns_id/initiatives/:id
DELETE /api/v1/namespaces/:ns_id/initiatives/:id

POST   /api/v1/namespaces/:ns_id/initiatives/:id/comments  (deferred)
GET    /api/v1/namespaces/:ns_id/initiatives/:id/comments   (deferred)

POST   /api/v1/namespaces/:ns_id/initiatives/:id/link-dp
DELETE /api/v1/namespaces/:ns_id/initiatives/:id/link-dp/:dp_id

POST   /api/v1/namespaces/:ns_id/initiatives/:id/link-service
DELETE /api/v1/namespaces/:ns_id/initiatives/:id/link-service/:service_id

GET    /api/v1/namespaces/:ns_id/value-creation/dashboard
GET    /api/v1/namespaces/:ns_id/value-creation/scorecard
GET    /api/v1/namespaces/:ns_id/value-creation/investment-summary
GET    /api/v1/namespaces/:ns_id/value-creation/workspace-summary  (v1.1)
```

---

## 18. Migration / Seeding

### 18.1 Seed Default Findings (Optional)

For new namespaces, optionally seed placeholder findings:

```sql
INSERT INTO findings (namespace_id, assessment_domain, impact, title, rationale, as_of_date, source_type)
VALUES
  (:ns_id, 'icoms', 'medium', 'IT Operating Model', 'Assessment pending', CURRENT_DATE, 'manual'),
  (:ns_id, 'bpa', 'medium', 'Business Applications', 'Assessment pending', CURRENT_DATE, 'manual'),
  (:ns_id, 'ti', 'medium', 'Technology Infrastructure', 'Assessment pending', CURRENT_DATE, 'manual'),
  (:ns_id, 'dqa', 'medium', 'Data Quality & Analytics', 'Assessment pending', CURRENT_DATE, 'manual'),
  (:ns_id, 'cr', 'medium', 'Cybersecurity Risk', 'Assessment pending', CURRENT_DATE, 'manual');
```

### 18.2 Import from IT Ally-style Assessment

If a consultant has an existing IT Ally-style report:

1. Parse the scorecard table → Create Findings (source_type='imported')
2. Parse the roadmap table → Create Initiatives
3. Link initiatives to findings by domain
4. Link initiatives to DPs by name matching (if applicable)
5. Set `estimated_run_rate_change` from consultant's analysis (v1.1)

---

## 19. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-12-29 | Initial draft. Defined Finding, Initiative, and junction tables. UI wireframes for Scorecard, Roadmap, Dashboard. |
| v1.1 | 2026-02-22 | **Schema deployed.** Added `source_type` + `source_reference_id` to findings for auto-generation pipeline. Added `estimated_run_rate_change` + `run_rate_change_rationale` to initiatives for IT Run Rate impact tracking. Added multi-persona dashboard architecture (PE/Government/Enterprise). Documented PE portfolio companies as workspaces model. Added ITSM integration field mapping (ServiceNow Demand/Change Request). Updated DDL to match deployed schema (auth.users FK, 30 columns on initiatives). Added reporting views (vw_finding_summary, vw_initiative_summary). Deferred initiative_comments to polish pass. Seeded Riverside demo data (8 findings, 6 initiatives). Resolved Open Questions #1 and #5. Database stats: 86 tables, 331 RLS policies, 33 audit triggers, 25 views. |

---

## 20. Summary

The IT Value Creation Module transforms GetInSync from an assessment tool into an **action-oriented APM platform**. By adding:

- **Findings** — Structured observations by domain (manual + auto-generated from lifecycle data)
- **Initiatives** — Actionable recommendations with cost, timeline, ownership, and run rate impact
- **Status Tracking** — From Identified to Completed (doubles as IT intake workflow)
- **Investment Summary** — One-time, recurring, and net run rate impact by theme
- **Living Dashboard** — Real-time scorecard and roadmap, with namespace-level workspace summary
- **Multi-Persona Support** — Same schema serves PE firms, government, and enterprise CTOs

GetInSync becomes **the only APM tool that answers "So What?"** — turning static assessments into dynamic roadmaps that drive measurable value creation.

The killer demo story: *"Your CMDB told us SQL Server 2016 reaches End of Support in July. GetInSync automatically created a finding and suggested an initiative to upgrade. Here's the projected impact on your IT Run Rate."*

---

End of document.
