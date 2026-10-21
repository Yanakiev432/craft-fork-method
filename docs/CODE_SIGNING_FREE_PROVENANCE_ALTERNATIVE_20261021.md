# Code signing after SignPath Foundation decision (2026-10-21)

## Verified application status

The maintainer submitted an application to the SignPath Foundation program
on **2026-10-21**. The provider acknowledged submission and declined
the **free Foundation code-signing application on the same date**.

The provider described the reason as insufficient public evidence of project
adoption or reputation. Review indicators include independent community
references and discussions, adoption metrics, sustained contributions, and
possible institutional backing. It expressly allows a later reapplication when
public visibility increases. This is **not a technical failure** and must not
be treated as a granted certificate. The provider offered a paid subscription,
which is not a substitute for the project's zero-cost requirement.

- Foundation program: https://signpath.org/
- Reapplication terms: https://signpath.org/apply.html
- Do not publish the private email body, maintainer identity, or credentials
  in a public GitHub repository.

**Current release flag: `SIGNPATH_FOUNDATION=DECLINED_2026-10-21`.**

## Free independent artifact provenance — usable now

GitHub Actions artifact attestations use Sigstore provenance for publicly
hosted repositories, available to public GitHub repositories without a
commercial signing subscription:
https://docs.github.com/en/actions/concepts/security/artifact-attestations

For a build-generated ZIP or executable produced by an authorized and reviewed
workflow, GitHub Actions `actions/attest` binds the exact artifact SHA-256
to the repository, workflow, commit SHA and build provenance. A reviewer can
verify it with:

```powershell
gh attestation verify 'C:\path\to\downloaded-artifact.zip' -R Yanakiev432/pdfcraft
```

**Never conflate Sigstore attestation with an Authenticode signature**, a
CA-issued Windows Code Signing EKU certificate, a Windows Smart App Control
allow decision, Microsoft Defender reputation, EU QES or RFC3161 QTSA.
Attestations are verifiable source-to-binary provenance, not operating-system
approval.

- Official GitHub documentation:
  https://docs.github.com/en/actions/concepts/security/artifact-attestations
- Official Windows Smart App Control signature requirements:
  https://support.microsoft.com/en-us/windows/security/threat-malware-protection/smart-app-control-frequently-asked-questions
- Independent GitHub verification CLI:
  https://cli.github.com/manual/gh_attestation_verify

## Concrete adoption and future Foundation reapplication

This is ongoing lawful community building, not synthetic popularity:
- Maintain reproducible software CI, changelogs and published issue templates.
- Publish full sources, artifact provenance, license/brand attribution and
  clear release notes for any developer test bundle.
- Seek real external users, independent reviews and verified contributors.
- If an institution offers support, record genuine, authorized public
  references, not fabricated endorsements.
- Reapply only after genuinely documenting such external public evidence.
- Neither pay for the subscription nor upload a private key without a separate
  user decision. No use of a personal B-Trust document QES certificate for
  unrelated Windows executable publisher claims.

## Safe technical distribution until approved Windows code signing

1. Keep the public GitHub release workflow's fail-closed blocking preflight.
2. Optionally make an **explicitly marked UNSIGNED DEVELOPMENT ARTIFACT**
   from a reviewed commit using GitHub Actions with source and SHA provenance.
   Never represent it as a SAC-compatible installer.
3. Use `gh attestation verify` before inspecting the test artifact.
4. Do not disable or bypass Smart App Control/WDAC. If SAC rejects an unsigned
   test installer, record `SAC=REJECTED`, not `PASS`.
5. Preserve actual publisher trust: `CRAFT_RELEASE_PUBLISHER_SHA256` must
   correspond to a separately approved trusted code-signing cert, not the
   signature embedded in arbitrary downloaded content.
6. A public trusted MSI requires a real authorized Authenticode signature,
   independent SHA/publisher/timestamp checks and SAC install/uninstall tests.

## Independent qualified PDF signing

BORICA request SD1614999 is a separate pending external technical dependency.
It is not a blocker for the Craft build, RFC3161 parsing, manual qualified TSA
workflow, OPC signing tests, or Sigstore development attestations. Neither the
SignPath rejection nor GitHub attestations affects legal TSA qualification.
