#import "../bookmaster/bookmaster.typ": *

= The ld370 Command <ld370>

#idx("ld370")
#idx("linkage editor")
The ld370 command is the linkage editor of the toolchain. It reads object
modules, resolves the references between them, searches object libraries
for the modules a program needs but does not supply, and writes the result
as a load module: one member of a load library, in the record format that
program fetch reads on MVS. It takes the place of the MVS linkage editor
(IEWL) and runs on the workstation.
#idx("IEWL", "compared with ld370")

A load module cannot be copied to MVS as an ordinary file, because a load
library is a partitioned data set with undefined-length records. ld370
therefore also writes the module in two transport formats: the unloaded form
that IEBCOPY writes, and a TSO TRANSMIT file that holds that unloaded form.
The TRANSMIT file is uploaded to MVS and received into a load library;
@ld370-transport describes how.

ld370 is the last step of the chain cc370, as370, ld370. The cc370 driver
runs it for you when you compile and link a C program in one command (see
@cc)\; you call it yourself to link assembler programs, to choose
attributes or aliases, or to pack several modules into one library.

== What ld370 Produces <ld370-output>

#idx("load module", "written by ld370")
A link writes one load module member to the file named by #cmd("-o"), or to
#cmd("a.out") when #cmd("-o") is omitted. The file holds the records of the
member in the order program fetch expects them:

- the composite external symbol dictionary (CESD): one entry for each
  control section, each entry point and each external reference left
  unresolved\;
- two identification records (IDRs), described in @ld370-idr\;
- the text of the module, in pairs of a control record and a text record\;
- the relocation dictionary, when the module contains address constants.

The member file is always written. The options #cmd("-iebcopy") and
#cmd("-xmit") add the transport files beside it, named after the
#cmd("-o") file with #cmd(".iebcopy") or #cmd(".xmit") appended:
#cmd("-o build/app.lm -xmit") writes #cmd("build/app.lm") and
#cmd("build/app.lm.xmit").

#idx("directory entry")
Some properties of a load module are not stored in the member at all but in
its entry in the library directory: the entry point, the module length, the
attributes, such as reentrant, and the authorization code. A member file
has no directory, so these properties exist only in the transport files.
*Two links that differ only in these properties write identical member
files.* Keep this in mind when you compare outputs, and see @ld370-pack for
what it means when a member file is packed later.

== Invoking ld370 <ld370-invoke>

#idx("ld370", "syntax")
ld370 has three forms. The first links object modules into a load module:

#syntax(read("../syntax/ld370-main.txt"))

#syntax(title: "Link option:", read("../syntax/ld370-option.txt"))

The second, described in @ld370-pack, packs load modules that are already
linked into one transport file, without linking:

#syntax(read("../syntax/ld370-pack.txt"))

#syntax(title: "Pack option:", read("../syntax/ld370-packopt.txt"))

The third displays the version or a summary of the options:

#syntax(read("../syntax/ld370-version.txt"))

Options and input files may be given in any order, with one exception: a
#cmd("-l") option is resolved when it is read, so the #cmd("-L") directories
it is to search must come before it.

An operand that begins with #cmd("-") and is not an option is refused with
#cmd("ld370: unknown option '")#var("operand")#cmd("' (ld370 --help)"), and an
option that needs a value but is the last operand with
#cmd("ld370: -e needs a value")\; both end with return code 2. Called with no
input files, ld370 writes the usage summary to standard error and ends with
return code 2.

=== Operands

