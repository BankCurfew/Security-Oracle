# FA Tools (iAgencyAIA) — Baseline Security Audit

**Date**: 2026-03-19 16:00 GMT+7
**Auditor**: Security-Oracle
**Repo**: ~/repos/github.com/BankCurfew/iagencyaiafatools/
**Stack**: React + Vite + Tailwind + Supabase (645 files)
**Supabase Project**: `rugcuukelivcferjjzek`
**Thread**: #44

---

## Executive Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 4 |
| 🟠 HIGH | 9 |
| 🟡 MEDIUM | 8 |
| 🟢 LOW | 4 |

**Verdict**: ❌ **NOT READY** — 4 CRITICAL + 9 HIGH. FE assigned to fix 13 items. Awaiting push.

---

## 🔴 CRITICAL Findings

### C1 — .env with Live Supabase Credentials in Git History
- **Commit**: `40d53bcb` (2025-11-15, gpt-engineer-app[bot])
- **Exposed**: `VITE_SUPABASE_PUBLISHABLE_KEY` (anon JWT), `VITE_SUPABASE_URL`, `VITE_SUPABASE_PROJECT_ID`
- **Status**: .env removed from HEAD, in .gitignore now, but **permanently in git history**

### C2 — Supabase Anon Key Hardcoded in Migration SQL
- **File**: `supabase/migrations/20251221153252_*.sql:83`
- **Value**: Full Bearer JWT token hardcoded in SQL
- **Action**: Rotate anon key via Supabase Dashboard

### C3 — jspdf CRITICAL Vulnerabilities (CVSS 9.6)
- Path Traversal (CWE-22) + HTML Injection XSS
- Used to generate PDFs with customer PII (health data, ID numbers, bank accounts)
- **Action**: Upgrade jspdf to >=4.2.1

### C4 — `generate-reminders` Edge Function Completely Unauthenticated
- `verify_jwt = false`, no Bearer check, uses `service_role` key
- Anyone can trigger mass notification creation for ALL FAs
- **Action**: Add auth check

---

## 🟠 HIGH Findings

| # | Finding |
|---|---------|
| H1 | 13/16 Edge Functions have `verify_jwt = false` |
| H2 | `insurance-chat` uses `service_role` with no JWT verification — unauthenticated AI cost drain |
| H3 | `is_approved` flag not enforced at RLS/API level — unapproved FAs get full access |
| H4 | Real person name + license number hardcoded in 8 files (`นาย อาทิตย์ สกุลเสาวภาคย์กุล`) |
| H5 | react-router XSS via Open Redirect (CVSS 8.0) |
| H6 | xlsx Prototype Pollution (CVSS 7.8) |
| H7 | serialize-javascript RCE (CVSS 8.1) |
| H8 | Supabase anon key bundled into frontend JS (architectural — RLS must be airtight) |
| H9 | npm audit: 2 CRITICAL + 13 HIGH + 6 MODERATE vulnerabilities |

---

## 🟡 MEDIUM Findings

| # | Finding |
|---|---------|
| M1 | CORS `*` wildcard on all Edge Functions except api-gateway |
| M2 | Password minimum 6 chars (should be 12+) |
| M3 | Multiple routes without ProtectedRoute (Dashboard, Profile, etc.) |
| M4 | `Customers can update applications` RLS policy doesn't verify token value |
| M5 | Privacy policy URL typo: `privacys-policy` → `privacy-policy` |
| M6 | In-memory rate limiter resets on cold start |
| M7 | Health data collection (PDPA Section 26) — verify explicit consent implementation |
| M8 | `fetch-aia-funds` and `fetch-fund-factsheet` — no auth at all |

---

## ✅ Positive Findings

1. **AES-256-GCM encryption** for PII fields (national_id, health data, bank accounts) ✅
2. **API key hashing** (SHA-256, show once only) correctly implemented ✅
3. **RLS enabled on ALL 67 tables** — zero unprotected tables ✅
4. **No service_role key in frontend** — correctly uses anon key only ✅
5. **api-gateway** has proper CORS + dual auth (X-API-Key + Bearer) ✅
6. **admin_audit_log** is immutable (no UPDATE/DELETE policies) ✅
7. **No real customer PII in source code** — only placeholder data ✅

---

## 13 CRITICAL Items Assigned to FE for Fix

| # | Item | Verify Method |
|---|------|---------------|
| 1 | .env removal from git history | `git log --all -p -S "SUPABASE" | grep eyJ` |
| 2 | Encryption no plaintext fallback | Read encryption-utils.ts catch blocks |
| 3 | API ownership checks | Check service_role usage patterns |
| 4 | 7 Edge Functions auth added | Read each function for Bearer/JWT check |
| 5 | CORS restricted | Check `Access-Control-Allow-Origin` in functions |
| 6 | generate-reminders auth | Read function for auth check |
| 7 | insurance-chat auth | Read function for auth check |
| 8 | is_approved enforcement | Check RLS policies or API gateway |
| 9 | jspdf upgrade | Check package.json version |
| 10 | react-router upgrade | Check package.json version |
| 11 | Privacy policy URL fix | Check ApplicationFormStep1.tsx |
| 12 | Password min length increase | Check SignUpForm.tsx |
| 13 | Hardcoded name removal | Search for อาทิตย์ สกุลเสาวภาคย์กุล |

**Status**: FE reports fixes complete. Awaiting push to GitHub for verification.

---

> "Almost secure is not secure. Especially when health data and financial records are at stake."
> *Security-Oracle — FA Tools Baseline Audit*
