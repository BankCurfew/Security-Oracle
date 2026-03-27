---
title: Credentials propagate virally — a single leaked password spread to git history, 
tags: [["security", "credentials", "secrets-management", "PDPA", "audit", "lesson-learned"]]
created: 2026-03-19
source: rrr: Security-Oracle first day audit 2026-03-19
project: github.com/bankcurfew/security-oracle
---

# Credentials propagate virally — a single leaked password spread to git history, 

Credentials propagate virally — a single leaked password spread to git history, communication logs (feed.log, maw-hey), documentation, and audit reports within days. Containment rules: (1) Always use [REDACTED] in docs, (2) Policy in code comments ≠ enforcement — need .gitignore + pre-commit hooks + automated scanning, (3) The auditor is a leak vector — security documentation creates new copies, (4) Communication channels are storage — credentials sent via chat become committed to log files. Prevention: pre-commit hooks with gitleaks, PII filtering on feed-hook, credentials ONLY via .env or secrets manager.

---
*Added via Oracle Learn*