#deflist(width: 1.45in,
  [#var("object-file")], [is an object module written by as370, by cc370
    with #cmd("-c"), or by the MVS assembler. Object modules are placed in
    the module in the order given. A file that is not an object module, that
    is, not a sequence of 80-byte records each beginning with #cmd("X'02'")
    and ending with an END record, is refused with
    #cmd("ld370: ")#var("file")#cmd(" is not an object deck") and the
    reason, return code 1, and no member is written.],
  [#var("library-file")], [is an object library written by ar370. An
    operand is taken as a library when its name ends in #cmd(".a"). A library
    is not included as a whole\; it is searched by the automatic library
    call (see @ld370-autocall).],
  [#cmd("-o") #var("file")], [names the member file to write. The default is
    #cmd("a.out").],
  [#cmd("--name") #var("member")], [sets the member name used in the
    directory of the transport files. Without it, the name is taken from the
    #cmd("-o") file: the base name up to its first period. Either name is
    changed to uppercase. When the name is used, that is with
    #cmd("-iebcopy"), #cmd("-xmit") or #cmd("--map"), it must be a valid
    member name, one to eight characters as described for aliases in
    @ld370-alias\; otherwise ld370 ends with return code 2. A name is never
    cut to eight characters.],
  [#cmd("-e"), #cmd("--entry") #var("symbol")], [sets the entry point to
    #var("symbol"), the name of a control section or an entry point in the
    module. See @ld370-entry. With #cmd("--pack") it names the entry point
    of the member files packed (see @ld370-pack).],
  [#cmd("-L") #var("directory")], [adds #var("directory") to the
    directories searched by the #cmd("-l") options that follow it. The
    directory may also be attached: #cmd("-Llib").],
  [#cmd("-l") #var("name")], [searches for the library
    #cmd("lib")#var("name")#cmd(".a"), first in the #cmd("-L") directories
    given so far, in the order given, and then in the current directory, and
    uses the first one found. The name may also be attached: #cmd("-lc").],
  [#cmd("-i"), #cmd("--include") #var("name")], [includes a module from a
    library whether or not anything refers to it, as the #cmd("INCLUDE")
    statement of IEWL does. See @ld370-autocall.],
  [#cmd("--allow-unresolved")], [writes the module even when external
    references remain unresolved. They are listed, and their address
    constants are left zero.],
  [#cmd("--warn-shadow")], [also reports a symbol that a later library
    defines again. See @ld370-autocall.],
  [#cmd("--alias") #var("name")], [adds an alias for the member. Repeat the
    option for several aliases. See @ld370-alias.],
  [#cmd("--rent"), #cmd("--reus"), #cmd("--refr")], [mark the module
    reentrant, reusable or refreshable. See @ld370-attr.],
  [#cmd("--norent"), #cmd("--noreus")], [state that the module is not
    reentrant or not reusable. A module declares neither attribute by
    default, so they are accepted and change nothing on their own. Given together with #cmd("--rent") or
    #cmd("--reus") respectively, they are refused.],
  [#cmd("--ac") #var("code")], [sets the APF authorization code, as
    #cmd("SETCODE AC(")#var("code")#cmd(")") does: a number from 0 to 255.
    The default is 0.],
  [#cmd("--blocksize") #var("bytes")], [names the block size of the load
    library the module is going to, a number from 1024 to 32740. The default
    is 15040. See
    @ld370-blksize.],
  [#cmd("--sparse-text")], [leaves out text records that no part of the
    input defined. See @ld370-sparse.],
  [#cmd("--map") #var("file")], [writes a load map to #var("file"), or to
    standard output when #var("file") is #cmd("-"). See @ld370-map.],
  [#cmd("--xref")], [adds the cross-reference to the load map. It requires
    #cmd("--map").],
  [#cmd("-iebcopy")], [also writes the module as an IEBCOPY unloaded
    library to #var("file")#cmd(".iebcopy").],
  [#cmd("-xmit")], [also writes the module as a TSO TRANSMIT file to
    #var("file")#cmd(".xmit").],
  [#cmd("--dsn") #var("data-set-name")], [sets the data set name recorded
    in the TRANSMIT file. The default is #cmd("IBMUSER.HOST.LOAD").],
  [#cmd("-v"), #cmd("--verbose")], [traces the phases of the link on
    standard error, one line each, beginning with #cmd("[ld370]"): the
    objects read, the modules taken from libraries, the origin of each
    section, the counts of sections, entry points (LR) and unresolved
    references (ER) in the CESD, and each relocated address constant.],
  [#cmd("--pack")], [selects the second form. See @ld370-pack.],
  [#cmd("-h"), #cmd("--help")], [writes a summary of the options to
    standard output and ends with return code 0.],
  [#cmd("-V"), #cmd("--version")], [displays the toolchain version and the commit from
    which ld370 was built, for example #cmd("ld370 1.4.0 (2821ebb)"), and
    ends.],
)

== Building the Module <ld370-layout>

#idx("load module", "layout")
ld370 places the object modules one after another, each on a doubleword
boundary, in the order in which they were read: first the object files from
the command line, then the modules named by #cmd("--include"), then the
modules taken by the automatic library call. Within an object module the
sections keep the positions the assembler gave them. The module length is
rounded up to a multiple of eight. A module longer than 16 MB is refused.

Each address constant is then relocated to the final address of the symbol
it names, and an entry in the relocation dictionary is written for it, so
that program fetch can relocate it again when the module is loaded.

#idx("doubly defined symbol")
When two object modules define the same name, the first definition is kept:

- An entry point defined a second time is reported with a warning, and every
  reference goes to the first definition.
- A control section defined a second time is dropped, together with its
  text and its address constants, and the sections after it in the same
  object module move up to close the gap. IEWL does the same, without a
  message\; ld370 writes a note, #cmd("ld370: note: CSECT ADD1 defined
  again in add1b.o; the first definition is kept and this one dropped, as
  IEWL does"), and the link ends with return code 0.

#idx("unresolved reference")
An external reference that nothing defines ends the link with return code 1.
ld370 lists the names and writes no member: the address constant would be
zero, and the program would fail at the first call through it. With
#cmd("--allow-unresolved") the names are listed and the module is written.

#idx("common section", "in ld370")
Common sections (#cmd("COM"), see @apx-objfmt-pr) are allocated as IEWL
allocates them: one area for each name, as long as the longest of the
sections of that name, placed after all the object modules, each on a
doubleword boundary, in the order in which the names first appear. A common
area has no text, but it counts in the module length. The map lists each
with type #cmd("CM") and #cmd("(common, longest contribution)") as its
source.

#idx("external dummy section", "in ld370")
#note[ld370 does not yet resolve external dummy sections. The map lists
them among the unresolved names, the link still ends with return code 0,
the #cmd("Q")-type constants and #cmd("CXD") fields stay zero, and their
relocation items are written with the unresolved flag. Do not link modules
that use #cmd("DXD"), #cmd("CXD") or #cmd("Q")-type constants with ld370
yet.]

== Automatic Library Call <ld370-autocall>

#idx("automatic library call")
#idx("object library", "search by ld370")
When the object modules refer to a symbol that none of them defines, ld370
searches the libraries for a module that does, and includes it. That module
may refer to further symbols, which are searched in turn, until no
reference can be resolved from the libraries any more. The libraries are
those given by #cmd("-l") and those named as files ending in #cmd(".a"), at
most 32 in one link.

The search uses the symbol index that ar370 writes into every library (see
@ar370). The index lists the control sections _and the entry points_ of each
member, so a reference to an entry point inside a library module is resolved
as readily as a reference to a section. A C function is an entry point of its
compilation unit, so this is how calls into the C library are resolved.

The libraries are searched in the order they were given, and the first that
defines the symbol is used. When a library holds several members that define
the symbol, ld370 prefers a member that does not define again a symbol that
the link already has. A definition that is passed over is reported with a
warning:

- always, when it is in the same library, because then the order of the
  members decides, which is seldom intended\;
- only with #cmd("--warn-shadow"), when it is in a later library. A later
  library usually provides fallbacks, and IEWL is silent in that case too.

#idx("weak external reference", "in automatic library call")
A weak external reference, type #cmd("WX") (#cmd("WXTRN") in assembler), is
not searched for. It is resolved when a module that is part of the link for
another reason defines the name\; otherwise it stays 0, is listed under
#cmd("UNRESOLVED") in the load map, and does not fail the link.

#idx("INCLUDE", "--include option")
#cmd("--include") #var("name") takes a module from the libraries before the
search begins, whether or not anything refers to it. ld370 looks for a member
whose file name, without #cmd(".o"), is #var("name") in any mix of case, and
then for a member that defines #var("name"). Use it to choose one of several
variants of a module, for example a different C start-up routine, before the
search can pick another.

== The Entry Point <ld370-entry>

#idx("entry point", "of a load module")
The entry point is taken, in this order of priority:

+ from #cmd("--entry") #var("symbol"). When no module of the link defines
  #var("symbol") after the library search, ld370 looks it up in the
  libraries by name and includes the module that defines it. A name that is
  still not defined ends the link with return code 1.
+ from the END record of the first object module that names an entry point,
  as #cmd("END MAIN") does in assembler language\;
+ otherwise, the beginning of the module.

A C program enters at #cmd("@@CRT0"), the start-up routine of the C library,
not at the #cmd("@@MAIN") stub that the compiler names on the END record.
The cc370 driver passes #cmd("--entry @@CRT0") when it links\; when you link
a C program yourself, pass it too. With libc370 2.3.0 or later,
#cmd("@@CRT0") is a member of #cmd("libc.a") and comes into the module by
automatic library call, after the object modules named on the command line.
It is then not at offset 0\; the directory entry records where it is, and
the first line of the load map shows it.

== Module Attributes <ld370-attr>

#idx("attributes", "of a load module")
#idx("RENT")#idx("REUS")#idx("REFR")
The attributes are stored in the directory entry and reach MVS only through
the transport files. @ld370-attr-tab lists the ones the options set. *A
module is neither reentrant nor reusable unless you say so*, which is also the
default of IEWL. Each option sets exactly the attribute it names:
#cmd("--rent") does not imply #cmd("--reus"), so give both for what IEWL
calls #cmd("RENT").

#tab(caption: [Attributes set by ld370 options])[
  #table(columns: (1.3in, 1fr),
    [Option], [Effect],
    [#cmd("--rent")], [Marks the module reentrant. Give it only for a module
      that does not change its own storage. A C program compiled by cc370
      keeps its static variables in the module, so it is not reentrant if
      it changes them.],
    [#cmd("--reus")], [Marks the module serially reusable.],
    [#cmd("--refr")], [Marks the module refreshable.],
    [#cmd("--ac") #var("code")], [Sets the authorization code. A module that
      is to run authorized needs #cmd("--ac 1") and must be in an
      APF-authorized library.],
  )
] <ld370-attr-tab>

The other attribute bits, such as executable, follow from the module itself
and are set by ld370.

== Aliases <ld370-alias>

#idx("alias", "of a load module")
#cmd("--alias") #var("name") adds a second directory entry for the member,
under #var("name"), as the IEWL #cmd("ALIAS") statement does. The entry point
of an alias follows the IEWL rule: an alias that is the name of a section or
entry point in the module enters there\; any other alias enters where the
member does. So an alias spelled like an entry point inside the module does
not start the program at its main entry.

An alias name has one to eight characters, the first a letter or one of
#cmd("@"), #cmd("#") and #cmd("$"), the others letters, digits or the same
three characters. A name may appear only once in a library, as a member or as
an alias\; a second use, and an alias that is the name of the member
itself, are refused with return code 2. A member file has no directory, so an
alias given without #cmd("-iebcopy") or #cmd("-xmit") has no effect, and
ld370 warns.

== Block Size <ld370-blksize>

#idx("block size", "--blocksize option")
A load library has a block size, and no record of a module may be longer
than the block size of the library it is stored in. #cmd("--blocksize")
#var("bytes") names that block size\; the value must be between 1024 and
32740. It decides:

- the length of the text records. ld370 splits the text into records no
  longer than the largest of the IEWL text record lengths 18432, 13312,
  12288, 7680, 6144, 5120, 4096, 3072, 2048 and 1024 that does not exceed
  #var("bytes"), as @ld370-blksize-tab shows\;
- the block size that the transport files record for the library, and the
  block size of the unloaded form, which is #var("bytes") + 20.

#tab(caption: [Longest text record for some block sizes])[
  #table(columns: (1.3in, 1.5in, 1fr),
    [#cmd("--blocksize")], [Longest text record], [Library],
    [6144], [6144], [a small or older device],
    [15040], [13312], [the default],
    [19069], [18432], [a full 3350 track],
    [32000], [18432], [],
  )
] <ld370-blksize-tab>

A module built for a block size fits every library whose block size is at
least as large. The default of 15040 therefore fits libraries of 15040 and of
19069 alike.

#note[Use the same value when you build a module and when you pack it.
#cmd("--pack") does not split records again, and it refuses a module with a
record longer than its own #cmd("--blocksize"), naming the member and the
record length.]

== Sparse Text <ld370-sparse>

#idx("--sparse-text option")
A #cmd("DS") statement reserves storage without defining its content, and the
object module carries no text for it. ld370 nevertheless writes that storage
into the load module as zeros, as IEWL does. With #cmd("--sparse-text") a
text record that no part of the input defined is left out, which can make a
module with large reserved areas much smaller: a section that reserves 40000
bytes with #cmd("DS") becomes a member of 13721 bytes instead of 40385.

The option is off by default, for two reasons. The module is no longer the
one IEWL would write. And the reserved storage then holds whatever program
fetch leaves in it: the module relies on fetch providing zeros for the
records that are not there, and a C program relies on its static storage
starting at zero.

== The Load Map <ld370-map>

#idx("load map")
#cmd("--map") #var("file") writes a load map after the member has been
written. It lists every section in the order of its origin, with its type,
origin, length and the input it came from: the object file as named on the
command line, or #var("library")#cmd("(")#var("member")#cmd(")") followed by
#cmd("include") or #cmd("autocall"). The entry points of each section follow
it, indented, and unresolved names are listed at the end. The first line
gives the member name, the entry point and where it came from, and the module
length.

#cmd("--xref") adds, under each section, every address constant that names
an external symbol or a common section: its offset in the section, its type (#cmd("A") or
#cmd("V")), the symbol, and the address and section it resolved to, or
#cmd("unresolved").

The map does not follow the IEWL format. It carries no date, time or page
headings, so that the maps of two links can be compared line by line with
#cmd("diff"). @ld370-map-fig shows the map of the program in @ld370-ex,
with the cross-reference.

#fig(caption: [Load map with cross-reference])[
  #screen(raw(read("../ex/ld370/xref.txt")))
] <ld370-map-fig>

== Transport to MVS <ld370-transport>

#idx("transport files")
#idx("IEBCOPY", "unloaded form")
#idx("TRANSMIT", "file written by ld370")
#cmd("-iebcopy") writes the module as IEBCOPY writes a load library when it
unloads it: a sequential image of the library, with its directory and the
records of each member. #cmd("-xmit") wraps that image into a TSO TRANSMIT
(NETDATA) file of 80-byte fixed-length records. The TRANSMIT file is the one
to send to MVS: a file of fixed-length records can be uploaded byte for
byte, where the variable-length records of the unloaded image cannot.

The TRANSMIT file records, for the receiving side, the data set name given by
#cmd("--dsn"), the organization of a load library (partitioned, record format
U) with the block size given by #cmd("--blocksize"), and the space the
library needs. Its header also names the sending and receiving node and user
as #cmd("ORIGNODE"), #cmd("IBMUSER"), #cmd("IBMUSER") and #cmd("DUMMY"), as
the TRANSMIT file it was checked against does\; #cmd("RECEIVE") does not use
these fields. To install the module:

+ Upload the #cmd(".xmit") file in binary to a sequential data set with
  #cmd("RECFM=FB") and #cmd("LRECL=80"), for example through the mvsMF REST
  API or FTP. No character translation may take place.
+ Receive it with the TSO #cmd("RECEIVE") command, at a terminal or in a
  batch TSO step (#cmd("PGM=IKJEFT01")):
  ```
  RECEIVE INDSN('USER1.APP.XMIT') DATASET('USER1.APP.LOADLIB')
  ```
  #cmd("DATASET") names the load library to create, in place of the name
  recorded by #cmd("--dsn"). #cmd("RECEIVE") allocates the library from the
  attributes recorded in the file, which is why #cmd("--blocksize") must
  describe the library you want.
+ Run the program from that library, for example through the
  #cmd("STEPLIB") of the job. A module linked with #cmd("--ac 1") runs
  authorized only from an APF-authorized library.

#note[Receive into a library that does not exist yet. To replace the modules
of an existing library, delete it first, or receive into a new library and
copy the members with IEBCOPY.]

The mbt build tool performs these steps with #cmd("make deploy"): it packs
the modules of a project into one TRANSMIT file, uploads it and receives it.

== Packing Several Members <ld370-pack>

#idx("--pack option")
#idx("load library", "with several members")
#cmd("--pack") builds a transport file from modules that are already linked,
without linking them again. With several modules it makes a library of
several members, which is how a whole project is sent to MVS in one file. The
output is the TRANSMIT file, #var("name")#cmd(".xmit"), unless
#cmd("-iebcopy") is given\; #cmd("-o") #var("name") is required.

Each #var("file") is one of two kinds:

- *The #cmd(".iebcopy") file of a single module*, written by a link with
  #cmd("-iebcopy"). It carries the directory entry of the module, and the
  whole entry is kept: entry point, length, attributes, authorization code
  and aliases. The member name is the one in that directory.
- *A member file*, written by #cmd("-o"). It carries no directory, so
  ld370 takes what it can from the member itself and the rest from the
  #cmd("--pack") command:
  - The module length is computed from the CESD.
  - The entry point is the address that the CESD of the member gives to
    #cmd("--entry") #var("symbol"), or, without #cmd("--entry"), to
    #cmd("@@CRT0"), the start-up routine of a C program. The name may be a
    control section or an entry point. A name that the CESD does not hold,
    or holds more than once, ends the pack with return code 1. A member
    without #cmd("@@CRT0"), such as an assembler program, is packed with
    entry point 0.
  - The attributes and the authorization code are those given on the
    #cmd("--pack") command, and the member has no aliases.

  ld370 warns about every such file and says where the entry point came
  from, for example (one line, shown here on two):
  ```
  ld370: warning: 'B' is a bare load module: packing B at entry 000026
    (--entry), AC 0, neither RENT nor REUS
  ```
  The entry point is given as six hexadecimal digits. The member name is the base name
  of the file without its extension, in uppercase.

#var("member")#cmd("=")#var("file") gives the member a name of your own\; a
renamed #cmd(".iebcopy") module keeps its aliases, which then point at the
new name.

*Pack the #cmd(".iebcopy") file of each module, not its member file.* Its
directory entry is the one the link wrote, whatever the module contains. The
options of the #cmd("--pack") command do not change it: #cmd("--entry") is
reported with #cmd("ld370: warning: --entry does not apply to '")#var("file")#cmd("'")
and the entry point of the directory is kept, and the attribute options apply
only to member files. One #cmd("--entry") applies to every member file of the
pack, so packing member files with different entry points takes one
#cmd("--pack") command each, or their #cmd(".iebcopy") files. The usual
sequence is therefore:

```
ld370 -o MAIN --name MAIN main.o -L. -ldemo -iebcopy --rent --reus
ld370 -o ADDER --name ADDER add1.o -iebcopy -e ADD2 --ac 1
ld370 --pack MAIN.iebcopy ADDER.iebcopy -o mylib
```

which writes #cmd("mylib.xmit"), a library with the members #cmd("ADDER") and
#cmd("MAIN"), each with its own entry point, attributes and authorization
code. A name used twice in one pack, as a member or as an alias, is refused
with return code 2.

Some link options have no place in a pack:

- #cmd("--alias"), #cmd("--map"), #cmd("--name") and #cmd("--include") are
  refused with return code 2. A packed member is named with
  #var("member")#cmd("=")#var("file")\; its aliases come from its
  #cmd(".iebcopy") file.
- #cmd("--sparse-text"), #cmd("--allow-unresolved") and
  #cmd("--warn-shadow") are ignored with a warning, since a pack neither
  shapes text, nor resolves references, nor searches libraries.

A #var("file") that is not a load module is refused with return code 2. For a
TRANSMIT file, an object library or an object module the message says which
it is: an object module has to be linked first, and a TRANSMIT file has to be
packed from the modules it was made of.

== Identification Records <ld370-idr>

#idx("IDR", "written by ld370")
#idx("identification record")
Every member written by ld370 carries two identification records:

- an HMASPZAP record of 251 bytes with no entries, the record in which
  AMASPZAP notes the changes it makes to the module on MVS\;
- a linkage editor record of 22 bytes, which names #cmd("LD370") as the
  program, with the version and release of the toolchain as version and
  modification level (01 and 04 for cc370 1.4), and holds the date and time
  of the link.

The translator records that IEWL copies from the END records of the object
modules are not written.

#idx("LDDATE")#idx("LDTIME")
#idx("reproducible output")
The date and time come from the clock of the workstation, so two links of the
same input are not byte for byte the same. Two environment variables fix
them:

#deflist(width: 1.45in,
  [#cmd("LDDATE=")#var("yyddd")], [the date: two digits of the year and the
    day of the year, 001 to 366. #cmd("26277") is 4 October 2026.],
  [#cmd("LDTIME=")#var("hhmmss")], [the time, on the 24-hour clock.],
)

Each is read on its own\; set both for a reproducible link. They also fix the
time stamp in the TRANSMIT file. A value of the wrong form ends ld370 with
return code 2.

== Return Codes <ld370-rc>

#idx("ld370", "return codes")
@ld370-rc-tab lists the values. The rule that separates 1 from 2: *return
code 2 means that the command line is wrong, whatever the files hold*, and
nothing is written\; return code 1 means that a file, or the link itself,
failed. Messages are written to standard error and begin with
#cmd("ld370:")\; a warning begins with #cmd("ld370: warning:").

#tab(caption: [ld370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [The module or the transport file was written. *Warnings and notes
      also end with 0*: a doubly defined entry point, a control section
      dropped as a duplicate, a definition passed over by the library
      search, an alias without a directory, a member file packed without
      its directory, an option that #cmd("--pack") ignores. #cmd("--help")
      and #cmd("--version") also end with 0.],
    [1], [A file or the link failed: an input file that cannot be read or
      is not an object module, a file named as a library that is not one,
      #cmd("-l") or #cmd("--include") not found, an unresolved external
      reference, an entry point not defined (with #cmd("--pack"): not found,
      or found twice, in the CESD of a member file), a packed member with a
      record longer than the block size, an output file that cannot be
      written. A load map or transport file that cannot be written is found
      before the member is written, so no member file is left behind.],
    [2], [The command line is wrong, and nothing was written: an unknown
      option, an option without its value, no input files, #cmd("--pack")
      without #cmd("-o"), #cmd("--rent") with #cmd("--norent") or
      #cmd("--reus") with #cmd("--noreus"), #cmd("--xref") without
      #cmd("--map"), #cmd("--alias"), #cmd("--map"), #cmd("--name") or
      #cmd("--include") with #cmd("--pack"), a number that is not a number
      or out of range, a member or alias name that is not valid, one name
      used twice in a library (two packed members, or an alias that names
      the member or is given twice), more than 32 libraries, a
      #cmd("--pack") input that is not a load module or is an unloaded
      library with several members, or a wrong #cmd("LDDATE") or
      #cmd("LDTIME").],
  )
] <ld370-rc-tab>

== Differences from IEWL <ld370-iewl>

#idx("IEWL", "differences")
For the inputs it has been checked against, ld370 writes the same member as
IEWL apart from the identification records. The differences that remain are
these:

- ld370 has no control statements. #cmd("INCLUDE"), #cmd("ENTRY"),
  #cmd("ALIAS"), #cmd("NAME") and #cmd("SETCODE") are options:
  #cmd("--include"), #cmd("--entry"), #cmd("--alias"), #cmd("--name") and
  #cmd("--ac"). Overlay structures and the IEWL options that have no
  counterpart in this chapter are not supported.
- The automatic library call finds entry points as well as members (see
  @ld370-autocall). IEWL finds only the member names and aliases in the
  library directory.
- An unresolved reference ends the link unless #cmd("--allow-unresolved") is
  given.
- Warnings end with return code 0, where IEWL ends with 4.
- #cmd("--rent") sets only the reentrant attribute\; the #cmd("RENT")
  option of IEWL sets reusable as well.
- The identification records differ, as @ld370-idr describes.
- The load map has a format of its own (see @ld370-map).

== Example <ld370-ex>

The program in @ld370-ex-src calls #cmd("ADD1") through a V-type address
constant. #cmd("ADD1") is in a separate source and has a second entry point,
#cmd("ADD2").

#fig(caption: [MAIN and ADD1, two assembler programs])[
  #grid(columns: (1fr, 1fr), column-gutter: 1em,
    code(read("../ex/ld370/main.asm")),
    code(read("../ex/ld370/add1.asm")))
] <ld370-ex-src>

@ld370-session assembles both, puts #cmd("ADD1") into a library, links
#cmd("MAIN") against it with a load map and a TRANSMIT file, and examines the
results with file370. The map shows that #cmd("ADD1") was taken from the
library by the automatic library call.

#fig(caption: [Linking MAIN against a library])[
  #screen(raw(read("../ex/ld370/link.txt")))
] <ld370-session>

@ld370-errors shows one outcome for each return code. The object module
#cmd("dup2.o"), assembled from the source in @ld370-dup2, defines
#cmd("ADD2") a second time\; the link warns and ends with 0. Long messages
are shown on several lines.

#fig(caption: [DUP, a second definition of ADD2])[
  #code(read("../ex/ld370/dup2.asm"))
] <ld370-dup2>

#fig(caption: [A warning and two failed links])[
  #screen(raw(read("../ex/ld370/errors.txt")))
] <ld370-errors>
