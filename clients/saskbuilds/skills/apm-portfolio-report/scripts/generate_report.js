#!/usr/bin/env node
/**
 * generate_report.js — APM Portfolio Report: Word Document Generator
 *
 * Reads ministry_data.json + bubble chart PNG and produces a formatted .docx report.
 *
 * Usage:
 *   node generate_report.js --data ministry_data.json --chart time_bubble_chart.png --out report.docx
 */

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageBreak, ImageRun, Header, Footer, PageNumber,
  TabStopType, TabStopPosition, Bookmark, InternalHyperlink
} = require('docx');
const fs = require('fs');
const path = require('path');

// ─── CLI ARGS ───────────────────────────────────────────────────────────────
const args = {};
process.argv.slice(2).forEach((a, i, arr) => {
  if (a.startsWith('--')) args[a.slice(2)] = arr[i + 1];
});
if (!args.data || !args.chart || !args.out) {
  console.error('Usage: node generate_report.js --data <json> --chart <png> --out <docx>');
  process.exit(1);
}

const data = JSON.parse(fs.readFileSync(args.data, 'utf-8'));
const chartImg = fs.readFileSync(args.chart);

// ─── CONSTANTS ──────────────────────────────────────────────────────────────
const NAVY       = "1B365D";
const NAVY_LIGHT = "2A4A7F";
const LIGHT_BLUE = "EBF2FA";
const MID_GRAY   = "CBD5E1";
const WHITE      = "FFFFFF";
const DARK       = "1E293B";
const SLATE      = "475569";
const ELIM_BG    = "FEE2E2";
const MOD_BG     = "FEF3C7";
const INV_BG     = "DCFCE7";
const TOL_BG     = "EDE9FE";
const INC_BG     = "F1F5F9";
const ELIM_HDR   = "DC2626";
const MOD_HDR    = "D97706";
const INV_HDR    = "059669";
const TOL_HDR    = "7C3AED";
const W          = 9360;

const border    = { style: BorderStyle.SINGLE, size: 1, color: MID_GRAY };
const borders   = { top: border, bottom: border, left: border, right: border };
const noBorder  = { style: BorderStyle.NONE, size: 0, color: WHITE };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const thickBot  = { top: noBorder, bottom: { style: BorderStyle.THICK, size: 6, color: NAVY }, left: noBorder, right: noBorder };
const imgBorder = { style: BorderStyle.SINGLE, size: 6, color: MID_GRAY };
const imgBorders = { top: imgBorder, bottom: imgBorder, left: imgBorder, right: imgBorder };

// ─── APPLICATION NAMES FOR AUTO-BOLD ────────────────────────────────────────
// Build auto-bold list: full names + acronym-only forms (extracted from "ACRONYM - Description" pattern)
const fullNames = data.apps.map(a => a.name);
const acronymForms = data.apps
  .map(a => a.name.match(/^([A-Za-z]+)\s*-\s*.+/))
  .filter(Boolean)
  .map(m => m[1]);
const APP_NAMES = [...new Set([...fullNames, ...acronymForms])]
  .sort((a, b) => b.length - a.length); // longest first to avoid partial matches

function makeRuns(text, baseSize = 22) {
  const runs = [];
  let remaining = text;
  while (remaining.length > 0) {
    let foundAt = -1, foundName = null;
    for (const name of APP_NAMES) {
      const idx = remaining.indexOf(name);
      if (idx !== -1 && (foundAt === -1 || idx < foundAt)) { foundAt = idx; foundName = name; }
    }
    if (foundAt === -1) {
      runs.push(new TextRun({ text: remaining, size: baseSize, font: "Arial", color: DARK }));
      break;
    }
    if (foundAt > 0) runs.push(new TextRun({ text: remaining.slice(0, foundAt), size: baseSize, font: "Arial", color: DARK }));
    runs.push(new TextRun({ text: foundName, size: baseSize, font: "Arial", color: DARK, bold: true }));
    remaining = remaining.slice(foundAt + foundName.length);
  }
  return runs;
}

// ─── HELPERS ────────────────────────────────────────────────────────────────
const sp = (before = 0, after = 160) => ({ before, after });

function h1(text, id) {
  const run = new TextRun({ text, bold: true, size: 28, font: "Arial", color: NAVY });
  return new Paragraph({
    heading: HeadingLevel.HEADING_1, spacing: sp(240, 160),
    children: id ? [new Bookmark({ id, children: [run] })] : [run]
  });
}

