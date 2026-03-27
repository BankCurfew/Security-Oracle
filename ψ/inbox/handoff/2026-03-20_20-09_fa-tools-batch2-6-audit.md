# Handoff: FA Tools Batch 2-6 Audit

**Date**: 2026-03-20 20:09 GMT+7
**From**: Security-Oracle Session 3
**Context**: 85% — deep in FA Tools remaining remediation tracking

## What We Did
- /recap orientation — read handoff, checked all active/pending threads
- Thread scan: QA P0 to FE (3/4 already fixed), Admin feed.log overdue 24h+
- FA Tools R5 scan: all 11 remaining items from Master Remediation (batches 2-6)
- Verified R4 items still hold: CORS, JWT, auth, CSP, password, ProtectedRoute all ✅
- R5 report written: 8 FAIL / 2 PARTIAL / 1 PASS
- Notified FE (thread #106), cc'd BoB (thread #6 msg #689), followed up Admin (thread #107)

## Pending

### FA Tools Batch 2-6 (waiting on FE)

| # | Item | Status | Owner |
|---|------|--------|-------|
| 7 | PII encryption (names/phone/email plaintext) | ❌ FAIL | FE |
| 11 | Rate limiting (14/16 functions) | ❌ FAIL | FE |
| 12 | npm deps (5 HIGH — xlsx no fix) | ⚠️ PARTIAL | FE |
| 13 | Privacy policy page | ❌ FAIL | FE |
| 14 | Customer data access/export API | ❌ FAIL | FE |
| 16 | Encryption key rotation | ❌ FAIL | FE |
| 17 | Breach notification protocol | ❌ FAIL | Security + FE |
| 18 | DELETE policies (39 tables) | ⚠️ PARTIAL | DBA |
| 19 | Replace xlsx library | ❌ FAIL | FE |
| 20 | HTTPS self-hosted | ❌ FAIL | Infra |

### Admin — feed.log (overdue)
- [ ] PII sanitize in feed.log — sent follow-up thread #107
- [ ] Log rotation setup

### Self-Service (Security can do alone)
- [ ] .gitignore fix for 5 repos (BoB, Dev, AIA, Admin, Data)
- [ ] Daily security scan loop (`maw loop add`)
- [ ] Pre-commit hooks (gitleaks) across repos

### Carry-forwards from Session 1-2
- [ ] Data-Oracle PII removal (125+ customer records in git) — needs แบงค์ approval
- [ ] Dashboard public repo — Dev fix 4 blocking items, then scan R3
- [ ] Lovable.dev project scan — waiting for Dev to share repo

## Communication State
- FE: thread #106 — R5 batch 2-6 findings sent, waiting ack + timeline
- BoB: thread #6 msg #689 — cc'd R5 results
- Admin: thread #107 — feed.log PII follow-up sent
- QA: thread #69 — note: 3/4 of their P0 items already fixed by FE

## Key Files
| File | Purpose |
|------|---------|
| audits/2026-03-20/FA-TOOLS-VERIFICATION-R5-BATCH2-6.md | R5 full report (batches 2-6) |
| audits/2026-03-20/FA-TOOLS-VERIFICATION-R4-FINAL.md | R4 batch 1 PASS |
| audits/2026-03-20/FA-TOOLS-FULL-SECURITY-AUDIT.md | Master audit (20 items) |
| ψ/memory/retrospectives/2026-03/20/14.25_fa-tools-batch2-6-audit.md | Session 3 retro |

## Branch State
- `security/trace-deep-and-onboard` — 14 commits ahead of main, needs merge
- New untracked: R5 report + retro + learnings

## Recommended Next Actions
1. **Check FE thread #106 response** — did they ack R5? timeline for P0 items?
2. **Check Admin thread #107** — feed.log status
3. **Self-service: .gitignore fixes** — can do without waiting for anyone
4. **Self-service: maw loop add** — daily security scan
5. **If FE fixes land** — run R6 verification on batch 2-6 items

---

> "Day 3: The critical gates are locked. Now we reinforce the walls."
> *Security-Oracle — Session 3 complete*
