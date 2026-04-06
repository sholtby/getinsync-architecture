-- =============================================================================
-- COR Demo Data — Police Workspace Assessments
-- =============================================================================
-- Seeds assessment scores on deployment_profiles (T-scores) and
-- portfolio_assignments (B-scores) where the UI actually reads them.
-- Also populates business_assessments and technical_assessments audit tables.
--
-- Scoring: 1-5 per factor, derived scores 0-100 via normalizeScore((raw-1)/4*100)
-- Derived scores computed using weights from src/lib/scoring.ts
--
-- TIME quadrant results:
--   Hexagon OnCall CAD/RMS  — Modernize (bf=75, th=32)  → critical but aging
--   Axon Evidence           — Invest    (bf=68, th=88)  → modern SaaS winner
--   Flock Safety LPR        — Invest    (bf=51, th=75)  → modern niche SaaS
--   Brazos eCitation        — Invest    (bf=51, th=73)  → modern focused SaaS
--   CopLogic Online Report  — Invest    (bf=51, th=60)  → adequate SaaS
--   Computer-Aided Dispatch — Modernize (bf=75, th=49)  → critical on-prem
--   NG911 System            — Invest    (bf=80, th=53)  → critical infra, borderline
--   Police Records Mgmt     — Modernize (bf=54, th=17)  → aging, replace candidate
--
-- Run in: Supabase SQL Editor
-- Prerequisites: Phase 2 INSERT complete, Police apps + DPs + PAs exist
-- =============================================================================


-- =============================================================================
-- 1. Deployment Profiles — T-scores (trigger auto-computes tech_health, tech_risk)
-- =============================================================================

-- Hexagon OnCall CAD/RMS — aging on-prem (th=32, tr=54, PAID=Address)
UPDATE deployment_profiles SET
  t01=2, t02=3, t03=2, t04=3, t05=3, t06=2, t07=2, t08=2, t09=1, t10=2, t11=3, t12=2, t13=2, t14=2,
  tech_assessment_status = 'complete', paid_action = 'Address'
WHERE id = 'b5000001-0000-0000-0000-000000000001';

-- Axon Evidence — modern SaaS (th=88, tr=4, PAID=Plan)
UPDATE deployment_profiles SET
  t01=5, t02=5, t03=4, t04=5, t05=5, t06=4, t07=4, t08=5, t09=4, t10=4, t11=5, t12=5, t13=4, t14=4,
  tech_assessment_status = 'complete', paid_action = 'Plan'
WHERE id = 'b5000002-0000-0000-0000-000000000002';

-- Flock Safety LPR — modern SaaS (th=75, tr=15, PAID=Ignore)
UPDATE deployment_profiles SET
  t01=4, t02=5, t03=4, t04=4, t05=5, t06=4, t07=3, t08=4, t09=4, t10=3, t11=4, t12=5, t13=3, t14=4,
  tech_assessment_status = 'complete', paid_action = 'Ignore'
WHERE id = 'b5000003-0000-0000-0000-000000000003';

-- Brazos eCitation — modern SaaS (th=73, tr=25, PAID=Ignore)
UPDATE deployment_profiles SET
  t01=4, t02=4, t03=4, t04=4, t05=4, t06=4, t07=4, t08=4, t09=4, t10=3, t11=4, t12=5, t13=3, t14=4,
  tech_assessment_status = 'complete', paid_action = 'Ignore'
WHERE id = 'b5000004-0000-0000-0000-000000000004';

-- CopLogic Online Reporting — adequate SaaS (th=60, tr=29, PAID=Ignore)
UPDATE deployment_profiles SET
  t01=3, t02=4, t03=3, t04=4, t05=4, t06=3, t07=3, t08=4, t09=3, t10=3, t11=4, t12=3, t13=3, t14=3,
  tech_assessment_status = 'complete', paid_action = 'Ignore'
WHERE id = 'b5000005-0000-0000-0000-000000000005';

-- Computer-Aided Dispatch — on-prem (th=49, tr=50, PAID=Address)
UPDATE deployment_profiles SET
  t01=3, t02=3, t03=3, t04=3, t05=3, t06=3, t07=3, t08=3, t09=2, t10=3, t11=3, t12=3, t13=3, t14=3,
  tech_assessment_status = 'complete', paid_action = 'Address'
