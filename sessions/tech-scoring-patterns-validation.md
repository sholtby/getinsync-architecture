# Tech Scoring Patterns — Architecture Validation Report

**Date:** 2026-03-08
**Architecture doc:** `features/assessment/tech-scoring-patterns.md` v1.0
**Validator:** Claude Code (Opus 4.6)
**Status:** Validation only — no code or schema changes made

---

## 1. Schema Compatibility

### Table Name Conflict — PASS

No table named `tech_scoring_patterns` exists in the current schema. Safe to create.

### FK on deployment_profiles — PASS (with note)

The proposed `tech_scoring_pattern_id UUID REFERENCES tech_scoring_patterns(id) ON DELETE SET NULL` is compatible with the existing `deployment_profiles` column set. The table already has ~35 columns; one more nullable FK is fine. The `ON DELETE SET NULL` semantics are correct — if a pattern is deleted, DPs retain their scores but lose provenance.

### CHECK Constraint on hosting_type — PASS

The proposed constraint:
```sql
CHECK (hosting_type IN ('SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop'))
```

Matches **exactly** the constraint on `deployment_profiles.hosting_type` (schema line 6194):
```sql
CONSTRAINT deployment_profiles_hosting_type_check CHECK (
  hosting_type = ANY (ARRAY['SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop'])
)
```

**Note:** The `hosting_types` reference table exists (lines 6317–6326) but contains no seeded data in the schema dump. The valid values are enforced only via CHECK constraints on `deployment_profiles`. The architecture doc's CHECK constraint is consistent with this pattern.

### T-Score Columns — ISSUE FOUND

**deployment_profiles has T01–T15** (15 columns), not T01–T14:
- `t01` through `t15` all exist (schema lines 6146–6157)
- Each has `CHECK (tNN >= 1 AND tNN <= 5)`
- The auto-calculate trigger fires on changes to `t01–t15` (line 12197)

**However, T15 is unused in scoring:**
- `auto_calculate_deployment_profile_tech_scores` only uses T01–T14 (line 1132: "Calculate tech_health now using t12, t13, t14 instead of t13, t14, t15")
- `calculate_tech_health()` weights sum to 100% across T01–T14 only
- T15 appears to be a legacy column that was superseded when T12–T14 were remapped

**Architecture doc is correct to exclude T15** from the scoring patterns table. T15 is vestigial on `deployment_profiles` and is not scored. No issue here — just documenting the context.

**Recommendation:** Add a one-line note to the architecture doc: *"T15 exists on deployment_profiles as a legacy column but is excluded from scoring patterns because it is not used by the auto-calculate trigger."*

### Column Names and Constraints — PASS

The proposed `t01`–`t14` columns with `CHECK (tNN BETWEEN 1 AND 5)` match the pattern on `deployment_profiles` exactly. The columns are nullable (no `NOT NULL`), which is correct — a pattern may not define all 14 values.

---

## 2. Applicability Rules Integration

### JSONB Structure — PASS

The architecture doc's documented structure matches exactly what the frontend parses.

**TypeScript interface** (`PortfolioAssessmentWizard.tsx`, lines 35–39):
```typescript
interface ApplicabilityRule {
  action: 'ask' | 'auto_score' | 'skip';
  value?: number;        // 1-5 when action='auto_score'
  reason?: string;       // Explanation text shown to user
}
```

**Lookup logic** (lines 122–129):
```typescript
const getFactorApplicability = (factor: AssessmentFactor, hostingType: string | null): ApplicabilityRule => {
  if (!hostingType || factor.factor_type !== 'technical') {
    return { action: 'ask' };
  }
  const rules = factor.applicability_rules || {};
  return rules[hostingType] || { action: 'ask' };
};
```

The JSONB is keyed by hosting type string (e.g., `"SaaS"`) with `{action, value?, reason?}` per key. Matches the doc's description precisely.

### Frontend Components That Read Applicability Rules

