#!/usr/bin/env python3
"""Read-only Craft 2026-10-21 TLS security and EU DSS acceptance audit.

Checks exact GitHub PR source heads, Cargo.lock fixes and commit-scoped CI.
Never grants B-Trust QES, eIDAS QTSA, Microsoft Office hardware interoperability
or trusted Windows MSI release based on successful test runners.
"""
from __future__ import annotations
import argparse
import base64
import copy
import json
import os
from pathlib import Path
import re
import tomllib
import urllib.request

SPEC = {
 "pdfcraft": {
  "pr":19,"sha":"9768befe200d0f7b1a1291724cebbdf8bd925cb6",
  "checks":["CI","Windows ARM64","Nix","Packaging lint",
            "Independent EU DSS PAdES profile boundary",
            "Patched TLS trust roots lockfile gate"],
  "packages":{"rustls-webpki":(0,103,16),"webpki-root-certs":(1,0,10)},
 },
 "wordcraft": {
  "pr":6,"sha":"cd367f8c3d6093baad859e29fe0b0a8534560ab5",
  "checks":["Packaging lint","Nix","Windows ARM64","Printing",
            "OPC wordcraft signing acceptance",
            "Reject compromised emSign TLS trust dependencies"],
  "packages":{"rustls-webpki":(0,103,16)},
 },
 "gridcraft": {
  "pr":7,"sha":"43c5b6ad14bc15d0a64421f773abca9f1c6a6c83",
  "checks":["CI","Nix","Packaging lint","OPC gridcraft signing acceptance",
            "Reject compromised emSign TLS trust dependencies"],
  "packages":{"rustls-webpki":(0,103,16)},
 },
}
HEX40=re.compile(r"^[0-9a-f]{40}$")
NO_GO={
 "actual_btrust_hardware_qes":"NOT_CHECKED",
 "qualified_rfc3161_at_token_generation_time":"NOT_CHECKED",
 "independent_final_eu_dss_b_t_lt_lta":"NOT_CHECKED",
 "real_microsoft_office_btrust_interoperability":"NOT_CHECKED",
 "signpath_foundation_authorized_issuer":"NOT_APPROVED",
 "own_windows_exe_msi_signed_and_sac":"NOT_VERIFIED",
}

def _require(v:bool,message:str):
 if not v:raise ValueError(message)

def _parse_locked(data:bytes,needed:dict):
 packages=tomllib.loads(data.decode("utf-8")).get("package",[])
 _require(isinstance(packages,list),"Missing Cargo.lock packages")
 result={}
 for name,minimum in needed.items():
  values=[p.get("version") for p in packages if isinstance(p,dict) and p.get("name")==name]
  _require(len(values)==1, "Missing or duplicate lockfile dependency "+name)
  val=values[0]
  _require(isinstance(val,str),"Malformed dependency version")
  parts=val.split(".")
  _require(len(parts)==3 and all(s.isascii() and s.isdecimal() for s in parts),
           "Unreviewed prerelease version "+name)
  triple=tuple(map(int,parts))
  _require(triple[:2]==minimum[:2] and triple[2]>=minimum[2],
           "Unpatched or unreviewed TLS dependency "+name)
  result[name]=val
 return result

def evaluate(records:dict)->dict:
 outputs=[]
 _require(isinstance(records,dict),"Invalid GitHub snapshot")
 for name,requirements in SPEC.items():
  row=records.get(name)
  _require(isinstance(row,dict),"Missing repository "+name)
  exact_sha=requirements["sha"]
  source_ok=(row.get("pr_head_sha")==exact_sha and row.get("branch_sha")==exact_sha)
  try:
   locked=_parse_locked(row.get("lockfile",b""),requirements["packages"])
   cargo_ok=True
  except (ValueError,UnicodeError,TypeError,tomllib.TOMLDecodeError):
   locked={}
   cargo_ok=False
  runs=row.get("runs",[])
  _require(isinstance(runs,list),"Invalid CI run listing")
  checks=[]
  for wanted in requirements["checks"]:
   valid=[r for r in runs if isinstance(r,dict) and r.get("name")==wanted and r.get("head_sha")==exact_sha]
   valid.sort(key=lambda x:(str(x.get("created_at","")),int(x.get("run_attempt",1))),reverse=True)
   latest=valid[0] if valid else None
   passed=(latest is not None and latest.get("status")=="completed" and latest.get("conclusion")=="success")
   checks.append({"name":wanted,"passed":bool(passed),"run_id":latest.get("id") if latest else None,
    "status":latest.get("status") if latest else "MISSING",
    "conclusion":latest.get("conclusion") if latest else "MISSING"})
  release=row.get("release_yml")
  denial=isinstance(release,str) and "needs: fail-closed-release-preflight" in release and "PUBLIC_RELEASE_NO_GO" in release and "exit 1" in release
  integration_ready=bool(source_ok and cargo_ok and denial and all(c["passed"] for c in checks))
  outputs.append({"repository":"Yanakiev432/"+name,"pr":requirements["pr"],
   "exact_head_sha":exact_sha,"head_matches":bool(source_ok),"patched_lock_verified":bool(cargo_ok),
   "locked_tls_packages":locked,"release_denial_preserved":bool(denial),
   "checks":checks,"software_security_ci_ready":integration_ready})
 all_ready=all(v["software_security_ci_ready"] for v in outputs)
 return {"schema":"craft.signing.security-20261021.v1",
  "source":"LIVE_GITHUB_API_OR_EXPLICIT_OFFLINE_FIXTURE",
  "software_security_ci_ready":bool(all_ready),
  "required_checks":sum(len(v["checks"]) for v in outputs),
  "passed_checks":sum(sum(c["passed"] for c in v["checks"]) for v in outputs),
  "external_qualification":NO_GO.copy(),
  "trusted_public_release_ready":False,
  "repositories":outputs}

