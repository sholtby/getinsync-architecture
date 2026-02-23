# Phase 25.8: Super Admin Provisioning
**Duration:** 4 hours  
**Priority:** CRITICAL - Enables Customer Success independence  
**Goal:** Delta can create namespaces and onboard trial customers without Stuart

---

## Problem Statement

**Current State:**
- Phase 25.7 lets Delta add users to EXISTING namespaces ✓
- But Delta can't CREATE new namespaces
- Every trial customer still requires Stuart to run SQL
- Delta is 50% unblocked (can manage users, can't create namespaces)

**Desired State:**
- Delta creates namespace via UI
- System auto-provisions all required entities
- Generates invitation link for customer admin
- Delta operates completely independently

---

## What We're Building (4 Hours)

### Part 1: Platform Admins (1 hour)

**Create Super Admin Role:**

```sql
-- Table to track platform admins (Delta, Stuart, future CS team)
CREATE TABLE platform_admins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  name text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES platform_admins(id)
);

ALTER TABLE platform_admins ENABLE ROW LEVEL SECURITY;

-- Only platform admins can see this table
CREATE POLICY "Platform admins can view all"
  ON platform_admins FOR SELECT
  USING (
    auth.uid() IN (
      SELECT user_id FROM platform_admins WHERE is_active = true
    )
  );

-- Seed with Stuart and Delta
INSERT INTO platform_admins (user_id, email, name, is_active)
VALUES
  ('{stuart-auth-uuid}', 'stuart@allstartech.com', 'Stuart Holtby', true),
  ('{delta-auth-uuid}', 'delta@getinsync.ca', 'Delta Customer Success', true);
```

**Helper Function:**
```sql
-- Check if current user is platform admin
CREATE FUNCTION is_platform_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM platform_admins
    WHERE user_id = auth.uid() AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
```

---

### Part 2: Provisioning Functions (1.5 hours)

**Function 1: Create Workspace as Super Admin**
```sql
-- Bypasses workspace trigger that auto-adds current user
CREATE FUNCTION create_workspace_as_super_admin(
  p_namespace_id uuid,
  p_name text,
  p_slug text,
  p_admin_user_id uuid
) RETURNS uuid AS $$
DECLARE
  v_workspace_id uuid;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can call this function';
  END IF;

  -- Disable auto-add trigger
  EXECUTE 'ALTER TABLE workspaces DISABLE TRIGGER add_workspace_creator_trigger';
  
  -- Create workspace
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (p_namespace_id, p_name, p_slug, true)
  RETURNING id INTO v_workspace_id;
  
  -- Add admin to workspace
  INSERT INTO workspace_users (workspace_id, user_id, role)
  VALUES (v_workspace_id, p_admin_user_id, 'admin');
  
  -- Re-enable trigger
  EXECUTE 'ALTER TABLE workspaces ENABLE TRIGGER add_workspace_creator_trigger';
  
  RETURN v_workspace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Function 2: Seed Template Data**
```sql
-- Copy assessment configuration from template namespace
CREATE FUNCTION seed_namespace_templates(p_namespace_id uuid)
RETURNS void AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can call this function';
  END IF;

  -- Copy assessment factors
  INSERT INTO assessment_factors (
    namespace_id, factor_key, question, weight, category, 
    is_business, min_score, max_score, display_order
  )
  SELECT 
    p_namespace_id, factor_key, question, weight, category,
    is_business, min_score, max_score, display_order
  FROM assessment_factors
  WHERE namespace_id = v_template_namespace_id;
  
  -- Copy assessment thresholds
  INSERT INTO assessment_thresholds (
    namespace_id, metric_type, threshold_type, 
    threshold_value, description
  )
  SELECT 
    p_namespace_id, metric_type, threshold_type,
    threshold_value, description
  FROM assessment_thresholds
  WHERE namespace_id = v_template_namespace_id;
  
  -- Service types seed automatically via trigger on namespace creation
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Function 3: Complete Provisioning**
```sql
-- Orchestrates entire namespace provisioning
CREATE FUNCTION provision_namespace(
  p_org_name text,
  p_slug text,
  p_tier text,
  p_admin_email text,
  p_admin_name text,
  p_workspace_name text
) RETURNS jsonb AS $$
DECLARE
  v_namespace_id uuid;
  v_workspace_id uuid;
  v_result jsonb;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can provision namespaces';
  END IF;

  -- Validate tier
  IF p_tier NOT IN ('free', 'pro', 'enterprise', 'full') THEN
    RAISE EXCEPTION 'Invalid tier: %. Must be free, pro, enterprise, or full', p_tier;
  END IF;

  -- Create namespace
  INSERT INTO namespaces (name, slug, tier)
  VALUES (p_org_name, p_slug, p_tier)
  RETURNING id INTO v_namespace_id;
  
  -- Seed template data
  PERFORM seed_namespace_templates(v_namespace_id);
  
  -- Return result (auth user creation happens in app layer)
  v_result := jsonb_build_object(
    'namespace_id', v_namespace_id,
    'namespace_name', p_org_name,
    'slug', p_slug,
    'tier', p_tier
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### Part 3: Super Admin UI (1.5 hours)

**Route:** `/super-admin/namespaces/new`

**Access Control:**
```typescript
// Middleware to protect super admin routes
async function requirePlatformAdmin() {
  const { data: isAdmin } = await supabase
    .rpc('is_platform_admin');
  
  if (!isAdmin) {
    throw new Error('Unauthorized: Platform admin access required');
  }
}
```

**Component:**
```typescript
// src/pages/super-admin/CreateNamespace.tsx

interface CreateNamespaceForm {
  organizationName: string;
  slug: string;
  tier: 'free' | 'pro' | 'enterprise' | 'full';
  adminEmail: string;
  adminName: string;
  workspaceName: string;
}

async function handleCreateNamespace(form: CreateNamespaceForm) {
  try {
    // Step 1: Create namespace (calls provision_namespace function)
    const { data: namespaceResult } = await supabase
      .rpc('provision_namespace', {
        p_org_name: form.organizationName,
        p_slug: form.slug,
        p_tier: form.tier,
        p_admin_email: form.adminEmail,
        p_admin_name: form.adminName,
        p_workspace_name: form.workspaceName
      });
    
    // Step 2: Create auth user via Supabase Admin API
    const { data: authUser } = await supabase.auth.admin.createUser({
      email: form.adminEmail,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        name: form.adminName
      }
    });
    
    // Step 3: Create public.users record
    await supabase.from('users').insert({
      id: authUser.user.id,
      email: form.adminEmail,
      name: form.adminName,
      namespace_id: namespaceResult.namespace_id,
      namespace_role: 'admin'
    });
    
    // Step 4: Create workspace
    const { data: workspaceId } = await supabase
      .rpc('create_workspace_as_super_admin', {
        p_namespace_id: namespaceResult.namespace_id,
        p_name: form.workspaceName,
        p_slug: slugify(form.workspaceName),
        p_admin_user_id: authUser.user.id
      });
    
    // Step 5: Generate invitation link
    const inviteToken = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    
    await supabase.from('pending_invitations').insert({
      namespace_id: namespaceResult.namespace_id,
      email: form.adminEmail,
      role: 'admin',
      token: inviteToken,
      expires_at: expiresAt
    });
    
    const inviteLink = `https://nextgen.getinsync.ca/signup?token=${inviteToken}`;
    
    // Step 6: Show success with invitation link
    showSuccessModal({
      namespace: namespaceResult,
      adminEmail: form.adminEmail,
      inviteLink: inviteLink
    });
    
  } catch (error) {
    console.error('Provisioning failed:', error);
    showError('Failed to create namespace. Please check logs.');
  }
}
```

**UI Layout:**
```typescript
<div className="max-w-2xl mx-auto p-8">
  <h1 className="text-2xl font-bold mb-6">Create New Namespace</h1>
  
  <form onSubmit={handleSubmit}>
    {/* Organization Info */}
    <section className="mb-8">
      <h2 className="text-lg font-semibold mb-4">Organization</h2>
      
      <div className="mb-4">
        <label>Organization Name</label>
        <input 
          type="text"
          placeholder="Government of Saskatchewan"
          value={form.organizationName}
          onChange={e => setForm({...form, organizationName: e.target.value})}
          required
        />
      </div>
      
      <div className="mb-4">
        <label>Slug (URL)</label>
        <input 
          type="text"
          placeholder="gov-sask"
          value={form.slug}
          onChange={e => setForm({...form, slug: slugify(e.target.value)})}
          required
        />
        <p className="text-sm text-gray-500">
          https://nextgen.getinsync.ca/{form.slug}
        </p>
      </div>
      
      <div className="mb-4">
        <label>Tier</label>
        <select 
          value={form.tier}
          onChange={e => setForm({...form, tier: e.target.value})}
          required
        >
          <option value="free">Free</option>
          <option value="pro">Pro</option>
          <option value="enterprise">Enterprise</option>
          <option value="full">Full</option>
        </select>
      </div>
    </section>
    
    {/* Admin User Info */}
    <section className="mb-8">
      <h2 className="text-lg font-semibold mb-4">Initial Administrator</h2>
      
      <div className="mb-4">
        <label>Admin Email</label>
        <input 
          type="email"
          placeholder="admin@gov.sk.ca"
          value={form.adminEmail}
          onChange={e => setForm({...form, adminEmail: e.target.value})}
          required
        />
      </div>
      
      <div className="mb-4">
        <label>Admin Name</label>
        <input 
          type="text"
          placeholder="John Smith"
          value={form.adminName}
          onChange={e => setForm({...form, adminName: e.target.value})}
          required
        />
      </div>
    </section>
    
    {/* Default Workspace */}
    <section className="mb-8">
      <h2 className="text-lg font-semibold mb-4">Default Workspace</h2>
      
      <div className="mb-4">
        <label>Workspace Name</label>
        <input 
          type="text"
          placeholder="Central IT"
          value={form.workspaceName}
          onChange={e => setForm({...form, workspaceName: e.target.value})}
          required
        />
      </div>
    </section>
    
    <div className="flex gap-4">
      <button type="button" onClick={() => router.back()}>
        Cancel
      </button>
      <button type="submit" className="btn-primary">
        Create Namespace
      </button>
    </div>
  </form>
