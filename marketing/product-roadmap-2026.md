# GetInSync NextGen - Product Roadmap 2026

**Vision:** QuickBooks for CSDM - ServiceNow APM readiness accelerator  
**Market:** Government & Enterprise customers requiring clean APM data  
**Competitive Edge:** 30-60 day implementations vs 6-12+ months for enterprise tools

---

## 🎯 Strategic Priorities

1. **Delta Independence** - Customer Success can operate without Stuart (Q1 2026) ✅
2. **Core APM Value** - Assessment + Portfolio + Costs deliver immediate ROI (Q1-Q2 2026)
3. **Scale & Automation** - Discovery + Integrations reduce manual data entry (Q2-Q3 2026)
4. **Market Differentiation** - AI features + Multi-region distinguish from competitors (Q3-Q4 2026)
5. **Enterprise Readiness** - SSO + Advanced features enable large deals (Q4 2026)

---

## 📦 AREA 1: Platform Operations & Enablement

**Strategic Goal:** Delta can independently operate, scale, and support customers

### ✅ Phase 25.8: Super Admin Provisioning (COMPLETE)
**Status:** Shipped Feb 1, 2026  
**Capability:** Delta creates trial namespaces, tracks pending invitations  
**Impact:** 100% Delta independence for customer onboarding

### 🔄 Phase 25.9: Namespace Management (PRIORITY 1)
**Effort:** 3-4 days  
**Capability:** Manage existing customers (tier changes, add workspaces, user management)  
**Components:**
- Namespace list view (search, filter by tier)
- Detail view: Overview, Workspaces, Users tabs
- Operations: Change tier, add workspace, manage user roles
- Safety: Confirmations for destructive operations, validation checks
**Blockers:** None  
**Delivers:** Complete operational control for Delta

### Phase 25.10: User Self-Service (PRIORITY 2)
**Effort:** 2-3 days  
**Capability:** Namespace admins invite users, manage workspace access independently  
**Components:**
- Invite User page (namespace admins only)
- Workspace member management
- User role assignment (admin/editor/steward/read_only)
- Bulk user upload (CSV import for enterprise)
**Blockers:** None  
**Delivers:** Reduces Delta support burden, enables enterprise scalability

### Phase 25.11: Platform Monitoring (MEDIUM PRIORITY)
**Effort:** 3-4 days  
**Capability:** Delta monitors platform health, usage, and issues proactively  
**Components:**
- Admin dashboard: Active namespaces, users, storage usage
- Namespace activity log (audit trail of admin actions)
- Error monitoring (failed logins, API errors, email bounces)
- Usage alerts (approaching tier limits, expiring trials)
**Blockers:** None  
**Delivers:** Proactive customer success, reduces reactive support

### Phase 25.12: Customer Impersonation (LOW PRIORITY)
**Effort:** 2-3 days  
**Capability:** Delta troubleshoots customer issues by viewing their account  
**Components:**
- "View as User" button in namespace management
- Impersonation banner (clear visual indicator)
- 30-minute session timeout
- Audit log of all impersonation sessions
**Blockers:** Security review required  
**Delivers:** Faster customer support resolution

---

## 🎨 AREA 2: User Experience & Polish

**Strategic Goal:** Professional, demo-ready UI that competes with enterprise tools

### 🔄 Phase 26.1: Application Form Redesign (PRIORITY 1)
**Effort:** 3-5 days  
**Capability:** Eliminate scroll jump, improve form usability  
**Components:**
- Option A: Wizard/stepped approach (About → Deployment → Costs)
- Option B: Tabbed interface (single page, tab switching)
- Option C: Modal for deployment details (simplified main form)
- Option D: Sticky accordion (sections stay open during edits)
**Blockers:** Decision on approach needed  
**Delivers:** Demo-ready form experience, reduced user frustration

