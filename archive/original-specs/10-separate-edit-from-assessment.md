# Fix: Separate Application Edit from Assessment

## Problem Summary

The current implementation has conflated two different concepts:

1. **Application metadata** (name, description, owner, cost, lifecycle) â€” lives on the Application in the pool
2. **Assessment scores** (B1-B10, T01-T15, remediation effort) â€” lives on the Portfolio Assignment

The Edit button on the Applications table now opens the Assessment modal, but there's no way to edit the application's core metadata.

Additionally, the Move and Clone features for portfolio assignments are missing.

---

## Fix Order (Do These In Sequence)

### Step 1: Restore Edit Application Modal

**The Edit (pencil) button on the Applications table should open the Edit Application modal, NOT the Assessment modal.**

**Edit Application modal contains (pool metadata only):**
- Application Name (required)
- Description
- Business Owner (dropdown)
- Primary Support (dropdown)
- Annual Cost
- Lifecycle Status (dropdown)

**This modal does NOT contain:**
- Factor scores (B1-B10, T01-T15) â€” in Assessment modal
- Remediation Effort â€” in Assessment modal
- Assessment status â€” in Assessment modal
- Portfolio assignment â€” managed via Move/Copy actions

Those belong in the Assessment modal or are managed via separate actions.

---

### Step 2: Add Separate "Assess" Action

**Add an "Assess" button/icon to each application row** (separate from Edit).

| Action | Icon | Opens | Contains |
|--------|------|-------|----------|
| **Edit** | Pencil âœï¸ | Edit Application modal | Name, description, owner, cost, lifecycle |
| **Assess** | Clipboard ðŸ“‹ or Checklist âœ“ | Assessment modal | B1-B10, T01-T15, remediation effort |

**On the Dashboard (portfolio-filtered view):**
- Edit â†’ Edit Application modal (pool-level metadata)
- Assess â†’ Assessment modal for THAT portfolio context

**On the Applications screen (pool view):**
- Edit â†’ Edit Application modal
- Assess â†’ Assessment modal (need to pick portfolio if app is in multiple)

---

### Step 3: Add "Add Applications" to Portfolio

**On the Dashboard (when viewing a specific portfolio), add an "Add Applications" button** next to "+ Add Application".

**Purpose:** Add existing applications from the pool to this portfolio.

**Button location:**
```
Application Portfolio                    [View Charts] [Add Applications] [+ Add Application]
3 of 3 applications assessed
Portfolio: [Finance â–¼]
```

**"+ Add Application"** = Create NEW app (adds to pool AND assigns to current portfolio)
**"Add Applications"** = Pick EXISTING apps from pool to add to current portfolio

**Add Applications modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Add Applications to Finance                                âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Select applications from the pool to add to this portfolio:    â”‚
â”‚                                                                 â”‚
â”‚ ðŸ” Search applications...                                       â”‚
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ â˜ Sage 300 General Ledger      (already in: General)       â”‚ â”‚
â”‚ â”‚ â˜ AdjustedCostBase.ca          (already in: General)       â”‚ â”‚
â”‚ â”‚ â˜ Sage 300 Accounts Payable    (already in: General)       â”‚ â”‚
â”‚ â”‚ â˜‘ Legacy Payroll System        (not in any portfolio)      â”‚ â”‚
â”‚ â”‚ â˜‘ Cloud HR Platform            (not in any portfolio)      â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ 2 applications selected                                         â”‚
â”‚                                                                 â”‚
â”‚ â„¹ï¸ New assessments will be created for each application.        â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Add to Portfolio     â”‚                â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Behavior:**
- Shows all applications in the pool
- Indicates which portfolios each app is already in
- Multi-select with checkboxes
- Search/filter capability
- Adds selected apps to the current portfolio with blank assessments (Not Started)

**Note:** Apps can be in multiple portfolios. Adding an app that's already in General to Finance creates a NEW assessment in Finance â€” the General assessment is unchanged.

