# Application Pool & Portfolio Assignment Model

## Design Specification for Bolt.new
Version: 1.0
Date: 2025-12-21

---

## Overview

This document describes a two-level data model separating the **Application Pool** (inventory) from **Portfolio Assignments** (assessment context). This aligns with enterprise APM patterns where applications exist as organizational assets, then are assessed within specific portfolio contexts.

---

## Current Model (Single Level)

```
Portfolio
  â””â”€â”€ Application (with assessment scores)
```

**Problems:**
- Application is tightly coupled to one portfolio
- To add same app to multiple portfolios, must duplicate all data
- No concept of "organization's application inventory"

---

## Target Model (Two Levels)

```
Organization
  â””â”€â”€ Application Pool (inventory)
        â””â”€â”€ Application (master record)
  â””â”€â”€ Portfolios
        â””â”€â”€ Portfolio Assignment (app + assessment context)
```

---

## Default Portfolio Behavior

### "General" Default Portfolio

When an organization is created, automatically create a default portfolio:
- **Name:** "General" (but CAN be renamed to a friendly name)
- **Description:** "Default portfolio for all applications"
- **System flag:** `isDefault: true`
- **Cannot be deleted** â€” disable delete button, show tooltip "Default portfolio cannot be deleted"
- **Always shows "Default" badge** in UI regardless of name
- **Landing portfolio** â€” users land here when opening the app

**Renaming the default portfolio:**
- User CAN rename "General" to any name (e.g., "Corporate IT", "Main Portfolio")
- The `isDefault: true` flag stays â€” it's still the system default
- Name field is editable in Edit Portfolio modal
- Show info message: "This is the default portfolio. It cannot be deleted."

### Lazy/Simple UX Path

For users who don't care about portfolios, everything "just works":

1. **Add Application** â†’ adds to pool AND automatically assigns to "General" portfolio
2. **Assess** â†’ scores the app in "General" context
3. **View Charts** â†’ shows "General" portfolio analysis
4. **User never has to think about portfolios**

This is the 80% use case â€” one big bucket, score everything, see the charts.

### When User Creates Additional Portfolios

Once a user creates a second portfolio, the UX evolves:

**Adding applications:**
- Still adds to pool
- Prompt: "Assign to portfolio?" with dropdown (default: General)
- Or: Add to pool only, assign later

**Reassigning applications:**
- Can **move** apps from one portfolio to another
- "Move to Portfolio" action on application row
- Bulk select + "Move to Portfolio" action

**Move behavior:**
- Transfers the **entire Portfolio Assignment** (scores, remediation, status)
- Application remains in the pool (always)
- App is **removed from source portfolio**, **added to target portfolio**
- This is a MOVE, not a copy

**Use case:**
> "I jumped in without thinking, assessed 10 apps in General, then realized they should be in Finance."

| Before Move | After Move |
|-------------|------------|
| App "Sage 300" in General with scores | App "Sage 300" in Finance with same scores |
| General shows Sage 300 | General no longer shows Sage 300 |
| Finance doesn't show Sage 300 | Finance shows Sage 300 |
| Scores: BF=71, TH=51 | Scores: BF=71, TH=51 (preserved) |

**Move to Portfolio modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Move Application                            â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                             â”‚
â”‚ Move "Sage 300 General Ledger"              â”‚
â”‚ from: General                               â”‚
â”‚                                             â”‚
â”‚ To portfolio:                               â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Finance                              â–¼  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                             â”‚
â”‚ âœ“ Assessment scores will be preserved       â”‚
â”‚                                             â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐    â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Move         â”‚    â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘    â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Bulk move:**
- Select multiple apps via checkboxes
- "Move to Portfolio" button appears
- Same modal, shows count: "Move 5 applications from General to..."

**Copy to Portfolio (separate action):**
If user wants the app in **multiple portfolios** with **separate assessments**:
- "Add to Portfolio" action (not Move)
- Creates a **new Portfolio Assignment** with blank scores
- App now appears in both portfolios
- Each portfolio has independent assessment

| Action | Source Portfolio | Target Portfolio | Scores |
|--------|------------------|------------------|--------|
| **Move** | Removed | Added | Transferred |
| **Add/Copy** | Unchanged | Added | Blank (new assessment) |

---

### Cloning Scores from Another Portfolio

When an application exists in multiple portfolios, users often want to **copy scores from an existing assessment** as a starting point â€” especially Technical scores which tend to be consistent across portfolios.

