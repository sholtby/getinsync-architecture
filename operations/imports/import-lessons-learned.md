# Import Lessons Learned — Garland Showcase (2026-04-09)

**Version:** 1.0
**Context:** 21-app curated import into existing "City of Garland" namespace
**Purpose:** Capture every constraint, trigger, and schema gotcha encountered during import so the full 370-app bulk import doesn't hit the same issues.

---

## 1. Workspace Deletion — Audit Trigger Circular FK

**Problem:** Deleting workspaces cascades to child tables (applications, DPs, portfolios, etc.). Each child table has an audit trigger that INSERTs into `audit_logs` with `workspace_id`. But the workspace is being deleted, so the FK `audit_logs_workspace_id_fkey` fails — either because:
- The audit trigger fires on the workspace DELETE itself (trying to log the deletion with the workspace_id that no longer exists)
- Cascade deletes on child tables fire audit triggers that create new audit_log rows referencing the soon-to-be-deleted workspace

**Fix:** Disable all user triggers during cleanup:
```sql
SET session_replication_role = 'replica';  -- disables all user triggers
-- ... DELETE statements ...
SET session_replication_role = 'origin';   -- re-enables all triggers
```

**Why not `ALTER TABLE ... DISABLE TRIGGER`?** There are 60+ audit triggers across the schema. Disabling them individually is fragile and you'd miss cascade targets. `session_replication_role = 'replica'` is the nuclear option but it's clean for scoped data wipes.

**Future bulk import note:** Any operation that deletes workspaces or does cascading deletes across multiple tables needs this pattern.

---

## 2. Workspace Deletion — Non-Cascading Foreign Keys

**Problem:** Three tables reference `workspaces` without `ON DELETE CASCADE`:

| Table | FK Column | Delete Rule |
|-------|-----------|-------------|
| `audit_logs` | `workspace_id` | NO ACTION |
| `organizations` | `primary_workspace_id` | NO ACTION |
| `applications` | `owner_workspace_id` | SET NULL |

The `applications.owner_workspace_id` is fine (SET NULL), but `audit_logs` and `organizations` will block workspace deletion if not cleaned first.

**Fix:** Delete `audit_logs` and `organizations` before deleting workspaces. With `session_replication_role = 'replica'` active, the audit_logs issue is moot, but organizations still need explicit deletion.

---

## 3. Portfolio Deletion — Parent-Child Trigger

**Problem:** Trigger `prevent_parent_portfolio_deletion()` prevents deleting a portfolio that has children. During workspace cleanup, the cascade tries to delete parent portfolios before children.

**Fix:** With `session_replication_role = 'replica'`, all user triggers (including this one) are disabled, so cascade deletes work. If you ever need to delete portfolios with triggers active:
```sql
UPDATE portfolios SET parent_portfolio_id = NULL WHERE workspace_id IN (...);
DELETE FROM portfolios WHERE workspace_id IN (...);
```

---

## 4. Workspaces Require `slug` Column

**Problem:** `workspaces.slug` is NOT NULL with no default and no auto-generation trigger. INSERT without slug fails.

**Fix:** Always provide a kebab-case slug:
```sql
INSERT INTO workspaces (id, namespace_id, name, slug) VALUES
  ('...', '...', 'Customer Service & Utilities', 'customer-service-utilities');
```

**Pattern:** Lowercase, replace spaces/ampersands with hyphens, strip special chars.

---

## 5. Application Creation Auto-Generates Deployment Profiles

**Problem:** Trigger `create_deployment_profile_on_app_create` fires on every application INSERT and creates a default "Region-PROD" deployment profile. If you then INSERT your own curated DP, you end up with duplicates (42 DPs instead of 21).

**Fix:** After inserting curated DPs, delete the auto-generated ones:
```sql
DELETE FROM deployment_profiles
WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '...')
AND name LIKE '%Region-PROD%';
```

**Better fix for bulk import:** Disable the trigger before inserting applications:
```sql
ALTER TABLE applications DISABLE TRIGGER create_deployment_profile_on_app_create;
-- ... INSERT applications ...
-- ... INSERT deployment_profiles ...
ALTER TABLE applications ENABLE TRIGGER create_deployment_profile_on_app_create;
```

---

## 6. Contacts — `workspace_role` Check Constraint

**Problem:** `contacts_workspace_role_check` enforces valid values: `admin`, `editor`, `steward`, `read_only`, `restricted`. The CLAUDE.md documents namespace roles as `viewer` but the contacts table uses `read_only`.

**Fix:** Use `'read_only'` not `'viewer'` for contact records.

**Note:** This is a contacts-specific constraint. `namespace_users.role` and `workspace_users.role` may have different valid values — always check the check constraint before inserting.

---

## 7. Portfolio Assignments — `relationship_type` Check Constraint

**Problem:** `portfolio_assignments_relationship_type_check` enforces: `publisher`, `consumer`. Script used `'primary'` which doesn't exist.

**Fix:** Use `'publisher'` for the standard app-to-portfolio assignment.

---

## 8. DP-IT-Services — `relationship_type` Check Constraint

**Problem:** `dpis_relationship_check` enforces: `depends_on`, `built_on`. Script used `'consumer'` which doesn't exist.

**Fix:** Use `'depends_on'` for the standard DP-to-IT-service cost allocation link.

---

## 9. Default Portfolio Auto-Creation on Workspace

**Problem:** Workspace creation auto-generates a default "Core" portfolio per workspace (trigger-created). Script 13 tried to INSERT new default portfolios, hitting unique constraint `portfolios_workspace_id_default_unique`.

**Fix:** UPDATE the existing auto-generated portfolios instead of inserting new ones:
```sql
UPDATE portfolios
SET id = '<planned-uuid>', name = '<desired-name>'
WHERE id = '<auto-generated-id>';
```

