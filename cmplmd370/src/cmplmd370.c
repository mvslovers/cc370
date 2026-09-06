/* cmplmd370 -- does this object deck match that CSECT, byte for byte?
 *
 * The host equivalent of COMPLMD, the utility Dave Kreiss wrote for his MVS 3.8j
 * source recovery (mvslovers/cc370#110).  It is the SUCCESS CRITERION of a
 * recovery pipeline: a module may be declared recovered only when this exits 0,
 * so exit 0 must mean identity and nothing weaker.
 *
 * WHAT IT COMPARES, AND WHY NOT WHAT COMPLMD COMPARED.  Dave compared two LOAD
 * MODULES -- assemble, bind, compare.  This compares an as370 object deck
 * directly against the shipped load module with no binder in between, and that
 * is possible for one reason: in a bound module every address constant is
 * relocated and in a deck none is, but the binder does not touch instructions.
 * Zero the adcons on BOTH sides and the remaining text is identical.
 *
 * So --clearrld is not noise suppression, it is what makes the comparison
 * possible without reproducing IBM's bind -- which is why it defaults ON, as
 * COMPLMD's CLEARRLD did.  71 of the 102 measured DLIB members carry RLD items;
 * without it they cannot be compared at all.
 *
 * Sections are paired BY NAME, never by ESDID: the two sides number differently
 * (a deck numbers from its card's first-id field and skips LD items; a load
 * module's CESD position IS the id), and about 1 member in 10 carries several
 * sections, so assuming either is wrong twice over.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mvs370.h"
#include "obj370.h"

#define MAXSECT 512

struct sect {
    char name[9];
    long org;                   /* origin: within the object, or in the module image */
    long len;                   /* declared length -- the unit the comparison uses */
    unsigned char *bytes;       /* text image, zero where no text landed */
    unsigned char *relo;        /* 1 per byte covered by an address constant */
};

struct side {
    struct sect s[MAXSECT];
    int n;
    int id2sect[65536];         /* ESDID -> index into s[]; -1 for none */
};

static void die(const char *m, const char *a)
{
    fprintf(stderr, "cmplmd370: %s%s%s\n", m, a ? ": " : "", a ? a : "");
    exit(2);
}

static struct sect *sect_add(struct side *sd, const unsigned char *nm8,
                             long org, long len, int esdid)
{
    struct sect *s;
    if (sd->n >= MAXSECT) die("too many sections", NULL);
    s = &sd->s[sd->n];
    memset(s, 0, sizeof *s);
    strncpy(s->name, mvs_nm(nm8), sizeof s->name - 1);
    s->org = org;
    s->len = len;
    s->bytes = calloc((size_t)(len > 0 ? len : 1), 1);
    s->relo  = calloc((size_t)(len > 0 ? len : 1), 1);
    if (!s->bytes || !s->relo) die("out of memory", NULL);
    if (esdid > 0 && esdid < 65536) sd->id2sect[esdid] = sd->n;
    sd->n++;
    return s;
}

static void side_init(struct side *sd)
{
    memset(sd, 0, sizeof *sd);
    memset(sd->id2sect, -1, sizeof sd->id2sect);
}

/* Mark the bytes an address constant covers.  The item's `addr` is relative to
 * whatever the producer measured from -- section origin in a deck, module origin
 * in a bound member -- and `p` names the section, so the section's own origin is
 * the right thing to subtract in both cases. */
static int mark_relo(const struct obj_rld *r, void *ctx)
{
    struct side *sd = ctx;
    int si = (r->p > 0 && r->p < 65536) ? sd->id2sect[r->p] : -1;
    long a, w, i;
    if (si < 0) return 1;
    a = r->addr - sd->s[si].org;
    w = obj_rld_len(r->flag);
    for (i = 0; i < w; i++)
        if (a + i >= 0 && a + i < sd->s[si].len) sd->s[si].relo[a + i] = 1;
    return 1;
}

/* ---------------- object deck ---------------- */

static int deck_esd(const struct obj_esd *e, void *ctx)
{
    if (obj_is_section(e->type)) sect_add(ctx, e->name, e->addr, e->len, e->esdid);
    return 1;
}

static void load_deck(struct side *sd, const unsigned char *b, long n)
{
    long off;
    side_init(sd);
    for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN)
        if (obj_card_type(b + off) == OBJ_ESD) obj_esd_walk(b + off, deck_esd, sd);

    for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN) {
        const unsigned char *c = b + off;
        if (obj_card_type(c) == OBJ_TXT) {
            struct obj_txt t;
            int si;
            if (!obj_txt_get(c, &t)) continue;
            si = (t.esdid > 0 && t.esdid < 65536) ? sd->id2sect[t.esdid] : -1;
            if (si < 0) continue;
            {   /* TXT addresses are section-relative in a deck */
                long a = t.addr - sd->s[si].org;
                if (a >= 0 && a + t.len <= sd->s[si].len)
                    memcpy(sd->s[si].bytes + a, t.data, (size_t)t.len);
            }
        } else if (obj_card_type(c) == OBJ_RLD) {
            obj_rld_walk(c, mark_relo, sd);
        }
    }
}

