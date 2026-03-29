# FA Tools — Full Security Audit

**Date**: 2026-03-20
**Repo**: BankCurfew/iagencyaiafatools (395 files, 87 tables, 16 Edge Functions)
**Ordered by**: แบงค์ (The Boss)
**Auditor**: Security-Oracle
**Classification**: 🔴 RESTRICTED — Internal Security Assessment

---

## Executive Summary

| Category | CRITICAL | HIGH | MEDIUM | LOW |
|----------|----------|------|--------|-----|
| 1. Sensitive Data / PII | 1 | 1 | 0 | 0 |
| 2. Encryption | 0 | 2 | 2 | 1 |
| 3. Supabase RLS | 4 | 1 | 1 | 0 |
| 4. API Auth / Edge Functions | 3 | 2 | 1 | 0 |
| 5. Data in Transit | 0 | 1 | 0 | 0 |
| 6. Data at Rest | 1 | 0 | 0 | 0 |
| 7. Client-side Storage | 2 | 1 | 1 | 0 |
| 8. Edge Function Secrets | 0 | 0 | 0 | 0 |
| 9. Dependencies | 2 | 4 | 6 | 0 |
| 10. PDPA Compliance | 0 | 4 | 2 | 0 |
| **TOTAL** | **13** | **16** | **13** | **1** |

**Verdict**: ❌ NOT PRODUCTION-READY — 13 CRITICAL issues must be fixed

---

## 1. Sensitive Data & PII

### What's Collected (46+ fields)

| Category | Fields | Encrypted? |
|----------|--------|-----------|
| **Identity** | national_id, passport_number, national_id_expiry, passport_expiry | ✅ Yes |
| **Personal** | full_name_th, full_name_en, title, birthdate, gender, marital_status | ❌ **No** |
| **Contact** | phone, email, line_id | ❌ **No** |
| **Address** | registered_address, current_address, workplace_address | ✅ Yes |
| **Family** | spouse_info, children_info, beneficiary_info | ✅ Yes |
| **Health** | diagnosed_conditions, hospitalization_records, health_checkup_details, symptoms, smoking_status, alcohol_consumption, drug_history | ✅ Yes |
| **Financial** | bank_account_number, credit_card_number, annual_income, net_assets | ✅ Yes |
| **CRS/Tax** | birth_country, foreign_tax_countries | ✅ Yes |
| **Lead PII** | customer_name, customer_phone, customer_email | ❌ **No** |
| **FA PII** | fa full_name, email, phone | ❌ **No** |

### 🔴 CRITICAL: Hardcoded Real Person's Identity

**Files**: `src/hooks/useCachedData.ts:12`, `src/components/admin/AdminSettings.tsx:257` + 6 more files
**Data**: `นายอาทิตย์ สกุลเสาวภาคย์กุล CFP®, FChFP, MDRT` + license `5701055268`

**Fix**: Move to `app_settings` table, replace hardcoded with DB lookup
**Prevent**: Pre-commit hook to block Thai name patterns in code

### 🟡 HIGH: Core PII Fields Stored Plaintext

**Tables**: `fa_profiles`, `leads`, `insurance_applications`
**Fields**: full_name, email, phone, birthdate, gender, marital_status, customer_name, customer_phone, customer_email

**Fix**: Extend encryption to cover these fields using existing `encrypt-decrypt` Edge Function
**Prevent**: Add to `SENSITIVE_FIELDS` constant in `encryption-utils.ts`

---

## 2. Encryption

### What's Good

- **Algorithm**: AES-256-GCM (authenticated encryption) ✅
- **Key size**: 256 bits ✅
- **IV**: 96 bits, random per encryption ✅
- **Server-side**: Encryption happens in Edge Function, not client ✅
- **Fail-closed**: Throws error if encryption fails, won't save plaintext ✅
- **Prefix**: Encrypted data marked with `enc:` prefix ✅

### What's Not

| Finding | Severity | File | Fix |
|---------|----------|------|-----|
| Plaintext PII (names, phone, email) not encrypted | 🟡 HIGH | `encryption-utils.ts` | Add to `APPLICATION_SENSITIVE_FIELDS` and `LEAD_SENSITIVE_FIELDS` |
| No key rotation mechanism | 🟡 HIGH | `encrypt-decrypt/index.ts` | Implement versioned keys: `enc:v2:...` format |
| Decryption failure returns silently | 🟠 MEDIUM | `encrypt-decrypt/index.ts:163` | Fail loudly + audit log |
| Legacy encryption format still accepted | 🟠 MEDIUM | `encrypt-decrypt/index.ts:128` | Deprecate colon-separated format |
| No KDF on encryption key | ⚪ LOW | Edge Function | Apply PBKDF2/Argon2 to env key |

