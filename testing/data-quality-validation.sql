-- =============================================================================
-- GetInSync NextGen — Data Quality Validation
-- =============================================================================
-- Version: 1.0
-- Date:    March 3, 2026
-- Purpose: Detect data-level inconsistencies that schema constraints miss.
--          Catches enum casing mismatches, placeholder values, and naming
--          convention violations.
-- Trigger: End of any session where data was seeded/migrated, or as a
--          periodic health check.
-- Usage:   Paste into Supabase SQL Editor, or run via psql:
--          psql "$DATABASE_READONLY_URL" -f testing/data-quality-validation.sql
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 1: Assessment Status Values
-- Both tech and business assessment status must be snake_case:
--   'not_started' | 'in_progress' | 'complete'
-- Bug found 2026-03-03: portfolio_assignments had 'Not Started' (title-case)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 1a: portfolio_assignments.business_assessment_status' AS check_name,
       business_assessment_status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM portfolio_assignments
WHERE business_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
  AND business_assessment_status IS NOT NULL
GROUP BY business_assessment_status

UNION ALL

SELECT 'CHECK 1a: portfolio_assignments.business_assessment_status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM portfolio_assignments
  WHERE business_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
    AND business_assessment_status IS NOT NULL
);

SELECT 'CHECK 1b: deployment_profiles.tech_assessment_status' AS check_name,
       tech_assessment_status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE tech_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
  AND tech_assessment_status IS NOT NULL
GROUP BY tech_assessment_status

UNION ALL

SELECT 'CHECK 1b: deployment_profiles.tech_assessment_status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE tech_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
    AND tech_assessment_status IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 2: Deployment Profile Naming Convention
-- Primary DPs (is_primary = true) should follow: "{App Name} - {Env} - {Region}"
-- Bug found 2026-03-03: 47 DPs had name = app name (no env/region suffix)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 2a: Primary DP name = app name (missing env/region suffix)' AS check_name,
       dp.name AS dp_name,
       a.name AS app_name,
       dp.environment,
       dp.region
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
WHERE dp.is_primary = true
  AND dp.name = a.name
LIMIT 20;

SELECT 'CHECK 2b: Primary DP name missing " - " separator' AS check_name,
       dp.name AS dp_name,
       a.name AS app_name
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
WHERE dp.is_primary = true
  AND dp.name NOT LIKE '% - %'
LIMIT 20;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 3: Placeholder Values in Required Fields
-- Region, environment, and other fields should not have placeholder values
-- Bug found 2026-03-03: 14 DPs had region = 'UNKNOWN' or empty string
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 3a: deployment_profiles.region placeholders' AS check_name,
       region AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE region IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
  OR (region IS NOT NULL AND trim(region) = '')
GROUP BY region

UNION ALL

SELECT 'CHECK 3a: deployment_profiles.region placeholders',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE region IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
    OR (region IS NOT NULL AND trim(region) = '')
);

SELECT 'CHECK 3b: deployment_profiles.environment placeholders' AS check_name,
       environment AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE environment IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
  OR (environment IS NOT NULL AND trim(environment) = '')
GROUP BY environment

UNION ALL

SELECT 'CHECK 3b: deployment_profiles.environment placeholders',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE environment IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
    OR (environment IS NOT NULL AND trim(environment) = '')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 4: Operational Status Consistency
-- deployment_profiles: 'operational' | 'non-operational' (hyphen, not underscore)
-- applications: 'operational' | 'pipeline' | 'retired'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 4a: deployment_profiles.operational_status' AS check_name,
       operational_status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE operational_status NOT IN ('operational', 'non-operational')
  AND operational_status IS NOT NULL
GROUP BY operational_status

UNION ALL

SELECT 'CHECK 4a: deployment_profiles.operational_status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE operational_status NOT IN ('operational', 'non-operational')
    AND operational_status IS NOT NULL
);

SELECT 'CHECK 4b: applications.operational_status' AS check_name,
       operational_status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM applications
WHERE operational_status NOT IN ('operational', 'pipeline', 'retired')
  AND operational_status IS NOT NULL
GROUP BY operational_status

UNION ALL

