/*
 * tsttrapv.c - the runtime helpers new in libcc370rt.a (#687), on MVS.
 *
 * Every helper is reached the way a program reaches it: __builtin_ffs on
 * an int, and long long + - * unary - and int * compiled with -ftrapv, so
 * cc370 emits the libcall and chooses the name.  Operands are volatile so
 * nothing folds at compile time.
 *
 *   no PARM   (1) @@FFSSI2: 0, 1, bit 31, mixed values, negatives
 *             (2) the -ftrapv helpers without overflow, up to the limits
 *             RC 0 = all passed, 1 = a check failed
 *   PARM=ADDV|SUBV|MULV|MULS|NEGV
 *             one overflowing operation through @@ADDVDI / @@SUBVDI /
 *             @@MULVDI / @@MULVSI / @@NEGVDI; the helper calls abort().
 *             What that does on MVS is what the step's completion code
 *             records.  Reaching the end prints a line and returns 99.
 *
 * Build (cc370 >= 1.1.0, from the repo root; libc370 2.0 is enough, the
 * runtime is searched first):
 *     cc370 -O1 -ftrapv runtime/tests/mvs/tsttrapv.c -o TRTV \
 *           -flinker-output=iebcopy -Wl,--map,TRTV.map
 * The map must show @@ffssi2 and @@trapv from libcc370rt.a.
 * Install: ld370 --pack TRTV=TRTV.iebcopy ... -o rt -xmit
 *          --dsn IBMUSER.CC370.RTSCR, upload to IBMUSER.CC370.RTXMIT (FB 80),
 *          RECEIVE INDSN('IBMUSER.CC370.RTXMIT') after deleting RTSCR.
 * Run:     one step without PARM, then one per PARM, STEPLIB RTSCR.
 *
 * GREEN, mvsdev JOB01185 (RECEIVE JOB01184), 2026-10-03, cc370 28cf083
 * linked against libc370 2.0 with -lcc370rt first:
 *   no PARM                      CC 0000, 29 checks, 0 failed
 *   ADDV SUBV MULV MULS NEGV     CC 0012 each, and "RETURNED" never printed:
 *     the helper calls abort(), libc370's abort() raises SIGABRT, whose
 *     default action is exit(EXIT_FAILURE), and EXIT_FAILURE is 12 on MVS.
 *     A normal step end -- no abend, no dump.
 * In the same job the moved helpers' tests from libc370, linked from
 * libcc370rt.a (the maps name no helper member of libc.a): tstcnvdi
 * 565/565, tstdi3 1138/1138 including the four S0C9 zero divisors.
 */
#include <stdio.h>
#include <string.h>
#include <limits.h>
#ifndef LLONG_MAX                   /* libc370 2.0's <limits.h> has none */
#define LLONG_MAX 9223372036854775807LL
#define LLONG_MIN (-LLONG_MAX - 1)
#endif

static int failed, checks;
#define CHECK(cond, ...) do { checks++; if (!(cond)) { failed++; \
    printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); } } while (0)

typedef long long ll;

static volatile int vi[] = { 0, 1, (int)0x80000000u, 0x00F0, -8, 0x7FFFFFFF, 6, -1, 0x00010000 };
static const int ffs_want[] = { 0, 1, 32, 5, 4, 1, 2, 1, 17 };

static volatile ll va, vb;
static volatile int ia, ib;

static void ffs_checks(void)
{
    unsigned i;
    printf("(1) __builtin_ffs(int) through @@FFSSI2\n");
    for (i = 0; i < sizeof ffs_want / sizeof *ffs_want; i++) {
        int x = vi[i];
        CHECK(__builtin_ffs(x) == ffs_want[i], "ffs(%d) = %d, want %d", x, __builtin_ffs(x), ffs_want[i]);
    }
}

static void trapv_checks(void)
{
    printf("(2) -ftrapv helpers without overflow\n");
    va = LLONG_MAX - 5; vb = 5;     CHECK(va + vb == LLONG_MAX, "LLONG_MAX-5 + 5");
    va = LLONG_MIN + 5; vb = -5;    CHECK(va + vb == LLONG_MIN, "LLONG_MIN+5 + -5");
    va = LLONG_MAX; vb = LLONG_MIN; CHECK(va + vb == -1, "LLONG_MAX + LLONG_MIN");
    va = 0x100000000LL; vb = 0xFFFFFFFFLL; CHECK(va + vb == 0x1FFFFFFFFLL, "carry across the halves");
    va = LLONG_MIN + 5; vb = 5;     CHECK(va - vb == LLONG_MIN, "LLONG_MIN+5 - 5");
    va = LLONG_MAX - 5; vb = -5;    CHECK(va - vb == LLONG_MAX, "LLONG_MAX-5 - -5");
    va = -1; vb = LLONG_MAX;        CHECK(va - vb == LLONG_MIN, "-1 - LLONG_MAX");
    va = 0x100000000LL; vb = 1;     CHECK(va - vb == 0xFFFFFFFFLL, "borrow across the halves");
    va = 3037000499LL; vb = 3037000499LL; CHECK(va * vb == 9223372030926249001LL, "3037000499^2");
    va = -4611686018427387904LL; vb = 2; CHECK(va * vb == LLONG_MIN, "-2^62 * 2 = LLONG_MIN");
    va = LLONG_MIN; vb = 1;         CHECK(va * vb == LLONG_MIN, "LLONG_MIN * 1");
    va = -123456789LL; vb = -987654321LL; CHECK(va * vb == 121932631112635269LL, "neg * neg");
    va = 0x100000000LL; vb = 0x7FFFFFFFLL; CHECK(va * vb == 0x7FFFFFFF00000000LL, "cross term only");
    va = LLONG_MAX;                 CHECK(-va == -LLONG_MAX, "-LLONG_MAX");
    va = LLONG_MIN + 1;             CHECK(-va == LLONG_MAX, "-(LLONG_MIN+1)");
    va = 0;                         CHECK(-va == 0, "-0");
    ia = INT_MIN; ib = 1;           CHECK(ia * ib == INT_MIN, "INT_MIN * 1");
    ia = -46341; ib = 46340;        CHECK(ia * ib == -2147441940, "-46341 * 46340");
    ia = 65535; ib = 32768;         CHECK(ia * ib == 2147450880, "65535 * 32768");
    ia = -1; ib = INT_MAX;          CHECK(ia * ib == -INT_MAX, "-1 * INT_MAX");
}

static int overflow(const char *what)
{
    ll r = 0; int s = 0;
    printf("overflow %s: calling the helper\n", what);
    if (!strcmp(what, "ADDV")) { va = LLONG_MAX; vb = 1; r = va + vb; }
    else if (!strcmp(what, "SUBV")) { va = LLONG_MIN; vb = 1; r = va - vb; }
    else if (!strcmp(what, "MULV")) { va = 3037000500LL; vb = 3037000500LL; r = va * vb; }
    else if (!strcmp(what, "MULS")) { ia = 65536; ib = 32768; s = ia * ib; }
    else if (!strcmp(what, "NEGV")) { va = LLONG_MIN; r = -va; }
    else { printf("unknown PARM %s\n", what); return 98; }
    printf("overflow %s: the helper RETURNED (%lld / %d) -- it should not have\n", what, r, s);
    return 99;
}

int main(int argc, char **argv)
{
    if (argc > 1)
        return overflow(argv[1]);
    ffs_checks();
    trapv_checks();
    printf("%d checks, %d failed\n", checks, failed);
    return failed ? 1 : 0;
}
