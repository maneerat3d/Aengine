param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path $RepoRoot).Path

$errors = @()
$invariantOwners = @{}
$stateOwners = @{}

function Add-Error([string]$Message) {
    $script:errors += $Message
}

function Has-Property($Object, [string]$Name) {
    return $null -ne $Object.PSObject.Properties[$Name]
}

function Require-Text($Object, [string]$Name, [string]$Module) {
    if (-not (Has-Property $Object $Name) -or [string]::IsNullOrWhiteSpace([string]$Object.$Name)) {
        Add-Error "$Module requires non-empty '$Name'"
        return $false
    }
    return $true
}

$testText = ""
$testCMake = Join-Path $RepoRoot "tests\CMakeLists.txt"
if (Test-Path $testCMake) { $testText = Get-Content $testCMake -Raw }
$knownTests = @([regex]::Matches($testText, 'add_test\s*\(\s*NAME\s+([^\s\)]+)', 'IgnoreCase') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)

$manifestFiles = @()
foreach ($rootName in @("engine", "tools")) {
    $root = Join-Path $RepoRoot $rootName
    if (Test-Path $root) {
        $manifestFiles += Get-ChildItem $root -Recurse -File -Filter "MODULE.json"
    }
}

foreach ($file in ($manifestFiles | Sort-Object FullName)) {
    try { $manifest = Get-Content $file.FullName -Raw | ConvertFrom-Json }
    catch { Add-Error "Invalid JSON: $($file.FullName): $($_.Exception.Message)"; continue }

    $module = if (Has-Property $manifest "module") { [string]$manifest.module } else { $file.FullName }
    if (-not (Has-Property $manifest "schema_version") -or [int]$manifest.schema_version -ne 2) {
        Add-Error "$module must use MODULE.json schema_version 2"
    }

    foreach ($field in @("module", "kind", "owner", "responsibility")) {
        [void](Require-Text $manifest $field $module)
    }
    if ($manifest.owner -match '^(?i:tbd|unknown|none)$') {
        Add-Error "$module owner must be a stable subsystem owner, not '$($manifest.owner)'"
    }

    foreach ($arrayField in @("public_api", "implementation", "tests", "allowed_dependencies",
                              "forbidden_dependencies", "state_owners", "mutation_gateway",
                              "invariants", "entry_points", "skills", "stop_line")) {
        if (-not (Has-Property $manifest $arrayField)) { Add-Error "$module requires '$arrayField'" }
    }

    if (@($manifest.implementation).Count -eq 0) { Add-Error "$module requires implementation path(s)" }
    if (@($manifest.tests).Count -eq 0) { Add-Error "$module requires focused tests" }
    if (@($manifest.mutation_gateway).Count -eq 0) { Add-Error "$module requires mutation_gateway" }
    if (@($manifest.invariants).Count -eq 0) { Add-Error "$module requires invariant(s)" }
    if (@($manifest.entry_points).Count -eq 0) { Add-Error "$module requires entry_points" }
    if (@($manifest.stop_line).Count -eq 0) { Add-Error "$module requires stop_line" }

    if (-not (Has-Property $manifest "lifetime")) {
        Add-Error "$module requires lifetime contract"
    }
    else {
        foreach ($field in @("scope", "creation", "shutdown")) {
            [void](Require-Text $manifest.lifetime $field $module)
        }
    }

    if (-not (Has-Property $manifest "threading")) {
        Add-Error "$module requires threading contract"
    }
    else {
        foreach ($field in @("affinity", "concurrency")) {
            [void](Require-Text $manifest.threading $field $module)
        }
    }

    $tests = @($manifest.tests | ForEach-Object { [string]$_ })
    foreach ($test in $tests) {
        if ($test -notin $knownTests) { Add-Error "$module declares missing CTest '$test'" }
    }

    if ([string]$manifest.kind -eq "library" -and "cpp-oop-design" -notin @($manifest.skills)) {
        Add-Error "$module library must route class/ownership work through cpp-oop-design"
    }

    foreach ($dependency in @($manifest.allowed_dependencies)) {
        if ([string]$dependency -eq $module) { Add-Error "$module cannot depend on itself" }
    }

    foreach ($stateOwner in @($manifest.state_owners)) {
        $name = [string]$stateOwner
        if ([string]::IsNullOrWhiteSpace($name)) { Add-Error "$module has empty state owner"; continue }
        if ($stateOwners.ContainsKey($name)) {
            Add-Error "Mutable state owner '$name' is declared by both $($stateOwners[$name]) and $module"
        }
        else { $stateOwners[$name] = $module }
    }

    if (@($manifest.state_owners).Count -gt 0 -and
        @($manifest.mutation_gateway | ForEach-Object { ([string]$_).ToLowerInvariant() }) -eq @("none")) {
        Add-Error "$module owns mutable state but mutation_gateway is none"
    }

    foreach ($invariant in @($manifest.invariants)) {
        foreach ($field in @("id", "text", "test")) {
            [void](Require-Text $invariant $field $module)
        }
        $id = [string]$invariant.id
        if ($id -notmatch '^[A-Z][A-Z0-9]*-[0-9]{3}$') {
            Add-Error "$module invariant '$id' must use stable form PREFIX-001"
        }
        elseif ($invariantOwners.ContainsKey($id)) {
            Add-Error "Invariant '$id' is duplicated by $($invariantOwners[$id]) and $module"
        }
        else { $invariantOwners[$id] = $module }

        if ([string]$invariant.test -notin $tests) {
            Add-Error "$module invariant '$id' references test '$($invariant.test)' not declared by the module"
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Module contract v2 validation failed:" -ForegroundColor Red
    $errors | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Module contract v2 validation passed for $($manifestFiles.Count) module(s)"
exit 0
