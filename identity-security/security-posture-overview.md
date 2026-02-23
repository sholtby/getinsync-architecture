# GetInSync NextGen — Security Posture & Automated Compliance Validation

**Version:** 1.2
**Date:** February 23, 2026
**Status:** 🟢 AS-BUILT  
**Audience:** Prospects (security review), SOC2 auditors, internal reference

---

## The Problem We Solve (For Our Customers' Security Teams)

Enterprise and government procurement teams ask the same questions of every SaaS vendor:

- "How do you isolate our data from other tenants?"
- "Can you prove who accessed what and when?"
- "What happens if your application has a bug — does our data leak?"
- "How do you know your security controls actually work?"

Most vendors answer with policies and promises. We answer with database-enforced controls and automated validation that proves they're in place.

---

## Our Security Architecture: Three Layers of Enforcement

### Layer 1 — Database-Enforced Tenant Isolation (Row-Level Security)

Every query against every table is filtered by the database engine itself — not by application code. This means:

- A bug in our frontend **cannot** expose another tenant's data
- A misconfigured API endpoint **cannot** bypass isolation
- A compromised user session **cannot** read across namespace boundaries

**By the numbers:**

| Metric | Value |
|--------|-------|
| Tables with RLS policies | 90 |
| Total RLS policies | 347 |
| Views with security_invoker | 27/27 (RLS enforced through views) |
| Policy pattern | Granular 4-policy (SELECT, INSERT, UPDATE, DELETE) |
| Isolation boundary | Namespace (organization) |
| Admin override | Explicit platform admin check, logged |
| Cross-tenant queries | Impossible at database level |

**How it works:** Every authenticated query passes through PostgreSQL Row-Level Security. The database checks the user's current namespace (stored in a session table, not a cookie or JWT claim) and filters every row before returning results. Even `SELECT *` returns only the requesting tenant's data.

Database views are configured with `security_invoker = true`, ensuring they respect the calling user's RLS policies rather than running with elevated creator privileges. This means tenant isolation is enforced consistently whether data is queried from tables directly or through views.

**Why this matters:** Application-layer filtering (WHERE clauses in code) can be bypassed by bugs, injection attacks, or developer error. Database-layer filtering cannot — it's enforced by the database engine regardless of how the query was constructed.

### Layer 2 — Comprehensive Audit Trail (Trigger-Based Logging)

Every data change and access control event is captured by database triggers — not application code. This means:

- Direct SQL changes are logged (database admin actions)
- RPC-driven changes are logged (backend operations)
- Cascade deletes are logged (referential integrity events)
- Bulk operations are logged (data migrations)
- Application code cannot skip logging

**By the numbers:**

| Metric | Value |
|--------|-------|
| Audit triggers | 37 (all critical tables) |
| Event categories | 4 |
| Trigger type | SECURITY DEFINER (bypasses RLS for write to audit log) |
| Noise reduction | Skips updates where only timestamps changed |
| Changed fields | Captured as array on every UPDATE |
| Retention | 365-day minimum (SOC2 requirement) |

**Four event categories:**

| Category | Source | What It Captures |
|----------|--------|-----------------|
| `access_control` | Database trigger | User added/removed, role changes, invitation lifecycle |
| `data_change` | Database trigger | Application created/edited/deleted, assessment changes, portfolio updates |
| `session` | Frontend | Login, logout, namespace switches |
| `usage` | Frontend | Page views, feature adoption (60-second debounce) |

**Trigger coverage:**

| Category | Tables |
|----------|--------|
| Core business data | applications, deployment_profiles, portfolios, portfolio_assignments |
| Integration tracking | application_integrations, integration_contacts |
| Reference data | contacts, organizations, data_tag_types, it_services |
| Access control | users, invitations, namespace_users, workspace_users, platform_admins, user_sessions |

