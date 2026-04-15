# ministry_data.json — Full Schema

This file is produced by `parse_data.py` and consumed by `generate_chart.py` and `generate_report.js`. Claude fills in the `narratives`, `team`, `data_quality_notes`, `key_insights`, and `ea_questions` fields after parsing.

---

## Top-Level Structure

```json
{
  "ministry": "string — derived from Business Fit CSV Ministry column",
  "assessment_period": "string — e.g. 'Feb–Mar 2026', derived from Modified dates",
  "report_date": "string — e.g. 'April 2026', for footer",
  "total_apps": "integer — all non-blank, non-metadata rows in curated XLSX",
  "assessed_apps": "integer — rows where TIME Category is not 'Incomplete Data'",
  "incomplete_count": "integer — rows where TIME Category is 'Incomplete Data'",

  "apps": [ /* see App Object below */ ],

  "team": {
    "program_lead": "string",
    "assessment_lead": "string",
    "owners": ["string"],
    "architects": ["string — append † if first name only"],
    "advisor": "string"
  },

  "data_quality_notes": [
    "string — one entry per identified data issue, e.g. inverted scores"
  ],

  "key_insights": [
    "string — 4 bullet-level insights for the Portfolio Snapshot page"
  ],

  "narratives": {
    "abstract": "string — two prose paragraphs",
    "snapshot_insight": "string — one prose paragraph about THIS ministry's distribution",

    "invest": {
      "pattern": "string — prose paragraph synthesizing B/T factor patterns",
      "criticality_insight": "string — prose paragraph on urgency/protection"
    },
    "modernize": {
      "pattern": "string",
      "criticality_insight": "string"
    },
    "tolerate": {
      "pattern": "string",
      "criticality_insight": "string"
    },
    "eliminate": {
      "pattern": "string",
      "criticality_insight": "string — name specific apps where criticality creates tension"
    },

    "ea_questions": [
      "string — 3 to 5 portfolio-wide open questions"
    ],

    "next_trigger": "string — one sentence suggested trigger for next review"
  },

  "incomplete_apps": [
    {
      "name": "string",
      "business_fit": "number or null",
      "criticality": "number or null",
      "tech_fit": "number or null",
      "lifecycle": "string or null",
      "likely_position": "string — e.g. 'Invest or Modernize based on scores'",
      "action": "string — what the EA team needs to do"
    }
  ]
}
```

---

## App Object

```json
{
  "num": "integer — sequential index, sorted alphabetically",
  "name": "string — full application name",
  "time_category": "Invest | Modernize | Tolerate | Eliminate | Incomplete Data",
  "criticality": "number",
  "business_fit": "number",
  "tech_fit": "number or null",
  "lifecycle": "string",
  "crown_jewel": "boolean",
  "owner": "string or null",
  "assessors": ["string"],
  "architect": "string or null",
  "itsm_incidents": "number or null — 24-month count from infra file",
  "itsm_requests": "number or null",
  "itsm_problems": "number or null"
}
```

---

## Derivation Rules

| Field | Source | Rule |
|-------|--------|------|
| `ministry` | Business Fit CSV, Ministry column | First non-null value |
| `assessment_period` | Both CSVs, Modified column | Earliest → Latest month/year range |
| `report_date` | Derived from latest Modified date | Format as "Month YYYY" |
| `total_apps` | Curated XLSX | Count of non-blank, non-metadata rows |
| `assessed_apps` | Curated XLSX | Rows where TIME Category ≠ "Incomplete Data" |
| `num` | Derived | Sort apps alphabetically, assign 1..N |
| `crown_jewel` | Infrastructure XLSX | True if Crown Jewel column = "Yes" |
| `itsm_*` | Infrastructure XLSX | Sum across duplicate rows for same app |

---

## Data Quality Check

Before generating narratives, check for:

1. **Score inversions:** If a Crown Jewel application is in Eliminate, or a core operational system scores lower than its BI/reporting layer, flag and correct.
2. **Boundary cases:** Apps within 5 points of the 50-point threshold on either axis — note in narrative.
3. **Missing tech scores:** Apps with no Technical Fit Score are Incomplete Data regardless of TIME Category.
4. **Lifecycle anomalies:** Non-standard lifecycle values (e.g. "ITDNAS-End-Of-Life", "Business/Vendor Managed") — preserve as-is, note in narrative where relevant.
