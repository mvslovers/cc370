# cc370 — Open Work, Ranked

**State lives on GitHub, not here.** `gh issue list --repo mvslovers/cc370` is
the source of truth for what is open, closed or newly filed. What this file adds
is the part the tracker cannot hold: the **order**, the reason for it, and which
items wait on a decision rather than on code.

**It carries nothing that is copied.** Where a chain of reasoning already has an
owner — the issue thread, the PR, a reference document — this file points at it
and stops. A copy of a tracker is wrong the first time someone closes something,
and the only defence that works is to hold nothing worth going stale.

*2026-09-12 — `as370 == IFOX00` stands at **5,433 of 5,528 (98.3 %)** at
`1146d58`, 96 modules still differing; #364 took the last one in `SYS1.LPALIB`
that was ours rather than the source's — the largest target library, 2,343
CSECTs, and of its 2,061 CSECTs carrying a finding that was the only place the
two assemblers disagreed. **And `mvs38src` now quotes a second number over a
narrower population — 4,590 of 4,595 — which is not this one and does not
contradict it**: it excludes the 933 modules whose IFOX00 reference came from a
run IFOX00 itself abandoned above severity 4, on the ground that a *case* needs
a diagnosable reference. This file's number deliberately keeps them, because
reproducing a flagged run's deck means reproducing its error behaviour. Both are
right and neither may be quoted for the other's population; their
`docs/cc370-cases.md` says so from the other side. Last reconciled against the
tracker: 2026-09-11 — `as370 == IFOX00` stood at
**5,431 of 5,528 (98.2 %)** at `a1b101d`, 97 modules still differing — **and
4,558 of those 5,431 are against a reference IFOX00 produced at rc ≤ 4**. The
other 873 match a deck IFOX00 emitted from a run it flagged (772 at rc 8, 101 at
rc 12). That does not weaken them: reproducing a flagged run's deck byte for byte
means reproducing its error behaviour too, which is the stronger agreement. What
it does weaken is any *distance* verdict on such a module — "closer to" or
"further from" a deck the assembler did not finish is a distance from a broken
artefact, and `mvs38src`'s `tool-diffs.tsv` has marked those `comparable=no` all
along. Quote the split with the number. Two merges
took it there from 5,427: **#359** chained the implicit private-code section
(+3) and **#360** closed **#290** (+1, `IECVHDET`). `mvs38src` ran the tree gate
independently for the second and reported it in the shape this file should use
from now on — *exactly one deck in 5,528 changed, it is `IECVHDET`, and it went
DIFFER to IDENTICAL* — which excludes what `+1` cannot, that something else moved
and cancelled. **The oracle is pinned**: MVSTK5-REF, frozen and proved (2,332 of
2,332 members identical across a shutdown, a restart and a real IFOX00 run), so
reference decks can be captured again. Before that, 2026-09-10 — all 48 open
issues read against `origin/main` at `fd287d3`, one at a time, and every figure
below re-derived on this host rather than carried forward. Twenty-five PRs merged since
this file last looked (#311…#337 on the evening of 2026-09-09, #340…#357 on
2026-09-10) and **none of them was recorded here**. `as370 == IFOX00` stands at
**5,427 of 5,528 (98.2 %)** at `fd287d3` — deck body, END card excluded, 101
modules still differing. For part of the day it read 5,426, and chasing that one
module is the most useful hour in this entry: `mvs38src` had put
`macros/amaclib-live` at the *head* of the `-I` list, and its `IHADVCT` is a
pre-`@ZA40405` level with no `DVCBPSEC`, so as370 correctly reported the symbol
undefined against a macro IFOX00 never used. `mvs38src` `0457a00` moved the
directory to the **end** of the path and the two figures converged; re-measured
here at `fd287d3` afterwards, the reordered path and the baseline path are not
merely equal in count but the **same set of modules**, `+0 / -0`. **Quote the
path with the number anyway** — the same binary produced both, and a figure
without its rule is the one mistake this file keeps making. What the pass found:
**#39 has been closed since 2026-09-08 and led the ranking through two
reconciliations anyway**; **#35 is fixed** and closes on this one; **#110 is
delivered but not finished** and is narrowed rather than closed; **#108 is closed
and still sits in the loud-gaps band below**; and eleven open issues — #160,
#184, #193, #199, #229, #241, #258, #272, #333, #342, #345 — had never been
mentioned in this file at all. Before that, 2026-09-09 — thirty PRs merged that day
(see the two 2026-09-09 entries in *Recently landed*) and twenty-three issues
filed, of which #290, #297, #305 and #307 name mechanisms rather than
populations. `as370 == IFOX00` stands at **5,379 of 5,528 (97.3 %)** at
`b799ae0`, and every one of the 5,528 modules produces a deck. Before that,
2026-09-08 — five PRs merged that day (#212, #214, #216 carrying two commits,
#219), and six issues filed (#209, #210, #211, #215, #217, #218). Before
that, 2026-09-06, second pass — five PRs merged
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
top class, "has already shipped broken code" breaks the tie. It ranks *defects*.

**The tie-break is spent.** It picked #39 for a year and #39 closed on
2026-09-08; no open issue now has a shipped instance behind it. What replaces it
is the weakest ordering that is still defensible, and it is worth saying out
loud so the next reader can argue with it: inside the top class, **a defect whose
wrongness can be read off the source alone** outranks one that needs a
measurement to establish, and a defect **nothing is waiting on** outranks one
parked behind a decision. That is why a reproducing single case (#26) now leads a
twenty-module population (#241) — the first was re-run today and is wrong in
front of you, the second is nineteen-twentieths unattributable.

---

## The order

| | Issue | Tool | Kind | Waiting on |
|---|---|---|---|---|
| 1 | #97 | as370 | silent — a different object module | nothing |
| 2 | #104 | as370 | silent — a swallowed build option | nothing |
| 3 | #342 | as370 | silent — a DSECT symbol recorded absolute | nothing |
| 4 | #362 | as370 | silent under-reporting — 155 `USING` operands | nothing |
| 5 | #89 | as370 | silent — a wrong value in the deck | **one corpus measurement** |
| 6 | #100 | ld370 | silent — inverted attribute default | **a decision**, after one survey |
| 7 | #86 | as370 | silent under-reporting, ×11 recorders | nothing |
| 8 | #184 | as370 | silent under-reporting — three scans left | **a separating construct** |
| 9 | #241 | as370 | silent — twenty modules, one of them readable | nothing |
| 10 | #23 | tests | the gate that would have caught most of this | **a decision** (where decks come from) |

**#37 left the table on 2026-09-12** (PR #368, open). Its own header here —
*the AC does not survive `--pack`* — was a mis-description, and measuring it is
what showed that: the AC **does** survive a bare pack when the flag is repeated
there, which is how libc370's authorized probes are built. The half that cannot
be repaired from the command line is the **entry point**, and `--entry` was
being accepted and silently dropped by `--pack` on top of it. See the entry in
*Recently landed*.

Eleven: **#26 closed on 2026-09-11**, fifteen hours after this file put it at
rank 1 — and the split that preceded it is the entry worth reading, because the
reason for it was wrong twice before it was right. **#362 moves UP to rank 5**,
not because it grew but because measuring it showed what it is: 155 `USING`
operands, not a diagnostic detail. **#290 leaves on 2026-09-11**, closed by #360 — it entered this table on
2026-09-10 and was the first item the ranking produced work for. #39 and #35 left
before it; #342, #184 and #241 arrived because this file had never listed them.

**#56 was written into row 1 of this table during the pass and taken out again**,
and the reason is worth keeping rather than quietly deleting. `opc_table.h:134`
records `BRXH`/`BRXLE` as `F_SI`, which is not their format — they are RSI — and
that reads exactly like silent wrong output. It is not, because **`BRXH` is not
an Assembler XF statement at all**: it is ESA/390, and X'84'/X'85' on S/370 are
`WRD`/`RDD`, which the same table also carries at `F_SI` and which *are* correct.
So the defect is real but its shape is different — as370 accepts two mnemonics
IFOX00 rejects and invents an encoding for them, which is the precise thing the
comment ten lines above forbids for `TPROT` and `IPTE`. A defect with no
plausible caller on this target does not outrank one that is reproducing. It
belongs in the loud-gaps band, with #56, and it is recorded there.

**Ahead of all of it, agreed with `mvs38src` on 2026-09-06 and the only part of
this file that is a joint plan rather than our own ranking:**

| | Issue | Why here |
|---|---|---|
| A | ~~#141~~ | **Fixed on `fix/as370-open-code-setc`; the `mvs38src` tree-wide gate says go — 844 → 874 modules byte-identical to IBM's object, none lost.** Substitution in open code, the model/generated listing pair, and `IFO115`/`IFO116`/`IFO117` from `eval_setc` so the macro path reports too, which is where the issue's named case lives. **Read the credit correctly: 29 of the 30 new identities belong to the `&&` commit, one (`HMBLKXRF`) to #141 itself** — and 16 of the 30 came out of the *length* bucket both projects had written off as blocked on macro provenance. The two module counts in the thread disagree because the baselines do: 33 moved decks and 32 newly assembling are the #141 commit alone, 63 and 33 are the whole branch. The `52 modules / 13 assembling` figure is **withdrawn at source** — there was never a list behind it; `mvs38src`'s rebuilt scan says 258 / 148, and my own 67-68 undercounts for want of continuation joining. Their write-up: `docs/opencode-gate.md`. |
| B | **#140** | The silent-success class: modules where IFOX00 flags and as370 does not. **Re-derived at `fd287d3` from the recorded IFOX00 return codes: `as370 alone flags` is 0, `IFOX00 alone flags` is 5** — `IBCDASDI`, `IBCDMPRS`, `IEAVEXS`, `IEAVRTI0` at severity 8, and `BLSR3270` at severity 4. The issue's headline count of four is still exactly right; the fifth is the severity-4 module the thread already knows about. It is larger than the five, and #165 proved how: 48 modules were returning rc 0 with a wrong deck from the `IPK`/`PTLB` defect alone, and only a *byte* sweep could see them — a rc-based gate cannot. **`dc_split` is measured and closed** (#218): it read every apostrophe as a string quote, so `DC AL1(L'FLD),X'FF'` dropped the `X'FF'` — at rc 0, and **IFOX00 assembles the same statement at rc 0 with no diagnostics either**, which is the cleanest argument in this file for why the deck is the instrument. `EQU` (`:3413`) and `SYM+(expr)` (`:761`) remain suspected and unscoped. |
| C | **#109 adoption** | as370, ld370 and ar370 onto the `obj370` readers. **Re-read at `fd287d3`, and the acceptance list in the issue is now literally satisfied while the work in its title is not**: all six tools compile with `-Icommon/include` and link `common/src/{mvs370,obj370}.c`, so "they build against the library" is true and says nothing. What is actually left is four reader sites — ld370, ar370 and file370 still carry their own ESD walk. A refactor that must change nothing, so it wants the sharpest available measurement: `mvs38src` has agreed to run the tree-wide gate as acceptance, **one tool at a time**, so a divergence names the tool. |
| D | **Paket A — closed except #184** | The 2026-09-07 hand-over was eleven issues, one per diagnostic class, each measured by assembling all 5,528 `MVSBLD` modules twice — as370 here, the real Assembler XF under MVS/CE, same source and same seven macro libraries. **Ten of the eleven are closed**; #153, #154, #155, #157, #158, #159 and #161 each ended on a re-derivation that measured its own class at 0 or 1. What is left is **#184**, the attribute apostrophe in the three scans that decide *diagnostics* rather than bytes — PR #347 says in its own body that it does not close it. The decks are recorded, so the gate runs on this host in about 90 seconds per binary (`mvs38src/tools/gate.sh` + `retest.py`); no MVS, no waiting on the other session. Read the class files as *populations*, not as causes: they overlap, and most of what looks like a cascade is not. |
| E | **Paket B — #160, #193, #199, #241** | The four population issues, none of which this file had ever listed, and all four re-derived in this pass. **They shrank:** #193 is 2 → 1, #199 is 3, #160 is 3, #241 is 20 under one counting rule and 33 under another. What they now share is the thing that decides whether any of them is workable: **nineteen of #241's twenty, and the survivor of #193, have reference decks from IFOX00 runs that ended at rc 12** — a deck an assembler did not finish is not an oracle. The band's real question is no longer "what is the mechanism" but "which of these has a witness at all", and for #241 the answer is one module, `BLSR3270`. |

`#117` and `#118` do not touch that consumer today — they upload over FTP and
xmit370 is not in their chain. **At their M7 it changes**: `++PTF`/`++USERMOD`
are to go out through `xmit370` and be received with `RECV370`, and #118 is then
a silent defect with their name on it. Build it before M7, not now.

Thirteen, not ten — and two of the ten had already gone: **#13 closed
2026-08-30, #99 on 2026-09-04, #39 on 2026-09-08, and #35 closes on this pass.**
See *Recently landed*.

**The three issues this block used to carry are down to one.** #148, #149 and
#151 were all filed while fixing #141, all silent, all found by a gate rather
than by reading — and #149 and #151 both closed on 2026-09-09/10 on their own
re-derivations. What is left of that family is #184, which is ranked above, and
one listing item:

- **#150** — an **in-stream** macro definition is not listed, so every statement
  after one is numbered short by the number of cards it held. Listing-only, but
  the statement number is what a diagnostic is addressed by. **#233 was filed a
  day later from a different fixture and closed as a duplicate of this one**, so
  #150 is the canonical record and carries the scope note that decides how a fix
  is tested: `NOLIBMAC` is the default and IFOX00 does not list a library macro
  either, which is why `listref` case 1 compares clean — in-stream definitions
  only. It is the reason `tests/sysparm_substr.s` is checked on its deck rather
  than as a `listref` case.

**What #149 left behind is worth keeping, because it is the rule for #184.**
The three attribute-apostrophe letter sets in as370 are not all one bug, and the
oracle says so: `dc_split` took `KNLT` deliberately, because IFOX00 reads `S'`
and `I'` in an ordinary expression as an opening quote and answers `IFO035
QUOTES NOT PAIRED` (measured). The narrow set is right for a `DC` operand and
the wide one for a card scan, where conditional assembly also passes — they
differ **by context**. What remains wrong is the `E`: IFOX's own set is
`T L I S N K` (`ifnx1a.asm:4862`) and `attr_apos` carries `LTKNISE`.

Below the line, in bands rather than ranks: **the entry-point work** (#8, #107,
#10 and `libc370#159` — decided, sequenced, and spanning two repos), **the format
library and the tools on it** (#109 adoption left; **#110 delivered but narrowed,
not closed**; #111, #112, #113, #117, #118 open — the only band with an outside
consumer), **loud gaps** (#56, #76, #78, #101, #102, #103, #128, #211, #229, #297 —
**#108 closed on 2026-09-06 and should have left this band then**), **populations**
(#160, #193, #199, #241), **observability** (#9, #106, #345), **listing
fidelity** (#24, #28, #91, #150), **conditional assembly** (#258, #272, #333),
**deferred** (#36). `&&` folding moved from the substituter to the DC scanner
en route to #141 (`6d235db`): the two paths had contradicted each other at `rc=0`
since as370 existed, and the two defects cancelled, so 950 modules of deck
byte-identity could never show it.

**Correction to that commit's own message, which cannot be amended now it is
merged.** It reports "258 of 5528 modules contain `&&`; of the 82 that assemble,
39 move". The candidate list behind those figures was built with the shell's
`grep`, which in this environment resolves to a wrapper that returns **nothing at
all** on MVSBLD's 80-column CRLF members — no output, no error, no zero.

The right figure is **144**: modules with `&&` in a *code* card, which is also
exactly the set with `&&` in *open code*. A first replacement of 1124 counted
comment cards too and was wrong in the other direction — a `&&` in a comment
cannot reach the object deck. Two artifacts, one four times low and one eight
times high, around a number neither of us had measured properly.

Movement, from `mvs38src`'s tree-wide gate: **71 of the 144 moved, and the 144
contain every one of the 29 identities the commit gained.** Not one gainer falls
outside it.

**That last line refutes something written here first.** The note used to say a
candidate list can only subtract and that one should never scan before measuring.
Against the `&&` list that is plainly false — half of it moved and it captured
the gains completely. The distinction that survives is `mvs38src`'s: **`&&` is a
lexical fact of the card**, present or absent, and nothing between the card and
the deck can hide it; a variable-symbol reference is only the *start* of a value
flow, and `BLSR3270` shows what that flow crosses — fourteen `COPY` members and a
`GBLC`. So: **scan where the defect is lexical, measure the tree where it is
not.** The scepticism about the `--mode emit` scan holds; the general claim did
not.

---

### ~~1~~ · #37 — a bare `.lm` pack loses the entry point, not the AC — **PR #368, open**

*half of this issue did not reproduce, the half that did was silent, and naming
it "the AC" was wrong in a way only measuring it could show*

**The driver half is gone, and it was measured rather than assumed.**
`-Wl,--ac,1` does reach ld370 at `fd287d3` — `-###` shows `"--ac" "1"` in its
argv, and the two real links produce xmits that differ (`AC=1` against `AC=0`)
while the bare members stay byte-identical. That last clause is the trap the
report fell into: a bare `-o OUT` member carries no directory and therefore no
attributes at all, so comparing members can never show an AC. The same
member-versus-directory reading is what the thread already corrected once, for
the `--norent` observation.

**What still reproduces is `--pack` on a bare `.lm`**: it packs at `AC=0`, rc 0,
no diagnostic, where the same module packed from its `-iebcopy` form carries
`AC=1`. `build_userdata()` keeps a packed member's *complete* PDS2 user-data
verbatim — entry, modlen, AC, RENT/REUS/REFR — since 2026-06-23, but only for the
self-describing `-iebcopy` input. So the fix is not "carry the AC over"; it is to
stop the bare-`.lm` path from looking like the `-iebcopy` one: say so when a bare
`.lm` is packed with attributes that cannot survive, and put the two-step
workflow in the usage text, which at `ld370.c:1581` still does not mention
`--ac` at all.

Why it costs a cycle rather than a minute: an unauthorized module is
indistinguishable from an authorized one until it runs, and then the first
`MODESET KEY=ZERO` ends the step **S047** with an empty SYSPRINT, because stdio
buffers are lost with the unclosed DCB. The symptom is "no output and an abend",
with nothing pointing at the link step. It cost two deploy cycles.

**Measured 2026-09-12, and the paragraph above needs one correction of its own.**
`--ac`, `--norent` and `--noreus` given on the *pack* command **do** reach a bare
member — `build_userdata()` applies them on exactly that path — so "attributes
that cannot survive" was too broad, and a diagnostic saying it would have been
wrong for libc370's own probe recipes (`jcl/tstracau.jcl:26`), which pack a bare
`.lm` with `--ac 1` and work. The **entry point** is the half that is genuinely
unrecoverable: two links differing only in entry point produce **byte-identical**
bare members over three trials once the IDR link-time stamp at `0x127..0x128` is
masked, and the entire difference is two directory bytes (`PDS2EP0`, `PDS2EPA`).
And `--entry` was the same defect one flag further along — the parser accepts it,
the `--pack` block returns before entry resolution, so `--pack --entry NOSUCHSY`
packed at rc 0 in silence.

### 2 · #97 — an undeclared SET symbol produces a different object module

The risk of enforcing it was measured before the issue was filed and it is nil:
an instrumented build found **0 modules** with an undeclared SET symbol across
826 ecosystem modules and 277 real IBM ones. Nothing relies on the leniency.

Two halves, and the first is worth doing alone: the *diagnostic* is a check at
`SETA`/`SETB`/`SETC` and at the reference site. The *code effect* — IFOX leaves
the reference unsubstituted and the statement generates nothing — is the larger
half, because the substitution path has to distinguish "undeclared" from
"declared but null", which today it does not.

### 3 · #104 — an unrecognised option becomes the source filename

The argument loop ends in `else src = argv[ai];` with no validation, so a typo,
an option from a build script, or an IFOX00 option as370 does not implement is
silently swallowed. Measured: `as370 --sysparm=DEBUG` returns rc 0 and assembles
the *production* branch of an `AIF ('&SYSPARM' EQ 'DEBUG')`, because `&SYSPARM`
is not implemented either. The caller gets a production build believing it is a
debug build.

Cheapest fix in either tool, and it must not wait for `SYSPARM` — adding that
later does not help anyone who mistyped it in the meantime.

### 4 · #342 — a symbol from a macro-generated DSECT is recorded absolute

In `IEDQWIE` a symbol defined inside a DSECT that a macro generated comes out
absolute rather than relocatable, so an SS operand written with an explicit
length loses its base register. Filed 2026-09-10 and unchanged at `fd287d3`.

It sits this high because no measurement is owed before the work can start: the
mechanism is one bookkeeping decision and the witness is a single named module.
Everything below this line in the top class is waiting on something.

### 5 · #362 — the relocatability rule is not applied to `USING`

*measured into a different issue than the one that was filed*

IFOX00 raises `IFO217` on **155 `USING` operands** in the corpus and as370 raises
nothing. It was filed as a diagnostic that never fires, and both things measuring
it established are larger than that.

**It is a `USING` defect, not an instruction-operand one.** Classifying every
`IFO217` statement by kind gives 155 `USING` against roughly ten machine
instructions. #363 supplies the classifier and the zeroing and hooks the
instruction path, so it cannot reach any of the 155 — which is why #363 closed
#26 and left this untouched. *(Crude extractor: the 155 dominates, the tail is
misalignment and should not be quoted.)*

**One check covers both statements, and that was the open question.** Every
corpus site has an undefined *and* a potentially complex operand at once, so the
corpus cannot say which draws the message. `tests/usingreloc.s` can: a `USING`
whose operand is **defined** but relocatable across a multiply flags anyway
(`MVSTK5-REF JOB00036`). The rule genuinely applies on the `USING` path, so the
work is to reach it rather than to invent a second rule.

**And the message is chosen by the statement, not by the expression.** On a
`USING`, IFOX00 answers `IFO217` for everything — including the two-section sum
that gives `IFO213` in a machine operand. A fix reusing #363's classifier
unchanged would put `IFO213` there: right severity, right behaviour, wrong
message, and **nothing could catch it** — `IFO213` appears in 0 of the 926
recorded corpus diagnostics.

The 75 modules stay at rc 8 against IFOX00's 12 until this lands, and all 75
already have byte-identical decks, so the return code is the only thing that will
move.

### 6 · #89 — a forward reference in EQU resolves to 0

`A EQU B` before `B EQU 4` gives `A = 0`, RC 0, no diagnostic, and pass 2 does not
repair it — the wrong value reaches the deck. IFOX00 flags IFO188, the message
#82 just implemented everywhere else; #82's recorder is gated on pass 2 and has to
be, so it cannot cover this.

**Measure first.** Whether any ecosystem module relies on a forward EQU is not
known — the #82 probe counted pass-2 lookups only and says nothing about it. A
corpus that quietly depends on this would move decks.

### 7 · #100 — every module is marked RENT+REUS, IEWL marks neither

*the decision is which default*

The PDS2 template hardcodes `0xC3`, and `build_userdata` only ever *clears* those
bits. IEWL zeroes both attribute bytes before PARM processing (`NI PDSE7,ZERO` /
`NI PDSE8,ZERO`, with `ZERO EQU 0`) and sets RENT/REUS only from the option table
when the PARM asks — verified in the source, not inferred. A false RENT is not a
label but a promise the loader acts on: the module may be placed in the LPA and
shared across address spaces, which makes this the one finding in the group that
corrupts storage across address spaces rather than within one module. rexx370
already needs `--norent`, so the case is live; today it depends on remembering the
flag per module, and forgetting is silent.

Whoever touches `build_userdata` should read #37 in the same sitting — #37 is
about a value that never arrives, this is about a default that is wrong when
nothing arrives — and `REFR` is worth four more lines while in there (another
`PDS2ATR1` bit with no control at all).

**Two open points.** The decision: invert the default to match IEWL, or keep it
and *require* an explicit `--rent`/`--norent`. And the survey that sizes it —
mbt v2 links every ecosystem module through ld370, so how many of them actually
want RENT decides whether inverting is a one-line change or a sweep across every
`project.toml`. Do the survey before the decision.

### 8 · #86 — the diagnostic recorders drop everything past 128 entries

200 undefined opcodes in one module report 128 and state the truncated number as
fact. #85 already fixed this for the continuation recorder after nsf370 hit it and
established the shape — count every diagnostic whether or not it is printed,
derive the severity from the counters, bound only the printed list, and say what
was dropped.

**Two corrections from this pass.** The count in the title is **eleven**, not
nine: `note_mnote` (`as370.c:3709`) is a twelfth recorder of the same shape and
was never listed. And the issue's own demonstration — *"128 reported and stated as
fact"* — was **fixed by #88** on 2026-08-29, which added `mark_flagged` /
`stmt_flagged` so the flagged count no longer comes from the printed list. The
defect that remains is the shared-buffer cap itself and the silence about what it
dropped; the sentence that demonstrates it needs replacing before the issue is
quoted. In one recorder (`note_operr`) the cap can also mis-state the severity.

### 9 · #184 — the attribute apostrophe, in the scans that decide diagnostics

*the last live member of the #35/#149/#218 family, and the one PR #347 says it
did not close*

Nineteen apostrophe toggles exist in as370; twelve carry the quote-state guard
and seven do not. Four of the seven were measured clear by #347 — it fixed the two
that were demonstrably wrong and said in its own body that **three sites remain**:
`scan_undef_terms()` twice and `undefined_term()`. They decide *diagnostics*, not
bytes, which is exactly why a deck-based gate cannot see them and why this is
under-reporting rather than wrong output.

**What it is waiting on is a construct, not a decision**: a source that separates
a correct diagnostic from a suppressed one on those three paths. Until one
exists, a fix here is unfalsifiable by every instrument this project owns — the
tree gate included.

### 10 · #241 — twenty modules longer than IFOX00, one of them readable

*the largest remaining population, and the number depends on which length you
count*

Re-derived at `fd287d3` over the 102 decks that still differ, with both rules
written down because they disagree:

| rule | as370 longer | delta a multiple of 8 |
|---|---:|---:|
| section text extents rebuilt from the TXT cards | 33 | 3 |
| declared `SD`/`PC`/`CM` lengths on the ESD cards | 20 | 10 |

Nothing goes the other way: no module lays out *fewer* bytes than IFOX00. Neither
figure contradicts the 36/4 recorded on the issue — that was ten merges earlier
and **its rule was never written down**, which is the whole reason two correct
counts can look like a contradiction.

**Nineteen of the twenty have no oracle behind them.** They are `IFCE*`/`IFCS*`
at IFOX00 rc 12 plus `IEAVEXS` at rc 8 — a deck the assembler did not finish is
not a reference. The one that did finish is `BLSR3270`: `+8` on section
`BLSR327A`, IFOX00 rc 4, as370 rc 0, first divergence at `0x00513`. That is the
whole workable surface of this issue today, and it is one module.

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

**Half of this question is now answered from outside.** `mvs38src` assembles a
module on the guest with the real IFOX00 and diffs the two decks directly, which
separates *does as370 assemble like IFOX* from *does the source match the
shipped object* — a DLIB comparison alone conflates them. Two rules that
comparison needs, both measured: exclude the END card (each assembler stamps its
own translator id) and compare columns 1–72 only (73–76 is the card sequence
number, and ignoring that produced a false alarm on all five cards of one
module). Both sides must also see the **same macro libraries**, or the diff
attributes nothing to anyone. That is what found #138 — and on 2026-09-10 it
cost `IGC018` and then earned it back: a macro path corrected on one argument
handed as370 an older `IHADVCT` than the oracle had used, and one identity moved
for reasons that have nothing to do with either assembler. **What settled it is
the rule this whole band rests on** — the decks decide, not the search order.
IFOX00's own diagnostics for that module flag `DVCMODU` and `DVCUFIX1` undefined
and say nothing about `DVCBPSEC`, and only one of the three `IHADVCT` copies on
the path has that profile. A claim about which library an oracle read is
answerable from what it produced, and answerable from nothing else.

**And it is available as an acceptance gate, not only as a report.** The decks
are recorded, so it runs on this host in about 90 seconds per binary
(`mvs38src/tools/gate.sh` + `retest.py`) — no MVS and no waiting on the other
session. Ask for it per tool rather than per branch, so a divergence names the
tool. That is the right gate for any change that is supposed to alter nothing —
the 743-module corpus here is our own output and has been structurally blind
to whole classes: the scatter record, the resumed section, the base-register
tie, and every `T'` defect moved none of it.

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

**Re-read at `fd287d3`, and one thing about #109 needs saying before the rest is
read: its Acceptance list is now literally satisfied while the work in its title
is not.** All six tools compile with `-Icommon/include` and link
`common/src/{mvs370,obj370}.c`, so *"as370, ld370 and file370 build against the
library"* is true and measures nothing. What is actually left is four reader
sites — ld370, ar370 and file370 still walk an ESD of their own. An acceptance
list that a half-done change passes is worth rewriting, and that is the one edit
this issue needs.

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
| #110 | — | `cmplmd370` — **built and accepted, and still open on one behaviour** (#122, #123, #124). Compare, `--clearrld`, `--csect`, `--difin`/`--difout`, `--json`, hole classification all work; `--difout` does **not** merge `--difin` forward, so a reviewed run cannot seed the next one — the property the issue asks `--difout` for. Worse, `--difin acc --difout acc` on a converged comparison leaves `acc` **zero bytes**: `difin_load()` runs before the output file is opened, and an identical section writes nothing. That is data loss in the obvious usage, and it is why this stays open |
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

**#108 left this band on 2026-09-06** — `DC S(…)` / `DS S` were implemented by
#130 and the issue closed the same day; it stood here through two reconciliations
afterwards.

- **#56** — the IFOX00 opcode gaps, and it is now two different things.
  **The half that landed:** `BNPR`/`BNMR` were added by #299, which closes #298 —
  filed separately out of the `Undefined operation code` cluster, which is why
  this issue stayed open while its work was done. **The half that is still a
  loud gap:** `enum fmt` has no SSE and no RRE, so `TPROT` and `IPTE` are rejected
  at rc 8; the exclusion is deliberate, written down at `opc_table.h:183` and
  asserted by `tests/run.sh:1065`, because a fabricated encoding turns a clean
  RC 8 into silently wrong bytes. **RRE is worth more than `IPTE` alone** — it is
  also the format a good part of the Hercules S/370-extension set needs.
  **And a third thing, found in this pass:** `opc_table.h:134` carries `BRXH` and
  `BRXLE` at `F_SI`, which is not their format — they are RSI. `BRXH 2,4,T`
  assembles to `8404 0002` at rc 0. It is *not* the silent-wrong-output it looks
  like, because `BRXH` is ESA/390 and Assembler XF does not know it at all: on
  S/370, X'84'/X'85' are `WRD`/`RDD`, which the same table carries correctly.
  What it is, is the table breaking its own stated rule — an invented encoding
  for a mnemonic IFOX00 rejects, ten lines below the comment that refuses exactly
  that for `TPROT`. Either drop the two rows or give them RSI; do not leave them
  encoding as something else.

- **#229** — `COM` gets no `CM` entry in the ESD and does not reset the location
  counter, so a common section is neither declared nor addressed. Adjacent to
  #76's `DXD`/`COM` message-class note and worth doing with it.
- **#297** — a macro prototype may take a machine mnemonic's name and as370
  assembles it in silence; IFOX00 answers `IFO043` at rc 12. Loud on the oracle
  side, absent on ours.
- **#211** — a CCW whose data address names a DSECT symbol draws no `IFO158`,
  though the `DC` path already does. The check exists; one call site does not
  make it.
- **#128** — `ISEQ` is recognised and does nothing. **Read the title with care: it
  says "not implemented (25 modules)" and that is no longer what is open.** PR
  #129 landed the operand parse, the column range and the disable form and its own
  body says what it did *not* do — raise `IFO025` on an out-of-sequence card. So
  the gap is the check, not the statement, and it is diagnostic-only either way.
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
- **#345** — `-am`, the macro and copy code source summary, is accepted on the
  command line and produces nothing. It is the only instrument that says which
  library a macro came from — which is exactly the question `IGC018` turned into
  a lost identity on 2026-09-10, and exactly the question a second macro-path
  argument will ask again. Filed 2026-09-10; new, and better placed here than
  among the listing options it looks like it belongs to.
- **#106** — the translator IDR is dropped on the floor. Split out of #13:
  a genuine IEWL member carries three IDR records and ours carries two, so
  `AMBLIST LISTIDR` cannot say which assembler produced the code. as370 already
  writes its identity into every END card; ld370 does not read it. One field, one
  21-byte record, one flag byte — and the fixture oracle settles the layout.
## Listing fidelity

All five are cosmetic, and the first three are pinned rather than hidden — each
was found while building a `listref` case, and each is excluded from that case
*with a reference to its issue* instead of being silently masked.

- **#24** — DS inside a DSECT renders with the enclosing CSECT's LOC and stale
  object-code bytes. **Half of it is fixed and the issue does not say so**: PR
  #230 (closing #227) gave `DSECT` its own counter, so the LOC half is right at
  `fd287d3`. What survives is the object code — a `DS` in a DSECT body still
  prints bytes from the enclosing section. Two rows of `listref/README.md` are
  stale for the same reason.
- **#28** — LTORG renders at the pre-alignment LOC, and literal-pool entries are
  numbered out of source order.
- **#91** — a library-member continuation diagnostic cannot be reconciled with the
  statement it belongs to, so the flagged count can be one too high. The printed
  count only; RC, bytes and listing are unaffected, and **0 of 835 ecosystem
  modules** produce one at all. The residual is pinned as a tripwire in
  `flagged_libmac`, so implementing it fails that case and brings whoever does it
  to the number that has to change.
- **#150** — an in-stream macro definition is not listed, so every statement after
  one is numbered short. The canonical record of the defect #233 duplicated; see
  the block under *The order*.
- **#199** — three modules whose object image matches IFOX00 exactly and whose
  *deck* does not, both assemblers silent. Re-derived at `fd287d3`: still three.
  PRs #200 and #206 each say in their own bodies that they address a part of it,
  and the split the 2026-09-08 comment predicted — a card-layout issue separate
  from an ESD-numbering one — is still on the table rather than made.

## Conditional assembly — three that behave, and one that has to be decided

Filed 2026-09-09/10 out of the macro-language work and never listed here.

- **#258** — `S'` and `I'` are not evaluated in conditional assembly. Note the
  context rule above before fixing it: IFOX00 treats `S'` in an *ordinary*
  expression as an opening quote, so the letter set is not the same on both
  paths.
- **#272** — an expression outside conditional assembly is not held to 20 terms;
  IFOX00 raises `IFO168` and zeroes the result. Wants a corpus measurement before
  it is worth doing — a limit nothing reaches costs a check on every expression.
- **#333** — `T'` of a macro parameter answers from the parameter's *value*;
  IFOX00 answers from what was written at the call site. **The defect reproduces
  unchanged and its decision does not stand**: the withdrawal comment rests on a
  `-70 LOST` measurement, and that figure is now known to be an artefact of the
  run it came from. Re-derive before quoting it either way.

## The five cases — `mvssrc`'s cut, and the smallest is first on purpose

`work/measurements/cases-for-cc370.tsv` in `mvs38src`, produced by
`tools/case_list.py` so it can be re-cut after any merge. Stamp differences are
masked inside the comparison, and the 933 modules whose reference came from a
run above severity 4 are excluded — see the population note at the head of this
file before quoting the denominator. Over the 4,595 that remain, the two
assemblers agree on 4,590.

| | module | cards | differing | first | rc as370/IFOX00 |
|---|---|---|---:|---|---|
| 1 | `IFNX2A` | 105/105 | **2** | 49 TXT | 0 / 0 |
| 2 | `IFNX4M` | 65/65 | **2** | 61 TXT | 0 / 0 |
| 3 | `IFFAHA16` | 76/76 | 5 | 70 RLD | 0 / 0 |
| 4 | `BLSR3270` | 156/156 | 88 | 0 ESD | 0 / **4** |
| 5 | `HMASMTMD` | 275/**274** | 270 | 4 ESD | 0 / 0 |

Smallest first, and that ordering is the lesson from #364 rather than a
convenience: a two-card difference in a module nobody has opened is where a
mechanism gets found, and `IGARPT01`'s 94 bytes turned out to be a whole
evaluator path.

**Measured the same day, and the list contains no new mechanism at all:**

| | module | what it actually is |
|---|---|---|
| 1 | `IFNX2A` | **not a case** — the assembly TIME in the module's own text |
| 2 | `IFNX4M` | **not a case** — the same |
| 3 | `IFFAHA16` | **#366**, fixed and merged — RLD order inside an `(R,P)` group |
| 4 | `BLSR3270` | #140's severity-4 module; its reference is the weakest here |
| 5 | `HMASMTMD` | #199's ESD half, already open and named in that issue |

`IFNX2A` and `IFNX4M` carry an eyecatcher built from `&SYSTIME`, and the gate
pins one `ASMTIME` for all 5,528 while IFOX00's runs had real clock times. Give
each its own — `03.38` and `03.31`, from `state.tsv`, the same figure
`ifox_compare.py` already uses — and both decks are byte-identical with nothing
else changed. **The class is larger than those two: of the 95 modules whose
decks still differ, 38 become byte-identical when re-assembled with the clock
their own IFOX job ran at**, all of them `IFNX*`, `IFOX0*`, `BLSD*`,
`IFCDIP00`, `IFCIOHND` and `IGC0007F` — `IFOX0A`–`IFOX0I` being IFOX00 itself,
which stamps its own assembly time into its eyecatcher. The date is `09/07/26`
on all thirty-eight END cards — measured, not sampled — and the thirty-eight
jobs started at **29 distinct times**, so the time is the only variable and no
single pinned `ASMTIME` can ever match more than a few of them.

**That is an instrument finding, not an as370 defect**, and it belongs to
`mvs38src`: `case_list.py` and `retest.py` masked the END card's stamp and not
an eyecatcher's, so a module that assembles perfectly read as a case. Reported
and **fixed the same day** — `case_list.py` now re-assembles each candidate
with the clock its own IFOX00 job ran at, and their case list is three:
`IFFAHA16` (merged), `BLSR3270`, `HMASMTMD`. What it means here is that the
honest residue after #366 is **57 modules by this file's count, three by their
stricter cut**, and neither is a ranking of the other.

**A second inequality of the same family, found on 2026-09-12 and NOT fixed.**
`mvssrc` noticed that `gate.sh` passes ten `-I` directories and
`ifox_compare.py` eight — no `erep-set`, no `amaclib-live` — and flagged it
rather than editing a tool under another session's running measurement.
`module-table.tsv`, the table this file reads, comes off `ifox_compare.py`.
Measured here, same binary, both paths over all 5,528:

**33 decks change with the path**, every one of them EREP (`IFCE*`/`IFCS*`),
and no return code changes at all. Scored against the reference:

| | 10 dirs (`gate.sh`) | 8 dirs (`ifox_compare.py`) |
|---|---:|---:|
| card count equals the reference | **9** of 33 | 1 of 33 |
| card count within 2 | **21** of 33 | 2 of 33 |

So the eight-directory decks are drastically short — the EREP macros are
simply not there — and every verdict recorded for those 33 is measured against
an input the oracle did not have. `IFCE33XX` is the sharpest instance: **1
differing card of 97 on the correct path, 61 on the wrong one.** Nothing in
any headline moves, because all 33 have an IFOX00 reference at rc 12 and are
inside the excluded 933 — but their `first_diff` and class in
`module-table.tsv` are not attributable, and any class work that reads that
table must re-measure them first.

**And the direction changed on 2026-09-12: Mike is building his own development
on TSO, so TSO first and SMP second.** `mvssrc` profiled both against TK5's
object before this file could rank anything around it, and the result is worth
more than a ranking would have been — **228 TSO modules (`IKJ*`/`IKT*`) and 109
SMP (`HMA*`), and zero as370 cases between them.** Everything open there is
source work concentrated in two or three years, with SMP's 82 same-length
differences the most tractable block they have found anywhere. `HMASMTMD` above
is the single exception and it is an ESD/card-count case, not a code one. So the
priority does **not** re-rank this file's queue — it tells us where not to spend
time looking. Their profile: `docs/tso-and-smp.md`.

---

## Populations — two left, and the question is whether they have a witness

- **#193** — as370 and IFOX00 choosing different base registers. **2 → 1 at
  `fd287d3`**: `IDA019S6` and `IKJEBELT` are byte-identical, and PR #353's
  fixture settled the tie-break in #138's favour in *both* declaration orders, so
  the issue's premise — that #138's rule is in question — is answered. The
  survivor is `IECVXURT`, whose reference deck comes from an IFOX00 run at rc 12,
  which means the remaining question cannot be tested on it at all.
- **#160** — three sections whose object differs from IFOX00's inside the first
  16 bytes, both assemblers silent. Same three at `fd287d3`. It waits on a
  decision rather than on work: the reference decks are rc-12 runs, and whether
  such a deck is admissible as an oracle is the question the whole band turns on.

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

- **2026-09-12, second — #37, open in PR #368, not yet merged.** `ld370 --pack`
  of a **bare** `.lm` wrote entry 0 and this command's attributes and said
  nothing; it now says so, and packing the `-iebcopy` form stays silent because
  nothing is lost there. `--entry` is fixed with it: the parser accepted it and
  the pack path returned before entry resolution, so `--pack --entry NOSUCHSY`
  packed at rc 0 without a word — and a warning reading *"entry 0"* while that
  flag stayed silently dropped would send the reader straight to the thing that
  does nothing. **A warning and not a refusal, measured rather than cautious:**
  twelve `--pack` sites in `ld370/tests/run.sh` and one in `run_2mem_mvs.py`
  pack a bare member on purpose, every one shaped `if "$LD" --pack …`, and CI
  runs the suite on every push — a non-zero rc fails on the commit that adds it.
  Every production path is already clean; mbt's three sites can only pass
  `build/NAME.iebcopy`. Diagnostics only: eight pack variants and the link path
  byte-identical before and after. The new case is the suite's **first stderr
  assertion** — four of its six assertions fail on the pre-fix binary and two
  are controls that must pass both ways (rc still 0; the `-iebcopy` form silent).

- **2026-09-12 — #364 landed (`e53f404`, PR #365).** A `USING` whose base
  operand is **parenthesised** was valued at 0: `expr_val` reads a leading `(`
  as a machine-operand subscript and returns without evaluating. `IGARPT01`
  writes `USING (IGARPT01+X'4B0'),R15` eight times, every displacement through
  R15 came out exactly the USING constant too high — 94 bytes, same deck
  length, both assemblers silent — and `mvssrc` had it as the **only** case in
  `SYS1.LPALIB` (2,343 CSECTs) where as370 disagrees with IFOX00 rather than
  the source being short of something. The same statement also filed the
  domain under the wrong **section**, because the scan for the base symbol
  stops on that `(` and `""` is the unnamed private code rather than a name;
  that half has no witness in the tree and needed its own module. Reach is one
  module, established lexically over the tree *and* the macro path before the
  fix, so `+1` was a prediction met rather than a number read afterwards. Tree
  gate `5,431 → 5,432, gained IGARPT01, LOST 0, 0 further`; `mvssrc` re-ran it
  on its own tree with a control and reported the sharper form — exactly one
  deck changed, it is `IGARPT01`, and it went **20 differing cards to 0** with
  no masking. Oracles MVSTK5-REF `JOB00306`/`JOB00307` (`00304`/`00305`
  discarded: renumbering a fixture's comment cards invalidates its committed
  listing), macro snapshots either side 2,785 of 2,785 unchanged.

- **2026-09-11, third — #26 closed, and the ranking produced work for the third
  time.** **#363** gave as370 a simply-relocatable check: `L 1,FLDX*2-FLDX`
  assembled to base 0 at rc 0 and a pair spanning two sections to a displacement
  of `x'FE0'`; IFOX00 zeroes the instruction and says which of two things went
  wrong (`IFO217` inside a product, `IFO213` for a complexly relocatable
  expression). Tree gate `+0 / LOST 0 / 0 closer / 0 further`.

  **The fixture passed every version and the TREE caught both defects**, which
  inverts the day's other lesson. Counting relocatable *terms* is not asking
  whether a factor is relocatable — `NOPR ((@ENDDATD-@DATD)*16)` meets two terms
  inside the group, they **pair**, so the group is absolute and the multiply is
  legal. That cost **331 identities**. And a *subtracted* parenthesised group had
  been tallying positively per section since those tallies existed, so
  `IOB-(CHPG1+17)` came to `+2` where the truth is `0`; latent until something
  classified on it, three more identities. Both were invisible to the fixture and
  obvious to the corpus.

  **Three corrections in one day on one issue, each from a measurement.** The
  #26/#362 split was argued as "different code", corrected to "one
  implementation closes both" when the oracle showed IFOX00 zeroes and diagnoses
  from one decision, and corrected back when it turned out every corpus site is a
  `USING` that the instruction path cannot reach. The split stands on the
  evidence argument it was measured into, not the one that won it.

  **CI caught what neither machine did.** `-Wmisleading-indentation` on two lines
  of the new code, red on gcc, silent on clang — and `/usr/bin/gcc` here *is*
  Apple clang. The conclusion drawn at the time, that a local build cannot
  substitute for CI on this project, is **wrong**: `gcc-16` is installed at
  `/opt/homebrew/bin/gcc-16` and `make tools HOSTCC=gcc-16` reproduces the failure
  exactly. The instrument was on both machines and neither of us ran it.

- **2026-09-11, second half — the oracle is pinned and the parked question is
  answered.** MVSTK5-REF frozen, copied with 73 checksums, and proved: 2,332 of
  2,332 members unchanged across a shutdown, a restart and now three assemblies.
  Two captures came off it (`JOB00032`, `JOB00033`) and the snapshot after them
  is 0 changed, 0 gone, 0 new.

  **#361** — a literal blank `CSECT` card resumes the private code, and as370
  restarted on the first card and resumed on every later one. Two behaviours for
  one construct, so it was a defect before the oracle answered; the oracle only
  decided which one to keep. `extrn_csect`'s provisional deck was recaptured at
  the same time and is **byte-identical to the DEV capture outside the END date**,
  so the provisional marking came off having been tested rather than assumed.

  **The gate line on that merge is the entry worth keeping, and it outlives the
  PR.** It read `+0` with **five decks closer to IFOX00 and nine further** — and
  every one of the fourteen that moved is an IFOX00 `rc 12` run, already marked
  `comparable=no` in `mvs38src`'s `tool-diffs.tsv`. **Fourteen of fourteen**, so
  the closer column was exactly as meaningless as the further one; this file first
  recorded only the nine as doubtful, which was half the correction. A distance
  from a deck the assembler did not finish is a distance from a broken artefact,
  in either direction — and **the gate printed that verdict anyway, in the number
  a human reads in a PR description.** 933 modules in the tree have an `rc > 4`
  reference, a sixth of the corpus, so it was never an edge case.

  `mvs38src` `495ca81` fixes it, and the two choices in it are worth copying. The
  excluded modules are **named, not dropped** — a filter that quietly removes rows
  is the next version of this defect — and **identity is not filtered at all**,
  because reproducing a flagged run's deck byte for byte reproduces its error
  behaviour too. Only distance needs the reference to be a statement. Re-run
  against #361 the report now reads `closer 0, further 0` over 4,595 scoreable
  modules with the fourteen named beside it: **the whole tree-wide effect of that
  merge landed where nothing can score it.** The first-divergence run this file
  cited — later on all nine, earlier on none — remains a true statement about each
  prefix, and was not the argument that settled it.

- **2026-09-11 — two merges, none lost, 5,427 → 5,431 of 5,528 (98.2 %).** The
  first work this file's ranking produced rather than recorded.

  | PR | | gained |
  |---|---|---|
  | #359 | the implicit private-code section is chained (#358) | +3 |
  | #360 | a name declared `EXTRN` may not name a control section (#290) | +1 |

  **#290 took two prerequisites nobody had filed, and both were found by
  measuring rather than by reading.** The issue itself warned that the obvious
  implementation produces a malformed deck and asked whoever picked it up to
  understand that first; the answer turned out to be two separate defects
  underneath it.

  *The implicit private-code section was never chained.* `assign_origins()` walks
  `sect_ord` and only the `CSECT` handler appended to it, so private code kept
  origin 0 and the first named section was assigned 0 as well — two sections
  overlapping in one module. **The invariant that found it has no oracle in it at
  all**: no two sections of one deck may overlap. IFOX00 produces no such deck in
  5,528 and as370 produced five. Three of those five — `BNGCLOCL`, `BNGCMENU`,
  `BNGCRMOT` — became byte-identical, and they are modules this file had written
  off as unusable witnesses because their references come from rc 8 runs. They
  were unusable for the question then being asked and decisive for a different
  one, which is worth more than the +3.

  *An unnamed `DSECT` took the private code's own symbol.* It marked that section
  as a DSECT and defined the symbol without an `esd_add`, so the rejected control
  section found it defined, emitted no ESD entry, and filed its TXT under ESDID 0.
  That is the malformed deck, reproduced in three cards. `deck_lint` caught it the
  moment the rejection landed without the separation.

  **`IECVHDET` closed completely**, which is what made it an acceptance case
  rather than an example: three cards differed with END excluded and all three
  were this defect — the ESD name field, the `DC A(IECVHIDT)` as370 resolved to
  `0x0408` where IFOX00 leaves `0x0000` and relocates, and the RLD behind it.

  **Two method notes, both mine and both caught by a gate rather than by care.**
  A first attempt routed section membership through `opened`, which also decides
  whether a section's counter is reset; nine `IFCE`/`IFCS` modules moved *away*
  from IFOX00 for a reason unrelated to chaining. And the provisional-oracle
  comment added to the fixture ran to 73 columns, so `make test` went straight to
  rc 2 — an over-long **comment card** in a fixture whose whole subject is what
  IFOX00 does with a card.

- **2026-09-10 — the tracker pass itself: 48 issues read, one closed, nine
  corrected.** No code changed. What it found is in the header; what it is worth
  recording here is the failure mode, because it is the same one three times.
  **#39 closed on 2026-09-08 and led this ranking until today. #108 closed on
  2026-09-06 and still sat in the loud-gaps band. #149 and #151 closed and their
  paragraphs stayed.** Every one of them was a *closure* nobody propagated, and
  in each case the file went on being read as current. The tracker is the source
  of truth and this file is the order — but an order that names a closed issue
  first is worse than no order, and nothing here detects that on its own. The
  cheapest guard is the one this pass used: `comm` the issue numbers this file
  mentions against `gh issue list --state open`, which takes a second and would
  have caught all four.

- **2026-09-10 — thirteen merges, none lost, 5,415 → 5,427 of 5,528 (98.2 %).**
  Measured on this host at `b67af3d` and `fd287d3` on one macro path, so the two
  figures are comparable to each other and to the 5,379 this file already
  records — `b799ae0` reproduces that number exactly, which is what makes the
  rest quotable.

  | PR | |
  |---|---|
  | #340 | a macro's parameter values are as many as its prototype (#334) |
  | #341 | an empty nominal value is rejected and reserves nothing (#338) |
  | #344 | a grouped parenthesis is descended into, not skipped (#343) |
  | #346 | an `EQU` alias of an external relocates against the ER (#186) |
  | #347 | an attribute apostrophe is not a delimiter in two more scans (#184, part) |
  | #350 | a register operand may begin with a grouping parenthesis (#247) |
  | #351 | an S-type constant takes its base from an absolute `USING` |
  | #352 | `AWR` and `AUR` had each other's opcode |
  | #353 | a `DROP` takes as many registers as it names (#193) |
  | #354 | `T'` of an expression is the type of its leftmost term (#270) |
  | #355 | a `COPY`'d symbol carries its attributes |
  | #356 / #357 | the `END` literal pool follows its own section's extent (#349) |

  **#352 is the one to read twice.** `AWR` and `AUR` carried each other's opcode
  — a two-row table error, silent, in code generation, on a table that has been
  read many times. This pass found the same shape twice more in the same file:
  `BRXH`/`BRXLE` at the wrong format (see #56 under *Loud gaps*). An opcode table
  is not self-checking, and nothing in the corpus gate looks at a mnemonic nobody
  uses — which is exactly where a table error survives.

  **What did not move, and why the day's number is not the day's work.** Six of
  the thirteen closed an issue that had been open for less than a day. The gate
  says `+12`; the issues say twelve *mechanisms*, several of which reach modules
  no oracle can settle. Both are true and they answer different questions.

- **2026-09-09, second half — twelve merges, none lost, 5,379 → 5,415 of 5,528.**
  Never recorded here: the day's close-out entry below stops at #306, and #311
  through #337 merged after it was written.

  | PR | |
  |---|---|
  | #311 | a `DC`'s label is defined before its own duplication factor (#310) |
  | #313 | an attribute apostrophe is not a quote in `has_overlong_term` (#312) |
  | #316 | `REPRO` punches the next card into the object deck (#314) |
  | #318 | a literal carries its duplication factor (#317) |
  | #319 | a macro definition is as long as it is (#287) |
  | #322 | a card IFOX00 does not flag does not raise the return code (#320) |
  | #324 | `IFO220`, the alignment warning IFOX00 gives and we did not |
  | #326 | an empty continuation card is `IFO026` (#325) |
  | #328 | a literal carries its scale modifier (#327) |
  | #330 | a packed or zoned literal is sized and emitted like its `DC` (#329) |
  | #332 | an `F` or `H` literal may carry a list of nominal values (#331) |
  | #337 | `ACTR` bounds the conditional-assembly loops (#336) |

  **Five of the twelve are the literal pool**, and they are one defect wearing
  five names: a literal was being sized and emitted by a path that had never been
  reconciled with the `DC` path it is supposed to be identical to. Duplication
  factor, scale modifier, packed/zoned, value lists — each was found separately,
  each was a separate issue, and every one of them was the same missing sentence.
  Whoever next finds a literal defect should assume the pool, not the case.

- **2026-09-09 — twenty merges, none lost, 5,213 → 5,379 of 5,528 (97.3 %).** The day
  the definition of done changed: Mike's `as370 == IFOX00` now means the deck **and**
  the return code, and the second half was worth 151 modules that every deck-based
  figure had been calling finished. `as370 alone flags` went 107 → 16.

  | PR | | gained |
  |---|---|---|
  | #266 | a `USING` may name up to 16 base registers (#154) | +25 |
  | #268 | a statement is as long as the joiner made it (#153) | +2 |
  | #269 | a macro parameter value is 255 characters (#151) | +46 |
  | #271 | a `DC` operand carries as many values as it has room for (#270) | +0 |
  | #274 | a term following a substring is concatenated (#273) | +1 |
  | #278 | a `USING` operand beginning with `*` is an expression (#275) | +10 |
  | #280 | an `ORG` past the content extends the section (#279) | +1 |
  | #283 | the section high-water mark rises in pass 1 too (#282) | +7 |
  | #284 | a section outranks an ER of the same name (#281) | +46 |
  | #286 | a definition outranks a lingering ER type (#285) | +6 |
  | #289 | `END` ends the assembly (#288) | +2 |
  | #293 | a keyword the prototype does not declare is `IFO092` (#162, #292) | +115 rc |
  | #294 | a discarded statement carries IFOX00's severity, not ours | +8 rc |
  | #296 | an operand that substitutes to nothing stays empty (#295) | +1 rc |
  | #299 | `BNPR` and `BNMR`, the `BR` forms (#298) | +3 |
  | #301 | an attribute apostrophe inside a sublist is not a quote (#300) | +3 |
  | #304 | a blank in a generated statement does not end the operand (#302) | +39 |
  | #306 | a `COPY`'d card inside a macro is not a model statement (#305) | +2 both |

  The `rc` column is return-code agreement where the deck did not move. #293 is the
  largest single figure of the day and not one byte of it is code generation: a
  keyword the prototype never declared was accepted in silence, so 115 modules
  IFOX00 rejects assembled clean here.

  **The first four are silent CAPS**: a fixed size reached, the excess dropped, and
  the assembler carrying on as though nothing had been. They never announce
  themselves — the symptom is always something else, a long way downstream.
  `JTEXT`'s whole `JT*` set came out of one `DBV` call carrying 86 positional
  operands of which 61 survived, at rc 0 with no diagnostic anywhere.

  **The last seven are all the same sentence, and it is the result worth keeping.**
  Not one of them is a wrong byte of code generation. The text as370 emitted was
  already right; what diverged was **what the object said about it** — a length
  (#280, #283), an origin (#278, #283), which section the text was filed under
  (#284, #286), or a name that never got its counter (#274). as370 computes the
  text from the source and the metadata from its own bookkeeping, and only the
  first of those had ever been under a byte-for-byte test.

  **How they were found is the transferable part.** Every instrument until then
  compared as370 against IFOX00 and treated IFOX00 as the authority — which is
  exactly no help on a divergence where neither assembler says anything. `mvs38src`
  built a **third witness**: IBM's own shipped DLIB object, produced by neither of
  them. Where it agrees with IFOX00, as370 is wrong without any appeal to
  authority. Six modules selected that way, five closed, and every one of the five
  lived outside the bytes anyone was comparing.

  Two open at the end of it: **#290**, where the rule is measured against the oracle
  (`EXTRN X` then `X CSECT` is IFO196 and unnamed private code, while `DC V(X)` then
  `X CSECT` keeps the name) and the obvious implementation produces a malformed
  deck — deliberately not shipped. And `IFCEA155`, a **−8** across 3,876 bytes.

  **Two method notes that cost real time and are worth the space.**

  *A gate line can be green on a deck that is structurally wrong.* #290's naive fix
  reads `+0, closer 1, none lost` while writing TXT under an ESDID with no ESD entry.
  `mvs38src` closed that hole the same evening with `deck_lint.py`, which asks of one
  deck alone whether it is well formed; every as370 deck outside the five excluded
  CICS modules passes.

  *Aggregation fails where measurement does not.* Four times in one day the number
  was already correct and nobody looked at it in the right shape — a class file that
  had stopped measuring its own issue, a messages cache eleven merges stale, and both
  sessions reading `AMASPZAP`'s module totals while its per-section view named the
  defect. Re-measuring the witness **before** writing the commit message rather than
  after is the only practice that caught one of them in time.

  *A net count cannot report a regression it is outnumbered by.* #304 gained 39
  modules and broke three — `IFNX1K`, `IFNX3K`, `IFNX5V` went RC 0 → RC 8 — and the
  gate printed `LOST : 0` and `alone flags 23 → 19`, **both true**. The three decks
  were already non-identical, so the deck measure could not see them, and seven
  others improved in the same run. It was found the next morning by asking *when* a
  suspiciously uniform family broke, from two `.tsv` files already on disk. #306
  closes it; `retest.py` now prints `rc CLEAN -> FLAGGED` by name, unconditionally.

  *A frozen file and a stable measurement look the same from outside.* The map of
  what is left carried a fresh timestamp and a baseline **29 commits behind**, so
  every cluster size in it was too large by an unknown amount. Second instance of
  the shape in two days. A derivation is now written down with the command that
  prints its own distance from `main`, because a bare commit hash needs a reader who
  thinks to check it.

- **2026-09-08/09 — twenty merges, none lost, 4,753 → 5,213 of 5,528 (94.3 %).**

  The run that took the tree from 86.0 % to 94.3 %. Pointers, newest first:
  #265 EBCDIC collating (+7), #263 a closing parenthesis ends a term (+9),
  #261 `T'` of a sublist (+5), #259 `T'` in a SETC expression (+0),
  #256 the scale modifier (+5), #255 a DC operand's value list (+31),
  #254 stale operand fields (+17), #251 the continuation join (+82),
  #249 `L'` of an ordinary symbol (+13), #248 a leading parenthesis (+30),
  #245 a comparison operator without blanks (+67), #242 the bit length
  modifier (+99), #239 a doubled apostrophe (+12), #237 the AIF condition
  buffer (+9), #234 MNOTE, #232 CNOP (+57), #230/#228 the listing counters,
  #225 `E` is a constant type, #222 `EQU` with a leading parenthesis.

  **Not one merge lost an identity, in twenty.** The two that gained nothing
  were not failures: #259 was the half of `T'` that pays only through #261, and
  #234 is a diagnostic that changes no bytes at all.

  Three method notes worth more than any single fix. **A difference class is not
  a cause class** — 78 modules of "missing relocations" were 7 once the other
  instruments' explanations were subtracted. **The population an instrument
  returns is the population it can see**, which is why #264's seven were the
  whole reach and not a sample. And **a message names its own cause, but the
  name can be wrong**: four residuals closed free on changes aimed elsewhere,
  recognisable only because they had been recorded with module names.

- **2026-09-08 — five merges, +10 identities, none lost, and every module in the
  corpus produces a deck for the first time.**

  | PR | | gained | note |
  |---|---|---|---|
  | #212 | `scopy` in `set_put` | 0 | `main` had been red since #208 on a gcc-only `-Wstringop-truncation` |
  | #214 | a CCW data address written as `*` is relocatable | +7 | |
  | #216 | `expr_sect` never terminates on a comma (#215) | 0 | `HEWLDIOC` assembles for the first time |
  | #216 | a cross-section difference needs a signed pair (#209) | +1 | |
  | #219 | the attribute apostrophe is not a quote in `dc_split` (#218) | +2 | |

  The `gained` column is `retest.py` on this host, each PR against its own
  parent. Standing after them, from `mvssrc`'s `ifox_compare.py`: **4,753 of
  5,528 (86.0 %)**, hand-over 853, thirty-five merges without a lost identity —
  `retest.py` reads 4,745 for the same tree, which is the ten-minute answer and
  not a disagreement. Name the tool with the number.

  **The relocation dictionary is now correct on every module whose bytes are
  correct.** Before #209 there was exactly one exception in the tree, and that
  was the whole class — right value, right image, a loader that would not
  relocate it, invisible to anything that rebuilds the image.

  **A lost deck is a regression and the identity line cannot show it.** #209's
  first gate read `+1 gained, LOST 0` and, on a different line, `deck NOW
  MISSING: 2`. The identity figure was correct and meaningless: with no deck
  there is nothing to compare, so every other line silently excluded those
  modules. `retest.py`'s hint said a vanished deck is *usually* the worker's
  alarm — true twice running, which is exactly what makes a hint get followed
  instead of the procedure it recommends. Timing the two alone took thirty
  seconds: 0 s on `main`, never on the candidate. A hang.

  **An alarm cannot tell slow from broken — it reports where measurement
  stopped.** `HEWLDIOC` was recorded in both runbooks as a module that "does not
  terminate in 300 s and never will within any alarm". The 300 s was measured;
  *never* was a conclusion. It had been hung on `main` for eleven months in a
  walk with no progress guard, reachable from an ordinary machine-operand path,
  and it now assembles in 0 s to within 4 bytes of IFOX00 out of 5,056. Writing
  a measurement limit down as a property of the thing measured is what stops it
  being a question.

  **A difference class is not a cause class.** A sweep of every deck's relocation
  dictionary gave 78 modules and 410 missing entries, read as a small fix with
  twenty times the reach of the one-module case in hand. Split by what each
  module *already* disagreed about — 43 with undefined symbols, 28 with a wrong
  TXT image — **390 of the 410 were downstream**, and the genuine class was 7
  modules and 20 entries. The entry comparison cannot tell a missing relocation
  from a missing *symbol* and reports both identically.

  **"Lexical" is a property of the text you are reading, not of the construct.**
  #218's source scan found the construct in two modules; **neither of the two
  gainers was one of them.** The operand reached them through a macro. The
  characters really were on a card — just not on a card anyone was scanning.

  **Two paths over the same term, one right — four times in one week.** The SS
  implied length (#201), `tgtreal` on the `DC` path against the CCW path (#210),
  and `reloc_sym` against `expr_sect` twice, once for a dropped relocation and
  once for the hang (#215). It is a class of *place*, not a class of bug:
  wherever two walks read the same syntax and only one has been maintained. A
  source pass, since the consequence is indistinguishable from any other wrong
  byte until you know which construct to look for. **And it generates false
  positives that only an oracle kills** — six readers of the attribute apostrophe
  carry three different letter sets, and the asymmetry is correct.

- **The 2026-09-07 run with `mvs38src`: six merges, 271 modules gained, not one
  identity lost.** That last clause is the one worth quoting — the gain says the
  work is useful, the absence of a single regression across six changes is what
  says as370 is becoming dependable.

  | PR | | gained | decks closer | further |
  |---|---|---|---|---|
  | #164 + #165 | `.*` comment card, IPK/PTLB zero-operand | +93 | | |
  | #166 | diagnostics in source order + statement numbers | 0 | 0 decks changed | |
  | #168 | address constant whose value starts with `(` | +24 | 69 | 9 |
  | #170 | parenthesised index register, and the paren that is not a subscript | +58 | 178 | 1 |
  | #171 | `L'` from the nominal value | +95 | 229 | 1 |
  | #175 | a relocatable `EQU` belongs to the section of its VALUE | +282 | 452 | 2 |
  | #178 | a `USING` replaces the domain of its base register | +108 | 167 | 0 |
  | #180 | where a continued operand ends depends on the statement | +24 | 90 | 5 |
  | #182 | an attribute apostrophe is not a quote in `parse()` | +23 | 50 | 1 |

  Over the tree, as of #171: `as370 == IFOX00` **3,466 → 3,737 of 5,528**
  (62.7 % → 67.6 %), recovered against IBM's own object 869 → 902, silent
  divergences 1,169 → 1,046.

  **After #175: 4,192 of 5,528 (75.8 %).** That row's baseline is its own parent
  — #172 and #174 already in — which the gate reproduces at **3,910 (70.7 %)**,
  independently the figure `mvssrc` reported for the same point. The two rows do
  not chain arithmetically from #171 because #172/#174 sit between them; every
  number here is only readable with its baseline named, which is why each row
  carries one.

  `mvssrc` reproduced #175 exactly (+282, none lost, 452 closer, two further by
  one byte, section lengths 0/0) and reports the merged tree at **4,196 (75.9 %)**
  — four above the figure here, and not a disagreement: `retest.py` wants a
  ten-minute answer, while `ifox_compare.py` re-assembles each differing module
  with the date and time its IFOX run used. Quote whichever tool you ran, by name.

  **After ten merges, none of which lost an identity** (`mvssrc`, post-#178):

  | | before | after |
  |---|---|---|
  | `as370 == IFOX00` | 3,466 (62.7 %) | 4,304 (77.9 %) |
  | recovered against IBM's object | 869 | 1,002 |
  | silent divergence | 1,169 | 766 |
  | as370 alone flags | 512 | 236 |
  | hand-over list | 2,107 | 1,389 |

  **When a mechanism class does not empty, check first whether the survivors were
  ever in the mechanism.** #190 was 54 modules whose only divergence was an RX
  base register; #191 closed 52 of them and gained 5 more that the survey's "at
  most 8 differing addresses" bound had excluded — the first time one of these
  bounds has been given a number rather than merely flagged. The two survivors
  turned out never to have had the `B → 0` pattern at all: they are `ifox_base=10`
  against as370's 14 and 15, a base-register *choice* between two live USINGs
  rather than a missing base, and they want their own issue. #186's residue is the
  same shape from the other side — `AMDPRPJB`/`AMDPRPMS` sit in it with `xor 0x00`,
  so their divergence was never in the flag byte. A residue defined by "what the
  fix did not move" is a membership rule, not a class, and reads as one to whoever
  picks it up.

  **Self-contradiction proves an assembler wrong; it cannot say what right is.**
  At `IEAVELCR` (#187) those were the same question, because the correct behaviour
  was "do what you already do everywhere else" — 23 identical `VL3` cards at
  length 3 and one at 4. At #190 there was no such uniform behaviour to point at:
  as370 had *no* absolute-domain resolution, so nothing internally consistent
  existed to copy. The oracle was needed twice and changed the answer both times —
  whether a self-defining term resolves (it does), and `defined and absolute`
  against `not relocatable`, which was worth **52 identities in the wrong
  direction**. Use the internal-consistency shortcut only where the assembler
  already does the right thing somewhere.

  **The artefact that reports success.** Three times in one day, in three
  different tools, an instrument said "fine" because it could not see the thing
  it was measuring — and each was caught by a number looking slightly wrong
  rather than by a check:

  - a fixture that passed on **both** binaries (`rldlen.s` with an A-con instead
    of a V-con in the DSECT) — a non-test, indistinguishable from a passing one;
  - `rebuild_classes.py` collecting into a `defaultdict`, so a class with no
    members was never rewritten and kept its last non-empty contents — **the one
    file it never refreshed was the one where a fix had succeeded completely**;
  - a `no-as370-deck` count reading `10 -> 10` while one module lost a deck to a
    timeout race and another gained one for real.

  The shared shape is worth more than any of the three defects: **an instrument
  that cannot observe the change reports success**, and success is the reading
  nobody investigates. So make a fixture fail before you trust it passing, seed
  every class before writing class files, and treat a count that did not move as
  a claim to check rather than a result.

  **The named trap: two builds at once.** Three times in one day, between the two
  sessions and in both directions, a figure came back plausible and wrong because
  it was measured with one binary against state written by another. Both
  instruments take a binary **and** read stored state, and nothing in their
  output says which commit each half came from:

  - `ifox_compare.py` re-assembles the differing modules with the binary on its
    command line while comparing decks stored under `ifox-run/as370/` — a step
    that copies the gate output there was never written down. It reported **+11**
    for #182 where the truth is **+23**.
  - The same shape here: an `alarm 20` run compared against an `alarm 120` run to
    check for a timeout race, with the two runs made by **different binaries**.
    Twenty modules appeared to move; it was #182's own effect, and the real
    answer to the timeout question was 0.
  - And a deck count that moved on a change altering nothing, which turned out to
    be `IFCEE155` racing a 20-second alarm — while in the same run `IFNX1A`
    gained a deck for real, the two cancelling to `10 -> 10`.

  So: **name the binary and the stored state separately on every figure**, and
  treat a deck that appears or disappears as a timeout until proved otherwise —
  `IFCEE155` and `IFNX1A` were indistinguishable in the gate table, both `rc 142`
  with no deck, and one was an artefact while the other was the largest
  behavioural change in the merge (240 s to 0.06 s).

  The cheap standing control is to **gate a merged binary against itself**: a
  byte-identical deck set and `+0 / 0 lost / 0 closer / 0 further`. It needs no
  no-op PR to come along, and it would have caught the alarm race in one run
  rather than thirteen merges.

  **The rule the day earned: any population derived from as370's own behaviour
  is provisional until the assembler stops changing.** Three times in one day a
  fix changed what a *measurement* said rather than what the program does, and
  each time the earlier number was a property of the assembler, not of the
  source:

  - #174 dissolved `IHANVT` and `UCBDADVC` off the missing-macro list entirely —
    two of its three largest entries. With operand fields no longer clipped at
    63, the modules that appeared to need them resolve them from a library we
    already had. Every missing-macro count taken before #174 was measuring
    as370's truncated expansion.
  - #175 exposed nothing new, but its own class had been mis-hypothesised for
    exactly this reason: the reach figures for #154 were read as evidence about
    `USING` when they were evidence about `EQU`.
  - #178 lifted three modules (`IDA019R4`, `IDA019RU`, `IDA019RY`) out of
    silent-wrong-bytes and into `as370 alone flags` — the count went 233 → 236
    while the decks improved tenfold. One defect had been concealing another.

  So a class list, a reach count or a hand-over list is a **snapshot of the
  assembler**, not an inventory of the work. Re-derive it after every merge
  before ranking anything by it, and say which binary produced it — the same
  discipline the baseline rule already imposes on the identity figures.

  **Three of the five were the same shape**, and it is worth naming because it
  predicts where the next ones are: a CORRECT helper sitting beside the wrong
  call. `expr_val_full` was written for the duplication factor and never wired
  to nominal values (#168); `eval_reg` was written for `LR 0,(3)` and never
  reached from the subscript loop (#170); the P/Z arm computed `L'` from the
  scanned body while C/X/B did not (#171). Each helper's own comment named the
  failure mode it was guarding. A sweep for the rest of that shape is the
  current work.

  **A measurement correction that cost a published number.** The card-based
  distance measure from #168 charges a full card for a card-count difference, so
  it scores a *corrected section length* as a regression: `IFNX4S` reached
  exactly IFOX00's `0x1ad` and was marked +71. Distance is now the address-keyed
  section image on both sides, and #170's row was restated from 172/6 to 178/1.
  A deck's cards are an encoding, not the object.

- **#149, and the first regression of the run — caught by the gate, not by
  reasoning.** `3b510c4` (#182). `parse()` toggled quote state on every
  apostrophe, so after `L'A`/`T'&V`/`K'&P` the state stayed inverted, the first
  blank read as "inside a string", and the remarks field was swallowed. Invisible
  on a machine instruction — the evaluator stops at the real operand end — but
  not on a **macro call**, where the tail becomes a parameter, and not in the
  **literal pool**, where it becomes part of the literal's *name* so one literal
  is laid down twice. The second is libc370 `@@crt0` card 266, and it is why the
  743-corpus moved for the first time in the run: `@@crt0` and `@@crt1` lose a
  duplicated literal and shrink four bytes.

  **The obvious fix scored +0 and −96.** `attr_apos()` is a purely lexical test,
  so it reads the CLOSING quote of a string whose last character is an attribute
  letter as an attribute apostrophe. `AMDPREAD` card 327 —
  `READ MAPDECB,SF,(R3),(REG0),'S' READ RECORD INTO BUFFER` — ends in `'S'`, the
  string never closed, the remark joined the macro's operands, `MAPDECB` was
  never defined, and **96 modules lost byte-identity with 175 decks further**.
  Inside a string an apostrophe can only close it; the guard is `q ||`, and every
  other attribute-aware scan in the file already had it. **`split_card()` calls
  `attr_apos()` without it** and has the same latent reading — it cannot move a
  deck, so it is left for #141's owner.

  Two things worth keeping from that. The local suite stayed green through the
  broken version: **743 corpus modules and 21 IFOX reference decks all passed a
  change that cost 96 identities**, because none of them contains a string ending
  in an attribute letter. And `tests/attrapos.s` therefore carries **three**
  cases — macro parameter, literal identity, closing-quote guard — since the
  obvious fix passes the first two.

  **+23, none lost, 50 closer, one further by three bytes. rc 0 4493 → 4526.**
  #156 falls to zero as a side effect (`IEEVMNT1`, `IFNX6B` were its whole
  population); #155 is unmoved at 5. `mvssrc` measured the merge and found
  **#157 fell 23 → 2** as well, which nobody aimed at — 21 of the 23 are `BLS*`
  moving together, so one shared macro rather than 21 operands.

  **The second half, `87c66cf` (#183): `split_card()` needed the same guard.**
  #182 called that latent and left it, which was the weaker call. The
  substitution splitter is already field-aware, so the boundary `split_card()`
  computes decides whether a REMARK is substituted — and IFOX00 leaves remarks
  alone. `DC C'ADD 1 TO N'   BEMERKUNG &X ENDE` had its `&X` replaced and emitted
  a generated statement where IFOX00 emits none. The issue records 2,030 bare `&`
  in open-code remarks across 716 modules; each one behind a string ending in
  `L T K N I S E` was exposed. **0 of 5,528 decks change**, deck-by-deck by
  sha256 — which is why that test is on the listing: a deck comparison passes in
  both directions and proves nothing.

- **#154's third cause: the continuation join — five of the class, +24 in the
  tree.** `ccd061b` (#180). A continued line's operand ends at the first blank
  outside QUOTES; the join also required it to be outside parentheses, and
  applied that to every statement. A macro call whose operand broke inside an
  unclosed sublist therefore carried its remark in:

  ```
  XCTLTABL ID=(NAME,SECLOADA,,IFG0195V,             Y02134X
         ,IGG03001,,IGG0290A,...
  ```

  joined as `...IFG0195V,   Y02134,IGG03001,...`, so the change-level tag became
  a sublist element, the macro generated its `DC` under that name, and every
  reference to the real one was an undefined symbol addressed through no `USING`.

  **Dropping the parenthesis test is not the fix, and the suite says so
  immediately.** `AIF` and `SETB` operands are expressions whose operators are
  blank-separated; without the test they fall apart and take the `#63` DCB
  common-interface block with them. So the rule depends on the statement, and
  the set was **measured, not guessed** — both rules computed over the 5,528
  modules, the operation recorded wherever they disagree: `AIF` 3,200, `SETB`
  1,597, `SETC` 2 need the expression rule; all 27 other operations that appear
  are macro calls that must cut (`XCTLTABL` 57, `SETLOCK` 17, `DEQ` 8, `GETMAIN`,
  `OPEN`, `WTO`, `ENQ`, `CALL`, `ACB`, `RPL`). `AGO`, `SETA` and `ACTR` are in on
  grammar rather than measurement, and the comment says so.

  **+24 identical, none lost, 90 closer, rc 0 4449 → 4493.** The class itself
  moves only **42 → 37** (`IFG0194F`, `IFG0195D`, `IFG0196O`, `IFG0552B`,
  `SECLOADA`): a contributing cause, not the dominant remaining one. Most of the
  tree-wide gain is in modules that were never in the class — a mis-joined
  continuation is not usually an addressability error, it is simply wrong bytes.
  **32 of the 42 still want a fourth cause.**

  **The identity count is the smaller half, and the diagnostic instrument shows
  why.** The mis-join was inventing operations out of change-level tags — a
  module whose only fault was a line break reported `Y02134` as an undefined
  operation. Counting IFOX-silent modules that *carry* each message:

  | | before | after |
  |---|---|---|
  | undefined operation code | 163 | 114 |
  | undefined symbol | 300 | 275 |
  | addressability | 83 | 78 |

  **33 modules carried at least one of the three and now carry none; 49 lost at
  least one class.** `mvssrc` reports the same change against the *class* files
  (51 → 5, 170 → 135, 42 → 37) and sums the first two to 81. Both are right about
  different questions and neither should be quoted as the other: the class files
  count each module once, under its **dominant** diagnostic, so a module that
  merely reclassifies still leaves its class; the figures above count every
  module carrying the message, so a module dominated by another defect stays
  visible. That is the same 42-against-83 distinction as the class size itself,
  and the rule recorded above — a population derived from as370's own behaviour
  is provisional until the assembler stops changing — applies to *these* numbers
  as much as to the class lists.

  Third time in one day the headline was the smaller half, after #174's section
  lengths and #178's rc composition — and all three surfaced on an instrument
  that looked like it had nothing left to prove.

- **#177, the USING table — the hypothesis #154 disproved, measured and fixed.**
  `0c2f4a6` (#178). `USING` is keyed by base register: a second `USING` on a
  register that already has a domain **replaces** it. as370 appended, so the
  dead entry stayed live and `using_for` kept resolving against it. An operand
  below the new base then assembled **at rc 0** where IFOX00 gives `IFO209` and
  zeroes the instruction — **#140** again, a third issue wearing its name.

  **The 32-entry cap was a consequence, not a second defect.** Keyed by register
  the table holds at most 16 entries, so the bound is now unreachable. It had
  been silently dropping every `USING` past the 32nd in 31 modules; `IDA019R4`
  alone lost 130.

  **+108, none lost, 167 closer, 0 further** against `f06508f`. Instrumented
  reach — macro-generated `USING`s included, which a source count misses —
  **1,132 of 5,528 modules re-USE a live register.**

  **Two things this settles about #154's triage.** `IDA019R2`, offered there as
  the witness for the silent addressability class, is not in that class and is
  among these 108 — it becomes byte-identical, and it was also a cap-hitter. And
  the append-only table, the leading hypothesis for #154's 156 modules, was
  correctly ruled out: it closes exactly **one** of #154's 40 residual modules
  (`IGG019JH`). A real defect in the right neighbourhood is still not the cause
  of the class next door — the 6-of-156 count is what separated them, and no
  amount of plausibility would have.

- **#154, 116 of 156 — and the issue stays open.** `e99e2c1` (#175). The EQU
  handler took a symbol's section from *where the card sits*
  (`s->sect = cur_sect_id`). Harmless for an absolute equate; for a relocatable
  one it mis-files the symbol, and PL/S output makes that systematic, because
  every EQU is at the end of the module after the mapping macros have left a
  DSECT current. `BLSCCLSE`'s `@RC00027 EQU @RC00025` — a plain CSECT label —
  was booked into the DSECT `IFGRPL` opened, and `using_for` then hunted for a
  USING covering *that* section. `s->sect = rc ? expr_sect(F[0]) : cur_sect_id;`

  **Two symptoms, one cause, and the second is the one that matters.** With no
  USING in range for the wrong section you get IFO209 — the diagnostic the issue
  reports. With the wrong section's USING *in* range, the operand silently takes
  that base register **at rc 0**. `s->sect` also drives the `dsect_sect[]`
  RLD-target test, so the same mis-filing can cost an address constant its
  relocation: any count derived from as370's relocation behaviour before this
  commit may be measuring the defect rather than the program. That is **#140**
  again, wearing this issue's name, exactly as #153 wore it.

  **The hypothesis it disproves.** The leading theory was the USING table:
  append-only, and capped at 32 with later cards silently dropped. Both are still
  true and neither is the cause here — only 6 of the 156 modules carry ≥32 USING
  cards, and 4 of those 6 are fixed by this change. A rekey defect may be real;
  it wants its own issue and its own measurement, and was deliberately kept out
  of this commit. `HEWLDIOC` (45 USING cards, #163) still does not terminate.

  **40 remain and need a second root cause** — AMAPTFLE BLSUPUT BNGI3270
  BNGIDISP BNGLOGR2 BNGT3270 BNGTDISP HEWLFSCN ICAPRTBL ICFBIF00 IDA019C1
  IDA019ST IEAVEAT0 IEBCMAIN IEBGENR3 IEBPPAL1 IEBPPCH1 IEBUPDT2 IEFVDA IEFVEA
  IEFVFA IEHLIST1 IEHPROG1 IEHPROG2 IFCDIP00 IFCEI145 IFCET008 IFCIOHND IFG0194C
  IFG0194F IFG0195D IFG0196O IFG0552B IGC0001F IGG019JH IGG019MB ISTINCU7
  ISTNSC00 ISTZGF0A SECLOADA. `IDA019R2`, offered as the class's silent witness,
  is **not** in it (it sits in `rx-index-dropped`) and is unchanged by #175 —
  the silent behaviour it was cited for is real and `tests/equsect.s` now pins
  it, but that module is not an instance.

- **#153, the first two of sixteen** — `84cf294` (#164) and `879e86a` (#165),
  merged 2026-09-07. `parse()` did not know the `.*` comment card, so
  `capture_macro()` ended a definition on the word `MEND` inside a prose card:
  `AMODGEN(IECDSECS)` card 131 quotes a sample macro that way, and as370 kept
  130 of its 1,672 cards — `FORCORE`, `WTG`, `UCB`, `IHADCB` and the whole
  `IECDSECT` tail were never generated. And `IPK`/`PTLB` were coded `F_S`, so
  the remark behind the mnemonic was read as the operand. Over the 5,528:
  **rc 0 4154 → 4312, byte-identical 3465 → 3558 (+93, none lost)**; of #153's
  333 modules, 144 go clean. Reproduced independently by `mvs38src` from both
  branches and their merge.

  **Two lessons worth more than the count.** All 93 gained modules were booked
  to *cc370* in `module-table.tsv`, none to the source — the first evidence that
  the ownership attribution itself holds. And the byte gain far exceeds the rc
  gain (+93 against +158 rc, but only +13 rc from #165 alone) because most of
  the `IPK` class never flagged anything: 48 modules were returning rc 0 with a
  wrong deck, which is **#140** wearing this issue's name.

  **A defect of ours made the triage harder and is now the next step:** the
  stderr diagnostic dump is category-ordered (`as370.c:3936-4038`,
  undefined-symbol printed last) and `line_org` folds every macro-generated
  message onto the call card, so "first diagnostic" is neither first nor
  causal — all 75 of `IFG0190P`'s said *"in line 1"*. Both are byte-safe, both
  should land before further mechanism work, and until they do, reach figures
  derived from as370's own message order are isolation evidence, not counts.
  The fourteen unfixed mechanisms in #153 carry exactly that caveat.

- **The September as370 parity run** — #127 (`START`), #128 (`ISEQ`), #129
  (DC/DS type `S`), #133 (cross-section duplication factor), #134 (`&SYSECT`),
  #136 (per-section location counter), #138 (base-register tie-break), #142
  (`T'` of a self-defining term), #144 (`T'` of a symbol, via an open-code
  look-ahead) and #146 (`T'` written out rather than through a parameter),
  closed 2026-09-04…06. Driven by `mvs38src`, which assembles recovered MVS 3.8j
  source with as370 and diffs the deck against what the system ships. Over that
  tree: 4,270 → 4,533 modules assemble, **572 → 837 byte-identical**, 853 →
  1,263 identical-or-only-`DS`-holes (21.9 % → 30.8 %), and **nothing
  regressed**.

  **Five of the ten were silent**, and four of them unlocked no module at all —
  `&SYSECT`, the cross-section null factor, the base-register tie-break, and
  the `T'` family. Between them they were the largest contribution,
  because they corrected object code that 80-odd modules had been emitting
  silently and wrongly all along. That is the lesson worth keeping: **the
  expensive assembler defects are the ones nothing fails on.** No test of ours
  found either; both needed foreign material and a real IFOX00 to compare
  against.

  A second lesson, hit **three times in one week on this side alone**: *a
  fixture whose two hypotheses give the same answer decides nothing.*

  | fixture | the two cases it could not separate |
  |---|---|
  | `csect_resume.s` | origin-at-open vs origin-from-final-lengths — `align8(4)` and `align8(6)` are both 8 |
  | `basereg.s` | highest-numbered register vs last registered — its USINGs are declared ascending |
  | `tattr_symbol.s` | `T'&VAR` vs `T'SYMBOL` — all 17 cases went through a macro parameter |

  The first two were caught before shipping; **the third shipped**, and #146 is
  the repair. In the second case the obvious one-character fix (`dd < bd` →
  `dd <= bd`) would have been wrong. Write down what each candidate rule
  predicts before capturing: if the predictions match, the fixture proves
  nothing whatever the oracle says.

  The `T'` family is closed, and closing it answered a question that looked like
  a fourth defect. The 184 modules calling a type-attribute macro with a
  self-defining term were **eight times less often byte-identical** than the
  tree average, and two exact fixes lifted only five of them. The fixes do reach
  them — 77 of the 184 decks changed — so the set is not depleted by a defect
  still in hiding: **it selected for complexity.** A module that calls `DCB`
  with a self-defining term is a module with more going on. Worth remembering
  the next time a subpopulation looks damning.

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
- **`obj370` scatter record / PR #126** — 22 of 5,252 real DLIB members carry a
  record with byte 0 `X'10'`, and both walkers stopped dead at it. The answer had
  been in `docs/load-module-format.md` §8 since it was written: byte 0 `X'10'`,
  bytes 1-3 the data count, 4-byte header. It went unimplemented because a module
  only carries one when bound SCTR or OVLY, and neither cc370 nor as370 ever
  emits one — **the same story as `rld[512]` and `dir[256]`: the corpus never
  contained the triggering input.** Found only when foreign material ran against
  it. Its 16 members in the tree-wide run now all produce a verdict, one of them
  byte-identical, and 400 randomly re-run modules are unchanged.
  The test asserts **continuation, not survival** — every record after the
  scatter record must be reported exactly as before it was inserted, because
  "does not crash" also passes a walker that stops one record later. `SYM`
  (`X'40'`) stays deliberately unknown, verified by flipping the type byte: the
  point was to learn one documented record, not to make the reader permissive.
- **#110 `cmplmd370` / PRs #122, #123, #124, #125** — the host COMPare Load MoDule, and
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
  A later fix belongs with it (#125): on its two error paths the JSON printed
  `error` and returned, leaving out `exit` and `identical` — the fields a caller
  branches on, missing where it most needs them. Sixteen of a 3,888-module run
  hit it, and the missing message hid a real defect underneath (the scatter
  record above). Same class as the fixed 64-cluster array: **a machine-readable
  answer that omits something without saying so.** One shape on every path now.
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

- **A literal blank `CSECT` card: does it resume its counter or restart it?**
  Parked deliberately while #290 was fixed, and as370 answers **neither** rule
  consistently — measured on `0a6e868` it RESTARTS on the first blank card and
  RESUMES on every later one, because `opened` reads 1 then 2. A first blank card
  and a second cannot both be right, **so this is a defect whichever way IFOX00
  answers**; the oracle decides which of the two behaviours to keep, not whether
  there is something to fix. The fixture is written with its three predictions
  (`as370/tests/blank_csect.s`) and carries **two** blank cards on purpose: with
  one it would have read as a clean RESTART and proved the wrong thing. The
  `&CSECT` family — `IFCETRN6`, `IFCS5424` and the other `IFCE`/`IFCS` — is where
  it bites, and those cannot arbitrate it: their IFOX00 references come from rc 12
  runs. Waiting on a capture against the pinned oracle, not on a decision.
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

**Settled the same day it was raised, and the answer is worth more than the
identity it recovered.** `mvs38src`'s `25679ba` put `work/macros/amaclib-live` at
the head of the gate's `-I` path, on the argument that `SYS1.AMACLIB` is first in
the oracle's SYSLIB. For five of the six members that holds. For `IHADVCT` the
reference deck contradicted it, and `0457a00` moved the directory to the end of
the path: unique members still resolve out of it, colliding ones come from
`mirror`. Re-measured here at `fd287d3` afterwards — 5,427 on the reordered path,
the same **set** as the baseline path, `+0 / -0`.

**What it exposed is not ours to fix and is bigger than the one module.** IFOX00's
diagnostics for `IGC018` name `DVCMODU` and `DVCUFIX1` and not `DVCBPSEC`, a
profile only the `@ZA40405` level has; `IHADVCT` is in no other library of the
oracle's SYSLIB; and the SYSLIB list itself did not change on 2026-09-07. So
`MVSCE-LAB`'s `SYS1.AMACLIB` is **no longer in the state that produced the
reference corpus**, and MVS 3.8j keeps no member statistics to date the change.
Re-running the oracle there today would not reproduce the decks we measure
against. Their call and their stage-1 direction — but it is the strongest
argument yet for a reference system that is pinned rather than live, and for us
it is the reason `#345` (`-am`, the macro and copy code source summary) stopped
being a listing nicety.

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
