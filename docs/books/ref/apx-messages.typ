#import "../bookmaster/bookmaster.typ": *

// cmd() and var() set their text in a box, which cannot break; message texts
// are longer than a line, so this appendix uses the same faces unboxed.
#let mc(x) = text(font: mono-font, weight: "bold", size: 0.88em, hyphenate: false, x)
#let mv(x) = text(font: mono-font, style: "italic", size: 0.88em, hyphenate: false, x)

// One message: the text as the tool writes it, then what it means and what to
// do.  Variables in the text are set with mv().
#let msg(text-line, explanation, response) = block(above: 1.3em, below: 0.6em, breakable: true, {
  block(below: 0.55em, sticky: true, { set par(justify: false); text-line })
  pad(left: 0.3in, {
    block(below: 0.45em)[*Explanation:* #explanation]
    block(below: 0em)[*User Response:* #response]
  })
})

= Messages and Return Codes <apx-messages>

#idx("messages")#idx("return codes", "summary")
This appendix lists the return codes of the nine commands of the toolchain
and the messages that each of them writes. It is arranged by command, in the
order of the chapters.

Every message is written to standard error. A message written by the
command itself begins with the name of the command and a colon, for example
#mc("ld370:")\; a warning continues with #mc("warning:"). A message about a
file that could not be opened, read or written usually consists of the file
name, a colon, and the reason given by the host system, with no command name
in front, for example #mc("nosuch.o: No such file or directory"). ld370
writes such messages with its name, as
#mc("ld370: cannot open ")#mv("file")#mc(": ")#mv("reason"), and so does
as370 for the object module (#mc("as370: cannot write ")#mv("file")). Such messages are not listed
one by one; each command has one entry for them.

In the message texts, #mv("variable") marks the part that changes from one
occurrence to the next: a file name, a symbol, a number.

Every command takes #mc("-V") or #mc("--version"), which writes the
version, and #mc("-h") or #mc("--help"), which writes a summary of the
options; both end with return code 0 and ignore any other operands, so
nothing else is done. Where a command has #mc("-v"), it asks
for more detail and never for the version\; for cc370 it is the verbose
option of the GNU C driver (see @cc370-invoke). The lines it adds are not
messages and are not listed here: as370 names the source, each directory of
the macro search (with #mc("(absent)") after one that does not exist) and
each macro read from a library, and writes its summary line even when
nothing is flagged\; dasm370 names the section read, with its origin,
length and RLD and LD entries\; ld370 writes trace lines beginning
#mc("[ld370]")\; #mc("ar370 rcv") lists each member, as #mc("a - ")#mv("file"),
on standard output.

Not listed are the messages that report an exhausted host resource
(#mc("out of memory") and the like) and those that report an internal
inconsistency of the program. They end the command with an error code; the
response is to report the problem.

== Return Code Summary <apx-messages-rc>

#idx("return codes", "conventions")
Two conventions are in use. cc370, ld370, ar370, file370, xmit370, cmplmd370
and idrdump370 follow the convention of host commands: 0 for success, 1 or 2
for failure. as370 and dasm370 follow the convention of the MVS assembler: the
return code is a severity, 4 for a warning, 8 for an error, and so on.
@apx-messages-rc1 to @apx-messages-rc3 summarize the codes; the chapter of
each command describes them in full.

#tab(caption: [Return codes (part 1 of 3)])[
  #table(columns: (0.95in, 0.45in, 1fr),
    [Command], [Code], [Meaning],
    [cc370], [0], [The build completed. Warnings, among them an as370
      return code of 4, do not change the code.],
    [], [1], [A phase failed: cc1 found an error, as370 ended with 8 or
      higher, ld370 failed, an input file is missing, or the command was
      refused. The output of the failing phase is not kept.],
    [], [#mv("rc")], [With #mc("-pass-exit-codes"): the code of the phase
      that failed.],
    [as370], [0], [No statement was flagged.],
    [], [2], [The assembly stopped at a capacity limit (see
      @apx-messages-as370-cmd). No object module is written.],
    [], [4], [Warnings only. The object module is complete.],
    [], [8], [Errors. The object module is written but is not expected to
      run.],
    [], [12], [Severe errors.],
    [], [16], [The source or an output file could not be opened, or the
      command line was in error. No object module is written, except when
      only #mc("--sym="), #mc("--stmts=") or #mc("--usings=") failed\; on a
      wrong command line the assembly still runs and reports its
      messages.],
  )
] <apx-messages-rc1>

#tab(caption: [Return codes (part 2 of 3)])[
  #table(columns: (0.95in, 0.45in, 1fr),
    [Command], [Code], [Meaning],
    [ld370], [0], [The module or transport file was written. Warnings also end
      with 0.],
    [], [1], [A file or the link failed: an input that cannot be read or is
      not an object module, a library or member not found, an unresolved
      reference, an output that cannot be written.],
    [], [2], [The command line is wrong, whatever the files hold: an
      unknown option, options that do not go together, a name used twice in
      a library, a #mc("--pack") input that is not a load module. Nothing
      was written.],
    [ar370], [0], [The library was written or listed.],
    [], [1], [A file could not be read or written, or is of the wrong
      kind.],
    [], [2], [Too few operands, or an unknown operation.],
    [file370], [0], [Every file was recognized or was empty.],
    [], [1], [A file could not be read.],
    [], [2], [A file was not recognized, an option was unknown, or no file
      was named.],
  )
] <apx-messages-rc2>

#tab(caption: [Return codes (part 3 of 3)])[
  #table(columns: (0.95in, 0.45in, 1fr),
    [Command], [Code], [Meaning],
    [xmit370], [0], [The subcommand completed.],
    [], [1], [A file or directory could not be read or is not a
      transmission, a name or a line was refused, or #mc("extract") could
      not write a member.],
    [], [2], [The command was in error and nothing was done, or the
      transmission could not be written.],
    [dasm370], [0], [The output was written.],
    [], [2], [No operands were given, the section named by #mc("--csect")
      is not in the module or is a common section, or the input is
      incomplete.],
    [], [4], [The output was written, with a warning.],
    [], [16], [The command was in error, a file could not be opened or is
      not an object module or a load module, or a hint file was refused.],
    [cmplmd370], [0], [Every compared section is identical.],
    [], [1], [At least one section differs.],
    [], [2], [The comparison could not be made.],
    [idrdump370], [0], [At least one IDR was displayed.],
    [], [1], [The load module holds no IDR.],
    [], [2], [The command was in error, or the file could not be read or is
      not a load module.],
  )
] <apx-messages-rc3>

== cc370 Messages <apx-messages-cc370>

#idx("cc370", "messages")
cc370 runs cc1, as370 and ld370 in turn (see @cc370-phases). The messages of
as370 and ld370 reach the terminal unchanged and are described under those
commands\; an as370 warning, return code 4, does not end the build. cc1 reports a problem in the C source in the form

#screen[#mv("file")#mc(":")#mv("line")#mc(": error: ")#mv("text") \
#mv("file")#mc(":")#mv("line")#mc(": warning: ")#mv("text")]

These are the diagnostics of the GNU C compiler, version 3.4.6, on which cc1
is based; they are not listed here. An error ends the build with return code
1, a warning does not. The entries below are the messages that cc370 adds for
MVS, and those of the driver itself.

#msg[#mc("cc370: no input files")][
  No source, assembler or object file was named, or none of those named
  exists. Return code 1.
][Name at least one input file.]

#msg[#mc("cc370: ")#mv("file")#mc(": No such file or directory")][
  An input file does not exist. It is followed by
  #mc("cc370: no input files") when it was the only one. Return code 1.
][Correct the file name.]

#msg[#mc("cc370: `-b' selects another compiler version or target in GCC; cc370 has one of each") \
#mc("cc370: `-V' selects another compiler version or target in GCC; cc370 has one of each")][
  The GNU C driver option #mc("-b")#mv("machine") or #mc("-V")#mv("version")
  was given. cc370 is a single compiler for a single target, so the command
  is refused before any phase runs. #mc("-V") on its own is the version
  option. Return code 1.
][Remove the option.]

#msg[#mc("cc370: cannot specify -o with -c or -S and multiple files")][
  #mc("-o") was given with #mc("-c") or #mc("-S") and more than one source.
  Nothing is compiled. Return code 1.
][Leave out #mc("-o"), so that each source gets an output file of its own,
  or compile one source per command.]

#msg[#mc("cc370: -flinker-output= takes xmit or iebcopy, not \"")#mv("type")#mc("\"")][
  The value of #mc("-flinker-output=") is neither #mc("xmit") nor
  #mc("iebcopy"). The command is refused before any phase runs, also when it
  would not link. Return code 1.
][Write #mc("-flinker-output=xmit") or #mc("-flinker-output=iebcopy").]

#msg[#mc("cc1: error: unrecognized command line option \"")#mv("option")#mc("\"")][
  cc1 does not know the option. An option written #mc("--")#mv("name") is
  shown as #mc("-f")#mv("name"). Return code 1.
][Correct the option. Options for as370 and ld370 are passed with
  #mc("-Wa,") and #mc("-Wl,"); see @cc370-passthru.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: external symbol `")#mv("name1")#mc("' collides with `")#mv("name2")#mc("': both map to the MVS name `")#mv("mvsname")#mc("'")][
  Two external names of one source file become the same name of at most
  eight characters on MVS (see @cc370-names). The names may be defined or
  only referenced. The compilation continues. When both are defined, as370
  then rejects the second definition with IFO196, and the build fails\;
  otherwise the build completes, and the references reach whatever has that
  name.
][Rename one of the two, make it #mc("static"), or give it an #mc("asm")
  label.]

