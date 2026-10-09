#import "../bookmaster/bookmaster.typ": *

= Introducing the Toolchain <ug-intro>

#idx("cc370 toolchain")
The CC/370 toolchain builds programs for MVS 3.8j on a workstation running
macOS or Linux. It compiles C, assembles System/370 assembler language,
link-edits the result into an MVS load module and packs the load module into
a file that MVS can receive. All of this happens on the workstation: the
compiler, the assembler and the linkage editor are programs of the
workstation, not of MVS, and none of them needs a connection to the
mainframe.

This chapter introduces the tools, follows a program from its source to the
point where it runs on MVS, and says which of those steps take place on MVS
and which do not.

== The Tools <ug-intro-tools>

#idx("cc370 toolchain", "commands")
The toolchain consists of nine commands. Three of them form the chain that
turns a source into a load module, and the cc370 driver runs them for you\;
the others are utilities that you call yourself. @ug-intro-tools-tab lists
them, with the chapter of the _CC/370 Command Reference_ that describes each.

#tab(caption: [The commands of the toolchain])[
  #table(columns: (0.95in, 1fr, 0.75in),
    [Command], [Purpose], [Reference],
    [#cmd("cc370")], [The C compiler driver. It compiles C source to
      assembler language and runs as370 and ld370 on the result.],
      [Chapter 1],
    [#cmd("as370")], [The assembler. It accepts the language of the MVS 3.8j
      assembler, Assembler XF (IFOX00), and writes the same object modules.],
      [Chapter 2],
    [#cmd("ld370")], [The linkage editor. It takes the place of the MVS
      linkage editor (IEWL), writes the load module and packs it for
      transport to MVS.], [Chapter 3],
    [#cmd("ar370")], [The archiver. It collects object modules into an object
      library, which ld370 searches for the modules a program needs.],
      [Chapter 4],
    [#cmd("file370")], [Identifies and displays every kind of file the
      toolchain writes.], [Chapter 5],
    [#cmd("xmit370")], [Packs a directory of text files into a TSO TRANSMIT
      file holding a source library, such as a library of JCL or macros, and
      lists and unpacks such files.], [Chapter 6],
    [#cmd("dasm370")], [Disassembles a control section of an object module
      or load module into assembler language.], [Chapter 7],
    [#cmd("cmplmd370")], [Compares the program text of two modules.],
      [Chapter 8],
    [#cmd("idrdump370")], [Displays the identification records of a load
      module.], [Chapter 9],
  )
] <ug-intro-tools-tab>

#idx("libc370")#idx("libcc370rt")#idx("sysroot")
Two libraries complete the toolchain. *LIBC/370* (libc370) is the C library: the
standard C functions, the start-up code that runs before #cmd("main"), and
functions for the services of MVS. It is a project of its own, with its own
releases, and is installed into the toolchain's directory tree, the
_sysroot_, where the compiler finds its headers and the linkage editor its
library without being told. *libcc370rt* comes with CC/370 itself: it holds
the routines the compiler calls for operations that have no System/370
instruction, such as the division of 64-bit integers. @ug-install describes
how both are installed\; the _LIBC/370 Programmer's Guide_ describes the C
library.

== From Source to Running Program <ug-intro-path>

#idx("cc370", "phases")
A C program passes through five forms on the workstation and three on MVS.
@ug-intro-path-fig shows them, with the program that makes each one from
the one before.

#fig(caption: [From a C source to a program running on MVS])[
  #set text(size: 8.5pt)
  #let item(t, d) = rect(width: 100%, inset: 5pt, stroke: 0.5pt)[
    #text(font: mono-font, weight: "bold")[#t] \ #d]
  #let step(t) = align(center)[#text(size: 8pt)[↓ #t]]
  #grid(columns: (1fr, 0.35in, 1fr), row-gutter: 3pt,
    align(center)[*Workstation*], [], align(center)[*MVS*],
    item("hello.c", [C source]), [], [],
    step[cc1, the compiler proper], [], [],
    item("hello.s", [assembler source]), [], [],
    step[as370], [], [],
    item("hello.o", [object module]), [], [],
    step[ld370, with the C library], [], [],
    item("hello", [load module member]), [], [],
    step[ld370], [], [],
    item("hello.xmit", [TSO TRANSMIT file]),
      align(horizon + center)[#text(size: 7pt)[upload] \ →],
      item("USER1.HELLO.XMIT", [sequential data set, FB 80]),
    [], [], step[RECEIVE],
    [], [], item("USER1.HELLO.LOAD(HELLO)", [load library member]),
    [], [], step[EXEC PGM=HELLO],
    [], [], item("SYSPRINT", [the output of the program]),
  )
] <ug-intro-path-fig>

