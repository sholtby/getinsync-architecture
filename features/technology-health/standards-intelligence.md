# Technology Standards Intelligence Architecture

**Document:** `features/technology-health/standards-intelligence.md`
**Version:** v1.2
**Status:** 🟢 AS-BUILT (Phase 1)
**Author:** Stuart Holtby
**Date:** 2026-03-11
**Repo path:** `features/technology-health/standards-intelligence.md`

---

## 1. Problem Statement

Organizations make technology choices over years — OS versions, database engines, middleware, web servers — but rarely document those choices as formal standards. The result: shadow standards embedded in the data, invisible to decision-makers.

GetInSync already captures the raw material. Every deployment profile is tagged with technology products organized by category. The prevalence patterns in that data **are** the organization's implied technology standards. If 87% of your deployments run Windows Server and 92% use SQL Server, those are standards — whether anyone wrote them down or not.

**This feature reverse-engineers standards from the technology tagging data, surfaces them for human review, and lets an authorized user assert or deny standard status.** Phase 1 is read-only intelligence. Phase 2 integrates with T-scores and Roadmap Findings. Phase 3 connects the AI agent to generate reference architecture documents from asserted standards.

**Enterprise pain point:** When organizations issue RFPs, the "reference architecture" section is typically written by a senior architect from memory — out of date by the time ink hits paper, never reconciled against what's actually deployed. Standards Intelligence + the AI agent eliminates that gap: the data-grounded standards become the reference architecture, narrated by the agent.

---

## 2. Concepts

### 2.1 Implied Standard

A technology product family that appears on a significant proportion of deployment profiles within a category. Computed, not configured. The system detects it; a human confirms or denies it.

**Detection rule:** Within a technology product category (e.g., "Database"), group by `product_family`. Any family appearing on ≥ 40% of tagged DPs in that category is flagged as an **implied standard**. The threshold is configurable at the namespace level (default: 40%).

### 2.2 Asserted Standard

An implied standard that has been reviewed and explicitly confirmed by a namespace admin. Assertion records who approved it, when, and optionally which specific product version is preferred.

### 2.3 Standard Status Lifecycle

```
[not detected] → implied → asserted_standard
                         → asserted_non_standard
                         → under_review
                         → retiring (sunset date set)
```

| Status | Meaning |
|--------|---------|
| `implied` | System-detected from prevalence data. No human review yet. |
| `standard` | Human-confirmed: this is an intentional organizational choice. |
| `non_standard` | Human-reviewed and explicitly marked as NOT a standard (e.g., legacy, exception, pilot). |
| `under_review` | Flagged for governance review. Neither confirmed nor denied. |
| `retiring` | Currently standard but has a planned sunset date. |

### 2.4 Preferred Version

Within a standard family, the specific product version the organization recommends for new deployments. Example: family = "Windows Server", preferred version = "Windows Server 2022". A standard can exist without a preferred version (family-only assertion).

### 2.5 Conformance

A deployment profile's technology tag is **conforming** if it matches an asserted standard's family (and optionally its preferred version). **Non-conforming** tags are technology choices that deviate from asserted standards. **Unassessed** tags are in categories or families where no standard has been asserted.

### 2.6 Standards Readiness

A pre-generation check that evaluates whether the namespace's standards data is complete enough to produce a useful reference architecture. Separate from the generation itself — an admin should know what gaps exist before they ask the agent to write anything. See §8.

---

## 3. Data Model

### 3.1 New Table: `technology_standards`

One row per category + product_family combination per namespace.

```sql
CREATE TABLE public.technology_standards (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    namespace_id uuid NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    category_id uuid NOT NULL REFERENCES technology_product_categories(id),
    product_family text NOT NULL,
    preferred_product_id uuid REFERENCES technology_products(id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'implied',
    prevalence_pct numeric(5,2),           -- last computed: % of tagged DPs in this category
    dp_count integer,                       -- last computed: absolute count of DPs using this family
    total_category_dp_count integer,        -- last computed: total DPs tagged in this category
    detection_threshold numeric(5,2) DEFAULT 40.00,  -- namespace-configurable
    asserted_by uuid REFERENCES users(id) ON DELETE SET NULL,
    asserted_at timestamp with time zone,
    sunset_date date,                       -- for 'retiring' status
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),

    CONSTRAINT technology_standards_status_check
        CHECK (status IN ('implied', 'standard', 'non_standard', 'under_review', 'retiring')),
    CONSTRAINT technology_standards_namespace_category_family_key
        UNIQUE (namespace_id, category_id, product_family),
    CONSTRAINT technology_standards_prevalence_check
        CHECK (prevalence_pct IS NULL OR (prevalence_pct >= 0 AND prevalence_pct <= 100))
);

COMMENT ON TABLE public.technology_standards IS
    'Namespace-level technology standards, reverse-engineered from deployment profile technology tags. '
    'Each row represents one product family within one technology category. '
    'Status lifecycle: implied → standard | non_standard | under_review | retiring.';

COMMENT ON COLUMN public.technology_standards.product_family IS
    'Matches technology_products.product_family. The family-level standard (e.g., "Windows Server").';

COMMENT ON COLUMN public.technology_standards.preferred_product_id IS
    'Optional: specific version recommended for new deployments (e.g., Windows Server 2022).';

COMMENT ON COLUMN public.technology_standards.prevalence_pct IS
    'Percentage of DPs in this category that use this family. Recomputed by detection view/RPC.';

COMMENT ON COLUMN public.technology_standards.detection_threshold IS
    'Prevalence percentage above which the system flags a family as an implied standard. Default 40%.';
```