#msg[#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": character U+")#mv("xxxx")#mc(" has no equivalent in the execution character set (ISO-8859-1, mapped to EBCDIC)")][
  A string literal or character constant contains a character above
  U+00FF, which has no place in the code page of the target (see
  @cc370-charset). The message is an error; return code 1.
][Replace the character, or write the byte wanted as an escape,
  #mc("\\x")#mv("hh").]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: #pragma map is not implemented; `")#mv("name")#mc("' keeps its derived external name -- declare it with __asm__(\"NAME\") instead")][
  The source contains #mc("#pragma map"). cc370 does not implement it: the
  function or variable #mv("name") keeps the external name made from its C
  name (see @cc370-names).
][Remove the pragma and declare the name with an #mc("asm") label, as
  #mc("extern int f(void) asm(\"NAME\");").]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: #pragma linkage has no effect: `")#mv("name")#mc("' is called with cc370's own linkage")][
  The source, or a header it includes from outside the sysroot, contains
  #mc("#pragma linkage"). Calls of #mv("name") use the ordinary cc370
  linkage, a parameter list addressed by register 1. Older libc370
  headers carried the pragma\; installed in the sysroot they are system
  headers, and the warning is not shown.
][Remove the pragma from your source.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: weak definition of '")#mv("name")#mc("' is an ordinary definition on MVS; only a weak reference (WXTRN) exists [-Wweak-definition]")][
  A function or variable is defined with #mc("__attribute__((weak))"). MVS
  has weak references only (see @cc370-weak): the definition is compiled as
  an ordinary one and the name is external. The compilation continues.
][Remove the attribute from the definition. Declare the name weak only
  where it is referenced. #mc("-Wno-weak-definition") turns the warning off.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: '")#mv("name")#mc("' is writable data in a reentrant module [-Wwritable-data]")][
  Under #mc("-mrent"), #mv("name") is a global or #mc("static") variable
  that is not #mc("const"). The load module keeps it in itself, so in a
  reentrant module every task that uses the module shares it (see
  @cc370-target). The compilation continues.
][Make the variable #mc("const"), move it into storage the program
  obtains for each task, or do not mark the module reentrant.
  #mc("-Wno-writable-data") turns the warning off.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: -fwritable-strings puts writable string literals into a reentrant module [-Wwritable-data]")][
  #mc("-mrent") and #mc("-fwritable-strings") are given together. The
  string literals are then writable storage in the module, shared by every
  task that uses it. The message appears once per compilation.
][Leave out #mc("-fwritable-strings").]

#msg[#mc("cc1: error: invalid option `")#mv("name")#mc("'")][
  #mc("-m")#mv("name") is not a target option of cc370 (see @cc370-target).
  #mc("-mpickax") and #mc("-mno-pickax") of earlier releases give this
  message. Return code 1.
][Remove the option.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: malformed #pragma ")#mv("name")#mc(", ignored")][
  A #mc("#pragma map"), #mc("#pragma linkage") or #mc("#pragma checkout")
  could not be parsed. The pragma has no effect.
][Correct the pragma.]

#msg[#mv("file")#mc(":")#mv("line")#mc(": warning: junk at end of #pragma ")#mv("name")][
  A #mc("#pragma map"), #mc("#pragma linkage") or #mc("#pragma checkout")
  is followed by further text on the same line. The pragma is processed; the
  text is ignored.
][Remove the text after the closing parenthesis.]

== as370 Messages <apx-messages-as370>

#idx("as370", "messages")
as370 reports a statement in error with two lines on standard error: the
statement as it was read, and the message. The message begins with
#mc("ERROR:"), as a rule for severity 8 and above, or with #mc("WARNING:")
below 8\; a lost continuation card is an #mc("ERROR:") at severity 4
(@apx-messages-as370-cont), and an #mc("MNOTE") of severity 0 prints
#mc("NOTE:"). The message ends with #mc("in line ")#mv("n"), the line of
the source file, and some messages then add #mc(" - ") and the operation,
symbol or text concerned. When the statement was generated by a macro or
brought in by #mc("COPY"), the line is that of the macro instruction or
#mc("COPY") statement. Whenever the number the statement has in the listing
differs from the line -- after a macro expansion this holds for the open
code that follows as well -- the line is followed by
#mc("(statement ")#mv("m")#mc(")"). The statements are reported in source order. The assembly ends
with a summary line

#screen[#mc(" Assembler Done   ")#mv("n")#mc(" Statements Flagged / ")#mv("sev")#mc(" was Highest Severity")]

and the return code is #mv("sev"). An assembly without flagged statements
writes nothing at all, unless #mc("-v") is given. @apx-messages-as370-fig shows an example.

#fig(caption: [Messages of an as370 assembly])[
  #screen(raw(read("../ex/apx-messages/as370-diag.txt")))
] <apx-messages-as370-fig>

=== Messages with an IFOX00 Number <apx-messages-ifo>

#idx("IFOX00", "message numbers")
Where IFOX00 has a message for the same condition, as370 gives its number in
parentheses, as #mc("(IFOX00 IFO")#mv("nnn")#mc(")"), and uses its
severity. @apx-messages-ifo1 and @apx-messages-ifo2 list them. In
the tables, the number is left out of the text; where the text ends in
#mc("- ")#mv("x"), the symbol or operand #mv("x") follows the number in
the message as printed.

