# Session Prompt 01 — Riverside Application Category Enrichment (Application Categories, Part 1 of 3)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> It is a complete, standalone brief — it assumes no prior conversation context.
> This session does NOT execute any database writes. It produces chunked SQL files in `docs-architecture/planning/application-categories/enrichment-sql/` for Stuart to paste into the Supabase SQL Editor manually. The session is gated by a checkpoint with Stuart before any SQL is written.

---

## Task: Propose and generate Riverside application category assignments

You are starting fresh. Read this entire brief before doing anything. Do not read other files in the repo until instructed. Do not write any SQL until you have completed Step 1 (read required context), Step 2 (live inventory), and Step 3 (mapping checkpoint with Stuart).

### Why this work exists

The GetInSync NextGen schema supports a many-to-many relationship between applications and a per-namespace `application_categories` catalog (e.g. Finance & Accounting, Human Resources, CRM & Citizen Services, GIS & Spatial). The catalog is in production, the assignment UI is in production (`ApplicationForm.tsx`, `useApplicationCategories.ts`), and the City of Riverside demo namespace already has all 14 categories defined.

But **0 of Riverside's 32 applications have category assignments**. This blocks AI Chat queries like *"what apps do we have for Customer Relationship Management?"* — the data exists in the schema but the demo namespace is empty for this dimension.

This session populates the `application_category_assignments` junction table for Riverside so the AI Chat tools shipped in Session 2 of this initiative have real data to query. It is purely demo-data work — no schema changes, no view changes, no code.

You are Session 1 of 3 in the Application Categories initiative. Sessions 2 and 3 are queued at `02-session-prompt-ai-chat-category-tools.md` and `03-session-prompt-category-eval.md` in the same directory.

### Hard rules (read before touching anything)

1. **You MUST NOT execute any database writes.** Your `DATABASE_READONLY_URL` connection is read-only by policy and you will use it ONLY for `SELECT` queries against `applications`, `workspaces`, `application_categories`, `service_types`, `application_service_types`, and other reference tables.
2. **You MUST NOT modify any database schema.** No `ALTER TABLE`, no `CREATE`, no `DROP`, no migrations. The two tables you are populating (`application_categories`, `application_category_assignments`) already exist in production with the correct structure.
3. **You MUST NOT modify any code.** No files outside `docs-architecture/planning/application-categories/` may be touched.
4. **You MUST checkpoint with Stuart** after producing the proposed mapping table (Step 3). Wait for explicit approval before generating SQL. Do not proceed past the checkpoint without an affirmative response in the chat.
5. **You MUST use the chunked-SQL pattern** with `BEGIN; ... COMMIT;` wrappers and CTE+UNION ALL verifier queries. See the CLAUDE.md rule "Supabase SQL Editor — Multi-statement output semantics" — the SQL Editor only displays the LAST result set from a multi-statement query, so all verification SELECTs in a chunk must be consolidated into one CTE+UNION ALL query.
6. **You MUST NOT use the `Uncategorized` category** (code `UNCATEGORIZED`, display_order 99) in any assignment. It exists as a default for net-new apps users add via the form. All 32 Riverside apps must end up in real categories.
7. **You MUST assign every Riverside application** to at least one category. Multi-category is the norm — most real apps span 2-3 categories. Single-category assignment is fine when a system is genuinely focused (e.g. a pure firewall is just `SECURITY`), but err on the side of completeness.
8. **You MUST scope every assignment to Riverside.** The `application_categories` table is namespace-scoped, and `application_category_assignments` references both the app and the category. Verify both sides resolve to Riverside before generating any INSERT.
9. **You MUST NOT touch other namespaces.** The Riverside namespace ID is `a1b2c3d4-e5f6-7890-abcd-ef1234567890`. Every SQL chunk must filter by this ID or by app IDs that resolve to a Riverside workspace. If any query touches a different namespace, STOP and tell Stuart.
10. **You MUST NOT deploy or run anything against the production database.** Stuart pastes the chunks manually into the Supabase SQL Editor.

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/planning/application-categories/README.md
   - Tracker, decision log, schema reference, Riverside catalog
   - Pay attention to the "Uncategorized is reserved" rule and the
     execution flow

2. docs-architecture/planning/phase-0-assets/enrichment-session-prompt.md
   - The precedent for chunked SQL paste-into-SQL-Editor pattern
   - Read the structure (00-verify, 01..NN-assign, 99-verify) and
     the CTE+UNION ALL verifier idiom — you will mirror this exactly