| File | Role | Lines |
|------|------|-------|
| `src/components/PortfolioAssessmentWizard.tsx` | Main assessment form — applies skip/auto_score/ask per factor | 122–129, 968–1022 |
| `src/hooks/useDeploymentProfileEditor.ts` | DP editor hook — fetches hosting_type | ~230 |
| `src/hooks/useAssessmentConfiguration.ts` | Admin CRUD for assessment factors (including applicability_rules JSONB) | Throughout |
| `src/components/AssessmentFactorsTab.tsx` | Admin factor list — shows "Applicability" button for technical factors | Throughout |
| `src/components/ApplicabilityRulesModal.tsx` | Admin editor for applicability rules — table of hosting types × actions | Lines 1–255 |

### Rendering Priority — PASS (with minor gap)

The architecture doc defines priority: `skip > auto_score > pattern_fill > manual`

The current frontend implements the first three levels:
1. **skip**: Factor hidden entirely (not rendered in wizard sidebar or main area)
2. **auto_score**: Blue lock icon + info box with reason text, score not editable (lines 968–1022)
3. **manual (ask)**: Dropdown/Likert scale, fully editable

**Gap:** There is currently **no "pattern_fill" rendering state**. The wizard only knows about `skip`, `auto_score`, and `ask`. The pattern pre-fill indicator (`📋 pattern` badge, "from pattern" label) is entirely new UI that must be added. This is expected — the doc describes a new feature — but the integration point is clear:

- **Where to add:** `PortfolioAssessmentWizard.tsx` between the auto_score check (line ~968) and the manual score rendering (line ~1030)
- **What to add:** A new rendering branch when `action === 'ask'` AND pattern provides a value: show the dropdown pre-filled with pattern value, add a subtle "from pattern" indicator, keep it editable

### Auto-Score Override System (Existing)

The override system (`ScoreOverrideModal.tsx`, `deployment_profiles.score_overrides` JSONB) allows admins to override auto-scored values. The architecture doc correctly states that pattern values are ignored for auto-scored factors — the existing override system is orthogonal and doesn't conflict.

---

## 3. RLS Pattern Compliance

### SELECT Policy — ISSUE FOUND

**Proposed:**
```sql
CREATE POLICY "Users can view scoring patterns in current namespace"
  ON tech_scoring_patterns FOR SELECT
  USING (namespace_id = get_current_namespace_id());
```

**assessment_factors SELECT policy:**
```sql
CREATE POLICY "Users can view assessment_factors in current namespace"
  ON assessment_factors FOR SELECT
  USING ((namespace_id = get_current_namespace_id()) OR check_is_platform_admin());
```

**Issue:** The proposed SELECT policy is **missing the `OR check_is_platform_admin()` fallback**. Platform admins managing the template namespace or switching between namespaces would be unable to view patterns unless they set their current namespace context first. This is inconsistent with the assessment_factors pattern and other admin-accessible tables.

**Fix:** Add `OR check_is_platform_admin()` to the USING clause of the SELECT policy.

### INSERT Policy — PASS

The proposed INSERT policy matches the assessment_factors INSERT policy pattern exactly:
```sql
WITH CHECK (
  namespace_id = get_current_namespace_id()
  AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id()))
);
```

### UPDATE Policy — PASS

Matches assessment_factors pattern with both USING and WITH CHECK clauses.

### DELETE Policy — PASS

Matches assessment_factors pattern.

### GRANT Statements — ISSUE FOUND

**Proposed:**
```sql
GRANT SELECT ON tech_scoring_patterns TO authenticated;
GRANT SELECT ON tech_scoring_patterns TO service_role;
```

**CLAUDE.md rule:** *"All new tables need: GRANT ALL TO authenticated, service_role"*

**Issue:** The proposed GRANTs are `SELECT`-only, but the CLAUDE.md standard requires `GRANT ALL`. RLS policies handle access control — the GRANT just needs to allow the `authenticated` role to perform operations. With SELECT-only GRANTs, even admin users (who pass the RLS INSERT/UPDATE/DELETE policies) would be blocked at the GRANT level.

**Fix:** Change to:
```sql
GRANT ALL ON tech_scoring_patterns TO authenticated, service_role;
```

### Overall INSERT Permission for "Save As Pattern" Flow — CONSIDERATION

