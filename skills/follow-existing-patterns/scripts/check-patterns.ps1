param(
    [string]$ProjectPath = ".",
    [switch]$DryRun
)

$resolved = Resolve-Path $ProjectPath
Write-Host "=== Pattern Check: $resolved ===" -ForegroundColor Cyan

$files = Get-ChildItem -LiteralPath $resolved -File -Recurse -Depth 3 -ErrorAction SilentlyContinue
$issues = @()

# Check indentation consistency per extension
$fileGroups = $files | Group-Object Extension
foreach ($g in $fileGroups) {
    if ($g.Count -lt 3) { continue }
    $spaces = 0; $tabs = 0
    foreach ($f in $g.Group) {
        try {
            $firstLine = Get-Content -LiteralPath $f.FullName -TotalCount 50 -ErrorAction SilentlyContinue | Where-Object { $_ -match '^( +|\t+)' } | Select-Object -First 1
            if ($firstLine -match '^\t') { $tabs++ }
            elseif ($firstLine -match '^ +') { $spaces++ }
        } catch {}
    }
    if ($tabs -gt 0 -and $spaces -gt 0) {
        $issues += "$($g.Name): mixed tabs ($tabs files) and spaces ($spaces files)"
    }
}

# Check for copyright/license header consistency
$headerFiles = $files | Where-Object { @(".py",".js",".ts",".go",".rs",".java",".cs",".ps1") -contains $_.Extension.ToLower() } | Select-Object -First 20
$headers = @{}
foreach ($f in $headerFiles) {
    $line = Get-Content -LiteralPath $f.FullName -TotalCount 3 -ErrorAction SilentlyContinue | Where-Object { $_ -match 'copyright|license|©|MIT|Apache' } | Select-Object -First 1
    if ($line) { $headers[$line.Trim()] = ($headers[$line.Trim()] + 1) }
}
if ($headers.Count -gt 1) {
    $issues += "Inconsistent license headers: $($headers.Count) variants found"
}

# Check naming convention consistency
$nameFiles = $files | Where-Object { @(".py",".js",".ts") -contains $_.Extension.ToLower() } | Select-Object -First 30
$snake = 0; $camel = 0; $pascal = 0
foreach ($f in $nameFiles) {
    $functions = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*(def |function |const \w+ = .*=>|const \w+ = function)' }
    foreach ($fn in $functions) {
        if ($fn -match 'def ([a-z]+_[a-z]+)') { $snake++ }
        elseif ($fn -match 'function ([a-z][A-Z])') { $camel++ }
        elseif ($fn -match '(?:function |const )([A-Z][a-z])') { $pascal++ }
    }
}
if ($snake -gt 0 -and $camel -gt 0) { $issues += "Mixed naming: snake_case ($snake) and camelCase ($camel)" }

if ($issues.Count -eq 0) { Write-Host "[+] No pattern issues found" -ForegroundColor Green; exit 0 }
foreach ($issue in $issues) { Write-Host "[-] $issue" -ForegroundColor Yellow }
exit $issues.Count
