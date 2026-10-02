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

### Added
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