### Phase 26.2: Mobile Responsiveness (MEDIUM PRIORITY)
**Effort:** 4-5 days  
**Capability:** Usable on tablets and mobile devices  
**Components:**
- Responsive dashboard layout
- Mobile-friendly assessment flow
- Touch-optimized bubble charts
- Collapsible navigation for small screens
**Blockers:** None  
**Delivers:** Field access for executives, broader usability

### Phase 26.3: Dark Mode (LOW PRIORITY)
**Effort:** 2-3 days  
**Capability:** Optional dark theme for UI  
**Components:**
- Theme toggle in user preferences
- Dark color palette (maintain brand colors)
- Persist preference in user settings
**Blockers:** None  
**Delivers:** Modern UX expectation, reduces eye strain

### Phase 26.4: Onboarding Wizard (MEDIUM PRIORITY)
**Effort:** 3-4 days  
**Capability:** First-time users guided through setup  
**Components:**
- Welcome screen with GetInSync value prop
- Guided tour: "Add your first application"
- Assessment configuration tutorial
- Data import options (manual, CSV, discovery)
**Blockers:** Phase 25.10 (user self-service) recommended first  
**Delivers:** Faster time-to-value, reduced support burden

---

## 📊 AREA 3: Core APM Features

**Strategic Goal:** Complete assessment → portfolio → cost → action workflow

### ✅ Phase 17: DP-Centric Assessment (COMPLETE)
**Status:** Shipped  
**Capability:** Deployment profiles as assessment anchor (not applications)

### Phase 27: Application Wizard (DEPRIORITIZED)
**Effort:** 4-5 days  
**Capability:** Guided creation of applications with AI assistance  
**Status:** Deprioritized in favor of operational readiness  
**Reconsider:** Q2 2026 after Delta independence complete

### Phase 28: Composite Applications (DESIGNED, NOT IMPLEMENTED)
**Effort:** 5-6 days  
**Capability:** Model application relationships (dependencies, integrations)  
**Components:**
- Relationship types: depends_on, integrates_with, provides_data_to
- Visual relationship diagram
- Impact analysis ("what breaks if we retire this?")
- Publisher/consumer assessment model (already implemented)
**Blockers:** None, design complete (core/composite-application.md)  
**Delivers:** Enterprise-grade APM capability, competitive differentiation

### Phase 29: Assessment Templates (MEDIUM PRIORITY)
**Effort:** 3-4 days  
**Capability:** Pre-configured assessment sets for common scenarios  
**Components:**
- Templates: Cloud migration, SaaS consolidation, Tech debt reduction
- Custom template builder (namespace admins)
- Import/export assessment configuration
- Industry-specific factor sets (government, healthcare, finance)
**Blockers:** None  
**Delivers:** Faster customer implementations, vertical market targeting

### Phase 30: Bulk Assessment Import (HIGH PRIORITY)
**Effort:** 3-4 days  
**Capability:** Import assessment scores from CSV/Excel  
**Components:**
- CSV template generator (includes current assessment factors)
- Bulk upload UI with validation
- Preview before commit
- Error handling (duplicate apps, invalid scores)
**Blockers:** None  
**Delivers:** Accelerates large portfolio onboarding (100+ applications)

---

## 💰 AREA 4: Cost Management

**Strategic Goal:** Complete TCO visibility from software → services → infrastructure

### ✅ Phase 25: IT Services & Budgets (COMPLETE)
**Status:** Shipped  
**Capability:** IT Service catalog, budget tracking, data center management

### Phase 31: Software Product Catalog (DESIGNED, PRIORITY 1)
**Effort:** 5-6 days  
**Capability:** Centralized software license management  
**Components:**
- Software products table (namespace-level)
- Link deployment profiles to shared products
- Aggregate licensing costs across DPs
- Vendor attribution for procurement
**Blockers:** None, design complete (catalogs/software-product.md)  
**Delivers:** Eliminate duplicate license data entry, vendor spend visibility