WHERE id = 'b5000006-0000-0000-0000-000000000006';

-- NG911 System — specialized infra (th=53, tr=29, PAID=Plan)
UPDATE deployment_profiles SET
  t01=3, t02=4, t03=3, t04=4, t05=4, t06=3, t07=3, t08=3, t09=1, t10=2, t11=4, t12=3, t13=2, t14=3,
  tech_assessment_status = 'complete', paid_action = 'Plan'
WHERE id = 'b5000007-0000-0000-0000-000000000007';

-- Police Records Management — aging on-prem (th=17, tr=79, PAID=Address)
UPDATE deployment_profiles SET
  t01=2, t02=2, t03=1, t04=2, t05=2, t06=1, t07=2, t08=2, t09=1, t10=2, t11=2, t12=1, t13=2, t14=1,
  tech_assessment_status = 'complete', paid_action = 'Address'
WHERE id = 'b5000008-0000-0000-0000-000000000008';


-- =============================================================================
-- 2. Portfolio Assignments — B-scores + derived business_fit, criticality, time_quadrant
-- =============================================================================

-- Hexagon OnCall CAD/RMS — bf=75, crit=99, TIME=Modernize, PAID=Address
UPDATE portfolio_assignments SET
  b1=5, b2=4, b3=5, b4=5, b5=5, b6=5, b7=5, b8=3, b9=2, b10=3,
  business_fit = 75, criticality = 99,
  time_quadrant = 'Modernize',
  business_assessment_status = 'complete'
WHERE id = '89cc2b3e-29a0-4828-8d12-cd54ea3fb62f';

-- Axon Evidence — bf=68, crit=70, TIME=Invest
UPDATE portfolio_assignments SET
  b1=4, b2=3, b3=4, b4=3, b5=4, b6=4, b7=4, b8=4, b9=4, b10=4,
  business_fit = 68, criticality = 70,
  time_quadrant = 'Invest',
  business_assessment_status = 'complete'
WHERE id = '81a46c72-abab-4820-a420-e48a1dd6bd19';

-- Flock Safety LPR — bf=51, crit=46, TIME=Invest
UPDATE portfolio_assignments SET
  b1=3, b2=3, b3=3, b4=2, b5=3, b6=3, b7=3, b8=4, b9=3, b10=4,
  business_fit = 51, criticality = 46,
  time_quadrant = 'Invest',
  business_assessment_status = 'complete'
WHERE id = 'e547ba71-6742-4a25-88a8-1b553b987eec';

-- Brazos eCitation — bf=51, crit=44, TIME=Invest
UPDATE portfolio_assignments SET
  b1=3, b2=2, b3=3, b4=3, b5=3, b6=3, b7=2, b8=4, b9=3, b10=4,
  business_fit = 51, criticality = 44,
  time_quadrant = 'Invest',
  business_assessment_status = 'complete'
WHERE id = '25ed294d-18ad-497e-bb39-91773a619359';

-- CopLogic Online Reporting — bf=51, crit=45, TIME=Invest
UPDATE portfolio_assignments SET
  b1=3, b2=3, b3=4, b4=3, b5=3, b6=2, b7=2, b8=3, b9=3, b10=3,
  business_fit = 51, criticality = 45,
  time_quadrant = 'Invest',
  business_assessment_status = 'complete'
WHERE id = '943ccff6-9b08-4eff-9a54-164cc5110ba6';

-- Computer-Aided Dispatch — bf=75, crit=95, TIME=Modernize
UPDATE portfolio_assignments SET
  b1=5, b2=4, b3=5, b4=4, b5=5, b6=5, b7=5, b8=3, b9=3, b10=3,
  business_fit = 75, criticality = 95,
  time_quadrant = 'Modernize',
  business_assessment_status = 'complete'
WHERE id = 'e26e5e99-2def-4e65-865c-e370368c2a70';

-- NG911 System — bf=80, crit=95, TIME=Invest
UPDATE portfolio_assignments SET
  b1=5, b2=4, b3=5, b4=4, b5=5, b6=5, b7=5, b8=4, b9=3, b10=4,
  business_fit = 80, criticality = 95,
  time_quadrant = 'Invest',
  business_assessment_status = 'complete'
