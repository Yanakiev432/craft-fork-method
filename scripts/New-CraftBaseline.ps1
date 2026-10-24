# Create a fail-closed, immutable-at-creation Git provenance checkpoint.
# Local evidence only: this is NOT legal approval, CI success or signing/QES.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RepositoryPath,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$AllowLocalOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git([string[]]$GitArgs) {
    $lines = @(& git @GitArgs 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ('Git operation failed; exit=' + $LASTEXITCODE)
    }
    return (($lines | Out-String).Trim())
}

$repo = (Resolve-Path -LiteralPath $RepositoryPath -ErrorAction Stop).ProviderPath
$repo = [IO.Path]::GetFullPath($repo).TrimEnd('\', '/')
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    throw 'Repository must be a directory.'
}
$top = (Invoke-Git -GitArgs @('-C', $repo, 'rev-parse', '--show-toplevel')).Replace('/', '\').TrimEnd('\')
if ($repo -ine $top) {
    throw 'Specify the Git repository top-level directory, not a subdirectory.'
}
$destination = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\', '/')
if ($destination -ieq $repo -or
    $destination.StartsWith(($repo + '\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Baseline output must be outside the repository (would dirty the source).'
}
if (Test-Path -LiteralPath $destination) {
    throw 'Baseline output already exists. Refusing overwrite or reuse.'
}
$parent = Split-Path -Path $destination -Parent
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    throw 'Parent evidence directory must exist; refusing implicit directory-tree creation.'
}
$status = Invoke-Git -GitArgs @('-C',$repo,'status','--porcelain=v1','--untracked-files=all')
if ($status) {
    throw 'Dirty worktree. Refusing baseline (including untracked files).'
}
$head = Invoke-Git -GitArgs @('-C',$repo,'rev-parse','HEAD')
$tree = Invoke-Git -GitArgs @('-C',$repo,'rev-parse','HEAD^{tree}')
if ($head -notmatch '^[a-f0-9]{40}$' -or $tree -notmatch '^[a-f0-9]{40}$') {
    throw 'Unverifiable Git commit/tree SHA.'
}
$remotes = @(& git -C $repo remote)
if ($LASTEXITCODE -ne 0) { throw 'Unable to list configured remotes.' }
$hasOrigin = @($remotes | Where-Object { $_ -ceq 'origin' }).Count -eq 1
if (-not $hasOrigin -and -not $AllowLocalOnly) {
    throw 'Origin URL is required. Use -AllowLocalOnly only for explicitly local-only evidence.'
}
$origin = ''
if ($hasOrigin) { $origin = Invoke-Git -GitArgs @('-C',$repo,'remote','get-url','origin') }
if (-not $origin -and $hasOrigin) { throw 'Empty origin URL is not acceptable.' }
# A remote with embedded HTTP credentials is unsafe to serialize into JSON.
if ($origin -match '^https?://[^/]+@') {
    throw 'Remote URL contains user-info; refuse to persist credentials.'
}
$branchName = (& git -C $repo symbolic-ref --quiet --short HEAD 2>$null)
if ($LASTEXITCODE -ne 0) { $branchName = '(detached)' }
$gitVersion = Invoke-Git -GitArgs @('--version')

# Prevent time-of-check/time-of-use drift immediately before writing.
if ((Invoke-Git -GitArgs @('-C',$repo,'rev-parse','HEAD')) -ne $head -or
    (Invoke-Git -GitArgs @('-C',$repo,'status','--porcelain=v1','--untracked-files=all'))) {
    throw 'Repository changed while baseline was captured.'
}
$record = [ordered]@{
    schema = 'craft.fork.baseline.v1'
    recorded_utc = (Get-Date).ToUniversalTime().ToString('o')
    repository_path = $repo
    origin_url = $origin
    remote_provenance = $(if ($hasOrigin) { 'URL_RECORDED_REMOTE_NOT_VERIFIED' } else { 'LOCAL_ONLY_NO_ORIGIN' })
    branch = (($branchName | Out-String).Trim())
    commit_sha = $head
    tree_sha = $tree
    working_tree_clean = $true
    git_version = $gitVersion
    acceptance = 'BASELINE_ONLY_NO_LICENSE_BUILD_TEST_OR_RELEASE_APPROVAL'
}
# New unique directory only. Preserve earlier evidence and never replace a file.
[void](New-Item -ItemType Directory -Path $destination -ErrorAction Stop)
$target = Join-Path $destination 'craft-baseline.json'
$temp = Join-Path $destination 'craft-baseline.json.tmp'
try {
    $json = $record | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($temp, $json + [Environment]::NewLine, ([Text.UTF8Encoding]::new($false)))
    Move-Item -LiteralPath $temp -Destination $target -ErrorAction Stop
    Write-Output $target
} catch {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    throw
}
