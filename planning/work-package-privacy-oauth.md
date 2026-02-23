# planning/work-package-privacy-oauth.md
Privacy Policy Update & OAuth Social Login Work Package  
Phase: Foundation (Week 1-2)  
Last updated: 2026-02-07

---

## Executive Summary

**Objective:** Update Privacy Policy to enable OAuth verification and implement Google/Microsoft social login

**Critical Path:** Privacy Policy is the blocker for OAuth verification. Must be deployed BEFORE submitting OAuth apps for verification.

**Timeline:**
- Privacy Policy Update: 2-3 hours (Mon-Thu Week 1)
- OAuth Implementation: 1-2 days (Thu Week 1 - Tue Week 2)
- Verification Submission: Friday Week 2

**Owner:** Stuart (Privacy Policy), Stuart + AG (OAuth implementation)

---

## The Catch-22: Legal Pages Must Come First

### The Problem
1. Google/Microsoft require privacy policy URL during OAuth app registration
2. Privacy policy must disclose OAuth providers BEFORE they're enabled
3. Current privacy policy has critical gaps blocking verification
4. Can't enable OAuth without verification, can't get verified without proper privacy policy

### The Solution
1. ✅ **Update Privacy Policy first** (this work package)
2. ✅ Register OAuth apps (using updated privacy policy URL)
3. ✅ Implement OAuth UI
4. ✅ Submit for verification
5. ⏳ Use "unverified" OAuth while verification processes (works but shows warning)

---

## PRIVACY POLICY ANALYSIS - CRITICAL ISSUES

### Issue 1: Wrong Domain Throughout
**Current:** References "allstartech.com"  
**Required:** "getinsync.ca"  
**Impact:** Trust/credibility failure, OAuth verification will reject  
**Fix:** Find-replace all instances

### Issue 2: Outdated Date
**Current:** December 31, 2020  
**Required:** February 7, 2026  
**Impact:** Appears abandoned/unmaintained  
**Fix:** Update to deployment date

### Issue 3: Missing OAuth Disclosure
**Current:** No mention of third-party authentication  
**Required:** MUST disclose Google OAuth, Microsoft OAuth before verification  
**Impact:** **BLOCKER** for OAuth verification  
**Fix:** Add comprehensive Third-Party Authentication section

### Issue 4: No Multi-Tenant Security Explanation
**Current:** Generic privacy policy  
**Required:** Explain namespace isolation, RLS, workspace segregation  
**Impact:** Enterprise buyers need this for security reviews  
**Fix:** Add Multi-Tenant Security section

### Issue 5: No Canadian Data Residency Emphasis
**Current:** Generic infrastructure mentions  
**Required:** Emphasize Canadian hosting, PIPEDA compliance, LA FOIP alignment  
**Impact:** Competitive differentiator not leveraged  
**Fix:** Add Canadian Data Residency section

---

## MAJOR SECTIONS TO ADD

### 1. Third-Party Authentication (CRITICAL - OAuth Blocker)

**What to Include:**

```markdown
## 3. Third-Party Authentication Services

GetInSync offers multiple ways to create and access your account:

### Email/Password Authentication
You can create an account directly with GetInSync using your email address and a password you create.

### Sign in with Google
When you choose "Sign in with Google", you authenticate using your Google account. Google shares the following information with us:
- Your email address (used as your account identifier)
- Your name (used to personalize your experience)
- Your profile picture (optional, used in your account display)

**What we DON'T receive:**
- Your Google password
- Access to your Gmail or Google Drive
- Any other Google account data

For more information about Google's privacy practices, see: https://policies.google.com/privacy

### Sign in with Microsoft
When you choose "Sign in with Microsoft" (personal accounts), Microsoft shares:
- Your email address (used as your account identifier)
- Your name (used to personalize your experience)
- Your profile picture (optional, used in your account display)

**What we DON'T receive:**
- Your Microsoft password
- Access to your OneDrive or Office 365
- Any other Microsoft account data

For more information about Microsoft's privacy practices, see: https://privacy.microsoft.com/

### Entra ID Single Sign-On (Enterprise Work Accounts)
Enterprise customers can configure Single Sign-On (SSO) through Microsoft Entra ID. When your organization's IT administrator configures Entra ID SSO:
- You authenticate using your company work account
- Your organization controls access and can revoke it at any time
- We receive only the information your IT administrator has configured to share (typically: email, name, department)
- We do NOT receive your corporate password or access to your company resources

**Your organization's privacy policy** governs how your employer handles your work account data.

### What Happens When You Use Third-Party Authentication
1. You are redirected to Google, Microsoft, or your company's login page
2. You authenticate directly with that provider (we never see your password)
3. The provider sends us a secure token confirming your identity
4. We create or access your GetInSync account using your email as the identifier
5. You can disconnect third-party authentication at any time in Account Settings

### Account Linking
If you sign up with email/password and later use "Sign in with Google" using the same email address, we will link these to the same account. You can use either method to log in.
```