def _github(url:str):
 token=os.environ.get("GITHUB_TOKEN","").strip()
 headers={"User-Agent":"Craft-TLS-QTSA-ReadOnly-20261021",
          "Accept":"application/vnd.github+json"}
 if token:headers["Authorization"]="Bearer "+token
 with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=20) as f:
  return json.load(f)

def fetch_live():
 output={}
 for name,spec in SPEC.items():
  base="https://api.github.com/repos/Yanakiev432/"+name
  pr=_github(base+"/pulls/"+str(spec["pr"]))
  branch=_github(base+"/branches/feature/"+("dss-baseline-profile-boundary-20261021" if name=="pdfcraft" else
      "tls-emsign-trust-chain-fix-20261021" if name=="wordcraft" else
      "tls-emsign-final-reviewed-20261021"))
  lock=_github(base+"/contents/Cargo.lock?ref="+spec["sha"])
  release=_github(base+"/contents/.github/workflows/release.yml?ref=main")
  runs=_github(base+"/actions/runs?head_sha="+spec["sha"]+"&per_page=100")
  _require(lock.get("encoding")=="base64" and release.get("encoding")=="base64","GitHub content encoding changed")
  output[name]={
    "pr_head_sha":pr["head"]["sha"],"branch_sha":branch["commit"]["sha"],
    "lockfile":base64.b64decode(lock["content"]),
    "release_yml":base64.b64decode(release["content"]).decode("utf-8"),
    "runs":runs.get("workflow_runs",[])}
 return output

def _fixture():
 out={}
 for name,spec in SPEC.items():
  lock="".join("[[package]]\nname = '"+n+"'\nversion = '"+str(v[0])+"."+str(v[1])+"."+str(v[2])+"'\n\n"
               for n,v in spec["packages"].items()).replace("'","\"").encode()
  out[name]={"pr_head_sha":spec["sha"],"branch_sha":spec["sha"],"lockfile":lock,
    "release_yml":"release:\n  needs: fail-closed-release-preflight\n  echo PUBLIC_RELEASE_NO_GO\n  exit 1\n",
    "runs":[{"name":check,"head_sha":spec["sha"],"created_at":"2026-10-21T15:00:00Z",
            "id":100+i,"status":"completed","conclusion":"success"} for i,check in enumerate(spec["checks"])]}
 return out

def test_fail_closed():
 good=_fixture()
 positive=evaluate(good)
 _require(positive["software_security_ci_ready"],"Offline positive fixture rejected")
 bads=[
  lambda r:r["wordcraft"].__setitem__("pr_head_sha","0"*40),
  lambda r:r["pdfcraft"].__setitem__("lockfile",r["pdfcraft"]["lockfile"].replace(b"0.103.16",b"0.103.15")),
  lambda r:r["gridcraft"]["runs"][0].__setitem__("conclusion","failure"),
  lambda r:r["wordcraft"].__setitem__("release_yml","untrusted: disabled gate missing"),
  lambda r:r["pdfcraft"]["runs"].pop(0),
  lambda r:r["gridcraft"].__setitem__("branch_sha","1"*40),
 ]
 for i,mutate in enumerate(bads):
  sample=copy.deepcopy(good);mutate(sample)
  _require(not evaluate(sample)["software_security_ci_ready"],"Negative fixture passed: "+str(i))

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument("--live",action="store_true")
 parser.add_argument("--self-test",action="store_true")
 parser.add_argument("--output",type=Path)
 parser.add_argument("--require-ready",action="store_true")
 opts=parser.parse_args()
 if opts.self_test:test_fail_closed()
 report=evaluate(fetch_live() if opts.live else _fixture())
 result=json.dumps(report,indent=2,ensure_ascii=False,sort_keys=True)+"\n"
 if opts.output:
  opts.output.parent.mkdir(parents=True,exist_ok=True)
  with opts.output.open("x",encoding="utf-8") as f:f.write(result)
 print(result)
 if opts.require_ready and not report["software_security_ci_ready"]:
  raise SystemExit(1)

if __name__=="__main__":
 main()
