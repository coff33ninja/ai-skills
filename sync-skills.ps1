param(
    [ValidateSet("Agents", "Claude", "Codex", "Copilot", "Cursor", "Gemini", "Antigravity", "Kiro", "Windsurf", "Continue", "Augment", "Tabnine", "Cline", "RooCode")]
    [string[]]$Tool,
    [string]$ProjectRoot,
    [switch]$DryRun,
    [switch]$ConvertRules
)

$Source = Join-Path -Path $PSScriptRoot -ChildPath "skills"
if (-not (Test-Path $Source)) {
    Write-Error "Source skills directory not found: $Source"
    exit 1
}

$SkillDirs = Get-ChildItem -LiteralPath $Source -Directory

# ─── Tool path map & filtering ─────────────────────────────────
$ToolPaths = [ordered]@{
    Agents      = "$env:USERPROFILE\.agents\skills"
    Claude      = "$env:USERPROFILE\.claude\skills"
    Codex       = "$env:USERPROFILE\.codex\skills"
    Copilot     = "$env:USERPROFILE\.copilot\skills"
    Cursor      = "$env:USERPROFILE\.cursor\skills"
    Gemini      = "$env:USERPROFILE\.gemini\skills"
    Antigravity = "$env:USERPROFILE\.gemini\antigravity\skills"
    Kiro        = "$env:USERPROFILE\.kiro\skills"
    Windsurf    = "$env:USERPROFILE\.codeium\windsurf\skills"
    Continue    = "$env:USERPROFILE\.continue\skills"
    Augment     = "$env:USERPROFILE\.augment\skills"
    Tabnine     = "$env:USERPROFILE\.tabnine\agent\skills"
    Cline       = "$env:USERPROFILE\.cline\skills"
    RooCode     = "$env:USERPROFILE\.roo\skills"
}

$activeTools = if ($Tool) { $Tool } else { $ToolPaths.Keys }
$Targets = $activeTools | ForEach-Object { $ToolPaths[$_] }

# ─── Helper: parse SKILL.md frontmatter ─────────────────────────────
function Parse-SkillFrontmatter {
    param([string]$SkillPath)
    $mdPath = Join-Path $SkillPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { return $null }
    $content = Get-Content -LiteralPath $mdPath -Raw
    if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)') {
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
        return @{ Name = $name; Description = $description; Body = $body }
    }
    return $null
}

# ─── Helper: write UTF-8 without BOM (cross-PS-version) ─────────────
function Set-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Value, $utf8)
}

# ─── Helper: sanitize a string for use in filenames ────────────────
function Get-SafeFileName {
    param([string]$Name)
    return $Name -replace '[^\w\-\.]', '_'
}

# ═════════════════════════════════════════════════════════════════════
#  PHASE 1 — Sync SKILL.md directories to all tool skill paths
# ═════════════════════════════════════════════════════════════════════

Write-Host "=== Phase 1: Syncing skills to tool skill paths ===" -ForegroundColor Cyan
Write-Host ""

$Summary = @()

