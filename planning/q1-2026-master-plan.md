# planning/q1-2026-master-plan.md
GetInSync NextGen - Q1 2026 Master Execution Plan  
Last updated: 2026-02-14

---

## Executive Summary

**Timeline:** February 10 - March 31, 2026 (7 weeks)  
**Owner:** Stuart Holtby  
**Status:** Resequenced — Architecture Sprint Changed Priorities

### What Changed Since v1.3

**v1.3 (Feb 9)** planned a Foundation Phase (Week 1-2) followed by IT Value Creation (Week 3). What actually happened was an intense architecture sprint (Feb 10-14) that produced 12 new architecture documents covering three major feature areas — all originally deferred to Q2:

1. **Technology Health Dashboard** — designed, schema spec'd (~8-9 days to implement)
2. **Gamification & Data Governance** — designed, schema spec'd (~12-15 days across 7 phases)
3. **Technology Lifecycle Intelligence v1.1** — designed, views spec'd (~17 hrs)

Plus: Visual Tab architecture, two-path technology model, infrastructure boundary rubric, risk boundary ADR, cost model addendum, and marketing positioning updates.

**Why this matters:** Customer conversations (Saskatchewan Power BI problem, Garland 637 servers, crawl-to-walk gap) revealed that Technology Health is the #1 demo-worthy feature for ServiceNow Knowledge. IT Value Creation is still important but benefits from having Technology Health data to generate findings FROM. The architecture sprint wasn't scope creep — it was customer discovery that changed our understanding of what to build first.

### Key Metrics (Updated)
- **Available Dev Days Remaining:** ~15-17 days (Feb 15 - Mar 31)
- **Architecture Designed (Not Built):** ~35 days of implementation work
- **Must Ship for Knowledge:** Technology Health Dashboard + IT Value Creation (minimum viable)
- **Critical Foundation Items Still Open:** 5 (from v1.3 WBS)
- **Status:** Behind on Foundation, ahead on architecture

### Strategic Decision (Updated)
**Build Order:** ~~IT Value Creation (Week 3)~~ → **Technology Health Dashboard (Week 3-4) → IT Value Creation (Week 4-5)**  
**Deferred to Q2:** Gamification implementation (architecture complete), Composite Applications, SSO  
**Rationale:** Technology Health is most visual, most aligned with Knowledge conference messaging ("your CMDB has the infrastructure — we add the business context"), and feeds findings into IT Value Creation.

---

## Key Milestones (Updated)

### Completed

