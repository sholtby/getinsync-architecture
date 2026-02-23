---
name: getinsync-team-workflow
description: "GetInSync NextGen team workflow for Claude, Stuart, and Antigravity collaboration. Use this skill to understand roles, development process, handoffs, and documentation standards when working on GetInSync NextGen features."
version: 1.0
last_updated: 2026-02-03
---

# GetInSync NextGen Team Workflow

## Team Roles & Responsibilities

### Stuart (Product Owner / Architect)
- **Role:** Final decision maker, architecture owner, business logic expert
- **Responsibilities:**
  - Refines data architecture with Claude
  - Makes final calls on schema design
  - Tests implementations locally and in dev
  - Pushes to production (GitHub merge)
  - Maintains architecture documentation
  - Owns product vision and roadmap

### Claude Sonnet 4.5 (Architecture & Integration Lead)
- **Role:** Schema designer, architecture consultant, AG prompt engineer
- **Responsibilities:**
  - Designs Supabase schema (tables, columns, relationships, RLS)
  - Collaborates with Stuart to refine data architecture
  - Prepares prompts for Antigravity (AG)
  - Reviews AG implementation plans
  - Documents architecture changes
  - Maintains changelog versioning

### Antigravity (AG) (Code Implementation)
- **Role:** Frontend developer (React/TypeScript/Vite)
- **Responsibilities:**
  - Implements UI components based on prompts
  - Creates implementation plans for complex features
  - Writes React/TypeScript code
  - Follows AG-specific best practices
  - **CONSTRAINT:** No Supabase access (schema provided by Claude/Stuart)

---

## Standard Development Workflow

### Phase 1: Schema Design & Architecture (Claude + Stuart)

**1. Requirements Gathering**
- Stuart describes feature requirements
- Claude asks clarifying questions
- Identify data entities, relationships, constraints

**2. Schema Design (Claude)**
- Claude proposes Supabase schema:
  - Table definitions (columns, types, constraints)
  - Foreign key relationships
  - RLS (Row Level Security) policies
  - Indexes for performance
  - Triggers/functions if needed
- Format: SQL migration script

**3. Architecture Refinement (Stuart + Claude)**
- Stuart reviews schema proposal
- Iterative refinement:
  - "Add this field"
  - "Change relationship from 1:N to N:M"
  - "Split this table into two"
  - "Add this constraint"
- Multiple rounds until Stuart approves

**4. Schema Implementation (Stuart)**
- Stuart applies schema to Supabase:
  - Manual SQL execution in Supabase dashboard
  - OR migration script execution
- Confirms schema is live in dev environment

### Phase 2: AG Prompt Preparation (Claude + Stuart)

**1. Claude Prepares AG Prompt**
- **Prompt Structure:**
  ```
  # Feature: [Name]
  
  ## Context
  [Brief description of what we're building]
  
  ## Schema
  [Relevant table definitions - what AG needs to know]
  
  ## Requirements
  1. [Specific UI requirement]
  2. [Specific behavior requirement]
  3. [Integration points]
  
  ## Technical Notes
  - [Any AG-specific constraints]
  - [Styling guidelines]
  - [Performance considerations]
  
  ## Request Implementation Plan (if complex)
  [Only include this line if feature is complex]
  ```

**2. Stuart Reviews Prompt**
- Checks for completeness
- Adds business logic details
- Confirms scope is clear

**3. Complexity Check**
- **Simple features:** AG can implement directly (no plan needed)
- **Complex features:** Claude explicitly requests implementation plan
  - Add to prompt: "Please provide an implementation plan before coding"
  - AG will create step-by-step plan
  - Stuart/Claude review plan before AG proceeds

### Phase 3: AG Implementation

**1. AG Receives Prompt**
- AG reads requirements
- (If requested) Creates implementation plan
- Begins coding

**2. Implementation Plan Review (Complex Features Only)**
- AG provides plan with:
  - Components to create/modify
  - File structure
  - Integration approach
  - Testing strategy
- Stuart/Claude review and approve
- If changes needed, iterate on plan before coding

**3. AG Codes**
- Creates React components
- Implements TypeScript types
- Integrates with Supabase (using schema provided)
- Follows AG best practices

**4. AG Delivers**
- Code is committed to localhost:5173
- Stuart tests locally

### Phase 4: Test & Iterate (Stuart + Claude + AG)

**1. Local Testing (Stuart)**
- Environment: `localhost:5173`
- Browser: Chrome on MacBook Pro
- Tests:
  - UI functionality
  - Data flow (form → Supabase → display)
  - Edge cases
  - Tier limit enforcement
  - RLS policy validation

**2. Bug Fixes / Iterations**
- Stuart identifies issues
- Claude/Stuart determine if:
  - **Schema fix needed:** Claude updates schema, Stuart applies
  - **Code fix needed:** Stuart feeds back to AG
  - **Logic fix needed:** Claude/Stuart refine requirements, AG updates
