-- =============================================================================
-- GetInSync NextGen - Audit Logging Migration (3 of 3)
-- SCRIPT 3: Attach Triggers to Tables
-- Date: 2026-02-08
-- Prerequisites: Script 1 (table exists) + Script 2 (functions exist)
-- =============================================================================
--
-- ⚠️  THIS SCRIPT ACTIVATES LOGGING ON PRODUCTION DATA.
--     Every INSERT/UPDATE/DELETE on these 11 tables will write to audit_logs.
--     Run Scripts 1 and 2 first and verify they succeeded.
--
-- Run in Supabase SQL Editor as postgres role.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- CORE BUSINESS TABLES (7) — Category: data_change
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TRIGGER audit_applications
    AFTER INSERT OR UPDATE OR DELETE ON public.applications
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_deployment_profiles
    AFTER INSERT OR UPDATE OR DELETE ON public.deployment_profiles
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_portfolios
    AFTER INSERT OR UPDATE OR DELETE ON public.portfolios
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_portfolio_assignments
    AFTER INSERT OR UPDATE OR DELETE ON public.portfolio_assignments
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_contacts
    AFTER INSERT OR UPDATE OR DELETE ON public.contacts
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_organizations
    AFTER INSERT OR UPDATE OR DELETE ON public.organizations
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_it_services
    AFTER INSERT OR UPDATE OR DELETE ON public.it_services
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

-- ─────────────────────────────────────────────────────────────────────────────
-- SECURITY-RELEVANT TABLES (4) — Category: access_control / session
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TRIGGER audit_workspace_users
    AFTER INSERT OR UPDATE OR DELETE ON public.workspace_users
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_namespace_users
    AFTER INSERT OR UPDATE OR DELETE ON public.namespace_users
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

-- user_sessions: INSERT + UPDATE only (no DELETE — sessions are overwritten)
CREATE TRIGGER audit_user_sessions
    AFTER INSERT OR UPDATE ON public.user_sessions
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

CREATE TRIGGER audit_platform_admins
    AFTER INSERT OR UPDATE OR DELETE ON public.platform_admins
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION
-- ─────────────────────────────────────────────────────────────────────────────

-- Should return 11 triggers across 11 tables
SELECT 
    trigger_name,
    event_object_table,
    string_agg(event_manipulation, ', ' ORDER BY event_manipulation) AS events
FROM information_schema.triggers 
WHERE trigger_name LIKE 'audit_%' 
  AND trigger_schema = 'public'
GROUP BY trigger_name, event_object_table
ORDER BY event_object_table;

-- ─────────────────────────────────────────────────────────────────────────────
-- SMOKE TEST
-- ─────────────────────────────────────────────────────────────────────────────
-- After running this script, do a quick namespace switch or edit an application.
-- Then check:
--
--   SELECT id, event_category, event_type, entity_type, entity_name, created_at
--   FROM audit_logs 
--   ORDER BY created_at DESC 
--   LIMIT 10;
--
-- You should see your action logged.
--
-- Then run the full evidence report:
--
--   SELECT generate_soc2_evidence();
--
-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE COUNT: 66 → 67
-- RLS POLICIES: 279 → 282
-- FUNCTIONS: 85 → 89
-- TRIGGERS: +11 audit triggers
-- SOC2 CLOCK: STARTED
-- ─────────────────────────────────────────────────────────────────────────────
