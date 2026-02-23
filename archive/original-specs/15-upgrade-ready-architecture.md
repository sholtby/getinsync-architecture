# Upgrade-Ready Architecture

## Overview

This document specifies the complete GetInSync architecture with **progressive feature unlocking** across tiers. The goal is to stub all Full features in Lite so that:

1. **"Just Assess" users** get a clean, fast TIME/PAID experience
2. **"Architecture Curious" users** discover the full data model and upgrade
3. **Upgrade path is seamless** â€” no data migration, just feature unlocks

---

## Tier Structure

| Tier | Target User | Price Point |
|------|-------------|-------------|
| **Lite Free** | Individual assessors, tire-kickers | $0 |
| **Lite Pro** | Small teams, serious assessment | $29/mo |
| **Lite Enterprise** | Large orgs, multi-workspace | $99/mo |
| **GetInSync Full** | Enterprise APM, cross-org visibility | Custom |

---

## Complete Feature Matrix

### Core Assessment

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Applications (per workspace) | 20 | 100 | Unlimited | Unlimited |
| Portfolios (per workspace) | 3 | 10 | Unlimited | Unlimited |
| Nested Portfolios | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| TIME/PAID Assessment | âœ… | âœ… | âœ… | âœ… |
| T-shirt Sizing (XS-2XL) | âœ… | âœ… | âœ… | âœ… |
| Est. Tech Debt (relative) | âœ… | âœ… | âœ… | âœ… |
| Priority Backlog | âœ… | âœ… | âœ… | âœ… |
| CSV Import | 20 rows | 100 rows | Unlimited | Unlimited |
| CSV Export | âœ… | âœ… | âœ… | âœ… |

### Multi-Tenant

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Workspaces | 2 | 5 | Unlimited | Unlimited |
| Users | 3 | 20 | Unlimited | Unlimited |
| User Roles | âœ… | âœ… | âœ… | âœ… |
| WorkspaceGroups | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Publish to Namespace | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Deployment Profiles

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Auto-created profile (Region-PROD) | âœ… View | âœ… Edit | âœ… Edit | âœ… Edit |
| Edit profile fields | ðŸ”’ | âœ… | âœ… | âœ… |
| Multiple profiles per app | ðŸ”’ | ðŸ”’ | âœ… | âœ… |
| Environment Details (version, URL) | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Assessment Configuration

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| View factor configuration | âœ… | âœ… | âœ… | âœ… |
| Edit questions/descriptions | ðŸ”’ | âœ… | âœ… | âœ… |
| Edit factor weightings | ðŸ”’ | âœ… | âœ… | âœ… |
| Edit thresholds | ðŸ”’ | âœ… | âœ… | âœ… |
| Add/remove factors | ðŸ”’ | ðŸ”’ | âœ… | âœ… |

### Catalogs & Costs

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| IT Service Catalog | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Software Product Catalog | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| App â†’ Service/Product links | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Annual Cost (derived) | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Cost-based Tech Debt ($) | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Relationships (Stubbed)

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Involved Parties | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Integrations/Dependencies | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Data Assets | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Operations (Stubbed)

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Compliance/Regulatory | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Documents/Attachments | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Lifecycle (Stubbed)

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Roadmap/Lifecycle Events | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Assessment History | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

### Automation (Stubbed)

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Workflows/Approvals | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Notifications/Alerts | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Scheduled Reports | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| API Access | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |
| Custom Fields | ðŸ”’ | ðŸ”’ | ðŸ”’ | âœ… |

---

## Part 1: Deployment Profiles

### Database Schema

```sql
-- ============================================
-- DEPLOYMENT PROFILES
-- ============================================

CREATE TABLE public.deployment_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  name text NOT NULL,
  is_primary boolean NOT NULL DEFAULT false,
  hosting_type text,
  cloud_provider text,
  region text,
  dr_status text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT deployment_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT deployment_profiles_hosting_check CHECK (
    hosting_type IS NULL OR hosting_type IN ('on_premise', 'cloud', 'hybrid', 'saas', 'unknown')
  ),
  CONSTRAINT deployment_profiles_cloud_check CHECK (
    cloud_provider IS NULL OR cloud_provider IN ('azure', 'aws', 'gcp', 'oracle', 'ibm', 'other', 'na')
  ),
  CONSTRAINT deployment_profiles_dr_check CHECK (
    dr_status IS NULL OR dr_status IN ('active_active', 'active_passive', 'pilot_light', 'backup_only', 'none')
  )
);

CREATE INDEX idx_deployment_profiles_app ON public.deployment_profiles(application_id);

-- RLS Policies
ALTER TABLE public.deployment_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view deployment profiles" ON public.deployment_profiles
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));

CREATE POLICY "Editors can manage deployment profiles" ON public.deployment_profiles
  FOR ALL TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));
```

