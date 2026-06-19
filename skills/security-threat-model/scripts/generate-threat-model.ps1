param(
    [string]$SystemName = "MySystem",
    [string]$OutputFile = "THREAT_MODEL.md"
)

$template = @"
# Threat Model: $SystemName

## 1. System Description
_What does this system do? What are its components?_

## 2. Trust Boundaries
| Boundary | Description |
|----------|-------------|
| {User ↔ System} | {trust level} |
| {System ↔ External API} | {trust level} |
| {Internal ↔ Database} | {trust level} |

## 3. Assets
| Asset | Sensitivity | Owner |
|-------|-------------|-------|
| {e.g., user credentials} | {high/medium/low} | {team} |

## 4. Attacker Capabilities
- [ ] Network-level: {e.g., MITM, packet inspection}
- [ ] OS-level: {e.g., local access, process injection}
- [ ] Application-level: {e.g., XSS, CSRF, injection}
- [ ] Physical: {e.g., device theft, side-channel}

## 5. Threats (STRIDE)
| Category | Threat | Mitigation |
|----------|--------|------------|
| Spoofing | | |
| Tampering | | |
| Repudiation | | |
| Information Disclosure | | |
| Denial of Service | | |
| Elevation of Privilege | | |

## 6. Abuse Cases
- {What happens when a user deliberately misuses the system?}

## 7. Mitigations Summary
| ID | Mitigation | Status |
|----|------------|--------|
| M1 | | proposed/in-progress/done |

*Generated $(Get-Date -Format yyyy-MM-dd)*
"@

$template | Set-Content -LiteralPath $OutputFile -Encoding utf8
Write-Host "[+] Threat model template: $OutputFile" -ForegroundColor Green
Write-Host "    Fill out each section collaboratively with domain experts."
