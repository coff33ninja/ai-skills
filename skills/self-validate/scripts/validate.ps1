param(
    [string]$SkillsDir = (Join-Path $PSScriptRoot ".."),
    [switch]$Fix
)

$errors = 0

# 1. Check all SKILL.md have YAML frontmatter
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch '^---\s*\n.*?\n---') {
        Write-Warning "Missing frontmatter: $($_.FullName)"
        $errors++
    }
}

# 2. Check all cross-references point to existing skills
$allSkills = @(Get-ChildItem -LiteralPath $SkillsDir -Directory | ForEach-Object { $_.Name })
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    [regex]::Matches($content, '\*\*([a-z][\w-]+)\*\*') | ForEach-Object {
        $ref = $_.Groups[1].Value
        if ($ref -notin $allSkills -and $ref -ne "TODO") {
            Write-Warning "Broken cross-ref in $($_.FullName): $ref"
            $errors++
        }
    }
}

# 3. Check all referenced scripts exist
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    [regex]::Matches($content, 'scripts/[\w.-]+') | ForEach-Object {
        $scriptPath = Join-Path (Split-Path $_.FullName -Parent) $_.Value
        if (-not (Test-Path $scriptPath)) {
            Write-Warning "Missing script ref: $scriptPath"
            $errors++
        }
    }
}

if ($errors -eq 0) {
    Write-Host "[+] All validations passed." -ForegroundColor Green
} else {
    Write-Host "[-] $errors issues found." -ForegroundColor Red
}
exit $errors
