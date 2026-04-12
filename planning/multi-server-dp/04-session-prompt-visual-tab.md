# Session Prompt 04 — Multi-Server DP: Visual Tab Rendering

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: Session 02 types must be merged to `dev`. Can run in PARALLEL with Sessions 05 and 06 (use git worktree).
> Estimated: 30-45 min.

---

## Task: Update the Visual tab DPNode to render multiple servers at 3 zoom levels

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Visual tab currently shows a single `server_name` string on each DP node. Now that DPs can have multiple servers (via the `deployment_profile_servers` junction table), the node rendering needs to adapt: compact view shows just the primary server, enriched view shows primary + count badge, and hero view shows all servers with roles.

### Hard rules

1. **Branch:** `feat/multi-server-visual`. Create from `dev`.
2. **You MAY only modify files in:**
   - `src/components/visual/nodes/DPNode.tsx`
   - `src/hooks/useVisualGraphData.ts`
   - `src/components/visual/graphBuilders.ts`
3. **Run `npx tsc --noEmit` AND `npm run build` before committing.**
4. **Do NOT add server nodes as a new tier in the ReactFlow graph** — that is a future enhancement, out of scope.
5. **Graceful degradation:** If `servers` array is empty, render nothing (no crash, no "undefined").

### Step 1 — Read the required context (in this order)

```
1. docs-architecture/features/technology-health/multi-server-dp-design.md
   - Section "Visual Tab (DPNode)"

2. docs-architecture/core/visual-diagram.md
   - Overall visual tab architecture

3. src/components/visual/nodes/DPNode.tsx (full file)
   - DPNodeData interface (lines 8-21)
   - Level 3 Hero card server rendering (lines 97-102)
   - Level 2 Enriched card server rendering (lines 153-158)
   - Level 1 Compact card server rendering (lines 219-221)

4. src/hooks/useVisualGraphData.ts
   - DPQueryData interface (lines 33-42)
   - Supabase query selecting server_name (line 111)

5. src/components/visual/graphBuilders.ts
   - Three locations passing server_name to node data (lines 266, 350, 427)
```

### Step 2 — Update data pipeline

**`src/hooks/useVisualGraphData.ts`:**

1. Update the `DPQueryData` interface: replace `server_name: string | null` with a nested servers array. You'll need to fetch from the junction table.
2. Update the Supabase query (~line 111): the current query selects `server_name` directly from `deployment_profiles`. Change to a two-step approach:
   - First query: fetch DPs as before (minus `server_name`)
   - Second query: fetch `deployment_profile_servers` joined with `servers` for the relevant DP ids
   - Post-process: attach the server array to each DP record
   - OR use a single query with Supabase's nested select if the relationship is configured: `.select('..., deployment_profile_servers(id, server_role, is_primary, servers(id, name))')` — check if this works with the FK relationship.

The servers array shape for each DP should be:
```typescript
servers: Array<{ id: string; name: string; role: string | null; is_primary: boolean }>
```

**`src/components/visual/graphBuilders.ts`:**

Update all 3 locations (lines 266, 350, 427) to pass the `servers` array instead of `server_name` string into the DP node data object.

### Step 3 — Update DPNode rendering

**`src/components/visual/nodes/DPNode.tsx`:**

1. Update `DPNodeData` interface: replace `server_name: string | null` with:
   ```typescript
   servers: Array<{ id: string; name: string; role: string | null; is_primary: boolean }>;
   ```

2. Add a helper to get the primary server:
   ```typescript
   const primaryServer = d.servers.find(s => s.is_primary) || d.servers[0];
   const otherCount = d.servers.length - 1;
   ```

3. **Level 1 (Compact, ~line 219):** Show primary server name only.
   - Replace `{d.server_name && ...}` with `{primaryServer && <span className="text-gray-400 truncate">{primaryServer.name}</span>}`
   - Same position and styling as current single server_name

4. **Level 2 (Enriched, ~line 153):** Show primary server name + count badge.
   - Replace `{d.server_name && ...}` with:
   ```tsx
   {primaryServer && (
     <>
       <span>·</span>
       <span className="text-gray-400 truncate">{primaryServer.name}</span>
       {otherCount > 0 && (
         <span className="text-xs text-gray-500 bg-gray-100 rounded px-1">+{otherCount}</span>
       )}
     </>
   )}
   ```

5. **Level 3 (Hero, ~line 97):** Show all servers with roles.
   - Replace `{d.server_name && ...}` with a compact list:
   ```tsx
   {d.servers.length > 0 && (
     <div className="text-xs text-gray-400 truncate">
       {d.servers.map((s, i) => (
         <span key={s.id}>
           {i > 0 && ' · '}
           {s.name}{s.role && ` (${s.role})`}
         </span>
       ))}
     </div>
   )}
   ```

6. **Empty array guard:** If `d.servers.length === 0`, render nothing (same as current `server_name === null` behavior).

### Step 4 — Verify

```bash
npx tsc --noEmit
npm run build
```

### Step 5 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add src/components/visual/nodes/DPNode.tsx src/hooks/useVisualGraphData.ts src/components/visual/graphBuilders.ts
git commit -m "feat: visual tab multi-server DP rendering (L1 primary, L2 +badge, L3 all with roles)"
git push -u origin feat/multi-server-visual
```

### Done criteria checklist

- [ ] `npx tsc --noEmit` passes
- [ ] `npm run build` succeeds
- [ ] Level 1 (Compact): shows primary server name only
- [ ] Level 2 (Enriched): shows primary server name + "+N" badge when multiple
- [ ] Level 3 (Hero): shows all servers with role labels
- [ ] Empty servers array renders cleanly (no crash, no "undefined")
- [ ] No changes to dagre layout, spacing, or non-DP node types

### What NOT to do

- Do NOT add server nodes as a new tier in the ReactFlow graph (out of scope)
- Do NOT change the dagre layout algorithm or spacing
- Do NOT touch AppNode, ServiceNode, TechProductNode, or any non-DP node type
- Do NOT touch `src/components/technology-health/` (Session 05)
- Do NOT touch `supabase/functions/` or `docs-architecture/` (Session 06)
