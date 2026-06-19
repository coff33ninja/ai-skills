param([string]$FilePath)

if (-not $FilePath) { Write-Host "Usage: .\check-assumptions.ps1 -FilePath <script-or-task-md>"; exit 1 }
if (-not (Test-Path $FilePath)) { Write-Host "[-] File not found: $FilePath"; exit 1 }

$lines = Get-Content -LiteralPath $FilePath
$steps = @(); $currentStep = ""
$stepNum = 0

foreach ($line in $lines) {
    if ($line -match '^\d+\.|^Step \d+|^-\s*\*\*Step') {
        if ($currentStep) { $steps += $currentStep }
        $stepNum++
        $currentStep = @{Number=$stepNum; Text=$line.Trim(); Checks=@()}
    }
    elseif ($currentStep -and $line -match 'check|verify|ensure|confirm|validate|assum') {
        $currentStep.Checks += $line.Trim()
    }
}
if ($currentStep) { $steps += $currentStep }

if ($steps.Count -eq 0) { Write-Host "[-] No structured steps found in $FilePath"; exit 1 }

Write-Host "=== Assumption Check: $($steps.Count) steps found ===" -ForegroundColor Cyan
$issues = 0
foreach ($step in $steps) {
    if ($step.Checks.Count -eq 0) {
        Write-Host "[-] Step $($step.Number): No verification checks found" -ForegroundColor Yellow
        Write-Host "    $($step.Text)"
        $issues++
    } else {
        Write-Host "[+] Step $($step.Number): $($step.Checks.Count) check(s)" -ForegroundColor Green
    }
}
exit $issues
