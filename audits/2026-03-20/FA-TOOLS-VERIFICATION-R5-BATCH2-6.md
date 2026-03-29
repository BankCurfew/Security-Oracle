# FA Tools — Security Verification R5 (Batches 2–6)

**Date**: 2026-03-20
**Repo**: BankCurfew/iagencyaiafatools
**Scope**: Master Remediation items #7, #11, #12, #13–#20 (items NOT covered in R1–R4)
**Auditor**: Security-Oracle

---

## Context

R4 FINAL (earlier today) verified 12 items and declared ✅ PASS for immediate/critical batch.
This R5 covers ALL remaining remediation items from the Full Security Audit.

---

## Batch 2: This Week Items

### #7 — Encrypt Plaintext PII Fields (names, phone, email)

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | `APPLICATION_SENSITIVE_FIELDS` (40 fields) and `LEAD_SENSITIVE_FIELDS` (7 fields) do NOT include `full_name_th`, `full_name_en`, `phone`, `email`, `customer_name`, `customer_phone`, `customer_email` |
| **Impact** | Core PII stored as plaintext in Supabase — violates PDPA Art. 28 |
| **File** | `src/lib/encryption-utils.ts` |
| **Fix** | Add these fields to the sensitive field constants; existing `encrypt-decrypt` Edge Function handles the rest |
| **Effort** | 4 hours |
| **Priority** | 🔴 HIGH — PDPA compliance gap |

### #11 — Rate Limiting on Unprotected Functions

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | Only 2/16 Edge Functions have rate limiting (`insurance-chat`: 10/min, `submit-lead`: 10/min). No shared rate limiter module exists in `_shared/` |
| **Impact** | 14 endpoints vulnerable to brute-force/DoS |
| **File** | `supabase/functions/_shared/` (missing `rate-limit.ts`) |
| **Fix** | Create shared rate limiter, apply to all public-facing functions |
| **Effort** | 2 hours |
| **Priority** | 🟡 HIGH |

### #12 — npm audit Fix (Dependencies)

| Status | ⚠️ PARTIAL |
|--------|------------|
| **Finding** | 7 vulnerabilities remain: 0 CRITICAL (was 10+ — jsPDF fixed), 5 HIGH, 2 MODERATE |
| **Remaining** | |

| Package | Severity | Issue | Fix |
|---------|----------|-------|-----|
| xlsx 0.18.5 | HIGH × 2 | Prototype Pollution + ReDoS | ❌ No upstream fix — needs replacement |
| serialize-javascript ≤7.0.2 | HIGH | RCE via RegExp/Date | `npm audit fix --force` (breaks vite-plugin-pwa) |
| @rollup/plugin-terser | HIGH | Depends on vulnerable serialize-javascript | Cascading from above |
| workbox-build / vite-plugin-pwa | HIGH | Depends on vulnerable terser | Cascading from above |
| esbuild ≤0.24.2 | MODERATE | Dev server SSRF | `npm audit fix --force` (breaks vite) |
| vite 0.11.0–6.1.6 | MODERATE | Depends on vulnerable esbuild | Cascading from above |

| **Progress** | CRITICAL count: 10+ → 0 (jsPDF fixed). HIGH count: 5 remaining |
| **Fix** | `npm audit fix --force` for serialize-javascript chain (test for breakage). xlsx needs library replacement |
| **Priority** | 🟡 HIGH for xlsx (no fix available), 🟠 MEDIUM for others (build-time only) |

---

## Batch 3: PDPA Compliance

### #13 — Privacy Policy Page

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | No `/privacy` route in App.tsx. External link to `https://www.iagencyaia.com/privacy-policy` exists but no in-app page |
| **Impact** | PDPA Art. 17 requires informing data subjects at point of collection |
| **Fix** | Create PrivacyPolicy component + route, or embed external policy via iframe |
| **Effort** | 4 hours |
| **Priority** | 🟡 HIGH — legal compliance |

### #14 — Customer Data Access/Export API

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | No `/my-data`, `/data-export`, or data portability endpoint. `export-utils.ts` handles proposal/portfolio exports but NOT customer data subject requests |
| **Impact** | PDPA Art. 18 (Right to Access) + Art. 20 (Right to Data Portability) violation |
| **Fix** | Create Edge Function `customer-data-export` with auth + data compilation |
| **Effort** | 8 hours |
| **Priority** | 🟡 HIGH — legal compliance |

### #15 — Consent Timestamp Tracking

| Status | ✅ PASS |
|--------|---------|
| **Finding** | `useCookieConsent.ts` saves `CookieConsentData` with `timestamp` (ISO format) + `version` string to localStorage |
| **Evidence** | Consent captures both timestamp AND version for audit trail |
| **Note** | Consider also persisting to DB for server-side audit |

### #17 — Breach Notification Protocol

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | No breach/incident notification mechanism. `NotificationBell.tsx` is for app events only |
| **Impact** | PDPA Art. 31 requires 72-hour breach notification |
| **Fix** | Create incident response document + alert mechanism (can be Edge Function → LINE/email) |
| **Effort** | 4 hours |
| **Priority** | 🟡 HIGH — legal compliance |

