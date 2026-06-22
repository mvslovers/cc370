#!/usr/bin/env python3
"""Record-aware MVS load-module member parser, dumper and differ.

The inner-loop oracle tool for the host-native `ld`: it parses an IEWL (or
ld) load-module member record stream into typed records and compares two of
them record-by-record, so a length change in one record does not smear the
diff across everything after it.

The IDR *identity* records (LKED + translator) are a documented CARVE-OUT:
ld stamps its own identity (like as370 stamps ASM370, not IFOX's id), so those
records legitimately differ from an IEWL oracle and are skipped in the diff.
The byte-exact target is: CESD + SPZAP-IDR(zeros) + control + text + RLD.

Record stream (no on-disk delimiters; boundaries come from the format's own
length fields, exactly as program fetch walks them):
    CESD(0x20) -> SPZAP-IDR(80FA0100, 251B) -> LKED/translator IDR(0x80...)
    -> { control -> text } -> { RLD } ... last record carries EOM (byte0 & 0x08)

Usage:
    lmdiff.py dump  FILE
    lmdiff.py diff  ORACLE  CANDIDATE
"""
import sys

CTRL_TEXT = {0x01, 0x03, 0x05, 0x07, 0x0D, 0x0F}   # control byte: a text record follows
CTRL_RLD_ONLY = {0x02, 0x06, 0x0E}                 # RLD-only record (no text)


def u16(b, o):
    return (b[o] << 8) | b[o + 1]


def u24(b, o):
    return (b[o] << 16) | (b[o + 1] << 8) | b[o + 2]


def e2a(bs):
    try:
        return bs.decode("cp037")
    except Exception:
        return "".join(chr(c) if 32 <= c < 127 else "." for c in bs)


def decode_rld_flag(f):
    """Decode the RLD flag byte (TTTT LL S T) per the verified spec."""
    tttt = (f >> 4) & 0x0F
    ll = (f >> 2) & 0x03
    sign = "-" if (f & 0x02) else "+"
    same = bool(f & 0x01)
    types = {0x0: "A", 0x1: "V", 0x2: "PR", 0x3: "CXD",
             0x8: "A!unres", 0x9: "V!unres"}
    t = types.get(tttt, f"?{tttt:X}")
    length = ll + 1
    return f"{t} len={length} {sign}{' SAME-RP' if same else ''}"


def parse_rld_items(b, off, rldlen):
    items = []
    p, end = off, off + rldlen
    R = P = None
    same = False
    while p + 4 <= end:
        if not same:
            if p + 4 > end:
                break
            R, P = u16(b, p), u16(b, p + 2)
            p += 4
        if p + 4 > end:
            break
        flag, addr = b[p], u24(b, p + 1)
        p += 4
        items.append({"R": R, "P": P, "flag": flag, "addr": addr})
        same = bool(flag & 0x01)
    return items


def parse(b):
    """Parse a load-module member into a list of typed records."""
    recs = []
    n = len(b)
    p = 0

    # --- CESD ---
    if n >= 8 and b[0] == 0x20:
        cnt = u16(b, 6)
        rlen = 8 + cnt
        entries = []
        for e in range(8, 8 + cnt, 16):
            entries.append({
                "name": e2a(b[e:e + 8]).rstrip(),
                "type": b[e + 8], "addr": u24(b, e + 9),
                "segno": b[e + 12], "lenid": u24(b, e + 13),
            })
        recs.append({"kind": "CESD", "off": 0, "len": rlen,
                     "carve": False, "first_id": u16(b, 4),
                     "entries": entries})
        p = rlen

    # --- SPZAP IDR (80 FA 01 00, fixed 251B, zero zap-data) : BYTE-EXACT ---
    if p + 4 <= n and b[p] == 0x80 and b[p + 1] == 0xFA and b[p + 2] == 0x01:
        rlen = 1 + b[p + 1]            # 1 + 0xFA(250) = 251
        recs.append({"kind": "IDR-SPZAP", "off": p, "len": rlen, "carve": False})
        p += rlen

    # --- LKED + translator IDR(s): identity CARVE-OUT. Skip to the control rec. ---
    cp = p
    while cp + 16 <= n:
        if (b[cp] in CTRL_TEXT
                and b[cp + 1:cp + 4] == b"\x00\x00\x00"
                and b[cp + 8] == 0x06):
            break
        cp += 1
    if cp > p:
        recs.append({"kind": "IDR-IDENT", "off": p, "len": cp - p, "carve": True})
    p = cp

    # --- control / text / RLD records ---
    while p + 16 <= n:
        b0 = b[p]
        idlen = u16(b, p + 4)
        rldlen = u16(b, p + 6)
        if b0 in CTRL_TEXT:
            textlen = u16(b, p + 14)
            hdr = 16 + idlen + rldlen
            idlist = [(u16(b, p + 16 + i), u16(b, p + 18 + i))
                      for i in range(0, idlen, 4)]
            rld_in_ctrl = parse_rld_items(b, p + 16 + idlen, rldlen) if rldlen else []
            recs.append({"kind": "CTRL", "off": p, "len": hdr, "carve": False,
                         "b0": b0, "idlen": idlen, "rldlen": rldlen,
                         "textlen": textlen, "idlist": idlist,
                         "rld": rld_in_ctrl, "eom": bool(b0 & 0x08)})
            p += hdr
            recs.append({"kind": "TEXT", "off": p, "len": textlen, "carve": False})
            p += textlen
            if b0 & 0x08:
                break
        elif b0 in CTRL_RLD_ONLY:
            hdr = 16 + rldlen
            recs.append({"kind": "RLD", "off": p, "len": hdr, "carve": False,
                         "b0": b0, "rldlen": rldlen, "eom": bool(b0 & 0x08),
                         "items": parse_rld_items(b, p + 16, rldlen)})
            p += hdr
            if b0 & 0x08:
                break
        else:
            recs.append({"kind": "TRAILING", "off": p, "len": n - p, "carve": True})
            p = n
            break
    if p < n:
        recs.append({"kind": "TRAILING", "off": p, "len": n - p, "carve": True})
    return recs


