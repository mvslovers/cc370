# Does IEWL ship sparse text? — measured, 2026-09-22

## Question

The cobc370 patch changes `ASM_OUTPUT_SKIP` under `TARGET_PDPMAC` from
`DC nX'00'` to `DS XLn`, and teaches ld370 to drop any text record whose bytes
are all zero. Its rationale, from the comment it adds to `i370.h`:

> program fetch reads sparse text into freshly obtained (zeroed) storage,
> exactly as IEWL-linked assembler DS behaves.

That is a claim about IEWL, and it is measurable without touching the C
question. Three findings below; none of them decides whether fetch-target
storage is zero, which remains open and needs its own measurement on MVS.

## Instrument

`zprobe.c`, built against `common/src/obj370.c` — the repo's own record walker,
already exercised across this corpus. For each member it pairs every control
record carrying `LMOD_CTL_TEXT` with the text record it announces, taking the
load address from the CCW (bytes 9-11) and the count from bytes 14-15, merges
the covered intervals, and compares them with the module extent from the CESD
(max `addr+len` over SD/PC/CM).

Calibrated on `BLSFLD00`, whose answer is known independently: `file370 -v`
reports one 1536-byte text record and the CESD extent is 0x538+0xC8 = 1536. The
probe reports extent 1536, one record, 1536 bytes, no gap.

Population: 5,252 bound members, the 34 `SYS1.AOS*` distribution libraries off
MVS/CE, all of them IEWL output.

    excluded, incomplete image        0
    excluded, scatter / overlay      22
    analysed                      5,230

## A — IEWL does not elide all-zero text records

    all-zero text records                    33, in 31 members
    bytes in them                         7,384
    record sizes            8,8,8,8,16,16,16,24,32,32,32,40,40,48,48,56,56,
                            64,64,128,144,160,160,176,184,392,936,1024,1024
    members whose entire text is all-zero     8

Hand-verified: `ISTPATCH` is a 64-byte CSECT that is nothing but a reserved
zeroed patch area. Its member carries one control record (`0D`, MODEND, count
0x0040, CCW address 0) followed by a 64-byte text record of zeros. IEWL had
every opportunity to drop it and wrote it out.

This finding stands on its own and has no confound: ld370's elision diverges
from IEWL rather than converging on it.

## B — a DS reservation in a shipped module carries non-zero content

From cmplmd370's existing tree run (3,888 modules / 4,140 sections), restricted
to sections whose verdict is `holes` — as370 reproduced **every byte it wrote**,
and the only differences are at offsets no TXT card covered:

    sections                                    296  (in 295 modules)
    non-zero bytes inside DS reservations     12,326
    clusters                                   1,723   mean 7.2 B, largest 218
    cluster lengths 1-3 B                        994   (58%)

The shape is what excludes the remaining confound. An omitted TXT card would
appear as one contiguous run of hundreds or thousands of bytes; 1,723 scattered
runs averaging 7 bytes is binder buffer residue.

So wherever a module is built the IFOX00 → IEWL way, a `DS` used as BSS is not
"zero because fetch zeroes it". It is **deterministically non-zero**, because
the linker wrote content there. That is independent of ld370 and of any question
about GETMAIN.

Note what this does and does not say about cobc370. Its *generated* COBOL
programs take the IFOX00 → IEWL path on the guest and would meet this directly.
The COBC370 binary itself was linked host-side by ld370 with the elision, so it
faces the fetch-zeroing question instead, not this one. The finding refutes the
comment's claim about IEWL; it does not by itself predict a failure in either
artefact.

## C — IEWL materialises the module extent

    members whose text covers the whole extent, no gap    5,221   99.83%
    members with an INTERIOR gap                              1   (ICBMSG56, 1024 B)
    members with a LEADING gap                                0
    members with a TRAILING gap                               8   (87,445 B total)

    sum of module extents                            11,598,450 B
    sum of text-record bytes                         11,522,128 B   99.34%
    unmaterialised (interior gaps + trailing tails)      88,469 B

Text-record lengths are block multiples (1024 / 1680 / 6144), so a module's last
record is usually rounded *up* past the extent rather than trimmed. The nine
outliers (the interior gap and the eight trailing tails, the largest being
LETRRIP at 64,132 B and GENRMT at 12,886 B) are reported as measured; the record
sizes do not support a clean rule for why those nine differ, and no mechanism is
asserted here. HEWL's source is the authority if it matters.

**Population, named.** This corpus is IBM system code, so a single 4.7 MB
reservation of cobc370's kind is not in it. Reservations of *some* size are: D
below finds them in 67.4% of the 5,528 decks, 320 KB in total, and the linker's
treatment of them does not vary with size. So the 99.83% is not "the condition
rarely arises" — the condition arises in two thirds of the corpus. The precedent
argument does not rest on that percentage in any case, and finding B is why: **where IEWL materialises a DS,
the content is non-zero residue (B); where it does not, the content is whatever
fetch storage holds.** Neither of those is "sparse text into zeroed storage."

## D — IFOX00 reserves without emitting; IEWL fills it in

