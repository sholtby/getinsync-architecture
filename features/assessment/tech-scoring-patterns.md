# features/assessment/tech-scoring-patterns.md
Tech Scoring Patterns Architecture
Last updated: 2026-03-08

---

## 1. Purpose

Define the architecture for **Tech Scoring Patterns** — reusable sets of default T-score values that pre-fill technical assessments on Deployment Profiles, dramatically reducing assessment time for organizations with many applications deployed on common platforms.

**Problem:** An organization with 300+ applications may have 50 SharePoint sites, 30 Power Apps, 40 SaaS subscriptions, and 20 MS Access databases. Each shares near-identical technical characteristics, yet today every DP requires answering up to 14 T-questions from scratch. This creates assessment fatigue, inconsistency, and delays.

**Solution:** Scoring patterns capture proven T-score defaults for common deployment shapes. When an assessor opens a tech assessment, the system offers to pre-fill applicable scores. The assessor reviews, adjusts any deviations, and confirms — reducing a 10-minute questionnaire to a 30-second review.

**Status:** Design complete. Not yet built.

---

## 2. Design Principles

### 2.1 Applicability Rules Are the Gatekeeper

The existing `applicability_rules` JSONB on `assessment_factors` already implements a three-action model per hosting type:

| Action | Meaning | Pattern Interaction |
|--------|---------|---------------------|
| `ask` | Show question, user answers | **Pattern provides default value** |
| `auto_score` | System assigns value + reason, not editable | Pattern value ignored — system wins |
| `skip` | Factor not applicable, no score | Pattern value ignored — not shown |

Scoring patterns **only operate in the `ask` space**. They never override auto-scores or resurrect skipped factors. The rendering priority is:

1. `skip` → factor hidden, no score stored
2. `auto_score` → display system value + reason, greyed out, not editable
3. Pattern has value for this `ask` factor → pre-fill, editable, subtle "from pattern" indicator
4. No pattern or no value → blank field, user scores manually

### 2.2 Copied, Not Linked

When a pattern is applied, T-score values are **copied** to the Deployment Profile. Subsequent changes to the pattern do not retroactively alter existing assessments. This ensures assessment integrity — a completed assessment is a point-in-time snapshot.

Provenance is tracked: the DP records which pattern was applied. This enables reporting and a future "re-apply pattern" bulk action, but the link is informational, not live.

### 2.3 Hosting Type Is the Join Key

Every pattern is associated with a `hosting_type` (SaaS, Cloud, On-Prem, Desktop, Hybrid, Third-Party-Hosted). This is the primary matching dimension because:

- Applicability rules are keyed by hosting type
- A pattern's default values only make sense for factors that are `ask` under that hosting type
- The DP already has `hosting_type` set before assessment begins

### 2.4 Two-Tier Pattern Model

| Tier | Source | Scope | Example |
|------|--------|-------|---------|
| **Deployment-shape patterns** | Seeded on namespace creation | Generic — one per hosting type | "SaaS Application (General)" |
| **Product-specific patterns** | Created by users (bottom-up) | Linked to a Software Product | "SharePoint Online", "MS Access" |

Tier 1 solves cold start. Tier 2 builds itself organically through assessment workflow.

### 2.5 UI Naming

The entity is called **"Scoring Pattern"** in all user-facing surfaces. No CSDM terminology.

---

## 3. Applicability Rules Reference

All 14 technical factors have applicability rules. The current state in the template namespace:

### 3.1 SaaS Hosting Type

| Factor | Action | Auto Value | Reason |
|--------|--------|:---:|--------|
| T01 Platform Footprint | `auto_score` | 5 | SaaS delivered hosting |
| T02 Vendor Support | `ask` | — | |
| T03 Dev Platform | `auto_score` | 4 | Vendor manages platform currency |
| T04 Security Controls | `ask` | — | |
| T05 Resilience & Recovery | `auto_score` | 4 | Vendor manages resilience and recovery |
| T06 Observability | `ask` | — | |
| T07 Integration Capabilities | `ask` | — | |
| T08 Identity Assurance | `ask` | — | |
| T09 Platform Portability | `auto_score` | 3 | SaaS portability depends on data export |
| T10 Configurability | `ask` | — | |
| T11 Data Security | `ask` | — | |
| T12 Modern UX | `ask` | — | |
| T13 Integrations | `ask` | — | |
| T14 Data Accessibility | `ask` | — | |

