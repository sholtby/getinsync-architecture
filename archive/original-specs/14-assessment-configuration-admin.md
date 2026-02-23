# Assessment Configuration Admin Panel

## Overview

The TIME/PAID assessment framework uses Business Factors (B1-B10) and Technical Factors (T01-T15) with weightings to calculate Business Fit, Tech Health, Criticality, and Tech Risk scores. 

Currently these are **hard-coded**. This feature adds an admin panel to customize:
- Factor questions and descriptions
- Factor weightings
- Which factors contribute to derived scores (Criticality, Tech Risk)
- Score thresholds for TIME/PAID quadrants

**This is a PAID feature** â€” Free tier users see the configuration (read-only) but cannot edit.

---

## Tier Availability

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| View factor configuration | âœ… | âœ… | âœ… |
| Edit factor questions/descriptions | âŒ | âœ… | âœ… |
| Edit factor weightings | âŒ | âœ… | âœ… |
| Edit derived score formulas | âŒ | âŒ | âœ… |
| Add/remove factors | âŒ | âŒ | âœ… |
| Custom scoring scales (1-10, 0-100) | âŒ | âŒ | âœ… |

---

## Current Hard-Coded Configuration

### Business Factors (B1-B10)

| ID | Question | Weight | Criticality? |
|----|----------|--------|--------------|
| B1 | Alignment with Strategic Goals | 10% | âœ… |
| B2 | Support for Regional Growth | 10% | âœ… |
| B3 | Impact on Public Confidence | 10% | âœ… |
| B4 | Scope of Use | 10% | âœ… |
| B5 | Business Process Criticality | 10% | âœ… |
| B6 | Tolerance for Interruption | 10% | âœ… |
| B7 | Essential Service Delivery | 10% | âœ… |
| B8 | Current Business Needs | 10% | âŒ |
| B9 | Future Business Needs | 10% | âŒ |
| B10 | User Satisfaction | 10% | âŒ |

**Business Fit** = Weighted average of B1-B10, normalized to 0-100
**Criticality** = Weighted average of B1-B7 only, normalized to 0-100

### Technical Factors (T01-T15, no T12)

| ID | Question | Weight | Tech Risk? |
|----|----------|--------|------------|
| T01 | Platform Footprint | 7.1% | âœ… |
| T02 | Vendor Support Status | 7.1% | âœ… |
| T03 | Development Platform Currency | 7.1% | âœ… |
| T04 | Security Controls | 7.1% | âœ… |
| T05 | Resilience & Recovery | 7.1% | âœ… |
| T06 | Observability | 7.1% | âŒ |
| T07 | Integration Capabilities | 7.1% | âŒ |
| T08 | Identity Assurance | 7.1% | âœ… |
| T09 | Platform Portability | 7.1% | âŒ |
| T10 | Configurability | 7.1% | âŒ |
| T11 | Data Sensitivity Controls | 7.1% | âœ… |
| T13 | Modern UX | 7.1% | âŒ |
| T14 | Integration Count | 7.1% | âŒ |
| T15 | Data Accessibility | 7.1% | âŒ |

**Tech Health** = Weighted average of T01-T15, normalized to 0-100
**Tech Risk** = Weighted average of selected T factors, normalized to 0-100

---

## Database Schema

### assessment_factors table

```sql
CREATE TABLE public.assessment_factors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  factor_type text NOT NULL, -- 'business' or 'technical'
  factor_code text NOT NULL, -- 'B1', 'B2', 'T01', etc.
  sort_order integer NOT NULL,
  question text NOT NULL,
  description text, -- Longer explanation/guidance
  weight decimal NOT NULL DEFAULT 10.0,
  contributes_to_criticality boolean DEFAULT false,
  contributes_to_tech_risk boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT assessment_factors_pkey PRIMARY KEY (id),
  CONSTRAINT assessment_factors_unique UNIQUE (namespace_id, factor_code),
  CONSTRAINT assessment_factors_type_check CHECK (factor_type IN ('business', 'technical'))
);

CREATE INDEX idx_assessment_factors_namespace ON public.assessment_factors(namespace_id);
```

### assessment_factor_options table (for custom scale labels)

