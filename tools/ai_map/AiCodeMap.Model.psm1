Set-StrictMode -Version Latest
$script:RepoRoot = ""

function Set-AiCodeMapModelRoot([string]$Path) {
    $script:RepoRoot = (Resolve-Path $Path).Path
}

function Get-AiCMakeModel {
    $cmakeFiles = Get-ChildItem $script:RepoRoot -Recurse -File -Filter "CMakeLists.txt" | Where-Object {
        $_.FullName -notmatch "[\\/]out[\\/]" -and $_.FullName -notmatch "[\\/]build[\\/]"
    }
    $allText = ($cmakeFiles | Sort-Object FullName | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
    $aliases = @{}
    foreach ($match in [regex]::Matches($allText, 'add_library\s*\(\s*([^\s\)]+)\s+ALIAS\s+([^\s\)]+)', 'IgnoreCase')) {
        $aliases[$match.Groups[1].Value] = $match.Groups[2].Value
    }
    return [ordered]@{ files = $cmakeFiles; text = $allText; aliases = $aliases }
}

function Get-AiProductionTargets {
    $texts = @()
    foreach ($rootName in @("engine", "tools")) {
        $root = Join-Path $script:RepoRoot $rootName
        if (-not (Test-Path $root)) { continue }
        $texts += Get-ChildItem $root -Recurse -File -Filter "CMakeLists.txt" | Sort-Object FullName | ForEach-Object {
            Get-Content $_.FullName -Raw
        }
    }
    $targets = @()
    foreach ($match in [regex]::Matches(($texts -join "`n"), '(?i)add_(?:library|executable)\s*\(\s*(aengine_[^\s\)]+)')) {
        $targets += $match.Groups[1].Value
    }
    return @($targets | Sort-Object -Unique)
}

function Get-AiTargetDependencies([string]$Target, $CMakeModel) {
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

function Get-AiObservedTests {
    $testRoot = Join-Path $script:RepoRoot "tests"
    if (-not (Test-Path $testRoot)) { return @() }
    $text = (Get-ChildItem $testRoot -Recurse -File | Where-Object { $_.Name -eq "CMakeLists.txt" } |
        Sort-Object FullName | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
    $tests = @()
    foreach ($match in [regex]::Matches($text, 'add_test\s*\(\s*NAME\s+([^\s\)]+)', 'IgnoreCase')) {
        $tests += $match.Groups[1].Value
    }
    return @($tests | Sort-Object -Unique)
}

function Expand-AiDeclaredPaths($Values, [string[]]$Extensions) {
    $result = @()
    foreach ($value in @($Values)) {
        $path = Join-Path $script:RepoRoot ([string]$value)
        if (-not (Test-Path $path)) { throw "Declared module path does not exist: $value" }
        if ((Get-Item $path).PSIsContainer) {
            $result += Get-ChildItem $path -Recurse -File | Where-Object { $_.Extension -in $Extensions }
        }
        else { $result += Get-Item $path }
    }
    return $result | Sort-Object FullName -Unique
}

function Get-AiPublicSymbols($Headers) {
    $symbols = @()
    foreach ($header in $Headers) {
        $text = Get-Content $header.FullName -Raw
        $relative = Get-AiRepoRelativePath $header.FullName
        foreach ($match in [regex]::Matches($text, '(?m)^\s*(?:class|struct)\s+(?:\[\[[^\]]+\]\]\s*)?([A-Za-z_]\w*)')) {
            $symbols += [pscustomobject][ordered]@{ name = $match.Groups[1].Value; kind = "type"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\s*enum\s+class\s+([A-Za-z_]\w*)')) {
            $symbols += [pscustomobject][ordered]@{ name = $match.Groups[1].Value; kind = "enum"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\s*using\s+([A-Za-z_]\w*)\s*=')) {
            $symbols += [pscustomobject][ordered]@{ name = $match.Groups[1].Value; kind = "alias"; header = $relative }
        }
        foreach ($match in [regex]::Matches($text, '(?m)^\[\[[^\]]+\]\]\s+[^;\r\n]+?\s+([A-Za-z_]\w*)\s*\([^;{]*\)\s*(?:noexcept)?\s*;')) {
            $symbols += [pscustomobject][ordered]@{ name = $match.Groups[1].Value; kind = "function"; header = $relative }
        }
    }
    return @($symbols | Sort-Object name, kind, header -Unique)
}

function New-AiModuleMap($ManifestFile, $ObservedTests, $CMakeModel) {
    $manifest = Get-Content $ManifestFile.FullName -Raw | ConvertFrom-Json
    $module = [string]$manifest.module
    $kind = [string]$manifest.kind
    $responsibility = [string]$manifest.responsibility
    if (-not $module -or -not $kind -or -not $responsibility) {
        throw "MODULE.json requires module, kind, and responsibility: $($ManifestFile.FullName)"
    }
    $targetPattern = '(?i)(add_library|add_executable)\s*\(\s*' + [regex]::Escape($module) + '(\s|\))'
    if (-not [regex]::IsMatch($CMakeModel.text, $targetPattern)) {
        throw "Declared module has no CMake target: $module"
    }

    $publicHeaders = Expand-AiDeclaredPaths $manifest.public_api @(".h", ".hpp")
    $implementationFiles = Expand-AiDeclaredPaths $manifest.implementation @(".h", ".hpp", ".cpp", ".c", ".cc", ".cxx")
    $actualDependencies = @(Get-AiTargetDependencies $module $CMakeModel)
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
        if (-not (Test-Path (Join-Path $script:RepoRoot ".agent\skills\$skill\SKILL.md"))) {
            throw "Module $module references missing skill '$skill'"
        }
    }

    return [ordered]@{
        schema_version = 1
        module = $module
        kind = $kind
        responsibility = $responsibility
        manifest = Get-AiRepoRelativePath $ManifestFile.FullName
        declared = [ordered]@{
            allowed_dependencies = @($allowedDependencies)
            forbidden_dependencies = @($manifest.forbidden_dependencies)
            state_owners = @($manifest.state_owners)
            entry_points = @($manifest.entry_points)
            skills = @($manifest.skills)
            tests = @($manifest.tests)
        }
        observed = [ordered]@{
            dependencies = @($actualDependencies)
            public_headers = @($publicHeaders | ForEach-Object { Get-AiRepoRelativePath $_.FullName })
            implementation_files = @($implementationFiles | ForEach-Object { Get-AiRepoRelativePath $_.FullName })
            public_symbols = @(Get-AiPublicSymbols $publicHeaders)
        }
    }
}

function Get-AiModuleMaps {
    $observedTests = @(Get-AiObservedTests)
    $cmakeModel = Get-AiCMakeModel
    $roots = @()
    foreach ($name in @("engine", "tools")) {
        $path = Join-Path $script:RepoRoot $name
        if (Test-Path $path) { $roots += $path }
    }
    $maps = @()
    foreach ($manifestFile in @(Get-ChildItem $roots -Recurse -File -Filter "MODULE.json" | Sort-Object FullName)) {
        $maps += New-AiModuleMap $manifestFile $observedTests $cmakeModel
    }
    $mappedTargets = @($maps | ForEach-Object { $_.module })
    foreach ($target in Get-AiProductionTargets) {
        if ($target -notin $mappedTargets) { throw "Production target is missing MODULE.json: $target" }
    }
    return @($maps | Sort-Object module)
}

Export-ModuleMember -Function Set-AiCodeMapModelRoot, Get-AiModuleMaps
