# Section 6h: User Documentation — Write It Now

**Extracted from:** `operations/session-end-checklist.md`
**When:** Any session that added or changed user-facing behavior (new screens, changed workflows, renamed labels, new features, changed permissions).

**Philosophy:** If you just shipped the feature, you have full context on how it works *right now*. Deferring doc updates to a future session means that session has to re-explore the feature from scratch — which rarely happens. Write the docs while the context is fresh.

---

## 6h.1 — Did This Session Change User-Facing Behavior?

If YES to any of these, user documentation **must** be updated this session:
- New screen, tab, or page added
- Existing workflow changed (button moved, steps reordered, new modal)
- Labels, terminology, or tooltips changed
- Permission gating changed (who sees what)
- New feature visible to end users
- Error messages or empty states changed

If NO to all → skip this section.

---

## 6h.2 — Determine Scope

| Tier | Change Scope | Example | Action |
|------|-------------|---------|--------|
| **Minor** | Label rename, tooltip tweak, icon swap | Changed "Email" to "Work Email" | Add a one-liner to the relevant existing guide |
| **Moderate** | New section on existing screen, new modal, workflow change | Added photo upload to Profile Settings | Add/update the relevant section in the existing guide (a few paragraphs) |
| **Major** | Entirely new screen, entirely new workflow | New "Standards" tab | Create a new guide file in `guides/user-help/`, add to guide index below |

---

## 6h.3 — Find the Right Guide

**User help guides** (`docs-architecture/guides/user-help/`):

| Guide | Covers |
|-------|--------|
| `getting-started.md` | Onboarding, key concepts, first 5 minutes, navigation, profile settings |
| `assessment-guide.md` | Business + technical assessment, scoring, TIME/PAID |
| `time-framework.md` | TIME quadrant explanation |
| `paid-framework.md` | PAID quadrant explanation |
| `tech-health.md` | Technology health dashboard, lifecycle, KPI cards |
| `deployment-profiles.md` | What deployment profiles are, how to create |
| `roadmap-initiatives.md` | Creating and managing initiatives |
| `integrations.md` | Managing application integrations |
| `ai-assistant.md` | Portfolio AI Assistant chat, data scope, tips |

**Other guides** (`docs-architecture/guides/`):

| Guide | Covers |
|-------|--------|
| `feature-walkthrough.md` | Screen-by-screen reference for enterprise architects, CSDM mapping |
| `whats-new.md` | User-facing release changelog — append entry for every user-visible change |
| `user-documentation/technology-health-badges.md` | Badge status reference (lifecycle + conformance colors) |

If no existing guide covers the area → create a new guide (Major tier).

---

## 6h.4 — Write the Update

**For Minor/Moderate changes (update existing guide):**
1. Read the relevant guide file
2. Find the section closest to the changed behavior
3. Update or add content to match what was built
4. Keep the guide's existing tone and structure
5. Commit the updated guide to the architecture repo

**For Major changes (new guide):**
1. Create a new file in `docs-architecture/guides/user-help/`
2. Follow the structure of existing guides (title, overview, step-by-step, tips)
3. Add the new guide to the table in §6h.3 above (edit this file)
4. Update `MANIFEST.md` with the new guide
5. Commit to the architecture repo

**For Moderate/Major changes — also check the feature walkthrough:**
- If the change affects a screen covered by `guides/feature-walkthrough.md`, update the relevant section of the walkthrough to match.

**Always — What's New entry:**
- Append a dated entry to `guides/whats-new.md` for every user-visible change, regardless of tier.
- Format: `- **Feature Name** — One-line description.`
- Group entries under the current date heading, or create a new date heading if none exists for today.

**Writing guidelines:**
- Write for end users, not developers — no code, no schema references
- Use plain language — the audience may not be technical
- Include what the feature does, how to use it, and any limitations
- Only document what is confirmed working — do not document features that depend on unfinished setup (note those as "coming soon" if relevant)

---

## 6h.5 — Guard Rail: Unfinished Dependencies

If a feature depends on external setup that Stuart hasn't completed yet (e.g., a third-party integration, a storage bucket), document the feature but note the dependency clearly:
- Document the UI and workflow as built
- Note "Requires [X] to be configured — contact your administrator" where applicable
- Do NOT skip documentation entirely because of a dependency

---

## 6h.6 — Version Bump (CalVer)

If this session shipped user-visible features to production, bump `version` in `package.json` using CalVer format `YYYY.MM.patch`:
- **New month?** → `YYYY.MM.1`
- **Same month, another release?** → increment patch (e.g. `2026.3.1` → `2026.3.2`)
- **No user-visible changes?** → no bump

The version is displayed at the bottom of the Profile Settings page (`GetInSync v{version}`).
