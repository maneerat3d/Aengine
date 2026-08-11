param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path $RepoRoot).Path
$sdkRoot = Join-Path $RepoRoot "sdk\include\AEngine"

if (-not (Test-Path $sdkRoot)) {
    Write-Host "Public SDK root is missing: $sdkRoot" -ForegroundColor Red
    exit 1
}

function Get-Relative([string]$Path) {
    $prefix = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    return [IO.Path]::GetFullPath($Path).Substring($prefix.Length).Replace('\', '/')
}

$owners = @{}
$errors = @()
$manifestFiles = @()
foreach ($rootName in @("engine", "tools")) {
    $root = Join-Path $RepoRoot $rootName
    if (Test-Path $root) { $manifestFiles += Get-ChildItem $root -Recurse -File -Filter "MODULE.json" }
}

foreach ($file in ($manifestFiles | Sort-Object FullName)) {
    $manifest = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $module = [string]$manifest.module
    foreach ($declaredPath in @($manifest.public_api)) {
        $path = Join-Path $RepoRoot ([string]$declaredPath)
        if (-not (Test-Path $path)) { $errors += "$module declares missing public API path '$declaredPath'"; continue }
        $item = Get-Item $path
        $files = if ($item.PSIsContainer) {
            @(Get-ChildItem $path -Recurse -File | Where-Object { $_.Extension -in @(".h", ".hpp") })
        }
        else { @($item) }

        foreach ($header in $files) {
            $relative = Get-Relative $header.FullName
            if (-not $relative.StartsWith("sdk/include/AEngine/")) {
                $errors += "$module public API path escapes sdk/include/AEngine: $relative"
                continue
            }
            if (-not $owners.ContainsKey($relative)) { $owners[$relative] = @() }
            $owners[$relative] += $module
        }
    }
}

$publicHeaders = @(Get-ChildItem $sdkRoot -Recurse -File | Where-Object { $_.Extension -in @(".h", ".hpp") })
foreach ($header in $publicHeaders) {
    $relative = Get-Relative $header.FullName
    if (-not $owners.ContainsKey($relative)) {
        $errors += "Orphan public header has no module owner: $relative"
        continue
    }
    $uniqueOwners = @($owners[$relative] | Sort-Object -Unique)
    if ($uniqueOwners.Count -ne 1) {
        $errors += "Public header must have exactly one owner: $relative -> $($uniqueOwners -join ', ')"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Public API ownership validation failed:" -ForegroundColor Red
    $errors | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Public API ownership is unique for $($publicHeaders.Count) header(s)"
exit 0
