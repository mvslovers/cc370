#import "../bookmaster/bookmaster.typ": *

= Installing the Toolchain <ug-install>

#idx("installation")
The toolchain is installed in two parts: cc370 itself, which is the compiler,
the assembler, the linkage editor and the utilities, and libc370, the C
library, which is installed into cc370's directory tree. This chapter shows
the ways to install both, what the installed tree contains, and how to check
that it works.

== Choosing a Way to Install <ug-install-choose>

#idx("installation", "methods")
There are two ways to obtain the toolchain:

- *Install a release.* Every release of cc370 publishes prebuilt toolchains
  for macOS and Linux, and every release of libc370 publishes the library
  ready to install. This is the quickest way, and the right one unless you
  intend to change the toolchain.
- *Build from source.* You clone the repositories and build both parts on
  your workstation. This takes a few minutes, and gives you the current
  development level.

Both ways give the same directory tree, described in @ug-install-tree.

== Installing a Release <ug-install-release>

#idx("install.sh")
The installation script of the latest release installs cc370 and, beside
it, the newest release of libc370 that declares itself compatible with that
cc370:

```
curl -fsSL https://github.com/mvslovers/cc370/releases/latest/download/install.sh | sh
```

The script installs under #cmd("~/.local") unless the environment variable
#cmd("PREFIX") names another directory, and checks each download against the
checksums published with its release. When no libc370 release fits, it
installs cc370 alone and says so. At the end it reminds you to add
#cmd("$PREFIX/bin") to your #cmd("PATH") if it is not there yet.

The releases also come in other forms:

#deflist(width: 1.1in,
  [Tarball], [#cmd("cc370-")#var("version")#cmd("-")#var("os")#cmd("-")#var("arch")#cmd(".tar.gz")
    holds the whole installed tree. Unpack it anywhere and use its
    #cmd("bin") directory\; the tree finds its own parts. Unpack the libc370
    tarball, #cmd("libc370-")#var("version")#cmd("-sysroot.tar.gz"), into
    the tree's #cmd("cc370") directory. On macOS, a tarball downloaded with
    a web browser is marked as quarantined: remove the mark with
    #cmd("xattr -d com.apple.quarantine") on the unpacked tree.],
  [Homebrew], [#cmd("brew trust mvslovers/tap"), then
    #cmd("brew install mvslovers/tap/cc370"), which installs libc370 with
    it.],
  [Linux packages], [#cmd(".deb") and #cmd(".rpm") packages install the tree
    under #cmd("/usr/lib/cc370"), with links in #cmd("/usr/bin"). cc370 and
    libc370 depend on each other, so install the two packages together.],
)

== Building from Source <ug-install-build>

#idx("installation", "from source")
To build the toolchain you need, on the workstation:

- a C compiler, used as #cmd("cc"): clang on macOS, gcc or clang on Linux\;
- #cmd("make")\;
- #cmd("pod2man"), which comes with Perl, for the manual pages\;
- Python 3, for the build of libc370\;
- #cmd("git"), to obtain the sources.

Build cc370 first: libc370 is compiled with it.

+ Obtain the source of cc370:
  ```
  git clone https://github.com/mvslovers/cc370.git
  cd cc370
  ```
+ Build and install it. #cmd("make install") builds whatever has not been
  built yet and installs it under #cmd("~/.local"). To install elsewhere,
  give the directory as #cmd("PREFIX"), for example
  #cmd("make install PREFIX=/opt/cc370").
  ```
  make install
  ```
  The build of the compiler takes the most time, a minute or two on a
  current workstation\; the other tools are built in seconds. The command
  ends with the lines in @ug-install-make-fig.
+ Make sure that #cmd("$PREFIX/bin") is in your #cmd("PATH"), so that the
  shell finds #cmd("cc370") and the other commands. libc370 is built with
  the #cmd("cc370") it finds there.
+ Obtain the source of libc370, build it and install it:
  ```
  git clone https://github.com/mvslovers/libc370.git
  cd libc370
  make install
  ```
  libc370 needs no #cmd("PREFIX"): it asks the #cmd("cc370") on your
  #cmd("PATH") where its tree is, and installs there. The output ends as in
  @ug-install-libc-fig.

#fig(caption: [The end of #cmd("make install") for cc370. The installation
  prefix is shown as #cmd("$PREFIX"), and the long lines are broken.])[
  #screen(raw(read("../ex/ug-install/install.txt")))
] <ug-install-make-fig>

#fig(caption: [#cmd("make install") for libc370. The installation prefix is shown as #cmd("$PREFIX") and the source directory as #cmd(".../libc370").])[
  #screen(raw(read("../ex/ug-install/libc.txt")))
] <ug-install-libc-fig>

#idx("make tools")
#cmd("make tools") builds only the eight standalone tools, as370 to
idrdump370, and not the compiler. It takes seconds, and is useful when you
need a tool, for example file370, on a workstation where you do not compile
C.

The version of the toolchain comes from the file #cmd("VERSION") of the
source tree. A build between two releases carries a version such as
#cmd("1.2.1-dev"), which the figures in this chapter show.

== The Installed Tree <ug-install-tree>

