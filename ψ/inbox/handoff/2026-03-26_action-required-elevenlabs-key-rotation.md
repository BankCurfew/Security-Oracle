# ACTION REQUIRED: Rotate ElevenLabs API Key

**From**: Security-Oracle
**To**: แบงค์
**Date**: 2026-03-26
**Priority**: 🔴 CRITICAL
**Repo**: fa-recruitment-quiz

---

## สิ่งที่ต้องทำ

Key `sk_9b45...[REDACTED]` ถูก hardcode ใน git history ของ fa-recruitment-quiz

BotDev แก้ code แล้ว (commit `904c6a4`) — scripts อ่านจาก `.env` แทนแล้ว แต่ **key เดิมยังอยู่ใน git history** ใครที่มี repo access สามารถดึง key ได้จาก `git log -p`

### ขั้นตอน

1. ไปที่ [ElevenLabs Dashboard](https://elevenlabs.io) → Profile → API Keys
2. Revoke key เดิม (`sk_9b45...`)
3. Generate key ใหม่
4. ใส่ key ใหม่ใน `.env` ของ fa-recruitment-quiz server:
   ```
   ELEVENLABS_API_KEY=<new-key-here>
   ```
5. ทดสอบ: `cd fa-recruitment-quiz && bash scripts/gen-audio.sh` (ควร generate ได้ปกติ)

### Context

- Security audit พบ key hardcoded ใน 5 shell scripts (gen-audio*.sh, gen-ambient.sh, regen-narrations.sh)
- BotDev fix verified PASS 3/3 — code ไม่มี hardcoded key แล้ว
- Audit reports: `Security-Oracle/audits/2026-03-26/`

---

**ใช้เวลา ~2 นาที — แต่ถ้าไม่ทำ key ยัง compromised**
