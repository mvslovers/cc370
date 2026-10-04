# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
the project follows [Semantic Versioning](https://semver.org/) as a compiler
applies it (cc370#523):

- **MAJOR** — generated code or the ABI changes incompatibly: the calling
  convention, runtime helper names (as in libc370#190), the object or load
  module format, the `@@CRT0` interface.
- **MINOR** — additions: new options, tool features, diagnostics, helpers.
- **PATCH** — fixes that change neither what compiles nor how it links.

One version covers the whole toolchain. It comes from the `VERSION` file, and
every binary reports it with the commit it was built from:
`cc370 --version` prints `cc370 1.0.0 (<commit>), based on GCC 3.4.6`, and
each tool `<tool> 1.0.0 (<commit>)`. The GCC base is reported separately so
neither number is mistaken for the other.

## [Unreleased]

## [1.2.0] - 2026-10-04

### Added
- **A second sysroot** (#726): besides its own `cc370/{include,lib,macros}`,
  cc370 searches `cc370/libc370/{include,lib,macros}` -- headers in cc1,
  `crt0.o` and `-lc` through the driver, macros in as370 -- after the tree's
  own. A libc370 kept in its own tree can be linked in with one symlink;
  the Homebrew formula moves to that with this release, so a file a later
  libc370 adds no longer needs `brew reinstall cc370`. `make test-sysroot`
  (part of `make test-cc370`) checks all four with a stand-in libc370.
- **Homebrew** (#699): `brew trust mvslovers/tap`, then
  `brew install mvslovers/tap/cc370` from the tap `mvslovers/homebrew-tap`,
  on macOS and Linux (Homebrew 7 refuses a dependency from an untrusted
  tap); it depends on
  `mvslovers/tap/libc370` and links libc370's sysroot into its own tree.
  `release.yml` renders the formula (`packaging/homebrew/`) and pushes it to
  the tap with a deploy key held in the `release` environment (v* tags
  only); `homebrew.yml` then installs it from the tap on all four hosts. A
  file a later libc370 adds is seen after `brew reinstall cc370` until cc370
  searches a second sysroot (#726).
  With this release the formula links libc370 with one symlink, and that
  restriction is gone (#732).
- **as370: `TPROT` and `IPTE`**, in the formats IFOX00 gives them (#56,
  measured on MVSTK5-REF JOB00321): TPROT is SSE `D1(B1),D2(B2)`, IPTE the
  S-format `D2(B2)` -- not RRE.
- **as370: `S'` and `I'`** are evaluated in conditional assembly (#258); every
  value IFOX00-confirmed (JOB00320).
- **ld370: `--entry` seeds automatic library call** (#107), so the CRT can live
  inside an archive: an entry still undefined after the fixpoint is pulled by
  name.
- **New as370 diagnostics, as IFOX00 raises them:** IFO025 for an
  out-of-sequence card under ISEQ (#128), IFO043 for a macro prototype named
  after an operation (#297), IFO254 for an ill-formed second operand of END
  (#441), IFO085 for a library member without a MACRO header (#427), IFO168
  for an expression of more than 20 terms (#272), IFO211 for an S instruction
  with a second operand (#56), IFO123/IFO124 for `S'`/`I'` without a scale
  (#258).
- **ld370 warns when two explicit objects define the same entry** (#478), as
  IEWL does (IEW0241); the first definition is kept, as before.

### Changed
- **ld370 links modules neither RENT nor REUS by default** (#100) -- IEWL's
  default (a plain IEWL link lists ATTR `03F2`); until now every module was
  marked RENT+REUS unless told otherwise. That claim had consequences: httpd
  shares one copy of a RENT module between concurrent requests (measured on
  mvsdev, `CDUSE` 3), and cc370 keeps writable statics in the CSECT. Ask for
  the attributes with `--rent`, `--reus` and `--refr` -- orthogonal, so IEWL's
  RENT is `--rent --reus`; mbt v2.1.x passes them from `project.toml`
  (`rent`/`reus`/`refr`). `--norent`/`--noreus` are still accepted and now
  change nothing on their own. **Projects not yet on mbt v2.1.x get modules
  without RENT/REUS from this release**: httplua, httprexx, lua370 and nsf370
  at the time of writing. A `--pack` of a pre-built `-iebcopy` keeps that
  member's own attributes.
- **ld370 keeps the first definition of a duplicate CSECT** (#102), as IEWL
  does: the later copy is dropped with its text, space, RLDs and entries, and
  the sections after it move up (IEWL layouts JOB01409, IRXVTOC JOB01635).
  Until now the last copy won and every copy's text stayed in the module.
- **dasm370 names every section of a multi-section deck on stderr** (#439),
  and returns rc 4 when the section it took is empty while another is not.
- **xmit370: the unloaded form declares at least BLKSIZE 296** (#118), so a
  RECFM=F library with BLKSIZE 80 RECEIVEs (mvsdev JOB01343).

### Fixed
- **Nested functions** (#686): the static chain was passed in R10, which every
  prologue reloads with the page table, so a nested function read its parent's
  variables through the wrong address -- silently. It is now R0; the
  trampoline no longer clobbers R14, its label fits in 8 characters, and it is
  copied with `memcpy`. MVS JOB01338.
- **xmit370: INMR02 #2 INMRECFM is 4802** (#117), as every real transmission
  carries (RECEIVE on mvsdev JOB01316).
- **as370: the return code no longer depends on the 128-entry diagnostic
  lists** (#86); `MNOTE 0` counts among the flagged statements (#682);
  `BRXH`/`BRXLE` are undefined operation codes, as in IFOX00 (#56).
- **`make test-corpus` builds its baseline again** (#744).

## [1.1.1] - 2026-10-03

A packaging release: the prebuilt toolchains are stripped. The compiler, the
runtime and the macros are unchanged, so nothing changes for libc370 or for
what compiles and links.

### Changed
- **The release binaries are stripped** (#718): `make dist` strips the
  driver, `cc1` and the tools after installing the tree, so the release
  tarballs and packages carry no symbol tables or debug info; the Linux smoke
  test fails on an ELF binary that is not stripped. `make install` is
  unchanged and keeps them for development.

## [1.1.0] - 2026-10-03

**The compiler takes over its runtime.** The helper routines its code calls
and the prologue macros its assembler output needs now ship with cc370
instead of libc370, so cc370 assembles its own output without libc370, and
the two projects no longer have to release in lockstep when a helper changes.
libc370 2.1.0 is the matching release: it drops its copies and requires
`cc370 >= 1.1.0` (checked at compile time through `__CC370__`). From this
release cc370 is also published prebuilt for Linux and macOS.

**Upgrading:** projects built with mbt need an mbt that links `-lcc370rt`
(mbt#138) before they move to libc370 2.1. An installed libc370 2.0 keeps
working with cc370 1.1.0: the runtime is linked first and wins over its
copies.

### Added
- **Prebuilt releases** (#523): `cc370-<v>-{linux-amd64,linux-arm64,
  darwin-arm64,darwin-amd64}.tar.gz` (the Linux ones statically linked
  against musl), `.deb` and `.rpm` for both Linux arches, `install.sh`
  (cc370 plus a matching libc370 into `~/.local`) and `SHA256SUMS`, built and
  smoke-tested by `.github/workflows/package.yml` and attached by
  `release.yml`. The packages depend on `libc370-dev`/`-devel >= 2.1.0` and
  break/replace (RPM: conflict with) older ones, whose macro files cc370 now
  ships (#688). `make dist` builds the tarball for the host.
- **`libcc370rt.a`, the compiler runtime** (#687): the routines cc370 itself
  emits calls to, as libgcc is to gcc -- 64-bit multiply, divide and negate,
  float <-> long long conversions, the popcount/parity/clz/ctz/ffs builtins.
  Moved from libc370 unchanged, same external names. New in it: the
  `-ftrapv` helpers (`@@ADDVDI @@SUBVDI @@MULVDI @@MULVSI @@NEGVDI`, which
  abort on overflow) and `__ffssi2` (`@@FFSSI2`), which `__builtin_ffs(int)`
  now calls instead of libc's `ffs()`. Installed as `<sysroot>/lib/libcc370rt.a`;
  the driver links `-lcc370rt` ahead of `-lc`, so it wins over the copies
  libc370 before 2.1 still carries. mbt links it when the file exists
  (mbt#138).
- **The prologue macros ship with cc370** (#688): `PDPTOP`, `PDPPRLG` and
  `PDPEPIL`, the members every `.s` the compiler writes depends on, install
  into `<sysroot>/macros` with the compiler, so its output assembles without
  libc370. `PDPPRLG` and `PDPEPIL` no longer call the IBM macros `SAVE` and
  `RETURN`; they write out the same instructions, and no object deck moves
  (`make test-macros`). libc370 2.1 stops shipping them (libc370#313).
- **`__CC370__`, the compiler's version as a number** (#704):
  `MAJOR*10000 + MINOR*100 + PATCH`, so 1.1.0 is `10100`, with
  `__CC370_MAJOR__`, `__CC370_MINOR__` and `__CC370_PATCH__` beside it. A
  library requires a minimum compiler with
  `#if !defined(__CC370__) || __CC370__ < 10100` (libc370#315). 1.0.0 does not
  define it, so a missing macro means 1.0.0 or older.

### Fixed
- **ld370 names a missing input object** (#519, #713) instead of ending the
  link at rc 1 with no message: `ld370: cannot open PATH: <reason>`.

## [1.0.0] - 2026-10-02

The first release: the toolchain eleven ecosystem projects already build with,
given a version they can name. A libc370 release can now require
`cc370 >= 1.0.0` instead of a commit, and mbt can pin it.

### Added
- **The toolchain**, as it stands on `main`:
  - `cc370` — the driver and C → i370 HLASM compiler, a GCC 3.4.6 fork for
    MVS 3.8j (`-O1` validated, `-Os` experimental).
  - `as370` — host-native Assembler XF (IFOX00) clone: object decks and the
    `-a` SYSPRINT listing.
  - `ld370` — host-native linker (replaces IEWL) with automatic library call,
    and the `-iebcopy` / `-xmit` host-to-MVS transport.
  - `ar370` — static archives with an ESD symbol index for `ld370 -l`.
  - `file370` — inspector for every format the toolchain reads or writes.
  - `xmit370` — TSO TRANSMIT files holding a source PDS, created, listed and
    extracted on the host.
  - `dasm370`, `cmplmd370`, `idrdump370` — disassembler, load module
    comparison and IDR dump.
- **A version for the toolchain** (#523): the `VERSION` file is its one
  source, for the install paths and for what every binary reports.
  `--version` on every binary (`-v` stays on `as370` and `dasm370`, `-V` on
  `file370`, `xmit370` and `idrdump370`); the commit gains `-dirty` when the
  tree had uncommitted changes, and reads `unknown` outside a git checkout.
- `make test-version` checks that every binary reports the same version and
  the commit the tree is at.
- `cc370/tests/helpers.sh` (#685), part of `make test-cc370`: every runtime
  helper the compiler can emit is named as expected and links against the
  sysroot. The six that do not link yet (`__builtin_ffs` and the five
  `-ftrapv` helpers) are expected failures against #687.
- A release workflow: a `v*` tag builds the tools and the compiler, runs the
  suites, checks that `VERSION` matches the tag and publishes the release
  notes from this file.

### Changed
- `cc370 --version` and `cc370 -v` print the version and commit instead of
  the build date; the tools no longer print a fixed `V1.0` and the build date.
- The GCC version string reads `3.4.6 - cc370 1.0.0` (was
  `3.4.6 - cc370 version 2.0`, which no release ever carried).