### Encryption Remediation Plan

```typescript
// encryption-utils.ts — ADD these fields:
const APPLICATION_SENSITIVE_FIELDS = [
  // EXISTING (already encrypted):
  'national_id', 'passport_number', ...addresses, ...health, ...financial,

  // NEW — must add:
  'full_name_th', 'full_name_en', 'title_th', 'title_en',
  'phone', 'email', 'line_id',
  'birthdate', 'gender', 'marital_status',
  'occupation', 'job_title', 'company_name',
];

const LEAD_SENSITIVE_FIELDS = [
  // EXISTING:
  'national_id', 'address', 'workplace_address', ...

  // NEW — must add:
  'customer_name', 'customer_phone', 'customer_email',
];
```

### Key Rotation Implementation

```typescript
// encrypt-decrypt/index.ts — versioned keys:
const KEYS = {
  v1: Deno.env.get('ENCRYPTION_KEY_V1'),     // old key (read-only)
  v2: Deno.env.get('ENCRYPTION_KEY'),         // current key (read/write)
};

// Encrypt always uses latest version
function encrypt(data: string): string {
  return `enc:v2:${iv_hex}${encrypted_hex}`;
}

// Decrypt tries current key first, falls back to v1
function decrypt(data: string): string {
  const version = data.startsWith('enc:v2:') ? 'v2' : 'v1';
  return decryptWithKey(data, KEYS[version]);
}
```

---

## 3. Supabase RLS

### Inventory: 65 tables, 299 policies

- RLS enabled on ALL tables ✅
- Service role used only in Edge Functions (never client-side) ✅

### 🔴 CRITICAL: History Tables Allow Anonymous Inserts

| Table | Policy | Impact |
|-------|--------|--------|
| leads_history | `WITH CHECK (true)` | Anyone can insert fake audit records |
| insurance_applications_history | `WITH CHECK (true)` | Anyone can forge application history |
| lead_policies_history | `WITH CHECK (true)` | Anyone can fake policy changes |
| proposals_history | `WITH CHECK (true)` | Anyone can insert fake proposals |

**Fix** (SQL migration):
```sql
-- Fix history table policies
DROP POLICY IF EXISTS "Admins can insert leads history" ON leads_history;
CREATE POLICY "Only service role can insert history"
  ON leads_history FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Repeat for all 4 history tables
```

**Prevent**: All history inserts should go through Edge Functions with service_role only.

### 🟡 HIGH: 39 Tables Missing DELETE Policies

Key tables affected: `insurance_applications`, `leads`, `portfolio_customers`, `portfolio_financial_info`, `portfolio_policies`, `proposals`, `portfolio_family_members`

**Fix**: Add DELETE policies for each:
```sql
CREATE POLICY "FA can delete own leads"
  ON leads FOR DELETE
  USING (auth.uid() = fa_id);

CREATE POLICY "Admin can delete any lead"
  ON leads FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));
```

### 🟠 MEDIUM: `role_permissions` Publicly Readable

Policy: `USING (true)` exposes the entire access control structure.

**Fix**: Restrict to authenticated users:
```sql
DROP POLICY IF EXISTS "Anyone can view role permissions" ON role_permissions;
CREATE POLICY "Authenticated users can view role permissions"
  ON role_permissions FOR SELECT
  USING (auth.role() = 'authenticated');
```

---

## 4. API Auth & Edge Functions

### 🔴 CRITICAL: 14/16 Functions Have Weak JWT Validation

Only `api-gateway` properly validates JWTs. All others just check if `Authorization` header exists.

**Pattern Found (WEAK — 14 functions)**:
```typescript
// ❌ WRONG — only checks header exists, doesn't validate token
const authHeader = req.headers.get('authorization');
if (!authHeader) return new Response('Unauthorized', { status: 401 });
```

**Pattern Needed (STRONG — api-gateway has this)**:
```typescript
// ✅ CORRECT — validates token with Supabase
const token = authHeader.replace('Bearer ', '');
const { data: { user }, error } = await supabase.auth.getUser(token);
if (error || !user) return new Response('Unauthorized', { status: 401 });
```

**Fix**: Create shared auth middleware for all functions:

