# FA Recruitment Quiz — Full Security Audit

**Date**: 2026-03-28
**Auditor**: Security-Oracle
**Requested by**: BoB
**Project**: fa-recruitment-quiz
**Production**: quiz.vuttipipat.com
**Supabase**: tekvqbbjsfncwbdsvrfw
**Framework**: React 19 + TypeScript + Vite + Supabase

---

## Executive Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH | 3 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **10** |

**Verdict**: FAIL — 2 CRITICAL findings must be fixed before production use.

---

## 1. RLS Policies

### Tables Audited

All 4 quiz tables have RLS **enabled**:

| Table | RLS | INSERT | SELECT | UPDATE | DELETE |
|-------|-----|--------|--------|--------|--------|
| quiz_sessions | ON | anon: true | admin only | **anon: true (ALL ROWS)** | none |
| quiz_answers | ON | anon: true | admin only | none | none |
| quiz_events | ON | anon: true | admin only | none | none |
| quiz_admin_users | ON | super_admin only | admin + own record | super_admin only | none |

### Finding 1: CRITICAL — quiz_sessions UPDATE allows anon to modify ANY row

**Policy**: `"Allow anonymous update"` — `qual = true, with_check = true`

Any anonymous user with the Supabase anon key can UPDATE any column on ANY quiz_sessions row. This means:

- **PII tampering**: Attacker can overwrite first_name, last_name, phone, line_id, birthday on any session
- **Score manipulation**: Can change dimension_scores, card_id, tier, work_mode
- **Data integrity**: Can set completed_at, share_token, etc.

**Attack vector**: Knowing or brute-forcing a session UUID (v4 UUIDs, but still):
```javascript
supabase.from('quiz_sessions').update({ first_name: 'HACKED' }).eq('id', 'any-session-uuid')
```

**Fix**: Restrict UPDATE to own session only. Add session ownership check:
```sql
DROP POLICY "Allow anonymous update" ON quiz_sessions;
CREATE POLICY "Allow session owner update" ON quiz_sessions
  FOR UPDATE USING (id = current_setting('request.headers')::json->>'x-session-id')
  WITH CHECK (true);
```

Or simpler — use visitor_id:
```sql
CREATE POLICY "Allow own session update" ON quiz_sessions
  FOR UPDATE USING (visitor_id = (current_setting('request.headers')::json->>'x-visitor-id')::uuid)
  WITH CHECK (true);
```

**Alternative (recommended)**: Since sessions are identified by UUID stored in localStorage, the simplest safe approach is a server-side function:
```sql
CREATE OR REPLACE FUNCTION update_quiz_session(session_uuid UUID, updates JSONB)
RETURNS void AS $$
  -- Validate and update specific columns only
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Finding 2: HIGH — No anon SELECT on quiz_sessions breaks share flow

**Impact**: The share link feature reads `card_id, dimension_scores` via:
```typescript
sb.from('quiz_sessions').select('card_id, dimension_scores').eq('share_token', hash)
```

But the only SELECT policy requires `is_quiz_admin(auth.uid())`. **Anonymous users cannot read shared results.**

**Fix**: Add a limited anon SELECT policy for share_token lookups:
```sql
CREATE POLICY "Allow share token lookup" ON quiz_sessions
  FOR SELECT USING (share_token IS NOT NULL AND share_token = current_setting('request.query')::json->>'share_token');
```

Or simpler:
```sql
CREATE POLICY "Allow public read via share_token" ON quiz_sessions
  FOR SELECT USING (share_token IS NOT NULL);
