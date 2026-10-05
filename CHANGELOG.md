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
- **as370: `COM`, `DXD`, `CXD` and Q-type constants** (#810, #229). They were
  the last Assembler XF statements and constant types it lacked: `COM` and
  `DXD` were undefined operation codes, `CXD` and `DC Q(...)` "not
  implemented".
  - `COM` opens a common section (ESD type CM): its own counter from zero, can
    be resumed, holds no text, and its symbols relocate against it.
  - `DXD` defines an external dummy section (XD) with the length and alignment
    of its operands.
  - `CXD` reserves a fullword that is not punched, with an RLD entry of type 3.
  - `Q(name)` gives an RLD entry of type 2 against the DXD or DSECT it names;
    a DSECT named this way becomes an XD. IFO231 is reported for a name not yet
    defined and IFO207 for one that is neither.
  - Decks and listings were measured on IFOX00 and are byte-identical up to the
    END card.
  - **ld370 does not handle pseudo registers yet:** they stay unresolved (#76).
    Common sections are allocated since #837.
- **as370: IFO203** (#776), severity 4, for a fixed-point or Y-type constant
  that does not fit its field: `F'2147483648'`, `H'65535'`, `FL1'128'`,
  `Y(32768)`. The signed range of the field decides, A-type is never flagged,
  and the bytes stay the low-order ones as before. Measured on IFOX00: as370
  flags the same 27 values in `as370/tests/ifo203.s` (`FE9'3'` since the
  exponent modifier, #782).

### Changed
- **`-v` is verbose and `-V` the version, in every tool** (#811). **Read this
  first:** `as370 -v` and `dasm370 -v` used to print the version and now turn
  on verbose output. Use `--version` or `-V` instead.
  - as370 `-v`: the macro search path, each macro with the file it came from,
    and the summary line even on a clean assembly, all on stderr; the deck is
    unchanged.
  - dasm370 `-v`: the section read, with its origin, length, RLD and LD entries.
    dasm370 now asks as370 for its version with `--version`.
  - ar370: a trailing `v` (`rcv`) names each member written, as GNU ar does.
  - `-V` is new in as370, dasm370 and cmplmd370, and `-h` in as370 and dasm370,
    so every tool takes `--version`/`-V` and `--help`/`-h`.
  - The cc370 driver as well: `-V` prints the version and `-h` the usage. Its
    `-v` stays GCC's verbose mode. `--version` is now the one line
    `cc370 <version> (<commit>), based on GCC 3.4.6`, without GCC's copyright
    and warranty lines. GPLv2 asks for that announcement only from a program
    that reads commands interactively; the licence is in `COPYING`.
  - The driver refuses `-b` and `-V<version>` (#833). In GCC they start another
    installed driver: `cc370 -bogus` tried to run `ogus-gcc-1.2.0`.
- **The eyecatcher in front of `main` names cc370** (#813). A program's
  `main` module carried `DC C'GCCMVS!!'`, after the compiler cc370 descends
  from; it is now `DC C'CC370',AL1(major,minor,patch)` -- in a dump
  `C3C3F3F7F0 010201` for 1.2.1 -- so a module shows which cc370 built it.
  Same 8 bytes, `@@MAIN` still at offset 8.

### Fixed
- **cmplmd370 pairs unnamed and empty sections** (#809).
  - Private code (an unnamed section) paired only when a single one was left
    over, so a module linked from several C objects compared with ITSELF was
    "not in the reference" throughout. An unnamed section now pairs by its
    first entry point and is reported under it, as `(ADDUP)`.
  - An empty section is left out of the comparison.
  - A refusal (`--csect` naming no section, an incomplete image) comes before
    anything is written to stdout; `--json` keeps its shape and `--difout`
    still carries every range.
  - The usage calls the operands NEW and REFERENCE, each an object deck or a
    load module.
- **cc370 `-mcsect` no longer opens an empty private-code section** (#809).
  `COPY PDPTOP`'s absolute EQUs ahead of the CSECT card opened one, as they do
  on IFOX00. The CSECT card now comes first and is resumed after the COPY. The
  text is unchanged.
- **ld370's bare-member warning prints the entry point in six hex digits**
  (`entry 000026`), as file370 does.
- **dasm370 details** (#809).
  - A file that is neither an object deck nor a load module is refused with
    rc 16 ("not an object deck or a load module"), where it used to be taken
    for an incomplete module, rc 2.
  - Called with no arguments, it prints the usage on stderr and ends rc 2, as
    cmplmd370 and idrdump370 do.
  - A common (CM) section is neither listed nor disassembled; `--csect` on one
    says it holds no text.
  - In a linked module, a section's first instruction was named after an entry
    point of another section that sits at module address 0 (`@@CRT0`). Labels
    now come from the section's own entries only.
  - The usage no longer lists `--reach` and `--reach-OLD`, which are refused;
    `--reach-OLD` is now an unknown option.
  - The usage and the messages carry no issue numbers or corpus statistics.
  - The man page gives the JSON schema as `dasm370-repair/3`.
- **ld370 `--pack` takes a bare member's entry point from its CESD** (#850).
  A bare load module (one not linked with `-iebcopy`) was always packed with
  entry 0, and `--entry` was ignored. That held only while `@@CRT0` came first
  in the module. Now `--pack` uses the address of `--entry NAME`, or of
  `@@CRT0`, in the member's own CESD. A name it does not find is refused with
  rc 1, and a module without `@@CRT0` keeps entry 0, warned as before. A packed
  bare member is now identical to the direct `-iebcopy` link of the same module.
- **ld370 allocates common sections** (#837). A CM section was placed at
  origin 0 of its object, on top of the object's first section, and was not
  counted in the module length, at rc 0. Now, as with IEWL, each common name
  becomes one area as long as its longest contribution. These areas follow
  every object on doubleword boundaries, carry no text, and count in the module
  length. Measured with IEWL on two objects sharing a common section of
  different lengths: CESD, control, text and RLD records are identical.
  `--xref` lists the address constants that point at a common section, as
  IEWL's cross-reference does (#845).
- **as370: COM and DXD names in address constants** (#840).
  - `A(BLK)`, `A(BLK+4)` and `=A(BLK)` on a COM section's own name got their
    value and no RLD entry at rc 0. They now relocate against the CM entry, as
    a field inside the section already did.
  - A `=Q(PR)` literal got no RLD entry; it now gets the same type-2 entry as
    `DC Q(PR)`.
  - A DXD name in an A-con is a dummy-section term, as on IFOX00: `A(PR)` is
    IFO158.
  - The ESD page of the listing printed an ER that shares its name with a
    section under the section's id.
- **as370: IFO204** (#840). A relocatable A-type constant of 1 or 2 bytes, or a
  Y-type of 1, was assembled with an RLD entry of that length at rc 0. IFOX00
  rejects it: severity 8, value 0, no RLD entry.
- **The cc370 driver** (#808):
  - An as370 warning (return code 4) no longer fails the command and deletes
    the object. 8 and above still do.
  - `-c`/`-S` with several sources and `-o` is refused. It used to run one
    cc1 over all of them and write one combined output.
  - `--target-help` prints cc1's target options with rc 0. It used to pass
    the option to as370 and ld370, which refused it, and then try a link.
  - `-flinker-output=` takes `xmit` or `iebcopy` and refuses anything else,
    on a link of objects alone as well.
  - `-print-libgcc-file-name` names `libcc370rt.a`.
  - `--help` sends bug reports to the cc370 issue tracker.
  - A reference whose 8-character external name collides with another name
    of the same unit, defined or referenced, is warned like two definitions
    already were.
  - `make test-driver` runs these checks on an installed tree.
- **as370 relocates negative and mixed-sign address terms right** (#824).
  `A(-SECT)`, `A(-EXT)` and `AL3(-EXT)` got a positive RLD entry, and
  `A(EXT-SECT)`, `A(-SECT+EXT)`, `A(SECT-EXT)` none at all, so a module
  linked from them held wrong addresses with no diagnostic. A unary minus
  now counts, and an external reference is a relocation target of its own:
  one entry per term, in its own direction, as IFOX00 writes them.
- **xmit370 checks what it used to take or cut silently** (#804). A derived
  member name longer than 8 characters was cut (`verylongname.txt` became
  `VERYLONG`); it is refused with the `--member` hint. `--member` names and
  `--userid` are upper-cased, and a userid over 8 characters is refused.
  `--recfm f` takes the record length as block size and refuses another;
  an impossible `--stats-date` is refused, not normalised; a non-numeric
  `--tabs`, `--lrecl` or `--blocksize` is refused. `list`/`extract` on a
  file that is not a transmission say so (rc 1 was silent). `--latin1` on
  a UTF-8 file warns. An option given to a command it does not belong to is
  an error, `--help`/`--version` work anywhere, and INMR03's INMRECFM is
  named -- the same decoding as file370's, which now shows FB (not F) and
  INMR01's INMNUMF.
- **ld370 refuses what it used to take silently** (#807). A file that is not
  an object deck linked at rc 0 into an empty member; it is refused with
  rc 1. An unknown option, or an option given last without its value, was
  taken as an input file; both are rc 2, and `--help`/`-h` and `-V` are new.
  A member name from `--name` or `-o` that is not a valid MVS name was
  accepted or cut (`verylongname` became `VERYLONG`); where it reaches a
  directory or the map it is refused. `--ac` above 255 (300 stored as 44)
  and a non-numeric `--blocksize` are refused. `--pack` names an XMIT, an
  archive or an object deck given as a member, refuses `--name`, and warns
  that `--sparse-text`/`--allow-unresolved` do not apply. A dropped duplicate
  CSECT is named in a note (rc unchanged, as IEWL's). The LKED IDR carries
  the toolchain's version, not V01 M00, and `-v` counts an LR as an LR.
- **file370 reads source libraries and large transmissions right** (#806).
  The directory of a source library (as `xmit370 create` writes it) was
  decoded as a load library's, its ISPF statistics shown as entry point,
  length and attributes; COPYR1's RECFM now decides, and the heading names
  it. Data of a transmission past 4 MB was cut without a word; it is kept
  whole. `--json` over several files is one JSON array (one file still one
  object), names are escaped, an object deck carries its ESD as a load
  module carries its CESD, and any other file reports its format;
  `--json` implies `--csects`. INMR03's record format is named, `-` reads
  standard input, and a text file beginning with a space or `@`..`O` is no
  longer taken for a load module.
- **ar370 no longer drops or cuts anything silently** (#805). More than 2048
  objects or 16384 symbols were dropped at rc 0; they have no limit now. A
  member name longer than 15 characters was cut to 16 bytes; it goes into a
  GNU `//` long-name member, which ld370 already reads, and a name longer
  than 63 characters is refused. Only object decks are stored -- a source
  file or an archive given as input is an error. The operation is matched
  whole (`ar370 --version x` created an empty archive `x`); `--help`/`-h`
  and `-V` are new. `t` lists member names without the trailing `/` and
  names the member behind every symbol. `rc` replaces an existing archive;
  the manual now says so.
- **as370: an open-code MNOTE substitutes its variable symbols** (#799).
  `MNOTE 1,'X=&X'` printed `X=&X`; it is now listed as written, followed by
  the generated statement `1,X=ABC` with its `+`, and the message is on that
  one -- as IFOX00 lists it. MNOTEs inside macros were never affected.
- **as370: floating-point range and modifier limits** (#783). `E'1E76'` was
  silent with a wrapped characteristic; IFOX00 says IFO201 and writes 1.0,
  because a value exponent plus modifier outside -85..75 is taken as zero
  (ifnx5f). A characteristic outside 0..127 (`E'7.3E75'`, `E'1E-80'`) is
  IFO239 and the constant all zeros; a scale or exponent modifier outside
  DCTABLE's limits is IFO200 / IFO201 and taken as zero. All severity 8,
  measured on IFOX00 (`as370/tests/dcfperr.s`).
- **as370: the scale and exponent modifiers on E, D and L** (#761). `DS2'1.5'`
  was written normalised (`41180000…`); it is `43001800…`. The fraction is
  rounded at its normalised precision, shifted right S hex digits with the
  characteristic raised by S, and the shifted-out digits are dropped;
  IFO202 (severity 8) when no bit of the fraction is left, as ifnx5f tests
  it. `En` adds to the value's exponent. Measured on IFOX00
  (`as370/tests/dcmod.s`, `as370/tests/dcscale.s`).
- **as370: the exponent modifier on F and H** (#782). `FE9'2'` assembled as
  2; it is 2E9. The value is mantissa x 10**(value exponent + modifier) x
  2**scale in exact arithmetic, rounded half away from zero, the exponent
  before the scale -- all measured on IFOX00 (`as370/tests/dcmod.s`). A value
  exponent alone (`F'1E2'`) is honoured too, on the DC and the literal path.
  `FE9'3'` now gets the IFO203 that #780 had left open.
- **as370: a macro's LCLx no longer overwrites a global** (#786). A name
  declared GBLx anywhere was global in every context, so a macro's `LCLA &M`
  wrote and reset the open code's global `&M`. IFNX5M lost 384 bytes of its
  opcode table at rc 8; it is now identical to IFOX00, and nothing else in
  the 5,528-module tree moved.
- **A fullword constant is emitted signed** (#776). The words of a floating
  constant reached the backend unsigned on a 64-bit host, so the low word of
  `1e32` came out as `DC F'3558193243'`, which IFOX00 flags IFO203 (rc 4).
  Now `DC F'-736774053'`: the same bits, so the deck does not change. Of
  libc370's 724 C sources only `strtod.c` was affected.

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
  measured against IFOX00): TPROT is SSE `D1(B1),D2(B2)`, IPTE the
  S-format `D2(B2)` -- not RRE.
- **as370: `S'` and `I'`** are evaluated in conditional assembly (#258); every
  value confirmed against IFOX00.
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
  marked RENT+REUS unless told otherwise. That claim had consequences: a
  server that loads a module once shares one copy of a RENT module between
  concurrent requests (measured on MVS: use count 3), and cc370 keeps
  writable statics in the CSECT. **A module that declares no attributes is
  now linked with neither RENT nor REUS; declare them** with `--rent`,
  `--reus` and `--refr` -- orthogonal, so IEWL's RENT is `--rent --reus`.
  `--norent`/`--noreus` are still accepted and now change nothing on their
  own. A `--pack` of a pre-built `-iebcopy` keeps that member's own
  attributes.
- **ld370 keeps the first definition of a duplicate CSECT** (#102), as IEWL
  does: the later copy is dropped with its text, space, RLDs and entries, and
  the sections after it move up, as in IEWL's layouts (measured on MVS).
  Until now the last copy won and every copy's text stayed in the module.
- **dasm370 names every section of a multi-section deck on stderr** (#439),
  and returns rc 4 when the section it took is empty while another is not.
- **xmit370: the unloaded form declares at least BLKSIZE 296** (#118), so a
  RECFM=F library with BLKSIZE 80 RECEIVEs (measured on MVS; 288 is refused).

### Fixed
- **Nested functions** (#686): the static chain was passed in R10, which every
  prologue reloads with the page table, so a nested function read its parent's
  variables through the wrong address -- silently. It is now R0; the
  trampoline no longer clobbers R14, its label fits in 8 characters, and it is
  copied with `memcpy`. Measured on MVS.
- **xmit370: INMR02 #2 INMRECFM is 4802** (#117), as every real transmission
  carries (a RECEIVE on MVS accepts it).
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

**Upgrading:** the cc370 driver links `-lcc370rt` itself; a build system that
calls ld370 directly must link `-lcc370rt` ahead of `-lc` before it moves to
libc370 2.1. An installed libc370 2.0 keeps working with cc370 1.1.0: the
runtime is linked first and wins over its copies.

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
  libc370 before 2.1 still carries. A build system that calls ld370 itself
  links it the same way, when the file exists.
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

The first release: the toolchain as it already stood, given a version a
project can name. A libc370 release can now require `cc370 >= 1.0.0` instead
of a commit, and a build system can pin it.

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
