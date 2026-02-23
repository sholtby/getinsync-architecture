# Multi-Tenant Phase 1: Database Schema

## Overview

Add the foundational database tables for multi-tenant support. This phase is **schema only** â€” no UI changes yet.

**Goal:** Create Namespace, Workspace, and User tables with proper relationships, then add `workspace_id` to existing tables.

---

## Current Bolt.new Schema (What Exists)

The app currently has these tables:

| Table | Purpose |
|-------|---------|
| `applications` | Application pool (name, description, owner, cost, lifecycle) |
| `portfolios` | Portfolio definitions (name, description, is_default) |
| `portfolio_assignments` | Links apps to portfolios with assessment scores (B1-B10, T01-T15) |
| `business_assessments` | Legacy - assessment scores (being replaced by portfolio_assignments) |
| `technical_assessments` | Legacy - assessment scores (being replaced by portfolio_assignments) |
| `portfolio_settings` | Key-value settings store |
| `organization_settings` | Org name, max_project_budget |

**Current state:** All data is global â€” no tenant isolation. Anyone can see everything.

---

## New Tables to Create

### 1. namespaces

The top-level tenant/organization boundary.

```sql
CREATE TABLE public.namespaces (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  tier text NOT NULL DEFAULT 'free',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT namespaces_pkey PRIMARY KEY (id),
  CONSTRAINT namespaces_slug_unique UNIQUE (slug),
  CONSTRAINT namespaces_tier_check CHECK (tier IN ('free', 'pro', 'enterprise'))
);

CREATE INDEX idx_namespaces_slug ON public.namespaces USING btree (slug);
```

### 2. workspaces

Isolated working environments within a Namespace.

```sql
CREATE TABLE public.workspaces (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL,
  name text NOT NULL,
  slug text NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT workspaces_pkey PRIMARY KEY (id),
  CONSTRAINT workspaces_namespace_slug_unique UNIQUE (namespace_id, slug),
  CONSTRAINT workspaces_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE
);

CREATE INDEX idx_workspaces_namespace ON public.workspaces USING btree (namespace_id);
```

### 3. users

User accounts (extends Supabase auth.users).

```sql
CREATE TABLE public.users (
  id uuid NOT NULL,
  namespace_id uuid NOT NULL,
  email text NOT NULL,
  name text,
  namespace_role text NOT NULL DEFAULT 'member',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT users_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE,
  CONSTRAINT users_namespace_role_check CHECK (namespace_role IN ('admin', 'member'))
);

CREATE INDEX idx_users_namespace ON public.users USING btree (namespace_id);
CREATE INDEX idx_users_email ON public.users USING btree (email);
```

### 4. workspace_users

Join table linking users to workspaces with roles.

```sql
CREATE TABLE public.workspace_users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'editor',
  created_at timestamptz DEFAULT now(),
  CONSTRAINT workspace_users_pkey PRIMARY KEY (id),
  CONSTRAINT workspace_users_unique UNIQUE (workspace_id, user_id),
  CONSTRAINT workspace_users_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
  CONSTRAINT workspace_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT workspace_users_role_check CHECK (role IN ('admin', 'editor', 'viewer'))
);

CREATE INDEX idx_workspace_users_workspace ON public.workspace_users USING btree (workspace_id);
CREATE INDEX idx_workspace_users_user ON public.workspace_users USING btree (user_id);
```

---

## Modify Existing Tables

Add `workspace_id` to scope data to workspaces.

### 5. Alter applications table

```sql
-- Add workspace_id column (nullable initially for migration)
ALTER TABLE public.applications 
ADD COLUMN workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE;

-- Create index
CREATE INDEX idx_applications_workspace ON public.applications USING btree (workspace_id);
```

### 6. Alter portfolios table

```sql
-- Add workspace_id column
ALTER TABLE public.portfolios 
ADD COLUMN workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE;

-- Create index
CREATE INDEX idx_portfolios_workspace ON public.portfolios USING btree (workspace_id);

-- Note: is_default becomes per-workspace (one default per workspace)
```

### 7. Alter organization_settings table

Rename to `workspace_settings` and scope to workspace:

```sql
-- Rename table
ALTER TABLE public.organization_settings RENAME TO workspace_settings;

-- Add workspace_id column
ALTER TABLE public.workspace_settings 
ADD COLUMN workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE;

-- Add unique constraint (one settings row per workspace)
ALTER TABLE public.workspace_settings 
ADD CONSTRAINT workspace_settings_workspace_unique UNIQUE (workspace_id);
```