The architecture doc (Section 6.3) describes a "Save as Scoring Pattern" flow where **any assessor** can save their assessment as a pattern. However, the INSERT RLS policy only allows **admins**.

This is either:
- (a) Intentional — only admins can create patterns, and "Save as" is admin-only. The doc's UX flow at 6.3 should clarify this.
- (b) An oversight — editors/stewards should be able to "Save as" pattern, requiring a less restrictive INSERT policy.

**Recommendation:** Clarify in the architecture doc whether "Save as Pattern" is admin-only or available to any assessor (editor+). If editor+, the INSERT RLS policy needs a broader role check.

---

## 4. Seed Trigger Pattern

### Template Namespace ID — PASS

Uses `'00000000-0000-0000-0000-000000000001'` — matches all other seed triggers.

### Function Structure — PASS

Follows the established pattern:
1. Check if template has data → RAISE NOTICE and return if not
2. INSERT INTO ... SELECT from template
3. RAISE NOTICE with count
4. RETURN NEW

Matches `copy_software_product_categories_to_new_namespace()` (lines 1716–1757) closely.

### software_product_id Handling — PASS

The seed trigger correctly sets `software_product_id` to `NULL` for copied patterns:
```sql
SELECT NEW.id, name, description, hosting_type, NULL,  -- No SP link for seeded patterns
```

This is correct because software products are namespace-scoped — a template namespace's software_product_id would not be valid in the new namespace.

### Seed Filter — PASS

The trigger filters by `AND is_seeded = true`, which ensures only the 6 base patterns (not any custom patterns in the template namespace) are copied. This is cleaner than the other triggers which copy everything indiscriminately.

### Trigger Registration Naming — MINOR INCONSISTENCY

Existing trigger names:
| Trigger Name | Function |
|---|---|
| `trigger_copy_assessment_factors_to_new_namespace` | `copy_assessment_factors_to_new_namespace()` |
| `trigger_copy_assessment_thresholds_to_new_namespace` | `copy_assessment_thresholds_to_new_namespace()` |
| `trigger_copy_service_types_to_new_namespace` | `copy_service_types_to_new_namespace()` |
| `trigger_copy_technology_categories_to_new_namespace` | `copy_technology_categories_to_new_namespace()` |
| `seed_software_product_categories` | `copy_software_product_categories_to_new_namespace()` |

The proposed trigger name `trigger_copy_scoring_patterns_to_new_namespace` follows the majority pattern (`trigger_copy_*`), which is fine. The `seed_software_product_categories` outlier is a naming inconsistency in the existing schema, not in the proposed design.

### SET search_path — PASS

Function includes `SET search_path TO 'public'` — matches the CLAUDE.md requirement for DEFINER functions.

---

## 5. Frontend Integration Points

### Primary Assessment Component

**File:** `src/components/PortfolioAssessmentWizard.tsx` (~1,100+ lines)

This is where all pattern-related UI changes need to happen:

| Feature | Integration Point | Line Range |
|---------|-------------------|------------|
| **Pattern suggestion banner** | Insert between header and first assessment section | After line ~670 (wizard header), before line ~780 (factor sections) |
| **Pattern pre-fill logic** | Extend `getFactorApplicability()` to return pattern value for `ask` factors | Lines 122–129 |
| **📋 pattern indicator** | New rendering branch alongside existing 🔒 auto indicator | Lines 968–1030 (add between auto_score and manual branches) |
| **Pre-filled dropdown value** | Modify score button rendering to show pattern default as selected | Lines 1030–1070 |
| **Pattern provenance tracking** | Save `tech_scoring_pattern_id` when writing assessment results | Wherever DP update call happens (search for `.update(` calls) |
| **"Save as Pattern" prompt** | Add after assessment completion | After the completion state handler |

### Hosting Type Detection

**Current flow:**
```
PortfolioAssessmentWizard receives assignment prop
→ assignment.deployment_profile.hosting_type (line 230)
→ Passed to getFactorApplicability() for each factor
```

This is already available and would also be used to query matching patterns.

### Software Product Link for Pattern Matching

