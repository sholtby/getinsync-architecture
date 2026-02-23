-- =============================================================================
-- GetInSync NextGen - Audit Logging Migration (1 of 3)
-- SCRIPT 1: Table, Indexes, RLS Policies, Grants
-- Date: 2026-02-08
-- =============================================================================
--
-- Run in Supabase SQL Editor as postgres role.
-- After running, verify with the queries at the bottom.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. AUDIT_LOGS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE public.audit_logs (
    id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Context: WHO did WHAT WHERE
    namespace_id    uuid REFERENCES public.namespaces(id),
    workspace_id    uuid REFERENCES public.workspaces(id),
    user_id         uuid REFERENCES auth.users(id),
    
    -- Event classification
    event_category  text NOT NULL,                  -- 'data_change', 'access_control', 'session', 'admin'
    event_type      text NOT NULL,                  -- 'INSERT', 'UPDATE', 'DELETE'
    
    -- What was affected
    entity_type     text NOT NULL,                  -- table name: 'applications', 'workspace_users', etc.
    entity_id       uuid,                           -- PK of affected row
    entity_name     text,                           -- human-readable label (app name, user email, etc.)
    
    -- Change details
    old_values      jsonb,                          -- previous state (NULL for INSERTs)
    new_values      jsonb,                          -- new state (NULL for DELETEs)
    changed_fields  text[],                         -- list of fields that changed (UPDATEs only)
    
    -- Request metadata
    ip_address      inet,
    user_agent      text,
    
    -- Outcome
    outcome         text NOT NULL DEFAULT 'success', -- 'success', 'denied'
    
    -- Timestamp (immutable — no updated_at, append-only)
    created_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.audit_logs IS 'SOC2 application-level audit trail. Append-only. Started 2026-02-08.';
COMMENT ON COLUMN public.audit_logs.old_values IS 'Previous row state as JSONB. NULL for INSERTs.';
COMMENT ON COLUMN public.audit_logs.new_values IS 'New row state as JSONB. NULL for DELETEs.';
COMMENT ON COLUMN public.audit_logs.changed_fields IS 'Array of column names that changed. UPDATEs only.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────────────────────

-- Primary: "Show me audit logs for this namespace"
CREATE INDEX idx_audit_logs_namespace_created 
    ON public.audit_logs (namespace_id, created_at DESC);

-- "Show me what this user did"
CREATE INDEX idx_audit_logs_user_created 
    ON public.audit_logs (user_id, created_at DESC);

-- "Show me changes to this entity"
CREATE INDEX idx_audit_logs_entity 
    ON public.audit_logs (entity_type, entity_id, created_at DESC);

-- "Show me access control events" (SOC2 auditor favorite)
CREATE INDEX idx_audit_logs_category_created 
    ON public.audit_logs (event_category, created_at DESC);

-- Retention: efficient deletion of old records
CREATE INDEX idx_audit_logs_created_at 
    ON public.audit_logs (created_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- SELECT: Namespace-scoped + platform admin override
CREATE POLICY "Users can view audit logs in current namespace"
    ON public.audit_logs FOR SELECT
    USING (
        namespace_id = get_current_namespace_id()
        OR check_is_platform_admin()
    );

-- INSERT: Trigger function (SECURITY DEFINER) writes logs
CREATE POLICY "Service role can insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (true);

-- No UPDATE policy — audit logs are immutable

-- DELETE: Platform admin only (retention cleanup)
CREATE POLICY "Platform admins can delete audit logs for retention"
    ON public.audit_logs FOR DELETE
    USING (check_is_platform_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. GRANTS
-- ─────────────────────────────────────────────────────────────────────────────

GRANT SELECT ON public.audit_logs TO authenticated;
GRANT INSERT ON public.audit_logs TO authenticated;
GRANT DELETE ON public.audit_logs TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION (run these after the script completes)
-- ─────────────────────────────────────────────────────────────────────────────

-- Should return 1
SELECT count(*) AS table_exists 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'audit_logs';

-- Should return 5
SELECT count(*) AS index_count 
FROM pg_indexes 
WHERE schemaname = 'public' AND tablename = 'audit_logs';

-- Should return true
SELECT rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'audit_logs';

-- Should return 3 (SELECT, INSERT, DELETE)
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'audit_logs'
ORDER BY cmd;
