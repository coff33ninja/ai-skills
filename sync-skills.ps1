param(
    [switch]$DryRun,
    [switch]$ConvertRules
)

$Source = Join-Path -Path $PSScriptRoot -ChildPath "skills"
if (-not (Test-Path $Source)) {
    Write-Error "Source skills directory not found: $Source"
    exit 1
}

$SkillDirs = Get-ChildItem -LiteralPath $Source -Directory
$ProjectRoot = "C:\Cleaning"

# ─── Helper: parse SKILL.md frontmatter ─────────────────────────────
function Parse-SkillFrontmatter {
    param([string]$SkillPath)
    $mdPath = Join-Path $SkillPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { return $null }
    $content = Get-Content -LiteralPath $mdPath -Raw
    if ($content -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
        $yamlBlock = $matches[1]
        $body = $matches[2].Trim()
        $name = ""
        $description = ""
        if ($yamlBlock -match '(?m)^name:\s*["'']?(.+?)["'']?\s*$') { $name = $matches[1].Trim() }
        if ($yamlBlock -match '(?m)^description:\s*["''](.+?)["'']\s*$') {
            $description = $matches[1].Trim()
        } elseif ($yamlBlock -match '(?m)^description:\s*(.+?)$') {
            $description = $matches[1].Trim()
        }
        $description = $description -replace '\s*\|$' -replace '\s*>$'
        return @{ Name = $name; Description = $description; Body = $body }
    }
    return $null
}

# ═════════════════════════════════════════════════════════════════════
#  PHASE 1 — Sync SKILL.md directories to all tool skill paths
# ═════════════════════════════════════════════════════════════════════

$Targets = @(
    "$env:USERPROFILE\.agents\skills"
    "$env:USERPROFILE\.claude\skills"
    "$env:USERPROFILE\.codex\skills"
    "$env:USERPROFILE\.copilot\skills"
    "$env:USERPROFILE\.cursor\skills"
    "$env:USERPROFILE\.gemini\skills"
    "$env:USERPROFILE\.gemini\antigravity\skills"
    "$env:USERPROFILE\.kiro\skills"
    "$env:USERPROFILE\.codeium\windsurf\skills"
    "\.claude\skills"
    "\.codex\skills"
    "\.cursor\skills"
    "\.gemini\skills"
    "\.github\skills"
    "\.kiro\skills"
    "\.windsurf\skills"
)

Write-Host "=== Phase 1: Syncing skills to tool skill paths ===" -ForegroundColor Cyan
Write-Host ""

$Summary = @()

foreach ($target in $Targets) {
    if ($target.StartsWith("\")) {
        $absTarget = Join-Path -Path $ProjectRoot -ChildPath $target.TrimStart("\")
    } else {
        $absTarget = $target
    }

    if (-not (Test-Path $absTarget)) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would create: $absTarget" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $absTarget -Force | Out-Null
        }
    }

    $copied = 0
    $syncDirs = @()

    foreach ($skill in $SkillDirs) {
        $dest = Join-Path -Path $absTarget -ChildPath $skill.Name
        $syncDirs += $skill.Name
        if ($DryRun) {
            Write-Host "[DRY RUN] Would sync: $($skill.FullName) -> $dest" -ForegroundColor Yellow
        } else {
            if (Test-Path $dest) {
                Remove-Item -LiteralPath $dest -Recurse -Force
            }
            Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse
            $copied++
        }
    }

    $afterCount = if (Test-Path $absTarget) { (Get-ChildItem -LiteralPath $absTarget -Directory -ErrorAction SilentlyContinue).Count } else { 0 }

    $Summary += [PSCustomObject]@{
        Target = $absTarget
        Synced = if ($DryRun) { $syncDirs.Count } else { $copied }
        Total  = $afterCount
        Status = if ($DryRun) { "dry-run" } else { "synced" }
    }
}

Write-Host ""
Write-Host "=== Phase 1 Summary ===" -ForegroundColor Cyan
$Summary | Format-Table Target, Synced, Total, Status -AutoSize

# ═════════════════════════════════════════════════════════════════════
#  PHASE 2 — Convert skills to tool-specific rule/instruction formats
# ═════════════════════════════════════════════════════════════════════