### Phase 32: Cost Bundles (DESIGNED, PRIORITY 2)
**Effort:** 3-4 days  
**Capability:** Bundle costs that don't fit software/services model  
**Components:**
- Cost bundle entity (consulting, one-time projects, amortized capex)
- Link bundles to applications
- Budget tracking for cost bundles
- Reporting: Total cost by application (all channels)
**Blockers:** Phase 31 (software products) recommended first  
**Delivers:** Complete cost picture, CFO-ready reporting

### Phase 33: Vendor Management (MEDIUM PRIORITY)
**Effort:** 4-5 days  
**Capability:** Centralized vendor database with spend tracking  
**Components:**
- Vendors table (namespace-level)
- Link software products → vendors
- Link IT services → vendors
- Vendor spend dashboard (total across all cost channels)
- Contract tracking (renewal dates, terms)
**Blockers:** Phase 31 (software products)  
**Delivers:** Procurement insights, vendor consolidation opportunities

### Phase 34: Budget Alerts (LOW PRIORITY)
**Effort:** 2-3 days  
**Capability:** Proactive notifications for budget overruns  
**Components:**
- Budget threshold configuration (80%, 100%, 110%)
- Email alerts to workspace admins
- Dashboard warnings for over-budget portfolios
- Historical burn rate tracking
**Blockers:** Phase 25 (budgets complete), Phase 31 (software products)  
**Delivers:** Financial governance, prevents surprise overruns

---

## 🔗 AREA 5: Data Discovery & Integration

**Strategic Goal:** Automate data collection, reduce manual entry burden

### Phase 35: Cloud Discovery - MVP (DESIGNED, HIGH PRIORITY)
**Effort:** 6-8 days  
**Capability:** Automated discovery of AWS/Azure/GCP resources  
**Components:**
- CSV import for cloud billing data
- Resource parser (EC2, RDS, Lambda, Azure VMs, GCP instances)
- Map resources → applications (AI-powered suggestions)
- Cost aggregation by application
**Blockers:** None, design complete (features/cloud-discovery/architecture.md)  
**Delivers:** Major competitive differentiator, reduces manual data entry

### Phase 36: Cloud Discovery - API Integration (HIGH PRIORITY)
**Effort:** 8-10 days  
**Capability:** Real-time cloud resource discovery via API  
**Components:**
- AWS API integration (Cost Explorer, EC2, RDS)
- Azure API integration (Cost Management, Resource Graph)
- GCP API integration (Cloud Billing, Compute Engine)
- OAuth credential management (per namespace)
- Automated daily sync
**Blockers:** Phase 35 (CSV import establishes data model)  
**Delivers:** Real-time cost tracking, automated updates

### Phase 37: ServiceNow Integration (MEDIUM PRIORITY)
**Effort:** 6-8 days  
**Capability:** Bi-directional sync with ServiceNow CMDB  
**Components:**
- Export to ServiceNow (CSDM-compliant format)
- Import from ServiceNow (CI discovery)
- Field mapping configuration
- Scheduled sync jobs
**Blockers:** None  
**Delivers:** ServiceNow readiness validation, data quality checks

### Phase 38: Technology Lifecycle Intelligence (DESIGNED, MEDIUM PRIORITY)
**Effort:** 5-6 days  
**Capability:** Automated EOL/EOS tracking from vendor websites  
**Components:**
- Web scraping for vendor lifecycle pages
- AI extraction of EOL dates
- Alerts for approaching end-of-life
- Replacement recommendations
**Blockers:** None, design complete (features/technology-health/lifecycle-intelligence.md)  
**Delivers:** Replaces expensive subscription services (Flexera, Gartner)

### Phase 39: Active Directory Integration (LOW PRIORITY)
**Effort:** 4-5 days  
**Capability:** Sync user data from AD/Entra ID  
**Components:**
- LDAP/Graph API connector
- User import with role mapping
- Group-based workspace assignment
- Automated user provisioning/deprovisioning
**Blockers:** Phase 25.10 (user self-service)  
**Delivers:** Enterprise scalability, reduced admin burden

