# Multi-text load module truncates in program FETCH — investigation

> ## ✅ RESOLVED (2026-06-21) — it was never FETCH, never placement
>
> **Root cause:** `ld/ld370.c` `struct obj` stored the per-object text in a **fixed
> 16384-byte array** (`unsigned char text[1 << 14]`), and the OBJ TXT-card reader
> (`parse_object`) did `if (addr + cnt <= sizeof o->text) memcpy(...)` — it **silently
> dropped every TXT card past 16384 B**. Any object with >16 KB of text was truncated:
> the dropped region stayed **zeros** in `mod`, was emitted into the member, written to
> disk, and at run time the first zero halfword past the cut took **S0C1**. The cut sat
> at the last 56-byte TXT-card boundary ≤ 16384 — which is exactly the "fixed ~16384,
> record-independent" signature, to the byte:
> - run 2 (1 CSECT, cards from 0): 292 × 56 = **16352** (next card 16408 > 16384, dropped)
> - run 1 (12288 + csect2): 12288 + 73 × 56 = **16376** (next card 16432 > 16384, dropped)
>
> **Fix:** `o->text` is now a `realloc`-grown pointer (with `textcap`), zero-filling gaps
> and erroring on OOM instead of silently dropping. Builds clean under `-Wall -Wextra
> -Werror`.
>
> **Verified on real MVS:** NOPT `--t1 17000 --t2 2056` *and* `--t1 12288 --t2 12288`
> (both previously S0C1) now RECV370-install and **RUN COND CODE 0000**; `ld/tests/run.sh`
> fixture byte-identity to IEWL is **all green** (text < 16 K fills identically — no
> regression).
>
> **Why the investigation below went wrong:** §2/§4 inferred "the on-disk image is full"
> from AMBLIST and the control-record CCW count (which honestly said 17000) — but **nobody
> scanned the actual member bytes**. A one-command host-side hexscan of `ld370`'s own
> `nopt.lm` shows the 1811-fill run ends at **16352** followed by zeros: the member `ld370`
> *emits* is already truncated. The IDR-82 and off33 directory diffs were red herrings
> (both FETCH-irrelevant). Lesson: when "the image is full" is an *inference*, scan the
> bytes before theorising about the reader (IEWFETCH).
>
> **Follow-on (also fixed, 2026-06-21):** a ~60 KB module (`--t1 40000 --t2 20000`) then
> hit `U0200-13 RECV370 .RECVBLK` — again *not* a geometry limit, but ld370 emitting one
> oversized text record for a section larger than MAXTEXT (intra-section split was
> unimplemented). Fixed by splitting such a section at MAXTEXT boundaries, byte-for-byte
> the IEWL layout (oracle `ld/tests/run_iewl_bigsect.py`: 40000 → 18432/18432/3136); the
> 60 KB module installs and runs RC=0.
>
> **Real-C-program (`t1`) progress:** with the text + intra-section-split + RLD-record-split
> fixes, `t1` (`int main(){return 7;}` + crent, ~69 KB / 11 tracks) now **transports
> (RECV370 RC=0), fetches, and executes** the crent startup on MVS.
> - The **S106** that blocked fetch was ld370 emitting one oversized RLD record; program
>   fetch reads RLD records into a 256-byte buffer, so an RLD record > ~236 B overflows it
>   and fetch relocates garbage → S106-0E. Fixed by splitting RLD data into ≤236-byte
>   records like IEWL (oracle `ld/tests/run_iewl_mtrld.py`).
> - **Now blocked on a runtime `S0C4`** (not fetch): crent prints
>   `__CRTGET CRT for TCB was not found in PPA(00000000)` — `@@PPAGET` walks the TCB
>   save-area chain for the `PPAEYE` eyecatcher and returns PPA=0, so `__CRTGET` returns
>   NULL and the caller derefs it. `@@CRT0` should establish the PPA in the chain. crent
>   runs fine via mbt/IEWL, so this is specific to the ld370 link — next: link `t1`'s exact
>   objects with real IEWL and run; if RC=7, diff the entry point + the @@CRT0/@@PPAGET adcons.

**Original (incorrect) status:** open bug in `ld370`'s multi-text **placement** (NOT emission — see §4, the
member and PDS2 attributes are proven byte-correct against a real IEWL oracle). Single-text
modules (one program = one text record ≤ 18432 B) link, install, and run. The blocker below
appears only when a module is split into **two or more** control+text records — which every
real C program is (`libcrent.a` closure ≈ 58600 B / 4 text records).

