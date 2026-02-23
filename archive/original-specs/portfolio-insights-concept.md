# Portfolio Insights / Anomaly Detection - Concept Note

## Overview

A future feature that surfaces actionable insights from TIME/PAID assessment data, answering "So what should we DO about it?"

This addresses the synthesis gap where:
- TIME tells you WHERE an app sits (fit/health)
- PAID tells you the RISK/IMPACT situation
- **Insights tell you what deserves ATTENTION**

## Proposed Alert Rules

| Alert | Condition | Message |
|-------|-----------|---------|
| Critical apps neglected | Criticality > 75 AND TIME = Tolerate | "X high-criticality apps in Tolerate quadrant - review needed" |
| Over-investment | Criticality < 25 AND Annual Cost > 10% of Portfolio Total | "X low-criticality apps consuming Y% of portfolio spend" |
| Modernize candidates | Business Fit > 70 AND Tech Health < 40 | "X apps with strong business fit need tech investment" |
| Eliminate candidates | Business Fit < 30 AND Tech Health < 40 | "X apps are candidates for retirement" |
| Cost/value mismatch | Business Fit < 30 AND Annual Cost > 10% of Portfolio Total | "X low-value apps consuming Y% of spend - review ROI" |
| Tech debt hotspots | Tech Risk > 70 AND Criticality > 70 | "X critical apps with high tech risk - urgent attention" |
| Organizational dysfunction | Same app scored differently across portfolios (variance > 20) | "X apps have conflicting assessments across stakeholder groups" |

## Threshold Sizing

Cost thresholds should be **relative, not absolute** to auto-scale across organizations:

- **Percentage of Portfolio Total** (recommended): "Costs > 10% of portfolio spend"
- **Multiple of Average**: "Costs > 3x portfolio average"
- **Configurable**: Admin sets threshold in Org Settings (Enterprise tier)

$100k is massive for a 50-person company but trivial for a government ministry.

## UI Placement Options

1. **Dashboard Card**: "âš ï¸ 5 items need attention" with expandable list
2. **Charts Sidebar**: Insights panel next to TIME/PAID charts
3. **Portfolio Report**: Section in exported PDF/PPTX reports
4. **Email Digest**: Weekly summary of portfolio health (Enterprise)

## Tier Availability

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| View insights | 3 basic alerts | All alerts | All alerts |
| Configure thresholds | âŒ | âŒ | âœ… |
| Email digest | âŒ | âŒ | âœ… |
| Custom alert rules | âŒ | âŒ | âœ… |

## Related Concepts

- **Organizational Dysfunction Detection**: Same app with different scores across portfolios reveals stakeholder disagreement
- **Demand Collision**: Multiple initiatives competing for the same system resources
- **IT Value Creation Module (Phase 18)**: Initiatives as "pre-vetted Ideas with Value Plans"

## Implementation Notes

- Query runs on portfolio view load or dashboard refresh
- Cache results for performance (refresh on assessment changes)
- Consider materialized views for complex cross-portfolio queries

---

*Captured: 2024-12-31*
*Related to: Phase 18 - IT Value Creation Module*
