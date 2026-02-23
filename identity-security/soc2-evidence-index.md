# identity-security/soc2-evidence-index.md
GetInSync NextGen — SOC2 Type II Evidence Index  
Last updated: 2026-02-23  
Status: 🟢 AS-BUILT (evidence collection started Feb 8, 2026)

---

## Purpose

This document maps SOC2 Trust Service Criteria to specific GetInSync architecture documents, database objects, and live queries that evidence compliance. It serves as the "push button" audit preparation guide — every line is either a document reference or a query that can be run on demand.

**Audit Period Start:** February 8, 2026 (audit_logs table created)  
**Target Audit:** SOC2 Type II (Security + Availability)  
**Earliest Audit Eligibility:** August 2026 (6 months of evidence)

---

## How to Use This Document

**For quarterly evidence collection:**
1. Run `SELECT generate_soc2_evidence();` as platform admin
2. Save the JSON output with timestamp
3. Review gaps flagged in this document
4. Update status of any newly implemented controls

**For auditor preparation:**
1. Walk through each Trust Criteria section below
2. Each section lists: what the auditor asks → what we show them
3. Documents marked 📄 are architecture docs in the project
4. Queries marked ðŸ” are live queries run against production
5. Gaps marked ⚠️ are items that need implementation or formal documentation

---

## Trust Criteria Coverage Decision

**In scope (Q1 2026):**
- CC: Common Criteria (Security) — all organizations require this
- A: Availability — SaaS customers expect this

**Deferred:**
- PI: Processing Integrity — not required for initial certification
- C: Confidentiality — partially covered by Security controls
- P: Privacy — covered by Privacy Policy, not SOC2 scope

---

## CC6: Logical and Physical Access Controls

### CC6.1 — Logical Access Security

**Auditor asks:** "How do you control who can access what data?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | RLS Policy Architecture — 347 policies across 90 tables | identity-security/rls-policy.md + v2_4-addendum |
| 2 | 📄 | Access Control Matrix (5 roles × 5 operations) | identity-security/rls-policy.md § SOC2 Compliance |
| 3 | 📄 | RBAC model (namespace_role + workspace role) | identity-security/identity-security.md (v1.2 — rewritten Feb 23) |
| 4 | ðŸ” | All tables have RLS enabled | `SELECT count(DISTINCT tablename) FROM pg_policies WHERE schemaname = 'public';` → should match table count |
| 5 | ðŸ” | No orphaned admin accounts | `SELECT * FROM platform_admins pa WHERE NOT EXISTS (SELECT 1 FROM auth.users au WHERE au.id = pa.user_id);` → 0 rows |
| 6 | ðŸ” | Users by role distribution | `SELECT namespace_role, count(*) FROM users GROUP BY namespace_role;` |
| 7 | ðŸ” | Platform admin count | `SELECT count(*) FROM platform_admins;` |
| 8 | 📄 | Platform admin provisioning process | planning/super-admin-provisioning.md |
| 9 | ðŸ” | Namespace isolation verification | `SELECT n.name, count(a.id) FROM namespaces n LEFT JOIN workspaces w ON w.namespace_id = n.id LEFT JOIN applications a ON a.workspace_id = w.id GROUP BY n.name;` |

**Gaps:**
- ✅ **Identity/Security doc rewritten to v1.2** (Feb 23, 2026) — Supabase Auth, RBAC, SOC2 controls
- ⚠️ **No MFA enforcement** — Supabase Auth supports MFA but not enforced yet
- ⚠️ **No formal access review process** — need quarterly review procedure documented

---

### CC6.2 — Encryption

**Auditor asks:** "How is data protected at rest and in transit?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Database encryption at rest (AES-256, Supabase managed) | Supabase infrastructure — ca-central-1 |
| 2 | 📄 | TLS 1.2+ enforced on all connections | Netlify HTTPS + Supabase SSL |
| 3 | 📄 | Data residency enforcement | planning/work-package-multi-region.md |
| 4 | ðŸ” | All namespaces have region assigned | `SELECT region, count(*) FROM namespaces GROUP BY region;` |
| 5 | ðŸ” | Region constraint enforced | `SELECT conname, consrc FROM pg_constraint WHERE conrelid = 'namespaces'::regclass AND conname LIKE '%region%';` |
| 6 | 📄 | No cross-region data transfer by design | planning/work-package-multi-region.md § Design Decisions |