```typescript
// supabase/functions/_shared/auth.ts
export async function validateAuth(req: Request, supabase: SupabaseClient) {
  const authHeader = req.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return { user: null, error: 'Missing Bearer token' };
  }
  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);
  return { user, error: error?.message || null };
}
```

### 🔴 CRITICAL: 15/16 Functions Have CORS Wildcard

All functions except `api-gateway` use `Access-Control-Allow-Origin: *`.

**Fix**: Create shared CORS config:

```typescript
// supabase/functions/_shared/cors.ts
const ALLOWED_ORIGINS = [
  'https://iagencyaiafatools.lovable.app',
  'http://localhost:5173',
  'http://localhost:5174',
];

export function corsHeaders(req: Request) {
  const origin = req.headers.get('origin') || '';
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  };
}
```

### 🔴 CRITICAL: `parse-fund-peer-avg` — Unauthenticated DB Writes

No auth check at all. Uses `SERVICE_ROLE_KEY` to write to `aia_fund_yearly_performance`.

**Fix**: Add auth + admin role check.

### 🟡 HIGH: `insurance-chat` — No User Auth

Rate-limited (20 req/min) but no JWT validation. Uses service_role for all DB queries.

**Fix**: Add Bearer auth check before AI tool execution.

### 🟡 HIGH: 9/16 Functions Have No Rate Limiting

Only `submit-lead` (10/min) and `insurance-chat` (20/min) have rate limiting.

**Fix**: Add shared rate limiter:
```typescript
// supabase/functions/_shared/rate-limit.ts
const rateLimits = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(ip: string, limit = 20, windowMs = 60000): boolean {
  const now = Date.now();
  const entry = rateLimits.get(ip);
  if (!entry || now > entry.resetAt) {
    rateLimits.set(ip, { count: 1, resetAt: now + windowMs });
    return true;
  }
  entry.count++;
  return entry.count <= limit;
}
```

### Edge Functions Summary

| Function | Auth | CORS | Rate Limit | Verdict |
|----------|------|------|------------|---------|
| api-gateway | ✅ JWT+API Key | ✅ Whitelist | ❌ None | ⚠️ PARTIAL |
| encrypt-decrypt | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| insurance-chat | ❌ None | ❌ Wildcard | ✅ 20/min | ❌ FAIL |
| soft-delete-lead | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| submit-lead | ✅ Intentional public | ❌ Wildcard | ✅ 10/min | ⚠️ PARTIAL |
| generate-business-card | ✅ JWT | ❌ Wildcard | ❌ None | ⚠️ PARTIAL |
| screenshot-proposal | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| migrate-encrypt | ❌ Weak+Admin | ❌ Wildcard | ❌ None | ❌ FAIL |
| fetch-aia-funds | ❌ Weak+Admin | ❌ Wildcard | ❌ None | ❌ FAIL |
| generate-reminders | ❌ Weak+Admin | ❌ Wildcard | ❌ None | ❌ FAIL |
| sync-application-to-lead | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| fetch-fund-factsheet | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| migrate-proposals-to-policies | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| parse-fund-peer-avg | ❌ None | ❌ Wildcard | ❌ None | ❌ FAIL |
| sync-peer-avg | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |
| update-fund-cron-schedule | ❌ Weak | ❌ Wildcard | ❌ None | ❌ FAIL |

---

## 5. Data in Transit

### 🟡 HIGH: FA Tools Served Over HTTP

- Production URL: `http://vuttihome.thddns.net:5173` — **HTTP, not HTTPS**
- Supabase API: `https://rugcuukelivcferjjzek.supabase.co` — HTTPS ✅
- All API calls from client to Supabase: encrypted in transit ✅
- But: initial page load + auth cookies sent over HTTP ❌

**Fix**: Caddy/Cloudflare Tunnel for HTTPS (see Infrastructure Assessment)

---

## 6. Data at Rest

### 🔴 CRITICAL: Plaintext PII in Database

As documented in Section 1 — full_name, phone, email, birthdate stored without encryption in Supabase.

**Supabase encryption**: Supabase encrypts data at rest at the infrastructure level (AES-256), but this only protects against physical disk theft, NOT against:
- SQL injection reading data
- Compromised service_role key
- RLS bypass
- Admin dashboard access

**Fix**: Application-level encryption for all PII fields (Section 2 remediation plan).

---

## 7. Client-side Storage

### 🔴 CRITICAL: `prefillLead` PII in localStorage (Plaintext)