The two findings above are about the linker. This one measures the assembler
too, so the pair is IBM's own assembler against IBM's own linker with nothing of
ours in between.

`oprobe.c`, built against the same `common/src/obj370.c`, marks every byte a TXT
card covers (index = `txt.addr - section.org`, the mapping cmplmd370 uses) and
reports what is left. Calibrated on three constructed decks whose answers are
known by hand — a 1-byte `DC` after 1,507,282 bytes of `DS` comes back as
`covered=1, interior gap 1,507,282`; the same `DC` first and the `DS` after it
comes back as `trail=1,310,680`; both exact.

Over the 5,528 recorded IFOX00 decks (`ifox-run/decks`):

    decks with an INTERIOR uncovered run      3,579   64.7%    283,217 B
    decks with a TRAILING uncovered run         403    7.3%     37,324 B
    decks with ANY uncovered byte             3,728   67.4%
    section bytes 11,560,372, covered by TXT 11,239,831 (97.23%)

So IFOX00 does not emit TXT for a `DS`. That half of the patch's model is right.

Joining the two sides by module name, keeping only pairs where the deck's
section total and the member's extent agree (the filter that makes the two sides
comparable at all):

    modules in both sets                                      5,056
      minus scatter / overlay / incomplete                    5,034
      minus deck/member extent mismatch                       2,611   <- analysed
    of those, decks with reserved-but-not-emitted bytes       1,631   62.5%
      of which the MEMBER covers the whole extent             1,629   99.9%
      of which the member also leaves a gap                       2   (IEDQCA, IHJQRS20)

    bytes IFOX reserved without emitting, in that set        80,721
    bytes the member leaves unwritten, in that same set        4,009

**The assembler leaves it blank and the linker writes it out.** That is the
whole precedent question, measured end to end on IBM's own tools.

## E — the two halves of the patch are separable, and only one costs anything

Measured on a module of the shape that motivated the patch (4,000-int and
12,000-byte statics, a partially initialised struct, a common): the `DS` change
was applied by building the **patched cc1 from #445** and confirming it differs
from stock cc1 in exactly the five `ASM_OUTPUT_SKIP` lines and nothing else.
Both `.s` then went through the *same* as370 and the *same* ld370.

    object deck      42,160 B  ->     880 B        (-98%)
    member, ld370 as it is today    29,629 B  ->  29,629 B   BYTE-IDENTICAL
    member, ld370 with the elision  29,629 B  ->  13,725 B

`ld370` zero-fills and materialises (`memset(mod, 0, modlen)`), and as370 extends
the section length for a `DS` (`as370.c:5912`), so the reservation still reaches
the member as real zeros. The backend half therefore buys the whole deck-size win
and changes no semantics at all.

Note the third line carefully: **the elision gives 13,725 from the stock `DC`
deck as well.** It drops explicitly written zero constants exactly as it drops
reservations — the value-versus-coverage point, on a compiled module rather than
in the abstract.

## What this settles, and what it does not

**Settles:** the rationale's premise. IEWL-linked assembler `DS` does not behave
the way the comment describes, in either of the two cases it can fall into. The
patch is new behaviour, not a return to established behaviour, and the argument
from precedent does not hold.

**Settles:** the fidelity direction for ld370. The elision diverges from IEWL.
On IBM's own code it would show in 31 of 5,230 members.

**Settles:** that the backend half carries none of this. It shrinks the deck by
98% and leaves the member byte-identical (E), so it can land on its own.

**Does not settle:** whether the storage program fetch loads into is zero. That
is what the *elision* depends on, and it still needs the LOAD / DELETE / LOAD
measurement after dirtying subpool 0. This work removes one argument for
assuming the answer; it does not supply the answer.

## F — the elision turns the ld370 suite red today

`ld370/tests/run.sh` is ALL GREEN on `main` and reports one failure on #445:

    FAIL: packed a 13312-B block into a 6144 library (guard absent)

The fixture is `BIGTXT CSECT / DC 8000F'0' / GO BR 14` — 32,000 bytes of
explicitly written zeros. The elision removes them, the member's largest block
falls from 13,312 to 5,384, and the pack-time guard that must refuse an
oversized block into a smaller library has nothing left to refuse. Everything
else in the suite, including the IEWL byte-identity fixtures, is unchanged —
those fixtures are small enough to contain no all-zero record, which is why our
own oracle set cannot see what the 5,230-member corpus does.

## Artefacts

    tools/zprobe.c   load-module record probe (build against common/src/obj370.c)
    tools/oprobe.c   object-deck coverage probe

Both rebuild in one line and the tables re-derive in about two minutes:

    gcc -O2 -Wall -Icommon/include -o /tmp/zprobe docs/measurements/tools/zprobe.c \
        common/src/obj370.c common/src/mvs370.c

The corpora are local and unpublished: the bound members under
`mvs38src/work/measurements/dlib/` and the recorded IFOX00 decks under
`mvs38src/work/measurements/ifox-run/decks/`. Module names appear in the figures
above; no IBM source or object content is reproduced here or in the probes.
