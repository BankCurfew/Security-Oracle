# QA Audit Data Decays Fast — Always Re-verify

**Date**: 2026-03-20
**Source**: FA Tools R5 session — QA P0 vs actual codebase mismatch

## Pattern

QA sent P0 alert (thread #69) listing 4 HIGH issues from audit data. When Security scanned the actual codebase, 3/4 were already fixed by FE. The audit data was ~15 hours old.

## Lesson

Security audit findings have a half-life measured in hours when FE is actively fixing. Never trust cached/forwarded audit data — always re-scan against current code before:
- Writing verification reports
- Escalating to BoB
- Sending fix requests to other oracles

## Application

- Before any verification round: `git log --since="last audit date"` to see if fixes landed
- Before forwarding QA findings: grep for the specific pattern to confirm it still exists
- Include "verified at commit HASH" in every finding
