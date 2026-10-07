#import "../bookmaster/bookmaster.typ": *

= The cc370 Command <cc>

#idx("cc370")
The cc370 command is the C compiler driver. It compiles C source to
System/370 assembler language, runs as370 on the result to obtain an object
module and, unless told to stop earlier, runs ld370 on the object modules to
produce an MVS load module. Everything happens on the workstation; the load
module, optionally wrapped for transport, is the only file that has to reach
MVS.

cc370 is derived from the GNU C compiler, version 3.4.6, and accepts its
command language. This chapter describes what is particular to the MVS
target: the phases and the files they produce, the libraries and start-up
code a program is linked with, the character set, the names a C program has
on MVS, and the options of the target. Options that behave as in any GCC
3.4.6 driver are listed, but not described again.

== How cc370 Builds a Program <cc370-phases>

#idx("cc370", "phases")
cc370 runs up to three programs, one after the other:

+ #cmd("cc1"), the compiler proper, which preprocesses and compiles C source
  to an assembler source;#idx("cc1")
+ #cmd("as"), which is as370, described in Chapter 2\;
+ #cmd("ld"), which is ld370, described in Chapter 3.

cc1 is private to the driver and is not on the search path. The names
#cmd("as") and #cmd("ld") are links to as370 and ld370 that the driver finds
in its own program directory, #cmd("libexec/cc370/")#var("version") under the
installation prefix, before it looks anywhere else. The option #cmd("-###")
displays the commands the driver would run, without running them\;
#cmd("-v") displays them and runs them. @cc370-phases-fig shows the commands
for a complete build\; in the figure, the installation prefix is shown as
#cmd("$PREFIX"), the temporary directory as #cmd("$TMP"), and the long lines
are broken.#idx("-###")

#fig(caption: [The three phases of a build])[
  #screen(raw(read("../ex/cc370/phases.txt")))
] <cc370-phases-fig>