---

## Batch 4: Encryption & Key Management

### #16 — Encryption Key Rotation

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | `encrypt-decrypt/index.ts` uses single `ENCRYPTION_KEY` env var with NO versioning. Legacy `enc:IV:DATA` format backward-compatible but no `v1`/`v2` key prefix support |
| **Impact** | Key compromise = all data compromised, no rotation path without downtime |
| **File** | `supabase/functions/encrypt-decrypt/index.ts` |
| **Fix** | Implement versioned keys (`enc:v2:IV:DATA`), decrypt tries current key then fallback |
| **Effort** | 4 hours |
| **Priority** | 🟠 MEDIUM — resilience improvement |

---

## Batch 5: Database Hardening

### #18 — DELETE Policies for Tables

| Status | ⚠️ PARTIAL |
|--------|------------|
| **Finding** | Some migrations add DELETE policies (unitlink admin, portfolio_shares, 5× in migration `20251202`), but original audit flagged 39 tables missing DELETE policies |
| **Impact** | Incomplete RLS coverage — some tables may allow uncontrolled deletes |
| **Fix** | Audit all 87 tables against current RLS policies via Supabase SQL |
| **Effort** | 4 hours |
| **Priority** | 🟠 MEDIUM |

### #19 — Replace xlsx Library

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | `xlsx@0.18.5` still in `package.json`. No replacement installed. 2 HIGH CVEs with NO upstream fix |
| **CVEs** | Prototype Pollution (GHSA-4r6h-8v6p-xvw6) + ReDoS (GHSA-5pgg-2g8v-p4x9) |
| **Fix** | Replace with [ExcelJS](https://github.com/exceljs/exceljs) or [SheetJS Pro](https://sheetjs.com/pro) |
| **Effort** | 8 hours (API differences require code changes) |
| **Priority** | 🟠 MEDIUM — no upstream fix means this will never auto-resolve |

---

## Batch 6: Infrastructure

### #20 — HTTPS for FA Tools

| Status | ❌ FAIL |
|--------|---------|
| **Finding** | FA Tools served via HTTP on `vuttihome.thddns.net:5173` (Vite dev server). No HTTPS |
| **Impact** | Auth cookies/tokens sent in plaintext. MITM possible |
| **Fix** | Cloudflare Tunnel or Caddy reverse proxy with auto-TLS |
| **Effort** | 2 hours |
| **Priority** | 🟡 HIGH — auth tokens over HTTP = credential theft risk |
| **Note** | Production on `tools.iagencyaia.com` via Lovable has HTTPS ✅. Only self-hosted instance affected |

---

## Scorecard Summary

| # | Item | Batch | Status | Severity |
|---|------|-------|--------|----------|
| 7 | Encrypt plaintext PII | 2 | ❌ FAIL | HIGH |
| 11 | Rate limiting (14 functions) | 2 | ❌ FAIL | HIGH |
| 12 | npm audit fix | 2 | ⚠️ PARTIAL | HIGH |
| 13 | Privacy policy page | 3 | ❌ FAIL | HIGH |
| 14 | Customer data access/export | 3 | ❌ FAIL | HIGH |
| 15 | Consent timestamp | 3 | ✅ PASS | — |
| 16 | Key rotation | 4 | ❌ FAIL | MEDIUM |
| 17 | Breach notification | 3 | ❌ FAIL | HIGH |
| 18 | DELETE policies | 5 | ⚠️ PARTIAL | MEDIUM |
| 19 | Replace xlsx | 5 | ❌ FAIL | MEDIUM |
| 20 | HTTPS self-hosted | 6 | ❌ FAIL | HIGH |

### Totals

| Result | Count |
|--------|-------|
| ✅ PASS | 1 |
| ⚠️ PARTIAL | 2 |
| ❌ FAIL | 8 |

---

## Result: ❌ FAIL — 8/11 items unresolved

### Priority Fix Order (recommended)

| Priority | Items | Owner | Effort |
|----------|-------|-------|--------|
| **P0** | #7 PII encryption, #20 HTTPS | FE + Infra | 6 hrs |
| **P1** | #11 Rate limiting, #13 Privacy policy | FE | 6 hrs |
| **P2** | #14 Data access API, #17 Breach protocol | FE + Security | 12 hrs |
| **P3** | #12 npm deps, #16 Key rotation, #18 DELETE policies, #19 xlsx | FE + DBA | 20 hrs |

### What's Already Good (from R4)

All 12 immediate/critical items from R1–R4 are ✅ PASS:
- CORS whitelisted, JWT validated, auth on all functions
- CSP headers, password 12 chars, ProtectedRoute, logout cleanup
- prefillLead secured, console.log PII removed
- jsPDF patched, history table RLS fixed

---

🔒 Security-Oracle — R5 Batch 2–6 Audit Complete
*"The walls stand. Now we build the gates."*
