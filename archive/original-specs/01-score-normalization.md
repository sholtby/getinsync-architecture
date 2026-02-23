# Score Normalization: 1-5 â†’ 0-100

## What Changed

All composite scores (BusinessFit, TechHealth, Criticality, TechnicalRisk) now use a **0-100 scale** instead of 1-5.

## Why

- More intuitive for stakeholders ("75% healthy" vs "3.75 out of 5")
- Threshold becomes 50 (clean midpoint)
- Matches Excel-based APM tools stakeholders may be familiar with

## Normalization Formula

```
NormalizedScore = ((WeightedAverage - 1) / 4) Ã— 100
```

### Conversion Table

| Factor Score (1-5) | Normalized (0-100) |
|--------------------|-------------------|
| 1 | 0 |
| 2 | 25 |
| 3 | 50 |
| 4 | 75 |
| 5 | 100 |

## Code Changes Required

### Before (v1.1)
```javascript
// Calculate Business Fit (1-5 scale)
const businessFit = 
  (b1 * 0.15) + (b2 * 0.15) + (b3 * 0.05) + (b4 * 0.15) +
  (b5 * 0.15) + (b8 * 0.10) + (b9 * 0.15) + (b10 * 0.10);

// Result: 1.0 - 5.0
```

### After (v1.2)
```javascript
// Calculate Business Fit (0-100 scale)
const rawScore = 
  (b1 * 0.15) + (b2 * 0.15) + (b3 * 0.05) + (b4 * 0.15) +
  (b5 * 0.15) + (b8 * 0.10) + (b9 * 0.15) + (b10 * 0.10);

const businessFit = Math.round(((rawScore - 1) / 4) * 100);

// Result: 0 - 100
```

### Helper Function
```javascript
/**
 * Normalize a weighted average from 1-5 scale to 0-100 scale
 * @param {number} rawScore - Weighted average on 1-5 scale
 * @returns {number} - Normalized score on 0-100 scale
 */
function normalizeScore(rawScore) {
  return Math.round(((rawScore - 1) / 4) * 100);
}
```

## All Scores to Normalize

Apply the normalization formula to these composite scores:

| Score | Formula (weights unchanged) | Output |
|-------|----------------------------|--------|
| BusinessFit | B1-B5, B8-B10 weighted | 0-100 |
| TechHealth | T01-T15 weighted (no T12) | 0-100 |
| Criticality | B1-B7 weighted | 0-100 |
| TechnicalRisk | T02-T05, T11 weighted | 0-100 |

## Display Changes

### Score Display
```javascript
// Before
<span>{score.toFixed(1)}</span>  // "3.5"

// After
<span>{score}%</span>  // "63%"
// or
<span>{score}</span>   // "63"
```

### Score Interpretation Labels
```javascript
function getScoreLabel(score) {
  if (score >= 75) return 'Excellent';
  if (score >= 63) return 'Good';
  if (score >= 50) return 'Average';
  if (score >= 25) return 'Below Average';
  return 'Critical';
}
```

## Validation

After implementing, verify:
- [ ] A factor score of 3 across all factors produces a composite score of 50
- [ ] A factor score of 5 across all factors produces a composite score of 100
- [ ] A factor score of 1 across all factors produces a composite score of 0
- [ ] Mixed scores produce values between 0-100
