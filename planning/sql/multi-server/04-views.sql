-- =============================================================================
-- 04-views.sql — Multi-Server Deployment Profile: View Rewrites + New View
-- =============================================================================
-- Rewrites: vw_server_technology_report, vw_application_infrastructure_report,
--           vw_technology_tag_lifecycle_risk
-- Creates:  vw_server_deployment_summary
-- Run AFTER 01-tables.sql, 02-rls.sql, 03-migration.sql
-- Run in: Supabase SQL Editor
-- Author: Claude + Stuart
-- Date: 2026-04-12
--
-- All views use security_invoker = true (matching existing pattern).
-- DROP + CREATE for vw_server_technology_report and vw_application_infrastructure_report
--   (no dependent views).
-- CREATE OR REPLACE for vw_technology_tag_lifecycle_risk (has 5 dependent views:
--   vw_dashboard_summary, vw_dashboard_summary_scoped, vw_dashboard_workspace_breakdown,
--   vw_run_rate_by_lifecycle_status, vw_explorer_detail).
--   New column server_names appended at the END to preserve existing column positions.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. vw_server_technology_report — Rewrite
-- OLD: grouped by free-text dp.server_name
-- NEW: joins through deployment_profile_servers → servers entity
-- Added columns: server_id, server_os, server_status, data_center_name
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS public.vw_server_technology_report;

CREATE VIEW public.vw_server_technology_report WITH (security_invoker='true') AS
SELECT
  s.id AS server_id,
  s.name AS server_name,
  s.os AS server_os,
  s.status AS server_status,
  dc.name AS data_center_name,
  s.namespace_id,
  count(DISTINCT dp.id) AS deployment_count,
  count(DISTINCT dp.application_id) AS application_count,
  mode() WITHIN GROUP (ORDER BY os_tp.name) AS primary_os,
  mode() WITHIN GROUP (ORDER BY os_dptp.deployed_version) AS primary_os_version,
  CASE
    WHEN bool_or(tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE) THEN 'end_of_support'
    WHEN bool_or(tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE) THEN 'end_of_support'
    WHEN bool_or(tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE) THEN 'extended'
    WHEN bool_or(tlr.id IS NOT NULL) THEN 'mainstream'
    ELSE 'incomplete_data'
  END AS worst_lifecycle_status,
  count(DISTINCT dptp.id) FILTER (
    WHERE tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE
       OR tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE
  ) AS end_of_support_tech_count,
  min(tlr.end_of_life_date) FILTER (WHERE tlr.end_of_life_date >= CURRENT_DATE) AS next_eol_date
FROM public.servers s
JOIN public.deployment_profile_servers dps ON dps.server_id = s.id
JOIN public.deployment_profiles dp ON dp.id = dps.deployment_profile_id
LEFT JOIN public.data_centers dc ON dc.id = s.data_center_id
LEFT JOIN public.deployment_profile_technology_products dptp ON dptp.deployment_profile_id = dp.id
LEFT JOIN public.technology_products tp ON tp.id = dptp.technology_product_id
LEFT JOIN public.technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
LEFT JOIN public.deployment_profile_technology_products os_dptp ON os_dptp.deployment_profile_id = dp.id
LEFT JOIN public.technology_products os_tp ON os_tp.id = os_dptp.technology_product_id
LEFT JOIN public.technology_product_categories os_tpc
  ON os_tpc.id = os_tp.category_id AND os_tpc.name = 'Operating System'
GROUP BY s.id, s.name, s.os, s.status, dc.name, s.namespace_id;


-- -----------------------------------------------------------------------------
-- 2. vw_application_infrastructure_report — Rewrite
-- OLD: single dp.server_name column
-- NEW: adds aggregated server_names (comma-separated), keeps server_name
--      for backward compatibility (first/primary server)
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS public.vw_application_infrastructure_report;

