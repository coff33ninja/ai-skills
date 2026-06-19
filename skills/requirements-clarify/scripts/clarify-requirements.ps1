param([string]$Topic, [string]$OutputFile = "REQUIREMENTS.md")

if (-not $Topic) { Write-Host "Usage: .\clarify-requirements.ps1 -Topic <feature-or-task> [-OutputFile REQUIREMENTS.md]"; exit 1 }

$template = @"
# Requirements: $Topic

## Goal
_What problem does this solve?_

## Scope
_In scope:_
- ...

_Out of scope:_
- ...

## User Stories / Acceptance Criteria
- [ ] As a user, I can...
- [ ] ...

## Technical Constraints
- Platform: {Windows/macOS/Linux/cross-platform}
- Language/Framework: {target stack}
- Dependencies: {key libraries}

## Data / API
- Input format: {JSON, CSV, CLI args...}
- Output format: {JSON, stdout, file...}
- Error handling: {how are errors surfaced}

## Edge Cases & Risks
- {e.g., empty input, network failure, large payloads}

## Verification
- {How will we confirm it works?}
"@

$template | Set-Content -LiteralPath $OutputFile -Encoding utf8
Write-Host "[+] Requirements clarification template: $OutputFile" -ForegroundColor Green
Write-Host "    Fill out each section by asking the user one question at a time."
Write-Host "    Start with: 'What specific problem does $Topic solve?'"
