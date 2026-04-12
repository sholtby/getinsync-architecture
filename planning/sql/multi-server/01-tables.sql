-- =============================================================================
-- 01-tables.sql — Multi-Server Deployment Profile: Table Creation
-- =============================================================================
-- Creates: servers, server_role_types, deployment_profile_servers
-- Run in: Supabase SQL Editor
-- Author: Claude + Stuart
-- Date: 2026-04-12
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. server_role_types — Standard reference table
-- Pattern: integration_method_types
-- -----------------------------------------------------------------------------

CREATE TABLE public.server_role_types (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  description text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  is_system boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.server_role_types
  ADD CONSTRAINT server_role_types_pkey PRIMARY KEY (id);

ALTER TABLE public.server_role_types
  ADD CONSTRAINT server_role_types_code_key UNIQUE (code);

COMMENT ON TABLE public.server_role_types IS 'Reference table for server roles in deployment profile server relationships';
COMMENT ON COLUMN public.server_role_types.code IS 'Unique code used as soft FK from deployment_profile_servers.server_role';
COMMENT ON COLUMN public.server_role_types.name IS 'Display name for the server role';
COMMENT ON COLUMN public.server_role_types.display_order IS 'Sort order for UI dropdowns';
COMMENT ON COLUMN public.server_role_types.is_system IS 'If true, cannot be deleted by namespace admins';

ALTER TABLE public.server_role_types ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.server_role_types TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.server_role_types TO service_role;

-- Seed data
INSERT INTO public.server_role_types (code, name, description, display_order, is_active, is_system) VALUES
  ('database',    'Database Server',    'Hosts database engines (SQL Server, Oracle, PostgreSQL, etc.)',         10, true, true),
  ('web',         'Web Server',         'Hosts web/HTTP services (IIS, Apache, Nginx, etc.)',                   20, true, true),
  ('application', 'Application Server', 'Hosts application runtime (Tomcat, .NET, JBoss, etc.)',                30, true, true),
  ('file',        'File Server',        'Hosts shared file storage or file-based integrations',                 40, true, true),
  ('utility',     'Utility Server',     'Hosts batch jobs, scheduled tasks, or background services',            50, true, true),
  ('other',       'Other',              'Server role not covered by standard categories',                       60, true, true);


-- -----------------------------------------------------------------------------
-- 2. servers — Namespace-scoped server reference
-- Pattern: data_centers
-- -----------------------------------------------------------------------------

CREATE TABLE public.servers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  namespace_id uuid NOT NULL,
  name text NOT NULL,
  os text,
  data_center_id uuid,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.servers
  ADD CONSTRAINT servers_pkey PRIMARY KEY (id);

ALTER TABLE public.servers
  ADD CONSTRAINT servers_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;

ALTER TABLE public.servers
  ADD CONSTRAINT servers_data_center_id_fkey FOREIGN KEY (data_center_id) REFERENCES public.data_centers(id) ON DELETE SET NULL;

ALTER TABLE public.servers
  ADD CONSTRAINT servers_namespace_name_key UNIQUE (namespace_id, name);

ALTER TABLE public.servers
  ADD CONSTRAINT servers_status_check CHECK (status IN ('active', 'decommissioned'));

CREATE INDEX idx_servers_namespace_id ON public.servers (namespace_id);

COMMENT ON TABLE public.servers IS 'Namespace-scoped server reference for deployment profile infrastructure mapping';
COMMENT ON COLUMN public.servers.namespace_id IS 'Owning namespace — scopes visibility and RLS';
COMMENT ON COLUMN public.servers.name IS 'Server display name, e.g. PROD-SQL-01. Unique within namespace.';
COMMENT ON COLUMN public.servers.os IS 'Optional OS label, e.g. Windows Server 2022';
COMMENT ON COLUMN public.servers.data_center_id IS 'Optional link to the data_centers table for physical location';
COMMENT ON COLUMN public.servers.status IS 'Lifecycle status: active or decommissioned';
COMMENT ON COLUMN public.servers.notes IS 'Free-form notes about this server';

ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.servers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.servers TO service_role;

CREATE TRIGGER update_servers_updated_at
  BEFORE UPDATE ON public.servers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER audit_servers
  AFTER INSERT OR DELETE OR UPDATE ON public.servers
  FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


-- -----------------------------------------------------------------------------
-- 3. deployment_profile_servers — Junction table (many-to-many)
-- Pattern: application_contacts
-- -----------------------------------------------------------------------------

CREATE TABLE public.deployment_profile_servers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  deployment_profile_id uuid NOT NULL,
  server_id uuid NOT NULL,
  server_role text,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.deployment_profile_servers
  ADD CONSTRAINT deployment_profile_servers_pkey PRIMARY KEY (id);

ALTER TABLE public.deployment_profile_servers
  ADD CONSTRAINT deployment_profile_servers_dp_fkey FOREIGN KEY (deployment_profile_id)
    REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;

ALTER TABLE public.deployment_profile_servers
  ADD CONSTRAINT deployment_profile_servers_server_fkey FOREIGN KEY (server_id)
    REFERENCES public.servers(id) ON DELETE RESTRICT;

ALTER TABLE public.deployment_profile_servers
  ADD CONSTRAINT deployment_profile_servers_dp_server_key UNIQUE (deployment_profile_id, server_id);

CREATE INDEX idx_dps_deployment_profile_id ON public.deployment_profile_servers (deployment_profile_id);
CREATE INDEX idx_dps_server_id ON public.deployment_profile_servers (server_id);

COMMENT ON TABLE public.deployment_profile_servers IS 'Junction table linking deployment profiles to servers (many-to-many)';
COMMENT ON COLUMN public.deployment_profile_servers.deployment_profile_id IS 'FK to deployment_profiles — CASCADE on delete';
COMMENT ON COLUMN public.deployment_profile_servers.server_id IS 'FK to servers — RESTRICT on delete (must unlink before deleting server)';
COMMENT ON COLUMN public.deployment_profile_servers.server_role IS 'Soft reference to server_role_types.code (database, web, application, etc.)';
COMMENT ON COLUMN public.deployment_profile_servers.is_primary IS 'Marks the primary server for this DP (display priority, backward compat)';

ALTER TABLE public.deployment_profile_servers ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.deployment_profile_servers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deployment_profile_servers TO service_role;

CREATE TRIGGER audit_deployment_profile_servers
  AFTER INSERT OR DELETE OR UPDATE ON public.deployment_profile_servers
  FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


-- =============================================================================
-- Verification SELECT
-- =============================================================================
-- Consolidated verification: Supabase SQL Editor only shows the LAST result set.

WITH table_check AS (
  SELECT tablename
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename IN ('servers', 'server_role_types', 'deployment_profile_servers')
),
rls_check AS (
  SELECT tablename, rowsecurity
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename IN ('servers', 'server_role_types', 'deployment_profile_servers')
),
trigger_check AS (
  SELECT tgrelid::regclass::text AS table_name, tgname, tgfoid::regproc::text AS function_name
  FROM pg_trigger
  WHERE tgrelid IN (
    'public.servers'::regclass,
    'public.server_role_types'::regclass,
    'public.deployment_profile_servers'::regclass
  )
  AND NOT tgisinternal
),
constraint_check AS (
  SELECT conrelid::regclass::text AS table_name, conname, pg_get_constraintdef(oid) AS definition
  FROM pg_constraint
  WHERE conrelid IN (
    'public.servers'::regclass,
    'public.server_role_types'::regclass,
    'public.deployment_profile_servers'::regclass
  )
),
seed_check AS (
  SELECT code, name, display_order FROM public.server_role_types ORDER BY display_order
),
grant_check AS (
  SELECT table_name, grantee, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
  FROM information_schema.role_table_grants
  WHERE table_name IN ('servers', 'server_role_types', 'deployment_profile_servers')
    AND grantee IN ('authenticated', 'service_role')
  GROUP BY table_name, grantee
)
SELECT ord, section, details FROM (
  -- Section 1: Tables exist
  SELECT 1 AS ord, 'tables_created' AS section,
         jsonb_build_object('tables', (SELECT jsonb_agg(tablename) FROM table_check)) AS details
  UNION ALL
  -- Section 2: RLS enabled
  SELECT 2, 'rls_enabled',
         jsonb_build_object('rls', (SELECT jsonb_agg(jsonb_build_object('table', tablename, 'rls', rowsecurity)) FROM rls_check))
  UNION ALL
  -- Section 3: Triggers
  SELECT 3, 'triggers',
         jsonb_build_object('triggers', (SELECT jsonb_agg(jsonb_build_object('table', table_name, 'trigger', tgname, 'function', function_name)) FROM trigger_check))
  UNION ALL
  -- Section 4: Constraints
  SELECT 4, 'constraints',
         jsonb_build_object('constraints', (SELECT jsonb_agg(jsonb_build_object('table', table_name, 'name', conname, 'def', definition)) FROM constraint_check))
  UNION ALL
  -- Section 5: Seed data
  SELECT 5, 'seed_data',
         jsonb_build_object('server_role_types', (SELECT jsonb_agg(jsonb_build_object('code', code, 'name', name, 'order', display_order)) FROM seed_check))
  UNION ALL
  -- Section 6: GRANTs
  SELECT 6, 'grants',
         jsonb_build_object('grants', (SELECT jsonb_agg(jsonb_build_object('table', table_name, 'grantee', grantee, 'privileges', privileges)) FROM grant_check))
) x
ORDER BY ord;
