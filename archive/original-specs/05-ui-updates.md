# UI Updates

## Overview

UI changes required for the 0-100 scale and T-shirt sizing updates.

## Chart Axis Changes

### TIME Bubble Chart

#### Before (v1.1)
```javascript
const timeChartConfig = {
  xAxis: { min: 1, max: 5, label: 'Business Fit' },
  yAxis: { min: 1, max: 5, label: 'Tech Health' },
  referenceLine: 3.0
};
```

#### After (v1.2)
```javascript
const timeChartConfig = {
  xAxis: { 
    min: 0, 
    max: 100, 
    label: 'Business Fit',
    tickInterval: 10
  },
  yAxis: { 
    min: 0, 
    max: 100, 
    label: 'Tech Health',
    tickInterval: 10
  },
  referenceLine: 50
};
```

### PAID Bubble Chart

#### Before (v1.1)
```javascript
const paidChartConfig = {
  xAxis: { min: 1, max: 5, label: 'Technical Risk' },
  yAxis: { min: 1, max: 5, label: 'Criticality' },
  referenceLine: 3.0,
  bubbleSize: { field: 'annualCost', scale: 'log' }
};
```

#### After (v1.2)
```javascript
const paidChartConfig = {
  xAxis: { 
    min: 0, 
    max: 100, 
    label: 'Technical Risk',
    tickInterval: 10
  },
  yAxis: { 
    min: 0, 
    max: 100, 
    label: 'Business Impact (Criticality)',
    tickInterval: 10
  },
  referenceLine: 50,
  bubbleSize: { 
    field: 'remediationBubbleSize',  // CHANGED
    // No scale needed - values are pre-scaled
  }
};
```

## Reference Line Styling

```css
.quadrant-reference-line {
  stroke: #CCCCCC;
  stroke-dasharray: 5, 5;
  stroke-width: 1;
}
```

```jsx
// Add reference lines at 50 on both axes
<line 
  x1={xScale(50)} 
  y1={0} 
  x2={xScale(50)} 
  y2={height} 
  className="quadrant-reference-line"
/>
<line 
  x1={0} 
  y1={yScale(50)} 
  x2={width} 
  y2={yScale(50)} 
  className="quadrant-reference-line"
/>
```

## Quadrant Labels on Chart

Position labels in each quadrant corner:

```jsx
const quadrantLabels = {
  time: [
    { x: 25, y: 75, label: 'TOLERATE', color: '#808080' },
    { x: 75, y: 75, label: 'INVEST', color: '#2E7D32' },
    { x: 25, y: 25, label: 'ELIMINATE', color: '#C62828' },
    { x: 75, y: 25, label: 'MIGRATE', color: '#F57C00' }
  ],
  paid: [
    { x: 25, y: 75, label: 'PLAN', color: '#1565C0' },
    { x: 75, y: 75, label: 'ADDRESS', color: '#C62828' },
    { x: 25, y: 25, label: 'IGNORE', color: '#808080' },
    { x: 75, y: 25, label: 'DELAY', color: '#F9A825' }
  ]
};
```

## Score Display Components

### Score Badge
```jsx
function ScoreBadge({ score, label }) {
  const getColor = (score) => {
    if (score >= 75) return 'green';
    if (score >= 50) return 'blue';
    if (score >= 25) return 'orange';
    return 'red';
  };
  
  return (
    <div className={`score-badge score-${getColor(score)}`}>
      <span className="score-value">{score}</span>
      <span className="score-label">{label}</span>
    </div>
  );
}

// Usage
<ScoreBadge score={app.businessFit} label="Business Fit" />
```

### Score Bar
```jsx
function ScoreBar({ score, label }) {
  return (
    <div className="score-bar">
      <div className="score-bar-label">{label}</div>
      <div className="score-bar-track">
        <div 
          className="score-bar-fill" 
          style={{ width: `${score}%` }}
        />
        <div 
          className="score-bar-threshold" 
          style={{ left: '50%' }}
        />
      </div>
      <div className="score-bar-value">{score}%</div>
    </div>
  );
}
```

## Tooltip Updates

### TIME Chart Tooltip
```jsx
function TIMETooltip({ app }) {
  return (
    <div className="chart-tooltip">
      <h4>{app.name}</h4>
      <hr />
      <div>Quadrant: <strong>{app.timeQuadrant}</strong></div>
      <div>Business Fit: {app.businessFit}%</div>
      <div>Tech Health: {app.techHealth}%</div>
      <div>Criticality: {app.criticality}%</div>
      <hr />
      <div>Annual Cost: ${app.annualCost.toLocaleString()}</div>
      <div>Portfolio: {app.portfolioName}</div>
    </div>
  );
}
```