</div>
```

**Success Modal:**
```typescript
<Modal isOpen={showSuccess}>
  <h2>✓ Namespace Created Successfully</h2>
  
  <div className="my-6">
    <p className="mb-2">Organization: <strong>{namespace.name}</strong></p>
    <p className="mb-2">URL: <strong>nextgen.getinsync.ca/{namespace.slug}</strong></p>
    <p className="mb-2">Tier: <strong>{namespace.tier}</strong></p>
  </div>
  
  <div className="bg-gray-50 p-4 rounded mb-4">
    <p className="font-semibold mb-2">Send this invitation to {adminEmail}:</p>
    <code className="block bg-white p-2 rounded text-sm">
      {inviteLink}
    </code>
    <button onClick={() => copyToClipboard(inviteLink)} className="mt-2">
      Copy Link
    </button>
  </div>
  
  <p className="text-sm text-gray-600 mb-4">
    ℹï¸ Link expires in 7 days
  </p>
  
  <button onClick={handleClose}>Done</button>
</Modal>
```

---

## Implementation Checklist

### Database (1 hour)
- [ ] Create platform_admins table
- [ ] Create is_platform_admin() function
- [ ] Create create_workspace_as_super_admin() function
- [ ] Create seed_namespace_templates() function
- [ ] Create provision_namespace() function
- [ ] Insert Stuart and Delta as platform admins
- [ ] Test functions in SQL editor

### Backend/API (1.5 hours)
- [ ] Create super admin middleware
- [ ] Implement namespace provisioning endpoint
- [ ] Handle Supabase Admin API auth user creation
- [ ] Link auth user to namespace (users table)
- [ ] Create workspace via RPC
- [ ] Generate invitation token
- [ ] Error handling and rollback

### Frontend (1.5 hours)
- [ ] Create /super-admin/namespaces/new route
- [ ] Build CreateNamespace form component
- [ ] Implement form validation
- [ ] Call provisioning API
- [ ] Show success modal with invite link
- [ ] Copy to clipboard functionality
- [ ] Error handling and user feedback

---

## Testing Plan

### Test Case 1: Happy Path
```
1. Delta logs in as platform admin
2. Navigate to /super-admin/namespaces/new
3. Fill form:
   - Org: Test Company Inc
   - Slug: test-company
   - Tier: Pro
   - Email: admin@test.com
   - Name: Test Admin
   - Workspace: IT Department
