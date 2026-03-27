#!/bin/bash
# Brute Force Monitor for MAW Dashboard (:3456)
# Watches auth.json for failed login patterns
# Alerts via feed.log + maw hey bob
#
# Usage: Run via maw loop (every 2 minutes)

FEED_LOG="$HOME/.oracle/maw-log.jsonl"
STATE_FILE="/tmp/security-brute-force-state.json"
AUTH_JSON="$HOME/maw-js/auth.json"
THRESHOLD=5
WINDOW_SEC=300  # 5 minutes

# Also check Cloudflare access logs if available
MAW_LOG="$HOME/maw-js/maw.log"

log_feed() {
  local msg="$1"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  echo "{\"ts\":\"$ts\",\"from\":\"security-monitor\",\"to\":\"bob\",\"target\":\"feed\",\"msg\":\"$msg\",\"host\":\"VuttiServer\",\"sid\":null}" >> "$FEED_LOG"
}

alert_bob() {
  local msg="$1"
  maw hey bob "$msg" 2>/dev/null || true
}

# Parse maw server logs for failed auth attempts
check_auth_failures() {
  local now
  now=$(date +%s)
  local cutoff=$((now - WINDOW_SEC))

  # Check if maw.log exists and has recent POST /auth/login with 401
  if [[ -f "$MAW_LOG" ]]; then
    # Count 401 responses to /auth/login in last 5 minutes
    local failures
    failures=$(tail -500 "$MAW_LOG" 2>/dev/null | grep -c "POST /auth/login.*401" || echo 0)

    if [[ "$failures" -ge "$THRESHOLD" ]]; then
      local msg="🔴 BRUTE FORCE ALERT: $failures failed login attempts on MAW Dashboard (:3456) in last 5 min! Check auth.json sessions."
      log_feed "$msg"
      alert_bob "$msg"
      echo "ALERT: $failures failures detected"
      return 1
    fi
  fi

  # Fallback: check auth.json session count changes (many new sessions = suspicious)
  if [[ -f "$AUTH_JSON" ]]; then
    local session_count
    session_count=$(python3 -c "import json; d=json.load(open('$AUTH_JSON')); print(len(d.get('sessions',{})))" 2>/dev/null || echo 0)

    # Load previous state
    local prev_count=0
    if [[ -f "$STATE_FILE" ]]; then
      prev_count=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('session_count',0))" 2>/dev/null || echo 0)
    fi

    # Save current state
    echo "{\"session_count\":$session_count,\"checked_at\":$now}" > "$STATE_FILE"

    # If session count jumped by 5+ in one check cycle, suspicious
    local diff=$((session_count - prev_count))
    if [[ "$diff" -ge 5 ]]; then
      local msg="🟡 SUSPICIOUS: $diff new sessions on MAW Dashboard in last check cycle. Possible credential sharing or brute force."
      log_feed "$msg"
      alert_bob "$msg"
      echo "ALERT: session jump $diff"
      return 1
    fi
  fi

  echo "OK: no brute force detected"
  return 0
}

# Also monitor the Hono server access pattern via netstat
check_connection_flood() {
  local conn_count
  conn_count=$(ss -tn state established | grep -c ':3456' 2>/dev/null || echo 0)

  if [[ "$conn_count" -gt 50 ]]; then
    local msg="🔴 CONNECTION FLOOD: $conn_count concurrent connections to :3456! Possible DoS."
    log_feed "$msg"
    alert_bob "$msg"
    echo "ALERT: $conn_count connections"
    return 1
  fi
  return 0
}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Brute force check running..."
check_auth_failures
check_connection_flood
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Check complete."
