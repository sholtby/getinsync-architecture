# TDX Connector — NextGen Build Plan

> **Status: DRAFT** — pre-workshop working draft for the May 14, 2026 Garland session.
> **Date:** 2026-04-18
> **Audience:** Internal (Stuart, future Claude Code implementation sessions).
> **Companion docs:** `tdx-tenant-prep-spec.md` (Garland-facing) and `tdx-api-investigation-log.md` (internal reference). Sections of the investigation log that this plan most depends on: §5.1 (Authentication), §5.2 (Rate limits), §5.3 (CI CRUD — the no-upsert constraint that drives the mapping table), §5.4 (Relationship operations — the no-custom-attributes-on-relationships constraint that drives the v1 integration-modelling choice), and §6 (Gotchas and unknowns).
> **Also referenced:** `core/composite-application.md` — for NextGen's Platform Host / Platform Application suite model (Q4, §Relationship pushes, Phase 3).

---

## Executive summary

Garland is a current GetInSync customer on the OG platform, migrating to TeamDynamix (TDX) for ITSM. NextGen will eventually replace OG for Garland, and when it does, NextGen will push application-portfolio data into TDX as Configuration Items. This document is the internal build plan for that outbound connector.

The connector is outbound-only for v1: NextGen writes to TDX, TDX does not write back. It pushes **one CI per NextGen Application** — a "best-of-portfolio" roll-up that hides NextGen's Deployment Profile detail. Integration edges are pushed as TDX CI relationships, with the richer edge metadata (direction, method, frequency, sensitivity) remaining GetInSync-internal because TDX relationships cannot carry custom attributes.

The connector runs as a Supabase Edge Function on the NextGen side. It authenticates to each customer's TDX tenant via `/api/auth/loginadmin` using per-workspace credentials stored in Supabase Vault. It is triggered by publish events, a scheduled nightly delta, and a manual button. It throttles itself well under TDX's per-endpoint rate limits and maintains a durable `NextGen Application ID → TDX CI ID` mapping because TDX does not support search-by-ExternalID.

Garland must be migrated from OG to NextGen before this connector activates for them. That migration is a hard dependency, not solved here. Garland's TDX tenant must also complete the prep described in the companion tenant-prep spec before any push can succeed.

---

## Scope

### In scope

- Outbound push of NextGen Applications → TDX Configuration Items of a custom "Business Application" CI type
- Outbound push of NextGen integration edges → TDX CI relationships
- Outbound push of suite parent/child relationships (for composite Applications) → TDX CI relationships
- Per-workspace configuration (TDX tenant URL, BEID, WebServicesKey, target Asset/CI App, target CI Type ID)
- Delta sync, retry, and audit logging
- Admin UI for configuring the connector per workspace

### Explicitly out of scope

- Inbound sync (TDX → NextGen) — not v1
- Ticket read-through (surfacing TDX incidents/changes in NextGen) — future work
- Deployment Profile publishing to TDX — DPs stay GetInSync-internal
- Sassafras data-space writes — GetInSync does not write into Sassafras-populated CI types
- Infrastructure / server CI publishing — the DP-Infrastructure ADR boundary holds; TDX (and Sassafras, and any discovery tool Garland chooses) owns hostnames, IPs, and operational CI attributes
- CSDM mapping — TDX has no CSDM equivalent. The connector is TDX-native.

---

## NextGen-side architecture

### Where the connector lives

**Supabase Edge Function** at `supabase/functions/tdx-connector/`. Rationale:

- Follows the existing pattern set by `supabase/functions/ai-chat/`
- Inherits the `supabase/config.toml` / `verify_jwt = false` rule (see `CLAUDE.md` Edge Functions section) — the connector does its own JWT verification via `_shared/auth.ts` for inbound admin-UI triggers, and uses service-role keys for background work
- Network egress to `*.teamdynamix.com` is permitted from Edge Functions
- Scales horizontally per tenant without needing a long-running worker

### Data source

