# features/cloud-discovery/architecture.md
Cloud Discovery & Auto-Population Architecture
Last updated: 2026-01-31

---

## 1. Overview

This document defines the Cloud Discovery feature that enables organizations to automatically discover cloud resources and create Deployment Profiles without manual data entry.

**Vision:** "From Cloud to Clarity in 5 Minutes" - connect AWS/Azure/GCP accounts, auto-discover infrastructure, map to business applications, start rationalizing immediately.

**Phase:** 27 (Post-MVP, Enterprise tier feature)

---

## 2. Problem Statement

### 2.1 Current State: Manual Entry Hell

**What organizations do today:**
1. Log into AWS/Azure/GCP console
2. Navigate through services (EC2, RDS, App Services, etc.)
3. Export lists to CSV or screenshot
4. Copy-paste into spreadsheet
5. Manually map servers to applications (guesswork)
6. Enter into GetInSync one by one
7. Data goes stale within weeks
8. Repeat monthly (40+ hours of work)

**Pain points:**
- ❌ Time-consuming (40 hours/month for 500 resources)
- ❌ Error-prone (typos, missing resources)
- ❌ Incomplete (people give up halfway)
- ❌ Stale data (too much effort to keep updated)
- ❌ No cost integration (manual cost entry from billing)
- ❌ Missing context (which server supports which app?)

### 2.2 Competitive Landscape

**ServiceNow Discovery:**
- Discovers infrastructure CIs
- Complex setup ($$$, requires ITOM license)
- Doesn't map to business applications well
- **Cost:** $100K+ implementation + $50K/year licenses

**Flexera One:**
- Multi-cloud discovery and inventory
- Strong FinOps focus (cost optimization)
- Weak application portfolio management
- **Cost:** $50K-$200K/year

**Apptio Cloudability:**
- Cloud cost management with discovery
- Focuses on chargeback/showback
- Doesn't assess application health
- **Cost:** $75K-$150K/year

**LeanIX:**
- Manual data entry for APM
- No discovery capabilities
- **Cost:** $40K-$80K/year

**Device42:**
- IT infrastructure discovery
- Can query cloud APIs
- Inventory focus, not APM
- **Cost:** $30K-$60K/year

### 2.3 GetInSync's Opportunity

**None of these tools:**
- ✅ Discover cloud resources
- ✅ Auto-create Deployment Profiles
- ✅ Map to business applications intelligently
- ✅ Assess with TIME/PAID framework
- ✅ Maintain QuickBooks simplicity

**GetInSync will be the ONLY tool that discovers → maps → assesses in one platform.**

---

## 3. Solution Architecture

### 3.1 High-Level Approach

```
Cloud Provider API
      ↓
GetInSync Cloud Connector
      ↓
Discovery Engine
      ↓
Mapping Engine (tag-based + AI)
      ↓
Deployment Profile Creation
      ↓
Cost Data Integration
```

### 3.2 Three-Phase Implementation

**Phase 27.1: CSV Import (2 weeks) - MVP**
- Manual export from cloud console
- CSV upload to GetInSync
- Column mapping wizard
- Bulk create Deployment Profiles

**Phase 27.2: AWS API Discovery (8 weeks) - Enterprise Feature**
- OAuth/IAM role connection to AWS
- Auto-discover EC2, RDS, Lambda
- Tag-based application mapping
- Manual sync trigger

**Phase 27.3: Multi-Cloud + Auto-Sync (12 weeks) - Full Tier Feature**
- Azure + GCP support
- Scheduled daily sync
- Cost data from billing APIs
- Orphan detection (deleted in cloud)

---

## 4. Schema Changes

### 4.1 New Tables

#### cloud_connections
```sql
CREATE TABLE cloud_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id),
  name text NOT NULL,
  provider text NOT NULL CHECK (provider IN ('aws', 'azure', 'gcp', 'oracle')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'error', 'disabled')),
  
  -- AWS: IAM Role ARN or Access Keys
  -- Azure: Service Principal credentials
  -- GCP: Service Account key
  credentials_encrypted jsonb NOT NULL,
  
  -- Connection metadata
  account_id text, -- AWS Account ID, Azure Subscription ID, GCP Project ID
  account_name text,
  region_filter text[], -- Optional: only sync specific regions
  
  -- Sync settings
  sync_frequency text DEFAULT 'manual' CHECK (sync_frequency IN ('manual', 'daily', 'weekly')),
  last_sync_at timestamptz,
  next_sync_at timestamptz,
  
  -- Discovery scope
  resource_types text[] DEFAULT ARRAY['compute', 'database', 'storage'], -- What to discover
  tag_filters jsonb, -- Only sync resources with specific tags
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  
  CONSTRAINT cloud_connections_unique_provider UNIQUE(namespace_id, provider, account_id)
);

CREATE INDEX idx_cloud_connections_namespace ON cloud_connections(namespace_id);
CREATE INDEX idx_cloud_connections_next_sync ON cloud_connections(next_sync_at) WHERE status = 'active';

COMMENT ON TABLE cloud_connections IS 'Cloud provider account connections for discovery';
COMMENT ON COLUMN cloud_connections.credentials_encrypted IS 'Encrypted IAM/Service Principal credentials stored in Supabase Vault';
```

