import { useState, useMemo } from "react";

// ─── Data ──────────────────────────────────────────────────────────────
const BASE_RUN_RATE = 1800000;

const findingsData = [
  { id: "f1", domain: "ti", impact: "high", title: "RHEL 7 End of Support — SirsiDynix Symphony at Risk", rationale: "RHEL 7 reached end of maintenance support. SirsiDynix Symphony library system runs on RHEL 7 with no upgrade path tested.", source: "computed", date: "2026-02-18" },
  { id: "f2", domain: "ti", impact: "medium", title: "Oracle 19c Entering Extended Support Window", rationale: "Oracle 19c premier support ended Oct 2024. Extended support continues through 2028 but at increasing cost premium.", source: "computed", date: "2026-02-18" },
  { id: "f3", domain: "ti", impact: "medium", title: "SQL Server 2016 Approaching End of Support", rationale: "SQL Server 2016 extended support ends July 2026. Three applications depend on this version.", source: "computed", date: "2026-02-18" },
  { id: "f4", domain: "bpa", impact: "high", title: "ERP System Cannot Scale Beyond Current Operations", rationale: "Great Plains cannot handle multi-jurisdiction billing. Manual reconciliation across three systems required monthly.", source: "manual", date: "2026-01-15" },
  { id: "f5", domain: "bpa", impact: "medium", title: "Redundant Systems in Public Safety", rationale: "Police and Fire departments maintain separate dispatch and records systems with overlapping functionality.", source: "manual", date: "2026-01-15" },
  { id: "f6", domain: "cr", impact: "high", title: "No Formal Vulnerability Management Program", rationale: "No scheduled vulnerability scanning. Patching is reactive. No baseline security posture measurement.", source: "manual", date: "2026-01-20" },
  { id: "f7", domain: "icoms", impact: "medium", title: "IT Governance Limited to Operational Support", rationale: "IT operates as help desk. No strategic planning process, no project intake, no portfolio governance.", source: "manual", date: "2026-01-10" },
  { id: "f8", domain: "dqa", impact: "low", title: "Asset Inventory Partially Maintained", rationale: "Hardware asset inventory exists in spreadsheet. No software asset management. No automated discovery.", source: "manual", date: "2026-01-10" },
];

const initialInitiatives = [
  { id: "i1", title: "Upgrade SirsiDynix Infrastructure", domain: "ti", theme: "risk", priority: "critical", horizon: "q1", status: "planned", otcLow: 25000, otcHigh: 45000, rcLow: 2000, rcHigh: 5000, runRate: 3000, finding: "f1", ideaId: null, programs: ["p1"], enabled: true },
  { id: "i2", title: "Vulnerability Management Program", domain: "cr", theme: "risk", priority: "critical", horizon: "q1", status: "in_progress", otcLow: 10000, otcHigh: 20000, rcLow: 8000, rcHigh: 12000, runRate: 10000, finding: "f6", ideaId: null, programs: ["p1"], enabled: true },
  { id: "i3", title: "Migrate SQL Server 2016 → 2022", domain: "ti", theme: "risk", priority: "high", horizon: "q2", status: "planned", otcLow: 15000, otcHigh: 30000, rcLow: 0, rcHigh: 0, runRate: 0, finding: "f3", ideaId: null, programs: ["p1"], enabled: true },
  { id: "i4", title: "IT Strategic Planning Process", domain: "icoms", theme: "optimize", priority: "medium", horizon: "q2", status: "planned", otcLow: 5000, otcHigh: 10000, rcLow: 0, rcHigh: 0, runRate: 0, finding: "f7", ideaId: null, programs: ["p2"], enabled: true },
  { id: "i5", title: "Oracle 19c → 23ai Migration", domain: "ti", theme: "optimize", priority: "medium", horizon: "q3", status: "identified", otcLow: 40000, otcHigh: 80000, rcLow: 0, rcHigh: 0, runRate: -15000, finding: "f2", ideaId: null, programs: ["p1"], enabled: true },
  { id: "i6", title: "ERP Evaluation & Replacement", domain: "bpa", theme: "growth", priority: "high", horizon: "q3", status: "identified", otcLow: 150000, otcHigh: 300000, rcLow: 40000, rcHigh: 60000, runRate: 15000, finding: "f4", ideaId: "idea5", programs: ["p2"], enabled: true },
];

const ideasData = [
  { id: "idea1", title: "Mobile app for field inspectors", description: "Field inspectors currently use paper forms. A mobile app would allow real-time data capture, photo documentation, and GPS tagging.", workspace: "Public Works", domain: "bpa", from: "Mike Thompson", status: "submitted", date: "2026-02-20", reviewNotes: null },
  { id: "idea2", title: "Replace fax with digital forms", description: "We still receive permit applications by fax. Other municipalities have moved to online submission.", workspace: "Community Services", domain: null, from: "Jennifer Lee", status: "submitted", date: "2026-02-18", reviewNotes: null },
  { id: "idea3", title: "Consolidate help desk tools", description: "IT uses three ticketing systems. One platform would improve SLA tracking and reduce license costs.", workspace: "Information Technology", domain: "icoms", from: "Lisa Park", status: "submitted", date: "2026-02-15", reviewNotes: null },
  { id: "idea4", title: "Citizen portal for building permits", description: "Residents visit City Hall in person for building permits. An online portal would reduce wait times.", workspace: "Development Services", domain: "bpa", from: "Lt. Maria Santos", status: "under_review", date: "2026-02-10", reviewNotes: null },
  { id: "idea5", title: "ERP evaluation for billing", description: "Current ERP cannot handle multi-jurisdiction billing. Finance manually reconciles across three systems.", workspace: "Finance", domain: "bpa", from: "Capt. Robert Williams", status: "approved", date: "2026-01-28", reviewNotes: "Approved — aligns with existing ERP finding. Initiative created." },
  { id: "idea6", title: "Replace desktops with iPads", description: "iPads would be more portable. Staff could use them in meetings and in the field.", workspace: "Information Technology", domain: "ti", from: "Sgt. James Chen", status: "declined", date: "2026-01-25", reviewNotes: "Declined — most applications require Windows. Not feasible." },
];

const programsData = [
  { id: "p1", title: "Infrastructure Stabilization", theme: "risk", budget: 200000, fy: "FY2026", driver: "Board mandate: reduce critical technology debt by FY2027.", owner: "Mike Thompson", sponsor: "Lisa Park", status: "active", start: "2026-01-01", end: "2026-12-31", initiatives: ["i1", "i2", "i3", "i5"] },
  { id: "p2", title: "Digital Transformation 2026", theme: "growth", budget: 500000, fy: "FY2026-27", driver: "County billing contract expires Dec 2027. Current ERP cannot handle multi-jurisdiction.", owner: "Jennifer Lee", sponsor: "Capt. Robert Williams", status: "active", start: "2026-04-01", end: "2027-09-30", initiatives: ["i6", "i4"] },
];

const dependenciesData = [
  { source: "i6", target: "i3", type: "requires", notes: "New ERP requires SQL Server 2019+." },
  { source: "i3", target: "i6", type: "enables", notes: "SQL 2022 unlocks ERP options." },
  { source: "i5", target: "i4", type: "requires", notes: "Need strategy framework before Oracle exit." },
  { source: "i4", target: "i5", type: "enables", notes: "IT strategy informs Oracle decision." },
];

