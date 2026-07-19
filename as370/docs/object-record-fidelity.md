# Object-record fidelity — full byte-identity to IFOX00

as370 is byte-identical to IFOX00 across the entire ecosystem corpus —
**libc370 (formerly crent370) 736/736, rexx370 81/81, ufsd 20/20, httpd 105/105** plus the 9 in-repo
samples (950 modules). The comparison strips only the END card (its IDR
identifies the producing assembler) and compares every remaining card
byte-for-byte (see the corpus scripts and `as/tests/run.sh`).

Three subtle object-record issues were resolved by reading the Assembler-XF
source (Jay Moseley's binary-matched IFOX rebuild + the base source in
`mainframed/tk4`):

## 1. TXT record boundaries (`@@aopen`)

`@@aopen` has an `ADHOC DSECT` + `ORG CAMDUM+4` that rewinds the location counter
and overlays already-emitted bytes; IFOX punches two *overlapping* TXT records
(the CAMLST template, then the ORG'd code), while as370 collapsed them into one.
Per `IFNX5P` `PUNRTN`, IFOX punches TXT in **emission order** and starts a new
card whenever the next byte's address is not the running card address
(`CRDVAL != LOCATN`), the card fills (56), or the ESDID changes. as370 now logs
every pass-2 `put()` (address + bytes as written, so pre-overlay content
survives) and replays it by that rule. `emit_float` writes its fraction bytes
ascending so the log stays address-monotonic.

## 2. Open-code variable in a macro argument (`@@aopen` MACRF byte)

HLASM resolves the caller's variable symbols in a macro's arguments in the
caller's context. as370 passed the raw operand through, so
`DCB MACRF=P&OUTM.M` (open-code `GBLC &OUTM='M'`) bound `&MACRF` to the literal
`P&OUTM.M`; IHB01 char-scanned it, hit the `T` at position 5 → substitute-mode
qualifier → spurious `DCBMACRF` bit `X'04'`. as370 now resolves macro arguments
through the open-code context before binding.

## 3. ESD entry order — `=V` registration timing (`@@crtm`)

IFOX registers a `=V` literal's external-reference ESD entry when the literal
**pool is flushed** (`LTORG`/`END`), not at the source reference. as370
registered it at first use, so an `ENTRY` (LD) declared between the reference and
the flush sorted *after* the V-con ERs instead of before.

The rule is consistent across the corpus:

| module | structure | ESD order |
|--------|-----------|-----------|
| `@@crtm` | `ENTRY @@EXITA` after the `=V` refs but before `LTORG` | LD before the ERs |
| `@@@try` | `LTORG` flushes the pool before the `PDPPRLG ENTRY=YES` | ERs before the LDs |
| `@@75vect` | direct `DC V(...)` (registered at the DC) before `ENTRY` | ERs before the LD |

as370 now defers the `=V` `esd_add` to the pool flush, in first-reference order;
the symbol is still defined at `lit_get` so resolution is unaffected. A direct
`DC V(...)` is still registered at the DC statement (source order), matching IFOX.
