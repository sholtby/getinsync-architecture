-- ============================================================
-- COR Demo Data — Roadmap Seed (Phase 3)
-- ============================================================
-- Purpose: Restore roadmap data lost during cor-demo-data-reset.
--          Phase 2 rebuilt apps/DPs/services/tech but omitted
--          findings, initiatives, ideas, programs, and dependencies.
--
-- Run:     Supabase SQL Editor (Stuart)
-- Prereq:  Phase 2 insert must already be applied (apps, DPs, services exist)
-- Idempotent: ON CONFLICT DO NOTHING on all inserts
-- ============================================================

-- Namespace guard — abort if COR namespace UUID doesn't match
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM namespaces WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  ) THEN
    RAISE EXCEPTION 'COR namespace not found — aborting';
  END IF;
END $$;

-- ============================================================
-- Phase 3a: Contacts (7 fictional COR staff)
-- ============================================================
-- UUID pattern: b8000001-0000-0000-0000-000000000001 (trailing mirrors entity number)

INSERT INTO contacts (id, namespace_id, primary_workspace_id, display_name, job_title, department, email, contact_category, workspace_role)
VALUES
  -- IT Department
  ('b8000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'J. Martinez', 'IT Director', 'Information Technology',
   'j.martinez@riverside.example.gov', 'internal', 'admin'),
  ('b8000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'M. Davis', 'Help Desk Lead', 'Information Technology',
   'm.davis@riverside.example.gov', 'internal', 'steward'),
  ('b8000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'K. Patel', 'Desktop Support Lead', 'Information Technology',
   'k.patel@riverside.example.gov', 'internal', 'editor'),
  -- Finance
  ('b8000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0003-0000-0000-000000000003', 'T. Wong', 'Finance Director', 'Finance',
   't.wong@riverside.example.gov', 'internal', 'admin'),
  -- Public Works
  ('b8000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0012-0000-0000-000000000012', 'J. Smith', 'Field Ops Manager', 'Public Works',
   'j.smith@riverside.example.gov', 'internal', 'steward'),
  -- Community Development
  ('b8000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0011-0000-0000-000000000011', 'R. Chen', 'Permits Supervisor', 'Community Development',
   'r.chen@riverside.example.gov', 'internal', 'steward'),
  ('b8000007-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0011-0000-0000-000000000011', 'A. Lee', 'Senior Planner', 'Community Development',
   'a.lee@riverside.example.gov', 'internal', 'editor')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Phase 3b: Findings (8 records)
-- ============================================================
-- UUID pattern: b9000001-0000-0000-0000-000000000001

INSERT INTO findings (id, namespace_id, workspace_id, assessment_domain, impact, title, rationale, source_type)
VALUES
  -- ti findings (Technology Infrastructure)
  ('b9000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'high',
   'RHEL 7 End of Support — SirsiDynix Symphony at Risk',
   'SirsiDynix Symphony runs on RHEL 7 which reached end of maintenance support. No security patches available, creating unmitigated vulnerability exposure for the library system.',
   'computed'),

  ('b9000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'medium',
   'Oracle 19c Entering Extended Support Window',
   'Oracle Database 19c enters extended support in 2025. While patches remain available, costs increase significantly and migration planning should begin for Oracle 23ai or alternative platforms.',
   'computed'),

  ('b9000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'medium',
   'SQL Server 2016 Approaching End of Support',
   'SQL Server 2016 extended support ends July 2026. Cayenta Financials and other critical systems depend on this platform. Migration to SQL Server 2022 required before EOS date.',
   'computed'),

  -- bpa findings (Business Process Alignment)
  ('b9000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0003-0000-0000-000000000003', 'bpa', 'high',
   'ERP System Cannot Scale Beyond Current Operations',
   'Microsoft Dynamics GP has reached functional limits for multi-jurisdiction billing. Finance team uses manual workarounds for inter-fund transfers and county billing reconciliation.',
   'manual'),

  ('b9000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0006-0000-0000-000000000006', 'bpa', 'medium',
   'Redundant Systems in Public Safety',
   'Police department operates overlapping CAD and RMS systems with manual data re-entry between Hexagon OnCall and legacy records management. Consolidation opportunity identified.',
   'manual'),

  -- cr finding (Cyber Risk)
  ('b9000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'cr', 'high',
   'No Formal Vulnerability Management Program',
   'The city lacks a structured vulnerability scanning and remediation program. Patching is reactive and inconsistent across departments. No SLA for critical vulnerability remediation.',
   'manual'),

  -- icoms finding (IT Cost & Ops Maturity)
  ('b9000007-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'icoms', 'medium',
   'IT Governance Limited to Operational Support',
   'IT department operates in a reactive, break-fix mode with no formal strategic planning process. Technology decisions are made ad hoc without alignment to city business objectives.',
   'manual'),

  -- dqa finding (Data Quality & Architecture)
  ('b9000008-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'dqa', 'low',
   'Asset Inventory Partially Maintained',
   'IT asset inventory exists in ServiceDesk Plus but is only partially maintained. Hardware assets are tracked but software licensing and cloud subscriptions lack systematic inventory.',
   'manual')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Phase 3c: Initiatives (6 records)
