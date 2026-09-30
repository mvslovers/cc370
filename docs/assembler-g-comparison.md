# Assembler G 27A against Assembler XF — what as370 could take from it

**Status: written for mvslovers/cc370#521.** Only the §6 findings have been
run on MVS: IFOX00 on MVSTK5-REF, JOB00281–00288, 2026-09-30, with macro
snapshots taken before and after.
Every statement about Assembler G rests on the sources in [§1](#1-sources); every
statement about as370 says whether it was *read* from the code or *measured* by
assembling a probe on the host; every statement about XF says where it comes
from. Where no primary source was found, the row says so.

**The short version.**

- Assembler G is a modification of IBM **Assembler F**, not of XF. Most of what
  Waterloo calls extensions are extensions *over F*, and XF — IBM's own
  successor to F — adopted many of the same things independently: `&SYSDATE`,
  `&SYSTIME`, `&SYSPARM`, `PUSH`/`POP`, `OPSYN`, `WXTRN`, the 3-operand `EQU`,
  operandless `DROP`, `PRINT` inside macros, eight-character `TITLE` names,
  the extended branch-register mnemonics. Measured against XF the delta is much
  smaller than the G documentation suggests.
- G's **three documented incompatibilities with F** (defaults `LOAD,NODECK`;
  the `BxR` mnemonics in the default instruction set; `SYSLIN` preferred over
  `SYSGO`) are all either host-irrelevant or already XF behaviour.