**Use case:**
> "Sage 300 is already assessed in Finance. I'm adding it to HR portfolio â€” the Technical scores are the same, but Business scores will differ."

**Clone UI in Assessment Modal:**

When assessing an app that exists in other portfolios, show a "Clone from..." option:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Assess Application                                              â”‚
â”‚ Sage 300 General Ledger in HR portfolio                         â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ ðŸ’¡ This application has been assessed in other portfolios: â”‚ â”‚
â”‚ â”‚                                                             â”‚ â”‚
â”‚ â”‚    Finance (Complete) - assessed Dec 15, 2025               â”‚ â”‚
â”‚ â”‚                                                             â”‚ â”‚
â”‚ â”‚    [Clone All Scores] [Clone Technical Only] [Start Fresh]  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ [Business Factors]  [Technical Factors]  [Remediation]          â”‚
â”‚                                                                 â”‚
â”‚ ...                                                             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Clone options:**

| Option | What it copies | Use when |
|--------|----------------|----------|
| **Clone All Scores** | B1-B10, T01-T15, Remediation | Quick start, then adjust as needed |
| **Clone Technical Only** | T01-T15 only | Tech scores same, Business scores differ by portfolio |
| **Clone Business Only** | B1-B10 only | Less common, but available |
| **Start Fresh** | Nothing | Completely independent assessment |

**Clone behavior:**
- Copies scores from selected source portfolio
- User can then edit any scores
- Status set to "In Progress" (not Complete, even if source was Complete)
- Clone is a one-time copy â€” no ongoing link between portfolios

**Clone from dropdown (if multiple source portfolios):**

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Clone scores from:                                              â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Finance (Complete)                                       â–¼  â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                 â”‚
â”‚ What to clone:                                                  â”‚
â”‚ â˜‘ Technical Factors (T01-T15)                                   â”‚
â”‚ â˜ Business Factors (B1-B10)                                     â”‚
â”‚ â˜ Remediation Effort                                            â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                        â”‚
â”‚              â”‚ Cancel â”‚ â”‚ Clone        â”‚                        â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                        â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**When clone option appears:**
- Only when app exists in 2+ portfolios
- Only when at least one other portfolio has scores (not "Not Started")
- If current assessment already has scores, warn: "This will overwrite existing scores"

**Assessment context:**
- If app is in multiple portfolios, assessment is per-portfolio
- Editing from General portfolio edits General's scores
- Editing from Finance portfolio edits Finance's scores

### Progressive UI Disclosure

**If only "General" portfolio exists:**
- Hide portfolio column in Applications table (unnecessary)
- Hide portfolio filter on dashboard
- Hide "Portfolios" nav item or show as subtle/secondary
- View Charts goes directly to General analysis

**Once 2+ portfolios exist:**
- Show portfolio column in tables
- Show portfolio filter/selector
- Show "Portfolios" nav item prominently
- View Charts shows portfolio selector

### Portfolio Count in Free Tier

**Free tier allows 3 portfolios** (including the default):
- Default portfolio + 2 custom portfolios
- Paid tier: Unlimited

**When user tries to create 4th portfolio, show upgrade modal:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Upgrade to Pro                                             âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                 â”‚
â”‚ ðŸš€ You've reached the free tier limit                           â”‚
â”‚                                                                 â”‚
â”‚ Free tier includes:                                             â”‚
â”‚ â€¢ 3 portfolios (3/3 used)                                       â”‚
â”‚ â€¢ 20 applications                                               â”‚
â”‚                                                                 â”‚
â”‚ Upgrade to Pro for:                                             â”‚
â”‚ â€¢ Unlimited portfolios                                          â”‚
â”‚ â€¢ Unlimited applications                                        â”‚
â”‚ â€¢ Priority support                                              â”‚
â”‚                                                                 â”‚
â”‚              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐           â”‚
â”‚              â”‚ Maybe Later â”‚ â”‚ View Pricing         â”‚           â”‚
â”‚              â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Data Model

### Application (Pool/Inventory)

The master record for an application. Lives at the organization level.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | Primary key |
| name | String | Yes | Application name |
| description | String | No | What it does |
| businessOwner | FK â†’ Person | No | Business owner |
| primarySupport | FK â†’ Person | No | Technical support contact |
| annualCost | Decimal | No | Annual run cost |
| lifecycleStatus | Enum | Yes | Mainstream, Extended, End of Support |
| createdAt | DateTime | Yes | |
| updatedAt | DateTime | Yes | |

**Note:** No assessment scores here â€” those live on Portfolio Assignment.

