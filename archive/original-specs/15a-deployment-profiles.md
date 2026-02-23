# 15a: Deployment Profiles

## Overview

Add Deployment Profiles to track where applications are deployed. This is a "gateway feature" that shows users the depth of the data model.

**Key behaviors:**
- Auto-create one profile named "{AppName} â€” Region-PROD" when application is created
- Profile is collapsed by default in the UI (progressive disclosure)
- Free tier: View only (cannot edit)
- Pro tier: Can edit the one profile
- Enterprise tier: Can add multiple profiles per app
- Full tier: Can also track Environment Details (version, URL, etc.)

---

## Database Schema

```sql
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
```

---

## RLS Policies

```sql
ALTER TABLE public.deployment_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view profiles for apps in their workspaces
CREATE POLICY "Users can view deployment profiles" ON public.deployment_profiles
  FOR SELECT TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid()
  ));

-- Editors can manage profiles
CREATE POLICY "Editors can insert deployment profiles" ON public.deployment_profiles
  FOR INSERT TO authenticated
  WITH CHECK (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));

CREATE POLICY "Editors can update deployment profiles" ON public.deployment_profiles
  FOR UPDATE TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));

CREATE POLICY "Editors can delete deployment profiles" ON public.deployment_profiles
  FOR DELETE TO authenticated
  USING (application_id IN (
    SELECT a.id FROM applications a
    JOIN workspace_users wu ON a.workspace_id = wu.workspace_id
    WHERE wu.user_id = auth.uid() AND wu.role IN ('admin', 'editor')
  ));
```

---

## Auto-Create Trigger

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

---

## Backfill Existing Apps

```sql
-- Create deployment profiles for existing applications that don't have one
INSERT INTO public.deployment_profiles (application_id, name, is_primary)
SELECT id, name || ' â€” Region-PROD', true
FROM public.applications
WHERE id NOT IN (SELECT application_id FROM public.deployment_profiles);
```

---

## Dropdown Options

Create a constants file with these options:

```typescript
// Hosting Type
const HOSTING_TYPES = [
  { value: 'on_premise', label: 'On-Premise' },
  { value: 'cloud', label: 'Cloud' },
  { value: 'hybrid', label: 'Hybrid' },
  { value: 'saas', label: 'SaaS' },
  { value: 'unknown', label: 'Unknown' },
];

// Cloud Provider (shown when hosting = cloud or hybrid)
const CLOUD_PROVIDERS = [
  { value: 'azure', label: 'Microsoft Azure' },
  { value: 'aws', label: 'Amazon Web Services' },
  { value: 'gcp', label: 'Google Cloud Platform' },
  { value: 'oracle', label: 'Oracle Cloud' },
  { value: 'ibm', label: 'IBM Cloud' },
  { value: 'other', label: 'Other' },
  { value: 'na', label: 'N/A' },
];

// Region
const REGIONS = [
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

// DR Status
const DR_STATUS = [
  { value: 'active_active', label: 'Active-Active (Full redundancy)' },
  { value: 'active_passive', label: 'Active-Passive (Standby)' },
  { value: 'pilot_light', label: 'Pilot Light (Minimal standby)' },
  { value: 'backup_only', label: 'Backup Only (Restore from backup)' },
  { value: 'none', label: 'None' },
];
```

---

## UI Component

Add a collapsible "Deployment Profile" section to the Application form/detail view.

### Collapsed State (default)

```
â–¶ Deployment Profile (optional)
```

### Expanded - Free Tier (View Only)

```
â–¼ Deployment Profile

â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Sage 300 â€” Region-PROD                                    ðŸ”’    â”‚
â”‚                                                                 â”‚
â”‚ Hosting Type        Cloud Provider      Region                  â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐         â”‚
â”‚ â”‚ Not set     â”‚     â”‚ Not set     â”‚     â”‚ Not set     â”‚         â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘         â”‚
â”‚                                                                 â”‚
â”‚ DR Status                                                       â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                                                 â”‚
â”‚ â”‚ Not set     â”‚                                                 â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                                                 â”‚
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ ðŸ”’ Upgrade to Pro to edit deployment profile                â”‚ â”‚
â”‚ â”‚                                        [Upgrade to Pro â†’]   â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

### Expanded - Pro Tier (Edit One)

```
â–¼ Deployment Profile

â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Sage 300 â€” Region-PROD                                  [Edit]  â”‚
â”‚                                                                 â”‚
â”‚ Hosting Type        Cloud Provider      Region                  â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐         â”‚
â”‚ â”‚ Cloud    â–¼  â”‚     â”‚ Azure    â–¼  â”‚     â”‚ Canada Cenâ–¼ â”‚         â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘         â”‚
â”‚                                                                 â”‚
â”‚ DR Status                                                       â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                                                 â”‚
â”‚ â”‚ Active-Pasâ–¼ â”‚                                                 â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                                                 â”‚
â”‚                                                                 â”‚
â”‚ â”Œ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ ┐ â”‚
â”‚   ðŸ”’ + Add Region-DR, Region-DEV...                             â”‚
â”‚       Upgrade to Enterprise for multiple profiles               â”‚
â”‚                                    [Upgrade to Enterprise â†’]    â”‚
â”‚ â”” â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ â”€ ┘ â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

### Expanded - Enterprise Tier (Multiple Profiles)

```
â–¼ Deployment Profiles

â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Sage 300 â€” Region-PROD                        [Edit] [Delete]   â”‚
â”‚ Cloud Â· Azure Â· Canada Central Â· Active-Passive DR              â”‚
â”‚                                                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                 â”‚
â”‚ Sage 300 â€” Region-DR                          [Edit] [Delete]   â”‚
â”‚ Cloud Â· Azure Â· US East Â· Failover                              â”‚
â”‚                                                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                 â”‚
â”‚                                        [+ Add Profile]          â”‚
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ ðŸ”’ Environment Details (version, URL, deployment history)   â”‚ â”‚
â”‚ â”‚    Available in GetInSync Full             [Learn More â†’]   â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## TypeScript Type

```typescript
interface DeploymentProfile {
  id: string;
  application_id: string;
  name: string;
  is_primary: boolean;
  hosting_type: 'on_premise' | 'cloud' | 'hybrid' | 'saas' | 'unknown' | null;
  cloud_provider: 'azure' | 'aws' | 'gcp' | 'oracle' | 'ibm' | 'other' | 'na' | null;
  region: string | null;
  dr_status: 'active_active' | 'active_passive' | 'pilot_light' | 'backup_only' | 'none' | null;
  created_at: string;
  updated_at: string;
}
```

---

## Integration Points

1. **Application Modal (Add/Edit)**: Add the collapsible Deployment Profile section
2. **Application Detail View**: Show deployment profile summary
3. **Applications Table**: Optionally show hosting type as a column
4. **CSV Export**: Include deployment profile fields

---

## Verification

After implementation:

1. Create a new application â†’ verify deployment profile "AppName â€” Region-PROD" is auto-created
2. Expand the Deployment Profile section â†’ verify it shows (collapsed by default)
3. On Free tier â†’ verify fields are disabled with upgrade prompt
4. On Pro tier â†’ verify can edit the profile, but cannot add more
5. On Enterprise tier â†’ verify can add multiple profiles