### Auto-Create Trigger

```sql
-- Auto-create deployment profile when application is created
CREATE OR REPLACE FUNCTION create_default_deployment_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.deployment_profiles (application_id, name, is_primary)
  VALUES (NEW.id, NEW.name || ' â€” Region-PROD', true);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER create_deployment_profile_on_app_create
  AFTER INSERT ON public.applications
  FOR EACH ROW EXECUTE FUNCTION create_default_deployment_profile();
```

### Dropdown Options

```typescript
// src/lib/deploymentOptions.ts

export const HOSTING_TYPES = [
  { value: 'on_premise', label: 'On-Premise' },
  { value: 'cloud', label: 'Cloud' },
  { value: 'hybrid', label: 'Hybrid' },
  { value: 'saas', label: 'SaaS' },
  { value: 'unknown', label: 'Unknown' },
];

export const CLOUD_PROVIDERS = [
  { value: 'azure', label: 'Microsoft Azure' },
  { value: 'aws', label: 'Amazon Web Services' },
  { value: 'gcp', label: 'Google Cloud Platform' },
  { value: 'oracle', label: 'Oracle Cloud' },
  { value: 'ibm', label: 'IBM Cloud' },
  { value: 'other', label: 'Other' },
  { value: 'na', label: 'N/A' },
];

export const REGIONS = [
  { value: 'canada_central', label: 'Canada Central' },
  { value: 'canada_east', label: 'Canada East' },
  { value: 'us_east', label: 'US East' },
  { value: 'us_west', label: 'US West' },
  { value: 'europe_west', label: 'Europe West' },
  { value: 'europe_north', label: 'Europe North' },
  { value: 'asia_pacific', label: 'Asia Pacific' },
  { value: 'australia', label: 'Australia' },
  { value: 'other', label: 'Other' },
];

export const DR_STATUS = [
  { value: 'active_active', label: 'Active-Active (Full redundancy)' },
  { value: 'active_passive', label: 'Active-Passive (Standby)' },
  { value: 'pilot_light', label: 'Pilot Light (Minimal standby)' },
  { value: 'backup_only', label: 'Backup Only (Restore from backup)' },
  { value: 'none', label: 'None' },
];
```

### UI Component: DeploymentProfileSection

```tsx
// src/components/DeploymentProfileSection.tsx

interface Props {
  applicationId: string;
  applicationName: string;
  tier: 'free' | 'pro' | 'enterprise' | 'full';
}

export function DeploymentProfileSection({ applicationId, applicationName, tier }: Props) {
  const [expanded, setExpanded] = useState(false);
  const [profiles, setProfiles] = useState<DeploymentProfile[]>([]);
  
  const canEdit = tier !== 'free';
  const canAddMore = tier === 'enterprise' || tier === 'full';
  const canViewDetails = tier === 'full';

  return (
    <div className="border rounded-lg">
      {/* Collapsed Header */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full flex items-center justify-between p-4 hover:bg-gray-50"
      >
        <div className="flex items-center gap-2">
          {expanded ? <ChevronDown /> : <ChevronRight />}
          <span className="font-medium">Deployment Profile</span>
          <span className="text-sm text-gray-500">(optional)</span>
        </div>
        {profiles[0]?.hosting_type && (
          <span className="text-sm text-gray-600">
            {profiles[0].hosting_type} Â· {profiles[0].cloud_provider} Â· {profiles[0].region}
          </span>
        )}
      </button>

      {/* Expanded Content */}
      {expanded && (
        <div className="p-4 border-t bg-gray-50">
          {profiles.map((profile, index) => (
            <ProfileCard
              key={profile.id}
              profile={profile}
              canEdit={canEdit}
              canDelete={index > 0 && canAddMore}
              onEdit={() => handleEdit(profile)}
              onDelete={() => handleDelete(profile)}
            />
          ))}

          {/* Tier-specific teasers */}
          {tier === 'free' && (
            <UpgradeTeaser
              icon={Lock}
              title="Upgrade to Pro to edit deployment profile"
              buttonText="Upgrade to Pro"
              buttonLink="/settings/billing"
            />
          )}

          {tier === 'pro' && (
            <GhostProfileTeaser
              title="Add Region-DR, Region-DEV..."
              description="Upgrade to Enterprise for multiple deployment profiles per application."
              buttonText="Upgrade to Enterprise"
            />
          )}

          {(tier === 'enterprise' || tier === 'full') && (
            <button
              onClick={handleAddProfile}
              className="w-full p-3 border-2 border-dashed rounded-lg text-gray-500 hover:border-teal-500 hover:text-teal-600"
            >
              + Add Profile
            </button>
          )}

          {tier !== 'full' && (
            <UpgradeTeaser
              icon={Lock}
              title="Environment Details (version, URL, deployment history)"
              description="Track granular environment data with GetInSync Full"
              buttonText="Learn More"
              buttonLink="/pricing"
              variant="subtle"
            />
          )}
        </div>
      )}
    </div>
  );
}
```