```sql
CREATE TABLE public.assessment_factor_options (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  factor_id uuid NOT NULL REFERENCES assessment_factors(id) ON DELETE CASCADE,
  score integer NOT NULL, -- 1, 2, 3, 4, 5
  label text NOT NULL, -- "None", "Low", "Medium", "High", "Critical"
  description text, -- Guidance for this score level
  CONSTRAINT assessment_factor_options_pkey PRIMARY KEY (id),
  CONSTRAINT assessment_factor_options_unique UNIQUE (factor_id, score)
);
```

### assessment_thresholds table

```sql
CREATE TABLE public.assessment_thresholds (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  threshold_type text NOT NULL, -- 'time_quadrant', 'paid_quadrant'
  threshold_name text NOT NULL, -- 'business_fit', 'tech_health'
  threshold_value decimal NOT NULL DEFAULT 50.0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT assessment_thresholds_pkey PRIMARY KEY (id),
  CONSTRAINT assessment_thresholds_unique UNIQUE (namespace_id, threshold_type, threshold_name)
);
```

---

## Seed Default Configuration

When a new Namespace is created, seed the default factors:

```sql
-- Function to seed default factors for new namespace
CREATE OR REPLACE FUNCTION seed_default_assessment_factors()
RETURNS TRIGGER AS $$
BEGIN
  -- Business Factors
  INSERT INTO assessment_factors (namespace_id, factor_type, factor_code, sort_order, question, weight, contributes_to_criticality)
  VALUES
    (NEW.id, 'business', 'B1', 1, 'Alignment with Strategic Goals', 10, true),
    (NEW.id, 'business', 'B2', 2, 'Support for Regional Growth', 10, true),
    (NEW.id, 'business', 'B3', 3, 'Impact on Public Confidence', 10, true),
    (NEW.id, 'business', 'B4', 4, 'Scope of Use', 10, true),
    (NEW.id, 'business', 'B5', 5, 'Business Process Criticality', 10, true),
    (NEW.id, 'business', 'B6', 6, 'Tolerance for Interruption', 10, true),
    (NEW.id, 'business', 'B7', 7, 'Essential Service Delivery', 10, true),
    (NEW.id, 'business', 'B8', 8, 'Current Business Needs', 10, false),
    (NEW.id, 'business', 'B9', 9, 'Future Business Needs', 10, false),
    (NEW.id, 'business', 'B10', 10, 'User Satisfaction', 10, false);

  -- Technical Factors
  INSERT INTO assessment_factors (namespace_id, factor_type, factor_code, sort_order, question, weight, contributes_to_tech_risk)
  VALUES
    (NEW.id, 'technical', 'T01', 1, 'Platform Footprint', 7.14, true),
    (NEW.id, 'technical', 'T02', 2, 'Vendor Support Status', 7.14, true),
    (NEW.id, 'technical', 'T03', 3, 'Development Platform Currency', 7.14, true),
    (NEW.id, 'technical', 'T04', 4, 'Security Controls', 7.14, true),
    (NEW.id, 'technical', 'T05', 5, 'Resilience & Recovery', 7.14, true),
    (NEW.id, 'technical', 'T06', 6, 'Observability', 7.14, false),
    (NEW.id, 'technical', 'T07', 7, 'Integration Capabilities', 7.14, false),
    (NEW.id, 'technical', 'T08', 8, 'Identity Assurance', 7.14, true),
    (NEW.id, 'technical', 'T09', 9, 'Platform Portability', 7.14, false),
    (NEW.id, 'technical', 'T10', 10, 'Configurability', 7.14, false),
    (NEW.id, 'technical', 'T11', 11, 'Data Sensitivity Controls', 7.14, true),
    (NEW.id, 'technical', 'T13', 13, 'Modern UX', 7.14, false),
    (NEW.id, 'technical', 'T14', 14, 'Integration Count', 7.14, false),
    (NEW.id, 'technical', 'T15', 15, 'Data Accessibility', 7.14, false);

  -- Default thresholds
  INSERT INTO assessment_thresholds (namespace_id, threshold_type, threshold_name, threshold_value)
  VALUES
    (NEW.id, 'time_quadrant', 'business_fit', 50),
    (NEW.id, 'time_quadrant', 'tech_health', 50),
    (NEW.id, 'paid_quadrant', 'criticality', 50),
    (NEW.id, 'paid_quadrant', 'tech_risk', 50);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER seed_assessment_factors_on_namespace_create
  AFTER INSERT ON namespaces
  FOR EACH ROW EXECUTE FUNCTION seed_default_assessment_factors();
```

