# Compiler runtime, versioning and releases — the plan

*Written 2026-10-02. A plan, not a record: the issues named here carry the
details and the measurements, and this page is updated as they close.*

## Why

cc370 and libc370 are coupled more tightly than two projects with an interface
between them should be. When `i370.c` renamed eight helper routines
(libc370#190), libc370 1.0.7 needed cc370 at `f3f7e21` or later — and since
cc370 has no versions, a libc370 release could only say so by commit hash.

The cause is that things belonging to the compiler live in the library:

- the **helper routines** the compiler emits calls to (64-bit arithmetic,
  conversions, builtins), and
- the **prologue/epilogue macros** every generated assembler file uses.

GCC ships its helpers with the compiler (libgcc), clang likewise
(compiler-rt); the C library provides only the C library. This plan does the
same for cc370, gives cc370 real versions and releases, and makes the pair
installable as prebuilt artifacts.

## The interface between cc370 and libc370

Measured on 2026-10-02 (method and data in #685): probe sources exercising
every construct that may become a library call, compiled at every
optimisation level, every external reference collected and link-tested.

| What the compiler depends on | Today | Belongs to | Issue |
|---|---|---|---|
| 22 helper routines (`@@MULDI3`, `@@DIVDI3`, `@@FIXDFD`, `@@POPCSI`, …) | libc370 `src/s370/` | **cc370** — `libcc370rt.a` | #687 |
| helpers emitted but provided nowhere (`-ftrapv`, `__builtin_ffs`) | missing — link fails | **cc370** — `libcc370rt.a` | #685, #687 |
| `COPY PDPTOP`, `PDPPRLG`, `PDPEPIL` | libc370 `maclib/` | **cc370** | #688 |
| `@@CRT0` (entry, `EXTRN` from `main`, `--entry` in the driver) | libc370 `crt0/crt1/crtm` | **libc370**, as a documented interface | libc370#159 |
| ordinary library calls (`abort` for `__builtin_trap`) | libc370 | **libc370** | — |

## Phases

### Phase 0 — safeguards, nothing moves

- **#685 — done (PR #694, `e245141`).** A regression test: every helper the
  compiler can emit must link (`cc370/tests/helpers.sh`, part of
  `make test-cc370`). The six links that fail today — `__builtin_ffs` and the five
  `-ftrapv` helpers — are XFAIL against #687.
- **#687 (first step) — done, measured:** ld370 resolves iteratively, like
  IEWL autocall, so the order of `-lc` and `-lcc370rt` does not matter for
  resolution; where a name is defined twice, the first archive in `-l` order
  wins silently (`--warn-shadow` names it). A real split of libc370's objects
  into `libc.a` and `libcc370rt.a` links. libc370 itself references none of
  the helpers outside the helper files.
- **#686** Nested functions whose address is taken do not assemble
  (`@@LTRAMP0` is 9 characters) and call `bcopy`. Independent of the rest.

### Phase 1 — versioning (#523)

**Done (PR #700, `a3ab418`); the first release, v1.0.0, is tagged from the
release commit of PR #702.** `VERSION` is the one source, every binary prints
`<tool> 1.0.0 (<commit>)` (the driver adds `based on GCC 3.4.6`), `CHANGELOG.md`
holds the notes and `release.yml` builds the compiler on `v*` tags. #523 stays
open for the artifacts of Phase 5. What follows is the plan as it was written.

cc370 had no tags and no releases, and its version names no build:
`cc370 --version` prints a date, `version.c` says 2.0, the tools a fixed V1.0.
Before the first release:

- **SemVer for a compiler:**
  - **MAJOR** — generated code or the ABI changes incompatibly: calling
    convention, helper names (as in libc370#190), object or load module
    format, the `@@CRT0` interface.
  - **MINOR** — additions: options, tool features, diagnostics, new helpers.
  - **PATCH** — fixes that change neither what compiles nor how it links.
- **One version for the whole toolchain,** from one `VERSION` file, which the
  Makefile's install paths use instead of a fixed `1.0.0`.
- **Every binary reports it with its commit** — `cc370 --version`, `as370`,
  `ld370`, `ar370`, `file370`, `xmit370`, … print `<version> (<commit>)`.
- **CI builds the compiler on tags,** not only the tools; a release has to
  prove `make compiler` works.
- **Release notes from `CHANGELOG.md`,** as libc370 does (its D6).

**Decided (#523):** the first release is **1.0.0**, with today's code, as soon
as the points above are done — from then on libc370 can name `cc370 >= 1.0.0`
instead of a commit, and mbt can pin it. The runtime move in Phase 2 is an
addition and ships as **1.1.0**; the first incompatible change to generated
code or the ABI is 2.0.0. Not 2.0.0 to match libc370: equal numbers would
suggest a bundled pair, and the two are versioned separately with a range.
`--version` reports the toolchain version and its GCC base separately, e.g.
`cc370 1.0.0 (957adbb), based on GCC 3.4.6`.

### Phase 2 — the compiler takes over its runtime

- **#687** `libcc370rt.a`: the 22 helpers move from libc370 with their tests;
  the missing `-ftrapv` helpers and a `__ffssi2` are added. The driver links it
  automatically, **before** `-lc`: resolution does not depend on the order,
  but where a name is defined twice the first archive wins, and that should be
  the compiler's own runtime. External names stay exactly as they are.
- **#688** `PDPTOP`, `PDPPRLG`, `PDPEPIL` move to cc370, installed into the
  macro directory as370 searches. Content unchanged.
- **cc370 1.1.0** carries both.
- **libc370#313** libc370 drops its copies in its next minor release and
  requires `cc370 >= 1.1.0`. No header declares either, so it is not an API change.
  In between, both archives carry identical code — harmless.
- **brexx370#292** brexx370 deletes its own copy of five helpers
  (`compat/libgcc64.c`) when it pins that cc370.

### Phase 3 — public macros for hand-written assembler

43 hand-written files use the internal prologue macros: 27 in libc370, 7 in
rexx370, 9 in nsf370. That makes every change to them a breaking change.

- **#689** A documented, stable macro set for C-callable assembler, shipped by
  cc370 — the role `EDCPRLG`/`EDCEPIL` play for Metal C and
  `CEEENTRY`/`CEETERM` for Language Environment. Initially a thin layer over
  the internal macros.
- The 43 files move to it, project by project.
- After that the internal macros are free to be reworked — they date from
  PDPCLIB — including for a later VM/CMS target. Related: #482 (Metal C).

### Phase 4 — startup (research, in libc370)

- **libc370#159** `crt0` and `crt1` differ by three lines (the `IDENTIFY` for
  `CTHREAD`); a weak external (`WXTRN`) can merge them. `crtm` needs its
  purpose settled first. Once one variant is left, the startup can move into
  `libc.a`: cc370 already emits a real reference (`EXTRN @@CRT0`), so autocall
  would find it.

### Phase 5 — prebuilt and pinned

- **cc370 binary releases** with SHA-256 (#523). The installation is already
  relocatable: cc370 finds everything relative to its own binary.

  | Platform | Channel |
  |---|---|
  | Linux amd64, arm64 | `.deb` and `.rpm` (nFPM), a statically linked tarball, `install.sh` |
  | macOS arm64, amd64 | two separate tarballs |
  | macOS and Linux | Homebrew tap: `brew install mvslovers/tap/cc370` (#699) |
  | Windows | WSL2 officially; native builds are research (#698) |

  Debian: the tree under `/usr/lib/cc370/`, symlinks in `/usr/bin/`;
  libc370 as `libc370-dev` with `Depends: cc370 (>= …)`. macOS binaries are
  not signed for now — Homebrew, `install.sh` and mbt download with curl,
  which sets no quarantine flag.
- **libc370 sysroot tarball** per release (headers, `libc.a`, `crt*.o`,
  macros), built with a named cc370 and declaring the cc370 range it needs —
  after Phase 2 that range is wide and rarely moves.
- **Consumers pin both** through mbt; mbt can build libc370 from its tag with
  the pinned cc370 as a cached fallback, and every published artifact records
  the toolchain it was built with. That half is mbt's, in its design proposal
  (mvslovers/mbt#136, section 8).

## Open

- **Where libc370 lives outside cc370's own tree** — the question three
  channels share: Homebrew installs each formula into its own keg, the
  Debian package and mbt want to replace or pin libc370 independently. All
  need cc370 to accept an explicit sysroot; until then the Homebrew formula
  carries libc370 inside cc370's keg (#699).

- Whether the GCC 3.4.6 driver supports `--sysroot`, or mbt passes
  `-nostdinc`/`-isystem`/`-L` itself; as370 needs a switch for its macro
  directory instead of `<exedir>/../macros`.
- Whether ld370 treats a weak external as specified — no autocall, resolved
  to zero when absent — before libc370#159 relies on it.
- Not covered by the inventory: `-finstrument-functions`, `--coverage`,
  `__builtin_setjmp`.
