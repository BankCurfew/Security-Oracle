---
title: Security changes (RLS tightening, auth requirements) must be checked against pub
tags: [security-audit, public-flows, rls, auth, incident-learning]
created: 2026-03-21
source: incident: FA Tools customer form blocked by security migration
project: github.com/bankcurfew/iagencyaiafatools
---

# Security changes (RLS tightening, auth requirements) must be checked against pub

Security changes (RLS tightening, auth requirements) must be checked against public-facing flows before deployment. Incident: encrypt-decrypt got auth requirement → broke customer application form submission. Fix: encrypt stays public (forms need it), decrypt requires auth (protects data). Always check: /apply/:shareToken, /icompare/:token, /submit-lead, encrypt-decrypt before recommending auth changes.

---
*Added via Oracle Learn*
