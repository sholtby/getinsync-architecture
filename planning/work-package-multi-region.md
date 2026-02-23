# planning/work-package-multi-region.md
Multi-Region Data Residency Architecture Work Package  
Phase: Foundation (Week 2)  
Last updated: 2026-02-07

---

## Executive Summary

**Objective:** Make GetInSync codebase multi-region capable while deploying Canada first

**Strategic Decision:** Option C (Hybrid Smart Compromise)
- Canada instance: Ready NOW (live in production)
- Multi-region capable: Build infrastructure Week 2
- US/EU instances: Deploy on-demand when first customer needs them (2-3 hours each)

**Timeline:** 2-3 hours (Week 2)  
**Owner:** Stuart  
**Effort:** Minimal - mostly configuration, no code changes

---

## Strategic Context

### Why Multi-Region Matters

**Government Market (Primary):**
- Canadian governments REQUIRE Canadian data residency (FOIP compliance)
- US governments require US data residency (state data residency laws)
- EU governments require EU data residency (GDPR Article 45)

**Competitive Positioning:**
- LeanIX: US-only (data in US East)
- ServiceNow: Multi-region but expensive ($$$)
- Flexera: US-only
- **GetInSync:** Multi-region at "QuickBooks price" 🎯

**Market Reality:**
- 95% of near-term customers = Canadian (Saskatchewan, Alberta, BC, Ontario)
- 5% might be US/EU in 6-12 months
- Don't optimize for hypothetical customers

---

## Option Analysis (From Session)

### Option A: Canada Only (Rejected)

**Pros:**
- Simplest (no extra work)
- Meets 95% of near-term customer needs

**Cons:**
- ❌ Blocks US expansion (even if 6-12 months away)
- ❌ "Sorry, Canada only" hurts positioning
- ❌ Can't say "multi-region" in marketing
- ❌ Limits addressable market

**Verdict:** Too limiting for growth ambitions

---

### Option B: Full Multi-Region Now (Rejected)

**Pros:**
- Ready for any customer from Day 1
- Strong marketing position

**Cons:**
- ❌ **Massive overkill** for current customer base
- ❌ 8-10 hours effort (database setup, deployment, testing × 3 regions)
- ❌ Monthly hosting cost × 3 ($150/mo → $450/mo)
- ❌ Testing complexity × 3
- ❌ 95% waste if no US/EU customers for 6 months

**Verdict:** Premature optimization, poor ROI

---

### Option C: Hybrid Smart Compromise (SELECTED) ✓

**Infrastructure:**
- Codebase supports multiple regions (environment variables)
- Canada deployed NOW (already live)
- US/EU deployed on-demand (2-3 hours each when needed)

**Deployment Trigger:**
- First US customer signs up → Deploy US region (same day)
- First EU customer signs up → Deploy EU region (same day)

**Marketing Message:**
- "Multi-region data residency available"
- "Default: Canadian data centers"
- "US and EU regions available on request"

**Pros:**
- ✅ Ready for Canada NOW (95% of customers)
- ✅ Can say "multi-region capable" in marketing
- ✅ Deploy US/EU in 2-3 hours when needed
- ✅ Low effort (2-3 hours total)
- ✅ Low cost (pay only for regions you use)
- ✅ No waste if US/EU customers don't materialize

**Cons:**
- First US/EU customer has 1-day delay (acceptable)

**Verdict:** Perfect balance of capability and pragmatism

---

## Architecture Design

### Current State (Canada Only)

```
┌─────────────────────────────────────┐
│  Frontend (Netlify)                 │
│  nextgen.getinsync.ca               │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Supabase                           │
│  Project: getinsync-nextgen         │
│  Region: ca-central-1 (Montreal)    │
│  - Database (PostgreSQL)            │
│  - Auth (Supabase Auth)             │
│  - Storage (S3-compatible)          │
└─────────────────────────────────────┘
```