function h2(text, color = NAVY_LIGHT, id) {
  const run = new TextRun({ text, bold: true, size: 24, font: "Arial", color });
  return new Paragraph({
    heading: HeadingLevel.HEADING_2, spacing: sp(200, 100),
    children: id ? [new Bookmark({ id, children: [run] })] : [run]
  });
}

function h3(text, color = DARK) {
  return new Paragraph({
    spacing: sp(160, 80),
    children: [new TextRun({ text, bold: true, size: 22, font: "Arial", color })]
  });
}

function body(text) {
  return new Paragraph({ spacing: sp(0, 160), children: makeRuns(text) });
}

function italic(text) {
  return new Paragraph({
    spacing: sp(0, 80),
    children: [new TextRun({ text, size: 20, font: "Arial", italics: true, color: SLATE })]
  });
}

function spacer() {
  return new Paragraph({ spacing: sp(100, 0), children: [new TextRun("")] });
}

function pageBreak() { return new Paragraph({ children: [new PageBreak()] }); }

function ruled() {
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: [W],
    rows: [new TableRow({ children: [new TableCell({
      borders: thickBot, width: { size: W, type: WidthType.DXA },
      children: [new Paragraph({ children: [new TextRun("")] })]
    })]})]
  });
}

function calloutBox(children, bg = LIGHT_BLUE, borderColor = NAVY) {
  const b = { style: BorderStyle.SINGLE, size: 4, color: borderColor };
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: [W],
    rows: [new TableRow({ children: [new TableCell({
      borders: { top: b, bottom: b, left: b, right: b },
      shading: { fill: bg, type: ShadingType.CLEAR },
      margins: { top: 160, bottom: 160, left: 200, right: 200 },
      width: { size: W, type: WidthType.DXA }, children
    })]})]
  });
}

function sectionHeader(label, bg, textColor = WHITE) {
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: [W],
    rows: [new TableRow({ children: [new TableCell({
      borders: noBorders, shading: { fill: bg, type: ShadingType.CLEAR },
      margins: { top: 140, bottom: 140, left: 200, right: 200 },
      width: { size: W, type: WidthType.DXA },
      children: [new Paragraph({ children: [new TextRun({ text: label, bold: true, size: 26, font: "Arial", color: textColor })] })]
    })]})]
  });
}

function appTable(apps, bgColor, accentColor) {
  const hdrs = ["#", "Application Name", "Criticality", "Business Fit", "Tech Fit", "Lifecycle Status"];
  const cols = [480, 3280, 1000, 1000, 1000, 2600];
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: cols,
    rows: [
      new TableRow({
        tableHeader: true,
        children: hdrs.map((h, i) => new TableCell({
          borders, shading: { fill: accentColor, type: ShadingType.CLEAR },
          width: { size: cols[i], type: WidthType.DXA },
          margins: { top: 80, bottom: 80, left: 100, right: 100 },
          children: [new Paragraph({ alignment: i > 1 ? AlignmentType.CENTER : AlignmentType.LEFT, children: [new TextRun({ text: h, bold: true, size: 18, font: "Arial", color: WHITE })] })]
        }))
      }),
      ...apps.map((app, idx) => new TableRow({ children: [
        new TableCell({ borders, shading: { fill: idx % 2 === 0 ? bgColor : WHITE, type: ShadingType.CLEAR }, width: { size: cols[0], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: String(app.num), bold: true, size: 18, font: "Arial", color: accentColor })] })] }),
        new TableCell({ borders, shading: { fill: idx % 2 === 0 ? bgColor : WHITE, type: ShadingType.CLEAR }, width: { size: cols[1], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ children: [new TextRun({ text: app.name + (app.crown_jewel ? "  \u2605" : ""), size: 18, font: "Arial", color: DARK })] })] }),
        ...["criticality", "business_fit", "tech_fit"].map((k, ci) => new TableCell({ borders, shading: { fill: idx % 2 === 0 ? bgColor : WHITE, type: ShadingType.CLEAR }, width: { size: cols[ci + 2], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: app[k] != null ? String(app[k]) : "N/A", size: 18, font: "Arial", color: DARK })] })] })),
        new TableCell({ borders, shading: { fill: idx % 2 === 0 ? bgColor : WHITE, type: ShadingType.CLEAR }, width: { size: cols[5], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ children: [new TextRun({ text: app.lifecycle || "Unknown", size: 18, font: "Arial", color: DARK })] })] }),
      ]}))
    ]
  });
}

