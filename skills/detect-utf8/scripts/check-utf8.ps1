param(
    [switch]$Json,
    [switch]$Quiet
)

$results = @{
    PowerShellOutputEncoding   = "$($OutputEncoding.WebName)"
    ConsoleOutputEncoding      = "$([Console]::OutputEncoding.WebName)"
    DotNetDefaultEncoding      = "$([System.Text.Encoding]::Default.WebName)"
    DotNetDefaultCodePage      = [System.Text.Encoding]::Default.CodePage
    UTF8WithoutBOMAvailable    = $true
}

# Windows code page
if ($PSVersionTable.PSVersion.Major -ge 6 -or $IsWindows) {
    $cp = & chcp 2>$null
    if ($cp -match '(\d+)') { $results.WindowsCodePage = [int]$Matches[1] }
}

# Locale
if ($IsLinux -or $IsMacOS -or (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core")) {
    $results.LANG    = [Environment]::GetEnvironmentVariable("LANG")
    $results.LC_ALL  = [Environment]::GetEnvironmentVariable("LC_ALL")
    $results.LC_CTYPE = [Environment]::GetEnvironmentVariable("LC_CTYPE")
}

# Round-trip test
$testStr = "UTF8✨🔬✅"
$tempFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($tempFile, $testStr, [System.Text.UTF8Encoding]::new($false))
    $roundTrip = [System.IO.File]::ReadAllText($tempFile, [System.Text.UTF8Encoding]::new($false))
    $results.UTF8RoundTripPassed = ($roundTrip -eq $testStr)

    [System.IO.File]::WriteAllText($tempFile, $testStr, [System.Text.UTF8Encoding]::new($true))
    $roundTripBom = [System.IO.File]::ReadAllText($tempFile)
    $results.UTF8BOMRoundTripPassed = ($roundTripBom -eq $testStr)

    $bom = [System.IO.File]::ReadAllBytes($tempFile)[0..2]
    $results.UTF8FileHasBOM = (($bom[0] -eq 0xEF) -and ($bom[1] -eq 0xBB) -and ($bom[2] -eq 0xBF))
} finally {
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
}

# Overall conclusion
$utf8Ok = $results.UTF8RoundTripPassed
if ($results.ContainsKey("WindowsCodePage")) {
    $utf8Ok = $utf8Ok -and ($results.WindowsCodePage -eq 65001 -or $results.WindowsCodePage -eq 0)
}
if ($results.ContainsKey("LC_ALL")) { $utf8Ok = $utf8Ok -and $results.LC_ALL -match "UTF-8" }
if ($results.ContainsKey("LANG"))   { $utf8Ok = $utf8Ok -and $results.LANG -match "UTF-8" }

$results.UTF8Supported = $utf8Ok

if ($Quiet) { exit $(if ($utf8Ok) { 0 } else { 1 }) }

if ($Json) {
    $results | ConvertTo-Json
    return
}

Write-Host "=== UTF-8 Detection Report ===" -ForegroundColor Cyan
Write-Host "PowerShell OutputEncoding: $($results.PowerShellOutputEncoding)"
Write-Host "Console OutputEncoding:    $($results.ConsoleOutputEncoding)"
Write-Host ".NET Default Encoding:     $($results.DotNetDefaultEncoding) (code page $($results.DotNetDefaultCodePage))"
Write-Host "UTF-8 w/o BOM available:   $($results.UTF8WithoutBOMAvailable)"
if ($results.ContainsKey("WindowsCodePage")) {
    $cpName = switch ($results.WindowsCodePage) {
        65001 { "UTF-8" }
        437   { "US-ASCII / OEM" }
        932   { "Shift-JIS" }
        1252  { "Windows-1252 (Latin-1)" }
        default { "code page $($results.WindowsCodePage)" }
    }
    Write-Host "Windows code page:         $cpName"
}
if ($results.ContainsKey("LANG"))    { Write-Host "LANG:    $($results.LANG)" }
if ($results.ContainsKey("LC_ALL"))  { Write-Host "LC_ALL:  $($results.LC_ALL)" }
if ($results.ContainsKey("LC_CTYPE")) { Write-Host "LC_CTYPE: $($results.LC_CTYPE)" }
Write-Host "UTF-8 round-trip:          $(if ($results.UTF8RoundTripPassed) { '✅ passed' } else { '❌ failed' })"
Write-Host "UTF-8 BOM round-trip:      $(if ($results.UTF8BOMRoundTripPassed) { '✅ passed' } else { '❌ failed' })"
Write-Host "UTF-8 BOM present:         $($results.UTF8FileHasBOM)"
Write-Host ""

if ($utf8Ok) {
    Write-Host "[+] UTF-8 fully supported." -ForegroundColor Green
} else {
    Write-Host "[-] UTF-8 NOT fully supported." -ForegroundColor Yellow
    Write-Host "    Run 'chcp 65001' (Windows) or set LANG=en_US.UTF-8 (Unix)."
}