**Summary:** 4 auto-scored, 10 ask, 0 skipped. A SaaS scoring pattern provides defaults for 10 factors.

### 3.2 Desktop Hosting Type

| Factor | Action | Auto Value | Reason |
|--------|--------|:---:|--------|
| T01 Platform Footprint | `auto_score` | 3 | Desktop apps have limited platform footprint |
| T02 Vendor Support | `ask` | — | |
| T03 Dev Platform | `skip` | — | Not applicable to desktop apps |
| T04 Security Controls | `ask` | — | |
| T05 Resilience & Recovery | `skip` | — | Not applicable to desktop apps |
| T06 Observability | `skip` | — | Not applicable to desktop apps |
| T07 Integration Capabilities | `ask` | — | |
| T08 Identity Assurance | `skip` | — | Desktop apps typically use local or domain auth |
| T09 Platform Portability | `skip` | — | Not applicable to desktop apps |
| T10 Configurability | `ask` | — | |
| T11 Data Security | `ask` | — | |
| T12 Modern UX | `ask` | — | |
| T13 Integrations | `ask` | — | |
| T14 Data Accessibility | `ask` | — | |

**Summary:** 1 auto-scored, 8 ask, 5 skipped. A Desktop scoring pattern provides defaults for 8 factors.

### 3.3 Cloud / On-Prem / Hybrid / Third-Party-Hosted

All 14 factors are `ask`. No auto-scores, no skips. A scoring pattern provides defaults for all 14 factors.

### 3.4 Business Factors

All 10 business factors (B1-B10) have empty applicability rules — they are universal across all hosting types. Business factors are **not** part of scoring patterns. B-scores are always assessed independently per portfolio assignment because the same deployment has different business value to different stakeholders.

---

## 4. Data Model

### 4.1 Tech Scoring Patterns Table

```sql
CREATE TABLE tech_scoring_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  hosting_type TEXT NOT NULL,
  software_product_id UUID REFERENCES software_products(id) ON DELETE SET NULL,
  
  -- T-score defaults (only 'ask' factor values are rendered; auto_score/skip ignored by UI)
  t01 INTEGER CHECK (t01 BETWEEN 1 AND 5),
  t02 INTEGER CHECK (t02 BETWEEN 1 AND 5),
  t03 INTEGER CHECK (t03 BETWEEN 1 AND 5),
  t04 INTEGER CHECK (t04 BETWEEN 1 AND 5),
  t05 INTEGER CHECK (t05 BETWEEN 1 AND 5),
  t06 INTEGER CHECK (t06 BETWEEN 1 AND 5),
  t07 INTEGER CHECK (t07 BETWEEN 1 AND 5),
  t08 INTEGER CHECK (t08 BETWEEN 1 AND 5),
  t09 INTEGER CHECK (t09 BETWEEN 1 AND 5),
  t10 INTEGER CHECK (t10 BETWEEN 1 AND 5),
  t11 INTEGER CHECK (t11 BETWEEN 1 AND 5),
  t12 INTEGER CHECK (t12 BETWEEN 1 AND 5),
  t13 INTEGER CHECK (t13 BETWEEN 1 AND 5),
  t14 INTEGER CHECK (t14 BETWEEN 1 AND 5),
  
  -- Metadata
  is_seeded BOOLEAN DEFAULT false NOT NULL,
  usage_count INTEGER DEFAULT 0 NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT uq_scoring_pattern_name UNIQUE(namespace_id, name),
  CONSTRAINT valid_hosting_type CHECK (hosting_type IN (
    'SaaS', 'Third-Party-Hosted', 'Cloud', 'On-Prem', 'Hybrid', 'Desktop'
  ))
);

COMMENT ON TABLE tech_scoring_patterns IS 
  'Reusable T-score defaults for common deployment shapes. Values pre-fill assessment for ask factors only; auto_score and skip factors are governed by applicability_rules on assessment_factors.';

COMMENT ON COLUMN tech_scoring_patterns.hosting_type IS 
  'Determines which applicability rules context this pattern operates in. Must match a valid hosting_type from the hosting_types reference table.';

COMMENT ON COLUMN tech_scoring_patterns.software_product_id IS 
  'Optional link to a software product. Enables auto-suggestion when a DP is linked to this product via deployment_profile_software_products.';

COMMENT ON COLUMN tech_scoring_patterns.is_seeded IS 
  'True for patterns copied from the template namespace on namespace creation. Seeded patterns can be modified or deleted by namespace admins.';

COMMENT ON COLUMN tech_scoring_patterns.usage_count IS 
  'Number of DPs that have applied this pattern. Incremented on apply, informational only.';
```

