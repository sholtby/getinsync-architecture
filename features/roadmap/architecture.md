# features/roadmap/architecture.md

**GetInSync Roadmap Module**
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
- What's the impact on our IT Run Rate?
- **What depends on what?** *(v1.2)*
- **Why are we doing this?** *(v1.2)*

And the APM tool has no answer. The consultant goes back to PowerPoint.

### The Solution

The **Roadmap Module** extends GetInSync from assessment to action.

**Entities (data model):**

1. **Findings** — Documented assessment observations by domain (manual + auto-generated)
2. **Ideas** — Lightweight intake suggestions from anyone in the organization *(v1.2)*
3. **Initiatives** — Strategic recommendations with cost, timeline, ownership, and run rate impact
4. **Initiative Dependencies** — Requires / enables / blocks relationships between initiatives *(v1.2)*
5. **Programs** — Strategic grouping with budget envelopes and business drivers *(v1.2)*

**UI components (presentation layer):**

6. **Scorecard** — Living findings dashboard by domain with impact distribution
7. **Roadmap** — Initiative table with status tracking and program filtering
8. **Scenario Planner** — Interactive Gantt with drag-drop scheduling, dependency awareness, what-if toggle, and run rate trajectory
9. **Investment Summary** — One-time, recurring, and net run rate impact by theme/program
10. **Value Dashboard** — Namespace-level workspace summary (PE QBR / Government CIO / Enterprise CTO view)

### The Value Proposition

> **GetInSync: The only APM tool that answers "So What?" and "What depends on what?"**

| For | Value |
|-----|-------|
| **IT Leaders** | Board-ready roadmap with dependency-aware scheduling |
| **Consultants** | Deliver assessments into the client's system; ongoing engagement |
| **PE Firms** | Track value creation across portfolio companies (workspaces) |
| **Government CIOs** | Ministry-level IT intake (Ideas) and annual planning (Programs) |
| **Enterprise CTOs** | Business unit budget cycle planning with program justification |
| **GetInSync** | Differentiation, stickiness, upsell path |

### v1.2 Origin — OG Entity Mapping & Dependency Planning

v1.2 was driven by a systematic mapping of GetInSync OG (original) entities against NextGen. The OG schema diagram revealed three entities not yet represented in NextGen:

1. **Ideas** — OG had a formal Idea → Project promotion workflow. NextGen replaces Projects with Initiatives but had no intake pipeline. Ideas fills this gap as a second upstream source alongside Findings.

2. **Programs** — OG grouped Projects into Programs with budget tracking. NextGen Initiatives had no grouping mechanism above the individual initiative. Programs provides the strategic envelope.

3. **Dependencies** — OG's "Projects impact Applications" arrow hinted at impact awareness, but never formalized inter-project dependencies. The real-world problem — "upgrading Cayenta Financials requires SQL Server 2022" — demands explicit dependency tracking. This is the "left hand knowing what the right hand is doing" problem.

### Two-Pipeline Model

```
PIPELINE 1: Assessment (expert-driven, top-down)
  Technology Health Dashboard detects RHEL 7 EOL
    → auto-generates Finding (source_type='computed')
      → assessor creates Initiative from finding

  Consultant performs BPA assessment
    → manually creates Finding (source_type='manual', impact='high')
      → creates Initiative with source_finding_id

PIPELINE 2: Intake (crowd-sourced, bottom-up)
  Ministry user submits Idea: "We need a citizen portal"
    → admin reviews, approves
      → system creates Initiative with source_idea_id
      → Idea status → 'approved', promoted_to_initiative_id set

  Ministry user submits Idea: "Replace all printers with iPads"
    → admin reviews, declines with review_notes
      → Idea status → 'declined'
      → Idea persists as historical record (governance audit trail)
```

Both pipelines feed into Initiatives. Initiatives can optionally be grouped into Programs with budget envelopes, and linked to each other via Dependencies.

---

## 2. Multi-Persona Dashboard Architecture (v1.1)

### 2.1 Same Schema, Three Personas

The Roadmap dashboard serves three distinct buyer personas using identical schema with context-dependent labels:

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
- **Programs** → PE firm creates programs that span workspaces ("Digital Transformation" across 3 portfolio companies) *(v1.2)*
- **Ideas** → Portfolio company employees submit Ideas within their workspace; PE partner reviews *(v1.2)*

### 2.3 Government IT Intake Model

Central IT receives intake requests from ministries each budget cycle:

1. Ministry users submit **Ideas** within their workspace (bottom-up) *(v1.2)*
2. Central IT creates **Findings** from assessment (top-down)
3. Both feed into **Initiatives** (approved Ideas + Finding-driven recommendations)
4. Related initiatives grouped into **Programs** with budget envelopes *(v1.2)*
5. Initiative **Dependencies** surface cross-ministry impacts *(v1.2)*
6. Initiative `status` workflow (`identified` → `planned` → `in_progress`) IS the intake workflow
7. Namespace-wide findings/ideas (`workspace_id = NULL`) capture cross-ministry observations

### 2.4 Namespace-Level Summary Dashboard

```
Portfolio / Ministry / Business Unit Summary
┌──────────────────┬──────────┬──────┬──────────┬─────────────┬────────┐
│ Unit             │ Run Rate │ Apps │ Findings │ Initiatives │ Ideas  │
├──────────────────┼──────────┼──────┼──────────┼─────────────┼────────┤
│ Finance          │ $800K    │ 34   │ 🔴 3     │ 2 planned   │ 4 new  │
│ Justice          │ $1.1M    │ 47   │ 🟡 2     │ 1 active    │ 1 new  │
│ Municipal Affairs│ $450K    │ 19   │ 🔴 4     │ 1 planned   │ 0      │
├──────────────────┼──────────┼──────┼──────────┼─────────────┼────────┤
│ All Units        │ $2.35M   │ 100  │ 9 total  │ 4 total     │ 5 new  │
│ Projected Impact │          │      │          │ -$50K/yr    │        │
│ Investment Req'd │          │      │          │ $430K       │        │
└──────────────────┴──────────┴──────┴──────────┴─────────────┴────────┘
```

---

## 3. Relationship to Existing Architecture

### 3.1 OG → NextGen Entity Mapping (v1.2)

Systematic mapping of all GetInSync OG entities to NextGen equivalents:

| # | OG Entity | NextGen Equivalent | Status | Notes |
|---|-----------|-------------------|--------|-------|
| 1 | Portfolios | `portfolios` + `portfolio_assignments` | ✅ Built | |
| 2 | Applications | `applications` | ✅ Built | |
| 3 | IT Services | `it_services` + service types | ✅ Built | |
| 4 | Factors | `assessment_factors` | ✅ Built | |
| 5 | Owners/SME/Support | `contacts` + `application_contacts` | ✅ Built | |
| 6 | People | `contacts` (namespace-scoped v1.9) | ✅ Built | |
| 7 | Technical Services Model | `service_types` + `service_type_categories` | ✅ Built | |
| 8 | Data Processes | `application_integrations` + `external_integrations` | ✅ Built | |
| 9 | Investment | Cost Model v2.5 (3 channels) | ✅ Built | |
| 10 | **Ideas** | **`ideas`** | 📋 v1.2 | Lightweight intake suggestions |
| 11 | **Projects** | **`initiatives`** (absorbs Projects) | ✅ Built | Initiatives = richer Projects |
| 12 | **Programs** | **`programs`** + **`program_initiatives`** | 📋 v1.2 | N:M grouping + budget |
| — | *(new)* Dependencies | **`initiative_dependencies`** | 📋 v1.2 | Not in OG |

**OG lifecycle preserved:**
```
OG:      Idea ──(approve)──► Project ──(group by)──► Program
NextGen: Idea ──(promote)──► Initiative ──(assign)──► Program
                                  ▲
         Finding ──(spawn)────────┘
```

**OG "Programs influence Factors" dropped.** Confirmed as aspirational — never fully implemented in OG. Programs in NextGen are pure grouping + budget, no assessment scoring influence.

### 3.2 What Already Exists (Deployed)

| Entity | Purpose | Deployed |
|--------|---------|----------|
| `findings` | Assessment observations by domain | ✅ v1.1 |
| `initiatives` | Strategic recommendations with cost/timeline | ✅ v1.1 |
| `initiative_deployment_profiles` | Link initiatives to DPs | ✅ v1.1 |
| `initiative_it_services` | Link initiatives to IT Services | ✅ v1.1 |
| `vw_finding_summary` | Scorecard aggregate view | ✅ v1.1 |
| `vw_initiative_summary` | Roadmap/investment view | ✅ v1.1 |

### 3.3 What's New in v1.2 (Proposed)

| Entity | Purpose | Proposed |
|--------|---------|----------|
| `ideas` | Lightweight intake/suggestion entity | 📋 v1.2 |
| `programs` | Initiative grouping + budget envelope | 📋 v1.2 |
| `program_initiatives` | N:M junction (program ↔ initiative) | 📋 v1.2 |
| `initiative_dependencies` | Bidirectional dependency graph | 📋 v1.2 |
| `initiatives.source_idea_id` | FK from initiative to originating idea | 📋 v1.2 |

### 3.4 What Already Exists (Pre-Phase 21)

| Entity | Purpose | Limitation |
|--------|---------|------------|
| `application_roadmap` (stub) | Lifecycle events per app | App-centric, not strategic; event types are tactical |
| `remediation_effort` | T-shirt size for tech debt | Per-DP estimate, not tied to actionable initiative |
| `assessment_history` (stub) | Track assessment changes | Historical, not forward-looking |
| `technology_lifecycle_reference` | EOL/EOS dates | Source data for auto-generated findings |
| Cost Model v2.5 | Software Products, IT Services, Cost Bundles | Provides IT Run Rate baseline |

