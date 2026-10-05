#import "../bookmaster/bookmaster.typ": *

= The cmplmd370 Command <cmplmd370>

#idx("cmplmd370")
#idx("comparing modules")
The cmplmd370 command compares the control sections of two modules, byte for
byte, and says whether they are identical. Its first operand is usually an
object module that as370 has just produced; its second, the reference, is a
load module member or another object module. The question it answers is
whether the program text of a module rebuilt from source is the program text
of the module it is meant to replace.

What makes the comparison possible without linking the new object module
first is that the linkage editor changes only the address constants of a
module, never its instructions or other data. cmplmd370 therefore leaves the
bytes of every address constant out of the comparison, and compares the
rest.

cmplmd370 compares program text only. It does not compare the attributes of
a load module (reentrant, reusable, authorization code, entry point), which
are held in the directory entry of the library rather than in the member,
and it does not compare the identification records (see @idrdump370).

== Invoking cmplmd370 <cmplmd370-invoke>

#idx("cmplmd370", "syntax")
#syntax(read("../syntax/cmplmd370-main.txt"))

#syntax(title: "Option:", read("../syntax/cmplmd370-option.txt"))

=== Operands

#deflist(width: 1.45in,
  [#var("new")], [is the module being checked: an object module, or a load
    module member. See @cmplmd370-inputs.],
  [#var("reference")], [is the module it is compared against: a load module
    member, or an object module.],
  [#cmd("--csect") #var("name")], [compares only the control section
    #var("name"). The default is to compare every control section of
    #var("new").],
  [#cmd("--clearrld")], [leaves the bytes of address constants out of the
    comparison. This is the default; the option exists to say so
    explicitly.],
  [#cmd("--no-clearrld")], [compares the bytes of address constants too.
    This is meaningful only when both operands are object modules, since a
    load module holds relocated values.],
  [#cmd("--difin") #var("file")], [ignores the byte ranges listed in
    #var("file"), in the form described in @cmplmd370-dif.],
  [#cmd("--difout") #var("file")], [writes the ranges that differ to
    #var("file"), in the same form.],
  [#cmd("--json")], [writes the result as a JSON object on standard output.
    See @cmplmd370-json.],
  [#cmd("--allow-incomplete")], [compares even when the record stream of a
    load module could not be read to its end. See @cmplmd370-incomplete.],
  [#cmd("-v")], [also lists the sections that are identical, and lists the
    differing bytes of each section.],
  [#cmd("-h"), #cmd("--help")], [displays a summary of the options and
    ends.],
  [#cmd("-V"), #cmd("--version")], [displays the toolchain version and the
    commit from which cmplmd370 was built, and ends.],
)

== Inputs <cmplmd370-inputs>

#idx("cmplmd370", "inputs")
cmplmd370 decides the kind of each operand from its first bytes. A file that
begins like a load module member is read as one; otherwise a file of 80-byte
object module records is read as an object module. Any other file is
rejected with return code 2. A load module member is the file ld370 writes
with #cmd("-o")\; the #cmd(".iebcopy") and #cmd(".xmit") files written
beside it are not accepted.

A load module is accepted on the left as well. That compares two members,
for example two links of the same object modules, or a member against
another member said to be built from the same source.

== How Sections Are Compared <cmplmd370-compare>

#idx("cmplmd370", "section pairing")
Sections are paired *by name*. Each control section of #var("new") is looked
for, by name, among the sections of #var("reference"). A section of
#var("new") that has no partner is reported as #cmd("not in the reference")
and counts as a difference. A section of #var("reference") that has no
partner is not reported: comparing the object module of one control section
against a load module that holds many is the ordinary case.

#idx("private code")
An unnamed section, which is what a #cmd("CSECT") statement without a name
produces, is the one exception. It is paired with the one section of the
reference that is left over after pairing by name, if exactly one is left,
and is then reported under that section's name. When the partner is unnamed
too, it is reported as #cmd("(private)").

A pair of sections whose lengths differ is reported as
#cmd("LENGTH differs"), with both lengths; no bytes are compared. When the
lengths agree, the sections are compared byte by byte, leaving out the bytes
of address constants unless #cmd("--no-clearrld") is given. A byte is an
address constant byte if a relocation dictionary entry of either operand
covers it.

=== Storage Areas and Generated Text <cmplmd370-holes>

#idx("DS hole")
An object module records which bytes the assembler actually produced: an
area reserved with #cmd("DS") has no text record and is filled with zeros
when the module is loaded or linked, whereas the program it replaces may
have anything there. When #var("new") is an object module, cmplmd370
therefore classifies every differing byte as lying either in such a reserved
area (a _hole_) or in generated text, and says which:

#tab(caption: [Classification of differences])[
  #set par(justify: false)
  #table(columns: (2.6in, 1fr),
    [Message], [Meaning],
    [#cmd("ALL in DS holes (no byte as370 wrote)")], [Every differing byte
      lies in an area #var("new") reserves but does not fill. The source
      agrees with the reference; only the content of reserved storage
      differs.],
    [#cmd("all in GENERATED TEXT")], [Every differing byte is one the
      assembler produced.],
    [#cmd("some in DS holes, some in generated text")], [Both.],
    [#cmd("hole/text split not determinable from a bound member")], [The
      left operand is a load module, which does not record which of its
      bytes were reserved.],
  )
] <cmplmd370-holes-tab>

The classification depends on the left operand only. The same two files given
in the other order can therefore be classified differently, as the example in
@cmplmd370-holes-fig shows.

#fig(caption: [The order of the operands decides the classification])[
  #screen(raw(read("../ex/cmplmd370/holes.txt")))
] <cmplmd370-holes-fig>