**Canonical source:** `public.vw_explorer_detail` (pre-joined across applications, portfolio_assignments, deployment_profiles, application_contacts, and `vw_application_run_rate`). Every custom field Doc 2 asks Garland to provision comes from this view, plus a few standard `ConfigurationItem` columns. One row per Application.

**Supplementary source:** `public.vw_application_integration_summary` and `public.application_integrations` for integration edges. The connector filters edges to those whose `source_application_id` and `target_application_id` both map to TDX CIs (i.e., both ends are Applications that have been published).

**Not read:** Deployment Profile detail, server tables, technology lifecycle history, assessment factor scores (B-scores, T-scores). These are NextGen-internal.

### Triggers

Three independent triggers feed the same queue:

1. **Publish-event trigger.** When key Application or primary Deployment Profile fields change (name, operational_status, owner, assessment scores, cost, integration count), a database trigger enqueues a sync row. Scoped at Application granularity — one sync row per dirty Application, regardless of how many columns changed.
2. **Scheduled delta.** A cron-invoked Edge Function run (nightly during off-hours) sweeps for Applications whose `updated_at` or downstream view output changed since the last successful sync for the workspace. Catches edge cases the publish trigger might miss (e.g., recomputed derived values).
3. **Manual trigger.** Admin UI button per workspace: "Sync now" for the full portfolio, or per-Application "Sync this app" for spot-check / reprovisioning. Writes a sync row with `trigger='manual'` and the invoking user's ID.

Triggers never write directly to TDX. They write to `tdx_sync_queue`. The Edge Function drains the queue.

### State store

Four NextGen-side tables (design sketch — not implemented in this session):

- **`tdx_ci_mappings`** — the NextGen ↔ TDX bridge.
  - `workspace_id`, `application_id` (NextGen UUID), `tdx_ci_id` (TDX integer), `content_hash` (sha256 of the last-pushed payload), `last_synced_at`, `last_success_at`, `last_attempt_at`.
  - Uniqueness: `(workspace_id, application_id)`.
  - This table is what makes idempotent updates possible given TDX's no-search-by-ExternalID constraint.

- **`workspace_tdx_config`** — per-workspace connector configuration.
  - `workspace_id` (primary key), `tdx_base_url`, `tdx_asset_app_id`, `tdx_ci_type_id`, `beid_vault_ref`, `web_services_key_vault_ref`, `is_active`, `created_by`, `created_at`, `updated_at`.
  - Secrets (BEID, WebServicesKey) are stored in Supabase Vault; the table holds only the Vault reference IDs.

- **`tdx_sync_queue`** — pending work.
  - `id`, `workspace_id`, `application_id`, `trigger` (event | scheduled | manual), `enqueued_at`, `attempts`, `next_attempt_at`, `status` (pending | in_flight | done | failed).
  - A partial index on `(status, next_attempt_at)` keeps the drain query cheap.

- **`tdx_sync_log`** — audit trail.
  - `id`, `workspace_id`, `application_id`, `correlation_id`, `attempt`, `http_method`, `http_status`, `tdx_ci_id`, `payload_hash`, `response_snippet`, `error_code`, `duration_ms`, `created_at`.
  - One row per HTTP call to TDX. Retained per SOC2 retention policy.

### Queueing and rate-limit strategy

**Ceiling:** 30 requests per 60-second window per endpoint class. Against TDX's documented limits this works out to roughly 12.5% of the 240/60s CI-create ceiling but **~50% of the stricter 60/5s CI-update ceiling** — the update endpoint is the actual constraint. v1 picks the conservative floor intentionally: breach behaviour is `[UNKNOWN]` (Doc 3 §5.2), the penalty for under-running is just slower first-time population, and the penalty for over-running could be opaque throttling or account-level action. Once Phase 4 captures real 429 responses we can raise the ceiling with data.

**Token-bucket per endpoint class** (CI create / CI update / relationships / search / people-lookup). Buckets live in a small in-memory structure inside the Edge Function invocation. The scheduled delta and publish-event processors are the same code path — they both drain `tdx_sync_queue` and respect the same buckets.

