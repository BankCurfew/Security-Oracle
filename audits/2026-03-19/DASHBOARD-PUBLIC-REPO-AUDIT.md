# 🔴 Dashboard Public Repo Security Audit — oracle-v2

**Date**: 2026-03-19 14:53 GMT+7
**Auditor**: Security-Oracle
**Source**: ~/repos/github.com/Soul-Brews-Studio/oracle-v2/
**Thread**: #44 (channel:security)
**Requested by**: BoB-Oracle (via แบงค์)
**Scope**: Full security audit — secrets, git history, hardcoded values, PDPA, frontend, dependencies

---

## Executive Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 1 |
| 🟠 HIGH | 4 |
| 🟡 MEDIUM | 11 |
| 🟢 LOW | 9 |
| ⚪ INFO | 3 |

**Verdict**: ❌ **NOT READY for public repo** — 1 CRITICAL credential in git history must be purged + rotated before making public. 4 HIGH findings need remediation. No customer PII found (PDPA clean for code).

---

## 🔴 CRITICAL Findings

### C1 — Leaked Credential in Git History: `uniserv:uniservadmin`

| | |
|---|---|
| **File (deleted)** | `ψ/memory/learnings/2026-01-26_duckdb-remote-api-basic-auth.md` |
| **Commits** | `a7ad3a5`, `959c886`, `3d42254` (deleted but recoverable) |
| **Value** | Base64: `dW5pc2Vydjp1bmlzZXJ2YWRtaW4=` → `uniserv:uniservadmin` |
| **Service** | U-LIB APIs (ujic.uniserv.cmu.ac.th, cm-command.cmuccdc.org, pr.uniserv.cmu.ac.th + 4 others) |
| **Status** | File deleted from HEAD but **fully recoverable** from git history |

**Remediation**:
1. **Rotate credential NOW** — assume compromised, contact UNISERV/CMU team
2. Run `git filter-repo --path 'ψ/memory/learnings/2026-01-26_duckdb-remote-api-basic-auth.md' --invert-paths`
3. Force-push all branches
4. Notify all collaborators to re-clone

---

## 🟠 HIGH Findings

### H1 — X-Forwarded-For IP Spoofing Bypasses Authentication

| | |
|---|---|
| **File** | `src/server.ts:135-161` |
| **Issue** | Server trusts `X-Forwarded-For` from any client. Attacker sets header to `127.0.0.1` → bypasses auth entirely |
| **Impact** | Complete auth bypass when `localBypass` enabled (default) |
| **Fix** | Only trust proxy headers when direct connection IP is a known reverse proxy |

### H2 — Wildcard CORS on All Routes

| | |
|---|---|
| **File** | `src/server.ts:123` — `app.use('*', cors())` |
| **Issue** | `Access-Control-Allow-Origin: *` — any website can make cross-origin API requests |
| **Fix** | Restrict to known origins: `cors({ origin: ['http://localhost:3000'] })` |

### H3 — Authentication Disabled by Default (Fail-Open)

| | |
|---|---|
| **File** | `src/server.ts:194-196`, `frontend/src/contexts/AuthContext.tsx:19-25` |
| **Issue** | No password = no auth. On API error, frontend grants access. New deployments are completely open |
| **Fix** | Default to fail-closed. On auth check error, redirect to login |

### H4 — Session Cookie `secure: false`

| | |
|---|---|
| **File** | `src/server.ts:274` |
| **Issue** | Cookie transmitted over plain HTTP. MITM risk if accessed over non-localhost network |
| **Fix** | `secure: process.env.NODE_ENV === 'production'` |

---

## 🟡 MEDIUM Findings

### M1 — No Rate Limiting on Login Endpoint
- **File**: `src/server.ts:251`
- **Fix**: Add rate limiting (max 5 attempts/IP/minute)

### M2 — No Security Headers (CSP, X-Frame-Options, HSTS, etc.)
- **File**: `src/server.ts` — missing middleware
- **Fix**: Add security headers middleware

### M3 — Minimum Password Length = 4 Characters
- **File**: `frontend/src/pages/Settings.tsx:47`
- **Fix**: Enforce minimum 12 characters (NIST SP 800-63B). Add server-side validation

### M4 — Git Commit Hash Exposed in UI Bundle
- **File**: `frontend/vite.config.ts:9-10`, `frontend/src/components/Header.tsx:95`
- **Fix**: Show version only, omit git hash in production

### M5 — .gitignore Missing .env Variants
- **File**: `.gitignore`
- **Gap**: `.env.production`, `.env.development`, `.env.staging`, `.env.test`, `.env.*.local` not covered
- **Fix**: Add `.env*` wildcard pattern

### M6 — Hardcoded Internal Org/Repo Names Throughout Source
- `src/forum/types.ts:145` → `'laris-co/Nat-s-Agents'` (runtime code!)
- `src/indexer.ts:687` → `'github.com/laris-co/arthur-oracle'` (runtime code!)
- `scripts/generate-vault-report.mjs:183-192` → client names: `dryoungdo-wellness-clinic`, `prakit-advertising`, `maeon-lab`
- 6+ additional references in comments/docs
- **Fix**: Replace with env vars or configurable values. Remove client names from source

### M7 — Hardcoded `/home/nat` Fallback Path
- **File**: `src/server.ts:499`
- **Fix**: Use `os.tmpdir()` or require `HOME`

### M8 — Schedule Table Stores Personal Data Without Access Controls
- **File**: `src/db/schema.ts:251-265`
- **Fix**: Document data classification, add retention policy

