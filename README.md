# Craft Fork Method

A reproducible, auditable workflow for creating and maintaining **our own edition** of upstream software.

This is not a universal automated source-code transformation. It is a gated engineering process applicable to desktop, web, server, library and document applications.

## Workflow

1. **Identify upstream**: URL, owner, exact commit SHA, license, dependencies and release provenance.
2. **Legal gate**: check redistribution/modification rights, copyright notices, trademarks, patent obligations and third-party components. Stop if rights are unclear.
3. **Baseline**: create clean upstream mirror/fork and pin SHA; record build environment and reproduce unmodified tests.
4. **Requirements**: write Craft-specific deltas, acceptance criteria and explicitly excluded behavior.
5. **Architecture**: isolate reusable components from application-specific adapters; avoid upstream file edits when extension points suffice.
6. **Implementation**: small isolated changes, feature branch, tests and attribution. Never embed credentials or private user data.
7. **Verification**: unit, integration, security, platform and regression tests; compare with baseline; preserve signed/authoritative source files.
8. **Packaging**: reproducible local build, SBOM/dependency record, binary hashes, backup, smoke test and rollback.
9. **Upstream sync**: track upstream SHA, review upstream changes and conflicts, re-run the full gate before merge.
10. **Release**: tag only after acceptance; publish source and required notices. No implicit CI/Actions requirement.

See [plugin orchestration and tool responsibilities](docs/PLUGIN_ORCHESTRATION.md), [detailed gates](docs/GATES.md), [manifest schema](templates/edition-manifest.json) and [PowerShell baseline helper](scripts/New-CraftBaseline.ps1).

## Rules

- Never remove license/attribution notices.
- Never claim cryptographic validity by hiding a warning.
- Never run hardware signing, credential operations or destructive deployments without explicit authorization.
- GitHub Actions optional: use local PowerShell gates on constrained plans.
- Keep checkpoints with commands, outputs, hashes and rollback path.

## License

MIT (original workflow documentation and helper scripts). Third-party code keeps its original license.

## Local v1 provenance and evidence gates (24 October 2026)

- `scripts/New-CraftBaseline.ps1`: create one no-overwrite checkpoint **outside** a clean repository; pin commit SHA, tree SHA, branch and locally configured origin. A local-only project must explicitly use `-AllowLocalOnly`, and the record states that remote provenance is unavailable.
- `scripts/Test-CraftBaseline.ps1`: independently verify the same repository, SHA, tree, origin and clean state; does not mutate the checkout.
- `scripts/Test-CraftEditionGates.ps1`: check ordered G0–G7 statuses. A `PASS` requires a distinct file under the allowed evidence root, with matching SHA-256; the machine-readable release decision always remains **NO_GO**.
- `templates/edition-gates-v1.json`: fail-closed example with all eight gates initially pending.
- `scripts/Test-CraftBaselineNegative.ps1` and `scripts/Test-CraftEditionGatesNegative.ps1`: adversarial offline regression suites.

**Verified acceptance:** three existing repositories (Signing Core, WordCraft and local-only Craft Suite Installer) and **25/25 negative cases PASS** (13 provenance + 12 G0–G7 evidence checks). Actual legal rights, upstream build reproduction, external signature qualification and public code-signing approval are *not* determined by these local scripts. See [baseline acceptance](docs/BASELINE_V1_ACCEPTANCE_20261024.md).

No dependency on paid Actions, hosted LLMs, remote desktop accounts, private keys or certificate PINs.
