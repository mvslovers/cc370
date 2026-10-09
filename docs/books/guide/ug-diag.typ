#import "../bookmaster/bookmaster.typ": *

= Diagnosing Problems <ug-diag>

#idx("diagnosing problems")
#idx("debugging")
A problem shows itself in one of two places: on the workstation, as a
message from the compiler, the assembler or the linkage editor, or on MVS,
as a wrong result, a return code you did not expect, or an abend. This
chapter shows how to read the build messages, how to use the assembler
listing and the load map, and how to go from the address of an abend back
to the statement that caused it. It ends with the tools that inspect and
compare what the build wrote.

There is no source-level debugger for programs built with cc370, and the
compiler writes no line number information: #cmd("-g") is accepted and ends
with the warning #cmd("target system does not support debug output"). The
link between the C source and the running program is the assembler listing.

The example is SUMUP from @ug-asm. Run without a parameter, it abends.

== Messages at Build Time <ug-diag-build>

#idx("messages", "at build time")
Each tool writes its messages to standard error and ends with a return code
that says how serious they were.

- *cc370* reports errors and warnings with the file name and the line
  number in the C source, in the form of the GNU C compiler. A warning
  does not stop the build\; an error does, and cc370 then ends with return
  code 1. Compile with #cmd("-Wall"), and treat each warning as a question
  about your code.
- *as370* reports each statement in error with its line number, as in
  @ug-asm-clock-session. When as370 runs under cc370, a warning, return
  code 4, is shown and the build goes on\; return code 8 or higher fails
  it.
- *ld370* reports, above all, external references that nothing defines.
  @ug-diag-unres shows the link of SUMUP without the library that holds
  ADDUP and REPORT.

#fig(caption: [A link with unresolved references])[
  #screen(raw(read("../ex/ug-diag/unres.txt")))
] <ug-diag-unres>

