# 3 Commitments — 2026-03-29 Self-Improvement

**Source**: แบงค์ ordered self-improve review of all retros + learnings

## Patterns Found

1. **Knowing-doing gap**: Same lesson ("commit at session end") written 3 times across 6 days before being acted on
2. **Duplicate learnings**: 4 pairs of near-identical files — writing without checking existing
3. **No CRITICAL follow-up**: Handoff markdown has no enforcement. ElevenLabs key 3 days pending
4. **RLS Watchdog is core strength**: Both migration-based and direct SQL audits produce real findings

## 3 Commitments

### 1. COMMIT + PUSH every session — no exceptions
The lesson was written 3 times. Now it's a mechanical rule: before /rrr, run `git status`. If anything exists → commit + push. Don't write another learning about it. Just do it.

### 2. CRITICAL findings get oracle threads, not just markdown
When a finding is CRITICAL: create or update an oracle thread, /talk-to the responsible oracle, and set a conditional loop to check status. A handoff file is documentation, not tracking.

**Applied today**: Follow up on ElevenLabs key rotation (3 days) + quiz_sessions RLS fix.

### 3. CHECK before WRITE — zero duplicate learnings
Before writing a new learning, grep existing learnings for the same topic. If it exists, update it or don't write. Clean up the 4 existing duplicates today.
