# PR #444 — verification, 2026-09-22

Binaries built from worktrees and staged to fixed paths before any run, so
nothing moved under a measurement:

    as370.main   ed82138   as370.pr444  4b77b46
    ld370.main   ed82138   ld370.pr444  4b77b46

## Negative controls — each FAILS on the pre-fix binary

**`put()` past `TEXTMAX`.** `c1.s`: 46 × `DS XL32767` then one `DC X'FF'`, so
the byte lands at 1,507,282. To find out whether `put()` is really reached
there, pr444's source was rebuilt with `TEXTMAX` set back to 1 MB; its new check
fires: `as370: text beyond TEXTMAX at 1507282`. So on `main` that write goes
**458,706 bytes past `text[]`**, into `defn[]`.

It does not crash and it is not reported. An ASan build of `as370.main` runs
`c1.s` to rc=0 in silence — the write lands deep inside the next global, not in
a redzone. At 8.2 MB (`c5.s`) `main` is still rc=0. Both decks are byte-identical
to pr444's, because `put()` reads the byte back from the same wrong address.

    module extent   as370.main              as370.pr444
    1.5 MB          rc=0, deck looks right  rc=0, same deck
    8.2 MB          rc=0                    rc=0
    17.7 MB         rc=139 (SIGSEGV)        rc=2, "text beyond TEXTMAX at 17694184"

So the author's "segfaults with no message" is the far case. The near case,
1 MB to 16 MB, is a **silent out-of-bounds write** — which is the better
argument for the patch than the one the PR makes.

**`MAXLIT`.** `c7.s`: 8,400 distinct literals in 21 blocks of 400, each pool
inside its own base register's 4 K range, so the literal table is the only limit
in play.

    as370.main   rc=2  "as370: literal table full"   no deck
    as370.pr444  rc=0  97,600-byte deck              0 errors

**`ld370 mod[1 << 20]`.** `c3.s`: one `DC X'FF'` then 40 × `DS XL32767`, extent
1,310,681.

    ld370.main   rc=133 (fortify abort)  no member
    ld370.pr444  rc=0                    1,312,965-byte member

## Regression — nothing moves

    as370 suite       main and pr444 produce BYTE-IDENTICAL output
                      174 OK, same 5 pre-existing failures (sample2/7/8/9, dcb;
                      these fail on main too)
    ld370 suite       identical output, ALL GREEN on both

    tree-wide gate    tools/gate.sh, ASMDATE=09/07/26 ASMTIME=12.00
                      g444base = as370.main, g444cand = as370.pr444
                      5,528 modules each, 5,528 rows in each .tsv (complete)
                      ALL 5,528 ROWS IDENTICAL, including every deck's SHA256
                      rc distribution identical: rc0=4749 rc4=25 rc8=711 rc12=43

`retest.py` was run on both anyway, with `ASMDATES=/dev/null SYSPARMS=/dev/null`
(the IFOX00 comparison setting). The two reports are **identical line for line**
except for the name of their own per-module `.tsv`:

    as370 == IFOX00 : 5431 -> 5213   (-218)      <- the same figure on BOTH runs

So PR #444's own delta is zero. The `-218` is the *baseline's* age, not this
PR: it compares as370 today against the IFOX00 recording of 2026-09-07, across
a macro corpus that has been repaired since (`amaclib-live` ordering, the
`IGGCP14` CCW-count fix). It is not interpretable as a regression without
re-running on the corpus-date macros, and it is identical on `main`.

## Verdict

Three real defects, each demonstrated on the pre-fix binary and each fixed.
Whole-tree output unchanged, deck for deck, and the IFOX identity figure
unmoved. Mergeable.

Open, as a follow-up and not a blocker: `TEXTMAX` at 16 MB makes `text` +
`defn` + `txl_bytes` (`TXL_BUF = TEXTMAX*2`) **64 MB of static arrays**. The
repo's pattern for this class is computed sizing (`grow_arr`, `unload_size()`).
