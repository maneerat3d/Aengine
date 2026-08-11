param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path $RepoRoot).Path
$mapRoot = Join-Path $RepoRoot ".agent\code-map\current\modules"

if (-not (Test-Path $mapRoot)) {
    Write-Host "AI module map is missing: $mapRoot" -ForegroundColor Red
    exit 1
}

$graph = @{}
foreach ($file in Get-ChildItem $mapRoot -File -Filter "*.json" | Sort-Object Name) {
    $map = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $module = [string]$map.module
    $graph[$module] = @($map.observed.dependencies | ForEach-Object { [string]$_ })
}

$errors = @()
foreach ($module in @($graph.Keys)) {
    foreach ($dependency in @($graph[$module])) {
        if ($dependency.StartsWith("aengine_") -and -not $graph.ContainsKey($dependency)) {
            $errors += "$module depends on unmapped production target $dependency"
        }
    }
}

$state = @{}
$stack = New-Object System.Collections.Generic.List[string]
$script:cycle = $null

function Visit-Module([string]$Module) {
    if ($script:cycle) { return }
    $status = if ($state.ContainsKey($Module)) { [string]$state[$Module] } else { "unvisited" }
    if ($status -eq "visited") { return }
    if ($status -eq "visiting") {
        $index = $stack.IndexOf($Module)
        $items = @()
        if ($index -ge 0) {
            for ($i = $index; $i -lt $stack.Count; ++$i) { $items += $stack[$i] }
        }
        $items += $Module
        $script:cycle = $items -join " -> "
        return
    }

    $state[$Module] = "visiting"
    [void]$stack.Add($Module)
    foreach ($dependency in @($graph[$Module])) {
        if ($graph.ContainsKey($dependency)) { Visit-Module $dependency }
        if ($script:cycle) { return }
    }
    $stack.RemoveAt($stack.Count - 1)
    $state[$Module] = "visited"
}

foreach ($module in @($graph.Keys | Sort-Object)) {
    Visit-Module $module
    if ($script:cycle) { break }
}

if ($script:cycle) { $errors += "Production dependency cycle: $script:cycle" }

if ($errors.Count -gt 0) {
    Write-Host "Production dependency graph validation failed:" -ForegroundColor Red
    $errors | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Production dependency graph is acyclic across $($graph.Count) mapped module(s)"
exit 0