function tocRow(label, anchor, pageNum, isHeader = false) {
  const rowBorder = { style: BorderStyle.NONE, size: 0, color: WHITE };
  const bottomLine = { style: BorderStyle.DOTTED, size: 1, color: MID_GRAY };
  return new TableRow({
    children: [
      new TableCell({
        borders: { top: rowBorder, bottom: bottomLine, left: rowBorder, right: rowBorder },
        width: { size: 7800, type: WidthType.DXA },
        margins: { top: 80, bottom: 80, left: 0, right: 0 },
        children: [new Paragraph({
          spacing: sp(60, 60),
          children: [new InternalHyperlink({ anchor, children: [
            new TextRun({ text: label, size: isHeader ? 22 : 20, font: "Arial", color: NAVY, bold: isHeader })
          ]})]
        })]
      }),
      new TableCell({
        borders: { top: rowBorder, bottom: bottomLine, left: rowBorder, right: rowBorder },
        width: { size: 1560, type: WidthType.DXA },
        margins: { top: 80, bottom: 80, left: 0, right: 0 },
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          spacing: sp(60, 60),
          children: [new TextRun({ text: pageNum, size: 20, font: "Arial", color: SLATE })]
        })]
      }),
    ]
  });
}

// ─── DATA PREPARATION ───────────────────────────────────────────────────────
const ministry = data.ministry;
const narr = data.narratives;
const team = data.team;
const assessedApps = data.apps.filter(a => a.time_category !== 'Incomplete Data');

// Group by TIME category, sorted by criticality descending
function quadrantApps(cat) {
  return assessedApps.filter(a => a.time_category === cat).sort((a, b) => (b.criticality || 0) - (a.criticality || 0));
}

const investApps = quadrantApps('Invest');
const modernizeApps = quadrantApps('Modernize');
const tolerateApps = quadrantApps('Tolerate');
const eliminateApps = quadrantApps('Eliminate');

// Split eliminate at 8 rows if needed
const elimSplit = eliminateApps.length > 8 ? 8 : eliminateApps.length;
const eliminateApps1 = eliminateApps.slice(0, elimSplit);
const eliminateApps2 = eliminateApps.slice(elimSplit);

// Distribution stats
const distMap = {};
assessedApps.forEach(a => { distMap[a.time_category] = (distMap[a.time_category] || 0) + 1; });
function pct(cat) { return distMap[cat] ? Math.round(distMap[cat] / data.assessed_apps * 100) + '%' : '0%'; }
function cnt(cat) { return String(distMap[cat] || 0); }

// ─── CHART IMAGE ────────────────────────────────────────────────────────────
const chartW = 608, chartH = Math.round(608 / 1.79);

// ─── HEADER & FOOTER ────────────────────────────────────────────────────────
function makeHeader() {
  return new Header({
    children: [
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [W], rows: [
          new TableRow({
            children: [new TableCell({
              borders: noBorders,
              shading: { fill: NAVY, type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 200, right: 200 },
              width: { size: W, type: WidthType.DXA },
              children: [
                new Paragraph({ spacing: sp(0, 40), children: [new TextRun({ text: ministry.toUpperCase(), bold: true, size: 26, font: "Arial", color: WHITE })] }),
                new Paragraph({ spacing: sp(0, 0), children: [new TextRun({ text: "Application Portfolio  TIME  Assessment", size: 18, font: "Arial", color: "B0C4D8" })] }),
              ]
            })]
          })]
      })
    ]
  });
}

function makeFooter() {
  return new Footer({
    children: [
      new Paragraph({
        tabStops: [
          { type: TabStopType.CENTER, position: Math.round(W / 2) },
          { type: TabStopType.RIGHT, position: W },
        ],
        border: { top: { style: BorderStyle.SINGLE, size: 4, color: MID_GRAY } },
        spacing: sp(80, 0),
        children: [
          new TextRun({ text: "Application Portfolio Assessment", size: 18, font: "Arial", color: SLATE }),
          new TextRun({ text: "\t", size: 18, font: "Arial" }),
          new TextRun({ children: [PageNumber.CURRENT], size: 18, font: "Arial", color: SLATE }),
          new TextRun({ text: "\t", size: 18, font: "Arial" }),
          new TextRun({ text: data.report_date, size: 18, font: "Arial", color: SLATE }),
        ]
      })
    ]
  });
}