// ─── Config ────────────────────────────────────────────────────────────
const domainConfig = {
  ti: { name: "Technology Infrastructure", short: "TI", color: "#6366f1" },
  bpa: { name: "Business Applications", short: "BPA", color: "#f59e0b" },
  cr: { name: "Cybersecurity Risk", short: "CR", color: "#ef4444" },
  icoms: { name: "IT Operating Model", short: "ICOMS", color: "#10b981" },
  dqa: { name: "Data Quality", short: "DQA", color: "#8b5cf6" },
};

const themeColors = {
  risk: { bg: "#fef2f2", border: "#fecaca", text: "#b91c1c", dot: "#ef4444", light: "#fee2e2" },
  optimize: { bg: "#ecfdf5", border: "#a7f3d0", text: "#047857", dot: "#10b981", light: "#d1fae5" },
  growth: { bg: "#eff6ff", border: "#bfdbfe", text: "#1d4ed8", dot: "#3b82f6", light: "#dbeafe" },
};

const statusList = [
  { id: "identified", label: "Identified", icon: "○", color: "#6b7280" },
  { id: "planned", label: "Planned", icon: "◎", color: "#2563eb" },
  { id: "in_progress", label: "In Progress", icon: "◉", color: "#d97706" },
  { id: "completed", label: "Completed", icon: "●", color: "#059669" },
];

const ideaStatusCfg = {
  submitted: { icon: "📬", color: "#2563eb", bg: "#eff6ff", label: "New" },
  under_review: { icon: "👀", color: "#d97706", bg: "#fffbeb", label: "Review" },
  approved: { icon: "✅", color: "#059669", bg: "#ecfdf5", label: "Approved" },
  declined: { icon: "❌", color: "#dc2626", bg: "#fef2f2", label: "Declined" },
  deferred: { icon: "⏸", color: "#6b7280", bg: "#f3f4f6", label: "Deferred" },
};

const quarters = [
  { id: "q1", label: "Q1", sub: "0–3 mo" },
  { id: "q2", label: "Q2", sub: "3–6 mo" },
  { id: "q3", label: "Q3", sub: "6–9 mo" },
  { id: "q4", label: "Q4", sub: "9–12 mo" },
  { id: "beyond", label: "FY28+", sub: "12+ mo" },
];

const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
const priorityColors = { critical: "#dc2626", high: "#ea580c", medium: "#6b7280", low: "#9ca3af" };

const fmt = (v, compact) => {
  if (v === 0) return "$0";
  const abs = Math.abs(v);
  if (compact && abs >= 1000000) return `${v < 0 ? "-" : ""}$${(abs / 1000000).toFixed(1)}M`;
  if (compact && abs >= 1000) return `${v < 0 ? "-" : ""}$${(abs / 1000).toFixed(0)}K`;
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(v);
};

const ff = "'DM Sans', sans-serif";
const fm = "'JetBrains Mono', monospace";
const getDeps = (id) => dependenciesData.filter(d => d.source === id);
const midCost = (i) => (i.otcLow + i.otcHigh) / 2;

// ─── Shared Micro-Components ───────────────────────────────────────────
const Chip = ({ children, bg, color, border, small }) => (
  <span style={{ display: "inline-flex", alignItems: "center", gap: 3, padding: small ? "1px 6px" : "2px 8px", borderRadius: 4, fontSize: small ? 10 : 11, fontWeight: 600, fontFamily: ff, background: bg || "#f3f4f6", color: color || "#6b7280", border: `1px solid ${border || bg || "#e5e7eb"}`, whiteSpace: "nowrap" }}>{children}</span>
);

const RunRate = ({ value, large }) => {
  if (!value || value === 0) return <span style={{ fontFamily: fm, fontSize: large ? 13 : 11, color: "#d1d5db" }}>—</span>;
  const pos = value > 0;
  return <span style={{ fontFamily: fm, fontSize: large ? 13 : 11, fontWeight: 600, color: pos ? "#dc2626" : "#059669" }}>{pos ? "+" : ""}{fmt(value, true)}/yr</span>;
};

const PriorityDot = ({ p }) => <span style={{ display: "inline-block", width: 7, height: 7, borderRadius: "50%", background: priorityColors[p] || "#d1d5db", flexShrink: 0 }} />;

// ─── Initiative Card (shared across Gantt & Kanban) ────────────────────
const InitCard = ({ init, onToggle, isDragging, compact, onClick, selected }) => {
  const tc = themeColors[init.theme];
  const deps = getDeps(init.id);
  return (
    <div
      draggable
      onClick={onClick}
      style={{
        padding: compact ? "6px 8px" : "8px 10px", marginBottom: 4, borderRadius: 6,
        background: selected ? "#f0fdfa" : "#fff",
        border: `1px solid ${selected ? "#0d9488" : "#e5e7eb"}`,
        borderLeft: `3px solid ${tc.dot}`,
        cursor: "grab", opacity: isDragging ? 0.35 : 1,
        transition: "all 0.12s",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 4 }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 6, flex: 1, minWidth: 0 }}>
          <PriorityDot p={init.priority} />
          <span style={{ fontSize: 12, fontWeight: 600, color: "#1e293b", fontFamily: ff, lineHeight: 1.3, overflow: "hidden", textOverflow: "ellipsis" }}>{init.title}</span>
        </div>
        {onToggle && <button onClick={e => { e.stopPropagation(); onToggle(init.id); }} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 9, color: "#cbd5e1", padding: 0, lineHeight: 1 }}>✕</button>}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 4 }}>
        <span style={{ fontFamily: fm, fontSize: 11, color: "#475569" }}>{fmt(midCost(init), true)}</span>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          {deps.length > 0 && <span style={{ fontSize: 9, color: "#7c3aed", fontFamily: fm }}>🔗{deps.length}</span>}
          <RunRate value={init.runRate} />
        </div>
      </div>
    </div>
  );
};

// ─── KPI Bar (shared across all views) ─────────────────────────────────
const KpiBar = ({ initiatives }) => {
  const active = initiatives.filter(i => i.enabled);
  const totalInvest = active.reduce((s, i) => s + midCost(i), 0);
  const totalRunRate = active.reduce((s, i) => s + i.runRate, 0);
  const newRecurring = active.reduce((s, i) => s + (i.rcLow + i.rcHigh) / 2, 0);
  const projected = BASE_RUN_RATE + totalRunRate;
  const inProgress = active.filter(i => i.status === "in_progress").length;

  const items = [
    { label: "Active Initiatives", value: <><span style={{ fontSize: 24 }}>{active.length}</span><span style={{ fontSize: 14, color: "#94a3b8" }}> / {initiatives.length}</span></> },
    { label: "Total Investment", value: fmt(totalInvest, true) },
    { label: "New Recurring", value: <>{fmt(newRecurring, true)}<span style={{ fontSize: 12, color: "#94a3b8" }}>/yr</span></> },
    { label: "Net Run Rate Δ", value: <RunRate value={totalRunRate} large /> },
    { label: "Projected Run Rate", value: <>{fmt(projected, true)}<span style={{ fontSize: 12, color: "#94a3b8" }}>/yr</span></> },
  ];

  return (
    <div style={{ display: "flex", gap: 1, background: "#e5e7eb", borderRadius: 8, overflow: "hidden", marginBottom: 16 }}>
      {items.map((item, idx) => (
        <div key={idx} style={{ flex: 1, background: "#fff", padding: "10px 16px", textAlign: "center" }}>
          <div style={{ fontSize: 10, fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.6, color: "#94a3b8", fontFamily: ff }}>{item.label}</div>
          <div style={{ fontSize: 18, fontWeight: 700, fontFamily: fm, color: item.accent || "#0f172a", marginTop: 2 }}>{item.value}</div>
          <div style={{ fontSize: 10, color: "#cbd5e1", fontFamily: ff }}>{item.sub}</div>
        </div>
      ))}
    </div>
  );
};

