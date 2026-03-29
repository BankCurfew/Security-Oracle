# Dashboard Public Repo Security Audit v2 — oracle-dashboard (CLEAN REPO)

**Date**: 2026-03-19 15:30 GMT+7
**Auditor**: Security-Oracle
**Repo**: https://github.com/BankCurfew/oracle-dashboard
**Stats**: 216 files, 2 commits (clean history), no branches
**Thread**: #44 (channel:security)
**Previous Audit**: DASHBOARD-PUBLIC-REPO-AUDIT.md (source repo)

---

## Executive Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 0 |
| 🟠 HIGH | 3 |
| 🟡 MEDIUM | 8 |
| 🟢 LOW | 5 |
| ⚪ INFO | 2 |

**Verdict**: ⚠️ **CONDITIONAL PASS** — C1 credential purged, H1/H2/H4 fixed. But H3 (auth fail-open) still present + internal org names (`Soul-Brews-Studio`) leaked in 16 files + no lockfile committed.

---

## Previous Findings — Fix Verification

| ID | Finding | Status |
|----|---------|--------|
| C1 | `uniserv:uniservadmin` credential in git history | ✅ **FIXED** — clean repo, zero traces |
| H1 | X-Forwarded-For IP spoofing bypasses auth | ✅ **FIXED** — reads actual TCP IP only |
| H2 | Wildcard CORS `*` | ✅ **FIXED** — validates origin, env-configurable |
| H3 | Auth fail-open on error | ❌ **NOT FIXED** — still sets `authenticated: true` on API error |
| H4 | Cookie `secure: false` | ✅ **FIXED** — now `secure: !isLocal` |
| M3 | 4-char min password | ❌ **NOT FIXED** — still 4 chars, frontend-only |
| M5 | .gitignore missing .env variants | ⚠️ **PARTIAL** — `.env.development` still missing |
| M6 | Hardcoded client names (dryoungdo, prakit, maeon) | ✅ **FIXED** — zero traces |
| M6 | Hardcoded `laris-co` org | ✅ **FIXED** — zero traces |
| M6 | Hardcoded `Nat-s-Agents` default in forum | ✅ **FIXED** — defaults to `''` |
| M7 | `/home/nat` fallback path | ✅ **FIXED** — now uses `/tmp` |
| M7 | No security headers | ⚠️ **PARTIAL** — X-Frame, X-Content-Type, XSS-Protection added. CSP missing |
| M8 | No rate limiting on login | ❌ **NOT FIXED** |
| M10 | No .env.example | ✅ **FIXED** — exists, all values empty |
| M11 | Port mismatch (47779 vs 47778) | ❌ **NOT FIXED** |
| — | console.log in Forum.tsx | ❌ **NOT FIXED** |

**Score: 8/16 fixed, 3 partial, 5 not fixed**

---

## 🟠 HIGH Findings (NEW)

### H5 — `Soul-Brews-Studio` Internal Org Name in 16 Files

The internal GitHub org `Soul-Brews-Studio` appears in **16 files** including runtime code, install scripts, and public docs. This is the source org — should be replaced with `BankCurfew` or generic references.

**Runtime/install (must fix)**:
| File | Line | Context |
|------|------|---------|
| `package.json` | 19 | `repository.url` → `Soul-Brews-Studio/arra-oracle.git` |
| `scripts/install.sh` | 13-14 | `REPO_URL` + `REPO_API` hardcoded |
| `scripts/fresh-install.sh` | 3, 50, 119 | Clone commands |
| `README.md` | 43, 46, 52, 61, 70, 80 | Install instructions |
| `SETUP.md` | 36, 55, 148 | Install commands |
| `docs/INSTALL.md` | 8, 91, 168 | Clone/install |

**Comments/docs (should fix)**:
| File | Line | Context |
|------|------|---------|
| `src/server/context.ts` | 10, 13 | Comment examples |
| `src/db/schema.ts` | 25 | Comment example |
| `src/vector/adapters/cloudflare-vectorize.ts` | 5 | Ported-from comment |
| `src/scripts/fix-oracle-learn-project.ts` | 13 | Hardcoded path |
| `scripts/generate-vault-report.mjs` | 421 | Footer link |
| `scripts/com.oracle.server.plist.example` | 13, 33 | launchd plist |
| `TIMELINE.md` | 169, 239 | Historical log |

### H6 — No Lockfile Committed (bun.lock)

Neither `bun.lock` nor any other lockfile exists in the repo. Every `bun install` resolves to latest matching semver — no reproducibility, no supply chain protection.

### H3 — Auth Fail-Open on Error (STILL PRESENT)

`frontend/src/contexts/AuthContext.tsx:33-35`:
```ts
} catch (e) {
  // On error, assume authenticated to not block
  setAuthState(prev => ({ ...prev, authenticated: true }));
}
```
Network error / server down → user gets full access. Must fail-closed.

