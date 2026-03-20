-- =============================================================================
-- GetInSync NextGen — Stage 1: Shared Data Layer
-- =============================================================================
-- Run in Supabase SQL Editor as 7 chunks (marked with chunk separators).
-- Each chunk can be validated independently before proceeding.
--
-- Chunk 0: vw_run_rate_by_lifecycle_status (new view)
-- Chunk 1: vw_explorer_detail (new view)
-- Chunk 2: ai_chat_conversations + ai_chat_messages (new tables)
-- Chunk 3: GRANTs, RLS, audit triggers for chat tables
-- Chunk 4: Integration-DP Phase 1 — schema migration (2 nullable FKs)
-- Chunk 5: Integration-DP Phase 2 — vw_integration_detail rebuild
-- Chunk 6: Validation queries
--
-- Schema impact: 97→99 tables, 36→38 views, 372→380 RLS policies
-- =============================================================================


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 0: vw_run_rate_by_lifecycle_status                                ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ Purpose: Aggregates application run rate by worst technology lifecycle   ║
-- ║          status. Powers the Explorer "Annual Run Rate by Support Status" ║
-- ║          card and the AI Chat cost-analysis MCP tool.                    ║
-- ║                                                                         ║
-- ║ Logic: For each operational application, determine the WORST lifecycle   ║
-- ║        status across all its technology tags, then sum the app's         ║
-- ║        total_run_rate into that bucket.                                  ║
-- ║                                                                         ║
-- ║ Consumers: Explorer tab, AI Chat cost-analysis tool, semantic layer     ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

CREATE OR REPLACE VIEW public.vw_run_rate_by_lifecycle_status
WITH (security_invoker = 'true') AS

WITH app_worst_lifecycle AS (
  -- For each application, find its worst technology lifecycle status.
  -- Ranking: end_of_support(1) > extended(2) > mainstream(3) > preview(4) > incomplete_data(5) > no_tech(6)
  SELECT
    tlr.application_id,
    tlr.namespace_id,
    MIN(
      CASE tlr.lifecycle_status
        WHEN 'end_of_support' THEN 1
        WHEN 'extended'       THEN 2
        WHEN 'mainstream'     THEN 3
        WHEN 'preview'        THEN 4
        WHEN 'incomplete_data' THEN 5
        ELSE 6
      END
    ) AS worst_rank
  FROM public.vw_technology_tag_lifecycle_risk tlr
  WHERE tlr.app_operational_status = 'operational'
  GROUP BY tlr.application_id, tlr.namespace_id
)

SELECT
  rr.namespace_id,
  CASE awl.worst_rank
    WHEN 1 THEN 'end_of_support'
    WHEN 2 THEN 'extended'
    WHEN 3 THEN 'mainstream'
    WHEN 4 THEN 'preview'
    WHEN 5 THEN 'incomplete_data'
    ELSE 'no_technology_data'
  END AS worst_lifecycle_status,
  COUNT(DISTINCT rr.application_id) AS application_count,
  SUM(rr.total_run_rate) AS total_run_rate,
  SUM(rr.service_cost)   AS total_service_cost,
  SUM(rr.bundle_cost)    AS total_bundle_cost
FROM public.vw_application_run_rate rr
LEFT JOIN app_worst_lifecycle awl ON awl.application_id = rr.application_id
GROUP BY rr.namespace_id,
  CASE awl.worst_rank
    WHEN 1 THEN 'end_of_support'
    WHEN 2 THEN 'extended'
    WHEN 3 THEN 'mainstream'
    WHEN 4 THEN 'preview'
    WHEN 5 THEN 'incomplete_data'
    ELSE 'no_technology_data'
  END;

COMMENT ON VIEW public.vw_run_rate_by_lifecycle_status IS
  'Aggregates application run rate by worst technology lifecycle status. '
  'Each app is classified by its worst tech tag lifecycle, then costs are summed per status bucket. '
  'Consumer: Explorer "Annual Run Rate by Support Status" card, AI Chat cost-analysis tool.';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 1: vw_explorer_detail                                             ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ Purpose: Composite detail table for the Explorer tab and AI Chat        ║