// ─── GANTT VIEW (row-based horizontal timeline) ────────────────────────
const ganttQuarters = [
  { id: "q1", label: "Q1", sub: "Mar–May '26" },
  { id: "q2", label: "Q2", sub: "Jun–Aug '26" },
  { id: "q3", label: "Q3", sub: "Sep–Nov '26" },
  { id: "q4", label: "Q4", sub: "Dec '26–Feb '27" },
  { id: "beyond", label: "FY28+", sub: "Mar '27+" },
];

function GanttView({ initiatives, setInitiatives, selectedId, setSelectedId }) {
  const [dragId, setDragId] = useState(null);
  const [hoveredQ, setHoveredQ] = useState(null);

  const active = initiatives.filter(i => i.enabled);
  const sorted = useMemo(() => [...initiatives].sort((a, b) => {
    const hOrder = { q1: 0, q2: 1, q3: 2, q4: 3, beyond: 4 };
    return hOrder[a.horizon] - hOrder[b.horizon] || priorityOrder[a.priority] - priorityOrder[b.priority];
  }), [initiatives]);

  const move = (id, q) => setInitiatives(prev => prev.map(i => i.id === id ? { ...i, horizon: q } : i));
  const toggle = (id) => setInitiatives(prev => prev.map(i => i.id === id ? { ...i, enabled: !i.enabled } : i));

  // Quarter totals
  const qTotals = useMemo(() => {
    const t = {};
    ganttQuarters.forEach(q => { t[q.id] = { otc: 0, rr: 0 }; });
    active.forEach(i => { t[i.horizon].otc += midCost(i); t[i.horizon].rr += i.runRate; });
    return t;
  }, [active]);

  const barColors = { risk: "#ef4444", optimize: "#10b981", growth: "#3b82f6" };

  return (
    <div style={{ background: "#fff", border: "1px solid #e5e7eb", borderRadius: 10, overflow: "hidden" }}>
      {/* Legend */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 16px", borderBottom: "1px solid #f1f5f9" }}>
        <span style={{ fontSize: 14, fontWeight: 700, color: "#0f172a", fontFamily: ff }}>Initiative Timeline</span>
        <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
          {[{ t: "Risk", c: "#ef4444" }, { t: "Optimize", c: "#10b981" }, { t: "Growth", c: "#3b82f6" }].map(l => (
            <span key={l.t} style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11, color: "#64748b", fontFamily: ff }}>
              <span style={{ width: 10, height: 10, borderRadius: "50%", background: l.c }} />{l.t}
            </span>
          ))}
          <span style={{ fontSize: 11, color: "#cbd5e1", fontFamily: ff }}>| Drag to reschedule</span>
        </div>
      </div>

      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        {/* Header */}
        <thead>
          <tr style={{ borderBottom: "2px solid #e5e7eb" }}>
            <th style={{ width: 280, textAlign: "left", padding: "10px 14px", fontSize: 10, fontWeight: 700, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 0.6, fontFamily: ff }}>Initiative</th>
            {ganttQuarters.map(q => (
              <th key={q.id} style={{ textAlign: "center", padding: "10px 8px", borderLeft: "1px solid #f1f5f9" }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: "#0f172a", fontFamily: ff }}>{q.label}</div>
                <div style={{ fontSize: 10, color: "#94a3b8", fontFamily: ff }}>{q.sub}</div>
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {sorted.map(init => {
            const tc = themeColors[init.theme];
            const deps = getDeps(init.id);
            const isSelected = selectedId === init.id;

            return (
              <tr key={init.id} style={{ borderBottom: "1px solid #f1f5f9", background: isSelected ? "#f0fdfa" : init.enabled ? "#fff" : "#fafafa", opacity: init.enabled ? 1 : 0.45, transition: "all 0.12s" }}>
                {/* Initiative label */}
                <td style={{ padding: "10px 14px", width: 280 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <button onClick={() => toggle(init.id)} style={{
                      width: 22, height: 22, borderRadius: 6, border: `2px solid ${init.enabled ? "#0d9488" : "#d1d5db"}`,
                      background: init.enabled ? "#0d9488" : "#fff", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
                      fontSize: 12, color: "#fff", flexShrink: 0, transition: "all 0.12s",
                    }}>{init.enabled ? "✓" : ""}</button>
                    <div style={{ minWidth: 0, cursor: "pointer" }} onClick={() => setSelectedId(isSelected ? null : init.id)}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "#0f172a", fontFamily: ff, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", maxWidth: 200 }}>{init.title}</div>
                      <div style={{ display: "flex", gap: 6, marginTop: 3, alignItems: "center" }}>
                        <Chip bg={tc.bg} color={tc.text} border={tc.border} small>{init.theme.charAt(0).toUpperCase() + init.theme.slice(1)}</Chip>
                        <span style={{ fontFamily: fm, fontSize: 11, color: "#64748b" }}>{fmt(midCost(init), true)}</span>
                        {deps.length > 0 && <span style={{ fontSize: 9, color: "#7c3aed", fontFamily: fm }}>🔗{deps.length}</span>}
                      </div>
                    </div>
                  </div>
                </td>

                {/* Quarter cells */}
                {ganttQuarters.map(q => {
                  const isHere = init.horizon === q.id && init.enabled;
                  const isHover = hoveredQ === `${init.id}-${q.id}`;
                  return (
                    <td
                      key={q.id}
                      onDragOver={e => { e.preventDefault(); setHoveredQ(`${init.id}-${q.id}`); }}
                      onDragLeave={() => setHoveredQ(null)}
                      onDrop={e => { e.preventDefault(); if (dragId) move(dragId, q.id); setDragId(null); setHoveredQ(null); }}
                      style={{ padding: "8px 6px", borderLeft: "1px solid #f1f5f9", textAlign: "center", verticalAlign: "middle", background: isHover && !isHere ? "#f0fdfa" : "transparent", transition: "background 0.1s" }}
                    >
                      {isHere && (
                        <div
                          draggable
                          onDragStart={() => setDragId(init.id)}
                          onDragEnd={() => { setDragId(null); setHoveredQ(null); }}
                          style={{
                            background: barColors[init.theme] || "#6b7280",
                            borderRadius: 6, padding: "7px 10px", cursor: "grab",
                            opacity: dragId === init.id ? 0.35 : 1,
                            display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
                            transition: "opacity 0.12s", minWidth: 0,
                          }}
                        >
                          <span style={{ fontSize: 12, fontWeight: 600, color: "#fff", fontFamily: ff, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                            {init.title.length > 20 ? init.title.slice(0, 18) + "…" : init.title}
                          </span>
                          {init.runRate !== 0 && (
                            <span style={{ fontSize: 10, fontFamily: fm, color: "rgba(255,255,255,0.85)", whiteSpace: "nowrap", flexShrink: 0 }}>
                              {init.runRate > 0 ? "+" : ""}{fmt(init.runRate, true)}
                            </span>
                          )}
                        </div>
                      )}
                    </td>
                  );
                })}
              </tr>
            );
          })}
        </tbody>

        {/* Quarter totals */}
        <tfoot>
          <tr style={{ borderTop: "2px solid #e5e7eb", background: "#f8fafc" }}>
            <td style={{ padding: "10px 14px", fontSize: 11, fontWeight: 700, color: "#94a3b8", fontFamily: ff, textTransform: "uppercase", letterSpacing: 0.6 }}>Quarter Totals</td>
            {ganttQuarters.map(q => {
              const t = qTotals[q.id];
              return (
                <td key={q.id} style={{ textAlign: "center", padding: "10px 8px", borderLeft: "1px solid #f1f5f9" }}>
                  <div style={{ fontFamily: fm, fontSize: 14, fontWeight: 700, color: t.otc > 0 ? "#0f172a" : "#cbd5e1" }}>{t.otc > 0 ? fmt(t.otc, true) : "$0"}</div>
                  {t.rr !== 0 && <div style={{ marginTop: 2 }}><RunRate value={t.rr} /></div>}
                </td>
              );
            })}
          </tr>
        </tfoot>
      </table>

      {/* Excluded pool */}
      {initiatives.filter(i => !i.enabled).length > 0 && (
        <div style={{ padding: "10px 16px", borderTop: "1px solid #f1f5f9", background: "#fafafa" }}>
          <span style={{ fontSize: 10, fontWeight: 600, color: "#94a3b8", fontFamily: ff, marginRight: 8 }}>EXCLUDED:</span>
          {initiatives.filter(i => !i.enabled).map(init => (
            <button key={init.id} onClick={() => toggle(init.id)} style={{ padding: "3px 8px", borderRadius: 4, border: "1px dashed #cbd5e1", background: "#fff", color: "#94a3b8", fontSize: 11, fontFamily: ff, cursor: "pointer", marginRight: 4 }}>+ {init.title}</button>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── KANBAN VIEW ───────────────────────────────────────────────────────
function KanbanView({ initiatives, setInitiatives, selectedId, setSelectedId }) {
  const [dragId, setDragId] = useState(null);
  const [hoveredCol, setHoveredCol] = useState(null);

  const active = initiatives.filter(i => i.enabled);
  const changeStatus = (id, newStatus) => setInitiatives(prev => prev.map(i => i.id === id ? { ...i, status: newStatus } : i));
  const toggle = (id) => setInitiatives(prev => prev.map(i => i.id === id ? { ...i, enabled: !i.enabled } : i));

  return (
    <div>
      <div style={{ display: "grid", gridTemplateColumns: `repeat(${statusList.length}, 1fr)`, gap: 8 }}>
        {statusList.map(col => {
          const items = active.filter(i => i.status === col.id).sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
          const colCost = items.reduce((s, i) => s + midCost(i), 0);
          return (
            <div
              key={col.id}
              onDragOver={e => { e.preventDefault(); setHoveredCol(col.id); }}
              onDragLeave={() => setHoveredCol(null)}
              onDrop={e => { e.preventDefault(); if (dragId) changeStatus(dragId, col.id); setDragId(null); setHoveredCol(null); }}
              style={{
                minHeight: 240, borderRadius: 8,
                background: hoveredCol === col.id ? "#f0fdfa" : "#f8fafc",
                border: `1.5px ${hoveredCol === col.id ? "solid" : "dashed"} ${hoveredCol === col.id ? "#0d9488" : "#e2e8f0"}`,
                transition: "all 0.12s",
              }}
            >
              <div style={{ padding: "10px 10px 8px", borderBottom: "1px solid #e2e8f0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <span style={{ fontSize: 14, color: col.color }}>{col.icon}</span>
                  <span style={{ fontSize: 13, fontWeight: 700, color: "#0f172a", fontFamily: ff }}>{col.label}</span>
                  <span style={{ fontSize: 11, fontFamily: fm, color: "#94a3b8", fontWeight: 500 }}>{items.length}</span>
                </div>
                {colCost > 0 && <span style={{ fontSize: 10, fontFamily: fm, color: "#64748b" }}>{fmt(colCost, true)}</span>}
              </div>
              <div style={{ padding: 8 }}>
                {items.map(init => (
                  <div key={init.id} draggable onDragStart={() => setDragId(init.id)} onDragEnd={() => setDragId(null)}>
                    <InitCard init={init} onToggle={toggle} isDragging={dragId === init.id} onClick={() => setSelectedId(selectedId === init.id ? null : init.id)} selected={selectedId === init.id} />
                  </div>
                ))}
                {items.length === 0 && <div style={{ textAlign: "center", padding: 32, color: "#e2e8f0", fontSize: 11, fontFamily: ff }}>Drop here</div>}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── GRID VIEW ─────────────────────────────────────────────────────────
function GridView({ initiatives, selectedId, setSelectedId }) {
  const [sortBy, setSortBy] = useState("priority");

  const active = initiatives.filter(i => i.enabled);
  const sorted = useMemo(() => {
    let list = [...active];
    const hOrder = { q1: 0, q2: 1, q3: 2, q4: 3, beyond: 4 };
    if (sortBy === "priority") list.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
    if (sortBy === "horizon") list.sort((a, b) => hOrder[a.horizon] - hOrder[b.horizon]);
    if (sortBy === "cost") list.sort((a, b) => midCost(b) - midCost(a));
    if (sortBy === "status") list.sort((a, b) => statusList.findIndex(s => s.id === a.status) - statusList.findIndex(s => s.id === b.status));
    return list;
  }, [active, sortBy]);

  return (
    <div>
      <div style={{ display: "flex", gap: 4, marginBottom: 10 }}>
        <span style={{ fontSize: 10, fontWeight: 600, color: "#94a3b8", fontFamily: ff, alignSelf: "center", marginRight: 4 }}>SORT</span>
        {["priority", "horizon", "cost", "status"].map(s => (
          <button key={s} onClick={() => setSortBy(s)} style={{ padding: "3px 8px", borderRadius: 4, fontSize: 10, fontWeight: 600, fontFamily: ff, cursor: "pointer", border: `1px solid ${sortBy === s ? "#0d9488" : "#e5e7eb"}`, background: sortBy === s ? "#f0fdfa" : "#fff", color: sortBy === s ? "#0d9488" : "#94a3b8", textTransform: "capitalize" }}>{s}</button>
        ))}
      </div>
      <div style={{ background: "#fff", border: "1px solid #e5e7eb", borderRadius: 8, overflow: "hidden" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontFamily: ff, fontSize: 12 }}>
          <thead>
            <tr style={{ background: "#f8fafc", borderBottom: "1px solid #e5e7eb" }}>
              <th style={{ textAlign: "left", padding: "8px 10px", fontWeight: 600, color: "#94a3b8", fontSize: 10 }}>Initiative</th>
              <th style={{ textAlign: "center", padding: "8px 6px", fontWeight: 600, color: "#94a3b8", fontSize: 10, width: 80 }}>Status</th>
              <th style={{ textAlign: "center", padding: "8px 6px", fontWeight: 600, color: "#94a3b8", fontSize: 10, width: 50 }}>When</th>
              <th style={{ textAlign: "center", padding: "8px 6px", fontWeight: 600, color: "#94a3b8", fontSize: 10, width: 60 }}>Theme</th>
              <th style={{ textAlign: "right", padding: "8px 6px", fontWeight: 600, color: "#94a3b8", fontSize: 10, width: 70 }}>Cost</th>
              <th style={{ textAlign: "right", padding: "8px 10px", fontWeight: 600, color: "#94a3b8", fontSize: 10, width: 80 }}>Δ Run Rate</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map(init => {
              const deps = getDeps(init.id);
              const sc = statusList.find(s => s.id === init.status);
              const tc = themeColors[init.theme];
              return (
                <tr key={init.id} onClick={() => setSelectedId(selectedId === init.id ? null : init.id)} style={{ cursor: "pointer", background: selectedId === init.id ? "#f0fdfa" : "transparent", borderBottom: "1px solid #f1f5f9", transition: "background 0.1s" }}>
                  <td style={{ padding: "8px 10px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                      <PriorityDot p={init.priority} />
                      <span style={{ fontWeight: 600, color: "#0f172a" }}>{init.title}</span>
                      {deps.length > 0 && <span style={{ fontSize: 9, color: "#7c3aed", fontFamily: fm }}>🔗{deps.length}</span>}
                      {init.ideaId && <span style={{ fontSize: 9 }}>💡</span>}
                    </div>
                  </td>
                  <td style={{ textAlign: "center", padding: "8px 6px" }}><Chip bg={sc?.color + "18"} color={sc?.color} small>{sc?.icon} {sc?.label}</Chip></td>
                  <td style={{ textAlign: "center", padding: "8px 6px", fontFamily: fm, fontSize: 11, color: "#64748b" }}>{quarters.find(q => q.id === init.horizon)?.label}</td>
                  <td style={{ textAlign: "center", padding: "8px 6px" }}><Chip bg={tc.bg} color={tc.text} border={tc.border} small>{themeColors[init.theme] && init.theme.charAt(0).toUpperCase() + init.theme.slice(1)}</Chip></td>
                  <td style={{ textAlign: "right", padding: "8px 6px", fontFamily: fm, fontWeight: 500, color: "#0f172a" }}>{fmt(midCost(init), true)}</td>
                  <td style={{ textAlign: "right", padding: "8px 10px" }}><RunRate value={init.runRate} /></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ─── DETAIL PANEL ──────────────────────────────────────────────────────
function DetailPanel({ init, onClose }) {
  if (!init) return null;
  const tc = themeColors[init.theme];
  const sc = statusList.find(s => s.id === init.status);
  const deps = getDeps(init.id);
  const finding = findingsData.find(f => f.id === init.finding);

  return (
    <div style={{ background: "#fff", border: "1px solid #e5e7eb", borderRadius: 8, borderTop: `3px solid ${tc.dot}`, padding: 16, fontSize: 12, fontFamily: ff }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10 }}>
        <h4 style={{ fontSize: 14, fontWeight: 700, color: "#0f172a", margin: 0 }}>{init.title}</h4>
        <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "#cbd5e1", fontSize: 14 }}>✕</button>
      </div>

      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 14 }}>
        <Chip bg={tc.bg} color={tc.text} border={tc.border}>{init.theme}</Chip>
        <Chip bg={sc?.color + "18"} color={sc?.color}>{sc?.icon} {sc?.label}</Chip>
        <Chip bg={priorityColors[init.priority] + "18"} color={priorityColors[init.priority]}>{init.priority}</Chip>
        <Chip bg="#f3f4f6" color="#64748b">{quarters.find(q => q.id === init.horizon)?.label} · {quarters.find(q => q.id === init.horizon)?.sub}</Chip>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 14 }}>
        <div style={{ padding: 10, background: "#f8fafc", borderRadius: 6 }}>
          <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 0.4 }}>One-Time Cost</div>
          <div style={{ fontFamily: fm, fontSize: 15, fontWeight: 700, color: "#0f172a", marginTop: 2 }}>{fmt(midCost(init), true)}</div>
          <div style={{ fontFamily: fm, fontSize: 10, color: "#94a3b8" }}>{fmt(init.otcLow)} – {fmt(init.otcHigh)}</div>
        </div>
        <div style={{ padding: 10, background: "#f8fafc", borderRadius: 6 }}>
          <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 0.4 }}>Run Rate Impact</div>
          <div style={{ marginTop: 2 }}><RunRate value={init.runRate} large /></div>
          <div style={{ fontFamily: fm, fontSize: 10, color: "#94a3b8" }}>annual change</div>
        </div>
      </div>

      {finding && (
        <div style={{ padding: 8, background: "#faf5ff", borderRadius: 6, border: "1px solid #ede9fe", marginBottom: 10 }}>
          <div style={{ fontSize: 9, fontWeight: 600, color: "#7c3aed", textTransform: "uppercase", letterSpacing: 0.4 }}>Source Finding</div>
          <div style={{ fontSize: 12, color: "#374151", marginTop: 2 }}>{finding.title}</div>
        </div>
      )}

      {init.programs.length > 0 && (
        <div style={{ marginBottom: 10 }}>
          <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 0.4, marginBottom: 4 }}>Programs</div>
          {init.programs.map(pid => {
            const prog = programsData.find(p => p.id === pid);
            return prog && (
              <div key={pid} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "5px 8px", background: "#f8fafc", borderRadius: 4, marginBottom: 3 }}>
                <span style={{ fontSize: 12, color: "#374151" }}>📁 {prog.title}</span>
                <span style={{ fontFamily: fm, fontSize: 10, color: "#94a3b8" }}>{fmt(prog.budget, true)}</span>
              </div>
            );
          })}
        </div>
      )}

      {deps.length > 0 && (
        <div>
          <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 0.4, marginBottom: 4 }}>Dependencies</div>
          {deps.map((dep, idx) => {
            const target = initialInitiatives.find(i => i.id === dep.target);
            const isReq = dep.type === "requires";
            return (
              <div key={idx} style={{ display: "flex", alignItems: "center", gap: 6, padding: "5px 8px", background: isReq ? "#fef2f2" : "#ecfdf5", borderRadius: 4, marginBottom: 3, border: `1px solid ${isReq ? "#fecaca" : "#a7f3d0"}` }}>
                <span style={{ fontFamily: fm, fontSize: 9, fontWeight: 700, color: isReq ? "#dc2626" : "#059669", width: 52, flexShrink: 0 }}>{isReq ? "⬆ NEEDS" : "⬇ UNLOCKS"}</span>
                <span style={{ fontSize: 11, color: "#374151" }}>{target?.title}</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ─── SCORECARD TAB ─────────────────────────────────────────────────────
function ScorecardTab() {
  const [expanded, setExpanded] = useState(null);
  const domains = useMemo(() => {
    const g = {};
    findingsData.forEach(f => {
      if (!g[f.domain]) g[f.domain] = { domain: f.domain, findings: [], high: 0, medium: 0, low: 0 };
      g[f.domain].findings.push(f);
      g[f.domain][f.impact]++;
    });
    return Object.values(g).sort((a, b) => (b.high * 100 + b.medium * 10) - (a.high * 100 + a.medium * 10));
  }, []);

  return (
    <div>
      <div style={{ display: "flex", gap: 1, background: "#e5e7eb", borderRadius: 8, overflow: "hidden", marginBottom: 16 }}>
        {[
          { l: "High", v: findingsData.filter(f => f.impact === "high").length, c: "#dc2626", bg: "#fef2f2" },
          { l: "Medium", v: findingsData.filter(f => f.impact === "medium").length, c: "#d97706", bg: "#fffbeb" },
          { l: "Low", v: findingsData.filter(f => f.impact === "low").length, c: "#059669", bg: "#ecfdf5" },
          { l: "Total", v: findingsData.length, c: "#0f172a", bg: "#fff" },
        ].map((item, idx) => (
          <div key={idx} style={{ flex: 1, background: item.bg, padding: "10px 16px", textAlign: "center" }}>
            <div style={{ fontSize: 10, fontWeight: 600, color: "#94a3b8", fontFamily: ff, textTransform: "uppercase" }}>{item.l}</div>
            <div style={{ fontSize: 22, fontWeight: 700, fontFamily: fm, color: item.c }}>{item.v}</div>
          </div>
        ))}
      </div>

      {domains.map(d => {
        const dc = domainConfig[d.domain];
        const isOpen = expanded === d.domain;
        return (
          <div key={d.domain} onClick={() => setExpanded(isOpen ? null : d.domain)} style={{ background: "#fff", border: "1px solid #e5e7eb", borderLeft: `4px solid ${dc.color}`, borderRadius: 8, padding: "12px 14px", marginBottom: 6, cursor: "pointer" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontFamily: fm, fontSize: 10, fontWeight: 700, color: dc.color, width: 44 }}>{dc.short}</span>
                <span style={{ fontFamily: ff, fontSize: 13, fontWeight: 600, color: "#0f172a" }}>{dc.name}</span>
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                {d.high > 0 && <span style={{ display: "inline-flex", alignItems: "center", gap: 2 }}><span style={{ width: 8, height: 8, borderRadius: "50%", background: "#ef4444", display: "inline-block" }} /><span style={{ fontSize: 11, fontFamily: fm, color: "#dc2626" }}>{d.high}</span></span>}
                {d.medium > 0 && <span style={{ display: "inline-flex", alignItems: "center", gap: 2 }}><span style={{ width: 8, height: 8, borderRadius: "50%", background: "#f59e0b", display: "inline-block" }} /><span style={{ fontSize: 11, fontFamily: fm, color: "#d97706" }}>{d.medium}</span></span>}
                {d.low > 0 && <span style={{ display: "inline-flex", alignItems: "center", gap: 2 }}><span style={{ width: 8, height: 8, borderRadius: "50%", background: "#10b981", display: "inline-block" }} /><span style={{ fontSize: 11, fontFamily: fm, color: "#059669" }}>{d.low}</span></span>}
                <span style={{ fontSize: 11, color: "#cbd5e1", transition: "transform 0.2s", transform: isOpen ? "rotate(180deg)" : "none" }}>▾</span>
              </div>
            </div>
            {isOpen && (
              <div style={{ marginTop: 10, paddingTop: 8, borderTop: "1px solid #f1f5f9" }}>
                {d.findings.map(finding => (
                  <div key={finding.id} style={{ padding: "6px 0", borderBottom: "1px solid #f8fafc", display: "flex", gap: 8, alignItems: "flex-start" }}>
                    <span style={{ width: 8, height: 8, borderRadius: "50%", background: finding.impact === "high" ? "#ef4444" : finding.impact === "medium" ? "#f59e0b" : "#10b981", marginTop: 4, flexShrink: 0 }} />
                    <div>
                      <div style={{ fontSize: 12, fontWeight: 500, color: "#0f172a", fontFamily: ff }}>{finding.title}</div>
                      <div style={{ fontSize: 11, color: "#64748b", fontFamily: ff, marginTop: 1 }}>{finding.rationale}</div>
                      <div style={{ display: "flex", gap: 6, marginTop: 3 }}>
                        <Chip bg={finding.source === "computed" ? "#eff6ff" : "#f3f4f6"} color={finding.source === "computed" ? "#2563eb" : "#6b7280"} small>{finding.source === "computed" ? "⚡ Auto" : "✍ Manual"}</Chip>
                        <span style={{ fontSize: 10, fontFamily: fm, color: "#cbd5e1" }}>{finding.date}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

// ─── IDEAS TAB ─────────────────────────────────────────────────────────
function IdeasTab() {
  const [filter, setFilter] = useState("all");
  const [selected, setSelected] = useState(null);
  const filtered = filter === "all" ? ideasData : ideasData.filter(i => i.status === filter);
  const pending = ideasData.filter(i => ["submitted", "under_review"].includes(i.status)).length;

  return (
    <div>
      <div style={{ display: "flex", gap: 1, background: "#e5e7eb", borderRadius: 8, overflow: "hidden", marginBottom: 16 }}>
        {[
          { l: "Pending", v: pending, c: "#2563eb", bg: "#eff6ff" },
          { l: "Approved", v: ideasData.filter(i => i.status === "approved").length, c: "#059669", bg: "#ecfdf5" },
          { l: "Declined", v: ideasData.filter(i => i.status === "declined").length, c: "#dc2626", bg: "#fef2f2" },
          { l: "Total", v: ideasData.length, c: "#0f172a", bg: "#fff" },
        ].map((item, idx) => (
          <div key={idx} style={{ flex: 1, background: item.bg, padding: "10px 16px", textAlign: "center" }}>
            <div style={{ fontSize: 10, fontWeight: 600, color: "#94a3b8", fontFamily: ff, textTransform: "uppercase" }}>{item.l}</div>
            <div style={{ fontSize: 22, fontWeight: 700, fontFamily: fm, color: item.c }}>{item.v}</div>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", gap: 4, marginBottom: 12 }}>
        {[{ k: "all", l: "All" }, { k: "submitted", l: "📬 New" }, { k: "under_review", l: "👀 Review" }, { k: "approved", l: "✅ Approved" }, { k: "declined", l: "❌ Declined" }].map(f => (
          <button key={f.k} onClick={() => setFilter(f.k)} style={{ padding: "4px 10px", borderRadius: 5, border: `1px solid ${filter === f.k ? "#0d9488" : "#e5e7eb"}`, background: filter === f.k ? "#f0fdfa" : "#fff", color: filter === f.k ? "#0d9488" : "#94a3b8", fontSize: 11, fontWeight: 600, fontFamily: ff, cursor: "pointer" }}>{f.l}</button>
        ))}
      </div>

      <div style={{ display: "flex", gap: 12 }}>
        <div style={{ flex: selected ? "0 0 55%" : 1, display: "flex", flexDirection: "column", gap: 4 }}>
          {filtered.map(idea => {
            const sc = ideaStatusCfg[idea.status];
            return (
              <div key={idea.id} onClick={() => setSelected(idea)} style={{ background: selected?.id === idea.id ? "#f0fdfa" : "#fff", border: `1px solid ${selected?.id === idea.id ? "#0d9488" : "#e5e7eb"}`, borderLeft: `3px solid ${sc.color}`, borderRadius: 6, padding: "10px 12px", cursor: "pointer" }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ fontSize: 13, fontWeight: 600, color: "#0f172a", fontFamily: ff }}>{idea.title}</span>
                  <span style={{ fontSize: 10, fontFamily: fm, color: "#cbd5e1" }}>{idea.date}</span>
                </div>
                <div style={{ display: "flex", gap: 6, marginTop: 4, alignItems: "center" }}>
                  <Chip bg={sc.bg} color={sc.color} small>{sc.icon} {sc.label}</Chip>
                  {idea.domain && <Chip small>{domainConfig[idea.domain]?.short}</Chip>}
                  <span style={{ fontSize: 10, color: "#94a3b8", fontFamily: ff }}>{idea.workspace} · {idea.from}</span>
                </div>
              </div>
            );
          })}
        </div>

        {selected && (
          <div style={{ flex: "0 0 43%" }}>
            <div style={{ background: "#fff", border: "1px solid #e5e7eb", borderTop: `3px solid ${ideaStatusCfg[selected.status].color}`, borderRadius: 8, padding: 16, fontFamily: ff }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10 }}>
                <h4 style={{ fontSize: 14, fontWeight: 700, color: "#0f172a", margin: 0 }}>{selected.title}</h4>
                <button onClick={() => setSelected(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#cbd5e1", fontSize: 14 }}>✕</button>
              </div>
              <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
                <Chip bg={ideaStatusCfg[selected.status].bg} color={ideaStatusCfg[selected.status].color}>{ideaStatusCfg[selected.status].icon} {ideaStatusCfg[selected.status].label}</Chip>
                {selected.domain && <Chip>{domainConfig[selected.domain]?.name}</Chip>}
              </div>
              <div style={{ fontSize: 12, color: "#374151", lineHeight: 1.6, padding: 10, background: "#f8fafc", borderRadius: 6, marginBottom: 12 }}>{selected.description}</div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6, fontSize: 11, marginBottom: 12 }}>
                <div><span style={{ color: "#94a3b8" }}>From:</span> <span style={{ color: "#0f172a", fontWeight: 500 }}>{selected.from}</span></div>
                <div><span style={{ color: "#94a3b8" }}>Workspace:</span> <span style={{ color: "#0f172a", fontWeight: 500 }}>{selected.workspace}</span></div>
              </div>
              {selected.reviewNotes && (
                <div style={{ padding: 10, background: selected.status === "approved" ? "#ecfdf5" : "#fef2f2", borderRadius: 6, border: `1px solid ${selected.status === "approved" ? "#a7f3d0" : "#fecaca"}`, marginBottom: 12 }}>
                  <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", textTransform: "uppercase", marginBottom: 2 }}>Review Notes</div>
                  <div style={{ fontSize: 12, color: "#374151", lineHeight: 1.5 }}>{selected.reviewNotes}</div>
                </div>
              )}
              {selected.status === "approved" && <div style={{ padding: 8, background: "#eff6ff", borderRadius: 6, border: "1px solid #bfdbfe", fontSize: 12, color: "#2563eb" }}>🔗 Promoted to: ERP Evaluation & Replacement</div>}
              {selected.status === "submitted" && (
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <button style={{ flex: 1, padding: "8px", borderRadius: 6, border: "none", background: "#059669", color: "#fff", fontSize: 12, fontWeight: 600, fontFamily: ff, cursor: "pointer" }}>✅ Approve → Initiative</button>
                  <button style={{ padding: "8px 12px", borderRadius: 6, border: "1px solid #e5e7eb", background: "#fff", color: "#dc2626", fontSize: 12, fontWeight: 600, cursor: "pointer" }}>❌</button>
                  <button style={{ padding: "8px 12px", borderRadius: 6, border: "1px solid #e5e7eb", background: "#fff", color: "#6b7280", fontSize: 12, fontWeight: 600, cursor: "pointer" }}>⏸</button>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── PROGRAMS TAB ──────────────────────────────────────────────────────
function ProgramsTab() {
  const [expanded, setExpanded] = useState(null);

  return (
    <div>
      {programsData.map(prog => {
        const inits = initialInitiatives.filter(i => i.programs.includes(prog.id));
        const consumed = inits.reduce((s, i) => s + midCost(i), 0);
        const pct = Math.round(consumed / prog.budget * 100);
        const rrDelta = inits.reduce((s, i) => s + i.runRate, 0);
        const tc = themeColors[prog.theme];
        const isOpen = expanded === prog.id;

        return (
          <div key={prog.id} onClick={() => setExpanded(isOpen ? null : prog.id)} style={{ background: "#fff", border: "1px solid #e5e7eb", borderLeft: `4px solid ${tc.dot}`, borderRadius: 8, marginBottom: 10, cursor: "pointer", overflow: "hidden" }}>
            <div style={{ padding: "16px 16px 12px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 700, color: "#0f172a", fontFamily: ff }}>📁 {prog.title}</div>
                  <div style={{ fontSize: 11, color: "#64748b", fontFamily: ff, marginTop: 2, fontStyle: "italic" }}>"{prog.driver}"</div>
                </div>
                <div style={{ display: "flex", gap: 6 }}>
                  <Chip bg={tc.bg} color={tc.text} border={tc.border} small>{prog.theme}</Chip>
                  <Chip bg="#ecfdf5" color="#059669" small>{prog.status}</Chip>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12, marginBottom: 10 }}>
                {[
                  { l: "Budget", v: fmt(prog.budget, true), s: prog.fy },
                  { l: "Consumed", v: fmt(consumed, true), s: `${fmt(prog.budget - consumed, true)} left` },
                  { l: "Initiatives", v: inits.length, s: `${inits.filter(i => i.status === "in_progress").length} active` },
                  { l: "Δ Run Rate", v: <RunRate value={rrDelta} large />, s: "net annual" },
                ].map((item, idx) => (
                  <div key={idx}>
                    <div style={{ fontSize: 9, fontWeight: 600, color: "#94a3b8", fontFamily: ff, textTransform: "uppercase" }}>{item.l}</div>
                    <div style={{ fontSize: 16, fontWeight: 700, fontFamily: fm, color: "#0f172a", marginTop: 1 }}>{item.v}</div>
                    <div style={{ fontSize: 9, color: "#cbd5e1", fontFamily: ff }}>{item.s}</div>
                  </div>
                ))}
              </div>

              <div style={{ position: "relative", height: 20, background: "#f1f5f9", borderRadius: 4, overflow: "hidden" }}>
                <div style={{ position: "absolute", left: 0, top: 0, height: "100%", width: `${Math.min(pct, 100)}%`, background: `linear-gradient(90deg, ${tc.dot}bb, ${tc.dot})`, borderRadius: 4, transition: "width 0.4s" }} />
                <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <span style={{ fontSize: 10, fontWeight: 700, fontFamily: fm, color: pct > 50 ? "#fff" : "#475569" }}>{pct}%</span>
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6 }}>
                <span style={{ fontSize: 10, color: "#94a3b8", fontFamily: ff }}>Owner: {prog.owner} · Sponsor: {prog.sponsor}</span>
                <span style={{ fontSize: 10, color: "#cbd5e1", fontFamily: fm }}>{prog.start} → {prog.end}</span>
              </div>
            </div>

            {isOpen && (
              <div style={{ borderTop: "1px solid #e5e7eb", padding: 12, background: "#f8fafc" }}>
                {inits.map(init => {
                  const sc = statusList.find(s => s.id === init.status);
                  return (
                    <div key={init.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "6px 8px", background: "#fff", borderRadius: 4, marginBottom: 3, border: "1px solid #e5e7eb" }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                        <PriorityDot p={init.priority} />
                        <span style={{ fontSize: 12, fontWeight: 500, fontFamily: ff, color: "#0f172a" }}>{init.title}</span>
                        <Chip bg={sc?.color + "18"} color={sc?.color} small>{sc?.icon} {sc?.label}</Chip>
                      </div>
                      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                        <span style={{ fontFamily: fm, fontSize: 11, color: "#475569" }}>{fmt(midCost(init), true)}</span>
                        <RunRate value={init.runRate} />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

// ─── MAIN ──────────────────────────────────────────────────────────────
const sections = [
  { id: "initiatives", label: "Initiatives", icon: "🎯" },
  { id: "scorecard", label: "Scorecard", icon: "📊" },
  { id: "ideas", label: "Ideas", icon: "💡" },
  { id: "programs", label: "Programs", icon: "📁" },
];

const viewModes = [
  { id: "gantt", label: "Gantt" },
  { id: "kanban", label: "Kanban" },
  { id: "grid", label: "Grid" },
];

export default function ITValueCreation() {
  const [activeSection, setActiveSection] = useState("initiatives");
  const [viewMode, setViewMode] = useState("gantt");
  const [initiatives, setInitiatives] = useState(initialInitiatives);
  const [selectedId, setSelectedId] = useState(null);

  const selectedInit = initiatives.find(i => i.id === selectedId);
  const pendingIdeas = ideasData.filter(i => ["submitted", "under_review"].includes(i.status)).length;
  const resetAll = () => { setInitiatives(initialInitiatives); setSelectedId(null); };

  return (
    <div style={{ fontFamily: ff, background: "#f1f5f9", minHeight: "100vh" }}>
      <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet" />

      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #0f172a, #1e293b)", padding: "20px 28px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: 1.5, color: "#0d9488", textTransform: "uppercase" }}>City of Riverside</div>
            <h1 style={{ fontSize: 22, fontWeight: 700, color: "#f8fafc", margin: "2px 0 0" }}>IT Value Creation</h1>
          </div>
          <div style={{ display: "flex", gap: 20 }}>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 9, color: "#64748b", textTransform: "uppercase", letterSpacing: 0.6 }}>Baseline</div>
              <div style={{ fontSize: 18, fontWeight: 700, fontFamily: fm, color: "#f8fafc" }}>{fmt(BASE_RUN_RATE, true)}</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 9, color: "#64748b", textTransform: "uppercase", letterSpacing: 0.6 }}>Investment</div>
              <div style={{ fontSize: 18, fontWeight: 700, fontFamily: fm, color: "#0d9488" }}>{fmt(initiatives.filter(i => i.enabled).reduce((s, i) => s + midCost(i), 0), true)}</div>
            </div>
          </div>
        </div>

        {/* Section tabs */}
        <div style={{ display: "flex", gap: 1 }}>
          {sections.map(sec => (
            <button key={sec.id} onClick={() => { setActiveSection(sec.id); setSelectedId(null); }} style={{
              padding: "9px 18px", borderRadius: "6px 6px 0 0", border: "none",
              background: activeSection === sec.id ? "#f1f5f9" : "transparent",
              color: activeSection === sec.id ? "#0f172a" : "#64748b",
              fontSize: 12, fontWeight: 600, fontFamily: ff, cursor: "pointer",
              display: "flex", alignItems: "center", gap: 5, transition: "all 0.12s",
            }}>
              <span>{sec.icon}</span>{sec.label}
              {sec.id === "ideas" && pendingIdeas > 0 && <span style={{ background: "#ef4444", color: "#fff", fontSize: 9, fontWeight: 700, borderRadius: 8, padding: "0 5px", fontFamily: fm }}>{pendingIdeas}</span>}
            </button>
          ))}
        </div>
      </div>

      {/* Body */}
      <div style={{ padding: "16px 28px", maxWidth: 1240, margin: "0 auto" }}>
        {activeSection === "initiatives" && (
          <>
            {/* View mode toggle + reset */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <div style={{ display: "flex", gap: 1, background: "#e2e8f0", borderRadius: 6, padding: 2 }}>
                {viewModes.map(vm => (
                  <button key={vm.id} onClick={() => setViewMode(vm.id)} style={{
                    padding: "5px 14px", borderRadius: 4, border: "none",
                    background: viewMode === vm.id ? "#fff" : "transparent",
                    color: viewMode === vm.id ? "#0f172a" : "#94a3b8",
                    fontSize: 12, fontWeight: 600, fontFamily: ff, cursor: "pointer",
                    boxShadow: viewMode === vm.id ? "0 1px 2px rgba(0,0,0,.06)" : "none",
                    transition: "all 0.12s",
                  }}>{vm.label}</button>
                ))}
              </div>
              <button onClick={resetAll} style={{ padding: "5px 12px", borderRadius: 5, border: "1px solid #e5e7eb", background: "#fff", color: "#94a3b8", fontSize: 11, fontWeight: 600, fontFamily: ff, cursor: "pointer" }}>↺ Reset</button>
            </div>

            <KpiBar initiatives={initiatives} />

            <div style={{ display: "flex", gap: 16 }}>
              <div style={{ flex: selectedInit ? "1 1 0" : 1, minWidth: 0 }}>
                {viewMode === "gantt" && <GanttView initiatives={initiatives} setInitiatives={setInitiatives} selectedId={selectedId} setSelectedId={setSelectedId} />}
                {viewMode === "kanban" && <KanbanView initiatives={initiatives} setInitiatives={setInitiatives} selectedId={selectedId} setSelectedId={setSelectedId} />}
                {viewMode === "grid" && <GridView initiatives={initiatives} selectedId={selectedId} setSelectedId={setSelectedId} />}
              </div>
              {selectedInit && (
                <div style={{ flex: "0 0 280px" }}>
                  <DetailPanel init={selectedInit} onClose={() => setSelectedId(null)} />
                </div>
              )}
            </div>
          </>
        )}

        {activeSection === "scorecard" && <ScorecardTab />}
        {activeSection === "ideas" && <IdeasTab />}
        {activeSection === "programs" && <ProgramsTab />}
      </div>
    </div>
  );
}
