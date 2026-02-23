# 15c: Stub Tables for GetInSync Full

## Overview

Create all database tables for GetInSync Full features, but keep them locked in Lite tiers. This ensures:
- Seamless upgrade path (no schema changes needed)
- In-context teasers can reference real tables
- Data model is complete from day one

**Important:** These tables will exist but the UI will show "ðŸ”’ Available in GetInSync Full" until unlocked.

---

## Tables to Create

Run all of these SQL statements to create the stub tables:

### 1. Involved Parties

Track stakeholders, SMEs, vendors, and partners connected to applications.

```sql
CREATE TABLE public.application_parties (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  party_type text NOT NULL,
  contact_type text NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  external_name text,
  external_email text,
  external_org text,
  role_description text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_parties_pkey PRIMARY KEY (id),
  CONSTRAINT application_parties_type_check CHECK (
    party_type IN ('stakeholder', 'sme', 'approver', 'vendor', 'partner', 'other')
  ),
  CONSTRAINT application_parties_contact_check CHECK (
    contact_type IN ('internal', 'external')
  )
);

CREATE INDEX idx_application_parties_app ON public.application_parties(application_id);
ALTER TABLE public.application_parties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view application parties" ON public.application_parties
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 2. Integrations / Dependencies

Map upstream and downstream system dependencies.

```sql
CREATE TABLE public.application_integrations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  source_application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  target_application_id uuid REFERENCES applications(id) ON DELETE SET NULL,
  external_system_name text,
  direction text NOT NULL,
  integration_type text,
  frequency text,
  criticality text,
  description text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_integrations_pkey PRIMARY KEY (id),
  CONSTRAINT application_integrations_direction_check CHECK (
    direction IN ('upstream', 'downstream', 'bidirectional')
  ),
  CONSTRAINT application_integrations_type_check CHECK (
    integration_type IS NULL OR integration_type IN ('api', 'file', 'database', 'sso', 'manual', 'event', 'other')
  ),
  CONSTRAINT application_integrations_frequency_check CHECK (
    frequency IS NULL OR frequency IN ('real_time', 'batch_daily', 'batch_weekly', 'batch_monthly', 'on_demand')
  ),
  CONSTRAINT application_integrations_criticality_check CHECK (
    criticality IS NULL OR criticality IN ('critical', 'important', 'nice_to_have')
  )
);

