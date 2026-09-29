# A "Metal C" mode for cc370

*Research notes for [#482](https://github.com/mvslovers/cc370/issues/482):
C code that is entered by a foreign caller with a standard save area and runs
without the libc370 C runtime, in the sense of IBM XL C's `METAL` option.*

Status: **first assessment, 2026-09-28. Nothing built, nothing measured on
MVS.** Each claim below says whether it was read from source, measured on the
host (`cc370 -S`), or is still open.

---

## 1. The crux is one instruction

Every function prologue is the `PDPPRLG` macro (`libc370/maclib/pdpprlg.macro`):

```
         SAVE  (14,12)
         LA    12,0(,15)
         L     15,76(,13)        next free stack address from the CALLER's save area
         ST    13,4(,15)
         ST    15,8(,13)
         LR    13,15
         LA    15,FRAME(,15)
         ST    15,76(13)         next free address for the next call
```

The C stack is a chain of frames whose "next available byte" travels at
**+76** of each save area. A foreign caller (ISPF, an exit driver) passes an
ordinary 72-byte save area; +76 is whatever lies there, and the first C
prologue writes its save area to that address.

Everything else in the generated code is runtime-free (read from source and
from a `cc370 -O1 -S` probe, 2026-09-28):

- **Epilogue.** `PDPEPIL` (`libc370/maclib/pdpepil.macro`) is only
  `L 13,4(,13)` + `RETURN (14,12),RC=(15)`. It does not read +76.
- **Callees.** Once the first frame carries a valid +76, every further function
  runs with the ordinary `PDPPRLG`. Only *entry* functions need a different
  prologue.
- **Frame layout.** Save area 0–71, +76 the next-available address, 80–87
  scratch, arguments/locals from +88 (`STACK_FRAME_BASE`). `CINDEX`, the page
  tables (`@@PGTn`) and base registers 10/12 are per function and independent
  of any runtime.
- **Helpers pulled in.** Only 64-bit `/` and `%` (`=V(@@DIVDI3)`,
  `=V(@@UMODDI)` in the probe). A 300-byte struct copy became `MVCL`, and the
  double arithmetic stayed inline.

## 2. Compiler side (issue question 4): small

The prologue is emitted in one place, `i370_output_function_prologue`
(`cc370/gcc/config/i370/i370.c:2590`), a single `fprintf` that already
switches between `DCCPRLG` (Dignus) and `PDPPRLG`. An attribute looked up on
`current_function_decl` could select a variant, e.g.
`PDPPRLG …,ENTRY=METAL` or a separate `PDPPRLM`, with a matching epilogue
at `i370.c:3103`. Frame layout, `CINDEX` and the page tables stay untouched,
because the variant still ends with a valid R13 and +76.

What the entry variant has to do:

1. `SAVE (14,12)` into the caller's save area.
2. GETMAIN the stack. It must be **conditional**, the lesson of #108 recorded in
   `libc370/asm/@@crtm.asm:38` (the R-form abended S80A). The stack size is
   fixed per entry point, as a macro or attribute operand.
3. **GETMAIN destroys R1**, which holds the parameter list, so reload R1 from
   the caller's save area (+24) afterwards.
4. Chain the save areas (+4/+8), set +76 of the first frame, continue as usual.
5. Epilogue: hold R15 (and R0 if needed) across FREEMAIN, then
   `L 13,4(,13)` / `RETURN`.

Reentrant by construction (a fresh stack per call), 24-bit. Subpool and key
are design choices still to name.

**Parameter passing works with OS linkage as is.** cc370 passes arguments by
value in a list at R1 (`L 15,0(11)` loads `x` itself). A foreign caller passes
a list of *addresses*, so declaring the parameters as pointers
(`int IRXEXCOM(char *p1, int *p2, …)`) reads them directly. The VL bit on the
last address is ignored by 24-bit addressing, but it is visible in pointer
comparisons.

## 3. Blocker A: writable statics live in the code CSECT

Probe output:

```
GVAL     EQU   *
         DC    F'5'          int gval = 5;
...
@V1      EQU   *
         DS    XL4           static int counter;
```

Both sit inside the code CSECT. A Metal module with **any** writable static is
not reentrant, which rules it out for exits and anything shared or loaded into
LPA. #482 does not mention this constraint. A Metal mode needs at least the
rule "no writable statics", and preferably a compiler diagnostic
(an error on a non-`const` static or global definition in a Metal translation
unit).

## 4. Blocker B: the libc370 runtime is anchored per TCB

Read from source:

- `__CRTGET` (`libc370/src/clib/@@crtget.c`) walks `ppa->ppacrt[]` for an
  entry with `crttcb == PSATOLD`. If there is none, it WTOs
  `CRT for TCB(…) was not found in PPA(…)` and returns NULL.
- `__PPAGET` (`libc370/asm/@@ppaget.asm`) finds the PPA through the next
  pointer (+8) of `TCBFSAB`, the TCB's first save area, and then through the
  owner TCBs (`TCBOTC`).
- 129 `.c` files in `libc370/src/clib` mention `__crtget`, `__getcrt` or
  `errno` (a textual grep, not a call graph; §5 is the real measure): `malloc`,
  stdio, the math functions (errno), `vsnprint.c`, `strtok`, `rand`, `asctime`,
  `wto*`.

Consequence for the BREXX driver (mvslovers/brexx370#151, IRXEXCOM called by
ISPF):

- **Same TCB as a running BREXX:** a CLIBCRT exists and only the stack chain
  is missing. `malloc`/stdio might even work once the frame is built.
- **Different TCB, or an exit/SSI router with no C program at all:**
  `__CRTGET` returns NULL, and everything reaching it fails.

**Open, must be measured first:** which case IRXEXCOM under ISPF is. It depends
on whether ISPF enters BREXX by LINK (same TCB) or ATTACH (own TCB). That
decides how much of libc a Metal routine can use there.

## 5. Runtime subset (issue question 2): measure it, don't guess

Method: dump the ER symbols of every deck in `libc.a` (`file370 -v`), build the
reference graph, and take the transitive closure from the CRT roots
(`@@CRTGET`, `@@PPAGET`, `@@ERRNO`, plus the GETMAIN wrappers that read
CLIBCRT). Exported functions whose closure avoids those roots form the safe
subset. That subset decides the cut: an `-lc` subset or a separate
`libmetal.a`. `errno` would need its own home there, e.g. a static in the
Metal stack area.

Prior art to replace rather than port: `brexx370/metal/metal.{c,h}` provides
`GETSA`, `SVC`, `_xregs`, `_tput`, `_getm`/`_freem`, `_malloc`/`_realloc`/`_free`,
`_dump`, `_upper`, `_bldl`, `_load`, `_link` (plus `asm/svc.asm`,
`asm/getsa.asm`).

## 6. Services via inline asm (issue question 3)

Probe:

```c
int sv(int r1)
{
    register int r15 __asm__("15");
    register int rr1 __asm__("1") = r1;
    __asm__ volatile("SVC 99" : "=r"(r15) : "r"(rr1));
    return r15;
}
```

produced `L 1,0(11)` / `SVC 99` / `PDPEPIL`, so the input binding to R1 and
the result in R15 come out right in this trivial case.

**Not verified: clobber lists.** SVCs destroy R0/R1/R14/R15. Without a clobber
list naming them, GCC may keep live values in those registers across the asm.
That check (a function with values live across the asm, with and without
clobbers) has to come before header-only wrappers for
GETMAIN/FREEMAIN/LOAD/LINK/BLDL/WTO/TPUT.

## 7. Consumers (issue question 6)

- **In scope:** exits, SSI routers, REXX programming services such as
  IRXEXCOM. All of them are entered with a standard save area.
- **Out of scope:** SVC routines. They get no save-area linkage (R3 CVT,
  R4 TCB, R5 SVRB, R6/R7), run in key 0, and type 1/6 must not issue SVCs.
  A Metal C mode as described here does not cover them.
- Not yet counted: how many hand-written entry modules in the ecosystem would
  switch.

## 8. mbt (issue question 5)

`startup = "metal"`: link without a crt object, emit (or take from the sysroot)
the entry shim below for each module, and link against the Metal subset
instead of full `-lc`. Today's `startup = false` (`LINK_NOCRT`) still links
`-lc` and leaves the entry to hand-written assembler.

## 9. Recommendation

**Worth doing, in two steps. The compiler side is small; the work is on the
runtime side.**

1. **Smaller alternative first, with no compiler change:** an assembler entry
   shim, essentially `@@crtm.asm` minus CLIBCRT. It does SAVE, conditional
   GETMAIN of the stack, set +76, BALR to the C function, FREEMAIN with R15
   held, RETURN. Parameters are the target function name and the stack size;
   mbt can generate it for `startup = "metal"`. This shim is also the measured
   prototype #482 asks for: a C function entered with a foreign 72-byte save
   area from a tiny assembler driver, calling another C function and returning
   cleanly.
2. **Then the attribute** in the i370 backend (§2), so an entry point is one C
   file with no separate shim. It is a refinement, not a prerequisite.

In parallel: the static-data rule/diagnostic (§3), the TCB measurement (§4),
the `libc.a` closure (§5), and the clobber check (§6).

Rough effort: shim plus MVS prototype about one day. Backend attribute one to
two days. The Metal libc subset depends on the closure measurement.

## 10. Next steps (open)

- [ ] Measure LINK vs ATTACH for IRXEXCOM under ISPF (§4).
- [ ] `libc.a` ER closure from the CRT roots, giving the list of safe functions (§5).
- [ ] Inline-asm clobber check across an `SVC` (§6).
- [ ] Shim prototype + assembler driver with a foreign 72-byte save area, run on
      MVS (§9.1).
- [ ] Decide: backend attribute vs. mbt-generated shim only.
- [ ] Decide: a diagnostic for writable statics in Metal translation units (§3).
