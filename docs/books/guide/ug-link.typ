#import "../bookmaster/bookmaster.typ": *

= Linking and Libraries <ug-link>

#idx("linking")
#idx("ld370")
Linking turns object modules into a load module, the form in which MVS
loads and runs a program. With cc370 the link runs on the workstation: ld370
takes the place of the MVS linkage editor, IEWL, and writes the load module
together with the file that carries it to MVS. This chapter explains what a
load module is made of, how a C program and an assembler program are
linked, how to build and use a library of your own, and how to put several
programs into one load library.

The examples continue with SUMUP and GREET from @ug-asm. Every option of
ld370 and ar370 is described in the _cc370 Command Reference_, Chapter 3,
“The ld370 Command”, and Chapter 4, “The ar370 Command”.

== What a Load Module Is <ug-link-lmod>

#idx("load module")
#idx("directory entry")
On MVS a load module is a member of a load library, a partitioned data set
with undefined-length records. Its properties live in two places:

- *The member* holds the program: the external symbol dictionary, the text,
  and the relocation dictionary that tells program fetch which address
  constants to adjust when it loads the module. This is the file that ld370
  writes to the name given by #cmd("-o").
- *The directory entry* of the member, in the directory of the library,
  holds the entry point, the length of the module, its attributes, such as
  reentrant, and its authorization code.

A file on the workstation has no library directory, so the second half can
only travel in the two transport files that ld370 writes on request: the
IEBCOPY unloaded form (#cmd("-iebcopy")) and the TSO TRANSMIT file
(#cmd("-xmit")), which holds the unloaded form. Both carry a directory.
*The TRANSMIT file is the one you send to MVS*\; the unloaded form is the
one you keep when modules are to be packed into one library later, as
@ug-link-pack shows.

== Linking a C Program <ug-link-c>

#idx("linking", "C program")
#idx("@@CRT0")
When cc370 links, it runs ld370 with everything a C program needs:

- the start-up object #cmd("crt0.o") in front of your object modules\;
- the entry point #cmd("@@CRT0"), the C start-up, which builds the run time
  and then calls #cmd("main")\;
- the libraries #cmd("-lcc370rt -lc -lcc370rt") after your object modules:
  the run-time support routines of the compiler and the C library.

So the command in @ug-asm-sumup-session,

```
cc370 -o sumup sumup.o addup.o report.o -flinker-output=xmit
```

is all a C program needs. To pass an option to ld370, write it after
#cmd("-Wl,"), with a comma in place of each blank:
#cmd("-Wl,--map,sumup.map") writes a load map.

You can also run ld370 yourself, for example from a build system that calls
each tool directly. Then you name what cc370 would add. @ug-link-manual
links SUMUP that way. #cmd("cc370 -print-file-name=libc.a") gives the
directory of the C library, which also holds #cmd("crt0.o").

#fig(caption: [Linking SUMUP with ld370 directly])[
  #screen(raw(read("../ex/ug-link/manual.txt")))
] <ug-link-manual>

#note[Without #cmd("--entry @@CRT0"), ld370 takes the entry point from the
#cmd("END") statement of the first object module that names one. For a C
program that is the #cmd("@@MAIN") stub of the compiler, which only branches
to #cmd("@@CRT0"). Give #cmd("--entry @@CRT0") anyway, so that the entry
point is the one the program is built for.]

== Linking an Assembler Program <ug-link-asm>

#idx("linking", "assembler program")
A program written entirely in assembler, such as GREET, is linked with ld370
alone, as in @ug-asm-greet-session:

```
ld370 -o GREET greet.o -xmit
```

It needs no start-up object and no library. Its entry point is the one
named on the #cmd("END") statement, #cmd("END GREET"), or, if that names
none, the beginning of the module. #cmd("--entry") #var("name") overrides
both.

== Building an Object Library <ug-link-ar>

#idx("object library")
#idx("ar370")
An object library is a collection of object modules in one file. On MVS it
would be a partitioned data set that IEWL searches through #cmd("SYSLIB")\;
on the workstation it is an archive with the extension #cmd(".a"), made by
ar370. Besides the object modules, ar370 writes an index of the names that
each module defines, both control sections and entry points. ld370 uses the
index to find the module that defines a name.

The two assembler routines of SUMUP are a good candidate for a library: any
C program that needs them can then be linked with #cmd("-lsum"), and gets
only the routines it calls. To build the library and link SUMUP against it:

+ Put the object modules into the library #cmd("libsum.a"):
  ```
  ar370 rc libsum.a addup.o report.o
  ```
  *ar370 always writes the library anew* from the object modules named: it
  does not add to an existing library. Name every member each time.
+ List the library with #cmd("ar370 t"), to see the members and the names in
  the index.
+ Link SUMUP with #cmd("-L.") and #cmd("-lsum"): #cmd("-L") names the
  directory that holds the library, #cmd("-l") its name without
  #cmd("lib") and #cmd(".a").

@ug-link-lib-session shows the steps.

#fig(caption: [Building libsum.a and linking SUMUP with it])[
  #screen(raw(read("../ex/ug-link/lib.txt")))
] <ug-link-lib-session>

== Automatic Library Call <ug-link-autocall>

#idx("automatic library call")
#idx("load map")
The object module #cmd("sumup.o") refers to #cmd("ADDUP"), #cmd("REPORT")
and #cmd("ATOI"), but defines none of them. For each name that the modules
read so far do not define, ld370 searches the libraries in the order they
were given, takes the first module that defines it, and adds it to the load
module. That module may refer to further names, which are searched in turn,
until nothing more can be resolved. This is the automatic library call of
IEWL, and it is why a C program needs no #cmd("-lc"): cc370 names the C
library on every link.

The load map shows what was taken from where. @ug-link-map shows the
beginning of the map of SUMUP from @ug-link-lib-session and the two
sections taken from #cmd("libsum.a"). In the figure, #cmd("$LIB") stands for
the directory of the C library, #cmd("cc370/lib") under the installation
prefix.

#fig(caption: [The load map of SUMUP (excerpts)])[
  #let m = read("../ex/ug-link/sumup.map").split("\n")
  #screen(raw((m.slice(0, 12) + ("...",)
    + m.filter(l => l.contains("libsum.a")) + ("...",)
    + m.slice(m.len() - 4)).join("\n")))
] <ug-link-map>

Each line gives a section with its type, its origin and length in the load
module, and where it came from. C code, your own and that of the C library,
is compiled into unnamed sections, type #cmd("PC"), so their lines have no
name\; the entry points of a section follow it, indented. The first line gives the member name, the
entry point and the length of the module.

#idx("weak external reference")
The two names under #cmd("UNRESOLVED") are not an error. Type #cmd("WX")
marks a weak external reference: a name that the program may define and need
not. The C start-up refers to #cmd("@@STKLEN") in this way, so that a program
can choose the size of its stack, for example with
#cmd("unsigned __stklen = 64 * 1024;") in a C source. An unresolved ordinary
reference, on the other hand, ends the link, as @ug-diag-unres shows.

When two libraries define the same name, the first library given wins.
Give your own libraries before the C library, which cc370 does by putting
#cmd("-l") options of the command line ahead of its own.

== Optional Functions: Weak References <ug-link-weak>

#idx("weak external reference", "in C")
Sometimes a program can use a function when it is there and do without it
when it is not: a trace routine that only a test build links, an exit that
an installation may supply, a component that is linked into some modules
and not into others. Declare such a function weak where you call it, and
test its address before the call:

```
extern int trace_hook(const char *msg) __attribute__((weak));

    if (trace_hook != 0)
        trace_hook("main entered");
```

cc370 writes a weak external reference, #cmd("WXTRN"), for it. When the link
includes a module that defines #cmd("trace_hook"), the call reaches it\;
when it does not, the address is 0, the link ends with return code 0, and
the load map lists #cmd("TRACE@HO") with type #cmd("WX") under
#cmd("UNRESOLVED"), like #cmd("@@STKLEN") in @ug-link-map.

Three rules follow from how the linkage editor treats a weak reference:

- *Name the defining object module in the link.* Automatic library call
  does not search for a weak reference, so a library member that defines
  it is not taken unless the link needs it for another reason.
  @ug-link-weak-fig shows both links: the first, with the definition only
  in #cmd("libhook.a"), leaves the reference unresolved\; the second, with
  #cmd("hook.o") named, resolves it. To take the member from a library,
  give #cmd("-Wl,--include,hook").
- *Never call it without the test.* An unresolved weak reference is 0, and
  a call through it branches to address 0.
