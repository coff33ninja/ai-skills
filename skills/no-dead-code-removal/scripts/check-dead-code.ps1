param(
    [string]$ProjectPath = ".",
    [string]$LogFile,
    [switch]$SuggestRefactor
)

$resolved = Resolve-Path $ProjectPath

if ($LogFile -and (Test-Path $LogFile)) {
    $added = Get-Content -LiteralPath $LogFile | Where-Object { $_ -match 'added|created|wrote|new file' }
    Write-Host "=== Refactoring Opportunities (session log) ===" -ForegroundColor Cyan
    Write-Host "Items added this session: $($added.Count)"

    $unused = @()
    foreach ($item in $added) {
        $file = if ($item -match '(\S+\.\w+)') { $Matches[1] } else { $null }
        if ($file -and (Test-Path $file)) {
            $refs = Select-String -Path (Get-ChildItem -LiteralPath $resolved -Recurse -Include @("*.ps1","*.py","*.js","*.ts","*.go","*.rs") -ErrorAction SilentlyContinue) -Pattern [regex]::Escape($file) -ErrorAction SilentlyContinue
            if (-not $refs) {
                Write-Host "[!] Not yet integrated: $file" -ForegroundColor Yellow
                Write-Host "    Options: route through it, wire it in, merge it, parameterize it"
                $unused += $file
            }
        }
    }

    if ($unused.Count -eq 0) {
        Write-Host "[+] All added files are referenced elsewhere." -ForegroundColor Green
    }
    exit $unused.Count
}

Write-Host "=== Integration Check ===" -ForegroundColor Cyan
Write-Host "Use -LogFile <session-log> to check code you added this session."
Write-Host "This skill refactors, never deletes. No files will be flagged for removal."
exit 0
