-- ============================================================================
-- Phase 27 — Technology Lifecycle Intelligence: Schema Gap Scripts
-- Run in Supabase SQL Editor (Stuart only)
-- ============================================================================
-- These scripts add the missing columns and tables required for Phase 27b.4,
-- 27b.5, and the Path 2 lifecycle chain.
-- ============================================================================

-- ============================================================================
-- SCRIPT 1: Add lifecycle_reference_id FK to it_services
-- Spec reference: lifecycle-intelligence.md S4.4
-- ============================================================================

ALTER TABLE it_services
ADD COLUMN lifecycle_reference_id UUID REFERENCES technology_lifecycle_reference(id) ON DELETE SET NULL;

CREATE INDEX idx_it_services_lifecycle_ref ON it_services(lifecycle_reference_id)
WHERE lifecycle_reference_id IS NOT NULL;

-- ============================================================================
-- SCRIPT 2: Add lifecycle_reference_id FK to software_products
-- Spec reference: lifecycle-intelligence.md S4.5
-- ============================================================================

ALTER TABLE software_products
ADD COLUMN lifecycle_reference_id UUID REFERENCES technology_lifecycle_reference(id) ON DELETE SET NULL;

CREATE INDEX idx_software_products_lifecycle_ref ON software_products(lifecycle_reference_id)
WHERE lifecycle_reference_id IS NOT NULL;

-- ============================================================================
-- SCRIPT 3: Create it_service_technology_products junction table
-- Spec reference: lifecycle-intelligence.md S3.2 (Path 2 chain)
-- Pattern: mirrors it_service_software_products
-- ============================================================================

CREATE TABLE it_service_technology_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    it_service_id UUID NOT NULL REFERENCES it_services(id) ON DELETE CASCADE,
    technology_product_id UUID NOT NULL REFERENCES technology_products(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT istp_unique_link UNIQUE (it_service_id, technology_product_id)
);

CREATE INDEX idx_istp_it_service ON it_service_technology_products(it_service_id);
CREATE INDEX idx_istp_technology_product ON it_service_technology_products(technology_product_id);

-- GRANTs
GRANT SELECT, INSERT, UPDATE, DELETE ON it_service_technology_products TO authenticated;

-- RLS (scoped through parent it_services.namespace_id)
ALTER TABLE it_service_technology_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "it_service_technology_products_select"
    ON it_service_technology_products FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM it_services its
            WHERE its.id = it_service_technology_products.it_service_id
            AND its.namespace_id = (current_setting('app.current_namespace_id', true))::uuid
        )
    );

CREATE POLICY "it_service_technology_products_insert"
    ON it_service_technology_products FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM it_services its
            WHERE its.id = it_service_technology_products.it_service_id
            AND its.namespace_id = (current_setting('app.current_namespace_id', true))::uuid
        )
    );

CREATE POLICY "it_service_technology_products_update"
    ON it_service_technology_products FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM it_services its
            WHERE its.id = it_service_technology_products.it_service_id
            AND its.namespace_id = (current_setting('app.current_namespace_id', true))::uuid
        )
    );

CREATE POLICY "it_service_technology_products_delete"
    ON it_service_technology_products FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM it_services its
            WHERE its.id = it_service_technology_products.it_service_id
            AND its.namespace_id = (current_setting('app.current_namespace_id', true))::uuid
        )
    );

-- Audit trigger
CREATE TRIGGER audit_it_service_technology_products
    AFTER INSERT OR UPDATE OR DELETE ON it_service_technology_products
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- ============================================================================
-- SCRIPT 4: Create vw_it_service_lifecycle_risk view
-- Spec reference: lifecycle-intelligence.md S7.4 (Path 2)
-- Depends on: Script 1 (lifecycle_reference_id on it_services)
-- ============================================================================

CREATE OR REPLACE VIEW vw_it_service_lifecycle_risk
WITH (security_invoker = true) AS
SELECT
    its.id,
    its.name AS service_name,
    its.owner_workspace_id,
    w.name AS workspace_name,
    its.namespace_id,
    tlr.vendor_name,
    tlr.product_name,
    tlr.version,
    tlr.current_status,
    tlr.mainstream_support_end,
    tlr.extended_support_end,
    tlr.end_of_life_date,

    CASE
        WHEN tlr.extended_support_end IS NOT NULL
        THEN tlr.extended_support_end - CURRENT_DATE
        ELSE NULL
    END AS days_until_eol,

    CASE
        WHEN tlr.current_status IN ('end_of_support', 'end_of_life') THEN 'critical'
        WHEN tlr.extended_support_end IS NOT NULL
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '6 months' THEN 'high'
        WHEN tlr.extended_support_end IS NOT NULL
             AND tlr.extended_support_end < CURRENT_DATE + INTERVAL '12 months' THEN 'medium'
        ELSE 'low'
    END AS lifecycle_risk,

    (SELECT COUNT(*) FROM deployment_profile_it_services dpis
     WHERE dpis.it_service_id = its.id) AS dependent_dp_count

