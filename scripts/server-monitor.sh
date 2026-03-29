#!/bin/bash
# Server Health Monitor — Security-Oracle
# Checks: load, RAM, disk, ports, Chrome processes
# Alerts via feed.log + maw hey bob
#
# Usage: Run via maw loop (every 5 minutes)

FEED_LOG="$HOME/.oracle/maw-log.jsonl"
ALERT_FIRED=false

log_feed() {
  local msg="$1"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  echo "{\"ts\":\"$ts\",\"from\":\"security-monitor\",\"to\":\"bob\",\"target\":\"feed\",\"msg\":\"$msg\",\"host\":\"VuttiServer\",\"sid\":null}" >> "$FEED_LOG"
}

alert_bob() {
  local msg="$1"
  maw hey bob "$msg" 2>/dev/null || true
  ALERT_FIRED=true
}

alerts=""

# 1. Load Average
load=$(awk '{print $1}' /proc/loadavg)
load_int=$(echo "$load" | awk '{printf "%d", $1}')
if [[ "$load_int" -ge 3 ]]; then
  alerts+="🔴 LOAD: $load (threshold: 3.0)\n"
fi

# 2. RAM Usage
ram_info=$(free -m | awk 'NR==2{printf "%d %d %.0f", $3, $2, $3*100/$2}')
ram_used=$(echo "$ram_info" | awk '{print $1}')
ram_total=$(echo "$ram_info" | awk '{print $2}')
ram_pct=$(echo "$ram_info" | awk '{print $3}')
if [[ "$ram_pct" -ge 85 ]]; then
  alerts+="🔴 RAM: ${ram_used}MB/${ram_total}MB (${ram_pct}%, threshold: 85%)\n"
fi

# 3. Disk Usage
disk_pct=$(df -h / | awk 'NR==2{gsub(/%/,""); print $5}')
if [[ "$disk_pct" -ge 80 ]]; then
  disk_info=$(df -h / | awk 'NR==2{print $3"/"$2}')
  alerts+="🔴 DISK: ${disk_info} (${disk_pct}%, threshold: 80%)\n"
fi

# 4. Port checks — :3456 (MAW) and :3460 (Dashboard)
for port in 3456 3460; do
  if ! ss -tlnp | grep -q ":${port} " 2>/dev/null; then
    service_name="MAW Dashboard"
    [[ "$port" == "3460" ]] && service_name="Personal Dashboard"
    alerts+="🔴 PORT $port ($service_name) DOWN!\n"

    # Attempt auto-restart
    if command -v pm2 &>/dev/null; then
      if [[ "$port" == "3456" ]]; then
        pm2 restart maw 2>/dev/null && alerts+="  ↳ Auto-restart: pm2 restart maw attempted\n"
      elif [[ "$port" == "3460" ]]; then
        pm2 restart dashboard 2>/dev/null && alerts+="  ↳ Auto-restart: pm2 restart dashboard attempted\n"
      fi
    else
      alerts+="  ↳ pm2 not found — manual restart needed\n"
    fi
  fi
done

# 5. Chrome/Playwright memory check
chrome_pids=$(pgrep -f 'chrome|chromium|mcp-chrome' 2>/dev/null || true)
if [[ -n "$chrome_pids" ]]; then
  chrome_mem_kb=0
  while IFS= read -r pid; do
    mem=$(awk '/VmRSS/{print $2}' /proc/$pid/status 2>/dev/null || echo 0)
    chrome_mem_kb=$((chrome_mem_kb + mem))
  done <<< "$chrome_pids"
  chrome_mem_mb=$((chrome_mem_kb / 1024))
  chrome_mem_gb=$(echo "scale=1; $chrome_mem_mb / 1024" | bc 2>/dev/null || echo "0")
  chrome_count=$(echo "$chrome_pids" | wc -l)

  if [[ "$chrome_mem_mb" -gt 5120 ]]; then  # > 5GB
    alerts+="🔴 CHROME: ${chrome_count} processes using ${chrome_mem_gb}GB RAM (threshold: 5GB)\n"
    alerts+="  ↳ Cleanup: pkill -f 'mcp-chrome' or close Playwright sessions\n"
  fi
fi

# Report
if [[ -n "$alerts" ]]; then
  header="🚨 SERVER HEALTH ALERT — $(date '+%H:%M %d/%m')"
  status="Load: $load | RAM: ${ram_pct}% | Disk: ${disk_pct}%"
  full_msg="$header\n$status\n\n$(echo -e "$alerts")"
  plain_msg=$(echo -e "$full_msg")
  log_feed "$plain_msg"
  alert_bob "$plain_msg"
  echo -e "$full_msg"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Server healthy — Load: $load | RAM: ${ram_pct}% | Disk: ${disk_pct}%"
fi