-- ║          application-detail MCP tool. One row per application with      ║
-- ║          business scores, tech scores, worst lifecycle, cost, contacts.  ║
-- ║                                                                         ║
-- ║ Grain: One row per operational application (primary DP scores).         ║
-- ║        For apps with multiple DPs, uses the primary DP for tech scores  ║
-- ║        and sums cost across all DPs via vw_application_run_rate.        ║
-- ║                                                                         ║
-- ║ Consumers: Explorer detail table, AI Chat application-detail tool       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

CREATE OR REPLACE VIEW public.vw_explorer_detail
WITH (security_invoker = 'true') AS

WITH primary_dp AS (
  -- Get the primary deployment profile for each application (tech scores live here)
  SELECT DISTINCT ON (dp.application_id)
    dp.id AS dp_id,
    dp.application_id,
    dp.tech_health,
    dp.tech_risk,
    dp.paid_action,
    dp.tech_assessment_status,
    dp.estimated_tech_debt,
    dp.hosting_type
  FROM public.deployment_profiles dp
  WHERE dp.dp_type = 'application'
    AND dp.operational_status = 'operational'
  ORDER BY dp.application_id, dp.is_primary DESC, dp.created_at ASC
),

primary_pa AS (
  -- Get the publisher portfolio assignment (business scores live here)
  SELECT DISTINCT ON (pa.application_id)
    pa.application_id,
    pa.business_fit,
    pa.criticality,
    pa.time_quadrant,
    pa.business_assessment_status,
    pa.remediation_effort
  FROM public.portfolio_assignments pa
  WHERE pa.relationship_type = 'publisher'
  ORDER BY pa.application_id, pa.created_at ASC
),

app_worst_lifecycle AS (
  -- Worst technology lifecycle status per application
  SELECT
    tlr.application_id,
    MIN(
      CASE tlr.lifecycle_status
        WHEN 'end_of_support' THEN 1
        WHEN 'extended'       THEN 2
        WHEN 'mainstream'     THEN 3
        WHEN 'preview'        THEN 4
        WHEN 'incomplete_data' THEN 5
        ELSE 6
      END
    ) AS worst_rank,
    COUNT(*) AS tech_tag_count
  FROM public.vw_technology_tag_lifecycle_risk tlr
  WHERE tlr.app_operational_status = 'operational'
  GROUP BY tlr.application_id
),

owner_contact AS (
  -- Primary business owner contact per application
  SELECT DISTINCT ON (ac.application_id)
    ac.application_id,
    c.display_name AS owner_name
  FROM public.application_contacts ac
  JOIN public.contacts c ON c.id = ac.contact_id
  WHERE ac.role_type = 'business_owner'
  ORDER BY ac.application_id, ac.is_primary DESC, ac.created_at ASC
),

support_contact AS (
  -- Primary support/technical owner contact per application
  SELECT DISTINCT ON (ac.application_id)
    ac.application_id,
    c.display_name AS support_name
  FROM public.application_contacts ac
  JOIN public.contacts c ON c.id = ac.contact_id
  WHERE ac.role_type IN ('support', 'technical_owner')
  ORDER BY ac.application_id, ac.is_primary DESC, ac.created_at ASC
),

integration_counts AS (
  -- Integration count per application (source + target sides)
  SELECT app_id, SUM(cnt) AS integration_count
  FROM (
    SELECT source_application_id AS app_id, COUNT(*) AS cnt
    FROM public.application_integrations
    WHERE status = 'active'
    GROUP BY source_application_id
    UNION ALL
    SELECT target_application_id AS app_id, COUNT(*) AS cnt
    FROM public.application_integrations
    WHERE status = 'active' AND target_application_id IS NOT NULL
    GROUP BY target_application_id
  ) sub
  GROUP BY app_id
)