4. Click "Create Namespace"
5. Verify:
   ✓ Namespace created in database
   ✓ Auth user created and confirmed
   ✓ public.users record created
   ✓ Workspace created
   ✓ workspace_users record created
   ✓ Assessment factors seeded
   ✓ Assessment thresholds seeded
   ✓ Invitation link displayed
6. Copy invitation link
7. Open in incognito browser
8. Complete signup
9. Login
10. Verify user sees workspace with template data
```

### Test Case 2: Non-Admin Access
```
1. Login as non-platform-admin user
2. Try to access /super-admin/namespaces/new
3. Verify: 403 Unauthorized error
4. Try to call provision_namespace() directly
5. Verify: Permission denied error
```

### Test Case 3: Invalid Tier
```
1. Delta fills form with tier = 'invalid'
2. Click "Create Namespace"
3. Verify: Error message "Invalid tier"
4. No namespace created
```

### Test Case 4: Duplicate Slug
```
1. Create namespace with slug 'test-org'
2. Try to create another with same slug
3. Verify: Error message "Slug already exists"
4. Suggest alternative slug
```

---

## Success Criteria

**Phase 25.8 is COMPLETE when:**
- ✅ Delta can create namespace via UI (no SQL required)
- ✅ System auto-provisions all required entities
- ✅ Template data (factors, thresholds) seeded automatically
- ✅ Invitation link generated and copyable
- ✅ Customer can complete signup and access workspace
- ✅ Non-platform-admins cannot access super admin UI
- ✅ All functions have proper security checks
- ✅ Git committed with proper documentation

---

## Delta's Complete Workflow (All Phases)

### Onboard New Trial Customer:

**Phase 25.8: Create Namespace**
1. Delta → /super-admin/namespaces/new
2. Fill form (org name, tier, admin email)
3. Click "Create Namespace"
4. Copy invitation link

**Phase 25.7: Send Invitation**
5. Delta → Outlook/Gmail
6. Compose email with invitation link
7. Send to customer admin

**Customer: Self-Service Signup**
8. Customer clicks link
9. Sets password
10. Logs in
11. Sees workspace with template data

**Phase 25.7: Customer Adds Team**
12. Customer → Settings → Team
13. Adds team members
14. Team members complete signup
15. Team starts using GetInSync

**Delta never needs Stuart! 🎉**

---

## Security Considerations

### Platform Admin Protection
```sql
-- Only specific users can be platform admins
-- Managed via platform_admins table
-- Cannot be self-assigned
-- Requires existing platform admin to add new ones
```

### RLS Enforcement
```sql
-- All super admin functions check is_platform_admin()
-- RLS policies prevent unauthorized access
-- Supabase Admin API calls from backend only
```

### Audit Trail (Future Phase 29)
```sql
-- Log all namespace provisioning actions
-- Track who created what when
-- Immutable audit log for compliance
```

---

## What's NOT in Phase 25.8

**Deliberately excluded (future phases):**
- ❌ Edit existing namespace (Phase 29)
- ❌ Delete/archive namespace (Phase 29)
- ❌ Namespace transfer between admins (Phase 29)
- ❌ Bulk namespace creation (Phase 30+)
- ❌ Self-service signup (customer creates own namespace) (Phase 30+)
- ❌ Billing integration (Phase 30+)
- ❌ Audit log UI (Phase 29)
- ❌ Namespace list view (Phase 29)

**Rationale:** MVP to unblock Delta. Enhancements later.

---

## Migration Notes

### Existing Namespaces
```sql
-- No migration needed
-- Existing namespaces continue to work
-- Just adds super admin capability going forward
```

### Existing Platform Admins
```sql
-- Manually add to platform_admins table:
INSERT INTO platform_admins (user_id, email, name)
VALUES
  ('{stuart-uuid}', 'stuart@allstartech.com', 'Stuart Holtby'),
  ('{delta-uuid}', 'delta@getinsync.ca', 'Delta Customer Success');
