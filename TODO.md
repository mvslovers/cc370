# cc370 — Open Work, Ranked

**State lives on GitHub, not here.** `gh issue list --repo mvslovers/cc370` is
the source of truth for what is open, closed or newly filed. What this file adds
is the part the tracker cannot hold: the **order**, the reason for it, and which
items wait on a decision rather than on code.

**It carries nothing that is copied.** Where a chain of reasoning already has an
owner — the issue thread, the PR, a reference document — this file points at it
and stops. A copy of a tracker is wrong the first time someone closes something,
and the only defence that works is to hold nothing worth going stale.

*Last reconciled against the tracker: 2026-09-06, second pass — five PRs merged
that day (#116, #119, #120, #121 for #109; #122, #123, #124 for #110). `#110` is
functionally complete and accepted by its consumer; `#109`'s readers are in and
only the as370/ld370/ar370 adoption is left. #117 and #118 remain open defects
inside the emitters. See the format-library band and *Recently landed*. Before
that, 2026-09-04: #99 closed, and
**seven new issues filed the same day — #108, #109, #110, #111, #112, #113,
#115** — of which **#115 was closed again within hours, because the report was
wrong and as370 was right** (see *Recently landed*; it is the most useful thing
that happened that day). Six of
the seven come from one place: a project moving MVS 3.8j source recovery onto
the host (`mvs38src`, a local repository — unpublished while its licensing
question is open, so there is no link to give), which assembles recovered source
with as370 and compares the deck against what the system ships. It is the first consumer this
toolchain has had that is neither the C ecosystem nor ourselves, and it changes
what is worth building — see the two new sections below. The reconciliation
before this one was 2026-08-30, 26 open, eight of them filed
that day: #99–#104 out of two working notes — `TODO-LD370.md` and
`TODO-ASM370.md`, which this file replaces — #106 out of closing #13, which went
the same day, and #107 out of the entry-point decision below. What was reference material rather than open work moved to
[`docs/ld370-iewl-divergences.md`](docs/ld370-iewl-divergences.md) and
[`as370/docs/ifox-option-parity.md`](as370/docs/ifox-option-parity.md); what was
already fixed was dropped).*

**The ranking rule, and it is the project's own:** *silent wrong output* beats
*silent under-reporting* beats *a loud gap* beats *cosmetics* — and inside the
top class, "has already shipped broken code" breaks the tie. It ranks *defects*,
which is why **#39 — the one with a shipped instance — leads.** It held that
place until the entry-point direction was decided and #99 was moved ahead of it
for a reason the rule does not cover: the whole direction rests on weak
externals, and #99 was the one place ld370 got them wrong. #99 landed on
2026-09-04, so the rule applies unmodified again.

---

## The order

| | Issue | Tool | Kind | Waiting on |
|---|---|---|---|---|
| 1 | #39 | as370 | silent — **and it has already shipped** | nothing |
| 2 | #37 | driver + ld370 | silent — the driver drops the AC | nothing |
| 3 | #100 | ld370 | silent — inverted attribute default | **a decision**, after one survey |
| 4 | #26 | as370 | silent — garbage bytes IFOX00 rejects | nothing |
| 5 | #97 | as370 | silent — a different object module | nothing |
| 6 | #89 | as370 | silent — a wrong value in the deck | **one corpus measurement** |
| 7 | #104 | as370 | silent — a swallowed build option | nothing |
| 8 | #86 | as370 | silent under-reporting, ×9 recorders | nothing |
| 9 | #35 | as370 | one root cause under two known symptoms | nothing |
| 10 | #23 | tests | the gate that would have caught most of this | **a decision** (where decks come from) |

Ten, not twelve: **#13 was closed on 2026-08-30 and #99 on 2026-09-04** — see
*Recently landed*.