- Iterate until feature works

**3. Dev Environment Push**
- Stuart commits to GitHub
- Auto-deploys to dev: `https://dev--relaxed-kataifi-57d630.netlify.app`
- Test in dev environment (multi-browser, real data)

**4. Production Merge**
- Stuart merges to main branch
- Auto-deploys to production: `nextgen.getinsync.ca`
- Monitor for issues

---

## Key Constraints & Tools

### Technical Environment
- **Frontend:** React + TypeScript + Vite + Tailwind
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Local Dev:** `localhost:5173`
- **Dev URL:** `https://dev--relaxed-kataifi-57d630.netlify.app`
- **Production URL:** `nextgen.getinsync.ca`
- **Repo:** `sholtby/getinsync-nextgen-ag`

### Stuart's Setup
- **Device:** MacBook Pro
- **Browser:** Chrome (primary testing)
- **Editor:** (AG handles code, Stuart reviews)
- **Access:** Supabase dashboard (direct SQL execution)

### AG Constraints
- **NO Supabase access:** Schema must be provided in prompt
- **NO database migrations:** Claude/Stuart handle schema
- **Frontend only:** React components, TypeScript types, UI logic

### Documentation Standards
- **Session Notes:** Export at end of each session for continuity
- **Architecture Changes:** Update `archive/superseded/architecture-changelog-v1_7.md`
- **Versioning:** Increment changelog version on major changes
- **Project Files:** Keep architecture docs in `/mnt/project/`

---

## Workflow Decision Trees

### "Should AG Create an Implementation Plan?"

```
Is the feature complex?
├─ Yes (>3 components, >5 integration points, new patterns)
│  └─ Claude requests plan in AG prompt
│     └─ AG creates plan → Review → Approve → Code
├─ No (simple CRUD, single component, existing pattern)
│  └─ AG codes directly (no plan needed)
└─ Unsure?
   └─ Claude asks Stuart: "Should we request implementation plan?"
```

### "Who Fixes This Bug?"

```
Bug identified in testing
├─ Schema issue (wrong column type, missing FK, RLS failure)
│  └─ Claude proposes fix → Stuart applies SQL
├─ Code issue (UI broken, TypeScript error, integration bug)
│  └─ Stuart describes to AG → AG fixes
├─ Logic issue (wrong calculation, incorrect flow)
│  └─ Claude/Stuart refine requirements → AG updates
└─ Configuration issue (env vars, deployment)
   └─ Stuart fixes directly
```

### "When to Update Architecture Changelog?"

```
Did we change:
├─ Core data model (new tables, renamed columns, new relationships)?
│  └─ YES → Update changelog, increment version
├─ RLS policies significantly?
│  └─ YES → Update changelog
├─ Added new architectural pattern?
│  └─ YES → Update changelog
├─ Just UI tweaks or bug fixes?
│  └─ NO → No changelog update needed
└─ Unsure?
   └─ Ask Stuart: "Should this be in changelog?"
```

---

## AG Prompt Best Practices

### ✅ DO Include in AG Prompts:
- Clear feature description (1-2 sentences)
- Relevant schema (tables AG will interact with)
- Specific UI requirements (layout, behavior, validation)
- Example data (if helpful for context)
- Request for implementation plan (if complex)

