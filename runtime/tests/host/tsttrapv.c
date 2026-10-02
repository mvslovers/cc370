/*
 * tsttrapv.c - the -ftrapv helpers and __ffssi2 (#687), on the host.
 *
 * @@trapv.c and @@ffssi2.c are #included and checked against the host
 * compiler's own overflow builtins: a table of edge operands crossed with
 * itself, then 1,000,000 pseudo-random pairs per helper, with operand
 * widths drawn so that small, mid-range and near-limit values all occur.
 * abort() is redirected to a longjmp, so "aborted" is something a check
 * can see: a helper must abort exactly when the operation overflows, and
 * otherwise return the exact result.
 *
 * What this proves is the arithmetic, not the S/370 code -- the halves'
 * word order is picked from __BYTE_ORDER__, as in tstdi3.c.
 *
 * BUILD / RUN (host, from runtime/tests/host):
 *
 *     cc -std=gnu99 -Wall -Wextra -Werror -O1 -o /tmp/tsttrapv tsttrapv.c
 *     /tmp/tsttrapv
 */
#include <setjmp.h>
#include <stdio.h>
#include <limits.h>

static jmp_buf trap;
static void test_abort(void) { longjmp(trap, 1); }
/* The asm("@@NAME") labels are the S/370 names; an ELF assembler rejects
   '@' in a symbol it is handed as an operand, which taking a helper's
   address (call_ll below) does.  The host test calls the C names. */
#define asm(name)
#define abort test_abort
#include "../../src/@@trapv.c"
#undef abort
#include "../../src/@@ffssi2.c"
#undef asm

static long checks, failures;

#define CHECK(cond, ...) do { checks++; if (!(cond)) { failures++; \
    if (failures <= 20) { printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); } } } while (0)

/* a: returns 1 when the helper aborted, else 0 and *res */
static int call_ll(long long (*f)(long long, long long), long long a, long long b, long long *res)
{
    volatile int aborted = 0;
    if (setjmp(trap)) aborted = 1;
    else *res = f(a, b);
    return aborted;
}
static int call_neg(long long a, long long *res)
{
    volatile int aborted = 0;
    if (setjmp(trap)) aborted = 1;
    else *res = __negvdi2(a);
    return aborted;
}
static int call_si(int a, int b, int *res)
{
    volatile int aborted = 0;
    if (setjmp(trap)) aborted = 1;
    else *res = __mulvsi3(a, b);
    return aborted;
}

static void one_ll(long long a, long long b)
{
    long long want, got = 0;
    int ovf, ab;

    ovf = __builtin_add_overflow(a, b, &want);
    ab = call_ll(__addvdi3, a, b, &got);
    CHECK(ab == ovf && (ovf || got == want), "addvdi3(%lld, %lld): aborted %d got %lld, want %s%lld", a, b, ab, got, ovf ? "abort " : "", want);
    ovf = __builtin_sub_overflow(a, b, &want);
    ab = call_ll(__subvdi3, a, b, &got);
    CHECK(ab == ovf && (ovf || got == want), "subvdi3(%lld, %lld): aborted %d got %lld, want %s%lld", a, b, ab, got, ovf ? "abort " : "", want);
    ovf = __builtin_mul_overflow(a, b, &want);
    ab = call_ll(__mulvdi3, a, b, &got);
    CHECK(ab == ovf && (ovf || got == want), "mulvdi3(%lld, %lld): aborted %d got %lld, want %s%lld", a, b, ab, got, ovf ? "abort " : "", want);
}

static void one_neg(long long a)
{
    long long want, got = 0;
    int ovf = __builtin_sub_overflow(0LL, a, &want);
    int ab = call_neg(a, &got);
    CHECK(ab == ovf && (ovf || got == want), "negvdi2(%lld): aborted %d got %lld", a, ab, got);
}

static void one_si(int a, int b)
{
    int want, got = 0;
    int ovf = __builtin_mul_overflow(a, b, &want);
    int ab = call_si(a, b, &got);
    CHECK(ab == ovf && (ovf || got == want), "mulvsi3(%d, %d): aborted %d got %d, want %s%d", a, b, ab, got, ovf ? "abort " : "", want);
}

static int ref_ffs(int a)
{
    unsigned u = (unsigned)a;
    int n;
    if (!u) return 0;
    for (n = 1; !(u & 1); u >>= 1) n++;
    return n;
}

static unsigned long long rng = 0x2545F4914F6CDD1DULL;
static unsigned long long next(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return rng;
}
/* a value whose magnitude has a random number of significant bits */
static long long draw(void)
{
    unsigned bits = (unsigned)(next() % 64) + 1;
    unsigned long long v = next();
    v = bits == 64 ? v : v & ((1ULL << bits) - 1);
    return (next() & 1) ? (long long)v : -(long long)(v & ~(1ULL << 63));
}

int main(void)
{
    static const long long edge[] = {
        0, 1, -1, 2, -2, 3, 0x7FFFFFFFLL, -0x7FFFFFFFLL, 0x80000000LL, -0x80000000LL,
        0xFFFFFFFFLL, 0x100000000LL, -0x100000000LL, 0x7FFFFFFFFFFFLL, 3037000499LL,
        -3037000499LL, 3037000500LL, -3037000500LL, 0x4000000000000000LL,
        -0x4000000000000000LL, LLONG_MAX, LLONG_MAX - 1, LLONG_MIN, LLONG_MIN + 1,
    };
    static const int iedge[] = {
        0, 1, -1, 2, -2, 46340, -46340, 46341, -46341, 65536, -65536, 0x7FFF, 0x8000,
        INT_MAX, INT_MAX - 1, INT_MIN, INT_MIN + 1,
    };
    unsigned i, j;
    long n;

    for (i = 0; i < sizeof edge / sizeof *edge; i++) {
        one_neg(edge[i]);
        for (j = 0; j < sizeof edge / sizeof *edge; j++)
            one_ll(edge[i], edge[j]);
    }
    for (i = 0; i < sizeof iedge / sizeof *iedge; i++)
        for (j = 0; j < sizeof iedge / sizeof *iedge; j++)
            one_si(iedge[i], iedge[j]);
    for (n = 0; n < 1000000; n++) {
        long long a = draw(), b = draw();
        one_ll(a, b);
        one_neg(a);
        one_si((int)a, (int)(b >> (next() % 32)));
    }
    for (i = 0; i < sizeof iedge / sizeof *iedge; i++)
        CHECK(__ffssi2(iedge[i]) == ref_ffs(iedge[i]), "ffssi2(%d) = %d", iedge[i], __ffssi2(iedge[i]));
    for (n = 0; n < 1000000; n++) {
        int a = (int)next();
        a = (int)((unsigned)a & (~0u << (next() % 32)));
        CHECK(__ffssi2(a) == ref_ffs(a), "ffssi2(%d) = %d", a, __ffssi2(a));
    }
    printf("  total: %ld checks, %ld failures\n", checks, failures);
    return failures != 0;
}
