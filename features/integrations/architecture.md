# features/integrations/architecture.md
GetInSync Integrations Architecture  
Last updated: 2025-12-12

---

## 1. Purpose

Define the internal and external integration model for GetInSync.  
This architecture replaces the legacy "interfaces as applications" pattern and standardizes how BusinessApplications connect to each other and to external organizations.  
It supports the Next-Gen cost, deployment profile and product-based architecture.

---

## 2. Design Overview

Integrations describe data movement.  
Two types exist:

1. **Internal Integration** - between two BusinessApplications.  
2. **External Integration** - between a BusinessApplication and an ExternalEntity (vendor, partner, agency, SaaS endpoint).

Each integration stores direction, method, format, cadence, sensitivity and tags.  
External Integrations also reference Suppliers and Contacts.  
Integrations attach directly to the **BusinessApplication**, not to DeploymentProfiles.

DeploymentProfiles may surface integrations in visualizations later, but they do not store them.

---

## 3. Core Entities or Components

### 3.1 InternalIntegration

Represents data exchange between two BusinessApplications.

Fields:
- InternalIntegrationId (PK)
- Name  
- SourceBusinessApplicationId  
- TargetBusinessApplicationId  
- Direction (Publish | Subscribe)  
- Method (API, CSV, Excel, ServiceBus, SQLView, SFTP, Email)  
- Format (JSON, XML, CSV, XLSX)  
- Cadence (RealTime, Daily, Weekly, Monthly, AdHoc)  
- Sensitivity (Low, Moderate, High, Confidential)  
- Notes  

Behaviors:
- Source/target define publish/subscribe roles.  
- One-way integrations do not auto-generate reverse links.  
- Both endpoints must be BusinessApplications.

---

### 3.2 ExternalIntegration

Represents an external data flow.

Fields:
- ExternalIntegrationId (PK)
- Name  
- ExternalEntityId  
- SupplierId  
- ContactId (optional)  
- Direction  
- Method  
- Format  
- Cadence  
- Sensitivity  
- Notes  

Behaviors:
- ExternalEntity represents the outside system.  
- Supplier identifies the owning organization.  
- Contact represents a person at that Supplier.

---

### 3.3 BusinessApplicationExternalIntegration

Join between BusinessApplication and ExternalIntegration.

Fields:
- BusinessApplicationExternalIntegrationId (PK)
- BusinessApplicationId  
- ExternalIntegrationId  

---

### 3.4 ExternalEntity

Represents an external system or endpoint.

Fields:
- ExternalEntityId (PK)
- Name  
- EntityType (Vendor, Partner, Agency, ExternalSaaS)  
- Notes  

---

### 3.5 IntegrationContact

Links Contacts to Integrations with specific roles.

Fields:
- IntegrationContactId (PK)
- ContactId (FK)
- InternalIntegrationId (FK, nullable)
- ExternalIntegrationId (FK, nullable)
- IntegrationContactRoleId (FK)
- Notes

---

### 3.6 IntegrationContactRole (Authoritative Definition)

**This is the authoritative source for IntegrationContactRole.**
Other architecture files (e.g., core/involved-party.md) should reference this definition rather than re-defining the entity.

Fields:
- IntegrationContactRoleId (PK)
- Name
- Description (optional)
- IsActive (boolean)

Standard Values:
- Integration Owner
- Technical SME
- Data Steward
- Vendor Contact
- Support Contact

---

### 3.7 Data Tags

No changes required.  
Used to classify data domains or sensitivity.

---

## 4. Relationships to Other Domains

### 4.1 BusinessApplication  
- Links to InternalIntegrations (as source or target).  
- Links to ExternalIntegrations via BusinessApplicationExternalIntegration.  
- DeploymentProfiles do not hold integrations.

### 4.2 DeploymentProfile  
- No direct relationship.  
- May surface integration visibility in future lifecycle views only.

### 4.3 ITService  
- No direct relationship.

