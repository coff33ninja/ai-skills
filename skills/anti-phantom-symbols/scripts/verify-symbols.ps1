param(
    [string]$ProjectPath = ".",
    [string]$SymbolsFile,
    [string]$Language = "auto"
)

$resolved = Resolve-Path $ProjectPath

# If symbols provided inline via file
if ($SymbolsFile -and (Test-Path $SymbolsFile)) {
    $symbols = Get-Content -LiteralPath $SymbolsFile
} else {
    Write-Host "Usage: .\verify-symbols.ps1 -SymbolsFile symbols.txt [-ProjectPath .]"
    Write-Host ""
    Write-Host "symbols.txt format: one symbol per line"
    exit 1
}

$missing = @()
$found = 0

foreach ($sym in $symbols) {
    $sym = $sym.Trim()
    if (-not $sym -or $sym -match '^#|^//') { continue }

    # Search in project files
    $matches = Select-String -Path (Get-ChildItem -LiteralPath $resolved -Recurse -Include @("*.py","*.js","*.ts","*.go","*.rs","*.java") -ErrorAction SilentlyContinue) -Pattern "\b$([regex]::Escape($sym))\b" -ErrorAction SilentlyContinue

    if ($matches) {
        Write-Host "[+] $sym" -ForegroundColor Green
        $found++
    } else {
        Write-Host "[-] $sym" -ForegroundColor Red
        $missing += $sym
    }
}

Write-Host ""
Write-Host "$found found, $($missing.Count) missing"
if ($missing) { Write-Host "Missing: $($missing -join ', ')" -ForegroundColor Yellow }
exit $missing.Count
