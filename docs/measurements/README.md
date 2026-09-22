# Measurements

Measurement records that answer a question the source cannot. Each one names its
instrument, its population, its controls, and — the part that matters most when
someone reaches for it later — **what it did not cover**.

The rule these follow: a number may be published by whoever measured it, but the
sentence beside it has to be re-derived from the artefact rather than from memory
of it. Where a figure here is not what the run produced, the run is the authority.

| File | Question | Answer |
|---|---|---|
| [`ifox-reserves-iewl-fills.md`](ifox-reserves-iewl-fills.md) | Does the IBM toolchain ship a load module with holes where the source reserved storage? | No. IFOX00 emits no TXT for a `DS` (67.4% of 5,528 decks), IEWL fills it in (1,629 of 1,631 pairs), and what it fills it with is non-zero residue. IEWL does not elide all-zero text records either. |
| [`fetch-zeroing.md`](fetch-zeroing.md) | Does program fetch deliver a zeroed area for a region no text record covers? | On MVS 3.8j, yes — five runs including a positive control and a run where the same storage demonstrably held `X'EE'` moments before. Batch, one system, no storage pressure. |
| [`module-size-limits.md`](module-size-limits.md) | Do the three size/bounds fixes change anything on the corpus? | No: 5,528 of 5,528 decks byte-identical either way. The `put()` overflow they fix is silent between 1 MB and 16 MB, not a crash. |

`tools/` holds the probes and the MVS apparatus. They are measurement code, not
part of the toolchain: nothing builds or installs them, and they are kept so a
figure can be re-derived rather than re-argued.

Both host probes build against the repo's own record walker, which is the point —
a probe with its own parser measures its own parser:

    gcc -O2 -Wall -Icommon/include -o /tmp/zprobe docs/measurements/tools/zprobe.c \
        common/src/obj370.c common/src/mvs370.c

The corpora they read are local and unpublished (`mvs38src/work/measurements/`).
Module names appear in the figures; no IBM source or object content is reproduced.