Below the line, in bands rather than ranks: **the entry-point work** (#8, #107,
#10 and `libc370#159` — decided, sequenced, and spanning two repos), **the format
library and the tools on it** (#109 adoption left; #110 done; #111, #112, #113,
#117, #118 open — the only band with an outside consumer), **loud gaps** (#108, #56, #76, #78, #101, #102,
#103), **observability** (#9, #106), **listing fidelity** (#24, #28, #91),
**deferred** (#36).

---

### 1 · #39 — MNOTE severity is swallowed

*the only open issue with a confirmed shipped instance*

`MNOTE` is skipped in the macro-expansion loop alongside the listing controls, so
the operand — including the severity — is never parsed. The IBM macro error
convention is `IHBERMAC` → `MNOTE 8/12` → `MEXIT`: the macro **deletes the
statement** and reports the error only through the MNOTE. Under as370 that means
a macro-argument error compiles to silence — no instruction, no diagnostic, rc 0.

It has already cost the ecosystem once. libc370's `@@aopen.asm` wrote a
`FREEMAIN` whose operand combination `freemain.macro` rejects; the storage-shortage
cleanup therefore never existed, and the buffer leaked exactly when storage was
short. It was found by scanning the object for a missing SVC 10, not by the
toolchain. The same statement shape is one typo away in every GETMAIN/FREEMAIN
caller.

The fix is three small steps and the issue spells them out. Note the last one:
`mklibc.py` already deletes the object and stops on a non-zero rc, so libc370
inherits the protection with no change on its side.

### 2 · #37 — the AC is dropped, and an unauthorized module looks authorized

*one of the two drops is real; the other has a narrower cause than the issue says*

`-Wl,--ac,1` never reaches ld370 from the driver — the two outputs are
byte-identical, and passing `--ac` to the driver directly is at least loud
(`unrecognized command line option "-fac"` from cc1). That half is a plain driver
defect and is the substance of this issue.

Why it costs a cycle rather than a minute: an unauthorized module is
indistinguishable from an authorized one until it runs, and then the first
`MODESET KEY=ZERO` ends the step **S047** with an empty SYSPRINT, because stdio
buffers are lost with the unclosed DCB. The symptom is "no output and an abend",
with nothing pointing at the link step. It cost two deploy cycles.

**The `--pack` half is narrower than reported.** `build_userdata()` already keeps
a packed member's *complete* PDS2 user-data verbatim — entry, modlen, AC,
RENT/REUS/REFR — and re-stamps only `PDS2TTRT`, since 2026-06-23. It can only do
that for an **`-iebcopy` input**, which is the self-describing form; the issue's
command packs a bare `.lm`, which carries no directory and therefore no
attributes to carry over. So the fix here is not "carry the AC over" — that
exists — but to make the bare-`.lm` path stop looking like the `-iebcopy` one:
recommend the two-step workflow in the usage text, and say so when a bare `.lm`
is packed with attributes that cannot survive.

**Its "adjacent observation" is answered and is not a bug.** `--norent` producing
a byte-identical module is not the flag being ignored: `build_userdata()` is
reached only from `emit_unload`, so attributes exist only in the directory entry
of an `-iebcopy`/`-xmit`/`--pack` output. A bare `-o OUT` member carries none at
all and is byte-identical with and without the flag by construction. Confirm on
the `-iebcopy` output before closing that half.

### 3 · #100 — every module is marked RENT+REUS, IEWL marks neither

*adjacent to #3, not the same change; the decision is which default*

The PDS2 template hardcodes `0xC3`, and `build_userdata` only ever *clears* those
bits. IEWL zeroes both attribute bytes before PARM processing (`NI PDSE7,ZERO` /
`NI PDSE8,ZERO`, with `ZERO EQU 0`) and sets RENT/REUS only from the option table
when the PARM asks — verified in the source, not inferred. A false RENT is not a
label but a promise the loader acts on: the module may be placed in the LPA and
shared across address spaces, which makes this the one finding in the group that
corrupts storage across address spaces rather than within one module. rexx370
already needs `--norent`, so the case is live; today it depends on remembering the
flag per module, and forgetting is silent.

It shares a function with #3 and nothing else — #3 is about a value that never
arrives, this is about a default that is wrong when nothing arrives. Whoever
touches `build_userdata` should read both, and `REFR` is worth four more lines
while in there (another `PDS2ATR1` bit with no control at all).

**Two open points.** The decision: invert the default to match IEWL, or keep it
and *require* an explicit `--rent`/`--norent`. And the survey that sizes it —
mbt v2 links every ecosystem module through ld370, so how many of them actually
want RENT decides whether inverting is a one-line change or a sweep across every
`project.toml`. Do the survey before the decision.

### 4 · #26 — operands IFOX00 rejects, assembled to garbage

as370 has no "simply relocatable" check, so `L 1,FLDX*2-FLDX` assembles as an
absolute base-0 reference and a paren subterm spanning two sections yields a
garbage displacement. IFOX00 flags both IFO217, severity 12, and zeroes the
instruction. Two mechanisms let them through: `expr_val` loses relocatability
across a multiply, and `expr_sect` skips parenthesised content wholesale while
`expr_val` evaluates it. Both verified against a real IFOX00.

It is complementary to #21, not overlapping: #21's fix relies on
"IFOX-accepted ⇒ `expr_sect`-correct", which holds *because* these forms are
IFOX-rejected.

### 5 · #97 — an undeclared SET symbol produces a different object module

The risk of enforcing it was measured before the issue was filed and it is nil:
an instrumented build found **0 modules** with an undeclared SET symbol across
826 ecosystem modules and 277 real IBM ones. Nothing relies on the leniency.

Two halves, and the first is worth doing alone: the *diagnostic* is a check at
`SETA`/`SETB`/`SETC` and at the reference site. The *code effect* — IFOX leaves
the reference unsubstituted and the statement generates nothing — is the larger
half, because the substitution path has to distinguish "undeclared" from
"declared but null", which today it does not.

### 6 · #89 — a forward reference in EQU resolves to 0

`A EQU B` before `B EQU 4` gives `A = 0`, RC 0, no diagnostic, and pass 2 does not
repair it — the wrong value reaches the deck. IFOX00 flags IFO188, the message
#82 just implemented everywhere else; #82's recorder is gated on pass 2 and has to
be, so it cannot cover this.

**Measure first.** Whether any ecosystem module relies on a forward EQU is not
known — the #82 probe counted pass-2 lookups only and says nothing about it. A
corpus that quietly depends on this would move decks.

### 7 · #104 — an unrecognised option becomes the source filename

The argument loop ends in `else src = argv[ai];` with no validation, so a typo,
an option from a build script, or an IFOX00 option as370 does not implement is
silently swallowed. Measured: `as370 --sysparm=DEBUG` returns rc 0 and assembles
the *production* branch of an `AIF ('&SYSPARM' EQ 'DEBUG')`, because `&SYSPARM`
is not implemented either. The caller gets a production build believing it is a
debug build.

Cheapest fix in either tool, and it must not wait for `SYSPARM` — adding that
later does not help anyone who mistyped it in the meantime.

### 8 · #86 — nine diagnostic recorders drop everything past 128 entries

200 undefined opcodes in one module report 128 and state the truncated number as
fact. #85 already fixed this for the continuation recorder after nsf370 hit it and
established the shape — count every diagnostic whether or not it is printed,
derive the severity from the counters, bound only the printed list, and say what
was dropped. Nine recorders to go, worth one pass with a shared helper rather than
nine copies. In one of them (`note_operr`) the cap can also mis-state the severity.

### 9 · #35 — the attribute apostrophe, and the lockstep it imposes

`parse()`'s operand tokenizer toggles string state on every apostrophe with no
attribute-operator exception, so `L'SYM` opens a string that never closes and the
trailing comment is absorbed. Historically harmless, and every *other* scanner in
as370 already special-cases it.

**The lockstep is the point.** #32's `has_overlong_term` was deliberately written
to mirror the buggy tokenization, and #34 disclosed the false negative that
buys. Whoever fixes `parse()` must update `has_overlong_term` in the same change,
or it either resumes false-positiving on comments or stays blind to attribute-ref
over-length symbols.

### 10 · #23 — the corpus gate has an oracle-shaped hole

*#48 delivered half of it; the other half needs a decision*

`as370/tests/corpus` compares two as370 binaries over one tree and answers *did
as370 change*. It deliberately cannot answer *is as370 right* — both sides are
as370. That question is answered today for nine modules (`tests/ref`) and four
listings (`tests/listref`), against real IFOX00.

Most of what is ranked above this line is a construct the corpus never contained.
The decision it waits on: commit IFOX00 reference decks for the corpus (sizeable),
or generate them on demand through the mvsMF path and cache. `tests/oracle/capture.py`
already does the capture for a single module.

---

## The entry-point work — decided, and it spans two repositories

*The one thread here that is a design change rather than a defect. The decision
was taken on 2026-08-30 and is recorded in #10; what is left is sequencing.*

**What is wrong.** Startup is customized by redefining `@@START` under the same
name and letting it shadow libc370's default. For one program that is clean. With
two custom startups in one autocall pool — httpd's server and its CGI launcher —
they are indistinguishable by name, so the linker picks one and produces a module
that links RC 0 with the wrong entry and faults at runtime. httpd works around it
by keeping the launcher out of the shared archive. The full analysis, with the
measured 52-versus-35-CESD evidence, is in
[`docs/entry-point-resolution.md`](docs/entry-point-resolution.md).

**The same shape one level down.** The startup *objects* are forked the way the
startup *symbol* is: `@@crt0.asm` and `@@crt1.asm` are 319 and 322 lines that
differ in three — the `IDENTIFY` for `CTHREAD` — and the two copies have already
drifted apart in a fourth place. The ecosystem uses `crt1` **132 times**, `crt0`
once, and `crtm` not at all.

**Decided:** the collision diagnostic now, the pre-`main` hook as the
destination. A distinct symbol per startup was considered and rejected — it makes
the choice explicit but leaves a decision in every project, where the hook removes
the decision.

| step | where | what |
|---|---|---|
| — | #99 | **done, 2026-09-04** — have weak externals right first; the whole direction rests on them |
| 1 | #8 | warn when autocall resolves a symbol several members define — the cheap half, and it catches the exact httpd failure at link time |
| 2 | `libc370#159` | collapse `@@crt0`/`@@crt1` with a weak `CTHREAD` reference — the pattern the same file already uses for `@@STKLEN` |
| 3 | #107 | `--entry` seeds autocall, so the CRT moves inside `libc.a` and mbt's four near-identical link recipes collapse |
| 4 | #10 | the weak `__premain()` hook in libc370; then this issue closes |

Steps 2 and 3 are independent of each other and of 4. The prerequisite 4 really
wanted — weak externals behaving regardless of link order — is in.

**Two questions `libc370#159` must answer before anything is merged**, and they
are not rhetorical: what the `CTHREAD` `IDENTIFY` is actually for — several
`project.toml` files call `crt1` *"the threading runtime"* while its own header
says it is `@@CRT0` **without** the threading `IDENTIFY` — and what `crtm` is for.
`crtm` reads as the startup for a program entering a task whose C runtime already
exists: it only takes a stack and requires `@@CRTGET` to *find* a `CLIBCRT`
(`@@crtget.c` looks one up in the PPA, it never creates one), where `crt0`/`crt1`
create the environment. That is exactly an httpd CGI or display module — and
those are linked with `crt1`. So either `crtm` is obsolete, or the CGI path builds
the environment twice. Settle that before deleting anything.

**What the hook also removes.** `mbt/mk/mbt.mk` names `-lc` twice on every link,
with a paragraph explaining that crt0/crt1/crtm declare `@@START` as an ER and
autocall would otherwise take a dependency's launcher. That trick exists only
because two startups share one name.

---

## The format library and the tools on it — new, and with a consumer

Five issues filed 2026-09-04 — one of them now half done — and the first band
here that exists because somebody outside this repository needs it. `mvs38src` assembles
recovered MVS 3.8j source with as370 and compares the deck against the object the
system ships; the comparison **is** its success criterion, and an agent works the
loop unattended. That is a harder contract than the C ecosystem ever placed on
these tools — it needs machine-readable output and exit codes that mean one thing.

**#109: `libmvs370` done, `libobj370`'s READERS done, its adoption pending.**
PRs #116 and #119 moved the byte layer (primitives, 3350 geometry, the
COPYR1/COPYR2 template). PRs #120 and #121 built `common/obj370` — the
object-record layer the issue title names — and put **file370** on it: ESD, TXT,
RLD, END, plus the load-module record walk and CESD.

**as370, ld370 and ar370 still carry their own object-deck ESD copies.** That is
the last of the reader half, and it is the one piece here on nobody's critical
path.

This file once said "the first half landed, the emitters remain". That was wrong
in a way worth keeping visible, because it made the rest look like one deferred
mass: it omitted that half of the library named in the title did not exist yet.

**What landed is worth carrying, because it was not what the issue assumed.**
`common/mvs370` already existed — added with xmit370 in `51bdf5b` — and only
xmit370 ever included it. So step one was *adoption*, not extraction: −166 lines,
three identical `e2a1` decoders, two sets of big-endian accessors, and ld370's
complete second NETDATA layer, all gone. #119 then removed the dangerous
duplication — the 3350 constants that *are* the S106-0F fix, copied verbatim
between the two emitters — and put a mutation-tested guard under them.

**The rest splits into readers and emitters, and they have nothing in common but
the issue number.**

| | who is waiting | risk |
|---|---|---|
| **object-record readers** — ESD/TXT/END, RLD only to *locate* relocatable fields, plus the load-module record walk | **#110, #111, #112 — all three, and all three only read** | low: reconcile three existing implementations, byte-identity as the oracle |
| **emitters** — IEBCOPY unload, XMIT | nobody | high: the code behind four production failures, with **#117 and #118 open inside it** |

**Readers first, and explicitly not to speed the emitters up.** `cmplmd370`
compares an object deck against a DLIB element or against a CSECT inside a load
module; it never writes an unload or an XMIT stream, and the same holds for
`idrdump370` and `dasm370`. So the thing on three tools' critical path is the
mechanical half.

**The emitters wait on their own defects, not on scheduling.** `mvs370.h`'s rule
— unify *"with two proven implementations in hand rather than one guessed
abstraction"* — is sharpened by #117 and #118: two measured defects in exactly
the code that would be unified. Merging two implementations while both have
something open merges the defects too. Close them, then unify.

Acceptance for the reader extraction is the same as #116's and needs nothing new:
the byte-identity corpus deck for deck plus the ld370 regression. For a
reader-only change that is a complete proof, because no output is produced that
those do not already cover.

| | depends on | what it is |
|---|---|---|
| #109 | — | `libmvs370` **done** (#116, #119); `libobj370` **readers done** (#120, #121); **adoption of as370/ld370/ar370 open** |
| #110 | — | `cmplmd370` — **built and accepted** (#122, #123, #124). Compare, `--clearrld`, `--csect`, `--difin`/`--difout`, `--json`, hole classification |
| #111 | #109 readers | `idrdump370` — translator/ZAP IDRs and eyecatchers per CSECT. The ZAP record is the only way to see a module was modified after assembly |
| #112 | #109 readers | `dasm370` — a disassembler as370 can reassemble, plus an alignment diff that classifies insertion/deletion rather than reporting a byte delta |
| #113 | *ownership only* | read a **foreign** IEBCOPY unload — an FB source library unloaded by MVS parses to zero members today |
| #117 / #118 | — | measured defects **in the emitters**; they gate unifying them, and nothing else |

**Why #113 sits here and not in the loud gaps below:** it is a capability, not a
regression. file370 recognises the container and then finds nothing, because an
unload produced by IEBCOPY from an FB source library is a shape our own emitters
never produce — the `RECFM=U` it reports is the visible symptom of the same
mismatch. Nothing that works today stops working.

**And #113 is not actually behind the gate.** The issue says it *belongs with*
#109 because libmvs370 would own the unload decoder — that is ownership, not a
blocker. It is a decoder file370 lacks today and could gain before the
extraction, and it is the one item here the caller needs *now*: the macros it is
missing (`PVTMAC`/`APVTMAC`, over 100 of its remaining assembly failures) are on
a tape it cannot read. Do not let the table's tidy dependency column park it.

**Read #112's licensing note before starting it, not after.** The route matters
to the result and not only to the paperwork; the roadmap carries the argument.

**The sequencing lives with the consumer, not here.** `mvs38src/TODO.md` ranks
these by what unblocks its measurements (#109 and #110 first; #112 waits on how
large its case D turns out to be). Do not restate that ranking in this file — it
will be wrong the first time that project learns something. As of 2026-09-06 that
project reports 111 of 150 modules assembling and says what is missing is no
longer an assembler problem but the comparator: without #110 a module can be
translated and not declared recovered.

## Loud gaps — nothing silent about them

Ranked below the whole list above for that reason alone, not by size.

- **#108** — `DC S(…)` / `DS S` are diagnosed and not implemented, so no storage
  is reserved and every later symbol in the section would move. #53 turned the
  corruption into that diagnostic; it did not close the gap. Two bytes,
  base+displacement through the active `USING` — small, and the only as370
  limitation reported *by name* in the same 150-module sample (4 failures).
  **Not #76:** that covers `Q` as part of pseudo registers; `S` is unrelated.
- **#56** — the last four IFOX00 opcodes. Two are table rows with masks already in
  the table; two need formats as370 does not have (SSE, RRE). They were left out
  of #55 deliberately: a fabricated encoding turns a clean RC 8 into silently
  wrong bytes. **RRE is worth more than `IPTE` alone** — it is also the format a
  good part of the Hercules S/370-extension set needs.
- **#76** — pseudo registers, one feature across both tools (`DXD`, `CXD`,
  `Q`-cons, PR collection in the linker). Zero occurrences anywhere in the
  ecosystem and no oracle in reach. **One part is worth doing regardless of the
  feature:** `DXD` and `COM` are rejected as *"undefined operation code"*, which
  is the wrong message class for a valid Assembler XF statement — a one-line
  change, and the distinction #53 already established for DC/DS types.
- **#78** — IFO069 needs a statement type `join_cont` does not have, because the
  limit is two continuations for machine/assembler operations and comments but
  *not* for macro calls.
  **The severity-4 return-code question this entry used to carry is settled, and
  the entry was wrong about both halves of it.** It said as370 has no severity-4
  path and that any non-zero RC is fatal to `make`. as370 *does* return 4
  (`as370/src/as370.c:3281` raises SEV26/SEV69 to 4, `:3406` returns it), and
  mbt *does* honour `COND=(8,LT)` — `mbt/mk/mbt.mk:151` is
  `|| { rc=$$?; [ $$rc -lt 8 ] || exit $$rc; }`. Verified 2026-09-04; whichever
  of the two changed after the entry was written, the entry outlived it.
  What is left is the narrower design question, and #115 is the evidence to read
  before reopening it: IFOX00 gives a harmless continued comment and a
  statement-losing continuation the same severity 4, and as370 deliberately
  splits them — the second is its own error (`:3282`). #115 was filed to undo
  exactly that split and was closed when the input turned out to be corrupt. Had
  as370 warned and continued, 150 modules would have been assembled against
  mangled macros and compared in good faith.
- **#101** — ld370's module image buffer is a fixed 1 MB static with no bounds
  check. Latent (the largest module in the corpus is ~241 KB) but it is literally
  the pattern that has produced four production failures in that one file. One
  guard, or grow it like `out[]`.
- **#102 / #103** — duplicate CSECT and duplicate COMMON, where ld370 takes the
  last and IEWL takes the first / the maximum. Derived from the linkage editor,
  **not reproduced**, and the deliverable for each is a fixture: once it exists,
  the `ld370/tests` IEWL oracle settles the semantics by diff without any further
  reading of the reference. #103 is not reachable through as370 at all — it needs
  IFOX00-assembled input.

## Observability

- **#9** — no link map. IEWL had MAP/XREF for exactly this, and the absence cost
  real time during the httpd migration: "which 17 sections are missing, and where
  did they come from" turned into guesswork against a CESD full of string
  literals. It is the thing you reach for *after* the link succeeded but the
  module misbehaves.
- **#106** — the translator IDR is dropped on the floor. Split out of #13:
  a genuine IEWL member carries three IDR records and ours carries two, so
  `AMBLIST LISTIDR` cannot say which assembler produced the code. as370 already
  writes its identity into every END card; ld370 does not read it. One field, one
  21-byte record, one flag byte — and the fixture oracle settles the layout.
## Listing fidelity

All three are cosmetic, all three are pinned rather than hidden — each was found
while building a `listref` case, and each is excluded from that case *with a
reference to its issue* instead of being silently masked.

- **#24** — DS inside a DSECT renders with the enclosing CSECT's LOC and stale
  object-code bytes.
- **#28** — LTORG renders at the pre-alignment LOC, and literal-pool entries are
  numbered out of source order.
- **#91** — a library-member continuation diagnostic cannot be reconciled with the
  statement it belongs to, so the flagged count can be one too high. The printed
  count only; RC, bytes and listing are unaffected, and **0 of 835 ecosystem
  modules** produce one at all. The residual is pinned as a tripwire in
  `flagged_libmac`, so implementing it fails that case and brings whoever does it
  to the number that has to change.

---

## Deferred

### #36 — `'\n'` compiles to NEL `X'15'`, not LF `X'25'`

*the first deliverable is a survey, not a change*

Filed as an investigation and it should stay one. The byte is baked into every
object at compile time — string literals as much as character constants — so
changing it only works if compiler and library move together, and every load
module already in the field carries the old byte. `X'15'` is also what IBM
compilers emit, so diverging makes cc370 correct in CP037 and unusual on z/OS.

What would move it forward is the survey the issue asks for: who compares against
`'\n'` across the mvslovers projects, and what breaks in each direction. A
`-fnewline=lf|nel` flag is the option that lets the ecosystem move deliberately,
at the cost of one more dimension in which two objects can disagree.

---

## Recently landed

Pointers only. The reasoning lives in the issues and their PRs.

- **The August as370 parity run** — #94, #93, #88, #82, #74, #72, #70, #68, #64,
  #63, #61, #57, #53, #52, #51, #50, #48, #44, closed 2026-08-28…30. Between them
  they retired the whole DC/DS silent-zero class (#53), the diagnostic
  message/statement counting (#88), IFO188 (#82), the corpus gate's manifest decay
  (#48 — replaced by a differential gate, and #44 closed *not planned* with the
  reason), and the S/370-extension policy (#57).
- **#13 / PR #46** — ld370 stamps a linkage-editor IDR with the BIND date and
  time, so ISPF's CHANGED column has something to read. Contributed by the
  reporter himself in August and then left open; closed 2026-08-30 after checking
  the bytes a current link actually produces (`80 15 82`, product, V/M, packed
  `YYDDDF` and `0HHMMSSF`). The last change to `ld370.c` — the tool has been
  untouched since 2026-08-13.
- **#110 `cmplmd370` / PRs #122, #123, #124** — the host COMPare Load MoDule, and
  the recovery project's success criterion. It compares an as370 object deck
  directly against the shipped DLIB **load module**, which works only because
  the binder relocates adcons but does not touch instructions: zero them on both
  sides and the rest is comparable without reproducing IBM's bind. Hence
  `--clearrld` defaults ON, as Dave Kreiss' `CLEARRLD` did.
  **Result over 102 real pairs:** 18 byte-identical, 9 differing only in `DS`
  holes, 9 mixed, 14 differing inside generated text, 52 length mismatches — and
  all 52 correctly reported, no crash anywhere. Accepted by its consumer.
  Three things worth keeping. **A tool can compute what looked like hand
  analysis:** our own TXT cards say which offsets the assembler wrote, so a
  differing byte outside them is DS-hole residue rather than a disagreement —
  the tool finds exactly the nine modules that were identified by hand.
  **Real material found two bugs no self-generated case could:** a text record
  reaching past the sum of section lengths (binder padding) made every reference
  byte read as zero, which looks exactly like a difference at offset 0; and
  clusters were collected into a fixed 64, so `--difout` silently omitted every
  range past the 64th on a 319-cluster module. **The test now asserts the
  property, not the symptom** — cluster lengths must sum to `diff_bytes`.
  Closed avenue, recorded so nobody rebuilds it: a third verdict, "differs but
  explained by a named zap", has no data. `SYS1.SMPPTS` carries only MVS/CE's
  local layer (28 modules, none among ours); the zaps that left an IDR in 71 % of
  DLIB members came from IBM's service process and its data is not on the system.
- **#109 `libobj370` readers / PRs #120, #121** — `common/obj370`: the object
  record layer (ESD/TXT/RLD/END) and the load-module record walk, with file370
  converted. The ESDID rule differs between the two and is the trap: a deck
  numbers from its card's first-id field and skips LD items, a load module's
  CESD position IS the id. Verified 114/114 against real IBM material by the
  mvs38src session and 102/102 on the load-module side here.
- **#109 `libmvs370` / PR #119** — the 3350 geometry, the UDEBX and COPYR1 field
  offsets and the 328-byte COPYR1/COPYR2 template move to `common/`, with
  `mvs_udebx_extent()` replacing the identical computation in both emitters. The
  constants moved were the ones the over-packed-track bug was made of, copied
  verbatim between the two tools. Byte-neutral over 27 artifacts; 14 shared
  constants each corrupted in turn and every one turns a suite red. Three new
  guards had to exist first: `LDDATE`/`LDTIME` now pin the XMIT timestamp (before
  that a `.xmit` could not equal itself across a second boundary, so
  "output unchanged" was unprovable), `track_check.py` asserts the physical 3350
  geometry ld370 had never checked, and the same checker covers xmit370 through
  `--from-xmit`. An adversarial review then found the guard's own hole: the
  packing budget was unprotected against being "corrected" up to the real track
  length, 19069 → 19254 — measured green on both suites. **A mutation test is
  only as good as the plausibility of its mutants**; mine had used 999999.
- **#109, primitives / PR #116** — all five tools now share `common/mvs370`
  instead of their own copies of it. The surprise was that `common/mvs370`
  already existed (`51bdf5b`, with xmit370) and only xmit370 used it, so this was
  adoption rather than extraction: −166 lines, and ld370's entire second NETDATA
  layer removed. Two conversion behaviours changed deliberately — 53 printable
  characters that used to render as `?` now render, and ld370 no longer blanks an
  unknown character when encoding XMIT text units. Verified by the corpus gate
  (743 modules deck for deck), the IFOX00 and IEWL oracles, and a real C link
  byte-identical in `.lm`/`.iebcopy`/`.xmit`. Two build paths broke *after* the
  change and were caught before merge, both of a kind that only fails on a clean
  rebuild: the corpus gate exports the `as370` subtree alone, and
  `as370/Makefile` is what `make test-as370` really compiles with. The emitters
  are untouched and are the rest of the issue.
- **#115** — filed against as370 for treating IFOX00's IFO026 (severity 4) as
  fatal, so that IBM's shipped `WTO` macro "could not be assembled": the `AIF`
  comment on line 654 reached column 72 and the card said "continued". Closed the
  same day, **because the report was wrong and as370 was right.** Column 72 of the
  real `SYS1.MACLIB` member is a blank; the continuation was introduced by the
  reporter's own EBCDIC→ASCII conversion, which wrote UTF-8 — the `¬` (`X'5F'`)
  became two bytes and shifted the rest of the line one column right. Re-converting
  to a single-byte encoding fixed it, and the sample's clean-assembly rate went
  from 65/150 to 73/150 with the whole error class gone.
  **Worth keeping, because it is evidence for a stance and not just a closed
  ticket:** `270b22d` ("a discarded statement is an error, not a severity-4
  warning") and `c31c806` ("comment cards take part in the continuation rule")
  were argued on the grounds that IFOX00 gives a harmless continued comment and a
  statement-losing continuation the same severity 4, and only the second silently
  corrupts a host build. Here the strict stance caught a data-corruption bug in
  the *caller's* toolchain that a warning would have passed through — 150 modules
  would have been assembled against mangled macros and compared in good faith.
  It is the counter-evidence to reach for when the severity-4 question in #78 is
  reopened.
- **#99** — a `WXTRN` parsed before an `EXTRN` of the same name left the composite
  entry at ESD type `0x0A`, so the unresolved check (which compares against `T_ER`
  exactly) never fired: a hard reference nothing defines linked rc 0 with a zero
  adcon. Reverse the two objects and it was reported correctly — the order *was*
  the bug. `g_intern` now promotes a `WX` matched by anything but another `WX`,
  the way `HEWLFESD` does. An unmatched weak external is untouched and stays type
  `0x0A`; the regression test asserts that in both object orders, because that is
  the half the entry-point work depends on. Closed 2026-09-04.
- **#41** — an inherited RLD continuation bit survived onto a record's last item.
- **#40** — `-O1` 64-bit load through a dying pointer clobbered its own base
  register.
- **#33 / #11 / #38 / #2** — host-build breakage on modern gcc/clang.

Beyond the tracker, the two milestones this file inherits rather than tracks:
`--pack` and the transport formats were validated end-to-end on real MVS in June,
and mbt v2 has compiled, assembled *and* linked entirely on the host since
2026-08-13. `CLAUDE.md` holds that history.

## Not in the tracker

Small things with no issue, recorded here so they are not lost twice.

- **`ld370 --help` does not exist** — it is parsed as a filename. as370 has one.
  Noted in `docs/ld370-iewl-divergences.md`.
- **as370 has no `YFLAG` equivalent** — it emits Y-cons with no range check, the
  same silent-truncation shape as the rest of that class. Noted in
  `as370/docs/ifox-option-parity.md`.
- **[`docs/tool-roadmap.md`](docs/tool-roadmap.md)** is the roadmap for *new*
  tools (`objdump370`, `nm370`, `iebcopy370`, …). It used to say here that the
  roadmap was not open work and needed a decision before it became any — **that
  decision was made on 2026-09-04**: #109 through #113 are filed, and the band
  above ranks them. What is left in the roadmap is still a proposal, and it is
  still the right place to read *why* Phase 0 comes first; the parts that now
  have issues are marked there.

## Cross-repo

This file is cc370-only, and two threads are not.

**The entry-point work.** Its libc370 half is `mvslovers/libc370#159` (the CRT
variants) and — now that #99 is in — the `__premain()` hook that closes #10. Do
not rank those here; the sequence table above is the place that keeps them in
step.

**MVS 3.8j source recovery** (`mvs38src`) is a *consumer*, not a half: it needs
#109–#113 and #115 and files them here, but it decides nothing about cc370 beyond
what a caller decides by needing something. It has **no remote yet** — publication
waits on a licensing answer — so it is a path on this machine, not a link, and
that is worth knowing before someone goes looking for it. Its `TODO.md` holds the
sequencing that matters to it, and it is allowed to disagree with the ranking in
this file — its scale is 5,500 modules of IBM source, ours is a C toolchain, and
the same issue can be worth a different amount to each. Where the two must agree
is on what the issue *says*, which is why the issue is the record and neither
file restates it.
