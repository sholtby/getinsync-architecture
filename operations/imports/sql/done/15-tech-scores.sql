-- ============================================================================
-- Script 15: Tech Scores Validation
-- Records: 0 (T-scores already set in script 07)
-- Purpose: Validation-only script confirming T-scores from script 07
-- ============================================================================

-- No INSERT or UPDATE — T-scores (t01..t10) and tech_assessment_status
-- were populated in the deployment_profiles INSERT in script 07.
-- This script exists solely to verify that data is present and correct.

-- ============================================================================
-- Validation: All DPs with their T-scores
-- ============================================================================

SELECT
  dp.name,
  dp.t01, dp.t02, dp.t03, dp.t05, dp.t07, dp.t09, dp.t10,
  dp.tech_assessment_status
FROM deployment_profiles dp
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY dp.name;