SELECT
  a.id AS application_id,
  a.name AS application_name,
  a.workspace_id,
  w.name AS workspace_name,
  w.namespace_id,
  a.operational_status,

  -- Business scores (from portfolio_assignments)
  COALESCE(pa.business_fit, 0) AS business_fit,
  COALESCE(pa.criticality, 0) AS criticality,
  CASE WHEN COALESCE(pa.criticality, 0) >= 50 THEN true ELSE false END AS is_crown_jewel,
  pa.time_quadrant,
  pa.business_assessment_status,

  -- Tech scores (from primary deployment_profile)
  COALESCE(pdp.tech_health, 0) AS tech_health,
  COALESCE(pdp.tech_risk, 0) AS tech_risk,
  pdp.paid_action,
  pdp.tech_assessment_status,
  COALESCE(pdp.estimated_tech_debt, 0) AS estimated_tech_debt,
  pdp.hosting_type,

  -- Worst technology lifecycle
  CASE awl.worst_rank
    WHEN 1 THEN 'end_of_support'
    WHEN 2 THEN 'extended'
    WHEN 3 THEN 'mainstream'
    WHEN 4 THEN 'preview'
    WHEN 5 THEN 'incomplete_data'
    ELSE 'no_technology_data'
  END AS worst_lifecycle_status,
  COALESCE(awl.tech_tag_count, 0) AS tech_tag_count,

  -- Cost (from vw_application_run_rate)
  COALESCE(rr.total_run_rate, 0) AS total_run_rate,
  COALESCE(rr.service_cost, 0) AS service_cost,
  COALESCE(rr.bundle_cost, 0) AS bundle_cost,

  -- Contacts
  oc.owner_name,
  sc.support_name,

  -- Integration count
  COALESCE(ic.integration_count, 0) AS integration_count,

  -- Remediation
  pa.remediation_effort

FROM public.applications a
JOIN public.workspaces w ON w.id = a.workspace_id
LEFT JOIN primary_dp pdp ON pdp.application_id = a.id
LEFT JOIN primary_pa pa ON pa.application_id = a.id
LEFT JOIN app_worst_lifecycle awl ON awl.application_id = a.id
LEFT JOIN public.vw_application_run_rate rr ON rr.application_id = a.id
LEFT JOIN owner_contact oc ON oc.application_id = a.id
LEFT JOIN support_contact sc ON sc.application_id = a.id
LEFT JOIN integration_counts ic ON ic.app_id = a.id
WHERE a.operational_status = 'operational';

COMMENT ON VIEW public.vw_explorer_detail IS
  'Composite application detail view. One row per operational application with '
  'business scores (from PA), tech scores (from primary DP), worst lifecycle status, '
  'run rate cost, owner/support contacts, and active integration count. '
  'Consumer: Explorer detail table, AI Chat application-detail tool, Power BI export.';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 2: AI Chat tables                                                 ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ Purpose: Conversation persistence for AI Chat MVP.                      ║
-- ║          Simple session-scoped conversations, no threading/branching.    ║
-- ║                                                                         ║
-- ║ Consumers: Edge Function E1 (ai-chat), NativeChatPanel                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ai_chat_conversations: one row per chat session
CREATE TABLE public.ai_chat_conversations (
  id          UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  namespace_id UUID NOT NULL REFERENCES public.namespaces(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT,
  status      TEXT DEFAULT 'active' NOT NULL,
  message_count INTEGER DEFAULT 0 NOT NULL,
  total_tokens  INTEGER DEFAULT 0,
  metadata    JSONB DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT now() NOT NULL,

  CONSTRAINT chk_chat_status CHECK (status IN ('active', 'archived', 'deleted'))
);

COMMENT ON TABLE public.ai_chat_conversations IS
  'AI Chat conversation sessions. Namespace-scoped for RLS. '
  'Status lifecycle: active → archived → deleted.';

-- ai_chat_messages: individual messages within a conversation
CREATE TABLE public.ai_chat_messages (
  id              UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES public.ai_chat_conversations(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,
  content         TEXT NOT NULL,
  token_count     INTEGER,
  tool_name       TEXT,
  tool_input      JSONB,
  tool_output     JSONB,
  metadata        JSONB DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ DEFAULT now() NOT NULL,

  CONSTRAINT chk_message_role CHECK (role IN ('user', 'assistant', 'system', 'tool_call', 'tool_result'))
);

COMMENT ON TABLE public.ai_chat_messages IS
  'Individual messages in an AI Chat conversation. Ordered by created_at. '
  'Tool calls and results stored as separate messages for audit trail.';

-- Indexes
CREATE INDEX idx_chat_conversations_namespace ON public.ai_chat_conversations(namespace_id);
CREATE INDEX idx_chat_conversations_user ON public.ai_chat_conversations(user_id);
CREATE INDEX idx_chat_conversations_updated ON public.ai_chat_conversations(updated_at DESC);
CREATE INDEX idx_chat_messages_conversation ON public.ai_chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_created ON public.ai_chat_messages(created_at);

-- updated_at trigger for conversations
CREATE TRIGGER update_ai_chat_conversations_updated_at
  BEFORE UPDATE ON public.ai_chat_conversations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 3: GRANTs, RLS, audit triggers for chat tables + view GRANTs      ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ── GRANTs: Views ──
GRANT SELECT ON public.vw_run_rate_by_lifecycle_status TO authenticated;
GRANT SELECT ON public.vw_run_rate_by_lifecycle_status TO service_role;
GRANT SELECT ON public.vw_explorer_detail TO authenticated;
GRANT SELECT ON public.vw_explorer_detail TO service_role;

-- ── GRANTs: Tables ──
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_chat_conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_chat_conversations TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_chat_messages TO service_role;

-- ── RLS: Enable ──
ALTER TABLE public.ai_chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_messages ENABLE ROW LEVEL SECURITY;

-- ── RLS: ai_chat_conversations (4 policies) ──
CREATE POLICY "ai_chat_conversations_select" ON public.ai_chat_conversations
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.platform_admins WHERE user_id = auth.uid())
  );

