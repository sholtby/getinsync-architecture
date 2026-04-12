-- =============================================================================
-- 02-rls.sql — Multi-Server Deployment Profile: RLS Policies
-- =============================================================================
-- Creates RLS policies for: servers, server_role_types, deployment_profile_servers
-- Run AFTER 01-tables.sql
-- Run in: Supabase SQL Editor
-- Author: Claude + Stuart
-- Date: 2026-04-12
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. server_role_types — Reference table pattern
-- Pattern: integration_method_types (Anyone SELECT, Platform admins manage)
-- -----------------------------------------------------------------------------

CREATE POLICY "Anyone can view server_role_types"
  ON public.server_role_types
  FOR SELECT
  USING (true);

CREATE POLICY "Platform admins can manage server_role_types"
  ON public.server_role_types
  USING (public.check_is_platform_admin())
  WITH CHECK (public.check_is_platform_admin());


-- -----------------------------------------------------------------------------
-- 2. servers — Namespace-scoped
-- Pattern: data_centers (namespace SELECT, namespace admin INSERT/UPDATE/DELETE)
-- Enhancement: editors+ can INSERT/UPDATE (not just admins)
-- -----------------------------------------------------------------------------

-- SELECT: Any user in the namespace can view servers
CREATE POLICY "Users can view servers in current namespace"
  ON public.servers
  FOR SELECT
  USING (
    (namespace_id = public.get_current_namespace_id())
    OR public.check_is_platform_admin()
  );