#tab(caption: [as370 messages with an IFOX00 number (part 1 of 2)])[
  #set par(justify: false)
  #table(columns: (0.72in, 0.35in, 1fr),
    [Number], [Sev], [Message text],
    [IFO006], [8], [#mv("&var")#mc(" is an undefined variable symbol - nothing declares it")],
    [IFO007], [8], [#mc("Usage of ")#mv("&var")#mc(" is inconsistent with its declaration - it is subscripted and nothing declares a dimension")],
    [IFO012], [8], [#mc("ICTL or OPSYN statement appears too late in the program") \ #mc("ICTL statement appears too late in the program")],
    [IFO013], [8], [#mc("OPSYN name field not an ordinary symbol")],
    [IFO014], [8], [#mc("Invalid opcode in OPSYN operand")],
    [IFO025], [4], [#mc("Statement out of sequence") (#mc("ISEQ"))],
    [IFO026], [4], [Continuation card in error; see @apx-messages-as370-cont.],
    [IFO042], [8], [#mc("parameter in macro prototype or macro instruction exceeds 255 characters")],
    [IFO043], [8], [#mc("Macro prototype statement has invalid op code - ")#mv("x")],
    [IFO068], [8], [#mc("COPY member ")#mv("name")#mc(" not found in library")],
    [IFO069], [4], [#mc("Too many continuation cards, two allowed")],
    [IFO080], [4], [#mc("attribute reference to undefined symbol ")#mv("sym")],
    [IFO085], [8], [#mc("Macro header missing, macro not expandable")],
    [IFO092], [8], [#mc("keyword parameter ")#mv("kw")#mc(" is not declared in the macro prototype")],
    [IFO104], [4], [#mc("More than one TITLE statement named")],
    [IFO115], [8], [#mc("first expression in substring notation has zero or negative value")],
    [IFO116], [4], [#mc("second expression in substring notation has negative value")],
    [IFO117], [8], [#mc("first expression in substring notation exceeds the length of the string")],
    [IFO118], [8], [#mc("The ACTR limit has been exceeded - conditional assembly terminated")],
    [IFO120], [4], [#mc("illegal length attribute reference") \ #mc("illegal length attribute reference - the length of an EQU symbol is defaulted")],
    [IFO123], [4], [#mc("illegal scale attribute reference")],
    [IFO124], [4], [#mc("illegal integer attribute reference")],
    [IFO158], [8], [#mc("DSECT symbol ")#mv("sym")#mc(" used in a relocatable address constant")],
    [IFO161], [8], [#mc("Literal combined with another term (... instruction zeroed) - ")#mv("x")],
    [IFO165], [4], [#mc("Null PUNCH operand or PUNCH operand exceeds 80 characters")],
    [IFO168], [8], [#mc("An arithmetic expression not used in conditional assembly contains more than 20 terms")],
    [IFO169], [8], [#mc("Invalid self-defining term")],
    [IFO171], [4], [#mc("TITLE statement operand exceeds 100 characters")],
  )
] <apx-messages-ifo1>

#tab(caption: [as370 messages with an IFOX00 number (part 2 of 2)])[
  #set par(justify: false)
  #table(columns: (0.72in, 0.35in, 1fr),
    [Number], [Sev], [Message text],
    [IFO177], [12], [#mc("SRP needs a third operand, the rounding digit")],
    [IFO178], [8], [#mc("Syntax error in the MNOTE severity") \ #mc("Syntax error - the nominal value is empty") \ #mc("Syntax error - decimal constant has no nominal value") \ #mc("Syntax error - more than one decimal point in a decimal constant") \ #mc("SRP rounding digit must be absolute")],
    [IFO179], [8], [#mc("Length modifier must be absolute - nothing assembled")],
    [IFO189], [8], [#mc("Invalid ENTRY operand, linkage cannot be performed - ")#mv("sym")],
    [IFO195], [12], [#mc("Invalid USING or DROP statement - ")#mv("x")],
    [IFO196], [8], [#mc("Symbol previously defined - ")#mv("sym") \ #mc("A name declared EXTRN may not name a control section - ")#mv("sym")],
    [IFO200], [8], [#mc("Invalid scale modifier")],
    [IFO201], [8], [#mc("Illegal or invalid exponent modifier")],
    [IFO202], [8], [#mc("Arithmetic precision of floating-point constant lost")],
    [IFO203], [4], [#mc("L, D, E, F, H, or Y-type constant truncated, high order digits lost")],
    [IFO204], [8], [#mc("Relocatable expression in A- or Y-type address constant with the specified length not allowed")],
    [IFO205], [4], [#mc("Relocatable Y-type constant, value truncated to rightmost 2 bytes")],
    [IFO206], [8], [#mc("Duplication factor error - no storage reserved") \ #mc("Duplication factor error - the terms are not from one section") \ #mc("Negative duplication factor")],
    [IFO207], [8], [#mc("Operand of Q-type constant does not name a DSECT or DXD - ")#mv("sym")],
    [IFO211], [12], [#mc("too many operands")],
    [IFO213], [12], [#mc("Complexly relocatable expression (... instruction zeroed) - ")#mv("x")],
    [IFO217], [12], [#mc("Relocatable operand of a multiply or divide (... instruction zeroed) - ")#mv("x") \ #mc("USING base not absolute or simply relocatable - ")#mv("x") \ #mc("Relocatable duplication factor - an absolute expression is required")],
    [IFO220], [4], [#mc("Alignment error - ")#mv("op")#mc(" needs a ")#mv("n")#mc("-byte boundary and the operand resolves to x'")#mv("addr")#mc("'")],
    [IFO224], [8], [#mc("Length error - a packed-decimal constant may have at most 31 digits") \ #mc("Length error - a zoned-decimal constant may have at most 16 digits") \ #mc("Length error - a packed- or zoned-decimal constant may not exceed 16 bytes") \ #mc("SRP rounding digit is outside 0-9")],
    [IFO231], [8], [#mc("Symbol not previously defined - ")#mv("sym") \ #mc("Duplication factor uses a symbol not previously defined - ")#mv("sym") \ #mc("Length modifier uses a symbol not previously defined - ")#mv("sym")],
    [IFO233], [8], [#mc("More than 6 levels of parentheses")],
    [IFO234], [8], [#mc("Premature end of expression - the address constant has no value")],
    [IFO236], [8], [#mc("Illegal character in a decimal constant")],
    [IFO239], [8], [#mc("Invalid floating point characteristic")],
    [IFO242], [4], [#mc("SPACE operand not a single positive decimal self-defining term")],
    [IFO254], [4], [#mc("Illegal format of second operand of END statement")],
    [IFO255], [8], [#mc("Fixed or floating point expression error - the nominal value is empty")],
    [IFO258], [16], [Invalid option; see @apx-messages-as370-cmd.],
  )
] <apx-messages-ifo2>

The explanation of each of these conditions is that of the IFOX00 message
with the same number, and so is the response: correct the statement. Two
remarks apply to as370:

- IFO161, IFO213 and IFO217 in a machine instruction: the instruction is
  assembled as zeros, as IFOX00 does. It keeps its length, so the error does
  not move any later symbol.
- IFO158 is also issued for the name of an external dummy section
  (#mc("DXD")) in a 3- or 4-byte #mc("A")-type constant. IFO204 is issued
  for a relocatable #mc("A")-type constant of 1 or 2 bytes and a
  relocatable #mc("YL1"), in a literal as well\; the constant is assembled
  as zeros, without a relocation item.
- IFO206 and IFO179: no storage is reserved for the statement, so every
  later symbol of the section is placed differently from what the source
  intends.

=== Messages without an IFOX00 Number <apx-messages-as370-stmt>

The following messages report a statement that IFOX00 also rejects, in
words of as370's own, or a condition that as370 handles differently from
IFOX00. The severity is given with each.

#msg[#mc("ERROR: Undefined operation code in line ")#mv("n")#mc(" - ")#mv("op")][
  #mv("op") is neither an instruction, an assembler instruction, nor a
  macro defined in the source or found in a macro library. Severity 8.
][Check the spelling. If #mv("op") is a macro, check the library search
  (@as370-maclib): a directory that does not exist is skipped without a
  message, so a misspelled #mc("-I") shows up here.]

#msg[#mc("ERROR: Undefined symbol in line ")#mv("n")#mc(" - ")#mv("sym")][
  #mv("sym") is used and not defined anywhere in the assembly. Severity 8.
][Define the symbol, or declare it with #mc("EXTRN").]

#msg[#mc("ERROR: Addressability error - no active USING covers the operand's section (base and displacement set to 0) in line ")#mv("n")#mc(" - ")#mv("op")][
  An operand refers to a storage location that no #mc("USING") in effect
  covers. The base and displacement are assembled as zeros. Severity 8.
][Add or correct the #mc("USING") statement.]

#msg[#mc("ERROR: Relocatable displacement in machine instruction (explicit base requires an absolute displacement) in line ")#mv("n")#mc(" - ")#mv("op")][
  An operand names a base register explicitly, as in #mc("D(X,B)"), and the
  displacement is a relocatable expression. Severity 8.
][Write an absolute displacement, or omit the base register and let a
  #mc("USING") resolve the address.]

#msg[#mc("ERROR: Illegal operand format (index/length not allowed on RS/SI/S operand) in line ")#mv("n")#mc(" - ")#mv("op")][
  An RS, SI or S instruction has an operand with an index register or a
  length. Severity 12.
][Remove the index or length.]

#msg[#mc("ERROR: Invalid type declared on DC/DS/DXD constant in line ")#mv("n")#mc(" - ")#mv("c") \
#mc("ERROR: DC/DS/DXD operand has no constant type in line ")#mv("n")][
  The type letter #mv("c") is not a constant type of the assembler
  language, or the operand has no type at all, for example after a trailing
  comma that does not continue the statement. Severity 8.
][Correct the operand.]

#msg[#mc("ERROR: ")#mv("what")#mc(" is valid Assembler XF but not implemented by as370 - no storage reserved, every later symbol in the section would move, in line ")#mv("n")][
  The statement is correct for IFOX00, but as370 does not assemble it.
  #mv("what") is #mc("unnamed COM"), a #mc("COM") statement without a
  name. Nothing is reserved, so the section is shorter than IFOX00 would
  make it. Severity 8.
][Give the common section a name, or assemble the module with IFOX00.]

#msg[#mc("ERROR: OPSYN with a blank operand (deleting an operation code) is valid Assembler XF but not implemented by as370") \
#mc("ERROR: ICTL with columns other than 1,71,16 is valid Assembler XF but not implemented by as370 - the cards are read with the standard columns")][
  The statement is correct for IFOX00, but as370 does not carry it out.
  Severity 12.
][Remove the statement, and for #mc("ICTL") arrange the source in the
  standard columns.]

#msg[#mc("ERROR: Symbol longer than 8 characters (MVS external names are limited to 8) in line ")#mv("n")#mc(" - ")#mv("sym") \
#mc("ERROR: Symbol longer than 8 characters in name field (name rejected; MVS symbols are limited to 8) in line ")#mv("n")#mc(" - ")#mv("sym") \
#mc("ERROR: Symbol longer than 8 characters in operand expression (instruction zeroed; MVS symbols are limited to 8) in line ")#mv("n")#mc(" - ")#mv("op")][
  A symbol has more than eight characters: as an external name, in the name
  field, or in an operand. A name so rejected is not defined; an
  instruction that uses one is assembled as zeros. Severity 8.
][Shorten the symbol to eight characters.]

#msg[#mc("WARNING: Character U+")#mv("xxxx")#mc(" has no EBCDIC (CP037) equivalent - read as X'3F' in line ")#mv("n")][
  The source, or a library member (the text then ends
  #mc("in line ")#mv("n")#mc(" of library member ")#mv("name")), contains
  a character that the code page cannot represent (see @as370-encoding). The
  character is read as #mc("X'3F'")\; in an echoed statement it is shown as
  #mc("?"). These warnings are written before the statement messages.
  Severity 4.
][Replace the character.]

#msg[#mc("ERROR: Character with no EBCDIC equivalent in a constant - assembled as X'3F' (see the source-encoding warning) in line ")#mv("n")][
  Such a character stands in a constant, so it reaches the object module.
  Severity 8.
][Replace the character, or write the constant in hexadecimal.]

#msg[#mc("ERROR: MNOTE in line ")#mv("n")#mc(" - ")#mv("text") \
#mc("WARNING: MNOTE in line ")#mv("n")#mc(" - ")#mv("text") \
#mc("NOTE: MNOTE in line ")#mv("n")#mc(" - ")#mv("text")][
  A macro issued an #mc("MNOTE"). The severity is the one the macro gave:
  #mc("ERROR") for 8 and above, #mc("WARNING") for 1 to 7, #mc("NOTE")
  for an #mc("MNOTE") without a severity or with severity 0. It goes into
  the return code.
][Read the text; it is written by the author of the macro.]

#msg[#mc("ERROR: &SYSLIST is longer than the operand buffer - the tail is not addressable") \
#mc("ERROR: More than 255 positional macro operands - the rest are not addressable through &SYSLIST") \
#mc("ERROR: DC value list is longer than the operand buffer - the tail is dropped") \
#mc("ERROR: more than 128 values in one DC operand - the rest are dropped")][
  An operand exceeds a limit of as370. The part beyond the limit is not
  processed. Severity 8.
][Divide the macro instruction or the #mc("DC") statement.]

When more than 128 messages of one kind occur, the rest are not shown but
counted, in a line such as #mc("... and ")#mv("k")#mc(" further
undefined-symbol diagnostics"). They still count towards the summary line
and the return code.

=== Continuation Cards <apx-messages-as370-cont>

#idx("continuation", "messages")
A statement is continued when column 72 is not blank. The messages about
continuation cards are written before the statement messages. Each shows
the card in error and then the message, which ends with
#mc("in line ")#mv("n") or with
#mc("in line ")#mv("n")#mc(" of library member ")#mv("name").

#msg[#mc("ERROR: This card was consumed as a continuation and the statement on it discarded (IFOX00 IFO026, severity 4)")][
  The card above this one has a character in column 72, so this card was
  read as its continuation, and the statement written on it is lost. The
  card has characters in columns 1 to 15, so IFOX00 reports it with IFO026.
  Severity 4. With #mc("--strict-cont") the severity is 8, and the text
  ends #mc("--strict-cont raises it to 8)").
][Clear column 72 of the card above; it is typically a comment that runs
  into it.]

#msg[#mc("ERROR: This card was consumed as a continuation and the statement on it discarded (IFOX00 does not even warn here; the card's columns 1-15 are blank)")][
  As above, but columns 1 to 15 of the card are blank, and IFOX00 assembles
  it without a message. The message does not raise the return code unless
  #mc("--strict-cont") is given, which makes it severity 8.
][As above.]

#msg[#mc("WARNING: Characters appear between the begin and continue columns on a continuation card (IFOX00 IFO026)") \
#mc("WARNING: Continuation card is empty - nothing between the continue column and 71 (IFOX00 IFO026)") \
#mc("WARNING: Too many continuation cards, two allowed (IFOX00 IFO069)")][
  A continuation card has text before column 16, has nothing from column 16
  to 71, or follows two continuation cards already. Severity 4.
][Correct the continuation.]

=== Command Messages <apx-messages-as370-cmd>

#msg[#mv("file")#mc(": ")#mv("reason")][
  The source file could not be opened, or one of the output files
  #mc("--sym="), #mc("--stmts=") and #mc("--usings=") could not be
  written. Return code 16. When the source cannot be opened, nothing is
  assembled\; the object module is written before the other output files,
  so it exists when one of them fails.
][Correct the file name or the directory.]

#msg[#mc("as370: cannot write ")#mv("file")#mc(": ")#mv("reason")][
  The object module named with #mc("-o") could not be written. Return
  code 16.
][Correct the file name or the directory.]

#msg[#mc("as370: cannot write listing ")#mv("file")#mc(": ")#mv("reason")][
  The listing file named with #mc("-a=")#mv("file") cannot be written. It
  is checked as soon as the options are read. The assembly still runs and
  reports its messages, but no listing and no object module are written.
  Return code 16.
][Correct the file name or the directory.]

#msg[#mc("as370: invalid option '")#mv("option")#mc("' - option ignored (IFOX00 IFO258)")][
  The option is not known. It is ignored, as IFOX00 ignores an option it does
  not know, and the assembly is carried out and reports its messages, but
  *no object module is written*. Return code 16.
][Correct or remove the option.]

#msg[#mc("as370: more than one source file - '")#mv("file2")#mc("' ignored, assembling '")#mv("file1")#mc("'")][
  Two source files were named. The first is assembled and its messages
  reported, but no object module is written. Return code 16.
][Assemble one source file per call.]

#msg[#mc("as370: symbol table full") \
#mc("as370: literal table full") \
#mc("as370: reloc table full") \
#mc("as370: global variable-symbol table full (")#mv("n")#mc(")") \
#mc("as370: local SET-symbol table full (")#mv("n")#mc(")")][
  The source needs more entries than the table holds: 65,536 ordinary
  symbols, 65,536 literals, 131,072 relocation items, 1,024 global or 512
  local variable symbols. The assembly stops; no object module is written.
  Return code 2.
][Divide the source into several modules.]

#msg[#mc("as370: section location counter past 24 bits (")#mv("n")#mc(" > 16777216); a section cannot be addressed beyond 16MB")][
  A control section would grow beyond 16 megabytes, the limit of 24-bit
  addressing. The assembly stops; no object module is written. Return code
  2. A dummy section (#mc("DSECT")) is not subject to the limit.
][Correct the #mc("DS"), #mc("DC") or #mc("ORG") statement that makes the
  section so long.]

#msg[#mc("as370: library member ")#mv("name")#mc(" is longer than 16384 cards and was cut") \
#mc("as370: macro ")#mv("name")#mc(" is longer than ")#mv("n")#mc(" statements and was cut") \
#mc("as370: COPY member ")#mv("name")#mc(" is longer than ")#mv("n")#mc(" statements and was cut")][
  A library member is longer than as370 reads. The cards after the limit are
  not used. The message does not change the return code.
][Divide the member.]

#msg[#mc("as370: conditional expression too complex (over 95 terms or a 255-character term) - ")#mv("expr")][
  A conditional-assembly expression exceeds a limit of as370. The message
  does not change the return code.
][Simplify the expression.]

== ld370 Messages <apx-messages-ld370>

#idx("ld370", "messages")
ld370 ends with return code 2 when the command line is wrong, whatever the
files hold, and writes nothing\; with 1 when a file or the link failed\; a
warning or note does not change the return code (see @ld370-rc).

#msg[#mc("ld370: cannot open ")#mv("file")#mc(": ")#mv("reason") \
#mc("ld370: cannot read ")#mv("file")#mc(": ")#mv("reason") \
#mc("ld370: cannot write ")#mv("file")#mc(": ")#mv("reason")][
  An object module or library could not be read (first form), a file given
  to #mc("--pack") could not be read (second form), or an output file could
  not be written (third form). The load map and the transport files
  (#mv("out")#mc(".xmit"), #mv("out")#mc(".iebcopy")) are checked before
  the member is written, so when one of them cannot be written, no member
  file is left behind. Return code 1.
][Correct the file name or the directory.]

#msg[#mc("ld370: ")#mv("file")#mc(" is not an object deck (")#mv("reason")#mc(")") \
#mc("ld370: ")#mv("file")#mc(" is an archive; name it with .a, or link it with -l") \
#mc("ld370: ")#mv("file")#mc(" is a TSO transmission (XMIT), not an object deck")][
  A file named as an object module is not one. #mv("reason") is
  #mc("not a multiple of 80-byte cards"),
  #mc("a card does not begin X'02'") or #mc("no END card"). A library is
  recognized as one only by a name ending in #mc(".a"). Return code 1.
][Name object modules, and libraries with #mc(".a") or #mc("-l").]

#msg[#mc("ld370: ")#mv("file")#mc(": not an archive")][
  A file whose name ends in #mc(".a") is not a library written by ar370.
  Return code 1.
][Rebuild the library with ar370.]

#msg[#mc("ld370: more than 32 archives")][
  More than 32 libraries were given. Return code 2; nothing is written.
][Combine libraries with ar370.]

#msg[#mc("ld370: cannot find -l")#mv("name")][
  No file #mc("lib")#mv("name")#mc(".a") was found in the #mc("-L")
  directories or in the current directory (see @ld370-autocall). Only the
  #mc("-L") options that precede the #mc("-l") are searched. Return code 1.
][Correct the name, or add the directory with #mc("-L") ahead of the
  #mc("-l").]

#msg[#mc("ld370: --include '")#mv("name")#mc("' not found in any archive")][
  No member of the libraries defines #mv("name"). Return code 1.
][Correct the name, or name the library that defines it.]

#msg[#mc("ld370: unresolved external reference(s):") \
#mc("    ")#mv("name") \
#mc("ld370: ")#mv("n")#mc(" unresolved external(s) -- the module would S0C4 at runtime (each is a NULL adcon); add the defining object/archive, or pass --allow-unresolved to override")][
  The external names listed are referred to and defined nowhere. No module
  is written. Return code 1.
][Add the object module or library that defines each name.]

#msg[#mc("ld370: ")#mv("n")#mc(" unresolved external(s) left for the loader (--allow-unresolved)")][
  As above, but #mc("--allow-unresolved") was given. The module is written,
  with zeros in each address constant that refers to a listed name. Return
  code 0.
][Make sure that each name is resolved before the module runs.]

#msg[#mc("ld370: --entry symbol '")#mv("name")#mc("' not found or unresolved")][
  The entry point named with #mc("--entry") is not defined in the module.
  Return code 1.
][Correct the name; see @ld370-entry.]

#msg[#mc("ld370: '")#mv("name")#mc("' names two directory entries (a member or alias may appear only once in a library)")][
  Two packed members, or a member and an alias, have the same name. Return
  code 2; nothing is written.
][Rename one of them.]

#msg[#mc("ld370: --alias ")#mv("name")#mc(" is the member's own name") \
#mc("ld370: --alias ")#mv("name")#mc(" is given twice")][
  Return code 2; nothing is written.
][Remove the alias, or give it once.]

#msg[#mc("ld370: member '")#mv("name")#mc("' has a ")#mv("n")#mc("-byte block > --blocksize ")#mv("m")#mc("; rebuild it with a matching --blocksize")][
  A member given to #mc("--pack") was linked with a larger block size than
  the pack declares (see @ld370-blksize). Return code 1.
][Link the member again with the block size of the pack.]

#msg[#mc("ld370: cannot split member '")#mv("name")#mc("' (unknown record)")][
  A file given to #mc("--pack") looked like a load module, but holds a
  record that ld370 cannot place. Return code 1.
][Name a load module written by ld370 or IEWL, or its #mc(".iebcopy")
file.]

#msg[#mc("ld370: --pack: --entry ")#mv("name")#mc(" is not in the CESD of '")#mv("file")#mc("'") \
#mc("ld370: --pack: '")#mv("file")#mc("' names ")#mv("name")#mc(" ")#mv("n")#mc(" times in its CESD; the entry is ambiguous")][
  The entry point of a member file given to #mc("--pack") is taken from its
  CESD, by the #mc("--entry") name or #mc("@@CRT0") (see @ld370-pack). The
  name is not there, or is there more than once. Return code 1; nothing is
  written.
][Correct the name, or pack the #mc(".iebcopy") file of the module.]

#msg[#mc("ld370: module length ")#mv("n")#mc(" exceeds 24-bit addressing (")#mv("m")#mc("); the text records' load addresses would wrap")][
  The module would be longer than 16 megabytes. Return code 1.
][Divide the program.]

#msg[#mc("usage: ld370 ...")][
  No object module and no #mc("--include") was named. The usage text is
  written. Return code 2.
][Name the object modules to link.]

#msg[#mc("ld370: unknown option '")#mv("option")#mc("' (ld370 --help)") \
#mc("ld370: ")#mv("option")#mc(" needs a value") \
#mc("ld370: ")#mv("option")#mc(" takes a number, not '")#mv("value")#mc("'") \
#mc("ld370: --ac ")#mv("n")#mc(" out of range (0..255)")][
  The option is not known, its value is missing, or the value is not a
  number in the range. Return code 2.
][Correct the option; #mc("ld370 --help") lists them.]

#msg[#mc("ld370: --rent given with --norent; the two ask for opposite attributes and ld370 will not choose between them") \
#mc("ld370: --reus given with --noreus; ...")][
  Contradictory attributes were requested. Return code 2.
][Give one of the two options.]

#msg[#mc("ld370: --blocksize ")#mv("n")#mc(" out of range (1024..32740)")][
  Return code 2.
][Give a block size in the range.]

#msg[#mc("ld370: invalid alias name '")#mv("name")#mc("' (1-8 chars, letter or @#$ first, then letters/digits/@#$)") \
#mc("ld370: invalid member name '")#mv("name")#mc("' in --pack (1-8 chars, letter or @#$ first, then letters/digits/@#$)")][
  The name is not a valid member name. Return code 2.
][Correct the name.]

#msg[#mc("ld370: '")#mv("name")#mc("' (from -o) is not a valid MVS member name (1-8 chars, letter or @#$ first, then letters/digits/@#$); give --name") \
#mc("ld370: '")#mv("name")#mc("' (--name) is not a valid MVS member name (1-8 chars, letter or @#$ first, then letters/digits/@#$)")][
  The member name, taken from #mc("--name") or from the base name of the
  #mc("-o") file, is not a valid member name. It is checked only when the
  name is used: with #mc("-iebcopy"), #mc("-xmit") or #mc("--map"). Return
  code 2.
][Give a valid name with #mc("--name").]

#msg[#mc("ld370: cannot derive a valid MVS member name from '")#mv("file")#mc("' (got '")#mv("name")#mc("')")][
  A file given to #mc("--pack") without #mc("NAME=") has a base name that
  is not a valid member name. The next line shows the form to use. Return
  code 2.
][Write #mv("NAME")#mc("=")#mv("file").]

#msg[#mc("ld370: --xref adds the references to the load map; give --map FILE") \
#mc("ld370: --map applies to a link, not to --pack; a pack places no sections") \
#mc("ld370: --alias applies to a link, not to --pack; build the member with --alias and -iebcopy, and pack that -- its aliases come along") \
#mc("ld370: --name applies to a link, not to --pack; name a packed member as NAME=FILE") \
#mc("ld370: --include names a link input; --pack takes members only") \
#mc("ld370: --pack needs -o OUT (base name)")][
  The options do not go together. Return code 2.
][Correct the command as the message says.]

#msg[#mc("ld370: --pack: '")#mv("file")#mc("' is ")#mv("what")#mc(", not a load module; pack the member or its -iebcopy") \
#mc("ld370: --pack: '")#mv("file")#mc("' is not a load module")][
  A file given to #mc("--pack") is #mc("an object deck (link it first)"),
  #mc("an archive") or #mc("a TSO transmission (XMIT)") (first form), or
  any other file that is not a load module, a C source for example (second
  form). Return code 2; nothing is written.
][Link the object modules first, and pack the member or its
  #mc(".iebcopy") file.]

#msg[#mc("ld370: --pack: '")#mv("file")#mc("' is a multi-member unload; pass single-member -iebcopy files") \
#mc("ld370: --pack: '")#mv("file")#mc("' is a malformed unload")][
  A file given to #mc("--pack") is an unloaded library with several
  members, or could not be read as one. Return code 2.
][Pack the #mc(".iebcopy") file of each member.]

#msg[#mc("ld370: LDDATE must be YYDDD (e.g. 26223)") \
#mc("ld370: LDTIME must be HHMMSS (e.g. 220517)")][
  The environment variable that sets the date or time of the identification
  record has a wrong form (see @ld370-idr). Return code 2.
][Correct or unset the variable.]

The following are warnings and notes. The module is written and the return
code is 0.

#msg[#mc("ld370: note: CSECT ")#mv("name")#mc(" defined again in ")#mv("file")#mc("; the first definition is kept and this one dropped, as IEWL does")][
  Two object modules contain a control section of the same name. The text of
  the second is not placed in the module.
][Make sure that the first definition is the one intended, or remove the
  other.]

#msg[#mc("ld370: warning: '")#mv("name")#mc("' doubly defined: ")#mv("file")#mc(" defines it again (first definition kept)")][
  An entry point is defined in two object modules, or in a member that
  automatic library call or #mc("--include") brought in (the text then
  names the member and the library). The first definition is used. Two C
  names in different sources that agree in their first eight characters
  give this message too (see @cc370-names).
][Remove one of the definitions, or rename one of the C names.]

#msg[#mc("ld370: warning: '")#mv("name")#mc("' resolved from ")#mv("member")#mc(" in ")#mv("lib")#mc("; also defined by ")#mv("member2")#mc(" ...")][
  More than one library member defines #mv("name"). The text ends
  #mc("in the same archive (ignored)") or, with #mc("--warn-shadow"),
  #mc("(ignored, searched in archive order)").
][Make sure that the member chosen is the one intended.]

#msg[#mc("ld370: warning: adcon at ")#mv("addr")#mc(" points ")#mv("n")#mc(" bytes into CSECT '")#mv("name")#mc("' of ")#mv("source")#mc(", a duplicate that was dropped ...")][
  An address constant refers into a control section that was defined twice
  and whose second definition was dropped. It now points into the copy that
  was kept, which may hold something else at that offset.
][Remove the duplicate control section.]

#msg[#mc("ld370: warning: --alias has no effect without -iebcopy or -xmit; a bare member carries no directory") \
#mc("ld370: warning: --sparse-text is ignored by --pack; it shapes the text records of a link") \
#mc("ld370: warning: --allow-unresolved is ignored by --pack; a pack resolves nothing") \
#mc("ld370: warning: --warn-shadow is ignored by --pack; it reports archive members a link pulls")][
  The option has no effect in this command.
][Remove the option, or add #mc("-iebcopy") or #mc("-xmit").]

#msg[#mc("ld370: warning: --entry does not apply to '")#mv("file")#mc("'; a -iebcopy member keeps the entry its directory holds")][
  #mc("--entry") was given to #mc("--pack") together with a
  #mc(".iebcopy") file. The entry point in its directory is kept\; the
  option still applies to the member files of the same pack (see
  @ld370-pack).
][None, or remove the option.]

#msg[#mc("ld370: warning: '")#mv("file")#mc("' is a bare load module: packing ")#mv("NAME")#mc(" at entry ")#mv("addr")#mc(" (")#mv("source")#mc("), AC ")#mv("n")#mc(", ")#mv("attributes")][
  A member file without its directory entry was given to #mc("--pack") (see
  @ld370-pack). #mv("addr") is the entry point as six hexadecimal digits, and
  #mv("source") says where it came from: #mc("--entry"), #mc("@@CRT0"), or
  #mc("no @@CRT0 in its CESD"), in which case the entry point is 000000. The
  attributes are those of the pack command. A note with the commands to use
  follows.
][If the entry point is wrong, give #mc("--entry")\; better, link the member
with #mc("-iebcopy") and pack the #mc(".iebcopy") file.]

== ar370 Messages <apx-messages-ar370>

#idx("ar370", "messages")
#msg[#mv("file")#mc(": ")#mv("reason")][
  An object module or the library to be listed could not be read, or the
  library could not be written. Return code 1; no library is written.
][Correct the file name or the directory.]

#msg[#mc("ar370: ")#mv("file")#mc(" is not an object deck (")#mv("reason")#mc(")") \
#mc("ar370: ")#mv("file")#mc(" is an archive, not an object deck")][
  A file to be stored is not an object module. #mv("reason") is
  #mc("not a multiple of 80-byte cards"),
  #mc("a card does not begin X'02'") or #mc("no END card"). Return code 1;
  no library is written.
][Name object modules only.]

#msg[#mc("ar370: ")#mv("file")#mc(": member name longer than 63 characters")][
  The base name of the file cannot be a member name. Return code 1.
][Rename the file.]

#msg[#mc("ar370: ")#mv("file")#mc(": not an archive")][
  The file given to #mc("t") is not a library. Return code 1.
][Name a library written by ar370.]

#msg[#mc("ar370: unknown operation '")#mv("op")#mc("' (r, c, rc, cr or t)")][
  Return code 2.
][Give one of the operations listed.]

#msg[#mc("usage: ar370 rc ARCHIVE.a OBJ...  ...")][
  Fewer than two operands were given. Return code 2.
][Give the operation and the library.]

== file370 Messages <apx-messages-file370>

#idx("file370", "messages")
#msg[#mv("file")#mc(": ")#mv("reason")][
  The file could not be read. The other files are still examined. Return
  code 1.
][Correct the file name.]

#msg[#mv("file")#mc(": data (not a recognized cc370 toolchain format)")][
  Written to standard output, in place of the summary. The file is none of
  the formats of @file370-formats. Return code 2.
][None; the file is not one that file370 describes.]

#msg[#mv("file")#mc(": empty file")][
  Written to standard output. Return code 0.
][None.]

