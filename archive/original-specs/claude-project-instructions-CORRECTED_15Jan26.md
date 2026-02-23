# GetInSync NextGen - Claude Project Instructions

## Project Overview

GetInSync NextGen is an Application Portfolio Management (APM) SaaS tool that helps organizations assess and rationalize their application portfolios using the TIME/PAID assessment framework.

**Product Vision:** One codebase with tier-based licensing (Free â†’ Pro â†’ Enterprise â†’ Full), not separate "Lite" and "Full" products.

---

## Tech Stack

| Component | Technology | Details |
|-----------|------------|---------|
| Frontend | Bolt.new | React + TypeScript + Vite + Tailwind |
| Database | Supabase | PostgreSQL, ca-central-1 (Canadian region) |
| Auth | Supabase Auth | Email/password, future: SSO |
| Code Backup | GitHub | sholtby/gis-nextgen-lite |
| Target Deployment | Azure Static Web Apps | Canada Central region |

---

## Core Concepts

### TIME Framework (Technical Health vs Business Fit)
- **Tolerate:** High tech health, Low business fit â€” live with it
- **Invest:** High tech health, High business fit â€” grow it
- **Modernize:** Low tech health, High business fit â€” fix it
- **Eliminate:** Low tech health, Low business fit â€” retire it

### PAID Framework (Criticality vs Tech Risk)
- **Plan:** High criticality, Low tech risk â€” schedule proactive maintenance
- **Address:** High criticality, High tech risk â€” immediate remediation priority
- **Ignore:** Low criticality, Low tech risk â€” accept the risk, minimal investment
- **Delay:** Low criticality, High tech risk â€” fix when able, lower priority

```
PAID Quadrant Grid (X: Technical Risk, Y: Criticality)

Criticality
    â–²
100 â”‚    PLAN    â”‚   ADDRESS
    â”‚            â”‚
 50 â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    â”‚            â”‚
    â”‚   IGNORE   â”‚    DELAY
  0 â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º
    0           50          100
                    Technical Risk
```

### Assessment Factors
- **B1-B10:** Business factors (contribute to Business Fit + Criticality)
- **T01-T15:** Technical factors (contribute to Tech Health + Tech Risk)
- Scores: 1-5 per factor
- Weights: Configurable at Namespace level

---

## Data Architecture

### Hierarchy
```
Namespace (e.g., "Government of Alberta")
â”œâ”€â”€ Assessment Configuration (factors, weights, thresholds)
â”œâ”€â”€ Workspace (e.g., "Ministry of Finance")
â”‚   â”œâ”€â”€ Portfolio (e.g., "Critical Applications")
â”‚   â”‚   â””â”€â”€ Portfolio Assignment â†’ Deployment Profile
â”‚   â”œâ”€â”€ Application (the WHAT - identity only)
â”‚   â”‚   â””â”€â”€ Deployment Profile (the WHERE/HOW - assessment anchor)
â”‚   â””â”€â”€ Contacts
â””â”€â”€ Workspace (e.g., "Central IT")
    â””â”€â”€ ...
```

### Key Architectural Decision: DP-Centric Assessment

**Deployment Profile (DP) is the assessment anchor, NOT Application.**

| Entity | Role |
|--------|------|
| Application | Identity only (name, description, owner, lifecycle) |
| Deployment Profile | Assessment anchor (infrastructure + B1-B10 + T01-T15 + TIME/PAID) |
| Portfolio | Grouping mechanism (contains DPs for reporting views) |
| Portfolio Assignment | Links DP to Portfolio (no scores here) |

**Why:** Same software can have multiple deployments with different technical realities. You assess a DEPLOYMENT, not abstract software.

### DP Naming Convention
- **Single DP:** Name = App name (no suffix) â†’ "Quickbooks Online"
- **When 2nd DP added:** First DP auto-renamed to "{App Name} â€” Primary"
- **Additional DPs:** User names them (e.g., "DR", "Test", "Azure-PROD")
- **Dashboard display:** Shows app name when 1 DP, shows DP name when multiple

---

## Tier Structure

| Tier | Workspaces | Key Features |
|------|------------|--------------|
| **Free** | 2 | View DPs, basic assessment |
| **Pro** | 5 | Edit DPs (hosting, cloud, region, DR) |
| **Enterprise** | Unlimited | Multiple DPs per app, advanced reporting |
| **Full** | Unlimited | Software Product Catalog, IT Service Catalog, Publishing, API |

---

## Assessment Configuration

- **Scope:** Namespace-level (universal across all workspaces)
- **Tables:** `assessment_factors`, `assessment_thresholds`
- **Customizable:** Questions, weights, threshold values
- **Seeded:** Default factors created when namespace is created

---

## Sanitized Case Study

**IMPORTANT:** Use sanitized names for demos, docs, and examples. Never use real Saskatchewan data.

| Real | Sanitized |
|------|-----------|
| Saskatchewan | Alberta |
| Thomson Reuters Elite ProLaw | LegalEdge by Meridian Software |
| Ministry of Justice | Human Rights Tribunal (HRT) |
| Labour Relations and Workplace Safety | Workplace Standards Division (WSD) |
| Saskatchewan Municipal Board | Municipal Affairs Board (MAB) |
| GOS Central IT | Provincial Shared Services (PSS) |

**Demo Story:** PSS purchased LegalEdge, three agencies deploy it (WSD, HRT, MAB) with different infrastructure and different assessments. Shows the value of DP-centric model.

---

## Current Implementation Status