-- INSERT: Editors+ in the namespace can create servers
CREATE POLICY "Editors can insert servers in current namespace"
  ON public.servers
  FOR INSERT
  WITH CHECK (
    (namespace_id = public.get_current_namespace_id())
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (
        SELECT 1 FROM public.workspace_users wu
        JOIN public.workspaces w ON w.id = wu.workspace_id
        WHERE w.namespace_id = public.get_current_namespace_id()
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );

-- UPDATE: Editors+ in the namespace can update servers
CREATE POLICY "Editors can update servers in current namespace"
  ON public.servers
  FOR UPDATE
  USING (
    (namespace_id = public.get_current_namespace_id())
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (
        SELECT 1 FROM public.workspace_users wu
        JOIN public.workspaces w ON w.id = wu.workspace_id
        WHERE w.namespace_id = public.get_current_namespace_id()
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  )
  WITH CHECK (
    (namespace_id = public.get_current_namespace_id())
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(namespace_id)
      OR EXISTS (
        SELECT 1 FROM public.workspace_users wu
        JOIN public.workspaces w ON w.id = wu.workspace_id
        WHERE w.namespace_id = public.get_current_namespace_id()
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );

-- DELETE: Admins only (namespace or platform)
CREATE POLICY "Admins can delete servers in current namespace"
  ON public.servers
  FOR DELETE
  USING (
    (namespace_id = public.get_current_namespace_id())
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(namespace_id)
    )
  );


-- -----------------------------------------------------------------------------
-- 3. deployment_profile_servers — Junction table
-- Pattern: application_contacts (scope through parent → workspace → namespace)
-- Parent chain: deployment_profile_servers → deployment_profiles → workspaces → namespace
-- -----------------------------------------------------------------------------

-- SELECT: Any user in the namespace can view DP-server links
CREATE POLICY "Users can view deployment_profile_servers in current namespace"
  ON public.deployment_profile_servers
  FOR SELECT
  USING (
    deployment_profile_id IN (
      SELECT dp.id FROM public.deployment_profiles dp
      JOIN public.workspaces w ON w.id = dp.workspace_id
      WHERE w.namespace_id = public.get_current_namespace_id()
    )
  );

-- INSERT: Editors+ in the workspace can create links
CREATE POLICY "Editors can insert deployment_profile_servers in current namespace"
  ON public.deployment_profile_servers
  FOR INSERT
  WITH CHECK (
    (deployment_profile_id IN (
      SELECT dp.id FROM public.deployment_profiles dp
      JOIN public.workspaces w ON w.id = dp.workspace_id
      WHERE w.namespace_id = public.get_current_namespace_id()
    ))
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM public.deployment_profiles dp
        JOIN public.workspace_users wu ON wu.workspace_id = dp.workspace_id
        WHERE dp.id = deployment_profile_servers.deployment_profile_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );

-- UPDATE: Editors+ in the workspace can update links
CREATE POLICY "Editors can update deployment_profile_servers in current namespace"
  ON public.deployment_profile_servers
  FOR UPDATE
  USING (
    (deployment_profile_id IN (
      SELECT dp.id FROM public.deployment_profiles dp
      JOIN public.workspaces w ON w.id = dp.workspace_id
      WHERE w.namespace_id = public.get_current_namespace_id()
    ))
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM public.deployment_profiles dp
        JOIN public.workspace_users wu ON wu.workspace_id = dp.workspace_id
        WHERE dp.id = deployment_profile_servers.deployment_profile_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  )
  WITH CHECK (
    (deployment_profile_id IN (
      SELECT dp.id FROM public.deployment_profiles dp
      JOIN public.workspaces w ON w.id = dp.workspace_id
      WHERE w.namespace_id = public.get_current_namespace_id()
    ))
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM public.deployment_profiles dp
        JOIN public.workspace_users wu ON wu.workspace_id = dp.workspace_id
        WHERE dp.id = deployment_profile_servers.deployment_profile_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );

-- DELETE: Editors+ in the workspace can remove links
CREATE POLICY "Editors can delete deployment_profile_servers in current namespace"
  ON public.deployment_profile_servers
  FOR DELETE
  USING (
    (deployment_profile_id IN (
      SELECT dp.id FROM public.deployment_profiles dp
      JOIN public.workspaces w ON w.id = dp.workspace_id
      WHERE w.namespace_id = public.get_current_namespace_id()
    ))
    AND (
      public.check_is_platform_admin()
      OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())
      OR EXISTS (
        SELECT 1 FROM public.deployment_profiles dp
        JOIN public.workspace_users wu ON wu.workspace_id = dp.workspace_id
        WHERE dp.id = deployment_profile_servers.deployment_profile_id
          AND wu.user_id = auth.uid()
          AND wu.role = ANY(ARRAY['admin', 'editor'])
      )
    )
  );


-- =============================================================================
-- Verification SELECT
-- =============================================================================

WITH policy_check AS (
  SELECT tablename, policyname, cmd, roles::text AS roles
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('servers', 'server_role_types', 'deployment_profile_servers')
  ORDER BY tablename, cmd, policyname
)
SELECT ord, section, details FROM (
  -- Section 1: Policy count per table
  SELECT 1 AS ord, 'policy_counts' AS section,
         jsonb_build_object('counts', (
           SELECT jsonb_agg(jsonb_build_object('table', tablename, 'count', cnt))
           FROM (SELECT tablename, count(*) AS cnt FROM policy_check GROUP BY tablename) sub
         )) AS details
  UNION ALL
  -- Section 2: All policies detail
  SELECT 2, 'server_role_types_policies',
         jsonb_build_object('policies', (
           SELECT jsonb_agg(jsonb_build_object('policy', policyname, 'cmd', cmd))
           FROM policy_check WHERE tablename = 'server_role_types'
         ))
  UNION ALL
  SELECT 3, 'servers_policies',
         jsonb_build_object('policies', (
           SELECT jsonb_agg(jsonb_build_object('policy', policyname, 'cmd', cmd))
           FROM policy_check WHERE tablename = 'servers'
         ))
  UNION ALL
  SELECT 4, 'deployment_profile_servers_policies',
         jsonb_build_object('policies', (
           SELECT jsonb_agg(jsonb_build_object('policy', policyname, 'cmd', cmd))
           FROM policy_check WHERE tablename = 'deployment_profile_servers'
         ))
) x
ORDER BY ord;