The intermediate assembler source and object module are temporary files and
are deleted when the build ends. #cmd("-save-temps") keeps them in the
current directory, together with the preprocessed source (#cmd(".i")).

=== Where cc370 Stops

#idx("cc370", "-E, -S, -c")
Without an option the driver runs every phase that the input needs. Three
options end the build earlier, as @cc370-stop-tab shows.

#tab(caption: [Stopping points of cc370])[
  #table(columns: (0.7in, 1.3in, 1fr),
    [Option], [Last phase run], [Output],
    [#cmd("-E")], [preprocessor], [the preprocessed source, written to
      standard output unless #cmd("-o") names a file],
    [#cmd("-S")], [cc1], [an assembler source, #var("name")#cmd(".s")],
    [#cmd("-c")], [as370], [an object module, #var("name")#cmd(".o")],
    [none], [ld370], [a load module member, #cmd("a.out") unless
      #cmd("-o") names it\; see @cc370-output],
  )
] <cc370-stop-tab>

#var("name") is the name of the source without its extension. With
#cmd("-S") or #cmd("-c") and a single source, #cmd("-o") names the output
instead.

With #cmd("-c") or #cmd("-S") and several sources, each source gets an
output file of its own, and #cmd("-o") cannot be given: cc370 refuses the
command with #cmd("cannot specify -o with -c or -S and multiple files") and
return code 1.

=== Input Files

#idx("cc370", "input files")
The driver decides what to do with an input file by its extension:

#deflist(width: 1.1in,
  [#cmd(".c")], [C source: preprocessed, compiled, assembled.],
  [#cmd(".i")], [Preprocessed C source: compiled and assembled.],
  [#cmd(".s")], [Assembler source: assembled by as370.],
  [#cmd(".o"), #cmd(".a")], [Object module or object library: passed to
    ld370.],
  [any other], [Passed to ld370 as it is. A file with the extension
    #cmd(".asm") is therefore not assembled: put #cmd("-x assembler") in
    front of it.#idx("-x")],
)

With #cmd("-c"), a file that would only be given to ld370 is ignored with
the message #cmd("linker input file unused because linking not done").

== Invoking cc370 <cc370-invoke>

#idx("cc370", "syntax")
#syntax(read("../syntax/cc370-main.txt"))

#syntax(title: "Option:", read("../syntax/cc370-option.txt"))

Options and file names may be given in any order, except that the order of
object modules and #cmd("-l") libraries is the order in which ld370 reads
them.

=== Operands

#deflist(width: 1.75in,
  [#var("file")], [is a C source, a preprocessed source, an assembler
    source, an object module or an object library\; see @cc370-phases.],
  [#cmd("-E")], [preprocesses only\; see @cc370-stop-tab.],
  [#cmd("-S")], [compiles to assembler source only.],
  [#cmd("-c")], [compiles and assembles, but does not link.],
  [#cmd("-o") #var("file")], [names the output file. For a link, it names
    the load module member and gives the member name\; see
    @cc370-output.],
  [#cmd("-flinker-output=")#var("type")], [writes a transport file beside
    the load module member: #cmd("xmit") a TSO TRANSMIT file,
    #cmd("iebcopy") an IEBCOPY unloaded data set. See @cc370-output. Any
    other #var("type") is an error, on every command, also one that does not
    link.],
  [#cmd("-O")#var("level")], [selects the optimization level\; see
    @cc370-opt.],
  [#cmd("-std=")#var("standard")], [selects the C dialect\; see
    @cc370-dialect.],
  [#cmd("-m")#var("target-option")], [one of the target options described
    in @cc370-target.],
  [#cmd("-D") #var("name")\[#cmd("=")#var("value")\]], [defines a
    preprocessor macro.],
  [#cmd("-U") #var("name")], [undefines a preprocessor macro.],
  [#cmd("-I") #var("directory")], [adds a directory to the header search,
    ahead of the C library headers.],
  [#cmd("-L") #var("directory")], [adds a directory to the library search of
    ld370.],
  [#cmd("-l") #var("library")], [links the object library
    #cmd("lib")#var("library")#cmd(".a").],
  [#cmd("-e") #var("entry")], [names the entry point of the load module\;
    see @cc370-startup.],
  [#cmd("-nostartfiles")], [is accepted and has no effect: the driver links
    no start-up object\; see @cc370-startup.],
  [#cmd("-nodefaultlibs"), #cmd("-nostdlib")], [do not link the C library
    and the run-time support library, and so not the C start-up
    either.],
  [#cmd("-Wa,")#var("options")], [passes options to as370\; see
    @cc370-passthru.],
  [#cmd("-Xassembler") #var("argument")], [passes one argument to as370.],
  [#cmd("-Wl,")#var("options")], [passes options to ld370.],
  [#cmd("-Xlinker") #var("argument")], [passes one argument to ld370.],
  [#cmd("-Wp,")#var("options")], [passes options to the preprocessor.],
  [#cmd("-Xpreprocessor") #var("argument")], [passes one argument to the
    preprocessor.],
  [#cmd("-x") #var("language")], [treats the files that follow as
    #var("language"), for example #cmd("c") or #cmd("assembler"), whatever
    their extension. #cmd("-x none") returns to deciding by the
    extension.],
  [#cmd("-v")], [displays the configuration, the version and each command
    as it is run. Unlike #cmd("-V"), it does not end the command.],
  [#cmd("-###")], [displays the commands without running them.],
  [#cmd("-save-temps")], [keeps the intermediate files.],
  [#cmd("-pass-exit-codes")], [ends with the return code of the phase that
    failed instead of 1\; see @cc370-rc.],
  [#cmd("-print-file-name=")#var("file")], [displays the full name of a
    file of the C library, for example #cmd("libc.a") or
    #cmd("crtm.o").],
  [#cmd("-print-libgcc-file-name")], [displays the full name of
    #cmd("libcc370rt.a"), the run-time support library (@cc370-sysroot).],
  [#cmd("-print-search-dirs")], [displays the program and library search
    paths.],
  [#cmd("-print-prog-name=")#var("program")], [displays the full name of
    #cmd("cc1"), #cmd("as") or #cmd("ld").],
  [#cmd("-dumpmachine")], [displays the target name, #cmd("cc370").],
  [#cmd("-dumpversion")], [displays the toolchain version, for example
    #cmd("1.4.0").],
  [#cmd("-dumpspecs")], [displays the rules by which the driver builds the
    commands of the phases.],
  [#cmd("-h"), #cmd("--help")], [display a summary of the driver options
    and end with return code 0. Nothing is compiled or linked.],
  [#cmd("--target-help")], [displays the target options of
    @cc370-target and ends with return code 0. Nothing is compiled or
    linked, even when files are named.],
  [#cmd("-V"), #cmd("--version")], [display the version, the commit the
    driver was built from and the GCC version it is based on, on one line,
    for example #cmd("cc370 1.4.0 (2821ebb), based on GCC 3.4.6"), and end
    with return code 0. Nothing is compiled or linked.],
  [#cmd("-b") #var("machine")], [is refused with return code 1. In GCC it
    selects another target\; cc370 has only one. #cmd("-V") followed
    directly by a version, as in #cmd("-V3.4"), is refused the same way.],
  [#var("gcc-option")], [any other option of the GCC 3.4.6 driver and
    compiler, such as the #cmd("-W") warning options, the #cmd("-f") code
    generation options and #cmd("-g"). They behave as described in the GCC
    3.4.6 manual.],
)

#note[#cmd("-pipe") is accepted and has no effect: the phases always
exchange temporary files, because as370 reads its source from a file.]

== From C Source to Assembler Source <cc370-asm>

#idx("cc370", "-S option")
With #cmd("-S"), cc370 stops after compiling and writes the assembler source
to a file named after the C source, with the extension #cmd(".s"). The
program in @cc370-upcase-c copies #cmd("SYSIN") to #cmd("SYSPRINT") and
folds each record to upper case\; the command

```
cc370 -O1 -S upcase.c
```

writes #cmd("upcase.s"), the beginning of which is shown in
@cc370-upcase-s.

#fig(caption: [UPCASE, a C program])[
  #code(read("../ex/cc370/upcase.c"), numbers: true)
] <cc370-upcase-c>

Four things in @cc370-upcase-s are worth noting:

- The module is one control section without a name, unless
  #cmd("-mcsect=") names it\; see @cc370-target.
- String literals become #cmd("DC") statements in EBCDIC. The newline that
  ends the #cmd("fprintf") format is the byte #cmd("X'15'"), the EBCDIC
  newline used throughout the mvslovers ecosystem\; see @cc370-charset.
- The C function #cmd("main") becomes the entry #cmd("MAIN"). Beside it,
  #cmd("@@MAIN") is a stub that branches to #cmd("@@CRT0"), the start-up
  routine\; see @cc370-startup.
- Each function begins with the #cmd("PDPPRLG") macro and ends with
  #cmd("PDPEPIL"). The macros come with the toolchain and are found by as370
  as described in @as370-maclib.#idx("PDPPRLG")#idx("PDPEPIL") The arguments of a
  call are passed in a parameter list addressed by register 1, and the
  function value is returned in register 15.

#fig(caption: [Assembler source generated for UPCASE (beginning)])[
  #code(read("../ex/cc370/upcase.s").split("\n").slice(0, 52).join("\n"), numbers: true, size: 7.5pt)
] <cc370-upcase-s>

== The Load Module <cc370-output>

#idx("load module", "written by cc370")
A build that is not stopped early ends with ld370 and writes one load module
member: a host file that holds the records of one member of a load library.
Chapter 3 describes the format.

#idx("member name")
The member name is taken from the name given by #cmd("-o"): the directory
and everything from the first period on are removed, the rest is put in
upper case and cut to eight characters. #cmd("-o upcase.lm") gives the
member #cmd("UPCASE"), #cmd("-o verylongname1") the member
#cmd("VERYLONG"). Without #cmd("-o") the file is #cmd("a.out") and the member
#cmd("A"). The name is not checked: #cmd("-o my_prog") gives the member
#cmd("MY_PROG"), which is not a valid member name on MVS. Always give
#cmd("-o"), with a name that is valid on MVS.

#idx("-flinker-output")
A member file cannot be uploaded to MVS as it is. #cmd("-flinker-output=")
asks ld370 to write, in addition to the member, a file that can:

#deflist(width: 1.6in,
  [#cmd("-flinker-output=xmit")], [writes #var("out")#cmd(".xmit"), a TSO
    TRANSMIT (NETDATA) file of 80-byte records that holds an IEBCOPY
    unloaded load library with the one member. It is uploaded in binary to
    a data set with fixed 80-byte records and installed with the TSO
    #cmd("RECEIVE") command.#idx("XMIT")],
  [#cmd("-flinker-output=iebcopy")], [writes #var("out")#cmd(".iebcopy"),
    the IEBCOPY unloaded data set itself. It carries the member's directory
    entry, so ld370 can combine several of them into one library with
    #cmd("--pack").#idx("IEBCOPY", "unloaded data set")],
)

#var("out") is the whole name given by #cmd("-o"), so #cmd("-o upcase.lm")
writes #cmd("upcase.lm.xmit"). The data set name recorded in the TRANSMIT
file, the block size and the module attributes are ld370 options\; pass them
with #cmd("-Wl,") (@cc370-passthru) and see Chapter 3 for their meaning.

== Libraries and Start-Up Code <cc370-sysroot>

#idx("sysroot")#idx("libc370")
The toolchain is installed with its C library, libc370, in a directory tree
of its own, #cmd("cc370/") under the installation prefix:

#deflist(width: 1.4in,
  [#cmd("cc370/include")], [the C library headers. The compiler searches
    this directory without #cmd("-I")\; a directory given with #cmd("-I") is
    searched first.],
  [#cmd("cc370/lib")], [#cmd("libc.a"), the C library, which also holds the
    start-up routine #cmd("@@CRT0")\; and #cmd("libcc370rt.a"), the run-time
    support library. libc370 2.4.0 also installs the start-up object
    #cmd("crtm.o"), which the driver does not use unless you name it.],
  [#cmd("cc370/macros")], [the assembler macros, among them #cmd("PDPTOP"),
    #cmd("PDPPRLG") and #cmd("PDPEPIL")\; see @as370-maclib.],
)

A C library that is kept in a tree of its own can be linked in as
#cmd("cc370/libc370")\; its #cmd("include") and #cmd("lib") directories are
then searched after those above.

#idx("libcc370rt")
Every link names the libraries #cmd("-lcc370rt -lc -lcc370rt"), in that
order, after the object modules of the program, so no #cmd("-l") is needed
for the C library. #cmd("libcc370rt.a") holds the routines the compiler
calls for operations that have no System/370 instruction: 64-bit
multiplication, division and remainder, conversions between
#cmd("long long") and floating point, and bit counting. Their names begin
with #cmd("@@"), for example #cmd("@@DIVDI3"). ld370 takes from the
libraries only the members the program needs.

#idx("libc370", "version required")
cc370 1.4 needs libc370 2.3.0 or later. Since that release the start-up
routine is a member of #cmd("libc.a")\; an older #cmd("libc.a") has none,
and a program with a #cmd("main") does not link. The cc370 packages
require libc370 2.3.0 for this reason. libc370 2.4.0 in turn requires cc370
1.4.0: every one of its headers stops the compile with
#cmd("libc370 needs cc370 1.4.0 or later") under an older cc370.

=== Entry Point and Start-Up <cc370-startup>

#idx("entry point")#idx("@@CRT0")#idx("@@START")
The driver links no start-up object of its own. It passes
#cmd("--entry @@CRT0") to ld370 (@cc370-phases-fig), and a source that
defines #cmd("main") refers to #cmd("@@CRT0"), so automatic library call
takes the start-up routine from #cmd("libc.a") like any other routine. MVS
gives control to #cmd("@@CRT0"), which builds the run time and calls
#cmd("@@START"), the C start-up routine of the library. #cmd("@@START")
calls #cmd("__premain") if the program defines it, opens the standard
streams and calls #cmd("MAIN"), the C function #cmd("main"). A library named
with #cmd("-l") is searched before the C library, so one that defines
#cmd("@@START") replaces the routine of the C library without a message\;
put work before #cmd("main") into #cmd("__premain") instead (libc370 2.4.0
or later). The _cc370 User's Guide_ describes it under "Work Before main", the
_libc370 Programmer's Guide_ under "Running Code Before main()".

#idx("CTHREAD")
The start-up refers to #cmd("CTHREAD"), the thread driver of the C library,
by a weak reference. A program that creates threads with
#cmd("cthread_create") links it with that function, and the start-up then registers it with MVS\; a program that does not
links none of it. No option chooses between the two.

#idx("entry point", "offset in the module")
The object modules named on the command line come first in the load module,
and #cmd("@@CRT0") lies wherever the library search puts it, not at offset
0. The directory entry of the member points to it, and the first line of the
load map names it with its offset: the map of UPCASE begins
#cmd("ENTRY @@CRT0 0001F8"), because the code of #cmd("upcase.c"), at offset
0, is #cmd("X'1F8'") bytes long.

A source that defines #cmd("main") also defines #cmd("@@MAIN") and names
it on its #cmd("END") statement. The entry point of the load module is set
by #cmd("--entry"), so #cmd("@@MAIN") matters only when the object module is
link-edited by another linkage editor without an #cmd("ENTRY") statement:
it then leads to #cmd("@@CRT0") as well.

The start-up can be changed in two ways:

- A C module that a running C program enters on the same task does not
  build a run time of its own: it uses the caller's. Its caller passes the
  address of a parameter block, a halfword length and the text, in
  register 0, not in a register-1 parameter list, so a plain LINK is not
  enough. Link it with the start-up object #cmd("crtm.o") that
  libc370 installs. It defines #cmd("@@CRT0"), so the library member is not
  taken:
  ```
  cc370 -o sub sub.c $(cc370 -print-file-name=crtm.o)
  ```
  *Never use #cmd("crtm.o") for a program that MVS starts*, as a job step
  or a TSO command: without a C program before it on the same task there is
  no run time to use, and the module abends. How the two start-ups differ
  is described in the _libc370 Programmer's Guide_, "The Start-Up
  Routines" in the chapter "Program Structure and Start-Up".
- To link a module that does not use the C start-up at all, give
  #cmd("-e") #var("entry"). ld370 uses the last entry it is given, which is
  #var("entry"). A name in lower case is accepted: #cmd("-e myentry") finds
  the entry #cmd("MYENTRY"). Without #cmd("-e"), the driver's
  #cmd("--entry @@CRT0") brings in the C start-up even for a source without
  #cmd("main"), and the link fails on the unresolved reference to
  #cmd("MAIN").

#idx("-nostartfiles")#idx("-nostdlib")#idx("-nodefaultlibs")
#cmd("-nostartfiles") has no effect: there is no start-up object to leave
out, and the module is the same as without it. #cmd("-nodefaultlibs") and
#cmd("-nostdlib") leave out the libraries, and with them #cmd("@@CRT0")\;
use them only for a module that has its own entry point and calls nothing
in the libraries, together with #cmd("-e").

== Language Dialect and Predefined Macros <cc370-dialect>

#idx("C dialect")#idx("-std")
Without #cmd("-std"), cc370 compiles the GNU dialect of C89
(#cmd("gnu89")), the default of GCC 3.4.6: a declaration in the first clause
of a #cmd("for") statement is an error. The projects of the mvslovers
ecosystem compile with #cmd("-std=gnu99"). #cmd("-std=c89"), #cmd("c99"),
#cmd("gnu89") and #cmd("gnu99") are accepted, with the meaning they have in
GCC 3.4.6.

#idx("trigraphs")
Trigraphs are always replaced, whatever #cmd("-std") says:
#cmd("\"what??!\"") becomes #cmd("\"what|\""), so a string has the same value under every
dialect. The
replacement is silent\; #cmd("-Wall") or #cmd("-Wtrigraphs") reports each
trigraph with a warning. To write the characters #cmd("??!") themselves,
escape the second question mark: #cmd("\"what?\\?!\"").#idx("trigraphs", "escaping")

#idx("predefined macros")
Besides the macros of GCC 3.4.6, cc370 defines the macros in
@cc370-macro-tab. #cmd("cc370 -dM -E - </dev/null") lists all of them.

#tab(caption: [Macros predefined by cc370 1.4.0])[
  #table(columns: (1.6in, 0.7in, 1fr),
    [Macro], [Value], [Meaning],
    [#cmd("__CC370__")], [#cmd("10400")], [the toolchain version: major
      × 10000 + minor × 100 + patch],
    [#cmd("__CC370_MAJOR__")], [#cmd("1")], [major version],
    [#cmd("__CC370_MINOR__")], [#cmd("4")], [minor version],
    [#cmd("__CC370_PATCH__")], [#cmd("0")], [patch level],
    [#cmd("__CC370_WEAK__")], [#cmd("1")], [weak references are supported\;
      see @cc370-weak],
    [#cmd("__MVS__")], [#cmd("1")], [the target is MVS],
    [#cmd("__CHAR_UNSIGNED__")], [#cmd("1")], [plain #cmd("char") is
      unsigned],
    [#cmd("__FLT_RADIX__")], [#cmd("16")], [floating point is System/370
      hexadecimal floating point],
  )
] <cc370-macro-tab>

#idx("data types", "sizes")
@cc370-types-tab gives the sizes of the basic types. Floating point is
hexadecimal: #cmd("float") has 6 hexadecimal digits of fraction,
#cmd("double") and #cmd("long double") 14\; the largest value is about
#cmd("7.2E+75"), and there are no infinities and no NaNs
(#cmd("__DBL_HAS_INFINITY__") and #cmd("__DBL_HAS_QUIET_NAN__") are 0).

#tab(caption: [Sizes of the basic types, in bytes])[
  #table(columns: (2.2in, 1fr),
    [Type], [Size],
    [#cmd("char")], [1],
    [#cmd("short")], [2],
    [#cmd("int"), #cmd("long"), pointers], [4],
    [#cmd("long long")], [8],
    [#cmd("float")], [4],
    [#cmd("double"), #cmd("long double")], [8],
    [#cmd("wchar_t")], [4 (an #cmd("int"))],
  )
] <cc370-types-tab>

A pointer occupies four bytes, but MVS 3.8j uses only 24 bits of an
address.

== Character Set <cc370-charset>

#idx("character set", "of C programs")#idx("EBCDIC")
A C program compiled by cc370 runs in EBCDIC. Character constants and string
literals are translated to code page 037 by the compiler, so that a constant
has the same value in the program as on MVS: #cmd("'A'") is 193
(#cmd("X'C1'")), and #cmd("#if 'A' == 193") is true. Write characters as
character constants, never as their ASCII codes.

#idx("newline")
The newline #cmd("'\\n'") is #cmd("X'15'"), the EBCDIC NEL character, and
not #cmd("X'25'"). This is the newline that the C library and the
mvslovers programs agree on. Other characters map to their code page 037
values, for example #cmd("'\\t'") to #cmd("X'05'") and #cmd("'['") to
#cmd("X'BA'").

#idx("escape sequences")
An escape sequence with a number, #cmd("\\x")#var("hh") or
#cmd("\\")#var("ooo"), is not translated: it stands for the byte with that
value. #cmd("\"\\x41\"") is therefore the byte #cmd("X'41'"), not the letter
#cmd("A").

@cc370-charset-fig shows the three rules.

#fig(caption: [Character constants and a string literal (left) and the
  code cc370 generates for them (right)])[
  #grid(columns: (1fr, 1fr), column-gutter: 0.2in,
    code(read("../ex/cc370/charset.c")),
    code(read("../ex/cc370/charset.s").split("\n").slice(5, 21)
      .filter(l => not l.starts-with("*") and not l.contains("ENTRY")).join("\n")))
] <cc370-charset-fig>

#idx("character set", "of the source")
The source is read in UTF-8 or in Latin-1 (ISO 8859-1)\; cc370 decides for
each file, and the locale of the workstation plays no part. A file that is
valid UTF-8 is read as UTF-8, any other file as Latin-1. A leading byte
order mark is ignored. In @cc370-charset-fig, #cmd("é") is written in UTF-8
and becomes #cmd("X'51'")\; the same character written as the Latin-1 byte
#cmd("X'E9'") gives the same result.

A character constant or string literal can hold only the characters of
Latin-1, up to U+00FF. A character above it is an error, as @cc370-errors
shows for #cmd("€"). Comments may contain any character. A wide character
constant above U+00FF, such as #cmd("L'€'"), keeps its Unicode value
(8364)\; up to U+00FF a wide character is translated to code page 037 like a
narrow one.

== External Names <cc370-names>

#idx("external names")
An external name in an MVS object module has at most eight characters, in
upper case. cc370 makes such a name from a C name with external linkage, a
function or a variable, in three steps:

+ The name is cut to eight characters.
+ Lower-case letters become upper case.
+ The underscore becomes #cmd("@").

#cmd("copy_file") becomes #cmd("COPY@FIL"), #cmd("record_count")
#cmd("RECORD@C") and #cmd("Trace") #cmd("TRACE"), as @cc370-names-fig
shows. Names with static linkage do not appear in the object module\; cc370
gives them internal labels such as #cmd("@V1").

#idx("asm", "external name")
To give a C name an external name of your choice, declare it with an
#cmd("asm") label. The name in the label is used as written, without
translation:

```
extern int write_rec(int) asm("WRITEREC");
```

#fig(caption: [External names made from C names (right: excerpts of the
  generated code)])[
  #let s = read("../ex/cc370/names.s").split("\n")
  #grid(columns: (auto, auto), column-gutter: 0.25in,
    code(read("../ex/cc370/names.c"), size: 7.5pt),
    code((s.slice(3, 4) + s.slice(6, 8) + ("...",) + s.slice(11, 12)
      + ("...",) + s.filter(l => l.contains("=V("))).join("\n"), size: 7.5pt))
] <cc370-names-fig>

#idx("external names", "collisions")
Two C names that agree in their first eight characters, apart from case,
get the same external name. Within one source, cc370 warns about every such
pair, whether the names are defined or only referenced:

- When both are defined, as370 then rejects the second definition, and the
  build fails.
- When one is defined and the other referenced, or both are referenced, the
  build continues with the warning only. The calls reach whatever ends up
  with that name: in @cc370-errors, #cmd("codec_stream_encode") calls
  itself.

cc370 compiles one source at a time and cannot see the names of another.
When two sources define colliding names, ld370 warns that the name is doubly
defined, keeps the first definition and ends with return code 0. When one
source defines a name and another only references a colliding one, nothing
reports the collision. Choose names that differ in their first eight
characters, or give one of them an #cmd("asm") label.

#idx("pragma")
The pragmas #cmd("#pragma map"), #cmd("#pragma linkage"),
#cmd("#pragma checkout"), #cmd("#pragma nomargins") and
#cmd("#pragma nosequence") of the MVS compilers are accepted and have no
effect. #cmd("#pragma map") and #cmd("#pragma linkage") say so with a
warning: #cmd("#pragma map") does not change an external name, so use an
#cmd("asm") label instead\; #cmd("#pragma linkage") does not change how a
function is called. The other three are accepted silently. Any other
pragma is ignored, silently by default and with a warning under
#cmd("-Wall") or #cmd("-Wunknown-pragmas"). Like every warning, these do not change
the return code, but #cmd("-Werror") turns them into errors. #cmd("-w")
suppresses them\; #cmd("-Wno-unknown-pragmas") does not.

A header in the sysroot is a system header, and its warnings are not
shown, also with #cmd("-Wall -Werror"). The same header named with
#cmd("-I") from a libc370 source tree is an ordinary header, and its
warnings are reported.

== Weak References <cc370-weak>

#idx("weak external reference")#idx("WXTRN")#idx("__attribute__", "weak")
A function or variable declared with #cmd("__attribute__((weak))") is a
weak external reference: cc370 writes a #cmd("WXTRN") for it, at the end of
the assembler source, and the linkage editor treats it as optional.

```
extern int trace_hook(const char *msg) __attribute__((weak));
```

- When a module of the link defines the name, the reference is resolved
  like any other.
- When none does, the link still succeeds, with return code 0. The name is
  listed with type #cmd("WX") under #cmd("UNRESOLVED") in the load map, and
  its address is 0. Test it before you use it:
  #cmd("if (trace_hook != 0) trace_hook(\"...\");").
- Automatic library call does not search for a weak reference. A library
  member that defines the name is taken only when the link needs it for
  another reason, or with #cmd("-Wl,--include,")#var("member").
- A weak declaration that the source does not use produces nothing.

#cmd("__CC370_WEAK__") is predefined as 1 by a cc370 that supports weak
references, so a source can test for them with #cmd("#ifdef").

@cc370-weak-fig compiles the program #cmd("opt.c"), which calls
#cmd("trace_hook") when it is present, and #cmd("hook.c"), which defines it.
Linked against a library that holds #cmd("hook.o"), the program leaves the
reference unresolved\; linked with #cmd("hook.o") named, it calls the
function.

#fig(caption: [A weak reference, unresolved and resolved])[
  #grid(columns: (1fr, 1fr), column-gutter: 0.2in,
    code(read("../ex/cc370/opt.c"), size: 7.5pt),
    code(read("../ex/cc370/hook.c"), size: 7.5pt))
  #screen(raw(read("../ex/cc370/weak.txt")))
] <cc370-weak-fig>

#idx("-Wweak-definition")
MVS has no weak definition. A definition with #cmd("__attribute__((weak))")
is compiled as an ordinary definition: the name is external, as the entry
point #cmd("TRACE@HO") in the last command of @cc370-weak-fig shows, and a
module that defines it again gets ld370's #cmd("doubly defined") warning
instead of being preferred. cc370 warns with
#cmd("weak definition of '")#var("name")#cmd("' is an ordinary definition on MVS")
(#cmd("-Wweak-definition"), on by default\;
#cmd("-Wno-weak-definition") turns it off). Put the attribute on the
declarations that reference a name, not on its definition.

A name that a source declares weak, uses, and then defines itself is an
ordinary name of that source: its references go to its own definition, no
#cmd("WXTRN") is written, and the definition draws the warning above.

== Optimization <cc370-opt>

#idx("optimization")#idx("-O")
The optimization levels are those of GCC 3.4.6: #cmd("-O0"), the default,
#cmd("-O1"), #cmd("-O2"), #cmd("-O3") and #cmd("-Os"). cc370 accepts all of
them, but they are not equally proven on this target:

#deflist(width: 1.1in,
  [#cmd("-O1")], [is the level the toolchain is validated at, and the level
    mbt builds with by default. Use it for production code.],
  [#cmd("-O0")], [generates larger and slower code, but code that is the
    easiest to follow in an assembler listing.],
  [#cmd("-Os")], [is experimental. The sources of the ecosystem compile and
    assemble with it, but it has been run on MVS far less than
    #cmd("-O1")\; a program built with it needs its own tests.],
  [#cmd("-O2"), #cmd("-O3")], [are not supported.],
)

Two optimizations that the higher levels of GCC turn on are off on this
target at every level: compiling a file as one unit
(#cmd("-funit-at-a-time")) and the aliasing rules of the C standard
(#cmd("-fstrict-aliasing")). The options named turn them on again.

#idx("printf", "replaced by puts")
As in any GCC, #cmd("-O1") replaces some library calls by cheaper ones: a
#cmd("printf") of a string that ends in a newline becomes a call of
#cmd("puts"). A program that defines its own #cmd("printf") is compiled with
#cmd("-fno-builtin"), which keeps the call as written.

== Target Options <cc370-target>

#idx("target options")
#cmd("cc370 --target-help") lists the options of the System/370 target:

#deflist(width: 1.8in,
  [#cmd("-mchar-instructions")], [uses storage-to-storage and
    storage-immediate instructions such as #cmd("MVC"), #cmd("MVI"),
    #cmd("NI"), #cmd("OI") and #cmd("XI") for operations on bytes in
    storage. This is the default.],
  [#cmd("-mno-char-instructions")], [does not use them: a byte is loaded
    into a register with #cmd("IC"), changed there and stored back with
    #cmd("STC"). @cc370-char-tab shows the difference.],
  [#cmd("-mcsect=")#var("name")], [names the control section of the
    module. The name is put in upper case and cut to eight characters.
    #cmd("-mcsect=upcase") writes #cmd("UPCASE CSECT") both before and
    after #cmd("COPY PDPTOP"), so that the object module holds the one
    section #cmd("UPCASE"), type #cmd("SD"), and no other. Without the
    option the module is one section without a name, type #cmd("PC").],
  [#cmd("-mrent")], [declares that the translation unit goes into a
    reentrant load module, and reports its writable data (see below). It
    changes no generated code. From cc370 1.5.0 on.],
  [#cmd("-mno-rent")], [the default: no such check.],
)

#idx("-mrent")#idx("-Wwritable-data")#idx("reentrant", "writable data")
A reentrant load module is one copy that every task linking to it shares.
cc370 keeps a C #cmd("static") or global variable in the module itself, so
every such definition that is not #cmd("const") is state those tasks share
without serialization. Under #cmd("-mrent") each one draws the warning
#cmd("-Wwritable-data"): global variables, #cmd("static") variables at file
scope and inside functions, and #cmd("const volatile") objects.
#cmd("const char *p") is writable, because the pointer is\;
#cmd("char *const p") is not. Declarations (#cmd("extern")) and string
literals draw no warning\; under #cmd("-fwritable-strings") the string
literals are writable too, and one warning says so. #cmd("__stklen") is
exempt: the start-up reads it as the size of the stack.

The warning is on by default under #cmd("-mrent"), an error under
#cmd("-Werror"), and #cmd("-Wno-writable-data") turns it off. It sees only
the translation unit being compiled: code that automatic library call
takes from a library was compiled without it and is not checked. Give
#cmd("-mrent") to every source of a module that is linked with
#cmd("--rent").

The options #cmd("-mpickax") and #cmd("-mno-pickax") of earlier releases are
gone\; cc1 rejects them with #cmd("invalid option"), return code 1.

#tab(caption: [Code for #cmd("p->flags |= 0x80; p->buf[0] = 'A';") at
  #cmd("-O1")])[
  #table(columns: (1fr, 1fr),
    [#cmd("-mchar-instructions")], [#cmd("-mno-char-instructions")],
    code("OI    0(2),128\nMVI   2(2),193"),
    code("IC    3,0(2)\nO     3,=XL4'80'\nSTC   3,0(2)\nL     3,=F'-63'\nSTC   3,2(2)"),
  )
] <cc370-char-tab>

== Passing Options to as370 and ld370 <cc370-passthru>

#idx("-Wa")#idx("-Wl")#idx("-Xlinker")
The driver passes the options it knows to the phase they belong to, but
as370 and ld370 options must be passed explicitly:

- #cmd("-Wa,")#var("option")\[#cmd(",")#var("option")\]... passes each
  #var("option") to as370\; #cmd("-Xassembler") #var("argument") passes one
  argument.
- #cmd("-Wl,")#var("option")\[#cmd(",")#var("option")\]... passes each
  #var("option") to ld370\; #cmd("-Xlinker") #var("argument") passes one
  argument.

An option with a value takes two items, as in #cmd("-Wl,--ac,1") or
#cmd("-Xlinker --map -Xlinker hello.map"). The following command writes an
assembler listing, marks the module as authorized with #cmd("AC=1") and
writes a link map:

```
cc370 -O1 -o hello -Wa,-a=hello.lst -Wl,--ac,1 -Wl,--map,hello.map hello.c
```

== Return Codes <cc370-rc>

#idx("cc370", "return codes")#idx("return codes")
cc370 ends with return code 0 when every phase it ran succeeded, and with 1
as soon as one failed. A phase that fails ends the build: no later phase is
run, and the output file of the failing phase is not kept.

#idx("as370", "warnings under cc370")
as370 succeeds with return code 0 or 4. A warning, return code 4, is shown,
the object module is kept, and the build continues\; return code 8 and above
fail the build.

#tab(caption: [cc370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The build completed. Warnings from cc1, as370 and ld370 do not
      change the return code.],
    [1], [A phase failed: cc1 found an error, as370 ended with return code 8
      or higher, ld370 found an unresolved reference or another error, an
      input file was missing, or the command was refused (for example
      #cmd("-o") with #cmd("-c") and several sources, or an unknown
      #cmd("-flinker-output=") type).],
    [#var("rc")], [With #cmd("-pass-exit-codes"), the return code of the
      phase that failed, for example 8 for an as370 error.],
  )
] <cc370-rc-tab>

== Examples <cc370-examples>

@cc370-session builds UPCASE (@cc370-upcase-c) into a load module member and
a TRANSMIT file, and examines both with file370.

#fig(caption: [Building a load module and a TRANSMIT file])[
  #screen(raw(read("../ex/cc370/session.txt")))
] <cc370-session>

The TRANSMIT file names the data set #cmd("IBMUSER.HOST.LOAD"), which is
ld370's default\; #cmd("-Wl,--dsn,")#var("data-set-name") records another
one. The member name #cmd("UPCASE") comes from #cmd("-o upcase").

@cc370-errors shows three messages described in this chapter: two external
names defined in one source that collide, a definition that collides with a
reference (@cc370-names), and a character that has no image in code page
037 (@cc370-charset).

#fig(caption: [Collisions of external names and a character outside
  Latin-1])[
  #screen(raw(read("../ex/cc370/errors.txt")))
] <cc370-errors>
