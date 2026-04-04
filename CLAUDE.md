# CLAUDE.md — GetInSync NextGen Development Rules 3 Mar 2026

> This file is read by Claude Code at the start of every session.
> It defines rules you MUST follow while writing code.
> When Stuart says **"run session-end checklist"**, read and execute `./docs-architecture/operations/session-end-checklist.md`.

---

## Project Overview

GetInSync NextGen is an Application Portfolio Management (APM) SaaS platform.
- **Vision:** "QuickBooks for CSDM" — hide complexity, user answers plain English questions
- **Stack:** React + TypeScript + Vite + Tailwind, Supabase (PostgreSQL, ca-central-1)
- **Auth:** Supabase Auth (email/password + OAuth)
- **Repo:** ~/Dev/getinsync-nextgen-ag
- **Production:** https://nextgen.getinsync.ca (Netlify)
- **Dev server:** http://localhost:5173

---

## Architecture Documentation

Architecture docs live in a separate repo, symlinked into this project:
- **Symlink:** `./docs-architecture/` -> `~/getinsync-architecture/`
- **Document index:** `./docs-architecture/MANIFEST.md`
- **Schema reference:** `./docs-architecture/schema/nextgen-schema-current.sql`
- **Feature specs:** `./docs-architecture/features/` (e.g., `roadmap/architecture.md`)
- **ERDs and data model:** `./docs-architecture/core/`
- **RLS and security:** `./docs-architecture/identity-security/`

**Before building any feature, read the relevant architecture doc from `./docs-architecture/`.**
Do not rely on memory — always verify against the actual docs.

### Architecture Docs Are Living Specs — UPDATE AFTER EVERY BUILD

Architecture documents must stay current with what is deployed. After completing any feature work that changes behavior described in `./docs-architecture/`:

1. **Find the relevant doc** using the Feature-to-Doc Map below
2. **Update it** to match what you just built (stats, UI behavior, schema references, status flags)
3. **Update `./docs-architecture/MANIFEST.md`** — bump version, add changelog entry
4. **Commit both repos** (see Dual-Repo Commits)

If you built something that has NO architecture doc, tell Stuart: "This feature needs a doc in docs-architecture/."

**This is not optional.** Shipping code without updating the corresponding architecture doc creates SOC2 audit risk.

---

## Dual-Repo Commits

This project spans two git repos. When you modify files in `./docs-architecture/`, those changes write to `~/getinsync-architecture/` (a separate repo).

**Code repo:** commits go to your current feature branch.
**Architecture repo:** commits always go to `main` (no feature branches needed for docs).

**When you modify files in ./docs-architecture/:**
1. Commit and push the code repo on your feature branch:
   ```bash
   cd ~/Dev/getinsync-nextgen-ag
   git add -A
   git commit -m "description of code changes"
   git push -u origin $(git branch --show-current)
   ```
2. Also commit and push the architecture repo (always on main):
   ```bash
   cd ~/getinsync-architecture
   git add -A
   git commit -m "description of doc changes"
   git push origin main
   cd ~/Dev/getinsync-nextgen-ag
   ```

**Always commit to both repos before ending a session.**

---

## Architecture Rules — ALWAYS FOLLOW

### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly.
- **Budget data lives in workspace_budgets table**, NOT workspaces.budget_amount (that column is legacy — do not read or write to it).
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.

### Dropdowns and Reference Tables
- **ALL dropdowns MUST fetch from database reference tables.** Never hardcode arrays in React.
- If a dropdown does not have a reference table yet, stop and tell Stuart "we need a reference table for this."
- Filter by `is_active = true`, order by `display_order`.
- Reference table pattern: id (uuid), code (text unique), name (text), description (text), display_order (int), is_active (bool), is_system (bool), created_at (timestamptz).

### Existing Reference Tables

| Table | Purpose |
|-------|---------|
| criticality_types | Integration criticality levels |
| integration_direction_types | upstream/downstream/bidirectional |
| integration_method_types | api/file/database/sso/manual/event/other |
| integration_frequency_types | real_time/batch_daily/weekly/monthly/on_demand |
| integration_status_types | planned/active/deprecated/retired |
| data_format_types | json/xml/csv/xlsx/etc |
| sensitivity_types | low/moderate/high/confidential |
| data_classification_types | public/internal/confidential/restricted |
| data_tag_types | Employee/Citizen/Customer/Financial/etc |
| hosting_types | SaaS/On-Prem/Cloud/Hybrid/etc |
| cloud_providers | AWS/Azure/GCP/etc |
| dr_statuses | Disaster recovery statuses |
| lifecycle_statuses | Application lifecycle stages |
| environments | PROD/DEV/TEST/etc |
| remediation_efforts | XS/S/M/L/XL/2XL t-shirt sizes |
| service_types | IT Service categories |

