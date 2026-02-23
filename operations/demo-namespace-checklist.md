# Demo Namespace Setup Checklist

**Version:** 2.0  
**Updated:** 2026-01-29  
**Based on:** Riverside Police Department demo preparation

---

## Pre-Setup

- [ ] Create auth user in Supabase Dashboard (Authentication → Users → Add User)
- [ ] Generate namespace UUID (use: `SELECT gen_random_uuid();`)
- [ ] Choose organization name (e.g., "City of Riverside (Demo)")
- [ ] Choose slug (e.g., "city-of-riverside-demo")
- [ ] Plan workspace structure (IT, HR, Finance, Police, Fire, Public Works, etc.)
- [ ] Determine demo budget scenario (e.g., $3.5M budget, $3.3M run rate)

---

## Section 1: Namespace + User Setup

- [ ] Create namespace record in `namespaces` table
- [ ] Create users record with **`namespace_role = 'admin'`** (CRITICAL for full menu)
- [ ] Add user to `namespace_users` table
- [ ] Create `organization_settings` record with `max_project_budget` (e.g., 1000000)
- [ ] Verify user can log in

---

## Section 2: Workspaces

- [ ] Disable triggers: `ALTER TABLE workspaces DISABLE TRIGGER add_workspace_creator_trigger;`
- [ ] Disable trigger: `ALTER TABLE workspace_users DISABLE TRIGGER enforce_workspace_user_namespace;`
- [ ] Create workspaces (MUST include IT workspace for catalog ownership)
- [ ] Add user to all workspaces as admin via `workspace_users`
- [ ] Re-enable triggers
- [ ] Verify workspaces show in UI dropdown

---

## Section 3: Applications + Deployment Profiles

- [ ] Create applications in `applications` table
- [ ] Create deployment_profiles with `is_primary = true`
- [ ] Verify `hosting_type` values (SaaS, Cloud, On-Prem, etc.)
- [ ] Verify `region` values (e.g., "Canada Central", "N/A (Vendor Managed)")
- [ ] Check that DP names match app names for single-DP apps

---

## Section 4: Portfolio Assignments (CRITICAL!)

