# Session 4: Hooks — `useApplicationProfile` + `useApplicationNarrativeCache` + `useUpdatePortfolioPlan`

**Effort:** 1.5 hrs. **Prerequisite:** Session 3 merged (types available). **Committable:** yes — hooks compile but no component renders them yet.

## Goal

Create the three hooks that Session 5 will consume. No component integration yet.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` §Section 1 Session 4.
2. `src/hooks/useApplicationDetail.ts` — the existing pattern this session follows (Supabase `.from()` query, state shape, error handling).
3. `src/hooks/useApplicationCategories.ts` — small reference hook; good template for concise style.
4. `src/lib/supabase.ts` — the configured Supabase client import path.
5. `src/types/view-contracts.ts` — interfaces added in Session 3.
6. `CLAUDE.md` — especially error-handling patterns (try/catch + toast, revert on error).

## Rules

- **PAID = Plan / Address / Delay / Ignore.** Where the hooks type `paid_action`, use the string-literal union from Session 3 (not `string`).
- **Try/catch wraps every Supabase call.** Errors surface via toast (not console.log, not alert).
- **Prefer `unknown` over `any`.** Cast narrowly when the Supabase SDK returns `any`.

## Concrete changes

### 1. `src/hooks/useApplicationProfile.ts` (new)

Selects one row from `vw_application_profile` by `application_id`. Shape:

```typescript
import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { VwApplicationProfile } from '../types/view-contracts';

interface UseApplicationProfileResult {
  profile: VwApplicationProfile | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useApplicationProfile(applicationId: string | undefined): UseApplicationProfileResult {
  const [profile, setProfile] = useState<VwApplicationProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchProfile = useCallback(async () => {
    if (!applicationId) {
      setProfile(null);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const { data, error: fetchError } = await supabase
        .from('vw_application_profile')
        .select('*')
        .eq('application_id', applicationId)
        .maybeSingle();
      if (fetchError) throw fetchError;
      setProfile(data as VwApplicationProfile | null);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to fetch application profile';
      setError(message);
      setProfile(null);
    } finally {
      setLoading(false);
    }
  }, [applicationId]);

  useEffect(() => { fetchProfile(); }, [fetchProfile]);

  return { profile, loading, error, refetch: fetchProfile };
}
```

### 2. `src/hooks/useApplicationNarrativeCache.ts` (new)

Reads all narrative rows for an app, groups by `narrative_key`. Exposes mutations for update and approval. Does NOT call any generation Edge Function — that ships in Tier 2.

Key types:

```typescript
export type NarrativeKey =
  | 'plain_language_summary'
  | 'business_impact'
  | 'integration_summary'
  | 'time_paid_tension'
  | 'remediation_summary'
  | 'remediation_alignment';

export interface CachedNarrative {
  id: string;
  application_id: string;
  deployment_profile_id: string | null;
  narrative_key: NarrativeKey;
  content: string | null;
  generated_at: string | null;
  input_hash: string | null;
  approved: boolean;
  approved_by: string | null;
  approved_at: string | null;
}

export type NarrativeMap = Partial<Record<NarrativeKey, CachedNarrative>>;

interface UseApplicationNarrativeCacheResult {
  narratives: NarrativeMap;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  updateNarrative: (key: NarrativeKey, content: string, inputHash: string) => Promise<void>;
  approveNarrative: (key: NarrativeKey) => Promise<void>;
  computeInputHash: (key: NarrativeKey, profile: VwApplicationProfile) => string;
}
```

`updateNarrative` performs an upsert keyed by `(application_id, deployment_profile_id, narrative_key)` (the unique index from Session 1). `approveNarrative` sets `approved = true`, `approved_by = current user`, `approved_at = now()`.

`computeInputHash(key, profile)` is a pure function that hashes a narrative-specific subset of the profile. For now, implement the minimum:
- `plain_language_summary` → hash of `{application_name, acronym, short_description, business_outcome}`.
- `business_impact` → hash of `{criticality, business_fit, is_crown_jewel}`.
- `integration_summary` → hash of `{integration_count, upstream_count, downstream_count, critical_integration_count}`.
- `time_paid_tension` → hash of `{time_quadrant, paid_action, time_paid_tension_flag}`.
- `remediation_summary` → hash of `{remediation_status_rollup, linked_initiative_count, target_state}`.
- `remediation_alignment` → hash of `{time_quadrant, remediation_status_rollup, paid_action}`.

Use a simple hash — a stable JSON string or a tiny FNV-1a implementation. No need for cryptographic strength; just stable across renders.

### 3. `src/hooks/useUpdatePortfolioPlan.ts` (new)

Mutation hook for the Response Plan inline edit (Session 5) and the optional wizard panel (Session 5b). Accepts a `portfolioAssignmentId` and exposes `.update({ has_plan, plan_note, plan_document_url, planned_remediation_date })` that writes to `portfolio_assignments`.

```typescript
export interface PortfolioPlanUpdate {
  has_plan: boolean | null;
  plan_note: string | null;
  plan_document_url: string | null;
  planned_remediation_date: string | null; // ISO date
}

export function useUpdatePortfolioPlan(portfolioAssignmentId: string | undefined) {
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const update = useCallback(async (values: PortfolioPlanUpdate) => {
    if (!portfolioAssignmentId) throw new Error('portfolioAssignmentId required');
    setUpdating(true);
    setError(null);
    try {
      const { error: updateError } = await supabase
        .from('portfolio_assignments')
        .update(values)
        .eq('id', portfolioAssignmentId);
      if (updateError) throw updateError;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to update plan status';
      setError(message);
      throw err;
    } finally {
      setUpdating(false);
    }
  }, [portfolioAssignmentId]);

  return { update, updating, error };
}
```

### 4. Sanity test

Unit tests are optional (the repo doesn't have a hook-test harness today — don't introduce one unilaterally). Instead, wire the hook into a throwaway test component for a sitting-only smoke test:

```typescript
// Temporarily in any page you're developing:
const { profile, loading, error } = useApplicationProfile('<known-good-id>');
console.log({ profile, loading, error });
```

Verify in the browser dev server that the hook returns a populated row. Remove the test code before commit.

## Exit criteria

1. `cd ~/Dev/getinsync-nextgen-ag && npx tsc --noEmit` → zero errors.
2. The three hooks are importable — no circular imports, no missing types.
3. Smoke test in a throwaway component: `useApplicationProfile('<known-id>')` returns a profile; `useApplicationNarrativeCache('<known-id>')` returns an empty map (cache table is empty post-Session-1); `useUpdatePortfolioPlan(...).update(...)` updates a row in the dev DB and the updated values appear on re-fetch.
4. No `any` types in the new files (except when unavoidable at Supabase SDK boundaries).
5. No new `alert()` / `confirm()` usage anywhere.

## Git

- **Code repo:** commit on `feat/application-profile-tier-1`. Message: `feat: useApplicationProfile + useApplicationNarrativeCache + useUpdatePortfolioPlan (Session 4 of 6)`. Push.
- **Architecture repo:** no changes this session.

## Stuck?

- Supabase upsert on a composite unique key: use `.upsert(row, { onConflict: 'application_id,deployment_profile_id,narrative_key' })`. If the index is an expression index (from Session 1 using `COALESCE`), upsert may not match — fall back to read-then-update-or-insert in the hook.
- Error shape: Supabase errors have `.message`, `.code`, `.details`. Surface `.message` via toast; log the full object if unexpected.
