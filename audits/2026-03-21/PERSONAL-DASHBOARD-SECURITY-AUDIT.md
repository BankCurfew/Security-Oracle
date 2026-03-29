# Personal Dashboard (:3460) — Security Audit

**Date**: 2026-03-21
**Target**: personal-dashboard (frontend :3460) + PA-Oracle dashboard-api (backend :3461)
**Ordered by**: แบงค์ (The Boss)
**Auditor**: Security-Oracle
**Classification**: 🔴 RESTRICTED — Personal Financial Data

---

## Executive Summary

| Category | CRITICAL | HIGH | MEDIUM |
|----------|----------|------|--------|
| Access Control | 2 | 1 | 1 |
| Data Protection | 1 | 1 | 1 |
| Network Exposure | 1 | 0 | 0 |
| Authentication | 1 | 1 | 0 |
| **TOTAL** | **5** | **3** | **2** |

**Security Grade**: 🔴 **D** — Critical vulnerabilities in access control and data protection

---

## Architecture

```
User (external) → vuttihome.thddns.net:3460 (HTTP, no TLS)
  → bun serve.ts (static + proxy, 0.0.0.0:3460)
  → /api/* → localhost:3461 (PA-Oracle Hono API)
  → /tmp/pa-dashboard-*.json (cache files)
```

| Component | Location | Tech |
|-----------|----------|------|
| Frontend | `BankCurfew/personal-dashboard` | React + Vite + Bun |
| Backend API | `BankCurfew/PA-Oracle/src/dashboard-api.ts` | Hono on Bun |
| Data store | `/tmp/pa-dashboard-*.json` | JSON cache files |

---

## Q1: ข้อมูลเก็บที่ไหน?

**JSON cache files ใน `/tmp/`** — ไม่มี database

| File | Size | Contents | Sensitive? |
|------|------|----------|-----------|
| `/tmp/pa-dashboard-finance.json` | 33KB | รายรับ/รายจ่าย/หนี้/spending patterns | 🔴 YES |
| `/tmp/pa-dashboard-finance-pin.json` | 51B | PIN plaintext | 🔴 YES |
| `/tmp/pa-dashboard-pending.json` | 5.3KB | คำถามรอตอบ + context | 🟡 YES |
| `/tmp/pa-dashboard-email.json` | 3.5KB | Email summary | 🟡 YES |
| `/tmp/pa-dashboard-aia-summary.json` | 16KB | AIA insurance data | 🟡 YES |
| `/tmp/pa-dashboard-calendar.json` | 4KB | Google Calendar events | 🟡 YES |
| `/tmp/pa-dashboard-line.json` | 2.2KB | LINE chat summary | ⚠️ PARTIAL |
| `/tmp/pa-dashboard-tasks.json` | 3.9KB | Aggregated tasks | ⚪ NO |
| `/tmp/pa-dashboard-claude-usage.json` | 436B | API usage metrics | ⚪ NO |

**Risk**: `/tmp` readable by all system processes. No encryption at rest.

---

## Q2: Data ส่งผ่าน HTTP ไม่ encrypt?

**YES — ทุกอย่างเป็น HTTP plaintext** 🔴

- Frontend: `http://vuttihome.thddns.net:3460` — **NO HTTPS**
- API proxy: `http://localhost:3461` — localhost OK but frontend-to-user is HTTP
- Finance data (income ฿1.3M, debts, bank balances) sent as plaintext JSON
- PIN sent as plaintext in POST body

**Impact**: Anyone on the same network (WiFi, ISP) can see all financial data via packet capture.

---

## Q3: Finance data ปลอดภัยไหม?

**ไม่ปลอดภัยเพียงพอ** 🔴

### Finance Data Contains:
- รายรับ Q1: ฿1,307,685 (AIA commissions, Grab, etc.)
- รายจ่ายรายเดือน: SAM ฿10,420, Tesla, personal loans
- SAM remaining: ฿834,252
- Bank balance start/end
- Spending patterns + merchant details
- Debt overview ทุกรายการ

### Protection: 6-digit PIN only

| Vulnerability | Severity | Detail |
|--------------|----------|--------|
| PIN brute-force | 🔴 CRITICAL | 6 digits = 1M combos, no rate limiting, no lockout |
| PIN stored plaintext | 🔴 CRITICAL | `/tmp/pa-dashboard-finance-pin.json` readable by all processes |
| PIN in frontend .env | 🟡 HIGH | `VITE_FINANCE_PIN=060533` baked into JS build (viewable in browser DevTools) |
| No server-side session | 🟡 HIGH | PIN check is client-side fallback — can be bypassed |
| Finance data in /tmp | 🟡 HIGH | Plaintext JSON, no encryption at rest |

### ⚠️ CRITICAL: PIN Exposed in Frontend Build

```typescript
// personal-dashboard/src/lib/api.ts
export const FINANCE_PIN = import.meta.env.VITE_FINANCE_PIN || '0000'
```

`VITE_*` variables are embedded in the compiled JavaScript. Anyone can:
1. Open browser DevTools → Sources → search for "FINANCE_PIN"
2. Or: `curl http://vuttihome.thddns.net:3460/assets/index-*.js | grep -o 'FINANCE_PIN.*'`

