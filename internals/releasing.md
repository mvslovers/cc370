# Releasing cc370 — versions, and what libc370 needs

cc370 and [libc370](https://github.com/mvslovers/libc370) are versioned
separately; each states the range of the other it works with. This file is
cc370's side. libc370 keeps the same sections in its own
[`doc/releasing.md`](https://github.com/mvslovers/libc370/blob/main/doc/releasing.md):
*Who owns what*, *Who needs which version* and *The rule* are word for word
the same in both files; each project writes its own release checklist.

## Who owns what

| cc370 | libc370 |
|---|---|
| `libcc370rt.a` — every helper the compiler emits (`@@MULDI3` … `@@FFSSI2`, the `-ftrapv` helpers) | headers, `libc.a`, `crt0.o` / `crt1.o` / `crtm.o` |
| the prologue macros `PDPTOP`, `PDPPRLG`, `PDPEPIL` (`<sysroot>/macros`) | every other macro: `maclib/` and the vendored `sysmac/` |
| `__CC370__` = MAJOR·10000 + MINOR·100 + PATCH (a `-dev` suffix is dropped) | the check of it in every header (`<sys/_cc370.h>`) |
| the link line: `-lcc370rt -lc -lcc370rt`, `--entry @@CRT0`, no startfile (since 1.4.0); for `main` the compiler emits `EXTRN @@CRT0` | the startup `@@CRT0`, a member of `libc.a` since 2.3.0 (libc370#159); `crt0.o` stays as a copy until libc370's cc370 minimum is 1.4.0 |

## Who needs which version (2026-10-03)

| | needs | enforced by |
|---|---|---|
| libc370 2.1.x | cc370 >= 1.1.0, < 2 | `#error` in every header (`__CC370__ < 10100`), `.deb` Depends / `.rpm` Requires, `metadata.json` — all derived from libc370's `sdk/cc370.json` |
| cc370 1.4.x | libc370 >= 2.3.0 | the packages: `LIBC_MIN` 2.3.0 -- the link no longer names `crt0.o`, and an older `libc.a` has no `@@CRT0` member (libc370#159) |
| cc370 1.1.x - 1.3.x | libc370 >= 2.1.0 | the packages only: `Depends: libc370-dev (>= 2.1.0)`, `Breaks`/`Replaces: libc370-dev (<< 2.1.0)` (RPM: `Requires`/`Conflicts` on `libc370-devel`), because libc370 2.0 still shipped the three macro files |
| cc370 1.0.0 | libc370 <= 2.0.x | the old arrangement: helpers and macros still in libc370 |
| projects built with mbt | both, pinned | `[toolchain]` in `project.toml` |

## The rule

A release waits for the other project only when it needs a *higher* minimum
of it — and then the one it needs is released first.

## Releasing cc370

1. **A normal release** — fixes, options, diagnostics: nothing to do in
   libc370.
2. **The compiler emits a new helper:** the helper goes into `runtime/src/`
   in the same release, with a case in `cc370/tests/helpers.sh`. That test
   catches a helper that is renamed or vanishes for the constructs it lists;
   a new construct needs its own case.
3. **An incompatible change** — a renamed helper, the calling convention or
   the prologue macros' expansion, the `@@CRT0` interface, the object or load
   module format — is **cc370 2.0.0**. libc370 is then rebuilt and released
   with a range `>= 2.0, < 3`, and prebuilt archives built with 1.x no longer
   fit. Changing what `PDPPRLG`/`PDPEPIL` generate also touches hand-written
   assembler in libc370, rexx370 and nsf370 (#688, #689).
4. **The packages' libc370 minimum** (`LIBC_MIN` in `packaging/nfpm.sh`)
   rises only when cc370 itself needs a newer libc370.
5. **The release:**
   - a release PR sets `VERSION` to the plain number and dates the
     `CHANGELOG.md` section;
   - tag `v<version>` on its merge commit — **only after the coordinating
     mbt session's go** (the maintainer's delegation, 2026-10-03);
   - `release.yml` requires `VERSION` == tag, builds the compiler, runs the
     suites and `test-version-cc370`, and attaches the tarballs, `.deb` /
     `.rpm`, `install.sh` and `SHA256SUMS` (`package.yml`);
   - check the release afterwards — the assets and, from a clean prefix,
     `install.sh`;
   - then set `VERSION` to the next `-dev`, so `main` reports a version
     ahead of the last tag (`__CC370__` follows it).

## Releasing libc370

libc370 releases against a *released* cc370 at the minimum its
`sdk/cc370.json` names, and raises that minimum only after the cc370 it
needs is out — see its
[`doc/releasing.md`](https://github.com/mvslovers/libc370/blob/main/doc/releasing.md#releasing-libc370).
