# GetInSync Architecture Repo — Migration Guide

**Date:** 2026-02-22  
**Purpose:** Consolidate all architecture documents from local disk + Claude Project into a single git repo  
**Principle:** Import as-is, clean up after. Git history > version suffixes.

---

## Step 1: Create the GitHub Repo

```bash
# On GitHub: Create new repo
# Name: getinsync-architecture
# Visibility: Private
# DON'T initialize with README (we'll push our own)

# Local machine
mkdir getinsync-architecture
cd getinsync-architecture
git init
git remote add origin git@github.com:sholtby/getinsync-architecture.git
```

---

## Step 2: Create the Folder Structure

```bash
mkdir -p core
mkdir -p features/cost-budget
mkdir -p features/technology-health
mkdir -p features/it-value-creation
mkdir -p features/ai-chat
mkdir -p features/cloud-discovery
mkdir -p features/gamification
mkdir -p features/integrations
mkdir -p catalogs
mkdir -p identity-security
mkdir -p operations
mkdir -p marketing
mkdir -p planning
mkdir -p sessions
mkdir -p schema
mkdir -p archive/original-specs
mkdir -p archive/superseded
mkdir -p prd
```

---

## Step 3: Copy Files from Claude Project / Local Disk

Below is the complete migration map. The left column is the current filename (as it exists in the Claude Project or on disk). The right column is where it goes in the new repo.

### Naming Convention for New Filenames

- **Drop `gis-` prefix** — redundant inside a GetInSync repo  
- **Drop version suffixes from filenames** — git handles versioning  
- **Keep version in the document header** — human-readable reference  
- **When multiple versions exist** — import only the latest, archive the older one  
- **Use kebab-case** — consistent with current convention  

### 3A: Core Architecture (7 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-core-architecture-v2_4.md` | `core/core-architecture.md` | 🟠 Has AWS refs — cleanup later |
| `gis-nextgen-conceptual-erd-v1_2.md` | `core/conceptual-erd.md` | 🟠 Has AWS refs |
| `gis-deployment-profile-architecture-v1_8.md` | `core/deployment-profile.md` | 🟢 |
| `gis-composite-application-architecture-v1_1.md` | `core/composite-application.md` | 🟡 |
| `gis-composite-application-erd.md` | `core/composite-application-erd.md` | 🟡 |
| `gis-workspace-group-architecture-v1_6.md` | `core/workspace-group.md` | 🟠 3 AWS refs |
| `gis-involved-party-architecture-v1_9.md` | `core/involved-party.md` | |

### 3B: Catalogs & Classification (7 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-software-product-architecture-v2_1.md` | `catalogs/software-product.md` | 🟠 10 AWS refs |
| `gis-it-service-architecture-v1_3.md` | `catalogs/it-service.md` | 🟠 13 AWS refs |
| `gis-business-application-architecture-v1_2.md` | `catalogs/business-application.md` | 🟠 4 AWS refs |
| `gis-business-application-identification-v1_0.md` | `catalogs/business-application-identification.md` | ☪ Reference |
| `gis-csdm-application-attributes-v1_0.md` | `catalogs/csdm-application-attributes.md` | ☪ Reference |
| `gis-technology-catalog-architecture-v1_0.md` | `catalogs/technology-catalog.md` | 🟢 |
| `gis-application-reference-model-architecture-v2_0.md` | `catalogs/application-reference-model.md` | ☪ Reference |
| `gis-application-reference-model-erd-v2_0.md` | `catalogs/application-reference-model-erd.md` | ☪ Reference |

