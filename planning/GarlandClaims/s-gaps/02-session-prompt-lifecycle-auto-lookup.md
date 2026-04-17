# Session Prompt 02 — Lifecycle Lookup: Remove Confirmation, Make Automatic

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 1-2 hours

---

## Task: Make the lifecycle intelligence lookup automatic — remove the user confirmation step

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation (Slide 6) claims: "When reference data doesn't exist, AI looks it up automatically."

Currently, the lookup is **user-initiated with confirmation**. When creating or editing a technology/software product, the user sees an "AI Lookup" button, clicks it, waits for results, reviews them, and then clicks "Apply & Link." We need to remove the review/confirm step — when a product is saved without lifecycle data, the lookup fires automatically and results are applied without a confirmation modal.

The `lifecycle-lookup` Edge Function (3-tier: DB cache → endoflife.date API → Claude extraction) is already deployed and working. This is purely a UI flow change.

### Hard rules

1. **Branch:** `fix/lifecycle-auto-lookup`. Create from `dev`.
2. **You MAY only modify:**
   - `src/components/TechnologyProductModal.tsx`
   - `src/components/SoftwareProductModal.tsx`
3. **Do NOT modify the Edge Function** (`supabase/functions/lifecycle-lookup/`).
4. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
5. **Graceful degradation is mandatory** — if the lookup fails or returns `found: false`, the product saves normally without lifecycle data. Never block product creation on a failed lookup.
6. **Keep the manual "AI Lookup" button as a fallback** — users should still be able to trigger a lookup for existing products that missed the auto-lookup.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/lifecycle-intelligence.md
   - §6.1 — current lookup flow
   - §2 — the 3-tier pipeline description

