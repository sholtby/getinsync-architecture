# Session Prompt 02 — Presentation Text Fixes (Doc-Only)

> **Copy everything below the `---` line into a fresh Claude Code session.**
> Prerequisite: None
> Estimated: 10 minutes

---

## Task: Fix two factual inaccuracies in the Garland presentation content

You are starting fresh. Read this entire brief before doing anything.

### Why this work exists

The Garland presentation claim audit found two factual inaccuracies that are simple text fixes — no code changes required. Both are in `docs-architecture/marketing/garland-presentation-content.md`.

### Hard rules

1. **No branch needed** — this file is in the architecture repo (symlinked at `docs-architecture/`), which commits to `main`.
2. **Only modify** `docs-architecture/marketing/garland-presentation-content.md`. No other files.
3. **Make exactly the two changes described below.** Do not rewrite surrounding text or "improve" anything else.

### Step 1 — Read the file

```
docs-architecture/marketing/garland-presentation-content.md
```

Find these two passages:
1. Slide 9, bottom reference line — look for "Technology Product (15 categories)"
2. Slide 6, AI-Augmented Lifecycle Intelligence card — look for "$60K+ per year"

### Step 2 — Fix the Technology Product count

**Find (Slide 9, near bottom):**
```
Technology Product (15 categories)
```

**Replace with:**
```
Technology Product (16 categories)
```

**Why:** Database query confirms 16 active technology product categories, not 15. The categories are: Compute, Operating System, Network, Storage, Database, Data Warehouse, Data Integration, Middleware, Runtime/PaaS, Container/Kubernetes, Identity & Access, Network Security, Data Protection, Web Server, Framework, Language/Runtime.

### Step 3 — Fix the competitor pricing comparison

**Find (Slide 6, AI-Augmented Lifecycle Intelligence card):**
```
Services like Flexera, Snow, and ServiceNow SAM charge $60K+ per year for similar lifecycle intelligence.
```

**Replace with:**
```
Services like Flexera, Snow, and ServiceNow SAM typically charge $20K–$100K+ per year for similar lifecycle intelligence.
```

**Why:** The architecture doc (`features/technology-health/lifecycle-intelligence.md` §2.1) cites: Flexera $20K–100K+, Snow $15K–50K+. "$60K+" cherry-picks a mid-range number. Using the actual range is more defensible if challenged.

### Step 4 — Commit and push

```bash
cd ~/getinsync-architecture
git add marketing/garland-presentation-content.md
git commit -m "docs: fix Tech Product count (16 not 15) and competitor pricing range in Garland deck"
git push origin main
cd ~/Dev/getinsync-nextgen-ag
```

### Done criteria checklist

- [ ] "15 categories" changed to "16 categories" in Slide 9
- [ ] "$60K+" changed to "$20K–$100K+" in Slide 6
- [ ] No other text modified
- [ ] Committed and pushed to architecture repo `main`

### What NOT to do

- Do NOT rewrite or rephrase any other slide content
- Do NOT modify the code repo — this is architecture repo only
- Do NOT create a feature branch — architecture repo uses `main`