**Per-call pacing:** between calls the connector sleeps to `(60s / bucket_capacity) - rtt`. Cheaper than reactive 429 handling.

**Auth token reuse:** the admin token from `/api/auth/loginadmin` is obtained once per Edge Function invocation and held in-memory for the life of that invocation. On 401 from any call, re-authenticate once and retry; a second 401 is a hard failure.

### Error handling and retry

- Every TDX HTTP call wrapped in try/catch; response status and body snippet logged to `tdx_sync_log`.
- Transient failures (429, 503, 504, network timeout): enqueue retry with exponential backoff (30s → 2m → 10m). Max 3 attempts; after that, move to `status='failed'` and notify workspace admin via the existing notification pattern.
- Hard failures (400, 403, 404 on a TDX ID we believed valid): do not retry automatically. Log and notify. A 404 on a known `tdx_ci_id` `[INFERENCE]` means the CI was deleted from TDX (TDX's docs don't explicitly specify the 404 vs 410 distinction for deleted CIs, so we treat 404 as authoritative) — the mapping row is marked `invalidated=true` and the next sync for that Application will create a fresh CI.
- Rate limit detection: TDX's breach response is `[UNKNOWN]` (see Doc 3 §5.2 and §6) — whether 429 + `Retry-After` is used, or a different code/header, is not documented. The connector treats any 429 or unexpected 5xx as rate-limited, backs off with bounded jitter, and logs the response headers verbatim on first occurrence so the actual TDX signal can be captured and the logic refined.
- Auth response shape: the `Token` field name in the `/api/auth/loginadmin` response body is assumed `[INFERENCE]` from common TDX client patterns; the exact response schema is thin in the public docs. The connector reads the JWT from `Authorization: Bearer ...` in a test call and logs the response body on first successful login so the real shape is captured.

**Queue backpressure.** If `tdx_sync_queue` depth for a workspace exceeds a threshold (tentative: 5,000 pending items), the connector sets a `workspace_tdx_config.paused_at` flag and stops enqueuing new work. Both the publish-event trigger and the scheduled delta honour the pause flag. Manual "Sync this app" calls still work — they bypass the queue. The admin is notified and the pause is lifted manually once the underlying issue is resolved. This prevents a prolonged TDX outage (or a credential revocation that nobody notices) from producing unbounded queue growth. The 5,000 ceiling is a placeholder; actual value tuned during Phase 4.

### Operational visibility

Per-workspace connector health is surfaced inside NextGen (not inside TDX — TDX users only see the resulting CIs, not the sync machinery):

- **TDX Sync admin panel** (new, in the workspace admin UI): last successful sync timestamp, queue depth, failed-sync count in the last 24 hours, recent `tdx_sync_log` entries (most recent 50). A "Run readiness check" button re-runs the tenant-prep validation from Phase 0. A "Force full resync" button enqueues every Application in the workspace.
- **Per-Application sync indicator** (on the Application detail page, visible to anyone who can see the Application): a small badge showing last-synced timestamp, and — if the last sync failed — a short error summary with a link to the full log entry for workspace admins.
- **Daily email digest** of failed syncs to workspace admins. One email per workspace per day if there are failures; no email if everything synced cleanly.
- **Audit-table retention:** `tdx_sync_log` rows retained per SOC2 retention policy (90 days hot, archived thereafter — align with existing `audit_logs` retention).

Implementation details (table layouts, RLS policies, digest-email templates) are deferred to the implementation session; this section pins the feature set so it doesn't get accidentally dropped during phase planning.

### Authentication to TDX

