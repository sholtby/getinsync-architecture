# GitBook Rollout — Phase 0 Readiness Report

**Parent plan:** [gitbook-complete-rollout-plan.md](gitbook-complete-rollout-plan.md) §4
**Date:** 2026-04-10
**Status:** Complete — **4 READY, 4 NEEDS ENRICHMENT** (none blocking; enrichment tasks listed below)
**Namespace walked:** City of Riverside (`city-of-riverside-demo`, id `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
**Method:** Read-only DB queries via `DATABASE_READONLY_URL` + Chrome MCP spot checks. No UI mutations.

---

## Summary

| # | Article | Status | One-line |
|---|---------|--------|----------|
| 3.5 | Overview Dashboard prereq (≥2 workspaces) | ✅ READY | 10 workspaces visible in overview, 18 in DB |
| 1.4 | Deployment Profiles | ✅ READY | Accela Civic Platform DP has hosting/env/DR populated |
| 2.1 | Managing Applications | 🟡 NEEDS ENRICHMENT | 32 apps but **zero contacts** at any level |
| 2.2 | Importing Applications | ✅ READY | UI has built-in "Download Template" button |
| 2.4 | Integrations (DP-aligned) | 🟡 NEEDS ENRICHMENT | 9 integrations but only 1 with both DPs aligned |
| 4.1 | Roadmap Initiatives | ✅ READY | 6 initiatives, 5 with linked DPs, all with dates |
| 4.2 | IT Spend (budgets) | 🟡 PARTIALLY READY | Only 2 of 18 workspaces have budgets |
| 4.3 | Cost Analysis (channels) | 🟡 NEEDS ENRICHMENT | $2.98M in IT services but **zero contract data** |

**Blocking items:** none — all tiers can proceed. Articles marked NEEDS ENRICHMENT can either (a) wait for Stuart to seed the gap before their tier kicks off, or (b) publish with a narrower scope that matches current data.

---

## 3.5 Overview Dashboard prereq — ≥2 workspaces

**Status:** ✅ READY

- Overview dashboard renders "All of My Workspaces — across 10 workspaces" (visible in screenshot, Stuart's session).
- DB shows 18 workspaces in the Riverside namespace; the 10 visible are the role-filtered subset.
- `count(*) FROM workspaces WHERE namespace_id = riverside = 18`
- KPI cards render: At Risk 0, Applications 32, Fully Assessed 8, Crown Jewels 5, Annual Run Rate $3.0M.

**Action:** none.

---

## 1.4 Deployment Profiles

**Status:** ✅ READY — with a caveat

**Recommended DP for the article screenshot:** **`Accela Civic Platform - PROD - CA`** in the **Development Services** workspace.

Populated fields:

| Field | Value |
|-------|-------|
| hosting_type | SaaS |
| environment | PROD |
| dr_status | vendor_managed |
| tech_assessment_status | not_started |

**Caveat — operational fields still empty across Riverside:**

- `data_center_id` (no DPs have one) — expected for SaaS, but on-prem DPs also blank
- `server_name` (empty on all DPs)
- `support_team_id` / `change_team_id` / `managing_team_id` (empty on all DPs)
- `contract_reference` (empty on all DPs)

**Recommendation:** Write the 1.4 article using a SaaS DP example (Accela is ideal) and describe on-prem fields briefly in text. If Stuart wants the article to showcase on-prem operational depth, he would need to enrich one on-prem DP (e.g. `Computer-Aided Dispatch - PROD - CHDC`) with data_center_id + server_name + team IDs before Phase 1.

**Also ready as fallback DPs** (4 ops fields filled, ready for comparison shots):

- Computer-Aided Dispatch - PROD - CHDC (On-Prem, PROD)
- Hexagon OnCall CAD/RMS - PROD - CA (On-Prem, PROD)
- Emergency Response System - PROD - Hybrid (Hybrid, PROD)
- SirsiDynix Symphony - PROD - CHDC (On-Prem, PROD)

---

## 2.1 Managing Applications

**Status:** 🟡 NEEDS ENRICHMENT

**Recommended app for the article walkthrough:** **Computer-Aided Dispatch**, **Hexagon OnCall CAD/RMS**, or **NG911 System** (all in Police Department workspace, all Mainstream lifecycle, all with 2 DPs and complete tech assessment).

**What's present on every Riverside app:**

- `name`, `description` (>20 chars), `lifecycle_status` = Mainstream
- 1-2 deployment profiles per app
- Workspace assignment

**What's missing on every Riverside app:**

| Data | Status | Impact |
|------|--------|--------|
| `application_contacts` (junction) | 0 rows across all 32 apps | Contacts section renders empty |
| `deployment_profile_contacts` | 0 rows | Per-DP contacts section empty |
| `workspace_contacts` | 0 rows | Workspace-level contacts empty |
| `owner` text field | 0 apps populated | "Owner" badge shows "—" |
| `primary_support` text field | 0 apps populated | Support badge shows "—" |
| `expert_contacts` text field | 0 apps populated | Expert contact list empty |
| `primary_use_case` | 0 apps populated | Use case field empty |

(The `contacts` master table has 7 contacts in the Riverside namespace but none are attached to any application, DP, or workspace.)

**Enrichment task for Stuart (Phase 1):**

Attach at least 2 contacts to **Computer-Aided Dispatch** (or another nominated "showcase" app) via the app detail page → Contacts section, **before** Phase 2 (Tier 2) kicks off. A showcase app with populated `owner`, `primary_support`, and 2-3 involved parties would give the 2.1 article a realistic Contacts section to screenshot.

Alternative: Phase 2 writer can publish 2.1 with a note that Contacts is documented but not screenshotted in the demo data. Lower fidelity but unblocked.

---

## 2.2 Importing Applications

**Status:** ✅ READY — no enrichment needed

**What exists:**

- Import wizard at `src/pages/settings/import/useImportWizard.ts` has a built-in `handleDownloadTemplate` function that generates `getinsync-import-template.csv` at runtime.
- The template includes headers + instructional comment lines + valid-value hints.
- Stuart's `~/Downloads/getinsync-import-template.csv` (Apr 9, 914 bytes) is almost certainly from a prior test — he can capture a fresh one by clicking "Download Template" in the wizard during the article walkthrough.

**Action:** none. Phase 2 writer captures the download at writing time.

---

## 2.4 Managing Integrations

**Status:** 🟡 NEEDS ENRICHMENT

**What exists:** 9 application integrations in Riverside.

| Integration | Source → Target | Method | DP-aligned? |
|-------------|-----------------|--------|-------------|
| *(unnamed)* | ServiceNow ITSM → Active Directory Services | api | ✅ both |
| Dynamics GP ↔ Cayenta GL Sync | Microsoft Dynamics GP → Cayenta Financials | database | ❌ neither |
| Emergency Response ↔ CAD | Emergency Response System → Computer-Aided Dispatch | api | ❌ |
| Flock ALPR → Hexagon RMS | Hexagon OnCall CAD/RMS → Flock Safety LPR | api | ❌ |
| Hexagon → Axon Evidence | Hexagon OnCall CAD/RMS → Axon Evidence | api | ❌ |
| Hexagon ↔ CAD Dispatch | Hexagon OnCall CAD/RMS → Computer-Aided Dispatch | api | ❌ |
| NG911 → CAD Call Routing | NG911 System → Computer-Aided Dispatch | api | ❌ |
| ServiceDesk ← Active Directory SSO | ServiceDesk Plus → Active Directory Services | sso | ❌ |
| Workday → Dynamics GP Payroll | Workday HCM → Microsoft Dynamics GP | file | ❌ |

**Gap:** Article 2.4 is a refresh specifically to document the **Phase 2 DP-aligned integrations** feature (`source_deployment_profile_id` / `target_deployment_profile_id` FKs shipped Mar 2026). Currently, only 1 of 9 integrations has both DPs set, and that row has no `name` — so it reads poorly in a screenshot.

**Enrichment task for Stuart (before Phase 2):**

1. Give a name to the ServiceNow ITSM → Active Directory Services row (e.g. "ServiceNow CMDB Sync")
2. Add DP alignment (source + target deployment profile) to **≥2 more** integrations — ideally:
   - **Emergency Response ↔ CAD** (already shows a clear paired relationship)
   - **NG911 → CAD Call Routing** (single direction, good for showing one-way DP flow)
3. After enrichment: ≥3 integrations with DP alignment is plenty for a walkthrough and comparison screenshots.

---

## 4.1 Roadmap Initiatives

**Status:** ✅ READY

**6 initiatives** in Riverside, all with target dates and diverse statuses (in_progress, planned, identified).

| Title | Status | Start → End | Linked DPs |
|-------|--------|-------------|------------|
| Implement Vulnerability Management Program | in_progress | 2026-03-01 → 2026-06-30 | 1 |
| Migrate SQL Server 2016 to 2022 | planned | 2026-04-01 → 2026-06-30 | 3 |
| ERP Evaluation and Replacement | planned | 2026-06-01 → 2027-06-30 | 2 |
| Upgrade SirsiDynix Symphony Infrastructure | planned | 2026-07-01 → 2026-09-30 | 2 |
| Establish IT Strategic Planning Process | identified | 2026-07-01 → 2026-12-31 | 0 |
| Plan Oracle 19c to 23ai Migration Path | identified | 2027-01-01 → 2027-12-31 | 1 |

All 6 have a linked IT service. 5 of 6 have linked deployment profiles. Status spread gives the Gantt/Kanban views varied content.

**Action:** none. Phase 4 writer has good material.

---

## 4.2 Understanding IT Spend

**Status:** 🟡 PARTIALLY READY

**What exists:**

- 2 workspaces with fiscal 2026 budgets in `workspace_budgets`:
  - Information Technology: $3,120,000
  - Police Department: $3,500,000
- 11 IT services all with `annual_cost` + `budget_amount` — total annual cost **$2,976,000** (matches the "$3.0M Annual Run Rate" KPI card on the overview dashboard)
- All 11 IT services have `budget_fiscal_year` set

**What's missing:**

- Only 2 of 18 workspaces have budgets — the IT Spend tab's workspace-by-workspace view will show budget data for 2 rows and empty rows for 16
- `actual_run_rate` column is NULL for both budget rows (the overview's run rate is computed from IT services, not from this column)

**Enrichment option (not required):**

Stuart could add fiscal 2026 budgets to 2-3 more workspaces (e.g. Fire Department, Public Works, Finance) to give the 4.2 article a richer workspace-comparison screenshot. Not blocking — the article can focus on IT and Police as the two fully-budgeted examples.

---

## 4.3 Cost Analysis & Run Rate

**Status:** 🟡 NEEDS ENRICHMENT

**What exists:**

- 11 IT services in Riverside with `annual_cost` totaling **$2,976,000**
- 17 software products in Riverside (linked to DPs via `deployment_profile_software_products`)
- Views `vw_deployment_profile_costs`, `vw_portfolio_costs`, `vw_portfolio_costs_rollup`, `vw_it_service_budget_status` all exist and should aggregate the $2.98M correctly

**What's missing:**

| Feature the article wants to show | Data state |
|-----------------------------------|------------|
| Contract references | 0 of 11 IT services have `contract_reference` |
| Contract expiry widget | 0 of 11 IT services have `contract_end_date` |
| Software product costs | 0 of 17 software products have `annual_cost` (cost lives only on IT services) |
| ~~"Cost bundles" panel~~ | ~~`cost_bundles` table **does not exist** in the schema (referenced in parent plan §4 but not implemented)~~ **[STRUCK — see Correction below]** |
| Recurring Costs / Cost Bundle DPs | **0 cost_bundle DPs** exist in Riverside (the CAD showcase app's "Recurring Costs" section reads $0 because no child cost_bundle DPs are linked) |

> **Correction (2026-04-10):** The struck row above is wrong. **Cost Bundle is not a separate table** — it is a deployment-profile type. `deployment_profiles.dp_type = 'cost_bundle'` is a fully-shipped feature with `annual_cost`, `cost_recurrence`, `vendor_org_id`, `contract_reference`, `contract_start_date`, `contract_end_date`, and `renewal_notice_days` columns, all commented as "Primarily for cost_bundle DPs" in the schema. Views `vw_portfolio_costs` / `vw_portfolio_costs_rollup` already aggregate `WHERE dp_type = 'cost_bundle' AND cost_recurrence = 'recurring'` into a `bundle_cost` column. The canonical definition is `docs-architecture/features/cost-budget/cost-model.md` §3.3. The original Phase 0 walk pattern-matched on "cost_bundles table" and missed the DP-type discriminator. The real enrichment need for Article 4.3 is to **seed cost_bundle DPs in the Riverside demo namespace** — zero exist today (confirmed via the CAD app's "Recurring Costs: $0" cost summary).

**Enrichment tasks for Stuart (before Phase 4):**

1. Add `contract_reference` + `contract_start_date` + `contract_end_date` to **≥3 IT services** so the IT-service contract expiry widget has content. Suggested: the three largest-cost services.
2. ~~Clarify with the 4.3 author that `cost_bundles` is not a real table — the "cost bundle" concept in the article needs to be reframed around `vw_portfolio_costs_rollup` or removed from the article scope.~~ **[STRUCK — the clarification was based on the wrong finding.]** Instead: **seed 2-3 `dp_type = 'cost_bundle'` deployment profiles** linked to the CAD / Hexagon / NG911 showcase apps, with realistic vendor, contract dates, and annual cost (e.g. "Accela Annual Support Contract", "Hexagon Managed Services Agreement", "Axon Evidence Cloud Hosting"). This gives Article 4.3 a real Recurring Costs + renewal-alert story on the showcase DPs.
3. Optional: populate `annual_cost` on a handful of software products if the article wants to show cost attribution at the software-product level rather than only IT-service level.

**Unblocking alternative:** Phase 4 writer can publish 4.3 focused entirely on IT-service-level costs + annual run rate calculation, and mention cost_bundle DPs as "coming soon when demo data is populated." But with enrichment task 2 done, Article 4.3 can cover the full three-channel story (Software Product inventory → IT Service cost pool → Cost Bundle DPs for everything else) that `cost-model.md` §3.3 and §12 already document.

---

## Bonus captures from Phase 0 (not in scope but noted)

- **`docs-architecture/planning/phase-0-assets/nextgen-nav.png`** — 2880×256 retina screenshot of the top nav (City of Riverside / Overview / Application Health / Technology Health / Roadmap / IT Spend / Explorer). **Held here, not yet moved into `guides/user-help/images/`** — per this session's decision, Phase 1 (Tier 1 writer) will move it when the 1.2 Navigating article is ready to publish. The file is at 2× retina, 70 KB PNG.

- **Overview dashboard KPIs as-of 2026-04-10** (Riverside, Stuart's view, all workspaces): At Risk 0, Applications 32, Fully Assessed 8 of 46 deployments, Crown Jewels 5 (criticality ≥50), Annual Run Rate $3.0M across 10 workspaces. Assessment Status: 8 assessed / 0 in progress / 38 not started (17% complete). TIME Analysis & PAID Analysis both show "8 apps plotted, 38 remaining".

- **Policy change committed this session:** `docs-architecture/CLAUDE.md` now carves out an exception for screenshots in `guides/user-help/images/` so the parent rollout plan can proceed. Pre-existing rule "no images in `guides/`" was stricter and would have blocked all screenshot use.

---

## Next steps (Phase 1 kickoff checklist)

Before Phase 1 (Tier 1 article writing) starts, Stuart should either (a) complete the enrichment tasks flagged above, or (b) explicitly accept the narrower article scopes. The tier phases do not need to run in strict order relative to enrichment — Tier 1 (articles 1.1-1.5) has **no data dependencies on the enrichment tasks** and can start immediately. The enrichment tasks only block Tiers 2 and 4.

**Tier 1 is fully unblocked** — it can run as soon as Stuart approves this report.

**Tiers 2 and 4** should wait on enrichment, or accept the narrower scopes documented above.

**Tier 3** (3.1-3.6, Assess & Analyze) is all marked "Yes" in the audit — not walked in Phase 0. Should be ready.

**Tier 5** (5.1 AI Assistant, 5.2 Global Search) is all marked "Yes" in the audit — not walked in Phase 0. Should be ready.
