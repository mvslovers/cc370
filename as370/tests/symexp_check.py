#!/usr/bin/env python3
"""Read an as370 --sym export and resolve tests/symexp.s's displacements.

The point of the fixture is that the answers are written into the source by
hand (TCBFSA is the third fullword of TCB, PARMPTR follows six plus two bytes
of code), so this scan can be wrong in a way the export itself cannot hide.

Prints one line and exits 0, or prints every failure and exits 1.
"""
import sys

COLUMNS = ["name", "value", "length", "type", "sect", "sectname",
           "dsect", "esdid", "defined", "entry"]

path = sys.argv[1]
rows, header, columns = [], None, None
for line in open(path, encoding="ascii").read().splitlines():
    if line.startswith("#columns\t"):
        columns = line.split("\t")[1:]
    elif line.startswith("#as370-sym\t"):
        header = line.split("\t")[1]
    elif line.startswith("#"):
        continue
    else:
        f = line.split("\t")
        r = dict(zip(COLUMNS, f))
        r["_n"] = len(f)
        rows.append(r)

bad = []


def check(cond, msg):
    if not cond:
        bad.append(msg)


def one(name):
    hit = [r for r in rows if r["name"] == name]
    check(len(hit) == 1, f"{name}: expected one record, got {len(hit)}")
    return hit[0] if hit else None


def resolve(sect, target):
    """The scan #373 exists for: nearest defined symbol at or below target."""
    cand = [r for r in rows if r["sect"] == sect and r["defined"] == "1"
            and int(r["value"]) <= target]
    return max(cand, key=lambda r: int(r["value"])) if cand else None


check(header == "1", f"header: expected version 1, got {header!r}")
check(columns == COLUMNS, f"columns: {columns} != {COLUMNS}")
check(all(r["_n"] == len(COLUMNS) for r in rows),
      "a record does not have %d fields" % len(COLUMNS))

tcb, sym = one("TCB"), one("SYMEXP")
if tcb and sym:
    # The displacement `8(4,13)' under `USING TCB,13'.
    a = resolve(tcb["sect"], 8)
    check(a and a["name"] == "TCBFSA" and a["value"] == "8" and a["length"] == "4",
          f"8(4,13) under USING TCB,13 resolved to {a and a['name']!r}, "
          "expected TCBFSA at 8 length 4")
    # The control: offset 8 of the CSECT is a different symbol entirely.
    b = resolve(sym["sect"], 8)
    check(b and b["name"] == "PARMPTR",
          f"offset 8 of SYMEXP resolved to {b and b['name']!r}, expected PARMPTR")
    check(tcb["dsect"] == "1" and sym["dsect"] == "0",
          "TCB must be a DSECT and SYMEXP must not")
    check(sym["type"] == "SD" and sym["esdid"] != "0",
          f"SYMEXP: expected an SD with an ESDID, got {sym['type']}/{sym['esdid']}")

eq = one("TCBLEN")
check(eq and eq["type"] == "ABS" and eq["value"] == "16",
      f"TCBLEN: expected ABS 16, got {eq and (eq['type'], eq['value'])}")

ext = one("EXTSYM")
check(ext and ext["type"] == "ER" and ext["defined"] == "0",
      f"EXTSYM: expected an undefined ER, got {ext and (ext['type'], ext['defined'])}")

# The unnamed DSECT: its own section, no name invented for it or for its rows.
un = one("UNPARM")
if un and tcb:
    check(un["sect"] != tcb["sect"], "the unnamed DSECT is not TCB's section")
    check(un["dsect"] == "1" and un["sectname"] == "",
          f"UNPARM: expected dsect=1 and an empty sectname, got "
          f"{un and (un['dsect'], un['sectname'])}")
    owner = [r for r in rows if r["sect"] == un["sect"] and r["name"] == ""]
    check(len(owner) == 1 and owner[0]["dsect"] == "1",
          "the unnamed DSECT's own record should be the one with no name")

if bad:
    for m in bad:
        print("symexp:", m)
    sys.exit(1)
print("symexp: OK (8(4,13) -> TCBFSA, the CSECT's own 8 -> PARMPTR, "
      "ABS EQU, undefined ER, unnamed DSECT)")