- **Endpoint:** `POST {tdx_base_url}/api/auth/loginadmin`
- **Body:** `{ BEID, WebServicesKey }`
- **Response:** `{ Token, ... }` — Bearer JWT. Token TTL is `[UNKNOWN]` in TDX's public docs (see Doc 3 §5.1); v1 assumes ~24 hours but does not rely on that assumption — the connector re-authenticates on any 401 regardless of how long the token has been held.
- **Storage:** BEID and WebServicesKey stored in Supabase Vault. The `workspace_tdx_config` table holds only the Vault reference IDs. Access to the Vault refs is gated by RLS on `workspace_tdx_config` (workspace admins only).
- **Rotation:** admins rotate the WebServicesKey from TDAdmin → Organization Details and update the Vault secret via the connector admin UI. No automated rotation in v1.
- **Failure mode if credentials are wrong:** `/api/auth/loginadmin` returns 401; connector marks `workspace_tdx_config.is_active = false` and notifies the admin. No sync attempts are made on a disabled config.
- **Refresh semantics unknown:** TDX's public docs do not describe a refresh-token flow (see Doc 3 §5.1). The connector treats every 401 as "re-login required" and makes no assumption about silent renewal.

---

## Data mapping (NextGen → TDX)

### Standard `ConfigurationItem` fields

| TDX field | NextGen source | Notes |
|---|---|---|
| `Name` | `vw_explorer_detail.application_name` | Required |
| `TypeID` | `workspace_tdx_config.tdx_ci_type_id` | The Business Application CI type ID from Garland's tenant prep |
| `AppID` (path) | `workspace_tdx_config.tdx_asset_app_id` | URL path parameter, not body field |
| `ExternalID` | `vw_explorer_detail.application_id` (UUID as text) | Stored for human traceability; not searchable in TDX (see investigation log §5.3) |
| `OwnerUID` | Lookup via `/api/people/lookup?searchText=<owner_email or owner_name>` | Soft-skip on no-match in v1 (open question) |
| `OwningDepartmentID` | Lookup via `/api/accounts/search` with `vw_explorer_detail.workspace_name` | Soft-skip on no-match in v1 |
| `IsActive` | `vw_explorer_detail.operational_status = 'operational'` | Retired apps still push as inactive CIs rather than being deleted |

### Custom attributes (16 fields, aligns one-to-one with Doc 2's table)

| # | TDX attribute name | TDX field type | Ownership | NextGen source | Derivation / notes |
|---|---|---|---|---|---|
| 1 | GetInSync Application ID | Text | GetInSync-written | `vw_explorer_detail.application_id` (UUID as text) | Searchable custom attribute — doubles as DR fallback for the mapping table |
| 2 | GetInSync Workspace | Text | GetInSync-written | `vw_explorer_detail.workspace_name` | Human-readable workspace label |
| 3 | Last Synced From GetInSync | DateTime | GetInSync-written | Now() at push time | Lets TDX users see freshness |
| 4 | Business Fit | Numeric (0–100) | GetInSync-written | `vw_explorer_detail.business_fit` | Null-safe: push only if not null |
| 5 | Tech Health | Numeric (0–100) | GetInSync-written | `vw_explorer_detail.tech_health` | Null-safe |
| 6 | Tech Risk | Numeric (0–100) | GetInSync-written | `vw_explorer_detail.tech_risk` | Null-safe |
| 7 | Criticality | Numeric (0–100) | GetInSync-written | `vw_explorer_detail.criticality` | Null-safe |
| 8 | Crown Jewel | Checkbox | GetInSync-written | Derived: `criticality >= 50` | False if criticality is null |
| 9 | TIME Quadrant | Choice: Invest, Tolerate, Modernize, Eliminate | GetInSync-written | `vw_explorer_detail.time_quadrant` | Lower-case codes mapped to display labels |
| 10 | PAID Action | Choice: Plan, Address, Delay, Ignore | GetInSync-written | `vw_explorer_detail.paid_action`, normalised to Title Case on push | See §Data-mapping translation notes below for the casing rule |
| 11 | Technology Lifecycle | Choice: Mainstream, Extended, End of Support, Incomplete Data, No Technology Data, Preview | GetInSync-written | `vw_explorer_detail.worst_lifecycle_status` | Worst-of across all technology tags on the primary DP |
| 12 | Hosting Type | Choice: On-Prem, Cloud, SaaS, Hybrid, Third-Party-Hosted, Desktop | GetInSync-written | `vw_explorer_detail.hosting_type` | From primary DP |
| 13 | Annual Run Rate | Numeric (currency) | GetInSync-written | `vw_explorer_detail.total_run_rate` | Services + Cost Bundles aggregated across DPs |
| 14 | Estimated Tech Debt | Numeric (currency) | GetInSync-written | `vw_explorer_detail.estimated_tech_debt` | Null-safe |
| 15 | Integration Count | Numeric | GetInSync-written | `vw_explorer_detail.integration_count` | Active integrations only |
| 16 | Architecture Type | Choice: Standalone, Platform Host, Platform Application | GetInSync-written | `applications.architecture_type` (join) | Needed for suite parent/child distinction |

