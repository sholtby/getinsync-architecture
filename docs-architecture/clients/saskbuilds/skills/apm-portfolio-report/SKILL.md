---
name: apm-portfolio-report
description: >
  Generate a formatted, multi-page Word document (.docx) Application Portfolio
  TIME Assessment report for a government ministry, from four standardized input
  files. Use this skill whenever the user uploads APM assessment data files and
  asks for a portfolio report, assessment summary, TIME report, or handoff
  document — even if they just say "generate the report" or "build the
  portfolio doc". Also triggers when the user mentions ministry application
  assessments, TIME quadrant reports, or APM-to-EA handoff documents.
  Always use this skill before attempting to write report code from scratch.
---

# APM Portfolio TIME Assessment Report

Generates a two-part Word document from four standardized APM input files:

- **Part 1 (pages 1–2):** Portfolio Snapshot (bubble chart + KPIs + insights) and Abstract (methodology)
- **Part 2 (pages 3+):** Table of Contents → Assessment Team → one section per TIME quadrant → Incomplete Data → EA Handoff

---

## Input Files

| File | Type | Role |
|------|------|------|
| Curated Assessment Summary | `.xlsx` | **Authoritative.** Defines the assessed population: Application Name, Lifecycle Status, TIME Category, Criticality Fit Score, Business Fit Score, Technical Fit Score. Ignore blank rows and Power BI filter metadata rows. |
| Business Fit Assessment | `.csv` | Enrichment: B1–B10 factor responses, Application Owner, Who was involved, Modified date |
| Technical Fit Assessment | `.csv` | Enrichment: T01–T14 factor responses, Architect / SME |
| Infrastructure & Lifecycle Report | `.xlsx` | Supplementary: server/OS/DB/Web lifecycle stages, Crown Jewel flag, 24-month ITSM counts |

**Join rule:** Curated XLSX defines scope. Join other files on Application Name (exact match). If no match, omit — do not fabricate.

---

## Workflow

### Step 1 — Parse and validate data

```bash
python3 scripts/parse_data.py \
  --curated    "<path to curated .xlsx>" \
  --business   "<path to business fit .csv>" \
  --technical  "<path to technical fit .csv>" \
  --infra      "<path to infrastructure .xlsx>" \
  --out        /home/claude/ministry_data.json
```

This script outputs `ministry_data.json`. Review the console output for:
- **Data quality flags** — any applications where scores appear inverted or anomalous
- **Incomplete Data applications** — TIME Category = "Incomplete Data"
- **Crown Jewel applications** — from the infrastructure file

> ⚠️ If any applications have suspicious score inversions (e.g. a Crown Jewel application in Eliminate with low scores, or a BI/reporting layer in Invest with higher scores than its core system), flag this to the user before proceeding. Document the correction in `ministry_data.json` under `data_quality_notes`.

---

### Step 2 — Generate AI narratives

Read `ministry_data.json` and generate the narrative content for the report. Write narratives directly into the JSON by updating the `narratives` object. Follow these rules:

**APM is the library — it does not prescribe.** All narratives surface insights and open questions. Never use "we recommend," "should," or "must."

**Tone:** Third-person, passive voice for the Abstract. Confident, factual prose for quadrant sections. Written for two audiences simultaneously: the application owner and a steering committee.

**No jargon.** No CSDM terminology. If a technical term must appear, define it on first use.

Generate the following narrative fields (see `references/narrative_schema.md` for field names):

| Field | Content |
|-------|---------|
| `abstract` | Two paragraphs. What was done, how, who, when. Flag any data quality corrections. |
| `snapshot_insight` | One paragraph. What the TIME distribution tells us about THIS ministry — not a generic description of TIME. |
| Per quadrant: `pattern` | What do the apps in this quadrant share? Synthesize from B/T factor data. |
| Per quadrant: `criticality_insight` | Where does TIME position + Criticality score create tension or urgency? Name specific apps only where data makes them notable. |
| `ea_questions` | 3–5 portfolio-wide open questions derived from what the data actually shows. Not generic APM questions. Not leading questions. |

---

### Step 3 — Generate bubble chart

```bash
python3 scripts/generate_chart.py \
  --data  /home/claude/ministry_data.json \
  --out   /home/claude/time_bubble_chart.png
```

