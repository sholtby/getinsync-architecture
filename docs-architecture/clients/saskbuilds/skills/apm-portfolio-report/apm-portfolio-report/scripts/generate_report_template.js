const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageBreak, ImageRun, Header, Footer, PageNumber,
  TabStopType, TabStopPosition, Bookmark, InternalHyperlink
} = require('docx');
const fs = require('fs');

// ─── CONSTANTS ───────────────────────────────────────────────────────────────
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

// ─── APPLICATION NAMES FOR AUTO-BOLD ─────────────────────────────────────────
const APP_NAMES = [
  "IRIS — Integrated Resource Information System",
  "IRIS Business Intelligence",
  "Water Analysis",
  "GeoLogic Geoscout",
  "RBC Receivables Link Application",
  "GeoVista",
  "Land Claims GIS Mapping",
  "SMAD — Saskatchewan Mineral Assessment Data",
  "Daily Drilling Activity Report Archive",
  "GeoPlanner",
  "Licensed Wells Archive",
  "Geoscience Data Management",
  "SMDI — Saskatchewan Mineral Deposits Index",
  "Coal Files",
  "GeoAtlas",
  "Preliminary Plans",
  "AccuMap",
  "LogSleuth",
  "Test Holes",
  "Treeno",
  "Value Navigator",
  "MARS — Mineral Administration Registration System",
].sort((a, b) => b.length - a.length); // longest first to avoid partial matches

function makeRuns(text, baseSize=22) {
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

// ─── HELPERS ─────────────────────────────────────────────────────────────────
const sp = (before=0, after=160) => ({ before, after });

function h1(text, id) {
  const run = new TextRun({ text, bold: true, size: 28, font: "Arial", color: NAVY });
  return new Paragraph({
    heading: HeadingLevel.HEADING_1, spacing: sp(240, 160),
    children: id ? [new Bookmark({ id, children: [run] })] : [run]
  });
}

function h2(text, color=NAVY_LIGHT, id) {
  const run = new TextRun({ text, bold: true, size: 24, font: "Arial", color });
  return new Paragraph({
    heading: HeadingLevel.HEADING_2, spacing: sp(200, 100),
    children: id ? [new Bookmark({ id, children: [run] })] : [run]
  });
}

function h3(text, color=DARK) {
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

function calloutBox(children, bg=LIGHT_BLUE, borderColor=NAVY) {
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

function sectionHeader(label, bg, textColor=WHITE) {
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
        new TableCell({ borders, shading: { fill: idx%2===0?bgColor:WHITE, type: ShadingType.CLEAR }, width: { size: cols[0], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: String(app.num), bold: true, size: 18, font: "Arial", color: accentColor })] })] }),
        new TableCell({ borders, shading: { fill: idx%2===0?bgColor:WHITE, type: ShadingType.CLEAR }, width: { size: cols[1], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ children: [new TextRun({ text: app.name + (app.crownJewel ? "  ★" : ""), size: 18, font: "Arial", color: DARK })] })] }),
        ...["criticality","businessFit","techFit"].map((k,ci) => new TableCell({ borders, shading: { fill: idx%2===0?bgColor:WHITE, type: ShadingType.CLEAR }, width: { size: cols[ci+2], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: String(app[k]), size: 18, font: "Arial", color: DARK })] })] })),
        new TableCell({ borders, shading: { fill: idx%2===0?bgColor:WHITE, type: ShadingType.CLEAR }, width: { size: cols[5], type: WidthType.DXA }, margins: { top: 80, bottom: 80, left: 100, right: 100 }, children: [new Paragraph({ children: [new TextRun({ text: app.lifecycle, size: 18, font: "Arial", color: DARK })] })] }),
      ]}))
    ]
  });
}

// Table-based TOC entry
function tocRow(label, anchor, pageNum, isHeader=false) {
  const rowBorder = { style: BorderStyle.NONE, size: 0, color: WHITE };
  const bottomLine = { style: BorderStyle.DOTTED, size: 1, color: MID_GRAY };
  return new TableRow({ children: [
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
  ]});
}

