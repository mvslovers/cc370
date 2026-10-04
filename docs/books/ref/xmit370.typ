#import "../bookmaster/bookmaster.typ": *

= The xmit370 Command <xmit370>

#idx("xmit370")
The xmit370 command packs a directory of text files on the workstation into
a TSO TRANSMIT file that holds one partitioned data set with fixed-length
records: a sample library, a JCL library or a macro library. Each file
becomes a member. The file is received on MVS into a new library, and
RECEIVE takes the attributes of that library from the transmission itself.
#idx("TSO TRANSMIT")#idx("NETDATA")

xmit370 also lists the contents of a transmission and extracts its members
into files again.

The toolchain has two transmission writers. ld370 writes the transmission of
a load library, with record format U, as described in Chapter 3. xmit370
writes the transmission of a source library, with record format FB or F. The
container is the same in both cases: an IEBCOPY unloaded data set inside
NETDATA records, described in Appendix B. xmit370 is not called by cc370 or
by any other tool of the chain; you call it when a product has members other
than load modules to install.

== Invoking xmit370 <xmit370-invoke>

#idx("xmit370", "syntax")
#syntax(read("../syntax/xmit370-main.txt"))

#syntax(title: "Create:", read("../syntax/xmit370-create.txt"))

#syntax(title: "Extract:", read("../syntax/xmit370-extract.txt"))

#syntax(title: "Create option:", read("../syntax/xmit370-option.txt"))

The first operand is the subcommand. The options that follow may be given in
any order, before or after the file or directory operand.

=== Operands