#### discovered_resources
```sql
CREATE TABLE discovered_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cloud_connection_id uuid NOT NULL REFERENCES cloud_connections(id) ON DELETE CASCADE,
  namespace_id uuid NOT NULL REFERENCES namespaces(id),
  
  -- Resource identification
  external_id text NOT NULL, -- AWS: i-1234567890abcdef0, Azure: /subscriptions/.../resourceId
  resource_type text NOT NULL, -- 'ec2_instance', 'rds_database', 'azure_vm', etc.
  name text NOT NULL,
  
  -- Cloud metadata
  provider text NOT NULL, -- 'aws', 'azure', 'gcp'
  region text NOT NULL,
  account_id text NOT NULL,
  
  -- Resource details
  resource_details jsonb NOT NULL, -- Full API response
  tags jsonb, -- Resource tags/labels
  
  -- State tracking
  status text NOT NULL DEFAULT 'discovered' CHECK (status IN ('discovered', 'mapped', 'ignored', 'orphaned')),
  deployment_profile_id uuid REFERENCES deployment_profiles(id), -- NULL if not mapped yet
  
  -- Cost data
  estimated_monthly_cost numeric(12,2),
  actual_monthly_cost numeric(12,2), -- From billing API
  
  -- Discovery metadata
  discovered_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  orphaned_at timestamptz, -- Set when resource no longer found in cloud
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT discovered_resources_unique_external UNIQUE(cloud_connection_id, external_id)
);

CREATE INDEX idx_discovered_resources_namespace ON discovered_resources(namespace_id);
CREATE INDEX idx_discovered_resources_connection ON discovered_resources(cloud_connection_id);
CREATE INDEX idx_discovered_resources_status ON discovered_resources(status);
CREATE INDEX idx_discovered_resources_orphaned ON discovered_resources(orphaned_at) WHERE orphaned_at IS NOT NULL;

COMMENT ON TABLE discovered_resources IS 'Cloud resources discovered via API, pending mapping to deployment profiles';
COMMENT ON COLUMN discovered_resources.orphaned_at IS 'Set when resource deleted in cloud but still exists in GetInSync';
```

#### discovery_sync_log
```sql
CREATE TABLE discovery_sync_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cloud_connection_id uuid NOT NULL REFERENCES cloud_connections(id) ON DELETE CASCADE,
  
  -- Sync details
  sync_started_at timestamptz NOT NULL DEFAULT now(),
  sync_completed_at timestamptz,
  status text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
  
  -- Results
  resources_discovered integer DEFAULT 0,
  resources_created integer DEFAULT 0,
  resources_updated integer DEFAULT 0,
  resources_orphaned integer DEFAULT 0,
  
  -- Error tracking
  error_message text,
  error_details jsonb,
  
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_discovery_sync_log_connection ON discovery_sync_log(cloud_connection_id);
CREATE INDEX idx_discovery_sync_log_started ON discovery_sync_log(sync_started_at DESC);

COMMENT ON TABLE discovery_sync_log IS 'Audit log of cloud discovery sync operations';
```

### 4.2 Updated Tables

#### deployment_profiles (add columns)
```sql
ALTER TABLE deployment_profiles
ADD COLUMN external_id text,
ADD COLUMN discovered_resource_id uuid REFERENCES discovered_resources(id),
ADD COLUMN discovery_source text CHECK (discovery_source IN ('manual', 'csv_import', 'aws_api', 'azure_api', 'gcp_api')),
ADD COLUMN last_synced_at timestamptz;

CREATE INDEX idx_deployment_profiles_external_id ON deployment_profiles(external_id);
CREATE INDEX idx_deployment_profiles_discovered_resource ON deployment_profiles(discovered_resource_id);

COMMENT ON COLUMN deployment_profiles.external_id IS 'Cloud provider resource ID (e.g., AWS instance ID)';
COMMENT ON COLUMN deployment_profiles.discovery_source IS 'How this DP was created';
```

---

## 5. Cloud Provider APIs

### 5.1 AWS Integration

**Authentication:**
- Option A: IAM Role with AssumeRole (recommended for enterprises)
- Option B: Access Key + Secret Key (for smaller orgs)

**Required IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "rds:DescribeDBInstances",
        "lambda:ListFunctions",
        "elasticloadbalancing:DescribeLoadBalancers",
        "ecs:ListClusters",
        "ecs:ListServices",
        "eks:ListClusters",
        "s3:ListAllMyBuckets",
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    }
  ]
}
```

**Discovery Flow:**
```typescript
// 1. List all regions
const ec2 = new AWS.EC2({ region: 'us-east-1' });
const regions = await ec2.describeRegions().promise();

