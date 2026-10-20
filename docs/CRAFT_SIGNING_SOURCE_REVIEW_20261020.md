# Craft signing — source acceptance packet (2026-10-20)

## Determination

**All four current software integration candidates passed their complete required
exact-commit CI matrix: 18/18 checks.**

This authorizes **source review**, not qualified signature status, not a
SignPath Foundation grant, not a Windows Smart App Control acceptance, and not
a trusted public MSI release. **Do not conflate CI=PASS with RELEASE=PASS.**

The immutable, machine-readable evidence manifest is
[`CRAFT_SIGNING_SOURCE_REVIEW_EVIDENCE_20261020.json`](CRAFT_SIGNING_SOURCE_REVIEW_EVIDENCE_20261020.json).
The live read-only verifier is
[`Test-CraftRemoteIntegration.ps1`](../scripts/Test-CraftRemoteIntegration.ps1).

Local read-only proof from the owner-controlled Windows host:

- `C:\Users\User\Documents\CraftReleaseAudits\integration-20261020-verified-04.json`
- SHA-256 `2570e85a6310377c6449a641908db46a47785fb6586dab9617af577eac91dbda`
- `exact_commit_ci_ready=true`
- `trusted_release_ready=false`
- Four PR HEAD commits match the accepted source SHA.
- `Test-CraftRemoteIntegration.ps1 -RequireIntegrationReady` exit code 0.

## Source review queue

| Candidate | Exact reviewed HEAD | GitHub PR | Acceptance |
|---|---|---|---|
| PdfCraft | `4eb8aa42e3e3418bc156dcc9c6b69e04f8af9690` | https://github.com/Yanakiev432/pdfcraft/pull/15 | 7/7 |
| WordCraft | `d6811ab1d70b5b068964de74b490fea21e749add` | https://github.com/Yanakiev432/wordcraft/pull/5 | 5/5 |
| GridCraft | `33a1095642d71d6edcd11331bb0510c626dffed1` | https://github.com/Yanakiev432/gridcraft/pull/5 | 5/5 |
| Signing core | `080adc424c4b8f32d2f00e9fdad096e1be6ac85a` | https://github.com/Yanakiev432/craft-signing-core/pull/3 | 1/1 |

All four are `READY_FOR_REVIEW`, mergeable, and **not merged**. Each
human reviewer must examine source/provenance/branding, not merely a green
badge. Every change to a listed HEAD invalidates its old passing evidence
until the exact-SHA monitor is rerun.

## Technical acceptance

- Shared signing core: Windows + Linux Rust contract tests and a Windows
  synthetic DOCX/XLSX OPC/XMLDSig interoperability test with tamper rejection.
- PdfCraft: complete Windows/Linux testing, wasm32, dependency licensing,
  full manual RFC3161 one-CMS-signature in-flight PDF test, strict offline
  TSQ/TSR verification, brand gate, and privileged workflow pin.
- WordCraft: actual CLI synthetic OPC signing/verification and tamper
  rejection using the accepted core SHA, Windows ARM64 build and
  installation test, packaging and release negative controls.
- GridCraft: full quality CI and synthetic OPC/XLSX signing,
  branding/packaging and unsigned-release negative controls.
- All forks: protected upstream brand assets absent from source; privileged
  upstream reusable release workflow SHA-pinned; public `release` tasks
  deliberately blocked by a fail-closed preflight until production signing
  approval; vendor publisher certificate must match a preapproved X.509
  DER SHA-256 pin, not just any `Authenticode: Valid` signer.
- Current acceptance is **software, synthetic identities and test artifacts
  only**. It does not establish provenance of production hardware credentials.

## Mandatory qualified-release acceptance (all NO-GO)

1. Real B-Trust hardware token uses the legitimate provider PIN dialog,
   without key export or copying private user documents into CI; generate a
   disposable signed document whose exact CMS and PAdES ByteRange remain
   intact during the in-flight TSA exchange.
2. Obtain a permitted actual **qualified** RFC3161 token; bind exact
   SHA-256 imprint and nonce. Confirm the TSA's qualified status at
   generation time independently from authoritative EU Trusted Lists; a
   `timestamp.genTime` or QTSA claim in the token is not sufficient.
3. EU DSS must independently verify the final real PDF and distinguish
   PAdES-B, B-T, B-LT and B-LTA. Genuine OCSP/CRL/certificate validation
   material and, for B-LTA, archive timestamps are required.
4. Confirm Office interoperability with real B-Trust signing identity in
   Microsoft Word and Excel; the synthetic Windows signer test cannot
   substitute for this.
5. Obtain actual free SignPath Foundation approval (or another legitimate
   code signing solution) for these modified open-source forks; configure
   hosted trusted builds, manual approval and exact authorized publisher
   certificate fingerprint.
6. Produce immutable EXE/MSI artifacts from reviewed commits; independently
   validate their Authenticode signing identities, timestamps and SHA256.
   Install/uninstall on Windows SAC-enabled clean device without WDAC/SAC
   bypass. A valid **upstream** publisher signature is not our fork signature.
7. Only after all attestations are positive may the explicit release denial
   preflight be replaced by a reviewed, audited, signed-artifact acceptance
   job. Its replacement must run in the same release workflow **before**
   credentials are forwarded or assets are published.

## Providers and limits

- **BORICA**: engineering request SD1614999 was acknowledged, not granted
  API access. A manual nonprofit TSQ upload is separately documented.
  Development is not blocked.
- **ACCV**: free personal use, paid professional use. No claim that its
  unauthenticated endpoint can be used for mass/organizational signing.
  https://www.accv.es/servicios/empresas/sellado-de-tiempo/
- **APED**: HTTPS RFC3161 endpoint officially published without application
  authentication; that fact does not grant unrestricted third-party or
  automated service use. Confirm APED's terms before any production request.
  https://aped.gov.gr/allagi-archis-chronosimansis-chronosfragidas-tis-aped/

## Operational constraints

Do not restart the owner's Windows computer, disable SAC/WDAC, force-push
integration branches, persist or solicit the B-Trust PIN, imply actual QES
from synthetic CI, or merge a trusted public release prematurely. Preserve
all earlier source checkpoints and isolated review branches. Any source
merges are a separate human/code-review decision.