#deflist(width: 1.5in,
  [#cmd("create")], [writes a transmission of the files in #var("dir") and
    of the files named by #cmd("--member"). #var("dir") may be omitted when
    at least one #cmd("--member") is given.],
  [#cmd("list")], [displays the control records of #var("file"), the
    attributes of the transmitted data set and its directory. See
    @xmit370-list.],
  [#cmd("extract")], [writes each member of #var("file") to a file of its
    own. See @xmit370-extract.],
  [#cmd("-o") #var("out-file")], [names the transmission to write. Required
    for #cmd("create").],
  [#cmd("--dsn") #var("dsname")], [is the name of the data set, recorded in
    the transmission as #cmd("INMDSNAM"). Required for #cmd("create"). Its
    first qualifier is also the default user ID (see @xmit370-stats).],
  [#var("dir")], [is the directory whose files become members. See
    @xmit370-members.],
  [#var("file")], [is the transmission to list or extract.],
  [#cmd("-C") #var("dir")], [names the directory into which #cmd("extract")
    writes the members. The default is the current directory. The directory
    must exist.],
  [#cmd("--lrecl") #var("n")], [sets the logical record length of the
    library, from 1 to 32760. The default is 80.],
  [#cmd("--blocksize") #var("n")], [sets the block size of the library. It
    must be a multiple of #cmd("--lrecl") and must not exceed 19069, the
    largest block that one 3350 track holds as a single record. The default
    is 3120, 39 records of 80 bytes.#idx("block size", "of a source library")],
  [#cmd("--recfm") #var("format")], [sets the record format: #cmd("fb"), the
    default, or #cmd("f"), in capitals or not. Other formats are refused.
    For #cmd("f"), give #cmd("--blocksize") equal to #cmd("--lrecl")\; xmit370
    does not check this and records whatever block size it is given.],
  [#cmd("--stats")], [writes ISPF statistics into each directory entry.
    This is the default.],
  [#cmd("--no-stats")], [leaves the statistics out.],
  [#cmd("--userid") #var("name")], [sets the user ID recorded in the
    statistics and in the control records. See @xmit370-stats.],
  [#cmd("--stats-date") #var("date")], [sets one date and time for every
    member and for the transmission itself. See @xmit370-stats.],
  [#cmd("--member") #var("name")#cmd("=")#var("file")], [adds #var("file")
    as member #var("name"). Repeat the option to add several members. See
    @xmit370-members.],
  [#cmd("--exclude") #var("pattern")], [skips the files of #var("dir") whose
    name matches #var("pattern"), a shell wildcard pattern matched against
    the file name without its directory. Quote it, so that the shell does not
    expand it. Repeat the option to give several patterns. It does not apply
    to the files named by #cmd("--member").],
  [#cmd("--tabs") #var("n")], [expands each tab character to the next
    multiple of #var("n") columns. The default is 8. #cmd("--tabs 0")
    refuses tab characters\; so does a value that is not a number.],
  [#cmd("--no-tabs")], [refuses tab characters, as #cmd("--tabs 0") does.],
  [#cmd("--latin1")], [translates bytes above #cmd("X'7F'") as Latin-1
    characters instead of refusing them. See @xmit370-chars.],
  [#cmd("-v"), #cmd("--verbose")], [for #cmd("create"), lists each member
    as it is packed, and the attributes of the library\; for #cmd("list"),
    adds the directory flag byte and the length of the user data to each
    member\; for #cmd("extract"), names each file written.],
  [#cmd("--help"), #cmd("-h")], [displays a summary of the options and
    ends.],
  [#cmd("--version"), #cmd("-V")], [displays the toolchain version and the
    commit from which xmit370 was built, for example
    #cmd("xmit370 1.2.0 (b17cd14)"), and ends. It is recognized only in
    place of the subcommand. Unlike as370, xmit370 uses #cmd("-v") for
    verbose output, not for the version.],
)

#note[The three subcommands share one option parser. An option that does
not apply to the subcommand, such as #cmd("-C") with #cmd("create") or
#cmd("--dsn") with #cmd("list"), is accepted and has no effect. The summary
from #cmd("--help") does not mention #cmd("-h"), #cmd("-V"),
#cmd("--version") or #cmd("--verbose").]

== How Files Become Members <xmit370-members>

#idx("member name", "derived from a file name")
xmit370 reads #var("dir") itself, not its subdirectories. For each file in
it:

- A name that begins with a period is skipped, and so is a file that
  matches an #cmd("--exclude") pattern.
- A subdirectory is skipped with a message. Other files that are not regular
  files are skipped without one.
- The member name is the file name without its last extension, in capitals,
  and cut to eight characters: #cmd("runhello.jcl") becomes
  #cmd("RUNHELLO"), and #cmd("verylongname.txt") becomes
  #cmd("VERYLONG"), without a message.
- The name must then be a valid member name: one to eight characters of
  #cmd("A")–#cmd("Z"), #cmd("0")–#cmd("9"), #cmd("@"), #cmd("#") and
  #cmd("$"), the first not a digit. A file whose name does not qualify is
  refused, and the message shows the #cmd("--member") option that would
  take it:

#screen(```
xmit370: t1/my-file: 'MY-FILE' is not a valid member name (1-8 of A-Z 0-9 @ # $, first not a digit); use --member NAME=t1/my-file
```)

#cmd("--member") #var("name")#cmd("=")#var("file") adds a file under a
name of your choosing. The name is used exactly as written, *without*
conversion to capitals, so write it in capitals. A name of more than eight
characters is refused\; a name of one to eight characters outside the valid
set is accepted with a warning, because existing libraries do contain such
names:

#screen(```
xmit370: warning: '1BAD' is not a standard member name (A-Z 0-9 @ # $); ISPF and TSO may not handle it
```)

Two files that give the same member name are an error, whichever way the
names were obtained. Because the extension is removed, #cmd("hello.asm") and
#cmd("hello.jcl") in one directory collide:

#screen(```
xmit370: duplicate member name HELLO (samplib/hello.asm and samplib/hello.jcl)
```)

The members are written in the collating order of their EBCDIC names, as in
any partitioned data set, so the order of the files in the directory does
not affect the transmission.

== Character Handling <xmit370-chars>

#idx("character set", "of a source library")
Each line of a file becomes one record. The line end marks the record
boundary and is not written: the newline character is not translated to
an EBCDIC newline as it is in a C program. xmit370 treats each line in this
order:

+ A carriage return before the line feed is removed, so a file with CRLF line
  ends gives the same records as one with LF line ends. A last line without
  a line end is a record like the others.
+ Tab characters are expanded to blanks (see #cmd("--tabs")). Columns matter
  in assembler language and in JCL, so a tab must become the blanks it
  stood for, not a single blank.
+ Trailing blanks are removed.
+ The line must then fit the logical record length. A longer line is an
  error.
+ The characters are translated to EBCDIC code page 037, with the same table
  that cc370 and as370 use: for example #cmd("[") becomes #cmd("X'BA'") and
  #cmd("]") becomes #cmd("X'BB'").
+ The record is padded with EBCDIC blanks, #cmd("X'40'"), to the logical
  record length.

A character that cannot be written is an error, never a substitution. The
message names the file, the line and the column, as in @xmit370-refused.
Each line is reported once, at its first error. #cmd("create") reports up
to eight errors for each file, followed by a line such as
#cmd("t11/many: ... and 2 more error(s)"), checks every file, and then
writes no transmission.

#fig(caption: [Characters that xmit370 refuses])[
  #screen(```
t1/ctl:1:4: control character 0x01 in a text member (binary content cannot be a fixed-length text member)
t1/latin:1:4: byte 0xE9 is outside ASCII (pass --latin1 to map it through CP037)
t1/longline:1:81: line is 81 columns, exceeds LRECL 80
t1/utf8:1:4: file is UTF-8; this character has no EBCDIC equivalent -- use plain ASCII here
xmit370: 4 error(s), no output written
```)
] <xmit370-refused>

A control character (below #cmd("X'20'"), and #cmd("X'7F'")) other than the
tab is refused: a file that contains one is not text. For a byte above
#cmd("X'7F'") the message depends on the whole file:

- If the file is valid UTF-8, the byte is part of a character that an editor
  wrote in UTF-8, such as a dash or an arrow, and the file should be changed
  to plain ASCII. A byte order mark at the start of the file is such a
  character too.
- Otherwise the bytes are taken to be Latin-1 characters, which code page 037
  can represent. #cmd("--latin1") translates them. This is the usual case for
  text that came out of an EBCDIC data set, for example #cmd("¬") in a
  macro.

#note[#cmd("--latin1") applies to every file and is not checked against
the UTF-8 test: a UTF-8 file packed with #cmd("--latin1") is accepted
without a message, and each of its multi-byte characters becomes two or
three wrong characters on MVS.]

All members of one transmission share one logical record length, so a
library whose lines are longer than 80 columns needs #cmd("--lrecl") and a
#cmd("--blocksize") that is a multiple of it.

== ISPF Statistics and Reproducible Output <xmit370-stats>

#idx("ISPF statistics")
Unless #cmd("--no-stats") is given, each directory entry carries the 30
bytes of statistics that the ISPF editor keeps for a member, so that ISPF and
other programs show the member with a date, a size and an owner. xmit370
writes:

- version 1, modification level 0;
- the same date and time as the creation and the last change;
- the number of lines as both the current and the initial size (up to
  65535), and zero changed lines;
- the user ID.

#idx("xmit370", "--userid option")
The user ID is the #cmd("--userid") value, cut to eight characters and used
as written, so give it in capitals. Without #cmd("--userid") it is the first
qualifier of #cmd("--dsn"), cut to eight characters and in capitals:
#cmd("--dsn user1.hello.samplib") gives #cmd("USER1"). The same user ID is
recorded as the sender and the receiver of the transmission
(#cmd("INMFUID"), #cmd("INMTUID")), with #cmd("ORIGNODE") as both nodes.

The date and time of each member are the time its file was last modified.
The transmission also records when it was made (#cmd("INMFTIME")), which is
the current time. Two transmissions made from the same files therefore
differ.

#idx("reproducible output")
#cmd("--stats-date") replaces all of these times with one:
#var("yyyy")#cmd("-")#var("mm")#cmd("-")#var("dd"), optionally followed by
#cmd("T") or a blank and #var("hh")#cmd(":")#var("mm"), with or without
#cmd(":")#var("ss"). The time defaults to midnight. With
#cmd("--stats-date"), the transmission depends only on the contents and the
names of the files and on the options: it is identical byte for byte from
one run to the next, whatever the modification times of the files and the
time zone of the workstation. Give it when the transmission is a release
artifact that must be reproducible.

#note[A date that is out of range is not refused but carried over:
#cmd("2026-13-45") is taken as 14 February 2027. Only text that does not
have the form of a date is refused.]

== Attributes of the Transmitted Library <xmit370-dcb>

#idx("DCB", "of a transmitted library")
#idx("RECEIVE", "allocation of the library")
The transmission describes the library it holds, and the receiving side
uses that description: when RECEIVE allocates the new data set without
being given attributes, it takes them from the transmission. The library is
then created on MVS as xmit370 described it. @xmit370-attr lists the
attributes and where they come from.

#tab(caption: [Attributes recorded in the transmission])[
  #table(columns: (1.15in, 1fr),
    [Attribute], [Value],
    [DSORG], [#cmd("PO"), always.],
    [RECFM], [#cmd("FB"), or #cmd("F") with #cmd("--recfm f").],
    [LRECL], [#cmd("--lrecl"), default 80.],
    [BLKSIZE], [#cmd("--blocksize"), default 3120.],
    [Directory blocks], [The number of 256-byte directory blocks the members
      need, plus five, and at least 10.],
    [Data set name], [#cmd("--dsn").],
  )
] <xmit370-attr>

The attributes appear twice in the transmission: in the first #cmd("INMR02")
control record, which RECEIVE reads, and in the header of the IEBCOPY
unloaded data set, which IEBCOPY reads when it loads the members. xmit370
writes the same values to both. #cmd("list") shows both, as in
@xmit370-list-fig.

Because #cmd("--blocksize") becomes the block size of the library on MVS,
choose it for the library you want there. The default of 3120 is a common
block size for libraries of 80-byte records.

A directory entry takes 42 bytes with statistics and 12 without, so a
directory block holds 6 members with statistics and 21 without, and the
last block, which also holds the end of the directory, 5 and 20. For
example, 36 members with statistics need seven directory blocks, and the
transmission asks for 12\; without statistics they need two, and it asks
for 10.

Within each member the records are packed into blocks of #cmd("--blocksize")
bytes. The last block of a member is short, not padded.

== Installing a Transmission on MVS <xmit370-mvs>

#idx("RECEIVE")#idx("RECV370")
A transmission consists of 80-byte records, and its length is always a
multiple of 80. To install it:

+ Transfer the file to MVS in binary, into a sequential data set with
  #cmd("RECFM=FB") and #cmd("LRECL=80"). It must not be translated from
  ASCII to EBCDIC: it is EBCDIC already.
+ Receive it into a new library with the TSO RECEIVE command, or with the
  RECV370 batch program. Give the new library a name and, where the system
  requires them, a volume and space, but *no record format, record length
  or block size*. The library is then allocated with the attributes of
  @xmit370-attr.

With the RECEIVE command of NJE38, which provides TSO TRANSMIT and RECEIVE on
MVS 3.8j, the second step is one command:

```
RECEIVE INDSN('USER1.HELLO.XMIT') DATASET('USER1.HELLO.SAMPLIB')
```

IEBCOPY reports each member it loads with message #cmd("IEB154I"). In
batch, RECV370 does the same. The job below receives the transmission
#cmd("USER1.HELLO.XMIT")\; RECV370 must be in the link list or in a
#cmd("STEPLIB") library. #cmd("SYSUT2") has no #cmd("DCB") parameter, for
the reason given above:

```
//RECV    EXEC PGM=RECV370
//RECVLOG  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//XMITIN   DD DSN=USER1.HELLO.XMIT,DISP=SHR
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(5,1)),DISP=(NEW,DELETE)
//SYSUT2   DD DSN=USER1.HELLO.SAMPLIB,DISP=(,CATLG),UNIT=SYSDA,
//            SPACE=(CYL,(1,1,20),RLSE)
```

#note[A #cmd("DCB") on #cmd("SYSUT2"), or a library allocated in advance,
takes the place of the attributes of the transmission. A return code of 0
does not show which attributes the library received: after the first
installation, check the attributes and list the members of the library.]

== Listing a Transmission <xmit370-list>

#idx("xmit370", "list subcommand")
#cmd("list") shows a transmission in three parts, as in @xmit370-list-fig:

- Each control record, #cmd("INMR01") to #cmd("INMR06"), with the text units
  it carries: the user IDs and nodes, the time of the transmission, and for
  each #cmd("INMR02") the utility, the size and the attributes. A record
  format that list does not decode is shown as #cmd("?").
- The header of the unloaded data set and the attributes it records for the
  library (#cmd("source DCB")), with the block size of the unloaded form in
  parentheses: the library block size plus 20, and at least 296.
- Each member with its relative address (#cmd("TTR")), its size in bytes
  and, when the entry has them, its statistics: the version and
  modification level, the date as year and day of the year, the time, the
  number of lines and the user ID.

#cmd("list") and #cmd("extract") take the track geometry from the header
of the unloaded data set, not from a fixed device, so they also read the
transmissions of load libraries that ld370 writes and transmissions made by
TSO TRANSMIT.

== Extracting the Members <xmit370-extract>

#idx("xmit370", "extract subcommand")
#cmd("extract") writes each member to a file in the #cmd("-C") directory.
The file name is the member name, with no extension. A file of the same
name is replaced.

- A member of a library with record format F or FB is written as text: each
  record becomes one line, translated from EBCDIC with the table of
  @xmit370-chars, without its trailing blanks and ended by a line feed.
- A member of any other library, such as a load module from ld370, is
  written unchanged as the bytes of its records. That file is for
  inspection only: the entry point and attributes of a load module are in
  its directory entry, which the file does not contain, so ld370 cannot
  pack it again.

A text file comes back from #cmd("create") and #cmd("extract") identical
to the original if its lines end in a line feed, have no trailing blanks and
contain no tabs. Otherwise it comes back as #cmd("create") changed it: CRLF
line ends become LF, tabs become blanks, trailing blanks are gone, and a
last line without a line end receives one.

== Return Codes <xmit370-rc>

#idx("xmit370", "return codes")
@xmit370-rc-tab lists the return codes. When #cmd("create") ends with a
code other than 0, it has not written the transmission.

#tab(caption: [xmit370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The subcommand completed.],
    [1], [A file or directory could not be read, a file name was not a
      valid member name, a line could not be translated (see
      @xmit370-refused), or #cmd("extract") could not write a member. A
      file given to #cmd("list") or #cmd("extract") that is not a
      transmission also ends with 1, with no message.],
    [2], [The command was in error and nothing was done: no subcommand, an
      unknown subcommand or option, a missing #cmd("-o") or #cmd("--dsn"),
      an option value out of range, a malformed #cmd("--member"), two
      files with the same member name, or no members at all.],
  )
] <xmit370-rc-tab>

== Example <xmit370-example>

The directory #cmd("samplib") holds three files: an assembler program, a
member of parameters with a blank line, and a job. They are shown in
@xmit370-files.

#fig(caption: [The files of the sample library])[
  #grid(columns: (1fr,), row-gutter: 0.8em,
    [#cmd("samplib/hello.asm")],
    code(read("../ex/xmit370/samplib/hello.asm")),
    [#cmd("samplib/parms")],
    code(read("../ex/xmit370/samplib/parms")),
    [#cmd("samplib/runhello.jcl")],
    code(read("../ex/xmit370/samplib/runhello.jcl")),
  )
] <xmit370-files>

@xmit370-create-fig packs the directory for the library
#cmd("USER1.HELLO.SAMPLIB"). #cmd("--stats-date") and #cmd("--userid") make
the transmission, and therefore the figures below, the same on every run.

#fig(caption: [Creating the transmission])[
  #screen(raw(read("../ex/xmit370/create.txt")))
] <xmit370-create-fig>

@xmit370-list-fig lists the transmission. The library will be allocated as
#cmd("PO"), #cmd("FB"), 80, 3120, with 10 directory blocks. The size of each
member is its number of lines times 80 bytes.

#fig(caption: [Listing the transmission])[
  #screen(raw(read("../ex/xmit370/list.txt")))
] <xmit370-list-fig>

@xmit370-extract-fig extracts the members again and compares them with the
original files. The member #cmd("PARMS") keeps its blank line: a blank
record becomes an empty line.

#fig(caption: [Extracting and comparing the members])[
  #screen(raw(read("../ex/xmit370/extract.txt")))
] <xmit370-extract-fig>
