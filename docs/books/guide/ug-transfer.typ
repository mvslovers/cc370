#import "../bookmaster/bookmaster.typ": *

= Getting Programs onto MVS <ug-transfer>

#idx("transfer to MVS")
#idx("TRANSMIT file")
Everything up to now has happened on the workstation. This chapter brings
the result to MVS: the TRANSMIT file that ld370 wrote is copied into a data
set on MVS and received into a load library, from which the programs can be
run. The same steps install a library of source members, such as JCL, that
xmit370 has packed.

The chapter describes three ways to copy the file, in order of preference:
the mvsMF REST interface, FTP, and the IND\$FILE file transfer of a 3270
terminal emulator. All three end the same way, with the TSO command
#cmd("RECEIVE"). The last section shows how the MBT build tool does all of
it with one command.

The examples install #cmd("sumlib.xmit"), the library with the members
SUMUP and GREET that @ug-link-pack-session built, as the load library
#cmd("USER1.SUMUP.LOAD"). Replace #cmd("USER1") with your own user ID or
high-level qualifier.

== The TRANSMIT File <ug-transfer-xmit>

#idx("TRANSMIT file", "format")
#idx("NETDATA")
A TRANSMIT file, also called an XMIT file, is the format of the TSO
#cmd("TRANSMIT") command: a sequence of 80-byte records that describe a data
set and carry its contents. The file that ld370 writes carries a whole load
library, in the form IEBCOPY gives it when it unloads one. It records:

- the name of the library, given by #cmd("--dsn") when it was written\;
- the organization and record format of a load library, partitioned with
  undefined-length records, and its block size\;
- the space the library needs\;
- the members, each with its directory entry.

Three properties of the file decide how it is transferred:

- *It is binary.* Its records are already in EBCDIC, with binary fields
  between the characters. It must be transferred without any translation
  between ASCII and EBCDIC, and without any change to line ends.
- *It has fixed-length records of 80 bytes.* It must arrive in a sequential
  data set with #cmd("RECFM=FB") and #cmd("LRECL=80")\; #cmd("BLKSIZE=3120")
  is a good block size. The length of the file is always a multiple of 80.
- *It is not the library.* The data set it is copied into is only a staging
  data set\; #cmd("RECEIVE") reads it and creates the library.

#cmd("file370") shows which library a TRANSMIT file will create:

#screen(raw(read("../ex/ug-transfer/file.txt")))

== Transferring with mvsMF <ug-transfer-mvsmf>

#idx("mvsMF")
#idx("REST API")
mvsMF is an implementation of the z/OSMF REST interface for MVS 3.8j. It runs
as a module of the HTTP server on MVS and lets a program on the workstation
create, write and delete data sets and submit jobs over HTTP. Any HTTP
client can use it\; the examples use #cmd("curl").

The examples assume that mvsMF answers at #cmd("http://mvs:1080"). Replace
the host and port with those of your system. #cmd("-u USER1") makes
#cmd("curl") ask for the password of the user ID, so it does not appear on
the command line. Write each option out as it is shown: do not collect
options in a shell variable, because a shell such as #cmd("zsh") then passes
them as a single argument, and #cmd("curl") sends something other than what
you meant.

To install the library:

+ Allocate the staging data set, sequential with fixed 80-byte records. The
  space is in tracks, ample for a file of this size:
  ```
  curl -u USER1 -X POST -H "Content-Type: application/json" \
    -d '{"dsorg":"PS","recfm":"FB","lrecl":80,"blksize":3120,
         "alcunit":"TRK","primary":50,"secondary":20,"unit":"SYSDA"}' \
    http://mvs:1080/zosmf/restfiles/ds/USER1.SUMUP.XMIT
  ```
  If the data set exists from an earlier transfer, delete it first, as in
  step 3, or use it again.
+ Upload the TRANSMIT file into it, in binary. The header
  #cmd("X-IBM-Data-Type: binary") turns off the translation\;
  #cmd("--data-binary") sends the file unchanged:
  ```
  curl -u USER1 -X PUT -H "Content-Type: application/octet-stream" \
    -H "X-IBM-Data-Type: binary" --data-binary @sumlib.xmit \
    http://mvs:1080/zosmf/restfiles/ds/USER1.SUMUP.XMIT
  ```
