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

## [1.0.0] - unreleased

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
- A release workflow: a `v*` tag builds the tools and the compiler, runs the
  suites, checks that `VERSION` matches the tag and publishes the release
  notes from this file.

### Changed
- `cc370 --version` and `cc370 -v` print the version and commit instead of
  the build date; the tools no longer print a fixed `V1.0` and the build date.
- The GCC version string reads `3.4.6 - cc370 1.0.0` (was
  `3.4.6 - cc370 version 2.0`, which no release ever carried).
