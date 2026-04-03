# ADR: Contract-Aware Cost Bundles

**Version:** 1.0
**Date:** April 3, 2026
**Status:** PROPOSED
**Author:** Stuart Holtby + Claude
**Relates to:**
- `adr/adr-cost-model-reunification.md` (v1.0) — IT Services absorb contract role
- `features/cost-budget/cost-model.md` (v3.0) — two-channel cost model
- `features/cost-budget/software-contract.md` (v2.0) — contract lifecycle tracking
- `features/cost-budget/cost-model-validation-2026-03-04.md` — legacy field audit
- `adr/adr-csdm-export-readiness.md` (v1.0) — CSDM export mapping
- `features/integrations/servicenow-alignment.md` (v1.2) — ProductContract sync rules

---

## 1. Context

### The Question That Exposed the Gap

"If we want to list all contract renewals happening in the next 18 months, where do we find them?"

The answer today: contract dates live on `it_services` (4 columns added by the cost model reunification). But querying "which applications have expiring contracts" requires joining through IT Service allocations — and most customers haven't created IT Services yet. All 26 IT Services in production have `contract_end_date = NULL`.

More fundamentally: a customer who wants to say **"I pay Microsoft $50K/year for Dynamics, the contract expires March 2027"** must first understand and create an IT Service, link software products to it, set up allocation values, and configure the cost pool. That's ITSM-mature thinking. It's not QuickBooks.

### The History

The original architecture included `ProductContract` as a first-class entity — a commercial agreement linked to deployment profiles. It was killed (January 2026, v2.5 fork) because it would have introduced a third budget track. The budget management system was being built concurrently for two tracks (application budgets + IT service budgets), and a third track would have required rewriting `vw_workspace_budget_summary`, `vw_budget_status`, `vw_budget_alerts`, and the entire BudgetSettings UI.

The cost model reunification (March 4, 2026) correctly consolidated cost allocation onto IT Services, but in doing so it also consolidated **contract awareness** onto IT Services. These are different concerns:

1. **"How do we calculate what this application costs?"** — IT Service allocation model. Correct. Works.
2. **"When does this application's contract expire?"** — Doesn't require allocation machinery. Just needs a date, a vendor, and a PO#.

The reunification conflated the two, creating a maturity wall: you can't know when your contracts expire unless you've set up IT Services.

### The Cost Bundle Opportunity

Cost Bundles (`dp_type = 'cost_bundle'`) were designed for the Day 1 customer — "just enter a number." They already:
- Flow into dashboard cost calculations (via `vw_deployment_profile_costs`)
- Support vendor attribution (`vendor_org_id` already exists on `deployment_profiles`)
- Appear in `vw_run_rate_by_vendor` (Cost Bundle UNION leg)
- Are part of the budget math (no changes needed)

But they have no contract awareness — no PO#, no expiry date, no renewal tracking. Adding three columns gives Cost Bundles the commercial awareness that customers need on Day 1, without touching the cost calculation machinery.

---

## 2. Decision

**Enrich Cost Bundles with contract awareness fields.** Three new nullable columns on `deployment_profiles` (meaningful only for `dp_type = 'cost_bundle'`):

- `contract_reference` — PO#, agreement ID, or contract reference
- `contract_start_date` / `contract_end_date` — contract lifecycle
- `renewal_notice_days` — alert threshold (default 90)

These mirror the same columns already on `it_services`, creating a consistent contract vocabulary across both maturity levels.

**Cost Bundles are NOT a new cost channel.** They are already part of the existing two-channel model. This ADR adds commercial metadata to an existing cost source — no budget math changes, no third budget track, no view rewrites.

**IT Services remain the mature path** for allocated costs, shared contracts, and stranded cost visibility. Cost Bundles are the on-ramp.

---

## 3. The Maturity Graduation Model

This design creates a natural customer journey from simple to sophisticated:

### Level 1: "I don't know my costs"

No Cost Bundles, no IT Services. TIME/PAID assessment works without cost data. Contract expiry dashboard shows nothing — and that's fine.

### Level 2: "I roughly know what I pay"

