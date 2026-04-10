-- Chunk: 01-app-contacts-showcase.sql
-- Purpose: Article 2.1 (Managing Applications) — populate the showcase app
--          "Computer-Aided Dispatch" with realistic contacts so the Contacts
--          section renders meaningfully in screenshots.
-- Preconditions:
--   - Tables touched: contacts, application_contacts, applications
--   - Reference tables read: contacts.contact_category check constraint
--     (internal / external / vendor_rep) — no lookup table, use check values.
--   - Unique constraint: application_contacts (application_id, contact_id, role_type)
--   - Idempotent via WHERE NOT EXISTS guards. Safe to re-run.
-- Namespace scope: a1b2c3d4-e5f6-7890-abcd-ef1234567890 (City of Riverside)
-- Showcase app: Computer-Aided Dispatch (id b1000006-0000-0000-0000-000000000006, Police Department)

BEGIN;

-- Step 1: Seed 2 new fictional Police Department contacts (idempotent by email).
-- These will own the business and SME roles on the CAD showcase app.
INSERT INTO contacts (
  id, namespace_id, primary_workspace_id, display_name, job_title, department,
  email, phone, workspace_role, contact_category, is_active
)
SELECT
  gen_random_uuid(),
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',              -- Riverside namespace
  'a1b2c3d4-0006-0000-0000-000000000006',              -- Police Department workspace
  'Pat Alvarez',
  'Police Communications Manager',
  'Police Communications',
  'pat.alvarez@riverside-demo.example',
  '555-0101',
  'editor',
  'internal',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND email        = 'pat.alvarez@riverside-demo.example'
);

INSERT INTO contacts (
  id, namespace_id, primary_workspace_id, display_name, job_title, department,
  email, phone, workspace_role, contact_category, is_active
)
SELECT
  gen_random_uuid(),
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'a1b2c3d4-0006-0000-0000-000000000006',
  'Jordan Chen',
  'CAD Dispatch Supervisor',
  'Police Communications',
  'jordan.chen@riverside-demo.example',
  '555-0102',
  'editor',
  'internal',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM contacts
  WHERE namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    AND email        = 'jordan.chen@riverside-demo.example'
);

-- Step 2: Link contacts to the Computer-Aided Dispatch application.
-- role_type values come from application_contacts_role_check:
-- 'business_owner','technical_owner','steward','sponsor','sme','support','vendor_rep','other'

-- 2a: Pat Alvarez as business_owner (primary)
INSERT INTO application_contacts (application_id, contact_id, role_type, is_primary, notes)
SELECT
  'b1000006-0000-0000-0000-000000000006',
  c.id,
  'business_owner',
  true,
  'Accountable owner for CAD dispatch operations'
FROM contacts c
WHERE c.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND c.email        = 'pat.alvarez@riverside-demo.example'
  AND NOT EXISTS (
    SELECT 1 FROM application_contacts
    WHERE application_id = 'b1000006-0000-0000-0000-000000000006'
      AND contact_id     = c.id
      AND role_type      = 'business_owner'
  );

-- 2b: K. Patel (existing IT contact, id b8000006) as technical_owner
INSERT INTO application_contacts (application_id, contact_id, role_type, is_primary, notes)
SELECT
  'b1000006-0000-0000-0000-000000000006',
  'b8000006-0000-0000-0000-000000000006',
  'technical_owner',
  true,
  'IT technical owner for CAD integration and uptime'
WHERE NOT EXISTS (
  SELECT 1 FROM application_contacts
  WHERE application_id = 'b1000006-0000-0000-0000-000000000006'
    AND contact_id     = 'b8000006-0000-0000-0000-000000000006'
    AND role_type      = 'technical_owner'
);

-- 2c: Jordan Chen as SME
INSERT INTO application_contacts (application_id, contact_id, role_type, is_primary, notes)
SELECT
  'b1000006-0000-0000-0000-000000000006',
  c.id,
  'sme',
  false,
  'Day-to-day subject matter expert for dispatch workflows'
FROM contacts c
WHERE c.namespace_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND c.email        = 'jordan.chen@riverside-demo.example'
  AND NOT EXISTS (
    SELECT 1 FROM application_contacts
    WHERE application_id = 'b1000006-0000-0000-0000-000000000006'
      AND contact_id     = c.id
      AND role_type      = 'sme'
  );

-- Step 3: Backfill the legacy text fields on the applications row so the
-- Owner / Support / Expert badges render on the app detail page.
-- Only overwrite if currently empty (idempotent on re-run).
UPDATE applications
SET
  owner            = CASE WHEN COALESCE(owner,'')            = '' THEN 'Pat Alvarez'            ELSE owner            END,
  primary_support  = CASE WHEN COALESCE(primary_support,'')  = '' THEN 'K. Patel'               ELSE primary_support  END,
  expert_contacts  = CASE WHEN COALESCE(expert_contacts,'')  = '' THEN 'Jordan Chen'            ELSE expert_contacts  END,
  primary_use_case = CASE WHEN COALESCE(primary_use_case,'') = ''
                          THEN 'Dispatch 911 calls to police, fire, and EMS units; track unit status and incident response across Riverside public safety operations.'
                          ELSE primary_use_case END,
  updated_at = now()
WHERE id = 'b1000006-0000-0000-0000-000000000006';

-- Verification: show the 3 linked contacts and the updated legacy fields.
SELECT
  ac.role_type,
  c.display_name,
  c.job_title,
  c.email,
  ac.is_primary
FROM application_contacts ac
JOIN contacts c ON c.id = ac.contact_id
WHERE ac.application_id = 'b1000006-0000-0000-0000-000000000006'
ORDER BY ac.role_type;

SELECT id, name, owner, primary_support, expert_contacts, left(primary_use_case, 80) AS primary_use_case_preview
FROM applications
WHERE id = 'b1000006-0000-0000-0000-000000000006';

COMMIT;

-- Rollback: DELETE FROM application_contacts WHERE application_id = 'b1000006-0000-0000-0000-000000000006' AND contact_id IN (SELECT id FROM contacts WHERE email IN ('pat.alvarez@riverside-demo.example','jordan.chen@riverside-demo.example') OR id = 'b8000006-0000-0000-0000-000000000006'); DELETE FROM contacts WHERE email IN ('pat.alvarez@riverside-demo.example','jordan.chen@riverside-demo.example'); UPDATE applications SET owner = '', primary_support = '', expert_contacts = NULL, primary_use_case = NULL WHERE id = 'b1000006-0000-0000-0000-000000000006';
