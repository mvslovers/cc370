#import "../bookmaster/bookmaster.typ": *

= Object Module Format <apx-objfmt>

#idx("object module", "format")
This appendix describes the object module as as370 writes it and as ld370
reads it. The format is that of the OS/360 and MVS assemblers and compilers,
so an object module written by the MVS assembler (IFOX00) can be linked by
ld370, and one written by as370 can be link-edited by IEWL on MVS. Where
as370 writes only part of what the format allows, the tables say so.

The format is given for a reader who wants to inspect an object module,
compare two of them, or write one with a program of their own. file370
shows the external symbols and the entry point of an object module (see
@file370)\; for anything else, a hexadecimal dump and this appendix are the
tools. @apx-objfmt-ex takes one module apart byte by byte.

== Records <apx-objfmt-card>

#idx("card image")
#idx("EBCDIC", "in object modules")
An object module is a sequence of 80-byte records, card images, with no
separators between them: the file is a multiple of 80 bytes long. Character
fields are in EBCDIC, code page 037. Numeric fields are unsigned binary,
most significant byte first. An address is three bytes long.

Every record shares the frame in @apx-objfmt-frame. A column that a record
does not use holds an EBCDIC blank, #cmd("X'40'"), not a zero.

#tab(caption: [Columns common to all object module records])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [1], [1], [#cmd("X'02'"), which marks the card as an object module
      record.],
    [2--4], [3], [The record type in EBCDIC: #cmd("ESD"), #cmd("TXT"),
      #cmd("RLD") or #cmd("END").],
    [5--72], [68], [The contents, which depend on the record type.],
    [73--80], [8], [Identification and sequence number, in EBCDIC. as370
      numbers the records of a module from 1. When the source has a named
      #cmd("TITLE") statement, its name stands at the left of the field and
      the number fills the remaining columns, with leading zeros:
      #cmd("DEMO0001"). Otherwise the number takes all eight columns:
      #cmd("00000001").],
  )
] <apx-objfmt-frame>

as370 writes the records of a module in this order: all ESD records, then
all TXT records, then all RLD records, and one END record last.

#idx("ld370", "records ignored")
ld370 reads the four record types and passes over every other card: a card
whose first byte is not #cmd("X'02'"), and a card with #cmd("X'02'") and
another type, such as #cmd("SYM"). A module mixed with other cards therefore
links as if they were not there.

== External Symbol Dictionary <apx-objfmt-esd>

#idx("ESD record")
#idx("external symbol dictionary")
The ESD records name the control sections of the module, its entry points
and the external symbols it refers to. Each ESD record holds up to three
items of 16 bytes. as370 writes the items in the order in which the source
declares the symbols, three to a record.

#tab(caption: [ESD record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [1--4], [4], [#cmd("X'02'") and #cmd("ESD").],
    [5--10], [6], [Blank.],
    [11--12], [2], [The number of bytes of ESD items in the record: 16, 32
      or 48.],
    [13--14], [2], [Blank.],
    [15--16], [2], [The ESD identifier of the first item in the record that
      has one. On a record that holds only LD items, which have no
      identifier, the field is blank.],
    [17--64], [48], [One to three ESD items, described in
      @apx-objfmt-esd-item. Unused item positions are blank.],
    [65--72], [8], [Blank.],
    [73--80], [8], [Identification and sequence number.],
  )
] <apx-objfmt-esd-rec>

#idx("ESD identifier")
*The ESD identifier* is the number by which the other records of the module
refer to a symbol. Identifiers are not written in the items. They are given
in order, starting with 1 at the first item of the module and counting every
item except LD items: the identifier of an item is the number in columns
15--16 of its record plus the number of items before it in the record that
are not LD items.