SELECT 'CHECK 4b: applications.operational_status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM applications
  WHERE operational_status NOT IN ('operational', 'pipeline', 'retired')
    AND operational_status IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 5: Lifecycle Status Values
-- applications.lifecycle_status: 'Mainstream' | 'Extended' | 'End of Support'
-- (Title-case with spaces — intentionally NOT snake_case for this column)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 5: applications.lifecycle_status' AS check_name,
       lifecycle_status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM applications
WHERE lifecycle_status NOT IN ('Mainstream', 'Extended', 'End of Support')
  AND lifecycle_status IS NOT NULL
GROUP BY lifecycle_status

UNION ALL

SELECT 'CHECK 5: applications.lifecycle_status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM applications
  WHERE lifecycle_status NOT IN ('Mainstream', 'Extended', 'End of Support')
    AND lifecycle_status IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 6: Remediation Effort Casing
-- Should be uppercase: 'XS' | 'S' | 'M' | 'L' | 'XL' | '2XL'
-- Multiple tables use this — check all of them
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 6a: deployment_profiles.remediation_effort' AS check_name,
       remediation_effort AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
  AND remediation_effort IS NOT NULL
GROUP BY remediation_effort

UNION ALL

SELECT 'CHECK 6a: deployment_profiles.remediation_effort',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
    AND remediation_effort IS NOT NULL
);

SELECT 'CHECK 6b: portfolio_assignments.remediation_effort' AS check_name,
       remediation_effort AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM portfolio_assignments
WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
  AND remediation_effort IS NOT NULL
GROUP BY remediation_effort

UNION ALL

SELECT 'CHECK 6b: portfolio_assignments.remediation_effort',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM portfolio_assignments
  WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
    AND remediation_effort IS NOT NULL
);

SELECT 'CHECK 6c: applications.remediation_effort' AS check_name,
       remediation_effort AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM applications
WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
  AND remediation_effort IS NOT NULL
GROUP BY remediation_effort

UNION ALL

SELECT 'CHECK 6c: applications.remediation_effort',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM applications
  WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
    AND remediation_effort IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 7: PAID Action Casing
-- Canonical lowercase enum: 'plan' | 'address' | 'ignore' | 'delay'
-- (2026-04-18: 'improve' and 'divest' removed — they were never the real PAID labels)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 7: deployment_profiles.paid_action' AS check_name,
       paid_action AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE paid_action NOT IN ('plan', 'address', 'ignore', 'delay')
  AND paid_action IS NOT NULL
GROUP BY paid_action

UNION ALL

SELECT 'CHECK 7: deployment_profiles.paid_action',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE paid_action NOT IN ('plan', 'address', 'ignore', 'delay')
    AND paid_action IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 8: Hosting Type Values
-- 'SaaS' | 'Third-Party-Hosted' | 'Cloud' | 'On-Prem' | 'Hybrid' | 'Desktop'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 8: deployment_profiles.hosting_type' AS check_name,
       hosting_type AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE hosting_type NOT IN ('SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop')
  AND hosting_type IS NOT NULL
GROUP BY hosting_type

UNION ALL

SELECT 'CHECK 8: deployment_profiles.hosting_type',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE hosting_type NOT IN ('SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop')
    AND hosting_type IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 9: Namespace Tier Values
-- 'trial' | 'essentials' | 'plus' | 'enterprise'
-- NEVER 'free' | 'pro' | 'full' (per CLAUDE.md)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 9: namespaces.tier' AS check_name,
       tier AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM namespaces
WHERE tier NOT IN ('trial', 'essentials', 'plus', 'enterprise')
  AND tier IS NOT NULL
GROUP BY tier

UNION ALL

SELECT 'CHECK 9: namespaces.tier',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM namespaces
  WHERE tier NOT IN ('trial', 'essentials', 'plus', 'enterprise')
    AND tier IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 10: Contact Category Values
-- 'internal' | 'external' | 'vendor_rep'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 10: contacts.contact_category' AS check_name,
       contact_category AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM contacts
WHERE contact_category NOT IN ('internal', 'external', 'vendor_rep')
  AND contact_category IS NOT NULL
GROUP BY contact_category

UNION ALL

SELECT 'CHECK 10: contacts.contact_category',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM contacts
  WHERE contact_category NOT IN ('internal', 'external', 'vendor_rep')
    AND contact_category IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 11: Initiative / Idea / Program Status Values
