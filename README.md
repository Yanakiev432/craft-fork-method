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

