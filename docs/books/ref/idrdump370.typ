#import "../bookmaster/bookmaster.typ": *

= The idrdump370 Command <idrdump370>

#idx("idrdump370")
#idx("IDR", "displaying")
#idx("identification record")
The idrdump370 command displays the CSECT identification records (IDRs) of
a load module. IDRs are the records in a load module that say what built it
and what changed it afterwards: the linkage editor records its own name and
the date of the link, and SPZAP, the service aid that modifies a module in
place, adds an entry for each control section it changes. Each entry names
its control section, so idrdump370 can tell whether a particular control
section of a module was modified, not only whether the module was.

idrdump370 reads a load module on the workstation, normally one that ld370
has written (see @ld370). It only reads; it never changes a module.

== Invoking idrdump370 <idrdump370-invoke>

#idx("idrdump370", "syntax")
#syntax(read("../syntax/idrdump370-main.txt"))

#syntax(title: "Option:", read("../syntax/idrdump370-option.txt"))

=== Operands

#deflist(width: 1.1in,
  [#var("member")], [is the load module to read: one member, as ld370
    writes it with #cmd("-o") (see @idrdump370-input). Exactly one file is
    read; a second file name is an error.],
  [#cmd("--csect") #var("name")], [reports only the SPZAP and user data
    entries that name the control section #var("name"). The linkage editor
    and translator records do not belong to a section and are not shown. An
    SPZAP record that holds no entries is still reported as such.],
  [#cmd("--json")], [writes the result as a JSON object instead of text.
    See @idrdump370-json.],
  [#cmd("-h"), #cmd("--help")], [displays a summary of the options and
    ends.],
  [#cmd("-V"), #cmd("--version")], [displays the toolchain version and the
    commit from which idrdump370 was built, and ends. The short form is a
    capital #cmd("V").],
)

== What idrdump370 Reads <idrdump370-input>

#idx("load module", "member file")
The input is a bare load module member: the record stream that ld370 writes
to the file named by #cmd("-o"), beginning with the composite external symbol
dictionary. idrdump370 follows the record chain from the start of the member
and reads every IDR it meets, up to the one that carries the last-record
flag. It does not search the file for bytes that look like an IDR, so a text
record is never mistaken for one.

The transport files that ld370 writes beside the member, #cmd(".iebcopy")
and #cmd(".xmit"), are not read, and neither is an object module. For any of
these idrdump370 finds no IDR, reports #cmd("no IDR records") and ends with
return code 1; it does not say that the file is of the wrong kind.

== What idrdump370 Shows <idrdump370-output>

#idx("idrdump370", "output")
The first line names the file and gives the number of control sections in
the composite external symbol dictionary. Each following line describes one
IDR, or one entry of an IDR, and begins with #cmd("@") and the offset of the
record in the member, in hexadecimal. @idrdump370-types lists what is shown
for each type of record.

#tab(caption: [IDR types shown by idrdump370])[
  #table(columns: (1.05in, 1fr),
    [Shown as], [Contents],
    [#cmd("HMASPZAP")], [One line for each entry that SPZAP has recorded:
      #cmd("csect=") the control section the entry names, #cmd("cesdid=")
      its number in the composite external symbol dictionary,
      #cmd("date=") the date of the change, and #cmd("zap=") the
      identifier given to SPZAP. #cmd("[chain continues]") means that
      further entries follow in another record. A record without entries
      is shown once, as #cmd("no entries").],
    [#cmd("LKED")], [The linkage editor record: its length in bytes and up
      to 40 characters of its contents, beginning with the program name of
      the linkage editor.],
    [#cmd("translator")], [A translator record, shown in the same way as
      #cmd("LKED").],
    [#cmd("user")], [One line for each entry of user data: #cmd("csect="),
      #cmd("cesdid="), #cmd("date=") and #cmd("id="), the identifying text
      of the entry.],
    [#cmd("unknown")], [A record of any other type, with its length.],
  )
] <idrdump370-types>

#cmd("[LAST]") marks the record that ends the chain. An entry whose section
number does not appear in the composite external symbol dictionary is shown
with #cmd("csect=(unknown)").

#idx("IDR", "dates")
The SPZAP and user data dates are shown as stored, in the form
#var("yyddd"): two digits of the year and the day of the year. The record
holds no century, and idrdump370 does not supply one. The linkage editor and
translator records are not decoded: their contents are shown as characters,
and their binary fields, among them the version and the date and time of the
link, appear as #cmd("?") or as arbitrary characters.

=== What ld370 Writes <idrdump370-ld370>

#idx("ld370", "IDRs written by")
A member written by ld370 holds two IDRs:

- an SPZAP record of 251 bytes with no entries, which leaves room for SPZAP
  to record changes made later on MVS;
- a linkage editor record of 22 bytes naming #cmd("LD370"), with its
  version and the date and time of the link. The date and time come from
  the workstation clock, or from the environment variables
  #cmd("LDDATE") (#var("yyddd")) and #cmd("LDTIME") (#var("hhmmss")) when
  they are set.#idx("LDDATE")#idx("LDTIME")

ld370 writes no translator records. A module that shows more records than
these has been processed by another program since it was linked, or was not
linked by ld370.

== JSON Output <idrdump370-json>

#idx("idrdump370", "JSON output")
With #cmd("--json"), idrdump370 writes one JSON object with these members:

#deflist(width: 1.1in,
  [#cmd("file")], [the file name as given.],
  [#cmd("idr")], [an array with one object for each line of the text form,
    except that an SPZAP record without entries has no object. Every object
    has #cmd("record"), the offset of the record as a decimal number,
    #cmd("subtype") and #cmd("last"). SPZAP entries add #cmd("chain"),
    #cmd("csect"), #cmd("cesdid"), #cmd("date") and #cmd("zap")\; user data
    entries add #cmd("csect"), #cmd("cesdid"), #cmd("date") and
    #cmd("id")\; the other records add #cmd("bytes") and, for linkage editor
    and translator records, #cmd("text"). A #cmd("csect") that cannot be
    resolved is #cmd("null").],
  [#cmd("records")], [the number of IDRs read, including those that add
    nothing to #cmd("idr").],
  [#cmd("malformed")], [#cmd("true") if the record chain could not be
    followed to its end.],
)

== Return Codes <idrdump370-rc>

#idx("idrdump370", "return codes")
#tab(caption: [idrdump370 return codes])[
  #table(columns: (0.9in, 1fr),
    [Code], [Meaning],
    [0], [At least one IDR was read and displayed.],
    [1], [No IDR was found. This is also the result for a file that is not
      a load module member.],
    [2], [The command was given incorrectly, or the file could not be
      opened or read, or it is empty.],
  )
] <idrdump370-rc-tab>

== Example <idrdump370-example>

@idrdump370-session assembles the program of @dasm370-count-asm, links it
with ld370 at a fixed date and time, and displays its IDRs, first as text and
then as JSON. The last command shows the result for an object module.

#fig(caption: [Displaying the IDRs of a module linked by ld370])[
  #screen(raw(read("../ex/idrdump370/session.txt")))
] <idrdump370-session>

The SPZAP record at offset #cmd("X'18'") has no entries: nothing has
modified the module. The linkage editor record at #cmd("X'113'") ends the
chain. Its text begins with #cmd("LD370")\; the characters after it are the
binary version, date (#cmd("26277")) and time (#cmd("120000")) fields, which
idrdump370 does not decode.