---

### Steps 4 & 5: Consolidate Move and Copy into Single Action

**Instead of separate Move and Copy actions, combine them into one "Move/Copy" action** that opens a modal where the user chooses which operation to perform.

**Single icon:** â†—ï¸ (or folder-arrow icon)

**Move or Copy modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Move or Copy Application                                   âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ Application: AdjustedCostBase.ca                                â”‚
â”‚ Currently in: General                                           â”‚
â”‚                                                                 â”‚
â”‚ Select portfolio:                                               â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Finance                                                  â–¼  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ Choose action:                                                  â”‚
â”‚                                                                 â”‚
â”‚ â—‹ Move                                                          â”‚
â”‚   Transfer to Finance with all assessment scores.               â”‚
â”‚   Application will be removed from General.                     â”‚
â”‚                                                                 â”‚
â”‚ â—‹ Copy                                                          â”‚
â”‚   Add to Finance with a new blank assessment.                   â”‚
â”‚   Application will remain in General.                           â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Confirm              â”‚                â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Radio button behavior:**
- **Move selected:** Confirm button transfers assignment with all scores, removes from source portfolio
- **Copy selected:** Confirm button creates new blank assessment, keeps app in both portfolios

---

### Step 6: Add "Clone Scores" in Assessment Modal

**When assessing an app that has existing assessments in other portfolios, offer to clone scores.**

**Show this only when:**
- App exists in 2+ portfolios
- At least one other portfolio has scores (not "Not Started")

**UI at top of Assessment modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ ðŸ’¡ This application has been assessed in other portfolios:      â”‚
â”‚                                                                 â”‚
â”‚    General (Complete) - assessed Dec 21, 2025                   â”‚
â”‚                                                                 â”‚
â”‚    [Clone All Scores] [Clone Technical Only] [Start Fresh]      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Clone options:**
| Button | What it copies |
|--------|----------------|
| Clone All Scores | B1-B10, T01-T15, Remediation Effort |
| Clone Technical Only | T01-T15 only (most common use case) |
| Start Fresh | Nothing â€” blank assessment |

**After cloning:**
- Scores are populated in the form
- User can edit any scores
- Status set to "In Progress"
- User must still click "Save" or "Mark Complete"

---

## Summary of Actions per Screen

### Dashboard (Portfolio-Filtered View)

**Header buttons:**
| Button | What it does |
|--------|--------------|
| Add Existing App | Add existing apps from pool to this portfolio |
| + New Application | Create new app (adds to pool + assigns to this portfolio) |
| View Charts | Go to Portfolio Analysis (TIME/PAID charts) |

**Row actions:**
| Action | Icon | What it does |
|--------|------|--------------|
| Edit | âœï¸ | Edit Application modal (metadata) |
| Assess | ðŸ“‹ | Assessment modal (scores for THIS portfolio) |
| Move/Copy | â†—ï¸ | Opens modal to Move (transfer) or Copy (new assessment) |
| Remove | ðŸ—‘ï¸ | Remove from this portfolio (app stays in pool) |

### Applications Screen (Pool View)

| Action | Icon | What it does |
|--------|------|--------------|
| Edit | âœï¸ | Edit Application modal (metadata) |
| Assess | ðŸ“‹ | Assessment modal (pick portfolio if multiple) |
| Delete | ðŸ—‘ï¸ | Delete from pool (warns if in portfolios) |

---

## Data Model Reminder

```
Application (Pool)              Portfolio Assignment
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€               â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
id                              id
name                    â†â”€â”€â”€â”€â”€â”€â”€applicationId
description                     portfolioId
businessOwner                   assessmentStatus
primarySupport                  remediationEffort
annualCost                      b1-b10
lifecycleStatus                 t01-t15
                                businessFit (computed)
                                techHealth (computed)
                                etc.
```

**Edit Application** modifies the LEFT side (pool).
**Assessment** modifies the RIGHT side (portfolio assignment).
