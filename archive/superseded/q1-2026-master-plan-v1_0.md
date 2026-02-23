# gis-q1-2026-master-plan-v1.0
GetInSync NextGen - Q1 2026 Master Execution Plan  
Last updated: 2026-02-07

---

## Executive Summary

**Timeline:** February 10 - March 31, 2026 (7 weeks)  
**Owner:** Stuart Holtby  
**Status:** Ready for Execution

### Key Metrics
- **Available Dev Days:** 20-25 days (realistic capacity)
- **Committed Work:** 21-27 days
- **Buffer:** 3-5 days (customer support, bugs, flexibility)
- **Status:** On Track ✓

### Strategic Decision
**Build Order:** Integration Management → IT Value Creation → SSO (or Polish)  
**Deferred to Q2:** Composite Applications (architectural risk - changes core DP model)

---

## Key Milestones

| Date | Status | Milestone |
|------|--------|-----------|
| Feb 7, 2026 | ✓ Complete | Phase 25.9 Complete (RLS Migration - All 66 tables) |
| Feb 21, 2026 | Target | Delta 100% Operational (Namespace UI Complete) |
| Feb 28, 2026 | Target | Integration Management Shipped |
| Mar 14, 2026 | Target | IT Value Creation Shipped |
| Mar 28, 2026 | Target | SSO Complete OR Feature Polish |
| Mar 31, 2026 | Target | Q1 Complete - Enterprise Ready |

---

## Q1 Success Criteria

### Operations
- ✅ Delta 100% independent (no SQL needed)
- ✅ Namespace Management UI operational
- ✅ Platform admin tools complete

### Enterprise Credibility
- ✅ Professional website deployed
- ✅ Privacy Policy + Terms updated (OAuth ready)
- ✅ OAuth social login working (Google + Microsoft)
- ✅ Entra ID SSO functional OR deferred with plan
- ✅ Multi-region architecture ready

### Competitive Differentiation
- ✅ Integration Management shipped (FOIP/compliance tracking)
- ✅ IT Value Creation shipped (strategic roadmaps)
- ✅ Features competitors don't have

### Market Positioning
- ✅ "QuickBooks for CSDM" messaging live
- ✅ "Multi-region data residency" positioned
- ✅ "Canadian data sovereignty" marketed
- ✅ Ready for ServiceNow Knowledge (May 2026)

---

## Week-by-Week Timeline

### Week 1-2: Foundation Phase (Feb 10-21)
**Theme:** Delta Independence + Enterprise Credibility  
**Effort:** 8-10 days

**Primary Focus:**
- Namespace Management UI (3-4 days)

**Parallel Work:**
- Website Update (2-3 hours)
- Privacy Policy Update (2-3 hours)
- OAuth Social Login (1-2 days)
- Multi-Region Architecture Prep (2-3 hours)
- Legal Entity Coordination (meetings)
- OAuth Verification Submission (1 hour)

**Deliverables:**
- Delta can manage namespaces without SQL
- Website professionally updated
- Privacy Policy OAuth-ready
- Google + Microsoft sign-in working
- Multi-region capable (deploy US/EU on-demand)

---

### Week 3: Integration Management (Feb 24-28)
**Theme:** FOIP Compliance + Data Governance  
**Effort:** 5-6 days

**Components:**
1. **Database Schema** (1 day)
   - internal_integrations table
   - external_integrations table
   - external_entities table
   - integration_contacts table
   - RLS policies

2. **Backend API** (1 day)
   - CRUD endpoints (internal/external)
   - External entities registry
   - Validation logic

3. **Frontend UI** (2-3 days)
   - Integrations tab on application detail
   - Internal integrations table
   - External integrations table
   - Add/edit modals
   - External entities registry page

4. **Visualization** (1 day)
   - Integration network diagram (D3.js)
   - Filter by sensitivity (FOIP-relevant data)

5. **Export** (0.5 day)
   - Data flow diagram (PDF)
   - Integration inventory (Excel)

**Deliverables:**
- Map all external data flows (FOIP compliance)
- Track integration contacts
- Visual network diagram
- Export for privacy assessments

