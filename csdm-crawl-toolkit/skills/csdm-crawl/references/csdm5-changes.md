# CSDM 5 Changes Relevant to Crawl

> CSDM 5 was released with ServiceNow Yokohama (2025). Changes are additive —
> nothing from CSDM 4 is broken. But naming and scope have shifted.

---

## Key renames

| CSDM 4 Term | CSDM 5 Term | Table (unchanged) |
|-------------|-------------|-------------------|
| Application Service | **Service Instance** | `cmdb_ci_service_auto` |
| Technical Service | **Technology Management Service** | `cmdb_ci_service` |
| Manage Technical Services (domain) | **Service Delivery** | — |
| — (new domain) | **Ideation & Strategy** | — |

**Critical point:** The table names did NOT change. `cmdb_ci_service_auto` is still
the table. "Service Instance" is a conceptual rename in the whitepaper and UI labels.
Your Import Sets, GlideRecord scripts, and Transform Maps still target `cmdb_ci_service_auto`.

## New domains (5 → 7)

| # | CSDM 4 | CSDM 5 |
|---|--------|--------|
| 1 | Foundation | Foundation |
| 2 | — | **Ideation & Strategy** (new) |
| 3 | Design | **Design & Planning** (renamed) |
| 4 | — | **Build & Integration** (new scope) |
| 5 | Manage Technical Services | **Service Delivery** (renamed) |
| 6 | Sell/Consume | **Service Consumption** (renamed) |
| 7 | — | **Manage Portfolios** (new) |

## New CI classes in CSDM 5 (not needed for Crawl)

- AI Function, AI Application (for ServiceNow AI Agents)
- Data Service Instance, Network Service Instance, Connection Service Instance
- Software Bill of Materials (SBOM)
- Value Streams
- DevOps Change Data Model classes
- Operational Technology classes

## Impact on Crawl: minimal

For Crawl, CSDM 5 changes are cosmetic. You still:
1. Create records in `cmdb_ci_business_app`
2. Create records in `cmdb_ci_service_auto`
3. Link them with "Consumes::Consumed By"
4. Populate the same fields

The Yokohama release did add new subtypes under `cmdb_ci_service_auto`, but these
are optional specializations — base records in the parent table remain valid.

## Why CSDM 5 matters strategically

ServiceNow's AI Agents (Now Assist, AI Search, Predictive Intelligence) depend on
clean CSDM-aligned data. Organizations that skip Crawl will find their AI investments
underperform because the AI can't reason about applications without Business Application
and Service Instance records. This is the primary urgency driver for CSDM adoption in
2025–2026.

---

*GetInSync NextGen tracks CSDM maturity stage per application (Stage 0–4) and produces
CSDM 5-aligned export data. See getinsync.ca.*
