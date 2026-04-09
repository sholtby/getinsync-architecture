# GitBook Documentation Audit & Gap Closure Plan

**Version:** 1.0
**Date:** 2026-04-09
**Status:** Approved
**Owner:** Stuart Holtby

---

## 1. Context

The GetInSync GitBook ([docs.getinsync.ca](https://docs.getinsync.ca)) has **10 published articles**, but the application has **40+ user-facing features** across 6 main tabs, 14+ settings pages, and enterprise catalogs.

**Audience:** Enterprise Architects leading APM initiatives. They understand CSDM, expect strategic-level documentation, and need to see how GetInSync fits their architecture.

**Key gaps identified:**

- No CSDM alignment documentation despite it being a core differentiator
- No coverage for IT Spend, Overview dashboard, Explorer, Settings/Admin, Import, Cost Analysis, or Global Search
- AI Assistant guide exists in repo (`ai-assistant.md`) but is not in GitBook SUMMARY.md
- 6 existing articles need refresh for current UI (April 2026 state)

---

## 2. Approach

Articles organized by **EA Journey Tiers** — the stages an Enterprise Architect follows when adopting GetInSync. Stuart prioritizes and selects articles per-session.

**Output:** Markdown files in `guides/user-help/`, synced to GitBook via git.

**Screenshots:** Captured from dev server (localhost:5173) using Chrome MCP tools. Saved to `guides/user-help/images/`. Data readiness assessed per article.

---

## 3. Article Inventory by EA Journey Tier

### Tier 1: Understand the Platform & CSDM Alignment

*EA asks: "What is this tool and does it fit my architecture?"*

| # | Article | File | Type | Work |
|---|---------|------|------|------|
| 1.1 | Getting Started | `getting-started.md` | Refresh | Update for 6-tab nav, EA tone, CSDM alignment mention |
| 1.2 | Navigating GetInSync | `navigating-getinsync.md` | Refresh | Add Explorer tab, update IT Spend (was Budget), refresh tab descriptions |
| 1.3 | How GetInSync Maps to CSDM | `csdm-alignment.md` | **NEW** | Entity mapping (App to Business App, DP to App Service, Integration to Relationship). DP-as-assessment-anchor philosophy. Conceptual only — no export/sync mechanics |
| 1.4 | What Are Deployment Profiles? | `deployment-profiles.md` | Review | Connect to CSDM language where natural |

**1.3 source material:** `catalogs/csdm-application-attributes.md`, `features/integrations/servicenow-alignment.md`

### Tier 2: Set Up & Populate

*EA asks: "How do I get my portfolio data in here?"*

| # | Article | File | Type | Work |
|---|---------|------|------|------|
| 2.1 | Adding & Managing Applications | `managing-applications.md` | **NEW** | Creation flow, detail page walkthrough, contacts, DPs, operations |
| 2.2 | Importing Applications | `importing-applications.md` | **NEW** | CSV import workflow, field mapping, validation, bulk tips |
| 2.3 | Settings & Administration | `settings-admin.md` | **NEW** | Org settings, user/role management, workspace setup, teams, assessment config, data centers |
| 2.4 | Managing Integrations | `integrations.md` | Refresh | Update for DP-aligned integrations (Phase 2 shipped) |

### Tier 3: Assess & Analyze

*EA asks: "How do I score my portfolio and find the risks?"*

| # | Article | File | Type | Work |
|---|---------|------|------|------|
| 3.1 | How to Assess an Application | `assessment-guide.md` | Refresh | Verify wizard screenshots, add staleness indicators |
| 3.2 | TIME Quadrant | `time-framework.md` | Review | Spot-check accuracy |
| 3.3 | PAID Quadrant | `paid-framework.md` | Review | Spot-check accuracy |
| 3.4 | Reading Tech Health | `tech-health.md` | Refresh | "End of Support" label, CSV export, data quality badges |
| 3.5 | Overview Dashboard Guide | `overview-dashboard.md` | **NEW** | KPI cards, drill-down, risk panels, assessment completion |
| 3.6 | Using the Explorer | `explorer.md` | **NEW** | Cross-cutting filters, column selection, advanced queries |

### Tier 4: Plan & Budget

*EA asks: "What should we do about it, and what does it cost?"*

| # | Article | File | Type | Work |
|---|---------|------|------|------|
| 4.1 | Creating & Managing Initiatives | `roadmap-initiatives.md` | Refresh | Programs/ideas, Gantt/Kanban views, scorecard |
| 4.2 | Understanding IT Spend | `it-spend.md` | **NEW** | Budget tab walkthrough, KPI cards, workspace/service views, run rate |
| 4.3 | Cost Analysis & Run Rate | `cost-analysis.md` | **NEW** | Cost analysis panel, vendor attribution, contracts, expiry widget |

### Tier 5: AI & Search (Power Features)

*EA asks: "How do I get quick answers?"*

| # | Article | File | Type | Work |
|---|---------|------|------|------|
| 5.1 | Portfolio AI Assistant | `ai-assistant.md` | Publish | Review for V2 tool-use, add to SUMMARY.md |
| 5.2 | Using Global Search | `global-search.md` | **NEW** | Cmd+K shortcut, searchable entities, result navigation |

---

## 4. Data Readiness per Article

| Article | Data Ready? | Action Needed |
|---------|-------------|---------------|
| 1.1 Getting Started | Yes | — |
| 1.2 Navigating | Yes | — |
| 1.3 CSDM Alignment | N/A | Conceptual, no live data needed |
| 1.4 Deployment Profiles | Check | Need DP with populated fields + operations section |
| 2.1 Managing Applications | Check | Need a well-populated application |
| 2.2 Importing Applications | No | Need sample CSV prepared |
| 2.3 Settings & Admin | Yes | — |
| 2.4 Integrations | Check | Need integrations with DP links |
| 3.1 Assessment Guide | Yes | — |
| 3.2 TIME Quadrant | Yes | — |
| 3.3 PAID Quadrant | Yes | — |
| 3.4 Tech Health | Yes | — |
| 3.5 Overview Dashboard | Yes | Requires 2+ workspaces |
| 3.6 Explorer | Yes | — |
| 4.1 Roadmap Initiatives | Check | Need initiatives with linked apps |
| 4.2 IT Spend | Check | Need budget data populated |
| 4.3 Cost Analysis | Check | Need cost channel data |
| 5.1 AI Assistant | Yes | — |
| 5.2 Global Search | Yes | — |

---

## 5. Execution Workflow (Per Article)

1. Stuart selects an article from the tier list
2. Check data readiness — seed sample data if needed
3. Start dev server (`npm run dev`) and Chrome MCP
4. Capture screenshots — save to `guides/user-help/images/`
5. Write/update the markdown in `guides/user-help/`
6. Update `SUMMARY.md` if adding a new article
7. Update `whats-new.md` if documenting recently shipped features
8. Stuart reviews article
9. Commit architecture repo

---

## 6. Operational Changes (After First Batch)

Once articles exist, future sessions must keep them current automatically.

### 6a. Add Feature-to-User-Help Map to CLAUDE.md

Add alongside the existing Feature-to-Doc Map:

| Feature Area | User Help Article |
|-------------|-------------------|
| Overview / Dashboard | `overview-dashboard.md` |
| Application Health / TIME-PAID | `assessment-guide.md`, `time-framework.md`, `paid-framework.md` |
| Application detail / creation | `managing-applications.md` |
| Deployment Profiles | `deployment-profiles.md` |
| Technology Health | `tech-health.md` |
| Roadmap / Initiatives | `roadmap-initiatives.md` |
| IT Spend / Budgets | `it-spend.md` |
| Cost Analysis / Contracts | `cost-analysis.md` |
| Explorer tab | `explorer.md` |
| Integrations | `integrations.md` |
| Global Search | `global-search.md` |
| AI Chat | `ai-assistant.md` |
| Settings / Admin / Users | `settings-admin.md` |
| Import | `importing-applications.md` |
| CSDM alignment | `csdm-alignment.md` |
| Navigation / Onboarding | `getting-started.md`, `navigating-getinsync.md` |

### 6b. Enhance Session-End Checklist section 6h

Update `operations/session-end-checklist.md`:

1. Reference the Feature-to-User-Help Map in CLAUDE.md for article routing
2. Make `whats-new.md` append format explicit (date, heading, bullet points with business impact)
3. Add step: "If you created a new article, update `SUMMARY.md` for GitBook navigation"

### 6c. Update session-end-user-docs.md Procedure

Update `operations/session-end-user-docs.md`:

- Point to the Feature-to-User-Help Map in CLAUDE.md
- Add screenshot update guidance: "If UI changed visually, recapture screenshots via Chrome MCP"
- Include `whats-new.md` entry template

---

## 7. Summary

| Category | Count |
|----------|-------|
| New articles | 8 |
| Refresh existing | 6 |
| Review only | 3 |
| Publish (exists, not on GitBook) | 1 |
| **Total** | **18** |

---

## 8. SUMMARY.md Target State

After all articles are written, `guides/SUMMARY.md` should read:

```markdown
# Table of contents

* [Getting Started](README.md)
* [What's New](whats-new.md)

## New to GetInSync

* [Getting Started with GetInSync](user-help/getting-started.md)
* [Navigating GetInSync](user-help/navigating-getinsync.md)
* [How GetInSync Maps to CSDM](user-help/csdm-alignment.md)

## Setting Up Your Portfolio

* [Adding & Managing Applications](user-help/managing-applications.md)
* [What Are Deployment Profiles?](user-help/deployment-profiles.md)
* [Importing Applications](user-help/importing-applications.md)
* [Settings & Administration](user-help/settings-admin.md)
* [Managing Application Integrations](user-help/integrations.md)

## Assessing Your Applications

* [How to Assess an Application](user-help/assessment-guide.md)
* [TIME Quadrant Explanation](user-help/time-framework.md)
* [PAID Quadrant Explanation](user-help/paid-framework.md)
* [Reading Tech Health Indicators](user-help/tech-health.md)
* [Overview Dashboard Guide](user-help/overview-dashboard.md)
* [Using the Explorer](user-help/explorer.md)

## Planning & Budgeting

* [Creating and Managing Initiatives](user-help/roadmap-initiatives.md)
* [Understanding IT Spend](user-help/it-spend.md)
* [Cost Analysis & Run Rate](user-help/cost-analysis.md)

## Power Features

* [Portfolio AI Assistant](user-help/ai-assistant.md)
* [Using Global Search](user-help/global-search.md)
```
