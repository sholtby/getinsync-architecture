# TeamDynamix Tenant Readiness Specification

> **Status: DRAFT** — for discussion ahead of the May 14, 2026 workshop.
> **Date:** 2026-04-18
> **Prepared for:** City of Garland and Garland's TeamDynamix implementer.
> **Prepared by:** GetInSync.

---

## 1. Introduction

Garland is bringing TeamDynamix online as its ITSM platform. GetInSync will push application portfolio information from its platform into Garland's TDX tenant so that the tenant is populated with business applications on day one — not as a one-time dump, but as a live feed that keeps TDX current as Garland's portfolio changes.

This document describes what Garland's TDX implementer needs to configure in the TDX tenant so that GetInSync's data lands correctly and cleanly. Think of it as a tenant-readiness checklist: when every item on it is complete, GetInSync can start writing.

### Why applications deserve their own space in TDX

TDX's CMDB is a flexible configuration management framework. It ships strong on IT assets (laptops, servers, mobile devices) and on the software discovered running on those assets. Where it is less prescriptive is in modelling the **business applications** that the organisation depends on — the logical systems that run the business, regardless of how or where they are deployed.

There is a real and useful distinction between two related but different disciplines:

- **Software Asset Management (SAM)** — what software is installed on which endpoints, what is licensed, what is running, what is unused. TDX handles this strongly through its bundled software-discovery component (Sassafras / AllSight).
- **Application Portfolio Management (APM)** — which business applications the organisation runs, who owns them, what they cost, what their lifecycle and modernisation disposition is, how they integrate with each other. This is what GetInSync does.

The two disciplines share some vocabulary but answer different questions. SAM answers "what software is on this laptop?" APM answers "which business applications do we run and what are we going to do about them?" Both matter, and both should live in TDX — but in **separate spaces** inside the tenant, owned by different processes, populated by different tools, so that neither steps on the other.

### "Ready on Day 1" — what it means for Garland

When Garland's TDX tenant is ready to receive GetInSync's data, Garland's staff will see a complete portfolio of business applications in TDX from the moment TDX goes live. Each application will carry the ownership, cost, technology, and portfolio-assessment information Garland has been maintaining in GetInSync. Integrations between applications will appear as relationships in TDX's relationship explorer. As the portfolio changes in GetInSync, those changes will flow into TDX within hours.

This readiness spec makes that possible by describing the container, the configuration item type, the fields, the relationships, and the service account that GetInSync will write into.

---

## 2. TDX tenant requirements

This section lists everything Garland's TDX implementer needs to provision before GetInSync can begin writing. It is framed as a starting point; everything here is open to refinement during the May 14 workshop.

### 2.1 A dedicated Asset/CI App for applications

**Create a new Asset/CI App** inside the TDX tenant — a container used exclusively for the application portfolio.