### Completed Phases (1-16)
- âœ… Core TIME/PAID scoring and normalization
- âœ… Quadrant thresholds and calculations
- âœ… Multi-tenant architecture (Namespace â†’ Workspace â†’ Portfolio)
- âœ… RLS policies for data isolation
- âœ… User management and roles
- âœ… Tier limits infrastructure
- âœ… Assessment configuration admin
- âœ… Deployment profiles (stub)
- âœ… Upgrade teasers
- âœ… Multi-workspace portfolio UI

### In Progress: Phase 17 (DP-Centric Assessment)
- 17a: Database schema (score columns on deployment_profiles)
- 17b: Data migration (scores from portfolio_assignments to DPs)
- 17c: TypeScript types
- 17d: UI changes (dashboard shows DPs, assessment modal for DPs)
- 17e: Clone/Move operations

### Future Phases
- **18:** Software Product Catalog (link DPs to shared products)
- **19:** IT Service + Shared Tech Scores (inherited tech for shared infrastructure)
- **20:** Cost Allocation (contracts, IT service costs)
- **21:** WorkspaceGroups + Publishing (shared applications across workspaces)

---

## Shared Application Architecture (Future - Phase 19-21)

### The LegalEdge Consolidation Scenario

When an application is consolidated to shared infrastructure (e.g., all ministries move to one Azure deployment):

**Publisher (PSS/Central IT):**
- Owns the Application and primary Deployment Profile
- Assesses Technical factors (T01-T15) once
- Sets `is_internal_only = false` to publish
- Creates WorkspaceGroup with consumers

**Consumers (WSD, HRT, MAB):**
- See the published application in their workspace
- Assess their own Business factors (B1-B10)
- Technical scores are INHERITED (read-only)
- Each gets their own TIME/PAID based on shared tech + their business fit

### Data Model for Sharing

```
WorkspaceGroup: "LegalEdge Consumers"
â”œâ”€â”€ PSS (IsCatalogPublisher: true) â€” owns the app
â”œâ”€â”€ WSD (Consumer) â€” assesses business fit
â”œâ”€â”€ HRT (Consumer) â€” assesses business fit
â””â”€â”€ MAB (Consumer) â€” assesses business fit

Application (owner_workspace_id: PSS, is_internal_only: false)
â””â”€â”€ DeploymentProfile (PSS) â€” T01-T15 scores
    â””â”€â”€ deployment_profile_consumers
        â”œâ”€â”€ WSD â€” B1-B10 scores, computed TIME/PAID
        â”œâ”€â”€ HRT â€” B1-B10 scores, computed TIME/PAID
        â””â”€â”€ MAB â€” B1-B10 scores, computed TIME/PAID
```

### Key Tables (in stub tables from Phase 15c)
- `workspace_groups` â€” Groups of workspaces that can share
- `workspace_group_members` â€” Membership with IsCatalogPublisher flag
- `deployment_profile_consumers` â€” Consumer's business scores on shared DPs

---

## Spec Documents

All specifications are in `bolt-time-paid-updates-v10.zip` (31 documents):

| Doc | Description |
|-----|-------------|
| 00-overview | Project overview |
| 01-score-normalization | How B1-B10, T01-T15 are normalized |
| 02-quadrant-thresholds | TIME/PAID threshold logic |
| 03-remediation-tshirt-sizing | XS/S/M/L/XL/2XL effort sizing |
| 04-data-model-changes | Database schema |
| 05-ui-updates | UI component specs |
| 06-bubble-sizing-and-settings | Chart configuration |
| 07-application-pool-portfolio-model | Pool vs Portfolio design |
| 08-consistency-review | Cross-doc consistency |
| 09-dashboard-restoration | Dashboard components |
| 10-separate-edit-from-assessment | Edit app vs Assess app |
| 11-rebrand-org-settings | Settings UI |
| 12-getinsync-lite-multi-tenant | Multi-tenant architecture |
| 13a-e | Multi-tenant implementation phases |
| 14-assessment-configuration-admin | Admin UI for factors/thresholds |
| 15-upgrade-ready-architecture | Tier gating, teasers |
| 15a-d | Deployment profiles, free tier, stubs, teasers |
| 16-multi-workspace-portfolio-ui | Portfolio dropdown for multi-workspace |
| 17-dp-centric-assessment | DP as assessment anchor |
| 17a-e | DP implementation phases |

---

## Working with Bolt.new

When giving prompts to Bolt.new:
1. Be specific about what table/component to change
2. Include SQL for database changes
3. Include TypeScript for type changes
4. Describe expected UI behavior
5. One major change per prompt (avoid overwhelming it)

Bolt.new can run Supabase migrations directly â€” no need for manual SQL execution.

---

## Key Reminders

1. **DP is the anchor** â€” Scores live on deployment_profiles, not applications or portfolio_assignments
2. **Namespace-level config** â€” Assessment factors/thresholds are universal within a namespace
3. **Clean DP names** â€” No suffix for single DP, add suffix only when multiple DPs exist
4. **Sanitized data** â€” Use Alberta/LegalEdge for examples, not Saskatchewan/ProLaw
5. **Canadian hosting** â€” Supabase ca-central-1, target Azure Canada Central
6. **GitHub backup** â€” Always sync Bolt.new to sholtby/gis-nextgen-lite

---

## Useful Commands

**Check if DP has score columns:**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'deployment_profiles' AND column_name LIKE 'b%';
```

**Check if DPs exist for all apps:**
```sql
SELECT a.name, dp.id, dp.name 
FROM applications a 
LEFT JOIN deployment_profiles dp ON dp.application_id = a.id;
```

**Create missing DPs:**
```sql
INSERT INTO deployment_profiles (application_id, workspace_id, name, is_primary, assessment_status)
SELECT a.id, a.workspace_id, a.name, true, 'not_started'
FROM applications a
WHERE NOT EXISTS (SELECT 1 FROM deployment_profiles dp WHERE dp.application_id = a.id);
```
