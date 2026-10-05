#import "../bookmaster/bookmaster.typ": *

= Compiling C Programs <ug-compile>

#idx("compiling")
cc370 is a C compiler of the GNU family, and compiles C as GCC 3.4.6 does.
What is particular to it follows from the system it compiles for: the
program runs in EBCDIC, its external names have eight characters, and it is
link-edited into an MVS load module. This chapter shows how to compile a C
program and what to keep in mind while writing one. The options are
described in full in the _cc370 Command Reference_, Chapter 1, “The cc370
Command”.

== Compiling and Linking <ug-compile-basic>

#idx("cc370", "recommended options")
The command that builds a program from one source is the one you met in
@ug-first:

```
cc370 -std=gnu99 -Wall -O1 -o prog -flinker-output=xmit prog.c
```

#deflist(width: 1.55in,
  [#cmd("-std=gnu99")], [compiles C99 with the GNU extensions\; see
    @ug-compile-dialect.],
  [#cmd("-Wall")], [reports the common mistakes\; see @ug-compile-warn.],
  [#cmd("-O1")], [optimizes at the level that the toolchain is validated
    at\; see @ug-compile-opt.],
  [#cmd("-o prog")], [names the output. The member name of the load
    module, #cmd("PROG"), is made from this name: everything from the
    first period on is removed, the rest is put in upper case and cut to
    eight characters. Give a name that is a valid member name.],
  [#cmd("-flinker-output=xmit")], [writes the TRANSMIT file
    #cmd("prog.xmit") beside the load module.],
)

#idx("separate compilation")
A program of several sources is compiled one source at a time with
#cmd("-c"), which stops after the object module, and linked in a last
command that names the object modules:

```
cc370 -std=gnu99 -Wall -O1 -c main.c
cc370 -std=gnu99 -Wall -O1 -c report.c
cc370 -o prog -flinker-output=xmit main.o report.o
```

Only the sources that changed need to be compiled again. @ug-link describes
programs of several modules and object libraries.

== Choosing the Language Dialect <ug-compile-dialect>

#idx("C dialect")#idx("-std")
Without #cmd("-std"), cc370 compiles C89 with the GNU extensions
(#cmd("gnu89")), the default of GCC 3.4.6. Features of C99 that GNU C89
lacks are then errors, as @ug-compile-dialect-fig shows for a declaration in
a #cmd("for") statement. The projects of the mvslovers ecosystem are written
in C99 and compiled with #cmd("-std=gnu99"), and so are the examples of this
book.

#fig(caption: [A C99 program compiled as GNU C89 and as GNU C99])[
  #grid(columns: (auto, 1fr), column-gutter: 0.2in,
    code(read("../ex/ug-compile/count.c"), size: 7.5pt),
    screen(raw(read("../ex/ug-compile/dialect.txt"))))
] <ug-compile-dialect-fig>

#idx("trigraphs")
#cmd("-std=c89") and #cmd("-std=c99") select the dialects without the GNU
extensions. Trigraphs, such as #cmd("??!") for #cmd("|"), are replaced in
every dialect, without a message unless #cmd("-Wall") is given: the string
#cmd("\"what??!\"") is #cmd("\"what|\""). Write #cmd("\"what?\\?!\"") when
you mean the question marks.

== Writing C for EBCDIC <ug-compile-ebcdic>

#idx("EBCDIC", "in C programs")#idx("character set", "of C programs")
A program compiled by cc370 runs on MVS, where text is EBCDIC, code page 037.
The compiler translates every character constant and string literal into
EBCDIC, so that #cmd("'A'") is 193 (#cmd("X'C1'")) in the program, in the
same way as in a file on MVS. The value is the same everywhere in the
program, the preprocessor included: @ug-compile-ebcdic-fig asks the
preprocessor five questions about character values and shows the answers.

#fig(caption: [Character values as cc370 sees them])[
  #code(read("../ex/ug-compile/ebcdic.c"), size: 7.5pt)
  #screen(raw(read("../ex/ug-compile/ebcdic.txt")))
] <ug-compile-ebcdic-fig>

Most C code needs no change for this, because it compares characters with
character constants and leaves the values to the compiler. The code that
does need attention is the code that assumes the order of ASCII:

- *The letters are not contiguous.* In EBCDIC the alphabet is split into
  three groups, #cmd("a") to #cmd("i"), #cmd("j") to #cmd("r") and
  #cmd("s") to #cmd("z"), with other characters between them. A test such
  as #cmd("c >= 'a' && c <= 'z'") is true for #cmd("'~'"), and
  #cmd("c - 'a'") is not the position of a letter in the alphabet. Use the
  functions of #cmd("<ctype.h>"), as in @ug-compile-lower, which know the
  code page.
- *The sort order differs.* Lower-case letters sort before upper-case ones,
  and digits after both. A table sorted by #cmd("strcmp") on the
  workstation is in a different order on MVS.