+ If the load library exists already, delete it. #cmd("RECEIVE") creates
  the library and does not add members to an existing one (see
  @ug-transfer-replace for the alternative):
  ```
  curl -u USER1 -X DELETE http://mvs:1080/zosmf/restfiles/ds/USER1.SUMUP.LOAD
  ```
+ Submit the job of @ug-transfer-receive-jcl, which receives the staging
  data set into the library. The job is sent as the body of the request:
  ```
  curl -u USER1 -X PUT -H "Content-Type: text/plain" \
    --data-binary @receive.jcl http://mvs:1080/zosmf/restjobs/jobs
  ```
  The answer is a JSON object that contains, among other things, the job
  name and the job identifier, for example
  #cmd("\"jobname\":\"RECEIVE\"") and #cmd("\"jobid\":\"JOB01234\"").
  The following steps use these two values\; #cmd("JOB01234") stands for
  the identifier your system returns.
+ Ask for the status of the job until it has ended:
  ```
  curl -u USER1 http://mvs:1080/zosmf/restjobs/jobs/RECEIVE/JOB01234
  ```
  While the job runs, #cmd("\"status\"") is #cmd("\"INPUT\"") or
  #cmd("\"ACTIVE\"")\; when it reads #cmd("\"OUTPUT\""), the job has ended,
  and #cmd("\"retcode\"") holds its completion, such as
  #cmd("\"CC 0000\"") or #cmd("\"ABEND S0C4\"").
+ Read the output of the job. The first request lists the output data sets
  of the job, each with a number (#cmd("\"id\"")) and its DD name\; the
  second returns the records of the one with that number, here 4:
  ```
  curl -u USER1 http://mvs:1080/zosmf/restjobs/jobs/RECEIVE/JOB01234/files
  curl -u USER1 http://mvs:1080/zosmf/restjobs/jobs/RECEIVE/JOB01234/files/4/records
  ```
+ List the members of the library, to make sure they are there:
  ```
  curl -u USER1 http://mvs:1080/zosmf/restfiles/ds/USER1.SUMUP.LOAD/member
  ```
+ Delete the staging data set, as in step 3, when you no longer need it.

#note[On some systems the status of a job carries no #cmd("retcode"). The
completion of the job is then only in its output: read the messages of the
job, as in step 6.]

#note[Some characters do not survive the way through the REST interface
unchanged. A job that contains #cmd("¬") or #cmd("^") may arrive with
another character in their place. Write #cmd("NE") instead of
#cmd("¬=") in JCL and in utility control statements.]

== Transferring with FTP <ug-transfer-ftp>

#idx("FTP")
#idx("ftpd")
Any FTP server on MVS can receive the file, for example ftpd, the FTP server
of the mvslovers project, which listens on port 2121 unless configured
otherwise. What matters is that the transfer is binary and that the data set
it creates has fixed 80-byte records. With most FTP clients:

+ Connect to the server and log on with your user ID and password.
+ Switch to binary transfer with #cmd("binary").
+ Set the attributes of the data set to be created. ftpd, like the z/OS FTP
  server, takes them as #cmd("SITE") commands, which most clients send with
  #cmd("quote"):
  ```
  quote site recfm=fb
  quote site lrecl=80
  quote site blksize=3120
  quote site tracks
  quote site primary=50
  quote site secondary=20
  ```
+ Send the file, giving the data set name in quotes, so that it is not
  prefixed with your user ID twice:
  ```
  put sumlib.xmit 'USER1.SUMUP.XMIT'
  ```
+ Receive the data set, either with the job of
  @ug-transfer-receive-jcl or at a TSO terminal:
  ```
  RECEIVE INDSN('USER1.SUMUP.XMIT') DATASET('USER1.SUMUP.LOAD')
  ```

#idx("ftpd", "submitting a job")
ftpd can also submit the job for you. After #cmd("quote site filetype=jes"),
a file you #cmd("put") is submitted as a job instead of being stored, and
#cmd("dir") lists your jobs. Switch back with
#cmd("quote site filetype=seq"). Send the job as text: give #cmd("ascii")
before #cmd("put receive.jcl").