**Environment Variables (Current):**
```env
VITE_SUPABASE_URL=https://[project-id].supabase.co
VITE_SUPABASE_ANON_KEY=[key]
```

**Problem:** Hardcoded single Supabase instance

---

### Target State (Multi-Region Capable)

```
┌─────────────────────────────────────────────────────────────┐
│  Frontend (Netlify or Azure Static Web Apps)                │
│  - Canada:  nextgen.getinsync.ca                            │
│  - US:      us.getinsync.ca  (deploy when needed)           │
│  - EU:      eu.getinsync.ca  (deploy when needed)           │
└──────────────┬──────────────────────────────────────────────┘
               │
               ↓ (Routing based on namespace.region)
               │
    ┌──────────┼──────────┐
    │          │          │
    ↓          ↓          ↓
┌────────┐ ┌────────┐ ┌────────┐
│ Canada │ │   US   │ │   EU   │
│Supabase│ │Supabase│ │Supabase│
│ca-cent-│ │us-east-│ │eu-west-│
│ral-1   │ │   1    │ │   1    │
└────────┘ └────────┘ └────────┘
   NOW      ON-DEMAND  ON-DEMAND
```

**Key Architectural Decision:**
- Namespace has `region` column: 'ca' | 'us' | 'eu'
- Frontend reads namespace.region → connects to correct Supabase instance
- Each region = separate Supabase project (complete data isolation)

---

## Implementation Plan

### Step 1: Add Region Field to Namespaces (10 minutes)

**Database Migration:**
```sql
-- Add region column to namespaces table
ALTER TABLE namespaces 
ADD COLUMN region VARCHAR(10) DEFAULT 'ca' NOT NULL;

-- Add check constraint (only allow known regions)
ALTER TABLE namespaces
ADD CONSTRAINT namespaces_region_check 
CHECK (region IN ('ca', 'us', 'eu'));

-- Create index for efficient region lookups
CREATE INDEX idx_namespaces_region ON namespaces(region);

-- Update existing namespaces to 'ca' (already default)
UPDATE namespaces SET region = 'ca';

-- Add comment
COMMENT ON COLUMN namespaces.region IS 
'Data residency region: ca (Canada), us (United States), eu (European Union)';
```

**Verify:**
```sql
SELECT id, name, region, created_at 
FROM namespaces 
ORDER BY created_at DESC 
LIMIT 10;
```

**Expected Output:**
```
id                                   | name              | region | created_at
-------------------------------------|-------------------|--------|-------------------
b00adf2d-4584-4bb4-a889-6931782960dc | GetInSync Demo    | ca     | 2026-01-15 10:23:45
...
```

---

### Step 2: Create Region Configuration (15 minutes)

**Add Environment Variables:**

Create `.env.local` (development):
```env
# Default region (Canada)
VITE_SUPABASE_URL_CA=https://[your-project-id].supabase.co
VITE_SUPABASE_ANON_KEY_CA=[your-anon-key]

# US region (will create when needed)
VITE_SUPABASE_URL_US=
VITE_SUPABASE_ANON_KEY_US=

# EU region (will create when needed)
VITE_SUPABASE_URL_EU=
VITE_SUPABASE_ANON_KEY_EU=
```

Create `src/lib/region-config.ts`:
```typescript
// Region configuration for multi-region data residency

export type Region = 'ca' | 'us' | 'eu'

export interface RegionConfig {
  code: Region
  name: string
  location: string
  supabaseUrl: string
  supabaseAnonKey: string
  available: boolean
}

export const REGION_CONFIGS: Record<Region, RegionConfig> = {
  ca: {
    code: 'ca',
    name: 'Canada',
    location: 'Montreal, Quebec',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_CA || '',
    supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY_CA || '',
    available: true // Canada is always available
  },
  us: {
    code: 'us',
    name: 'United States',
    location: 'Virginia, USA',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_US || '',
    supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY_US || '',
    available: false // Will be true when we deploy US instance
  },
  eu: {
    code: 'eu',
    name: 'European Union',
    location: 'Ireland, EU',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_EU || '',
    supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY_EU || '',
    available: false // Will be true when we deploy EU instance
  }
}

export function getRegionConfig(region: Region): RegionConfig {
  const config = REGION_CONFIGS[region]
  
  if (!config) {
    throw new Error(`Unknown region: ${region}`)
  }
  
  if (!config.available) {
    throw new Error(`Region ${region} is not yet available. Contact support@getinsync.ca to enable.`)
  }
  
  return config
}

export function getAvailableRegions(): RegionConfig[] {
  return Object.values(REGION_CONFIGS).filter(r => r.available)
}
```