Customer creates a Cost Bundle:
- Name: "Dynamics 365 License"
- Annual Cost: $50,000
- Vendor: Microsoft
- Contract Reference: EA-12345
- Contract End Date: 2027-03-31
- Renewal Notice: 90 days

Result: $50,000 shows on the application dashboard. Contract appears on the expiry widget. One entity, one step. QuickBooks simple.

### Level 3: "I need to allocate shared contracts"

Customer graduates to IT Services:
- Creates "Microsoft Dynamics EA" IT Service with $240K cost pool
- Allocates across 5 DPs using fixed or percentage allocation
- IT Service carries the same contract fields (reference, dates, renewal)
- UX warning prompts cleanup of the old Cost Bundle (see §6)

Result: Full allocation, stranded cost visibility, budget alerts. The Cost Bundle is no longer needed and can be deleted or zeroed out.

### Level 4: "I need to publish to ServiceNow"

IT Services with teams (per CSDM Export Readiness ADR), integrations at DP level (per Integration-DP ADR), and CSDM export. Everything's already in the right place.

**Each level builds on the last. No rip-and-replace. No "you did it wrong, start over."**

---

## 4. Schema Changes

### 4.1 New Columns on `deployment_profiles`

```sql
ALTER TABLE deployment_profiles
  ADD COLUMN contract_reference text,
  ADD COLUMN contract_start_date date,
  ADD COLUMN contract_end_date date,
  ADD COLUMN renewal_notice_days integer DEFAULT 90;

CREATE INDEX idx_dp_contract_end
  ON deployment_profiles(contract_end_date)
  WHERE contract_end_date IS NOT NULL
    AND dp_type = 'cost_bundle';

COMMENT ON COLUMN deployment_profiles.contract_reference
  IS 'PO number, agreement ID, or contract reference. Primarily for cost_bundle DPs.';
COMMENT ON COLUMN deployment_profiles.contract_start_date
  IS 'When the contract term begins. Primarily for cost_bundle DPs.';
COMMENT ON COLUMN deployment_profiles.contract_end_date
  IS 'When the contract term expires. Used for renewal alerts. Primarily for cost_bundle DPs.';
COMMENT ON COLUMN deployment_profiles.renewal_notice_days
  IS 'Days before contract_end_date to trigger renewal alert. Default 90. Primarily for cost_bundle DPs.';
```

**Why nullable:** These columns are optional. A Cost Bundle without contract dates is still valid — it just doesn't appear in contract expiry reporting.

**Why on `deployment_profiles` and not a separate table:** Cost Bundles ARE deployment profiles (`dp_type = 'cost_bundle'`). The columns sit alongside `vendor_org_id` which already exists for this purpose. No new table, no new junction, no new RLS policy.

**Existing column:** `deployment_profiles.vendor_org_id` already exists with FK to `organizations`, index (`idx_dp_vendor`), and comment: "Vendor for cost bundles (support contracts, misc costs)." No change needed.

### 4.2 New View: `vw_contract_expiry` (UNION — replaces `vw_it_service_contract_expiry`)

This view unifies contract expiry data from both sources: IT Services (mature path) and Cost Bundles (simple path). One widget, two sources, complete picture regardless of customer maturity level.