```
Note: This exposes card_id + dimension_scores for any session with a share_token. Since share_tokens are random, this is acceptable risk. But restrict columns via a view or RPC function for better security.

### quiz_answers & quiz_events: PASS

- anon INSERT only (no read, no update, no delete)
- Admin SELECT via `is_quiz_admin()` function
- No data leakage risk

### quiz_admin_users: PASS

- SELECT: approved admins see all, users see own record only
- INSERT/UPDATE: super_admin only
- No privilege escalation path

---

## 2. Secrets in Code

### Finding 3: HIGH — ElevenLabs API key needs rotation

| Key | Location | Status |
|-----|----------|--------|
| `sk_9b45...` (old) | git history | In history since commit f389686, removed in 904c6a4. **Must rotate on ElevenLabs dashboard** |
| `sk_bcc0...` (current) | `.env` on disk | Active key. .gitignore covers .env (added in 904c6a4). NOT in git. |
| Supabase anon key | `.env` + client bundle | Expected — anon keys are public by design |

**Status**:
- .gitignore: correctly covers `.env`, `.env.local`, `.env.*.local`
- Shell scripts (5): All read from `$ELEVENLABS_API_KEY` env var, no hardcoded keys
- Source code: All use `import.meta.env.VITE_*` — correct

**Action needed**: Rotate old key `sk_9b45...` on ElevenLabs dashboard (handoff created 2026-03-26, still pending).

---

## 3. Supabase Anon Key Exposure

**Status**: EXPECTED — anon key is embedded in client-side Vite bundle (`import.meta.env.VITE_SUPABASE_ANON_KEY`). This is by design for Supabase client-side access.

**RLS must protect**: The anon key gives INSERT and UPDATE access to quiz_sessions (see Finding 1). RLS is the only defense.

**Current gap**: UPDATE policy on quiz_sessions is wide open (Finding 1 — CRITICAL).

---

## 4. Input Validation

### Finding 4: MEDIUM — No input format validation

**File**: `src/components/ShareModal.tsx` (lines 76-83)

Validation only checks for empty fields:
```typescript
if (!info.firstName.trim()) e.firstName = true
if (!info.lastName.trim()) e.lastName = true
if (!info.phone.trim() && !info.lineId.trim()) e.contact = true
```

| Field | Validation | Risk |
|-------|-----------|------|
| first_name | Non-empty only | No format check |
| last_name | Non-empty only | No format check |
| phone | Non-empty (if no LINE ID) | No Thai phone format validation |
| line_id | Non-empty (if no phone) | No format check |
| birthday | Date picker | Browser-enforced only |

**SQL injection**: NOT a risk — Supabase client uses parameterized queries throughout.

**XSS**: NOT a risk — React auto-escapes all rendered output. No `dangerouslySetInnerHTML` found anywhere in codebase.

**Recommendation**: Add phone format validation (`/^0[0-9]{8,9}$/`) and reasonable length limits. Low urgency — no injection vector exists.

---

## 5. Admin Auth

### Admin authentication flow:

1. Supabase Auth (email/password) via `supabase.auth.signInWithPassword()`
2. Check `quiz_admin_users` table: `auth_user_id = session.user.id`
3. Require `status === 'approved'`
4. Route guard in `AdminApp.tsx`: no user = show login page

### Finding 5: MEDIUM — Client-side only route protection

**File**: `src/admin/AdminApp.tsx` (lines 15-34)

Admin routes are protected by React component logic only. No server-side middleware.

**Mitigation**: Since all data access goes through Supabase RLS (which requires `is_quiz_admin(auth.uid())`), a client-side bypass would only show empty UI — no data would be returned. **Effective security is enforced at the database level.**

**Privilege escalation**: NOT possible. Even if a regular authenticated user navigates to `/admin`, the `quiz_admin_users` table check and RLS policies prevent data access.

### Admin functions: PASS

```sql
is_quiz_admin(user_id) → checks quiz_admin_users WHERE status = 'approved'
is_quiz_super_admin(user_id) → checks quiz_admin_users WHERE status = 'approved' AND role = 'super_admin'
```

Properly scoped. No bypass vector found.

---

## 6. PDPA Compliance

### Finding 6: CRITICAL — No consent notice for PII collection

**PII collected in quiz_sessions**:

| Field | Data Type | PDPA Category |
|-------|-----------|---------------|
| first_name | text | Personal identifier |
| last_name | text | Personal identifier |
| phone | text | Contact info |
| line_id | text | Contact info |
| birthday | date | Personal identifier |
| latitude/longitude | double | Location data |
| geo_accuracy | double | Location data |
| ip_city/ip_region/ip_country/ip_district | text | Location data |
| user_agent | text | Device fingerprint |
| screen_width/screen_height | integer | Device fingerprint |
| device_type | text | Device fingerprint |
| visitor_id | uuid | Tracking identifier |

**No consent mechanism found**:
- No privacy policy page or link
- No consent checkbox before data collection
- No data collection disclosure
- No data retention policy
- No right-to-access or right-to-delete notice
- Geolocation uses browser permission (OK) but falls back to IP-based lookup without notice

**Thai PDPA requires** (Section 19, 23, 24):
1. Explicit, informed consent before collecting personal data
2. Clear statement of purpose
3. Data subject rights notice (access, correction, deletion, portability)
4. Data retention period disclosure

**Recommendation**: Add a consent screen before the share/info form showing:
- What data is collected and why
- How long it's retained
- Rights to access/delete
- Contact info for data controller

### Finding 7: MEDIUM — CSV export has no audit trail

**File**: `src/admin/pages/ProspectTable.tsx` (lines 108-131)

Admin can export all PII as plain CSV. No logging of who exported or when. Under PDPA, data controller must track access to personal data.

---

## Additional Findings

### Finding 8: LOW — No DELETE policies on any table

No RLS DELETE policies exist. This means no one (not even admins) can delete rows via the API. Data deletion for PDPA right-to-erasure requests would require direct database access.

### Finding 9: LOW — quiz_events metadata is untyped JSONB

`quiz_events.metadata` is JSONB with no schema validation. Could store arbitrary data. Low risk since INSERT is the only operation available to anon.

### Finding 10: HIGH — Anon INSERT on quiz_events allows analytics spam

`quiz_events` INSERT policy is `with_check = true`. An attacker could flood the events table with garbage data, polluting analytics and potentially causing storage issues.

**Mitigation**: Add rate limiting or a session existence check:
```sql
CREATE POLICY "Allow insert for valid sessions" ON quiz_events
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM quiz_sessions WHERE id = session_id)
  );