- What is **genuinely G-only** and worth anything to as370 is small:
  `&SYSSTYP`, the `LCLC &X*n` length declaration, `&SYSECT`/`&SYSNDX` in open
  code, G's `&SYSDATE`/`&SYSTIME` formats, and three listing pages (literal
  cross-reference in G's format, the squished/multi-column XREF, the USING map).
  None of the language items occurs even once in the IBM corpora measured
  ([§5](#5-is-any-of-it-in-real-source)). They belong in an optional `G`
  dialect if one is ever built, not in the default.
- The investigation turned up **as370-versus-XF divergences that have
  nothing to do with G** ([§6](#6-findings-independent-of-g)), all confirmed
  against IFOX00 and filed as #525–#535. Among them are a literal that
  assembles to the wrong bytes with rc 0, and an `EQU` type operand that as370
  ignored in open code (#525, fixed). The 1,110 statements of the IBM maclib that
  use that operand turned out not to be affected: they sit in macro bodies, and
  IFOX00 answers `U` for a macro-generated symbol too (JOB00291). They are the
  most actionable result of this reading.

---

## 1. Sources

What was actually read, and what each is good for.

**Primary — Assembler G**

| Source | Where | Used for |
|---|---|---|
| *A Guide to Using the University of Waterloo Level G Assembler*, 10th ed., June 1976 (V2L7a) — "Usage Guide" | bitsavers `pdf/univOfWaterloo/V2L7_ASMG_University_of_Waterloo_Assembler_G_Usage_Guide_10th_ed_197606.pdf` (fetched from the trailing-edge mirror; `www.bitsavers.org` answered 403) | options pp. 6–12, data sets pp. 13–14, BATCH p. 15, EXECUTE p. 16, UPDATE p. 17, **the EXTEN extensions pp. 18–21**, output pp. 22–27, invocation p. 28, messages App. A, instruction sets App. B |
| *Assembler (G) Implementation Guide*, 10th ed. (V2L7a) | same directory, `V2L7A_ASMG_-_University_of_Waterloo_Assembler_G_Implementation_Guide_10th_ed_197693.pdf` | incompatibilities and extension list pp. 6–8, distribution p. 9, **change history V2L3 … V2L7a pp. 25–35** (the `V7Axx` tags that also appear in the source) |
| `asmg27a.tgz` (MD5 `F91F9764…9C`, matches the page) — Dan Skomsky's CBT-593-derived source with the March 1976 updates applied, plus PTF #1 | jaymoseley.com `hercules/downloads/archives/asmg27a.tgz`, linked from `hercules/compilers/list_of.htm#ASMG27A` | the source itself: 44 modules (≈43,000 statements), 74 macros, the option table (`ASMGF1`, label `OPTEST`), the default-option bytes (`ASMGASM` `PARBYT*`), the instruction-set modules `ASMGIS00…ASMGIS71`, the system-variable names (`MACLIB(COMMON)`), and every `EXTEN` gate |

The OCR of both PDFs is poor; every claim below that comes from them was
cross-checked against the source where the source could answer it.

**Secondary — Assembler G**

| Source | Where | Used for |
|---|---|---|
| Datapro 70, report 70E-886-01a/01b, "Assembler G, University of Waterloo", **November 1973** | bitsavers `pdf/datapro/datapro_70/Datapro_70_Volume_3_Section_E.pdf`, PDF pages 326–327 | historical context, performance table, the "3 incompatibilities / 13 extensions" summary |
| Jay Moseley, *Language Compilers Available for MVS 3.8* | jaymoseley.com `hercules/compilers/list_of.htm#ASMG27A` | provenance of the archive, install sequence |
| Jay Moseley, *System Compiler/Language/Tools Pack* (SYSCPK 01.44) | jaymoseley.com `hercules/compilers/syscpk.htm` | that SYSCPK carries ASMG procedures |

**Datapro describes an older level than the one analysed.** It lists 13
extensions under EXTEN (Nov. 1973, pre-V2L7); the V2L7a Usage Guide lists 23.
It also names the section-type variable `&SYSTYP`; the Usage Guide (p. 18), the
Implementation Guide (p. 8) and the source all spell it **`&SYSSTYP`** — the
name is stored in `MACLIB(COMMON)` in G's internal character code and decodes
to `SYSSTYP`. This document uses the source's spelling.

**Level analysed.** 27A = V2L7a, release date 21MAR76 (Implementation Guide
p. 33); the root phase `ASMGASM` carries the eyecatcher `ASMGV2L7`.

**Assembler XF** is read from the local IFOX00 source (`~/repos/mvs/ifox-src/all/`,
IBM proprietary — cited by file and line, never quoted) and from as370, which is
byte-identical to IFOX00 over the 950-module ecosystem corpus. Where neither
answers, the XF cell says "not verified".

**Citations into the ASMG source** use module and label names (`ASMGF1`
`OPTEST`, `ASMGF2` `VARSYM`, `ASMGF7C` `EQUINVER`, `ASMGASM` `PARBYT*`). Because
ASMG is a modification of IBM's IEUASM (Usage Guide p. 3), some of those
identifiers are likely IBM's; they are cited as identifiers only, and no ASMG
source text is reproduced here.

**as370** is read from `as370/src/as370.c`, `as370/include/opc_table.h`,
`as370/README.md` and the issue tracker, and measured with probe files
assembled by the as370 built from this tree (`as370 V1.0 - Sep 30 2026`). The
probes are our own code; their shapes are listed in [§8](#8-probe-shapes-used).

---

## 2. What Assembler G is

A modification of OS/360 Assembler F (IEUASM), begun at Waterloo in 1967 and
first installed March 1968 (Usage Guide p. 5; Datapro). Its stated aims were
speed, a batch processor for student jobs, a compressed cross-reference,
suppressible ESD/RLD listings and selectable instruction sets (Usage Guide
p. 5). Datapro's benchmark puts it at 4–5× Assembler F in macro-heavy jobs and
close to Assembler H in a much smaller region.

The architecture is F's: the phase names `F1`, `F2`, `F3`, `F7x`, `F8x`, `FPP`
survive as `ASMGF1` … `ASMGFPP`. **Every language extension is gated by one
option, `EXTEN`** (default on); `NOEXTEN` restores strict F rules, and
`INSTSET=0` restores F's opcode table (Usage Guide p. 7). G is therefore already
a two-dialect assembler, and that switch is the natural model for the dialect
question in #521.

---

## 3. The option set

G's PARM table is `APARM` entries in `ASMGF1` (label `OPTEST`), with minimum
unique abbreviations. The defaults (Usage Guide p. 12) are
`ALGN, NOBATCH, CALIGN=0, COLUMN=1, NODECK, NOESD, NOEXECUTE, EXTEN, EXTIME=5,
INSTSET=1, LINECNT=55, LIST, LOAD, LREF, LSETC=8, NUM, OS, PRINTER, NORENT,
NORLD, SPACE=MAX-4K, STMT, SYSPARM=, NOTERM, NOTEST, UMAP, UPCOND=12,
NOUPDATE, UPLIST, UTBUFF=3, XREF, YFLAG`.

XF's PARM keywords are read from `ifox0d.asm:674-768`: `DECK OBJECT XREF ESD
RLD RENT ALIGN TERM NUM STMT TEST MCALL ALOGIC MLOGIC LIBMAC SYSMAC YFLAG LIST
BUF FLAG LINECOUNT SYSPARM LOAD ALGN CALLS MINBUF MSGLEVEL WORKSIZE` and their
`NO` forms, with `XREF(FULL|SHORT)` at `ifox0d.asm:398-409`.

| Option (G) | XF | as370 today | Recommendation |
|---|---|---|---|
| `LIST`, `DECK`, `LOAD`/`OBJECT`, `ESD`, `RLD`, `TERM`, `NUM`, `STMT`, `TEST`, `RENT`, `ALGN`, `LINECNT`, `SYSPARM`, `YFLAG` | all present (`ifox0d.asm`) | host CLI: `-a[e,r]`, `-o`, `--sysparm=` (read, `as370.c:7151`) | not relevant — option spelling is a driver matter |
| `BATCH` (`MULT`): many decks in one SYSIN, batch summary (UG p. 15) | absent | one file per invocation | not relevant — a host loop does this |
| `EXECUTE`, `EXTIME=`: load-and-go under a one-pass loader (UG p. 16) | absent | — | not relevant |
| `UPDATE`, `SYSUP`, `UPLIST`, `FULLUPLIST`, `UPCOND=`: apply an IEBUPDTE-format deck to SYSIN and assemble the result (UG p. 17) | absent | — | intentionally not supported — the host has version control |
| `INSTSET=` 0/9/20/44/60/67/70/71 | absent (one table, `genop.asm`) | one table plus the Hercules S37X extras decided in #57 | see [§4.7](#47-instruction-set-and-mnemonics) |
| `EXTEN`/`NOEXTEN` | absent | — | model for a dialect switch, see [§7](#7-dialects) |
| `LREF`/`NOLREF` (default `LREF`) | literal cross-reference exists but is part of `XREF`, no separate option (`ifnx6a.asm` header lines 1–70, routine at ~1388) | no XREF page at all (`--help`: `-as` "not yet implemented") | see [§4.5](#45-listings-and-cross-references) |
| `XREF`, `XREF=SHORT`, `FULLXREF` (UG p. 11) | `XREF(FULL)`/`XREF(SHORT)` | none | see §4.5 |
| `UMAP`/`NOUMAP` (default on) — USING map | absent | `--usings=FILE` exports the events as data (#393, read) | see §4.5 |
| `COLUMN=` 0–3 — columns for UMAP/XREF/RLD | absent | — | optional, listing only |
| `CALIGN=` — column for comments of generated statements | absent | — | not relevant |
| `FULLLIST` — list library macros as edited | nearest is `LIBMAC` (`ifox0d.asm`); behaviour not compared | — | not relevant |
| `LSETC=` — default maximum SETC length (8) | absent | — | only with the `LCLC &X*n` extension, §4.1 |
| `DOS` — flag Q-/L-constants, unsorted RLD | absent | — | not relevant |
| `SPACE=`, `UTBUFF=`, `CMS`, `PRINTER` | absent (XF has `BUF`/`WORKSIZE`) | — | not relevant |

---

## 4. The language, area by area

Column key. **XF**: what IFOX00 does and where that was read.
**G**: what Assembler G does; `EXTEN #n` is the item number in the Usage Guide's
list (pp. 18–21). **as370**: *measured* = a probe was assembled; *read* = taken
from the code or tracker. **Rec.**: one of *implement* / *implement as optional
dialect behaviour* / *already supported* / *not relevant* / *intentionally not
supported*.

### 4.1 Macro processing

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| `GBLx`/`LCLx`/`SETx`/`AIF`/`AGO`/`ANOP`/`ACTR`/`MEXIT`/`MNOTE` | yes (`genop.asm`) | yes — F's | yes (read; README) | already supported |
| `AIFB`/`AGOB` (F's old spellings of `AIF`/`AGO`) | yes (`genop.asm:284-285`) | yes, all instruction sets | **no** — "Undefined operation code" (measured) | implement (XF feature, JOB00288; trivial aliases; corpus count 0): #533 |
| `PRINT` inside a macro definition | yes — IBM mapping macros `CVT`, `IEFJFCBN`, `IKJTCB` … do `PUSH PRINT`/`PRINT`/`POP PRINT` inside the macro (8 maclib members) | EXTEN #1; F forbids | yes (measured, no diagnostic) | already supported |
| Attributes of a symbol defined inside one macro, read in another | not verified | EXTEN #2; F keeps attributes only for open-code symbols | yes: an outer macro generates `X DC CL3'A'` and passes `X` to an inner macro, whose `L'&S` gives 3 (measured) | already supported |
| `&SYSNDX`, `&SYSECT` in **open code** | `&SYSECT` in open code is IFO006 (as370 comment citing IFOX, `as370.c:2137`) | EXTEN #3: both allowed in open code | `&SYSECT` rejected in open code (read) | implement as optional dialect behaviour |
| `&SYSDATE` | yes, format `MM/DD/YY` (`as370.c:453`, from `ifnx1j.asm`) | EXTEN #3, format `YYMONDD` (e.g. `70JAN15`, UG p. 18) | `MM/DD/YY` (read) | already supported (XF); G's format → optional dialect |
| `&SYSTIME` | yes, `HH.MM` | EXTEN #3, `HH:MM:SS`, changes per deck in BATCH (UG p. 18) | `HH.MM` (read) | already supported (XF); G's format → optional dialect |
| `&SYSPARM` in open code and macros | yes (`ifnx1j.asm:1358` per `as370.c:2132`) | EXTEN #3 (and `SYSPARM=` ignored under NOEXTEN, UG p. 10) | yes (measured) | already supported |
| **`&SYSSTYP`** — type of the section the macro was called in: `CSECT`, `DSECT` or `COM` (`START` reported as `CSECT`) | **absent** (not in any IFOX module) | EXTEN #3; UG pp. 18–19 gives the use case: restore the caller's section at macro end; source `ASMGF3` CSECT/START handling, name in `MACLIB(COMMON)` | not implemented; `&SYSSTYP` in a model statement is substituted as **empty with rc 0** (measured) — the same silence as #97 | implement as optional dialect behaviour — cheap; HLASM later has a variable of the same name (general knowledge, not checked here) |
| SETC maximum length declared per variable: `LCLC &A*100` (1–255), default from `LSETC=` | absent; XF SETC values are up to 255 without declaration | EXTEN #5 (UG p. 19); source `ASMGF2` routine `VARSYM` scans `*n` after a `GBLC`/`LCLC` name | **rejected**: the variable is not declared, the use is IFO006 (measured) | implement as optional dialect behaviour, low priority (corpus 0) |
| SETC values longer than 8 characters | yes | only under EXTEN; NOEXTEN caps at 8 (`ASMGF3`, `EXTEN` test before the 254/7 limits) | yes (measured: 12 characters kept) | already supported |
| `K'` on any SETC (and in G on SETA/SETB) | not verified | EXTEN #6; `K'` of a SETA is its digit count, of a SETB is 1 | `K'` of a 12-char SETC = 12 (measured); SETA/SETB not measured | already supported for SETC; SETA/SETB → optional dialect, only if needed |
| SETC holding a `C'…'`/`X'…'`/`B'…'` term used in SETA | not verified | EXTEN #7 (`ASMGF3`, EXTEN test before the C/X/B branch) | direct `&A SETA C'A'`/`X'10'`/`B'101'` evaluate to 193/16/5 (measured); via a SETC variable not measured | already supported (direct form); indirect form not measured |
| `COPY` bringing in `MACRO`…`MEND` (programmer macros from a library) | not verified | EXTEN #8, nested `COPY` to five levels | yes — a `COPY`'d definition is called and expands (measured) | already supported |
| Positional and keyword operands intermixed | not verified | EXTEN #22, prototype **and** call | call `MYM K=2,3` against `&P,&K=1` assembles `&P=3,&K=2` silently (measured); prototype not measured | already supported (call); XF check needed |
| Null positional operand in a prototype | not verified | V2L7 change 26 (Impl. p. 33) | not measured | needs a probe |
| `LCLx`/`GBLx`/`ACTR` anywhere before first use | not verified — IFOX has a statement-ordering message (`erms.asm:37`), which suggests an ordering rule | EXTEN #23 | accepted silently in a macro and in open code (measured) | XF check needed before any recommendation |
| SET-symbol dimension up to 9999 | limit not read; IFOX has an illegal-dimension message (`erms.asm:45`) | EXTEN #19 (NOEXTEN: F's limit) | `LCLA &X(2000)` accepted (measured) | already supported up to at least 2000; XF limit to be measured |
| Substring whose length runs past the end: `'ABC'(2,5)` | IFOX has messages for a first expression past the end and a negative second one (`erms.asm:129-134`), none for a second one past the end | EXTEN #5: second expression may be up to 255; PTF readme says G and H truncate while "IFOX00 doesn't like" it (secondary, and ambiguous — the MNOTE it mentions comes from G's own macro) | truncates to `'BC'` silently (measured) | XF behaviour to be measured |
| `MNOTE 'text'` without severity | yes — 1,250 statements in MVSBLD | EXTEN #21: printed as a comment | printed as a NOTE (measured) | already supported |
| Undefined variable symbol in a model statement | IFO006 (#97) | — | substituted as empty (measured; #97 open) | implement (#97) — not a G item |

### 4.2 Symbols and attributes

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| Extended `EQU value,length,type` | yes — IFOX has range messages for expressions 2 and 3 (`erms.asm:78,80`); IBM maclib uses the 3-operand form 1,110 times | EXTEN #10: length 0–65535, type 0–255 (`ASMGF7C`, `EQU` … `EQUINVER`) | length operand honoured (`as370.c:6305`; measured `L'A`=4); **type operand ignored — `T'` of `A EQU X'40',,C'X'` is `U`** (measured) | **implement** — XF feature, confirmed on IFOX00 (JOB00281): #525 |
| `L'` of any type letter | yes | NOEXTEN: A–Z except M–U and `$`; EXTEN: any byte (`ASMGF3` comment block) | not a G item | not relevant |
| Eight-character `TITLE` name | yes — 31 MVSBLD modules | EXTEN #14 (NOEXTEN: 4) | accepted (measured) | already supported |
| Only one named `TITLE`, not necessarily the first | XF flags a second named `TITLE` (`erms.asm:113`) | EXTEN #15 | two named `TITLE`s after an unnamed one accepted silently (measured) | XF-fidelity finding, confirmed (`IFO104`, JOB00286): #530 |
| Larger local dictionary (>64K) | n/a | yes (UG p. 5) | host memory | not relevant |

### 4.3 Literals

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| Literal pools, `LTORG`, `=V`/`=A`/`=F`/… | yes | yes (F's) | yes (read; README; #317/#327/#329/#331 closed) | already supported |
| Expression as a literal's duplication or length factor: `=(2*2)F'7'` | yes: 16 bytes, four fullwords of 7 (JOB00283); **0 uses** in MVSBLD and the maclib (scanner confirmed against a positive control) | EXTEN #16 (`ASMGF7D`/`ASMGF8M`, V7A13) | **assembles one fullword of zeros, rc 0** (measured) — wrong object, silently | not relevant as a G feature; the silent wrong object is #527 |
| `*` in a DC/DS/literal duplication or length factor | yes — 119 statements in 102 MVSBLD modules | EXTEN #17 (V7A14) | `DC (*-A)X'00'` and `DC CL(*-A)'X'` correct (measured) | already supported |
| A literal combined with other terms: `=F'1'+4` | `IFO161 INVALID LITERAL`, severity 8 (JOB00284) | not listed as an extension | the `+4` is **dropped, rc 0** (measured) | #528 |
| Literal cross-reference | yes, printed with the XREF (`ifnx6a.asm`) | `LREF` option, default on; EBCDIC collating order of the literal text; columns LOCATION, LENGTH, DEFINITION, LITERAL (truncated at 100), REFERENCES (14 per line); unaffected by `PRINT OFF`/`NOLIST`/`NOXREF` (UG p. 25) | none | see §4.5 |

### 4.4 Expressions and self-defining terms

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| Unary `+`/`-` | yes — 23 statements in 18 MVSBLD modules start an EQU/DC/DS operand with `-` | EXTEN #13, assembly phases only, not conditional assembly | `EQU -4`, `A(-5,+6)`, `-1(2)` correct (measured) | already supported |
| Parenthesis depth / term count | XF flags more than **6** levels (`erms.asm:244`) | F: 5 levels, 16 terms; EXTEN #13: 11 levels, 25 terms | 8 levels accepted silently (measured) | already supported for G's range; the missing XF diagnostic (`IFO233`, JOB00285) is #529 |
| Four-byte self-defining terms (`X'12345678'`, `C'ABCD'`, 32-bit `B'…'`) | presumed yes (as370 accepts and is IFOX-validated) — not isolated | EXTEN #18 (NOEXTEN: F's 3 bytes / 24 bits, `ASMGF7V`/`ASMGF8V`) | correct (measured); `C'ABCDE'` (5 chars) accepted silently and `DC A(A)` emits `C2C3C4C5` — the leftmost character dropped (measured) | already supported; the missing diagnostic (`IFO169`, JOB00287) is #531 |

### 4.5 Listings and cross-references

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| Symbol cross-reference, full | yes, `XREF(FULL)` | `FULLXREF` — F's format | none (`-as` not implemented) | implement the XF page first (existing open point, `as370/README.md`) |
| Symbol cross-reference, short (defined but never referenced removed) | yes, `XREF(SHORT)` | `XREF=SHORT` (V2L7 change 15) | none | same page, same option |
| "Squished" XREF: one stream of `SYMBOL LENGTH,VALUE,DEFINITION REFERENCES`, and 1–2 columns via `COL=` | absent | default `XREF` format (UG p. 26) | none | implement as optional dialect behaviour (listing only), after the XF page |
| Literal cross-reference | yes (inside XREF) | `LREF`, G's own format (above) | none | XF format first; G's collated, long-literal format as an optional listing style — it reads better for 100-character literals |
| USING map: per register, USING statement, DROP statement (or `END`), value, label (`*** POP ***` for a `POP USING`) | absent | `UMAP`, default on (UG p. 24; source `ASMGFPP`) | the same events already exist as data, `--usings=FILE` (#393) | implement as optional listing — rendering, not new analysis |
| RLD in several columns | absent | `COL=2`/`COL=3` | — | not relevant |
| ESD/RLD pages off by default | on by default in XF | — | `-ae`/`-ar` | not relevant (a default) |
| `***MNOTE***` flag, ORG printing old and new counter, EQU/ORG/USING operand in ADDR2 (UG p. 23) | ADDR2 behaviour matches (#226) | yes | ADDR2 for EQU/ORG (read) | not relevant beyond XF fidelity |
| Batch summary, header page with `LEVEL=G`, `SYSTEM=`, `DAY=` | absent | yes | — | not relevant |
| Error-message prefix `ASMGnnn` instead of `IEUnnn` | `IFOnnn` | yes | cites IFOX numbers | not relevant |

### 4.6 Object generation and control statements

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| `CSECT`, `DSECT`, `START`, `ENTRY`, `EXTRN`, `END`, `LTORG`, `ORG`, `USING`, `DROP`, `PUSH`/`POP` | yes | yes; `PUSH`/`POP` five levels, not in IS=0/IS=9 (Impl. V2L7 items 25 and 46, p. 33) | yes (read); `PUSH` depth 16 (read, `as370.c:5582`) | already supported |
| `WXTRN` | yes | yes, all instruction sets (Impl. change list before V2L6, item 42, p. 29) | yes (measured) | already supported |
| Operandless `DROP` drops all | yes (the branch #394 made reachable) | EXTEN #9 | yes (measured; #394) | already supported |
| Unnamed `COM` | yes (`genop.asm`) | yes | **no** — "Undefined operation code" (measured; #229 open) | implement (#229) — XF feature, corpus count 0 |
| Named `COM` | not verified | EXTEN #4; `ASMGF7E` COM routine accepts a name only under EXTEN | no `COM` at all | implement as optional dialect behaviour, after #229 |
| Labelled `CNOP` | yes — `IECVEXCP` (MVSBLD) and `EVENTS` (maclib) | EXTEN #11 | label defined at the aligned counter (measured) | already supported |
| Labelled `ORG` | yes — `IHALRB` (7) in the maclib, `IKJEGWHR` in MVSBLD | EXTEN #11 | **label not defined**: `DC A(L1)` after `L1 ORG T+8` is "Undefined symbol" (measured) | implement — XF feature; IFOX00 gives the label the counter before the ORG (JOB00282): #526 |
| Unlabelled `DSECT` | yes — 10 MVSBLD modules, `IEZCTGPL`/`IHACCW`/`IHACSW` | EXTEN #11 | accepted (measured) | already supported |
| `DXD`, `CXD`, Q-constants | yes | yes | not implemented (measured; #76 open) | implement (#76) — not a G item |
| `ICTL` | yes (`genop.asm`) | yes | **no** (measured) | implement, low priority (corpus 0; IFOX00 accepts it, JOB00288): #534 |
| `ISEQ`, `REPRO` | yes | yes | yes (read) | already supported |
| `PUNCH` | yes (`genop.asm`) | yes | **no** — "Undefined operation code" (measured) | implement, low priority (corpus count 0; IFOX00 writes the card, JOB00288): #535 |
| `END` inside a `COPY` member ends the assembly, rest of the member is comment | not verified | EXTEN #20 | the assembly ends at the copied `END`; the statement after `COPY` is not assembled (measured) | already supported; XF check needed |
| Generated comment: a blank inside a generated operand starts the comment | not verified | EXTEN #12 | not measured | needs a probe |
| Object deck | — | "the same as Assembler (F)" but **fewer TXT cards** (better packing) and a different END-card IDR — date and time in the second IDR slot when there is none (UG p. 27; V2L6 change 14) | IFOX-identical TXT packing | not relevant — but a G-vs-XF deck comparison must normalise TXT packing and the END card; ESD/RLD content is comparable |
| `INSTSET=20`: one ESD item per card for the Model 20 loader | — | Impl. change list before V2L6, item 46, p. 29 | — | not relevant |

### 4.7 Instruction set and mnemonics

Measured by extracting the opcode tables (names only): G `ASMGIS70`, XF
`genop.asm`, as370 `opc_table.h`.

- **G's default table (IS=70, `INSTSET=1`) contains no machine instruction XF
  lacks.** XF additionally has `CLRCH CONCS DISCS IPTE MVCIN TPROT`.
- G's IS=0 ("compatible with Assembler F") differs from IS=70 only by lacking
  the fourteen `BxR` mnemonics and `PUSH`/`POP`. G's own macro library defines
  `BER`, `BNER`, `BZR`, `BLR`, `BNLR`, `BNZR` as macros — presumably a relic of
  assemblers without those mnemonics (not traced). This is the shape of the
  "incompatibility" Datapro and the Implementation Guide (p. 7) mention: under
  G's default table, programs defining these mnemonics as macros draw errors.
- The directive set of IS=70 equals XF's (`AGOB AIFB OPSYN ICTL ISEQ REPRO
  PUNCH COM CXD DXD WXTRN PUSH POP ACTR …`).
- as370 has every `BxR` mnemonic (measured, `as370/tests/brmnem.s`), and lacks
  **`IPTE` and `TPROT`** from XF's machine table (table diff) — a documented,
  deliberate gap (`opc_table.h:388`, #51).

| Feature | XF | G | as370 today | Rec. |
|---|---|---|---|---|
| `BER`, `BNER`, … `BNMR` | yes | IS=60/70/71 | yes | already supported |
| `OPSYN` | yes (`genop.asm:289`) | yes; only `ICTL` or another `OPSYN` may precede it (Impl. change list before V2L6, item 28, p. 29) | **no** (measured) | implement — XF feature (JOB00288), corpus count 0, so low priority: #532 |
| Instruction-set selection (360/20, /44, /67 RPQ, DOS, F-compatible, CMS `HVC`) | absent | `INSTSET=` | one table + S37X extras (#57) | not relevant; #57 is the existing precedent if an opcode dialect is ever wanted |
| Restricted table for macro expansions, "illegal if generated" flag (`ASMGIS11`, `ASMGF7X` table doc) | absent | internal | — | not relevant |
| `IPTE`, `TPROT` | yes | no | no — left out deliberately because as370 has neither the RRE nor the SSE format (`opc_table.h:388`, #51) | intentionally not supported (existing decision, #51) — not a G item |

---

## 5. Is any of it in real source?

Counted over two IBM corpora with a scanner that looks only at the operation
and operand fields of non-comment, non-continuation cards. **Counts and module
names only — the corpora are IBM proprietary and nothing from them is
reproduced here.** Every construct the scanner reports as zero was first
confirmed non-zero on a positive-control file containing each shape once.

- **MVSBLD** — 5,528 `.ASM` modules (Dave Kreiss, *MVS from Source*), largely
  PL/S compiler output.
- **maclib** — the 353 non-HTML members of the stben.net MVS 3.8 maclib. This is
  the better witness for macro-language rows.

| Construct | MVSBLD | maclib | Reading |
|---|---|---|---|
| `&SYSSTYP` / `&SYSTYP` | 0 / 0 | 0 / 0 | G-only, never used in IBM source |
| `LCLC`/`GBLC` with `*n` length | 0 | 0 | G-only |
| `=(expr)` literal duplication | 0 | 0 | G extension, unused |
| `OPSYN`, `AIFB`, `AGOB`, `ICTL`, `COM`, `DXD`, `CXD`, `PUNCH` | 0 each | 0 each | XF features as370 lacks, and IBM's MVS source does not use them |
| 3-operand `EQU` | 6 stmts / 4 modules (`BLSDVECT BLSRVECT BLSUVECT IGE0003C`) | **1,110 stmts / 27 members** (`CVT`, `IHAPSA`, `IKJTCB`, `IEZDEB`, …) | XF feature, heavily used in mapping macros. The `T'` gap reaches none of the 1,110: those symbols are macro-generated, and IFOX00 answers `U` for them as well (#525, JOB00291) |
| 2+-operand `EQU` | 342 / 74 | 1,111 / 28 | |
| Labelled `ORG` | 1 (`IKJEGWHR`) | 7 (`IHALRB`) | XF accepts; as370 drops the label |
| Labelled `CNOP` | 1 (`IECVEXCP`) | 1 (`EVENTS`) | |
| Unlabelled `DSECT` | 11 / 10 | 3 (`IEZCTGPL IHACCW IHACSW`) | |
| `TITLE` name longer than 4 | 31 / 31 | 0 | |
| `*` in DC/DS duplication factor | 119 / 102 | 0 | |
| Leading unary `-` in EQU/DC/DS | 23 / 18 | 0 | |
| Operandless `DROP` | 3 (`BLSUALLO IEAVTRT2 IGC018`) | 0 | |
| `MNOTE` without severity | 1,250 / 123 | 1 (`SPLEVEL`) | |
| `PUSH`/`POP` | 6 / 6 | 8 / 8 | |
| `WXTRN` | 14 / 4 | 2 | |
| `&SYSDATE` / `&SYSTIME` / `&SYSPARM` | 180 / 4 / 6 statements | 1 / 0 / 0 | |

**Conclusion for objective 3:** the G-only language extensions do not occur in
the IBM MVS corpora at all. The EXTEN items that *do* occur (3-operand EQU,
labelled ORG/CNOP, unlabelled DSECT, long TITLE names, `*` in dup factors,
unary minus, operandless DROP) occur because XF accepts them too — they are XF
compatibility, and two of them (EQU type, labelled ORG) are where as370 falls
short. Programs written *for* G — Waterloo's own tree, university code of the
1970s — would be the population that uses the G-only items; the ASMG source
itself is one such program and could be measured on the host, subject to the
licence question in §9.

---

## 6. Findings independent of G

Each row was first measured with as370 on a probe of our own, and then
**confirmed against IFOX00** on MVSTK5-REF (the pinned oracle, `capture.py`,
macro snapshots before and after), 2026-09-30. Every row has its own issue,
which carries the probe, both results and the job number.

| # | Probe | IFOX00 (measured) | as370 (measured) | Issue |
|---|---|---|---|---|
| 1 | `A EQU X'40',,C'X'`, `T'A` in a macro | `X` (and `F` for `,4,C'F'`), rc 0 — JOB00281 | `U` for both, rc 0 | #525, fixed; reaches open code and COPY members only (JOB00291) |
| 2 | `L1 ORG P+16` after 8 bytes, `DC A(L1)` | `L1` = **8**, the counter before the ORG, rc 0 — JOB00282 | "Undefined symbol", rc 8 | #526 |
| 3 | `L 1,=(2*2)F'7'` | 16 bytes, four fullwords of 7, rc 0 — JOB00283 | **one fullword of zeros**, pool reordered, rc 0 | #527 |
| 4 | `L 2,=F'1'+4` | `IFO161 INVALID LITERAL`, sev 8, instruction zeroed — JOB00284 | accepted, `+4` dropped, rc 0 | #528 |
| 5 | 6/7/8 nested parentheses in `EQU` | 6 fine; 7 and 8 `IFO233`, sev 8, value 0 — JOB00285 | all accepted, value 1 | #529 |
| 6 | an unnamed, then two named `TITLE`s | `IFO104` on the second named one, sev 4 — JOB00286 | no message | #530 |
| 7 | `A EQU C'ABCDE'`, `DC A(A)` | `IFO169 INVALID SELF-DEFINING TERM`, sev 8, value 0 — JOB00287 | `C2C3C4C5`, rc 0 | #531 |
| 8 | `&FOO` / `&SYSSTYP` in a model statement, undeclared | IFO006 (already #97) | substituted empty, rc 0 | #97 |
| 9 | `OPSYN` | accepted, `LR2 1,2` = `1812` — JOB00288 | "Undefined operation code" | #532 |
| 10 | `AIFB` / `AGOB` | accepted, behave as `AIF`/`AGO` — JOB00288 | "Undefined operation code" | #533 |
| 11 | `ICTL 1,71,16` | accepted — JOB00288 | "Undefined operation code" | #534 |
| 12 | `PUNCH ' PUNCHED CARD'` | the card goes into the deck between TXT and END — JOB00288 | "Undefined operation code", no card | #535 |

`COM`, `DXD` and `CXD` are also missing, and are already #229 and #76.
`IPTE`/`TPROT` are missing deliberately (#51).

Rows 3 and 4 are the serious ones: as370 produces an object that differs from
what was written, with a zero return code. Rows 5–7 are missing diagnostics,
and in 5 and 7 the value differs as well, because IFOX sets a flagged term to 0.

---

## 7. Dialects

G already is the dialect mechanism #521 sketches, and its switch maps onto the
proposed names directly:

| Proposed dialect | Nearest real thing | Would change |
|---|---|---|
| `XF` (default) | IFOX00 | nothing — as370's contract |
| `G` | ASMG V2L7a, `EXTEN` | `&SYSSTYP`; `&SYSECT`/`&SYSNDX` in open code; `&SYSDATE` as `YYMONDD`, `&SYSTIME` as `HH:MM:SS`; `LCLC &X*n` and a default SETC length; named `COM`; `K'` of SETA/SETB; the squished XREF, `LREF` and `UMAP` pages on by default |
| `F` | ASMG `NOEXTEN,INSTSET=0` | the *restrictions*: no PRINT in macros, SETC ≤ 8, 3-byte SDTs, 5 paren levels / 16 terms, no unary, no `BxR`, no `PUSH`/`POP`, declarations only at the top |
| `AS370` | — | the host extensions (S37X opcodes, #57), the data exports (`--sym`, `--stmts`, `--usings`) |

Two observations for that decision:

- **A G dialect is small and additive.** Every item above is either a new
  system variable, a new declaration syntax or a listing format; none changes
  the object code of a program that assembles under XF. That makes it cheap to
  gate and cheap to test, but also means nobody *needs* it unless they have
  Waterloo-era source.
- **An F dialect would be mostly diagnostics** — it removes things. Its value
  is checking that source still assembles under F, which nobody in the
  ecosystem is asking for. Recommend not building it.

---

## 8. Probe shapes used

All our own code, assembled with the as370 of this tree; the files live outside
the repository. Listed so they can become `as370/tests/` fixtures once the
maintainer picks rows.

`EQU *,4,C'F'` / `EQU *,,C'X'` with `L'`/`T'`; `LCLC` 12-char SETC with `K'`;
`SETA C'A'`, `X'10'`, `B'101'`; `PRINT NOGEN` in a macro; `LCLA` after a model
statement; `GBLA` after a DC in open code; unnamed and named `COM`; `EQU -4`,
`A(-5,+6)`, `-1(2)`; 4-byte `X`/`C`/`B` terms and a 5-char `C'…'`; `(*-A)` and
`CL(*-A)` in DC; operandless `DROP`; `MNOTE 'text'`; `OPSYN`; `AIFB`/`AGOB`;
`ICTL`; named `TITLE` with a 5-char name and a second named `TITLE`; `&SYSSTYP`;
`&SYSPARM` in open code; `MYM K=2,3`; `=F'1'+4`, `=A(*)`, `=(2*2)F'7'`,
`=2F'7'`, `=3C'A'`; labelled `LTORG`, `ORG`, `CNOP`; unlabelled `DSECT`;
`WXTRN`; `LCLA &X(2000)`; `DXD`/`CXD`; `&SYSNDX&SYSECT`; a `COPY`'d macro
definition; `LCLC &C*20`; `END` inside a `COPY` member; eight nested
parentheses; `'ABC'(2,5)`; an outer macro passing a label it generated to an
inner macro that reads `L'`; `PUNCH`.

---

## 9. A second oracle — can G be run?

**Installable.** `asmg27a.tgz` holds five jobstreams: three IEBUPDTE loads
(SOURCE, MACLIB, LKEDCTL), one assembly of all modules into an object library,
one link-edit (Moseley; archive `ReadMe.txt`). The assembly job
`ASMGBASE.ASMG27A.jcl` runs its procedure step as `PGM=IFOX00` (with a
commented-out `PGM=ASMGASM` alternative beside it), so building G needs nothing
beyond a stock MVS 3.8j. The ReadMe's target names are `CBT593.ASMG27A.*`
on a 3330 volume; they need editing.

**Possibly already present.** Moseley's SYSCPK 01.44 lists procedures `ASMGC`,
`ASMGCG`, `ASMGCL`, `ASMGCLG` ("Assembler G (Waterloo)") beside `ASMXC…`
for IFOX00. **Whether TK4-, TK5 or MVS/CE ship SYSCPK with these procedures was
not verified** — the SYSCPK page does not say, and no system was queried.

**Measurement plan** (not executed). For each fixture chosen from §4/§6:

1. IFOX00 — the reference, as today.
2. ASMG `EXTEN` (the default) — G's behaviour.
3. ASMG `NOEXTEN,INSTSET=0` — G reduced to F. Comparing 1 with 3 separates
   "G-specific" from "XF-specific" without guessing: whatever 3 rejects and 1
   accepts is an XF addition; whatever 2 accepts and 1 rejects is a G addition.
4. as370 on the host.

Compare ESD and RLD content directly; compare TXT **after normalising packing**
(G packs differently, UG p. 27) and ignore the END card IDR. Compare listings
only for diagnostics (G's messages are `ASMGnnn`, XF's `IFOnnn`; map by
meaning). Submit one job at a time to the oracle host (it has wedged under two
concurrent snapshots before).

**A host corpus nobody has measured.** The ASMG source is ≈43,000 statements
of hand-written assembler with its own macro library — not PL/S and not cc370
output, the kind of input the existing corpora lack. It assembles under IFOX00,
so as370 should assemble it too, and a host-only differential run (before/after
an as370 change) needs no MVS. **But it is not simply Waterloo's code:** the
Usage Guide (p. 3) calls ASMG a modification of IBM's Assembler F (IEUASM). It
is IBM-derived code with Waterloo's changes, distributed via CBT tape 593, and
that distribution does not settle its licence. Treat it like the other
corpora — measure locally, report counts, do not commit it — until the
maintainer decides otherwise.

---

## 10. Open questions

- Every "not verified" XF cell above, most importantly: declaration placement
  (§4.1), intermixed keyword/positional in a **prototype**, `K'` of non-parameter
  SETC, SETC in SETA via a variable, `END` in a COPY member, the SET-symbol
  dimension limit, named `COM`, and substring overrun.
- Whether TK4-/TK5/MVS/CE carry SYSCPK's ASMG procedures.
- G's `UNUSED` option (bit in `PARBYT3`, "UNUSED" in the option table) — the
  Usage Guide does not document it and its use in the source was not traced.
- The meaning of G's labelled-ORG value (old or new counter) — the Usage Guide
  says only that it is valid.
- The licence status of the ASMG source (IBM-derived) for use as any corpus.
- Literals in `EQU` operands (listed in #521) were not probed; only literals in
  instruction operands were.
- Why G's macro library defines six `BxR` mnemonics as macros.