// 2. For each region, discover resources
for (const region of regions.Regions) {
  const regionalEc2 = new AWS.EC2({ region: region.RegionName });
  const instances = await regionalEc2.describeInstances().promise();
  
  for (const reservation of instances.Reservations) {
    for (const instance of reservation.Instances) {
      await createDiscoveredResource({
        external_id: instance.InstanceId,
        resource_type: 'ec2_instance',
        name: getNameFromTags(instance.Tags),
        provider: 'aws',
        region: mapAwsRegion(region.RegionName),
        tags: convertTags(instance.Tags),
        resource_details: instance
      });
    }
  }
}
```

**Cost Data:**
```typescript
// AWS Cost Explorer API
const ce = new AWS.CostExplorer({ region: 'us-east-1' });
const costs = await ce.getCostAndUsage({
  TimePeriod: {
    Start: '2026-01-01',
    End: '2026-01-31'
  },
  Granularity: 'MONTHLY',
  Metrics: ['UnblendedCost'],
  GroupBy: [
    { Type: 'TAG', Key: 'Application' }
  ]
}).promise();
```

### 5.2 Azure Integration

**Authentication:**
- Service Principal (App Registration)
- Requires: Tenant ID, Client ID, Client Secret

**Required Permissions:**
- Reader role on subscription
- Optional: Cost Management Reader for billing data

**Discovery Flow:**
```typescript
import { ComputeManagementClient } from '@azure/arm-compute';
import { SqlManagementClient } from '@azure/arm-sql';

// List VMs
const computeClient = new ComputeManagementClient(credentials, subscriptionId);
const vms = computeClient.virtualMachines.listAll();

for await (const vm of vms) {
  await createDiscoveredResource({
    external_id: vm.id,
    resource_type: 'azure_vm',
    name: vm.name,
    provider: 'azure',
    region: mapAzureRegion(vm.location),
    tags: vm.tags,
    resource_details: vm
  });
}
```

**Cost Data:**
```typescript
import { CostManagementClient } from '@azure/arm-costmanagement';

const costClient = new CostManagementClient(credentials);
const costs = await costClient.query.usage(scope, {
  type: 'ActualCost',
  timeframe: 'MonthToDate',
  dataset: {
    granularity: 'Monthly',
    aggregation: {
      totalCost: { name: 'Cost', function: 'Sum' }
    },
    grouping: [
      { type: 'Tag', name: 'Application' }
    ]
  }
});
```

### 5.3 GCP Integration

**Authentication:**
- Service Account key (JSON file)

**Required Permissions:**
- Compute Viewer
- Cloud SQL Viewer
- Cloud Functions Viewer

**Discovery Flow:**
```typescript
import { Compute } from '@google-cloud/compute';

const compute = new Compute();
const [vms] = await compute.getVMs();

for (const vm of vms) {
  const metadata = vm.metadata;
  await createDiscoveredResource({
    external_id: metadata.id,
    resource_type: 'gcp_vm',
    name: metadata.name,
    provider: 'gcp',
    region: mapGcpZone(metadata.zone),
    tags: metadata.labels,
    resource_details: metadata
  });
}
```

---

## 6. Mapping Engine

### 6.1 Tag-Based Application Mapping

**Common tag patterns:**
```
AWS:
- Application: "Customer Portal"
- app: "customer-portal"
- Name: "customer-portal-web-01"

Azure:
- application: "Customer Portal"
- app-name: "customer-portal"

