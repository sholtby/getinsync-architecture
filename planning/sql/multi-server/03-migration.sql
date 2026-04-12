-- =============================================================================
-- 03-migration.sql — Multi-Server Deployment Profile: Data Migration
-- =============================================================================
-- Migrates deployment_profiles.server_name → servers + deployment_profile_servers
-- Run AFTER 01-tables.sql and 02-rls.sql
-- Run in: Supabase SQL Editor
-- Author: Claude + Stuart
-- Date: 2026-04-12
--
-- IMPORTANT: Does NOT drop server_name column — that is a future cleanup task.
--
-- Migration handles two data patterns found in production:
--   1. Single server name: "PROD-SQL-01"
--   2. Comma-separated list: "COG-IMAGEWS2, IMAGE-APP3, IMAGE-APP4"
-- Both are split and normalized into individual server rows.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Step 1: Extract distinct server names per namespace
-- Split comma-separated server_name values into individual server names.
-- Join through deployment_profiles → workspaces to resolve namespace_id.
-- -----------------------------------------------------------------------------

INSERT INTO public.servers (namespace_id, name, status)
SELECT DISTINCT
  w.namespace_id,
  trim(srv.server_name_single) AS name,
  'active' AS status
FROM public.deployment_profiles dp
JOIN public.workspaces w ON w.id = dp.workspace_id
CROSS JOIN LATERAL unnest(
  string_to_array(dp.server_name, ', ')
) AS srv(server_name_single)
WHERE dp.server_name IS NOT NULL
  AND dp.server_name != ''
  AND trim(srv.server_name_single) != ''
ON CONFLICT (namespace_id, name) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Step 2: Create deployment_profile_servers junction rows
-- For each DP with a non-null server_name, link to the corresponding server(s).
-- First server in the comma-separated list is marked as is_primary = true.
-- Remaining servers get is_primary = false.
-- server_role is NULL (unknown from legacy data).
-- -----------------------------------------------------------------------------

-- Insert primary server links (first server in each server_name value)
INSERT INTO public.deployment_profile_servers (deployment_profile_id, server_id, server_role, is_primary)
SELECT
  dp.id AS deployment_profile_id,
  s.id AS server_id,
  NULL AS server_role,
  true AS is_primary
FROM public.deployment_profiles dp
JOIN public.workspaces w ON w.id = dp.workspace_id
JOIN public.servers s
  ON s.namespace_id = w.namespace_id
  AND s.name = trim(split_part(dp.server_name, ', ', 1))
WHERE dp.server_name IS NOT NULL
  AND dp.server_name != ''
ON CONFLICT (deployment_profile_id, server_id) DO NOTHING;

-- Insert non-primary server links (2nd and subsequent servers in comma-separated values)
INSERT INTO public.deployment_profile_servers (deployment_profile_id, server_id, server_role, is_primary)
SELECT
  dp.id AS deployment_profile_id,
  s.id AS server_id,
  NULL AS server_role,
  false AS is_primary
FROM public.deployment_profiles dp
JOIN public.workspaces w ON w.id = dp.workspace_id
CROSS JOIN LATERAL unnest(
  string_to_array(dp.server_name, ', ')
) WITH ORDINALITY AS srv(server_name_single, ordinal)
JOIN public.servers s
  ON s.namespace_id = w.namespace_id
  AND s.name = trim(srv.server_name_single)
WHERE dp.server_name IS NOT NULL
  AND dp.server_name != ''
  AND trim(srv.server_name_single) != ''
  AND srv.ordinal > 1
ON CONFLICT (deployment_profile_id, server_id) DO NOTHING;

COMMIT;

-- =============================================================================
-- Verification SELECT
-- =============================================================================

WITH server_counts AS (
  SELECT
    s.namespace_id,
    n.name AS namespace_name,
    count(*) AS server_count
  FROM public.servers s
  JOIN public.namespaces n ON n.id = s.namespace_id
  GROUP BY s.namespace_id, n.name
),
link_counts AS (
  SELECT
    w.namespace_id,
    count(*) AS total_links,
    count(*) FILTER (WHERE dps.is_primary) AS primary_links,
    count(*) FILTER (WHERE NOT dps.is_primary) AS non_primary_links
  FROM public.deployment_profile_servers dps
  JOIN public.deployment_profiles dp ON dp.id = dps.deployment_profile_id
  JOIN public.workspaces w ON w.id = dp.workspace_id
  GROUP BY w.namespace_id
),
unmigrated AS (
  SELECT count(*) AS unmigrated_dp_count
  FROM public.deployment_profiles dp
  WHERE dp.server_name IS NOT NULL
    AND dp.server_name != ''
    AND NOT EXISTS (
      SELECT 1 FROM public.deployment_profile_servers dps
      WHERE dps.deployment_profile_id = dp.id
    )
)
SELECT ord, section, details FROM (
  -- Section 1: Servers created per namespace
  SELECT 1 AS ord, 'servers_per_namespace' AS section,
         jsonb_build_object('namespaces', (
           SELECT jsonb_agg(jsonb_build_object(
             'namespace', namespace_name,
             'servers', server_count
           )) FROM server_counts
         )) AS details
  UNION ALL
  -- Section 2: Junction links per namespace
  SELECT 2, 'links_per_namespace',
         jsonb_build_object('namespaces', (
           SELECT jsonb_agg(jsonb_build_object(
             'namespace_id', namespace_id,
             'total', total_links,
             'primary', primary_links,
             'non_primary', non_primary_links
           )) FROM link_counts
         ))
  UNION ALL
  -- Section 3: Unmigrated DPs (should be 0)
  SELECT 3, 'unmigrated_check',
         jsonb_build_object('unmigrated_dps', (SELECT unmigrated_dp_count FROM unmigrated))
  UNION ALL
  -- Section 4: Sample data (first 10 links)
  SELECT 4, 'sample_links',
         jsonb_build_object('samples', (
           SELECT jsonb_agg(jsonb_build_object(
             'dp_name', dp.name,
             'server_name', s.name,
             'is_primary', dps.is_primary,
             'server_role', dps.server_role
           ))
           FROM (
             SELECT * FROM public.deployment_profile_servers
             ORDER BY created_at
             LIMIT 10
           ) dps
           JOIN public.deployment_profiles dp ON dp.id = dps.deployment_profile_id
           JOIN public.servers s ON s.id = dps.server_id
         ))
) x
ORDER BY ord;