---

## ðŸ” AREA 6: Security & Enterprise Features

**Strategic Goal:** SOC2 compliance, enterprise SSO, advanced permissions

### Phase 40: Entra ID SSO (DESIGNED, HIGH PRIORITY)
**Effort:** 5-6 days  
**Capability:** Enterprise single sign-on via Microsoft Entra ID  
**Components:**
- SAML/OAuth integration
- Namespace-level SSO configuration
- JIT (just-in-time) user provisioning
- Group-based role mapping
**Blockers:** None, design complete (archive/superseded/identity-security-v1_0.md)  
**Delivers:** Enterprise sales requirement, reduces support burden

### Phase 41: Advanced RBAC (MEDIUM PRIORITY)
**Effort:** 4-5 days  
**Capability:** Fine-grained permissions beyond workspace roles  
**Components:**
- Object-level permissions (who can edit specific portfolios/apps)
- Field-level security (hide sensitive cost data)
- Custom role builder (namespace admins define roles)
- Permission inheritance (workspace → portfolio → application)
**Blockers:** None  
**Delivers:** Enterprise governance, sensitive data protection

### Phase 42: Audit Logging (MEDIUM PRIORITY)
**Effort:** 3-4 days  
**Capability:** Comprehensive activity tracking for compliance  
**Components:**
- Log all CRUD operations (who, what, when, IP address)
- Searchable audit log UI
- Export to SIEM (Splunk, Azure Sentinel)
- Retention policy (configurable, default 1 year)
**Blockers:** None  
**Delivers:** SOC2 requirement, forensic analysis capability

### Phase 43: Data Residency & Multi-Region (DESIGNED, LOW PRIORITY)
**Effort:** 10-12 days (significant infrastructure work)  
**Capability:** Regional data isolation for regulatory compliance  
**Components:**
- Canada, US, EU regions
- Namespace-to-region assignment
- Regional database instances (Supabase multi-region)
- Cross-region replication for disaster recovery
**Blockers:** Significant infrastructure investment, Supabase architecture  
**Delivers:** EU/Canadian regulatory compliance, competitive edge

---

## 📈 AREA 7: Reporting & Analytics

**Strategic Goal:** Executive dashboards, portfolio insights, QuickSight integration

### Phase 44: Portfolio Insights Dashboard (MEDIUM PRIORITY)
**Effort:** 4-5 days  
**Capability:** Cross-portfolio analytics and comparisons  
**Components:**
- Multi-portfolio bubble chart (compare across workspaces)
- Portfolio health scorecard (avg scores, cost trends)
- Quadrant distribution analysis
- Remediation effort aggregation
**Blockers:** None, concept in portfolio-insights-concept.md  
**Delivers:** Executive visibility, optimization opportunities

### Phase 45: QuickSight Integration (DESIGNED, MEDIUM PRIORITY)
**Effort:** 6-8 days  
**Capability:** Embedded AWS QuickSight dashboards  
**Components:**
- QuickSight dataset generation (Athena views)
- Embedded dashboard iframe
- Row-level security (namespace isolation)
- Pre-built dashboard templates
**Blockers:** AWS account setup, QuickSight licensing  
**Delivers:** Advanced analytics, competitive parity with enterprise tools  
**Reference:** archive (superseded — frontend React charts)

### Phase 46: Custom Report Builder (LOW PRIORITY)
**Effort:** 5-6 days  
**Capability:** User-defined reports without SQL knowledge  
**Components:**
- Drag-and-drop report designer
- Filter builder (date range, portfolio, scores, costs)
- Export to PDF, Excel, PowerPoint
- Scheduled report delivery (email)
**Blockers:** Phase 44 (portfolio insights establishes patterns)  
**Delivers:** Self-service analytics, reduces Stuart/Delta ad-hoc requests