---

## 4. Domain Model

### 4.1 Assessment Domains

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

### 4.6 Idea Status (v1.2)

| Status | Code | Description |
|--------|------|-------------|
| **Submitted** | `submitted` | New idea awaiting review |
| **Under Review** | `under_review` | Being evaluated by admin |
| **Approved** | `approved` | Accepted — initiative created |
| **Declined** | `declined` | Rejected with reason (persists) |
| **Deferred** | `deferred` | Good idea, not now |

### 4.7 Program Status (v1.2)

| Status | Code | Description |
|--------|------|-------------|
| **Draft** | `draft` | Being planned |
| **Active** | `active` | Underway |
| **Completed** | `completed` | All initiatives done |
| **Cancelled** | `cancelled` | Program abandoned |

### 4.8 Dependency Types (v1.2)

| Type | Code | Direction | Description |
|------|------|-----------|-------------|
| **Requires** | `requires` | Source needs target done first | "Cayenta v12 requires SQL 2022" |
| **Enables** | `enables` | Source unlocks target | "SQL 2022 enables Cayenta v12" |
| **Blocks** | `blocks` | Source prevents target | "Legacy data format blocks Data Warehouse" |
| **Related To** | `related_to` | Informational, no sequencing | "Vuln Mgmt related to Security Audit" |

---

## 5. Entity Definitions

### 5.1 Finding (Deployed — v1.1)

Captures a documented assessment observation. Findings can be manually entered, auto-generated from Technology Lifecycle data, or imported from external assessments.

```sql
CREATE TABLE public.findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  
  assessment_domain TEXT NOT NULL,
  impact TEXT NOT NULL DEFAULT 'medium',
  title TEXT NOT NULL,
  rationale TEXT NOT NULL,
  as_of_date DATE NOT NULL DEFAULT CURRENT_DATE,
  source_type TEXT NOT NULL DEFAULT 'manual',
  source_reference_id UUID,
  
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT findings_domain_check CHECK (
    assessment_domain IN ('icoms', 'bpa', 'ti', 'dqa', 'cr', 'other')
  ),
  CONSTRAINT findings_impact_check CHECK (impact IN ('high', 'medium', 'low')),
  CONSTRAINT findings_source_type_check CHECK (
    source_type IN ('manual', 'computed', 'imported')
  )
);
```

**Status:** ✅ Deployed with 5 indexes, 4 RLS policies, audit trigger.

---

### 5.2 Idea (Proposed — v1.2)

Lightweight intake suggestion from anyone in the organization. The bottom-up pipeline.

```sql
CREATE TABLE public.ideas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  
  -- Content (intentionally lightweight)
  title TEXT NOT NULL,
  description TEXT,
  assessment_domain TEXT,  -- OPTIONAL routing hint, not required
  
  -- Submitter
  submitted_by_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  
  -- Review workflow
  status TEXT NOT NULL DEFAULT 'submitted',
  review_notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  
  -- Promotion link
  promoted_to_initiative_id UUID REFERENCES initiatives(id) ON DELETE SET NULL,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT ideas_status_check CHECK (
    status IN ('submitted', 'under_review', 'approved', 'declined', 'deferred')
  ),
  CONSTRAINT ideas_domain_check CHECK (
    assessment_domain IS NULL OR
    assessment_domain IN ('icoms', 'bpa', 'ti', 'dqa', 'cr', 'other')
  )
);

CREATE INDEX idx_ideas_namespace ON public.ideas(namespace_id);
CREATE INDEX idx_ideas_workspace ON public.ideas(workspace_id);
CREATE INDEX idx_ideas_status ON public.ideas(status);
CREATE INDEX idx_ideas_promoted ON public.ideas(promoted_to_initiative_id)
  WHERE promoted_to_initiative_id IS NOT NULL;
```

**Design Decisions:**

| Decision | Rationale |
|----------|-----------|
| `assessment_domain` is optional | Submitter may not know the domain. Admin assigns during review if needed. Keeps the 18-year-old test intact. |
| `submitted_by_contact_id` (not `created_by`) | The person who enters the idea may not be the person who had it. A manager might submit on behalf of a technician. `created_by` tracks who actually clicked the button. |
| `promoted_to_initiative_id` on Idea | Forward-link from Idea to Initiative. Reciprocal to `source_idea_id` on Initiative. Denormalized for query convenience. |
| `review_notes` required on decline | Business rule (not schema constraint). UI enforces "you must give a reason when declining." Governance audit trail. |
| Declined ideas persist | Never deleted. Status = `declined` with `review_notes`. Historical record of what was considered and why it was rejected. |

**Idea vs Finding Comparison:**

| Dimension | Idea | Finding |
|-----------|------|---------|
| Required fields | title | title, rationale, domain, impact, as_of_date |
| Domain | Optional | Required |
| Impact | Not tracked | Required (H/M/L) |
| Source tracking | No | Yes (manual/computed/imported + reference_id) |
| Review workflow | Yes (submit → review → approve/decline) | No (created directly by authorized users) |
| Volume expectation | High (50+ per cycle) | Low (5-15 per cycle) |
| Creator expertise | Low | High |

---

### 5.3 Initiative (Deployed — v1.1, ALTER proposed v1.2)

The core entity that answers "So What?" — a recommended action with timeline, cost, and run rate impact.

```sql
-- DEPLOYED DDL (v1.1) — see v1.1 doc for full CREATE TABLE
-- v1.2 adds one column:

ALTER TABLE public.initiatives
  ADD COLUMN source_idea_id UUID REFERENCES ideas(id) ON DELETE SET NULL;

CREATE INDEX idx_initiatives_idea ON public.initiatives(source_idea_id)
  WHERE source_idea_id IS NOT NULL;

COMMENT ON COLUMN public.initiatives.source_idea_id IS
  'FK to the Idea that was promoted to create this initiative. '
  'An initiative can have source_finding_id, source_idea_id, both, or neither.';
```

**Source Tracking (v1.2 — updated):**

An initiative can originate from:

| Source | Field | Example |
|--------|-------|---------|
| Assessment finding | `source_finding_id` | "RHEL 7 EOL → upgrade infrastructure" |
| Intake idea | `source_idea_id` | "Ministry user suggested citizen portal → approved" |
| Both | Both populated | Finding confirmed an idea that was already submitted |
| Neither | Both NULL | Manually created by admin (e.g., executive directive) |

---

### 5.4 Program (Proposed — v1.2)

Strategic grouping of related initiatives with budget envelope and ownership. Programs answer "why are we doing this group of work?"

```sql
CREATE TABLE public.programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  
  -- Content
  title TEXT NOT NULL,
  description TEXT,
  strategic_theme TEXT,
  
  -- Business justification (v1.2 — text field, promote to table later)
  business_driver TEXT,
  
  -- Budget envelope
  budget_amount DECIMAL,
  budget_fiscal_year TEXT,
  
  -- Timeline
  target_start_date DATE,
  target_end_date DATE,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active',
  
  -- Ownership
  owner_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  sponsor_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT programs_theme_check CHECK (
    strategic_theme IS NULL OR strategic_theme IN ('optimize', 'growth', 'risk')
  ),
  CONSTRAINT programs_status_check CHECK (
    status IN ('draft', 'active', 'completed', 'cancelled')
  )
);

CREATE INDEX idx_programs_namespace ON public.programs(namespace_id);
CREATE INDEX idx_programs_workspace ON public.programs(workspace_id);
CREATE INDEX idx_programs_status ON public.programs(status);
CREATE INDEX idx_programs_owner ON public.programs(owner_contact_id);
```

**Design Decisions:**

| Decision | Rationale |
|----------|-----------|
| `business_driver` is TEXT | Start simple. "County billing contract expires Dec 2027." Promote to a structured table if/when customers need categorization (regulatory/growth/risk/cost) and target dates. |
| `budget_amount` is explicit | Not derived from initiative sum. Leadership approves a $500K envelope. Variance = budget - sum(initiative midpoint costs). |
| `owner_contact_id` + `sponsor_contact_id` | Owner executes. Sponsor approves budget. Maps to PE model (Operating Partner = sponsor, CIO = owner). |
| `strategic_theme` is optional | A program might span themes. If set, it's a default for new initiatives created within the program. |
| `workspace_id` nullable | Program can span workspaces (namespace-wide) or be workspace-specific. Same pattern as findings/initiatives. |
| No `factor_focus_areas` | Dropped "Programs influence Factors" from OG. Programs are pure grouping + budget. |

**Program Budget Variance:**

```
Program: "Digital Transformation 2026"
  Budget envelope:     $500,000
  Initiative sum:      $455,000 (midpoint of cost ranges)
  Budget remaining:    $45,000
  Budget utilization:  91%
```

---

### 5.5 Program ↔ Initiative (Junction — Proposed v1.2)

N:M relationship. An initiative can belong to multiple programs. A program contains multiple initiatives.

```sql
CREATE TABLE public.program_initiatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT program_initiatives_unique UNIQUE (program_id, initiative_id)
);

CREATE INDEX idx_program_initiatives_program ON public.program_initiatives(program_id);
CREATE INDEX idx_program_initiatives_initiative ON public.program_initiatives(initiative_id);
```

**N:M Rationale:** Real-world programs overlap. "ERP Replacement" belongs to both "Digital Transformation" and "Cost Reduction 2026." The double-counting problem is solved in the reporting layer — same pattern as `portfolio_assignments` where a DP can appear in multiple portfolios but its cost is only counted once at the namespace level.

