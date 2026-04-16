#!/usr/bin/env python3
"""
parse_data.py — APM Portfolio Report: Data Parser

Reads four APM input files, joins them, validates data quality,
and outputs ministry_data.json for chart and report generation.

Usage:
  python3 parse_data.py \
    --curated  path/to/curated.xlsx \
    --business path/to/business_fit.csv \
    --technical path/to/technical_fit.csv \
    --infra    path/to/infrastructure.xlsx \
    --out      ministry_data.json
"""

import argparse
import json
import pandas as pd
import re
import sys
from datetime import datetime

def clean_curated(path):
    df = pd.read_excel(path)
    # Drop blank rows and Power BI metadata rows
    df = df.dropna(subset=['Application Name'])
    df = df[~df['Application Name'].astype(str).str.contains('Applied filters', na=False)]
    df = df.reset_index(drop=True)
    return df

def clean_business(path):
    try:
        df = pd.read_csv(path)
    except UnicodeDecodeError:
        df = pd.read_csv(path, encoding='cp1252')
    return df

def clean_technical(path):
    try:
        df = pd.read_csv(path)
    except UnicodeDecodeError:
        df = pd.read_csv(path, encoding='cp1252')
    return df

def clean_infra(path):
    df = pd.read_excel(path)
    df = df.dropna(subset=['Business Application'])
    return df

def derive_assessment_period(bf_df, tf_df):
    dates = []
    for df in [bf_df, tf_df]:
        if 'Modified' in df.columns:
            for val in df['Modified'].dropna():
                try:
                    dates.append(pd.to_datetime(val))
                except Exception:
                    pass
    if not dates:
        return "Unknown"
    earliest = min(dates)
    latest = max(dates)
    if earliest.month == latest.month and earliest.year == latest.year:
        return earliest.strftime("%b %Y")
    return f"{earliest.strftime('%b')}–{latest.strftime('%b %Y')}"

def derive_report_date(bf_df, tf_df):
    dates = []
    for df in [bf_df, tf_df]:
        if 'Modified' in df.columns:
            for val in df['Modified'].dropna():
                try:
                    dates.append(pd.to_datetime(val))
                except Exception:
                    pass
    if not dates:
        return datetime.now().strftime("%B %Y")
    return max(dates).strftime("%B %Y")

def get_itsm(infra_df, app_name):
    rows = infra_df[infra_df['Business Application'] == app_name]
    if rows.empty:
        return None, None, None
    inc = rows['Sum of Incidents 24 Months'].sum() if 'Sum of Incidents 24 Months' in rows else None
    req = rows['Sum of  Requests 24 Months'].sum() if 'Sum of  Requests 24 Months' in rows else None
    prob = rows['Sum of  Problems 24 Months'].sum() if 'Sum of  Problems 24 Months' in rows else None
    return (
        int(inc) if pd.notna(inc) else None,
        int(req) if pd.notna(req) else None,
        int(prob) if pd.notna(prob) else None,
    )

def is_crown_jewel(infra_df, app_name):
    rows = infra_df[infra_df['Business Application'] == app_name]
    if rows.empty:
        return False
    cj = rows['Crown Jewel'].dropna()
    return any(str(v).strip().lower() in ['yes', 'true', '1'] for v in cj)

def build_apps(curated, bf, tf, infra):
    # Sort alphabetically for numbering
    apps_sorted = curated.sort_values('Application Name').reset_index(drop=True)
    app_number = {row['Application Name']: i+1 for i, row in apps_sorted.iterrows()}

    apps = []
    quality_flags = []

    for _, row in curated.iterrows():
        name = row['Application Name']
        num = app_number[name]

        # Scores from curated
        crit = row.get('Criticality Fit Score')
        bf_score = row.get('Business Fit Score')
        tf_score = row.get('Technical Fit Score')
        lifecycle = str(row.get('Lifecycle Status', '')) if pd.notna(row.get('Lifecycle Status')) else None
        time_cat = str(row.get('TIME Category', '')) if pd.notna(row.get('TIME Category')) else 'Incomplete Data'

        # Enrichment from business fit CSV
        bf_row = bf[bf['Application Name'] == name]
        owner = bf_row['Application Owner'].iloc[0] if not bf_row.empty and pd.notna(bf_row['Application Owner'].iloc[0]) else None
        who = bf_row['Who was involved'].iloc[0] if not bf_row.empty and 'Who was involved' in bf_row.columns else None
        assessors = [x.strip() for x in str(who).split(',')] if who and pd.notna(who) else []

        # Enrichment from technical fit CSV
        tf_row = tf[tf['Application Name'] == name]
        architect = tf_row['Architect / SME'].iloc[0] if not tf_row.empty and 'Architect / SME' in tf_row.columns and pd.notna(tf_row['Architect / SME'].iloc[0]) else None

        # Infrastructure data
        crown_jewel = is_crown_jewel(infra, name)
        itsm_inc, itsm_req, itsm_prob = get_itsm(infra, name)

        app = {
            "num": num,
            "name": name,
            "time_category": time_cat,
            "criticality": float(crit) if pd.notna(crit) else None,
            "business_fit": float(bf_score) if pd.notna(bf_score) else None,
            "tech_fit": float(tf_score) if pd.notna(tf_score) else None,
            "lifecycle": lifecycle,
            "crown_jewel": crown_jewel,
            "owner": owner,
            "assessors": assessors,
            "architect": architect,
            "itsm_incidents": itsm_inc,
            "itsm_requests": itsm_req,
            "itsm_problems": itsm_prob,
        }
        apps.append(app)

        # Data quality check: Crown Jewel in Eliminate
        if crown_jewel and time_cat == 'Eliminate':
            quality_flags.append(
                f"⚠ DATA QUALITY: '{name}' has Crown Jewel designation but is positioned in Eliminate. "
                f"Scores: Criticality={crit}, Business Fit={bf_score}, Tech Fit={tf_score}. "
                f"Verify whether scores have been inverted with another application."
            )

    return apps, quality_flags