```sql
CREATE OR REPLACE VIEW vw_contract_expiry WITH (security_invoker = true) AS

-- IT Service contracts (mature path)
SELECT
  'it_service'::text AS source_type,
  its.id AS source_id,
  its.name AS source_name,
  its.namespace_id,
  its.owner_workspace_id AS workspace_id,
  NULL::uuid AS application_id,
  NULL::text AS application_name,
  its.vendor_org_id,
  o.name AS vendor_name,
  its.contract_reference,
  its.contract_start_date,
  its.contract_end_date,
  its.renewal_notice_days,
  its.annual_cost,
  CASE
    WHEN its.contract_end_date IS NULL THEN NULL
    ELSE its.contract_end_date - CURRENT_DATE
  END AS days_until_expiry,
  CASE
    WHEN its.contract_end_date IS NULL THEN 'no_contract'
    WHEN its.contract_end_date < CURRENT_DATE THEN 'expired'
    WHEN its.contract_end_date <= CURRENT_DATE
      + (COALESCE(its.renewal_notice_days, 90) || ' days')::interval
      THEN 'renewal_due'
    WHEN its.contract_end_date <= CURRENT_DATE + interval '180 days'
      THEN 'expiring_soon'
    ELSE 'active'
  END AS status
FROM it_services its
LEFT JOIN organizations o ON o.id = its.vendor_org_id
WHERE its.contract_end_date IS NOT NULL

UNION ALL

-- Cost Bundle contracts (simple path)
SELECT
  'cost_bundle'::text AS source_type,
  dp.id AS source_id,
  dp.name AS source_name,
  w.namespace_id,
  dp.workspace_id,
  dp.application_id,
  a.name AS application_name,
  dp.vendor_org_id,
  o.name AS vendor_name,
  dp.contract_reference,
  dp.contract_start_date,
  dp.contract_end_date,
  dp.renewal_notice_days,
  dp.annual_cost,
  CASE
    WHEN dp.contract_end_date IS NULL THEN NULL
    ELSE dp.contract_end_date - CURRENT_DATE
  END AS days_until_expiry,
  CASE
    WHEN dp.contract_end_date IS NULL THEN 'no_contract'
    WHEN dp.contract_end_date < CURRENT_DATE THEN 'expired'
    WHEN dp.contract_end_date <= CURRENT_DATE
      + (COALESCE(dp.renewal_notice_days, 90) || ' days')::interval
      THEN 'renewal_due'
    WHEN dp.contract_end_date <= CURRENT_DATE + interval '180 days'
      THEN 'expiring_soon'
    ELSE 'active'
  END AS status
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
LEFT JOIN applications a ON a.id = dp.application_id
LEFT JOIN organizations o ON o.id = dp.vendor_org_id
WHERE dp.dp_type = 'cost_bundle'
  AND dp.contract_end_date IS NOT NULL;
```

**Key design decisions:**
- `source_type` column distinguishes IT Service vs Cost Bundle origin
- Cost Bundle leg includes `application_id` and `application_name` — answering the original question: "which applications have expiring contracts?"
- IT Service leg does not include application_id (an IT Service may serve multiple applications — the join path is through dpis → dp → application, which is a reporting concern, not a view concern)
- `security_invoker = true` — inherits caller's RLS context
- Status buckets match the existing `vw_it_service_contract_expiry` logic for consistency

**Disposition of existing views:**
- `vw_it_service_contract_expiry` — DEPRECATED. Replaced by the IT Service leg of `vw_contract_expiry`. Keep until frontend consumers are migrated.
- `vw_software_contract_expiry` — already DEPRECATED by cost model reunification. No change.

### 4.3 GRANTs

```sql
GRANT SELECT ON vw_contract_expiry TO authenticated, service_role;
```

No new table grants needed — columns are added to `deployment_profiles` which already has full grants.

---

## 5. What Does NOT Change

This is critical. The power of this approach is how little it disrupts:

| Component | Change Required |
|---|---|
| `vw_deployment_profile_costs` | None — Cost Bundles already flow through this view |
| `vw_application_run_rate` | None — reads from `vw_deployment_profile_costs` |
| `vw_workspace_budget_summary` | None — budget math unchanged |
| `vw_budget_status` | None — budget tracks unchanged |
| `vw_budget_alerts` | None — alert logic unchanged |
| `vw_run_rate_by_vendor` | None — Cost Bundle UNION leg already reads `dp.vendor_org_id` |
| BudgetSettings.tsx | None — budget UI unchanged |
| Cost calculation views | None — no new cost channel |
| IT Service contract fields | None — remain for mature customers |
| IT Service allocation model | None — cost pool/allocation/stranded cost unchanged |

**Zero budget math changes. Zero cost channel changes. Zero view rewrites.**

---

## 6. Double-Count Prevention — UX Guardrails

The risk: a customer creates a Cost Bundle for "Dynamics 365 License — $50K" on Day 1, then on Day 90 creates an IT Service "Microsoft Dynamics EA — $50K" allocated to the same DP. The dashboard now shows $100K.