---

### Step 3: Update Supabase Client (30 minutes)

**Current Implementation:**
```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

**Problem:** Single global Supabase client

**New Implementation:**
```typescript
// src/lib/supabase.ts
import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { Region, getRegionConfig } from './region-config'

// Cache of Supabase clients by region
const clients: Partial<Record<Region, SupabaseClient>> = {}

/**
 * Get Supabase client for a specific region
 * Clients are cached to avoid recreating connections
 */
export function getSupabaseClient(region: Region = 'ca'): SupabaseClient {
  // Return cached client if exists
  if (clients[region]) {
    return clients[region]!
  }
  
  // Get region configuration
  const config = getRegionConfig(region)
  
  // Create new client
  const client = createClient(config.supabaseUrl, config.supabaseAnonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true
    }
  })
  
  // Cache it
  clients[region] = client
  
  return client
}

/**
 * Get Supabase client for current user's namespace region
 * This is the most common use case
 */
export async function getCurrentUserClient(): Promise<SupabaseClient> {
  // Get current user's namespace
  const defaultClient = getSupabaseClient('ca') // Default to Canada for initial auth
  const { data: { user } } = await defaultClient.auth.getUser()
  
  if (!user) {
    throw new Error('No authenticated user')
  }
  
  // Look up user's namespace region
  const { data: namespace, error } = await defaultClient
    .from('namespaces')
    .select('region')
    .eq('user_id', user.id)
    .single()
  
  if (error || !namespace) {
    console.warn('Could not determine user region, defaulting to Canada')
    return defaultClient
  }
  
  // Return client for user's region
  return getSupabaseClient(namespace.region as Region)
}

// Default export for backward compatibility (uses Canada)
export const supabase = getSupabaseClient('ca')
```

**Migration Strategy:**
```typescript
// Gradually migrate code from:
import { supabase } from '@/lib/supabase'

// To:
import { getCurrentUserClient } from '@/lib/supabase'
const supabase = await getCurrentUserClient()

// Or for unauthenticated operations (login, signup):
import { getSupabaseClient } from '@/lib/supabase'
const supabase = getSupabaseClient('ca') // Default to Canada
```

**Phase 1 (Week 2):** Add new functions, keep old export  
**Phase 2 (Future):** Gradually migrate components to use getCurrentUserClient()  
**Phase 3 (Future):** Remove old default export when all code migrated

---

### Step 4: Update Namespace Creation (20 minutes)

**When Creating New Namespace:**

Add region selector to signup flow (optional for now, default to Canada):

```typescript
// src/components/onboarding/NamespaceSetup.tsx
import { useState } from 'react'
import { getAvailableRegions, Region } from '@/lib/region-config'

