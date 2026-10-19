# SignPath Foundation — verified free-signing application dossier (draft)

**Status 2026-10-19: NOT SUBMITTED, NOT APPROVED.** Not a qualified release.

## Evidence: signed upstream and actual GitHub fork

| Our public fork | Upstream | Official signed Windows MSI | SHA256 |
|---|---|---|---|
| https://github.com/Yanakiev432/pdfcraft | https://github.com/storytold/pdfcraft | v0.9.0, 71,999,488 bytes | 372a80ff736b0e1f242f7001a2157de081fa5fdb2192d001b1cbbf7f53739f4b |
| https://github.com/Yanakiev432/wordcraft | https://github.com/storytold/wordcraft | v0.8.0, 81,330,176 bytes | 7ca27a11f7122322a2525af4e11308abb70b1cdb2625b5ab95afadcac12d79bb |
| https://github.com/Yanakiev432/gridcraft | https://github.com/storytold/gridcraft | v0.8.0, 14,131,200 bytes | 2986211704e8ef791f2efd0278e46b13ed7f23f3da6b247f982c1c2acf81d852 |

All three source repositories are public Apache-2.0 GitHub forks, confirmed by GitHub's fork and parent fields. Original installers were downloaded and their signatures checked using Get-AuthenticodeSignature on Windows: status Valid, upstream publisher Learning Machines Inc. We have NOT code-signed our fork outputs. Upstream packages were neither executed nor installed.

## Public policy and changes

- PdfCraft policy https://github.com/Yanakiev432/pdfcraft/pull/9 ; source-brand cleanup https://github.com/Yanakiev432/pdfcraft/pull/10 ; combined signing QA https://github.com/Yanakiev432/pdfcraft/pull/11 .
- WordCraft policy https://github.com/Yanakiev432/wordcraft/pull/2 ; brand cleanup https://github.com/Yanakiev432/wordcraft/pull/3 ; combined signing QA https://github.com/Yanakiev432/wordcraft/pull/4 .
- GridCraft policy https://github.com/Yanakiev432/gridcraft/pull/2 ; brand cleanup https://github.com/Yanakiev432/gridcraft/pull/3 ; combined signing QA https://github.com/Yanakiev432/gridcraft/pull/4 .
- Nine non-open upstream ArtCraft trademark files per project were removed from the modified sources; source-brand gates PASS. Application icons separately documented as MIT/Apache licensed. Screenshots, binaries, website and installer metadata still need inspection.

## Release architecture and approval gates

The requested free code signing would cover only our own modified Windows EXE/DLL/MSI binaries built from reviewed public source, using a pinned GitHub Actions release commit and manually approved hosted signing request. A certificate for qualified document signatures (B-Trust USB QES) is not a software code-signing certificate. No private signing keys, hardware PINs, or user PDFs may enter public CI.

The owner must independently confirm all requirements in https://signpath.org/terms.html and https://signpath.org/apply.html , authenticate, apply, obtain written SignPath Foundation acceptance, assign reviewers/MFA, set branch protections, configure verified trusted source builds and signing permissions, and approve each release. We cannot assume that three product forks may share one free signing identity.

After approval, hash produced artifacts; sign only immutable verified build outputs; independently check Authenticode Code Signing EKU, timestamp, chain, exact MSI/EXE hash and publisher identity; run install/uninstall/rollback tests on clean Windows with Smart App Control enabled. No policy bypass. NO trusted release or signed MSI exists until this evidence passes.

## Proposed text for maintainer application — NOT SENT

I maintain public modified forks of PdfCraft, WordCraft and GridCraft, each preserving verifiable source provenance and its Apache-2.0 license obligations. The original upstream projects publish Microsoft Windows x64 installers with independently verified valid Authenticode signatures from Learning Machines Inc. The exact upstream versions and hashes are documented above. Our forks have removed the separately protected ArtCraft brand assets. We request an eligibility review for free SignPath Foundation code signing for our own open-source binaries only, built through auditable GitHub Actions workflows from reviewed release commits. We will configure MFA, origin-verified trusted builds, human signing approval, post-signing verification and Windows SAC acceptance prior to a public release. Please advise whether three related modified forks require separate applications.

This application text is a draft: no external approval or submission has been made. The unrelated qualified RFC3161 TSA, B-Trust Office token interoperability, independent EU DSS positive B-T/LT/LTA validation, and SignPath Foundation signing remain separate non-negotiable gates.