if ($ConvertRules -and -not $DryRun) {
    Write-Host ""
    Write-Host "=== Phase 2: Converting skills to rules/instructions ===" -ForegroundColor Cyan
    Write-Host ""

    $ParsedSkills = @()
    foreach ($skill in $SkillDirs) {
        $info = Parse-SkillFrontmatter -SkillPath $skill.FullName
        if ($info -and $info.Name) {
            $ParsedSkills += $info
        }
    }

    if ($ParsedSkills.Count -eq 0) {
        Write-Host "No skills with valid frontmatter found." -ForegroundColor Yellow
    } else {
        Write-Host "Parsed $($ParsedSkills.Count) skills." -ForegroundColor Green

        # --- Helper: pick first N chars of body as summary ---
        function Get-BodySummary {
            param([string]$Body, [int]$MaxChars = 500)
            $text = $Body -replace '#+', '' -replace '\*+', '' -replace '`+', ''
            $text = $text.Trim()
            if ($text.Length -le $MaxChars) { return $text }
            return $text.Substring(0, $MaxChars) + "..."
        }

        # ────────────────────────────────────────────────────────────
        #  2a — Codex: Global + Project AGENTS.md
        # ────────────────────────────────────────────────────────────
        $agentsLines = New-Object System.Collections.Generic.List[string]
        $agentsLines.Add("# AI Skills - Global Agent Instructions")
        $agentsLines.Add("")
        $agentsLines.Add("Generated by sync-skills.ps1 - do not edit manually")
        $agentsLines.Add("")
        $agentsLines.Add("This file is loaded before every Codex session. It consolidates all installed skills as always-on guidance.")
        $agentsLines.Add("")

        foreach ($s in $ParsedSkills) {
            $agentsLines.Add("## $($s.Name)")
            $agentsLines.Add("")
            $agentsLines.Add($s.Description)
            $agentsLines.Add("")
            $summary = Get-BodySummary -Body $s.Body
            if ($summary.Length -gt 0) {
                $agentsLines.Add($summary)
                $agentsLines.Add("")
            }
        }

        $agentsMdContent = $agentsLines -join "`r`n"

        $codexGlobalDir = "$env:USERPROFILE\.codex"
        if (-not (Test-Path $codexGlobalDir)) { New-Item -ItemType Directory -Path $codexGlobalDir -Force | Out-Null }
        Set-Content -LiteralPath (Join-Path $codexGlobalDir "AGENTS.md") -Value $agentsMdContent -Encoding utf8
        Write-Host "  [Codex] Generated global AGENTS.md" -ForegroundColor Green

        $projAgentsMd = Join-Path $ProjectRoot "AGENTS.md"
        Set-Content -LiteralPath $projAgentsMd -Value $agentsMdContent -Encoding utf8
        Write-Host "  [Codex] Generated project AGENTS.md at $ProjectRoot" -ForegroundColor Green

        # ────────────────────────────────────────────────────────────
        #  2b — Copilot: .github/copilot-instructions.md
        # ────────────────────────────────────────────────────────────
        $copilotLines = New-Object System.Collections.Generic.List[string]
        $copilotLines.Add("# AI Skills - Copilot Instructions")
        $copilotLines.Add("")
        $copilotLines.Add("Generated by sync-skills.ps1")
        $copilotLines.Add("")

        foreach ($s in $ParsedSkills) {
            $copilotLines.Add("## $($s.Name)")
            $copilotLines.Add("")
            $copilotLines.Add($s.Description)
            $copilotLines.Add("")
            $summary = Get-BodySummary -Body $s.Body
            if ($summary.Length -gt 0) {
                $copilotLines.Add($summary)
                $copilotLines.Add("")
            }
        }

        $copilotDir = Join-Path $ProjectRoot ".github"
        if (-not (Test-Path $copilotDir)) { New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null }
        Set-Content -LiteralPath (Join-Path $copilotDir "copilot-instructions.md") -Value ($copilotLines -join "`r`n") -Encoding utf8
        Write-Host "  [Copilot] Generated .github\copilot-instructions.md" -ForegroundColor Green

        # ────────────────────────────────────────────────────────────
        #  2c — Cursor: .mdc rule files (one per skill)
        # ────────────────────────────────────────────────────────────
        $cursorRulesDir = Join-Path $ProjectRoot ".cursor\rules"
        if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
        Get-ChildItem -LiteralPath $cursorRulesDir -Filter "skill-*.mdc" -ErrorAction SilentlyContinue | Remove-Item -Force

        foreach ($s in $ParsedSkills) {
            $escapedDesc = $s.Description -replace '"', '""'
            $lines = New-Object System.Collections.Generic.List[string]
            $lines.Add("---")
            $lines.Add("description: `"$escapedDesc`"")
            $lines.Add("alwaysApply: false")
            $lines.Add("---")
            $lines.Add("")
            $lines.Add("# $($s.Name)")
            $lines.Add("")
            $lines.Add($s.Body)
            Set-Content -LiteralPath (Join-Path $cursorRulesDir "skill-$($s.Name).mdc") -Value ($lines -join "`r`n") -Encoding utf8
        }
        Write-Host "  [Cursor] Generated $($ParsedSkills.Count) .mdc rule files in .cursor\rules\" -ForegroundColor Green

        # ────────────────────────────────────────────────────────────
        #  2d — Windsurf: .md rule files (one per skill)
        # ────────────────────────────────────────────────────────────
        $windsurfRulesDir = Join-Path $ProjectRoot ".windsurf\rules"
        if (-not (Test-Path $windsurfRulesDir)) { New-Item -ItemType Directory -Path $windsurfRulesDir -Force | Out-Null }
        Get-ChildItem -LiteralPath $windsurfRulesDir -Filter "skill-*.md" -ErrorAction SilentlyContinue | Remove-Item -Force

        foreach ($s in $ParsedSkills) {
            $escapedDesc = $s.Description -replace '"', '""'
            $lines = New-Object System.Collections.Generic.List[string]
            $lines.Add("---")
            $lines.Add("trigger: model_decision")
            $lines.Add("description: `"$escapedDesc`"")
            $lines.Add("---")
            $lines.Add("")
            $lines.Add("# $($s.Name)")
            $lines.Add("")
            $lines.Add($s.Body)
            Set-Content -LiteralPath (Join-Path $windsurfRulesDir "skill-$($s.Name).md") -Value ($lines -join "`r`n") -Encoding utf8
        }
        Write-Host "  [Windsurf] Generated $($ParsedSkills.Count) .md rule files in .windsurf\rules\" -ForegroundColor Green

        Write-Host ""
        Write-Host "=== Phase 2 Complete ===" -ForegroundColor Cyan
    }
}

# ─── Final message ────────────────────────────────────────────
Write-Host ""
if ($DryRun) {
    Write-Host "Run without -DryRun to apply." -ForegroundColor Green
} elseif ($ConvertRules) {
    Write-Host "Done. Skills synced and rules generated." -ForegroundColor Green
} else {
    Write-Host "Done. Skills synced to all targets." -ForegroundColor Green
    Write-Host "Tip: Use -ConvertRules to also generate rule/instruction files for Cursor, Windsurf, Copilot, and Codex." -ForegroundColor Yellow
}
