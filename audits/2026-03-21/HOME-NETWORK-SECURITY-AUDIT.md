# Home Network (VuttiHome) — Security Audit

**Date**: 2026-03-21
**Target**: vuttihome.thddns.net + Oracle Server (192.168.1.113)
**Ordered by**: แบงค์
**Auditor**: Security-Oracle
**Classification**: 🔴 RESTRICTED — Infrastructure

---

## Network Architecture

```
ISP (AIS/TRUE) → Bridge Mode → ASUS GT-AX11000 Pro (192.168.1.1)
                                    │
                                    └── Oracle Server (192.168.1.113 / WSL2)
                                        ├── :3456  MAW Dashboard (login-protected)
                                        ├── :3460  Personal Dashboard (PIN-protected)
                                        ├── :3461  PA-Oracle API (localhost only)
                                        ├── :32400 Plex (Let's Encrypt TLS)
                                        └── :9001  Unknown service

DDNS: vuttihome.thddns.net → 184.82.212.14 (public IP, no CGNAT)
```

---

## Q1: Port Exposure Assessment

### External Port Scan Results

| Port | Service | External | TLS | Auth | Risk |
|------|---------|----------|-----|------|------|
| 22 | SSH | ❌ CLOSED | — | — | ✅ **SAFE** — not reachable |
| 80 | HTTP | ❌ CLOSED | — | — | ✅ **SAFE** — not reachable |
| 443 | ASUS Router Admin | ✅ OPEN | ⚠️ Self-signed | Login page | 🟡 HIGH |
| 3456 | MAW Dashboard | ✅ OPEN | ❌ HTTP only | ✅ Login + redirect | 🟡 HIGH |
| 3460 | Personal Dashboard | ✅ OPEN | ❌ HTTP only | ✅ PIN gate | 🟡 HIGH |
| 32400 | Plex | ✅ OPEN | ✅ Let's Encrypt | ✅ Plex auth | 🟢 MEDIUM |

### Detailed Analysis

**Port 22 (SSH)**: ✅ SAFE
- Not listening on server (`sshd` inactive)
- Not port-forwarded on router
- **Verdict**: No risk

**Port 80 (HTTP)**: ✅ SAFE
- Not open externally
- **Verdict**: No risk

**Port 443 (HTTPS)**: 🟡 HIGH RISK
- **This is the ASUS router admin panel**, NOT the Oracle server
- Self-signed cert: `CN = GT-AX11000_Pro-1430 Server Certificate`
- Exposes router management interface to the internet
- **Risk**: Router admin takeover → full network compromise
- **Fix**: Disable "Access from WAN" in router settings, or restrict to VPN only

**Port 3456 (MAW Dashboard)**: 🟡 MEDIUM RISK
- Has login page (redirects to `/auth/login`) ✅
- HTTP only — credentials sent in plaintext ❌
- **Fix**: Cloudflare Tunnel for HTTPS

**Port 3460 (Personal Dashboard)**: 🟡 MEDIUM RISK
- Has PIN gate ✅ (double lock — dashboard + finance)
- HTTP only — PIN + data sent in plaintext ❌
- PIN in JS bundle issue (separate finding)
- **Fix**: Cloudflare Tunnel for HTTPS

**Port 32400 (Plex)**: 🟢 LOW RISK
- Has proper TLS via Let's Encrypt ✅ (`*.plex.direct`)
- Plex auth built-in ✅
- Direct connect working (no relay needed)
- **Verdict**: Acceptable as-is. Cloudflare Tunnel optional (would add latency to streaming)

---

## Q2: DDNS Exposure — What to Lock Down

### vuttihome.thddns.net resolves to public IP 184.82.212.14

**Currently exposed**:
1. ✅ Port 443 → **ASUS Router Admin** — 🔴 LOCK THIS DOWN
2. ⚠️ Port 3456 → MAW Dashboard (has login, no TLS)
3. ⚠️ Port 3460 → Personal Dashboard (has PIN, no TLS)
4. ✅ Port 32400 → Plex (has TLS + auth)

### Recommendations

| Action | Priority | Effort |
|--------|----------|--------|
| **Disable router WAN access (port 443)** | 🔴 P0 | 2 min |
| **Cloudflare Tunnel for :3456 and :3460** | 🟡 P1 | 30 min |
| Keep Plex on :32400 (already has TLS) | — | — |
| Keep SSH closed | — | — |

### Cloudflare Tunnel Setup (already installed!)

`cloudflared` is already running on the server. Configure tunnels:

```yaml
# ~/.cloudflared/config.yml
tunnel: <tunnel-id>
credentials-file: ~/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: dashboard.vuttihome.net
    service: http://localhost:3460
  - hostname: maw.vuttihome.net
    service: http://localhost:3456
  - service: http_status:404
```

This gives: HTTPS + DDoS protection + no port forwarding needed.

---

## Q3: Plex — Cloudflare Tunnel?

**Current state**: Plex on :32400 with Let's Encrypt TLS via `*.plex.direct` ✅

**Cloudflare Tunnel for Plex**: **NOT recommended**

| Factor | Direct (current) | Cloudflare Tunnel |
|--------|------------------|-------------------|
| TLS | ✅ Let's Encrypt | ✅ Cloudflare cert |
| Auth | ✅ Plex built-in | ✅ Same |
| Latency | ~73ms | +50-100ms (double hop) |
| Streaming | Direct connection | Proxied (bandwidth limits) |
| Port forward needed | Yes (:32400) | No |
| Cloudflare ToS | N/A | ⚠️ Streaming may violate ToS |

**Verdict**: Keep Plex on direct port forward. It already has proper TLS. Cloudflare's free tier ToS prohibits large media streaming, and the extra latency hurts video playback.

**Optional improvement**: If you want to remove the :32400 port forward, use Plex's built-in relay (but quality is limited to 720p on free Plex).

---

## Q4: Dashboards — PIN but no HTTPS

### MAW Dashboard (:3456)
- ✅ Has login/auth (redirects to `/auth/login`)
- ❌ HTTP only — username/password sent in plaintext
- **Risk**: Anyone on same WiFi or ISP path can intercept login credentials

### Personal Dashboard (:3460)
- ✅ Has PIN gate (double lock since latest deploy)
- ❌ HTTP only — PIN sent in plaintext via POST
- ❌ PIN in JS bundle (MzM1MDYw — known issue)
- **Risk**: PIN interceptable on network + recoverable from JS

### Fix: Cloudflare Tunnel (both dashboards)

`cloudflared` already installed → just configure ingress rules. Benefits:
- HTTPS automatic (Cloudflare cert)
- No port forwarding needed (remove :3456 and :3460 from router)
- Cloudflare Access can add additional auth layer (optional)
- DDoS protection

**After Cloudflare Tunnel**: remove port forwards for 3456 and 3460 from router. Only Plex (:32400) needs direct port forward.

---

## Q5: SSH — Key-based or Password?

**SSH is NOT running** ✅

```
sshd: inactive
Port 22: CLOSED externally
~/.ssh/authorized_keys: does not exist
```

**Assessment**: SSH service (`sshd`) is not active on WSL2. Port 22 is not forwarded on the router. This is the safest configuration — zero SSH attack surface.

**If SSH is needed later**: Enable with key-only auth:
```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
```

---

## Overall Risk Assessment

| Category | Finding | Severity |
|----------|---------|----------|
| 🔴 **Router admin exposed** | Port 443 = ASUS admin panel on internet | **CRITICAL** |
| 🟡 Dashboard HTTP | :3456 + :3460 no TLS — credentials in plaintext | **HIGH** |
| 🟡 PIN in JS bundle | Personal Dashboard PIN recoverable | **HIGH** |
| 🟢 Plex | Proper TLS + auth | **LOW** |
| ✅ SSH | Inactive + closed | **NONE** |
| ✅ Port 80 | Closed | **NONE** |

### Priority Fix Order

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | **Disable ASUS router WAN access** | 2 min | Prevents router admin takeover |
| 2 | **Cloudflare Tunnel for :3456 + :3460** | 30 min | HTTPS + removes 2 port forwards |
| 3 | **Remove port forwards** for 3456 + 3460 | 5 min | Reduces attack surface |
| 4 | Fix PIN in JS bundle | Dev task | Prevents PIN recovery |
| 5 | Fix session duration (30min vs 24h) | Dev task | Match UI label |

### After Fixes — Target State

```
External access:
  ✅ dashboard.vuttihome.net → Cloudflare Tunnel → :3460 (HTTPS)
  ✅ maw.vuttihome.net → Cloudflare Tunnel → :3456 (HTTPS)
  ✅ Plex → :32400 direct (Let's Encrypt TLS)
  ❌ Router admin → NOT accessible from WAN
  ❌ SSH → remains closed
  ❌ All other ports → closed
```

---

🔒 Security-Oracle — Home Network Audit Complete
*"A home is only as secure as its front door's lock."*