CREATE VIEW public.vw_application_infrastructure_report WITH (security_invoker='true') AS
SELECT
  a.id AS application_id,
  a.name AS application_name,
  a.operational_status AS app_operational_status,
  a.management_classification,
  a.csdm_stage,
  a.branch,
  dp.id AS deployment_profile_id,
  dp.name AS deployment_profile_name,
  dp.is_primary,
  dp.hosting_type,
  dp.cloud_provider,
  dp.environment,
  -- Backward compat: keep server_name as the primary server name
  COALESCE(
    (SELECT s.name FROM public.deployment_profile_servers dps
     JOIN public.servers s ON s.id = dps.server_id
     WHERE dps.deployment_profile_id = dp.id AND dps.is_primary
     LIMIT 1),
    dp.server_name
  ) AS server_name,
  -- New: all servers as comma-separated string
  (SELECT string_agg(s.name, ', ' ORDER BY dps2.is_primary DESC, s.name)
   FROM public.deployment_profile_servers dps2
   JOIN public.servers s ON s.id = dps2.server_id
   WHERE dps2.deployment_profile_id = dp.id
  ) AS server_names,
  dp.tech_health,
  dp.tech_risk,
  dp.tech_assessment_status,
  dp.operational_status AS dp_operational_status,
  w.id AS workspace_id,
  w.name AS workspace_name,
  w.namespace_id,
  os_tag.technology_name AS os_name,
  os_tag.deployed_version AS os_version,
  os_tag.deployed_edition AS os_edition,
  os_tag.lifecycle_status AS os_lifecycle_status,
  os_tag.days_to_eol AS os_days_to_eol,
  db_tag.technology_name AS db_name,
  db_tag.deployed_version AS db_version,
  db_tag.deployed_edition AS db_edition,
  db_tag.lifecycle_status AS db_lifecycle_status,
  db_tag.days_to_eol AS db_days_to_eol,
  web_tag.technology_name AS web_name,
  web_tag.deployed_version AS web_version,
  web_tag.deployed_edition AS web_edition,
  web_tag.lifecycle_status AS web_lifecycle_status,
  web_tag.days_to_eol AS web_days_to_eol,
  (EXISTS (
    SELECT 1 FROM public.portfolio_assignments pa
    WHERE pa.application_id = a.id AND pa.criticality IS NOT NULL AND pa.criticality >= 50
  )) AS is_crown_jewel,
  CASE
    WHEN (dp.hosting_type = ANY(ARRAY['SaaS', 'Managed'])) AND NOT (EXISTS (
      SELECT 1 FROM public.deployment_profile_technology_products dptp2
      WHERE dptp2.deployment_profile_id = dp.id
    )) THEN 'business_vendor_managed'
    WHEN (EXISTS (
      SELECT 1 FROM public.deployment_profile_technology_products dptp2
      JOIN public.technology_products tp2 ON tp2.id = dptp2.technology_product_id
      JOIN public.technology_lifecycle_reference tlr2 ON tlr2.id = tp2.lifecycle_reference_id
      WHERE dptp2.deployment_profile_id = dp.id
        AND (tlr2.end_of_life_date IS NOT NULL AND tlr2.end_of_life_date < CURRENT_DATE
             OR tlr2.extended_support_end IS NOT NULL AND tlr2.extended_support_end < CURRENT_DATE)
    )) THEN 'end_of_support'
    WHEN (EXISTS (
      SELECT 1 FROM public.deployment_profile_technology_products dptp2
      JOIN public.technology_products tp2 ON tp2.id = dptp2.technology_product_id
      JOIN public.technology_lifecycle_reference tlr2 ON tlr2.id = tp2.lifecycle_reference_id
      WHERE dptp2.deployment_profile_id = dp.id
        AND tlr2.mainstream_support_end IS NOT NULL AND tlr2.mainstream_support_end < CURRENT_DATE
    )) THEN 'extended'
    WHEN (EXISTS (
      SELECT 1 FROM public.deployment_profile_technology_products dptp2
      WHERE dptp2.deployment_profile_id = dp.id
    )) THEN 'mainstream'
    ELSE 'incomplete_data'
  END AS worst_lifecycle_status
FROM public.deployment_profiles dp
JOIN public.applications a ON a.id = dp.application_id
JOIN public.workspaces w ON w.id = dp.workspace_id
LEFT JOIN LATERAL (
  SELECT tp.name AS technology_name,
         COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
         dptp.edition AS deployed_edition,
         CASE
           WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'extended'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'mainstream'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'preview'
           WHEN tlr.id IS NOT NULL THEN 'incomplete_data'
           ELSE NULL
         END AS lifecycle_status,
         CASE WHEN tlr.end_of_life_date IS NOT NULL THEN tlr.end_of_life_date - CURRENT_DATE ELSE NULL END AS days_to_eol
  FROM public.deployment_profile_technology_products dptp
  JOIN public.technology_products tp ON tp.id = dptp.technology_product_id
  JOIN public.technology_product_categories tpc ON tpc.id = tp.category_id
  LEFT JOIN public.technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
  WHERE dptp.deployment_profile_id = dp.id AND tpc.name = 'Operating System'
  LIMIT 1
) os_tag ON true
LEFT JOIN LATERAL (
  SELECT tp.name AS technology_name,
         COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
         dptp.edition AS deployed_edition,
         CASE
           WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'extended'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'mainstream'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'preview'
           WHEN tlr.id IS NOT NULL THEN 'incomplete_data'
           ELSE NULL
         END AS lifecycle_status,
         CASE WHEN tlr.end_of_life_date IS NOT NULL THEN tlr.end_of_life_date - CURRENT_DATE ELSE NULL END AS days_to_eol
  FROM public.deployment_profile_technology_products dptp
  JOIN public.technology_products tp ON tp.id = dptp.technology_product_id
  JOIN public.technology_product_categories tpc ON tpc.id = tp.category_id
  LEFT JOIN public.technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
  WHERE dptp.deployment_profile_id = dp.id AND tpc.name = 'Database'
  LIMIT 1
) db_tag ON true
LEFT JOIN LATERAL (
  SELECT tp.name AS technology_name,
         COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
         dptp.edition AS deployed_edition,
         CASE
           WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'end_of_support'
           WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'extended'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'mainstream'
           WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'preview'
           WHEN tlr.id IS NOT NULL THEN 'incomplete_data'
           ELSE NULL
         END AS lifecycle_status,
         CASE WHEN tlr.end_of_life_date IS NOT NULL THEN tlr.end_of_life_date - CURRENT_DATE ELSE NULL END AS days_to_eol
  FROM public.deployment_profile_technology_products dptp
  JOIN public.technology_products tp ON tp.id = dptp.technology_product_id
  JOIN public.technology_product_categories tpc ON tpc.id = tp.category_id
  LEFT JOIN public.technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
  WHERE dptp.deployment_profile_id = dp.id AND tpc.name = 'Web Server'
  LIMIT 1
) web_tag ON true;