### ❌ DON'T Include in AG Prompts:
- Full database schema dump (only relevant tables)
- Supabase connection details (AG can't access anyway)
- Backend logic (AG is frontend only)
- Deployment instructions (Stuart handles)

### Example: Good AG Prompt

```markdown
# Feature: Budget Alert Configuration

## Context
Users need to set budget thresholds and receive alerts when spending approaches limits.

## Schema
CREATE TABLE budget_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id),
  threshold_percentage INTEGER CHECK (threshold_percentage BETWEEN 50 AND 100),
  alert_type TEXT CHECK (alert_type IN ('email', 'dashboard', 'both')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

## Requirements
1. Settings page: Workspace Settings → Budget Alerts
2. Form fields:
   - Threshold slider (50-100%, default 80%)
   - Alert type dropdown (Email / Dashboard / Both)
   - Enable/disable toggle
3. Save button → insert to budget_alerts table
4. Show current settings if already configured

## Technical Notes
- Use existing Settings page layout pattern
- Tailwind styling to match workspace settings
- Form validation: threshold required if enabled
- Success toast on save

Please provide an implementation plan before coding.
```

---

## Session Continuity

### At End of Session (Claude)
1. **Export Session Summary:**
   - What was built
   - What was decided
   - Next steps
   - Open questions
2. **Update Architecture Changelog (if needed):**
   - Document schema changes
   - Increment version
3. **Commit Documentation:**
   - Session notes to project files
   - Updated changelogs

### At Start of New Session (Claude)
1. **Read Context:**
   - Check latest architecture changelog
   - Review project files for recent changes
   - Read previous session notes (if available)
2. **Confirm Understanding:**
   - "Based on v1_7 changelog, we're working on [X]"
   - "Last session we completed [Y], correct?"
3. **Proceed:**
   - Continue from where previous session left off

---

## Common Patterns

### Pattern: New Feature from Scratch
1. Stuart describes feature
2. Claude designs schema
3. Stuart reviews → iterate → approve
4. Stuart applies schema to Supabase
5. Claude prepares AG prompt
6. Stuart reviews prompt → approve
7. Stuart sends to AG (in new AG chat)
8. AG implements
9. Stuart tests locally
10. Fix bugs, iterate
11. Push to dev → test
12. Merge to production
13. Update changelog

### Pattern: Schema Migration
1. Stuart identifies need for schema change
2. Claude proposes migration SQL
3. Stuart reviews → approve
4. Stuart runs migration in Supabase
5. Claude updates affected AG prompts (if needed)
6. Test to confirm migration succeeded
7. Update architecture changelog (version bump)

### Pattern: Bug Fix
1. Stuart reports bug
2. Claude diagnoses (schema vs code vs logic)
3. If schema: Claude fixes → Stuart applies
4. If code: Stuart describes to AG → AG fixes
5. Test fix
6. Deploy

---

## Example Workflow: Phase 21 (IT Value Creation)

### Week 1: Schema Design
**Claude:**
- Designs tables: `strategic_initiatives`, `findings`, `strategic_themes`
- Proposes relationships, RLS policies
- Iterates with Stuart on data model

**Stuart:**
- Reviews schema proposals
- Suggests refinements ("Add priority field", "Change enum values")
- Approves final schema

**Stuart:**
- Applies schema to Supabase dev environment
- Confirms tables created successfully

### Week 2: UI Implementation
**Claude + Stuart:**
- Prepare AG prompt for "Strategic Initiatives List View"
- Include schema, requirements, mock data
- Request implementation plan (complex feature)

**AG:**
- Creates implementation plan
- Stuart/Claude review → approve
- AG implements React components

**Stuart:**
- Tests on localhost:5173
- Finds bugs ("Delete button doesn't work")
- Reports to AG → AG fixes

**Stuart:**
- Push to dev environment
- Test with real data
- Merge to production

**Claude:**
- Updates `archive/superseded/architecture-changelog-v1_7.md`
- Version bump to v1_8
- Documents new tables, relationships

---

## Critical Rules

### Rule 1: AG Never Touches Supabase
- ❌ AG cannot run migrations
- ❌ AG cannot view database
- ❌ AG cannot test RLS policies
- ✅ AG receives schema in prompt
- ✅ AG writes TypeScript types based on schema
- ✅ AG uses Supabase client (assumes schema exists)

### Rule 2: Schema is Source of Truth
- Claude designs schema
- Stuart approves schema
- Stuart applies schema to Supabase
- AG codes against schema
- If schema changes, update AG prompts

### Rule 3: Test Locally Before Dev
- Never push untested code to dev
- Always test on localhost:5173 first
- Use Chrome for primary testing
- Verify RLS policies work correctly

### Rule 4: Document Architecture Changes
- Any table/column/relationship change → changelog
- Version bump on significant changes
- Session notes for continuity
- Architecture docs live in project files

### Rule 5: Incremental Iterations
- Build one feature at a time
- Test thoroughly before moving to next
- Don't stack features (finish, test, deploy, then next)
- Iterate on bugs immediately

---

## Quick Reference

### When Claude Should:
- **Design schema:** New feature needs database tables
- **Update changelog:** Schema/architecture changed
- **Prepare AG prompt:** Ready to implement UI
- **Review AG plan:** Complex feature implementation
- **Export session notes:** End of session

### When Stuart Should:
- **Apply schema:** Claude's SQL ready for Supabase
- **Test locally:** AG delivered code
- **Push to dev:** Local tests passing
- **Merge to prod:** Dev tests passing
- **Make final calls:** Architecture decisions

### When AG Should:
- **Create plan:** Complex feature (if requested)
- **Implement UI:** Prompt received, plan approved
- **Fix bugs:** Stuart reports code issues
- **Iterate:** Stuart requests changes

---

## Handoff to New Claude Session

When starting a new chat with Claude, Stuart should say:

> "We're working on GetInSync NextGen. Read the getinsync-team-workflow skill to understand our process. Current phase: [X]. Latest changelog: archive/superseded/architecture-changelog-v1_7.md. Last session we [Y]."

Claude will then:
1. Read the workflow skill (this document)
2. Check architecture changelog for context
3. Review project files for current state
4. Confirm understanding before proceeding

---

**End of Skill: getinsync-team-workflow v1.0**

