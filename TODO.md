# cc370 — Open Work, Ranked

**State lives on GitHub, not here.** `gh issue list --repo mvslovers/cc370` is
the source of truth for what is open, closed or newly filed. What this file adds
is the part the tracker cannot hold: the **order**, the reason for it, and which
items wait on a decision rather than on code.

**It carries nothing that is copied.** Where a chain of reasoning already has an
owner — the issue thread, the PR, a reference document — this file points at it
and stops. A copy of a tracker is wrong the first time someone closes something,
and the only defence that works is to hold nothing worth going stale.

*Last reconciled against the tracker: 2026-08-30. 26 open, eight of them filed
that day: #99–#104 out of two working notes — `TODO-LD370.md` and
`TODO-ASM370.md`, which this file replaces — #106 out of closing #13, which went
the same day, and #107 out of the entry-point decision below. What was reference material rather than open work moved to
[`docs/ld370-iewl-divergences.md`](docs/ld370-iewl-divergences.md) and
[`as370/docs/ifox-option-parity.md`](as370/docs/ifox-option-parity.md); what was
already fixed was dropped.*

**The ranking rule, and it is the project's own:** *silent wrong output* beats
*silent under-reporting* beats *a loud gap* beats *cosmetics* — and inside the
top class, "has already shipped broken code" breaks the tie. It ranks *defects*,
which is why #39 — the one with a shipped instance — sat first until the
entry-point direction was decided. **#99 now leads instead**, and for a reason
the rule does not cover: the whole direction rests on weak externals, and #99 is
the one place ld370 gets them wrong. #39 follows immediately; it is small and
must not be allowed to slip behind a design thread.

---

## The order

| | Issue | Tool | Kind | Waiting on |
|---|---|---|---|---|
| 1 | #99 | ld370 | silent — measured; and the mechanism the entry-point work uses | nothing |
| 2 | #39 | as370 | silent — **and it has already shipped** | nothing |
| 3 | #37 | driver + ld370 | silent — the driver drops the AC | nothing |
| 4 | #100 | ld370 | silent — inverted attribute default | **a decision**, after one survey |
| 5 | #26 | as370 | silent — garbage bytes IFOX00 rejects | nothing |
| 6 | #97 | as370 | silent — a different object module | nothing |
| 7 | #89 | as370 | silent — a wrong value in the deck | **one corpus measurement** |
| 8 | #104 | as370 | silent — a swallowed build option | nothing |
| 9 | #86 | as370 | silent under-reporting, ×9 recorders | nothing |
| 10 | #35 | as370 | one root cause under two known symptoms | nothing |
| 11 | #23 | tests | the gate that would have caught most of this | **a decision** (where decks come from) |

Eleven, not twelve: **#13 was closed on 2026-08-30** — see *Recently landed*.

