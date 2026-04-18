# TDX Web API Investigation Log

> **Status: DRAFT** — working reference for the May 14, 2026 Garland workshop.
> **Date:** 2026-04-18
> **Audience:** Internal (Stuart, future Claude Code sessions).
> **Source of truth:** <https://solutions.teamdynamix.com/TDWebApi/Home/>

This log captures what was learned from vanilla TeamDynamix Web API documentation during the planning session that produced the NextGen → TDX outbound connector build plan and Garland tenant prep spec. Every claim is either cited to a TDX documentation URL, marked `[INFERENCE]` (where the docs are silent and we reasoned from context), or marked `[UNKNOWN]` (where the answer cannot be determined from public documentation alone and must be confirmed with TDX).

---

## 1. Scope of this investigation

**Examined:**

- CMDB (Configuration Items, CI Types, CI Relationships, CI Relationship Types, CI Forms)
- Assets (only where directly relevant to how CIs relate to asset structure)
- Users, Accounts/Departments (for owner and department field mapping)
- Security Roles and Permissions (for service account scoping)
- Authentication (for the outbound connector's login flow)

**Explicitly skipped** (out of scope for the outbound-enrichment use case):

- Tickets, Problems, Change
- Service Catalog
- Knowledge Base
- Portfolio / Project Planning / PPM
- Time tracking and reporting

**Out-of-scope reminder:** this session is about outbound Application push only. No ticket read-through, no inbound sync, no Deployment Profile publishing. The TDX surfaces above are the minimum set needed to design that outbound path.

---

## 2. API sections reviewed

| TDX API section | URL |
|---|---|
| Configuration Items | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItems> |
| Configuration Item Types | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItemTypes> |
| Configuration Relationship Types | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationRelationshipTypes> |
| Custom Attributes | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Attributes> |
| Auth | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Auth> |
| People / Users | <https://solutions.teamdynamix.com/TDWebApi/Home/section/People> |
| Accounts (Departments) | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Accounts> |
| Security Roles | <https://solutions.teamdynamix.com/TDWebApi/Home/section/SecurityRoles> |

---

## 3. Primary question answered

**Does TDX provide a native Business Application construct that is distinct from software assets / installed software products?**

**Answer: No.**

TDX's CMDB is a generic configuration management framework. The API documentation lists no predefined "Business Application" CI type. What it provides is:

- A flexible CI type framework (customers create their own via `POST /api/{appId}/cmdb/types`)
- An **Asset/CI App** container (addressed by `{appId}` in every CMDB URL) inside which CI types and CI instances live
- A custom-attributes framework for extending CI types with additional fields
- A custom-relationship-types framework for defining how CIs link to each other

**Implication for the NextGen → TDX connector:** Garland's TDX tenant needs a customer-provisioned Asset/CI App with a custom CI type (working name: "Business Application") that NextGen writes into. There is no out-of-the-box type to target; Doc 2 (Tenant Prep Spec) must walk Garland's TDX implementer through the creation of this container and CI type before the connector can push anything.

**Evidence:** no Business Application type is listed in the CI Types section of the TDX Web API docs; `POST /api/{appId}/cmdb/types` and the supporting `ConfigurationItemType` model are the provided extension points.

---

## 4. Sassafras's role in TDX

**What the public TDX Web API docs say:** nothing. Searches across the API reference for "Sassafras", "AllSight", "SAM" (software asset management), "software discovery", and "installed software" return zero API-level mentions.

**What we can reason about** (`[INFERENCE]` — must be confirmed with TDX or with Garland's implementer):

- Sassafras was acquired by TDX in April 2025 and is now bundled with Garland's TDX purchase.
- Sassafras's function is software asset management (SAM): it inventories installed software on endpoints and feeds that inventory into TDX.
- Sassafras almost certainly writes into TDX via proprietary integration paths (not the public Web API surface), populating an inventory-oriented Asset/CI App with CI types such as "Installed Software", "Software Product", "Endpoint", or similar. These CI types are likely system-provisioned rather than customer-authored.
- Sassafras's writes and GetInSync's writes must not collide. The cleanest architectural separation is for GetInSync's Application CIs to live in **their own Asset/CI App**, distinct from Sassafras's inventory space. Doc 2 makes this a hard requirement for Garland's tenant provisioning.

**What must be confirmed with TDX or Garland's TDX implementer** (`[UNKNOWN]`):

1. Which Asset/CI App(s) does Sassafras write into — and can a customer inspect or constrain that?
2. What CI types does Sassafras define, and is the shape public/documented, or is it opaque to customers?
3. Is the Sassafras-written space readable via the public Web API, or only via a Sassafras-specific API?
4. Does Sassafras ship with predefined relationship types (e.g., "Installed On", "Running On") that a NextGen Application CI could eventually be linked into (future integration direction — not v1)?
5. Is there documented guidance on the GetInSync + Sassafras coexistence pattern, or are we defining one from scratch?

The cleanest safe default while these are unknown: **separate Asset/CI Apps, separate service accounts, no write from GetInSync into Sassafras's space, no write from Sassafras into GetInSync's space**. Doc 1 (Build Plan) and Doc 2 (Tenant Prep Spec) both enshrine this.

---

## 5. Key API patterns

### 5.1 Authentication

**Documented endpoints** (from the Auth section):

- `POST /api/auth` — standard user credentials (username + password). Returns a Bearer JWT.
- `POST /api/auth/loginadmin` — administrative service account. Body: `{ BEID, WebServicesKey }`. Returns a Bearer JWT.

**Recommended pattern for the NextGen connector:** `/api/auth/loginadmin`. The BEID and WebServicesKey are obtained from **TDAdmin → Organization Details** inside the TDX tenant. The service account is a regular TDX User record marked Active — there is no separate "service account" construct, just a user with the admin privileges needed to generate a WebServicesKey.

**Token lifetime:** `[INFERENCE]` — commonly reported as 24 hours for TDX JWTs. The Auth section does not explicitly state TTL or refresh semantics. There is no documented refresh-token mechanism; practical implementation re-authenticates on 401.

**`[UNKNOWN]` to confirm with TDX:**

- Exact token TTL
- Whether tokens can be refreshed without re-login
- Whether concurrent tokens for the same service account are allowed and how they interact

### 5.2 Rate limits

TDX documents per-endpoint rate limits embedded in the reference pages for each endpoint. Observed pattern:

| Endpoint class | Limit | Notes |
|---|---|---|
| `POST /api/{appId}/cmdb` (create CI) | 240 / 60s | Higher; designed for bulk creation |
| `PUT /api/{appId}/cmdb/{id}` (update CI) | 60 / 5s | **Strictest** documented limit seen |
| `GET`, `DELETE`, `PATCH` on CIs | 60 / 60s | Standard |
| `POST /api/{appId}/cmdb/search` | 60 / 60s | Standard |
| `PUT /api/{appId}/cmdb/{id}/relationships` | 60 / 5s | Strict (mirrors CI update) |
| Auth endpoints | 60 / 60s | Standard |

**Scope:** limits are per endpoint, and `[INFERENCE]` per client identity (IP + service account). The docs do not explicitly clarify "per IP", "per user", or "per tenant".

**Response on breach:** `[UNKNOWN]` — the documentation does not specify whether HTTP 429 is returned, whether a `Retry-After` header is provided, or what the recommended backoff strategy is. Practical implementation should:

- Treat 429, 503, and unexpected 5xx as transient and back off exponentially
- Assume no `Retry-After` is provided and use bounded jitter
- Log the response body on the first rate-limit failure to capture whatever signal TDX does send

**Bulk operations:**

- **No bulk CI create endpoint exists.** Each CI requires an individual `POST /api/{appId}/cmdb`. This is the single most expensive constraint on initial population.
- **Bulk relationship endpoints exist:** `POST /api/{appId}/cmdb/relationships/bulkadd` and `POST /api/{appId}/cmdb/relationships/bulkdelete`. Relationship rounds trip can batch.

### 5.3 CI CRUD

| Operation | Endpoint | Notes |
|---|---|---|
| Create | `POST /api/{appId}/cmdb` | Returns the created CI with TDX-assigned `ID` |
| Retrieve by TDX ID | `GET /api/{appId}/cmdb/{id}` | |
| Full update | `PUT /api/{appId}/cmdb/{id}` | Replace mode — pass the full CI body |
| Partial update | `PATCH /api/{appId}/cmdb/{id}` | Custom attributes only |
| Delete | `DELETE /api/{appId}/cmdb/{id}` | |
| Search | `POST /api/{appId}/cmdb/search` | `ConfigurationItemSearch` body |

**Critical gap — no upsert, no ExternalID lookup:**

- The `ConfigurationItem` model includes an `ExternalID` field (string, nullable, editable) that is clearly intended for pairing with an external system of record.
- **But** the `ConfigurationItemSearch` model does not expose `ExternalID` as a searchable field. Searchable fields appear limited to `NameLike`, `IsActive`, `TypeIDs`, `MaintenanceScheduleIDs`, and `CustomAttributes`.
- **Consequence:** you cannot ask TDX "find the CI whose ExternalID equals this NextGen `applications.id`." After create, you must remember the TDX-assigned `ID` locally; subsequent updates call `PUT /api/{appId}/cmdb/{TDX_ID}`. The NextGen side must own the NextGen-ID ↔ TDX-ID mapping table. This is a foundational design constraint, not a convenience problem.

**Workaround if ExternalID search is truly needed (e.g., disaster recovery after losing the local mapping):** use `POST /api/{appId}/cmdb/search` with `CustomAttributes` containing a GetInSync-Application-ID custom attribute value. This means defining "GetInSync Application ID" as a custom attribute (not only as `ExternalID`) — which Doc 1 and Doc 2 do.

### 5.4 Relationship operations

**What relationships can do:**

- Relationship types are customer-definable (`POST /api/{appId}/cmdb/relationshiptypes`). Fields: `Description` (parent → child wording), `InverseDescription` (child → parent wording), `IsOperationalDependency` (flag), `IsActive`.
- Relationship instances (`ConfigurationItemRelationship`) carry: `RelationshipTypeID`, `ParentID`, `ChildID`, `IsOperationalDependency` (inherited from the type), audit fields (`CreatedDateUtc`, `CreatedUid`, `CreatedFullName`), and the system `IsSystemMaintained` flag.
- Bulk endpoints exist for relationship add/delete — useful for the connector's first-pass population.

**What relationships cannot do:**

- **Relationships cannot carry custom attributes.** The `ConfigurationRelationshipType` model has no `CustomAttributes` field, and the instance model has none either. You cannot annotate a relationship with "this integration carries PII", "this dependency is cadence=daily", or any other per-edge metadata.
- This is a significant constraint for NextGen, where integration edges carry direction, method, frequency, sensitivity, criticality, and data tags.

**Implication for v1 connector:** push only the edge itself (two CI IDs + a relationship type). Integration metadata stays in GetInSync. The Application CI in TDX gets a link back to GetInSync where the detail lives. Doc 1 lists the richer "Integration as its own CI type" as an open question but not the v1 default.

### 5.5 Custom fields (custom attributes)

**What custom attributes support:**

- The `CustomAttribute` model exposes `FieldType`, `DataType`, `Choices[]`, `IsRequired`, `IsUpdatable`, `Name`, etc.
- Choice lists (`CustomAttributeChoice[]`) are explicitly supported. Choice fields are defined at the attribute level and shared across all CIs of the given type.
- `[INFERENCE]` typical data types: Text, Numeric, Date/DateTime, Checkbox/Boolean, Dropdown (single-choice). The exact enumeration of allowed `FieldType`/`DataType` values is not listed in the public reference.

**What custom attributes do not support** (based on model inspection):

- **No lookup to other TDX records.** Custom attributes cannot be typed as "Person" or "Vendor" or "Account/Department" pointers. There is no reference-ID field on the `CustomAttribute` model.
- **Workaround:** use the standard CI fields that are already typed as lookups (`OwnerUID` → Person, `OwningDepartmentID` → Account/Dept, `LocationID` → Location, `VendorID` on assets) for the cases TDX ships with. For other entity references (e.g., linking an Application CI to a Vendor record on the CI type), either (a) use a CI relationship instead of a custom attribute, or (b) store the referenced entity's display text in a plain text custom attribute and accept that it won't navigate.
- Owner lookup from NextGen: NextGen stores free-text owner names, not necessarily TDX UIDs. The connector will need to resolve names/emails via `POST /api/people/lookup?searchText=...` before setting `OwnerUID`. This lookup has its own failure mode (no match, ambiguous match) that Doc 1 handles as an open question on fallback behaviour.

**Field count limits:** `[UNKNOWN]` — the docs do not state a hard limit on custom attributes per CI type. Practical implementations typically stay under ~30 per type for usability.

### 5.6 People and Accounts (Departments)

- `POST /api/people/lookup?searchText=...` — fuzzy search for TDX Users by name/email/uid. Returns a limited set; extract UID (GUID).
- `POST /api/accounts/search` — search Accounts (Departments). `[INFERENCE]` supports name filtering; exact search parameter shape not fully documented in the reference page inspected.
- These are the lookups the connector performs to translate NextGen owner/workspace values to TDX `OwnerUID` and `OwningDepartmentID`.

### 5.7 Security Roles

- Security Roles can be inspected and managed via `/api/securityroles` endpoints.
- `GET /api/permissions?appId={appId}` lists available permissions for an Asset/CI App. The specific permission names/IDs required for CI CRUD, relationship CRUD, and People/Account search are **not enumerated in the public docs** — `[UNKNOWN]` and must be inspected in Garland's tenant.

**`[INFERENCE]` for service account scoping:**

- Needs Create/Update/Delete on Configuration Items in the designated Asset/CI App
- Needs Create/Update on Configuration Item Relationships
- Needs Read on People and Accounts (for lookup calls)
- Does **not** need admin, security role management, ticketing, or any non-CMDB surface
- Does **not** need any permission in the Asset/CI App that Sassafras populates

---

## 6. Gotchas and unknowns (top 5)

Ranked by how badly each will bite if not confirmed before implementation.

1. **No upsert / no search-by-ExternalID** — `[DOCUMENTED]`. The connector must own the NextGen-ID ↔ TDX-ID mapping or it will create duplicate CIs on every retry after a mapping loss. Mitigation: durable mapping table with transactional upsert semantics on the NextGen side, plus "GetInSync Application ID" stored as a searchable custom attribute as a disaster-recovery fallback.
2. **Relationships cannot carry custom metadata** — `[DOCUMENTED]`. Any integration attribute NextGen wants in TDX must live on one of the two endpoint CIs, or on a new "Integration" CI type. v1 accepts the loss; integration-as-CI remains an open question for v2.
3. **Sassafras coexistence is undefined in public docs** — `[UNKNOWN]`. We proceed with a conservative "separate Asset/CI App, separate service account, no overlap" design, but need Garland (and potentially TDX support) to confirm what Sassafras actually writes and where.
4. **Rate-limit breach behaviour is undocumented** — `[UNKNOWN]`. Whether 429 + `Retry-After` is returned, or some other code/header combination, is not specified. Implement assuming nothing; log first breaches to capture the real signal.
5. **Custom attribute type enumeration and lookup support are under-documented** — `[INFERENCE]`. We assume primitive + choice-list only, no entity-lookup custom attributes. If TDX actually does support a lookup field type, Doc 2's field table simplifies. Confirm during tenant provisioning.

Additional unknowns worth flagging:

- Whether a single TDX tenant can host multiple Asset/CI Apps, and whether CI types are tenant-wide or per-App. `[INFERENCE]` per-App, based on the `AppID` field in the `ConfigurationItemType` model, but not explicitly stated.
- Whether CI type creation requires special admin rights beyond standard CMDB permissions (matters for who can provision the Asset/CI App — Garland's admin vs the GetInSync service account).
- Whether the Web API exposes enough of the TDX forms system to let NextGen drive form selection when writing a CI (form assignment typically happens via the UI, not the API).

---

## 7. Future integration directions (flag only — not for this session)

Recorded here so the next session or planning pass can pick them up without re-deriving:

- **Sassafras software discovery → NextGen Technology Product catalog.** If Sassafras's software inventory is readable via the Web API (or a Sassafras-native API), NextGen's Technology Product catalog could be seeded or cross-referenced from it. This would strengthen NextGen's standards-intelligence coverage for Garland and reduce manual tagging. Entirely inbound; not in scope for the outbound-only connector.
- **TDX ticket data → NextGen DP blast-radius view.** Incident volume and change frequency against a given CI are first-class signals for NextGen's health/risk assessments. A read-only pull of ticket counts per CI (or per ExternalID) would feed the DP-level view Stuart has flagged for future work. Inbound and explicitly out of scope for this session.
- **Application CI → Sassafras Installed Software relationship.** If Sassafras's CI types are linkable via public relationships, a NextGen Application CI could eventually be joined to the software products it runs on, giving TDX users a single place to see "business app → installed software → endpoints". Requires answering the Sassafras `[UNKNOWN]`s above.

---

## 8. Source evidence map

For each major claim, the supporting URL. Where multiple URLs contribute, the most load-bearing is listed first.

| Claim | Primary source |
|---|---|
| No native Business Application CI type | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItemTypes> |
| Asset/CI Apps are the container for CIs | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItems> |
| Custom CI type creation endpoint | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItemTypes> |
| Custom attributes support choice lists, not entity lookups | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Attributes> |
| Relationships cannot carry custom attributes | <https://solutions.teamdynamix.com/TDWebApi/Home/type/TeamDynamix.Api.Cmdb.ConfigurationItemRelationship> |
| Custom relationship types endpoint | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationRelationshipTypes> |
| `loginadmin` BEID + WebServicesKey flow | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Auth> |
| Per-endpoint rate limits | Individual endpoint reference pages under ConfigurationItems and ConfigurationRelationshipTypes |
| No bulk CI create; bulk add/delete for relationships | <https://solutions.teamdynamix.com/TDWebApi/Home/section/ConfigurationItems> |
| ExternalID not in `ConfigurationItemSearch` | <https://solutions.teamdynamix.com/TDWebApi/Home/type/TeamDynamix.Api.Cmdb.ConfigurationItemSearch> |
| People lookup | <https://solutions.teamdynamix.com/TDWebApi/Home/section/People> |
| Accounts (Departments) search | <https://solutions.teamdynamix.com/TDWebApi/Home/section/Accounts> |
| Permissions listing | <https://solutions.teamdynamix.com/TDWebApi/Home/section/SecurityRoles> |

---

*End of investigation log. This document is a draft; claims marked `[INFERENCE]` or `[UNKNOWN]` must be confirmed with TDX or Garland's TDX implementer before the connector moves past the scaffolding phase.*