```

---

## Summary Table

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| 1 | CRITICAL | quiz_sessions UPDATE allows anon to modify ANY row (PII + scores) | OPEN |
| 2 | HIGH | No anon SELECT for share_token — share flow broken | OPEN |
| 3 | HIGH | ElevenLabs key sk_9b45... in git history — rotation pending | OPEN (since Mar 26) |
| 4 | MEDIUM | No input format validation (phone, names) | OPEN |
| 5 | MEDIUM | Admin routes client-side only (mitigated by RLS) | ACCEPTABLE |
| 6 | CRITICAL | No PDPA consent notice for PII/location collection | OPEN |
| 7 | MEDIUM | CSV export no audit trail | OPEN |
| 8 | LOW | No DELETE policies (PDPA right-to-erasure blocked) | OPEN |
| 9 | LOW | quiz_events metadata untyped | ACCEPTABLE |
| 10 | HIGH | Anon INSERT spam on quiz_events | OPEN |

---

## Recommended Fix Priority

1. **IMMEDIATE**: Fix quiz_sessions UPDATE policy — restrict to own session
2. **IMMEDIATE**: Add PDPA consent screen before info collection
3. **URGENT**: Rotate ElevenLabs key (pending since Mar 26)
4. **URGENT**: Add share_token SELECT policy to restore share flow
5. **SOON**: Add session validation to quiz_events INSERT
6. **LATER**: Input validation, CSV audit trail, DELETE policies

---

*Security-Oracle — 2026-03-28*
*"Trust, but verify. Then verify again."*
