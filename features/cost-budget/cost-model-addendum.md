# GetInSync — Cost Model Addendum (Technology Inventory Confirmation)

**Version:** 2.5.1 (Addendum to features/cost-budget/cost-model.md)  
**Date:** February 13, 2026  
**Status:** ✅ CONFIRMED — No changes to cost model

---

## 1. Purpose

This addendum confirms that the decision to retain `deployment_profile_technology_products` as a direct inventory tagging table (per features/technology-health/technology-stack-erd-addendum.md) has **zero impact** on the cost model architecture.

---

## 2. The Three Channels Are Unchanged

| Channel | Table | Cost Field | Purpose | Impact |
|---|---|---|---|---|
| **Software Product** | `deployment_profile_software_products` | `annual_cost` on junction + catalog | Licensing/subscription cost | None |
| **IT Service** | `deployment_profile_it_services` | `allocation_value` on junction, `annual_cost` pool on service | Infrastructure cost allocation | None |
| **Cost Bundle** | `deployment_profiles` (dp_type='cost_bundle') | `annual_cost` on DP | Everything else | None |

No fourth channel is created. The principle holds: **every dollar needs a home and an owner**, and that home is one of these three channels.

---

## 3. Why Technology Tagging Is Not a Cost Channel

`deployment_profile_technology_products` answers an **inventory** question ("what technology does this run on?"), not a cost question ("what does this technology cost?").

**Explicitly excluded from the junction:**
- `annual_cost`
- `allocation_value`
- `allocation_basis`
- `allocation_percent`
- Any field that could carry or imply a dollar amount

If a user wants to track what SQL Server costs, the answer is:

| Scenario | Correct Channel | How |
|---|---|---|
| SQL Server is managed by Central IT | IT Service | Create "Database Hosting" IT Service with $100K cost pool. Link DPs to it with allocation. |
| SQL Server license is a direct purchase | Software Product | If treated as installable software, track in Software Product catalog with `annual_cost`. |
| SQL Server cost is estimated/rough | Cost Bundle | Create Cost Bundle DP: "Database Infrastructure — $15K estimated." |
| User just knows "we run SQL Server" | No cost (yet) | Tag it on the DP. Lifecycle dashboard works. Cost attribution comes later. |

---

## 4. The "What Does SQL Server Cost Us?" Question

This is the one scenario that needs explicit design guidance.

### With IT Services (Level 3-4 maturity):

```sql
-- Total cost attributed to technology via IT Services
SELECT 
    tp.name AS technology,
    SUM(its.annual_cost) AS total_service_cost,
    COUNT(DISTINCT dpis.deployment_profile_id) AS consuming_dps
FROM it_service_technology_products istp
JOIN technology_products tp ON tp.id = istp.technology_product_id
JOIN it_services its ON its.id = istp.it_service_id
LEFT JOIN deployment_profile_it_services dpis ON dpis.it_service_id = its.id
GROUP BY tp.name;
```

This answers: "IT Services that run SQL Server have a combined cost pool of $X, consumed by Y deployments."

### Without IT Services (Level 1 maturity):

The system cannot answer "what does SQL Server cost?" because the user hasn't attributed cost to it. This is correct behavior — not a gap. The dashboard can show:

```
SQL Server 2019 — 15 deployments tagged
⚠️ No cost attribution. Add an IT Service or Cost Bundle to track costs.
```

### The Reconciliation Nudge

When technology is tagged directly (Path 1) AND an IT Service exists for it (Path 2), the system can surface the connection:

```
SQL Server 2019
├── 8 DPs linked via "Database Hosting" service → $65,000 allocated
├── 7 DPs tagged directly → no cost yet
└── [Link to existing service] or [Create Cost Bundle]
```

---

## 5. Cost Tracking Maturity (Unchanged — Reconfirmed)

The maturity levels from v2.5 Section 8 map cleanly to the two-path technology model:

| Level | Technology Tagging | Technology Costing |
|---|---|---|
| **0 — Not Tracked** | No tags | No cost |
| **1 — Estimated** | Direct tags on DPs | Cost Bundle: "Infra estimate $15K" |
| **2 — Categorized** | Direct tags on DPs | Software Product costs known; infra estimated via Cost Bundle |
| **3 — Attributed** | Direct tags + IT Service links | IT Service cost pools allocated to DPs |
| **4 — Allocated** | Reconciled (all direct tags covered by services) | Full chargeback with stranded cost visible |

The technology tag (Path 1) enables Levels 0-2 immediately. IT Services (Path 2) unlock Levels 3-4. The reconciliation view bridges them.

---

## 6. Design Constraint (Enforcement)

To prevent `deployment_profile_technology_products` from ever becoming a shadow cost channel:

1. **Schema:** No cost columns on the table. Period.
2. **UI:** No cost fields on the technology tagging dialog. Only: technology picker, version, notes.
3. **Views:** Cost rollup views (`vw_deployment_profile_costs`, `vw_application_run_rate`) must NOT join to `deployment_profile_technology_products`. They only use the three established channels.
4. **Code review flag:** Any PR adding a cost column to `deployment_profile_technology_products` should be rejected with reference to this document.

---

## 7. References

| Document | Relationship |
|---|---|
| `features/cost-budget/cost-model.md` | Parent document — unchanged |
| `features/technology-health/technology-stack-erd-addendum.md` | Companion — defines two-path model |
| `features/cost-budget/vendor-cost.md` | Unchanged — vendor attribution stays on cost channels |

---

## Change Log

| Version | Date | Changes |
|---|---|---|
| v2.5.1 | 2026-02-13 | Addendum confirming zero cost model impact from technology inventory decision. Enforcement constraints documented. |
