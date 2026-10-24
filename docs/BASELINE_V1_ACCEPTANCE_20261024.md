# Craft Fork Method v1 — Local provenance acceptance

Date: 2026-10-24. Status: **source provenance and guardrails PASS; public release NO-GO**.

## Scope

- `scripts/New-CraftBaseline.ps1` writes a new, uniquely located, non-overwriting baseline outside a clean Git checkout.
- `scripts/Test-CraftBaseline.ps1` independently rechecks the Git commit SHA, tree SHA, branch, configured origin and clean working tree.
- `scripts/Test-CraftBaselineNegative.ps1` demonstrates fail-closed behavior with synthetic JSON mutations and no mutation of tracked application source.
- The remote URL is a *recorded local Git configuration*, **not a network-attested owner**, license grant, copyright review or approved release.
- `-AllowLocalOnly` permits checkpoints for source packages without origin **only with explicit opt-in**. The result is labeled `LOCAL_ONLY_NO_ORIGIN` and cannot be passed off as externally verified provenance.
- Baseline checkpoints are not signed and are not tamper-evident against a malicious operator who controls both the report and repository. Independent remote repository review is separately required before release.

## Real local tests

| Source | Mode | Result |
| --- | --- | --- |
| `craft-signing-core` | Configured origin + clean Git HEAD/tree | PASS |
| `wordcraft` | Configured origin + clean Git HEAD/tree | PASS |
| `craft-suite-installer` | Explicit local-only mode (no origin configured) | PASS, NO remote trust |
| Synthetic tampered copies | 13 fail-closed cases | 13/13 PASS |

Evidence root: `C:\Users\User\Documents\CRAFT_FORK_METHOD_V1_ACCEPTANCE_20261024`

Expected attacks rejected include commit/tree substitution, wrong origin, wrong path/branch, forged clean flag, forged release claim, unsupported schema, destination reuse, output inside Git, dirty working tree, missing origin and implicit local-only approval.

## Commands (Windows PowerShell 5.1 or PowerShell 7)

```powershell
$repo = 'C:\Users\User\Documents\GitHub\craft-signing-core'
$out  = 'C:\Users\User\Documents\new-unique-checkpoint-directory'
& 'C:\Users\User\Documents\GitHub\craft-fork-method\scripts\New-CraftBaseline.ps1' -RepositoryPath $repo -OutputDirectory $out
& 'C:\Users\User\Documents\GitHub\craft-fork-method\scripts\Test-CraftBaseline.ps1' -RepositoryPath $repo -BaselinePath (Join-Path $out 'craft-baseline.json')
```

For an intentionally local-only project without an `origin` remote, both commands additionally require `-AllowLocalOnly`.

## Unfinished external gates

This source-only acceptance does not close G0 (legal license/redistribution review), G2 (reproducible upstream build), G5 (human acceptance), G6 (publicly trusted installer signing) or any qualified timestamp/eIDAS provider requirement. The 13 installed Craft applications and their production branches have not been modified.

## Executable G0–G7 release-evidence gate

New files: `templates/edition-gates-v1.json`, `scripts/Test-CraftEditionGates.ps1`, `scripts/Test-CraftEditionGatesNegative.ps1`.

The checker accepts a completed stage only when its evidence file is present inside the designated evidence root with the exact pinned SHA-256. No two stages may reuse an identical evidence file. The public release setting is *always* `NO_GO`; even a locally complete checklist may only be submitted for separate human review.

A live SHA-256 pin from the Signing Core baseline was accepted as synthetic **G1** test evidence: `1/8` machine verified, remaining stages pending. Twelve adversarial manipulations were rejected: public-release forgery, human-license-approval forgery, wrong evidence hash, traversal, absolute path, missing evidence, wrong gate order/count, evidence on a pending gate, duplicate evidence, fabricated PASS and wrong schema.

**Final v1 local acceptance: 25/25 negative controls PASS; 3 provenance baselines PASS.** Proof files:

- `C:\Users\User\Documents\CRAFT_FORK_METHOD_V1_ACCEPTANCE_20261024\negative-v1\acceptance.json`
- `C:\Users\User\Documents\CRAFT_FORK_METHOD_V1_ACCEPTANCE_20261024\edition-gates-v1-tests\acceptance.json`

These are local algorithm acceptance results. They do not certify real software redistribution rights, PDF eIDAS qualification, installer public-signing status or remote GitHub identity.
