#!/usr/bin/env python3
"""Build synthetic bound load-module members for the record-reader tests.

Our own bytes, not IBM's: the members below are assembled here from the layout
in docs/load-module-format.md, so the reader cases in run.sh need no corpus and
nothing proprietary is committed.  They are deliberately minimal -- a CESD, a
control record per text record, and whatever the case under test needs.

    mkmember.py overlay|trailing|sym|flagtype OUT.bin

overlay   two segments whose sections SHARE an address, which is the whole
          point of an overlay and what a single flat image gets wrong
trailing  a well-formed module with bytes after the MODEND record
sym       a SYM record ahead of the CESD, which used to end the walk at -1
flagtype  a CESD whose SD entry keeps an edit-time control bit (X'20')
truncated a member whose last record runs past the end of the image
"""
import sys


def e(s, n=8):
    return s.ljust(n)[:n].encode("cp037")


def be(v, n):
    return v.to_bytes(n, "big")


def cesd(entries, last=True):
    """entries: list of (name, typebyte, addr, seg, len). One record."""
    body = b""
    for nm, tb, addr, seg, ln in entries:
        body += e(nm) + bytes([tb]) + be(addr, 3) + bytes([seg]) + be(ln, 3)
    head = bytes([0x28 if last else 0x20]) + b"\0" * 5 + be(len(body), 2)
    return head + body


def ctl_text(addr, text, segend=False, modend=False):
    """A control record announcing one text record, plus the text record."""
    b0 = 0x01 | (0x04 if segend else 0) | (0x08 if modend else 0)
    rec = bytes([b0]) + b"\0" * 3 + be(0, 2) + be(0, 2)      # no id list, no RLD
    rec += b"\0" + be(addr, 3) + b"\0" * 2 + be(len(text), 2)   # addr +9, len +14
    assert len(rec) == 16, len(rec)
    return rec + text


def sym_record(payload, esd_images=False):
    return bytes([0x40, 0x80 if esd_images else 0x00]) + be(len(payload), 2) + payload


def deck(name, text, org=0):
    """A minimal object deck: one SD, its text, an END.  80-byte EBCDIC cards."""
    def card(kind3, body):
        c = bytearray(b"\x40" * 80)
        c[0] = 0x02
        c[1:4] = kind3
        for i, v in body:
            c[i:i + len(v)] = v
        return bytes(c)

    esd_item = e(name) + bytes([0x00]) + be(org, 3) + b"\x00" + be(len(text), 3)
    cards = [card(b"\xc5\xe2\xc4", [(10, be(16, 2)), (14, be(1, 2)), (16, esd_item)])]
    off = 0
    while off < len(text):
        chunk = text[off:off + 56]
        cards.append(card(b"\xe3\xe7\xe3",
                          [(5, be(org + off, 3)), (10, be(len(chunk), 2)),
                           (14, be(1, 2)), (16, chunk)]))
        off += len(chunk)
    cards.append(card(b"\xc5\xd5\xc4", []))
    return b"".join(cards)


def build(kind):
    if kind == "overlay":
        # Segment 1 at 0x00, segments 2 and 3 BOTH at 0x40 -- the shared
        # address that makes a flat image last-writer-wins.
        m = cesd([("ROOT", 0x00, 0x00, 1, 0x40),
                  ("SEGA", 0x00, 0x40, 2, 0x20),
                  ("SEGB", 0x00, 0x40, 3, 0x20)])
        m += ctl_text(0x00, bytes([0x11]) * 0x40, segend=True)   # ends segment 1
        m += ctl_text(0x40, bytes([0xAA]) * 0x20, segend=True)   # ends segment 2
        m += ctl_text(0x40, bytes([0xBB]) * 0x20, segend=True, modend=True)
        return m
    if kind == "trailing":
        m = cesd([("ONESECT", 0x00, 0x00, 1, 0x20)])
        m += ctl_text(0x00, bytes([0x5A]) * 0x20, segend=True, modend=True)
        return m + bytes([0xDE, 0xAD, 0xBE, 0xEF] * 7)
    if kind == "sym":
        m = sym_record(b"\x01" * 40)
        m += cesd([("WITHSYM", 0x00, 0x00, 1, 0x20)])
        m += ctl_text(0x00, bytes([0x7E]) * 0x20, segend=True, modend=True)
        return m
    if kind == "flagtype":
        # X'20' over an SD: the edit-time control bit that IEANUC01's whole
        # nucleus carries, and that a whole-byte test makes invisible.
        m = cesd([("FLAGGED", 0x20, 0x00, 1, 0x20)])
        m += ctl_text(0x00, bytes([0x3C]) * 0x20, segend=True, modend=True)
        return m
    if kind == "truncated":
        # A member whose last record claims more bytes than are there.  The
        # walk cannot finish, so the image is INCOMPLETE and a verdict drawn
        # from it would be drawn from records nobody read.
        m = cesd([("CHOPPED", 0x00, 0x00, 1, 0x20)])
        m += ctl_text(0x00, bytes([0x99]) * 0x20, segend=True, modend=True)
        return m[:-8]
    if kind.startswith("deck:"):
        _, nm, fill, ln = kind.split(":")
        return deck(nm, bytes([int(fill, 16)]) * int(ln, 0))
    raise SystemExit("unknown kind: " + kind)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    open(sys.argv[2], "wb").write(build(sys.argv[1]))