CREATE POLICY "ai_chat_conversations_insert" ON public.ai_chat_conversations
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "ai_chat_conversations_update" ON public.ai_chat_conversations
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "ai_chat_conversations_delete" ON public.ai_chat_conversations
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.platform_admins WHERE user_id = auth.uid())
  );

-- ── RLS: ai_chat_messages (4 policies) ──
CREATE POLICY "ai_chat_messages_select" ON public.ai_chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.ai_chat_conversations c
      WHERE c.id = conversation_id
        AND (c.user_id = auth.uid()
             OR EXISTS (SELECT 1 FROM public.platform_admins WHERE user_id = auth.uid()))
    )
  );

CREATE POLICY "ai_chat_messages_insert" ON public.ai_chat_messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.ai_chat_conversations c
      WHERE c.id = conversation_id AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "ai_chat_messages_update" ON public.ai_chat_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.ai_chat_conversations c
      WHERE c.id = conversation_id AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "ai_chat_messages_delete" ON public.ai_chat_messages
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.ai_chat_conversations c
      WHERE c.id = conversation_id
        AND (c.user_id = auth.uid()
             OR EXISTS (SELECT 1 FROM public.platform_admins WHERE user_id = auth.uid()))
    )
  );

-- ── Audit triggers ──
CREATE TRIGGER audit_ai_chat_conversations
  AFTER INSERT OR UPDATE OR DELETE ON public.ai_chat_conversations
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_ai_chat_messages
  AFTER INSERT OR UPDATE OR DELETE ON public.ai_chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 4: Integration-DP Phase 1 — Schema Migration                      ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ ADR: adr-integration-dp-alignment.md v1.2 (ACCEPTED)                    ║
-- ║                                                                         ║
-- ║ Adds nullable DP foreign keys to application_integrations.              ║
-- ║ Existing integrations remain valid at the app level.                    ║
-- ║ New integrations can optionally specify DP-level granularity.           ║
-- ║ Auto-assigns existing integrations to primary DP of source app.        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 4a: Add nullable FK columns
ALTER TABLE public.application_integrations
  ADD COLUMN source_deployment_profile_id UUID
    REFERENCES public.deployment_profiles(id) ON DELETE SET NULL,
  ADD COLUMN target_deployment_profile_id UUID
    REFERENCES public.deployment_profiles(id) ON DELETE SET NULL;

-- 4b: Index for DP-scoped lookups (Visual tab Level 3, integration counts)
CREATE INDEX idx_integrations_source_dp
  ON public.application_integrations(source_deployment_profile_id)
  WHERE source_deployment_profile_id IS NOT NULL;

CREATE INDEX idx_integrations_target_dp
  ON public.application_integrations(target_deployment_profile_id)
  WHERE target_deployment_profile_id IS NOT NULL;