// ─── DATA ────────────────────────────────────────────────────────────────────
const eliminateApps1 = [ // first 8 — fits on page 8
  { num:11, name: "Land Claims GIS Mapping",                          criticality:"43.8", businessFit:"45.0", techFit:"37.0",  lifecycle:"Incomplete Data" },
  { num:17, name: "SMAD — Sask. Mineral Assessment Data",             criticality:"42.5", businessFit:"48.8", techFit:"29.3",  lifecycle:"Extended Support" },
  { num: 4, name: "Daily Drilling Activity Report Archive",           criticality:"41.3", businessFit:"42.5", techFit:"35.5",  lifecycle:"Extended Support" },
  { num: 8, name: "GeoPlanner",                                       criticality:"41.3", businessFit:"42.5", techFit:"36.0",  lifecycle:"End of Support" },
  { num:12, name: "Licensed Wells Archive",                           criticality:"41.3", businessFit:"42.5", techFit:"35.5",  lifecycle:"Extended Support" },
  { num:10, name: "IRIS Business Intelligence",                       criticality:"38.8", businessFit:"45.0", techFit:"48.0",  lifecycle:"Mainstream Support" },
  { num: 2, name: "Coal Files",                                       criticality:"38.8", businessFit:"45.0", techFit:"44.3",  lifecycle:"Mainstream Support" },
  { num: 5, name: "GeoAtlas",                                         criticality:"30.0", businessFit:"37.5", techFit:"29.5",  lifecycle:"End of Support" },
];

const eliminateApps2 = [ // remaining 6 — continued on page 9
  { num:14, name: "Preliminary Plans",                                criticality:"28.8", businessFit:"46.3", techFit:"36.8",  lifecycle:"Mainstream Support" },
  { num: 1, name: "AccuMap",                                          criticality:"22.5", businessFit:"26.3", techFit:"29.5",  lifecycle:"Extended Support" },
  { num:13, name: "LogSleuth",                                        criticality:"21.3", businessFit:"16.3", techFit:"36.5",  lifecycle:"ITDNAS-End-Of-Life" },
  { num:18, name: "Test Holes",                                       criticality: "8.8", businessFit:"11.3", techFit:"35.5",  lifecycle:"Mainstream Support" },
  { num:19, name: "Treeno",                                           criticality: "3.8", businessFit:"11.3", techFit:"35.5",  lifecycle:"End of Support" },
  { num:20, name: "Value Navigator",                                  criticality: "3.8", businessFit:"11.3", techFit:"35.5",  lifecycle:"Extended Support" },
];

const modernizeApps = [
  { num: 7, name: "GeoLogic Geoscout",                                criticality:"46.3", businessFit:"50.0", techFit:"18.0",  lifecycle:"ITDNAS-End-Of-Life" },
  { num:15, name: "RBC Receivables Link Application",                 criticality:"38.8", businessFit:"51.3", techFit:"43.3",  lifecycle:"Extended Support" },
  { num: 6, name: "GeoVista",                                         criticality:"35.0", businessFit:"50.0", techFit:"36.5",  lifecycle:"Extended Support" },
];

const investApps = [
  { num: 9, name: "IRIS — Integrated Resource Information System",    criticality:"88.8", businessFit:"88.8", techFit:"65.8",  lifecycle:"Mainstream Support", crownJewel:true },
  { num:21, name: "Water Analysis",                                   criticality:"67.5", businessFit:"70.0", techFit:"50.0",  lifecycle:"Mainstream Support" },
];

const tolerateApps = [
  { num: 3, name: "MARS — Mineral Administration Registration System",criticality:"41.3", businessFit:"42.5", techFit:"50.0",  lifecycle:"Business/Vendor Managed" },
];

// ─── IMAGES ──────────────────────────────────────────────────────────────────
const chartImg = fs.readFileSync('/home/claude/time_bubble_chart.png');
const chartW = 608, chartH = Math.round(608 / 1.79); // fits within content width

// ─── HEADER ──────────────────────────────────────────────────────────────────
function makeHeader() {
  return new Header({ children: [
    new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [W], rows: [
      new TableRow({ children: [new TableCell({
        borders: noBorders,
        shading: { fill: NAVY, type: ShadingType.CLEAR },
        margins: { top: 100, bottom: 100, left: 200, right: 200 },
        width: { size: W, type: WidthType.DXA },
        children: [
          new Paragraph({ spacing: sp(0,40), children: [new TextRun({ text: "ENERGY AND RESOURCES", bold: true, size: 26, font: "Arial", color: WHITE })] }),
          new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Application Portfolio  TIME  Assessment", size: 18, font: "Arial", color: "B0C4D8" })] }),
        ]
      })]})]
    })
  ]});
}

// ─── FOOTER ──────────────────────────────────────────────────────────────────
function makeFooter() {
  return new Footer({ children: [
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
        new TextRun({ text: "April 2026", size: 18, font: "Arial", color: SLATE }),
      ]
    })
  ]});
}