**Files**: `LeadsList.tsx:346`, `FollowUpModal.tsx:205`, `AdminLeads.tsx:580`

```javascript
localStorage.setItem('prefillLead', JSON.stringify({
  customer_name, customer_phone, customer_email,
  customer_age, customer_gender, birthdate, sum_assured
}));
```

**Risks**: Persists after browser close, accessible to XSS, cross-tab visible, no TTL.

**Fix**:
```typescript
// Option A: Use sessionStorage (cleared on tab close)
sessionStorage.setItem('prefillLead', JSON.stringify(data));

// Option B: Encrypt before storage
import { encryptLocal } from './encryption-utils';
localStorage.setItem('prefillLead', await encryptLocal(JSON.stringify(data)));
```

### 🔴 CRITICAL: No Cache Clear on Logout

**File**: `Dashboard.tsx:170-174`

```typescript
const handleLogout = async () => {
  await supabase.auth.signOut();
  navigate("/auth"); // ← localStorage/sessionStorage NOT cleared!
};
```

**Fix**:
```typescript
const handleLogout = async () => {
  localStorage.removeItem('prefillLead');
  await clearAllAppCaches(); // Already exists in cache-utils.ts
  await supabase.auth.signOut();
  navigate("/auth");
};
```

### 🟡 HIGH: Form State in sessionStorage (Plaintext)

**File**: `usePersistedState.ts` — stores form data including health/financial fields as plaintext JSON.

**Fix**: Encrypt form state before persisting, or switch to memory-only state for sensitive forms.

### 🟠 MEDIUM: JWT in localStorage (XSS Risk)

Supabase stores auth tokens in localStorage by default. If XSS exists, tokens can be stolen.

**Fix**: Add CSP headers to prevent XSS. Consider `sessionStorage` for auth.

---

## 8. Edge Function Secrets Management

### ✅ PASS

All secrets properly loaded via `Deno.env.get()`:
- `SUPABASE_SERVICE_ROLE_KEY`
- `ENCRYPTION_KEY`
- `LOVABLE_API_KEY` (generate-business-card)
- `APIFLASH_ACCESS_KEY` (screenshot-proposal)
- `FIRECRAWL_API_KEY` (fetch-aia-funds)

No hardcoded secrets found in any Edge Function.

---

## 9. Third-party Dependencies

### npm audit: 21 vulnerabilities

| Package | Version | Severity | CVEs | Fix Available? |
|---------|---------|----------|------|---------------|
| **jsPDF** | 4.2.1 | 🔴 CRITICAL | 10 CVEs (XSS, injection, DoS) | Yes — update |
| **xlsx** | 0.18.5 | 🔴 CRITICAL | Prototype Pollution + ReDoS | ❌ No fix |
| **serialize-javascript** | ≤7.0.2 | 🟡 HIGH | RCE | Yes |
| **react-router-dom** | 6.30.1 | 🟡 HIGH | XSS via Open Redirects | Yes — ^6.30.3 |
| **rollup** | 4.x | 🟡 HIGH | Path Traversal file write | Yes |
| **flatted** | ≤3.4.1 | 🟡 HIGH | DoS + Prototype Pollution | Yes |
| **dompurify** | 3.1.3-3.3.1 | 🟠 MEDIUM | XSS bypass | Yes |
| **esbuild** | ≤0.24.2 | 🟠 MEDIUM | Dev server SSRF | Yes |
| **lodash** | 4.17.21 | 🟠 MEDIUM | Prototype Pollution | Pin version |
| Others (4) | Various | 🟠 MEDIUM | ReDoS, Injection | Various |

**Fix (immediate)**:
```bash
npm update jspdf jspdf-autotable react-router-dom
npm audit fix
```