### 3.2 Security Posture

Standard 4-policy pattern + audit trigger:

```sql
-- RLS
ALTER TABLE technology_standards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view technology_standards in current namespace"
    ON technology_standards FOR SELECT
    USING (namespace_id = get_current_namespace_id());

CREATE POLICY "Admins can insert technology_standards in current namespace"
    ON technology_standards FOR INSERT
    WITH CHECK (namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id())));

CREATE POLICY "Admins can update technology_standards in current namespace"
    ON technology_standards FOR UPDATE
    USING (namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id())))
    WITH CHECK (namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id())));

CREATE POLICY "Admins can delete technology_standards in current namespace"
    ON technology_standards FOR DELETE
    USING (namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(get_current_namespace_id())));

-- GRANTs
GRANT SELECT ON technology_standards TO authenticated;
GRANT INSERT, UPDATE, DELETE ON technology_standards TO authenticated;

-- Audit
CREATE TRIGGER audit_technology_standards
    AFTER INSERT OR UPDATE OR DELETE ON technology_standards
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- updated_at
CREATE TRIGGER set_updated_at_technology_standards
    BEFORE UPDATE ON technology_standards
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 3.3 New View: `vw_implied_technology_standards`

The detection engine. Aggregates technology tags by category + product_family and computes prevalence. This is the query that reverse-engineers standards from the data.

```sql
CREATE VIEW public.vw_implied_technology_standards
WITH (security_invoker = 'true') AS
WITH category_dp_counts AS (
    -- Total distinct DPs per category per namespace
    SELECT
        w.namespace_id,
        tp.category_id,
        tpc.name AS category_name,
        COUNT(DISTINCT dptp.deployment_profile_id) AS total_dps_in_category
    FROM deployment_profile_technology_products dptp
    JOIN technology_products tp ON tp.id = dptp.technology_product_id
    JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
    JOIN applications a ON a.id = dp.application_id
    JOIN workspaces w ON w.id = dp.workspace_id
    JOIN technology_product_categories tpc ON tpc.id = tp.category_id
    WHERE a.operational_status = 'operational'
    GROUP BY w.namespace_id, tp.category_id, tpc.name
),
family_counts AS (
    -- DPs per product_family per category per namespace
    SELECT
        w.namespace_id,
        tp.category_id,
        COALESCE(NULLIF(tp.product_family, ''), tp.name) AS product_family,
        COUNT(DISTINCT dptp.deployment_profile_id) AS dp_count,
        COUNT(DISTINCT dp.application_id) AS app_count,
        -- Best lifecycle status in this family
        MIN(
            CASE
                WHEN tlr.end_of_life_date IS NOT NULL AND tlr.end_of_life_date < CURRENT_DATE THEN 4
                WHEN tlr.extended_support_end IS NOT NULL AND tlr.extended_support_end < CURRENT_DATE THEN 3
                WHEN tlr.mainstream_support_end IS NOT NULL AND tlr.mainstream_support_end < CURRENT_DATE THEN 2
                WHEN tlr.ga_date IS NOT NULL AND tlr.ga_date <= CURRENT_DATE THEN 1
                ELSE 5
            END
        ) AS best_lifecycle_rank,
        -- Most common specific product in this family
        MODE() WITHIN GROUP (ORDER BY tp.name) AS most_common_product,
        -- Count of distinct versions in use
        COUNT(DISTINCT tp.id) AS version_count
    FROM deployment_profile_technology_products dptp
    JOIN technology_products tp ON tp.id = dptp.technology_product_id
    JOIN deployment_profiles dp ON dp.id = dptp.deployment_profile_id
    JOIN applications a ON a.id = dp.application_id
    JOIN workspaces w ON w.id = dp.workspace_id
    LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
    WHERE a.operational_status = 'operational'
    GROUP BY w.namespace_id, tp.category_id, COALESCE(NULLIF(tp.product_family, ''), tp.name)
)
SELECT
    fc.namespace_id,
    fc.category_id,
    cdc.category_name,
    fc.product_family,
    fc.dp_count,
    fc.app_count,
    cdc.total_dps_in_category,
    ROUND((fc.dp_count::numeric / NULLIF(cdc.total_dps_in_category, 0)) * 100, 2) AS prevalence_pct,
    fc.most_common_product,
    fc.version_count,
    CASE fc.best_lifecycle_rank
        WHEN 1 THEN 'mainstream'
        WHEN 2 THEN 'extended'
        WHEN 3 THEN 'end_of_support'
        WHEN 4 THEN 'end_of_life'
        ELSE 'unknown'
    END AS best_lifecycle_status,
    -- Has this family already been asserted?
    ts.id AS standard_id,
    ts.status AS asserted_status,
    ts.preferred_product_id,
    pp.name AS preferred_product_name
