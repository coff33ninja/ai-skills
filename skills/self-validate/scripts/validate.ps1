param(
    [string]$SkillsDir = (Join-Path $PSScriptRoot ".."),
    [switch]$Fix
)

$errors = 0

# 1. Check all SKILL.md have YAML frontmatter
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $skillFile = $_
    $content = Get-Content -LiteralPath $skillFile.FullName -Raw
    if ($content -notmatch '(?s)^---\s*\r?\n.*?\r?\n---') {
        Write-Warning "Missing frontmatter: $($skillFile.FullName)"
        $errors++
    }

    $crossRefHeaders = [regex]::Matches($content, '(?m)^## Cross-references\s*$').Count
    if ($crossRefHeaders -gt 1) {
        Write-Warning "Duplicate Cross-references sections: $($skillFile.FullName)"
        $errors++
    }
}

# 2. Check all cross-references point to existing skills
$allSkills = @(Get-ChildItem -LiteralPath $SkillsDir -Directory | ForEach-Object { $_.Name })
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $skillFile = $_
    $content = Get-Content -LiteralPath $skillFile.FullName -Raw
    $section = [regex]::Match($content, '(?ms)^## Cross-references\s*(.*?)(?=^## |\z)')
    if (-not $section.Success) { return }
    [regex]::Matches($section.Groups[1].Value, '(?m)^\s*-\s+\*\*([a-z][\w-]+)\*\*') | ForEach-Object {
        $ref = $_.Groups[1].Value
        if ($ref -notin $allSkills -and $ref -ne "TODO") {
            Write-Warning "Broken cross-ref in $($skillFile.FullName): $ref"
            $errors++
        }
    }
}

# 3. Check all referenced scripts exist
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $skillFile = $_
    $content = Get-Content -LiteralPath $skillFile.FullName -Raw
    $content -split '\r?\n' | ForEach-Object {
        $line = $_
        if ($line -match '\.ai_scripts[\\/]') { return }
        if ($line -match '^\s*\*\*scripts[\\/]') { return }
        if ($line -match '\be\.g\.') { return }

        [regex]::Matches($line, 'scripts[\\/][\w.-]+\.(ps1|py|sh|js|ts|bat|cmd)') | ForEach-Object {
            $relativePath = $_.Value -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $scriptPath = Join-Path (Split-Path $skillFile.FullName -Parent) $relativePath
            if (-not (Test-Path -LiteralPath $scriptPath)) {
                Write-Warning "Missing script ref: $scriptPath"
                $errors++
            }
        }
    }
}

if ($errors -eq 0) {
    Write-Host "[+] All validations passed." -ForegroundColor Green
} else {
    Write-Host "[-] $errors issues found." -ForegroundColor Red
}
exit $errors
