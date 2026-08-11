Set-StrictMode -Version Latest
$script:RepoRoot = ""

function Set-AiCodeMapIoRoot([string]$Path) {
    $script:RepoRoot = (Resolve-Path $Path).Path
}

function Get-AiRepoRelativePath([string]$Path) {
    $rootPrefix = [IO.Path]::GetFullPath($script:RepoRoot).TrimEnd('\') + '\'
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside repository: $fullPath"
    }
    return $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-AiTextSha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Write-AiUtf8([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    if ($directory) { [IO.Directory]::CreateDirectory($directory) | Out-Null }
    [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}

function Write-AiStableJson([string]$Path, $Object) {
    Write-AiUtf8 $Path (($Object | ConvertTo-Json -Depth 16) + "`n")
}

function Get-AiDirectoryFingerprint([string]$Root) {
    if (-not (Test-Path $Root)) { return "missing" }
    $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $parts = @()
    Get-ChildItem $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($prefix.Length).TrimStart('\').Replace('\', '/')
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $parts += ("{0}:{1}" -f $relative, $hash)
    }
    return Get-AiTextSha256 ($parts -join "`n")
}

function Get-AiInputFingerprint {
    $files = @()
    foreach ($fixed in @("AGENTS.md", "CMakeLists.txt", "CMakePresets.json", ".agent\code-map\config.json")) {
        $path = Join-Path $script:RepoRoot $fixed
        if (Test-Path $path) { $files += Get-Item $path }
    }
    foreach ($rootName in @("engine", "sdk\include\AEngine", "tools", "tests", ".agent\skills")) {
        $root = Join-Path $script:RepoRoot $rootName
        if (-not (Test-Path $root)) { continue }
        $files += Get-ChildItem $root -Recurse -File | Where-Object {
            $_.Name -eq "CMakeLists.txt" -or $_.Name -eq "MODULE.json" -or
            $_.Extension -in @(".h", ".hpp", ".cpp", ".c", ".cc", ".cxx", ".cmake", ".ps1", ".psm1", ".md")
        }
    }
    $parts = @()
    foreach ($file in ($files | Sort-Object FullName -Unique)) {
        $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $parts += ("{0}:{1}" -f (Get-AiRepoRelativePath $file.FullName), $hash)
    }
    return Get-AiTextSha256 ($parts -join "`n")
}

function Sync-AiGeneratedDirectory([string]$Source, [string]$Destination) {
    [IO.Directory]::CreateDirectory($Destination) | Out-Null
    $sourceFiles = Get-ChildItem $Source -Recurse -File
    $sourceRelative = @($sourceFiles | ForEach-Object {
        $_.FullName.Substring($Source.TrimEnd('\').Length).TrimStart('\')
    })
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
    foreach ($existing in Get-ChildItem $Destination -Recurse -File) {
        $relative = $existing.FullName.Substring($Destination.TrimEnd('\').Length).TrimStart('\')
        if ($relative -notin $sourceRelative) { Remove-Item $existing.FullName -Force; $changed++ }
    }
    return $changed
}

function Compare-AiGeneratedDirectory([string]$Expected, [string]$Actual) {
    if (-not (Test-Path $Actual)) { return @("generated AI code map directory is missing") }
    $expectedFiles = @{}
    $actualFiles = @{}
    Get-ChildItem $Expected -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($Expected.TrimEnd('\').Length).TrimStart('\').Replace('\', '/')
        $expectedFiles[$relative] = (Get-FileHash $_.FullName).Hash
    }
    Get-ChildItem $Actual -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($Actual.TrimEnd('\').Length).TrimStart('\').Replace('\', '/')
        $actualFiles[$relative] = (Get-FileHash $_.FullName).Hash
    }
    $differences = @()
    foreach ($key in @($expectedFiles.Keys + $actualFiles.Keys | Sort-Object -Unique)) {
        if (-not $actualFiles.ContainsKey($key)) { $differences += "missing: $key"; continue }
        if (-not $expectedFiles.ContainsKey($key)) { $differences += "stale: $key"; continue }
        if ($expectedFiles[$key] -ne $actualFiles[$key]) { $differences += "changed: $key" }
    }
    return $differences
}

Export-ModuleMember -Function Set-AiCodeMapIoRoot, Get-AiRepoRelativePath, Get-AiInputFingerprint, Get-AiDirectoryFingerprint, Write-AiUtf8, Write-AiStableJson, Sync-AiGeneratedDirectory, Compare-AiGeneratedDirectory