// ─── DOCUMENT ────────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
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

      // KPI stats at 12pt
      new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [2340, 2340, 2340, 2340], rows: [
        new TableRow({ children: [
          ["22", "Total Applications"],
          ["20", "Assessed"],
          ["2", "Incomplete Data"],
          ["Feb–Mar 2026", "Assessment Period"],
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
      })] }),

      // Chart with picture border
      new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [W], rows: [
        new TableRow({ children: [new TableCell({
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
        })]})]
      }),

      // Distribution + insights side by side
      new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [2600, 240, 6520], rows: [
        new TableRow({ children: [
          // Distribution
          new TableCell({ borders: noBorders, width: { size: 2600, type: WidthType.DXA }, children: [
            new Table({ width: { size: 2600, type: WidthType.DXA }, columnWidths: [1400, 600, 600], rows: [
              new TableRow({ children: ["TIME Category","Count","% of Assessed"].map((h, i) => new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: [1400,600,600][i], type: WidthType.DXA }, margins: { top:60,bottom:60,left:80,right:80 }, children: [new Paragraph({ alignment: i>0?AlignmentType.CENTER:AlignmentType.LEFT, children: [new TextRun({ text: h, bold:true, size:16, font:"Arial", color:WHITE })] })] })) }),
              ...[["Invest","2","10%",INV_BG],["Modernize","3","15%",MOD_BG],["Tolerate","1","5%",TOL_BG],["Eliminate","14","70%",ELIM_BG]].map(([cat,cnt,pct,bg]) =>
                new TableRow({ children: [[cat,1400],[cnt,600],[pct,600]].map(([val,w],i) => new TableCell({ borders, shading:{ fill:bg, type:ShadingType.CLEAR }, width:{size:w,type:WidthType.DXA}, margins:{top:60,bottom:60,left:80,right:80}, children:[new Paragraph({ alignment:i>0?AlignmentType.CENTER:AlignmentType.LEFT, children:[new TextRun({text:val,size:16,font:"Arial",color:DARK})] })] })) })
              )
            ]})
          ]}),
          new TableCell({ borders: noBorders, width: { size: 240, type: WidthType.DXA }, children: [new Paragraph({ children: [new TextRun("")] })] }),
          // Insights
          new TableCell({ borders: noBorders, width: { size: 6520, type: WidthType.DXA }, children: [
            new Paragraph({ spacing: sp(0,100), children: [new TextRun({ text: "Key Portfolio Insights", bold: true, size: 22, font: "Arial", color: NAVY })] }),
            new Paragraph({ numbering: { reference:"bullets", level:0 }, spacing: sp(60,80), children: makeRuns("70% of the assessed portfolio lands in Eliminate, reflecting accumulated technical legacy against declining business relevance across a large portion of the ministry's application inventory.", 20) }),
            new Paragraph({ numbering: { reference:"bullets", level:0 }, spacing: sp(60,80), children: makeRuns("IRIS — Integrated Resource Information System is the portfolio's highest-criticality asset (88.8), correctly positioned in Invest with Crown Jewel designation. Its scores were found to be inverted in the source data and have been corrected in this report.", 20) }),
            new Paragraph({ numbering: { reference:"bullets", level:0 }, spacing: sp(60,80), children: makeRuns("GeoLogic Geoscout represents the most time-pressured Modernize application — the lowest technical fit score in the portfolio (18.0) combined with ITDNAS-End-Of-Life infrastructure status.", 20) }),
            new Paragraph({ numbering: { reference:"bullets", level:0 }, spacing: sp(60,80), children: makeRuns("Geoscience Data Management carries the highest criticality (60.0) of the two incomplete-data applications and warrants priority follow-up before the next portfolio planning cycle.", 20) }),
          ]}),
        ]})
      ]}),
      italic("For the full visual portfolio summary, refer to the attached Application Assessment Summary."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 2 — ABSTRACT
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Abstract", "abstract"),
      ruled(),
      body("This report presents the findings of the Application Portfolio TIME Assessment conducted for the Ministry of Energy and Resources, Government of Saskatchewan. The assessment was administered across 20 business applications using the TIME methodology, adapted from the Gartner Application Portfolio Management (APM) framework. Each application was evaluated against ten business fit factors (B1–B10) and fourteen technical fit factors (T01–T14), yielding normalized scores on a 0–100 scale for Business Fit, Technical Health, and Criticality. Applications were subsequently positioned within one of four strategic quadrants — Invest, Tolerate, Modernize, or Eliminate — based on the intersection of their Business Fit and Technical Fit scores. Bubble size in the portfolio visualization represents the Criticality score, providing a risk-weighted view of each application's portfolio position."),
      body("The assessment was conducted by the APM Team, Ministry of Energy and Resources, in collaboration with application owners, technical architects, and subject matter experts across the ministry. Assessment sessions were facilitated between February and March 2026. Two applications — Geoscience Data Management and SMDI — Saskatchewan Mineral Deposits Index — could not be fully assessed due to incomplete data and are excluded from quadrant analysis pending follow-up assessment sessions. One data quality issue was identified during report preparation: the assessment records for IRIS — Integrated Resource Information System and IRIS Business Intelligence were found to have been recorded with inverted scores. This error has been corrected in the present report; the source data should be updated accordingly."),

      calloutBox([
        new Paragraph({ spacing: sp(0,100), children: [new TextRun({ text: "Assessment Methodology", bold: true, size: 22, font: "Arial", color: NAVY })] }),
        new Paragraph({ spacing: sp(0,120), children: [new TextRun({ text: "Each application was assessed using two standardized factor sets. Scores for each factor are recorded on a 1–5 scale and normalized to 0–100.", size: 20, font: "Arial", color: DARK })] }),
        new Table({ width: { size: W-400, type: WidthType.DXA }, columnWidths: [Math.round((W-400)/2), Math.round((W-400)/2)], rows: [
          new TableRow({ children: [
            new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: Math.round((W-400)/2), type: WidthType.DXA }, margins: { top:80,bottom:80,left:120,right:120 }, children: [new Paragraph({ children: [new TextRun({ text: "Business Fit Factors (B1–B10)", bold:true, size:20, font:"Arial", color:WHITE })] })] }),
            new TableCell({ borders, shading: { fill: NAVY, type: ShadingType.CLEAR }, width: { size: Math.round((W-400)/2), type: WidthType.DXA }, margins: { top:80,bottom:80,left:120,right:120 }, children: [new Paragraph({ children: [new TextRun({ text: "Technical Fit Factors (T01–T14)", bold:true, size:20, font:"Arial", color:WHITE })] })] }),
          ]}),
          ...[
            ["B1 — Strategic Contribution","T01 — Platform / Product Footprint"],
            ["B2 — Regional Growth Support","T02 — Application Development Platform"],
            ["B3 — Public Confidence Impact","T03 — Platform Portability"],
            ["B4 — Scope of Use","T04 — Configurability & Extensibility"],
            ["B5 — Business Process Criticality","T05 — Support for Modern UX"],
            ["B6 — Business Interruption Tolerance","T06 — Security Controls"],
            ["B7 — Essential Service Impact","T07 — Security Controls for Data Sensitivity"],
            ["B8 — Current Needs Fulfillment","T08 — Identity Assurance"],
            ["B9 — Future Needs Adaptability","T09 — Resilience & Recovery"],
            ["B10 — User Satisfaction","T10 — Observability & Manageability"],
            ["","T11 — Vendor and Support Availability"],
            ["","T12 — Integration Capabilities"],
            ["","T13 — Integrations"],
            ["","T14 — Data Accessibility"],
          ].map((row, i) => new TableRow({ children: row.map((cell, ci) => new TableCell({
            borders, shading: { fill: i%2===0?LIGHT_BLUE:WHITE, type: ShadingType.CLEAR },
            width: { size: Math.round((W-400)/2), type: WidthType.DXA },
            margins: { top:60,bottom:60,left:120,right:120 },
            children: [new Paragraph({ children: [new TextRun({ text: cell, size:18, font:"Arial", color:DARK })] })]
          })) }))
        ]}),
        new Paragraph({ spacing: sp(120,0), children: [new TextRun({ text: "The TIME methodology is adapted from the Gartner APM framework. SaskBuilds uses \"Modernize\" in place of Gartner's original \"Migrate\" designation to better reflect the nature of platform renewal activities within the Government of Saskatchewan context.", size:18, font:"Arial", italics:true, color:SLATE })] }),
      ]),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 3 — TABLE OF CONTENTS
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Contents", "toc"),
      ruled(),
      new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [7800, 1560],
        rows: [
          tocRow("Portfolio Snapshot", "snapshot", "1", true),
          tocRow("Abstract", "abstract", "2"),
          tocRow("Assessment Team", "team", "4"),
          tocRow("Invest", "invest", "5", true),
          tocRow("Modernize", "modernize", "6", true),
          tocRow("Tolerate", "tolerate", "7", true),
          tocRow("Eliminate", "eliminate", "8", true),
          tocRow("Incomplete Data", "incomplete", "10"),
          tocRow("EA Handoff", "handoff", "11"),
        ]
      }),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 4 — ASSESSMENT TEAM
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Assessment Team", "team"),
      ruled(),
      italic("Names marked † are first-name only as recorded in the assessment data. Full names to be confirmed."),
      new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: [2600, 6760], rows: [
        new TableRow({ children: [
          new TableCell({ borders, shading:{fill:NAVY,type:ShadingType.CLEAR}, width:{size:2600,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:"Role",bold:true,size:20,font:"Arial",color:WHITE})]})] }),
          new TableCell({ borders, shading:{fill:NAVY,type:ShadingType.CLEAR}, width:{size:6760,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:"Name(s)",bold:true,size:20,font:"Arial",color:WHITE})]})] }),
        ]}),
        ...[
          ["APM Program Lead", "Ryan Brittner, Director IT Planning"],
          ["Assessment Lead / Facilitator", "Emma Zhou"],
          ["Application Owners", "Colin Card, Scott Weaver, Jenni Gasson, Jane McLeod, Kim Olyowsky, Yanyan Han, Bruce Wilhelm, Marilyn Lolacher, Emma Zhou"],
          ["Technical Architects / SMEs", "Ryan Brittner, Dalton Stevens, Robert Danforth, Glenn †, Barrie †, Michele †, Martin †, Leanne †, Sheng †"],
          ["EA / APM Advisor", "Stuart Holtby, Allstar Technologies"],
        ].map(([role, names], i) => new TableRow({ children: [
          new TableCell({ borders, shading:{fill:i%2===0?LIGHT_BLUE:WHITE,type:ShadingType.CLEAR}, width:{size:2600,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:role,bold:true,size:20,font:"Arial",color:NAVY})]})] }),
          new TableCell({ borders, shading:{fill:i%2===0?LIGHT_BLUE:WHITE,type:ShadingType.CLEAR}, width:{size:6760,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:names,size:20,font:"Arial",color:DARK})]})] }),
        ]}))
      ]}),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 5 — INVEST
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      sectionHeader("INVEST", INV_HDR),
      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "What is Invest?", bold: true, size: 20, font: "Arial", color: INV_HDR })] }),
        new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Applications in the Invest quadrant demonstrate high business fit and strong technical health. They are core to operational delivery and are built on sustainable, modern platforms. Continued investment in maintenance, enhancement, and capability growth is warranted. These applications represent the portfolio's highest-value digital assets and carry the greatest risk if disrupted or allowed to decline.", size: 20, font: "Arial", italics: true, color: DARK })] }),
      ], INV_BG, INV_HDR),
      h2("Pattern Narrative", INV_HDR, "invest"),
      body("IRIS — Integrated Resource Information System and Water Analysis are distinctly differentiated from the rest of the Energy and Resources portfolio. Both applications scored above the 50-point threshold on all three dimensions — business fit, technical health, and criticality — placing them in a category of their own within the assessed portfolio. IRIS — Integrated Resource Information System carries a criticality of 88.8 alongside Crown Jewel designation and active ITSM history (7 incidents and 3 service requests over 24 months), consistent with a high-dependency operational platform embedded in day-to-day ministry work. Water Analysis, at 70.0 business fit and 67.5 criticality, serves a clear operational mandate and was assessed with broad technical participation. Both applications' B-factor profiles reflect strong strategic alignment, high organizational scope, and direct relevance to ministry mandate delivery."),
      h3("Applications — Ranked by Criticality"),
      ...(investApps.some(a => a.crownJewel) ? [italic("★ denotes Crown Jewel designation")] : []),
      appTable(investApps, INV_BG, INV_HDR),
      h3("Criticality-Weighted Insight"),
      body("IRIS — Integrated Resource Information System at 88.8 criticality is the single most operationally significant application in the portfolio. Its technical fit of 65.8 is adequate but not exceptional — sufficient to remain in Invest, but not so strong that the platform can be taken for granted. The EA team should ensure governance exists to monitor this application's technical currency and platform roadmap actively. Water Analysis sits precisely at the 50-point technical fit threshold; any further decline in technical health without corresponding investment would push this application into Modernize territory at the next assessment cycle."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 6 — MODERNIZE
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      sectionHeader("MODERNIZE", MOD_HDR),
      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "What is Modernize?", bold: true, size: 20, font: "Arial", color: MOD_HDR })] }),
        new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Applications in the Modernize quadrant deliver meaningful business value but are constrained by aging or inadequate technical foundations. The business case for continued use is present; however, the platform, infrastructure, or development environment has not kept pace with organizational needs or current standards. Re-platforming, upgrading, or transitioning to modern alternatives is indicated. SaskBuilds uses 'Modernize' in place of Gartner's original 'Migrate' designation to reflect the broader range of renewal approaches applicable in a government context.", size: 20, font: "Arial", italics: true, color: DARK })] }),
      ], MOD_BG, MOD_HDR),
      h2("Pattern Narrative", MOD_HDR, "modernize"),
      body("The three Modernize applications share a business fit cluster at or just above the 50-point threshold, each retaining sufficient organizational relevance to justify continued investment. What distinguishes this group most sharply is the severity of their technical positions. GeoLogic Geoscout carries a technical fit score of 18.0 — the lowest in the entire assessed portfolio — while running on ITDNAS-End-Of-Life infrastructure. GeoVista and RBC Receivables Link Application sit in Extended Support with moderate technical scores, suggesting they are aging but not yet in crisis. B-factor assessments across the group reflect applications that support visible operational functions — resource management workflows, geoscience data visualization, and financial receivables processing — but have not kept pace with user expectations or organizational growth."),
      h3("Applications — Ranked by Criticality"),
      appTable(modernizeApps, MOD_BG, MOD_HDR),
      h3("Criticality-Weighted Insight"),
      body("GeoLogic Geoscout demands the most immediate EA attention in this quadrant. A technical fit score of 18.0 on ITDNAS-End-Of-Life infrastructure, combined with a criticality of 46.3 and recorded ITSM activity (7 incidents, 3 requests, 1 problem over 24 months), signals a platform under active operational stress. The infrastructure lifecycle status alone — ITDNAS-End-Of-Life — constitutes an active planning trigger. RBC Receivables Link Application and GeoVista carry Extended Support status and more moderate technical scores, providing more runway, but both sit close enough to the Eliminate boundary on business fit that a further decline in organizational relevance could shift their quadrant position at the next assessment cycle."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 7 — TOLERATE
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      sectionHeader("TOLERATE", TOL_HDR),
      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "What is Tolerate?", bold: true, size: 20, font: "Arial", color: TOL_HDR })] }),
        new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Applications in the Tolerate quadrant exhibit adequate technical health but deliver limited strategic business value. These systems continue to function reliably but are not aligned with the organization's core mandate or growth priorities. The appropriate posture is to maintain as-is, limit further investment, and monitor for a natural exit or replacement opportunity. Tolerate applications are often candidates for consolidation as the broader portfolio evolves.", size: 20, font: "Arial", italics: true, color: DARK })] }),
      ], TOL_BG, TOL_HDR),
      h2("Pattern Narrative", TOL_HDR, "tolerate"),
      body("MARS — Mineral Administration Registration System is the sole application in the Tolerate quadrant, with a business fit of 42.5 paired with a technical fit of exactly 50.0. Its Business/Vendor Managed lifecycle status indicates the application is maintained and supported externally, limiting the ministry's direct control over its technical trajectory and roadmap. The criticality score of 41.3 places MARS in the moderate dependency range — present enough to require a managed approach if the vendor relationship changes, but not so critical that disruption poses immediate operational risk."),
      h3("Applications — Ranked by Criticality"),
      appTable(tolerateApps, TOL_BG, TOL_HDR),
      h3("Criticality-Weighted Insight"),
      body("The key question MARS — Mineral Administration Registration System surfaces for the EA team is one of ownership and control. Given that it is vendor-managed, what visibility does the ministry have into its technical roadmap and contract renewal timeline? A change in the vendor relationship — price increase, product discontinuation, or acquisition — could force a repositioning decision without the lead time a ministry-managed application would afford. The combination of moderate criticality and external control makes this application's status worth including in any contract review or vendor management process."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 8 — ELIMINATE
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      sectionHeader("ELIMINATE", ELIM_HDR),
      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "What is Eliminate?", bold: true, size: 20, font: "Arial", color: ELIM_HDR })] }),
        new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Applications in the Eliminate quadrant provide limited business value and are built on aging or unsupported platforms. They have aged past their operational relevance on both dimensions simultaneously. Planning for retirement, consolidation, or replacement is appropriate. The Criticality score determines urgency: low-criticality applications are candidates for near-term retirement, while moderate-criticality applications require sequenced exit planning to manage operational dependencies.", size: 20, font: "Arial", italics: true, color: DARK })] }),
      ], ELIM_BG, ELIM_HDR),
      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "⚠  Data Quality Note", bold: true, size: 20, font: "Arial", color: ELIM_HDR })] }),
        new Paragraph({ spacing: sp(0,0), children: makeRuns("During report preparation, the assessment records for IRIS — Integrated Resource Information System and IRIS Business Intelligence were found to have been recorded with inverted scores. IRIS — Integrated Resource Information System has been corrected to Invest (Criticality 88.8, Business Fit 88.8, Tech Fit 65.8). IRIS Business Intelligence has been placed in Eliminate (Criticality 38.8, Business Fit 45.0, Tech Fit 48.0). The source assessment data should be corrected before the next portfolio review cycle.", 20) }),
      ], "FFF3F3", ELIM_HDR),
      h2("Pattern Narrative", ELIM_HDR, "eliminate"),
      body("The 14 Eliminate applications share consistent patterns across their assessment data. On the business side, most scored low on strategic contribution, organizational scope, and user satisfaction, indicating they serve narrow, non-strategic functions within specific branches or units. Process criticality ratings are predominantly low to moderate, suggesting these applications support work that has viable workarounds or could be absorbed through other means. Several applications were assessed with limited stakeholder participation, which may itself reflect limited organizational awareness of the application."),
      body("On the technical side, the group shows a concentration of legacy client-server architectures, limited platform portability, and minimal disaster recovery posture. Many run on infrastructure that is either at end-of-life or on the ITDNAS-managed file share network, with no active vendor support path. The overall profile is a group of applications that have been maintained but not modernized — functional enough to keep running, but carrying accumulating technical debt on both dimensions."),
      h3("Applications — Ranked by Criticality"),
      ...(eliminateApps1.concat(eliminateApps2).some(a => a.crownJewel) ? [italic("★ denotes Crown Jewel designation")] : []),
      appTable(eliminateApps1, ELIM_BG, ELIM_HDR),

      // ── CONTINUED on next page ────────────────────────────────────────────
      spacer(),
      h3("Applications — Ranked by Criticality (continued)", ELIM_HDR),
      appTable(eliminateApps2, ELIM_BG, ELIM_HDR),
      h3("Criticality-Weighted Insight"),
      body("Despite sharing an Eliminate position, the criticality scores within this group vary enough to warrant differentiated EA attention. Five applications cluster between 38 and 44 on the criticality scale — Land Claims GIS Mapping (43.8), SMAD — Saskatchewan Mineral Assessment Data (42.5), Daily Drilling Activity Report Archive (41.3), GeoPlanner (41.3), and Licensed Wells Archive (41.3). These represent moderate-dependency applications requiring sequenced exit planning rather than straightforward retirement. Their lifecycle statuses — a mix of Extended Support, End of Support, and Incomplete Data — add complexity to any planning effort."),
      body("At the lower end of the criticality scale, Test Holes (8.8), Treeno (3.8), and Value Navigator (3.8) represent the clearest candidates for near-term retirement with minimal organizational disruption. LogSleuth, on ITDNAS-End-Of-Life infrastructure with a criticality of 21.3, also presents a low-risk retirement opportunity, though its active incident history (3 incidents over 24 months) warrants a brief operational check before exit."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 10 — INCOMPLETE DATA
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("Incomplete Data", "incomplete"),
      ruled(),
      body("Two applications could not be fully positioned in the TIME model due to incomplete assessment data. These applications are not included in the quadrant analysis above and require a follow-up assessment session before they can be incorporated into portfolio planning."),

      h2("Geoscience Data Management", NAVY_LIGHT),
      new Table({ width:{size:W,type:WidthType.DXA}, columnWidths:[2600,6760], rows:
        [["Business Fit Score","55.0"],["Criticality Score","60.0 — highest of the two incomplete applications"],["Technical Fit Score","Not assessed — technical assessment in progress"],["Lifecycle Status","Incomplete Data"],["TIME Position","Cannot be determined. Scores suggest Invest or Modernize. Priority follow-up recommended."],["Action Required","Complete technical assessment before the next portfolio planning cycle."]].map(([k,v],i) =>
          new TableRow({ children:[
            new TableCell({ borders, shading:{fill:i%2===0?INC_BG:WHITE,type:ShadingType.CLEAR}, width:{size:2600,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:k,bold:true,size:18,font:"Arial",color:NAVY})]})] }),
            new TableCell({ borders, shading:{fill:i%2===0?INC_BG:WHITE,type:ShadingType.CLEAR}, width:{size:6760,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:v,size:18,font:"Arial",color:DARK})]})] }),
          ]})
        )
      }),

      h2("SMDI — Saskatchewan Mineral Deposits Index", NAVY_LIGHT),
      new Table({ width:{size:W,type:WidthType.DXA}, columnWidths:[2600,6760], rows:
        [["Business Fit Score","33.8"],["Criticality Score","28.8"],["Technical Fit Score","Not assessed"],["Lifecycle Status","Incomplete Data"],["TIME Position","Cannot be determined. Scores suggest Eliminate or Tolerate."],["Action Required","Determine whether a full technical assessment is warranted given low business fit and criticality scores."]].map(([k,v],i) =>
          new TableRow({ children:[
            new TableCell({ borders, shading:{fill:i%2===0?INC_BG:WHITE,type:ShadingType.CLEAR}, width:{size:2600,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:k,bold:true,size:18,font:"Arial",color:NAVY})]})] }),
            new TableCell({ borders, shading:{fill:i%2===0?INC_BG:WHITE,type:ShadingType.CLEAR}, width:{size:6760,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:v,size:18,font:"Arial",color:DARK})]})] }),
          ]})
        )
      }),
      italic("Note: Geoscience Data Management has both the highest criticality score (60.0) and the highest business fit score (55.0) of the two incomplete applications. Its technical assessment status — in progress — suggests active work is underway. This application warrants priority follow-up before the next portfolio review cycle."),

      pageBreak(),

      // ══════════════════════════════════════════════════════════════════════
      // PAGE 11 — EA HANDOFF
      // ══════════════════════════════════════════════════════════════════════
      spacer(),
      h1("EA Handoff — Open Questions", "handoff"),
      ruled(),
      body("The following questions are surfaced by the assessment data. They are portfolio-wide observations intended to frame the EA team's planning conversations. APM collects data and provides insights — it does not make decisions or prescribe outcomes."),

      ...[
        "IRIS Business Intelligence is positioned in Eliminate with scores close to the quadrant boundary (Business Fit 45.0, Tech Fit 48.0). Given its functional relationship to IRIS — Integrated Resource Information System — the core operational system — what downstream reporting or operational dependencies exist that would affect how any exit or consolidation of the BI layer is planned?",
        "Geoscience Data Management carries the highest criticality score (60.0) of any application without a confirmed TIME position, and its technical assessment is described as in progress. What is the expected completion timeline, and what governance path exists to incorporate it into portfolio planning once complete?",
        "Five Eliminate applications cluster between 38 and 44 on the criticality scale. What data flows, shared infrastructure, or operational dependencies exist between these applications that would affect how any exit or consolidation effort is sequenced?",
        "GeoLogic Geoscout sits on ITDNAS-End-Of-Life infrastructure with the lowest technical fit score in the portfolio (18.0) and active ITSM history. Is there a current infrastructure exit plan for this application, and if not, at what point does the infrastructure end-of-life status become a forcing function for the modernization decision?",
        "IRIS — Integrated Resource Information System is the highest-value asset in the portfolio with a criticality of 88.8 and Crown Jewel designation. What governance mechanism exists to ensure this application's technical currency, platform roadmap, and lifecycle status are actively maintained and visible to the EA team?",
      ].map(q => new Paragraph({
        numbering: { reference:"numbers", level:0 },
        spacing: sp(120, 120),
        children: makeRuns(q)
      })),

      calloutBox([
        new Paragraph({ spacing: sp(0,80), children: [new TextRun({ text: "Suggested Next Assessment Trigger", bold: true, size: 20, font: "Arial", color: NAVY })] }),
        new Paragraph({ spacing: sp(0,0), children: [new TextRun({ text: "Review this portfolio assessment when any Eliminate-quadrant application reaches an infrastructure end-of-life event, contract renewal, or sustained ITSM activity threshold — or when the Geoscience Data Management technical assessment is completed.", size: 20, font: "Arial", italics: true, color: DARK })] }),
      ]),

    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/home/claude/EnergyResources_Portfolio_Assessment_v4.docx', buf);
  console.log('Done');
});
