# CLAUDE.md — GetInSync NextGen Development Rules

> This file is read by Claude Code at the start of every session.
> It defines rules you MUST follow while writing code.
> For session-end validation, Stuart runs separate checklists from the project docs.

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

## Architecture Rules — ALWAYS FOLLOW

### Data Model
- **Deployment Profile is the assessment anchor, NOT Application.** Scores live on deployment_profiles.
- **Cost data lives on cost channels** (SoftwareProduct / ITService / CostBundle), NEVER on applications directly.
- **Budget data lives in workspace_budgets table**, NOT workspaces.budget_amount (that column is legacy — do not read or write to it).
- **Namespace-level config:** Assessment factors/thresholds are universal within a namespace.

### Dropdowns & Reference Tables
- **ALL dropdowns MUST fetch from database reference tables.** Never hardcode arrays in React.
- If a dropdown doesn't have a reference table yet, stop and tell Stuart "we need a reference table for this."
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

---

## Git Workflow

- **Branch:** Work on `dev`, merge to `main` for deployment
- **Commit messages:** Use prefixes: `feat:` / `fix:` / `refactor:` / `chore:`
- **Push after commits:** Always push to origin
- **Deploy flow:** dev → main → Netlify auto-deploys from main

---

## What You Must NOT Do

- ❌ Do NOT modify database schema (Stuart handles that via Supabase SQL Editor)
- ❌ Do NOT create database migrations, tables, columns, or constraints
- ❌ Do NOT use `sudo` for npm installs
- ❌ Do NOT hardcode dropdown values — always fetch from reference tables
- ❌ Do NOT use `alert()` or `confirm()` — use toast/modal components
- ❌ Do NOT create separate CSS/JS files — keep everything in single component files
- ❌ Do NOT read from `workspaces.budget_amount` — use `workspace_budgets` table
- ❌ Do NOT assume schema from memory — check actual table/view definitions via Supabase queries

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

## Existing Documentation (for reference, do not modify)

Stuart maintains these docs in the Claude Project. You don't need to read them, but know they exist:

| Document | Purpose |
|----------|---------|
| `getinsync-development-rules-v1_3.md` | Team workflow rules (Claude Project ↔ Stuart ↔ AG) |
| `operations/session-end-checklist.md` | Session-end validation (Stuart runs this, not you) |
| `operations/new-table-checklist.md` | New table creation checklist |
| `operations/database-change-validation.md` | Database validation queries |
| `identity-security/security-validation-runbook.md` | Security posture checks |
| `identity-security/rls-policy-addendum.md` | RLS policy patterns |

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

*Last updated: February 17, 2026*
*Update this file when architecture rules change.*