def build_team(bf, tf):
    owners = []
    architects = []

    if 'Application Owner' in bf.columns:
        for val in bf['Application Owner'].dropna().unique():
            name = str(val).strip()
            if name and name not in owners and 'deleted' not in name.lower():
                owners.append(name)

    if 'Architect / SME' in tf.columns:
        for val in tf['Architect / SME'].dropna().unique():
            for part in str(val).split(','):
                name = part.strip()
                if name and name not in architects and name.lower() != 'vendor':
                    # Flag first-name only entries
                    if ' ' not in name and name not in architects:
                        architects.append(name + ' †')
                    elif name not in architects:
                        architects.append(name)

    # Who was involved (assessors)
    lead = None
    if 'Who was involved' in bf.columns:
        vals = bf['Who was involved'].dropna().unique()
        if len(vals) == 1:
            lead = str(vals[0]).strip()

    return {
        "program_lead": "",  # To be filled manually or from additional context
        "assessment_lead": lead or "",
        "owners": owners,
        "architects": architects,
        "advisor": "",  # To be filled manually
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--curated',  required=True)
    parser.add_argument('--business', required=True)
    parser.add_argument('--technical',required=True)
    parser.add_argument('--infra',    required=True)
    parser.add_argument('--out',      default='ministry_data.json')
    args = parser.parse_args()

    print("Reading files...")
    curated = clean_curated(args.curated)
    bf      = clean_business(args.business)
    tf      = clean_technical(args.technical)
    infra   = clean_infra(args.infra)

    ministry_vals = bf['Ministry'].dropna() if 'Ministry' in bf.columns else pd.Series(dtype=str)
    ministry = str(ministry_vals.iloc[0]) if len(ministry_vals) > 0 else "Unknown Ministry"
    assessment_period = derive_assessment_period(bf, tf)
    report_date = derive_report_date(bf, tf)

    total_apps = len(curated)
    incomplete = curated[curated['TIME Category'] == 'Incomplete Data']
    assessed_apps = total_apps - len(incomplete)

    print(f"Ministry: {ministry}")
    print(f"Total apps: {total_apps} | Assessed: {assessed_apps} | Incomplete: {len(incomplete)}")
    print(f"Assessment period: {assessment_period}")

    apps, quality_flags = build_apps(curated, bf, tf, infra)
    team = build_team(bf, tf)

    if quality_flags:
        print("\n⚠ DATA QUALITY FLAGS:")
        for f in quality_flags:
            print(f"  {f}")

    # Group by TIME category for quick summary
    from collections import Counter
    dist = Counter(a['time_category'] for a in apps if a['time_category'] != 'Incomplete Data')
    print("\nTIME Distribution:")
    for cat, count in sorted(dist.items(), key=lambda x: -x[1]):
        print(f"  {cat}: {count}")

    # Build incomplete app entries
    incomplete_apps = []
    for _, row in incomplete.iterrows():
        name = row['Application Name']
        incomplete_apps.append({
            "name": name,
            "business_fit": float(row['Business Fit Score']) if pd.notna(row.get('Business Fit Score')) else None,
            "criticality": float(row['Criticality Fit Score']) if pd.notna(row.get('Criticality Fit Score')) else None,
            "tech_fit": None,
            "lifecycle": str(row['Lifecycle Status']) if pd.notna(row.get('Lifecycle Status')) else None,
            "likely_position": "",  # Claude to fill
            "action": "",           # Claude to fill
        })

    output = {
        "ministry": ministry,
        "assessment_period": assessment_period,
        "report_date": report_date,
        "total_apps": total_apps,
        "assessed_apps": assessed_apps,
        "incomplete_count": len(incomplete),
        "apps": apps,
        "team": team,
        "data_quality_notes": quality_flags,
        "key_insights": [],      # Claude to fill (4 bullet-level insights)
        "incomplete_apps": incomplete_apps,
        "narratives": {
            "abstract": "",
            "snapshot_insight": "",
            "invest":    {"pattern": "", "criticality_insight": ""},
            "modernize": {"pattern": "", "criticality_insight": ""},
            "tolerate":  {"pattern": "", "criticality_insight": ""},
            "eliminate": {"pattern": "", "criticality_insight": ""},
            "ea_questions": [],
            "next_trigger": "",
        }
    }

    with open(args.out, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"\n✓ Written to {args.out}")
    print("Next: Claude fills in narratives, then run generate_chart.py and generate_report.js")

if __name__ == '__main__':
    main()
