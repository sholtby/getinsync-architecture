# Secure Coding Standards — GetInSync NextGen

Version: 1.0
Last updated: 2026-03-10
Status: 🟢 AS-BUILT
SOC 2 Alignment: CC6.1, CC6.3, CC6.7, CC7.1, CC7.2

---

## 1. Purpose & Scope

This document defines secure coding standards for GetInSync NextGen, adapted from OWASP Top 10 and SOC 2 Trust Service Criteria for our specific stack.

**In scope:** React + TypeScript + Vite + Tailwind frontend, Supabase backend (PostgreSQL, Edge Functions).
**Out of scope:** Infrastructure-as-code, container orchestration, backend workers, cron jobs. Supabase manages infrastructure security.

---

## 2. Security Architecture — RLS-First Model

GetInSync enforces security at the **database layer**, not the application layer. This is the single most important architectural decision for SOC 2.

- **357+ RLS policies** across 92+ tables enforce all data access — a frontend bug **cannot** expose another tenant's data
- **Frontend role checks** (`isNamespaceAdmin`, `isWorkspaceAdmin`) are UI convenience only, not security controls
- **Audit triggers** (51) on critical tables log all mutations — cannot be bypassed by application code
- **All views** use `security_invoker = true` — RLS enforced through views, not just tables

**Cross-references:**
- RLS policy architecture: `identity-security/rls-policy.md`
- Security posture: `identity-security/security-posture-overview.md`
- Three-layer model: Database isolation → Audit trail → Automated validation

---

## 3. Authentication & Session Management

Supabase Auth is the **only** authentication provider. No custom auth flows.

**MUST:**
- Use the singleton client in `src/lib/supabase.ts` for all Supabase operations
- Use `AuthContext` for all auth state — never call `supabase.auth.*` directly from components
- Use `supabase.auth.getSession()` to check auth status
- Let Supabase SDK manage token refresh (`autoRefreshToken: true`)

**MUST NOT:**
- Store tokens in custom localStorage keys (Supabase SDK manages this)
- Pass tokens in URL query parameters
- Create custom auth flows or token validation logic
- Log tokens, session IDs, or invitation codes to console

**Gap:** MFA not yet enforced (Supabase supports it). Target: before first enterprise deal.

**Cross-reference:** `identity-security/identity-security.md`

---

## 4. Input Validation & XSS Prevention

### 4.1 Frontend Inputs
- Validate all user inputs before passing to Supabase (required fields, format, length)
- Numeric inputs: `parseInt`/`parseFloat` with NaN guard
- UUID inputs: validate format before passing to `.eq()` / `.in()` queries
- String inputs: `.trim()`, enforce max length where applicable

### 4.2 XSS Prevention
- React auto-escapes JSX expressions — this is the primary defense
- **NEVER** use `dangerouslySetInnerHTML`
- **NEVER** use `eval()`, `new Function()`, or dynamic script injection
- Sanitize data from external APIs (endoflife.date, etc.) before rendering
- Validate URL protocols in `href`/`src` attributes (allow `https://` only)

### 4.3 SQL Injection
- **Not applicable** for standard queries — Supabase SDK parameterizes all `.eq()`, `.in()`, `.ilike()` calls
- **NEVER** construct raw SQL strings client-side
- RPC calls use parameterized arguments — verify parameter types match function signatures

---

## 5. Error Handling & Logging

### 5.1 Error Handling Pattern

Pattern: `try { const { data, error } = await supabase...; if (error) throw error; } catch (err) { toast.error('User message'); console.error('Context:', err); }`

**Rules:**
- Wrap **ALL** Supabase calls in try/catch
- Show toast notifications on error — **NEVER** use `alert()` or `confirm()`
- Show generic user-facing messages; log specifics to `console.error` only
- Revert UI state on mutation failure (e.g., restore previous dropdown selection)
- Disable buttons during mutations to prevent double-submission
- Use `ErrorBoundary` around feature sections, not just at App root

### 5.2 Logging Rules
- **NEVER** log: tokens, passwords, invitation codes, PII, namespace/user IDs in production
- `console.log` is for development only — ESLint `no-console` warns
- `console.error` for genuine errors only — include context but not sensitive data
- **Gap:** No centralized error tracking (Sentry/LogRocket). Target: before enterprise.

---

## 6. Secrets Management

- Only two frontend env vars: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- Both are **public-safe** by design — the anon key is scoped by RLS
- `.env` is in `.gitignore` (verified)
- `DATABASE_READONLY_URL` is development-only — never used in application code
- **NEVER** commit `.env` or any file containing connection strings
- **NEVER** hardcode credentials, API keys, or connection strings in source
- **NEVER** include secrets in error messages, logs, or URL parameters