def dump(b, label):
    print(f"### {label}: {len(b)} bytes, {len(parse(b))} records")
    for r in parse(b):
        tag = " [CARVE]" if r["carve"] else ""
        head = f"  @{r['off']:#06x} +{r['len']:<3} {r['kind']:<10}{tag}"
        if r["kind"] == "CESD":
            print(head + f" first_id={r['first_id']} entries={len(r['entries'])}")
            for e in r["entries"]:
                ty = {0: "SD", 1: "LD", 2: "ER", 4: "PC", 5: "CM",
                      6: "PR", 7: "Null", 0x0A: "WX"}.get(e["type"] & 0x0F, "?")
                print(f"        {e['name']:<8} type={e['type']:02X}({ty}) "
                      f"addr={e['addr']:06X} segno={e['segno']} "
                      f"len/id={e['lenid']:06X}")
        elif r["kind"] == "CTRL":
            print(head + f" b0={r['b0']:02X} textlen={r['textlen']} "
                  f"idlist={r['idlist']} rldlen={r['rldlen']}"
                  f"{' EOM' if r['eom'] else ''}")
        elif r["kind"] == "RLD":
            print(head + f" b0={r['b0']:02X} rldlen={r['rldlen']}"
                  f"{' EOM' if r['eom'] else ''}")
            for it in r["items"]:
                print(f"        R={it['R']} P={it['P']} "
                      f"flag={it['flag']:02X} addr={it['addr']:06X}  "
                      f"[{decode_rld_flag(it['flag'])}]")
        else:
            print(head)


def diff(a, c):
    ra, rc = parse(a), parse(c)
    print(f"### diff  oracle={len(a)}B/{len(ra)}rec  candidate={len(c)}B/{len(rc)}rec")
    # align by record kind sequence, skipping carve-outs on either side
    ia = ic = 0
    fails = 0
    nonc_a = [r for r in ra if not r["carve"]]
    nonc_c = [r for r in rc if not r["carve"]]
    if len(nonc_a) != len(nonc_c):
        print(f"  !! comparable-record count differs: {len(nonc_a)} vs {len(nonc_c)}")
        fails += 1
    for ra_r, rc_r in zip(nonc_a, nonc_c):
        if ra_r["kind"] != rc_r["kind"]:
            print(f"  !! kind mismatch: {ra_r['kind']} vs {rc_r['kind']}")
            fails += 1
            continue
        sa = a[ra_r["off"]:ra_r["off"] + ra_r["len"]]
        sc = c[rc_r["off"]:rc_r["off"] + rc_r["len"]]
        if sa == sc:
            print(f"  OK  {ra_r['kind']:<10} ({len(sa)}B)")
        else:
            fails += 1
            print(f"  !!  {ra_r['kind']:<10} DIFFERS  "
                  f"(len {len(sa)} vs {len(sc)})")
            for i in range(min(len(sa), len(sc))):
                if sa[i] != sc[i]:
                    print(f"        rec-byte {i} (abs {ra_r['off']+i:#06x}): "
                          f"{sa[i]:02X} vs {sc[i]:02X}")
    carved = [r["kind"] for r in ra if r["carve"]]
    print(f"  (carve-outs skipped: {carved})")
    print("PASS" if fails == 0 else f"FAIL ({fails} mismatching records)")
    return fails == 0


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "dump":
        dump(open(sys.argv[2], "rb").read(), sys.argv[2])
    elif len(sys.argv) >= 4 and sys.argv[1] == "diff":
        ok = diff(open(sys.argv[2], "rb").read(), open(sys.argv[3], "rb").read())
        sys.exit(0 if ok else 1)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
