# Bolt Update: Bubble Sizing Fix & Settings Panel

## Issue 1: Bubble Size Differentiation

The current PAID chart bubble sizes don't show enough visual differentiation. XL and 2XL look almost the same size.

### Problem

The weights (1/5/15/40/80/150) represent area, but we perceive radius visually. With area-based scaling:
- XL (80) â†’ radius â‰ˆ âˆš80 â‰ˆ 9
- 2XL (150) â†’ radius â‰ˆ âˆš150 â‰ˆ 12
- Result: Only ~33% larger visually

### Solution

Adjust weights so each T-shirt size is **visually distinct** â€” roughly 1.5-2x larger radius than the previous size:

```javascript
// Revised bubble weights for better visual differentiation
const BUBBLE_SIZES = {
  'XS':  8,
  'S':   18,
  'M':   32,
  'L':   50,
  'XL':  72,
  '2XL': 100
};

function getRemediationBubbleSize(effort) {
  return BUBBLE_SIZES[effort] || null;
}
```

This produces clear visual steps where:
- XS is clearly small
- 2XL is obviously much larger than XL
- Each size is distinguishable from adjacent sizes

### Update the Legend

The bubble size legend on the PAID chart should reflect these new visual sizes.

---

## Issue 2: Add Settings Panel for T-Shirt Thresholds

Add a Settings control on the Portfolio Analysis screen so users can configure what each T-shirt size means for their organization.

### Location

Add a **gear icon (âš™ï¸)** in the top-right area of the Portfolio Analysis screen, near the PAID chart or in the header area.

### Settings Modal/Panel

Clicking the gear opens a modal or slide-out panel:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Remediation Sizing Settings            âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                             â”‚
â”‚ Maximum Single-Project Budget               â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ $ 1,000,000                             â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                             â”‚
â”‚ This defines your 2XL threshold.            â”‚
â”‚ Other sizes scale proportionally.           â”‚
â”‚                                             â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                             â”‚
â”‚ Preview:                                    â”‚
â”‚   XS:   < $25K                              â”‚
â”‚   S:    $25K - $100K                        â”‚
â”‚   M:    $100K - $250K                       â”‚
â”‚   L:    $250K - $500K                       â”‚
â”‚   XL:   $500K - $1M                         â”‚
â”‚   2XL:  > $1M                               â”‚
â”‚                                             â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐  â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Apply Changes  â”‚  â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

### Calculation Logic

```javascript
function calculateThresholds(maxProjectBudget) {
  return {
    XS:   { 
      max: Math.round(maxProjectBudget * 0.025), 
      label: `< ${formatCurrency(maxProjectBudget * 0.025)}` 
    },
    S:    { 
      max: Math.round(maxProjectBudget * 0.10),  
      label: `${formatCurrency(maxProjectBudget * 0.025)} - ${formatCurrency(maxProjectBudget * 0.10)}` 
    },
    M:    { 
      max: Math.round(maxProjectBudget * 0.25),  
      label: `${formatCurrency(maxProjectBudget * 0.10)} - ${formatCurrency(maxProjectBudget * 0.25)}` 
    },
    L:    { 
      max: Math.round(maxProjectBudget * 0.50),  
      label: `${formatCurrency(maxProjectBudget * 0.25)} - ${formatCurrency(maxProjectBudget * 0.50)}` 
    },
    XL:   { 
      max: maxProjectBudget,         
      label: `${formatCurrency(maxProjectBudget * 0.50)} - ${formatCurrency(maxProjectBudget)}` 
    },
    '2XL': { 
      max: null,                     
      label: `> ${formatCurrency(maxProjectBudget)}` 
    }
  };
}

function formatCurrency(value) {
  if (value >= 1000000) {
    return `$${(value / 1000000).toFixed(1)}M`;
  } else if (value >= 1000) {
    return `$${Math.round(value / 1000)}K`;
  }
  return `$${value}`;
}

// Example: maxProjectBudget = 1,000,000
// XS:   < $25K
// S:    $25K - $100K
// M:    $100K - $250K
// L:    $250K - $500K
// XL:   $500K - $1M
// 2XL:  > $1M

// Example: maxProjectBudget = 2,000,000
// XS:   < $50K
// S:    $50K - $200K
// M:    $200K - $500K
// L:    $500K - $1M
// XL:   $1M - $2M
// 2XL:  > $2M
```

### Behaviors

1. **Live preview**: As user types the budget number, the preview labels update immediately
2. **Apply Changes**: Persists the setting and updates:
   - Remediation Effort dropdown labels (in Edit Application modal)
   - PAID chart bubble legend
   - Any tooltips showing remediation cost ranges
3. **Persist**: Store `maxProjectBudget` in application/portfolio settings (localStorage for now, or database if available)
4. **Default**: If no setting exists, default to $1,000,000

### Update Remediation Effort Dropdown

The Edit Application modal's "Remediation Effort Estimate" dropdown should use the calculated labels:

```jsx
// Before (hardcoded)
<option value="XS">XS - Extra Small (< $25K)</option>

// After (dynamic from settings)
<option value="XS">XS - Extra Small ({thresholds.XS.label})</option>
```

---

## Summary of Changes

| Component | Change |
|-----------|--------|
| PAID bubble sizes | Increase differentiation (new weights: 8/18/32/50/72/100) |
| PAID bubble legend | Update to reflect new visual sizes |
| Portfolio Analysis | Add settings gear icon |
| Settings modal | New component for max budget input + preview |
| Edit Application dropdown | Dynamic labels from settings |
| Tooltips | Dynamic labels from settings |
