# 15d: In-Context Teaser UI Components

## Overview

Add teaser sections throughout the UI that show locked features **where they would be used**. This creates discovery moments for "Architecture Curious" users without cluttering the experience for "Just Assess" users.

**Design principles:**
- Teasers are subtle, not intrusive
- Collapsed by default where possible
- Show value proposition, not just "locked"
- Clear upgrade path

---

## Reusable Teaser Component

Create a reusable teaser component:

```tsx
// src/components/FeatureTeaser.tsx

import { Lock } from 'lucide-react';

interface FeatureTeaserProps {
  title: string;
  description?: string;
  tier: 'pro' | 'enterprise' | 'full';
  variant?: 'card' | 'inline' | 'ghost';
  onUpgrade?: () => void;
}

export function FeatureTeaser({ 
  title, 
  description, 
  tier, 
  variant = 'card',
  onUpgrade 
}: FeatureTeaserProps) {
  const tierLabels = {
    pro: 'Pro',
    enterprise: 'Enterprise', 
    full: 'GetInSync Full'
  };

  if (variant === 'inline') {
    return (
      <div className="flex items-center gap-2 text-gray-400 py-2">
        <Lock className="w-4 h-4" />
        <span className="text-sm">{title}</span>
        <span className="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded">
          {tierLabels[tier]}
        </span>
      </div>
    );
  }

  if (variant === 'ghost') {
    return (
      <div className="border-2 border-dashed border-gray-200 rounded-lg p-4 text-center">
        <Lock className="w-5 h-5 text-gray-300 mx-auto mb-2" />
        <p className="text-sm text-gray-400">{title}</p>
        <p className="text-xs text-gray-400 mt-1">
          Upgrade to {tierLabels[tier]}
        </p>
        {onUpgrade && (
          <button 
            onClick={onUpgrade}
            className="mt-2 text-xs text-teal-600 hover:underline"
          >
            Learn More â†’
          </button>
        )}
      </div>
    );
  }

  // Default: card variant
  return (
    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
      <div className="flex items-start gap-3">
        <div className="p-2 bg-gray-100 rounded-lg">
          <Lock className="w-4 h-4 text-gray-400" />
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="font-medium text-gray-700">{title}</span>
            <span className="text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded">
              {tierLabels[tier]}
            </span>
          </div>
          {description && (
            <p className="text-sm text-gray-500 mt-1">{description}</p>
          )}
          {onUpgrade && (
            <button 
              onClick={onUpgrade}
              className="mt-2 text-sm text-teal-600 hover:underline"
            >
              Upgrade to {tierLabels[tier]} â†’
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## Application Detail Teasers

Add these teasers at the bottom of the Application form or detail view:

```tsx
// src/components/ApplicationDetailTeasers.tsx

import { FeatureTeaser } from './FeatureTeaser';
import { useTierLimits } from '../hooks/useTierLimits';

export function ApplicationDetailTeasers() {
  const { hasFeature } = useTierLimits();

  // Don't show if user has Full tier
  if (hasFeature('involvedParties')) return null;

  return (
    <div className="space-y-3 mt-6 pt-6 border-t">
      <p className="text-sm text-gray-500 font-medium">
        Additional capabilities in GetInSync Full:
      </p>
      
      <FeatureTeaser
        title="Involved Parties"
        description="Track stakeholders, SMEs, vendors, and partners"
        tier="full"
        variant="inline"
      />
      
      <FeatureTeaser
        title="Integrations"
        description="Map upstream and downstream dependencies"
        tier="full"
        variant="inline"
      />
      
      <FeatureTeaser
        title="Data Assets"
        description="Catalog data with classification and retention"
        tier="full"
        variant="inline"
      />
      
      <FeatureTeaser
        title="Compliance"
        description="Track regulatory requirements and audit status"
        tier="full"
        variant="inline"
      />
      
      <FeatureTeaser
        title="Documents"
        description="Attach architecture diagrams, SLAs, contracts"
        tier="full"
        variant="inline"
      />
      
      <FeatureTeaser
        title="Roadmap"
        description="Plan migrations, upgrades, decommissions"
        tier="full"
        variant="inline"
      />
    </div>
  );
}
```

---

## Settings Menu with Locked Items

Update the Settings navigation to show locked items:

```tsx
// In SettingsLayout.tsx

