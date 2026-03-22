# Crawl to Walk: What Comes Next

---

## Walk adds three major constructs

| Construct | Table | Purpose |
|-----------|-------|---------|
| Technical Service | `cmdb_ci_service` (classified as Technical) | Shared infrastructure services (Windows Hosting, Network Access, Identity Management) |
| Technical Service Offering | `svc_offering` | Operational variants of Technical Services with support/change groups |
| Dynamic CI Group | `cmdb_ci_query_based_service` | Query-based CI groupings for service management |

## Walk enables

- **Event Management** — correlate events to Application Services via infrastructure CIs
- **Change risk assessment** — understand blast radius via service dependency maps
- **Improved MTTR** — incidents auto-route through service hierarchy
- **Service Mapping** — auto-discover infrastructure below Application Services

## Walk prerequisites (build during Crawl)

While you're getting to Crawl, plan for Walk by:

1. **Cataloging shared infrastructure** — list your hosting platforms, database services,
   network services, identity providers. These become Technical Services.
2. **Deploying Discovery/Service Mapping** — requires ITOM license. Maps infrastructure
   CIs (servers, databases, load balancers) below Application Services.
3. **Defining service tiers** — Gold/Silver/Bronze SLA tiers become Technical Service
   Offering variants.

## Walk timeline

Most organizations reach Walk 3–6 months after achieving Crawl, depending on:
- ITOM licensing and Discovery deployment
- Organizational agreement on Technical Service taxonomy
- Support group alignment across infrastructure teams

## The full maturity path

| Phase | Focus | Key additions |
|-------|-------|--------------|
| **Foundation** | Base data | Locations, Users, Groups, Companies |
| **Crawl** | Application inventory | Business Applications + Application Services + relationships |
| **Walk** | Infrastructure services | Technical Services + Service Offerings + Dynamic CI Groups |
| **Run** | Business services | Business Services + Business Service Offerings + Service Portfolio |
| **Fly** | Strategic alignment | Information Objects + Business Capabilities + Value Streams |

## How GetInSync maps to the maturity model

| CSDM Phase | GetInSync Capability |
|------------|---------------------|
| Crawl | Application inventory, Deployment Profiles, ServiceNow publish |
| Walk | IT Service catalog, Technology Products, cost attribution |
| Run | Portfolio management, TIME/PAID assessment, roadmap planning |
| Fly | Business capability mapping (future), strategic alignment |

GetInSync is designed to accelerate organizations through Crawl → Walk → Run by
providing the data curation layer that ServiceNow's native tools lack.

---

*This toolkit covers Crawl. For Walk and beyond, GetInSync NextGen provides IT Service
cataloging, technology health tracking, and cost attribution — the data layers that
Walk and Run require. See getinsync.ca.*
