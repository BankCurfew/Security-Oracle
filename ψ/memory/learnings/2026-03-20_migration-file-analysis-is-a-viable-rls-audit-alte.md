---
title: Migration file analysis is a viable RLS audit alternative when Supabase MCP acce
tags: [rls, supabase, security-audit, migration-analysis]
created: 2026-03-20
source: rrr: Security-Oracle Session 4
project: github.com/bankcurfew/security-oracle
---

# Migration file analysis is a viable RLS audit alternative when Supabase MCP acce

Migration file analysis is a viable RLS audit alternative when Supabase MCP access is blocked. Search CREATE TABLE vs ENABLE ROW LEVEL SECURITY to find gaps, CREATE POLICY + USING/WITH CHECK for policy adequacy. 90% as good as live DB query — blind spot is tables/policies modified outside migrations.

---
*Added via Oracle Learn*
