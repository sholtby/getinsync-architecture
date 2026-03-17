# identity-security/secrets-inventory.md
GetInSync NextGen — Secrets Inventory
Version: 1.0
Date: 2026-03-13
Status: 🟢 AS-BUILT
SOC2 Controls: CC6.1, CC6.3, CC6.6

---

## Purpose

This document inventories all secrets (API keys, service credentials) used by the GetInSync NextGen platform. It records metadata only — **never actual key values**. This supports SOC2 CC6.1 (logical access), CC6.3 (API authentication), and CC6.6 (credential management) evidence requirements.

---

## Secrets Storage Location

All secrets are stored in **Supabase Edge Function Secrets** (encrypted at rest, managed via `supabase secrets set`). They are accessible only by Edge Functions running on the Supabase Deno runtime.

**Access method:** `Deno.env.get('SECRET_NAME')` within Edge Functions
**Management CLI:** `supabase secrets set`, `supabase secrets list`, `supabase secrets unset`
**Who can manage:** Stuart Holtby (project owner, Supabase dashboard access)

---

## Secrets Inventory

| # | Secret Name | Purpose | Consumer(s) | Owner | Created | Rotation Schedule | Classification |
|---|-------------|---------|-------------|-------|---------|-------------------|----------------|
| 1 | `SUPABASE_URL` | Supabase project URL for API calls | All Edge Functions | Stuart Holtby | Project creation | On project migration only | Internal |
| 2 | `SUPABASE_ANON_KEY` | Public anonymous key for unauthenticated Supabase access | All Edge Functions | Stuart Holtby | Project creation | On JWT secret rotation | Internal |
| 3 | `SUPABASE_SERVICE_ROLE_KEY` | Privileged key — bypasses RLS for admin operations | Edge Functions requiring elevated access | Stuart Holtby | Project creation | On JWT secret rotation | Confidential |
| 4 | `SUPABASE_DB_URL` | Direct PostgreSQL connection string | Edge Functions requiring direct DB access | Stuart Holtby | Project creation | On password rotation | Confidential |
| 5 | `ANTHROPIC_API_KEY` | Claude API access for AI-powered features | `lifecycle-lookup`, `apm-chat`, `ai-generate` Edge Functions | Stuart Holtby | 2026-03-13 | Every 90 days | Confidential |
| 6 | `OPENAI_API_KEY` | OpenAI Embeddings API (`text-embedding-3-small`) | `embed-entity`, `apm-chat` Edge Functions | Stuart Holtby (Service Account) | 2026-03-13 | Every 90 days | Confidential |

---

## Classification Levels

| Level | Definition | Handling |
|-------|-----------|----------|
| **Internal** | Non-sensitive infrastructure identifiers. Exposure is low risk. | Store in secrets manager. No special rotation urgency. |
| **Confidential** | Grants privileged access to data or external services. Exposure = security incident. | Store in secrets manager. Rotate every 90 days. Monitor for unauthorized use. |

---

## Rotation Procedure

### For Supabase Keys (SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY)
1. Rotate JWT secret in Supabase Dashboard → Settings → API
2. Copy new anon and service_role keys
3. Run: `supabase secrets set SUPABASE_ANON_KEY=new_value SUPABASE_SERVICE_ROLE_KEY=new_value`
4. Redeploy all Edge Functions: `supabase functions deploy`
5. Update Netlify environment variables (frontend uses anon key)
6. Verify: smoke test application login + Edge Function calls
7. Log rotation in this document (Rotation Log below)

### For Third-Party API Keys (ANTHROPIC_API_KEY, OPENAI_API_KEY)
1. Generate new key in provider dashboard (Anthropic Console / OpenAI Platform)
2. Run: `supabase secrets set KEY_NAME=new_value`
3. Verify: trigger the consuming Edge Function and check logs
4. Revoke the old key in provider dashboard
5. Log rotation in this document (Rotation Log below)

### For Database URL (SUPABASE_DB_URL)
1. Reset database password in Supabase Dashboard → Settings → Database
2. Update connection string: `supabase secrets set SUPABASE_DB_URL=new_value`
3. Redeploy affected Edge Functions
4. Verify: Edge Function DB queries succeed
5. Log rotation in this document (Rotation Log below)

---

## Rotation Log

| Date | Secret | Action | Performed By | Verified |
|------|--------|--------|-------------|----------|
| 2026-03-13 | `OPENAI_API_KEY` | Initial creation (Service Account) | Stuart Holtby | `supabase secrets list` confirmed |
| 2026-02-xx | `ANTHROPIC_API_KEY` | Initial creation | Stuart Holtby | `lifecycle-lookup` function tested |

---

## Monitoring & Alerts

| Check | Frequency | Method |
|-------|-----------|--------|
| Verify all secrets are set | Monthly (with SOC2 evidence collection) | `supabase secrets list` — compare against this inventory |
| Review API key usage | Monthly | Check Anthropic Console + OpenAI Platform usage dashboards |
| Check for leaked keys | On commit | GitHub secret scanning (enabled by default on public repos) |
| Rotation compliance | Quarterly (with access review) | Compare Rotation Log dates against 90-day schedule |

---

## SOC2 Evidence Queries

```bash
# List all configured secrets (shows names + digest, never values)
supabase secrets list

# Verify count matches this inventory (expect 6)
supabase secrets list | grep -c "|"
```

---

## Related Documents

| Document | Purpose |
|----------|---------|
| `identity-security/soc2-evidence-index.md` | Maps trust criteria to evidence sources |
| `identity-security/soc2-evidence-collection.md` | Monthly evidence collection procedure |
| `identity-security/identity-security.md` | Identity/security architecture |
| `infrastructure/edge-functions-layer-architecture.md` | Edge Functions that consume these secrets |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-13 | Initial secrets inventory. 6 secrets documented. Rotation procedures defined. OPENAI_API_KEY added for Phase 2 AI Chat embeddings. |

---

*Document: identity-security/secrets-inventory.md*
*SOC2 Controls: CC6.1, CC6.3, CC6.6*
*March 2026*