-- ============================================================
-- UUID pattern: ba000001-0000-0000-0000-000000000001

INSERT INTO initiatives (
  id, namespace_id, workspace_id, assessment_domain, strategic_theme, priority,
  title, description,
  one_time_cost_low, one_time_cost_high, recurring_cost_low, recurring_cost_high,
  estimated_run_rate_change, run_rate_change_rationale,
  source_finding_id, owner_contact_id,
  status, time_horizon,
  target_start_date, target_end_date
)
VALUES
  -- 1. SirsiDynix Infrastructure Upgrade (Risk/Critical)
  ('ba000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'risk', 'critical',
   'Upgrade SirsiDynix Symphony Infrastructure',
   'Migrate SirsiDynix Symphony from end-of-life RHEL 7 to RHEL 8. Includes OS upgrade, application compatibility testing, and cutover planning for library services.',
   25000, 45000, 3000, 3000,
   3000, 'Annual RHEL 8 subscription replaces unsupported RHEL 7 — net new cost',
   'b9000001-0000-0000-0000-000000000001', 'b8000001-0000-0000-0000-000000000001',
   'planned', 'q1',
   '2026-07-01', '2026-09-30'),

  -- 2. SQL Server Migration (Risk/High)
  ('ba000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'risk', 'high',
   'Migrate SQL Server 2016 to 2022',
   'Upgrade SQL Server cluster from 2016 to 2022 before July 2026 EOS. Impacts Cayenta Financials, Questica Budget, and other Finance systems. Requires application compatibility validation.',
   18000, 28000, 0, 0,
   0, 'License cost neutral — SA covers upgrade. No run rate change.',
   'b9000003-0000-0000-0000-000000000003', 'b8000001-0000-0000-0000-000000000001',
   'planned', 'q1',
   '2026-04-01', '2026-06-30'),

  -- 3. Vulnerability Management Program (Risk/Critical)
  ('ba000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'cr', 'risk', 'critical',
   'Implement Vulnerability Management Program',
   'Deploy Tenable Nessus for continuous vulnerability scanning. Establish remediation SLAs: critical within 48h, high within 7d, medium within 30d. Train IT staff on triage and patch management.',
   10000, 20000, 10000, 10000,
   10000, 'Annual Tenable Nessus licensing + dedicated staff time for scanning program',
   'b9000006-0000-0000-0000-000000000006', 'b8000001-0000-0000-0000-000000000001',
   'in_progress', 'q1',
   '2026-03-01', '2026-06-30'),

  -- 4. Oracle Migration Planning (Optimize/Medium)
  ('ba000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'ti', 'optimize', 'medium',
   'Plan Oracle 19c to 23ai Migration Path',
   'Evaluate migration from Oracle 19c to Oracle 23ai or PostgreSQL. Extended support cost increase makes this a cost optimization opportunity. Requires vendor consultation and PoC.',
   40000, 80000, -15000, -15000,
   -15000, 'Eliminating Oracle extended support premium saves ~$15K/yr if migrated to PostgreSQL',
   'b9000002-0000-0000-0000-000000000002', 'b8000001-0000-0000-0000-000000000001',
   'identified', 'q3',
   '2027-01-01', '2027-12-31'),

  -- 5. IT Strategic Planning (Optimize/Medium)
  ('ba000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001', 'icoms', 'optimize', 'medium',
   'Establish IT Strategic Planning Process',
   'Create formal IT governance framework with annual strategic planning cycle, project intake process, and alignment to city business objectives. Includes stakeholder workshops and roadmap development.',
   5000, 12000, 0, 0,
   0, 'Staff time only — no new tooling required',
   'b9000007-0000-0000-0000-000000000007', 'b8000001-0000-0000-0000-000000000001',
   'identified', 'q2',
   '2026-07-01', '2026-12-31'),

  -- 6. ERP Replacement (Growth/High)
  ('ba000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0003-0000-0000-000000000003', 'bpa', 'growth', 'high',
   'ERP Evaluation and Replacement',
   'Replace Microsoft Dynamics GP with modern cloud ERP. County billing contract expires Dec 2027, requiring multi-jurisdiction billing capability. RFP, vendor selection, implementation, and data migration.',
   150000, 300000, 15000, 15000,
   15000, 'Cloud ERP SaaS licensing exceeds current Dynamics GP on-prem cost by ~$15K/yr, offset by reduced DBA effort',
   'b9000004-0000-0000-0000-000000000004', 'b8000002-0000-0000-0000-000000000002',
   'planned', 'q2',
   '2026-06-01', '2027-06-30')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Phase 3d: Ideas (6 records)
