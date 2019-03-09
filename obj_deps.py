#!/usr/bin/env python
from __future__ import print_function

import sys

TGT = sys.argv[2]

with open(sys.argv[1], "r") as f:
    deps = f.read()

deps = deps.replace("\\\n", "")

objs = set(sys.stdin.read().split())

tgt = ""
for tok in deps.split():
    if tok[-1] == ':':
        if tgt != "":
            print()
            print()
        tgt = tok[:-1]
        tok = tok.replace(".o:", ".o.tar:")
        print(tok, end=" ")
        continue
    if tok[-3:] == '.cc':
        tok = tok.replace(".cc", ".o")
        tok = TGT + 'build/' + tok
        print(tok, end=" ")
        continue
    if tok[-2:] == '.h':
        tok = tok.replace(".h", ".o")
        tok = TGT + 'build/' + tok
        if tok in objs and tok != tgt:
            print(tok + ".tar", end=" ")

print()
