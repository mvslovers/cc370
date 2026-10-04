# Does program fetch deliver a zeroed area for a hole? — measured on mvsdev, 2026-09-22

This is the question #443 was left hanging on. It is now measured, and it comes
out **in the patch's favour** — against my expectation from the IEWL evidence.

## Apparatus

`PROBE` (assembler, ~50 lines) reserves 128 KB with `DS XL131072`, counts the
non-zero bytes in it on entry, then fills it with `X'EE'` and returns: RC 0 if
the area came in clean, RC 8 if it did not.

Two builds of the same object deck, differing only in the linker:

    PROBEB   ld370 @ main    extent 131248, 10 text records, 131248 B text, no gap
    PROBE    ld370 @ #445    extent 131248,  2 text records,  24752 B text,
                             ONE INTERIOR GAP OF 106,496 BYTES

Drivers `LOAD` / call / `DELETE` and compare the load addresses; a run where the
two loads land at different addresses reports RC 16 and is discarded.

Deployed to `IBMUSER.FETCH*.LINKLIB` on mvsdev via the mvsMF REST API; every
install verified by listing the members, not by the RECEIVE return code.

## Runs

| # | What | Result |
|---|---|---|
| 1 | control: materialised PROBEB, LOAD/DELETE/LOAD | `FETCH000I` all-zero, RC 0 |
| 2 | experiment: sparse PROBE, LOAD/DELETE/LOAD, same address | `FETCH000I` all-zero, RC 0 |
| 3 | **positive control**: LOAD once, call twice, no DELETE | `FETCH2OKI` the second call SEES the `X'EE'` |
| 4 | strict: `GETMAIN` 192 KB, fill `X'DD'`, `FREEMAIN`, then LOAD sparse | `FETCH3OKI` all-zero, RC 0 |
| 5 | faithful: load materialised twin, let it write `X'EE'`, DELETE, then load sparse at the same address | `FETCH4OKI` all-zero, RC 0 |

Run 3 is what makes the rest mean anything. Without it, "the area was zero" is
indistinguishable from "the fill never happened" — and the first two runs cannot
tell those apart, because in the control fetch writes the zeros itself. Run 3
shows the mark is written and the scan finds it.

Run 5 is the faithful one: both loads go through program fetch's own allocator,
the two modules have identical extents, the addresses match, and the twin
provably left `X'EE'` across the whole work area moments earlier. The sparse
module then reads zero there.

## What it says

On this system, **MVS clears the module area**: a region of a load module that
no text record covers reads zero even when the same storage demonstrably held
non-zero bytes immediately before. The property the elision depends on holds.

Note the shape of the result: the patch's *mechanism* ("exactly as IEWL-linked
assembler DS behaves") is refuted — IFOX reserves, IEWL fills, and what it fills
with is non-zero residue. Its *conclusion* is supported. Those are independent,
and only the second one was ever load-bearing.

## What it does not say

One system, one size, one storage configuration, a batch step with a 4 MB
region and no storage pressure. Not measured: fragmentation, a long-running
address space over hours, other subpools, a module large enough to force a
different allocation path. httpd's LOAD/DELETE loop is modelled here, not
reproduced.

And it does not touch the two objections that never depended on it:

- the elision drops explicitly written `DC` zeros, which turns `ld370/tests/run.sh`
  red today — a predicate bug, not a storage question;
- it diverges from IEWL byte-fidelity, which on IBM's own code would show in
  31 of 5,230 members.

Both are fixed by keying on definedness instead of value, and by a flag.
Neither is fixed by this measurement.

## Artefacts

    tools/probe.asm     the probe: reserve 128 KB, count non-zero, fill X'EE'
    tools/driver.asm    run 2: LOAD / call / DELETE / LOAD / call
    tools/driver2.asm   run 3: the positive control (LOAD once, call twice)
    tools/driver3.asm   run 4: dirty the freed storage via GETMAIN/FREEMAIN
    tools/driver4.asm   run 5: dirty it through fetch itself, with a twin

Rebuild and deploy:

    as370 -I <libc370>/maclib -I <libc370>/sysmac -I <sysroot>/macros -o probe.o probe.asm
    ld370 -o PROBEB --name PROBEB --norent probe.o -iebcopy        # materialised
    ld370 --sparse-text -o PROBE --name PROBE --norent probe.o -iebcopy
    ld370 --pack PROBE=PROBE.iebcopy PROBEB=PROBEB.iebcopy \
          FETCHDR4=FETCHDR4.iebcopy -o lib --dsn <dsn> -xmit

then upload the XMIT and RECEIVE it into a throwaway load library, and
`EXEC PGM=FETCHDR4` with that library as STEPLIB. The datasets used for the
runs above were deleted afterwards; nothing here needs to stay on a system.

Note the `--sparse-text` spelling: the flag did not exist when these runs were
made (the linker under test was the first attempt, which elided unconditionally).
The measurement is unaffected — what was loaded is a member with a hole either
way — but a re-run today needs the flag.
