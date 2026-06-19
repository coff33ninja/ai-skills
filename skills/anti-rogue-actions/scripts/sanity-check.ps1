param(
    [string]$Command,
    [string]$Action,
    [string]$Target,
    [int]$MaxItems = 100,
    [switch]$DryRun
)

Write-Host "=== Sanity Check ===" -ForegroundColor Cyan
$issues = @()

if ($Command) {
    Write-Host "Command: $Command"
    # Check for destructive patterns
    if ($Command -match 'rm\s+-rf|Remove-Item.*-Recurse|format.*/fs:') {
        $issues += "Destructive command detected: $Command"
    }
    if ($Command -match '>\s+/dev/|>\s+NUL|Out-Null') {
        $issues += "Output suppression may hide errors"
    }
}

if ($Action) {
    Write-Host "Action: $Action"
    if ($Action -match 'delete|remove|drop|truncate|purge|wipe') {
        $issues += "Destructive action: $Action"
    }
}

if ($Target) {
    Write-Host "Target: $Target"
    if (-not (Test-Path $Target)) {
        $issues += "Target does not exist: $Target"
    }
    if ((Get-ChildItem -LiteralPath $Target -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -gt $MaxItems) {
        $issues += "Target contains more than $MaxItems items — may be too broad"
    }
}

if ($DryRun) {
    Write-Host "[DRY-RUN] Flag is set — no changes will be made" -ForegroundColor Green
}

if ($issues.Count -eq 0) {
    Write-Host "[+] All sanity checks passed" -ForegroundColor Green
    exit 0
}

foreach ($issue in $issues) {
    Write-Host "[-] $issue" -ForegroundColor Yellow
}
exit 1
