param(
    [string]$TodoFile,
    [string]$TaskDescription
)

if (-not $TodoFile -and -not $TaskDescription) {
    Write-Host "Usage: .\check-completion.ps1 -TodoFile TODO.md [-TaskDescription 'optional filter']"
    exit 1
}

# Check TODO file
if ($TodoFile -and (Test-Path $TodoFile)) {
    $content = Get-Content -LiteralPath $TodoFile -Raw
    $incomplete = [regex]::Matches($content, '- \[ \]').Count
    $complete = [regex]::Matches($content, '- \[x\]').Count
    $total = $incomplete + $complete

    Write-Host "=== Completion Check ===" -ForegroundColor Cyan
    Write-Host "TODO: $TodoFile"
    Write-Host "Complete: $complete / $total" -ForegroundColor $(if ($incomplete -eq 0) { "Green" } else { "Yellow" })
    Write-Host "Remaining: $incomplete" -ForegroundColor $(if ($incomplete -eq 0) { "Green" } else { "Yellow" })

    if ($TaskDescription) {
        $filtered = [regex]::Matches($content, "- \[.\].*$([regex]::Escape($TaskDescription))", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($filtered.Count -gt 0) {
            Write-Host "Task '$TaskDescription': $($filtered.Count) match(es)"
        }
    }

    if ($incomplete -gt 0) { exit 1 }
    exit 0
}
elseif ($TodoFile) {
    Write-Host "[-] TODO file not found: $TodoFile"; exit 1
}

# No TODO file — ask basic questions
Write-Host "=== Quick Completion Check ===" -ForegroundColor Cyan
Write-Host "1. Was the task explicitly confirmed by the user?"
Write-Host "2. Were all required steps completed?"
Write-Host "3. Were results verified?"
exit 0
