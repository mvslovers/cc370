# as370 — host-native MVS assembler (work in progress)

Part of the **c2asm370** host-assembler initiative (Notion Epic TSK-273): an
Assembler-XF (IFOX00)-compatible assembler that emits MVS object directly
(OS/360 OBJ first, GOFF later), so the C→object path no longer needs IFOX00 on
MVS. Lives in this repo (no separate binutils). Linker/pre-linker is deferred.

## Status — WP-2 (core skeleton)

First light: the two-pass core assembles the WP-1 macro-free reference
(`tests/sample1.s`) and reproduces IFOX00's TXT bytes **exactly**:

```
05C0 58F0 C00E 4110 C00A 07FE 00000000 00000000
```

Working so far:
- two passes (location counter, symbol table, high-water module length)
- formats **RR, RX, RS, SI, SS**; extended branches **BR** (→ `BCR 15,r`) and **B**
- directives **CSECT** (named=SD / unnamed=PC), **ENTRY** (LD), **USING/DROP**,
  **DC A/F/C** (EBCDIC), **DS, EQU, LTORG, END**
- operands both **explicit** (`d(x,b)`, `d(len,b)`, `d(b)`) and **symbolic via USING**
- literal pool (`=V`, `=A`, `=F`) with LTORG placement; `=V` registers an ER
- gap-aware TXT (alignment/DS gaps split TXT records, matching IFOX)
- validated byte-identical to IFOX on `tests/sample{1,3,4}.s`

Validation oracle = the IFOX00 `PRINT GEN` listing (see Epic / WP-1, TSK-274).

## Status — WP-3 (OS/360 OBJ writer)

`as370 -o deck.obj` emits an 80-col EBCDIC object deck (ESD/TXT/RLD/END). For
`sample1` the deck is **byte-identical to IFOX00's** on cards 1-3 (ESD + TXT +
RLD); the END card matches except cols 33-52 (the IDR, which legitimately
identifies the producing assembler — left blank for now).

Broadened for compiler output (`tests/sample3.s`, byte-identical to IFOX on cards
1-4): **PC** (unnamed CSECT, type 04), **LD** (`ENTRY`, type 01 + owner ESDID),
**multi-card TXT** (56-byte chunks), **RLD bit-7 continuation packing**
(consecutive same Reloc+Pos → `0D` + 4-byte cont), plus `LR` and `DC nF'v'`.
Pending: RS/SI/SS formats, EBCDIC `DC C`, then the macro processor (WP-4).

## Build & test

```sh
make          # builds ./as370 (clang/gcc, -std=gnu99)
make test     # assembles tests/sample1.s
./as370 tests/sample1.s
```

## Next (roadmap inside WP-2 → WP-3/4)

- Lift the full **i370 opcode table** from `i370-binutils` (`opcodes/i370-opc.c`,
  `include/opcode/i370.h`) — clean `{name,len,opcode,mask,flags,operands}` form;
  add the remaining formats (RS, SI, SS) and extended branches.
- Handle the **compiler-output** instruction set (Sample #2: STM/LM, MVC, B, LR,
  A, base-register prologue) — still macro-free at the core level.
- **EBCDIC** for `DC C'...'` via the compiler's CP037+NEL tables (shared, so the
  assembler is not a "second cook").
- **WP-3:** OS/360 OBJ writer (ESD/TXT/RLD/END cards) from one internal
  ESD/TXT/RLD model — incl. PC/LD symbols and RLD bit-7 continuation packing.
- **WP-4:** minimal macro processor (COPY + maclib lookup, MACRO/MEND, GBLC/SETC,
  AIF/AGO) to expand PDPTOP/PDPPRLG/PDPEPIL from `CRENT370.MACLIB`.
```
