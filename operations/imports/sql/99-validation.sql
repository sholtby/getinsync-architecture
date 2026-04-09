-- =============================================================================
-- Script 99: Post-Import Validation
-- Records: 0 (queries only)
-- Source: garland-showcase-demo-plan.md Validation Checklist
-- Purpose: Comprehensive validation of the Garland showcase import
-- =============================================================================

-- =========================================================================
-- 1. Record counts — expected values in comments
-- =========================================================================

SELECT 'namespaces' AS entity, count(*) AS actual, 1 AS expected
FROM namespaces WHERE name = 'City of Garland';

SELECT 'workspaces' AS entity, count(*) AS actual, 4 AS expected
FROM workspaces w
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'applications' AS entity, count(*) AS actual, 21 AS expected
FROM applications a
JOIN workspaces w ON w.id = a.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'deployment_profiles' AS entity, count(*) AS actual, 21 AS expected
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'it_services' AS entity, count(*) AS actual, 8 AS expected
FROM it_services its
JOIN namespaces n ON n.id = its.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'organizations' AS entity, count(*) AS actual, 21 AS expected
FROM organizations o
JOIN namespaces n ON n.id = o.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'contacts' AS entity, count(*) AS actual, 13 AS expected
FROM contacts c
JOIN namespaces n ON n.id = c.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'software_products' AS entity, count(*) AS actual, 17 AS expected
FROM software_products sp
JOIN namespaces n ON n.id = sp.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'technology_products' AS entity, count(*) AS actual, 7 AS expected
FROM technology_products tp
JOIN namespaces n ON n.id = tp.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'portfolios' AS entity, count(*) AS actual, 7 AS expected
FROM portfolios p
JOIN workspaces w ON w.id = p.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'portfolio_assignments' AS entity, count(*) AS actual, 21 AS expected
FROM portfolio_assignments pa
JOIN portfolios p ON p.id = pa.portfolio_id
JOIN workspaces w ON w.id = p.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'application_integrations' AS entity, count(*) AS actual, 16 AS expected
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
JOIN workspaces sw ON sw.id = sa.workspace_id
JOIN namespaces n ON n.id = sw.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'dp_software_products' AS entity, count(*) AS actual, 17 AS expected
FROM deployment_profile_software_products dpsp
JOIN deployment_profiles dp ON dp.id = dpsp.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'dp_technology_products' AS entity, count(*) AS actual, 21 AS expected
FROM deployment_profile_technology_products dptp
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN workspaces w ON w.id = dp.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'dp_it_services' AS entity, count(*) AS actual, 8 AS expected
FROM deployment_profile_it_services dis
JOIN it_services its ON its.id = dis.it_service_id
JOIN namespaces n ON n.id = its.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'it_service_software_products' AS entity, count(*) AS actual, 6 AS expected
FROM it_service_software_products issp
JOIN it_services its ON its.id = issp.it_service_id
JOIN namespaces n ON n.id = its.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'workspace_contacts' AS entity, count(*) AS actual, 5 AS expected
FROM workspace_contacts wc
JOIN workspaces w ON w.id = wc.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

SELECT 'portfolio_contacts' AS entity, count(*) AS actual, 3 AS expected
FROM portfolio_contacts pc
JOIN portfolios p ON p.id = pc.portfolio_id
JOIN workspaces w ON w.id = p.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland';

-- =========================================================================
-- 2. Cost model validation — the key test
-- =========================================================================

-- Run rate by vendor: Databank should show ~$511K consolidated
SELECT 'run_rate_by_vendor' AS test, vendor_name, cost_channel, total_cost
FROM vw_run_rate_by_vendor
WHERE namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
ORDER BY total_cost DESC;

-- IT Service cost totals: should sum to $3,331,550
SELECT 'it_service_total' AS test,
       count(*) AS service_count,
       sum(annual_cost) AS total_annual_cost
FROM it_services
WHERE namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland');

-- =========================================================================
-- 3. Dashboard summary — total_annual_cost should be $0 (costs on IT Services)
-- =========================================================================

SELECT 'dashboard_summary' AS test,
       total_annual_cost, total_applications, total_dps
FROM vw_dashboard_summary
WHERE namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland');

-- =========================================================================
-- 4. DP costs — service_cost populated, bundle_cost = 0
-- =========================================================================

SELECT dp.name,
       dpc.service_cost,
       dpc.bundle_cost,
       dpc.total_cost
FROM vw_deployment_profile_costs dpc
JOIN deployment_profiles dp ON dp.id = dpc.deployment_profile_id
WHERE dpc.application_id IN (
  SELECT a.id FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN namespaces n ON n.id = w.namespace_id
  WHERE n.name = 'City of Garland'
)
ORDER BY dpc.total_cost DESC;

