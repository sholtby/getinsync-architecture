# Multi-Tenant Phase 5: Tier Limits Enforcement

## Overview

Enforce free/pro/enterprise tier limits throughout the application with friendly upgrade prompts.

**Prerequisites:** Phases 1-4 must be complete.

**Goal:** Users on free tier hit limits gracefully with clear upgrade paths.

---

## Tier Limits Summary

| Resource | Free | Pro | Enterprise |
|----------|------|-----|------------|
| Workspaces | 1 | 5 | Unlimited |
| Portfolios per Workspace | 3 | 10 | Unlimited |
| Applications per Workspace | 20 | 100 | Unlimited |
| Users | 3 | 20 | Unlimited |
| CSV Import rows | 20 | 100 | Unlimited |

---

## Tier Configuration

Create a centralized tier configuration:

```typescript
// src/config/tiers.ts

export interface TierLimits {
  workspaces: number;
  portfoliosPerWorkspace: number;
  applicationsPerWorkspace: number;
  users: number;
  csvImportRows: number;
}

export const TIER_LIMITS: Record<string, TierLimits> = {
  free: {
    workspaces: 1,
    portfoliosPerWorkspace: 3,
    applicationsPerWorkspace: 20,
    users: 3,
    csvImportRows: 20,
  },
  pro: {
    workspaces: 5,
    portfoliosPerWorkspace: 10,
    applicationsPerWorkspace: 100,
    users: 20,
    csvImportRows: 100,
  },
  enterprise: {
    workspaces: Infinity,
    portfoliosPerWorkspace: Infinity,
    applicationsPerWorkspace: Infinity,
    users: Infinity,
    csvImportRows: Infinity,
  },
};

export const TIER_PRICING = {
  pro: {
    monthly: 29,
    yearly: 290,
  },
  enterprise: {
    monthly: 99,
    yearly: 990,
  },
};

export const TIER_FEATURES = {
  free: [
    '1 workspace',
    '3 portfolios',
    '20 applications',
    '3 team members',
    'TIME/PAID assessment',
    'CSV import (20 rows)',
    'Basic reporting',
  ],
  pro: [
    '5 workspaces',
    '10 portfolios per workspace',
    '100 applications per workspace',
    '20 team members',
    'Everything in Free',
    'CSV import (100 rows)',
    'Priority support',
  ],
  enterprise: [
    'Unlimited workspaces',
    'Unlimited portfolios',
    'Unlimited applications',
    'Unlimited team members',
    'Everything in Pro',
    'SSO/SAML integration',
    'Dedicated support',
    'Custom branding',
  ],
};
```

---

## Tier Context Hook

```typescript
// src/hooks/useTierLimits.ts

import { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import { TIER_LIMITS, TierLimits } from '../config/tiers';

interface UsageStats {
  workspaces: number;
  portfolios: number;
  applications: number;
  users: number;
}

export function useTierLimits() {
  const { profile, currentWorkspace } = useAuth();
  const [tier, setTier] = useState('free');
  const [usage, setUsage] = useState<UsageStats>({
    workspaces: 0,
    portfolios: 0,
    applications: 0,
    users: 0,
  });

  useEffect(() => {
    if (!profile) return;

    async function fetchUsage() {
      const { data: namespace } = await supabase
        .from('namespaces')
        .select('tier')
        .eq('id', profile.namespace_id)
        .single();

      setTier(namespace?.tier || 'free');

      const { count: workspaceCount } = await supabase
        .from('workspaces')
        .select('*', { count: 'exact', head: true })
        .eq('namespace_id', profile.namespace_id);

      const { count: userCount } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('namespace_id', profile.namespace_id);

      const { count: portfolioCount } = await supabase
        .from('portfolios')
        .select('*', { count: 'exact', head: true })
        .eq('workspace_id', currentWorkspace?.id);

      const { count: applicationCount } = await supabase
        .from('applications')
        .select('*', { count: 'exact', head: true })
        .eq('workspace_id', currentWorkspace?.id);

      setUsage({
        workspaces: workspaceCount || 0,
        portfolios: portfolioCount || 0,
        applications: applicationCount || 0,
        users: userCount || 0,
      });
    }

    fetchUsage();
  }, [profile, currentWorkspace]);

  const limits = TIER_LIMITS[tier] || TIER_LIMITS.free;

  const canCreateApplication = usage.applications < limits.applicationsPerWorkspace;
  const canCreatePortfolio = usage.portfolios < limits.portfoliosPerWorkspace;
  const canCreateWorkspace = usage.workspaces < limits.workspaces;
  const canInviteUser = usage.users < limits.users;

  const getUsagePercent = (resource: keyof UsageStats): number => {
    const limitMap = {
      workspaces: limits.workspaces,
      portfolios: limits.portfoliosPerWorkspace,
      applications: limits.applicationsPerWorkspace,
      users: limits.users,
    };
    const limit = limitMap[resource];
    if (limit === Infinity) return 0;
    return Math.round((usage[resource] / limit) * 100);
  };

  const isApproachingLimit = (resource: keyof UsageStats): boolean => {
    return getUsagePercent(resource) >= 80;
  };

  return {
    tier,
    limits,
    usage,
    canCreateWorkspace,
    canCreatePortfolio,
    canCreateApplication,
    canInviteUser,
    isApproachingLimit,
    getUsagePercent,
  };
}
```

