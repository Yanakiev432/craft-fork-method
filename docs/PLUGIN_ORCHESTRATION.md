# Craft plugin and tool orchestration contract

This document is normative for Craft edition engineering. A plugin is a capability boundary, **not** a substitute for verifying the tool actually exists, is connected, has the required permission and returned a real result. Tool availability can differ by conversation and account.

## Responsibility matrix

| Integration | Use it for | Do not use it for |
| --- | --- | --- |
| **GitHub plugin** | Repository metadata, branches, commits, files, issues, pull requests, reviews and publication where authorized | Local compilation, operating-system changes, USB tokens, assuming a repo exists without checking |
| **RA Core** | Authorized Windows machine operations: inspect local source, read/write bounded files, run PowerShell/Git, inspect build logs, launch tests, local process status; optional fixed GitHub profile operations | Assuming administrator rights, bypassing device security, accessing arbitrary paths, handling hardware PINs |
| **SentinelX** | Machine-side system administration where permitted: inspect Windows certificate stores, elevated installation, service/system diagnostics, verify deployed hashes and backups | Editing GitHub by implication, treating SYSTEM's profile as the interactive user's profile, silently changing Windows trust policy |
| **Remote Desktop Commander** | Fallback for authorized filesystem/terminal access when RA Core lacks a necessary capability | Defaulting to a second executor when RA Core already works, uncontrolled duplicate execution |
| **ChatGPT Work / cloud browser** | Browser-only administrative workflows, interactive web UI and site publication where supported; explicitly authorized actions | Pretending it is needed for local builds or substituting screenshots for logs and hashes |
| **Figma** | Editable UI specifications, components, design review and handoff when a design change requires it | Code execution, security or signing validation |
| **Canva / Adobe Express** | Visual identity, graphics and publication assets when needed | Build gates, code review or signature trust |
| **Base44** | Rapid app prototypes only when specifically chosen for the target architecture | Replacing an existing Craft Rust/desktop codebase without architectural review |
| **Google Drive / Docs / Sheets** | Requirements, shared documents, inventories and reports when the user has connected the source | Source-of-truth for code or credential storage |
| **Plugin Management** | Discover, connect or check permissions of missing plugins before claiming an operation is unavailable | Silent plugin installation or granting permissions |

Other domain-specific plugins are used only if their capability matches the task and the user has authorized it.

## Execution sequence

1. **Discover** actual tools and schemas in the current session. Identify the least-privileged tool for each operation; do not assume a historical tool count.
2. **Inspect** upstream and local workspace using GitHub for remote metadata and RA Core for local code, branch, dirty state, toolchains and logs.
3. **Plan** source changes, acceptance criteria, legal/attribution requirements and rollback. Use design plugins only when visual work is involved.
4. **Edit** locally through RA Core with small changes, explicit paths and a checkpoint after each coherent change. Use GitHub plugin for remote repository operations when possible.
5. **Build/test** through RA Core on the authorized Windows host. For WDAC-blocked native Rust builds, use the existing WSL cross-build toolchain; never disable WDAC. No default GitHub Actions.
6. **Inspect system trust/deploy** with SentinelX only when necessary and authorized. Distinguish CurrentUser from LocalMachine/SYSTEM stores.
7. **Verify** real executable output, document/UI status, hashes, process exit codes, rollback path and Git status. Do not mark PASS from a command being submitted or a background job being started.
8. **Publish** with GitHub plugin or authenticated local Git as authorized; verify the repository URL and commit SHA from GitHub.
9. **Use Work** only for remaining web UI steps that cannot be completed through connected tools, not as a mandatory intermediate step.
10. **Report** completed/failed/pending steps, exact evidence, limitations and next action.

## Capability and safety rules

- Read-only inspection first; mutation only after determining scope and user authorization.
- Never request or store smart-card PINs, passwords, signing keys, private tokens or credential files in repositories, logs or prompts.
- Hardware signing requires specific approval; validation of an existing signed document does not authorize creating a new signature.
- Certificate-chain trust, cryptographic integrity, revocation, timestamp and eIDAS/QES status are distinct verdicts.
- Do not add the individual signer as a trusted root merely to remove a yellow warning.
- If a tool call fails or times out, inspect job status and logs; never claim it succeeded.
- Windows service/SYSTEM and interactive user have different profiles and TEMP directories.
- For GitHub Free, prefer local PowerShell build/test gates; no Actions consumption unless explicitly chosen.
- Preserve upstream remotes, licensing, provenance, signed originals, and a working rollback copy.
- Do not upload private PDFs or machine logs to public GitHub repositories.

## Verified case: PdfCraft B-Trust (2026-10-17)

**RA Core** inspected Rust sources, compiled Windows GNU binaries through WSL and ran PdfCraft CLI/UI tests. **SentinelX** installed the staged binaries in Program Files with backup and SHA-256 comparison. **Windows certificate stores** supplied an already trusted B-Trust root; no global trust-policy change was needed. The final PdfCraft GUI inspection returned `Signed and all signatures are valid.` **GitHub** was used to create and verify the two new public Craft repositories. No Work or design plugin was needed for this repair.

This is evidence for the tested PDF only. It is not a blanket assertion about every certificate, PDF, revocation response or QES status.

## Checkpoint template

```text
Checkpoint ID:
Task / repository / branch / upstream SHA:
Tool and actual action:
Execution host / privilege:
Inputs (no secrets):
Command or operation:
Exit code / job ID / output location:
Tests / verdict / hashes:
Backup / rollback:
Git commit / remote verification:
Status: PASS | FAIL | BLOCKED | PENDING
Next action:
```
