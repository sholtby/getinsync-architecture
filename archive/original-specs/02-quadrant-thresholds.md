# Quadrant Thresholds: 3.0 â†’ 50

## What Changed

The threshold for TIME and PAID quadrant assignment changed from **3.0** to **50**.

## Why

With the 0-100 scale, the midpoint is 50 (equivalent to the old 3.0 on a 1-5 scale).

## TIME Quadrant Logic

### Before (v1.1)
```javascript
function getTIMEQuadrant(businessFit, techHealth) {
  if (techHealth >= 3.0 && businessFit >= 3.0) return 'Invest';
  if (techHealth >= 3.0 && businessFit < 3.0)  return 'Tolerate';
  if (techHealth < 3.0  && businessFit >= 3.0) return 'Migrate';
  return 'Eliminate';
}
```

### After (v1.2)
```javascript
const TIME_THRESHOLD = 50;

function getTIMEQuadrant(businessFit, techHealth) {
  if (techHealth >= TIME_THRESHOLD && businessFit >= TIME_THRESHOLD) return 'Invest';
  if (techHealth >= TIME_THRESHOLD && businessFit < TIME_THRESHOLD)  return 'Tolerate';
  if (techHealth < TIME_THRESHOLD  && businessFit >= TIME_THRESHOLD) return 'Migrate';
  return 'Eliminate';
}
```

## PAID Quadrant Logic

### Before (v1.1)
```javascript
function getPAIDAction(criticality, technicalRisk) {
  if (criticality >= 3.0 && technicalRisk >= 3.0) return 'Address';
  if (criticality >= 3.0 && technicalRisk < 3.0)  return 'Plan';
  if (criticality < 3.0  && technicalRisk >= 3.0) return 'Delay';
  return 'Ignore';
}
```

### After (v1.2)
```javascript
const PAID_THRESHOLD = 50;

function getPAIDAction(criticality, technicalRisk) {
  if (criticality >= PAID_THRESHOLD && technicalRisk >= PAID_THRESHOLD) return 'Address';
  if (criticality >= PAID_THRESHOLD && technicalRisk < PAID_THRESHOLD)  return 'Plan';
  if (criticality < PAID_THRESHOLD  && technicalRisk >= PAID_THRESHOLD) return 'Delay';
  return 'Ignore';
}
```

## Quadrant Grid Reference

### TIME (X: Business Fit, Y: Tech Health)
```
Tech Health
    â–²
100 â”‚  TOLERATE  â”‚   INVEST
    â”‚            â”‚
 50 â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    â”‚            â”‚
    â”‚  ELIMINATE â”‚   MIGRATE
  0 â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º
    0           50          100
                    Business Fit
```

### PAID (X: Technical Risk, Y: Criticality)
```
Criticality
    â–²
100 â”‚    PLAN    â”‚   ADDRESS
    â”‚            â”‚
 50 â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    â”‚            â”‚
    â”‚   IGNORE   â”‚    DELAY
  0 â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º
    0           50          100
                    Technical Risk
```

## Configurable Threshold (Optional)

If you want to support customer-configurable thresholds:

```javascript
// Default thresholds
const DEFAULT_TIME_THRESHOLD = 50;
const DEFAULT_PAID_THRESHOLD = 50;

// Get from organization settings (if available)
function getThreshold(type, orgSettings) {
  if (type === 'TIME') {
    return orgSettings?.timeThreshold ?? DEFAULT_TIME_THRESHOLD;
  }
  if (type === 'PAID') {
    return orgSettings?.paidThreshold ?? DEFAULT_PAID_THRESHOLD;
  }
  return 50;
}
```

## Quadrant Colors (Unchanged)

| TIME Quadrant | Color | Hex |
|---------------|-------|-----|
| Invest | Green | #2E7D32 |
| Tolerate | Gray | #808080 |
| Migrate | Orange | #F57C00 |
| Eliminate | Red | #C62828 |

| PAID Action | Color | Hex |
|-------------|-------|-----|
| Address | Red | #C62828 |
| Plan | Blue | #1565C0 |
| Delay | Yellow | #F9A825 |
| Ignore | Gray | #808080 |

## Validation

After implementing, verify:
- [ ] App with BusinessFit=50, TechHealth=50 â†’ Invest (boundary case)
- [ ] App with BusinessFit=49, TechHealth=50 â†’ Tolerate
- [ ] App with BusinessFit=50, TechHealth=49 â†’ Migrate
- [ ] App with BusinessFit=49, TechHealth=49 â†’ Eliminate
- [ ] Same boundary tests for PAID quadrants
