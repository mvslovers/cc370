/* oprobe -- what an OBJECT DECK leaves uncovered.
 * For each SD/PC/CM section: how many of its bytes are covered by a TXT card.
 * A byte no TXT card covers is one the assembler reserved (DS) and did not
 * emit. Mapping follows cmplmd370: index = txt.addr - section.org.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "obj370.h"

#define MAXS 512
struct sect { int id; long org, len; unsigned char *cov; };
static struct sect S_[MAXS]; static int nS;
static int esd_cb(const struct obj_esd *e, void *ctx) {
    (void)ctx;
    if (obj_is_section(e->type) && nS < MAXS) {
        S_[nS].id = e->esdid; S_[nS].org = e->addr; S_[nS].len = e->len;
        S_[nS].cov = e->len > 0 ? calloc((size_t)e->len, 1) : NULL;
        nS++;
    }
    return 1;
}
int main(int argc, char **argv) {
    int ai;
    printf("name\tnsect\tseclen\tcovered\tngap\tgapb\ttrail\n");
    for (ai = 1; ai < argc; ai++) {
        FILE *f = fopen(argv[ai], "rb"); unsigned char *b; long n, off; int i;
        const char *base, *p;
        long seclen = 0, covered = 0, ngap = 0, gapb = 0, trail = 0;
        if (!f) continue;
        fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
        b = malloc((size_t)(n > 0 ? n : 1));
        if (fread(b, 1, (size_t)n, f) != (size_t)n) { fclose(f); free(b); continue; }
        fclose(f);
        for (i = 0; i < nS; i++) free(S_[i].cov);
        nS = 0;
        for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN)
            if (obj_card_type(b + off) == OBJ_ESD) obj_esd_walk(b + off, esd_cb, NULL);
        for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN) {
            struct obj_txt t;
            if (obj_card_type(b + off) != OBJ_TXT) continue;
            if (!obj_txt_get(b + off, &t)) continue;
            for (i = 0; i < nS; i++) if (S_[i].id == t.esdid && S_[i].cov) {
                long a = t.addr - S_[i].org, k;
                for (k = 0; k < t.len; k++)
                    if (a + k >= 0 && a + k < S_[i].len) S_[i].cov[a + k] = 1;
                break;
            }
        }
        for (i = 0; i < nS; i++) {
            long k, run = -1, lastcov = -1;
            seclen += S_[i].len;
            for (k = 0; k < S_[i].len; k++) if (S_[i].cov && S_[i].cov[k]) { covered++; lastcov = k; }
            /* interior gaps: uncovered runs that lie before the last covered byte */
            for (k = 0; k <= lastcov; k++) {
                int c = S_[i].cov && S_[i].cov[k];
                if (!c && run < 0) run = k;
                if (c && run >= 0) { ngap++; gapb += k - run; run = -1; }
            }
            trail += S_[i].len - 1 - lastcov;   /* lastcov==-1 -> whole section */
        }
        base = argv[ai]; for (p = base; *p; p++) if (*p == '/') base = p + 1;
        printf("%s\t%d\t%ld\t%ld\t%ld\t%ld\t%ld\n", base, nS, seclen, covered, ngap, gapb, trail);
        free(b);
    }
    return 0;
}