-- -----------------------------------------------------------------------------
-- 3. vw_technology_tag_lifecycle_risk — CREATE OR REPLACE
-- Uses CREATE OR REPLACE (not DROP) because 5 dependent views exist:
--   vw_dashboard_summary, vw_dashboard_summary_scoped,
--   vw_dashboard_workspace_breakdown, vw_run_rate_by_lifecycle_status,
--   vw_explorer_detail
-- Existing columns 1-35 kept in same order (server_name at position 17 updated
-- to use primary server with legacy fallback).
-- New column server_names appended at position 36.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW public.vw_technology_tag_lifecycle_risk WITH (security_invoker='true') AS
SELECT
  dptp.id AS tag_id,
  dptp.deployment_profile_id,
  dptp.technology_product_id,
  dptp.deployed_version,
  dptp.edition AS deployed_edition,
  dptp.notes AS tag_notes,
  tp.name AS technology_name,
  tp.version AS catalog_version,
  tp.product_family,
  tp.manufacturer_id,
  tpc.name AS category_name,
  dp.name AS deployment_profile_name,
  dp.application_id,
  dp.workspace_id,
  dp.hosting_type,
  dp.environment,
  -- Position 17: server_name — updated source (primary server with legacy fallback)
  COALESCE(
    (SELECT s.name FROM public.deployment_profile_servers dps
     JOIN public.servers s ON s.id = dps.server_id
     WHERE dps.deployment_profile_id = dp.id AND dps.is_primary
     LIMIT 1),
    dp.server_name
  ) AS server_name,
  dp.operational_status AS dp_operational_status,
  a.name AS application_name,
  a.operational_status AS app_operational_status,
  w.namespace_id,
  w.name AS workspace_name,
  tlr.id AS lifecycle_reference_id,
  tlr.vendor_name,
  tlr.ga_date,
  tlr.mainstream_support_end,
  tlr.extended_support_end,
  tlr.end_of_life_date,
  tlr.confidence_level,
  tlr.is_manually_overridden,
  CASE
    WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 'end_of_support'
    WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 'end_of_support'
    WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 'extended'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 'mainstream'
    WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date > CURRENT_DATE THEN 'preview'
    WHEN tlr.id IS NOT NULL THEN 'incomplete_data'
    ELSE NULL
  END AS lifecycle_status,
  CASE WHEN tlr.end_of_life_date IS NOT NULL THEN tlr.end_of_life_date - CURRENT_DATE ELSE NULL END AS days_to_eol,
  CASE WHEN tlr.extended_support_end IS NOT NULL THEN tlr.extended_support_end - CURRENT_DATE ELSE NULL END AS days_to_extended_end,
  CASE WHEN tlr.mainstream_support_end IS NOT NULL THEN tlr.mainstream_support_end - CURRENT_DATE ELSE NULL END AS days_to_mainstream_end,
  (SELECT max(pa.criticality) FROM public.portfolio_assignments pa WHERE pa.application_id = a.id) AS max_criticality,
  -- Position 36: NEW column appended at end (safe for CREATE OR REPLACE)
  (SELECT string_agg(s.name, ', ' ORDER BY dps2.is_primary DESC, s.name)
   FROM public.deployment_profile_servers dps2
   JOIN public.servers s ON s.id = dps2.server_id
   WHERE dps2.deployment_profile_id = dp.id
  ) AS server_names