-- initiatives: 'identified' | 'planned' | 'in_progress' | 'completed' | 'deferred' | 'cancelled'
-- ideas: 'submitted' | 'under_review' | 'approved' | 'declined' | 'deferred'
-- programs: 'draft' | 'active' | 'completed' | 'cancelled'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 11a: initiatives.status' AS check_name,
       status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM initiatives
WHERE status NOT IN ('identified', 'planned', 'in_progress', 'completed', 'deferred', 'cancelled')
  AND status IS NOT NULL
GROUP BY status

UNION ALL

SELECT 'CHECK 11a: initiatives.status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM initiatives
  WHERE status NOT IN ('identified', 'planned', 'in_progress', 'completed', 'deferred', 'cancelled')
    AND status IS NOT NULL
);

SELECT 'CHECK 11b: ideas.status' AS check_name,
       status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ideas
WHERE status NOT IN ('submitted', 'under_review', 'approved', 'declined', 'deferred')
  AND status IS NOT NULL
GROUP BY status

UNION ALL

SELECT 'CHECK 11b: ideas.status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM ideas
  WHERE status NOT IN ('submitted', 'under_review', 'approved', 'declined', 'deferred')
    AND status IS NOT NULL
);

SELECT 'CHECK 11c: programs.status' AS check_name,
       status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM programs
WHERE status NOT IN ('draft', 'active', 'completed', 'cancelled')
  AND status IS NOT NULL
GROUP BY status

UNION ALL

SELECT 'CHECK 11c: programs.status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM programs
  WHERE status NOT IN ('draft', 'active', 'completed', 'cancelled')
    AND status IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 12: Integration Status Values
-- 'planned' | 'active' | 'deprecated' | 'retired'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 12: application_integrations.status' AS check_name,
       status AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM application_integrations
WHERE status NOT IN ('planned', 'active', 'deprecated', 'retired')
  AND status IS NOT NULL
GROUP BY status

UNION ALL

SELECT 'CHECK 12: application_integrations.status',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM application_integrations
  WHERE status NOT IN ('planned', 'active', 'deprecated', 'retired')
    AND status IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 13: DP Type Values
-- 'application' | 'platform_tenant' | 'infrastructure' | 'cost_bundle'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 13: deployment_profiles.dp_type' AS check_name,
       dp_type AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM deployment_profiles
WHERE dp_type NOT IN ('application', 'platform_tenant', 'infrastructure', 'cost_bundle')
  AND dp_type IS NOT NULL
GROUP BY dp_type

UNION ALL

SELECT 'CHECK 13: deployment_profiles.dp_type',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM deployment_profiles
  WHERE dp_type NOT IN ('application', 'platform_tenant', 'infrastructure', 'cost_bundle')
    AND dp_type IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHECK 14: Role Values Across Tables
-- namespace_users.role / users.namespace_role: 'admin' | 'editor' | 'steward' | 'viewer' | 'restricted'
-- workspace_users.role: 'admin' | 'editor' | 'viewer'
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'CHECK 14a: namespace_users.role' AS check_name,
       role AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM namespace_users
WHERE role NOT IN ('admin', 'editor', 'steward', 'viewer', 'restricted')
  AND role IS NOT NULL
GROUP BY role

UNION ALL

SELECT 'CHECK 14a: namespace_users.role',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM namespace_users
  WHERE role NOT IN ('admin', 'editor', 'steward', 'viewer', 'restricted')
    AND role IS NOT NULL
);

SELECT 'CHECK 14b: workspace_users.role' AS check_name,
       role AS bad_value,
       count(*) AS row_count,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM workspace_users
WHERE role NOT IN ('admin', 'editor', 'viewer')
  AND role IS NOT NULL
GROUP BY role

UNION ALL

SELECT 'CHECK 14b: workspace_users.role',
       '(all valid)', 0, 'PASS'