### 4.2 Deployment Profile Provenance Column

```sql
ALTER TABLE deployment_profiles 
  ADD COLUMN tech_scoring_pattern_id UUID REFERENCES tech_scoring_patterns(id) ON DELETE SET NULL;

COMMENT ON COLUMN deployment_profiles.tech_scoring_pattern_id IS 
  'Which scoring pattern was last applied to this DP. Informational provenance — scores are copied, not live-linked. NULL if assessed manually.';
```

### 4.3 Indexes

```sql
CREATE INDEX idx_tsp_namespace ON tech_scoring_patterns(namespace_id);
CREATE INDEX idx_tsp_hosting_type ON tech_scoring_patterns(namespace_id, hosting_type);
CREATE INDEX idx_tsp_software_product ON tech_scoring_patterns(software_product_id) 
  WHERE software_product_id IS NOT NULL;
CREATE INDEX idx_dp_scoring_pattern ON deployment_profiles(tech_scoring_pattern_id) 
  WHERE tech_scoring_pattern_id IS NOT NULL;
```

### 4.4 RLS Policies

```sql
ALTER TABLE tech_scoring_patterns ENABLE ROW LEVEL SECURITY;

-- All namespace users can view patterns
CREATE POLICY "Users can view scoring patterns in current namespace"
  ON tech_scoring_patterns FOR SELECT
  USING (namespace_id = get_current_namespace_id());

-- Admins can manage patterns
CREATE POLICY "Admins can insert scoring patterns in current namespace"
  ON tech_scoring_patterns FOR INSERT
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id()))
  );

CREATE POLICY "Admins can update scoring patterns in current namespace"
  ON tech_scoring_patterns FOR UPDATE
  USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id()))
  )
  WITH CHECK (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id()))
  );

CREATE POLICY "Admins can delete scoring patterns in current namespace"
  ON tech_scoring_patterns FOR DELETE
  USING (
    namespace_id = get_current_namespace_id()
    AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id()))
  );

-- GRANTs
GRANT SELECT ON tech_scoring_patterns TO authenticated;
GRANT SELECT ON tech_scoring_patterns TO service_role;
```

### 4.5 Audit Trigger

```sql
CREATE TRIGGER audit_tech_scoring_patterns
  AFTER INSERT OR UPDATE OR DELETE ON tech_scoring_patterns
  FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

### 4.6 Updated_at Trigger

```sql
CREATE TRIGGER set_updated_at_tech_scoring_patterns
  BEFORE UPDATE ON tech_scoring_patterns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 4.7 Seed Trigger

```sql
CREATE OR REPLACE FUNCTION copy_scoring_patterns_to_new_namespace()
RETURNS TRIGGER AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM tech_scoring_patterns WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no scoring patterns, skipping copy';
    RETURN NEW;
  END IF;

  INSERT INTO tech_scoring_patterns (
    namespace_id, name, description, hosting_type, software_product_id,
    t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12, t13, t14,
    is_seeded, usage_count, created_by
  )
  SELECT
    NEW.id, name, description, hosting_type, NULL,  -- No SP link for seeded patterns
    t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12, t13, t14,
    true, 0, NULL
  FROM tech_scoring_patterns
  WHERE namespace_id = v_template_namespace_id
    AND is_seeded = true;

  RAISE NOTICE 'Copied % scoring patterns to new namespace %',
    (SELECT COUNT(*) FROM tech_scoring_patterns WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path TO 'public';

CREATE TRIGGER trigger_copy_scoring_patterns_to_new_namespace
  AFTER INSERT ON namespaces
  FOR EACH ROW EXECUTE FUNCTION copy_scoring_patterns_to_new_namespace();
```

