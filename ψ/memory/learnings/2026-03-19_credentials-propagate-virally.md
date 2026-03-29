# Lesson: Credentials Propagate Virally

**Date**: 2026-03-19
**Source**: First Full Security Audit of BoB's Office

## Pattern

A single leaked credential will spread to every system that touches it — git history, communication logs, documentation, training data, and even audit reports. Containment must be faster than propagation.

## Evidence

One password was found in:
1. AIA-Knowledge git history (2 files)
2. feed.log (5+ entries via maw-hey broadcast)
3. maw-log.jsonl (5 entries)
4. Security-Oracle's own learning file (documenting the finding)

Timeline: password committed → broadcast via inter-oracle comms → logged in feed → documented in audit → 4 separate exposure vectors in days.

## Rules

1. **Always [REDACTED] in documentation** — never include real credentials, even in internal audit findings
2. **Policy in comments ≠ enforcement** — "never commit to GitHub" written in source code did nothing. Only .gitignore + pre-commit hooks + automated scanning = actual policy
3. **Containment = rotate + purge + prevent** — rotating the password alone is insufficient if it's in git history, logs, and docs
4. **The auditor is a leak vector** — security documentation creates new copies of the secret being documented
5. **Communication channels are storage** — maw-hey, feed.log, Oracle threads all persist. Credentials sent via chat are credentials committed to a log file

## Application

- Pre-commit hooks with gitleaks/truffleHog on all repos
- PII/secret filtering on feed-hook before logging
- Policy: credentials shared ONLY via .env files or secrets manager, NEVER via any communication channel
- Audit reports always use [REDACTED] for actual values