- *Numeric codes are wrong.* Never write a character as its ASCII value,
  such as #cmd("0x41") for #cmd("'A'") or #cmd("10") for the newline. Write
  the character constant.

#fig(caption: [Testing for a lower-case letter])[
  #code(read("../ex/ug-compile/lower.c"), numbers: true)
] <ug-compile-lower>

#idx("newline")
The newline #cmd("'\\n'") is #cmd("X'15'"), the EBCDIC character NEL, the
newline that the C library and the mvslovers programs use. An escape
sequence with a number, such as #cmd("\\x41") or #cmd("\\101"), is not
translated: it stands for the byte with that value. Use numeric escapes for
binary data, and character constants for text.

#idx("character set", "of the source")
The source file itself is read in UTF-8 or in Latin-1, whichever it is. A
string literal may contain any character of Latin-1, such as #cmd("é"),
which becomes its code page 037 value. A character beyond Latin-1, such as
#cmd("€"), is an error in a literal\; in a comment it is allowed.

Data that a program exchanges with an ASCII system, over a network for
example, has to be translated explicitly. The _libc370 Programmer's Guide_
describes the functions for this.

== External Names <ug-compile-names>

#idx("external names")
The name of a function or a variable with external linkage becomes an
external name in the object module, and an external name on MVS has at most
eight characters. cc370 cuts the C name to eight characters, puts it in
upper case and replaces the underscore by #cmd("@"): #cmd("print_header")
becomes #cmd("PRINT@HE"). Names with static linkage are not affected\; they
do not appear in the object module.

#idx("external names", "collisions")
Two names that agree in their first eight characters therefore become the
same name. @ug-compile-names-fig compiles #cmd("names.c"), which defines
#cmd("print_header") and #cmd("print_heading"): the compiler warns, and the
assembler rejects the second definition of #cmd("PRINT@HE"), so the
compilation fails. The compiler also warns when one of the two names, or
both, are only referenced in the source\; then the compilation succeeds, and
every call goes to whichever function ends up with the name. Treat the
warning as an error.

#fig(caption: [Two names that collide, and the same names with asm
  labels])[
  #grid(columns: (1fr, 1fr), column-gutter: 0.2in,
    [#cmd("names.c")#code(read("../ex/ug-compile/names.c"), size: 7.5pt)],
    [#cmd("asmname.c")#code(read("../ex/ug-compile/asmname.c"), size: 7.5pt)])
  #screen(raw(read("../ex/ug-compile/names.txt")))
] <ug-compile-names-fig>

#idx("asm", "external name")
Declare a name with an #cmd("asm") label to give it an external name of
your own, as #cmd("asmname.c") does. The label is used exactly as written,
so write it in upper case, with at most eight characters. The C name stays
unchanged in the source\; only the object module sees the label. Put the
declaration in the header that the callers include, so that every source
uses the same external name.

A collision between names in _different_ sources is not seen by the
compiler, which compiles one source at a time. When two sources define the
name, ld370 warns that #cmd("PRINT@HE") is doubly defined, keeps the first
definition and still ends with return code 0. When one source defines
#cmd("print_heading") and another only calls #cmd("print_header"), nothing
reports the collision at all: the call reaches #cmd("print_heading"). Choose
external names that differ in their first eight characters, or give each an
#cmd("asm") label, from the start\; a static function needs neither.

#note[#cmd("#pragma map"), with which other MVS compilers rename an external
name, has no effect in cc370, and the compiler warns about it. Use an
#cmd("asm") label.]

== Choosing the Optimization Level <ug-compile-opt>

#idx("optimization")
cc370 accepts the optimization levels of GCC, but they are not equally
proven on this target. @ug-compile-opt-tab says which to use.

#tab(caption: [Optimization levels])[
  #table(columns: (0.8in, 1fr),
    [Level], [Use],
    [#cmd("-O1")], [For production code. It is the level at which the
      toolchain is validated, and the default of the mbt build tool.],
    [#cmd("-O0")], [The default when no #cmd("-O") is given. The code is
      larger and slower, but follows the source most closely, which helps
      when you read it in an assembler listing or a dump.],
    [#cmd("-Os")], [Experimental. It makes code smaller and is used for the
      C library, but has been tested on MVS far less than #cmd("-O1"). Test
      a program built with it with its own tests.],
    [#cmd("-O2"), #cmd("-O3")], [Not supported.],
  )
] <ug-compile-opt-tab>

#idx("printf", "replaced by puts")
At #cmd("-O1"), the compiler replaces some library calls by cheaper ones,
as @ug-first-asm showed: a #cmd("printf") of a plain string becomes
#cmd("puts"). A program that defines a function of the C library itself,
such as its own #cmd("printf"), must be compiled with #cmd("-fno-builtin")
to keep its calls as written.

== Warnings and Errors <ug-compile-warn>

#idx("warnings")#idx("-Wall")#idx("-Werror")
The compiler reports few warnings unless asked. #cmd("-Wall") turns on the
warnings that point at mistakes rather than at style: an unused variable, a
#cmd("printf") format that does not match its argument, a missing return
value, and many more. #cmd("-Werror") makes every warning fail the
compilation. The projects of the mvslovers ecosystem compile with both, and
it is a good rule for any program for MVS, where a mistake is far harder to
find in a dump than in a compiler message.

#fig(caption: [The same source without -Wall, with -Wall, and with
  -Werror])[
  #code(read("../ex/ug-compile/warn.c"), numbers: true, size: 7.5pt)
  #screen(raw(read("../ex/ug-compile/warn.txt")))
] <ug-compile-warn-fig>