**Strategic Value:**
- Government/FOIP appeal: "Where does citizen data go?"
- Privacy Officer positioning
- Lightweight ServiceNow DIM at QuickBooks price

---

### Week 4-5: IT Value Creation (Mar 3-14)
**Theme:** Strategic Planning + "So What?" Answer  
**Effort:** 6-8 days

**Components:**
1. **Database Schema** (1 day)
   - initiatives table
   - findings table
   - Junction tables (initiative_deployment_profiles, initiative_findings)
   - Views for reporting
   - RLS policies

2. **Backend API** (1 day)
   - Initiatives CRUD endpoints
   - Findings CRUD endpoints
   - Auto-generate findings from assessments

3. **Frontend UI** (3-4 days)
   - Initiatives list view (filterable)
   - Initiative detail/edit modal
   - Roadmap timeline view (Kanban board)
   - Value dashboard (charts)
   - Findings list view

4. **Export Functionality** (1 day)
   - Export to PDF (roadmap timeline)
   - Export to PowerPoint (optional)

5. **Testing & Documentation** (1 day)
   - Sample data creation
   - User documentation
   - Delta training

**Deliverables:**
- Board-ready strategic roadmap
- Initiatives linked to applications
- Timeline view shows sequencing
- Investment tracking by theme

**Strategic Value:**
- CIO appeal: "So what do I do with this data?"
- Only APM tool with strategic planning
- Differentiates from LeanIX/Flexera/ServiceNow

---

### Week 6-7: SSO OR Polish (Mar 17-31)
**Theme:** Enterprise Unlock OR Conference Prep  
**Effort:** 7-8 days (SSO) OR 3-4 days (Polish)

**Option A: Entra ID SSO** (7-8 days)
1. Research & Planning (0.5 day)
2. Azure AD Configuration (1 day)
3. Supabase SAML Configuration (1 day)
4. UI Integration (0.5 day)
5. Testing & Validation (1 day)
6. Documentation (0.5 day)

**Option B: Feature Polish** (3-4 days)
1. Integration Management polish (1 day)
2. IT Value Creation polish (1 day)
3. ServiceNow Knowledge prep (1 day)
4. Q1 review & Q2 planning (0.5 day)

**Decision Point:** Week 5 based on progress

**Deliverables:**
- Enterprise SSO operational OR
- Polished features + conference materials

---

## Strategic Feature Options

### Selected for Q1

#### **Integration Management** ⭐⭐⭐⭐⭐
- **Effort:** 5-6 days
- **Strategic Value:** FOIP/compliance, data lineage, government appeal
- **Competitive Impact:** Lightweight ServiceNow DIM at QuickBooks price
- **Customer Appeal:** Privacy Officer + Government markets
- **Build Risk:** Low (new tables only, no refactoring)
- **Q1 Status:** ✓ SELECTED - Week 3

#### **IT Value Creation** ⭐⭐⭐⭐⭐
- **Effort:** 6-8 days
- **Strategic Value:** Answers "So what?" - only APM with strategic planning
- **Competitive Impact:** Differentiates from all competitors
- **Customer Appeal:** CIO appeal - board-ready roadmaps
- **Build Risk:** Low (new tables only, no refactoring)
- **Q1 Status:** ✓ SELECTED - Week 4-5

---

### Deferred to Q2

#### **Composite Applications** ⭐⭐⭐
- **Effort:** 4-5 days
- **Strategic Value:** Catches up to competitors (not differentiation)
- **Competitive Impact:** LeanIX/ServiceNow have this already
- **Customer Appeal:** Enterprise - suite modeling
- **Build Risk:** 🔴 HIGH - Changes core DP model
- **Q2 Status:** DEFERRED - Architectural risk

**Why Deferred:**
1. **Architectural Impact:** Only feature that changes core model
2. **Suite children can't have DPs** - requires DP inheritance model
3. **Would require refactoring** all features built before it
4. **No customer demand** - no one asking for Sage 300 suite modeling yet
5. **Safer later** - build after 50+ apps, real suite examples

#### **Technology Lifecycle Intelligence** ⭐⭐⭐⭐⭐
- **Effort:** 5-6 days
- **Strategic Value:** AI-powered EOL replaces $50K/year tools
- **Customer Appeal:** CFO appeal - cost savings
- **Q2 Status:** DEFERRED - Time constraints