### Database Conventions
- Tiers: `trial` / `essentials` / `plus` / `enterprise` (NEVER free/pro/full)
- Namespace roles: `admin` / `editor` / `steward` / `viewer` / `restricted`
- Contact categories: `internal` / `external` / `vendor_rep`
- All new tables need: `GRANT ALL TO authenticated, service_role` + RLS enabled + audit trigger
- All new views: `security_invoker = true`
- New DEFINER functions: `SET search_path = 'public'`
- Supabase queries use snake_case (matching PostgreSQL columns exactly)

### Grid and Table Standards
- **ALL data tables/grids MUST include pagination:** Bottom bar showing "Showing X-Y of Z [items]" with page size selector (10/25/50/100/All). Default 10 rows. No separate count line at the top — one count display, one location (bottom).
- **ALL dropdown options with non-obvious meaning MUST have tooltips** explaining what each option does.
- Reuse `src/components/shared/TablePagination.tsx` — do not create new pagination implementations.

---

## Bulletproof React — Code Quality Direction

These are principles for NEW code written this session. They are NOT a mandate to refactor existing code. If existing code violates these patterns, leave it alone unless Stuart specifically asks for a refactoring session.

**The priority is always: ship the feature first, clean code second.**

### For new code you write this session:
- Prefer custom hooks over inline `supabase.from()` calls in components
- Prefer `unknown` over `any` for new type declarations
- Prefer feature-folder organization for new pages/features
- Keep new components under 300 lines when practical
- Add error boundaries around new feature sections
- Use try/catch with toast notifications for all Supabase calls
- Show loading states during fetches, disable buttons during mutations

### What NOT to do with these rules:
- Do NOT refactor existing files to match these patterns unless asked
- Do NOT split a working component just because it is over 300 lines
- Do NOT create abstraction layers (barrel exports, context providers) before they are needed — wait until there is actual duplication
- Do NOT block feature work to fix existing `any` types or non-null assertions

---

## Impact Analysis — BEFORE EVERY CHANGE

### The Cardinal Rule
**Before changing ANY view, table, type, interface, or shared component, you MUST check what else uses it.**

### Required Steps
1. **Before modifying a database view's columns or query:**
   ```bash
   grep -r "view_name" src/ --include="*.ts" --include="*.tsx"
   ```
   Update ALL files that query this view.
2. **Before modifying a TypeScript type or interface:**
   ```bash
   grep -r "InterfaceName" src/ --include="*.ts" --include="*.tsx"
   ```
   Update ALL files that import or use this type.
3. **Before modifying a shared component:**
   ```bash
   grep -r "ComponentName" src/ --include="*.tsx"
   ```
   Verify all parent components still pass correct props.
4. **Before modifying a utility/hook:**
   ```bash
   grep -r "hookName\|utilityName" src/ --include="*.ts" --include="*.tsx"
   ```
   Verify all consumers still work.

### Why This Matters
The budget page broke because `vw_workspace_budget_summary` was changed to read from `workspace_budgets` but the TypeScript interface still expected the old column names. The view returned data but every field read as `undefined`. This class of bug is silent — no compile error, no runtime error, just wrong data.

---

## Before Completing Any Task — CHECKLIST

1. **Type check:** Run `npx tsc --noEmit` — must pass with zero errors
2. **Impact scan:** If you changed a view, type, interface, or component — did you grep and update all consumers?
3. **No hardcoded dropdowns:** Any new `<select>` or `<option>` must fetch from a reference table
4. **No browser alerts:** Use toast notifications, not `alert()`
5. **No TODO/FIXME left behind:** Search for any you introduced
6. **Test the build:** If in doubt, run `npm run build` to verify production build works
7. **Architecture doc updated:** If you changed behavior described in `./docs-architecture/`, did you update the doc? (see Living Specs rule)

---

## Git Workflow

### Branch Strategy

Each Claude Code window works on its own **feature branch**, branched from `dev`. Multiple windows can run simultaneously on separate branches.

