#!/usr/bin/env python3
"""cc370#393: check as370's --usings export against hand-written answers.

The answers below are derived from tests/useexp.s BY HAND and not from a run of
the thing under test.  That is the whole value of this file: the export and the
checker must disagree if either is wrong, and a checker generated from the
export's own output would agree with any export at all.

Two of these cases exist only here.  An omitted base register (`USING D,,9') is
0 of 31,529 tree-wide and an operandless DROP is 4, so no corpus run reaches
either.  And exactly ONE module in the whole corpus writes PUSH USING and
assembles byte-identical (IGG019V6), so the PUSH/POP rows below are very nearly
all the coverage that half of the export will ever have.
"""
import sys

# (seq, kind, loc, reg, value, valsectname, valdsect, abs, by)
#
# Read against tests/useexp.s.  BALR 12,0 leaves R12 holding 2, which is why
# `USING *,12' has value 2 and not 0.
WANT = [
    (19, "USING",  2, 12,    2, "USEEXP", 0, 0, "stmt"),  # *  -> lc after BALR
    (20, "USING",  2, 11,    0, "USEEXP", 0, 0, "stmt"),  # BY POSITION, not by
    (20, "USING",  2, 10, 4096, "USEEXP", 0, 0, "stmt"),  # register number
    (21, "USING",  2,  9, 4096, "USEEXP", 0, 0, "stmt"),  # omitted reg: 9 still
                                                          # advances to +4096
    (22, "PUSH",   2, -1,    0, "",       0, 0, "stmt"),
    (23, "DROP",   2, 11,    0, "USEEXP", 0, 0, "stmt"),
    (24, "USING",  2,  8,    0, "MYDS",   1, 0, "stmt"),  # a DSECT domain: loc
                                                          # is the CSECT's,
                                                          # valsect is the DSECT
    (25, "USING",  2,  7,    0, "USEEXP", 0, 1, "stmt"),  # ABSOLUTE: valsect is
                                                          # where the EQU's card
                                                          # was, and holds no
                                                          # address -- abs says so
    (26, "POP",    2, -1,    0, "",       0, 0, "stmt"),
    (26, "DROP",   2,  8,    0, "MYDS",   1, 0, "pop"),   # what the POP DID, so
    (26, "DROP",   2,  7,    0, "USEEXP", 0, 1, "pop"),   # nothing downstream
    (26, "USING",  2, 11,    0, "USEEXP", 0, 0, "pop"),   # keeps a stack
    (27, "DROP",   2,  6,    0, "",       0, 0, "noop"),  # named, never based
    (28, "DROP",   2, 12,    2, "USEEXP", 0, 0, "stmt"),
    (28, "DROP",   2, 10, 4096, "USEEXP", 0, 0, "stmt"),
    (31, "DROP",   2,  0,    0, "",       0, 0, "noop"),  # cc370#394: a bare
                                                          # DROP drops R0 and
                                                          # leaves 9 and 11 live
    (32, "PUSH",   2, -1,    0, "",       0, 0, "stmt"),  # never popped
    (34, "USING", 32,  5,   32, "USEEXP", 0, 0, "stmt"),  # after ORG: loc moved
                                                          # and the record needs
                                                          # no ORG record to say so
]


def main(path):
    rows, cols = [], None
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("#columns"):
            cols = line.split("\t")[1:]
            continue
        if line.startswith("#"):
            continue
        rows.append(dict(zip(cols, line.split("\t"))))

    bad = []
    if cols is None:
        print("useexp: FAIL -- no #columns header")
        return 1
    if len(rows) != len(WANT):
        print("useexp: FAIL -- %d records, expected %d" % (len(rows), len(WANT)))
        for r in rows:
            print("   ", r)
        return 1

    # The statement numbers are relative: the fixture's comment block may grow,
    # and an answer keyed to an absolute line would then be wrong for a reason
    # that has nothing to do with the export.  Only the OFFSETS between them are
    # asserted, against the first record's seq.
    base = int(rows[0]["seq"])
    want_base = WANT[0][0]
    for i, (r, w) in enumerate(zip(rows, WANT)):
        got = (int(r["seq"]) - base + want_base, r["kind"], int(r["loc"]),
               int(r["reg"]), int(r["value"]), r["valsectname"],
               int(r["valdsect"]), int(r["abs"]), r["by"])
        if got != w:
            bad.append("  record %d\n     got  %s\n     want %s" % (i, got, w))

    # A record's own (sect, loc) is what makes ORG need no record, so assert the
    # section is carried on every row and not merely on the interesting ones.
    for i, r in enumerate(rows):
        if r["sectname"] != "USEEXP" or r["sect"] != "1":
            bad.append("  record %d: sect/sectname is %s/%s, not 1/USEEXP"
                       % (i, r["sect"], r["sectname"]))

    if bad:
        print("useexp: FAIL")
        print("\n".join(bad))
        return 1
    print("useexp: OK (%d events: 4 kinds, by position, omitted reg, DSECT and "
          "absolute domains, the POP diff, noop, ORG)" % len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
