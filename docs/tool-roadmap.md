# Toolchain roadmap — tools beyond the four that build

*What exists, what is worth building next, and in which order. Written 2026-08;
Phase 0/1 sharpened 2026-09 after a session that hand-decoded these records one
time too many.*

**Most of this is still a proposal — but it stopped being only a proposal on
2026-09-04, and on 2026-09-06 part of it shipped.** Five items now have issues
and, more to the point, a **caller**: `mvs38src` — a local repository,
unpublished while its licensing question is open — moves MVS 3.8j source recovery
onto the host, assembling recovered source with as370 and comparing the deck
against the object the system ships. Those items are marked ▸ below and ranked in
`TODO.md`; the rest of this page is unchanged in status — nothing else here is
scheduled.

Phase 0's first half is **done** (PR #116): all five tools now share
`common/mvs370` rather than each carrying its own copy of the primitives. The
emitters — the part that actually blocks Phases 1-4 — are still ahead.

| | tool | issue |
|---|---|---|
| Phase 0 | `libobj370` / `libmvs370` | [#109](https://github.com/mvslovers/cc370/issues/109) — **the gate; the other three depend on it.** Primitives landed 2026-09-06 (PR #116); the emitters remain |
| Phase 1 | `cmplmd370` | [#110](https://github.com/mvslovers/cc370/issues/110) — new to this page, see below |
| Phase 2 | foreign IEBCOPY unloads | [#113](https://github.com/mvslovers/cc370/issues/113) — *with* libmvs370 by ownership, not behind it |
| Phase 3 | `idrdump370` | [#111](https://github.com/mvslovers/cc370/issues/111) |
| Phase 4 | `dasm370` (was `objdump370 -d` / `dis370`) | [#112](https://github.com/mvslovers/cc370/issues/112) |

Having a caller changed two judgments on this page, and both corrections are
kept in place rather than quietly edited away: the disassembler no longer "can
wait", and Phase 2's *"roughly 80 % of the code exists"* was measured against our
own formats only.

## What ships today

| Tool | Role |
|------|------|
| `cc370` | C → S/370 assembler (GCC 3.4.6 fork) |
| `as370` | assembler → OS/360 object deck, byte-identical to IFOX00 |
| `ld370` | object decks → load module, `-iebcopy` / `-xmit` transport |
| `ar370` | object decks → `.a` archive with an ESD symbol index |
| `file370` | read-only inspector for every format above |
| `xmit370` | host directory ⇄ TSO TRANSMIT of a RECFM=FB **source** PDS |
| `common/mvs370` | the shared primitives all five link against: big-endian access, CP037, the CKD count field, NETDATA framing |

`xmit370` is on this list because it is easy to forget it exists and then
duplicate it: it is a second, independent writer of the unload + XMIT container,
for source libraries rather than load libraries. `common/mvs370` is what Phase 0
grows into.

Everything below is additional, and most of it is cheap **only after the
refactor in the last section**.

---

## Phase 0 — `libobj370` and `libmvs370` first ▸ [#109](https://github.com/mvslovers/cc370/issues/109)

**This is the multiplier, and it should come before any new tool.**

The argument below was written before anything depended on it. Three of the tools
now filed — `cmplmd370`, `idrdump370`, `dasm370` — decode exactly these formats,
so the question is no longer whether the duplication is worth removing but
whether there will be three copies of it or six.

**Status: half done, 2026-09-06 (PR #116).** And the first half was not what this
page predicted. `common/mvs370` already existed — added with `xmit370` in
`51bdf5b`, describing itself as holding what was *"byte-for-byte duplicated
across ld370, ar370, file370 and as370"* — but only xmit370 ever included it.
So step one was **adoption, not extraction**: −166 lines, removing three
identical `e2a1` decoders, two sets of big-endian accessors, and ld370's complete
second NETDATA text-unit layer. The validation this page promised held exactly as
described — 743 corpus modules deck for deck, the IFOX00 and IEWL oracles green.

**What remains is the emitters, and this page should not pretend they are the
same job.** There are two, and they differ for a real reason rather than by
accident:

| | ld370 | xmit370 |
|---|---|---|
| `emit_unload` | 157 lines | 84 lines |
| `emit_xmit` | 121 lines | 104 lines |
| for | RECFM=U **load** libraries | RECFM=FB **source** libraries |
| additionally knows | `--blocksize`, the `maxtext` split, PDS2 attributes, entry point | ISPF statistics, LRECL, lines×80 |

Same container, different DCB in COPYR1/INMR02. `mvs370.h` states the rule and it
still holds: unify them *"with two proven implementations in hand rather than one
guessed abstraction."* Both are separately MVS-validated, and ld370's is the code
behind four production failures — dropped text, over-packed tracks → S106-0F,
directory overflow, SIGBUS.

**It is not optional, because the duplication already sits in the worst place.**
The 3350 geometry constants are copied verbatim between the two, *including the
ones that are the S106-0F fix*:

```
TRK_CAP_3350   19069  ld370  ·  19069  xmit370
TRK_OVH_3350     185  ld370  ·    185  xmit370
UDEBX_NMTRK       82  ld370  ·     82  xmit370
UNLOAD_TRKPERCYL  30  ld370  ·     30  xmit370
```

The next device change has to be got right twice. Order: **the constants and the
COPYR1/COPYR2 templates first** — mechanical, byte-checkable, and it removes the
dangerous copy without touching layout logic — **then #113**, whose reader forces
both shapes to be described precisely and supplies an independent third view,
**then the merge**.

The object- and load-module format logic — CESD, RLD, control records, IDRs,
PDS2 directory entries, the IEBCOPY unload geometry — sits **duplicated** across
as370, ld370 and file370 today, and every ad-hoc decode written during a
debugging session is a sixth copy that gets thrown away.

That duplication has already cost real defects. The dropped-text bug and the
over-packed-track bug were both *format logic* bugs: one subtle format
implemented in several places is several places for the same mistake. Centralise
it and there is one source of truth; every new tool below becomes a thin frontend
of 50–100 lines.

```
libobj370                        libmvs370
 ├── ESD / TXT / RLD / END        ├── PDS directory + members
 └── load module records          ├── IEBCOPY unload
                                  ├── XMIT / NETDATA
     consumers:                   └── dataset metadata, record formats
     ld370, as370, file370,
     nm370, objdump370,               consumers:
     size370, loadmod370              iebcopy370, xmit370, dataset370
```

**Order matters:** extract from the existing, battle-tested code rather than
writing the library fresh, and use as370/ld370/file370 as the validation — if
they still produce byte-identical output after the refactor, the library is
right. The byte-identity corpus and the IEWL oracles already make that a
mechanical check.

**Where byte-identity stops working:** it is the right check for a refactor that
is meant to change nothing. It says nothing about two decks that are
*semantically* the same but differ in ESDID numbering, TXT/RLD record packing or
the deck-id columns — which is what you get whenever a deck is regenerated by a
different path instead of reproduced. Answering that needs a tolerant
comparison; see Phase 1.

---

## Phase 1 — the tools that were actually missed while debugging

- **`objdump370 -x`** — decode ESD, RLD, control records, IDRs and the PDS
  directory of any object deck or load module. The highest debugging value of
  anything on this page: the sessions that chased dropped text and a bad entry
  point were hours of decoding those records by hand. **Split it:** `-x` (headers)
  is cheap and pays immediately; the disassembler `-d` is the expensive half —
  as370's opcode tables could be inverted for it.
  **This page said the expensive half "can wait". Corrected 2026-09-04: it
  cannot.** [#112](https://github.com/mvslovers/cc370/issues/112) gives it a
  caller, a specification and a round-trip acceptance gate, and it is tracked as
  `dasm370` under Phase 4 rather than as a `-d` flag here. The split itself still
  holds — `-x` first — but only the ordering was right, not the dismissal.
  **Scoped against what exists, `-x` is smaller than it looks:** `file370 -v`
  already prints the ESD dictionary, down to the `(blank) PC` line that
  identifies an unnamed private-code section. What it does not print is the RLD
  entries themselves — it reports `2 RLD card(s)` and stops — or the text as an
  address-ordered byte image. Those two are the whole remaining gap, and they
  are a flag on file370, not a new tool. The RLD listing has to resolve the
  continuation bit (`flag & 0x01` means "the next entry repeats these ESDIDs"
  and is 4 bytes rather than 8); that is precisely where an ad-hoc parser
  written mid-session gets it wrong.
- **`nm370`** — symbol table of an object or archive, `nm`-style:
  `00000000 T main` / `U fopen`.
- **`cmplmd370`** ▸ [#110](https://github.com/mvslovers/cc370/issues/110) — the
  host equivalent of Dave Kreiss' `COMPLMD`: does this object deck match that
  CSECT, byte for byte, **with a list of tolerated differences**. New to this
  page, and it belongs in Phase 1 rather than among the curiosities later: it is
  the source-recovery project's success criterion, an agent keys on its exit code,
  and on top of `libobj370` it is small. Two design points that are not
  negotiable and are easy to get wrong — **exit 0 only on identity** (never for
  "close enough"), and `--difin`/`--difout`, because PL/S `DS` gaps hold whatever
  the assembler left there and differ between two assemblies of identical source.
- **deck comparison** — `file370 --diff a.obj b.obj`: are two object decks
  *equivalent*, not are they identical. Distinct from `cmplmd370` above and worth
  keeping apart: this one sees *through* ESDID renumbering and record packing to
  ask whether two decks mean the same thing; `cmplmd370` insists on the bytes and
  takes an explicit list of what to ignore. Same text bytes by address, same
  relocation targets (flag + address), ignoring ESDID renumbering, record
  packing and the deck-id columns (bytes 72–79). See the note under Phase 0.
  This is the question that comes up whenever a deck is regenerated rather than
  reproduced — validating a codegen change, checking a round trip, deciding
  whether a third-party tool understood our output. Byte-identity cannot answer
  it and reports a false difference instead.
- **`size370`**, **`strings370`** — small, familiar, ~50 lines each on top of
  `libobj370`.

`file370 -v` already does a good part of this. Prefer **extending file370 with
modes** over building parallel tools wherever the overlap is total — see the
caution below.

---

## Phase 2 — the distinguishing feature: host-side PDS exchange

- **`iebcopy370`** — read and create IEBCOPY unload files on the host
  (`iebcopy370 extract sys1mac.unl`, `iebcopy370 create mylib.unl *.obj`).
- **`xmit370`** — create and inspect TSO TRANSMIT / NETDATA files without MVS.
  (A `xmit370` for *source* PDSs already exists in this repo; this is the general
  form over `libmvs370`.)

**This is the part nobody else offers.** Exchanging PDS libraries between
Hercules systems and modern platforms without touching MVS is a genuine
distinguishing feature, and roughly 80 % of the code exists: ld370 has
`emit_unload` and `read_iebcopy_member`, file370 decodes both formats, and the
geometry was hardened the hard way (3350 track packing, `INMSIZE` sizing,
per-member VS framing, multi-block directories). That hard-won knowledge *is* the
foundation.

**Correction (2026-09-04): that 80 % is 80 % of *our own* formats.** ▸
[#113](https://github.com/mvslovers/cc370/issues/113) — a real MVS IEBCOPY unload
of a RECFM=FB **source** library parses to zero members: file370 recognises the
container, reports `RECFM=U`, and finds no directory. Our emitters only ever
produce the RECFM=U load-library shape and the `xmit370 create` FB shape, so an
unload made by IEBCOPY itself from an FB library is a case that never had to
work. `docs/xmit-source-pds.md` already records the field-by-field delta on the
producer side; the consumer side does not know it.

The distinction is worth naming, because it is the difference between a *transport*
format and an *interchange* format: writing something MVS can read is half of it,
and reading what MVS wrote — including shapes we never emit — is the other half.
Phase 2 only delivers the distinguishing feature once both hold.

Realistic scope: the final **install** still needs MVS — the load module has to
land there via `RECEIVE` / `RECV370`. Creating and inspecting on the host is the
win.

---

## Phase 3 — module inspection

- **`loadmod370` / `modinfo370`** — entry point, aliases, CSECTs, size,
  attributes. **Build these as file370 modes, not as separate tools** (see the
  caution).
- **`idrdump370`** ▸ [#111](https://github.com/mvslovers/cc370/issues/111) — the
  same idea narrowed to the three facts that identify *which level of the source*
  a CSECT was built from: the eyecatcher, the translator IDR (`X'04'`) and the
  HMASPZAP IDR (`X'01'`). Also best as a file370 mode. The third is the one with
  no substitute — **`IMASPZAP` does not touch the eyecatcher**, so a module can
  advertise an old level and still have been modified, which is exactly the
  explanation for "the source looks right but a handful of bytes differ". Wanted
  in bulk (~5,500 modules joined against a source index), so it streams JSON
  records rather than taking one invocation per module. `docs/load-module-format.md`
  §10 already specifies the bytes; §10.5's `LASTIDR X'80'` OR'd into the *subtype*
  is the detail an ad-hoc parser misses.
- **`map370`** — a modern binder map. Related: ld370 itself has no `MAP`/`XREF`
  ([#9](https://github.com/mvslovers/cc370/issues/9)); the linker's own map is the
  more useful of the two, because it can name where each section *came from*.
- **`dsect370`** — render a DSECT as offset/name/length.

**A fact worth pinning before any of these is written:** there is **no
AMODE/RMODE in an F-level load module** (5752-SC104, MVS 3.8j) — that is a DFP
concept (5665-295). The "A24 R24" a modern ISPF shows is the editor's default
display, not something stored in the module (`docs/load-module-format.md` §13).
A tool should say *"24-bit (F-level)"* rather than suggest a stored mode.

---

## Phase 4 and later

- **`dump370`** (ABEND/SVC dump analysis: registers, storage, PSW, symbol
  resolution) and **`addr2line370`** (address → source line from cc370's line
  tables). Together these give the practical 80 % of debugging — *where did it
  crash, in which source line* — at a fraction of the cost of the alternative
  below.
- **`objcopy370`** — convert and manipulate object modules.
- **`dasm370`** ▸ [#112](https://github.com/mvslovers/cc370/issues/112) — was
  `dis370` on this page, "a raw-binary disassembler, fold it into `objdump370
  -d`". The folding advice stands; the framing was too small. What the caller
  needs is not a listing but an **alignment diff** that classifies divergences as
  insertion, deletion, displacement change or constant change — "an `LA R1,x` is
  missing here, which shifts everything after it", not "3 bytes differ at
  0x4B2". Only the first tells an agent what to edit next. The **round trip
  `dasm370 → as370 → cmplmd370` is the acceptance gate**, not an afterthought:
  run it over a corpus and the disassembler is either right or it is not.
  **Two cautions from #112, both cheap to honour and expensive to discover late.**
  The Waterloo `dasm370.c` in circulation (1985/1991) reserves all rights and
  **cannot seed a tool we intend to publish** — consult it, never copy it. The
  clean route is the one this page already proposed: invert as370's own opcode
  tables, which also makes the disassembler agree with the assembler by
  construction, which is what the round trip depends on. And output has to be
  *workable*, not merely correct: labels for branch targets, `USING`
  reconstruction, literals recognised as literals. Bare offsets assemble and
  nobody can maintain them — Dave Kreiss left six NUCLEUS modules in exactly that
  state and marked them unfinished.
- **`browse370`**, **`dataset370`** — dataset-level inspection over `libmvs370`.
- **`binder370`** — an interactive explorer for link maps and load modules.
- **`jobinfo370`** (JES2/JCL analysis), **`ipltext370`** (IPL text and nucleus),
  **`repro370`** (IDCAMS REPRO) — very niche; only if systems-software or VSAM
  work becomes concrete.

### A full debugger is the wrong shape

`gdb370` would be the single largest project on this page, and MVS has no
`ptrace` and no `exec`: debugging here is post-mortem (a dump) or via TSO TEST —
a fundamentally different model from a host debugger. `dump370` + `addr2line370`
deliver most of the value and fit the model. Recommendation: build those two
**instead of** a full debugger.

### Deliberately dropped

- **`ranlib370`** — `ar370` already builds the GNU `/`-member ESD symbol index
  while archiving. At most an `ar370 -s` alias.
- **`make370`** — GNU Make works and mbt already orchestrates. No gap to fill.
- **`c++filt370`** — cc370 is a C compiler and the ecosystem is C89/C99. Nothing
  to demangle unless C++ is concretely planned.
- **`packlib370`** — a new portable archive format would *lose* the property that
  makes the existing ones valuable: IEBCOPY unload and XMIT are already
  transportable PDS archives, and they interoperate with real systems. `.a`
  covers the host-native case.

---

## The overlap caution

`loadmod370`, `modinfo370`, a `hexdump370 --load`, `strings370` and parts of
`objdump370` all decode **the same load module** that `file370 -v` already
decodes. Without `libobj370` that becomes four or five drifting implementations
of one subtle format — precisely the bug class that produced the dropped-text and
over-packed-track defects. With it, they are all thin frontends, and the question
"separate tool or a `file370` mode?" stops mattering much.

**This stopped being hypothetical.** `idrdump370` walks the IDR chain,
`cmplmd370` reads CSECT text and RLDs, `dasm370` reads text and relocations, and
#113 needs the unload directory read a second way. That is three or four more
copies of the same decoders, all filed within one day of each other — which is
the whole argument for #109 restated by events rather than by reasoning.
(Half of it is now paid off — see the Phase 0 status — but the emitters, which is
where `cmplmd370` and `dasm370` will actually read text and RLDs, are still
ahead.)

---

## Suggested order

**Phase 0** `libobj370` / `libmvs370` (extract, validate by byte-identity) →
**Phase 1** `objdump370 -x` (as file370 flags: RLD detail, text image, `--diff`),
`nm370`, `size370`, `strings370` →
**Phase 2** `iebcopy370`, `xmit370` →
**Phase 3** load-module inspection (preferably as file370 modes), `map370`,
`dataset370` →
**later** `dump370` + `addr2line370`, `objcopy370`, `dsect370`.

The short version: the tools with the highest value for **users** are
`iebcopy370` and `xmit370`; the highest value for **us** are `objdump370 -x` and
`nm370`; and all four are much cheaper after Phase 0 than before it.

### The order the caller needs, which is not this one

The sequence above ranks by value to this repository. `mvs38src` ranks by what
unblocks its next measurement, and lands somewhere else:

**#109** → **#110** (its success criterion; nothing can be declared recovered
without it) → **#111** (the pre-filter that makes 5,500 modules tractable) →
**#112** (waits until the size of the no-source case is known). **#113 sits
outside that chain and is wanted first of all** — the macros that would lift its
assembly rate most are on a tape it cannot currently read, and reading a foreign
unload needs no extraction to happen first. It belongs *with* libmvs370 by
ownership, not behind it.

Both orders agree on the only thing that has to be agreed: **#109 comes before
the tools built on it**, and for the same reason in each — every one of them
decodes formats it would own. Where they differ, the caller's order wins for work
done *for* the caller, and `mvs38src/TODO.md` is where that sequencing is kept
current. It is deliberately not restated here; a copy of someone else's plan is
wrong the first time they learn something.