---

### Portfolio

A collection of applications being assessed together.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | Primary key |
| name | String | Yes | Portfolio name |
| description | String | No | Purpose/scope |
| isDefault | Boolean | Yes | True for "General" portfolio, false otherwise |
| createdAt | DateTime | Yes | |
| updatedAt | DateTime | Yes | |

**Constraints:**
- Only one portfolio can have `isDefault: true`
- Default portfolio cannot be deleted

---

### Portfolio Assignment

Links an application to a portfolio with assessment context.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | Primary key |
| applicationId | FK â†’ Application | Yes | Link to pool |
| portfolioId | FK â†’ Portfolio | Yes | Link to portfolio |
| remediationEffort | Enum | No | XS, S, M, L, XL, 2XL |
| remediationBubbleSize | Integer | Computed | 8, 18, 32, 50, 72, 100 (from effort) |
| assessmentStatus | Enum | Yes | Not Started, In Progress, Complete |
| b1 - b10 | Integer (1-5) | No | Business factor scores |
| t01 - t15 | Integer (1-5) | No | Technical factor scores (no t12) |
| businessFit | Integer (0-100) | Computed | Calculated from B factors |
| techHealth | Integer (0-100) | Computed | Calculated from T factors |
| criticality | Integer (0-100) | Computed | Calculated from B1-B7 |
| technicalRisk | Integer (0-100) | Computed | Calculated from T subset |
| timeQuadrant | Enum | Computed | Invest, Tolerate, Migrate, Eliminate |
| paidAction | Enum | Computed | Plan, Address, Ignore, Delay |
| createdAt | DateTime | Yes | |
| updatedAt | DateTime | Yes | |

**Unique constraint:** (applicationId + portfolioId) â€” an app can only be in a portfolio once.

---

## User Interface Changes

### Navigation Structure

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ APM Portfolio Manager                                       â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                             â”‚
â”‚  [Dashboard]    [Portfolios]    [Applications]              â”‚
â”‚       â†‘              â†‘               â†‘                      â”‚
â”‚   LANDING PAGE   Management      App Pool                   â”‚
â”‚                                                             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Three main sections:**
1. **Dashboard** â€” Main working screen with summary cards, distributions, apps table (LANDING PAGE)
2. **Portfolios** â€” Create/edit/delete portfolios
3. **Applications** â€” Manage the application pool (inventory)

**IMPORTANT:** The Dashboard is the landing page, NOT the Portfolios screen. Users should see their data immediately upon opening the app.

---

### Dashboard Screen (Landing Page)

**Purpose:** Main working screen showing portfolio health at a glance.

**This is the LANDING PAGE â€” users see this first when opening the app.**

**Header:**
```
Application Portfolio              [View Charts] [Add Applications] [+ Add Application]
3 of 3 applications assessed

Portfolio: [General â–¼]
```

**Header buttons:**
| Button | What it does |
|--------|--------------|
| View Charts | Go to Portfolio Analysis (TIME/PAID bubble charts) |
| Add Existing App | Add existing apps from pool to this portfolio |
| + New Application | Create new app (adds to pool + assigns to current portfolio) |

**Portfolio context switcher:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ ðŸ“ All Portfolios           â”‚  â† Aggregate view
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ ðŸ“ Corporate IT     Default â”‚  â† Default (renamed from General)
â”‚ ðŸ“ Finance                  â”‚
â”‚ ðŸ“ HR                       â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ Manage Portfolios...        â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Portfolio selector behavior:**
| Selection | Dashboard Shows | View Charts Behavior |
|-----------|-----------------|----------------------|
| All Portfolios | Aggregate of all apps across all portfolios | Switches to default portfolio, then opens charts |
| Default Portfolio | Only default portfolio apps | Opens charts for default portfolio |
| Other Portfolio | Only that portfolio's apps | Opens charts for that portfolio |

**"All Portfolios" view:**
- Summary cards show aggregate totals
- Applications table shows ALL apps with Portfolio column
- TIME/PAID Distribution charts show combined counts
- **No combined TIME/PAID bubble charts** â€” that's a GetInSync feature

**"View Charts" when "All Portfolios" selected:**
- Automatically switch to default portfolio
- Then open Portfolio Analysis (charts) screen
- Show toast: "Viewing charts for [Default Portfolio Name]"

**Summary cards:**
- Total Applications
- Total Annual Cost
- Est. Tech Debt
- Avg Business Fit
- Avg Tech Health

