/* @@TRAPV.C - the -ftrapv helpers: arithmetic that aborts on overflow.
 *
 * Under -ftrapv cc370 compiles a long long +, -, *, unary - and an int *
 * into calls to these (#685, #687); before them nothing defined any, and
 * such a program did not link.
 *
 *   __addvdi3   @@ADDVDI     long long a + b
 *   __subvdi3   @@SUBVDI     long long a - b
 *   __mulvdi3   @@MULVDI     long long a * b
 *   __mulvsi3   @@MULVSI     int a * b
 *   __negvdi2   @@NEGVDI     long long -a
 *
 * The int + and - and the int - stay inline.  On overflow each calls
 * abort(), as libgcc's do; that is the one thing this member takes from
 * libc.  Otherwise the result is the wrapped one, which is also what the
 * operation without -ftrapv gives.
 *
 * Everything works on 32-bit halves, for the reasons given in @@muldi3.c:
 * a 64-bit operation here could compile into a call to a helper, and some
 * inline 64-bit shapes are miscompiled (cc370#467, cc370#468).
 */

typedef union {
    unsigned long long  u;
    long long           s;
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    struct { unsigned lo, hi; } w;      /* little-endian host test only */
#else
    struct { unsigned hi, lo; } w;      /* S/370 is big-endian */
#endif
} dw_t;

#define SIGN 0x80000000u

void abort(void);

long long __addvdi3(long long a, long long b) asm("@@ADDVDI");
long long __subvdi3(long long a, long long b) asm("@@SUBVDI");
long long __mulvdi3(long long a, long long b) asm("@@MULVDI");
int       __mulvsi3(int a, int b)             asm("@@MULVSI");
long long __negvdi2(long long a)              asm("@@NEGVDI");

/* 32 x 32 -> 64 unsigned, from 16-bit partial products (see @@muldi3.c) */
static void
mul32(unsigned a, unsigned b, unsigned *hi, unsigned *lo)
{
    unsigned a0 = a & 0xFFFF, a1 = a >> 16;
    unsigned b0 = b & 0xFFFF, b1 = b >> 16;
    unsigned p00 = a0 * b0, p01 = a0 * b1, p10 = a1 * b0, p11 = a1 * b1;
    unsigned mid = (p00 >> 16) + (p01 & 0xFFFF) + (p10 & 0xFFFF);

    *lo = (p00 & 0xFFFF) | (mid << 16);
    *hi = p11 + (p01 >> 16) + (p10 >> 16) + (mid >> 16);
}

/* two's complement of a double word, in place */
static void
neg64(dw_t *x)
{
    x->w.lo = ~x->w.lo + 1;
    x->w.hi = ~x->w.hi + (x->w.lo == 0);
}

long long
__addvdi3(long long a, long long b)
{
    dw_t x, y, r;

    x.s = a;
    y.s = b;
    r.w.lo = x.w.lo + y.w.lo;
    r.w.hi = x.w.hi + y.w.hi + (r.w.lo < x.w.lo);
    /* overflow: both operands have one sign and the sum the other */
    if (~(x.w.hi ^ y.w.hi) & (x.w.hi ^ r.w.hi) & SIGN)
        abort();
    return r.s;
}

long long
__subvdi3(long long a, long long b)
{
    dw_t x, y, r;

    x.s = a;
    y.s = b;
    r.w.lo = x.w.lo - y.w.lo;
    r.w.hi = x.w.hi - y.w.hi - (x.w.lo < y.w.lo);
    /* overflow: the operands differ in sign and the result's is not a's */
    if ((x.w.hi ^ y.w.hi) & (x.w.hi ^ r.w.hi) & SIGN)
        abort();
    return r.s;
}

long long
__negvdi2(long long a)
{
    dw_t x;

    x.s = a;
    if (x.w.hi == SIGN && x.w.lo == 0)      /* -LLONG_MIN */
        abort();
    neg64(&x);
    return x.s;
}

int
__mulvsi3(int a, int b)
{
    unsigned ua = a < 0 ? 0u - (unsigned)a : (unsigned)a;
    unsigned ub = b < 0 ? 0u - (unsigned)b : (unsigned)b;
    unsigned neg = (a < 0) != (b < 0), hi, lo;

    mul32(ua, ub, &hi, &lo);
    /* the magnitude may reach 2^31 only when the product is negative */
    if (hi != 0 || lo > 0x7FFFFFFFu + neg)
        abort();
    return (int)(neg ? 0u - lo : lo);
}

long long
__mulvdi3(long long a, long long b)
{
    dw_t x, y, r;
    unsigned neg, h, l, ch, cl;

    x.s = a;
    y.s = b;
    neg = ((x.w.hi ^ y.w.hi) & SIGN) != 0;
    if (x.w.hi & SIGN)
        neg64(&x);
    if (y.w.hi & SIGN)
        neg64(&y);
    /* |a| * |b| must stay below 2^63 (2^63 itself when negative).  Two high
       words that are both non-zero already make it at least 2^64. */
    if (x.w.hi != 0 && y.w.hi != 0)
        abort();
    mul32(x.w.lo, y.w.lo, &r.w.hi, &r.w.lo);
    /* at most one cross term; it reaches the result shifted by 32 */
    if (x.w.hi != 0)
        mul32(x.w.hi, y.w.lo, &ch, &cl);
    else
        mul32(x.w.lo, y.w.hi, &ch, &cl);
    if (ch != 0)
        abort();
    h = r.w.hi + cl;
    if (h < cl)                             /* carry out of bit 63 */
        abort();
    r.w.hi = h;
    l = r.w.lo;
    if ((h & SIGN) && !(neg && h == SIGN && l == 0))
        abort();
    if (neg)
        neg64(&r);
    return r.s;
}
