# Phase 0 — Riverside demo data enrichment SQL

These scripts close the data gaps identified in `../../../planning/gitbook-phase-0-readiness.md` (§2.1, §2.4, §4.2, §4.3, §1.4) so that four user-help articles have realistic content to screenshot before publication to docs.getinsync.ca.

**These SQL files touch LIVE demo data in production Supabase. Read every chunk before pasting.**

## What these scripts do NOT do

- They do NOT create, alter, or drop any schema (no tables, columns, indexes, constraints, policies).
- They ONLY `INSERT` or `UPDATE` into existing tables, within the Riverside namespace (`a1b2c3d4-e5f6-7890-abcd-ef1234567890`).
- Every `INSERT`/`UPDATE` is idempotent — re-running a chunk simply no-ops the second time.
- Every mutation chunk is wrapped in `BEGIN;` / `COMMIT;` with a verification `SELECT` before `COMMIT`.

## Execution order

Run in Supabase SQL Editor, top to bottom. Chunks are independently runnable and independently rollback-able.

| # | File | Mandatory? | Article / Purpose |
|---|------|------------|-------------------|
| 0 | `00-verify-state-before.sql` | Run first | Baseline snapshot (read-only) |
| 1 | `01-app-contacts-showcase.sql` | Yes | 2.1 Managing Applications |
| 2 | `02-integrations-dp-alignment.sql` | Yes | 2.4 Managing Integrations |
| 3 | `03-workspace-budgets-fy2026.sql` | Yes | 4.2 Understanding IT Spend |
| 4 | `04-it-service-contracts.sql` | Yes | 4.3 Cost Analysis (IT service channel) |
| 5 | `05-deployment-profile-ops-fields.sql` | **Optional** | 1.4 Deployment Profiles (on-prem depth) |
| 6 | `06-cost-bundle-dps-showcase.sql` | Yes | 4.3 Cost Analysis (Cost Bundle channel) |
| 7 | `07-it-service-vendor-attribution.sql` | Yes (post-Phase-0 repair) | AI Chat vendor-spend analysis — closes GAP 6 (Unknown: $2.56M) |
| 99 | `99-verify-state-after.sql` | Run last | Post-enrichment snapshot (read-only) |

> **Chunk 07 note:** Chunk 07 is a post-Phase-0 data repair added 2026-04-10 after AI Chat harness testing surfaced that IT services had 100% NULL `vendor_org_id`, forcing vendor cost analysis to report "Unknown (IT Service): $2.56M" (73% of namespace spend). Cost bundles already had vendor attribution post-Phase-0; IT services did not. Chunk 07 closes this gap. The baseline (00) and after (99) verifier files were written before chunk 07 existed — they do not include a `07 baseline/result` section. Chunk 07's own trailing verification SELECT is sufficient for validation.

## Workflow

1. Paste `00-verify-state-before.sql` into the SQL Editor and run. Save the output for diffing.
2. For each mandatory chunk (01, 02, 03, 04, 06), paste the file, review the verification `SELECT` output that appears immediately before the `COMMIT`, then commit. The `BEGIN; ... COMMIT;` block lets you cancel a chunk if the verification row looks wrong.
3. Chunk 05 is optional — only run it if article 1.4 needs to showcase on-prem operational depth. Note its `-- NOTE:` comment about team IDs being left NULL.
4. Run `99-verify-state-after.sql` and diff against the baseline. Expected AFTER counts are listed inside the file.

## Rollback

Every chunk has a `-- Rollback:` comment at the bottom naming the exact `DELETE` / `UPDATE` statements needed to undo it. These are commented-out — they are for reference, not automated rollback. To undo a chunk, copy its rollback line, wrap it in `BEGIN; ... COMMIT;` yourself, and run.

## Scope boundaries

- Every mutation is scoped to Riverside demo IDs. No statement can reach into another namespace.
- All seeded contacts use fictional names and `@riverside-demo.example` email addresses.
- No real PII. No real credentials. No real phone numbers.
- Chunk 06 also seeds one new vendor org (`CentralSquare Technologies`) inside the Riverside namespace — see the file header for details.

## Related docs

- Readiness report: `../../gitbook-phase-0-readiness.md`
- Cost model (cost bundle semantics): `../../../features/cost-budget/cost-model.md` §3.3, §12
- Schema source of truth: `../../../schema/nextgen-schema-current.sql`