**Why This Section is Critical:**
- Google OAuth verification REQUIRES disclosure of what data is collected
- Must explain what you DO and DON'T receive
- Must link to provider privacy policies
- Missing this = automatic verification rejection

---

### 2. Canadian Data Residency (Competitive Differentiator)

**What to Include:**

```markdown
## 4. Canadian Data Residency

### Where Your Data is Stored
All GetInSync customer data is stored in **Canada** by default:
- Database: Supabase (ca-central-1 region - Montreal, Quebec)
- Application hosting: Canada Central region
- File storage: Canadian data centers

### Why This Matters
**Canadian Privacy Laws:** Your data is subject to Canadian privacy legislation, including:
- Personal Information Protection and Electronic Documents Act (PIPEDA)
- Provincial privacy laws where applicable (e.g., Alberta FOIP, LA FOIP for Saskatchewan customers)

**Data Sovereignty:** Your data remains under Canadian jurisdiction and is not subject to foreign government access requests under laws like the US PATRIOT Act or CLOUD Act, except through proper Canadian legal channels.

### Multi-Region Options
Enterprise customers can choose their data region:
- **Canada** (default): All data in Canadian data centers
- **United States**: Optional US region for American organizations
- **European Union**: Optional EU region for European organizations (GDPR compliance)

**Your region choice is permanent** and data is NOT transferred between regions. If you start in Canada, your data stays in Canada.

### Cross-Border Data Transfer
If you choose a non-Canadian region, your data will be stored in that jurisdiction and subject to that region's laws. We disclose this choice clearly during signup.

**For Canadian organizations:** We recommend the Canada region to maintain data sovereignty and comply with procurement policies requiring Canadian data residency.
```

**Why This Section Matters:**
- Government RFPs increasingly require Canadian data residency
- SOC2 compliance easier when data location is clear
- Competitive advantage over US-only SaaS tools
- FOIP compliance requirement for Saskatchewan government

---

### 3. Multi-Tenant Security (Enterprise Credibility)

**What to Include:**

```markdown
## 5. Multi-Tenant Security & Data Isolation

GetInSync is a multi-tenant SaaS platform. This means multiple organizations use the same application infrastructure, but **your data is completely isolated** from other customers.

### How We Isolate Your Data

**Namespace-Level Isolation:**
Every organization gets a unique "namespace" - a logical container for all your data. Think of it like separate apartments in a building: shared infrastructure, but your space is private and locked.

**Row-Level Security (RLS):**
Our database uses PostgreSQL Row-Level Security policies to enforce data isolation at the database level. This means:
- Database queries automatically filter to show only YOUR organization's data
- Even if there were an application bug, the database prevents cross-tenant data access
- Every query is checked against your namespace membership BEFORE returning results

**Workspace Segregation:**
Within your namespace, you can create multiple "workspaces" (e.g., different departments). Users only see workspaces they're assigned to. A user in "Finance Workspace" cannot see data in "HR Workspace" unless explicitly granted access.

### Access Controls

**Role-Based Access Control (RBAC):**
- Namespace Admins: Can manage all workspaces and users in their organization
- Workspace Admins: Can manage their assigned workspace(s)
- Editors: Can create and edit data in their workspace
- Viewers: Read-only access to their workspace

**Audit Logging:**
All user actions are logged with:
- Who performed the action
- What was changed
- When it occurred
- Which namespace/workspace it affected

### SOC2 Compliance Roadmap
We are preparing for SOC2 Type II certification, which includes:
- Annual third-party security audits
- Penetration testing
- Data encryption at rest and in transit
- Disaster recovery procedures
- Access control reviews

**Current Status:** SOC2 Type II certification targeted for Q2 2026.

### What This Means For You
- **Your data is private:** Other GetInSync customers cannot access your applications, assessments, or any data
- **Administrator isolation:** Your namespace admins cannot access other organizations' data
- **Database-enforced:** Security is enforced at the database level, not just the application layer
- **Transparent:** You can request documentation of our security architecture for your procurement or security team
```