- *Declare it weak where it is referenced, not where it is defined.* MVS has
  no weak definition. cc370 warns about one, and the function it defines
  cannot be reached from other modules (the last command of
  @ug-link-weak-fig). Define the function as usual.

#fig(caption: [A weak reference, left unresolved and resolved])[
  #screen(raw(read("../ex/cc370/weak.txt")))
] <ug-link-weak-fig>

#cmd("__CC370_WEAK__") is defined when the compiler supports weak
references\; a source that must also compile with an older cc370 can test
it with #cmd("#ifdef").

== Module Attributes <ug-link-attr>

#idx("attributes", "of a load module")
#idx("RENT")#idx("REUS")#idx("REFR")#idx("authorization code")
The directory entry tells MVS how a module may be used. @ug-link-attr-tab
lists the attributes you set when you link.

#tab(caption: [Attributes of a load module])[
  #table(columns: (1.2in, 1fr),
    [Option], [Meaning, and when to give it],
    [#cmd("--reus")], [Serially reusable: one copy may be used by one task
      after another, without being loaded again. Give it when the module
      sets up again, each time it is entered, all the storage it changes.],
    [#cmd("--rent")], [Reentrant: one copy may be used by several tasks at
      once. Give it only when the module changes none of its own storage.
      IEWL's #cmd("RENT") is #cmd("--rent --reus").],
    [#cmd("--refr")], [Refreshable: the module may be replaced by a fresh
      copy at any time. Give it only to a module that never changes
      itself.],
    [#cmd("--ac 1")], [Authorization code 1: the module runs APF-authorized
      when it is loaded from an APF-authorized library. Give it only to a
      program that needs to be authorized.],
  )
] <ug-link-attr-tab>

*A module has none of these attributes unless you give them*, as with IEWL.
That is always safe: a module without them is loaded afresh where one with
them might be shared. Give an attribute only when the module deserves it.
A C program keeps its static variables in the load module itself, so it is
not reentrant if it changes any of them. GREET changes none of its storage
and can be marked #cmd("--rent --reus")\; CLOCK, which stores the date into
itself, cannot.

The attributes are part of the directory entry, so they reach MVS only
through the transport files. Give them on the link that writes
#cmd("-iebcopy") or #cmd("-xmit"). With cc370, pass them with
#cmd("-Wl,"): #cmd("-Wl,--rent,--reus").

== Several Programs in One Library <ug-link-pack>

#idx("--pack option")
#idx("load library", "with several members")
Each link writes a TRANSMIT file with one member. To send several programs
to MVS together, link each into its #cmd(".iebcopy") file and pack those
into one TRANSMIT file with #cmd("ld370 --pack"). The result is received on
MVS as one load library with all the members.

To build the load library of SUMUP and GREET:

+ Link SUMUP with #cmd("-flinker-output=iebcopy"), which writes
  #cmd("sumup.iebcopy"), member #cmd("SUMUP").
+ Link GREET with #cmd("-iebcopy") and the attributes it deserves, which
  writes #cmd("GREET.iebcopy").
+ Pack the two into #cmd("sumlib.xmit"). #cmd("--dsn") records the name of
  the library, #cmd("USER1.SUMUP.LOAD")\; it is the name that RECEIVE uses
  when it is given no other.

@ug-link-pack-session shows the steps, and file370 shows the directory of
the packed library: each member keeps its own entry point and attributes.

#fig(caption: [Packing SUMUP and GREET into one library])[
  #screen(raw(read("../ex/ug-link/pack.txt")))
] <ug-link-pack-session>

*Pack the #cmd(".iebcopy") files, not the member files.* A member file
carries no directory entry. ld370 then looks up the entry point in the
external symbol dictionary of the member, by the name given with
#cmd("--entry") or else #cmd("@@CRT0"), which is right for a C program, and
uses entry point 0 for a member without #cmd("@@CRT0"), such as an assembler
program. The attributes and the authorization code it cannot recover: the
member gets those of the #cmd("--pack") command, none unless you give them,
and ld370 warns about every member file.

#idx("block size", "of a load library")
A load library has a block size, and no record of a module may be longer.
ld370 builds modules for a block size of 15040 unless told otherwise with
#cmd("--blocksize"), and records that block size for the library that
RECEIVE creates. Such modules fit any load library with a block size of
15040 or more. If you are going to copy them into an existing library with a
smaller block size, link them with #cmd("--blocksize") set to that size, and
give the same value to #cmd("--pack").
