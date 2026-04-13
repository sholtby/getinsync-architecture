# Session Prompt 01 — AI Chat: Add `has_owner` Filter to `list-applications` Tool

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 20-30 minutes

---

## Task: Add a boolean `has_owner` filter to the `list-applications` AI chat tool

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation claims users can ask "Show me all applications with no assigned business owner." The AI chat's `list-applications` tool currently has an `owner` filter that does case-insensitive partial name matching (`ilike`), but there is **no way to query for NULL/missing owners**. The `ilike` filter cannot match NULL values — it only matches non-null strings.

This adds a boolean `has_owner` parameter:
- `true` → applications where `owner_name IS NOT NULL`
- `false` → applications where `owner_name IS NULL`

### Hard rules

1. **Branch:** `fix/ai-chat-owner-filter`. Create from `dev`.
2. **You MAY only modify** `supabase/functions/ai-chat/tools.ts`. No other files.
3. **Run `npx tsc --noEmit` before committing** — must pass with zero errors.
4. **Follow the existing filter pattern exactly** — extract input, apply conditionally, add to filter description.
5. **Do not change any other tool** — only `list-applications`.

### Step 1 — Read the required context (in this order)

```
1. supabase/functions/ai-chat/tools.ts
   - TOOL_DEFINITIONS array — find 'list-applications' (look for the tool with name 'list-applications')
   - Its input_schema.properties — note all existing filters
   - executeListApplications() function — note the filter extraction pattern, query building, and filter description

2. Note these specific code patterns:
   - How ownerFilter is extracted:  const ownerFilter = (input.owner as string) || '';
   - How filters are applied:       if (ownerFilter) query = query.ilike('owner_name', `%${ownerFilter}%`);
   - How filter descriptions work:  filters.push(`owner matches "${ownerFilter}"`);
```

### Step 2 — Add `has_owner` to the tool schema

In the `list-applications` tool definition within `TOOL_DEFINITIONS`, add to `input_schema.properties`:

```typescript
has_owner: {
  type: 'boolean',
  description: 'Filter by owner assignment. true = only applications with an assigned business owner. false = only applications missing a business owner (ownership gaps). Omit to return all.',
},
```

### Step 3 — Extract the filter value in `executeListApplications()`

Near where other filters are extracted (around the `ownerFilter` extraction), add:

```typescript
const hasOwner = input.has_owner !== undefined ? Boolean(input.has_owner) : null;
```

Use `!== undefined` (not truthiness) because `false` is a valid value.

### Step 4 — Apply the filter to the query

In the query building section, after the `ownerFilter` application, add:

```typescript
if (hasOwner === true) {
  query = query.not('owner_name', 'is', null);
} else if (hasOwner === false) {
  query = query.is('owner_name', null);
}
```

**Important:** Use triple-equals checks against `true`/`false`, not truthiness, because `null` means "don't filter."

### Step 5 — Add to filter description

In the section where filter descriptions are built (the `filters.push(...)` block), add:

```typescript
if (hasOwner === true) filters.push('has_owner=yes');
if (hasOwner === false) filters.push('has_owner=no (ownership gaps)');
```

### Step 6 — Verify

```bash
npx tsc --noEmit
```

Must pass with zero errors.

### Step 7 — Commit and push

```bash
cd ~/Dev/getinsync-nextgen-ag
git add supabase/functions/ai-chat/tools.ts
git commit -m "fix: add has_owner filter to AI chat list-applications tool

Adds boolean has_owner parameter to detect ownership gaps.
true = apps with business owner, false = apps missing owner.
Closes Garland audit yellow flag (Slide 5)."
git push -u origin fix/ai-chat-owner-filter
```

### Done criteria checklist

- [ ] `has_owner` property added to `list-applications` input_schema
- [ ] Boolean extraction uses `!== undefined` (not truthiness)
- [ ] Query uses `.is('owner_name', null)` for false and `.not('owner_name', 'is', null)` for true
- [ ] Filter description includes `has_owner` when set
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] No other tools or files modified

### What NOT to do

- Do NOT modify any other tool definition — only `list-applications`
- Do NOT modify the system prompt or tool dispatch logic
- Do NOT add a new tool — this is a filter addition to an existing tool
- Do NOT deploy the Edge Function (Stuart handles deployment via `supabase functions deploy ai-chat`)
- Do NOT touch `index.ts`, `context.ts`, or any other file in `supabase/functions/ai-chat/`
