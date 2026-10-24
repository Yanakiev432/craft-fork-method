# Fail-closed review-gate test: genuine pinned evidence + synthetic mutations.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$EvidenceRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root = (Resolve-Path -LiteralPath $EvidenceRoot).ProviderPath
$testDir = Join-Path $root 'edition-gates-v1-tests'
if(Test-Path -LiteralPath $testDir){throw 'Refusing to overwrite previous gate test evidence.'}
[void](New-Item -ItemType Directory -Path $testDir)
$validator=Join-Path $PSScriptRoot 'Test-CraftEditionGates.ps1'
$template=Join-Path (Split-Path $PSScriptRoot -Parent) 'templates\edition-gates-v1.json'
& $validator -ManifestPath $template -EvidenceRoot $root | Out-Null
$baseline=Join-Path $root 'signing-core-baseline\craft-baseline.json'
$baselineSha=(Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash
$positive=(Get-Content -LiteralPath $template -Raw |ConvertFrom-Json)
$positive.gates[1].status='PASS'
$positive.gates[1].evidence_path='signing-core-baseline\craft-baseline.json'
$positive.gates[1].evidence_sha256=$baselineSha
$valid=Join-Path $testDir 'valid-one-reviewed-gate.json'
[IO.File]::WriteAllText($valid,($positive|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
& $validator -ManifestPath $valid -EvidenceRoot $root | Out-Null
$passed=New-Object System.Collections.Generic.List[string]
$cases=@(
    @{n='FORGED_RELEASE';do={param($v) $v.release_status='GO'}},
    @{n='FORGED_HUMAN_APPROVAL';do={param($v) $v.external_approvals.licensing_and_trademarks='APPROVED'}},
    @{n='WRONG_EVIDENCE_HASH';do={param($v) $v.gates[1].evidence_sha256='0'*64}},
    @{n='TRAVERSAL_PATH';do={param($v) $v.gates[1].evidence_path='..\..\outside.json'}},
    @{n='ABSOLUTE_PATH';do={param($v) $v.gates[1].evidence_path='C:\outside.json'}},
    @{n='MISSING_FILE';do={param($v) $v.gates[1].evidence_path='nonexistent.json'}},
    @{n='GATE_REORDER';do={param($v) $v.gates[1].id='G5'}},
    @{n='GATE_COUNT';do={param($v) $v.gates=@($v.gates|Select-Object -First 7)}},
    @{n='UNAPPROVED_GATE_EVIDENCE';do={param($v) $v.gates[2].evidence_path='signing-core-baseline\craft-baseline.json'}},
    @{n='DUPLICATE_EVIDENCE';do={param($v) $v.gates[2].status='PASS';$v.gates[2].evidence_path=$v.gates[1].evidence_path;$v.gates[2].evidence_sha256=$v.gates[1].evidence_sha256}},
    @{n='FAKE_ACCEPTED_GATE';do={param($v) $v.gates[2].status='PASS'}},
    @{n='SCHEMA_TAMPER';do={param($v) $v.schema='unexpected'}}
)
foreach($case in $cases){
    $clone=Get-Content -LiteralPath $valid -Raw|ConvertFrom-Json
    & $case.do $clone
    $filename=Join-Path $testDir ($case.n+'.json')
    [IO.File]::WriteAllText($filename,($clone|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
    $fail=$false
    try { & $validator -ManifestPath $filename -EvidenceRoot $root|Out-Null }
    catch {$fail=$true}
    if(-not $fail){throw ('FAIL_OPEN:'+ $case.n)}
    [void]$passed.Add($case.n)
    Write-Output ('NEGATIVE_'+$case.n+'=PASS')
}
$report=[ordered]@{
 schema='craft.fork.method-edition-gates-acceptance.v1'
 status='PASS'
 pinned_real_evidence_gate='G1'
 positive_cases=2
 negative_cases=$passed.Count
 negative_passed=$passed.Count
 denial_cases=@($passed.ToArray())
 public_release='NO_GO'
 machine_readable_gates_are_not_independent_human_approval=$true
}
$file=Join-Path $testDir 'acceptance.json'
[IO.File]::WriteAllText($file,($report|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output ('EDITION_GATE_ADVERSARIAL='+$passed.Count+'/12_PASS')
Write-Output ('ACCEPTANCE='+$file)