---

## UI: Assessment Configuration Page

**Location:** Settings â†’ Assessment Configuration (Namespace Admin only)

### Tabs Structure

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Assessment Configuration                                                    â”‚
â”‚                                                                             â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Business Factors â”‚ Technical Factorsâ”‚ Derived Scores   â”‚ Thresholds     â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

### Tab 1: Business Factors

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Business Factors                                           [Reset Defaults] â”‚
â”‚ These factors assess how well an application meets business needs.          â”‚
â”‚                                                                             â”‚
â”‚ ðŸ”’ Upgrade to Pro to customize factors                    [Upgrade to Pro] â”‚
â”‚                                                                             â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚   Code  Question                           Weight   Criticality  Actionsâ”‚ â”‚
â”‚ â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤ â”‚
â”‚ â”‚ â‰¡ B1    Alignment with Strategic Goals     10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B2    Support for Regional Growth        10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B3    Impact on Public Confidence        10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B4    Scope of Use                       10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B5    Business Process Criticality       10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B6    Tolerance for Interruption         10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B7    Essential Service Delivery         10%      âœ…           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B8    Current Business Needs             10%      âŒ           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B9    Future Business Needs              10%      âŒ           âœï¸     â”‚ â”‚
â”‚ â”‚ â‰¡ B10   User Satisfaction                  10%      âŒ           âœï¸     â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚ Total Weight: 100%  âœ“                                                       â”‚
â”‚ Criticality includes: B1-B7 (7 factors)                                     â”‚
â”‚                                                                             â”‚
â”‚ [+ Add Factor] (Enterprise only)                                            â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Features:**
- Drag handle (â‰¡) to reorder factors (Pro+)
- Weight column â€” must sum to 100%
- Criticality checkbox â€” which factors contribute to Criticality score
- Edit button opens Edit Factor modal
- "Add Factor" only visible for Enterprise tier

---

### Edit Factor Modal

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Edit Factor: B1                                                        âœ•    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚                                                                             â”‚
â”‚ Question *                                                                  â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Alignment with Strategic Goals                                          â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚ Description / Guidance                                                      â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ How well does this application support the organization's strategic    â”‚ â”‚
â”‚ â”‚ objectives and long-term vision?                                        â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚ Weight                                        Contributes to Criticality    â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                          â”Œâ”€â”€â”€┐                          â”‚
â”‚ â”‚ 10            % â”‚                          â”‚ âœ“ â”‚                          â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                          â””â”€â”€â”€┘                          â”‚
â”‚                                                                             â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚                                                                             â”‚
â”‚ Score Labels (what each score means)                                        â”‚
â”‚                                                                             â”‚
â”‚ Score 1: â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚          â”‚ No alignment with strategic goals                              â”‚ â”‚
â”‚          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚ Score 2: â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚          â”‚ Minimal alignment                                              â”‚ â”‚
â”‚          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚ Score 3: â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚          â”‚ Moderate alignment                                             â”‚ â”‚
â”‚          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚ Score 4: â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚          â”‚ Strong alignment                                               â”‚ â”‚
â”‚          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚ Score 5: â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚          â”‚ Critical to strategic goals                                    â”‚ â”‚
â”‚          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚                           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐               â”‚
â”‚                           â”‚ Cancel â”‚ â”‚ Save Changes         â”‚               â”‚
â”‚                           â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘               â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

### Tab 2: Technical Factors

Same layout as Business Factors, but:
- Shows T01-T15 (no T12)
- "Tech Risk" checkbox instead of "Criticality"
- Weight must sum to 100%

---

