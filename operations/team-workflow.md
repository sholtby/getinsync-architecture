---
name: getinsync-team-workflow
description: "GetInSync NextGen team workflow for Stuart and Claude Code collaboration. Use this skill to understand roles, development process, handoffs, and documentation standards when working on GetInSync NextGen features."
version: 2.0
last_updated: 2026-02-23
---

# GetInSync NextGen Team Workflow

## Team Roles & Responsibilities

### Stuart (Product Owner / Architect)
- **Role:** Final decision maker, architecture owner, business logic expert
- **Responsibilities:**
  - Refines data architecture with Claude Code
  - Makes final calls on schema design
  - Applies schema changes via Supabase SQL Editor (Claude Code does NOT modify schema)
  - Tests implementations locally and in dev
  - Pushes to production (GitHub merge)
  - Maintains architecture documentation
  - Owns product vision and roadmap

### Claude Code (Architecture + Implementation)
- **Role:** Schema designer, architecture consultant, frontend developer
- **Responsibilities:**
  - Designs Supabase schema (tables, columns, relationships, RLS)
  - Implements React/TypeScript/Tailwind frontend code
  - Has read-only database access for schema introspection
  - Reads architecture docs from `./docs-architecture/` (symlinked repo)
  - Follows rules in `CLAUDE.md` at repo root
  - Documents architecture changes
  - Runs type checks (`npx tsc --noEmit`) and builds (`npm run build`)
  - Commits to both code repo and architecture repo when applicable

> **Note:** Prior to Feb 17, 2026, UI implementation was done via Antigravity (bolt.new). Claude Code replaced AG as the primary development tool. AG remains available as a fallback.

---

## Standard Development Workflow

### Phase 1: Schema Design & Architecture (Claude Code + Stuart)

**1. Requirements Gathering**
- Stuart describes feature requirements
- Claude Code reads relevant architecture doc from `./docs-architecture/features/`
- Claude Code asks clarifying questions
- Identify data entities, relationships, constraints

**2. Schema Design (Claude Code)**
- Claude Code proposes Supabase schema:
  - Table definitions (columns, types, constraints)
  - Foreign key relationships
  - RLS (Row Level Security) policies
  - Indexes for performance
  - Triggers/functions if needed
- Format: SQL script (Stuart applies via Supabase SQL Editor)

**3. Architecture Refinement (Stuart + Claude Code)**
- Stuart reviews schema proposal
- Iterative refinement until Stuart approves
- Claude Code can verify existing schema via read-only database connection

**4. Schema Implementation (Stuart)**
- Stuart applies schema to Supabase via SQL Editor
- Claude Code does NOT modify database schema
- Stuart confirms schema is live

### Phase 2: Frontend Implementation (Claude Code)

**1. Claude Code Implements Directly**
- Reads the codebase and existing patterns
- Creates/modifies React components, TypeScript types, hooks
- Integrates with Supabase client using actual view/table definitions
- Verifies view columns via database introspection before writing TypeScript interfaces
- Follows all rules in `CLAUDE.md` (no hardcoded dropdowns, no `alert()`, etc.)

**2. Impact Analysis (Before Every Change)**
- Before modifying a view, type, interface, or shared component: grep for all consumers
- Update ALL files that reference the changed entity
- This is the cardinal rule — silent bugs come from partial updates

**3. Validation**
- Run `npx tsc --noEmit` — must pass with zero errors
- Run `npm run build` if in doubt
- No TODO/FIXME left behind

### Phase 3: Test & Iterate (Stuart + Claude Code)

**1. Local Testing (Stuart)**
- Environment: `localhost:5173`
- Tests:
  - UI functionality
  - Data flow (form → Supabase → display)
  - Edge cases
  - Tier limit enforcement
  - RLS policy validation

**2. Bug Fixes / Iterations**
- Stuart identifies issues
- Claude Code diagnoses and determines if:
  - **Schema fix needed:** Claude Code proposes SQL → Stuart applies
  - **Code fix needed:** Claude Code fixes directly
  - **Logic fix needed:** Claude Code + Stuart refine requirements → Claude Code updates

**3. Deploy**
- Stuart commits to `dev` branch
- Auto-deploys to dev Netlify site
- Test in dev environment
- Merge `dev` → `main` for production deploy to `nextgen.getinsync.ca`

---

## Key Constraints & Tools

### Technical Environment
- **Frontend:** React + TypeScript + Vite + Tailwind
- **Backend:** Supabase (PostgreSQL 17.6 + Auth + Storage)
- **Region:** ca-central-1 (Montreal)
- **Local Dev:** `localhost:5173`
- **Production URL:** `nextgen.getinsync.ca`
- **Code Repo:** `sholtby/getinsync-nextgen-ag`
- **Architecture Repo:** `sholtby/getinsync-architecture` (symlinked as `./docs-architecture/`)

### Claude Code Capabilities
- ✅ Read/write frontend code (React, TypeScript, Tailwind)
- ✅ Read-only database access (schema introspection, view definitions)
- ✅ Read architecture docs from `./docs-architecture/`
- ✅ Run type checks and builds
- ✅ Commit to both repos (code + architecture)
- ❌ NO database schema modifications (Stuart handles via Supabase SQL Editor)
- ❌ NO `sudo` for npm installs
- ❌ NO hardcoded dropdown values (always fetch from reference tables)
- ❌ NO `alert()` or `confirm()` (use toast/modal components)

