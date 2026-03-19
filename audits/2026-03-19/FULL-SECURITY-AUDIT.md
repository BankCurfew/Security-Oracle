# BoB's Office — Full Security Audit Report

> **Date**: 2026-03-19
> **Auditor**: Security-Oracle #15 (First Audit)
> **Scope**: All 17 BankCurfew repos + infrastructure + communications
> **Ordered by**: แบงค์ (The Boss)

---

## Executive Summary

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 CRITICAL | 4 | ต้องแก้ทันที |
| 🟡 HIGH | 5 | แก้ภายใน 24 ชม. |
| 🟢 MEDIUM | 5 | แก้ภายในสัปดาห์ |
| ⚪ LOW | 4 | Recommend |

**Overall Security Posture: 🟡 AMBER — Significant risks requiring immediate attention**

The biggest risks are: (1) plaintext password in git history, (2) MAW server with zero auth, (3) customer PII in logs and repos, (4) .env files tracked in git.

---

## 🔴 CRITICAL — ต้องแก้ทันที

### C1: Plaintext Password in Git History — AIA-Knowledge
- **Files**: `fa-tools/api-spec.md`, `technical/jarvis-api-documentation.md`
- **Content**: `"password": "@Bankie6533"` + `"email": "bankvuttipipat@gmail.com"`
- **Commits**: `c885427`, `9bc2976`
- **Risk**: Even though repo is private, credentials in git history are permanent
- **Action**: Rotate password immediately → Remove from files → `git filter-repo` to purge history

### C2: MAW Server (port 3456) — Zero Authentication
- **Binding**: `*:3456` (all interfaces)
- **Impact**: `/api/send` endpoint = **unauthenticated remote code execution** — anyone who reaches port 3456 can send commands to any oracle's terminal
- **Also**: `maw.config.json` has `"commands": {"default": "claude --dangerously-skip-permissions"}`
- **Action**: Add bearer token auth middleware immediately → Bind to 127.0.0.1 or restrict via firewall

### C3: Password Broadcast via feed.log / maw-hey
- **File**: `~/.oracle/feed.log` (52,227 lines, 10MB)
- **Content**: Password `@Bankie6533` appears in 5+ entries — sent via `maw hey` from BoB to Dev and Researcher
- **Also in**: `~/.oracle/maw-log.jsonl` (5 matches)
- **Action**: Rotate password → Sanitize logs → **Policy: credentials NEVER via maw-hey/talk-to**

### C4: .env Files Tracked in Git — Admin-Oracle & Dev-Oracle
- **Admin-Oracle/.env**: LINE_CHANNEL_SECRET, LINE_CHANNEL_ACCESS_TOKEN, SUPABASE_SERVICE_KEY, ANTHROPIC_API_KEY, FA_TOOLS_API_KEY
- **Dev-Oracle/.env**: SUPABASE_SERVICE_KEY, GEMINI_API_KEY, GOOGLE_APPLICATION_CREDENTIALS
- **Risk**: Service role key bypasses all RLS — full database access
- **Action**: `git rm --cached .env` in both repos → Rotate ALL keys → Purge git history

---

## 🟡 HIGH — แก้ภายใน 24 ชม.

### H1: Customer PII in feed.log (PDPA Violation Risk)
- **Content**: Customer name `ชัชชม รักขิตกูล`, phone `0655170399`, DOB, health info, province — all in single maw-hey message (2026-03-17)
- **Classification**: 🔴 Restricted data per data classification policy
- **Action**: Sanitize PII from feed.log → Add PII filtering to feed-hook → Review PDPA 72-hour notification

### H2: Customer PII in DocCon-Oracle — Real Names + Policy Numbers
- **File**: `DocCon-Oracle/CLAUDE_email.md`
- **Content**: `น.ส. ณัฐณิชา ปัญญามโน` (policy U887623367), `นาง สุดารัตน์ ชาญเฉลิมชัย` (policy T249134180)
- **Action**: Replace with fake/anonymized data immediately

### H3: Jarvis Bot /test Endpoint Bypasses LINE Signature Verification
- **Location**: `bot.ts` line 367-389
- **Comment in code**: "NOT for production — disable before deploy" — but it's LIVE through Cloudflare tunnel
- **Action**: Remove or auth-protect /test endpoint

### H4: Cloudflare Quick Tunnel — No Access Policies
- **Process**: `cloudflared tunnel --url http://localhost:3200` (2 instances)
- **Risk**: Random `*.trycloudflare.com` URL with no access control
- **Action**: Migrate to named tunnel with Cloudflare Access policies

### H5: Personal Phone Number in Multiple Git Repos
- **Number**: `0628245356` in AIA-Knowledge (3 files), Researcher-Oracle (1 file)
- **Action**: Replace with placeholder in documentation

---