- **Working name:** "Applications" (Garland's implementer is free to choose the final name)
- **Purpose:** to host the business-application configuration items GetInSync writes
- **Separation:** distinct from whichever Asset/CI App holds Garland's IT Assets; and distinct from whichever Asset/CI App the software-discovery component (Sassafras / AllSight) populates with installed-software and endpoint records

**Why a dedicated container?** Because the items GetInSync writes are a different kind of thing from the items Sassafras writes. Mixing them in the same container makes both harder to govern: ownership, retention, workflows, reports, and security roles all get muddled. A dedicated container keeps the concerns clean.

### 2.2 A custom configuration item type

**Inside the "Applications" Asset/CI App, create a new CI type** to represent business applications.

- **Working name:** "Business Application"
- **Purpose:** this is the single type that GetInSync writes. Every GetInSync-managed CI in this Asset/CI App is of this type.
- **Attachment points:** the custom fields in §2.3 are attached to this CI type. The relationship types in §2.4 connect instances of this type to each other.

**Why a custom CI type?** TDX does not ship with a prebuilt "Business Application" CI type; the CMDB is intentionally generic so that each organisation can model its portfolio its way. Creating a named, dedicated type gives the portfolio its own identity in the tenant and lets Garland govern it separately from the rest of the CMDB.

### 2.3 Custom fields on the Business Application CI type

The table below is the starting point for the fields GetInSync will populate. Garland's implementer may add more fields for TDX-internal use (ticket routing, automation tags, etc.) — those fields are Garland's to define and are not overwritten by GetInSync.

**Conventions:**

- **"Owner: GetInSync"** means GetInSync writes this field on every sync. Changes made in the TDX UI to these fields will be overwritten on the next sync. Please do not build TDX-side workflows that depend on editing these fields.
- **"Owner: Customer"** means Garland owns the field. GetInSync never writes to it.
- **"Choice"** means a dropdown list whose allowed values are listed. Choice labels should use the same wording as the table (the CI field's internal code may be lower-case for interoperability).

| # | Field name | Type | Owner | Purpose |
|---|---|---|---|---|
| 1 | GetInSync Application ID | Text | GetInSync | Stable unique identifier used by GetInSync to locate this CI on updates. Do not edit. |
| 2 | GetInSync Workspace | Text | GetInSync | The GetInSync workspace this application lives in (typically the department or organisational unit). |
| 3 | Last Synced From GetInSync | Date/Time | GetInSync | Timestamp of the most recent successful sync. Lets TDX users see how fresh the data is. |
| 4 | Business Fit | Numeric (0–100) | GetInSync | How well the application aligns with Garland's business strategy. |
| 5 | Tech Health | Numeric (0–100) | GetInSync | Overall technical health of the application's primary deployment. |
| 6 | Tech Risk | Numeric (0–100) | GetInSync | Technical risk score for the application's primary deployment. |
| 7 | Criticality | Numeric (0–100) | GetInSync | How critical the application is to Garland's operations. |
| 8 | Crown Jewel | Checkbox | GetInSync | True for applications flagged as strategically critical (derived from Criticality ≥ 50). |
| 9 | TIME Quadrant | Choice: Invest, Tolerate, Modernize, Eliminate | GetInSync | Portfolio-level strategic disposition. |
| 10 | PAID Action | Choice: Plan, Address, Delay, Ignore | GetInSync | Near-term remediation priority. |
| 11 | Technology Lifecycle | Choice: Mainstream, Extended, End of Support, Incomplete Data, No Technology Data, Preview | GetInSync | Worst-case lifecycle status of the underlying technology stack. |
| 12 | Hosting Type | Choice: On-Prem, Cloud, SaaS, Hybrid, Third-Party-Hosted, Desktop | GetInSync | How the application is deployed. |
| 13 | Annual Run Rate | Numeric (currency) | GetInSync | Total annual cost (licensing + services + any allocated bundles). |
| 14 | Estimated Tech Debt | Numeric (currency) | GetInSync | Estimated cost to modernise or remediate. |
| 15 | Integration Count | Numeric | GetInSync | How many active integrations the application participates in. |
| 16 | Architecture Type | Choice: Standalone, Platform Host, Platform Application | GetInSync | Distinguishes standalone applications from platforms and their hosted components. |

**Field count:** 16 GetInSync-written fields. Garland may add any number of Customer-owned fields alongside these.

**Note on choice fields:** GetInSync will send the displayed label exactly as listed above. If the implementer prefers different wording in Garland's TDX tenant, let us know during the workshop so the connector sends the matching label.

**A note on what's not in this table:** GetInSync does not write a free-text "Description" field, nor fields for ticketing/routing, nor owner-contact-record pointers. Those are either handled by TDX's own CI fields (Name, Owner, Owning Department, Active flag) or they are Garland's to define for TDX-internal use.

### 2.4 Relationship types

**Create two custom relationship types** in the Asset/CI App. These let GetInSync express how business applications relate to each other.

| Relationship (parent → child wording) | Inverse (child → parent wording) | Used for |
|---|---|---|
| Integrates With | Integrates With | Data exchange between two applications (APIs, file transfers, database syncs, message queues, etc.). Symmetric — the same phrase reads correctly both ways. |
| Composed Of | Component Of | Platform applications that are made up of component applications (e.g., "Microsoft 365" composed of "Teams" and "SharePoint Online"). |

**Optional third relationship type** (flag for discussion — not required for v1):

| Relationship | Inverse | Used for |
|---|---|---|
| Depends On | Depended On By | Runtime dependency where one application relies on another to function (not mere data exchange). |

**What relationships do not carry.** TDX relationships are the connections themselves — they do not carry extra attributes like "direction", "data volume", or "sensitivity". GetInSync will push the relationship itself (application A ↔ application B), and the richer detail stays inside GetInSync, where a TDX user can follow a link on the CI to see it. If Garland has a strong need to surface per-relationship detail inside TDX, please raise it at the workshop — there is an alternative modelling approach (modelling each integration as its own CI), but it has trade-offs worth discussing.

### 2.5 Service account

**Create a dedicated TDX user account for GetInSync.**

- **Named something like:** "GetInSync Integration" or "svc-getinsync-apm"
- **Active:** yes
- **License type:** whatever TDX requires to hold a Web Services Key; a Technician or similar license is the usual answer
- **Authentication:** GetInSync authenticates using the `BEID` and `Web Services Key` obtained from **TDAdmin → Organization Details**. Please share both values with GetInSync securely (not email, not chat — any shared password manager or secure hand-off is fine). GetInSync stores them in an encrypted secrets vault.

**Required permissions** (scope as tightly as possible — no admin, no security-role management, no ticketing access):

- Create, update, delete Configuration Items *in the "Applications" Asset/CI App only*
- Create and update Configuration Item Relationships in that same Asset/CI App
- Read People / Users (so GetInSync can resolve application owners to their TDX user records)
- Read Accounts / Departments (so GetInSync can resolve workspaces to departments)

**Permissions the service account must not have:**

- Any write access to the Asset/CI App that Sassafras / AllSight populates with software-inventory and endpoint data. GetInSync stays out of Sassafras's lane; the cleanest way to guarantee that is to not grant write permission there in the first place.
- Admin rights, security-role management, user management.
- Ticketing, problem, change, knowledge, service catalog write access.

**Rate-limit context.** GetInSync respects TDX's documented per-endpoint rate limits and runs at well under half of them. The connector is designed so that a full-portfolio refresh on a mid-sized tenant completes in tens of minutes, not seconds. If Garland's tenant has a non-standard rate-limit configuration, please let us know at the workshop.

**Service-account separation from Sassafras.** Please use two **different** TDX users — one for GetInSync, one for Sassafras / AllSight. Each writes into its own Asset/CI App; neither touches the other's space. Shared accounts blur audit trails and make incidents harder to diagnose. Two accounts, two audit trails, clean separation.

---

## 3. How GetInSync and Sassafras stay in their lanes

The tenant will have two automated writers. Here is how each stays on its own side of the fence:

| | GetInSync | Sassafras / AllSight |
|---|---|---|
| What it writes | Business applications | Installed software, endpoints, device inventory |
| Where it writes | The "Applications" Asset/CI App (this spec) | Its own Asset/CI App, provisioned by Sassafras or by Garland's implementer per Sassafras's guidance |
| Which CI types | Business Application (one type, defined in §2.2) | Sassafras-defined CI types (typically Installed Software, Endpoint, and similar) |
| Which service account | "svc-getinsync-apm" (or similar) | Sassafras's dedicated service account |
| What it reads | People, Accounts (for owner / department lookups) | Whatever Sassafras needs for its discovery process |
| What it **never touches** | Any Sassafras-populated CI type or Asset/CI App | Any CI in the "Applications" Asset/CI App |

The two systems can coexist in the same tenant peacefully because they write into different containers, with different credentials, and for different purposes. Over time — once the tenant is stable and both integrations are proven — Garland may want to cross-link the two (e.g., show which installed software runs a given business application). That is a future conversation, not a day-one requirement.

---

## 4. Implementation sequence for the TDX implementer

A suggested order of operations. Each step is straightforward in TDAdmin; the whole sequence should take a TDX implementer a few hours, plus time for review.

1. **Provision the Asset/CI App.** Name it "Applications" (or Garland's preferred name). Decide who owns it administratively — a senior TDAdmin user typical for CMDB governance.
2. **Create the Business Application CI type** inside that Asset/CI App.
3. **Create the 16 custom fields** listed in §2.3, attached to the Business Application CI type. Use the names, types, and choice lists as given; alert GetInSync at the workshop if any need to be changed before go-live.
4. **Create the relationship types** listed in §2.4 — Integrates With and Composed Of at a minimum, Depends On optional.
5. **Create a Form** (if TDX requires one to make the CI type usable) that includes the standard fields (Name, Owner, Owning Department, Active) and the 16 custom fields. Default layout is fine — the form's main role here is to make the CI legible in the TDX UI.
6. **Create the GetInSync service account** per §2.5. Generate its Web Services Key. Note the BEID from TDAdmin → Organization Details.
7. **Assign a security role** to the service account that grants exactly the permissions listed in §2.5 — CI CRUD and relationship CRUD in the Applications Asset/CI App, People and Accounts read, nothing else.
8. **Validate** per §5.
9. **Hand off credentials** (BEID + Web Services Key) to GetInSync through a secure channel.

---

## 5. Validation — confirming the tenant is ready

Before GetInSync attempts its first push, Garland's implementer should confirm each of the following. A short test CI created by the service account and then deleted is the cleanest proof.

1. **Service account can authenticate.** From a shell or Postman, `POST` to `/api/auth/loginadmin` with the BEID and Web Services Key; a bearer token comes back.
2. **Service account can create a Business Application CI.** Using the token, `POST` a minimal CI body (name + type ID) to `/api/{appId}/cmdb` with the Applications Asset/CI App's ID. A CI is created and its ID is returned.
3. **Service account can retrieve it.** `GET /api/{appId}/cmdb/{id}` returns the CI with all 16 custom attributes present (values may be null; attribute definitions must be there).
4. **Service account can update it.** `PUT /api/{appId}/cmdb/{id}` with a modified payload succeeds.
5. **Service account can create a relationship.** `PUT /api/{appId}/cmdb/{id}/relationships` (or the bulk endpoint) creates an "Integrates With" relationship between the test CI and another CI (Garland can use any existing CI as the other end for this validation).
6. **Service account can search People and Accounts.** `POST /api/people/lookup?searchText=` with a known Garland user name returns a user record; `POST /api/accounts/search` returns an Account. These are the lookups GetInSync uses to resolve Owner and Owning Department.
7. **Service account cannot do anything else.** Attempt any action outside the listed permissions — e.g., creating a ticket, writing a CI in a different Asset/CI App, or accessing a Sassafras CI type — and confirm the service account is denied. This is the safest posture.
8. **Delete the test CI.** Leave the tenant clean for the real first push.

GetInSync's connector also includes a "Tenant Readiness Check" that exercises the same path and reports a pass/fail per item. That check can be run ahead of any production sync.

---

## 6. Open items for Garland

Things the workshop will benefit from clarifying. GetInSync does not need answers to any of these to begin Phase 0 preparation, but answering them sharpens the May 14 discussion.

- **Who is implementing TDX on Garland's behalf?** In-house team, TeamDynamix's professional services, or an implementation partner? GetInSync wants to hand this spec to the right people and invite them into the workshop.
- **Timeline for TDX tenant provisioning.** When does Garland expect the Applications Asset/CI App, the CI type, the custom fields, and the service account to be in place? GetInSync's own work (on the NextGen side) can run in parallel, but integration testing needs a prepped tenant.
- **TDX sandbox vs production.** Does Garland have (or can Garland provision) a TDX sandbox we target during development, or do we go straight to production on a small validation portfolio?
- **Sassafras / AllSight status.** Is Sassafras already writing into Garland's TDX tenant, or is it being deployed in parallel? Knowing its state helps GetInSync understand what CI types already exist in the tenant and avoid any accidental overlap.
- **TDX AI and automation features.** If Garland plans to enable any TDX automation that looks at CIs — classification AI, automated relationship inference, health scoring — please flag which CI types it will touch. GetInSync-written fields are freshly overwritten on each sync; automated transforms on those fields will conflict.
- **Shared or separate service accounts across the two integrations.** This spec recommends separate service accounts for GetInSync and Sassafras. If Garland has a policy preference either way, please confirm.
- **Access for Garland's TDX team to review this spec.** Is this document suitable to share with Garland's implementer directly, or does Stuart at GetInSync plan to walk through it with them first? Either is fine; we want to match the spec's tone to the audience.

---

*End of specification. This document is a draft; numbers, field names, and modelling choices are all open to refinement during the May 14 workshop.*