FROM family_counts fc
JOIN category_dp_counts cdc
    ON cdc.namespace_id = fc.namespace_id AND cdc.category_id = fc.category_id
LEFT JOIN technology_standards ts
    ON ts.namespace_id = fc.namespace_id
    AND ts.category_id = fc.category_id
    AND ts.product_family = fc.product_family
LEFT JOIN technology_products pp
    ON pp.id = ts.preferred_product_id
ORDER BY fc.namespace_id, cdc.category_name, fc.dp_count DESC;

COMMENT ON VIEW public.vw_implied_technology_standards IS
    'Reverse-engineers technology standards from deployment profile tags. '
    'Groups by category + product_family, computes prevalence, '
    'and joins to asserted standards for review status.';
```

### 3.4 New View: `vw_technology_standards_summary`

Dashboard-level KPIs for the standards feature.

```sql
CREATE VIEW public.vw_technology_standards_summary
WITH (security_invoker = 'true') AS
SELECT
    its.namespace_id,
    COUNT(DISTINCT its.category_id) AS categories_with_data,
    COUNT(*) FILTER (WHERE its.asserted_status IS NULL
        AND its.prevalence_pct >= 40) AS implied_pending_review,  -- Phase 1: hardcoded 40%. Phase 2: read from namespace setting or per-row threshold.
    COUNT(*) FILTER (WHERE its.asserted_status = 'standard') AS asserted_standard_count,
    COUNT(*) FILTER (WHERE its.asserted_status = 'non_standard') AS asserted_non_standard_count,
    COUNT(*) FILTER (WHERE its.asserted_status = 'under_review') AS under_review_count,
    COUNT(*) FILTER (WHERE its.asserted_status = 'retiring') AS retiring_count,
    -- Dominant family per category (highest prevalence)
    COUNT(DISTINCT its.category_id) FILTER (
        WHERE its.prevalence_pct >= 70
    ) AS strong_standard_categories
FROM vw_implied_technology_standards its
GROUP BY its.namespace_id;

COMMENT ON VIEW public.vw_technology_standards_summary IS
    'Namespace-level KPI aggregation for technology standards intelligence. '
    'Counts implied, asserted, and under-review standards across all categories.';
