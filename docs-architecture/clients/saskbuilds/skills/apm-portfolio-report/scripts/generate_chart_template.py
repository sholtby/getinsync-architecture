import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Data - corrected (IRIS IRS and IRIS BI swapped)
apps = [
    # name, business_fit, tech_fit, criticality, time_category
    ("AccuMap",                                          26.3, 29.5, 22.5, "Eliminate"),
    ("Coal Files",                                       45.0, 44.3, 38.8, "Eliminate"),
    ("Daily Drilling Activity Report Archive",           42.5, 35.5, 41.3, "Eliminate"),
    ("GeoAtlas",                                         37.5, 29.5, 30.0, "Eliminate"),
    ("GeoPlanner",                                       42.5, 36.0, 41.3, "Eliminate"),
    ("GeoVista",                                         50.0, 36.5, 35.0, "Modernize"),
    ("IRIS Business Intelligence",                       45.0, 48.0, 38.8, "Eliminate"),
    ("Land Claims GIS Mapping",                          45.0, 37.0, 43.8, "Eliminate"),
    ("Licensed Wells Archive",                           42.5, 35.5, 41.3, "Eliminate"),
    ("LogSleuth",                                        16.3, 36.5, 21.3, "Eliminate"),
    ("MARS - Mineral Admin. Registration System",        42.5, 50.0, 41.3, "Tolerate"),
    ("Preliminary Plans",                                46.3, 36.8, 28.8, "Eliminate"),
    ("RBC Receivables Link Application",                 51.3, 43.3, 38.8, "Modernize"),
    ("SMAD - Sask. Mineral Assessment Data",             48.8, 29.3, 42.5, "Eliminate"),
    ("Test Holes",                                       11.3, 35.5,  8.8, "Eliminate"),
    ("Treeno",                                           11.3, 35.5,  3.8, "Eliminate"),
    ("Value Navigator",                                  11.3, 35.5,  3.8, "Eliminate"),
    ("Water Analysis",                                   70.0, 50.0, 67.5, "Invest"),
    ("GeoLogic Geoscout",                                50.0, 18.0, 46.3, "Modernize"),
    ("IRIS - Integrated Resource Info. System",          88.8, 65.8, 88.8, "Invest"),
]

# Sort by app number for legend
apps_sorted = sorted(apps, key=lambda x: x[0])
app_numbers = {a[0]: i+1 for i, a in enumerate(apps_sorted)}

COLORS = {
    "Eliminate": "#EF4444",
    "Modernize": "#F59E0B",
    "Invest":    "#10B981",
    "Tolerate":  "#8B5CF6",
}

QUADRANT_TEXT_COLOR = {
    "Eliminate": "#991B1B",
    "Modernize": "#92400E",
    "Invest":    "#065F46",
    "Tolerate":  "#5B21B6",
}

fig, (ax_main, ax_legend) = plt.subplots(1, 2, figsize=(16, 9),
    gridspec_kw={'width_ratios': [3, 1]})

fig.patch.set_facecolor('#FFFFFF')

# --- Main chart ---
ax_main.set_facecolor('#F8FAFC')
ax_main.set_xlim(-2, 102)
ax_main.set_ylim(-2, 102)

# Quadrant fills
ax_main.axhspan(50, 102, xmin=0, xmax=0.5, alpha=0.06, color='#8B5CF6', zorder=0)   # Tolerate
ax_main.axhspan(50, 102, xmin=0.5, xmax=1.0, alpha=0.06, color='#10B981', zorder=0)  # Invest
ax_main.axhspan(-2, 50, xmin=0, xmax=0.5, alpha=0.06, color='#EF4444', zorder=0)    # Eliminate
ax_main.axhspan(-2, 50, xmin=0.5, xmax=1.0, alpha=0.06, color='#F59E0B', zorder=0)  # Modernize

# Grid lines
ax_main.grid(True, color='#CBD5E1', linewidth=0.5, linestyle='--', alpha=0.7, zorder=1)

# Quadrant dividers
ax_main.axhline(y=50, color='#1E293B', linewidth=1.5, zorder=2)
ax_main.axvline(x=50, color='#1E293B', linewidth=1.5, zorder=2)

# Quadrant labels
ql_props = dict(fontsize=11, fontweight='bold', alpha=0.6, zorder=3)
ax_main.text(2, 98, 'TOLERATE', color=QUADRANT_TEXT_COLOR['Tolerate'], ha='left', va='top', **ql_props)
ax_main.text(98, 98, 'INVEST', color=QUADRANT_TEXT_COLOR['Invest'], ha='right', va='top', **ql_props)
ax_main.text(2, 2, 'ELIMINATE', color=QUADRANT_TEXT_COLOR['Eliminate'], ha='left', va='bottom', **ql_props)
ax_main.text(98, 2, 'MODERNIZE', color=QUADRANT_TEXT_COLOR['Modernize'], ha='right', va='bottom', **ql_props)