### Tab 3: Derived Scores

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Derived Scores                                                              â”‚
â”‚ These scores are calculated from the factor scores above.                   â”‚
â”‚                                                                             â”‚
â”‚ ðŸ”’ Upgrade to Enterprise to customize formulas            [Contact Sales]   â”‚
â”‚                                                                             â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚ Score          Formula                              Used In             â”‚ â”‚
â”‚ â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤ â”‚
â”‚ â”‚ Business Fit   Weighted avg of B1-B10               TIME (Y-axis)       â”‚ â”‚
â”‚ â”‚ Tech Health    Weighted avg of T01-T15              TIME (X-axis)       â”‚ â”‚
â”‚ â”‚ Criticality    Weighted avg of B1-B7                PAID (Y-axis)       â”‚ â”‚
â”‚ â”‚ Tech Risk      Weighted avg of T01-T05, T08, T11    PAID (X-axis)       â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚ To change which factors contribute to Criticality or Tech Risk,             â”‚
â”‚ use the checkboxes on the Business/Technical Factors tabs.                  â”‚
â”‚                                                                             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

### Tab 4: Thresholds

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Quadrant Thresholds                                                         â”‚
â”‚ These values determine where the quadrant boundaries are drawn.             â”‚
â”‚                                                                             â”‚
â”‚ ðŸ”’ Upgrade to Pro to customize thresholds                 [Upgrade to Pro]  â”‚
â”‚                                                                             â”‚
â”‚ TIME Quadrants                                                              â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â”‚   Business Fit Threshold        Tech Health Threshold                   â”‚ â”‚
â”‚ â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                     â”‚ â”‚
â”‚ â”‚   â”‚ 50              â”‚           â”‚ 50              â”‚                     â”‚ â”‚
â”‚ â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘           â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                     â”‚ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â”‚   Preview:                                                              â”‚ â”‚
â”‚ â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                                         â”‚ â”‚
â”‚ â”‚   â”‚   INVEST    â”‚  TOLERATE   â”‚  Business Fit â‰¥ 50                      â”‚ â”‚
â”‚ â”‚   â”‚  (high/high)â”‚ (high/low)  â”‚                                         â”‚ â”‚
â”‚ â”‚   â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€                      â”‚ â”‚
â”‚ â”‚   â”‚  MIGRATE    â”‚  ELIMINATE  â”‚  Business Fit < 50                      â”‚ â”‚
â”‚ â”‚   â”‚  (low/high) â”‚  (low/low)  â”‚                                         â”‚ â”‚
â”‚ â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                                         â”‚ â”‚
â”‚ â”‚      Tech â‰¥ 50     Tech < 50                                            â”‚ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚ PAID Quadrants                                                              â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â”‚   Criticality Threshold         Tech Risk Threshold                     â”‚ â”‚
â”‚ â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                     â”‚ â”‚
â”‚ â”‚   â”‚ 50              â”‚           â”‚ 50              â”‚                     â”‚ â”‚
â”‚ â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘           â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                     â”‚ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â”‚   Preview:                                                              â”‚ â”‚
â”‚ â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐                                         â”‚ â”‚
â”‚ â”‚   â”‚    PLAN     â”‚   ADDRESS   â”‚  Criticality â‰¥ 50                       â”‚ â”‚
â”‚ â”‚   â”‚ (high/low)  â”‚ (high/high) â”‚                                         â”‚ â”‚
â”‚ â”‚   â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€                      â”‚ â”‚
â”‚ â”‚   â”‚   IGNORE    â”‚    DELAY    â”‚  Criticality < 50                       â”‚ â”‚
â”‚ â”‚   â”‚  (low/low)  â”‚  (low/high) â”‚                                         â”‚ â”‚
â”‚ â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘                                         â”‚ â”‚
â”‚ â”‚     Risk < 50      Risk â‰¥ 50                                            â”‚ â”‚
â”‚ â”‚                                                                         â”‚ â”‚
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘ â”‚
â”‚                                                                             â”‚
â”‚                           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€┐ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐               â”‚
â”‚                           â”‚ Cancel â”‚ â”‚ Save Changes         â”‚               â”‚
â”‚                           â””â”€â”€â”€â”€â”€â”€â”€â”€┘ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘               â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Free Tier: Read-Only View

