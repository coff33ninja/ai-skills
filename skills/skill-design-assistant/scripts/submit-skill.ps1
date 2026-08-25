<#
.SYNOPSIS
    Copies a skill into the ai-skills repo and opens a PR.

.DESCRIPTION
    Takes a skill directory (must contain SKILL.md), copies it into the
    ai-skills repository under skills/, updates the README catalog, and
    opens a pull request via gh.

.PARAMETER SkillPath
    Path to the skill directory containing SKILL.md.

.PARAMETER RepoPath
    Path to the ai-skills repository root. Defaults to the repo this
    script lives in.

.PARAMETER BranchPrefix
    Prefix for the feature branch name. Default: "skill".

.PARAMETER Draft
    Open the PR as a draft.

.PARAMETER DryRun
    Show what would happen without making changes.

.EXAMPLE
    .\submit-skill.ps1 -SkillPath "C:\my-new-skill"
    .\submit-skill.ps1 -SkillPath ".\my-skill" -Draft
    .\submit-skill.ps1 -SkillPath ".\my-skill" -DryRun
#>
param(
    [Parameter(Mandatory)][string]$SkillPath,
    [string]$RepoPath,
    [string]$BranchPrefix = "skill",
    [switch]$Draft,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ── Resolve paths ──────────────────────────────────────────────
if (-not $RepoPath) {
    $RepoPath = Join-Path $PSScriptRoot ".." ".." ".."
}
$RepoPath = (Resolve-Path $RepoPath).Path

$SkillPath = (Resolve-Path $SkillPath).Path
$skillMd = Join-Path $SkillPath "SKILL.md"
if (-not (Test-Path $skillMd)) {
    Write-Host "[-] No SKILL.md found in $SkillPath" -ForegroundColor Red
    exit 1
}

# ── Prerequisites ──────────────────────────────────────────────
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Host "[-] gh CLI required — install from https://cli.github.com" -ForegroundColor Red
    exit 1
}
try { gh auth status 2>&1 | Out-Null } catch {
    Write-Host "[-] Not authenticated to GitHub — run 'gh auth login'" -ForegroundColor Red
    exit 1
}

# ── Extract skill name from frontmatter ────────────────────────
$content = Get-Content $skillMd -Raw
$nameMatch = [regex]::Match($content, '(?m)^name:\s*(.+?)$')
if (-not $nameMatch.Success) {
    Write-Host "[-] Could not find 'name:' in SKILL.md frontmatter" -ForegroundColor Red
    exit 1
}
$skillName = $nameMatch.Groups[1].Value.Trim()

# Validate kebab-case
if ($skillName -notmatch '^[a-z0-9]([a-z0-9\-]*[a-z0-9])?$') {
    Write-Host "[-] Skill name '$skillName' is not kebab-case" -ForegroundColor Red
    exit 1
}

$destDir = Join-Path $RepoPath "skills" $skillName

Write-Host "[*] Skill name:  $skillName" -ForegroundColor Cyan
Write-Host "[*] Source:      $SkillPath" -ForegroundColor Cyan
Write-Host "[*] Destination: $destDir" -ForegroundColor Cyan

# ── Check for conflicts ────────────────────────────────────────
if (Test-Path $destDir) {
    Write-Host "[-] Skill '$skillName' already exists in repo at $destDir" -ForegroundColor Red
    Write-Host "    Remove it first or choose a different name." -ForegroundColor Yellow
    exit 1
}

# ── Dry run stop ───────────────────────────────────────────────
if ($DryRun) {
    Write-Host "[DRY-RUN] Would copy $SkillPath -> $destDir" -ForegroundColor Yellow
    Write-Host "[DRY-RUN] Would run update-readme-catalog.ps1" -ForegroundColor Yellow
    Write-Host "[DRY-RUN] Would create branch and open PR" -ForegroundColor Yellow
    exit 0
}

# ── Copy skill directory ───────────────────────────────────────
Copy-Item -Path $SkillPath -Destination $destDir -Recurse -Force
Write-Host "[+] Copied skill to $destDir" -ForegroundColor Green

# ── Update README catalog ──────────────────────────────────────
$catalogScript = Join-Path $RepoPath "scripts" "update-readme-catalog.ps1"
if (Test-Path $catalogScript) {
    & $catalogScript
    Write-Host "[+] README catalog updated" -ForegroundColor Green
} else {
    Write-Host "[!] update-readme-catalog.ps1 not found — update README manually" -ForegroundColor Yellow
}

# ── Create branch, commit, push ────────────────────────────────
$branch = "$BranchPrefix/add-$skillName"

Push-Location $RepoPath
try {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -in @("main", "master", "develop")) {
        git checkout -b $branch 2>&1 | Out-Null
        Write-Host "[+] Created branch: $branch" -ForegroundColor Green
    }

    git add "skills/$skillName/" "README.md"
    git commit -m "add $skillName skill" 2>&1 | Out-Null
    Write-Host "[+] Committed" -ForegroundColor Green

    git push -u origin $branch 2>&1 | Out-Null
    Write-Host "[+] Pushed to origin/$branch" -ForegroundColor Green

    # ── Open PR ────────────────────────────────────────────────
    $prArgs = @("pr", "create",
        "--title", "add $skillName skill",
        "--body", "Adds the ``$skillName`` skill to the repository.`n`nCopied from ``$SkillPath``.",
        "--head", $branch)
    if ($Draft) { $prArgs += "--draft" }

    $env:GH_PROMPT_DISABLED = "1"
    $env:GIT_TERMINAL_PROMPT = "0"
    $prUrl = & "gh" @($prArgs)
    Write-Host "[+] PR created: $prUrl" -ForegroundColor Green
} finally {
    Pop-Location
}
