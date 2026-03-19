# Infrastructure Security Assessment

**Date**: 2026-03-20
**Auditor**: Security-Oracle
**Scope**: All external-facing services on vuttihome.thddns.net

---

## Findings

### 🔴 CRITICAL: All Services on HTTP (No HTTPS)

**Affected Services**:
| Service | URL | Risk |
|---------|-----|------|
| Dashboard | http://vuttihome.thddns.net:3456 | Login credentials sent in cleartext |
| Knowledge Graph | http://vuttihome.thddns.net:3000/graph | Data exposed in transit |
| FA Tools | http://vuttihome.thddns.net:5173 | Customer financial data exposed |

**Impact**: Any network observer (ISP, WiFi sniffer, MITM) can:
- Intercept login credentials (bank/maw2026 for Dashboard)
- Read all customer data transmitted to/from FA Tools
- Modify responses in transit (inject malicious JS)

**Recommendation**:
1. Set up reverse proxy (nginx/Caddy) with Let's Encrypt SSL
2. Caddy is simplest — auto-HTTPS with zero config
3. Redirect all HTTP → HTTPS
4. Example Caddy config:
```
vuttihome.thddns.net {
    handle /graph* {
        reverse_proxy localhost:3000
    }
    handle {
        reverse_proxy localhost:3456
    }
}
fatools.vuttihome.thddns.net {
    reverse_proxy localhost:5173
}
```

### 🔴 CRITICAL: FA Tools Running Vite Dev Server in Production

**Port 5173** is the default Vite development server port.

**Risks**:
- Dev server exposes source maps (full source code visible)
- Dev server has no security hardening
- Performance is significantly worse than production build
- Hot Module Replacement (HMR) WebSocket exposed

**Recommendation**:
1. Build production bundle: `bun run build` or `npm run build`
2. Serve `dist/` folder via nginx/Caddy (not Vite)
3. Remove source maps from production

### 🟡 HIGH: Dashboard Credentials Are Weak

- Username: `bank` — predictable
- Password: `maw2026` — short, contains year, guessable
- No MFA
- No session timeout visible

**Recommendation**:
1. Change to strong password (16+ chars, random)
2. Implement session timeout (30 min idle)
3. Consider IP allowlisting if used from fixed locations

### 🟡 HIGH: Dynamic DNS (DDNS) Security

- `vuttihome.thddns.net` uses dynamic DNS
- If DDNS credentials are compromised, attacker can redirect all traffic
- No DNS monitoring in place

**Recommendation**:
1. Secure DDNS credentials (rotate if shared)
2. Monitor DNS resolution changes
3. Consider Cloudflare Tunnel as alternative (free, auto-HTTPS, DDoS protection)

---

## Priority Actions for แบงค์

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | Install Caddy for auto-HTTPS | 30 min | Fixes MITM for all services |
| 2 | Build FA Tools production bundle | 15 min | Closes dev server exposure |
| 3 | Rotate Dashboard password | 5 min | Fixes weak credential |
| 4 | Consider Cloudflare Tunnel | 1 hour | Fixes DDNS + HTTPS + DDoS in one |

**Recommended**: Option 4 (Cloudflare Tunnel) solves all issues at once.

---

🔒 Assessment by Security-Oracle