```

---

## Git Commit Message

```bash
git add migrations/phase-25.8-super-admin-provisioning.sql
git add src/pages/super-admin/CreateNamespace.tsx
git add src/middleware/requirePlatformAdmin.ts
git commit -m "Phase 25.8: Super Admin Provisioning

Enable platform admins to create namespaces via UI:
- platform_admins table for super admin role
- provision_namespace() RPC for complete provisioning
- create_workspace_as_super_admin() RPC bypasses trigger
- seed_namespace_templates() copies assessment config
- /super-admin/namespaces/new UI form
- Auto-creates auth user, namespace, workspace, templates
- Generates invitation link for customer admin
- Security: All functions check is_platform_admin()

Delta can now onboard trial customers independently:
1. Create namespace via UI (Phase 25.8)
2. Generate invitation link
3. Email to customer admin
4. Customer self-service signup (Phase 25.7)
5. Customer adds team via UI (Phase 25.7)

Duration: 4 hours
Status: Complete - Customer Success fully independent"

git push origin main
```

---

## Related Documents

**Architecture:**
- planning/super-admin-provisioning.md (this phase implements it)
- archive/superseded/identity-security-v1_0.md (platform admin role)
- core/core-architecture.md (namespace/workspace model)

**Dependencies:**
- Phase 25.7 (User Management) - invitation system
- Supabase Admin API - auth user creation
- pending_invitations table - signup flow

---

**Ready to execute when you are!** 🚀

**Next:** After Phase 25.8, Delta can onboard customers end-to-end with zero Stuart involvement.