#msg[#mc(", WARNING: not a multiple of 80") \
#mc(", WARNING: not FB80 (size % 80 != 0)")][
  At the end of the summary line of an object module or of a transmission:
  its length is not a multiple of 80 bytes, so it is incomplete or was
  transferred in a way that added or removed bytes. The return code is not
  changed.
][Transfer the file again in binary.]

#msg[#mc("file370: unknown option '")#mv("option")#mc("'")][
  The usage text follows. Return code 2.
][Correct the option.]

== xmit370 Messages <apx-messages-xmit370>

#idx("xmit370", "messages")
#mc("create") checks every member before it writes anything. Each line it
refuses is reported with the file, line and column, and the command ends
with a count of the errors.

#msg[#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": tab character (use --tabs N to expand)") \
#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": byte 0x")#mv("xx")#mc(" is outside ASCII (pass --latin1 to map it through CP037)") \
#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": file is UTF-8; this character has no EBCDIC equivalent -- use plain ASCII here") \
#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": control character 0x")#mv("xx")#mc(" in a text member (binary content cannot be a fixed-length text member)") \
#mv("file")#mc(":")#mv("line")#mc(":")#mv("col")#mc(": line is ")#mv("n")#mc(" columns, exceeds LRECL ")#mv("lrecl")][
  A line of a member cannot be made into a record (see @xmit370-refused).
  Eight such messages are shown for each file; the rest are counted in a
  line #mv("file")#mc(": ... and ")#mv("n")#mc(" more error(s)").
][Correct the file, or give #mc("--tabs"), #mc("--latin1") or
  #mc("--lrecl").]

#msg[#mc("xmit370: ")#mv("n")#mc(" error(s), no output written")][
  Follows the messages above. Return code 1.
][Correct the members and repeat the command.]