**Reporting approach:**
- **Program view:** Show all initiatives in program, sum costs. Users understand this is the program's scope.
- **Investment summary view:** Deduplicate by initiative ID. Each initiative's cost counted once regardless of how many programs reference it.
- **Variance view:** Compare `program.budget_amount` against sum of linked initiative midpoints. This IS intended to double-count, because each program has its own budget approval.

---

### 5.6 Initiative Dependencies (Proposed — v1.2)

Bidirectional dependency graph between initiatives. Enables dependency-aware scheduling and impact analysis.

```sql
CREATE TABLE public.initiative_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  target_initiative_id UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  dependency_type TEXT NOT NULL DEFAULT 'requires',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT initiative_deps_unique 
    UNIQUE (source_initiative_id, target_initiative_id),
  CONSTRAINT initiative_deps_no_self 
    CHECK (source_initiative_id != target_initiative_id),
  CONSTRAINT initiative_deps_type_check CHECK (
    dependency_type IN ('requires', 'enables', 'blocks', 'related_to')
  )
);

CREATE INDEX idx_initiative_deps_source ON public.initiative_dependencies(source_initiative_id);
CREATE INDEX idx_initiative_deps_target ON public.initiative_dependencies(target_initiative_id);
CREATE INDEX idx_initiative_deps_type ON public.initiative_dependencies(dependency_type);
```

**Direction Convention:** `source` [dependency_type] `target`

| Dependency | Reads as | Scheduling Impact |
|------------|----------|-------------------|
| A `requires` B | A cannot start until B completes | B.target_end_date < A.target_start_date |
| A `enables` B | Completing A unlocks B | A.target_end_date < B.target_start_date |
| A `blocks` B | A must be resolved before B proceeds | A.status must not be 'identified' |
| A `related_to` B | Informational | No scheduling constraint |

**requires vs enables:** These are inverse perspectives of the same dependency. Both are stored for query convenience:
- "What does Cayenta upgrade depend on?" → `SELECT * WHERE source = cayenta AND type = 'requires'`
- "What does SQL Server upgrade unlock?" → `SELECT * WHERE source = sql_server AND type = 'enables'`

A single real-world dependency is stored as **two rows** (one `requires`, one `enables`). The application layer creates both when the user declares a dependency.

**Worked Example:**

```
"Upgrade Cayenta Financials to v12"
    ├── REQUIRES → "Migrate SQL Server 2016 to 2022"
    ├── REQUIRES → "Upgrade Windows Server 2016 to 2022"
    └── ENABLES  → "Implement Multi-Jurisdiction Billing"

Stored as:
  (cayenta, sql_server, 'requires')      ← Cayenta requires SQL
  (sql_server, cayenta, 'enables')       ← SQL enables Cayenta
  (cayenta, win_server, 'requires')      ← Cayenta requires Windows
  (win_server, cayenta, 'enables')       ← Windows enables Cayenta  
  (cayenta, multi_billing, 'enables')    ← Cayenta enables Multi-Billing
  (multi_billing, cayenta, 'requires')   ← Multi-Billing requires Cayenta
```

**Gantt Integration (Future):**
When a user drags an initiative to a later quarter on the Scenario Planner:
1. Query `initiative_dependencies WHERE target = moved_initiative AND type = 'enables'`
2. Flag all downstream initiatives: "Warning: Cayenta Financials upgrade depends on SQL Server — it may also need to slip."
3. Optionally auto-cascade the slip (with user confirmation).

**Circular Dependency Prevention:**
Application-level validation, not database constraint. Before creating a dependency A → B, check that B does not already transitively depend on A. Simple recursive CTE:

```sql
WITH RECURSIVE dep_chain AS (
  SELECT target_initiative_id AS id, 1 AS depth
  FROM initiative_dependencies
  WHERE source_initiative_id = :proposed_target
    AND dependency_type IN ('requires', 'enables')
  
  UNION ALL
  
  SELECT d.target_initiative_id, dc.depth + 1
  FROM initiative_dependencies d
  JOIN dep_chain dc ON dc.id = d.source_initiative_id
  WHERE d.dependency_type IN ('requires', 'enables')
    AND dc.depth < 10  -- prevent infinite loops
)
SELECT EXISTS (
  SELECT 1 FROM dep_chain WHERE id = :proposed_source
) AS would_create_cycle;
```

---

### 5.7 Initiative ↔ Deployment Profile (Deployed — v1.1)

```sql
-- See v1.1 for full DDL
-- Links initiatives to the deployment profiles they affect
-- relationship_type IN ('impacted', 'replaced', 'modernized', 'retired', 'dependent')
```

**Status:** ✅ Deployed with unique constraint, 4 RLS policies, audit trigger.

---

### 5.8 Initiative ↔ IT Service (Deployed — v1.1)

```sql
-- See v1.1 for full DDL
-- Links initiatives to IT services they affect
-- relationship_type IN ('impacted', 'replaced', 'enhanced', 'dependent')
```

**Status:** ✅ Deployed with unique constraint, 4 RLS policies, audit trigger.

---

### 5.9 Initiative Comments / Activity Log (Deferred)

Deferred to polish pass. Audit trail covered by existing `audit_log` triggers. See v1.1 Section 5.5 for planned schema.

---

## 6. Reporting Views

### 6.1 vw_finding_summary (Deployed — v1.1)

Powers the Scorecard — one row per domain with aggregate impact. See v1.1 Section 6.1 for full DDL.

### 6.2 vw_initiative_summary (Deployed — v1.1)

Powers the Roadmap table, Investment Summary, and Workspace dashboard. See v1.1 Section 6.2 for full DDL.

### 6.3 vw_idea_summary (Proposed — v1.2)

Powers the Idea Inbox and namespace-level intake dashboard.

```sql
CREATE OR REPLACE VIEW public.vw_idea_summary
WITH (security_invoker=true)
AS
SELECT
  i.namespace_id,
  i.workspace_id,
  w.name AS workspace_name,
  i.id AS idea_id,
  i.title,
  i.description,
  i.assessment_domain,
  CASE i.assessment_domain
    WHEN 'icoms' THEN 'IT Operating Model & Spend'
    WHEN 'bpa'   THEN 'Business Process & Applications'
    WHEN 'ti'    THEN 'Technology Infrastructure'
    WHEN 'dqa'   THEN 'Data Quality & Analytics'
    WHEN 'cr'    THEN 'Cybersecurity Risk'
    WHEN 'other' THEN 'Other'
    ELSE NULL
  END AS domain_name,
  i.status,
  i.review_notes,
  i.reviewed_at,
  c.display_name AS submitted_by_name,
  i.promoted_to_initiative_id,
  init.title AS promoted_initiative_title,
  i.created_at
FROM ideas i
LEFT JOIN workspaces w ON w.id = i.workspace_id
LEFT JOIN contacts c ON c.id = i.submitted_by_contact_id
LEFT JOIN initiatives init ON init.id = i.promoted_to_initiative_id;
```

### 6.4 vw_program_summary (Proposed — v1.2)

Powers the Program Overview dashboard with budget variance and initiative roll-up.

```sql
CREATE OR REPLACE VIEW public.vw_program_summary
WITH (security_invoker=true)
AS
SELECT
  p.namespace_id,
  p.workspace_id,
  w.name AS workspace_name,
  p.id AS program_id,
  p.title,
  p.description,
  p.strategic_theme,
  p.business_driver,
  p.status,
  p.budget_amount,
  p.budget_fiscal_year,
  p.target_start_date,
  p.target_end_date,
  owner_c.display_name AS owner_name,
  sponsor_c.display_name AS sponsor_name,
  (SELECT count(*) FROM program_initiatives pi WHERE pi.program_id = p.id) AS initiative_count,
  (SELECT count(*) FROM program_initiatives pi
   JOIN initiatives i ON i.id = pi.initiative_id
   WHERE pi.program_id = p.id AND i.status = 'completed'
  ) AS completed_count,
  (SELECT count(*) FROM program_initiatives pi
   JOIN initiatives i ON i.id = pi.initiative_id
   WHERE pi.program_id = p.id AND i.status = 'in_progress'
  ) AS active_count,
  (SELECT COALESCE(SUM(
    ROUND((COALESCE(i.one_time_cost_low, 0) + COALESCE(i.one_time_cost_high, 0)) / 2)
  ), 0) FROM program_initiatives pi
   JOIN initiatives i ON i.id = pi.initiative_id
   WHERE pi.program_id = p.id AND i.status != 'cancelled'
  ) AS total_initiative_cost_mid,
  (SELECT COALESCE(SUM(COALESCE(i.estimated_run_rate_change, 0)), 0)
   FROM program_initiatives pi
   JOIN initiatives i ON i.id = pi.initiative_id
   WHERE pi.program_id = p.id AND i.status != 'cancelled'
  ) AS total_run_rate_change,
  p.created_at
FROM programs p
LEFT JOIN workspaces w ON w.id = p.workspace_id
LEFT JOIN contacts owner_c ON owner_c.id = p.owner_contact_id
LEFT JOIN contacts sponsor_c ON sponsor_c.id = p.sponsor_contact_id;
```

**Derived fields in this view:**

| Field | Calculation |
|-------|-------------|
| `initiative_count` | Count of linked initiatives |
| `completed_count` | Count where status = 'completed' |
| `active_count` | Count where status = 'in_progress' |
| `total_initiative_cost_mid` | Sum of initiative cost midpoints (excludes cancelled) |
| `total_run_rate_change` | Sum of run rate changes (excludes cancelled) |
| Budget variance (UI-computed) | `budget_amount - total_initiative_cost_mid` |
| Completion rate (UI-computed) | `completed_count / initiative_count` |

---