#### **Budget Management** ⭐⭐⭐⭐
- **Effort:** 4-5 days
- **Strategic Value:** CFO-ready tracking, variance analysis
- **Customer Appeal:** Executive stakeholder appeal
- **Q2 Status:** DEFERRED - Time constraints

#### **AI Chat (APM Q&A)** ⭐⭐⭐⭐
- **Effort:** 5-6 days
- **Strategic Value:** Natural language queries
- **Customer Appeal:** Modern, innovative positioning
- **Q2 Status:** DEFERRED - Not core priority

---

## Detailed Work Breakdown Structure

### 1.0 FOUNDATION PHASE (Week 1-2)

#### 1.1 Namespace Management UI (3-4 days) ⭐ PRIMARY FOCUS

**1.1.1 Database & Backend** (1.5 days)
- Create view: vw_namespace_summary (2 hours)
- Create view: vw_namespace_workspaces (1 hour)
- Create view: vw_namespace_users (1 hour)
- Backend API endpoints (4 hours)
- Validation logic (2 hours)

**1.1.2 Frontend UI** (1.5-2 days)
- Namespace List View (4 hours)
- Namespace Detail - Overview Tab (3 hours)
- Namespace Detail - Workspaces Tab (4 hours)
- Namespace Detail - Users Tab (4 hours)
- Change Tier Modal (3 hours)

**1.1.3 Testing & Training** (0.5-1 day)
- Test with real customer data (2 hours)
- Delta training session (1 hour)
- Documentation (2 hours)
- Bug fixes and polish (3 hours)

**Success Criteria:**
- Delta upgrades tier without SQL
- Delta adds workspace without Stuart
- Delta changes user roles
- Delta manages City of Garland workflow

---

#### 1.2 Website Update (2-3 hours) - PARALLEL

**1.2.1 Content Planning** (1 hour - Week 1)
- Homepage messaging
- Pricing page updates
- Security/Compliance page (NEW)
- Footer updates

**1.2.2 Implementation** (1-2 hours - Week 2)
- Deploy homepage updates (30 min)
- Deploy pricing page (30 min)
- Create Security page (30 min)
- Update footer/about (15 min)

**Success Criteria:**
- Professional appearance for prospects
- Multi-region messaging live
- Canadian data sovereignty highlighted

---

#### 1.3 Privacy Policy Update (2-3 hours) - PARALLEL

**1.3.1 Document Drafting** (1.5 hours - Mon-Tue Week 1)
- Critical fixes (domain, date, entity) (15 min)
- New section: Third-Party Authentication (30 min)
- New section: Canadian Data Residency (30 min)
- New section: Multi-Tenant Security (20 min)
- Update section: Infrastructure Providers (15 min)
- Update section: Cookies (OAuth-specific) (10 min)

**1.3.2 Review & Finalize** (0.5-1 hour - Wed-Thu Week 1)
- Stuart review (30 min)
- Edits and polish (20 min)
- Legal compliance check (10 min)

**1.3.3 Deployment** (15 minutes - Fri Week 1)
- Replace existing Privacy Policy page (10 min)
- Update "Last Updated" on all legal pages (5 min)

**Success Criteria:**
- Domain corrected (getinsync.ca)
- OAuth providers disclosed
- Canadian data residency highlighted
- Multi-tenant security explained
- Ready for OAuth verification submission

---

#### 1.4 OAuth Social Login (1-2 days) - PARALLEL

**1.4.1 Provider Registration** (2 hours - Thu-Fri Week 1)
- Google Cloud Console setup (30 min)
- Azure Portal setup (30 min)
- Supabase Configuration (15 min)
- Test in development (45 min)

**1.4.2 UI Implementation** (3-4 hours - Mon Week 2)
- Update login page (1 hour)
- Update registration page (1 hour)
- First-time OAuth user flow (1 hour)
- Account settings page (1 hour - optional, can defer)

**1.4.3 Production Deployment** (1 hour - Tue Week 2)
- Update production OAuth apps (15 min)
- Test in production (30 min)
- Monitor for issues (15 min)

