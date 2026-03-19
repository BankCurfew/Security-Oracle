# FA Tools — Security Verification Round 2

**Date**: 2026-03-19
**Repo**: BankCurfew/iagencyaiafatools
**Fix Commit**: 08be39aa "security: fix 15 CRITICAL vulnerabilities — full audit remediation"
**Auditor**: Security-Oracle

---

## CRITICAL Items (4)

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| C1 | insurance-chat unauth access | ✅ PASS | Bearer JWT auth check added |
| C2 | jspdf XSS via innerHTML | ✅ PASS | Upgraded to v4.2.1 (CVE patched) |
| C3 | parse-fund-peer-avg unauth DB write | ❌ FAIL | No auth check — anyone can write to DB |
| C4 | Supabase anon key in git history | ✅ PASS* | .env removed from git; key rotation needed on Supabase dashboard |

## HIGH Items (9)

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| H1 | fetch-fund-factsheet no auth | ❌ FAIL | No Bearer token validation |
| H2 | is_approved client-only | ✅ PASS | Enforced at API gateway + RLS |
| H3 | Hardcoded name in 8 files | ❌ FAIL | อาทิตย์ สกุลเสาวภาคย์กุล + license 5701055268 still hardcoded |
| H4 | xlsx CVE | ✅ PASS | Updated to patched version |
| H5 | CORS wildcard | ⚠️ PARTIAL | api-gateway fixed; 10 other Edge Functions still `*` |
| H6 | Password min 6 chars | ❌ FAIL | Still `< 6` in SignUpForm + FAProfileEditor |
| H7 | No CSP headers | ❌ FAIL | No CSP configuration |
| H8 | No rate limiting | ⚠️ PARTIAL | insurance-chat + submit-lead have it; others don't |
| H9 | Sensitive data in console.log | ✅ PASS | No sensitive logging found |

## Additional Fixes Verified

| Finding | Status |
|---------|--------|
| Encryption fallback | ✅ PASS — throws error instead of fallback |
| Ownership checks (proposals/apps/portfolio) | ✅ PASS — FA-scoped queries |
| UnitLink corridor factor hardcode | ✅ PASS — now parameterized |
| Tax bracket boundary gap | ✅ PASS — corrected |
| SQL injection via .or() | ✅ PASS — pattern removed |

---

## Scorecard

| Severity | Pass | Fail | Partial |
|----------|------|------|---------|
| CRITICAL | 3 | 1 | 0 |
| HIGH | 3 | 4 | 2 |
| **Total** | **6** | **5** | **2** |

## Result: ❌ CONDITIONAL FAIL

### Must Fix (Blockers)

1. **`parse-fund-peer-avg`** — Add Bearer auth. Unauthenticated DB writes = CRITICAL.
2. **`fetch-fund-factsheet`** — Add Bearer auth. Public PDF endpoint = HIGH.
3. **Password minimum** — Change from 6 → 12 in SignUpForm.tsx + FAProfileEditor.tsx.

### Should Fix (Next Sprint)

4. Hardcoded name → make configurable via admin settings
5. CORS restrict on remaining 10 Edge Functions
6. CSP headers in production config
7. Rate limiting on all public endpoints

### แบงค์ Action Required

- Rotate Supabase anon key for project `rugcuukelivcferjjzek`
