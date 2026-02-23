# GetInSync NextGen - Demo & Test Credentials

**Version:** 1.1  
**Last Updated:** February 3, 2026  
**Maintainer:** Stuart Holtby

---

## Production Namespaces

### City of Riverside (Primary Demo Namespace)
- **Purpose:** Primary demo/showcase namespace for customer presentations (Delta's main demo)
- **URL:** nextgen.getinsync.ca
- **Namespace UUID:** `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
- **Admin Email:** demo@getinsync.ca
- **Admin Password:** [SECURE - Not documented here, use password manager]
- **Tier:** Enterprise
- **Data:**
  - 56 applications across 17 workspaces
  - $4.6M total budget (documented value)
  - Multiple portfolios configured
  - TIME/PAID assessments complete
- **Created:** January 28, 2026
- **Read-Only Access:** Yes (for Delta demos)
- **Notes:** Reference demo data for customer presentations, most comprehensive demo

### Pal's Pets (Production Test Namespace)
- **Purpose:** Production testing, feature validation
- **URL:** nextgen.getinsync.ca
- **Namespace UUID:** `6b6b1b74-3196-48a0-8978-4619a797859d`
- **Admin Emails:** stuart@allstartech.com, stuart@getinsync.ca
- **Tier:** Enterprise
- **Data:** 64 applications, 1 workspace
- **Users:** 5 users (2 admins, 1 super admin)
- **Created:** December 29, 2025
- **Notes:** Stuart's production test environment

### Government of Saskatchewan (Stuart's Main Namespace)
- **Purpose:** Stuart's primary working namespace
- **URL:** nextgen.getinsync.ca
- **Namespace UUID:** `b00adf2d-4584-4bb4-a889-6931782960dc`
- **Admin Email:** smholtby@gmail.com
- **Tier:** Enterprise
- **Data:** 14 applications across 4 workspaces
- **Created:** December 22, 2025
- **Notes:** Contains production IT Services data, handle with care

---

## Test Namespaces

### Government of Alberta (Test)
- **Purpose:** Testing multi-ministry scenarios, demo data development
- **URL:** nextgen.getinsync.ca
- **Namespace UUID:** `b65cf341-1288-4ce8-a360-0b45f27d8aa4`
- **Admin Email:** ns.admin@test.gov.ab.ca
- **Admin Password:** [SECURE]
- **Tier:** Enterprise
- **Data:** 10 applications across 3 workspaces (LegalEdge deployment scenario: WSD, HRT, MAB)
- **Created:** January 22, 2026
- **Notes:** Used for testing DP-centric assessment model

### Phase 25.8 Test Namespaces (Provisioning Tests)
Created to test Super Admin provisioning workflow:

1. **Test Customer Co**
   - UUID: `90ca7db9-c20e-4ece-bc87-592da2409994`
   - Admin: smholtby+testcust@gmail.com
   - Tier: Trial | Created: Feb 3, 2026
   - Data: 2 workspaces, 0 apps

2. **SaskEnergy Corporation**
   - UUID: `1089544b-4261-4823-a5ed-bd93a4f4da0a`
   - Admins: smholtby+skenergy@gmail.com, smholtby+test@gmail.com (2 admins)
   - Tier: Trial | Created: Feb 2, 2026
   - Data: 2 workspaces, 0 apps

3. **Selkirk Productions**
   - UUID: `7c0dfa01-10f1-43d6-b782-35c7aaa679de`
   - Admin: smholtby+selkirk@gmail.com
   - Tier: Enterprise | Created: Feb 1, 2026
   - Data: 1 workspace, 0 apps

4. **Final Test Co**
   - UUID: `8d42e6d1-df0d-4675-b42e-d58fb6e91794`
   - Admin: smholtby+finaltest@gmail.com
   - Tier: Essentials | Created: Feb 1, 2026
   - Data: 1 workspace, 0 apps

5. **Acme Corp 2025**
   - UUID: `af069217-437b-4e14-bd75-b87f11b3c17b`
   - Admin: smholtby+acme@gmail.com
   - Tier: Trial | Created: Feb 1, 2026
   - Data: 1 workspace, 1 app

6. **Test Corp 2025**
   - UUID: `29897df0-1f04-45a3-b3c3-0d94146c201a`
   - Admin: smholtby+testcorp@gmail.com
   - Tier: Trial | Created: Feb 1, 2026
   - Data: 1 workspace, 0 apps

7. **SaskPower Corporation**
   - UUID: `a841a561-56f3-4332-b3a4-c377529f028f`
   - Admin: smholtby+skpower@gmail.com
   - Tier: Enterprise | Created: Feb 1, 2026
   - Data: 1 workspace, 0 apps

8. **Delta's OrgSpace**
   - UUID: `3c0c338b-5f78-4e90-a985-58e5d6063866`
   - Admin: smholtby+delta@gmail.com
   - Tier: Enterprise | Created: Feb 3, 2026
   - Data: 1 workspace, 0 apps
   - Notes: Delta's personal test namespace

### Orphaned/Legacy Namespaces

1. **Technical Safety Authority of Saskatchewan**
   - UUID: `1a50f34e-e2e4-4747-b9bb-3156f92687ad`
   - Admin: **None** (no users)
   - Tier: Trial | Created: Jan 3, 2026
   - Data: 1 workspace, 3 apps
   - Status: ⚠ï¸ Orphaned (no admin assigned)

2. **Default Organization**
   - UUID: `00000000-0000-0000-0000-000000000001`
   - Admin: **None** (system default)
   - Tier: Trial | Created: Dec 22, 2025
   - Data: 1 workspace, 0 apps
   - Status: System default namespace (likely unused) 

---

## Development Access

### Platform Admin (Delta)
- **URL:** nextgen.getinsync.ca
- **Email:** [TBD - Delta's platform admin email]
- **Role:** Platform Admin (super admin privileges)
- **Can Access:**
  - All namespaces (Super Admin dashboard)
  - Provisioning new customers
  - Pending invitations
  - [Future: Namespace management, impersonation]

### Platform Admin (Stuart)
- **URL:** nextgen.getinsync.ca
- **Email:** [TBD - Stuart's platform admin email]
- **Role:** Platform Admin + Database access
- **Additional Access:**
  - Supabase dashboard (ca-central-1)
  - GitHub repo: sholtby/getinsync-nextgen-ag
  - Netlify deployment

---

## Environment URLs

### Production
- **URL:** https://nextgen.getinsync.ca
- **Deployment:** GitHub main branch → Netlify
- **Database:** Supabase ca-central-1 (production)

### Dev/Staging
- **URL:** https://dev--relaxed-kataifi-57d630.netlify.app
- **Deployment:** GitHub dev branch → Netlify
- **Database:** Supabase ca-central-1 (shared with production - use carefully)

### Local Development
- **URL:** http://localhost:5173
- **Database:** Supabase ca-central-1 (shared)
- **Notes:** Stuart's MacBook Pro, Chrome browser

---

## Supabase Access

### Project Details
- **Region:** ca-central-1 (Canada Central)
- **Project URL:** [TBD - Supabase project URL]
- **Access:** Stuart only (schema migrations, direct SQL)

### API Keys (Not Documented Here)
- **Location:** Environment variables in Netlify
- **Security:** Never commit to GitHub, use .env.local for development

---

## Third-Party Services

### Antigravity (AG)
- **URL:** bolt.new (or specific AG instance)
- **Access:** Stuart's account
- **Constraints:** No Supabase access, frontend only

### GitHub Repository
- **Repo:** sholtby/getinsync-nextgen-ag
- **Access:** Stuart (owner)
- **Branches:**
  - `main` → Production
  - `dev` → Staging
  - Feature branches as needed

---

## Security Notes

### Password Management
- **DO NOT** store actual passwords in this document
- **USE:** 1Password, LastPass, or secure password manager
- **SHARE:** Only via secure channels (never email/Slack plain text)

### Access Levels
- **Platform Admin:** Full system access (Delta, Stuart)
- **Namespace Admin:** Single namespace only (customer admins)
- **Editor:** Can create/edit apps within workspace
- **Read-Only:** Dashboard viewing only

### Credential Rotation
- **Platform Admin passwords:** Rotate quarterly
- **Demo namespace passwords:** Change after customer-facing events
- **API keys:** Rotate on security incidents or team changes

---

## Adding New Credentials

When creating new test/demo namespaces:

1. **Create namespace** (Super Admin → New Namespace)
2. **Document here:**
   - Purpose
   - Admin email
   - Namespace UUID (from database)
   - Tier
   - Data scope
3. **Store password** in password manager (reference here, don't store actual password)
4. **Update this doc version** (increment to v1_1, v1_2, etc.)

---

## Changelog

### v1.1 (2026-02-03)
- Imported all namespace data from production database
- Documented 14 namespaces total:
  - 3 production namespaces (Riverside, Pal's Pets, Gov of Saskatchewan)
  - 9 test namespaces (Gov of Alberta + 8 Phase 25.8 provisioning tests)
  - 2 orphaned namespaces (TSASK, Default Org)
- Added namespace UUIDs, admin emails, tier info, creation dates
- Identified orphaned namespaces needing cleanup

### v1.0 (2026-02-03)
- Initial credentials tracking document
- Placeholder for Riverside demo namespace
- Placeholder for Government of Alberta test namespace
- Security guidelines added

---

**Next Steps:**
- Stuart to fill in actual credentials (admin emails, namespace UUIDs)
- Store passwords in secure password manager
- Share read-only access details with Delta for demo purposes