## 🟢 MEDIUM — แก้ภายในสัปดาห์

### M1: 5 Repos Missing Secrets Patterns in .gitignore
- **Repos**: AIA-Oracle, Admin-Oracle, BoB-Oracle, Data-Oracle, Dev-Oracle
- **Missing**: `.pem`, `.key`, `credentials.json`, `*secret*` patterns
- **Action**: Add comprehensive secrets patterns to .gitignore

### M2: Embedding Service (port 8100) — No Auth, Bound 0.0.0.0
- **Source**: `Dev-Oracle/knowledge-base/scripts/embedding-service.py`
- **Action**: Bind to 127.0.0.1, add auth

### M3: Hardcoded Supabase URLs in Source Code
- **Files**: Admin-Oracle `src/fa/proposal.ts`, `products.ts`, `premium.ts`
- **URL**: `https://rugcuukelivcferjjzek.supabase.co`
- **Action**: Move to env var

### M4: `--dangerously-skip-permissions` on All Oracles
- **Config**: Every oracle runs with permissions bypassed
- **Risk**: Any oracle can execute arbitrary commands without confirmation
- **Action**: Review if this can be scoped more tightly

### M5: AWS Credentials (Canva Export) in feed.log
- **Content**: `AKIAQYCGKMUH5AO7UJ26` (Canva's S3 signing credentials) — 4 occurrences
- **Risk**: Low (expired signed URLs) but pattern is concerning
- **Action**: Filter signed URLs from feed logs

---

## ⚪ LOW — Recommend

### L1: feed.log Growing Unchecked
- 10MB / 52K lines with no rotation — data retention risk with PII
- **Recommend**: Implement log rotation (logrotate or daily truncation)

### L2: Hardcoded Owner Contact in Admin-Oracle Source
- Phone/email in `src/fa/proposal.ts` — move to env var

### L3: Playwright Browser Instances with Cached Sessions
- Two persistent Chrome instances (`mcp-chrome-aia`, `mcp-chrome-dev`) may hold cookies
- **Recommend**: Clear browser data periodically

### L4: Supabase Project URL Hardcoded in 6 Files
- `heciyiepgxqtbphepalf.supabase.co` as fallback — move to env var for cleanliness

---

## Positive Findings ✅

| Area | Status |
|------|--------|
| No hardcoded API keys in source code (except .env tracked in git) | ✅ |
| LINE webhook validates x-line-signature properly | ✅ |
| All repos use process.env / os.environ patterns | ✅ |
| No force-push or destructive git operations in any repo | ✅ |
| .env.example files contain only empty placeholders | ✅ |
| AIA-Knowledge contains no customer PII (products only) | ✅ |
| Admin/Dev repos are private on GitHub | ✅ |
| No SSH configuration found (WSL2 — minimal attack surface) | ✅ |

---

## Remediation Priority Matrix

| Priority | Action | Owner | Deadline |
|----------|--------|-------|----------|
| 🔴 P0 | Rotate FA Tools password (@Bankie6533) | แบงค์ + Admin | Today |
| 🔴 P0 | Add auth to MAW server | Dev-Oracle | Today |
| 🔴 P0 | `git rm --cached .env` in Admin + Dev repos | Dev-Oracle | Today |
| 🔴 P0 | Rotate ALL keys in Admin + Dev .env files | แบงค์ | Today |
| 🟡 P1 | Sanitize feed.log (PII + passwords) | Admin-Oracle | 24h |
| 🟡 P1 | Replace real customer data in DocCon-Oracle | DocCon-Oracle | 24h |
| 🟡 P1 | Remove /test endpoint from Jarvis bot | BotDev-Oracle | 24h |
| 🟡 P1 | Migrate to named Cloudflare tunnel | Dev-Oracle | 24h |
| 🟢 P2 | Add secrets patterns to 5 .gitignore files | Security-Oracle | This week |
| 🟢 P2 | Bind embedding service to 127.0.0.1 | Dev-Oracle | This week |
| 🟢 P2 | Move hardcoded URLs to env vars | Dev + Admin | This week |
| 🟢 P2 | Implement feed.log rotation + PII filter | Admin-Oracle | This week |

---

## PDPA Compliance Summary

| Check | Status |
|-------|--------|
| Customer PII only in Supabase (not repos) | ⚠️ FAIL — PII in DocCon-Oracle + feed.log |
| Consent documented | ❓ Not verified — no consent records found |
| Data minimization | ⚠️ FAIL — health data in feed.log |
| Access control on customer data | ⚠️ Partial — Supabase RLS exists but service key bypasses it |
| Breach notification ready (72h) | ❓ No incident response automation |
| Data subject rights (access/delete) | ❓ Not verified |

---

> "Trust, but verify. Then verify again."
>
> *Security-Oracle — First Audit Complete, 2026-03-19*
