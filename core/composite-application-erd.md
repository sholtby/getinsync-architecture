```
COMPOSITE APPLICATION ERD — v2.0
=================================
Updated: 2026-03-08
Replaces v1.0 (parent_application_id self-referencing FK — superseded)


DATA MODEL
==========

+---------------------------+       +------------------------------+
|       applications        |       |   application_relationships  |
+---------------------------+       +------------------------------+
| id (PK)                   |<------| source_application_id (FK)   |
| name                      |<------| target_application_id (FK)   |
| workspace_id (FK)         |       | namespace_id (FK)            |
| architecture_type (FK)    |---+   | relationship_type            |
| lifecycle_status           |   |   |   ('constitutes' |           |
| ...                        |   |   |    'depends_on'  |           |
+---------------------------+   |   |    'replaces')               |
                                |   | dependency_criticality       |
                                |   | notes                        |
                                |   | display_order                |
+---------------------------+   |   +------------------------------+
|   architecture_types      |   |
+---------------------------+   |
| code (PK) ----------------+--+
| name                      |
| description               |
| display_order             |
| is_active                 |
+---------------------------+

Seed data:
  standalone         = Independent application
  platform_host      = Parent (e.g., Microsoft 365)
  platform_application = Module (e.g., Teams)


DEPLOYMENT PROFILE WITH INHERITANCE
====================================

deployment_profiles
+-----------------------------------+
| id (PK)                           |
| application_id (FK → applications)|
| name                              |
| is_primary                        |
| inherits_tech_from (FK → self)  --+---> deployment_profiles.id
| hosting_type                      |     (parent's primary DP)
| T01-T14 scores                    |
| tech_health (computed)            |
| tech_risk (computed)              |
+-----------------------------------+

When inherits_tech_from IS NOT NULL:
  - T01-T14 = NULL (scores come from parent)
  - tech_health = NULL, tech_risk = NULL
  - Frontend resolves FK to display parent's scores


SUITE EXAMPLE (constitutes)
============================

applications
+------------------------------------------+
| id: aaa-...                              |
| name: "Sage 300 General Ledger"          |
| architecture_type: platform_host         |
+------------------------------------------+
           |
           | (children via application_relationships)
           |
     +-----+-----------+-----------+
     |                 |           |
     v                 v           v
+------------+  +------------+  +------------+
| id: bbb    |  | id: ccc    |  | id: ddd    |
| Sage 300   |  | Sage 300   |  | Sage 300   |
| AR         |  | AP         |  | IC         |
| arch_type: |  | arch_type: |  | arch_type: |
| platform_  |  | platform_  |  | platform_  |
| application|  | application|  | application|
+------------+  +------------+  +------------+

application_relationships
+----------------------------------------------------+
| source: aaa (GL)  | target: bbb (AR) | constitutes |
| source: aaa (GL)  | target: ccc (AP) | constitutes |
| source: aaa (GL)  | target: ddd (IC) | constitutes |
+----------------------------------------------------+


DEPLOYMENT PROFILE INHERITANCE
==============================

Parent App (Sage 300 GL)
    |
    +-- Parent DP: "Sage 300 GL - PROD"
    |       |
    |       +-- T01-T14 scored (e.g., T01=4, T02=3, ...)
    |       +-- tech_health = 72.5
    |       +-- tech_risk = 35.2
    |       +-- inherits_tech_from = NULL (this IS the source)
    |       +-- IT Services linked here
    |       +-- Software Product linked here
    |
    +-- Child App (Sage 300 AR)
    |       |
    |       +-- Child DP: "Sage 300 AR - PROD"
    |               +-- inherits_tech_from = [Parent DP id]
    |               +-- T01-T14 = NULL (inherited)
    |               +-- tech_health = NULL, tech_risk = NULL
    |               +-- UI displays: 72.5 (inherited), 35.2 (inherited)
    |               +-- Portfolio Assignment (Sales Portfolio)
    |                       +-- B01-B10 scored independently
    |
    +-- Child App (Sage 300 IC)
            |
            +-- Child DP: "Sage 300 IC - PROD"
                    +-- inherits_tech_from = [Parent DP id]
                    +-- T01-T14 = NULL (inherited)
                    +-- Portfolio Assignment (Warehouse Portfolio)
                            +-- B01-B10 scored independently


FULL CONTEXT — ASSESSMENT FLOW
================================

+----------------+       +------------------+       +---------------------+
|  applications  |       | deployment_      |       | portfolio_          |
|                |       | profiles         |       | assignments         |
+----------------+       +------------------+       +---------------------+
| id             |<------| application_id   |       | id                  |
| name           |       | id               |<------| deployment_         |
| architecture_  |       | name             |       | profile_id          |
| type           |       | is_primary       |       | portfolio_id        |
| workspace_id   |       | inherits_tech_   |       | B-scores (B01-B10)  |
+----------------+       | from (FK→self)   |       | relationship_type   |
                          | T01-T14 scores   |       +---------------------+
                          | tech_health      |
                          | tech_risk        |
                          +------------------+

                          +------------------------------+
                          | application_relationships    |
                          +------------------------------+
                          | source_application_id (FK)   |
                          | target_application_id (FK)   |
                          | relationship_type            |
                          | namespace_id (FK)            |
                          +------------------------------+


COST ROLLUP (SUITE)
====================

Parent DP (GL - PROD):
    IT Services: Cloud Hosting ($30,000), Database ($15,000)
    Software Product: Sage 300 Bundle (inventory-only, no cost)
    Cost Bundles: Sage maintenance contract ($5,000)
    DP Total: $50,000

Child DP (AR - PROD):
    IT Services: (none — shares parent's infrastructure)
    Cost Bundles: (none)
    DP Total: $0

Child DP (IC - PROD):
    IT Services: Warehouse add-on module ($5,000)
    Cost Bundles: (none)
    DP Total: $5,000

Child DP (Payroll - PROD):
    IT Services: Payroll processing SaaS ($12,000)
    Cost Bundles: (none)
    DP Total: $12,000
    -----------------------------------------
    SUITE TOTAL: $67,000

Costs flow through standard channels (IT Services + Cost Bundles).
Each child DP can have its own cost items for add-on modules.
Parent DP carries the shared infrastructure cost.


COMPOSITE EXAMPLE (depends_on) — Phase 2
==========================================

applications
+---------------------+
| Customer Portal     |-----+-- depends_on --> Sage 300 GL (critical)
| (composite)         |     |-- depends_on --> SharePoint (required)
| arch_type: standalone|     +-- depends_on --> Custom API (critical)
+---------------------+

Risk calculation:
  Sage 300 GL    tech_risk = 35.2
  SharePoint     tech_risk = 15.0
  Custom API     tech_risk = 60.5  ← weakest link

  Customer Portal derived_tech_risk = MAX(35.2, 15.0, 60.5) = 60.5


SUCCESSION EXAMPLE (replaces) — Phase 2
=========================================

New CRM ──replaces──► Legacy CRM

Both applications maintain independent DPs and assessments.
Used for migration tracking and impact analysis.
```