**Why This Section Matters:**
- Enterprise security reviews require multi-tenant explanation
- Government procurement often needs RLS confirmation
- Differentiates from "everyone can see everyone" tools
- Supports SOC2 readiness claims

---

### 4. UPDATE SECTION: Infrastructure Providers

**Current Section Likely Says:**
```markdown
We use third-party service providers to operate our platform...
```

**Update To Include:**

```markdown
## 6. Infrastructure and Service Providers

We use carefully selected third-party service providers to operate GetInSync. Each provider has been evaluated for security, privacy, and compliance with Canadian/international privacy laws.

### Core Infrastructure
- **Supabase (Database, Authentication, Storage):** Canada (ca-central-1)
  - Role: PostgreSQL database, user authentication, file storage
  - Data location: Montreal, Quebec, Canada
  - Data Processing Agreement: In place
  - Security: SOC2 Type II certified

- **Netlify / Azure Static Web Apps (Application Hosting):** Canada
  - Role: Hosts the web application frontend
  - Data location: Canada Central region
  - Data Processing Agreement: In place
  - Note: User data is NOT stored here, only application code

### Email Services
- **[Email Provider Name]:** [Location]
  - Role: Transactional emails (password resets, notifications)
  - Data shared: Email address, name, notification content only
  - Data Processing Agreement: In place

### Payment Processing
- **[Payment Processor Name]:** [Location]
  - Role: Subscription billing, payment processing
  - Data shared: Email address, billing information
  - Note: Credit card data is processed by payment processor only (we never store full card numbers)
  - PCI-DSS Compliant: Yes

### Analytics (Optional - Only if implemented)
- **[Analytics Provider]:** [Location]
  - Role: Usage analytics (anonymized)
  - Data shared: Anonymized usage patterns only
  - Personal data: NOT shared
  - Opt-out: Available in Account Settings

### Data Processing Agreements
We maintain **Data Processing Agreements (DPAs)** with all service providers who process personal information on our behalf. These agreements ensure:
- Providers only use your data to deliver services to us
- Providers maintain appropriate security measures
- Providers comply with applicable privacy laws
- Providers notify us of any data breaches
- You can request copies of our DPAs for your security review

### Subprocessor List
We maintain a current list of all subprocessors (service providers with access to customer data). You can request this list by emailing privacy@getinsync.ca.

**We notify customers 30 days in advance** if we add a new subprocessor who will have access to customer data.
```

**Why This Update Matters:**
- Enterprise buyers require subprocessor lists for vendor risk management
- Government procurement needs Canadian data residency confirmation
- GDPR/PIPEDA compliance requires DPA disclosure
- Transparency builds trust

---

### 5. UPDATE SECTION: Cookies (OAuth-Specific)

**Current Section Likely Says:**
```markdown
We use cookies to improve your experience...
```

**Update To Include OAuth Details:**

