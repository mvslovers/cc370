# XMIT of a Source PDS (the host→MVS distribution transport)

**Producer:** `xmit370 create` (`xmit370/src/xmit370.c`).
**Consumer on MVS:** `RECV370` (`PGM=RECV370`), the same batch unpacker the
load-module path uses.

This is the RECFM=FB sibling of `docs/xmit-format.md`. The container is the
same pair of nested formats — an IEBCOPY unloaded PDS wrapped in TSO
TRANSMIT/NETDATA — so read `docs/unload-format.md` and `docs/xmit-format.md`
first. This document records only what a **source** library does differently
from the **load** library `ld370` emits, and how each of those differences was
measured rather than guessed.

---

## 1. The oracle

Everything below was read off a real TSO TRANSMIT of a source PDS:

```
~/Downloads/mvs-tk5/ctca_demo/sysgen/ctca_demo.xmi
  -> JUERGEN.CTCA.PDS,  PO / RECFM=FB / LRECL=80 / BLKSIZE=19040
     7 members, 3380 geometry, transmitted 2016-05-31
```

It ships with the Hercules TK5 CTCA demo. `xmit370/tests/run.sh` checks against
it and **skips itself** when the file is absent (override the path with
`XMIT370_ORACLE`), the way `test-corpus` skips without a libc370 checkout.

A second reference is the **XMIT370/RECV370 source itself** — CBT tape file 571
by Jim Morrison, unpacked at `~/repos/mvs/cbt571/PDS/`. `DXCOPYR1` is the
authoritative COPYR1 DSECT; `RECVRCPY` and `RECVCTL` show what RECV370 actually
does with the fields; `JRECVPDS` is the install JCL.

> **Licence.** CBT571 is under the **Q Public License**, which is
> GPL-incompatible. It is read here as a *format specification only*: no code is
> taken from it and the sources are **not** committed to this repository. This is
> the same arrangement the project uses for the IFOX00 and IEBCOPY references.

---

## 2. What differs from a load library

| Field | Load library (`ld370`) | **Source library (`xmit370`)** | How known |
|---|---|---|---|
| COPYR1 length | 52 | 52 | `DXCOPYR1` `L$XC138`; oracle agrees |
| `XC1DSORG` (off 4) | `0200` PO | `0200` PO | unchanged |
| `XC1BLKSZ` (off 6) | library BLKSIZE | library BLKSIZE | unchanged |
| `XC1LRECL` (off 8) | 0 | **LRECL** (80) | measured |
| `XC1RECFM` (off 10) | `C0` (U) | **`90`** (F+B) | measured |
| `XC1KEYLN` (off 11) | 0 | 0 | unchanged |
| `XC1TBLKS` (off 14) | BLKSIZE+20 | **BLKSIZE+20** | measured — same formula |
| Directory C byte | `2C` (1 TTR, 12 halfwords) | **`0F`** (0 TTR, 15 halfwords) | measured |
| Directory user data | PDS2 load-module fields | **30-byte ISPF statistics** | measured |
| Entries per block | 7 | **6** (2 + 6×42 = 254) | falls out of the entry size |
| Member data | load-module record images | **FB blocks**, last one short | measured |
| INMR02 #1 | `LRECL=0, DSORG=PO, RECFM=U` | `LRECL=n, DSORG=PO, RECFM=FB` | measured |

Unchanged: COPYR2, the device characteristics, the DEB extent handling, the
directory record framing, the per-member `DL=0` end-of-member record, INMR02 #2
(INMCOPY / PS / VS / BLKSIZE+20), INMR03 and INMR06.

**Why the DCB fields matter here and not there.** `docs/xmit-format.md` notes
that RECV370 pre-allocates `SYSUT2` from the JCL DCB and ignores `INMBLKSZ`.
That is true of the *load-library* path, where the JCL supplies
`DCB=(RECFM=U,BLKSIZE=15040)`. The CBT571 sample `JRECVPDS` allocates a source
PDS **with no DCB at all**, so RECV370 fills the attributes in from COPYR1 /
INMR02 — which makes these computed fields load-bearing, and testable.

---

## 3. ISPF statistics (30 bytes)

Decoded from the oracle; `$README` and `CTCASOS` cross-check every field.

```
off len field                       oracle value
 0   1  version                     01
 1   1  modification level          00  (CTCASOS: 09)
 2   1  flags                       00
 3   1  seconds                     00      packed
 4   4  creation date               0116149F   = 2016 day 149 = 2016-05-28
 8   4  last modification date      0116149F
12   2  last modification time      2215       packed hhmm
14   2  current lines               0032 = 50  binary, not packed
16   2  initial lines               0032 = 50
18   2  modified lines              0000
20   8  userid, EBCDIC              'JUERGEN '
28   2  filler                      4040       (EBCDIC blanks)
```

The date is `0cyydddF`: a leading zero nibble, one century digit (0 = 19xx,
1 = 20xx), two year digits, three day-of-year digits, sign `F`. Verified
against the file's own modification date — the oracle's 2016-149 is 2016-05-28,
and 2016 is a leap year.

Line counts are **binary**, not packed decimal: `CTCASOS` carries `0A80` = 2688,
which is not a valid BCD value. They are clamped to 65535.

`xmit370` writes version 01, modification level 00, zero modified lines, and
takes the dates from the file's mtime unless `--stats-date` pins them.

---

## 4. Blocking and geometry

Records are packed `BLKSIZE / LRECL` to a block; the last block of a member is
**short, not padded** (measured: the oracle's 50-line `$README` is one 4000-byte
block against a 19040-byte BLKSIZE).

