# Project status and integration overview

*A plain-language overview of the host-native MVS toolchain: what it does, what
it replaced, and what still touches the mainframe. Little jargon on purpose —
for the detail, follow the references at the end. Status: 2026-08.*

## In one sentence

Build mainframe programs **entirely on a PC** (macOS or Linux) and send only the
finished program to MVS — instead of uploading source and translating and binding
it there, which meant a queue of batch jobs for every change.

## The tools

| Tool | What it does |
|------|--------------|
| **cc370** | C source → mainframe assembler |
| **as370** | assembler → object file |
| **ld370** | object files → finished program, plus a transport package |
| **ar370** | object files → library (`.a`), from which ld370 pulls only what is needed |
| **file370** | looks inside any of the above and says what it is |

`cc370` is also the **driver**: `cc370 prog.c -o prog` runs the whole chain, and
it knows where the C library lives, so no include or library paths have to be
given by hand.

## What works today

**The complete path, proven on a real system.** Compile, assemble, link, package,
upload, install, run — with no IFOX00, no IEWL and no IEBCOPY involved anywhere.
This was first shown with a small test program in June 2026 and has been the
normal way of working since.

**Real programs, not just test cases.** The ecosystem projects — ufsd, ftpd,
httpd, mvsmf, httplua, httprexx, lua370, lstring370, rexx370 — are built this
way. Their C library (libc370) is archived once, and ld370 pulls exactly the
parts each program uses, the way any linker does.

**The build system uses it end to end.** Since 2026-08-13 mbt compiles,
assembles *and* links on the host: `make deploy` packs the finished programs into
a single transport file, uploads that, and has MVS unpack it. No assemble or link
job is submitted any more. Programs that do not use the standard C startup are
handled too — the build names their entry point explicitly.

**The output is checked against the originals, not just against itself.** as370's
object files are compared byte for byte against those the IBM assembler produces,
over the whole ecosystem; ld370's programs and transport files are compared
against the ones the IBM linkage editor and IEBCOPY produce. Where we differ, it
is deliberate and written down.

## What still needs MVS

**The install.** The finished program has to end up in a library on the
mainframe, so the last step is still an upload and an unpack job there. Reading
the result — did it install, does it run — happens on MVS as well.

**Nothing else.** Building, linking and packaging are host-side; the mainframe
sees one file.

## What is not done

Two kinds of open work, and they are tracked in different places.

**Defects and gaps in the tools** — every one of them is a GitHub issue, and
[`../TODO.md`](../TODO.md) ranks them and says why in that order. The short
version: as370 has a series of places where it accepts something the IBM
assembler rejects, quietly; ld370 has a few of the same shape. None of them
blocks day-to-day building, which is exactly why they need writing down.

**Tools that do not exist yet** — a symbol lister, an object dumper, host-side
library exchange — are sketched in [`tool-roadmap.md`](tool-roadmap.md). That is
a proposal, not a plan.

Two smaller limits worth knowing: symbol names are still limited to eight
characters (the archive format is already prepared for more), and the compiler is
used at `-O1` only, because higher optimisation levels are unsafe on this
backend.

## References

- [`../CLAUDE.md`](../CLAUDE.md) — the tool table, the detailed history and the
  build instructions.
- [`object-module-format.md`](object-module-format.md),
  [`load-module-format.md`](load-module-format.md) — the file formats as370 and
  ld370 produce.
- [`unload-format.md`](unload-format.md), [`xmit-format.md`](xmit-format.md),
  [`xmit-source-pds.md`](xmit-source-pds.md) — the transport formats.
- [`entry-point-resolution.md`](entry-point-resolution.md) — how a program gets
  its entry point, and how a multi-program project can get the wrong one.
- [`ld370-iewl-divergences.md`](ld370-iewl-divergences.md),
  [`../as370/docs/ifox-option-parity.md`](../as370/docs/ifox-option-parity.md) —
  where our tools differ from the IBM originals, and why.
- [`multitext-fetch-truncation.md`](multitext-fetch-truncation.md) — a solved
  blocker, kept because the lesson generalises.
