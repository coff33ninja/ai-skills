param([switch]$DryRun)

Write-Host "=== Global Install Detection ===" -ForegroundColor Cyan
$found = @()

# npm global
try { $npmGlobal = npm list -g --depth=0 2>$null; if ($npmGlobal) { $found += @{Type="npm"; Source="$((Get-Command npm).Source)"; Items=($npmGlobal | Select-String "^[├└]" | ForEach-Object { $_ -replace ".* ","" }) } } } catch {}

# pip global
try { $pipGlobal = pip list --user 2>$null; if ($pipGlobal) { $found += @{Type="pip --user"; Source="$(pip --version)"; Items=($pipGlobal | Select-Object -Skip 2 | ForEach-Object { ($_ -split "\s+")[0] }) } } catch {}

# cargo global
if (Test-Command "cargo") {
    $cargoRoot = & cargo root 2>$null
    if ($cargoRoot) { $cargoBins = Get-ChildItem "$cargoRoot\bin" -ErrorAction SilentlyContinue; if ($cargoBins) { $found += @{Type="cargo --root"; Source=$cargoRoot; Items=$cargoBins.Name } } }
}

# dotnet global
try { $dotnetTools = dotnet tool list -g 2>$null; if ($dotnetTools) { $found += @{Type="dotnet tool -g"; Source="dotnet"; Items=($dotnetTools | Select-Object -Skip 2 | ForEach-Object { ($_ -split "\s+")[0] }) } } catch {}

if ($found.Count -eq 0) { Write-Host "[+] No global installs detected" -ForegroundColor Green; exit 0 }

foreach ($f in $found) {
    Write-Host "[-] $($f.Type) — $($f.Source)" -ForegroundColor Yellow
    $f.Items | ForEach-Object { Write-Host "    $_" }
}

Write-Host ""
Write-Host "Recommendation: Use project-local installs instead. See portable-self-contained skill." -ForegroundColor Cyan
exit $found.Count

function Test-Command { param([string]$Name) $null = Get-Command $Name -ErrorAction SilentlyContinue; return $? }
