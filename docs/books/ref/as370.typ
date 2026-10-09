#import "../bookmaster/bookmaster.typ": *

= The as370 Command <asm>

#idx("as370")
The as370 assembler reads System/370 assembler language source on the
workstation and writes an OS/360 object module. It accepts the language of
the OS/VS Assembler XF (IFOX00), which is the assembler of MVS 3.8j, and it
produces the same object module: the external symbol dictionary, the text
and the relocation dictionary are identical, byte for byte, to what IFOX00
writes for the same source.
#idx("IFOX00", "compatibility with")

You do not usually call as370 yourself. The cc370 driver runs it for every C
source it compiles, as described in @cc. You call it directly to
assemble a program written in assembler language, or to obtain a listing.

== What as370 Produces

#idx("object module")
The object module is written as 80-byte card images in EBCDIC: ESD, TXT, RLD
and END records, in the format that the MVS linkage editor reads. It can be
link-edited on the workstation with ld370 (see Chapter 3) or uploaded and
link-edited on MVS with IEWL; both accept it. Appendix A describes the
format.

#idx("COM")#idx("DXD")#idx("CXD")#idx("Q-type address constant")
Besides control sections, entry points and external references, the object
module can describe common sections (#cmd("COM")), external dummy sections
(#cmd("DXD"), and a #cmd("DSECT") named in a #cmd("Q")-type constant), and
the constants that refer to them: #cmd("DC Q(")#var("name")#cmd(")") and
#cmd("CXD"). as370 assembles all of these, except a
#cmd("COM") statement without a name, which it reports as not implemented.
ld370 allocates common sections, but does not yet resolve external dummy
sections (see @ld370-layout)\; a module that uses them is link-edited with
IEWL on MVS.

The one difference from IFOX00 is the translator identification on the END
record, which reads #cmd("ASM370") where IFOX00 writes its own program number. It does not affect the
linkage editor.

On request, as370 also writes an assembler listing (see @as370-listing) and three
tab-separated data files that describe the assembly for other programs (see
@as370-datafiles).

== Invoking as370 <as370-invoke>

#idx("as370", "syntax")
#syntax(read("../syntax/as370-main.txt"))

#syntax(title: "Option:", read("../syntax/as370-option.txt"))

=== Operands

#deflist(
  [#var("source-file")], [is the assembler source to read. It is a host
    file; see @as370-encoding for the character sets as370 accepts.],
  [#cmd("-a")], [writes an assembler listing. The listing always contains
    the source statements. Without #var("sub-options") it also contains the
    external symbol dictionary, the relocation dictionary when the module has
    one, and the cross-reference. Each sub-option is one letter and asks for
    one section:
    #v(0.3em)
    #deflist(width: 0.3in,
      [#cmd("e")], [the external symbol dictionary],
      [#cmd("r")], [the relocation dictionary],
      [#cmd("s")], [the ordinary symbol and literal cross-reference],
    )
    #v(0.3em)
    The sub-options #cmd("g"), #cmd("i"), #cmd("m") and #cmd("x") are
    accepted and have no effect yet. The listing goes to standard output
    unless #cmd("=")#var("file") follows the sub-options; it must be the last
    of them. A #var("file") that cannot be written is a command-line error
    (return code 16, no object module).#idx("listing", "requesting")],
  [#cmd("-I") #var("directory")], [adds #var("directory") to the macro and
    COPY library search. Repeat the option to add several directories; they
    are searched in the order given. See @as370-maclib.],
  [#cmd("-o") #var("object-file")], [names the object module to write. *No
    object module is written when #cmd("-o") is omitted*, which is what you
    want when you need only a listing.],
  [#cmd("--xref=")#var("form")], [selects the form of the cross-reference:
    #cmd("full"), the default, lists every symbol, as IFOX00 does for
    #cmd("XREF(FULL)")\; #cmd("short") leaves out the symbols that nothing
    references, as #cmd("XREF(SHORT)") does.],
  [#cmd("--sym="), #cmd("--stmts="), #cmd("--usings=")], [write the symbol
    table, the generated statements, or the #cmd("USING") and #cmd("DROP")
    events to #var("file"). See @as370-datafiles.],
  [#cmd("--sysparm=")#var("string")], [sets the value of the system
    variable symbol #cmd("&SYSPARM"), as the #cmd("SYSPARM") option of
    IFOX00 does. Without it, #cmd("&SYSPARM") is the null string.#idx("&SYSPARM")],
  [#cmd("--strict-cont")], [raises a statement that was lost because the
    card above it continued into it (column 72) to severity 8, so that the
    return code shows it. See @apx-messages-as370-cont.],
  [#cmd("-m") #var("option"), #cmd("-d") #var("argument")], [are accepted
    with their argument and have no effect.],
  [#cmd("-v")], [reports on standard error what as370 does: the source it
    assembles, each directory of the macro search path (marked
    #cmd("(absent)") when it does not exist), each macro and the file it
    came from, and the closing #cmd("Assembler Done") line, also after a
    clean assembly.#idx("as370", "-v option")],
  [#cmd("-h"), #cmd("--help")], [displays a summary of the options and
    ends.],
  [#cmd("-V"), #cmd("--version")], [displays the toolchain version and the
    commit from which as370 was built, for example
    #cmd("as370 1.4.0 (2821ebb)"), and ends.],
)

== Macro and COPY Libraries <as370-maclib>

#idx("macro library", "search order")
#idx("COPY")
A macro instruction that is not defined in the source, and every #cmd("COPY")
statement, is resolved from a library. On the workstation a library is a
directory, and each of its members is a file. as370 searches these
directories, highest priority first:

+ the directories named by #cmd("-I"), in the order given;
+ the directories named by the environment variable #cmd("AS370_MACLIB"),
  separated by colons;#idx("AS370_MACLIB")
+ #cmd("../macros") relative to the directory that holds the as370 program;
+ #cmd("../libc370/macros") relative to the same directory.

The last two are the macro libraries of the installed toolchain, so an
installed as370 assembles a program that uses the LIBC/370 and system macros
with no #cmd("-I") and no environment variable.

Within a directory, as370 looks for the member name as written and then, if
it contains capitals, in lowercase. For each spelling it tries the
extensions #cmd(".macro"), #cmd(".copy"), #cmd(".mac") and #cmd(".asm"), and
finally the name with no extension. The macro #cmd("SAVE") is therefore found
as #cmd("SAVE.macro"), #cmd("save.mac") or simply #cmd("SAVE").

#note[A directory that does not exist is not an error. It is skipped, so a
misspelled #cmd("-I") shows itself as an undefined operation code\; #cmd("-v")
lists the search path and marks a missing directory #cmd("(absent)").]

== Source Encoding <as370-encoding>

#idx("character set", "of the source")
IFOX00 reads EBCDIC, one byte to a character, and column 72 marks a
continuation. as370 reads a host file and keeps that rule by deciding the
encoding of each file, source or library member, by itself:

- A file that is valid UTF-8 and contains a character above #cmd("X'7F'") is
  read as UTF-8, one character to a column. A leading byte order mark is
  ignored.
- Any other file is read one byte to a character, as Latin-1. Many existing
  macros are Latin-1: their #cmd("¬") is the byte #cmd("X'AC'").

Every character is then translated from Latin-1 to EBCDIC code page 037. A
character above U+00FF has no image in code page 037: as370 reads it as
#cmd("X'3F'"), flags its statement with severity 4, and with severity 8 if
the character reaches the object module.

== The Assembler Listing <as370-listing>

#idx("listing", "format")
The listing follows the IFOX00 listing column for column, so that a listing
from as370 can be compared with one printed on MVS. @as370-hello-lst shows the
listing of a six-statement program, produced by the following command:

```
as370 -a=hello.lst -o hello.o hello.asm
```

#fig(caption: [Assembler listing of HELLO])[
  #set par(justify: false, leading: 0.32em)
  #text(font: mono-font, size: 6.1pt,
    read("../ex/as370/hello.lst").replace("\f", "").split("\n").map(l => l.trim(at: end)).join("\n"))
] <as370-hello-lst>


The listing has one page for each section. The headings are those of
IFOX00; #cmd("ASM370 0100") in the top right-hand corner takes the place of
the IFOX00 release level, followed by the time and date of the assembly.
The diagnostics and statistics pages of IFOX00 are not produced; messages
are written to standard error instead.

== Data Files for Other Programs <as370-datafiles>

#idx("data files")
Three options write a description of the assembly as tab-separated text, one
record to a line, for programs that compare or analyse object modules. A
file name of #cmd("-") writes to standard output.

#deflist(width: 1.1in,
  [#cmd("--sym=")], [The symbol table.],
  [#cmd("--stmts=")], [One record for each generated statement: where it
    is placed, how many bytes it produces, whether it reserves storage or
    only aligns, and which macro call generated it. An object module cannot
    show the difference between #cmd("DS 0F") and #cmd("DS CL1")\; this file
    can.],
  [#cmd("--usings=")], [One record for each #cmd("USING"), #cmd("DROP"),
    #cmd("PUSH") and #cmd("POP") event and base register, each with its
    section and location counter.],
)

== Return Codes <as370-rc>

#idx("as370", "return codes")#idx("return codes")
as370 ends with the highest severity of the messages it issued, using the
convention of IFOX00. @as370-rc-tab lists the values.

#tab(caption: [as370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The assembly completed without messages.],
    [2], [The assembly was abandoned because a limit of as370 was reached:
      one of its tables (symbols, literals, relocations) is full, a section
      would extend beyond 16 MB, or storage ran out. A message beginning
      #cmd("as370:") names the limit. No object module is written.],
    [4], [Warnings only. The object module is complete.],
    [8], [Errors. At least one statement could not be assembled as
      written, for example an undefined operation code. The object module is
      written, but it is not expected to run.],
    [12], [Severe errors.],
    [16], [Terminal error: the source or the object module could not be
      opened or written, or the command line is wrong -- an unknown option
      (#cmd("IFO258")), a second source file, or a listing file named by
      #cmd("-a=")#var("file") that cannot be written. On a wrong command line
      the assembly still runs and reports its messages, but no object
      module is written.],
  )
] <as370-rc-tab>

A statement in error is shown on standard error with its line number, as in
@as370-session.

== Example

@as370-session shows a session that assembles the program of @as370-hello-lst, examines
the object module with file370, and then assembles a source with an
undefined operation code.

#fig(caption: [Assembling and inspecting a program])[
  #screen(```
$ as370 -o hello.o hello.asm
$ echo $?
0
$ file370 -v hello.o
hello.o: OS/360 object deck -- 1 section(s) (first HELLO), 14B text
    3 card(s) of 80 bytes; 0 LD entr(y/ies)
    ESD    1  HELLO     SD  addr=000000  len=00000E
    END  entry at offset 000000
$ as370 -o bad.o bad.asm
   FOO 1,2
 ERROR: Undefined operation code in line 2 - FOO
 Assembler Done   1 Statement Flagged /   8 was Highest Severity
$ echo $?
8
```)
] <as370-session>

