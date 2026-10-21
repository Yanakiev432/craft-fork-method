#requires -Version 7.0
<#
.SYNOPSIS
  Read-only local prerequisites for Craft physical B-Trust / Microsoft Office acceptance.
.DESCRIPTION
  Does not open private keys, launch Office, invoke CNG signing, call network,
  solicit a PIN, change Windows services, or claim eIDAS qualification.
  A certificate reporting HasPrivateKey is NOT proof of token availability.
#>
[CmdletBinding()]
param(
  [string] $OutputPath,
  [string] $FixturePath,
  [switch] $RequireInteractivePrerequisites
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($FixturePath) {
  $fixture = Get-Content -LiteralPath $FixturePath -Raw | ConvertFrom-Json -Depth 10
  $counts = [pscustomobject]@{
    Certificates = [int]$fixture.certificates_total
    BtrustCertificates = [int]$fixture.btrust_certificates
    BtrustWithPrivateKeyReference = [int]$fixture.btrust_key_reference_count
    WordRegistered = [bool]$fixture.word_com_registered
    ExcelRegistered = [bool]$fixture.excel_com_registered
    SmartCardServiceStatus = 'NOT_TESTED_FIXTURE'
  }
  if ($counts.Certificates -lt 0 -or $counts.BtrustCertificates -lt 0 -or
      $counts.BtrustWithPrivateKeyReference -lt 0 -or
      $counts.BtrustWithPrivateKeyReference -gt $counts.BtrustCertificates -or
      $counts.BtrustCertificates -gt $counts.Certificates) {
    throw 'Invalid fixture counters'
  }
  $source = 'OFFLINE_TEST_FIXTURE'
} else {
  if (-not $IsWindows) { throw 'Live certificate preflight requires Windows' }
  $certificates = @(Get-ChildItem -Path 'Cert:\CurrentUser\My' -ErrorAction Stop)
  $btrust = @($certificates | Where-Object { $_.Issuer -match '(?i)borica|b-trust|btrust' })
  # HasPrivateKey is Windows certificate metadata only. NO GetRSAPrivateKey,
  # NCryptOpenKey, CryptAcquireCertificatePrivateKey, or PIN prompt.
  $keyReferences = @($btrust | Where-Object { $_.HasPrivateKey })
  $word = [type]::GetTypeFromProgID('Word.Application', $false)
  $excel = [type]::GetTypeFromProgID('Excel.Application', $false)
  $smartCardService = Get-Service -Name 'SCardSvr' -ErrorAction SilentlyContinue
  $counts = [pscustomobject]@{
    Certificates = $certificates.Count
    BtrustCertificates = $btrust.Count
    BtrustWithPrivateKeyReference = $keyReferences.Count
    WordRegistered = ($null -ne $word)
    ExcelRegistered = ($null -ne $excel)
    SmartCardServiceStatus = if ($null -eq $smartCardService) { 'NOT_FOUND' } else { [string]$smartCardService.Status }
  }
  $source = 'WINDOWS_CURRENT_USER_METADATA'
}

$possible = ($counts.BtrustWithPrivateKeyReference -gt 0 -and
             $counts.WordRegistered -and $counts.ExcelRegistered)
$report = [ordered]@{
  schema = 'craft.operator.preflight.v1'
  utc = [DateTime]::UtcNow.ToString('o')
  source = $source
  windows_user_certificate_store = 'CurrentUser/My'
  counts = [ordered]@{
    certificates_total = [int]$counts.Certificates
    btrust_issuer_certificates = [int]$counts.BtrustCertificates
    btrust_key_references = [int]$counts.BtrustWithPrivateKeyReference
  }
  office_com_registration = [ordered]@{
    word_registered = [bool]$counts.WordRegistered
    excel_registered = [bool]$counts.ExcelRegistered
  }
  smartcard_service_status = $counts.SmartCardServiceStatus
  possible_operator_interop_setup = [bool]$possible
  # These require a human-authorized, interactive production acceptance.
  private_key_opened = $false
  pin_requested = $false
  word_or_excel_launched = $false
  actual_btrust_token_signature = 'NOT_TESTED'
  office_real_document_sign_verify = 'NOT_TESTED'
  qualified_eidas_status = 'NOT_VERIFIED'
  publisher_signing_approval = 'NOT_VERIFIED'
  public_release_ready = $false
}
$json = $report | ConvertTo-Json -Depth 12
if ($OutputPath) {
  $absolute = [IO.Path]::GetFullPath($OutputPath)
  if (-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($absolute))) {
    throw 'Output parent directory does not exist'
  }
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json + [Environment]::NewLine)
  $stream = [IO.File]::Open($absolute, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
  try {
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush($true)
  } finally {
    $stream.Dispose()
  }
}
$json
if ($RequireInteractivePrerequisites -and -not $possible) { exit 1 }
