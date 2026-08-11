param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path $RepoRoot).Path

$roots = @(
    (Join-Path $RepoRoot "engine"),
    (Join-Path $RepoRoot "sdk\include\AEngine"),
    (Join-Path $RepoRoot "tools")
)
$bannedNames = @(
    "EngineManager", "SystemManager", "GlobalContext", "ServiceLocator",
    "Everything", "Misc", "Common", "Utils"
)
$errors = @()
$inheritance = @{}

function Get-Relative([string]$Path) {
    $prefix = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    return [IO.Path]::GetFullPath($Path).Substring($prefix.Length).Replace('\', '/')
}

$sourceFiles = @()
foreach ($root in $roots) {
    if (Test-Path $root) {
        $sourceFiles += Get-ChildItem $root -Recurse -File | Where-Object {
            $_.Extension -in @(".h", ".hpp", ".cpp", ".cc", ".cxx")
        }
    }
}

foreach ($file in ($sourceFiles | Sort-Object FullName -Unique)) {
    $relative = Get-Relative $file.FullName
    $stem = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    if ($stem -in $bannedNames) {
        $errors += "Generic production file name is forbidden: $relative"
    }

    $text = Get-Content $file.FullName -Raw
    foreach ($name in $bannedNames) {
        if ([regex]::IsMatch($text, '(?m)^\s*(?:class|struct)\s+' + [regex]::Escape($name) + '\b')) {
            $errors += "Generic production owner '$name' is forbidden: $relative"
        }
    }

    if ([regex]::IsMatch($text, '\bEngine\s*::\s*Get\s*\(')) {
        $errors += "Global Engine::Get service access is forbidden: $relative"
    }
    if ([regex]::IsMatch($text, '\bGetInstance\s*\(')) {
        $errors += "Singleton-style GetInstance access is forbidden: $relative"
    }
    if ([regex]::IsMatch($text, '\bServiceLocator\b')) {
        $errors += "ServiceLocator access is forbidden: $relative"
    }

    foreach ($match in [regex]::Matches($text,
        '(?m)^\s*(?:class|struct)\s+([A-Za-z_]\w*)\s*:\s*(?:public|protected|private)?\s*([A-Za-z_]\w*)')) {
        $derived = $match.Groups[1].Value
        $base = $match.Groups[2].Value
        if (-not $inheritance.ContainsKey($derived)) { $inheritance[$derived] = $base }
    }
}

foreach ($type in @($inheritance.Keys)) {
    $seen = @{}
    $current = $type
    $depth = 0
    while ($inheritance.ContainsKey($current)) {
        if ($seen.ContainsKey($current)) {
            $errors += "Inheritance cycle detected at type '$type'"
            break
        }
        $seen[$current] = $true
        $current = [string]$inheritance[$current]
        ++$depth
        if ($depth -gt 2) {
            $errors += "Inheritance depth exceeds 2 for '$type'; prefer composition"
            break
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "C++ OOP policy validation failed:" -ForegroundColor Red
    $errors | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "C++ OOP anti-pattern guard passed across $($sourceFiles.Count) production source file(s)"
exit 0
