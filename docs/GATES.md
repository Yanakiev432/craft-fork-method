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

## Executable local gate policy (24 October 2026)

Use `templates/edition-gates-v1.json` and `scripts/Test-CraftEditionGates.ps1` for fail-closed **evidence-integrity** validation. Only `PENDING`, `BLOCKED`, `FAIL` and `PASS` are accepted states. A `PASS` requires a **unique** relative evidence path within a configured evidence directory and a byte-equal SHA-256 fingerprint; paths outside that root, duplicate evidence, nonexistent files or reused hashes with the wrong file are rejected.

These G0–G7 machine checks certify **that a claimed evidence file is present and byte-identical**; they do **not** evaluate whether a license permits rebranding, whether a publisher approved a binary or whether a QES document meets eIDAS. Until qualified human review and actual provider acceptance, the only valid `release_status` value is `NO_GO`. Even 8/8 machine gate records give `READY_FOR_HUMAN_REVIEW_ONLY`, not a release.

Source baseline capture and subsequent independent re-verification are provided by `New-CraftBaseline.ps1` and `Test-CraftBaseline.ps1`. The `origin` URL is only locally configured metadata, **not authenticated GitHub evidence**. A local-only project requires an explicit `-AllowLocalOnly` argument; its provenance remains limited to local Git commit/tree integrity.

Automated failure-control acceptance is documented in `BASELINE_V1_ACCEPTANCE_20261024.md`.