---

## Part 2: Free Tier Adjustment (2 Workspaces)

### Update Tier Configuration

```typescript
// src/lib/tiers.ts

export const TIER_LIMITS = {
  free: {
    workspaces: 2,        // Changed from 1 to 2
    portfoliosPerWorkspace: 3,
    applicationsPerWorkspace: 20,
    users: 3,
    csvImportRows: 20,
    deploymentProfilesPerApp: 1,
  },
  pro: {
    workspaces: 5,
    portfoliosPerWorkspace: 10,
    applicationsPerWorkspace: 100,
    users: 20,
    csvImportRows: 100,
    deploymentProfilesPerApp: 1,
  },
  enterprise: {
    workspaces: 999,
    portfoliosPerWorkspace: 999,
    applicationsPerWorkspace: 999,
    users: 999,
    csvImportRows: 999,
    deploymentProfilesPerApp: 999,
  },
  full: {
    workspaces: 999,
    portfoliosPerWorkspace: 999,
    applicationsPerWorkspace: 999,
    users: 999,
    csvImportRows: 999,
    deploymentProfilesPerApp: 999,
  },
};

export const TIER_FEATURES = {
  free: {
    editDeploymentProfile: false,
    editAssessmentConfig: false,
    addFactors: false,
    multipleDeploymentProfiles: false,
    publishToNamespace: false,
    itServiceCatalog: false,
    softwareProductCatalog: false,
    involvedParties: false,
    integrations: false,
    dataAssets: false,
    compliance: false,
    documents: false,
    roadmap: false,
    assessmentHistory: false,
    workflows: false,
    notifications: false,
    scheduledReports: false,
    apiAccess: false,
    customFields: false,
    nestedPortfolios: false,
    annualCost: false,
    environmentDetails: false,
  },
  pro: {
    editDeploymentProfile: true,
    editAssessmentConfig: true,
    addFactors: false,
    multipleDeploymentProfiles: false,
    // ... rest same as free except above
  },
  enterprise: {
    editDeploymentProfile: true,
    editAssessmentConfig: true,
    addFactors: true,
    multipleDeploymentProfiles: true,
    // ... rest same as free except above
  },
  full: {
    // All true
  },
};
```

---

## Part 3: Stub Tables (Full Features)

Create all tables now, but features are locked until Full tier.

### Involved Parties

```sql
-- ============================================
-- INVOLVED PARTIES (Stub for Full)
-- ============================================

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
```

### Integrations

```sql
-- ============================================
-- INTEGRATIONS / DEPENDENCIES (Stub for Full)
-- ============================================

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
    integration_type IS NULL OR integration_type IN ('api', 'file', 'database', 'sso', 'manual', 'other')
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
```

### Data Assets

```sql
-- ============================================
-- DATA ASSETS (Stub for Full)
-- ============================================

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
```

### Compliance

```sql
-- ============================================
-- COMPLIANCE (Stub for Full)
-- ============================================

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
```

### Documents

```sql
-- ============================================
-- DOCUMENTS (Stub for Full)
-- ============================================

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
```

### Roadmap

```sql
-- ============================================
-- ROADMAP / LIFECYCLE EVENTS (Stub for Full)
-- ============================================

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
```

### Assessment History

```sql
-- ============================================
-- ASSESSMENT HISTORY (Stub for Full)
-- ============================================

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
```

### IT Service Catalog

```sql
-- ============================================
-- IT SERVICE CATALOG (Stub for Full)
-- ============================================

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

### Software Product Catalog

```sql
-- ============================================
-- SOFTWARE PRODUCT CATALOG (Stub for Full)
-- ============================================

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

### WorkspaceGroups (Publishing)