WHERE NOT EXISTS (
  SELECT 1 FROM workspace_users
  WHERE role NOT IN ('admin', 'editor', 'viewer')
    AND role IS NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- SUMMARY: Quick All-Checks Overview
-- Run this last for a single-glance pass/fail summary
-- ─────────────────────────────────────────────────────────────────────────────

SELECT '=== DATA QUALITY SUMMARY ===' AS check_name, '' AS detail, '' AS result

UNION ALL

-- Assessment status
SELECT 'Assessment: business_assessment_status',
       coalesce(
         (SELECT string_agg(DISTINCT business_assessment_status, ', ')
          FROM portfolio_assignments
          WHERE business_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
            AND business_assessment_status IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM portfolio_assignments
         WHERE business_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
           AND business_assessment_status IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Assessment: tech_assessment_status',
       coalesce(
         (SELECT string_agg(DISTINCT tech_assessment_status, ', ')
          FROM deployment_profiles
          WHERE tech_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
            AND tech_assessment_status IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM deployment_profiles
         WHERE tech_assessment_status NOT IN ('not_started', 'in_progress', 'complete')
           AND tech_assessment_status IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- DP naming
SELECT 'DP naming: name = app name',
       coalesce(
         (SELECT count(*)::text FROM deployment_profiles dp
          JOIN applications a ON a.id = dp.application_id
          WHERE dp.is_primary = true AND dp.name = a.name),
         '0') || ' violations',
       CASE WHEN EXISTS (
         SELECT 1 FROM deployment_profiles dp
         JOIN applications a ON a.id = dp.application_id
         WHERE dp.is_primary = true AND dp.name = a.name
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- Region placeholders
SELECT 'Placeholders: dp.region',
       coalesce(
         (SELECT string_agg(DISTINCT region, ', ')
          FROM deployment_profiles
          WHERE region IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
            OR (region IS NOT NULL AND trim(region) = '')),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM deployment_profiles
         WHERE region IN ('UNKNOWN', 'Unknown', 'unknown', 'N/A', 'n/a', 'TBD', 'tbd', '')
           OR (region IS NOT NULL AND trim(region) = '')
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- Tier values
SELECT 'Tier: namespaces.tier',
       coalesce(
         (SELECT string_agg(DISTINCT tier, ', ')
          FROM namespaces
          WHERE tier NOT IN ('trial', 'essentials', 'plus', 'enterprise')
            AND tier IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM namespaces
         WHERE tier NOT IN ('trial', 'essentials', 'plus', 'enterprise')
           AND tier IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- Remediation effort casing
SELECT 'Casing: remediation_effort (dp)',
       coalesce(
         (SELECT string_agg(DISTINCT remediation_effort, ', ')
          FROM deployment_profiles
          WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
            AND remediation_effort IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM deployment_profiles
         WHERE remediation_effort NOT IN ('XS', 'S', 'M', 'L', 'XL', '2XL')
           AND remediation_effort IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- PAID action casing
SELECT 'Casing: paid_action',
       coalesce(
         (SELECT string_agg(DISTINCT paid_action, ', ')
          FROM deployment_profiles
          WHERE paid_action NOT IN ('plan', 'address', 'ignore', 'delay')
            AND paid_action IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM deployment_profiles
         WHERE paid_action NOT IN ('plan', 'address', 'ignore', 'delay')
           AND paid_action IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

-- Roles
SELECT 'Roles: namespace_users',
       coalesce(
         (SELECT string_agg(DISTINCT role, ', ')
          FROM namespace_users
          WHERE role NOT IN ('admin', 'editor', 'steward', 'viewer', 'restricted')
            AND role IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM namespace_users
         WHERE role NOT IN ('admin', 'editor', 'steward', 'viewer', 'restricted')
           AND role IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Roles: workspace_users',
       coalesce(
         (SELECT string_agg(DISTINCT role, ', ')
          FROM workspace_users
          WHERE role NOT IN ('admin', 'editor', 'viewer')
            AND role IS NOT NULL),
         '(clean)'),
       CASE WHEN EXISTS (
         SELECT 1 FROM workspace_users
         WHERE role NOT IN ('admin', 'editor', 'viewer')
           AND role IS NOT NULL
       ) THEN 'FAIL' ELSE 'PASS' END

ORDER BY check_name;

-- =============================================================================
-- END OF DATA QUALITY VALIDATION
-- Expected: All checks show PASS. Any FAIL requires investigation.
-- =============================================================================