**Gaps:**
- ⚠️ **No Supabase encryption certificate on file** — request from Supabase support
- ⚠️ **Password hashing documentation** — document bcrypt usage via Supabase Auth

---

### CC6.3 — API Authentication

**Auditor asks:** "How are API endpoints protected?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Supabase Auth JWT-based API authentication | Supabase default — all API calls require JWT |
| 2 | 📄 | RLS enforces authorization after authentication | identity-security/rls-policy.md |
| 3 | 📄 | Anon key vs service_role key separation | Supabase default security model |
| 4 | ðŸ” | No tables accessible without auth | `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT IN (SELECT DISTINCT tablename FROM pg_policies WHERE schemaname = 'public');` → should be 0 (all tables have RLS) |

**Gaps:**
- ⚠️ **No rate limiting documentation** — Supabase has defaults but not documented
- ⚠️ **No API key rotation procedure** — document process for JWT secret rotation

---

### CC6.6 — Audit Logging

**Auditor asks:** "Can you show me who did what, when?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Application audit logging (37 tables with triggers) | public.audit_logs table (created Feb 8, 2026) |
| 2 | 📄 | Authentication audit logging | auth.audit_log_entries (Supabase built-in) |
| 3 | 📄 | Audit log schema design | identity-security/identity-security.md § 9.2 |
| 4 | ðŸ” | Audit trail evidence accumulation | `SELECT min(created_at), max(created_at), count(*) FROM audit_logs;` |
| 5 | ðŸ” | Events by category | `SELECT event_category, count(*) FROM audit_logs GROUP BY event_category;` |
| 6 | ðŸ” | Auth events accumulation | `SELECT min(created_at), count(*) FROM auth.audit_log_entries;` |
| 7 | 📄 | Retention policy (365 day minimum) | audit_log_cleanup() function enforces minimum |
| 8 | ðŸ” | Full evidence report | `SELECT generate_soc2_evidence();` |
| 9 | 📄 | Audit logs are append-only (no UPDATE trigger, no updated_at column) | Table design — immutability by structure |

**Gaps:**
- ⚠️ **No SIEM integration** — future: export to Splunk/Azure Sentinel
- ⚠️ **No automated alerting on suspicious events** — future: Supabase Edge Functions

---

### CC6.7 — Vulnerability Management

**Auditor asks:** "How do you identify and fix vulnerabilities?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Dependency management via npm (frontend) | package.json in GitHub |
| 2 | 📄 | Database patching managed by Supabase | Supabase SLA |

**Gaps:**
- ⚠️ **No automated vulnerability scanning** — need: GitHub Dependabot, Snyk, or similar
- ⚠️ **No penetration testing** — schedule for Q3 2026
- ⚠️ **No formal patch management policy** — document procedure

---

## CC7: System Operations

### CC7.1 — Change Management

**Auditor asks:** "How do you manage changes to the system?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Architecture changelog | archive/superseded/architecture-changelog-v1_7.md |
| 2 | 📄 | Architecture manifest with version tracking | MANIFEST.md |
| 3 | 📄 | Git commit history | GitHub: sholtby/getinsync-nextgen-ag |
| 4 | 📄 | Schema backup with full DDL | getinsync-nextgen-schema-2026-02-11.sql |
| 5 | 📄 | Document status convention (AS-BUILT / AS-DESIGNED / NEEDS UPDATE) | MANIFEST.md |

**Gaps:**
- ⚠️ **No formal change approval process** — need: documented approval flow (ticket → review → deploy → verify)
- ⚠️ **No separate staging environment** — dev site exists but no formal promotion process
- ⚠️ **No rollback procedure documented** — document database rollback from pg_dump

---

### CC7.2 — Monitoring

**Auditor asks:** "How do you detect and respond to issues?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Supabase dashboard monitoring | Supabase built-in |
| 2 | 📄 | Netlify deploy notifications | Netlify built-in |
| 3 | 📄 | Budget alerts architecture | features/cost-budget/budget-alerts.md |

**Gaps:**
- ⚠️ **No uptime monitoring** — need: UptimeRobot, Pingdom, or similar
- ⚠️ **No error tracking** — need: Sentry, LogRocket, or similar
- ⚠️ **No incident response plan** — document runbook