FROM it_services its
LEFT JOIN technology_lifecycle_reference tlr ON its.lifecycle_reference_id = tlr.id
LEFT JOIN workspaces w ON its.owner_workspace_id = w.id
WHERE its.lifecycle_reference_id IS NOT NULL;

-- ============================================================================
-- SCRIPT 5: Create vw_dp_lifecycle_risk_combined view (unified)
-- Spec reference: lifecycle-intelligence.md S7.4
-- Depends on: Script 3 (it_service_technology_products junction)
-- ============================================================================

CREATE OR REPLACE VIEW vw_dp_lifecycle_risk_combined
WITH (security_invoker = true) AS
WITH path1_risk AS (
    -- Direct technology tags on DPs
    SELECT
        dptp.deployment_profile_id,
        'direct_tag' AS source_type,
        tp.name AS technology_name,
        tlr.current_status,
        tlr.extended_support_end,
        tlr.end_of_life_date
    FROM deployment_profile_technology_products dptp
    JOIN technology_products tp ON tp.id = dptp.technology_product_id
    LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
    WHERE tp.lifecycle_reference_id IS NOT NULL
),
path2_risk AS (
    -- Technology via IT Services
    SELECT
        dpis.deployment_profile_id,
        'it_service' AS source_type,
        tp.name AS technology_name,
        tlr.current_status,
        tlr.extended_support_end,
        tlr.end_of_life_date
    FROM deployment_profile_it_services dpis
    JOIN it_service_technology_products istp ON istp.it_service_id = dpis.it_service_id
    JOIN technology_products tp ON tp.id = istp.technology_product_id
    LEFT JOIN technology_lifecycle_reference tlr ON tlr.id = tp.lifecycle_reference_id
    WHERE tp.lifecycle_reference_id IS NOT NULL
),
all_risk AS (
    SELECT * FROM path1_risk
    UNION ALL
    SELECT * FROM path2_risk
)
SELECT
    dp.id AS deployment_profile_id,
    dp.name AS deployment_name,
    a.name AS application_name,
    dp.workspace_id,
    w.namespace_id,
    -- Worst status across all linked technology
    MIN(CASE ar.current_status
        WHEN 'end_of_life' THEN 1
        WHEN 'end_of_support' THEN 2
        WHEN 'extended' THEN 3
        WHEN 'mainstream' THEN 4
        WHEN 'preview' THEN 5
        ELSE 6
    END) AS worst_status_rank,
    -- Count by source
    COUNT(DISTINCT CASE WHEN ar.source_type = 'direct_tag' THEN ar.technology_name END) AS direct_tag_count,
    COUNT(DISTINCT CASE WHEN ar.source_type = 'it_service' THEN ar.technology_name END) AS it_service_count,
    -- Earliest EOL date
    MIN(ar.extended_support_end) AS earliest_eol
FROM deployment_profiles dp
JOIN applications a ON a.id = dp.application_id
JOIN workspaces w ON w.id = a.workspace_id
LEFT JOIN all_risk ar ON ar.deployment_profile_id = dp.id
GROUP BY dp.id, dp.name, a.name, dp.workspace_id, w.namespace_id;

-- ============================================================================
-- VALIDATION QUERIES — run after all scripts
-- ============================================================================

-- Check new columns exist
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('it_services', 'software_products')
AND column_name = 'lifecycle_reference_id';

-- Check new junction table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'it_service_technology_products'
ORDER BY ordinal_position;

-- Check RLS on new junction
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'it_service_technology_products';

-- Check views created
SELECT viewname FROM pg_views
WHERE schemaname = 'public'
AND viewname IN ('vw_it_service_lifecycle_risk', 'vw_dp_lifecycle_risk_combined');

-- Check audit trigger
SELECT tgname FROM pg_trigger
WHERE tgrelid = 'public.it_service_technology_products'::regclass
AND NOT tgisinternal;