-- =========================================================================
-- 5. Server names populated (expect 15 with servers, 6 without)
-- =========================================================================

SELECT dp.name, dp.server_name, dp.hosting_type,
       CASE WHEN dp.server_name IS NOT NULL THEN 'HAS_SERVER' ELSE 'NO_SERVER' END AS server_status
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland'
ORDER BY server_status, dp.name;

-- =========================================================================
-- 6. Technology tags — DP to technology product links
-- =========================================================================

SELECT a.name AS app, tp.name AS tech_product, dptp.edition
FROM deployment_profile_technology_products dptp
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
JOIN namespaces n ON n.id = w.namespace_id
WHERE n.name = 'City of Garland'
ORDER BY a.name, tp.name;

-- =========================================================================
-- 7. Cross-workspace integrations
-- =========================================================================

SELECT sa.name AS source_app, ta.name AS target_app, ai.direction,
       sw.name AS source_workspace, tw.name AS target_workspace,
       CASE WHEN sw.id != tw.id THEN 'CROSS-WORKSPACE' ELSE 'same-workspace' END AS scope
FROM application_integrations ai
JOIN applications sa ON sa.id = ai.source_application_id
JOIN applications ta ON ta.id = ai.target_application_id
JOIN workspaces sw ON sw.id = sa.workspace_id
JOIN workspaces tw ON tw.id = ta.workspace_id
JOIN namespaces n ON n.id = sw.namespace_id
WHERE n.name = 'City of Garland'
ORDER BY scope DESC, sa.name;

-- =========================================================================
-- 8. Apps per workspace — expect CSU=8, FB=4, POL=3, IT=6
-- =========================================================================

SELECT w.name AS workspace, count(a.id) AS app_count
FROM workspaces w
LEFT JOIN applications a ON a.workspace_id = w.id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
GROUP BY w.name
ORDER BY w.name;

-- =========================================================================
-- 9. Assessment coverage — T-scores and B-scores populated
-- =========================================================================

SELECT 'tech_assessed' AS metric,
       count(*) FILTER (WHERE dp.tech_assessment_status = 'in_progress') AS in_progress,
       count(*) FILTER (WHERE dp.tech_assessment_status = 'not_started') AS not_started,
       count(*) AS total
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland');

SELECT 'business_assessed' AS metric,
       count(*) FILTER (WHERE pa.business_assessment_status = 'in_progress') AS in_progress,
       count(*) FILTER (WHERE pa.business_assessment_status = 'Not Started') AS not_started,
       count(*) AS total
FROM portfolio_assignments pa
JOIN portfolios p ON p.id = pa.portfolio_id
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland');

-- =========================================================================
-- 10. Leadership contacts — workspace and portfolio assignments
-- =========================================================================

SELECT 'workspace_leaders' AS scope, w.name, c.display_name, wc.role_type
FROM workspace_contacts wc
JOIN workspaces w ON w.id = wc.workspace_id
JOIN contacts c ON c.id = wc.contact_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
ORDER BY w.name;

SELECT 'portfolio_leaders' AS scope, p.name, c.display_name, pc.role_type
FROM portfolio_contacts pc
JOIN portfolios p ON p.id = pc.portfolio_id
JOIN contacts c ON c.id = pc.contact_id
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
ORDER BY p.name;

-- =========================================================================
-- 11. Data quality flags
-- =========================================================================

-- Apps missing B-scores (expected: 8)
SELECT 'missing_b_scores' AS flag, a.name
FROM applications a
JOIN portfolio_assignments pa ON pa.application_id = a.id
JOIN portfolios p ON p.id = pa.portfolio_id
JOIN workspaces w ON w.id = p.workspace_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
  AND pa.business_assessment_status = 'Not Started'
ORDER BY a.name;

-- DPs with deprecated technology products (EOL risk)
SELECT 'eol_tech' AS flag, a.name AS app, tp.name AS tech_product
FROM deployment_profile_technology_products dptp
JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN technology_products tp ON tp.id = dptp.technology_product_id
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
WHERE w.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
  AND tp.is_deprecated = true
ORDER BY a.name, tp.name;

-- Vendor consolidation: vendors with multiple IT services
SELECT 'vendor_consolidation' AS flag,
       o.name AS vendor,
       count(its.id) AS service_count,
       sum(its.annual_cost) AS total_spend
FROM it_services its
JOIN organizations o ON o.id = its.vendor_org_id
WHERE its.namespace_id = (SELECT id FROM namespaces WHERE name = 'City of Garland')
GROUP BY o.name
HAVING count(its.id) > 1
ORDER BY total_spend DESC;