| Date | Status | Milestone |
|------|--------|-----------|
| Feb 7, 2026 | ✅ Complete | Phase 25.9 Complete (RLS Migration — All 66→72 tables) |
| Feb 8, 2026 | ✅ Complete | Phase 25.10 Schema + Multi-Region DB + Architecture Audit |
| Feb 8, 2026 | ✅ Complete | **Phase 28: Integration Management Shipped** |
| Feb 9, 2026 | ✅ Complete | SOC2 Audit Logging + Quality Infrastructure |
| Feb 10, 2026 | ✅ Complete | Visual Tab Architecture v1.0 + Technology Stack ERD v1.0 |
| Feb 11, 2026 | ✅ Complete | Operational Statuses table + Schema backup (72 tables) |
| Feb 12, 2026 | ✅ Complete | Google OAuth verified + Session-end checklist v1.2 |
| Feb 13, 2026 | ✅ Complete | Nested Portfolio UI + Audit log backfill (#5 closed) + Schema backup |
| Feb 13, 2026 | ✅ Complete | **Technology Health Dashboard architecture designed** (5 new docs) |
| Feb 14, 2026 | ✅ Complete | **Gamification architecture designed** (1 new doc, 4 tables) |
| Feb 14, 2026 | ✅ Complete | **Infrastructure Boundary Rubric + Lifecycle Intelligence v1.1** |

### Upcoming

| Date | Status | Milestone |
|------|--------|-----------|
| Feb 17-21 | Target | Foundation Catchup (Power BI, bug fixes, Delta training) |
| Feb 21 | Target | Delta 100% Operational |
| Feb 24-28 | Target | Technology Health Dashboard — schema + views deployed |
| Mar 3-7 | Target | Technology Health Dashboard — UI live (AG) |
| Mar 10-14 | Target | IT Value Creation — schema + UI shipped |
| Mar 17-28 | Target | Polish + Knowledge Conference Prep |
| Mar 31, 2026 | Target | Q1 Complete — Knowledge Demo Ready |

---

## Revised Week-by-Week Timeline

### Architecture Sprint (Feb 10-14) — COMPLETED

**What happened:** Instead of executing Foundation Phase items, went deep on architecture driven by customer insights:

| Customer Signal | Architecture Response | Knowledge Demo Value |
|----------------|----------------------|---------------------|
| Saskatchewan built Power BI from 8 CMDB spreadsheets | Technology Health Dashboard v1.0 | "Replace your spreadsheet dashboards" |
| Garland has 637 server records mixed with apps | Infrastructure Boundary Rubric v1.0 | "We know what belongs in APM vs CMDB" |
| Every customer asks "what's end-of-life?" | Lifecycle Intelligence v1.1 (two-path model) | "AI-powered EOL tracking" |
| Government staff don't fill in the tool | Gamification v1.2 + Data Quality Flags | "Built-in engagement, not bolted-on" |
| Risk registers stuck in Draft (93%) | Risk Boundary ADR | "We detect risks. GRC tools manage response." |

**Documents produced (12 new, 3 updated):**
- Visual Tab architecture v1.0
- Technology Stack ERD v1.0 + Addendum v1.1 (two-path model)
- Technology Health Dashboard architecture v1.0
- Cost Model Addendum v2.5.1
- Risk Management Boundary Decision v1.0
- Infrastructure Boundary Rubric v1.0
- Technology Lifecycle Intelligence v1.1 (updated from v1.0)
- Gamification Architecture v1.2
- Marketing Explainer v1.6 + v1.7 additions
- Architecture Manifest v1.18→v1.23 (5 versions)
- Architecture Changelog v1.8→v1.9

**Architecture Principles established:** 9 (Two-Path Technology Model), 10 (Risk Boundary — APM vs GRC), 11 (Audit-Log-Driven Event Sourcing)

**Net assessment:** This sprint was the right use of time. We now have a product story that sells at Knowledge, not just features. The penalty is Foundation Phase items slipped by one week.

---

### Week 3: Foundation Catchup (Feb 17-21)
**Theme:** Execute the v1.3 Week 1-2 items that slipped  
**Effort:** 4-5 days

**Stuart:**

| Item | Effort | Priority | Notes |
|------|--------|----------|-------|
| Power BI Foundation (WBS 1.10) | 3-4 hrs | HIGH | 14 views ready, just deploy + first dashboard. Quick win. |
| Delta training on Namespace UI | 2 hrs | HIGH | Operational necessity — Garland depends on it |
| Schema backup refresh | 30 min | HIGH | Capture Feb 13 as current (done), need to capture any Feb 14+ changes |
| Dependabot enable (#13) | 30 min | MED | SOC2 CC6.7 gap, trivial to close |
| Identity/Security rewrite assessment | 2 hrs | MED | Assess scope — is v2.0 needed for Knowledge, or can SSO wait? |

**AG (Antigravity):**

| Item | Effort | Priority | Notes |
|------|--------|----------|-------|
| Phase 28 bug fixes — 13 items | 1-2 days | HIGH | Consolidated prompt ready. Connections tab needs to work for demos. |
| Namespace UI polish — slug, region dropdown | 0.5 day | MED | Nice-to-have for demo, not blocking |
| Website update | 1 day | MED | Professional credibility for Knowledge |

**Delta:**

| Item | Effort | Priority | Notes |
|------|--------|----------|-------|
| Garland mapping completion | 2-3 days | HIGH | 363 apps + 7,646 assessments |
| SOC2 policies (3 HIGH — GPD-528/529/530) | 6-8 hrs | HIGH | Due Feb 27 |
| Namespace UI training | 2 hrs | HIGH | Must be independent before Garland import |

**Deliverables by Feb 21:**
- Power BI views deployed, first dashboard built
- Delta can manage namespaces independently
- Connections tab bugs fixed (AG)
- Dependabot enabled (SOC2 quick win)
- Clear decision on SSO timeline (do or defer)

---

### Week 4: Technology Health Dashboard — Schema (Feb 24-28)
**Theme:** Build the #1 Knowledge demo feature — backend  
**Effort:** 5 days

**Why Technology Health before IT Value Creation:**
1. Most visual feature — lifecycle badges, risk indicators, blast radius
2. Most aligned with Knowledge messaging — "your CMDB has infrastructure, we add context"
3. Customer-validated — Saskatchewan's Power BI problem is the exact use case
4. Feeds IT Value Creation — lifecycle findings auto-generate from Tech Health data
5. Simpler schema — 8 column additions + 3 views vs IT Value Creation's 4 new tables + junctions

**Components:**

1. **Schema deployment** (0.5 day)
   - applications: +is_crown_jewel, +management_classification, +csdm_stage, +branch
   - deployment_profiles: +server_name (optional text ref per Boundary Rubric)
   - technology_products: +product_family, +lifecycle_reference_id (FK)
   - deployment_profile_technology_products: +edition
   - technology_lifecycle_entries: +maintenance_type
   - All per new table checklist (GRANT/RLS/audit)

2. **Technology lifecycle reference seeding** (0.5 day)
   - Populate common products: Windows Server (2012R2→2025), SQL Server (2012→2022), Oracle (11g→23ai), Red Hat (7→9)
   - Include lifecycle dates from vendor documentation
   - Link technology_products → technology_lifecycle_reference

3. **Database views** (0.5 day)
   - vw_technology_health_summary
   - vw_application_infrastructure_report
   - vw_technology_tag_lifecycle_risk (Path 1, from Lifecycle Intelligence v1.1)
   - vw_dp_lifecycle_risk_combined (unified, from Lifecycle Intelligence v1.1)

4. **Lifecycle badge integration on DP** (1 day)
   - When user tags technology on DP, show lifecycle status inline
   - Badge: "SQL Server 2016 [EXTENDED] EOL Jul 2026"
   - T02 score suggestion from lifecycle status

5. **Demo data — City of Riverside** (0.5 day)
   - Tag technology products on existing 56 apps' DPs
   - Mix of lifecycle statuses: some EOL, some Extended, mostly Mainstream
   - Crown Jewel flags on ~5 apps

6. **Garland import execution** (1-2 days, flexible)
   - Execute once Delta mapping complete
   - Apply boundary rubric: import tech tags from server data, not server entities
   - 363 apps + 7,646 assessments

**Deliverables by Feb 28:**
- Technology Health schema live in production
- Lifecycle reference data seeded for common platforms
- Lifecycle badges visible on deployment profiles
- Riverside demo has technology tags + Crown Jewel flags
- Garland import underway or complete

---

### Week 5: Technology Health Dashboard — UI + IT Value Creation Start (Mar 3-7)
**Theme:** Make it visual, start "So What?"  
**Effort:** 5 days

**AG (primary):**

1. **Technology Health Dashboard page** (2-3 days AG)
   - New top-level navigation item
   - Summary KPIs: Total apps, Crown Jewels, EOL count, Extended count, Mainstream
   - Technology layer breakdown: OS, DB, Web with lifecycle charts
   - Workspace breakdown table
   - Filterable application infrastructure report
   - Blast radius drill-down (click technology → see all affected apps)

**Stuart (parallel):**

2. **IT Value Creation schema** (1 day)
   - initiatives, findings, initiative_deployment_profiles, initiative_findings tables
   - RLS + GRANTs + audit triggers per checklist
   - findings.source_type column ('manual'/'computed'/'imported') — informed by lifecycle pipeline
   - findings.source_reference_id — links to technology_product for auto-generated findings

3. **IT Value Creation views** (0.5 day)
   - Initiative summary view
   - Finding summary view (including computed lifecycle findings)

4. **Connect the pipeline** (0.5 day)
   - Auto-generate findings from lifecycle risk data
   - "SQL Server 2016 — End of Support Jul 2026" → Finding with affected DP count
   - This is the "four-document pipeline" in action: Boundary Rubric → Lifecycle Intelligence → Risk Indicators → Findings

**Deliverables by Mar 7:**
- Technology Health Dashboard live and visual
- IT Value Creation schema deployed
- Auto-generated lifecycle findings working
- Knowledge demo data compelling

---

### Week 6: IT Value Creation UI (Mar 10-14)
**Theme:** Complete the "So What?" answer  
**Effort:** 4-5 days

**AG:**

1. **Findings list view** (1 day)
   - Filterable by assessment_domain (business, technical, infrastructure)
   - Source type badges (manual, computed, imported)
   - Link to affected DPs/applications

2. **Initiatives list + detail** (1.5 days)
   - Initiative cards with status, linked findings, affected DPs
   - Kanban board view (backlog → planned → in-progress → complete)
   - Value dashboard (investment by theme, timeline)

3. **Roadmap timeline view** (1 day)
   - Gantt-style or swim-lane view of initiatives
   - Shows sequencing and dependencies
   - Board-ready strategic roadmap

**Stuart:**

4. **Demo data + testing** (0.5 day)
   - Create sample initiatives for Riverside (and Garland if imported)
   - Link findings to initiatives
   - Delta training

5. **Documentation** (0.5 day)
   - Update IT Value Creation architecture to v1.1 (source_type, lifecycle pipeline)

**Deliverables by Mar 14:**
- Full IT Value Creation module live
- Findings auto-generated from technology lifecycle data
- Board-ready roadmap view
- "So what?" question answered with data

---

### Week 7-8: Polish + Knowledge Prep (Mar 17-31)
**Theme:** Make it demo-perfect  
**Effort:** 5-8 days (buffer absorbed here)

**Priority order:**

1. **Knowledge demo script** (1 day)
   - Walk-through: import data → technology tags → lifecycle risk → findings → roadmap
   - Live demo using Riverside (56 apps) or Garland (363 apps)
   - Pitch: "Your CMDB has the infrastructure. Your cmdb_ci_business_app is empty. We fill it."

2. **Power BI Garland demo** (1 day)
   - 363 apps in Power BI with namespace-scoped views
   - Shows complementary story: GetInSync data → Power BI visualization

3. **UI consistency pass** (1-2 days AG)
   - Icons (Phase C — 8 entity list pages)
   - Branding (logo in sidebar — #31)
   - Any remaining Integration Management bugs
   - DP edit modal improvements

4. **Website update** (0.5 day)
   - Security/compliance page (content from security posture doc)
   - Pricing page refresh
   - Knowledge conference landing page?

5. **SSO assessment** (decision point)
   - If identity/security rewrite done: attempt SSO (7-8 days — probably too late)
   - If not: formally defer to Q2, document plan

6. **Q1 review + Q2 planning** (0.5 day)

---

## Updated Q1 Success Criteria

### Operations
- ✅ Delta 100% independent (Namespace UI)
- ✅ Platform admin tools complete
- ⬜ Garland import complete (363 apps)
- ⬜ Power BI views deployed

### Enterprise Credibility
- ✅ Multi-region architecture ready
- ✅ SOC2 audit logging operational (72 tables, 17 triggers)
- ✅ Security Posture document for prospects
- ✅ Google OAuth live
- ⬜ Website professionally updated
- ⬜ Microsoft OAuth publisher verification (cosmetic — works without it)
- ⬜ Entra ID SSO → **LIKELY DEFERRED TO Q2**

### Knowledge Conference Demo (May 2026)
- ⬜ **Technology Health Dashboard live** (lifecycle risk, blast radius)
- ⬜ **IT Value Creation live** (findings, initiatives, roadmap)
- ⬜ **Lifecycle badges on deployment profiles**
- ⬜ **Auto-generated findings from lifecycle data**
- ⬜ Power BI demo with Garland data
- ⬜ Demo script tested and polished

### Competitive Differentiation
- ✅ Integration Management shipped
- ⬜ **Technology Health — no competitor has this at our price point**
- ⬜ IT Value Creation — "So What?" answer
- ⬜ Two-path technology model — crawl-to-walk story
- 🟡 Gamification designed (architecture complete, implementation Q2)

### Market Positioning
- ✅ "Canadian data sovereignty" positioned
- ✅ "Multi-region data residency" positioned
- ⬜ **"QuickBooks for CSDM" messaging live with Technology Health proof**
- ⬜ **Crawl-to-walk positioning validated at Knowledge**

---

## Items Deferred from v1.3 → Q2

| Item | v1.3 Status | v1.4 Decision | Rationale |
|------|-------------|---------------|-----------|
| SSO (Entra ID) | Week 4-5 option | **Deferred Q2** | Identity/Security rewrite not started. Knowledge doesn't need SSO to demo. |
| Identity/Security rewrite v2.0 | Week 1-2 (1.8.3) | **Deferred Q2** | Only needed for SSO. Not blocking any Q1 deliverable. |
| Architecture doc cleanup (12 AWS refs) | Week 1-2 (1.8) | **Deferred Q2** | Cosmetic. Doesn't affect demos, doesn't block features. |
| Gamification implementation | Not in v1.3 | **Deferred Q2** | Architecture complete (v1.2). Phase 1 is 2-3 days — do early Q2. |
| Composite Applications | Q2 (unchanged) | **Still Q2** | Schema risk unchanged. |

---

## Items Pulled Forward from Q2

| Item | v1.3 Status | v1.4 Decision | Rationale |
|------|-------------|---------------|-----------|
| Technology Health Dashboard | Q2 deferred | **Week 4-5 (implement)** | #1 Knowledge demo feature. Architecture complete. Customer-validated. |
| Lifecycle Intelligence | Q2 deferred | **Week 4 (partial)** | Lifecycle badges + reference seeding. Full AI lookup still Q2. |
| Infrastructure Boundary Rubric | Not planned | **Complete (architecture)** | Needed for Garland import. Informs all future customer onboarding. |

---

## Risk Register (Updated)

| Risk | Probability | Impact | Severity | Mitigation | Owner |
|------|-------------|--------|----------|------------|-------|
| Tech Health Dashboard takes >8 days | Medium | High | 🟡 MEDIUM | Schema is simple (column adds, not new tables). Views are straightforward. UI is AG work. | Stuart |
| IT Value Creation squeezed by Tech Health | Medium | Medium | 🟡 MEDIUM | IT Value Creation schema is ready (v1.0). If UI slips, ship schema + basic list views. | Stuart |
| Knowledge demo not compelling enough | Low | High | 🟡 MEDIUM | Two demo paths: Riverside (curated 56 apps) + Garland (real 363 apps). Both cover the story. | Stuart |
| ~~SSO takes >7 days~~ | ~~Medium~~ | ~~High~~ | Deferred | SSO moved to Q2. No longer a Q1 risk. | Stuart |
| Foundation items never get done | Medium | Medium | 🟡 MEDIUM | Week 3 dedicated to catchup. Power BI and bug fixes are bounded (hours not days). | Stuart |
| Architecture debt > implementation capacity | High | Medium | 🟡 NEW | 35 days designed, ~15 days to build. Accept that Gamification is Q2. Tech Health + IT Value Creation is the Q1 goal. | Stuart |
| Garland import blocked by mapping | Low | Medium | 🟢 LOW | Delta mapping flexible timeline. Import is 2-3 days when ready. Can demo with Riverside if needed. | Delta |
| Delta SOC2 policies late (3 HIGH due Feb 27) | Medium | Medium | 🟡 MEDIUM | Delta has 6-8 hrs of work. Templates provided. Stuart can review quickly. | Delta |

---

## Predecessor / Dependency Map (Updated)

```
COMPLETED (Feb 7-14):
  ✅ Phase 25.9-25.10 (RLS, Schema, Multi-Region) ─────────────────────┐
  ✅ Phase 28: Integration Management ──────────────────────────────────┤
  ✅ Quality Infrastructure (validation, audit, checklist) ─────────────┤
  ✅ Google OAuth ──────────────────────────────────────────────────────┤
  ✅ Nested Portfolio UI ──────────────────────────────────────────────┤
  ✅ Architecture Sprint (12 new docs, 3 principles) ──────────────────┤
  ✅ Gamification Architecture v1.2 (DESIGNED, not built) ─────────────┤
  ✅ Technology Health Dashboard Architecture (DESIGNED, not built) ────┤
  ✅ Infrastructure Boundary Rubric + Lifecycle Intelligence v1.1 ─────┤
                                                                       │
WEEK 3 — FOUNDATION CATCHUP (Feb 17-21):                              │
  Power BI Foundation (deploy views) ◄─────────────────────────────────┘
  Delta Training (Namespace UI)
  Phase 28 Bug Fixes (AG)
  Dependabot Enable
  Website Update (AG)
       │
WEEK 4 — TECH HEALTH SCHEMA (Feb 24-28):                 
  Technology Health Schema Deployment ◄────────────────────┘
       │
  Lifecycle Reference Seeding ◄────────┘
       │
  Database Views (4) ◄────────────────┘
       │
  Lifecycle Badges on DP ◄────────────┘
       │
  Demo Data (Riverside) ◄─────────────┘
       │
  Garland Import (when Delta ready) ───── (parallel, flexible)
       │
WEEK 5 — TECH HEALTH UI + IT VALUE CREATION START (Mar 3-7):
  Technology Health Dashboard UI (AG) ◄────┘
       │
  IT Value Creation Schema ◄───────────────┘ (parallel with AG)
       │
  Auto-generate Lifecycle Findings ◄───────┘
       │
WEEK 6 — IT VALUE CREATION UI (Mar 10-14):
  Findings List View (AG) ◄────────────────┘
  Initiatives + Kanban (AG) ◄──────────────┘
  Roadmap Timeline View (AG) ◄─────────────┘
       │
WEEK 7-8 — POLISH + KNOWLEDGE PREP (Mar 17-31):
  Knowledge Demo Script ◄──────────────────┘
  Power BI Garland Demo
  UI Consistency Pass (AG)
  Website Update
  Q1 Review + Q2 Planning
```

**Critical Path:** Technology Health Schema → Views → UI → IT Value Creation Schema → Findings → Knowledge Demo

**No longer on critical path:** SSO, Identity/Security rewrite, Architecture doc cleanup

---

## Resource Allocation (Updated)

### Stuart's Time Allocation

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 3 (Feb 17-21) | Foundation catchup (PBI, Delta, Dependabot) | 2-3 days | PRIMARY |
| 3 | SSO decision + identity/security assessment | 0.5 day | SECONDARY |
| 4 (Feb 24-28) | Tech Health schema + views + lifecycle seeding | 3-4 days | PRIMARY |
| 4 | Garland import (if Delta ready) | 1-2 days | PARALLEL |
| 5 (Mar 3-7) | IT Value Creation schema + lifecycle pipeline | 2-3 days | PRIMARY |
| 6 (Mar 10-14) | IT Value Creation testing + demo data | 1-2 days | PRIMARY |
| 7-8 (Mar 17-31) | Knowledge demo prep + polish + Q2 planning | 3-5 days | PRIMARY |

### AG (Antigravity) Usage

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 3 (Feb 17-21) | Phase 28 bug fixes (13 items) | 1-2 days | PRIMARY |
| 3 | Namespace UI polish + website update | 1 day | SECONDARY |
| 5 (Mar 3-7) | Technology Health Dashboard page | 2-3 days | PRIMARY |
| 6 (Mar 10-14) | IT Value Creation UI (findings, initiatives, roadmap) | 3-4 days | PRIMARY |
| 7-8 (Mar 17-31) | UI consistency pass + polish | 1-2 days | SECONDARY |

### Delta's Time Allocation

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 3 (Feb 17-21) | Garland mapping completion + Namespace UI training | 2-3 days | PRIMARY |
| 3 | SOC2 policies (3 HIGH — due Feb 27) | 6-8 hrs | PRIMARY |
| 4-5 | Garland import support + testing | 1-2 days | SECONDARY |
| 5-6 | SOC2 policies (2 MED — due Mar 6) | 3 hrs | SECONDARY |
| Ongoing | Customer success | Continuous | PRIMARY |

---

## Open Items Impact

The following open items from the priority matrix are affected by this resequencing:

| # | Item | v1.3 Timeline | v1.4 Timeline | Change |
|---|------|---------------|---------------|--------|
| 1 | Identity/Security rewrite | Week 1-2 | **Q2** | SSO deferred, rewrite not blocking |
| 8 | Doc cleanup (12 AWS refs) | Week 1-2 | **Q2** | Cosmetic, not blocking |
| 16 | Delta training on Namespace UI | Week 1-2 | **Week 3** | Slipped 1 week |
| 17 | Website update | Week 1-2 | **Week 3 or 7-8** | AG work, flexible |
| 18 | Power BI Foundation | Week 1-2 | **Week 3** | Slipped 1 week, still quick |

New items that should be added to the matrix:

| # | Category | Item | Priority | Notes |
|---|----------|------|----------|-------|
| 34 | Feature | Technology Health Dashboard implementation | HIGH | Week 4-5, Knowledge demo anchor |
| 35 | Feature | IT Value Creation implementation | HIGH | Week 5-6, "So What?" answer |
| 36 | Architecture | Lifecycle reference data seeding | MED | Prerequisite for Tech Health demo |
| 37 | Demo | Riverside technology tagging (demo data) | MED | Prerequisite for Tech Health demo |

---

## Q2 2026 Preview (Updated)

### Gamification Implementation (Early Q2)
- Architecture complete (v1.2 — 2,000+ lines, 7 phases)
- Phase 1: 2-3 days (schema + toast + dashboard widget)
- Phase 2: 2-3 days (achievement wall + flags UI)
- Targets: first customer deployment, not Knowledge
- **Total: ~12-15 days across Q2**

### SSO + Identity/Security Rewrite
- Identity/Security architecture v1.1 → v2.0 (Supabase Auth)
- Entra ID SSO implementation (7-8 days)
- Trigger: first enterprise customer requiring SSO
- **Total: ~10 days**

### Microsoft 365 Ecosystem (Enterprise Tier)
- Power Automate, Power Apps, SharePoint integration
- Trigger: first Enterprise customer on M365

### Technology Lifecycle Intelligence (Full)
- AI-powered EOL lookup via Claude API (Phase 27d-g)
- Architecture complete (v1.1). Manual seeding in Q1, AI in Q2.
- **Total: ~10 hrs remaining after Q1 seeding**

### Automation & Discovery
- Cloud Discovery (CSV → AWS → Azure/GCP)
- ServiceNow Publishing (CSDM export)

### Deferred (Unchanged)
- Composite Applications (schema risk)
- Budget Management (CFO tracking)
- AI Chat (natural language APM queries)
- Namespace Editor role activation

---

## The Knowledge Conference Story

**Audience:** ServiceNow Platform Owners stuck in CSDM crawl-to-walk

**Demo flow (10 minutes):**

1. **The Problem** (2 min)
   - "Your CMDB has 10,000 CIs from Discovery. Your cmdb_ci_business_app has 0."
   - "You extracted data into spreadsheets. Built Power BI dashboards. Maintain risk registers in SharePoint."
   - "93% of your risk entries are stuck in Draft."

2. **Import** (1 min)
   - Show Garland: 363 applications imported from their spreadsheet extract
   - "We took their existing data and had it live in days, not months."

3. **Technology Health** (3 min)
   - Technology Health Dashboard: lifecycle risk across the portfolio
   - Blast radius: "Click SQL Server 2016 — see every application affected"
   - Lifecycle badges: "This deployment is on Extended Support, EOL July 2026"
   - Crown Jewels: "These 5 apps are business-critical AND on end-of-life technology"

4. **So What?** (2 min)
   - Auto-generated findings: "12 deployments on EOL technology across 8 applications"
   - Initiative: "Database Platform Modernization — upgrade SQL Server 2016 to 2022"
   - Roadmap: strategic timeline showing sequenced initiatives

5. **The Pitch** (2 min)
   - "Your ServiceNow partner needs this data on day one. We're how it gets there."
   - "CSDM-aligned. Canadian data residency. 10% of ServiceNow APM cost."
   - "Import your spreadsheet once. You'll never need to extract it again."

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.4 | 2026-02-14 | **Major resequencing.** Architecture sprint (Feb 10-14) changed priorities: Technology Health Dashboard pulled from Q2 to Week 4-5 (most visual Knowledge demo feature). IT Value Creation moved from Week 3 to Week 5-6 (benefits from Tech Health data). SSO formally deferred to Q2 (identity rewrite not started, not blocking). Gamification implementation deferred to Q2 (architecture complete). Foundation Phase catchup moved to Week 3. Added Knowledge Conference Story section. Updated predecessor map, risk register, resource allocation. |
| v1.3 | 2026-02-09 | Integration Management shipped. IT Value Creation pulled forward. Quality infrastructure built. |
| v1.2 | 2026-02-08 | M365 ecosystem slotted. Power BI Foundation added. |
| v1.1 | 2026-02-08 | Phase 25.10 complete. Architecture audit. Multi-region DB. Identity/Security rewrite flagged. |
| v1.0 | 2026-02-07 | Initial Q1 2026 Master Plan. |

---

*Document: planning/q1-2026-master-plan.md*  
*February 2026*
