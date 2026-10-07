#import "../bookmaster/bookmaster.typ": *

= The dasm370 Command <dasm370>

#idx("dasm370")
#idx("disassembler")
The dasm370 command is a disassembler. It reads one control section of an
object module, or of a load module member, and writes assembler language
source that as370 assembles back into the same bytes. You use it to obtain
source for a module that has none, to read what the compiler and the
assembler produced, and to compare two levels of one control section
statement by statement.

dasm370 works the other way round from as370 (see @asm). It decodes
instructions from as370's own operation code table, so the two programs
agree on every instruction by construction. Every instruction dasm370
decodes is encoded again from the decoded fields and compared with the bytes
it came from; anything that does not reproduce its own bytes, or that as370
would not accept as written, is written as a #cmd("DC") constant instead.
Fields that a relocation dictionary entry covers are address constants and
are never decoded as instructions.

dasm370 decodes; it does not guess. Without further information it does not
know which register is a base register, so it writes operands in numeric
form, such as #cmd("34(0,12)"). A _hint file_ supplies what the bytes do not
say: names, base registers and data areas (see @dasm370-hints).

== Invoking dasm370 <dasm370-invoke>

#idx("dasm370", "syntax")
dasm370 has three forms. The first disassembles a control section:

#syntax(read("../syntax/dasm370-main.txt"))

#syntax(title: "Option:", read("../syntax/dasm370-option.txt"))

The second assembles a source with as370 and writes a hint file from what
the assembly found (see @dasm370-derive):

#syntax(read("../syntax/dasm370-derive.txt"))

The third compares two levels of a control section (see @dasm370-align):

#syntax(read("../syntax/dasm370-align.txt"))

#syntax(title: "Report:", read("../syntax/dasm370-report.txt"))

dasm370 with no operands writes the summary of the options to standard
error and ends with return code 2. Options without an #var("input-file")
end it with return code 16.

=== Operands