-- 4c: Backfill — assign existing integrations to primary DP of source app
-- This is the safe default per ADR: "attach to the default/first DP"
UPDATE public.application_integrations ai
SET source_deployment_profile_id = (
  SELECT dp.id
  FROM public.deployment_profiles dp
  WHERE dp.application_id = ai.source_application_id
    AND dp.dp_type = 'application'
    AND dp.is_primary = true
  LIMIT 1
)
WHERE ai.source_deployment_profile_id IS NULL;

-- 4d: Backfill — assign target DP for internal integrations (target_application_id IS NOT NULL)
UPDATE public.application_integrations ai
SET target_deployment_profile_id = (
  SELECT dp.id
  FROM public.deployment_profiles dp
  WHERE dp.application_id = ai.target_application_id
    AND dp.dp_type = 'application'
    AND dp.is_primary = true
  LIMIT 1
)
WHERE ai.target_application_id IS NOT NULL
  AND ai.target_deployment_profile_id IS NULL;

-- 4e: Verify backfill results
SELECT
  COUNT(*) AS total_integrations,
  COUNT(source_deployment_profile_id) AS with_source_dp,
  COUNT(target_deployment_profile_id) AS with_target_dp,
  COUNT(*) FILTER (WHERE source_deployment_profile_id IS NULL) AS missing_source_dp,
  COUNT(*) FILTER (WHERE target_application_id IS NOT NULL AND target_deployment_profile_id IS NULL) AS missing_target_dp
FROM public.application_integrations;
-- Expected: missing_source_dp should be 0 or only apps with no primary DP
-- Expected: missing_target_dp should be 0 or only apps with no primary DP


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 5: Integration-DP Phase 2 — View Rebuild                          ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ Rebuilds vw_integration_detail to include DP columns and names.         ║
-- ║ Additive only — all existing columns preserved, 4 new columns added.   ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

CREATE OR REPLACE VIEW public.vw_integration_detail
WITH (security_invoker = 'true') AS
SELECT
  ai.id,
  ai.name AS integration_name,

  -- Source: application + workspace
  ai.source_application_id,
  sa.name AS source_application_name,
  sw.id AS source_workspace_id,
  sw.name AS source_workspace_name,
  sw.namespace_id,

  -- Source: deployment profile (NEW)
  ai.source_deployment_profile_id,
  sdp.name AS source_deployment_profile_name,

  -- Target: application + workspace
  ai.target_application_id,
  ta.name AS target_application_name,
  tw.name AS target_workspace_name,

  -- Target: deployment profile (NEW)
  ai.target_deployment_profile_id,
  tdp.name AS target_deployment_profile_name,

  -- External system
  ai.external_system_name,
  ai.external_organization_id,
  eo.name AS external_organization_name,

  -- Classification
  CASE
    WHEN ai.target_application_id IS NOT NULL THEN 'internal'
    ELSE 'external'
  END AS integration_category,

  -- Integration attributes
  ai.direction,
  ai.integration_type,
  ai.data_format,
  ai.frequency,
  ai.criticality,
  ai.sensitivity,
  ai.data_classification,
  ai.status,
  ai.description,
  ai.sla_description,
  ai.notes,
  ai.data_tags,
  ai.created_at,
  ai.updated_at,

  -- Contact aggregates
  (SELECT COUNT(*) FROM public.integration_contacts ic WHERE ic.integration_id = ai.id) AS contact_count,
  (SELECT c.display_name
   FROM public.integration_contacts ic
   JOIN public.contacts c ON c.id = ic.contact_id
   WHERE ic.integration_id = ai.id AND ic.is_primary = true
   LIMIT 1) AS primary_contact_name

FROM public.application_integrations ai
JOIN public.applications sa ON sa.id = ai.source_application_id
JOIN public.workspaces sw ON sw.id = sa.workspace_id
LEFT JOIN public.deployment_profiles sdp ON sdp.id = ai.source_deployment_profile_id
LEFT JOIN public.applications ta ON ta.id = ai.target_application_id
LEFT JOIN public.workspaces tw ON tw.id = ta.workspace_id
LEFT JOIN public.deployment_profiles tdp ON tdp.id = ai.target_deployment_profile_id
LEFT JOIN public.organizations eo ON eo.id = ai.external_organization_id;

