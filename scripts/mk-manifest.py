#! /usr/bin/python
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

    cmd = ["dpkg-query", "-f", "\\t".join(map(lambda f: "${%s}" % f, fields)) + "\\n", "-W"]

    packages = [
            dict(zip(fields, line.split("\t")))
            for line in filter(
                lambda line: line.strip() != "",
                subprocess.check_output(cmd).decode("utf-8").split("\n")
                )
            ]
    with open(dest, "w") as fh:
        for p in packages:
            fh.write(json.dumps(p) + "\n")

def make_manifest_packages_txt(src="/tmp/packages.jsonl", dest="/tmp/packages.txt"):
    fields = '''
      db:Status-Abbrev Package Version Architecture binary:Summary
    '''.split()

    with open(src, "r") as src_fh:
        packages = [json.loads(line.decode("utf-8")) for line in src_fh.readlines()]

    width = {}
    for f in fields:
        width[f] = 0
        for package in packages:
            if width[f] < len(package[f]):
                width[f] = len(package[f])

    with open(dest, "w") as dest_fh:
        for package in packages:
            line = "  ".join(map(lambda f: "%-" + str(width[f]) + "s", fields)) % tuple(map(lambda f: package[f], fields))
            line = line.rstrip().encode("utf-8")
            dest_fh.write(line + "\n")

make_manifest_packages_jsonl()
make_manifest_packages_txt()

