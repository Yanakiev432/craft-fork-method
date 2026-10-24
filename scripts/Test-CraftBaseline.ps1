# Read-only gate: verify a saved Craft baseline against an actual Git checkout.
# This asserts source provenance only. All legal/build/release gates remain open.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RepositoryPath,
    [Parameter(Mandatory=$true)][string]$BaselinePath,
    [switch]$AllowLocalOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git([string[]]$GitArgs) {
    $output = @(& git @GitArgs 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'Git read failed during baseline verification.' }
    return (($output | Out-String).Trim())
}
$repo = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryPath).ProviderPath).TrimEnd('\','/')
$file = (Resolve-Path -LiteralPath $BaselinePath -ErrorAction Stop).ProviderPath
$data = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
if ($data.schema -cne 'craft.fork.baseline.v1') { throw 'Baseline schema mismatch.' }
if ($data.acceptance -cne 'BASELINE_ONLY_NO_LICENSE_BUILD_TEST_OR_RELEASE_APPROVAL') {
    throw 'Forged or changed baseline acceptance statement.'
}
if ($data.working_tree_clean -isnot [bool] -or -not $data.working_tree_clean) {
    throw 'Baseline claims must include a boolean clean=true.'
}
if ($data.commit_sha -cnotmatch '^[a-f0-9]{40}$' -or
    $data.tree_sha -cnotmatch '^[a-f0-9]{40}$') {
    throw 'Unverifiable Git commit/tree identity.'
}
if ($data.repository_path -ine $repo) { throw 'Checkpoint belongs to a different checkout.' }
$top = (Invoke-Git -GitArgs @('-C',$repo,'rev-parse','--show-toplevel')).Replace('/','\').TrimEnd('\')
if ($repo -ine $top) { throw 'Repository path is not top level.' }
if ((Invoke-Git -GitArgs @('-C',$repo,'status','--porcelain=v1','--untracked-files=all'))) {
    throw 'Worktree dirty after provenance checkpoint.'
}
$head = Invoke-Git -GitArgs @('-C',$repo,'rev-parse','HEAD')
$tree = Invoke-Git -GitArgs @('-C',$repo,'rev-parse','HEAD^{tree}')
$remotes = @(& git -C $repo remote)
if ($LASTEXITCODE -ne 0) { throw 'Remote inventory check failed.' }
$hasOrigin = @($remotes | Where-Object { $_ -ceq 'origin' }).Count -eq 1
if ($hasOrigin) {
    $origin = Invoke-Git -GitArgs @('-C',$repo,'remote','get-url','origin')
    if ($origin -cne $data.origin_url) { throw 'Recorded origin changed.' }
    if ($data.PSObject.Properties.Name -contains 'remote_provenance' -and
        $data.remote_provenance -cne 'URL_RECORDED_REMOTE_NOT_VERIFIED') {
        throw 'Remote-provenance mode changed.'
    }
} else {
    if (-not $AllowLocalOnly -or $data.origin_url -ne '' -or
        $data.remote_provenance -cne 'LOCAL_ONLY_NO_ORIGIN') {
        throw 'Local-only baseline requires explicit opt-in and matching provenance.'
    }
}
if ($head -cne $data.commit_sha -or $tree -cne $data.tree_sha) {
    throw 'Repository commit/tree does not match recorded baseline.'
}
$branch = (& git -C $repo symbolic-ref --quiet --short HEAD 2>$null)
if ($LASTEXITCODE -ne 0) { $branch = '(detached)' }
if ($data.branch -cne (($branch | Out-String).Trim())) {
    throw 'Branch changed after baseline.'
}
Write-Output ('CRAFT_BASELINE_PROVENANCE=PASS;HEAD='+$head+';TREE='+$tree+
    ';LICENSE=NOT_EVALUATED;BUILD=NOT_EVALUATED;RELEASE=NO_GO')
