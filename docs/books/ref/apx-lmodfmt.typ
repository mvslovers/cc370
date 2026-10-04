#import "../bookmaster/bookmaster.typ": *

= Load Module and Transport #box[Formats] <apx-lmodfmt>

#idx("load module", "format")
This appendix describes the files that ld370 and xmit370 write, from the
inside out:

- *the load module member*, the file ld370 names by #cmd("-o"): the records
  of one member of a load library, as program fetch reads them on MVS\;
- *the directory entry* of the member, which holds the entry point, the
  length and the attributes of the module, and exists only in the two
  transport files\;
- *the IEBCOPY unloaded form*, the #cmd(".iebcopy") file: a library with its
  directory and its members, as IEBCOPY writes it when it unloads a
  partitioned data set\;
- *the TSO TRANSMIT form*, the #cmd(".xmit") file of ld370 and the output of
  #cmd("xmit370 create"): the unloaded form wrapped in NETDATA records of 80
  bytes, which RECEIVE reads.

Each layer contains the one before it. @apx-lmodfmt-ex shows all three
files of one small module, byte by byte. The formats are those of MVS 3.8j:
the load module is that of the F-level linkage editor, with 24-bit addresses
and none of the addressing-mode fields of later systems.

Throughout this appendix, offsets are decimal and count from 0, numeric
fields are unsigned binary with the most significant byte first, and names
are in EBCDIC, padded with blanks. Dates and times marked as packed are
packed decimal with the sign #cmd("F").

== The Load Module <apx-lmodfmt-member>

#idx("load module", "records")
A load library has undefined-length records (#cmd("RECFM=U")), and a
member is a sequence of such records. The member file that ld370 writes holds
the records one after another with nothing between them, so a program that
reads it must find the length of each record from the record itself. The
first byte of every record says what it is (@apx-lmodfmt-recs), and
@apx-lmodfmt-len shows where its length comes from.

#tab(caption: [Record types, by the first byte])[
  #table(columns: (0.9in, 1fr),
    [First byte], [Record],
    [#cmd("X'20'")], [Composite external symbol dictionary (CESD).],
    [#cmd("X'80'")], [Identification record (IDR).],
    [#cmd("X'01'")], [Control record. A text record follows it.],
    [#cmd("X'02'")], [RLD record: relocation items, and no text follows.],
    [#cmd("X'03'")], [Control record that also carries relocation items. A
      text record follows it.],
    [#cmd("X'0D'"), #cmd("X'0E'"), #cmd("X'0F'")], [The same three, as the
      last control or RLD record of the module: #cmd("X'0C'") is added to
      mark the end of the module (#cmd("X'08'")) and of its segment
      (#cmd("X'04'")).],
    [none], [Text record. It has no header of its own and is recognized by
      its position, after a control record.],
  )
] <apx-lmodfmt-recs>

#tab(caption: [Length of each record])[
  #table(columns: (1.3in, 1fr),
    [Record], [Length],
    [CESD], [8 plus the byte count at offset 6.],
    [IDR], [The byte at offset 1, plus 1.],
    [Control, RLD], [16 plus the counts at offsets 4 and 6.],
    [Text], [The count at offset 14 of the control record before it.],
  )
] <apx-lmodfmt-len>

A member written by ld370 holds, in this order: the CESD records\; two IDRs\;
a control record and a text record for each piece of text\; and the RLD
records, the last of which ends the module. A module without address
constants has no RLD records, and its last control record carries the end
mark: #cmd("X'0D'"). ld370 does not write #cmd("X'03'") records\; the MVS
linkage editor does, placing the relocation items of a text record in the
control record in front of it.

=== Composite External Symbol Dictionary <apx-lmodfmt-cesd>

#idx("CESD")
#idx("composite external symbol dictionary")
The CESD lists every control section, entry point and unresolved external
reference of the module. It is built from the ESD records of the object
modules (see @apx-objfmt-esd), and the other records of the load module
refer to its entries by number, the CESD identifier. A record holds up to
15 entries.

#tab(caption: [CESD record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [#cmd("X'20'").],
    [1], [3], [Zero.],
    [4], [2], [The CESD identifier of the first entry in the record. The
      entries are numbered from 1 through all the records.],
    [6], [2], [The number of bytes of entries: 16 times the number of
      entries.],
    [8], [16 each], [The entries.],
  )
] <apx-lmodfmt-cesd-rec>

#tab(caption: [CESD entry])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [8], [The symbol. Blank for private code.],
    [8], [1], [The type, from @apx-lmodfmt-cesd-types.],
    [9], [3], [SD, PC, CM: the address of the section in the module. LR:
      the address of the entry point. ER, WX: zero.],
    [12], [1], [The overlay segment number: 1 in a module without overlay
      structure. ER, WX: zero.],
    [13], [3], [SD, PC, CM: the length of the section. LR: zero in the first
      byte, then the CESD identifier of the section that contains the entry
      point. ER, WX: not used, carried over from the object module.],
  )
] <apx-lmodfmt-cesd-entry>