#msg[#mc("xmit370: ")#mv("path")#mc(": '")#mv("name")#mc("' is not a valid member name (1-8 of A-Z 0-9 @ # $, first not a digit); use --member NAME=")#mv("path")][
  A file of the directory has a name that cannot be a member name, for
  example one longer than eight characters. Return code 1; no transmission
  is written.
][Rename the file, or map it with #mc("--member").]

#msg[#mc("xmit370: ")#mv("path")#mc(": subdirectories are not members, skipped")][
  The directory contains a subdirectory. It is not included; the return code
  is not changed by it.
][None, or move the subdirectory out.]

#msg[#mc("xmit370: ")#mv("dir")#mc(": cannot open directory") \
#mc("xmit370: ")#mv("path")#mc(": cannot stat") \
#mc("xmit370: ")#mv("path")#mc(": cannot read")][
  The directory, a file in it or named by #mc("--member"), or the
  transmission given to #mc("list") or #mc("extract") could not be read.
  Return code 1.
][Correct the name.]

#msg[#mc("xmit370: ")#mv("path")#mc(": cannot write")][
  For #mc("create"), the transmission could not be written; return code 2.
  For #mc("extract"), a member could not be written; the other members are
  still extracted, and the return code is 1.
][Correct the output name or directory.]

#msg[#mc("xmit370: warning: '")#mv("name")#mc("' is not a standard member name (A-Z 0-9 @ # $); ISPF and TSO may not handle it")][
  A name given with #mc("--member") contains characters outside the usual
  set. The name is shown, and the member written, in capitals.
][Use a standard name unless the other name is intended.]

