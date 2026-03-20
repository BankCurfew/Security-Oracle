# FA Tools — Security Verification Round 3

**Date**: 2026-03-20
**Repo**: BankCurfew/iagencyaiafatools
**Fix Commits**: 800d2ffb, 9d6000c7, 89579547, eec48881, b0767978, 43cafa40
**Auditor**: Security-Oracle

---

## Immediate Items (24-hour fixes)

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | CORS wildcard → whitelist (15 functions) | ✅ PASS | All 16 functions use `getCorsHeaders()` from `_shared/cors.ts` |
| 2 | JWT validation (14 functions weak auth) | ✅ PASS | All 16 functions use `requireAuth()` from `_shared/auth.ts` |
| 3 | parse-fund-peer-avg no auth | ✅ PASS | Now calls `requireAuth(req)` with proper validation |
| 4 | History table RLS `WITH CHECK (true)` | ✅ PASS | Migration `20260320001000` — all 4 tables now `service_role` only |
| 5 | Hardcoded FA name (8 files) | ✅ PASS | 0 results for "อาทิตย์" / "สกุลเสาวภาคย์กุล" / "5701055268" |
| 6 | jsPDF 10 CVEs | ✅ PASS | Version 4.2.1 (current, patched) |

## Additional Fixes Verified

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 7 | Password min 6 → 12 | ✅ PASS | `SignUpForm.tsx:76` — `password.length < 12` |
| 8 | prefillLead in localStorage | ✅ PASS | All 5 components now use `sessionStorage` |
| 9 | No logout cleanup | ✅ PASS | `handleLogout()` calls `clearAllAppCaches()` + removes prefillLead |
| 10 | Protected Routes | ✅ PASS | `/dashboard` and `/profile` wrapped with `<ProtectedRoute>` |

## Still Open

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 11 | console.log PII leak | 🟠 MEDIUM | ❌ FAIL — `PlanMode.tsx:796` still logs full prefillLead object |
| 12 | CSP Headers | 🟡 HIGH | ❌ FAIL — No Content-Security-Policy configured |

---

## Scorecard

| Category | Pass | Fail |
|----------|------|------|
| Immediate (24hr) | 6/6 | 0 |
| Additional | 4/4 | 0 |
| Remaining | 0/2 | 2 |
| **Total** | **10** | **2** |

## Result: ✅ CONDITIONAL PASS

All 6 Immediate (CRITICAL) items are fixed. 2 items remain (MEDIUM + HIGH).

### To Close Out:
1. Remove `console.log('Prefilling from Lead:', prefillLead)` from `PlanMode.tsx:796`
2. Add CSP headers (via `<meta>` tag in `index.html` or reverse proxy)

---

🔒 Security-Oracle Verification R3