#tab(caption: [ESD item])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [8], [The symbol, in EBCDIC, padded with blanks. Blank for private
      code.],
    [8], [1], [The type of the item, from @apx-objfmt-esd-types.],
    [9], [3], [SD, PC, CM: the address of the section. LD: the address of
      the entry point. ER, WX, XD: zero.],
    [12], [1], [XD: the alignment, less one: #cmd("X'00'") byte,
      #cmd("X'01'") halfword, #cmd("X'03'") fullword, #cmd("X'07'")
      doubleword. All other types: blank.],
    [13], [3], [SD, PC, CM, XD: the length of the section or of the
      external dummy section. LD: the ESD identifier of the section that
      contains the entry point. ER, WX: blank.],
  )
] <apx-objfmt-esd-item>

The addresses are those the assembler assigned. as370 assembles all control
sections of a source into one address space, each section beginning on a
doubleword boundary, so the second section of a module does not begin at 0.
The length of a section is the length of its own contents, without the
padding that follows it.

#tab(caption: [ESD item types])[
  #table(columns: (0.55in, 0.6in, 1fr),
    [Type], [Code], [Meaning],
    [SD], [#cmd("X'00'")], [Section definition: a named control section
      (#cmd("CSECT"), #cmd("START")).],
    [LD], [#cmd("X'01'")], [Label definition: an entry point named by
      #cmd("ENTRY"). It has no ESD identifier of its own.],
    [ER], [#cmd("X'02'")], [External reference: a symbol named by
      #cmd("EXTRN") or in a #cmd("V")-type address constant.],
    [PC], [#cmd("X'04'")], [Private code: an unnamed control section.],
    [CM], [#cmd("X'05'")], [Common section, named by #cmd("COM"). It
      carries no text: the address is 0 and the length is the size the
      #cmd("DS") statements of the section reserve, over all the
      #cmd("COM") statements of the same name.],
    [XD], [#cmd("X'06'")], [External dummy section (in linkage editor terms,
      a pseudo register): a name defined by #cmd("DXD"), or a
      #cmd("DSECT") named in a #cmd("Q")-type address constant. file370
      shows it as #cmd("PR").],
    [WX], [#cmd("X'0A'")], [Weak external reference, named by
      #cmd("WXTRN"). The link does not fail when nothing defines it.],
  )
] <apx-objfmt-esd-types>

ld370 takes the type from the low-order four bits of the type byte.

#note[An #cmd("ENTRY") statement that names a control section produces no
LD item. The SD item already makes the section an entry point.]

== Text <apx-objfmt-txt>

#idx("TXT record")
The TXT records carry the contents of the module: instructions and
constants, as they are to be loaded. Each record carries up to 56 bytes of
consecutive storage. Storage reserved by #cmd("DS") and not otherwise
defined is not carried in any record.

#tab(caption: [TXT record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [1--4], [4], [#cmd("X'02'") and #cmd("TXT").],
    [5], [1], [Blank.],
    [6--8], [3], [The address of the first byte of text in the record.],
    [9--10], [2], [Blank.],
    [11--12], [2], [The number of bytes of text, 1 to 56.],
    [13--14], [2], [Blank.],
    [15--16], [2], [The ESD identifier of the control section the text
      belongs to.],
    [17--72], [56], [The text. Columns after the last byte of text are
      blank.],
    [73--80], [8], [Identification and sequence number.],
  )
] <apx-objfmt-txt-rec>

as370 writes the text in the order the assembler produced it. A record ends
when it is full, when the next byte is not at the following address, and when
the next byte belongs to another section. The literal pool at the end of a
section therefore comes in a record of its own, after the text of any later
section. When an #cmd("ORG") statement moves back over text already
produced, the bytes are written again in a further record for the same
addresses, and the later record replaces the earlier bytes.

ld370 places text by its address. It does not use columns 15--16.

== Relocation Dictionary <apx-objfmt-rld>

#idx("RLD record")
#idx("relocation dictionary")
#idx("address constant", "in the object module")
The RLD records list the address constants of the module: every place whose
value depends on where a control section is loaded or on an external symbol.
The linkage editor uses them to fill in the constants and passes them on to
the load module.

#tab(caption: [RLD record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [1--4], [4], [#cmd("X'02'") and #cmd("RLD").],
    [5--10], [6], [Blank.],
    [11--12], [2], [The number of bytes of RLD items in the record.],
    [13--16], [4], [Blank.],
    [17--72], [56], [RLD items, described below. Columns after the last
      item are blank.],
    [73--80], [8], [Identification and sequence number.],
  )
] <apx-objfmt-rld-rec>