```markdown
## 7. Cookies and Similar Technologies

### Essential Cookies (Required for Operation)
These cookies are necessary for GetInSync to function. You cannot opt out of these cookies.

**Authentication Session Cookies:**
- Purpose: Keep you logged in between page refreshes
- Duration: Session (deleted when you close your browser, unless "Remember Me" is checked)
- Data stored: Encrypted session token
- Created when: You log in (email/password, Google, Microsoft, or Entra ID)

**OAuth State Management Cookies:**
When you use "Sign in with Google" or "Sign in with Microsoft":
- Purpose: Prevent Cross-Site Request Forgery (CSRF) attacks during OAuth login
- Duration: Temporary (deleted after successful login, typically <5 minutes)
- Data stored: Random state token
- Security: These cookies ensure that the response from Google/Microsoft is actually in response to YOUR login request, not a malicious third party

**Multi-Factor Authentication Cookies (if MFA enabled):**
- Purpose: Remember your device for 30 days after successful MFA verification
- Duration: 30 days
- Data stored: Encrypted device token
- Opt-out: Disable "Trust this device" during MFA setup

### Functional Cookies (Optional but Recommended)
These cookies improve your experience. You can disable these, but some features may not work as well.

**Workspace/Namespace Preference Cookies:**
- Purpose: Remember your last-used workspace so you don't have to select it every time
- Duration: 90 days
- Data stored: Workspace ID (encrypted)

**UI Preferences:**
- Purpose: Remember your dashboard layout, dark mode preference, etc.
- Duration: 1 year
- Data stored: UI settings (no personal data)

### Analytics Cookies (Optional - Only if you consent)
We do NOT use analytics cookies by default. If you opt in:
- Purpose: Understand how users interact with GetInSync to improve the product
- Provider: [Analytics Provider Name]
- Data collected: Anonymized usage patterns, feature usage
- Personal data: NOT collected
- Opt-out: Available in Account Settings

### Third-Party Cookies
**Google OAuth / Microsoft OAuth:**
When you use "Sign in with Google" or "Sign in with Microsoft", those providers may set their own cookies. We do not control these cookies. See:
- Google cookie policy: https://policies.google.com/technologies/cookies
- Microsoft cookie policy: https://privacy.microsoft.com/en-us/privacystatement

### How to Manage Cookies
**Browser Settings:**
Most browsers allow you to:
- Block all cookies
- Block third-party cookies only
- Delete existing cookies
- Get notified when a cookie is set

**Warning:** If you block essential cookies, you will not be able to log in to GetInSync.

**Account Settings:**
You can manage optional cookies (analytics, functional preferences) in:
1. Log in to GetInSync
2. Go to Account Settings > Privacy & Cookies
3. Toggle individual cookie categories on/off
```

**Why This Update Matters:**
- GDPR/PIPEDA require cookie disclosure
- OAuth providers need cookie consent explanation
- Users need to understand what cookies do during OAuth flow
- Enterprise security teams review cookie policies

---

## ADDITIONAL SECTIONS TO ADD

### 6. Add Table of Contents (Top of Document)

```markdown
## Table of Contents
1. Introduction
2. Information We Collect
3. Third-Party Authentication Services (Google, Microsoft, Entra ID)
4. Canadian Data Residency
5. Multi-Tenant Security & Data Isolation
6. Infrastructure and Service Providers
7. Cookies and Similar Technologies
8. How We Use Your Information
9. How We Share Your Information
10. Data Retention
11. Your Privacy Rights
12. Security Measures
13. International Data Transfers
14. Children's Privacy
15. Changes to This Policy
16. Contact Us
```

**Why:** Long privacy policies need navigation, improves user experience

---

### 7. Strengthen Security Language

**Add New Section:**

```markdown
## 12. Security Measures

We take the security of your data seriously and implement industry-standard security measures:

### Encryption
- **Data in Transit:** All data transmitted to/from GetInSync is encrypted using TLS 1.2 or higher (HTTPS)
- **Data at Rest:** All customer data stored in databases is encrypted at rest using AES-256 encryption
- **Password Storage:** Passwords are hashed using bcrypt with salt (we never store plain-text passwords)

### Access Controls
- **Least Privilege:** Employees have access only to the data necessary for their role
- **Background Checks:** All employees with access to production systems undergo background checks
- **Multi-Factor Authentication:** Required for all administrative access to production systems
- **Access Logging:** All access to production systems is logged and monitored

### Network Security
- **Firewalls:** Production databases are behind firewalls and not directly accessible from the internet
- **IP Whitelisting:** Administrative access restricted to known IP addresses
- **Intrusion Detection:** Automated monitoring for suspicious activity

### Application Security
- **Regular Updates:** We promptly apply security patches to all software components
- **Penetration Testing:** Annual third-party penetration testing (SOC2 requirement)
- **Code Reviews:** All code changes reviewed by at least one other developer
- **Dependency Scanning:** Automated scanning for vulnerabilities in third-party libraries

### Incident Response
- **Breach Notification:** If a data breach occurs, we will notify affected users within 72 hours (GDPR/PIPEDA requirement)
- **Incident Response Plan:** We maintain a documented incident response plan
- **Regular Drills:** Quarterly incident response drills

### SOC2 Type II Certification (In Progress)
We are pursuing SOC2 Type II certification, which includes:
- Independent third-party audit of our security controls
- Annual recertification
- Public attestation of our security practices

**Expected Completion:** Q2 2026

### Questions About Security?
Enterprise customers can request:
- Security questionnaire completion
- Architecture diagrams for security review
- Participation in your vendor risk assessment process

Contact: security@getinsync.ca
```