**Bulk import note:** After creating workspaces, query for the auto-generated default portfolios and work with their IDs rather than trying to create new defaults.

---

## 10. Default Portfolios Cannot Have Children

**Problem:** Trigger `prevent_children_on_default_portfolio()` blocks inserting child portfolios under a default (`is_default = true`) portfolio.

**Fix:** Remove the default flag before adding children:
```sql
UPDATE portfolios SET is_default = false WHERE id = '<parent-id>';
-- Then INSERT children with parent_portfolio_id = '<parent-id>'
```

**Implication:** Any workspace with a portfolio hierarchy needs at least one non-default leaf portfolio for app assignments. We created "General" catch-all children under CSU and FB roots for apps that don't fit specific sub-portfolios.

---

## 11. Parent Portfolios Cannot Accept App Assignments

**Problem:** Trigger `prevent_assignment_to_parent_portfolio()` blocks assigning apps to a portfolio that has children. Only leaf portfolios accept assignments.

**Fix:** Create leaf portfolios (e.g., "General") under any parent that needs to hold apps directly. For the Garland import, we added:
- CSU root → "General" child (for Selectron IVR, Aperta)
- FB root → "General" child (for Courts Plus)

**Bulk import note:** Before assigning apps to portfolios, verify the target portfolio has no children. If it does, assign to a child or create a "General" leaf.

---

## 12. `deployment_profiles` Has No `namespace_id` Column

**Problem:** Multiple validation queries referenced `dp.namespace_id` which doesn't exist. Deployment profiles connect to namespaces through workspaces.

**Fix:** Always join through workspaces:
```sql
-- WRONG
WHERE dp.namespace_id = '...'

-- RIGHT
JOIN workspaces w ON w.id = dp.workspace_id
WHERE w.namespace_id = '...'
```

**Same pattern applies to:** `applications` (no `namespace_id` — join through `workspaces`).

**Tables that DO have `namespace_id`:** `it_services`, `organizations`, `contacts`, `software_products`, `technology_products`, `namespaces`, `assessment_factors`.

---

## 13. OG Data Quality Notes

These aren't schema issues but data mapping gotchas for the bulk import:

| Issue | Detail | Resolution |
|-------|--------|-----------|
| IT Service costs are $0 in OG | All 706 OG IT Services have AnnualCost=0. Real costs are in OG `ApplicationCosts` or hand-curated. | Use plan values or PortfolioApplicationCostHistory for bulk import |
| OG hosting is multi-valued | OG assigns multiple hosting types per app (e.g., "On Premise" + "COTS"). NextGen uses a single value. | Pick primary hosting type; prefer the one matching server infrastructure |
| OG directions differ | OG uses "Publish"/"Subscribe"/blank. NextGen uses "downstream"/"upstream"/"bidirectional". | Map: Publish→downstream, Subscribe→upstream, blank→bidirectional |
| OG integration field names | OG uses `ApplicationId`/`OtherApplicationId`, not `SourceApplicationId`/`TargetApplicationId` | Map correctly during extraction |
| OG assessment answers need joins | Path: `ApplicationQuestionAnswers` → `AccountQuestions` (get QuestionId) → `Questions` (get Attribute) → `QuestionAnswers` (get AnswerValue). PortfolioId NULL = tech, NOT NULL = business. | Build the full join pipeline before extracting scores |
| B-scores missing for many apps | Only 13 of 21 showcase apps had B-scores in OG. Expect similar gaps in bulk import. | Set `business_assessment_status = 'Not Started'` for unscored apps |
| Cayenta has two OG variants | "Cayenta (Cognos)" and "Cayenta (Finance)" are separate OG apps | Only "Cayenta (Finance)" was imported for showcase |

---

## Recommended Import Order

Based on FK dependencies and trigger behavior:

```
1.  Disable auto-DP trigger on applications
2.  Workspaces (slug required, auto-creates "Core" default portfolio)
3.  Organizations (namespace-scoped, no tricky FKs)
4.  Software Products (needs org IDs for manufacturer_org_id)
5.  Technology Products (namespace-scoped)
6.  Contacts (workspace_role must be read_only/admin/editor/steward/restricted)
7.  Applications (with DP trigger disabled)
8.  Deployment Profiles (with T-scores, vendor_org_id, server_name)
9.  Re-enable auto-DP trigger
10. DP → Software Products junction
11. DP → Technology Products junction
12. IT Services (namespace-scoped, with costs)
13. DP → IT Services (relationship_type: depends_on/built_on)
14. IT Service → Software Products junction
15. Update default portfolios (rename, remove is_default if adding children)
16. Child portfolios
17. Portfolio Assignments (relationship_type: publisher/consumer, with B-scores)
18. Integrations
19. Application Contacts
20. Workspace Contacts / Portfolio Contacts (leadership)
21. Validation
```

---

## Check Constraints Reference

Quick reference for enum-like columns that have check constraints:

| Table | Column | Valid Values |
|-------|--------|-------------|
| `contacts` | `workspace_role` | admin, editor, steward, read_only, restricted |
| `contacts` | `contact_category` | internal, external, vendor_rep |
| `portfolio_assignments` | `relationship_type` | publisher, consumer |
| `deployment_profile_it_services` | `relationship_type` | depends_on, built_on |
| `workspace_contacts` | `role_type` | leader, business_owner, technical_owner, steward, budget_owner, sponsor, other |
| `portfolio_contacts` | `role_type` | leader, business_owner, technical_owner, steward, budget_owner, sponsor, other |
| `workspaces` | `slug` | NOT NULL, no default — must provide |

---

*Last updated: 2026-04-09*
*Next: Use this document when building the 370-app bulk import scripts.*