An unresolved reference is almost always one of two things: an object
module or library missing from the link, or an external name that is
spelled differently on the two sides. (A #cmd("-l") option given before the
#cmd("-L") option of its directory ends the link earlier, with
#cmd("cannot find -l")#var("name").) For the last, remember that cc370 cuts C names
to eight characters in upper case (@ug-asm-asmfromc): two C functions whose
names agree in their first eight characters have the same external name.

== The Assembler Listing of a C Program <ug-diag-listing>

#idx("listing", "of a C program")
cc370 compiles C to assembler language, and as370 can list what it
assembles. Pass #cmd("-a=")#var("file") to as370 with #cmd("-Wa,"):

```
cc370 -O1 -Wall -c -Wa,-a=sumup.lst sumup.c
```

The listing shows, for each statement of the generated assembler source,
its offset in the control section (#cmd("LOC")), the bytes it generated
(#cmd("OBJECT CODE")) and the statement itself. The object module is the
same as without #cmd("-a").

To find your way in it:

- The external symbol dictionary at the start lists each C function with
  external linkage as an entry point (type #cmd("LD")) with its offset:
  #cmd("MAIN") is at #cmd("000014").
- Comments that the compiler writes divide the code of each function:
  #cmd("* X-func main prologue"), #cmd("* Function main code"),
  #cmd("* Function main epilogue"), and the literal pool after it.
- Calls are easy to spot: #cmd("L 15,=V(")#var("NAME")#cmd(")") followed
  by #cmd("BALR 14,15"). The arguments are stored at #cmd("88(13)") and
  following just before.

Reading the code of a C statement takes some practice, because the
optimizer moves and combines code. For a first look at a function that
misbehaves, compile it with #cmd("-O0"), which generates code that follows
the source closely, at the price of a larger and slower program.

#idx("-mcsect")
The code of a C source is one control section without a name. To give it
one, which then also appears in the load map, compile with
#cmd("-mcsect=")#var("name").

== The Load Map <ug-diag-map>

#idx("load map")
The load map of a link says where each control section and entry point
lies in the load module. @ug-link-map showed the map of SUMUP, written by

```
cc370 -o sumup sumup.o -L. -lsum -Wl,--map,sumup.map
```

Each control section has an origin and a length. To find the section that
holds a given offset in the load module, look for the section whose origin
is at or below the offset and whose origin plus length is above it. Keep
the map of every build you send to MVS: an abend address can be traced only
with the map of the module that abended.

== Finding the Statement That Abended <ug-diag-abend>

#idx("abend", "finding the failing statement")
#idx("PSW")
Run SUMUP without a parameter:

```
//SUMUP    EXEC PGM=SUMUP
//STEPLIB  DD DSN=USER1.SUMUP.LOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSTERM  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
```

The step ends with abend #cmd("S0C9"), a fixed-point divide exception.

#fig(caption: [The abend of SUMUP: job log and the beginning of the
  dump])[_Output to be captured on MVS._] <ug-diag-abend-out>

To find the statement:

+ *Take two addresses from the dump.* The program status word (PSW) at the
  time of the abend holds the address of the instruction that would have
  run next, together with the instruction length code (ILC), the length of
  the instruction that failed. The list of loaded programs gives the entry
  point address of SUMUP.
+ *Compute the load address.* The entry point of a C program,
  #cmd("@@CRT0"), is not at offset 0 of the module: the first line of the
  load map gives its offset, #cmd("X'F8'") for SUMUP (@ug-link-map). The
  module was loaded at the entry point address minus that offset.
+ *Compute the offset in the module*: the PSW address, minus the load
  address, minus the instruction length. For example, with an entry point
  address of #cmd("X'0A10F8'"), SUMUP was loaded at #cmd("X'0A1000'")\; with
  a PSW address of #cmd("X'0A10C0'") after an instruction of 2 bytes, the
  failing instruction is at offset #cmd("X'10C0'") − #cmd("X'1000'") − 2 =
  #cmd("X'BE'").
+ *Find the section in the load map.* Offset #cmd("X'BE'") lies in the
  unnamed section from #cmd("sumup.o"), which begins at 0 and is
  #cmd("X'F8'") bytes long. The offset in that section is
  #cmd("X'BE'") − 0 = #cmd("X'BE'").
+ *Find the statement in the listing.* @ug-diag-lst shows the listing of
  #cmd("sumup.o") around #cmd("LOC 0000BE"): the instruction there is
  #cmd("DR 6,5"), a division.
+ *Find the C statement.* The code before the division stores the result of
  #cmd("ADDUP"), the sum, and the division is followed by the call of
  #cmd("REPORT"). The only division in #cmd("main") is #cmd("sum / n"), and
  register 5 holds #cmd("n"), the number of arguments. Without a parameter,
  #cmd("n") is 0.

#fig(caption: [Listing of sumup.o around offset X'BE'])[
  #set par(justify: false, leading: 0.32em)
  #let lst = (read("../ex/ug-diag/sumup.lst").replace("\f", "").split("\n")
    .map(x => x.trim(at: end)))
  #text(font: mono-font, size: 6.1pt,
    (lst.slice(10, 11) + lst.slice(84, 101)).join("\n"))
] <ug-diag-lst>

The offsets in the listing are offsets in the control section, which is why
step 4 subtracts the origin of the section (0 for #cmd("sumup.o"), which the link puts first). If the abend lies in a section
from a library, such as one of the C library, the map names the member, and
the error is usually in the arguments your program passed to it: look at
the call in your own code that led there. The chain of save areas in the
dump leads back to it: each function stores the address of its caller's
save area at offset 4 of its own, and each save area holds at offset 12 the
return address into the code that made the call.

#idx("dasm370", "finding an instruction")
When there is no listing, for example because the module was built some time
ago, dasm370 disassembles the object module, or a section of the load
module, and marks each instruction with its offset, as
@ug-diag-dasm-dr shows.

#fig(caption: [The instruction at X'BE', found with dasm370])[
  #screen(raw(read("../ex/ug-diag/dasm-dr.txt")))
] <ug-diag-dasm-dr>

