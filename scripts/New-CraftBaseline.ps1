# Creates a non-destructive provenance checkpoint for an existing Git checkout.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RepositoryPath,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath $RepositoryPath).Path
$top = (& git -C $repo rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0) { throw 'Not a Git repository' }
$status = (& git -C $repo status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect worktree' }
if ($status) { throw 'Dirty worktree: refusing baseline checkpoint' }
$sha = (& git -C $repo rev-parse HEAD).Trim()
$remote = (& git -C $repo remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0) { $remote = '' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$record = [ordered]@{
    schema_version = '1.0'
    recorded_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repository = $top.Trim()
    origin = ($remote | Out-String).Trim()
    commit_sha = $sha
    clean = $true
    git_version = ((& git --version) | Out-String).Trim()
}
$dest = Join-Path $OutputDirectory 'craft-baseline.json'
$record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $dest -Encoding utf8
Write-Output $dest
