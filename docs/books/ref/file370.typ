#import "../bookmaster/bookmaster.typ": *

= The file370 Command <file370>

#idx("file370")
The file370 command identifies the files that the toolchain writes and
describes their contents. It recognizes an object module, an object
library, a load module member and the two transport forms of a load
library, and for each it writes either a one-line summary or, on request, a
structural display of the records it consists of. It plays the part of the
#cmd("file") and #cmd("objdump") commands of the workstation for MVS
formats.

file370 only reads. It does not change the files it examines and does not
contact MVS. It is useful at every step of the chain: to see what as370
wrote (see @asm), what a library made by ar370 contains (see @ar370), and
what ld370 is about to send to MVS (see @ld370).

== Invoking file370 <file370-invoke>

#idx("file370", "syntax")
#syntax(read("../syntax/file370-main.txt"))

#syntax(read("../syntax/file370-info.txt"))

=== Operands

#deflist(
  [#var("file")], [is a file to examine. Name one or more\; each is described
    in turn. file370 recognizes a file by its contents, not by its name (see
    @file370-formats). A #var("file") of #cmd("-") is standard input,
    reported under the name #cmd("-").],
  [#cmd("-v")], [writes a structural display of each file instead of the
    one-line summary. @file370-verbose describes it for each format.],
  [#cmd("--csects")], [writes the external symbol dictionary of each file
    and nothing else. For a load module member this is the composite ESD
    (see @file370-csects). For an object module it is the same as
    #cmd("-v"). For the other formats it has no effect.],
  [#cmd("--json")], [writes the output of #cmd("--csects") in JSON, and
    implies #cmd("--csects"). For a load module member that is its composite
    ESD, for an object module its ESD\; for any other file it is the format
    alone. See
    @file370-json.],
  [#cmd("--help"), #cmd("-h")], [displays a summary of the options on
    standard output and ends with return code 0.],
  [#cmd("--version"), #cmd("-V")], [displays the toolchain version and the
    commit from which file370 was built, for example
    #cmd("file370 1.4.0 (2821ebb)"), and ends.],
)

#idx("file370", "order of operands")
The operands are processed from left to right, and an option applies to the
files named after it. #cmd("file370 a.o -v b.o") therefore summarizes
#cmd("a.o") in one line and displays #cmd("b.o") in full. An operand that
begins with #cmd("-") and is not one of the options above ends file370 at
once with the message #cmd("file370: unknown option '")#var("op")#cmd("'"),
the usage summary on standard error, and return code 2\; the files named
after it are not examined.

== Recognized Formats <file370-formats>

#idx("file370", "recognized formats")
file370 examines the first bytes of a file and applies the tests of
@file370-formats-tab in the order shown. The first test that succeeds
decides the format.

#tab(caption: [Formats recognized by file370])[
  #table(columns: (1.35in, 1.05in, 1fr),
    [Format], [Written by], [Recognized by],
    [Object library], [ar370], [The seven characters #cmd("!<arch>") followed by
      a newline.],
    [IEBCOPY unloaded data set], [#cmd("ld370 -iebcopy")], [The bytes
      #cmd("X'00CA6D0F'") that begin the first IEBCOPY control record
      (COPYR1).],
    [TSO XMIT (NETDATA) file], [#cmd("ld370 -xmit"), xmit370], [The
      characters #cmd("INMR01"), in EBCDIC, at offset 2.],
    [Object module], [as370, #cmd("cc370 -c")], [The byte #cmd("X'02'")
      followed by #cmd("ESD"), #cmd("TXT"), #cmd("RLD"), #cmd("END") or
      #cmd("SYM") in EBCDIC.],
    [Load module member], [ld370], [A first byte of #cmd("X'20'") or
      #cmd("X'28'"), which begins a composite ESD record, or a first byte
      from #cmd("X'40'") to #cmd("X'4F'"), which begins the SYM record of a
      module linked with the TEST attribute\; and, in either case, a record
      stream that decodes as far as a CESD or control record.],
  )
] <file370-formats-tab>

A file that passes none of the tests is reported as
#var("file")#cmd(": data (not a recognized cc370 toolchain format)"), with
return code 2. The last test is what keeps a text file out of the load
module class: a line that begins with a blank or with one of the
characters #cmd("@") to #cmd("O") has a first byte in the SYM range, but
no load module records follow, so the file is reported as data. A file of
length zero is reported as
#var("file")#cmd(": empty file"), with return code 0.

#idx("load module", "transport forms")
The three load module forms nest. ld370 writes a load module member\; with
#cmd("-iebcopy") it wraps the member, or several members, in the unloaded
form of a partitioned data set that IEBCOPY reads\; with #cmd("-xmit") it
wraps that unloaded data set in a TSO XMIT file, which is what is sent to
MVS and received there. With #cmd("-v"), file370 takes an XMIT file apart
layer by layer.

== The One-Line Summary <file370-summary>

#idx("file370", "summary")
Without #cmd("-v"), file370 writes one line for each file, beginning with the
file name. @file370-summary-fig shows a summary of each format. The fields are:

#deflist(width: 1.35in,
  [Object module], [The number of sections (SD, CM and PC), the name of the
    first, or #cmd("(private)") when it is unnamed, the number of external
    references (ER and WX), the number of bytes of text, and the number of
    RLD records. A file whose length is not a multiple of 80 has
    #cmd("WARNING: not a multiple of 80") added.],
  [Object library], [The number of object members, not counting the symbol
    index, and the number of symbols in the index.],
  [Load module member], [Counts of the records of each kind: CESD records,
    IDR records, scatter-load records, SYM records, overlay segments when
    there is more than one, text records, control records, and how many of
    the control records also carry relocation data (#cmd("w/RLD")).
    #cmd("MODEND") shows that the last control record marks the end of the
    module, and the length of the file in bytes follows. The counts are of
    records, not of entries: one CESD record holds several ESD entries.
    Bytes found after the end of the module are reported as
    #cmd("(+")#var("n")#cmd(" after MODEND)"), and a record that cannot be
    decoded as #cmd("(TRUNCATED/unrecognized record)").],
  [IEBCOPY], [The kind of library, taken from the record format in the
    IEBCOPY header: #cmd("(RECFM=U load library)"), or for any other record
    format a source library with its record format and record length, such
    as #cmd("(RECFM=FB, LRECL=80 source library)"). Then the name of every
    entry in the directory, aliases included, in directory order.],
  [XMIT], [The data set name the file will be received into
    (#cmd("INMDSNAM")), the utility that unloaded it (#cmd("INMUTILN")),
    and what the data is: an IEBCOPY unloaded data set, with its member name
    or the number of its directory entries, a load module, or other data. A
    file whose length is not a multiple of 80 has
    #cmd("WARNING: not FB80 (size % 80 != 0)") added.],
)

A warning does not change the return code.

== The Structural Display <file370-verbose>

#idx("file370", "-v option")
With #cmd("-v"), file370 shows how each file is built. The examples in this
section were produced from the files of @file370-example.

=== Object Module

After the summary line, file370 gives the number of 80-byte records and of
LD entries, and then one line for each entry of the external symbol
dictionary: its ESD identifier, name and type, and, for a section, its
address and length. An LD entry has no ESD identifier of its own and shows
#cmd("--") and its address\; an ER or WX entry has neither address nor
length. An unnamed section is shown as #cmd("(blank)"). The last line gives
the entry point from the END record, or says that there is none.

#fig(caption: [Structural display of an object module])[
  #screen(raw(read("../ex/file370/file-v-obj.txt")))
] <file370-v-obj>

=== Object Library

file370 lists the members of the library with their lengths, and then the
names in the symbol index, in index order (see @ar370-index).

#fig(caption: [Structural display of an object library])[
  #screen(raw(read("../ex/file370/file-v-ar.txt")))
] <file370-v-ar>

=== Load Module Member

#idx("composite ESD")
file370 lists the records of the member, each with its offset in hexadecimal
(after #cmd("@")), its kind and its length in bytes. The kinds are
#cmd("CESD"), #cmd("IDR"), #cmd("SYM"), #cmd("scatter"), #cmd("control")
and #cmd("text")\; the control record that ends the module is marked
#cmd("(MODEND)"). The entries of the composite ESD follow, in the form
described in @file370-csects, and the summary line comes last.

#fig(caption: [Structural display of a load module member])[
  #screen(raw(read("../ex/file370/file-v-lmod.txt")))
] <file370-v-lmod>

=== IEBCOPY Unloaded Data Set

#idx("PDS directory", "load module attributes")
After the length of the IEBCOPY header, file370 shows each directory entry.
How it reads the user data of an entry depends on the kind of library given
in the heading.

In a load library each entry takes two lines. The first gives the member name, #cmd("(alias)") for an alias,
the TTR of the member, its entry point, its length (#cmd("modlen"), in
decimal), for an alias the name of the member it is an alias of, and the
attributes that are set, in brackets. The second line gives the attribute
bytes PDS2ATR1 and PDS2ATR2, the APF authorization code, the PDS2TTRT
field and, for an alias, the main entry point (PDS2EPM), in hexadecimal.
When the directory occupies more than one block, the number of blocks is
given before the number of entries.

#fig(caption: [Structural display of an IEBCOPY unloaded data set])[
  #screen(raw(read("../ex/file370/file-v-iebcopy.txt")))
] <file370-v-iebcopy>

The attributes are named as in @file370-attr-tab.

#tab(caption: [Load module attributes shown by file370])[
  #table(columns: (0.9in, 1fr),
    [Shown], [Attribute],
    [#cmd("RENT")], [reenterable],
    [#cmd("REUS")], [serially reusable],
    [#cmd("REFR")], [refreshable],
    [#cmd("OVLY")], [in overlay structure],
    [#cmd("TEST")], [linked with the TEST option],
    [#cmd("OL")], [only loadable],
    [#cmd("SCTR")], [scatter format],
    [#cmd("EXEC")], [executable],
    [#cmd("1BLK")], [a single text record and no RLD records],
    [#cmd("NRLD")], [no relocation data],
    [#cmd("AC=")#var("n")], [the APF authorization code],
  )
] <file370-attr-tab>

#idx("PDS directory", "ISPF statistics")
In a source library each entry takes one line: the member name and TTR,
followed by the ISPF statistics when the entry carries them (30 bytes of
user data): the version and modification level, the date and time of the
last change, the number of lines and the user ID, as in
#cmd("ispf v1.00 2026/277 00:00 7 lines TESTER"). The date is given as year
and day of the year. An entry with user data of another length shows
#cmd("userdata=")#var("n")#cmd(" bytes"). @file370-v-srcxmit shows a source
library written by xmit370.

=== XMIT File

#idx("XMIT", "control records")
file370 gives the number of control records and the number of data bytes,
and then each control record (#cmd("INMR01"), #cmd("INMR02"),
#cmd("INMR03"), #cmd("INMR06")) with the text units it decodes:

#deflist(width: 1.1in,
  [#cmd("INMDSNAM")], [the data set name],
  [#cmd("INMUTILN")], [the utility program],
  [#cmd("INMFNODE")], [the node that sent the file],
  [#cmd("INMFUID")], [the user that sent it],
  [#cmd("INMTNODE")], [the node it is sent to],
  [#cmd("INMTUID")], [the user it is sent to],
  [#cmd("INMFTIME")], [the time it was sent],
  [#cmd("INMNUMF")], [the number of files in the transmission],
  [#cmd("INMDSORG")], [the data set organization],
  [#cmd("INMRECFM")], [the record format],
  [#cmd("INMLRECL")], [the record length],
  [#cmd("INMBLKSZ")], [the block size],
  [#cmd("INMSIZE")], [the size of the data],
  [#cmd("INMDIR")], [the number of directory blocks],
)

Other text units are not shown. #cmd("INMRECFM") is shown by name with its
value in hexadecimal, for example #cmd("U (X'C002')") for a load library,
#cmd("FB (X'9000')") for a source library, #cmd("VS (X'4802')") for the
unloaded data set, and #cmd("VBS, transmission records (X'0001')") in
#cmd("INMR03"). When the data is an IEBCOPY unloaded data set, it follows
under #cmd("wrapped image:") in the form of @file370-v-iebcopy, however
large it is.

#fig(caption: [Structural display of an XMIT file])[
  #screen(raw(read("../ex/file370/file-v-xmit.txt")))
] <file370-v-xmit>

#fig(caption: [Structural display of a source library in an XMIT file])[
  #screen(raw(read("../ex/file370/file-v-srcxmit.txt")))
] <file370-v-srcxmit>

== Listing the Composite ESD <file370-csects>

#idx("file370", "--csects option")
#idx("composite ESD", "listing")
#cmd("--csects") lists the composite external symbol dictionary of a load
module member and nothing else. Each line gives the ESD identifier, the
name, the type and, by type:

#deflist(width: 1.1in,
  [#cmd("SD"), #cmd("PC"), #cmd("CM")], [the address and length of the
    section],
  [#cmd("LR")], [the address of the label and, as #cmd("owner"), the ESD
    identifier of the section that holds it. An LR entry is what an LD entry
    of an object module becomes in a load module.],
  [#cmd("ER"), #cmd("WX")], [nothing more: the reference was left
    unresolved],
  [#cmd("PR"), #cmd("Nul")], [a pseudo-register, and a deleted entry whose
    name remains],
)

#cmd("seg=")#var("n") gives the overlay segment. An entry with no name is
shown as #cmd("(blank)") when the name field holds blanks and as
#cmd("(null)") when it holds zeros. When the high-order bits of the type
byte are set, which a finished module should not have, the byte is shown as
#cmd("[typebyte ")#var("xx")#cmd("]").

#fig(caption: [The composite ESD of a load module member])[
  #screen(raw(read("../ex/file370/file-csects.txt")))
] <file370-v-csects>

=== JSON Output <file370-json>

#idx("file370", "--json option")
#cmd("--json") writes one JSON object for each file. Every object has the
members #cmd("file"), the name as given, and #cmd("format"), one of
#cmd("\"object deck\""), #cmd("\"ar370 archive\""),
#cmd("\"load module\""), #cmd("\"IEBCOPY unload\""), #cmd("\"XMIT\""),
#cmd("\"data\"") and #cmd("\"empty\""). For a load module member and
for an object module, the members #cmd("csects") and #cmd("count") follow,
in the same shape for both. Each element of #cmd("csects") has
#cmd("name") and #cmd("type"), and as the type requires:

#deflist(width: 1.6in,
  [sections (#cmd("SD"), #cmd("PC"), #cmd("CM"))], [#cmd("esdid"),
    #cmd("addr") and #cmd("len")],
  [#cmd("LR") in a load module], [#cmd("esdid"), #cmd("addr") and
    #cmd("owner"), the ESD identifier of the section that holds the label],
  [#cmd("LD") in an object module], [#cmd("addr") and #cmd("owner") but no
    #cmd("esdid"), since an LD entry has no ESD identifier of its own],
  [#cmd("ER"), #cmd("WX")], [#cmd("esdid") only],
)

A load module entry also carries #cmd("seg"), and #cmd("typebyte") when the
high-order bits of its type byte are set. Addresses and lengths are decimal
numbers, and strings are escaped as JSON requires.

For one file the output is that object. For several files it is a JSON
array of them, as in @file370-json-fig. A file that cannot be read is
reported on standard error and left out of the array.

#fig(caption: [JSON output for three files])[
  #screen(raw(read("../ex/file370/file-json.txt")))
] <file370-json-fig>

== Return Codes <file370-rc>

#idx("file370", "return codes")
When several files are named, file370 ends with the highest of the return
codes of @file370-rc-tab. A file that is not recognized therefore outranks
a file that could not be read.

#tab(caption: [file370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [Every file was recognized, or was empty. Warnings in a summary
      line do not change it.],
    [1], [A file could not be read. Its name and the reason are written to
      standard error.],
    [2], [A file was not recognized, an option was not known, or no file was
      named.],
  )
] <file370-rc-tab>

== Example <file370-example>

The files of @file370-summary-fig are those of the example of
@ar370-session, together with two transport forms that ld370 wrote: the
module #cmd("MAIN") was linked with #cmd("--rent --reus --alias ADD2"),
#cmd("sub1.o") was linked by itself with #cmd("--ac 1"), and the two were
packed with #cmd("ld370 --pack") into #cmd("demolib.iebcopy") and
#cmd("demolib.xmit"). #cmd("notes.txt") is a text file, and
#cmd("missing.o") does not exist.

#fig(caption: [One-line summaries and return codes])[
  #screen(raw(read("../ex/file370/file-summary.txt")))
] <file370-summary-fig>