-- ============================================================
-- UUID pattern: bb000001-0000-0000-0000-000000000001

INSERT INTO ideas (
  id, namespace_id, workspace_id, title, description,
  assessment_domain, submitted_by_contact_id, status,
  review_notes, promoted_to_initiative_id
)
VALUES
  ('bb000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0012-0000-0000-000000000012',
   'Mobile app for field inspectors',
   'Field inspectors currently use paper forms and re-enter data at the office. A mobile app with offline capability would eliminate duplicate entry and speed up inspection turnaround.',
   'bpa', 'b8000003-0000-0000-0000-000000000003', 'submitted',
   NULL, NULL),

  ('bb000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0011-0000-0000-000000000011',
   'Replace fax with digital forms',
   'Community Development still receives permit applications by fax. Digital intake forms would reduce processing time and improve record accuracy.',
   NULL, 'b8000004-0000-0000-0000-000000000004', 'submitted',
   NULL, NULL),

  ('bb000003-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001',
   'Consolidate help desk tools',
   'IT currently uses ServiceDesk Plus for ticketing but has shadow tools in several departments. Consolidating to a single ITSM platform would improve visibility and SLA tracking.',
   'icoms', 'b8000005-0000-0000-0000-000000000005', 'submitted',
   NULL, NULL),

  ('bb000004-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0011-0000-0000-000000000011',
   'Citizen portal for building permits',
   'Citizens should be able to submit building permit applications online, track status, and receive approvals digitally instead of visiting City Hall.',
   'bpa', 'b8000007-0000-0000-0000-000000000007', 'under_review',
   NULL, NULL),

  -- Approved idea — promoted to ERP initiative
  ('bb000005-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0003-0000-0000-000000000003',
   'ERP evaluation',
   'Current ERP (Dynamics GP) cannot handle multi-jurisdiction billing needed for county contract renewal. Recommend formal evaluation of modern cloud ERP platforms.',
   'bpa', 'b8000002-0000-0000-0000-000000000002', 'approved',
   'Approved — promoted to initiative. County billing contract deadline makes this urgent.',
   'ba000006-0000-0000-0000-000000000006'),

  -- Declined idea
  ('bb000006-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001',
   'Replace all desktops with iPads',
   'Proposal to replace all desktop workstations with iPads to reduce hardware costs and improve mobility.',
   'ti', 'b8000006-0000-0000-0000-000000000006', 'declined',
   'Declined — most city staff require desktop applications (Dynamics GP, ArcGIS, CAD) that are not available on iPad. Selective tablet deployment already underway for field staff.',
   NULL)
ON CONFLICT (id) DO NOTHING;

-- Now that ideas exist, link the promoted idea to the ERP initiative
UPDATE initiatives
SET source_idea_id = 'bb000005-0000-0000-0000-000000000005'
WHERE id = 'ba000006-0000-0000-0000-000000000006'
  AND source_idea_id IS NULL;

-- ============================================================
-- Phase 3e: Programs (2 records)
-- ============================================================
-- UUID pattern: bc000001-0000-0000-0000-000000000001

