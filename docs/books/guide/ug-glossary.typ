#import "../bookmaster/bookmaster.typ": *

= Glossary <ug-glossary>

This glossary defines the terms of MVS and of the toolchain that you meet in
this book and in the _CC/370 Command Reference_. A term printed in _italics_
in a definition has an entry of its own.

#let g(..items) = deflist(width: 1.45in, ..items.pos().enumerate().map(
  ((i, x)) => if calc.even(i) { par(justify: false, strong(x)) } else { x }))

#g(
  [abend], [The abnormal end of a task. MVS reports it with a system
    completion code, such as #cmd("S0C4"), or a user completion code, such
    as #cmd("U0100"), and may write a dump.],
  [AC], [_Authorization code._],
  [address constant], [A field in a module that holds an address, defined
    in assembler language with #cmd("DC A(...)") or #cmd("DC V(...)"). The
    _relocation dictionary_ lists them, and the _linkage editor_ and
    _program fetch_ adjust them to where the module is placed.],
  [alias], [A second name of a _member_ of a _partitioned data set_: a
    further _directory entry_ that points at the same member. An alias of a
    _load module_ may enter it at a different _entry point_.],
  [APF], [The authorized program facility of MVS. A program runs authorized,
    and may use services that are otherwise denied to it, only if its
    _load module_ has _authorization code_ 1 and it is loaded from a
    library that the system lists as APF-authorized.],
  [authorization code], [A value in the _directory entry_ of a _load
    module_\; 1 asks for authorized execution under _APF_. Set by ld370
    with #cmd("--ac").],
  [automatic library call], [The search of _object libraries_ by the
    _linkage editor_ for modules that define the symbols a program refers
    to but does not define. Also called autocall.],
  [block size], [The length of the blocks in which records are written to
    a data set (#cmd("BLKSIZE")). The block size of a _load library_ limits
    the length of the text records of the modules in it.],
  [CESD], [_Composite external symbol dictionary._],
  [code page 037], [The EBCDIC code page, for the United States and Canada,
    into which cc370 translates character constants and strings. It is the
    code page of data on MVS in the mvslovers ecosystem.],
  [composite external symbol dictionary], [The _external symbol dictionary_
    of a _load module_, which the _linkage editor_ builds from those of the
    _object modules_ it combines.],
  [condition code], [The return code of a job step, as MVS reports it in the
    job log\; for a C program, the value returned by #cmd("main") or passed
    to #cmd("exit").],
  [control section], [The smallest unit of a program that the _linkage
    editor_ places as a whole: a block of code or data with one origin. In
    assembler language it begins with #cmd("CSECT")\; cc370 makes one
    unnamed control section of each source. Also called CSECT.],
  [CP037], [_Code page 037._],
  [CSECT], [_Control section._],
  [data set], [A file on MVS. It has a name of up to 44 characters, in
    qualifiers of up to eight characters separated by periods, such as
    #cmd("USER1.HELLO.LOAD"), and attributes such as the _record format_,
    the record length and the _block size_.],
  [DD statement], [A statement of JCL that connects a name used by a
    program, the ddname, with a _data set_, a _SYSOUT_ data set or the
    input stream.],
  [directory entry], [The entry of a _member_ in the directory of a
    _partitioned data set_: its name and location and, for a _load module_,
    the _entry point_, the length, the module attributes and the
    _authorization code_.],
  [EBCDIC], [The Extended Binary Coded Decimal Interchange Code, the
    character encoding of MVS. It exists in several _code pages_\; cc370
    uses _code page 037_.],
  [entry point], [The address at which a module or a function is entered.
    The entry point of a _load module_ is where MVS gives control when the
    module is run\; for a C program it is #cmd("@@CRT0").],
  [ESD], [_External symbol dictionary._],
  [external name], [A name that is known outside the _object module_ that
    defines it: a _control section_, an entry point or an _external
    reference_. On MVS it has at most eight characters.],
  [external reference], [A name that an _object module_ uses but does not
    define, for which the _linkage editor_ must find a definition.],
  [external symbol dictionary], [The part of an _object module_ that lists
    its _control sections_, its entry points and its _external
    references_.],
  [Hercules], [An emulator of the System/370, ESA/390 and z/Architecture
    machines, on which MVS 3.8j runs on a workstation.],
  [IDR], [_Identification record._],
  [identification record], [A record in a _load module_ that says what built
    it and what changed it afterwards: the _linkage editor_ and the date of
    the link and, for each _control section_ changed with the service aid
    SPZAP, the change.],
  [IEBCOPY], [The MVS utility that copies, unloads and reloads
    _partitioned data sets_. Its _unloaded data set_ is the form in which a
    library travels inside a _TRANSMIT file_.],
  [IEWL], [The MVS _linkage editor_. ld370 takes its place on the
    workstation.],
  [IFOX00], [The MVS 3.8j assembler, Assembler XF. as370 accepts its
    language and writes the same _object modules_.],
  [IKJEFT01], [The program of the TSO terminal monitor. Run as a batch job
    step, it executes TSO commands read from #cmd("SYSTSIN").],
  [JCL], [Job control language: the statements that describe a job and its
    steps to MVS.],
  [linkage editor], [The program that combines _object modules_ into a
    _load module_, resolving the references between them. On MVS it is
    IEWL\; in the toolchain it is ld370.],
  [load library], [A _partitioned data set_ with _record format_ U whose
    members are _load modules_.],
  [load module], [A program in the form that MVS loads and runs: a _member_
    of a _load library_, written by the _linkage editor_.],
  [load module member], [In this book, the host file that ld370 writes with
    #cmd("-o"): the records of one member of a load library, without the
    library around it.],
  [member], [One of the named parts of a _partitioned data set_. A member
    name has one to eight characters\; the first is a letter or one of
    #cmd("@"), #cmd("#") and #cmd("$"), the others may also be digits.],
  [mvsMF], [A server for MVS 3.8j that offers a REST interface in the style
    of z/OSMF, through which files can be uploaded and jobs submitted.],
  [NEL], [The EBCDIC character #cmd("X'15'"), new line. It is the newline
    character #cmd("'\\n'") of programs compiled by cc370.],
  [NETDATA], [The format of a _TRANSMIT file_: control records that describe
    the data sets carried, followed by the data in records of 80 bytes.],
  [NJE38], [A package for MVS 3.8j that provides network job entry and the
    TSO commands #cmd("TRANSMIT") and #cmd("RECEIVE").],
  [object deck], [_Object module._],
  [object library], [In the toolchain, a file in the format of #cmd("ar"),
    written by ar370, that collects _object modules_ with an index of the
    names they define. ld370 searches it by _automatic library call_.],
  [object module], [The output of a compiler or assembler: 80-byte records
    of the types ESD, TXT, RLD and END, which the _linkage editor_ reads.
    Also called object deck.],
  [partitioned data set], [A _data set_ divided into _members_, with a
    directory that lists them by name. Also called PDS, or library.],
  [PDS], [_Partitioned data set._],
  [private code], [A _control section_ without a name. cc370 writes one for
    each source.],
  [program fetch], [The part of MVS that reads a _load module_ into storage
    and adjusts its _address constants_.],
  [RECEIVE], [The TSO command that installs a _TRANSMIT file_. On MVS 3.8j
    it is provided by _NJE38_. It creates the data set the file carries,
    with the attributes recorded in the file.],
  [record format], [The attribute of a _data set_ that says how its records
    are built (#cmd("RECFM")): #cmd("F") fixed length, #cmd("V") variable
    length, #cmd("U") undefined length, with #cmd("B") for blocked. A
    _TRANSMIT file_ is uploaded into #cmd("RECFM=FB") with 80-byte records\;
    a _load library_ has #cmd("RECFM=U").],
  [RECV370], [A batch program for MVS 3.8j that installs a _TRANSMIT file_,
    as the _RECEIVE_ command does.],
  [REFR], [Refreshable: a module attribute saying that the module may be
    replaced by a fresh copy at any time, because it never changes itself.],
  [relocation dictionary], [The part of an _object module_ or _load module_
    that lists its _address constants_, so that they can be adjusted when
    the module is placed in storage.],
  [RENT], [Reentrant: a module attribute saying that one copy of the module
    can be used by several tasks at once, because it does not change its
    own storage. ld370 sets it only when asked, with #cmd("--rent").],
  [return code], [The value a program leaves in register 15 when it ends\;
    for a job step, MVS reports it as the _condition code_. The tools of the
    toolchain also end with return codes, 0 for success.],
  [REUS], [Serially reusable: a module attribute saying that one copy of the
    module can be used by one task after another, without being loaded
    again. ld370 sets it only when asked, with #cmd("--reus").],
  [RLD], [_Relocation dictionary._],
  [STEPLIB], [A _DD statement_ that names the libraries in which MVS looks
    for the programs of a job step before it searches the system
    libraries.],
  [SYSOUT], [Output that the job entry subsystem collects and prints, or
    holds for viewing, after the job.],
  [SYSPRINT], [The ddname of the printed output of a program. The C library
    writes the standard output, #cmd("stdout"), to it.],
  [sysroot], [The directory #cmd("cc370") of an installed toolchain, which
    holds the headers, libraries and macros of the target, and in which the
    tools look for them without being told.],
  [text], [The bytes of a module: its instructions and data, as they are
    placed in storage. An _object module_ carries them in TXT records.],
  [TRANSMIT file], [A file in the _NETDATA_ format, as the TSO
    #cmd("TRANSMIT") command writes it and the _RECEIVE_ command reads it.
    ld370 and xmit370 write it with an _IEBCOPY unloaded data set_ inside.
    Also called an XMIT file.],
  [TSO], [The time sharing option of MVS: interactive use from a terminal,
    and the command language used there.],
  [unloaded data set], [A sequential copy of a _partitioned data set_, with
    its directory and members, as IEBCOPY writes it when it unloads a
    library and reads it when it loads one back.],
  [XMIT file], [_TRANSMIT file._],
)