#tab(caption: [CESD entry types])[
  #table(columns: (0.55in, 0.6in, 1fr),
    [Type], [Code], [Meaning],
    [SD], [#cmd("X'00'")], [Control section.],
    [ER], [#cmd("X'02'")], [External reference that the link left
      unresolved.],
    [LR], [#cmd("X'03'")], [Entry point. An LD item of an object module
      becomes an LR entry.],
    [PC], [#cmd("X'04'")], [Private code: an unnamed control section.],
    [CM], [#cmd("X'05'")], [Common section.],
    [Null], [#cmd("X'07'")], [An unused entry. ld370 does not write it\;
      modules from the MVS linkage editor can contain it.],
    [WX], [#cmd("X'0A'")], [Weak external reference that the link left
      unresolved.],
  )
] <apx-lmodfmt-cesd-types>

=== Identification Records <apx-lmodfmt-idr>

#idx("IDR", "format")
#idx("identification record")
The IDRs follow the CESD. They record which programs built and changed the
module. All share a three-byte header:

#tab(caption: [IDR header])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [#cmd("X'80'").],
    [1], [1], [The length of the record, less 1.],
    [2], [1], [The type of the record: #cmd("X'01'") HMASPZAP,
      #cmd("X'02'") linkage editor, #cmd("X'04'") translator,
      #cmd("X'08'") user data. #cmd("X'80'") is added on the last IDR of
      the module.],
  )
] <apx-lmodfmt-idr-hdr>

*The HMASPZAP record*, type #cmd("X'01'"), is 251 bytes long. Byte 3 holds
the number of entries, and the entries follow, 13 bytes each: the CESD
identifier of the section that was changed (2 bytes), the date of the change
(3 bytes, packed #var("yyddd")) and the name given to the change (8
characters). ld370 writes the record with no entries, as a place for
AMASPZAP to record changes made on MVS.

#idx("LDDATE")#idx("LDTIME")
*The linkage editor record*, type #cmd("X'02'"), names the program that
linked the module:

