param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [switch]$Report
)

$results = @()

# Dependency health
if (Test-Path (Join-Path $ProjectPath "package.json")) {
    $results += [PSCustomObject]@{ Check = "npm audit"; Status = "run 'npm audit' manually"; Found = $true }
}
if (Test-Path (Join-Path $ProjectPath "Cargo.toml")) {
    $results += [PSCustomObject]@{ Check = "cargo audit"; Status = "run 'cargo audit'"; Found = $true }
}

# Config drift check
Get-ChildItem -LiteralPath $ProjectPath -Filter "*.json" -Depth 1 | ForEach-Object {
    try { $null = Get-Content $_.FullName -Raw | ConvertFrom-Json } catch {
        $results += [PSCustomObject]@{ Check = "Config: $($_.Name)"; Status = "Invalid JSON"; Found = $true }
    }
}

# Disk usage
$size = (Get-ChildItem -LiteralPath $ProjectPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
$results += [PSCustomObject]@{ Check = "Disk usage"; Status = "$([math]::Round($size, 2)) MB"; Found = $true }

# Git health
if (Test-Path (Join-Path $ProjectPath ".git")) {
    Push-Location $ProjectPath
    $stashed = git stash list 2>$null | Measure-Object | Select-Object -ExpandProperty Count
    $ahead = git rev-list --count '@{u}..HEAD' 2>$null
    if (-not $ahead) { $ahead = 0 }
    $results += [PSCustomObject]@{ Check = "Git: stashes"; Status = "$stashed stash(es)"; Found = $true }
    $results += [PSCustomObject]@{ Check = "Git: commits ahead"; Status = "$ahead ahead of remote"; Found = $true }
    Pop-Location
}

$results | Format-Table -AutoSize

if ($Report) {
    $reportPath = Join-Path $ProjectPath "audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json | Set-Content -LiteralPath $reportPath
    Write-Host "[+] Report saved: $reportPath"
}
