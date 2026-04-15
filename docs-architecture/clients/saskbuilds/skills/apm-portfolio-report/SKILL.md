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

**File storage:** Input files and generated outputs are stored per-ministry under:
```
docs-architecture/clients/saskbuilds/data/<ministry>/
```

---

## Workflow

### Step 0 — Prerequisites

Ensure the following Python and Node packages are installed:

```bash
pip3 install pandas openpyxl matplotlib
npm ls docx || npm install docx
```

### Step 1 — Parse and validate data

```bash
python3 scripts/parse_data.py \
  --curated    "<path to curated .xlsx>" \
  --business   "<path to business fit .csv>" \
  --technical  "<path to technical fit .csv>" \
  --infra      "<path to infrastructure .xlsx>" \
  --out        "<output dir>/ministry_data.json"
```

This script outputs `ministry_data.json`. Review the console output for:
- **Data quality flags** — any applications where scores appear inverted or anomalous
- **Incomplete Data applications** — TIME Category = "Incomplete Data"
- **Crown Jewel applications** — from the infrastructure file
- **Ministry name** — if the Ministry column in the Business Fit CSV is empty, the script sets "Unknown Ministry". Update the JSON manually with the correct ministry name before proceeding.

> ⚠️ If any applications have suspicious score inversions (e.g. a Crown Jewel application in Eliminate with low scores, or a BI/reporting layer in Invest with higher scores than its core system), flag this to the user before proceeding. Document the correction in `ministry_data.json` under `data_quality_notes`.

---

### Step 2 — Generate AI narratives

Read `ministry_data.json` and generate the narrative content for the report. Write narratives directly into the JSON by updating the `narratives` object. Follow these rules:

**APM is the library — it does not prescribe.** All narratives surface insights and open questions. Never use "we recommend," "should," or "must."

**Tone:** Third-person, passive voice for the Abstract. Confident, factual prose for quadrant sections. Written for two audiences simultaneously: the application owner and a steering committee.

**No jargon.** No CSDM terminology. If a technical term must appear, define it on first use.

**Application name handling:**
- Always use the **full data name** from the JSON (e.g., "AQMS - Air Quality Monitoring System"), never a bare acronym alone (e.g., "AQMS")
- The report generator auto-bolds text that matches application names. Bare acronyms will not match and will appear unbolded.
- If an application name in the data uses an acronym without expansion (e.g., "ECRM - ENV" where the suffix is a ministry abbreviation, not a descriptive name), use it as-is — do not fabricate an expansion.
- On first reference in each section, always use the complete data name. For readability in dense passages, abbreviation after first use is acceptable only if the acronym form has also been registered in the auto-bold list.

**Also fill in:** `key_insights` (4 bullet-level portfolio insights for the Snapshot page), `incomplete_apps[].likely_position` and `incomplete_apps[].action`.

**Assessment team assembly:**
- The user provides the assessment team roster (names and ministry affiliations). The four input files may contain partial team data (Application Owner, Who was involved, Architect / SME columns) but this is often incomplete.
- Look up team members on https://www.saskatchewan.ca/government/directory to find job titles and departments. Not all names will be found — use what the directory returns, do not fabricate titles.
- The team is split into two groups in the report:
  - **Assessment Team table** — `program_lead`, `assessment_lead`, `participants` (people who attended sessions), and `ea_advisors` (EA architects and advisors including Stuart Holtby)
  - **Application Owners table** — `owners` listed separately with a note that they were not present during assessment sessions. These are the designated owners of record from the data files.
- Team fields: `program_lead` (string), `assessment_lead` (string), `participants` (array), `ea_advisors` (array), `owners` (array). Format each entry as "Name, Title — Ministry" where title is known.

Generate the following narrative fields (see `references/narrative_schema.md` for field names):

| Field | Content |
|-------|---------|
| `abstract` | Two paragraphs. What was done, how, who, when. Flag any data quality corrections. |
| `snapshot_insight` | One paragraph. What the TIME distribution tells us about THIS ministry — not a generic description of TIME. |
| Per quadrant: `pattern` | What do the apps in this quadrant share? Synthesize from B/T factor data. |
| Per quadrant: `criticality_insight` | Where does TIME position + Criticality score create tension or urgency? Name specific apps only where data makes them notable. |
| `ea_questions` | 3–5 portfolio-wide open questions derived from what the data actually shows. Not generic APM questions. Not leading questions. |
| `next_trigger` | One sentence: when should this portfolio be reassessed? |

