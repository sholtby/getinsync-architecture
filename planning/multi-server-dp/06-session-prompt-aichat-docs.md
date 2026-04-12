# Session Prompt 06 — Multi-Server DP: AI Chat Tools + Architecture Docs

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: Session 01 SQL must be applied. Can run in PARALLEL with Sessions 04 and 05 (use git worktree).
> Estimated: 30-45 min. This is the ONLY session that commits to both repos.

---

## Task: Update AI Chat server context builder and update 4 architecture docs + MANIFEST

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The AI Chat Edge Function builds a "Servers" context section for each application by querying `deployment_profiles.server_name`. With the new junction table, this needs to query through `deployment_profile_servers` + `servers` and include role information. Additionally, 4 architecture docs need updating to reflect the multi-server model, plus the ADR needs a v2.0 amendment.

### Hard rules

1. **Branch:** `feat/multi-server-aichat-docs`. Create from `dev`.
2. **Code files you MAY modify:**
   - `supabase/functions/ai-chat/tools.ts`
3. **Architecture files you MUST update:**
   - `docs-architecture/adr/adr-dp-infrastructure-boundary.md`
   - `docs-architecture/core/deployment-profile.md`
   - `docs-architecture/features/technology-health/dashboard.md`
   - `docs-architecture/core/visual-diagram.md`
   - `docs-architecture/MANIFEST.md`
4. **Dual-repo commit required.** Code repo on feature branch, architecture repo on `main`.
5. **Do NOT deploy the Edge Function.** Stuart deploys manually.
6. **Use the read-only DB connection** to verify the junction table exists before writing queries.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - Sections "AI Chat Tools" and "ADR Update"

2. supabase/functions/ai-chat/tools.ts (lines 1040-1080)
   - Current server context builder — find the section that queries deployment_profiles
     for server_name IS NOT NULL and formats the output

3. docs-architecture/adr/adr-dp-infrastructure-boundary.md
   - Current v1.1 — needs v2.0 amendment

4. docs-architecture/core/deployment-profile.md
   - Current server relationship section

5. docs-architecture/features/technology-health/dashboard.md
   - Server dashboard section

6. docs-architecture/core/visual-diagram.md
   - Node rendering spec

7. docs-architecture/MANIFEST.md
   - Document index — needs version bumps and changelog entries
```

### Step 2 — Verify schema via read-only DB

```bash
export $(grep DATABASE_READONLY_URL .env | xargs)

# Confirm junction table exists
psql "$DATABASE_READONLY_URL" -c "\d public.deployment_profile_servers"
psql "$DATABASE_READONLY_URL" -c "\d public.servers"

# Check what data exists
psql "$DATABASE_READONLY_URL" -c "SELECT count(*) FROM deployment_profile_servers"
psql "$DATABASE_READONLY_URL" -c "SELECT count(*) FROM servers"
```

### Step 3 — Update AI Chat server context builder

In `supabase/functions/ai-chat/tools.ts`, find the server context section (~lines 1052-1068).

**Current pattern:**
```typescript
// Fetches deployment_profiles where server_name IS NOT NULL
// Outputs: - server_name (dp_name)
```

**New pattern:**
```typescript
// Query through junction: deployment_profile_servers → servers → deployment_profiles
const { data: serverData } = await supabaseClient
  .from('deployment_profile_servers')
  .select(`
    server_role,
    is_primary,
    servers!inner (name),
    deployment_profiles!inner (name, application_id)
  `)
  .eq('deployment_profiles.application_id', applicationId);