**Ownership semantics:**

- "GetInSync-written" fields are overwritten on every sync. Customer-editable values in these fields are not preserved. Doc 2 calls this out explicitly so Garland's TDX implementer doesn't build workflows around editing them.
- The two descriptive fields where Garland is free to edit (and NextGen won't overwrite) — `Description` and whatever TDX natively provides — are *not* on the 16-field list. The connector does not touch them.

### Data-mapping translation notes

The connector performs a few stable translations between NextGen's internal representation and the TDX choice labels described in Doc 2. Grouping them here so the translation layer is a single, well-documented responsibility:

- **PAID Action.** The canonical PAID framework labels are `Plan / Address / Delay / Ignore` (matching the NextGen standard). `deployment_profiles.paid_action` data is stored with mixed casing (both `Plan` and `plan`, `Address` and `address`, etc. — the CHECK constraint is permissive). The connector normalises to Title Case on push (`plan|Plan → Plan`, `address|Address → Address`, `delay|Delay → Delay`, `ignore|Ignore → Ignore`) so TDX sees a single canonical label per value regardless of how the source row happens to be cased. No value translation — source and target labels are the same set.
- **TIME Quadrant.** NextGen's `portfolio_assignments.time_quadrant` already holds the canonical framework labels (`Invest`, `Tolerate`, `Modernize`, `Eliminate`); no translation needed beyond passing through with defensive null-handling.
- **Architecture Type.** NextGen's `applications.architecture_type` uses lower snake case (`standalone`, `platform_host`, `platform_application`); TDX receives Title Case with spaces (`Standalone`, `Platform Host`, `Platform Application`). Pure case/format translation.
- **Technology Lifecycle, Hosting Type.** Passed through from NextGen's reference tables using the `name` (display label) rather than the `code`. The connector reads `lifecycle_statuses` and `hosting_types` once per invocation and caches the code-to-name map.

All translations are deterministic and side-effect-free. They live in one module (`supabase/functions/tdx-connector/translations.ts` — future implementation location) with unit coverage. Any future enum-label change in NextGen gets reflected by updating this module only.

### Relationship pushes

- **Integrates With** (custom relationship type, symmetric). Created for each row in `application_integrations` where both `source_application_id` and `target_application_id` map to TDX CIs for the same workspace. Metadata (direction, method, frequency, sensitivity, criticality, data tags) does not push — it stays in GetInSync, source of truth, surfaced via a per-CI link back to GetInSync.
- **Component Of** / **Composed Of** (custom relationship type, asymmetric). Created for each suite relationship: parent Application (`architecture_type='Platform Host'`) ↔ child Application (`architecture_type='Platform Application'`, joined via `deployment_profiles.inherits_tech_from` → parent DP → parent Application).

Relationship creation uses `POST /api/{appId}/cmdb/relationships/bulkadd` for the first-time population. On incremental updates, the connector diffs "current TDX relationships" (via `GET /api/{appId}/cmdb/{id}/relationships`) against "expected per NextGen" and issues targeted adds / deletes.

---

## Dependencies (hard)

1. **Garland migration OG → NextGen.** Garland must be running on NextGen before the connector activates for their workspace. Timeline is outside this session's scope; Garland's app portfolio data must be in NextGen first.
2. **Garland TDX tenant prep.** The Asset/CI App, Business Application CI type, custom attributes, relationship types, and service account described in `tdx-tenant-prep-spec.md` must be provisioned before any push attempt. A readiness-check subcommand in the connector admin UI validates the tenant side (reads the CI type, walks the custom attributes, confirms relationship types exist, issues a trivial GET to confirm auth).
3. **Supabase Vault.** The NextGen project must have Supabase Vault enabled before `workspace_tdx_config` can store secrets. This is a one-time platform-level prerequisite.

---

## Build plan sequence

Proposed phasing. Dependencies are strict top-down — a phase does not start until the previous is complete and signed off.

- **Phase 0 — Garland-side tenant prep.** Garland's TDX implementer provisions the Asset/CI App, Business Application CI type, custom attributes, and relationship types per `tdx-tenant-prep-spec.md`. GetInSync is not in the critical path for Phase 0. Validation is a short checklist in Doc 2. **Exit:** Garland can issue the service-account curl that creates and retrieves a trivial test CI.

- **Phase 1 — NextGen schema + Edge Function scaffolding.** Four new tables (`tdx_ci_mappings`, `workspace_tdx_config`, `tdx_sync_queue`, `tdx_sync_log`) with RLS. Edge Function scaffold at `supabase/functions/tdx-connector/` with auth, rate-limit buckets, queue drain, and basic logging. Admin UI panel for per-workspace credential entry and readiness check. **Exit:** an admin can enter credentials, the connector authenticates successfully, the readiness check passes against a prepped tenant.

- **Phase 2 — Applications push.** Full custom-attribute mapping. Owner and department lookups. Idempotent create/update via the mapping table. Soft-skip on owner/department lookup miss (log, continue). Manual "Sync this app" end-to-end. **Exit:** one test Application round-trips from NextGen to TDX, appears correctly in the TDX CMDB UI with all 16 custom attributes populated.

- **Phase 3 — Relationships.** Integrates With pushes; Component Of pushes for suite composites; diff-based incremental relationship updates. **Exit:** a small portfolio of 3–5 Applications with 2–3 integrations between them shows the correct graph in TDX's CMDB relationship explorer.

- **Phase 4 — Delta sync + hardening.** Publish-event trigger active. Scheduled delta job. Retry/backoff proven under induced failure. Admin notifications on failed sync. **Test coverage, concise form:**
  - **Unit:** translation module (PAID label mapping, Architecture Type case), rate-limiter token buckets, content-hash comparison, retry backoff calculator.
  - **Integration against a TDX sandbox:** auth flow, CI create/update/delete, relationship add/bulk-delete, People and Accounts lookup, readiness check.
  - **Load test at Garland-sized scale:** 363-app initial push from scratch, measured wall-clock and observed rate-limit behaviour. (363 is the working target based on Garland's current OG inventory; adjust once we know NextGen-migrated numbers.)
  - **Failure injection:** forced 429, forced 401 mid-batch, forced 500, network timeout, TDX-side CI deletion, credential rotation mid-sync, `tdx_sync_queue` backpressure threshold breach.
  **Exit:** a 48-hour soak with synthetic traffic shows no drift between NextGen and TDX at the close of the window.

- **Phase 5 — Sassafras coexistence hardening.** Once Garland's TDX tenant has Sassafras writing to it, we inspect the real Sassafras CI types (via the TDX API and UI) and confirm that GetInSync's writes don't collide, that the two service accounts don't overlap, and that there's a future path for cross-linking (Application CI ↔ Sassafras Installed Software). **Exit:** explicit sign-off that coexistence works and a short "what Sassafras actually writes" appendix added to `tdx-api-investigation-log.md`.

- **Phase 6 — Garland go-live (hard dependency on OG→NextGen migration).** Once Garland is on NextGen, enable the connector for their workspace. First push targets a small validation portfolio (e.g., 10 Applications); full portfolio follows on admin sign-off.

---

## Rollback and disaster recovery

Short operator runbook. Details firm up during Phase 4; the shapes below are the v1 commitment.

- **Disable the connector for a workspace** (scheduled work: maintenance window, credentials rotated, TDX outage on Garland's side). Set `workspace_tdx_config.is_active = false`. The publish-event trigger and scheduled delta both honour this flag; manual "Sync this app" is also refused. In-flight sync rows finish their current attempt and then stop. TDX state is not touched. Re-enable by flipping the flag back and optionally running a manual "Force full resync".
- **Pause without disabling** (used by backpressure — see above). Same as disable but via `paused_at` instead of `is_active`. Distinguishes "connector is off on purpose" from "connector is temporarily backed off".
- **Bulk-unpublish** (rare: Garland asks GetInSync to pull out of their tenant entirely). The connector does not ship with a "delete all CIs in the Asset/CI App" command in v1 — the blast radius is too large for an automated button. Procedure: flip `is_active = false`, then TDX admin performs the deletion manually through TDAdmin (or scripts it themselves via the TDX API). On the GetInSync side, clear the `tdx_ci_mappings` rows for the workspace so a future re-enable starts from scratch. Consider adding a guarded "bulk unpublish" admin command in a later iteration if the need recurs.
- **Mapping-table loss or corruption** (the scariest scenario — without the mapping, the connector would create duplicate CIs on the next sync). Recovery uses the "GetInSync Application ID" searchable custom attribute (see Doc 3 §5.3 and §6 item 1): the connector runs a recovery pass that `POST /api/{appId}/cmdb/search` lookups each NextGen Application ID, rebuilds `tdx_ci_mappings` from the TDX-side matches, and flags Applications with no TDX match for fresh creation. Documented in the admin UI as "Rebuild mapping from TDX." Not a one-click button; executed by a GetInSync engineer with Stuart's sign-off.
- **TDX side of Garland's tenant gets wiped / rebuilt** (e.g., tenant migration, disaster recovery on Garland's side). `tdx_ci_mappings` rows are stale — flip `is_active = false` and clear them; re-enable to repopulate from scratch. First push will take the full initial-seed duration (minutes to low hours, depending on portfolio size).

---

## Sassafras coexistence architecture

The design choice is **separation**, not integration, for v1:

- **Separate Asset/CI App.** Garland's TDX tenant hosts a dedicated Asset/CI App for Applications (GetInSync's write target), distinct from whichever Asset/CI App Sassafras populates with software inventory and endpoint data.
- **Separate service accounts.** GetInSync's service account has no permissions in Sassafras's Asset/CI App. Sassafras's service account has no permissions in GetInSync's Asset/CI App.
- **No overlap in CI types.** GetInSync writes only to the Business Application CI type. Sassafras writes to its own CI types (Installed Software, Endpoint, or whatever names Sassafras actually uses — currently `[UNKNOWN]`, see investigation log §4).
- **No cross-writes.** GetInSync never PUT/PATCHes a Sassafras-owned CI. Sassafras (as far as we know) does not touch GetInSync-owned CIs.

**Future (not v1):** once Sassafras's CI types and relationship types are known in Garland's live tenant (Phase 5), we can consider a **read-only cross-link**: NextGen reads Sassafras's Installed Software inventory and creates "Runs On" relationships from its own Application CIs into Sassafras's software CIs. This gives TDX users a single view of business app → installed software → endpoints. That is a future direction, not a v1 commitment.

---

## Open questions

These surface at the workshop. Each has a v1 default chosen; Stuart can redirect before implementation starts.

- **Q1 — Integration modelling.** v1 default: simple `Integrates With` relationship between two Application CIs, integration metadata stays in GetInSync. Alternative: model each integration as its own "Integration" CI with two `Participates In` relationships. Alternative gives TDX users richer visibility but doubles write volume, requires a second CI type in Garland's tenant, and duplicates the source-of-truth problem. Revisit if Garland has a strong TDX-side integration-catalog use case.

- **Q2 — Multi-portfolio TIME/PAID rollup.** An Application assigned to 3 portfolios has 3 TIME quadrants in NextGen. v1 default: push the value from the Application's primary portfolio only. Alternatives: push the worst-case quadrant across all portfolios; or push all three as separate repeating fields (TDX doesn't have great native support for repeating fields, so this is heavier). Decision is workshop-worthy — Garland may have an opinion on which portfolio their TDX users will treat as authoritative.