=== Incomplete Load Modules <cmplmd370-incomplete>

#idx("cmplmd370", "incomplete module")
If the records of a load module operand cannot be followed to the end of the
module, for example because the file was truncated, the image of the module
is incomplete. The bytes that were read might match, but that is not a
match. cmplmd370 reports the reason on a line beginning #cmd("reader:"),
names it in an error message, and ends with return code 2. With
#cmd("--allow-incomplete") it compares anyway and ends with 0 or 1 as usual.

== Output <cmplmd370-output>

#idx("cmplmd370", "output")
The first line names the two operands, followed by #cmd("(adcons compared)")
when #cmd("--no-clearrld") is in effect and #cmd("(difin applied)") when
#cmd("--difin") is. Then comes one line for each section that differs, or
for every section when #cmd("-v") is given, and finally a line that reads
#cmd("IDENTICAL") or #cmd("DIFFER").

The line for a differing section gives the number of differing bytes, the
number of _clusters_ (runs of adjacent differing bytes) they form, the
length of the section and the classification described in
@cmplmd370-holes. With #cmd("-v"), each cluster follows on a line of its
own: its offset in the section, its length, and the bytes of the new and the
reference module. At most 64 clusters and 16 bytes of each are listed; the
JSON output lists all of them in full.

== Difference Files <cmplmd370-dif>

#idx("cmplmd370", "difference file")
A difference file lists byte ranges, section by section. A line that begins
with #cmd(">") starts a section and holds its name in columns 2 to 9. Each
following line is a range: six hexadecimal digits of offset in the section
and two of length.

```
>COUNT
00001101
```

#cmd("--difin") makes cmplmd370 treat the listed ranges as equal. Use it
after you have examined a difference and accepted it. #cmd("--difout")
writes the ranges that the next run needs to ignore: those that differ now,
together with the #cmd("--difin") ranges that hid a difference in this run.
A #cmd("--difin") range that hid nothing is not written. Ranges for sections
this run did not compare (because of #cmd("--csect"), or because the
section was missing or differed in length) are copied unchanged. The same
file can therefore be given to both options, and grows only by what has been
reviewed.

#note[An #cmd("IDENTICAL") result obtained with #cmd("--difin") depends on
the ranges in the file. The text output says that the file was applied but
not how many bytes it hid; #cmd("bytes_ignored_difin") in the JSON output
does.]

== JSON Output <cmplmd370-json>

#idx("cmplmd370", "JSON output")
With #cmd("--json"), cmplmd370 writes one JSON object. Its members are
#cmd("new"), #cmd("reference"), #cmd("clearrld"), #cmd("difin"), a
#cmd("reader") object for each load module operand, a #cmd("sections")
array, #cmd("error"), #cmd("identical") and #cmd("exit"), the return code.
The object has the same members when the comparison fails, with the reason
in #cmd("error").

Each element of #cmd("sections") has #cmd("name") and #cmd("verdict"), one
of #cmd("identical"), #cmd("text"), #cmd("holes"), #cmd("mixed"),
#cmd("differs") (the classification could not be made), #cmd("length") and
#cmd("unpaired"). A paired section also has the two lengths, the counts of
differing bytes in holes and in text (#cmd("null") when they cannot be
determined), the number of bytes left out as address constants and as
#cmd("--difin") ranges, and a #cmd("clusters") array with the offset, the
length and the bytes of each cluster.

== Return Codes <cmplmd370-rc>

#idx("cmplmd370", "return codes")
#tab(caption: [cmplmd370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [Every compared section is identical. This is the only code that
      means identity.],
    [1], [At least one section differs, differs in length, or has no
      partner in the reference.],
    [2], [The command was given incorrectly, a file could not be read or is
      neither a load module nor an object module, the section named by
      #cmd("--csect") does not exist, #var("new") has no control section, or a
      load module is incomplete and #cmd("--allow-incomplete") was not
      given.],
  )
] <cmplmd370-rc-tab>

== Examples <cmplmd370-examples>

=== Comparing an Object Module with Its Load Module

@cmplmd370-session1 assembles the program of @dasm370-count-asm and links it
twice, the second time with the reentrant and reusable attributes. The
object module is identical to the load module; the four bytes of the address
constant at offset #cmd("X'28'") are left out of the comparison. The two links are
identical as well, byte for byte: the attributes are held in the directory
entry, which file370 shows from the #cmd(".iebcopy") files (see @file370).

#fig(caption: [An object module and two links of it])[
  #screen(raw(read("../ex/cmplmd370/session1.txt")))
] <cmplmd370-session1>

=== Finding and Accepting a Difference

In @cmplmd370-session2 the source has been changed to load 5 instead of 4
into register 3. cmplmd370 finds one differing byte in generated text, at
offset #cmd("X'11'") of the section. The difference is written to a file
with #cmd("--difout")\; given back with #cmd("--difin"), it makes the
comparison succeed.

#fig(caption: [Finding and accepting a difference])[
  #screen(raw(read("../ex/cmplmd370/session2.txt")))
] <cmplmd370-session2>
