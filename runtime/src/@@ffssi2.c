/* @@FFSSI2.C - __builtin_ffs on an int (#685, #687).
 *
 * GCC 3.4 calls libc's ffs() for __builtin_ffs(int), and libc370 has no
 * ffs(), so the call did not link.  i370_init_libfuncs now names this
 * helper instead, as later GCC versions do with __ffssi2; the 64-bit form,
 * __ffsdi2 (@@FFSDI2), is in @@bitops.c.
 *
 * ffs of 0 is 0; otherwise the 1-based index of the lowest set bit.
 */

int __ffssi2(int a) asm("@@FFSSI2");

int
__ffssi2(int a)
{
    unsigned u = (unsigned)a;
    int n = 1;

    if (u == 0)
        return 0;
    while ((u & 1) == 0) {
        u >>= 1;
        n++;
    }
    return n;
}
