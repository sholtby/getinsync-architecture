# Documentation Consistency Review

## Review Date: 2025-12-21

---

## Inconsistencies Found

### 1. Bubble Size Values â€” INCONSISTENT

**Document 00-overview.md (line 35):**
```
PAID bubble sizes reflect T-shirt (1/5/15/40/80/150)
```

**Document 03-remediation-tshirt-sizing.md:**
```
Uses 1/5/15/40/80/150
```

**Document 04-data-model-changes.md (line 71):**
```
remediationBubbleSize: number | null;  // 1, 5, 15, 40, 80, 150
```

**Document 06-bubble-sizing-and-settings.md (line 20-27):**
```javascript
const BUBBLE_SIZES = {
  'XS':  8,
  'S':   18,
  'M':   32,
  'L':   50,
  'XL':  72,
  '2XL': 100
};
```

**Resolution:** Document 06 has the CORRECT values (8/18/32/50/72/100) for visual differentiation. Update all other docs to match.

---

### 2. Data Model â€” Application vs Portfolio Assignment

**Document 04-data-model-changes.md:**
- Shows `remediationEffort` on Application entity
- Shows factor scores (b1-b10, t01-t15) on Application entity
- Shows computed scores on Application entity

**Document 07-application-pool-portfolio-model.md:**
- Shows Application (Pool) with NO assessment scores
- Shows factor scores on Portfolio Assignment entity
- Shows remediationEffort on Portfolio Assignment entity
- Shows computed scores on Portfolio Assignment entity

**Resolution:** Document 07 is the TARGET model. Document 04 describes the CURRENT/TRANSITIONAL model. Need to clarify this relationship â€” 04 is "before pool/portfolio split" and 07 is "after".

---

### 3. CSV Import â€” Portfolio Column

**Document 07 (line 490-495):**
```csv
Application Name,Description,Business Owner,Primary Support,Annual Cost,Lifecycle Status
```
Portfolio column REMOVED from import template.

**Earlier conversation prompt for Bolt:**
Included Portfolio column in import.

**Resolution:** Document 07 is correct â€” import goes to pool, portfolio assignment is separate. But we should support optional Portfolio column for the "lazy path" (auto-assign to specified portfolio or General).

---

### 4. Lifecycle Status â€” Missing from some docs

**Document 07:** Includes `lifecycleStatus` on Application entity
**Document 04:** Does NOT include `lifecycleStatus`

**Resolution:** Add lifecycleStatus to Document 04.

---

### 5. Assessment Status â€” Missing from Document 04

**Document 07:** Includes `assessmentStatus` on Portfolio Assignment
**Document 04:** Does NOT include `assessmentStatus`

**Resolution:** Document 04 is pre-pool model, so assessmentStatus would be on Application. Add it.

---

## Recommended Updates

### Update 00-overview.md

Change line 35:
```
- [ ] PAID bubble sizes reflect T-shirt (8/18/32/50/72/100)
```

Add to Files to Update:
```
6. **06-bubble-sizing-and-settings.md** â€” Bubble visual sizing and threshold settings
7. **07-application-pool-portfolio-model.md** â€” Two-level data model (future architecture)
```

---

### Update 03-remediation-tshirt-sizing.md

Update bubble size table:
```markdown
| Size | Code | Bubble Size | Default Cost Range | Description |
|------|------|-------------|-------------------|-------------|
| XS | `XS` | 8 | < $25K | Minor fix; internal effort only |
| S | `S` | 18 | $25K - $100K | Small project; single team |
| M | `M` | 32 | $100K - $250K | Medium project; cross-team |
| L | `L` | 50 | $250K - $500K | Large project; significant |
| XL | `XL` | 72 | $500K - $1M | Major initiative |
| 2XL | `2XL` | 100 | > $1M | Multi-year program |
```

---

### Update 04-data-model-changes.md

Add note at top:
```markdown
> **Note:** This document describes the v1.2 data model BEFORE the Application Pool / Portfolio Assignment refactor. See `07-application-pool-portfolio-model.md` for the target architecture where assessment scores move from Application to Portfolio Assignment.
```

Add lifecycleStatus:
```typescript
interface Application {
  // ...existing fields...
  
  // Lifecycle (new in v1.2)
  lifecycleStatus: 'Mainstream' | 'Extended' | 'End of Support';
  
  // Assessment status
  assessmentStatus: 'Not Started' | 'In Progress' | 'Complete';
  
  // ...
}
```

Update remediationBubbleSize comment:
```typescript
remediationBubbleSize: number | null;  // 8, 18, 32, 50, 72, 100 (visual scaling)
```

---

### Update 07-application-pool-portfolio-model.md

**Fix markdown formatting issue (line 71):**
```markdown
### Reassigning applications:
```
Should be:
```markdown
**Reassigning applications:**
```

**Add CSV Import option for lazy path:**
After line 495, add:
```markdown
**Optional: Portfolio column for lazy path**

If Portfolio column is included in CSV:
- Application added to pool
- AND automatically assigned to specified portfolio
- If portfolio doesn't exist, create it
- If Portfolio column is blank or missing, assign to "General"

This supports the simple use case where users just want to import and assess without thinking about pool vs. portfolio.
```

**Update Portfolio Assignment bubble size (line 281):**
Currently missing `remediationBubbleSize`. Add as computed field.

---

## Document Dependency Order

For Bolt implementation, process docs in this order:

1. **04-data-model-changes.md** â€” Current model (single-level)
2. **01-score-normalization.md** â€” 0-100 scale
3. **02-quadrant-thresholds.md** â€” Threshold = 50
4. **03-remediation-tshirt-sizing.md** â€” T-shirt sizing
5. **05-ui-updates.md** â€” UI changes for above
6. **06-bubble-sizing-and-settings.md** â€” Visual bubble sizing + settings
7. **07-application-pool-portfolio-model.md** â€” Future architecture (PHASE 2)

**Phase 1:** Docs 01-06 (current single-level model with improvements)
**Phase 2:** Doc 07 (refactor to pool/portfolio model)

---

## Summary

| Issue | Status | Action |
|-------|--------|--------|
| Bubble sizes inconsistent | Found | Update 00, 03, 04 to use 8/18/32/50/72/100 |
| Data model evolution unclear | Found | Add note to 04 explaining it's pre-pool model |
| CSV Portfolio column | Found | Add optional Portfolio for lazy path in 07 |
| Lifecycle Status missing | Found | Add to 04 |
| Assessment Status missing | Found | Add to 04 |
| Markdown formatting | Found | Fix line 71 in 07 |