CREATE INDEX idx_application_integrations_source ON public.application_integrations(source_application_id);
CREATE INDEX idx_application_integrations_target ON public.application_integrations(target_application_id);
ALTER TABLE public.application_integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view application integrations" ON public.application_integrations
  FOR SELECT TO authenticated
  USING (source_application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 3. Data Assets

Catalog data with classification and retention policies.

```sql
CREATE TABLE public.application_data_assets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  classification text,
  contains_pii boolean DEFAULT false,
  contains_phi boolean DEFAULT false,
  contains_financial boolean DEFAULT false,
  retention_years integer,
  data_steward_id uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_data_assets_pkey PRIMARY KEY (id),
  CONSTRAINT application_data_assets_class_check CHECK (
    classification IS NULL OR classification IN ('public', 'internal', 'confidential', 'restricted')
  )
);

CREATE INDEX idx_application_data_assets_app ON public.application_data_assets(application_id);
ALTER TABLE public.application_data_assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view data assets" ON public.application_data_assets
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 4. Compliance

Track regulatory requirements and audit status.

```sql
CREATE TABLE public.application_compliance (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  framework text NOT NULL,
  applicability text NOT NULL,
  compliance_status text,
  last_audit_date date,
  next_audit_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT application_compliance_pkey PRIMARY KEY (id),
  CONSTRAINT application_compliance_applicability_check CHECK (
    applicability IN ('required', 'optional', 'not_applicable')
  ),
  CONSTRAINT application_compliance_status_check CHECK (
    compliance_status IS NULL OR compliance_status IN ('compliant', 'non_compliant', 'in_progress', 'not_assessed')
  )
);

CREATE INDEX idx_application_compliance_app ON public.application_compliance(application_id);
ALTER TABLE public.application_compliance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view compliance" ON public.application_compliance
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 5. Documents

Attach architecture diagrams, SLAs, contracts, runbooks.

```sql
CREATE TABLE public.application_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  name text NOT NULL,
  document_type text,
  storage_type text NOT NULL,
  file_path text,
  external_url text,
  uploaded_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_documents_pkey PRIMARY KEY (id),
  CONSTRAINT application_documents_type_check CHECK (
    document_type IS NULL OR document_type IN ('architecture', 'data_flow', 'sla', 'contract', 'runbook', 'security', 'other')
  ),
  CONSTRAINT application_documents_storage_check CHECK (
    storage_type IN ('uploaded', 'link')
  )
);

CREATE INDEX idx_application_documents_app ON public.application_documents(application_id);
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view documents" ON public.application_documents
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 6. Roadmap / Lifecycle Events

Plan migrations, upgrades, decommissions.

```sql
CREATE TABLE public.application_roadmap (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  title text NOT NULL,
  description text,
  target_date date,
  status text NOT NULL DEFAULT 'planned',
  replacement_app_id uuid REFERENCES applications(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT application_roadmap_pkey PRIMARY KEY (id),
  CONSTRAINT application_roadmap_type_check CHECK (
    event_type IN ('upgrade', 'migration', 'decommission', 'major_release', 'security_patch', 'audit', 'review', 'other')
  ),
  CONSTRAINT application_roadmap_status_check CHECK (
    status IN ('planned', 'in_progress', 'completed', 'cancelled', 'deferred')
  )
);

CREATE INDEX idx_application_roadmap_app ON public.application_roadmap(application_id);
ALTER TABLE public.application_roadmap ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view roadmap" ON public.application_roadmap
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 7. Assessment History

Track assessment changes over time (versioning).

```sql
CREATE TABLE public.assessment_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  portfolio_assignment_id uuid NOT NULL REFERENCES portfolio_assignments(id) ON DELETE CASCADE,
  version integer NOT NULL,
  assessed_at timestamptz NOT NULL DEFAULT now(),
  assessed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  business_fit decimal,
  tech_health decimal,
  criticality decimal,
  tech_risk decimal,
  time_quadrant text,
  paid_action text,
  snapshot_data jsonb,
  notes text,
  CONSTRAINT assessment_history_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_assessment_history_assignment ON public.assessment_history(portfolio_assignment_id);
CREATE INDEX idx_assessment_history_date ON public.assessment_history(assessed_at);
ALTER TABLE public.assessment_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assessment history" ON public.assessment_history
  FOR SELECT TO authenticated
  USING (portfolio_assignment_id IN (
    SELECT pa.id FROM portfolio_assignments pa
    JOIN portfolios p ON pa.portfolio_id = p.id
    JOIN workspace_users wu ON p.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));
```

### 8. IT Service Catalog

```sql
CREATE TABLE public.it_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  owner_workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  service_type text,
  annual_cost decimal DEFAULT 0,
  cost_model text,
  is_internal_only boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT it_services_pkey PRIMARY KEY (id),
  CONSTRAINT it_services_type_check CHECK (
    service_type IS NULL OR service_type IN ('infrastructure', 'platform', 'security', 'network', 'storage', 'database', 'other')
  ),
  CONSTRAINT it_services_cost_model_check CHECK (
    cost_model IS NULL OR cost_model IN ('fixed', 'per_user', 'per_instance', 'consumption', 'tiered')
  )
);

CREATE INDEX idx_it_services_namespace ON public.it_services(namespace_id);
ALTER TABLE public.it_services ENABLE ROW LEVEL SECURITY;

-- Application â†’ IT Service links
CREATE TABLE public.application_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  it_service_id uuid NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
  usage_notes text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_services_pkey PRIMARY KEY (id),
  CONSTRAINT application_services_unique UNIQUE (application_id, it_service_id)
);

CREATE INDEX idx_application_services_app ON public.application_services(application_id);
ALTER TABLE public.application_services ENABLE ROW LEVEL SECURITY;
```

### 9. Software Product Catalog

```sql
CREATE TABLE public.software_products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  owner_workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  vendor text,
  version text,
  license_type text,
  annual_cost decimal DEFAULT 0,
  cost_per_user decimal,
  is_internal_only boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT software_products_pkey PRIMARY KEY (id),
  CONSTRAINT software_products_license_check CHECK (
    license_type IS NULL OR license_type IN ('perpetual', 'subscription', 'open_source', 'freemium', 'enterprise', 'other')
  )
);

CREATE INDEX idx_software_products_namespace ON public.software_products(namespace_id);
ALTER TABLE public.software_products ENABLE ROW LEVEL SECURITY;

-- Application â†’ Software Product links
CREATE TABLE public.application_products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  software_product_id uuid NOT NULL REFERENCES software_products(id) ON DELETE CASCADE,
  license_count integer,
  usage_notes text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT application_products_pkey PRIMARY KEY (id),
  CONSTRAINT application_products_unique UNIQUE (application_id, software_product_id)
);

CREATE INDEX idx_application_products_app ON public.application_products(application_id);
ALTER TABLE public.application_products ENABLE ROW LEVEL SECURITY;
```

### 10. WorkspaceGroups (Publishing)

```sql
CREATE TABLE public.workspace_groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT workspace_groups_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_workspace_groups_namespace ON public.workspace_groups(namespace_id);
ALTER TABLE public.workspace_groups ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.workspace_group_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workspace_group_id uuid NOT NULL REFERENCES workspace_groups(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  is_publisher boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT workspace_group_members_pkey PRIMARY KEY (id),
  CONSTRAINT workspace_group_members_unique UNIQUE (workspace_group_id, workspace_id)
);

ALTER TABLE public.workspace_group_members ENABLE ROW LEVEL SECURITY;
```

### 11. Add Publishing Fields to Applications

```sql
-- Add publishing fields to applications table
ALTER TABLE public.applications 
ADD COLUMN IF NOT EXISTS is_internal_only boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS owner_workspace_id uuid REFERENCES workspaces(id);

-- Set owner_workspace_id = workspace_id for existing apps
UPDATE public.applications 
SET owner_workspace_id = workspace_id 
WHERE owner_workspace_id IS NULL;
```

### 12. Workflows (Stub)

```sql
CREATE TABLE public.workflow_definitions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  workflow_type text NOT NULL,
  steps jsonb NOT NULL DEFAULT '[]',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT workflow_definitions_pkey PRIMARY KEY (id),
  CONSTRAINT workflow_definitions_type_check CHECK (
    workflow_type IN ('assessment_approval', 'change_request', 'decommission', 'custom')
  )
);

ALTER TABLE public.workflow_definitions ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.workflow_instances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workflow_definition_id uuid NOT NULL REFERENCES workflow_definitions(id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  current_step integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  started_by uuid REFERENCES users(id),
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  CONSTRAINT workflow_instances_pkey PRIMARY KEY (id),
  CONSTRAINT workflow_instances_status_check CHECK (
    status IN ('pending', 'in_progress', 'approved', 'rejected', 'cancelled')
  )
);

ALTER TABLE public.workflow_instances ENABLE ROW LEVEL SECURITY;
```

### 13. Notifications (Stub)

```sql
CREATE TABLE public.notification_rules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  trigger_type text NOT NULL,
  conditions jsonb NOT NULL DEFAULT '{}',
  channels jsonb NOT NULL DEFAULT '["in_app"]',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT notification_rules_pkey PRIMARY KEY (id),
  CONSTRAINT notification_rules_trigger_check CHECK (
    trigger_type IN ('assessment_due', 'license_expiry', 'end_of_support', 'compliance_due', 'custom')
  )
);

ALTER TABLE public.notification_rules ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  link text,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
```

### 14. Custom Fields (Stub)

```sql
CREATE TABLE public.custom_field_definitions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  field_name text NOT NULL,
  field_label text NOT NULL,
  field_type text NOT NULL,
  options jsonb,
  is_required boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT custom_field_definitions_pkey PRIMARY KEY (id),
  CONSTRAINT custom_field_definitions_entity_check CHECK (
    entity_type IN ('application', 'portfolio', 'it_service', 'software_product')
  ),
  CONSTRAINT custom_field_definitions_type_check CHECK (
    field_type IN ('text', 'number', 'date', 'dropdown', 'multi_select', 'checkbox', 'url')
  )
);

ALTER TABLE public.custom_field_definitions ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.custom_field_values (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  field_definition_id uuid NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  value jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT custom_field_values_pkey PRIMARY KEY (id),
  CONSTRAINT custom_field_values_unique UNIQUE (field_definition_id, entity_type, entity_id)
);

ALTER TABLE public.custom_field_values ENABLE ROW LEVEL SECURITY;
```

---

## Verification

After running all SQL:

```sql
-- Check all stub tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'application_parties',
  'application_integrations', 
  'application_data_assets',
  'application_compliance',
  'application_documents',
  'application_roadmap',
  'assessment_history',
  'it_services',
  'application_services',
  'software_products',
  'application_products',
  'workspace_groups',
  'workspace_group_members',
  'workflow_definitions',
  'workflow_instances',
  'notification_rules',
  'notifications',
  'custom_field_definitions',
  'custom_field_values'
);
```

Expected: 19 tables