/* ---------------- load module ---------------- */

static int lmod_sect(const struct lmod_esd *e, void *ctx)
{
    /* Full type byte: a bound CESD uses 00/04/05 for the storage-owning kinds. */
    if (e->type == 0x00 || e->type == 0x04 || e->type == 0x05)
        sect_add(ctx, e->name, e->addr, e->len, e->esdid);
    return 1;
}

static void load_lmod(struct side *sd, const unsigned char *m, long n)
{
    struct lmod_iter it;
    struct lmod_item r;
    unsigned char *img;
    long imglen = 0, pend = -1;
    int rc, i;

    side_init(sd);
    lmod_cesd_walk(m, n, lmod_sect, sd);

    for (i = 0; i < sd->n; i++)
        if (sd->s[i].org + sd->s[i].len > imglen) imglen = sd->s[i].org + sd->s[i].len;
    /* A text record can reach PAST the sum of the section lengths: the binder
     * pads to a doubleword, so a 12-byte section arrives as 16 bytes of text.
     * Sizing the image from the sections alone made the bounds check below
     * reject the whole copy and every reference byte then read as zero --
     * which looks exactly like a real difference at offset 0.  Found on
     * IGG026DU, the first real DLIB member this was pointed at. */
    lmod_iter_init(&it, m, n);
    {
        long pa = -1;
        while (lmod_iter_next(&it, &r) == 1) {
            if (r.kind == LMOD_CTL)
                pa = (r.flags & LMOD_CTL_TEXT) ? mvs_be24(m + r.off + 9) : -1;
            else if (r.kind == LMOD_TEXT) {
                if (pa >= 0 && pa + r.len > imglen) imglen = pa + r.len;
                pa = -1;
            }
        }
    }
    img = calloc((size_t)(imglen > 0 ? imglen : 1), 1);
    if (!img) die("out of memory", NULL);

    /* Reassemble the module image, then slice each section out of it: a control
     * record carries the load address (24-bit at +9) of the text record that
     * follows it, and the RLD items sit after its ID/length list. */
    lmod_iter_init(&it, m, n);
    while ((rc = lmod_iter_next(&it, &r)) == 1) {
        if (r.kind == LMOD_CTL) {
            pend = (r.flags & LMOD_CTL_TEXT) ? mvs_be24(m + r.off + 9) : -1;
            if (r.flags & LMOD_CTL_RLD) {
                long idl = mvs_be16(m + r.off + 4), rl = mvs_be16(m + r.off + 6);
                long dat = r.off + 16 + idl;
                if (rl > 0 && dat + rl <= n) obj_rld_items(m + dat, rl, mark_relo, sd);
            }
        } else if (r.kind == LMOD_TEXT) {
            if (pend >= 0 && pend + r.len <= imglen)
                memcpy(img + pend, m + r.off, (size_t)r.len);
            pend = -1;
        }
    }
    if (rc < 0) die("malformed load-module record stream", NULL);

    for (i = 0; i < sd->n; i++)
        if (sd->s[i].org >= 0 && sd->s[i].org + sd->s[i].len <= imglen)
            memcpy(sd->s[i].bytes, img + sd->s[i].org, (size_t)sd->s[i].len);
    free(img);
}

/* ---------------- compare ---------------- */

/* Clusters matter more than the total: three separate one-byte differences and
 * one three-byte run mean very different things (#110). */
#define MAXCLU 64
#define CLUBYTES 16

static void hexrun(const unsigned char *p, long n)
{
    long i;
    for (i = 0; i < n && i < CLUBYTES; i++) printf("%02x", p[i]);
    if (n > CLUBYTES) printf("..");
}