### 3C: Features — Cost & Budget (6 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-cost-model-architecture-v2_5.md` | `features/cost-budget/cost-model.md` | 🟠 2 AWS refs |
| `gis-cost-model-addendum-v2_5_1.md` | `features/cost-budget/cost-model-addendum.md` | 🟡 |
| `gis-budget-management-architecture-v1_3.md` | `features/cost-budget/budget-management.md` | 🟠 Latest version |
| `gis-budget-alerts-architecture-v1_0.md` | `features/cost-budget/budget-alerts.md` | 🟢 |
| `gis-vendor-cost-architecture-v1_0.md` | `features/cost-budget/vendor-cost.md` | 🟢 |
| `gis-software-contract-architecture-v1_0.md` | `features/cost-budget/software-contract.md` | 🟡 |

### 3D: Features — Technology Health & Risk (5 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-technology-health-dashboard-architecture-v1_0.md` | `features/technology-health/dashboard.md` | 🟢 |
| `gis-technology-lifecycle-intelligence-architecture-v1_1.md` | `features/technology-health/lifecycle-intelligence.md` | 🟡 |
| `gis-technology-stack-erd-corrected-v1_0.md` | `features/technology-health/technology-stack-erd.md` | 🟢 |
| `gis-technology-stack-erd-addendum-v1_1.md` | `features/technology-health/technology-stack-erd-addendum.md` | 🟡 |
| `gis-risk-management-boundary-decision-v1_0.md` | `features/technology-health/risk-boundary.md` | 🟢 |

### 3E: Features — IT Value Creation (1 file)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-it-value-creation-architecture-v1_1.md` | `features/it-value-creation/architecture.md` | 🟡 AS-DESIGNED |

### 3F: Features — AI Chat (3 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-apm-AI-chat-mvp.md` | `features/ai-chat/mvp.md` | 🟢 |
| `gis-apm-AI-chat-v2.md` | `features/ai-chat/v2.md` | 🟢 |
| `gis-apm-AI-chat-v3-multicloud.md` | `features/ai-chat/v3-multicloud.md` | 🟡 Mixed refs |

### 3G: Features — Other (5 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-cloud-discovery-architecture-v1_0.md` | `features/cloud-discovery/architecture.md` | 🟡 |
| `gis-gamification-architecture-v1_2.md` | `features/gamification/architecture.md` | 🟡 |
| `gis-integrations-architecture-v1_2.md` | `features/integrations/architecture.md` | |
| `gis-itsm-api-research-v1_0.md` | `features/integrations/itsm-api-research.md` | |
| `gis-servicenow-alignment-v1_2.md` | `features/integrations/servicenow-alignment.md` | |

### 3H: Identity, Security & Compliance (9 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-identity-security-architecture-v1_1.md` | `identity-security/identity-security.md` | 🟠 MAJOR REWRITE NEEDED |
| `gis-rls-policy-architecture-v2_3.md` | `identity-security/rls-policy.md` | Latest full doc |
| `gis-rls-policy-architecture-v2_4-addendum.md` | `identity-security/rls-policy-addendum.md` | |
| `gis-rbac-permission-architecture-v1_0.md` | `identity-security/rbac-permissions.md` | |
| `gis-user-registration-invitation-architecture-v1_0.md` | `identity-security/user-registration.md` | |
| `gis-security-posture-automated-overview-v1_1.md` | `identity-security/security-posture-overview.md` | 🟠 Stats stale |
| `gis-security-validation-runbook-v1_0.md` | `identity-security/security-validation-runbook.md` | |
| `gis-soc2-evidence-collection-skill.md` | `identity-security/soc2-evidence-collection.md` | 🟠 Trigger count stale |
| `gis-soc2-evidence-index-v1_1.md` | `identity-security/soc2-evidence-index.md` | |

### 3I: Operations & Development (8 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `getinsync-development-rules-v1_4.md` | `operations/development-rules.md` | 🟢 |
| `CLAUDE.md` | `CLAUDE.md` | **Keep at repo root** for Claude Code |
| `getinsync-team-workflow-skill.md` | `operations/team-workflow.md` | 🟠 Refs AG as primary |
| `gis-session-end-checklist-v1_3.md` | `operations/session-end-checklist.md` | 🟢 |
| `gis-database-change-validation-skill-v1_0.md` | `operations/database-change-validation.md` | |
| `gis-new-table-checklist-v1_0.md` | `operations/new-table-checklist.md` | |
| `gis-demo-namespace-checklist-v2.md` | `operations/demo-namespace-checklist.md` | 🟢 |
| `gis-demo-credentials-v1_1.md` | `operations/demo-credentials.md` | 🟢 |

