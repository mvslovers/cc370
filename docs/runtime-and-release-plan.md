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

- **#685** A regression test: every helper the compiler can emit must link.
  Red today for `__builtin_ffs` and `-ftrapv`, on purpose.
- **#687 (first step)** Check that ld370 resolves `-lc -lcc370rt` in that
  order: `libc.a` members use `long long` themselves and will reference the
  helpers once they live in the runtime library.
- **#686** Nested functions whose address is taken do not assemble
  (`@@LTRAMP0` is 9 characters) and call `bcopy`. Independent of the rest.

### Phase 1 — versioning (#523)

cc370 has no tags and no releases, and its version names no build:
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

The first release number is settled in #523; the issues use **v1.1.0** as a
placeholder.

### Phase 2 — the compiler takes over its runtime

- **#687** `libcc370rt.a`: the 22 helpers move from libc370 with their tests;
  the missing `-ftrapv` helpers and a `__ffssi2` are added. The driver links it
  automatically after `-lc`. External names stay exactly as they are.
- **#688** `PDPTOP`, `PDPPRLG`, `PDPEPIL` move to cc370, installed into the
  macro directory as370 searches. Content unchanged.
- **#523** First release, carrying both.
- **libc370#313** libc370 drops its copies in its next minor release and
  requires that cc370. No header declares either, so it is not an API change.
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

- **cc370 binary releases** per host (linux/darwin × amd64/arm64) with
  SHA-256 (#523). The installation is already relocatable: cc370 finds
  everything relative to its own binary.
- **libc370 sysroot tarball** per release (headers, `libc.a`, `crt*.o`,
  macros), built with a named cc370 and declaring the cc370 range it needs —
  after Phase 2 that range is wide and rarely moves.
- **Consumers pin both** through mbt; mbt can build libc370 from its tag with
  the pinned cc370 as a cached fallback, and every published artifact records
  the toolchain it was built with. That half is mbt's, in its design proposal
  (mvslovers/mbt#136, section 8).

## Open

- Whether the GCC 3.4.6 driver supports `--sysroot`, or mbt passes
  `-nostdinc`/`-isystem`/`-L` itself; as370 needs a switch for its macro
  directory instead of `<exedir>/../macros`.
- Whether ld370 treats a weak external as specified — no autocall, resolved
  to zero when absent — before libc370#159 relies on it.
- Not covered by the inventory: `-finstrument-functions`, `--coverage`,
  `__builtin_setjmp`.
