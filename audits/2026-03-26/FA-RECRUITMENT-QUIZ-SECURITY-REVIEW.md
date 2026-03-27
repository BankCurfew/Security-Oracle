# FA Recruitment Quiz — Security Review

**Date**: 2026-03-26
**Auditor**: Security-Oracle
**Repo**: BankCurfew/fa-recruitment-quiz
**Branch**: main (commit `0703ebd`)
**Requested by**: BoB (thread #22 context — BotDev fixing scoring bugs)
**Scope**: Data exposure, input sanitization, score tampering, result URL spoofing

---

## Architecture Summary

| Aspect | Detail |
|--------|--------|
| **Type** | Pure client-side React SPA (Vite + TypeScript) |
| **Backend** | None — static file server only (`serve.ts` via Bun on port 3470) |
| **Database** | None |
| **API calls** | None (no fetch/axios/supabase in app code) |
| **PII collected** | None — no name, email, phone, or any user input fields |
| **Data persistence** | None — quiz state lives in React `useReducer`, lost on page refresh |

---

## Findings

### 🔴 CRITICAL — ElevenLabs API Key Hardcoded in Git (5 files)

**Severity**: CRITICAL
**Files**:
- `scripts/gen-audio.sh:9`
- `scripts/gen-audio-adaptive.sh:5`
- `scripts/gen-audio-emotional.sh:10`
- `scripts/gen-ambient.sh:9`
- `scripts/regen-narrations.sh:8`

**Key**: `sk_9b4540d912aa27571f357cce57a0296abe6bedf55e5395ca` (ElevenLabs TTS API)

**Risk**: Anyone with repo access (or if repo goes public) can use this key to generate TTS audio at our expense. Key is in git history even if removed from HEAD.

**Remediation**:
1. **IMMEDIATE**: Rotate the ElevenLabs API key from their dashboard
2. Replace hardcoded key with `${ELEVENLABS_API_KEY}` env var in all 5 scripts
3. Add `.env` to `.gitignore` (currently missing — see next finding)
4. Consider `git filter-branch` or BFG to purge key from history (or accept it's in history and rotate)

---

### 🟡 HIGH — .gitignore Missing Secret Patterns

**Severity**: HIGH
**File**: `.gitignore`

Current `.gitignore` has NO entries for:
- `.env` / `.env.*`
- `credentials*`
- `*.key` / `*.pem`
- `secret*`

**Risk**: Any future `.env` file added to the project will be committed by default.

**Remediation**: Add to `.gitignore`:
```
.env
.env.*
*.key
*.pem
```

---

### 🟡 HIGH — Path Traversal in serve.ts

**Severity**: HIGH
**File**: `serve.ts:27`

```typescript
const filePath = DIST + url.pathname;
const file = Bun.file(filePath);
```

`url.pathname` is used directly without sanitization. While `new URL()` normalizes `../` in most cases, encoded variants or edge cases in Bun's URL parser could allow reading files outside `dist/`.

**Risk**: Potential file read outside the intended directory on the production server.

**Remediation**:
```typescript
import { resolve, normalize } from 'path';
const safePath = resolve(DIST, '.' + normalize(url.pathname));
if (!safePath.startsWith(DIST)) {
  return new Response('Forbidden', { status: 403 });
}
```

---

### 🟢 MEDIUM — No Security Headers on serve.ts

**Severity**: MEDIUM
**File**: `serve.ts`

Missing headers:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` (prevent clickjacking)
- `Content-Security-Policy` (prevent XSS via injected scripts)
- `Strict-Transport-Security` (if served over HTTPS)

**Risk**: Standard hardening headers absent. Low immediate risk for a quiz with no auth, but good hygiene.

**Remediation**: Add security headers to all responses in `serve.ts`.

---

### 🟢 MEDIUM — Server Binds to 0.0.0.0

**Severity**: MEDIUM
**File**: `serve.ts:23`

```typescript
hostname: "0.0.0.0",
```

Binds to all network interfaces. If the server runs on a machine with a public IP, the quiz is exposed without any auth or rate limiting.

**Risk**: Open access from any network. Combined with the path traversal issue above, this increases exposure.

**Remediation**: Bind to `127.0.0.1` and use a reverse proxy (nginx/caddy) in production with rate limiting.

---

## Requested Review Areas

### 1. Data Exposure Risk — ✅ LOW

- **No PII collected**: Quiz has zero text input fields. All interactions are predefined choice buttons or drag-to-rank.
- **No backend/database**: Quiz state (`useReducer`) exists only in browser memory. Nothing is sent anywhere.
- **No analytics/tracking code**: No Google Analytics, no Mixpanel, no pixels detected.
- **Career card results** show generic role descriptions (income ranges, next steps) — no personalized data.

**Verdict**: Minimal data exposure risk. The quiz is essentially a client-side calculator.

### 2. User Input Sanitization — ✅ LOW

- **No free-text input**: All user interactions are clicking predefined `Choice` objects from `questions.ts`.
- **React default escaping**: React auto-escapes rendered content, preventing XSS even if choice text contained HTML.
- **Choice scores are statically defined**: `scores: { goals: 2, motivation: 3 }` — not user-controllable.

**Verdict**: No sanitization issues. There is no user-supplied text to sanitize.

### 3. Score Tampering — ⚠️ MEDIUM (Accepted Risk)

- **All scoring is client-side**: `scoring.ts` runs entirely in the browser. A technical user can open DevTools and modify `state.scores` via React DevTools or by intercepting the reducer.
- **No server-side validation**: There is no backend to verify scores against.
- **No result submission**: Scores are not sent to any server, so tampering only affects what the user sees on their own screen.

**Risk Assessment**: Since this is a **self-assessment recruitment screening tool** (not a certification exam), client-side scoring is acceptable. The quiz result is a conversation starter, not a binding decision. A candidate who tampers with their own score gains nothing — the follow-up interview will reveal reality.

**If score integrity becomes important** (e.g., results are shared with recruiters via URL):
1. Sign the result with HMAC on a backend
2. Generate a tamper-proof result token
3. Verify server-side before showing to recruiters

### 4. Result URL Spoofing — ✅ N/A

- **No result URLs exist**: The quiz does not generate shareable result URLs.
- **No `navigator.share`, no clipboard copy, no URL parameters**: Results are displayed in-browser only.
- **No route-based results**: The SPA uses a single route — no `/result/FA_PRIME` style URLs.

**Verdict**: Not applicable. No URL to spoof.

---

## Summary

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | ElevenLabs API key in git | 🔴 CRITICAL | Needs immediate key rotation |
| 2 | .gitignore missing .env patterns | 🟡 HIGH | Needs fix before next commit |
| 3 | Path traversal in serve.ts | 🟡 HIGH | Needs fix in production |
| 4 | Missing security headers | 🟢 MEDIUM | Recommended |
| 5 | Server binds 0.0.0.0 | 🟢 MEDIUM | Recommended for production |

**Overall Assessment**: The quiz app itself is well-architected from a security standpoint — pure client-side, no PII, no backend. The main risks are **operational** (leaked API key, server misconfiguration), not application-level.

**Priority Action**: Rotate the ElevenLabs API key immediately.

---

🔒 SECURITY REVIEW COMPLETE — Security-Oracle
