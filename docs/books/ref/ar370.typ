#import "../bookmaster/bookmaster.typ": *

= The ar370 Command <ar370>

#idx("ar370")
#idx("object library")
The ar370 command collects object modules into an object library: a single
file, by convention with the extension #cmd(".a"), that holds the object
modules together with an index of the external symbols they define. It is
the workstation counterpart of an automatic call library on MVS, the
partitioned data set that the linkage editor searches through its
#cmd("SYSLIB") DD statement.

An object library is used by ld370. When a program refers to a symbol that
none of its own object modules defines, ld370 looks the symbol up in the
index of each library it was given and includes the object module that
defines it. This is the automatic library call\; @ar370-autocall summarizes
it, and @ld370 describes it in full. The C library of the toolchain,
#cmd("libc.a"), is an ar370 library.

The object modules that go into a library are those written by as370 (see
@asm) or by cc370 with #cmd("-c") (see @cc). ar370 does not translate or
change them; it stores each one byte for byte.

== Invoking ar370 <ar370-invoke>

#idx("ar370", "syntax")
#syntax(read("../syntax/ar370-main.txt"))

#syntax(read("../syntax/ar370-info.txt"))

=== Operands

#deflist(width: 1.6in,
  [#cmd("rc") #var("archive") #var("object")...], [creates the library
    #var("archive") from the object modules named, in the order given, and
    builds its symbol index. *A library that already exists is replaced, not
    updated*: #cmd("ar370 r lib.a new.o") leaves #cmd("lib.a") holding
    #cmd("new.o") alone. With no #var("object"), ar370 writes an empty
    library. With a trailing #cmd("v"), as in #cmd("rcv"), ar370 also writes
    one line #cmd("a - ")#var("member") to standard output for each member it
    stores, as GNU #cmd("ar") does.
    #v(0.3em)
    Each member is named after the base name of its file\; the directory
    part is dropped. Every #var("object") must be an object module: a whole
    number of 80-byte card images, each of which begins with
    #cmd("X'02'"), among them an END record. A source file or an archive
    is refused with a message and return code 1. ar370 reads and checks every
    #var("object") before it opens #var("archive"), so when one of them is
    refused or cannot be read, the library is neither written nor changed.],
  [#cmd("t") #var("archive")], [lists the library: under #cmd("members:")
    each member with its length in bytes, then under #cmd("symbol table:")
    each symbol of the index with the member that defines it, in index
    order (see @ar370-session).],
  [#cmd("--help"), #cmd("-h")], [writes the usage summary to standard output
    and ends with return code 0.],
  [#cmd("--version"), #cmd("-V")], [displays the toolchain version and the
    commit from which ar370 was built, for example
    #cmd("ar370 1.4.0 (2821ebb)"), and ends.],
)

#idx("ar370", "operations")
The operation is one of #cmd("r"), #cmd("c"), #cmd("rc") or #cmd("cr"), all
of which create the library, or #cmd("t"), which lists it\; it may be
written with a leading #cmd("-"), as in #cmd("-rc"). A create operation
may end in #cmd("v") (#cmd("rv"), #cmd("cv"), #cmd("rcv"), #cmd("crv")) to
name each member as it is written\; #cmd("t") takes no #cmd("v"). Any other
operation, such as #cmd("crs"), #cmd("tv"), #cmd("vrc") or #cmd("x"), is
rejected with the message
#cmd("ar370: unknown operation '")#var("op")#cmd("' (r, c, rc, cr or t)")
and return code 2. #cmd("--help"), #cmd("-h"), #cmd("--version") and
#cmd("-V") are recognized as the first operand whatever follows them\; as in
every tool of the toolchain, #cmd("-v") never means the version, and
#cmd("ar370 -v") alone is too few operands. Called with no operands, or with
too few, ar370 writes its usage summary to standard error and ends with
return code 2.

== The Symbol Index <ar370-index>

#idx("symbol index")
#idx("external symbol dictionary", "in an object library")
For each object module it stores, ar370 reads the external symbol dictionary
(the ESD records) and enters into the index every symbol that the module
defines:

- the name of each control section (SD) and common section (CM)\;
- the name of each entry point (LD), such as a name declared by
  #cmd("ENTRY") in assembler language.

External references (ER) and weak external references (WX) are not entered,
nor is unnamed private code (PC), since it has no name, nor are external
dummy sections (XD). The names are
translated from EBCDIC and the trailing blanks removed. They appear in the
index in member order, and within a member in ESD order.

A symbol defined by more than one member is entered once for each member
that defines it. The index of a library built from two copies of the same
object module therefore lists each of its symbols twice. Which of several
definitions ld370 then uses is described in @ld370.

== How ld370 Uses a Library <ar370-autocall>

