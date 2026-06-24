param(
    [string]$ProjectPath = ".",
    [string]$ReportFile = "SECURITY_REPORT.md"
)

$resolved = Resolve-Path $ProjectPath
Write-Host "=== Security Scan: $resolved ===" -ForegroundColor Cyan

$report = @"
# Security Scan Report
- **Project:** $(Split-Path -Leaf $resolved)
- **Date:** $(Get-Date -Format yyyy-MM-dd HH:mm)
- **Scope:** $resolved

## Findings
"@

$findings = @()

# Check for common security issues
$patterns = @(
    @{Pattern='(api[_-]?key|apikey|secret|token|password|passwd|credential)\s*[:=]\s*["'"']\w{8,}["'"']'; Severity='HIGH'; Desc='Hardcoded credential'}
    @{Pattern='Invoke-Expression|iex\s|eval\s|exec\(|os\.system|subprocess\.call'; Severity='HIGH'; Desc='Code execution risk'}
    @{Pattern='(SELECT|INSERT|UPDATE|DELETE).*\+.*(input|param|arg|var)'; Severity='MEDIUM'; Desc='Possible SQL injection'}
    @{Pattern='(http://)[^s]'; Severity='LOW'; Desc='Unencrypted HTTP (not HTTPS)'}
)

$files = Get-ChildItem -LiteralPath $resolved -Recurse -File | Where-Object { $_.Extension -match '\.(ps1|py|js|ts|go|rs|java|cs|php|sh)$' -and $_.FullName -notmatch '\\\.(git|venv|node_modules)' }

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    foreach ($p in $patterns) {
        $matches = [regex]::Matches($content, $p.Pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -gt 0) {
            $relative = $file.FullName.Substring($resolved.Path.Length + 1)
            $finding = "- [$($p.Severity)] $relative: $($p.Desc) ($($matches.Count) match(es))"
            $findings += $finding
            Write-Host "  $finding" -ForegroundColor $(if ($p.Severity -eq 'HIGH') {'Red'} elseif ($p.Severity -eq 'MEDIUM') {'Yellow'} else {'Gray'})
        }
    }
}

if ($findings.Count -eq 0) { $report += "No security issues detected.`n" }
else { $report += ($findings -join "`n") + "`n" }

$report | Set-Content -LiteralPath $ReportFile -Encoding utf8
Write-Host ""
Write-Host "$($findings.Count) finding(s). Report: $ReportFile" -ForegroundColor Cyan
exit $findings.Count
