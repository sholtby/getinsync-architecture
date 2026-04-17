# Session 6: Doc Alignment + Publish Assessment RPC Spec Reshape

**Effort:** 1–1.5 hrs. **Prerequisite:** Session 5 merged and shipped to `dev`. **Committable:** yes — docs only.

## Goal

Close the Tier 1 loop: update architecture docs to reflect what shipped, reshape the Publish Assessment RPC spec so `vw_application_profile` becomes the canonical per-app data shape, and document the EA Handoff auto-finding patterns for the (future) generation pipeline.

## Required reads (in order)

1. `docs-architecture/planning/application-profile/session-plan.md` — especially §Section 1 Session 6 and §Section 4 Publish Assessment RPC Alignment.
2. `docs-architecture/features/publish-assessment/architecture.md` — the RPC spec doc that gets reshaped here.
3. `docs-architecture/features/application-profile/schema-mapping.md` v1.1 — status transitions.
4. `docs-architecture/core/application.md`, `core/deployment-profile.md`, `core/involved-party.md` — core entity docs that need new-column cross-references.
5. `docs-architecture/guides/user-help/applications.md` (or equivalent) — user-facing docs that may need updating.
6. `docs-architecture/guides/whats-new.md` — append entry for every user-visible change (per CLAUDE.md).
7. `docs-architecture/MANIFEST.md` — bump + changelog.
8. `CLAUDE.md` — especially the "Architecture Docs Are Living Specs" rule.

## Rules

- **PAID = Plan / Address / Delay / Ignore.** Before commit: `grep -rn "Improve\|Divest" docs-architecture/` should find zero NEW occurrences. Pre-existing references are all already cleaned up (commit `7f51786`).
- **Dual-repo commit:** all changes in this session land in the architecture repo on `main`.
- **MANIFEST update is not optional.** Every doc change requires a MANIFEST bump + changelog entry.

## Concrete changes

### 1. Reshape `features/publish-assessment/architecture.md` §Step 1

Replace the existing per-app bundle description (§45–62) with a three-layer description:

> **The RPC returns a three-layer JSON:**
>
> 1. **`workspace_aggregates`** — TIME/PAID distribution counts, Crown Jewel count, assessment completion stats, publishing user, plus plan-coverage counts per quadrant (e.g., `eliminate_apps_without_plan_count`, `modernize_apps_with_target_date_count`, `address_apps_with_plan_no_initiative_count`).
> 2. **`applications[]`** — each entry is a row from `vw_application_profile` projected to JSONB. This is the canonical Application Profile shape, shared with the UI drawer. Includes plan-status (`has_plan`, `plan_note`, `plan_document_url`, `planned_remediation_date`).
> 3. **`applications[].assessment_detail`** — raw B1–B10 and T01–T15 factor values plus namespace-scoped factor labels from `assessment_factors`. Needed for the PDF factor tables; not surfaced in the UI drawer.

Mention that the RPC becomes thin:

```sql
SELECT jsonb_build_object(
  'workspace_aggregates', (SELECT ... FROM vw_application_profile WHERE workspace_id = $1),
  'applications',         (SELECT jsonb_agg(row_to_json(p))
                          FROM vw_application_profile p WHERE p.workspace_id = $1),
  'applications_assessment_detail', (SELECT ... FROM portfolio_assignments pa
                                     JOIN deployment_profiles dp ON ...
                                     WHERE ...)
);
```

### 2. Fix T14/T15 ambiguity in the same doc

The current doc references "T01–T14" in one or two spots. The schema has T01–T15 (confirmed in `schema/nextgen-schema-current.sql:7452`). Replace every T14 with T15 where the intent is the full factor range. Grep to find them:

```bash
grep -n "T14\|t14" docs-architecture/features/publish-assessment/architecture.md
```

### 3. Add the EA Handoff auto-finding patterns

In the same doc, under §System Prompt Strategy, add a new subsection "Plan-coverage findings" with these example patterns the Edge Function should be able to generate:

