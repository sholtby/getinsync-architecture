# identity-security/soc2-evidence-collection
GetInSync NextGen — SOC2 Evidence Collection Procedure  
Version: 1.3
Date: 2026-04-09  
Status: 🟢 AS-BUILT  
SOC2 Controls: CC6.1, CC6.2, CC6.6, CC7.1, C1.1, A1.2

---

## Purpose

This skill defines the repeatable process for collecting, naming, storing, and reviewing SOC2 Type II evidence snapshots. Follow this procedure monthly (minimum) to build the continuous monitoring evidence trail required for SOC2 certification.

---

## Evidence Clock

| Milestone | Date |
|-----------|------|
| **Audit logging activated** | 2026-02-08T15:59:08Z |
| **Baseline snapshot (EV-001)** | 2026-02-08 |
| **6-month evidence threshold** | 2026-08-08 |
| **Target Type II audit** | Q4 2026 |

---

## Naming Convention

### Evidence Snapshots

```
GIS-SOC2-EV-{sequence}-{YYYY}-{MM}-{DD}.json
```

| Element | Description | Example |
|---------|-------------|---------|
| `GIS` | Company prefix | GIS |
| `SOC2` | Compliance framework | SOC2 |
| `EV` | Evidence artifact | EV |
| `{sequence}` | Sequential number, zero-padded to 3 digits | 001, 002, 013 |
| `{YYYY}-{MM}-{DD}` | Collection date (UTC) | 2026-02-08 |

**Examples:**
- `GIS-SOC2-EV-001-2026-02-08.json` — Baseline
- `GIS-SOC2-EV-002-2026-03-01.json` — March monthly
- `GIS-SOC2-EV-003-2026-04-01.json` — April monthly

### Other SOC2 Document Types

| Type Code | Purpose | Example |
|-----------|---------|---------|
| `EV` | Evidence snapshot (monthly RPC output) | GIS-SOC2-EV-001-2026-02-08.json |
| `POL` | Policy document | GIS-SOC2-POL-ISP-v1_0.md (Information Security Policy) |
| `IRP` | Incident Response Plan | GIS-SOC2-IRP-v1_0.md |
| `CMP` | Change Management Policy | GIS-SOC2-CMP-v1_0.md |
| `AR` | Access Review (quarterly) | GIS-SOC2-AR-Q1-2026.json |
| `BRT` | Backup Restore Test | GIS-SOC2-BRT-2026-Q2.md |
| `PT` | Penetration Test Results | GIS-SOC2-PT-2026.pdf |
| `VAR` | Variance Analysis (month-over-month) | GIS-SOC2-VAR-2026-03.md |

---

## Monthly Evidence Collection Procedure

### Step 1: Run the Evidence RPC

Open Supabase SQL Editor and run:

```sql
SELECT generate_soc2_evidence();
```

This executes as postgres (SECURITY DEFINER) and queries all compliance-relevant tables. Takes ~2 seconds.

### Step 2: Copy the JSON Output

The RPC returns a single JSON object with sections for each trust criteria:
- `cc6_1_logical_access` — users, roles, RLS policies, namespaces
- `cc6_2_encryption` — regions, encryption status
- `cc6_6_audit_logging` — audit trail statistics
- `c1_1_tenant_isolation` — orphaned record checks
- `a1_2_backup_recovery` — schema statistics
- `access_review` — admin counts, recent events

### Step 3: Create the Evidence File

Wrap the RPC output in the standard evidence envelope. Ask Claude:

> "Here is this month's SOC2 evidence snapshot. Please create the evidence file with proper naming and metadata. Snapshot sequence is {next number}."

Then paste the JSON. Claude will:
1. Determine the next sequence number from project context
2. Create `GIS-SOC2-EV-{seq}-{date}.json` with metadata envelope
3. Calculate variance from previous snapshot
4. Flag any anomalies (new orphaned records, user count spikes, RLS policy drops)

### Step 4: Review and Archive

**Review checklist:**
- [ ] `users_without_namespace` = 0
- [ ] `orphaned_workspace_users` = 0
- [ ] `orphaned_portfolio_assignments` = 0
- [ ] `tables_with_rls` = `total_tables` (100% RLS coverage)
- [ ] `total_rls_policies` ≥ previous month (should not decrease)
- [ ] `total_audit_entries` > previous month (evidence accumulating)
- [ ] No unexpected tier changes in `namespaces_by_tier`
- [ ] `platform_admin_count` matches expected (currently 3)

**Archive to:** GitHub repo `soc2-evidence/` directory (create if needed)

### Step 5: Variance Analysis

Starting with snapshot #2, Claude will automatically compare to the previous snapshot and flag:

| Change Type | Action Required |
|-------------|-----------------|
| Users increased/decreased | Verify: new hires or departures? |
| RLS policies changed | Verify: new table or policy fix? |
| Tables changed | Verify: planned migration? |
| Platform admins changed | **INVESTIGATE IMMEDIATELY** |
| Orphaned records > 0 | **FIX BEFORE NEXT SNAPSHOT** |
| Audit entries not growing | **INVESTIGATE** — triggers may be broken |
| Region changed | **INVESTIGATE IMMEDIATELY** |

---

## Quarterly Access Review Procedure

Every quarter (March, June, September, December), run an extended review:

```sql
-- Who are the platform admins?
SELECT pa.user_id, u.email, pa.created_at 
FROM platform_admins pa 
JOIN auth.users au ON au.id = pa.user_id
JOIN users u ON u.id = pa.user_id
ORDER BY pa.created_at;

-- Who are namespace admins?
SELECT u.email, u.namespace_id, n.name as namespace_name, u.namespace_role
FROM users u
JOIN namespaces n ON n.id = u.namespace_id
WHERE u.namespace_role = 'admin'
ORDER BY n.name, u.email;

-- Who are workspace admins?
SELECT u.email, w.name as workspace_name, n.name as namespace_name, wu.role
FROM workspace_users wu
JOIN users u ON u.id = wu.user_id
JOIN workspaces w ON w.id = wu.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE wu.role = 'admin'
ORDER BY n.name, w.name, u.email;

-- Namespace switches in last 90 days
SELECT al.user_id, u.email, al.entity_name, al.created_at
FROM audit_logs al
LEFT JOIN users u ON u.id = al.user_id
WHERE al.entity_type = 'user_sessions'
AND al.created_at > now() - interval '90 days'
ORDER BY al.created_at DESC;
```

Save results as `GIS-SOC2-AR-{quarter}-{year}.json`.

**Review questions:**
1. Does every platform admin still need that access?
2. Does every namespace admin still work for that organization?
3. Are there any workspace admins who should be downgraded to editor?
4. Are namespace switches consistent with support activity?

---

## Evidence File Structure

Every evidence JSON file has this structure:

```json
{
  "evidence_metadata": {
    "document_id": "GIS-SOC2-EV-{seq}",
    "document_title": "SOC2 Type II Monthly Evidence Snapshot",
    "evidence_type": "Continuous Monitoring",
    "trust_criteria": ["CC6.1", "CC6.2", "CC6.6", "CC7.1", "C1.1", "A1.2"],
    "collection_method": "Automated RPC: generate_soc2_evidence()",
    "collected_by": "Stuart Holtby (Platform Admin)",
    "collection_date": "YYYY-MM-DD",
    "collection_timestamp": "from report_generated_at",
    "environment": "Production",
    "platform": "GetInSync NextGen",
    "database_region": "ca-central-1 (Montreal, QC)",
    "audit_period_start": "2026-02-08",
    "audit_period_end": null,
    "snapshot_sequence": N,
    "notes": "Any observations or actions taken",
    "naming_convention": "GIS-SOC2-EV-{sequence}-{YYYY}-{MM}-{DD}.json",
    "next_collection_due": "YYYY-MM-DD"
  },
  "evidence_data": {
    "...RPC output goes here..."
  },
  "variance_from_previous": {
    "total_users": "+2 (19 → 21)",
    "total_rls_policies": "unchanged (282)",
    "total_audit_entries": "+847 (1 → 848)",
    "flags": ["None — all metrics within expected range"]
  }
}
```

---

## Key Metrics to Track Over Time

These metrics tell the SOC2 story month over month:

| Metric | Current (EV-002, Apr 9) | Expected Trend |
|--------|--------------------------|----------------|
| `total_tables` | 103 | Gradual increase (new features) |
| `tables_with_rls` | 103 | Must equal total_tables (100%) |
| `total_rls_policies` | 392 | Increases with tables |
| `total_users` | 25 | Grows with customers |
| `platform_admins` | 3 | Stable (changes = investigate) |
| `total_audit_entries` | 8,600 | Monotonically increasing |
| `audited_tables` | 52 | Increases with new business tables |
| `namespaces_by_region.ca` | 17 | Grows (all CA until US/EU customer) |
| `orphaned_*` | 0, 1, 0 | Must remain 0 — 1 orphaned workspace_user under investigation |

---

## Database Objects

| Object | Type | Purpose |
|--------|------|---------|
| `audit_logs` | Table | Append-only audit trail (SOC2 CC6.6) |
| `audit_log_trigger()` | Function | Generic trigger capturing INSERT/UPDATE/DELETE |
| `generate_soc2_evidence()` | RPC | Produces monthly evidence snapshot JSON |
| `search_audit_logs()` | RPC | Filtered audit log queries for review |
| `audit_log_cleanup()` | RPC | Retention management (365-day minimum enforced) |

### Triggers Attached (52 tables per EV-002)

Per `cc6_6_audit_logging.audited_tables` from the April 2026 evidence snapshot. See `soc2-evidence/GIS-SOC2-EV-002-2026-04-09.json` for the full list.

---

## Related Documents

| Document | Purpose |
|----------|---------|
| identity-security/soc2-evidence-index.md | Maps trust criteria to evidence sources |
| identity-security/security-posture-overview.md | Customer-facing security overview (sales collateral) |
| identity-security/rls-policy.md | Complete RLS policy documentation |
| identity-security/identity-security.md | Identity/security architecture (v1.2 — cleaned Feb 23) |
| MANIFEST.md | Master document index with status tags |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-08 | Initial skill. Audit logging deployed. Baseline snapshot EV-001 collected. Naming convention, collection procedure, variance analysis, and quarterly access review defined. |
| v1.1 | 2026-02-23 | Updated trigger coverage: 11 → 37 tables. Updated key metrics: 67 → 90 tables, 282 → 347 RLS policies. Updated identity-security.md reference (v1.2 cleaned). |
| v1.2 | 2026-03-04 | Stats updated: 92 tables (was 90), 357 RLS (was 347), 50 triggers (was 48). Added application_categories + application_category_assignments to Core Business triggers. |
| v1.3 | 2026-04-09 | EV-002 collected. Stats updated: 103 tables, 392 RLS, 52 audited tables, 25 users, 8,600 audit entries. Created soc2-evidence/ repo directory. Archived EV-001 baseline. Condensed trigger list to reference evidence file. 1 orphaned workspace_user flagged. |

---

*Document: identity-security/soc2-evidence-collection.md*  
*SOC2 Controls: CC6.1, CC6.2, CC6.6, CC7.1, C1.1, A1.2*  
*April 2026*