---

## 5. Seeded Patterns (Tier 1)

Six patterns, one per hosting type. These populate the template namespace and get copied to every new namespace.

Values represent defensible baselines. Namespace admins can modify or delete.

### 5.1 SaaS Application (General)

Only `ask` factors scored (4 auto-scored factors handled by applicability rules).

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T02 Vendor Support | 4 | Commercial SaaS vendors provide active support |
| T04 Security Controls | 4 | Enterprise SaaS typically has strong security posture |
| T06 Observability | 3 | Limited to vendor-provided dashboards and logs |
| T07 Integration Capabilities | 3 | API availability varies by vendor |
| T08 Identity Assurance | 4 | Most enterprise SaaS supports SSO/SAML |
| T10 Configurability | 3 | Configuration yes, deep customization typically no |
| T11 Data Security | 3 | Depends on data classification and vendor controls |
| T12 Modern UX | 4 | SaaS vendors invest heavily in UX |
| T13 Integrations | 3 | Varies by product maturity |
| T14 Data Accessibility | 3 | Reporting often limited to vendor exports |

### 5.2 Cloud Application

All 14 factors are `ask` for Cloud hosting type.

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T01 Platform Footprint | 4 | Cloud-native typically modern architecture |
| T02 Vendor Support | 4 | Cloud platforms well-supported |
| T03 Dev Platform | 4 | Modern frameworks typical |
| T04 Security Controls | 3 | Shared responsibility model — varies by config |
| T05 Resilience & Recovery | 3 | Cloud enables HA but must be configured |
| T06 Observability | 3 | Cloud-native monitoring available but setup varies |
| T07 Integration Capabilities | 4 | APIs and messaging typical in cloud |
| T08 Identity Assurance | 4 | IAM services standard in cloud platforms |
| T09 Platform Portability | 3 | Depends on managed vs cloud-native services |
| T10 Configurability | 4 | Infrastructure as Code enables extensibility |
| T11 Data Security | 3 | Encryption available but classification drives rating |
| T12 Modern UX | 4 | Cloud apps typically modern |
| T13 Integrations | 4 | Cloud apps generally integration-friendly |
| T14 Data Accessibility | 4 | Cloud platforms provide data access tooling |

### 5.3 On-Premises Server Application

All 14 factors are `ask`.

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T01 Platform Footprint | 3 | Depends on age and architecture |
| T02 Vendor Support | 3 | Support varies — some legacy apps have limited support |
| T03 Dev Platform | 2 | On-prem often runs older development frameworks |
| T04 Security Controls | 3 | Security depends on organizational patching discipline |
| T05 Resilience & Recovery | 2 | DR often manual or limited |
| T06 Observability | 2 | Monitoring varies widely, often basic |
| T07 Integration Capabilities | 2 | Older apps may lack API support |
| T08 Identity Assurance | 3 | AD integration common but not always modern |
| T09 Platform Portability | 2 | Often tied to specific OS/hardware |
| T10 Configurability | 3 | Depends on application maturity |
| T11 Data Security | 3 | Physical control is strong; encryption varies |
| T12 Modern UX | 2 | On-prem apps often have dated interfaces |
| T13 Integrations | 2 | File-based or database-level integration common |
| T14 Data Accessibility | 3 | Direct database access often possible |

### 5.4 Desktop Application

Only `ask` factors scored (1 auto-scored, 5 skipped by applicability rules).

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T02 Vendor Support | 3 | Varies — some actively maintained, some abandonware |
| T04 Security Controls | 2 | Local data storage, limited audit trails |
| T07 Integration Capabilities | 2 | Desktop apps often lack API interfaces |
| T10 Configurability | 2 | Limited to application settings |
| T11 Data Security | 2 | Local files often unencrypted |
| T12 Modern UX | 2 | Desktop UI often dated |
| T13 Integrations | 2 | File export/import typical integration pattern |
| T14 Data Accessibility | 2 | Reporting limited to built-in reports or file exports |

