# Technology Health — Badge Reference

**Document:** `guides/user-documentation/technology-health-badges.md`
**Version:** v1.0
**Status:** Draft — for GitBook iteration
**Date:** 2026-03-12

> This document defines the badge statuses shown on Technology Health screens.
> It serves as the source of truth for GitBook user documentation.

---

## Screen: Technology Health > By Application / Analysis

Two badge types appear next to each technology product in the OS, Database, and Web Server columns.

### Lifecycle Badges

These indicate the vendor's support status for the technology version.

| Badge | Color | Meaning | User Action |
|-------|-------|---------|-------------|
| **Mainstream** | Green | Vendor actively supports this version with updates and patches. | None needed. |
| **Extended Support** | Amber | Vendor provides limited support (security fixes only). Approaching end of life. | Plan migration to a newer version. |
| **End of Support** | Red | Vendor no longer provides any support or security patches. | Migrate urgently — security risk. |
| **Preview** | Blue | Pre-release or beta version. Not yet generally available. | Do not use in production. |
| **Incomplete Data** | Gray | Lifecycle dates are missing or incomplete. | Link to endoflife.date or enter lifecycle dates manually. |
| **Business/Vendor Managed** | Gray | SaaS or vendor-hosted — lifecycle managed by the vendor. | No action needed. |

### Standards Conformance Badges

These indicate how the technology aligns with your organization's asserted technology standards. Standards are set by administrators on the **Standards** tab.

| Badge | Color | Meaning | User Action |
|-------|-------|---------|-------------|
| **Preferred** | Dark Green | This is the recommended version of an asserted standard. New deployments should use this. | None — this is the target state. |
| **Conforming** | Green | This technology belongs to a standard family but is not the preferred version. | Consider upgrading to the preferred version. |
| **Containment** | Orange | This technology is a recognized standard that is being retired. No new deployments allowed; existing ones should plan migration. | Plan migration to the replacement standard. |
| **Under Review** | Yellow | This technology family is under governance review. Status will be updated after review. | Await governance decision. |
| **Non-Standard** | Red | This technology family has been explicitly rejected by the organization. | Migrate to an approved standard. |
| **Non-Conforming** | Yellow | This technology deviates from asserted standards in its category. *(Future — requires category-level review completion.)* | Review with architecture governance team. |
| *(no badge)* | — | No standard has been asserted for this technology's category/family. | No action — standards have not been defined yet. |

---

## Screen: Technology Health > Standards

### Standard Assertion Statuses

These are set by administrators when reviewing implied standards detected by the system.

| Badge | Color | Meaning |
|-------|-------|---------|
| **Standard** | Green | Confirmed organizational technology choice. |
| **Non-Standard** | Red | Explicitly rejected — not an approved technology. |
| **Under Review** | Yellow | Flagged for governance review. Neither confirmed nor denied. |
| **Retiring** | Orange | Currently a standard but has a planned sunset date. New deployments should use the replacement. Maps to "Containment" on deployment tags. |
| **Implied** | Gray | System-detected from deployment data. Prevalence above threshold but no human review yet. |

---

## How Standards and Conformance Relate

1. **Admin asserts a standard** on the Standards tab (e.g., marks "Windows Server" as Standard with preferred version "Windows Server 2022").
2. **Tags are evaluated** against asserted standards:
   - A tag using Windows Server 2022 → **Preferred** (matches preferred version)
   - A tag using Windows Server 2019 → **Conforming** (same family, not preferred)
   - A tag using RHEL → *(no badge)* if RHEL hasn't been reviewed, or **Containment** if RHEL is marked Retiring
3. **No badge** means no assertion exists for that technology's family — the organization hasn't expressed a position on it yet.

---

## ServiceNow / CSDM Alignment

| GetInSync Badge | ServiceNow Technology Portfolio Equivalent |
|----------------|---------------------------------------------|
| Standard | Strategic / Approved |
| Preferred | Strategic — Preferred Version |
| Conforming | Approved |
| Containment | Containment — No New Deployments |
| Under Review | Emerging / Under Evaluation |
| Non-Standard | Not Permitted / Prohibited |
| Retiring (assertion) | Retirement — Sunset Date Set |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-12 | Initial badge reference: lifecycle badges, standards conformance badges, assertion statuses, ServiceNow alignment. |