### 3J: Marketing & Business (5 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-marketing-explainer-v1_7-additions.md` | `marketing/explainer.md` | Latest — merge v1.5 base + v1.7 additions later |
| `gis-marketing-positioning-statements-v1_0.md` | `marketing/positioning-statements.md` | |
| `gis-marketing-product-roadmap-2026.md` | `marketing/product-roadmap-2026.md` | |
| `gis-pricing-model-v1_0.md` | `marketing/pricing-model.md` | ☪ |
| `gis-nextgen-presentation-v1_0.md` | `marketing/executive-presentation.md` | ☪ |

### 3K: Planning & Change Management (6 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-architecture-manifest-v1_24.md` | `MANIFEST.md` | **Keep at repo root** — becomes the README-like index |
| `gis-architecture-changelog-v1_9.md` | `CHANGELOG.md` | **Keep at repo root** |
| `gis-q1-2026-master-plan-v1_4.md` | `planning/q1-2026-master-plan.md` | Superseded by xlsx but keep for reference |
| `GetInSync_Q1_2026_Gantt_v2_0.xlsx` | `planning/q1-2026-gantt-v2.xlsx` | Binary — keep version in name |
| `gis-open-items-priority-matrix.md` | `planning/open-items-priority-matrix.md` | Living doc |
| `gis-phase-25_8-super-admin-plan.md` | `planning/phase-25-8-super-admin-plan.md` | |

### 3L: Work Packages (2 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-work-package-multi-region-v1_0.md` | `planning/work-package-multi-region.md` | |
| `gis-work-package-privacy-oauth-v1_0.md` | `planning/work-package-privacy-oauth.md` | |

### 3M: Visualization (2 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-visual-diagram-architecture-v1_0.md` | `core/visual-diagram.md` | |
| `gis-namespace-workspace-ui-architecture-v1_0.md` | `core/namespace-workspace-ui.md` | |
| `gis-namespace-management-ui-v1_0.md` | `core/namespace-management-ui.md` | |

### 3N: Session Summaries (7 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `session-summary-2026-02-12b.md` | `sessions/2026-02-12b.md` | |
| `session-summary-2026-02-13.md` | `sessions/2026-02-13.md` | |
| `session-summary-2026-02-14b.md` | `sessions/2026-02-14b.md` | |
| `session-summary-2026-02-17.md` | `sessions/2026-02-17.md` | |
| `session-summary-2026-02-18.md` | `sessions/2026-02-18.md` | |
| `session-summary-2026-02-18-part1.md` | `sessions/2026-02-18-part1.md` | |
| `session-summary-2026-02-18-part2.md` | `sessions/2026-02-18-part2.md` | |
| `session-summary-2026-02-21.md` | `sessions/2026-02-21.md` | |

### 3O: Schema & SQL (4 files)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `getinsync-nextgen-schema-2026-02-18-pm.sql` | `schema/nextgen-schema-current.sql` | Always overwrite with latest |
| `gis-demo-namespace-template-v2_0.sql` | `schema/demo-namespace-template.sql` | |
| `gis-audit-logging-1-ddl.txt` | `schema/audit-logging-ddl.sql` | Rename .txt → .sql |
| `gis-audit-logging-2-functions.txt` | `schema/audit-logging-functions.sql` | Rename .txt → .sql |
| `gis-audit-logging-3-triggers.txt` | `schema/audit-logging-triggers.sql` | Rename .txt → .sql |