An RLD item is 8 or 4 bytes long. The long form names the two ESD identifiers
the constant depends on: the *relocation pointer*, the symbol whose address
the constant holds, and the *position pointer*, the control section in which
the constant stands. When the previous item has the same two pointers, the
item can leave them out, which the previous item announces in its flag byte.

#tab(caption: [RLD item])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Offset], [Length], [Contents],
    [0], [2], [The relocation pointer: the ESD identifier of the symbol.
      For a symbol that is an LD item, it is the identifier of the section
      that contains it. For a #cmd("Q")-type constant, the XD item. For a
      #cmd("CXD"), zero.],
    [2], [2], [The position pointer: the ESD identifier of the section that
      contains the constant.],
    [4], [1], [The flag byte, described in @apx-objfmt-rld-flag.],
    [5], [3], [The address of the constant, as the assembler assigned it.],
  )
] <apx-objfmt-rld-item>

An item whose predecessor has the continuation bit set consists only of the
flag byte and the address, offsets 4 to 7 of the table. as370 sorts the items
by position pointer, then relocation pointer, then address, so that items
with the same pointers come together. It starts every record with a long
item, so that each record can be read by itself.

#tab(caption: [RLD flag byte])[
  #table(columns: (0.85in, 1fr),
    [Bits], [Meaning],
    [#cmd("X'F0'")], [The type of the constant. #cmd("X'00'"): an
      #cmd("A")-type constant. #cmd("X'10'"): a #cmd("V")-type constant.
      #cmd("X'20'"): a #cmd("Q")-type constant, the offset of an external
      dummy section. #cmd("X'30'"): a #cmd("CXD"), the total length of all
      external dummy sections.],
    [#cmd("X'0C'")], [The length of the constant, less one:
      #cmd("X'04'") 2 bytes, #cmd("X'08'") 3 bytes, #cmd("X'0C'") 4 bytes.],
    [#cmd("X'02'")], [Negative relocation: the address is subtracted, as in
      #cmd("A(10-MAIN)").],
    [#cmd("X'01'")], [Continuation: the next item has the same pointers and
      is written in the short form.],
  )
] <apx-objfmt-rld-flag>

The usual flag bytes are therefore #cmd("X'0C'") for
#cmd("DC A(")#var("x")#cmd(")"), #cmd("X'1C'") for
#cmd("DC V(")#var("x")#cmd(")"), #cmd("X'08'") for
#cmd("DC AL3(")#var("x")#cmd(")") and #cmd("X'04'") for
#cmd("DC AL2(")#var("x")#cmd(")"), each with #cmd("X'01'") added when a
short item follows.

== Common and External Dummy Sections <apx-objfmt-pr>

#idx("COM")#idx("DXD")#idx("CXD")#idx("Q-type address constant")
#idx("common section")#idx("external dummy section")#idx("pseudo register")
Three kinds of storage are described in the object module without being
part of its text:

- *A common section* (#cmd("COM")) is storage that several modules share
  by name. as370 gives it a location counter of its own, starting at 0, and
  a later #cmd("COM") statement with the same name continues it. Only
  #cmd("DS") belongs there\; the section has a CM item and no TXT records.
- *An external dummy section* (#cmd("DXD")) is a piece of storage whose
  place the linkage editor decides: it adds up the lengths of all external
  dummy sections of the program, aligning each, and assigns each an offset.
  The operand of #cmd("DXD") is written like that of #cmd("DS"), and the
  length and alignment it gives become the XD item. A #cmd("DSECT") named
  in a #cmd("Q")-type constant becomes an XD item as well.
- #cmd("DC Q(")#var("name")#cmd(")") is a 4-byte constant that receives the
  offset of the external dummy section #var("name"), and #cmd("CXD") a
  fullword that receives the total length of all of them. The
  #cmd("Q")-type constant is written as zeros, the #cmd("CXD") field is
  not written at all\; the RLD item, with type #cmd("X'20'") or
  #cmd("X'30'"), tells the linkage editor what to put there.

@apx-objfmt-pr-dump shows the object module of the source in
@apx-objfmt-pr-src.

#fig(caption: [PR, a source with a common section and external dummy
  sections])[
  #code(read("../ex/apx-objfmt/pr.asm"))
] <apx-objfmt-pr-src>