**Distribution charts:**
- TIME Distribution (Invest/Migrate/Tolerate/Eliminate)
- PAID Distribution (Address/Plan/Delay/Ignore)

**Applications table:**
- Shows apps in selected portfolio (or all if "All Portfolios")
- Columns: ID, Application, Status, Business Fit, Tech Health, TIME, PAID, Annual Cost, Actions

**Row actions:**
| Action | Icon | What it does |
|--------|------|--------------|
| Edit | âœï¸ | Edit Application modal (name, owner, cost, lifecycle â€” pool metadata) |
| Assess | ðŸ“‹ | Assessment modal (B1-B10, T01-T15, remediation â€” portfolio-specific) |
| Move/Copy | â†—ï¸ | Opens modal to Move (transfer with scores) OR Copy (new blank assessment) |
| Remove | ðŸ—‘ï¸ | Remove from this portfolio (app stays in pool) |

**Key behavior:**
- All stats, charts, and table filter based on selected portfolio
- "All Portfolios" aggregates across all portfolios
- Edit modifies the Application (pool), Assess modifies the Portfolio Assignment

---

### Add Applications Modal

**Purpose:** Add existing applications from the pool to the current portfolio.

**Opened by:** "Add Applications" button on Dashboard

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
â”‚ â”‚ â˜ Sage 300 General Ledger      (in: General)               â”‚ â”‚
â”‚ â”‚ â˜ AdjustedCostBase.ca          (in: General)               â”‚ â”‚
â”‚ â”‚ â˜‘ Legacy Payroll System        (not assigned)              â”‚ â”‚
â”‚ â”‚ â˜‘ Cloud HR Platform            (not assigned)              â”‚ â”‚
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
- Creates Portfolio Assignment with status "Not Started" for each selected app

---

### Applications Screen (Pool/Inventory)

**Purpose:** Manage the master list of applications (the pool).

**Header:**
```
Applications                          [Import CSV] [+ Add Application]
X applications in inventory
```

**Table columns:**
| Column | Sortable | Notes |
|--------|----------|-------|
| ID | Yes | |
| Application | Yes | Name + description |
| Business Owner | Yes | |
| Primary Support | Yes | |
| Annual Cost | Yes | |
| Lifecycle Status | Yes | With color indicator |
| Portfolios | No | Count or list: "3 portfolios" or "Finance, HR, IT" |
| Actions | No | Edit, Assess, Delete |

**Row actions:**
| Action | Icon | What it does |
|--------|------|--------------|
| Edit | âœï¸ | Edit Application modal (pool metadata) |
| Assess | ðŸ“‹ | Assessment modal (if in multiple portfolios, prompt to pick which one) |
| Delete | ðŸ—‘ï¸ | Delete from pool (warns if assigned to portfolios) |

**Add/Edit Application modal** (pool metadata only):
- Name (required)
- Description
- Business Owner (dropdown, can create new)
- Primary Support (dropdown, can create new)
- Annual Cost
- Lifecycle Status (dropdown)

**NOT in Edit Application modal** (these are portfolio-specific):
- Portfolio â€” managed via Move/Copy actions
- Remediation Effort â€” managed in Assessment modal
- Factor scores (B1-B10, T01-T15) â€” managed in Assessment modal

**When ADDING a new application:**
- App is added to pool
- App is automatically assigned to the currently selected portfolio
- No portfolio dropdown needed â€” uses context

**Edit modal does NOT contain:**
- Factor scores (B1-B10, T01-T15)
- Remediation Effort
- Assessment status
- Portfolio assignment

Those belong in the Assessment modal or are managed via Move/Copy actions.

**Delete behavior:**
- If application is assigned to any portfolio, show warning
- "This application is assigned to 3 portfolios. Removing it will also remove those assignments and their assessments."
- Require confirmation

---

### Portfolios Screen

**Purpose:** Manage portfolios and their application assignments.

**Header:**
```
Portfolios                                        [+ Create Portfolio]
X portfolios
```

**Portfolio cards or list:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Finance                                              [Edit] â”‚
â”‚ Financial systems portfolio                                 â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚ 12 applications Â· 8 assessed Â· Avg Business Fit: 67%        â”‚
â”‚                                                             â”‚
â”‚ [View Portfolio]                                            â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Create/Edit Portfolio modal:**
- Name (required)
- Description

---

### Portfolio Detail Screen

**Purpose:** Manage applications within a portfolio and perform assessments.

**Note:** This screen may be consolidated with the Dashboard when viewing a specific portfolio. The functionality is the same.

