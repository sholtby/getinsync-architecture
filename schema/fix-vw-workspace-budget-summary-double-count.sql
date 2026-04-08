-- =============================================================================
-- Fix: vw_workspace_budget_summary double-counting IT service costs
-- =============================================================================
-- Problem:  app_run_rate uses vpc.total_cost which includes BOTH bundle_cost
--           AND service_cost. service_run_rate then computes service_cost again
--           independently, causing IT service allocations to be counted twice.
-- Fix:      Change vpc.total_cost → vpc.bundle_cost in the app_run_rate subquery
-- Impact:   Dashboard "Annual Run Rate" will drop from ~$5.1M to ~$2.88M (correct)
-- =============================================================================

CREATE OR REPLACE VIEW vw_workspace_budget_summary WITH (security_invoker = true) AS
SELECT w.id AS workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    wb.budget_amount AS workspace_budget,
    wb.fiscal_year AS budget_fiscal_year,
    COALESCE(sum(a.budget_amount), 0::numeric) AS app_budget_allocated,
    -- FIX: was vpc.total_cost (included service_cost, causing double-count)
    COALESCE(sum(( SELECT vpc.bundle_cost
           FROM vw_deployment_profile_costs vpc
          WHERE vpc.application_id = a.id AND vpc.deployment_profile_id = (( SELECT deployment_profiles.id
                   FROM deployment_profiles
                  WHERE deployment_profiles.application_id = a.id AND deployment_profiles.is_primary = true
                 LIMIT 1)))), 0::numeric) AS app_run_rate,
    COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM it_services its
          WHERE its.owner_workspace_id = w.id), 0::numeric) AS service_budget_allocated,
    COALESCE(( SELECT sum(( SELECT sum(
                        CASE
                            WHEN dpis.allocation_basis = 'fixed'::text THEN dpis.allocation_value
                            WHEN dpis.allocation_basis = 'percent'::text AND dpis.allocation_value > 100::numeric THEN dpis.allocation_value
                            WHEN dpis.allocation_basis = 'percent'::text THEN its2.annual_cost * dpis.allocation_value / 100::numeric
                            ELSE dpis.allocation_value
                        END) AS sum
                   FROM deployment_profile_it_services dpis
                  WHERE dpis.it_service_id = its2.id)) AS sum
           FROM it_services its2
          WHERE its2.owner_workspace_id = w.id), 0::numeric) AS service_run_rate,
    COALESCE(sum(a.budget_amount), 0::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM it_services its
          WHERE its.owner_workspace_id = w.id), 0::numeric) AS total_allocated,
    COALESCE(wb.budget_amount, 0::numeric) - (COALESCE(sum(a.budget_amount), 0::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM it_services its
          WHERE its.owner_workspace_id = w.id), 0::numeric)) AS unallocated,
        CASE
            WHEN wb.budget_amount IS NULL THEN 'no_budget'::text
            WHEN (COALESCE(wb.budget_amount, 0::numeric) - (COALESCE(sum(a.budget_amount), 0::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
               FROM it_services its
              WHERE its.owner_workspace_id = w.id), 0::numeric))) < 0::numeric THEN 'over_allocated'::text
            WHEN ((COALESCE(wb.budget_amount, 0::numeric) - (COALESCE(sum(a.budget_amount), 0::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
               FROM it_services its
              WHERE its.owner_workspace_id = w.id), 0::numeric))) / NULLIF(wb.budget_amount, 0::numeric)) < 0.10 THEN 'under_10'::text
            ELSE 'healthy'::text
        END AS workspace_status
   FROM workspaces w
     LEFT JOIN workspace_budgets wb ON wb.workspace_id = w.id AND wb.is_current = true
     LEFT JOIN applications a ON a.workspace_id = w.id
  GROUP BY w.id, w.name, w.namespace_id, wb.budget_amount, wb.fiscal_year;