- `"N of M eliminate applications have no documented plan — governance review recommended."`
- `"N modernize applications have planned_remediation_date in the next 12 months; M have no target date."`
- `"N address applications have has_plan = true but no linked initiative — candidate for formal initiative creation."`
- `"N applications have has_plan = null — assessment is incomplete from a plan-status perspective."`

Note: the `workspace_aggregates` block should expose the counts so the Edge Function doesn't re-count.

### 4. Snapshot immutability note

Add to §Step 5: when `assessment_history.snapshot_data` is written on publish, include (a) the current `application_narrative_cache` rows for each app AND (b) the plan-status values at publish time — so snapshots are immutable regardless of future cache invalidation or plan edits.

### 5. Update `features/application-profile/schema-mapping.md`

- Status transitions: change Tier 1 fields from 🟡 to 🟢. Leave Tier 2 items (capabilities, data domains, tech debt items, narrative generation) at 🟡.
- Add "Tier 1 shipped 2026-MM-DD" note near the top.
- Add a cross-reference pointer to the session plan at `planning/application-profile/session-plan.md` v1.2.
- Bump version v1.1 → v1.2 (or whatever is current + 0.1).

### 6. Update core entity docs

- `core/application.md` — document new columns: `acronym`, `business_outcome`, `target_state`, `cost_notes`, `user_groups`, `estimated_user_count`.
- `core/deployment-profile.md` — cross-reference `vw_application_profile` as a composite projection.
- `core/involved-party.md` — document the new `accountable_executive` role on `application_contacts.role_type`.
- `catalogs/application-categories.md` (if exists) — note that categories now surface in the application profile view.

### 7. User docs + What's New

- `guides/user-help/*.md` — find the article(s) covering the application detail drawer. Update the screenshots/descriptions to reflect the new blocks (categories chips, Response Plan sub-section, etc.). Follow CLAUDE.md §6h pattern.
- `guides/whats-new.md` — append a dated entry summarizing user-visible changes: new drawer layout, category chips, Response Plan capture, plan-status visibility.

### 8. MANIFEST bump

- Bump version (e.g., v2.18 → v2.19).
- Update the session-plan entry status: add "Tier 1 shipped" note.
- Update the schema-mapping entry to the new version.
- Changelog entry: describe the Tier 1 ship at a one-paragraph level.

### 9. CalVer bump in the code repo

Per CLAUDE.md: when merging user-visible changes to `main`, bump CalVer in `package.json` (`2026.4.x` → `2026.4.x+1` or `2026.5.1` if month rolls over). Include in the merge commit or as `chore: bump version`.

## Exit criteria

1. `grep -rn "Improve\|Divest" docs-architecture/` → only the pre-approved "never use" directive lines from `features/application-profile/schema-mapping.md` and `planning/application-profile/session-plan.md`. Zero new content using the non-canonical terms.
2. `grep -rn "T14" docs-architecture/features/publish-assessment/architecture.md` → only in prose explicitly distinguishing T14 from T15 (otherwise gone).
3. MANIFEST version bumped, changelog entry present.
4. `docs-architecture/features/publish-assessment/architecture.md` §Step 1 describes the three-layer RPC output shape referencing `vw_application_profile`.
5. `docs-architecture/features/application-profile/schema-mapping.md` Tier 1 fields show 🟢.
6. `guides/whats-new.md` has a new dated entry.

## Git

- **Architecture repo:** one commit, message: `docs: Application Profile Tier 1 shipped — RPC spec reshape + doc alignment (Session 6 of 6)`. Push to `main`.
- **Code repo:** CalVer bump in `package.json` + the feature-branch merge to `dev`. After Session 6 completes and validates, merge `feat/application-profile-tier-1` into `dev`, push, then `dev` → `main` (Netlify auto-deploys). Standard CLAUDE.md flow.

## Stuck?

- If the publish-assessment doc has other stale content (beyond T14/T15 and the RPC reshape), note it and fix if quick; defer deeper edits to a separate session.
- If the user-help article for the drawer is significantly out of date beyond just new-block mentions, flag to Stuart rather than rewriting — wholesale user-docs refresh is not Tier 1 scope.
- Version numbering for `schema-mapping.md` and `session-plan.md`: follow the existing 0.1 increment pattern. Don't jump to v2.0 for doc updates.