---

## 7. Data Protection

- **At rest:** AES-256 encryption (Supabase managed, ca-central-1 region)
- **In transit:** TLS 1.2+ (Netlify HTTPS + Supabase SSL)
- **Namespace isolation:** Enforced at database level via `get_current_namespace_id()` — cannot be bypassed
- **localStorage:** Only Supabase auth session + UI preferences (namespace/workspace/portfolio selection)
- **NEVER** store sensitive data in localStorage beyond what Supabase SDK manages
- **NEVER** include PII or sensitive data in URL parameters

**Cross-reference:** `identity-security/rls-policy.md`, `planning/work-package-multi-region.md`

---

## 8. Dependency Security

- npm manages frontend dependencies via `package.json`
- **Gap:** GitHub Dependabot configured but no automated CI scanning
- **Gap:** No `npm audit` in CI pipeline
- Review new dependencies for maintenance status before adoption
- **NEVER** install packages with known critical CVEs without justification

---

## 9. Red Flag Checklist

Anti-patterns to catch during code review. Run these grep commands before committing:

| Red Flag | Severity | Detection | Current |
|----------|----------|-----------|---------|
| `dangerouslySetInnerHTML` | CRITICAL | `grep -rn "dangerouslySetInnerHTML" src/` | 0 |
| `eval()` / `new Function()` | CRITICAL | `grep -rn "eval(\|new Function" src/` | 0 |
| Hardcoded dropdown values | HIGH | Code review (CLAUDE.md rule) | Enforced |
| Missing try/catch on Supabase calls | HIGH | Manual review | Widespread |
| `alert()` / `confirm()` | MEDIUM | ESLint `no-alert` | ~22 |
| `console.log` in production | MEDIUM | ESLint `no-console` | ~33 |
| Sensitive data in console.log | CRITICAL | Manual review | Review needed |
| `.env` committed to git | CRITICAL | `.gitignore` | Protected |
| `any` type in new code | LOW | ESLint `no-explicit-any` | ~239 legacy |

### Pre-Commit Security Scan
```bash
# Check for critical anti-patterns
grep -rn "dangerouslySetInnerHTML\|eval(" src/ --include="*.ts" --include="*.tsx"
grep -rn "password\|secret\|token" src/ --include="*.ts" --include="*.tsx" | grep -v ".d.ts" | grep -v "import.meta.env" | grep -v "node_modules"
```

---

## 10. SOC 2 Compliance Mapping

| SOC 2 Criteria | Sections | Evidence Document |
|----------------|----------|-------------------|
| CC6.1 Logical Access | 2, 3, 7 | `identity-security/rls-policy.md` |
| CC6.3 API Auth | 3, 4.3 | `identity-security/identity-security.md` |
| CC6.6 Audit Logging | 5 | `identity-security/soc2-evidence-index.md` |
| CC6.7 Vulnerability Mgmt | 8 | (gap — Dependabot CI needed) |
| CC7.1 Change Management | 9 | `operations/session-end-checklist.md` |
| CC7.2 Monitoring | 5.2 | (gap — Sentry/LogRocket needed) |

---

## 11. Gap Summary & Priority Roadmap

| # | Gap | Severity | Effort | SOC 2 |
|---|-----|----------|--------|-------|
| 1 | No CI checks on PRs (tsc, lint, build) | HIGH | 2 hrs | CC7.1 |
| 2 | No error tracking service (Sentry) | HIGH | 2 hrs | CC7.2 |
| 3 | No PR template with security checklist | MEDIUM | 30 min | CC7.1 |
| 4 | Eliminate `alert()` calls (~22) | MEDIUM | 2 hrs | CC6.1 |
| 5 | Add try/catch to all Supabase calls | MEDIUM | 4 hrs | CC7.1 |
| 6 | Add CSP / security headers (Netlify `_headers`) | MEDIUM | 1 hr | CC6.3 |
| 7 | Enable MFA enforcement | MEDIUM | 1 hr | CC6.1 |
| 8 | Reduce console.log to zero (~33) | LOW | 2 hrs | CC6.6 |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-10 | Initial version. Adapted from OWASP + SOC 2 Enterprise Secure Coding skill for React + Supabase stack. RLS-first model documented. Red flag checklist with current violation counts. 8-item gap roadmap. |

---

*Document: operations/secure-coding-standards.md*
*SOC 2 Controls: CC6.1, CC6.3, CC6.7, CC7.1, CC7.2*
*March 2026*
