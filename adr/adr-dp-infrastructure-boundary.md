# ADR: Deployment Profile Infrastructure Boundary — GetInSync vs ServiceNow

**Version:** 1.1
**Date:** March 19, 2026
**Status:** ACCEPTED
**Author:** Stuart Holtby + Claude
**Relates to:** `core/deployment-profile.md`, `features/technology-health/technology-stack-erd.md`, `features/integrations/servicenow-alignment.md`

---

## Context

During Garland import analysis (363 apps), a proposal was made to add `instance_name` to `dp_technology_products` to capture per-role hostnames (OS server, database server, web/app server). This ADR records why that was rejected and establishes the correct boundary between GetInSync and ServiceNow for infrastructure data.

---

## Decision

ServiceNow is the system of record for all CI-level infrastructure. GetInSync publishes Applications to Business Application and Deployment Profiles to Application Service. ServiceNow IRE owns everything below — all hostnames, server roles, CI relationships.

---

## What GetInSync Owns

- **Technology product type tags on DPs** — for portfolio intelligence, lifecycle risk, upgrade impact analysis
- **`server_name` on DP** — single loose pre-publish reference, business stakeholder facing, not a CI hostname

---

## Why `instance_name` Was Rejected

- IRE maintains hostnames automatically post-publish — storing them in GetInSync creates a diverging second source of truth
- No inbound sync mechanism exists and should not be built for CI-level data
- Hostname data belongs to the operational layer, not the portfolio layer

---

## The Garland Import Implication

Garland (363 apps, 7,646 assessments) provides a flat server list with multiple named hostnames per application broken down by server role — OS server, database server, web/app server. This is representative of what mature government IT clients will bring to GetInSync imports.

### Mapping Rule

| Garland Data | Maps To | Notes |
|---|---|---|
| Application name | `applications` | One record per application |
| Environment (PROD/TEST/DR) | Separate DPs per environment | PROD DP, TEST DP, DR DP |
| Technology type (SQL Server, IIS, Windows Server) | `dp_technology_products` tags | Type only — no hostname |
| Primary app server hostname | `server_name` on DP | One value — pick app server; if ambiguous leave null |
| All other hostnames (DB server, web server, OS server) | Not imported | Deferred to ServiceNow post-publish |

### Decision Rule for `server_name`

Use the primary application server hostname. If the source data does not clearly identify a primary server, leave `server_name` null and populate technology product tags only. Do not block the import on hostname decisions — the technology type tags are the valuable data for portfolio intelligence.

### What Gets Left Behind and Why

The DB server, web server, and OS server hostnames are CI-level data. They belong in ServiceNow as CI relationships on the Application Service record post-publish, discovered and maintained by IRE. Recording them in GetInSync would create a second source of truth that diverges from CMDB over time with no automated reconciliation path.

### Customer Conversation Guidance

When a customer questions why GetInSync is not capturing all their server names, the correct framing is:

> "We're capturing your technology stack for portfolio intelligence — what you're running and whether it's at risk. Full server inventory lives in ServiceNow once we publish your Application Services. For TIME assessment and upgrade impact analysis, the technology type is what matters, not every hostname."

### Applies to All Future Imports

This guidance is not Garland-specific. Any customer arriving with flat server lists, CMDB exports, or infrastructure spreadsheets should be mapped using the same rules. GetInSync captures technology types and one primary server reference. Everything else is ServiceNow's responsibility post-publish.

---

## Positioning Statement

> "GetInSync ingests, validates, attests, and corrects portfolio data. ServiceNow executes and discovers operational data. GetInSync is the on-ramp to CSDM — it walks customers up the Business Application to Application Service chain correctly and hands off to IRE for everything below."

---

## Risks

| Risk | Mitigation |
|---|---|
| Customers expect all server names stored | Clear boundary statement in onboarding |
| `server_name` confusion post-publish | UI tooltip: "pre-publish reference only" |
| Garland import loses hostname detail | Hostnames go to ServiceNow post-publish |
| Customer has no ServiceNow yet | `server_name` + tech tags sufficient until publish configured |

---

## Changelog

- **v1.1 — March 19, 2026** — Expanded Garland Import Implication section into general import guidance applicable to all customers with infrastructure-rich source data.
- **v1.0 — March 19, 2026** — Initial ADR.
