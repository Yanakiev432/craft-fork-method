#!/usr/bin/env python3
"""Fail-closed structural checks for a source-review-only Craft CI packet.

This is an OFFLINE consistency gate, never a replacement for the GitHub API
exact-HEAD auditor or independently validated qualified signatures.
"""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
import re

EXPECTED = {"pdfcraft": 7, "wordcraft": 5, "gridcraft": 5, "craft-signing-core": 1}
SHA = re.compile(r"^[0-9a-f]{40}$")
PENDING = {"NOT_ACCEPTED", "NOT_APPROVED"}

def verify(packet: dict) -> None:
    def require(test: bool, reason: str) -> None:
        if not test:
            raise ValueError(reason)

    require(packet.get("schema") == "craft.signing.source-review-evidence.v1", "unrecognized schema")
    require(packet.get("release_ready") is False, "no reviewed trusted release")
    require(packet.get("public_trusted_release_enabled") is False, "public release must remain disabled")
    require(packet.get("merge_main_automatically") is False, "no automatic main merge")
    monitor = packet.get("read_only_monitor", {})
    require(monitor.get("exact_commit_ci_ready") is True, "source CI must be independently accepted")
    require(monitor.get("passing") == 18 and monitor.get("verification_count") == 18, "expected 18/18")
    require(SHA.fullmatch(monitor.get("output_sha256", "")) is None, "report digest cannot be a git SHA")
    digest = monitor.get("output_sha256", "")
    require(re.fullmatch(r"[a-f0-9]{64}", digest) is not None, "report must have SHA256")
    reviews = packet.get("repositories")
    require(isinstance(reviews, list) and len(reviews) == 4, "expected exactly 4 projects")
    found = set()
    run_ids = set()
    for item in reviews:
        name = item.get("key")
        require(name in EXPECTED and name not in found, "missing or duplicate project")
        found.add(name)
        repository = "Yanakiev432/" + name
        require(item.get("repository") == repository, "repository identity changed")
        require(item.get("review_status") == "READY_FOR_REVIEW" and item.get("merged") is False, "review state changed")
        require(item.get("pr", "").startswith("https://github.com/" + repository + "/pull/"), "PR repository differs")
        sha = item.get("head_sha", "")
        require(SHA.fullmatch(sha) is not None, "exact SHA required")
        checks = item.get("checks")
        require(isinstance(checks, list) and len(checks) == EXPECTED[name], "missing or extra checks")
        names = set()
        for row in checks:
            label = row.get("name")
            require(isinstance(label, str) and label and label not in names, "duplicate/blank workflow")
            names.add(label)
            require(row.get("status") == "completed" and row.get("conclusion") == "success", "unaccepted CI")
            require(row.get("head_sha") == sha, "CI refers to different commit")
            url = row.get("run_url", "")
            prefix = "https://github.com/" + repository + "/actions/runs/"
            require(url.startswith(prefix) and url[len(prefix):].isdigit(), "CI source is not repo Actions")
            require(url not in run_ids, "duplicated action evidence URL")
            run_ids.add(url)
    require(found == set(EXPECTED), "missing project")
    gates = packet.get("non_bypassable_external_gates", {})
    require(len(gates) >= 6, "external release gates missing")
    for gate in gates.values():
        require(gate.get("status") in PENDING, "external gate may only be accepted with independently reviewed evidence")
    policies = packet.get("tsa_provider_policy", {})
    require(policies.get("ACCV", {}).get("usage", "").startswith("NO_UNRESTRICTED"), "ACCV free professional use must not be inferred")
    require(policies.get("APED", {}).get("usage", "").startswith("NO_AUTHENTICATION"), "APED cannot be treated as unrestricted")
    require("NO_APPROVED_AUTOMATION" in policies.get("BORICA", {}).get("usage", ""), "BORICA approval must not be implied")

def selftest(original: dict) -> None:
    verify(original)
    cases = [
        (lambda p: p.__setitem__("release_ready", True)),
        (lambda p: p.__setitem__("public_trusted_release_enabled", True)),
        (lambda p: p["repositories"][0]["checks"][0].__setitem__("head_sha", "0"*40)),
        (lambda p: p["repositories"][1]["checks"][0].__setitem__("conclusion", "failure")),
        (lambda p: p["repositories"][2]["checks"].pop()),
        (lambda p: p["repositories"][2]["checks"][0].__setitem__("run_url", "https://evil.invalid/run")),
        (lambda p: p["non_bypassable_external_gates"]["final_real_document_eu_dss"].__setitem__("status", "PASS")),
        (lambda p: p["tsa_provider_policy"]["ACCV"].__setitem__("usage", "FREE_UNLIMITED_COMMERCIAL")),
    ]
    for i, bad in enumerate(cases):
        data = copy.deepcopy(original)
        bad(data)
        try:
            verify(data)
        except ValueError:
            continue
        raise AssertionError(f"negative control {i} failed open")

def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("manifest", nargs="?", default="docs/CRAFT_SIGNING_SOURCE_REVIEW_EVIDENCE_20261020.json")
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args()
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    verify(data)
    if args.self_test:
        selftest(data)
    print("CRAFT_SOURCE_REVIEW_EVIDENCE_STRUCTURE=PASS; RELEASE_READY=NO_GO")
if __name__ == "__main__":
    main()
