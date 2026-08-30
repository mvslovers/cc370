# Toolchain roadmap — tools beyond the four that build

*What exists, what is worth building next, and in which order. This is a
proposal, not a plan of record: nothing here is scheduled, and `TODO.md` ranks
only work that is actually open. Written 2026-08.*

## What ships today

| Tool | Role |
|------|------|
| `cc370` | C → S/370 assembler (GCC 3.4.6 fork) |
| `as370` | assembler → OS/360 object deck, byte-identical to IFOX00 |
| `ld370` | object decks → load module, `-iebcopy` / `-xmit` transport |
| `ar370` | object decks → `.a` archive with an ESD symbol index |
| `file370` | read-only inspector for every format above |

Everything below is additional, and most of it is cheap **only after the
refactor in the last section**.

---

## Phase 0 — `libobj370` and `libmvs370` first

**This is the multiplier, and it should come before any new tool.**

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

---

## Phase 1 — the tools that were actually missed while debugging

- **`objdump370 -x`** — decode ESD, RLD, control records, IDRs and the PDS
  directory of any object deck or load module. The highest debugging value of
  anything on this page: the sessions that chased dropped text and a bad entry
  point were hours of decoding those records by hand. **Split it:** `-x` (headers)
  is cheap and pays immediately; the disassembler `-d` is the expensive half —
  as370's opcode tables could be inverted for it — and can wait.
- **`nm370`** — symbol table of an object or archive, `nm`-style:
  `00000000 T main` / `U fopen`.
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

Realistic scope: the final **install** still needs MVS — the load module has to
land there via `RECEIVE` / `RECV370`. Creating and inspecting on the host is the
win.

---

## Phase 3 — module inspection

- **`loadmod370` / `modinfo370`** — entry point, aliases, CSECTs, size,
  attributes. **Build these as file370 modes, not as separate tools** (see the
  caution).
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
- **`dis370`** — a raw-binary disassembler. Fold it into `objdump370 -d` rather
  than building it twice.
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

---

## Suggested order

**Phase 0** `libobj370` / `libmvs370` (extract, validate by byte-identity) →
**Phase 1** `objdump370 -x`, `nm370`, `size370`, `strings370` →
**Phase 2** `iebcopy370`, `xmit370` →
**Phase 3** load-module inspection (preferably as file370 modes), `map370`,
`dataset370` →
**later** `dump370` + `addr2line370`, `objcopy370`, `dsect370`.

The short version: the tools with the highest value for **users** are
`iebcopy370` and `xmit370`; the highest value for **us** are `objdump370 -x` and
`nm370`; and all four are much cheaper after Phase 0 than before it.
