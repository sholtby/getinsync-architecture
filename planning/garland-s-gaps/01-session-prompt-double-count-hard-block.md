# Session Prompt 01 — Double-Count Guard: Convert Soft Warning to Hard Block

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 1-2 hours

---

## Task: Convert the cost channel double-count warning from a bypassable modal to a hard block

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 3) claims: "Each application follows one cost path — never attributed to both an IT Service and a Cost Bundle simultaneously."

Currently this is a **soft warning** — users see a modal explaining the double-count risk but can click "Add anyway" to bypass it. We need to remove the bypass, making it a hard block. If an application already has IT Service allocations, you cannot add a Cost Bundle (and vice versa).

### Hard rules

1. **Branch:** `fix/double-count-hard-block`. Create from `dev`.
2. **You MAY only modify:**
   - `src/components/applications/CostBundleSection.tsx`
   - `src/components/ITServiceDependencyList.tsx`
3. **Do NOT modify database schema** — this is a UI-only change.
4. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
5. **Both directions must be blocked** — adding Cost Bundle when IT Services exist, AND adding IT Service when Cost Bundles exist.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/cost-budget/cost-model.md
   - §3.2 and §3.3 — cost channel separation rationale
   - §2.4 — "Two cost channels only: IT Service, Cost Bundle"

2. src/components/applications/CostBundleSection.tsx
   - checkForITServiceAllocations() — lines ~80-110 (what it queries)
   - handleAddClick() — lines ~112-128 (where warning triggers)
   - Warning modal — lines ~444-484 ("Add anyway" button at ~473-480)
   - doInsert() — lines ~130-162 (the insertion function)

3. src/components/ITServiceDependencyList.tsx
   - checkForContractBearingCostBundles() — lines ~74-95 (reverse check)
   - handleAddDependency() — lines ~97-109 (where warning triggers)
   - Cost bundle prompt modal — lines ~366-401 ("Continue" button at ~390-396)
   - doInsertDependency() — lines ~111-132 (the insertion function)
```

### Step 2 — Impact analysis

```bash
grep -r "CostBundleSection" src/ --include="*.tsx"
grep -r "ITServiceDependencyList" src/ --include="*.tsx"
grep -r "doInsert\|handleAddClick\|handleAddDependency" src/components/applications/CostBundleSection.tsx src/components/ITServiceDependencyList.tsx
```

Record all consumers.

### Step 3 — Harden CostBundleSection.tsx

**3a. Broaden the check trigger:**
Currently `checkForITServiceAllocations()` only runs when `bundles.length === 0` (first cost bundle). Change this to run on EVERY cost bundle addition — the user might have added IT Services after creating their first bundle.

**3b. Convert the warning modal to a hard block:**
- Remove the "Add anyway" button entirely
- Keep "Cancel" (or rename to "Understood" / "OK")
- Change the modal tone from warning (amber) to blocked (red)
- Update the modal text to explain WHY they can't add a cost bundle:
  - Header: "Cannot add Cost Bundle"
  - Body: "This application already has IT Service cost allocations. Each application uses one cost channel — either IT Services or Cost Bundles, not both. To use Cost Bundles instead, remove the existing IT Service allocations first."
- Show the existing IT Service count and total cost (already available from `checkForITServiceAllocations()`)

**3c. Ensure doInsert() is unreachable when IT Services exist:**
The modal should only have one button that dismisses it. `doInsert()` should never be called from the warning state.

### Step 4 — Harden ITServiceDependencyList.tsx

**4a. Broaden the check:**
Currently `checkForContractBearingCostBundles()` only looks for cost bundles with `contract_end_date NOT NULL`. Change this to check for ANY cost bundle DPs on the application, regardless of whether they have contract details. The presence of any cost bundle should block IT Service additions.

Update the query: instead of filtering `contract_end_date NOT NULL`, query for all DPs where `dp_type = 'cost_bundle'` for this application. Return count and total `annual_cost`.

**4b. Convert the info modal to a hard block:**
- Remove the "Continue" button
- Remove the "Review Cost Bundles" button (or keep it as a navigation aid but don't proceed with insertion)
- Change from info (blue) to blocked (red)
- Update text:
  - Header: "Cannot add IT Service allocation"
  - Body: "This application already has Cost Bundle cost data. Each application uses one cost channel — either IT Services or Cost Bundles, not both. To use IT Service allocations instead, remove the existing Cost Bundles first."
- Show the existing cost bundle count and total annual cost

**4c. Ensure doInsertDependency() is unreachable when Cost Bundles exist:**
Same pattern — the modal dismisses only, never proceeds.

### Step 5 — Verify both directions

Mentally trace through both flows:
1. Application has IT Service allocations → user clicks "Add Cost Bundle" → blocked modal appears → only option is to dismiss
2. Application has Cost Bundles → user clicks "Add IT Service" → blocked modal appears → only option is to dismiss
3. Application has neither → both buttons work normally (no modal)

### Step 6 — Type check

```bash
npx tsc --noEmit
```

Must pass with zero errors.

### Step 7 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/applications/CostBundleSection.tsx src/components/ITServiceDependencyList.tsx
git commit -m "fix: convert double-count cost channel guard from soft warning to hard block

Applications now use one cost channel only — IT Services OR Cost Bundles,
not both. The 'Add anyway' bypass has been removed. Users must remove
existing allocations before switching channels.
Closes Garland audit yellow flag (Slide 3, double-count guard)."
git push -u origin fix/double-count-hard-block
```

### Done criteria checklist

- [ ] CostBundleSection: "Add anyway" button removed, modal is a hard block
- [ ] CostBundleSection: Check runs on every add, not just first bundle
- [ ] ITServiceDependencyList: "Continue" button removed, modal is a hard block
- [ ] ITServiceDependencyList: Check covers ALL cost bundles, not just contract-bearing ones
- [ ] Both modals use red/blocked styling, not amber/info
- [ ] Both modals explain how to switch channels (remove existing allocations first)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] No other files modified

### What NOT to do

- Do NOT modify database schema — no triggers, no constraints, no migrations
- Do NOT change the cost model architecture — just remove the bypass
- Do NOT touch the cost calculation logic or budget views
- Do NOT add new props or change component interfaces
- Do NOT modify any other components besides the two listed