// ─── QUADRANT DEFINITIONS ───────────────────────────────────────────────────
const QUADRANT_DEFS = {
  Invest: "Applications in the Invest quadrant demonstrate high business fit and strong technical health. They are core to operational delivery and are built on sustainable, modern platforms. Continued investment in maintenance, enhancement, and capability growth is warranted. These applications represent the portfolio's highest-value digital assets and carry the greatest risk if disrupted or allowed to decline.",
  Modernize: "Applications in the Modernize quadrant deliver meaningful business value but are constrained by aging or inadequate technical foundations. The business case for continued use is present; however, the platform, infrastructure, or development environment has not kept pace with organizational needs or current standards. Re-platforming, upgrading, or transitioning to modern alternatives is indicated. SaskBuilds uses 'Modernize' in place of Gartner's original 'Migrate' designation to reflect the broader range of renewal approaches applicable in a government context.",
  Tolerate: "Applications in the Tolerate quadrant exhibit adequate technical health but deliver limited strategic business value. These systems continue to function reliably but are not aligned with the organization's core mandate or growth priorities. The appropriate posture is to maintain as-is, limit further investment, and monitor for a natural exit or replacement opportunity. Tolerate applications are often candidates for consolidation as the broader portfolio evolves.",
  Eliminate: "Applications in the Eliminate quadrant provide limited business value and are built on aging or unsupported platforms. They have aged past their operational relevance on both dimensions simultaneously. Planning for retirement, consolidation, or replacement is appropriate. The Criticality score determines urgency: low-criticality applications are candidates for near-term retirement, while moderate-criticality applications require sequenced exit planning to manage operational dependencies.",
};

// ─── BUILD QUADRANT SECTION ─────────────────────────────────────────────────
function buildQuadrantSection(catName, apps, bgColor, hdrColor, narrKey, bookmark) {
  const n = narr[narrKey];
  if (!apps.length && !n.pattern) {
    // Empty quadrant
    return [
      spacer(),
      sectionHeader(catName.toUpperCase(), hdrColor),
      calloutBox([
        new Paragraph({ spacing: sp(0, 80), children: [new TextRun({ text: `What is ${catName}?`, bold: true, size: 20, font: "Arial", color: hdrColor })] }),
        new Paragraph({ spacing: sp(0, 0), children: [new TextRun({ text: QUADRANT_DEFS[catName], size: 20, font: "Arial", italics: true, color: DARK })] }),
      ], bgColor, hdrColor),
      h2("Pattern Narrative", hdrColor, bookmark),
      body(n.pattern || `No applications were positioned in the ${catName} quadrant.`),
      ...(n.criticality_insight ? [h3("Criticality-Weighted Insight"), body(n.criticality_insight)] : []),
    ];
  }

  const elements = [
    spacer(),
    sectionHeader(catName.toUpperCase(), hdrColor),
    calloutBox([
      new Paragraph({ spacing: sp(0, 80), children: [new TextRun({ text: `What is ${catName}?`, bold: true, size: 20, font: "Arial", color: hdrColor })] }),
      new Paragraph({ spacing: sp(0, 0), children: [new TextRun({ text: QUADRANT_DEFS[catName], size: 20, font: "Arial", italics: true, color: DARK })] }),
    ], bgColor, hdrColor),
    h2("Pattern Narrative", hdrColor, bookmark),
    body(n.pattern),
    h3("Applications \u2014 Ranked by Criticality"),
  ];

  if (apps.some(a => a.crown_jewel)) {
    elements.push(italic("\u2605 denotes Crown Jewel designation"));
  }

  if (catName === 'Eliminate' && eliminateApps2.length > 0) {
    elements.push(appTable(eliminateApps1, bgColor, hdrColor));
    elements.push(spacer());
    elements.push(h3("Applications \u2014 Ranked by Criticality (continued)", hdrColor));
    elements.push(appTable(eliminateApps2, bgColor, hdrColor));
  } else {
    elements.push(appTable(apps, bgColor, hdrColor));
  }

  elements.push(h3("Criticality-Weighted Insight"));
  elements.push(body(n.criticality_insight));

  return elements;
}