---

## A1: Availability

### A1.1 — System Availability

**Auditor asks:** "What is your uptime commitment and how do you ensure it?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Supabase SLA (99.9% for Pro plan) | Supabase terms |
| 2 | 📄 | Netlify SLA (99.99% for CDN) | Netlify terms |
| 3 | 📄 | Multi-region capability (deploy US/EU in 2-3 hours) | planning/work-package-multi-region.md |

**Gaps:**
- ⚠️ **No published SLA for GetInSync customers** — draft SLA document
- ⚠️ **No uptime tracking/reporting** — implement monitoring first
- ⚠️ **No disaster recovery test** — schedule: restore from pg_dump, document results

---

### A1.2 — Backup and Recovery

**Auditor asks:** "Can you restore from backup? When was it last tested?"

**Evidence:**

| # | Type | Evidence | Location |
|---|------|----------|----------|
| 1 | 📄 | Supabase daily automated backups | Supabase Pro plan feature |
| 2 | 📄 | Manual pg_dump backup | getinsync-nextgen-schema-2026-02-11.sql (GitHub) |
| 3 | 📄 | Schema backup procedure | Session summary 2026-02-08 |
| 4 | ðŸ” | Schema object counts | `SELECT 'tables' as type, count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' UNION ALL SELECT 'views', count(*) FROM information_schema.views WHERE table_schema='public' UNION ALL SELECT 'functions', count(*) FROM information_schema.routines WHERE routine_schema='public';` |

**Gaps:**
- ⚠️ **No backup restore test** — CRITICAL: schedule restore test, document results
- ⚠️ **No documented RTO/RPO** — draft: RTO 4 hours, RPO 24 hours (Supabase daily backup)
- ⚠️ **No backup monitoring** — verify Supabase backups are running

---

## Policy Documents Needed

These standalone policy documents don't exist yet but are required for SOC2. Each can be a 2-5 page document.

| Policy | Priority | Effort | Notes |
|--------|----------|--------|-------|
| Information Security Policy | HIGH | 2-3 hours | Umbrella policy covering all controls |
| Acceptable Use Policy | MEDIUM | 1 hour | For internal team (Stuart, Delta) |
| Incident Response Plan | HIGH | 2-3 hours | Runbook: detect → assess → contain → notify |
| Change Management Policy | HIGH | 1-2 hours | Codify existing Git/architecture workflow |
| Data Classification Policy | MEDIUM | 1 hour | Define: Public, Internal, Confidential, Restricted |
| Business Continuity Plan | MEDIUM | 2 hours | DR procedures, communication plan |
| Vendor Management Policy | LOW | 1 hour | Supabase, Netlify, GitHub evaluation criteria |
| Data Retention Policy | LOW | 30 min | Already enforced in audit_log_cleanup() |

**Total effort to draft all policies:** ~12-15 hours  
**Assigned to:** Delta Holtby (8 Jira tickets created Feb 12, 2026)  
**Method:** Claude AI drafts, Stuart reviews  
**Priority 1 due:** March 15, 2026 (Information Security, Change Management, Incident Response)

---

## Evidence Collection Schedule

| Frequency | Action | Method |
|-----------|--------|--------|
| **Monthly** | Run `generate_soc2_evidence()`, save JSON | Platform admin → SQL Editor |
| **Monthly** | Review audit_logs for anomalies | `search_audit_logs()` RPC |
| **Quarterly** | Access review (who has admin/platform admin) | Query + manual review |
| **Quarterly** | Review and update this document | Manual |
| **Annually** | Penetration test | Third-party vendor |
| **Annually** | Backup restore test | Restore pg_dump to test environment |
| **On change** | Update architecture docs + changelog | Existing workflow |

---

## Current Readiness Score