#tab(caption: [Linkage editor IDR])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [3], [Header: #cmd("X'80'"), #cmd("X'15'") (22 bytes), and
      #cmd("X'02'"), or #cmd("X'82'") when it is the last IDR.],
    [3], [10], [The program: #cmd("LD370") followed by five blanks. The MVS
      linkage editor writes #cmd("5752SC104").],
    [13], [2], [The version and modification level. ld370 writes
      #cmd("X'0100'").],
    [15], [3], [The date of the link, packed #var("yyddd").],
    [18], [4], [The time of the link, packed #var("0hhmmss").],
  )
] <apx-lmodfmt-lked>

The MVS linkage editor writes the record in the same 22-byte form, or in an
18-byte form without the time, with #cmd("X'11'") in byte 1. The date and
time that ld370 writes can be fixed with #cmd("LDDATE") and #cmd("LDTIME")
(see @ld370-idr).

*The translator records*, type #cmd("X'04'"), name the assemblers and
compilers that produced the object modules, with their versions and dates,
taken from the END records (see @apx-objfmt-end). *The user data records*,
type #cmd("X'08'"), carry the identification given to the MVS linkage editor
by #cmd("IDENTIFY") statements, as entries of the CESD identifier (2 bytes),
the date (3 bytes, packed #var("yyddd")), the length of the text (1 byte) and
the text. ld370 writes neither. idrdump370 displays all four types (see
@idrdump370).

=== Control and Text Records <apx-lmodfmt-ctl>

#idx("control record")
#idx("text record")
The text of the module is carried in text records, each preceded by a
control record that tells program fetch where to put it. The control record
holds a channel command word (CCW) with which fetch reads the text record
directly into place.

#tab(caption: [Control record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [The record type: #cmd("X'01'"), #cmd("X'03'"), or with the end
      mark #cmd("X'0D'"), #cmd("X'0F'").],
    [1], [3], [Zero.],
    [4], [2], [The length of the ID/length list: 4 times the number of
      sections in the text record that follows.],
    [6], [2], [The length of the relocation items in the record. Zero for
      #cmd("X'01'") and #cmd("X'0D'").],
    [8], [1], [#cmd("X'06'"), the read command of the CCW.],
    [9], [3], [The address in the module at which the text is loaded.],
    [12], [1], [#cmd("X'40'"), the command-chaining flag of the CCW.],
    [13], [1], [Zero.],
    [14], [2], [The length of the text record that follows.],
    [16], [], [The relocation items, if offset 6 is not zero.],
    [], [], [The ID/length list: for each section in the text record, its
      CESD identifier (2 bytes) and the number of bytes of the text record
      that belong to it (2 bytes).],
  )
] <apx-lmodfmt-ctl-rec>

#note[When a control record carries both, the relocation items come first
and the ID/length list after them. The lengths in the list add up to the
text length at offset 14, which is the way to tell the two apart.]

ld370 places each section at the next doubleword boundary, so the length
given for a section in the list is its length rounded up to a multiple of
8, except that the last section of the module ends with the module. A text
record carries whole sections, and as many as fit\; a section longer than
the largest text record is split over several, each with one entry in its
list. The largest text record follows from the block size, as described in
@ld370-blksize.

The text record that follows is the text itself, with no header, as long as
offset 14 of the control record says.

=== RLD Records <apx-lmodfmt-rld>

#idx("RLD record", "in the load module")
#idx("relocation dictionary", "in the load module")
An RLD record has the 16-byte header of a control record with only offsets 0
and 6 filled in: #cmd("X'02'"), or #cmd("X'0E'") on the last record, and the
length of the relocation items. Offsets 8 to 15 are zero, and no text record
follows. ld370 writes at most 236 bytes of items to a record.

The relocation items have the format of the object module
(@apx-objfmt-rld-item), with these differences:

- the pointers are CESD identifiers, and the relocation pointer of an entry
  point is the identifier of the section that contains it\;
- the address is the address of the constant in the module, not in its
  object module\;
- the flag byte has one more bit: #cmd("X'80'") marks a constant whose
  symbol was not resolved, which program fetch leaves alone. A
  #cmd("V")-type constant for a weak external reference that nothing
  defines therefore has the flag #cmd("X'9C'")\;
- the continuation bit does not reach from one record into the next.

== The Directory Entry <apx-lmodfmt-dir>

#idx("directory entry", "format")
#idx("PDS2")
Each member of a library, and each of its aliases, has an entry in the
directory of the library. For a load module, the entry holds what program
fetch needs before it reads the first record. A member file has no
directory\; ld370 builds the entry when it writes a transport file.

#tab(caption: [Directory entry of a load module])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [8], [The member or alias name.],
    [8], [3], [The relative address (TTR) of the first record of the
      member.],
    [11], [1], [Indicators: #cmd("X'80'") the name is an alias\;
      #cmd("X'60'") the number of TTRs in the user data\; #cmd("X'1F'")
      the length of the user data in halfwords. A member written by ld370
      has #cmd("X'2C'"), an alias #cmd("X'B1'").],
    [12], [3], [The TTR of the first text record.],
    [15], [1], [Zero.],
    [16], [3], [The TTR of the note list or scatter table. Zero.],
    [19], [1], [The number of note list entries. Zero.],
    [20], [1], [Attributes, first byte (@apx-lmodfmt-atr1).],
    [21], [1], [Attributes, second byte (@apx-lmodfmt-atr2).],
    [22], [3], [The length of the module in storage.],
    [25], [2], [The length of the first text record.],
    [27], [3], [The entry point: of the member, or of the alias.],
    [30], [3], [Flags. ld370 writes #cmd("X'880000'"): #cmd("X'80'") the
      module was processed by an OS/VS linkage editor, #cmd("X'08'") the APF
      section is valid.],
    [33], [11], [Alias entries only: the entry point of the member (3 bytes)
      and the name of the member (8).],
    [33 or 44], [2], [The APF section: #cmd("X'01'"), the length of the
      authorization code, and the code (see @ld370-attr).],
    [35], [1], [Member entries only: zero, to make the user data a whole
      number of halfwords.],
  )
] <apx-lmodfmt-dir-entry>

A member entry is therefore 36 bytes long and an alias entry 46. The offsets
above are those of the entry on disk\; the #cmd("BLDL") macro inserts two
bytes after the TTR when it reads an entry into storage, and the mapping
macro #cmd("IHAPDS") describes that form.

#tab(caption: [First attribute byte])[
  #table(columns: (0.75in, 1fr),
    [Bit], [Meaning when set],
    [#cmd("X'80'")], [Reentrant (#cmd("--rent")).],
    [#cmd("X'40'")], [Reusable (#cmd("--reus")).],
    [#cmd("X'20'")], [Overlay structure. Not written by ld370.],
    [#cmd("X'10'")], [Module to be tested with TESTRAN. Not written by
      ld370.],
    [#cmd("X'08'")], [Only loadable. Not written by ld370.],
    [#cmd("X'04'")], [Scatter format. Not written by ld370.],
    [#cmd("X'02'")], [Executable. ld370 always sets it.],
    [#cmd("X'01'")], [The module is a single text record and has no
      relocation items.],
  )
] <apx-lmodfmt-atr1>

#tab(caption: [Second attribute byte])[
  #table(columns: (0.75in, 1fr),
    [Bit], [Meaning when set],
    [#cmd("X'80'")], [Can be processed only by the F-level linkage editor.
      ld370 always sets it.],
    [#cmd("X'40'")], [The first text record is loaded at offset 0, as in
      every module ld370 writes.],
    [#cmd("X'20'")], [The entry point is at offset 0.],
    [#cmd("X'10'")], [The module has no relocation items.],
    [#cmd("X'08'")], [The module cannot be processed again by the linkage
      editor. Not written by ld370.],
    [#cmd("X'04'")], [The module contains TESTRAN symbol records. Not written
      by ld370.],
    [#cmd("X'02'")], [Built by the F-level linkage editor. ld370 always sets
      it.],
    [#cmd("X'01'")], [Refreshable (#cmd("--refr")).],
  )
] <apx-lmodfmt-atr2>

The module of @apx-lmodfmt-ex, linked with #cmd("--reus"), has
#cmd("X'42'") and #cmd("X'E2'"). The same link with #cmd("-e ALT"), whose
entry point is not at 0, has #cmd("X'02'") and #cmd("X'C2'").

== The IEBCOPY Unloaded Form <apx-lmodfmt-unload>

#idx("IEBCOPY", "unloaded form")
#idx("unloaded library")
When IEBCOPY unloads a partitioned data set, it writes a sequential data set
that describes the library and holds a copy of each of its records. The
#cmd(".iebcopy") file of ld370 is that data set, and the TRANSMIT form
carries the same thing. The file consists of logical records with nothing
between them:

+ COPYR1, 52 bytes, which describes the library\;
+ COPYR2, 276 bytes, which describes the disk space it occupied\;
+ the directory, one record for each 256-byte directory block\;
+ an end-of-directory record, a count field of 12 zero bytes\;
+ for each member, one record for each record of the member, and an
  end-of-file record.

From the directory on, every record is the image of a record on a disk
track: a 12-byte count field, then the key, if any, then the data.

#tab(caption: [COPYR1])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [Zero.],
    [1], [3], [#cmd("X'CA6D0F'"), which identifies an unloaded data set.],
    [4], [2], [The organization of the library: #cmd("X'0200'"),
      partitioned.],
    [6], [2], [The block size of the library: the #cmd("--blocksize") of
      ld370 or xmit370.],
    [8], [2], [The record length: 0 for a load library, the
      #cmd("--lrecl") of xmit370 for a source library.],
    [10], [1], [The record format: #cmd("X'C0'") undefined (load library),
      #cmd("X'90'") fixed blocked, #cmd("X'80'") fixed.],
    [11], [1], [The key length. Zero.],
    [12], [2], [Zero.],
    [14], [2], [The block size of the unloaded data set: the block size of
      the library plus 20.],
    [16], [20], [The characteristics of the device the library was on, as
      the #cmd("DEVTYPE") macro returns them. ld370 and xmit370 write those
      of a 3350: device type #cmd("X'3050200B'"), largest block 19069, 560
      cylinders, 30 tracks to a cylinder, 19254 bytes to a track, and
      further constants for the space taken by a block.],
    [36], [16], [Zero.],
  )
] <apx-lmodfmt-copyr1>

COPYR2 holds 16 bytes from the data extent block (DEB) of the library,
followed by its extent descriptions of 16 bytes each, and zeros to fill the
record. IEBCOPY uses the extents for one purpose: to convert the relative
track addresses of the records, below, into actual ones while it loads the
library. ld370 and xmit370 write one extent, beginning at cylinder
#cmd("X'8D'"), with as many whole cylinders as the members need.

#tab(caption: [Extent description in COPYR2, at offset 16])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [16], [4], [The file mask and the address of the device.],
    [20], [2], [Zero.],
    [22], [4], [The cylinder and track where the extent begins.],
    [26], [4], [The cylinder and track where the extent ends.],
    [30], [2], [The number of tracks in the extent.],
  )
] <apx-lmodfmt-copyr2>

#tab(caption: [Count field])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [Zero.],
    [1], [3], [Zero: the extent number and the bin.],
    [4], [2], [The cylinder: zero for the directory, otherwise in the extent
      of COPYR2.],
    [6], [2], [The track.],
    [8], [1], [The record number on the track.],
    [9], [1], [The key length: 8 for a directory record, otherwise 0.],
    [10], [2], [The data length. Zero marks the end of the directory or of a
      member.],
  )
] <apx-lmodfmt-count>

*A directory record* has a count field with key length 8 and data length
256, a key, and one directory block. The block begins with the number of
bytes in use, including these two, and holds the entries in ascending order
of their names: a load module entry as in @apx-lmodfmt-dir-entry, a source
member entry as in @apx-lmodfmt-source. An entry goes into a block while it
fits\; the last block ends with an entry of eight bytes #cmd("X'FF'") and
four zero bytes. The key of a block is the last name in it, and eight bytes
#cmd("X'FF'") for the last block. With 36-byte entries a block holds seven.

*The member records* follow the end-of-directory record. Each record of a
member (@apx-lmodfmt-recs) becomes one record of the unloaded form, the text
record as well as its control record, and a record with data length 0 ends
the member. The TTRs in the directory entry give the track relative to the
start of the extent and the record number on that track, so they must agree
with the count fields. ld370 places the records of a library with one member
one to a track, each as record 1\; with several members it places them one
after another on each track, as IEBCOPY does, counting the space each
record takes on a 3350 track.

== The TRANSMIT Form <apx-lmodfmt-xmit>

#idx("TRANSMIT", "file format")
#idx("NETDATA")
A TRANSMIT file is what the TSO #cmd("TRANSMIT") command sends and what
#cmd("RECEIVE") reads. It is a sequence of 80-byte records that carry a
stream of NETDATA segments. The stream does not respect record boundaries:
a segment may begin in one 80-byte record and end in the next. The last
record is filled with zero bytes.

#tab(caption: [NETDATA segment])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [1], [The length of the segment, including these two bytes: 2 to
      255.],
    [1], [1], [Flags: #cmd("X'80'") first segment of a logical record,
      #cmd("X'40'") last segment of a logical record, #cmd("X'20'")
      control record.],
    [2], [], [Up to 253 bytes of the logical record.],
  )
] <apx-lmodfmt-seg>

A logical record longer than 253 bytes is carried in several segments: the
first has #cmd("X'80'"), the last #cmd("X'40'"), one in between neither. A
control record that fits in one segment has the flags #cmd("X'E0'"), a data
record #cmd("X'C0'").

=== Control Records <apx-lmodfmt-inmr>

#idx("INMR01")#idx("INMR02")#idx("INMR03")#idx("INMR06")
A transmission of one library consists of these logical records:

#tab(caption: [Logical records of a transmitted library])[
  #table(columns: (1in, 1fr),
    [Record], [Contents],
    [#cmd("INMR01")], [Header: the sender, the receiver and the time of the
      transmission.],
    [#cmd("INMR02")], [The library as IEBCOPY sees it: its organization,
      record format, record length, block size, size, directory blocks and
      name.],
    [#cmd("INMR02")], [The unloaded form, as the transmission carries it:
      a sequential data set of variable-length spanned records.],
    [#cmd("INMR03")], [The format of the data records that follow.],
    [data], [The unloaded form: COPYR1, COPYR2, each directory block, and
      the member records.],
    [#cmd("INMR06")], [End of the transmission.],
  )
] <apx-lmodfmt-inmr-list>

A control record begins with its name in EBCDIC, #cmd("INMR01") and so on.
An #cmd("INMR02") record continues with a 4-byte file number, 1. The rest of
the record is a list of text units:

#tab(caption: [Text unit])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [2], [The key, from @apx-lmodfmt-keys.],
    [2], [2], [The number of values: 1, except for the data set name, which
      has one value for each qualifier.],
    [4], [], [Each value: its length (2 bytes), then the value.],
  )
] <apx-lmodfmt-tu>