GCP:
- app: "customer-portal"
- application: "Customer Portal"
```

**Mapping logic:**
```typescript
function mapResourceToApplication(resource: DiscoveredResource): string | null {
  const tags = resource.tags || {};
  
  // Priority 1: Explicit application tag
  const appTag = tags.Application || tags.application || tags.app || tags['app-name'];
  if (appTag) {
    return findOrCreateApplication(appTag);
  }
  
  // Priority 2: Parse from resource name
  // "customer-portal-web-01" → "Customer Portal"
  const namePattern = /^([a-z-]+)-(web|db|app|api)-\d+$/i;
  const match = resource.name.match(namePattern);
  if (match) {
    const appName = match[1].split('-').map(capitalize).join(' ');
    return findOrCreateApplication(appName);
  }
  
  // Priority 3: Group by owner/team tag
  const owner = tags.Owner || tags.owner || tags.Team || tags.team;
  if (owner) {
    return findOrCreateApplication(`${owner} Infrastructure`);
  }
  
  // Priority 4: Leave unmapped for manual review
  return null;
}
```

### 6.2 AI-Powered Mapping (Phase 27.4 - Future)

**Use Claude API to analyze resource relationships:**

```typescript
async function aiMapResources(resources: DiscoveredResource[]): Promise<Mapping[]> {
  const prompt = `
    Analyze these cloud resources and suggest which belong to the same business application:
    
    Resources:
    ${JSON.stringify(resources.map(r => ({
      id: r.external_id,
      name: r.name,
      type: r.resource_type,
      tags: r.tags
    })), null, 2)}
    
    Consider:
    - Name patterns (e.g., "portal-web-01", "portal-db-01" likely same app)
    - Tag relationships (same application/owner tags)
    - Resource dependencies (web server → database)
    
    Return JSON array of application groups:
    [
      {
        "application_name": "Customer Portal",
        "resource_ids": ["i-123", "db-456"],
        "confidence": 0.95
      }
    ]
  `;
  
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 2000
  });
  
  return JSON.parse(response.content[0].text);
}
```

---

## 7. UI Components

### 7.1 Cloud Connections Page

**Location:** Settings → Integrations → Cloud Providers

```
┌──────────────────────────────────────────────────────────────┐
│ Cloud Providers                              [+ Connect New] │
├──────────────────────────────────────────────────────────────┤
│ Connect your cloud accounts to auto-discover applications   │
│ and infrastructure. Read-only access required.              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ ☁️  AWS Production Account                              ││
│ │ Account: 123456789012                                   ││
│ │ Connected: Jan 30, 2026 • Last sync: 2 hours ago       ││
│ │ Status: ✅ Active • 47 resources discovered            ││
│ │                                                          ││
│ │ [View Resources] [Sync Now] [Settings] [Disconnect]     ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ ☁️  Azure Main Subscription                            ││
│ │ Subscription: sub-abcd-1234                             ││
│ │ Connected: Jan 28, 2026 • Last sync: Yesterday          ││
│ │ Status: ✅ Active • 23 resources discovered            ││
│ │                                                          ││
│ │ [View Resources] [Sync Now] [Settings] [Disconnect]     ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ Empty state:                                                 │
│ ┌──────────────────────────────────────────────────────────┐│
│ │  ☁️                                                      ││
│ │  No cloud providers connected                            ││
│ │  Connect AWS, Azure, or GCP to automatically discover   ││
│ │  your cloud infrastructure.                              ││
│ │                                        [+ Connect Cloud] ││
│ └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

### 7.2 Connect Cloud Provider Wizard

**Step 1: Choose Provider**
```
┌──────────────────────────────────────────────────────────────┐
│ Connect Cloud Provider                              [✕ Close]│
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Choose your cloud provider:                                  │
│                                                              │
│ ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│ │    AWS     │  │   Azure    │  │    GCP     │             │
│ │  ☁️       │  │  ☁️       │  │  ☁️       │             │
│ │  [Select]  │  │  [Select]  │  │  [Select]  │             │
│ └────────────┘  └────────────┘  └────────────┘             │
│                                                              │
│                                    [Cancel]  [Next]          │
└──────────────────────────────────────────────────────────────┘
```

**Step 2: AWS - IAM Role Setup**
```
┌──────────────────────────────────────────────────────────────┐
│ Connect AWS Account                                 [✕ Close]│
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Connection Name *                                            │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ AWS Production Account                                  │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                              │
│ Authentication Method                                        │
│ ◉ IAM Role (Recommended)                                    │
│ ○ Access Keys                                               │
│                                                              │
│ IAM Role ARN *                                              │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ arn:aws:iam::123456789012:role/GetInSyncDiscovery      │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                              │
│ ℹ️ GetInSync needs read-only access to discover resources. │
│ Follow our guide to create the IAM role:                    │
│ [View Setup Guide]                                          │
│                                                              │
│ Discovery Settings                                           │
│ Regions: ☑ All regions  ☐ Specific regions only            │
│ Resource Types: ☑ EC2  ☑ RDS  ☑ Lambda  ☐ S3              │
│                                                              │
│ Sync Frequency                                               │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Daily (recommended)        ▼                            │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                              │
│                          [Back]  [Test Connection]  [Save]  │
└──────────────────────────────────────────────────────────────┘
```

### 7.3 Discovered Resources Page

**Location:** Settings → Integrations → Discovered Resources

```
┌──────────────────────────────────────────────────────────────┐
│ Discovered Resources                       [Sync All Now]   │
├──────────────────────────────────────────────────────────────┤
│ Filter: [All Providers ▼] [All Status ▼] [Search...]        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Unmapped Resources (12)                                      │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ ☁️ web-server-prod-01 (AWS EC2)                         ││
│ │ us-east-1 • t3.medium • $30/mo                           ││
│ │ Tags: Environment=Production, Owner=engineering          ││
│ │ Suggested App: Engineering Infrastructure [Accept]       ││
│ │                                 [Map to App ▼] [Ignore]  ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ Mapped Resources (47)                                        │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ ☁️ customer-portal-web-01 (AWS EC2)                     ││
│ │ Mapped to: Customer Portal - PROD                        ││
│ │ us-east-1 • t3.large • $60/mo                            ││
│ │                                            [Edit] [Unmap] ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ Orphaned Resources (3)                                       │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ ⚠️  old-web-server-02 (AWS EC2)                         ││
│ │ Deleted in AWS 3 days ago • Still linked to App         ││
│ │                                  [Archive] [Keep Active] ││
│ └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

### 7.4 Deployment Profile with Discovery Badge

**In Edit Application modal:**
```
┌──────────────────────────────────────────────────────────────┐
│ Deployment Profiles                                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ Customer Portal - PROD                          ☁️ AWS  ││
│ │ Cloud (IaaS/PaaS) • ca-central-1                        ││
│ │ Discovered: Jan 30, 2026 • Last synced: 2 hours ago     ││
│ │ External ID: i-0abc123def456789                          ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ [+ Add Deployment Profile]                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 8. Security & Privacy

