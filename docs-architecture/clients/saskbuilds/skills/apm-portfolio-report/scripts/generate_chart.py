#!/usr/bin/env python3
"""
generate_chart.py — APM Portfolio Report: Bubble Chart Generator

Reads ministry_data.json and produces a TIME bubble chart PNG.

Usage:
  python3 generate_chart.py --data ministry_data.json --out time_bubble_chart.png
"""

import argparse
import json
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

def short_name(full_name):
    """Extract acronym or short form from 'ACRONYM - Full Name' pattern.
    Falls back to the full name if no acronym prefix is present."""
    m = re.match(r'^([A-Za-z]+)\s*-\s+.+', full_name)
    if m:
        return m.group(1)
    return full_name

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', required=True, help='Path to ministry_data.json')
    parser.add_argument('--out', required=True, help='Output PNG path')
    args = parser.parse_args()

    with open(args.data) as f:
        data = json.load(f)

    ministry = data['ministry']
    apps = [a for a in data['apps'] if a['time_category'] != 'Incomplete Data']

    # Sort alphabetically for numbering
    apps_sorted = sorted(apps, key=lambda x: x['name'])
    app_numbers = {a['name']: i+1 for i, a in enumerate(apps_sorted)}

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

    n_apps = len(apps_sorted)

    # Use fixed-position axes to guarantee a square chart
    # Figure: 16 wide x 10 tall (inches)
    # Chart must be square: 8.5in x 8.5in → in figure coords: w=8.5/16=0.53, h=8.5/10=0.85
    fig = plt.figure(figsize=(16, 10))
    fig.patch.set_facecolor('#FFFFFF')

    chart_w_in = 8.5
    chart_h_in = 8.5
    fig_w_in = 16
    fig_h_in = 10
    chart_l = 0.06
    chart_b = 0.08
    ax_main = fig.add_axes([chart_l, chart_b, chart_w_in / fig_w_in, chart_h_in / fig_h_in])
    ax_legend = fig.add_axes([chart_l + chart_w_in / fig_w_in + 0.03, chart_b, 0.30, chart_h_in / fig_h_in])

    # --- Main chart ---
    ax_main.set_facecolor('#F8FAFC')
    ax_main.set_xlim(-2, 102)
    ax_main.set_ylim(-2, 102)

    # Quadrant fills
    ax_main.axhspan(50, 102, xmin=0, xmax=0.5, alpha=0.06, color='#8B5CF6', zorder=0)   # Tolerate
    ax_main.axhspan(50, 102, xmin=0.5, xmax=1.0, alpha=0.06, color='#10B981', zorder=0)  # Invest
    ax_main.axhspan(-2, 50, xmin=0, xmax=0.5, alpha=0.06, color='#EF4444', zorder=0)     # Eliminate
    ax_main.axhspan(-2, 50, xmin=0.5, xmax=1.0, alpha=0.06, color='#F59E0B', zorder=0)   # Modernize

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
    for app in apps:
        num = app_numbers[app['name']]
        crit = app['criticality'] or 20
        bf = app['business_fit'] or 0
        tf = app['tech_fit'] or 0
        cat = app['time_category']
        size = max(crit * bubble_scale * 3000, 300)
        color = COLORS.get(cat, '#999999')
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

    # Size reference
    ax_main.text(50, 4, '\u25cf Bubble size = Criticality score', ha='center', va='bottom',
                fontsize=8, color='#64748B', style='italic',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='#CBD5E1', alpha=0.85))

    # --- Legend panel ---
    ax_legend.set_facecolor('#F8FAFC')
    ax_legend.axis('off')

    # Title
    ax_legend.text(0.05, 0.98, 'Application Index', fontsize=12, fontweight='bold',
                  color='#1B365D', va='top', transform=ax_legend.transAxes)
    ax_legend.plot([0.05, 0.95], [0.962, 0.962], color='#1B365D',
                  linewidth=1.5, transform=ax_legend.transAxes, clip_on=False)

    # Quadrant legend — coloured text, no rectangles
    quad_y = 0.94
    cat_order = [("Invest", COLORS["Invest"]), ("Modernize", COLORS["Modernize"]),
                 ("Tolerate", COLORS["Tolerate"]), ("Eliminate", COLORS["Eliminate"])]
    legend_str_x = 0.07
    for cat, col in cat_order:
        ax_legend.text(legend_str_x, quad_y, '\u25cf', fontsize=10, color=col,
                      va='center', transform=ax_legend.transAxes)
        ax_legend.text(legend_str_x + 0.06, quad_y, cat, fontsize=9, fontweight='semibold',
                      color=col, va='center', transform=ax_legend.transAxes)
        legend_str_x += 0.25

    # Separator line between quadrant legend and app list
    ax_legend.plot([0.05, 0.95], [0.915, 0.915], color='#E2E8F0',
                  linewidth=0.8, transform=ax_legend.transAxes, clip_on=False)

    # App list — pill badge + acronym/short name in larger font
    y_start = 0.89
    line_h = min(0.048, 0.87 / max(n_apps, 1))
    for app in apps_sorted:
        num = app_numbers[app['name']]
        col = COLORS.get(app['time_category'], '#999999')
        y = y_start - (num - 1) * line_h

        # Pill-shaped number badge
        pill_w = 0.10
        pill_h = 0.028
        rect = mpatches.FancyBboxPatch((0.04, y - pill_h / 2), pill_w, pill_h,
            boxstyle="round,pad=0.005", facecolor=col, alpha=0.85,
            transform=ax_legend.transAxes, clip_on=False)
        ax_legend.add_patch(rect)
        ax_legend.text(0.04 + pill_w / 2, y, str(num), ha='center', va='center',
                      fontsize=9, fontweight='bold', color='white',
                      transform=ax_legend.transAxes)

        # Acronym / short name — larger font
        label = short_name(app['name'])
        ax_legend.text(0.19, y, label, fontsize=9.5, color='#1E293B',
                      va='center', fontweight='medium',
                      transform=ax_legend.transAxes)

    # Title bar
    title_bar = mpatches.FancyBboxPatch((0, 0.985), 1, 0.015,
        boxstyle="square,pad=0", facecolor='#1B365D',
        transform=fig.transFigure, clip_on=False)
    fig.add_artist(title_bar)
    fig.text(0.5, 0.993, f'{ministry} \u2014 Application Portfolio TIME Assessment',
            ha='center', va='center', fontsize=13, fontweight='bold',
            color='white', transform=fig.transFigure)

    # No tight_layout or subplots_adjust — axes are manually positioned
    plt.savefig(args.out, dpi=180, facecolor='white', edgecolor='none')
    print(f"Chart saved to {args.out}")

if __name__ == '__main__':
    main()
