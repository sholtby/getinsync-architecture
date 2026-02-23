# 15b: Free Tier Update (2 Workspaces)

## Overview

Update the Free tier to allow **2 workspaces** (previously 1). This lets users experience the multi-workspace concept and see how data isolation works, which teases the publishing features in GetInSync Full.

---

## Changes Required

### Update Tier Limits

Find the tier configuration (likely in `tiers.ts` or similar) and update:

```typescript
export const TIER_LIMITS = {
  free: {
    workspaces: 2,        // â† Changed from 1 to 2
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
    workspaces: 999,      // Effectively unlimited
    portfoliosPerWorkspace: 999,
    applicationsPerWorkspace: 999,
    users: 999,
    csvImportRows: 999,
    deploymentProfilesPerApp: 999,
  },
};
```

### Add Feature Flags

Add a feature flags object to track what each tier can do:

```typescript
export const TIER_FEATURES = {
  free: {
    editDeploymentProfile: false,
    editAssessmentConfig: false,
    addAssessmentFactors: false,
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
    editDeploymentProfile: true,       // â† Unlocked
    editAssessmentConfig: true,        // â† Unlocked
    addAssessmentFactors: false,
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
  enterprise: {
    editDeploymentProfile: true,
    editAssessmentConfig: true,
    addAssessmentFactors: true,        // â† Unlocked
    multipleDeploymentProfiles: true,  // â† Unlocked
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
  full: {
    // All features enabled
    editDeploymentProfile: true,
    editAssessmentConfig: true,
    addAssessmentFactors: true,
    multipleDeploymentProfiles: true,
    publishToNamespace: true,
    itServiceCatalog: true,
    softwareProductCatalog: true,
    involvedParties: true,
    integrations: true,
    dataAssets: true,
    compliance: true,
    documents: true,
    roadmap: true,
    assessmentHistory: true,
    workflows: true,
    notifications: true,
    scheduledReports: true,
    apiAccess: true,
    customFields: true,
    nestedPortfolios: true,
    annualCost: true,
    environmentDetails: true,
  },
};
```

---

## Update useTierLimits Hook

Update the hook to expose both limits and features:

```typescript
export function useTierLimits() {
  const { profile } = useAuth();
  const [namespace, setNamespace] = useState<any>(null);

  useEffect(() => {
    // Fetch namespace to get tier
    async function fetchNamespace() {
      if (!profile?.namespace_id) return;
      const { data } = await supabase
        .from('namespaces')
        .select('tier')
        .eq('id', profile.namespace_id)
        .single();
      setNamespace(data);
    }
    fetchNamespace();
  }, [profile?.namespace_id]);

  const tier = (namespace?.tier || 'free') as keyof typeof TIER_LIMITS;
  const limits = TIER_LIMITS[tier];
  const features = TIER_FEATURES[tier];

  return {
    tier,
    limits,
    features,
    
    // Helper functions
    canCreate: (resource: string, currentCount: number) => {
      const limit = limits[resource as keyof typeof limits];
      return typeof limit === 'number' ? currentCount < limit : true;
    },
    
    isAtLimit: (resource: string, currentCount: number) => {
      const limit = limits[resource as keyof typeof limits];
      return typeof limit === 'number' ? currentCount >= limit : false;
    },
    
    hasFeature: (feature: keyof typeof TIER_FEATURES['free']) => {
      return features[feature] === true;
    },
  };
}
```

---

## Update UI Copy

### Upgrade Modal - Free Tier

When Free tier hits workspace limit (now 2):

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Upgrade to Pro                                             âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ ðŸš€ You've reached the free tier limit                           â”‚
â”‚                                                                 â”‚
â”‚ Free tier includes:                                             â”‚
â”‚ â€¢ 2 workspaces (2/2 used)                                       â”‚
â”‚ â€¢ 20 applications per workspace                                 â”‚
â”‚ â€¢ 3 portfolios per workspace                                    â”‚
â”‚ â€¢ 3 users                                                       â”‚
â”‚                                                                 â”‚
â”‚ Upgrade to Pro for:                                             â”‚
â”‚ â€¢ 5 workspaces                                                  â”‚
â”‚ â€¢ 100 applications per workspace                                â”‚
â”‚ â€¢ 10 portfolios per workspace                                   â”‚
â”‚ â€¢ 20 users                                                      â”‚
â”‚ â€¢ Edit deployment profiles                                      â”‚
â”‚ â€¢ Customize assessment factors                                  â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐           â”‚
â”‚              â”‚ Maybe Later â”‚ â”‚ Upgrade to Pro       â”‚           â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Why 2 Workspaces?

With 2 workspaces, free tier users can:

1. **Create two separate departments** (e.g., "IT" and "Finance")
2. **See the workspace switcher** in action
3. **Understand data isolation** between workspaces
4. **Notice the locked "Publish to Namespace"** option and wonder "Can I share between these?"
5. **Experience the value** before hitting limits

This creates a natural upgrade path when they want:
- More workspaces (Pro: 5)
- Cross-workspace sharing (Full)

---

## Verification

1. Create a Free tier account
2. Verify can create 2 workspaces (not just 1)
3. Try to create a 3rd workspace â†’ should show upgrade modal
4. Check upgrade modal shows "2/2 workspaces used"