### PAID Chart Tooltip
```jsx
function PAIDTooltip({ app }) {
  return (
    <div className="chart-tooltip">
      <h4>{app.name}</h4>
      <hr />
      <div>Action: <strong style={{ color: getPAIDColor(app.paidAction) }}>
        {app.paidAction}
      </strong></div>
      <div>Technical Risk: {app.technicalRisk}%</div>
      <div>Business Impact: {app.criticality}%</div>
      <hr />
      <div>Remediation Effort: <strong>{app.remediationEffort || 'Not Estimated'}</strong></div>
      {app.remediationEffort && (
        <div className="text-muted">{app.remediationLabel}</div>
      )}
      <hr />
      <div>Portfolio: {app.portfolioName}</div>
    </div>
  );
}
```

## Application Edit Form

### Add Remediation Effort Field
```jsx
function ApplicationEditForm({ app, onSave }) {
  const [formData, setFormData] = useState(app);
  
  return (
    <form onSubmit={() => onSave(formData)}>
      {/* ... existing fields ... */}
      
      {/* NEW: Remediation Effort */}
      <div className="form-group">
        <label>Remediation Effort Estimate</label>
        <select 
          value={formData.remediationEffort || ''}
          onChange={(e) => setFormData({
            ...formData,
            remediationEffort: e.target.value || null
          })}
        >
          <option value="">Not Estimated</option>
          <option value="XS">XS - Extra Small (&lt; $25K)</option>
          <option value="S">S - Small ($25K - $100K)</option>
          <option value="M">M - Medium ($100K - $250K)</option>
          <option value="L">L - Large ($250K - $500K)</option>
          <option value="XL">XL - Extra Large ($500K - $1M)</option>
          <option value="2XL">2XL - Program (&gt; $1M)</option>
        </select>
        <p className="help-text">
          Estimate the cost/effort to remediate technical debt for this application.
        </p>
      </div>
      
      {/* ... rest of form ... */}
    </form>
  );
}
```

## Summary Cards / KPIs

### Portfolio Summary
```jsx
function PortfolioSummary({ apps }) {
  const avgBusinessFit = Math.round(
    apps.reduce((sum, a) => sum + a.businessFit, 0) / apps.length
  );
  const avgTechHealth = Math.round(
    apps.reduce((sum, a) => sum + a.techHealth, 0) / apps.length
  );
  
  return (
    <div className="summary-cards">
      <div className="summary-card">
        <div className="summary-value">{apps.length}</div>
        <div className="summary-label">Applications</div>
      </div>
      <div className="summary-card">
        <div className="summary-value">{avgBusinessFit}%</div>
        <div className="summary-label">Avg Business Fit</div>
      </div>
      <div className="summary-card">
        <div className="summary-value">{avgTechHealth}%</div>
        <div className="summary-label">Avg Tech Health</div>
      </div>
    </div>
  );
}
```

### Quadrant Distribution
```jsx
function QuadrantDistribution({ apps, type }) {
  const quadrants = type === 'TIME' 
    ? ['Invest', 'Tolerate', 'Migrate', 'Eliminate']
    : ['Address', 'Plan', 'Delay', 'Ignore'];
  
  const field = type === 'TIME' ? 'timeQuadrant' : 'paidAction';
  
  const counts = quadrants.map(q => ({
    name: q,
    count: apps.filter(a => a[field] === q).length,
    percent: Math.round(apps.filter(a => a[field] === q).length / apps.length * 100)
  }));
  
  return (
    <div className="quadrant-distribution">
      {counts.map(q => (
        <div key={q.name} className={`quadrant-stat quadrant-${q.name.toLowerCase()}`}>
          <span className="quadrant-count">{q.count}</span>
          <span className="quadrant-name">{q.name}</span>
          <span className="quadrant-percent">({q.percent}%)</span>
        </div>
      ))}
    </div>
  );
}
```

## Validation

After implementing, verify:
- [ ] Chart axes show 0-100 range
- [ ] Reference lines appear at 50 on both axes
- [ ] Quadrant labels appear in correct positions
- [ ] Tooltips show percentage values (e.g., "69%" not "3.75")
- [ ] PAID tooltip shows T-shirt size and cost range
- [ ] Application edit form has Remediation Effort dropdown
- [ ] Summary cards show percentage averages