This is solved with contextual UX warnings, not data model constraints. Both scenarios are technically valid — a DP can legitimately have IT Service allocations (hosting) AND Cost Bundles (consulting). Blocking would break valid use cases.

### 6.1 Warning When Adding a Cost Bundle to a DP with IT Service Allocations

Triggered when: user creates a Cost Bundle on an application that already has IT Service allocations on any of its DPs.

```
┌─────────────────────────────────────────────────────┐
│ ⚠ This application already has IT Service costs     │
│                                                     │
│ "SAP Finance" receives costs from 2 IT Services     │
│ totalling $36,000/year. Adding a Cost Bundle may    │
│ duplicate costs already covered by those services.  │
│                                                     │
│ Common reasons to add a Cost Bundle anyway:         │
│  - One-time migration or consulting costs           │
│  - Support agreements not covered by IT Services    │
│  - Estimated costs while IT Services are set up     │
│                                                     │
│              [Add anyway]        [Cancel]            │
└─────────────────────────────────────────────────────┘
```

### 6.2 Prompt When Adding IT Service Allocation to a DP with Contract-Bearing Cost Bundles

Triggered when: user adds an IT Service allocation to a DP whose application has Cost Bundles with `contract_end_date IS NOT NULL` (i.e., contract-aware Cost Bundles, not plain cost entries).

```
┌─────────────────────────────────────────────────────┐
│ ℹ This application has Cost Bundles with contract   │
│   details                                           │
│                                                     │
│ "Dynamics 365 License" ($50,000/yr, expires         │
│  March 2027) may overlap with this IT Service.      │
│                                                     │
│ If this IT Service replaces that Cost Bundle,       │
│ consider removing it to avoid double-counting.      │
│                                                     │
│         [Continue]      [Review Cost Bundles]        │
└─────────────────────────────────────────────────────┘
```

"Review Cost Bundles" scrolls to / opens the Cost Bundle section of the Deployments & Costs tab.

### 6.3 Dashboard-Level Indicator (Future Enhancement)

A future enhancement could flag applications where both IT Service allocations and contract-bearing Cost Bundles coexist, surfacing a data quality indicator:

```
⚠ 3 applications may have overlapping cost sources
```

This is informational — it doesn't block anything. It nudges the customer to clean up as they mature. Not required for initial implementation.

---

## 7. CSDM Export Mapping

### 7.1 Cost Bundles with Contract Data → `ast_contract`

The CSDM Export Readiness ADR and ServiceNow alignment doc (§3.5) define the sync rules for contracts. Cost Bundles with contract fields map cleanly:

| Cost Bundle Field | ServiceNow `ast_contract` Field |
|---|---|
| `name` | `short_description` |
| `vendor_org_id` → `organizations.name` | `vendor` (→ `core_company.name`) |
| `contract_reference` | `contract_number` |
| `contract_start_date` | `starts` |
| `contract_end_date` | `ends` |
| `annual_cost` | `cost` |
| `application_id` → `applications.name` | Related CI (`cmdb_ci_business_app`) |

### 7.2 Internal Chargeback Rule

Per `servicenow-alignment.md` §3.5: contracts where the vendor is an internal organization (Central IT, another ministry) must NOT sync to `ast_contract`. They stay in GetInSync.

Detection: If `vendor_org_id` references an organization that is also a workspace owner within the same namespace, it's internal. The export engine checks this at publish time.

### 7.3 IT Service Contracts

No change. IT Services with contract fields continue to export as `ast_contract` linked to their Application Service CIs. The UNION view (`vw_contract_expiry`) is for internal reporting — the export engine queries each source independently for field-level mapping.

---

## 8. UI Changes

### 8.1 Cost Bundle Card — Contract Details Section

The existing Cost Bundle card on the Deployments & Costs tab gains an optional "Contract Details" section, collapsed by default:

```
┌───────────────────────────────────────────────────┐
│ Dynamics 365 License                          [✕] │
│ Cost Bundle                                       │
├───────────────────────────────────────────────────┤
│ Annual Cost: $50,000        Recurrence: Recurring │
│ Vendor: Microsoft                                 │
│                                                   │
│ ▸ Contract Details                                │
│                                                   │
│ [Expand reveals:]                                 │
│ ▾ Contract Details                                │
│ ┌───────────────────────────────────────────────┐ │
│ │ Reference:    EA-12345                        │ │
│ │ Start Date:   2024-04-01                      │ │
│ │ End Date:     2027-03-31                      │ │
│ │ Renewal Notice: 90 days                       │ │
│ └───────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘
```

