# Data Model Changes

> **Note:** This document describes the v1.2 data model BEFORE the Application Pool / Portfolio Assignment refactor. See `07-application-pool-portfolio-model.md` for the target architecture where assessment scores move from Application to Portfolio Assignment.

## Summary

New fields required on the Application entity. All score fields change from decimal (1-5) to integer (0-100).

## Schema Changes

### Application Entity

#### New Fields
```typescript
// Add to Application
remediationEffort: 'XS' | 'S' | 'M' | 'L' | 'XL' | '2XL' | null;
lifecycleStatus: 'Mainstream' | 'Extended' | 'End of Support';
assessmentStatus: 'Not Started' | 'In Progress' | 'Complete';
```

#### Score Field Type Changes
```typescript
// Before (v1.1) - Decimal 1-5
businessFit: number;      // e.g., 3.75
techHealth: number;       // e.g., 4.20
criticality: number;      // e.g., 2.85
technicalRisk: number;    // e.g., 3.10

// After (v1.2) - Integer 0-100
businessFit: number;      // e.g., 69
techHealth: number;       // e.g., 80
criticality: number;      // e.g., 46
technicalRisk: number;    // e.g., 53
```

## Database Migration

### SQL (if applicable)
```sql
-- Add remediation effort column
ALTER TABLE Application 
ADD COLUMN remediation_effort VARCHAR(3) NULL;

-- Add constraint for valid values
ALTER TABLE Application
ADD CONSTRAINT chk_remediation_effort 
CHECK (remediation_effort IN ('XS', 'S', 'M', 'L', 'XL', '2XL') OR remediation_effort IS NULL);

-- Note: Score columns don't need schema change if stored as numeric
-- The change is in calculation, not storage type
```

### Prisma Schema (if using Prisma)
```prisma
model Application {
  // ... existing fields ...
  
  remediationEffort String? @map("remediation_effort")
  
  // Score fields remain as Float or Int
  businessFit       Float?
  techHealth        Float?
  criticality       Float?
  technicalRisk     Float?
}
```

## Computed/Derived Fields

These fields should be computed, not stored:

```typescript
interface ApplicationWithDerived extends Application {
  // Derived from remediationEffort
  remediationBubbleSize: number | null;  // 8, 18, 32, 50, 72, 100 (visual scaling)
  remediationLabel: string;              // "Extra Large ($500K - $1M)"
  
  // Derived from scores
  timeQuadrant: 'Invest' | 'Tolerate' | 'Migrate' | 'Eliminate';
  paidAction: 'Address' | 'Plan' | 'Delay' | 'Ignore';
}
```

## API Response Changes

### GET /applications/:id

#### Before (v1.1)
```json
{
  "id": "app-123",
  "name": "Payment Portal",
  "businessFit": 3.75,
  "techHealth": 2.10,
  "criticality": 4.20,
  "technicalRisk": 3.85,
  "annualCost": 450000,
  "timeQuadrant": "Migrate",
  "paidAction": "Address"
}
```

#### After (v1.2)
```json
{
  "id": "app-123",
  "name": "Payment Portal",
  "businessFit": 69,
  "techHealth": 28,
  "criticality": 80,
  "technicalRisk": 71,
  "annualCost": 450000,
  "remediationEffort": "XL",
  "remediationBubbleSize": 80,
  "remediationLabel": "Extra Large ($500K - $1M)",
  "timeQuadrant": "Migrate",
  "paidAction": "Address"
}
```

## Type Definitions

### Complete Application Type (v1.2)
```typescript
type TShirtSize = 'XS' | 'S' | 'M' | 'L' | 'XL' | '2XL';
type TIMEQuadrant = 'Invest' | 'Tolerate' | 'Migrate' | 'Eliminate';
type PAIDAction = 'Address' | 'Plan' | 'Delay' | 'Ignore';
type LifecycleStatus = 'Mainstream' | 'Extended' | 'End of Support';
type AssessmentStatus = 'Not Started' | 'In Progress' | 'Complete';

interface Application {
  id: string;
  name: string;
  workspaceId: string;
  
  // Factor scores (raw 1-5, stored)
  factors: {
    b1?: number;
    b2?: number;
    // ... b3-b10, t01-t15 (no t12)
  };
  
  // Composite scores (0-100, computed)
  businessFit: number;
  techHealth: number;
  criticality: number;
  technicalRisk: number;
  
  // Quadrant assignments (computed)
  timeQuadrant: TIMEQuadrant;
  paidAction: PAIDAction;
  
  // Cost data
  annualCost: number;
  
  // Lifecycle (new in v1.2)
  lifecycleStatus: LifecycleStatus;
  
  // Assessment tracking (new in v1.2)
  assessmentStatus: AssessmentStatus;
  
  // Remediation (new in v1.2)
  remediationEffort: TShirtSize | null;
  remediationBubbleSize: number | null;  // derived: 8, 18, 32, 50, 72, 100
  remediationLabel: string;               // derived
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
}
```

## Data Migration for Existing Records

If you have existing applications with 1-5 scores, migrate them:

```javascript
// Migration script
async function migrateScoresTo100Scale() {
  const apps = await db.application.findMany();
  
  for (const app of apps) {
    await db.application.update({
      where: { id: app.id },
      data: {
        businessFit: normalizeScore(app.businessFit),
        techHealth: normalizeScore(app.techHealth),
        criticality: normalizeScore(app.criticality),
        technicalRisk: normalizeScore(app.technicalRisk),
        // remediationEffort defaults to null (needs manual entry)
      }
    });
  }
}

function normalizeScore(score) {
  if (score === null || score === undefined) return null;
  return Math.round(((score - 1) / 4) * 100);
}
```

## Validation Rules

```typescript
const applicationValidation = {
  remediationEffort: {
    type: 'enum',
    values: ['XS', 'S', 'M', 'L', 'XL', '2XL'],
    nullable: true
  },
  businessFit: {
    type: 'integer',
    min: 0,
    max: 100
  },
  techHealth: {
    type: 'integer',
    min: 0,
    max: 100
  },
  criticality: {
    type: 'integer',
    min: 0,
    max: 100
  },
  technicalRisk: {
    type: 'integer',
    min: 0,
    max: 100
  }
};
```
