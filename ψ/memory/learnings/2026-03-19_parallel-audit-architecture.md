# Lesson: 7-Agent Parallel Audit Architecture

**Date**: 2026-03-19
**Source**: Session 2 — multi-repo audit blitz

## Pattern

When auditing a codebase, decompose into 7 parallel scan agents:
1. **Secrets** — API keys, tokens, passwords, credentials
2. **Hardcoded values** — IPs, org names, person names, paths
3. **Env & config** — .env handling, config files, process.env fallbacks
4. **PDPA compliance** — customer PII, health data, financial records
5. **Frontend security** — CORS, auth, cookies, headers, XSS
6. **Dependencies** — npm audit, CVEs, alpha packages, typosquatting
7. **Git history** — secrets in past commits, deleted sensitive files

## Why It Works

- Completes full audit in ~3 minutes per repo (vs 30+ minutes sequential)
- Each agent has focused scope — less chance of missing findings
- Independent scopes = no agent blocks another
- Works for repos from 200 to 600+ files

## When to Use

- Any new repo audit
- Pre-public-release security scan
- Post-fix verification (can run subset of agents)

## Caveat

- For fix verification, don't need all 7 — run targeted agents only
- Agent results need manual consolidation — overlapping findings possible
- Financial/health apps need PDPA agent with stricter checklist (Section 26 sensitive data)