#deflist(width: 1.45in,
  [#var("input-file")], [is the object module or load module member to
    read. See @dasm370-input.],
  [#cmd("--csect") #var("name")], [selects the control section to
    disassemble, or with #cmd("--align-diff") to compare. The default is the
    first one. A name that is not in the module ends dasm370 with return
    code 2, and the message lists the sections the module holds.],
  [#cmd("--hints") #var("file")], [reads a hint file. See
    @dasm370-hints.],
  [#cmd("--anchors=")#var("mode")], [decides what a failed check in a hint
    file does. #cmd("refuse"), the default, ends dasm370 with return code 16
    at the first failure and writes nothing. #cmd("report") writes the
    disassembly anyway and records a failed check of bytes, of a label or
    of a range as a comment at its offset. A failed date check and the
    other errors of a hint file still end the run.],
  [#cmd("--labels") #var("mode")], [decides how a label that dasm370 makes
    up is named. #cmd("displacement"), the default, names it after its
    offset: #cmd("L00002C") for #cmd("X'2C'"). #cmd("sequential") numbers
    the labels in order of offset, #cmd("L0010"), #cmd("L0020"), and so on.
    Use #cmd("sequential") for source that you will edit: a name derived
    from an offset becomes false as soon as a statement is inserted above
    it, and nothing reports that. Either form reassembles to the same
    bytes.],
  [#cmd("--isa") #var("set")], [selects the operation codes the decoder may
    use. #cmd("full"), the default, is the System/370 instruction set as
    as370 accepts it; #cmd("s370") is the same set. #cmd("app") leaves out
    floating-point, decimal, input/output and privileged instructions, so
    that fewer data bytes are mistaken for instructions in an application
    program; such bytes are then written as #cmd("DC"). #cmd("s360") is
    accepted by the option parser and refused with return code 16.],
  [#cmd("--format") #var("form")], [selects the form of the output.
    #cmd("card"), the default, writes 80-column records with column 72
    blank and a sequence number in columns 73 to 80. #cmd("free") writes the
    same statements without padding or sequence numbers.],
  [#cmd("--infer")], [writes a hint file of base register candidates found
    in the code, instead of a disassembly. See @dasm370-derive.],
  [#cmd("--reach-report")\[#cmd("=")#var("set")\]], [writes a report of the
    code reachable from the entry points, instead of a disassembly. See
    @dasm370-reach.],
  [#cmd("--reach")\[#cmd("=")#var("set")\]], [is recognized and refused
    with return code 16: applying the traversal to the disassembly is not
    implemented. #cmd("--reach-report") is available.],
  [#cmd("--allow-incomplete")], [reads a load module member whose records
    cannot be followed to the end. Text that could not be read is written
    as #cmd("DS"). Without this option such a member is refused with return
    code 2.],
  [#cmd("-o") #var("file")], [writes the output to #var("file") instead of
    standard output. The file is opened only after every check has passed,
    so a run that is refused leaves no file behind.],
  [#cmd("-v")], [writes one line to standard error that says what was read:
    the file, the section, its origin and length, and the number of its
    relocation dictionary and entry point (LD) entries. It has no effect
    with #cmd("--align-diff").],
  [#cmd("-h"), #cmd("--help")], [displays a summary of the options and
    ends.],
  [#cmd("-V"), #cmd("--version")], [displays the toolchain version and the
    commit from which dasm370 was built, and ends.],
  [#cmd("--derive-hints") #var("source-file")], [assembles
    #var("source-file") with as370 and writes a hint file. It takes no
    #var("input-file") and cannot be combined with #cmd("--hints") or
    #cmd("--infer").],
  [#cmd("-I") #var("directory")], [adds a macro library for the assembly
    that #cmd("--derive-hints") runs. It can be repeated, up to 64 times.
    In the other forms it is accepted and has no effect.],
  [#cmd("--as370") #var("path")], [names the as370 program that
    #cmd("--derive-hints") runs. The default is the as370 in the directory
    that holds dasm370, and failing that the one found through
    #cmd("PATH"). In the other forms it has no effect.],
  [#cmd("--align-diff") #var("reference") #var("candidate")], [disassembles
    the same control section of two modules and reports their differences.
    It takes no #var("input-file") and cannot be combined with
    #cmd("--hints"), #cmd("--infer") or #cmd("--derive-hints").],
  [#cmd("--json") #var("file")], [with #cmd("--align-diff"), also writes the
    differences to #var("file") as JSON. Without #cmd("--align-diff") it is
    refused.],
  [#cmd("--ref-stmts") #var("file"),\ #cmd("--cand-stmts") #var("file")],
    [name the statement files that as370 wrote with #cmd("--stmts=") for the
    source of the reference and of the candidate (see @as370-datafiles). Their
    information is added to the JSON file, so both options require
    #cmd("--json").],
  [#cmd("--stmts")], [is refused with return code 16 and a message
    pointing to #cmd("--ref-stmts") and #cmd("--cand-stmts").],
)

== What dasm370 Reads <dasm370-input>

#idx("dasm370", "inputs")
#var("input-file") is either an object module, as as370 writes it, or a
load module member, as ld370 writes it with #cmd("-o")\; dasm370 decides
which from the contents. Any other file, including the #cmd(".iebcopy")
and #cmd(".xmit") files, is refused with the message
#cmd("not an object deck or a load module") and return code 16.

#idx("control section", "selecting")
A run writes one control section. When an object module holds several and
#cmd("--csect") is not given, dasm370 writes the first and lists all of them
on standard error. If the first section is empty and another is not, the
list is headed #cmd("WARNING") and the return code is 4.

#idx("common section")
A common section (#cmd("COM"), ESD type CM) holds no text and is not a
section to disassemble: it is not listed and not counted. #cmd("--csect")
naming one ends dasm370 with return code 2 and the message that it is a
common section and holds no text.

From an object module, dasm370 also writes the #cmd("ENTRY") statements of
the section and an #cmd("END") statement naming the entry point the
#cmd("END") record gives. A load module member does not record its entry
point (it is in the directory entry of the library), so the #cmd("END")
statement of a member's disassembly has no operand.

== The Disassembly <dasm370-output>

#idx("dasm370", "output")
@dasm370-count-asm shows a small program, COUNT, which adds the four words
of a table. @dasm370-count-s shows what the command

```
dasm370 -o count.s count.o
```

writes for its object module.

#fig(caption: [COUNT, an assembler program])[
  #code(read("../ex/dasm370/count.asm"), numbers: true)
] <dasm370-count-asm>

#fig(caption: [Disassembly of COUNT])[
  #code(read("../ex/dasm370/count.s"), size: 7pt)
] <dasm370-count-s>

The disassembly has these elements:

- A #cmd("CSECT") statement with the name of the section; its remark gives
  the length of the section and the file it was read from.
- #cmd("ENTRY") statements for the entry points the section defines, and
  #cmd("EXTRN") statements for every other symbol that an address constant
  of the section refers to.
- One statement for each instruction or constant. Its remark is the offset
  of the statement in the section, in hexadecimal.
- Labels for the start of the section, for each entry point of the
  section and for each location that an address constant of the section
  points to. Entry points that belong to other sections of a load module
  are not used. A label that
  the module does not name is made up from its offset (#cmd("L00002C")), or
  numbered with #cmd("--labels sequential").
- Address constants, written from the relocation dictionary as
  #cmd("A(...)") or #cmd("V(...)"), with a length modifier where the field
  is not a full word, for example #cmd("AL3(VV+X'C')").
- Instructions with their operands in numeric form, #var("d")#cmd("(")#var("x")#cmd(",")#var("b")#cmd(")"),
  unless a hint file declares a base register. Branches on condition use
  the extended mnemonics (#cmd("B"), #cmd("BE"), #cmd("BR")) where the mask
  has one; immediate operands are decimal numbers.
- Areas that no text record covers, written as #cmd("DS XL")#var("n") with
  the remark #cmd("not covered by TXT"). A reserved area is not the same as
  an area of zeros, and the distinction is kept.
- Any other data, written as #cmd("DC X'...'").

=== The Round Trip <dasm370-roundtrip>

#idx("dasm370", "round trip")
#idx("round trip")
The output is meant to be assembled again. For COUNT, assembling
@dasm370-count-s gives an object module identical to the original, byte for
byte:

```
dasm370 -o count.s count.o
as370 -o count-rt.o count.s
cmp count.o count-rt.o
```

Where the two object modules may legitimately differ, for example because
the original came from a load module, compare them with cmplmd370 (see
@cmplmd370), which leaves the relocated address constants out.

A successful round trip proves that the source reproduces the bytes, not
that every byte was read correctly. @dasm370-date shows both ways in which a
reading can be wrong and still reassemble to the same bytes: the constant
#cmd("C'26.123'") at offset #cmd("X'E'") is decoded as a #cmd("PACK")
instruction, and #cmd("BZ") comes back as #cmd("BE"), which is the same
instruction. A #cmd("[[data]]") entry in a hint file (see @dasm370-hints)
corrects the first. Note also that the result assembles the one control
section, not the whole object module.

#fig(caption: [A constant read as an instruction])[
  #grid(columns: (1fr, 1.6fr), column-gutter: 1em,
    code(read("../ex/dasm370/date.asm"), size: 7.5pt),
    code(read("../ex/dasm370/date.txt"), size: 7.5pt))
] <dasm370-date>

== Hint Files <dasm370-hints>

#idx("hint file")
#idx("dasm370", "hint file")
A hint file tells dasm370 what the bytes cannot: what a location was called,
which register is a base register and over which range, which areas are
data, and what the module is expected to hold. Its syntax is a small subset
of TOML:

- #cmd("#") begins a comment that runs to the end of the line.
- #var("key") #cmd("=") #var("value") sets a key. The value is a string in
  double quotation marks, or an integer, decimal or with the prefix
  #cmd("0x").
- #cmd("[[")#var("table")#cmd("]]") begins one entry of a table; the keys
  that follow belong to it. Keys before the first table belong to the file.

Anything outside this subset is refused, with the line number and return
code 16, and nothing is written: an unknown table or key, a key given twice,
a missing key, a value of the wrong kind, a table written with single
brackets and an offset outside the section. Offsets are relative to the
start of the section.

#tab(caption: [Contents of a hint file])[
  #table(columns: (1.5in, 1fr),
    [Entry], [Meaning],
    [#cmd("isa =") #var("set")], [As #cmd("--isa")\; the option takes
      precedence. At the file level.],
    [#cmd("prefix =") #var("string")], [One or two characters that replace
      the #cmd("L") of made-up labels, so that two disassemblies can be
      assembled together. At the file level.],
    [#cmd("[[label]]") #cmd("at"), #cmd("name")], [Names the location
      #cmd("at"). A label inside what was decoded as an instruction makes
      that instruction a #cmd("DC").],
    [#cmd("[[data]]") #cmd("at"), #cmd("len")], [Do not decode these bytes
      as instructions.],
    [#cmd("[[fill]]") #cmd("at"), #cmd("len")], [These bytes are one
      repeated value; write them with a duplication factor, such as
      #cmd("DC 20X'00'"). Refused unless the run is covered by text, uniform,
      and free of labels and address constants.],
    [#cmd("[[base]]") #cmd("reg"), #cmd("value"), #cmd("from") \[,
      #cmd("to")\]], [Register #cmd("reg") addresses #cmd("value") (an offset,
      or the name of the section, an entry point or a label) from offset
      #cmd("from") to offset #cmd("to"). Without #cmd("to") the range is 4096
      bytes, ended early by the end of the section. dasm370 writes
      #cmd("USING") and #cmd("DROP") statements, writes operands in that range
      symbolically where as370 would choose the same register, and labels
      the targets of #cmd("BC") instructions it can resolve.],
    [#cmd("[[verify]]") #cmd("at"), #cmd("bytes") | #cmd("date")], [Checks
      that the module holds these bytes (hexadecimal) at #cmd("at"), or a
      date in the form #cmd("\"mdy\"") (#var("mm/dd/yy")) or
      #cmd("\"julian\"") (#var("yy.ddd")).],
    [#cmd("[[replace]]") #cmd("at"), #cmd("bytes")], [Replaces bytes before
      the disassembly. Each replacement must lie within a
      #cmd("[[verify]]") entry, which checks the original bytes.],
  )
] <dasm370-hints-tab>

The tables #cmd("[[using]]") and #cmd("[[dsect]]"), which would map a
register onto a dummy section, are recognized and refused as not yet
implemented.

#idx("dasm370", "anchors")
A #cmd("[[verify]]") entry that fails ends the run with return code 16 and a
message giving the offset and the bytes found. With #cmd("--anchors=report")
a failed check of bytes no longer ends the run (a failed date check still
does): the disassembly is written anyway, headed by comments that count the
failures, give the offset of the first one and list each one. The first
failure shows where the module and the hint file part company.

@dasm370-hints-fig shows a hint file for COUNT and the disassembly it
produces, written with #cmd("--format free"). The base register makes the
#cmd("L") and #cmd("BCT") operands symbolic; the result still reassembles to
the original bytes.

#fig(caption: [A hint file and its effect])[
  #code(read("../ex/dasm370/count.hints"))
  #v(0.6em)
  #code(read("../ex/dasm370/count-hints.txt"), size: 7.5pt)
] <dasm370-hints-fig>

== Deriving and Inferring Hint Files <dasm370-derive>

#idx("dasm370", "--derive-hints option")
When you have a source that is close to the module, for example an earlier
level of it, #cmd("--derive-hints") writes the hint file for you. It
assembles the source with as370, using the #cmd("-I") libraries given, and
writes a hint file with the labels the source defines, its base registers
with the ranges of their #cmd("USING") statements, and #cmd("[[verify]]")
entries at the labelled locations. Comments at the head of the file record
which as370 was run, its version and size, and the #cmd("-I") libraries,
because hints derived with the wrong macro library are wrong without
looking wrong.

The offsets in a derived file are those of the source. Applied to a module
that has changed since, every label and range past the first change is
wrong; that is what the #cmd("[[verify]]") entries are for. Use
#cmd("--anchors=report") to find the first place where they fail.

#idx("dasm370", "--infer option")
For a module with no source at all, #cmd("--infer") examines the code and
writes base register candidates, each as a comment line beginning
#cmd("# infer:"), with the kind of evidence for it:

#deflist(width: 1.0in,
  [#cmd("prologue")], [a #cmd("BALR") #var("n")#cmd(",0") instruction
    establishes the register; the starting point is known, the range is
    not.],
  [#cmd("rld")], [the register is loaded from an address constant that
    points into the section, and is then used as a base.],
  [#cmd("pattern")], [the register is used as a base and nothing was found
    that loads it.],
)

No candidate is applied, because a base register with a wrong range
produces wrong symbols that still reassemble to the right bytes. To use a
candidate, write it as a #cmd("[[base]]") entry with the range you have
established.

== Comparing Two Levels of a Section <dasm370-align>

#idx("dasm370", "--align-diff option")
#cmd("--align-diff") disassembles the same control section of two modules,
the _reference_ and the _candidate_, and aligns the two disassemblies
statement by statement. Each operand may be an object module or a load module
member. Statements are matched with their displacements left out, so that a
statement that only moved still matches. Every difference is then reported
as a _finding_ or as a _consequence_ of one:

#deflist(width: 1.0in,
  [#cmd("FINDING")], [a real change: #cmd("insert"), #cmd("delete"),
    #cmd("change"), #cmd("data") (a change in a data run) or #cmd("const") (a
    displacement or address constant that changed by an amount no shift
    explains). The statements involved follow on lines of their own.],
  [#cmd("CONSEQ")], [a displacement (#cmd("shift")) or address constant
    (#cmd("adcon")) that changed by an amount by which matched statements
    moved. These are expected results of the findings, not changes of their
    own.],
)

The report ends with the set of shifts, a line that says how far the
classification can be trusted, and a #cmd("SUMMARY") line for programs to
read. A displacement is relative to a base register, and dasm370 takes the
first #cmd("BALR") #var("n")#cmd(",0") of the reference as the point where
the base is established: #cmd("EXACT") means it precedes every change, so a
shift is measured exactly; #cmd("WEAK") means a change precedes it, or there
is no such instruction. The #cmd("SUMMARY") line gives the counts of
findings and consequences, #cmd("first=") the offset of the first finding
(#cmd("-") when there is none), the statement counts and lengths of both
sections, #cmd("base=") and #cmd("align=ok"). If the two sections need more than 20000 insertions and
deletions to align, the alignment is abandoned, the summary says
#cmd("align=abandoned") and the return code is 4.

@dasm370-align-fig shows the report for COUNT against a version with one
#cmd("LTR") instruction inserted after the second #cmd("LA"). It reports two
insertions: the instruction, and two bytes the assembler added to keep the
address constant on a full-word boundary. The changed displacements of the
#cmd("L") and #cmd("BCT") instructions and the changed address constant are
consequences. The #cmd("L") instruction comes before the insertion, but the
table it addresses comes after it.

#fig(caption: [Comparing two levels of COUNT])[
  #code(read("../ex/dasm370/align.txt").replace(" conseq=", "\n    conseq="), size: 6.4pt)
] <dasm370-align-fig>

The SUMMARY line is one line in the output; it is shown broken here.

#idx("dasm370", "JSON output")
With #cmd("--json"), the findings are also written to a file as JSON. The
document names its format in #cmd("schema"), #cmd("dasm370-repair/3"), and
explains its fields in #cmd("note") members of its own. For each finding it
gives the offsets, lengths and bytes on both sides and the statement
dasm370 decoded there. Given #cmd("--ref-stmts") and #cmd("--cand-stmts"),
it adds for each side the source statement that produced the bytes: its line
number, its text and whether a macro generated it.

== Reachability Report <dasm370-reach>

#idx("dasm370", "--reach-report option")
#cmd("--reach-report") follows the flow of control from the entry points of
the section, the start of the section, its entry points and, for an object
module, the entry point of the #cmd("END") record, and reports which bytes it
reaches. Bytes that are never reached are usually data. The report is one
#cmd("REACH") line, which gives among other things the length of the section,
the number of starting points, #cmd("reached=") and #cmd("dark=") (the
number of bytes reached and not reached), and one #cmd("REACHRUN") line for
each run of reached bytes, with its offset and length. For COUNT:

```
REACH COUNT len=60 roots=2 sd=1 ld=0 end=1 reached=40 dark=20 runs=1 ...
REACHRUN 000000 40
```

The 20 bytes not reached are the address constant and the table. The
optional #var("set") selects which assumptions about base registers the
traversal may make: #cmd("none"), #cmd("r15"), #cmd("balr"),
#cmd("both"), #cmd("rld"), #cmd("lr"), #cmd("bothlr"), #cmd("acon") or
#cmd("all"), the default. The report does not change the disassembly.

== Return Codes <dasm370-rc>

#idx("dasm370", "return codes")
#tab(caption: [dasm370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The output was written.],
    [2], [dasm370 was called without operands; or the section named by
      #cmd("--csect") is not in the module or is a common section; or a
      load module member is incomplete and #cmd("--allow-incomplete") was
      not given.],
    [4], [The output was written, but the first section of the module is
      empty while another is not; or #cmd("--align-diff") abandoned the
      alignment.],
    [16], [The command was given incorrectly or used an option that is
      refused, a file could not be opened or is neither an object module
      nor a load module member, or a hint file is in error or failed a
      check.],
  )
] <dasm370-rc-tab>
