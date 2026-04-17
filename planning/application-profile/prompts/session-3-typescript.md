# Session 3: TypeScript Interfaces + View-Contract Cleanup

**Effort:** 1–1.5 hrs (2 hrs if #96 included). **Prerequisite:** Session 2 merged. **Committable:** yes — additive types, no runtime changes.

## Goal

Declare `VwApplicationProfile` in `src/types/view-contracts.ts` so the next session's hook and eventual drawer can consume the view with type safety. Fix two pre-existing view-contract gaps while in this file. Optionally split `src/types/index.ts` if sizing warrants.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` §Section 1 Session 3 — scope and prerequisites.
2. `docs-architecture/features/application-profile/vw_application_profile.sql` — deployed view; the interface must match its output columns exactly.
3. `src/types/view-contracts.ts` (full file) — existing interfaces. Follow the style/naming conventions.
4. `src/types/index.ts` (just skim length + identify the deployment-profile and server interfaces for the potential #96 split).
5. `supabase/functions/ai-chat/tools.ts` line ~800 — uses `vw_application_run_rate` without an interface; we fix that here.
6. Current state of `ServerTechnologyReportRow` in `view-contracts.ts` — has phantom `workspace_id`, `workspace_name` (open item #97).
7. `CLAUDE.md` — especially the view-to-TypeScript contract rule and impact analysis rule.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** In any TypeScript string-union type describing `paid_action` values, use only these four.
- **Impact analysis before touching shared interfaces.** After editing `view-contracts.ts`, run `grep -r "ServerTechnologyReportRow" src/` and update any consumers whose props change.
- **Strict types.** Prefer `string | null` / `number | null` over `any`. For `paid_action` and `time_quadrant`, use string-literal unions so callers get autocomplete.

## Concrete changes

### 1. Add `VwApplicationProfile` interface

In `src/types/view-contracts.ts`, add an exported interface whose shape mirrors `vw_application_profile` field-for-field. Key fields:

```typescript
export type TimeQuadrant = 'tolerate' | 'invest' | 'modernize' | 'eliminate';
export type PaidAction = 'plan' | 'address' | 'delay' | 'ignore';
export type AssessmentCompletenessRollup = 'complete' | 'partial' | 'not_started';
export type RemediationStatusRollup = 'in_progress' | 'planned' | 'completed' | 'none_planned';

export interface ApplicationCategoryTag {
  category_code: string;
  category_name: string;
}

export interface VwApplicationProfile {
  // Identity
  application_id: string;
  namespace_id: string;
  workspace_id: string;
  application_name: string;
  acronym: string | null;
  short_description: string | null;
  operational_status: string | null;
  management_classification: string | null;
  csdm_stage: string | null;
  is_internal_only: boolean | null;

  // Business Purpose
  business_outcome: string | null;
  category_names: ApplicationCategoryTag[]; // non-null; empty array when no categories

  // User Community
  user_groups: unknown | null; // JSONB — refine once the shape stabilizes
  estimated_user_count: '<10' | '10-100' | '100-1000' | '1000+' | null;
  serving_area: string | null; // applications.branch

  // Ownership
  business_owner_contact_id: string | null;
  business_owner_name: string | null;
  application_owner_contact_id: string | null;
  application_owner_name: string | null;
  accountable_executive_contact_id: string | null;
  accountable_executive_name: string | null;
  technical_contact_id: string | null;
  technical_contact_name: string | null;

  // Criticality
  criticality: number | null;
  is_crown_jewel: boolean;

  // Lifecycle Position
  time_quadrant: TimeQuadrant | null;
  paid_action: PaidAction | null;
  lifecycle_status: string | null;
  time_paid_tension_flag: boolean;

  // Response Plan (v1.2)
  has_plan: boolean | null;          // tri-state
  plan_note: string | null;
  plan_document_url: string | null;
  planned_remediation_date: string | null; // ISO date string

  // Application Context
  upstream_count: number;
  downstream_count: number;
  integration_count: number;
  critical_integration_count: number;

  // Cost
  annual_licensing_cost: number | null;
  annual_tech_cost: number | null;
  total_cost_of_ownership: number | null;
  cost_notes: string | null;

  // Tech Debt & Remediation
  tech_debt_description: string | null;
  remediation_effort: string | null;
  linked_initiative_count: number;
  remediation_status_rollup: RemediationStatusRollup;
  estimated_remediation_cost_low: number | null;
  estimated_remediation_cost_high: number | null;
  target_state: string | null;

  // Assessment Context
  business_fit: number | null;
  tech_health: number | null;
  tech_risk: number | null;
  near_threshold_flag: boolean;
  latest_assessed_at: string | null;
  assessment_completeness_rollup: AssessmentCompletenessRollup;
  assessed_at: string | null;
  business_assessed_at: string | null;

  // Primary DP context
  primary_deployment_profile_id: string | null;
  environment: string | null;
  hosting_type: string | null;
  cloud_provider: string | null;
  region: string | null;
  dr_status: string | null;
  server_name: string | null;
  data_center_id: string | null;
  contract_end_date: string | null;
  renewal_notice_days: number | null;
  vendor_org_id: string | null;
}
```

**Verify the field list matches the deployed view.** Connect to the read-only DB:

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -c "\d vw_application_profile"
```

Any column present in the view but missing from the interface → add it. Any column in the interface not in the view → remove it. The view is the source of truth.

### 2. Add `VwApplicationRunRate`

Find the existing column list:

```bash
psql "$DATABASE_READONLY_URL" -c "\d vw_application_run_rate"
```

Add a matching interface. Update `supabase/functions/ai-chat/tools.ts` imports if it uses untyped access today.

### 3. Fix `ServerTechnologyReportRow` (closes #97)

Remove `workspace_id` and `workspace_name` from the interface — they don't exist in `vw_server_technology_report` (which groups by `server_id` + `namespace_id`). Then run `grep -r "ServerTechnologyReportRow" src/` to confirm the components adapted in the Apr 12 fix (see open-items matrix) don't reference the removed fields.

### 4. Optional: #96 — split `src/types/index.ts`

Only do this if, after all other Session 3 edits, `src/types/index.ts` is still past 800 lines AND the split can be done without touching interfaces this session's hook/drawer work depends on. Split plan (from the open-items matrix):

- `src/types/deployment-profiles.ts` — `DeploymentProfile`, `DpSummary`, related.
- `src/types/servers.ts` — `Server`, `ServerRoleType`, `DeploymentProfileServer`.
- `src/types/index.ts` — keep as a barrel that re-exports everything so no caller imports change.

If any doubt, **defer this to a separate session**. Splitting files is a blast-radius change; the rest of Session 3 is additive.

## Exit criteria

1. `cd ~/Dev/getinsync-nextgen-ag && npx tsc --noEmit` → zero errors.
2. `grep -rn "VwApplicationProfile" src/` finds the export in `view-contracts.ts` and no callers yet (Session 4 adds them).
3. `grep -rn "ServerTechnologyReportRow" src/` — all consumers still compile (they adapted in the Apr 12 fix).
4. If #96 included: barrel `index.ts` still exports the old names; no caller's import statements change.

## Git

- **Code repo:** commit on `feat/application-profile-tier-1`. Message: `feat: VwApplicationProfile interface + view-contract cleanup (Session 3 of 6)`. Push.
- **Architecture repo:** no changes this session.

## Stuck?

- View-to-TypeScript contract mismatch pattern: CLAUDE.md "View-to-TypeScript Contract Rule" — the view is always the source of truth.
- If the view has a column the interface doesn't need (e.g., internal diagnostic column), still declare it in the interface — completeness matches the deployed shape.
