# libc370 corpus regression gate (#23-lite)

Assembles every non-wip `libc370` `.asm`/`.s` module with `as370` and checks
each object deck's SHA256 against the committed manifest (`libc370.manifest`,
737 modules).

```
make test-corpus                      # verify against the manifest
sh as370/tests/corpus/check.sh        # same, directly
sh as370/tests/corpus/check.sh --generate   # rewrite the manifest
```

Needs the `libc370` checkout beside this repo (`../../libc370`); override with
`LIBC370=/path`.

## What it is — and isn't

This is a **regression guard**: it catches an `as370` change that alters any
`libc370` object deck ("did I move the corpus?"). It is **not** an oracle guard
— it does **not** re-verify "today's bytes == IFOX00". The manifest baseline is
byte-identical to IFOX00 by the historical 736/736 validation, but this gate
only enforces the *stability* of that baseline, not its *equivalence* to the
oracle. Re-running the full 910-module + sibling-repo corpus against committed
IFOX00 references is **#23-full** (follow-up).

## Determinism

The gate pins `ASMDATE`/`ASMTIME` to a fixed synthetic value. Without it the
SHAs would drift: `as370` stamps the END-record IDR with the assembly date, and
a few modules (`@@crt0`, `@@crt1`, `@@crtsvc`) embed `&SYSDATE`/`&SYSTIME` in
their object as an eye-catcher. Pinning makes every deck reproducible on any
wall clock.

## Coverage

737 of 738 non-wip modules. One (`src/clib/@@stow.s`) does not assemble on
`as370` today (pre-existing) and is skipped; `src/wip/` is excluded. Regenerate
the manifest with `--generate` when a change legitimately alters the corpus.