### 8.2 Contract Expiry Dashboard Widget

The existing `ContractExpiryWidget.tsx` switches from querying `vw_it_service_contract_expiry` to `vw_contract_expiry`. The widget now shows contracts from both sources with a source indicator:

| Contract | Vendor | Expires | Source |
|---|---|---|---|
| Dynamics 365 License | Microsoft | 2027-03-31 | Cost Bundle |
| Azure Hosting EA | Microsoft | 2026-12-01 | IT Service |
| SAP Support Agreement | SAP | 2026-09-15 | Cost Bundle |

The "Source" column helps mature customers identify Cost Bundles that should graduate to IT Services.

### 8.3 Contract Expiry Report (18-Month View)

The original question — "list all applications with contract renewals in the next 18 months" — is now answerable:

```sql
SELECT
  application_name,
  source_name AS contract_name,
  source_type,
  vendor_name,
  contract_reference,
  contract_end_date,
  days_until_expiry,
  annual_cost,
  status
FROM vw_contract_expiry
WHERE contract_end_date BETWEEN CURRENT_DATE
  AND CURRENT_DATE + interval '18 months'
ORDER BY contract_end_date;
```

This returns contracts from both Cost Bundles (with direct `application_id`) and IT Services. For IT Services, a separate join through `dpis → dp → application` provides the application linkage at the reporting layer.

---

## 9. The Multi-Application Contract Question

**Concern:** A single EA covers 5 applications. With Cost Bundles (per-DP), you'd duplicate the contract reference across 5 Cost Bundles.

**Answer:** This is the graduation signal. When a customer has the same `contract_reference` on multiple Cost Bundles, that's the moment IT Services make sense — one IT Service, one contract, allocated to 5 DPs.

The duplicate contract reference is not a data integrity problem — it's a **maturity indicator**. A future enhancement could detect this and prompt:

```
ℹ "EA-12345" appears on 4 Cost Bundles totalling $180,000.
  An IT Service with allocations may be a better fit.
  [Learn more]
```

This is not required for initial implementation. It's a data quality nudge, not a constraint.

---

## 10. Impact on Existing Architecture

### 10.1 Cost Model Reunification ADR

No conflict. The reunification decided that IT Services are the cost/contract layer for **allocated, shared costs**. This ADR adds contract awareness to Cost Bundles for **simple, direct costs**. The cost calculation path is unchanged.

The reunification ADR's §7 trade-off — "Simple 'link a product and it has a cost' UX → Users now create an IT Service for contracted software" — is addressed. Cost Bundles are the simple path; IT Services are the mature path.

### 10.2 Software Contract Doc (v2.0)

Section 7 (Contract Expiry Reporting) needs updating to reference `vw_contract_expiry` instead of `vw_it_service_contract_expiry`. The dashboard widget section is updated to show both sources.

### 10.3 CSDM Export Readiness ADR

Add Cost Bundles with contract data as a source for `ast_contract` export. The internal chargeback rule applies equally to Cost Bundle vendors.

### 10.4 Cost Model Doc (v3.0)

Section 3.3 (Cost Bundle DP) needs updating to document the contract fields. Add a note that Cost Bundles can now carry commercial awareness (vendor, contract dates) for Day 1 customers.

---

## 11. Implementation Sequence

| Phase | Work | Estimate | Dependencies |
|---|---|---|---|
| 1 | Schema: 4 columns on `deployment_profiles` + index | 30 min | None (Stuart — SQL Editor) |
| 2 | Schema: `vw_contract_expiry` UNION view + grants | 30 min | Phase 1 (Stuart — SQL Editor) |
| 3 | UI: Contract details section on Cost Bundle card | 2 hours | Phase 1 (Claude Code) |
| 4 | UI: Update ContractExpiryWidget to use `vw_contract_expiry` | 1 hour | Phase 2 (Claude Code) |
| 5 | UI: Double-count warning in Add Cost Bundle / Add IT Service modals | 2 hours | Phase 3 (Claude Code) |
| 6 | Docs: Update software-contract.md, cost-model.md, MANIFEST.md | 1 hour | Phase 4 (Claude Code) |