# Bubbles
bubble_scale = 0.045
for name, bf, tf, crit, cat in apps:
    num = app_numbers[name]
    size = max(crit * bubble_scale * 3000, 300)
    color = COLORS[cat]
    ax_main.scatter(bf, tf, s=size, c=color, alpha=0.72, edgecolors='white',
                   linewidths=1.5, zorder=4)
    ax_main.text(bf, tf, str(num), ha='center', va='center',
                fontsize=7.5, fontweight='bold', color='white', zorder=5)

# Axes
ax_main.set_xlabel('Business Fit Score', fontsize=12, fontweight='semibold',
                   color='#1E293B', labelpad=10)
ax_main.set_ylabel('Technical Fit Score', fontsize=12, fontweight='semibold',
                   color='#1E293B', labelpad=10)
ax_main.tick_params(colors='#475569', labelsize=10)
for spine in ax_main.spines.values():
    spine.set_edgecolor('#CBD5E1')

# Size reference — text annotation only, no ghost scatter markers
ax_main.text(50, 4, '● Bubble size = Criticality score', ha='center', va='bottom',
            fontsize=8, color='#64748B', style='italic',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='#CBD5E1', alpha=0.85))

# --- Legend panel ---
ax_legend.set_facecolor('#F8FAFC')
ax_legend.axis('off')

# Title
ax_legend.text(0.05, 0.98, 'Application Index', fontsize=11, fontweight='bold',
              color='#1B365D', va='top', transform=ax_legend.transAxes)
ax_legend.plot([0.05, 0.95], [0.965, 0.965], color='#1B365D',
              linewidth=1.5, transform=ax_legend.transAxes, clip_on=False)

# Color chips
cat_colors = [("Invest", COLORS["Invest"]), ("Modernize", COLORS["Modernize"]),
              ("Tolerate", COLORS["Tolerate"]), ("Eliminate", COLORS["Eliminate"])]
chip_x = 0.05
chip_y = 0.94
for cat, col in cat_colors:
    rect = mpatches.FancyBboxPatch((chip_x, chip_y - 0.012), 0.12, 0.018,
        boxstyle="round,pad=0.002", facecolor=col, alpha=0.85,
        transform=ax_legend.transAxes, clip_on=False)
    ax_legend.add_patch(rect)
    ax_legend.text(chip_x + 0.15, chip_y, cat, fontsize=8, color='#1E293B',
                  va='center', transform=ax_legend.transAxes)
    chip_x += 0.28
    if chip_x > 0.8:
        chip_x = 0.05
        chip_y -= 0.025

# App list
y_start = 0.87
line_h = 0.038
for name, bf, tf, crit, cat in apps_sorted:
    num = app_numbers[name]
    col = COLORS[cat]
    y = y_start - (num - 1) * line_h

    # Number badge
    rect = mpatches.FancyBboxPatch((0.02, y - 0.013), 0.1, 0.024,
        boxstyle="round,pad=0.002", facecolor=col, alpha=0.85,
        transform=ax_legend.transAxes, clip_on=False)
    ax_legend.add_patch(rect)
    ax_legend.text(0.07, y, str(num), ha='center', va='center',
                  fontsize=8, fontweight='bold', color='white',
                  transform=ax_legend.transAxes)

    # Short name (truncate if needed)
    short = name if len(name) <= 32 else name[:30] + '…'
    ax_legend.text(0.15, y, short, fontsize=7.2, color='#1E293B',
                  va='center', transform=ax_legend.transAxes)

# Title bar
title_bar = mpatches.FancyBboxPatch((0, 0.985), 1, 0.015,
    boxstyle="square,pad=0", facecolor='#1B365D',
    transform=fig.transFigure, clip_on=False)
fig.add_artist(title_bar)
fig.text(0.5, 0.993, 'Energy & Resources — Application Portfolio TIME Assessment',
        ha='center', va='center', fontsize=13, fontweight='bold',
        color='white', transform=fig.transFigure)

plt.tight_layout(rect=[0, 0, 1, 0.985])
plt.savefig('/home/claude/time_bubble_chart.png', dpi=180, bbox_inches='tight',
           facecolor='white', edgecolor='none')
print("Chart saved")