### 4.4 SoftwareProduct / ProductContract  
- No relationship; integrations handle data flow, not licensing.

### 4.5 External Integrations  
- Linked to Suppliers and optional Contacts.

### 4.6 Organizations / Contacts  
- Represent the external parties involved.
- IntegrationContact links Contacts to integrations with roles.

### 4.7 Involved Party Architecture
- IntegrationContactRole is authoritatively defined here.
- core/involved-party.md references this definition.

---

## 5. ASCII ERD (Conceptual)

```
BusinessApplication
        |
        | 1..* (as source or target)
        |
+-------------------------+
|   InternalIntegration   |
+-------------------------+
| InternalIntegrationId   |
| SourceBusinessAppId     |
| TargetBusinessAppId     |
| Direction               |
| Method                  |
| Format                  |
| Cadence                 |
| Sensitivity             |
+-------------------------+
```

```
BusinessApplication
        |
        | 1..* via BAExternalIntegration
        |
+-----------------------------------------+
| BusinessApplicationExternalIntegration  |
+-----------------------------------------+
| BAExternalIntegrationId                 |
| BusinessApplicationId                   |
| ExternalIntegrationId                   |
+-----------------------------------------+
                 |
                 | *..1
                 |
+----------------------------------+
|        ExternalIntegration       |
+----------------------------------+
| ExternalIntegrationId            |
| Name                             |
| ExternalEntityId                 |
| SupplierId                       |
| ContactId                        |
| Direction                        |
| Method                           |
| Format                           |
| Cadence                          |
| Sensitivity                      |
+----------------------------------+
                 |
                 | *..1
                 |
+-----------------------------+
|       ExternalEntity        |
+-----------------------------+
| ExternalEntityId            |
| Name                        |
| EntityType                  |
| Notes                       |
+-----------------------------+
```

```
ExternalIntegration
        |
        | *..1
        |
+-----------------------------+
|          Supplier           |
+-----------------------------+
| SupplierId                  |
| Name                        |
| Type                        |
+-----------------------------+
```

```
Integration Contact Model

+-------------------------+
|   IntegrationContact    |
+-------------------------+
| IntegrationContactId    |
| ContactId (FK)          |
| InternalIntegrationId   |
| ExternalIntegrationId   |
| IntegrationContactRoleId|
| Notes                   |
+-----------+-------------+
            |
            | *..1
            v
+---------------------------+
| IntegrationContactRole    |  <-- Authoritative Definition
+---------------------------+
| IntegrationContactRoleId  |
| Name                      |
| Description               |
| IsActive                  |
+---------------------------+
```

## 6. Migration Considerations

- Remove legacy "data feed applications" that were created to represent integrations.
- Convert those records into `ExternalIntegration` entries paired with new `ExternalEntity` records.
- Populate `Supplier` and `Contact` fields where details are available.
- Convert existing internal integration links into `InternalIntegration` records.
- Populate the `BusinessApplicationExternalIntegration` join table using legacy associations.
- Create `IntegrationContact` records for all known integration contacts.
- Populate `IntegrationContactRole` lookup table with standard values.

---

## 7. Open Questions or Follow-Up Work

- Should ExternalEntity include more specific subcategories such as SaaS endpoint or public agency?
- Should integrations support lifecycle states (Planned, Active, Deprecated, Retired)?
- Should the system block duplicate combinations of BusinessApplication and ExternalIntegration?
- Future enhancement: allow DeploymentProfiles to reference integrations for lifecycle visualization.

---

## 8. Out of Scope

- RBAC
- ServiceNow mapping
- API integration
- Integration discovery
- Cost model and DeploymentProfile architecture

## 9. Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.2 | 2025-12-12 | Fixed version mismatch (header now matches filename). Designated this file as authoritative source for IntegrationContactRole. Added IntegrationContact entity. Added note about cross-reference from core/involved-party.md. |
| v1.1 | 2025-02-14 | Previous version with header showing v1.0. |

End of file.
