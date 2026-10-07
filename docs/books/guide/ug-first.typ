#import "../bookmaster/bookmaster.typ": *

= Your First Program <ug-first>

#idx("first program")
This chapter takes a small C program from its source on the workstation to
its output on MVS. It builds the program, looks at the files the build
writes, sends the result to MVS, installs it into a load library and runs
it. Each step is described in more detail later in this book\; here the aim
is to go through all of them once.

You need the toolchain installed as described in @ug-install, and a user ID
on an MVS 3.8j system to which you can transfer files and submit jobs. The
examples use the user ID #cmd("USER1")\; put your own in its place.

== Writing the Program <ug-first-write>

Create the file #cmd("hello.c") shown in @ug-first-hello, in an empty
directory on the workstation.

#fig(caption: [HELLO, the first program])[
  #code(read("../ex/ug-first/hello.c"), numbers: true)
] <ug-first-hello>

Nothing in it is particular to MVS. #cmd("printf") writes to the standard
output, which a C program on MVS finds on the DD statement
#cmd("SYSPRINT")\; the value returned by #cmd("main") becomes the return code
of the job step.

== Building the Program <ug-first-build>

#idx("first program", "building")
Build the program with one command:

```
cc370 -Wall -O1 -o hello -flinker-output=xmit hello.c
```

#deflist(width: 1.6in,
  [#cmd("-Wall")], [reports the common mistakes the compiler can detect\;
    see @ug-compile.],
  [#cmd("-O1")], [optimizes the code. It is the level the toolchain is
    validated at.],
  [#cmd("-o hello")], [names the output #cmd("hello"). The member name of
    the load module is made from it: #cmd("HELLO").],
  [#cmd("-flinker-output=xmit")], [writes, beside the load module, the TSO
    TRANSMIT file #cmd("hello.xmit"), which is the file you send to MVS.],
)

@ug-first-build-fig shows the build and the files it leaves.

#fig(caption: [Building HELLO])[
  #screen(raw(read("../ex/ug-first/build.txt")))
] <ug-first-build-fig>

The build is silent when it succeeds and ends with return code 0. It
writes two files:

- #cmd("hello") is the load module member: the records of one member of a
  load library, as the MVS linkage editor would write them. file370
  counts its records: the composite external symbol dictionary (CESD), the
  identification records (IDR), and the text with its control and
  relocation records. It cannot be sent to MVS as it is.
- #cmd("hello.xmit") is the TRANSMIT file. It holds a load library with the
  one member #cmd("HELLO"), and its length is a multiple of 80, because it
  consists of 80-byte records. It also records a name for the library,
  #cmd("IBMUSER.HOST.LOAD")\; you give the library a name of your own when
  you receive it.

The module is larger than the program: most of it is the C library, whose
start-up code, input and output routines and storage management the program
uses.

=== What the Driver Did <ug-first-steps>

#idx("cc370", "phases")
cc370 ran three programs one after the other, and deleted the files that
passed between them. You can run the steps yourself, as in
@ug-first-steps-fig: #cmd("-S") stops after the compiler, #cmd("-c") after
the assembler, and an object module given to cc370 is only linked.

#fig(caption: [The same build, one step at a time])[
  #screen(raw(read("../ex/ug-first/steps.txt")))
] <ug-first-steps-fig>

#cmd("hello.s") is the assembler source of the program. @ug-first-asm shows
the function #cmd("main"). The string is translated to EBCDIC by the
compiler, and the call is a call of #cmd("puts"), not of #cmd("printf"): at
#cmd("-O1") the compiler replaces a #cmd("printf") of a plain string that
ends in a newline by #cmd("puts") of the string without it. #cmd("puts")
adds the newline when it writes the line.

#fig(caption: [The function main in hello.s])[
  #code(read("../ex/ug-first/hello.s").split("\n").slice(3, 6)
    .join("\n") + "\n...\n" + read("../ex/ug-first/hello.s").split("\n")
    .slice(17, 36).join("\n"), size: 7.5pt)
] <ug-first-asm>

#cmd("hello.o") is the object module, the deck that IFOX00 would punch for
the same source. Its one external reference besides #cmd("PUTS") is
#cmd("@@CRT0"), the start-up routine of the C library, which ld370 found
in the library together with everything #cmd("PUTS") needs.

== Installing It on MVS <ug-first-install>

#idx("first program", "installing")
Two steps bring the program into a load library on MVS: the transfer of
the TRANSMIT file, and the #cmd("RECEIVE") that unpacks it. @ug-transfer
describes both in detail and the other ways of doing them\; the steps below
are one way that works.