### 5.5 Hybrid Application

All 14 factors are `ask`. Scores blend SaaS and On-Prem characteristics.

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T01 Platform Footprint | 3 | Split architecture adds complexity |
| T02 Vendor Support | 3 | Support model often fragmented |
| T03 Dev Platform | 3 | Mixed technology stack |
| T04 Security Controls | 3 | Must secure both cloud and on-prem components |
| T05 Resilience & Recovery | 3 | DR must cover both environments |
| T06 Observability | 2 | Monitoring across environments is challenging |
| T07 Integration Capabilities | 3 | Integration between environments adds complexity |
| T08 Identity Assurance | 3 | Must bridge identity across environments |
| T09 Platform Portability | 2 | Harder to migrate due to split architecture |
| T10 Configurability | 3 | Depends on which components are cloud vs on-prem |
| T11 Data Security | 3 | Data may reside in multiple locations |
| T12 Modern UX | 3 | Often modern frontend with legacy backend |
| T13 Integrations | 3 | Cross-environment data flow required |
| T14 Data Accessibility | 3 | Data distributed across environments |

### 5.6 Third-Party-Hosted Application

All 14 factors are `ask`.

| Factor | Score | Rationale |
|--------|:---:|-----------|
| T01 Platform Footprint | 3 | Vendor controls hosting; org has limited visibility |
| T02 Vendor Support | 3 | Depends on vendor contract and responsiveness |
| T03 Dev Platform | 3 | Vendor-managed, limited org control |
| T04 Security Controls | 3 | Trust but verify — depends on vendor audit reports |
| T05 Resilience & Recovery | 3 | Vendor-managed DR, limited org visibility |
| T06 Observability | 2 | Monitoring limited to what vendor exposes |
| T07 Integration Capabilities | 3 | API availability depends on vendor |
| T08 Identity Assurance | 3 | SSO depends on vendor support |
| T09 Platform Portability | 2 | Data portability depends on contract terms |
| T10 Configurability | 3 | Configuration within vendor constraints |
| T11 Data Security | 3 | Contractual controls, limited direct oversight |
| T12 Modern UX | 3 | Vendor-dependent |
| T13 Integrations | 3 | Vendor-dependent |
| T14 Data Accessibility | 3 | Reporting depends on vendor tools and data exports |

---

## 6. UX Flows

### 6.1 Pattern Matching Hierarchy

When a DP's tech assessment is opened, the system determines which pattern(s) to suggest:

```
1. Check DP → deployment_profile_software_products → software_product_id
2. Find tech_scoring_patterns WHERE software_product_id = match AND hosting_type = DP.hosting_type
3. If found → offer exact match: "Apply SharePoint Online scoring pattern?"
4. If not found → find WHERE hosting_type = DP.hosting_type AND software_product_id IS NULL
5. If found → offer generic: "Apply SaaS Application (General) scoring pattern?"
6. If multiple → show dropdown of all matching patterns for this hosting type
7. If none → no suggestion, manual assessment
```

### 6.2 Apply Pattern (Assessment Screen)