#fig(caption: [The object module pr.o])[
  #code(read("../ex/apx-objfmt/pr-o.txt"))
] <apx-objfmt-pr-dump>

#deflist(width: 1.3in,
  [Record 1, ESD], [#cmd("WORK"), type #cmd("06"), alignment #cmd("03")
    and length 8 (#cmd("2F"))\; #cmd("FLAG"), alignment #cmd("00") and
    length 1\; #cmd("AREA"), type #cmd("05"), address 0, length
    #cmd("2A"): the 40 bytes of the first #cmd("COM") statement and the 2 of
    the second.],
  [Record 2, ESD], [The SD item #cmd("PROG"), identifier 4, length
    #cmd("0C"): the two #cmd("Q")-type constants and the #cmd("CXD").],
  [Record 3, TXT], [Only the 8 bytes of the two #cmd("Q")-type constants,
    as zeros. The #cmd("CXD") at offset 8 is not written.],
  [Record 4, RLD], [#cmd("00 00 00 04 3C 00 00 08"): the #cmd("CXD"),
    relocation pointer 0, type #cmd("X'30'"), length 4.
    #cmd("00 01 00 04 2C 00 00 00") and #cmd("00 02 00 04 2C 00 00 04"):
    the two #cmd("Q")-type constants, for #cmd("WORK") and #cmd("FLAG").],
)

The #cmd("Q")-type operand must name a #cmd("DXD") or a #cmd("DSECT")
defined before it: a name that is defined later is flagged with IFO231, a
name that is neither with IFO207. A #cmd("COM") statement without a name
is not supported by as370. See @ld370-layout for what ld370 does with these
items.

== End Record <apx-objfmt-end>

#idx("END record")
#idx("IDR", "in the object module")
#idx("translator identification")
The END record closes the module. It gives the entry point, when the source
names one on its #cmd("END") statement, and identifies the program that
wrote the module.

#tab(caption: [END record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [1--4], [4], [#cmd("X'02'") and #cmd("END").],
    [5], [1], [Blank.],
    [6--8], [3], [The address of the entry point. Blank when the
      #cmd("END") statement has no operand.],
    [9--14], [6], [Blank.],
    [15--16], [2], [The ESD identifier of the section that contains the entry
      point. Blank when columns 6--8 are blank.],
    [17--32], [16], [Blank.],
    [33--52], [20], [Translator identification, described below.],
    [53--72], [20], [Blank.],
    [73--80], [8], [Identification and sequence number.],
  )
] <apx-objfmt-end-rec>

The translator identification is the data from which IEWL builds the
translator record of the load module. as370 writes it in EBCDIC as follows:

#tab(caption: [Translator identification in the END record])[
  #table(columns: (0.85in, 0.6in, 1fr),
    [Columns], [Length], [Contents],
    [33--42], [10], [The program: #cmd("ASM370") followed by four blanks.
      IFOX00 writes its program number here.],
    [43], [1], [Blank.],
    [44--47], [4], [The version and modification level: #cmd("0100").],
    [48--52], [5], [The date of the assembly, #var("yyddd"): two digits of
      the year and the day of the year.],
  )
] <apx-objfmt-end-idr>

#idx("ASMDATE")
#idx("reproducible output")
The date is the date of the workstation, so the same source assembled on two
days gives two object modules that differ in this field and, unless the
source uses #cmd("&SYSDATE") or #cmd("&SYSTIME"), nowhere else.
To fix it, set the environment variable #cmd("ASMDATE") to a date in the
form #var("mm")#cmd("/")#var("dd")#cmd("/")#var("yy"). The same variable sets
the date that the assembler variable #cmd("&SYSDATE") returns, and
#cmd("ASMTIME"), in the form #var("hh")#cmd(".")#var("mm"), sets
#cmd("&SYSTIME").

ld370 reads only columns 6--8 and 15--16 of the END record, and only when
columns 6--8 are not blank. It does not copy the translator identification
into the load module (see @ld370-idr).

== Example <apx-objfmt-ex>

The source in @apx-objfmt-src has two control sections, an entry point, an
external reference, a weak external reference, and address constants of
lengths 2, 3 and 4. It was assembled with

```
ASMDATE=10/04/26 as370 -o fmt.o fmt.asm
```

#fig(caption: [FMT, a source with the usual items of a module])[
  #code(read("../ex/apx-objfmt/fmt.asm"))
] <apx-objfmt-src>