### Phase 47: Executive Summaries (AI-Powered) (LOW PRIORITY)
**Effort:** 4-5 days  
**Capability:** Auto-generated portfolio narratives  
**Components:**
- AI summary of portfolio health
- Key findings and recommendations
- Trend analysis (month-over-month changes)
- Natural language insights ("3 applications at risk of EOL")
**Blockers:** Phase 44 (portfolio insights), AI infrastructure  
**Delivers:** C-suite presentation ready, thought leadership

---

## 🤖 AREA 8: AI & Automation

**Strategic Goal:** AI-powered insights, application mapping, recommendation engine

### Phase 48: AI Application Mapping (DESIGNED, HIGH PRIORITY)
**Effort:** 6-8 days  
**Capability:** AI suggests application relationships and dependencies  
**Components:**
- Analyze cloud resources → suggest application groupings
- Network traffic analysis (VPC flow logs) → dependency mapping
- User survey integration ("which apps does Finance use?")
- Confidence scoring for recommendations
**Blockers:** Phase 35 (cloud discovery provides data)  
**Delivers:** Automates hardest APM task (application identification)  
**Reference:** catalogs/business-application-identification.md

### Phase 49: Assessment Co-Pilot (MEDIUM PRIORITY)
**Effort:** 5-6 days  
**Capability:** AI assists with assessment completion  
**Components:**
- Question rephrasing ("explain this factor in plain English")
- Score suggestions based on deployment profile
- Identify missing information ("you need to set DR status first")
- Consistency checks ("this score conflicts with hosting type")
**Blockers:** None  
**Delivers:** Faster assessments, higher data quality

### Phase 50: Recommendation Engine (LOW PRIORITY)
**Effort:** 6-8 days  
**Capability:** AI-powered optimization recommendations  
**Components:**
- Consolidation opportunities (duplicate software products)
- Migration candidates (on-prem → cloud cost analysis)
- Retirement recommendations (low business fit + high cost)
- Vendor consolidation (multiple products from same vendor)
**Blockers:** Phase 31 (software products), Phase 32 (cost bundles)  
**Delivers:** Actionable insights, ROI justification for platform

---

## 🚀 AREA 9: Publishing & Ecosystem

**Strategic Goal:** GetInSync as data hub, publish to ServiceNow/Power Platform

### Phase 51: ServiceNow APM Publishing (DESIGNED, MEDIUM PRIORITY)
**Effort:** 6-8 days  
**Capability:** Export portfolio data to ServiceNow APM  
**Components:**
- CSDM-compliant export format
- Application, Business Service, Technical Service entities
- Deployment profile → CI mapping
- Assessment scores → APM metrics
**Blockers:** None, design complete (features/integrations/servicenow-alignment.md)  
**Delivers:** ServiceNow readiness accelerator (core value prop)

### Phase 52: Power Platform Publishing (LOW PRIORITY)
**Effort:** 5-6 days  
**Capability:** Export to Power Apps, Power BI, SharePoint  
**Components:**
- Power BI dataset (live connection or scheduled refresh)
- SharePoint list export (application inventory)
- Power Apps connector (custom connector)
- Power Automate triggers (on assessment complete)
**Blockers:** None  
**Delivers:** Microsoft ecosystem integration, government market fit

### Phase 53: API Ecosystem (LOW PRIORITY)
**Effort:** 8-10 days  
**Capability:** Public API for custom integrations  
**Components:**
- RESTful API (applications, portfolios, assessments)
- API key management
- Rate limiting and usage tracking
- OpenAPI/Swagger documentation
- Webhooks for events (assessment complete, threshold breach)
**Blockers:** None  
**Delivers:** Enterprise extensibility, partner ecosystem enablement

---

## 📱 AREA 10: Tier Feature Differentiation

**Strategic Goal:** Clear value progression from Free → Pro → Enterprise → Full

