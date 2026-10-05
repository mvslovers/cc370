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
 * offset (internals/load-module-format.md 10.1, from HEWLFIDR.ASM's ZAPLOOP).  So a
 * member's entry COUNT is an upper bound on "was this CSECT serviced" and the
 * decoded CESDID is the answer -- which is the whole reason this exists.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mvs370.h"
#include "obj370.h"

#include "cc370-version.h"   /* CC370_VERSION, CC370_COMMIT (common/mkversion.sh) */
#define VERSION_STR "idrdump370 " CC370_VERSION " (" CC370_COMMIT ")"

/* IDR subtypes -- HEWLFOUT.ASM via internals/load-module-format.md section 10.
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

/* EBCDIC field -> printable ASCII, trailing blanks dropped. */
static void efield(char *out, const unsigned char *p, int n)
{
    int j;
    for (j = 0; j < n; j++) out[j] = mvs_e2a_pr(p[j]);
    while (j > 0 && out[j - 1] == ' ') j--;
    out[j] = 0;
}

/* X'02' linkage editor (internals/load-module-format.md 10.2): program id (10),
 * version and modification (1 + 1), date packed yyddd (3); IEWL here and ld370
 * append the time, packed 0hhmmss (4). */
static void packed_time(char *out, size_t n, const unsigned char *p)
{
    /* 0h hm ms sF: the six digits between the leading 0 and the sign */
    snprintf(out, n, "%x%x%x%x%x%x", p[0] & 0x0f, p[1] >> 4, p[1] & 0x0f,
             p[2] >> 4, p[2] & 0x0f, p[3] >> 4);
}
static void show_lked(const unsigned char *r, long rlen, long off, int last, int json, int *first)
{
    char prog[11];
    char date[16];
    char tm[16] = "";
    if (rlen < 18) return;
    efield(prog, r + 3, 10);
    packed_date(date, r + 15);
    if (rlen >= 22) packed_time(tm, sizeof tm, r + 18);
    if (!json) {
        printf("  @%06lX  LKED      %s V%02X M%02X  date=%s%s%s%s\n", off, prog, r[13], r[14], date,
               tm[0] ? "  time=" : "", tm, last ? "  [LAST]" : "");
        return;
    }
    printf("%s\n    {\"record\": %ld, \"subtype\": \"LKED\", \"last\": %s, \"bytes\": %ld, \"program\": ",
           *first ? "" : ",", off, last ? "true" : "false", rlen);
    jstr(prog);
    printf(", \"version\": \"%02X\", \"modification\": \"%02X\", \"date\": ", r[13], r[14]);
    jstr(date);
    printf(", \"time\": ");
    if (tm[0]) jstr(tm); else printf("null");
    printf("}");
    *first = 0;
}

/* X'04' translator (HEWLFOUT TRNSREC): items packed back to back -- the
 * CESDIDs the item applies to (2 each, the last with X'80' in its first
 * byte), a flag (0 one translator, else two), then per translator its id and
 * level (12: 10 + 2) and its date packed yyddd (3). */
struct xitem { int ids[64]; int nid; };

/* The CESDID list from q on; returns the offset past it. */
static long xlate_ids(const unsigned char *r, long rlen, long q, struct xitem *it)
{
    int more = 1;
    it->nid = 0;
    while (more && q + 2 <= rlen) {
        int b0 = r[q];
        if (it->nid < 64) it->ids[it->nid++] = ((b0 & 0x7f) << 8) | r[q + 1];
        more = !(b0 & 0x80);
        q += 2;
    }
    return q;
}
static void xlate_owners(const struct xitem *it, int json)
{
    for (int k = 0; k < it->nid; k++) {
        const char *o = sect_name(it->ids[k]);
        if (k) fputs(json ? ", " : ",", stdout);
        if (o && json) jstr(o);
        else if (o) fputs(o, stdout);
        else printf("%d", it->ids[k]);
    }
}
/* One translator: id and level at t, date at t + 12. */
static void xlate_one(const unsigned char *t, const struct xitem *it, long off, int last, int json, int *first)
{
    char prog[11];
    char date[16];
    efield(prog, t, 10);
    packed_date(date, t + 12);
    if (!json) {
        printf("  @%06lX  translator %s V%02X M%02X  date=%s  csect=", off, prog, t[10], t[11], date);
        xlate_owners(it, 0);
        printf("%s\n", last ? "  [LAST]" : "");
        return;
    }
    printf("%s\n    {\"record\": %ld, \"subtype\": \"translator\", \"last\": %s, \"csects\": [",
           *first ? "" : ",", off, last ? "true" : "false");
    xlate_owners(it, 1);
    printf("], \"program\": ");
    jstr(prog);
    printf(", \"version\": \"%02X\", \"modification\": \"%02X\", \"date\": ", t[10], t[11]);
    jstr(date);
    printf("}");
    *first = 0;
}
static void show_xlate(const unsigned char *r, long rlen, long off, int last, int json, int *first)
{
    long q = 3;
    struct xitem it;
    while (q + 2 <= rlen) {
        int ntr;
        q = xlate_ids(r, rlen, q, &it);
        if (q + 1 > rlen) return;
        ntr = r[q] ? 2 : 1;
        q++;
        if (q + 15L * ntr > rlen) return;               /* framed short */
        xlate_one(r + q, &it, off, last, json, first);
        if (ntr == 2) xlate_one(r + q + 15, &it, off, last, json, first);
        q += 15L * ntr;
    }
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
                printf("  @%06lX  HMASPZAP  csect=%-8s cesdid=%-3d date=%s  zap=%s%s%s\n",
                       off, owner ? owner : "(unknown)", esdid, date, zap,
                       chain ? "  [chain continues]" : "", last ? "  [LAST]" : "");
            }
        }
        if (n == 0 && !only) {
            /* an empty record is a record: --json lists it too, so `idr' and
             * `records' count the same thing (#809) */
            if (json) {
                printf("%s\n    {\"record\": %ld, \"subtype\": \"HMASPZAP\", \"last\": %s, \"entries\": 0}",
                       *first ? "" : ",", off, last ? "true" : "false");
                *first = 0;
            } else
                printf("  @%06lX  HMASPZAP  no entries\n", off);
        }
        return;
    }

    /* X'08' USER (IDENTIFY) -- the same first field as X'01', confirmed rather
     * than assumed: mvs38src read three APARs out of IKJEFT01's record by hand
     * and, separately, out of the three DLIB elements it is bound from; the
     * CESDIDs this reader resolves put each APAR on the element it came from
     * (1 IKJEFT01 UY13431, 2 IKJEFT06 UZ42826, 33 IKJEFTSC UY43678), and all
     * three are SD entries while the rest of that CESD is LR/ER.  Two
     * instruments, three agreements.
     *
     * Entry: CESDID(2) date(3, packed yyddd) len(1) text(len), variable, packed
     * back to back until the record ends -- 3 x (6+7) = 39 = the 42-byte
     * record less its 3-byte header.
     *
     * THIS IS THE DIRECT ANSWER TO "WAS THIS CSECT SERVICED" and the zap
     * entries are not: IKJEFT01 carries THREE APARs and ZERO zap entries, so a
     * zap-only reader reports "no service" about a module carrying three. */
    if (base == IDR_USER) {
        long q = 3;
        while (q + 6 <= rlen) {
            const unsigned char *e = r + q;
            int esdid = e[0] << 8 | e[1], tl = e[5], j;
            char date[16], txt[64];
            const char *owner;
            if (q + 6 + tl > rlen) break;               /* framed short */
            packed_date(date, e + 2);
            if (tl > 63) tl = 63;
            for (j = 0; j < tl; j++) txt[j] = mvs_e2a_pr(e[6 + j]);
            txt[tl] = 0;
            owner = sect_name(esdid);
            q += 6 + e[5];
            if (only && (!owner || strcmp(owner, only))) continue;
            if (json) {
                printf("%s\n    {\"record\": %ld, \"subtype\": \"user\", \"last\": %s, \"csect\": ",
                       *first ? "" : ",", off, last ? "true" : "false");
                if (owner) jstr(owner); else printf("null");
                printf(", \"cesdid\": %d, \"date\": ", esdid); jstr(date);
                printf(", \"id\": "); jstr(txt); printf("}");
                *first = 0;
            } else {
                printf("  @%06lX  user      csect=%-8s cesdid=%-3d date=%s  id=%s%s\n",
                       off, owner ? owner : "(unknown)", esdid, date, txt,
                       last ? "  [LAST]" : "");
            }
        }
        return;
    }

    /* The linkage-editor and translator records describe the module: shown
     * with --csect as well (#809). */
    if (base == IDR_LKED)  { show_lked(r, rlen, off, last, json, first); return; }
    if (base == IDR_XLATE) { show_xlate(r, rlen, off, last, json, first); return; }
    if (only) return;          /* an unknown subtype is not per-CSECT */

    if (json) {
        printf("%s\n    {\"record\": %ld, \"subtype\": ", *first ? "" : ",", off);
        jstr(nm);
        printf(", \"last\": %s, \"bytes\": %ld", last ? "true" : "false", rlen);
        if (base == IDR_XLATE || base == IDR_LKED) {
            char txt[256]; long j, m = rlen - 3; if (m > 255) m = 255;
            for (j = 0; j < m; j++) txt[j] = mvs_e2a_pr(r[3 + j]);
            txt[m] = 0;
            printf(", \"text\": "); jstr(txt);
        }
        printf("}");
        *first = 0;
    } else {
        printf("  @%06lX  %-9s %ld bytes%s", off, nm, rlen, last ? "  [LAST]" : "");
        if (base == IDR_XLATE || base == IDR_LKED) {
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
      "  --csect NAME   report only the HMASPZAP and IDENTIFY entries naming this\n"
      "                 section; the linkage-editor and translator records are\n"
      "                 always shown\n"
      "  --json         machine-readable output\n"
      "\n"
      "Walks the IDR chain (it ends on LASTIDR X'80', it is not a scan for\n"
      "X'80' -- text records begin with that byte too) and decodes each\n"
      "HMASPZAP entry: the entry NAMES its section by CESDID and carries no\n"
      "offset, so a count of entries cannot say whether one CSECT was serviced\n"
      "and the decoded CESDID can.\n"
      "\n"
      "Exit: 0 a chain was read, 1 no IDR record, 2 the invocation, or a file\n"
      "that is not a load module\n");
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

    /* Not a load module at all is a format error, not "no IDR records" (#809). */
    if (!lmod_plausible(b, n)) {
        fprintf(stderr, "idrdump370: %s is not a load module\n", path);
        free(b); return 2;
    }
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