3. CLAUDE.md (at repo root)
   - "Supabase SQL Editor — Multi-statement output semantics" rule
     (the multi-statement output gotcha that bit the Phase 0 chunks)
   - "Database Access (Read-Only by Policy)" rule
   - "What You Must NOT Do" rule

4. docs-architecture/schema/nextgen-schema-current.sql
   - Look up `application_categories`, `application_category_assignments`,
     and `applications` definitions to confirm columns and FK behavior
```

You do NOT need to read the AI Chat tools or the Batch 1/2 work. Session 2 owns those changes.

### Step 2 — Live inventory of Riverside

Use `DATABASE_READONLY_URL` to gather the data you need. Run these queries (or equivalents) and keep the output for Step 3.

```bash
cd ~/Dev/getinsync-nextgen-ag
export $(grep DATABASE_READONLY_URL .env | xargs)
```

**Query 1 — confirm Riverside namespace ID and category catalog:**

```sql
-- Riverside namespace ID should be a1b2c3d4-e5f6-7890-abcd-ef1234567890
SELECT id, name FROM namespaces WHERE name ILIKE '%riverside%';

-- 14 categories — verify the catalog is current
SELECT id, code, name, description, display_order, is_active
FROM application_categories
WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY display_order;
```

**Query 2 — every Riverside application with name, workspace, and description:**

```sql
SELECT
  a.id,
  a.name AS application_name,
  w.name AS workspace_name,
  a.description,
  a.operational_status,
  a.business_purpose
FROM applications a
JOIN workspaces w ON a.workspace_id = w.id
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY w.name, a.name;
```

**Query 3 — service types per application (the strongest hint for category mapping):**

```sql
SELECT
  a.id AS application_id,
  a.name AS application_name,
  st.name AS service_type_name,
  stc.name AS service_type_category_name