The DP-to-software-product relationship goes through `deployment_profile_software_products` junction table. The wizard would need to:
1. Query `deployment_profile_software_products` for the current DP
2. Use the `software_product_id` to find product-specific patterns
3. Fall back to hosting-type-generic patterns

**Current code does NOT query `deployment_profile_software_products`** in the wizard. This is a new data fetch that must be added.

### Assessment Configuration Admin Page

**File:** `src/pages/settings/AssessmentConfiguration.tsx`

The Pattern Management admin UI (Section 6.4 of the doc) would be a new tab on this existing settings page:

| Existing Tab | Location |
|---|---|
| Business Factors | Lines 196–216 |
| Technical Factors | Lines 218–238 |
| Derived Scores | Lines 240–246 |
| Thresholds | Lines 248–254 |
| **Scoring Patterns (NEW)** | Add as 5th tab |

### Key Hooks

| Hook | File | Relevant For |
|------|------|-------------|
| `useAssessmentConfiguration` | `src/hooks/useAssessmentConfiguration.ts` | Assessment factor CRUD pattern — reuse for pattern CRUD |
| `useDeploymentProfileEditor` | `src/hooks/useDeploymentProfileEditor.ts` | DP update pattern — extend for `tech_scoring_pattern_id` |

---

## 6. Reusable Patterns

### Admin CRUD Page Pattern

`src/pages/settings/AssessmentConfiguration.tsx` + `src/components/AssessmentFactorsTab.tsx` provide the exact pattern for the Scoring Patterns admin tab:
- Tabbed settings layout
- Inline editing with save-on-blur
- Tier-gated access (`hasFeature('editAssessmentConfig')`)
- Modal for complex sub-editing (see `ApplicabilityRulesModal.tsx`)

### Namespace-Scoped Dropdown Picker

Three reusable patterns exist:

| Component | File | Pattern |
|-----------|------|---------|
| `ServiceTypePicker` | `src/components/ServiceTypePicker.tsx` | Grouped dropdown, namespace-scoped view query |
| `ContactPicker` | `src/components/ContactPicker.tsx` | Async search, namespace context from auth |
| `SearchableSelect` | `src/components/shared/SearchableSelect.tsx` | Generic combobox with client-side filter |

For the "Link to Software Product" dropdown in the Save As flow, `SearchableSelect` is the best fit — pass software products as options, client-side filter.

### Score Display Components

| Component | File | Reuse For |
|-----------|------|-----------|
| `AssessmentScoreCard` | `src/components/AssessmentScoreCard.tsx` | Pattern preview (show T-score values in card format) |
| `AssessmentScoreDisplay` | `src/components/AssessmentScoreDisplay.tsx` | Alternative score visualization |

### Table Pagination

`src/components/shared/TablePagination.tsx` — required for the Pattern Management grid (CLAUDE.md mandates pagination on all data tables).

### No Existing "Save As" / "Clone" Pattern

There is **no existing "Save As" action** anywhere in the codebase. The "Save as Scoring Pattern" flow would be the first of its kind. Closest analog is `ScoreOverrideModal.tsx` (a post-action modal that captures user input and writes to the DB).

---

## 7. Test Impact

### pgTAP RLS Coverage (`pgtap-rls-coverage.sql`)

**Current counts:**
| Category | Current | New | Delta |
|----------|---------|-----|-------|
| Tables | 93 | 94 | +1 |
| RLS enabled checks | 93 | 94 | +1 |
| Authenticated GRANT checks (tables) | 93 | 94 | +1 |
| Service-role GRANT checks (tables) | 93 | 94 | +1 |
| Audit trigger checks | 51 | 52 | +1 |
| Views | 30 | 30 | 0 |
| View security_invoker checks | 30 | 30 | 0 |
| Auth/service GRANT checks (views) | 30+30 | 30+30 | 0 |
| Sentinel checks | 3 | 3 | 0 |
| **Total assertions** | **425** | **429** | **+4** |

