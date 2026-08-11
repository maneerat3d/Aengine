param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [ValidateSet("Update", "Check")]
    [string]$Mode = "Update"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path $RepoRoot).Path
$configPath = Join-Path $RepoRoot ".agent\code-map\config.json"
$currentRoot = Join-Path $RepoRoot ".agent\code-map\current"
$workRoot = Join-Path $RepoRoot "out\ai-code-map"
$generatedRoot = Join-Path $workRoot "generated"
$statePath = Join-Path $workRoot "state.json"

function Get-RepoRelativePath([string]$Path) {
    $rootPrefix = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside repository: $fullPath"
    }
    return $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-TextSha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Write-Utf8([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    if ($directory) {
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}

function Write-StableJson([string]$Path, $Object) {
    $json = $Object | ConvertTo-Json -Depth 16
    Write-Utf8 $Path ($json + "`n")
}

function Get-DirectoryFingerprint([string]$Root) {
    if (-not (Test-Path $Root)) {
        return "missing"
    }
    $parts = @()
    Get-ChildItem $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring([IO.Path]::GetFullPath($Root).TrimEnd('\').Length).TrimStart('\').Replace('\', '/')
        $parts += "$relative:$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())"
    }
    return Get-TextSha256 ($parts -join "`n")
}

function Get-InputFiles {
    $files = @()
    foreach ($fixed in @("AGENTS.md", "CMakeLists.txt", "CMakePresets.json", ".agent\code-map\config.json")) {
        $path = Join-Path $RepoRoot $fixed
        if (Test-Path $path) { $files += Get-Item $path }
    }
    foreach ($rootName in @("engine", "sdk\include\AEngine", "tools", "tests", ".agent\skills")) {
        $root = Join-Path $RepoRoot $rootName
        if (-not (Test-Path $root)) { continue }
        $files += Get-ChildItem $root -Recurse -File | Where-Object {
            $_.Name -eq "CMakeLists.txt" -or
            $_.Name -eq "MODULE.json" -or
            $_.Extension -in @(".h", ".hpp", ".cpp", ".c", ".cc", ".cxx", ".cmake", ".ps1", ".psm1", ".md")
        }
    }
    return $files | Sort-Object FullName -Unique
}

function Get-InputFingerprint {
    $parts = @()
    foreach ($file in Get-InputFiles) {
        $parts += "$(Get-RepoRelativePath $file.FullName):$((Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant())"
    }
    return Get-TextSha256 ($parts -join "`n")
}

function Get-CMakeModel {
    $cmakeFiles = Get-ChildItem $RepoRoot -Recurse -File -Filter "CMakeLists.txt" | Where-Object {
        $_.FullName -notmatch "[\\/]out[\\/]" -and $_.FullName -notmatch "[\\/]build[\\/]"
    }
    $allText = ($cmakeFiles | Sort-Object FullName | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
    $aliases = @{}
    foreach ($match in [regex]::Matches($allText, 'add_library\s*\(\s*([^\s\)]+)\s+ALIAS\s+([^\s\)]+)', 'IgnoreCase')) {
        $aliases[$match.Groups[1].Value] = $match.Groups[2].Value
    }
    return [ordered]@{ files = $cmakeFiles; text = $allText; aliases = $aliases }
}

function Get-TargetDependencies([string]$Target, $CMakeModel) {
    $pattern = 'target_link_libraries\s*\(\s*' + [regex]::Escape($Target) + '\s+(?<body>.*?)\)'
    $dependencies = @()
    foreach ($match in [regex]::Matches($CMakeModel.text, $pattern, 'IgnoreCase,Singleline')) {
        foreach ($token in ($match.Groups['body'].Value -split '\s+')) {
            $value = $token.Trim()
            if (-not $value -or $value -in @("PRIVATE", "PUBLIC", "INTERFACE")) { continue }
            if ($value.StartsWith('$<')) { continue }
            if ($CMakeModel.aliases.ContainsKey($value)) { $value = $CMakeModel.aliases[$value] }
            $dependencies += $value
        }
    }
    return @($dependencies | Sort-Object -Unique)
}

function Get-ObservedTests {
    $tests = @()
    $testRoot = Join-Path $RepoRoot "tests"
    if (-not (Test-Path $testRoot)) { return @() }
    $text = (Get-ChildItem $testRoot -Recurse -File | Where-Object { $_.Name -eq "CMakeLists.txt" } |
        Sort-Object FullName | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
    foreach ($match in [regex]::Matches($text, 'add_test\s*\(\s*NAME\s+([^\s\)]+)', 'IgnoreCase')) {
        $tests += $match.Groups[1].Value
    }
    return @($tests | Sort-Object -Unique)
}

function Expand-DeclaredPaths($Values, [string[]]$Extensions) {
    $result = @()
    foreach ($value in @($Values)) {
        $path = Join-Path $RepoRoot ([string]$value)
        if (-not (Test-Path $path)) { throw "Declared module path does not exist: $value" }
        if ((Get-Item $path).PSIsContainer) {
            $result += Get-ChildItem $path -Recurse -File | Where-Object { $_.Extension -in $Extensions }
        }
        else {
            $result += Get-Item $path
        }
    }
    return $result | Sort-Object FullName -Unique
}

function Get-PublicSymbols($Headers) {
    $symbols = @()
    foreach ($header in $Headers) {
        $text = Get-Content $header.FullName -Raw
        $relative = Get-RepoRelativePath $header.FullName
        foreach ($match in [regex]::Matches($text, '(?m)^\s*(?:class|struct)\s+(?:\[\[[^\]]+\]\]\s*)?([A-Za-z_]\w*)')) {
            $symbols += [ordered]@{ name = $match.Groups[1].Value; kind = "type"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\s*enum\s+class\s+([A-Za-z_]\w*)')) {
            $symbols += [ordered]@{ name = $match.Groups[1].Value; kind = "enum"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\s*using\s+([A-Za-z_]\w*)\s*=')) {
            $symbols += [ordered]@{ name = $match.Groups[1].Value; kind = "alias"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\s*(?:\[\[[^\]]+\]\]\s*)?[A-Za-z_][\w:<>,*&\s]+\s+([A-Za-z_]\w*)\s*\([^;{}]*\)\s*(?:noexcept)?\s*;')) {
            $symbols += [ordered]@{ name = $match.Groups[1].Value; kind = "function"; header = $relative }
        }
    }
    return @($symbols | Sort-Object name, kind, header -Unique)
}

function New-ModuleMap($ManifestFile, $ObservedTests, $CMakeModel) {
    $manifest = Get-Content $ManifestFile.FullName -Raw | ConvertFrom-Json
    $module = [string]$manifest.module
    if (-not $module) { throw "MODULE.json missing module name: $($ManifestFile.FullName)" }
    if (-not [regex]::IsMatch($CMakeModel.text, '(?i)(add_library|add_executable)\s*\(\s*' + [regex]::Escape($module) + '(\s|\))')) {
        throw "Declared module has no CMake target: $module"
    }

    $publicHeaders = Expand-DeclaredPaths $manifest.public_api @(".h", ".hpp")
    $implementationFiles = Expand-DeclaredPaths $manifest.implementation @(".h", ".hpp", ".cpp", ".c", ".cc", ".cxx")
    $actualDependencies = Get-TargetDependencies $module $CMakeModel
    $allowedDependencies = @($manifest.allowed_dependencies | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    foreach ($dependency in $actualDependencies) {
        if ($dependency -notin $allowedDependencies) {
            throw "Module $module links undeclared dependency '$dependency'. Update ownership intent or remove the dependency."
        }
    }
    foreach ($test in @($manifest.tests)) {
        if ([string]$test -notin $ObservedTests) { throw "Module $module declares missing test '$test'" }
    }
    foreach ($skill in @($manifest.skills)) {
        if (-not (Test-Path (Join-Path $RepoRoot ".agent\skills\$skill\SKILL.md"))) {
            throw "Module $module references missing skill '$skill'"
        }
    }

    $sourceFiles = @($implementationFiles | ForEach-Object {
        [ordered]@{ path = Get-RepoRelativePath $_.FullName; line_count = @(Get-Content $_.FullName).Count }
    })
    $headerPaths = @($publicHeaders | ForEach-Object { Get-RepoRelativePath $_.FullName })
    $symbols = Get-PublicSymbols $publicHeaders

    return [ordered]@{
        schema_version = 1
        module = $module
        kind = [string]$manifest.kind
        responsibility = [string]$manifest.responsibility
        manifest = Get-RepoRelativePath $ManifestFile.FullName
        declared = [ordered]@{
            allowed_dependencies = $allowedDependencies
            forbidden_dependencies = @($manifest.forbidden_dependencies)
            state_owners = @($manifest.state_owners)
            entry_points = @($manifest.entry_points)
            skills = @($manifest.skills)
            tests = @($manifest.tests)
        }
        observed = [ordered]@{
            dependencies = $actualDependencies
            public_headers = $headerPaths
            implementation_files = $sourceFiles
            public_symbols = $symbols
        }
    }
}

function Sync-GeneratedDirectory([string]$Source, [string]$Destination) {
    [IO.Directory]::CreateDirectory($Destination) | Out-Null
    $sourceFiles = Get-ChildItem $Source -Recurse -File
    $sourceRelative = @($sourceFiles | ForEach-Object { $_.FullName.Substring($Source.TrimEnd('\').Length).TrimStart('\') })
    $changed = 0
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($Source.TrimEnd('\').Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
        if (-not (Test-Path $target) -or (Get-FileHash $file.FullName).Hash -ne (Get-FileHash $target).Hash) {
            Copy-Item $file.FullName $target -Force
            $changed++
        }
    }
    if (Test-Path $Destination) {
        foreach ($existing in Get-ChildItem $Destination -Recurse -File) {
            $relative = $existing.FullName.Substring($Destination.TrimEnd('\').Length).TrimStart('\')
            if ($relative -notin $sourceRelative) { Remove-Item $existing.FullName -Force; $changed++ }
        }
    }
    return $changed
}

function Compare-GeneratedDirectory([string]$Expected, [string]$Actual) {
    if (-not (Test-Path $Actual)) { return @("generated AI code map directory is missing") }
    $differences = @()
    $expectedFiles = @{}
    Get-ChildItem $Expected -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($Expected.TrimEnd('\').Length).TrimStart('\').Replace('\', '/')
        $expectedFiles[$relative] = (Get-FileHash $_.FullName).Hash
    }
    $actualFiles = @{}
    Get-ChildItem $Actual -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($Actual.TrimEnd('\').Length).TrimStart('\').Replace('\', '/')
        $actualFiles[$relative] = (Get-FileHash $_.FullName).Hash
    }
    foreach ($key in @($expectedFiles.Keys + $actualFiles.Keys | Sort-Object -Unique)) {
        if (-not $actualFiles.ContainsKey($key)) { $differences += "missing: $key"; continue }
        if (-not $expectedFiles.ContainsKey($key)) { $differences += "stale: $key"; continue }
        if ($expectedFiles[$key] -ne $actualFiles[$key]) { $differences += "changed: $key" }
    }
    return $differences
}

if (-not (Test-Path $configPath)) { throw "AI code map config is missing: $configPath" }
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$inputHash = Get-InputFingerprint
if ($Mode -eq "Update" -and (Test-Path $statePath) -and (Test-Path (Join-Path $currentRoot "INDEX.json"))) {
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    $currentOutputHash = Get-DirectoryFingerprint $currentRoot
    if ($state.input_hash -eq $inputHash -and $state.output_hash -eq $currentOutputHash) {
        Write-Host "AI code map: up to date"
        exit 0
    }
}

if (Test-Path $generatedRoot) { Remove-Item $generatedRoot -Recurse -Force }
[IO.Directory]::CreateDirectory((Join-Path $generatedRoot "modules")) | Out-Null
$observedTests = Get-ObservedTests
$cmakeModel = Get-CMakeModel
$manifestFiles = @(Get-ChildItem (Join-Path $RepoRoot "engine"), (Join-Path $RepoRoot "tools") -Recurse -File -Filter "MODULE.json" | Sort-Object FullName)
$moduleMaps = @()
foreach ($manifestFile in $manifestFiles) {
    $map = New-ModuleMap $manifestFile $observedTests $cmakeModel
    $moduleMaps += $map
    Write-StableJson (Join-Path $generatedRoot "modules\$($map.module).json") $map
}

$indexModules = @($moduleMaps | Sort-Object module | ForEach-Object {
    [ordered]@{
        module = $_.module
        kind = $_.kind
        responsibility = $_.responsibility
        map = "modules/$($_.module).json"
        dependencies = $_.observed.dependencies
        tests = $_.declared.tests
        skills = $_.declared.skills
    }
})
$index = [ordered]@{
    schema_version = 1
    current_phase = [string]$config.current_phase
    build_entrypoint = [string]$config.canonical_build_entrypoint
    modules = $indexModules
}
Write-StableJson (Join-Path $generatedRoot "INDEX.json") $index

$context = @("# A-Engine AI Context", "", "> Generated by `build.bat`. Do not edit generated files directly.", "", "Current phase: **$($config.current_phase)**", "", "Build/test entrypoint: **$($config.canonical_build_entrypoint)**", "", "## Navigation rules")
foreach ($rule in @($config.rules)) { $context += "- $rule" }
$context += @("", "## Modules")
foreach ($map in $moduleMaps | Sort-Object module) {
    $deps = if (@($map.observed.dependencies).Count) { @($map.observed.dependencies) -join ", " } else { "none" }
    $context += @("", "### $($map.module)", "$($map.responsibility)", "", "- Map: `modules/$($map.module).json`", "- Dependencies: $deps", "- Tests: $(@($map.declared.tests) -join ', ')", "- Skills: $(@($map.declared.skills) -join ', ')", "- Entry points: $(@($map.declared.entry_points) -join ', ')")
}
Write-Utf8 (Join-Path $generatedRoot "AI_CONTEXT.md") (($context -join "`n") + "`n")

if ($Mode -eq "Check") {
    $differences = Compare-GeneratedDirectory $generatedRoot $currentRoot
    if ($differences.Count -gt 0) {
        Write-Host "AI code map drift detected:" -ForegroundColor Red
        $differences | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host "Run .\build.bat map and commit the generated map changes." -ForegroundColor Yellow
        exit 3
    }
    Write-Host "AI code map: committed snapshot matches source"
    exit 0
}

$changeCount = Sync-GeneratedDirectory $generatedRoot $currentRoot
$outputHash = Get-DirectoryFingerprint $currentRoot
[IO.Directory]::CreateDirectory($workRoot) | Out-Null
Write-StableJson $statePath ([ordered]@{ input_hash = $inputHash; output_hash = $outputHash })
Write-Host "AI code map: updated $changeCount file(s)"
exit 0