- **Q3 — Owner / Department lookup fallback.** v1 default: if the NextGen owner name/email doesn't resolve to a TDX Person, log the miss and push the CI without `OwnerUID` (leave the field blank in TDX). Alternative: hard-fail the sync and require manual resolution. Soft-skip keeps flow moving; hard-fail surfaces data-quality issues earlier.

- **Q4 — Suite parent/child push scope.** v1 default: push both the Platform Host parent and each Platform Application child as separate CIs, linked by `Component Of`. Child CIs push their own T-scores if set (otherwise push the parent's scores with a "Tech Scores Inherited From" text field pointing to the parent CI name). Alternative: push parent only, list children as text in a `Child Applications` custom attribute. v1 default honours the CSDM-aligned child-is-a-first-class-App philosophy from `core/composite-application.md`.

- **Q5 — Delta detection mechanism.** v1 default: content-hash comparison (sha256 of the payload NextGen would push). Only if the hash differs does the connector issue a PUT. Alternative: `updated_at`-based fan-out from the publish trigger. Hash is safer (catches derived-value changes the trigger might miss); trigger is cheaper (doesn't require reading and hashing for every scheduled sweep). v1 can do both — trigger narrows the candidate set, hash confirms something actually changed.

- **Q6 — Secret storage.** v1 default: Supabase Vault references stored in `workspace_tdx_config`. Alternative: encrypted column in `workspace_tdx_config` using pgcrypto + a KMS-managed key. Vault is the cleaner pattern but requires the Vault extension to be enabled on the NextGen project.

- **Q7 — TDX sandbox or production-first.** Does Garland have a TDX sandbox we target during Phase 1–4 development, or do we develop against a GetInSync-owned TDX trial? This shapes whether credentials need to be rotated before Phase 6 go-live.

- **Q8 — Retired Applications.** When a NextGen Application is retired (`operational_status != 'operational'`), do we flip the TDX CI to `IsActive=false` (v1 default), or do we delete it? Flipping preserves history; deleting removes clutter but breaks external references. v1 default is flip.

---

## Revisions

- **2026-04-18 — Stuart review pass.** Added §Data-mapping translation notes (PAID casing normalisation, Architecture Type case translation, TIME pass-through, reference-table reads). Added §Operational visibility (admin panel, per-Application indicator, daily digest). Added §Queue backpressure under Error handling. Added §Rollback and disaster recovery as a new ops subsection. Tightened TDX-behaviour assertions in §Authentication and §Error handling to inherit Doc 3's `[INFERENCE]`/`[UNKNOWN]` tags. Corrected rate-limit headroom claim (~12.5% of CI-create ceiling, ~50% of CI-update ceiling). Resolved a dangling §9 cross-reference in the PAID Action row by pointing it to the new translation-notes section. Expanded Phase 4 exit criteria with explicit test types (unit, integration-against-sandbox, load at 363-app scale, failure injection). Expanded Companion-docs header with pointers to Doc 3's load-bearing sections and `core/composite-application.md`. PAID framework labels remain `Plan / Address / Delay / Ignore` — a mid-review suggestion to switch to `Plan / Address / Improve / Divest` was applied in-flight and then reverted after Stuart re-confirmed Plan/Address/Delay/Ignore as the GetInSync canonical.

---

*End of build plan. Companion documents: `tdx-tenant-prep-spec.md` (what Garland's TDX implementer does), `tdx-api-investigation-log.md` (what we learned about TDX).*