static int compare(const struct sect *a, const struct sect *b, int clearrld,
                   int verbose, const char *label)
{
    long i, diff = 0, nclu = 0, masked = 0;
    long cluoff[MAXCLU], clulen[MAXCLU];
    int inrun = 0;

    if (a->len != b->len) {
        printf("  %-8s LENGTH differs: new %ld, reference %ld (%+ld)\n",
               label, a->len, b->len, a->len - b->len);
        return 1;
    }
    for (i = 0; i < a->len; i++) {
        int skip = clearrld && (a->relo[i] || b->relo[i]);
        if (skip) { masked++; inrun = 0; continue; }
        if (a->bytes[i] != b->bytes[i]) {
            diff++;
            if (!inrun) {
                inrun = 1;
                if (nclu < MAXCLU) { cluoff[nclu] = i; clulen[nclu] = 0; }
                nclu++;
            }
            if (nclu <= MAXCLU) clulen[nclu - 1]++;
        } else inrun = 0;
    }
    if (!diff) {
        if (verbose)
            printf("  %-8s identical (%ld bytes%s)\n", label, a->len,
                   masked ? (clearrld ? ", adcons cleared" : "") : ", no adcons");
        return 0;
    }
    printf("  %-8s %ld byte(s) differ in %ld cluster(s) of %ld%s\n",
           label, diff, nclu, a->len,
           masked ? "" : " -- no adcon was cleared, so this is instruction text");
    for (i = 0; i < nclu && i < MAXCLU && verbose; i++) {
        printf("      @%06lX  %2ld  new ", cluoff[i], clulen[i]);
        hexrun(a->bytes + cluoff[i], clulen[i]);
        printf("  ref ");
        hexrun(b->bytes + cluoff[i], clulen[i]);
        printf("\n");
    }
    if (nclu > MAXCLU && verbose)
        printf("      ... %ld more cluster(s) not listed\n", nclu - MAXCLU);
    return 1;
}

/* ---------------- driver ---------------- */

static void usage(FILE *f)
{
    fprintf(f,
      "usage: cmplmd370 [options] NEW.obj REFERENCE\n"
      "\n"
      "  NEW.obj     an object deck (as370 output)\n"
      "  REFERENCE   a bound load-module member, or another object deck\n"
      "\n"
      "  --csect NAME   compare only this section (default: pair all by name)\n"
      "  --clearrld     zero address constants before comparing (DEFAULT)\n"
      "  --no-clearrld  compare adcons too -- only meaningful deck against deck\n"
      "  -v             report identical sections too\n"
      "\n"
      "Exit 0 ONLY on identity; 1 on any difference; 2 on a usage or format error.\n");
}

int main(int argc, char **argv)
{
    const char *fa = NULL, *fb = NULL, *only = NULL;
    int clearrld = 1, verbose = 0, i, rc = 0, npair = 0;
    unsigned char *ba, *bb;
    long na, nb;
    static struct side A, B;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--csect") && i + 1 < argc) only = argv[++i];
        else if (!strcmp(argv[i], "--clearrld")) clearrld = 1;
        else if (!strcmp(argv[i], "--no-clearrld")) clearrld = 0;
        else if (!strcmp(argv[i], "-v")) verbose = 1;
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) { usage(stdout); return 0; }
        else if (argv[i][0] == '-') { fprintf(stderr, "cmplmd370: unknown option %s\n", argv[i]); usage(stderr); return 2; }
        else if (!fa) fa = argv[i];
        else if (!fb) fb = argv[i];
        else { usage(stderr); return 2; }
    }
    if (!fa || !fb) { usage(stderr); return 2; }

    ba = mvs_read_file(fa, &na); if (!ba) { perror(fa); return 2; }
    bb = mvs_read_file(fb, &nb); if (!bb) { perror(fb); return 2; }

    if (na < 4 || obj_card_type(ba) == OBJ_OTHER) die("not an object deck", fa);
    load_deck(&A, ba, na);

    if (nb >= 1 && (bb[0] & 0xf0) == 0x20) load_lmod(&B, bb, nb);
    else if (nb >= 4 && obj_card_type(bb) != OBJ_OTHER) load_deck(&B, bb, nb);
    else die("reference is neither a load module nor an object deck", fb);

    printf("%s vs %s%s\n", fa, fb, clearrld ? "" : "  (adcons compared)");
    for (i = 0; i < A.n; i++) {
        struct sect *b2;
        if (only && strcmp(A.s[i].name, only)) continue;
        b2 = NULL;
        {   int k;
            for (k = 0; k < B.n; k++)
                if (!strcmp(B.s[k].name, A.s[i].name)) { b2 = &B.s[k]; break; }
        }
        if (!b2) {
            printf("  %-8s not in the reference\n", A.s[i].name[0] ? A.s[i].name : "(private)");
            rc = 1;
            continue;
        }
        npair++;
        if (compare(&A.s[i], b2, clearrld, verbose, A.s[i].name[0] ? A.s[i].name : "(private)"))
            rc = 1;
    }
    if (only && !npair) { fprintf(stderr, "cmplmd370: no section named %s\n", only); return 2; }
    if (!npair && !rc) { fprintf(stderr, "cmplmd370: no sections paired\n"); return 2; }
    printf("%s\n", rc ? "DIFFER" : "IDENTICAL");
    return rc;
}