INSERT INTO programs (
  id, namespace_id, workspace_id, title, description,
  strategic_theme, business_driver, budget_amount, budget_fiscal_year,
  target_start_date, target_end_date, status, owner_contact_id
)
VALUES
  ('bc000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0001-0000-0000-000000000001',
   'Infrastructure Stabilization',
   'Address critical technology debt identified through assessment findings. Board mandate to reduce high-risk infrastructure exposure by end of FY2027.',
   'risk', 'Board mandate: reduce critical tech debt by FY27',
   200000, 'FY2026-27',
   '2026-04-01', '2027-06-30', 'active',
   'b8000001-0000-0000-0000-000000000001'),

  ('bc000002-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'a1b2c3d4-0003-0000-0000-000000000003',
   'Digital Transformation 2026',
   'Strategic investment in modern platforms to replace aging systems. Driven by county billing contract expiration in Dec 2027 and need for scalable digital services.',
   'growth', 'County billing contract expires Dec 2027',
   500000, 'FY2026-27',
   '2026-06-01', '2027-12-31', 'active',
   'b8000002-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Phase 3f: Program-Initiatives junction (6 rows)
-- ============================================================

INSERT INTO program_initiatives (id, program_id, initiative_id, notes)
VALUES
  -- Infrastructure Stabilization: 4 initiatives
  (gen_random_uuid(), 'bc000001-0000-0000-0000-000000000001', 'ba000001-0000-0000-0000-000000000001',
   'SirsiDynix RHEL 7 → 8 upgrade'),
  (gen_random_uuid(), 'bc000001-0000-0000-0000-000000000001', 'ba000002-0000-0000-0000-000000000002',
   'SQL Server 2016 → 2022 migration'),
  (gen_random_uuid(), 'bc000001-0000-0000-0000-000000000001', 'ba000003-0000-0000-0000-000000000003',
   'Vulnerability management program standup'),
  (gen_random_uuid(), 'bc000001-0000-0000-0000-000000000001', 'ba000004-0000-0000-0000-000000000004',
   'Oracle migration planning and PoC'),

  -- Digital Transformation 2026: 2 initiatives
  (gen_random_uuid(), 'bc000002-0000-0000-0000-000000000002', 'ba000006-0000-0000-0000-000000000006',
   'ERP replacement — primary program driver'),
  (gen_random_uuid(), 'bc000002-0000-0000-0000-000000000002', 'ba000005-0000-0000-0000-000000000005',
   'Strategic planning framework for technology decisions')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Phase 3g: Initiative Dependencies (4 rows = 2 bidirectional pairs)
-- ============================================================

INSERT INTO initiative_dependencies (id, source_initiative_id, target_initiative_id, dependency_type, notes)
VALUES
  -- ERP Replacement requires SQL Server Upgrade
  (gen_random_uuid(),
   'ba000006-0000-0000-0000-000000000006', 'ba000002-0000-0000-0000-000000000002',
   'requires', 'New ERP version requires SQL Server 2022 — upgrade must complete before ERP migration begins'),
  -- SQL Server Upgrade enables ERP Replacement (inverse)
  (gen_random_uuid(),
   'ba000002-0000-0000-0000-000000000002', 'ba000006-0000-0000-0000-000000000006',
   'enables', 'SQL Server 2022 upgrade unblocks ERP platform migration'),

  -- Oracle Migration requires IT Strategic Planning
  (gen_random_uuid(),
   'ba000004-0000-0000-0000-000000000004', 'ba000005-0000-0000-0000-000000000005',
   'requires', 'Need strategy framework before committing to Oracle exit — PostgreSQL vs Oracle 23ai decision'),
  -- IT Strategic Planning enables Oracle Migration (inverse)
  (gen_random_uuid(),
   'ba000005-0000-0000-0000-000000000005', 'ba000004-0000-0000-0000-000000000004',
   'enables', 'Strategic planning process will inform Oracle migration direction')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Phase 3h: Initiative-Deployment-Profiles junction
-- ============================================================
-- Phase 2 DP UUIDs use trailing mirror pattern: b6000001-...-000000000001

INSERT INTO initiative_deployment_profiles (id, initiative_id, deployment_profile_id, relationship_type, notes)
VALUES
  -- SirsiDynix upgrade → impacts SirsiDynix Symphony DP
  (gen_random_uuid(), 'ba000001-0000-0000-0000-000000000001', 'b500001f-0000-0000-0000-00000000001f',
   'modernized', 'SirsiDynix Symphony RHEL 7 → 8 OS upgrade'),
  -- SirsiDynix upgrade → impacts Windows Server Farm (RHEL VMs co-hosted)
  (gen_random_uuid(), 'ba000001-0000-0000-0000-000000000001', 'b6000001-0000-0000-0000-000000000001',
   'impacted', 'RHEL VMs hosted on shared Windows Server infrastructure'),

  -- SQL Server migration → impacts SQL Server Cluster
  (gen_random_uuid(), 'ba000002-0000-0000-0000-000000000002', 'b6000002-0000-0000-0000-000000000002',
   'modernized', 'SQL Server 2016 → 2022 in-place upgrade'),
  -- SQL Server migration → impacts Cayenta DP
  (gen_random_uuid(), 'ba000002-0000-0000-0000-000000000002', 'b5000010-0000-0000-0000-000000000010',
   'impacted', 'Cayenta requires SQL Server compatibility validation'),
  -- SQL Server migration → impacts Questica DP
  (gen_random_uuid(), 'ba000002-0000-0000-0000-000000000002', 'b5000011-0000-0000-0000-000000000011',
   'impacted', 'Questica Budget runs on SQL Server'),

  -- Vuln management → impacts Security Appliances
  (gen_random_uuid(), 'ba000003-0000-0000-0000-000000000003', 'b6000007-0000-0000-0000-000000000007',
   'modernized', 'Tenable Nessus scanner deployment on security infrastructure'),

  -- Oracle migration → impacts Oracle RAC
  (gen_random_uuid(), 'ba000004-0000-0000-0000-000000000004', 'b6000003-0000-0000-0000-000000000003',
   'modernized', 'Oracle 19c → 23ai or PostgreSQL migration'),

  -- ERP replacement → impacts Dynamics GP DP
  (gen_random_uuid(), 'ba000006-0000-0000-0000-000000000006', 'b500000f-0000-0000-0000-00000000000f',
   'replaced', 'Dynamics GP deployment profile will be retired after ERP migration'),
  -- ERP replacement → impacts Cayenta DP
  (gen_random_uuid(), 'ba000006-0000-0000-0000-000000000006', 'b5000010-0000-0000-0000-000000000010',
   'impacted', 'Cayenta integration with ERP must be re-evaluated')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Phase 3i: Initiative-IT-Services junction
-- ============================================================
-- Phase 2 IT Service UUIDs: b4000001-...-000000000001

INSERT INTO initiative_it_services (id, initiative_id, it_service_id, relationship_type, notes)
VALUES
  -- SirsiDynix upgrade → Windows Server Hosting
  (gen_random_uuid(), 'ba000001-0000-0000-0000-000000000001', 'b4000001-0000-0000-0000-000000000001',
   'impacted', 'RHEL 7 VM hosted on Windows Server infrastructure'),

  -- SQL Server migration → SQL Server Database Services
  (gen_random_uuid(), 'ba000002-0000-0000-0000-000000000002', 'b4000003-0000-0000-0000-000000000003',
   'enhanced', 'Upgrading the core SQL Server platform to 2022'),

  -- Vuln management → Cybersecurity Operations
  (gen_random_uuid(), 'ba000003-0000-0000-0000-000000000003', 'b4000007-0000-0000-0000-000000000007',
   'enhanced', 'Adding vulnerability scanning capability to security operations'),

  -- Oracle migration → Oracle Database Services
  (gen_random_uuid(), 'ba000004-0000-0000-0000-000000000004', 'b4000004-0000-0000-0000-000000000004',
   'impacted', 'Migration may retire Oracle DB service entirely'),

  -- IT Strategic Planning → ITSM Platform
  (gen_random_uuid(), 'ba000005-0000-0000-0000-000000000005', 'b4000009-0000-0000-0000-000000000009',
   'enhanced', 'Strategic planning will formalize ITSM processes and governance'),

  -- ERP replacement → SQL Server Database Services (dependency)
  (gen_random_uuid(), 'ba000006-0000-0000-0000-000000000006', 'b4000003-0000-0000-0000-000000000003',
   'dependent', 'New ERP requires SQL Server 2022 — dependency on platform upgrade')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Verification queries
-- ============================================================
SELECT 'contacts' AS entity, count(*) AS count FROM contacts WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' AND id::text LIKE 'b8%'
UNION ALL
SELECT 'findings', count(*) FROM findings WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'initiatives', count(*) FROM initiatives WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'ideas', count(*) FROM ideas WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'programs', count(*) FROM programs WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'program_initiatives', count(*) FROM program_initiatives pi
  JOIN programs p ON pi.program_id = p.id WHERE p.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'initiative_dependencies', count(*) FROM initiative_dependencies id
  JOIN initiatives i ON id.source_initiative_id = i.id WHERE i.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'initiative_dps', count(*) FROM initiative_deployment_profiles idp
  JOIN initiatives i ON idp.initiative_id = i.id WHERE i.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'initiative_services', count(*) FROM initiative_it_services iis
  JOIN initiatives i ON iis.initiative_id = i.id WHERE i.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY entity;

-- Expected:
-- contacts             | 7
-- findings             | 8
-- ideas                | 6
-- initiative_dps       | 9   (added SirsiDynix DP link)
-- initiative_services  | 6
-- initiative_dependencies | 4
-- initiatives          | 6
-- program_initiatives  | 6
-- programs             | 2