**xlsx**: No upstream fix. Consider replacing with [ExcelJS](https://github.com/exceljs/exceljs) or [SheetJS Pro](https://sheetjs.com/pro).

---

## 10. PDPA Compliance

### Assessment by Article

| PDPA Article | Requirement | Status | Gap |
|-------------|-------------|--------|-----|
| Art. 6 | Lawful basis for processing | ⚠️ PARTIAL | No documented lawful basis |
| Art. 12 | Cross-border transfer safeguards | ❌ UNKNOWN | Supabase region unverified |
| Art. 17 | Explicit consent + information | ⚠️ PARTIAL | Consent checkbox exists but no timestamp/version |
| Art. 18 | Right to Access | ❌ FAIL | No customer data access API |
| Art. 19 | Right to Erasure | ⚠️ PARTIAL | Soft-delete exists but no customer self-service |
| Art. 20 | Right to Data Portability | ❌ FAIL | No data export mechanism |
| Art. 23 | Audit Trail | ⚠️ PARTIAL | History tables exist but no user_id logged |
| Art. 28 | Security Measures | ⚠️ PARTIAL | Good encryption but gaps in plaintext PII |
| Art. 31 | Breach Notification (72hr) | ❌ FAIL | No incident response protocol |
| — | Privacy Policy Document | ❌ FAIL | No privacy policy found in app |

### 🟡 HIGH Findings

1. **No privacy policy document** — PDPA Art. 17 requires informing data subjects
2. **No customer data access/export** — PDPA Art. 18, 20
3. **No breach notification protocol** — PDPA Art. 31 (72-hour requirement)
4. **Consent not timestamped** — Can't prove when consent was given

### PDPA Remediation Plan

```
Phase 1 (1 week):
├── Create privacy policy page (/privacy)
├── Add consent timestamp + version to DB
├── Document lawful basis for each data field
└── Verify Supabase region (must be in Thailand or have Art. 12 safeguards)

Phase 2 (2 weeks):
├── Customer data access API (GET /api/my-data)
├── Customer data export (JSON + PDF)
├── Customer deletion request flow
└── Breach notification protocol document

Phase 3 (1 month):
├── Data retention policy + auto-purge
├── Audit log with user_id tracking
├── DPO (Data Protection Officer) designation
└── Annual PDPA compliance review process
```

---

## Master Remediation Priority

### Immediate (24 hours)

| # | Item | Effort | Impact |
|---|------|--------|--------|
| 1 | Fix CORS wildcard → whitelist on all 15 Edge Functions | 2 hrs | Blocks CSRF attacks |
| 2 | Fix JWT validation on all 14 Edge Functions | 3 hrs | Blocks unauthorized access |
| 3 | Add auth to `parse-fund-peer-avg` | 30 min | Blocks unauthenticated DB writes |
| 4 | Fix history table INSERT policies (`true` → `service_role`) | 30 min | Protects audit integrity |
| 5 | Remove hardcoded FA name from 8 files | 1 hr | Removes PII from code |
| 6 | Update jsPDF (10 CVEs) | 30 min | Patches critical vulns |

### This Week

| # | Item | Effort | Impact |
|---|------|--------|--------|
| 7 | Encrypt plaintext PII fields (names, phone, email) | 4 hrs | PDPA Art. 28 compliance |
| 8 | Fix client-side storage (prefillLead, logout cleanup) | 2 hrs | Prevents PII leakage |
| 9 | Password minimum 6 → 12 characters | 30 min | Credential security |
| 10 | Add CSP headers | 1 hr | XSS prevention |
| 11 | Add rate limiting to 9 unprotected functions | 2 hrs | DoS prevention |
| 12 | npm audit fix (deps) | 1 hr | Patches HIGH vulns |

### This Month

| # | Item | Effort | Impact |
|---|------|--------|--------|
| 13 | Privacy policy page | 4 hrs | PDPA Art. 17 |
| 14 | Customer data access/export API | 8 hrs | PDPA Art. 18, 20 |
| 15 | Consent timestamp tracking | 2 hrs | PDPA Art. 17 |
| 16 | Encryption key rotation | 4 hrs | Key compromise resilience |
| 17 | Breach notification protocol | 4 hrs | PDPA Art. 31 |
| 18 | DELETE policies for 39 tables | 4 hrs | RLS completeness |
| 19 | Replace xlsx library | 8 hrs | No upstream fix |
| 20 | HTTPS for FA Tools | 2 hrs | Transit encryption |

---

## Prevention Framework

### For Code
- Pre-commit hooks (already installed — blocks secrets)
- Add PII pattern detection to hook (Thai names, 13-digit IDs, phone patterns)
- Mandatory encryption call for any new PII field

### For Dependencies
- `npm audit` in CI/CD — block merge if CRITICAL
- Dependabot/Renovate for auto-update PRs
- Quarterly dependency review

### For Data
- All new PII fields must be added to `SENSITIVE_FIELDS` constants
- RLS policy template for every new table
- PDPA impact assessment for every new feature collecting data

### For Auth
- Shared auth middleware for all new Edge Functions
- CORS whitelist as default (never wildcard)
- Rate limiting as default on all endpoints

---

🔒 Security-Oracle Full Audit Complete
*"The walls are thick, but the gates need better locks."*