### Documentation Standards
- **Architecture docs:** Maintained in `~/getinsync-architecture/` repo
- **Document index:** `./docs-architecture/MANIFEST.md`
- **Schema reference:** `./docs-architecture/schema/nextgen-schema-current.sql`
- **Session summaries:** `./docs-architecture/sessions/`
- **Status tags:** 🟢 AS-BUILT | 🟡 AS-DESIGNED | 🟠 NEEDS UPDATE | ☪ REFERENCE

---

## Workflow Decision Trees

### "Who Fixes This Bug?"

```
Bug identified in testing
├── Schema issue (wrong column type, missing FK, RLS failure)
│   └── Claude Code proposes fix → Stuart applies SQL
├── Code issue (UI broken, TypeScript error, integration bug)
│   └── Claude Code fixes directly in the codebase
├── Logic issue (wrong calculation, incorrect flow)
│   └── Claude Code + Stuart refine requirements → Claude Code updates
└── Configuration issue (env vars, deployment)
    └── Stuart fixes directly
```

### "When to Update Architecture Docs?"

```
Did we change:
├── Core data model (new tables, renamed columns, new relationships)?
│   └── YES → Update relevant doc in docs-architecture/, update MANIFEST
├── RLS policies significantly?
│   └── YES → Update rls-policy.md or addendum
├── Added new architectural pattern?
│   └── YES → Create or update feature doc
├── Just UI tweaks or bug fixes?
│   └── NO → No doc update needed
└── Unsure?
    └── Ask Stuart
```

---

## Dual-Repo Commit Process

When Claude Code modifies files in `./docs-architecture/`, those changes write to the architecture repo. Both repos must be committed:

```bash
# 1. Commit code repo
cd ~/Dev/getinsync-nextgen-ag
git add <changed files>
git commit -m "feat: description"
git push

# 2. Commit architecture repo (if docs changed)
cd ~/getinsync-architecture
git add <changed files>
git commit -m "docs: description"
git push
cd ~/Dev/getinsync-nextgen-ag
```

---

## Session Continuity

### At Start of Session (Claude Code)
1. Reads `CLAUDE.md` at repo root (automatic)
2. Reads relevant architecture docs from `./docs-architecture/` as needed
3. Checks latest session summary if continuing previous work

### At End of Session
1. Run type check (`npx tsc --noEmit`)
2. Commit all code changes to code repo
3. Commit any architecture doc changes to architecture repo
4. Create session summary in `./docs-architecture/sessions/` if significant work done
5. Stuart runs session-end checklist from `./docs-architecture/operations/session-end-checklist.md`

---

## Common Patterns

### Pattern: New Feature from Scratch
1. Stuart describes feature
2. Claude Code reads relevant architecture doc
3. Claude Code designs schema
4. Stuart reviews → iterate → approve
5. Stuart applies schema to Supabase
6. Claude Code implements React frontend
7. Stuart tests locally on `localhost:5173`
8. Fix bugs, iterate
9. Push to dev → test → merge to production
10. Update architecture docs if needed

### Pattern: Schema Migration
1. Stuart identifies need for schema change
2. Claude Code proposes migration SQL (verifying current schema via DB connection)
3. Stuart reviews → approve
4. Stuart runs migration in Supabase SQL Editor
5. Claude Code updates TypeScript interfaces to match new schema
6. Test to confirm migration succeeded
7. Update architecture docs

### Pattern: Bug Fix
1. Stuart reports bug
2. Claude Code diagnoses (schema vs code vs logic)
3. If schema: Claude Code proposes fix → Stuart applies
4. If code: Claude Code fixes directly
5. Test fix
6. Deploy

---

## Critical Rules

### Rule 1: Claude Code Never Modifies Database Schema
- ❌ Claude Code cannot run CREATE, ALTER, DROP, INSERT, UPDATE, DELETE
- ✅ Claude Code can SELECT for schema introspection
- ✅ Claude Code proposes SQL for Stuart to apply
- ✅ Claude Code writes TypeScript types based on verified schema

### Rule 2: View-to-TypeScript Contract
- The database view is the source of truth
- TypeScript interfaces MUST exactly match view column names and types
- Before modifying any TypeScript that queries a view, check the actual view definition first
- Grep for all consumers before changing any shared type or interface

### Rule 3: Test Locally Before Dev
- Never push untested code to dev
- Always test on `localhost:5173` first
- Verify data flow end-to-end

### Rule 4: Document Architecture Changes
- Any table/column/relationship change → update relevant architecture doc
- Commit to architecture repo
- Update MANIFEST.md if new documents added

### Rule 5: Incremental Iterations
- Build one feature at a time
- Test thoroughly before moving to next
- Don't stack features (finish, test, deploy, then next)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-03 | Initial workflow: Stuart + Claude (Sonnet) + Antigravity (AG) three-role model |
| v2.0 | 2026-02-23 | **Major rewrite:** AG replaced by Claude Code (Feb 17). Collapsed to two-role model (Stuart + Claude Code). Removed AG prompt preparation workflow. Added dual-repo commit process, database introspection, impact analysis rules. Updated all tool references and documentation paths. |

---

*Document: operations/team-workflow.md*
*February 2026*
