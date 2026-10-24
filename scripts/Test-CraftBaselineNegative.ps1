# Offline adversarial acceptance of fail-closed Craft Git provenance.
# Tests synthetic JSON copies. Never modifies tracked source files.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CleanRepositoryPath,
    [Parameter(Mandatory=$true)][string]$DirtyRepositoryPath,
    [Parameter(Mandatory=$true)][string]$BaselinePath,
    [Parameter(Mandatory=$true)][string]$EvidenceDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$create = Join-Path $PSScriptRoot 'New-CraftBaseline.ps1'
$verify = Join-Path $PSScriptRoot 'Test-CraftBaseline.ps1'
$dir = [IO.Path]::GetFullPath($EvidenceDirectory)
if (Test-Path -LiteralPath $dir) { throw 'Refusing existing evidence directory.' }
[void](New-Item -ItemType Directory -Path $dir)
$passed = New-Object System.Collections.Generic.List[string]

function Expect-Rejection([string]$Case, [scriptblock]$Action) {
    $rejected = $false
    try { & $Action | Out-Null }
    catch { $rejected = $true }
    if (-not $rejected) { throw ('FAIL_OPEN:'+$Case) }
    [void]$passed.Add($Case)
    Write-Output ('NEGATIVE_'+$Case+'=PASS')
}
& $verify -RepositoryPath $CleanRepositoryPath -BaselinePath $BaselinePath | Out-Null
Write-Output 'POSITIVE_EXACT_BASELINE=PASS'

$mutations = @(
    @{ name='COMMIT_TAMPER'; change={param($a) $a.commit_sha = ('0'*40)} },
    @{ name='TREE_TAMPER'; change={param($a) $a.tree_sha = ('0'*40)} },
    @{ name='ORIGIN_TAMPER'; change={param($a) $a.origin_url = 'https://example.invalid/rogue.git'} },
    @{ name='PATH_TAMPER'; change={param($a) $a.repository_path = 'C:\NOT-THE-REPOSITORY'} },
    @{ name='BRANCH_TAMPER'; change={param($a) $a.branch = 'main'} },
    @{ name='CLEAN_FLAG_TAMPER'; change={param($a) $a.working_tree_clean = $false} },
    @{ name='RELEASE_APPROVAL_FORGERY'; change={param($a) $a.acceptance = 'PUBLIC_RELEASE_APPROVED'} },
    @{ name='SCHEMA_TAMPER'; change={param($a) $a.schema = 'unknown'} }
)
foreach ($case in $mutations) {
    $copy = Get-Content -LiteralPath $BaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
    & $case.change $copy
    $file = Join-Path $dir ($case.name + '.json')
    [IO.File]::WriteAllText($file, ($copy|ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $currentFile = $file
    Expect-Rejection $case.name { & $verify -RepositoryPath $CleanRepositoryPath -BaselinePath $currentFile }
}
Expect-Rejection 'OUTPUT_OVERWRITE' {
    & $create -RepositoryPath $CleanRepositoryPath -OutputDirectory (Split-Path $BaselinePath -Parent)
}
Expect-Rejection 'OUTPUT_INSIDE_GIT' {
    & $create -RepositoryPath $CleanRepositoryPath -OutputDirectory (Join-Path $CleanRepositoryPath 'do-not-create-baseline-inside')
}
Expect-Rejection 'DIRTY_WORKTREE' {
    & $create -RepositoryPath $DirtyRepositoryPath -OutputDirectory (Join-Path $dir 'do-not-create-dirty-baseline')
}
Expect-Rejection 'MISSING_ORIGIN' {
    & $create -RepositoryPath 'C:\Users\User\Documents\GitHub\craft-suite-installer' -OutputDirectory (Join-Path $dir 'do-not-create-without-origin')
}
Expect-Rejection 'LOCAL_ONLY_IMPLICIT_APPROVAL' {
    & $verify -RepositoryPath 'C:\Users\User\Documents\GitHub\craft-suite-installer' -BaselinePath 'C:\Users\User\Documents\CRAFT_FORK_METHOD_V1_ACCEPTANCE_20261024\installer-baseline\craft-baseline.json'
}
$result = [ordered]@{
    schema = 'craft.fork.method-baseline-test.v1'
    date_utc = (Get-Date).ToUniversalTime().ToString('o')
    positive_baseline_verified = $true
    negative_total = $passed.Count
    negative_passed = $passed.Count
    cases = @($passed.ToArray())
    source_repositories_mutated = $false
    legal_relicense_approval = 'NOT_ASSESSED'
    public_release = 'NO_GO'
}
$evidence = Join-Path $dir 'acceptance.json'
[IO.File]::WriteAllText($evidence, ($result|ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
Write-Output ('CRAFT_METHOD_ADVERSARIAL=' + $passed.Count + '/13_PASS')
Write-Output ('EVIDENCE=' + $evidence)
