param([string]$LogFile)

if (-not $LogFile) { Write-Host "Usage: .\detect-repetition.ps1 -LogFile <session-log.txt>"; exit 1 }
if (-not (Test-Path $LogFile)) { Write-Host "[-] Log file not found: $LogFile"; exit 1 }

$lines = Get-Content -LiteralPath $LogFile
$normalized = @()

foreach ($line in $lines) {
    $n = $line -replace '\d+','N' -replace '"([^"]*)"','"..."' -replace '\s+',' '
    $normalized += $n
}

Write-Host "=== Repetition Detection ===" -ForegroundColor Cyan
Write-Host "Lines: $($normalized.Count)"

# Find repeated patterns (3+ consecutive identical normalized lines)
$repeats = @()
$i = 0
while ($i -lt $normalized.Count) {
    $count = 1
    while ($i + $count -lt $normalized.Count -and $normalized[$i] -eq $normalized[$i + $count]) { $count++ }
    if ($count -ge 3) { $repeats += @{Line=$i+1; Text=$lines[$i]; Count=$count} }
    $i += $count
}

if ($repeats.Count -eq 0) { Write-Host "[+] No repetitive patterns found." -ForegroundColor Green; exit 0 }

Write-Host "[-] $($repeats.Count) repetitive pattern(s):" -ForegroundColor Yellow
foreach ($r in $repeats) {
    Write-Host "  Line $($r.Line): repeated $($r.Count)x — $($r.Text.Substring(0, [Math]::Min(80, $r.Text.Length)))"
}
exit $repeats.Count