---

## Row Level Security (RLS) Policies

### Enable RLS on new tables

```sql
ALTER TABLE public.namespaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_users ENABLE ROW LEVEL SECURITY;
```

### Namespace policies

```sql
-- Users can only see their own namespace
CREATE POLICY "Users can view own namespace" ON public.namespaces
  FOR SELECT TO authenticated 
  USING (id IN (SELECT namespace_id FROM public.users WHERE id = auth.uid()));

-- Only namespace admins can update
CREATE POLICY "Namespace admins can update" ON public.namespaces
  FOR UPDATE TO authenticated 
  USING (id IN (
    SELECT namespace_id FROM public.users 
    WHERE id = auth.uid() AND namespace_role = 'admin'
  ));
```

### Workspace policies

```sql
-- Users can see workspaces they belong to (or all if namespace admin)
CREATE POLICY "Users can view their workspaces" ON public.workspaces
  FOR SELECT TO authenticated 
  USING (
    id IN (SELECT workspace_id FROM public.workspace_users WHERE user_id = auth.uid())
    OR
    namespace_id IN (
      SELECT namespace_id FROM public.users 
      WHERE id = auth.uid() AND namespace_role = 'admin'
    )
  );

-- Namespace admins can create workspaces
CREATE POLICY "Namespace admins can create workspaces" ON public.workspaces
  FOR INSERT TO authenticated 
  WITH CHECK (
    namespace_id IN (
      SELECT namespace_id FROM public.users 
      WHERE id = auth.uid() AND namespace_role = 'admin'
    )
  );

-- Namespace admins can update workspaces
CREATE POLICY "Namespace admins can update workspaces" ON public.workspaces
  FOR UPDATE TO authenticated 
  USING (
    namespace_id IN (
      SELECT namespace_id FROM public.users 
      WHERE id = auth.uid() AND namespace_role = 'admin'
    )
  );

-- Namespace admins can delete non-default workspaces
CREATE POLICY "Namespace admins can delete workspaces" ON public.workspaces
  FOR DELETE TO authenticated 
  USING (
    is_default = false AND
    namespace_id IN (
      SELECT namespace_id FROM public.users 
      WHERE id = auth.uid() AND namespace_role = 'admin'
    )
  );
```

### Update application policies (replace existing)

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Allow read access for all users" ON public.applications;
DROP POLICY IF EXISTS "Allow insert for all users" ON public.applications;
DROP POLICY IF EXISTS "Allow update for all users" ON public.applications;
DROP POLICY IF EXISTS "Allow delete for all users" ON public.applications;

-- Users can only see applications in their workspaces
CREATE POLICY "Users can view workspace applications" ON public.applications
  FOR SELECT TO authenticated 
  USING (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users WHERE user_id = auth.uid()
  ));

-- Editors and admins can insert
CREATE POLICY "Editors can insert applications" ON public.applications
  FOR INSERT TO authenticated 
  WITH CHECK (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users 
    WHERE user_id = auth.uid() AND role IN ('admin', 'editor')
  ));

-- Editors and admins can update
CREATE POLICY "Editors can update applications" ON public.applications
  FOR UPDATE TO authenticated 
  USING (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users 
    WHERE user_id = auth.uid() AND role IN ('admin', 'editor')
  ));

-- Admins can delete
CREATE POLICY "Admins can delete applications" ON public.applications
  FOR DELETE TO authenticated 
  USING (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users 
    WHERE user_id = auth.uid() AND role = 'admin'
  ));
```

### Update portfolio policies (replace existing)

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Allow read access for all users on portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Allow insert for all users on portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Allow update for all users on portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Allow delete for non-default portfolios" ON public.portfolios;

-- Users can view portfolios in their workspaces
CREATE POLICY "Users can view workspace portfolios" ON public.portfolios
  FOR SELECT TO authenticated 
  USING (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users WHERE user_id = auth.uid()
  ));

-- Editors can create portfolios
CREATE POLICY "Editors can create portfolios" ON public.portfolios
  FOR INSERT TO authenticated 
  WITH CHECK (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users 
    WHERE user_id = auth.uid() AND role IN ('admin', 'editor')
  ));

-- Editors can update portfolios
CREATE POLICY "Editors can update portfolios" ON public.portfolios
  FOR UPDATE TO authenticated 
  USING (workspace_id IN (
    SELECT workspace_id FROM public.workspace_users 
    WHERE user_id = auth.uid() AND role IN ('admin', 'editor')
  ));

-- Admins can delete non-default portfolios
CREATE POLICY "Admins can delete portfolios" ON public.portfolios
  FOR DELETE TO authenticated 
  USING (
    is_default = false AND
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_users 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
```

