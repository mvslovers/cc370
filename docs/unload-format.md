# IEBCOPY Unloaded-PDS Format (the host→MVS install transport)

**Producer:** `ld370 --unload` (`ld/ld370.c`, the unload emitter).
**Consumer:** IEBCOPY `COPY` with an unloaded sequential `SYSUT1` (the LOAD step),
which writes the members back into a real load library on MVS.

**Why this exists.** mvsMF cannot create RECFM=U PDS members directly, so the
host toolchain cannot upload a load module as a member. Instead `ld370` wraps
the member(s) in the byte stream an IEBCOPY *UNLOAD* would produce; that stream
uploads as an ordinary binary sequential dataset and IEBCOPY *LOADs* it into the
target load library. (A future XMIT emitter will live next to this one.)

**Authoritative sources** (MVS 3.8j, `~/repos/MVSSRC/.../Data Management Utilities (IEB)`):
`IEBLDUL` (LOAD/UNLOAD init: COPYR1/COPYR2 field equates, the fake-DEB TTR
conversion), `IEBRSAM`/`IEBWSAM` (read/write SAM), `IEBDSCPY` (copy engine).
Directory user-data layout: `IHAPDS` (PDS2). Reverse-engineered against a real
unload pair: `ld/tests/fixtures/e2e.iewl-member.bin` (the member) and
`e2e.iebcopy-unload.bin` (its IEBCOPY unload — the byte oracle).

> **This is synthesis, not a pure function of the member.** Unlike as370↔IFOX,
> a large part of an unload is *source-environment* state (volume geometry,
> device type, DEB extents) that a host tool cannot derive. We **choose** it:
> echo a known-good environment header and build only the member-derived parts.
> A green host byte-diff therefore proves the *wrapping*, not that the image
> reloads. The real oracle is **IEBCOPY LOAD + run on MVS** (Stage 2).

---

## 1. File layout

```
[ COPYR1 + COPYR2 ]            328 bytes, echoed verbatim (environment)
[ directory record ]          count12(KL=8,DL=256) + key FF*8 + 256-byte dir block
[ end-of-directory record ]   12 zero bytes (a DL=0 marker record)
  per member, per physical block, in record-number order:
    [ member-data record ]    count12(KL=0, DL=blocklen) + DATA[blocklen]
[ end-of-module record ]      count12(KL=0, DL=0)   -- one, after the last block
```

All records after COPYR2 are **CKD record images**: a 12-byte count field
optionally followed by a key and data. There is **no** RDW/BDW in the stream
(the COPYR records are raw logical records; everything else is a count+key+data
image).

## 2. The 12-byte count field

```
off len field
 0   1  F          flag byte (0)
 1   8  MBBCCHHR   M(1) BB(2) CC(2) HH(2) R(1)   -- CKD record address
 9   1  KL         key length  (8 for directory, 0 for member data)
10   2  DL         data length (big-endian)
```
`put_count()` in `ld/ld370.c` writes exactly this. Member-data records ascend by
`R` on a single track (`CC` = `UNLOAD_DATA_CC` = 0x8d, `HH` = 0); the directory
record sits at all-zero MBBCCHHR.

## 3. COPYR1 / COPYR2 (the 328-byte environment header)

Echoed verbatim (`unload_env_hdr[]`). Decoded for reference (COPYR1 content
starts at the eye-catcher's INDC byte; field equates from `IEBLDUL`):

| COPYR1 off | field | value here | meaning |
|---|---|---|---|
| 0 | INDC | 00 | flags |
| 1 | ID | `CA6D0F` | "this is an unloaded data set" eye-catcher |
| 4 | UDSORG | `0200` | PO (partitioned) |
| 6 | UBLKSIZE | 19069 | source library BLKSIZE |
| 8 | ULRECL | 0 | RECFM=U ⇒ lrecl 0 |
| 10 | URECFM | `C0` | U (undefined) |
| 11 | UKEYLEN | 0 | |
| 16 | UDEVTYPE | 20 B | source UCB device characteristics |

COPYR2 = `UDEBL16`(16) + `UDEBX`(256, the source DEB extent descriptions). On
LOAD, IEBCOPY builds a *fake DEB* from UDEBX+UDEVTYPE purely to convert the
stored relative TTRs to absolute MBBCCHHR — so the echoed geometry must be
self-consistent with the data records' `CC`. We keep both at the oracle's
values; the base cylinder is arbitrary, only the consistency matters.

## 4. Directory record

`count12(CC=0,HH=0,R=0,KL=8,DL=256)` + `KEY` = X'FF'×8 (high values) + a
256-byte PDS directory block:

```
off len
 0   2   used-byte count (includes itself, all entries, and the FF terminator entry)
 2   *   member entries, ASCENDING EBCDIC name order:
           NAME(8) TTR(3) C(1) USERDATA(2*halfwords)
 *   12  end marker: NAME = X'FF'*8, TTR=0, C=0
 *   ..  zero pad to 256
```
* **TTR** = (relative track 0, R of the member's first block).
* **C-byte** = alias(bit0) | #TTR(bits1-2) | #halfwords-of-userdata(bits3-7).
  Here `0x2c` = 1 TTR + 12 halfwords (24-byte user data).
* **USERDATA** = the PDS2 load-module attributes (`IHAPDS`): `PDS2TTRT` (TTR of
  first text block) + zero + note-list TTR + attrs + entry point + length…
  `ld370` computes `PDS2TTRT` from the block layout and **echoes** the
  remaining attribute/EP/length bytes (TODO: derive them from the member's
  CESD/control records — see `build_userdata()`).

## 5. Member-data records

The member's record stream is split into its physical blocks (the records a
loader/IEWFETCH sees — see `docs/load-module-format.md` §3) by `split_member()`:

| byte 0 | record | block length |
|---|---|---|
| `X'20'/X'28'` | CESD | `8 + count(off 6)` |
| `X'80'` | IDR | `byte1 + 1` |
| high nibble 0 | control / RLD | `16 + IDlen(off 4) + RLDlen(off 6)`; if the TXT bit `X'01'` is set, a **separate** pure-text block of length `count(off 14)` follows |

Each block becomes one member-data record: `count12(CC=0x8d, HH=0, R=next,
KL=0, DL=blocklen)` + the block bytes. A final **DL=0** record (R = last+1)
ends the member data (the on-disk end-of-file).

> The IDR length rule (`byte1 + 1`) is grounded on three samples (0xFA→251,
> 0x15→22, 0x14→21); confirm against an IDR with a different byte 1 — a real
> MVS reload settles it for free.

## 6. Status & open points

* **Stage 1 (done):** single member, byte-identical to `e2e.iebcopy-unload.bin`;
  `split_member` round-trips every linked regression member (incl. the `0x0E`
  RLD path); multi-member (`--pack`) reconstructs + name-sorts. Host checks:
  `ld/tests/run.sh` + `ld/tests/unload_check.py`.
* **Stage 2 (next):** IEBCOPY LOAD a couple of small modules on real MVS and run
  one — the only proof the image actually reloads.
* **Stage 3 (generalise):** multi-track geometry (advance `R`→`HH`→`CC`, size
  `UDEBX`) once a member/library exceeds one track; multi-block directories;
  computed PDS2 user-data. The emit loops are already laid out for N members.