Without #cmd("-Wall") the source of @ug-compile-warn-fig compiles silently.
With it, the two warnings appear and the return code is still 0\; with
#cmd("-Werror") as well, the same messages end the compilation with return
code 1, and no object module is written. The messages still read
#cmd("warning:").

The format warning matters even though #cmd("int") and #cmd("long") have the
same size on this target: the program would print the right value here,
and the wrong one when it is compiled for a system on which they differ.

#note[A warning of the assembler, return code 4, is shown and does not fail
the build. An assembler error, 8 or
higher, does. Both come only from assembler code you write yourself, in an
#cmd("asm") statement or an assembler source, or from a collision of
external names\; see @ug-asm.]

== Headers and the Sysroot <ug-compile-headers>

#idx("headers")#idx("sysroot")
The headers of the C library are in the sysroot, the directory
#cmd("cc370/include") of the installation, and the compiler searches it
without being told. The headers are arranged in groups:

#deflist(width: 1.55in,
  [#cmd("<stdio.h>"), ...], [the headers of the C standard, at the top.],
  [#cmd("<mvs/...>")], [the services of MVS: data sets, dynamic
    allocation, the console, TSO, tasks, and more.],
  [#cmd("<ext/...>")], [portable extensions of the library.],
  [#cmd("<s370/...>"), #cmd("<ibm/...>")], [the System/370 machine and the
    control blocks of MVS.],
  [#cmd("<sys/...>"), #cmd("<netinet/...>"), #cmd("<arpa/...>")], [the
    headers for sockets.],
)

The _libc370 Programmer's Guide_ and the _libc370 Library Reference_
describe them.

#idx("-I")
#cmd("-I") #var("directory") adds a directory of your own headers. It is
searched before the sysroot, so a header of yours with the name of a
library header hides the library's. Write #cmd("#include \"name.h\"") for
your own headers and #cmd("#include <name.h>") for the library's.

#idx("predefined macros")
To compile one source for both MVS and the workstation, test the macros the
compiler predefines: #cmd("__MVS__") is defined for the MVS target, and
#cmd("__CC370__") gives the version of the compiler, for example
#cmd("10400") for 1.4.0. @ug-compile-portable reads its input from a DD
statement on MVS and from a file on the workstation, and refuses a compiler
that is too old. It compiles without a warning with cc370 and with the C
compiler of the workstation.

#fig(caption: [A source for MVS and for the workstation])[
  #code(read("../ex/ug-compile/portable.c"), numbers: true, size: 7.5pt)
] <ug-compile-portable>

== Passing Options to the Assembler and the Linkage Editor <ug-compile-passthru>

#idx("-Wa")#idx("-Wl")
cc370 passes its own options to the phase they belong to, but options of
as370 and ld370 must be passed explicitly: #cmd("-Wa,")#var("option") to
as370 and #cmd("-Wl,")#var("option") to ld370. An option with a value is
written with a comma between the two, as in #cmd("-Wl,--map,hello.map").
Some ld370 options you will pass this way:

#deflist(width: 1.4in,
  [#cmd("-Wl,--dsn,")#var("name")], [records #var("name") in the TRANSMIT
    file as the name of the library, in place of
    #cmd("IBMUSER.HOST.LOAD").],
  [#cmd("-Wl,--map,")#var("file")], [writes a load map: every section of
    the module, where it came from and where it is.],
  [#cmd("-Wl,--ac,1")], [marks the module for authorized execution.],
  [#cmd("-Wl,--rent"), #cmd("-Wl,--reus")], [mark the module reentrant
    or reusable.],
  [#cmd("-Wa,-a=")#var("file")], [writes an assembler listing of the
    compiled source.],
)

@ug-compile-passthru-fig builds HELLO with a library name and a load map.
@ug-link describes the load map and the module attributes, and
@ug-diag the listing.

#fig(caption: [Passing options to ld370])[
  #screen(raw(read("../ex/ug-compile/passthru.txt")))
] <ug-compile-passthru-fig>