### 8.1 Credential Storage

**Supabase Vault Integration:**
```typescript
// Store credentials encrypted
const { data, error } = await supabase.rpc('vault.create_secret', {
  secret: JSON.stringify({
    access_key_id: awsAccessKey,
    secret_access_key: awsSecretKey
  }),
  name: `cloud-connection-${connectionId}`
});

// Retrieve for sync
const credentials = await supabase.rpc('vault.read_secret', {
  name: `cloud-connection-${connectionId}`
});
```

**Best practices:**
- Never log credentials
- Use IAM roles with least privilege
- Rotate credentials every 90 days
- Audit access to vault

### 8.2 IAM Role Setup (AWS)

**Trust policy for AssumeRole:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::GETINSYNC-ACCOUNT:role/DiscoveryService"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "namespace-uuid-here"
        }
      }
    }
  ]
}
```

**External ID prevents confused deputy:**
- Use namespace_id as ExternalId
- Ensures one organization can't access another's resources

### 8.3 Data Privacy

**What we collect:**
- ✅ Resource metadata (IDs, names, types, regions)
- ✅ Tags/labels
- ✅ Cost data (aggregated)
- ❌ Application data (S3 contents, database records, etc.)
- ❌ Secrets, environment variables, or credentials

**Compliance:**
- PIPEDA compliant (Canadian data stays in ca-central-1)
- GDPR compliant (metadata only, no personal data)
- SOC 2 controls for credential management

---

## 9. Cost Estimation

### 9.1 Instance Type Pricing

**Maintain price database:**
```sql
CREATE TABLE cloud_instance_pricing (
  provider text NOT NULL,
  region text NOT NULL,
  instance_type text NOT NULL,
  hourly_rate numeric(10,4) NOT NULL,
  monthly_rate numeric(10,2) GENERATED ALWAYS AS (hourly_rate * 730) STORED,
  currency text DEFAULT 'USD',
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (provider, region, instance_type)
);

-- Example data
INSERT INTO cloud_instance_pricing VALUES
  ('aws', 'us-east-1', 't3.medium', 0.0416),
  ('aws', 'us-east-1', 't3.large', 0.0832),
  ('azure', 'canadacentral', 'Standard_D2s_v3', 0.096);
```

**Update monthly via API:**
- AWS: Pricing API
- Azure: Retail Prices API
- GCP: Cloud Billing API

### 9.2 Actual Cost Allocation

**From billing APIs:**
```typescript
// Get actual costs by tag
const costs = await getCostsByTag('Application', 'Customer Portal');
// Returns: { '2026-01': 1250.00, '2026-02': 1320.00 }

// Update deployment profile
await supabase
  .from('deployment_profiles')
  .update({
    annual_cost: costs['2026-01'] * 12 // Annualized from last month
  })
  .eq('external_id', instanceId);
```

---

## 10. Implementation Phases

### 10.1 Phase 27.1: CSV Import (2 weeks)

**MVP: Manual export + bulk upload**

**Features:**
- Upload CSV from AWS/Azure/GCP console export
- Map columns to DP fields (hosting_type, cloud_provider, region, etc.)
- Preview before import
- Bulk create Deployment Profiles
- Error handling (duplicate detection)

**Schema:**
- No cloud_connections table needed
- No discovered_resources table needed
- Just add: deployment_profiles.discovery_source = 'csv_import'

**UI:**
```
Settings → Data Management → Import from Cloud
  → Upload CSV
  → Map Columns
  → Preview (show first 10 rows)
  → Confirm Import
  → Show Results (47 created, 3 errors)