Chart specs:
- X-axis: Business Fit Score (0–100), threshold at 50
- Y-axis: Technical Fit Score (0–100), threshold at 50
- Bubble size: proportional to Criticality score
- Bubble colour: Invest=green, Modernize=amber, Tolerate=purple, Eliminate=red
- Numbered bubbles (1–N, sorted alphabetically) with indexed legend panel on the right
- Quadrant colour fills (light tints), quadrant labels at corners
- Note at centre-bottom: "● Bubble size = Criticality score"
- Title bar: "{Ministry} — Application Portfolio TIME Assessment"

---

### Step 4 — Generate Word document

```bash
node scripts/generate_report.js \
  --data  /home/claude/ministry_data.json \
  --chart /home/claude/time_bubble_chart.png \
  --out   /home/claude/portfolio_report.docx
```

Then fix duplicate bookmark IDs (docx-js limitation):

```bash
python3 scripts/fix_bookmark_ids.py /home/claude/portfolio_report.docx
python3 scripts/validate_docx.py    /home/claude/portfolio_report.docx
```

Copy to outputs:

```bash
cp /home/claude/portfolio_report.docx /mnt/user-data/outputs/
cp /home/claude/time_bubble_chart.png /mnt/user-data/outputs/
```

---

## Document Structure

| Page | Content |
|------|---------|
| 1 | Portfolio Snapshot: KPI banner (12pt) + bordered bubble chart + TIME distribution table + key insights |
| 2 | Abstract (research paper register) + methodology callout (B1–B10, T01–T14 factor tables) |
| 3 | Table of Contents (table-based, right-aligned page numbers) |
| 4 | Assessment Team (organised by role) |
| 5 | INVEST section |
| 6 | MODERNIZE section |
| 7 | TOLERATE section |
| 8–9 | ELIMINATE section (table split at ~8 rows, "continued" label on page 9) |
| 10 | Incomplete Data (one card per app) |
| 11 | EA Handoff (numbered open questions + trigger callout) |

**Each quadrant section contains:**
1. Coloured section header bar
2. "What is [Quadrant]?" callout box (Gartner definition, using "Modernize" not "Migrate")
3. Pattern Narrative (prose, synthesized from factor data)
4. Applications — Ranked by Criticality table (★ Crown Jewel note only if applicable)
5. Criticality-Weighted Insight (prose)

---

## Formatting Rules

- **Header:** Navy bar on every page — Ministry name (bold) + "Application Portfolio TIME Assessment" subtitle
- **Footer:** Left = "Application Portfolio Assessment" | Centre = page number | Right = report month/year
- **Spacer:** Add one `spacer()` paragraph after every `pageBreak()` to prevent tables from running into the header
- **Crown Jewel note:** Render only when at least one app in the table has `crown_jewel: true`
- **App names in body text:** Auto-bold using `makeRuns()` helper; plain weight in tables
- **Blank lines:** Remove explicit gap paragraphs; rely on paragraph `spacing.before/after`
- **Table split (Eliminate):** Split at ~8 data rows so the first segment fits on one page. Add `spacer()` + "continued" h3 before the second segment
- **Incomplete Data apps:** Do not assess or position them. Card format only. Flag as open item.

---

## Colour Reference

| Quadrant | Header | Row bg |
|----------|--------|--------|
| INVEST | `059669` | `DCFCE7` |
| MODERNIZE | `D97706` | `FEF3C7` |
| TOLERATE | `7C3AED` | `EDE9FE` |
| ELIMINATE | `DC2626` | `FEE2E2` |
| Navy (header/TOC) | `1B365D` | `EBF2FA` |

---

## Reference Files

- `references/narrative_schema.md` — Full JSON schema for `ministry_data.json` including the `narratives` object field names
- `references/factor_labels.md` — Canonical B1–B10 and T01–T14 factor names and descriptions
- `scripts/parse_data.py` — Reads the four input files, validates, outputs `ministry_data.json`
- `scripts/generate_chart.py` — Parameterised matplotlib bubble chart generator
- `scripts/generate_report.js` — Parameterised docx-js Word document generator
- `scripts/fix_bookmark_ids.py` — Fixes duplicate `w:id` attributes in generated .docx
- `scripts/validate_docx.py` — Validates the generated .docx before presenting to user
