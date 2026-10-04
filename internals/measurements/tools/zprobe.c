/* zprobe -- what a bound load module materializes.
 *
 * Two questions about IEWL, asked at the record level so the answer does not
 * depend on as370 having reproduced the deck:
 *   A) does IEWL emit text records whose bytes are ALL ZERO?
 *   B) does the text coverage span the module extent, or are there gaps?
 * One TSV line per member; aggregation happens outside.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "obj370.h"

#define MAXIV 20000
static long iv_a[MAXIV], iv_b[MAXIV]; static int niv;

struct ext { long hi; int nsect; };
static int cesd_cb(const struct lmod_esd *e, void *ctx) {
    struct ext *x = ctx;
    if (e->type == OBJ_SD || e->type == OBJ_PC || e->type == OBJ_CM) {
        if (e->addr + e->len > x->hi) x->hi = e->addr + e->len;
        x->nsect++;
    }
    return 1;
}
static int cmpiv(const void *p, const void *q) {
    long a = *(const long *)p, b = *(const long *)q; return a < b ? -1 : a > b;
}
static long be16(const unsigned char *p) { return (p[0] << 8) | p[1]; }
static long be24(const unsigned char *p) { return ((long)p[0] << 16) | (p[1] << 8) | p[2]; }

int main(int argc, char **argv) {
    int ai;
    printf("name\tanom\tnseg\tscat\textent\tntext\ttextb\tnzero\tzerob\tngap\tgapb\tlead\ttrail\tmaxrec\n");
    for (ai = 1; ai < argc; ai++) {
        FILE *f = fopen(argv[ai], "rb");
        unsigned char *m; long n, i;
        struct lmod_iter it; struct lmod_item item; struct lmod_info info;
        struct ext x; 
        long ntext = 0, textb = 0, nzero = 0, zerob = 0, maxrec = 0;
        long pend_addr = -1, pend_len = 0;
        const char *base, *slash;
        if (!f) { fprintf(stderr, "open %s\n", argv[ai]); continue; }
        fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
        m = malloc((size_t)(n > 0 ? n : 1));
        if (fread(m, 1, (size_t)n, f) != (size_t)n) { fclose(f); free(m); continue; }
        fclose(f);

        memset(&info, 0, sizeof info); lmod_scan(m, n, &info);
        memset(&x, 0, sizeof x); lmod_cesd_walk(m, n, cesd_cb, &x);

        niv = 0;
        lmod_iter_init(&it, m, n);
        while (lmod_iter_next(&it, &item) == 1) {
            const unsigned char *r = m + item.off;
            if (item.kind == LMOD_CTL) {
                pend_addr = -1;
                if (item.flags & LMOD_CTL_TEXT) { pend_addr = be24(r + 9); pend_len = be16(r + 14); }
            } else if (item.kind == LMOD_TEXT) {
                long k; int allz = 1;
                ntext++; textb += item.len;
                if (item.len > maxrec) maxrec = item.len;
                for (k = 0; k < item.len; k++) if (r[k]) { allz = 0; break; }
                if (allz) { nzero++; zerob += item.len; }
                if (pend_addr >= 0 && niv < MAXIV) {
                    /* trust the CCW count only when it matches the record */
                    iv_a[niv] = pend_addr; iv_b[niv] = pend_addr + item.len; niv++;
                }
                pend_addr = -1; (void)pend_len;
            }
        }
        /* merge intervals -> gaps */
        {
            long ngap = 0, gapb = 0, lead = 0, trail = 0, end = -1;
            long *idx = malloc((size_t)(niv > 0 ? niv : 1) * sizeof(long));
            for (i = 0; i < niv; i++) idx[i] = iv_a[i];
            qsort(idx, (size_t)niv, sizeof(long), cmpiv);
            /* re-walk in sorted-start order (intervals are few and disjoint in
             * practice; pair each sorted start with its own end) */
            for (i = 0; i < niv; i++) {
                long a = idx[i], b = 0; long j;
                for (j = 0; j < niv; j++) if (iv_a[j] == a) { if (iv_b[j] > b) b = iv_b[j]; }
                if (end < 0) { lead = a; end = b; continue; }
                if (a > end) { ngap++; gapb += a - end; }
                if (b > end) end = b;
            }
            if (end < 0) end = 0;
            trail = x.hi > end ? x.hi - end : 0;
            base = argv[ai]; for (slash = base; *slash; slash++) if (*slash == '/') base = slash + 1;
            printf("%s\t%d\t%d\t%d\t%ld\t%ld\t%ld\t%ld\t%ld\t%ld\t%ld\t%ld\t%ld\t%ld\n",
                   base, info.anomalies, info.nseg, info.has_scatter, x.hi,
                   ntext, textb, nzero, zerob, ngap, gapb, lead, trail, maxrec);
            free(idx);
        }
        free(m);
    }
    return 0;
}
