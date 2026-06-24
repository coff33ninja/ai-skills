param(
    [string]$ProjectPath = ".",
    [string]$FileFilter = "*.py"
)

$resolved = Resolve-Path $ProjectPath
$files = Get-ChildItem -LiteralPath $resolved -Recurse -Filter $FileFilter

Write-Host "=== Unused Import Analysis: $(Split-Path -Leaf $resolved) ===" -ForegroundColor Cyan
Write-Host "Scanning $($files.Count) files matching $FileFilter`n"

$totalSuggestions = 0
foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $ext = $file.Extension

    $pattern = switch ($ext) {
        ".py"  { '(?m)^(?:import |from )\s+(\S+)' }
        ".js"  { '(?m)^(?:import |const .* = require\()\s*["'"']?([^"'"'\s;]+)' }
        ".ts"  { '(?m)^(?:import |import type |const .* = require\()\s*["'"']?([^"'"'\s;]+)' }
        ".go"  { '(?m)^\s*import\s+"([^"]+)"' }
        ".rs"  { '(?m)^(?:use |use )\s+([^;{]+)' }
        default { $null }
    }

    if (-not $pattern) { continue }

    $imports = [regex]::Matches($content, $pattern)
    $suggestions = @()

    foreach ($imp in $imports) {
        $name = $imp.Groups[1].Value.Trim()
        $shortName = $name.Split('/')[-1].Split('.')[-1]

        $afterImport = $content.Substring($imp.Index + $imp.Length)
        if (-not [regex]::IsMatch($afterImport, "\b$([regex]::Escape($shortName))\b")) {
            $suggestions += $name
        }
    }

    if ($suggestions.Count -gt 0) {
        Write-Host "=== $($file.FullName) ===" -ForegroundColor Cyan
        foreach ($s in $suggestions) {
            $context = ""
            $lines = $content -split "`n"
            $importLine = $lines | Where-Object { $_ -match [regex]::Escape($s) }
            $lineNum = 0
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match [regex]::Escape($s)) { $lineNum = $i + 1; break }
            }

            # Check comments/TODOs near the import
            $nearby = ($lines[($lineNum-1)..($lineNum+5)] -join "`n")
            $todos = [regex]::Matches($nearby, 'TODO|FIXME|HACK|XXX|NOTE')
            if ($todos.Count -gt 0) {
                $context = " (nearby: $($todos.Value -join ', '))"
            }

            Write-Host "  Import: $s"
            Write-Host "  Inferred intent: symbol '$shortName' available but unused$context"
            Write-Host "  Suggestion: search for patterns where $shortName would fit"
            Write-Host ""
        }
        $totalSuggestions += $suggestions.Count
    }
}

if ($totalSuggestions -eq 0) {
    Write-Host "[+] No unused imports found." -ForegroundColor Green
    exit 0
}
Write-Host "Found $totalSuggestions import(s) needing implementation — implement usage, don't delete."
exit 0
