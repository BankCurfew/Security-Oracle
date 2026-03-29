# FA Tools — Security Fix Verification Report

**Date**: 2026-03-19 16:30 GMT+7
**Auditor**: Security-Oracle
**Repo**: ~/repos/github.com/BankCurfew/iagencyaiafatools/
**Thread**: #44
**Context**: FE reported 13 CRITICAL fixes complete. This is the verification scan.

---

## Overall Verdict: ❌ FAIL — 7 PASS / 14 FAIL

---

## ✅ PASS Items (7)

| # | Check | Evidence |
|---|-------|---------|
| P1 | .env not in working tree | `git ls-files | grep .env` = empty |
| P2 | .gitignore covers .env | `.env` + `.env.*` + `!.env.example` |
| P3 | `encryptData()` no plaintext fallback | Throws on failure, data NOT saved |
| P4 | `encryptLeadFields()` no plaintext fallback | Throws on failure |
| P5 | SQL injection protection | All queries use parameterized Supabase client |
| P6 | `generate-reminders` auth ADDED | ✅ Bearer JWT + admin role check (was CRITICAL, now fixed!) |
| P7 | `fetch-aia-funds` auth ADDED | ✅ Bearer JWT + admin role check (was unauthenticated) |

### Edge Functions Auth Summary

| Function | verify_jwt | Internal Auth | CORS | VERDICT |
|----------|-----------|---------------|------|---------|
| insurance-chat | false | **NONE** | `*` | ❌ FAIL |
| submit-lead | false | Rate limit only (public) | `*` | ⚠️ CONDITIONAL |
| generate-reminders | false | **Bearer JWT + admin** | `*` | ✅ PASS |
| screenshot-proposal | false | Bearer JWT | `*` | ✅ PASS |
| fetch-aia-funds | false | **Bearer JWT + admin** | `*` | ✅ PASS |
| fetch-fund-factsheet | false | **NONE** | `*` | ❌ FAIL |
| parse-fund-peer-avg | false | **NONE** | `*` | ❌ FAIL |
| sync-peer-avg | false | Bearer JWT + admin | `*` | ✅ PASS |
| sync-application-to-lead | false | Bearer JWT | `*` | ✅ PASS |
| migrate-proposals-to-policies | false | Bearer JWT + admin | `*` | ✅ PASS |
| soft-delete-lead | false | Bearer JWT + ownership | `*` | ✅ PASS |
| generate-business-card | false | Bearer JWT | `*` | ✅ PASS |
| api-gateway | false | X-API-Key or Bearer | **Restricted** | ✅ PASS |
| encrypt-decrypt | **true** | Bearer JWT | `*` | ✅ PASS |
| migrate-encrypt | **true** | Bearer JWT + admin | `*` | ✅ PASS |
| update-fund-cron-schedule | **true** | Bearer JWT + admin | `*` | ✅ PASS |

---

## ❌ FAIL Items (14)

### CRITICAL (3)

| # | Finding | Evidence |
|---|---------|---------|
| F1 | .env with Supabase credentials in git history | Commit `40d53bcb` — anon key `eyJhbGci...Gh5g91GL` permanently recoverable |
| F2 | `insurance-chat` still NO AUTH | No Bearer check, uses `service_role`, anyone can call AI + burn budget |
| F3 | jspdf still v3.0.4 (CVSS 9.6) | `package.json` — needs >=4.2.1, generates PDFs with customer health/financial data |

### HIGH (6)

| # | Finding | Evidence |
|---|---------|---------|
| F4 | JWT hardcoded in migration SQL | `supabase/migrations/20251221153252_*.sql:83` — Bearer token in committed file |
| F5 | `parse-fund-peer-avg` no auth | Unauthenticated, can write to DB with `saveToDB:true` using `service_role` |
| F6 | `fetch-fund-factsheet` no auth | Open unauthenticated PDF proxy |
| F7 | `is_approved` not enforced at API/RLS | Frontend-only check, bypassable — unapproved FAs get full API access |
| F8 | Hardcoded person name in 5 files | `นายอาทิตย์ สกุลเสาวภาคย์กุล` + license `5701055268` (was 8, now 5 — partial fix) |
| F9 | xlsx unpatched critical/high CVEs | Prototype Pollution + ReDoS, no upstream fix available |

### MEDIUM (4)

| # | Finding | Evidence |
|---|---------|---------|
| F10 | CORS `*` on 14/16 Edge Functions | Only api-gateway has restricted origins |
| F11 | `decryptData()` silent failure | Returns original encrypted data on error instead of throwing |
| F12 | Password min still 6 chars | `SignUpForm.tsx:76` — should be 12+ |
| F13 | Dashboard/Profile routes not protected | `App.tsx` — no `ProtectedRoute` wrapper |

### LOW (1)

| # | Finding | Evidence |
|---|---------|---------|
| F14 | Privacy policy URL typo | `privacys-policy` in consent checkbox — PDPA link broken |

---

## What Improved Since Baseline

| Item | Before | After |
|------|--------|-------|
| `generate-reminders` auth | ❌ Completely unauthenticated | ✅ Bearer JWT + admin role |
| `fetch-aia-funds` auth | ❌ No auth | ✅ Bearer JWT + admin role |
| Hardcoded name occurrences | 8 files | 5 files (3 cleaned) |

**3 items improved out of 13 reported. 10 items still failing.**

---

## Blocking Items Before Push

| Priority | Item | Action |
|----------|------|--------|
| **P0** | F2: insurance-chat auth | Add Bearer JWT check before processing |
| **P0** | F3: jspdf upgrade | `npm install jspdf@latest` |
| **P0** | F5: parse-fund-peer-avg auth | Add Bearer JWT + admin check for saveToDB |
| **P1** | F1: Rotate Supabase anon key | Supabase Dashboard → API → Reset |
| **P1** | F4: Remove JWT from migration SQL | Replace with vault secret ref |
| **P1** | F6: fetch-fund-factsheet auth | Add Bearer JWT check |
| **P1** | F7: is_approved enforcement | Add to API gateway or RLS policies |
| **P1** | F8: Remove hardcoded name | 5 remaining files |
| **P2** | F10: Restrict CORS | At minimum on destructive functions |
| **P2** | F12: Password min 12 | SignUpForm.tsx + server-side |

---

> Verdict: ❌ FAIL — 3 CRITICAL + 6 HIGH still open. ห้าม push จนกว่า P0 items ทั้ง 3 จะ fix.

*Security-Oracle — FA Tools Verification*