@apx-objfmt-v shows what file370 reports for the object module, and
@apx-objfmt-dump the module itself, as #cmd("xxd -g1 -c16") displays it
without its character column. Each record takes five lines of the dump.

#fig(caption: [file370 -v fmt.o])[
  #screen(raw(read("../ex/apx-objfmt/fmt-o-v.txt")))
] <apx-objfmt-v>

#fig(caption: [The object module fmt.o])[
  #code(read("../ex/apx-objfmt/fmt-o.txt"))
] <apx-objfmt-dump>

#deflist(width: 1.3in,
  [Record 1, ESD], [Three items, 48 bytes (#cmd("00 30")). The first item
    is the LD item #cmd("ALT")\: type #cmd("01"), address #cmd("000008"),
    and #cmd("000003"), the identifier of #cmd("MAIN"), which contains it.
    The ER item #cmd("SUB") and the WX item #cmd("OPT") follow, with zero
    addresses and blank lengths. #cmd("SUB") is the first item with an
    identifier, so columns 15--16 hold #cmd("00 01")\; #cmd("OPT") is
    therefore 2. Columns 73--80 hold #cmd("DEMO0001"), from the name of the
    #cmd("TITLE") statement.],
  [Record 2, ESD], [The SD items #cmd("MAIN") (identifier 3, address 0,
    length #cmd("1C")) and #cmd("SECOND") (identifier 4, address
    #cmd("20"), length 6).],
  [Records 3--5, TXT], [20 bytes of #cmd("MAIN") at address 0, 6 bytes of
    #cmd("SECOND") at #cmd("20"), and the literal pool of #cmd("MAIN"), the
    4 bytes of #cmd("=V(SUB)"), at #cmd("18"). The literal pool comes last
    because it belongs to #cmd("MAIN") but was produced after the text of
    #cmd("SECOND").],
  [Record 6, RLD], [40 bytes of items. #cmd("00 01 00 03 1C 00 00 18"):
    #cmd("SUB") in #cmd("MAIN"), a 4-byte #cmd("V")-type constant at
    #cmd("18"). The same for #cmd("OPT") at #cmd("10"). Then
    #cmd("00 03 00 03 0D 00 00 08"), #cmd("A(ALT)")\: #cmd("ALT") is an LD
    item, so the relocation pointer is 3, the section #cmd("MAIN")\; the
    flag #cmd("0D") announces a short item, #cmd("08 00 00 0C"), the 3-byte
    #cmd("AL3(MAIN)"). The last two items, in #cmd("SECOND"), are a long
    and a short one: #cmd("A(MAIN)") at #cmd("20") and the 2-byte
    #cmd("AL2(ALT)") at #cmd("24").],
  [Record 7, END], [The entry point, address #cmd("000000") in section 3,
    and from column 33 the translator identification: #cmd("ASM370"), the
    version #cmd("0100") and the date #cmd("26277"), day 277 of 2026.],
)
