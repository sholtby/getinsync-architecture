```
COMPOSITE APPLICATION ERD
=========================

+---------------------------+
|       applications        |
+---------------------------+
| id (PK)                   |
| name                      |
| workspace_id (FK)         |
| parent_application_id (FK)|----+
| lifecycle_status          |    |
| ...                       |    |
+---------------------------+    |
      |                          |
      | (self-reference)         |
      +--------------------------+


EXAMPLE HIERARCHY
=================

applications
+------------------------------------------+
| id: aaa-...                              |
| name: "Sage 300 ERP"                     |
| parent_application_id: NULL (is parent)  |
+------------------------------------------+
           |
           | (children reference parent)
           |
     +-----+-----+-----+-----+
     |           |           |
     v           v           v
+----------+ +----------+ +----------+
| id: bbb  | | id: ccc  | | id: ddd  |
| Sage 300 | | Sage 300 | | Sage 300 |
| GL       | | AP       | | IC       |
| parent:  | | parent:  | | parent:  |
| aaa-...  | | aaa-...  | | aaa-...  |
+----------+ +----------+ +----------+


RELATIONSHIP TO DEPLOYMENT PROFILES
===================================

applications                 deployment_profiles
+-------------------+        +----------------------+
| id (PK)           |        | id (PK)              |
| name              |        | application_id (FK)  |----> applications.id
| parent_app_id(FK) |        | name                 |
+-------------------+        | dp_type              |
                             | is_primary           |
                             | T01-T15 scores       |
                             +----------------------+


FULL CONTEXT
============

+----------------+       +------------------+       +---------------------+
|  applications  |       | deployment_      |       | portfolio_          |
|                |       | profiles         |       | assignments         |
+----------------+       +------------------+       +---------------------+
| id             |<------| application_id   |       | id                  |
| name           |       | id               |<------| deployment_         |
| parent_app_id  |--+    | name             |       | profile_id          |
| workspace_id   |  |    | dp_type          |       | portfolio_id        |
+----------------+  |    | T-scores         |       | B-scores            |
        ^           |    +------------------+       | relationship_type   |
        |           |                               +---------------------+
        +-----------+
        (self-ref)


ASSESSMENT FLOW
===============

Parent App (Sage 300 ERP)
    |
    +-- Parent DP (shared infra)
    |       |
    |       +-- T-scores (technical reality)
    |       +-- Portfolio Assignment
    |               +-- B-scores (aggregated view)
    |
    +-- Child App (Sage 300 GL)
    |       |
    |       +-- Child DP (or inherits parent)
    |               +-- T-scores (own or inherited)
    |               +-- Portfolio Assignment (Finance)
    |                       +-- B-scores (Finance's view)
    |
    +-- Child App (Sage 300 IC)
            |
            +-- Child DP
                    +-- T-scores
                    +-- Portfolio Assignment (Shipping)
                            +-- B-scores (Shipping's view)


COST ROLLUP
===========

Parent DP: $50,000 (suite license)
    |
    +-- Child DP (GL): $0 (included)
    +-- Child DP (AP): $0 (included)
    +-- Child DP (IC): $5,000 (add-on)
    +-- Child DP (Payroll): $12,000 (add-on)
    -----------------------------------------
    TOTAL: $67,000 (shown on parent dashboard)
```
