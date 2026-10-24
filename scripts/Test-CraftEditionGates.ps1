# Validates Craft edition G0-G7 evidence records without granting release.
# A PASS gate requires an existing evidence file, a pinned SHA-256 and a safe
# path rooted inside EvidenceRoot. This is NOT legal or qualified-signing review.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$file = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).ProviderPath
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $EvidenceRoot -ErrorAction Stop).ProviderPath).TrimEnd('\','/')
$data = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
if ($data.schema -cne 'craft.fork.gates.v1') { throw 'Invalid edition gate schema.' }
if ($data.release_status -cne 'NO_GO') { throw 'Cannot self-approve public release.' }
if ($data.edition -cnotmatch '^[a-z0-9][a-z0-9_.-]{2,100}$') {
    throw 'Invalid edition identifier.'
}
$expected = @('G0','G1','G2','G3','G4','G5','G6','G7')
$gates = @($data.gates)
if ($gates.Count -ne 8) { throw 'Exactly eight ordered gates required.' }
$passed = 0
$used = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
for ($i=0; $i -lt 8; $i++) {
    $gate = $gates[$i]
    if ($gate.id -cne $expected[$i]) { throw 'Gate identity/order changed.' }
    if ($gate.status -cnotin @('PASS','PENDING','BLOCKED','FAIL')) {
        throw ('Invalid gate status: '+$gate.id)
    }
    if ($gate.status -ceq 'PASS') {
        $relative = [string]$gate.evidence_path
        $sha = [string]$gate.evidence_sha256
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or
            $relative.Contains(':') -or $relative -match '[\x00-\x1f]' -or
            $sha -cnotmatch '^[0-9A-Fa-f]{64}$') {
            throw ('Invalid PASS evidence path/hash at '+$gate.id)
        }
        $resolved = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $resolved.StartsWith(($root+'\'), [StringComparison]::OrdinalIgnoreCase)) {
            throw ('Evidence path escapes root at '+$gate.id)
        }
        if (-not $used.Add($resolved)) {
            throw ('A single evidence file cannot satisfy multiple different gates.')
        }
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw ('Missing evidence file for '+$gate.id)
        }
        $actual = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
        if ($sha -ine $actual) { throw ('Evidence hash mismatch at '+$gate.id) }
        $passed++
    } else {
        if ($gate.evidence_path -or $gate.evidence_sha256) {
            throw ('Non-PASS gate must not carry approved evidence at '+$gate.id)
        }
    }
}
$approvals = $data.external_approvals
if ($approvals.licensing_and_trademarks -cne 'NOT_APPROVED' -or
    $approvals.public_publisher_identity -cne 'NOT_APPROVED' -or
    $approvals.hardware_or_qualified_signature -cne 'NOT_EVALUATED' -or
    $approvals.deployment -cne 'NOT_APPROVED') {
    throw 'External authorizations cannot be claimed by this local gate.'
}
$review = if ($passed -eq 8) { 'READY_FOR_HUMAN_REVIEW_ONLY' } else { 'INCOMPLETE' }
Write-Output ('CRAFT_EDITION_GATE_STRUCTURE=PASS;GATES_VERIFIED='+$passed+
    '/8;REVIEW='+$review+';PUBLIC_RELEASE=NO_GO')