## 7. Conceptual ERD (v1.2)

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                  IT VALUE CREATION MODULE — v1.2                                  │
└───────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐          ┌─────────────────┐
│    Namespace    │          │    Workspace    │
└────────┬────────┘          └────────┬────────┘
         │                            │
         │ 1:N (all entities below)   │ 1:N (optional on all)
         │                            │
    ┌────┴────────────────────────────┴────────────────────────────────────┐
    │                                                                      │
    │  ╔═══════════════════════════════════════════════════════════════╗    │
    │  ║  UPSTREAM SOURCES (two pipelines into initiatives)           ║    │
    │  ╠═══════════════════════════════════════════════════════════════╣    │
    │  ║                                                              ║    │
    │  ║  ┌─────────────────────────┐   ┌──────────────────────────┐ ║    │
    │  ║  │       Finding           │   │         Idea             │ ║    │
    │  ║  │  (expert assessment)    │   │   (crowd-sourced intake) │ ║    │
    │  ║  ├─────────────────────────┤   ├──────────────────────────┤ ║    │
    │  ║  │ domain (REQUIRED)       │   │ domain (OPTIONAL)        │ ║    │
    │  ║  │ impact (H/M/L)         │   │ status workflow           │ ║    │
    │  ║  │ rationale              │   │ submitted_by_contact_id   │ ║    │
    │  ║  │ source_type            │   │ review_notes              │ ║    │
    │  ║  │ source_reference_id    │   │ promoted_to_initiative_id │ ║    │
    │  ║  └───────────┬────────────┘   └──────────────┬────────────┘ ║    │
    │  ║              │ source_finding_id              │ source_idea_id║   │
    │  ║              │          ┌─────────────────────┘              ║    │
    │  ╚══════════════│══════════│════════════════════════════════════╝    │
    │                 │          │                                         │
    │                 ▼          ▼                                         │
    │  ╔═══════════════════════════════════════════════════════════════╗   │
    │  ║  CORE ENTITY                                                 ║   │
    │  ╠═══════════════════════════════════════════════════════════════╣   │
    │  ║                                                              ║   │
    │  ║  ┌────────────────────────────────────────────────────────┐  ║   │
    │  ║  │                     Initiative                         │  ║   │
    │  ║  ├────────────────────────────────────────────────────────┤  ║   │
    │  ║  │ domain, theme, priority, status                        │  ║   │
    │  ║  │ time_horizon, target_start/end                         │  ║   │
    │  ║  │ one_time_cost_low/high, recurring_cost_low/high        │  ║   │
    │  ║  │ estimated_run_rate_change, run_rate_change_rationale   │  ║   │
    │  ║  │ owner_contact_id                                       │  ║   │
    │  ║  │ source_finding_id, source_idea_id (v1.2)               │  ║   │
    │  ║  └──┬───────────┬───────────┬───────────┬────────────────┘  ║   │
    │  ║     │           │           │           │                    ║   │
    │  ╚═════│═══════════│═══════════│═══════════│════════════════════╝   │
    │        │           │           │           │                        │
    │   ┌────┘     ┌─────┘    ┌──────┘     ┌─────┘                       │
    │   │          │          │            │                              │
    │   ▼          ▼          ▼            ▼                              │
    │ ┌─────────┐┌─────────┐┌──────────┐┌──────────────────────────────┐ │
    │ │DP Junct.││Svc Junct││Dep. Graph││Program Junction              │ │
    │ │ (N:M)   ││ (N:M)   ││ (self)   ││ (N:M)                       │ │
    │ ├─────────┤├─────────┤├──────────┤├──────────────────────────────┤ │
    │ │init_id  ││init_id  ││source_id ││program_id                    │ │
    │ │dp_id    ││svc_id   ││target_id ││initiative_id                 │ │
    │ │rel_type ││rel_type ││dep_type  ││                              │ │
    │ └────┬────┘└────┬────┘│(requires │└────────────┬─────────────────┘ │
    │      │          │     │ enables  │             │                    │
    │      ▼          ▼     │ blocks   │             ▼                   │
    │ ┌─────────┐┌─────────┐│related_to│  ┌──────────────────────────┐  │
    │ │   DP    ││IT Svc   │└──────────┘  │       Program            │  │
    │ │(existing││(existing│              ├──────────────────────────┤  │
    │ └─────────┘└─────────┘              │ title, description       │  │
    │                                     │ business_driver (text)   │  │
    │                                     │ budget_amount            │  │
    │                                     │ budget_fiscal_year       │  │
    │                                     │ strategic_theme          │  │
    │                                     │ owner + sponsor contacts │  │
    │                                     │ status                   │  │
    │                                     └──────────────────────────┘  │
    │                                                                    │
    └────────────────────────────────────────────────────────────────────┘
```

**Entity Count Summary (v1.2):**

| Category | Tables | Status |
|----------|--------|--------|
| Deployed (v1.1) | findings, initiatives, initiative_deployment_profiles, initiative_it_services | ✅ |
| Deployed views (v1.1) | vw_finding_summary, vw_initiative_summary | ✅ |
| Proposed (v1.2) | ideas, programs, program_initiatives, initiative_dependencies | 📋 |
| Proposed views (v1.2) | vw_idea_summary, vw_program_summary | 📋 |
| ALTER (v1.2) | initiatives + source_idea_id | 📋 |

---

## 8. UI Components

### 8.1 Roadmap Scorecard

See v1.1 Section 8.1 — unchanged. Powered by `vw_finding_summary`.

### 8.2 Initiative Roadmap Table

See v1.1 Section 8.2, with the following v1.2 additions:

- **Program column** (optional filter) — filter by program to see only that program's initiatives
- **Dependency indicator** — icon on initiatives that have upstream or downstream dependencies. Hover to see linked initiatives.
- **Source badge** — "From Finding" / "From Idea" / "Direct" indicator per initiative

### 8.3 Initiative Detail Panel

See v1.1 Section 8.3, with the following v1.2 additions:

```
  ─────────────────────────────────────────────────────────────────
  
  SOURCE                                                           
  🔴 Finding: RHEL 7 End of Support — SirsiDynix at Risk          
  💡 Idea: (none)                                                  
  
  ─────────────────────────────────────────────────────────────────

  PROGRAMS                                                         
  📁 Infrastructure Stabilization ($200K budget)                   
  📁 FY2026 Risk Reduction ($350K budget)                          
  [+ Add to Program]                                               
  
  ─────────────────────────────────────────────────────────────────

  DEPENDENCIES (v1.2)                                              
  ⬆ REQUIRES:                                                     
    (none)                                                         
  ⬇ ENABLES:                                                      
    → Cayenta Financials Upgrade (planned, Q3)                     
  [+ Add Dependency]                                               
  
  ─────────────────────────────────────────────────────────────────
```

### 8.4 Roadmap Dashboard

See v1.1 Section 8.4 — enhanced with:
- **Ideas Inbox count** in KPI row ("12 ideas pending review")
- **Programs at a Glance** card showing active programs with budget utilization bars

### 8.5 Idea Inbox (v1.2)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  IDEA INBOX                                              [+ Submit Idea]   │
├────────┬───────────────────────────────┬──────────┬──────────┬─────────────┤
│ Status │ Idea                          │ From     │ Domain   │ Submitted   │
├────────┼───────────────────────────────┼──────────┼──────────┼─────────────┤
│ 🆕 New │ Mobile app for field inspect. │ J. Smith │ BPA      │ Feb 20      │
│ 🆕 New │ Replace fax with digital forms│ R. Chen  │ —        │ Feb 18      │
│ 🆕 New │ Consolidate help desk tools   │ M. Davis │ ICOMS    │ Feb 15      │
│ 👀 Rev │ Citizen portal for permits    │ A. Lee   │ BPA      │ Feb 10      │
│ ✅ App │ ERP evaluation                │ T. Wong  │ BPA      │ Jan 28      │
│ ❌ Dec │ Replace all desktops with iPad│ K. Patel │ TI       │ Jan 25      │
├────────┴───────────────────────────────┴──────────┴──────────┴─────────────┤
│ 3 pending review | 1 under review | 1 approved | 1 declined               │
└─────────────────────────────────────────────────────────────────────────────┘

Filters: [All Statuses ▼] [All Domains ▼] [All Workspaces ▼]
```

**Review Panel (slide-out on click):**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [←]  Citizen portal for permits                                   [Edit] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Status: 👀 Under Review     Domain: BPA     From: A. Lee                │
│  Submitted: Feb 10, 2026     Workspace: Community Development             │
│                                                                            │
│  DESCRIPTION                                                               │
│  Residents currently need to visit City Hall in person for building         │
│  permits. An online portal would reduce wait times and free up counter     │
│  staff. Other municipalities in the region have implemented this.          │
│                                                                            │
│  ──────────────────────────────────────────────────────────────────────    │
│                                                                            │
│  ADMIN REVIEW                                                              │
│  Notes: [                                                               ]  │
│                                                                            │
│  [✅ Approve → Create Initiative]  [❌ Decline]  [⏸ Defer]              │
│                                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

On **Approve**: System creates a new Initiative pre-populated with title, description, domain (if provided), `source_idea_id` set, and Idea status → `approved` with `promoted_to_initiative_id` set.

### 8.6 Program Dashboard (v1.2)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PROGRAMS                                                    [+ New Program]│
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 📁 Digital Transformation 2026                      Status: Active  │  │
│  │ Driver: County billing contract expires Dec 2027                    │  │
│  │ Owner: J. Martinez    Sponsor: CIO Office                          │  │
│  │                                                                     │  │
│  │ Budget: $500K                        Initiatives: 3                 │  │
│  │ Consumed: $455K ████████████████████░ (91%)       1 active, 2 plan │  │
│  │ Remaining: $45K                      Run Rate Δ: +$35K/yr          │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 📁 Infrastructure Stabilization                     Status: Active  │  │
│  │ Driver: Board mandate - reduce critical tech debt by FY27           │  │
│  │ Owner: S. Thompson    Sponsor: IT Director                         │  │
│  │                                                                     │  │
│  │ Budget: $200K                        Initiatives: 4                 │  │
│  │ Consumed: $133K ████████████░░░░░░░░ (67%)       1 active, 3 plan │  │
│  │ Remaining: $67K                      Run Rate Δ: -$2K/yr           │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ NOTE: "ERP Replacement" initiative appears in both programs.        │  │
│  │ Deduplicated investment total: $588K (not $655K).                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.7 Dependency Visualization (v1.2 — stretch)

On the Scenario Planner / Gantt chart:

```
Dependency arrows between initiative bars:

  Q1                Q2                Q3
  ┌───────────┐     ┌───────────┐
  │ SQL Server │─────► Cayenta   │─ ─ ─ ─►┌──────────────┐
  │ Upgrade    │     │ Upgrade   │         │Multi-Jurisd. │
  └───────────┘     └───────────┘         │Billing       │
                                          └──────────────┘
       requires ────►     enables ─ ─ ─►

  If SQL Server slips to Q2:
  ⚠ "Cayenta Upgrade depends on SQL Server — will also slip to Q3"
  ⚠ "Multi-Jurisdiction Billing downstream impact — may slip to Q4"
```

### 8.8 Dashboard Scoping & Filter Model (v1.3)

The Roadmap dashboard supports both namespace-wide and workspace-filtered views, following the same filter drawer pattern established by the Technology Health Dashboard (Phase 20).

#### 8.8.1 Design Principle: Self-Organizing Visibility

Programs, findings, and initiatives follow a **self-organizing visibility model** — the data determines who can see what, with no admin configuration required. This matches the existing workspace provider/consumer/hybrid auto-categorization pattern.

Key decisions:
- **No WorkspaceGroup tagging** — Programs are not assigned to WorkspaceGroups. Visibility is derived from initiative membership.
- **Full context, not sliced** — When a workspace user sees a cross-cutting program, they see the full program (total budget, all initiative count) rather than a misleading slice containing only their workspace's initiatives.
- **NULL workspace_id = namespace-wide** — Findings and programs with NULL workspace_id are visible to all workspace users within the namespace, not restricted to admins.

#### 8.8.2 Scoping Rules by Entity

| Entity | workspace_id | Namespace View (no filter) | Workspace View (filtered) |
|--------|-------------|---------------------------|--------------------------|
| **Findings** | Optional | All findings in namespace | `workspace_id = selected` OR `workspace_id IS NULL` |
| **Initiatives** | Optional (NULL = namespace-wide) | All initiatives in namespace | `workspace_id = selected` OR `workspace_id IS NULL` |
| **Ideas** | Optional (NULL = namespace-wide) | All ideas in namespace | `workspace_id = selected` OR `workspace_id IS NULL` |
| **Programs** | Optional (NULL = namespace-wide) | All programs in namespace | `workspace_id = selected` OR any linked initiative has `workspace_id = selected` ¹ |
| **Dependencies** | Via initiative | All dependencies | Visible if either source or target initiative is visible ² |

**¹ Program Visibility Query Pattern:**

```sql
-- Programs visible to a workspace user
SELECT DISTINCT p.*
FROM programs p
WHERE p.namespace_id = :namespace_id
  AND (
    -- Direct: program belongs to this workspace
    p.workspace_id = :workspace_id
    -- Namespace-wide: no workspace assigned
    OR p.workspace_id IS NULL
    -- Derived: program contains an initiative in this workspace
    OR EXISTS (
      SELECT 1 FROM program_initiatives pi
      JOIN initiatives i ON i.id = pi.initiative_id
      WHERE pi.program_id = p.id
        AND i.workspace_id = :workspace_id
    )
  );
```

**² Dependency Visibility Rule:**

A dependency row is visible when the workspace user can see at least one of the linked initiatives. In practice, most dependency pairs involve initiatives in the same or related workspaces. Cross-workspace dependencies (e.g., "ERP Replacement in Finance *requires* SQL Server Upgrade in IT") are visible to both Finance and IT workspace users — this is intentional, as the dependency exists precisely because the workspaces are coupled.

#### 8.8.3 KPI Rollup Behavior

| Scope | KPIs aggregate... |
|-------|-------------------|
| **Namespace view** | All initiatives in namespace. Deduplicated. |
| **Workspace view** | Only initiatives with `workspace_id = selected`. |
| **Programs** | Always show **full program context** regardless of filter. A Finance user sees "Digital Transformation 2026: $500K budget, 6 initiatives, 52% utilized" even if only 2 of those 6 initiatives are in Finance. |
| **Run Rate baseline** | Namespace view: total namespace run rate. Workspace view: workspace-level run rate (from Cost Model v2.5 workspace budget totals). |

**Rationale for full program context:** Slicing a program's budget by workspace creates a misleading picture. If Finance sees "$225K budget, 100% utilized" for their two initiatives within a $500K program, they'd think the program is fully consumed when it's actually at 52%. The program is a shared envelope — showing it whole is more honest.

#### 8.8.4 Filter Drawer Integration

The filter drawer follows the Technology Health Dashboard pattern:

```
┌─────────────────────────────────────┐
│  FILTERS                     [Clear]│
├─────────────────────────────────────┤
│                                     │
│  Workspace                          │
│  [All Workspaces           ▼]       │
│                                     │
│  Assessment Domain                  │
│  [All Domains              ▼]       │
│                                     │
│  Strategic Theme                    │
│  [All Themes               ▼]       │
│                                     │
│  Priority                           │
│  [All Priorities           ▼]       │
│                                     │
│  Status                             │
│  [All Statuses             ▼]       │
│                                     │
│  Program                            │
│  [All Programs             ▼]       │
│                                     │
│  Time Horizon                       │
│  [All Quarters             ▼]       │
│                                     │
│  [Apply Filters]                    │
└─────────────────────────────────────┘
```

Filter availability varies by tab:

| Filter | Initiatives (Gantt/Kanban/Grid) | Scorecard | Ideas | Programs |
|--------|-------------------------------|-----------|-------|----------|
| Workspace | ✅ | ✅ | ✅ | ✅ |
| Domain | ✅ | ✅ | ✅ | — |
| Theme | ✅ | — | — | ✅ |
| Priority | ✅ | — | — | — |
| Status | ✅ | — | ✅ | ✅ |
| Program | ✅ | — | — | — |
| Horizon | ✅ (Gantt/Grid only) | — | — | — |

#### 8.8.5 Global Workspace Selector Sync (v1.4)

The Roadmap dashboard automatically syncs with the **global workspace selector** in the navigation header:

- **Specific workspace selected** → `filters.workspaceId` is set to that workspace's ID. The filter drawer reflects this selection. Items shown: workspace-scoped items + organization-wide items (`workspace_id = NULL`).
- **"My Workspaces" (all-workspaces) selected** → `filters.workspaceId` is cleared (no workspace filter). All items from the user's accessible workspaces are shown.
- **User can override** via the filter drawer. Selecting a different workspace in the drawer overrides the global selector until the next global workspace switch.
- **Membership-based filtering** → Regardless of workspace filter state, items are always filtered to workspaces the user is a member of (derived from `allWorkspaces` in AuthContext, which is RLS-filtered). Namespace admins see everything because their workspace list contains all workspaces.

**Implementation note:** RLS SELECT policies on `initiatives`, `ideas`, and `programs` currently enforce namespace-level isolation only (not workspace-level). Workspace-scoped visibility is enforced client-side via the `userWorkspaceIds` membership set. A future RLS enhancement may add workspace-level SELECT restrictions for `restricted`/`viewer` roles.

#### 8.8.6 RBAC Interaction

Scoping rules layer on top of existing RLS policies:

| Role | Namespace View | Workspace View | Cross-Workspace Programs |
|------|---------------|----------------|--------------------------|
| **Namespace Admin** | ✅ Full access | ✅ Any workspace | ✅ Full context |
| **Workspace Admin** | ❌ Own workspace only | ✅ Own workspace | ✅ Full context (via initiative membership) |
| **Workspace Editor** | ❌ Own workspace only | ✅ Own workspace | ✅ Full context (read-only on other workspace initiatives) |
| **Viewer** | ❌ Own workspace only | ✅ Own workspace (read-only) | ✅ Full context (read-only) |

**Note:** RLS policies on `programs` already scope to namespace. The "workspace filter" is a **UI filter**, not an RLS constraint. A workspace editor who can see a cross-cutting program via initiative membership can read the program details but cannot edit programs owned by other workspaces. Program edit rights follow standard workspace_id ownership rules.

---

### 8.9 Initiative View Modes (v1.3)

The Initiatives tab provides three views of the same data. All three share a common KPI bar, filter state, and detail panel.

#### 8.9.1 View Toggle

```
┌─────────────────────────────────────────────────────────────────────┐
│  🎯 Initiatives    📊 Scorecard    💡 Ideas    📁 Programs         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [Gantt]  [Kanban]  [Grid]                          [↺ Reset] [⚙] │
│                                                                     │
│  ┌───────┬───────┬───────┬────────┬────────────┐                   │
│  │Active │Invest │Recur. │Δ Run   │Projected   │  ← KPI bar       │
│  │ 6/6   │$365K  │$64K/yr│+$13K/yr│$1.8M/yr    │                   │
│  └───────┴───────┴───────┴────────┴────────────┘                   │
│                                                                     │
│  [Active view renders here]                                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### 8.9.2 Gantt View (Default)

Row-based horizontal timeline. **This is the default landing view** because it tells the richest story — time, cost, dependencies, and priority in one glance.

```
┌──────────────────────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ INITIATIVE               │  Q1     │  Q2     │  Q3     │  Q4     │ FY28+   │
│                          │Mar-May  │Jun-Aug  │Sep-Nov  │Dec-Feb  │ Mar+    │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ SirsiDynix Upgrade     │ ████████│         │         │         │         │
│   Risk  $35K             │ +$3K    │         │         │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ Vuln Mgmt Program      │ ████████│         │         │         │         │
│   Risk  $15K             │ +$10K   │         │         │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ SQL Server 2016 → 2022 │         │ ████████│         │         │         │
│   Risk  $23K             │         │         │         │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ IT Strategic Planning   │         │ ████████│         │         │         │
│   Optimize  $8K          │         │         │         │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ ERP Evaluation          │         │         │ ████████│         │         │
│   Growth  $225K          │         │         │ +$15K   │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ☑ Oracle 19c → 23ai      │         │         │ ████████│         │         │
│   Optimize  $60K         │         │         │ -$15K   │         │         │
├──────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ QUARTER TOTALS           │  $50K   │  $30K   │  $285K  │   $0    │   $0    │
│                          │+$13K/yr │         │         │         │         │
└──────────────────────────┴─────────┴─────────┴─────────┴─────────┴─────────┘
```

**Behavior:**
- Each initiative occupies one row
- Left column: checkbox (enable/disable), name, theme badge, midpoint cost, dependency count
- Colored bar in the assigned quarter column (red=Risk, green=Optimize, blue=Growth)
- Bar shows truncated title + run rate delta (if non-zero)
- **Drag bar** between quarter columns to reschedule (`time_horizon` update)
- Checkbox toggles initiative in/out of scenario (excluded initiatives dim but stay in table)
- Footer row shows per-quarter investment total and run rate delta
- Click row → detail panel opens on right
- Sorted by: time_horizon ASC, then priority DESC

**What-If Scenario:**
- Toggling checkboxes and dragging bars updates KPI row in real-time
- Reset button restores original state
- No "save scenario" in v1 — this is an exploration tool, not a planning workflow

#### 8.9.3 Kanban View

Status-based columns with drag-to-change-status.

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│  ○ Identified │  ◎ Planned   │  ◉ In Prog.  │  ● Completed │
│  (2)  $285K  │  (3)  $65K   │  (1)  $15K   │  (0)         │
├──────────────┼──────────────┼──────────────┼──────────────┤
│ ┌──────────┐ │ ┌──────────┐ │ ┌──────────┐ │              │
│ │ERP Eval  │ │ │SirsiDynix│ │ │Vuln Mgmt │ │              │
│ │Growth    │ │ │Risk      │ │ │Risk      │ │              │
│ │$225K     │ │ │$35K      │ │ │$15K      │ │              │
│ └──────────┘ │ └──────────┘ │ └──────────┘ │              │
│ ┌──────────┐ │ ┌──────────┐ │              │              │
│ │Oracle 19c│ │ │SQL Server│ │              │              │
│ │Optimize  │ │ │Risk      │ │              │              │
│ │$60K      │ │ │$23K      │ │              │              │
│ └──────────┘ │ └──────────┘ │              │              │
│              │ ┌──────────┐ │              │              │
│              │ │IT Stratgy│ │              │              │
│              │ │Optimize  │ │              │              │
│              │ │$8K       │ │              │              │
│              │ └──────────┘ │              │              │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**Behavior:**
- Columns: Identified → Planned → In Progress → Completed (matches `status` enum)
- Column header shows count and total midpoint cost
- Cards show: priority dot, title, theme badge, midpoint cost, run rate chip, dependency count
- **Drag card** between columns to change `status`
- Cards sorted by priority within each column
- Click card → detail panel opens on right
- Same checkbox/enable toggle available on cards

**Note:** Dragging in Kanban is a more consequential action than Gantt drag — it changes initiative status, not just timeline. The UI should confirm status changes in production (not in the mockup).

> **Realtime:** When multiple users view the same Kanban board, card moves sync via Supabase Realtime Postgres Changes (P1). See `features/realtime-subscriptions/realtime-subscriptions-architecture.md` § 6.1.

#### 8.9.4 Grid View

Sortable, filterable table. The densest view — best for comparing multiple initiatives side-by-side.

```
┌───┬──────────────────────────┬──────────┬──────┬─────────┬─────────┬──────────┐
│   │ Initiative               │ Status   │ When │ Theme   │ Cost    │ Δ Run    │
├───┼──────────────────────────┼──────────┼──────┼─────────┼─────────┼──────────┤
│ ● │ Vuln Mgmt Program        │ ◉ Active │ Q1   │ Risk    │ $15K    │+$10K/yr  │
│ ● │ SirsiDynix Upgrade       │ ◎ Planne │ Q1   │ Risk    │ $35K    │ +$3K/yr  │
│ ● │ SQL Server 2016 → 2022   │ ◎ Planne │ Q2   │ Risk    │ $23K    │ —        │
│ ● │ IT Strategic Planning     │ ◎ Planne │ Q2   │ Optimize│ $8K     │ —        │
│ ● │ ERP Evaluation            │ ○ Ident  │ Q3   │ Growth  │ $225K   │+$15K/yr  │
│ ● │ Oracle 19c → 23ai        │ ○ Ident  │ Q3   │ Optimize│ $60K    │-$15K/yr  │
└───┴──────────────────────────┴──────────┴──────┴─────────┴─────────┴──────────┘
  SORT: [Priority ▼] [Horizon] [Cost] [Status]
```

**Behavior:**
- Sortable columns: priority, horizon, cost (desc), status, theme
- Priority dot as leading indicator (red/orange/gray)
- Dependency and source badges inline (🔗2, 💡, 🔍)
- Click row → detail panel opens on right
- Default sort: priority DESC

#### 8.9.5 Shared Detail Panel

All three views share the same right-side detail panel when an initiative is selected:

```
┌────────────────────────────────────┐
│ Upgrade SirsiDynix Infrastructure  │  ← Title
│                                [✕] │
│                                    │
│ Risk  ◎ Planned  ● Critical  Q1   │  ← Chips
│                                    │
│ ┌────────────┬────────────┐        │
│ │ ONE-TIME   │ RUN RATE Δ │        │
│ │ $35K       │ +$3K/yr    │        │  ← Cost cards
│ │ $25K–$45K  │ annual     │        │
│ └────────────┴────────────┘        │
│                                    │
│ SOURCE FINDING                     │
│ 🟣 RHEL 7 End of Support —        │
│    SirsiDynix at Risk              │
│                                    │
│ PROGRAMS                           │
│ 📁 Infrastructure Stabilization    │
│    $200K budget                    │
│                                    │
│ DEPENDENCIES                       │
│ ⬇ UNLOCKS: Cayenta Upgrade        │
│                                    │
└────────────────────────────────────┘
```

#### 8.9.6 KPI Bar (Shared)

The KPI bar renders above all three views and updates in real-time as initiatives are toggled or rescheduled.

| KPI | Source | Format |
|-----|--------|--------|
| Active Initiatives | Count of enabled initiatives / total | `6 / 6` |
| Total Investment | Sum of `(otc_low + otc_high) / 2` for enabled initiatives | `$365K` |
| New Recurring | Sum of `(recurring_cost_low + recurring_cost_high) / 2` | `$64K/yr` |
| Net Run Rate Δ | Sum of `estimated_run_rate_change` for enabled initiatives | `+$13K/yr` (red if positive, green if negative) |
| Projected Run Rate | Baseline run rate + Net Run Rate Δ | `$1.8M/yr` |

**Baseline Run Rate source:** Workspace budget total from Cost Model v2.5 (workspace view) or namespace budget total (namespace view). Falls back to manual entry if cost model not populated.

---

## 9. Calculation Rules

### 9.1 Investment Summary

See v1.1 Section 9.1 — unchanged.

### 9.2 Run Rate Impact

See v1.1 Section 9.2 — unchanged.

### 9.3 Progress Metrics

See v1.1 Section 9.3 — unchanged.

### 9.4 Scorecard Impact Roll-up

See v1.1 Section 9.4 — unchanged.

### 9.5 Program Budget Variance (v1.2)

```
Program Budget Variance:
  Budget Amount (approved envelope)           = program.budget_amount
  Consumed (initiative cost midpoints)        = SUM(initiative one_time_cost_mid)
                                                WHERE program_initiatives.program_id = :pid
                                                AND initiative.status != 'cancelled'
  Remaining                                   = Budget - Consumed
  Utilization %                               = Consumed / Budget × 100

Program Run Rate Impact:
  = SUM(initiative.estimated_run_rate_change)
    WHERE program_initiatives.program_id = :pid
    AND initiative.status != 'cancelled'

Program Completion Rate:
  = COUNT(status='completed') / COUNT(all non-cancelled)
```

### 9.6 Deduplicated Investment Total (v1.2)

When showing namespace-wide or cross-program investment:

```
Total Investment (deduplicated):
  = SUM(DISTINCT initiative.one_time_cost_mid)
    for all active initiatives (regardless of program membership)

NOT:
  = SUM(program.total_initiative_cost_mid) across all programs
  (this would double-count initiatives in multiple programs)
```

### 9.7 Idea Metrics (v1.2)

```
Ideas Pending:     COUNT(status IN ('submitted', 'under_review'))
Ideas Approved:    COUNT(status = 'approved')
Ideas Declined:    COUNT(status = 'declined')
Approval Rate:     approved / (approved + declined) × 100
Avg Review Time:   AVG(reviewed_at - created_at) WHERE status IN ('approved','declined')
```

### 9.8 Dependency Impact (v1.2)

```
Upstream blockers for Initiative X:
  SELECT target_initiative_id, dependency_type
  FROM initiative_dependencies
  WHERE source_initiative_id = X
  AND dependency_type = 'requires'

Downstream dependents of Initiative X:
  SELECT source_initiative_id, dependency_type
  FROM initiative_dependencies
  WHERE target_initiative_id = X
  AND dependency_type = 'requires'

Blocked initiatives (at risk):
  SELECT DISTINCT source_initiative_id
  FROM initiative_dependencies d
  JOIN initiatives blocker ON blocker.id = d.target_initiative_id
  WHERE d.dependency_type = 'requires'
  AND blocker.status IN ('deferred', 'cancelled')
```

---

## 10. RLS Policies

### 10.1 Findings & Initiatives (Deployed — v1.1)

See v1.1 Section 10.1 — unchanged.

### 10.2 Junction Tables (Deployed — v1.1)

See v1.1 Section 10.2 — unchanged. Applies to `initiative_deployment_profiles` and `initiative_it_services`.

### 10.3 Ideas (Deployed — v1.2)

Same pattern as findings. Special note: all namespace members can **submit** ideas (INSERT), but only admins/editors can **review** (UPDATE status).

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | All namespace members | `namespace_id = get_current_namespace_id()` |
| INSERT | All namespace members (editor+) | Same namespace check. Stewards and viewers can submit if business rule allows (future). |
| UPDATE | Namespace admins + workspace admins/editors | Same namespace check + role check. Status changes restricted to reviewers. |
| DELETE | Namespace admins + workspace admins | Admin role only |

### 10.4 Programs (Deployed — v1.2)

Same pattern as findings/initiatives.

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | All namespace members | `namespace_id = get_current_namespace_id()` |
| INSERT | Namespace admins + workspace admins/editors | Role check |
| UPDATE | Namespace admins + workspace admins/editors | Role check |
| DELETE | Namespace admins + workspace admins | Admin only |

### 10.5 Program Initiatives Junction (Deployed — v1.2)

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | Anyone who can see both the program and initiative | Namespace scope |
| INSERT/UPDATE | Anyone who can edit the parent program | Role check |
| DELETE | Namespace admins + workspace admins | Admin only |

### 10.6 Initiative Dependencies (Deployed — v1.2)

| Operation | Who Can | Rule |
|-----------|---------|------|
| SELECT | Anyone who can see initiatives in the namespace | `source IN (initiatives where namespace_id = current)` |
| INSERT/UPDATE | Anyone who can edit either initiative | Editor+ role |
| DELETE | Namespace admins + workspace admins | Admin only |

---

## 11. Security Posture

### 11.1 Deployed (v1.1)

| Table | RLS | Policies | GRANTs | Audit | Updated_at |
|-------|-----|----------|--------|-------|------------|
| findings | ✅ | 4 | 4 | ✅ | ✅ |
| initiatives | ✅ | 4 | 4 | ✅ | ✅ |
| initiative_deployment_profiles | ✅ | 4 | 4 | ✅ | N/A |
| initiative_it_services | ✅ | 4 | 4 | ✅ | N/A |

### 11.2 Deployed (v1.2)

| Table | RLS | Policies | GRANTs | Audit | Updated_at |
|-------|-----|----------|--------|-------|------------|
| ideas | ✅ | 4 | 4 | ✅ | ✅ |
| programs | ✅ | 4 | 4 | ✅ | ✅ |
| program_initiatives | ✅ | 4 | 4 | ✅ | N/A |
| initiative_dependencies | ✅ | 4 | 4 | ✅ | N/A |

**Projected post-deployment stats:** 90 tables, ~347 RLS policies, 37 audit triggers, 27 views, 53 functions.

All proposed views use `security_invoker=true`.

---

## 12. Tier Gating

| Feature | Essentials | Plus | Enterprise |
|---------|------------|------|------------|
| View Scorecard | ✅ | ✅ | ✅ |
| View Initiatives (read-only) | ✅ | ✅ | ✅ |
| Submit Ideas | ✅ | ✅ | ✅ |
| Add Findings | ❌ | ✅ | ✅ |
| Review Ideas (approve/decline) | ❌ | ✅ | ✅ |
| Add Initiatives (unlimited) | ❌ | ✅ | ✅ |
| Link to DPs/Services | ❌ | ✅ | ✅ |
| Run Rate Impact | ❌ | ✅ | ✅ |
| Initiative Dependencies | ❌ | ✅ | ✅ |
| Programs | ❌ | ❌ | ✅ |
| Program Budget Tracking | ❌ | ❌ | ✅ |
| Export Roadmap | ❌ | ❌ | ✅ |
| Namespace Summary Dashboard | ❌ | ❌ | ✅ |
| Scenario Planner (Gantt) | ❌ | ❌ | ✅ |

**Note:** Ideas at Essentials tier is intentional — it's the "democratic intake" that drives adoption from day one. Even free users can suggest improvements. Reviewing and acting on them requires Plus or higher.

---

## 13. Integration with Existing Entities

### 13.1–13.5: See v1.1

Sections 13.1 through 13.5 unchanged from v1.1 (TIME/PAID suggestions, Technology Lifecycle findings pipeline, Remediation Effort cost mapping, DP cost impact, ITSM integration readiness).

### 13.6 Idea → Initiative Promotion (v1.2)

When an Idea is approved:

1. System creates new Initiative:
   - `title` = Idea title
   - `description` = Idea description
   - `assessment_domain` = Idea domain (if provided)
   - `source_idea_id` = Idea ID
   - `status` = 'identified'
   - `created_from_assessment` = false
2. Idea updated:
   - `status` = 'approved'
   - `promoted_to_initiative_id` = new Initiative ID
   - `reviewed_by` = current user
   - `reviewed_at` = now()

### 13.7 Initiative → Program Assignment (v1.2)

Initiatives can be assigned to programs at any time:
- From Initiative detail → "Add to Program" picker
- From Program detail → "Add Initiative" picker
- Bulk assignment from roadmap table (multi-select → assign to program)

### 13.8 Dependency-Aware Scheduling (v1.2)

When modifying an initiative's `time_horizon` or `target_start_date`:

1. Query `initiative_dependencies WHERE target_initiative_id = :moved AND dependency_type = 'enables'`
2. For each downstream initiative:
   - If moved initiative's new end date > downstream's start date → **flag warning**
   - "Cayenta Upgrade depends on SQL Server Upgrade. Moving SQL Server to Q3 may impact Cayenta (currently Q2)."
3. User decides: cascade the slip or acknowledge the conflict.

### 13.9 Relationship to `application_roadmap` (Existing Stub)

See v1.1 Section 15. Both tables retained — `application_roadmap` for tactical app lifecycle events, `initiatives` for strategic value creation. An initiative might result in roadmap entries.

---

## 14. Seed Data (Riverside Demo)

> **Status:** Lost during cor-demo-data-reset (Apr 2026). Restoration SQL: `schema/cor-demo-data-roadmap-seed.sql` (Phase 3).

### 14.1 Findings (8 records — Deployed v1.1)

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

### 14.2 Initiatives (6 records — Deployed v1.1)

| Theme | Priority | Title | Cost Mid | Δ Run Rate |
|-------|----------|-------|----------|------------|
| 🔴 Risk | Critical | Upgrade SirsiDynix Symphony Infrastructure | $35K | +$3K/yr |
| 🔴 Risk | High | Migrate SQL Server 2016 to 2022 | $23K | $0/yr |
| 🔴 Risk | Critical | Implement Vulnerability Management Program | $15K | +$10K/yr |
| 🟢 Optimize | Medium | Plan Oracle 19c to 23ai Migration Path | $60K | -$15K/yr |
| 🟢 Optimize | Medium | Establish IT Strategic Planning Process | $8K | $0/yr |
| 🔵 Growth | High | ERP Evaluation and Replacement | $225K | +$15K/yr |

### 14.3 Ideas (Deployed — v1.2 seed data)

| Status | Title | From | Domain | Workspace |
|--------|-------|------|--------|-----------|
| submitted | Mobile app for field inspectors | J. Smith | bpa | Public Works |
| submitted | Replace fax with digital forms | R. Chen | — | Community Dev |
| submitted | Consolidate help desk tools | M. Davis | icoms | IT |
| under_review | Citizen portal for building permits | A. Lee | bpa | Community Dev |
| approved | ERP evaluation | T. Wong | bpa | Finance |
| declined | Replace all desktops with iPads | K. Patel | ti | IT |

**Note:** "ERP evaluation" Idea links to the existing "ERP Evaluation and Replacement" initiative via `promoted_to_initiative_id` and `source_idea_id`. This demonstrates the full promotion workflow in the demo.

### 14.4 Programs (Deployed — v1.2 seed data)

| Title | Theme | Budget | Driver | Initiatives |
|-------|-------|--------|--------|-------------|
| Infrastructure Stabilization | risk | $200K | Board mandate: reduce critical tech debt by FY27 | SirsiDynix, SQL Server, Oracle, Vuln Mgmt |
| Digital Transformation 2026 | growth | $500K | County billing contract expires Dec 2027 | ERP Replacement, IT Strategic Planning |

**Note:** ERP Replacement could appear in both programs in a real scenario. For seed data simplicity, it's in Digital Transformation only.

### 14.5 Dependencies (Deployed — v1.2 seed data)

| Source | Type | Target | Notes |
|--------|------|--------|-------|
| ERP Replacement | requires | SQL Server Upgrade | New ERP version requires SQL 2022 |
| SQL Server Upgrade | enables | ERP Replacement | (inverse) |
| Oracle Migration | requires | IT Strategic Planning | Need strategy framework before committing to Oracle exit |
| IT Strategic Planning | enables | Oracle Migration | (inverse) |

---

## 15. API Endpoints (Future)

```
-- Existing (v1.1)
GET/POST       /api/v1/namespaces/:ns_id/findings
GET/PUT/DELETE /api/v1/namespaces/:ns_id/findings/:id

GET/POST       /api/v1/namespaces/:ns_id/initiatives
GET/PUT/DELETE /api/v1/namespaces/:ns_id/initiatives/:id

POST/DELETE    /api/v1/namespaces/:ns_id/initiatives/:id/link-dp/:dp_id
POST/DELETE    /api/v1/namespaces/:ns_id/initiatives/:id/link-service/:svc_id

GET            /api/v1/namespaces/:ns_id/roadmap/dashboard
GET            /api/v1/namespaces/:ns_id/roadmap/scorecard
GET            /api/v1/namespaces/:ns_id/roadmap/investment-summary
GET            /api/v1/namespaces/:ns_id/roadmap/workspace-summary

-- New (v1.2)
GET/POST       /api/v1/namespaces/:ns_id/ideas
GET/PUT/DELETE /api/v1/namespaces/:ns_id/ideas/:id
POST           /api/v1/namespaces/:ns_id/ideas/:id/approve
POST           /api/v1/namespaces/:ns_id/ideas/:id/decline
POST           /api/v1/namespaces/:ns_id/ideas/:id/defer

GET/POST       /api/v1/namespaces/:ns_id/programs
GET/PUT/DELETE /api/v1/namespaces/:ns_id/programs/:id
POST/DELETE    /api/v1/namespaces/:ns_id/programs/:id/initiatives/:init_id

GET/POST       /api/v1/namespaces/:ns_id/initiatives/:id/dependencies
DELETE         /api/v1/namespaces/:ns_id/initiative-dependencies/:dep_id

GET            /api/v1/namespaces/:ns_id/roadmap/idea-inbox
GET            /api/v1/namespaces/:ns_id/roadmap/program-summary
GET            /api/v1/namespaces/:ns_id/initiatives/:id/dependency-graph
```

---

## 16. Migration / Seeding

### 16.1–16.2: See v1.1

Seed Default Findings and Import from IT Ally unchanged.

### 16.3 Idea Promotion Procedure (v1.2)

```sql
-- Promote idea to initiative (application-level, not raw SQL)
BEGIN;
  -- 1. Create initiative
  INSERT INTO initiatives (
    namespace_id, workspace_id, title, description,
    assessment_domain, source_idea_id, status,
    created_from_assessment, created_by
  ) VALUES (
    :ns_id, :ws_id, :idea_title, :idea_description,
    :idea_domain, :idea_id, 'identified',
    false, auth.uid()
  ) RETURNING id INTO :new_initiative_id;

  -- 2. Update idea
  UPDATE ideas SET
    status = 'approved',
    promoted_to_initiative_id = :new_initiative_id,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  WHERE id = :idea_id;
COMMIT;
```

### 16.4 Dependency Creation Procedure (v1.2)

```sql
-- Create bidirectional dependency (application-level)
BEGIN;
  -- 1. Insert forward direction
  INSERT INTO initiative_dependencies (
    source_initiative_id, target_initiative_id, dependency_type, notes
  ) VALUES (:init_a, :init_b, 'requires', :notes);
  
  -- 2. Insert inverse direction
  INSERT INTO initiative_dependencies (
    source_initiative_id, target_initiative_id, dependency_type, notes
  ) VALUES (:init_b, :init_a, 'enables', :notes);
COMMIT;
```

---

## 17. Open Questions

1. ~~**Should initiatives be at Namespace or Workspace level?**~~
   **RESOLVED (v1.1):** Either. Workspace-scoped or namespace-wide.

2. **Should we auto-generate initiatives from TIME/PAID quadrants?**
   Future enhancement. "Suggest Initiatives" button for Eliminate/Modernize/Address apps.

3. ~~**Should there be approval workflow for initiatives?**~~
   **RESOLVED (v1.2):** Ideas provide the approval workflow (submit → review → approve → initiative). Initiatives themselves don't need separate approval — the Idea approval IS the gate.

4. **Should we track actual spend vs. estimated?**
   Future enhancement. Add `actual_one_time_cost` and `actual_recurring_cost` for post-execution tracking.

5. ~~**How to handle PE cross-portfolio comparison?**~~
   **RESOLVED (v1.1):** Workspaces = portfolio companies.

6. **Should the namespace-level dashboard label be configurable?**
   Future enhancement.

7. **Should auto-generated findings include remediation suggestions?**
   Future enhancement. Computed findings → auto-suggest initiatives.

8. ~~**Should Ideas and Projects from OG be separate entities in NextGen?**~~
   **RESOLVED (v1.2):** Ideas = new entity (lightweight intake). Projects absorbed by Initiatives (richer). Programs = new entity (grouping + budget). See Section 3.1 OG mapping.

9. ~~**Should dependency arrows render on the Gantt chart?**~~
   **DEFERRED (v1.3):** Row-based Gantt adopted instead of lane-based Scenario Planner. Dependency count shown as badge on initiative row (🔗2). Full dependency detail in side panel. SVG arrow overlay deferred — high implementation cost, low incremental value given the detail panel already shows dependency chain. Revisit if customers request visual dependency mapping.

10. **Should Programs have a configurable label?**
    Future enhancement. PE firms might call them "Roadmap Tracks." Government might call them "Budget Programs." Enterprises might call them "Strategic Initiatives." Same entity, different label.

11. **Should Ideas support attachments?**
    Future enhancement. "Attach a screenshot" or "link a document" to an Idea. Would use the existing `application_documents` pattern.

12. **When should Business Drivers be promoted from text to a table?**
    Monitor usage. If customers start requesting categorization (regulatory/growth/risk/cost), target dates, or KPI tracking on drivers, it's time. Likely when the second PE customer onboards.

---

## 18. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-12-29 | Initial draft. Defined Finding, Initiative, and junction tables. UI wireframes for Scorecard, Roadmap, Dashboard. |
| v1.1 | 2026-02-22 | **Schema deployed.** Added `source_type` + `source_reference_id` to findings. Added `estimated_run_rate_change` + `run_rate_change_rationale` to initiatives. Multi-persona dashboard (PE/Government/Enterprise). Reporting views. ITSM field mapping. Riverside seed data (8 findings, 6 initiatives). Resolved OQ #1, #5. Stats: 86 tables, 331 RLS, 33 triggers, 25 views. |
| v1.2 | 2026-02-22 | **Schema deployed.** OG → NextGen entity mapping (12 entities). Added Ideas table (lightweight intake, promotion workflow). Added Programs table (N:M grouping, budget envelope, business drivers as text). Added Initiative Dependencies (bidirectional: requires/enables/blocks/related_to). ALTER initiatives + source_idea_id. Reporting views (vw_idea_summary, vw_program_summary). Circular dependency prevention CTE (future). Riverside seed data (6 ideas, 2 programs, 6 assignments, 4 dependencies). Updated ERD, tier gating, API endpoints. Resolved OQ #3, #8. Stats: 90 tables, 347 RLS, 37 triggers, 27 views. |
| v1.3 | 2026-02-22 | **Dashboard scoping model.** Added Section 8.8: Dashboard Scoping & Filter Model — workspace filtering rules for all Roadmap entities. Programs visible via initiative membership (self-organizing, no configuration required). Full program context shown to workspace users (not sliced). Added Section 8.9: Initiative View Modes — three views of same data (Gantt/Kanban/Grid). Row-based Gantt with drag-to-reschedule adopted as default. Kanban columns by status with drag-to-change-status. Grid with sort/filter. Shared KPI bar and detail panel across all views. Resolved OQ #9 (dependency arrows deferred). |

---

## 19. Summary

The Roadmap Module transforms GetInSync from an assessment tool into a **dependency-aware investment planning platform**. The v1.3 architecture completes the dashboard model with:

- **Two-Pipeline Model** — Expert-driven Findings (top-down) and crowd-sourced Ideas (bottom-up) both feed into Initiatives
- **Programs** — Strategic grouping with budget envelopes, owner/sponsor accountability, and business driver justification
- **Initiative Dependencies** — "Requires / enables / blocks" relationships with badge indicators and detail panel
- **Self-Organizing Scoping** — Programs visible to workspace users via initiative membership, no admin configuration required
- **Three View Modes** — Gantt (default, time axis), Kanban (status axis), Grid (sortable table) with shared KPI bar and detail panel
- **Full Program Context** — Workspace users see complete program envelopes, not misleading slices

Combined with v1.1's deployed foundation (Findings, Initiatives, run rate impact, multi-persona dashboards) and v1.2's entity expansion (Ideas, Programs, Dependencies), GetInSync now has the complete architecture to deliver:

> **Assessment → Finding → Idea → Initiative → Program → Budget → Dependencies → Impact**

The killer demo story: *"Your Technology Health Dashboard detected SQL Server 2016 end of support. GetInSync auto-created a finding. Finance submitted an idea to upgrade Cayenta. When we approved the Cayenta initiative, GetInSync flagged the dependency — Cayenta v12 requires SQL 2022. Both initiatives are in the Infrastructure Stabilization program. The Gantt shows the timeline. The KPI bar shows $365K investment with +$13K/yr run rate impact. Drag the SQL Server bar to Q3 and watch the projected run rate update in real time."*

---

End of document.

---

End of document.