**Updates needed:**
1. Update `plan()` call: `94 + 94 + 94 + 52 + 30 + 30 + 30 + 3` = 427 (plan count, not assertion count — verify)
2. Add RLS enabled check for `tech_scoring_patterns`
3. Add authenticated GRANT check for `tech_scoring_patterns`
4. Add service_role GRANT check for `tech_scoring_patterns`
5. Add audit trigger check for `tech_scoring_patterns`
6. Update table sentinel: 93 → 94
7. Update audit trigger sentinel: 51 → 52

### Security Posture Validation (`security-posture-validation.sql`)

**Updates needed:**
1. Add `tech_scoring_patterns` to `expected_tables` array (currently 93 entries → 94)
2. Add `tech_scoring_patterns` to `expected_audit_tables` array (currently 51 entries → 52)
3. No view changes needed

### MEMORY.md / CLAUDE.md Schema Stats

Update after deployment:
```
Tables: 94 | RLS policies: 365 (+4) | Audit triggers: 52
```

---

## 8. Recommendations

### Must-Fix Before Build

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 1 | **SELECT RLS policy missing `OR check_is_platform_admin()`** | HIGH | Add `OR check_is_platform_admin()` to USING clause of SELECT policy |
| 2 | **GRANT is SELECT-only, should be GRANT ALL** | HIGH | Change to `GRANT ALL ON tech_scoring_patterns TO authenticated, service_role;` per CLAUDE.md standard |
| 3 | **Clarify "Save as Pattern" permissions** | MEDIUM | Decide: admin-only or editor+? If editor+, INSERT policy needs broader role check |

### Should-Fix Before Build

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 4 | **Add T15 context note** | LOW | One-line note explaining T15 is legacy/unused on DP, excluded from patterns intentionally |
| 5 | **Hosting types hardcoded in ApplicabilityRulesModal** | LOW (pre-existing) | The value `HOSTING_TYPES = ['SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop']` is hardcoded at line 20 of `ApplicabilityRulesModal.tsx`. Not a blocker for patterns, but should be noted as tech debt — a future migration to fetch from `hosting_types` table would benefit both features. |
| 6 | **`deployment_profile_software_products` query not in wizard** | INFO | The pattern matching hierarchy (Section 6.1) requires querying the DP↔software product junction table. This is a new data fetch — not currently done in `PortfolioAssessmentWizard.tsx`. |

### Architecture Doc Improvements (Optional)

| # | Suggestion |
|---|-----------|
| 7 | Section 4.4 — show the corrected SELECT policy with `OR check_is_platform_admin()` |
| 8 | Section 4.4 — show the corrected GRANT as `GRANT ALL` |
| 9 | Section 6.3 — explicitly state which roles can "Save as Pattern" (admin only, or editor+) |
| 10 | Section 4.1 — add comment noting T15 exclusion rationale |
| 11 | Section 9 (Implementation Phases) — note that Phase D requires a new hook/query for `deployment_profile_software_products` to power the pattern matching hierarchy |

---

## Appendix A: File Reference

| File | Purpose |
|------|---------|
| `src/components/PortfolioAssessmentWizard.tsx` | Main assessment wizard — primary integration point |
| `src/components/ApplicabilityRulesModal.tsx` | Admin rules editor — reference for hosting type values |
| `src/components/AssessmentFactorsTab.tsx` | Admin factor CRUD — reuse pattern for pattern CRUD |
| `src/components/ScoreOverrideModal.tsx` | Override modal — analog for "Save as Pattern" modal |
| `src/pages/settings/AssessmentConfiguration.tsx` | Settings page — add Scoring Patterns tab here |
| `src/hooks/useAssessmentConfiguration.ts` | Factor CRUD hook — reuse pattern for pattern hook |
| `src/hooks/useDeploymentProfileEditor.ts` | DP editor — extend for `tech_scoring_pattern_id` |
| `src/lib/factorMapping.ts` | Factor code ↔ column mapping |
| `src/lib/scoring.ts` | Scoring algorithms & weights |
| `src/types/index.ts` | TypeScript interfaces for assessments |
| `src/components/shared/SearchableSelect.tsx` | Reusable combobox — use for software product picker |
| `src/components/shared/TablePagination.tsx` | Pagination — required for pattern management grid |

---

*Validation performed: 2026-03-08*
*No code, schema, or branch changes were made during this validation.*