**Total: ~7 hours across 2 sessions (1 DB session + 1 frontend session).**

Phases 1-2 can ship as a single DB session. Phases 3-6 as a single frontend session.

---

## 12. pgTAP Assertions to Add

```sql
-- Contract columns exist on deployment_profiles
SELECT has_column('public', 'deployment_profiles', 'contract_reference');
SELECT has_column('public', 'deployment_profiles', 'contract_start_date');
SELECT has_column('public', 'deployment_profiles', 'contract_end_date');
SELECT has_column('public', 'deployment_profiles', 'renewal_notice_days');

-- Contract expiry view exists
SELECT has_view('public', 'vw_contract_expiry');

-- View returns expected columns
SELECT has_column('public', 'vw_contract_expiry', 'source_type');
SELECT has_column('public', 'vw_contract_expiry', 'application_name');
SELECT has_column('public', 'vw_contract_expiry', 'days_until_expiry');
SELECT has_column('public', 'vw_contract_expiry', 'status');

-- Grants
SELECT table_privs_are('public', 'vw_contract_expiry', 'authenticated', ARRAY['SELECT']);
```

---

## 13. Documents to Update After Implementation

| Document | Update Required |
|---|---|
| `features/cost-budget/software-contract.md` | §7: contract expiry reporting uses `vw_contract_expiry`. Dashboard widget shows both sources. |
| `features/cost-budget/cost-model.md` | §3.3: Cost Bundles can carry contract fields. Add maturity graduation note. |
| `features/integrations/servicenow-alignment.md` | §3.5: Cost Bundles with vendor contracts export to `ast_contract`. |
| `adr/adr-csdm-export-readiness.md` | Add Cost Bundle contract export to Phase 7-8 scope. |
| `MANIFEST.md` | Add this ADR, bump version. |
| `testing/pgtap-rls-coverage.sql` | Add assertions per §12. |
| `guides/whats-new.md` | Append entry for contract-aware Cost Bundles. |

---

## 14. Risks

| Risk | Mitigation |
|---|---|
| Double-counting (Cost Bundle + IT Service for same cost) | UX warnings at creation time (§6). Source column on expiry widget. Future: data quality indicator. |
| Duplicate contract references across Cost Bundles | Not a data error — it's a maturity signal. Future nudge to consolidate into IT Service. |
| Customer confusion about when to use Cost Bundle vs IT Service | Maturity model documented (§3). Tooltips in UI. Help article update. |
| Contract columns used on non-cost-bundle DPs | Columns are technically on all DPs but UI only surfaces them for `dp_type = 'cost_bundle'`. Comments note "Primarily for cost_bundle DPs." |
| Migration from Cost Bundle to IT Service loses contract history | Contract fields are independent — customer can set up IT Service first, verify, then delete Cost Bundle. No automated migration needed. |

---

## 15. Why Not a Separate `contracts` Table?

This was considered and rejected for the initial implementation. A separate table would:
1. Require a many-to-many junction to deployment profiles (new table, RLS, audit)
2. NOT be a cost channel — so the contract's `total_value` wouldn't appear on dashboards without additional view changes
3. OR be a cost channel — creating the third budget track that killed ProductContract
4. Add schema complexity for a problem that Cost Bundles already solve

A separate `contracts` table may make sense in the future if customers need:
- One contract entity covering 20+ applications (beyond the Cost Bundle duplication tolerance)
- Contract lifecycle workflows (approval, negotiation status, amendment tracking)
- Full SAM-level contract management

At that point, the contract table would reference IT Services (`contract_id` FK on `it_services`) and the contract fields on both `deployment_profiles` and `it_services` would become derived. But that's a future concern — the enriched Cost Bundle is the right 80/20 answer today.

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-04-03 | Initial ADR — contract-aware Cost Bundles, UNION expiry view, double-count guardrails, maturity graduation model |