// ─── INCOMPLETE DATA SECTION ────────────────────────────────────────────────
function buildIncompleteSection() {
  const elements = [
    spacer(),
    h1("Incomplete Data", "incomplete"),
    ruled(),
    body(`${data.incomplete_count} application${data.incomplete_count !== 1 ? 's' : ''} could not be fully positioned in the TIME model due to incomplete assessment data. ${data.incomplete_count !== 1 ? 'These applications are' : 'This application is'} not included in the quadrant analysis above and require${data.incomplete_count !== 1 ? '' : 's'} a follow-up assessment session before ${data.incomplete_count !== 1 ? 'they' : 'it'} can be incorporated into portfolio planning.`),
  ];

  for (const app of data.incomplete_apps) {
    elements.push(h2(app.name, NAVY_LIGHT));
    const rows = [
      ["Business Fit Score", app.business_fit != null ? String(app.business_fit) : "Not assessed"],
      ["Criticality Score", app.criticality != null ? String(app.criticality) : "Not assessed"],
      ["Technical Fit Score", app.tech_fit != null ? String(app.tech_fit) : "Not assessed"],
      ["Lifecycle Status", app.lifecycle || "Unknown"],
      ["TIME Position", app.likely_position || "Cannot be determined"],
      ["Action Required", app.action || "Complete assessment"],
    ];
    elements.push(new Table({
      width: { size: W, type: WidthType.DXA }, columnWidths: [2600, 6760],
      rows: rows.map(([k, v], i) =>
        new TableRow({
          children: [
            new TableCell({ borders, shading: { fill: i % 2 === 0 ? INC_BG : WHITE, type: ShadingType.CLEAR }, width: { size: 2600, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: k, bold: true, size: 18, font: "Arial", color: NAVY })] })] }),
            new TableCell({ borders, shading: { fill: i % 2 === 0 ? INC_BG : WHITE, type: ShadingType.CLEAR }, width: { size: 6760, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: v, size: 18, font: "Arial", color: DARK })] })] }),
          ]
        })
      )
    }));
  }

  return elements;
}

// ─── EA HANDOFF SECTION ─────────────────────────────────────────────────────
function buildHandoffSection() {
  const elements = [
    spacer(),
    h1("EA Handoff \u2014 Open Questions", "handoff"),
    ruled(),
    body("The following questions are surfaced by the assessment data. They are portfolio-wide observations intended to frame the EA team's planning conversations. APM collects data and provides insights \u2014 it does not make decisions or prescribe outcomes."),
  ];

  narr.ea_questions.forEach(q => {
    elements.push(new Paragraph({
      numbering: { reference: "numbers", level: 0 },
      spacing: sp(120, 120),
      children: makeRuns(q)
    }));
  });

  elements.push(calloutBox([
    new Paragraph({ spacing: sp(0, 80), children: [new TextRun({ text: "Suggested Next Assessment Trigger", bold: true, size: 20, font: "Arial", color: NAVY })] }),
    new Paragraph({ spacing: sp(0, 0), children: [new TextRun({ text: narr.next_trigger, size: 20, font: "Arial", italics: true, color: DARK })] }),
  ]));

  return elements;
}

// ─── TEAM TABLE ─────────────────────────────────────────────────────────────
function buildTeamRows() {
  const rows = [];
  if (team.program_lead) rows.push(["APM Program Lead", team.program_lead]);
  if (team.assessment_lead) rows.push(["Assessment Lead / Facilitator", team.assessment_lead]);
  if (team.participants && team.participants.length) rows.push(["Assessment Participants", team.participants.join(", ")]);
  if (team.ea_advisors && team.ea_advisors.length) rows.push(["EA / APM Advisors", team.ea_advisors.join(", ")]);
  // Legacy fallback
  if (team.architects && team.architects.length) rows.push(["Technical Architects / SMEs", team.architects.join(", ")]);
  if (team.advisor) rows.push(["EA / APM Advisor", team.advisor]);
  return rows;
}

function buildOwnerRows() {
  if (!team.owners || !team.owners.length) return [];
  return team.owners.map(name => [name]);
}

