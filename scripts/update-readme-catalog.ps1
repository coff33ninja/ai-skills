param([string]$ReadmePath, [string]$SkillsDir, [switch]$DryRun)

if (-not $ReadmePath) { $ReadmePath = Join-Path $PSScriptRoot ".." "README.md" }
if (-not $SkillsDir) { $SkillsDir = Join-Path $PSScriptRoot ".." "skills" }

$ErrorActionPreference = "Stop"
$readme = [System.IO.File]::ReadAllText($ReadmePath)
$skillNames = Get-ChildItem $SkillsDir -Directory | ForEach-Object Name | Sort-Object
$changed = $false

function SaveFile { param($Content)
    [System.IO.File]::WriteAllText($ReadmePath, $Content, [System.Text.UTF8Encoding]::new($false))
}

# ── Helper: get description from SKILL.md ────────────────────
function Get-Desc($name) {
    $md = Join-Path $SkillsDir "$name\SKILL.md"
    if (Test-Path $md) {
        $c = Get-Content $md -Raw
        $m = [regex]::Match($c, '(?m)^description:\s*["''](.+?)["'']\s*$')
        if (-not $m.Success) { $m = [regex]::Match($c, '(?m)^description:\s*(.+?)$') }
        if ($m.Success) { return $m.Groups[1].Value.Trim() }
    }
    return $name
}

# ── 1. Rebuild directory tree from actual skills ────────────
$treeAnchor = "├── sync-skills.ps1"
$treeEndAnchor = "└── README.md"
$treeStart = $readme.IndexOf($treeAnchor)
$treeEnd = $readme.IndexOf($treeEndAnchor)
if ($treeStart -lt 0 -or $treeEnd -lt 0) { Write-Error "Cannot find directory tree"; exit 1 }

$beforeTree = $readme.Substring(0, $treeStart)
$afterTree = $readme.Substring($treeEnd)

$allSkillNames = $skillNames | Sort-Object
$lastSkill = $allSkillNames[-1]
$treeLines = @()
$treeLines += "├── sync-skills.ps1        # Push skills + convert to rules"
$treeLines += "├── skills\                # Source of truth — edit SKILL.md files here"
foreach ($s in $allSkillNames) {
    $prefix = if ($s -eq $lastSkill) { "│   └──" } else { "│   ├──" }
    $treeLines += "$prefix $s\"
}
$newTreeBlock = $treeLines -join "`r`n"

$oldTreeBlock = $readme.Substring($treeStart, $treeEnd - $treeStart)

$changedTree = $false
if ($oldTreeBlock.TrimEnd() -ne $newTreeBlock.TrimEnd()) {
    $readme = $beforeTree + $newTreeBlock + "`r`n" + $afterTree
    $changedTree = $true
    $changed = $true
    Write-Host "Directory tree updated." -ForegroundColor Green
}

# ── 4. Update catalog table ─────────────────────────────────
$tableAnchor = "| Skill | Description | Scripts | Assets | Refs |"
$tableStart = $readme.IndexOf($tableAnchor)
if ($tableStart -lt 0) { Write-Error "Cannot find catalog table"; exit 1 }

$beforeTable = $readme.Substring(0, $tableStart)
$tableSection = $readme.Substring($tableStart)
$tableLines = $tableSection -split "`r`n"

# Find end of table: blank line after rows
$rowEnd = 0
for ($i = 0; $i -lt $tableLines.Count; $i++) {
    if ($tableLines[$i].Trim() -eq "" -and $rowEnd -eq 0 -and $i -gt 1) { $rowEnd = $i; break }
}
if ($rowEnd -eq 0) { $rowEnd = $tableLines.Count }
$afterTable = ($tableLines[$rowEnd..$tableLines.Count] -join "`r`n")

# Extract existing rows (skip header line 0, separator line 1)
$existingRows = @{}
for ($i = 2; $i -lt $rowEnd; $i++) {
    $m = [regex]::Match($tableLines[$i], '^\|\s+\*\*(.+?)\*\*')
    if ($m.Success) { $existingRows[$m.Groups[1].Value] = $tableLines[$i] }
}

$missingTable = $skillNames | Where-Object { $_ -notin $existingRows.Keys }
$staleTable = $existingRows.Keys | Where-Object { $_ -notin $skillNames }

if ($missingTable.Count -gt 0 -or $staleTable.Count -gt 0) {
    if ($missingTable.Count -gt 0) {
        Write-Host "Missing from table: $($missingTable -join ', ')" -ForegroundColor Yellow
    }
    if ($staleTable.Count -gt 0) {
        Write-Host "Stale in table: $($staleTable -join ', ')" -ForegroundColor Yellow
    }

    # Rebuild all rows preserving header/separator, sorted by skill name
    $newRows = @()
    foreach ($s in $skillNames) {
        if ($existingRows.ContainsKey($s)) {
            $newRows += $existingRows[$s]
        } else {
            $d = Get-Desc $s
            $extras = " | | | |"
            if ($s -eq "playwright") { $extras = " | ✅ | ✅ | ✅" }
            elseif ($s -eq "screenshot") { $extras = " | ✅ | ✅ |" }
            elseif ($s -eq "yeet") { $extras = " | ✅ | |" }
            elseif ($s -in @("security-best-practices","security-threat-model")) { $extras = " | | | ✅" }
            elseif ($s -eq "security-ownership-map") { $extras = " | ✅ | | ✅" }
            $newRows += "| **$s** | $d$extras"
        }
    }

    $newTableSection = $tableLines[0] + "`r`n" + $tableLines[1] + "`r`n" + ($newRows -join "`r`n")
    $readme = $beforeTable + $newTableSection + "`r`n" + $afterTable
    $changed = $true
}

if ($changed) {
    $readme = $readme -replace "`r`n`r`n`r`n+", "`r`n`r`n"
    if ($DryRun) { Write-Host "[DRY RUN] Would update README." -ForegroundColor Yellow; return }
    SaveFile $readme
    Write-Host "README updated." -ForegroundColor Green
} else {
    Write-Host "README is up to date." -ForegroundColor Green
}