#msg[#mc("xmit370: ")#mv("path")#mc(": warning: the file is UTF-8, and --latin1 maps each of its bytes on its own; its non-ASCII characters will not survive")][
  #mc("--latin1") was given and a member file is valid UTF-8 with characters
  above ASCII. Each byte is translated as a Latin-1 character, so every such
  character becomes two or three wrong ones. The return code is not
  changed.
][Remove #mc("--latin1") and replace the characters, or convert the file to
  Latin-1.]

#msg[#mc("xmit370: ")#mv("path")#mc(": not a TSO transmission (it does not begin with INMR01)")][
  The file given to #mc("list") or #mc("extract") is not a transmission.
  Return code 1.
][Name a transmission file.]

#msg[#mc("xmit370: ")#mv("path")#mc(": warning: not a multiple of 80 bytes")][
  Written by #mc("list"): the transmission does not consist of whole 80-byte
  records. The listing continues.
][Transfer the file again in binary.]

#msg[#mc("xmit370: ")#mv("path")#mc(": not an IEBCOPY unload payload")][
  Written by #mc("extract"): the transmission does not contain an unloaded
  library. Return code 1.
][None; the transmission holds no members to extract.]

#msg[#mc("xmit370: create: -o OUT.xmit is required") \
#mc("xmit370: create: --dsn NAME is required") \
#mc("xmit370: list: need a file") \
#mc("xmit370: extract: need a file") \
#mc("xmit370: unexpected argument '")#mv("arg")#mc("'")][
  An operand is missing, or there is one too many. Return code 2.
][Correct the command.]

#msg[#mc("xmit370: --lrecl ")#mv("n")#mc(" out of range (1..32760)") \
#mc("xmit370: --blocksize ")#mv("n")#mc(" out of range (")#mv("lrecl")#mc("..32760)") \
#mc("xmit370: --blocksize ")#mv("n")#mc(" is not a multiple of --lrecl ")#mv("lrecl") \
#mc("xmit370: --blocksize ")#mv("n")#mc(" exceeds 19069, the largest block that fits one track") \
#mc("xmit370: --recfm f is unblocked: --blocksize must equal --lrecl (")#mv("lrecl")#mc("), not ")#mv("n")][
  The record length or block size cannot be used. Return code 2.
][Correct the value.]

#msg[#mc("xmit370: --member: '")#mv("name")#mc("' is ")#mv("n")#mc(" characters, a member name is 1-8") \
#mc("xmit370: --member: expected NAME=FILE, got '")#mv("arg")#mc("'") \
#mc("xmit370: --stats-date: '")#mv("arg")#mc("' is not a date YYYY-MM-DD[THH:MM:SS] between 1900 and 2099") \
#mc("xmit370: --userid '")#mv("x")#mc("' is ")#mv("n")#mc(" characters, a userid is 1-8") \
#mc("xmit370: ")#mv("option")#mc(" takes a number, not '")#mv("value")#mc("'") \
#mc("xmit370: ")#mv("option")#mc(" needs a value") \
#mc("xmit370: --recfm: only 'f' and 'fb' are supported")][
  The value of the option is missing or not valid. Return code 2.
][Correct the value.]