2. src/components/TechnologyProductModal.tsx (full file, ~1300 lines)
   Focus on:
   - handleAiLookup() — lines ~528-552 (triggers the Edge Function call)
   - handleApplyAiResult() — lines ~554-594 (upserts to technology_lifecycle_reference, links to product)
   - The AI lookup results modal — lines ~1167-1297 (the confirmation UI we're removing)
   - handleSave() / form submission — find where the product is saved to DB
   - lifecycleMode state — controls which UI is shown

3. src/components/SoftwareProductModal.tsx (full file, ~700 lines)
   Focus on:
   - Same pattern as TechnologyProductModal but for software products
   - handleAiLookup() — lines ~480-530
   - handleApplyAiResult() — lines ~530-570
   - The confirmation UI block

4. supabase/functions/lifecycle-lookup/index.ts (read-only, for reference)
   - Request interface: { vendor, product, version?, edition? }
   - Response interface: { found, confidence, source, data?, alternatives? }
```

### Step 2 — Impact analysis

```bash
grep -r "handleAiLookup\|handleApplyAiResult\|lifecycleMode\|aiLookupResult" src/ --include="*.tsx" --include="*.ts"
grep -r "lifecycle-lookup" src/ --include="*.tsx" --include="*.ts"
```

Confirm these functions are only used within the two modal components.

### Step 3 — Modify TechnologyProductModal.tsx

**3a. Add auto-lookup to the save flow:**

Find the product save/submit handler. After the product is successfully saved to the database (upsert to `technology_products`), add this logic:

```
If the saved product has NO lifecycle_reference_id:
  1. Extract vendor, product name, version, edition from the form data
  2. If vendor AND product name are present (minimum required for lookup):
     a. Call the lifecycle-lookup Edge Function (same code as handleAiLookup)
     b. If response.found === true AND response.confidence !== 'low':
        - Call handleApplyAiResult() to upsert the reference and link it
        - Show a success toast: "Lifecycle data found and linked automatically"
     c. If response.found === false OR confidence === 'low':
        - Show an info toast: "No lifecycle data found — you can look it up later via AI Lookup"
        - Do NOT block — product is already saved
     d. If the Edge Function call fails (network error, timeout):
        - Show a warning toast: "Lifecycle lookup failed — you can try again via AI Lookup"
        - Do NOT block — product is already saved
  3. If vendor or product name are missing, skip the lookup silently
```

**3b. Keep the manual "AI Lookup" button:**
The existing button and `handleAiLookup()` function stay as-is for cases where:
- Auto-lookup failed and user wants to retry
- User edited a product and wants to refresh lifecycle data
- Product was created before this feature existed

**3c. Simplify the confirmation UI (optional but recommended):**
The results modal (lines ~1167-1297) currently shows full results with "Apply & Link" / "Cancel" buttons. Since auto-lookup now handles the happy path, this UI is only needed for manual retrigger. You can simplify it:
- Keep the results display
- Change "Apply & Link" to "Apply" (shorter label)
- Keep "Cancel"
- This is the fallback for manual lookups, so the confirm step is fine here

**3d. Handle the `low` confidence threshold:**
Auto-apply only when confidence is `high` or `medium`. For `low` confidence results, show a toast suggesting manual review: "Lifecycle data found with low confidence — use AI Lookup to review before applying." This prevents bad data from silently entering the system.

### Step 4 — Modify SoftwareProductModal.tsx

Apply the same pattern as Step 3. The SoftwareProductModal has the same lifecycle lookup flow — find its save handler, add the auto-lookup logic after successful save, keep the manual button as fallback.

### Step 5 — Test the flows mentally

Trace through these scenarios:

1. **New tech product with vendor + name:** Save → auto-lookup fires → lifecycle data found (high confidence) → linked automatically → success toast
2. **New tech product, no vendor:** Save → auto-lookup skipped → product saved normally
3. **New tech product, vendor + name but no lifecycle data exists:** Save → auto-lookup fires → `found: false` → info toast → product saved without lifecycle
4. **New tech product, lookup returns low confidence:** Save → auto-lookup fires → low confidence → toast suggests manual review → product saved without lifecycle
5. **Edge Function timeout:** Save → auto-lookup fires → network error → warning toast → product saved without lifecycle
6. **Existing product, user clicks "AI Lookup" manually:** Same flow as today (results modal → Apply → linked)
7. **Product already has lifecycle_reference_id:** Save → auto-lookup skipped (already has data)

### Step 6 — Type check

```bash
npx tsc --noEmit
```

Must pass with zero errors.

### Step 7 — Update architecture doc

Update `docs-architecture/features/technology-health/lifecycle-intelligence.md`:
- §6.1: Change description from "user-initiated with confirmation" to "automatic on product save"
- Note that manual "AI Lookup" button remains as fallback
- Note the confidence threshold (low confidence → manual review suggested)

### Step 8 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/TechnologyProductModal.tsx src/components/SoftwareProductModal.tsx
git commit -m "fix: auto-trigger lifecycle lookup on product save (remove confirmation step)

When a technology or software product is saved without lifecycle data,
the lifecycle-lookup Edge Function is called automatically. High/medium
confidence results are applied immediately. Low confidence results prompt
manual review via the existing AI Lookup button.
Closes Garland audit yellow flag (Slide 6, 'automatically')."
git push -u origin fix/lifecycle-auto-lookup
```

Also commit the architecture doc update:
```bash
cd ~/getinsync-architecture
git add features/technology-health/lifecycle-intelligence.md
git commit -m "docs: update lifecycle-intelligence — auto-lookup on save, manual fallback"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] TechnologyProductModal: auto-lookup fires after save when no lifecycle_reference_id
- [ ] SoftwareProductModal: same auto-lookup behavior
- [ ] High/medium confidence results auto-applied with success toast
- [ ] Low confidence results show info toast suggesting manual review (NOT auto-applied)
- [ ] Lookup failures show warning toast but don't block product save
- [ ] Missing vendor/product name skips lookup silently
- [ ] Manual "AI Lookup" button still works as fallback
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] Architecture doc updated
- [ ] No other files modified

### What NOT to do

- Do NOT modify the `lifecycle-lookup` Edge Function
- Do NOT remove the manual "AI Lookup" button — it's the fallback
- Do NOT auto-apply low-confidence results — those need human review
- Do NOT block product creation if the lookup fails
- Do NOT add new API endpoints or database tables
- Do NOT touch `LinkedTechnologyProductsList.tsx` — that's the DP-linking flow, not the product catalog flow
