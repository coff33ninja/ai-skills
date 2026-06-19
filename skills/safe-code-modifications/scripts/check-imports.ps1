param(
    [string]$FilePath,
    [string]$ProjectPath = "."
)

if (-not $FilePath) { Write-Host "Usage: .\check-imports.ps1 -FilePath <script-or-source> [-ProjectPath .]"; exit 1 }
if (-not (Test-Path $FilePath)) { Write-Host "[-] File not found: $FilePath"; exit 1 }

$resolved = Resolve-Path $ProjectPath
$content = Get-Content -LiteralPath $FilePath -Raw
$imports = [regex]::Matches($content, '^(import |from |using |require\(|use )\s*(\S+)', [Text.RegularExpressions.RegexOptions]::Multiline)

Write-Host "=== Import Verification: $(Split-Path -Leaf $FilePath) ===" -ForegroundColor Cyan
Write-Host "$($imports.Count) import(s) found"

$unused = @()
foreach ($match in $imports) {
    $keyword = $match.Groups[1].Value.Trim()
    $symbol = $match.Groups[2].Value.Trim().TrimEnd('(')
    $usagePattern = "(?<!\b$keyword\s)$([regex]::Escape($symbol))(?!\.)"
    $usages = [regex]::Matches($content, $usagePattern)
    $validUsages = $usages | Where-Object { $_.Index -ne $match.Index }

    if ($validUsages.Count -eq 0) {
        Write-Host "[?] Check usage: $symbol (0 references found after import)" -ForegroundColor Yellow
        Write-Host "    Before removing, search project for $symbol in other files"
        $unused += $symbol
    } else {
        Write-Host "[+] $symbol ($($validUsages.Count) reference(s))" -ForegroundColor Green
    }
}

if ($unused.Count -gt 0) {
    Write-Host ""
    Write-Host "$($unused.Count) import(s) with zero references: $($unused -join ', ')" -ForegroundColor Yellow
    Write-Host "Action: search project-wide. If unused, verify intent before removing."
}
Write-Host "[+] Verification complete." -ForegroundColor Green
exit 0