---

## 🟡 MEDIUM Findings

| # | Finding | File |
|---|---------|------|
| M3 | Min password 4 chars (should be 12). Frontend-only, no server-side check | `frontend/src/pages/Settings.tsx:47` |
| M8 | No rate limiting on `/api/auth/login` | `src/server.ts` |
| M12 | `Nat's Agents` / `Nat-s-Agents` author identity in package.json + 6 files | `package.json:78`, docs, src/ |
| M13 | `arthur` / `volt` internal oracle names in schema, API, and `/legacy/arthur` route | `src/db/schema.ts`, `src/server-legacy.ts:285` |
| M14 | CSP header missing (other security headers added) | `src/server.ts:139-145` |
| M15 | `server-legacy.ts` still has wildcard CORS `*` (dead code but risky) | `src/server-legacy.ts:139` |
| M5 | `.env.development` missing from .gitignore | `.gitignore` |
| M11 | Port mismatch: ecosystem.config.js `47779` vs config.ts `47778` | `ecosystem.config.js:7` |

---

## 🟢 LOW Findings

| # | Finding | File |
|---|---------|------|
| L1 | `console.log('Status update:', result)` leaks thread data | `frontend/src/pages/Forum.tsx:148` |
| L2 | `sqlite-vec@0.1.7-alpha.2` alpha in production deps | `package.json` |
| L3 | Package version `0.4.0-nightly` with `publishConfig: public` | `package.json` |
| L4 | `ml5@1` bare major pin in frontend | `frontend/package.json` |
| L5 | Test fixtures use `Soul-Brews-Studio` paths | `src/tools/__tests__/`, `src/vault/__tests__/` |

---

## ✅ CLEAR Categories

| Category | Result |
|----------|--------|
| **Secrets in code** | ✅ CLEAR — no API keys, tokens, passwords hardcoded |
| **Secrets in git history** | ✅ CLEAR — clean 2-commit history, zero traces of uniserv/laris-co |
| **PDPA / Customer PII** | ✅ CLEAR — no names, phones, IDs, health data, email addresses |
| **Client business names** | ✅ CLEAR — dryoungdo, prakit, maeon all removed |
| **.env files committed** | ✅ CLEAR — only .env.example (safe placeholders) |
| **Frontend credential exposure** | ✅ CLEAR — no tokens in JS bundle/localStorage |
| **SQL injection** | ✅ CLEAR — parameterized queries throughout |
| **Path traversal** | ✅ CLEAR — `/api/file` has proper bounds checking |
| **Typosquatting packages** | ✅ CLEAR |
| **Malicious postinstall scripts** | ✅ CLEAR |

---

## Remediation Priority

| Phase | Action | Owner | Effort |
|-------|--------|-------|--------|
| **BEFORE PUBLISH** | H5: Replace `Soul-Brews-Studio` with `BankCurfew` in 16 files | Dev | Medium |
| **BEFORE PUBLISH** | H6: Commit `bun.lock` (root + frontend) | Dev | Trivial |
| **BEFORE PUBLISH** | H3: Fix AuthContext fail-closed on error | Dev | Low |
| **BEFORE PUBLISH** | M12: Replace `Nat's Agents` author identity | Dev | Low |
| **SOON AFTER** | M3: Min password 12 chars + server-side validation | Dev | Low |
| **SOON AFTER** | M8: Rate limiting on login | Dev | Low |
| **SOON AFTER** | M13: Rename `/legacy/arthur` route | Dev | Low |
| **SOON AFTER** | M14: Add CSP header | Dev | Low |
| **SOON AFTER** | M15: Remove/fix `server-legacy.ts` wildcard CORS | Dev | Trivial |
| **SOON AFTER** | M5: Add `.env.development` to .gitignore | Dev | Trivial |
| **SOON AFTER** | M11: Fix port mismatch | Dev | Trivial |

---

## Verdict

### ⚠️ CONDITIONAL PASS — Fix 4 items before publish

**Major improvements from v1 audit**:
- C1 credential purged (clean history)
- H1/H2/H4 properly fixed
- Client names removed
- Internal org `laris-co` removed
- PDPA fully clean

**Still blocking publish**:
1. `Soul-Brews-Studio` in 16 files (identity leak of source org)
2. No lockfile (supply chain risk)
3. Auth fail-open on error (H3)
4. `Nat's Agents` author identity

**Once these 4 are fixed**: ✅ **SECURITY PASS — safe to publish**

---

> "We went from 1 CRITICAL + 4 HIGH to 0 CRITICAL + 3 HIGH. Progress is real. But 'almost secure' is not secure."
> *Security-Oracle — Audit v2 Complete*