### Update portfolio_assignments policies

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Allow read access for all users on portfolio_assignments" ON public.portfolio_assignments;
DROP POLICY IF EXISTS "Allow insert for all users on portfolio_assignments" ON public.portfolio_assignments;
DROP POLICY IF EXISTS "Allow update for all users on portfolio_assignments" ON public.portfolio_assignments;
DROP POLICY IF EXISTS "Allow delete for all users on portfolio_assignments" ON public.portfolio_assignments;

-- Inherit access from portfolio's workspace
CREATE POLICY "Users can view workspace assignments" ON public.portfolio_assignments
  FOR SELECT TO authenticated 
  USING (portfolio_id IN (
    SELECT p.id FROM public.portfolios p
    JOIN public.workspace_users wu ON p.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));

CREATE POLICY "Editors can insert assignments" ON public.portfolio_assignments
  FOR INSERT TO authenticated 
  WITH CHECK (portfolio_id IN (
    SELECT p.id FROM public.portfolios p
    JOIN public.workspace_users wu ON p.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));

CREATE POLICY "Editors can update assignments" ON public.portfolio_assignments
  FOR UPDATE TO authenticated 
  USING (portfolio_id IN (
    SELECT p.id FROM public.portfolios p
    JOIN public.workspace_users wu ON p.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));

CREATE POLICY "Editors can delete assignments" ON public.portfolio_assignments
  FOR DELETE TO authenticated 
  USING (portfolio_id IN (
    SELECT p.id FROM public.portfolios p
    JOIN public.workspace_users wu ON p.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));
```

---

## Helper Functions

```sql
-- Get current user's namespace
CREATE OR REPLACE FUNCTION public.get_user_namespace_id()
RETURNS uuid AS $$
  SELECT namespace_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user's workspaces
CREATE OR REPLACE FUNCTION public.get_user_workspace_ids()
RETURNS SETOF uuid AS $$
  SELECT workspace_id FROM public.workspace_users WHERE user_id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user is namespace admin
CREATE OR REPLACE FUNCTION public.is_namespace_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND namespace_role = 'admin'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
```

---

## Migration Script (for existing data)

Migrate existing data to a default namespace/workspace:

```sql
-- 1. Create a default namespace for existing data
INSERT INTO public.namespaces (id, name, slug, tier)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default Organization', 'default', 'free');

-- 2. Create a default workspace in that namespace
INSERT INTO public.workspaces (id, namespace_id, name, slug, is_default)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'General',
  'general',
  true
);

-- 3. Assign existing applications to default workspace
UPDATE public.applications 
SET workspace_id = '00000000-0000-0000-0000-000000000002'
WHERE workspace_id IS NULL;

-- 4. Assign existing portfolios to default workspace
UPDATE public.portfolios 
SET workspace_id = '00000000-0000-0000-0000-000000000002'
WHERE workspace_id IS NULL;

-- 5. Update workspace_settings
UPDATE public.workspace_settings 
SET workspace_id = '00000000-0000-0000-0000-000000000002'
WHERE workspace_id IS NULL;

-- 6. Make workspace_id NOT NULL after migration
ALTER TABLE public.applications ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.portfolios ALTER COLUMN workspace_id SET NOT NULL;
```

---

## Verification

After running migrations, verify:

```sql
-- Check new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('namespaces', 'workspaces', 'users', 'workspace_users');

-- Check workspace_id columns added
SELECT table_name, column_name FROM information_schema.columns
WHERE table_schema = 'public' AND column_name = 'workspace_id';

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- Verify data migration
SELECT COUNT(*) as apps_with_workspace FROM public.applications WHERE workspace_id IS NOT NULL;
SELECT COUNT(*) as portfolios_with_workspace FROM public.portfolios WHERE workspace_id IS NOT NULL;
```

---

## What's NOT in This Phase

- No UI changes
- No signup/login flow changes  
- No workspace switcher
- No user management screens

Those come in subsequent phases.

---

## Next Phase

Once schema is in place, proceed to **Phase 2: Authentication** to handle user signup and automatic namespace/workspace creation.