#msg[#mc("xmit370: duplicate member name ")#mv("name")#mc(" (")#mv("path1")#mc(" and ")#mv("path2")#mc(")") \
#mc("xmit370: no members found")][
  Two files would become the same member, or there is no member at all.
  Return code 2.
][Rename or exclude one of the files, or name a directory that contains
  files.]

#msg[#mc("xmit370: ")#mv("option")#mc(" does not apply to '")#mv("command")#mc("' (xmit370 --help)")][
  The option belongs to another subcommand, for example #mc("--dsn") given
  to #mc("list"). Return code 2.
][Remove the option.]

#msg[#mc("xmit370: unknown option '")#mv("option")#mc("'") \
#mc("xmit370: unknown command '")#mv("command")#mc("'")][
  The usage text follows. Return code 2.
][Correct the command.]

== dasm370 Messages <apx-messages-dasm370>

#idx("dasm370", "messages")

=== Messages about the Input <apx-messages-dasm370-input>

#msg[#mv("file")#mc(": ")#mv("reason")][
  The input, a hint file, a statement file, or an output file could not be
  opened. Return code 16.
][Correct the file name.]

#msg[#mc("dasm370: ")#mv("file")#mc(" has ")#mv("n")#mc(" control sections; disassembling the first, ")#mv("name")#mc(" (")#mv("len")#mc(" bytes) -- choose another with --csect NAME:")][
  The module has more than one control section; the lines that follow list
  them. The return code is 0, or 4 when the text begins #mc("WARNING:"),
  which it does when the first section is empty and another is not.
][Select a section with #mc("--csect").]

#msg[#mc("dasm370: no section named ")#mv("name")#mc(" in ")#mv("file")#mc("; it holds ")#mv("list") \
#mc("dasm370: ")#mv("name")#mc(" is an ENTRY POINT in ")#mv("file")#mc(", not a control section; its section is ")#mv("sect")#mc(" -- try --csect ")#mv("sect") \
#mc("dasm370: ")#mv("name")#mc(" is an ENTRY POINT (LR) in ")#mv("file")#mc(", not a control section") \
#mc("dasm370: ")#mv("name")#mc(" is a COMMON section in ")#mv("file")#mc("; it holds no text to disassemble") \
#mc("dasm370: ")#mv("name")#mc(" is in ")#mv("file")#mc(" only as a DELETED (null) CESD entry, not a control section") \
#mc("dasm370: ")#mv("name")#mc(" is in ")#mv("file")#mc(" as a ")#mv("type")#mc(" entry, not a control section")][
  The name given with #mc("--csect") is not a control section of the
  module that has text. A common section holds none. Return code 2.
][Give the name of a control section.]

#msg[#mc("dasm370: the image is incomplete (")#mv("anomaly")#mc("); --allow-incomplete to read it anyway")][
  A load module member ends before its last record. Return code 2.
][Obtain a complete copy of the member, or give #mc("--allow-incomplete").]

#msg[#mc("dasm370: ")#mv("file")#mc(" is not an object deck or a load module")][
  The input is neither an object module nor a load module member, for
  example a source file or an #mc(".iebcopy") or #mc(".xmit") file.
  Return code 16.
][Give the object module, or the member that ld370 wrote with #mc("-o").]

#msg[#mc("dasm370: ")#mv("name")#mc(" is ")#mv("n")#mc(" bytes, over the ")#mv("max")#mc(" this build holds")][
  The control section is longer than dasm370 can hold. Return code 16.
][None.]

#msg[#mc("dasm370: ")#mv("name")#mc(": TXT reaches ")#mv("addr")#mc(", past the ESD length ")#mv("len")][
  The object module carries text beyond the length that its ESD gives the
  section. The disassembly is written, and the return code is not changed.
][Check how the object module was produced.]

=== Messages about the Command <apx-messages-dasm370-cmd>

All of these end dasm370 with return code 16, and nothing is written.
Called with no operands at all, dasm370 writes the summary of its options to
standard error and ends with return code 2.

#msg[#mc("dasm370: invalid option '")#mv("option")#mc("'") \
#mc("dasm370: more than one input file") \
#mc("dasm370: too many -I directories for this build")][
  The command line is in error.
][Correct the command.]

#msg[#mc("dasm370: --labels ")#mv("v")#mc(" is not displacement or sequential") \
#mc("dasm370: --isa ")#mv("v")#mc(" is not one of app|s370|s360|full") \
#mc("dasm370: --format ")#mv("v")#mc(" is not card or free") \
#mc("dasm370: --anchors=")#mv("v")#mc(" is not report or refuse") \
#mc("dasm370: --reach=")#mv("v")#mc(" is not none|r15|balr|rld|lr|both|bothlr|acon|all")][
  The value of the option is not one of those listed.
][Give one of the values listed.]

#msg[#mc("dasm370: --isa s360 is not implemented: MVS 3.8j code uses the S/370") \
#mc("dasm370: --reach is not implemented: applied, it would turn more real") \
#mc("dasm370: --stmts is as370's option for WRITING the export; dasm370 reads one")][
  The option is refused. Further lines explain why and what to use.
][Use #mc("--isa app"), #mc("s370") or #mc("full"), #mc("--reach-report"),
  or #mc("--ref-stmts") and #mc("--cand-stmts").]

#msg[#mc("dasm370: --derive-hints takes a source and assembles its own deck; do not also give one") \
#mc("dasm370: --infer reads a module and --derive-hints a source; they are two ways to produce one file, not two halves of one") \
#mc("dasm370: --derive-hints writes a hint file; it does not read one") \
#mc("dasm370: --align-diff takes two objects, a reference and a candidate") \
#mc("dasm370: --align-diff already names both objects; do not give a third") \
#mc("dasm370: --align-diff compares two objects; it neither reads nor writes a hint file") \
#mc("dasm370: a statement export fills the `source' field of --json;") \
#mc("dasm370: --ref-stmts/--cand-stmts name the sources of the two objects --align-diff compares;") \
#mc("dasm370: --json is the repair contract for --align-diff; it has nothing to describe without one")][
  The options given do not go together, as the text says. See
  @dasm370-derive and @dasm370-align.
][Correct the command.]

=== Messages of Hint Derivation and Comparison <apx-messages-dasm370-run>

#msg[#mc("dasm370: as370 ended rc ")#mv("rc")#mc(" on ")#mv("source")#mc(" -- a hint set from a failed assembly cannot be told from one from a clean run")][
  #mc("--derive-hints") assembles the source with as370, and as370 did not
  end with 0. The lines that follow #mc("dasm370: as370 said:") are the
  messages of as370. No hint file is written. Return code 16.
][Correct the source until as370 ends with 0.]

#msg[#mc("dasm370: could not run ")#mv("as370") \
#mc("dasm370: as370 printed nothing -- check that '")#mv("as370")#mc("' is the")][
  The as370 program could not be started, or failed without a message.
  Return code 16.
][Name the right program with #mc("--as370").]

#msg[#mc("dasm370: ")#mv("file")#mc(": no #columns header -- not an as370 export") \
#mc("dasm370: ")#mv("file")#mc(": the export is missing a column this needs") \
#mc("dasm370: ")#mv("file")#mc(" is not an as370 --stmts export -- its first line is") \
#mc("dasm370: ")#mv("file")#mc(" is as370-stmts version ")#mv("v")#mc("; this build reads 1") \
#mc("dasm370: ")#mv("file")#mc(" is missing a column this needs -- it has") \
#mc("dasm370: ")#mv("file")#mc(" has no statement in section ")#mv("name")#mc(".")][
  A data file written by as370 (see @as370-datafiles) is not in the expected
  form, was written by another version of as370, or belongs to another
  module. Return code 16.
][Write the file again with the as370 of the same installation, from the
  source of this module.]

#msg[#mc("dasm370: ")#mv("file")#mc(" covers ")#mv("n")#mc(" bytes of ")#mv("name")#mc(", the object ")#mv("m")#mc(" -- a STALE export")][
  A statement file given with #mc("--ref-stmts") or #mc("--cand-stmts")
  describes a section of a different length than the object module: it was
  written from another level of the source.
][Write the statement file again from the source of the object module.]