**Why this matters:** Application-layer audit logging has gaps. If someone runs a SQL query directly, or a database trigger fires a cascade delete, or a background job modifies data — application logging misses it. Trigger-based logging captures everything because it operates at the database engine level.

### Layer 3 — Automated Compliance Validation (Self-Testing)

We maintain a suite of validation queries that verify our security controls are in place. These queries check the actual database state — not documentation, not configuration files, not assertions about what should exist.

**What we validate:**

| Check | What It Proves | Red Signal |
|-------|---------------|------------|
| GRANT verification | Every table is accessible to authenticated users | Table invisible to application (silent data loss) |
| RLS enablement | Every table has row-level security active | Tenant data exposed to other tenants |
| RLS policy coverage | Every RLS-enabled table has policies | RLS blocks all access (no data returned) |
| View security mode | Every view uses security_invoker | Views bypass RLS, exposing cross-tenant data |
| Function search_path | Every SECURITY DEFINER function sets search_path | Schema hijacking vulnerability |
| Audit trigger coverage | Every critical table has change logging | Data modifications invisible to audit trail |
| Timestamp trigger coverage | Every mutable table auto-updates timestamps | Stale metadata, unreliable change tracking |
| Role alignment | All role values exist in lookup tables | Permission errors, UI dropdowns broken |
| FK safety | Foreign key ON DELETE actions are intentional | Delete operations blocked or data orphaned |
| Namespace defaults | Every tenant has a default workspace | New user onboarding fails |
| Constraint alignment | Column defaults match CHECK constraints | Insert operations fail silently |

**How it works:** At the end of every development session, we run the applicable validation queries against the production database. Each query returns either an empty result (pass) or a list of violations (fail). No manual interpretation required.

**Why this matters:** Security controls drift. Tables get added without RLS. Views get created without security_invoker. Triggers get missed during schema changes. GRANTs are forgotten. Most organizations discover these gaps during an audit — or worse, during an incident. We discover them in real-time, every session, automatically.

---

## SOC2 Trust Service Criteria Mapping

| Criteria | Category | How We Address It |
|----------|----------|-------------------|
| CC6.1 | Logical Access | RBAC at namespace + workspace level, database-enforced via RLS |
| CC6.2 | Encryption | TLS 1.2+ in transit, AES-256 at rest (Supabase managed) |
| CC6.6 | Audit Logging | 37 database triggers, 4 event categories, 365-day retention |
| CC7.1 | Security Monitoring | Automated validation queries, evidence snapshots |
| CC7.2 | Security Events | Audit log search RPC, monthly evidence collection |
| C1.1 | Confidentiality | Namespace isolation enforced at database level |
| A1.2 | Recovery | Daily automated backups, schema versioned in GitHub |

---

## Evidence We Can Produce On Demand

For any SOC2 auditor or enterprise security review, we can produce the following evidence within minutes — not days:

| Evidence | Method | Frequency |
|----------|--------|-----------|
| Complete RLS policy inventory | `pg_policies` system catalog query | On demand |
| View security mode inventory | `pg_class.reloptions` query | On demand |
| Audit trigger inventory | `pg_trigger` system catalog query | On demand |
| GRANT/permission matrix | `information_schema.role_table_grants` query | On demand |
| Full security posture dashboard | Single composite query (4 categories) | On demand |
| Monthly compliance snapshot | `generate_soc2_evidence()` RPC | Monthly (automated) |
| Audit log for any entity | `search_audit_logs()` RPC | On demand |
| User access history | Audit log filtered by user_id | On demand |
| Role change history | Audit log filtered by event_category = 'access_control' | On demand |
| Data change history | Audit log filtered by entity_type + entity_id | On demand |
| Tenant isolation proof | Run validation suite, show zero cross-tenant queries | On demand |

---

## Competitive Differentiation

### What Typical SaaS Startups Have