**Why This Matters:**
- Enterprise procurement requires security section
- Government RFPs need encryption disclosure
- Builds credibility and trust
- Supports SOC2 certification claims

---

### 8. Add Data Retention Section

**Add New Section:**

```markdown
## 10. Data Retention

### How Long We Keep Your Data

**Active Accounts:**
We retain your data for as long as your account is active and for a reasonable period afterward to allow for potential reactivation.

**Account Deletion:**
When you delete your account:
- **Application data** (applications, assessments, portfolios): Deleted within 30 days
- **User profile data**: Deleted within 30 days
- **Billing records**: Retained for 7 years (Canadian tax law requirement)
- **Audit logs**: Retained for 1 year (security/compliance requirement)

**Backup Retention:**
Deleted data may remain in encrypted backups for up to 90 days, then is permanently purged.

**Legal Holds:**
If your data is subject to a legal hold (e.g., litigation, government investigation), we will retain the relevant data until the hold is lifted, regardless of the above timelines.

### Export Your Data (Data Portability)
Before deleting your account, you can export:
- All application data (CSV/Excel format)
- All assessment results (CSV/Excel format)
- User lists and workspace assignments
- Cost data and budget information

**How to Export:**
1. Log in to GetInSync
2. Go to Account Settings > Export Data
3. Select what data to export
4. We'll email you a download link (available for 30 days)

### Inactive Accounts
If your account is inactive (no logins) for **2 years**:
1. We send an email warning of pending deletion (90 days notice)
2. If you don't log in within 90 days, we delete your account
3. Billing records retained for 7 years (tax requirement)

**Free tier accounts:** May be deleted after 1 year of inactivity (with 60 days notice)

### Third-Party Data Retention
Data shared with our service providers (Supabase, email provider, etc.) is deleted according to their retention policies, which are aligned with ours through Data Processing Agreements.
```

**Why This Matters:**
- GDPR requires data retention disclosure
- Users have right to know how long data is kept
- Government procurement needs retention clarity
- Shows data minimization principle (privacy best practice)

---

## CRITICAL PATH: OAuth-Ready Privacy Policy

### Week 1 Timeline (February 10-14, 2026)

**Monday, Feb 10 (Morning):**
- [ ] Claude drafts complete updated Privacy Policy with all sections above
- [ ] Stuart reviews draft

**Tuesday, Feb 11:**
- [ ] Stuart makes edits, finalizes content
- [ ] Legal review if possible (Joseph Gill) - Optional, can proceed without

**Wednesday, Feb 12:**
- [ ] Deploy updated Privacy Policy to https://getinsync.ca/privacy-policy/
- [ ] Verify URL works
- [ ] Archive old version for records

**Thursday, Feb 13:**
- [ ] START OAuth provider registration (Google, Microsoft)
- [ ] Use updated Privacy Policy URL in applications

**This sequence is CRITICAL:** Privacy Policy must be live BEFORE registering OAuth apps.

---

## OAUTH VERIFICATION REQUIREMENTS - GAP ANALYSIS

### Google OAuth Verification Requirements

**What Google Checks:**

1. **✅ Business Information**
   - Company name: Allstar Technologies Canada Limited (for now)
   - Website: https://getinsync.ca
   - Logo: Professional logo required
   - Support email: support@getinsync.ca

2. **✅ Legal Documents (CRITICAL)**
   - Privacy Policy URL: https://getinsync.ca/privacy-policy/
   - Terms of Service URL: https://getinsync.ca/terms/
   - Must be accessible without login
   - Must disclose what data is collected via Google OAuth
   - Must link to Google's privacy policy