#idx("installation", "directory tree")
@ug-install-tree-fig shows the tree that #cmd("make install") and the
release tarballs leave under the installation prefix. Only the commands are
in #cmd("bin")\; everything else that belongs to the target is in one
directory, #cmd("cc370").

#fig(caption: [The installed tree])[
  #code(
"$PREFIX/
  bin/
    cc370                   the compiler driver
    as370 ld370 ar370 ...   links to ../cc370/bin
  cc370/                    the sysroot
    bin/                    the tools: as370 ld370 ar370 file370 xmit370
                              dasm370 cmplmd370 idrdump370
    include/                the headers of libc370
    lib/                    libc.a, libcc370rt.a, crt0.o crt1.o crtm.o
    macros/                 the assembler macros
  libexec/cc370/version/
    cc1                     the compiler proper
    as ld ar                links to ../../../cc370/bin
  lib/cc370/version/        empty, but required
  share/man/man1/           the manual pages")
] <ug-install-tree-fig>

#deflist(width: 1.55in,
  [#cmd("bin")], [the commands you type. Put this directory in your
    #cmd("PATH"). Apart from #cmd("cc370"), its entries are links to the
    real programs in #cmd("cc370/bin").],
  [#cmd("cc370/include")], [the headers of the C library. The compiler
    searches this directory without #cmd("-I").],
  [#cmd("cc370/lib")], [the C library #cmd("libc.a") and the start-up
    objects #cmd("crt0.o"), #cmd("crt1.o") and #cmd("crtm.o"), which come
    from libc370, and the run-time support library #cmd("libcc370rt.a"),
    which comes with cc370. Every link searches this directory without
    #cmd("-L").],
  [#cmd("cc370/macros")], [the assembler macros: #cmd("PDPTOP"),
    #cmd("PDPPRLG") and #cmd("PDPEPIL"), which every module compiled by
    cc370 uses and which come with cc370, and the macros of libc370 and the
    system macros it needs. as370 searches this directory without
    #cmd("-I").],
  [#cmd("libexec/cc370")], [the compiler proper, #cmd("cc1"), which only the
    driver runs, and the links #cmd("as"), #cmd("ld") and #cmd("ar") by
    which the driver finds as370, ld370 and ar370. The directory is named
    after the version, so that two versions can be installed under one
    prefix.],
  [#cmd("lib/cc370")], [an empty directory, named after the version. The
    driver finds the sysroot through a path relative to it.],
)

#note[Do not remove the empty directory #cmd("lib/cc370/")#var("version").
Without it the compiler finds neither the headers nor the C library, and
every link fails with #cmd("cannot find -lc").]

#idx("sysroot", "second")
A libc370 that is kept in a directory tree of its own, as Homebrew keeps
it, can be linked into the tree as #cmd("cc370/libc370"). Its
#cmd("include"), #cmd("lib") and #cmd("macros") directories are then
searched after those of #cmd("cc370").

=== Matching Versions of cc370 and libc370 <ug-install-versions>

#idx("libc370", "version")
cc370 and libc370 are released separately, and each states the versions of
the other it works with. libc370 2.1 needs cc370 1.1.0 or later, below 2.0,
and every header of libc370 checks it: compiled with an older cc370, it
stops with the error #cmd("libc370 needs cc370 1.1.0 or later"). cc370 from
1.1.0 on needs libc370 2.1.0 or later. The installation script and the
packages choose matching versions for you\; when you build from source, build
both from their current sources.

== Checking the Installation <ug-install-check>

#idx("installation", "checking")
Check a new installation with the commands in @ug-install-check-fig:

+ #cmd("cc370 --version") shows the version of the compiler. Every tool
  answers #cmd("--version") with the same version.
+ #cmd("cc370 -print-file-name=libc.a") shows where the driver finds the C
  library. If it prints only #cmd("libc.a"), without a directory, libc370
  is not installed in this tree.
+ Compile and link a program. Any short program does\; the one used here
  is HELLO, shown in @ug-first-hello. The build must end with return code
  0 and write the load module and the TRANSMIT file.
+ #cmd("file370") identifies the TRANSMIT file and names the member in it.

#fig(caption: [Checking the installation])[
  #screen(raw(read("../ex/ug-install/check.txt")))
] <ug-install-check-fig>

#idx("stdio.h", "not found")
When libc370 is missing, the compiler cannot find even #cmd("<stdio.h>"),
and says so in a message that does not mention libc370:

#screen(raw(read("../ex/ug-install/nolibc.txt")))

Install libc370 as described in @ug-install-build or @ug-install-release,
into the tree of the #cmd("cc370") on your #cmd("PATH").

#idx("manual pages")
The manual pages are installed in #cmd("share/man/man1"). If
#cmd("man cc370") does not find them, add #cmd("$PREFIX/share/man") to the
#cmd("MANPATH") environment variable.

#idx("uninstalling")
To remove a toolchain built from source, run #cmd("make uninstall") in its
source tree, with the same #cmd("PREFIX") as for the installation. It
removes the files of cc370, but not those of libc370 in #cmd("cc370/include")
and #cmd("cc370/lib").