export function NamespaceSetup() {
  const [region, setRegion] = useState<Region>('ca')
  const availableRegions = getAvailableRegions()
  
  return (
    <div>
      <h2>Set Up Your Organization</h2>
      
      {/* Existing fields: organization name, etc. */}
      
      <div className="mt-4">
        <label className="block text-sm font-medium mb-2">
          Data Residency Region
        </label>
        <p className="text-sm text-gray-600 mb-2">
          Your data will be stored in this region and cannot be changed later.
        </p>
        
        <select 
          value={region}
          onChange={(e) => setRegion(e.target.value as Region)}
          className="w-full px-3 py-2 border rounded-lg"
        >
          {availableRegions.map(r => (
            <option key={r.code} value={r.code}>
              {r.name} ({r.location})
            </option>
          ))}
        </select>
        
        {region === 'ca' && (
          <p className="text-sm text-green-600 mt-2">
            ✓ Recommended for Canadian organizations (PIPEDA/FOIP compliance)
          </p>
        )}
      </div>
      
      {/* Rest of form... */}
    </div>
  )
}
```

**Backend RPC Function Update:**
```sql
CREATE OR REPLACE FUNCTION create_namespace(
  p_name TEXT,
  p_region VARCHAR(10) DEFAULT 'ca'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_namespace_id UUID;
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate region
  IF p_region NOT IN ('ca', 'us', 'eu') THEN
    RAISE EXCEPTION 'Invalid region: %. Must be ca, us, or eu', p_region;
  END IF;
  
  -- Check if region is available (for future use)
  -- For now, only 'ca' is available
  IF p_region != 'ca' THEN
    RAISE EXCEPTION 'Region % is not yet available. Contact support@getinsync.ca', p_region;
  END IF;
  
  -- Create namespace
  INSERT INTO namespaces (name, region, created_by)
  VALUES (p_name, p_region, v_user_id)
  RETURNING id INTO v_namespace_id;
  
  -- Assign creator as namespace admin
  INSERT INTO namespace_users (namespace_id, user_id, role)
  VALUES (v_namespace_id, v_user_id, 'admin');
  
  RETURN v_namespace_id;
END;
$$;
```

---

### Step 5: UI Region Indicator (20 minutes)

**Show User's Region in Header:**

```typescript
// src/components/layout/Header.tsx
import { useEffect, useState } from 'react'
import { getCurrentUserClient } from '@/lib/supabase'
import { getRegionConfig, Region } from '@/lib/region-config'

export function Header() {
  const [region, setRegion] = useState<Region>('ca')
  
  useEffect(() => {
    const loadUserRegion = async () => {
      try {
        const client = await getCurrentUserClient()
        const { data: { user } } = await client.auth.getUser()
        
        if (user) {
          const { data: namespace } = await client
            .from('namespaces')
            .select('region')
            .eq('user_id', user.id)
            .single()
          
          if (namespace) {
            setRegion(namespace.region as Region)
          }
        }
      } catch (err) {
        console.error('Error loading region:', err)
      }
    }
    
    loadUserRegion()
  }, [])
  
  const regionConfig = getRegionConfig(region)
  
  return (
    <header className="border-b bg-white">
      <div className="flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-4">
          <h1>GetInSync</h1>
          
          {/* Region badge */}
          <span className="inline-flex items-center gap-1 px-2 py-1 bg-green-50 text-green-700 text-xs rounded-full">
            <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd" />
            </svg>
            {regionConfig.name}
          </span>
        </div>
        
        {/* User menu, etc. */}
      </div>
    </header>
  )
}
```

**Why Show Region?**
- Transparency: Users know where their data is
- Compliance: Easy to verify for audits
- Support: Helpful when troubleshooting

---

### Step 6: Documentation & Testing (30 minutes)

**Create `docs/multi-region-deployment.md`:**

```markdown
# Multi-Region Deployment Guide

## Current Status
- ✅ Canada (ca-central-1): LIVE
- ⏳ US (us-east-1): Deploy on-demand
- ⏳ EU (eu-west-1): Deploy on-demand

## How to Deploy a New Region

### Step 1: Create Supabase Project (20 minutes)

1. Go to https://app.supabase.com
2. Click "New project"
3. Name: "getinsync-nextgen-[region]" (e.g., "getinsync-nextgen-us")
4. Database password: Generate strong password (save in 1Password)
5. Region: Select desired region
   - US: us-east-1 (Virginia)
   - EU: eu-west-1 (Ireland)
6. Wait for project creation (~2 minutes)

### Step 2: Run Database Migrations (10 minutes)

```bash
# Export Supabase credentials
export SUPABASE_URL=https://[new-project-id].supabase.co
export SUPABASE_KEY=[service-role-key]

# Run all migrations
npm run migrate:region -- --region us
```

### Step 3: Configure Authentication (10 minutes)

1. In Supabase Dashboard → Authentication → Providers
2. Enable Google OAuth (same Client ID/Secret as Canada)
3. Enable Azure OAuth (same Application ID/Secret as Canada)
4. Configure redirect URLs for new region
5. Update Site URL

### Step 4: Update Environment Variables (5 minutes)

```env
# Add to .env.production
VITE_SUPABASE_URL_US=https://[project-id].supabase.co
VITE_SUPABASE_ANON_KEY_US=[anon-key]
```

### Step 5: Update Region Config (5 minutes)

```typescript
// src/lib/region-config.ts
us: {
  code: 'us',
  name: 'United States',
  location: 'Virginia, USA',
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL_US || '',
  supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY_US || '',
  available: true // ← Change to true
}
```

### Step 6: Deploy Frontend (10 minutes)

```bash
# Rebuild with new environment variables
npm run build

# Deploy to Netlify/Azure
netlify deploy --prod

# Or Azure Static Web Apps
az staticwebapp deploy
```

### Step 7: Test (30 minutes)

1. Create test account in new region
2. Verify data is in correct Supabase project
3. Test authentication (Google, Microsoft, email)
4. Test RLS policies
5. Test cross-region isolation (Canada user can't see US data)

### Step 8: Enable Region in Database (5 minutes)

```sql
-- Remove availability check from create_namespace function
-- Now allows 'us' as valid region
```

### Step 9: Update Marketing (10 minutes)

- Update website to show US available
- Add US region to sales materials
- Notify sales team

**Total Time:** ~2-3 hours
```

---

## Testing Strategy

### Test 1: Region Field Works (5 minutes)

```sql
-- Verify region column exists
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'namespaces' AND column_name = 'region';

-- Verify check constraint exists
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'namespaces_region_check';

-- Test creating namespace with different regions
-- This should work (Canada is available)
SELECT create_namespace('Test Canada', 'ca');

-- This should fail (US not yet available)
SELECT create_namespace('Test US', 'us');
-- Expected: ERROR:  Region us is not yet available
```

---

### Test 2: Multi-Client Configuration Works (10 minutes)

```typescript
// Test in browser console
import { getSupabaseClient, getAvailableRegions } from './lib/supabase'

// Should return Canada config
const caClient = getSupabaseClient('ca')
console.log('Canada client:', caClient.supabaseUrl)

// Should throw error (not available)
try {
  const usClient = getSupabaseClient('us')
} catch (err) {
  console.log('Expected error:', err.message)
  // "Region us is not yet available"
}

// Should return only Canada
const available = getAvailableRegions()
console.log('Available regions:', available)
// [{code: 'ca', name: 'Canada', ...}]
```

---

### Test 3: Namespace Creation with Region (10 minutes)

```typescript
// In signup flow
const { data, error } = await supabase.rpc('create_namespace', {
  p_name: 'Test Organization',
  p_region: 'ca'
})

if (error) {
  console.error('Error:', error)
} else {
  console.log('Namespace created:', data)
}

// Verify in database
const { data: namespace } = await supabase
  .from('namespaces')
  .select('*')
  .eq('id', data)
  .single()

console.log('Namespace region:', namespace.region)
// Should be 'ca'
```

---

## On-Demand Deployment Process

### Trigger: First US Customer Signs Up

**Day 1 (Before they sign up):**
- Sales team identifies customer is US-based
- Sales team emails Stuart: "US customer ready to sign up"

**Day 1 (Same day, 2-3 hours):**
1. Stuart creates US Supabase project (20 min)
2. Runs migrations (10 min)
3. Configures OAuth (10 min)
4. Updates environment variables (5 min)
5. Updates region-config.ts (5 min)
6. Deploys frontend (10 min)
7. Tests (30 min)
8. Enables US region in database (5 min)

**Day 1 (Evening):**
- Customer can sign up and select US region
- Data goes to US Supabase instance
- All working properly

**Total Customer Delay:** Same day (acceptable for first customer in new region)

---

## Marketing Messaging

### Website Copy (NOW - Even Before US/EU Deployed)

**Homepage:**
```markdown
## Enterprise-Grade Data Residency

Your data stays where you need it to stay.

**Default:** Canadian data centers (Montreal, Quebec)  
**PIPEDA & FOIP compliant** out of the box

**Available on Request:**
- United States (Virginia)
- European Union (Ireland, GDPR compliant)

Choose your region during signup. Your data never leaves your chosen region.
```

**Pricing Page:**
```markdown
### Multi-Region Data Residency

**Included in all tiers:**
- Default: Canada (ca-central-1)
- Available: US (us-east-1) and EU (eu-west-1)
- Your choice is permanent (data doesn't move)

**Enterprise customers:** Custom regions available (contact sales)
```

**Security Page (NEW):**
```markdown
## Where Your Data Lives

GetInSync gives you control over where your data is stored:

### Canada (Default)
- Location: Montreal, Quebec
- Compliance: PIPEDA, provincial FOIP laws
- Ideal for: Canadian government, healthcare, education

### United States (Available on Request)
- Location: Virginia, USA
- Compliance: SOC2, US state data residency laws
- Ideal for: US government, US enterprises

### European Union (Available on Request)
- Location: Ireland, EU
- Compliance: GDPR, Data Protection Directive
- Ideal for: EU government, EU enterprises

**Your data never crosses borders.** When you choose a region, your data stays there permanently.
```

---

## Competitive Positioning

### Against LeanIX (US-Only)

**Sales Pitch:**
> "LeanIX stores all customer data in US data centers, which can be a procurement blocker for Canadian government organizations required to comply with provincial FOIP laws. GetInSync stores your data in Canada by default, with US and EU options available if needed."

**Proof Points:**
- Alberta FOIP requires Canadian data residency
- Saskatchewan LA FOIP requires Canadian data residency
- BC FIPPA requires Canadian data residency
- LeanIX: US-only = automatic disqualification

---

### Against ServiceNow (Expensive Multi-Region)

**Sales Pitch:**
> "ServiceNow offers multi-region deployment, but their enterprise pricing starts at $100K+/year. GetInSync offers the same multi-region capability at a fraction of the cost, with Canadian data residency included in all tiers."

**Proof Points:**
- ServiceNow APM: $100K-$500K/year
- GetInSync Pro: $5K-$10K/year
- Same multi-region capability
- "QuickBooks price, enterprise features"

---

## Success Criteria

### Week 2 (Foundation Complete)
- ✅ Region field added to namespaces table
- ✅ Region config TypeScript module created
- ✅ Multi-client Supabase setup working
- ✅ Documentation written
- ✅ Tested in development

### Marketing Ready (Immediate)
- ✅ Can claim "multi-region data residency" in marketing
- ✅ Website updated with data residency messaging
- ✅ Sales team trained on data residency pitch
- ✅ Competitive positioning documents updated

### Production Ready (When First Non-CA Customer)
- ⏳ US instance deployed in 2-3 hours
- ⏳ EU instance deployed in 2-3 hours
- ⏳ Customer can sign up same day
- ⏳ Zero code changes required

---

## Cost Analysis

### Current (Canada Only)
- Supabase ca-central-1: $25/mo (Free tier for now, $25 when we exceed limits)
- Netlify Pro: $19/mo
- **Total:** $44/mo

### With US Added
- Supabase ca-central-1: $25/mo
- Supabase us-east-1: $25/mo
- Netlify Pro: $19/mo (same deployment, multiple domains)
- **Total:** $69/mo (+$25/mo)

### With US + EU Added
- Supabase ca-central-1: $25/mo
- Supabase us-east-1: $25/mo
- Supabase eu-west-1: $25/mo
- Netlify Pro: $19/mo
- **Total:** $94/mo (+$50/mo)

**ROI Calculation:**
- Cost per region: $25/mo
- Revenue per customer (Pro tier): $99/mo
- **Break-even:** 1 customer = 4 regions paid for

**Conclusion:** Financially prudent to deploy regions on-demand

---

## Risks & Mitigations

### Risk 1: First US Customer Impatient

**Risk:** First US customer wants to sign up immediately, can't wait 2-3 hours

**Mitigation:**
- Sales qualifies region preference during initial call
- If US customer, deploy US region BEFORE sales call concludes
- Customer gets signup link with US region ready

**Likelihood:** Low (sales cycle is weeks, not hours)

---

### Risk 2: Forgot to Deploy Region

**Risk:** Customer signs up for US, but Stuart forgot to deploy US instance

**Mitigation:**
- Region selector shows only available regions (getAvailableRegions())
- If US not available, it won't show in dropdown
- Customer defaults to Canada
- Clear messaging: "US region available on request"

**Impact:** Customer uses Canada temporarily, we migrate later (acceptable)

---

### Risk 3: Data Migration Between Regions

**Risk:** Customer signs up in Canada, later wants to move to US

**Mitigation:**
- Clear messaging during signup: "Your region choice is permanent"
- If customer absolutely needs migration: manual process, 1-2 days
- Charge migration fee ($500) to discourage

**Prevention:** Make region choice very obvious during signup

---

## Future Enhancements

### Phase 2 (6-12 Months)
- **Custom Regions:** Azure Government Cloud for US federal customers
- **Multi-Region Redundancy:** Automatic failover to secondary region
- **Cross-Region Reporting:** Aggregated reporting across multiple namespaces in different regions

### Phase 3 (12-24 Months)
- **Regional Compliance Packs:** Pre-configured compliance templates by region
  - Canada: PIPEDA compliance checklist
  - US: FedRAMP compliance checklist
  - EU: GDPR compliance checklist

---

## Dependencies

**Blocks:**
- US market expansion (enables "yes" to data residency question)
- EU market expansion
- Government RFP responses (can now answer "yes" to Canadian data residency)

**Blocked By:**
- None (can implement independently)

**Parallel Work:**
- Privacy Policy update (mentions multi-region capability)
- Website update (markets multi-region)
- SOC2 preparation (easier with clear data boundaries)

---

## Appendix: Region Selection UI Mockup

```
┌─────────────────────────────────────────────────┐
│  Create Your Organization                       │
├─────────────────────────────────────────────────┤
│                                                  │
│  Organization Name *                             │
│  ┌─────────────────────────────────────────┐   │
│  │ My Company                               │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
│  Data Residency Region *                         │
│  ┌─────────────────────────────────────────┐   │
│  │ Canada (Montreal, Quebec)            ▼  │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
│  ✓ Recommended for Canadian organizations       │
│  ✓ PIPEDA and FOIP compliant                    │
│  ✓ Your data stays in Canada                    │
│                                                  │
│  ⚠️ This choice is permanent and cannot be      │
│     changed after your organization is created. │
│                                                  │
│  Available regions:                              │
│  • Canada: Montreal, Quebec                      │
│  • United States: Virginia (on request)          │
│  • European Union: Ireland (on request)          │
│                                                  │
│  Need a different region? Contact us:           │
│  sales@getinsync.ca                              │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │        Create Organization               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-07 | Initial work package from Q1 2026 planning session. Option C (Hybrid) selected. |

---

*Document: planning/work-package-multi-region.md*  
*February 2026*