```
┌─────────────────────────────────────────────────────────────┐
│ Technical Assessment — SharePoint HR Portal                  │
│ Hosting: SaaS                                                │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ 💡 A scoring pattern is available for this deployment.  │  │
│ │    SharePoint Online (10 of 14 factors pre-filled)      │  │
│ │    [Apply Pattern]   [Skip — I'll score manually]       │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
│ Platform Architecture & Hosting                              │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ T01 Platform / Product Footprint          5  🔒 auto    │  │
│ │     SaaS delivered hosting                              │  │
│ │                                                         │  │
│ │ T03 Application Development Platform      4  🔒 auto    │  │
│ │     Vendor manages platform currency                    │  │
│ │                                                         │  │
│ │ T09 Platform Portability                  3  🔒 auto    │  │
│ │     SaaS portability depends on data export             │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
│ Resilience & Operations                                      │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ T02 Vendor and Support Availability   [4 ▼]  📋 pattern │  │
│ │                                                         │  │
│ │ T05 Resilience & Recovery                 4  🔒 auto    │  │
│ │     Vendor manages resilience and recovery              │  │
│ │                                                         │  │
│ │ T06 Observability & Manageability     [3 ▼]  📋 pattern │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
│ Security Posture                                             │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ T04 Security Controls                 [4 ▼]  📋 pattern │  │
│ │ T08 Identity Assurance                [4 ▼]  📋 pattern │  │
│ │ T11 Data Security                     [3 ▼]  📋 pattern │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
│ [Continue to Review]                                         │
└─────────────────────────────────────────────────────────────┘

Legend:
  🔒 auto    = Auto-scored by applicability rule (not editable)
  📋 pattern = Pre-filled by scoring pattern (editable)
  [N ▼]      = Dropdown, user can change
```

### 6.3 Save As Scoring Pattern (Post-Assessment)

After completing a tech assessment, if the DP was scored manually (no pattern applied):

```
┌─────────────────────────────────────────────────────────────┐
│ ✅ Technical assessment complete.                            │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ 💡 Save these scores as a scoring pattern?              │  │
│ │    Future assessments for similar deployments can        │  │
│ │    start from these values.                             │  │
│ │                                                         │  │
│ │ Name: [________________________]                        │  │
│ │ Description: [________________________] (optional)      │  │
│ │ Hosting Type: SaaS (auto-filled from DP)               │  │
│ │ Link to Software Product: [SharePoint Online ▼]         │  │
│ │                                                         │  │
│ │ [Save Pattern]   [No Thanks]                            │  │
│ └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

When saving, all 14 T-score values from the DP are copied to the pattern (including auto-scored values). The UI rendering logic filters at display time.

If the DP was assessed using a pattern but the user modified scores, offer a variation: *"Your scores differ from the SharePoint Online pattern. Save as a new pattern?"*

### 6.4 Pattern Management (Admin)

Accessible from namespace Settings (alongside Assessment Configuration):

```
┌─────────────────────────────────────────────────────────────┐
│ Settings > Scoring Patterns                    [+ New Pattern]│
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ NAME                    │ HOSTING  │ PRODUCT    │ USED  │  │
│ │ SaaS Application        │ SaaS     │ —          │ 47    │  │
│ │ Cloud Application       │ Cloud    │ —          │ 23    │  │
│ │ On-Prem Server App      │ On-Prem  │ —          │ 31    │  │
│ │ Desktop Application     │ Desktop  │ —          │ 12    │  │
│ │ Hybrid Application      │ Hybrid   │ —          │ 5     │  │
│ │ Third-Party Hosted      │ TPH      │ —          │ 8     │  │
│ │─────────────────────────┤──────────┤────────────┤───────│  │
│ │ SharePoint Online       │ SaaS     │ SharePoint │ 48    │  │
│ │ Power Apps              │ SaaS     │ Power Apps │ 15    │  │
│ │ MS Access               │ Desktop  │ MS Access  │ 20    │  │
│ │ ESRI ArcGIS Online      │ SaaS     │ ESRI AGOL  │ 7     │  │
│ │ Oracle Forms (Legacy)   │ On-Prem  │ Oracle     │ 4     │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
│ Top 6 rows = seeded (modifiable). Bottom rows = user-created.│
└─────────────────────────────────────────────────────────────┘
```

### 6.5 Deviation Reporting (Future Enhancement)

When a DP has a `tech_scoring_pattern_id` set, the system can compute deviation:

```
Deviation % = count(factors where DP.tNN != pattern.tNN) / count(applicable 'ask' factors)
```

Surfaced as a data quality indicator on the dashboard or in a reporting view:

- *"48 of 50 SharePoint sites match the pattern. 2 have deviations worth reviewing."*
- Clicking shows which DPs deviate and which factors differ.

**Scope:** Future enhancement, not in initial build.

---

## 7. Pattern Application Logic (Frontend)

### 7.1 Pseudocode

```typescript
interface PatternApplicationResult {
  factor_code: string;
  action: 'auto_score' | 'skip' | 'pattern_fill' | 'manual';
  value: number | null;
  editable: boolean;
  source_label: string | null;   // "SaaS delivered hosting" or "from SharePoint Online pattern"
}

