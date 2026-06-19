param(
    [Parameter(Mandatory)][string]$Description,
    [switch]$Draft,
    [switch]$DryRun
)

# Prerequisites
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) { Write-Host "[-] gh CLI required"; exit 1 }
try { gh auth status 2>&1 | Out-Null } catch { Write-Host "[-] Not authenticated to GitHub"; exit 1 }

$branch = "codex/$($Description -replace '\s+','-')"

if ($DryRun) {
    Write-Host "[DRY-RUN] Branch: $branch"
    Write-Host "[DRY-RUN] Commit: $Description"
    Write-Host "[DRY-RUN] Would push and open PR"
    exit 0
}

# Create branch if on main
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -in @("main","master","develop")) {
    git checkout -b $branch
}

git add -A
git commit -m $Description
git push -u origin (git branch --show-current)

$prArgs = @("pr","create","--fill","--head",(git branch --show-current))
if ($Draft) { $prArgs += "--draft" }

$env:GH_PROMPT_DISABLED = "1"
$env:GIT_TERMINAL_PROMPT = "0"
& "gh" $prArgs
