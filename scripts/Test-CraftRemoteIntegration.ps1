#requires -Version 7.0
<# Read-only exact-SHA acceptance for the current Craft integration candidates.
Never infers eIDAS qualification, approved code signing, or release authorization
from successful synthetic CI. External QES/TSA/installer gates remain NO_GO. #>
[CmdletBinding()]
param(
    [string]$SnapshotFile,
    [switch]$RequireIntegrationReady,
    [string]$OutputFile
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$specs=@(
    @{ repo='Yanakiev432/pdfcraft'; pr=15; sha='4eb8aa42e3e3418bc156dcc9c6b69e04f8af9690'; required=@('CI','Windows ARM64','Packaging lint','Modified fork brand gate','Immutable privileged release workflow gate','Manual RFC3161 TSQ-TSR offline checks','Manual RFC3161 in-flight handoff (no network)') },
    @{ repo='Yanakiev432/wordcraft'; pr=5; sha='d6811ab1d70b5b068964de74b490fea21e749add'; required=@('OPC wordcraft signing acceptance','Packaging lint','Modified fork brand gate','Trusted Windows release gate (negative controls)','Windows ARM64') },
    @{ repo='Yanakiev432/gridcraft'; pr=5; sha='33a1095642d71d6edcd11331bb0510c626dffed1'; required=@('OPC gridcraft signing acceptance','Packaging lint','Modified fork brand gate','Trusted Windows release gate (negative controls)','CI') },
    @{ repo='Yanakiev432/craft-signing-core'; pr=3; sha='080adc424c4b8f32d2f00e9fdad096e1be6ac85a'; required=@('Shared signing core acceptance') }
)
$headers=@{ Accept='application/vnd.github+json'; 'User-Agent'='Craft-Exact-Commit-ReadOnly-Acceptance' }
$snapshot=$null
if($SnapshotFile){
    $full=[IO.Path]::GetFullPath($SnapshotFile)
    if(-not [IO.File]::Exists($full)){throw 'SnapshotFile does not exist'}
    $snapshot=Get-Content -LiteralPath $full -Raw | ConvertFrom-Json -Depth 50
}
$results=@()
foreach($spec in $specs){
    $repo=$spec.repo
    $actualHead=$null
    $runs=@()
    $errorCode=$null
    try{
        if($SnapshotFile){
            $fixture=@($snapshot.repositories | Where-Object { $_.repo -ceq $repo })
            if($fixture.Count -ne 1){throw 'Missing or duplicate snapshot repository'}
            $actualHead=[string]$fixture[0].head_sha
            $runs=@($fixture[0].workflow_runs)
        }else{
            $pr=Invoke-RestMethod -Uri ("https://api.github.com/repos/$repo/pulls/"+$spec.pr) -Headers $headers -Method Get -TimeoutSec 18
            $actualHead=[string]$pr.head.sha
            $uri="https://api.github.com/repos/$repo/actions/runs?head_sha="+$spec.sha+"&per_page=100"
            $raw=Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 18
            $runs=@($raw.workflow_runs)
        }
    }catch{
        # Fail closed. Never convert an API outage, missing PR or ambiguous fixture into PASS.
        $errorCode='FETCH_OR_SNAPSHOT_ERROR'
    }
    $headMatched=($null -ne $actualHead -and $actualHead -ceq $spec.sha)
    $checks=@()
    foreach($name in $spec.required){
        $candidates=@($runs | Where-Object { $_.name -ceq $name -and $_.head_sha -ceq $spec.sha } | Sort-Object -Property created_at -Descending)
        $run=if($candidates.Count -gt 0){$candidates[0]}else{$null}
        $ok=($headMatched -and $null -ne $run -and $run.status -ceq 'completed' -and $run.conclusion -ceq 'success' -and $null -eq $errorCode)
        $checks+=([pscustomobject]@{
            workflow=$name
            status=if($null -eq $run){'MISSING'}else{[string]$run.status}
            conclusion=if($null -eq $run){'MISSING'}else{[string]$run.conclusion}
            run_id=if($null -eq $run){$null}else{$run.id}
            passed=[bool]$ok
        })
    }
    $ready=$headMatched -and ($null -eq $errorCode) -and @($checks | Where-Object {-not $_.passed}).Count -eq 0
    $results+=([pscustomobject]@{
        repository=$repo; pr=$spec.pr; expected_sha=$spec.sha
        observed_pr_head_sha=$actualHead
        head_exact_match=[bool]$headMatched
        fetch_error=$errorCode
        required_checks=$checks
        integration_ci_ready=[bool]$ready
    })
}
$allReady=(@($results | Where-Object { -not $_.integration_ci_ready }).Count -eq 0)
$report=[ordered]@{
    schema='craft.signing.exact-head-integration.v1'
    generated_utc=[DateTime]::UtcNow.ToString('o')
    source=if($SnapshotFile){'OFFLINE_FIXTURE'}else{'LIVE_PUBLIC_GITHUB_API'}
    read_only=$true
    exact_commit_ci_ready=[bool]$allReady
    qualified_tsa_eu_trusted_list='NOT_VERIFIED'
    final_pdf_eu_dss_qes_bt_lt_lta='NOT_VERIFIED'
    real_btrust_token_word_excel='NOT_TESTED'
    our_windows_msi_code_signed='NO'
    signpath_foundation_approved='NO'
    trusted_release_ready=$false
    repositories=$results
}
$json=$report | ConvertTo-Json -Depth 25
if($OutputFile){
    $absolute=[IO.Path]::GetFullPath($OutputFile)
    $parent=[IO.Path]::GetDirectoryName($absolute)
    if(-not [IO.Directory]::Exists($parent)){throw 'Output parent does not exist'}
    $file=[IO.File]::Open($absolute,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$bytes=[Text.Encoding]::UTF8.GetBytes($json+[Environment]::NewLine);$file.Write($bytes,0,$bytes.Length);$file.Flush($true)}finally{$file.Dispose()}
}
$json
if($RequireIntegrationReady -and -not $allReady){exit 1}
