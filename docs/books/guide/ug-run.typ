#import "../bookmaster/bookmaster.typ": *

= Running Programs on MVS <ug-run>

#idx("running a program")
Once the load library is on MVS, its programs run like any other MVS
program: as a step of a batch job, or from a TSO terminal. This chapter
shows both, explains how a C program receives its parameter and where its
standard streams go, and what a return code and an abend look like.

The examples run SUMUP and GREET from the library #cmd("USER1.SUMUP.LOAD")
that @ug-transfer installed. The run time behaviour of a C program is
described in full in the _libc370 Programmer's Guide_\; this chapter covers
what you need to run one.

== Running a Program in a Batch Job <ug-run-batch>

#idx("batch job")
#idx("JCL", "EXEC PGM=")
#idx("STEPLIB")
@ug-run-jcl shows a job with two steps: the first runs SUMUP with the
parameter #cmd("10 20 30"), the second runs GREET.

#fig(caption: [RUNSUMUP, a job that runs SUMUP and GREET])[
  #code(read("../ex/ug-run/runsumup.jcl"), numbers: true)
] <ug-run-jcl>

The statements that matter:

#deflist(width: 1.3in,
  [#cmd("EXEC PGM=SUMUP")], [names the member of the load library to run.
    MVS enters it at the entry point recorded in its directory entry, which
    for a C program is #cmd("@@CRT0"), the C start-up.],
  [#cmd("PARM='10 20 30'")], [is the parameter of the program, up to 100
    characters. For a C program it becomes the arguments of #cmd("main")\;
    see @ug-run-parm.],
  [#cmd("STEPLIB")], [names the library in which MVS looks for the program
    before it looks in the link list. Without it, the program is not found,
    and the step ends with abend #cmd("S806").],
  [#cmd("SYSPRINT")], [receives the standard output of a C program,
    #cmd("stdout").],
  [#cmd("SYSTERM")], [receives its standard error, #cmd("stderr").],
  [#cmd("SYSUDUMP")], [receives a dump if the program abends\; see
    @ug-run-abend.],
)

To run the job:

+ Submit it: from the ISPF editor with #cmd("SUBMIT"), from TSO with
  #cmd("SUBMIT 'USER1.SUMUP.JCL(RUNSUMUP)'"), or from the workstation through
  mvsMF or ftpd as described in @ug-transfer.
+ When it has ended, look at its output, in the held output queue or through
  mvsMF.
+ Check the condition code of each step in the job log, in the message
  #cmd("IEF142I")\; see @ug-run-rc.

The output of the step SUMUP, in #cmd("SYSPRINT"), is the line
#cmd("SUM 60, AVERAGE 20"). GREET writes its message with #cmd("WTO"), so it
appears on the operator console and in the job log, not in a #cmd("SYSPRINT")
data set. Both steps end with condition code 0.

#fig(caption: [Output of the job RUNSUMUP])[_Output to be captured on MVS._]
<ug-run-out>

== Passing a Parameter <ug-run-parm>

#idx("PARM")#idx("argc and argv")
The C start-up turns the #cmd("PARM") text into the arguments of
#cmd("main"):

- #cmd("argv[0]") is the name of the program, #cmd("SUMUP").
- The text is divided into words at blanks\; each word is one argument.
  Several blanks count as one.
- A word that begins with a double quote, #cmd("\""), extends to the next
  double quote, blanks included. The quotes are not part of the argument.
- At most 49 arguments are passed after #cmd("argv[0]")\; #cmd("argv[argc]")
  is a null pointer.

The case of the text is not changed. #cmd("PARM='10 20 30'") gives
#cmd("argc") the value 4 and #cmd("argv") the strings #cmd("SUMUP"),
#cmd("10"), #cmd("20") and #cmd("30"). To pass a single argument that
contains blanks, write

```
//SUMUP    EXEC PGM=SUMUP,PARM='"A B" C'
```

which gives the arguments #cmd("A B") and #cmd("C").

The parameter is a character string. A C program converts numbers itself,
as SUMUP does with #cmd("atoi"). A program that needs no parameter is run
without #cmd("PARM")\; #cmd("argc") is then 1.

== Standard Streams and Files <ug-run-files>

#idx("stdin")#idx("stdout")#idx("stderr")
#idx("DD statement", "for a C program")
Before #cmd("main") is called, the start-up opens the three standard
streams on DD statements of the step, as @ug-run-streams-tab shows. A
stream that the program has already set in #cmd("__premain")
(@ug-link-premain) is kept.

#tab(caption: [The standard streams of a C program])[
  #table(columns: (0.75in, 0.85in, 1fr),
    [Stream], [DD name], [When the DD statement is missing],
    [#cmd("stdout")], [#cmd("SYSPRINT")], [A SYSOUT data set of the job's
      message class is allocated, or, under TSO, the terminal is used.],
    [#cmd("stderr")], [#cmd("SYSTERM")], [As for #cmd("stdout").],
    [#cmd("stdin")], [#cmd("SYSIN")], [The stream is empty: the first read
      returns end of file.],
  )
] <ug-run-streams-tab>

So a program that only writes to #cmd("stdout") also runs in a step without
#cmd("SYSPRINT"). Give the DD statements anyway: the output then goes where
you expect it. When one of the streams cannot be opened, for example
because the region is too small, the program ends before #cmd("main") with
return code 12 and a message on the console that names the stream.

#idx("SYSIN", "in-stream data")
Input for #cmd("stdin") can follow in the job itself:

```
//SYSIN    DD *
first line of input
second line of input
/*
```

#idx("fopen", "DD name")
Other files are opened with #cmd("fopen"). The name selects the data set:
#cmd("\"dd:INPUT\"") opens the data set of the DD statement #cmd("INPUT")
of the step, and a name in single quotes, such as
#cmd("\"'USER1.SUMUP.DATA'\""), opens that data set by its name. A program
that reads #cmd("dd:INPUT") is run with a DD statement for it:

```
//INPUT    DD DSN=USER1.SUMUP.DATA,DISP=SHR
```

Opening by DD name is the usual way in batch: the job, not the program,
decides which data set is read, and MVS allocates it before the program
starts. The forms of file names and the record formats a C program can read
and write are described in the _libc370 Programmer's Guide_.

#idx("environment variables")
A C program can also be given environment variables, which it reads with
#cmd("getenv"). The start-up reads them from the DD statement
#cmd("SYSENV"), or, if there is none, #cmd("ENVIRON"): one variable on each
line, in the form #var("NAME")#cmd("=")#var("value").

== Running a Program under TSO <ug-run-tso>

#idx("TSO", "CALL command")
#idx("CALL")
At a TSO terminal, the command #cmd("CALL") runs a member of a load library,
with the parameter in quotes after the name:

```
CALL 'USER1.SUMUP.LOAD(SUMUP)' '10 20 30'
```

The parameter reaches the program as #cmd("PARM") does in batch, and
#cmd("argv") is built in the same way. Without #cmd("SYSPRINT") and
#cmd("SYSTERM") allocated, #cmd("stdout") and #cmd("stderr") write to the
terminal, so the result appears below the command. #cmd("stdin") reads the
data set allocated to #cmd("SYSIN")\; when that is the terminal, a line that
contains only #cmd("/*") ends the input.

#idx("IKJEFT01")
The same command runs in batch under the TSO terminal monitor program,
IKJEFT01, which is useful to test how a program behaves under TSO:

```
//TSOSTEP  EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=USER1.SUMUP.LOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD *
 CALL 'USER1.SUMUP.LOAD(SUMUP)' '10 20 30'
/*
```

#fig(caption: [SUMUP called at a TSO terminal])[_Output to be captured on
MVS._] <ug-run-tso-out>

== Return Codes <ug-run-rc>

#idx("return code")#idx("condition code")
The value that #cmd("main") returns, or that the program passes to
#cmd("exit"), is the return code of the program. In a batch job it is the
condition code of the step: the job log reports it in the message
#cmd("IEF142I"), and the
#cmd("COND") parameter of a later step can test it. Use the values that MVS
programs use:

#tab(caption: [Return codes by convention])[
  #table(columns: (0.75in, 1fr),
    [Code], [Meaning],
    [0], [Success.],
    [4], [Warning: the program did its work, with something to note.],
    [8], [Error: the program could not do all of its work.],
    [12], [Severe error. #cmd("EXIT_FAILURE") is 12, and so is the return
      code of #cmd("abort()") and of a program whose standard streams cannot
      be opened.],
    [16], [Terminal error.],
  )
] <ug-run-rc-tab>

