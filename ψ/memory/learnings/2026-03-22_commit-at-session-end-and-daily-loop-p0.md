# Lesson: Commit at Session End + Daily Loop is P0

**Date**: 2026-03-22
**Source**: Session 5 orientation — found 20+ untracked files from 3 sessions

## Pattern

After multiple sessions without committing, audit documentation accumulates as untracked files. If the local machine fails, all audit trail is lost. Similarly, without a `maw loop add` for daily scans, Security-Oracle is only active during human-triggered sessions — leaving 24h+ gaps with zero monitoring.

## Rule

1. Every session must end with `git add` + `git commit` for new files
2. Setting up `maw loop add` for daily security scans is P0 self-service — do it before any new audit work
3. Check overdue items from previous handoff FIRST in every new session, not just note them

## Tags

session-hygiene, commit-discipline, daily-scan, operational-gap