Companion reference: [load-module-format.md §5 / §5.1](load-module-format.md) (text record
+ IEWL's splitting rule). Harness: [`ld/tests/run_nopt_mvs.py`](../ld/tests/run_nopt_mvs.py).

---

## 1. Symptom

A multi-text-record load module built by `ld370`, installed via `--xmit` → RECV370,
loads only the **first ≈ 0x4000 (16384) bytes**; everything past that is zeros, so the
first instruction beyond the cut takes **S0C1**. The cut is at a roughly *fixed cumulative
text offset*, independent of the text-record boundaries.

Two reproductions (`run_nopt_mvs.py`, two NOP CSECTs):

| run | record layout | observed cut | where the cut falls |
|---|---|---|---|
| original | text1 = 12288, text2 = 12288 | load+0x3FF8 = **16376** | inside text2 (12288 + 4088) |
| `--t1 17000 --t2 2056` | text1 = 17000, text2 = 2056 | load+0x3FE0 = **16352** | **inside text1** (text1 is 0…16999) |

EPA(load point) = `0x095590`, extent `0x4A70` (19056) — both correct. The second run is
decisive: the cut is **inside a single text record**, so this is not a "second text
record" problem and not track-crossing.

The ~24-byte wobble (16352 vs 16376) tracks the physical chunk layout: run 2 stops inside
block 1 (no inter-record control record crossed); run 1 stops inside block 2 (one control
record crossed). The variation is a clue to the mechanism, not noise.

---

## 2. What is proven (and how)

| fact | method | conclusion |
|---|---|---|
| Reloaded member is **logically perfect** — both control records correct (`06000000 40003000` / `06003000 40003000`), both text records full, `IEB154I … SUCCESSFULLY LOADED` | AMBLIST LISTLOAD (reads member as DATA via BSAM, executes nothing) | RECV370/IEBCOPY **reload is not the cause** |
| text1 is **one contiguous 17000-byte block on one track** (CC=141 HH=3 R=1); install library is `SYSUT2 RECFM=U BLKSIZE=19069` (> 17000) | host-side parse of `/tmp/noptrun/nopt.unl` (the IEBCOPY-unload image = the physical CKD blocks), **zero MVS cycles** | not write/unload truncation (block is full), not IEBCOPY reblock-split (17000 < 19069); the cut is **mid a single physical block** |
| `PDS21BLK` (ud[8] X'01') cleared when `ntext > 1` ([`ld370.c` build_userdata ~:522](../ld/ld370.c)) | moved the abend **12288 → 16376** | multi-block FETCH path is active; PDS2/ATR is not the bug |
| `PDS2FTBL` = first-text-block length (commit `aaaae7c7`) | moved the cap **12288 → 16384** | FETCH's first-read sizing reads from the **PDS2 directory user-data** |

Net: AMBLIST proves the on-disk image is full; the `.unl` parse proves the first text
block is physically whole. **The truncation is in program FETCH (or in the module metadata
that drives FETCH's read sizing), not in the reload or the unload geometry.**

> Caveat on AMBLIST: it follows the *logical* block chain (BSAM), so it verifies the
> reload, not the physical note-list/CCHHR path FETCH actually uses. The `.unl` parse
> closes that gap for the single-member case.

---

## 3. Hypotheses ruled out

| hypothesis | killed by |
|---|---|
| track / block crossing | text1 is one block on one track, yet cut mid-record |
| `ld370` write/unload truncation | `.unl` block is the full 17000 B |
| IEBCOPY reblock-split on reload | 17000 < install BLKSIZE 19069 |
| **"just lower `MAXTEXT` to 16384"** | 16384 is **not** an IEWL text-record size (table = 18432/13312/12288/…); IEWL's max is **18432 > 16384** and such records load fine in production (crent370/rexx370/httpd). FETCH demonstrably reads records > 16384. See [load-module-format.md §5.1](load-module-format.md) |
| PCI-appendage flag (`cr[12]=0x40` without PCI `0x08`) as the anchor | that predicts a stop at the **end** of record 1 (17000), not **mid** record 1 (16352). Do not anchor on it — it may still surface in a full diff, but it is not the lead |

Five earlier IEWFETCH (reader-side) hypotheses — track boundary, note list, re-drive,
`FIXLIMTM` page-fix window, `TXTFIX` — were each raised from static reading of
`IEWFETCH.ASM` and each refuted by the measurements. Reading the *loader* to infer what
the *writer* should produce is the approach that kept failing.

---

## 4. Oracle result (2026-06-20) — member + PDS2 are CORRECT; bug is **placement**

The oracle method was run ([`ld/tests/run_iewl_oracle.py`](../ld/tests/run_iewl_oracle.py)):
the **exact** failing `nopt.o` (t1=17000/t2=2056) was linked with **real IEWL** on MVS,
AMBLISTed, **run**, and its directory dumped with IEHLIST LISTPDS FORMAT.

**4.1 IEWL produces the SAME member as `ld370`** (AMBLIST of the IEWL module):

| | `ld370` (`nopt.lm`) | IEWL oracle |
|---|---|---|
| control 1 | CCW `06000000 40` count **17000** | `06000000 40004268` (17000) |
| text 1 | 17000 | 17000 |
| control 2 | count **2056**, MODEND | `06004268 40000808` (2056) |
| text 2 | 2056 | 2056 |
| module length | 0x4A70 (19056) | 0x4A70 (19056) |

→ **The §4-old "leading hypothesis" is REFUTED.** IEWL does **not** fill text records
byte-wise to 18432 across CSECT boundaries; for this module it writes **17000 + 2056**,
splitting on the CSECT origin change exactly like `ld370`. The member record stream
(control indicators, CCW flags `0x40`/no-PCI, lengths, MODEND) is structurally identical.
The `HEWLFINT` `TXT18K`/`TXTSIZE` table caps a record's max but does not force a fill.

**4.2 The IEWL member RUNS — COND CODE 0000** (`PGM=NOPT` from the IEWL load library).
The identical member content, placed **normally** by IEWL, fetches correctly. This
**exonerates the member**: the fault is not in what `ld370` links, but in how it gets onto
disk.

**4.3 IEWL's PDS2 directory == `ld370`'s computed PDS2 — except the TTRs** (IEHLIST):

| field | IEWL | `ld370` `build_userdata` | match |
|---|---|---|---|
| ENTRY PT | `000000` | `entry=0` | ✓ |
| ATTR (ATR1/ATR2) | **`C2F2`** | `(0xC3&~1)\|0`=C2 / `(0xF2&~0x70)\|0x10\|0x40\|0x20`=F2 = **C2F2** | ✓ |
| STOR (total) | `19056` | `19056` | ✓ |
| LEN 1ST TXT (`PDS2FTBL`) | `17000` | `17000` | ✓ |
| ORG 1ST TXT | `0` | `0` | ✓ |
| BEGIN TTR | `00 00 07` | placement-dependent | **differs** |
| 1ST TXT TTR | `00 01 01` | placement-dependent | **differs** |

ATTR `C2F2` decodes (IEHLIST attribute index) to RENT, REUS, EXEC, **MULTI-RCD**, ZERO ORG,
EP ZERO, NO RLD, EDIT, F-LEVEL — and `ld370` computes the byte-identical value.

**Conclusion:** member ✓, PDS2 attributes ✓. The **only** difference is the physical
**TTR / track placement**. IEWL packs records contiguously (`1ST TXT` at relative track 1,
record 1; small leading records share track 0); `ld370`'s unload places **one block per
track** (each record alone on its own relative track at R=1). The bug lives in the
`ld370` unload → RECV370/IEBCOPY reload → FETCH path, **not** in the linked member.

> Tension to resolve: IEWFETCH's read-text CCW is single-track `X'06'` but its read-COUNT
> CCW is multi-track `X'92'`+PCI (`IEWFETCH.ASM:2095-2098`), so FETCH *can* cross tracks
> within a cylinder — and text1 alone on its own track should still read fully (a single
> 06 read of a 17000-byte block on a 19069-byte track). So one-block-per-track for text1
> *by itself* does not obviously explain the **mid-text1** cut at 16352. The next step must
> dissect the **reloaded** `ld370` member's on-disk geometry, not assume.

---

## 5. Plan — dissect the reloaded `ld370` member (next step)

Steps 1-2 of the old oracle plan are **done** (IEWL runs RC=0; member identical). Remaining:

1. Full round-trip the failing `ld370` 17000/2056 module (RECV370 into `rcv_dsn`), then on
   the **reloaded** member run **IEHLIST LISTPDS FORMAT** + **AMBLIST** and compare to the
   IEWL oracle:
   - `1ST TXT` / `BEGIN` TTRs — does FETCH's SEARCH-ID land on the right CCHHR?
   - is text1 physically **one 17000-byte block on one track** after RECV370 reload, or did
     the reload re-place/re-block it (one-block-per-track CKD count fields carried through)?
2. If the reloaded geometry differs from IEWL's contiguous packing → the fix is in
   `emit_unload`'s one-block-per-track layout (pack contiguously like IEWL, or size FETCH's
   read correctly). If identical yet still failing → the `PDS2TTRT` / note-list path.

---

## 6. Source files cited

- `HEWLFINT.ASM:569-587` — `TXTSIZE` selection; `:978-989` — the `TXT18K` size table;
  `:581-583` — 20K threshold / 5K RLD buffer; `:630-632` — −4K for RLD buffers.
- `HEWLFINP.ASM:66` — "TXT RECORDS … MAXIMUM LENGTH IS `TXTBSIZE`".
- `HEWLFSCD.ASM:74-106` — control + text record writer (authoritative byte layout).
- `IEWFETCH.ASM` — loader (reader side; **not** the emission oracle, kept for the read path
  only). See memory `nopt-multitext-fetch-truncation` for the read-path mechanism notes.
- [`ld/ld370.c`](../ld/ld370.c) — `:1154-1181` control+text emit (whole-section packing);
  `build_userdata` ~`:504-523` (`PDS2FTBL`, `PDS21BLK`).
- [`ld/tests/run_nopt_mvs.py`](../ld/tests/run_nopt_mvs.py) — the reproduction harness
  (`--t1`/`--t2` sizes, `--amblist` mode).
