-- =============================================================================
-- GetInSync NextGen - Audit Logging Migration (2 of 3)
-- SCRIPT 2: Functions (trigger, SOC2 evidence, retention, search)
-- Date: 2026-02-08
-- Prerequisite: Script 1 (audit_logs table must exist)
-- =============================================================================
--
-- Run in Supabase SQL Editor as postgres role.
-- After running, verify with the queries at the bottom.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. GENERIC AUDIT TRIGGER FUNCTION
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.audit_log_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- Runs as postgres, bypasses RLS for INSERT into audit_logs
SET search_path = public
AS $$
DECLARE
    v_user_id       uuid;
    v_namespace_id  uuid;
    v_workspace_id  uuid;
    v_entity_id     uuid;
    v_entity_name   text;
    v_old_values    jsonb;
    v_new_values    jsonb;
    v_changed       text[];
    v_category      text;
    v_key           text;
    v_row_data      jsonb;  -- the NEW or OLD row as jsonb
BEGIN
    -- ── Get current user (NULL for system/service_role operations) ──
    BEGIN
        v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    -- ── Get current namespace from session ──
    IF v_user_id IS NOT NULL THEN
        BEGIN
            SELECT current_namespace_id INTO v_namespace_id
            FROM public.user_sessions
            WHERE user_id = v_user_id;
        EXCEPTION WHEN OTHERS THEN
            v_namespace_id := NULL;
        END;
    END IF;

    -- ── Event category based on table ──
    v_category := CASE TG_TABLE_NAME
        WHEN 'workspace_users' THEN 'access_control'
        WHEN 'namespace_users' THEN 'access_control'
        WHEN 'platform_admins' THEN 'access_control'
        WHEN 'user_sessions'   THEN 'session'
        ELSE 'data_change'
    END;

    -- ── Build old/new JSONB and determine the "reference row" ──
    IF TG_OP = 'DELETE' THEN
        v_old_values := to_jsonb(OLD);
        v_new_values := NULL;
        v_row_data   := v_old_values;
    ELSIF TG_OP = 'INSERT' THEN
        v_old_values := NULL;
        v_new_values := to_jsonb(NEW);
        v_row_data   := v_new_values;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_values := to_jsonb(OLD);
        v_new_values := to_jsonb(NEW);
        v_row_data   := v_new_values;

        -- Build changed fields array (skip metadata columns)
        v_changed := ARRAY[]::text[];
        FOR v_key IN SELECT jsonb_object_keys(v_new_values)
        LOOP
            IF v_key NOT IN ('updated_at', 'created_at') THEN
                IF (v_old_values -> v_key) IS DISTINCT FROM (v_new_values -> v_key) THEN
                    v_changed := array_append(v_changed, v_key);
                END IF;
            END IF;
        END LOOP;
        
        -- Skip no-op updates (only updated_at changed)
        IF array_length(v_changed, 1) IS NULL OR array_length(v_changed, 1) = 0 THEN
            RETURN NEW;
        END IF;
    END IF;

    -- ── Extract entity_id (fallback chain: id → user_id → NULL) ──
    IF v_row_data ? 'id' AND v_row_data ->> 'id' IS NOT NULL THEN
        BEGIN
            v_entity_id := (v_row_data ->> 'id')::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_entity_id := NULL;
        END;
    ELSIF v_row_data ? 'user_id' AND v_row_data ->> 'user_id' IS NOT NULL THEN
        -- Tables with user_id as PK (e.g. user_sessions)
        BEGIN
            v_entity_id := (v_row_data ->> 'user_id')::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_entity_id := NULL;
        END;
    END IF;

    -- ── Extract entity_name (table-specific for useful labels) ──
    IF TG_TABLE_NAME = 'user_sessions' THEN
        -- For namespace switches, show "Switched to namespace <uuid>"
        -- The namespace name isn't on the row, so we use the ID
        IF TG_OP = 'UPDATE' THEN
            v_entity_name := 'Namespace switch: ' 
                || COALESCE(v_old_values ->> 'current_namespace_id', '?')
                || ' → ' 
                || COALESCE(v_new_values ->> 'current_namespace_id', '?');
        ELSE
            v_entity_name := 'Session for user ' || COALESCE(v_row_data ->> 'user_id', '?');
        END IF;
    ELSE
        -- Generic: prefer name → email → display_name → id
        v_entity_name := COALESCE(
            v_row_data ->> 'name',
            v_row_data ->> 'email',
            v_row_data ->> 'display_name',
            v_entity_id::text
        );
    END IF;

    -- ── Extract workspace_id if present on the row ──
    IF v_row_data ? 'workspace_id' AND v_row_data ->> 'workspace_id' IS NOT NULL THEN
        BEGIN
            v_workspace_id := (v_row_data ->> 'workspace_id')::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_workspace_id := NULL;
        END;
    END IF;

    -- ── For tables with namespace_id directly, prefer it over session ──
    IF v_row_data ? 'namespace_id' AND v_row_data ->> 'namespace_id' IS NOT NULL THEN
        BEGIN
            v_namespace_id := (v_row_data ->> 'namespace_id')::uuid;
        EXCEPTION WHEN OTHERS THEN
            -- Keep session namespace_id
            NULL;
        END;
    END IF;

    -- ── For user_sessions, use the target namespace as the log namespace ──
    IF TG_TABLE_NAME = 'user_sessions' AND v_row_data ? 'current_namespace_id' THEN
        BEGIN
            v_namespace_id := (v_row_data ->> 'current_namespace_id')::uuid;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END IF;

    -- ── Strip sensitive fields ──
    IF v_old_values IS NOT NULL THEN
        v_old_values := v_old_values - ARRAY['password_hash', 'token', 'secret', 'api_key'];
    END IF;
    IF v_new_values IS NOT NULL THEN
        v_new_values := v_new_values - ARRAY['password_hash', 'token', 'secret', 'api_key'];
    END IF;

    -- ── Insert audit log entry ──
    INSERT INTO public.audit_logs (
        namespace_id, workspace_id, user_id,
        event_category, event_type,
        entity_type, entity_id, entity_name,
        old_values, new_values, changed_fields,
        outcome
    ) VALUES (
        v_namespace_id, v_workspace_id, v_user_id,
        v_category, TG_OP,
        TG_TABLE_NAME, v_entity_id, v_entity_name,
        v_old_values, v_new_values, v_changed,
        'success'
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.audit_log_trigger() IS 
    'Generic audit logging trigger. SECURITY DEFINER bypasses RLS for INSERT. '
    'Handles tables with id PK (standard) and user_id PK (user_sessions). '
    'Captures old/new values, changed fields, user context.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. SOC2 EVIDENCE GENERATION RPC
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_soc2_evidence()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result jsonb;
BEGIN
    -- Platform admin only
    IF NOT check_is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: platform admin required';
    END IF;

    SELECT jsonb_build_object(
        'report_generated_at', now(),
        'report_type', 'SOC2 Type II Evidence Summary',
        'platform_version', 'GetInSync NextGen',
        
        -- CC6.1: Logical Access Controls
        'cc6_1_logical_access', jsonb_build_object(
            'total_tables', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'),
            'tables_with_rls', (SELECT count(DISTINCT tablename) FROM pg_policies WHERE schemaname = 'public'),
            'total_rls_policies', (SELECT count(*) FROM pg_policies WHERE schemaname = 'public'),
            'total_users', (SELECT count(*) FROM public.users),
            'users_by_namespace_role', (
                SELECT COALESCE(jsonb_object_agg(COALESCE(namespace_role, 'null'), cnt), '{}'::jsonb)
                FROM (SELECT namespace_role, count(*) as cnt FROM public.users GROUP BY namespace_role) r
            ),
            'platform_admins', (SELECT count(*) FROM public.platform_admins),
            'total_namespaces', (SELECT count(*) FROM public.namespaces),
            'namespaces_by_tier', (
                SELECT COALESCE(jsonb_object_agg(tier, cnt), '{}'::jsonb)
                FROM (SELECT tier, count(*) as cnt FROM public.namespaces GROUP BY tier) t
            ),
            'namespaces_by_status', (
                SELECT COALESCE(jsonb_object_agg(COALESCE(status, 'null'), cnt), '{}'::jsonb)
                FROM (SELECT status, count(*) as cnt FROM public.namespaces GROUP BY status) s
            )
        ),

        -- CC6.2: Encryption & Data Protection
        'cc6_2_encryption', jsonb_build_object(
            'database_region', 'ca-central-1',
            'encryption_at_rest', 'AES-256 (Supabase managed)',
            'encryption_in_transit', 'TLS 1.2+ (enforced)',
            'namespaces_by_region', (
                SELECT COALESCE(jsonb_object_agg(region, cnt), '{}'::jsonb)
                FROM (SELECT region, count(*) as cnt FROM public.namespaces GROUP BY region) r
            )
        ),

        -- CC6.6: Audit Logging
        'cc6_6_audit_logging', jsonb_build_object(
            'audit_logging_enabled', true,
            'audit_logging_start_date', (SELECT min(created_at) FROM public.audit_logs),
            'total_audit_entries', (SELECT count(*) FROM public.audit_logs),
            'entries_last_30_days', (SELECT count(*) FROM public.audit_logs WHERE created_at > now() - interval '30 days'),
            'entries_by_category', (
                SELECT COALESCE(jsonb_object_agg(event_category, cnt), '{}'::jsonb)
                FROM (SELECT event_category, count(*) as cnt FROM public.audit_logs GROUP BY event_category) c
            ),
            'entries_by_event_type', (
                SELECT COALESCE(jsonb_object_agg(event_type, cnt), '{}'::jsonb)
                FROM (SELECT event_type, count(*) as cnt FROM public.audit_logs GROUP BY event_type) e
            ),
            'audited_tables', (
                SELECT COALESCE(jsonb_agg(DISTINCT entity_type), '[]'::jsonb)
                FROM public.audit_logs
            ),
            'auth_audit_entries', (SELECT count(*) FROM auth.audit_log_entries),
            'auth_audit_start_date', (SELECT min(created_at) FROM auth.audit_log_entries)
        ),

        -- C1.1: Tenant Isolation
        'c1_1_tenant_isolation', jsonb_build_object(
            'multi_tenant_model', 'Namespace-scoped with RLS',
            'isolation_method', 'PostgreSQL Row Level Security',
            'namespace_switching_method', 'user_sessions.current_namespace_id',
            'orphaned_records_check', jsonb_build_object(
                'orphaned_workspace_users', (
                    SELECT count(*) FROM public.workspace_users wu
                    WHERE NOT EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = wu.workspace_id)
                ),
                'orphaned_portfolio_assignments', (
                    SELECT count(*) FROM public.portfolio_assignments pa
                    WHERE NOT EXISTS (SELECT 1 FROM public.portfolios p WHERE p.id = pa.portfolio_id)
                ),
                'users_without_namespace', (
                    SELECT count(*) FROM public.users u WHERE u.namespace_id IS NULL
                )
            )
        ),

        -- A1.2: Backup & Recovery
        'a1_2_backup_recovery', jsonb_build_object(
            'backup_method', 'Supabase automated daily + manual pg_dump',
            'last_manual_backup', '2026-02-08',
            'schema_table_count', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'),
            'schema_view_count', (SELECT count(*) FROM information_schema.views WHERE table_schema = 'public'),
            'schema_function_count', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public')
        ),

        -- Access review snapshot
        'access_review', jsonb_build_object(
            'workspace_admins', (SELECT count(DISTINCT user_id) FROM public.workspace_users WHERE role = 'admin'),
            'namespace_admins', (SELECT count(*) FROM public.users WHERE namespace_role = 'admin'),
            'platform_admin_count', (SELECT count(*) FROM public.platform_admins),
            'recent_access_control_events_30d', (
                SELECT count(*) FROM public.audit_logs
                WHERE event_category = 'access_control'
                AND created_at > now() - interval '30 days'
            ),
            'recent_namespace_switches_30d', (
                SELECT count(*) FROM public.audit_logs
                WHERE entity_type = 'user_sessions'
                AND created_at > now() - interval '30 days'
            )
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.generate_soc2_evidence() IS 
    'Generates SOC2 Type II evidence report as JSON. Platform admin only. Run monthly and archive results.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. AUDIT LOG RETENTION MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.audit_log_cleanup(
    p_retention_days integer DEFAULT 365
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted integer;
BEGIN
    IF NOT check_is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: platform admin required';
    END IF;

    IF p_retention_days < 365 THEN
        RAISE EXCEPTION 'Minimum retention period is 365 days (SOC2 requirement)';
    END IF;

    DELETE FROM public.audit_logs
    WHERE created_at < now() - (p_retention_days || ' days')::interval;
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    
    -- Log the cleanup action itself
    INSERT INTO public.audit_logs (
        user_id, event_category, event_type, entity_type,
        entity_name, new_values, outcome
    ) VALUES (
        auth.uid(), 'admin', 'DELETE', 'audit_logs',
        'Retention cleanup', 
        jsonb_build_object('retention_days', p_retention_days, 'rows_deleted', v_deleted),
        'success'
    );
    
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION public.audit_log_cleanup(integer) IS 
    'Deletes audit logs older than retention period. Minimum 365 days (SOC2). Platform admin only.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. AUDIT LOG SEARCH RPC
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.search_audit_logs(
    p_namespace_id   uuid DEFAULT NULL,
    p_user_id        uuid DEFAULT NULL,
    p_entity_type    text DEFAULT NULL,
    p_entity_id      uuid DEFAULT NULL,
    p_event_category text DEFAULT NULL,
    p_from_date      timestamptz DEFAULT NULL,
    p_to_date        timestamptz DEFAULT NULL,
    p_limit          integer DEFAULT 100,
    p_offset         integer DEFAULT 0
)
RETURNS TABLE (
    id              uuid,
    namespace_id    uuid,
    workspace_id    uuid,
    user_id         uuid,
    event_category  text,
    event_type      text,
    entity_type     text,
    entity_id       uuid,
    entity_name     text,
    changed_fields  text[],
    outcome         text,
    created_at      timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Non-platform-admins scoped to current namespace
    IF NOT check_is_platform_admin() THEN
        p_namespace_id := get_current_namespace_id();
    END IF;

    RETURN QUERY
    SELECT 
        al.id, al.namespace_id, al.workspace_id, al.user_id,
        al.event_category, al.event_type,
        al.entity_type, al.entity_id, al.entity_name,
        al.changed_fields, al.outcome, al.created_at
    FROM public.audit_logs al
    WHERE (p_namespace_id IS NULL OR al.namespace_id = p_namespace_id)
      AND (p_user_id IS NULL OR al.user_id = p_user_id)
      AND (p_entity_type IS NULL OR al.entity_type = p_entity_type)
      AND (p_entity_id IS NULL OR al.entity_id = p_entity_id)
      AND (p_event_category IS NULL OR al.event_category = p_event_category)
      AND (p_from_date IS NULL OR al.created_at >= p_from_date)
      AND (p_to_date IS NULL OR al.created_at <= p_to_date)
    ORDER BY al.created_at DESC
    LIMIT LEAST(p_limit, 1000)
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.search_audit_logs IS 
    'Search audit logs with filters. Non-platform-admins scoped to current namespace. Returns summary (no old/new values for performance).';

-- ─────────────────────────────────────────────────────────────────────────────
-- GRANTS FOR FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.generate_soc2_evidence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.audit_log_cleanup(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_audit_logs TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION
-- ─────────────────────────────────────────────────────────────────────────────

-- Should return 4 functions (audit_log_trigger, generate_soc2_evidence, audit_log_cleanup, search_audit_logs)
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('audit_log_trigger', 'generate_soc2_evidence', 'audit_log_cleanup', 'search_audit_logs')
ORDER BY routine_name;
