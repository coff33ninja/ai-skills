param([switch]$Json)

$os = [Environment]::OSVersion.Platform

# Use non-automatic variable names (avoid $isWindows/$isLinux which are PS built-ins)
$winOS = $os -eq [PlatformID]::Win32NT
$unameOut = if (Get-Command "uname" -ErrorAction SilentlyContinue) { & uname -s } else { "" }
$macOS = $unameOut -eq "Darwin"
$linuxOS = $unameOut -eq "Linux" -or ($os -eq [PlatformID]::Unix -and -not $macOS)

$info = @{
    Platform = if ($winOS) { "Windows" } elseif ($macOS) { "macOS" } elseif ($linuxOS) { "Linux" } else { "Unknown" }
    Shell = if ($winOS) { "PowerShell" } else { (Split-Path -Leaf ($env:SHELL -replace '\\','/')) }
    PathSep = if ($winOS) { "\" } else { "/" }
    CaseSensitive = if ($winOS) { $false } else { $true }
    LineEnding = if ($winOS) { "CRLF" } else { "LF" }
    Notes = @()
}

if ($winOS) { $info.Notes = @(
    "Use PowerShell cmdlets, not bash",
    "Paths: use \ or Join-Path",
    "Case-insensitive filesystem",
    "Executables: .exe, .ps1, .bat",
    "env: prefix for env vars (e.g. `$env:PATH`)"
)}
elseif ($macOS) { $info.Notes = @(
    "Use zsh/bash, not PowerShell",
    "Paths: use /",
    "Case-sensitive (APFS can be case-insensitive)",
    "Executables: no extension needed",
    "`$VAR for env vars",
    "screencapture for screenshots"
)}
elseif ($linuxOS) { $info.Notes = @(
    "Use bash, not PowerShell",
    "Paths: use /",
    "Case-sensitive filesystem",
    "Executables: no extension needed",
    "`$VAR for env vars",
    "scrot/gnome-screenshot for screenshots"
)}

if ($Json) { $info | ConvertTo-Json }
else {
    Write-Host "=== OS Detection ===" -ForegroundColor Cyan
    $info.Keys | Sort-Object | ForEach-Object { 
        if ($_ -ne "Notes") { Write-Host "$_`: $($info.$_)" }
    }
    Write-Host "Notes:" -ForegroundColor Yellow
    $info.Notes | ForEach-Object { Write-Host "  - $_" }
}