#tab(caption: [Text units written by ld370 and xmit370])[
  #table(columns: (0.95in, 0.7in, 1fr),
    [Name], [Key], [Value],
    [INMDSNAM], [#cmd("X'0002'")], [The data set name, one value for each
      qualifier: the #cmd("--dsn") operand. In #cmd("INMR02") (IEBCOPY).],
    [INMDIR], [#cmd("X'000C'")], [The number of directory blocks to
      allocate: those the members need, plus 5, and at least 10.],
    [INMBLKSZ], [#cmd("X'0030'")], [The block size: of the library, or of
      the unloaded form (the library's plus 20).],
    [INMDSORG], [#cmd("X'003C'")], [The organization: #cmd("X'0200'")
      partitioned, #cmd("X'4000'") sequential.],
    [INMLRECL], [#cmd("X'0042'")], [The record length: 80 in
      #cmd("INMR01") and #cmd("INMR03")\; that of the library\; or, for the
      unloaded form, its block size less 4.],
    [INMRECFM], [#cmd("X'0049'")], [The record format, 2 bytes:
      #cmd("X'C002'") undefined (ld370), #cmd("X'9000'") fixed blocked
      (xmit370), #cmd("X'4802'") variable spanned (the unloaded form), and
      #cmd("X'0001'") in #cmd("INMR03").],
    [INMTNODE], [#cmd("X'1001'")], [The node of the receiver.],
    [INMTUID], [#cmd("X'1002'")], [The user ID of the receiver.],
    [INMFNODE], [#cmd("X'1011'")], [The node of the sender:
      #cmd("ORIGNODE").],
    [INMFUID], [#cmd("X'1012'")], [The user ID of the sender.],
    [INMFTIME], [#cmd("X'1024'")], [The time of the transmission, 16
      digits: #var("yyyymmddhhmmss") and two digits of fractions of a
      second.],
    [INMUTILN], [#cmd("X'1028'")], [The utility: #cmd("IEBCOPY") in the
      first #cmd("INMR02"), #cmd("INMCOPY") in the second.],
    [INMSIZE], [#cmd("X'102C'")], [The size in bytes: of the member records
      in the first #cmd("INMR02") and in #cmd("INMR03"), of the whole
      unloaded form in the second #cmd("INMR02").],
    [INMNUMF], [#cmd("X'102F'")], [The number of files in the transmission:
      1. In #cmd("INMR01").],
  )
] <apx-lmodfmt-keys>

#idx("RECEIVE", "allocation of the library")
RECEIVE allocates the library from the first #cmd("INMR02") when it is not
given an existing data set, which is why its block size, size and number of
directory blocks must describe the library as it is to be on MVS.
@ld370-transport describes how to send and receive the file.

=== Data Records <apx-lmodfmt-xmit-data>

The records of the unloaded form become logical records of the
transmission, one or more segments each: COPYR1, COPYR2, then each
directory block with its count field and key, the last one together with the
end-of-directory record. The member records follow, several to a logical
record, but a logical record always ends with the end-of-file record of a
member, so that each member begins a logical record of its own. ld370 also
ends a logical record before it would grow beyond the largest text record
(@ld370-blksize).

== Source Libraries <apx-lmodfmt-source>

#idx("source library", "transport format")
#idx("ISPF statistics", "format")
#cmd("xmit370 create") writes a library of fixed-length records in the same
two layers. These are the differences:

- COPYR1 and the first #cmd("INMR02") give the record format
  #cmd("X'90'") (fixed blocked) or #cmd("X'80'") (fixed) and the record
  length, and the default block size is 3120.
- A directory entry is the name, the TTR of the member, the indicator byte
  #cmd("X'0F'"), which means no TTRs and 15 halfwords of user data, and 30
  bytes of ISPF statistics (@apx-lmodfmt-stats). With #cmd("--no-stats") it
  is the 12 bytes of name, TTR and indicator #cmd("X'00'").
- Each member record is a block of records, as many as the block size
  holds\; the last block of a member is shorter.

#tab(caption: [ISPF statistics in a directory entry])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [12], [1], [The version number.],
    [13], [1], [The modification level.],
    [14], [1], [Flags. Zero.],
    [15], [1], [The seconds of the last change, packed.],
    [16], [4], [The date of creation, packed #var("0cyydddF"): #var("c") is
      0 for 19#var("yy"), 1 for 20#var("yy").],
    [20], [4], [The date of the last change, in the same form.],
    [24], [2], [The time of the last change, packed #var("hhmm").],
    [26], [2], [The current number of lines, binary.],
    [28], [2], [The initial number of lines, binary.],
    [30], [2], [The number of changed lines, binary.],
    [32], [8], [The user ID.],
    [40], [2], [Blank.],
  )
] <apx-lmodfmt-stats>

@xmit370-stats describes the values xmit370 puts there.

== Example <apx-lmodfmt-ex>

The two object modules of @apx-objfmt-ex, #cmd("fmt.o") and #cmd("sub.o")
(#cmd("SUB") is a section of two instructions), were linked with

```
LDDATE=26277 LDTIME=120000 ld370 -o FMT --name FMT fmt.o sub.o \
      --reus -iebcopy -xmit --dsn USER1.DEMO.LOAD
```

which wrote the member #cmd("FMT"), the unloaded library
#cmd("FMT.iebcopy") and the transmission #cmd("FMT.xmit"). The weak
reference #cmd("OPT") is left unresolved. The dumps were made with
#cmd("xxd -a -g1 -c16"), without the character column\; a line #cmd("*")
stands for lines equal to the one before it, and #cmd("...") for lines left
out here.

=== The Member

#fig(caption: [The load module member FMT])[
  #code(read("../ex/apx-lmodfmt/fmt-member.txt"))
] <apx-lmodfmt-member-dump>

#deflist(width: 1.4in,
  [#cmd("000"), CESD], [#cmd("20"), first identifier 1, 80 bytes: five
    entries. 1 #cmd("SUB") SD at #cmd("28"), length 4\; 2 #cmd("MAIN") SD
    at 0, length #cmd("1C")\; 3 #cmd("SECOND") SD at #cmd("20"), length 6\;
    4 #cmd("OPT") WX\; 5 #cmd("ALT") LR at 8, in section 2. Each section
    has segment number 1. The identifiers are not those of the object
    module: #cmd("SUB") has become a section and comes first.],
  [#cmd("058"), IDR], [#cmd("80 FA 01 00"): HMASPZAP, 251 bytes, no
    entries, then zeros.],
  [#cmd("153"), IDR], [#cmd("80 15 82"): linkage editor, last IDR, 22 bytes.
    #cmd("LD370"), version #cmd("01 00"), date #cmd("26 27 7F") (26277),
    time #cmd("01 20 00 0F") (12:00:00).],
  [#cmd("169"), control], [#cmd("01"), an ID/length list of 12 bytes, no
    relocation items\; CCW #cmd("06 000000 40 00 0030"): 48 bytes of text
    at address 0. The list: section 2 (#cmd("MAIN")) #cmd("20") bytes,
    section 3 #cmd("08"), section 1 #cmd("08"), together #cmd("30").],
  [#cmd("185"), text], [The 48 bytes of text, with the constants already
    relocated: #cmd("A(ALT)") is 8, and the #cmd("=V(SUB)") at offset
    #cmd("18") holds #cmd("28").],
  [#cmd("1B5"), RLD], [#cmd("0E"), the end of the module, with
    #cmd("28") (40) bytes of items and no CCW. #cmd("00 01 00 02 1C 00 00 18"):
    the #cmd("V")-constant for #cmd("SUB") at #cmd("18"). The one for
    #cmd("OPT") has the flag #cmd("9C"): unresolved. The last item,
    #cmd("04 00 00 24"), is the 2-byte #cmd("AL2(ALT)"), now at
    #cmd("24") in the module.],
)

@apx-lmodfmt-member-v shows the same member as file370 describes it.

#fig(caption: [file370 -v FMT])[
  #screen(raw(read("../ex/apx-lmodfmt/fmt-member-v.txt")))
] <apx-lmodfmt-member-v>

=== The Unloaded Library

#fig(caption: [The unloaded library FMT.iebcopy (in part)])[
  #code(read("../ex/apx-lmodfmt/iebcopy-dump.txt"))
] <apx-lmodfmt-unload-dump>

#deflist(width: 1.4in,
  [#cmd("000"), COPYR1], [#cmd("CA6D0F"), partitioned (#cmd("0200")),
    block size #cmd("3AC0") (15040), record length 0, record format
    #cmd("C0"), unloaded block size #cmd("3AD4") (15060), and from
    #cmd("010") the 3350 characteristics.],
  [#cmd("034"), COPYR2], [The DEB fields, and at #cmd("044") the extent:
    cylinder #cmd("8D") track 0 to cylinder #cmd("8D") track #cmd("1D"),
    #cmd("1E") (30) tracks.],
  [#cmd("148"), directory], [Count field with key length 8 and data
    length #cmd("0100"), the key #cmd("FF")... of the last block, and the
    block: #cmd("0032") (50) bytes in use, then the entry of #cmd("FMT")\:
    TTR #cmd("000001"), indicators #cmd("2C"), text at TTR #cmd("000401"),
    attributes #cmd("42 E2"), length #cmd("000030"), first text record
    #cmd("0030") bytes, entry point 0, flags #cmd("880000"), APF section
    #cmd("01 00"), a zero byte, and the 12-byte end entry.],
  [#cmd("25C"), end of directory], [Twelve zero bytes.],
  [#cmd("268"), member], [The first member record: cylinder #cmd("8D"),
    track 0, record 1, data length #cmd("58"), and the CESD record of
    @apx-lmodfmt-member-dump. Each of the six records of the member is on a
    track of its own, so the text record, the fifth, is on track 4: TTR
    #cmd("000401") in the directory entry.],
  [#cmd("49D"), end of member], [Cylinder #cmd("8D"), track 6, record 1,
    data length 0.],
)

=== The Transmission

#fig(caption: [The transmission FMT.xmit (in part)])[
  #code(read("../ex/apx-lmodfmt/xmit-dump.txt"))
] <apx-lmodfmt-xmit-dump>

#deflist(width: 1.4in,
  [#cmd("000"), INMR01], [A segment of #cmd("62") (98) bytes with the flags
    #cmd("E0"): #cmd("INMR01"), then the text units #cmd("0042")
    INMLRECL 80, #cmd("1011") INMFNODE #cmd("ORIGNODE"), #cmd("1012"),
    #cmd("1001"), #cmd("1002"), #cmd("1024") INMFTIME
    #cmd("2026100412000000"), and #cmd("102F") INMNUMF 1.],
  [#cmd("062"), INMR02], [#cmd("67") bytes: file number 1,
    #cmd("IEBCOPY"), INMSIZE #cmd("241") (577), INMDIR 10, INMLRECL 0,
    INMDSORG #cmd("0200"), INMBLKSZ 15040, INMRECFM #cmd("C002"), and
    #cmd("0002 0003"): a data set name of three qualifiers,
    #cmd("USER1"), #cmd("DEMO"), #cmd("LOAD").],
  [#cmd("0C9"), INMR02], [#cmd("47") bytes: #cmd("INMCOPY"), INMSIZE
    #cmd("4A9") (1193), INMLRECL 15056, INMDSORG #cmd("4000"), INMBLKSZ
    15060, INMRECFM #cmd("4802").],
  [#cmd("110"), INMR03], [#cmd("2C") bytes: INMSIZE 577, INMLRECL 80,
    INMDSORG #cmd("4000"), INMRECFM #cmd("0001").],
  [#cmd("13C"), data], [A segment of #cmd("36") bytes with the flags
    #cmd("C0")\: COPYR1, 52 bytes. The other records of the unloaded form
    follow.],
  [#cmd("5F5"), INMR06], [The last control record, #cmd("08 E0") and
    #cmd("INMR06")\; the file is filled with zeros to 1600 bytes, 20
    records of 80.],
)

=== A Source Library

#cmd("xmit370 list -v") decodes a transmission of a source library and its
directory. @apx-lmodfmt-src-list shows one made with

```
xmit370 create -o SRC.xmit --dsn USER1.DEMO.SOURCE --userid USER1 \
        --stats-date 2026-10-04T12:00:00 src
```

from a directory with the members #cmd("HELLO") (2 lines) and
#cmd("README") (3 lines). The directory entry of #cmd("HELLO") in that file
is

```
C8 C5 D3 D3 D6 40 40 40  00 00 01  0F  01 00 00 00  01 26 27 7F
01 26 27 7F  12 00  00 02  00 02  00 00  E4 E2 C5 D9 F1 40 40 40  40 40
```

the name, TTR 1, indicators #cmd("0F"), version 1, level 0, created and
changed on day 277 of 2026 (#cmd("0126277F")) at 12:00, 2 lines, 2 lines
initially, none changed, user ID #cmd("USER1"). Its member record holds
#cmd("A0") (160) bytes: two records of 80.

#fig(caption: [xmit370 list -v SRC.xmit])[
  #screen(raw(read("../ex/apx-lmodfmt/src-list.txt")))
] <apx-lmodfmt-src-list>