== Transferring with IND\$FILE <ug-transfer-indfile>

#idx("IND$FILE")
#idx("3270 file transfer")
If you work with MVS through a 3270 terminal emulator, such as x3270 or
wc3270, and an IND\$FILE program is installed on MVS, the emulator can send
the file over the terminal session. Log on to TSO, leave the session at the
READY prompt, and start the transfer from the emulator, with these choices:

- direction: send to the host\; host type: TSO\;
- transfer mode: binary, with no ASCII translation and no CR/LF
  handling\;
- record format fixed blocked (#cmd("RECFM(FB)")), logical record length
  80, block size 3120\;
- the data set name #cmd("'USER1.SUMUP.XMIT'").

The emulator then runs the command #cmd("IND$FILE PUT") on MVS with these
operands. Without them, IND\$FILE chooses its own record format, which is not
the one #cmd("RECEIVE") needs. IND\$FILE is slow for large files, since every
byte travels through the 3270 data stream. Receive the data set as described
in @ug-transfer-receive.

== Receiving the Library <ug-transfer-receive>

#idx("RECEIVE")
#idx("TSO", "RECEIVE command")
The TSO command #cmd("RECEIVE") reads the staging data set and creates the
load library. On MVS 3.8j it is provided by NJE38 or a similar package\; the
examples use the form that NJE38 accepts:

```
RECEIVE INDSN('USER1.SUMUP.XMIT') DATASET('USER1.SUMUP.LOAD')
```

#cmd("INDSN") names the staging data set, #cmd("DATASET") the library to
create. Without #cmd("DATASET"), the name recorded in the file is used, the
one given to ld370 with #cmd("--dsn"). Where new data sets must be placed on
a particular volume, add #cmd("VOLUME('")#var("volser")#cmd("')").

#cmd("RECEIVE") allocates the library itself, from the attributes recorded
in the file: a partitioned data set with #cmd("RECFM=U") and the block size
the modules were linked for. You do not allocate it beforehand, and you give
no DCB attributes.

@ug-transfer-receive-jcl shows a job that runs #cmd("RECEIVE") in batch,
under the TSO terminal monitor program IKJEFT01.

#fig(caption: [RECEIVE, a job that receives the library])[
  #code(read("../ex/ug-transfer/receive.jcl"), numbers: true)
] <ug-transfer-receive-jcl>

#idx("REGION", "for RECEIVE")
#cmd("REGION=4096K") is not a decoration. RECEIVE calls IEBCOPY to load the
members, and with the default region of many job classes IEBCOPY finds too
little storage for its buffers: it issues #cmd("IEB135I") and nothing is
received.

*Check the library, not the return code.* For each member it loads, IEBCOPY
writes the message #cmd("IEB154I") into the output of the job. Then list the
members: in TSO with #cmd("LISTDS 'USER1.SUMUP.LOAD' MEMBERS"), or through
mvsMF as in @ug-transfer-mvsmf. A job can end with condition code 0 and
still have received fewer members than you sent.

#fig(caption: [Output of the RECEIVE job])[_Output to be captured on MVS._]
<ug-transfer-receive-out>

=== Receiving with RECV370 <ug-transfer-recv370>

#idx("RECV370")
A system without a TSO #cmd("RECEIVE") command can install the file with
RECV370, a batch program that does the same work. RECV370 must be in the
link list or in a #cmd("STEPLIB") library. @ug-transfer-recv370-jcl
receives the staging data set into the new library
#cmd("USER1.SUMUP.LOAD").

#fig(caption: [A job that receives the library with RECV370])[
  #code(read("../ex/ug-transfer/recv370.jcl"), numbers: true)
] <ug-transfer-recv370-jcl>

#cmd("XMITIN") names the staging data set, #cmd("SYSUT1") is a work data
set, and #cmd("SYSUT2") is the library to create. Give #cmd("SYSUT2") space
and directory blocks, but *no DCB parameter*: the attributes of the library
come from the file. As with #cmd("RECEIVE"), IEBCOPY reports each member it
loads with #cmd("IEB154I")\; check the members of the library afterwards.

=== Replacing Members of an Existing Library <ug-transfer-replace>