**Success Criteria:**
- "Sign in with Google" working
- "Sign in with Microsoft" working
- New users can register via OAuth
- Improved signup conversion

---

#### 1.5 Multi-Region Architecture Prep (2-3 hours) - PARALLEL

**1.5.1 Database Schema** (1 hour - Tue Week 2)
- Add region column to namespaces (10 min)
- Update existing namespaces (5 min)
- Create region reference table (15 min)
- Document schema change (10 min)

**1.5.2 Environment Configuration** (1 hour - Wed Week 2)
- Set up environment variables structure (15 min)
- Create helper function (30 min)
- Update existing Supabase client (15 min)

**1.5.3 UI Preparation** (30 minutes - Thu Week 2)
- Region selector component stub (20 min)
- Documentation (10 min)

**1.5.4 Testing** (30 minutes - Thu Week 2)
- Verify Canada region still works (20 min)
- Document deployment process for US/EU (10 min)

**Success Criteria:**
- Region field exists on namespaces
- Environment structure supports multi-region
- Canada region continues to work
- Can deploy US/EU regions on-demand (2-3 hours each)

---

#### 1.6 Legal Entity Coordination - PARALLEL

**1.6.1 Initial Coordination** (Week 1)
- Email Joseph Gill (30 min)
- Document current state (30 min)
- Meeting with Joseph Gill if needed (1 hour)

**1.6.2 New Entity Details Collection** (Week 2)
- Get exact legal name
- Get registered address
- Get business numbers
- Document signing authority

**1.6.3 Transition Planning** (Ongoing)
- Create transition checklist (30 min)
- Plan customer communication (1 hour)
- Plan Update 2 execution (30 min)

---

#### 1.7 OAuth Verification Submission (1 hour) - End of Week 2

**1.7.1 Google OAuth Verification** (30 minutes - Fri Week 2)
- Submit app for verification (5 min)
- Provide required information (10 min)
- OAuth scope justification (15 min)

**1.7.2 Microsoft OAuth Verification** (30 minutes - Fri Week 2)
- Publisher verification (5 min)
- Domain verification (20 min)
- Submit verification request (5 min)

**1.7.3 Monitor & Respond** (Ongoing)
- Check verification status (5 min daily)
- Respond to any questions (as needed)

---

### 3.0 INTEGRATION MANAGEMENT (Week 3)

See section "Week 3: Integration Management" above for detailed breakdown.

**Key Tables:**
- internal_integrations
- external_integrations
- external_entities
- integration_contacts
- integration_contact_roles

**Technical Approach:**
- D3.js for network visualization
- Standard Supabase queries (simple joins)
- Progressive enhancement (build simple, add complexity later)

**No Full Context Diagram Yet:**
- Build integration network diagram (data flows only)
- Defer full context diagram to Q2 (when Composite Apps built)

---

### 4.0 IT VALUE CREATION (Week 4-5)

See section "Week 4-5: IT Value Creation" above for detailed breakdown.

**Key Tables:**
- initiatives
- findings
- initiative_deployment_profiles
- initiative_findings

**Key Features:**
- Strategic themes (Grow/Optimize/Risk)
- Time horizons (3/6/9/12/18+ months)
- Investment tracking (one-time + recurring)
- Auto-generated findings from assessments
- Roadmap timeline visualization (Kanban)

---

### 5.0 SSO OR POLISH (Week 6-7)

See section "Week 6-7: SSO OR Polish" above for detailed breakdown.

**Decision Criteria:**
- If on track after Week 5 → Pursue SSO (7-8 days)
- If behind or want polish → Feature refinement (3-4 days)

---

## Flexible/On-Demand Work Items

### City of Garland Import
- **Priority:** HIGH (but flexible timeline)
- **Owner:** Delta (mapping) + Stuart (execution)
- **Effort:** 2-3 days when executed
- **Dependencies:** Namespace Management UI complete
- **Status:** Delta mapping by Feb 14, import execution flexible
- **Trigger:** When Delta mapping complete AND capacity allows

### US Region Deployment
- **Trigger:** First US customer requiring US data residency
- **Effort:** 2-3 hours
- **Owner:** Stuart
- **Process:** Create Supabase us-east-1, run migrations, deploy frontend

