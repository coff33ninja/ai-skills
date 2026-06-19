param([switch]$Json)

$os = [Environment]::OSVersion.Platform
$isWindows = $os -eq [PlatformID]::Win32NT
$isLinux = $os -eq [PlatformID]::Unix -and (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "CurrentBuild" -ErrorAction SilentlyContinue) -eq $null
$isMacOS = (uname -s 2>$null) -eq "Darwin"

# Use uname for more reliable detection
$uname = if (Get-Command "uname" -ErrorAction SilentlyContinue) { uname -s } else { "" }
if ($uname -eq "Darwin") { $isMacOS = $true; $isLinux = $false; $isWindows = $false }
elseif ($uname -eq "Linux") { $isLinux = $true; $isWindows = $false; $isMacOS = $false }

$info = @{
    Platform = if ($isWindows) { "Windows" } elseif ($isMacOS) { "macOS" } elseif ($isLinux) { "Linux" } else { "Unknown" }
    Shell = if ($isWindows) { "PowerShell" } else { (Split-Path -Leaf ($env:SHELL -replace '\\','/')) }
    PathSep = if ($isWindows) { "\" } else { "/" }
    CaseSensitive = if ($isWindows) { $false } else { $true }
    LineEnding = if ($isWindows) { "CRLF" } else { "LF" }
    Notes = @()
}

if ($isWindows) { $info.Notes = @(
    "Use PowerShell cmdlets, not bash",
    "Paths: use \ or Join-Path",
    "Case-insensitive filesystem",
    "Executables: .exe, .ps1, .bat",
    "env: prefix for env vars (e.g. `$env:PATH`)"
)}
elseif ($isMacOS) { $info.Notes = @(
    "Use zsh/bash, not PowerShell",
    "Paths: use /",
    "Case-sensitive (APFS can be case-insensitive)",
    "Executables: no extension needed",
    "`$VAR for env vars",
    "screencapture for screenshots"
)}
elseif ($isLinux) { $info.Notes = @(
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
