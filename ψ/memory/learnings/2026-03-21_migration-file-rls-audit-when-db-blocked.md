# Migration File Analysis as RLS Audit Alternative

**Date**: 2026-03-21
**Source**: FA Tools RLS urgent audit — Supabase MCP access denied

## Pattern

When Supabase MCP/SQL access is blocked (e.g., Loveable-managed projects), migration files in `supabase/migrations/` contain the full RLS story. Search for `CREATE TABLE` vs `ENABLE ROW LEVEL SECURITY` to find gaps, and `CREATE POLICY` for policy adequacy.

## Lesson

Migration-based audit is 90% as good as live DB query for RLS verification. The 10% gap: tables created outside migrations (via dashboard) and policies modified after migration. For definitive results, need either Supabase MCP access or Playwright dashboard inspection.

## Application

- Grep `ENABLE ROW LEVEL SECURITY` → count tables with RLS
- Grep `CREATE TABLE.*public\.` → count total tables
- Diff the two lists → tables without RLS
- Grep `USING (true)` and `WITH CHECK (true)` → overly permissive policies
- Cross-reference with sensitive table names (leads, proposals, applications, profiles)
