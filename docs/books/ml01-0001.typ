#import "bookmaster/bookmaster.typ": *

#show: book.with(
  title: "cc370 Cross-Toolchain for MVS 3.8j",
  subtitle: "User's Guide",
  short-title: "cc370 User's Guide",
  number: "ML01-0001-0",
  date: "October 2026",
  authors: ("Mike Großmann",),
  edition: [
    #text(font: head-font, weight: "bold", size: 11pt)[First Edition (October 2026)]

    This edition applies to Version 1 Release 3 Modification 1 of the cc370
    cross-toolchain (cc370 1.3.1) and to all subsequent releases and
    modifications until otherwise indicated in new editions.

    *Draft.* The output of the examples that run on MVS has still to be
    captured; those figures are marked as such.

    Comments on this book may be addressed to the issue tracker of
    the mvslovers/cc370 repository on GitHub.

    © Copyright Mike Großmann 2026. All rights reserved.
  ],
)

#contents()
#figures()

#heading(numbering: none)[About This Book] <about>

This book shows how to write, build and run programs for MVS 3.8j with the
cc370 cross-toolchain: how to install it, how a C or assembler source
becomes a load module on the workstation, how the load module reaches MVS,
and how to run it and find out what went wrong.

Every command and option is described in full in the companion volume, the
_cc370 Command Reference_\; this book uses only what a task needs and points
there for the rest.

== Who Should Use This Book

This book is for programmers who want to build programs for MVS 3.8j on a
macOS or Linux workstation. It assumes that you know the C language and,
for the chapters on assembler, System/370 assembler language, and that you
can submit a job and read its output on MVS.

== How This Book Is Organized

#deflist(width: 1.35in,
  [Chapter 1], [“Introducing the Toolchain”: the tools and the path from a
    source to a running program.],
  [Chapter 2], [“Installing the Toolchain”.],
  [Chapter 3], [“Your First Program”: from #cmd("hello.c") to the output in
    SYSPRINT.],
  [Chapter 4], [“Compiling C Programs”.],
  [Chapter 5], [“Writing Assembler Code”, alone and together with C.],
  [Chapter 6], [“Linking and Libraries”.],
  [Chapter 7], [“Getting Programs onto MVS”: transfer and RECEIVE.],
  [Chapter 8], [“Running Programs on MVS”.],
  [Chapter 9], [“Diagnosing Problems”.],
  [Appendix A], [“Migrating from Other Compilers”.],
  [Appendix B], [“Glossary”.],
)

== Related Publications

#deflist(width: 1.35in,
  [ML01-0002], [_cc370 Command Reference_],
  [ML01-0003], [_libc370 Programmer's Guide_],
  [ML01-0004], [_libc370 Library Reference_],
)

#mainmatter()
#set page(numbering: "1")

#include "guide/ug-intro.typ"
#include "guide/ug-install.typ"
#include "guide/ug-first.typ"
#include "guide/ug-compile.typ"
#include "guide/ug-asm.typ"
#include "guide/ug-link.typ"
#include "guide/ug-transfer.typ"
#include "guide/ug-run.typ"
#include "guide/ug-diag.typ"

#show: appendices
#include "guide/ug-migrate.typ"
#include "guide/ug-glossary.typ"

#heading(numbering: none)[Index]
#make-index()
