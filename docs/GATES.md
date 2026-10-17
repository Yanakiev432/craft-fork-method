# Acceptance gates

| Gate | Required evidence | Failure behavior |
| --- | --- | --- |
| G0 License | SPDX, notices, redistribution review | STOP |
| G1 Provenance | Upstream URL, immutable SHA, clean baseline | STOP |
| G2 Reproduction | Tool versions, original build and test logs | STOP |
| G3 Delta | Scope, architecture, risk, feature branch | STOP |
| G4 Code | Review, tests, secrets scan, formatting | STOP |
| G5 Functional | Realistic tests, regression comparison, user acceptance | STOP |
| G6 Release | Binary SHA-256, backup, rollback, no unintended mutation | STOP |
| G7 Upstream | Pinned sync, conflicts resolved, gates rerun | STOP |

## Craft implementation example: PdfCraft / B-Trust (2026-10-17)

- Upstream: https://github.com/storytold/pdfcraft
- Local edition workspace: `pdfcraft-signatures`.
- Delta: Windows trusted-root store integration into PdfCraft signature validation.
- Validation: pre-fix PDF status `unknown`, trusted Windows B-Trust root yields `valid`; installed GUI subsequently reports `Signed and all signatures are valid.`
- Preserve the signed PDF and signing hardware key.
- Limitation: trust-chain success is not by itself a QES/eIDAS or revocation/LTV certification.
- Never copy personal certificates or hardware PINs into a repository.

## Synchronization policy

Keep `upstream` remote separate from `origin`. Review changes before merge. Do not force push `main`, automatically merge upstream or deploy before the local acceptance gate.
