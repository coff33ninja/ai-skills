param(
    [Parameter(Mandatory)][string]$PackageName,
    [ValidateSet("npm","pypi","cargo","nuget","go")][string]$Registry = "npm"
)

switch ($Registry) {
    "npm"   { $url = "https://registry.npmjs.org/$PackageName/latest" }
    "pypi"  { $url = "https://pypi.org/pypi/$PackageName/json" }
    "cargo" { $url = "https://crates.io/api/v1/crates/$PackageName" }
    "nuget" { $url = "https://api.nuget.org/v3-flatcontainer/$PackageName/index.json" }
    "go"    { $url = "https://proxy.golang.org/$($PackageName.Replace('/','%2F'))/@latest" }
}

Write-Host "[*] Checking $PackageName on $Registry ..." -NoNewline
try {
    $resp = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
    if ($resp.StatusCode -eq 200) {
        Write-Host " [EXISTS]" -ForegroundColor Green
        exit 0
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host " [NOT FOUND]" -ForegroundColor Red
    } else {
        Write-Host " [ERROR: $_]" -ForegroundColor Yellow
    }
    exit 1
}