// ─── ASSEMBLE TOC PAGE NUMBERS ──────────────────────────────────────────────
// Page estimates: 1=Snapshot, 2=Abstract, 3=TOC, 4=Team, 5+=quadrants
let pageNum = 5;
const tocPages = { invest: "5", modernize: "", tolerate: "", eliminate: "", incomplete: "", handoff: "" };
if (investApps.length) { tocPages.invest = String(pageNum); pageNum++; }
if (modernizeApps.length) { tocPages.modernize = String(pageNum); pageNum++; } else { tocPages.modernize = String(pageNum); pageNum++; }
if (tolerateApps.length) { tocPages.tolerate = String(pageNum); pageNum++; } else { tocPages.tolerate = String(pageNum); pageNum++; }
tocPages.eliminate = String(pageNum);
if (eliminateApps2.length) pageNum += 2; else pageNum++;
tocPages.incomplete = String(pageNum); pageNum++;
tocPages.handoff = String(pageNum);

// ─── DOCUMENT ───────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: NAVY },
        paragraph: { spacing: sp(240, 160), outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: NAVY_LIGHT },
        paragraph: { spacing: sp(200, 100), outlineLevel: 1 } },
    ]
  },

  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1080, right: 1080, bottom: 1080, left: 1080 }
      }
    },
    headers: { default: makeHeader() },
    footers: { default: makeFooter() },

    children: [

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 1 — PORTFOLIO SNAPSHOT
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Portfolio Snapshot", "snapshot"),
      ruled(),

      // KPI stats
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [2340, 2340, 2340, 2340], rows: [
          new TableRow({
            children: [
              [String(data.total_apps), "Total Applications"],
              [String(data.assessed_apps), "Assessed"],
              [String(data.incomplete_count), "Incomplete Data"],
              [data.assessment_period, "Assessment Period"],
            ].map(([val, lbl]) => new TableCell({
              borders: noBorders,
              shading: { fill: LIGHT_BLUE, type: ShadingType.CLEAR },
              width: { size: 2340, type: WidthType.DXA },
              margins: { top: 120, bottom: 120, left: 160, right: 160 },
              children: [
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: val, bold: true, size: 24, font: "Arial", color: NAVY })] }),
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: lbl, size: 16, font: "Arial", color: SLATE })] }),
              ]
            }))
          })]
      }),

      // Chart
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [W], rows: [
          new TableRow({
            children: [new TableCell({
              borders: imgBorders,
              margins: { top: 40, bottom: 40, left: 40, right: 40 },
              width: { size: W, type: WidthType.DXA },
              children: [new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new ImageRun({
                  type: "png", data: chartImg,
                  transformation: { width: chartW, height: chartH },
                  altText: { title: "TIME Portfolio Chart", description: "Bubble chart showing application positions in TIME quadrants", name: "TIMEChart" }
                })]
              })]
            })]
          })]
      }),

      // Distribution + insights
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [2600, 240, 6520], rows: [
          new TableRow({
            children: [
              new TableCell({
                borders: noBorders, width: { size: 2600, type: WidthType.DXA }, children: [
                  new Table({
                    width: { size: 2600, type: WidthType.DXA }, columnWidths: [1400, 600, 600], rows: [
                      new TableRow({ children: ["TIME Category", "Count", "% of Assessed"].map((h, i) => new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: [1400, 600, 600][i], type: WidthType.DXA }, margins: { top: 60, bottom: 60, left: 80, right: 80 }, children: [new Paragraph({ alignment: i > 0 ? AlignmentType.CENTER : AlignmentType.LEFT, children: [new TextRun({ text: h, bold: true, size: 16, font: "Arial", color: WHITE })] })] })) }),
                      ...[["Invest", cnt("Invest"), pct("Invest"), INV_BG], ["Modernize", cnt("Modernize"), pct("Modernize"), MOD_BG], ["Tolerate", cnt("Tolerate"), pct("Tolerate"), TOL_BG], ["Eliminate", cnt("Eliminate"), pct("Eliminate"), ELIM_BG]].map(([cat, c, p, bg]) =>
                        new TableRow({ children: [[cat, 1400], [c, 600], [p, 600]].map(([val, w], i) => new TableCell({ borders, shading: { fill: bg, type: ShadingType.CLEAR }, width: { size: w, type: WidthType.DXA }, margins: { top: 60, bottom: 60, left: 80, right: 80 }, children: [new Paragraph({ alignment: i > 0 ? AlignmentType.CENTER : AlignmentType.LEFT, children: [new TextRun({ text: String(val), size: 16, font: "Arial", color: DARK })] })] })) })
                      )
                    ]
                  })
                ]
              }),
              new TableCell({ borders: noBorders, width: { size: 240, type: WidthType.DXA }, children: [new Paragraph({ children: [new TextRun("")] })] }),
              new TableCell({
                borders: noBorders, width: { size: 6520, type: WidthType.DXA }, children: [
                  new Paragraph({ spacing: sp(0, 100), children: [new TextRun({ text: "Key Portfolio Insights", bold: true, size: 22, font: "Arial", color: NAVY })] }),
                  ...data.key_insights.map(insight => new Paragraph({
                    numbering: { reference: "bullets", level: 0 },
                    spacing: sp(60, 80),
                    children: makeRuns(insight, 20)
                  })),
                ]
              }),
            ]
          })
        ]
      }),
      italic("For the full visual portfolio summary, refer to the attached Application Assessment Summary."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 2 — ABSTRACT
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Abstract", "abstract"),
      ruled(),
      ...narr.abstract.split('\n').filter(p => p.trim()).map(p => body(p)),

      calloutBox([
        new Paragraph({ spacing: sp(0, 100), children: [new TextRun({ text: "Assessment Methodology", bold: true, size: 22, font: "Arial", color: NAVY })] }),
        new Paragraph({ spacing: sp(0, 120), children: [new TextRun({ text: "Each application was assessed using two standardized factor sets. Scores for each factor are recorded on a 1\u20135 scale and normalized to 0\u2013100.", size: 20, font: "Arial", color: DARK })] }),
        new Table({
          width: { size: W - 400, type: WidthType.DXA }, columnWidths: [Math.round((W - 400) / 2), Math.round((W - 400) / 2)], rows: [
            new TableRow({
              children: [
                new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: Math.round((W - 400) / 2), type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: "Business Fit Factors (B1\u2013B10)", bold: true, size: 20, font: "Arial", color: WHITE })] })] }),
                new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: Math.round((W - 400) / 2), type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: "Technical Fit Factors (T01\u2013T14)", bold: true, size: 20, font: "Arial", color: WHITE })] })] }),
              ]
            }),
            ...[
              ["B1 \u2014 Strategic Contribution", "T01 \u2014 Platform / Product Footprint"],
              ["B2 \u2014 Regional Growth Support", "T02 \u2014 Application Development Platform"],
              ["B3 \u2014 Public Confidence Impact", "T03 \u2014 Platform Portability"],
              ["B4 \u2014 Scope of Use", "T04 \u2014 Configurability & Extensibility"],
              ["B5 \u2014 Business Process Criticality", "T05 \u2014 Support for Modern UX"],
              ["B6 \u2014 Business Interruption Tolerance", "T06 \u2014 Security Controls"],
              ["B7 \u2014 Essential Service Impact", "T07 \u2014 Security Controls for Data Sensitivity"],
              ["B8 \u2014 Current Needs Fulfillment", "T08 \u2014 Identity Assurance"],
              ["B9 \u2014 Future Needs Adaptability", "T09 \u2014 Resilience & Recovery"],
              ["B10 \u2014 User Satisfaction", "T10 \u2014 Observability & Manageability"],
              ["", "T11 \u2014 Vendor and Support Availability"],
              ["", "T12 \u2014 Integration Capabilities"],
              ["", "T13 \u2014 Integrations"],
              ["", "T14 \u2014 Data Accessibility"],
            ].map((row, i) => new TableRow({
              children: row.map((cell) => new TableCell({
                borders, shading: { fill: i % 2 === 0 ? LIGHT_BLUE : WHITE, type: ShadingType.CLEAR },
                width: { size: Math.round((W - 400) / 2), type: WidthType.DXA },
                margins: { top: 60, bottom: 60, left: 120, right: 120 },
                children: [new Paragraph({ children: [new TextRun({ text: cell, size: 18, font: "Arial", color: DARK })] })]
              }))
            }))
          ]
        }),
        new Paragraph({ spacing: sp(120, 0), children: [new TextRun({ text: "The TIME methodology is adapted from the Gartner APM framework. SaskBuilds uses \"Modernize\" in place of Gartner's original \"Migrate\" designation to better reflect the nature of platform renewal activities within the Government of Saskatchewan context.", size: 18, font: "Arial", italics: true, color: SLATE })] }),
      ]),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 3 — TABLE OF CONTENTS
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Contents", "toc"),
      ruled(),
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [7800, 1560],
        rows: [
          tocRow("Portfolio Snapshot", "snapshot", "1", true),
          tocRow("Abstract", "abstract", "2"),
          tocRow("Assessment Team", "team", "4"),
          tocRow("Invest", "invest", tocPages.invest, true),
          tocRow("Modernize", "modernize", tocPages.modernize, true),
          tocRow("Tolerate", "tolerate", tocPages.tolerate, true),
          tocRow("Eliminate", "eliminate", tocPages.eliminate, true),
          tocRow("Incomplete Data", "incomplete", tocPages.incomplete),
          tocRow("EA Handoff", "handoff", tocPages.handoff),
        ]
      }),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 4 — ASSESSMENT TEAM
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Assessment Team", "team"),
      ruled(),
      ...(((team.architects || []).concat(team.ea_advisors || [])).some(a => a.endsWith('\u2020')) ? [italic("Names marked \u2020 are first-name only as recorded in the assessment data. Full names to be confirmed.")] : []),
      new Table({
        width: { size: W, type: WidthType.DXA }, columnWidths: [2600, 6760], rows: [
          new TableRow({
            children: [
              new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: 2600, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: "Role", bold: true, size: 20, font: "Arial", color: WHITE })] })] }),
              new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: 6760, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: "Name(s)", bold: true, size: 20, font: "Arial", color: WHITE })] })] }),
            ]
          }),
          ...buildTeamRows().map(([role, names], i) => new TableRow({
            children: [
              new TableCell({ borders, shading: { fill: i % 2 === 0 ? LIGHT_BLUE : WHITE, type: ShadingType.CLEAR }, width: { size: 2600, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: role, bold: true, size: 20, font: "Arial", color: NAVY })] })] }),
              new TableCell({ borders, shading: { fill: i % 2 === 0 ? LIGHT_BLUE : WHITE, type: ShadingType.CLEAR }, width: { size: 6760, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: names, size: 20, font: "Arial", color: DARK })] })] }),
            ]
          }))
        ]
      }),

      // Application Owners — separate table
      ...(buildOwnerRows().length ? [
        spacer(),
        h2("Application Owners", NAVY_LIGHT),
        italic("Application owners were not present during the assessment sessions. They are listed here as the designated owners of record for each assessed application."),
        new Table({
          width: { size: W, type: WidthType.DXA }, columnWidths: [W], rows: [
            new TableRow({
              children: [
                new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: W, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: "Application Owner", bold: true, size: 20, font: "Arial", color: WHITE })] })] }),
              ]
            }),
            ...buildOwnerRows().map(([name], i) => new TableRow({
              children: [
                new TableCell({ borders, shading: { fill: i % 2 === 0 ? LIGHT_BLUE : WHITE, type: ShadingType.CLEAR }, width: { size: W, type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 120, right: 120 }, children: [new Paragraph({ children: [new TextRun({ text: name, size: 20, font: "Arial", color: DARK })] })] }),
              ]
            }))
          ]
        }),
      ] : []),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // QUADRANT SECTIONS
      // ══════════════════════════════════════════════════════════════════════
      ...buildQuadrantSection("Invest", investApps, INV_BG, INV_HDR, "invest", "invest"),
      pageBreak(),
      ...buildQuadrantSection("Modernize", modernizeApps, MOD_BG, MOD_HDR, "modernize", "modernize"),
      pageBreak(),
      ...buildQuadrantSection("Tolerate", tolerateApps, TOL_BG, TOL_HDR, "tolerate", "tolerate"),
      pageBreak(),
      ...buildQuadrantSection("Eliminate", eliminateApps, ELIM_BG, ELIM_HDR, "eliminate", "eliminate"),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // INCOMPLETE DATA
      // ══════════════════════════════════════════════════════════════════════
      ...buildIncompleteSection(),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // EA HANDOFF
      // ══════════════════════════════════════════════════════════════════════
      ...buildHandoffSection(),

    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(args.out, buf);
  console.log(`Report saved to ${args.out}`);
}).catch(err => {
  console.error('Error generating report:', err);
  process.exit(1);
});
