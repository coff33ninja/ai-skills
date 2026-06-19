param(
    [string]$ProjectPath = ".",
    [string]$OutputFile = "QA_REVIEW.md",
    [string]$FileFilter = "*.py"
)

$resolved = Resolve-Path $ProjectPath
$files = Get-ChildItem -LiteralPath $resolved -Recurse -Filter $FileFilter

$template = @"
# Code Review: $(Split-Path -Leaf $resolved)

## Summary
- Files: $($files.Count) matching $FileFilter
- Reviewer: {your name}
- Date: $(Get-Date -Format yyyy-MM-dd)

## Files to Review
$($files | ForEach-Object { "- $_" } | Out-String)

## Review Checklist
- [ ] Logic is correct and handles edge cases
- [ ] Naming is clear and consistent with project conventions
- [ ] Functions are appropriately sized (under 50 lines)
- [ ] Error handling is robust
- [ ] No obvious security issues (injection, auth, secrets)
- [ ] Tests exist and cover the changes
- [ ] Performance considerations addressed

## Issues Found
| # | File | Severity | Description |
|---|------|----------|-------------|
|   |      |          |             |

## Suggestions
- ...
"@

$template | Set-Content -LiteralPath $OutputFile -Encoding utf8
Write-Host "[+] QA review template written to $OutputFile" -ForegroundColor Green