### 3P: Archive — Superseded Versions (keep for git history, not active)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `gis-identity-security-architecture-v1_0.md` | `archive/superseded/identity-security-v1_0.md` | Superseded by v1.1 |
| `gis-budget-management-architecture-v1_2.md` | `archive/superseded/budget-management-v1_2.md` | Superseded by v1.3 |
| `gis-architecture-changelog-v1_7.md` | `archive/superseded/architecture-changelog-v1_7.md` | Superseded by v1.9 |
| `gis-marketing-explainer-v1_5.md` | `archive/superseded/marketing-explainer-v1_5.md` | Base doc, additions in v1.7 |
| `gis-q1-2026-master-plan-v1_0.md` | `archive/superseded/q1-2026-master-plan-v1_0.md` | Superseded by v1.4 |
| `gis-rls-policy-architecture-v2_3.md` | `archive/superseded/rls-policy-v2_3.md` | If v2.4 addendum gets merged |

### 3Q: Archive — Original Specs (historical, Phase 1-16)

| Source Filename | Destination | Notes |
|----------------|-------------|-------|
| `00-overview.md` through `16-multi-workspace-portfolio-ui.md` | `archive/original-specs/` | **All 22 files** — keep names as-is |
| `claude-project-instructions-CORRECTED_15Jan26.md` | `archive/original-specs/` | Original Claude instructions |
| `portfolio-insights-concept.md` | `archive/original-specs/` | Early concept doc |
| `gis-time-paid-methodology-v1_0.md` | `archive/original-specs/` or `core/` | Could argue either way — it's ☪ Reference |

---

## Step 4: Create the README.md

The repo `README.md` replaces the manifest as the entry point. Create it from a simplified version of the manifest:

```markdown
# GetInSync NextGen — Architecture Documentation

> **Single source of truth** for all architecture, design, and operational documentation.  
> Clean up docs via PRs. Git history replaces version suffixes.

## Quick Links

| What | Where |
|------|-------|
| Master Document Index | [MANIFEST.md](MANIFEST.md) |
| Change Log | [CHANGELOG.md](CHANGELOG.md) |
| Claude Code Rules | [CLAUDE.md](CLAUDE.md) |
| Current Schema | [schema/nextgen-schema-current.sql](schema/nextgen-schema-current.sql) |
| Open Items | [planning/open-items-priority-matrix.md](planning/open-items-priority-matrix.md) |

## Folder Guide

| Folder | Contents |
|--------|----------|
| `core/` | Core data model, ERDs, deployment profiles, workspaces |
| `catalogs/` | Software products, IT services, technology catalog, reference models |
| `features/` | Feature-specific architecture (cost, tech health, AI chat, etc.) |
| `identity-security/` | RLS, RBAC, SOC2, auth, security runbooks |
| `operations/` | Dev rules, checklists, skills, demo setup |
| `marketing/` | Explainer, positioning, pricing, roadmap |
| `planning/` | Q1 plan, Gantt, work packages, open items |
| `sessions/` | Session summaries (recent only) |
| `schema/` | SQL schema dumps, audit logging DDL, demo templates |
| `prd/` | PRD-style execution specs for new phases |
| `archive/` | Superseded versions + original Phase 1-16 specs |

## Status Tags (in document headers)

| Tag | Meaning |
|-----|---------|
| 🟢 AS-BUILT | Accurately describes production |
| 🟡 AS-DESIGNED | Architecture approved, not yet implemented |
| 🟠 NEEDS UPDATE | Concept valid, contains stale references |
| ☪ REFERENCE | Stack-agnostic methodology or reference material |
```

---

## Step 5: Initial Commit