3. **✅ OAuth Scopes (What data we request)**
   - email: User's email address
   - profile: User's name and profile picture
   - openid: Standard OAuth 2.0 scope
   - **NO sensitive scopes** (Gmail, Drive, Calendar) ✓ Good

4. **✅ Application Screenshots**
   - Login page with "Sign in with Google" button
   - After-login page showing user is authenticated
   - Must show how user data is used

5. **⚠ï¸ Domain Verification**
   - Verify ownership of getinsync.ca
   - Add DNS TXT record OR upload HTML file
   - **Status:** Need to do this

**Verification Timeline:**
- Submit: Friday, Feb 21, 2026
- Google review: 1-4 weeks typically
- Can use "unverified" OAuth immediately (shows warning to users)

---

### Microsoft OAuth Verification Requirements

**What Microsoft Checks:**

1. **✅ Publisher Verification**
   - Company: Allstar Technologies Canada Limited
   - Domain: getinsync.ca
   - Verification method: DNS TXT record OR HTML file

2. **✅ Application Information**
   - App name: GetInSync NextGen
   - Logo: Professional logo required
   - Privacy Policy URL: https://getinsync.ca/privacy-policy/
   - Terms of Service URL: https://getinsync.ca/terms/

3. **✅ Permissions (Scopes)**
   - User.Read: Basic profile information
   - email: User's email address
   - openid: Standard OAuth scope
   - **NO Microsoft Graph permissions** (OneDrive, Teams) ✓ Good

**Verification Timeline:**
- Submit: Friday, Feb 21, 2026
- Microsoft review: Usually 1-3 days (faster than Google)
- Can use unverified OAuth immediately

---

## Privacy Policy IS the Blocker - Here's Why

### The Dependency Chain

```
Privacy Policy Updated & Deployed
    ↓
OAuth Apps Registered (Google, Microsoft)
    ↓
OAuth UI Implemented
    ↓
Production Deployment
    ↓
Verification Submission
    ↓
(2-4 weeks wait)
    ↓
Verified OAuth ✓
```

**If Privacy Policy is NOT updated:**
- ❌ Cannot submit for verification (auto-rejected)
- ❌ "Unverified app" warning scares users away
- ❌ Enterprise buyers won't accept unverified OAuth
- ❌ Delays enterprise deals

**If Privacy Policy IS updated:**
- ✅ Can submit immediately (Friday Week 2)
- ✅ "Unverified" works while verification processes
- ✅ Enterprise buyers see we're verification-pending (acceptable)
- ✅ Clears the blocker for going live

---

## Implementation Checklist

### Phase 1: Privacy Policy Update (Mon-Wed Week 1)

**Monday Morning:**
- [ ] Claude generates complete updated Privacy Policy
- [ ] Stuart reviews for accuracy
- [ ] Delta reviews for readability

**Monday Afternoon:**
- [ ] Stuart makes edits
- [ ] Add company-specific details (email provider, payment processor)
- [ ] Choose analytics provider (or mark as "not yet implemented")

**Tuesday:**
- [ ] Optional: Joseph Gill legal review (if time allows)
- [ ] Finalize all content
- [ ] Prepare for deployment

**Wednesday:**
- [ ] Deploy to https://getinsync.ca/privacy-policy/
- [ ] Update "Last Updated" date throughout document
- [ ] Test accessibility (can view without login)
- [ ] Archive old version

### Phase 2: OAuth Provider Registration (Thu-Fri Week 1)

**Thursday:**
- [ ] Create Google Cloud Console project
- [ ] Configure OAuth consent screen
- [ ] Add Privacy Policy URL
- [ ] Add Terms URL
- [ ] Add authorized redirect URIs
- [ ] Get Client ID and Client Secret

**Friday:**
- [ ] Create Azure AD app registration
- [ ] Configure OAuth settings
- [ ] Add Privacy Policy URL
- [ ] Add redirect URIs
- [ ] Get Application ID and Client Secret

### Phase 3: Supabase Configuration (Fri Week 1)

- [ ] Add Google OAuth provider to Supabase
- [ ] Add Microsoft OAuth provider to Supabase
- [ ] Test authentication in development environment