+ *The C source* is an ordinary text file on the workstation, in UTF-8 or
  Latin-1.
+ *The assembler source* is written by cc1, the compiler proper, which the
  driver runs first. Its character constants and strings are already
  translated to EBCDIC, and each function begins with the macro
  #cmd("PDPPRLG") and ends with #cmd("PDPEPIL").
+ *The object module* is written by as370: 80-byte card images with the
  external symbol dictionary, the text and the relocation dictionary, as
  IFOX00 writes them on MVS.
+ *The load module member* is written by ld370. ld370 takes from the C
  library the members the program needs, the start-up code among them, resolves the
  references between them and writes the records of one member of a load
  library, in the form that program fetch reads.
+ *The TRANSMIT file* is written by ld370 too, on request. A load library is
  a partitioned data set with undefined-length records and cannot be copied
  to MVS as a plain file. The TRANSMIT file holds the library in 80-byte
  records, which can be.

One cc370 command performs all of this:

```
cc370 -O1 -o hello -flinker-output=xmit hello.c
```

The assembler source and the object module are temporary files, which the
driver deletes. @ug-first takes the same program through the steps one at a
time, so that you can see each file.

#idx("RECEIVE")
On MVS, the TRANSMIT file is uploaded in binary into a sequential data set
with fixed 80-byte records, and the TSO #cmd("RECEIVE") command turns it
back into a load library. From there the program runs like any other: a job
step names it on #cmd("EXEC PGM="), with the library in its #cmd("STEPLIB").

== What Touches MVS <ug-intro-mvs>

#idx("MVS", "work done on")
On MVS you do three things, and only these:

- *Upload* the TRANSMIT file, by FTP, through the mvsMF REST API or with a
  3270 file transfer. @ug-transfer compares the ways.
- *Receive* it into a load library, with one #cmd("RECEIVE") command, at a
  terminal or in a batch job.
- *Run* the program.

No assembler step runs IFOX00, no link step runs IEWL, and no IEBCOPY step
builds the library: their work has been done on the workstation, and the
result arrives complete. A build therefore needs no MVS system at all. MVS
is needed to install and to test the program, and for nothing else.

#idx("mbt")
For a project of more than a few sources, the MBT build tool drives the
toolchain from a description of the project, and its #cmd("make deploy")
performs the upload and the #cmd("RECEIVE") in one command. This book uses
the tools directly, so that you can see what each step does\; MBT is
described in its own documentation.

== Supported Systems <ug-intro-systems>

#idx("supported systems")#idx("MVS 3.8j")
*The target* is MVS 3.8j running on the Hercules emulator. The programs the
toolchain writes use the System/370 instruction set and 24-bit addresses,
and run on any MVS 3.8j system. The distributions in common use are:

#deflist(width: 1.1in,
  [TK4-], [the Turnkey 4- system,],
  [TK5], [its successor, the Turnkey 5 system, and],
  [MVS/CE], [the MVS 3.8j Community Edition.],
)

They differ in what they install besides MVS itself: the TSO commands, the
job and output classes, and the volumes on which new data sets may be
placed. Where a step in this book depends on such a difference, the step
says so.

#idx("RECEIVE", "NJE38")#idx("RECV370")
To install a TRANSMIT file, the system needs either the TSO #cmd("RECEIVE")
command, which the NJE38 package provides, or the RECV370 batch program.
@ug-transfer describes both.

#idx("supported systems", "workstation")
*The workstation* is a macOS or Linux system with an Intel (x86-64) or ARM
(arm64) processor. Prebuilt toolchains are published for macOS 11 and later
on ARM, macOS 10.15 and later on Intel, and Linux on both processors. On
Windows, use the Linux toolchain under the Windows Subsystem for Linux
(WSL 2). The toolchain can also be built from source on any of these
systems, as @ug-install describes.