```

**Value:**
- Saves 20+ hours of manual entry
- Gets customers using discovery feature
- Validates data model

### 10.2 Phase 27.2: AWS API Discovery (8 weeks)

**Enterprise feature: Live AWS connection**

**Features:**
- IAM Role setup wizard
- OAuth-style connection flow
- Auto-discover EC2, RDS, Lambda
- Tag-based application mapping
- Manual "Sync Now" button
- Discovered Resources review page

**Schema:**
- Add cloud_connections table
- Add discovered_resources table
- Add discovery_sync_log table
- Update deployment_profiles with external_id, discovered_resource_id

**Implementation:**
1. **Week 1-2:** Schema, RLS policies, cloud_connections CRUD
2. **Week 3-4:** AWS SDK integration, EC2/RDS discovery
3. **Week 5-6:** Mapping engine (tag-based)
4. **Week 7:** UI (Cloud Connections page, Discovered Resources page)
5. **Week 8:** Testing, error handling, docs

**Value:**
- Auto-discovers 500+ resources in 5 minutes
- Keeps data fresh (manual sync)
- Differentiates from LeanIX (manual entry)

### 10.3 Phase 27.3: Multi-Cloud + Auto-Sync (12 weeks)

**Full tier feature: Complete discovery automation**

**Features:**
- Azure + GCP support
- Scheduled daily/weekly sync
- Cost data from billing APIs
- Orphan detection (deleted resources)
- Email alerts (new resources found, orphans detected)
- Discovery dashboard (charts, trends)

**Implementation:**
1. **Week 1-4:** Azure integration (Service Principal, VM/SQL discovery)
2. **Week 5-8:** GCP integration (Service Account, Compute/SQL discovery)
3. **Week 9-10:** Scheduled sync (cron jobs, background workers)
4. **Week 11:** Cost data integration (AWS Cost Explorer, Azure Cost Management)
5. **Week 12:** Orphan detection, alerts, dashboard

**Value:**
- Zero-touch discovery after setup
- Cost data auto-populates
- Detects shadow IT (unauthorized resources)

### 10.4 Phase 27.4: AI-Powered Mapping (Future)

**Advanced feature: Intelligent application grouping**

**Features:**
- Claude API analyzes resource relationships
- Suggests application boundaries
- Confidence scoring
- Learns from user corrections

**Implementation:**
- Use Claude API to analyze tags, names, dependencies
- Build knowledge graph of resources
- Suggest groupings with confidence scores
- User accepts/rejects, system learns

**Value:**
- Maps 95% of resources automatically
- Handles orgs with poor tagging
- Discovers application boundaries

---

## 11. Tier Gating

### 11.1 Feature by Tier

| Feature | Free | Pro | Enterprise | Full |
|---------|------|-----|------------|------|
| Manual DP entry | ✅ | ✅ | ✅ | ✅ |
| CSV import | ❌ | ✅ | ✅ | ✅ |
| AWS discovery | ❌ | ❌ | ✅ (1 account) | ✅ (unlimited) |
| Azure discovery | ❌ | ❌ | ❌ | ✅ |
| GCP discovery | ❌ | ❌ | ❌ | ✅ |
| Scheduled sync | ❌ | ❌ | ❌ | ✅ |
| Cost data integration | ❌ | ❌ | ❌ | ✅ |
| AI mapping | ❌ | ❌ | ❌ | ✅ (Phase 27.4) |

### 11.2 Pricing Justification

**Competitive pricing:**
- Flexera One: $50K-$200K/year
- ServiceNow Discovery: $100K+ implementation
- Apptio: $75K-$150K/year

**GetInSync pricing:**
- **Pro tier ($99/user/mo):** CSV import only
- **Enterprise tier ($199/user/mo):** AWS discovery (1 account)
- **Full tier ($299/user/mo):** Multi-cloud discovery + auto-sync + cost data

**At 5 users:**
- Pro: $495/mo ($5,940/year) - still cheaper than competitors
- Enterprise: $995/mo ($11,940/year) - 75% cheaper than Flexera
- Full: $1,495/mo ($17,940/year) - 80% cheaper than Flexera

**Justification:**
- Saves 40+ hours/month of manual work = $4,000/month labor cost
- Discovers shadow IT ($50K-$100K in unnecessary spend)
- Enables TIME/PAID rationalization ($500K+ in savings)
- **ROI:** 10x in first year

---

## 12. Competitive Positioning

### 12.1 vs ServiceNow Discovery

**ServiceNow:**
- ❌ Complex setup (dedicated admin, 3-6 months)
- ❌ Expensive ($100K+ implementation)
- ❌ Discovers CIs but doesn't map to business applications well
- ✅ Comprehensive (network, on-prem, cloud)

**GetInSync:**
- ✅ 5-minute setup (connect AWS account)
- ✅ Affordable ($11,940/year vs $100K+)
- ✅ Auto-maps to business applications (tag-based)
- ❌ Cloud-only (not network discovery)

**Positioning:** "ServiceNow Discovery for the rest of us"

### 12.2 vs Flexera One

**Flexera:**
- ✅ Multi-cloud discovery
- ✅ Strong FinOps focus
- ❌ Weak APM capabilities
- ❌ Expensive ($50K-$200K/year)

**GetInSync:**
- ✅ Multi-cloud discovery (Phase 27.3)
- ✅ Discovery + APM + TIME/PAID assessment
- ✅ Affordable ($17,940/year)
- ❌ Less mature FinOps features (for now)

**Positioning:** "Discovery + Rationalization in one platform"

### 12.3 vs LeanIX

**LeanIX:**
- ❌ Manual data entry only
- ✅ Strong APM capabilities
- ✅ Good visualizations
- ❌ Expensive ($40K-$80K/year)

**GetInSync:**
- ✅ Auto-discovery (zero manual entry)
- ✅ APM + TIME/PAID framework
- ✅ Affordable ($17,940/year)
- ❌ Visualizations not as mature (yet)

**Positioning:** "LeanIX with auto-discovery"

---

## 13. Go-to-Market Strategy

### 13.1 Target Customers

**Phase 27.1 (CSV Import):**
- SMBs with 50-500 applications
- Organizations just starting APM journey
- Budget: $10K-$25K/year

**Phase 27.2 (AWS Discovery):**
- Mid-market with 500-2000 applications
- Cloud-first organizations
- Existing AWS footprint
- Budget: $25K-$75K/year

**Phase 27.3 (Multi-Cloud):**
- Enterprise with 2000+ applications
- Multi-cloud strategy (AWS + Azure + GCP)
- FinOps maturity
- Budget: $75K-$200K/year

### 13.2 Marketing Messages

**Pain → Solution:**

| Pain | GetInSync Message |
|------|-------------------|
| "We have 800 applications and no idea what's in the cloud" | "Connect your AWS account, discover 800 apps in 5 minutes" |
| "Manual data entry takes 40 hours/month" | "Auto-discovery saves 38 hours/month" |
| "Our APM data is always out of date" | "Daily sync keeps your portfolio fresh" |
| "Flexera costs $100K/year just for discovery" | "GetInSync: Discovery + APM for $18K/year" |
| "We can't justify ServiceNow's $200K implementation" | "GetInSync: 5-minute setup, no consultants required" |

**Value props:**
1. **Speed:** 5 minutes to discover 800 applications
2. **Savings:** 38 hours/month labor + 80% cheaper than competitors
3. **Freshness:** Daily sync, never stale
4. **Simplicity:** QuickBooks-simple, not ServiceNow-complex
5. **Integration:** Discovery + APM + Rationalization in one platform

### 13.3 Sales Collateral

**Demo flow:**
1. Show customer's AWS console (800 EC2 instances)
2. Connect GetInSync to AWS (5 minutes)
3. Watch 800 resources appear in Discovered Resources
4. AI suggests application mappings (accept 90%)
5. Show TIME/PAID dashboard now populated
6. "You just saved 40 hours of manual work"

**Case study template:**
```
Before GetInSync:
- 800 applications, manually tracked in Excel
- 40 hours/month updating inventory
- Data always 2-3 months stale
- No idea of cloud costs per application