COMMENT ON VIEW public.vw_integration_detail IS
  'Integration detail view with DP-level granularity. '
  'Includes source/target deployment profile names when specified. '
  'v2: Added source_deployment_profile_id/name and target_deployment_profile_id/name (Integration-DP ADR Phase 2).';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ CHUNK 6: Validation queries                                             ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║ Run after all chunks to confirm everything deployed correctly.           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 6a: Verify new views exist and return data
SELECT 'vw_run_rate_by_lifecycle_status' AS view_name, COUNT(*) AS row_count
FROM public.vw_run_rate_by_lifecycle_status
UNION ALL
SELECT 'vw_explorer_detail', COUNT(*) FROM public.vw_explorer_detail;

-- 6b: Verify new tables exist with correct columns
SELECT table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('ai_chat_conversations', 'ai_chat_messages')
GROUP BY table_name ORDER BY table_name;
-- Expected: ai_chat_conversations = 10, ai_chat_messages = 10

-- 6c: Verify RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('ai_chat_conversations', 'ai_chat_messages');
-- Expected: both = true

-- 6d: Verify GRANTs on new views
SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('vw_run_rate_by_lifecycle_status', 'vw_explorer_detail')
  AND grantee IN ('authenticated', 'service_role')
ORDER BY table_name, grantee;
-- Expected: 4 rows (2 views × 2 roles)

-- 6e: Verify GRANTs on new tables
SELECT table_name, grantee, string_agg(privilege_type, ', ' ORDER BY privilege_type)
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('ai_chat_conversations', 'ai_chat_messages')
  AND grantee IN ('authenticated', 'service_role')
GROUP BY table_name, grantee ORDER BY table_name, grantee;
-- Expected: 4 rows, each with "DELETE, INSERT, SELECT, UPDATE"

-- 6f: Verify audit triggers
SELECT event_object_table, trigger_name
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('ai_chat_conversations', 'ai_chat_messages')
  AND trigger_name LIKE 'audit_%';
-- Expected: 2 rows

-- 6g: Verify RLS policies (8 = 4 per chat table)
SELECT tablename, COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('ai_chat_conversations', 'ai_chat_messages')
GROUP BY tablename;
-- Expected: 4 per table

-- 6h: Verify integration-DP columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'application_integrations'
  AND column_name IN ('source_deployment_profile_id', 'target_deployment_profile_id');
-- Expected: 2 rows, both uuid, both YES (nullable)

-- 6i: Verify vw_integration_detail has new DP columns
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'vw_integration_detail'
  AND column_name LIKE '%deployment_profile%'
ORDER BY ordinal_position;
-- Expected: 4 columns (source_deployment_profile_id, source_deployment_profile_name,
--           target_deployment_profile_id, target_deployment_profile_name)

-- 6j: Sanity check on vw_explorer_detail
SELECT
  COUNT(*) AS total_apps,
  COUNT(*) FILTER (WHERE is_crown_jewel) AS crown_jewels,
  COUNT(*) FILTER (WHERE time_quadrant IS NOT NULL) AS with_time,
  COUNT(*) FILTER (WHERE total_run_rate > 0) AS with_cost,
  COUNT(*) FILTER (WHERE worst_lifecycle_status != 'no_technology_data') AS with_tech,
  COUNT(*) FILTER (WHERE owner_name IS NOT NULL) AS with_owner,
  COUNT(*) FILTER (WHERE integration_count > 0) AS with_integrations
FROM public.vw_explorer_detail;

-- 6k: Sanity check on vw_run_rate_by_lifecycle_status
SELECT worst_lifecycle_status, application_count, total_run_rate
FROM public.vw_run_rate_by_lifecycle_status
ORDER BY total_run_rate DESC;

-- 6l: Integration backfill results
SELECT
  COUNT(*) AS total_integrations,
  COUNT(source_deployment_profile_id) AS with_source_dp,
  COUNT(target_deployment_profile_id) AS with_target_dp,
  COUNT(*) FILTER (WHERE source_deployment_profile_id IS NULL) AS orphan_source,
  COUNT(*) FILTER (WHERE target_application_id IS NOT NULL AND target_deployment_profile_id IS NULL) AS orphan_target
FROM public.application_integrations;
