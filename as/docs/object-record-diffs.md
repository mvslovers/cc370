# The last object-record diff (CRENT 735/736)

as370 is byte-identical to IFOX00 across the ecosystem corpus —
**crent370 735/736, rexx370 81/81, ufsd 20/20, httpd 105/105** plus the 9 in-repo
samples. One crent370 module, `@@crtm`, is not byte-equal: it differs only in the
**order of ESD entries** (same ESD/TXT/RLD content), which a link-edit normalises
away. So every module is functionally correct; `@@crtm` differs only in on-deck
record order.

Comparison strips the END card (its IDR identifies the producing assembler) and
compares every remaining card byte-for-byte (see the corpus scripts and
`as/tests/run.sh`).

## Fixed: `@@aopen` (was the TXT-framing + a MACRF diff)

`@@aopen` is now byte-identical. Two distinct bugs, both found by reading the
Assembler-XF source (Jay Moseley's binary-matched IFOX rebuild + the base source
in `mainframed/tk4`):

1. **TXT record boundaries.** `@@aopen` has an `ADHOC DSECT` + `ORG CAMDUM+4`
   that rewinds the location counter and overlays already-emitted bytes; IFOX
   punches two *overlapping* TXT records (the CAMLST template, then the ORG'd
   code), as370 collapsed them into one. Per `IFNX5P` `PUNRTN`, IFOX punches TXT
   in **emission order** and starts a new card whenever the next byte's address
   is not the running card address (`CRDVAL != LOCATN`), the card fills (56) or
   the ESDID changes. as370 now logs every pass-2 `put()` (address + bytes as
   written, so pre-overlay content survives) and replays it by that rule.
2. **DCB MACRF byte** (`X'0054'` vs `X'0050'`). as370 did not substitute the
   caller's variable symbols in a macro's *arguments*: `DCB MACRF=P&OUTM.M`
   (open-code `GBLC &OUTM='M'`) bound `&MACRF` to the literal `P&OUTM.M`; IHB01
   char-scanned it and hit the `T` at position 5 → substitute-mode qualifier →
   spurious `X'04'`. as370 now resolves macro arguments through the open-code
   context before binding.

## Open: `@@crtm` — ESD entry ordering

`@@crtm`'s ESD content is identical; only the **order** differs:

```
IFOX:   PC, @@CRT0(LD), @@STKLEN(WX), @@EXITA(LD), @@CRTGET(ER), @@START(ER), @@EXIT(ER)
as370:  PC, @@CRT0(LD), @@STKLEN(WX), @@CRTGET(ER), @@START(ER), @@EXIT(ER), @@EXITA(LD)
```

i.e. the LD `@@EXITA` (an `ENTRY`) sorts *before* the V-con ERs. But the corpus
norm is the opposite — `@@@try`/`@@75vect` put their LDs *after* the ERs. A
static "explicit-before-implicit" reorder fixes `@@crtm` but breaks those
opposite-case modules (16 regressions).

Reading the Assembler-XF source (`xdict.asm`) shows why: XDICT assigns each ESD
entry an **ascension slot** (`HIESDNR`, separate from the ESDID counter
`HICESDID`), and `ENTRY`→LD processing is **two-phase** — it *primes* a slot
(`ETYPELX`) in the initial pass and finalises it (`ETYPELD`) in a later pass,
while V-con ERs are assigned their slots in a different pass. The LD-vs-ER order
is therefore an artifact of IFOX's multi-pass slot-ascension, reproducible only
by modelling those passes — not by a single reorder rule. Parked; `@@crtm` is
functionally identical after link-edit.
