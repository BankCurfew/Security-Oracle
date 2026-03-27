---
title: QA audit data decays fast — findings have a half-life measured in hours when FE 
tags: [security-audit, verification, qa-coordination, data-freshness]
created: 2026-03-20
source: rrr: Security-Oracle Session 3
project: github.com/bankcurfew/security-oracle
---

# QA audit data decays fast — findings have a half-life measured in hours when FE 

QA audit data decays fast — findings have a half-life measured in hours when FE is actively fixing. Always re-scan against current codebase before writing verification reports, escalating, or forwarding fix requests. In FA Tools R5, 3/4 of QA's P0 items were already fixed when Security re-verified ~15 hours later. Include "verified at commit HASH" in every finding.

---
*Added via Oracle Learn*
