#import "../bookmaster/bookmaster.typ": *

= Migrating from Other Compilers <ug-migrate>

#idx("migration")
This appendix is for programmers who bring existing C programs to cc370:
from c2asm370 and its C library crent370, the predecessors of cc370 and
libc370, from an earlier release of cc370, and from the other C compilers
for MVS 3.8j. It lists what has to change in the sources and in the build.
The changes of the C library are described in more detail in the _libc370
Programmer's Guide_.

== From c2asm370 and crent370 <ug-migrate-c2asm370>

#idx("c2asm370")#idx("crent370")
cc370 is the successor of c2asm370, and libc370 the successor of crent370,
from which it was developed. c2asm370 was based on GCC 3.2.3\; cc370 is a
fork of GCC 3.4.6, the last GCC that carried the System/370 machine
description. c2asm370 is no longer developed: its last release, 1.x, is
kept unchanged so that existing builds keep working.

=== The Build

#idx("migration", "build")
The largest change is where the work is done. With c2asm370, the compiler
wrote assembler source on the workstation, and the source was uploaded to
MVS, assembled there by the MVS assembler and link-edited by IEWL. With
cc370 all of it happens on the workstation:

#tab(caption: [Where each step runs])[
  #table(columns: (1.1in, 1.4in, 1fr),
    [Step], [c2asm370], [cc370],
    [Compile], [workstation], [workstation: cc370],
    [Assemble], [MVS: IFOX00], [workstation: as370, run by cc370],
    [Link], [MVS: IEWL], [workstation: ld370, run by cc370],
    [Install], [—], [MVS: RECEIVE of the TRANSMIT file],
  )
] <ug-migrate-steps-tab>

So the assembly and link-edit jobs of a c2asm370 build are no longer
needed. In their place comes one transfer and one #cmd("RECEIVE"), as
described in @ug-transfer. What used to be IEWL control statements are ld370
options:

#tab(caption: [IEWL control statements and ld370 options])[
  #table(columns: (1.4in, 1fr),
    [IEWL], [ld370],
    [#cmd("INCLUDE")], [the object module or library on the command line,
      or #cmd("--include") #var("name")],
    [#cmd("ENTRY") #var("name")], [#cmd("--entry") #var("name")],
    [#cmd("ALIAS") #var("name")], [#cmd("--alias") #var("name")],
    [#cmd("NAME") #var("member")], [#cmd("--name") #var("member"), or the
      name of the #cmd("-o") file],
    [#cmd("SETCODE AC(1)")], [#cmd("--ac 1")],
    [#cmd("PARM='RENT'")], [#cmd("--rent --reus")],
    [#cmd("SYSLIB")], [#cmd("-L") and #cmd("-l"), searched by the automatic
      library call],
  )
] <ug-migrate-iewl-tab>

The differences between ld370 and IEWL are listed in the _cc370 Command
Reference_, Chapter 3, “The ld370 Command”.

=== The Compiler

#idx("migration", "compiler")
- The driver is called #cmd("cc370"). Its options are those of GCC 3.4.6\;
  @ug-compile describes the ones that matter on MVS.
- The optimization level that is validated is #cmd("-O1"). #cmd("-Os") is
  experimental, #cmd("-O2") and #cmd("-O3") are not supported. A build that
  used another level should move to #cmd("-O1").
- The default C dialect is #cmd("gnu89"). Give #cmd("-std=gnu99") for C99
  features such as declarations in a #cmd("for") statement.
- Character constants and string literals are translated to EBCDIC code
  page 037, and #cmd("'\\n'") is #cmd("X'15'"), the newline of the C
  library. A program that compares characters with numeric codes instead of
  character constants must be corrected.
- The external name of a C function is made by cutting the name to
  eight characters, in upper case, with #cmd("@") for the underscore.
  #cmd("#pragma map") has no effect (the compiler warns)\; use an #cmd("asm") label
  (@ug-asm-asmfromc).
- The macro #cmd("__CC370__") gives the version of the compiler as a number,
  for example #cmd("10301") for 1.3.1. Use it to keep a source that must
  also compile with another compiler:
  ```
  #ifdef __CC370__
  ...
  #endif
  ```

=== Assembler Sources

#idx("migration", "assembler")
- Assembler source that the old compiler generated, recognizable by
  #cmd("COPY PDPMAIN"), is not kept: regenerate it from the C source with
  cc370. The macros #cmd("PDPMAIN"), #cmd("PDP370"), #cmd("PDP380"),
  #cmd("PDP390") and #cmd("PDPORIG") are no longer installed with the C
  library.
- Hand-written assembler that uses #cmd("PDPPRLG") and #cmd("PDPEPIL")
  assembles unchanged. The macros now come with cc370 and generate the same
  instructions as before, without calling #cmd("SAVE") and #cmd("RETURN").
- as370 accepts the language of the MVS assembler, IFOX00, and writes the
  same object module, so other assembler sources assemble unchanged. The
  macros they use must be found on the workstation (@ug-asm-maclib).

=== The C Library

#idx("migration", "C library")
#idx("libc370", "headers")
libc370 2.0 rearranged the headers of libc370 1.x, such as
#cmd("clibwto.h"), into a tree, and a program that includes the MVS headers of the library has to
change its #cmd("#include") lines. The names of the functions and what they
do are, with few exceptions, unchanged. @ug-migrate-headers-tab lists the
headers most often included.

#tab(caption: [Headers of libc370 1.x and 2.x (selection)])[
  #table(columns: (1.6in, 1fr),
    [1.x], [2.x],
    [#cmd("clibwto.h")], [#cmd("mvs/wto.h")],
    [#cmd("clibary.h")], [#cmd("ext/array.h")],
    [#cmd("clibcrt.h"), #cmd("clibgrt.h"), #cmd("clibppa.h")], [#cmd("mvs/crt.h")],
    [#cmd("clibecb.h")], [#cmd("mvs/ecb.h")],
    [#cmd("clibtry.h"), #cmd("clibstae.h")], [#cmd("mvs/recovery.h")],
    [#cmd("clibthrd.h")], [#cmd("mvs/thread.h")],
    [#cmd("clibenv.h")], [#cmd("mvs/env.h")],
    [#cmd("clibjes2.h")], [#cmd("mvs/jes2.h")],
    [#cmd("svc99.h")], [#cmd("mvs/dynalloc.h")],
    [#cmd("racf.h")], [#cmd("mvs/racf.h")],
    [#cmd("time64.h")], [#cmd("ext/time64.h")],
    [#cmd("clibos.h"), #cmd("clibio.h"), #cmd("clibstr.h"), #cmd("socket.h")],
      [divided among several headers: include the ones that declare the names
      the source uses],
    [#cmd("clibb64.h")], [removed: base64, SHA-256 and Blowfish are in the
      separate library crypto370],
  )
] <ug-migrate-headers-tab>

The libc370 repository holds the complete map of the old headers and names
to the new ones, and the procedure to convert a source file by file.

When you link with ld370 yourself rather than through cc370, name the
compiler's run-time library #cmd("-lcc370rt") before #cmd("-lc"), as in
@ug-link-manual. The routines the compiler calls for 64-bit arithmetic were
moved there from the C library.

== From an Earlier Release of cc370 <ug-migrate-cc370>

#idx("migration", "from earlier cc370")
- *Module attributes.* Up to cc370 1.1, ld370 marked every module reentrant
  and reusable unless told otherwise. Since 1.2 it marks a module with
  neither, as IEWL does. A module that needs the attributes must now ask for
  them with #cmd("--rent") and #cmd("--reus"), and a module that should not
  have had them no longer gets them (@ug-link-attr).
- *Duplicate control sections.* Since 1.2, when two object modules define
  the same control section, ld370 keeps the first and drops the later one,
  as IEWL does. Earlier releases kept the last.
- *Run-time library.* Since 1.1, the routines the compiler calls are in
  #cmd("libcc370rt.a"), which cc370 links by itself. A build that runs ld370
  directly adds #cmd("-lcc370rt") ahead of #cmd("-lc").
- *Matching C library.* cc370 1.1 and later need libc370 2.1 or later, and
  the libc370 headers stop the compile with #cmd("#error") when the compiler
  is older than they require. Update both together.

== Notes for GCCMVS Users <ug-migrate-gccmvs>

#idx("GCCMVS")
cc370 descends from the GCC port for MVS known as GCCMVS, by way of the
i370-gcc line of that compiler. The code it generates is of the same family:

- Every function begins with #cmd("PDPPRLG") and ends with #cmd("PDPEPIL"),
  and every source with #cmd("COPY PDPTOP"). The stack is addressed through
  the next available byte at offset 76 of the save area, and arguments are
  passed by value in a parameter list addressed by R1 (@ug-asm-linkage).

What differs is everything around the compiler:

- The C library is libc370, not the library of GCCMVS. Its start-up,
  #cmd("@@CRT0"), its headers and its MVS functions are its own\; check each
  call against the _libc370 Library Reference_.
- cc370 translates characters to EBCDIC as it writes its output, with
  #cmd("'\\n'") as #cmd("X'15'")\; a numeric escape such as #cmd("\\x25")
  stands for that byte unchanged.
- The assembler source is not meant to be assembled on MVS, though it can be:
  cc370 assembles and links on the workstation, and the toolchain ships the
  macros the generated code needs.

== Notes for JCC Users <ug-migrate-jcc>

#idx("JCC")
JCC is a separate C compiler with its own library, and nothing of either is
shared with cc370. Moving a program means rebuilding it with cc370 against
libc370:

- Replace the build. JCC jobs or scripts that compile and link
  are replaced by cc370 on the workstation and a #cmd("RECEIVE") on MVS
  (@ug-transfer).
- Check every library call that is not standard C against the _libc370
  Library Reference_. The standard C functions behave as the C standard
  describes them\; MVS-specific services have their own names and headers in
  libc370.
- The pragmas of other MVS compilers, #cmd("#pragma map"),
  #cmd("#pragma linkage"), #cmd("#pragma checkout"),
  #cmd("#pragma nomargins") and #cmd("#pragma nosequence"), have no effect\;
  #cmd("#pragma map") and #cmd("#pragma linkage") draw a warning.
  External names come from the C names (@ug-asm-asmfromc) or from
  #cmd("asm") labels.
- Characters are EBCDIC code page 037 and #cmd("'\\n'") is #cmd("X'15'"):
  test a program's character handling, and anything that writes records,
  before you rely on it.