Below the line, in bands rather than ranks: **the entry-point work** (#8, #107,
#10 and `libc370#159` — decided, sequenced, and spanning two repos), **loud
gaps** (#56, #76, #78, #101, #102, #103), **observability** (#9, #106),
**listing fidelity** (#24, #28, #91), **deferred** (#36).

---

### 1 · #99 — a WX parsed before an ER goes unreported

*derived from the linkage editor, then measured on the host*

`g_intern` sets a composite entry's type only when it creates it, so a weak
external seen first keeps type `0x0A` for the rest of the link even after a hard
ER for the same name arrives — and the unresolved check compares against `T_ER`
exactly. Measured 2026-08-30 with two four-line objects:

```
b.o        (hard ER, nothing defines X)   unresolved external X, rc 1   ✅
b.o a.o    (ER first, then WX)            unresolved external X, rc 1   ✅
a.o b.o    (WX first, then ER)            rc 0, no diagnostic           ❌
```

The third module carries `X` in its CESD as type `0A` and both adcons at zero. It
is the failure `--allow-unresolved` exists to prevent, arrived at by accident of
parse order. `as370` emits WX today, so this is reachable through our own
toolchain.

**It leads the list because of what was decided on top of it.** The entry-point
work — the `__premain()` hook, the CRT merge, `@@STKLEN` as it already stands —
all rests on one mechanism: a weak external that resolves to zero when nothing
defines it, plus a runtime test that skips the feature. This is the one known
defect in that mechanism. It is **not** a blocker for any of them, and saying so
would be overstating it: the failure needs a hard `ER` on the same name as the
`WX`, and neither a weak `__premain` nor a weak `CTHREAD` produces one — which is
why `@@STKLEN` has worked for years. But it is small, measured, and worth having
right before more of the runtime leans on it.

### 2 · #39 — MNOTE severity is swallowed

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

### 3 · #37 — the AC is dropped, and an unauthorized module looks authorized

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

### 4 · #100 — every module is marked RENT+REUS, IEWL marks neither

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

### 5 · #26 — operands IFOX00 rejects, assembled to garbage

as370 has no "simply relocatable" check, so `L 1,FLDX*2-FLDX` assembles as an
absolute base-0 reference and a paren subterm spanning two sections yields a
garbage displacement. IFOX00 flags both IFO217, severity 12, and zeroes the
instruction. Two mechanisms let them through: `expr_val` loses relocatability
across a multiply, and `expr_sect` skips parenthesised content wholesale while
`expr_val` evaluates it. Both verified against a real IFOX00.

It is complementary to #21, not overlapping: #21's fix relies on
"IFOX-accepted ⇒ `expr_sect`-correct", which holds *because* these forms are
IFOX-rejected.

### 6 · #97 — an undeclared SET symbol produces a different object module

The risk of enforcing it was measured before the issue was filed and it is nil:
an instrumented build found **0 modules** with an undeclared SET symbol across
826 ecosystem modules and 277 real IBM ones. Nothing relies on the leniency.

Two halves, and the first is worth doing alone: the *diagnostic* is a check at
`SETA`/`SETB`/`SETC` and at the reference site. The *code effect* — IFOX leaves
the reference unsubstituted and the statement generates nothing — is the larger
half, because the substitution path has to distinguish "undeclared" from
"declared but null", which today it does not.

### 7 · #89 — a forward reference in EQU resolves to 0

`A EQU B` before `B EQU 4` gives `A = 0`, RC 0, no diagnostic, and pass 2 does not
repair it — the wrong value reaches the deck. IFOX00 flags IFO188, the message
#82 just implemented everywhere else; #82's recorder is gated on pass 2 and has to
be, so it cannot cover this.

**Measure first.** Whether any ecosystem module relies on a forward EQU is not
known — the #82 probe counted pass-2 lookups only and says nothing about it. A
corpus that quietly depends on this would move decks.

### 8 · #104 — an unrecognised option becomes the source filename

The argument loop ends in `else src = argv[ai];` with no validation, so a typo,
an option from a build script, or an IFOX00 option as370 does not implement is
silently swallowed. Measured: `as370 --sysparm=DEBUG` returns rc 0 and assembles
the *production* branch of an `AIF ('&SYSPARM' EQ 'DEBUG')`, because `&SYSPARM`
is not implemented either. The caller gets a production build believing it is a
debug build.

Cheapest fix in either tool, and it must not wait for `SYSPARM` — adding that
later does not help anyone who mistyped it in the meantime.

### 9 · #86 — nine diagnostic recorders drop everything past 128 entries

200 undefined opcodes in one module report 128 and state the truncated number as
fact. #85 already fixed this for the continuation recorder after nsf370 hit it and
established the shape — count every diagnostic whether or not it is printed,
derive the severity from the counters, bound only the printed list, and say what
was dropped. Nine recorders to go, worth one pass with a shared helper rather than
nine copies. In one of them (`note_operr`) the cap can also mis-state the severity.

### 10 · #35 — the attribute apostrophe, and the lockstep it imposes

`parse()`'s operand tokenizer toggles string state on every apostrophe with no
attribute-operator exception, so `L'SYM` opens a string that never closes and the
trailing comment is absorbed. Historically harmless, and every *other* scanner in
as370 already special-cases it.

**The lockstep is the point.** #32's `has_overlong_term` was deliberately written
to mirror the buggy tokenization, and #34 disclosed the false negative that
buys. Whoever fixes `parse()` must update `has_overlong_term` in the same change,
or it either resumes false-positiving on comments or stays blind to attribute-ref
over-length symbols.

### 11 · #23 — the corpus gate has an oracle-shaped hole

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
| 1 | #8 | warn when autocall resolves a symbol several members define — the cheap half, and it catches the exact httpd failure at link time |
| 2 | #99 | have weak externals right first; the whole direction rests on them (rank 1 above) |
| 3 | `libc370#159` | collapse `@@crt0`/`@@crt1` with a weak `CTHREAD` reference — the pattern the same file already uses for `@@STKLEN` |
| 4 | #107 | `--entry` seeds autocall, so the CRT moves inside `libc.a` and mbt's four near-identical link recipes collapse |
| 5 | #10 | the weak `__premain()` hook in libc370; then this issue closes |

Steps 3 and 4 are independent of each other and of 5. Only 5 really wants 2 done
first.

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

## Loud gaps — nothing silent about them

Ranked below the whole list above for that reason alone, not by size.

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
  *not* for macro calls. It also carries the open severity-4 return-code question:
  as370 has no severity-4 path, and any non-zero RC is fatal to `make`, where
  IFOX00's RC 4 was tolerated by `COND=(8,LT)`.
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
  tools (`objdump370`, `nm370`, `iebcopy370`, …) and the proposal to extract
  `libobj370` / `libmvs370` from the format logic duplicated across as370, ld370
  and file370. It is not open work and is deliberately not ranked here; it is the
  next-project conversation, and it needs a decision before it becomes one.

## Cross-repo

This file is cc370-only, and the entry-point work is not. Its libc370 half is
`mvslovers/libc370#159` (the CRT variants) and, once #99 is in, the `__premain()`
hook that closes #10. Do not rank those here; the sequence table above is the
place that keeps them in step.
