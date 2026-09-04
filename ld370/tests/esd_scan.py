#!/usr/bin/env python3
"""Survey the ESD of a corpus of object decks: which symbols are weak externals,
and is any of them ALSO referenced by a hard EXTRN that nothing defines.

Written for issue #99 and kept because the claim it settles is the kind that goes
stale.  The #99 fix turns a silent rc 0 into a hard link failure for exactly one
input shape -- a WX and an ER on the same name with no definition in the closure
-- so "no current build acquires a new failure" had to be measured rather than
argued.  It was: @@STKLEN and @@CTCLUP are the ecosystem's only weak externals
and neither is ever paired with a hard ER.  Re-run this before touching the
promotion rule in g_intern, or when a new project starts using WXTRN.

Reads the deck format directly (an 80-byte EBCDIC card stream, ESD cards
identified by 02 'ESD'; each 16-byte item is name(8) + type(1) + ...), so it
needs no toolchain build and works on both loose .o files and ar370/ar archives.

usage: esd_scan.py [-x SUBSTR]... PATH...
  PATH      an object deck, an archive, or a directory to walk for both
  -x        skip any path containing SUBSTR (repeatable)

exit 1 if a weak external is paired with a hard ER that nothing in the scanned
set defines -- the shape that now fails the link.
"""
import os
import sys

T_SD, T_LD, T_ER, T_CM, T_WX = 0x00, 0x01, 0x02, 0x05, 0x0A
ESD = bytes([0x02, 0xC5, 0xE2, 0xC4])          # '\x02ESD' in EBCDIC


def decks(path):
    """yield (label, deck bytes) -- an archive contributes one deck per member."""
    with open(path, "rb") as f:
        d = f.read()
    if d[:8] != b"!<arch>\n":
        yield path, d
        return
    p = 8
    while p + 60 <= len(d):
        name = d[p : p + 16].decode("latin1").strip()
        try:
            size = int(d[p + 48 : p + 58].decode("latin1").strip())
        except ValueError:
            return                              # not an ar header: stop, don't guess
        if not name.startswith("/"):            # '/' and '//' are the symbol/name tables
            yield "%s(%s)" % (path, name), d[p + 60 : p + 60 + size]
        p += 60 + size + (size & 1)


def esd_items(deck):
    """yield (name, type) for every ESD item in an 80-byte card stream."""
    for off in range(0, len(deck) - 79, 80):
        c = deck[off : off + 80]
        if c[:4] != ESD:
            continue
        n = (c[10] << 8) | c[11]                # byte count of the item area
        for k in range(n // 16):
            e = c[16 + k * 16 : 32 + k * 16]
            if len(e) < 16:
                break
            yield e[:8].decode("cp037").rstrip(), e[8] & 0x0F


def walk(paths, exclude):
    for path in paths:
        if os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                dirs[:] = [d for d in dirs if d != ".git"]
                for f in sorted(files):
                    if f.endswith((".o", ".a")):
                        yield os.path.join(root, f)
        else:
            yield path


def main(argv):
    paths, exclude = [], []
    it = iter(argv[1:])
    for a in it:
        if a in ("-x", "--exclude"):
            exclude.append(next(it, ""))
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            paths.append(a)
    if not paths:
        print(__doc__, file=sys.stderr)
        return 2

    wx, er, defined, ndeck, nfile = {}, {}, set(), 0, 0
    for path in walk(paths, exclude):
        if any(x in path for x in exclude):
            continue
        nfile += 1
        try:
            for label, deck in decks(path):
                ndeck += 1
                for name, t in esd_items(deck):
                    if t == T_WX:
                        wx.setdefault(name, []).append(label)
                    elif t == T_ER:
                        er.setdefault(name, []).append(label)
                    elif t in (T_SD, T_LD, T_CM):
                        defined.add(name)
        except (OSError, UnicodeDecodeError) as e:
            print("  skipped %s: %s" % (path, e), file=sys.stderr)

    print("scanned %d deck(s) in %d file(s)" % (ndeck, nfile))
    print("weak externals (ESD type 0A): %s" % (", ".join(sorted(wx)) or "(none)"))

    at_risk = 0
    for sym in sorted(set(wx) & set(er)):
        state = "DEFINED (harmless)" if sym in defined else "UNDEFINED -- the link now fails"
        print("  %-8s WX+ER on the same name, %s" % (sym, state))
        print("      WX in: %s" % ", ".join(sorted(set(wx[sym]))[:4]))
        print("      ER in: %s" % ", ".join(sorted(set(er[sym]))[:4]))
        if sym not in defined:
            at_risk += 1
    if not set(wx) & set(er):
        print("no weak external is paired with a hard ER -- nothing at risk")
    return 1 if at_risk else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