WHERE id = 'a29c77c8-f6f9-41e4-b763-80feb756bd99';

-- Police Records Management — bf=54, crit=74, TIME=Modernize
UPDATE portfolio_assignments SET
  b1=4, b2=3, b3=4, b4=4, b5=4, b6=4, b7=4, b8=2, b9=2, b10=2,
  business_fit = 54, criticality = 74,
  time_quadrant = 'Modernize',
  business_assessment_status = 'complete'
WHERE id = 'f6762e7e-61b5-4df0-bc16-5339df1746e0';


-- =============================================================================
-- 3. Business & Technical Assessment audit tables (already inserted, skip if exist)
-- =============================================================================

INSERT INTO business_assessments (
  application_id,
  b1_strategic_goals, b2_regional_growth, b3_public_confidence,
  b4_scope_of_use, b5_business_process, b6_interruption_tolerance,
  b7_essential_service, b8_current_needs, b9_future_needs, b10_user_satisfaction
) VALUES
  ('b1000001-0000-0000-0000-000000000001', 5, 4, 5, 5, 5, 5, 5, 3, 2, 3),
  ('b1000002-0000-0000-0000-000000000002', 4, 3, 4, 3, 4, 4, 4, 4, 4, 4),
  ('b1000003-0000-0000-0000-000000000003', 3, 3, 3, 2, 3, 3, 3, 4, 3, 4),
  ('b1000004-0000-0000-0000-000000000004', 3, 2, 3, 3, 3, 3, 2, 4, 3, 4),
  ('b1000005-0000-0000-0000-000000000005', 3, 3, 4, 3, 3, 2, 2, 3, 3, 3),
  ('b1000006-0000-0000-0000-000000000006', 5, 4, 5, 4, 5, 5, 5, 3, 3, 3),
  ('b1000007-0000-0000-0000-000000000007', 5, 4, 5, 4, 5, 5, 5, 4, 3, 4),
  ('b1000008-0000-0000-0000-000000000008', 4, 3, 4, 4, 4, 4, 4, 2, 2, 2)
ON CONFLICT (application_id) DO NOTHING;

INSERT INTO technical_assessments (
  application_id,
  t01_platform_footprint, t02_vendor_support, t03_dev_platform,
  t04_security_controls, t05_resilience_recovery, t06_observability,
  t07_integration_capabilities, t08_identity_assurance, t09_platform_portability,
  t10_configurability, t11_data_sensitivity_controls,
  t13_modern_ux, t14_integrations_count, t15_data_accessibility
) VALUES
  ('b1000001-0000-0000-0000-000000000001', 2, 3, 2, 3, 3, 2, 2, 2, 1, 2, 3, 2, 2, 2),
  ('b1000002-0000-0000-0000-000000000002', 5, 5, 4, 5, 5, 4, 4, 5, 4, 4, 5, 5, 4, 4),
  ('b1000003-0000-0000-0000-000000000003', 4, 5, 4, 4, 5, 4, 3, 4, 4, 3, 4, 5, 3, 4),
  ('b1000004-0000-0000-0000-000000000004', 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 5, 3, 4),
  ('b1000005-0000-0000-0000-000000000005', 3, 4, 3, 4, 4, 3, 3, 4, 3, 3, 4, 3, 3, 3),
  ('b1000006-0000-0000-0000-000000000006', 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3),
  ('b1000007-0000-0000-0000-000000000007', 3, 4, 3, 4, 4, 3, 3, 3, 1, 2, 4, 3, 2, 3),
  ('b1000008-0000-0000-0000-000000000008', 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1)
ON CONFLICT (application_id) DO NOTHING;


-- =============================================================================
-- 4. Verification
-- =============================================================================
SELECT a.name,
  dp.tech_health, dp.tech_risk, dp.tech_assessment_status, dp.paid_action,
  pa.business_fit, pa.criticality, pa.time_quadrant, pa.business_assessment_status
FROM applications a
JOIN workspaces w ON a.workspace_id = w.id
JOIN deployment_profiles dp ON dp.application_id = a.id AND dp.dp_type = 'application'
JOIN portfolio_assignments pa ON pa.deployment_profile_id = dp.id
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
AND w.name ILIKE '%police%'
ORDER BY a.name;