#idx("automatic library call")
#idx("ld370", "object libraries")
ld370 is given a library in one of two ways: as an operand whose name ends
in #cmd(".a"), or by #cmd("-l")#var("name"), which ld370 resolves to the
file #cmd("lib")#var("name")#cmd(".a") in the directories named by
#cmd("-L") and then in the current directory. The command

```
ld370 -o main.lm main.o -L . -l demo
```

links #cmd("main.o") and resolves its external references from
#cmd("./libdemo.a").

After it has read the object modules named on the command, ld370 looks up
each unresolved external reference in the indexes of the libraries and
includes the member that defines it. A member brought in this way can refer
to further symbols, so the search is repeated until no reference is left
that a library can resolve. Three consequences follow:

- ld370 searches the index only. A symbol that a member defines but the
  index does not list, for instance because the library was built with an
  archiver other than ar370, is not found.
- A member is always included whole. If a program refers to #cmd("ADD1"),
  and #cmd("ADD1") and #cmd("ADD2") are defined by the same member, the
  module receives both, as @ar370-session shows.
- A weak external reference (#cmd("WXTRN")) does not cause a member to be
  included. It is resolved only when the member that defines the symbol is
  included for some other reason.

== Library Format <ar370-format>

#idx("object library", "format")
#idx("ar archive")
An ar370 library is an archive in the common Unix #cmd("ar") format, so the
#cmd("ar") command of the workstation can list its members. It begins with
the seven characters #cmd("!<arch>") followed by a newline, and each member follows
as a 60-byte header and the member's bytes, padded to an even length.

The first member is the symbol index. Its name is #cmd("/"), and its
contents have the layout used by GNU #cmd("ar"): a four-byte count of
symbols, then for each symbol the four-byte offset of the header of the
member that defines it, and then the symbol names, each ended by a zero
byte. All numbers are big-endian. The object modules follow in the order
they were named. A name of up to 15 characters is stored in the member's own
header, followed by #cmd("/"), as GNU #cmd("ar") writes short names. A longer
name is stored, as GNU #cmd("ar") does, in a second special member named
#cmd("//") that follows the index, and the member's header holds
#cmd("/")#var("n"), the offset of the name in it. The #cmd("ranlib") command of the
workstation cannot build this index, because it does not understand OS/360
object modules.

The date, owner and group fields of every header are zero and the mode is
#cmd("100644"), so the same object modules named in the same order always
produce an identical library.

== Limits <ar370-limits>

#idx("ar370", "limits")
@ar370-limits-tab lists the limits of ar370.

#tab(caption: [ar370 limits])[
  #table(columns: (1.6in, 1fr),
    [Limit], [Behavior when exceeded],
    [63 characters in a member name], [ar370 ends with the message
      #var("file")#cmd(": member name longer than 63 characters") and return
      code 1, and writes no library. A longer name could not be given to
      #cmd("ld370 --include").],
    [9,999,999,999 bytes in one member], [The size field of a header has ten
      digits. ar370 ends with the message #cmd("ar370: member is") #var("n")
      #cmd("bytes; an ar header's size field holds 10 digits and cannot express it") and return code 1.],
  )
] <ar370-limits-tab>

There is no limit on the number of object modules in a library or of
symbols in its index.

== Return Codes <ar370-rc>

#idx("ar370", "return codes")
#tab(caption: [ar370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The library was written, or listed.],
    [1], [A file could not be read or written: an #var("object"), or the
      #var("archive") to be listed, does not exist\; an #var("object") is not
      an object module or is itself an archive\; a member name is longer
      than 63 characters\; the file to be listed is not an archive
      (#cmd("ar370: ")#var("file")#cmd(": not an archive"))\; or the library
      cannot be created. A message naming the file is written to standard
      error.],
    [2], [The command was not understood: too few operands, or an unknown
      operation.],
  )
] <ar370-rc-tab>

== Example <ar370-example>

The object module in @ar370-add1 defines the control section #cmd("ADD1")
and, with #cmd("ENTRY"), the entry point #cmd("ADD2"). A second module,
#cmd("sub1.asm"), defines the control section #cmd("SUB1"), and the program
#cmd("main.asm") calls #cmd("ADD1") through #cmd("=V(ADD1)").

#fig(caption: [ADD1, a module with two entry points])[
  #code(read("../ex/ar370/add1.asm"), numbers: true)
] <ar370-add1>

@ar370-session assembles the two modules, builds the library
#cmd("libdemo.a") from them and lists it, then links #cmd("main.o") against
the library. The map that #cmd("--map -") writes to standard output shows
that ld370 took #cmd("ADD1") from the member #cmd("add1.o"), marked
#cmd("autocall"), and that #cmd("ADD2") came with it. Nothing refers to
#cmd("SUB1"), and it is not included.

#fig(caption: [Building and using an object library])[
  #screen(raw(read("../ex/ar370/ar-session.txt")))
] <ar370-session>