FROM public.deployment_profile_technology_products dptp
JOIN public.technology_products tp ON tp.id = dptp.technology_product_id
JOIN public.deployment_profiles dp ON dp.id = dptp.deployment_profile_id
JOIN public.applications a ON a.id = dp.application_id
JOIN public.workspaces w ON w.id = dp.workspace_id
LEFT JOIN public.technology_product_categories tpc ON tpc.id = tp.category_id
LEFT JOIN public.technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id;


-- -----------------------------------------------------------------------------
-- 4. vw_server_deployment_summary — NEW
-- Server-centric view answering "what runs on this server?"
-- -----------------------------------------------------------------------------

CREATE VIEW public.vw_server_deployment_summary WITH (security_invoker='true') AS
SELECT
  s.id AS server_id,
  s.name AS server_name,
  s.os AS server_os,
  s.status AS server_status,
  dc.name AS data_center_name,
  s.namespace_id,
  dps.deployment_profile_id,
  dp.name AS deployment_profile_name,
  dps.server_role,
  dps.is_primary,
  dp.application_id,
  a.name AS application_name,
  dp.workspace_id,
  w.name AS workspace_name,
  dp.environment,
  dp.tech_health
FROM public.servers s
JOIN public.deployment_profile_servers dps ON dps.server_id = s.id
JOIN public.deployment_profiles dp ON dp.id = dps.deployment_profile_id
JOIN public.applications a ON a.id = dp.application_id
JOIN public.workspaces w ON w.id = dp.workspace_id
LEFT JOIN public.data_centers dc ON dc.id = s.data_center_id;


-- -----------------------------------------------------------------------------
-- 5. GRANTs for views
-- DROP + CREATE removes existing GRANTs; CREATE OR REPLACE preserves them.
-- Explicitly grant SELECT on all views to ensure frontend access.
-- -----------------------------------------------------------------------------

GRANT SELECT ON public.vw_server_technology_report TO authenticated, service_role;
GRANT SELECT ON public.vw_application_infrastructure_report TO authenticated, service_role;
GRANT SELECT ON public.vw_server_deployment_summary TO authenticated, service_role;
-- vw_technology_tag_lifecycle_risk already has GRANTs (CREATE OR REPLACE preserved them)


-- =============================================================================
-- Verification SELECT
-- =============================================================================

WITH view_check AS (
  SELECT viewname
  FROM pg_views
  WHERE schemaname = 'public'
    AND viewname IN (
      'vw_server_technology_report',
      'vw_application_infrastructure_report',
      'vw_technology_tag_lifecycle_risk',
      'vw_server_deployment_summary'
    )
),
column_check_server_tech AS (
  SELECT column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'vw_server_technology_report'
  ORDER BY ordinal_position
),
column_check_infra AS (
  SELECT column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'vw_application_infrastructure_report'
    AND column_name IN ('server_name', 'server_names')
  ORDER BY ordinal_position
),
column_check_lifecycle AS (
  SELECT column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'vw_technology_tag_lifecycle_risk'
    AND column_name IN ('server_name', 'server_names')
  ORDER BY ordinal_position
),
column_check_summary AS (
  SELECT column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'vw_server_deployment_summary'
  ORDER BY ordinal_position
),
row_counts AS (
  SELECT 'vw_server_technology_report' AS view_name, count(*) AS row_count FROM public.vw_server_technology_report
  UNION ALL
  SELECT 'vw_server_deployment_summary', count(*) FROM public.vw_server_deployment_summary
)
SELECT ord, section, details FROM (
  -- Section 1: Views exist
  SELECT 1 AS ord, 'views_exist' AS section,
         jsonb_build_object('views', (SELECT jsonb_agg(viewname) FROM view_check)) AS details
  UNION ALL
  -- Section 2: vw_server_technology_report columns (new columns present?)
  SELECT 2, 'server_tech_report_columns',
         jsonb_build_object('columns', (SELECT jsonb_agg(column_name) FROM column_check_server_tech))
  UNION ALL
  -- Section 3: vw_application_infrastructure_report has both server_name and server_names
  SELECT 3, 'infra_report_server_columns',
         jsonb_build_object('columns', (SELECT jsonb_agg(column_name) FROM column_check_infra))
  UNION ALL
  -- Section 4: vw_technology_tag_lifecycle_risk has both server_name and server_names
  SELECT 4, 'lifecycle_risk_server_columns',
         jsonb_build_object('columns', (SELECT jsonb_agg(column_name) FROM column_check_lifecycle))
  UNION ALL
  -- Section 5: vw_server_deployment_summary columns
  SELECT 5, 'server_deploy_summary_columns',
         jsonb_build_object('columns', (SELECT jsonb_agg(column_name) FROM column_check_summary))
  UNION ALL
  -- Section 6: Row counts (sanity check)
  SELECT 6, 'row_counts',
         jsonb_build_object('counts', (SELECT jsonb_agg(jsonb_build_object('view', view_name, 'rows', row_count)) FROM row_counts))
) x
ORDER BY ord;