| Control | Typical Startup | GetInSync |
|---------|----------------|-----------|
| Data isolation | Application-layer WHERE clauses | Database-enforced RLS (347 policies) |
| View security | Default (bypasses isolation) | security_invoker on all views |
| Audit logging | Application code writes logs (gaps possible) | Database triggers (gaps impossible) |
| Compliance validation | Manual checklist before audit | Automated validation queries, every session |
| Evidence collection | Scramble when auditor asks | Monthly snapshots, on-demand queries |
| Role management | Hardcoded in application | Database-driven lookup tables |
| Security documentation | Written after the fact | Architecture docs maintained alongside code |

### What Enterprise Vendors Charge For This

LeanIX, ServiceNow, and other enterprise APM tools offer similar security controls — but at enterprise pricing ($100K+/year) and without the transparency we provide. Our customers can:

- Request our complete RLS policy architecture document
- See exactly which tables have audit triggers
- Review our validation queries themselves
- Run evidence collection RPCs from their own namespace
- Export their audit logs in JSON format

---

## Canadian Data Residency

All security controls described above operate within Canadian data residency boundaries:

| Component | Location | Compliance |
|-----------|----------|------------|
| Database (PostgreSQL) | Montreal, Quebec (ca-central-1) | PIPEDA, provincial FOIP |
| Authentication | Canadian region | PIPEDA |
| Audit logs | Same database, same region | PIPEDA, provincial FOIP |
| Backups | Same region | PIPEDA, provincial FOIP |
| Frontend hosting | CDN (cached only, no data storage) | N/A |

US and EU regions available on demand. Data never crosses regional boundaries.

---

## Architecture Documents Available for Review

| Document | Description |
|----------|-------------|
| RLS Policy Architecture v2.4 | Complete policy inventory for all 90 tables |
| Security Validation Runbook | Operational SQL queries for security posture checks |
| Audit Logging DDL | Table schema, indexes, RLS on audit_logs itself |
| Audit Logging Functions | Trigger function, evidence collection RPCs |
| Audit Logging Triggers | Which tables are monitored, trigger configuration |
| Database Change Validation Skill | Automated validation queries and expected results |
| New Table Checklist | Security requirements for every new table |
| SOC2 Evidence Collection Skill | Monthly evidence procedure, naming conventions |
| Identity & Security Architecture | Authentication, RBAC, session management |
| User Registration Architecture | Invitation lifecycle, signup flow, role assignment |

---

## Timeline

| Date | Milestone |
|------|-----------|
| Feb 2026 | RLS policies complete (90 tables, 347 policies) |
| Feb 2026 | Audit logging deployed (37 triggers, 4 categories) |
| Feb 2026 | Automated validation suite operational |
| Feb 2026 | View security hardened (27/27 views security_invoker) |
| Feb 2026 | First evidence snapshot collected (EV-001) |
| Aug 2026 | 6-month evidence threshold (SOC2 minimum) |
| Q4 2026 | Target SOC2 Type II audit |

---

## Summary

GetInSync doesn't bolt security on after the fact. Our security controls are enforced by the database engine, logged by database triggers, and validated by automated queries. Every table, every view, every policy, every trigger is verifiable — not by reading documentation, but by querying the live system.

When your security team asks "how do you know your controls work?" — we don't hand them a policy document. We hand them the queries and let them verify it themselves.

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-09 | Initial document. 70 tables, 286+ RLS policies, 16 audit triggers, automated validation suite, 4 audit event categories. |
| v1.1 | 2026-02-10 | Added view-level security (security_invoker) to Layer 1 metrics, Layer 3 validation checks, evidence list, competitive differentiation, and timeline. Added Security Validation Runbook to architecture documents list. |
| v1.2 | 2026-02-23 | Updated all stats from database: 90 tables (was 70), 347 RLS policies (was 286+), 37 audit triggers (was 16), 27/27 views with security_invoker (was 19/19). |

---

*Document: identity-security/security-posture-overview.md*  
*February 2026*