function resolveAssessmentField(
  factor: AssessmentFactor,
  hostingType: string,
  pattern: TechScoringPattern | null
): PatternApplicationResult {
  const rule = factor.applicability_rules[hostingType];
  
  if (!rule || rule.action === 'skip') {
    return { action: 'skip', value: null, editable: false, source_label: null };
  }
  
  if (rule.action === 'auto_score') {
    return { action: 'auto_score', value: rule.value, editable: false, source_label: rule.reason };
  }
  
  // rule.action === 'ask'
  const patternValue = pattern?.[`t${factor.factor_code.slice(1)}`] ?? null;
  
  if (patternValue !== null) {
    return { action: 'pattern_fill', value: patternValue, editable: true, 
             source_label: `from ${pattern.name} pattern` };
  }
  
  return { action: 'manual', value: null, editable: true, source_label: null };
}
```

### 7.2 Score Write Logic

When the user confirms assessment:

1. For each `auto_score` factor: write `rule.value` to `deployment_profiles.tNN`
2. For each `pattern_fill` or `manual` factor: write user's selected value to `deployment_profiles.tNN`
3. For each `skip` factor: write NULL to `deployment_profiles.tNN`
4. Set `deployment_profiles.tech_scoring_pattern_id` = applied pattern ID (or NULL if manual)
5. Set `deployment_profiles.tech_assessment_status` = 'complete'
6. Increment `tech_scoring_patterns.usage_count` if pattern was applied
7. Trigger `auto_calculate_deployment_profile_tech_scores` fires automatically

---

## 8. Queries

### 8.1 Find Best Pattern for a DP

```sql
-- Returns best-match pattern: product-specific first, then hosting-type generic
SELECT tsp.*
FROM tech_scoring_patterns tsp
WHERE tsp.namespace_id = :namespace_id
  AND tsp.hosting_type = :dp_hosting_type
ORDER BY 
  CASE WHEN tsp.software_product_id = :dp_software_product_id THEN 0 ELSE 1 END,
  tsp.usage_count DESC
LIMIT 1;
```

Note: `:dp_software_product_id` comes from `deployment_profile_software_products` where `deployment_profile_id = :dp_id` (use the first/primary software product if multiple are linked).

### 8.2 All Patterns for a Hosting Type

```sql
SELECT tsp.*, sp.name AS software_product_name
FROM tech_scoring_patterns tsp
LEFT JOIN software_products sp ON sp.id = tsp.software_product_id
WHERE tsp.namespace_id = :namespace_id
  AND tsp.hosting_type = :hosting_type
ORDER BY 
  CASE WHEN tsp.software_product_id IS NULL THEN 1 ELSE 0 END,
  tsp.name;
```

### 8.3 Pattern Usage Report

```sql
SELECT 
  tsp.name,
  tsp.hosting_type,
  tsp.usage_count,
  COUNT(dp.id) AS current_dp_count,
  COUNT(dp.id) FILTER (WHERE dp.tech_assessment_status = 'complete') AS assessed_count
