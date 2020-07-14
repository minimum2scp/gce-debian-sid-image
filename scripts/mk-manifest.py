#! /usr/bin/python3
# -*- coding: utf_8 -*-

import json
import subprocess

def make_manifest_packages_jsonl(dest="/tmp/packages.jsonl"):
    fields = '''
      Architecture Conflicts Breaks Depends Enhances Essential Installed-Size Origin Package
      Pre-Depends Priority Provides Recommends Replace Section Status Suggests Version
      binary:Package binary:Summary db:Status-Abbrev db:Status-Want db:Status-Status db:Status-Eflag
      source:Package source:Version
    '''.split()

    cmd = ["dpkg-query", "-f", "\\t".join(["${%s}" % f for f in fields]) + "\\n", "-W"]

    packages = [
            dict(list(zip(fields, line.split("\t"))))
            for line in [line for line in subprocess.check_output(cmd).decode("utf-8").split("\n") if line.strip() != ""]
            ]
    with open(dest, "w") as fh:
        for p in packages:
            fh.write(json.dumps(p) + "\n")

def make_manifest_packages_txt(src="/tmp/packages.jsonl", dest="/tmp/packages.txt"):
    fields = '''
      db:Status-Abbrev Package Version Architecture binary:Summary
    '''.split()

    with open(src, "r") as src_fh:
        packages = [json.loads(line) for line in src_fh.readlines()]

    width = {}
    for f in fields:
        width[f] = 0
        for package in packages:
            if width[f] < len(package[f]):
                width[f] = len(package[f])

    with open(dest, "w") as dest_fh:
        for package in packages:
            line = "  ".join(["%-" + str(width[f]) + "s" for f in fields]) % tuple([package[f] for f in fields])
            line = line.rstrip()
            dest_fh.write(line + "\n")

make_manifest_packages_jsonl()
make_manifest_packages_txt()