| Category | Status | Score |
|----------|--------|-------|
| CC6.1 Logical Access | RLS + RBAC implemented, docs updated. MFA + access review pending | 🟡 80% |
| CC6.2 Encryption | Supabase handles, needs documentation | 🟡 60% |
| CC6.3 API Auth | JWT + RLS implemented, needs docs | 🟡 65% |
| CC6.6 Audit Logging | ✅ Implemented Feb 8, 2026 | 🟢 90% |
| CC6.7 Vulnerability Mgmt | No scanning in place | ðŸ”´ 20% |
| CC7.1 Change Management | Git + changelogs, needs formal process | 🟡 60% |
| CC7.2 Monitoring | Minimal — Supabase/Netlify defaults only | ðŸ”´ 30% |
| A1.1 Availability | Supabase/Netlify SLAs, no customer SLA | 🟡 50% |
| A1.2 Backup/Recovery | Automated + manual, never tested restore | 🟡 55% |
| **Policy Documents** | None written yet | ðŸ”´ 0% |
| **Overall Readiness** | | **🟡 ~50%** |

---

## Recommended Priority Actions

### Before ServiceNow Knowledge (May 2026)
1. ✅ Audit logging implemented (Feb 8 — this migration)
2. ✅ Rewrite Identity/Security doc (v1.2 — Feb 23, 2026)
3. Draft Information Security Policy (2-3 hours)
4. Draft Change Management Policy (1-2 hours)
5. Enable GitHub Dependabot (30 minutes)
6. Run first `generate_soc2_evidence()` and archive (10 minutes)

### Before First Enterprise Deal
7. Conduct backup restore test (2 hours)
8. Draft Incident Response Plan (2-3 hours)
9. Set up uptime monitoring (1 hour)
10. Complete all 8 policy documents (weekend project)

### Before SOC2 Audit (Q3-Q4 2026)
11. Schedule penetration test (third-party vendor)
12. Conduct quarterly access reviews (3 cycles minimum)
13. Engage SOC2 readiness assessor
14. Complete 6 months of continuous evidence

---

## Architecture Documents → SOC2 Control Mapping

Quick reference: which architecture doc evidences which control.

| Document | Controls Evidenced |
|----------|--------------------|
| identity-security/rls-policy.md | CC6.1, CC6.3, C1.1 |
| identity-security/identity-security.md | CC6.1, CC6.6 |
| planning/work-package-multi-region.md | CC6.2, C1.2 |
| MANIFEST.md | CC7.1 |
| archive/superseded/architecture-changelog-v1_7.md | CC7.1 |
| planning/super-admin-provisioning.md | CC6.1 |
| features/cost-budget/budget-alerts.md | CC7.2 |
| planning/work-package-privacy-oauth.md | CC6.1, C1.1 |
| getinsync-nextgen-schema-2026-02-11.sql | A1.2, CC7.1 |
| operations/demo-credentials.md | CC6.1 (access management) |
| identity-security/security-posture-overview.md | CC6.1, CC6.6, CC6.7, CC7.1 |
| identity-security/security-validation-runbook.md | CC6.1, CC6.6, CC7.1 |
| operations/database-change-validation.md | CC7.1 |
| operations/new-table-checklist.md | CC6.1, CC6.6, CC7.1 |
| identity-security/soc2-evidence-collection.md | CC6.6, CC7.1 |
| operations/session-end-checklist.md | CC7.1 |
| identity-security/user-registration.md | CC6.1, CC6.6, C1.1 |
| identity-security/rls-policy-addendum.md | CC6.1, CC6.3, C1.1 |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-08 | Initial SOC2 Evidence Index. Audit logging migration created. Trust criteria mapped to existing docs and queries. Gaps identified. Readiness scored at ~50%. |
| v1.2 | 2026-02-23 | Stats updated: 90 tables (was 72), 347 RLS policies (was 282), 37 audit triggers (was 17). Identity-security rewrite ⚠️ flags cleared (v1.2 done). CC6.1 readiness bumped 75%→80%. |
| v1.1 | 2026-02-12 | Stats corrected: 72 tables (was 66), 17 audit triggers (was 11), 282+ RLS policies (was 279). Manifest ref v1.18→v1.20. Schema backup ref Feb 8→Feb 11. Added 9 docs to control mapping (Security & Operations section + user registration + RLS v2.4 addendum). Policy docs assigned to Delta via Jira (8 tickets). |

---

*Document: identity-security/soc2-evidence-index.md*  
*SOC2 Controls: CC6.1, CC6.2, CC6.3, CC6.6, CC6.7, CC7.1, CC7.2, A1.1, A1.2*  
*February 2026*
