# runtime/ — libcc370rt.a, the compiler runtime

The routines cc370 itself emits calls to, for operations it does not expand
inline — what libgcc is to gcc (#687). Every external name is an interface:
`i370.c` (`i370_init_libfuncs`) chooses it, the source here pins it with
`asm("@@…")`, and once released it does not change.

| Source | Routines |
|---|---|
| `@@bitops.c` | `@@POPCSI @@POPCDI @@PARTSI @@PARTDI @@FFSDI2 @@CLZSI2 @@CLZDI2 @@CTZSI2 @@CTZDI2` |
| `@@divdi3.c` | `@@DIVDI3 @@MODDI3 @@UDIVDI @@UMODDI` |
| `@@fixdi.c` | `@@FIXDFD @@FIXSFD @@FXUNDF @@FXUNSF` |
| `@@fltdi.c` | `@@FLTDDF @@FLTDSF` |
| `@@muldi3.c`, `@@cmpdi2.c`, `@@negdi2.c` | `@@MULDI3`, `@@CMPDI2`, `@@NEGDI2` |
| `@@trapv.c` (new) | the `-ftrapv` helpers `@@ADDVDI @@SUBVDI @@MULVDI @@MULVSI @@NEGVDI`; abort() on overflow |
| `@@ffssi2.c` (new) | `@@FFSSI2`, `__builtin_ffs` on an int |

The first seven came from libc370's `src/s370/` unchanged; their objects are
byte-identical to libc370's build. `cc370/tests/helpers.sh` checks that every
helper the compiler can emit is named as above and links.

- **Build:** `make runtime` (in-tree cc1, as370 with `../macros`, ar370) →
  `build/runtime/libcc370rt.a`. Needs the compiler, nothing from libc370.
- **Install:** `make install` → `<prefix>/cc370/lib/libcc370rt.a`, beside
  `libc.a`. The driver links `-lcc370rt -lc -lcc370rt`; mbt links
  `-lcc370rt` when that file exists (mbt#138).
- **Tests:** `make test-runtime-host` runs `tests/host/` — the C checked
  against the host's 64-bit arithmetic, which proves the arithmetic and not
  the S/370 code. `tests/mvs/` holds the target tests that came from
  libc370 (`tstdi3.c`, `tstcnvdi.c` with their tables); their build and JCL
  notes still describe libc370's tree, and nothing runs them automatically.