+ *Transfer #cmd("hello.xmit") to MVS*, into a sequential data set with
  fixed-length records of 80 bytes: #cmd("RECFM=FB"), #cmd("LRECL=80"),
  for example #cmd("BLKSIZE=3120"). Transfer it in binary. The file is
  EBCDIC already, and a translation from ASCII would destroy it. With an
  FTP client:
  ```
  ftp> binary
  ftp> put hello.xmit 'USER1.HELLO.XMIT'
  ```
  Whether the FTP server creates the data set with these attributes, or
  needs it allocated beforehand, depends on the server\; see @ug-transfer.
+ *Receive it into a new load library.* The TSO command
  ```
  RECEIVE INDSN('USER1.HELLO.XMIT') DATASET('USER1.HELLO.LOAD')
  ```
  creates the library #cmd("USER1.HELLO.LOAD") and loads the member
  #cmd("HELLO") into it. #cmd("DATASET") replaces the name recorded in the
  file. The library is allocated with the attributes recorded in the file,
  so do not allocate it yourself. You can enter the command at a TSO
  terminal, or run it in a batch job as in @ug-first-recv-jcl.

#fig(caption: [A job that receives HELLO])[
  #code("//USER1R   JOB (1),'RECEIVE HELLO',CLASS=A,MSGCLASS=A
//RECV     EXEC PGM=IKJEFT01,REGION=4096K
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 RECEIVE INDSN('USER1.HELLO.XMIT') DATASET('USER1.HELLO.LOAD')
/*")
] <ug-first-recv-jcl>

#cmd("PGM=IKJEFT01") runs TSO in batch\; the commands are read from
#cmd("SYSTSIN") and the messages written to #cmd("SYSTSPRT"). Use the job
class and message class of your system. #cmd("RECEIVE") calls IEBCOPY to
load the library, and IEBCOPY reports the member it loaded with the
message #cmd("IEB154I"). The region of 4096K leaves IEBCOPY enough storage:
with a smaller region it may end with message #cmd("IEB135I") and load
nothing.

#note[On MVS/CE, #cmd("RECEIVE") may not find a volume for the new library
by itself. Name one with the #cmd("VOLUME") operand, for example
#cmd("VOLUME(PUB000)"), choosing a volume of your system that holds user
data sets.]

#fig(caption: [The output of the RECEIVE job])[
  _Output to be captured on MVS._
] <ug-first-recv-out>

Check the result in the output, not by the return code alone: the message
#cmd("IEB154I") must name #cmd("HELLO"). A library that already exists is not
replaced. To receive the program again after a change, delete
#cmd("USER1.HELLO.LOAD") first.

== Running It <ug-first-run>

#idx("first program", "running")
Run the program with the job in @ug-first-run-jcl.

#fig(caption: [A job that runs HELLO])[
  #code("//USER1H   JOB (1),'RUN HELLO',CLASS=A,MSGCLASS=A
//HELLO    EXEC PGM=HELLO,REGION=4096K
//STEPLIB  DD DSN=USER1.HELLO.LOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*")
] <ug-first-run-jcl>

#deflist(width: 1.1in,
  [#cmd("EXEC PGM=")], [names the member of the load library to run.],
  [#cmd("STEPLIB")], [names the library in which MVS looks for it first.
    Without it, MVS searches only the system libraries and the step ends
    with abend #cmd("S806"), module not found.],
  [#cmd("SYSPRINT")], [receives the standard output of the program. If the
    step has no #cmd("SYSPRINT"), the C library writes to a SYSOUT data set
    of its own.],
)

The job writes two things you look for:

- In the job log, the step #cmd("HELLO") ends with condition code
  #cmd("0000"), the value returned by #cmd("main").
- The SYSOUT data set of #cmd("SYSPRINT") holds one line,
  #cmd("Hello, MVS!").

#fig(caption: [The output of the job HELLO])[
  _Output to be captured on MVS._
] <ug-first-run-out>

#idx("TSO", "running a program")
At a TSO terminal you can also run the program with the #cmd("CALL")
command:

```
CALL 'USER1.HELLO.LOAD(HELLO)'
```

The standard output then goes to the terminal, and the line
#cmd("Hello, MVS!") appears there.

#fig(caption: [HELLO run at a TSO terminal])[
  _Output to be captured on MVS._
] <ug-first-tso-out>

== Where to Go from Here <ug-first-next>

Every program you build goes through the same steps: compile and link on
the workstation, transfer, receive, run. The following chapters take them
one at a time:

- @ug-compile describes the options of the compiler and what is particular
  about C on MVS.
- @ug-asm describes programs written in assembler language, alone or
  together with C.
- @ug-link describes programs of several sources, object libraries and the
  attributes of a load module.
- @ug-transfer and @ug-run describe the transfer, the receive and the
  running of programs in more detail.
- @ug-diag describes what to do when a program does not do what it should.
