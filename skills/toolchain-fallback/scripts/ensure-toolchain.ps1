param(
    [switch]$InstallMissing,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

function Write-Status { param([string]$Label, [bool]$Ok)
    $icon = if ($Ok) { "[+]" } else { "[-]" }
    Write-Host "$icon $Label"
}

function Test-Command { param([string]$Name)
    $null = Get-Command $Name -ErrorAction SilentlyContinue; return $?
}

Write-Host "=== Toolchain Detection ===" -ForegroundColor Cyan

$results = @()

# MSYS2
$msys2Paths = @("C:\msys64\usr\bin\gcc.exe","C:\msys32\usr\bin\gcc.exe","$env:USERPROFILE\scoop\apps\msys2\current\usr\bin\gcc.exe")
$msys2Found = ($msys2Paths | Where-Object { Test-Path $_ }).Count -gt 0 -or (Test-Command "gcc")
Write-Status "MSYS2 (gcc/make)" $msys2Found; $results += @{Name="MSYS2"; Found=$msys2Found}

# Zig
$zigFound = (Test-Command "zig") -or (Test-Path "$env:LOCALAPPDATA\zig\zig.exe")
Write-Status "Zig (zig)" $zigFound; $results += @{Name="Zig"; Found=$zigFound}

# Clang
$clangFound = Test-Command "clang"
Write-Status "Clang/LLVM (clang)" $clangFound; $results += @{Name="Clang"; Found=$clangFound}

# GCC standalone
$gccFound = Test-Command "gcc"
Write-Status "GCC (standalone)" $gccFound; $results += @{Name="GCC"; Found=$gccFound}

# Visual Studio
$vsFound = $false
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) { $vsPath = & $vswhere -latest -property installationPath 2>$null; if ($vsPath) { $vsFound = $true } }
Write-Status "Visual Studio (MSBuild)" $vsFound; $results += @{Name="Visual Studio"; Found=$vsFound}

# Make / Ninja
$makeFound = (Test-Command "make") -or (Test-Command "ninja")
Write-Status "Make/Ninja" $makeFound; $results += @{Name="Make/Ninja"; Found=$makeFound}

$any = ($results | Where-Object { $_.Found }).Count
Write-Host "$any of $($results.Count) toolchains found." -ForegroundColor Cyan

if ($InstallMissing -and -not $any) {
    Write-Host "No toolchain found — installing Zig as fallback..." -ForegroundColor Yellow
    if ($DryRun) { Write-Host "[DRY-RUN] Would install zig to $env:LOCALAPPDATA\zig"; exit 0 }

    $tmpDir = "$env:TEMP\zig-install"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    try {
        $index = Invoke-RestMethod -Uri "https://ziglang.org/download/index.json" -TimeoutSec 30
        $version = if ($index.PSObject.Properties.Name -match '^\d+\.\d+\.\d+$') {
            ($index.PSObject.Properties.Name | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object -Descending)[0]
        } else { $index.master.version }
        $zipUrl = "https://ziglang.org/builds/zig-windows-x86_64-$version.zip"
        $zipPath = Join-Path $tmpDir "zig.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -TimeoutSec 120
        Expand-Archive -LiteralPath $zipPath -DestinationPath "$env:LOCALAPPDATA\zig" -Force
        $nested = Get-ChildItem "$env:LOCALAPPDATA\zig" -Directory | Where-Object { $_.Name -match '^zig-' } | Select-Object -First 1
        if ($nested) { Move-Item "$($nested.FullName)\*" "$env:LOCALAPPDATA\zig\" -Force; Remove-Item $nested.FullName -Recurse -Force }
        $userPath = [Environment]::GetEnvironmentVariable("PATH","User")
        if ($userPath -notlike "*$env:LOCALAPPDATA\zig*") {
            [Environment]::SetEnvironmentVariable("PATH","$env:LOCALAPPDATA\zig;$userPath","User")
        }
        Write-Host "[+] Zig installed" -ForegroundColor Green
    } catch { Write-Host "[ERROR] Zig install failed: $_" -ForegroundColor Red; exit 1 }
    finally { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}
