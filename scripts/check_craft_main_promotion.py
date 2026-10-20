#!/usr/bin/env python3
"""Craft main-promotion provenance gate. Read-only, fail-closed.

Offline mode checks manifest structure and negative test vectors. --live
independently checks real GitHub main, parent SHA, source tree and blocked
release workflows. A green source gate can NEVER claim eIDAS QES or MSI trust.
"""
from __future__ import annotations
import argparse
import base64
import copy
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.request

HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED = {"pdfcraft": 7, "wordcraft": 5, "gridcraft": 5, "craft-signing-core": 1, "craft-fork-method": 0}
DENIAL = re.compile(r"(?m)^  release:\s*\n    needs: fail-closed-release-preflight\s*$")
PIN = "storytold/craft-common-actions/.github/workflows/release.yml@d7bf8f06e138618890d0ebe8a84a18b010bf3f66"


def require(ok: bool, reason: str):
    if not ok:
        raise ValueError(reason)


def validate(snapshot: dict):
    require(snapshot.get("schema") == "craft.source-main-promotion.v1", "invalid schema")
    require(snapshot.get("baseline_exact_ci") == "18_OF_18_SUCCESS_ON_REVIEWED_SOURCE_COMMIT", "source CI is incomplete")
    require(bool(HEX64.fullmatch(snapshot.get("baseline_audit_sha256", ""))), "live audit digest invalid")
    require(snapshot.get("technical_source_merged_to_main") is True, "source not merged")
    for field in (
        "real_btrust_hardware_signature_verified",
        "qualified_tsa_eidas_tsl_at_gentime_verified",
        "final_independent_eu_dss_pades_b_t_lt_lta_verified",
        "signpath_foundation_application_approved",
        "own_code_signed_windows_installer_accepted",
        "clean_windows_sac_test_pass",
        "public_trusted_release_ready",
    ):
        require(snapshot.get(field) is False, f"unverified external release condition: {field}")
    require(snapshot.get("release_preflight_status") == "MUST_REMAIN_FAIL_CLOSED", "no public release approval")
    items = snapshot.get("modules", [])
    require(isinstance(items, list) and len(items) == 5, "five repositories required")
    found=set()
    for item in items:
        name = item.get("repo", "").removeprefix("Yanakiev432/")
        require(name in EXPECTED and name not in found, "unknown or duplicate source project")
        found.add(name)
        for field in ("reviewed_head_sha","merge_sha","reviewed_tree_sha","expected_main_sha_at_promotion"):
            require(bool(HEX40.fullmatch(item.get(field,""))), f"missing exact {field}")
        require(item["expected_main_sha_at_promotion"] == item["merge_sha"], "promotion SHA changed")
        require(item.get("required_ci_count") == EXPECTED[name], "source CI count changed")
        require(item.get("merged") is True and item.get("merge_method") == "merge", "main merge provenance missing")
        require(item.get("github_pr") == f"https://github.com/Yanakiev432/{name}/pull/"+str({"pdfcraft":15,"wordcraft":5,"gridcraft":5,"craft-signing-core":3,"craft-fork-method":1}[name]), "unrecognized reviewed pull request")
        require(item.get("blocking_public_release_required") is (name in {"pdfcraft","wordcraft","gridcraft"}), "release security scope incorrect")
        require(item.get("main_may_advance_only_with_reviewed_additional_commits") is (name=="craft-fork-method"), "main evolution policy unexpected")
    require(found == set(EXPECTED), "missing repository")


def offline_negative_controls(snapshot:dict):
    validate(snapshot)
    vectors = [
        lambda d: d.__setitem__("public_trusted_release_ready", True),
        lambda d: d.__setitem__("qualified_tsa_eidas_tsl_at_gentime_verified", True),
        lambda d: d["modules"][0].__setitem__("merge_sha", "0"*40),
        lambda d: d["modules"][0].__setitem__("reviewed_tree_sha", "not-sha"),
        lambda d: d["modules"][2].__setitem__("blocking_public_release_required", False),
        lambda d: d["modules"][3].__setitem__("required_ci_count", 0),
        lambda d: d["modules"].pop(1),
    ]
    for i,modify in enumerate(vectors):
        sample=copy.deepcopy(snapshot)
        modify(sample)
        try:validate(sample)
        except ValueError:continue
        raise AssertionError(f"offline tamper negative test {i} failed open")


def get_json(url:str):
    headers={"Accept":"application/vnd.github+json","User-Agent":"Craft-Main-Provenance-ReadOnly"}
    token=os.environ.get("GITHUB_TOKEN","")
    if token:headers["Authorization"]="Bearer "+token
    request=urllib.request.Request(url,headers=headers)
    with urllib.request.urlopen(request,timeout=18) as response:
        return json.load(response)


def audit_live(snapshot: dict):
    findings=[]
    for item in snapshot["modules"]:
        repo=item["repo"]
        base=f"https://api.github.com/repos/{repo}"
        current=get_json(base+"/branches/main")["commit"]["sha"]
        merge=get_json(base+"/git/commits/"+item["merge_sha"])
        source=get_json(base+"/git/commits/"+item["reviewed_head_sha"])
        parents={p["sha"] for p in merge.get("parents",[])}
        require(item["reviewed_head_sha"] in parents, f"{repo} merge does not include reviewed head")
        require(merge["tree"]["sha"] == source["tree"]["sha"] == item["reviewed_tree_sha"], f"{repo} merged source tree differs from tested PR")
        if item["main_may_advance_only_with_reviewed_additional_commits"]:
            # The audit repository can itself gain additional reviewed commits;
            # the originally proven integration must remain reachable from main.
            comparison=get_json(base+"/compare/"+item["merge_sha"]+"...main")
            require(comparison.get("behind_by")==0 and comparison.get("status") in {"ahead","identical"}, f"{repo} main no longer descends from reviewed baseline")
        else:
            require(current == item["merge_sha"], f"{repo} main has unreviewed changes relative to source gate")
        denied=None
        if item["blocking_public_release_required"]:
            data=get_json(base+"/contents/.github/workflows/release.yml?ref=main")
            require(data.get("encoding")=="base64", f"{repo} cannot inspect release workflow")
            source_text=base64.b64decode(data["content"]).decode("utf-8")
            require(bool(DENIAL.search(source_text)), f"{repo} release job no longer depends on rejecting preflight")
            require("PUBLIC_RELEASE_NO_GO" in source_text and "exit 1" in source_text, f"{repo} fail-closed release stop missing")
            require(PIN in source_text and ".github/workflows/release.yml@main" not in source_text, f"{repo} mutable privileged workflow")
            denied=True
        findings.append({"repo":repo,"head_sha":current,"source_tree_verified":True,"reviewed_commit_in_merge_parents":True,"public_release_denied":denied})
    return findings


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("manifest",nargs="?",default="docs/CRAFT_MAIN_MERGE_PROVENANCE_20261020.json")
    p.add_argument("--live",action="store_true")
    p.add_argument("--self-test",action="store_true")
    args=p.parse_args()
    data=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    validate(data)
    if args.self_test:offline_negative_controls(data)
    result={"schema":"craft.source-main-verification-result.v1","manifest_valid":True,"source_ci_baseline":"18/18","source_main_provenance":("PASS" if args.live else "NOT_CHECKED_LIVE"),"trusted_release":"NO_GO"}
    if args.live:result["repositories"]=audit_live(data)
    print(json.dumps(result,indent=2))
if __name__=="__main__":
    main()