After GetInSync (Phase 27.2):
- Connected AWS account in 5 minutes
- Auto-discovered 800 resources
- Daily sync keeps data fresh
- Cost per application auto-calculated
- Identified $500K in rationalization opportunities

ROI: 10x in first year
```

---

## 14. Technical Considerations

### 14.1 Rate Limits

**AWS:**
- EC2 DescribeInstances: 100 req/sec
- RDS DescribeDBInstances: 50 req/sec
- Strategy: Batch by region, respect limits

**Azure:**
- Resource Graph: 15 req/10 sec
- Strategy: Use continuation tokens, throttle

**GCP:**
- Compute API: 2000 req/min
- Strategy: Use batch requests

### 14.2 Error Handling

**Transient errors:**
- Network timeouts
- API throttling
- Temporary credential issues

**Strategy:**
- Exponential backoff retry (3 attempts)
- Log to discovery_sync_log
- Continue with other resources

**Permanent errors:**
- Invalid credentials
- Insufficient permissions
- Account suspended

**Strategy:**
- Mark connection status = 'error'
- Email admin
- Provide remediation steps

### 14.3 Performance

**Sync time estimates:**
- 100 resources: ~30 seconds
- 500 resources: ~2 minutes
- 2000 resources: ~10 minutes
- 10000 resources: ~45 minutes

**Optimization:**
- Parallel region discovery
- Batch database inserts
- Delta sync (only changed resources)

### 14.4 Data Volume

**Storage estimates per 1000 resources:**
- discovered_resources: ~5 MB (resource_details is large)
- discovery_sync_log: ~1 KB per sync
- cloud_connections: ~1 KB per connection

**At 10,000 resources:**
- ~50 MB for discovered_resources
- Acceptable for multi-tenant SaaS

---

## 15. Metrics & Success Criteria

### 15.1 Product Metrics

**Adoption:**
- % of Enterprise customers using discovery
- % of Full customers using discovery
- Average # of cloud connections per namespace

**Usage:**
- Total resources discovered
- % of resources mapped to applications
- Sync frequency (manual vs scheduled)
- Time from connect to first sync

**Value:**
- Hours saved per month (vs manual entry)
- % of applications with cost data
- Orphaned resources detected

### 15.2 Business Metrics

**Revenue:**
- Discovery feature conversion rate (Pro → Enterprise)
- Discovery feature retention
- Average ARR increase with discovery

**Competitive:**
- Win rate vs Flexera (cite discovery)
- Win rate vs LeanIX (cite auto-discovery)
- Customer quotes citing discovery as key differentiator

### 15.3 Success Criteria

**Phase 27.1 (CSV Import):**
- ✅ 30% of Pro customers use CSV import
- ✅ Average 200 resources imported per customer
- ✅ 90% customer satisfaction (survey)

**Phase 27.2 (AWS Discovery):**
- ✅ 50% of Enterprise customers connect AWS
- ✅ Average 500 resources discovered per customer
- ✅ 80% of resources auto-mapped
- ✅ 5x increase in customer references

**Phase 27.3 (Multi-Cloud):**
- ✅ 40% of Full customers use multi-cloud discovery
- ✅ Average 2000 resources discovered per customer
- ✅ Daily sync adoption: 70%
- ✅ "Discovery" cited in 80% of won deals

---

## 16. Risks & Mitigations

### 16.1 Security Risk

**Risk:** Credential compromise
**Impact:** Unauthorized access to customer cloud accounts
**Mitigation:**
- Supabase Vault encryption
- Read-only IAM permissions
- External ID for AWS (prevents confused deputy)
- Rotate credentials every 90 days
- SOC 2 controls for credential management

### 16.2 API Changes

**Risk:** Cloud provider API breaking changes
**Impact:** Discovery fails, customer data stale
**Mitigation:**
- Version lock API clients
- Monitor provider changelogs
- Automated tests for API changes
- Graceful degradation (log error, continue)

### 16.3 Performance Risk

**Risk:** Large customers (10,000+ resources) cause timeouts
**Impact:** Sync never completes, UI slow
**Mitigation:**
- Background job processing (not synchronous)
- Delta sync (only changed resources)
- Pagination with continuation tokens
- Progress indicators in UI

### 16.4 Mapping Accuracy

**Risk:** AI/tag-based mapping creates wrong application groups
**Impact:** Customer distrust, manual cleanup required
**Mitigation:**
- Confidence scoring (show low-confidence as "suggested")
- Review step before auto-mapping
- Easy unmapping + remapping in UI
- Learn from corrections (Phase 27.4)

### 16.5 Cost Accuracy

**Risk:** Estimated costs don't match actual bills
**Impact:** Customer questions data accuracy
**Mitigation:**
- Clearly label "Estimated" vs "Actual"
- Update pricing database monthly
- Use actual cost data from billing APIs (Phase 27.3)
- Disclaimer: "Costs are estimates, see cloud bill for actuals"

---

## 17. Documentation Requirements

### 17.1 Customer Documentation

**Setup Guides:**
- "Connect Your AWS Account in 5 Minutes"
- "Create an AWS IAM Role for GetInSync"
- "Connect Your Azure Subscription"
- "Understanding Cloud Discovery"

**Troubleshooting:**
- "Why Aren't Resources Appearing?"
- "How to Fix IAM Permission Errors"
- "Mapping Resources to Applications"

### 17.2 Internal Documentation

**Architecture:**
- Cloud Discovery System Design
- API Integration Patterns
- Mapping Engine Logic

**Operations:**
- Monitoring Discovery Sync Jobs
- Handling Failed Syncs
- Debugging IAM Issues

---

## 18. Future Enhancements

### 18.1 Phase 27.5: Kubernetes Discovery

**Problem:** Containers and microservices invisible to current discovery

**Solution:**
- Connect to Kubernetes clusters (EKS, AKS, GKE)
- Discover pods, services, ingresses
- Map to applications based on namespace/labels

### 18.2 Phase 27.6: Network Topology

**Problem:** No visibility into resource relationships

**Solution:**
- Discover security groups, VPCs, load balancers
- Build network topology map
- Show application dependencies

### 18.3 Phase 27.7: Configuration Drift Detection

**Problem:** Infrastructure changes outside GetInSync

**Solution:**
- Compare current cloud state to GetInSync
- Detect configuration drift
- Alert on unauthorized changes

### 18.4 Phase 27.8: Cost Optimization Recommendations

**Problem:** Customers don't know how to reduce cloud costs

**Solution:**
- Analyze instance utilization (CloudWatch, Azure Monitor)
- Recommend rightsizing (t3.large → t3.medium)
- Identify idle resources
- Estimate savings

---

## 19. Competitive Intelligence

### 19.1 Watch List

**Monitor these competitors:**
- Flexera One: Feature announcements, pricing changes
- ServiceNow: Discovery product updates
- Apptio Cloudability: New capabilities
- Device42: Cloud discovery expansion

**Monthly review:**
- Pricing comparisons
- Feature gap analysis
- Customer win/loss attribution

### 19.2 Differentiation Maintenance

**Ensure GetInSync remains differentiated:**
- Discovery + APM + Assessment (unique combination)
- QuickBooks simplicity (vs ServiceNow complexity)
- 80% cost savings (vs Flexera/Apptio)
- 5-minute setup (vs 3-6 month implementations)

---

## 20. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-01-31 | Initial architecture document for Phase 27 Cloud Discovery |

---

*Document: features/cloud-discovery/architecture.md*
*January 2026*