- **Branch naming:** `feat/<description>`, `fix/<description>`, `refactor/<description>`, `chore/<description>`, `docs/<description>`
- **Base branch:** Always branch from `dev` (not `main`)
- **Commit messages:** Use prefixes: `feat:` / `fix:` / `refactor:` / `chore:` / `docs:`
- **Push after commits:** Always push to origin with `-u` on first push
- **Deploy flow:** feature-branch -> dev -> main -> Netlify auto-deploys from main
- **Dual-repo:** If you modified `./docs-architecture/`, commit and push that repo too (see Dual-Repo Commits above)

### Starting Work

At the start of every session, before writing any code:
1. Run: `git status` (confirm which branch you're on)
2. If on `dev`: ask Stuart "What are we building? I'll create a feature branch before we start."
3. If already on a feature branch: confirm with Stuart "I'm on `feat/xxx` — continuing this work?"
4. Never start writing code while on the `dev` branch.

```bash
# At the start of a session, create a feature branch from dev
cd ~/Dev/getinsync-nextgen-ag
git checkout dev
git pull origin dev
git checkout -b feat/my-feature-name
```

### Finishing Work (feature complete)

```bash
# Merge your feature branch into dev when work is complete
cd ~/Dev/getinsync-nextgen-ag
git checkout dev
git pull origin dev
git merge feat/my-feature-name
git push origin dev
git branch -d feat/my-feature-name
```

### Finishing Work (feature in progress)

```bash
# Push your feature branch and note the branch name in the session handover
git push -u origin $(git branch --show-current)
```

### Parallel Sessions — Git Worktrees

When running parallel sessions on different branches, use `git worktree` to create separate working directories. Never run `git checkout` to switch branches if other sessions may be active. Each session should operate in its own worktree. Worktrees do not affect Netlify remote deployments.

- Stuart assigns features to sessions that do not conflict (non-overlapping files)
- If you discover you need to modify a file another session likely owns, **stop and tell Stuart**
- Before merging to `dev`, always `git pull origin dev` first and resolve any conflicts
- The architecture repo (`~/getinsync-architecture/`) stays on `main` — no feature branches needed for docs

### Branch Cleanup

Remote feature branches are kept on GitHub for audit trail after merging. Periodically (every few weeks), Stuart prunes stale remote branches:
```bash
# List merged remote branches (safe to delete)
git branch -r --merged dev | grep -v 'main\|dev\|HEAD'

# Delete stale remote branches older than 30 days
# Stuart runs this manually — Claude Code does NOT auto-delete remote branches
```

---

## What You Must NOT Do

- When running parallel sessions, use `git worktree` so each session has its own working directory — never `git checkout` to switch branches if other sessions may be active
- Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- Do NOT create database migrations, tables, columns, or constraints
- Do NOT use `sudo` for npm installs
- Do NOT hardcode dropdown values — always fetch from reference tables
- Do NOT use `alert()` or `confirm()` — use toast/modal components
- Do NOT create separate CSS/JS files — keep everything in single component files
- Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table
- Do NOT assume schema from memory — check actual table/view definitions via Supabase queries
- Do NOT create a data table without pagination — use the shared TablePagination component
- Do NOT show duplicate count displays (e.g. filter count at top AND pagination count at bottom)
- Do NOT ship feature changes without updating the corresponding architecture doc
- Do NOT refactor existing code to match Bulletproof React patterns unless Stuart asks
- Do NOT put non-publishable files in `guides/` — that directory syncs live to docs.getinsync.ca (see GitBook section)

---

## Database Access (Read-Only by Policy)

- A database connection is available via DATABASE_READONLY_URL in .env
- Use it ONLY for schema introspection: verifying view definitions, column names/types, checking policies
- Useful commands: pg_get_viewdef(), information_schema.columns, pg_tables, pg_policies
- You MUST treat this as READ-ONLY — SELECT queries only
- NEVER run INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, or TRUNCATE
- Do NOT use this for application data queries — only for schema validation
- Before modifying any TypeScript that queries a view, use this connection to check the actual view definition first
- Session-end checklist also uses this connection for security posture validation and stats alignment

---

## Mid-Session Schema Checkpoint

Run this checkpoint after Stuart confirms a complete unit of database work is finished. A unit may involve multiple SQL chunks (e.g., table + columns + triggers + RLS policies applied in sequence). Wait for Stuart to signal completion — phrases like "schema done", "that's the last chunk", or "all scripts applied" — before running the checkpoint. Do NOT run after each individual script chunk mid-sequence. Do NOT wait for the session-end checklist.

```bash
# 1. Security posture validation (zero FAIL rows = pass)
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)
psql "$DATABASE_READONLY_URL" -f ./docs-architecture/testing/security-posture-validation.sql

# 2. TypeScript check (zero errors = pass)
npx tsc --noEmit
```

- **All pass:** Say "Schema checkpoint passed" and continue working
- **Any failure:** STOP. Report the specific failures to Stuart. Do not continue feature work until resolved.
- This does NOT replace the session-end checklist — that still runs at session end
- Do NOT run the full session-end checklist after every DB change — use this checkpoint instead

---

## View-to-TypeScript Contract Rule

When the app queries a Supabase view, the TypeScript interface MUST exactly match the view's column names and types. If you find a mismatch:
1. Check whether the view or the TypeScript is wrong
2. Fix the TypeScript to match the view (the view is the source of truth)
3. Grep for all files using that interface and update them

---

## Error Handling Patterns

- Wrap all Supabase calls in try/catch
- Show toast notification on error (not console.log, not alert)
- Revert UI state on error (e.g., revert dropdown selection)
- Loading state during mutations (disable buttons)

---

## GitBook Docs Site — Live Sync from `guides/`

The `guides/` directory in this repo syncs automatically to **docs.getinsync.ca** via GitBook Git Sync.

**Every push to `main` that touches `guides/` triggers a live publish.** There is no staging — changes go straight to the public docs site.

### What belongs in `guides/`

Only markdown files intended for public docs.getinsync.ca belong in `guides/`. Currently:

| Path | Published URL |
|------|--------------|
| `guides/whats-new.md` | `docs.getinsync.ca/whats-new` |
| `guides/user-help/getting-started.md` | `docs.getinsync.ca/user-help/getting-started` |
| `guides/user-help/assessment-guide.md` | `docs.getinsync.ca/user-help/assessment-guide` |
| `guides/user-help/time-framework.md` | `docs.getinsync.ca/user-help/time-framework` |
| `guides/user-help/paid-framework.md` | `docs.getinsync.ca/user-help/paid-framework` |
| `guides/user-help/deployment-profiles.md` | `docs.getinsync.ca/user-help/deployment-profiles` |
| `guides/user-help/tech-health.md` | `docs.getinsync.ca/user-help/tech-health` |
| `guides/user-help/roadmap-initiatives.md` | `docs.getinsync.ca/user-help/roadmap-initiatives` |
| `guides/user-help/integrations.md` | `docs.getinsync.ca/user-help/integrations` |

### What does NOT belong in `guides/`

- `.docx` files, `.zip` files, or any non-markdown assets — move to `marketing/`
- Internal architecture docs — those stay in their existing directories (`core/`, `features/`, etc.)
- Draft docs not ready for public — keep in `marketing/` or another directory until ready

### Internal link rules

GitBook Git Sync resolves markdown links as **relative file paths**, not URL paths. When linking between pages in `guides/user-help/`:

```markdown
<!-- CORRECT — relative file path -->
See [What Are Deployment Profiles?](deployment-profiles.md)

<!-- WRONG — absolute URL path (resolves to GitHub, not GitBook) -->
See [What Are Deployment Profiles?](/user-help/deployment-profiles)

<!-- WRONG — bare slug (also resolves to GitHub) -->
See [What Are Deployment Profiles?](/deployment-profiles)
```

For links from `user-help/` to `whats-new.md` (one level up): `[What's New](../whats-new.md)`

### When editing user help articles

1. Edit the `.md` file in `guides/user-help/`
2. Use relative file paths for all internal cross-references
3. Commit and push to `main` — GitBook re-syncs automatically within ~1 minute
4. Update `guides/whats-new.md` if the change is user-visible

### Do NOT

- Do NOT put non-publishable files (`.docx`, `.zip`, images, drafts) in `guides/`
- Do NOT use absolute URL paths or bare slugs in markdown links
- Do NOT create new subdirectories in `guides/` without telling Stuart — new folders create new sections on the live docs site

---

## Architecture Documentation Reference

Stuart maintains architecture docs in the `getinsync-architecture` repo (symlinked at `./docs-architecture/`).

### Key References

| Path | Purpose |
|------|---------|
| `docs-architecture/MANIFEST.md` | Full document index — UPDATE THIS after every doc change |
| `docs-architecture/operations/development-rules.md` | Team workflow rules |
| `docs-architecture/operations/session-end-checklist.md` | Session-end validation — read this when Stuart says "run session-end checklist" |
| `docs-architecture/operations/screen-building-guidelines.md` | Page layout zones, KPI cards, typography, spacing |
| `docs-architecture/operations/new-table-checklist.md` | New table creation checklist |
| `docs-architecture/operations/database-change-validation.md` | Database validation queries |
| `docs-architecture/identity-security/security-validation-runbook.md` | Security posture checks |
| `docs-architecture/identity-security/rls-policy-addendum.md` | RLS policy patterns |
| `docs-architecture/schema/nextgen-schema-current.sql` | Current database schema |
| `docs-architecture/testing/pgtap-rls-coverage.sql` | pgTAP security regression (397 assertions) |
| `docs-architecture/testing/security-posture-validation.sql` | Standalone security validator |

### Feature-to-Doc Map

When you change a feature area, update the corresponding doc:

| Feature Area | Architecture Doc |
|-------------|-----------------|
| Overview / Dashboard | `operations/screen-building-guidelines.md` |
| App Health / TIME-PAID | `core/time-paid-methodology.md` |
| Tech Health / Dashboard | `features/technology-health/dashboard.md` |
| Tech Health / Lifecycle data | `features/technology-health/lifecycle-intelligence.md` |
| Roadmap | `features/roadmap/architecture.md` |
| Cost Model | `features/cost-budget/cost-model.md` |
| Budgets | `features/cost-budget/budget-management.md` |
| Integrations | `features/integrations/architecture.md` |
| Global Search | `features/global-search/architecture.md` |
| Visual Diagram tab | `core/visual-diagram.md` |
| Deployment Profiles | `core/deployment-profile.md` |
| Software Products | `catalogs/software-product.md` |
| IT Services | `catalogs/it-service.md` |
| Technology Catalog | `catalogs/technology-catalog.md` |
| Contacts / Involved Parties | `core/involved-party.md` |
| User Management / Auth | `identity-security/identity-security.md` |
| RLS Policies | `identity-security/rls-policy.md` |
| RBAC / Roles | `identity-security/rbac-permissions.md` |
| Namespace / Workspace UI | `core/namespace-management-ui.md` |
| Workspace Groups | `core/workspace-group.md` |
| Gamification | `features/gamification/architecture.md` |
| User Help Articles | `guides/user-help/*.md` (GitBook-synced — see GitBook section above) |
| What's New / Changelog | `guides/whats-new.md` (GitBook-synced) |
| Feature Walk-Through | `marketing/feature-walkthrough.md` |
| Tech Health Badges | `marketing/user-documentation/technology-health-badges.md` |

If your feature area is not listed, `grep -r "keyword" docs-architecture/` to find the right doc, or tell Stuart it is missing.

---

## Quick Reference: Common Supabase Query Pattern

```typescript
// Fetch from reference table
const { data, error } = await supabase
  .from('criticality_types')
  .select('code, name')
  .eq('is_active', true)
  .order('display_order');

// Fetch from view
const { data, error } = await supabase
  .from('vw_workspace_budget_summary')
  .select('*')
  .eq('workspace_id', workspaceId)
  .single();
```

---

## Open Items — UI Refactoring Backlog

Track these for future sessions. When Stuart asks to continue refactoring, start here.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | **ModalShell + ModalFooter** — Migrate remaining ~25 modals to shared components | In Progress | `src/components/shared/ModalShell.tsx`, `ModalFooter.tsx` created. 8 modals migrated. ~25 remain. |
| 2 | **useReferenceTable hook** — Extract duplicated reference table Supabase queries (18 files) into `src/hooks/useReferenceTable.ts` | Not Started | Pattern: `.from(table).select('code, name').eq('is_active', true).order('display_order')` repeated in 18 files. |
| 3 | **App.tsx decomposition** — Extract `usePortfolioActions` and `useDashboardNavigation` hooks to reduce App.tsx from 952 to ~300 lines | Not Started | App.tsx has 59 imports and 16+ useState calls. |
| 4 | **File reorganization** — Move 30+ modal files from `src/components/` root into `src/components/modals/` with barrel exports | Not Started | 62 files at component root; 20+ are modals. |
| 5 | **Split usePortfolios.ts** (889 lines) into `usePortfolioList`, `usePortfolioDetail`, `usePortfolioHierarchy` | Not Started | Currently contains 3 separate hooks in one file. |

---

*Last updated: March 19, 2026*
*Update this file when architecture rules change.*
