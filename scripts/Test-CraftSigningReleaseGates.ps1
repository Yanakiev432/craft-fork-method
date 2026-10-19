#requires -Version 7.0
<#
.SYNOPSIS
  Read-only cross-repository Craft signing release acceptance audit.
.DESCRIPTION
  Uses exact local git SHA and public GitHub Actions metadata. Never signs a
  document, touches USB PIN or certificate stores, merges, installs, or deploys.
  Optional -RunLocalTests executes only synthetic public test-key regression
  scripts. No third-party TSA is contacted.
#>
[CmdletBinding()]
param(
    [string]$RepositoriesRoot = (Join-Path $HOME 'Documents\GitHub'),
    [switch]$RunLocalTests,
    [string]$OutputFile,
    [switch]$RequireReleaseReady
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$gitCommand=Get-Command git -ErrorAction SilentlyContinue
if(-not $gitCommand){
    $candidate='C:\Program Files\Git\cmd\git.exe'
    if(-not (Test-Path -LiteralPath $candidate)){throw 'Git command not available'}
    $git=$candidate
}else{$git=$gitCommand.Source}
$definitions=@(
    [pscustomobject]@{name='pdfcraft';remote='Yanakiev432/pdfcraft';root='pdfcraft-lt-ocsp-20261019';workflow='RFC3161 provider and bridge (offline)'},
    [pscustomobject]@{name='wordcraft';remote='Yanakiev432/wordcraft';root='wordcraft';workflow='OPC wordcraft signing acceptance'},
    [pscustomobject]@{name='gridcraft';remote='Yanakiev432/gridcraft';root='gridcraft';workflow='OPC gridcraft signing acceptance'},
    [pscustomobject]@{name='craft-signing-core';remote='Yanakiev432/craft-signing-core';root='craft-signing-core';workflow=$null},
    [pscustomobject]@{name='craft-fork-method';remote='Yanakiev432/craft-fork-method';root='craft-fork-method';workflow=$null}
)
$repos=@()
foreach($d in $definitions){
    $path=Join-Path $RepositoriesRoot $d.root
    $entry=[ordered]@{
        name=$d.name;remote=$d.remote;workspace=$d.root
        local_present=(Test-Path -LiteralPath $path -PathType Container)
        sha=$null;branch=$null;clean=$false
        target_ci=$d.workflow
        ci_conclusion='NOT_CHECKED';ci_url=$null;ci_error=$null
        local_test='NOT_RUN'
    }
    if($entry.local_present){
        $sha=(& $git -C $path rev-parse HEAD)
        if($LASTEXITCODE -ne 0){throw "Cannot resolve HEAD: $($d.root)"}
        $branch=(& $git -C $path branch --show-current)
        if($LASTEXITCODE -ne 0){throw "Cannot resolve branch: $($d.root)"}
        $changes=@(& $git -C $path status --porcelain)
        if($LASTEXITCODE -ne 0){throw "Cannot read status: $($d.root)"}
        $entry.sha=([string]$sha).Trim()
        $entry.branch=([string]$branch).Trim()
        $entry.clean=($changes.Count -eq 0 -or ($changes.Count -eq 1 -and [string]::IsNullOrWhiteSpace($changes[0])))
        if($d.workflow){
            try{
                $uri='https://api.github.com/repos/'+$d.remote+'/actions/runs?head_sha='+$entry.sha+'&per_page=50'
                $data=Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 15 -Headers @{Accept='application/vnd.github+json';'User-Agent'='Craft-ReadOnly-Release-Gate'}
                $run=@($data.workflow_runs | Where-Object {$_.name -eq $d.workflow} | Sort-Object -Property created_at -Descending | Select-Object -First 1)
                if($run.Count -eq 1){
                    $entry.ci_conclusion=if($run[0].status -eq 'completed'){$run[0].conclusion}else{$run[0].status}
                    $entry.ci_url=$run[0].html_url
                }else{$entry.ci_conclusion='NO_MATCHING_CI_RUN'}
            }catch{
                $entry.ci_conclusion='UNKNOWN'
                $entry.ci_error=$_.Exception.GetType().Name
            }
        }
    }
    $repos+=([pscustomobject]$entry)
}
if($RunLocalTests) {
    $tests=@(
        @{repo='pdfcraft';directory='pdfcraft-lt-ocsp-20261019';script='tools/test_rfc3161_provider_probe.ps1';marker='OFFLINE_RFC3161_PROVIDER_POLICY_TESTS_PASS=6'},
        @{repo='craft-signing-core';directory='craft-signing-core';script='tools/test_opc_signature_windows.ps1';marker='OPC_SIGN_VERIFY_TAMPER=PASS'}
    )
    foreach($check in $tests){
        $path=Join-Path $RepositoriesRoot $check.directory
        $script=Join-Path $path $check.script
        $item=@($repos | Where-Object {$_.name -eq $check.repo})[0]
        if(Test-Path -LiteralPath $script -PathType Leaf){
            try{
                $lines=(& $script 2>&1 | Out-String)
                $item.local_test=if($lines.Contains($check.marker)){'PASS'}else{'FAIL'}
            }catch{$item.local_test='FAIL'}
        }else{$item.local_test='MISSING_TEST'}
    }
}
# These release gates cannot be inferred from compilation, a token-shaped DER,
# a local signed PDF, or a Windows software-key fixture.
$gates=@(
    [pscustomobject]@{gate='pdfcraft_rfc3161_synthetic_protocol';status=if(@($repos | Where-Object {$_.name -eq 'pdfcraft'})[0].local_test -eq 'PASS'){'PASS'}else{'NOT_CHECKED'};evidence='Local offline protocol policy regression, not a qualified time stamp'},
    [pscustomobject]@{gate='qualified_tsa_etrusted_list';status='NOT_CHECKED';evidence='Real token and authoritative EU Trusted Lists qualified-service chain required'},
    [pscustomobject]@{gate='independent_eu_dss_final_pades_b_t_lt_lta';status='NOT_CHECKED';evidence='Independent validation of final documents with complete issuer and revocation evidence required'},
    [pscustomobject]@{gate='word_grid_real_btrust_usb_office_interop';status='NOT_CHECKED';evidence='User-approved PIN via official provider UI plus Microsoft Word and Excel interoperability required'},
    [pscustomobject]@{gate='windows_trusted_signed_msi_release';status='BLOCKED_EXTERNAL';evidence='Authorized code signing publisher and SAC acceptance, not document QES'}
)
$releaseReady= @($gates | Where-Object {$_.status -ne 'PASS'}).Count -eq 0
$output=[ordered]@{
    schema='craft.signing.release-gates.v1'
    checked_utc=[DateTime]::UtcNow.ToString('o')
    operation='READ_ONLY'
    external_tsa_called=$false
    private_key_used=$false
    repos=$repos
    external_gates=$gates
    release_ready=[bool]$releaseReady
}
$json=$output | ConvertTo-Json -Depth 9
if($OutputFile){
    $dest=[IO.Path]::GetFullPath($OutputFile)
    $parent=[IO.Path]::GetDirectoryName($dest)
    if(-not [IO.Directory]::Exists($parent)){throw 'OutputFile parent directory missing'}
    $file=[IO.File]::Open($dest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{
        $bytes=[Text.Encoding]::UTF8.GetBytes($json+[Environment]::NewLine)
        $file.Write($bytes,0,$bytes.Length)
        $file.Flush($true)
    }finally{$file.Dispose()}
}
Write-Output $json
if($RequireReleaseReady -and -not $releaseReady){exit 1}
