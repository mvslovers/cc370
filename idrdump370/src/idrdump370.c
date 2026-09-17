/* idrdump370 -- the IDR core of cc370#429 (carved out of #111).
 *
 * Walks a bound load-module member's IDR CHAIN and reports each record by
 * subtype, with the HMASPZAP entries DECODED and attributed to the section
 * their CESDID names.
 *
 * WHY A CHAIN WALK AND NOT A SCAN FOR X'80'.  Text and control records begin
 * with X'80' too.  A loose scan over one real member (IEFVFA) reads the two
 * genuine IDRs and then reports subtypes X'14', X'58' and X'C8', which are text
 * records -- and mvs38src's own attempt found the always-present linkage-editor
 * IDR in 164 of 423 members where the answer is all of them.  The framing is
 * lmod_iter_next()'s, which is shared, tested, and stops at MODEND.
 *
 * WHY THE CESDID MATTERS.  An SPZAP entry NAMES its section and carries no
 * offset (docs/load-module-format.md 10.1, from HEWLFIDR.ASM's ZAPLOOP).  So a
 * member's entry COUNT is an upper bound on "was this CSECT serviced" and the
 * decoded CESDID is the answer -- which is the whole reason this exists.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mvs370.h"
#include "obj370.h"

#define VERSION_STR "idrdump370 V1.0"

/* IDR subtypes -- HEWLFOUT.ASM via docs/load-module-format.md section 10.
 * LASTIDR is OR'd into the subtype byte, so mask before comparing. */
enum { IDR_SPZAP = 0x01, IDR_LKED = 0x02, IDR_XLATE = 0x04, IDR_USER = 0x08,
       IDR_LAST  = 0x80 };
/* SPZAP: count at byte 3 with CHAIN X'40' OR'd in; entries from byte 4. */
enum { SPZAP_CHAIN = 0x40, SPZAP_HDR = 4, SPZAP_ENTLEN = 13 };

#define MAXSECT 1024
static struct { int esdid; char name[9]; } sect[MAXSECT];
static int nsect;

static int cesd_cb(const struct lmod_esd *e, void *ctx)
{
    (void)ctx;
    if (nsect >= MAXSECT) return 0;
    if (e->type != OBJ_SD && e->type != OBJ_PC) return 1;   /* sections only */
    sect[nsect].esdid = e->esdid;
    {
        int k;
        for (k = 0; k < 8; k++) sect[nsect].name[k] = mvs_e2a_pr(e->name[k]);
        sect[nsect].name[8] = 0;
        while (k > 0 && sect[nsect].name[k - 1] == ' ') k--;
        sect[nsect].name[k] = 0;
    }
    nsect++;
    return 1;
}

static const char *sect_name(int esdid)
{
    int i;
    for (i = 0; i < nsect; i++) if (sect[i].esdid == esdid) return sect[i].name;
    return NULL;
}

static const char *subtype_name(int s)
{
    switch (s & 0x7f) {
    case IDR_SPZAP: return "HMASPZAP";
    case IDR_LKED:  return "LKED";
    case IDR_XLATE: return "translator";
    case IDR_USER:  return "user";
    default:        return "unknown";
    }
}

/* A packed yyddd, rendered as-is rather than guessed into a century: the field
 * is three bytes and the century is not in them. */
static void packed_date(char *out, const unsigned char *p)
{
    sprintf(out, "%02x%03x", p[0], ((p[1] << 8 | p[2]) >> 4) & 0xfff);
}

static void jstr(const char *s)
{
    putchar('"');
    for (; *s; s++) {
        if (*s == '"' || *s == '\\') printf("\\%c", *s);
        else if ((unsigned char)*s < 0x20) printf("\\u%04x", *s);
        else putchar(*s);
    }
    putchar('"');
}