foreach ($target in $Targets) {
    $absTarget = $target

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
            $text = $Body -replace '(?m)^#+\s*', '' -replace '\*\*?', '' -replace '`[^`\r\n]*`', ''
            $text = $text.Trim()
            if ($text.Length -le $MaxChars) { return $text }
            return $text.Substring(0, $MaxChars) + "..."
        }

        # ────────────────────────────────────────────────────────────
        #  2a — Codex: Global + Project AGENTS.md
        # ────────────────────────────────────────────────────────────
        if ($activeTools -contains "Codex") {
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
            Set-Utf8NoBom -Path (Join-Path $codexGlobalDir "AGENTS.md") -Value $agentsMdContent
            Write-Host "  [Codex] Generated global AGENTS.md" -ForegroundColor Green

            if ($ProjectRoot) {
                $projAgentsMd = Join-Path $ProjectRoot "AGENTS.md"
                Set-Utf8NoBom -Path $projAgentsMd -Value $agentsMdContent
                Write-Host "  [Codex] Generated project AGENTS.md at $ProjectRoot" -ForegroundColor Green
            }
        }

        # ─── Helper: write a single rule file and report ─────────────
        function Write-RuleFile {
            param([string]$Path, [string]$Label)
            $dir = Split-Path $Path -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Set-Utf8NoBom -Path $Path -Value $args[0]
            Write-Host "  $Label" -ForegroundColor Green
        }

        # ────────────────────────────────────────────────────────────
        #  2b — Copilot: copilot-instructions.md
        # ────────────────────────────────────────────────────────────
        if ($activeTools -contains "Copilot") {
            $lines = New-Object System.Collections.Generic.List[string]
            $lines.Add("# AI Skills - Copilot Instructions")
            $lines.Add("")
            $lines.Add("Generated by sync-skills.ps1")
            $lines.Add("")
            foreach ($s in $ParsedSkills) {
                $lines.Add("## $($s.Name)"); $lines.Add("")
                $lines.Add($s.Description); $lines.Add("")
                $summary = Get-BodySummary -Body $s.Body
                if ($summary.Length -gt 0) { $lines.Add($summary); $lines.Add("") }
            }
            $content = $lines -join "`r`n"

            if ($ProjectRoot) {
                $copilotDir = Join-Path $ProjectRoot ".github"
                Write-RuleFile (Join-Path $copilotDir "copilot-instructions.md") "[Copilot] Generated .github\copilot-instructions.md at $ProjectRoot" $content
            } else {
                $copilotDir = "$env:USERPROFILE\.copilot"
                Write-RuleFile (Join-Path $copilotDir "copilot-instructions.md") "[Copilot] Generated copilot-instructions.md at $copilotDir" $content
            }
        }

        # ────────────────────────────────────────────────────────────
        #  2c — Cursor: .mdc rule files (one per skill)
        # ────────────────────────────────────────────────────────────
        if ($activeTools -contains "Cursor") {
            $cursorDir = if ($ProjectRoot) { Join-Path $ProjectRoot ".cursor\rules" } else { "$env:USERPROFILE\.cursor\rules" }
            if (-not (Test-Path $cursorDir)) { New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null }
            Get-ChildItem -LiteralPath $cursorDir -Filter "skill-*.mdc" -ErrorAction SilentlyContinue | Remove-Item -Force

            foreach ($s in $ParsedSkills) {
                $safeName = Get-SafeFileName -Name $s.Name
                $escapedDesc = $s.Description -replace '"', '""'
                $ruleLines = New-Object System.Collections.Generic.List[string]
                $ruleLines.Add("---"); $ruleLines.Add("description: `"$escapedDesc`""); $ruleLines.Add("alwaysApply: false"); $ruleLines.Add("---"); $ruleLines.Add("")
                $ruleLines.Add("# $($s.Name)"); $ruleLines.Add(""); $ruleLines.Add($s.Body)
                Set-Utf8NoBom -Path (Join-Path $cursorDir "skill-$safeName.mdc") -Value ($ruleLines -join "`r`n")
            }
            Write-Host "  [Cursor] Generated $($ParsedSkills.Count) .mdc rule files in $cursorDir" -ForegroundColor Green
        }

        # ────────────────────────────────────────────────────────────
        #  2d — Windsurf: .md rule files (one per skill)
        # ────────────────────────────────────────────────────────────
        if ($activeTools -contains "Windsurf") {
            $windsurfDir = if ($ProjectRoot) { Join-Path $ProjectRoot ".windsurf\rules" } else { "$env:USERPROFILE\.codeium\windsurf\rules" }
            if (-not (Test-Path $windsurfDir)) { New-Item -ItemType Directory -Path $windsurfDir -Force | Out-Null }
            Get-ChildItem -LiteralPath $windsurfDir -Filter "skill-*.md" -ErrorAction SilentlyContinue | Remove-Item -Force

            foreach ($s in $ParsedSkills) {
                $safeName = Get-SafeFileName -Name $s.Name
                $escapedDesc = $s.Description -replace '"', '""'
                $ruleLines = New-Object System.Collections.Generic.List[string]
                $ruleLines.Add("---"); $ruleLines.Add("trigger: model_decision"); $ruleLines.Add("description: `"$escapedDesc`""); $ruleLines.Add("---"); $ruleLines.Add("")
                $ruleLines.Add("# $($s.Name)"); $ruleLines.Add(""); $ruleLines.Add($s.Body)
                Set-Utf8NoBom -Path (Join-Path $windsurfDir "skill-$safeName.md") -Value ($ruleLines -join "`r`n")
            }
            Write-Host "  [Windsurf] Generated $($ParsedSkills.Count) .md rule files in $windsurfDir" -ForegroundColor Green
        }

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