FROM applications a
JOIN workspaces w ON a.workspace_id = w.id
LEFT JOIN application_service_types ast ON ast.application_id = a.id
LEFT JOIN service_types st ON st.id = ast.service_type_id
LEFT JOIN service_type_categories stc ON stc.id = st.category_id
WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY a.name, st.name;
```

If `application_service_types` does not exist or is empty for Riverside, fall back to inferring from name + description + workspace + business_purpose. Do not invent service_type data.

**Query 4 — baseline assignment count (must be zero before enrichment):**

```sql
SELECT
  (SELECT COUNT(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_apps,
  (SELECT COUNT(DISTINCT aca.application_id) FROM application_category_assignments aca
    JOIN applications a ON a.id = aca.application_id
    JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS apps_with_categories,
  (SELECT COUNT(*) FROM application_category_assignments aca
    JOIN applications a ON a.id = aca.application_id
    JOIN workspaces w ON a.workspace_id = w.id
    WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_assignments;
```

Expected: 32 / 0 / 0. If the baseline is non-zero, STOP and tell Stuart — the work has already been partially done and we need to decide whether to add to it or start clean.

### Step 3 — Propose mappings and CHECKPOINT WITH STUART

Build a markdown table with one row per Riverside application showing:
- Application name
- Workspace
- Proposed category codes (comma-separated, primary first)
- Brief justification (one short sentence — "GIS/mapping platform", "police RMS", "general ledger system", etc.)

Sort the table by workspace, then by application name within each workspace, so Stuart can scan it efficiently.

**Mapping guidance:**

- **Multi-category is the norm.** Most real apps span 2-3 categories. Hexagon OnCall CAD/RMS is plausibly `LEGAL` (case management) + `RECORDS` (records management) + `GIS_SPATIAL` (mapping for dispatch). Workday HCM is `HR` (workforce) + `FINANCE` (payroll). NG911 System is `CRM` (citizen service intake) + `HEALTH` (emergency response). Use your judgment based on the system's primary capabilities.
- **Single-category assignment is OK** when the system is genuinely focused. A pure backup system is just `INFRASTRUCTURE`. A pure document repository is just `RECORDS`. A pure SSO product is just `SECURITY`.
- **Read the catalog descriptions carefully.** "CRM & Citizen Services" includes case management and service requests. "Records & Document Mgmt" is document and retention management. "Legal & Regulatory" is case management AND legal research AND tribunal systems. There is some overlap; make a defensible choice and explain it in the justification column.
- **Do NOT assign to Uncategorized.** It is reserved.
- **Do NOT invent capabilities** the app does not have. If the app's name and description don't support a category, leave that category off.
- **Order categories by primacy.** The first category in the comma-separated list should be the system's primary capability. (The schema does not have a "primary category" flag, but ordering them helps Stuart review.)

**After the table is written, present it to Stuart and pause.** Use phrasing like:

> "Here is the proposed mapping for all 32 Riverside applications. Please review the assignments — particularly the multi-category cases — and let me know if any need to change before I generate the SQL chunks. Reply 'approved' or list specific changes."

Wait for an affirmative response. Do NOT proceed to Step 4 without it. If Stuart asks for changes, revise the table and present it again. Iterate until approved.

### Step 4 — Generate the chunked SQL files

After Stuart approves the mapping, create the directory and files:

```
docs-architecture/planning/application-categories/enrichment-sql/
├── 00-verify-baseline.sql
├── 01-assign-police-department.sql
├── 02-assign-fire-and-emergency.sql
├── 03-assign-finance-and-hr.sql
├── 04-assign-it-and-infrastructure.sql
├── 05-assign-public-services-and-other.sql
└── 99-verify-final.sql
```

The exact chunk count and file names depend on how the apps cluster by workspace — group apps so each chunk contains 4-8 INSERTs and one consolidated verifier. If a workspace has only one or two apps, fold it into the closest related chunk. Do NOT use one chunk per app — that's overkill.

**File `00-verify-baseline.sql`:**

A read-only snapshot script that proves the starting state (32 apps, 0 assignments, 14 categories) using ONE consolidated CTE+UNION ALL query. Stuart runs this first as a sanity check before any writes.

```sql
-- Run this BEFORE any enrichment chunks to confirm the starting state
-- Expected: 32 apps, 0 apps_with_categories, 0 total_assignments, 14 categories
\pset pager off

WITH counts AS (
  SELECT
    (SELECT COUNT(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_apps,
    (SELECT COUNT(DISTINCT aca.application_id) FROM application_category_assignments aca
      JOIN applications a ON a.id = aca.application_id
      JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS apps_with_categories,
    (SELECT COUNT(*) FROM application_category_assignments aca
      JOIN applications a ON a.id = aca.application_id
      JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') AS total_assignments,
    (SELECT COUNT(*) FROM application_categories
      WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' AND is_active = true) AS active_categories
)
SELECT 1 AS ord, 'baseline' AS section,
       jsonb_build_object(
         'total_apps', total_apps,
         'apps_with_categories', apps_with_categories,
         'total_assignments', total_assignments,
         'active_categories', active_categories
       ) AS details
FROM counts;
```

**Each `0N-assign-*.sql` chunk:**

Wrap in a transaction and use a CTE-driven INSERT pattern that resolves application name → app_id and category code → category_id by name lookup, so the chunk is robust against UUID changes:

```sql
-- Chunk 01 — assign categories to Police Department applications
-- Stuart: paste this into Supabase SQL Editor and check the verifier output below
\pset pager off

BEGIN;

-- Apps and categories to assign in this chunk
WITH ns AS (
  SELECT id FROM namespaces WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
mapping (app_name, category_codes) AS (
  VALUES
    ('Hexagon OnCall CAD/RMS', ARRAY['LEGAL', 'RECORDS', 'GIS_SPATIAL']),
    ('Computer-Aided Dispatch', ARRAY['CRM', 'GIS_SPATIAL']),
    ('NG911 System', ARRAY['CRM', 'HEALTH']),
    -- ... etc, one row per app in this chunk
    ('Police Records Management', ARRAY['LEGAL', 'RECORDS'])
),
expanded AS (
  SELECT m.app_name, unnest(m.category_codes) AS category_code FROM mapping m
),
resolved AS (
  SELECT
    a.id AS application_id,
    ac.id AS category_id,
    e.app_name,
    e.category_code
  FROM expanded e
  JOIN applications a ON a.name = e.app_name
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN application_categories ac
    ON ac.namespace_id = w.namespace_id
   AND ac.code = e.category_code
  WHERE w.namespace_id = (SELECT id FROM ns)
)
INSERT INTO application_category_assignments (application_id, category_id)
SELECT application_id, category_id FROM resolved
ON CONFLICT (application_id, category_id) DO NOTHING;

COMMIT;

-- Consolidated verifier (one query, single result set)
WITH chunk_apps AS (
  SELECT a.id, a.name
  FROM applications a
  JOIN workspaces w ON a.workspace_id = w.id
  WHERE w.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND a.name IN ('Hexagon OnCall CAD/RMS', 'Computer-Aided Dispatch', 'NG911 System', /* etc */ )
),
per_app AS (
  SELECT
    ca.name AS app_name,
    array_agg(ac.code ORDER BY ac.display_order) AS assigned_codes
  FROM chunk_apps ca
  LEFT JOIN application_category_assignments aca ON aca.application_id = ca.id
  LEFT JOIN application_categories ac ON ac.id = aca.category_id
  GROUP BY ca.name
)
SELECT 1 AS ord, app_name AS section,
       jsonb_build_object('codes', assigned_codes) AS details
FROM per_app
ORDER BY app_name;
```

**Why the CTE INSERT pattern:**

- It resolves apps by name (not by UUID), so the script is portable across environments and you don't have to embed UUIDs in the file.
- It uses `ON CONFLICT DO NOTHING` so re-running the chunk is safe.
- It scopes by Riverside's namespace ID at the join level, so cross-namespace contamination is impossible.
- The `mapping` CTE makes it easy for Stuart to see which apps and codes are touched by this chunk at a glance.

**File `99-verify-final.sql`:**

The consolidated CTE+UNION ALL verifier covering all post-enrichment expectations. ONE query, ONE result set, multiple sections via the `(ord, section, details)` shape per the CLAUDE.md rule:

```sql
-- Run this AFTER all enrichment chunks to confirm the final state
-- Expected: every Riverside app has at least one category, total assignments matches the proposed mapping count
\pset pager off

WITH ns AS (
  SELECT id FROM namespaces WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
),
totals AS (
  SELECT
    (SELECT COUNT(*) FROM applications a JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS total_apps,
    (SELECT COUNT(DISTINCT aca.application_id) FROM application_category_assignments aca
      JOIN applications a ON a.id = aca.application_id
      JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS apps_with_categories,
    (SELECT COUNT(*) FROM application_category_assignments aca
      JOIN applications a ON a.id = aca.application_id
      JOIN workspaces w ON a.workspace_id = w.id
      WHERE w.namespace_id = (SELECT id FROM ns)) AS total_assignments
),
unassigned AS (
  SELECT a.name
  FROM applications a
  JOIN workspaces w ON w.id = a.workspace_id
  LEFT JOIN application_category_assignments aca ON aca.application_id = a.id
  WHERE w.namespace_id = (SELECT id FROM ns)
    AND aca.id IS NULL
),
uncategorized_misuse AS (
  SELECT a.name AS app_name, ac.code
  FROM application_category_assignments aca
  JOIN applications a ON a.id = aca.application_id
  JOIN workspaces w ON w.id = a.workspace_id
  JOIN application_categories ac ON ac.id = aca.category_id
  WHERE w.namespace_id = (SELECT id FROM ns)
    AND ac.code = 'UNCATEGORIZED'
),
per_category AS (
  SELECT
    ac.code,
    ac.name,
    COUNT(aca.id) AS app_count
  FROM application_categories ac
  LEFT JOIN application_category_assignments aca ON aca.category_id = ac.id
  LEFT JOIN applications a ON a.id = aca.application_id
  LEFT JOIN workspaces w ON w.id = a.workspace_id
  WHERE ac.namespace_id = (SELECT id FROM ns)
    AND (aca.id IS NULL OR w.namespace_id = (SELECT id FROM ns))
  GROUP BY ac.code, ac.name, ac.display_order
)
SELECT ord, section, details FROM (
  SELECT 1 AS ord, 'totals' AS section,
         jsonb_build_object(
           'total_apps', total_apps,
           'apps_with_categories', apps_with_categories,
           'total_assignments', total_assignments
         ) AS details
  FROM totals
  UNION ALL
  SELECT 2, 'unassigned_apps_count',
         jsonb_build_object('count', (SELECT COUNT(*) FROM unassigned),
                            'names', COALESCE(jsonb_agg(name), '[]'::jsonb))
  FROM unassigned
  UNION ALL
  SELECT 3, 'uncategorized_misuse_count',
         jsonb_build_object('count', (SELECT COUNT(*) FROM uncategorized_misuse))
  UNION ALL
  SELECT 4 + ROW_NUMBER() OVER (ORDER BY code), code,
         jsonb_build_object('name', name, 'app_count', app_count)
  FROM per_category
) x
ORDER BY ord, section;
```

**Pass criteria for `99-verify-final.sql`:**
- `totals.apps_with_categories` = `totals.total_apps` = 32
- `unassigned_apps_count.count` = 0
- `uncategorized_misuse_count.count` = 0
- `per_category` shows non-zero counts for the categories you assigned, and zero for the ones you intentionally left unused (e.g. maybe Riverside has no DEVELOPMENT or ANALYTICS apps — fine, they should show 0)

### Step 5 — Commit the SQL files to the architecture repo

```bash
cd ~/getinsync-architecture
git add planning/application-categories/enrichment-sql/

git status --short  # confirm only files in enrichment-sql/

git commit -m "$(cat <<'EOF'
planning: Riverside application category enrichment SQL chunks

Generated by Session 1 of the application-categories initiative
(planning/application-categories/01-session-prompt-riverside-category-data.md).

Adds chunked SQL for Stuart to paste into the Supabase SQL Editor:
- 00-verify-baseline.sql — pre-enrichment sanity check
- 01..NN-assign-*.sql — category assignments grouped by workspace cluster
- 99-verify-final.sql — consolidated CTE+UNION ALL verifier

All chunks scope writes to Riverside namespace
(a1b2c3d4-e5f6-7890-abcd-ef1234567890) via the application/workspace
join. ON CONFLICT DO NOTHING makes chunks safe to re-run. The
Uncategorized category is intentionally not used.

Stuart-approved mapping table is preserved in the session transcript.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)" && git push origin main

cd ~/Dev/getinsync-nextgen-ag
```

### Step 6 — Session summary

Produce a short final message listing:

1. The number of chunk files generated and their names
2. The total number of category assignments the chunks will create (sum of all rows in the `mapping` CTEs)
3. The category-by-category breakdown (how many apps will land in each of the 14 categories)
4. The 1-3 multi-category cases you most expect Stuart to want to revisit, with your reasoning, so he knows what to look for when he reviews
5. A one-line summary of next steps:
   *"Stuart: paste 00-verify-baseline.sql into the Supabase SQL Editor first to confirm the starting state, then paste 01..NN-assign-*.sql in order, then paste 99-verify-final.sql to confirm 32 apps assigned, 0 unassigned, 0 Uncategorized misuse. After verification passes, Session 2 (`02-session-prompt-ai-chat-category-tools.md`) is ready to run."*

### Done criteria checklist

- [ ] All required-reading files in Step 1 have been read
- [ ] Live Riverside inventory pulled via DATABASE_READONLY_URL (queries 1-4 from Step 2)
- [ ] Baseline confirmed: 32 apps, 0 with categories, 0 assignments, 14 active categories
- [ ] Proposed mapping table presented to Stuart with one row per app
- [ ] Stuart approved the mapping (or asked for changes that have been incorporated and re-approved)
- [ ] No application is mapped to UNCATEGORIZED
- [ ] Every Riverside application has at least one category in the proposed mapping
- [ ] Multi-category assignments are used where appropriate (not artificially single-category)
- [ ] `enrichment-sql/` directory created under `docs-architecture/planning/application-categories/`
- [ ] `00-verify-baseline.sql` created
- [ ] One or more `0N-assign-*.sql` chunks created, each with `BEGIN; ... COMMIT;` wrapping and a consolidated verifier
- [ ] `99-verify-final.sql` created with CTE+UNION ALL covering totals, unassigned, uncategorized_misuse, and per-category counts
- [ ] All SQL files use the namespace ID `a1b2c3d4-e5f6-7890-abcd-ef1234567890` and never reference any other namespace
- [ ] Architecture repo committed and pushed on `main`
- [ ] Session summary produced

### What NOT to do

- Do NOT execute any database writes from this session. The connection is read-only by policy.
- Do NOT use the `Uncategorized` category in any assignment.
- Do NOT skip the checkpoint with Stuart in Step 3. Generating SQL before approval wastes Stuart's review time and risks shipping the wrong mappings.
- Do NOT touch any code files outside `docs-architecture/planning/application-categories/`.
- Do NOT modify existing files in `phase-0-assets/` or `ai-chat-harness-optimization/`.
- Do NOT create per-app chunk files. Group apps by workspace cluster.
- Do NOT use `INSERT ... VALUES` with hardcoded UUIDs. Use the CTE name-resolution pattern shown in Step 4.
- Do NOT skip `ON CONFLICT DO NOTHING`. Chunks must be re-runnable.
- Do NOT touch other namespaces. Every query must scope to `a1b2c3d4-e5f6-7890-abcd-ef1234567890`.
- Do NOT add new categories to `application_categories`. The 14-row catalog is the catalog.
- Do NOT generate verification SELECTs that produce more than one result set per chunk. Use CTE+UNION ALL with the `(ord, section, details)` shape per the CLAUDE.md SQL Editor rule.
- Do NOT deploy the Edge Function or merge any branch. This session is data-only.

---

**End of prompt. Paste everything above (not including this line) into a fresh Claude Code session.**