### Current Tier Model
- **Free:** 2 workspaces, view DPs, basic assessment
- **Pro:** 5 workspaces, edit DPs (hosting, cloud, region, DR)
- **Enterprise:** Unlimited workspaces, multiple DPs per app, advanced reporting
- **Full:** Software Products, IT Services, Publishing, API

### Phase 54: Tier Feature Audit (PRIORITY 1)
**Effort:** 1-2 days  
**Capability:** Document what features work at each tier, identify gaps  
**Components:**
- Feature matrix spreadsheet
- Test each tier (create test namespaces)
- Document upgrade teasers currently implemented
- Identify missing tier restrictions
**Blockers:** None  
**Delivers:** Clarity on tier boundaries, sales enablement

### Phase 55: Upgrade Flow (MEDIUM PRIORITY)
**Effort:** 3-4 days  
**Capability:** Self-service tier upgrades (with payment integration later)  
**Components:**
- "Upgrade" button in tier limit teasers
- Tier comparison page (feature matrix)
- Request upgrade form (for manual approval initially)
- Future: Stripe integration for credit card payment
**Blockers:** Stripe account setup (for automated payment)  
**Delivers:** Revenue automation, reduces Delta involvement

### Phase 56: Usage Analytics per Tier (LOW PRIORITY)
**Effort:** 2-3 days  
**Capability:** Track feature usage by tier for product decisions  
**Components:**
- Analytics events (which features used, how often)
- Dashboard: Usage by tier, feature adoption
- Identify upgrade triggers (what causes users to hit limits)
**Blockers:** Analytics infrastructure (PostHog, Mixpanel)  
**Delivers:** Data-driven product decisions, pricing optimization

---

## 🗓ï¸ Recommended Sequencing

### 🔥 IMMEDIATE (Feb 2026) - Delta Operational Readiness
**Focus:** Delta can fully operate platform independently  
**Duration:** 1-2 weeks

1. **Phase 25.9: Namespace Management** (3-4 days) - CRITICAL
2. **Phase 26.1: Application Form Redesign** (3-5 days) - Demo polish
3. **Phase 54: Tier Feature Audit** (1-2 days) - Sales clarity

**Outcome:** Delta independent, demos professional, ready for customer growth

---

### 📈 Q1 2026 (Mar) - Core Value Delivery
**Focus:** Complete core APM workflow, enable first customer wins  
**Duration:** 3-4 weeks

4. **Phase 31: Software Product Catalog** (5-6 days) - Cost visibility
5. **Phase 30: Bulk Assessment Import** (3-4 days) - Large portfolio onboarding
6. **Phase 25.10: User Self-Service** (2-3 days) - Enterprise scalability
7. **Phase 28: Composite Applications** (5-6 days) - Enterprise feature

**Outcome:** Complete TCO visibility, enterprise-ready, differentiated from competitors

---

### 🚀 Q2 2026 (Apr-Jun) - Automation & Scale
**Focus:** Reduce manual data entry, automate discovery  
**Duration:** 8-10 weeks

8. **Phase 35: Cloud Discovery - CSV** (6-8 days) - Quick win
9. **Phase 36: Cloud Discovery - API** (8-10 days) - Major differentiator
10. **Phase 48: AI Application Mapping** (6-8 days) - Automation value
11. **Phase 40: Entra ID SSO** (5-6 days) - Enterprise requirement
12. **Phase 32: Cost Bundles** (3-4 days) - Complete cost model

**Outcome:** Automated discovery, AI-powered insights, enterprise SSO

---

### ðŸ¢ Q3 2026 (Jul-Sep) - Enterprise & Compliance
**Focus:** Large enterprise deals, government compliance  
**Duration:** 8-10 weeks

