-- ============================================================================
-- Script 04: Technology Product Catalog
-- Records: 7
-- Source: garland-showcase-demo-plan.md Phase 4
-- Purpose: Create technology products for Tech Health dashboard and lifecycle intelligence
-- ============================================================================

BEGIN;

-- --------------------------------------------------------------------------
-- Technology Products (7 records)
-- --------------------------------------------------------------------------

INSERT INTO technology_products (id, namespace_id, name, version, category_id, description, is_internal_only, is_deprecated, license_type, product_family, eol_product_id)
VALUES
  ('187c9e0d-c907-4ebb-a069-830491ccc804', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Windows Server 2012 R2', '2012 R2', NULL, NULL, false, true, NULL, 'Windows Server', NULL),

  ('dea5a0ac-6cff-4733-9a4b-f9f77249dcac', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Windows Server 2012 Standard', '2012', NULL, NULL, false, true, NULL, 'Windows Server', NULL),

  ('7d8959fa-a9be-4bd6-bba6-53562f1ea91b', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Windows Server 2016 Standard', '2016', NULL, NULL, false, false, NULL, 'Windows Server', NULL),

  ('be95d3d5-3cdc-43fc-bc3a-908864fc910b', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Windows Server 2019 Standard', '2019', NULL, NULL, false, false, NULL, 'Windows Server', NULL),

  ('746faf67-14c6-43b3-81ea-24296a2679f9', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Windows Server 2022 Standard', '2022', NULL, NULL, false, false, NULL, 'Windows Server', NULL),

  ('e3f536e4-504f-42e2-a653-3d0af7b9ff76', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Linux Red Hat Enterprise 6.1', '6.1', NULL, NULL, false, true, NULL, 'Red Hat Enterprise Linux', NULL),

  ('50c9dfbb-4174-4f18-9993-428e56c2939f', 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523',
   'Linux Red Hat 6.5', '6.5', NULL, NULL, false, true, NULL, 'Red Hat Enterprise Linux', NULL);

COMMIT;

-- --------------------------------------------------------------------------
-- Validation
-- --------------------------------------------------------------------------
SELECT name, product_family, is_deprecated
FROM technology_products
WHERE namespace_id = 'b2b41bc0-e3c6-462f-b98c-6e9af9fbe523'
ORDER BY name;
