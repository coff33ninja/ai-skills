param(
    [string]$ProjectPath = ".",
    [switch]$Fix,
    [switch]$DryRun
)

$issues = 0

function Check { param([string]$Label, [scriptblock]$Cond, [string]$FixHint)
    $ok = & $Cond
    if ($ok) { Write-Host "  [+] $Label" -ForegroundColor Green }
    else { Write-Host "  [-] $Label — $FixHint" -ForegroundColor DarkYellow; $issues++ }
}

$resolved = Resolve-Path $ProjectPath
Write-Host "=== Portability Check: $resolved ===" -ForegroundColor Cyan

# Drive space
$drive = (Get-Item $resolved).PSDrive
$freeGB = ($drive.Free / 1GB)
Write-Host "Drive $($drive.Name): $([math]::Round($freeGB,2)) GB free" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } else { "Green" })

# Python
$venvDirs = @(Get-ChildItem -LiteralPath $resolved -Directory -Filter ".venv" -ErrorAction SilentlyContinue)
Check ".venv/ exists" { $venvDirs.Count -gt 0 } "Run 'uv venv .venv'"

# node_modules
$nmDirs = @(Get-ChildItem -LiteralPath $resolved -Directory -Filter "node_modules" -ErrorAction SilentlyContinue)
Check "node_modules/ exists (if JS project)" { $nmDirs.Count -gt 0 -or -not (Test-Path (Join-Path $resolved "package.json")) } "Run 'npm install'"

# scripts/
$scriptsDir = Join-Path $resolved "scripts"
Check "scripts/ directory exists" { Test-Path $scriptsDir } "Create scripts/ for setup/build scripts"

# setup doc
$setupDoc = (Test-Path (Join-Path $resolved "SETUP.md")) -or (Test-Path (Join-Path $resolved "docs\SETUP.md"))
Check "SETUP.md exists" { $setupDoc } "Document setup steps in SETUP.md"

# .gitignore for common dirs
$gi = Join-Path $resolved ".gitignore"
if (Test-Path $gi) {
    $gContent = Get-Content $gi -Raw
    Check ".gitignore has .venv/" { $gContent -match "\.venv/" } "Add '.venv/' to .gitignore"
    Check ".gitignore has node_modules/" { $gContent -match "node_modules/" } "Add 'node_modules/' to .gitignore"
} else { Write-Host "  [-] No .gitignore found" -ForegroundColor DarkYellow; $issues++ }

Write-Host ""
if ($issues -eq 0) { Write-Host "[+] All portability checks passed" -ForegroundColor Green }
else { Write-Host "[-] $issues issue(s) found" -ForegroundColor Yellow }
exit $issues