```

---

## 4. Detection & Assertion Flow

### 4.1 Detection Algorithm

The `vw_implied_technology_standards` view runs the detection on every query. No background job needed — the data is always current.

**Prevalence calculation:**
```
prevalence_pct = (DPs using this family in category / Total DPs tagged in category) × 100
```

**Key behaviors:**
- Only counts DPs on **operational** applications (excludes retired, decommissioned).
- Uses `COALESCE(NULLIF(tp.product_family, ''), tp.name)` so products without a `product_family` value (NULL or empty string) still participate (grouped by their individual name).
- A family appearing on ≥ threshold (default 40%) is an implied standard candidate.
- Families below threshold are visible but not flagged — the UI shows all families ranked by prevalence.

### 4.2 Assertion RPC

```sql
CREATE OR REPLACE FUNCTION assert_technology_standard(
    p_namespace_id uuid,
    p_category_id uuid,
    p_product_family text,
    p_status text,
    p_preferred_product_id uuid DEFAULT NULL,
    p_notes text DEFAULT NULL,
    p_sunset_date date DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_standard_id uuid;
BEGIN
    -- Verify caller is admin
    IF NOT (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(p_namespace_id)) THEN
        RAISE EXCEPTION 'Only namespace admins can assert technology standards';
    END IF;

    -- Validate status
    IF p_status NOT IN ('standard', 'non_standard', 'under_review', 'retiring') THEN
        RAISE EXCEPTION 'Invalid status: %. Must be standard, non_standard, under_review, or retiring.', p_status;
    END IF;

    -- Upsert
    INSERT INTO technology_standards (
        namespace_id, category_id, product_family, status,
        preferred_product_id, asserted_by, asserted_at,
        notes, sunset_date
    ) VALUES (
        p_namespace_id, p_category_id, p_product_family, p_status,
        p_preferred_product_id, v_user_id, now(),
        p_notes, p_sunset_date
    )
    ON CONFLICT (namespace_id, category_id, product_family)
    DO UPDATE SET
        status = EXCLUDED.status,
        preferred_product_id = EXCLUDED.preferred_product_id,
        asserted_by = EXCLUDED.asserted_by,
        asserted_at = EXCLUDED.asserted_at,
        notes = EXCLUDED.notes,
        sunset_date = EXCLUDED.sunset_date,
        updated_at = now()
    RETURNING id INTO v_standard_id;

    RETURN v_standard_id;
END;
$$;
```

### 4.3 Prevalence Refresh

Prevalence stats on the `technology_standards` table (`prevalence_pct`, `dp_count`, `total_category_dp_count`) are snapshot values updated when:

1. A user opens the Standards Intelligence page (frontend calls refresh RPC).
2. A technology tag is added/removed (optional trigger — Phase 2).

```sql
CREATE OR REPLACE FUNCTION refresh_technology_standard_prevalence(
    p_namespace_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    UPDATE technology_standards ts
    SET
        prevalence_pct = its.prevalence_pct,
        dp_count = its.dp_count,
        total_category_dp_count = its.total_dps_in_category,
        updated_at = now()
    FROM vw_implied_technology_standards its
    WHERE ts.namespace_id = p_namespace_id
        AND its.namespace_id = ts.namespace_id
        AND its.category_id = ts.category_id
        AND its.product_family = ts.product_family;
END;
$$;
```

---

## 5. UI Design

### 5.1 Location

New sub-tab or section within the **Tech Health** tab. Recommended: **Option C** — dedicated page accessible from Tech Health tab's KPI bar via a "Standards Intelligence" card. The card shows the count of implied standards pending review as a call-to-action.

### 5.2 Standards Intelligence Page

**Layout:** Two zones — Category Summary (left/top) and Family Detail (right/bottom).

**Category Summary Table:**

| Category | Dominant Family | Prevalence | Versions | Lifecycle | Standard Status | Action |
|----------|----------------|------------|----------|-----------|-----------------|--------|
| Operating System | Windows Server | 87% | 3 | Mainstream | ✅ Standard | Review |
| Database | SQL Server | 74% | 4 | Extended ⚠️ | — Implied | Assert |
| Web Server | IIS | 52% | 2 | Mainstream | 🔍 Under Review | Review |
| Application Server | Apache Tomcat | 38% | 2 | Mainstream | — Below threshold | — |

**Clicking a category row** expands to show all families in that category, ranked by prevalence:

| Family | DPs | Apps | Prevalence | Preferred Version | Status | |
|--------|-----|------|------------|-------------------|--------|-|
| SQL Server | 42 | 38 | 74% | SQL Server 2022 | Standard | ✏️ |
| Oracle Database | 8 | 7 | 14% | — | Non-standard | ✏️ |
| PostgreSQL | 5 | 5 | 9% | — | Under review | ✏️ |
| MariaDB | 2 | 2 | 4% | — | — | Assert |

**Assert/Review Modal:**

Fields:
- **Status** (required): Standard / Non-Standard / Under Review / Retiring
- **Preferred Version** (optional): Dropdown of technology_products in this family
- **Sunset Date** (conditional): Required if status = Retiring
- **Notes** (optional): Free text rationale

### 5.3 "Generate Reference Architecture" Button

Positioned in the page toolbar, alongside any CSV export or filter controls. Enabled only when at least one standard has been asserted (disabled with tooltip: "Assert at least one standard to generate a reference architecture").

**Button behavior:**
1. Runs the Standards Readiness Check (§8) and displays results in a brief modal.
2. If readiness score is acceptable (≥ 3 categories with asserted standards), the modal shows a "Generate" button.
3. "Generate" opens the AI Chat panel with pre-loaded context (§7).
4. Agent response renders in chat. After generation, the chat offers "Download as .docx" and "Copy as Markdown" actions.

### 5.4 Compliance Badges (Phase 2 UI)

Once standards are asserted, non-conforming technology tags surface as badges:

- **Tech Health table:** Yellow "Non-Standard" badge next to non-conforming tags.
- **Edit App → Deployments tab:** Warning icon on DP technology tags that deviate from standards.
- **Overview KPI bar:** "X non-conforming technology tags" metric.

---

## 6. T-Score Integration (Phase 2 — Designed, Not Shipped)

### 6.1 Current State

The assessment framework uses 14 technical factors (T01–T14) in the weighted `calculate_tech_health` function. A T15 column exists on `deployment_profiles` with sparse data — 11 of 204 DPs have values (scores ranging 2–5), with 193 NULL. It appears to have been used experimentally and is not included in the `calculate_tech_health` or `calculate_tech_risk` functions. **T15 is not part of the active scoring model.**

The derived modifier approach (§6.2) is preferred regardless of T15's status — standards conformance is computed from data, not assessed by a human. Repurposing T15 for a different meaning would create confusion in any namespace that has historical T15 values from the experimental period.

### 6.2 Design Decision: Derived Modifier, Not New Question

Standards conformance is fundamentally different from T01–T14. Those factors are **subjective assessments** — a human answers a question about the deployment. Standards conformance is **computed from the data** — the system already knows whether a DP's technology tags match the asserted standards.

Adding a T15 question that asks "how well does this deployment conform to standards?" would be asking the user something the system can answer. That violates the "derived over static" principle.

**Recommended approach:** A **standards conformance modifier** that adjusts the composite `tech_health` score post-calculation, separate from the T01–T14 weighted average. This keeps the 14-question survey clean and adds a data-derived adjustment layer.

```
adjusted_tech_health = tech_health + standards_modifier
```

Where `standards_modifier` is:
- **+0** if all tags conform to asserted standards (or no standards asserted).
- **-2 to -5** if non-conforming tags exist, scaled by severity (number of deviations, criticality of categories).
- **+2** bonus if all tags match preferred versions (not just standard families).

Alternatively, the modifier could be a multiplier (0.9× to 1.05×) rather than additive. Implementation details deferred to Phase 2 build.

### 6.3 Why Not T15?

| Approach | Pros | Cons |
|----------|------|------|
| New factor T15 | Fits existing framework, familiar UI | Asks user a computable question; T15 code may have legacy history in customer data |
| T02 modifier | No new factor | Couples two distinct concepts (vendor support ≠ organizational choice) |
| **Derived modifier** | Computed from data; principle-aligned; no new question | Requires new adjustment mechanism outside the 14-factor weighted average |

**Decision: Derived modifier.** Avoids reclaiming T15 (which may have legacy history), avoids coupling with T02, and respects the "derived over static" principle. The T01–T14 factor numbering remains frozen.

---

## 7. AI Agent: Reference Architecture Generation

### 7.1 Architecture

The generation flow uses the existing AI Chat infrastructure (Edge Function E1/E2, Anthropic API via `GetInSync-NextGen-Production` key). The Standards Intelligence page provides a dedicated entry point that pre-loads context into the chat.

```
[Standards Intelligence Page]
    │
    ├── "Generate Reference Architecture" button
    │       │
    │       ├── Runs Standards Readiness Check (§8)
    │       │
    │       └── Opens AI Chat with pre-loaded payload
    │               │
    │               ├── Edge Function: ai-chat
    │               │       │
    │               │       ├── System prompt (§7.2)
    │               │       ├── Context payload (§7.3)
    │               │       └── Anthropic API call
    │               │
    │               └── Response renders in chat panel
    │                       │
    │                       ├── View in chat (immediate)
    │                       ├── "Copy as Markdown" button
    │                       └── "Download as .docx" button
    │
    └── Also accessible via Ctrl+K → "generate reference architecture"
```

### 7.2 System Prompt

```
You are a technology architecture advisor embedded in GetInSync, an
Application Portfolio Management platform. You generate Reference
Architecture Summaries from real organizational data — not from
general knowledge or assumptions.

Your output is suitable for inclusion in RFP responses, technology
governance documents, and architecture review boards. Use professional
language appropriate for enterprise and government procurement audiences.

Rules:
- State only what the data shows. Never invent standards that aren't
  in the provided data.
- For each technology category, state: the organizational standard,
  preferred version (if asserted), current lifecycle status, adoption
  rate across deployments, and any active migrations (inferred from
  the presence of both a standard and a retiring/non-standard family
  in the same category).
- Flag categories where no standard has been asserted as "Pending
  governance review" — do not guess.
- Include lifecycle context: if a standard's preferred version is
  approaching end of mainstream support, note the date.
- Organize by technology category in order: Operating System,
  Database, Web Server, Application Server, then remaining categories
  alphabetically.
- Use specific numbers (e.g., "deployed across 42 of 57 deployment
  profiles (74%)") — never vague language like "most" or "many."
```

### 7.3 Context Payload

The frontend assembles the payload from two queries before opening the chat:

**Query 1:** `vw_implied_technology_standards` filtered to current namespace (all rows, not just above threshold).

**Query 2:** `technology_standards` filtered to current namespace (all asserted standards with notes).

**Payload structure sent to Edge Function:**

```typescript
interface ReferenceArchitectureContext {
  namespace_name: string;
  generation_date: string;
  total_applications: number;       // from vw_dashboard_summary
  total_deployment_profiles: number; // from vw_dashboard_summary

  categories: Array<{
    category_name: string;
    total_dps_in_category: number;
    families: Array<{
      product_family: string;
      dp_count: number;
      app_count: number;
      prevalence_pct: number;
      most_common_product: string;
      version_count: number;
      best_lifecycle_status: string;
      asserted_status: string | null;    // 'standard' | 'non_standard' | 'retiring' | etc.
      preferred_product_name: string | null;
      sunset_date: string | null;
      notes: string | null;
    }>;
  }>;

  readiness: StandardsReadinessResult;  // from §8
}
```

**Token budget:** This payload will typically be 1,000–3,000 tokens depending on the number of categories and families. Well within the context window. The response (reference architecture narrative) will be 500–2,000 tokens.

### 7.4 Output Formats

The chat response is the primary output. Two secondary formats are offered after generation:

**Markdown (copy-paste):**
A "Copy as Markdown" button extracts the chat response as clean markdown, suitable for pasting into an RFP document, wiki, or Confluence page. No additional API call — the chat response is already markdown-formatted.

**Word Document (.docx):**
A "Download as .docx" button triggers a client-side document generation (using the same `docx-js` library used elsewhere in the app). The .docx includes:

- Title: "Technology Reference Architecture — {Namespace Name}"
- Subtitle: "Generated {date} from GetInSync Standards Intelligence"
- Body: The chat response, formatted with proper headings per technology category
- Footer: "Generated by GetInSync NextGen. Data current as of {date}."

This is a frontend-only operation — no additional Edge Function call. The chat response text is the source; the .docx wraps it in professional formatting.

### 7.5 Ctrl+K Access

The Global Search overlay (Ctrl+K) should recognize natural language queries like:
- "generate reference architecture"
- "what are our technology standards"
- "reference architecture for RFP"

These route to the AI Chat with the same pre-loaded context payload. The Global Search → AI Chat handoff pattern is already designed in the Global Search architecture (cascading to AI chat for queries that don't match entity search).

---

## 8. Standards Readiness Check

### 8.1 Purpose

A pre-generation diagnostic that evaluates whether the namespace's standards data is complete enough to produce a useful reference architecture. Displayed as a modal when the user clicks "Generate Reference Architecture" — the user sees the gaps before the agent runs.

**This is not a blocking gate.** The user can generate even with gaps. The readiness check is advisory — it flags what's missing so the user can decide whether to fix the data first or generate with known gaps.

### 8.2 Readiness Criteria

| Check | Pass Condition | Severity |
|-------|----------------|----------|
| **Technology tags exist** | At least 1 DP has technology product tags | Blocker (cannot generate without data) |
| **Categories covered** | ≥ 3 technology categories have tagged DPs | Warning |
| **Standards asserted** | ≥ 1 standard has been asserted (status = 'standard' or 'retiring') | Warning |
| **Core categories asserted** | OS + Database categories each have an asserted standard | Warning |
| **Preferred versions set** | ≥ 50% of asserted standards have a preferred_product_id | Info |
| **Lifecycle data linked** | ≥ 70% of technology products in standard families have lifecycle_reference_id | Info |
| **product_family populated** | ≥ 80% of technology products have a non-null product_family | Info |
| **Low sample categories** | Flag categories where total_category_dp_count < 5 | Info |

### 8.3 Readiness Score

Simple traffic light derived from the checks above:

- **Green (Ready):** No blockers, no warnings. "Your standards data is comprehensive."
- **Yellow (Gaps exist):** No blockers, 1+ warnings. "Reference architecture will have gaps. Review warnings below."
- **Red (Not ready):** 1+ blockers. "Not enough data to generate. Tag deployment profiles with technology products first."

### 8.4 Readiness Modal UI

```
┌─────────────────────────────────────────────┐
│  Standards Readiness Check          🟡       │
│                                              │
│  ✅ Technology tags exist (52 tags across    │
│     20 DPs)                                  │
│  ✅ 5 categories covered                     │
│  ⚠️ Only 2 of 5 categories have asserted    │
│     standards. Consider reviewing:           │
│     • Web Server (implied: IIS at 52%)       │
│     • Application Server (no dominant family)│
│  ✅ OS + Database both have asserted         │
│     standards                                │
│  ℹ️ 3 of 4 standards have preferred versions │
│  ℹ️ 2 products missing product_family value  │
│                                              │
│  [ Cancel ]              [ Generate Anyway ] │
└─────────────────────────────────────────────┘
```

### 8.5 Implementation

The readiness check is a frontend function that queries `vw_implied_technology_standards` and `vw_technology_standards_summary`, then evaluates the criteria in §8.2. No additional database view or RPC needed — the data is already available from the two existing views.

```typescript
interface StandardsReadinessResult {
  score: 'green' | 'yellow' | 'red';
  checks: Array<{
    name: string;
    passed: boolean;
    severity: 'blocker' | 'warning' | 'info';
    message: string;
    detail?: string;  // e.g., list of categories missing standards
  }>;
}
```

The readiness result is included in the AI agent's context payload (§7.3) so the agent can acknowledge gaps in its output (e.g., "Note: No standard has been asserted for the Application Server category. This should be reviewed by the architecture governance team.").

---

## 9. Roadmap Findings Integration (Phase 2)

Non-conforming technology tags can auto-generate Findings in the Roadmap module:

```
Finding Type: Technology Standards Deviation
Source: Auto-detected
Description: "{App Name} uses {Product Name} ({Category}) which deviates
             from the asserted standard of {Standard Family}."
Severity: Medium (configurable)
Linked DP: {deployment_profile_id}
```

This creates the bridge from intelligence (Tech Health) to action (Roadmap) without crossing the APM/GRC boundary. The Finding records the observation. The Initiative (if created) captures the response. GetInSync detects; it doesn't prescribe.

---

## 10. ServiceNow Alignment

Technology standards map naturally to ServiceNow's **Technology Portfolio** and **Lifecycle Management** modules:

| GetInSync Concept | ServiceNow Equivalent |
|-------------------|-----------------------|
| technology_standards (status = standard) | Standard Technology Portfolio entry |
| preferred_product_id | Preferred/Strategic version |
| status = retiring | Retiring lifecycle stage |
| status = non_standard | Containment / Not Permitted |
| conformance_status | Compliance indicator on Application Service |

The ServiceNow publish flow (Phase 37+) would push asserted standards to `cmdb_ci_tech_portfolio` or equivalent.

---

## 11. Phasing

### Phase 1: Read-Only Intelligence (~8-10 hours)

| Step | Work | Estimate |
|------|------|----------|
| S.1 | Create `technology_standards` table + RLS + audit + GRANTs | 30 min |
| S.2 | Create `vw_implied_technology_standards` view + GRANT | 30 min |
| S.3 | Create `vw_technology_standards_summary` view + GRANT | 15 min |
| S.4 | Create `assert_technology_standard()` RPC | 30 min |
| S.5 | Create `refresh_technology_standard_prevalence()` RPC | 15 min |
| S.6 | Frontend: Standards Intelligence page (category table, family detail, assert modal) | 4-6 hrs |
| S.7 | Seed: Run detection against existing Riverside + Garland data to validate | 30 min |
| S.8 | pgTAP: RLS assertions for technology_standards (4 policies × 5 roles = 20 assertions) | 30 min |

### Phase 2: Scoring + Findings Integration (~8-10 hours)

| Step | Work | Estimate |
|------|------|----------|
| S.9 | Design and implement standards conformance derived modifier | 2-3 hrs |
| S.10 | Auto-generate Findings for non-conforming tags | 2 hrs |
| S.11 | Compliance badges on Tech Health table + Edit App | 2-3 hrs |
| S.12 | Overview KPI: non-conforming tag count | 1 hr |

### Phase 3: AI Agent Reference Architecture (~4-6 hours)

| Step | Work | Estimate |
|------|------|----------|
| S.13 | Standards Readiness Check (frontend function + modal) | 1-2 hrs |
| S.14 | Context payload assembly (TypeScript, queries → structured payload) | 1 hr |
| S.15 | System prompt + Edge Function integration (extends ai-chat) | 1 hr |
| S.16 | "Generate Reference Architecture" button + chat handoff | 30 min |
| S.17 | "Copy as Markdown" action on chat response | 30 min |
| S.18 | "Download as .docx" action (docx-js client-side generation) | 1-2 hrs |
| S.19 | Ctrl+K → reference architecture intent recognition | 30 min |

### Phase 4: Governance Workflow (Future)

- Standards review workflow (propose → review → approve).
- Exception requests: "I need MariaDB for this DP because..."
- Periodic re-detection: flag new implied standards as they emerge.
- Email digest: "3 new deployment profiles are using non-standard technology."

---

## 12. Edge Cases

| Scenario | Behavior |
|----------|----------|
| `product_family` is NULL on technology_products | Falls back to `tp.name` via COALESCE. Each product is its own "family." |
| No technology tags in a category | Category does not appear in the view. No implied standards detected. |
| Two families have equal prevalence (e.g., 50%/50%) | Both appear as implied. Both can be asserted as standard (multi-standard category). |
| Standard asserted but preferred product is deleted | `preferred_product_id` goes NULL (ON DELETE SET NULL). Family-level standard persists. |
| Application is retired | Excluded from prevalence calculation (WHERE operational_status = 'operational'). |
| Category has only 1 DP tagged | Prevalence is 100% but dp_count = 1. Low confidence. UI shows "low sample" indicator when total_category_dp_count < 5. |
| Namespace has no technology tags at all | Summary view returns no rows. UI shows empty state: "Tag deployment profiles with technology products to enable standards detection." Readiness check returns Red. |
| AI agent called with no asserted standards | Readiness check shows Yellow. Agent output describes implied patterns but marks everything as "pending governance review." |
| Agent generates while standards are being updated | No lock needed. The context payload is a snapshot at generation time. Subsequent generations will reflect updated assertions. |

---

## 13. Relationship to Existing Features

| Feature | Relationship |
|---------|-------------|
| **Tech Health Dashboard** | Standards Intelligence adds a governance layer on top of Tech Health's lifecycle data. Tech Health says "your SQL Server 2014 is end-of-support." Standards Intelligence says "and it's also not your standard — you should be on SQL Server 2022." |
| **Tech Scoring Patterns** | Scoring Patterns set default T-scores by hosting type. Standards Intelligence sets organizational expectations by technology category. Complementary, not overlapping. |
| **Lifecycle Intelligence** | Lifecycle answers "is the vendor still supporting this?" Standards answers "did the organization choose this?" Different questions, same tech tags. |
| **Risk Boundary** | Standards deviation is a risk indicator (APM territory). Risk acceptance workflow is GRC territory. Consistent with ADR. |
| **Roadmap / IT Value Creation** | Non-conformance generates Findings. Remediation creates Initiatives. The library detects; the roadmap acts. |
| **AI Chat** | Reference Architecture generation is a specialized use case of the AI Chat infrastructure. Same Edge Function, same Anthropic API key, specialized system prompt + structured context. |
| **Global Search** | Ctrl+K → "reference architecture" routes to AI Chat with pre-loaded standards context. Extends the Global Search → AI Chat handoff pattern. |

---

## 14. Architecture Principles Applied

| # | Principle | How Applied |
|---|-----------|-------------|
| 1 | Namespace = Hard Boundary | Standards are namespace-scoped. No cross-namespace leakage. |
| 3 | DP-Centric Assessment | Prevalence computed from DP-level technology tags, not application-level. |
| 7 | Granular Security | 4-policy RLS pattern. Admin-only assertion. Read access for all roles. |
| 9 | Two-Path Technology Model | Standards detection works on Path 1 data (direct inventory tags). IT Service path not needed. |
| 10 | Risk Boundary | Detects non-conformance as an indicator. Does not manage the response. |
| 14 | Derived over Static | Implied standards are derived from data, not configured from scratch. T-score impact is a derived modifier, not a human-answered question. |
| 15 | Edge Functions as Shared Infrastructure | Reference Architecture generation reuses the AI Chat Edge Function — new system prompt, same plumbing. |

---

## 15. Demo Script: Knowledge Conference

**Setup:** Riverside demo namespace with 12 technology products, 52 deployment tags across 20 DPs. Pre-assert 3 standards (Windows Server, SQL Server, IIS) with preferred versions. Leave one category (Application Server) un-asserted.

**Script (3 minutes):**

1. Open Tech Health tab. "Here's our technology landscape — lifecycle status across all deployments."
2. Click "Standards Intelligence" card. "GetInSync has analyzed your deployment data and detected your implied standards. Windows Server appears on 87% of deployments. SQL Server on 74%. The system found these patterns — we didn't configure them."
3. Show one un-asserted row. Click "Assert." Set to Standard, pick preferred version. "Your architecture team reviews and confirms. One click — that's now your asserted standard."
4. Click "Generate Reference Architecture." Show readiness check modal. "Before we generate, the system checks: do you have enough data? Are there gaps? Here we're missing an Application Server standard — noted."
5. Click "Generate Anyway." AI Chat opens, agent generates the reference architecture with real numbers. "This is written from your data. 42 of 57 deployments run Windows Server 2022. Not a guess — a fact."
6. Click "Download as .docx." "Drop this into your next RFP. Your reference architecture, current as of today, generated in 30 seconds."

**Closing line:** "Your ServiceNow partner needs business application data on day one. GetInSync is how it gets there — and now it writes your reference architecture too."

---

## 16. Open Questions

1. **Multi-standard categories:** Should a category support more than one asserted standard? (e.g., "Both SQL Server and PostgreSQL are approved for our org.") Current design allows it. Is this the right default?

2. **Workspace-level exceptions:** Namespace-wide standards with per-workspace exceptions — defer to Phase 4?

3. **product_family data quality:** Should the readiness check flag products without `product_family` values, and should the Standards Intelligence page offer a "Fix data" action that lets admins set product_family in bulk?

4. **Threshold configuration UI:** Should the 40% default threshold be configurable per namespace via a settings page, or admin-only via direct update?

5. **T-factor numbering history:** What was the original T15 before it was eliminated? Confirming this helps determine whether the code is safe to reclaim in future if the derived modifier approach proves insufficient.

---

## Cross-References

| Document | Relevance |
|----------|-----------|
| `features/technology-health/dashboard.md` | Existing Tech Health — standards badges extend this UI |
| `features/technology-health/lifecycle-intelligence.md` | Lifecycle data enriches standards compliance context |
| `features/technology-health/risk-boundary.md` | ADR: detection vs. management boundary |
| `features/technology-health/infrastructure-boundary-rubric.md` | What enters APM — standards evaluate what's already in |
| `features/roadmap/architecture.md` | Findings integration for non-conformance |
| `features/ai-chat/mvp.md` | AI Chat infrastructure reused for reference architecture generation |
| `features/global-search/architecture.md` | Ctrl+K → AI Chat handoff for natural language queries |
| `infrastructure/edge-functions-layer-architecture.md` | Edge Function E1/E2 — shared plumbing for AI calls |
| `catalogs/technology-catalog.md` | Technology product catalog structure |
| `core/time-paid-methodology.md` | T-score integration (Phase 2, derived modifier) |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-11 | Initial architecture: detection algorithm, assertion flow, data model, UI design, Phase 1-3 phasing. |
| v1.1 | 2026-03-11 | AI agent integration (§7): button triggers chat with pre-loaded context, three output formats (chat/markdown/docx). Standards Readiness Check (§8): separate pre-generation diagnostic. T-score reframe (§6): derived modifier instead of reclaiming T15 — standards conformance is computed from data, not a human-answered question. Knowledge conference demo script (§15). |
| v1.2 | 2026-03-11 | Post-review corrections from Claude Code schema validation. §6.1: T15 column exists with sparse data (11/204 DPs) — corrected from "does not exist." §3.3: COALESCE → COALESCE(NULLIF(..., '')) to handle empty string product_family values. §3.4: noted hardcoded 40% threshold for Phase 2 parameterization. |

---

*Document: features/technology-health/standards-intelligence.md*
*Architecture repo: getinsync-architecture*