/* ---- one IDR record ---------------------------------------------------- */
/* r points at the record; rlen is what the iterator framed for us. */
static void show_idr(const unsigned char *r, long rlen, long off,
                     const char *only, int json, int *first)
{
    int sub = r[2], base = sub & 0x7f, last = (sub & IDR_LAST) != 0;
    const char *nm = subtype_name(sub);

    if (base == IDR_SPZAP) {
        int raw = r[3], n = raw & 0x3f, chain = (raw & SPZAP_CHAIN) != 0, k;
        for (k = 0; k < n; k++) {
            const unsigned char *e = r + SPZAP_HDR + (long)k * SPZAP_ENTLEN;
            int esdid; char date[16], zap[9]; int j;
            const char *owner;
            if (SPZAP_HDR + (long)(k + 1) * SPZAP_ENTLEN > rlen) break;  /* framed short */
            esdid = e[0] << 8 | e[1];
            packed_date(date, e + 2);
            for (j = 0; j < 8; j++) zap[j] = mvs_e2a_pr(e[5 + j]);
            zap[8] = 0;
            {
                int t = 8;
                while (t > 0 && zap[t - 1] == ' ') t--;
                zap[t] = 0;
            }
            owner = sect_name(esdid);
            if (only && (!owner || strcmp(owner, only))) continue;
            if (json) {
                printf("%s\n    {\"record\": %ld, \"subtype\": \"HMASPZAP\", \"last\": %s,"
                       " \"chain\": %s, \"csect\": ", *first ? "" : ",", off,
                       last ? "true" : "false", chain ? "true" : "false");
                if (owner) jstr(owner); else printf("null");
                printf(", \"cesdid\": %d, \"date\": ", esdid); jstr(date);
                printf(", \"zap\": "); jstr(zap); printf("}");
                *first = 0;
            } else {
                printf("  @%06lX  HMASPZAP  csect=%-8s cesdid=%-3d date=%s  zap=%s%s\n",
                       off, owner ? owner : "(unknown)", esdid, date, zap,
                       chain ? "  [chain continues]" : "");
            }
        }
        if (!json && n == 0)
            printf("  @%06lX  HMASPZAP  no entries\n", off);
        return;
    }

    if (only) return;          /* the other subtypes are not per-CSECT */

    if (json) {
        printf("%s\n    {\"record\": %ld, \"subtype\": ", *first ? "" : ",", off);
        jstr(nm);
        printf(", \"last\": %s, \"bytes\": %ld", last ? "true" : "false", rlen);
        if (base == IDR_XLATE || base == IDR_LKED || base == IDR_USER) {
            char txt[256]; long j, m = rlen - 3; if (m > 255) m = 255;
            for (j = 0; j < m; j++) txt[j] = mvs_e2a_pr(r[3 + j]);
            txt[m] = 0;
            printf(", \"text\": "); jstr(txt);
        }
        printf("}");
        *first = 0;
    } else {
        printf("  @%06lX  %-9s %ld bytes%s", off, nm, rlen, last ? "  [LAST]" : "");
        if (base == IDR_XLATE || base == IDR_LKED || base == IDR_USER) {
            long j; printf("  ");
            for (j = 3; j < rlen && j < 3 + 40; j++) putchar(mvs_e2a_pr(r[j]));
        }
        putchar('\n');
    }
}

/* ---- driver ------------------------------------------------------------ */
static void usage(FILE *f)
{
    fprintf(f,
      "usage: idrdump370 [--json] [--csect NAME] FILE\n"
      "\n"
      "  FILE           a bound load-module member\n"
      "  --csect NAME   report only HMASPZAP entries naming this section\n"
      "  --json         machine-readable output\n"
      "\n"
      "Walks the IDR chain (it ends on LASTIDR X'80', it is not a scan for\n"
      "X'80' -- text records begin with that byte too) and decodes each\n"
      "HMASPZAP entry: the entry NAMES its section by CESDID and carries no\n"
      "offset, so a count of entries cannot say whether one CSECT was serviced\n"
      "and the decoded CESDID can.\n"
      "\n"
      "Exit: 0 a chain was read, 1 no IDR record, 2 the invocation or the file\n");
}

int main(int argc, char **argv)
{
    const char *path = NULL, *only = NULL;
    int json = 0, i, first = 1, nidr = 0, rc;
    unsigned char *b; long n;
    FILE *f;
    struct lmod_iter it; struct lmod_item r;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--json")) json = 1;
        else if (!strcmp(argv[i], "--csect") && i + 1 < argc) only = argv[++i];
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage(stdout); return 0; }
        else if (!strcmp(argv[i], "--version") || !strcmp(argv[i], "-V")) { printf("%s\n", VERSION_STR); return 0; }
        else if (argv[i][0] == '-' && argv[i][1]) {
            fprintf(stderr, "idrdump370: unknown option '%s'\n", argv[i]); usage(stderr); return 2;
        } else if (!path) path = argv[i];
        else { fprintf(stderr, "idrdump370: one file at a time\n"); return 2; }
    }
    if (!path) { usage(stderr); return 2; }

    if (!(f = fopen(path, "rb"))) { perror(path); return 2; }
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    if (n <= 0 || !(b = malloc((size_t)n)) || fread(b, 1, (size_t)n, f) != (size_t)n) {
        fprintf(stderr, "idrdump370: %s: cannot read\n", path); fclose(f); return 2;
    }
    fclose(f);

    lmod_cesd_walk(b, n, cesd_cb, NULL);

    if (json) printf("{\n  \"file\": "), jstr(path), printf(",\n  \"idr\": [");
    else      printf("%s: %d section(s)\n", path, nsect);

    lmod_iter_init(&it, b, n);
    while ((rc = lmod_iter_next(&it, &r)) == 1) {
        if (r.kind != LMOD_IDR) continue;
        nidr++;
        show_idr(b + r.off, r.len, r.off, only, json, &first);
    }

    if (json) printf("%s  ],\n  \"records\": %d,\n  \"malformed\": %s\n}\n",
                     first ? "" : "\n", nidr, rc < 0 ? "true" : "false");
    else if (!nidr) printf("  no IDR records\n");

    free(b);
    return nidr ? 0 : 1;
}
