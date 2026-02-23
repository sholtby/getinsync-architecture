# TIME/PAID Scoring Updates — Overview

## Summary

The TIME/PAID scoring system has been updated from v1.1 to v1.2. This document provides an overview of all changes required.

## Breaking Changes

| Change | Before (v1.1) | After (v1.2) |
|--------|---------------|--------------|
| Score scale | 1.0 - 5.0 | 0 - 100 |
| Quadrant threshold | 3.0 | 50 |
| PAID bubble size | AnnualCost (dollars) | RemediationEffort (T-shirt size) |

## Files to Update

1. **01-score-normalization.md** — Change all score calculations to 0-100 scale
2. **02-quadrant-thresholds.md** — Update TIME and PAID quadrant logic
3. **03-remediation-tshirt-sizing.md** — Add new T-shirt sizing for PAID bubble
4. **04-data-model-changes.md** — New fields required on Application entity
5. **05-ui-updates.md** — Chart axis ranges, tooltips, legends
6. **06-bubble-sizing-and-settings.md** — Bubble visual sizing and threshold settings
7. **07-application-pool-portfolio-model.md** — Two-level data model (Phase 2 refactor)
8. **08-consistency-review.md** — Documentation consistency audit
9. **09-dashboard-restoration.md** — Restore dashboard as landing page with portfolio switcher
10. **10-separate-edit-from-assessment.md** — Separate Edit (metadata) from Assess (scores), add Move/Copy/Clone
11. **11-rebrand-org-settings-clickable-cards.md** — Rebrand to GetInSync Lite, organization settings, clickable summary cards

## Implementation Order

### Phase 1: Current Model Enhancements
1. Data model changes (add RemediationEffort, LifecycleStatus, AssessmentStatus)
2. Score normalization (0-100)
3. Quadrant threshold updates (50)
4. T-shirt sizing implementation
5. UI updates (charts, tooltips)
6. Bubble sizing visual fix + settings panel

### Phase 2: Architecture Refactor (Future)
7. Application Pool / Portfolio Assignment model (see doc 07)

## Testing Checklist

- [ ] Scores display as 0-100 (not 1.0-5.0)
- [ ] Quadrants assign correctly at threshold 50
- [ ] PAID bubble sizes reflect T-shirt (8/18/32/50/72/100)
- [ ] TIME bubble sizes reflect Criticality (0-100)
- [ ] Chart axes show 0-100 range
- [ ] Reference lines appear at 50 on both axes
