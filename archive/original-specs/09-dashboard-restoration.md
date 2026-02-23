# Dashboard Restoration & Navigation Fix

## Issue

The recent portfolio model update broke the main UX. The Application Portfolio dashboard was replaced with a sparse Portfolios list page, requiring users to click through to see any useful information.

**Before (correct):** User lands on dashboard with summary cards, distributions, and app table
**After (broken):** User lands on empty-looking Portfolios page with just a "General" card

---

## Requirements

### 1. Restore Dashboard as Landing Page

The **Application Portfolio dashboard** must be the landing page, showing:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Application Portfolio                    [View Charts] [+ Add Application] │
│ 3 of 3 applications assessed                                                │
│                                                                             │
│ Portfolio: [General ▼]                   ← NEW: Portfolio context switcher  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐│
│ │ Total Apps  │ │ Total Cost  │ │Est Tech Debt│ │Avg Bus Fit  │ │Avg Tech ││
│ │     3       │ │   $15K      │ │   $13K      │ │   54.7      │ │  60.7   ││
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘│
│                                                                             │
│ ┌────────────────────────────────┐ ┌────────────────────────────────────┐  │
│ │ TIME Distribution              │ │ PAID Distribution                  │  │
│ │ ● Invest   ████████████  2     │ │ ● Address                     0    │  │
│ │ ● Migrate                 0     │ │ ● Plan     ████████████     2    │  │
│ │ ● Tolerate ████           1     │ │ ● Delay                      0    │  │
│ │ ● Eliminate               0     │ │ ● Ignore   ████              1    │  │
│ └────────────────────────────────┘ └────────────────────────────────────┘  │
│                                                                             │
│ Applications                                                                │
│ ┌─────────────────────────────────────────────────────────────────────────┐│
│ │ ID  APPLICATION           STATUS    BUS FIT  TECH   TIME   PAID   COST ││
│ │ 1   Sage 300 General...  Complete   71.0    51.0   Invest Plan   $10K  ││
│ │ 2   AdjustedCostBase.ca  Complete   30.0    74.0   Toler  Ignore $45   ││
│ │ 3   Sage 300 Accounts... Complete   63.0    57.0   Invest Plan   $5K   ││
│ └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2. Add Portfolio Context Switcher

Add a **portfolio dropdown** to the dashboard header:

```
Portfolio: [General ▼]
           ├── General (default)
           ├── Finance
           ├── HR
           └── All Portfolios
```

**Behavior:**
- Default selection: "General" (the default portfolio)
- Switching portfolio filters ALL dashboard content:
  - Summary cards recalculate for selected portfolio
  - TIME/PAID distributions show only that portfolio's apps
  - Applications table shows only that portfolio's apps
- "All Portfolios" shows aggregate across all portfolios

**If only one portfolio exists (General):**
- Still show the dropdown, but with only "General" option
- Or hide dropdown entirely until 2+ portfolios exist (progressive disclosure)

### 3. Keep Portfolios Management Screen (Secondary)

The Portfolios list page (Image 2) is still useful for:
- Creating new portfolios
- Editing portfolio names/descriptions
- Deleting portfolios (except General)
- Seeing portfolio-level stats at a glance

**Access via:**
- Navigation menu item: "Portfolios" or "Manage Portfolios"
- Or a link/button on the dashboard: "Manage Portfolios →"

**NOT the landing page.**

### 4. Navigation Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ APM Portfolio Manager                                           │
├─────────────────────────────────────────────────────────────────┤
│  [Dashboard]    [Portfolios]    [Applications]                  │
│       ↑              ↑               ↑                          │
│   Landing page   Manage portfolios   Application Pool           │
│   (with context  (create/edit/      (all apps, no              │
│    switcher)      delete)            portfolio filter)          │
└─────────────────────────────────────────────────────────────────┘
```

| Nav Item | Purpose | Shows |
|----------|---------|-------|
| **Dashboard** | Main working screen | Summary cards, distributions, apps table (filtered by portfolio) |
| **Portfolios** | Portfolio management | Portfolio cards with stats, create/edit/delete |
| **Applications** | Application Pool | All applications regardless of portfolio assignment |

**Default route:** Dashboard (not Portfolios)

### 5. URL Structure (if applicable)

```
/                     → Dashboard (General portfolio)
/dashboard            → Dashboard (General portfolio)  
/dashboard?portfolio=finance  → Dashboard filtered to Finance
/dashboard?portfolio=all      → Dashboard showing all portfolios
/portfolios           → Portfolio management screen
/applications         → Application pool (all apps)
```

---

## Summary of Changes

| Component | Change |
|-----------|--------|
| Landing page | Restore Application Portfolio dashboard |
| Dashboard | Add portfolio context dropdown |
| Navigation | Dashboard is primary, Portfolios is secondary |
| Portfolios page | Keep as management screen, not landing |
| Routes | Default route → Dashboard |

---

## What NOT to Change

- Summary cards design ✓
- TIME/PAID distribution charts ✓
- Applications table ✓
- View Charts button/flow ✓
- Add Application button/flow ✓
- Portfolio card design on Portfolios page ✓
