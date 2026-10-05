#import "bookmaster/bookmaster.typ": *

#show: book.with(
  title: "cc370 Cross-Toolchain for MVS 3.8j",
  subtitle: "Command Reference",
  short-title: "cc370 Command Reference",
  number: "ML01-0002-0",
  date: "October 2026",
  authors: ("Mike Großmann",),
  edition: [
    #text(font: head-font, weight: "bold", size: 11pt)[First Edition (October 2026)]

    This edition applies to Version 1 Release 3 Modification 1 of the cc370
    cross-toolchain (cc370 1.3.1) and to all subsequent releases and
    modifications until otherwise indicated in new editions.

    Comments on this book may be addressed to the issue tracker of
    the mvslovers/cc370 repository on GitHub.

    © Copyright Mike Großmann 2026. All rights reserved.
  ],
)

#contents()
#figures()

#heading(numbering: none)[About This Book] <about>

This book describes the commands of the cc370 cross-toolchain: the C
compiler, the assembler, the linkage editor, the archiver and two utilities,
all of which run on a workstation and produce programs for MVS 3.8j. For
each command it gives the syntax, every option, the files it reads and
writes, and its return codes.

How the tools are used together, from the first program to its deployment on
MVS, is the subject of the companion volume, the _cc370 User's Guide_.

== Who Should Use This Book

This book is for programmers who write C or assembler programs for MVS 3.8j
on a macOS or Linux workstation. It assumes that you know the C language,
System/370 assembler language and the basic concepts of MVS: data sets,
partitioned data sets, load modules and job control language.

== How This Book Is Organized

#deflist(width: 1.35in,
  [Chapter 1], [“The cc370 Command” describes the compiler driver.],
  [Chapter 2], [“The as370 Command” describes the assembler.],
  [Chapter 3], [“The ld370 Command” describes the linkage editor and the
    transport formats it writes.],
  [Chapter 4], [“The ar370 Command” describes object libraries.],
  [Chapter 5], [“The file370 Command” describes the inspector for every
    format the toolchain writes.],
  [Chapter 6], [“The xmit370 Command” describes the transmission of source
    libraries.],
  [Chapter 7], [“The dasm370 Command” describes the disassembler.],
  [Chapter 8], [“The cmplmd370 Command” describes the comparison of object
    modules and load modules.],
  [Chapter 9], [“The idrdump370 Command” describes the display of
    identification records.],
  [Appendix A], [“Object Module Format”.],
  [Appendix B], [“Load Module and Transport Formats”.],
  [Appendix C], [“Messages and Return Codes”.],
)

== Related Publications

#deflist(width: 1.35in,
  [ML01-0001], [_cc370 User's Guide_],
  [ML01-0003], [_libc370 Programmer's Guide_],
  [ML01-0004], [_libc370 Library Reference_],
)

== How to Read the Syntax Diagrams

Read the syntax diagrams from left to right, from top to bottom, following
the path of the line.

#deflist(width: 1.35in,
  [#syntax(framed: false, "►►──")], [begins a statement.],
  [#syntax(framed: false, "──►")], [shows that the statement continues on the next line.],
  [#syntax(framed: false, "──►◄")], [ends the statement.],
  [#syntax(framed: false, "├──") #syntax(framed: false, "──┤")], [begin and end a fragment, which is described
    in a diagram of its own.],
)

Items on the main path are required. Items below the main path are
optional. When you can choose from two or more items, they are stacked
vertically. An arrow returning to the left above the main line shows an item
that can be repeated. Keywords and options appear as they are typed; a
variable, for which you supply a value, appears in _italics_.

#mainmatter()
#set page(numbering: "1")

#include "ref/cc370.typ"
#include "ref/as370.typ"
#include "ref/ld370.typ"
#include "ref/ar370.typ"
#include "ref/file370.typ"
#include "ref/xmit370.typ"
#include "ref/dasm370.typ"
#include "ref/cmplmd370.typ"
#include "ref/idrdump370.typ"

#show: appendices
#include "ref/apx-objfmt.typ"
#include "ref/apx-lmodfmt.typ"
#include "ref/apx-messages.typ"

#heading(numbering: none)[Index]
#make-index()