#msg[#mc("dasm370: the as370 command line is too long for this build")][
  Return code 16.
][Use fewer or shorter #mc("-I") directories.]

=== Hint File Messages <apx-messages-dasm370-hints>

#idx("hint file", "messages")
A hint file (see @dasm370-hints) that dasm370 cannot accept is reported in
the form

#screen[#mc("dasm370: ")#mv("file")#mc(":")#mv("line")#mc(": ")#mv("text")]

and dasm370 ends with return code 16 without writing a disassembly. The
first error stops the reading. @apx-messages-hint1 and @apx-messages-hint2
list the texts. With #mc("--anchors=report"), the texts marked R in
@apx-messages-hint2 are not errors: they are written as comments into the
disassembly, at the offset concerned where there is one, and dasm370
continues.

#tab(caption: [Hint file messages: the form of the file])[
  #set par(justify: false)
  #table(columns: (1fr, 1.6in),
    [Text], [Meaning],
    [#mc("not a comment, a table header or `key = value'")], [The line has
      none of the three forms.],
    [#mc("a table is written [[name]]; single brackets are not in this subset") \
     #mc("a table header ends with ]]") \ #mc("table name too long")], [A table
      header is not written correctly.],
    [#mc("[[")#mv("name")#mc("]] is not a table of this format (label data fill base using dsect replace verify)")], [Unknown table.],
    [#mc("[[using]] and [[dsect]] are not implemented yet: ...")], [These
      tables are reserved.],
    [#mc("the key is empty or too long") \ #mc("`")#mv("key")#mc("' is given twice in this table") \
     #mc("`")#mv("key")#mc("' is not a key of this table")], [A key is in
      error.],
    [#mc("`base' is a table, not a root key: [[base]] with reg, value, from and an optional to")], [#mc("base") was written as a key.],
    [#mc("a value is \"a string\" or an integer (decimal or 0x...)") \
     #mc("`")#mv("key")#mc("' takes an integer") \ #mc("`")#mv("key")#mc("' takes a \"string\"") \
     #mc("`")#mv("key")#mc("' is longer than ")#mv("n")#mc(" characters") \
     #mc("`")#mv("key")#mc("' is required here")], [A value is in error,
      or a required key is missing.],
    [#mc("isa = \"")#mv("v")#mc("\" is not one of app|s370|s360|full") \
     #mc("prefix is 1 or 2 characters") \ #mc("a [[label]] name is empty") \
     #mc("len must be positive") \ #mc("reg is 0 through 15") \
     #mc("to must be greater than from") \
     #mc("`value' is required here -- what the register points at") \
     #mc("value name too long") \ #mc("bytes is an even number of hex digits") \
     #mc("a [[verify]] takes bytes or date, not both") \
     #mc("a [[verify]] needs bytes or date") \
     #mc("date is \"mdy\" (mm/dd/yy) or \"julian\" (yy.ddd)")], [A value is
      outside what the key accepts.],
    [#mc("too many keys in one table") \ #mc("too many [[")#mv("table")#mc("]] entries for this build") \
     #mc("too many ranges for this build")], [A limit of dasm370.],
  )
] <apx-messages-hint1>

#tab(caption: [Hint file messages: checks against the module])[
  #set par(justify: false)
  #table(columns: (1fr, 1.5in, 0.25in),
    [Text], [Meaning], [],
    [#mc("verify failed at X'")#mv("off")#mc("': the module holds ")#mv("hex")#mc(", not ")#mv("hex")], [A #mc("[[verify]]") of bytes does not
      hold: the module is not the level the hint file was written for.], [R],
    [#mc("verify failed at X'")#mv("off")#mc("': `")#mv("t")#mc("' (")#mv("hex")#mc(") is not a ")#mv("form")#mc(" date")], [A #mc("[[verify]]") of a
      date does not hold.], [],
    [#mc("anchor at X'")#mv("off")#mc("' is past the end of ")#mv("sect")#mc(" ... -- the module is SHORTER than the source these hints came from") \
     #mc("anchor at X'")#mv("off")#mc("' covers bytes no TXT card defined -- there is nothing there to assert")], [A #mc("[[verify]]") lies outside the
      text of the section.], [R],
    [#mc("label `")#mv("name")#mc("' at X'")#mv("off")#mc("' is past the end of ")#mv("sect")#mc(" ...") \
     #mc("`")#mv("name")#mc("' is at X'")#mv("a")#mc("' in this module and X'")#mv("b")#mc("' in the hint file -- the module has diverged from the source these hints came from")], [A
      #mc("[[label]]") does not match the module.], [R],
    [#mc("two [[label]] entries name one offset") \ #mc("two [[label]] entries share a name")], [Duplicate labels.], [],
    [#mv("table")#mc(" at X'")#mv("off")#mc("' for ")#mv("n")#mc(" byte(s) is outside ")#mv("sect")#mc(", which is X'")#mv("len")#mc("' bytes")], [A range lies
      outside the section.], [],
    [#mc("fill covers bytes no TXT card defined -- that run is a DS, not a DC") \
     #mc("fill is not uniform: X'")#mv("b1")#mc("' at X'")#mv("a1")#mc("' but X'")#mv("b2")#mc("' at X'")#mv("a2")#mc("'") \
     #mc("fill overlaps a relocatable field -- the RLD is ground truth and outranks it") \
     #mc("fill would swallow the label at X'")#mv("off")#mc("'")], [A
      #mc("[[fill]]") does not describe the bytes of the module.], [],
    [#mc("replace covers bytes no TXT card defined -- patching a hole would invent text") \
     #mc("no [[verify]] covers this replace -- an unasserted patch is what makes REPLACE unsafe")], [A #mc("[[replace]]") is refused.], [],
    [#mc("base from X'")#mv("a")#mc("' to X'")#mv("b")#mc("' is outside ")#mv("sect")#mc(" (X'")#mv("len")#mc("' bytes)")], [A #mc("[[base]]") range lies
      outside the section.], [R#super[1]],
    [#mc("value = \"")#mv("name")#mc("\" is not ")#mv("sect")#mc(", an ENTRY of it, or a [[label]] in this file") \
     #mc("value X'")#mv("v")#mc("' is outside ")#mv("sect")#mc(" (X'")#mv("len")#mc("' bytes)") \
     #mc("register ")#mv("r")#mc(" already has a base over this range (line ")#mv("n")#mc(")") \
     #mc("X'")#mv("off")#mc("' is inside a relocatable field and cannot begin a statement") \
     #mc("X'")#mv("off")#mc("' is inside the fill at X'")#mv("a")#mc("' and cannot begin a statement")], [A #mc("[[base]]") is in error.], [],
  )
] <apx-messages-hint2>

#super[1] With #mc("--anchors=report"), a range that runs past the end of
the section is cut back to it, and the comment reads
#mc("base reg ")#mv("r")#mc(" runs to X'")#mv("off")#mc("' but ")#mv("sect")#mc(" is X'")#mv("len")#mc("' bytes -- clamped, ...").

== cmplmd370 Messages <apx-messages-cmplmd370>

#idx("cmplmd370", "messages")
All of these end cmplmd370 with return code 2.

#msg[#mv("file")#mc(": ")#mv("reason")][
  #mv("new"), #mv("reference"), the #mc("--difin") file or the
  #mc("--difout") file could not be opened.
][Correct the file name.]

#msg[#mc("cmplmd370: neither a load module nor an object deck: ")#mv("file") \
#mc("cmplmd370: reference is neither a load module nor an object deck: ")#mv("file")][
  The first or the second file is neither of the two formats that cmplmd370
  compares.
][Name an object module or a load module member.]

#msg[#mc("cmplmd370: no section named ")#mv("name")][
  The section named by #mc("--csect") is not in #mv("new"), under the name
  cmplmd370 reports it by (see @cmplmd370-compare). Nothing is written to
  standard output.
][Correct the name.]

#msg[#mc("cmplmd370: no sections paired")][
  #mv("new") has no section with text, so nothing can be compared.
  Nothing is written to standard output.
][Check the files.]

#msg[#mc("cmplmd370: reference image incomplete (")#mv("anomaly")#mc("); --allow-incomplete to compare anyway")][
  A load module member ends before its last record (see
  @cmplmd370-incomplete). Nothing is written to standard output.
][Obtain a complete copy, or give #mc("--allow-incomplete").]

#msg[#mc("cmplmd370: ")#mv("file")#mc(":")#mv("line")#mc(": not a DIFIN record: ")#mv("text") \
#mc("cmplmd370: ")#mv("file")#mc(":")#mv("line")#mc(": record before any '>' header")][
  The #mc("--difin") file is not in the form described in @cmplmd370-dif.
][Correct the file.]

#msg[#mc("cmplmd370: unknown option ")#mv("option")][
  The usage text follows. The usage text alone is written when fewer or
  more than two files are named.
][Correct the command.]

#msg[#mc("cmplmd370: too many sections") \
#mc("cmplmd370: too many sections in --difin")][
  A limit of cmplmd370.
][Compare the sections one at a time with #mc("--csect").]

With #mc("--json"), the messages that arise during the comparison
(#mc("no section named"), #mc("no sections paired"),
#mc("reference image incomplete")) are given only in the field
#mc("error") of the JSON document, not on standard error.

== idrdump370 Messages <apx-messages-idrdump370>

#idx("idrdump370", "messages")
#msg[#mv("file")#mc(": ")#mv("reason") \
#mc("idrdump370: ")#mv("file")#mc(": cannot read")][
  The file could not be opened (first form), or it is empty or could not be
  read (second form). Return code 2.
][Correct the file name.]

#msg[#mc("idrdump370: ")#mv("file")#mc(" is not a load module")][
  The file is not a load module member: for example an object module, or an
  #mc(".iebcopy") or #mc(".xmit") file. Return code 2.
][Name the member that ld370 wrote with #mc("-o"), or extract it from the
  transport file.]

#msg[#mc("  no IDR records")][
  Written to standard output: the load module contains no identification
  record. Return code 1.
][None.]

#msg[#mc("idrdump370: unknown option '")#mv("option")#mc("'") \
#mc("idrdump370: one file at a time")][
  The command line is in error. The usage text follows the first. Return
  code 2.
][Name one file per call.]
