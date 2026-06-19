param(
    [string]$SkillsDir = (Join-Path $PSScriptRoot ".."),
    [switch]$Fix
)

$errors = 0

# 1. Check all SKILL.md have YAML frontmatter
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch '(?sm)^---\s*$.*?^---\s*$') {
        Write-Warning "Missing frontmatter: $($_.FullName)"
        $errors++
    }
}

# 2. Check all cross-references point to existing skills
$allSkills = @(Get-ChildItem -LiteralPath $SkillsDir -Directory | ForEach-Object { $_.Name })
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $fileRef = $_
    $content = Get-Content $fileRef.FullName -Raw
    [regex]::Matches($content, '(?m)^\s*-\s+\*\*([a-z][\w-]+)\*\*\s+—') | ForEach-Object {
        $ref = $_.Groups[1].Value
        if ($ref -notin $allSkills) {
            Write-Warning "Broken cross-ref in $($fileRef.FullName): $ref"
            $errors++
        }
    }
}

# 3. Check all referenced scripts exist
Get-ChildItem -LiteralPath $SkillsDir -Recurse -Filter "SKILL.md" | ForEach-Object {
    $skillFile = $_
    $content = Get-Content $skillFile.FullName -Raw
    [regex]::Matches($content, '\*\*scripts/[\w.-]+\*\*') | ForEach-Object {
        $scriptPath = Join-Path (Split-Path $skillFile.FullName -Parent) $_.Value.Trim('*')
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