**The PIN is effectively public.**

---

## Q4: ใครเข้าถึงได้บ้าง?

### Network Exposure

| Port | Binding | External Access |
|------|---------|----------------|
| 3460 (frontend) | `0.0.0.0` | ✅ YES — exposed via DDNS port forward |
| 3461 (backend) | `*` (all interfaces) | ⚠️ Technically exposed but needs port forward |

### CORS: Unrestricted 🔴

```typescript
// dashboard-api.ts
app.use("/*", cors())  // ANY origin can access ALL endpoints
```

**Impact**: Any website can make requests to the API from the user's browser. A malicious page could silently fetch `/finance`, `/pending`, `/email` data.

### Endpoints Without Authentication (11/12 GET endpoints)

| Endpoint | Data Exposed | Auth Required |
|----------|-------------|---------------|
| `/feed` | All oracle internal messages | ❌ NONE |
| `/pending` | Personal questions + context | ❌ NONE |
| `/email` | Email categorization | ❌ NONE |
| `/calendar` | Schedule + appointments | ❌ NONE |
| `/line` | LINE chat summary | ❌ NONE |
| `/oracles` | Active oracle status | ❌ NONE |
| `/aia-summary` | AIA insurance summary | ❌ NONE |
| `/tasks` | Task aggregation | ❌ NONE |
| `/welcome` | Daily briefing | ❌ NONE |
| `/achievements` | Team stats | ❌ NONE |
| `/claude-usage` | API usage | ❌ NONE |
| `/finance` | **Full financial data** | ⚠️ PIN only |

**Anyone who can reach port 3460 can read everything except finance (which has a bypassable PIN).**

---

## Q5: แนะนำ Hardening

### P0 — ทำทันที (1-2 ชั่วโมง)

| # | Item | Fix | Effort |
|---|------|-----|--------|
| 1 | **CORS restrict** | `cors({ origin: ['http://vuttihome.thddns.net:3460'] })` | 5 min |
| 2 | **Rate limit /finance/unlock** | Max 5 attempts per 5 min, then lockout | 30 min |
| 3 | **Remove PIN from frontend .env** | PIN validation server-side only, remove `VITE_FINANCE_PIN` | 15 min |
| 4 | **Hash stored PIN** | bcrypt hash in pin file, not plaintext | 30 min |

### P1 — ทำสัปดาห์นี้ (4-6 ชั่วโมง)

| # | Item | Fix | Effort |
|---|------|-----|--------|
| 5 | **Add Bearer token auth** | Generate API key, require on all endpoints | 2 hrs |
| 6 | **HTTPS** | Cloudflare Tunnel or Caddy reverse proxy | 1 hr |
| 7 | **Encrypt cache files** | AES-256 encrypt `/tmp/pa-dashboard-*.json` | 2 hrs |
| 8 | **Access logging** | Log every request (endpoint, IP, timestamp) | 1 hr |

### P2 — ถัดไป (nice to have)

| # | Item | Fix | Effort |
|---|------|-----|--------|
| 9 | **Replace PIN with OTP** | Time-based OTP (TOTP) for finance access | 4 hrs |
| 10 | **Move data from /tmp** | Use `~/.pa-data/` with 600 permissions | 30 min |
| 11 | **Input validation** | Validate all POST body size + content | 1 hr |
| 12 | **Cache expiration** | Auto-delete stale cache files (>24h) | 30 min |

### Quick Win: Minimal Hardening (15 minutes)

```typescript
// dashboard-api.ts — add these 3 lines:

// 1. Restrict CORS
app.use("/*", cors({ origin: ['http://vuttihome.thddns.net:3460'] }))

// 2. Add API key middleware (add to all routes)
const API_KEY = process.env.DASHBOARD_API_KEY || crypto.randomUUID()
app.use("/*", async (c, next) => {
  const key = c.req.header('x-api-key') || new URL(c.req.url).searchParams.get('key')
  if (!key || key !== API_KEY) return c.json({ error: 'Unauthorized' }, 401)
  await next()
})

// 3. Rate limit finance unlock
const attempts = new Map<string, { count: number; resetAt: number }>()
// ... (in /finance/unlock handler, check attempts)
```

---

## Risk Assessment

| Scenario | Likelihood | Impact | Risk |
|----------|-----------|--------|------|
| Someone finds DDNS URL + reads /feed, /pending | MEDIUM | HIGH | 🔴 |
| PIN brute-force → finance data exposed | HIGH | CRITICAL | 🔴 |
| MITM on HTTP → intercept all data | LOW (home network) | CRITICAL | 🟡 |
| CORS abuse → malicious site reads data | LOW | HIGH | 🟡 |
| /tmp file read by other process | LOW | HIGH | 🟡 |

**Overall**: This is a **personal** dashboard (single user), so attack surface is smaller than a public app. But the financial data sensitivity is HIGH. The main risks are:
1. PIN is effectively public (in JS build)
2. All non-finance endpoints have zero auth
3. HTTP means no transport encryption

---

🔒 Security-Oracle — Personal Dashboard Audit Complete
*"A personal safe needs a real lock, not a sticky note with the combination."*