13. **Phase 42: Audit Logging** (3-4 days) - SOC2 requirement
14. **Phase 41: Advanced RBAC** (4-5 days) - Enterprise governance
15. **Phase 51: ServiceNow Publishing** (6-8 days) - Core value prop delivery
16. **Phase 37: ServiceNow Integration** (6-8 days) - Bi-directional sync
17. **Phase 44: Portfolio Insights** (4-5 days) - Executive dashboards

**Outcome:** SOC2 ready, ServiceNow validated, enterprise governance

---

### ðŸŒ Q4 2026 (Oct-Dec) - Market Expansion
**Focus:** Vertical markets, partner ecosystem, advanced features  
**Duration:** 10-12 weeks

18. **Phase 45: QuickSight Integration** (6-8 days) - Advanced analytics
19. **Phase 38: Technology Lifecycle Intelligence** (5-6 days) - Replaces expensive tools
20. **Phase 53: API Ecosystem** (8-10 days) - Partner enablement
21. **Phase 52: Power Platform Publishing** (5-6 days) - Government market
22. **Phase 55: Upgrade Flow** (3-4 days) - Revenue automation

**Outcome:** Market differentiation, partner ecosystem, revenue scalability

---

## 📊 Effort Summary by Area

| Area | Total Effort | Priority Phases | Nice-to-Have |
|------|-------------|-----------------|--------------|
| 1. Platform Operations | 15-19 days | 25.9, 25.10 | 25.11, 25.12 |
| 2. User Experience | 12-17 days | 26.1 | 26.2, 26.3, 26.4 |
| 3. Core APM Features | 20-26 days | 30, 28 | 27, 29 |
| 4. Cost Management | 17-22 days | 31, 32 | 33, 34 |
| 5. Discovery & Integration | 29-37 days | 35, 36 | 37, 38, 39 |
| 6. Security & Enterprise | 22-28 days | 40 | 41, 42, 43 |
| 7. Reporting & Analytics | 15-21 days | 44, 45 | 46, 47 |
| 8. AI & Automation | 17-22 days | 48 | 49, 50 |
| 9. Publishing & Ecosystem | 19-24 days | 51 | 52, 53 |
| 10. Tier Differentiation | 6-9 days | 54 | 55, 56 |

**Total Roadmap:** ~172-225 days (8-11 months of focused development)

---

## 🎯 Success Metrics by Quarter

**Q1 2026:**
- ✅ Delta creates 10+ trial namespaces independently
- ✅ First 3 paying customers (Pro or Enterprise tier)
- ✅ Average implementation time: <60 days
- ✅ Customer NPS: >40

**Q2 2026:**
- ✅ Cloud discovery adopted by 50%+ of customers
- ✅ Average applications per customer: >100
- ✅ Automated data entry: >60% of applications discovered vs manual
- ✅ First enterprise deal (>$50K ARR)

**Q3 2026:**
- ✅ SOC2 Type I certification complete
- ✅ ServiceNow export validated by 3+ customers
- ✅ 10+ paying customers
- ✅ Churn rate: <10% annually

**Q4 2026:**
- ✅ 25+ paying customers
- ✅ Partner ecosystem: 2+ implementation partners
- ✅ ARR: $500K+ (target)
- ✅ Product-led growth: 50%+ signups via self-service

---

## 🚧 Dependencies & Risks

### Critical Path Dependencies
1. **Phase 25.9** blocks **25.10** (namespace mgmt before user self-service)
2. **Phase 31** blocks **32, 33, 34** (software products before cost bundles/vendors)
3. **Phase 35** blocks **36, 48** (CSV discovery before API/AI mapping)
4. **Phase 44** blocks **45, 46** (insights before QuickSight/custom reports)

### Technical Risks
- **Cloud Discovery:** API rate limits, credential management complexity
- **ServiceNow Integration:** CSDM schema changes, version compatibility
- **Multi-Region:** Significant infrastructure investment, Supabase limitations
- **AI Features:** Accuracy concerns, OpenAI API costs, hallucination risk