```

If Supabase nested select doesn't work cleanly for this, use a simpler approach:
1. Fetch DPs for the application
2. Fetch junction rows for those DP ids, joined with servers
3. Format the output

**New output format:**
```
## Servers
- PROD-SQL-01 (database) → Production MSSQL [primary]
- PROD-APP-01 (application) → Production IIS
- PROD-WEB-01 (web) → Production Apache
```

Include `[primary]` marker for the primary server. Include role in parentheses. Show DP name after the arrow.

**Backward compatibility:** If no junction rows exist for a DP but `server_name` is populated on the DP record, fall back to the old format. This handles the transition period before all data is migrated.

### Step 4 — Update ADR to v2.0

In `docs-architecture/adr/adr-dp-infrastructure-boundary.md`:

- Bump version to 2.0
- Add a new section "## Amendment — Multi-Server Support (April 2026)" after the existing content but before the Changelog
- Content:
  - **What changed:** GetInSync now supports multiple server references per DP via a many-to-many junction (`deployment_profile_servers`) with role context.
  - **Why:** Real-world import data (Garland, other municipal clients) has multiple named servers per deployment. Forcing a single-server choice lost valuable portfolio intelligence.
  - **Boundary unchanged:** The `servers` table is a portfolio-level reference for grouping and visualization — name, optional OS, optional data center link. It is NOT a CMDB CI. ServiceNow still owns operational attributes (IP, FQDN, patching, monitoring).
  - **Migration:** Existing `server_name` values were deduplicated into `servers` rows with junction links. The `server_name` column is retained during transition and will be dropped in a future release.
- Update Changelog section

### Step 5 — Update deployment-profile.md

In `docs-architecture/core/deployment-profile.md`:

- Find the section describing `server_name` (or server relationship)
- Update to describe the many-to-many: `servers` table + `deployment_profile_servers` junction with `server_role` and `is_primary`
- Note that `server_name` text column is retained for backward compat during transition
- Reference the ADR v2.0

### Step 6 — Update dashboard.md

In `docs-architecture/features/technology-health/dashboard.md`:

- Find the "By Server" tab/section
- Update to describe entity-based grouping (by `servers.id` not free text)
- Note new columns: OS, Data Center, Status from the `servers` entity
- Reference the new `vw_server_deployment_summary` view for server-centric queries

### Step 7 — Update visual-diagram.md

In `docs-architecture/core/visual-diagram.md`:

- Find the DPNode rendering spec
- Update to describe 3 zoom levels:
  - L1 (Compact): primary server name only
  - L2 (Enriched): primary + "+N" count badge
  - L3 (Hero): all servers with role labels
- Note that server nodes as a separate tier are a future enhancement

### Step 8 — Update MANIFEST.md

- Bump version numbers for all 4 updated docs
- Add changelog entries for each

### Step 9 — Commit both repos

```bash
# Code repo (feature branch)
cd ~/Dev/getinsync-nextgen-ag
git add supabase/functions/ai-chat/tools.ts
git commit -m "feat: AI Chat multi-server context builder with roles"
git push -u origin feat/multi-server-aichat-docs

# Architecture repo (always main)
cd ~/getinsync-architecture
git add -A
git commit -m "docs: multi-server DP updates — ADR v2.0, deployment-profile, dashboard, visual-diagram, MANIFEST"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] AI Chat server context includes role labels and primary marker
- [ ] Backward compat: falls back to `server_name` if no junction rows
- [ ] ADR updated to v2.0 with amendment section
- [ ] `deployment-profile.md` describes many-to-many server relationship
- [ ] `dashboard.md` describes entity-based server grouping
- [ ] `visual-diagram.md` describes 3-level server rendering
- [ ] `MANIFEST.md` has version bumps and changelog entries for all 4 docs
- [ ] Code repo committed and pushed on `feat/multi-server-aichat-docs`
- [ ] Architecture repo committed and pushed on `main`

### What NOT to do

- Do NOT deploy the Edge Function — Stuart deploys manually
- Do NOT modify AI Chat eval tests (manual testing needed after deploy)
- Do NOT add new AI tool functions — only update the existing server context builder
- Do NOT modify other Edge Functions
- Do NOT change the AI Chat system prompt or tool definitions schema
- Do NOT touch `src/` files — those are Sessions 03, 04, 05
