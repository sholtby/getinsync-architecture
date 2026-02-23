-- =============================================================================
-- GetInSync NextGen - Demo Namespace Setup Template
-- Version: 2.0
-- Last Updated: 2026-01-29
-- =============================================================================
-- 
-- CHANGELOG v2.0:
-- - Added Section 5B: Organizations (CRITICAL - was missing!)
-- - Updated Section 8: Assessment guidance (NULL vs 0, remediation thresholds)
-- - Enhanced Section 9: Full cost attribution example
-- - Updated Section 12: Verification includes organizations
-- - Added Section 13: Troubleshooting guide
-- - Based on lessons from Riverside Police Department demo (2026-01-29)
--
-- INSTRUCTIONS:
-- 1. Create auth user in Supabase Dashboard first (Authentication → Users → Add User)
-- 2. Find/replace the following placeholders:
--    - __NAMESPACE_ID__     → Your namespace UUID (e.g., 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
--    - __USER_ID__          → Auth user UUID from Supabase Dashboard
--    - __USER_EMAIL__       → User email (e.g., 'demo@getinsync.ca')
--    - __NAMESPACE_NAME__   → Display name (e.g., 'City of Riverside (Demo)')
--    - __NAMESPACE_SLUG__   → URL slug (e.g., 'city-of-riverside-demo')
-- 3. Run each section in order
-- 4. Add your custom workspaces, apps, etc. using the patterns shown
--
-- =============================================================================

-- =============================================================================
-- SECTION 1: NAMESPACE + USER SETUP
-- =============================================================================

-- 1a. Create namespace
INSERT INTO namespaces (id, name, slug, tier, created_at, updated_at)
VALUES ('__NAMESPACE_ID__', '__NAMESPACE_NAME__', '__NAMESPACE_SLUG__', 'enterprise', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

-- 1b. Create users record (MUST include namespace_role = 'admin' for full menu)
INSERT INTO users (id, namespace_id, email, namespace_role, created_at, updated_at)
VALUES ('__USER_ID__', '__NAMESPACE_ID__', '__USER_EMAIL__', 'admin', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET namespace_role = 'admin', updated_at = NOW();

-- 1c. Add user to namespace_users
INSERT INTO namespace_users (namespace_id, user_id, role)
VALUES ('__NAMESPACE_ID__', '__USER_ID__', 'admin')
ON CONFLICT (namespace_id, user_id) DO NOTHING;

-- 1d. Create organization settings (required for Settings UI)
INSERT INTO organization_settings (namespace_id, name, max_project_budget, created_at, updated_at)
VALUES ('__NAMESPACE_ID__', '__NAMESPACE_NAME__', 1000000, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 2: WORKSPACES (Disable triggers first!)
-- =============================================================================

-- 2a. Disable triggers
ALTER TABLE workspaces DISABLE TRIGGER add_workspace_creator_trigger;
ALTER TABLE workspace_users DISABLE TRIGGER enforce_workspace_user_namespace;

-- 2b. Create workspaces (customize this list)
INSERT INTO workspaces (id, namespace_id, name, slug, created_at, updated_at) VALUES
-- IT workspace (commonly owns software products and IT services)
('__NAMESPACE_ID__-0001', '__NAMESPACE_ID__', 'Information Technology', 'information-technology', NOW(), NOW()),
-- Add your workspaces here following the pattern:
-- ('__NAMESPACE_ID__-XXXX', '__NAMESPACE_ID__', 'Workspace Name', 'workspace-slug', NOW(), NOW()),
('__NAMESPACE_ID__-0002', '__NAMESPACE_ID__', 'Human Resources', 'human-resources', NOW(), NOW()),
('__NAMESPACE_ID__-0003', '__NAMESPACE_ID__', 'Finance', 'finance', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

-- 2c. Add user to all workspaces
INSERT INTO workspace_users (workspace_id, user_id, role)
SELECT id, '__USER_ID__', 'admin'
FROM workspaces 
WHERE namespace_id = '__NAMESPACE_ID__'
ON CONFLICT (workspace_id, user_id) DO NOTHING;

-- 2d. Re-enable triggers
ALTER TABLE workspaces ENABLE TRIGGER add_workspace_creator_trigger;
ALTER TABLE workspace_users ENABLE TRIGGER enforce_workspace_user_namespace;

-- =============================================================================
-- SECTION 3: APPLICATIONS + DEPLOYMENT PROFILES
-- =============================================================================
-- 
-- For each application:
-- 1. Insert application record
-- 2. Insert deployment profile record
-- 
-- Hosting type options: 'SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop'
-- Region: Use 'Canada Central' for cloud, 'N/A (Vendor Managed)' for on-prem
--
-- Pattern:
-- INSERT INTO applications (id, workspace_id, name, description, annual_cost, lifecycle_status, created_at, updated_at)
-- VALUES ('APP_UUID', 'WORKSPACE_UUID', 'App Name', 'Description', COST, 'Mainstream', NOW(), NOW());
-- 
-- INSERT INTO deployment_profiles (id, application_id, workspace_id, name, hosting_type, region, is_primary, created_at, updated_at)
-- VALUES ('DP_UUID', 'APP_UUID', 'WORKSPACE_UUID', 'App Name', 'SaaS', 'Canada Central', true, NOW(), NOW());

-- Example: SaaS Application
INSERT INTO applications (id, workspace_id, name, description, annual_cost, lifecycle_status, created_at, updated_at)
VALUES ('b0000001-0000-0000-0000-000000000001', '__NAMESPACE_ID__-0003', 'Workday HCM', 'Enterprise HR and financials', 500000, 'Mainstream', NOW(), NOW());
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, hosting_type, region, is_primary, created_at, updated_at)
VALUES ('d0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', '__NAMESPACE_ID__-0003', 'Workday HCM', 'SaaS', 'Canada Central', true, NOW(), NOW());

-- Example: On-Prem Application
INSERT INTO applications (id, workspace_id, name, description, annual_cost, lifecycle_status, created_at, updated_at)
VALUES ('b0000002-0000-0000-0000-000000000002', '__NAMESPACE_ID__-0001', 'Legacy ERP', 'On-premise ERP system', 250000, 'Mainstream', NOW(), NOW());
INSERT INTO deployment_profiles (id, application_id, workspace_id, name, hosting_type, region, is_primary, created_at, updated_at)
VALUES ('d0000002-0000-0000-0000-000000000002', 'b0000002-0000-0000-0000-000000000002', '__NAMESPACE_ID__-0001', 'Legacy ERP', 'On-Prem', 'N/A (Vendor Managed)', true, NOW(), NOW());

-- ADD YOUR APPLICATIONS HERE...

-- =============================================================================
-- SECTION 4: PORTFOLIO ASSIGNMENTS (CRITICAL - Apps won't show without this!)
-- =============================================================================

-- Portfolios are auto-created by trigger (named "Core")
-- This assigns all DPs to their workspace's Core portfolio

INSERT INTO portfolio_assignments (portfolio_id, application_id, deployment_profile_id)
SELECT p.id, dp.application_id, dp.id
FROM deployment_profiles dp
JOIN workspaces w ON dp.workspace_id = w.id
JOIN portfolios p ON p.workspace_id = w.id AND p.name = 'Core'
WHERE w.namespace_id = '__NAMESPACE_ID__'
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 5: SOFTWARE PRODUCTS (Optional)
-- =============================================================================
-- 
-- Software products are typically owned by IT workspace
-- No description column - just name and cost
--
-- Pattern:
-- INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, manufacturer_org_id, license_type, annual_cost, created_at, updated_at)
-- VALUES ('UUID', '__NAMESPACE_ID__', 'IT_WORKSPACE_UUID', 'Product Name', 'MANUFACTURER_ORG_UUID', 'subscription', COST, NOW(), NOW());

-- Example:
INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, annual_cost, created_at, updated_at) VALUES
('c0000001-0000-0000-0000-000000000001', '__NAMESPACE_ID__', '__NAMESPACE_ID__-0001', 'Microsoft 365', 500000, NOW(), NOW()),
('c0000002-0000-0000-0000-000000000002', '__NAMESPACE_ID__', '__NAMESPACE_ID__-0001', 'Adobe Creative Cloud', 50000, NOW(), NOW());

-- ADD YOUR SOFTWARE PRODUCTS HERE...

-- =============================================================================
-- SECTION 5B: ORGANIZATIONS (Vendors, Manufacturers, Partners) - NEW IN v2.0!
-- =============================================================================
-- 
-- *** CRITICAL: Set is_shared = true for cross-workspace visibility! ***
-- Without this, organizations won't show in Settings → Vendors & Partners
-- across all workspaces in the namespace.
--
-- Organization types (boolean flags):
--   is_vendor: TRUE if organization sells to you (e.g., CDW, SHI, Dell)
--   is_manufacturer: TRUE if organization makes the product (e.g., Microsoft, Oracle, SAP)
--   is_msp: TRUE if organization provides managed services
--   is_partner: TRUE if strategic partner relationship
--   is_internal: TRUE for internal departments acting as service providers
--   is_government: TRUE for government entities
--   is_shared: TRUE for cross-workspace visibility (REQUIRED FOR DEMO!)
--
-- Vendor vs Manufacturer distinction:
--   - Manufacturer goes on software_products table (who makes it)
--   - Vendor goes on deployment_profile_software_products junction (who you buy from)
--   - Same org can be both (e.g., Microsoft sells directly and through resellers)
--
-- Pattern:
-- INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_shared, created_at, updated_at)
-- VALUES ('ORG_UUID', '__NAMESPACE_ID__', 'Organization Name', true, false, true, NOW(), NOW());

-- Example: Software vendors (resellers)
INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_shared, created_at, updated_at) VALUES
('o0000001-0000-0000-0000-000000000001', '__NAMESPACE_ID__', 'CDW Government', true, false, true, NOW(), NOW()),
('o0000002-0000-0000-0000-000000000002', '__NAMESPACE_ID__', 'SHI International', true, false, true, NOW(), NOW()),
('o0000003-0000-0000-0000-000000000003', '__NAMESPACE_ID__', 'Dell Technologies', true, true, true, NOW(), NOW())  -- Both vendor and manufacturer
ON CONFLICT (id) DO UPDATE SET is_shared = true, updated_at = NOW();  -- Force is_shared = true

-- Example: Manufacturers (software creators)
INSERT INTO organizations (id, namespace_id, name, is_vendor, is_manufacturer, is_shared, created_at, updated_at) VALUES
('o0000004-0000-0000-0000-000000000004', '__NAMESPACE_ID__', 'Microsoft Corporation', true, true, true, NOW(), NOW()),  -- Sells direct too
('o0000005-0000-0000-0000-000000000005', '__NAMESPACE_ID__', 'Oracle Corporation', true, true, true, NOW(), NOW()),
('o0000006-0000-0000-0000-000000000006', '__NAMESPACE_ID__', 'SAP SE', false, true, true, NOW(), NOW())  -- Only manufacturer
ON CONFLICT (id) DO UPDATE SET is_shared = true, updated_at = NOW();

-- Example: Managed Service Providers
INSERT INTO organizations (id, namespace_id, name, is_vendor, is_msp, is_shared, created_at, updated_at) VALUES
('o0000007-0000-0000-0000-000000000007', '__NAMESPACE_ID__', 'Accenture Technology Services', true, true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET is_shared = true, updated_at = NOW();

-- Link organizations to software products (as manufacturers):
-- UPDATE software_products 
-- SET manufacturer_org_id = 'o0000004-0000-0000-0000-000000000004'  -- Microsoft
-- WHERE id = 'c0000001-0000-0000-0000-000000000001';  -- Microsoft 365

-- ADD YOUR ORGANIZATIONS HERE...

-- =============================================================================
-- SECTION 6: IT SERVICES (Optional)
-- =============================================================================
-- 
-- IT services typically owned by IT workspace
-- cost_model: 'fixed', 'per_user', 'per_instance', 'consumption', 'tiered'
-- lifecycle_state: 'operational'
--
-- Pattern:
-- INSERT INTO it_services (id, namespace_id, owner_workspace_id, name, description, annual_cost, cost_model, lifecycle_state, created_at, updated_at)
-- VALUES ('UUID', '__NAMESPACE_ID__', 'IT_WORKSPACE_UUID', 'Service Name', 'Description', COST, 'cost_model', 'operational', NOW(), NOW());

-- Example:
INSERT INTO it_services (id, namespace_id, owner_workspace_id, name, description, annual_cost, cost_model, lifecycle_state, created_at, updated_at) VALUES
('e0000001-0000-0000-0000-000000000001', '__NAMESPACE_ID__', '__NAMESPACE_ID__-0001', 'Azure Cloud Hosting', 'Microsoft Azure infrastructure', 500000, 'consumption', 'operational', NOW(), NOW()),
('e0000002-0000-0000-0000-000000000002', '__NAMESPACE_ID__', '__NAMESPACE_ID__-0001', 'Help Desk Services', 'Tier 1-2 IT support', 150000, 'per_user', 'operational', NOW(), NOW());

-- ADD YOUR IT SERVICES HERE...

-- =============================================================================
-- SECTION 7: LINK IT SERVICES TO CATALOG (Required for catalog display)
-- =============================================================================
-- 
-- IT services must have service_type_id to show in IT Service Catalog
-- First, check available service_types for your namespace:
-- SELECT id, name FROM service_types WHERE namespace_id = '__NAMESPACE_ID__';

-- Example (replace with actual service_type UUIDs):
-- UPDATE it_services SET service_type_id = 'SERVICE_TYPE_UUID' WHERE id = 'IT_SERVICE_UUID';

-- =============================================================================
-- SECTION 8: ASSESSMENT DATA (Optional but recommended for demos)
-- =============================================================================
-- 
-- *** CRITICAL ASSESSMENT ARCHITECTURE ***
-- T-scores (t01-t15) live on deployment_profiles table
-- B-scores (b1-b10) live on portfolio_assignments table
-- 
-- T-scores (t01-t15): 1=Poor, 5=Excellent → tech_health auto-calculated
-- B-scores (b1-b10): 1=Poor, 5=Excellent → business_fit NOT auto-calculated (must calculate manually!)
-- time_quadrant: NOT auto-calculated, must set manually
--
-- Pattern for MODERNIZE app (critical system, aging tech):
-- UPDATE deployment_profiles SET
--   t01=2, t02=2, t03=2, t04=3, t05=2, t06=2, t07=3, t08=2, t09=2, t10=3,
--   t11=2, t12=2, t13=3, t14=2, t15=2,
--   tech_assessment_status = 'complete',
--   estimated_tech_debt = 500000,
--   tech_debt_description = 'Windows Server 2012 EOL, Oracle 11g upgrade required'
-- WHERE id = 'DP_UUID';
--
-- NOTE: DO NOT manually set remediation_effort! UI calculates it from estimated_tech_debt
--
-- Pattern for INVEST app (modern SaaS, NO tech debt):
-- UPDATE deployment_profiles SET
--   t01=5, t02=5, t03=5, t04=5, t05=5, t06=5, t07=5, t08=5, t09=5, t10=5,
--   t11=5, t12=5, t13=5, t14=5, t15=5,
--   tech_assessment_status = 'complete',
--   estimated_tech_debt = NULL,           -- NULL for modern apps with no debt!
--   tech_debt_description = NULL
-- WHERE id = 'DP_UUID';
--
-- *** IMPORTANT: Remediation effort threshold calculation ***
-- The UI calculates remediation sizing from organization_settings.max_project_budget:
--   XS: 0-2.5% of budget (e.g., $0-$25K for $1M budget)
--   S: 2.5%-10% ($25K-$100K)
--   M: 10%-25% ($100K-$250K)
--   L: 25%-50% ($250K-$500K)
--   XL: 50%-100% ($500K-$1M)  ← NOTE: $500K is the START of XL (not end of L)
--   2XL: >100% (>$1M)
--
-- Set estimated_tech_debt, let UI calculate remediation_effort automatically.
-- DO NOT manually set remediation_effort unless you want to override the calculation!
-- DO NOT seed assessment_thresholds table with remediation_effort rows - they're unused!

-- After setting T-scores, update B-scores and calculate business_fit:
-- UPDATE portfolio_assignments SET
--   b1=5, b2=5, b3=5, b4=5, b5=5, b6=5, b7=4, b8=5, b9=5, b10=5,
--   business_assessment_status = 'complete',
--   business_fit = ((5+5+5+5+5+5+4+5+5+5 - 10.0) / 40.0) * 100,
--   criticality = ((5+5+5+5+5+5+4+5+5+5 - 10.0) / 40.0) * 100,
--   time_quadrant = 'Invest'  -- Invest/Modernize/Tolerate/Eliminate
-- WHERE deployment_profile_id = 'DP_UUID';

-- Bulk set time_quadrant for all assessed apps:
-- UPDATE portfolio_assignments pa
-- SET time_quadrant = CASE 
--     WHEN dp.tech_health >= 50 AND pa.business_fit >= 50 THEN 'Invest'
--     WHEN dp.tech_health < 50 AND pa.business_fit >= 50 THEN 'Modernize'
--     WHEN dp.tech_health >= 50 AND pa.business_fit < 50 THEN 'Tolerate'
--     ELSE 'Eliminate'
--   END
-- FROM deployment_profiles dp
-- WHERE pa.deployment_profile_id = dp.id
-- AND dp.workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__');

-- =============================================================================
-- SECTION 9: COST DATA (Three Channels)
-- =============================================================================
-- 
-- Cost attribution happens through three channels:
-- 1. Cost Bundles - Recurring costs (licenses, support contracts)
-- 2. Software Product Links - Shared software allocation
-- 3. IT Service Allocations - Infrastructure dependencies
--
-- Channel 1: COST BUNDLES (Recurring Costs)
-- Create cost_bundle DPs - these show as "Recurring Costs" in UI
--
-- INSERT INTO deployment_profiles 
--   (id, application_id, workspace_id, name, dp_type, cost_recurrence, annual_cost, is_primary, created_at)
-- VALUES
--   (gen_random_uuid(), 'APP_UUID', 'WORKSPACE_UUID', 'App Name - Annual License', 'cost_bundle', 'recurring', 100000, false, NOW());

-- Channel 2: SOFTWARE PRODUCT LINKS
-- Link apps to shared software products with vendor attribution
--
-- INSERT INTO deployment_profile_software_products 
--   (deployment_profile_id, software_product_id, vendor_org_id, annual_cost, allocation_percent, notes, created_at)
-- VALUES
--   ('DP_UUID', 'SP_UUID', 'VENDOR_ORG_UUID', 28000, 25, 'VMware hosting via CDW', NOW());

-- Channel 3: IT SERVICE ALLOCATIONS
-- Link apps to IT services (relationship_type: 'depends_on' or 'built_on')
-- allocation_basis: 'percent' (value ≤ 100) or 'fixed' (dollar amount)
--
-- INSERT INTO deployment_profile_it_services 
--   (deployment_profile_id, it_service_id, relationship_type, allocation_basis, allocation_value, notes, created_at)
-- VALUES
--   ('DP_UUID', 'ITS_UUID', 'depends_on', 'percent', 35, 'Primary hosting', NOW());

-- =============================================================================
-- EXAMPLE: Full Cost Attribution with Vendor
-- =============================================================================
-- This shows how to attribute costs to a deployment profile from all three channels
-- with proper vendor/manufacturer distinction.
--
-- Scenario: Police CAD/RMS system with $1.2M total cost breakdown:
--   - Software license: $485K (manufacturer: Hexagon AB, vendor: Hexagon direct sales)
--   - Oracle hosting: $144K (35% allocation of IT Service with $412K total cost)
--   - Maintenance: $446K (annual support contract, recurring cost bundle)
--
-- Step 1: Create the application and deployment profile (already done in Section 3)
-- INSERT INTO applications (id, workspace_id, name, description, lifecycle_status, created_at)
-- VALUES ('app-cad-rms', 'ws-police', 'CAD/RMS System', '911 dispatch and records management', 'Mainstream', NOW());
-- 
-- INSERT INTO deployment_profiles (id, application_id, workspace_id, name, hosting_type, region, is_primary, created_at)
-- VALUES ('dp-cad-rms', 'app-cad-rms', 'ws-police', 'CAD/RMS System', 'On-Prem', 'N/A (Vendor Managed)', true, NOW());

-- Step 2: Create software product (owned by IT workspace, manufactured by Hexagon)
-- INSERT INTO software_products (id, namespace_id, owner_workspace_id, name, manufacturer_org_id, license_type, created_at)
-- VALUES 
--   ('sp-cad-rms', '__NAMESPACE_ID__', '__NAMESPACE_ID__-0001', 'Hexagon OnCall CAD/RMS', 'o-hexagon-ab', 'subscription', NOW());

-- Step 3: Link to deployment profile via junction (with vendor attribution)
-- INSERT INTO deployment_profile_software_products 
--   (deployment_profile_id, software_product_id, vendor_org_id, annual_cost, allocation_percent, notes, created_at)
-- VALUES
--   ('dp-cad-rms', 'sp-cad-rms', 'o-hexagon-ab', 485000, 100, 'Direct from Hexagon Public Safety', NOW());

-- Step 4: Link to IT Service (Oracle hosting at 35% allocation)
-- INSERT INTO deployment_profile_it_services 
--   (deployment_profile_id, it_service_id, relationship_type, allocation_basis, allocation_value, notes, created_at)
-- VALUES
--   ('dp-cad-rms', 'its-oracle-hosting', 'depends_on', 'percent', 35, 'Oracle 11g database hosting', NOW());
-- If IT Service has $412K cost and DP takes 35%, that's $144,200

-- Step 5: Add cost bundle for maintenance (recurring annual contract)
-- INSERT INTO deployment_profiles 
--   (id, application_id, workspace_id, name, dp_type, cost_recurrence, annual_cost, vendor_org_id, is_primary, created_at)
-- VALUES
--   (gen_random_uuid(), 'app-cad-rms', 'ws-police', 'CAD/RMS - Annual Maintenance', 'cost_bundle', 'recurring', 446000, 'o-hexagon-ab', false, NOW());

-- Result: vw_deployment_profile_costs will show total cost
-- (Software $485K + IT Service allocation ~$144K + Maintenance $446K = ~$1,075K)

-- =============================================================================
-- SECTION 10: CONTACTS
-- =============================================================================
-- 
-- contact_category: 'internal', 'external', 'vendor_rep'
-- role_type: 'business_owner', 'technical_owner', 'steward', 'sponsor', 'sme', 'support', 'vendor_rep', 'other'
--
-- Create contacts:
-- INSERT INTO contacts (id, namespace_id, primary_workspace_id, display_name, job_title, department, email, contact_category, is_active, created_at)
-- VALUES
--   (gen_random_uuid(), '__NAMESPACE_ID__', 'WORKSPACE_UUID', 'Jane Smith', 'IT Manager', 'IT Division', 'jane.smith@example.gov', 'internal', true, NOW());
--
-- Assign to applications:
-- INSERT INTO application_contacts (application_id, contact_id, role_type, is_primary, created_at)
-- VALUES
--   ('APP_UUID', 'CONTACT_UUID', 'business_owner', true, NOW());

-- =============================================================================
-- SECTION 11: CLEANUP (if needed)
-- =============================================================================

-- Delete auto-created duplicate DPs (trigger creates "— Region-PROD" versions)
DELETE FROM deployment_profiles 
WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
AND name LIKE '%— Region-PROD';

-- =============================================================================
-- SECTION 12: VERIFICATION
-- =============================================================================

SELECT 
  'Workspaces' as entity, COUNT(*)::text as count FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__'
UNION ALL
SELECT 'Applications', COUNT(*)::text FROM applications WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
UNION ALL
SELECT 'Deployment Profiles', COUNT(*)::text FROM deployment_profiles WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
UNION ALL
SELECT 'Portfolio Assignments', COUNT(*)::text FROM portfolio_assignments pa JOIN portfolios p ON pa.portfolio_id = p.id JOIN workspaces w ON p.workspace_id = w.id WHERE w.namespace_id = '__NAMESPACE_ID__'
UNION ALL
SELECT 'Organizations', COUNT(*)::text FROM organizations WHERE namespace_id = '__NAMESPACE_ID__'
UNION ALL
SELECT 'Organizations (shared)', COUNT(*)::text FROM organizations WHERE namespace_id = '__NAMESPACE_ID__' AND is_shared = true
UNION ALL
SELECT 'Software Products', COUNT(*)::text FROM software_products WHERE namespace_id = '__NAMESPACE_ID__'
UNION ALL
SELECT 'IT Services', COUNT(*)::text FROM it_services WHERE namespace_id = '__NAMESPACE_ID__'
UNION ALL
SELECT 'Org Settings', COUNT(*)::text FROM organization_settings WHERE namespace_id = '__NAMESPACE_ID__';

-- Check user access
SELECT 
  u.email,
  u.namespace_role,
  (SELECT COUNT(*) FROM workspace_users wu WHERE wu.user_id = u.id) as workspace_count
FROM users u
WHERE u.id = '__USER_ID__';

-- Verify organization visibility (ALL should have is_shared = true for demo)
SELECT 
  o.name,
  o.is_vendor,
  o.is_manufacturer,
  o.is_shared,
  CASE WHEN o.is_shared THEN 'OK' ELSE '*** MISSING is_shared = true ***' END as status
FROM organizations o
WHERE o.namespace_id = '__NAMESPACE_ID__'
ORDER BY o.name;

-- =============================================================================
-- SECTION 13: TROUBLESHOOTING (NEW IN v2.0!)
-- =============================================================================

-- Issue: Apps not showing in dashboard
-- Fix: Check portfolio_assignments exist
SELECT 
  a.name as app_name, 
  dp.name as dp_name, 
  pa.id as assignment_id,
  CASE WHEN pa.id IS NULL THEN '*** MISSING ASSIGNMENT ***' ELSE 'OK' END as status
FROM applications a
JOIN deployment_profiles dp ON dp.application_id = a.id
LEFT JOIN portfolio_assignments pa ON pa.deployment_profile_id = dp.id
WHERE a.workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
ORDER BY a.name;
-- If any rows show MISSING ASSIGNMENT, run SECTION 4 again

-- Issue: Organizations not visible in Settings → Vendors & Partners
-- Fix: Ensure is_shared = true
UPDATE organizations 
SET is_shared = true
WHERE namespace_id = '__NAMESPACE_ID__'
AND is_shared = false;

-- Issue: Assessment scores not calculating correctly
-- Validate: T-scores on deployment_profiles, B-scores on portfolio_assignments
SELECT 
  'T-scores on deployment_profiles' as check_type,
  COUNT(*) as count
FROM deployment_profiles
WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
AND t01 IS NOT NULL
UNION ALL
SELECT 
  'B-scores on portfolio_assignments',
  COUNT(*)
FROM portfolio_assignments pa
JOIN portfolios p ON pa.portfolio_id = p.id
WHERE p.workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
AND pa.b1 IS NOT NULL;

-- Issue: Remediation effort showing "XS" for apps with NULL tech debt
-- Fix: Ensure estimated_tech_debt and remediation_effort are both NULL for modern apps
UPDATE deployment_profiles
SET 
  estimated_tech_debt = NULL,
  tech_debt_description = NULL
WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
AND estimated_tech_debt = 0;

-- Issue: Cost Analysis page showing no data
-- Verify: Check vw_deployment_profile_costs for the namespace
SELECT 
  a.name as app_name,
  dpc.total_cost,
  dpc.software_product_cost,
  dpc.it_service_cost,
  dpc.cost_bundle_cost
FROM vw_deployment_profile_costs dpc
JOIN deployment_profiles dp ON dp.id = dpc.deployment_profile_id
JOIN applications a ON a.id = dp.application_id
WHERE dp.workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '__NAMESPACE_ID__')
ORDER BY dpc.total_cost DESC
LIMIT 10;

-- Issue: Software Catalog showing products without manufacturers
-- Fix: Link manufacturer_org_id to software_products
SELECT 
  sp.name as product_name,
  o.name as manufacturer_name,
  CASE WHEN sp.manufacturer_org_id IS NULL THEN '*** MISSING MANUFACTURER ***' ELSE 'OK' END as status
FROM software_products sp
LEFT JOIN organizations o ON o.id = sp.manufacturer_org_id
WHERE sp.namespace_id = '__NAMESPACE_ID__'
ORDER BY sp.name;

-- Issue: IT Service Catalog empty or showing "(0)" for services
-- Fix: Set service_type_id on it_services
SELECT 
  its.name as service_name,
  st.name as service_type_name,
  CASE WHEN its.service_type_id IS NULL THEN '*** MISSING service_type_id ***' ELSE 'OK' END as status
FROM it_services its
LEFT JOIN service_types st ON st.id = its.service_type_id
WHERE its.namespace_id = '__NAMESPACE_ID__'
ORDER BY its.name;

-- =============================================================================
-- DONE! 
-- User can now log in and see all data.
-- If menu items missing, check:
--   1. organization_settings exists
--   2. users.namespace_role = 'admin'
--   3. organizations have is_shared = true
--
-- For issues, see SECTION 13: TROUBLESHOOTING above
-- =============================================================================
