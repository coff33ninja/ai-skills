param(
    [string]$LogFile,
    [int]$MaxToolCalls = 20,
    [int]$MaxUniqueTools = 8
)

if (-not $LogFile) { Write-Host "Usage: .\check-tool-usage.ps1 -LogFile <session-log.txt>"; exit 1 }
if (-not (Test-Path $LogFile)) { Write-Host "[-] Log file not found: $LogFile"; exit 1 }

$content = Get-Content -LiteralPath $LogFile -Raw

# Count tool calls (look for common tool invocation patterns)
$toolCalls = [regex]::Matches($content, '(Read|Write|Edit|Grep|Glob|Bash|Task)\(')
$uniqueTools = ($toolCalls | Select-Object -ExpandProperty Value | Sort-Object -Unique)

Write-Host "=== Tool Usage Check ===" -ForegroundColor Cyan
Write-Host "Total tool calls: $($toolCalls.Count)" -ForegroundColor $(if ($toolCalls.Count -gt $MaxToolCalls) { "Red" } else { "Green" })
Write-Host "Unique tools used: $($uniqueTools.Count)" -ForegroundColor $(if ($uniqueTools.Count -gt $MaxUniqueTools) { "Red" } else { "Green" })
Write-Host "Tools: $($uniqueTools -join ', ')"

$issues = @()
if ($toolCalls.Count -gt $MaxToolCalls) {
    $issues += "Tool call count ($($toolCalls.Count)) exceeds max ($MaxToolCalls) — consider batching"
}
if ($uniqueTools.Count -gt $MaxUniqueTools) {
    $issues += "Unique tool count ($($uniqueTools.Count)) exceeds max ($MaxUniqueTools) — consolidate"
}

if ($issues.Count -eq 0) { Write-Host "[+] Tool usage within bounds." -ForegroundColor Green; exit 0 }
foreach ($issue in $issues) { Write-Host "[-] $issue" -ForegroundColor Yellow }
exit 1