**Empty quadrants:** If a quadrant has zero applications, still write a `pattern` narrative explaining the absence and what it implies about the portfolio. Write a `criticality_insight` explaining the consequence (e.g., no managed phase-out candidates).

---

### Step 3 — Generate bubble chart

```bash
python3 scripts/generate_chart.py \
  --data  "<output dir>/ministry_data.json" \
  --out   "<output dir>/time_bubble_chart.png"
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

Legend panel specs:
- **Quadrant key:** Coloured dot + coloured text label (no rectangles — keeps it clean)
- **App list:** Pill-shaped coloured number badge + acronym/short name at ~9.5pt font. Names are extracted from the "ACRONYM - Description" pattern; names without an acronym prefix use the full short name.
- Separator line between quadrant key and app list
- Generous vertical spacing between entries to avoid running together

---

### Step 4 — Generate Word document

```bash
node scripts/generate_report.js \
  --data  "<output dir>/ministry_data.json" \
  --chart "<output dir>/time_bubble_chart.png" \
  --out   "<output dir>/portfolio_report.docx"
```

Then fix duplicate bookmark IDs (docx-js limitation):

```bash
python3 scripts/fix_bookmark_ids.py "<output dir>/portfolio_report.docx"
```

Open the generated `.docx` for the user to review before committing.

---

## Document Structure

| Page | Content |
|------|---------|
| 1 | Portfolio Snapshot: KPI banner (12pt) + bordered bubble chart + TIME distribution table + key insights |
| 2 | Abstract (research paper register) + methodology callout (B1–B10, T01–T14 factor tables) |
| 3 | Table of Contents (table-based, right-aligned page numbers) |
| 4 | Assessment Team (role table + separate Application Owners table) |
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
- `scripts/generate_chart.py` — Parameterised matplotlib bubble chart generator (reads `ministry_data.json`)
- `scripts/generate_chart_template.py` — Legacy hardcoded chart for Energy & Resources (reference only)
- `scripts/generate_report.js` — Parameterised docx-js Word document generator (reads `ministry_data.json` + chart PNG)
- `scripts/generate_report_template.js` — Legacy hardcoded report for Energy & Resources (reference only)
- `scripts/fix_bookmark_ids.py` — Fixes duplicate `w:id` attributes in generated .docx

## Known Issues and Lessons

- **Ministry column empty:** Some ministry CSV exports have the Ministry column present but empty. `parse_data.py` handles this gracefully (defaults to "Unknown Ministry"), but you must manually set the correct ministry name in the JSON before generating narratives.
- **Acronym handling:** The `generate_report.js` auto-bold function (`makeRuns`) matches exact app names from the JSON plus acronym-only forms extracted from the "ACRONYM - Description" pattern. Always use full data names in narratives to ensure consistent bolding.
- **Empty quadrants:** The report generator handles quadrants with zero applications — it still renders the section header, callout box, and pattern narrative. Write a meaningful narrative about why the quadrant is empty.
- **Eliminate table split:** Tables with more than 8 rows are automatically split across pages with a "continued" label.
- **TOC page numbers:** Page numbers in the TOC are estimated based on section count. They may drift by ±1 page for very large or very small portfolios. Word's built-in TOC update can correct this after opening.
- **Word caching:** When regenerating the `.docx` to the same filename, Word/Pages may serve the cached old version. Copy to a new filename (e.g., `_v2.docx`) to force a fresh open, or close the old document first.
- **SK Gov directory lookups:** Not all government employees appear in the public directory at https://www.saskatchewan.ca/government/directory. WebFetch on directory person pages sometimes returns the wrong person due to page redirect behaviour — verify names against the returned content. Use WebSearch with `site:saskatchewan.ca/government/directory "Full Name"` to find the direct URL first.
- **Team data from input files is incomplete:** The Business Fit CSV `Who was involved` and `Application Owner` columns contain partial team data. The user must supply the full assessment team roster separately. Application owners extracted from the CSV are owners of record, not necessarily assessment participants.