The correction is to check #cmd("n") before dividing, as in
@ug-diag-fix. With it, SUMUP run without a parameter writes a message to
#cmd("SYSTERM") and ends with return code 8. Rebuild the library as in
@ug-link-pack and install it again as in @ug-transfer.

#fig(caption: [SUMUP, corrected])[
  #code(read("../ex/ug-diag/sumup.c"), numbers: true)
] <ug-diag-fix>

== Inspecting and Comparing Builds <ug-diag-inspect>

#idx("file370")#idx("idrdump370")#idx("cmplmd370")#idx("dasm370")
Four tools of the toolchain read what the build wrote, without changing it.
They answer questions that come up when a module on MVS does not behave as
the source says it should: is it the module I built, and is it built from
the source I think?

#deflist(width: 1.1in,
  [file370], [identifies any file of the toolchain and summarizes it: an
    object module, an object library, a load module member, an unloaded
    library or a TRANSMIT file. With #cmd("-v") it shows the records, the
    external symbol dictionary and, for a library, the directory with entry
    point, length and attributes of each member.],
  [idrdump370], [shows the identification records of a load module: which
    linkage editor wrote it and when, and whether SPZAP has changed it
    since.],
  [cmplmd370], [compares the control sections of two modules, an object
    module with a load module or two load modules, and says whether their
    program text is identical. It leaves out the address constants, which
    the linkage editor changes.],
  [dasm370], [disassembles a control section into assembler source that
    as370 assembles back into the same bytes.],
)

@ug-diag-inspect-session uses each on SUMUP: file370 summarizes the load
module\; idrdump370 shows that it was written by ld370, version 1.4, on day
278 of 2026, and that SPZAP has not changed it since\; cmplmd370 confirms
that the ADDUP in the load module is the one assembled from
#cmd("addup.asm"), and that the code compiled from #cmd("sumup.c") is
there too\; and dasm370 shows ADDUP as it is in the load module.

#fig(caption: [Inspecting SUMUP])[
  #screen(raw(read("../ex/ug-diag/inspect.txt")))
] <ug-diag-inspect-session>

A disassembly has no names except those of the external symbols, and shows
operands in numeric form: the loop of ADDUP appears as
#cmd("BCT 2,18(0,12)"), and its #cmd("BNP") as #cmd("BNH"), which is the
same instruction. dasm370 can be told more with a hint file\; the _CC/370
Command Reference_, Chapter 7, “The dasm370 Command”, describes it.

The two comparisons that come up most often:

- *Is the module on MVS the one I built?* Copy the library to the
  workstation in a TRANSMIT file, extract the member with
  #cmd("xmit370 extract"), and compare your object modules with it.
  cmplmd370 pairs sections by name. The code of a C source is an unnamed
  section, which it pairs by its first entry point instead and reports
  under that name in parentheses, as #cmd("(@@MAIN)") in
  @ug-diag-inspect-session. To compare one section alone, name it with
  #cmd("--csect"), for example #cmd("cmplmd370 --csect '(@@MAIN)' sumup.o SUMUP").
  An object module compiled with #cmd("-mcsect=")#var("name") is paired in
  the same way with the unnamed section of a module linked without it. For
  the attributes and the
  entry point, which cmplmd370 does not compare, look at the directory with
  #cmd("file370 -v") on the TRANSMIT file.
- *Does a rebuilt object module still match?* After a change to the build,
  compare the new object module with the old load module, as
  @ug-diag-inspect-session does for ADDUP. Only the sections that differ
  need a closer look, with #cmd("cmplmd370 -v") or with dasm370.

Chapters 5, 7, 8 and 9 of the _CC/370 Command Reference_ describe file370,
dasm370, cmplmd370 and idrdump370 in full.
