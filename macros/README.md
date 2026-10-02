# macros/ — the compiler's own assembler macros

Every `.s` cc370 writes starts with `COPY PDPTOP` and wraps each function in
`PDPPRLG` / `PDPEPIL` (`cc370/gcc/config/i370/i370.c`). Those three members are
the compiler's calling convention, so they ship with the compiler (#688):
`make install` puts them into `<prefix>/cc370/macros`, where as370 looks by
default.

They came from libc370's `maclib/` (public domain, Chris Langford and Dave
Jones, 2006). `pdptop.copy` is unchanged. `PDPPRLG` and `PDPEPIL` used to call
the IBM macros `SAVE (14,12),,name` and `RETURN (14,12),RC=(15)`; they now
write out the instructions those generate, so cc370 ships no IBM macro.
`make test-macros` (`tests/check.sh`) assembles every source that uses the
members once with libc370's originals and once with these, and requires the
same deck.

The members are de facto public — hand-written assembler in libc370, rexx370
and nsf370 uses them — so their expansion is an interface: change it only
together with #689.