---

## Upgrade Modal Component

```tsx
// src/components/UpgradeModal.tsx

import { TIER_FEATURES, TIER_PRICING } from '../config/tiers';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  reason?: string;
}

export function UpgradeModal({ isOpen, onClose, reason }: Props) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl p-6">
        <div className="text-center mb-6">
          <div className="text-4xl mb-2">ðŸš€</div>
          <h2 className="text-2xl font-bold">Upgrade to unlock more</h2>
          {reason && <p className="text-gray-600 mt-2">{reason}</p>}
        </div>

        <div className="grid md:grid-cols-2 gap-4 mb-6">
          {/* Pro */}
          <div className="border-2 border-teal-500 rounded-lg p-6">
            <h3 className="text-xl font-bold text-center">Pro</h3>
            <div className="text-center mt-2">
              <span className="text-3xl font-bold">${TIER_PRICING.pro.monthly}</span>
              <span className="text-gray-500">/month</span>
            </div>
            <ul className="mt-4 space-y-2">
              {TIER_FEATURES.pro.slice(0, 5).map((f, i) => (
                <li key={i} className="flex items-start gap-2 text-sm">
                  <span className="text-teal-500">âœ“</span>{f}
                </li>
              ))}
            </ul>
            <button className="w-full mt-4 py-2 bg-teal-600 text-white rounded hover:bg-teal-700">
              Upgrade to Pro
            </button>
          </div>

          {/* Enterprise */}
          <div className="border rounded-lg p-6">
            <h3 className="text-xl font-bold text-center">Enterprise</h3>
            <div className="text-center mt-2">
              <span className="text-3xl font-bold">${TIER_PRICING.enterprise.monthly}</span>
              <span className="text-gray-500">/month</span>
            </div>
            <ul className="mt-4 space-y-2">
              {TIER_FEATURES.enterprise.slice(0, 5).map((f, i) => (
                <li key={i} className="flex items-start gap-2 text-sm">
                  <span className="text-teal-500">âœ“</span>{f}
                </li>
              ))}
            </ul>
            <button className="w-full mt-4 py-2 border rounded hover:bg-gray-50">
              Contact Sales
            </button>
          </div>
        </div>

        <div className="text-center">
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            Maybe later
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## Enforce Limits in UI

### Example: Create Application Button

```tsx
function AddApplicationButton() {
  const { canCreateApplication, limits } = useTierLimits();
  const [showUpgrade, setShowUpgrade] = useState(false);

  const handleClick = () => {
    if (!canCreateApplication) {
      setShowUpgrade(true);
      return;
    }
    setShowCreateModal(true);
  };

  return (
    <>
      <button onClick={handleClick} className="px-4 py-2 bg-teal-600 text-white rounded">
        + New Application
      </button>
      <UpgradeModal
        isOpen={showUpgrade}
        onClose={() => setShowUpgrade(false)}
        reason={`You've reached the limit of ${limits.applicationsPerWorkspace} applications.`}
      />
    </>
  );
}
```

---

## Database-Level Enforcement

```sql
-- Trigger to enforce application limit
CREATE OR REPLACE FUNCTION check_application_limit()
RETURNS TRIGGER AS $$
DECLARE
  ws_namespace_id UUID;
  ns_tier VARCHAR;
  current_count INTEGER;
  max_allowed INTEGER;