```bash
cd getinsync-architecture

# Stage everything
git add -A

# Initial import commit — this is your baseline
git commit -m "Initial import: 80+ architecture docs from Claude Project

Imported as-is from local disk and Claude Project files.
No cleanup performed — all AWS refs, stale stats, version suffixes
in content preserved. Git history starts here.

Documents organized into: core/, catalogs/, features/, identity-security/,
operations/, marketing/, planning/, sessions/, schema/, archive/

Superseded versions archived. Original Phase 1-16 specs preserved.
MANIFEST.md, CHANGELOG.md, and CLAUDE.md at repo root."

# Push
git branch -M main
git push -u origin main
```

---

## Step 6: Update Claude Project Files

After the repo exists, **trim the Claude Project down** to only what Claude needs in-context. You no longer need every document uploaded — Claude Code reads the repo directly, and Opus can search project knowledge.

### Keep in Claude Project (high-value, frequently referenced):
- `CLAUDE.md` — Claude Code rules
- `MANIFEST.md` — document index (so Opus knows what exists)
- `operations/development-rules.md` — dev workflow
- `operations/session-end-checklist.md` — end-of-session process  
- `planning/open-items-priority-matrix.md` — current backlog
- `schema/nextgen-schema-current.sql` — latest schema
- Latest session summary (1-2 max)
- Any **active phase PRD** from `prd/`

### Remove from Claude Project (accessible via repo):
- All archive/ docs
- All session summaries older than current week
- Superseded versions
- Marketing docs (rarely needed during dev)
- Original Phase 1-16 specs

**Target: ~15-20 files in Claude Project instead of 95+**

---

## Step 7: Update Workflows

### Session-End Checklist Update
Add to session-end checklist:

```
## 11. Architecture Repo Commit
- [ ] Any new/modified architecture docs committed to getinsync-architecture repo
- [ ] MANIFEST.md updated if new documents added
- [ ] Session summary committed to sessions/
- [ ] Schema dump updated if DB changes made
```

### Claude Code CLAUDE.md Update
Add to CLAUDE.md:

```
## Architecture Documentation
Architecture docs live in: https://github.com/sholtby/getinsync-architecture
Read architecture docs from this repo, not from memory.
Schema reference: schema/nextgen-schema-current.sql
```

### New Phase Workflow
For new phases (like IT Value Creation UI), create a PRD in `prd/`:

```
prd/phase-21-it-value-creation-ui.md
```

Using elements from the PRD template (task blocks, test requirements, dependency graph) while referencing the architecture doc in `features/it-value-creation/architecture.md`.

---

## Step 8: Post-Migration Cleanup Roadmap

Now that everything is in git, cleanup becomes a series of focused PRs:

| PR | Scope | Effort |
|----|-------|--------|
| PR-1 | Remove AWS refs from core-architecture.md | 30 min |
| PR-2 | Remove AWS refs from conceptual-erd.md | 30 min |
| PR-3 | Rewrite identity-security.md (drop Entra/QuickSight) | 2 hrs |
| PR-4 | Update security-posture-overview.md stats (86 tables/33 triggers) | 15 min |
| PR-5 | Update soc2-evidence-collection.md trigger count | 15 min |
| PR-6 | Update team-workflow.md (AG → Claude Code) | 30 min |
| PR-7 | Merge marketing explainer v1.5 + v1.7 additions into single doc | 45 min |
| PR-8 | Remove AWS refs from catalogs (software-product, it-service, etc.) | 1 hr |

Each PR has a clean diff showing exactly what was cleaned up. You can tackle one per session as a warmup task.

---

## Migration Checklist

- [ ] Create GitHub repo `getinsync-architecture`
- [ ] Run folder creation commands (Step 2)
- [ ] Copy files using migration map (Step 3) — use script below
- [ ] Create README.md (Step 4)
- [ ] Initial commit and push (Step 5)
- [ ] Trim Claude Project files (Step 6)
- [ ] Update session-end checklist (Step 7)
- [ ] Update CLAUDE.md (Step 7)
- [ ] First cleanup PR (Step 8) — pick an easy one to validate the workflow

---

*Document: gis-architecture-repo-migration-guide.md*  
*February 22, 2026*