```sql
-- ============================================
-- WORKSPACE GROUPS (Stub for Full)
-- ============================================

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

-- Add publishing fields to applications
ALTER TABLE public.applications 
ADD COLUMN IF NOT EXISTS is_internal_only boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS owner_workspace_id uuid REFERENCES workspaces(id);

-- Set owner_workspace_id = workspace_id for existing apps
UPDATE public.applications SET owner_workspace_id = workspace_id WHERE owner_workspace_id IS NULL;
```

### Workflows (Stub)

```sql
-- ============================================
-- WORKFLOWS (Stub for Full)
-- ============================================

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

### Notifications (Stub)

```sql
-- ============================================
-- NOTIFICATIONS (Stub for Full)
-- ============================================

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

### Custom Fields (Stub)

```sql
-- ============================================
-- CUSTOM FIELDS (Stub for Full)
-- ============================================

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

## Part 4: In-Context Teaser Placements

### Application Form/Detail View

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Application Details                                             â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ [Core fields: Name, Description, Owner, etc.]                   â”‚
â”‚                                                                 â”‚
â”‚ â–¶ Deployment Profile                                            â”‚
â”‚                                                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Involved Parties                          [GetInSync Full]   â”‚
â”‚    Track stakeholders, SMEs, vendors                            â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Integrations                              [GetInSync Full]   â”‚
â”‚    Map upstream and downstream dependencies                     â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Data Assets                               [GetInSync Full]   â”‚
â”‚    Catalog data with classification and retention               â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Compliance                                [GetInSync Full]   â”‚
â”‚    Track regulatory requirements and audit status               â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Documents                                 [GetInSync Full]   â”‚
â”‚    Attach architecture diagrams, SLAs, contracts                â”‚
â”‚                                                                 â”‚
â”‚ ðŸ”’ Roadmap                                   [GetInSync Full]   â”‚
â”‚    Plan migrations, upgrades, decommissions                     â”‚
â”‚                                                                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

### Settings Menu

```
Settings
â”œâ”€â”€ Organization âœ…
â”œâ”€â”€ Workspaces âœ…
â”œâ”€â”€ Users âœ…
â”œâ”€â”€ Assessment Configuration âœ…
â”œâ”€â”€ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
â”œâ”€â”€ ðŸ”’ Workspace Groups              [Full]
â”œâ”€â”€ ðŸ”’ IT Service Catalog            [Full]
â”œâ”€â”€ ðŸ”’ Software Products             [Full]
â”œâ”€â”€ ðŸ”’ Custom Fields                 [Full]
â”œâ”€â”€ ðŸ”’ Workflows                     [Full]
â”œâ”€â”€ ðŸ”’ Notifications                 [Full]
â”œâ”€â”€ ðŸ”’ API Access                    [Full]
â””â”€â”€ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
```

### Dashboard Teaser Card

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ ðŸ”’ Enterprise Features                           [Learn More â†’] â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Unlock the full GetInSync platform:                             â”‚
â”‚                                                                 â”‚
â”‚ â€¢ Publish apps across workspaces                                â”‚
â”‚ â€¢ IT Service & Software Product catalogs                        â”‚
â”‚ â€¢ Cost derivation and financial analysis                        â”‚
â”‚ â€¢ Cross-workspace reporting                                     â”‚
â”‚ â€¢ Workflows and approvals                                       â”‚
â”‚ â€¢ API access for integrations                                   â”‚
â”‚                                                                 â”‚
â”‚                              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐         â”‚
â”‚                              â”‚ Contact Sales          â”‚         â”‚
â”‚                              â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘         â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Part 5: Migration for Existing Apps

Create deployment profiles for existing applications:

```sql
-- Backfill deployment profiles for existing applications
INSERT INTO public.deployment_profiles (application_id, name, is_primary)
SELECT id, name || ' â€” Region-PROD', true
FROM public.applications
WHERE id NOT IN (SELECT application_id FROM public.deployment_profiles);
```

---

## Implementation Order

1. **15a**: Deployment Profiles table + trigger + UI component
2. **15b**: Update tier limits (2 workspaces for free)
3. **15c**: Stub tables (all Full features)
4. **15d**: In-context teaser components
5. **15e**: Settings menu with locked items
6. **15f**: Dashboard teaser card

---

## Summary

This architecture ensures:

1. **"Just Assess" path is clean** â€” Core features work without clutter
2. **"Architecture Curious" discovers depth** â€” Deployment Profile is the gateway
3. **Every stub is a teaser** â€” Locked features are visible, not hidden
4. **Upgrade is seamless** â€” Tables exist, just unlock features
5. **Full GetInSync path is clear** â€” Enterprise â†’ Full unlocks catalogs and publishing