### EU Region Deployment
- **Trigger:** First EU customer requiring GDPR residency
- **Effort:** 2-3 hours
- **Owner:** Stuart
- **Process:** Create Supabase eu-west-1, run migrations, deploy frontend

### Privacy Policy Update 2 (Entity Spinout)
- **Trigger:** Legal spinout completes
- **Effort:** 2-3 hours
- **Owner:** Stuart
- **Process:** Find-replace entity name, update addresses, update all legal docs

---

## Ongoing/Continuous Work Items

### OAuth Verification Monitoring
- **Ongoing:** Starting Week 2
- **Effort:** 5-10 minutes daily
- **Process:** Check status, respond to questions
- **Timeline:** Google (1-4 weeks), Microsoft (1-3 days)

### Legal Entity Coordination
- **Ongoing:** Throughout Q1
- **Effort:** Meetings as needed
- **Process:** Stay in touch with Joseph Gill, monitor progress

### Customer Support
- **Ongoing:** Daily
- **Effort:** Variable (budgeted in buffer)
- **Process:** Delta handles L1, Stuart handles L2/L3

### Delta Training & Enablement
- **Ongoing:** Weekly
- **Effort:** 1-2 hours/week
- **Process:** Friday demo sessions, documentation updates

---

## Risk Register

| Risk | Probability | Impact | Severity | Mitigation | Owner |
|------|-------------|--------|----------|------------|-------|
| SSO takes >7 days | Medium | High | 🟡 MEDIUM | Budget extra time, pivot to features if blocked | Stuart |
| Strategic features too ambitious | Medium | Medium | 🟡 MEDIUM | Pick 2 not 3, build MVPs, defer polish | Stuart |
| Customer emergency blocks dev time | Medium | Medium | 🟡 MEDIUM | 20-25 day estimate has 3-5 day buffer | Stuart |
| OAuth verification delayed | Low | Medium | 🟢 LOW | Can use unverified OAuth (works with warning) | Stuart |
| Legal spinout delayed | Low | Low | 🟢 LOW | Option B allows current entity, update later | Joseph Gill |
| D3.js network diagram complexity | Low | Medium | 🟢 LOW | AG has built complex viz before | AG |
| Integration queries performance | Low | Low | 🟢 LOW | Simple joins, limit to 50 nodes initially | Stuart |
| Composite Apps refactoring risk | None | High | 🟢 NONE | DEFERRED TO Q2 - no refactoring if done later | Stuart |

---

## Resource Allocation

### Stuart's Time Allocation

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 1-2 | Namespace UI (backend + testing) | 3-4 days | Primary |
| 1-2 | Privacy Policy, OAuth, Multi-region | 2-3 days | Parallel |
| 3 | Integration Management (schema + backend) | 3-4 days | Primary |
| 4-5 | IT Value Creation (schema + backend) | 4-5 days | Primary |
| 6-7 | SSO OR Feature Polish | 3-8 days | TBD |
| Ongoing | Legal coordination, customer support | 1-2 days | Secondary |

### AG (Antigravity) Usage

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 1-2 | Namespace UI (frontend) | 1.5-2 days | Primary |
| 1-2 | OAuth login UI | 0.5 days | Secondary |
| 3 | Integration Management UI + D3.js | 2-3 days | Primary |
| 4-5 | IT Value Creation UI (Kanban, dashboard) | 3-4 days | Primary |
| 6-7 | SSO UI OR Feature polish | 0.5-2 days | TBD |

### Delta's Time Allocation

| Week | Activity | Effort | Priority |
|------|----------|--------|----------|
| 1-2 | Website copywriting, Garland mapping | 2-3 days | Parallel |
| 2 | Namespace UI testing & training | 0.5 days | Secondary |
| 3 | Integration Management testing | 0.5 days | Secondary |
| 4-5 | IT Value Creation testing | 1 day | Secondary |
| Ongoing | Customer success, support | Continuous | Primary |

---

## Technical Architecture Decisions

### Integration Management vs Composite Applications

**Decision:** Build Integration Management FIRST, defer Composite Applications to Q2