### Market Risks
- **Competition:** Flexera/LeanIX price cuts, ServiceNow APM improvements
- **Sales Cycle:** Government procurement delays (6-12 months)
- **Churn:** Customers implement then cancel (post-ServiceNow migration)
- **Talent:** Stuart as single technical resource (bus factor = 1)

### Mitigation Strategies
- **Start small:** CSV discovery before API (validate model first)
- **Partner early:** ServiceNow ISV partnership for validation
- **Hire strategically:** Add developer Q2 2026 (after product-market fit)
- **Focus:** Nail core APM workflow before expanding to nice-to-haves

---

## 💡 Key Architectural Decisions

### Now vs Later Trade-offs

**Do Now (Technical Debt Worth Taking):**
- Smooth scroll CSS fix instead of form redesign (ship fast, fix later)
- Manual tier upgrades before Stripe integration (validate pricing first)
- CSV discovery before API (prove value, then automate)
- Namespace-level SSO before user-level (simpler, covers 90% of cases)

**Do Right the First Time (No Shortcuts):**
- Multi-tenant data isolation (RLS policies, namespace scoping)
- CSDM alignment for ServiceNow export (competitive moat)
- Deployment profile as assessment anchor (architectural foundation)
- Cost model separation (software/services/bundles - don't mix)

**Avoid Entirely (Out of Scope):**
- Custom assessment factors (stick to APQC/OOTB, not consulting)
- On-premise deployment (SaaS-only keeps infrastructure simple)
- White-labeling (focus on GetInSync brand, not reseller model)
- Free tier overage billing (upgrade or block, don't surprise charge)

---

## 📞 Stakeholder Communication

### Delta (Customer Success Director)
**Needs to Know:**
- Phase 25.9 delivery date (namespace management)
- Which features are tier-gated (sales clarity)
- Common customer objections and responses
- When to bring Stuart into pre-sales (complex integrations)

**Weekly Sync:** Feature releases, customer feedback, blockers

### Customers
**Needs to Know:**
- Roadmap transparency (what's coming, when)
- How to request features (feedback loop)
- Breaking changes (rare, but communicate 30 days ahead)
- Success stories (case studies, ROI examples)

**Monthly Newsletter:** Feature releases, tips & tricks, customer spotlights

### Investors/Board (Future)
**Needs to Know:**
- Revenue milestones (ARR growth)
- Customer count and churn
- Competitive positioning updates
- Hiring plans and burn rate

**Quarterly Business Review:** Metrics dashboard, roadmap progress, asks

---

## 🎓 Learning & Iteration

### Feedback Loops

**Customer Feedback:**
- In-app feedback button (every page)
- Quarterly customer advisory board (top 5 customers)
- Feature voting (ProductBoard, Canny)
- Usage analytics (what features are used/ignored)

**Delta Feedback:**
- Weekly 1:1 (blockers, customer insights, competitive intel)
- Demo rehearsals (identify UX friction before prospects see it)
- Support ticket themes (what questions repeat?)

**Market Feedback:**
- Competitive analysis (quarterly deep dive on Flexera, LeanIX, ServiceNow)
- Analyst relations (Gartner, Forrester - when budget allows)
- Conference attendance (ServiceNow Knowledge, Gartner IT Symposium)

### Pivot Points

**When to Accelerate:**
- Customer asking for feature = pull it forward (signal of willingness to pay)
- Competitor launches weak version = ship better version fast (land grab)
- Government RFP requires feature = prioritize (revenue opportunity)

**When to Pause:**
- Feature not used = cut scope or redesign (don't build more on weak foundation)
- Customer churn due to missing feature = emergency priority (revenue risk)
- Technical debt blocking velocity = refactor sprint (long-term speed)

---

*Roadmap Version: 1.0*  
*Last Updated: February 1, 2026*  
*Owner: Stuart Holtby*  
*Review Cadence: Monthly (adjust based on customer feedback and market changes)*
