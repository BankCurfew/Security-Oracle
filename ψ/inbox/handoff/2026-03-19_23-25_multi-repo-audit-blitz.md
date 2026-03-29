# Handoff: Multi-Repo Security Audit Blitz

**Date**: 2026-03-19 23:25 GMT+7
**From**: Security-Oracle Session 2
**Context**: 90% — deep in multiple concurrent audits

## What We Did
- Dashboard oracle-v2 source audit — 1 CRITICAL / 4 HIGH / 11 MEDIUM (report v1)
- Dashboard clean public repo audit (BankCurfew/oracle-dashboard) — Conditional PASS, 4 blocking items (report v2)
- FA Tools baseline audit (iagencyaiafatools) — 4 CRITICAL / 9 HIGH / 8 MEDIUM
- FA Tools fix verification — 7 PASS / 14 FAIL → re-verified 2 CRITICAL fixes → CONDITIONAL PASS
- Gemini strategy saved — non-code research → Gemini first (/deep-research, /watch)
- Playwright 2-session limit rule saved
- External URLs documented (vuttihome.thddns.net services)
- PA-Oracle financial email review — SECURITY CLEAR with conditions
- Coordinated with Dev (thread #5), BoB (thread #44)

## Pending

### Dashboard Public Repo (BankCurfew/oracle-dashboard)
- [ ] Dev fix 4 blocking items: Soul-Brews-Studio refs (16 files), bun.lock, H3 auth fail-open, Nat's Agents author
- [ ] Security scan round 3 when fixes land
- [ ] Then: ✅ PASS → publish

### FA Tools (iagencyaiafatools)
- [ ] FE push 2 verified fixes (insurance-chat auth + jspdf) to GitHub
- [ ] แบงค์ rotate Supabase anon key (project rugcuukelivcferjjzek) — in git history
- [ ] FE fix remaining HIGH items:
  - parse-fund-peer-avg auth (can write to DB unauthenticated!)
  - fetch-fund-factsheet auth
  - is_approved enforcement at API/RLS level
  - Hardcoded name in 5 files (อาทิตย์ สกุลเสาวภาคย์กุล)
  - xlsx CVE (no upstream fix — may need replacement)
- [ ] CORS restrict on Edge Functions
- [ ] Password min 6 → 12
- [ ] Security scan round 2 after fixes

### Lovable.dev Project
- [ ] Waiting for Dev to create/share repo → scan when ready

### Session 1 Carry-forwards (Still Pending)
- [ ] Data-Oracle PII removal — 125+ customer records in git (needs แบงค์ approve)
- [ ] Credential rotation — FA Tools password, SUPABASE_SERVICE_KEY, etc.
- [ ] .gitignore fix for 5 repos (BoB, Dev, AIA, Admin, Data)
- [ ] Daily security scan loop (maw loop add)
- [ ] Pre-commit hooks (gitleaks/truffleHog) across all repos

### Infrastructure Security
- [ ] All external services on HTTP (no HTTPS) — MITM risk
- [ ] FA Tools on port 5173 = Vite dev server — should be production build
- [ ] Dashboard login credentials in plaintext memory — periodic rotation needed

## Key Files
| File | Purpose |
|------|---------|
| audits/2026-03-19/DASHBOARD-PUBLIC-REPO-AUDIT.md | Source repo audit (v1) |
| audits/2026-03-19/DASHBOARD-PUBLIC-REPO-AUDIT-v2.md | Clean public repo audit (v2) |
| audits/2026-03-19/FA-TOOLS-BASELINE-AUDIT.md | FA Tools baseline |
| audits/2026-03-19/FA-TOOLS-VERIFICATION.md | FA Tools fix verification |
| ψ/memory/retrospectives/2026-03/19/14.52_session2-multi-repo-audit-blitz.md | Session 2 retro |

## Communication State
- BoB: thread #44 — last msg #402 (FA Tools conditional pass)
- Dev: thread #5 — last msg #398 (waiting for fixes + Lovable repo)
- PA-Oracle: thread #44 msg #382 — email security acknowledged

## Branch State
- `security/trace-deep-and-onboard` — 6 commits ahead of main, needs merge
- Safety guardian hook blocks direct push to main (correct behavior)

---

> "Day 2: The castle has walls, but the gates still need locks."
> *Security-Oracle — Session 2 complete*