The CKD placement is `ld370`'s, unchanged — contiguous packing costed in real
3350 track bytes (`185 + data` per record against a 19254-byte track). That
model is what survived program FETCH on MVS; costing by BLKSIZE instead
over-packs tracks with many small records into a physically impossible layout,
which is the `S106-0F` bug class. A source library has *many more, smaller*
blocks than a load library, so the density matters here more, not less —
`xmit370/tests/xmit_check.py` asserts it over the emitted image, and the suite
exercises it at `--blocksize 800`.

The largest permitted block is **19069** = 19254 − 185, which is exactly the
`UMBLK` the 3350 device table in COPYR1 carries.

**`--blocksize` default 3120.** Since RECV370 creates the target from COPYR1 on
the DCB-less path, `--blocksize` decides what the library is allocated as. 3120
(39 × 80) is to a source library what 15040 is to a LINKLIB: it fits anywhere.

---

## 5. NETDATA framing

Member data goes into logical records that always **end at each member's `DL=0`
end-of-member record** — the rule whose violation loses every member packed
behind an earlier one on reload (`IEB183I`).

The ceiling on a logical record is **32764 bytes**, not `ld370`'s 18432:
`RECVRCPY` GETMAINs a fixed 32 KiB buffer (`L R0,=A(32*1024)`, *"max QSAM
blocksize"*) and reserves its first four bytes for an RDW. ld370's 18432 is the
IEWL `TXTSIZE` ceiling for load-module *text records* — a different constraint
that does not apply here.

**One deliberate divergence from the oracle.** A real TSO TRANSMIT bundles all
directory blocks and the end-of-directory marker into a *single* logical record
(measured: 564 bytes = 2 × 276 + 12). `ld370` emits one logical record per
directory block, and that is the variant that has been through RECV370 on real
MVS, so `xmit370` emits it too. Whether the bundled form also works is worth
one MVS experiment; if it does, the per-block framing can go.

---

## 6. Text conversion

The record boundary **is** the line break, so no line-terminator byte is ever
written. In particular the ecosystem's `\n` → NEL `0x15` mapping is *not*
applied: a stray `\r` surviving as `0x0D` in a source card would be a real
hazard, and there is nothing for a terminator to do inside a fixed-length
record.

Per line, in order: strip a trailing `\r`; expand tabs (column position is
load-bearing in assembler and JCL); strip trailing blanks; verify the width
against LRECL; translate with the CP037 table shared with `cc370`/`as370`; pad
to LRECL with `0x40`.

Everything that cannot be represented is an error with `file:line:column` — a
line over LRECL, a control character, a byte outside ASCII. Two of those are
worth distinguishing, and `xmit370` does:

* the file is **well-formed UTF-8** → an editor wrote multi-byte characters that
  have no EBCDIC equivalent; the fix belongs in the file.
* the file is **not** valid UTF-8 → the high bytes are single-byte Latin-1,
  which CP037 covers exactly; `--latin1` maps them losslessly. This is the case
  for text that came *out* of an EBCDIC dataset.

Several ecosystem samplib files (`httpd/samplib/httpprm0`,
`ufsd/samplib/ufsdprm0`, `ufsd/samplib/ufsdclnp`, `nsf370/samplib/NSFPRM0`)
currently contain UTF-8 em dashes and arrows in comments and are refused. That
is correct behaviour; those files want cleaning.

---

## 7. Status

* **Host-validated.** `list` decodes the real TSO TRANSMIT oracle exactly —
  DCB, directory split, every member's ISPF statistics, and every member's byte
  count equal to lines × 80. A 217-member corpus (`~/repos/mvs/cbt571/PDS`,
  37 directory blocks, names with `$ @ #`) round-trips **byte-identically**
  through `create` → `extract`, and `create` is byte-reproducible across runs
  with `--stats-date`.
* **Validated end-to-end on real MVS (2026-08-13).** The `ufsd`, `ftpd` and
  `httpd` samplibs were built on the host, uploaded as FB80 and received into
  three new libraries. The target was allocated **without a DCB**, so every
  attribute came from the transmission:

  ```
  RECEIVE INDSN('IBMUSER.XMIT.IN') DATASET('IBMUSER.UFSD.SAMPLIB') VOLUME('WORK00')
    -> NJE38 RECEIVE v2.3.0, RC=0
       IEB154I  UFSD     HAS BEEN SUCCESSFULLY  LOADED     (x4, x2, x2)
       IEB147I  END OF JOB -00 WAS HIGHEST SEVERITY CODE
  ```

  The catalog then shows `DSORG=PO RECFM=FB LRECL=80 BLKSZ=3120` — the
  `--blocksize` default carried through COPYR1 off 6 and `INMR02#1 INMBLKSZ`
  into the real allocation. Reading every member back gives content identical to
  the source, blank lines included (`ufsdprm0`: 20 lines with 6 blank, 20 back).
  `IEHLIST LISTPDS` confirms the ISPF statistics reached the directory: each
  entry carries its own line count (`190019` = 25, `100010` = 16, `140014` = 20,
  `590059` = 89) and the userid. Note that `LISTPDS FORMAT` labels its columns
  with load-module field names, which do not apply to a source library — read
  the hex, not the headings.

  This went through **TSO/NJE38 `RECEIVE`, not `RECV370`**, which is the
  stricter of the two: `RECEIVE` allocates the target from `INMR02` itself,
  whereas `RECV370` with a DCB in the JCL would never look at those fields.
* **Not implemented:** sequential (PS) datasets, binary members from a
  directory, and more than one dataset per file (`INMNUMF > 1`).
