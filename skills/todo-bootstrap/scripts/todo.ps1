param(
    [Parameter(Position=0)][string]$Path = ".",
    [ValidateSet("create","update","check")][string]$Action = "create",
    [string]$Title = "Project TODO",
    [switch]$DryRun
)

$todoPath = Join-Path (Resolve-Path $Path) "TODO.md"
if (Test-Path (Join-Path (Resolve-Path $Path) "docs\TODO.md")) {
    $todoPath = Join-Path (Resolve-Path $Path) "docs\TODO.md"
}
if (Test-Path $todoPath) { $Action = "update" }

if ($DryRun) { Write-Host "[DRY-RUN] Action: $Action at $todoPath"; exit 0 }

switch ($Action) {
    "create" {
        if (Test-Path $todoPath) { Write-Host "[-] Already exists: $todoPath"; exit 1 }
        @"
# $Title

## Completed
- [ ] *(none yet)*

## Incomplete
- [ ] *(add tasks here)*
"@ | Set-Content -LiteralPath $todoPath
        Write-Host "[+] Created: $todoPath"
    }
    "update" {
        $content = Get-Content -LiteralPath $todoPath -Raw
        if ($content -match "^# .*`n`n## Completed`n") {
            Write-Host "[*] TODO file looks valid: $todoPath"
        } else {
            Write-Warning "TODO file at $todoPath has unexpected structure"
        }
    }
    "check" {
        if (-not (Test-Path $todoPath)) { Write-Host "[-] No TODO found"; exit 1 }
        $content = Get-Content -LiteralPath $todoPath -Raw
        $incomplete = [regex]::Matches($content, '- \[ \]').Count
        $complete = [regex]::Matches($content, '- \[x\]').Count
        Write-Host "[*] $todoPath — $complete done, $incomplete remaining"
    }
}