### Phase 4: UI Implementation (Mon Week 2)

**See separate work package: planning/work-package-privacy-oauth.md**

### Phase 5: Verification Submission (Fri Week 2)

**Google:**
- [ ] Submit app for verification
- [ ] Provide all required information
- [ ] Upload screenshots
- [ ] Verify domain ownership

**Microsoft:**
- [ ] Complete publisher verification
- [ ] Verify domain ownership
- [ ] Submit application

---

## Success Criteria

### Privacy Policy
- ✅ Deployed to https://getinsync.ca/privacy-policy/
- ✅ Accessible without login
- ✅ All 8 major sections included
- ✅ Domain corrected (getinsync.ca)
- ✅ Date updated (Feb 7, 2026)
- ✅ OAuth providers disclosed
- ✅ Canadian data residency emphasized
- ✅ Multi-tenant security explained

### OAuth Registration
- ✅ Google OAuth credentials obtained
- ✅ Microsoft OAuth credentials obtained
- ✅ Configured in Supabase
- ✅ Tested in development

### Verification Submission
- ✅ Google verification submitted
- ✅ Microsoft verification submitted
- ✅ Domain ownership verified
- ✅ Can track verification status

### Risk Mitigation
- ✅ Can use "unverified" OAuth if verification delayed
- ✅ Privacy Policy blocks no other work
- ✅ Enterprise buyers see verification-pending status

---

## Dependencies

**Blocks:**
- OAuth UI implementation (needs credentials from registration)
- OAuth verification (needs deployed Privacy Policy)
- Enterprise SSO discussions (privacy policy reviewed by security teams)

**Blocked By:**
- Legal entity spinout (optional - can proceed with current entity)
- Joseph Gill review (optional - can proceed without)

**Parallel Work:**
- Website updates (can happen same time)
- Namespace UI (completely independent)

---

## Contact Information

**Privacy Questions:**
- Email: privacy@getinsync.ca
- Lead: Stuart Holtby

**Security Questions:**
- Email: security@getinsync.ca
- Lead: Stuart Holtby

**OAuth Support:**
- Google: https://support.google.com/cloud/
- Microsoft: https://docs.microsoft.com/azure/

---

## Appendix A: Privacy Policy Template Structure

```markdown
# Privacy Policy

**Effective Date:** February 7, 2026  
**Last Updated:** February 7, 2026

**Company:** Allstar Technologies Canada Limited  
**Product:** GetInSync Strategic Management  
**Website:** https://getinsync.ca  
**Contact:** privacy@getinsync.ca

---

[Table of Contents - see Section 6 above]

---

## 1. Introduction

[Standard intro about commitment to privacy]

## 2. Information We Collect

[Standard GDPR/PIPEDA disclosure]

## 3. Third-Party Authentication Services

[See Section 1 above - CRITICAL]

## 4. Canadian Data Residency

[See Section 2 above]

## 5. Multi-Tenant Security & Data Isolation

[See Section 3 above]

## 6. Infrastructure and Service Providers

[See Section 4 above]

## 7. Cookies and Similar Technologies

[See Section 5 above]

## 8. How We Use Your Information

[Standard usage disclosure]

## 9. How We Share Your Information

[Standard sharing disclosure - emphasize we DON'T sell data]

## 10. Data Retention

[See Section 8 above]

## 11. Your Privacy Rights

[GDPR/PIPEDA rights: access, correct, delete, export, complain]

## 12. Security Measures

[See Section 7 above]

## 13. International Data Transfers

[Explain multi-region options, data stays in chosen region]

## 14. Children's Privacy

[Standard "not intended for children under 13" section]

## 15. Changes to This Policy

[Standard "we'll notify you of material changes" section]

## 16. Contact Us

**Privacy Officer:** Stuart Holtby  
**Email:** privacy@getinsync.ca  
**Mail:** [Company address]  
**Phone:** [Support number]

For privacy complaints or concerns, you may also contact:
- **Canadian residents:** Office of the Privacy Commissioner of Canada (https://www.priv.gc.ca/)
- **EU residents:** Your local data protection authority
```

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-02-07 | Initial work package created from Q1 2026 planning session |

---

*Document: planning/work-package-privacy-oauth.md*  
*February 2026*
