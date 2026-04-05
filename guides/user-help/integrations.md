# Managing Application Integrations

Integrations document the data flows between your applications and between your applications and external systems. Understanding these connections is critical before making any portfolio changes — you need to know what will break before you retire, migrate, or modernize an application.

---

## Why Document Integrations?

Most portfolio problems come from undocumented dependencies. An application that looks safe to retire might be sending nightly data feeds to three other systems. A migration project might fail because nobody mapped the downstream integrations.

Documenting integrations helps you:

- **Understand dependencies** — Know what connects to what before making changes
- **Assess data sensitivity** — Track what data flows between systems and how sensitive it is
- **Identify single points of failure** — Find applications that are integration hubs
- **Plan migrations safely** — Know every connection that needs to be rebuilt or redirected

---

## Internal vs. External Integrations

GetInSync tracks two types:

### Internal Integrations

Data flows **between your own applications**. For example:

- HR System sends employee data to Payroll System
- CRM sends customer records to the Data Warehouse
- ERP sends purchase orders to the Inventory System

Both the source and target are applications in your portfolio.

### External Integrations

Data flows **between your application and an outside system**. For example:

- Payroll sends tax filings to the government revenue agency
- CRM receives leads from a third-party marketing platform
- ERP sends invoices to a vendor's supplier portal

The external system is not in your portfolio — it belongs to a partner, vendor, or government agency.

---

## Integration Properties

Each integration captures:

| Property | Description |
|----------|-------------|
| **Direction** | Upstream (receives data), Downstream (sends data), or Bidirectional (both) |
| **Method** | How data moves: API, File Transfer, Database Link, SSO, Manual, Event-Driven, or Other |
| **Frequency** | How often: Real-Time, Batch Daily, Weekly, Monthly, or On-Demand |
| **Data Format** | JSON, XML, CSV, XLSX, or other format |
| **Data Sensitivity** | Low, Moderate, High, or Confidential |
| **Data Classification** | Public, Internal, Confidential, or Restricted |
| **Status** | Planned, Active, Deprecated, or Retired |

---

## Adding an Integration

### Internal Integration

1. Open the source or target application
2. Go to the **Integrations** tab
3. Click **Add Connection**
4. Select **Internal**
5. Pick the other application from your portfolio
6. If either application has multiple deployment profiles, you can optionally select which deployment profile the integration runs through. If the application has only one deployment profile, it is assigned automatically.
7. Set the direction (is your application sending, receiving, or both?)
8. Fill in method, frequency, data format, and sensitivity
9. Save

The integration appears on both applications' integration tabs automatically. When a deployment profile is specified, it appears alongside the application name in the connections list.

### External Integration

1. Open the application
2. Go to the **Integrations** tab
3. Click **Add Connection**
4. Select **External**
5. Describe the external entity (name, organization)
6. If your application has multiple deployment profiles, you can optionally select which deployment profile this integration runs through.
7. Set the direction, method, frequency, and other properties
8. Save

---

## Reading the Integration View

On an application's Integrations tab, you will see:

- **Upstream connections** — Systems that send data TO this application
- **Downstream connections** — Systems that this application sends data TO
- **Bidirectional connections** — Two-way data flows

Each connection shows the method, frequency, and data sensitivity at a glance. Click any integration to see full details or to edit.

---

## Integration Contacts

Each integration can have associated contacts — the people who own, manage, or support the data flow. This is especially important for external integrations where you need a point of contact at the partner organization.

---

## Using Integrations in Portfolio Decisions

Before creating a Roadmap initiative to retire or migrate an application, check its integrations:

1. **Open the application's Integrations tab**
2. **Count the connections** — An application with 15 integrations is much harder to retire than one with 2
3. **Check data sensitivity** — High-sensitivity data flows need special handling during migration
4. **Identify critical paths** — Real-time API integrations are more impactful than monthly batch files
5. **Document in the initiative** — Include integration remediation in your Roadmap initiative's scope and cost estimate

---

## Next Steps

- [What Are Deployment Profiles?](deployment-profiles.md) — Understand where applications run
- [Creating and Managing Initiatives](roadmap-initiatives.md) — Plan changes that account for integrations
- [Getting Started](getting-started.md) — Back to the onboarding guide