FROM tech_scoring_patterns tsp
LEFT JOIN deployment_profiles dp ON dp.tech_scoring_pattern_id = tsp.id
WHERE tsp.namespace_id = :namespace_id
GROUP BY tsp.id, tsp.name, tsp.hosting_type, tsp.usage_count
ORDER BY tsp.usage_count DESC;
```

---

## 9. Implementation Phases

| Phase | Scope | Effort | Dependencies |
|-------|-------|--------|--------------|
| **A** | Schema: `tech_scoring_patterns` table + RLS + audit + updated_at + indexes + `tech_scoring_pattern_id` on DP + seed trigger | ~2 hrs | None |
| **B** | Seed data: populate 6 hosting-type patterns in template namespace | ~1 hr | Phase A |
| **C** | Admin UI: scoring pattern CRUD in namespace Settings (alongside Assessment Configuration) | ~3-4 hrs | Phase A |
| **D** | Assessment integration: pattern suggestion banner, pre-fill logic, visual indicators (🔒 auto / 📋 pattern), provenance tracking | ~3-4 hrs | Phase A, C |
| **E** | Save as pattern: post-assessment "Save as scoring pattern" action + auto-fill hosting type and optional software product link | ~2 hrs | Phase D |

**Total estimate:** ~12-14 hours

**Phase A+B** are pure SQL with no frontend — can be deployed independently and validated with pgTAP.

**Phase C** can be developed in parallel with D since it's a standalone settings page.

**Phase D+E** are the assessment UX integration — the highest-value deliverable.

---

## 10. Decisions Log

| Question | Decision | Rationale |
|----------|----------|-----------|
| Store pattern values for auto_score factors? | Yes — store all, render selectively | Simpler save logic; future-proofs against applicability rule changes |
| Pattern linked or copied to DP? | Copied | Assessment integrity — completed assessment is point-in-time |
| Pattern per hosting type or span multiple? | One hosting type per pattern | Applicability rules are keyed by hosting type; spanning would create ambiguity |
| Who can create patterns? | Admin/namespace admin via Settings; any assessor via "Save as" | Top-down planning + bottom-up organic creation |
| Who can apply patterns? | Any user who can assess (editor+) | Pattern application is part of assessment workflow |
| Seeded patterns editable? | Yes | Namespace admin should customize baselines for their context |
| Seeded patterns deletable? | Yes | No locked system records |
| Pattern tracks tech_health/tech_risk? | No — computed on DP by existing trigger | Pattern is just T-score defaults; composite scores live on DP |
| Separate table vs columns on software_products? | Separate table | Not all products need patterns; patterns can be product-independent; keeps catalog clean |
| B-scores in patterns? | No | Business value is stakeholder-specific, not deployment-shape-specific |

---

## 11. Related Documents

| Document | Relevance |
|----------|-----------|
| core/deployment-profile.md | DP-centric assessment model (scoring pattern attaches here) |
| core/composite-application.md | Suite relationships — v2.0: child DPs with `inherits_tech_from` are NOT offered scoring patterns (§13) |
| catalogs/software-product.md | Software Product catalog (optional pattern link) |
| features/technology-health/technology-stack-erd.md | Technology stack architecture |
| operations/development-rules.md | Schema creation checklist (§2.1) |
| operations/session-end-checklist.md | Post-implementation validation |

---

## 12. Future Enhancements

| Enhancement | Description | Depends On |
|-------------|-------------|------------|
| Deviation reporting | Surface DPs that deviate from their applied pattern | Phase D deployed |
| Re-apply pattern (bulk) | Update all DPs using pattern X with latest values | Phase D deployed |
| Pattern versioning | Track when pattern scores change, show diff | Phase C deployed |
| Suite auto-suggestion | When a parent DP has a pattern applied, display that pattern name on child DPs as context (informational only — child T-scores are inherited, not pattern-applied) | Suite relationships feature |
| CSV import pattern assignment | Bulk-assign patterns during large imports | CSV import feature |
| Validated vs Draft status | Admin marks patterns as organizational standard; visual trust indicator | Phase C deployed |

### Suite Interaction Rule (Updated Mar 2026)

When a DP has `inherits_tech_from` set (i.e., it is a suite child):
- **Scoring patterns are NOT offered** during assessment — the child's T-scores come from the parent's DP, not from a pattern
- The parent DP can use scoring patterns normally
- If the parent re-applies or changes its pattern, the child's displayed scores update automatically (child has no local T-scores to conflict)
- The "Suite auto-suggestion" enhancement above is informational only — it shows which pattern the parent uses, but does not apply scores to the child

**Cross-reference:** `core/composite-application.md` v2.0 §13

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-08 | Initial design. Schema, applicability rules integration, seeded patterns, UX flows, implementation phases. |

---

*Document: features/assessment/tech-scoring-patterns.md*
*March 2026*