**Header:**
```
â† Back to Portfolios

Finance                                    [Add Applications] [View Charts]
Financial systems portfolio
12 applications Â· 8 assessed
```

**"Add Applications" button:**
- Opens modal to select from Application Pool
- Shows applications not yet in this portfolio
- Multi-select with checkboxes
- Search/filter capability
- [Add Selected to Portfolio] button

**Applications table (within portfolio):**
| Column | Sortable | Notes |
|--------|----------|-------|
| ID | Yes | |
| Application | Yes | Name (from pool) + Owner |
| Status | Yes | Not Started, In Progress, Complete |
| Business Fit | Yes | 0-100 or "â€”" if not assessed |
| Tech Health | Yes | 0-100 or "â€”" if not assessed |
| Criticality | Yes | |
| Tech Risk | Yes | |
| TIME | Yes | Quadrant badge |
| PAID | Yes | Action badge |
| Remediation | Yes | T-shirt size + cost range |
| Actions | No | Edit, Assess, Move, Copy, Remove |

**Row actions:**
| Action | Icon | What it does |
|--------|------|--------------|
| Edit | âœï¸ | Edit Application modal (pool metadata) |
| Assess | ðŸ“‹ | Assessment modal (scores for THIS portfolio) |
| Move/Copy | â†—ï¸ | Opens modal to Move OR Copy to another portfolio |
| Remove | ðŸ—‘ï¸ | Remove from this portfolio (app stays in pool) |

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

**Actions behavior:**
- **Edit**: Opens Edit Application modal â€” changes apply to the pool (affects all portfolios)
- **Assess**: Opens Assessment modal for this portfolio context (changes are portfolio-specific)
- **Move/Copy**: Opens modal to choose Move (transfer with scores) or Copy (blank assessment)
- **Remove**: Deletes the Portfolio Assignment â€” app stays in pool, can be re-added later

---

### Assessment Modal

**Purpose:** Score an application within a portfolio context.

**Header:**
```
Assess Application
Sage 300 General Ledger in Finance portfolio
```

**Clone scores prompt (if applicable):**

When the app exists in other portfolios with completed assessments, show:

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
| Clone Technical Only | T01-T15 only (tech scores are often the same across portfolios) |
| Start Fresh | Nothing â€” blank assessment |

**Only show clone prompt when:**
- App exists in 2+ portfolios
- At least one other portfolio has scores (not "Not Started")

**Tabs or sections:**
1. **Business Factors** (B1-B10)
2. **Technical Factors** (T01-T15)
3. **Remediation**

**Each factor:**
- Question text
- 1-5 scale selector (radio buttons or dropdown)
- Score labels visible (e.g., "1 - None", "5 - Essential")

**Remediation section:**
- Remediation Effort dropdown (XS - 2XL)
- Notes field (optional)

**Footer:**
- [Cancel] [Save as Draft] [Mark Complete]

**Status logic:**
- No scores entered â†’ "Not Started"
- Some scores entered â†’ "In Progress"
- User clicks "Mark Complete" â†’ "Complete"

---

### View Charts Screen (Portfolio Analysis)

**No changes to current functionality**, but now scoped to selected portfolio:

- TIME Analysis chart
- PAID Analysis chart
- Priority Backlog table

**Portfolio selector behavior:**

The portfolio dropdown on this screen should **NOT include "All Portfolios"**.

