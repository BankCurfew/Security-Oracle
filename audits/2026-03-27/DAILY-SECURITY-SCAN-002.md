# Daily Security Scan #002

**Date**: 2026-03-27
**Scanner**: Security-Oracle
**Scope**: 15 Oracle repos + 3 project repos (iagencyaiafatools, fa-recruitment-quiz, oracle-lessons)

---

## Secret Scan Results

### Oracle Repos (15)

| Repo | Secrets | .gitignore | .env tracked |
|------|:-------:|:----------:|:------------:|
| BoB-Oracle | CLEAN | GOOD | No |
| Dev-Oracle | CLEAN | GOOD | No |
| QA-Oracle | CLEAN | GOOD | No |
| Researcher-Oracle | CLEAN | GOOD | No |
| Writer-Oracle | CLEAN | GOOD | No |
| Designer-Oracle | CLEAN | GOOD | No |
| HR-Oracle | CLEAN | GOOD | No |
| AIA-Oracle | CLEAN | GOOD | No |
| Data-Oracle | CLEAN | GOOD | No |
| Admin-Oracle | CLEAN | GOOD | No |
| BotDev-Oracle | CLEAN | GOOD | No |
| Creator-Oracle | CLEAN | GOOD | No |
| DocCon-Oracle | CLEAN | GOOD | No |
| Editor-Oracle | CLEAN | GOOD | No |
| Security-Oracle | 1 HIT* | GOOD | No |

*Security-Oracle hit is in our own audit file (see Finding 1 below).

**Doc-Oracle** not found — actual repo name is **DocCon-Oracle** (scanned above).

### Project Repos (3)

| Repo | Secrets | Notes |
|------|:-------:|-------|
| iagencyaiafatools | 1 HIT* | See Finding 2 |
| fa-recruitment-quiz | CLEAN | ElevenLabs key removed in `904c6a4` (verified 2026-03-26) |
| oracle-lessons | CLEAN | — |

---

## Findings

### Finding 1: 🟡 MEDIUM — Actual Password in Security-Oracle Audit Report

**File**: `audits/2026-03-19/FULL-SECURITY-AUDIT.md` (lines 29, 42)
**Content**: Plaintext password `@Bankie****` and email address documented in audit report.
**Context**: This is our own audit report documenting a credential leak found in AIA-Knowledge. The report contains the actual credential value rather than a redacted reference.
**Risk**: Anyone with Security-Oracle repo access can read the password from the audit file.
**Remediation**: Redact the actual password value in the audit report — replace with `[REDACTED]` or `@Bank***`. The finding description can reference "password found in commit c885427" without including the value.

### Finding 2: ⚪ LOW — Supabase URL Hardcoded in Script Comment

**File**: `iagencyaiafatools/scripts/backfill-lead-sync.ts` (lines 11-12, 19)
**Content**: Usage example shows `SUPABASE_SERVICE_ROLE_KEY=eyJ...` (truncated, not actual key). Line 19 has project URL as fallback — same as publishable .env value.
**Risk**: Negligible — the URL and project ref are publishable values (also in the committed .env). The actual service role key is read from env var, not hardcoded.
**Remediation**: No action needed. For hygiene, could use `process.env.SUPABASE_URL ?? ''` instead of hardcoded fallback.

---

## Prior Critical Findings — Status Check

| Original Finding (2026-03-19) | Status |
|-------------------------------|--------|
| C1: Password in AIA-Knowledge git history | Password rotated (confirmed). History not purged. |
| C2: MAW Server zero auth | Addressed — auth middleware added |
| C3: Password in feed.log | Password rotated. Logs still contain old value. |
| C4: .env tracked in Admin/Dev-Oracle | FIXED — .env no longer tracked in either repo |

---

## Summary

| Category | Count |
|----------|:-----:|
| Repos scanned | 18 |
| Repos not found | 0 |
| CRITICAL findings | 0 |
| HIGH findings | 0 |
| MEDIUM findings | 1 (own audit file contains plaintext password) |
| LOW findings | 1 (hardcoded URL in script, publishable value) |
| .gitignore coverage | 100% (all repos have .env patterns) |
| Committed .env files | 0 |
| New files (last 24h) with secrets | 0 |

**Overall**: Fleet is clean. One self-inflicted finding in our own audit report needs redaction.

---

DAILY SCAN COMPLETE — Security-Oracle