For Free tier users, the Assessment Configuration page shows:
- All factors and their current configuration
- "ðŸ”’ Upgrade to Pro" banner at the top
- All edit buttons disabled / grayed out
- Clicking any edit control shows upgrade modal

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ âš ï¸ Assessment Configuration is read-only on the Free tier                   â”‚
â”‚                                                                             â”‚
â”‚ Upgrade to Pro to:                                                          â”‚
â”‚ â€¢ Customize factor questions and descriptions                               â”‚
â”‚ â€¢ Adjust factor weightings                                                  â”‚
â”‚ â€¢ Change quadrant thresholds                                                â”‚
â”‚                                                                             â”‚
â”‚ Upgrade to Enterprise to:                                                   â”‚
â”‚ â€¢ Add or remove factors                                                     â”‚
â”‚ â€¢ Create custom derived scores                                              â”‚
â”‚ â€¢ Use alternative scoring scales                                            â”‚
â”‚                                                                             â”‚
â”‚                                              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐       â”‚
â”‚                                              â”‚ Upgrade Now          â”‚       â”‚
â”‚                                              â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘       â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Impact on Assessment UI

When factors are customized, the Assessment modal must:
1. Fetch factors from `assessment_factors` table (not hard-coded)
2. Display custom question text and descriptions
3. Show custom score labels (if defined)
4. Use custom weights for calculations

```tsx
// Before (hard-coded)
const businessFactors = [
  { id: 'b1', label: 'Alignment with Strategic Goals', weight: 10 },
  // ...
];

// After (from database)
const { data: businessFactors } = await supabase
  .from('assessment_factors')
  .select('*')
  .eq('namespace_id', namespaceId)
  .eq('factor_type', 'business')
  .eq('is_active', true)
  .order('sort_order');
```

---

## Score Calculation Updates

Calculations must use custom weights and factor selections:

```typescript
// Calculate Business Fit with custom weights
async function calculateBusinessFit(scores: Record<string, number>, namespaceId: string) {
  const { data: factors } = await supabase
    .from('assessment_factors')
    .select('factor_code, weight')
    .eq('namespace_id', namespaceId)
    .eq('factor_type', 'business')
    .eq('is_active', true);

  let weightedSum = 0;
  let totalWeight = 0;

  for (const factor of factors) {
    const score = scores[factor.factor_code.toLowerCase()];
    if (score !== null && score !== undefined) {
      weightedSum += score * factor.weight;
      totalWeight += factor.weight;
    }
  }

  // Normalize: (weightedSum / totalWeight) gives 1-5, convert to 0-100
  const rawScore = totalWeight > 0 ? weightedSum / totalWeight : 0;
  return ((rawScore - 1) / 4) * 100;
}

// Calculate Criticality (only factors with contributes_to_criticality = true)
async function calculateCriticality(scores: Record<string, number>, namespaceId: string) {
  const { data: factors } = await supabase
    .from('assessment_factors')
    .select('factor_code, weight')
    .eq('namespace_id', namespaceId)
    .eq('factor_type', 'business')
    .eq('contributes_to_criticality', true)
    .eq('is_active', true);

  // Same calculation as above with filtered factors
  // ...
}
```

---

## Navigation

Add to Settings menu (Namespace Admin only):

```
Settings
â”œâ”€â”€ Organization
â”œâ”€â”€ Workspaces
â”œâ”€â”€ Users
â”œâ”€â”€ Assessment Configuration  â† NEW
â””â”€â”€ Workspace Settings
```

---

## Implementation Order

1. **Database:** Create tables + seed trigger
2. **API:** Endpoints to fetch/update factors
3. **UI:** Assessment Configuration page (read-only for Free)
4. **Assessment Modal:** Fetch factors from database instead of hard-coded
5. **Calculations:** Update to use custom weights/factors
6. **Tier checks:** Enable editing only for Pro+

---

## Out of Scope (Future)

- Import/export factor configurations
- Factor templates (e.g., "Government", "Healthcare", "Finance")
- A/B testing different factor sets
- Historical tracking of configuration changes
- Per-workspace factor overrides (currently Namespace-level only)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-12-22 | Initial draft |
