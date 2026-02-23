# catalogs/business-application-identification.md
GetInSync Architecture Specification

Last updated: 2026-01-15

## 1. Purpose

Define what constitutes a business application within Application Portfolio Management (APM). Not all software should be treated equally. The goal is to identify and manage systems that deliver structured, function-specific business value.

This guidance resolves common points of confusion:
- The difference between a tool, platform, and business application
- Whether IT-delivered services can be business applications (they can)
- How to track and manage non-application software assets
- What we mean by "the business" in a public sector context

## 2. Business Application Definition

A business application is a logical representation of the software and infrastructure used to carry out a specific business function. It includes all environments (Production, Test, Dev) and is regarded as a strategic asset within the application portfolio.

### The 7 Criteria

To qualify as a business application, a system must meet ALL of the following:

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | Supports a defined business function | Not just general productivity |
| 2 | Contains structured data | Database, records, transactions |
| 3 | Has accountable business ownership | Someone is responsible |
| 4 | Delivers a business outcome | Measurable value |
| 5 | Is formally managed | Not ad-hoc or informal |
| 6 | Has identifiable users | Known user base |
| 7 | Has operational lifecycle | Deployed, maintained, retired |

### Platform-Built Applications

Applications built on platforms (e.g., SharePoint, Dynamics, Power Apps) qualify IF they are implemented for a specific purpose with structured data and business ownership. These often have their own name or acronym (e.g., "HR Hub," "iStore," "Sales Tax Portal") and should be tracked individually, not just under the platform name.

## 3. What Doesn't Qualify

The following do NOT qualify as business applications:

| Category | Examples |
|----------|----------|
| Infrastructure software | OS, databases, integration layers |
| Security tools | Firewalls, antivirus, endpoint protection |
| Productivity tools | Word, Excel, PowerPoint, Adobe |
| Informal artifacts | Spreadsheets, dashboards, scripts (unless formally managed) |
| Generic platform usage | Team SharePoint sites, file shares |

These may still be tracked and supported, but they fall outside the scope of business application management.

## 4. Classification Workflow

```
START: Is this software?
    │
    ▼
Step 1: Does it support a defined business function?
    │ No → Not a business application
    ▼ Yes
Step 2: Does it contain structured data?
    │ No → Not a business application
    ▼ Yes
Step 3: Does it have accountable business ownership?
    │ No → Not a business application
    ▼ Yes
Step 4: Does it deliver a business outcome?
    │ No → Not a business application
    ▼ Yes
Step 5: Is it formally managed?
    │ No → Not a business application
    ▼ Yes
Step 6: Does it have identifiable users?
    │ No → Not a business application
    ▼ Yes
Step 7: Does it have an operational lifecycle?
    │ No → Not a business application
    ▼ Yes
    │
    ▼
RESULT: This is a Business Application
        → Track in GetInSync
        → Assess with TIME/PAID
```

## 5. What We Mean by "The Business"

In this context, "the business" includes any branch or team that delivers services or performs internal functions in support of government objectives:

- Ministry programs and services
- Corporate functions (HR, Finance, Communications)
- IT service lines that deliver services across government (e.g., cybersecurity, digital identity)

When these teams use software to deliver a business outcome, that software may qualify as a business application—even if it's built or run by IT.

## 6. Edge Case: IT-Operated Business Applications

Some systems—particularly those utilized by IT—do not clearly fall into typical categories like "business application" or "infrastructure." However, they still support structured processes, handle data, and provide services.

**Example: CyberInt Attack Surface Management (ASM)**

Used by the security team for asset discovery, vulnerability management, and threat visibility. If we view the security team as a business unit, ASM qualifies as a business application because it meets all seven criteria:

- Supports defined security function ✓
- Contains structured vulnerability data ✓
- Has accountable ownership (Security team) ✓
- Delivers business outcome (reduced risk) ✓
- Is formally managed ✓
- Has identifiable users (security analysts) ✓
- Has operational lifecycle ✓

**Conclusion:** ASM qualifies as a business application because it supports a defined security function, is managed by a business unit, and delivers structured, actionable data.

## 7. Implications for GetInSync Architecture

### What Gets Tracked

| Item | Track in GetInSync? | Entity Type |
|------|---------------------|-------------|
| SharePoint (platform) | Yes | IT Service or Software Deployment |
| Generic team SharePoint site | No | Not a business app |
| "Sales Tax Portal" (on SharePoint) | Yes | Application |
| "HR Hub" (on SharePoint) | Yes | Application |
| Oracle Database (platform) | Yes | Software Deployment |
| Sage 300 General Ledger | Yes | Application |

### The Scaling Reality

```
Platform: SharePoint Online
├── 500 SharePoint sites exist
├── Apply 7-step workflow
├── ~20 qualify as Business Applications
└── Only 20 tracked and assessed in GetInSync
```

This means:
- No need for T-score inheritance complexity
- Each qualified application gets its own assessment
- Expert assesses "fit for purpose" holistically
- Manageable portfolio size

## 8. Application Portfolio Scope

While this definition helps classify business applications, the APM practice is broader. GetInSync includes:

- Tracking business applications that meet the criteria above
- Managing non-application assets such as platforms, tools, and infrastructure (via Software Catalog, IT Services)
- Recording relationships to databases and underlying services

## 9. Open Questions

1. Should GetInSync include a "qualification wizard" to help users apply the 7 criteria?
2. How do we handle borderline cases where criteria are partially met?
3. Should non-qualifying software be tracked elsewhere (CMDB integration)?

## 10. Out of Scope

- Detailed CMDB integration specifications
- Automated discovery of platform-built applications
- Cost allocation for shared platforms
