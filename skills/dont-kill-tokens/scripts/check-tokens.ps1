param(
    [string]$FilePath,
    [int]$MaxTokens = 4000
)

if (-not $FilePath) { Write-Host "Usage: .\check-tokens.ps1 -FilePath <file> [-MaxTokens 4000]"; exit 1 }
if (-not (Test-Path $FilePath)) { Write-Host "[-] File not found: $FilePath"; exit 1 }

$content = Get-Content -LiteralPath $FilePath -Raw
$charCount = $content.Length
$wordCount = $content.Split(@(' ','`n','`r','`t'), [StringSplitOptions]::RemoveEmptyEntries).Count

# Rough token estimate: ~4 chars per token for code, ~1.3 words per token
$tokenEstimate = [Math]::Max(
    [int]($charCount / 4),
    [int]($wordCount / 1.3)
)

$pct = [Math]::Round(($tokenEstimate / $MaxTokens) * 100, 1)

Write-Host "=== Token Check: $(Split-Path -Leaf $FilePath) ===" -ForegroundColor Cyan
Write-Host "Characters: $charCount  |  Words: $wordCount  |  Est. tokens: $tokenEstimate"
Write-Host "Budget: $MaxTokens tokens  |  Used: $pct%"

if ($tokenEstimate -gt $MaxTokens) {
    Write-Host "[-] EXCEEDS budget by $($tokenEstimate - $MaxTokens) tokens" -ForegroundColor Red
    Write-Host "    Consider: removing dead code, simplifying expressions, splitting file"
    exit 1
} elseif ($tokenEstimate -gt ($MaxTokens * 0.8)) {
    Write-Host "[-] WARNING: Over 80% of token budget" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "[+] Within token budget" -ForegroundColor Green
    exit 0
}
