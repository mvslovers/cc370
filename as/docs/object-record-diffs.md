# The last two object-record diffs (CRENT 734/736)

as370 is byte-identical to IFOX00 across the whole ecosystem corpus —
**crent370 734/736, rexx370 81/81, ufsd 20/20, httpd 105/105** (949 modules)
plus the 9 in-repo samples. Exactly **two** crent370 modules are not byte-equal,
and **both are object-record _layout_, not code generation**: every byte of the
emitted CODE, DATA and RLD content is correct — only the *framing* (TXT record
boundaries) or *ordering* (ESD entries) of the object deck differs, and a
link-edit normalises both away. So all 736 crent modules are functionally
correct; these two differ only in how the cards are cut.

Comparison method: `tools` strip the END card (its IDR legitimately identifies
the producing assembler) and compare every remaining card byte-for-byte. See
the corpus scripts and `as/tests/run.sh`.

---

## 1. `@@aopen` — TXT record boundaries

- **Content identical**: 2244 TXT bytes == 2244 TXT bytes.
- **Framing differs**: as370 emits **43** TXT cards, IFOX **44** (`myT={ESD:1,
  TXT:43}` vs `refT={ESD:1, TXT:44}`).

`@@aopen` contains an `ADHOC DSECT` followed by `ORG CAMDUM+4`, which rewinds the
location counter back over already-emitted bytes. IFOX therefore emits **two
overlapping TXT records** — the CAMLST template first, then the `ORG`'d code
written over the same addresses — whereas as370 walks its `defn[]` (defined-byte)
map by **address** and emits one merged run for that address range.

**Why it is not "just fixed":** a pure assembly-order TXT recorder (track each
`put()` for contiguity, snapshot a record when the run breaks) *does* fix
`@@aopen`, but it **over-splits ~30 other modules + REXX** (734 → 705). The cause
is the literal pool: literals are emitted in creation/alignment order, not
address order, so address-contiguous ranges get written non-sequentially and an
assembly-order recorder shatters them into many small cards. IFOX emits TXT
**primarily by address** (merged runs) and starts a separate overlapping record
**only** on a true `ORG` origin-reset. That exact split rule lives in the IFOX
**OUTPUT phase (X51)**, which is not available (see below).

---

## 2. `@@crtm` — ESD entry ordering

- **Content identical**: `myT={ESD:3, TXT:6, RLD:1}` == `refT={ESD:3, TXT:6,
  RLD:1}`. Same ESD entries, same TXT, same RLD — only the **order** of the ESD
  entries differs.

IFOX's `@@crtm` ESD order is:

```
PC, @@CRT0(LD@18), @@STKLEN(WX@26), @@EXITA(LD@98), @@CRTGET(ER,=V@54), @@START(ER), @@EXIT(ER)
```

i.e. the LD `@@EXITA` — an `ENTRY` declared at source line 98 — sorts **before**
the V-con ERs that are first referenced at lines 54/86/94.

But the **corpus norm is the opposite**: LDs come **after** the ERs. e.g.
`@@@try` → `PC, @@CRTGET(ER), @@ESTAE(ER), @@@TRY(LD), @@@TRYRC(LD)`, and
`@@75vect` → `PC, <13 ERs>, @@75VECT(LD)`. That LD-after-ER order is exactly
as370's `esd_add` call order — already correct for the other 735 modules.

No observable property (address, declaration line, first-reference order)
distinguishes `@@crtm`'s `@@EXITA` from the LDs in `@@@try`/`@@75vect`. Both
candidate rules tried — (a) `[sections + explicitly-declared]` then `[implicit
ERs]`, and (b) pull an LD that follows the first implicit ER forward — **fix
`@@crtm` but break ~14 modules + REXX `tstvpol`**.

**ASMG cross-check** (`moshix/ASMG`, the U-of-Waterloo Assembler G = a modified
IBM Assembler **F**/IEUASM): its ESD-output phase (`ASMGFI`) writes the external
symbol table in a single pass in **table order** (built by `ASMGF7E` in
declaration order: `ENTRY`→LDCON, `EXTRN`/VCON→ERCON), i.e. **LD after the V-con
ERs — like as370, not like IFOX's `@@crtm`**. So `@@crtm`'s ordering is
**XF-specific**; the F-lineage does not reproduce it. Cracking it needs IFOX's
actual symbol-table→ESD emission code.

---

## Where the missing algorithms live

Both rules live in the IFOX00 **compute phases**:

| Phase | Role |
|-------|------|
| X11 | EDIT |
| X31 | GEN |
| **X41** | SYMBOL RESOLUTION (→ ESD ordering) |
| **X51** | OUTPUT (→ TXT record boundaries) |
| X61 | RLD |

`github.com/moshix/IFOX` contains only the **driver + I/O framework**
(IFOX0A driver, 0B workfile IO, 0C common, 0D init, 0E/0F input, 0G/0H output
IO/punch, 0I error, 0J options) — **not** X11/X31/X41/X51/X61. The phases are
also not on deepwiki, not in moshix's other repos, and not reproduced by ASMG
(F-lineage). `MTS_Assemblers` is a user guide, not a PLM.

**Until the X41/X51 phase source surfaces, these two layout diffs stay open.**
They are cosmetic at the deck level and vanish after link-edit, so they do not
block using as370 as the ecosystem's object producer.
