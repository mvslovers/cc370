# Entry-point resolution in the cc370 runtime

*Mechanics, a multi-module pitfall, and an architectural note.*

This document captures a deep-dive into how a cc370-built MVS load module
gets its entry point, why a multi-module project can link cleanly yet run the
wrong startup, and an open architectural question about the two-stage entry
design. It is written from observations on the **httpd** migration (6 load
modules over a shared autocall archive), with every claim backed by `file370`
ESD/CESD dumps and `ld370` link experiments.

*Written during the httpd migration; it is the write-up
[#10](https://github.com/mvslovers/cc370/issues/10) refers to, and the decision
between the three directions in §6 is what that issue is waiting on. Facts
re-checked against the tree on 2026-08-30: `crt0.o` / `crt1.o` / `crtm.o` are in
the sysroot, `@@start.o` is in `libc.a` at the 3120 bytes named below, and ld370
still has no link map ([#9](https://github.com/mvslovers/cc370/issues/9)).*

---

## 1. Motivation

The entry coding feels over-layered. Getting control into `main()` requires
**two** distinct resolution steps:

1. Pick a CRT object — `crt0.o` / `crt1.o` / `crtm.o` — which provides the
   load-module entry `@@CRT0`.
2. Resolve `@@START` — the C-level startup — either from libc's default or
   from a program-supplied override.

Two "startup" layers, two resolution games. The second one (`@@START`) is the
source of a genuinely nasty failure mode: a module that **links with RC=0 and
no unresolved references, but carries the wrong entry and faults at runtime**.
The question this document works toward: is the two-stage design — and
specifically the way startup is *customized* — an architectural smell?

---

## 2. The entry chain

The control path into a C program is:

```
MVS  →  @@CRT0  →  @@START  →  main()
        (crt*.o)   (startup)   (user)
```

Verified symbol facts (`file370 -v`):

| Object | defines | references (relevant) |
|--------|---------|-----------------------|
| `crt1.o` | `@@CRT0` (LD) | `@@START` **ER (strong)**, `@@STKLEN` WX (weak), `@@EXIT` ER |
| libc `@@start.o` | `@@START` | `MAIN` |
| a trivial `main()` TU | `MAIN`, `@@MAIN` | — |

So:

- **`@@CRT0`** is the load-module entry (where MVS hands control). It is
  assembler, OS-specific: save area, runtime anchor (GRT), stack. Which CRT
  object you link selects the runtime flavour (`crt0` simple, `crt1`
  threading, `crtm` minimal).
- **`@@START`** is the C-level startup: open `stdin`/`stdout`/`stderr`, parse
  the PARM/CPPL, then call `main()`. It lives in libc as the member
  `@@start.o` (3120 bytes).
- **`main()`** compiles to the symbol `MAIN` (and `@@MAIN`). A `main()` TU
  does **not** define `@@START`.

Empirical confirmation — a trivial `int main(void){return 0;}` links with
**only** `crt1.o + -lc`, RC=0: libc's `@@start.o` satisfies `crt1`'s strong
`@@START` reference and calls `MAIN`. The default startup is real and lives
in the library.

---

## 3. How the linker resolves it

Two rules govern everything below:

> **R1 — Explicit objects beat libraries.** An object named on the command
> line is included unconditionally. A library (`-l`, or an archive given by
> path) is searched only to satisfy **still-unresolved** strong references.
>
> **R2 — First definition wins, in search order.** Libraries are scanned
> left-to-right; the first member that defines a needed symbol is pulled, and
> any later definition is **never even looked at**.

This is standard OS/360 linkage-editor (IEWL) autocall behaviour; `ld370`
reproduces it.

Consequence: a program **overrides** the libc default `@@START` simply by
providing its own `@@START` as an explicit object. By R1 it resolves the
reference before any library is consulted; by R2 libc's `@@start.o` is then
never pulled. No "doubly defined" — the default just never loads. That is the
intended customization mechanism.

---

## 4. The multi-module pitfall (httpd)

httpd ships 6 load modules that share a large body of code. Two of its TUs
provide **custom** `@@START` routines:

| Object | `@@START` purpose |
|--------|-------------------|
| `httpstrt.o` | the **server** entry: HTTPD-specific DD setup (`HTTPDOUT`/`HTTPDERR`/`HTTPDIN`), console (`wtof`) diagnostics, then call `MAIN` |
| `cgistart.o` | the **CGI launcher** entry: parse CGI parms, build `argv`, call `main` |

`httpd.o` (the server body) defines `MAIN`, **not** `@@START`. So the real
server is `@@CRT0 → @@START(httpstrt) → MAIN(httpd)`.

Now the trap. Both `httpstrt.o` and `cgistart.o` define a symbol with the
**same name** `@@START`. When both sit in the project's autocall archive and
a module is seeded with an object that does *not* itself pin `@@START` (e.g.
`httpd.o`), R2 resolves `@@START` from whichever member is indexed first —
`cgistart` (alphabetical: `c` < `h`). The result:

- `@@START` *is* resolved (RC=0, no unresolved references), **but it is the
  CGI-launcher entry, not the server entry**.
- `httpstrt` and the closure it uniquely drags in are never pulled.
- The module is a valid load module that runs the wrong startup → S0C4 at
  runtime. The linker cannot warn: every `@@START` looks identical to it; it
  resolves by name, blind to "server vs CGI".

libc's generic `@@START` is *never* the culprit here — it sits behind `-lc`,
last in search order (R2), reached only if nothing earlier provides `@@START`.
The collision is always between two *real* program `@@START`s in the same (or
an earlier) library.

### Evidence

Linking the HTTPD module, varying only the explicitly-seeded object, archive
autocalled:

| seed object | RC | CESD | bytes | result |
|-------------|----|------|-------|--------|
| `httpstrt.o` (server) | 0 | 52 | 257 419 | ✅ correct |
| `httpd.o` (defines `MAIN`, not `@@START`) | 0 | **35** | **151 251** | ⚠️ `@@START` from `cgistart` → wrong entry |
| all 3 server roots | 0 | 52 | 257 411 | ✅ |
| **no** explicit seed | 0 | **35** | **151 239** | ⚠️ same wrong-entry module |

The two ⚠️ rows link clean and are missing ~17 CSECTs / ~106 KB of the
correct module.

### The fix, and a pleasant side effect

httpd's migration makes `cgistart` a per-module **root** (force-included by
each CGI module) and ships it in the public `[lib]`, while **excluding it from
the shared autocall archive**:

```toml
[internal]
sources = ["src/*.c", "credentials/src/*.c"]
exclude = ["src/cgistart.c"]
```

With `cgistart` gone from the pool, `httpstrt` is the **only** `@@START` there.
Re-running the table above, **every** seed — including `httpd.o` and "no
seed" — now produces the correct 52-CESD module: with a single `@@START` in
the pool there is no ambiguity, and R2 always resolves it to the server entry.
The duplicate-`@@START` trap is removed *structurally*, not by relying on the
caller to seed the right root.

---

## 5. The "what's actually missing" question — and a tooling gap

The wrong-entry module is 35 CESD vs the correct 52 — 17 sections, ~106 KB
short. Pinning *exactly which 17* turned out to be surprisingly hard, and the
reason is itself a finding:

- Decoding CSECT names out of the load module's CESD drowns in **string
  literals** — the larger (correct) module simply contains more text, so a
  byte-scan finds more "names" regardless of whether they are CSECTs.
- The real blocker: **`ld370` emits no link map.** IEWL had `MAP`/`XREF`
  precisely for this. Without a map, "which CSECTs ended up in this module,
  from which input, at what address/length" is guesswork.

What *is* solid: the difference is the transitive closure that the chosen
`@@START` drags in. The visible trigger sits in the `start.c` source diff
(libc default vs `httpstrt`): the server startup references `WTOF` (console),
the `@@GTOUT`/`@@GTERR`/`@@GTIN` stream setup, `LOADENV`, `TZSET`, and opens
the HTTPD-specific DDs — where the generic startup uses `*SYSPRINT` and
`printf`. The heavy server machinery (subtasks `@@AUTASK`, sockets `@@75ACCE`,
threads `@@CTPOST`) is referenced by `MAIN` (`httpd.o`) and is present
regardless; the 17-section delta is the startup closure, which an `ld370`
load map would enumerate in one line.

---

## 6. Architectural note: is the two-stage entry a smell?

**The layering itself is defensible.** Splitting an *assembler OS-bootstrap*
(`@@CRT0`) from a *C runtime-init* (`@@START`) is the standard pattern — it
mirrors Unix's `_start` → `__libc_start_main` → `main`. The CRT-object choice
(`crt0`/`crt1`/`crtm`) is just "which runtime flavour", a normal build-time
decision. Collapsing the two layers would entangle OS bootstrap with C
semantics for little gain.

**The friction is the customization mechanism, not the layering.** Startup is
customized by **redefining `@@START` under the same symbol name** and letting
it shadow the library default (Section 3). For a single program that is clean.
But it has two sharp edges:

1. **Same-symbol overriding is invisible to the linker.** Two custom
   `@@START`s (server, CGI launcher) are indistinguishable by name, so in an
   autocall context the linker silently picks one (Section 4). The mechanism
   that makes "override the default" easy is exactly what makes "two overrides
   collide" silent.

2. **It couples *which startup* to *symbol search order*** — archive member
   order, library order on the command line — rather than to an explicit
   declaration of intent.

Design directions worth weighing (not a verdict — input for the toolchain):

- **Named entry per startup.** Let a custom startup export a *distinct* symbol
  (e.g. `@@START$HTTPD`) and have the link select it via `-e` / a small
  per-module declaration, instead of every custom startup squatting on
  `@@START`. Collisions become impossible; the choice is explicit.
- **A pre-`main` hook instead of full replacement.** Keep one `@@START` (the
  library's) that, before calling `main`, calls an *optional weak* init hook
  (`__premain()` or similar) that a program may define. Custom startup work
  (DD setup, parm parsing) moves into the hook; nobody redefines `@@START`, so
  the duplicate-symbol class disappears entirely. This is the most invasive
  but the cleanest: it turns "replace the entry" into "extend the entry".
- **At minimum, diagnose the collision.** A linker warning when an autocalled
  strong symbol is multiply defined across the searched libraries would have
  surfaced the httpd trap at link time instead of as a runtime S0C4. (Tracked
  as cc370#8.)

---

## 7. Summary

- `@@CRT0 → @@START → main()` is a sound two-stage bootstrap; `@@START` has a
  real default in libc (`@@start.o`).
- Linking resolves the entry by **R1** (explicit beats library) and **R2**
  (first definition wins in search order). The library default never
  "conflicts" — it is last and only used as a fallback.
- The hazard is **two real `@@START`s competing in the autocall pool**: the
  link succeeds with the wrong entry, failing only at runtime. httpd removed
  it structurally by keeping the CGI launcher out of the shared archive.
- The architectural irritation is real but localized: not the two layers, but
  the **same-symbol override** mechanism for startup customization. Named
  entries or a pre-`main` hook would remove the whole failure class.
- Two concrete tooling gaps surfaced: a **multiply-defined-autocall-symbol
  warning** (cc370#8) and an **`ld370` load map** (`MAP`/`XREF` equivalent)
  that would have answered Section 5 in one command.