### M9 — Forum Messages Stored Indefinitely Without Deletion
- **File**: `src/db/schema.ts:113-128`
- **Fix**: Add data retention policy, deletion endpoint per PDPA Article 33

### M10 — No .env.example File
- **Fix**: Create `.env.example` with all required vars documented (no real values)

### M11 — PM2 Port Mismatch (47779 vs 47778)
- **File**: `ecosystem.config.js:7` vs `src/config.ts:20`
- **Fix**: Align ports

---

## 🟢 LOW Findings

| # | Finding | File |
|---|---------|------|
| L1 | `console.log('Status update:', result)` leaks thread data | `frontend/src/pages/Forum.tsx:148` |
| L2 | Test fixtures use `/Users/nat/Code/...` paths | `src/server/__tests__/project-detect.test.ts` |
| L3 | `package.json` author = "Nat's Agents" (identity disclosure) | `package.json` |
| L4 | `sqlite-vec@0.1.7-alpha.2` — alpha dependency in production | `package.json` |
| L5 | `rc@1.2.8` unmaintained (transitive via better-sqlite3) | `bun.lock` |
| L6 | Search log stores raw user queries indefinitely | `src/db/schema.ts:48-61` |
| L7 | Activity log stores file paths indefinitely | `src/db/schema.ts:231-245` |
| L8 | `ORACLE_SESSION_SECRET` not documented — sessions expire on restart | `src/server.ts:130` |
| L9 | `ORACLE_FORUM_REPO` env var not documented | `src/forum/types.ts:145` |

---

## ⚪ INFO

| # | Finding |
|---|---------|
| I1 | No `bun audit` available — recommend `osv-scanner --lockfile bun.lock` for CI |
| I2 | Personal ψ/ data in git history (gitignored since `3d42254` but recoverable) |
| I3 | 330 commits on main, 349 total across 11 branches |

---

## PDPA Compliance

| Check | Result |
|-------|--------|
| Customer PII in code | ✅ CLEAR — no names, phones, IDs, health data |
| Customer PII in test data | ✅ CLEAR — all synthetic |
| Customer PII in git history | ✅ CLEAR |
| Personal schedule data | ⚠️ Architecture risk — no retention policy |
| Forum content retention | ⚠️ No deletion mechanism |
| Data subject rights | ⚠️ Not implemented (no deletion endpoint) |

**PDPA Verdict**: Code is clean. Architecture needs retention policies before handling customer data.

---

## Dependencies

| Check | Result |
|-------|--------|
| Lock file committed | ✅ PASS |
| Malicious postinstall scripts | ✅ CLEAR |
| Typosquatting packages | ✅ CLEAR |
| Vendored third-party code | ✅ CLEAR |
| Known CVEs | ⚠️ Cannot fully verify (no bun audit). `rc@1.2.8` unmaintained but patched |
| Alpha dependencies | ⚠️ `sqlite-vec@0.1.7-alpha.2` |

---

## Positive Security Patterns Found ✅

1. All API credentials read exclusively from `process.env` — no hardcoded secrets
2. Password hashing uses `Bun.password.hash()` (bcrypt/argon2) — never plaintext
3. Session tokens use HMAC-SHA256 with `timingSafeEqual` — correct implementation
4. Auth password hash never exposed via API
5. File path traversal protection in `/api/file`
6. Parameterized SQL queries throughout (no SQL injection)
7. No `.env` files ever committed
8. Frontend uses relative `/api` paths — no credentials in JS bundle
9. No source maps in production build
10. No tokens stored in localStorage

---

## Remediation Priority

| Phase | Action | Owner | Effort |
|-------|--------|-------|--------|
| **BLOCK** | C1: Rotate UNISERV credential + `git filter-repo` | แบงค์ + Dev | High |
| **Before Public** | H1: Fix X-Forwarded-For IP spoofing | Dev | Low |
| **Before Public** | H2: Restrict CORS origins | Dev | Low |
| **Before Public** | H3: Fail-closed auth design | Dev | Medium |
| **Before Public** | H4: `secure: true` cookie in production | Dev | Low |
| **Before Public** | M3: Increase min password to 12 chars | Dev | Low |
| **Before Public** | M5: Fix .gitignore with `.env*` wildcard | Dev | Trivial |
| **Before Public** | M6: Remove hardcoded org names + client names | Dev | Medium |
| **Before Public** | M7: Fix `/home/nat` fallback | Dev | Trivial |
| **Before Public** | M10: Create .env.example | Dev | Low |
| **Soon After** | M1: Rate limiting on login | Dev | Low |
| **Soon After** | M2: Security headers | Dev | Low |
| **Soon After** | M4: Remove git hash from prod bundle | Dev | Low |
| **Soon After** | M11: Fix port mismatch | Dev | Trivial |

---

## Verdict

### ❌ NOT READY FOR PUBLIC REPO

**Blocking issues**:
1. Credential in git history (C1) — MUST purge before public
2. Auth bypass via IP spoofing (H1) — anyone can bypass auth
3. Hardcoded client business names in source (M6) — business confidentiality
4. Internal org references throughout (M6) — operational security

**Once BLOCK + Before Public items are resolved**: ✅ Ready for public with acceptable risk level.

---

> "The only truly secure system is one that is powered off, cast in a block of concrete, and sealed in a lead-lined room." — Gene Spafford
> But we can get pretty close by fixing these 16 things first.

*Security-Oracle — Audit Complete*
