# Craft dependency and plugin evidence registry

Updated 2026-10-20. Evidence: local repository inspection and archived 2026-10-17 engineering transcript. Historical versions are observations, not current installed-version guarantees.

| Component | Category | Actual role | Evidence / boundary |
|---|---|---|---|
| RA Core | Connected remote agent | Windows source inspection, Git, build commands, tests, file operations | Agent status checked 2026-10-20; no PIN handling |
| SentinelX | Machine administration plugin | Elevated deployment, installed-binary and certificate-store diagnostics | Recorded in PLUGIN_ORCHESTRATION.md; do not assume current session access |
| GitHub | Repository plugin/API | Remote branches, commits, PRs and publication | Remote verification required; local commit != push |
| Rust / Cargo 1.99.1 | Compiler/package manager | Build pdfcraft-sign and application | 2026-10-17 transcript |
| Visual Studio Build Tools 2022 / MSVC 14.44.35207 | Native toolchain | Windows linker/compiler | 2026-10-17 transcript |
| cryptoki 0.10.1 | Rust dependency | PKCS#11 slots, certificates, C_Sign integration | 2026-10-17 transcript; verify current Cargo.lock |
| rustls-cng 0.7.1 | Rust dependency | Windows CNG signing | 2026-10-17 transcript |
| SafeNet Authentication Client 10.9.4482.0 | Token middleware | B-Trust smartcard PKCS#11/CSP interface | Historical signed eTPKCS11.dll inspection |
| Windows CNG / CSP | Operating system APIs | Certificate selection and hardware-backed signatures | Keep hardware key non-exportable |
| PAdES / CMS | Standards/formats | PDF embedded signature and verification | Cryptographic VALID does not imply QES |
| WSL | Build environment | Windows GNU cross-build workaround where needed | Local orchestration document |
| Figma / Canva / Adobe Express / Base44 | Optional design/prototype plugins | Only relevant to visual or prototyping work | Not used in verified B-Trust repair |

## Required evidence for each new dependency
Record name, category, exact resolved version, upstream URL, license/SPDX, lockfile path, reason selected, alternatives, integration files, install command, reproducible test, security impact, rollback, SHA-256 where applicable and verification date.

## Hard acceptance rules
- Never count a skipped hardware integration test as PASS.
- Never equate cryptographic validity, trusted chain, revocation, timestamp and QES.
- Never write PIN, private key, access token or personal certificate into source control.
- Never call a plugin "used" merely because it is installed or suggested.
- Capture precise build logs, exit codes, hashes, installed binary provenance and Git remote SHA before marking release PASS.