#idx("load library", "updating")
#cmd("RECEIVE") creates a new library. It does not add members to a library
that exists. There are two ways to install a new level of a program:

- Delete the library and receive it again, as in @ug-transfer-mvsmf. This is
  the simple way when the library holds nothing else\; it is what MBT does.
- Receive into a new library and copy its members into the existing one with
  IEBCOPY, which replaces members of the same name.
  @ug-transfer-update-jcl shows a job that does this.

#fig(caption: [UPDATE, a job that replaces members of an existing
  library])[
  #code(read("../ex/ug-transfer/update.jcl"), numbers: true)
] <ug-transfer-update-jcl>

The copy step runs only when the RECEIVE step ended with a return code of 4
or less. The new library, #cmd("USER1.SUMUP.NEWLOAD"), is kept: check the
members of #cmd("USER1.SUMUP.LOAD") and then delete it. IEBCOPY does not
reblock load modules, so the block size of the existing library must be at
least the one the modules were linked for, 15040 unless #cmd("--blocksize")
said otherwise.

#note[A library that a running program, such as a started task, holds open
cannot be deleted, and a member it has loaded is not replaced in its
storage. Stop the program, install, and start it again.]

=== Authorized Programs

#idx("APF authorization")
A module linked with #cmd("--ac 1") runs authorized only when it is loaded
from an APF-authorized library. On MVS 3.8j the authorized libraries are
listed, with their volumes, in the member #cmd("IEAAPF00") of
#cmd("SYS1.PARMLIB"), which is read at IPL: a new library becomes authorized
only after it has been added there and the system has been loaded again.
Every library in the #cmd("STEPLIB") of an authorized program must be
authorized, or the program runs unauthorized.

== Sending a Source Library with xmit370 <ug-transfer-xmit370>

#idx("xmit370")
#idx("source library", "transfer")
JCL, macros and other source members travel the same way, in a TRANSMIT
file that xmit370 writes from a directory of text files. Each file becomes a
member, named after the file without its extension, and its lines are
translated to EBCDIC and padded to 80 columns. The library is received with
the attributes that xmit370 records: partitioned, #cmd("RECFM=FB"),
#cmd("LRECL=80"), #cmd("BLKSIZE=3120") by default.

@ug-transfer-xmitjcl packs the jobs of this chapter and of @ug-run into a
TRANSMIT file for the library #cmd("USER1.SUMUP.JCL").
#cmd("--stats-date") gives every member the same date, so that two runs give
the same file.

#fig(caption: [Packing a JCL library with xmit370])[
  #screen(raw(read("../ex/ug-transfer/xmitjcl.txt")))
] <ug-transfer-xmitjcl>

#cmd("sumjcl.xmit") is transferred and received exactly as
#cmd("sumlib.xmit"), in binary into a staging data set with fixed 80-byte
records:

```
RECEIVE INDSN('USER1.SUMJCL.XMIT') DATASET('USER1.SUMUP.JCL')
```

The members can then be edited and submitted on MVS. The options of
xmit370, and how it treats tabs, trailing blanks and characters outside
ASCII, are described in the _CC/370 Command Reference_, Chapter 6, “The
xmit370 Command”.

== Automating the Steps with MBT <ug-transfer-mbt>

#idx("mbt")
The steps of this chapter are the same for every change you make, which
makes them a candidate for a tool. MBT (mbt), the MVS build tool of the mvslovers
project, builds a project with cc370, as370 and ld370 from a description in
a file #cmd("project.toml"), and installs it with one command,
#cmd("make deploy"), which:

+ packs the #cmd(".iebcopy") file of every module it built into one TRANSMIT
  file with #cmd("ld370 --pack")\;
+ uploads it through mvsMF into a staging data set with fixed 80-byte
  records\;
+ deletes the target library if it exists, and submits a job that receives
  the staging data set into it with #cmd("RECEIVE"), in a region of 4096K\;
+ waits for the job, keeps its output, and deletes the staging data set.

MBT reads the address of mvsMF, the user ID and the password from a file
#cmd(".env") in the project, and the name of the target library from
#cmd("project.toml"). It is being rewritten as a stand-alone tool, so its
commands and files are not described here\; see the documentation in the
mbt repository of the mvslovers project on GitHub.
