param(
    [string[]]$Files,
    [switch]$DryRun
)

if (-not $Files) { Write-Host "Usage: .\format-lint.ps1 -Files file1.py,file2.js"; exit 1 }

$groups = @{}
foreach ($f in $Files) {
    $ext = [System.IO.Path]::GetExtension($f).ToLower()
    if (-not $groups[$ext]) { $groups[$ext] = @() }
    $groups[$ext] += $f
}

$ordered = @(
    @{Exts=@(".py",".pyi"); Tools=@("isort","black","ruff check --fix","black")},
    @{Exts=@(".js",".jsx",".ts",".tsx",".mjs",".cjs"); Tools=@("prettier --write","eslint --fix","prettier --write")},
    @{Exts=@(".md",".markdown",".json",".jsonc",".yml",".yaml"); Tools=@("prettier --write")},
    @{Exts=@(".ps1",".psm1",".psd1"); Tools=@("Invoke-Formatter","Invoke-ScriptAnalyzer -Fix","Invoke-Formatter")},
    @{Exts=@(".sh",".bash",".zsh"); Tools=@("shfmt -w","shellcheck -f gcc")}
)

foreach ($group in $ordered) {
    $match = @()
    foreach ($ext in $group.Exts) {
        if ($groups[$ext]) { $match += $groups[$ext] }
    }
    if (-not $match) { continue }

    $joined = $match -join " "
    foreach ($tool in $group.Tools) {
        $cmd = "$tool $joined"
        if ($DryRun) { Write-Host "[DRY-RUN] $cmd"; continue }
        try {
            if ($tool -match "^Invoke-") {
                $toolName = ($tool -split " ")[0]
                & $toolName -Path $match -ErrorAction SilentlyContinue | Out-Null
            } else {
                Invoke-Expression "$tool $joined" 2>$null | Out-Null
            }
            Write-Host "[+] $tool on $($match.Count) file(s)"
        } catch { Write-Warning "[-] $tool failed: $_" }
    }
}