**Rationale:**
1. **Orthogonal Concerns:**
   - Composites = Structural relationships (constitutes, depends_on)
   - Integrations = Data flow relationships (publishes to, subscribes from)
   - Can be built in either order

2. **Architectural Impact:**
   - Integration Management: New tables only (low risk)
   - Composite Applications: Changes DP model (high risk)

3. **Refactoring Risk:**
   - If Composites built AFTER features:
     - Suite children shouldn't have DPs
     - Need migration to delete child DPs
     - All DP queries need parent-child logic
     - IT Value Creation needs refactoring
   
   - If Composites built FIRST:
     - Suite model established Day 1
     - Features naturally handle parent-child
     - No migration needed

4. **Progressive Enhancement Strategy:**
   - Week 3: Build Integration Network Diagram (data flows only)
   - Q2: Build Full Context Diagram with all 3 layers:
     - Layer 1: IT Services (already exists)
     - Layer 2: Data integrations (from Week 3)
     - Layer 3: Application relationships (from Q2 Composite Apps)

**Conclusion:** No painting into corner. Progressive enhancement. No refactoring.

---

## D3.js Visualization Technical Validation

**Question:** Can AG build network diagrams with Supabase + React?

**Answer:** YES - Low risk

**Evidence:**
1. D3.js available via CDN in React artifacts
2. AG has built complex visualizations before
3. Network graphs are well-documented D3 pattern
4. Supabase queries are simple joins (not recursive)

**Approach:**
1. Build simple version first (50 nodes max)
2. Use force-directed graph layout
3. Color-code by entity type (app vs external)
4. Filter by sensitivity (FOIP-relevant data)
5. Add complexity progressively

**Performance:**
- Limit to 50 nodes initially
- Pagination if needed
- Server-side filtering

---

## Communication Plan

### Weekly Rhythm
- **Monday:** Week kickoff, priorities confirmation
- **Wednesday:** Mid-week check-in, blocker resolution
- **Friday:** Demo to Delta, training, week review

### Decision Points
- **Feb 21:** Review Week 1-2 progress, confirm SSO timeline
- **Feb 28:** Review Integration Management, confirm IT Value Creation scope
- **Mar 14:** Mid-features check-in, decide SSO vs Polish for Week 6-7
- **Mar 28:** Q1 review, Q2 planning kickoff

### Escalation
- **Blockers:** Flag immediately, don't wait for Friday
- **Scope creep:** Defer to Q2 unless critical
- **Customer urgency:** Evaluate against roadmap, adjust if revenue-critical

---

## Q2 2026 Preview

After Q1 foundation complete:

### Automation & Discovery
- Cloud Discovery (CSV → AWS → Azure/GCP)
- ServiceNow Publishing (CSDM export)
- Automated application discovery

### Deferred Features
- Composite Applications (when schema stable, real suite examples)
- Technology Lifecycle Intelligence (AI-powered EOL)
- Budget Management (CFO tracking)
- AI Chat (natural language APM queries)

### Scale & Growth
- SOC2 certification complete
- First enterprise deals closed (>$50K ARR)
- 10+ paying customers
- Hire first developer

---

## Appendices

### Key Documents
- Architecture Manifest v1.17
- RLS Policy Architecture v2.2
- Privacy Policy (updated Feb 7, 2026)
- Terms of Service (May 20, 2025)
- Namespace Management Operations Kit (8 documents)

### Credentials & Access
- Supabase: ca-central-1 project
- GitHub: sholtby/getinsync-nextgen-ag
- Production: nextgen.getinsync.ca
- Dev: dev--relaxed-kataifi-57d630.netlify.app

### Key Contacts
- Legal: Joseph A. Gill, McKercher LLP
- Customer Success: Delta Holtby
- Strategic Advisor: Dan Warfield (Managing Digital)
- Enterprise Sales Coaches: George Urquhart, Jayesh Parmar (Co.Labs)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-07 | Initial Q1 2026 Master Plan. Integration Management + IT Value Creation selected. Composite Applications deferred to Q2. Technical architecture validated. |

---

*Document: gis-q1-2026-master-plan-v1.0.md*  
*February 2026*