A #cmd("COND") test can compare values from 0 to 4095, so keep return
codes in that range. A C program does not abend when it calls
#cmd("abort()") or #cmd("exit()")\; it ends normally with the return code.

== When a Program Abends <ug-run-abend>

#idx("abend")
#idx("SYSUDUMP")
When a program does something the machine or the system does not allow, MVS
ends the step abnormally: it _abends_. Instead of a condition code, the job
log shows the completion code in the message #cmd("IEF450I"), which names
the job, the step and the code. The completion code is either a system code, #cmd("S") and three hexadecimal
digits, or a user code, #cmd("U") and four decimal digits, set by a program
that issues the #cmd("ABEND") macro. The following steps of the job are
skipped unless their #cmd("COND") parameter says otherwise.
@ug-run-abend-tab lists the system codes a C program meets most often.

#tab(caption: [Common system completion codes])[
  #table(columns: (0.75in, 1fr),
    [Code], [Usual cause],
    [#cmd("S0C1")], [Operation exception: a branch to something that is not
      an instruction, often through an address constant that is zero or
      wrong.],
    [#cmd("S0C4")], [Protection or addressing exception: a store into
      storage the program does not own, typically through a null or stale
      pointer.],
    [#cmd("S0C7")], [Data exception: a decimal instruction on data that is
      not a valid packed decimal number.],
    [#cmd("S0C9")], [Fixed-point divide exception: an integer division by
      zero, or a quotient too large.],
    [#cmd("S806")], [The program was not found: wrong name, or the library
      is missing from #cmd("STEPLIB").],
    [#cmd("S80A"), #cmd("S878")], [Not enough storage: raise the
      #cmd("REGION") of the step.],
    [#cmd("S322")], [The step used more processor time than the job or
      class allows, often because of a loop.],
  )
] <ug-run-abend-tab>

With a #cmd("SYSUDUMP") DD statement in the step, MVS writes a dump of the
program's storage when it abends. The dump begins with the completion code
and the program status word (PSW) at the time of the abend, which holds the
address of the instruction after the one that failed (@ug-diag shows how
to step back)\; further down it shows where each
program of the step was loaded. With these two addresses, the load map and
the assembler listing, you can find the statement in your source that
failed. @ug-diag shows how, for an abend of SUMUP.

#fig(caption: [The job log and the beginning of the dump of an abend])[
  _Output to be captured on MVS._] <ug-run-abend-out>
