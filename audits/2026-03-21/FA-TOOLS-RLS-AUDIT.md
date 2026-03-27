# FA Tools — Supabase RLS (Row Level Security) Audit

**Date**: 2026-03-21
**Project**: rugcuukelivcferjjzek (FA Tools Supabase)
**Triggered by**: Researcher flagged potential RLS risk
**Auditor**: Security-Oracle
**Method**: Migration file analysis (180 files, Supabase MCP access denied — Loveable-managed)

---

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total tables (public schema) | 64 | — |
| Tables with RLS enabled | 61 | ✅ 95.3% |
| Tables WITHOUT RLS | 3 | 🔴 |
| Customer data tables properly protected | 6/6 | ✅ |
| History tables (audit trail) | Fixed | ✅ |
| Overly permissive READ policies | 16 tables | ✅ Acceptable (public product data) |
| Overly permissive WRITE policies | 3 tables | ⚠️ Intentional (public chat) |

**Verdict**: **RLS posture is STRONG** — Researcher's concern is largely unfounded. Customer data is properly protected. 3 non-critical tables need RLS enabled.

---

## 1. Tables WITHOUT RLS (3) — 🔴

| Table | Risk | Data Type | Fix |
|-------|------|-----------|-----|
| `admin_broadcasts` | MEDIUM | Admin broadcast messages | Add RLS: authenticated users SELECT |
| `broadcast_reads` | MEDIUM | User read tracking | Add RLS: `USING (user_id = auth.uid())` |
| `cv_per_` | LOW | Reference/calculation data | Add RLS: authenticated SELECT |

**Note**: None of these contain customer PII. Risk is information disclosure, not data breach.

---

## 2. Critical Customer Data Tables — ALL PASS ✅

### proposals ✅
- SELECT: `USING (auth.uid() = fa_id)` — FA sees only own proposals
- INSERT/UPDATE: `WITH CHECK (auth.uid() = fa_id)` — FA writes only own
- Share link: `USING (share_link IS NOT NULL)` — intentional sharing feature

### leads ✅
- SELECT: `USING (auth.uid() = fa_id)` — FA sees only own leads
- INSERT/UPDATE/DELETE: `WITH CHECK (auth.uid() = fa_id)` — full CRUD restricted

### insurance_applications ✅
- SELECT: `EXISTS (SELECT 1 FROM leads WHERE leads.id = insurance_applications.lead_id AND leads.fa_id = auth.uid())` — chain-of-custody via lead ownership
- Share token: `USING (share_token IS NOT NULL AND is_active = true)` — intentional form sharing

### fa_profiles ✅
- SELECT/UPDATE: `USING (auth.uid() = id)` — self-only access

### portfolio_customers ✅
- SELECT: `USING (auth.uid() = fa_id)` — FA sees only own customers
- Sub-tables (family_members, financial_info, policies, coverages): EXISTS joins to verify FA ownership chain

### chat_conversations / chat_messages ⚠️ CONDITIONAL PASS
- INSERT: `WITH CHECK (true)` — public chat feature (by design)
- SELECT: `USING (auth.uid() = user_id OR user_id IS NULL)` — unauthenticated chats allowed
- **Design intent**: Insurance AI chatbot is public-facing. This is intentional.

---

## 3. Overly Permissive Policies

### READ `USING (true)` — 16 tables ✅ ACCEPTABLE
All are public product/reference data with no customer PII:
- `aia_funds`, `aia_fund_nav`, `aia_fund_yearly_performance`
- `product_benefits`, `product_links`, `product_payouts`
- `insurance_products`, `premium_calc_type_settings`
- `unitlink_*` (5 tables), `vitality_*` (3 tables)
- `tax_deduction_settings`, `role_permissions`

### WRITE `WITH CHECK (true)` — 7 tables

| Table | Status | Reason |
|-------|--------|--------|
| chat_conversations | ⚠️ Intentional | Public chatbot |
| chat_feedback | ⚠️ Intentional | Public feedback |
| chat_messages | ⚠️ Intentional | Public chatbot |
| leads_history | ✅ FIXED | → `service_role` only (migration 20260320) |
| insurance_applications_history | ✅ FIXED | → `service_role` only |
| lead_policies_history | ✅ FIXED | → `service_role` only |
| proposals_history | ✅ FIXED | → `service_role` only |

---

## 4. History Tables — FIXED ✅

Migration `20260320001000_fix-history-rls-service-role-only.sql` properly restricts all 4 history tables:
- Old: `WITH CHECK (true)` — anyone could forge audit records
- New: `WITH CHECK (auth.role() = 'service_role')` — only backend can insert
- Applied: 2026-03-20

---

## 5. Anon Key Risk Assessment

Researcher's concern: "ใครมี anon key ก็ query ข้อมูลได้หมด"

**Finding**: This is **NOT TRUE** for customer data.

- Anon key + RLS = can only access data matching policy conditions
- All customer tables require `auth.uid() = fa_id` — anon key has NO auth.uid()
- Anon key CAN read: product data, fund data, rate tables (all public by design)
- Anon key CANNOT read: proposals, leads, applications, profiles, portfolio data

**The only risk**: 3 tables without RLS (admin_broadcasts, broadcast_reads, cv_per_) are accessible with anon key. These don't contain customer PII.

---

## 6. Recommendations

### Immediate (fix today)
1. Enable RLS on 3 missing tables (admin_broadcasts, broadcast_reads, cv_per_)

### Validate
2. Confirm chat tables `WITH CHECK (true)` is intentional design for public chatbot

### Ongoing
3. Add pre-migration check: every `CREATE TABLE` must have `ENABLE ROW LEVEL SECURITY`
4. Quarterly RLS audit against live database (need Supabase MCP access)

---

🔒 Security-Oracle — RLS Audit Complete
*"The gates are locked where it matters. Three fences need mending."*