BEGIN
  SELECT namespace_id INTO ws_namespace_id
  FROM workspaces WHERE id = NEW.workspace_id;

  SELECT tier INTO ns_tier
  FROM namespaces WHERE id = ws_namespace_id;

  SELECT COUNT(*) INTO current_count
  FROM applications WHERE workspace_id = NEW.workspace_id;

  max_allowed := CASE ns_tier
    WHEN 'free' THEN 20
    WHEN 'pro' THEN 100
    ELSE 999999
  END;

  IF current_count >= max_allowed THEN
    RAISE EXCEPTION 'Application limit reached. Please upgrade.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_application_limit
  BEFORE INSERT ON applications
  FOR EACH ROW EXECUTE FUNCTION check_application_limit();

-- Similar for portfolios
CREATE OR REPLACE FUNCTION check_portfolio_limit()
RETURNS TRIGGER AS $$
DECLARE
  ws_namespace_id UUID;
  ns_tier VARCHAR;
  current_count INTEGER;
  max_allowed INTEGER;
BEGIN
  SELECT namespace_id INTO ws_namespace_id
  FROM workspaces WHERE id = NEW.workspace_id;

  SELECT tier INTO ns_tier
  FROM namespaces WHERE id = ws_namespace_id;

  SELECT COUNT(*) INTO current_count
  FROM portfolios WHERE workspace_id = NEW.workspace_id;

  max_allowed := CASE ns_tier
    WHEN 'free' THEN 3
    WHEN 'pro' THEN 10
    ELSE 999999
  END;

  IF current_count >= max_allowed THEN
    RAISE EXCEPTION 'Portfolio limit reached. Please upgrade.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_portfolio_limit
  BEFORE INSERT ON portfolios
  FOR EACH ROW EXECUTE FUNCTION check_portfolio_limit();
```

---

## Usage Warning Banner

```tsx
// src/components/UsageWarningBanner.tsx

export function UsageWarningBanner() {
  const { tier, isApproachingLimit, usage, limits, getUsagePercent } = useTierLimits();

  if (tier === 'enterprise') return null;

  const warnings = [];
  if (isApproachingLimit('applications')) {
    warnings.push(`${usage.applications}/${limits.applicationsPerWorkspace} applications`);
  }
  if (isApproachingLimit('portfolios')) {
    warnings.push(`${usage.portfolios}/${limits.portfoliosPerWorkspace} portfolios`);
  }

  if (warnings.length === 0) return null;

  return (
    <div className="bg-amber-50 border-b border-amber-200 px-4 py-2">
      <div className="flex items-center justify-between">
        <span className="text-sm text-amber-800">
          âš ï¸ Approaching limits: {warnings.join(' Â· ')}
        </span>
        <a href="/pricing" className="text-sm text-amber-700 font-medium hover:underline">
          Upgrade â†’
        </a>
      </div>
    </div>
  );
}
```

---

## Verification

1. **Free tier limits enforced:**
   - Cannot create 4th portfolio â†’ Upgrade modal
   - Cannot create 21st application â†’ Upgrade modal
   - Cannot invite 4th user â†’ Upgrade modal

2. **Warning banners** appear at 80% usage

3. **Database triggers** catch any bypass attempts

4. **Upgrade flow** opens pricing/Stripe checkout

---

## All Phases Complete

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Database Schema | âœ… Ready |
| 2 | Authentication | âœ… Ready |
| 3 | Data Scoping | âœ… Ready |
| 4 | User Management | âœ… Ready |
| 5 | Tier Limits | âœ… Ready |

The application is now fully multi-tenant with Namespace/Workspace hierarchy, user authentication, data isolation, admin management, and freemium tier enforcement.