const lockedItems = [
  { name: 'Workspace Groups', feature: 'publishToNamespace' },
  { name: 'IT Service Catalog', feature: 'itServiceCatalog' },
  { name: 'Software Products', feature: 'softwareProductCatalog' },
  { name: 'Custom Fields', feature: 'customFields' },
  { name: 'Workflows', feature: 'workflows' },
  { name: 'Notifications', feature: 'notifications' },
  { name: 'API Access', feature: 'apiAccess' },
];

// In the nav render:
{/* Divider */}
<li className="py-2">
  <div className="border-t border-gray-200" />
</li>

{/* Locked items */}
{lockedItems.map((item) => (
  <li key={item.feature}>
    <div className="flex items-center gap-2 px-3 py-2 text-gray-400 cursor-not-allowed">
      <Lock className="w-4 h-4" />
      <span>{item.name}</span>
      <span className="text-xs bg-gray-100 px-1.5 py-0.5 rounded text-gray-500">
        Full
      </span>
    </div>
  </li>
))}
```

**Rendered:**

```
Settings
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Organization
Workspaces
Users
Assessment Configuration
Workspace Settings
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ðŸ”’ Workspace Groups         [Full]
ðŸ”’ IT Service Catalog       [Full]
ðŸ”’ Software Products        [Full]
ðŸ”’ Custom Fields            [Full]
ðŸ”’ Workflows                [Full]
ðŸ”’ Notifications            [Full]
ðŸ”’ API Access               [Full]
```

---

## Dashboard Enterprise Features Card

Add a dismissible teaser card to the dashboard:

```tsx
// src/components/EnterpriseFeaturesTeaser.tsx

import { Lock, ArrowRight, X } from 'lucide-react';
import { useState } from 'react';

export function EnterpriseFeaturesTeaser() {
  const [dismissed, setDismissed] = useState(
    localStorage.getItem('enterprise-teaser-dismissed') === 'true'
  );

  if (dismissed) return null;

  const handleDismiss = () => {
    localStorage.setItem('enterprise-teaser-dismissed', 'true');
    setDismissed(true);
  };

  return (
    <div className="bg-gradient-to-r from-gray-50 to-gray-100 border border-gray-200 rounded-lg p-6 mt-6 relative">
      <button 
        onClick={handleDismiss}
        className="absolute top-3 right-3 text-gray-400 hover:text-gray-600"
      >
        <X className="w-4 h-4" />
      </button>
      
      <div className="flex items-start gap-4">
        <div className="p-3 bg-white rounded-lg shadow-sm">
          <Lock className="w-6 h-6 text-teal-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-gray-900">
            Unlock Enterprise Features
          </h3>
          <p className="text-sm text-gray-600 mt-1">
            GetInSync Full includes powerful capabilities for enterprise APM:
          </p>
          <ul className="mt-3 grid grid-cols-2 gap-2 text-sm text-gray-600">
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              Publish apps across workspaces
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              IT Service Catalog
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              Software Product Catalog
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              Cost derivation & analysis
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              Workflows & approvals
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 bg-teal-500 rounded-full" />
              API access
            </li>
          </ul>
          <button className="mt-4 inline-flex items-center gap-2 text-sm font-medium text-teal-600 hover:text-teal-700">
            Contact Sales
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## Teaser Placement Summary

| Location | Teaser Content | Unlock Tier |
|----------|----------------|-------------|
| Deployment Profile - fields | "Upgrade to Pro to edit" | Pro |
| Deployment Profile - add more | "Upgrade to Enterprise for multiple profiles" | Enterprise |
| Deployment Profile - details | "Environment Details available in Full" | Full |
| Application form - bottom | Involved Parties, Integrations, Data Assets, Compliance, Documents, Roadmap | Full |
| Settings menu | Workspace Groups, IT Service Catalog, Software Products, Custom Fields, Workflows, Notifications, API Access | Full |
| Dashboard - bottom | Enterprise Features card (dismissible) | Full |
| Workspace header | "Share across workspaces with Full" | Full |
| Assessment modal - after save | "Track history with Full" | Full |

---

## Progressive Disclosure Principle

**"Just Assess" users see:**
- Clean core UI
- Deployment Profile section (collapsed)
- Nothing else intrusive

**"Architecture Curious" users discover:**
- Expand Deployment Profile â†’ see tier-specific teasers
- Scroll to bottom â†’ see locked features list
- Go to Settings â†’ see locked menu items
- Dashboard card â†’ can dismiss if not interested

This keeps the fast path clean while rewarding exploration.