TIME/PAID bubble charts are always portfolio-specific â€” there is no combined cross-portfolio view (that's a GetInSync feature).

```
Portfolio dropdown on Dashboard:        Portfolio dropdown on View Charts:
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ ðŸ“ All Portfolios           â”‚        â”‚ ðŸ“ General          Default â”‚
â”‚ ðŸ“ General          Default â”‚        â”‚ ðŸ“ Finance                  â”‚
â”‚ ðŸ“ Finance                  â”‚        â”‚ ðŸ“ HR                       â”‚
â”‚ ðŸ“ HR                       â”‚        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘        (NO "All Portfolios" option)
```

**When user clicks "View Charts" while "All Portfolios" is selected on Dashboard:**
- Automatically switch to the default portfolio
- Open the Portfolio Analysis screen
- Show toast: "Viewing charts for [Default Portfolio Name]"

---

## CSV Import Changes

### Import to Application Pool

The existing CSV import adds applications to the **pool**, not directly to a portfolio.

**Template (unchanged except removing portfolio column as required):**

```csv
# APM Portfolio Manager - Import Template
# Instructions:
# - Application Name is required; all other fields are optional
# - Lifecycle Status: Mainstream, Extended, End of Support
# - Annual Cost: accepts $10000, $10K, $1.5M formats
# - Rows starting with # are ignored
# - Duplicate application names will update existing records
#
Application Name,Description,Business Owner,Primary Support,Annual Cost,Lifecycle Status
Example CRM System,Customer relationship management,Jane Smith,Bob Johnson,$50K,Mainstream
Legacy Payroll,End of life payroll system,Finance Team,IT Support,$150K,End of Support
```

**Note:** Portfolio column removed â€” assignment happens separately.

**Optional: Portfolio column for lazy path**

If Portfolio column IS included in CSV:
- Application added to pool
- AND automatically assigned to specified portfolio
- If portfolio doesn't exist, create it
- If Portfolio column is blank, assign to "General"

This supports the simple use case where users just want to import and assess without thinking about pool vs. portfolio.

```csv
# With optional Portfolio column (lazy path)
Application Name,Description,Business Owner,Primary Support,Annual Cost,Lifecycle Status,Portfolio
Example CRM System,Customer relationship management,Jane Smith,Bob Johnson,$50K,Mainstream,Sales
Legacy Payroll,End of life payroll system,Finance Team,IT Support,$150K,End of Support,Finance
New HR Tool,Modern HR platform,HR Director,Vendor,$75K,Mainstream,
```
- Row 1: Assigned to "Sales" portfolio (created if doesn't exist)
- Row 2: Assigned to "Finance" portfolio
- Row 3: Assigned to "General" portfolio (blank = default)

### Future Enhancement: Import Assignments

Could add separate import for portfolio assignments with scores:

```csv
Application Name,Portfolio,Remediation Effort,B1,B2,B3,...
Sage 300,Finance,M,4,3,4,...
Sage 300,HR,XL,3,2,3,...
```

**Not in scope for initial implementation.**

---

## CSV Export Changes

### Export from Portfolio

When exporting from a portfolio view, include:
- Application pool fields
- Portfolio name
- Assessment scores
- Computed scores and quadrants

```csv
Application Name,Description,Business Owner,Primary Support,Annual Cost,Lifecycle Status,Portfolio,Remediation Effort,Assessment Status,Business Fit,Tech Health,Criticality,Tech Risk,TIME,PAID
Sage 300,Financial system,Rob Barnes,Steve McQueen,$10K,Mainstream,Finance,M,Complete,71,51,64,44,Invest,Plan
```

---

## Migration from Current Model

If existing data needs migration:

1. **Applications** â†’ Move to Application Pool (keep all fields except assessment)
2. **Portfolio Assignments** â†’ Create assignment records linking apps to their current portfolio
3. **Assessment scores** â†’ Move to Portfolio Assignment records

**SQL pseudocode:**
```sql
-- Create pool entries from existing applications
INSERT INTO ApplicationPool (id, name, description, businessOwner, ...)
SELECT id, name, description, businessOwner, ...
FROM Application;

-- Create portfolio assignments with scores
INSERT INTO PortfolioAssignment (applicationId, portfolioId, b1, b2, ..., remediationEffort)
SELECT id, portfolioId, b1, b2, ..., remediationEffort
FROM Application;
```

---

## Summary of Screens

| Screen | Purpose | Landing? |
|--------|---------|----------|
| **Dashboard** | Summary cards, distributions, apps table with portfolio filter | **YES** |
| **Applications** | Manage application pool (inventory) | No |
| **Portfolios** | List/create/edit/delete portfolios | No |
| **Portfolio Detail** | Manage apps in portfolio, perform assessments | No |
| **Portfolio Analysis** | TIME/PAID charts, Priority Backlog | No |
| **Assessment Modal** | Score an app within portfolio context | No |

---

## Implementation Order

1. **Database schema changes** â€” Add PortfolioAssignment table, refactor Application table
2. **Applications screen** â€” New pool management UI
3. **Portfolios screen** â€” New portfolio list UI
4. **Portfolio Detail screen** â€” Assignment management + assessment
5. **Migration** â€” Move existing data to new model
6. **CSV Import/Export** â€” Update for new model
7. **Charts/Analysis** â€” Should work with minor query changes

---

## Out of Scope (Future / GetInSync)

- Version history for assessments
- Assessment workflow and approvals
- Role-based permissions (Assessor vs Viewer)
- Hierarchical portfolios
- CMDB integration
- Multi-tenant architecture
