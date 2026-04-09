-- =============================================================================
-- CSV Import Schema Changes
-- Date: 2026-04-09
-- Purpose: Import batch tracking + undo capability for self-serve CSV import
-- Run in: Supabase SQL Editor (Stuart)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. import_batches — tracks each CSV import for audit trail and undo
-- -----------------------------------------------------------------------------

CREATE TABLE public.import_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES public.namespaces(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  imported_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  filename TEXT NOT NULL,
  row_count INTEGER NOT NULL DEFAULT 0,
  skipped_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'rolled_back')),
  created_at TIMESTAMPTZ DEFAULT now(),
  rolled_back_at TIMESTAMPTZ
);

-- GRANTs
GRANT SELECT, INSERT, UPDATE ON public.import_batches TO authenticated;
-- No DELETE grant — batches are immutable audit records

-- RLS
ALTER TABLE public.import_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view import_batches in current namespace"
  ON public.import_batches
  FOR SELECT
  USING (namespace_id = get_current_namespace_id());

CREATE POLICY "Namespace admins can insert import_batches"
  ON public.import_batches
  FOR INSERT
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
    )
  );

CREATE POLICY "Namespace admins can update import_batches"
  ON public.import_batches
  FOR UPDATE
  USING (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
    )
  )
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (
      check_is_platform_admin()
      OR check_is_namespace_admin_of_namespace(namespace_id)
    )
  );

-- Audit trigger
CREATE TRIGGER audit_import_batches
  AFTER INSERT OR UPDATE OR DELETE ON public.import_batches
  FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- -----------------------------------------------------------------------------
-- 2. applications.import_batch_id — tags imported apps for batch undo
-- -----------------------------------------------------------------------------

ALTER TABLE public.applications
  ADD COLUMN import_batch_id UUID REFERENCES public.import_batches(id) ON DELETE SET NULL;

-- Index for batch lookup (undo queries filter on this)
CREATE INDEX idx_applications_import_batch_id
  ON public.applications(import_batch_id)
  WHERE import_batch_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 3. applications.external_id — customer correlation key to source systems
-- -----------------------------------------------------------------------------

ALTER TABLE public.applications
  ADD COLUMN external_id TEXT;

-- =============================================================================
-- Verification queries (run after applying)
-- =============================================================================

-- Check GRANTs
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'import_batches' AND grantee IN ('authenticated', 'anon');

-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'import_batches';

-- Check policies
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'import_batches';

-- Check triggers
SELECT tgname, tgfoid::regproc
FROM pg_trigger
WHERE tgrelid = 'public.import_batches'::regclass AND NOT tgisinternal;

-- Check new columns on applications
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'applications' AND column_name IN ('import_batch_id', 'external_id');