- [ ] Run bulk INSERT for portfolio_assignments
- [ ] **Verify all apps have assignments** (apps won't show without this!)
- [ ] Check dashboard to confirm apps are visible

**Test Query:**
```sql
-- Should return 0 rows (all apps should have assignments)
SELECT a.name 
FROM applications a
JOIN deployment_profiles dp ON dp.application_id = a.id
LEFT JOIN portfolio_assignments pa ON pa.deployment_profile_id = dp.id
WHERE a.workspace_id = 'YOUR_WORKSPACE_UUID'
AND pa.id IS NULL;
```

---

## Section 5: Organizations (CRITICAL - OFTEN MISSED!)

- [ ] Create vendor organizations with `is_vendor = true`
- [ ] Create manufacturer organizations with `is_manufacturer = true`
- [ ] **Set `is_shared = true` for ALL organizations** (required for cross-workspace visibility!)
- [ ] Link manufacturers to software_products via `manufacturer_org_id`
- [ ] Verify organizations show in Settings → Vendors & Partners

**Critical Note:** Without `is_shared = true`, organizations will NOT be visible across workspaces. This broke the Riverside demo initially.

**Test Query:**
```sql
-- Should return all organizations with is_shared = true
SELECT name, is_vendor, is_manufacturer, is_shared
FROM organizations
WHERE namespace_id = 'YOUR_NAMESPACE_UUID'
AND is_shared = false;  -- Should be empty!
```

---

## Section 6: Software Products

- [ ] Create software_products (owned by IT workspace)
- [ ] Set `manufacturer_org_id` for each product
- [ ] Set `license_type` (perpetual, subscription, site_license, etc.)
- [ ] Set `annual_cost` if known
- [ ] Verify products show in Software Catalog
- [ ] Verify manufacturer name displays (requires org link)

---

## Section 7: IT Services

- [ ] Create it_services (owned by IT workspace)
- [ ] Set `service_type_id` for catalog display (CRITICAL - won't show without this!)
- [ ] Set `cost_model` (fixed, per_user, per_instance, consumption, tiered)
- [ ] Set `lifecycle_state = 'operational'`
- [ ] Verify services show in IT Service Catalog with correct categories

**Find service_type_id:**
```sql
SELECT id, name FROM service_types WHERE namespace_id = 'YOUR_NAMESPACE_UUID';
```

---

## Section 8: Assessment Data

### T-Scores (Technical Assessment)

- [ ] Set T-scores (t01-t15) on `deployment_profiles` table
- [ ] Set `tech_assessment_status = 'complete'`
- [ ] Set `estimated_tech_debt` (dollar amount) OR `NULL` for modern apps
- [ ] **Set `remediation_effort = NULL`** (let UI calculate from budget %)
- [ ] Set `tech_debt_description` for apps with debt
- [ ] Verify `tech_health` and `tech_risk` auto-calculate correctly

**Critical Notes:**
- Modern SaaS apps with no tech debt: `estimated_tech_debt = NULL`, `remediation_effort = NULL`
- DO NOT set `remediation_effort = 'XS'` for apps with 0 or NULL debt (will display incorrectly)
- Remediation thresholds calculated from `max_project_budget` (XS=0-2.5%, S=2.5-10%, M=10-25%, L=25-50%, XL=50-100%, 2XL=>100%)

### B-Scores (Business Assessment)

- [ ] Set B-scores (b1-b10) on `portfolio_assignments` table
- [ ] Set `business_assessment_status = 'complete'`
- [ ] **Calculate `business_fit` manually** (NOT auto-calculated!)
- [ ] **Calculate `criticality` manually** (NOT auto-calculated!)
- [ ] **Set `time_quadrant` manually** (Invest/Modernize/Tolerate/Eliminate)

**Calculation Formula:**
```sql
business_fit = ((b1+b2+b3+b4+b5+b6+b7+b8+b9+b10 - 10.0) / 40.0) * 100
criticality = ((b1+b2+b3+b4+b5+b6+b7+b8+b9+b10 - 10.0) / 40.0) * 100
```

**Time Quadrant Logic:**
```sql
CASE 
  WHEN tech_health >= 50 AND business_fit >= 50 THEN 'Invest'
  WHEN tech_health < 50 AND business_fit >= 50 THEN 'Modernize'
  WHEN tech_health >= 50 AND business_fit < 50 THEN 'Tolerate'
  ELSE 'Eliminate'
END
```

---

## Section 9: Cost Data (Three Channels)

### Channel 1: Software Product Links

- [ ] Create `deployment_profile_software_products` junctions
- [ ] Set `vendor_org_id` (who you bought from - may differ from manufacturer!)
- [ ] Set `annual_cost` or `allocation_percent`
- [ ] Add `notes` explaining allocation

### Channel 2: IT Service Allocations

- [ ] Create `deployment_profile_it_services` junctions
- [ ] Set `relationship_type` (depends_on or built_on)
- [ ] Set `allocation_basis` (percent or fixed)
- [ ] Set `allocation_value` (percentage ≤100 or dollar amount)
- [ ] Add `notes` explaining infrastructure dependency

### Channel 3: Cost Bundles

- [ ] Create cost_bundle deployment_profiles for recurring costs
- [ ] Set `dp_type = 'cost_bundle'`
- [ ] Set `cost_recurrence = 'recurring'`
- [ ] Set `annual_cost`
- [ ] Set `vendor_org_id` if applicable
- [ ] Set `is_primary = false`

### Cost Verification

- [ ] Query `vw_deployment_profile_costs` for each portfolio
- [ ] Verify `total_cost` matches expectations
- [ ] Check vendor spend aggregation in Cost Analysis page
- [ ] Verify top 10 vendors display with correct percentages

---

## Section 10: Contacts (Optional)

- [ ] Create contacts with `contact_category` (internal/external/vendor_rep)
- [ ] Set `primary_workspace_id` for UI filtering
- [ ] Assign to applications via `application_contacts`
- [ ] Set `role_type` (business_owner, technical_owner, steward, etc.)
- [ ] Set `is_primary = true` for primary owner

---

## Final Verification

### Database Checks

- [ ] Run verification query for entity counts
- [ ] Verify organizations have `is_shared = true`
- [ ] Check portfolio_assignments coverage (all apps assigned)
- [ ] Verify assessment data split (T-scores on DPs, B-scores on PAs)
- [ ] Check cost rollup totals

**Entity Count Query:**
```sql
SELECT 
  'Workspaces' as entity, COUNT(*) FROM workspaces WHERE namespace_id = '...'
UNION ALL
SELECT 'Applications', COUNT(*) FROM applications WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '...')
UNION ALL
SELECT 'Deployment Profiles', COUNT(*) FROM deployment_profiles WHERE workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '...')
UNION ALL
SELECT 'Portfolio Assignments', COUNT(*) FROM portfolio_assignments pa JOIN portfolios p ON pa.portfolio_id = p.id WHERE p.workspace_id IN (SELECT id FROM workspaces WHERE namespace_id = '...')
UNION ALL
SELECT 'Organizations', COUNT(*) FROM organizations WHERE namespace_id = '...'
UNION ALL
SELECT 'Organizations (shared)', COUNT(*) FROM organizations WHERE namespace_id = '...' AND is_shared = true
UNION ALL
SELECT 'Software Products', COUNT(*) FROM software_products WHERE namespace_id = '...'
UNION ALL
SELECT 'IT Services', COUNT(*) FROM it_services WHERE namespace_id = '...';
```

### UI Checks

- [ ] Log in as demo user
- [ ] Verify dashboard shows all apps
- [ ] Check TIME Analysis chart displays quadrants correctly
- [ ] Check PAID Analysis chart displays quadrants correctly
- [ ] Verify Cost Analysis page loads with vendor breakdown
- [ ] Check Settings → Vendors & Partners shows all organizations
- [ ] Verify Software Catalog shows products with manufacturers
- [ ] Verify IT Service Catalog shows services with categories
- [ ] Test application detail pages (click through from dashboard)
- [ ] Verify Assessment modal displays T-scores and B-scores
- [ ] Check Tech Debt Analysis modal shows correct remediation sizes

---

## Common Issues & Fixes

### Issue: Apps not showing in dashboard
**Fix:** Check portfolio_assignments exist. Run Section 4 bulk INSERT.

### Issue: Organizations not visible in Settings → Vendors & Partners
**Fix:** Update organizations: `SET is_shared = true`

### Issue: Software Catalog empty
**Fix:** Check `manufacturer_org_id` is set on software_products

### Issue: IT Service Catalog empty or shows "(0)"
**Fix:** Set `service_type_id` on it_services

### Issue: Assessment scores not calculating
**Fix:** Verify T-scores on deployment_profiles, B-scores on portfolio_assignments

### Issue: Remediation effort showing "XS" for modern apps
**Fix:** Set `estimated_tech_debt = NULL` and `remediation_effort = NULL` (not 0 or 'XS')

### Issue: Cost Analysis page empty
**Fix:** Check `vw_deployment_profile_costs` - verify cost data on all three channels

### Issue: $500K tech debt showing as "L" instead of "XL"
**Fix:** This was a UI boundary bug (fixed in AG session). $500K is START of XL.

---

## Demo Readiness Criteria

✅ **User can log in and see workspace selector**  
✅ **Dashboard shows all applications**  
✅ **TIME/PAID charts render with bubbles**  
✅ **Cost Analysis page shows vendor breakdown**  
✅ **Settings menu fully accessible** (requires namespace_role = 'admin')  
✅ **Vendors & Partners page shows organizations**  
✅ **Software/IT Service catalogs populated**  
✅ **Assessment modals display data correctly**  
✅ **No NULL or missing data errors in console**

---

## Post-Demo Cleanup (Optional)

- [ ] Delete auto-created duplicate DPs (trigger artifacts)
- [ ] Remove unused assessment_thresholds rows (remediation_effort type)
- [ ] Archive demo namespace or update for next demo
- [ ] Document any new issues discovered during demo
- [ ] Update this checklist with lessons learned

---

**Last Updated:** 2026-01-29 (Riverside Police Department demo)  
**Next Review:** After next major demo or phase rollout
