# Remediation T-Shirt Sizing

## What Changed

The PAID bubble chart now uses **T-shirt sizes** for remediation effort instead of AnnualCost.

## Why

- AnnualCost = what you're spending to **run** the app
- RemediationEffort = what it costs to **fix** the tech debt
- T-shirt sizes avoid false precision in estimates
- Universal language for business and technology teams

## T-Shirt Size Definitions

| Size | Code | Bubble Size | Default Cost Range | Description |
|------|------|-------------|-------------------|-------------|
| XS | `XS` | 1 | < $25K | Minor fix; internal effort only |
| S | `S` | 5 | $25K - $100K | Small project; single team |
| M | `M` | 15 | $100K - $250K | Medium project; cross-team |
| L | `L` | 40 | $250K - $500K | Large project; significant |
| XL | `XL` | 80 | $500K - $1M | Major initiative |
| 2XL | `2XL` | 150 | > $1M | Multi-year program |

**Note:** Cost ranges are examples. Each organization defines their own thresholds.

## Data Model Changes

### Add to Application Entity
```typescript
interface Application {
  // ... existing fields ...
  
  // NEW: Remediation effort estimate
  remediationEffort: 'XS' | 'S' | 'M' | 'L' | 'XL' | '2XL' | null;
}
```

### Derived Field for Charting
```typescript
function getRemediationBubbleSize(effort: string | null): number | null {
  const sizeMap = {
    'XS': 1,
    'S': 5,
    'M': 15,
    'L': 40,
    'XL': 80,
    '2XL': 150
  };
  return effort ? sizeMap[effort] : null;
}
```

## UI Components

### T-Shirt Size Selector
```jsx
const TSHIRT_OPTIONS = [
  { value: 'XS', label: 'XS - Extra Small', description: 'Minor fix (< $25K)' },
  { value: 'S', label: 'S - Small', description: 'Small project ($25K-$100K)' },
  { value: 'M', label: 'M - Medium', description: 'Medium project ($100K-$250K)' },
  { value: 'L', label: 'L - Large', description: 'Large project ($250K-$500K)' },
  { value: 'XL', label: 'XL - Extra Large', description: 'Major initiative ($500K-$1M)' },
  { value: '2XL', label: '2XL - Program', description: 'Multi-year program (> $1M)' }
];

function RemediationEffortSelector({ value, onChange }) {
  return (
    <select value={value || ''} onChange={(e) => onChange(e.target.value || null)}>
      <option value="">Not Estimated</option>
      {TSHIRT_OPTIONS.map(opt => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}
```

### Display Label
```javascript
function getRemediationLabel(effort) {
  const labels = {
    'XS': 'Extra Small (< $25K)',
    'S': 'Small ($25K - $100K)',
    'M': 'Medium ($100K - $250K)',
    'L': 'Large ($250K - $500K)',
    'XL': 'Extra Large ($500K - $1M)',
    '2XL': 'Program (> $1M)'
  };
  return labels[effort] || 'Not Estimated';
}
```

## PAID Bubble Chart Changes

### Before (v1.1)
```javascript
// Bubble size from AnnualCost
const bubbleSize = app.annualCost / 10000; // Scale dollars to pixels
```

### After (v1.2)
```javascript
// Bubble size from T-shirt
const bubbleSize = getRemediationBubbleSize(app.remediationEffort);
// Returns: 1, 5, 15, 40, 80, or 150
```

### Chart Configuration
```javascript
const paidChartConfig = {
  xAxis: {
    field: 'technicalRisk',
    label: 'Technical Risk',
    min: 0,
    max: 100,
    referenceLine: 50
  },
  yAxis: {
    field: 'criticality',
    label: 'Business Impact (Criticality)',
    min: 0,
    max: 100,
    referenceLine: 50
  },
  bubbleSize: {
    field: 'remediationBubbleSize',  // CHANGED from annualCost
    // No additional scaling needed - values are already sized
  },
  color: {
    field: 'paidAction',
    colors: {
      'Address': '#C62828',
      'Plan': '#1565C0',
      'Delay': '#F9A825',
      'Ignore': '#808080'
    }
  }
};
```

## Bubble Size Legend

Add a legend showing T-shirt size to bubble mapping:

```jsx
function BubbleSizeLegend() {
  const sizes = [
    { label: 'XS', size: 1 },
    { label: 'S', size: 5 },
    { label: 'M', size: 15 },
    { label: 'L', size: 40 },
    { label: 'XL', size: 80 },
    { label: '2XL', size: 150 }
  ];
  
  return (
    <div className="bubble-legend">
      <span>Remediation Effort:</span>
      {sizes.map(({ label, size }) => (
        <div key={label} className="legend-item">
          <svg width={Math.sqrt(size) * 4} height={Math.sqrt(size) * 4}>
            <circle 
              cx={Math.sqrt(size) * 2} 
              cy={Math.sqrt(size) * 2} 
              r={Math.sqrt(size) * 2} 
              fill="#666" 
              opacity={0.5}
            />
          </svg>
          <span>{label}</span>
        </div>
      ))}
    </div>
  );
}
```

## Tooltip Update

### Before
```
Annual Cost: $450,000
```

### After
```
Remediation Effort: XL
Est. Cost: Extra Large ($500K - $1M)
```

## TIME Chart (Unchanged for Bubble)

The TIME chart bubble size still uses **Criticality** (0-100), not T-shirt sizing.

| Chart | Bubble Size Field |
|-------|------------------|
| TIME | Criticality (0-100) |
| PAID | RemediationBubbleSize (1/5/15/40/80/150) |

## Validation

After implementing, verify:
- [ ] T-shirt selector appears on application edit form
- [ ] PAID chart bubbles scale correctly (2XL = largest, XS = smallest)
- [ ] Tooltip shows T-shirt size and cost range
- [ ] TIME chart still uses Criticality for bubble size
- [ ] Applications without RemediationEffort show no bubble (or default size)
